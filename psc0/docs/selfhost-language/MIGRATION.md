# PSC0-SH/1 implementation and migration plan

Historical milestones: M0–M3 have a qualified implementation and selected authoring seed A at `e91b9558d665879871b8bf0893915ae64b27c7fe`. Foundation.List (B, `70d6010ddccbdd6b4939f2fb3c088bfe4e607de0`) is qualified. The three-helper migration H at `671685c3f0059574405a1e630dd965d421a26f05` passed compiler qualification and exact provider acceptance on its first execution. The recursive generic-argument repair E at `cf8fbd784944a98b1e390b709685ca54c2511827` passed compiler qualification and exact provider acceptance on its first execution. M5 remains bounded follow-on authoring work. The bounded M6 runtime typing checkpoint is compiler-qualified on TS5 and on the current TS7 profile, with separate exact-stream provider acceptance for each. Complete strict runtime enforcement remains separate. M7 remains optional. [IMPLEMENTATION.md](IMPLEMENTATION.md) documents the installed workflow; [qualification-evidence.json](qualification-evidence.json) records actual results. The historical baseline is in [README.md](README.md), language requirements are in [SPEC.md](SPEC.md), and the installed M6 scope, separately earned TS5/TS7 qualification and remaining requirements are in [RUNTIME_IR_PLAN.md](RUNTIME_IR_PLAN.md).

## Current F checkpoint: implemented candidate, qualification pending

F is the finite practical-v1 migration in
[migration-backlog.json](migration-backlog.json), prepared against R2 source
`fe2560aba0f347b1caf8d000d371464642d44f23`. R2 has now passed its own compiler
qualification and independent provider check in [run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635).
R cold recovery is verified, and [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) explicitly selects
that successor. F had not been applied at the original R2 evidence point and
retains its own pending qualification. Exact R records do not supply F runtime
or fixed-point evidence.

The candidate replaces twelve handwritten returned-function workers with ordinary
parameters: four fresh-name workers and eight state/accumulator workers. It also
removes three typed parameter-projection aliases from `CompilerIr/Check.lean`.
Complete public types, parameter order, fuel/exhaustion policies, lookup/collision
order, accumulator reversal, first errors and wrappers remain the contract.
Seven associated shape guards are updated without relaxing their unrelated checks.
The current `.ps` edition stays new-only `ps-0.9-r3`; `.lean` remains authoritative.

Use this finite integration sequence:

1. R2 compiler qualification, provider acceptance, cold source recovery and
   explicit successor selection are complete. Authenticate that selected R
   compiler before using it for F; do not substitute an unpinned bundle.
2. Apply the reviewed F1/F2 changes and three alias removals as one coherent
   candidate. Preserve the exact change manifests and family boundaries for
   review and rollback; do not expand to the deferred locator inventory.
3. Run the 87 explicit API cases against authenticated R and F compilers, each
   owning its values. Compare only JSON-safe observations after each compiler
   satisfies the independent expectations.
4. Read the existing generation's prepared declarations and exact IR in the ABI
   hook. Compare all twelve full Core types and ordered runtime signatures.
   Elaborate the small isolated signature/typed-partial module; do not prepare
   the full R closure again or add probe declarations to the compiler. Existing
   runtime partial-application gates cover lowering separately.
5. Run one coherent F promotion chain with checked original IR, current C2/C3
   canonical-source/admissions/TS/JS equality and separate exact-stream provider
   acceptance. Reuse generated products; do not repeat full qualification per
   worker. Keep actual compiler, source, toolchain and receipt identities.
6. Mark practical-v1 complete only after the pending F evidence is recorded.
   Unrestricted PSC1, strict SH/1, full PSCV and a measured compiler speedup remain
   outside this source migration.

The implementation/API map is in
[IMPLEMENTATION.md](IMPLEMENTATION.md#f-checkpoint-ordinary-worker-parameters).

## Prerequisite R: new-only grammar and parameter projections

The current `.ps` source and canonical printer move atomically to `ps-0.9-r3`,
mode `new-only`, support `bounded-selfhost-subset`. The user explicitly chose the
new edition without a current legacy grammar mode.
[PS_GRAMMAR_ADOPTION.md](PS_GRAMMAR_ADOPTION.md) pins the supplied reference,
records errata, and defines the enabled syntax and refusal boundaries. The
compiler's handwritten `.lean` authority and immutable historical S0/A recovery
remain in place. The current authoring seed is the explicitly selected R
successor, whose separate manifest preserves the immutable A parent.
The grammar implementation and paired projection repair earned their own R2
compiler/provider results; no earlier receipt was reused as that evidence.
[IMPLEMENTATION.md](IMPLEMENTATION.md#r2-compiler-and-provider-evidence) records
its 61-module closure, four-product equality and exact jobs. Cold recovery is
verified by [its receipt](grammar-migration-cold-recovery.json), SHA-256
`2aa93517b848da1493386ab9be50527275fe1a7a1c7e12f422d8d8431d8d9f1d`, and [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) records explicit selection.

The R implementation/compiler/provider/recovery/selection requirements below
have their own completed evidence. F's source/runtime qualification remains
pending:

1. Pin the reference and finite support scope before changing accepted syntax.
   Keep omitted annotations, defaults, named arguments, tuples, generic do and
   unsupported semantic extensions explicitly refused.
2. Implement the lexer/parser/printer and shared projection repair using `.lean`
   forms that selected A can consume. Migrate active `.ps` fixtures, canonical
   expectations, scripts and grammar provenance in the same tree. Current
   outputs use the new edition; old outputs remain only in immutable historical
   source/artifact recovery.
3. Review application/group ownership, binder order, newline boundaries and
   empty-call meaning as complete families. Run the generated compiler's finite
   grammar and projection corpus once in the native candidate gate before the
   expensive qualification chain. A failure blocks qualification; fix the cause
   without weakening cases, limits or the source contract.
4. At N1, round-trip the captured raw compiler closure through Lean-to-new-PS-to-Lean
   and require canonical correspondence and PS idempotence. Reuse those translated
   strings to hash the exact canonical source artifact. Require later C2/C3
   canonical source products to equal that hash instead of redoing the full
   closure round trip in every generation.
5. Keep current raw `.lean` as the generation input, then require current C2/C3
   deterministic product equality, the small grammar gate on N1/C1/C2/C3, raw
   `.ps` capability behavior and checked original-IR evidence. Reuse each emitted
   product in its downstream checks.
6. Obtain separate selected-provider decisions for the exact required admissions.
   Record grammar edition/mode/support/reference digest with compiler, closure,
   prelude, options and toolchain identities. Full Standard/PSCV, strict SH/1 and
   a Lean 4.35 provider are not claimed by this checkpoint.
7. After successful evidence, select a qualified recoverable successor explicitly
   before removing aliases needed by A or making compiler `.lean` depend on the
   repaired authoring form. Moving the handwritten closure to `.ps` remains the
   separate source-authority milestone; the new current `.ps` grammar does not
   depend on that move.

## 1. Execute two coordinated tracks

The language track owns source capability design, portable normalization, compiler preparation APIs, source migration and generated-compiler evidence. The existing native-provider track owns kernel conversion, provider resource handling and native checked acceptance. Reuse accepted work from that track; do not overwrite it or import an unverified provider merely to make a language milestone look complete.

Historical audit note: at native commit `b109be0075630dd17b791e3b0c5fcad016df53e8`, bounded provider checks passed but the full compiler workflow failed on a reduction budget. Its 12-package baseline lock, scoped CI, explicit workspaces and Lake caching already addressed part of the iteration problem.[NATIVE], [RUN], [NATIVELOCK], [NATIVECHECK]

Later evidence supersedes that pending status. The separately pinned provider at `963030dc2d154008fccc82e7c8ed29331f138799` accepted A's exact compiler and capability admission streams in [run 37831951758](https://github.com/dwijayuda/pskernel/actions/runs/37831951758). Each later source checkpoint obtains its own exact-stream decision. This branch consumes that provider without editing its implementation; compiler qualification and provider acceptance retain separate receipts.

## 2. Ordered implementation units

M0–M3 below preserve the implementation and acceptance requirements met by A. M4 records the migrated source families; M6 distinguishes the historical generic-erasure repair, the installed bounded typing checkpoint, and the remaining strict contract.

### M0 — preserve and make the baseline recoverable

**Work**

- Keep the original October 3 record and source hashes immutable.
- Reconcile the copied-package workspace issue using the existing integration work. Do not indiscriminately install/build every copied backend; the copied Wasm package expects an interface package absent from PSC0.
- Reproduce the original compiler-only lane in a controlled CI environment and record the exact current host/toolchain/source identities.
- Preserve a recoverable seed outside mutable dist, or publish an immutable CI artifact retrievable by digest. Record its parent, compiler bytes, source closure, prelude, TS/Node/Lean versions, options and evidence level.
- Keep kernel/provider qualification separate from this compiler-only reproduction.

**Acceptance**

A fresh environment can obtain or rebuild the pinned seed and verify its bytes. Cleaning the ordinary work directory does not destroy the only recovery path. Do not relabel historical source equality as a new build.

**Why first**

`build:auto` currently chooses by JS-file existence and `clean` deletes dist. A pleasant authoring language is unhelpful if one broken update strands the compiler.[AUTO], [CLEAN]

### M1 — establish fast, source-aware development

**Files/API area**

`Compiler/Api.lean`, the generated compiler driver, build-current/generation orchestration, and a small host-side iteration wrapper. Do not edit kernel implementation.

**Work**

1. Add an explicit preparation seam in the old accepted source subset: start, step one ordered module, finish. Preserve both the environment and ordered declaration accumulator from the current aggregate implementation.[API]
2. Let the existing aggregate API delegate to that seam so old callers retain behavior.
3. Add a resident generated-compiler session for one exact executing compiler instance. Cache parsing and preparation conservatively.
4. Distinguish building a candidate from testing that candidate. A cached old compiler preparing changed compiler source is a valid build stage; it is not a test of the newly changed frontend.
5. Make Lean replay optional in the development route while retaining it in comparison/qualification routes. Preserve existing default script behavior until callers are migrated.
6. Deduplicate repeated source and closure checks within one orchestrated run, keyed by the inputs those checks actually inspect.
7. Add stage timings, cache hits/misses and provenance to a development receipt.

**Acceptance**

Cold and warm paths produce the same artifacts and diagnostics for the same inputs. A no-edit run performs no avoidable parse/preparation work. A leaf edit never silently selects stale dist source. A compiler-implementation change creates a new compiler session. Mis-keyed/missing/corrupt cache entries cause recomputation, not acceptance.

This is a new layer above the concurrent branch's `--fast` behavior, not a replacement for its full checked pipeline.

### M2 — implement the minimum recursion capability

**Files/API area**

A small new typed recursion planning/normalization module in `packages/elab`, integrated into `Declaration.lean`, `Context.lean` and `Term.lean`; focused bootstrap/generated tests.

**Work**

- Implement changing-parameter generalization using the algorithm in SPEC.
- Start with direct explicit matches, ordinary non-indexed constructors and Nat successor fields.
- Emit the canonical internal worker with fixed/major outer parameters and generalized state in the motive; preserve the public interface with a wrapper. Keep the old recursive-call validator and the existing erasure parameter distinction for this representation.
- Add positive and negative cases before migrating compiler source.
- Retain source spans through normalization. Use the existing printer for deterministic canonical surface source, and compare lowered worker Core through canonical admissions; a syntax-only printer is not labeled semantic normalization.

**Acceptance**

The old seed builds the improved compiler while all its implementation source still uses the old accepted subset. The resulting generated compiler accepts accumulator/fuel-state examples and rejects nondecrease, unrelated children and unsupported dependent cases. Test two state parameters with swapping, state before the major, and stable generic/erased proof parameters to catch calling-convention, erasure-map and sequential-update errors.

The historical negative invariant test is not merely deleted: keep an equivalent old-mode test and add new-mode success plus new semantic failure cases.[TEST], [TERM]

### M3 — qualify an improved compiler seed before dogfooding

Run the current-source generation procedure in section 3. Include raw authoring inputs that exercise the new normalizer, not only pre-normalized generated workspaces. Keep canonical-source fixed-point evidence as a separate lane.

Promote a versioned **compiler-qualified** seed only after the current-source equality and capability/runtime gates pass. This checkpoint permits controlled migration; it is not yet strict SH/1 qualification if M6 is incomplete. Strict SH/1 additionally requires all mandatory capabilities and runtime IR enforcement. Kernel-checked qualification is a separate axis and requires actual selected-provider acceptance. If that acceptance is pending, retain the compiler-only label.

This stage breaks the bootstrap cycle: the compiler learns the feature while written in the old subset, then its source can begin using it.

### M4 — migrate source by feature family

**Completed first family:** Foundation.List now uses ordinary parameters in reverseAcc, append, take and zip. The selected A seed consumed both preserved and migrated sources; all ten public types and 1,666 behavior observations per library passed. The migrated compiler then passed its own raw-source C2/C3 equality and exact provider acceptance. The complete receipts are indexed in [qualification-evidence.json](qualification-evidence.json). The second bounded family H qualified under that same A seed and is recorded below. Further migrations remain small, independently qualified units.

**First family: simple total collection/index workers.** Start with a small sample of list traversal, reverse/append/take/zip wrappers and index scans. Reuse existing foundation helpers. Preserve public names/signatures and avoid an accompanying data-structure redesign.[LIST]

**Second family: fuel and explicit state.** Migrate workers returning functions of context, indices, accumulators or result state. Preserve exhaustion behavior, first-error order and state-on-error policy.

**Third family: compiler internals.** Apply the same established conversion to declaration preparation, elaboration, erasure and emission helpers. Change the normalizer's own implementation only after its capability is compiler-qualified.

Choose low-impact representatives first, then expand one verified family. Do not rewrite all high-fan-in modules together. In the measured import graph, Foundation.Name has 42 transitive importers, Core.Expr 31 and Environment.Basic 21; even small public changes can be broad. The ordered environment can make semantic invalidation broader still.

For each family, produce a dry-run inventory with source location, detected capability, proposed conversion, old guard coverage and unsupported cases. An AST-aware migration helper may apply proven mechanical forms; ambiguous cases stay unchanged for review. Regex replacement cannot classify binders or termination.

**Acceptance per family**

Changed source is accepted by the promoted generated compiler; relevant semantic and boundary fixtures pass; expected structural differences are reviewed; existing loopification is preserved or its change is explained. Retire only the shape guards covered by replacement capability tests. Commit each family separately so rollback is a normal revert.


### Second bounded source family: three compiler helpers

H at `671685c3f0059574405a1e630dd965d421a26f05` completed the three planned helper migrations in `Elab/Term.lean` and `Erasure/Definition.lean`. Its native gate, full compiler qualification and exact provider acceptance passed on the first execution in [run 37851669475](https://github.com/dwijayuda/pskernel/actions/runs/37851669475). The provider checked the exact compiler and raw capability streams separately after emission.

| Migrated helper | Guard updated to accept historical and qualified forms | Preserved behavior |
| --- | --- | --- |
| `psExprApplyManyWorker` | `check-elab-apply-many-selfhost-source-syntax.mjs` | Empty arguments preserve the starting expression; arguments form left-associated applications in order, including an existing application prefix |
| `psErasureAddUniqueStringWorker` | `check-erasure-add-unique-string-selfhost-source-syntax.mjs` | Collision order, duplicate handling, zero fuel and the exact exhaustion suffix |
| `psExprAppViewAccWorker` | `check-elab-app-view-selfhost-source-syntax.mjs` | Head and argument order, a nonempty accumulator suffix, direct expected trees and construction/decomposition round trips |

The first and third workers descend through immediate List/PsExpr constructor fields and change a nondependent value accumulator. The second descends through Nat fuel with a fixed used-name list and a changing String base. They now use ordinary explicit value parameters and fully saturated recursive calls. Public worker/wrapper names, complete types and argument order remain unchanged; no new parser or termination capability was needed.

The bounded correspondence gate compiles preserved and current raw helper slices with the actual Name/Level/Expr dependencies. It compares all seven public function types and 2,198 observations per compiled slice, including typed partial applications. A separate 1,568-observation check executes the actual exported helpers in N1/C1/C2/C3. Both H and E passed those checks on their first compiler execution. H's C1/C2/C3 agree on all four products; E's C2/C3 agree after the intentional generic-erasure change.

The unique-name algorithm deliberately retains its established exhaustion behavior: zero fuel and base `x` returns `x_overflow`; one collision at fuel one can return `x__overflow`. A change to that algorithm belongs in a separate checkpoint. The guards retain their wrapper, primitive and unrelated admission/source checks; no semantic gate was removed.

Choose additional source families from measured remaining authoring cost. Do not schedule these three completed source edits again, and keep broader normalizer/high-fan-in refactors separate.

### M5 — add conveniences in measured priority order

R supplies the new-only `.ps` edition and bounded projection repair. F consumes
that capability under its selected-seed prerequisite; it does not add another
grammar transition. Broader inference/semantic conveniences remain separate.

1. Completed in R2: repair parameter projections in the existing recursion normalizer under the bounded contract below. Cold recovery and explicit selection are recorded; F must still qualify its own use of that capability.
2. Common equation/lambda-wrapped declaration and harmless-let normalization.
3. Expected-type lambda domains with explicit fallback diagnostics.
4. Nested constructor patterns lowered to flat decision trees.
5. Except-only do if repeated explicit error plumbing remains a significant authoring cost.

These are independent improvements. Do not delay useful accumulator migration until a general equation compiler, all nested patterns or full monads are complete. Do not add unneeded source class/instance/deriving support.

Use actual remaining workaround counts to choose between the broader inference and nested-pattern extensions. A parser change affects a large part of this closure; it deserves a separate seed qualification rather than being mixed into a data-structure cleanup.

### Follow-on repair — parameter projections in recursion normalization

The historical M6 source remains consumable by A by using three source idioms: typed local callbacks passed by name, explicit result types on match-valued let initializers, and typed branch-local aliases before projecting original record parameters in generalized recursion. [SPEC.md](SPEC.md#current-authoring-forms) describes the exact restrictions. Qualification of M6 does not remove them.

R2 implements and compiler-qualifies the bounded normalizer repair, with independent provider acceptance. Cold source recovery is verified and [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) records explicit successor selection; F retains its own qualification. The implementation touches two Lean files: add a shared resolver returning an untyped resolved base and field suffix in `Elab/Term.lean`, then thread immutable `PsEnvironment` through the recursion walk/normalizer in `Elab/Recursion.lean`. The pre-repair qualified lookup and rewriting paths are visible in [Term.lean](https://github.com/dwijayuda/pskernel/blob/99786185f77edf952f11989d4c9bc44028f22f11/psc0/packages/elab/src/Ps/Elab/Term.lean#L306-L366) and [Recursion.lean](https://github.com/dwijayuda/pskernel/blob/99786185f77edf952f11989d4c9bc44028f22f11/psc0/packages/elab/src/Ps/Elab/Recursion.lean#L281-L305).

The resolver must use this order:

1. Resolve the complete exact local/global name first, preserving existing qualified-name meaning.
2. If there is no exact result, retain the existing first-segment local/global projection base whenever that base resolves.
3. Only if that first-segment base is absent, try the longest proper multi-segment **local** prefix and retain the remaining field suffix. Do not expand global prefixes or exempt a magic internal-name spelling.
4. Type the selected base and field chain once. A field-typing failure is final; it must not cause lookup to retry a different prefix.

Raw binders are currently single-segment in both [Lean syntax](https://github.com/dwijayuda/pskernel/blob/99786185f77edf952f11989d4c9bc44028f22f11/psc0/packages/syntax/src/Ps/Syntax/ParseLean.lean#L528-L546) and [common binder parsing](https://github.com/dwijayuda/pskernel/blob/99786185f77edf952f11989d4c9bc44028f22f11/psc0/packages/syntax/src/Ps/Syntax/ParseCommon.lean#L565-L581). The additional local-prefix path is needed for complete hygienic names such as `$psc0SH.0`; merely changing the printed prefix left the pre-R first-segment resolver unable to find that binding.

Its acceptance contract is:

1. Keep `psElabRecursionLocalId` and `psElabSyntaxLocalId` exact-only. A projected value such as `state.field` must not acquire the identity of an unchanged whole parameter or a known constructor child. Use projection-base resolution only in the rewriting/type-elaboration path that needs it.
2. Rewrite according to resolved binder identity and lexical scope. Preserve let, lambda and match-pattern shadowing, including exact qualified-name collisions; cover both fixed record parameters and generalized record state.
3. Preserve public binder order/kinds, the root structural match, child provenance, simultaneous recursive arguments and existing dependent/recursive-escape refusals. Do not weaken the stable recursive-call guard or invent structure getter declarations absent from the PSC environment.
4. Keep R's implementation source compilable by selected A using supported forms. Exercise ordinary raw source with direct projections under the repaired native and generated compilers; pre-normalized worker input or an external source rewrite is insufficient.
5. Use one focused family for direct/chained state and fixed-parameter projections, exact-name and prefix collisions, first-segment selection whose field typing fails, and let/lambda/pattern shadowing. Include refusals proving that projected values cannot masquerade as whole recursion arguments. Check runtime results and original-IR types, and review the entire affected reference class before one candidate gate.
6. Require exact-current-source C2/C3 equality and independent selected-provider decisions. Only a separate, explicit seed-selection checkpoint can permit compiler source to depend on the newly accepted form and remove compatibility aliases.

This repair addresses an observed authoring limitation. It does not promise general equation inference, arbitrary projections through dependent layouts, or unrestricted PSC1/Lean.


### M6 — strengthen the portable runtime contract

The historical report-only inventory preceded the portable checker. B's complete traversals recorded 244 call-expression typing obligations and 19 type-argument arity findings. That 19-finding result and the empty current-definition generic context are historical evidence; E implements their bounded repair.

E at `cf8fbd784944a98b1e390b709685ca54c2511827` preserves the current declaration's ordered generic arguments while type binders are opened, carries them through runtime/proof binders, and supplies them when reconstructing recursive induction-hypothesis calls. It uses only declaration binders; it does not collect every `scope.typeLocals` entry or whitelist affected helper names.

The focused fixture checks exact original-IR argument order for one, two and three generics, interleaved proposition/proof/runtime binders, and a monomorphic control. It emits the same IR object whose recursive calls were asserted. All N1/C1/C2/C3 fixture executions passed 19 behavior observations; N1/C1 also passed native parity. E's first full compiler run and separate provider job passed in [run 37852341550](https://github.com/dwijayuda/pskernel/actions/runs/37852341550). The pinned provider accepted the compiler, raw capability and focused generic-fixture admission streams after emission; this does not claim that emission itself was gated by checking.

E's C2 and C3 inventories complete with **zero type-argument arity findings** and **244 remaining call-expression typing obligations**, with no other recorded categories. C1's inventory still has the historical 19 findings because the older selected Q produced that first-generation IR. C1's executable contains the repaired erasure and produces the corrected C2 IR; C2 reproduces it for C3. This is the reason for the C2-versus-C3 equality contract, rather than requiring C1 to be byte-identical across a compiler change.

The bounded M6 implementation is now installed over the same original IR. It includes portable type operations, a whole-input preflight, compositional expression checking, neutral construction functions for generated host callers, and checked emission of the exact validated IR. The current host inventory validates carriers and reports this portable checker instead of maintaining a second expression-typing implementation. Its legacy inventory is restricted to explicit immutable-recovery or selected-authoring-seed boundaries and cannot grant runtime typing acceptance. [RUNTIME_IR_PLAN.md](RUNTIME_IR_PLAN.md) records the implementation and report contract.

Those historical 244 records were unfinished checking obligations, not 244 demonstrated runtime failures. Compare each new portable report using its own executing compiler, source closure, options and completeness; do not relabel E's report or old Q's C1 inventory as an M6 pass.

The TS5 M6 baseline at `1b5fd12382c920944924c9d03e0851984293caa2` passed compiler qualification and separate provider acceptance in [run 37906602597](https://github.com/dwijayuda/pskernel/actions/runs/37906602597). Its 61-module, 1,088,337-byte source closure passed the complete native IR check with 54,879 expressions, 707,753 visited steps and zero findings. All N1/C1/C2/C3 checker runs passed 59 runtime observations, 36 negative IR cases and five carrier refusals, plus the resource/substitution/checked-entry cases. C2/C3 complete current-source IR reports are accepted with zero findings and confirm same-IR checking before emission. All four deterministic C2/C3 products agree, and N1 TS/JS agree with them. C2/C3 expression and step counts were not printed in the completed log and are not inferred from the native report. See the [compiler/runtime receipt](runtime-ir-checker-qualification.json).

The selected provider accepted the three exact required admission streams in its separate successful job, after emission; the [provider receipt](runtime-ir-checker-provider.json) records that boundary. Selected A, `psconfig` and strict-profile activation are unchanged.

The current TS7 source at `99786185f77edf952f11989d4c9bc44028f22f11` separately passed compiler qualification and provider acceptance in [run 37910429506](https://github.com/dwijayuda/pskernel/actions/runs/37910429506), using the same portable M6 implementation. Its native full IR and C2/C3 current-source IR checks are complete and accepted with zero findings; the generated builds check the same IR before emission. Current C2/C3 products agree within the TS7 profile. Its compiler JS SHA-256 is `37ab7de713295b7a2143f1df92b746f97e5a73a8177e906f406fde4a474c0161`, while the preserved TS5 baseline keeps its separate JS identity. The [TS7 compiler/runtime receipt](typescript7-qualification.json) and [TS7 provider receipt](typescript7-provider.json) record the independent result. Historical recovery stays pinned to TS5; [TYPESCRIPT7.md](TYPESCRIPT7.md) retains the toolchain attempts and the one sequential same-full-source CLI comparison.

The TS5 baseline and the separate current TS7 checkpoint have completed the following gates. Keep them as acceptance requirements for subsequent compiler milestones:

1. Require successful raw PSC preparation of the complete current closure, then the bounded native/N1 checker and language fixtures. Preserve full typed rejection diagnostics and input identities before changing source again.
2. Require accepted, complete current-source portable reports where the executing compiler contains M6, plus the focused positive/negative, simultaneous-substitution, exhaustion, carrier and checked-emission cases. A capped diagnostic list must not conceal the total failed-obligation count.
3. Establish exact-current-source C2/C3 product equality within the selected toolchain profile. The old selected Q boundary remains explicitly legacy; the new C1 executable must exercise the installed checker. Obtain separate provider acceptance for the exact required admission streams.
4. Record the installed typing API, runtime evidence, compiler fixed point and provider decision as separate claims. The historical M6 integrations retained then-selected A and did not activate strict SH/1. R's later explicit selection has separate recovery/evidence records. Do not repeat completed full qualification for ordinary edits covered by the bounded development gate.
5. R's bounded projection/new-grammar implementation is qualified, cold-recovered and explicitly selected, with immutable A-consumable source preserved. F's implemented candidate uses that seed for the three scoped aliases and twelve handwritten state adapters; qualify F's coherent source separately. Preserve public types, error/exhaustion behavior and supported optimization paths.

Strict enforcement still requires the applicable primitive/value, scalar/bounds/text-position, layout and erasure/backend correspondence obligations. External imports and optional scalar capabilities remain refused until their own contracts are qualified. The tested let-initializer scope correction is one bounded backend repair, not a general preservation proof. Neither an accepted typing report nor provider acceptance alone activates strict SH/1.

Preserve the original TS path. Do not make the copied direct JS/Rust/Wasm backends prerequisites. Integrate a new target only after choosing a coherent IR interface, wiring its build/driver dependencies, and demonstrating the scalar/ADT/function contract and generated self-host evidence for that target.

This work can overlap M2–M5 when isolated and separately qualified. M3 and M6 together, plus all required capability gates, are prerequisites for strict SH/1 qualification; M3 alone is a limited compiler checkpoint.

### M7 — optionally make .ps authoritative

Consider this only after the generated PSC compiler can parse ordinary authored `.ps`, normalize the enabled SH/1 capabilities, check/compile its full source, produce stable successive generations and support useful diagnostics.

Require qualification of every enabled capability used by the authoritative source; completion of every optional M5 convenience is not required. Do one controlled extension/authority migration with source correspondence checks. Do not simultaneously rename declarations, switch punctuation, change runtime representations and replace the provider. Keeping `.lean` as the authoring spelling is a valid outcome if it gives the best workflow; self-hosting depends on which compiler consumes it, not the filename extension.

## 3. Correct generation and promotion procedure

The current pending F sequence uses authenticated selected R: `C1 = R(F)`,
`C2 = C1(F)`, `C3 = C2(F)`, all reading the same exact raw F source. Its evidence
remains pending. The initial S0/A construction below is the historical parent
procedure, not a claim that S0 or A can consume F.

Let A be the exact source tree containing the improved compiler, written in the old subset. Let S0 be the pinned old compiler.

1. Build C1 = S0(A).
2. Build C2 = C1(A), actually reading the same current A.
3. Build C3 = C2(A), again from that exact A.
4. Require equality of the deterministic canonical source, ordered admissions, TS and JS emitted when C1 and C2 consume that same raw A: the build products associated with C2 and C3. Pin all toolchains/configurations. Record each execution's provenance separately; parent/executing-compiler fields in receipts are not required to match.
5. Execute the raw new-authoring capability corpus using the generated C2 and C3. Record the normalized source, results and provider acceptance separately.

C1 can legitimately differ from C2 when the compiler's emitter or normalization behavior changes across the seed boundary. The historical lane retains its original comparisons; the new lane specifically requires C2-versus-C3 product equality. Any permitted artifact normalization must be explicitly specified before comparison, not introduced to hide a mismatch. Do not demand old-seed byte equality for every compiler improvement.

After promotion, let B be compiler source migrated to ordinary SH/1. Repeat the same procedure and C2-versus-C3 product equality using the promoted seed, and make each generated compiler consume B's **raw authored source**. If every generation only sees a pre-normalized workspace, the fixed point does not exercise the authoring normalizer.

A syntax-only translation route is insufficient here. The shared preparation/normalization seam must support ordinary authoring input and supply deterministic canonical output in its ordered environment. Source emission and compilation must use the same lowering implementation.

A toolchain upgrade receives its own current-source qualification. The preserved S0/A recovery recipes keep TypeScript 5.8.3 and their original artifact identity. Current TypeScript 7 uses a separate explicit CLI/profile; compare C2/C3 within that profile. A TS5 receipt does not qualify TS7, and cross-version emitted JS need not be byte-identical. Reuse the same already emitted full-compiler TS for the bounded 5/7 comparison rather than repeating PSC preparation. See [TYPESCRIPT7.md](TYPESCRIPT7.md).

Required receipt fields:

- Exact source closure and module order, including the new module count.
- Parent and executing compiler digests.
- Language/capability set and normalizer identity; current `.ps` grammar edition, new-only mode, enabled support scope and supplied reference SHA-256.
- Canonical source and ordered admissions digests, plus the N1 closure correspondence artifact digest used for current C2/C3 canonical source comparison.
- Generated TS/JS digests and runtime/toolchain options.
- Prelude/environment identity.
- Provider executable/runtime/options/resource policy and actual result.
- Evidence level: preparation, generated execution, compiler fixed point, or kernel-checked fixed point.

Missing evidence is a pending claim, not a reason to rename admission-ready output as checked.

## 4. The efficient development workflow

The implemented ordinary route is `npm run dev:sh1`, which builds current native PSC, emits N1 from raw current source and exercises N1 on the bounded language/session/CLI corpus. `npm run iterate:sh1 -- ... --loop` provides optional resident preparation reuse. The workflow runs that bounded native-candidate gate before expensive generation even for full runs. Full selected-seed C1/C2/C3 and provider checks remain promotion commands, selected in CI by `[sh1-qualify]` or a full manual dispatch. Independent checkpoint branches may qualify in parallel; ordinary edits do not repeat the complete bootstrap. Exact usage, recovery and measured scope are in [IMPLEMENTATION.md](IMPLEMENTATION.md).

| Workflow | When | Work and claim |
| --- | --- | --- |
| Resident edit feedback | Repeated requests within one compiler instance | Real parsing and elaboration, changed preparation suffix, focused diagnostics; no fixed-point claim |
| Candidate build/test | Ordinary compiler edits | Build native PSC incrementally, emit N1 from raw current source, then execute the generated compiler's bounded capability/runtime/session cases; no selected-seed ancestry claim |
| Current-source self-application | Feature or source-family milestone | Successive current-source generations and equality, with exact provenance |
| Checked qualification | Seed promotion and relevant provider/semantic changes | Required admissions accepted by selected provider plus source/generation evidence |
| Historical reproduction | Bootstrap changes or explicit recovery audit | Reproduce preserved old source/seed contract independently |

In the preserved baseline, `npm run build:psc` was the closest current-source build, and `npm run fixed-point` was the coarse full-chain route. The former does not establish candidate self-application; the latter is expensive to repeat per edit. The new ordinary route above adds focused generated-compiler feedback.[BUILD], [PKG]

### Cache identities and safe invalidation

| Cache/result | Minimum identity and invalidation |
| --- | --- |
| Parsed source | Exact bytes, source kind/path, grammar edition/mode/support/reference digest, executing parser implementation, options and diagnostic origins |
| Normalized/prepared module | Parsed input, executing normalizer/elaborator, full incoming environment/prelude, ordered declaration accumulator/provenance, resolution configuration and limits |
| In-memory state | Exact compiler import/session; do not share symbol-tagged values across independently imported generated modules |
| Emitted TS bundle | Entire prepared closure, runtime/prelude, emitter/options/target identity; retain aggregate emission initially |
| Compiled JS | TS bytes, TypeScript version, tsconfig/options, relevant package/runtime resolution |
| Provider result | Ordered canonical admission bytes, starting environment/prelude, provider executable plus runtime/toolchain closure, semantic options and resource policy |
| Qualification receipt | All required artifacts and stage results; a receipt is not independently granted provider authority |

Start conservatively. Parse independent modules in parallel where useful, but prepare the ordered semantic suffix sequentially until the complete state can be safely reused. Later fine-grained dependency tracking may reduce that suffix; include bodies used by definitional reduction, instance/name resolution, and negative lookup dependencies, not just exported signatures.

Generated TS creates fresh Symbol tags/brands and an import-local trampoline WeakMap. Even identical compiler bytes do not make two import instances' object graphs interchangeable.[MOD] Persistent caches should store a supported canonical serialization and reconstruct it, or cache source/artifacts only until such a format is defined.

Missing/corrupt cache entries require recomputation. Timeout/cancellation/budget exhaustion are operational outcomes, not permanent proof-invalid results. An editable acceptance-cache JSON cannot manufacture a checked session handle. If a provider exposes no resumable or attestable acceptance protocol, reuse may speed preliminary work but fresh provider checking remains necessary for qualification.

## 5. Measurement plan

First establish phase timings on one pinned environment: load/parse, normalize, elaborate, admission encode, provider accept, erase, TS emit, tsc, generation compare. Record wall time, peak memory where available, source/module/declaration counts and cache counters.

Measure these representative scenarios before and after an iteration change:

- Cold build from the recoverable seed.
- Warm no-change repeat.
- Small late/leaf implementation edit.
- Shared core or prelude change.
- Compiler implementation/normalizer change.
- Provider-only change.
- One full current-source qualification.

A warm no-change source loop should do zero unnecessary parse/elaboration work. A leaf source edit should reuse its valid prefix. A parser/compiler implementation change must invalidate affected sessions even if source filenames did not change. These are testable workflow properties; no speed multiplier is asserted without timings.

For generated runtime, measure representative lexer/parser scans, list/index helpers and a real compiler corpus. Inspect whether existing count/tail-loop paths are retained. Profile a demonstrated hot path before extending generic loopification or replacing collections. Current array push/set copy; changing lists to arrays can worsen repeated accumulation.[EXPR], [MOD]

Run full performance comparisons at milestones, not every keystroke. Set time budgets after the baseline is measured; do not invent a tenfold improvement target from source inspection.

## 6. Risk controls and stop conditions

| Risk | Concrete control |
| --- | --- |
| New source stranded on old seed | Feature implementation stays old-compatible; seed qualification precedes corpus migration |
| Semantically wrong accumulator lowering | Typed dependency/provenance analysis; swapping/multiple-state tests; reference behavior |
| Pattern lowering changes first match | Factored decision tree; overlap/default/order fixtures |
| “Checked” only means encodable | Separate preparation, actual provider acceptance and receipt integrity |
| Fast run silently uses stale compiler/source | Executing compiler and current closure digests in every receipt |
| Cache ignores semantic state | Full environment plus declaration accumulator; conservative suffix rebuild |
| Performance regresses behind nicer syntax | Preserve optimization paths; measure allocations/time on concrete workloads |
| New packages force a compiler rewrite | Integrate one coherent backend interface at a time |
| Parallel work overwrites provider changes | Separate branches and reviewed commit integration; never force-update native work |
| Migration loses the known-good compiler | Immutable recoverable seed and source-family rollback checkpoints |

Stop promotion, not all development, when required evidence fails. Preserve diagnostics and the failing corpus; fix the concrete issue or leave the associated claim pending. Do not respond by widening allowlists, replacing a semantic gate with a textual marker, or treating a larger fuel setting as proof of correctness.

## 7. Completion criteria

F's practical-v1 completion is limited to the twelve named workers, three alias
removals and their required evidence in the frozen backlog. Candidate source
edits alone do not complete that milestone, and practical-v1 completion does not
activate the full strict language/runtime contract below.

SH/1 is successfully adopted when the chosen compiler source families use ordinary structural recursion without handwritten state-currying adapters, the generated compiler consumes that authored source itself, capability-based checks replace the relevant spelling guards, current-generation artifacts meet their declared equality contracts, and the advertised provider qualification has actually passed.

The daily path must build and test current edits without repeating an unchanged full bootstrap. The historical 55-module point remains reproducible, later seeds have their own honest closure counts, and optional targets consume the same defined runtime contract instead of imposing new source dialects.

[TERM]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/elab/src/Ps/Elab/Term.lean#L2706-L2824
[LIST]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/foundation/src/Ps/Foundation/List.lean
[API]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/compiler/src/Ps/Compiler/Api.lean
[EXPR]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean
[MOD]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean
[BUILD]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/build-current.mjs
[PKG]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/package.json
[AUTO]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/build-auto.mjs
[CLEAN]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/clean.mjs
[NATIVE]: https://github.com/dwijayuda/pskernel/tree/b109be0075630dd17b791e3b0c5fcad016df53e8/psc0
[RUN]: https://github.com/dwijayuda/pskernel/actions/runs/37823400738
[TEST]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/test/BootstrapTests.lean
[NATIVECHECK]: https://github.com/dwijayuda/pskernel/blob/b109be0075630dd17b791e3b0c5fcad016df53e8/psc0/scripts/checked-selfhost.mjs
[NATIVELOCK]: https://github.com/dwijayuda/pskernel/blob/b109be0075630dd17b791e3b0c5fcad016df53e8/psc0/scripts/selfhost-baseline.mjs
