# PSKernel Reference

> Architecture, Lean 4.34 theory mapping, current implementation audit, and target structure.

## 0. Document status

This document is the human-oriented reference for the portable self-host PSKernel architecture.

It combines:

- the relevant Lean 4.34 kernel theory;
- the exact Lean 4.34 implementation architecture used as compatibility authority;
- the current PSKernel self-host architecture and source layout;
- an explicit architectural evaluation;
- a proposed target source/test structure;
- migration rules that preserve semantics and PSC1 self-hostability.

This document is descriptive and architectural. Machine-readable semantic completeness remains authoritative in:

- LEAN_4_34_COMPATIBILITY.json
- LEAN_4_34_CONFORMANCE.json

Normative anti-drift rules remain in:

- PSKERNEL_SELFHOST_ARCHITECTURE.md

The active development roadmap remains in:

- DEVELOPMENT_PLAN.md

The theory reading guide remains in:

- KERNEL_THEORY.md

This reference does not replace those machine gates. It explains how they fit together and records the recommended long-term architecture.

### Audited revisions

PSKernel branch:

~~~text
psc2/psc1kernel-selfhost-portable
~~~

PSKernel audited head:

~~~text
9611405267dbdaa66812e4dfa7642fc799d2e758
~~~

Lean semantic compatibility target:

~~~text
Lean 4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

Research date:

~~~text
2026-10-05
~~~

Lean 4.34.1 exists as a later patch release, but this project is intentionally pinned to Lean 4.34.0. The target must not change implicitly while reorganizing PSKernel.

---

# 1. Executive judgment

PSKernel's current architecture is good and materially better than the older flat PSC1Kernel structure.

Its strongest architectural properties are:

1. one semantic source of truth;
2. exact Lean 4.34 target pinning;
3. explicit fail-closed checking;
4. a clean conceptual distinction between semantic algorithms and non-semantic accelerators;
5. PSC1 portable-source self-hostability;
6. explicit inference, WHNF, recursor, definitional-equality and admission pipelines;
7. unusually good nested-inductive decomposition;
8. rule-to-source-to-test traceability;
9. frequent direct comparison with Lean behavior;
10. current 34/34 declared compatibility and conformance coverage.

However, the physical file/dependency structure is not yet as clean as the semantic design.

The main architecture debt is:

1. the top-level directory mixes foundational data, real implementation modules, public integration modules and compatibility umbrellas;
2. Theory modules occasionally depend upward through TypeChecker integration modules, so the physical import graph does not enforce the conceptual theory/runtime layering;
3. the central recursive checker knot is distributed across several TypeChecker*.lean files rather than being named explicitly as one engine boundary;
4. ordinary, mutual and nested inductive admission are physically separated into inconsistent top-level shapes even though they are one conceptual subsystem;
5. runtime cache policy is partly located inside theory-facing inference helpers;
6. Environment physically contains runtime index/provider state, so the semantic/runtime separation is an invariant rather than a strict type-level/module-level boundary;
7. the 34-rule matrix is excellent as a release checklist but too coarse to describe high-risk internal algorithms such as inductive and nested admission;
8. much differential coverage uses the frozen PSC1Kernel reference, which is valuable but not sufficiently independent by itself because the self-host implementation was derived from that implementation;
9. the foundation test and benchmark executables are now large monoliths;
10. the source still shows migration-era compatibility layers in the primary reading path.

## 1.1 Current score

Weighted architectural score:

| Area | Score | Assessment |
| --- | ---: | --- |
| Lean 4.34 semantic fidelity and trust discipline | 9.3/10 | Strong |
| PSC1 self-host portability | 9.6/10 | Excellent |
| Theory decomposition and readability | 8.9/10 | Strong |
| Runtime/semantic separation | 8.7/10 | Strong conceptually, imperfect physically |
| Dependency layering | 7.5/10 | Main source-layout weakness |
| File/folder coherence | 7.8/10 | Good but still migration-shaped |
| Conformance/evidence architecture | 8.5/10 | Strong, but oracle independence and subrule granularity should improve |
| Performance architecture | 8.5/10 | Profiling-driven and semantics-preserving |
| Test/benchmark organization | 7.0/10 | Correct but too monolithic |
| Deployment/provider readiness | 7.7/10 | Core is mature; provider authority gate is intentionally not yet promoted |

### Overall: 8.7 / 10

This is not a 9.8 architecture yet.

The reason is not missing core functionality. The reason is that a production proof kernel benefits from an import graph and test structure whose correctness boundaries are obvious mechanically, not only explained in documentation.

A realistic target after a semantics-preserving reorganization is approximately 9.4-9.6/10.

---

# 2. What the Lean kernel actually is

Lean separates a large frontend/compiler ecosystem from a small trusted proof-checking core.

The kernel consumes elaborated core expressions and declarations. Parsing, syntax macros, tactics, typeclass search and most elaboration are outside the kernel trust boundary.

The kernel's conceptual job is approximately:

~~~text
Environment
    +
core Declaration
    |
    v
validate declaration
    |
    +-- reject
    |
    '-- accept -> new Environment
~~~

The central logical judgments are:

~~~text
infer  : Γ |- e : A

whnf   : e -->* weak-head form

defeq  : Γ |- A <=> B

admit  : Γ + declaration is a valid environment extension
~~~

These judgments are mutually dependent at the algorithmic level.

Inference needs conversion.
Conversion needs inference and reduction.
Reduction may need recursor metadata and inference.
Admission invokes all of them.

This mutual dependency is one reason Lean's official C++ type_checker is a tightly integrated class rather than a collection of completely independent functions.

---

# 3. Lean 4 core theory relevant to PSKernel

Lean's core terms form a dependently typed lambda calculus extended with universes, constants, inductive types, primitive projections, literals, metadata and quotient primitives.

The expression kinds in Lean 4.34 are:

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

Metavariables are not accepted by the kernel type checker as checked proof terms.

## 3.1 Universes

Lean universe levels are built from:

~~~text
0
succ u
max u v
imax u v
parameter
metavariable
~~~

For kernel-checked declarations, level parameters must obey the declaration's universe context.

Important architectural consequence:

Universe equality is semantic normalization/equivalence, not text or constructor equality.

PSKernel correctly gives levels their own foundational module instead of treating them as a minor expression helper.

## 3.2 Dependent functions

Lean uses dependent Pi types.

The core rules include:

~~~text
Sort u : Sort (u + 1)

Pi x : A, B : Sort (imax level(A) level(B))

fun x : A => b : Pi x : A, type(b)

f a : B[a/x]
~~~

Prop is Sort 0 and is impredicative.

## 3.3 Proof irrelevance

Lean has definitional proof irrelevance.

When two expressions are proofs of definitionally equal propositions, the proof terms are definitionally equal.

This is part of kernel definitional equality, not a compiler erasure optimization.

## 3.4 Reduction

Definitional equality includes computation through:

~~~text
beta   function application
delta  definition unfolding
iota   recursor computation
zeta   let reduction
quotient computation
~~~

It also includes function eta and restricted structure eta.

Lean does not simply normalize both sides to full normal form and compare them.

The observable algorithm is deliberately staged and incomplete.

## 3.5 Algorithmic definitional equality is not transitive

This point is critical.

The Lean reference explicitly states that its mechanically implemented definitional-equality procedure is reflexive and symmetric but not transitive.

Lean 4.34 fixed a soundness issue caused by using a union-find structure for successful conversion queries. A union-find computes a transitive closure; that is invalid for Lean's incomplete algorithmic equality procedure.

The 4.34 kernel uses plain successful and failed expression-pair caches instead.

PSKernel's decision to model success/failure as pair sets rather than equivalence classes is therefore a soundness-relevant architectural rule, not merely a performance choice.

## 3.6 Inductive types

Inductive declarations extend the kernel environment with:

- inductive type information;
- constructor information;
- generated recursor information;
- computation rules.

The kernel checks, among other things:

- parameter and index shape;
- constructor well-typedness;
- recursive occurrences;
- strict positivity;
- universe constraints;
- elimination restrictions;
- generated recursor type;
- recursor computation rules.

Lean 4.34 specifically added stronger defensive recursor validation so generated computation rules are checked for type preservation, not merely checked for having some type.

## 3.7 Mutual inductives

Mutual inductive groups allow recursive occurrences across multiple simultaneously introduced families.

Architecturally this means recursor generation requires:

- multiple motives;
- coordinated minor premises;
- recursive hypotheses across family boundaries;
- one shared checked admission transaction.

Mutual admission is not just a loop over ordinary inductives.

## 3.8 Nested inductives

Nested inductive types contain recursive occurrences underneath previously declared inductive type constructors.

Lean translates supported nested declarations to an auxiliary mutual inductive declaration.

The important conceptual pipeline is:

~~~text
original nested declaration
        |
        v
discover nested occurrences
        |
        v
create auxiliary families
        |
        v
rewrite/flatten declaration
        |
        v
ordinary/mutual inductive admission
        |
        v
restore user-facing constructor/recursor expressions
        |
        v
re-check restored material
        |
        v
commit without leaking auxiliary declarations
~~~

Lean 4.34 also rejects user declarations that reach directly into the reserved _nested namespace.

PSKernel's current nested architecture closely follows this pipeline.

## 3.9 Quotients

Quot is a kernel primitive, with built-in declarations for the quotient former and its introduction/elimination principles.

Quot.lift/Quot.ind participate in kernel reduction.

It is therefore architecturally correct for PSKernel to keep quotient admission separate from ordinary definition admission while keeping quotient computation in the reduction subsystem.

---

# 4. Lean 4.34 official kernel source architecture

At the pinned Lean 4.34 commit, src/kernel contains 36 C++/header source files, approximately 344 KB of C++/header source.

That number should not be compared directly to Lean source byte counts as a complexity metric. It is useful only to understand source concentration.

The largest kernel implementation files include:

| Lean file | Approx. size | Main responsibility |
| --- | ---: | --- |
| src/kernel/inductive.cpp | 69 KB | ordinary/mutual/nested inductive checking, recursor construction/restoration |
| src/kernel/type_checker.cpp | 54 KB | inference, WHNF, defeq, projections, primitive/recursor reduction |
| src/kernel/declaration.h | 28 KB | declaration/constant metadata |
| src/kernel/expr.h | 23 KB | expression representation/API |
| src/kernel/level.cpp | 18 KB | universe level algorithms |
| src/kernel/expr.cpp | 18 KB | expression implementation |
| src/kernel/declaration.cpp | 15 KB | declaration implementation |
| src/kernel/environment.cpp | 12 KB | environment admission dispatch |
| src/kernel/instantiate.cpp | 11 KB | substitution/instantiation |

The complete kernel directory also contains focused infrastructure:

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

## 4.1 Lean's type_checker state

Lean 4.34's type checker state contains:

~~~text
environment
fresh-name generator
infer cache[checked/infer-only]
WHNF-core cache
WHNF cache
successful defeq pair set
failed defeq pair set
unfold cache
~~~

This is very close to the current PSKernel CheckerState design.

This similarity is good: the PSKernel state model is aligned with the actual observable Lean algorithm rather than being invented independently.

## 4.2 Lean inference

Lean has separate checked and infer-only modes.

Checked application:

~~~text
infer/check function
ensure Pi
infer/check argument
compare argument type to Pi domain with defeq
instantiate codomain
~~~

Infer-only application is optimized over the whole application spine and avoids revalidating arguments.

PSKernel's current checked/infer-only distinction is architecturally faithful.

## 4.3 Lean WHNF

Lean's public WHNF loop is approximately:

~~~text
whnf_core
    |
    +-- native reduction?
    |
    +-- Nat primitive reduction?
    |
    +-- unfold definition?
    |      |
    |      '-- loop
    |
    '-- return
~~~

PSKernel's current split between WhnfCore and the public WHNF pipeline mirrors this well.

## 4.4 Lean defeq orchestration

The Lean 4.34 source performs, in broad order:

~~~text
quick equality / success cache
reflection shortcut
cheap/core WHNF
proof irrelevance
lazy delta
same constant / fvar shortcuts
projection-sensitive comparison
full projection WHNF
application congruence
function eta
structure eta
string literal expansion
unit-like equality
failure
~~~

PSKernel's DefEq decomposition is one of the strongest parts of its current architecture because it exposes this order more clearly than the official monolithic C++ file.

## 4.5 Lean declaration admission

environment.cpp dispatches declarations by kind:

~~~text
Axiom
Definition
Theorem
Opaque
MutualDefinition
Quot
Inductive
~~~

Declaration admission is a transaction around the type checker.

Theorem admission additionally requires the declared type to be a proposition.

Unsafe/partial mutual definitions are installed as a block before bodies are checked, so recursive references resolve in the working environment.

PSKernel's Admission layer correctly treats environment extension as a separate concern from expression inference.

## 4.6 Lean nested restoration hardening

Lean's nested path:

1. rejects free variables/metavariables and reserved auxiliary names;
2. validates uniform occurrences;
3. creates the auxiliary declaration;
4. admits the transformed declaration;
5. restores recursors and constructors into a clean environment;
6. checks nested applications whose parametric arguments were erased by translation;
7. re-checks restored constructor types;
8. re-checks restored recursor types and rule RHSs.

The current PSKernel multi-family restoration fix matches an important invariant visible in this architecture: restoration must retain the complete auxiliary mapping even while iterating through a shrinking work queue.

---

# 5. Useful independent checker architecture lessons

PSKernel should not copy another checker blindly, but independent Lean checker projects reveal useful design patterns.

## 5.1 lean4lean

lean4lean separates:

~~~text
implementation
Theory
Verify
~~~

Its implementation is intentionally close to Lean's kernel algorithm, while Theory contains an abstract formalization and Verify connects implementation to theory.

Useful lesson for PSKernel:

- keep executable checker organization distinct from the mathematical description;
- do not make the word Theory carry both meanings.

PSKernel does not need to adopt lean4lean's formal-verification scope to benefit from this naming/layering distinction.

## 5.2 ConLeche

ConLeche uses strong import-layer rules separating:

~~~text
Kernel
Cached
Frontend
Semantics
Model
Verify
~~~

It explicitly tests/enforces layering.

Useful lesson for PSKernel:

- architecture documentation is weaker than an import fence;
- non-semantic acceleration deserves an explicit dependency contract;
- a pure conceptual checker and a cached executable checker can be separated if verification requires it.

PSKernel should not duplicate its semantic checker into pure/cached implementations merely to imitate ConLeche. One semantic source remains the better fit for PSKernel. The useful idea is the enforceable layer boundary.

---

# 6. Current PSKernel self-host architecture

Current source root:

~~~text
packages/pskernel-selfhost/src/Ps/KernelSelfHost/
~~~

At the audited head there are approximately:

~~~text
70 Lean source files
~795 KB source
~~~

Breakdown:

~~~text
Top-level files : 24
Runtime files   : 3
Theory files    : 43
~~~

Theory subtrees:

| Subsystem | Files | Approx. source bytes |
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

This is more decomposed than Lean's C++ kernel.

That is appropriate for PSKernel's goals: portability, explainability and source-level auditing matter more than minimizing file count.

---

# 7. Current PSKernel source map

The current conceptual architecture is:

~~~text
Core data
  Name
  Level
  Expr
  substitution
  Declaration
  LocalContext
  Environment

Checker machinery
  CheckerState
  TypeCheckerBase
  WHNF
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

Runtime acceleration
  Cache
  EnvironmentIndex
  NativeReduction

Root/API/compatibility
  Kernel
  Instantiate
  TypeCheckerPrimitives
  TypeCheckerDefEqSupport
  Inductive / InductiveAdmission
  MutualInductive
  NestedInductive
  Quot
  SelfHost
~~~

## 7.1 Core representation

Current foundational files:

~~~text
Name.lean
Level.lean
Expr.lean

Theory/Substitution/
  ListOps.lean
  Lift.lean
  Instantiate.lean
  Beta.lean
  Abstract.lean

Declaration.lean
LocalContext.lean
Environment.lean
~~~

This layer is conceptually sound.

## 7.2 Environment

PsKernelEnvironment currently contains:

~~~text
constants
index
quotInitialized
runtime.nativeEvaluator
~~~

Semantically:

~~~text
constants = authoritative declaration history
index     = lookup accelerator only
~~~

This invariant is good, but the representation physically mixes semantic state and runtime acceleration.

That is acceptable today, but it means semantic/runtime separation is enforced by discipline and tests rather than by the type/module structure.

## 7.3 Checker context

PsKernelCheckerContext contains:

~~~text
environment
localContext
levelParams
safety
eagerReduce
nativeEvaluator
maxRecDepth
maxNatSize
recDepth
~~~

This is a faithful executable analogue of Lean's checker operating context.

## 7.4 Checker state

PsKernelCheckerState contains:

~~~text
nextFresh
inferOnly
checkedInfer
whnfCore
whnf
unfold
success
failure
~~~

The cache structure is aligned with Lean 4.34.

In particular, success/failure are pair sets and not a transitive equivalence manager.

## 7.5 Checker session

CheckerSession packages:

~~~text
context + state
~~~

and exposes state-threading operations:

~~~text
SessionWhnf
SessionInfer
SessionCheck
SessionEnsureSort
SessionIsProp
SessionIsDefEq
~~~

This is a strong API boundary.

The recent nested-rule session threading change is architecturally correct even though it produced little measurable speedup in the current benchmark. Returning the updated checker state is still the right abstraction.

---

# 8. Current inference architecture

Current path:

~~~text
Theory/Inference/Helpers.lean
        |
        v
Theory/Inference/Core.lean
        |
        v
TypeCheckerInfer.lean
~~~

The semantic distinction between checked inference and infer-only inference is explicit.

Strengths:

- mirrors Lean 4.34 behavior;
- separates syntax-directed cases from public entry points;
- makes caching policy explicit;
- preserves checked-application node ordering.

Weakness:

Theory/Inference/Helpers.lean imports TypeCheckerProjection.lean, which imports TypeCheckerWhnf.lean.

This means a Theory module depends upward into the TypeChecker integration layer.

That is not a semantic bug, but it is an architectural inversion.

The file tree says:

~~~text
Theory -> TypeChecker -> Theory
~~~

conceptually, even if the actual import graph remains acyclic.

A better structure would place Projection, Inference and WHNF in one explicit Checker layer and reserve API wrappers for modules above them.

---

# 9. Current reduction architecture

Current reduction modules:

~~~text
Theory/Reduction/
  PrimitiveData.lean
  PrimitiveNat.lean
  KernelReductions.lean
  WhnfCore.lean

TypeCheckerPrimitives.lean
TypeCheckerWhnf.lean
TypeCheckerProjection.lean
~~~

Strengths:

- WHNF core is distinct from post-core unfolding/native/Nat pipeline;
- primitive operations are isolated;
- observable Lean ordering is documented;
- projection handling is explicit.

Structural issue:

The Theory/TypeChecker naming split suggests two layers, but the modules actually form one executable checker subsystem.

Recommendation:

Move these under one Checker namespace/folder and keep compatibility modules outside the canonical reading path.

---

# 10. Current recursor architecture

Current path:

~~~text
Theory/Recursor/Analysis.lean
        |
        v
Theory/Recursor/Reduction.lean
        |
        v
TypeCheckerRecursor.lean
~~~

This is good.

It gives recursor computation its own semantic subsystem instead of hiding all iota logic inside WHNF.

The remaining architectural opportunity is naming: TypeCheckerRecursor is not really a separate conceptual layer; it is the integration point that ties the checker knot.

---

# 11. Current definitional-equality architecture

Current path:

~~~text
Theory/DefEq/
  BinderSpines.lean
  Quick.lean
  DeltaStep.lean
  LazyDelta.lean
  FinalRules.lean
  Shortcuts.lean
  FullShape.lean

TypeCheckerDefEqSupport.lean
TypeCheckerDefEq.lean
~~~

This is the best-organized major subsystem.

It improves on the official Lean source for auditability because Lean places most of the algorithm in type_checker.cpp.

Strengths:

- observable algorithmic order is clear;
- quick structural rules are separated;
- lazy delta has a named module;
- final eta/string/unit/proof rules are not mixed with basic cache logic;
- projection-sensitive behavior is explicit;
- non-transitive cache policy is visible.

Improvement:

TypeCheckerDefEqSupport.lean is a compatibility umbrella and should not appear in the canonical architecture.

The canonical implementation should live entirely under Checker/DefEq, with one Engine/DefEq entry point.

---

# 12. Current admission architecture

Ordinary declaration admission:

~~~text
Theory/Admission/Validation.lean
Theory/Admission/Declarations.lean
Kernel.lean
~~~

This is clean.

The top-level Kernel.lean is only an umbrella, which is acceptable if clearly labeled as API/Compat rather than mixed with implementation files.

---

# 13. Current Quot architecture

~~~text
Theory/Quot/Bootstrap.lean
Theory/Quot/Admission.lean
Quot.lean
~~~

This is appropriately small and conceptually clear.

Quot.lean is an umbrella.

Recommended long-term structure should keep quotient admission under Admission/Quot and quotient reduction under Checker/Reduction.

---

# 14. Current inductive architecture

The current physical split is inconsistent:

~~~text
Inductive.lean
Theory/Inductive/*
InductiveAdmission.lean

Theory/Mutual/*
MutualInductive.lean

Theory/Nested/*
NestedInductive.lean
~~~

Inductive.lean is not merely an umbrella: it defines shared ordinary-inductive declaration/shape structures.

InductiveAdmission.lean contains actual top-level admission implementation.

MutualInductive.lean and NestedInductive.lean are umbrellas.

This inconsistency is one of the clearest migration-era structural artifacts.

All three belong under one canonical Inductive subsystem.

---

# 15. Current nested architecture

Current nested pipeline:

~~~text
Theory/Nested/Types.lean
Theory/Nested/ReservedNames.lean
Theory/Nested/Rebase.lean
Theory/Nested/Discover.lean
Theory/Nested/Flatten.lean
Theory/Nested/RestoreExpr.lean
Theory/Nested/Restore.lean
Theory/Nested/Validation.lean
Theory/Nested/Commit.lean
Theory/Nested/Admission.lean
~~~

This decomposition is excellent.

It directly represents the algorithm's phases.

The recently discovered multi-family bug also validates this decomposition: the defect could be localized to restoration state rather than being hidden inside a single huge inductive function.

The critical invariant is now:

~~~text
pending
  = structurally decreasing work queue

allFamilies
  = invariant complete restoration registry
~~~

Every restored expression must see allFamilies, including later auxiliary recursors that may refer to earlier auxiliary families.

This invariant belongs in the permanent architecture reference and conformance suite.

---

# 16. Runtime architecture

Current runtime modules:

~~~text
Runtime/Cache.lean
Runtime/EnvironmentIndex.lean
Runtime/NativeReduction.lean
~~~

The conceptual contract is excellent:

~~~text
runtime may accelerate a judgment
runtime may not create a semantic fact
~~~

The environment index narrows lookup.
Full structural name equality resolves collisions.

The expression caches accelerate inference/WHNF/defeq.
They do not change what is accepted.

NativeReduction is an explicit optional trust extension.

This is exactly the right high-level design.

## 16.1 Current runtime-layer weakness

Cache policy is not completely contained under Runtime.

For example, inference cache eligibility is owned by Theory/Inference/Helpers.lean even though decisions such as not caching checked applications/lambdas/foralls are performance policy.

Recommended target:

~~~text
Runtime/CachePolicy.lean
~~~

or:

~~~text
Checker/CachePolicy.lean
~~~

with an explicit statement that it is non-semantic.

This makes it harder for a future optimization to be mistaken for a typing rule.

---

# 17. Current self-host architecture

The semantic root is:

~~~text
Ps.KernelSelfHost.SelfHost
~~~

The portable source is accepted by PSC1 constraints.

Normal promotion gates are:

~~~text
portable source profile
        |
        v
psc1 check
        |
        v
canonical Lean -> ProofScript translation
        |
        v
psc1 check canonical .ps
        |
        v
Lean native build
        |
        v
compatibility/conformance
        |
        v
differential tests
~~~

Generated fixed-point reproduction is release/bootstrap evidence, not an every-commit gate.

That is a good balance.

It avoids making development unusably expensive while retaining a reproducible self-host milestone.

---

# 18. One source, two execution paths

The intended architecture remains:

~~~text
portable Lean-subset semantic source
              |
      +-------+-------+
      |               |
      v               v
PSC/backend-ts      Lean compiler
      |               |
      v               v
TypeScript/JS       native
~~~

There should not be separate hand-maintained semantic kernels for JS/native/Rust/WASM.

Backend-specific runtime acceleration is acceptable.
Backend-specific type theory is not.

---

# 19. Current evidence architecture

Current compatibility matrix:

~~~text
34 required rules
34 implemented
~~~

Current conformance matrix:

~~~text
33 direct-differential
1 direct-invariant
0 pending
~~~

This is strong release engineering.

However, two qualifications matter.

## 19.1 Rule granularity is too coarse for high-risk subsystems

Examples:

~~~text
PSK-ADMIT-IND
PSK-ADMIT-MUTIND
PSK-ADMIT-NESTED
~~~

Each row covers a large algorithm containing many soundness-sensitive subrules.

The matrix is sufficient as a top-level capability index.
It is not sufficient as the only soundness-oriented rule inventory.

Recommended architecture:

Keep the 34-row release matrix, but add a generated subrule inventory for high-risk areas.

Example nested subrules:

~~~text
NESTED-RESERVED-PREFIX
NESTED-UNIFORM-OCCURRENCE
NESTED-DISCOVERY
NESTED-AUX-FRESHNESS
NESTED-FLATTEN
NESTED-RESTORE-EXPR
NESTED-RESTORE-FULL-REGISTRY
NESTED-RESTORED-CONSTRUCTOR-CHECK
NESTED-RESTORED-REC-TYPE-CHECK
NESTED-RESTORED-RULE-CHECK
NESTED-RULE-TYPE-PRESERVATION
NESTED-AUX-NO-LEAK
~~~

Likewise ordinary/mutual inductives should expose positivity, elimination, recursor construction and rule preservation separately.

## 19.2 Differential-oracle independence can improve

The current generated rule reference explains that most direct-differential tests compare the self-host kernel with the frozen Lean-4.34-oriented PSC1Kernel reference.

That is valuable as regression coverage.

But PSC1Kernel and PSKernel-selfhost are closely related implementations.

Therefore they can share the same bug.

Recommended evidence hierarchy:

~~~text
Authority:
  official Lean 4.34.0 behavior/source

Primary direct oracle:
  official pinned Lean 4.34 executable/kernel API where practical

Regression oracle:
  frozen PSC1Kernel reference

Optional independent secondary evidence:
  lean4lean / ConLeche / kernel-arena adversarial corpus
~~~

Do not replace the frozen reference.
Add independence around it.

---

# 20. Current tests and benchmarks

Two important current files are now large:

~~~text
test/PsKernelSelfHostFoundationTests.lean  ~106 KB
test/PsKernelSelfHostBench.lean            ~145 KB
~~~

This is the weakest physical part of the project.

The tests are useful and currently green, but one large file makes:

- ownership unclear;
- code review harder;
- fixture reuse awkward;
- rule-to-test mapping less local;
- adversarial regression discovery harder;
- benchmark diagnostics prone to accumulating permanently.

The recent wide-nested debugging sequence is a good example: diagnostic helpers were useful but temporarily enlarged an already large benchmark file.

---

# 21. Architecture comparison

| Property | Lean 4.34 official | PSKernel current | Preferred PSKernel target |
| --- | --- | --- | --- |
| Semantic source | C++ kernel | portable Lean subset | same portable Lean subset |
| Main checker | type_checker class | distributed TypeChecker/Theory modules | explicit Checker/Engine knot |
| DefEq readability | concentrated in type_checker.cpp | strong conceptual split | retain split |
| Inductive implementation | one large inductive.cpp | ordinary/mutual/nested split | one Inductive subtree with submodes |
| Runtime caches | inside checker state | explicit Runtime/Cache | retain, strengthen import boundary |
| Environment index | implementation detail | explicit Runtime/EnvironmentIndex | retain |
| Native reduction | checker/runtime path | explicit capability provider | retain |
| Theory docs | language reference + source comments | strong KERNEL_THEORY + rule matrix | consolidate via this reference |
| Self-host source | C++/Lean runtime | PSC1-compatible Lean | retain |
| Conformance | Lean's own tests | 34/34 matrix + differential | add official direct oracle tier |
| Tests | broad Lean test suite | two large kernel test/bench files | split by subsystem |
| Import-layer enforcement | C++ module boundaries | mostly convention | add machine import fence |

---

# 22. Recommended target architecture

The best next architecture is not a rewrite.

It is a semantics-preserving package reorganization that makes the import graph match the conceptual graph.

Recommended canonical tree:

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
|   +-- Cache.lean
|   +-- CachePolicy.lean
|   +-- EnvironmentIndex.lean
|   '-- NativeReduction.lean
|
+-- Environment/
|   +-- Model.lean
|   +-- Lookup.lean
|   '-- Operations.lean
|
+-- Checker/
|   +-- Context.lean
|   +-- State.lean
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
|   +-- Engine.lean
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
|       +-- Common/
|       |   +-- Parameters.lean
|       |   +-- Positivity.lean
|       |   '-- RecursorValidation.lean
|       |
|       +-- Ordinary/
|       |   +-- Constructor.lean
|       |   +-- ConstructorAdmission.lean
|       |   +-- Recursor.lean
|       |   +-- Elimination.lean
|       |   '-- Admission.lean
|       |
|       +-- Mutual/
|       |   +-- Analysis.lean
|       |   +-- Recursor.lean
|       |   +-- Header.lean
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
|   +-- Kernel.lean
|   '-- SelfHost.lean
|
'-- Compat/
    +-- Instantiate.lean
    +-- TypeCheckerPrimitives.lean
    +-- TypeCheckerWhnf.lean
    +-- TypeCheckerProjection.lean
    +-- TypeCheckerInfer.lean
    +-- TypeCheckerRecursor.lean
    +-- TypeCheckerDefEqSupport.lean
    +-- TypeCheckerDefEq.lean
    +-- Quot.lean
    +-- Inductive.lean
    +-- InductiveAdmission.lean
    +-- MutualInductive.lean
    '-- NestedInductive.lean
~~~

The Compat folder may be transitional.
Long-term consumers should import API or canonical modules.

---

# 23. Why Checker/Engine should exist

The current source uses higher-order injection and several public TypeChecker*.lean integration files to avoid recursive module dependencies.

That implementation technique is reasonable.

The architecture problem is that the mutual recursion is not named as one concept.

Lean's official kernel has one type_checker object containing:

- infer;
- check;
- whnf;
- defeq;
- recursor reduction;
- caches;
- local context.

PSKernel should not collapse back into one giant file.

Instead, it should expose one explicit Engine module that ties the already-separated components together:

~~~text
Checker components
     |
     +-- Reduction
     +-- Inference
     +-- Recursor
     '-- DefEq
          |
          v
     Checker/Engine
          |
          v
     Checker/Session
~~~

This would make callback injection an implementation detail of the engine rather than a source-layout artifact visible through multiple top-level TypeChecker modules.

---

# 24. Recommended dependency law

The target import graph should be enforceable.

Recommended layers:

~~~text
Layer 0: Core

Layer 1: Runtime primitives
         Environment representation

Layer 2: Checker components

Layer 3: Checker Engine / Session

Layer 4: Admission

Layer 5: API

Layer 6: Compat
~~~

Allowed direction:

~~~text
Core
  ^
  |
Runtime / Environment
  ^
  |
Checker
  ^
  |
Admission
  ^
  |
API
  ^
  |
Compat consumers
~~~

Canonical implementation modules must never import Compat.

Admission may import Checker.
Checker must not import Admission.

Core must not import Runtime, Checker, Admission, API or Compat.

Runtime acceleration must not import Admission.

A small script should verify these import fences in CI.

This would convert architecture documentation into an executable invariant.

---

# 25. Environment representation recommendation

Do not immediately rewrite Environment.

The current representation is performant and tested.

Long-term cleaner model:

~~~text
PsKernelSemanticEnvironment
  constants
  quotInitialized

PsKernelEnvironment
  semantic
  index
  runtime capabilities
~~~

Potential benefit:

- semantic state becomes explicit;
- indexes/providers are visibly non-semantic;
- test oracles can compare semantic environments independently of acceleration;
- runtime resets become safer.

Risk:

- high churn through the whole checker;
- portable self-host source complexity;
- possible performance regressions.

Recommendation:

Do not make this change during the first folder reorganization.

Treat it as a later optional representation milestone only if profiling or provider work justifies it.

---

# 26. Inductive subsystem recommendation

The strongest source-structure improvement is to unify ordinary, mutual and nested inductive code physically.

Today:

~~~text
Inductive.lean
InductiveAdmission.lean
Theory/Inductive/
Theory/Mutual/
Theory/Nested/
MutualInductive.lean
NestedInductive.lean
~~~

Target:

~~~text
Admission/Inductive/
  Types
  Common
  Ordinary
  Mutual
  Nested
~~~

Advantages:

1. mirrors Lean's conceptual one-subsystem treatment;
2. makes shared recursor/positivity rules easier to discover;
3. prevents ordinary admission from looking more foundational than mutual/nested;
4. gives nested transformation a clear relationship to the mutual admission it invokes;
5. makes high-risk conformance subrules easier to organize.

Do not merge the source files back into a monolith.

Unify the namespace/folder hierarchy, not the implementation bodies.

---

# 27. Test architecture target

Recommended kernel test tree:

~~~text
test/KernelSelfHost/
|
+-- Fixtures/
|   +-- Base.lean
|   +-- Inductive.lean
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
+-- Runtime/
|   +-- CacheInvariant.lean
|   +-- EnvironmentIndexInvariant.lean
|   '-- NativeReduction.lean
|
+-- Adversarial/
|   +-- Lean434SoundnessRegressions.lean
|   +-- NestedAuxLeak.lean
|   '-- DefEqCacheOrder.lean
|
'-- Bench/
    +-- Harness.lean
    +-- Environment.lean
    +-- Cache.lean
    +-- Inference.lean
    +-- DefEq.lean
    +-- Recursor.lean
    +-- Inductive.lean
    +-- Nested.lean
    '-- Main.lean
~~~

Benefits:

- each compatibility rule has a local home;
- regression tests remain after debugging helpers are removed;
- benchmark instrumentation cannot pollute semantic conformance;
- fixtures are reusable;
- failures identify the subsystem immediately.

---

# 28. Conformance architecture target

Recommended evidence stack for each high-risk rule:

~~~text
1. source locator
2. positive case
3. negative case
4. edge/adversarial case
5. official Lean 4.34 result
6. frozen PSC1Kernel result
7. PSKernel-selfhost result
8. invariant checks where runtime representation matters
~~~

For soundness fixes introduced in Lean 4.33/4.34, add named permanent adversarial cases.

Especially important:

- non-transitive defeq-cache behavior;
- isProp must ensure a Sort;
- projection from Prop guard;
- recursor rule type preservation;
- uniform inductive occurrences;
- reserved nested auxiliary names;
- multi-family nested restoration;
- Nat computation size bound.

The release matrix can remain 34 rows.
The subrule registry can be generated or documented separately.

---

# 29. Documentation architecture target

PSKernel currently has several good documents:

~~~text
README
PSKERNEL_SELFHOST_ARCHITECTURE
DEVELOPMENT_PLAN
KERNEL_THEORY
KERNEL_RULE_REFERENCE
PERFORMANCE_BASELINE
compatibility JSON
conformance JSON
SELFHOST_EVIDENCE
~~~

The risk is not lack of documentation.
It is duplication and drift.

Recommended roles:

## PSKERNEL_REFERENCE.md

Human canonical reference:

- architecture;
- theory overview;
- source structure;
- trust model;
- current score/debt;
- target structure;
- reading map.

## PSKERNEL_SELFHOST_ARCHITECTURE.md

Short normative guardrails only.

## KERNEL_THEORY.md

Detailed explanation of algorithms/rules.

## KERNEL_RULE_REFERENCE.md

Generated machine-linked index only.

## DEVELOPMENT_PLAN.md

Only active roadmap and milestones.

## PERFORMANCE_BASELINE.md

Only measurements and performance conclusions.

## JSON matrices

Only machine-readable compatibility/conformance state.

Avoid copying the same policy paragraphs into every file.

---

# 30. What should not change

The architecture review does not recommend changing these decisions:

1. Keep one semantic implementation.
2. Keep Lean 4.34.0 pinned until an explicit target-version project.
3. Keep the PSC1 portable-source requirement.
4. Keep fail-closed exhaustion/error behavior.
5. Keep pair caches non-transitive.
6. Keep Environment.constants as semantic authority.
7. Keep runtime indexes/caches non-semantic.
8. Keep optional native reduction outside core theory.
9. Keep checked and infer-only inference semantically distinct.
10. Keep nested restoration re-validation.
11. Keep no generated-JS semantic patches.
12. Keep generated fixed point as promoted release/bootstrap evidence rather than every-commit work.
13. Do not create a second fast kernel.
14. Do not optimize by changing observable defeq ordering.

---

# 31. Recommended migration sequence

The reorganization should be incremental and semantics-preserving.

## Stage 0 - freeze invariants

Before moving files:

- portable CI green;
- 34/34 compatibility/conformance green;
- multi-family nested regression green;
- benchmarks recorded;
- canonical .ps recheck green.

No semantics change.

## Stage 1 - split tests

Move foundation tests and benchmarks into subsystem files.

This is low semantic risk and immediately improves reviewability.

Maintain one Main executable for each suite.

## Stage 2 - introduce canonical Checker hierarchy

Move:

~~~text
TypeCheckerBase
TypeCheckerWhnf
TypeCheckerProjection
Theory/Inference
Theory/Reduction
Theory/Recursor
Theory/DefEq
TypeChecker*
CheckerState
CheckerSession
~~~

under Checker without changing function bodies.

Add old-path compatibility umbrellas if needed.

## Stage 3 - unify inductive hierarchy

Move ordinary/mutual/nested source under Admission/Inductive.

Keep exact public symbols.

Do not alter algorithms.

## Stage 4 - isolate runtime cache policy

Move inference cache eligibility/publication policy out of theory-facing modules.

Add an explicit comment/API stating that cache policy cannot change judgments.

## Stage 5 - add import-fence audit

Machine-check canonical dependencies.

Fail CI if Core/Checker/Admission layers import upward.

## Stage 6 - improve oracle independence

Add official Lean 4.34 direct conformance adapters/cases.

Retain frozen PSC1Kernel differential as a second regression oracle.

## Stage 7 - optional environment representation cleanup

Only if justified by provider work or profiling.

This is not required to achieve a strong architecture score.

---

# 32. Suggested canonical reading order after reorganization

A reader should be able to learn the kernel in approximately this order:

~~~text
1. Core/Name
2. Core/Level
3. Core/Expr
4. Core/Substitution/*
5. Core/Declaration
6. Core/LocalContext
7. Environment/*
8. Checker/Context + State
9. Checker/Reduction/*
10. Checker/Projection
11. Checker/Inference/*
12. Checker/Recursor/*
13. Checker/DefEq/*
14. Checker/Engine
15. Checker/Session
16. Admission/Declaration/*
17. Admission/Quot/*
18. Admission/Inductive/Common/*
19. Admission/Inductive/Ordinary/*
20. Admission/Inductive/Mutual/*
21. Admission/Inductive/Nested/*
22. API/Kernel
23. API/SelfHost
24. Runtime internals for performance study
~~~

The important improvement is that compatibility wrappers disappear from the learning path.

---

# 33. Architecture invariants

These should be considered permanent unless deliberately revised.

## INV-1 One semantic source

There is exactly one maintained semantic kernel implementation.

## INV-2 Lean target is explicit

Every behavior claim names the Lean target version/commit.

## INV-3 Fail closed

Unsupported terms, malformed declarations, recursion/fuel exhaustion and failed checks reject.

## INV-4 No cache authority

A cache hit may reuse a previously established result.
A cache miss or cache representation may never create a semantic fact.

## INV-5 DefEq cache is not an equivalence closure

Successful and failed queries are pair facts only.

## INV-6 Environment history is authoritative

The runtime name index is an accelerator, not semantic storage.

## INV-7 Checked means checked

Infer-only results may only replace checked work when a stronger previously established invariant proves validity and the new use needs only the inferred type.

Such paths must be named explicitly, as with validated nested-rule comparison.

## INV-8 Nested restoration sees the complete family registry

Structural recursion over pending families must not shrink the semantic restoration universe.

## INV-9 Restored nested material is revalidated

Restored constructor types, recursor types and computation rules must be checked in the final environment.

## INV-10 Runtime capabilities are explicit

Native reduction is an optional capability at the trust boundary.

## INV-11 Portable source remains authoritative

PSC1-compatible source is maintained directly.
Generated JavaScript is not patched semantically.

## INV-12 Compatibility wrappers are downstream

Canonical implementation must not depend on legacy/compatibility umbrellas.

---

# 34. Evaluation by subsystem

## Core representations: 9.1/10

Strong:

- explicit data;
- portable;
- close to Lean;
- substitution split is readable.

Improve:

- move to Core namespace/folder consistently;
- keep compatibility umbrella outside canonical path.

## Environment/context/state: 8.5/10

Strong:

- authoritative constants vs index invariant;
- explicit runtime capability;
- checker state resembles Lean 4.34.

Improve:

- clarify runtime state physically;
- optionally split semantic environment later.

## Inference: 8.7/10

Strong:

- checked vs infer-only explicit;
- faithful application behavior;
- measurable cache policy.

Improve:

- remove dependency-layer inversion;
- move cache policy out of theory-facing helper.

## Reduction: 9.0/10

Strong:

- core/post-core split;
- observable order visible;
- native/Nat/definition phases explicit.

Improve:

- canonicalize namespace under Checker.

## Recursor reduction: 8.9/10

Strong:

- analysis and computation separated;
- resource behavior explicit.

Improve:

- integrate through named Engine rather than top-level wrapper pattern.

## DefEq: 9.4/10

Strongest subsystem.

The split makes Lean's difficult observable equality algorithm substantially more auditable.

Main remaining work is dependency/name cleanup, not semantic restructuring.

## Declaration admission: 9.0/10

Clear validation/admission transaction.

Could be nested under Admission/Declaration for consistency.

## Quot: 9.0/10

Small and clear.

## Ordinary inductives: 8.4/10

Semantically strong.
Physical placement is inconsistent with mutual/nested.

## Mutual inductives: 8.7/10

Good decomposition.
Should live inside a common Inductive hierarchy.

## Nested inductives: 9.2/10

Excellent phase decomposition after the recent bug-fix work.

Needs finer conformance subrules because this area is too soundness-sensitive for one matrix row.

## Runtime: 8.8/10

Correct principle and good measured indexing strategy.

Cache policy ownership should become more explicit.

## Tests: 7.2/10

High-value coverage but oversized files and mixed fixture/diagnostic/harness concerns.

This is the best low-risk structural improvement to do next.

---

# 35. Performance architecture assessment

Current performance engineering has generally followed the right rule:

~~~text
measure
-> identify hotspot
-> make narrow non-semantic change
-> run portability/conformance
-> keep or revert
~~~

Good examples:

- hybrid small cache promotion;
- environment index promotion;
- skipping counterproductive checked-app/lambda/forall cache publication;
- structural equality short path before full defeq;
- non-dependent instantiate fast path;
- constructor-major recursor WHNF shortcut;
- validated-old-rule nested comparison;
- reverting checked-constant cache removal when it harmed general workloads.

This is good engineering discipline.

The architecture should preserve a place for such policies without mixing them with the logical rule descriptions.

Target:

~~~text
Checker rule
  = semantic algorithm

Runtime policy
  = cache/index/allocation choice

Benchmark
  = evidence for runtime policy
~~~

---

# 36. Provider/deployment boundary

The self-host kernel is semantically mature, but the project intentionally has not yet promoted it as the default checking authority.

Current architecture guidance keeps lean434-wasm as the default authority until the provider-parity milestone is explicitly accepted.

That is a reasonable deployment posture.

Core-kernel completeness and provider-production-readiness are separate questions.

Recommended API layering:

~~~text
API/Kernel
  semantic declaration checking

API/Session
  checked-session operations

Provider adapter
  representation/protocol conversion only

Runtime provider
  optional native reduction capability
~~~

Provider adapters must not contain semantic fallback.

---

# 37. Recommended next architecture tasks

Order:

1. Split the foundation test file by subsystem.
2. Split the benchmark file by workload.
3. Add import-fence CI.
4. Create canonical Checker hierarchy and Engine module.
5. Move runtime cache policy out of inference theory helpers.
6. Unify ordinary/mutual/nested under Admission/Inductive.
7. Move compatibility umbrellas to Compat.
8. Expand high-risk conformance subrules.
9. Add more official-Lean direct oracle cases.
10. Only then consider deeper representation changes.

This order maximizes readability gains while minimizing semantic risk.

---

# 38. Final assessment

PSKernel should not be rewritten.

The current core design is sound enough that a rewrite would create more risk than value.

The right next step is architectural consolidation:

~~~text
current semantics
        +
strict dependency layers
        +
clean canonical folders
        +
split conformance/bench suites
        +
more independent oracle evidence
        =
production-grade reference kernel architecture
~~~

The current architecture has already crossed the threshold from experimental code into a credible kernel implementation.

What prevents a near-perfect architecture score is mostly not theory.
It is source topology, dependency enforcement and evidence organization.

The target should therefore be:

- preserve the semantic algorithms;
- preserve PSC1 portability;
- preserve current public symbols initially;
- reorganize modules by true ownership;
- enforce dependency direction in CI;
- strengthen independent Lean 4.34 oracle coverage;
- keep one source of truth.

---

# 39. Source references

## Lean 4.34 exact implementation sources

Pinned commit:

https://github.com/leanprover/lean4/tree/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel

Key files:

- https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/type_checker.cpp
- https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/type_checker.h
- https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/inductive.cpp
- https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/environment.cpp
- https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/quot.cpp
- https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/expr.h
- https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/level.h

## Lean language/type-system reference

- https://lean-lang.org/doc/reference/latest/The-Type-System/
- https://lean-lang.org/doc/reference/latest/The-Type-System/Universes/
- https://lean-lang.org/doc/reference/latest/The-Type-System/Propositions/
- https://lean-lang.org/doc/reference/latest/The-Type-System/Inductive-Types/
- https://lean-lang.org/doc/reference/latest/The-Type-System/Quotients/

The live language reference may describe a newer Lean release than 4.34. Exact implementation compatibility claims in this document therefore use the pinned 4.34 source as authority.

## Lean 4.34 release hardening

- https://lean-lang.org/doc/reference/latest/releases/v4.34.0/

Relevant kernel changes include:

- pair-based defeq caching after the non-transitivity soundness issue;
- stricter proposition/sort checking;
- recursor computation-rule type-preservation validation;
- uniform inductive occurrence validation;
- bounded Nat computation.

## Independent checker references

lean4lean:

- https://github.com/digama0/lean4lean
- https://arxiv.org/abs/2403.14064

ConLeche:

- https://github.com/leanprover/con-leche
- https://github.com/leanprover/con-leche/blob/master/OVERVIEW.md

These are comparative architectural references, not PSKernel semantic authorities.

---

# 40. Short architectural rule

If only one rule from this document is remembered, use this:

~~~text
Make the file/import architecture tell the same story as the kernel theory.

Core data
  -> checker algorithms
  -> admission
  -> API

Runtime accelerators may support that path,
but must never become an alternate path to acceptance.
~~~
