import assert from 'node:assert/strict';
import {chmod} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {checkCanonicalAdmissions as checkNative} from '../../pskernel-lean/index.mjs';
import {checkCanonicalAdmissions as checkWasm} from '../index.mjs';

const here=path.dirname(fileURLToPath(import.meta.url));
const nativeBinaryPath=path.resolve(
  here,
  '../../pskernel-lean/prebuilt/linux-x64/psc2_lean_kernel_provider',
);
const wasmLauncherPath=path.resolve(here,'../wasm/pskernel-lean.cjs');

// Git archives can lose executable intent in some consumers. The differential
// gate is about provider semantics, so make the checked-in Linux fixture
// executable explicitly before invoking it.
await chmod(nativeBinaryPath,0o755);

const acceptedRequest='{"protocol":"pskernel-lean/1","format":"proofscript-checked-admissions","version":2,"admissions":[{"kind":"constant","declaration":{"h":{"h":"1","k":"regular"},"k":"definition","lp":[],"n":{"k":"s","p":{"k":"a"},"v":"Differential.True"},"s":"safe","t":{"k":"const","ls":[],"n":{"k":"s","p":{"k":"a"},"v":"Nat"}},"v":{"k":"nat","v":"1"}}}]}';

const rejectedRequest='{"protocol":"pskernel-lean/1","format":"proofscript-checked-admissions","version":2,"admissions":[{"kind":"constant","declaration":{"h":{"h":"1","k":"regular"},"k":"definition","lp":[],"n":{"k":"s","p":{"k":"a"},"v":"Differential.Bad"},"s":"safe","t":{"k":"const","ls":[],"n":{"k":"s","p":{"k":"a"},"v":"Nat"}},"v":{"k":"sort","l":{"k":"z"}}}}]}';

const fixtures=[
  {name:'accepted',source:acceptedRequest,accepted:true,errorKind:undefined},
  {name:'kernel-rejection',source:rejectedRequest,accepted:false,errorKind:'kernel-rejection'},
  {name:'malformed',source:'{',accepted:false,errorKind:'malformed-request'},
];

for(const fixture of fixtures){
  const nativeResult=checkNative(fixture.source,{binaryPath:nativeBinaryPath});
  const wasmResult=await checkWasm(fixture.source,{launcherPath:wasmLauncherPath});

  assert.deepEqual(
    wasmResult,
    nativeResult,
    `${fixture.name}: WASM response must exactly match native Lean provider`,
  );
  assert.equal(nativeResult.accepted,fixture.accepted,`${fixture.name}: accepted`);
  if(fixture.errorKind!==undefined){
    assert.equal(nativeResult.errorKind,fixture.errorKind,`${fixture.name}: errorKind`);
  }
}

console.log('PSC2_LEAN_KERNEL_WASM_DIFFERENTIAL: PASS');
