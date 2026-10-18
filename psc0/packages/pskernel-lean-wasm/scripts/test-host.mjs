import assert from 'node:assert/strict';
import {test} from 'node:test';
import {createKernel,checkCanonicalAdmissions,kernelStatus,KernelNotReadyError,
  leanKernelProviderCommit,leanKernelProviderProfile} from '../index.mjs';
test('4.35.0/v7.2 identities are explicit',()=>{
  assert.equal(leanKernelProviderCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(leanKernelProviderProfile,'pscv0-v7.2');
});
test('missing or unqualified binary fails closed, never returns rejection',async()=>{
  if(kernelStatus().checkerReady)return; // Qualified bundle has separate smoke tests.
  await assert.rejects(createKernel(),e=>e instanceof KernelNotReadyError);
  await assert.rejects(checkCanonicalAdmissions('{"format":"proofscript-checked-admissions","version":2,"admissions":[]}'),
    e=>e instanceof KernelNotReadyError);
});
test('reject unverified launcher overrides',async()=>{
  await assert.rejects(createKernel({launcherPath:'/tmp/mock-kernel.cjs'}),e=>e instanceof KernelNotReadyError);
});
