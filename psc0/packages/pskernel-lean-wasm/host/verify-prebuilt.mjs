import {verifyWasmPrebuiltManifest} from './prebuilt.mjs';

const manifest=verifyWasmPrebuiltManifest();
console.log(
  `PSC2_LEAN_KERNEL_WASM_PREBUILT_VERIFY: PASS ${manifest.artifacts.wasm.bytes} bytes ${manifest.sourceCommit}`,
);
