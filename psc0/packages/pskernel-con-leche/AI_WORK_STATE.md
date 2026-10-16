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
  PR #109 are untouched.

## Qualification

At creation these are source candidates, NOT yet CI-qualified. The new workflow
must build the native executable, run focused tests/CLI protocol checks, and
build the proof target on the same commit before package acceptance is claimed.
Full PSC0/Standard/source/target integration is intentionally NOT claimed, even
if this package's focused gates pass. No self-host tests are required.

## Next implementation

First inspect the exact package CI result and fix genuine build/runtime issues.
Then follow ARCHITECTURE.md section 5: complete Core/Standard-to-export bridge,
host-owned requested dual-check integration, differential/negative qualification,
source-correspondence evidence and measured resource behavior. Never enable an
alternative authority or relax the input axioms just to make a test pass.
