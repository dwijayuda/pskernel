import assert from 'node:assert/strict';
import {
  checkCanonicalAdmissions,
  defaultLeanKernelProviderBinary,
  leanKernelProviderCommit,
} from './node-provider.mjs';

const binaryPath=defaultLeanKernelProviderBinary();
assert.match(binaryPath,/psc2_lean_kernel_provider(?:\.exe)?$/);
assert.equal(
  defaultLeanKernelProviderBinary({
    platform:'linux',
    arch:'x64',
    env:{PSC_LEAN_KERNEL_PROVIDER_BIN:'/custom/provider'},
  }),
  '/custom/provider',
);

const rootName=value=>({k:'s',p:{k:'a'},v:value});
const natType={k:'const',ls:[],n:rootName('Nat')};
const definition=(name,value)=>({
  kind:'constant',
  declaration:{
    h:{h:'1',k:'regular'},
    k:'definition',
    lp:[],
    n:rootName(name),
    s:'safe',
    t:natType,
    v:value,
  },
});
const payload=admissions=>JSON.stringify({
  admissions,
  format:'proofscript-checked-admissions',
  version:2,
});

const accepted=checkCanonicalAdmissions(
  payload([definition('nodeAccepted',{k:'nat',v:'1'})]),
  {binaryPath},
);
assert.equal(accepted.protocol,'pskernel-lean/1');
assert.equal(accepted.provider,'lean4-cpp');
assert.equal(accepted.leanVersion,'4.34.0');
assert.equal(
  accepted.leanCommit,
  '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
);
assert.equal(accepted.leanCommit,leanKernelProviderCommit);
assert.equal(accepted.accepted,true);

const rejected=checkCanonicalAdmissions(
  payload([definition('nodeRejected',{k:'sort',l:{k:'z'}})]),
  {binaryPath},
);
assert.equal(rejected.protocol,'pskernel-lean/1');
assert.equal(rejected.leanCommit,leanKernelProviderCommit);
assert.equal(rejected.accepted,false);
assert.equal(rejected.errorKind,'kernel-rejection');
assert.equal(rejected.declarationIndex,0);

assert.throws(
  ()=>checkCanonicalAdmissions('{}',{binaryPath:'/definitely/missing/pskernel-lean'}),
  /failed to start Lean kernel provider/,
);

console.log('PSC2_LEAN_KERNEL_NODE_ADAPTER_TESTS: PASS');
