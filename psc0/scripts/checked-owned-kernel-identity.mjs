import { readFileSync } from 'node:fs';

// Historical generated-owned transport only; never a protected provider selector.
const build = JSON.parse(readFileSync(new URL('../legacy/packages/pskernel-core/manifests/BUILD.json', import.meta.url), 'utf8'));
export const ownedCheckedIdentity = Object.freeze({
  protocol: 'pskernel-core/1', provider: 'psc-generated-owned',
  version: build.packageVersion, profile: 'owned-uniform-algebraic/11',
  sourceManifestSha256: build.sourceManifestSha256,
  generatedKernelSha256: build.outputs.find(item => item.path === 'dist/foundation.js').sha256,
});
