# PSC1 native npm package — current work state

Updated 2026-10-20. Work is on draft PR #165, stacked on Practical Core PR #163.
The previous PSC0 distribution work state is preserved
[verbatim](docs/history/NPM_PACKAGE_WORK_STATE_BEFORE_NATIVE_2026-10-20.md).

## Current implementation

The `psc` workspace command now launches `npm-cli/psc.js`, which validates and
executes the same checked native Lean compiler as the direct entrypoint.
`scripts/npm-native-distribution.mjs` builds an unpublished
`proofscript@0.1.0-psc1.2` tarball containing the native executable, all seven built-in
backends, compiled prelude/admission provider, source pin, host tools and locked
production dependencies. No generated PSC0 compiler or checker is a fallback.

The package has passed offline local and global installation and generated JS
execution in Linux CI. The installed native entrypoint locates its bundled host
files independently. The package remains private and unpublished; no merge,
release or registry publication is authorized or performed.

## Optional source libraries

The native import capture path invokes the declarative source resolver with the
actual importing file. The version-2 metadata contract specifies source kind,
namespace, public modules, declared dependencies and exact compiler/Lean profile.
Nested installed versions resolve relative to the importing package. Guest JavaScript
is never executed to resolve source. Metadata supplies no admission authority.

The actual two-library tarball canary passes: four captured source files,
independent native checking, public `answer = 42`, private declarations hidden.
Private-module imports, an incompatible pin and an ill-typed transitive source fail
while preserving previous output. The canary uses local unpublished tarballs;
registry fetching of transitive dependencies is outside its claim.

## Evidence and commands

See [backend conformance](docs/PSC1_BACKEND_CONFORMANCE.md) for exact successful
commit/run evidence and [the npm guide](docs/PSC1_NPM_ECOSYSTEM.md) for metadata
examples, installation and limitations.

Current commands are `npm run npm:pack:native` and `npm run test:npm-libraries`.
Historical aliases are `npm:archive:psc0` and `npm:inspect:psc0`.
Tarballs and receipts are retained in the focused Actions artifact under
`npm-native/`; `SEVEN_BACKEND_QUALIFICATION.json` consolidates runtime and package evidence.

Initial package qualification is Linux x64/glibc, Node >=22. Target runtimes remain
separate requirements. The current compiler stays authored in Lean and built
natively; no self-host compiler/kernel regeneration or fixed-point run is claimed.
