# KernelContract-v1

Target: Lean 4.35.0-rc4, source commit
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Import
`Ps.KernelCore.API.Kernel` for the stable checked-session entry points.
The existing low-level APIs remain available for compatibility. This contract
adds checked wrappers around the same semantic implementation; it does not
change the default provider or introduce fallback checking.

## Values and operations

`PsKernelDeclarationRequest` is untrusted input. It covers axioms, definitions,
theorems, opaque declarations, mutual definitions, Quot initialization, and
ordinary/mutual/nested inductives. Unsupported protocol variants can be represented
explicitly and are declined.

Create a `PsKernelKernelSession` with `psKernelKernelSessionEmpty`, a
`PsKernelResourcePolicy`, and a `PsKernelProviderCapability`. The default provider
has no native evaluator. Legacy evaluator fields remain source-compatible,
but the 4.35 checker never invokes them and they cannot authorize reduction. Provider target identity must
match the contract, Lean version, and source commit, including on every operation.

| Entry point | Successful payload | State effect |
| --- | --- | --- |
| `psKernelV1CheckDeclaration` | `PsKernelCheckedDeclaration` | Checks the entire admission transaction without committing it |
| `psKernelV1AdmitDeclaration` | `PsKernelAdmissionResult` | Returns a new session after successful checked admission |
| `psKernelV1AdmitChecked` | `PsKernelAdmissionResult` | Rechecks the recorded request in the current session before admission |
| `psKernelV1CheckExpression` | `PsKernelCheckedExpression` | Full checking, never the infer-only cache path |
| `psKernelV1Whnf` | `PsKernelExpr` | Fully checks the input before reducing it |
| `psKernelV1IsDefEq` | `Bool` | Fully checks both inputs before comparing them |

Sessions are immutable values. Failure produces no replacement session. Inductive
auxiliaries and generated recursors remain subject to the existing validation and
commit rules. Native capability configuration resides in the public session;
returned declaration history excludes it. Legacy low-level environment wrappers
retain their configuration field for compatibility.

## Outcome representation

Every entry point returns `Except PsKernelError Payload`. `Except.ok` means
`PsKernelOutcome.accepted` and carries the operation's typed payload.
`psKernelErrorOutcome` maps the four error constructors to the other outcome tags:

- `rejectedInvalid`: a known input-validation failure;
- `declinedUnsupported`: an unsupported request, target, or admission mode;
- `resourceExhausted`: explicit fuel, recursion depth, numeral-size, cancellation,
  or declaration-count policy;
- `internalError`: a checker invariant failure or unrecognized diagnostic,
  including unknown provider failures.

The implementation uses the PSC0-supported `Except` type instead of a
new datatype with runtime type parameters. `KERNEL_DIAGNOSTICS.json` records the
exact mapping of existing checker diagnostics. Unknown messages are conservative
internal failures. Every non-accepted outcome fails closed; no alternate checker,
retry, or provider promotion is performed.

## Resource policy

`fuel` is the existing recursive bound, not a consumed-instruction counter. Each
declaration operation receives the configured bound, including each phase of a
bundle. Zero fuel declines entry. `maxRecDepth` preserves the existing factor of
16 and zero/unbounded convention; `maxNatSize` preserves current numeral policy.

`cancelled` is sampled before the operation. The pure portable checker does not
support asynchronous interruption inside a call. `maxDeclarations` bounds the
total constants in the resulting environment, including generated declarations;
zero means no count limit. A bundle exceeding the limit yields no new session.
Receipts report environment sizes before and after checking, not fuel consumed.

The host owns stack and memory limits. Portable code cannot catch a host stack
overflow or process termination. An external adapter that catches such a failure
must report a resource/internal failure, never acceptance. `hostStack` is the
typed resource category available to that adapter; this library does not claim
to have intercepted such host failures.

## Trust boundary and receipt meaning

Requested, checked, and admitted values have distinct types. A
`PsKernelCheckingReceipt` is a process-local observation of target and declaration
counts. It is not signed, cryptographic, serializable admission authority, or a
proof certificate. Checked values never bypass admission: `psKernelV1AdmitChecked`
rechecks, so stale or manufactured receipts cannot authorize an invalid request.

The current PSC0 source profile exposes record constructors. Directly constructing a
session with an unchecked low-level environment belongs to the trusted
integration boundary. Callers handling untrusted inputs must start with the empty
session and extend it only through successful admission. This contract is an API
discipline, not a memory-isolation boundary against code that can call unchecked
environment constructors. Provider adapters translate requests and typed results;
they must not implement another semantic checker or fallback after failure.

## Evidence

`test/KernelCore/Foundation/KernelContract.lean` covers exact diagnostic
classification, checking versus admission, stale and fabricated receipts, invalid
applications (including reflexive equality), cancellation, zero fuel, declaration
limits, target mismatch and unknown provider failure. It is included in the
foundation executable in the 4.35 cloud workflow. Historical portable and
differential receipts do not qualify the migrated package.
