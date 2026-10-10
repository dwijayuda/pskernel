# PSKernel-Fast V2 — Major Architecture Redesign for Performance and Correctness

> **SUPERSEDED FOR NEW DEVELOPMENT (2026-10-11):** V2 is a historical design study, not binding project architecture. Its requirements to preserve the old checker, proof continuity, previous source interfaces, or current self-host constraints have been explicitly retired by the user. The authoritative performance-and-correctness-first V3 is [`pskernel-fast/ARCHITECTURE_V3.md`](../pskernel-fast/ARCHITECTURE_V3.md); the independent implementation is [`pskernel-fast/`](../pskernel-fast). Reuse older proofs or source only when that independently improves correctness, performance or auditability. The active proof branch and PR #89 are not edited by this supersession.
 
> **Decision status:** architectural proposal / research, not a production checker implementation or completed soundness proof.
>
> **Repository:** https://github.com/dwijayuda/pskernel
>
> **Design branch:** `research/pskernel-fast-major-v2-20261011`.
>
> **Current active implementation baseline observed:** `psc0/pskernel-core-lean435-arena-v1` at `1b517b7498a19436ec496dea0106845d30647c4d` (11 October 2026).
>
> **Pinned formal compatibility target:** Lean `4.35.0-rc4`, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
>
> **Scope:** major design freedom for `pskernel-fast` while retaining exact Lean behavior, modeled assumptions, self-host goals and independent evidence. Nothing in this proposal changes the active proof branch, its draft PR #89, or the current production kernel.

## 0. Executive architecture decision

**YES: permit a major, correctness-guided architectural reconstruction**, rather than limiting PSKernel-Fast to caches and local functions. The ideal design is a **small logical core plus one performance-oriented, proof-related executable kernel**.

The most valuable architecture is a combination of:

1. **Explicit correctness boundary:** untrusted raw syntax -> scoped, validated core expressions -> checked, provenance-carrying results -> atomic declaration admission.
2. **Compact shared term representation:** immutable hash-consed expression/universe/name DAG and opaque bounded handles, with exact decode/erasure. Retain raw expression syntax at the API/boundary; do not require apps/plugins to manipulate internal handles.
3. **Lazy closure-based WHNF:** avoid allocating newly instantiated trees during common beta/let reductions; maintain immutable environments and neutral application spines.
4. **Official-compatible, typed definitional equality:** transparent scheduling of cheap rigid conversion, guarded proof irrelevance, lazy delta, quotient/primitive reductions, recursors, eta and dependent binder rules.
5. **Separated lifetimes and immutable admission transactions:** permanent validated environment, scope/session caches, scratch reduction values; no unchecked or scratch references survive checked admission.
6. **A small abstract mathematical specification and systematic refinement proofs:** actual executable checking -> modeled typed judgments -> constructive declaration-model extension -> conditional consistency theorem. Treat reference and optimized representations as theorem-related, not two unrelated sources of trusted proof acceptance.
7. **One maintained semantic source for native and future self-hosted portable targets.** Development may maintain an old frozen oracle and an experimental new checker temporarily, but only one semantic checker is promoted as production authority.

**What changes from the previous PSKERNEL_FAST_ARCHITECTURE.md:** do **not** treat `Checker/Knot.lean`, the recursive tree representation or the current cache layout as permanent design constraints. They remain frozen baselines to relate against. The architecture is permitted to replace the recursive callback knot, checker state and internal expression representation **if and only if** source-level semantics and ongoing proof artifacts are preserved through an explicit migration/refinement strategy.

**Central principle:** we are free to radically change the *algorithm and representation*, **not** Lean's logic, the public meaning of successful admission or the visibility of the trusted computing base.

## 1. Why a major redesign is reasonable now

### 1.1 Live source measurements (GitHub tree; not performance metrics)

From the active branch's pinned `src` subtree (Git tree `a5b3a5608c9891ba8e417bfb3697c51f6e71f244`):

- **92** `.lean` source files and **935,471 bytes** of Lean source.
- The metatheory subtree (Git tree `ee07535d2b7ac7e3b88be0b50c2a4377f7882f2c`) contains **182** `.lean` files and **3,177,552 bytes** of Lean proof source.
- File count/bytes do **not** equal transitive trusted-base LOC. Native Lean runtime, export adapter, generated runtime and trusted capabilities must be inventoried separately.
- Actual recent proof HEAD `1b517b7` extends a concrete fresh-constant/theorem model argument, but does not establish the whole kernel acceptance-to-model theorem; do not infer its CI status without inspecting the corresponding completed job.

A future greenfield rewrite would risk losing years-equivalent proof effort. Yet the current source is already too substantial to assume “small kernel” just from a single semantic source. A targeted architectural reconstruction could **remove repeated logic and reduce proof maintenance**, but this is a design hypothesis to be tested, not a promised LOC reduction.

### 1.2 Current code-level constraints

The active source uses:

- `PsKernelExpr`: recursively nested algebraic expressions (`bvar`, `fvar`, `mvar`, `sort`, `const`, `app`, `lam`, `forallE`, `letE`, `lit`, `mdata`, `proj`). Core literals use `Nat` / `String`; constant level arguments use lists. [Source](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/src/Ps/KernelCore/Core/Expr/Basic.lean).
- `Checker/Knot.lean`: deeply recursive fuel-based wiring of inference, WHNF, recursors, projections and DefEq callbacks. A proof-friendly structural recursion technique in the current code, but potentially high interpreter/allocation overhead. **Needs profiling, not assumptions.** [Source](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/src/Ps/KernelCore/Checker/Knot.lean).
- `Checker/State.lean`: separate inference-only/checked, WHNF, unfold, positive and negative DefEq caches with a fresh-name counter. The current scope-exit function deliberately drops local semantic cache additions because raw free-variable names can be forged at public boundaries. This is an important correctness pressure on reuse across scopes. [Source](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/src/Ps/KernelCore/Checker/State.lean).
- `Runtime/Acceleration/Cache.lean`: hash-indexed expression maps with recursive structural hashing and a small hash modulus (65521). This is a **candidate** for measured CPU/memory cost, not proof of a bottleneck. Exact equality must always settle collisions. [Source](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/src/Ps/KernelCore/Runtime/Acceleration/Cache.lean).
- `Core/Expr/Shared.lean`: a **recent proof-carrying shared traversal with memoization**; do NOT claim the whole codebase lacks sharing or throw away an existing verified optimization. [Source](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/src/Ps/KernelCore/Core/Expr/Shared.lean).
- `Core/AnnotatedExpr.lean`: a separate full syntax tree augmented with binder range-sort information, plus erasure and substitution functions. It is a useful model proof layer but can multiply traversals and annotation-provenance obligations if converted back and forth at runtime. [Source](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/src/Ps/KernelCore/Core/AnnotatedExpr.lean).
- `Checker/Inference/Core.lean`: a `Bool`-graded infer-only / fully checked path returning raw expressions through `Except String` and explicit threaded state; full type/annotation witnesses do not yet propagate across all recursive calls. [Source](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/src/Ps/KernelCore/Checker/Inference/Core.lean).

None of these facts alone proves a performance defect. Together they justify testing whether a different representation and proof-facing API would be **simpler to reason about and faster on real large proofs**.

### 1.3 Current correctness gaps that architecture must *directly* address

As recorded in [active architecture](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/PSKERNEL_CORE_ARCHITECTURE.md) and [proof work state](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/AI_WORK_STATE.md):

1. Preserve the **actual selected** binder-sort/annotation reading across inference -> WHNF -> DefEq, not a guessed annotation chosen after the check.
2. Distinguish checked and infer-only results at type level or an unmistakably enforced mode invariant.
3. Prevent structural/quick equality from bypassing required universe-regime coherence, proof-irrelevance type checks, or soundness obligations.
4. Establish a real joint recursive soundness argument and scope/alloc/counter invariants.
5. Construct an extension of the semantic environment model for each newly admitted fresh name. Do not assume the new constant was modeled in an arbitrary fixed interpretation.
6. Prove inductive/recursor/quotient/primitive admission preserves the model and state the permitted/assumed axiom policy.
7. Derive the public conditional no-*derived*-`False` result only with explicit model foundations. Ordinary Lean mode permits arbitrary declared axioms, including an axiom of `False`, so unconditional consistency would be wrong.
8. Connect any fast representation to that **actual executable accepting path**, not a proof-friendly but unused shadow checker.

This is a rare opportunity to make the public soundness theorem **an architectural API requirement** rather than retrofitting checker-wide invariants afterward.

## 2. Options comparison

The following are relative engineering judgments, NOT benchmark results or quantified risk probabilities.

| Candidate | Performance ceiling | Small, auditable TCB | Continuity of existing proofs | Self-host portability | Assessment |
| --- | --- | --- | --- | --- | --- |
| A. Keep existing recursive tree/checker; optimize maps/spines | Medium | Medium | Excellent | Best immediate | Good low-risk fallback; may not reach leading Arena performance |
| **B. New internal compact DAG + typed checked results + lazy closure evaluator; one semantic authority** | **High** | **Potentially high after removing duplicated code** | Moderate with staged erasure/refinement | Achievable with careful source features | **Recommended V2** |
| C. Full new NbE/type checker and proof work from scratch | Potentially very high | Initially poor; later unknown | Very poor | High uncertainty | Do not big-bang replace production |
| D. Embed official Lean kernel C++ as authority and wrap it | Official performance baseline | Small ProofScript-specific code, larger external TCB | Existing PSKernel theorem track bypassed | Low for JS/native parity | Useful compatibility oracle, not the self-hostable goal |
| E. Port MathGraph or con-ron Rust directly as a separate PSKernel | High measured candidate performance | Larger dual-source TCB | Very poor | Poor | Reject as *canonical* production path; study algorithms |

**B is preferred because it changes the architecture enough to unlock performance yet permits precise erasure/simulation links to old code and the developing correctness model.** However, if early tests show the new DAG or closures are not the bottleneck, retain A rather than force the rewrite.

## 3. Primary research behind the redesign

- [Lean 4.35 official kernel](https://github.com/leanprover/lean4/tree/v4.35.0-rc4/src/kernel): inference and DefEq are not one generic normalizer; the ordered cheap WHNF, proof irrelevance, lazy δ, recursors, projections, eta and primitive operations are important to compatibility and cost.
- [MathGraph](https://github.com/metalogiclabs/mathgraph-lean-kernel): closure/value-based evaluation and selective conversion are extremely effective on the current Arena Mathlib export; MathGraph is not independent from sokonanoda.
- [nanoclo](https://github.com/sgraf812/nanoclo): interned closure environments and read-set-sensitive caching.
- [nanobruijn](https://github.com/nomeata/nanobruijn): lazy shifts and shareable DAG modulo binder depth; **do not** adopt a new bound-variable representation without exact scope/reification proof.
- [lazylean](https://github.com/corun1024/lazylean): call-by-need and memory-bounded sessions can drastically help computation-heavy reflective proofs. Its README's newer performance claims are not directly comparable to the current Arena's older 0.3.0 benchmark.
- [con-ron](https://github.com/leanprover/con-ron): compact per-constructor arrays, tagged handles, permanent/scratch arenas and a two-step machine-checked refinement chain between different representations.
- [con-leche](https://github.com/leanprover/con-leche): soundness against a set-theoretic model with explicit assumptions and a restricted verified axiom policy.
- [Courant and Leroy, “A Lazy, Concurrent Convertibility Checker”, POPL 2026](https://doi.org/10.1145/3776695): laziness plus interleaved/parallel exploration of convertibility subproblems can avoid pathological heuristic schedules. The paper studies and partially verifies a proposed algorithm; **not** an off-the-shelf theorem of correct Lean 4.35 checking.
- [Lean Kernel Arena](https://arena.lean-lang.org/): conversion heuristic order and proof irrelevance materially change cost; soundness negative examples include recursor and propositional-structure corner cases.

A **big architecture change is evidence-backed**, but it must be proven and measured on the actual PSKernel source, not justified by assuming that an unrelated Rust implementation's speedup transfers to generated Lean/JavaScript.


## 4. Proposed production architecture: one trusted checker

~~~text
untrusted Lean/ProofScript declarations
          |
   Host/ProtocolDecoder (not proof authority)
          |
    RawExpr / RawDecl
          |
   Decode + ValidateScope
          |
    CoreExprId (immutable, shared, validated DAG)
          |
    Kernel/Check      [one accepting checker]
       /      \
   WHNF        DefEq/Convert
  closures     guarded proof irrelevance
  neutrals     lazy delta and eta
  recursors    exact type/universe checks
       \      /
      CheckedResult | typed KernelFailure
                |
      Admission/Transaction
                |
      immutable admitted Env snapshot

Formal artifacts: model + erasure/refinement +
                  actual public acceptance soundness
                  (outside production runtime)
~~~

### 4.1 Canonical ownership

| Component | Owns | Does NOT own | Interface |
| --- | --- | --- | --- |
| Protocol/Host | Decoding, exporter identity, formats, resource isolation | Proof verdict or kernel axioms | Validated input and exact replay |
| Core/Representation | Names, universe levels, shared expression DAG, scope metadata | Definitional equality or declaration acceptance | Decode/encode and scope proofs |
| Engine/CheckedJudgments | Infer/check, WHNF, DefEq, resource/checked-mode rules | Unchecked env mutation | Grade-aware executable judgments |
| Admission/Environment | Checked declarations, positivity, recursors, quotients, atomic transactions | Foreign proof acceptance | Checked environment invariant |
| Assurance (proof-only) | Operational refinement, modeled type theory, relative consistency | Trusted runtime checking implementation | Public acceptance theorem |

A separate mathematical specification or frozen test oracle is compatible with **one production checker**. A second independent runtime capable of accepting declarations is not.

### 4.2 Compact expression DAG without changing external Lean syntax

The public input remains raw expressions with Lean-compatible constructors. Internally:

~~~text
RawExpr -> scope/level validation -> CoreExprId -> NodeStore

CoreExprId := opaque, bounds-checked handle
NodeView   := BVar | Sort | Const | App | Lam | Pi
           | Let | Lit | MData | Proj | internal FVar
NodeStore  := immutable, collision-checked interning
~~~

Representation invariants:

1. Any live ID references a node with the correct store identity, generation, constructor tag and bounds.
2. Two identical IDs denote **exactly the same syntax**, never merely the same hash. Hash collisions trigger complete key equality.
3. Universe levels and binder annotations participate in the canonical node identity.
4. Permanent admitted declarations must not point to invalidated scratch handles.
5. A raw free variable cannot masquerade as a scoped internal local identifier.
6. Tagged 32-bit or 64-bit handles are OPTIONAL backend encodings. Logical IDs are abstract and checked for overflow; no wraparound can change expression meaning.
7. Public callers cannot forge an internal validated handle to bypass checking. In a hostile-plugin environment, process/Wasm isolation is still required; language-level private fields alone are not a security sandbox.

**Schematic theorem obligations** (not yet proved):

~~~text
decodeEncode: WellFormed e -> decode(encode(e)) = e
internSound: valid(id) -> decode(id) = originalExpr(id)
scopePreserved: validScoped(id, Γ) -> scoped(decode(id), Γ)
scratchNoEscape: successfulCommit(txn) -> all published IDs permanent
collisionSafe: intern(x) = intern(y) -> x = y
~~~

Existing proof-backed shared syntax traversal in `Core/Expr/Shared.lean` should be reused as an erasure/reference bridge; do not discard it merely because a packed DAG is attractive.

### 4.3 Actual checked results and annotation provenance

Currently raw expressions can circulate among inference, WHNF and DefEq before the full selected annotation/provenance theorem is established. V2 should provide a single explicit return carrier:

~~~text
CheckGrade := InferOnly | FullyChecked

CheckResult := {
  expression: CoreExprId,
  inferredType: CoreExprId,
  grade: CheckGrade,
  environmentEpoch: EnvEpoch,
  scopedLocalContext: ContextId,
  checkedUniverseParameters: LevelParamsId,
  witnessedBinderSorts: ValidatedObservationMap
}
~~~

This is a design sketch, not compiled source syntax or user-creatable proof evidence. The `FullyChecked` grade must be earned by the actual checker. An infer-only result cannot be treated as fully checked. Binder range sorts must be carried from the **actual successful sort-exposure visits** and agree with universe-zero/positive interpretation.

The theorem to target is not existentially choosing an annotation after raw checker success; it is connecting **the exact selected reading returned by the executed checker** to the semantic model. Unchecked raw structural equality and bare proof-irrelevance guesses cannot authorize success.

### 4.4 Typed failures and explicit resource discipline

Replace internal `Except String` with an error sum, preserving external contract classification exactly:

~~~text
KernelFailure :=
  RejectedInvalid(rule, position)
  DeclinedUnsupported(feature, target)
  ResourceExhausted(kind, budget)
  InternalInvariantError(identifier)
~~~

Resource policy includes fuel/work units, recursion depth, heap and host process memory/stack limits. A pure kernel function cannot promise to catch host OOM; the host must translate termination into nonacceptance. No unsupported/resource/internal outcome can be promoted into success by another provider.

### 4.5 Atomic environment transactions and consistency modes

~~~text
already checked immutable Env
    |
begin transaction -> check fresh names / universe params / type and body
    |
validate positivity / constructors / recursor rules / quotients
    |
check all newly generated declarations as one batch
    |
commit ALL or NONE
~~~

Inductives and recursors must be generated/validated by the kernel, not accepted as unchecked exporter metadata. Proof/definition and axiom policies are different. An ordinary Lean-compatible checker may allow arbitrary axioms, including an axiom of `False`. A verified-model mode must constrain or explicitly assume their interpretations; no general unconditional consistency theorem is possible.

**Model extension blocker:** fresh constant admission requires constructing an extended model with the new name interpreted, preserving all prior name interpretations and the reserved `False` interpretation. The V2 admission interface must make this a first-class proof goal rather than postulating an already-correct `StoredConstantModeled` fact for arbitrary models.

## 5. High-performance evaluation and definitional equality

### 5.1 Lazy closure-based weak-head evaluator

The engine should evaluate **only what a checking rule demands**. Design value shapes:

~~~text
EvalValue :=
  Sort(universeLevel)
  Pi(domain, closureForCodomain)
  Lam(domain, closureForBody)
  Neutral(head, argumentSpine)
  Constructor(checkedName, levels, argumentSpine)
  Literal(checkedNatOrString)
  Thunk(term, exactEnvironment, forceState)

Closure := (CoreExprId, EnvId, LevelSubstId, ScopeId)
~~~

For **beta**, extend an environment rather than eagerly rebuilding the lambda body. For **let**, retain a lazily forced binder value. For **neutral terms**, compare rigid head and selective spine arguments instead of constructing full normal forms. For **delta**, respect declaration reducibility hints, bound unfolding, and stay folded until needed. For **recursors and projections**, reduce only when canonical conditions and major premises justify it.

A closure evaluator **is not another trusted kernel**: it runs under the one checker and must be proved to implement the relevant weak-head semantic judgments. If an optimization cannot decide the comparison, return an internal `Unknown` and continue the canonical rule path; do not manufacture Equal or a false rejection.

### 5.2 Correctness-first DefEq stage ordering

Conceptual strategy (NOT complete implementation):

~~~text
convert(Γ, typeWitness, lhs, rhs):
  check target, resources, scoped environment and validity
  if exact validated syntax identity: Equal
  if guarded proven positive conversion cache: Equal
  if both values are proven proofs of the same proposition: Equal
  compare same rigid heads and necessary neutral-spine arguments
  run cheap beta / zeta / iota / projection exposure
  use lazy constant unfolding with official reducibility hints
  apply only verified projection, recursor, K, quotient and eta rules
  handle type-directed Nat/String primitive reductions
  retry legal remaining cases; otherwise report NotEqual/Unknown
~~~

The actual pinned Lean 4.35 conversion algorithm uses a particular combination and order of these rules. The sketch above is an **optimization research direction**, not a substitute for the exact rule map or a correctness argument for arbitrary reordering. No shortcut should equate terms before required type and binder universe-regime checks.

The [Lean Kernel Arena conversion tests](https://arena.lean-lang.org/) explicitly exercise pathological order choices: expensive unfolding before comparing cheap rigid arguments, evaluation of an irrelevant proof before noticing proof irrelevance, eager projection, exponential repeated subproblems and conversion failures. Optimize **algorithm families**, never patches tailored to single benchmark names.

**Important:** do **not** introduce unconstrained union-find/e-graph transitive closure of algorithmic DefEq results. Lean's implemented algorithmic conversion has known incompleteness/transitivity subtleties in corner cases; a graph closure of results without a theorem can create false proofs. Interning identical raw syntax is fundamentally different from asserting arbitrary definitional equality.

### 5.3 Optional explicit work machine

The existing `Checker/Knot` uses fuel-indexed recursive callbacks. A potential major improvement is a typed continuation/worklist machine:

~~~text
WorkItem :=
    Infer(expression, grade, localContext)
  | Reduce(valueClosure, reductionMode)
  | Compare(leftValue, rightValue, typeEvidence)
  | CheckRecursor(recInfo, major, localContext)

MachineState :=
  immutableEnvironment
  scopedContext
  typedWorkStack
  boundedScratchAndCache
  exactSemanticBudget
~~~

**Potential benefits:** fewer higher-order closure allocations, iterative bounded stack use, explicit resource accounting, and a small set of transition invariants. **Potential drawbacks:** more continuation variants, worklist memory overhead and complex proofs about the order of reductions. Replace recursive knot only if profiling supports the decision AND a reference-machine simulation theorem exists.

The POPL 2026 [Courant–Leroy lazy/concurrent convertibility paper](https://doi.org/10.1145/3776695) suggests later fair interleaving or parallel exploration of expensive conversion alternatives, but its mechanized partial-correctness results are not ready-made Lean 4.35 kernel proofs. V2 starts with a deterministic single-threaded scheduler, not nondeterministic proof acceptance.

### 5.4 Memory and cache lifetimes

~~~text
PermanentEnvironment:
  checked declarations + trusted generated recursors
  interned names/levels/closed expressions

SessionCache:
  bounded, scope/epoch/level/transparency-aware entries
  separate inferOnly and checked
  whnf/constant unfolding, guarded positive DefEq

ScratchArena:
  forced closures and thunks
  neutral spines, temporary expansions
  provisional declarations
  released after a checked transaction
~~~

**Exact cache facts:**

| Cache | Minimal semantic identity | Non-negotiable invariant |
| --- | --- | --- |
| Checked inference | term, scoped context, env snapshot, universes, full-check grade | Never substitute infer-only success |
| Infer-only | term, context, env, universes, infer-only grade | Never conclude fully checked status |
| WHNF | term or closure + environment + scope + reduction policy + versions | Result refines canonical WHNF |
| DefEq positive | both terms, justified type/relevance, context, env, transparency and universe mode | Equal fact is proved under exact premises |
| DefEq negative | initially OFF | An early mismatch cannot bypass a later legal reduction |
| Closed constant unfold | declaration identity, instantiated universe levels and epoch | No stale definition change |
| Interned syntax | full structural key and exact collision check | Hash/key equality, not coincidentally equal hash |

Cache table addresses are not logical identities. A scratch handle from a previous generation can never authorize reuse of a positive proof result. Eviction and cache miss may change time, but cannot change accepted results.

### 5.5 Trust boundary and extension security

V2 must retain **sealed checked sessions** even when distributed through npm packages. A JavaScript, Rust, Wasm or Lean module providing a fast cache may suggest *candidate computations* but cannot append trusted declarations, install axioms or alter semantic rules. The kernel process / sandbox must validate the candidate under a trusted operation or use an already proved refinement.

Source-level visibility/private constructors are not a security boundary against malicious native code in the same process. For genuinely untrusted extensions use an isolated process or Wasm sandbox, an immutable checked input protocol and separate resource limits. Signed reports or type aliases do not certify a proof without a correctly enforced kernel boundary.

Avoid compiler/runtime “trusted reduction” escape hatches by default. A fast foreign evaluator is a TCB component unless its result is independently checked by trusted semantics or it is covered by a proved refinement and correctly implemented backend.

## 6. Formal architecture: specify once, prove execution

### 6.1 Separate the logical specification from production code

**Do not maintain two production semantic checkers.** Maintain:

1. A concise **mathematical specification** of expression typing, conversion, universes, inductive admission, quotient rules and axiom semantics.
2. One **executable checker** with concrete values/IDs/cache/resource strategy.
3. **Proofs/refinement relations** linking actual successful checking, result annotations, environment transitions and the mathematical model.
4. Independent *external implementations* (official Lean and selected checkers) used for differential evidence, not as an axiom of runtime correctness.

An optional pure executable reference for tests is not production authority, and its execution result is not a substitute for proving the optimized checker/model relation.

### 6.2 Required theorem chain

~~~text
Raw input / protocol
    |
  well-formed canonical decoding
    |
  CoreExpr representation invariant
    |
  optimized WHNF / DefEq / inference:
    accepted result refines the checked judgment
    |
  selected checked binder annotations preserved
    |
  actual declaration admission preserves model
    |
  constructive environment extension for new constants
    |
  explicit set-theory and allowed/modeled-axiom assumptions
    |
  relative no-derived-proof-of-False theorem
~~~

A final model theorem cannot follow from an incorrectly formulated typing/DefEq relation. The active branch already diagnosed an old equality specification in which too much equality was permitted; do not “verify” a faster checker against that defective relation.

### 6.3 Concrete proof obligations for migrating

| Structural change | Erasure/refinement proof before promotion |
| --- | --- |
| Raw syntax -> shared IDs | decoding/interning injectivity, exact scope, no lost binder/level metadata |
| Checked-result grade redesign | actual inference run produces same selected type and binder-sort reading; checked != infer-only |
| Binder local identity change | freshness, shadowing, scoped environment lookup and closing/opening correspond exactly |
| Lazy closure beta/let | forcing/quoting yields canonical WHNF semantics in same context/level substitution |
| New DefEq scheduler | every affirmative result sound, legal fallback preserved, proof irrelevance type-correct |
| Compact scratch stores | no untyped/stale/bounds-violating ID reaches checked persistent environment |
| Primitive arithmetic | identical 4.35 primitive computation and numeral/resource limits |
| Declaration and recursors | entire fresh batch checked, positivity/elimination validated, no partial commit |
| Axiom model | explicit modeled-axiom list, arbitrary-axiom mode distinguished |
| Generated backends | native/JS/Wasm artifacts preserve verdicts and numeric/stack semantics under stated host assumptions |

**Formal soundness vs official compatibility are not identical.** A proof that the new checker never derives False under a modeled axiom policy does not prove every Lean-valid source export is accepted. Full 4.35 algorithmic equivalence is also difficult because conversion is a partial/heuristic computation with explicit resource limits. Record source-rule compatibility plus differential tested positive/negative coverage, and state any supported/unsupported profile separately.

### 6.4 Preserve work without freezing flawed architecture

The active branch has extensive formal evidence but incomplete global theorems. Use **proof-guided dual development**, not a destructive merge:

- Freeze the old implementation at a pinned commit as a regression/differential oracle in Git history and tests.
- Construct the V2 modules in a separate branch; for a period both old and new can exist on that research branch **as test-only alternatives**. Only the designated current kernel authorizes production acceptance.
- Introduce a raw-term erasure/decoding bridge and a semantic model before replacing the core type checker.
- Close vertical proof slices for one expression family at a time (sort, variable, Pi/lambda, app, let, then reduction/defeq/recursors).
- Prove new result carrier obligations without inventing checked annotations from raw syntax.
- Bring in the existing model/consistency proof source by **matching theorem interfaces and source-rule facts**, not copying stale conclusions blindly.
- Promote the new V2 kernel only when its accepted proof domain has adequate verified/differential evidence and explicitly documented remaining gaps. Archive/retire the old production semantics at promotion; do not indefinitely maintain two competing authorities.

The existing PR #89 and live proof branch must remain intact. A performance experiment should not rewrite the current proof files or claim that a major schema migration has already closed full consistency.

## 7. Large-scale migration plan: architecture-first, bounded vertical slices

The project should allow major conceptual change, but **not a big-bang unqualified replacement**. The goal is to implement the new architecture family-by-family, with precise retained evidence and no test-specific rule patches.

| Phase | Work | Proof/checking exit gate | Perf/portability exit gate |
| --- | --- | --- | --- |
| **M0 — Design freeze and baseline** | Pin active HEAD, list trusted dependencies, recover precise source rule map and selected test corpus | No executable changes; proof obligations and axiom policy written | Reproducible native reference/cached profile, parse vs kernel split |
| **M1 — Correctness-shaped interface** | Introduce typed KernelFailure, explicit check grades, scope+annotation result carrier and atomic EnvTxn API | Erasure to existing checker results; fixed readings preserve actual observations; no new accepting shortcut | Minimal overhead/no major slowdown; source still builds |
| **M2 — Compact immutable CoreExpr store** | Add interned DAG behind RawExpr, canonical IDs, checked scratch/permanent lifetime | Round-trip, collision-safe injectivity, scope and scratch-escape invariants | Measured memory/lookup benefit; no claimed selfhost without gate |
| **M3 — Lazy WHNF and exact values** | Replace eager beta/let reconstruction with closure-backed WHNF; same canonical reduction owner | WHNF erasure/positive-result refinement; all official-compatible reductions and resource outcomes | Meaningful beta/let gain, bounded peak RSS |
| **M4 — Conversion engine rewrite** | Typed proof-irrel, lazy delta, rigid-spine comparison, eta, recursor and primitive handling; consider explicit work scheduler only if measured | No unsafe Equal; precise accepted DefEq theorem and checked annotation/coherence | Full focused conversion corpus and matched speedup |
| **M5 — Admission/model integration** | Preserve old checked API, integrate actual declaration model extension, induction and quotient proof | Conditional modeled public acceptance, exact axiom policy; remaining obligations auditable | Fresh pinned Lean 4.35 Init/Std and, eventually, Mathlib |
| **M6 — Portable self-host & release** | Qualify one source on Lean native and available PSC0-generated JS/Wasm paths; remove obsolete old semantic copy | Source/artifact parity, independent external checking and TCB audit | Exact-version full supported corpus, peak-RSS and throughput targets |

### M0 is mandatory even for an aggressive redesign

A major architecture should be selected on evidence. Profile today’s cost of:

- structural recursive expression equality, hash recursion and multi-level maps;
- actual memoized shared traversals (the certified fold already exists);
- beta/let instantiation, de Bruijn lifts and annotated-term reconstruction;
- higher-order fuel callbacks in `Checker/Knot` and repeated state copying;
- DefEq source-rule order, repeated infer-only versus checked exposure, local-context cache invalidation;
- induction and recursor checking, large Nat values, export parsing, GC and host serialization.

Only the top observed costs deserve replacement. If the current recursively boxed RawExpr already benefits greatly from structural sharing, V2 may discover that improving conversion scheduling or binder reading provides more value than switching to tagged IDs.

### M1: do not lose proofs while changing checked contracts

The **first correctness migration** should carry actual annotations and checked/infer-only grade through the existing runtime and prove the result agrees with old execution. Replacing raw expressions and DefEq in the same commit would entangle several proof failures and make source-level diagnosis difficult. Once M1 is stable, the new DAG can be behind an unchanged judgment boundary, making M2 representation proof more mechanical.

### M2–M4: new algorithm can coexist temporarily in tests

During redesign, keep `KernelV1` frozen in test/reference-only code, compare full typed outcomes and resource results with `KernelV2`, and link both to the pinned official Lean oracle. This **does not** require production builds to bundle two semantics. Once V2 has proven and measured acceptability, remove V1 from the runtime import closure.

### M5: do not postpone model correctness forever

The original project’s unfinished joint recursive soundness and fresh constant model-extension work are not solved simply by optimizing memory. Make them explicit phase gates; if runtime implementation advances beyond currently provable model cases, label the status **unverified**, not “model-sound”.

### M6: portable self-host constraints are real

The current PSC0 selected compiler/source reference and host toolchain are separately versioned from the experimental Lean 4.35 kernel. Do **not** assume that Lean 4.35 features such as specialized proof traversals, new packed arrays, `Squash`-dependent extracted algorithms or native pointer tricks are accepted by its bounded self-host language. Protect the future one-source goal using a plain, explicit CoreExpr interface and isolate backend-specific storage behind a narrow module.

Prefer Lean-native 4.35 first for algorithmic evidence. Generate/qualify JS and future Wasm **from the same maintained semantics**, and document any unsupported source feature or trusted native capability. The project must not claim self-host success without the actual current-source compiler qualification.

## 8. Benchmark and conformance plan

### 8.1 Provenance and measurement structure

Every benchmark reports:

~~~text
active PSKernel branch/commit; V2 branch/commit
Lean target version and Git SHA; exporter/tool version and schema
input hash and declaration count, including attempted/declined inputs
axiom/semantic profiles and resource limits
native compiler flags, CPU/core count, memory/OS details
parse/import time versus kernel-only inference/WHNF/DefEq/admission time
3+ repeated samples, median/variance, cold versus warm
retired instructions if available, wall time, peak RSS, scratch high-water
allocation count/bytes, GC cost, cache hit/miss/eviction, work budget
accepted/rejected/unsupported/resource/internal counts
proof compile status and exact theorem dependency/assumption inventory
~~~

Measure unmodified V1 and experimental V2 on the **same runner, corpus, exporter and semantic policy**. Arena virtual CPU time (instructions normalized at 6B/s) is not actual elapsed time. Upstream Rust benchmark speedups are **not forecasts** for a Lean-native or generated-JS build.

### 8.2 Required corpora and systematic corner cases

1. Existing cheap tutorial, raw scope/inference, and Arena negative corpus.
2. Pinned fresh Lean 4.35 Prelude and focused Std/Init imports, with full imports reserved for milestones.
3. Large beta/let ladders; variable capture and binder-shift cascades.
4. Same rigid-head arguments versus expensive unfolding; projection order and guarded proof irrelevance.
5. Repeated conversion subproblems; memory reuse and cache eviction.
6. Symbolic/max/imax universes including zero versus positive regime and annotation coherence.
7. Safe/unsafe/partial definitions and malformed or untrusted recursor metadata.
8. Ordinary, mutual and nested inductives, positivity, projections, quotients.
9. Explicit host resources, unknown exporter version, oversized numeral, illegal type/level arity and cancellation.
10. Reflective `decide` / large computational proofs and peak heap behavior.
11. Full pinned Init, Std, Mathlib **only on a separately budgeted acceptance milestone**.

Test outcomes must distinguish (a) disagreement with official behavior, (b) restricted verified axiom mode decline, (c) resource exhaustion, and (d) actual false acceptance. An internal fallback should never make a foreign checker’s success count as kernel acceptance.

### 8.3 Decision thresholds (proposed targets; no measurement performed)

| Area | V2 **proposal**, not a measured fact |
| --- | --- |
| Semantic correctness | Zero known-invalid accepts; typed failures accurate; all pinned focused supported checks match official result |
| Kernel-only throughput | Seek at least **2x** improvement on beta/let/convert-intensive hot workloads versus frozen V1 |
| General library speed | Target a meaningful sustained gain, e.g. **≥1.5x on a pinned Init/Std corpus**, after coverage is stable |
| Memory | Target at least **30% lower peak or retained heap** on a measured allocation-heavy corpus, if compact handles are justified |
| Source smallness | Prefer reduced *net* trusted semantic LOC and imported runtime primitives; no unconditional LOC number |
| Formal status | Proved exact representation/refinement for all **promoted** positive optimizations; explicit unfinished global theorems |
| Self-host | Only announce backend support after exact source/backend fixed-point or designated canonical qualification passes |
| Interop | Official Lean exports and source versions pinned; no silent conversion of old Lean 4.34 assumptions |

If the redesign fails to achieve improvements sufficient to offset code/proof burden, fall back to incremental V1 optimization. Failure to hit an aspirational speed target does not authorize changing semantic acceptance criteria.

## 9. Size and implementation cost — uncertainty-aware

**Current observations:** 92 production `.lean` source modules containing about 0.94 MB (Git tree only), plus 182 formal-metatheory `.lean` files containing about 3.18 MB (not runtime TCB). These are not a valid measured LOC or compile time baseline. Tests, host tooling and external runtime dependencies are excluded.

**Pure planning envelopes, not estimates supported by prototype data:**

| Work family | Illustrative gross new semantic LOC | Opportunity for deleting/replacing old code | Main uncertainty |
| --- | ---: | --- | --- |
| M1 typed checking/scope/error contracts | 600–2,000 | Obsolete raw-state adapters and string errors | Amount of recursive checker signature churn |
| M2 DAG and storage | 1,000–3,500 | Some repeated lookup/hash and substitution scaffolding | Lean native data layout vs portable source |
| M3 lazy closure evaluator | 1,500–4,500 | Eager instantiation and reconstruction helpers | Exact Lean recursor/eta behavior |
| M4 typed DefEq engine | 1,500–5,000 | Current callback wrapper/shortcut family | Proof-irrelevance and unfold scheduling |
| M5–M6 admission/model/backend | Highly dependent on proof completion | Legacy checking/storage modules | Very large mathematical/portability scope |

**Do not sum these bands and call the result “estimated new LOC”.** Some modules overlap; a true prototype may reuse far more existing code, and important existing proofs may require major revision. Produce an exact count of **net maintained source lines and transitive trusted dependencies** at each pilot gate.

The most expensive component is likely **the correctness bridge**, not writing the first compact DAG. The current 182 metatheory modules mean a big-bang checker rewrite has a high validation cost. Using incremental representation erasure and theorem-level interface stability may be cheaper than patching each old proof after the rewrite, but we need actual staged experiment results to confirm.

## 10. Architecture review criteria

| Criterion | Desired V2 result | What would make V2 worse |
| --- | --- | --- |
| Soundness/fidelity | Real public checker with explicit guarded valid results, mapped to Lean 4.35 | Unsupported positive equality shortcuts |
| Trusted computing base | One small inspected runtime authority, explicit native caps | Duplicated Rust/JS kernel or hidden FFI |
| Adversarial malformed-input robustness | Checked bounds/scope/levels/recursors, atomic env and typed errors | Untrusted IDs or pointers accepted as proof |
| Source smallness/extendibility | Minimal logical rules, nonsemantic plugins | Large framework with custom proof rules |
| Architecture | Distinct raw decode, semantic core, evaluation, admission and proof | Circular module ownership and parallel runtimes |
| Independent evidence | Official replay and separately implemented checker audits | Mistaking checker majority for theorem proof |
| Performance/resource behavior | Matched kernel-only gains, bounded heap/fuel, deterministic failures | Faster parser only, hidden out-of-memory acceptance |
| Portability/interoperability | One source, pinned exports, verified native/JS/Wasm profiles | Native-only unqualified pointers |
| Longevity/auditability | Versioned rule matrix, per-phase dependency/TCB manifests | Silent changing semantics between Lean releases |
| Formal assurance | Spec/model + executable refinement + constructive fresh model | Theorem about an unused spec or axiom-smuggled model |
| Self-host/bootstrap | Preserve canonical self-host target with source feature gates | Announcing self-host without generated qualification |
| Extension soundness security | Untrusted extensions cannot mutate checker/admission or axiom policy | Plugin-supplied “fast Equal” accepted directly |

## 11. Non-negotiable decision and stop rules

1. Lean `4.35.0-rc4` is the exact target until separately retargeted. Backward compatibility with obsolete 4.34 trusted reducers is not a hidden feature requirement.
2. A real **major** architectural improvement may replace internal data structures and algorithms; old `Checker/Knot` is an oracle/compatibility bridge, not a sacred end-state.
3. **No second independent production checker**, unchecked shortcut, foreign plugin trust rule, silent axiom import, `sorry` or new consistency assumption.
4. Prefer **proof-guided vertical slices** over test-specific patching and big-bang rewriting. Keep accepted cases and rejected malformed cases.
5. No phase may claim full soundness or Lean compatibility while public model/refinement cases, Init/Std/Mathlib, or portable backend qualification remain open.
6. GitHub branch history and active proof PR are preserved. Re-read live HEAD before any future code migration; do not force-update concurrent work.
7. If source simplification and performance do not improve jointly, prefer the cleaner provable design, but do not trade genuine compatibility for aesthetics.
8. Stop/revert a candidate when typed scope/annotation coherence, exact positive equality, whole-transaction admission or resources become harder to justify without a measured benefit.

## 12. Recommended first executable task

**Build a research-only M0+M1 vertical slice**, not the entire new kernel. Use actual pinned source from the current 4.35 branch, independently validate the full supported small corpus, and measure:

1. An optional exact interned CoreExpr representation round-tripping the first few expression constructors.
2. An explicit checked/infer-only result carrier with actual stored observation provenance.
3. A single small beta/let closure WHNF experiment (not yet authoritative for declaration acceptance).
4. Exact differential comparison with original checker and official Lean 4.35 on a bounded test set.
5. Source-line, proof-obligation, CPU and memory deltas that decide if an M2/M3 full migration has positive value.

**The first promotion gate should demand real exact erasure/grade evidence, not a headline speedup.** If this slice is clean and faster, expand to Pi/lambda/application and all expressions; if not, preserve V1 and optimize its existing certified sharing.

## 13. Final recommendation

**Choose V2 architecture B: an internal compact immutable expression DAG + provenance-carrying checked results + lazy closure evaluation + Lean-compatible typed conversion + atomic modeled admission, implemented as a single kernel with explicit formal refinement.**

Keep the old source as a temporary frozen oracle, do not overwrite ongoing proof work, and earn promotion through bounded semantic and performance gates. A full rewrite of every module before validating the representation and formal contract would jeopardize correctness, smallness and self-hostability.

This is a **design commit only**. No V2 kernel behavior, speedup, proof of full consistency, complete Mathlib compatibility or self-host qualification is claimed.
