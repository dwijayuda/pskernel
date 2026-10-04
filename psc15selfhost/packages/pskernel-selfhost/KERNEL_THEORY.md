# PSKernel Theory and Implementation Guide

PSKernel is an independent executable implementation of the Lean 4.34 kernel
semantics written in the PSC1-compatible subset of Lean.

Target:

- Lean version: 4.34.0
- Lean commit: `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`
- compatibility matrix: `LEAN_4_34_COMPATIBILITY.json`
- conformance matrix: `LEAN_4_34_CONFORMANCE.json`
- generated rule reference: `KERNEL_RULE_REFERENCE.md`

Project guidance:

- architecture/anti-drift rules: `PSKERNEL_SELFHOST_ARCHITECTURE.md`
- active roadmap: `DEVELOPMENT_PLAN.md`

The same semantic source is intended to have two primary execution paths:

```
Ps.KernelSelfHost/*.lean
        |
        +-- PSC compiler / backend-ts --> TypeScript / JavaScript
        |
        +-- Lean 4 compiler -----------> native executable/library
```

No separate Rust or C++ kernel is required.

## 1. Trust model

The kernel accepts already elaborated core declarations. Parsing, elaboration,
tactics, typeclass synthesis, and code generation are outside the semantic
kernel boundary.

The main trusted operation is conceptually:

```
checkDeclaration : Environment -> Declaration -> Except KernelError Environment
```

A successful result extends the environment by one checked declaration (or one
checked declaration bundle).

Runtime indexes and caches must never create new semantic facts. They may only
make an already-defined lookup or check faster.

## 2. Core judgments

A reader can understand the implementation around four judgments:

```
infer  : Γ |- e : A
whnf   : e -->* weak-head form
defeq  : Γ |- A <=> B
admit  : Γ + declaration is a valid environment extension
```

The `defeq` relation is Lean's algorithmic definitional equality, not ideal
mathematical equality. In particular it is intentionally incomplete and is not
transitive. This is why successful equality caching uses plain expression
pairs instead of an equivalence closure.

## 3. Recommended reading order

### Core syntax and substitution

1. `Name.lean`
2. `Level.lean`
3. `Expr.lean`
4. `Instantiate.lean`
5. `Declaration.lean`
6. `LocalContext.lean`
7. `Environment.lean`

These modules define the data manipulated by the checker.

### Type checking and reduction

8. `TypeCheckerBase.lean`
9. `TypeCheckerPrimitives.lean`
10. `Theory/Reduction/KernelReductions.lean`
11. `Theory/Reduction/WhnfCore.lean`
12. `TypeCheckerWhnf.lean`
13. `TypeCheckerProjection.lean`
14. `Theory/Inference/Helpers.lean`
15. `Theory/Inference/Core.lean`
16. `TypeCheckerInfer.lean`
17. `Theory/Recursor/Analysis.lean`
18. `Theory/Recursor/Reduction.lean`
19. `TypeCheckerRecursor.lean`

### Definitional equality

16. `Theory/DefEq/BinderSpines.lean`
17. `Theory/DefEq/Quick.lean`
18. `TypeCheckerDefEqSupport.lean` (compatibility umbrella)
19. `Theory/DefEq/LazyDelta.lean`
20. `Theory/DefEq/FinalRules.lean`
21. `Theory/DefEq/Shortcuts.lean`
22. `Theory/DefEq/FullShape.lean`
23. `TypeCheckerDefEq.lean`

`Theory/DefEq/BinderSpines.lean` isolates binder/application congruence.
`Theory/DefEq/Quick.lean` isolates the cheap pre-reduction decisions and pair-cache semantics.
`Theory/DefEq/DeltaStep.lean` isolates one-step definition selection and unfolding. `Theory/DefEq/LazyDelta.lean` isolates Lean's observable iterative lazy-unfolding order.
`Theory/DefEq/FinalRules.lean` isolates proof/proposition handling, structure eta,
string literal expansion, and unit-like structures.
`Theory/DefEq/Shortcuts.lean` contains reflection, projection, and function-eta shortcuts.
`Theory/DefEq/FullShape.lean` contains the last same-shape and terminal fallback rules.
`TypeCheckerDefEq.lean` is intentionally kept small so it reads as the observable
Lean 4.34 algorithmic-equality order rather than a bag of helper implementations.

### Declaration admission

22. `CheckerSession.lean`
23. `Theory/Admission/Validation.lean`
24. `Theory/Admission/Declarations.lean`
25. `Kernel.lean` (compatibility umbrella)
26. `Theory/Quot/Bootstrap.lean`
27. `Theory/Quot/Admission.lean`
28. `Quot.lean` (compatibility umbrella)
29. `Inductive.lean`
28. `Theory/Inductive/Constructor.lean`
29. `Theory/Inductive/Recursor.lean`
30. `Theory/Inductive/Elimination.lean`
31. `InductiveAdmission.lean`
32. `Theory/Mutual/Analysis.lean`
33. `Theory/Mutual/Recursor.lean`
34. `Theory/Mutual/Admission.lean`
35. `MutualInductive.lean` (compatibility umbrella)
36. `Theory/Nested/Discover.lean`
37. `Theory/Nested/Flatten.lean`
38. `Theory/Nested/Restore.lean`
39. `Theory/Nested/Admission.lean`
40. `NestedInductive.lean` (compatibility umbrella)

### Backend/runtime mechanisms

- `Runtime/Cache.lean`
- `Runtime/EnvironmentIndex.lean`
- `Runtime/NativeReduction.lean`

These modules are deliberately separated from the theory-facing algorithm.

## 4. Universe levels

Lean universe levels use:

```
0
succ u
max u v
imax u v
parameter
```

`Level.lean` implements normalization and semantic comparison.

A level comparison is not string/syntax equality. The checker compares the
meaning of level expressions for all assignments to universe parameters.

## 5. Inference

Inference is split into a small helper layer, the syntax-directed core, and
public entry points:

```text
Theory/Inference/Helpers.lean
      |
      | Sort/Pi views, application-spine exposure, cache publication
      v
Theory/Inference/Core.lean
      |
      | syntax-directed typing cases
      v
TypeCheckerInfer.lean
         public infer/check wrappers
```

Important cases include:

```
Sort u                 : Sort (u+1)
Const c levels         : instantiate universe parameters in type(c)
f a                    : instantiate the codomain of a checked Pi type
fun x : A => b         : Pi x : A, type(b)
Pi x : A, B            : Sort (imax level(A) level(B))
let x : A := v; b      : type(b[v/x])
literal                : Nat or String
projection             : dependent field type
```

When checking applications, inferred and expected argument types are compared
using algorithmic definitional equality.

## 6. Weak-head reduction

Weak-head reduction is split into three layers:

```text
Theory/Reduction/KernelReductions.lean
      |
      | Quot + optimized Nat reductions
      v
Theory/Reduction/WhnfCore.lean
      |
      | beta / zeta / projection / structural core WHNF
      v
TypeCheckerWhnf.lean
         public cached post-core pipeline
```

The public post-core order is intentionally explicit in
`psKernelWhnfAfterCore`:

```text
whnfCore
   |
   +-- optional Lean.reduceBool / Lean.reduceNat native provider
   |
   +-- optimized Nat primitive reduction
   |
   +-- definition unfolding
   |
   '-- repeat when unfolding makes progress
```

This order follows Lean 4.34. The order is observable because algorithmic
definitional equality is incomplete.

## 6.1 Recursor reduction

Recursor reduction is split into three layers:

```text
Theory/Recursor/Analysis.lean
      |
      | major-family discovery, K conversion, structure conversion
      v
Theory/Recursor/Reduction.lean
      |
      | Quot / inductive rule selection and computation
      v
TypeCheckerRecursor.lean
         bounded integration with WHNF and inference
```

This keeps the semantic iota/K logic readable while the public integration
layer makes recursion/resource behavior explicit and fail-closed.

## 7. Algorithmic definitional equality

The checker does not normalize both terms and compare normal forms.

The high-level algorithm is approximately:

```
structural equality / successful pair cache
        |
quick same-shape checks
        |
reflection fast path
        |
cheap WHNF
        |
proof irrelevance
        |
lazy delta reduction
        |
projection-specific shortcut
        |
full projection WHNF
        |
application/binder comparison
        |
function eta
        |
structure eta
        |
string literal expansion
        |
unit-like structure equality
        |
failure
```

Successful pairs are cached symmetrically, but never transitively.

## 8. Proof irrelevance

If both terms inhabit definitionally equal propositions, their proof values are
definitionally equal.

This is a kernel rule. It is not proof erasure performed by the compiler.

## 9. Function and structure eta

Function eta handles equality between a lambda and a non-lambda function by
expanding the latter at a fresh bound argument.

Structure eta is restricted to non-recursive structures. A constructor applied
to values definitionally equal to all projections of a structure value is
definitionally equal to that structure value.

See `Theory/DefEq/FinalRules.lean`.

## 10. Quotients

Quotient support is split into bootstrap shape construction and checked
environment admission:

```text
Theory/Quot/Bootstrap.lean
      |
      | validate Eq/Eq.refl and construct Quot primitive types
      v
Theory/Quot/Admission.lean
         reserve/install Quot, Quot.mk, Quot.lift, Quot.ind
```

`Quot.lean` remains a stable umbrella import.

Computation for `Quot.lift` and `Quot.ind` lives in
`Theory/Reduction/KernelReductions.lean`. Quotient initialization is explicit
state in the environment.

## 11. Inductive declarations

### Ordinary-inductive source layout

```text
Inductive.lean
      |
Theory/Inductive/Constructor.lean
      |  parameters, fields, positivity, constructor result
      v
Theory/Inductive/Recursor.lean
      |  motives, minors, recursive calls, rules
      v
Theory/Inductive/Elimination.lean
      |  large-elimination and K/reflexivity policy
      v
InductiveAdmission.lean
         top-level checked environment extension
```

The split is explanatory only: it preserves the same kernel algorithm and
keeps the PSC1 self-host source profile.

The inductive checker validates:

- universe parameters;
- common parameters;
- indices;
- constructor result shape;
- positivity of recursive occurrences;
- recursive-argument universes;
- elimination restrictions;
- generated constructor information;
- recursor types and computation rules.

Ordinary admission deliberately rejects nested recursive occurrences. Nested
admission preprocesses these occurrences and then validates the resulting
mutual bundle.

## 12. Mutual inductives

Mutual inductives are split by theory responsibility:

```text
Theory/Mutual/Analysis.lean
      |
      | discover targets, constructor fields, recursive occurrences
      v
Theory/Mutual/Recursor.lean
      |
      | motives, minors, recursive calls, computation rules
      v
Theory/Mutual/Admission.lean
         checked environment installation
```

`MutualInductive.lean` remains a stable umbrella import.

The implementation supports multiple simultaneously declared families, with a
separate motive per family and recursive hypotheses for recursive arguments
that may target any member of the bundle.

The families in one bundle must satisfy Lean's shared-universe constraints.

## 13. Nested inductives

Nested inductives are split by the transformation stages:

```text
Theory/Nested/Discover.lean
      |
      | reserved-name checks, parameter rebasing, auxiliary-family planning
      v
Theory/Nested/Flatten.lean
      |
      | rewrite nested applications and close the transformed mutual bundle
      v
Theory/Nested/Restore.lean
      |
      | restore user constructors/recursors and map auxiliary artifacts
      v
Theory/Nested/Admission.lean
         validate restored types/rules and install the final environment
```

`NestedInductive.lean` remains a stable umbrella import.

The transformation is necessary to preserve Lean 4 computation behavior for
nested inductives while keeping flattening details out of the user-visible
environment.

## 14. Declaration admission

Declaration admission is split into validation and environment extension:

```text
Theory/Admission/Validation.lean
      |
      | universe discipline, closedness, sort/header/body checking
      v
Theory/Admission/Declarations.lean
         axiom / definition / theorem / opaque / mutual environment extension
```

`Kernel.lean` remains a stable umbrella import.

The admission layer checks:

- duplicate declaration names;
- duplicate/undefined universe parameters;
- no metavariables or free variables in admitted declarations;
- declaration types are themselves well-typed sorts;
- definition bodies have the declared type;
- theorem declarations have proposition types and valid proofs;
- opaque values type check but are not delta-reduced;
- unsafe recursive definitions are checked in the recursive environment;
- unsafe/partial mutual definitions are checked as one block.

## 15. Runtime modules are non-semantic

### Environment index

`Runtime/EnvironmentIndex.lean` is a persistent hash trie used only to narrow
name lookup to a collision bucket.

The authoritative ordered list of constants remains in `PsKernelEnvironment`.
Bucket collisions are resolved with full structural `PsKernelName` equality.

### Defeq/inference caches

`Runtime/Cache.lean` owns memoization structures.

Changing cache representation must not change the result of a check.

### Native reduction

`Runtime/NativeReduction.lean` exposes an optional provider:

```
Name -> Except String (Option Bool)
Name -> Except String (Option Nat)
```

No provider means no native reduction step. This keeps the semantic kernel pure
and makes the extra compiler/runtime trust explicit.

## 16. Self-host coding discipline

Every module in the semantic closure must remain accepted by the PSC1 source
profile.

Prefer the patterns already demonstrated by the self-hosted compiler:

- explicit algebraic data;
- explicit `Except` errors;
- structural workers;
- curried workers when invariant arguments change;
- explicit fuel only where structural recursion is not sufficient;
- no hidden fallback from failed checking;
- no generated-JavaScript semantic patches;
- non-semantic indexes/caches behind narrow modules.

The authoritative gate is:

```
portable Lean source
      |
psc1 check
      |
canonical .ps translation
      |
psc1 check again
```

## 17. What feature-complete means

Feature completeness is defined mechanically by
`LEAN_4_34_COMPATIBILITY.json`.

A feature-complete release requires:

1. every required rule marked implemented;
2. the compatibility audit passes with `--require-complete`;
3. the focused conformance/differential suite is green;
4. the self-host source and generated-artifact fixed points pass.

This definition avoids treating project size or a successful demo as evidence
of semantic completeness.

## 18. Performance policy

Performance work should first change representations, not theory algorithms.

Preferred order:

1. indexed environment lookup;
2. indexed expression/defeq caches;
3. cached expression metadata/hash;
4. sharing/interning where measurements justify it;
5. only then algorithmic shortcuts.

Every representation optimization must preserve the semantic result.

## 19. Multi-backend policy

The kernel has one source of truth.

```
PSC backend-ts -> JS
Lean compiler   -> native
```

Backend-specific code may implement runtime capabilities, indexes, allocation,
or native evaluation. It must not duplicate or redefine type-theory rules.
