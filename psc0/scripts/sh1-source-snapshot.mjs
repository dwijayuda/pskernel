import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { packageBySection, parseImports } from './workspace-layout.mjs';

export const bootstrapEntryRelative = 'packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean';
const allowedPackages = new Set([
  'bootstrap', 'foundation', 'syntax', 'core', 'environment', 'meta', 'elab',
  'bridge', 'compiler-ir', 'erasure', 'compiler', 'backend-ts',
]);
const sha256 = (value) => createHash('sha256').update(value).digest('hex');
let importSequence = 0;

export function stripBootstrapImports(source) {
  return source.split(/\r?\n/u)
    .filter((line) => !/^\s*import\s+[A-Za-z0-9_.]+\s*;?\s*$/u.test(line))
    .join('\n').trim();
}

// Read raw authored Lean modules in dependency order on every request. This is
// the same restricted compiler closure used by SH/1 qualification. It neither
// substitutes a generated dist workspace nor pins the historical module count.
export async function readBootstrapClosure(workspace) {
  const ordered = [];
  const complete = new Set();
  const active = new Set();
  async function visit(relative) {
    if (complete.has(relative)) return;
    assert(!active.has(relative), 'PSC0_SH1_IMPORT_CYCLE: ' + relative);
    assert(!relative.startsWith('..') && !path.isAbsolute(relative), 'PSC0_SH1_SOURCE_OUTSIDE_ROOT');
    active.add(relative);
    const source = await readFile(path.join(workspace, relative), 'utf8');
    for (const moduleName of parseImports(source)) {
      const parts = moduleName.split('.');
      const packageName = parts[0] === 'Ps' ? packageBySection.get(parts[1]) : undefined;
      assert(allowedPackages.has(packageName), 'PSC0_SH1_CLOSURE_PACKAGE: ' + moduleName);
      await visit(path.posix.join('packages', packageName, 'src', ...parts) + '.lean');
    }
    active.delete(relative);
    complete.add(relative);
    ordered.push({ path: relative, source, sha256: sha256(source) });
  }
  await visit(bootstrapEntryRelative);
  const manifest = ordered.map(({ path: sourcePath, sha256: digest }) => ({
    path: sourcePath, sha256: digest,
  }));
  return {
    ordered,
    manifest,
    sha256: sha256(JSON.stringify(manifest)),
    moduleCount: ordered.length,
    bytes: ordered.reduce((count, item) => count + Buffer.byteLength(item.source), 0),
  };
}

// Generated bundles are standalone. Hash the bytes read and import those same
// bytes, with only a digest-labelled diagnostic sourceURL comment appended.
// An optional expected digest is checked before any compiler code is executed.
// Each explicit load has its own namespace; do not transfer tagged values.
export async function loadGeneratedCompiler(file, { expectedSha256 } = {}) {
  const bytes = await readFile(file);
  const compilerSha256 = sha256(bytes);
  if (expectedSha256 !== undefined) {
    assert(/^[a-f0-9]{64}$/u.test(expectedSha256), 'PSC0_SH1_COMPILER_PIN_SHAPE');
    assert.equal(compilerSha256, expectedSha256, 'PSC0_SH1_COMPILER_PIN_MISMATCH');
  }
  const sequence = ++importSequence;
  const diagnosticTrailer = '\n//# sourceURL=psc0-sh1-' + compilerSha256 + '-' + sequence + '.mjs\n';
  const exactBody = Buffer.concat([bytes, Buffer.from(diagnosticTrailer)]);
  const compiler = await import('data:text/javascript;base64,' + exactBody.toString('base64'));
  for (const name of [
    'PsCompilerSourceKind', 'List', 'psCompilerPrepareSource', 'psCompilerPrepareSources',
    'psCompilerAdmissionsFromPrepared', 'psCompilerTypeScriptFromPrepared',
    'psCompilerTranslateSource',
  ]) assert(name in compiler, 'PSC0_SH1_COMPILER_EXPORT: ' + name);
  return { compiler, compilerSha256 };
}
