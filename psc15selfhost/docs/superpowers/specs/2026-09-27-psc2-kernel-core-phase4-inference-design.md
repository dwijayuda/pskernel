# PSC2 KernelCore Phase 4 Minimal Inference Design

Status: proposed architectural design awaiting written-spec review.

Date: 2026-09-27

Branch: `psc2/kernel-core-phase4-infer`

Base: accepted and merged Phase 3 at `8f3a808adb279b1c48d04dfe075b8babd8259b4d`.

## Purpose

Extend the accepted minimal trusted `pskernel-core` with the smallest useful **infer-only type-inference substrate** built on Phase 3 basic WHNF.

Phase 4 exists to establish the dependency needed by later definitional equality without prematurely importing checked-inference, declaration-admission, inductive, Quot, primitive-runtime, or resource-policy semantics into the trusted core.

The semantic reference remains `psc15selfhost/packages/pskernel/PSC1Kernel/TypeChecker.lean`, specifically the public `infer` / `inferCore ... true` behavior.

This phase MUST preserve the project rules already accepted in Phases 1–3:

- trusted code is PSC1-compatible `.lean`;
- actual `psc1 check` of the complete trusted closure is mandatory;
- differential evidence is scoped and incremental;
- the mature `PSC1Kernel` remains the oracle, not a file-copy target;
- no host IO, caches, unsafe/partial escapes, backend code, replay machinery, or Lean/Std implementation dependencies enter `pskernel-core`;
- Phase 3 remains independently green;
- no full Lean 4.34 equivalence claim is made.

## Why inference precedes DefEq

The mature checker has a semantic cycle at full capability:

- checked inference calls definitional equality for application and let checking;
- full definitional equality calls inference for proof irrelevance, function eta, structure eta, and unit-like cases.

Phase 4 breaks that cycle deliberately by implementing only the mature checker's **infer-only** mode.

`PSC1Kernel.infer` calls `inferCore ctx e true`. In this mode the reference computes types while intentionally not rechecking several trusted-well-typedness obligations. That mode is therefore a valid small dependency for a later DefEq phase.

Phase 4 MUST NOT introduce `isDefEq` merely to increase fixture coverage.

## Existing trusted baseline

The accepted trusted closure already contains:

```text
Ps.KernelCore.Data
Ps.KernelCore.Name
Ps.KernelCore.Level
Ps.KernelCore.Expr
Ps.KernelCore.Subst
Ps.KernelCore.Declaration
Ps.KernelCore.Environment
Ps.KernelCore.LocalContext
Ps.KernelCore.Reduce
Ps.KernelCore
```

Phase 3 provides:

```text
psKernelCoreWhnf :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreExpr
```

It covers the accepted basic beta/zeta/metadata/local-let/delta subset under an explicit total budget.

## Architectural decision

Add one trusted semantic module:

```text
Ps.KernelCore.Infer
```

and minimally extend `Ps.KernelCore.Subst` with the binder-closing operations inference actually needs.

The resulting trusted package becomes conceptually:

```text
Ps.KernelCore
├── Data
├── Name
├── Level
├── Expr
├── Subst
├── Declaration
├── Environment
├── LocalContext
├── Reduce
└── Infer
```

Do not add a broad checker context, state/cache object, diagnostics subsystem, or general standard-library layer in this phase.

## Public inference interface

The primary entry point is:

```text
psKernelCoreInfer :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreExpr
```

The first `Nat` is the explicit total inference-depth budget.

Two small helpers are part of the trusted semantic API because later DefEq/checking phases will need the same behavior:

```text
psKernelCoreEnsureSort :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreLevel

psKernelCoreEnsureForall :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreExpr
```

`psKernelCoreEnsureForall` returns the reduced expression only when it is a `forallE`; callers pattern-match the returned expression rather than introducing a tuple/product dependency solely for this phase.

## Totality and budget semantics

Trusted inference MUST remain total and PSC1-admission-ready.

The implementation follows the successful Phase-3 pattern:

- `budget = 0` fails deterministically with `"inference budget exhausted"`;
- `budget = Nat.succ remaining` binds the smaller recursive inference function first;
- recursive inference calls use only `remaining`;
- WHNF exposure invoked by inference uses the remaining budget available to that inference step;
- source must not use `partial`, termination annotations, `unsafe`, or host recursion escapes.

The budget is a deterministic **depth bound**, not a global mutable step counter. Separate child branches may each use the same smaller budget.

Phase 9 may later align this with the final explicit Lean-compatible resource configuration. Phase 4 only needs a deterministic total boundary.

## Minimal binder support

Inference of lambdas and lets requires opening bound variables as local free variables and then closing the inferred type again.

Add only these structurally recursive operations to `Subst.lean`:

```text
psKernelCoreExprHasFVarName :
  PsKernelCoreExpr -> PsKernelCoreName -> Bool

psKernelCoreExprAbstractFVar :
  PsKernelCoreExpr -> PsKernelCoreName -> PsKernelCoreExpr
```

`psKernelCoreExprAbstractFVar` implements capture-safe abstraction at the outermost binder:

- the target free variable becomes `bvar 0` at the outermost level;
- traversal under lambda/forall/let bodies increases the abstraction depth;
- pre-existing bound variables at or above the insertion depth are shifted so abstraction does not capture them;
- all expression constructors are traversed;
- names, levels, literals, binder metadata and projection metadata are preserved.

Required law for the supported well-scoped boundary:

```text
instantiate1 (abstractFVar e x) (fvar x) = e
```

for expressions in which `x` is the free variable being abstracted and the surrounding expression is otherwise well scoped.

Do not add general multi-free-variable abstraction, maps, sets, or binder utility libraries in this phase.

## Fresh local names

Use the same observable name strategy as the mature checker:

```text
fresh := PsKernelCoreName.num userName lctx.nextIndex
```

A lambda/forall binder is opened by:

1. constructing `fresh`;
2. extending the local context with `psKernelCoreLocalContextAddLocal`;
3. instantiating the source body once with `PsKernelCoreExpr.fvar fresh`.

A let binder uses `psKernelCoreLocalContextAddLet` with the declared type and value.

The local context's monotonically increasing `nextIndex` is the uniqueness mechanism. No global name supply enters the TCB.

## Constructor semantics

### Bound variables

A top-level/loose `bvar` is rejected with the mature-reference error:

```text
loose bound variable in type checker
```

Proper binders are opened to trusted local free variables before their bodies are recursively inferred.

### Metavariables

Expression metavariables are rejected:

```text
kernel type checker does not support metavariables
```

No metavariable assignment/elaboration machinery belongs in the kernel.

### Free variables

For `fvar name`:

- lookup `name` in `PsKernelCoreLocalContext`;
- return the declaration's stored type;
- fail with `"unknown free variable"` when absent.

Both local declarations and let declarations return their declared type when referenced.

### Sorts

```text
infer (sort u) = sort (succ u)
```

No additional normalization is needed for this rule.

### Constants

For `const name levels`:

1. find the declaration in the environment;
2. reject absent declarations with `"unknown constant"`;
3. require the number of supplied universe levels to equal the declaration's universe-parameter count;
4. reject mismatch with `"incorrect number of universe levels"`;
5. instantiate the declaration type with the supplied levels using the already accepted Phase-3 universe-instantiation path;
6. return the instantiated type.

Because this is infer-only mode, Phase 4 deliberately does **not** reject unsafe or partial constants. Those checks belong to checked inference / declaration admission in Phase 6.

### Literals

For the current expression literal forms:

```text
lit (nat n) -> const Nat []
lit (str s) -> const String []
```

The names are the ordinary Lean-compatible root names:

```text
Nat
String
```

Phase 4 differential cases use bounded Nat values. Final `maxNatSize` enforcement remains deferred to the resource/primitive phase and is not claimed here.

### Metadata

```text
infer (mdata _ body) = infer body
```

Metadata is semantically transparent for inference.

### Lambdas

Infer-only lambda behavior deliberately **does not validate that the domain is itself a type**.

For:

```text
lam name domain body binderInfo
```

Phase 4:

1. creates a fresh local with type `domain`;
2. opens `body` with that local free variable;
3. recursively infers the opened body;
4. capture-safely abstracts the fresh variable from the inferred body type;
5. returns:

```text
forallE name domain closedBodyType binderInfo
```

This preserves the key mature infer-only behavior without invoking DefEq.

### Foralls

Unlike lambda-domain validation, forall formation still needs universe information even in infer-only mode.

For:

```text
forallE name domain body binderInfo
```

Phase 4:

1. infers `domain`;
2. calls `psKernelCoreEnsureSort` on that inferred type;
3. opens the body under a fresh local of type `domain`;
4. infers the opened body;
5. calls `psKernelCoreEnsureSort` on the inferred body type;
6. returns:

```text
sort (psKernelCoreLevelMkIMax domainLevel bodyLevel)
```

This is the direct small-core counterpart of the reference's `inferForallSpine` universe computation.

### Let expressions

Infer-only let behavior deliberately skips validation of the declared type and value.

For:

```text
letE name type value body nondep
```

Phase 4:

1. adds a let declaration containing `type` and `value`;
2. opens the body with its fresh free variable;
3. infers the opened body;
4. if the inferred body type does not contain the fresh variable, returns that type directly;
5. otherwise capture-safely abstracts the fresh variable and returns:

```text
letE name type value closedBodyType nondep
```

This matches the mature infer-only intent of removing dead type-level lets while retaining dependent ones.

Phase 4 does not attempt to reproduce every `cheapBetaReduce` micro-ordering case outside its direct fixtures. Such differences, if any, are expanded under later differential/corpus gates rather than by importing broad reducer logic here.

### Applications

Infer-only application behavior MUST NOT infer or type-check the argument.

For:

```text
app fn arg
```

Phase 4:

1. infers the function type;
2. exposes that type with `psKernelCoreEnsureForall` using accepted Phase-3 WHNF;
3. rejects a non-function type with `"expected function type"`;
4. instantiates the forall body once with `arg`;
5. returns the instantiated result type.

A test MUST prove that an argument which would itself fail ordinary inference can still be accepted when the function type is known, because infer-only mode intentionally trusts application arguments.

The mature checker uses a whole-application-spine optimization with delayed substitution. Phase 4's semantic requirement is direct differential parity for the accepted application fixtures, including dependent multi-application and a hidden forall exposed by basic delta reduction. It does not yet claim parity for every evaluation-order corner case of the mature spine optimization.

If a differential fixture demonstrates that per-application inference changes an observable result, the implementation must adopt the smallest PSC1-total spine algorithm needed to match the oracle rather than weakening the test.

### Projections

Projection inference requires trusted inductive and constructor metadata that Phase 2 deliberately deferred.

Therefore `proj` MUST fail closed in Phase 4 with a stable Phase-4-specific error rather than inventing unchecked metadata:

```text
projection inference unavailable before inductive metadata
```

Projection parity becomes part of the primitive-inductive/recursor phase.

## `ensureSort`

`psKernelCoreEnsureSort`:

1. calls accepted Phase-3 `psKernelCoreWhnf`;
2. returns the level if the result is `sort level`;
3. otherwise returns `"expected sort"`.

It does not invoke DefEq.

## `ensureForall`

`psKernelCoreEnsureForall`:

1. calls accepted Phase-3 `psKernelCoreWhnf`;
2. returns the reduced `forallE` expression if exposed;
3. otherwise returns `"expected function type"`.

It does not infer the expression and does not invoke DefEq.

## Explicitly excluded from Phase 4

The following stay outside this phase:

- definitional equality;
- proof irrelevance;
- function or structure eta;
- lazy delta ordering for DefEq;
- checked application arguments;
- lambda-domain type validation;
- let declared-type/value validation;
- unsafe/partial-use restrictions;
- closed declaration admission;
- projection inference;
- inductive/constructor/recursor metadata;
- iota/projection computation;
- Quot admission/computation;
- primitive Nat arithmetic reduction;
- large-Nat resource enforcement;
- String constructor expansion;
- native reduction/provider behavior;
- caches/sessions/stateful checker machinery;
- K7/K8 corpus adapter;
- compiler `CheckedCore` provider integration;
- executable self-host/fixed-point claims.

## Differential parity design

Add a dedicated test executable comparing the normalized result of `psKernelCoreInfer` to `PSC1Kernel.infer` for the overlap surface.

### Positive parity cases

At minimum:

1. `sort u -> sort (succ u)`;
2. ordinary local free-variable lookup;
3. local let-variable lookup returns its declared type;
4. constant with no universe parameters;
5. polymorphic constant with universe instantiation;
6. Nat literal typing;
7. String literal typing;
8. metadata transparency;
9. nondependent lambda type;
10. dependent/nested lambda closure using fresh locals and abstraction;
11. forall universe result using `imax`;
12. nested/dependent forall;
13. nondependent let removes the dead type-level let;
14. dependent let retains the type-level let;
15. visible forall application;
16. dependent multi-application;
17. hidden forall exposed by accepted basic delta reduction;
18. infer-only application with an intentionally non-inferable argument still returns the function result type.

### Negative parity cases

At minimum:

1. loose `bvar`;
2. expression `mvar`;
3. unknown free variable;
4. unknown constant;
5. incorrect universe-level arity;
6. forall domain whose inferred type is not a sort;
7. application whose function type cannot be exposed as a forall.

### KernelCore-only fail-closed cases

Because the current small core does not yet possess inductive metadata:

1. projection inference returns the stable deferred-feature error;
2. budget zero returns `"inference budget exhausted"`;
3. a term that needs exactly one more inference-depth unit fails at the lower budget and succeeds at the higher budget.

### Binder helper cases

Directly exercise:

1. abstract/instantiate round trip;
2. abstraction under nested lambda/forall/let bodies;
3. pre-existing bound-variable shifting at the insertion depth;
4. target free-variable detection through every recursive expression-child constructor;
5. no change when the target free variable is absent.

## Test normalization boundary

Reference and KernelCore use different data types. Test-only adapters may translate:

```text
Name
Level
Expr
result/error
```

between the two representations.

Adapters remain outside `pskernel-core` and MUST NOT become trusted dependencies.

For overlapping reference errors, the direct fixture should compare the stable semantic error category/string listed in this spec. Phase-4-specific deferred projection/budget errors are tested only against the KernelCore contract.

## Required gate order

Every Phase-4 implementation checkpoint follows:

```text
Lean compilation
↓
Phase-4 direct inference differential parity
↓
Phase-1/2/3 direct parity remains green
↓
KernelCore boundary/bootstrap isolation
↓
actual PSC1 self-host source check of the full trusted closure
↓
Phase-1 aggregate assurance
↓
Phase-2 aggregate assurance
↓
Phase-3 aggregate assurance
↓
Phase-4 aggregate assurance
↓
full npm run check
```

No lower gate may be weakened or removed to admit Phase 4.

## Size and trust discipline

Update the existing size reporter after adding `Infer.lean` and the minimal `Subst.lean` helpers.

Record:

- trusted `.lean` file count;
- trusted bytes;
- trusted nonblank/noncomment LOC;
- ratio to the same comparable `PSC1Kernel` baseline;
- host/runtime dependencies, which must remain zero.

A size increase is expected because inference is a semantic capability increase. The acceptance argument is based on a narrowly scoped trusted implementation, not on preserving the Phase-3 percentage.

## Integration boundary

Phase 4 does **not** make KernelCore the active PSC2 admission provider.

The compiler path remains unchanged. In particular, do not rename an existing codec/shape-validation boundary to `CheckedCore` merely because infer-only exists.

The future path remains:

```text
AdmissionReadyModule
        |
        v
pskernel-core checked admission
        |
        v
CheckedCore / CheckedModule
        |
        v
erasure -> VerifiedIR
```

That cutover requires checked inference, DefEq, Quot/inductive semantics, and the mandated parity gates first.

## Acceptance criteria

Phase 4 is accepted only when all of the following are true:

1. `Ps.KernelCore.Infer` exists as trusted PSC1-subset source;
2. only the minimal binder-closing helpers needed by inference are added to `Subst.lean`;
3. the complete trusted closure passes the actual PSC1 self-host source check;
4. direct overlap fixtures agree with `PSC1Kernel.infer` for the accepted infer-only surface;
5. infer-only application nonchecking is explicitly proven by regression;
6. lambda and let binder closing is capture-safe under the direct helper fixtures;
7. projection behavior fails closed rather than trusting absent inductive metadata;
8. Phase-1/2/3 gates remain green;
9. Phase-4 aggregate assurance is green;
10. full existing repository regressions are green on the exact tested implementation SHA;
11. size/evidence are recorded;
12. `PHASE4_ACCEPTANCE.md` states exact claims and non-claims.

## Allowed claims after acceptance

If all gates pass, documentation may claim:

- KernelCore contains a PSC1-self-hostable infer-only type-inference substrate;
- the explicitly tested sort/fvar/const/literal/metadata/lambda/forall/let/application subset agrees with `PSC1Kernel.infer`;
- the inference API is suitable as a dependency for the next DefEq phase;
- Phase-4 projection behavior is intentionally fail-closed pending trusted inductive metadata.

## Non-claims after acceptance

Phase 4 MUST NOT be described as:

- a complete type checker;
- checked inference;
- complete Lean 4.34 inference parity;
- complete DefEq;
- complete WHNF parity;
- complete projection/inductive/Quot semantics;
- a closed declaration-admission kernel;
- the active PSC2 checked-core provider;
- formal equivalence to Lean 4.34;
- a completed self-host or fixed point.

## Next dependency-ordered phase

After Phase 4 is accepted, the next architectural phase is **Phase 5: definitional equality** built on:

```text
Phase-3 basic WHNF
+ Phase-4 infer-only
```

Phase 5 should begin with structural/quick equality and the smallest proof-irrelevance/lazy-delta/eta slices justified by direct differential fixtures. It must not import checked declaration admission merely for convenience.
