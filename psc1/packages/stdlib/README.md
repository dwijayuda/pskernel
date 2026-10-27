# @proofscript/stdlib

Optional PSC1 source package. The existing canonical sources remain under `psc1/stdlib/ProofScript`; the npm distribution stages these unchanged Lean sources or the supported Lean-to-PS translations as `src/ProofScript/...`. Consumers explicitly install and register the library in `package.json` through explicit source capture; reserved namespaces retain the existing compiler policy.

Not installed by `npm install -g proofscript`. This package is currently experimental; source conformance and stable module ABI have not been claimed.

## npm package build

This is a source package. Its default API exposes sourcePackage and readSources; it does not export the compiler's private internal functions or provide a proof checker. The ./compiler entry transparently re-exports the existing checked proofscript API.

Build from this directory with npm run build, clean generated dist with npm run clean,
and create a tarball with npm pack. Builds use the pinned qualified inputs and the
workspace scripts; installation has no build or download hooks. Registry publication
is not authorized. See [the package guide](../../docs/guides/npm-packages.md).
