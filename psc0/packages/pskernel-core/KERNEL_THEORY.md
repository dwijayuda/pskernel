# PSKernel Theory and Implementation Guide

The active PSC0 package targets Lean **4.35.0-rc4** at
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. It currently uses the Lean-native
experimental execution profile; the current PSC0 self-host profile is the
separate qualification target. Old PSC1 restrictions are historical.

**Correctness status:** the legacy metatheory is not an adequate semantic
specification. `JudgmentAdequacy.lean` proves its algorithmic equality universal
and its typing relation capable of assigning every type to `Sort 0`.
This is not an executable checker exploit. Full semantic metatheory and the
model/consistency proof remain unproved. See
[the current audit, model target and assumptions](RESEARCH_AND_MIGRATION.md).
The new `PsKernelSemantics` modules construct a relative set model of universes
and dependent functions, prove a declarative fragment sound and consistent,
and connect production substitution to that interpretation. The pinned
mathematical dependency and local foundation assumptions are explicit.
Full checker/inductive-admission correspondence remains open. The conceptual
judgments below are explanatory; they are not the completed kernel theorem.

The current proof target is the fixed cache-disabled reference specialization
of the shared production algorithm. Cache coherence is unnecessary for its
primitive cache operations and first inference bridges. No full recursive
soundness or acceptance-equivalence result is inferred from that simplification.
[REFERENCE_CORRECTNESS_PLAN.md](REFERENCE_CORRECTNESS_PLAN.md) defines the
milestones and exact completion claim.

Historical 4.34 reference artifacts (not current certification):

- compatibility matrix: `LEAN_4_34_COMPATIBILITY.json`
- conformance matrix: `LEAN_4_34_CONFORMANCE.json`
- generated rule reference: `KERNEL_RULE_REFERENCE.md`

Project guidance:

- architecture/anti-drift rules: `PSKERNEL_CORE_ARCHITECTURE.md`
- active roadmap: `DEVELOPMENT_PLAN.md`

The same semantic source is intended to have two primary execution paths:

```
Ps.KernelCore/*.lean
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

The recommended path follows the kernel dependency/theory flow rather than
historical file creation order.

### 3.1 Core syntax and substitution

1. `Core/Name.lean`
2. `Core/Level.lean`
3. `Core/Expr.lean`
4. `Core/Substitution/ListOps.lean`
5. `Core/Substitution/Lift.lean`
6. `Core/Substitution/Instantiate.lean`
7. `Core/Substitution/Beta.lean`
8. `Core/Substitution/Abstract.lean`
10. `Core/Declaration.lean`
11. `Core/LocalContext.lean`
12. `Environment/Semantic.lean`, `Environment/Environment.lean`,
    `Environment/Lookup.lean`, `Environment/Operations.lean`

These modules define the data manipulated by the checker. The substitution
sequence is deliberately explicit:

```text
list/spine helpers
    -> lift loose variables
    -> instantiate de Bruijn variables
    -> cheap beta/application helpers
    -> abstract free variables
```

`Core/Substitution/Instantiate.lean` contains the conservative
non-dependent `instantiate1` fast path: when a codomain has no loose bound
variable, substitution is the identity and the original expression is returned
without a node-count/substitution traversal.

### 3.2 Type checking and reduction

13. `Checker/Context.lean`
14. `Checker/Reduction/PrimitiveData.lean`
15. `Checker/Reduction/PrimitiveNat.lean`
16. `Checker/Reduction/Primitives.lean` (canonical aggregation module)
17. `Checker/Reduction/KernelReductions.lean`
18. `Checker/Reduction/WhnfCore.lean`
19. `Checker/Reduction/Whnf.lean`
20. `Checker/Projection.lean`
21. `Checker/Inference/Helpers.lean`
22. `Checker/Inference/Core.lean`
23. `Checker/Inference.lean`
24. `Checker/Recursor/Analysis.lean`
25. `Checker/Recursor/Reduction.lean`
26. `Checker/Ops.lean` (internal callback contract)

### 3.3 Definitional equality

27. `Checker/DefEq/BinderSpines.lean`
28. `Checker/DefEq/Quick.lean`
29. `Checker/DefEq/Support.lean` (canonical aggregation module)
30. `Checker/DefEq/DeltaStep.lean`
31. `Checker/DefEq/LazyDelta.lean`
32. `Checker/DefEq/FinalRules.lean`
33. `Checker/DefEq/Shortcuts.lean`
34. `Checker/DefEq/FullShape.lean`
35. `Checker/Knot.lean` (recursor/defeq wiring and public operations)

`Checker/DefEq/BinderSpines.lean` isolates binder/application congruence.
`Checker/DefEq/Quick.lean` isolates cheap pre-reduction decisions and pair-cache
semantics. `Checker/DefEq/DeltaStep.lean` isolates one-step definition
selection/unfolding, while `LazyDelta.lean` preserves the observable iterative
Lean 4.34 unfolding order. `FinalRules.lean` isolates proof/proposition
handling, structure eta, string literal expansion and unit-like structures.
`Shortcuts.lean` contains reflection and function-eta shortcuts. The projection
shortcut lives in `Checker/Knot.lean` because it constructs a recursor-aware
core-WHNF callback with an expression-derived budget.
`FullShape.lean` contains final same-shape/fallback rules.

`Checker/Knot.lean` owns the existing bounded recursor workers and top-level
defeq orchestration. Leaf rule modules receive callbacks and never import Knot
or Session. The observable algorithmic-equality order and fuel transitions are
preserved.

### 3.4 Declaration and inductive admission

36. `Checker/Session.lean`
37. `Admission/Declaration/Validation.lean`
38. `Admission/Declaration/Admission.lean`
40. `Admission/Quot/Bootstrap.lean`
41. `Admission/Quot/Admission.lean`
43. `Admission/Inductive/Types.lean`, `Admission/Inductive/Common/Occurrence.lean`,
    `Admission/Inductive/Common/Parameters.lean`
44. `Admission/Inductive/Ordinary/Constructor.lean`
45. `Admission/Inductive/Ordinary/ConstructorAdmission.lean`
46. `Admission/Inductive/Ordinary/Recursor.lean`
47. `Admission/Inductive/Common/RecursorValidation.lean`,
    `Admission/Inductive/Common/Elimination.lean`
48. `Admission/Inductive/Ordinary/Admission.lean`
49. `Admission/Inductive/Mutual/Analysis.lean`
50. `Admission/Inductive/Mutual/Recursor.lean`
51. `Admission/Inductive/Mutual/Header.lean`
52. `Admission/Inductive/Mutual/AdmissionLoops.lean`
53. `Admission/Inductive/Mutual/Admission.lean`
55. `Admission/Inductive/Nested/Types.lean`
56. `Admission/Inductive/Nested/ReservedNames.lean`
57. `Admission/Inductive/Nested/Rebase.lean`
58. `Admission/Inductive/Nested/Discover.lean`
59. `Admission/Inductive/Nested/Flatten.lean`
60. `Admission/Inductive/Nested/RestoreExpr.lean`
61. `Admission/Inductive/Nested/Restore.lean`
62. `Admission/Inductive/Nested/Validation.lean`
63. `Admission/Inductive/Nested/Commit.lean`
64. `Admission/Inductive/Nested/Admission.lean`

### 3.5 Runtime mechanisms

Read the acceleration modules to understand representation policy, and the
capability modules to understand explicit trusted external behavior:

- `Runtime/Acceleration/Cache.lean`
- `Runtime/Acceleration/EnvironmentIndex.lean`
- `Runtime/Capability/Lean434NativeReduction.lean`

Runtime mechanisms are separate owners. Acceleration must preserve semantic
answers; an incorrect trusted native evaluator can affect acceptance.


### 3.6 Checked public boundary

Read `Checker/ResourcePolicy.lean`, `API/Outcome.lean`,
`API/KernelContractV1.lean`, `API/Provider.lean`, `API/Session.lean` and
`API/Kernel.lean`. `KERNEL_CONTRACT_V1.md` defines the stable entry points,
resource semantics, typed outcomes, receipts and trusted construction boundary.

## 4. Universe levels

Lean universe levels use:

```
0
succ u
max u v
imax u v
parameter
```

`Core/Level.lean` implements normalization and semantic comparison.

A level comparison is not string/syntax equality. The checker compares the
meaning of level expressions for all assignments to universe parameters.

## 5. Inference

Inference is split into a small helper layer, the syntax-directed core, and
public entry points:

```text
Checker/Inference/Helpers.lean
      |
      | Sort/Pi views, application-spine exposure, cache publication
      v
Checker/Inference/Core.lean
      |
      | syntax-directed typing cases
      v
Checker/Inference.lean
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

Lean 4.34 has two deliberately different application paths:

- **checked inference** follows the application tree one node at a time:
  infer the function, expose a Pi type, infer the argument, compare the
  argument type with the Pi domain, then instantiate the codomain;
- **infer-only** mode exposes the whole application spine and avoids checking
  each argument when only the resulting type is required.

PSKernel preserves that semantic distinction. Performance work must not flatten
the checked path merely to make a benchmark faster. Memoization policy is kept
in `Checker/Inference/Helpers.lean` as a non-semantic runtime choice; currently
trivial literals and fully checked application nodes are not published into the
checked-inference cache when doing so only creates structural-hash/promotion
overhead.

## 5.1 Primitive literals and Nat reduction

Primitive reduction is split into two theory-facing modules:

```text
Checker/Reduction/PrimitiveData.lean
      |
      | Nat size limits, Bool expressions, String literal constructor form
      v
Checker/Reduction/PrimitiveNat.lean
         gcd / pow / bitwise / shifts / binary Nat kernel operations
```

`Checker/Reduction/Primitives.lean` groups the canonical primitive modules.

This split is explanatory only: public symbols and Lean 4.34 reduction behavior
are unchanged.

## 6. Weak-head reduction

Weak-head reduction is split into three layers:

```text
Checker/Reduction/KernelReductions.lean
      |
      | Quot + optimized Nat reductions
      v
Checker/Reduction/WhnfCore.lean
      |
      | beta / zeta / projection / structural core WHNF
      v
Checker/Reduction/Whnf.lean
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
Checker/Recursor/Analysis.lean
      |
      | major-family discovery, K conversion, structure conversion
      v
Checker/Recursor/Reduction.lean
      |
      | Quot / inductive rule selection and computation
      v
Checker/Knot.lean
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

See `Checker/DefEq/FinalRules.lean`.

## 10. Quotients

Quotient support is split into bootstrap shape construction and checked
environment admission:

```text
Admission/Quot/Bootstrap.lean
      |
      | validate Eq/Eq.refl and construct Quot primitive types
      v
Admission/Quot/Admission.lean
         reserve/install Quot, Quot.mk, Quot.lift, Quot.ind
```

`Admission/Quot/Admission.lean` owns the top-level admission transaction.

Computation for `Quot.lift` and `Quot.ind` lives in
`Checker/Reduction/KernelReductions.lean`. Quotient initialization is explicit
state in the environment.

## 11. Inductive declarations

### Ordinary-inductive source layout

```text
Admission/Inductive/Common/Parameters.lean
      |
Admission/Inductive/Ordinary/Constructor.lean
      |  parameters, fields, positivity, constructor result
      v
Admission/Inductive/Ordinary/Recursor.lean
      |  motives, minors, recursive calls, rules
      v
Admission/Inductive/Common/Elimination.lean
      |  large-elimination and K/reflexivity policy
      v
Admission/Inductive/Ordinary/Admission.lean
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

The ordinary path is split by responsibility:

- `Admission/Inductive/Ordinary/Constructor.lean` — constructor opening, positivity and result analysis;
- `Admission/Inductive/Ordinary/ConstructorAdmission.lean` — checked constructor loop and working-environment installation;
- `Admission/Inductive/Ordinary/Recursor.lean` — recursor metadata and rule construction;
- `Admission/Inductive/Common/Elimination.lean` — elimination restrictions;
- `Admission/Inductive/Ordinary/Admission.lean` — top-level bundle transaction and final commit.

## 12. Mutual inductives

Mutual inductives are split by theory responsibility:

```text
Admission/Inductive/Mutual/Analysis.lean
      |
      | discover targets, constructor fields, recursive occurrences
      v
Admission/Inductive/Mutual/Recursor.lean
      |
      | motives, minors, recursive calls, computation rules
      v
Admission/Inductive/Mutual/Admission.lean
         checked environment installation
```

`Admission/Inductive/Mutual/Admission.lean` owns the top-level admission transaction.

The implementation supports multiple simultaneously declared families, with a
separate motive per family and recursive hypotheses for recursive arguments
that may target any member of the bundle.

The families in one bundle must satisfy Lean's shared-universe constraints.

The mutual admission path is layered as:

- `Admission/Inductive/Mutual/Analysis.lean` — mutual occurrence and family analysis;
- `Admission/Inductive/Mutual/Recursor.lean` — motive/minor/recursive-hypothesis construction;
- `Admission/Inductive/Mutual/Header.lean` — shared header/name/type setup;
- `Admission/Inductive/Mutual/AdmissionLoops.lean` — checked constructor and recursor loops;
- `Admission/Inductive/Mutual/Admission.lean` — top-level bundle transaction.

## 13. Nested inductives

Nested inductives are split by theory concept rather than kept in one
transformation file. Read the implementation in this order:

```text
Admission/Inductive/Nested/Types.lean
      |
      v
Admission/Inductive/Nested/ReservedNames.lean
      |
      v
Admission/Inductive/Nested/Rebase.lean
      |
      v
Admission/Inductive/Nested/Discover.lean
      |
      v
Admission/Inductive/Nested/Flatten.lean
      |
      | transformed declaration bundle
      v
Admission/Inductive/Mutual/Admission.lean
      |
      | checked transformed environment
      v
Admission/Inductive/Nested/RestoreExpr.lean
      |
      v
Admission/Inductive/Nested/Restore.lean
      |
      v
Admission/Inductive/Nested/Validation.lean
      |
      v
Admission/Inductive/Nested/Commit.lean

Admission/Inductive/Nested/Admission.lean orchestrates the complete transaction.
```

The module responsibilities are:

- `Types.lean` — auxiliary-family, constructor-map and work-state data;
- `ReservedNames.lean` — reject user collisions with the internal
  `_nested` namespace;
- `Rebase.lean` — open/rebase parameters and restoration binders;
- `Discover.lean` — identify nested outer families and create collision-safe
  auxiliary families;
- `Flatten.lean` — rewrite nested occurrences and close the transformed mutual
  bundle;
- `RestoreExpr.lean` — map auxiliary family/constructor/recursor references
  back into user-facing expressions;
- `Restore.lean` — install restored constructors and recursors;
- `Validation.lean` — re-check restored types/rules and source-to-restored
  type preservation;
- `Commit.lean` — build the user-visible recursor rename map and final
  commit helpers;
- `Admission.lean` — top-level fail-closed transaction boundary.

`Admission/Inductive/Nested/Admission.lean` owns the top-level admission transaction.

The transformation is necessary to preserve Lean 4 computation behavior for
nested inductives while keeping flattening details out of the user-visible
environment.

A critical restoration invariant is that the structurally decreasing work queue
must be kept separate from the complete auxiliary-family registry. A worker may
recurse over a shrinking list of pending families, but every expression,
constructor and recursor restoration must still receive the full family set.
Later restored auxiliary recursors can refer to earlier auxiliary families in
the transformed mutual bundle; restoring against only the pending suffix can
therefore leak an internal `_nested.*` constant into the final environment.

The multi-family conformance case exercises this directly with two different
outer nested families. It requires the final main recursor and both restored
auxiliary recursors to type-check with no internal auxiliary declarations
visible after commit.

## 14. Declaration admission

Declaration admission is split into validation and environment extension:

```text
Admission/Declaration/Validation.lean
      |
      | universe discipline, closedness, sort/header/body checking
      v
Admission/Declaration/Admission.lean
         axiom / definition / theorem / opaque / mutual environment extension
```

Use `Admission/Declaration/Admission.lean` directly for low-level declaration admission.

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

## 15. Runtime acceleration and trusted capabilities

### Environment index

`Runtime/Acceleration/EnvironmentIndex.lean` is a persistent hash trie used only to narrow
name lookup to a collision bucket.

The authoritative ordered list of constants remains in `PsKernelEnvironment`.
Bucket collisions are resolved with full structural `PsKernelName` equality.

### Defeq/inference caches

`Runtime/Acceleration/Cache.lean` owns memoization structures.

Changing cache representation must not change the result of a check.

### Native reduction

`Runtime/Capability/Lean434NativeReduction.lean` exposes an optional provider:

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
4. portable-source profile, `psc1 check`, canonical `.ps` recheck and Lean-native tests are green.

Generated compiler/kernel fixed-point reproduction is optional/manual and is
reserved for explicit bootstrap/release checkpoints.

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

## Checker ownership migration

Checker implementations live under `Checker/`; former `TypeChecker*` and
`Theory/{Reduction,Inference,Recursor,DefEq}` import shims have been removed.
Definition bodies, fuel transitions and rule ordering are unchanged by this move.
`Checker/Knot` now owns cross-component callback wiring, including the
projection shortcut. `Checker/Ops` declares six operations: infer, check, whnfCore,
whnf, defeq and reduceRecursor. `Checker/Session` calls the concrete Knot
operations directly, avoiding allocation of a whole Ops record on each cache hit.
The Ops constructor uses the same concrete operations; check continues to select
the fully checked path. Existing function bodies were
moved verbatim. The architecture audit enforces the wiring symbol owner, import
fences and the retirement of legacy import paths.

The focused CheckerOps conformance module checks success and zero-fuel rejection
for all six operations. It also checks that full session checking rejects an
ill-typed application after infer-only checking has populated its cache.

## Unified admission ownership

Declaration and Quot admission now live under `Admission/`. Ordinary, mutual and
nested inductive phases share `Admission/Inductive/`; shared occurrence, parameter,
elimination and recursor-validation phases have explicit owners in `Common/`.
Constructor-specific positivity remains with each ordinary/mutual analysis owner,
because those routines use distinct shapes and are not one interchangeable rule.
The move preserves all existing declaration bodies and admission order.

## Core and environment ownership

Core values and substitution now live under `Core/`. `Environment/Semantic`
owns ordered declaration history; `Environment/Environment` retains the existing
wrapper representation; lookup and mutation have separate owners. Runtime
capability types live in `Runtime/Capability/Types`. The semantic view excludes
the rebuildable index and native evaluator. Existing environment constructors
and capability forwarding remain compatible; new public sessions configure the
capability explicitly. No lookup or mutation algorithm changed.

## Production architecture exit evidence

`PSKERNEL_ARCHITECTURE.json` records all canonical owners and confirms that no migration shims remain.
The audit checks import fences, unique Knot wiring, Lake registration, completed
layer ownership, all 61 rule mappings and all 136 legacy diagnostic mappings.
Rule evidence must be imported and callable from the foundation main. The
34-row Lean compatibility/conformance matrices remain the semantic gates.
`ARCHITECTURE_MIGRATION_REPORT.md` records completion scope and intentional
representation choices; formal proof coverage remains a separate assurance task.
