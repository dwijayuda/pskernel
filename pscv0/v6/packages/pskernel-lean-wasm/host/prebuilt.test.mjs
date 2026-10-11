import assert from 'node:assert/strict';
import {mkdtemp,mkdir,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {
  createWasmPrebuiltManifest,
  verifyWasmPrebuiltManifest,
} from './prebuilt.mjs';

const tempRoot=await mkdtemp(path.join(os.tmpdir(),'psc2-lean-wasm-prebuilt-'));
try{
  await mkdir(path.join(tempRoot,'wasm'),{recursive:true});
  await writeFile(path.join(tempRoot,'wasm','pskernel-lean.cjs'),'console.log("ok");\n');
  await writeFile(path.join(tempRoot,'wasm','pskernel-lean.wasm'),Buffer.from([0,97,115,109,1,0,0,0]));

  const manifest=createWasmPrebuiltManifest({
    packageRoot:tempRoot,
    sourceCommit:'0123456789abcdef0123456789abcdef01234567',
  });
  await writeFile(
    path.join(tempRoot,'PREBUILT_WASM_MANIFEST.json'),
    JSON.stringify(manifest,null,2)+'\n',
  );

  const verified=verifyWasmPrebuiltManifest({packageRoot:tempRoot});
  assert.equal(verified.protocol,'pskernel-lean/1');
  assert.equal(verified.provider,'lean4-cpp');
  assert.equal(verified.leanVersion,'4.34.0');
  assert.equal(verified.leanCommit,'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
  assert.equal(verified.emscriptenVersion,'6.0.9');
  assert.equal(verified.sourceCommit,'0123456789abcdef0123456789abcdef01234567');

  await writeFile(path.join(tempRoot,'wasm','pskernel-lean.wasm'),Buffer.from([0,97,115,109,1,0,0,1]));
  assert.throws(
    ()=>verifyWasmPrebuiltManifest({packageRoot:tempRoot}),
    /digest mismatch/u,
  );
}finally{
  await rm(tempRoot,{recursive:true,force:true});
}

// Exercise integrity through both public API entry points, not only the verifier.
await import('./prebuilt-api.test.mjs');

console.log('PSC2_LEAN_KERNEL_WASM_PREBUILT_INTEGRITY: PASS');
