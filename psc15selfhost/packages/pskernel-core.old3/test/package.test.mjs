import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import * as api from '@proofscript/pskernel-core.old3';
const manifest=JSON.parse(await readFile(new URL('../package.json',import.meta.url),'utf8'));
test('exports only immutable non-authoritative metadata',()=> {
  assert.deepEqual(Object.keys(api),['kernelInfo']);
  assert.equal(Object.isFrozen(api.kernelInfo),true);
  assert.equal(api.kernelInfo.canCheckProofs,false);
  assert.equal(api.kernelInfo.authoritative,false);
  assert.equal(api.kernelInfo.status,'experimental-term-checker');
  assert.equal(api.kernelInfo.compatibilityEvidence,'bounded-checker-fragment-not-full-compatibility');
});
test('package identity matches metadata and has no runtime dependencies',()=> {
  assert.equal(manifest.name,api.kernelInfo.name);
  assert.equal(manifest.version,api.kernelInfo.version);
  assert.deepEqual(manifest.dependencies,{});
  assert.equal(manifest.optionalDependencies,undefined);
  assert.equal(manifest.peerDependencies,undefined);
});
test('publication and compiler authority remain disabled',()=> {
  assert.equal(manifest.private,true);
  assert.equal(manifest.proofscript.bootstrap,false);
  assert.equal(manifest.proofscript.authoritative,false);
  assert.equal(manifest.proofscript.portable,true);
  for(const hook of ['preinstall','install','postinstall','prepare']) assert.equal(manifest.scripts[hook],undefined);
});
test('Lean target is pinned, not a compatibility claim',()=> {
  assert.equal(api.kernelInfo.targetLeanVersion,'4.34.0');
  assert.equal(api.kernelInfo.targetLeanCommit,'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
  assert.equal(api.kernelInfo.nativeEvaluation,'excluded-from-target-profile');
});
test('internal generated representation has no public package export',async()=> {
  await assert.rejects(import('@proofscript/pskernel-core.old3/dist/foundation.js'),{code:'ERR_PACKAGE_PATH_NOT_EXPORTED'});
});
