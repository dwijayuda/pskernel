# Finite practical self-host migration backlog

Status: **scope frozen; implementation pending**. This inventory is based on qualified integration [`5e3a991088aaa735c8f324c4e70a7a3dee4cd69a`](https://github.com/dwijayuda/pskernel/tree/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0), whose compiler products were qualified at `99786185f77edf952f11989d4c9bc44028f22f11`. It defines the remaining **practical v1 source migration** as **12 named workers across 9 existing Lean files**, plus **3 post-selection projection-alias removals in 2 declarations of one other file**. It does not claim every old worker must be rewritten, or that full PSCV/strict SH/1 is complete.

The accompanying [migration-backlog.json](migration-backlog.json) records exact declaration paths, lines, Git blob identities, complete existing headers, structural majors, moved state types, callers, preservation cases, guard identities, and the complete locator ledger.

## Current grammar direction and scope

The user requests the new uploaded **.ps grammar only** in the current implementation. Parser, printer, raw fixtures and tooling must move together in a separately qualified atomic grammar change. This backlog does not propose a dual active grammar, general PSCV support, or changing the pinned Lean/provider version. Immutable historical revisions remain recovery material. The selected A compiler can still build an implementation written in its accepted `.lean` authoring forms.

The practical finish line consists of the coordinated grammar checkpoint, the parameter-projection repair, explicit recoverable successor-seed selection, the 12 workers below, the three alias removals and the final adoption evidence. Optional inference, nested patterns, general equations, new backends and converting the implementation itself to authoritative `.ps` source are outside that finish line. Full strict SH/1 has its own remaining runtime/semantic obligations described in [RUNTIME_IR_PLAN.md](RUNTIME_IR_PLAN.md).

## What was inspected

All **61 raw modules**, **1,088,337 UTF-8 bytes** and **142 import edges** in the current composition-root closure were read. Reconstructing the supported import graph from [SelfHost.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean) reached every fetched module and found no missing dependency. The closure digest already bound by the qualification receipts is `1dbe0be4f97ad51c2898b86546590d4331b463dd080976ba4cb2c72f0e7c59a0`.

Discovery masked nested comments and string/character literals, located top-level declarations and balanced binder/type delimiters. It found **241 function-valued result headers** among 1,311 ordinary assigned definitions; a further 20 equation declarations were recorded separately. These are **locators, not 241 migration targets**. The complete bodies of the 12 selected workers were then reviewed for structural decrease, type dependencies, recursive uses, callback boundaries, state flow and errors. No full parser, build or runtime test was run for this inventory.

All **189 files immediately under psc0/scripts**, all **9 root test files**, and all **14 files in test/fixtures** were also read for caller and guard coverage. That is a bounded owned-source audit, not a claim about every file in the repository.

## Why these twelve

Every selected worker has one immediate `Nat` predecessor or `List` tail as its structural major, ordinary nondependent value state, exactly one typed `smaller` binding to the structurally recursive partial application, and saturated uses of that binding. The intended edit moves the returned state-domain telescope into ordinary declaration parameters, removes the handwritten branch lambdas and `smaller` adapter, and writes fully saturated self calls. It preserves the complete public type, parameter order and wrappers.

The selection covers both remaining requested authoring families: bounded fuel/index state and ordered compiler state. It avoids combining a language migration with new data structures, changing name algorithms, removing fuel, changing error policies, or refactoring defeq/cache/provider internals. Each selected declaration is small enough to review in full. The 12 present bodies span 269 source lines including intervening whitespace; that is an inventory size, not a predicted diff or performance gain.

Ten workers use capability already qualified in A. Two state folds directly project a parameter that must be renamed by normalization and therefore depend on the repaired, qualified, explicitly selected successor seed. Planning all twelve now prevents discovering those dependencies one failed test at a time.

### F1 — bounded fresh-name/index workers

Four declarations in four source files:

| ID | Declaration | Structural major | Ordinary state to expose | Required seed |
| --- | --- | --- | --- | --- |
| F1-01 | [`psErasureLocalNameWithFuel`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Basic.lean#L357) | `fuel : Nat` | `index : Nat` | Existing A capability |
| F1-02 | [`psErasureEtaNameWithFuel`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Expr.lean#L1354) | `fuel : Nat` | `index : Nat` | Existing A capability |
| F1-03 | [`psTsFreshMatchTempWorker`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean#L53) | `attempts : Nat` | `index : Nat` | Existing A capability |
| F1-04 | [`psTsFreshInternalWorker`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean#L14) | `attempts : Nat` | `index : Nat` | Existing A capability |

### F2 — ordered compiler-state folds

Eight declarations in six source files. The two families overlap in BackendTs/Module.lean, giving nine distinct target source files overall.

| ID | Declaration | Structural major | Ordinary state to expose | Required seed |
| --- | --- | --- | --- | --- |
| F2-01 | [`psCompilerPreparationSourcesWorker`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/compiler/src/Ps/Compiler/Api.lean#L154) | `sources : List String` | `state : PsCompilerPreparationState` | Existing A capability |
| F2-02 | [`psAddDeclarationListWorker`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/elab/src/Ps/Elab/Declaration.lean#L654) | `declarations : List PsDeclaration` | `environment : PsEnvironment` | Existing A capability |
| F2-03 | [`psElabDeclarationsWorker`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/elab/src/Ps/Elab/Declaration.lean#L1446) | `sources : List PsSyntaxDeclaration` | `environment : PsEnvironment`; `declarationsRev : List PsDeclaration` | Existing A capability |
| F2-04 | [`psBuildErasureDeclarationNamesWorker`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Definition.lean#L38) | `declarations : List PsDeclaration` | `state : PsErasureNameState` | Qualified projection seed |
| F2-05 | [`psEraseDefinitionsLoopWorker`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Definition.lean#L402) | `declarations : List PsDeclaration` | `declarationsRev : List PsVerifiedIrDeclaration` | Existing A capability |
| F2-06 | [`psPrepareRuntimeStructures`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Structure.lean#L106) | `inputs : List PsDeclaration` | `scope : PsErasureScope`; `structuresRev : List PsVerifiedIrStructure` | Existing A capability |
| F2-07 | [`psPrepareRuntimeInductives`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Inductive.lean#L367) | `inputs : List PsDeclaration` | `scope : PsErasureScope`; `irRev : List PsVerifiedIrInductive` | Existing A capability |
| F2-08 | [`psTsBuildSymbolMap`](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean#L37) | `names : List String` | `state : PsTsSymbolMapState` | Qualified projection seed |

## Per-declaration preservation and evidence

All declarations keep the root structural match visible, fixed parameters fixed, old argument order, explicit state types, supported typed callback locals, typed match initializers and simultaneous recursive-argument evaluation. Public partial application remains part of correspondence evidence.

### F1-01 — psErasureLocalNameWithFuel

Source: [psc0/packages/erasure/src/Ps/Erasure/Basic.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Basic.lean#L357), declaration line 357. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Zero fuel returns base + "$" + decimal index even if already used; do not replace it with a refusal.
- The same local/global collision predicate and index successor order; callers retain their input-derived fuel.

Bounded correspondence cases: fuel zero with unused and colliding candidate; collision chain, nonzero starting index; unchanged wrapper fuel and reserved-name handling.

### F1-02 — psErasureEtaNameWithFuel

Source: [psc0/packages/erasure/src/Ps/Erasure/Expr.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Expr.lean#L1354), declaration line 1354. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Zero fuel returns fuelExhausted.
- Preserve used-parameter check before body-name scan; retain the 4096 scan limit and __ps_eta_ spelling.
- Typed sameName callback remains a supported typed local; this migration is not lambda-inference work.

Bounded correspondence cases: zero fuel; collision in used list, in body, and in both; exact first fresh suffix; conservative exhausted body scan.

### F1-03 — psTsFreshMatchTempWorker

Source: [psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean#L53), declaration line 53. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Zero attempts returns exactly __ps$match$overflow.
- Preserve the 4096 expression-use scan and candidate sequence __ps$match$<index>.

Bounded correspondence cases: zero attempts; first free name and several collisions; nonzero index and conservative scan exhaustion.

### F1-04 — psTsFreshInternalWorker

Source: [psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean#L14), declaration line 14. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Zero attempts returns prefix + overflow and nextIndex = index + 1.
- A successful result also advances nextIndex once; only collisions consume another attempt.
- Preserve arbitrary prefix and duplicate used-name handling.

Bounded correspondence cases: zero attempts including colliding overflow spelling; duplicates, collision chains, nonzero starting index; exact returned name and nextIndex.

### F2-01 — psCompilerPreparationSourcesWorker

Source: [psc0/packages/compiler/src/Ps/Compiler/Api.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/compiler/src/Ps/Compiler/Api.lean#L154), declaration line 154. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Step sources in order using the same preparation seam.
- Empty input returns the incoming state; first failure stops before preparing the tail.
- Do not alter session identities, cache invalidation, source kinds, declaration accumulation or admission ownership.

Bounded correspondence cases: empty/nonempty initial state; success order and failure in first/middle source; existing cold/warm and parsed-step correspondence.

### F2-02 — psAddDeclarationListWorker

Source: [psc0/packages/elab/src/Ps/Elab/Declaration.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/elab/src/Ps/Elab/Declaration.lean#L654), declaration line 654. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Keep psEnvironmentAddOwnedBootstrapDeclaration, its ownership behavior and first duplicateDeclaration name.
- Empty input preserves environment; no later insertion after the first duplicate.
- Do not change the environment/index implementation.

Bounded correspondence cases: empty list; ordered insertions; duplicate against initial environment and earlier input.

### F2-03 — psElabDeclarationsWorker

Source: [psc0/packages/elab/src/Ps/Elab/Declaration.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/elab/src/Ps/Elab/Declaration.lean#L1446), declaration line 1446. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Elaborate each batch, add its declarations, then advance with that environment and reverse-prepended batch.
- Preserve first elaboration/duplicate failure, batch order, caller-supplied accumulator suffix and final reversal.
- Keep psElabDeclarations public argument order environment, sources, declarationsRev.

Bounded correspondence cases: empty input with nonempty accumulator; multiple batches and dependency on earlier declaration; elaboration failure, duplicate failure, exact first error.

### F2-04 — psBuildErasureDeclarationNamesWorker

Source: [psc0/packages/erasure/src/Ps/Erasure/Definition.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Definition.lean#L38), declaration line 38. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Keep the exact declaration whitelist: definition, partial, theorem and inductive names; skip other declarations.
- Keep identifier sanitization, default decl spelling, 4096 uniqueness fuel, collision order and entriesRev order.
- Retain the typed Option-valued match local; do not change the unique-name algorithm or reverse helper.

Bounded correspondence cases: each accepted/skipped declaration form; empty/nonempty initial used and entriesRev; sanitization collisions and exact ordered output.

### F2-05 — psEraseDefinitionsLoopWorker

Source: [psc0/packages/erasure/src/Ps/Erasure/Definition.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Definition.lean#L402), declaration line 402. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Process definition and partial declaration branches identically as before; skip the same remaining forms.
- Preserve error before Option handling, erased-result omission, first-error order and final local reversal.
- Keep environment and scope fixed and preserve psEraseDefinitionsLoop argument order.

Bounded correspondence cases: empty/nonempty initial accumulator; ordinary, partial, erased and skipped declarations; first error and exact emitted declaration order.

### F2-06 — psPrepareRuntimeStructures

Source: [psc0/packages/erasure/src/Ps/Erasure/Structure.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Structure.lean#L106), declaration line 106. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Visit only inductive declarations whose isStructure flag is true.
- Thread prepared.scope after success, preserve all skip paths and reverse output exactly once.
- Retain first failure and the full fixed declaration list used for lookup.

Bounded correspondence cases: mixed declaration stream and nonempty initial accumulator; scope dependencies between successive structures; first malformed structure; skip ordinary inductives.

### F2-07 — psPrepareRuntimeInductives

Source: [psc0/packages/erasure/src/Ps/Erasure/Inductive.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/erasure/src/Ps/Erasure/Inductive.lean#L367), declaration line 367. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Visit only inductive declarations whose isStructure flag is false.
- Thread prepared.scope after success, preserve skip paths, first failure and final reversal.
- Do not change constructor preparation, layout policy, lookup or recursor implementation.

Bounded correspondence cases: mixed declaration stream; skip structures; scope dependencies between successive inductives; first invalid inductive and exact output order.

### F2-08 — psTsBuildSymbolMap

Source: [psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean#L37), declaration line 37. Preserve the complete type and argument order recorded in [migration-backlog.json](migration-backlog.json).

- Keep fresh-name generation, used list, nextIndex and entriesRev updates in their existing order.
- Both brand and tag wrappers retain their prefixes, initial states and final output handling.
- Repeated source names and collisions keep the existing mapping behavior.

Bounded correspondence cases: empty and nonempty initial symbol state; duplicate source names and used-name collisions; exact name/index/map order for both callers.

## Guard changes are finite

Seven directly associated guard files require review alongside the 12 conversions:

| Guard | Relevant changes and preserved protection |
| --- | --- |
| [check-replay-emission-source.mjs](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/check-replay-emission-source.mjs) | Replace the fresh-local `smaller` spelling marker. Keep reserved names, input-derived fuel, name lookup, invocation and record-emission checks. |
| [check-backend-ts-replay-source.mjs](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/check-backend-ts-replay-source.mjs) | Replace three migrated partial-call markers. Keep other workers, supported-library restrictions, exact intrinsic coverage/arity and emission checks. |
| [check-modular-preparation-source.mjs](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/check-modular-preparation-source.mjs) | Replace the `smaller next` form. Keep ordered shared environment, structure fields, source ownership, admission derivation and session verification. |
| [check-elab-declarations-selfhost-source-syntax.mjs](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/check-elab-declarations-selfhost-source-syntax.mjs) | Replace curried worker/branch markers. Keep public wrapper order, batch accumulation, local reversal and first-error behavior. |
| [check-erasure-declaration-names-selfhost-source-syntax.mjs](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/check-erasure-declaration-names-selfhost-source-syntax.mjs) | Replace the state-currying requirements. Keep accepted declaration forms, sanitization, uniqueness budget, explicit state construction and the untouched output reverse helper. |
| [check-erasure-definitions-loop-selfhost-source-syntax.mjs](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/check-erasure-definitions-loop-selfhost-source-syntax.mjs) | Replace worker/recursive-call markers. Keep both definition cases, sequential Except/Option behavior, ordered results and the untouched reverse helper. |
| [check-erasure-replay-workers.mjs](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/check-erasure-replay-workers.mjs) | Replace the two aggregate-fold partial-call markers. Keep all other erasure worker checks, layout boundaries, explicit constructors, first-error ordering and mutation refusals. |

A spelling guard is retired only where new capability and correspondence evidence covers its reason for existing. Do not turn this into wholesale guard deletion. `psAddDeclarationListWorker` and `psErasureEtaNameWithFuel` have no direct name-specific guard in the 189 scanned scripts; they still need their stated family correspondence cases.

[SelfhostReplayAudit.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/SelfhostReplayAudit.lean#L336) directly calls both runtime aggregate folds. Their complete types and argument order remain unchanged, so those callers should need no edit.

## Exactly three compatibility aliases after seed selection

In [CompilerIr/Check.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/compiler-ir/src/Ps/CompilerIr/Check.lean), the post-selection cleanup is:

| Declaration | Base line | Alias |
| --- | --- | --- |
| `psIrCheckMatchBindings` | 339 | `limits : PsIrCheckOptions := options` |
| `psIrCheckRun` | 816 | `currentState : PsIrCheckState := state` |
| `psIrCheckRun` | 825 | `currentState : PsIrCheckState := state` |

These remain until the selected compiler actually accepts direct projections in the required changing-parameter context. The cleanup keeps the root matches, resource accounting, diagnostic policy and runtime typing behavior. Successful compilation by a new candidate alone is not seed selection.

## Recoverable TS7 successor seed

The existing [schema-1 validator](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/sh1-seed-manifest.mjs) is deliberately specific: historical S0 bootstrap, producer TypeScript 5.8.3, the original authoring descriptor and the original recovery recipe. The current [qualification script](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/sh1-qualify.mjs) retains A and explicitly declines automatic TS7 promotion. Preserve both facts.

A successor needs a separate versioned manifest/recovery contract. Bind the exact immutable parent A manifest, parent identity/compiler digest, new source revision/closure, all four converged product hashes, TS7 producer identity, Node/platform/architecture/Lean execution tuple, authoring capability descriptor and recovery recipe. Use an identity/cache namespace appropriate to that contract; changing a v1 checker to accept arbitrary TS versions would not preserve A's identity.

The minimum ordered sequence is:

1. Keep the new implementation's `.lean` source A-consumable, including the three aliases.
2. Qualify raw successor source R: **C1 = Q(R), C2 = C1(R), C3 = C2(R)**, where Q is the selected compiler from A. Newly generated compilers exercise current new-grammar `.ps` fixtures. Require four-product C2/C3 equality, same-IR typing, relevant behavior and separate exact-stream provider acceptance.
3. Add versioned selection/identity/cache/artifact/recovery dispatch while preserving the old S0/A TS5 route exactly.
4. The source recovery edge is **recover A under TS5 → execute exact Q on R → compile emitted TS with TS7 → run that first compiler on R → compare all four pinned successor products**. Historical TS replay stays TS5; new generation stays TS7. The existing per-child explicit launcher/PATH selection must be retained.
5. Reuse the producing qualification as the artifact-free source-recovery exercise only if it actually runs through the same recovery implementation, bypasses cache/artifact inputs at that edge, and verifies the final pinned products. Otherwise one explicit source-recovery verification remains before selection. An artifact replay is not that evidence.
6. Select the exact qualified recoverable manifest in a normal expected-HEAD commit. Selection enables the capability; it does not activate strict SH/1.
7. Apply the projection-dependent worker edits and alias cleanup. Current grammar stays new-only; immutable old revisions remain the reproducible parent chain.

## What is intentionally outside this finish line

The locator ledger retains every discovered function-valued header. Twelve are selected; three inspected nonrecursive interfaces are retained (`psPreludeProdOf`, `psPreludeArrayOf`, `psCompilerElaborateSourcesWorker`); the remaining **226 locators are deferred without a claim that all are safe conversion targets**.

Reasons differ:

- Function values are legitimate. The two prelude helpers construct Core application values, and the compiler elaboration wrapper delegates to the preparation seam. Their arrows do not establish a recursion workaround.
- Fixed-target searches such as `psTsLookup` and `psErasureIndexFindInBucket` pass the search target unchanged. Rewriting their result spelling does not unlock changing-state capability.
- Large parsing/elaboration/erasure/emission workers pass smaller functions as callbacks, carry depth policy, or have broad error/case contracts. Examples include `psElabTermWithFuel`, `psEraseRuntimeExprWithFuelWorker` and `psTsEmitTypeWithFuel`. A regex that moves every arrow parameter would not prove these transformations.
- Syntax/lexer/JSON cleanup should not expand the active atomic grammar change into a second broad refactor.
- Normalizer self-dogfooding is optional after its seed is qualified. Keep its implementation A-consumable during the current repair.
- Foundation.Name, Core, Environment index, Meta and checked-admission changes have high fan-in or overlap protected defeq/cache/kernel/metatheory responsibilities. This source-authoring milestone does not modify those implementations.
- Expected-type lambda domains, nested patterns, Except-only do, general equations, extra backends and authoritative `.ps` implementation source are independent follow-on work.

## Efficient execution and the stop condition

Review both families and all seven guard changes before running a candidate gate. Keep immutable before slices, compare their complete public types and bounded behavior under the selected generated compiler, and include partial application plus nonempty initial state. Reuse the existing iteration, let-shadowing, generic-erasure and IR checks where they already cover the relevant behavior.

Use the native development gate before expensive generation. Keep two source commits and two family-specific correspondence receipts. If both families are reviewed together, one combined final-source C1/C2/C3 qualification may cover their shared result; record that joint source honestly. Split full qualification only for an intervening promotion or a concrete remaining risk. Do not run a full compiler fixed point after each helper.

The target is authoring efficiency. Cleaner source does not itself prove faster generated code; inspect existing loopification/evaluation behavior and use recorded stage timings. Do not attribute all self-host time to TypeScript compilation.

Practical v1 is complete once the coordinated grammar/projection capability checkpoint is qualified and recoverably selected, all twelve workers and the three aliases are migrated with their preserved contracts, replacement guards and family receipts pass, the final exact source has its four-product fixed point and separate provider acceptance, and current-source iteration still works. Stop there. Extra locator cleanup is a new scoped objective.

## Scoped projection caller audit

At the immutable base, neither `psElabRecursionWalkWithFuel` nor `psElabRecursionRenameParameters` appears outside [Elab/Recursion.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/elab/src/Ps/Elab/Recursion.lean) across the 61-module closure, 189 scripts, 9 root tests and 14 fixtures. Walk occurrences are lines 272 (definition), 283, 520, 583, 587 and 652. Rename occurrences are lines 499 (definition), 514 and 580. The owned signature update therefore has no external existing callers in that scope. Concurrent/new branch edits still need their own audit.

This inventory performed no source edit, compiler run, seed selection, local checkout or shell operation. Its immutable identities and complete discovery ledger are retained in [migration-backlog.json](migration-backlog.json).

## Additional current-grammar feasibility audits

A balanced declaration-header audit of all **1,500 top-level declarations** in the 61-module closure (1,331 definitions, 56 inductives, 113 structures) found **zero implicit/instance parameter groups following an explicit group**. The new declaration rule requiring nonexplicit parameters before the explicit parameter group therefore does not require reordering public binders in this existing closure. This is a scoped source-order finding, not proof that every term prints in the new grammar.

Adding a new `PsSourcePrintError.unsupportedSourceForm` variant requires one additional exhaustive native renderer update in the same 273-file owned audit: [test/IrCheckerTests.lean::psIrNativePrintErrorText](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/test/IrCheckerTests.lean#L177), currently handling only `fuelExhausted`, `unsupportedApplication` and `emptyName`. No other exhaustive consumer of the three requested error enums was found in that scope. `psElabDeclarationBatch` already rethrows other `PsElabError` variants through a wildcard. Native host files outside the raw closure, including the known HostProjectCompiler renderers, remain the integration owner's scope.
