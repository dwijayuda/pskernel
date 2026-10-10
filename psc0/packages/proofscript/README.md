# proofscript

Metapackage that bundles all nineteen `@proofscript/*` modules, TypeScript 7.0.2, and the Node `psc` CLI.

**Development source only.** Run the cloud `psc0-npm-distribution.yml` workflow to build npm tarballs and source variants. Installing a repository directory before building does not supply compiled JS. Do not publish to npm without a successful installed-package acceptance run.

The JavaScript `@proofscript/pskernel-core` runtime is a candidate, not the selected trusted checking provider. The installed `psc` CLI uses the pinned `@proofscript/pskernel-lean-wasm` checker for its admitted builds.
