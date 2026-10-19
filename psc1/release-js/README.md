# PSC0 JavaScript bundle (isolated release branch)

This branch starts at main commit 748ee630e43ee1a89643cbc8cec3e31087788b08 and does not change the semantics of PSC0 or PSKernel Core.

GitHub Actions workflow: .github/workflows/psc0-js-bundle.yml.

The release workflow uses PSC0's Lean-native frontend and TypeScript 7.0.2
to compile the original self-host compiler root and the new 79-module
packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean source into separate
ES2022 JavaScript ES modules. The two module-discovery entries in
workspace-layout.mjs and ProjectCompiler.lean are host-only namespace
routing for the existing KernelCore source root; no kernel source is altered.

GitHub Actions uploads one ZIP artifact containing compiler/, pskernel-core/,
package.json, README.md and MANIFEST.json. Before upload it verifies the
compiled module imports and required exported APIs, and
hashes every output. It fails instead of publishing if compilation or smoke
testing fails.

This is an executable candidate, not a formally qualified runtime checker.
The smoke gate does not claim kernel operation-level or differential conformance.
The workflow does not assert kernel metatheory, native-versus-JS differential
compatibility, new self-host fixed point, full PSCV support, or checker promotion.

No historical legacy kernel JS is substituted for the new Core source.
