import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const workspaceRoot=path.resolve(packageRoot,'../..');

const manifest=JSON.parse(await readFile(path.join(packageRoot,'package.json'),'utf8'));
assert.equal(manifest.name,'@proofscript/pskernel-lean-wasm');
assert.equal(manifest.version,'4.34.0');
assert.equal(manifest.type,'module');
assert.equal(manifest.private,false);
assert.equal(manifest.proofscript?.bootstrap,false);
assert.equal(manifest.proofscript?.portable,false);
assert.equal(manifest.proofscript?.role,'external-lean-kernel-provider-wasm');

const leanPin=JSON.parse(await readFile(path.join(packageRoot,'LEAN_SOURCE_PIN.json'),'utf8'));
assert.equal(leanPin.leanVersion,'4.34.0');
assert.equal(leanPin.leanCommit,'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
assert.equal(leanPin.protocol,'pskernel-lean/1');
assert.equal(leanPin.provider,'lean4-cpp');
assert.equal(leanPin.profile,'lean4.34-core');

const emscriptenPin=JSON.parse(await readFile(path.join(packageRoot,'EMSCRIPTEN_PIN.json'),'utf8'));
assert.equal(emscriptenPin.version,'6.0.9');
assert.notEqual(emscriptenPin.version,'latest');
assert.notEqual(emscriptenPin.version,'tot');

const rootIndex=await readFile(path.join(packageRoot,'index.mjs'),'utf8');
assert.match(rootIndex,/createKernel/);
assert.match(rootIndex,/checkCanonicalAdmissions/);

const closure=await readFile(path.join(workspaceRoot,'scripts/bootstrap-closure-contract-tests.mjs'),'utf8');
assert.match(closure,/pskernel-lean-wasm/);

console.log('PSC2_LEAN_KERNEL_WASM_PACKAGE_CONTRACT: PASS');
