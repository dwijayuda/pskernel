// Host-side source graph. The qualified compiler still owns parsing/elaboration.
import path from 'node:path';
import { realpath } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { createSnapshotReader } from './snapshot.mjs';
import { nearestProject, resolveSourceDescriptor, findPackage, declaredLibraries } from './libraries.mjs';
import { createLibraryDisclosure } from './library-disclosure.mjs';
import { unwrapCompilerResult } from './checked-session.mjs';
const hostDirectory = path.dirname(fileURLToPath(import.meta.url));
const sections = Object.freeze({ BackendJs: 'backend-js', BackendRust: 'backend-rust', BackendTs: 'backend-ts', BackendWasm: 'backend-wasm', Bootstrap: 'bootstrap', Bridge: 'bridge', CompilerIr: 'compiler-ir', Compiler: 'compiler', Core: 'core', KernelCore: 'pskernel-core', Elab: 'elab', Environment: 'environment', Erasure: 'erasure', Foundation: 'foundation', Meta: 'meta', Syntax: 'syntax' });
const modulePattern = /^[A-Za-z_][A-Za-z_0-9]*(?:\.[A-Za-z_][A-Za-z_0-9]*)*$/u;
const leanImport = /^\s*import\s+([A-Za-z_][A-Za-z_0-9.]*)(?:\s*;)?\s*(?:--.*)?$/u;
function sumTag(value) {
  if (!value || typeof value !== 'object') return undefined;
  return Object.getOwnPropertySymbols(value).map(k => value[k]).find(v => typeof v === 'string');
}
export function readImports(compiler, source, kind) {
  if (kind === 'lean') return source.split(/\r?\n/u).map(s => s.match(leanImport)?.[1]).filter(Boolean);
  const module = unwrapCompilerResult(compiler.psParseProofScriptSource(source), 'PARSE');
  const names = [];
  let rest = module.imports;
  while (sumTag(rest) === 'cons') {
    if (names.length >= 2048) throw new Error('PSC_IMPORT_COUNT');
    const name = unwrapCompilerResult(compiler.psPrintSyntaxName(rest.head.moduleName), 'IMPORT_NAME');
    if (typeof name !== 'string') throw new Error('PSC_IMPORT_NAME');
    names.push(name); rest = rest.tail;
  }
  if (sumTag(rest) !== 'nil') throw new Error('PSC_IMPORT_LIST');
  return names;
}
export async function captureSourceGraph(compiler, entry, { limits, trustedFiles = [], packageDirectory = hostDirectory } = {}) {
  const kind = path.extname(entry).slice(1);
  if (!['lean', 'ps'].includes(kind)) throw new Error('PSC_SOURCE_EXTENSION');
  if (compiler.psProofScriptGrammarEdition !== 'ps-0.9-r3' || compiler.psProofScriptGrammarMode !== 'new-only') throw new Error('PSC_COMPILER_GRAMMAR_MISMATCH');
  const io = createSnapshotReader(limits);
  const project = await nearestProject(path.dirname(path.resolve(entry)), io);
  const libraries = createLibraryDisclosure(declaredLibraries(project));
  for (const name of ['package-lock.json', 'npm-shrinkwrap.json']) await io.readText(path.join(project.root, name), { optional: true, id: 'lock/' + name, maxBytes: 8 * 1024 * 1024 });
  for (const [id, file] of trustedFiles) await io.readText(file, { id: 'trusted/' + id, maxBytes: 8 * 1024 * 1024 });
  const visited = new Set(), active = new Set(), sources = [], edges = [];
  async function locate(name) {
    if (!modulePattern.test(name)) throw new Error('PSC_IMPORT_NAME: ' + name);
    const parts = name.split('.');
    if (parts[0] !== 'Ps') return resolveSourceDescriptor(name, kind, project, io);
    const section = sections[parts[1]];
    if (!section) throw new Error('PSC_OFFICIAL_MODULE_UNSUPPORTED: ' + name);
    const pkg = await findPackage('@proofscript/' + section, packageDirectory, io, { optional: true, scope: 'installed-host' }) || await findPackage('@proofscript/' + section, project.root, io);
    return { path: path.join(pkg.root, 'src', ...parts) + '.' + kind, root: pkg.root };
  }
  async function visit(descriptor, logical, depth) {
    if (depth > io.limits.maxDepth) throw new Error('PSC_IMPORT_DEPTH_LIMIT');
    const actual = await realpath(descriptor.path);
    if (active.has(actual)) throw new Error('PSC_IMPORT_CYCLE: ' + logical);
    const source = await io.readText(descriptor.path, { root: descriptor.root, id: 'source/' + logical });
    if (descriptor.library) libraries.record(descriptor.library, logical, kind, io.fileEvidence(descriptor.path));
    // Record every resolved alias before deduplicating compilation by realpath.
    // A second alias cannot escape snapshot revalidation or library disclosure.
    if (visited.has(actual)) return;
    active.add(actual);
    // Production delegates synchronous parser work to the owned child. Direct
    // compiler callers remain supported for source-only inventory qualification.
    const imports = typeof compiler.readSourceImports === 'function'
      ? await compiler.readSourceImports(source, kind) : readImports(compiler, source, kind);
    if (!Array.isArray(imports) || imports.length > 2048 || imports.some(n => typeof n !== 'string' || !modulePattern.test(n))) throw new Error('PSC_IMPORT_LIST');
    for (const name of imports) {
      const child = await locate(name); edges.push([logical, name]);
      await visit(child, name, depth + 1);
    }
    active.delete(actual); visited.add(actual);
    sources.push(kind === 'lean' ? source.split(/\r?\n/u).filter(s => !leanImport.test(s)).join('\n').trim() : source);
  }
  await visit({ path: path.resolve(entry), root: project.root }, 'entry', 0);
  const libraryDisclosure = libraries.seal();
  const snapshot = io.seal({ kind, entry: path.relative(project.root, path.resolve(entry)).split(path.sep).join('/'), grammar: 'ps-0.9-r3/new-only', profile: 'bounded-compiler', policy: project.meta.proofscript || {}, edges, limits: io.limits, libraryDisclosureSha256: libraryDisclosure.sha256 });
  await snapshot.revalidate();
  return Object.freeze({ kind, sources: Object.freeze(sources), sourceCount: sources.length, snapshot, libraryDisclosure });
}
