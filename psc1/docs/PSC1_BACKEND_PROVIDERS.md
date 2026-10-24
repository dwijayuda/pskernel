# PSC1 backend providers and npm package split

This is the native distribution/provider milestone. It does not claim a new
unified generated compiler or a new G1/G2/G3 fixed point.

The [finite contract](../BACKEND_PROVIDER_CONTRACT.json) defines five default
output targets: JS, TypeScript, Rust, Wasm core and Wasm component. The unpublished
`proofscript@0.1.0-psc1.3` package contains the core CLI/native compiler, independent
Lean checking integration and those emitters. `@proofscript/backend-python` and
`@proofscript/backend-php` are explicitly installed matching add-on tarballs.
They are not core dependencies or npm `optionalDependencies`.

The package builder is `scripts/npm-native-distribution.mjs`. It retains three
installable unpublished tarballs and exact receipts in
`dist/scoped-correctness/npm-native/`. No registry publication is performed.
Linux x64/glibc and Node>=22 are the qualified platform scope. Cross-platform
packages and a generated compiler distribution remain separate milestones.

## Provider boundary

1. The core captures and elaborates the original source, independently checks
   the logical graph with official Lean4.35.0, validates the runtime IR, checks
   the requested public ABI and constructs the existing closed specialization plan.
2. The host serializes only that IR, public names and the IO ABI flag. Native
   JSON adapters are host-only and do not enter the portable compiler closure.
   This is not a change to portable `psc1-ir/1`.
3. The core resolves only the explicit matching target package, reads its JSON
   manifest without loading a JavaScript package entrypoint, and compares its
   complete descriptor with the expected provider identity pinned by the core
   distribution. Exact compiler source, Lean identity, target, protocol,
   native bytes and runtime resource identities must match.
4. Each optional worker links its existing emitter and strict IR/ABI validator.
   It does not link the PSC1 frontend, independent admission host or artifact
   publisher. It revalidates the serialized IR/ABI and returns a candidate.
5. The core checks response identity, exact public names/ABI and request hash,
   writes output in its private stage, runs existing target syntax/runtime/ABI
   tooling, seals provenance and publishes using the existing atomic pointer.
   Missing, incompatible, corrupted or malformed providers never authorize output.

The process protocol is `psc1-backend-provider/1`; its native JSON representation
is tied to exact compiler-source and Lean identities. Requests and responses are
bounded at64MiB; identity timeout10s and emission timeout120s match the existing
host tooling envelope. Compiler semantics, original/transformed strict IR
validation, independent checking, unsupported ABI refusals and self-host
240/1800/3600s profiles are unchanged.

This first protocol deliberately permits only the existing Python/PHP targets.
It is not unrestricted language-plugin or kernel-authority support. Portable
source-library metadata still rejects plugin/kernel/FFI/runtime authority.
Providers are qualified compiler components; admission and well-typed IR alone
are not a proof of backend semantic preservation.

## Installation and resources

Use the tarball names recorded in the successful Actions receipt. For example,
from a directory containing the three qualified artifacts:

```sh
npm install ./proofscript-0.1.0-psc1.3.tgz
npm install ./proofscript-backend-python-0.1.0-psc1.3.tgz
npm install ./proofscript-backend-php-0.1.0-psc1.3.tgz
```

The two add-on installs are independent. A requested absent target reports
`PSC1_BACKEND_PROVIDER_MISSING`. `psc --identity` reports five built-in targets,
two optional targets and the provider protocol. Native workspace development
uses explicit `lake build psc1_backend_python psc1_backend_php` workers instead of
npm packages; no such fallback is permitted in an installed distribution.

Python resources export at
`@proofscript/backend-python/runtime/typed_io.py` and
`@proofscript/backend-python/runtime/generated-python-transport.py`.
PHP resources export at
`@proofscript/backend-php/runtime/typed-io.php` and
`@proofscript/backend-php/runtime/generated-php-transport.php`.
These backend resources are absent from the core tarball. The retained
`typed_io_component.py` in core belongs to the Wasm component consumer, not the
optional Python output backend. Node/Wasm adapters and the locked Rust adapter
remain in the core package.

The workers use the matching core package's bundled Lean native libraries;
installed `ldd` checks must show no dependency on the build toolchain location.
Target execution/checking still requires the relevant target tools. Installing
a Python/PHP output provider does not turn the compiler into a Python/PHP
execution engine.

## Qualification and stopping criteria

- Exact core/worker symbol inventories prove the intended dependency boundary.
- Worker wire output matches every field of the retained in-process emitters;
  complete IR values survive transport; malformed schemas/identity/IR refuse.
- Offline local core installation has no optional emitters/resources/dependencies.
  Both source grammars compile and execute all five default outputs, including an
  independent TypeScript consumer and native Rust/component consumers.
- Explicit independent offline add-on installs execute Python/PHP in both
  grammars. Missing/pin/source/target/schema/binary/resource failures preserve
  previous output. A rewritten provider's own hash cannot authorize its new binary.
- Existing offline local/global core, source-library, installed typed IO and
  runtime-resource checks remain. All existing seven-target/both-grammar/full
  Practical Core regression requirements remain mandatory.
- Exact source, tested merge tree, run/job IDs, tarball hashes, protocol receipts
  and regression artifacts are recorded before stopping. No merge/publication.

Further work after this verified slice: portable provider interfaces where
needed, one generated multi-backend composition root, and genuine enlarged
G1→G2→G3/fixed points for each claimed compiler execution engine. Preserve all
older qualifications on their exact historical source snapshots.

## Verified checkpoint

Full [40106542849](https://github.com/dwijayuda/pskernel/actions/runs/40106542849) PASSED: Linux120912148533/final gate120918578150;37/37 criteria,0 blocked,releaseReady=true; all seven backends/both grammars, applications, minimum-Python and installed package/IO/library checks. Review70522c25ea3826c05ba2e80f7f1e9c7df0b58213 and tested merge063d1da64db9beb69a8303af5a2a8788233dc7dd have identical Git treeb2d2ad3e24a07218c081eb20bc85670fd64e29e4. Artifact12566181617,sha256:be0a4ed3850383345acfbf2127d34caa32154ed6c5f8ac10304edd3d54899957.

Focused40105565252 PASSED at971718f5; normal full CI also requires the exact-commit provider boundary receipt. Three matching unpublished tarballs are retained in the full artifact; see the [machine receipt](PSC1_BACKEND_PROVIDER_QUALIFICATION_2026-10-24.json) for exact hashes. The requested milestone is complete and stopped. [Continuation](PSC1_BACKEND_PROVIDER_CONTINUATION.md).
