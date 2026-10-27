# ProofScript PSC1

This package owns one qualified shared compiler implementation and the normal
ProofScript CLI. The default install includes JS/TS executors, the four core
output emitters, and a genuine independent official Lean 4.35.0 checker compiled
with Emscripten to linear-memory Wasm.

Install the unpublished .12 tarball from its matching CI cohort:

    npm install -g ./proofscript-0.1.0-psc1.12.tgz
    psc --help
    psc init --kind lean
    psc check Main.lean
    psc build Main.lean --target js --out dist/app

No installation script downloads binaries, installs a native SDK, or builds the
compiler from source. Rust/Wasm compiler execution engines, native checking,
Python/PHP providers, and target SDKs remain explicit optional installations.
Their existing runtime/platform and ABI constraints still apply.

The public programmatic API exports compile, build, compileCandidate,
getCompilerMetadata, checkCanonicalAdmissions and the existing publication/kernel
helpers. Independent checking and strict original/transformed IR validation
remain part of checked compilation. Candidate APIs have no publication authority.

Other existing @proofscript packages provide source interfaces or transparent
adapters to this owner. There is no duplicate compiler bundle in each package.
Private elaborator/Core functions are not exposed through fabricated exports.

From the repository checkout, npm run build creates dist from pinned qualified
inputs, npm run clean removes dist, and npm pack creates the release tarball.
The generated provider/compiler bodies retain their original qualification
identities. The .12 distribution does not claim new modular G2/G3 fixed points.
Canonical source and old successful CI evidence remain preserved.

[Build, package inventory and limitations](../../docs/guides/npm-packages.md).
Apache-2.0; upstream notices are retained. No registry publication is authorized.
