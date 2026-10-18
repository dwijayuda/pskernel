import {createKernel,kernelStatus} from '../index.mjs';
if(!kernelStatus().checkerReady)throw new Error('Wasm bundle is unavailable/unqualified');
const kernel=await createKernel();
if(kernel.metadata.status!=='ok')throw new Error('Lean 4.35 Wasm health failed');
console.log('PSC0_WASM_PREBUILT_VERIFIED');
