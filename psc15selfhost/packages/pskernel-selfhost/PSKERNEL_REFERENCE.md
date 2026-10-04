# PSKernel Reference

> Canonical architecture review, Lean 4.34 theory map, current-state audit, final target architecture, trust model, dependency law, evidence model, and migration plan for the portable self-host kernel.

## 0. Status and scope

This document is the human architecture reference for:

~~~text
repository: dwijayuda/pskernel
branch:     psc2/psc1kernel-selfhost-portable
package:    psc15selfhost/packages/pskernel-selfhost
~~~

Audited PSKernel implementation head:

~~~text
9611405267dbdaa66812e4dfa7642fc799d2e758
~~~

PSKernel reference revision:

~~~text
this document supersedes the first PSKERNEL_REFERENCE.md created at
9f13c2caf1e5ff55a1f605fe0dc8d54c42a6375b
~~~

Lean compatibility authority:

~~~text
Lean 4.34.0
commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

Research date:

~~~text
2026-10-05
~~~

This reference has four jobs:

1. explain the Lean theory that PSKernel implements;
2. map that theory to the exact Lean 4.34 kernel implementation;
3. evaluate the current PSKernel self-host architecture honestly;
4. define a final target architecture that can be reached without changing semantics.

Machine-readable semantic completion remains authoritative in:

- LEAN_4_34_COMPATIBILITY.json
- LEAN_4_34_CONFORMANCE.json

Normative anti-drift policy remains in:

- PSKERNEL_SELFHOST_ARCHITECTURE.md

The active work plan remains in:

- DEVELOPMENT_PLAN.md

Detailed algorithm exposition remains in:

- KERNEL_THEORY.md

Generated rule indexing remains in:

- KERNEL_RULE_REFERENCE.md

This document should not duplicate those files unnecessarily. It defines how they fit together.

---

# 1. Executive conclusion

## 1.1 Current implementation

The current PSKernel self-host implementation is already a credible Lean 4.34-compatible kernel architecture.

Its strongest properties are:

- one maintained semantic implementation;
- explicit Lean 4.34 pinning;
- PSC1-self-hostable source;
- fail-closed errors and exhaustion;
- faithful checked-vs-infer-only distinction;
- a clear WHNF pipeline;
- a particularly strong definitional-equality decomposition;
- explicit ordinary, mutual and nested inductive admission;
- separate cache/index implementation;
- current 34/34 declared compatibility coverage;
- current 34/34 conformance mapping;
- frequent Lean-native performance comparison;
- a portable-source and canonical-ProofScript closure gate.

Current implementation architecture score:

~~~text
8.7 / 10
~~~

This score is intentionally below the target score.

The main remaining weakness is not missing Lean theory. It is physical architecture:

- folder ownership;
- import direction;
- checker-cycle wiring;
- migration-era top-level wrappers;
- trust-boundary classification;
- independent oracle coverage;
- very large test/benchmark files.

## 1.2 Previous target-plan score

The first PSKERNEL_REFERENCE proposed:

- Core
- Runtime
- Environment
- Checker
- Admission
- API
- Compat

with an explicit Checker/Engine and a unified inductive hierarchy.

Under the stricter rubric used in this review, that plan scores:

~~~text
9.44 / 10
~~~

It was directionally correct but still had important weaknesses:

1. Runtime grouped harmless caches/indexes together with native evaluation, even though native evaluation extends the trusted computing base.
2. Checker/Engine was described as an integration point but did not precisely define the recursion-knot interface.
3. Environment/runtime separation was still partly documentary rather than structural.
4. Compat was still shown as part of the final tree rather than a temporary migration layer.
5. The target did not define a machine-readable architecture manifest.
6. The oracle model still needed a stronger official-Lean-first hierarchy.
7. The target did not explicitly separate source architecture from migration architecture.

## 1.3 Design loop

The architecture was rescored after each redesign pass.

| Iteration | Main improvements | Score |
| --- | --- | ---: |
| 1 | first reference target: Core/Runtime/Environment/Checker/Admission/API | 9.44 |
| 2 | import fences, explicit checker knot, split tests, official Lean oracle, API contract | 9.78 |
| 3 | acceleration vs trusted-capability separation, semantic environment projection, final tree without Compat, architecture manifest, strict source ownership | **9.90** |

The final target architecture defined by this document therefore clears the requested threshold:

~~~text
final planned architecture score: 9.90 / 10
~~~

This is a score for the **planned architecture**.

It is not a claim that the current implementation has already reached 9.90.

---

# 2. Source authority hierarchy

Architecture decisions need a clear authority order.

Use:

~~~text
1. exact Lean 4.34.0 kernel source at the pinned commit
2. Lean 4.34 release hardening notes and direct behavior
3. Lean core type-system documentation
4. official Lean kernel differential execution
5. PSKernel machine compatibility/conformance matrices
6. frozen PSC1Kernel differential reference
7. independent checker implementations as comparative evidence
8. architectural inference and engineering judgment
~~~

The distinction between items 1 and 3 matters.

The live Lean Language Reference currently follows a newer release line than PSKernel's target. The exact 4.34.0 source is therefore the authority for implementation-order claims.

A particularly important example is native reduction:

- Lean 4.34 supports the deprecated Lean.reduceBool / Lean.reduceNat kernel path.
- Lean 4.35 removes it.
- PSKernel is pinned to 4.34.0, so 4.34 behavior must be preserved until the target changes explicitly.

Future-Lean information is useful for architecture isolation, but it must not silently alter current semantics.

---

# 3. Lean's kernel boundary

Lean has a deliberately small trusted logical core.

The kernel receives already elaborated expressions and declarations.

Outside the core kernel are:

~~~text
surface syntax
parser
macros
elaboration
unification
tactics
typeclass search
termination elaboration
compiler
code generator
package/build tooling
IDE/server
~~~

Recursive source functions are translated into primitive recursor use before kernel checking.

The kernel therefore does not need a general syntactic termination checker.

Conceptually, the main trusted transition is:

~~~text
Environment
    +
core Declaration
    |
    v
kernel validation
    |
    +-- reject
    |
    '-- accept -> Environment'
~~~

The corresponding PSKernel architecture should optimize for declaration validation, not attempt to absorb frontend/compiler responsibilities.

---

# 4. Lean theory implemented by the kernel

Lean's core theory is a dependently typed lambda calculus derived from the Calculus of Constructions and extended with inductive types, quotient primitives, proof irrelevance and Lean-specific definitional computation.

The central executable judgments for PSKernel are:

~~~text
infer  : Γ |- e : A

check  : Γ |- e valid, returning type A

whnf   : e -->* weak-head form

defeq  : Γ |- A <=> B

admit  : Environment + Declaration -> Environment'
~~~

They are algorithmically mutually dependent.

Inference needs conversion.
Conversion needs reduction and sometimes inference.
Reduction needs recursor metadata and sometimes conversion.
Admission invokes all of them.

This checker recursion knot is fundamental and should be explicit in the architecture.

---

# 5. Core expression language

Lean 4.34 kernel expressions include:

~~~text
BVar
FVar
MVar
Sort
Const
App
Lambda
Pi
Let
Lit
MData
Proj
~~~

The elaborator may create metavariables while solving a source program.

The kernel checker does not accept unresolved metavariables as valid checked terms.

Important architecture implication:

Core representation should remain independent from checker state, admission policy and runtime caches.

---

# 6. Universes

Lean universe levels contain:

~~~text
zero
succ
max
imax
parameter
metavariable
~~~

Relevant theory properties:

- Prop is Sort 0.
- Type u is Sort (u + 1).
- Prop is impredicative.
- Type universes are predicative.
- Lean universes are non-cumulative.
- Pi universes use imax.

Level equivalence is not mere constructor equality.

The kernel uses a semantic level-equivalence algorithm.

Therefore:

~~~text
Core/Level
~~~

is a foundational subsystem, not a utility module.

---

# 7. Functions, Pi types and conversion

Core rules include approximately:

~~~text
Sort u : Sort (succ u)

A : Sort u
B : Sort v
--------------------------
Pi x : A, B : Sort (imax u v)

Γ, x : A |- b : B
--------------------------
Γ |- fun x : A => b : Pi x : A, B

Γ |- f : Pi x : A, B
Γ |- a : A'
A' <=> A
--------------------------
Γ |- f a : B[a/x]
~~~

The final application rule explains why checked application depends on definitional equality.

Lean also supports function eta as definitional equality.

---

# 8. Proof irrelevance

Prop is definitionally proof-irrelevant.

When t and s inhabit definitionally equal propositions:

~~~text
Γ |- t : P
Γ |- s : Q
P <=> Q
P,Q : Prop
----------------
t <=> s
~~~

Proof irrelevance is not compiler erasure.

It is a kernel conversion rule.

This makes the correctness of isProp and projection restrictions soundness-critical.

---

# 9. Definitional equality

Lean definitional equality includes:

~~~text
beta
delta
iota
zeta
Quot computation
function eta
restricted structure eta
proof irrelevance
literal-specific behavior
~~~

The implementation is not:

~~~text
normalize both terms fully
compare syntax
~~~

Instead it is a staged, heuristic, sound-but-incomplete decision procedure.

The current Lean documentation explicitly describes the mechanically implemented relation as reflexive and symmetric but not transitive.

That property is architecture-critical.

---

# 10. Why the defeq cache must not use transitive closure

Lean 4.34 fixed a soundness issue caused by caching successful defeq results in a union-find structure.

Union-find creates transitive equivalence classes.

Lean's implemented defeq procedure is not transitive.

Therefore the cache itself changed observable answers depending on query history.

Lean 4.34 replaced this with pair-keyed caching.

PSKernel must preserve:

~~~text
successful pair cache
failed pair cache
~~~

and must never replace them with:

~~~text
union-find
equivalence closure
congruence closure used as semantic acceptance
~~~

This is a permanent soundness invariant.

---

# 11. Lean 4.34 kernel hardening that matters architecturally

Lean 4.34 specifically hardened the kernel in ways that should drive PSKernel tests and module boundaries.

Important items include:

## 11.1 DefEq cache order independence

Successful conversion facts must be stored as pair facts, not a transitive closure.

## 11.2 isProp must ensure a Sort

A stuck inferred type cannot silently be treated as "not a proposition".

The checker must establish that the type reduces to a Sort before deciding Prop-ness.

## 11.3 Projection from Prop

Projection typing must preserve proof irrelevance restrictions.

A data field must not be extractable from a term whose inductive type may be Prop under the relevant universe conditions.

## 11.4 Recursor rule type preservation

Generated computation-rule RHSs must not merely be well typed.

Their type must be definitionally equal to the expected recursor result type.

## 11.5 Uniform inductive occurrences

A newly declared family must occur with the correct parameter/universe application where required.

## 11.6 Nested auxiliary namespace

User input must not reach into the internal nested-inductive auxiliary namespace.

## 11.7 Dropped nested parameters

Nested transformation cannot let parametric arguments escape type checking.

## 11.8 Nat resource limit

Kernel Nat computation is bounded to avoid compact terms forcing unreasonable giant numeral allocation.

These belong in permanent adversarial regression coverage.

---

# 12. Inductive types

Inductive declarations add:

~~~text
type former(s)
constructors
recursor(s)
recursor computation rules
metadata used by projections/reduction
~~~

Kernel validation includes:

- universe validity;
- common parameter shape;
- indices;
- constructor result shape;
- strict positivity;
- recursive argument classification;
- elimination restrictions;
- generated recursor type;
- generated computation rules;
- recursor rule type preservation.

An architecture that hides all of these under one "add inductive" function is difficult to audit.

PSKernel's existing phase decomposition should be preserved.

---

# 13. Mutual inductives

Mutual groups require one checked transaction across several families.

They require:

~~~text
shared parameter/universe discipline
one motive per family
minor premises across all constructors
recursive hypotheses crossing family boundaries
coordinated recursor generation
~~~

Mutual admission is not ordinary admission repeated several times.

It deserves a dedicated subsystem inside a common Inductive hierarchy.

---

# 14. Nested inductives

Lean supports nested recursion by transforming nested occurrences into an auxiliary mutual-inductive problem and restoring the public declarations afterward.

The conceptual official path is:

~~~text
validate original declaration
        |
        v
identify nested occurrences
        |
        v
generate auxiliary nested families
        |
        v
rewrite constructors / form auxiliary block
        |
        v
ordinary/mutual inductive admission
        |
        v
restore constructor and recursor expressions
        |
        v
validate dropped nested applications
        |
        v
re-check rewritten constructor types
        |
        v
re-check rewritten recursor types/rules
        |
        v
return final environment without auxiliary declarations
~~~

The recent PSKernel multi-family bug demonstrated why restoration state must have two distinct concepts:

~~~text
pending
    structurally shrinking iteration queue

allFamilies
    complete immutable restoration registry
~~~

Later families can contain references to earlier auxiliary families.

Restoring against only the pending suffix is incorrect.

This is now a permanent architecture invariant.

---

# 15. Quotient theory

Lean's built-in quotient core consists of primitives such as:

~~~text
Quot
Quot.mk
Quot.lift
Quot.ind
Quot.sound
~~~

There is a definitional reduction rule for Quot.lift applied to Quot.mk.

Architecturally:

- Quot primitive installation belongs to admission.
- Quot computation belongs to reduction.
- Quot state belongs to the semantic environment.

PSKernel's current separation already follows this well.

---

# 16. Exact Lean 4.34 source structure

At the pinned Lean commit, src/kernel contains focused representation/infrastructure files and two especially large semantic implementation files.

Representative layout:

~~~text
abstract.*
declaration.*
environment.*
expr.*
expr_cache.*
expr_eq_fn.*
expr_maps.h
expr_sets.h
find_fn.h
for_each_fn.*
inductive.*
instantiate.*
kernel_exception.h
level.*
local_ctx.*
quot.*
replace_fn.*
trace.*
type_checker.*
~~~

The largest semantic concentration is approximately:

~~~text
inductive.cpp
type_checker.cpp
~~~

This official layout is optimized around C++ implementation concerns.

It is not a pedagogical target for PSKernel.

PSKernel should preserve Lean's algorithm and ordering while exposing more conceptual boundaries.

---

# 17. Lean 4.34 type_checker architecture

Lean's type checker owns a shared state containing:

~~~text
environment
fresh-name generator

infer cache:
    infer-only
    checked

whnfCore cache
whnf cache
unfold cache

successful defeq pair cache
failed defeq pair cache
~~~

Operationally it ties together:

~~~text
infer/check
whnfCore
whnf
projection
recursor reduction
defeq
isProp
unfold
primitive Nat reduction
native reduction
~~~

This is one recursive algorithmic engine.

PSKernel should preserve modular source files but explicitly represent this one engine boundary.

---

# 18. Checked inference versus infer-only inference

Lean 4.34 has two semantically distinct inference paths.

Checked application:

~~~text
check/infer function
ensure Pi
check/infer argument
compare argument type against domain
instantiate codomain
~~~

Infer-only application:

~~~text
infer function
walk application spine
expose Pi types as needed
avoid re-checking known-valid arguments
compute result type
~~~

The infer-only path is valid only under a precondition that the term is already known to be well typed.

PSKernel must continue making that distinction explicit.

Architectural rule:

~~~text
infer-only is not "fast check"
infer-only is "type recovery under a previously established validity invariant"
~~~

Any optimized path that relies on this must name the invariant.

---

# 19. Lean WHNF architecture

Lean's public weak-head reduction pipeline is approximately:

~~~text
whnfCore
    |
    +-- target-specific native reduction
    |
    +-- optimized Nat literal reduction
    |
    +-- delta unfold
    |      |
    |      '-- loop
    |
    '-- return
~~~

whnfCore handles structural reduction such as:

~~~text
beta
zeta
projection
recursor/Quot-facing reductions
~~~

The public order is observable because the defeq algorithm is incomplete and order-sensitive.

PSKernel's existing WhnfCore/public-WHNF split should remain.

---

# 20. Lean defeq orchestration

At a high level, Lean 4.34 performs:

~~~text
quick structural/cache checks
reflection shortcut
cheap/core WHNF
quick checks again
proof irrelevance
lazy delta
same-constant/free-variable shortcuts
projection-sensitive lazy comparison
full projection WHNF
application comparison
function eta
structure eta
string literal expansion
unit-like structure equality
failure
~~~

This sequence should remain easy to read top-to-bottom in PSKernel.

The current PSKernel DefEq subsystem already improves on the official source in auditability.

---

# 21. Independent checker lesson: lean4lean

lean4lean is especially relevant because its executable implementation is derived closely from Lean's official kernel.

Important architectural features:

~~~text
Lean4Lean/
    executable checker implementation

Lean4Lean/Theory/
    abstract metatheory

Lean4Lean/Verify/
    relation between implementation and theory
~~~

Its TypeChecker defines an explicit recursive-method interface containing operations corresponding to:

~~~text
isDefEqCore
whnfCore
whnf
inferType
~~~

and ties the recursive checker through a single monadic knot.

This directly validates one of the improvements PSKernel needs:

The recursive checker interface should have one explicit architectural owner.

PSKernel does not need to adopt lean4lean's formal verification scope.

It should adopt the clarity of the recursive-method boundary.

---

# 22. Independent checker lesson: ConLeche

ConLeche provides a different useful lesson.

Its implementation distinguishes:

~~~text
Kernel/
    pure fueled checker

Cached/
    shipped cached checker

Frontend/
    input preparation

Model/
Verify/
    proof layers
~~~

and enforces import layering with a CI import fence.

The key lesson for PSKernel is not to duplicate the checker into pure and cached versions.

PSKernel's one-semantic-source rule should remain.

The useful lesson is:

~~~text
architecture constraints should be executable CI rules
~~~

A documented dependency rule is weaker than a failing import-fence check.

---

# 23. Current PSKernel physical architecture

Audited source root:

~~~text
packages/pskernel-selfhost/src/Ps/KernelSelfHost/
~~~

Approximate current size:

~~~text
70 Lean source files
~795 KB source text
~~~

Current rough distribution:

~~~text
top-level files : 24
Runtime         : 3
Theory          : 43
~~~

Theory subtree:

| Area | Files | Approx. bytes |
| --- | ---: | ---: |
| Admission | 2 | 24 KB |
| DefEq | 7 | 90 KB |
| Inductive | 4 | 51 KB |
| Inference | 2 | 39 KB |
| Mutual | 5 | 90 KB |
| Nested | 10 | 128 KB |
| Quot | 2 | 22 KB |
| Recursor | 2 | 34 KB |
| Reduction | 4 | 47 KB |
| Substitution | 5 | 26 KB |

Large current source files include:

~~~text
Theory/Inference/Core.lean
Expr.lean
Theory/Mutual/Analysis.lean
Level.lean
Theory/Nested/Validation.lean
Inductive.lean
InductiveAdmission.lean
Theory/Nested/Discover.lean
Theory/Inductive/Constructor.lean
TypeCheckerDefEq.lean
Theory/Nested/Flatten.lean
Theory/Recursor/Analysis.lean
TypeCheckerProjection.lean
Theory/Mutual/AdmissionLoops.lean
~~~

The issue is not any one file being unreasonably large.

The bigger issue is ownership consistency.

---

# 24. Current PSKernel conceptual architecture

Current conceptual map:

~~~text
Core representation
    Name
    Level
    Expr
    substitution
    Declaration
    LocalContext
    Environment

Checker
    CheckerState
    TypeCheckerBase
    Reduction/WHNF
    Projection
    Inference
    Recursor
    DefEq
    CheckerSession

Admission
    ordinary declarations
    Quot
    ordinary inductives
    mutual inductives
    nested inductives

Execution support
    cache
    environment index
    native evaluation capability

Wrappers/roots
    Kernel
    Instantiate
    TypeChecker*
    Quot
    Inductive*
    MutualInductive
    NestedInductive
    SelfHost
~~~

Conceptually this is strong.

Physically the tree does not yet tell this same story.

---

# 25. Current PSKernel strengths

## 25.1 One semantic implementation

There is no hand-maintained "reference semantics" plus separate "fast semantics" inside the self-host package.

That is the right product architecture.

## 25.2 Exact target pin

Lean behavior is attached to an exact version/commit.

This prevents silent drift.

## 25.3 PSC1 source closure

The kernel is intentionally written within the portable source subset.

This directly serves the bootstrap/self-host goal.

## 25.4 Fail-closed resource behavior

Fuel/recursion exhaustion rejects.

No fallback converts an unsupported or exhausted computation into acceptance.

## 25.5 DefEq structure

The current DefEq split is excellent:

~~~text
BinderSpines
Quick
DeltaStep
LazyDelta
Shortcuts
FullShape
FinalRules
~~~

## 25.6 Nested architecture

The current nested phase split is excellent:

~~~text
Types
ReservedNames
Rebase
Discover
Flatten
RestoreExpr
Restore
Validation
Commit
Admission
~~~

## 25.7 Runtime indexing

Environment and expression-cache indexing preserve structural semantic equality and use hashing only as an accelerator.

## 25.8 Performance discipline

Recent optimization work generally follows:

~~~text
profile
make one narrow change
run portable/conformance gates
measure again
keep or revert
~~~

That discipline should become part of the permanent architecture.

---

# 26. Current PSKernel weaknesses

## 26.1 Top-level ownership is inconsistent

The top level mixes:

~~~text
foundational data
checker state/context
real checker integration
ordinary-inductive data
ordinary-inductive admission
API umbrellas
compatibility umbrellas
semantic root
~~~

This weakens discoverability.

## 26.2 "Theory" is overloaded

Most files under Theory are executable implementation, not abstract metatheory.

That differs from projects such as lean4lean, where Theory really means an abstract logical theory.

For PSKernel, names such as Checker/Inference or Admission/Inductive are clearer.

## 26.3 Import direction does not fully match conceptual direction

Example:

~~~text
Theory/Inference/Helpers
    imports TypeCheckerProjection

TypeCheckerProjection
    imports TypeCheckerWhnf

TypeCheckerWhnf
    imports Theory/Reduction/WhnfCore
~~~

This is acyclic but conceptually inverted.

The folder names imply that Theory is below TypeChecker, while the import graph crosses that boundary in both conceptual directions.

## 26.4 The checker recursion knot has no single owner

The mutually dependent checker operations are distributed across several files and callback signatures.

The code works.

The architecture does not yet make the knot obvious.

## 26.5 Ordinary/mutual/nested source hierarchy is inconsistent

Current physical shape:

~~~text
Inductive.lean
InductiveAdmission.lean
Theory/Inductive/*

Theory/Mutual/*
MutualInductive.lean

Theory/Nested/*
NestedInductive.lean
~~~

These are one conceptual admission subsystem.

## 26.6 Runtime classification is too broad

Cache/index and native execution are not the same trust class.

Caches/indexes are intended to be observationally irrelevant.

Native execution can affect reduction and therefore acceptance if wrong.

Native execution extends the trusted computing base.

They should not share one undifferentiated architectural category.

## 26.7 Cache policy ownership is mixed with typing helpers

Inference cache eligibility is a runtime/performance policy.

It currently lives with inference helpers.

The policy is valid, but its ownership should be clearer.

## 26.8 Environment mixes semantic and execution fields

The current environment contains:

~~~text
constants
index
quotInitialized
runtime/native evaluator
~~~

The semantic authority is constants plus semantic flags.

Index/provider fields have different trust meaning.

That distinction should be visible structurally.

## 26.9 Conformance rows are too coarse for high-risk algorithms

A single row such as:

~~~text
PSK-ADMIT-NESTED
~~~

cannot by itself communicate all soundness-critical subrules.

## 26.10 Differential oracle independence is incomplete

The frozen PSC1Kernel reference is useful.

But PSKernel-selfhost was derived from closely related code.

Shared bugs remain possible.

Official pinned Lean must become the primary external behavioral oracle wherever direct differential execution is practical.

## 26.11 Test and benchmark files are monolithic

Current important files are approximately:

~~~text
PsKernelSelfHostFoundationTests.lean  ~106 KB
PsKernelSelfHostBench.lean            ~145 KB
~~~

They should be split by ownership.

---

# 27. Architecture scoring rubric

The final design is evaluated against this weighted rubric.

| Dimension | Weight |
| --- | ---: |
| Trust boundary and Lean semantic fidelity | 15% |
| Checker decomposition and recursion-knot wiring | 13% |
| Dependency layering and machine enforcement | 12% |
| Separation of semantics, acceleration and trusted capabilities | 10% |
| Inductive subsystem coherence | 10% |
| PSC1 portability and self-host closure | 10% |
| Conformance and oracle independence | 10% |
| API/provider boundary | 7% |
| Test/benchmark architecture | 7% |
| Migration safety and maintainability | 6% |

Scores are engineering judgments, not formal proofs.

A score above 9.8 means the plan has no known major structural weakness under this rubric.

It does not prove semantic correctness.

---

# 28. Iteration 1 evaluation

The first reference target proposed:

~~~text
Core
Runtime
Environment
Checker
Admission
API
Compat
~~~

Strengths:

- canonical folders;
- Checker/Engine;
- unified inductives;
- split tests;
- import fence;
- official Lean oracle plan.

Weaknesses:

- native evaluation incorrectly shared a Runtime category with harmless accelerators;
- checker-knot abstraction not concrete enough;
- environment semantic projection not explicit;
- final tree still contained migration shims;
- architecture contract was not machine-readable;
- trust classes were not first-class.

Weighted score:

~~~text
9.44 / 10
~~~

Result:

~~~text
reject as final target
~~~

---

# 29. Iteration 2 evaluation

Second pass added:

- explicit Checker/Ops interface;
- Checker/Knot as the one recursive wiring point;
- import-fence CI;
- official-Lean-first differential architecture;
- subsystem test split;
- API/KernelContractV1;
- hierarchical conformance subrules.

Weighted score:

~~~text
9.78 / 10
~~~

Remaining concerns:

1. native evaluation was still not separated strongly enough from non-semantic acceleration;
2. final-source and migration-source trees were still conflated;
3. semantic environment equivalence and accelerator rebuild invariants were not explicit;
4. module ownership was not yet machine-declared.

Result:

~~~text
below requested 9.8 threshold
continue redesign
~~~

---

# 30. Final target architecture

Final planned score:

~~~text
9.90 / 10
~~~

The core idea is to separate five different architectural concerns that the current layout partially mixes:

~~~text
logical data
execution environment
checker algorithm
admission transactions
external/public boundary
~~~

and to further distinguish:

~~~text
non-semantic acceleration
from
trusted external capability
~~~

---

# 31. Final canonical source tree

The recommended final tree is:

~~~text
Ps/KernelSelfHost/
|
+-- Core/
|   +-- Name.lean
|   +-- Level.lean
|   +-- Expr.lean
|   +-- Declaration.lean
|   +-- LocalContext.lean
|   '-- Substitution/
|       +-- ListOps.lean
|       +-- Lift.lean
|       +-- Instantiate.lean
|       +-- Beta.lean
|       '-- Abstract.lean
|
+-- Runtime/
|   +-- Acceleration/
|   |   +-- Cache.lean
|   |   +-- CachePolicy.lean
|   |   '-- EnvironmentIndex.lean
|   |
|   '-- Capability/
|       +-- Types.lean
|       '-- Lean434NativeReduction.lean
|
+-- Environment/
|   +-- Semantic.lean
|   +-- Environment.lean
|   +-- Lookup.lean
|   '-- Operations.lean
|
+-- Checker/
|   +-- Context.lean
|   +-- State.lean
|   +-- Ops.lean
|   +-- Projection.lean
|   |
|   +-- Reduction/
|   |   +-- PrimitiveData.lean
|   |   +-- PrimitiveNat.lean
|   |   +-- KernelReductions.lean
|   |   '-- WhnfCore.lean
|   |
|   +-- Inference/
|   |   +-- Helpers.lean
|   |   '-- Core.lean
|   |
|   +-- Recursor/
|   |   +-- Analysis.lean
|   |   '-- Reduction.lean
|   |
|   +-- DefEq/
|   |   +-- BinderSpines.lean
|   |   +-- Quick.lean
|   |   +-- DeltaStep.lean
|   |   +-- LazyDelta.lean
|   |   +-- Shortcuts.lean
|   |   +-- FullShape.lean
|   |   '-- FinalRules.lean
|   |
|   +-- Knot.lean
|   '-- Session.lean
|
+-- Admission/
|   +-- Declaration/
|   |   +-- Validation.lean
|   |   '-- Admission.lean
|   |
|   +-- Quot/
|   |   +-- Bootstrap.lean
|   |   '-- Admission.lean
|   |
|   '-- Inductive/
|       +-- Types.lean
|       |
|       +-- Common/
|       |   +-- Parameters.lean
|       |   +-- Occurrence.lean
|       |   +-- Positivity.lean
|       |   +-- Elimination.lean
|       |   '-- RecursorValidation.lean
|       |
|       +-- Ordinary/
|       |   +-- Constructor.lean
|       |   +-- ConstructorAdmission.lean
|       |   +-- Recursor.lean
|       |   '-- Admission.lean
|       |
|       +-- Mutual/
|       |   +-- Analysis.lean
|       |   +-- Header.lean
|       |   +-- Recursor.lean
|       |   +-- AdmissionLoops.lean
|       |   '-- Admission.lean
|       |
|       '-- Nested/
|           +-- Types.lean
|           +-- ReservedNames.lean
|           +-- Rebase.lean
|           +-- Discover.lean
|           +-- Flatten.lean
|           +-- RestoreExpr.lean
|           +-- Restore.lean
|           +-- Validation.lean
|           +-- Commit.lean
|           '-- Admission.lean
|
+-- API/
|   +-- KernelContractV1.lean
|   +-- Kernel.lean
|   +-- Session.lean
|   '-- Provider.lean
|
'-- SelfHost.lean
~~~

This is the final target tree.

Compatibility shims are deliberately absent.

---

# 32. Temporary migration tree

During migration only, old import paths may be preserved under:

~~~text
Ps/KernelSelfHost/Compat/
~~~

or as old-path one-line forwarding modules.

Rules:

1. Compat modules may import canonical modules.
2. Canonical modules may never import Compat.
3. SelfHost.lean may never import Compat.
4. Compat is excluded from the canonical semantic-closure manifest.
5. Every Compat file has a deletion condition.
6. Compat disappears when repository consumers have moved.

This distinction fixes a weakness in the first plan:

~~~text
migration architecture != final architecture
~~~

---

# 33. Final dependency layers

The final dependency graph is:

~~~text
Layer 0
Core

Layer 1
Runtime/Acceleration
Runtime/Capability interfaces

Layer 2
Environment

Layer 3
Checker components

Layer 4
Checker/Knot
Checker/Session

Layer 5
Admission

Layer 6
API

Layer 7
SelfHost root
~~~

Allowed imports:

~~~text
Core
  imports Core only

Runtime/Acceleration
  imports Core only

Runtime/Capability
  imports Core only

Environment
  imports Core
  imports Runtime/Acceleration
  may refer to capability types only where unavoidable

Checker components
  import Core
  import Environment
  import Runtime/Acceleration
  import Runtime/Capability interface
  do not import Admission or API

Checker/Knot
  imports Checker components
  owns recursive checker wiring

Checker/Session
  imports Knot
  exposes state-threading operations

Admission
  imports Core/Environment/Checker
  does not define alternate checker semantics

API
  imports Admission/Checker
  contains stable external contracts only

SelfHost
  imports canonical API/admission roots
  imports no Compat
~~~

---

# 34. Machine-enforced dependency architecture

Create a machine-readable architecture file:

~~~text
PSKERNEL_ARCHITECTURE.json
~~~

Recommended fields:

~~~text
schemaVersion
semanticRoot
targetLeanVersion
targetLeanCommit

layers:
  name
  pathPrefix
  trustClass
  allowedImportLayers

modules:
  path
  owner
  role
  semantic
  public
  compatibilityShim

invariants:
  noCompatInSemanticRoot
  noReferenceKernelInSemanticRoot
  noTestImportsInSemanticRoot
  noUpwardImports
  oneSemanticOwnerPerRule
~~~

Add CI:

~~~text
psc1kernel-architecture-audit.mjs
~~~

It should fail when the source tree violates declared ownership.

This is a major improvement over relying only on prose.

---

# 35. Trust classes

The final architecture uses explicit trust classes.

## T0 - semantic kernel rule

Examples:

~~~text
universe equivalence
checked inference
WHNF order
defeq order
recursor reduction
inductive positivity
nested restoration validation
declaration admission
~~~

A T0 change may alter acceptance.

It requires semantic/conformance review.

## T1 - non-semantic acceleration

Examples:

~~~text
environment index
expression-map representation
pair-set representation
cache promotion threshold
cache-eligibility policy
precomputed structural hash
~~~

T1 must not create a fact.

Removing every T1 accelerator must preserve answers, modulo performance/resource consumption.

## T2 - trusted capability

Examples in Lean 4.34 compatibility:

~~~text
compiled execution used by Lean.reduceBool
compiled execution used by Lean.reduceNat
~~~

A wrong T2 result can change kernel acceptance.

T2 therefore extends the TCB.

It must never be documented as merely a cache.

## T3 - adapter/protocol

Examples:

~~~text
provider-neutral API adapter
serialization
bridge into npm/JS host
declaration codec
~~~

T3 must translate data and calls.

It must not implement an alternate typing rule or fallback acceptance path.

---

# 36. Why native reduction gets its own capability namespace

Lean 4.34's native reduction route executes compiled code for a closed constant.

That makes the compiler/runtime part of the trust boundary for that operation.

Lean 4.35 removes this deprecated route.

Therefore the final 4.34 architecture should isolate it as:

~~~text
Runtime/Capability/Lean434NativeReduction.lean
~~~

rather than placing it next to:

~~~text
Cache
EnvironmentIndex
~~~

This provides three benefits:

1. TCB expansion is visible.
2. A future Lean target can remove the module cleanly.
3. Cache/index reasoning cannot accidentally be used to justify native evaluation.

No provider remains:

~~~text
native step unavailable
-> continue normal kernel reduction
~~~

A provider must never be used as a fallback after semantic failure.

---

# 37. Environment architecture

The long-term environment should expose a semantic projection.

Recommended conceptual representation:

~~~text
PsKernelSemanticEnvironment
    constants
    quotInitialized

PsKernelEnvironment
    semantic
    index
~~~

Trusted checker capabilities should live in CheckerContext/Session configuration rather than semantic declaration history.

Important invariant:

~~~text
semanticView(environment)
~~~

must be sufficient to determine the logical environment.

EnvironmentIndex is a derivative of semantic constants.

It may be:

~~~text
discarded
rebuilt
changed in representation
~~~

without changing semanticView.

All environment mutations should go through one Operations module that updates semantic state and the index together.

## 37.1 Migration rule

Do not begin the architectural migration with this representation change.

First make folder/import ownership clean.

Then, if the environment split remains worthwhile, perform it as a separate measured commit series.

Architecture quality does not justify combining source moves with representation changes.

---

# 38. Checker context architecture

CheckerContext should contain logical/check configuration:

~~~text
environment
local context
universe parameters
definition safety
eager-reduction mode
resource limits
recursion depth
trusted capability set
~~~

Important distinction:

~~~text
environment semantic content
!=
trusted execution capability
~~~

This is why native-evaluator configuration belongs in the checker context/capability boundary, not in the semantic environment projection.

---

# 39. Checker state architecture

CheckerState should own transient per-session state:

~~~text
fresh-name state

infer-only cache
checked-infer cache

whnfCore cache
whnf cache
unfold cache

defeq success pair set
defeq failure pair set
~~~

State is not part of the logical environment.

A new session may start with empty caches and must produce the same semantic answers.

---

# 40. Checker/Ops and Checker/Knot

This is the most important structural refinement over the first reference.

The checker contains mutually dependent operations.

Instead of exposing this dependency accidentally through top-level import placement, define one internal operations interface.

Conceptually:

~~~text
CheckerOps
    infer
    check
    whnfCore
    whnf
    defeq
    reduceRecursor
~~~

Checker components receive only the callbacks they need.

Checker/Knot.lean ties the implementations together exactly once.

Conceptual graph:

~~~text
Reduction ───────┐
Inference ───────┤
Recursor ────────┼──> Checker/Knot
DefEq ───────────┤          |
Projection ──────┘          v
                       Checker/Session
~~~

This follows the useful pattern visible in lean4lean's explicit TypeChecker.Methods recursion interface.

## 40.1 PSC1 portability constraint

Do not introduce an elegant abstraction that the portable compiler cannot self-host reliably.

The architecture requirement is:

~~~text
one owned knot
~~~

not necessarily:

~~~text
one specific record-of-functions implementation
~~~

If a function-field structure causes portability or performance problems, keep the existing proven curried callback style but move all wiring into Checker/Knot.lean.

---

# 41. Inference ownership

Canonical inference path:

~~~text
Checker/Inference/Helpers.lean
        |
        v
Checker/Inference/Core.lean
        |
        v
Checker/Knot.lean
        |
        v
Checker/Session.lean
~~~

Helpers may expose:

- ensure Sort/Pi views;
- application-spine utilities;
- local binder helpers.

Cache publication/eligibility should move to:

~~~text
Runtime/Acceleration/CachePolicy.lean
~~~

Inference code may call the policy.

The policy must not be described as a typing rule.

---

# 42. Reduction ownership

Canonical reduction:

~~~text
Checker/Reduction/PrimitiveData
Checker/Reduction/PrimitiveNat
Checker/Reduction/KernelReductions
Checker/Reduction/WhnfCore
~~~

Primitive Nat reduction remains a semantic optimization path because it produces definitional reductions.

It is not in the same trust class as memoization.

Resource bounds such as max Nat size belong to checker limits/configuration.

Target-specific native execution remains outside this subtree under Runtime/Capability.

---

# 43. Projection ownership

Projection inference and reduction interact with:

- inductive metadata;
- WHNF;
- proof irrelevance;
- universe normalization.

Projection should be a first-class Checker module:

~~~text
Checker/Projection.lean
~~~

not an incidental public TypeChecker wrapper.

Permanent hardening cases should include:

- wrong structure name;
- out-of-range projection;
- Prop/imax projection restrictions;
- large projection index behavior.

---

# 44. Recursor ownership

Recursor subsystem remains:

~~~text
Checker/Recursor/Analysis.lean
Checker/Recursor/Reduction.lean
~~~

Analysis owns:

- major-family discovery;
- K-like behavior;
- structure conversion;
- recursor metadata interpretation.

Reduction owns:

- rule selection;
- iota computation;
- Quot/inductive interaction as appropriate.

Knot integrates recursor reduction with inference/WHNF/defeq.

---

# 45. DefEq ownership

Final DefEq tree remains close to the current one because the current decomposition is already excellent:

~~~text
Checker/DefEq/
    BinderSpines
    Quick
    DeltaStep
    LazyDelta
    Shortcuts
    FullShape
    FinalRules
~~~

Checker/Knot owns the public recursive entry.

Important design goal:

A reader should be able to inspect one short orchestration function and see the observable Lean 4.34 ordering.

Do not hide ordering behind generic rewrite registries.

---

# 46. Admission architecture

Admission is not a checker subroutine.

It is an environment transaction that calls the checker.

Final tree:

~~~text
Admission/
    Declaration/
    Quot/
    Inductive/
~~~

Admission invariants include:

- duplicate name rejection;
- universe parameter discipline;
- closedness;
- type is a Sort;
- value has declared type;
- theorem type is Prop;
- safety discipline;
- working-environment rules for recursive/partial declarations;
- final commit only after all checks pass.

---

# 47. Final inductive hierarchy

Unify ordinary, mutual and nested source physically:

~~~text
Admission/Inductive/
    Types
    Common
    Ordinary
    Mutual
    Nested
~~~

Do not merge them into one large file.

## 47.1 Common

Common owns only truly shared logic:

~~~text
parameter/header operations
occurrence analysis
positivity primitives
elimination policy
recursor result/rule validation helpers
~~~

Do not extract a "common" abstraction merely because two functions look similar.

Shared code should correspond to one shared Lean rule.

## 47.2 Ordinary

Ordinary owns:

~~~text
constructor shape
constructor admission
ordinary recursor construction
ordinary admission transaction
~~~

## 47.3 Mutual

Mutual owns:

~~~text
family analysis
shared header
motives/minors
cross-family recursive hypotheses
recursor construction
admission loops
bundle transaction
~~~

## 47.4 Nested

Nested preserves the current strong phase split:

~~~text
Types
ReservedNames
Rebase
Discover
Flatten
RestoreExpr
Restore
Validation
Commit
Admission
~~~

Nested calls the mutual admission transaction for the transformed bundle.

There must not be a second hidden "nested type checker".

---

# 48. API architecture

The final package should expose a small stable API surface.

~~~text
API/KernelContractV1.lean
API/Kernel.lean
API/Session.lean
API/Provider.lean
~~~

## 48.1 KernelContractV1

The contract should give the checked-session boundary a stable identity.

It should distinguish clearly between:

~~~text
unchecked/request state
checked result
admission result
provider capability
~~~

No status called "ready" should be able to mean both "constructed" and "kernel checked".

The contract should expose target identity:

~~~text
KernelContract-v1
Lean 4.34.0
commit 293d5d...
~~~

## 48.2 API/Kernel

Own public declaration admission.

## 48.3 API/Session

Own public infer/check/whnf/defeq session operations.

## 48.4 API/Provider

Own provider-neutral adapter contracts.

Provider code may:

- decode;
- encode;
- route calls;
- install declared capabilities.

Provider code may not:

- silently skip checking;
- fall back from rejection to another semantic implementation;
- patch generated JavaScript semantics;
- redefine defeq/reduction.

---

# 49. Self-host semantic root

SelfHost.lean must be a small root importing only canonical semantic/API modules.

It must not import:

~~~text
Compat
tests
benchmarks
frozen reference kernel
host adapters
generated JS
compiler frontend
~~~

A semantic-closure audit should compute the transitive import set.

Every file in that closure must pass the portable source profile.

This closure is the canonical source that may be translated through PSC/backend-ts.

---

# 50. Final test architecture

Recommended tree:

~~~text
test/KernelSelfHost/
|
+-- Fixtures/
|   +-- Core.lean
|   +-- Declarations.lean
|   +-- Inductive.lean
|   +-- Mutual.lean
|   '-- Nested.lean
|
+-- Conformance/
|   +-- Level.lean
|   +-- Inference.lean
|   +-- Reduction.lean
|   +-- Projection.lean
|   +-- Recursor.lean
|   +-- DefEq.lean
|   +-- Admission/
|   |   +-- Declaration.lean
|   |   +-- Quot.lean
|   |   +-- OrdinaryInductive.lean
|   |   +-- MutualInductive.lean
|   |   '-- NestedInductive.lean
|   '-- Main.lean
|
+-- Hardening/
|   +-- DefEqCacheOrder.lean
|   +-- PropProjection.lean
|   +-- RecursorRulePreservation.lean
|   +-- UniformOccurrences.lean
|   +-- NestedAuxNamespace.lean
|   +-- NestedDroppedParameters.lean
|   +-- NestedMultiFamilyRestore.lean
|   '-- NatResourceLimit.lean
|
+-- Oracle/
|   +-- Lean434.lean
|   +-- FrozenPSC1Kernel.lean
|   '-- Comparison.lean
|
+-- Runtime/
|   +-- CacheInvariant.lean
|   +-- EnvironmentIndexInvariant.lean
|   +-- SemanticProjectionInvariant.lean
|   '-- CapabilityBoundary.lean
|
+-- Architecture/
|   +-- SemanticClosure.lean
|   '-- SourceOwnership.lean
|
'-- Bench/
    +-- Harness.lean
    +-- Environment.lean
    +-- Cache.lean
    +-- Inference.lean
    +-- Whnf.lean
    +-- DefEq.lean
    +-- Recursor.lean
    +-- Inductive.lean
    +-- Mutual.lean
    +-- Nested.lean
    '-- Main.lean
~~~

Main executables should be thin aggregators.

---

# 51. Evidence hierarchy

Every high-risk rule should have evidence from several levels.

Recommended order:

~~~text
A. exact Lean 4.34 source locator

B. official Lean 4.34 differential result

C. PSKernel portable result

D. frozen PSC1Kernel differential result

E. direct invariant test where representation matters

F. adversarial hardening fixture

G. optional third-party checker comparison
~~~

Official Lean is the primary external behavior oracle.

PSC1Kernel remains useful as a regression oracle.

Independent checkers are corroborating evidence, not compatibility authority.

---

# 52. Hierarchical rule registry

Keep the current 34-row compatibility matrix.

It is useful as a product/release capability index.

Add a finer machine-readable registry for high-risk implementation rules.

Suggested file:

~~~text
LEAN_4_34_KERNEL_RULES.json
~~~

Suggested fields:

~~~text
id
parentCompatibilityId
area
statement
leanCommit
leanLocator
pskernelModule
pskernelSymbol
trustClass

tests:
    positive
    negative
    adversarial

oracles:
    officialLean
    frozenPSC1
    invariant

status
~~~

Example nested children:

~~~text
PSK-NESTED-RESERVED-NAMESPACE
PSK-NESTED-UNIFORM-OCCURRENCE
PSK-NESTED-DISCOVERY
PSK-NESTED-AUX-FRESHNESS
PSK-NESTED-FLATTEN
PSK-NESTED-DROPPED-PARAM-CHECK
PSK-NESTED-RESTORE-EXPR
PSK-NESTED-FULL-REGISTRY
PSK-NESTED-RESTORED-CTOR-CHECK
PSK-NESTED-RESTORED-REC-TYPE-CHECK
PSK-NESTED-RESTORED-RULE-CHECK
PSK-NESTED-RULE-TYPE-PRESERVATION
PSK-NESTED-NO-AUX-LEAK
~~~

The generated KERNEL_RULE_REFERENCE can include both top-level and subrule views.

---

# 53. Divergence registry

Add:

~~~text
LEAN_4_34_DIVERGENCES.md
~~~

Policy:

~~~text
default: no divergence

any known intentional difference:
    documented
    justified
    tested
    linked to target upgrade/migration plan
~~~

This mirrors a useful practice from lean4lean.

A hidden divergence is a bug.

---

# 54. Architecture tests

CI should verify architecture itself.

Required automated checks:

## 54.1 Import fence

Reject upward imports.

## 54.2 Semantic closure

Compute SelfHost transitive imports.

Require only canonical portable modules.

## 54.3 No reference dependency

Canonical semantic code must not import PSC1Kernel reference code.

## 54.4 No test dependency

Semantic source must not import test/benchmark modules.

## 54.5 No Compat dependency

SelfHost closure must contain no compatibility shim.

## 54.6 Unique semantic ownership

Every hierarchical kernel rule maps to one canonical implementation owner.

Multiple helper symbols are fine.

Multiple semantic implementations are not.

## 54.7 Target pin consistency

Architecture manifest, compatibility matrix, conformance matrix and reference document must name the same Lean target.

---

# 55. Documentation architecture

Recommended responsibilities:

## PSKERNEL_REFERENCE.md

Human canonical architecture reference.

Contains:

- theory overview;
- current architecture audit;
- final target architecture;
- dependency/trust laws;
- migration map;
- scoring.

## PSKERNEL_SELFHOST_ARCHITECTURE.md

Short normative anti-drift policy.

Avoid duplicating long explanatory material.

## KERNEL_THEORY.md

Algorithm and theory explanation.

## KERNEL_RULE_REFERENCE.md

Generated source/rule/test index.

## DEVELOPMENT_PLAN.md

Current work state only.

## PERFORMANCE_BASELINE.md

Measurements and performance conclusions only.

## Machine JSON

Compatibility, conformance, architecture and fine-grained rule state.

Documentation should point rather than duplicate.

---

# 56. Performance architecture

The permanent optimization law should be:

~~~text
measure first
identify exact cost
change one non-semantic representation/policy when possible
preserve Lean algorithmic order
run semantic + portable gates
remeasure
keep or revert
~~~

Classes of performance work:

## Safe-by-design acceleration candidates

~~~text
hash indexes
small-list -> trie promotion
cache representation
cache admission policy
structural hash metadata
node metadata
sharing/interning when proven useful
~~~

## Semantically sensitive optimization

~~~text
reduction shortcut
infer-only substitution for checked work
defeq ordering change
native evaluation
recursor shortcut
~~~

These require a proof/invariant argument plus differential coverage.

The recent validated-old-rule optimization is the right pattern:

~~~text
full validity established earlier
only type recovery needed later
fast path explicitly named for that invariant
new/restored term still fully checked where required
~~~

---

# 57. Provider readiness and deployment authority

Core semantic completeness and deployment authority are separate milestones.

The self-host kernel may be:

~~~text
rule-complete
portable
self-hosted
conformance-green
~~~

while the product still uses another checker as default authority.

Promotion to provider authority should require:

~~~text
stable KernelContract-v1
canonical declaration adapter
dual-check mode
official Lean parity corpus
no fallback-on-reject
provider capability audit
JS/native semantic corpus parity
explicit promotion decision
~~~

Do not equate self-host fixed point with provider authority.

---

# 58. Migration strategy

Do not execute the final architecture as one giant refactor.

Use small checkpoints.

## Phase M0 - pin baseline

Require green:

~~~text
compatibility 34/34
conformance 34/34
PSC1 check
canonical .ps recheck
Lean native build
foundation differential
nested multi-family regression
benchmark baseline
~~~

## Phase M1 - split tests and benches

No semantic source move yet.

Create subsystem suites and thin Main aggregators.

Delete temporary diagnostic code already represented by permanent regressions.

## Phase M2 - add architecture manifest and import fence

Describe current architecture first.

Make violations visible before moving files.

## Phase M3 - canonical Core and Runtime paths

Move only modules with no algorithmic edits.

Temporary old-path reexports allowed.

## Phase M4 - canonical Checker tree

Move:

~~~text
context
state
reduction
projection
inference
recursor
defeq
~~~

without changing bodies.

## Phase M5 - introduce Checker/Knot

Centralize existing recursive callback wiring.

Do not redesign algorithms in the same commit.

## Phase M6 - canonical Admission tree

Move declaration/Quot/inductive admission.

## Phase M7 - unify Inductive hierarchy

Place Ordinary/Mutual/Nested under one owner.

Keep phase files separate.

## Phase M8 - isolate cache policy and trusted capability

Move policy/capability code without semantic change.

## Phase M9 - stable API contract

Expose KernelContract-v1 and provider-neutral session/admission surface.

## Phase M10 - oracle and fine-grained rule expansion

Add official Lean fixtures and hierarchical rule registry.

## Phase M11 - remove Compat

Only after no canonical consumer imports old paths.

## Phase M12 - optional environment representation split

Do this only if still valuable after the import cleanup.

Treat as a separate semantic/runtime representation project.

---

# 59. Migration discipline

Each migration commit should be exactly one of:

~~~text
move/rename only
import-wiring only
documentation only
test split only
architecture gate only
semantic change only
performance change only
~~~

Avoid:

~~~text
move + semantic fix + optimization
~~~

in one commit.

This dramatically improves auditability for a proof kernel.

---

# 60. Permanent invariants

## INV-01 One semantic source

There is one maintained semantic kernel implementation.

## INV-02 Exact Lean target

Semantic claims name Lean 4.34.0 and the pinned commit.

## INV-03 Fail closed

Failure, unsupported input and resource exhaustion reject.

## INV-04 No cache authority

A cache can reuse a prior fact but cannot manufacture a fact.

## INV-05 DefEq pair facts are non-transitive

Never use successful-pair transitive closure.

## INV-06 Semantic environment is explicit

Logical environment identity is independent of cache/index representation.

## INV-07 Acceleration and trusted capability are different trust classes

Hashing is not native execution.

## INV-08 Infer-only has a validity precondition

It may not silently replace checking.

## INV-09 Checker recursion knot has one owner

All infer/whnf/defeq/recursor recursive wiring is centralized.

## INV-10 Admission is transactional

Nothing reaches the returned environment unless required checks complete.

## INV-11 Nested restoration uses the full family registry

Pending iteration state cannot shrink restoration knowledge.

## INV-12 Restored nested outputs are validated

Constructor types, recursor types and rule RHSs are rechecked according to Lean 4.34 behavior.

## INV-13 Internal nested declarations do not leak

Final user environment contains no generated nested implementation family.

## INV-14 Runtime index is derivative

Environment index can be rebuilt from semantic declarations.

## INV-15 Native reduction is explicit TCB extension

Provider use is visible and target-specific.

## INV-16 Canonical source imports no Compat

Compatibility shims are downstream migration artifacts.

## INV-17 Canonical source imports no reference kernel

Differential oracle code stays in tests.

## INV-18 Generated JS is never semantically patched

Fix source and regenerate.

## INV-19 Fixed point is evidence, not proof

Generated reproduction is a release/bootstrap receipt.

## INV-20 Official Lean remains primary compatibility authority

Independent checkers and frozen references are secondary evidence.

---

# 61. Final target score

Strict weighted score:

| Dimension | Weight | Final score |
| --- | ---: | ---: |
| Trust boundary and semantic fidelity | 15% | 9.90 |
| Checker decomposition and recursion-knot wiring | 13% | 9.90 |
| Dependency layering and machine enforcement | 12% | 9.95 |
| Semantics / acceleration / trusted-capability separation | 10% | 9.90 |
| Inductive subsystem coherence | 10% | 9.85 |
| PSC1 portability and self-host closure | 10% | 9.90 |
| Conformance and oracle independence | 10% | 9.90 |
| API/provider boundary | 7% | 9.85 |
| Test/benchmark architecture | 7% | 9.95 |
| Migration safety and maintainability | 6% | 9.90 |

Weighted result:

~~~text
9.901 / 10
rounded architecture score: 9.90 / 10
~~~

Why it is not 10:

1. the target deliberately remains an executable compatibility kernel, not a fully formally verified implementation;
2. PSC1 portability constrains some abstraction choices;
3. exact Lean compatibility necessarily preserves some target-specific implementation complexity;
4. provider/native behavior in 4.34 has an unavoidable extended trust boundary;
5. future performance work can reveal representation pressures not visible from architecture review alone.

Those are acceptable tradeoffs.

---

# 62. What would be required for a meaningful 10/10 claim

A genuine 10/10 should not be awarded for rearranging folders.

It would require evidence substantially stronger than this project currently targets, for example:

~~~text
machine-enforced architecture
+
independent official differential corpus
+
fine-grained soundness-rule registry
+
formal refinement/simulation proof
+
verified or eliminated trusted native capability
+
fully specified stable external contract
+
production provider parity
~~~

PSKernel does not need that scope to be production-ready.

The 9.90 target is intentionally ambitious but compatible with the project's executable/self-hosting goals.

---

# 63. Recommended implementation order from this point

Highest-value architectural work:

~~~text
1. split test/benchmark monoliths
2. create PSKERNEL_ARCHITECTURE.json
3. add import-fence + semantic-closure CI
4. establish canonical Checker directory
5. establish Checker/Ops + Checker/Knot ownership
6. move cache policy under Runtime/Acceleration
7. isolate Lean434 native reduction under Runtime/Capability
8. unify all inductive admission under Admission/Inductive
9. establish API/KernelContractV1
10. add fine-grained Lean 4.34 hardening rule registry
11. increase official-Lean direct differential coverage
12. remove migration shims
~~~

Do not start with environment representation changes.

Do not mix architecture moves with new performance algorithms.

---

# 64. Canonical reading order after migration

Recommended learning path:

~~~text
1. Core/Name
2. Core/Level
3. Core/Expr
4. Core/Substitution/*
5. Core/Declaration
6. Core/LocalContext

7. Environment/Semantic
8. Environment/Environment
9. Checker/Context
10. Checker/State

11. Checker/Reduction/*
12. Checker/Projection
13. Checker/Inference/*
14. Checker/Recursor/*
15. Checker/DefEq/*
16. Checker/Ops
17. Checker/Knot
18. Checker/Session

19. Admission/Declaration/*
20. Admission/Quot/*
21. Admission/Inductive/Common/*
22. Admission/Inductive/Ordinary/*
23. Admission/Inductive/Mutual/*
24. Admission/Inductive/Nested/*

25. API/KernelContractV1
26. API/Kernel
27. API/Session
28. API/Provider

29. Runtime/Acceleration internals
30. Runtime/Capability/Lean434NativeReduction

31. SelfHost semantic root
~~~

Compatibility shims are intentionally absent.

---

# 65. Source references

## 65.1 Lean 4.34 exact kernel source

Pinned tree:

https://github.com/leanprover/lean4/tree/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel

Key sources:

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/type_checker.cpp

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/type_checker.h

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/inductive.cpp

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/environment.cpp

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/quot.cpp

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/expr.h

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/level.h

## 65.2 Lean theory documentation

The live reference is useful for theory but may document a newer Lean release than PSKernel's target:

https://lean-lang.org/doc/reference/latest/The-Type-System/

https://lean-lang.org/doc/reference/latest/The-Type-System/Universes/

https://lean-lang.org/doc/reference/latest/The-Type-System/Functions/

https://lean-lang.org/doc/reference/latest/The-Type-System/Inductive-Types/

https://lean-lang.org/doc/reference/latest/The-Type-System/Quotients/

https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/

https://lean-lang.org/doc/reference/latest/ValidatingProofs/

## 65.3 Lean 4.34 hardening

https://lean-lang.org/doc/reference/latest/releases/v4.34.0/

Important architecture-relevant changes:

~~~text
#14806  pair-based defeq cache
#14807  isProp requires a Sort
#14843  corresponding inductive check
#14808  generated recursor/rule validation
#14582  uniform inductive occurrence hardening
#14849  Nat size bound
~~~

## 65.4 Future-version architecture signal

Lean 4.35 removes Lean.reduceBool / Lean.reduceNat native kernel support.

This does not change PSKernel 4.34 semantics.

It supports isolating the 4.34 native route as a target-specific trusted capability.

## 65.5 lean4lean

Repository:

https://github.com/digama0/lean4lean

Paper:

https://arxiv.org/abs/2403.14064

Particularly relevant:

~~~text
Lean4Lean/TypeChecker.lean
Lean4Lean/Theory/
Lean4Lean/Verify/
Lean4Lean/Tests/KernelHardening.lean
divergences.md
~~~

## 65.6 ConLeche

Repository:

https://github.com/leanprover/con-leche

Architecture overview:

https://github.com/leanprover/con-leche/blob/master/OVERVIEW.md

Particularly relevant lessons:

~~~text
explicit pure/cached checker boundaries
CheckerOps-style operation interface
machine import fence
inductive subsystem decomposition
hard separation between implementation and proof tiers
~~~

PSKernel adopts only the architecture lessons that fit its one-semantic-source and PSC1-portable goals.

---

# 66. Final architectural rule

The final architecture can be summarized in one statement:

~~~text
Make the dependency graph express the trust model.

Core defines the objects.
Environment stores semantic declarations.
Checker implements Lean's judgments.
Admission performs checked environment transactions.
API exposes only checked contracts.

Acceleration may make the same judgment faster.
Trusted capabilities must be explicit.
Neither may become a hidden alternate route to acceptance.
~~~

That is the architecture PSKernel should converge toward.
