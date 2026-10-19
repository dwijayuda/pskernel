# Finite practical self-host migration backlog

Initial F application: [`9ee0b1fd38dd1456a187d4675f9027440a989f2d`](https://github.com/dwijayuda/pskernel/commit/9ee0b1fd38dd1456a187d4675f9027440a989f2d). This is the initial attempt identity; any qualifying revision and its evidence are recorded separately below.

<a id="current-f-implementation-candidate"></a>

## Qualified F implementation

The frozen source inventory below describes the audited 5e3 baseline. The F
checkpoint implements its twelve eligible worker rewrites and three scoped typed
alias removals as one qualified change, with seven related source guards updated.
F at `fcd875c8f38db4b0524090bd10c7c2fd5024053d` is compiler-qualified and independently
provider-accepted in [F run 37947341800](https://github.com/dwijayuda/pskernel/actions/runs/37947341800). R2 source
`fe2560aba0f347b1caf8d000d371464642d44f23` passed compiler qualification and
independent provider acceptance in [run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635).
Cold recovery is verified, and [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) explicitly selects R.
F had not been applied at the original R2 evidence point. It subsequently used
that authenticated R compiler and earned its own qualification; R remains selected.

The implementation reuses existing prepared declarations and exact IR to check
all twelve complete public types and ordered runtime signatures. Its generated
behavior gate covers 87 independently expected cases. One coherent F generation
chain and the existing original-IR/provider gates qualify the combined change;
there is no separate full qualification run per worker. The complete locator
inventory and deferred groups remain historical audit data, outside this finite
migration. Current `.ps` stays new-only `ps-0.9-r3`, with `.lean` authoritative.

See [the current implementation ledger](proposal.json),
[the exact source fragments](worker-migration-candidate.json), and
[the migration sequence](MIGRATION.md#current-f-checkpoint-implemented-candidate-qualification-pending).

Historical inventory status at the audited baseline: **scope frozen; implementation pending**. This inventory is based on qualified integration [`5e3a991088aaa735c8f324c4e70a7a3dee4cd69a`](https://github.com/dwijayuda/pskernel/tree/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0), whose compiler products were qualified at `99786185f77edf952f11989d4c9bc44028f22f11`. It defines the remaining **practical v1 source migration** as **12 named workers across 9 existing Lean files**, plus **3 post-selection projection-alias removals in 2 declarations of one other file**. It does not claim every old worker must be rewritten, or that full PSCV/strict SH/1 is complete.

The accompanying [migration-backlog.json](migration-backlog.json) records exact declaration paths, lines, Git blob identities, complete existing headers, structural majors, moved state types, callers, preservation cases, guard identities, and the complete locator ledger.

## Current grammar direction and scope

The user requests the new uploaded **.ps grammar only** in the current implementation. R2 moved the parser, printer, raw fixtures and tooling together and earned separate compiler/provider qualification. Current PS has no legacy grammar mode. [IMPLEMENTATION.md](IMPLEMENTATION.md#r2-compiler-and-provider-evidence) records the compiler/provider evidence, verified cold recovery and explicit R selection. Immutable historical revisions remain recovery material. R2's implementation remains A-consumable `.lean`; qualified F used the selected R successor. This checkpoint does not claim general PSCV support or change the pinned Lean/provider version.

The practical finish line consists of the coordinated grammar checkpoint, the parameter-projection repair, explicit recoverable successor-seed selection, the 12 workers below, the three alias removals and the final adoption evidence. Optional inference, nested patterns, general equations, new backends and converting the implementation itself to authoritative `.ps` source are outside that finish line. Full strict SH/1 has its own remaining runtime/semantic obligations described in [RUNTIME_IR_PLAN.md](RUNTIME_IR_PLAN.md).

## What was inspected

All **61 raw modules**, **1,088,337 UTF-8 bytes** and **142 import edges** in the audited 5e3 composition-root closure were read. Reconstructing the supported import graph from [SelfHost.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean) reached every fetched module and found no missing dependency. The closure digest already bound by the qualification receipts is `1dbe0be4f97ad51c2898b86546590d4331b463dd080976ba4cb2c72f0e7c59a0`.

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

Before R selection, these aliases remained in R2's A-consumable source. R is now qualified, cold-recovered and explicitly selected. Qualified F removed only these three aliases and has its own retained source/runtime evidence. The cleanup keeps the root matches, resource accounting, diagnostic policy and runtime typing behavior. Successful compilation by a new candidate alone is not seed selection.

## Recoverable TS7 successor seed

The historical [schema-1 validator](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/sh1-seed-manifest.mjs) remains specific to S0 bootstrap, producer TypeScript 5.8.3, the original authoring descriptor and recovery recipe. The audited 5e3 [qualification script](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/scripts/sh1-qualify.mjs) retained A and declined automatic TS7 promotion. R2 adds a separate [successor manifest/recovery route](https://github.com/dwijayuda/pskernel/blob/fe2560aba0f347b1caf8d000d371464642d44f23/psc0/scripts/sh1-successor-seed.mjs); it does not broaden the historical validator or select its candidate automatically.

R2 implements the separate versioned successor contract. It binds the exact immutable parent A manifest, parent identity/compiler digest, new source revision/closure, all four converged product hashes, TS7 producer identity, Node/platform/architecture/Lean execution tuple, authoring capability descriptor and recovery recipe. Use an identity/cache namespace appropriate to that contract; changing a v1 checker to accept arbitrary TS versions would not preserve A's identity.

The sequence below records R's original qualification and selection history together with its now-proven TS7-only recovery route. R2's implementation, compiler/provider qualification, verified cold recovery and explicit selection are complete. Its selection is recorded by [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6); F has separately completed its source/runtime and provider qualification at `fcd875c8f38db4b0524090bd10c7c2fd5024053d`.

1. R2's implementation remains A-consumable `.lean`, including the three aliases. F's consumer source is a separate checkpoint after R selection.
2. Qualify raw successor source R: **C1 = Q(R), C2 = C1(R), C3 = C2(R)**, where Q is the selected compiler from A. Newly generated compilers exercise current new-grammar `.ps` fixtures. Require four-product C2/C3 equality, same-IR typing, relevant behavior and separate exact-stream provider acceptance.
3. R2's successor descriptor and embedded parent identity remain unchanged. The old S0/A TS5 recipes are retained as history; current tooling no longer executes their replay dispatch.
4. Current selected-R cache-miss recovery authenticates [the separate native policy](../../selfhost-seed-recovery.json), builds pinned R with native Lean, emits from its checked original IR, compiles with TypeScript 7, obtains native admissions and all 61 canonical `.ps` modules, and compares all four pinned R products before retaining the seed. It executes no parent compiler or TypeScript 5 profile.
5. The original pre-selection [cold-recovery receipt](grammar-migration-cold-recovery.json), SHA-256 `2aa93517b848da1493386ab9be50527275fe1a7a1c7e12f422d8d8431d8d9f1d`, remains historical evidence. The independent [TS7-native receipt](typescript7-native-recovery.json), SHA-256 `0d5606c25e634082da39d80ffa5974b3c390d2765ded71bcf1abaf442b7e3919`, passed [run 37947341899](https://github.com/dwijayuda/pskernel/actions/runs/37947341899) with all four R products matching and no seed/build cache or compiler artifact restored. The [reviewed evidence](typescript7-native-recovery-evidence.json) and [complete job log](evidence-logs/typescript7-native-recovery.log) retain that result separately from F qualification.
6. [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) selects the exact qualified, cold-recovered manifest, SHA-256 `7a0c2cf950333aa680f2ae00e214f57b674dab2d783a1403b242b92e71c56694`, with seed identity `47d88158e075f766f0d146ba3a13b28744c6e196d9844c71f4e52dc7351e2225`. Selection enables this authoring capability; it does not activate strict SH/1.
7. F's bounded source migration covers twelve ordinary-parameter workers and three typed projection-alias removals under selected R, with its own qualification evidence. Current grammar stays new-only. Old revisions remain historical evidence and do not create a current grammar or TypeScript 5 fallback.

## What is intentionally outside this finish line

The locator ledger retains every discovered function-valued header. Twelve are selected; three inspected nonrecursive interfaces are retained (`psPreludeProdOf`, `psPreludeArrayOf`, `psCompilerElaborateSourcesWorker`); the remaining **226 locators are deferred without a claim that all are safe conversion targets**.

Reasons differ:

- Function values are legitimate. The two prelude helpers construct Core application values, and the compiler elaboration wrapper delegates to the preparation seam. Their arrows do not establish a recursion workaround.
- Fixed-target searches such as `psTsLookup` and `psErasureIndexFindInBucket` pass the search target unchanged. Rewriting their result spelling does not unlock changing-state capability.
- Large parsing/elaboration/erasure/emission workers pass smaller functions as callbacks, carry depth policy, or have broad error/case contracts. Examples include `psElabTermWithFuel`, `psEraseRuntimeExprWithFuelWorker` and `psTsEmitTypeWithFuel`. A regex that moves every arrow parameter would not prove these transformations.
- Syntax/lexer/JSON cleanup should not expand the active atomic grammar change into a second broad refactor.
- Normalizer self-dogfooding remains optional. R2's repair stays A-consumable; broad normalizer cleanup is outside F.
- Foundation.Name, Core, Environment index, Meta and checked-admission changes have high fan-in or overlap protected defeq/cache/kernel/metatheory responsibilities. This source-authoring milestone does not modify those implementations.
- Expected-type lambda domains, nested patterns, Except-only do, general equations, extra backends and authoritative `.ps` implementation source are independent follow-on work.

## Efficient execution and the stop condition

Review both families and all seven guard changes before running a candidate gate. Keep immutable before slices, compare their complete public types and bounded behavior under the selected generated compiler, and include partial application plus nonempty initial state. Reuse the existing iteration, let-shadowing, generic-erasure and IR checks where they already cover the relevant behavior.

F1 and F2 were reviewed and qualified as one coherent exact source, with separate family observations inside the 87-case report and ABI observations from the existing prepared Core and IR. The chosen practical-v1 scope is complete. Use the bounded development route for ordinary edits; reserve further full qualification for a separately scoped promotion or concrete remaining risk.

The target is authoring efficiency. Cleaner source does not itself prove faster generated code; inspect existing loopification/evaluation behavior and use recorded stage timings. Do not attribute all self-host time to TypeScript compilation.

Practical v1 is complete: R supplies the qualified recoverable selected grammar/projection capability, and F supplies the twelve migrated workers, three alias removals, passing guards and correspondence/ABI/iteration results, four-product fixed point and independent provider acceptance. The retained F receipts bind those results to `fcd875c8f38db4b0524090bd10c7c2fd5024053d`. The 226 deferred locators remain outside this scope. Extra locator cleanup requires a new scoped objective.

## Scoped projection caller audit

At the immutable base, neither `psElabRecursionWalkWithFuel` nor `psElabRecursionRenameParameters` appears outside [Elab/Recursion.lean](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/packages/elab/src/Ps/Elab/Recursion.lean) across the 61-module closure, 189 scripts, 9 root tests and 14 fixtures. Walk occurrences are lines 272 (definition), 283, 520, 583, 587 and 652. Rename occurrences are lines 499 (definition), 514 and 580. The owned signature update therefore has no external existing callers in that scope. Concurrent/new branch edits still need their own audit.

This inventory performed no source edit, compiler run, seed selection, local checkout or shell operation. Its immutable identities and complete discovery ledger are retained in [migration-backlog.json](migration-backlog.json).

## Additional current-grammar feasibility audits

A balanced declaration-header audit of all **1,500 top-level declarations** in the 61-module closure (1,331 definitions, 56 inductives, 113 structures) found **zero implicit/instance parameter groups following an explicit group**. The new declaration rule requiring nonexplicit parameters before the explicit parameter group therefore does not require reordering public binders in this existing closure. This is a scoped source-order finding, not proof that every term prints in the new grammar.

Adding a new `PsSourcePrintError.unsupportedSourceForm` variant requires one additional exhaustive native renderer update in the same 273-file owned audit: [test/IrCheckerTests.lean::psIrNativePrintErrorText](https://github.com/dwijayuda/pskernel/blob/5e3a991088aaa735c8f324c4e70a7a3dee4cd69a/psc0/test/IrCheckerTests.lean#L177), currently handling only `fuelExhausted`, `unsupportedApplication` and `emptyName`. No other exhaustive consumer of the three requested error enums was found in that scope. `psElabDeclarationBatch` already rethrows other `PsElabError` variants through a wildcard. Native host files outside the raw closure, including the known HostProjectCompiler renderers, remain the integration owner's scope.
