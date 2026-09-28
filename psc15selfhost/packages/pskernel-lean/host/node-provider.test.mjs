import assert from 'node:assert/strict';
import {checkCanonicalAdmissions} from './node-provider.mjs';

const binaryPath=process.env.PSC_LEAN_KERNEL_PROVIDER_BIN;
assert.ok(binaryPath,'PSC_LEAN_KERNEL_PROVIDER_BIN must point at the built provider');

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
assert.equal(accepted.accepted,true);

const rejected=checkCanonicalAdmissions(
  payload([definition('nodeRejected',{k:'sort',l:{k:'z'}})]),
  {binaryPath},
);
assert.equal(rejected.protocol,'pskernel-lean/1');
assert.equal(rejected.accepted,false);
assert.equal(rejected.errorKind,'kernel-rejection');
assert.equal(rejected.declarationIndex,0);

assert.throws(
  ()=>checkCanonicalAdmissions('{}',{binaryPath:'/definitely/missing/pskernel-lean'}),
  /failed to start Lean kernel provider/,
);

console.log('PSC2_LEAN_KERNEL_NODE_ADAPTER_TESTS: PASS');
