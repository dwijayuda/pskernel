# Runtime semantics, effects and resources

**Proposed semantic policies.** Native Lean constructs keep pinned behavior. New names in this document, especially `Psc.Async`, denote ordinary library proposals, not implemented APIs or new kernel rules.

## 1. Logical and executable views

A total pure definition participates in logical computation and may have an executable realization. An IO or asynchronous computation can be described by a typed value without making every execution terminate or establishing the correctness of external services. Lean distinguishes effectful types from pure functions; its logical checking evaluation and runtime evaluation are different concerns. [L06](RESEARCH_SOURCES.md#lean-and-logical-foundations)

The target-neutral runtime relation must specify values, calls, allocations relevant to the model, observable effects, failure and divergence. Where a native construct's observable behavior is not yet covered, restrict executable coverage rather than invent a target-specific rule.

Claims distinguish partial correctness, termination, total correctness, safety properties over traces and environmental liveness assumptions. Resource exhaustion may be modeled as an allowed outcome or ruled out by proved bounds; it cannot be ignored while promising success on every finite machine.

## 2. Function evaluation and optimization

Effectful sequencing uses native `do`/bind or an explicitly defined library interpreter. The order of elaborating arguments is not permission to reorder external effects. Code motion, duplication and dead-code elimination require the appropriate purity and termination conditions.

Under a strict execution model, `first 1 (loopForever ())` does not necessarily behave like `1`. This is a design counterexample: it was not executed under Lean here. The partial function's runtime equations cannot be used as ordinary total equations without a separate justified relation. [L05](RESEARCH_SOURCES.md#lean-and-logical-foundations)

Closure conversion must preserve captured values and the relevant state discipline. A backend may use mutable cells internally only when that is a faithful representation of the admitted program. Copying a resource handle is not automatically allowed merely because copying an ordinary immutable record is allowed.

## 3. State and failure

Two different interfaces must stay different:

- `StateT S (Except E) A`: failure does not return a successful final-state pair.
- `ExceptT E (StateM S) A`: a final state accompanies either successful or failed computation.

A convenience alias must identify its stack. A parser's speculative logical rollback must restore its relevant internal state. It cannot roll back a filesystem write simply by discarding a state value.

Database transaction operations need a model of the actual transaction boundary, isolation/conflicts and retry semantics. A proof about an in-memory inventory transition is not a proof against concurrent database overselling.

## 4. Portable asynchronous library candidate

**Recommended application priority; experimental semantic profile until conformance closes.**

Do not redefine native Lean `Task`. Define a separately named library family `Psc.Async ε α` describing asynchronous computations and an explicit interpreter capability. Candidate operations are pure/return, bind, failure, start-in-scope, await, cancel request, timeout and bounded parallel traversal. Their exact signatures must be implementable using ordinary Lean data/functions under a recorded closure.

A recommended policy is **cold descriptions and explicit start**: constructing an Async value schedules nothing; interpreting it starts work. Reusing a description starts another computation, while sharing an already started handle awaits the same task. Native Promise adapters must account for the fact that an existing Promise may already be running; attaching a Promise is a different operation from starting a cancellable thunk. Promise semantics are a foreign reference, not PSC's definition. [E12](RESEARCH_SOURCES.md#application-and-javascript-platform)

### Lifecycle proposal

A started handle progresses from created to running, then exactly one of success, typed failure or cancelled. Cancellation is a request until a cancellation terminal event commits. A successful completion that committed first is not retroactively changed. Under races, permitted traces and the arbitration point must be specified; wall-clock identity across hosts is not promised.

The finite first-terminal-event model in the experiments only checks a small policy property. It does not establish scheduler correctness, fairness, cleanup or liveness.

Structured scope owns child handles. Scope completion requests cancellation for still-live children and observes their completion according to its declared policy. Uncooperative foreign work may prevent prompt shutdown; deadlines must not be advertised as unconditional termination guarantees. A force-detach escape is a separate explicit capability and disqualifies structured-completion claims for that operation.

A timeout measures a stated host clock/deadline policy. It does not prove that no remote side effect occurred. Late results are ignored or reconciled using an explicit request identity, not mistaken for rollback.

### Runtime bridge

For JS, specify queueing and Promise/AbortSignal adaptation; for Rust, specify executor and cancellation support; for Wasm, specify host imports and suspension/lifetime handling. Adapters must preserve the permitted trace set or report a narrower unsupported capability. Do not equate identical final values with identical effects.

## 5. Resource library candidate

Use an ordinary bracket-style API with explicit acquisition, body and release. The recommended outcome rules are:

| Situation | Required outcome policy |
|---|---|
| Acquisition fails | Do not call release for a handle never acquired. |
| Acquisition succeeds, body succeeds | Release once before reporting successful scoped completion. |
| Body fails | Release once; retain body error. |
| Release fails after body success | Report release failure; do not claim clean completion. |
| Body and release fail | Preserve both in a typed aggregate; do not silently lose the body error. |
| Cancellation after acquisition | Run the declared cleanup protocol before reporting scoped cancellation. |
| Process/engine termination | Outside exactly-once cleanup guarantee unless separately modeled. |

Exactly once here concerns the library's intended release invocation in its supported execution model, not proof that an arbitrary external service processed the release exactly once. Retry and idempotency need separate protocols.

Cancellation masking and cleanup interruption remain a freeze gate for the asynchronous resource profile. Native `try/finally` retains its upstream semantics; this different aggregation policy belongs to a differently named library operation. Garbage collection and destructors must not silently define external-resource lifetime.

## 6. Numeric and text contract

| Domain | Proposed binding discipline | Forbidden shortcut |
|---|---|---|
| Nat/Int | Exact mathematical values with exact pinned operations. | JS number range assumptions or machine truncation. |
| Nat subtraction | Saturating/truncated natural subtraction. | Signed BigInt subtraction for underflow. |
| Integer division/remainder | Name the exact selected operation and zero/sign convention. | Assuming JS/Rust variants are interchangeable. |
| Machine integers | Bind width, overflow, shifts and conversions per operation. | Debug/release-dependent source meaning. |
| USize/ISize | Explicit deployment width; width-sensitive results reported. | Claiming bit-identical wasm32/native64 results automatically. |
| Float/Float32 | Pin rounding, NaN/signed-zero and permitted transformations. | Real arithmetic proofs applied directly or silent fast-math. |
| String/Char | Pin Lean operations and index types; convert JS text explicitly. | JS UTF-16 code-unit length treated as native string length. |
| Byte data | Explicit encoding, endian and bounds behavior. | Native memory layout used as a wire format. |

The native numeric/text references and ECMAScript value model motivate these boundaries. The complete declaration-by-declaration primitive matrix is still a release deliverable; an unreviewed primitive is unsupported in the certified profile. [L11–L13,E11,R03](RESEARCH_SOURCES.md)

The local candidate experiment found the expected discrepancy between a one-code-point astral character and its two UTF-16 code units. That is not an implementation of a Lean String runtime.

## 7. Collections and lawfulness

Prefer application APIs over Array for indexed/bulk work and List for structural recursion where appropriate; do not redefine one as the other. Ordered and hashed collections need separate order, equality and hashing laws. Iteration order belongs to the documented collection API; it cannot vary accidentally with host containers.

Offer checked/optional access and proof-indexed access as distinct ordinary APIs. An unchecked host out-of-range read must not become a value of an arbitrary logical type. Schema-derived encoders must explicitly choose missing/null behavior and deterministic field ordering when the wire contract requires it.

## 8. Assurance gates

Required cases include divergence-sensitive optimizations; closure capture across mutation; nested state/error recovery; acquisition/body/release combinations; cancellation/completion races; stale results; large arithmetic; zero division; numeric conversion boundaries; Unicode conversion; collection law violations; and explicit host capability failures.

Native Lean examples, concurrent schedulers and backend traces were not executed in this pass. These policies must be implemented, modeled and tested before being advertised as portable runtime semantics.
