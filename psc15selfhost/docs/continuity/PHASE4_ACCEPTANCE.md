# PSC2 KernelCore Phase 4 Acceptance

Status date: 2026-09-27

Execution branch: `psc2/kernel-core-phase4-infer-work`

Reviewed branch: `psc2/kernel-core-phase4-infer`

Accepted implementation/assurance SHA:

```text
bfc4c33c79f81aa86c7f025789dbdadd0740516d
```

Exact acceptance evidence:

```text
GitHub Actions workflow: PSC2 minimal kernel
run: 36304371396
job: 108577961901
conclusion: success
```

The acceptance record itself is intentionally committed after the tested implementation/assurance SHA. No semantic or CI change is permitted between that tested SHA and this documentation-only acceptance commit.

## Accepted Phase 4 scope

Phase 4 adds the smallest PSC1-self-hostable **infer-only** type-inference substrate required before definitional equality.

Trusted semantic additions are:

```text
Ps.KernelCore.Infer
```

plus the minimal binder-closing support needed by inference in `Ps.KernelCore.Subst`:

```text
psKernelCoreExprHasFVarName
psKernelCoreExprAbstractFVar
```

The primary accepted inference entry point is:

```text
psKernelCoreInfer :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreExpr
```

with helpers:

```text
psKernelCoreEnsureSort
psKernelCoreEnsureForall
```

Phase 4 deliberately models the overlap surface of public `PSC1Kernel.infer` / `inferCore ... true`; it is not checked inference and it does not perform declaration admission.

## Trusted closure

The exact tested head reports:

```text
KERNEL_CORE_SOURCE_PROFILE: PASS (11 PSC1-subset, self-host-checkable modules)
```

Trusted files:

```text
packages/pskernel-core/src/Ps/KernelCore.lean
packages/pskernel-core/src/Ps/KernelCore/Data.lean
packages/pskernel-core/src/Ps/KernelCore/Declaration.lean
packages/pskernel-core/src/Ps/KernelCore/Environment.lean
packages/pskernel-core/src/Ps/KernelCore/Expr.lean
packages/pskernel-core/src/Ps/KernelCore/Infer.lean
packages/pskernel-core/src/Ps/KernelCore/Level.lean
packages/pskernel-core/src/Ps/KernelCore/LocalContext.lean
packages/pskernel-core/src/Ps/KernelCore/Name.lean
packages/pskernel-core/src/Ps/KernelCore/Reduce.lean
packages/pskernel-core/src/Ps/KernelCore/Subst.lean
```

Every trusted file passed the real flattened-closure command path through:

```text
lake exe psc1 check <flattened-module>
```

This is stronger than Lean compilation or lexical source-profile linting alone.

## Direct inference evidence

The exact-head workflow reports:

```text
PSC2_KERNEL_CORE_INFER_PARITY: PASS
```

The direct differential fixture compares the supported Phase-4 surface with `PSC1Kernel.infer`, including:

- sort inference;
- ordinary local free-variable lookup;
- local let-variable declared-type lookup;
- monomorphic constants;
- polymorphic constants with universe substitution;
- bounded Nat literal typing;
- String literal typing;
- metadata transparency;
- nondependent lambdas;
- nested/dependent lambdas requiring fresh-local opening and result-type closing;
- forall universe formation through `imax`;
- nested/dependent foralls;
- nondependent lets whose type-level let can disappear;
- dependent lets whose inferred type retains the type-level let;
- visible forall application;
- dependent multi-application;
- hidden forall exposure through accepted Phase-3 delta reduction;
- infer-only application behavior that does not infer the argument;
- infer-only lambda behavior that does not validate the domain;
- infer-only let behavior that does not validate declared type/value;
- unsafe and partial constants remaining usable in infer-only mode;
- fresh-local naming with an already populated local context;
- stable negative behavior for loose bound variables, expression metavariables, unknown free variables, unknown constants, universe-arity mismatch, malformed forall formation, and non-function application.

KernelCore-only Phase-4 boundary fixtures also pin:

```text
budget 0 -> "inference budget exhausted"
projection -> "projection inference unavailable before inductive metadata"
```

The budget is a small-core totality boundary, not a claim of exact Lean recursion-depth accounting.

## Binder support evidence

Phase 4 introduced direct tests for the trusted single-free-variable binder helpers before inference depended on them.

The fixture exercises:

- target free-variable detection through recursive expression children;
- absence behavior;
- abstraction at top level and under lambda/forall/let binders;
- binder-depth handling;
- bound-variable shifting required by the approved small-core abstraction contract;
- preservation of metadata/projection/binder information;
- abstraction followed by single instantiation on the supported well-scoped fixtures.

These helpers passed both Lean tests and the actual PSC1 self-host source gate before `Infer.lean` was added.

## Foundational Level correction discovered by Phase 4

The first inference GREEN attempt exposed an older foundational mismatch rather than an `Infer.lean` bug.

The mature oracle simplifies explicit universe maxima such as:

```text
max 2 1 -> 2
imax 2 1 -> 2
```

The earlier small-core `psKernelCoreLevelMkMax` did not collapse that explicit-universe case, which became observable through nested forall inference.

Phase 4 therefore added a direct Level parity regression first and then made the smallest foundational correction in `Ps.KernelCore.Level`:

```text
psKernelCoreLevelExplicitOffset?
psKernelCoreLevelMkMaxFallback
```

`psKernelCoreLevelMkMax` now chooses the larger explicit finite universe when both operands are explicit offsets and otherwise retains the previous fallback behavior.

The exact acceptance run reports both:

```text
PSC2_KERNEL_CORE_LEVEL_PARITY: PASS
PSC2_KERNEL_CORE_INFER_PARITY: PASS
```

This correction is part of the accepted Phase-4 tree because the inference differential fixture made the missing foundational behavior observable.

## Preserved lower-layer evidence

The exact acceptance run reports success for:

```text
PSC2_KERNEL_CORE_BOUNDARY: PASS
PSC2_KERNEL_CORE_NAME_PARITY: PASS
PSC2_KERNEL_CORE_LEVEL_PARITY: PASS
PSC2_KERNEL_CORE_EXPR_PARITY: PASS
PSC2_KERNEL_CORE_SUBST_PARITY: PASS
PSC2_KERNEL_CORE_DECLARATION_PARITY: PASS
PSC2_KERNEL_CORE_ENVIRONMENT_PARITY: PASS
PSC2_KERNEL_CORE_LOCAL_CONTEXT_PARITY: PASS
PSC2_KERNEL_CORE_REDUCTION_PARITY: PASS
PSC2_KERNEL_CORE_INFER_PARITY: PASS
PSC2_BOOTSTRAP_CLOSURE: PASS
KERNEL_CORE_SOURCE_PROFILE: PASS
Phase 1 aggregate assurance: success
Phase 2 aggregate assurance: success
Phase 3 aggregate assurance: success
Phase 4 aggregate assurance: success
Existing PSC2 regression gate (`npm run check`): success
```

The bootstrap closure remains isolated from `pskernel-core`; Phase 4 does not make the new kernel the active compiler admission provider.

## Exact size evidence

From the exact acceptance head:

```text
KERNEL_CORE_SIZE_REPORT: PASS
KernelCore trusted .lean file count: 11
KernelCore trusted source bytes: 59505
KernelCore trusted nonblank/noncomment LOC: 1450
PSC1Kernel comparable .lean file count: 22
PSC1Kernel comparable semantic-source bytes: 306641
PSC1Kernel comparable nonblank/noncomment LOC: 7403
KernelCore/reference byte ratio: 0.1941
KernelCore/reference LOC ratio: 0.1959
```

Reference exclusions are unchanged:

```text
Test/**
Replay.lean
ReplayJson.lean
NativeMap.lean
```

The current trusted slice is therefore approximately 19.41% of the comparable reference bytes and 19.59% of the comparable reference LOC. These are measurements of the current accepted slice, not predictions for the final completed kernel.

## Allowed claims

The evidence supports these claims:

- KernelCore now contains a small PSC1-self-hostable infer-only substrate on top of the accepted basic WHNF layer.
- The trusted closure consists of 11 PSC1-subset `.lean` modules and every module passes the actual PSC1 checker.
- The explicitly covered infer-only constructor/application/binder/universe cases agree with the mature `PSC1Kernel.infer` oracle under a sufficient explicit small-core budget.
- Infer-only mode intentionally leaves application arguments, lambda domains, let declared type/value, and unsafe/partial-use restrictions unchecked where the mature infer-only oracle does the same.
- Projection inference remains fail-closed until trusted inductive metadata exists.
- The foundational explicit-universe `mkMax` behavior exercised by Phase 4 is now pinned by a direct Level parity regression.
- Phase-1/2/3 semantic gates remain green.
- The complete existing PSC2/PSC1 repository regression suite remains green on the exact tested implementation/assurance SHA.

## Explicit non-claims

This acceptance must **not** be used to claim:

- checked inference or a complete type checker;
- definitional equality;
- proof irrelevance;
- function or structure eta;
- lazy-delta DefEq ordering;
- checked application argument types;
- lambda-domain type validation;
- let declared-type/value validation;
- unsafe/partial restrictions during declaration checking;
- closed declaration admission;
- projection inference or constructor projection computation;
- inductive, constructor, or recursor metadata validation;
- iota reduction;
- Quot admission or computation;
- complete Nat/String primitive kernel behavior;
- full Lean-compatible resource accounting;
- K7/K8 corpus parity through KernelCore;
- replacement of `PSC1Kernel`;
- compiler `CheckedCore` provider integration;
- full Lean 4.34 kernel equivalence;
- formal equivalence to Lean 4.34;
- executable PSC2 KernelCore fixed-point self-hosting;
- that the current 19.41% byte / 19.59% LOC ratios predict the final completed-kernel size.

The strongest valid Phase-4 summary is:

> KernelCore now has a PSC1-self-hostable infer-only type-inference substrate with direct differential parity against `PSC1Kernel.infer` for the explicitly covered Phase-4 surface, while checked inference, DefEq, projection/inductive semantics, declaration admission, and compiler cutover remain deferred.

## Recommended next semantic phase

The next dependency-ordered architectural slice is **Phase 5 — definitional equality**.

Phase 5 should build on the accepted Phase-3 WHNF and Phase-4 infer-only substrate. It should preserve the small pure trusted core, use explicit total budget/resource boundaries, begin with direct RED differential fixtures, and avoid importing recursor/Quot/primitive/resource behavior before those later phases have their own acceptance gates.

Phase 5 must be scoped carefully because mature `PSC1Kernel.isDefEq` includes proof irrelevance, eta, lazy delta, projection/recursor, Quot, Nat/native, String, and structure-specific behavior. The next spec should separate the smallest sound DefEq foundation from semantics that depend on still-deferred metadata or primitive layers rather than copying the entire mature checker into the TCB at once.
