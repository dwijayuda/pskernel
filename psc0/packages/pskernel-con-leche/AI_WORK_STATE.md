# PSKernel Con Leche work state

## Scope and provenance

Created on `feature/psc0-pskernel-con-leche-v1` from active PSC0 branch
`psc0/pscv0-v7-native-lean-v1` at `77f5fe75ad2731c2d7e8445d7aa953c8d41827bb`.
Do not rebase onto main/PSC2/PS0 or overwrite the continuing native compiler
branch. Upstream pin is `b47ea19d6864a1fd09db6144528f91baa5c550dd` (Lean 4.35.0).

## Implemented candidate

- Standalone pinned Lake package and private npm metadata.
- Verified-only complete-NDJSON checking, PSC0 two-input-axiom policy, resource
  guards, distinct reject/decline/error results and input-indexed Lean evidence.
- Native CLI with fail-closed panic/IO handling and no publication capability.
- Focused positive, invalid, policy, malformed, chunking and budget tests.
- Separate proof target composing wrapper acceptance with upstream model_exists.
- Dedicated package-only cloud CI; active host, kernels, backend sources and
  PR #109 are untouched. CI includes five process-level protocol/verdict cases,
  an actual theorem-axiom audit, and logs pinned to the source commit.

## Observed qualification and corrections

- Initial source `dccac0c438cfaedd375a5baf23ed02740f4168ee`, run `38949923855`:
  toolchain/upstream pins passed; imported upstream runtime modules built.
  The wrapper's multiline policy diagnostic had a Lean layout error.
- Correction `6c441087c7c38a05986d93465c86b5c4c3d2f294`, run `38950601637`:
  wrapper library and native test executable built; the CLI usage string had
  another layout error. Runtime tests and proofs did NOT run.
- Correction `594aa87437d37371c7bab0cbfc368b436ae8f3c3`, run `38951418065`:
  full native build SUCCEEDED (checker library, CLI and tests; 156 build jobs).
  Valid Nat definition, chunk split, fresh repeat and invalid False theorem
  tests PASSED. The fifth test returned the wrong phase/code; the combined
  runtime test step failed, so CLI process cases and proof gates did NOT run.
- Root cause verified in pinned `ConLeche/Frontend/Scan/Fast.lean`,
  `scanAxiomDeclLoop`: an axiom record admits `isUnsafe`, `levelParams`, `name`
  and `type`, NOT the `all` field allowed on definitions/theorems. The original
  policy fixture was malformed and never reached the policy audit. This
  checkpoint corrects the fixture, preserves a separate malformed-axiom test,
  and reports actual phase/code/error on any future mismatch. No policy or
  checker acceptance rule was changed to satisfy the test.

The current corrected suite has 13 focused cases. Its full runtime result,
the five CLI operations, proof target and actual axiom audit remain pending
until the exact new source commit's CI passes.

A saved incremental compiler cache is build acceleration, NEVER acceptance or
proof evidence. CI checks the upstream revision and clean tracked sources before
using it, and re-elaborates this wrapper's axiom report on every qualifying run.
Full PSC0/Standard/source/target integration is intentionally NOT claimed, even
if this package's focused gates pass. No self-host tests are required.

## Next implementation

First inspect the exact package CI result and fix genuine build/runtime issues.
Then follow ARCHITECTURE.md section 5: complete Core/Standard-to-export bridge,
host-owned requested dual-check integration, differential/negative qualification,
source-correspondence evidence and measured resource behavior. Never enable an
alternative authority or relax the input axioms just to make a test pass.
