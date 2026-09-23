# Lean 4.34 kernel study and continuation plan

Status: active research note for `kernel/lean434-study-hardening`.

## Purpose

This branch continues the trusted-kernel work without disturbing `main`. The
compatibility target remains **final Lean 4.34.0**. The goal of this study is to
use the checked-in source corpus to decide what work is actually missing before
adding kernel code.

The branch was cut from main at:

- `586dbdac71c0efa6ca7cf3dc0c634e83727f621d`

The first continuation fixes are:

- `3dda273` — restore valid JavaScript syntax in the canonical module-stream
  replay runner;
- `50bff93` — make the normal test gate syntax-check the canonical Full-Std
  oracle runners so the same failure cannot silently return.

The Full-Std semantic gate is **not** marked complete by either fix. A fresh
canonical replay is still required.

## Source-of-truth hierarchy

Use these sources in this order when behavior disagrees.

### 1. Final Lean 4.34 C++ kernel — behavioral oracle

Primary study paths:

- `study/lean4-4.34.0/src/kernel/type_checker.cpp`
- `study/lean4-4.34.0/src/kernel/inductive.cpp`
- `study/lean4-4.34.0/src/kernel/quot.cpp`
- `study/lean4-4.34.0/src/kernel/environment.cpp`
- `study/lean4-4.34.0/src/kernel/declaration.cpp`
- supporting expression, level, instantiation and local-context files under
  `study/lean4-4.34.0/src/kernel/`.

This tree is the compatibility oracle. pskernel must match this release even
when a theoretically cleaner implementation or a later Lean release behaves
differently.

### 2. Final Lean 4.34 kernel regressions — executable adversarial contract

Especially important:

- `tests/elab/kernelProjIdx.lean`
- `tests/elab/kernelProjSname.lean`
- `tests/elab/kernelImaxProp.lean`
- `tests/elab/kernelImaxPropInductive.lean`
- `tests/elab/kernelNestedAuxName.lean`
- `tests/elab/kernelMutualDupName.lean`
- `tests/elab/kernel_is_def_eq_equiv_manager_1.lean`
- `tests/elab/kernel_is_def_eq_equiv_manager_2.lean`
- `tests/elab/kernelMaxRecDepth.lean`
- `tests/elab/kernelErrorFollowup.lean`
- `tests/elab/kernelBacktrack.lean`
- `tests/elab_fail/kernelMVarBug.lean`
- `tests/elab_fail/kernelQuotNameCollision.lean`.

These tests are more useful than prose when checking a subtle edge because they
pin a concrete accept/reject/reduce behavior.

### 3. Lean4Lean — independent implementation guide and formal cross-check

Key paths:

- `study/lean4lean-master/Lean4Lean/TypeChecker.lean`
- `study/lean4lean-master/Lean4Lean/Inductive/Add.lean`
- `study/lean4lean-master/Lean4Lean/Inductive/Reduce.lean`
- `study/lean4lean-master/Lean4Lean/Quot.lean`
- `study/lean4lean-master/Lean4Lean/Verify/TypeChecker/InferType.lean`
- `study/lean4lean-master/Lean4Lean/Verify/TypeChecker/WHNF.lean`
- `study/lean4lean-master/Lean4Lean/Verify/TypeChecker/IsDefEq.lean`
- `study/lean4lean-master/bugs-found.md`
- `study/lean4lean-master/divergences.md`.

Important limitation: the checked-in Lean4Lean snapshot pins
`leanprover/lean4:v4.33.0-rc2`, not final 4.34. Its own README says the
implementation is derived directly from the C++ kernel, and
`divergences.md` documents deliberate differences. It is therefore a
secondary reference, never the final oracle for this branch.

### 4. Post-4.34 Lean kernel work — test-idea source only

Current upstream work discusses larger kernel-logic renovations such as more
complete level reasoning and redesigned definitional-equality behavior. Those
ideas must not be imported into a branch whose explicit target is final 4.34.
They can inspire adversarial tests for a future target bump.

## What the study says pskernel already has

The existing code is well beyond a skeleton. Direct source inspection and
`PROGRESS.json` show that the following 4.34-sensitive surfaces are already
implemented and regression-locked.

| Lean 4.34 concern | Reference | Current pskernel mapping | Audit result |
| --- | --- | --- | --- |
| Type inference, WHNF and algorithmic defeq | `type_checker.cpp` | `src/kernel/type-checker.ts` | present |
| Pair-local defeq caching, no transitive closure | `kernel_is_def_eq_equiv_manager_*.lean` | `KernelState` + direct regression | present |
| Theorem/opaque non-delta behavior | `type_checker.cpp` | `deltaInfo` accepts definitions only | present |
| Projection family validation | `kernelProjSname.lean` | inference and reduction validate structure family | present |
| Projection index width | `kernelProjIdx.lean` | integral uint32 validation | present |
| Prop recognition modulo level normalization | imax regressions | `normalizesToZero` path | present |
| Proof-irrelevant projection restrictions | projection/Prop regressions | `inferProj` checks Prop/data elimination | present |
| Quotient bootstrap and reduction | `quot.cpp` | `quotient.ts`, `reduction/quot.ts` | present |
| Quot primitive collision rejection | `kernelQuotNameCollision.lean` | `addQuot` fails before insertion | present |
| Ordinary/mutual/indexed inductives | `inductive.cpp` | `inductive/ordinary.ts` | present |
| Nested inductive elimination/restoration | `inductive.cpp` | `inductive/nested.ts` | present |
| Generated recursor type/rule validation | 4.34 recursor hardening | ordinary + nested preservation checks | present |
| Uniform inductive occurrence checks | 4.34 inductive hardening | constructor occurrence validation | present |
| Max recursion depth | kernel depth regression | explicit `maxRecDepth` guard | present |
| Bounded trusted Nat reduction | final 4.34 kernel | `maxNatBytes` and reducer guards | present |
| Primitive recognition | final Init behavior | `primitive.ts` and primitive submodules | present |
| Imported environment replay | Lean4export boundary | `src/integration/lean4export.ts` | present |

This means the next useful kernel work is **not** another checker, another defeq
engine, or a rewrite from Lean4Lean. One implementation per concern remains the
right anti-drift rule.

## Important Lean4Lean divergences not to copy blindly

The checked-in `divergences.md` is especially valuable because it explains
places where a superficially attractive Lean4Lean implementation would move us
away from the target.

Examples include:

1. level normalization/comparison can decide more equalities than the released
   C++ kernel;
2. projection treatment for universe levels that are neither provably zero nor
   provably nonzero differs;
3. some projection reduction checks are omitted because Lean4Lean relies on
   prior typing invariants;
4. nested-inductive restoration rechecks differ because Lean4Lean aims to prove
   the transformation correct;
5. reserved `_nested` handling differs;
6. fuel accounting differs from final kernel `maxRecDepth`;
7. unsafe/partial recursive-definition admission differs;
8. some mutual-definition restrictions described there correspond to work
   newer than the snapshot's released target.

For pskernel, these are comparison points, not porting instructions.

## 4.34 hardening themes that matter most

The final 4.34 release concentrated unusual attention on trusted-kernel
hardening. The study corpus and upstream release record converge on several
themes:

- algorithmic definitional equality must not gain unsound equivalence closure
  through caching;
- generated recursors and computation rules must be validated, not merely
  assumed correct because the generator produced them;
- inductive occurrences must remain uniform where parameters and universes are
  required;
- projection typing/reduction must agree on family identity, index width and
  Prop elimination;
- trusted Nat computation needs an explicit resource bound;
- rejected declarations and failed branches must not poison subsequent kernel
  state;
- kernel-specific generated/reserved names must not be forgeable by ordinary
  declarations.

These should remain first-class regression categories as the corpus expands.

## Current completion gates

`PROGRESS.json` currently leaves only these top-level kernel-completion gates
open:

1. `full-Std-environment-replay`
2. `full-Lean-environment-replay`
3. `formal-equivalence-proof`

This is the correct ordering.

### Native reduction boundary audit

Final Lean 4.34 has two observable reduction orders that must both be preserved:

- kernel `whnf`: `whnf_core -> reduce_native -> reduce_nat -> delta`;
- lazy definitional equality: offset check -> conditional Nat reduction -> native
  reduction -> lazy delta.

The TypeScript checker follows both orders. Its native marker shape also matches
C++: a level-free `Lean.reduceBool` or `Lean.reduceNat` application with one
constant argument, evaluated by name through an explicit TCB provider.

The Lean-backed provider deliberately does **not** call
`Meta.reduceBoolNative`/`Meta.reduceNatNative`. Those helpers route through
`Environment.evalConstCheck` and add declaration-type/meta-IR restrictions
that final C++ `reduce_native` does not impose. The oracle instead constructs
the exact `Lean.reduceBool c` / `Lean.reduceNat c` marker and calls pinned
Lean 4.34 `Kernel.whnf`. This enters the reference C++ `reduce_native`
implementation itself, so `run_boxed_kernel`, `@[implemented_by]`/extern
behavior, and Bool/Nat runtime-object validation are all taken from the same
code path we are comparing against.

Direct coverage now includes the native cases from upstream `kernel1.lean`:
equality/disequality of compiler-reduced Nat definitions, symmetric reduction to
`Nat.zero`, and Bool false versus `Bool.true`. `native-oracle-smoke` remains
the executable check that the external provider actually observes
`@[implemented_by]`; it still requires the pinned Lean runtime.

### Gate 1 — canonical Full Std

Use the project-canonical single-stream replay as the release gate, not
dependency-root batch success. Root seeding follows each imported module's
`EnvironmentHeader.moduleData[idx].constNames`, i.e. the serialized `.olean`
constant sequence actually loaded for that module, with first-occurrence
deduplication across modules. The deduplication is required because Lean 4.34
`finalizeImport` explicitly permits compatible duplicate private theorem names
across module data while `env.constants.map₁` contains one final ConstantInfo
per name. **Do not call this source declaration order**: Lean 4.34 may name-sort
exported module data, and its own `Kernel.Environment.replay` seeds a `NameSet`
rather than promising source order.
The exporter recursively emits dependencies before each root and carries one
global emitted set, so each replayable declaration is exported once into one
shared pskernel environment while replay-local intern/cache state is discarded
between shards. The canonical gate follows Lean 4.34
`Kernel.Environment.replay` exactly on scope: constants with
`ci.isUnsafe || ci.isPartial` are excluded from kernel replay. They are not
silently forgotten: release evidence reports the total corpus, replayable count,
unsafe skip count, partial skip count, and actual replayed environment size.
Diagnostic root-range tooling keeps its existing deterministic Name.quickLt
numbering so historical hot-range indices remain stable.

Quotient replay follows Lean's special case as well: before emitting any
`quotInfo`, the exporter recursively emits `Eq`. This is required even when
the current Quot root does not mention `Eq`, because adding the quotient
declaration installs the whole Quot family and `Quot.lift`/`Quot.ind` depend
on `Eq`.

The latest checked-in `full-std.log` did not produce semantic evidence: it
failed before replay because `scripts/module-stream-oracle.mjs` contained a
literal `\\n` before the final `console.log`, which made the module invalid
JavaScript. Commit `3dda273` fixes that syntax defect. Commit `50bff93`
makes normal tests syntax-check this runner and its Full-Std wrapper.

Next evidence required: a fresh `npm run oracle:std-full` using the pinned
Lean 4.34 toolchain. If it fails after replay begins, isolate the **first**
failing module/declaration and treat that as the next kernel task.

### Gate 2 — full Lean environment

Only after Full Std passes should the exhaustive `Lean.*` imported
environment become the active gate. Existing bounded `Lean.Data.RBMap`,
PersistentArray and PersistentHashMap evidence is useful but is not a substitute
for the whole environment.

Failure workflow:

```text
full environment failure
-> first failing module
-> first failing declaration
-> minimal exported dependency closure
-> C++ 4.34 behavior
-> matching TypeScript regression
-> smallest semantic patch
-> bounded regression
-> resume full stream
```

Never patch around a failing declaration in the importer merely to increase
coverage.

### Gate 3 — formal equivalence

Corpus parity is evidence, not a proof of equivalence. Formal work should start
from stable interfaces after the exhaustive environment gates are green.

Lean4Lean is valuable here because its `Theory` and `Verify` directories
show a workable decomposition:

- representation/translation invariants;
- level correctness;
- expression typing;
- environment well-formedness;
- inference;
- WHNF/reduction;
- definitional equality;
- inductive and quotient obligations.

For pskernel, a practical formal-equivalence project should first state a
precise relation between TypeScript kernel states/expressions and a Lean model.
Do not attempt to "prove the TypeScript source" directly before that semantic
relation is explicit.

## Branch working rules

For `kernel/lean434-study-hardening`:

1. preserve the final Lean 4.34 compatibility pin;
2. C++ final-4.34 source wins disagreements;
3. use Lean4Lean as a second implementation/formalization reference;
4. add a regression before or with every semantic fix;
5. fail closed on unsupported imported declarations;
6. never trust exported generated metadata as admission authority;
7. diagnose the first exhaustive-corpus failure rather than adding speculative
   features;
8. do not duplicate checker/defeq/inductive implementations;
9. do not mark Full Std, Full Lean, or formal equivalence complete without the
   corresponding executable/proof evidence;
10. keep parser, elaborator, tactic, compiler and LSP concerns outside the
    trusted kernel.

## Immediate continuation sequence

- [x] Create isolated continuation branch from current `main`.
- [x] Inspect full Lean 4.34 and Lean4Lean study trees.
- [x] Cross-check 4.34 hardening areas against current TypeScript kernel.
- [x] Diagnose the existing Full-Std log before touching semantics.
- [x] Repair canonical module-stream runner syntax.
- [x] Add syntax regression for the canonical Full-Std runners.
- [ ] Execute fresh canonical Full Std.
- [ ] If it fails semantically, preserve the first failure as a regression and
      patch only the demonstrated parity gap.
- [ ] Once Full Std is green, construct/run canonical Full Lean stream.
- [ ] Freeze the resulting behavioral acceptance matrix.
- [ ] Begin formal-equivalence obligations against that frozen target.

## External research checkpoint

The external release record for Lean 4.34 confirms that this release includes
substantial kernel changes/hardening, including definitional-equality caching,
recursor validation, uniform inductive-occurrence checks and trusted Nat
resource limits. Upstream's post-4.34 kernel renovation work is intentionally
out of scope for this pinned branch.

Research date: 2026-09-23.
