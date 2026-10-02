# Runtime semantics, effects and resources

**Proposed semantic policies. Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** `.ps` uses category-aware canonical lowering; native `.lean` retains the selected reference semantics. New library names, especially `Psc.Async`, are proposals, not implemented APIs, newly admitted syntax or kernel rules.

## 1. Logical and executable views

A total pure definition participates in logical computation and may have an executable realization. An IO/asynchronous computation can be described by a typed value without making every execution terminate or establishing external-service correctness. Logical checking and runtime evaluation are different concerns. [L06](RESEARCH_SOURCES.md#lean-and-logical-foundations)

The runtime relation specifies values, calls, relevant allocations, observable effects, failure and divergence. Unsupported observable behavior restricts executable coverage; it does not authorize a new target-specific source meaning.

Claims distinguish partial correctness, termination, total correctness, trace safety and environmental liveness. Resource exhaustion is either explicitly allowed or ruled out by bounds, not ignored while promising success on every finite machine.

## 2. Evaluation, grammar and optimization

Effect sequencing uses inherited `do`/bind or a named library interpreter. v0.7 §18 governs the accepted do-element grammar and the conditional gate for bracketed `do`. It does not admit a universal JS block, unrestricted `return`, `async function` or `using`. Local mutation retains `:=` and native scope; new resource/async policies use ordinary library calls.

Elaboration order does not authorize effect reordering. Code motion, duplication and dead-code elimination need appropriate purity/termination conditions. Under a strict execution model, `first(1, loopForever())` need not behave like `1`; its canonical Lean counterpart is `first 1 (loopForever ())`. This remains a design counterexample, not an executed Lean test. A partial function's runtime equations need separate justification before logical use.

D-CALL expresses curried application while preserving spaced tuple neighbors. Closure conversion must preserve captured values and state discipline. Mutable target cells may be an internal representation only when faithful. Copying a resource handle is not automatically safe because copying an immutable record is safe.

## 3. State and failure

Keep different interfaces distinct:

- `StateT S (Except E) A`: failure does not return a successful final-state pair.
- `ExceptT E (StateM S) A`: final state accompanies success or failure.

A convenience alias identifies its stack. Speculative logical rollback restores relevant parser/elaborator state; it does not undo a filesystem write. Database transactions need actual isolation/conflict/retry models. An in-memory inventory theorem is not a proof against concurrent database overselling.

## 4. Portable async library candidate

**Application priority; experimental until semantic conformance closes.**

Do not redefine native Lean Task. `Psc.Async ε α` is a separately named ordinary library describing asynchronous computation with an explicit interpreter capability. Candidate operations include pure, bind, failure, start-in-scope, await, cancellation request, timeout and bounded parallel traversal. Their signatures must have a valid v0.7/canonical-Lean expression and declared dependency closure. Method names such as await are library API candidates, not newly registered keywords.

The recommended policy is cold descriptions with explicit start: construction schedules nothing; interpretation starts work. Reusing a description starts another run, while sharing a started handle refers to the same run. An existing Promise may already be executing, so attachment differs from starting a cancellable thunk. Promise is a foreign reference, not the library's definition. [E12](RESEARCH_SOURCES.md#application-and-javascript-platform)

### Lifecycle

A handle moves from created to running, then one terminal success, typed failure or cancelled outcome. Cancellation is a request until committed; earlier committed success is not retroactively changed. Specify permitted traces and arbitration rather than wall-clock identity across hosts.

The historical finite terminal-event model checks only a small policy property, not a scheduler, fairness, cleanup or liveness. Structured scopes own children and follow a declared cancellation/completion policy. Uncooperative foreign work can prevent prompt shutdown. Force-detach is an explicit capability that changes structured-completion claims.

Timeout uses an identified clock/deadline policy. It does not prove that a remote side effect did not occur. Late results use request identity rather than being mistaken for rollback.

### Runtime bridge

Specify JS queues/Promise/AbortSignal adaptation, Rust executor/cancellation support, or Wasm suspension/import/lifetime handling. Adapters preserve the allowed traces or report unsupported capabilities. Equal final values alone do not establish equal effects.

## 5. Resource library candidate

Use ordinary bracket-style functions with explicit acquisition, body and release. No new `using` grammar is admitted by this proposal.

| Situation | Required outcome policy |
|---|---|
| Acquisition fails | No release of a never-acquired handle. |
| Body succeeds | Release once before reporting scoped success. |
| Body fails | Release once and retain the body error. |
| Release fails after body success | Report release failure. |
| Body and release fail | Preserve both in a typed aggregate. |
| Cancellation after acquisition | Perform the declared cleanup protocol before scoped cancellation. |
| Engine/process termination | Outside exactly-once cleanup unless separately modeled. |

Exactly once concerns the intended release invocation in the supported model, not proof of remote processing. Retry/idempotency are separate protocols. Cancellation masking and interruption remain freeze gates. Native try/finally keeps its meaning; different aggregation belongs in a differently named library operation. GC/destructors do not silently define external-resource lifetime.

## 6. Numeric and text contract

| Domain | Binding discipline | Forbidden shortcut |
|---|---|---|
| Nat/Int | Exact reference values and operations. | JS number range assumptions or truncation. |
| Nat subtraction | Truncated natural subtraction. | Signed BigInt subtraction on underflow. |
| Division/remainder | Exact named operation and zero/sign rules. | Assuming host variants coincide. |
| Machine integers | Width, overflow, shifts and conversions per operation. | Debug/release-dependent source meaning. |
| USize/ISize | Explicit deployment width. | Automatic native64/wasm32 identity claims. |
| Float/Float32 | Pinned rounding, NaN/signed-zero and transforms. | Real-number proofs or silent fast-math. |
| String/Char | Exact operations/index contracts and explicit conversion. | JS code-unit length as native string length. |
| Bytes | Encoding, endian and bounds contracts. | Runtime memory layout as a wire format. |

The v0.7 canonical baseline and primitive capability set govern bindings. Earlier patch/live-manual research is supporting evidence, not an implicit upgrade. The complete operation matrix is still required; unreviewed primitives remain unsupported. [L11–L13,E11,R03](RESEARCH_SOURCES.md)

The prior experiment's astral-character discrepancy is a recorded boundary example, not a Lean String implementation or newly executed test.

## 7. Collections and lawfulness

Array and List serve different roles and retain their semantics. Ordered/hashed collections need separate equality/order/hash laws. Iteration order belongs to the API, not an accidental host container.

Checked/optional access and proof-indexed access are distinct APIs. Host out-of-range reads cannot yield arbitrary logical values. Schema encoders explicitly select missing/null and field-order policies where needed.

## 8. Assurance gates

Test divergence-sensitive optimization, closure capture/mutation, transformer order, acquisition/body/release combinations, cancellation races, stale results, arithmetic and conversion boundaries, Unicode, collection laws and capability failures. Add source-category tests for each API example and source-map preservation through v0.7 lowering.

Native examples, concurrent schedulers and target traces were not executed by this syntax repair. Proposed library policies need implementation, models and tests before portable-runtime claims.
