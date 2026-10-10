#!/usr/bin/env node
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { readFile, mkdir, mkdtemp, writeFile, rename, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { dirname, join, resolve, extname, relative, isAbsolute } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import * as compiler from '@proofscript/compiler';
import { checkCanonicalAdmissions } from '@proofscript/pskernel-lean-wasm';

const require = createRequire(import.meta.url);
const meta = JSON.parse(readFileSync(fileURLToPath(new URL('../package.json', import.meta.url)), 'utf8'));
const sha = content => createHash('sha256').update(content).digest('hex');
const help = [
  'ProofScript PSC0 npm compiler',
  'Usage: psc version [--json]',
  '       psc init [directory] [--syntax ps|lean]',
  '       psc check <entry.ps|entry.lean> [--json]',
  '       psc build <entry.ps|entry.lean> [--out output.js|output.ts] [--json]',
  '       psc packages [--json]',
  'Builds use pinned Lean 4.34 WASM checking and TypeScript 7.0.2.',
  'The shipped JavaScript PSKernel Core is a separate unpromoted candidate.',
].join('\n');
const packageSections = {
  BackendJs:'backend-js', BackendRust:'backend-rust', BackendTs:'backend-ts',
  BackendWasm:'backend-wasm', Bootstrap:'bootstrap', Bridge:'bridge',
  CompilerIr:'compiler-ir', Compiler:'compiler', Core:'core', KernelCore:'pskernel-core',
  Elab:'elab', Environment:'environment', Erasure:'erasure', Foundation:'foundation',
  Meta:'meta', Syntax:'syntax', Kernel:'pskernel-core',
};
function fail(message) { throw new Error(message); }
function ctorTag(value) {
  if (!value || typeof value !== 'object') return undefined;
  return Object.getOwnPropertySymbols(value).map(x => value[x]).find(x => typeof x === 'string');
}
function unwrap(value, phase) {
  const tag = ctorTag(value);
  if (tag === 'ok') return value.value;
  fail('PSC_' + phase.toUpperCase() + '_FAILED: ' +
    (tag === 'error' ? JSON.stringify(value.error, (_key, x) => typeof x === 'bigint' ? x.toString() : x) : 'invalid compiler result'));
}
function parseImports(source, kind) {
  if (kind === 'lean') {
    return source.split(/\r?\n/u).map(line => line.match(/^\s*import\s+([A-Za-z_][A-Za-z_0-9.]*)\s*$/u)?.[1]).filter(Boolean);
  }
  const module = unwrap(compiler.psParseProofScriptSource(source), 'parse');
  const result = [];
  let cur = module.imports;
  while (ctorTag(cur) === 'cons') {
    const name = unwrap(compiler.psPrintSyntaxName(cur.head.moduleName), 'import-name');
    if (typeof name !== 'string') fail('PSC_IMPORT_INVALID');
    result.push(name);
    cur = cur.tail;
  }
  if (ctorTag(cur) !== 'nil') fail('PSC_IMPORT_LIST_INVALID');
  return result;
}
function packageRoot(name) {
  const fullName = '@proofscript/' + name;
  return dirname(require.resolve(fullName + '/package.json'));
}
function resolveSourceImport(name, kind, parentFile, projectRoot) {
  if (!/^[A-Za-z_][A-Za-z_0-9]*(?:\.[A-Za-z_][A-Za-z_0-9]*)*$/u.test(name)) fail('PSC_IMPORT_NAME: ' + name);
  const parts = name.split('.');
  const extension = '.' + kind;
  const candidate = parts[0] === 'Ps' && packageSections[parts[1]]
    ? join(packageRoot(packageSections[parts[1]]), 'src', ...parts) + extension
    : parts[0] === 'ProofScript'
      ? join(packageRoot('foundation'), 'src', ...parts) + extension
      : join(projectRoot, ...parts) + extension;
  if (!existsSync(candidate)) fail('PSC_IMPORT_MISSING: ' + name + ' (' + candidate + ')');
  return candidate;
}
async function sourceClosure(entry, kind) {
  const seen = new Set(), active = new Set(), sources = [];
  const projectRoot = process.cwd();
  async function visit(location) {
    const absolute = resolve(location);
    if (active.has(absolute)) fail('PSC_IMPORT_CYCLE: ' + absolute);
    if (seen.has(absolute)) return;
    const source = await readFile(absolute, 'utf8');
    active.add(absolute);
    for (const name of parseImports(source, kind)) await visit(resolveSourceImport(name, kind, absolute, projectRoot));
    active.delete(absolute);
    seen.add(absolute);
    sources.push(kind === 'lean'
      ? source.split(/\r?\n/u).filter(line => !/^\s*import\s+[A-Za-z_0-9.]+\s*$/u.test(line)).join('\n').trim()
      : source);
  }
  await visit(entry);
  return sources;
}
function listOf(sources) {
  let list = compiler.List.nil();
  for (let i = sources.length - 1; i >= 0; i--) list = compiler.List.cons(sources[i], list);
  return list;
}
async function prepare(entry) {
  const kind = extname(entry) === '.ps' ? 'ps' : extname(entry) === '.lean' ? 'lean' : null;
  if (!kind) fail('PSC_SOURCE_EXTENSION: provide .ps or .lean');
  if (compiler.psProofScriptGrammarEdition !== 'ps-0.9-r3' ||
      compiler.psProofScriptGrammarMode !== 'new-only') fail('PSC_COMPILER_GRAMMAR_MISMATCH');
  const sources = await sourceClosure(entry, kind);
  const sourceKind = kind === 'ps'
    ? compiler.PsCompilerSourceKind.proofScript : compiler.PsCompilerSourceKind.lean;
  const prepared = unwrap(compiler.psCompilerPrepareSources(sourceKind, listOf(sources)), 'prepare');
  const admissions = unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared), 'admissions');
  if (typeof admissions !== 'string') fail('PSC_ADMISSIONS_INVALID');
  const decision = await checkCanonicalAdmissions(admissions, { timeoutMs: 120000 });
  if (decision.accepted !== true) fail('PSC_KERNEL_REJECTED: ' + (decision.errorKind || decision.message || 'invalid admission'));
  return { prepared, kind, sourceCount: sources.length, admissionsSha256: sha(admissions),
    kernel: { protocol: decision.protocol, provider: decision.provider,
      leanVersion: decision.leanVersion, profile: decision.profile } };
}
function tscCLI() {
  const pkg = require.resolve('typescript/package.json');
  const manifest = JSON.parse(readFileSync(pkg, 'utf8'));
  if (manifest.name !== 'typescript' || manifest.version !== '7.0.2') fail('PSC_TYPESCRIPT_PIN');
  const bin = typeof manifest.bin === 'string' ? manifest.bin : manifest.bin?.tsc;
  if (!bin) fail('PSC_TYPESCRIPT_BIN_MISSING');
  return resolve(dirname(pkg), bin);
}
async function build(entry, out) {
  const checked = await prepare(entry);
  const typeScript = unwrap(compiler.psCompilerTypeScriptFromPrepared(checked.prepared), 'emit');
  if (typeof typeScript !== 'string') fail('PSC_TYPESCRIPT_INVALID');
  const output = resolve(out || entry.replace(/\.(ps|lean)$/u, '.js'));
  if (!/\.(?:js|ts)$/u.test(output)) fail('PSC_OUTPUT_EXTENSION');
  await mkdir(dirname(output), { recursive: true });
  const stage = await mkdtemp(join(dirname(output), '.psc-stage-'));
  const stem = 'output';
  try {
    const tmpTs = join(stage, stem + '.ts');
    await writeFile(tmpTs, typeScript);
    const result = spawnSync(process.execPath, [tscCLI(), '--ignoreConfig', tmpTs,
      '--target','ES2022','--module','ES2022','--moduleResolution','bundler',
      '--strict','--declaration','--sourceMap','--skipLibCheck','--noEmitOnError',
      '--pretty','false'], { encoding: 'utf8', timeout: 180000, maxBuffer: 16*1024*1024 });
    if (result.error || result.status !== 0) fail('PSC_TSC_FAILED: ' + String(result.stderr || result.stdout || result.error));
    const prefix = output.replace(/\.(?:js|ts)$/u, '');
    for (const extension of ['.ts','.js','.d.ts','.js.map']) {
      await rename(join(stage, stem + extension), prefix + extension);
    }
    const receipt = { kind: 'psc0-npm-checked-build', version: meta.version, entry: resolve(entry),
      sourceCount: checked.sourceCount, admissionsSha256: checked.admissionsSha256,
      kernel: checked.kernel, typescript: '7.0.2', output: prefix+'.js',
      outputSha256: sha(await readFile(prefix+'.js')), sourceSha256: sha(await readFile(entry)) };
    await writeFile(prefix+'.checked.json', JSON.stringify(receipt,null,2)+'\n');
    return receipt;
  } finally {
    await rm(stage, { recursive: true, force: true });
  }
}
async function init(directory='.', syntax='ps') {
  if (!['ps','lean'].includes(syntax)) fail('PSC_INIT_SYNTAX');
  const where = resolve(directory);
  await mkdir(join(where, 'src'), { recursive: true });
  const sourcePath = join(where,'src','Main.'+syntax);
  if (existsSync(sourcePath)) fail('PSC_INIT_EXISTS: ' + sourcePath);
  await writeFile(sourcePath, 'def answer : Nat := 42\n', { flag: 'wx' });
  const configPath = join(where, 'package.json');
  if (!existsSync(configPath)) await writeFile(configPath, JSON.stringify({
    name: 'proofscript-app', private: true, type: 'module',
    proofscript: { entry: 'src/Main.'+syntax, out: 'src/Main.js' },
    scripts: { check:'psc check src/Main.'+syntax, build:'psc build src/Main.'+syntax+' --out src/Main.js' },
  },null,2)+'\n',{flag:'wx'});
  return { projectRoot: where, source: sourcePath, initialized: true };
}
function argAfter(args, name) {
  const i = args.indexOf(name);
  if (i < 0) return undefined;
  if (!args[i+1] || args[i+1].startsWith('--')) fail('PSC_FLAG_VALUE: ' + name);
  return args[i+1];
}
async function main(args) {
  let [command='help',...rest]=args;
  if (['help','--help','-h'].includes(command)) { console.log(help); return; }
  if (['version','--version','-v','packages'].includes(command)) {
    const result = { name: 'proofscript', version: meta.version,
      distribution: meta.proofscript?.sourceVariant || 'unknown',
      compiler: 'PSC0 ps-0.9-r3 new-only bounded self-host subset',
      checker: '@proofscript/pskernel-lean-wasm / Lean 4.34.0',
      jsCore: '@proofscript/pskernel-core (unpromoted candidate)',
      packageCount: 19 };
    console.log(rest.includes('--json')||command==='packages'?JSON.stringify(result,null,2):'psc '+result.version); return;
  }
  if (command==='init') {
    const target=rest[0]&&!rest[0].startsWith('--')?rest.shift():'.';
    const result=await init(target,argAfter(rest,'--syntax')||meta.proofscript?.sourceVariant||'ps');
    console.log(JSON.stringify(result,null,2)); return;
  }
  if (!['check','build'].includes(command)) fail('PSC_COMMAND_UNSUPPORTED: '+command);
  const entry=rest.shift();
  if (!entry||entry.startsWith('--')) fail('PSC_ENTRY_REQUIRED');
  const result=command==='check' ? (()=>prepare(entry))() : build(entry,argAfter(rest,'--out'));
  const completed=await result;
  const summary=command==='check'?{
    kind:'psc0-npm-checked',entry:resolve(entry),sourceCount:completed.sourceCount,
    admissionsSha256:completed.admissionsSha256,kernel:completed.kernel,
  }:completed;
  console.log(rest.includes('--json')?JSON.stringify(summary,null,2):'PSC_'+command.toUpperCase()+'_PASS: '+entry);
}
try { await main(process.argv.slice(2)); }
catch (error) { console.error('psc: '+String(error?.stack||error)); process.exitCode=1; }
