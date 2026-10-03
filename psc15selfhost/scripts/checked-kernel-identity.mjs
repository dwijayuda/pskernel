import { readFileSync } from 'node:fs';

export const leanCheckedIdentity = Object.freeze({
  protocol: 'pskernel-lean/1', provider: 'lean4-cpp', leanVersion: '4.34.0',
  leanCommit: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b', profile: 'lean4.34-core',
});
const build = JSON.parse(readFileSync(new URL('../packages/pskernel-core/manifests/BUILD.json', import.meta.url), 'utf8'));
export const ownedCheckedIdentity = Object.freeze({
  protocol: 'pskernel-core/1', provider: 'psc-generated-owned',
  version: build.packageVersion, profile: 'owned-uniform-algebraic/11',
  sourceManifestSha256: build.sourceManifestSha256,
  generatedKernelSha256: build.outputs.find(item => item.path === 'dist/foundation.js').sha256,
});

export function checkedKernelIdentity(selector) {
  if (selector === 'pskernel-core') return ownedCheckedIdentity;
  if (selector === 'lean434-wasm' || selector === 'lean434') return leanCheckedIdentity;
  throw new Error(`PSC2_CHECKED_KERNEL_UNSUPPORTED: ${selector}`);
}
