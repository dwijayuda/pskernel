import {statSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {
  leanKernelProviderTargetKey,
  loadLeanKernelPrebuiltManifest,
  verifyLeanKernelPrebuiltBinary,
} from './prebuilt.mjs';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const target=leanKernelProviderTargetKey();
const manifest=loadLeanKernelPrebuiltManifest({packageRoot});
const entry=manifest.targets[target];
const binaryPath=path.resolve(packageRoot,...entry.path.split('/'));
verifyLeanKernelPrebuiltBinary({binaryPath,target,manifest,packageRoot});
const bytes=statSync(binaryPath).size;
if(bytes!==entry.size){
  throw new Error(`Lean kernel prebuilt size mismatch for ${target}: expected ${entry.size}, got ${bytes}`);
}
console.log(`PSC2_LEAN_KERNEL_PREBUILT_VERIFY: PASS ${target} ${bytes} bytes ${manifest.sourceCommit}`);
