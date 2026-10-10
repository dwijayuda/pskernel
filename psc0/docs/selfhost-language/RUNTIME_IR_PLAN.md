# Runtime IR work — current continuation and archived M6 plan

The practical F/new-only grammar/TypeScript 7 checkpoint remains merged at `ed5d00aca0743bde583b45fe7756dd494ac3960f`. The declared strict PSC0-SH/1 checkpoint at compiled source `1fa5559a72b293defc56ef7e7020cf82d4b44b79` now has complete 33/27 disposition and exact compiler/provider evidence in [strict/release-qualification.json](strict/release-qualification.json). It combines authenticated completed native/N1/C1 from cancelled run 38015134511, completed C2/C3 and their conformance gates from failed continuation 38021634599, and corrected binder/qualification evidence plus separate provider acceptance from successful evidence-completion run38027413274. The new producer at719f5ec4225baf51d1969cc3b5e4cbc6959fad4a retained all446 imported files and the original1fa source/48-file recipe; it rebuilt no generation and repeated no conformance. All four deduplicated admission streams covering eight C2/C3 roles were accepted by the pinned provider. R remains selected, `.lean` remains authoritative, and qualification applies to the explicit strict entry/lane. [strict/PLAN.md](strict/PLAN.md) preserves the contract and [AI_WORK_STATE.md](../../AI_WORK_STATE.md) records current integration status.

**Everything below is the historical M6 plan and its historical evidence.** Its references to selected A, TypeScript 5 recovery, current TS7 checkpoints and future projection work describe those old revisions. Selected R now remains active; current recovery and development use TypeScript 7.0.2 only; the qualified F projection/worker migrations are complete. Do not revive archived TODOs or execute retired TS5 recovery from this document.

The historical M6 checker and receipts remain valid for their exact sources. They do not establish the new strict milestone or a general preservation theorem.

---

# M6: bounded runtime typing for original PSC0 IR

## Active implementation and qualification boundary

The M6 source installs a portable checker for the existing original IR, a checked emission entry point, and host report integration. The implementation descends from `829a2e953895f03225a77425141aa3ded5e78694`; the TS5 baseline checkpoint is `1b5fd12382c920944924c9d03e0851984293caa2`. The separate TS7 integration is at `99786185f77edf952f11989d4c9bc44028f22f11`, with the same portable M6 implementation and its own qualification run.

The TS5 baseline completed compiler qualification and separate provider acceptance in [run 37906602597](https://github.com/dwijayuda/pskernel/actions/runs/37906602597). The [compiler/runtime receipt](runtime-ir-checker-qualification.json) preserves the completed compiler-job payloads, and the [provider receipt](runtime-ir-checker-provider.json) preserves the later independent provider decision. The current TS7 checkpoint separately completed compiler qualification and provider acceptance in [run 37910429506](https://github.com/dwijayuda/pskernel/actions/runs/37910429506); its [compiler/runtime receipt](typescript7-qualification.json) and [provider receipt](typescript7-provider.json) retain the independent result.

| Evidence axis | Earned TS5 baseline result |
| --- | --- |
| Native/current runtime typing | Complete accepted IR, 54,879 expressions, 707,753 visited steps, zero findings; eight native cases passed; checked emission equals native-generated N1 TS |
| Generated checker behavior | N1/C1/C2/C3 each passed 59 runtime observations, 36 negative IR cases and five carrier refusals, plus resource, simultaneous-substitution, diagnostic-cap and checked-entry cases |
| Current-source generated IR | C2/C3 accepted complete reports with zero findings and checked the same IR before emission |
| Compiler qualification | All four deterministic C2/C3 products agree: canonical source, admissions, TS and JS. N1 TS/JS also agree with C2/C3 |
| Selected provider | Three exact required admission streams accepted in a separate job after emission; emission was not gated by this later decision |
| Current TS7 qualification | Independently passed full compiler/runtime qualification and provider acceptance at the current source/run above; current identities are recorded below |
| Strict SH/1 and profile activation | Remain false |
| Selected authoring seed | A remains selected |

The qualified baseline contains **61 modules** and **1,088,337 source bytes**. Its source-closure SHA-256 is `1dbe0be4f97ad51c2898b86546590d4331b463dd080976ba4cb2c72f0e7c59a0`; its C2/C3 compiler JS SHA-256 is `eb9768db1a10ca6da40666914e116431646a6fcdeca50c3a2f5e6dd250a031af`. The native expression/step counts above belong to the native report. C2/C3 full report files are retained in the workflow artifact, but those counts were not printed in the completed log; no native-to-generated count equality is inferred.

The current TS7 checkpoint independently reports a complete native IR check with 54,879 expressions, 707,753 visited steps and zero findings, and complete C2/C3 accepted reports with zero findings and same-IR checking before emission. Its generated conformance covers 59 runtime observations, 36 negative IR cases and five carrier refusals in each of N1/C1/C2/C3, plus the resource, substitution, diagnostic-cap and checked-entry cases. Its 61-module, 1,088,337-byte source closure has SHA-256 `1dbe0be4f97ad51c2898b86546590d4331b463dd080976ba4cb2c72f0e7c59a0`; its C2/C3 JS SHA-256 is `37ab7de713295b7a2143f1df92b746f97e5a73a8177e906f406fde4a474c0161`. Current C2/C3 products agree within TS7, and N1 TS/JS match the current C2/C3 products. As in the TS5 baseline, the current C2/C3 full expression/step counts were not printed in the completed log and are not inferred from the native values. The provider accepted 3 exact required streams in its separate job after emission.

[TYPESCRIPT7.md](TYPESCRIPT7.md) records current-TS7/historical-TS5 toolchain attempts and the single sequential full-source CLI comparison separately. Installed source, runtime typing, compiler fixed point, provider acceptance and full strict qualification remain distinct claims.


The historical A/B/H/E records remain immutable. E's C2/C3 inventories contain zero type-argument arity findings and 244 `call-arity-needs-expression-typing` records. Those records described unfinished checking obligations in the old inventory, not 244 demonstrated runtime failures. M6 reports describe different executions and must retain their own compiler/source identities.

## 1. Installed modules and entry points

The implementation is in the original compiler packages:

| Module | Responsibility |
| --- | --- |
| [CheckTypes.lean](../../packages/compiler-ir/src/Ps/CompilerIr/CheckTypes.lean) | Type well-formedness, exact equality, simultaneous substitution, literal types and intrinsic signatures |
| [CheckSize.lean](../../packages/compiler-ir/src/Ps/CompilerIr/CheckSize.lean) | Bound the complete input shape before synchronous module/name/binding scans |
| [Check.lean](../../packages/compiler-ir/src/Ps/CompilerIr/Check.lean) | Ordered signatures/scopes, compositional expression typing, layouts, diagnostics and report acceptance |
| [Construct.lean](../../packages/compiler-ir/src/Ps/CompilerIr/Construct.lean) | Ordinary portable construction functions exported for generated host callers |
| [BackendTs/Checked.lean](../../packages/backend-ts/src/Ps/BackendTs/Checked.lean) | Check then emit the exact same IR; expose the route from a prepared module |

The public module operation is:

```lean
psCheckVerifiedIrModule
  (options : PsIrCheckOptions)
  (module : PsVerifiedIrModule) : PsIrCheckReport
```

The report contains `accepted`, `traversalComplete`, `visitedSteps`, `expressionCount`, `findingCount` and retained findings. Each finding carries its code, detail, owner, structural IR path, and optional expected/actual types. Acceptance requires a complete report with no failed obligations.

`psTsEmitCheckedModule options ir` returns a check error before calling the original emitter when the report is rejected or incomplete. On acceptance it passes that exact `ir` to `psTsEmitModule`. `psCompilerCheckedTypeScriptFromPrepared options prepared` first obtains the original IR and then uses that checked route. Both functions are defined in `Ps.BackendTs.Checked`.

The original raw erasure/emission APIs remain available. `PsVerifiedIrModule` is the original model's name, not a type-level certificate, and an admission-ready prepared module is not proof of selected-provider acceptance. Adding these entry points does not globally activate strict SH/1.

## 2. What the portable checker establishes

The old host inventory's known-callee helper recognized a variable with a known signature or a literal lambda. Walking the children of a function-valued let, conditional, match, projection or call did not return a type to the enclosing call. M6 supplies compositional typing for those forms using the original [IR model](../../packages/compiler-ir/src/Ps/CompilerIr/Model.lean).

| IR form or declaration | Installed checks |
| --- | --- |
| Variable | Nearest lexical binding, or a predeclared global value/scheme |
| Literal | Exact type from the supported literal constructor; refuse optional machine-integer literals |
| Lambda | Scoped parameter/result annotations and body result; retain the actual runtime parameter group |
| Call | Infer callee, instantiate a permitted generic scheme, require a function, check exact runtime/type arity and argument types |
| Let | Check initializer against its annotation in the old scope, then check the body under the new binding |
| If | Bool condition and compatible branch result types |
| Record | Resolved structure owner, generic arity, complete/nonduplicate fields and instantiated field types |
| Constructor | Resolved inductive/constructor, generic arity, complete/nonduplicate fields, positional field order and instantiated types |
| Projection | Correct owner/instantiation and declared field result type |
| Match | Scrutinee type, constructor ownership, complete/nonduplicate coverage, binding annotations and compatible branch results |
| Intrinsic | Exact generic/runtime operand and result signature from the active ledger |
| Module | Names, scoped signature/layout annotations, duplicate declarations/binders, and explicit refusal of external imports or unsupported layouts |

Signatures and layouts are available before expression bodies are traversed. Recursive calls use their declared signature; checking a reference does not recursively recheck the referenced body.

### Scoped generics and function groups

The checker validates a declaration/layout scheme under its own ordered generic scope and validates supplied type arguments under the caller's scope. Substitution is simultaneous: a selected replacement is copied verbatim rather than substituted again. Thus a callee T0/T1 mapping to caller T1/T0 preserves the swap even when the textual names overlap. The low-level substitution helper relies on these caller-side well-formedness obligations.

Exact function groups are part of the runtime ABI:

`Function([A], Function([B], R))` and `Function([A, B], R)` are different types.

A nongeneric declaration with no runtime parameters is a value of its declared result type; a function-valued result remains callable according to that result type. It is not automatically an arity-zero function. A declaration with runtime parameters contributes the corresponding function type. Generic schemes require direct explicit instantiation; generic zero-runtime-parameter values and uninstantiated generic escapes are refused.

`.unknown` never supplies a wildcard type or a successful equality result. A false let/lambda annotation therefore cannot be used to invent an apparently valid call arity.

## 3. Active scalar, collection and layout scope

The active scalar typing ledger is Nat, Int, Bool, Char, String and Unit. The declared Array runtime entry has exactly one type argument. Array intrinsics use that same generic/type machinery. For example, with element A and accumulator B:

`arrayFoldl<A, B> : ((B, A) -> B, B, Array<A>, Nat, Nat) -> B`

That signature has five runtime operands and preserves the callback's two-parameter group. String byte positions are represented by Nat in the current erased signatures; a Nat type alone does not establish a valid UTF-8 boundary. Nat/Int and Char/String remain distinct IR types even where their emitted host representations coincide.

Fixed-width integers, floating operations and word-sized scalars remain in the model but are refused when used in a checked module. External import annotations are refused without an enabled ABI contract. Empty inductive layouts and empty matches are also explicit unsupported cases in this bounded implementation. None of these variants is silently converted to `.unknown` or accepted because its metadata exists.

The checker validates declared layout ownership, field names/types, constructor order and match bindings. It does not prove that every erased source layout or emitted target object/tag preserves the source representation. Similarly, literal and intrinsic typing does not establish arithmetic laws, bounds, Unicode conversion behavior, byte-position validity or target-width semantics.

Sources: [intrinsic signatures](../../packages/compiler-ir/src/Ps/CompilerIr/CheckTypes.lean), [module/type checking](../../packages/compiler-ir/src/Ps/CompilerIr/Check.lean), [intrinsic lowering](../../packages/erasure/src/Ps/Erasure/Expr.lean), [target type mapping](../../packages/backend-ts/src/Ps/BackendTs/Type.lean).

## 4. Bounded work and honest diagnostics

The portable checker uses explicit work stacks and qualified structural recursion. It does not make mutual recursion or new authoring syntax a prerequisite.

| Option | Default | Scope |
| --- | ---: | --- |
| `maxSteps` | 5,000,000 | One whole-input preflight allowance and a separate dispatcher allowance |
| `maxTypeSteps` | 65,536 | Each type well-formedness, equality or substitution operation |
| `maxFindings` | 1,000 | Retained finding details; does not stop the dispatcher or total obligation count |

The preflight visits every model record/node and list-cell occurrence, including shared subtrees once per occurrence, before synchronous signature, name or binding scans. It also rejects an individual string whose UTF-8 byte size exceeds the initial input allowance. This is a tree/input-shape bound, not a total byte, wall-clock or allocation limit.

Resource errors are explicit: `checker-input-resource-limit`, `checker-resource-limit` and `type-resource-limit` reject and mark traversal incomplete. No fuel-exhausted type operation returns unchecked input as a successful result.

`visitedSteps` combines a completed input preflight with dispatcher steps. It does not add the internal work of every type operation or lookup. A failed input preflight reports zero because its partial count is not returned. Do not treat this counter as the total number of runtime instructions or compare it to a single shared `maxSteps` budget.

Findings count failed checking obligations. A type operation retains its first error, so a complete rejecting report does not enumerate every malformed descendant of that annotation. Reaching `maxFindings` only truncates stored details. In the host report, `findingCountsCoverage` is `retained-details-only` when the per-code counts cannot describe omitted details.

The original model has no source-origin field. Owners and paths identify IR structure rather than source lines. The native harness retains a full typed `.ir-report.json` before rejection/emission and stage-specific errors separately; the host report serializes expected/actual types with the original function groups.

## 5. Host carriers and the preserved seed boundary

[original-ir-carrier.mjs](../../scripts/original-ir-carrier.mjs) validates generated JavaScript values before entering portable code: constructor ownership, supported scalar carriers, malformed records/lists, cycles and carrier resource limits. Objects must belong to the current generated compiler instance. Neutral ordinary construction functions avoid assuming host exports for record constructors.

[original-ir-inventory.mjs](../../scripts/original-ir-inventory.mjs) then runs the portable checker and serializes its report. It does not maintain another current expression-typing engine. Invalid carriers reject before portable execution.

When a pinned pre-M6 compiler lacks the checker, the legacy inventory is allowed only with an explicit immutable-seed-recovery or selected-authoring-seed boundary identifying that executing compiler and source. Such a report records `runtimeIrTypingAccepted: false`; it is never an M6 pass. This is needed because selected authoring seed A remains unchanged.

A generation report belongs to the compiler that produced that IR. Old Q can produce the legacy C1 full-source report while the new C1 executable already contains M6 and exercises the checker fixtures. Complete current-source reports from later executing compilers must use the portable checker. Keep these receipts separate from E's historical counts and from provider decisions.

## 6. Focused semantic evidence and the let-scope repair

The installed [conformance harness](../../scripts/sh1-ir-checker-conformance.mjs) exercises compositional function-valued callees, generic substitution, annotation mismatches, layouts/matches, unknown or unsupported types, resource failure and capped diagnostics. It tests malformed/cyclic/foreign-instance host carriers before portable execution. It also requires rejected IR to fail in the checked entry before the emitter and accepted IR to preserve raw/checked emitted TS.

The [native harness](../../test/IrCheckerTests.lean) prepares the ordered raw compiler closure, checks its original IR and emits that same IR. Its accepted output is compared with the native-generated N1 TS. The retained TS5 baseline receipt records its eight native cases, complete full-source check, checked/raw parity, and generated conformance. Each later toolchain or source checkpoint needs its own applicable receipts.

A valid old-scope let-initializer fixture exposed a separate emitter defect during M6 development. A JavaScript const block placed the new binding in scope while evaluating its initializer, causing a temporal-dead-zone failure for legal same-spelled shadowing. The bounded repair evaluates an initializer that uses the old name as the argument to a generator whose parameter supplies the new body binding. It preserves one evaluation, suspended compiler calls and closure capture. The tail optimizer declines its direct-loop path for the same detected case so it can use the corrected generator path.

The existing name-use scan treats fuel exhaustion conservatively as a possible use. Ordinary nonshadowing let batching is retained. The focused family covers the original shadowing case, a wrapped call in the initializer, a function-valued initializer capturing the old binding, and repeated nested names inside self-tail recursion.

Sources: [let emission](../../packages/backend-ts/src/Ps/BackendTs/Expr.lean), [tail-optimizer guard](../../packages/backend-ts/src/Ps/BackendTs/Module.lean). These bounded examples support this correction; they do not prove general erasure or backend semantic preservation.

## 7. Remaining strict contract and follow-on migration

| Boundary | Remaining requirement |
| --- | --- |
| Primitive/value semantics | Establish the enabled arithmetic, canonical value, error and conversion laws; typing alone does not do so |
| Arrays and text | Establish bounds/proof provenance, total-helper behavior and UTF-8 position semantics; preserve existing update/copy behavior |
| Layout correspondence | Relate source erasure and target object/tag/field representation, in addition to the installed structural layout checks |
| Optional scalar/import extensions | Keep the current refusals or separately specify and qualify each capability before enabling it |
| Empty data/matches and other profile requirements | Account explicitly for the required profile coverage rather than inferring it from the current compiler corpus |
| Lowering | Establish evaluation, capture, error and representation correspondence for each claimed transformation |
| Enforcement and qualification | Exercise the exact checked path through generated compilers and activate only the complete profile actually supported |
| Provider | Obtain exact-stream selected-provider decisions independently of runtime typing |

Completing this bounded checkpoint does not activate strict SH/1, change `psconfig`, select another authoring seed, or grant unrestricted PSC1/Lean. The current source idioms and the next general recursion projection-normalizer repair are specified in [SPEC.md](SPEC.md#current-authoring-forms) and [MIGRATION.md](MIGRATION.md#follow-on-repair--parameter-projections-in-recursion-normalization).

The TS5 baseline and current TS7 checkpoint have completed their bounded native/generated reports, exact-current-source C2/C3 equality and separate provider receipts. Historical S0/A recovery continues to use its TS5 recipe; the toolchain comparison reuses the retained full-compiler TS. The recommended next language slice is to implement and qualify the planned two-file projection repair. That future repair must preserve exact full-name and existing first-segment lookup priority, use a longer local prefix only when the first segment is absent, and leave exact recursion-identity helpers unchanged. Keep its implementation consumable by selected A, and remove compatibility forms only after separately selecting a qualified compiler that accepts the new authored source.

[IMPLEMENTATION.md](IMPLEMENTATION.md) describes the executable workflow, and [qualification-evidence.json](qualification-evidence.json) is the result index.
