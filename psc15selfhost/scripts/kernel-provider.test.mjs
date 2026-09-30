import assert from 'node:assert/strict';
import {
  checkWithKernelProvider,
  kernelProviderOptions,
  kernelProviderSpec,
} from './kernel-provider.mjs';

const native=kernelProviderSpec('lean434');
assert.equal(native.packageName,'@proofscript/pskernel-lean');
assert.equal(native.localEntry,'../packages/pskernel-lean/index.mjs');
assert.equal(native.overrideKey,'binaryPath');

const wasm=kernelProviderSpec('lean434-wasm');
assert.equal(wasm.packageName,'@proofscript/pskernel-lean-wasm');
assert.equal(wasm.localEntry,'../packages/pskernel-lean-wasm/index.mjs');
assert.equal(wasm.overrideKey,'launcherPath');

assert.deepEqual(
  kernelProviderOptions('lean434',{binaryPath:'/tmp/native-provider'}),
  {binaryPath:'/tmp/native-provider'},
);
assert.deepEqual(
  kernelProviderOptions('lean434-wasm',{launcherPath:'/tmp/wasm-provider.cjs'}),
  {launcherPath:'/tmp/wasm-provider.cjs'},
);
assert.deepEqual(kernelProviderOptions('lean434',{}),{});
assert.deepEqual(kernelProviderOptions('lean434-wasm',{}),{});

let observed;
const asyncWasmProvider={
  async checkCanonicalAdmissions(source,options){
    await Promise.resolve();
    observed={source,options};
    return {accepted:true,provider:'lean4-cpp',leanVersion:'4.34.0'};
  },
};
const asyncResult=await checkWithKernelProvider(
  'lean434-wasm',
  'canonical-admissions',
  {launcherPath:'/tmp/wasm-provider.cjs',providerModule:asyncWasmProvider},
);
assert.equal(asyncResult.accepted,true);
assert.deepEqual(observed,{
  source:'canonical-admissions',
  options:{launcherPath:'/tmp/wasm-provider.cjs'},
});

const syncNativeProvider={
  checkCanonicalAdmissions(source,options){
    return {accepted:source==='native-admissions',options};
  },
};
const nativeResult=await checkWithKernelProvider(
  'lean434',
  'native-admissions',
  {binaryPath:'/tmp/native-provider',providerModule:syncNativeProvider},
);
assert.equal(nativeResult.accepted,true);
assert.deepEqual(nativeResult.options,{binaryPath:'/tmp/native-provider'});

assert.throws(
  ()=>kernelProviderSpec('unknown'),
  /PSC2_KERNEL_PROVIDER: expected lean434 or lean434-wasm, got unknown/,
);

console.log('PSC2_KERNEL_PROVIDER_SELECTOR_TESTS: PASS');
