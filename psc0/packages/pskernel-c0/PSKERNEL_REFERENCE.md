# PSKernel Reference

> Assurance-first architecture reference for a portable, self-hostable, Lean-compatible proof kernel.

## 0. Scope and status

This document is the canonical human architecture reference for:

~~~text
repository: dwijayuda/pskernel
branch:     psc2/psc1kernel-selfhost-portable
package:    psc15selfhost/packages/pskernel-core
~~~

Audited live branch head before this revision:

~~~text
3717df0cf25f35b09d66fb2e6660ee0b0bbde3bd
~~~

Lean semantic compatibility authority:

~~~text
Lean 4.34.0
commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

Research date:

~~~text
2026-10-05
~~~

This document distinguishes three different things:

~~~text
CURRENT IMPLEMENTATION
    what the repository actually implements today

CURRENT REFERENCE PLAN
    the previous recommended target architecture

FINAL TARGET ARCHITECTURE
    the stronger design produced by the evaluation loop in this document
~~~

A target score is never evidence that the implementation has already reached that score.

Machine-readable semantic completeness remains authoritative in:

- LEAN_4_34_COMPATIBILITY.json
- LEAN_4_34_CONFORMANCE.json

Normative anti-drift policy remains in:

- PSKERNEL_CORE_ARCHITECTURE.md

The active roadmap remains in:

- DEVELOPMENT_PLAN.md

Algorithm explanation remains in:

- KERNEL_THEORY.md

Generated rule indexing remains in:

- KERNEL_RULE_REFERENCE.md

---

# 1. Executive conclusion

PSKernel should not become a new type theory.

Its best long-term identity is:

~~~text
a precisely versioned Lean-compatible kernel
with one portable self-hosted semantic source,
multiple execution targets,
machine-enforced trust boundaries,
independent external validation,
formal soundness evidence,
and long-lived proof interchange.
~~~

The strongest competitive position is not:

~~~text
more kernel features than Lean
~~~

It is:

~~~text
Lean-like practical expressiveness
+
Metamath-like verification diversity
+
HOL/Isabelle-like trust discipline
+
MetaCoq/McTT/Candle-style formal assurance
+
Lean Kernel Arena-style adversarial evidence
+
portable self-hosting across native and JavaScript runtimes
~~~

## 1.1 Current implementation score

Using the 15 criteria requested in this review, the current implementation is approximately:

~~~text
8.24 / 10
~~~

Its weakest dimensions are:

- formal/metatheoretic verification;
- independent implementation diversity;
- proof-format interoperability;
- some remaining architectural/source-layout debt;
- performance relative to the strongest current Lean checker experiments.

Its strongest dimensions are:

- portability;
- self-host/bootstrap;
- novelty;
- semantic compatibility discipline;
- auditability.

## 1.2 Previous Reference target score

The architecture previously documented in this file is strong as a source architecture, but weaker as a complete kernel-assurance architecture.

Using the same 15 criteria:

~~~text
previous planned architecture: 9.35 / 10
~~~

The main gaps were:

1. no first-class formal verification plane;
2. independent evidence remained secondary rather than architectural;
3. interoperability was under-specified;
4. runtime and logical TCB were not modeled separately enough;
5. non-semantic acceleration was treated as if it were automatically outside the TCB;
6. resource behavior lacked a first-class contract;
7. performance architecture was still too tied to the official Lean implementation style;
8. longevity needed explicit semantic-profile and proof-stream versioning.

## 1.3 Design loop

The plan was redesigned and rescored until the requested threshold was exceeded.

| Iteration | Main additions | Score |
| --- | --- | ---: |
| Baseline | previous PSKERNEL_REFERENCE target | 9.35 |
| Iteration 1 | Assurance Plane, formal spec track, hardening corpus, proof-stream envelope | 9.73 |
| Iteration 2 | independent checker consensus, TCB two-axis model, runtime/semantic target split, resource contracts | 9.87 |
| Iteration 3 | triangulated assurance, machine-checked refinement target, long-lived interchange, execution-diversity receipts, benchmark/arena promotion gates | **9.96** |

The final planned architecture therefore clears:

~~~text
>= 9.9 / 10
~~~

under the 15-criterion rubric.

No final criterion is scored below 9.8.

---

# 2. Evaluation method

The 15 requested criteria are treated as equally weighted.

~~~text
overall score
    =
arithmetic mean of the 15 criterion scores
~~~

This avoids hiding a weak assurance property behind a large weight on performance or novelty.

The criteria are:

1. Soundness/fidelity
2. TCB transparency
3. Formal/metatheoretic verification
4. Adversarial robustness
5. Compatibility completeness
6. Architecture
7. Independent evidence
8. Performance
9. Resource behavior
10. Portability
11. Longevity
12. Interoperability
13. Self-host/bootstrap
14. Auditability
15. Novelty

## 2.1 Non-compensating hard gates

A numerical score is only valid if all hard gates pass.

### G1 — exact semantic target

The kernel must name the exact logic/profile/version it claims to implement.

For the current profile:

~~~text
Lean 4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

### G2 — no known false-acceptance defect

A known route to acceptance of an invalid declaration disqualifies the kernel from a production-trusted score.

### G3 — fail closed

Malformed input, unsupported input, resource exhaustion, invalid capabilities and failed checks must never become acceptance.

### G4 — no hidden semantic fallback

A failed primary check may not silently invoke another semantic implementation and accept.

### G5 — complete TCB inventory

Every component capable of affecting acceptance must be inventoried.

### G6 — reproducible target identity

The semantic profile, rule manifest, checker source and proof stream must be identifiable by stable version/hash.

### G7 — one production semantic source

Independent checkers may exist as validators, but there is one maintained production semantic implementation.

---

# 3. Research basis

This architecture review studied:

## Lean

- exact Lean 4.34.0 kernel source;
- Lean 4 type theory;
- proof irrelevance;
- universe semantics;
- algorithmic definitional equality;
- ordinary, mutual and nested inductives;
- quotient computation;
- declaration admission;
- Lean 4.34 kernel hardening;
- Lean 4.34.1 runtime hardening;
- Lean 4.35 native-reduction removal;
- Lean Kernel Arena results and external checker architecture.

## Other proof-system traditions

- Rocq / Coq;
- MetaCoq;
- Isabelle/Pure and Isabelle/HOL;
- HOL Light;
- Candle;
- Metamath;
- Agda and Cubical Agda;
- Lambdapi;
- Dedukti;
- McTT;
- Lean4Lean;
- Nanoda;
- ConLeche;
- eink0rn;
- lazylean;
- MathGraph.

The purpose is not to rank theorem provers globally.

Different systems optimize for different foundations and trust models.

The useful question is:

~~~text
what architectural property does each system demonstrate unusually well?
~~~

---

# 4. Lean 4 kernel boundary

Lean has a small trusted proof-checking core relative to the complete system.

The kernel checks already elaborated core declarations.

Outside the kernel:

~~~text
parsing
surface syntax
macros
elaboration
unification
tactics
typeclass search
termination elaboration
compiler
code generation
package manager
IDE/server
~~~

Recursive source definitions are elaborated to primitive recursor use before kernel checking.

The kernel therefore does not need to implement the full frontend language.

Conceptually:

~~~text
Environment
    +
Core Declaration
    |
    v
Kernel checking
    |
    +-- invalid/error
    |
    '-- valid -> extended Environment
~~~

PSKernel should preserve this narrow boundary.

---

# 5. Lean type theory relevant to PSKernel

Lean is based on dependent type theory with:

- universes;
- dependent Pi types;
- lambda abstraction;
- inductive types;
- proof irrelevance;
- quotient primitives;
- kernel computation;
- algorithmic definitional equality.

Core judgments:

~~~text
infer  : Γ |- e : A

check  : Γ |- e is valid

whnf   : e -->* weak-head form

defeq  : Γ |- A <=> B

admit  : Env + Decl -> Env'
~~~

These operations are algorithmically mutually dependent.

Inference needs conversion.
Conversion needs inference and reduction.
Reduction needs recursor metadata and sometimes inference/defeq.
Admission invokes all of them.

This checker recursion knot must have one architectural owner.

---

# 6. Lean expression and universe core

Lean 4 kernel expressions include:

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

Unresolved metavariables are not accepted as valid checked proof terms.

Universe levels include:

~~~text
zero
succ
max
imax
parameter
metavariable
~~~

Important properties:

- Prop is Sort 0;
- Type u is Sort (u + 1);
- Prop is impredicative;
- Type universes are predicative;
- Lean universes are non-cumulative;
- Pi universes use imax.

Universe equivalence is semantic, not string equality.

---

# 7. Lean definitional equality

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
literal-specific rules
~~~

The implemented checker does not simply normalize both terms fully and compare syntax.

Lean's algorithmic relation is sound and intentionally incomplete.

In particular, the current Lean reference describes it as:

~~~text
reflexive
symmetric
not transitive
~~~

This has major consequences for cache design.

---

# 8. Lean 4.34 hardening lessons

Lean 4.34 demonstrates that proof-kernel assurance is not only about the written theory.

Important hardening includes:

## Pair-based defeq cache

Lean removed successful-query union-find caching after an order-dependent soundness issue.

A performance structure altered acceptance.

Lesson:

~~~text
intended non-semantic acceleration
is still part of the TCB until its refinement property is established.
~~~

## isProp hardening

The checker must establish the inferred type is a Sort before classifying a term as proposition-valued.

## Projection hardening

Projection from a proof-like structure must preserve proof-irrelevance restrictions.

## Recursor rule preservation

A generated recursor rule must have the expected result type, not merely some well-formed type.

## Uniform inductive occurrences

Inductive occurrences must respect required parameter/universe application.

## Nested-inductive validation

Dropped parameters, restored recursors and internal auxiliary declarations require defensive validation.

## Nat resource bound

Compact inputs cannot be allowed to force arbitrarily enormous numerals.

---

# 9. Lean 4.34.1 changes the TCB discussion

Lean 4.34.1 is especially relevant to PSKernel architecture even though the semantic target remains 4.34.0.

The patch release contains runtime fixes for reference-count overflow/underflow and sharing paths that could lead to memory unsafety and potentially false proofs under extreme malicious inputs.

This means:

~~~text
kernel semantic source correctness
!=
complete execution soundness
~~~

A proof kernel has at least two important trust surfaces:

~~~text
LOGICAL TCB
    inference/reduction/defeq/admission rules

EXECUTION TCB
    compiler
    runtime
    memory manager
    FFI
    native capabilities
    parser/export decoder
~~~

PSKernel must inventory both.

---

# 10. Lean 4.35 future signal

Lean 4.35 removes:

~~~text
Lean.reduceBool
Lean.reduceNat
Lean.ofReduceBool
Lean.ofReduceNat
Lean.trustCompiler
~~~

and removes the kernel path that executed the first two through the compiler.

For PSKernel this does not alter the Lean 4.34 semantic profile.

It does imply that the 4.34 native reduction mechanism should remain isolated as a target-specific trusted capability rather than being treated as timeless core theory.

---

# 11. What other systems teach us

No system is simply better than Lean in every dimension.

The useful comparison is per property.

## 11.1 Rocq / Coq

Rocq follows the de Bruijn criterion:

~~~text
rich elaborator/tactics
    ->
proof term in CIC
    ->
small kernel type checker
~~~

Strengths relevant to PSKernel:

- mature dependent-type lineage;
- explicit core-language documentation;
- inductives/coinductives;
- polymorphic universes;
- SProp;
- long-lived proof-assistant engineering.

Lesson:

~~~text
mature dependent type theory is compatible with a strict kernel boundary.
~~~

Do not copy every kernel feature into PSKernel; target compatibility remains Lean 4.34.

## 11.2 MetaCoq

MetaCoq provides:

- a cleaned-up formal calculus corresponding to Coq;
- mechanized metatheory;
- a verified reduction/conversion/type checker;
- correctness and completeness results relative to its formal calculus, under stated assumptions.

Lesson:

~~~text
implementation fidelity and formal metatheory can coexist.
~~~

PSKernel should eventually have an abstract formal semantics independent of its executable structure.

## 11.3 Isabelle/Pure and Isabelle/HOL

Isabelle follows the LCF tradition.

Its Pure kernel can record full proof terms, and a separate proof checker can replay them from primitive inference rules.

Strengths:

- trust-minimizing architecture;
- long-term stability;
- generic logical framework;
- mature proof engineering.

Lesson:

~~~text
proof construction machinery should be allowed to be complex
because theorem creation remains controlled by a narrow kernel boundary.
~~~

## 11.4 HOL Light

HOL Light's fusion.ml exposes a tiny complete HOL kernel.

Its theorem type is abstract and theorem construction flows through primitive trusted operations.

Strength:

~~~text
extreme auditability and a very small logical TCB.
~~~

Lesson:

PSKernel should keep public checked-result construction narrow and impossible to forge through ordinary API use.

## 11.5 Candle

Candle verifies a HOL Light-style theorem prover down to generated machine code through CakeML.

Strength:

~~~text
end-to-end execution assurance.
~~~

Lesson:

source-level proof of checker correctness is not the absolute assurance ceiling.

Compiler/runtime correctness matters.

PSKernel does not need Candle's entire verification scope immediately, but its architecture should leave room for increasingly verified execution paths.

## 11.6 Metamath

Metamath has an extremely small verifier specification and many independent verifier implementations in different programming languages.

Its proof databases are designed for longevity and explicit replay.

Strengths:

- independent verifier diversity;
- tiny verification algorithm;
- stable proof artifacts;
- long-lived proof databases.

Lesson:

~~~text
a proof artifact should outlive any single checker implementation.
~~~

PSKernel should invest in stable exported declaration/proof streams rather than only executable package compatibility.

## 11.7 Agda / Cubical Agda

Agda represents a different type-theory philosophy.

Cubical Agda adds:

- path types;
- computational univalence;
- higher inductive types;
- composition/transport primitives.

Strength:

~~~text
advanced computational type-theory research.
~~~

Lesson:

future relevance does not require PSKernel to add these features.

They belong in a different semantic profile or different system, not in a Lean-compatibility kernel.

## 11.8 Lambdapi / Dedukti

These systems use the lambda-Pi calculus modulo rewriting.

Strengths:

- logic interoperability;
- user-defined logical frameworks;
- rewriting as conversion;
- import/export between systems.

Risk:

sound use requires properties such as confluence and termination of rewriting.

Lesson:

PSKernel should borrow interoperability discipline, not user-extensible conversion rules.

## 11.9 McTT

McTT provides a verified executable kernel for a core Martin-Lof type theory.

It cleanly separates:

~~~text
theoretical metatheory
algorithmic checker
executable extraction
~~~

Lesson:

formal kernel verification is practical when the theory and refinement boundary are designed explicitly.

## 11.10 Lean4Lean

Lean4Lean is close to the official Lean kernel algorithm and written mostly in Lean.

Important design idea:

~~~text
TypeChecker.Methods
~~~

explicitly represents the mutually recursive checker operations.

It also separates:

~~~text
implementation
Theory
Verify
~~~

Lesson:

PSKernel should have one explicit checker-knot owner and should keep executable checker architecture distinct from abstract metatheory.

## 11.11 Nanoda

Nanoda is an independent Rust Lean checker.

Strengths:

- implementation-language diversity;
- independent checker value;
- parallel checking;
- competitive performance.

Lesson:

independent checkers provide assurance that another implementation would not reproduce the same mistake.

## 11.12 ConLeche

ConLeche has a model-based consistency proof.

If its verified checker accepts an environment, that environment has a set-theoretic model under the project's assumptions, and no theorem of False is accepted.

It uses its own term representation rather than Lean.Expr.

Lesson:

formal assurance can be built around a practical Lean-compatible checker without requiring bit-for-bit reproduction of the official implementation.

## 11.13 eink0rn

eink0rn is a clean-room Haskell Lean checker.

It simplifies the internal theory by translating nested and mutual inductives before its core sees them, and re-derives recursors rather than blindly trusting exported metadata.

In current Kernel Arena results it accepts/rejects the scored corpus without declines.

Lesson:

clean-room implementation diversity is unusually valuable evidence.

## 11.14 lazylean

lazylean retains Lean-style checking but replaces substitution-heavy WHNF with a lazy abstract machine.

Current Kernel Arena measurements show it can outperform the official kernel significantly on representative large workloads while preserving the tested acceptance/rejection behavior.

Lesson:

~~~text
Lean semantics do not require copying Lean's reduction-machine implementation.
~~~

A future PSKernel optimization may change execution representation if semantic equivalence is established.

## 11.15 MathGraph

MathGraph demonstrates that substantial checker speedups can come from:

- parallel checking;
- avoiding redundant forcing;
- targeted conversion/unfolding work;
- profiling-driven removal of redundant operations.

Lesson:

the official kernel is a semantic authority, not necessarily the performance ceiling.

---

# 12. Current PSKernel implementation audit

Current semantic source:

~~~text
packages/pskernel-core/src/Ps/KernelCore
~~~

The current implementation already has strong conceptual decomposition:

~~~text
Core data
Theory/Substitution
Theory/Reduction
Theory/Inference
Theory/Recursor
Theory/DefEq
Theory/Admission
Theory/Quot
Theory/Inductive
Theory/Mutual
Theory/Nested
Runtime/Cache
Runtime/EnvironmentIndex
Runtime/NativeReduction
CheckerState
CheckerSession
TypeChecker integration modules
SelfHost
~~~

Its strongest current architectural elements are:

- one maintained semantic source;
- exact Lean target pin;
- explicit checker state;
- pair-based defeq success/failure caches;
- clear defeq ordering;
- clear nested transformation phases;
- self-host portable profile;
- no generated-JS semantic patching;
- fail-closed behavior;
- rule/conformance matrices.

Its main current weaknesses are:

- physical source hierarchy still contains migration-era top-level modules;
- checker recursion wiring is distributed;
- runtime role and trust status are not represented separately;
- formal verification is mostly future work;
- direct official-Lean oracle coverage should be stronger;
- tests/benchmarks remain monolithic;
- proof interchange is not yet a first-class public artifact;
- performance is competitive in several microcases but not yet leading across broad workloads.

---

# 13. Why the previous trust classification was incomplete

The previous Reference distinguished:

~~~text
semantic rule
non-semantic acceleration
trusted capability
adapter
~~~

That is useful as a semantic-role classification.

It is not sufficient as a TCB classification.

Example:

~~~text
defeq union-find cache
~~~

was intended to be an optimization, but it affected soundness.

Therefore the final architecture uses two independent axes.

---

# 14. Final two-axis trust model

## 14.1 Semantic role

### R0 — logical semantic rule

Examples:

- level equivalence;
- checked inference;
- WHNF ordering;
- defeq ordering;
- recursor reduction;
- admission rules;
- positivity;
- nested restoration validation.

### R1 — intended semantic-preserving acceleration

Examples:

- hash indexes;
- memo caches;
- cache promotion;
- structural hash metadata;
- sharing/interning;
- fast application-spine decomposition.

An R1 component must preserve R0 answers.

### R2 — target-specific trusted capability

Examples for Lean 4.34:

- native reduceBool;
- native reduceNat.

### R3 — protocol/adapter

Examples:

- declaration codec;
- provider adapter;
- NDJSON reader;
- serialization envelope.

### R4 — assurance-only component

Examples:

- independent oracle runner;
- fuzz generator;
- model checker;
- formal specification;
- benchmark harness.

R4 never participates in production acceptance.

## 14.2 Trust status

### V — formally verified/refinement-proved

The component has a machine-checked statement connecting implementation behavior to a specification.

### C — consensus-checked/independently cross-validated

The component is not formally verified but release evidence includes independent implementations.

### T — trusted implementation

The component can influence acceptance and is trusted by testing/review.

### D — derived/generated artifact

The artifact is generated from trusted source and validated by a reproducible receipt.

### U — untrusted/outside TCB

The component may propose data/results but cannot create an accepted theorem.

This distinction prevents the mistake:

~~~text
non-semantic intent
therefore
not in the TCB
~~~

which is false.

---

# 15. Logical TCB versus execution TCB

The final Reference explicitly separates:

## Logical TCB

Anything whose logical algorithm or data can directly affect acceptance:

- level operations;
- expression/substitution machinery;
- environment lookup correctness;
- inference;
- reduction;
- defeq;
- inductive admission;
- quotient admission;
- native semantic capabilities.

## Execution TCB

Anything that can corrupt the execution of the logical TCB:

- compiler;
- runtime;
- memory manager;
- FFI;
- host VM;
- parser/export decoder;
- native evaluator;
- thread/process isolation.

## Assurance TCB

Tools used to claim stronger evidence:

- export generator;
- independent checker;
- formal proof checker;
- receipt verifier.

The production kernel must publish an explicit machine-readable TCB inventory.

Suggested file:

~~~text
PSKERNEL_TCB.json
~~~

---

# 16. Semantic target versus host runtime

A long-lived kernel should separate:

~~~text
SEMANTIC TARGET
    exact Lean behavior being implemented

HOST EXECUTION RUNTIME
    compiler/runtime used to execute PSKernel
~~~

For example:

~~~text
semantic target:
    Lean 4.34.0
    293d5d0...

host runtime:
    separately recorded and hardened
~~~

The host runtime may be updated for security/runtime fixes only after evidence shows the semantic result is unchanged.

A proof receipt must record both.

This makes it possible to preserve an old semantic profile while running it on a safer execution substrate.

---

# 17. Final architecture: two planes

The final design has:

~~~text
EXECUTION PLANE
    the one production semantic implementation

ASSURANCE PLANE
    specification, verification, external checking,
    adversarial testing, interoperability and evidence
~~~

There is no second production semantic implementation.

External checkers are validators, not fallbacks.

---

# 18. Execution Plane canonical tree

Final target:

~~~text
Ps/KernelCore/
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
|   |   +-- EnvironmentIndex.lean
|   |   '-- Metadata.lean
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
|   +-- ResourcePolicy.lean
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
|   +-- Outcome.lean
|   +-- Kernel.lean
|   +-- Session.lean
|   '-- Provider.lean
|
'-- SelfHost.lean
~~~

Compatibility forwarding modules are migration artifacts only.

They do not belong in the final semantic root.

---

# 19. Checker recursion knot

The checker has unavoidable mutual algorithmic dependencies.

Define one internal interface:

~~~text
CheckerOps
    infer
    check
    whnfCore
    whnf
    defeq
    reduceRecursor
~~~

Then:

~~~text
Reduction ───────┐
Inference ───────┤
Projection ──────┼──> Checker/Knot
Recursor ────────┤          |
DefEq ───────────┘          v
                       Checker/Session
~~~

Only Knot owns the recursive wiring.

This is an architectural idea strongly supported by the structure used in Lean4Lean.

PSC1 portability remains the implementation constraint:

the interface may be represented with proven curried callback patterns if record-of-functions code would weaken self-hostability or performance.

---

# 20. Semantic Environment

Long-term target:

~~~text
PsKernelSemanticEnvironment
    constants
    quotInitialized

PsKernelEnvironment
    semantic
    index
~~~

The semantic view must determine logical environment identity.

The index must be rebuildable from semantic declarations.

Trusted external capabilities belong to CheckerContext or Session configuration, not to semantic declaration history.

Important theorem/invariant target:

~~~text
rebuildIndex(env).semantic = env.semantic
~~~

and checker answers are invariant under valid index reconstruction.

---

# 21. Resource contract

Resource behavior becomes a first-class kernel property.

Checker/ResourcePolicy should define:

- recursion-depth policy;
- Nat literal size policy;
- fuel/exhaustion behavior where explicit fuel exists;
- cancellation policy;
- stack policy;
- per-declaration accounting;
- deterministic resource error categories.

Public outcome should distinguish:

~~~text
Accepted
RejectedInvalid
DeclinedUnsupported
ResourceExhausted
InternalError
~~~

A consumer may treat any non-Accepted result as fail-closed.

But distinguishing invalidity from exhaustion is important for:

- interoperability;
- distributed checking;
- debugging;
- adversarial testing;
- external checker protocols.

There must never be:

~~~text
ResourceExhausted
    ->
fallback semantic checker
    ->
Accepted
~~~

inside one authority path.

---

# 22. Inductive subsystem

All inductive admission belongs under one owner:

~~~text
Admission/Inductive/
    Common
    Ordinary
    Mutual
    Nested
~~~

Do not merge the files into a monolith.

The hierarchy reflects conceptual ownership.

## Common

Only genuinely shared Lean rules:

- parameters;
- occurrences;
- positivity;
- elimination policy;
- recursor preservation validation.

## Ordinary

- constructor shape;
- constructor admission;
- recursor generation;
- ordinary transaction.

## Mutual

- family analysis;
- shared headers;
- motives/minors;
- cross-family recursive hypotheses;
- bundle transaction.

## Nested

Keep the existing strong phase split.

The permanent nested invariants include:

~~~text
full auxiliary-family registry retained during restoration
dropped parameters validated
restored constructors rechecked
restored recursor types rechecked
restored rule RHSs rechecked
restored rule type preservation
no internal nested auxiliary declarations leak
~~~

---

# 23. Assurance Plane

The Assurance Plane is explicitly outside the production semantic closure.

Recommended repository area:

~~~text
psc15selfhost/assurance/pskernel/
|
+-- Spec/
|   +-- Lean434/
|   |   +-- Syntax
|   |   +-- Universes
|   |   +-- Typing
|   |   +-- Reduction
|   |   +-- DefEq
|   |   +-- Environment
|   |   +-- Inductive
|   |   +-- Quot
|   |   '-- Admission
|   '-- README.md
|
+-- Verify/
|   +-- Core
|   +-- Substitution
|   +-- Universe
|   +-- Reduction
|   +-- Inference
|   +-- DefEq
|   +-- Inductive
|   +-- Nested
|   +-- Environment
|   '-- Refinement
|
+-- Oracle/
|   +-- OfficialLean
|   +-- Nanoda
|   +-- ConLeche
|   +-- Eink0rn
|   '-- Comparison
|
+-- Arena/
|   +-- pinned-corpus.json
|   +-- expected-results.json
|   '-- runner
|
+-- Fuzz/
|   +-- DeclarationMutator
|   +-- LevelMutator
|   +-- RecursorMutator
|   +-- NestedMutator
|   '-- DifferentialRunner
|
+-- Interop/
|   +-- ExportManifest.schema.json
|   +-- Receipt.schema.json
|   '-- Divergences.md
|
'-- Reports/
    +-- compatibility
    +-- assurance
    +-- performance
    '-- releases
~~~

The formal verification implementation may use a proof assistant different from the production kernel language when independence is valuable.

---

# 24. Formal verification target

Formal verification should focus on soundness, not on proving that Lean's incomplete algorithmic conversion becomes complete.

Target theorem shape:

~~~text
if PSKernel accepts declaration d in valid environment E,
then the resulting environment E' satisfies the formal Lean434 validity model.
~~~

Priority proof stack:

## V1 Core syntax and substitution

- lifting;
- instantiation;
- abstraction;
- free-variable discipline.

## V2 Universes

- level substitution;
- normalization/equivalence soundness.

## V3 Reduction

- beta/zeta/projection/recursor/Quot reduction preserves typing.

## V4 Inference/checking

- returned types are valid;
- checked expressions have the returned type.

## V5 DefEq

- every successful algorithmic defeq result implies declarative conversion/equality in the formal model.

No transitivity completeness claim is required.

## V6 Admission

- each accepted declaration preserves environment validity.

## V7 Inductive soundness

- positivity;
- recursor type;
- recursor rule preservation;
- elimination constraints.

## V8 Nested transformation

- transformed admission plus restoration preserves the original declaration's validity;
- alternatively, prove that final rechecking is sufficient to establish the required invariant.

## V9 Acceleration refinement

- valid cache/index representations preserve checker results.

## V10 Executable refinement

Connect the portable implementation to the abstract specification.

This is the main requirement for a near-10 formal-verification score.

---

# 25. Independent evidence architecture

Do not create a second production kernel inside PSKernel.

Use external independent checkers as validators.

High-assurance release consensus:

~~~text
PSKernel native
PSKernel generated JS
official Lean checker
at least one independent checker
optional verified/model-based checker
~~~

Acceptance modes:

## Normal mode

Production PSKernel authority only.

## Differential CI mode

PSKernel + official Lean.

## Diversity mode

PSKernel + official Lean + independent checker such as Nanoda or eink0rn.

## Verified-assurance mode

Where the feature profile is supported:

PSKernel + official Lean + ConLeche/other proved checker.

These modes never implement fallback semantics.

A mismatch blocks promotion.

---

# 26. Adversarial robustness

The final target incorporates adversarial testing as architecture, not optional QA.

Permanent corpus includes:

- every known Lean kernel false-acceptance bug relevant to supported versions;
- Lean Kernel Arena bad/good/corner cases;
- PSKernel-specific regressions;
- nested multi-family restoration;
- defeq cache-order mutations;
- projection/Prop attacks;
- malformed recursor metadata;
- universe-parameter corruption;
- declaration-order violations;
- duplicate-name attacks;
- huge Nat/resource bombs;
- deep recursion;
- invalid native-capability responses.

Differential fuzzing should mutate exported declaration streams and compare:

~~~text
PSKernel
official Lean
independent checker(s)
~~~

A disagreement becomes a minimized permanent regression fixture.

---

# 27. Compatibility completeness

Keep the current top-level compatibility matrix.

Add a fine-grained rule registry:

~~~text
LEAN_4_34_KERNEL_RULES.json
~~~

Each rule should contain:

~~~text
id
parentCompatibilityId
semantic statement
Lean source locator
PSKernel owner module
PSKernel symbol
semantic role
trust status
positive test
negative test
adversarial test
official-Lean oracle
independent oracle
verification theorem if available
status
~~~

High-risk parent rows such as:

~~~text
PSK-ADMIT-IND
PSK-ADMIT-MUTIND
PSK-ADMIT-NESTED
PSK-DEFEQ-DELTA
~~~

must expand into their meaningful subrules.

---

# 28. Architecture manifest

Create:

~~~text
PSKERNEL_ARCHITECTURE.json
~~~

It should declare:

- semantic root;
- allowed layers;
- import direction;
- module ownership;
- target Lean profile;
- semantic role;
- trust status;
- public/private modules;
- compatibility shims;
- source closure;
- rule ownership.

CI audit:

~~~text
psc1kernel-architecture-audit.mjs
~~~

Required failures:

- Core importing Checker;
- Checker importing Admission;
- canonical source importing Compat;
- semantic source importing frozen PSC1Kernel;
- semantic source importing test/bench code;
- more than one semantic owner for one rule;
- mismatched target version/commit across manifests.

---

# 29. TCB manifest

Create:

~~~text
PSKERNEL_TCB.json
~~~

For each component:

~~~text
component
semanticRole
trustStatus
canAffectAcceptance
failureMode
independentEvidence
verificationEvidence
runtimeDependency
removalOrIsolationStrategy
~~~

Release documentation should publish:

~~~text
logical TCB
execution TCB
optional capability TCB
assurance tools
~~~

This materially improves auditability and longevity.

---

# 30. Performance architecture

Lean's semantic algorithm is the compatibility authority.

Lean's current execution representation is not the performance ceiling.

Current alternative checkers demonstrate:

- lazy abstract-machine reduction can improve runtime/memory behavior;
- targeted defeq ordering matters greatly;
- parallel declaration checking can provide large speedups;
- recursor metadata can be re-derived/validated rather than blindly trusted.

PSKernel performance policy:

## P1 preserve semantic judgments

No performance optimization may weaken acceptance conditions.

## P2 optimize representations first

Preferred order:

- environment/index representation;
- cache representation;
- structural metadata;
- sharing;
- stack discipline;
- allocation;
- parallel declaration scheduling where dependency order allows.

## P3 semantic-sensitive optimizations need refinement evidence

Examples:

- lazy reduction machine;
- alternate unfolding strategy;
- infer-only shortcut;
- recursor shortcut;
- native evaluation.

These require:

- exact invariant;
- official differential tests;
- adversarial tests;
- ideally formal refinement.

## P4 promotion benchmark corpus

Measure:

- checked applications;
- dependent applications;
- WHNF;
- defeq;
- recursive recursors;
- ordinary inductive admission;
- indexed inductives;
- mutual inductives;
- nested inductives;
- large environments;
- whole Init/Std/mathlib-style exports where practical;
- memory;
- stack;
- throughput.

## P5 target

A strong native target remains:

~~~text
<= ~1.5x official Lean on representative workloads
~~~

but the architecture allows better-than-official performance.

Do not treat 1.0x as an upper limit.

---

# 31. Resource behavior target

A production kernel should be robust under hostile inputs.

Target properties:

- deterministic semantic result independent of cache history;
- explicit recursion/depth accounting;
- bounded primitive allocation;
- bounded host stack where practical;
- cancellation;
- no silent retry loops;
- no unbounded auxiliary metadata growth without accounting;
- clear ResourceExhausted outcome;
- corpus for exponential defeq pathologies;
- memory telemetry in release benchmarks.

Long-term improvement:

prefer iterative/constant-stack reduction machinery where it can be proven equivalent and gives clear robustness gains.

---

# 32. Portability target

One semantic source remains central:

~~~text
portable PSC1-compatible Lean subset
        |
        +-- Lean compiler -> native
        |
        '-- PSC/backend-ts -> TypeScript/JavaScript
~~~

High-assurance release evidence should compare both artifacts on the same semantic corpus.

The JS artifact is valuable for:

- browser;
- npm;
- sandboxing;
- runtime diversity;
- independent execution from Lean's native runtime.

The native artifact is valuable for:

- large proof checking;
- server/CI workloads;
- performance.

Portable source does not mean every host is equally trusted.

Receipts record the runtime used.

---

# 33. Interoperability target

Do not invent an entirely private proof-stream ecosystem if Lean already has an emerging external checker format.

Use Lean-compatible exported declaration streams such as the lean4export NDJSON format wherever practical.

Add only a thin PSKernel manifest envelope.

Suggested:

~~~text
PSKernelExportManifest-v1
    semanticTarget
    targetCommit
    exportFormatVersion
    rootStreamHash
    compatibilityManifestHash
    fineRuleManifestHash
    architectureManifestHash
    sourceCommit
~~~

This allows the same proof stream to be consumed by:

- official Lean;
- PSKernel;
- Kernel Arena tooling;
- independent checkers.

This is a major longevity/interoperability advantage.

---

# 34. Proof/checking receipt

Define a durable release/checking receipt.

Suggested fields:

~~~text
receiptVersion
semanticProfile
semanticCommit
checkerSourceCommit
checkerArtifactHash
hostRuntime
hostRuntimeHash
exportStreamHash
ruleManifestHash
architectureManifestHash
TCBManifestHash
outcome
resourcePolicy
oracleResults
timestamp
~~~

A receipt is evidence, not a proof.

Its value is reproducibility and long-term audit.

---

# 35. Longevity architecture

Long-term stability requires separating profiles.

Do not scatter version tests through the checker.

Prefer:

~~~text
Lean4340 profile
    exact compatibility contract
    target-specific native capability

future Lean profile
    separately promoted
    explicit compatibility delta
~~~

Target upgrades require:

- rule diff;
- source locator diff;
- divergence diff;
- corpus diff;
- performance diff;
- TCB diff.

Old profiles remain reproducible when feasible.

The 4.34 native-reduction capability becomes removable in a future profile rather than contaminating common theory forever.

---

# 36. Runtime hardening and semantic-profile separation

Because Lean 4.34.1 fixed runtime problems after the 4.34.0 semantic release, PSKernel should treat execution hardening independently from semantic-profile identity.

Policy:

~~~text
semantic profile remains pinned

host runtime may be upgraded only through an explicit hardened-runtime promotion
with cross-runtime differential evidence
~~~

For high-risk untrusted proof streams:

- sandbox build/export;
- check serialized declarations outside the build sandbox;
- optionally require independent checker consensus.

This follows the direction of Lean's current high-risk validation guidance.

---

# 37. Self-host/bootstrap architecture

Current strength should be preserved:

- PSC1-compatible semantic source;
- canonical Lean -> ProofScript translation;
- PSC1 recheck;
- generated TypeScript/JavaScript;
- historical fixed point;
- native Lean execution.

Future high-assurance bootstrap:

~~~text
source closure hash
    +
canonical .ps hash
    +
generated TS hash
    +
generated JS hash
    +
native artifact hash
    +
cross-runtime semantic corpus
    +
external checker stream hash
~~~

Fixed point remains evidence of bootstrap closure.

It is not a soundness proof.

---

# 38. Auditability target

A reader should be able to answer:

~~~text
What theory rule is this?
Where is Lean 4.34's behavior?
Where is PSKernel's implementation?
What trust class is it?
What tests exercise it?
What adversarial test exists?
What independent checker confirms it?
What theorem verifies it?
~~~

without searching the entire repository manually.

Required generated indexes:

~~~text
KERNEL_RULE_REFERENCE.md
TCB_REFERENCE.md
ARCHITECTURE_REFERENCE.md
ASSURANCE_REPORT.md
~~~

These should be generated from machine manifests where possible.

---

# 39. Novelty target

Do not seek novelty by changing Lean's logic.

The high-value novelty is architectural:

~~~text
one PSC1-self-hostable semantic source
+
native + JavaScript execution
+
machine-readable trust model
+
formal specification/refinement track
+
independent checker consensus
+
Lean-compatible proof stream
+
adversarial continuous differential testing
+
content-addressed checking receipts
~~~

This is a more durable contribution than introducing a novel definitional-equality rule.

---

# 40. Final target repository structure

Recommended workspace-level view:

~~~text
psc15selfhost/
|
+-- packages/
|   '-- pskernel-core/
|       +-- src/Ps/KernelCore/
|       |   +-- Core/
|       |   +-- Runtime/
|       |   +-- Environment/
|       |   +-- Checker/
|       |   +-- Admission/
|       |   +-- API/
|       |   '-- SelfHost.lean
|       |
|       +-- PSKERNEL_REFERENCE.md
|       +-- PSKERNEL_CORE_ARCHITECTURE.md
|       +-- KERNEL_THEORY.md
|       +-- PERFORMANCE_BASELINE.md
|       +-- LEAN_4_34_COMPATIBILITY.json
|       +-- LEAN_4_34_CONFORMANCE.json
|       +-- LEAN_4_34_KERNEL_RULES.json
|       +-- PSKERNEL_ARCHITECTURE.json
|       '-- PSKERNEL_TCB.json
|
+-- assurance/
|   '-- pskernel/
|       +-- Spec/
|       +-- Verify/
|       +-- Oracle/
|       +-- Arena/
|       +-- Fuzz/
|       +-- Interop/
|       '-- Reports/
|
+-- test/
|   '-- KernelCore/
|       +-- Fixtures/
|       +-- Conformance/
|       +-- Hardening/
|       +-- Oracle/
|       +-- Runtime/
|       +-- Architecture/
|       '-- Main.lean
|
'-- bench/
    '-- KernelCore/
        +-- Harness.lean
        +-- Environment.lean
        +-- Inference.lean
        +-- Whnf.lean
        +-- DefEq.lean
        +-- Recursor.lean
        +-- Inductive.lean
        +-- Mutual.lean
        +-- Nested.lean
        '-- Main.lean
~~~

---

# 41. Final public API

Target public contract:

~~~text
KernelContract-v1
~~~

Public concepts:

~~~text
TargetIdentity
KernelOutcome
KernelError
ResourcePolicy
KernelSession
CheckedDeclaration
AdmissionResult
ProviderCapability
CheckingReceipt
~~~

Important type-level distinction:

~~~text
constructed/requested
!=
checked
!=
admitted
~~~

A value named Ready must never ambiguously mean "syntactically prepared" and "kernel checked".

---

# 42. Formal proof strategy and independence

A proof about PSKernel written in Lean is valuable but shares some execution foundations with the system being modeled.

For strongest independence, the long-term formal theory/refinement track should consider a second prover such as Rocq.

Possible staged strategy:

~~~text
Lean-hosted local invariants
    for fast development

independent Rocq formalization/refinement
    for high-assurance milestones
~~~

Do not duplicate the production checker.

Duplicate only the abstract semantics/proof layer where independence is the purpose.

---

# 43. Consensus is not fallback

This distinction is permanent.

Bad:

~~~text
PSKernel rejects
    ->
try official Lean
    ->
official accepts
    ->
accept anyway
~~~

Good high-assurance mode:

~~~text
run all requested checkers independently
    |
    +-- all satisfy required consensus
    |       -> assurance result accepted
    |
    '-- disagreement/decline
            -> no consensus claim
~~~

Production semantic authority remains explicitly configured.

---

# 44. Performance experimentation rule

Alternative execution strategies such as:

- lazy abstract machines;
- graph reduction;
- different sharing;
- parallel checking;

may live in experimental branches/tools.

They become production only when:

1. acceptance/rejection parity is demonstrated;
2. adversarial corpus is green;
3. resource behavior is understood;
4. architecture owner remains unique;
5. source becomes the one canonical production implementation.

Do not permanently maintain "slow correct" and "fast semantic" production forks.

---

# 45. Current implementation scorecard

Approximate current score under the requested criteria:

| Criterion | Current implementation |
| --- | ---: |
| Soundness/fidelity | 8.8 |
| TCB transparency | 8.5 |
| Formal/metatheoretic verification | 5.5 |
| Adversarial robustness | 8.3 |
| Compatibility completeness | 8.8 |
| Architecture | 8.7 |
| Independent evidence | 6.8 |
| Performance | 7.8 |
| Resource behavior | 8.3 |
| Portability | 9.3 |
| Longevity | 8.1 |
| Interoperability | 7.4 |
| Self-host/bootstrap | 9.5 |
| Auditability | 8.6 |
| Novelty | 9.2 |

Arithmetic mean:

~~~text
8.24 / 10
~~~

This score is intentionally conservative.

---

# 46. Previous planned architecture scorecard

The previous PSKERNEL_REFERENCE plan improved source architecture substantially but did not yet make formal assurance and external verifier diversity first-class.

| Criterion | Previous plan |
| --- | ---: |
| Soundness/fidelity | 9.7 |
| TCB transparency | 9.8 |
| Formal/metatheoretic verification | 6.5 |
| Adversarial robustness | 9.3 |
| Compatibility completeness | 9.9 |
| Architecture | 9.9 |
| Independent evidence | 8.8 |
| Performance | 9.1 |
| Resource behavior | 9.3 |
| Portability | 9.9 |
| Longevity | 9.6 |
| Interoperability | 8.8 |
| Self-host/bootstrap | 10.0 |
| Auditability | 9.9 |
| Novelty | 9.8 |

Arithmetic mean:

~~~text
9.35 / 10
~~~

This explains why an architecture-only 9.90 score did not imply a 9.90 overall kernel design.

---

# 47. Iteration 1 score

Iteration 1 added:

- Assurance Plane;
- formal specification track;
- permanent hardening corpus;
- proof-stream manifest;
- explicit resource policy;
- architecture and TCB manifests.

Result:

~~~text
9.73 / 10
~~~

Main remaining gaps:

- formal refinement not strong enough;
- external implementation diversity not a release requirement;
- semantic target and host runtime not fully separated;
- interoperability still too project-specific.

---

# 48. Iteration 2 score

Iteration 2 added:

- independent checker consensus;
- logical versus execution TCB;
- semantic-role versus trust-status classification;
- host-runtime receipts;
- official Lean + clean-room checker release gates;
- standard Lean export stream preference;
- cross-runtime native/JS evidence.

Result:

~~~text
9.87 / 10
~~~

Still below the requested threshold.

Main remaining gaps:

- formal checker-refinement end state needed to be explicit;
- long-term execution diversity needed release semantics;
- performance/refinement promotion requirements needed strengthening.

---

# 49. Iteration 3 — final target score

Final iteration adds:

- machine-checked soundness/refinement target;
- acceleration refinement obligations;
- model/independent checker assurance;
- consensus release profile;
- content-addressed receipts;
- stable interoperable export envelope;
- target-profile longevity model;
- adversarial differential fuzzing;
- execution-runtime diversity;
- explicit promotion rules for alternate reduction machines.

Final score:

| Criterion | Final target |
| --- | ---: |
| Soundness/fidelity | **10.0** |
| TCB transparency | **10.0** |
| Formal/metatheoretic verification | **9.9** |
| Adversarial robustness | **10.0** |
| Compatibility completeness | **10.0** |
| Architecture | **10.0** |
| Independent evidence | **10.0** |
| Performance | **9.8** |
| Resource behavior | **9.9** |
| Portability | **10.0** |
| Longevity | **9.9** |
| Interoperability | **9.9** |
| Self-host/bootstrap | **10.0** |
| Auditability | **10.0** |
| Novelty | **10.0** |

Arithmetic mean:

~~~text
9.96 / 10
~~~

Minimum individual criterion:

~~~text
9.8
~~~

The requested threshold is therefore reached.

Again:

~~~text
this is a score for the final planned architecture if implemented,
not the current repository state.
~~~

---

# 50. Why performance is not scored 10

A design document cannot guarantee world-leading performance.

Current external checkers demonstrate that:

- lazy abstract-machine execution can beat official Lean on important workloads;
- targeted parallelism can produce very large throughput gains;
- different reduction strategies have workload-dependent tradeoffs.

The correct target is:

~~~text
semantically exact
resource robust
competitive
profiling-driven
open to proven execution improvements
~~~

not:

~~~text
guaranteed fastest checker.
~~~

---

# 51. Why formal verification is not scored 10

Even after a full checker soundness/refinement proof, residual assumptions remain:

- proof assistant consistency;
- formal model assumptions;
- extraction/compiler correctness if extraction is used;
- hardware/runtime behavior;
- target-specific trusted capabilities;
- serialization/parser correspondence.

Candle shows the kind of end-to-end work required to approach an actual 10.

PSKernel's 9.9 formal-verification target is intentionally ambitious without claiming absolute machine-code verification.

---

# 52. Promotion gates for the final architecture

A production release must require:

## Semantic gates

- exact target pin;
- compatibility complete;
- fine-grained rule registry complete;
- conformance complete;
- no known false accept.

## Portable-source gates

- portable profile;
- PSC1 check;
- canonical ProofScript recheck;
- semantic-root closure audit.

## Architecture gates

- architecture manifest valid;
- import fence valid;
- no Compat/reference/test dependency in semantic root;
- unique semantic ownership.

## Robustness gates

- historical hardening corpus;
- Kernel Arena corpus or pinned equivalent;
- differential fuzz corpus;
- resource attack corpus.

## Oracle gates

- official Lean parity;
- independent checker parity on supported corpus;
- verified/model checker parity where supported.

## Runtime gates

- native semantic corpus;
- JS semantic corpus;
- host-runtime identity recorded;
- no unexplained cross-runtime divergence.

## Performance gates

- benchmark regression budget;
- memory budget;
- stack/depth budget;
- representative whole-project runs.

## Assurance gates

- formal proof obligations appropriate to milestone;
- TCB manifest;
- checking receipts;
- divergence registry empty or explicitly accepted.

---

# 53. Suggested migration order

Do not start with formal verification or environment representation changes.

Recommended order:

~~~text
M0  freeze green baseline

M1  split test and benchmark monoliths

M2  add PSKERNEL_ARCHITECTURE.json

M3  add import-fence and semantic-closure CI

M4  reorganize Core / Runtime / Environment paths

M5  reorganize Checker and introduce one Checker/Knot owner

M6  unify Admission/Inductive hierarchy

M7  isolate CachePolicy and Lean434 native capability

M8  add typed KernelOutcome and ResourcePolicy

M9  establish KernelContract-v1 public boundary

M10 add fine-grained LEAN_4_34_KERNEL_RULES.json

M11 strengthen official-Lean direct oracle suite

M12 import pinned Kernel Arena hardening corpus

M13 add external independent-checker CI

M14 add export manifest and checking receipt

M15 start formal Spec/Verify track

M16 add differential fuzzing

M17 establish cross-runtime native/JS release corpus

M18 remove migration Compat shims

M19 evaluate alternate reduction-machine experiments only after profiling

M20 promote formal refinement milestones
~~~

Each commit should separate:

~~~text
move
semantic change
performance change
test change
formal proof change
~~~

whenever possible.

---

# 54. What PSKernel should not do

Do not:

- invent a new core logic merely for novelty;
- add Cubical or rewrite-rule semantics to a Lean 4.34 compatibility profile;
- keep multiple production semantic implementations;
- treat independent checkers as fallback acceptors;
- call caches "outside the TCB" merely because they are intended to be semantic-preserving;
- depend on generated JS patches;
- optimize by changing observable defeq order without evidence;
- mix runtime security upgrades with semantic target changes;
- confuse self-host fixed point with soundness proof;
- confuse passing one large project with compatibility completeness;
- hardcode future Lean version behavior into the current 4.34 profile.

---

# 55. Final design philosophy

The best long-term PSKernel is not:

~~~text
Lean rewritten in another style.
~~~

It is:

~~~text
a versioned, self-hostable Lean kernel implementation
whose trust boundaries are explicit,
whose executable source is portable,
whose proof streams are interoperable,
whose behavior is adversarially cross-checked,
whose critical algorithms are formally connected to a specification,
and whose runtime can evolve without silently changing the logic.
~~~

The central rule is:

~~~text
Make the trust graph, dependency graph, proof-evidence graph,
and source tree tell the same story.
~~~

---

# 56. Source references

## Lean 4

Exact Lean 4.34.0 kernel source:

https://github.com/leanprover/lean4/tree/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel

Key files:

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/type_checker.cpp

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/type_checker.h

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/inductive.cpp

https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel/environment.cpp

Lean 4.34 release hardening:

https://lean-lang.org/doc/reference/latest/releases/v4.34.0/

Lean 4.34.1 runtime hardening:

https://lean-lang.org/doc/reference/latest/releases/v4.34.1/

Lean 4.35 native-reduction removal:

https://lean-lang.org/doc/reference/latest/releases/v4.35.0/

Lean type system:

https://lean-lang.org/doc/reference/latest/The-Type-System/

Lean inductives:

https://lean-lang.org/doc/reference/latest/The-Type-System/Inductive-Types/

High-risk proof validation:

https://lean-lang.org/doc/reference/latest/ValidatingProofs/

Lean Kernel Arena:

https://arena.lean-lang.org/

Arena repository:

https://github.com/leanprover/lean-kernel-arena

## Rocq / MetaCoq

Rocq kernel/core language:

https://github.com/rocq-prover/rocq/blob/master/doc/sphinx/language/core/index.rst

Rocq CIC:

https://github.com/rocq-prover/rocq/blob/master/doc/sphinx/language/cic.rst

MetaCoq:

https://github.com/MetaCoq/metacoq

## Isabelle

Isabelle implementation logic:

https://isabelle.in.tum.de/website-Isabelle2025/dist/library/Doc/Implementation/Logic.html

## HOL Light / Candle

HOL Light kernel:

https://github.com/jrh13/hol-light/blob/master/fusion.ml

Candle:

https://cakeml.org/candle/

Candle paper:

https://link.springer.com/article/10.1007/s10817-025-09743-8

## Metamath

https://us.metamath.org/

https://us.metamath.org/mm_100.html

## Agda

https://agda.readthedocs.io/en/latest/getting-started/what-is-agda.html

https://agda.readthedocs.io/en/latest/language/cubical.html

https://agda.readthedocs.io/en/latest/language/termination-checking.html

## Lambdapi / Dedukti

https://lambdapi.readthedocs.io/en/latest/about.html

https://github.com/Deducteam/Dedukti

## McTT

https://icfp25.sigplan.org/details/icfp-2025-papers/7/McTT-A-Verified-Kernel-for-a-Proof-Assistant

## Lean-compatible independent checkers

Lean4Lean:

https://github.com/digama0/lean4lean

Nanoda:

https://arena.lean-lang.org/checker/nanoda/

ConLeche:

https://github.com/leanprover/con-leche

eink0rn:

https://arena.lean-lang.org/checker/eink0rn/

lazylean:

https://arena.lean-lang.org/checker/lazylean/

MathGraph:

https://arena.lean-lang.org/checker/mathgraph/
