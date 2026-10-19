import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, writeFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dir = path.join(root, 'dist/js-bundle/psc0-js-release');
const file = (pkg, extension) => path.join(dir, pkg, 'index.' + extension);
const sha256 = value => createHash('sha256').update(value).digest('hex');
const compiler = await import(pathToFileURL(file('compiler', 'js')).href);
for (const name of [
  'PsCompilerSourceKind', 'psCompilerPrepareSources',
  'psCompilerTypeScriptFromPrepared', 'psCompilerTranslateSource', 'List',
]) {
  assert.ok(Object.hasOwn(compiler, name), 'Missing compiler export: ' + name);
}
assert.equal(compiler.psProofScriptGrammarEdition, 'ps-0.9-r3');
assert.equal(compiler.psProofScriptGrammarMode, 'new-only');

const kernel = await import(pathToFileURL(file('pskernel-core', 'js')).href);
for (const name of [
  'PsKernelName', 'PsKernelLevel', 'PsKernelExpr', 'psKernelNameEq',
  'psKernelEnvironmentEmpty', 'psKernelEnvironmentSize',
  'psKernelV1AdmitDeclaration', 'psKernelCoreSemanticRoot',
]) {
  assert.ok(Object.hasOwn(kernel, name), 'Missing kernel export: ' + name);
}
assert.equal(typeof kernel.psKernelV1AdmitDeclaration, 'function');
assert.ok(typeof kernel.psKernelCoreSemanticRoot === 'function' ||
          kernel.psKernelCoreSemanticRoot === true);

const outputs = [];
for (const pkg of ['compiler', 'pskernel-core']) {
  for (const extension of ['js', 'ts', 'd.ts', 'js.map']) {
    const location = file(pkg, extension);
    const size = (await stat(location)).size;
    assert.ok(size > 0, 'Empty output: ' + location);
    outputs.push({
      path: path.relative(dir, location).split(path.sep).join('/'),
      size,
      sha256: sha256(await readFile(location)),
    });
  }
}
const commit = process.env.GITHUB_SHA || 'unknown';
const data = {
  schemaVersion: 1,
  releaseKind: 'psc0-compiled-js-candidate',
  repository: 'dwijayuda/pskernel',
  baseMainCommit: '748ee630e43ee1a89643cbc8cec3e31087788b08',
  buildCommit: commit,
  toolchain: { lean: '4.34.0', node: process.version, typescript: '7.0.2' },
  source: {
    compiler: 'psc0/packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean',
    kernel: 'psc0/packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean',
  },
  runtimeSmoke: { moduleImports: true, compilerExportSurface: true, kernelExportSurface: true, kernelSemanticsValidated: false },
  assurance: {
    exactCompiledOutputsHashed: true,
    freshSelfhostFixedPoint: false,
    nativeVsGeneratedKernelParity: false,
    fullPscvConformance: false,
    generatedKernelPromotedToTrustedChecker: false,
  },
  files: outputs,
};
await writeFile(path.join(dir, 'MANIFEST.json'), JSON.stringify(data, null, 2) + '\n');
await writeFile(path.join(dir, 'package.json'), JSON.stringify({
  name: 'psc0-selfhost-compiler-pskernel-core-js-candidate',
  version: '0.0.0-candidate',
  private: true,
  type: 'module',
}, null, 2) + '\n');
await writeFile(path.join(dir, 'README.md'), [
  '# PSC0 self-host compiler and PSKernel Core JavaScript',
  '',
  'Generated from the pinned repository main source at 748ee630e43ee1a89643cbc8cec3e31087788b08.',
  'Build commit: ' + commit,
  '',
  'Run with Node.js 22.23.3 or a compatible ESM-capable Node runtime:',
  '',
  'Example:',
  "import * as compiler from './compiler/index.js';",
  "import * as kernel from './pskernel-core/index.js';",
  'console.log(compiler.psProofScriptGrammarEdition);',
  'console.log(kernel.psKernelCoreSemanticRoot);',
  '',
  'Each component includes index.js, index.ts, index.d.ts and index.js.map.',
  'MANIFEST.json records exact SHA-256 values and tests executed in cloud CI.',
  'The JS smoke gate checks module imports and export presence, not semantic equivalence.',
  '',
  'Limitations: PSKernel Core JavaScript is a generated runtime candidate, not a promoted',
  'trusted checker. The smoke test is not a kernel soundness, consistency,',
  'full PSCV conformance, compiler semantic-preservation, or joint self-host proof.',
  'No fresh C1/C2/C3 compiler fixed-point or full kernel differential test runs here.',
  'Do not use these bytes as proof-checking authority without separate qualification.',
  '',
].join('\n'));
console.log('PSC0_JS_BUNDLE: PASS ' + JSON.stringify({
  buildCommit: commit, generatedFiles: outputs.length,
  compilerJsBytes: outputs.find(x => x.path === 'compiler/index.js').size,
  kernelJsBytes: outputs.find(x => x.path === 'pskernel-core/index.js').size,
}));
