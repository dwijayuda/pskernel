# PSKernel Core: Lean 4.35 repairs and architecture review

Date: 2026-10-10 (Asia/Jakarta). Work was performed through GitHub and cloud CI.

## Correctness audit and model-proof direction — 2026-10-10

Correctness now takes priority over performance. The metatheory is **not
complete**, and the present operational judgments cannot support a consistency
proof. This is stronger than an unfilled lemma: the current specification
admits a machine-checked counterexample.

### Confirmed specification failure

`JudgmentAdequacy.lean` proves, for every environment and local context:

- `PsKernelDefEqJudgment environment context left right` for arbitrary terms.
- `PsKernelTypingJudgment environment context (sort zero) type` for every type.
- Consequently, no interpretation with an empty type can validate all these
  typing derivations.

The cause is `proofIrrelevanceAlgorithmic` in `Judgments.lean`. It accepts
candidate types and a proposition-classification reduction, but has no premise
connecting the left term to its candidate type, the right term to its candidate
type, or the left candidate type to the second inferred type. Choose the candidate
types identically, choose the second type to be `Sort 0`, and its premises are
reflexive. The unrestricted conversion constructor then collapses typing.
Environment well-formedness alone cannot fix this counterexample, because the
construction works in every environment.

These are theorems **about the specification**, not successful runs of
`psKernelV1CheckExpression`. Existing refinement results establish only the
forward implication from executable success to the legacy judgment. Their
converse is neither stated nor proved. This audit therefore does not exhibit
an executable proof of False; it invalidates using those relations as evidence
that the executable is semantically sound.

The other algorithmic shortcuts, including unit-like structures and structure
eta, also need a typed-input and inference-connection audit. Repairing only the
single demonstrated constructor would not justify declaring the theory sound.

### Comparison with the actual reference proofs

| Implementation and exact research revision | What was checked | Consequence for PSKernel |
| --- | --- | --- |
| Official Lean `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364` | [Proof irrelevance calls actual type inference, proposition classification, and type comparison](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/type_checker.cpp). | Keep the actual term-to-type connections in the proof. An implementation-shaped rule with omitted inference premises is insufficient. |
| Lean4Lean `8223d223ed98661882e95d9d6a7126df7097cd76` | [The typed rule](https://github.com/digama0/lean4lean/blob/8223d223ed98661882e95d9d6a7126df7097cd76/Lean4Lean/Theory/Typing/Basic.lean) requires a proposition and both terms to inhabit it; [the checker proof](https://github.com/digama0/lean4lean/blob/8223d223ed98661882e95d9d6a7126df7097cd76/Lean4Lean/Verify/TypeChecker/IsDefEq.lean) carries translated, well-formed input evidence into infer-only calls. | Separate typed semantic equality from the incomplete comparison algorithm. This pinned verification file still contains unfinished structure-eta and unit-like proofs; it is not a completed proof we can import wholesale. |
| Con Leche `65e74db49e89ad2bbd1e90aa4f784954db41fa3a` | [Rule soundness](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Rules/Sound.lean) recursively retains inference premises. [Infer-only application](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Rules/InferSound.lean) uses semantic input evidence and binder classification; not every application may skip its argument check. | A model-directed checker may need justified annotations or extra checks. Its syntax, inductive treatment, and axiom policy differ from PSKernel, so its model theorem does not transfer by similarity. |
| Con Ron `64a2172a01276aa049220200bac11c075316230f` | [The capstone](https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/proof/ConRon/Capstone.lean) composes Rust-to-twin and twin-to-Con-Leche refinement, with explicit successful pipeline calls, complete worker coverage, chunk-source correspondence, and a set-theory foundation. | A storage rewrite needs its own simulation and input/output correspondence. Hash-consing performance does not establish kernel correctness. The extraction and runtime boundary remains distinct from the mathematical model. |
| Nanoda `4c544ed4099c8227f07d5de77ad1e69fb0740a27` | [Infer/check separation and proof irrelevance](https://github.com/ammkrn/nanoda_lib/blob/4c544ed4099c8227f07d5de77ad1e69fb0740a27/src/tc.rs) and [configurable axiom admission](https://github.com/ammkrn/nanoda_lib/blob/4c544ed4099c8227f07d5de77ad1e69fb0740a27/README.md). | Useful independent implementation evidence, not a substitute for the missing PSKernel model proof. |

The separate [Lean4Lean model target](https://github.com/digama0/lean4lean-model/blob/27fb3b656c0d536469f6817cf277904dee8eb5ca/Lean4LeanModel/Consistency.lean),
at `27fb3b656c0d536469f6817cf277904dee8eb5ca`, explicitly contains an unfinished
consistency theorem. Its statement and foundation are useful references;
the unfinished theorem cannot be used as a proof dependency.

### Actual primitive repair

The active `psKernelStringEq` now uses `decide (left = right)`, whose
[Lean 4.35 definition](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Prelude.lean)
decides equality of the represented UTF-8 bytes. The all-input theorem
`psKernelStringEq_true_iff` connects a positive result to actual string
equality, discharging `PsKernelStringEqSoundLaw` without a custom axiom.
Fresh-name and universe-parameter uniqueness consequences can now instantiate
that law with a theorem. Hash-coherence proofs use equality substitution, so
they no longer need the old cursor implementation to establish equal hashes.

This deliberately replaces the old implementation's opaque-read proof
obligation with a specified operation; equivalence to the old opaque worker
is not claimed. The worker remains for compatibility proofs but is no longer
called by public string equality. Native execution uses Lean's
`lean_string_dec_eq` runtime override, which remains in the existing
compiler/runtime TCB. Generated PSC0 qualification has not been established for
this implementation. No independent speedup is claimed from this change.


Validation for the specified string equality and adequacy audit is recorded at
`c78590556fca75f9ee080e32cbb0d0cd82f16b92`:
[run 38007755710](https://github.com/dwijayuda/pskernel/actions/runs/38007755710)
passed the 241-job executable build, the 200-job existing metatheory build,
all 84 companion files, foundation/cache/sharing regressions, all 141 tutorial
verdicts and all 18 Arena bug verdicts with no declines. Fresh Prelude, UTF8,
XOR and Int64 exports passed. The positive StringEq soundness theorem reports
**no axioms**; the equivalence lemma reports `propext`, and the freshness
corollary reports only the three standard host axioms. The classifier trace and its refactored caller subsequently passed
[run 38008230732](https://github.com/dwijayuda/pskernel/actions/runs/38008230732)
at `aea996799b986091a4c8fbf6e1ce28f578609348`: 201 build jobs and all 84
companion files. This later change affects assurance code and Lake registration,
not the production implementation tested at `c7859055`.

### Retained classifier evidence

`DefEqClassifierTrace.lean` now states the exact positive proposition-classifier
contract as an equivalence with an operational trace. That trace includes the
input expression's inference result, the intermediate checker state, the
WHNF call on that exact inferred type, the final state, and the zero-level
sort result. The legacy refinement helper derives its weaker result through
this trace. The primary trace interface therefore preserves the connections
needed for a future model proof instead of throwing them away.

This remains operational evidence. The trace's inference operation must still
be proved semantically sound on its actual valid inputs. The legacy equality
constructor is not repaired by adding this interface, and the adequacy
counterexample remains an intentional build target.

### Required model theorem and explicit assumptions

The compatibility API admits well-typed user axioms. Such an axiom need not
be true: admitting an axiom of type False cannot imply unconditional consistency.
The model theorem must therefore preserve a model of the safe logical
environment **relative to a satisfying interpretation of admitted axioms**.
A separate restricted consistency mode could instead enforce an exact axiom
policy with proved interpretations; changing that policy is not part of this
primitive repair. Unsafe/partial declarations and their accessibility from
safe checking also require an explicit semantic boundary.

The intended theorem is: given the mathematical foundation, a model of the
initial safe environment, interpretations of the admitted axioms, and a
successful actual safe admission run, construct a model of the resulting
safe environment which preserves earlier interpretations and validates the
new declarations. The no-False corollary additionally fixes the intended empty
interpretation of False. This is a target, not a theorem currently implemented.

Con Leche's [actual model theorem](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/MainTheorem.lean)
has a `SetTheory V` hypothesis. Its
[foundation interface](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/SetTheory/Core.lean)
includes an increasing countable hierarchy of universes. This is a stated
relative-consistency assumption, not an implementation soundness axiom.
The standard host axioms reported by `#print axioms` do not list such local
hypotheses, so both must be audited. PSKernel has not constructed this model
or adopted an extra foundation axiom in the kernel.

### Architecture and completion gates

1. Define an independent typed or semantic relation with scoped contexts,
   universe valuations, sound constant lookup, and valid environments.
   Retain inference connections and input validity at every shortcut.
2. Prove checked inference establishes that relation. Prove infer-only results
   under their actual well-typed-input premises; configuration preservation
   alone is insufficient. Carry the obligations through reduction, caches,
   proof irrelevance, eta, projection, quotient and recursor paths.
3. Establish complete admission model preservation, including ordinary,
   mutual and nested inductive transactions, positivity, generated recursors,
   quotient bootstrap, safety restrictions, and axiom interpretation.
4. Connect the exact public checker and stream adapter to those results.
   Prove input fidelity and complete coverage. Construct the model and derive
   the no-False corollary; audit all assumptions and runtime dependencies.

Do not assume generic subject reduction or transitivity of the executable
comparison. A semantic equality can be transitive without making the
algorithm's positive cache a transitive closure. Resource exhaustion may
reject or decline; the consistency proof concerns successful checking and
does not require proving all inputs terminate within an Arena budget.

These gates are unfinished. A successful build of the existing proof files
does not close them. No shortcut rule, arbitrary model-soundness premise,
`sorry`, custom axiom, unchecked cast, or fallback checker is an acceptable
substitute.

### Extended Init results and reporting correction

The old executable `e9b0cdae39ea9a2ff0d7da841e0faacbf7943df4`, SHA256
`74609c21967988d5cee861001a3a3334bd204a381b4cfa4b928e5aff4457c54e`,
accepted both full Init exports in
[extended run 38004337520](https://github.com/dwijayuda/pskernel/actions/runs/38004337520):

| Input | Records | Declarations | Wall seconds | Peak RSS KiB |
| --- | ---: | ---: | ---: | ---: |
| Fresh 4.35-rc4 Init | 6,452,982 | 57,919 | 1,647.02 | 319,028 |
| Historical 4.34.1 Init | 6,487,065 | 58,170 | 2,141.76 | 317,308 |

Both checker processes exited zero and emitted a final acceptance covering
every input record. The workflow jobs are recorded as failures because the
original monitor searched stdout while the adapter emits acceptance on stderr.
The monitor is corrected in `a3c9436e0b4a89c9434a72594e810aeccb1e93a0`.
The evidence receipt preserves the original job status and raw-log provenance
alongside the corrected interpretation; it does not relabel the original run
green or weaken the exit/coverage requirements.

These runs precede the specified string-equality repair. They do not validate
the new binary, prove semantic soundness, or pass the unchanged 500-second
Arena Init budget. Std and Mathlib results are recorded separately when known.

## Prior sharing stage: decision and scope

The active package is `psc0/packages/pskernel-core`, targeting the user-selected
Lean **4.35.0-rc4**, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
The repair stage addressed reduction order, resource accounting and cache
modes/scope. The authorized architectural stage now implements certified native
sharing and reusable hash metadata. It does not yet establish complete Arena or
Mathlib conformance. Exact checked results are recorded below and in
[MIGRATION_EVIDENCE.json](MIGRATION_EVIDENCE.json).

The remaining performance problem is architectural: PSKernel preserves
sharing when reading an export, but its semantic operations often traverse
that shared graph as an expanded tree. The implementation must preserve sharing while proving that execution returns
the specified result. This stage follows Con Leche's intrinsic-entry proof
pattern in safe Lean, retains the original expression specification and avoids
a simultaneous rewrite of checker judgments. Its runtime dependence is explicit:
this is a native experiment, not the separately planned portable graph/backend
qualification. No timeout or declaration-specific acceptance exception is added.

## Source ownership and exact comparison pins

The migration combines the latest inspected proof source
`85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62` with the Arena adapter and bounded
cache work from `132d817071cd62c23a70c15984d6c73e14d6e856`. The initial
PSC0 base was `e356162ddf1d0780337b2f510925455c70fb658d`; its later
`4c79a2e921b3b3c27e3be477f7646f89b6b3526a` update concerned compiler
proof-workspace documentation. Historical receipts from either old kernel
branch do not certify this combined source.

| Reference | Inspected identity | Role |
|---|---|---|
| Official Lean | `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364` | Selected 4.35.0-rc4 semantics/toolchain |
| Official development head | `5e96ee1153f945234f126ed024043a0697c9d6f3` | Research only; not the target |
| Con Leche | `65e74db49e89ad2bbd1e90aa4f784954db41fa3a` | Current cached implementation and proofs |
| Con Ron | `64a2172a01276aa049220200bac11c075316230f` | Current explicit DAG implementation and refinement |
| Nanoda | `4c544ed4099c8227f07d5de77ad1e69fb0740a27` | Interned expressions and binder traversal |
| Lean4Lean, Arena reference | `bce3448115f7819fc12d647fadd3bb090666637e` | Checker organization and theory |
| Kha/lean4lean, bundle tag | `456abe5015fc8f54ea595561fc39523d7733c93f` | Separate 4.35 bundle reference inspected |
| Kernel Arena | `b83254de5146ef34147ab82a48edbe1856b0edcc` | Frozen tutorial/bugs/Init/Std/Mathlib inputs |
| lean4export | `05d43a2bc773b40ecfdebb32294192a5ef756951` | Fresh 4.35 exports |

Do not conflate these with the checker versions bundled by rc4.
Its [CMake source][bundle] pins Con Leche at `67f04630d88718e81aa4d07ab64501f68f105398`,
Con Ron at `dd8d8218892c871276b1e569d3decbb368bba1b6`, and Nanoda at
`3a2407216ee84a75f9e1aead6803d0578be06ae7`. The comparison above includes
newer implementations. Reported upstream benchmark times are not controlled
speed ratios against our cloud runners.

## Arena branch audit

These are the extant Arena branch heads rechecked during this continuation.
The last column is workflow completion, **not** a kernel conformance verdict.

| Branch | Head | Latest inspected workflow | Workflow result |
|---|---|---|---|
| `pscv/pskernel-core-arena-budget-study-v1` | `ecf7dd801aaf43e7bbbb15970487c781084585c4` | [PSKernel Core Init proof DAG analysis](https://github.com/dwijayuda/pskernel/actions/runs/37933228241) | success |
| `pscv/pskernel-core-arena-cache-ab` | `9dab024b28697ed1233e4d8f9198d16cfe40c1a4` | [PSKernel Core Arena bounded-cache A/B experiment](https://github.com/dwijayuda/pskernel/actions/runs/37923962388) | success |
| `pscv/pskernel-core-arena-cache-order-ab` | `a178c619bce5ef415d2cb578f3169c4b5d17989c` | [PSKernel Core Arena cache-order A/B experiment](https://github.com/dwijayuda/pskernel/actions/runs/37924378742) | success |
| `pscv/pskernel-core-arena-cache-upper-sweep-v1` | `f6566e47744c87b1335e973fb3b96ce14fb6571f` | [PSKernel Core hot theorem cache-size upper sweep](https://github.com/dwijayuda/pskernel/actions/runs/37943616245) | success |
| `pscv/pskernel-core-arena-eligibility-fast-v1` | `35db6068579798402c1a78c3d909c6d8117b5a42` | [PSKernel Core proof](https://github.com/dwijayuda/pskernel/actions/runs/37943016615) | failure |
| `pscv/pskernel-core-arena-equality-ab` | `3beec6b575e452f23d6cb76d780218d5149398e8` | [PSKernel Core Arena equality A/B experiment](https://github.com/dwijayuda/pskernel/actions/runs/37923775015) | success |
| `pscv/pskernel-core-arena-optimized-v3` | `132d817071cd62c23a70c15984d6c73e14d6e856` | [PSKernel Core Arena focused UTF8 theorem diagnostic](https://github.com/dwijayuda/pskernel/actions/runs/37932815530) | success |
| `pscv/pskernel-core-arena-phase-profile-v1` | `0214fd67cb2a2d9a4ae24f0b549ab4adbe09ccac` | [PSKernel Core proof](https://github.com/dwijayuda/pskernel/actions/runs/37941957359) | success |
| `pscv/pskernel-core-arena-synced-v2` | `e1166c00c3e1e92bf3e67149c4b85b85461db35d` | [PSKernel Core Arena v2 hotspot profile](https://github.com/dwijayuda/pskernel/actions/runs/37922810339) | success |
| `pscv/pskernel-core-arena-v1` | `756f4b9175edc11adf19b6b50586af762d296edc` | [PSKernel Core Arena controlled native comparison](https://github.com/dwijayuda/pskernel/actions/runs/37676544921) | success |

The optimized-v3 branch's [complete Init/Std run 37930905868](https://github.com/dwijayuda/pskernel/actions/runs/37930905868)
failed even though its neighboring proof, readiness, and soundness workflows
were green. The [soundness job 113821083110](https://github.com/dwijayuda/pskernel/actions/runs/37930905967/job/113821083110)
reported 17 correct bug rejections and one decline. The v1
[controlled comparison](https://github.com/dwijayuda/pskernel/actions/runs/37676544921)
checked 200,000- and 362,100-record Init prefixes; it was not full Init or
Mathlib acceptance. The new workflow requires complete verdict counts and
does not allow the old known-decline exception.

The budget-study branch also supplies concrete sharing evidence:
[run 37933228241](https://github.com/dwijayuda/pskernel/actions/runs/37933228241)
measured the proof at historical Init record 361,999,
`Array.extract_append_extract._proof_1_1`, as **24,520 unique nodes versus
12,501,779 expanded tree nodes**, depth 85. Its direct proof DAG contained
neither `reduceNat` nor `reduceBool`; that observation alone does not bound
work after unfolding constants. It supports the traversal diagnosis without
assuming that every slow proof has the same cause.

## Implemented repairs

| Component | Defect | General repair |
|---|---|---|
| Nat evaluation | Both operands normalized before checking whether a name was a Nat primitive | Dispatch first; stop when the left operand is nonliteral |
| 4.35 native reduction | Old compiler callbacks could still participate in logical reduction | Native reduction always returns none; theorem and poisoned-callback check |
| Projection shortcut | Expression node count used as fuel for unfolding referenced definitions | Pass remaining checker fuel; small syntax no longer imposes a false unfolding bound |
| Core WHNF cache | Cheap-recursion results could be published as full results | Suppress publication when either cheap-recursion or cheap-projection mode is active |
| Recursive occurrence diagnostics | Stuck-recursion positivity failure classified as unsupported nested induction | Precise invalid-shape diagnostic; `rec-missing-ih` is a rejection, with no allowed decline |
| Lambda spine | Full type/body node count calculated just to select applied binders | Bound the peel by argument count |
| Equality lookup | Success lookup hashed a pair before applying publication's eligibility rule | Apply the bounded eligibility rule before lookup |
| Open expression caches | All expressions containing local variables refused memoization | Permit bounded open keys within the existing checker configuration and scope rollback discipline |
| Inference eligibility | Checked app/lam/forall and literal refusal paid an unnecessary expression scan | Refuse these shapes before traversing the key |
| Instantiation | Full tree count supplied a fuel wrapper before a second tree walk | Direct structural instantiation with a proof of equality to the reference |

No theorem-name special case or increased Arena time limit is part of these
repairs. Tests exercise the invariants: delayed unfolding, mode separation,
open-cache scope isolation, and giant shared inputs at the bounded lookup and
spine-selection boundaries. Structural instantiation has an all-input
refinement theorem, not just sample agreement.

The existing configuration/metatheory contracts remain. Some companion
operational equations had specifically asserted that fvar keys were never
cached. Those equations now express the scoped hit/miss behavior. In
particular, the raw-state unknown-fvar equation requires a cache miss;
a separate theorem proves unconditional unknown-fvar rejection for a fresh,
empty checker state. This is not a claim that arbitrary caller-supplied
cache contents are trusted input.

## Measured causes, with limits on the evidence

### Symbolic reduction recomputation

At `ad13026571931c0151b7ae53f468cd5363bef391`, a fresh 4.35
`Int64.toBitVec_div` closure (16,206 records, 405 declarations, 497 constants)
exceeded 180 seconds. [Trace run 37986278855][trace] showed repeated
symbolic `Nat.shiftRight`, `Nat.div`, and `Nat.ble` reduction around
`BitVec.msb`.

An [isolated experiment][open-experiment] allowed open keys in bounded caches
on that same source/export. Budgets of 256 and 4,096 took 0.30 and 0.38 seconds,
respectively. These diagnostic binaries are not production receipts. The
initial production WHNF-only repair subsequently took 0.36–0.37 seconds
with the full metatheory and all 84 companion files checked. The later
candidate extends scoped open caching to the other bounded caches.

### Traversal and allocation across the corpus

The [full Init profile report][profile-report] at the earlier scoped-WHNF
revision contains 366 slow declarations, totaling 446,874 milliseconds of
reported declaration time. The largest recorded costs include:

| Declaration family | Recorded elapsed time |
|---|---:|
| `Array.toList_reverse.go._unary` | 100,030 ms |
| `Array.extract_append._proof_1_1` | 29,772 ms |
| `Array.extract_append_extract._proof_1_1` | 21,676 ms |
| `Array.extract_extract._proof_1_1` | 13,719 ms |

The run reached well beyond the original Int64 stall, but did not complete
Init. [Worker-thread stack samples][samples] repeatedly showed instantiation,
tree node counting, structural equality, universe-parameter rebuilding,
eligibility traversal/allocation, and scope cleanup. Eleven samples identify
credible hot paths; they are not enough to assign precise CPU percentages.

A [four-way experiment][traversal-experiment] used the identical first
1,000,000 records, SHA-256
`735d43733b70c51d86d9c4365ea433abcdb76a9f94dfe09a7a7dfc4605699878`.
Baseline, structural instantiation alone, and open caching alone each hit
240 seconds. The combination accepted that prefix in 203.30 seconds,
with 8,507 declarations / 9,199 constants and 332,508 KiB maximum RSS.
This is interaction evidence for the combined change, not full Init
acceptance or a general speedup ratio.

### Why the current cost model remains wrong

Let a shared expression be `e(k+1) = app(e(k), e(k))`. It has O(k) distinct
nodes, but an un-memoized structural walk satisfies
T(k+1) = 2 T(k) + O(1). Returning unchanged nodes preserves memory sharing
after the walk; it does not prevent exponentially many visits during it.

The host adapter already interns export references and preserves physical
sharing. Reworking only JSON parsing therefore misses the measured semantic
walks. The 256-expression-node cache limit prevents some large expression
hashes, but it is a tactical policy, not constant-time metadata. It also
does not bound the cost of large names, universe levels, strings, or bignum
payloads inside an expression node. Lifting and abstraction still retain
node-count prepasses, and universe instantiation still rebuilds recursively.

The inference core opens and closes one lambda/forall at a time. A long
telescope can repeatedly traverse the whole remaining body. For k binders
and a residual body of size N, this introduces O(kN) work before considering
shared subgraphs. Batched telescopes avoid the repeated body substitutions;
dependent domains still require their own substitutions and checks.

## What the other implementations actually do

| Component | Primary-source observation | Consequence for PSKernel |
|---|---|---|
| Official Lean | [`replace_fn`][replace] memoizes shared nodes by address and binder offset; [instantiation][instantiate] cuts off using stored loose-variable metadata and reuses unchanged nodes | Repeated walks need a node identity and cursor-aware memo, not recursive hash preparation |
| Official Lean | [Checker][official] batches lambda, forall, and let telescopes and caches instantiated constant heads before applying arguments | Separate reusable constant work from call-specific arguments; batch binding operations |
| Con Leche | [Expression operations][con-ops] use metadata cutoffs and validated address/cursor memo hits, with each entry carrying its equality to the pure result | Study the refinement discipline; raw addresses are not evidence of equality |
| Con Leche | [Node layer][con-nodes] uses compiler-provided computed fields and distinguishes proved compiler simplifications from runtime/compiler assumptions | This mechanism is native-Lean-specific until PSC0 implements and qualifies an equivalent |
| Nanoda | [Expressions][nano-expr] use interned handles, stored hashes/variable summaries, and per-operation `(expression, offset)` memo tables; [checker][nano-tc] batches lambda/forall inference | Explicit handles are an alternative to raw pointers, with a clear memo lifetime |
| Current Con Ron | [Store][ron-store] has persistent/scratch tiers and per-constructor arrays; [walks][ron-ops] use handle/cursor memos and a Lean twin | Representation and proof boundaries can be designed together for the actual target runtime |
| Lean4Lean | [Checker][l4l] separates infer/check caches and gives the recursive checker explicit method contracts; its theory distinguishes checking from infer-only preconditions | Preserve the existing PSKernel method/configuration proof structure during representation changes |

A correction to broad comparisons is necessary: the inspected Lean4Lean
Arena and bundle revisions still contain an [`EquivManager` union-find][l4l-eq].
Official rc4 uses successful pair queries, and Con Leche uses pair results.
Therefore “all other kernels use only pair caches” is false. PSKernel should
retain its current pair discipline; do not copy an older equivalence manager
without proving its contextual and algorithmic premises. Incompleteness alone
does not make logical equality non-transitive. [Lean #14806][eq-fix] explains
the stronger problem: transitive closure may contain only true equalities,
yet change the algorithm's answer after earlier queries. Recursor construction
can then classify the same field differently while building its type and its
computation rule. Thus a semantic equality certificate alone is insufficient:
memoization must also preserve the algorithm's observable query behavior
where consumers rely on repeatability. This is an architectural invariant,
not merely an exploit-specific test.

Current Con Ron is materially different from the older web-indexed README
describing a close reference-counted Rust port. Its [current README][ron-readme]
describes the DAG rewrite. Its [capstone][ron-capstone] relates successful
Rust stages and complete pending-check coverage to a set model; the driver,
runtime assumptions, and the coverage premises remain relevant. It is a
refinement pattern to study, not a proof that a PSKernel port would be correct.

## Theory and trust obligations

The [Lean4Lean paper][paper] separates abstract typed judgments from the
concrete locally nameless representation and from the executable checker.
Its recursive-method contracts require well-typed input for infer-only
inference and reduction. This matters to cache transport: an unchecked
inference result is not automatically a typing certificate.

The same paper explains why a syntactic tree-size measure cannot justify
general reduction termination. Structural descent and checker fuel solve
different problems. Keep reduction/depth/resource exhaustion explicit;
never interpret a budget failure as a successful judgment. Formal refinement,
absence of false acceptance, conformance to a pinned algorithm, and predictable
runtime are separate obligations.

Con Leche's [`model_exists`][con-main] is accepting-direction consistency
relative to its set-theory interface and checker/axiom policy. PSKernel's
configuration and substitution proofs do not yet constitute the same theorem.
No end-to-end consistency claim is made here.

The [2026 nested-inductive postmortem][postmortem] gives another architectural
lesson: information erased by a transformation can escape validation.
PSKernel must check original declarations and all their arguments before
normalizing them into a more convenient representation. Projection type names,
phantom/non-uniform parameters, and recursor positivity obligations must remain
visible. Shared implementation ancestry is not independent evidence.

## Certified native execution architecture

The current implementation keeps the original pure syntax in `Core/Expr/Basic`.
A single cursor-aware fold specifies syntax operations. Its executed walker
carries entries with an intrinsic equation `value = fold algebra node cursor`;
there is no external table invariant to assume. A hit validates the stored
input and cursor. Each substitution operation fixes its parameters for the
table's lifetime. Keys are non-semantic hints; they cannot authorize a value.

Cursor advancement belongs to each operation's algebra. Instantiation, lifting,
abstraction and both loose-variable queries advance at binders. Node counts,
free-variable queries, structural hashes and universe substitution keep their
cursor fixed: the same node reached at different binder depths must not acquire
redundant entries for a context it does not depend on. Exact bound-variable
occurrence uses this same certified fold, including negative searches.

The design uses the [Con Leche entry discipline][con-ops], but does not import
its exclusivity primitive or its constructor metadata. This distinction matters
to performance: a safe always-memoized traversal can cost more on an ordinary
unshared tree. Small bounded shapes use direct pure execution. Boolean queries
preserve early exits through certificates proving the remaining children cannot
change the result. Native compiler specialization removes the operation
dictionary callbacks; generated C is inspected in CI.

Lifting and free-variable abstraction now use structural descent, with all-input
refinements to the existing reference definitions; term instantiation already
had that refinement. Rebuilding keeps unchanged nodes. Substitution arguments
are prepared once: a checked closedness fact proves lifting is the identity at
every binder depth. Open arguments retain the ordinary lifting operation.
The argument preparation condition is outside the returned closure in generated
C. Empty universe substitutions return the original node under an unconditional
identity theorem.

Exact syntactic equality has a separate pair memo and a proved reflexive pointer
shortcut. Only successful pair results are retained: a false comparison already
terminates that conjunction. This is not the checker's definitional-equality
cache, and it does not infer additional pairs by transitivity.

Hash metadata has a longer lifetime than a substitution memo. A profile of the
first retained-metadata candidate caught whole bucket-array copying and release
costs: four of eleven sparse worker samples were inside array copying under memo
insertion. Retaining a parent state aliases the mutable-array-backed table, so
the expected in-place insertion cost did not apply. The corrected storage uses
Lean's [persistent hash trie][persistent-map], with bounded-width path copying.
A subsequent worker profile still found temporary variable-query memos paying
persistent-trie insertion costs. The current design separates an operation-local
`Std.HashMap` scratch delta from its persistent checkpoint. Only updates that
publish metadata freeze the delta into the checkpoint; read-only cache queries
return the exact hash without publishing. Scalar mixed keys avoid a pair
allocation per probe; collisions remain validated. Each semantic map
or pair set retains a `Squash` of intrinsically certified structural hashes.
The cached result still equals the original hash; the logically unobservable
memo can change without changing a returned cache record. Four compiler
simplification theorems preserve complete map/set operations, including misses.
This is stronger than claiming that cache hits are sound. A separate full
state-equality theorem proves that certified context-free hash metadata could be
retained across scope exit. That theorem is deliberately not installed as a
compiler rewrite: the retention experiment reached 982,096 KiB peak RSS in the
600-second Init profile, versus 153,152 KiB in the preceding trie-only profile.
These are separate-run measurements, not a controlled speed comparison, but they
expose a lifetime risk. Executed scope exit restores the entire parent cache.
No environment-dependent semantic fact is moved into syntax metadata.

The code introduces no project-defined unsafe implementation, cast or axiom.
It relies on Lean's existing pointer-hint contracts, compiler simplification,
proof erasure, `Squash` and `Lean.PersistentHashMap`. These are native execution dependencies,
not features established for the current PSC0 bounded frontend/backend.
`package.json` therefore records `portable: false`,
`Lean-4.35-native-experimental` and `jointSelfhostQualified: false`.
The portable target remains the current PSC0 profile, not either old PSC1 profile.

General tests cover constructor variants and binder cursors, forced memo-key
collisions, open and closed substitution arguments, independently rebuilt equal
DAGs, hash reuse, symmetric pair lookup and failed lookup. A depth-32 shared
family denotes 8,589,934,591 expanded nodes. Passing that family demonstrates
sharing-sensitive execution; it is not a claim that all Arena terms are fast.

The revised worker sample at [run 38000670791](https://github.com/dwijayuda/pskernel/actions/runs/38000670791)
contained no top-frame whole-table copy among eleven samples. It still showed
repeated bounded cache-eligibility scans, structural name hashing, substitution
allocation, semantic-index lookup and scope cleanup. Absence from eleven sparse
samples is not proof that a cost vanished. The two eligibility specifications
now share one scalar-code execution worker: zero means exhaustion and successor
n means n remaining nodes. A decode theorem proves equality for every expression
and budget, and full-function compiler equations preserve all eligibility
decisions and the unchanged 256-node policy. For the bounded native path this
removes per-node Option-result allocations.

## Portable representation and remaining checker work

The native layer above does not implement or qualify the following portable
storage and context-transport obligations:

1. **Retain a pure expression specification; introduce an explicit internal
   graph with a proved denotation.** Use separate typed handles for names,
   levels, level lists, and expressions. Validate handle origin/range and
   acyclicity. Parsed IDs and serialized metadata are untrusted; derive
   metadata from validated constructor inputs.
2. **Make construction establish the invariant.** Store hashes and exact or
   safely saturated variable/level summaries from child summaries.
   Prove erasure/denotation preservation, metadata agreement, and collision
   handling. Hash agreement never proves expression equality. A saturated
   bound may suppress an optimization; it may not authorize an unsound cutoff.
3. **Choose storage against the real PSC0 backend.** Current TS Array push/set
   copy arrays. A naive ever-growing immutable array can make construction
   quadratic. Benchmark a portable persistent/chunked structure, or qualify
   a versioned runtime storage primitive first. Do not borrow Rust Vec or
   Lean reference-count uniqueness costs by assumption.
4. **Unify binding-sensitive walks.** Instantiation, lifting, abstraction,
   and universe substitution need operation-local memo tables keyed by
   handle and every varying semantic cursor. A substitution environment
   may be omitted from the key only when it is fixed for the table's entire
   lifetime. Preserve unchanged handles; prove each accelerated result
   denotes the existing pure result.
5. **Batch telescopes with a context relation.** Accumulate fresh locals,
   instantiate each domain as needed, open the residual body once, and
   close the result in one pass. Prove substitution composition, variable
   freshness, weakening/context transport, and result correspondence.
   Account for changed recursion-depth consumption explicitly.
6. **Scope semantic caches and graph lifetimes together.** Associate caches
   with environment, local context, checking/reduction mode, and graph epoch.
   Preserve query repeatability as well as accepting-direction soundness;
   do not derive extra answers by closing successful pairs transitively.
   Parent scope restoration and fresh declaration state remain required
   until a proved selective transport replaces them. Persistent objects
   must not retain discarded scratch handles.
7. **Separate constant-head work from applications.** Cache universe-instantiated
   declaration types/values by constant plus levels in an immutable environment;
   apply arguments afterward. No-universe/identity substitutions should
   reuse the original term under a proved identity law.
8. **Integrate through one production semantic path.** Preserve existing method
   contracts and admission checks. An internal refined representation is
   acceptable; an unverified second checker or fallback accepting path is not.

The current richer [PSC0 authoring profile][psc0-guide] permits ordinary
structural workers with supported changing parameters. The old
PSC1-selfhost-stable/1 and PSC1-portable-selfhost/1 profiles are not imposed.
The selected generated compiler still needs to consume and qualify the exact
new source. General `do`, computed fields, pointer operations, Std maps,
and constant-time mutable arrays are not implied by that profile.

### Validation follows the design

- Prove representation/metadata and traversal refinements for all inputs
  in their stated domains, including resource-failure behavior.
- Exercise graph families with sharing, the same node under different
  binder depths, hash collisions, name/level payload growth, nested dependent
  telescopes, and scope/epoch reuse. Measure node visits and allocations,
  not just the time of one theorem.
- Replay the complete pinned tutorial, bugs, Init, Std, and Mathlib streams
  at their original limits. Keep fresh 4.35 exports separate from historical
  inputs. A prefix, skipped job, or green diagnostic job is not conformance.
- Qualify actual generated PSC0 kernel products and the compiler/kernel
  combination separately before selecting this package as the default provider.

## Native architectural checkpoint

Checked source: `e9b0cdae39ea9a2ff0d7da841e0faacbf7943df4`.
[Main cloud run 38001623085](https://github.com/dwijayuda/pskernel/actions/runs/38001623085).
Native binary SHA-256:
`74609c21967988d5cee861001a3a3334bd204a381b4cfa4b928e5aff4457c54e`.

The native build (241 jobs), full metatheory (199 jobs), all 84 companion files,
foundations, resource/cache/scope regressions and shared-syntax tests pass.
Tutorial has 141 correct verdicts and zero declines; bugs have 18 correct
rejections and zero accepts/declines. Fresh 4.35 Prelude, UTF8, XOR and Int64
closures all pass. Their separate-run wall times are 1.12, 13.50, 16.75 and
0.28 seconds respectively; these are not controlled speed ratios.

The final historical Arena run still times out: Init at 500.014 seconds,
with last progress 2,399,999 records / 18,883 declarations; Std at 590.073
seconds, with last progress 1,999,999 / 14,314. Mathlib is skipped because
both prerequisite gates failed.

[Final diagnostic/fresh run 38001895321](https://github.com/dwijayuda/pskernel/actions/runs/38001895321)
verifies the same binary SHA-256. Complete fresh 4.35 Init and Std also time out
at the unchanged 500/590-second limits, both with exit code 124:

| Complete fresh input | Records in input | Last progress records / declarations | Peak RSS KiB |
|---|---:|---:|---:|
| Init | 6,452,982 | 2,299,999 / 18,434 | 175,280 |
| Std | 10,193,568 | 1,999,999 / 14,186 | 161,416 |

Their input hashes match the preceding sharing experiment recorded below.
These progress counters are not full acceptance. The separate 600-second Init
profile also times out (exit 124), with 175,428 KiB maximum RSS; its last entered
declaration is record 2,414,950,
`String.Slice.Pattern.Model.ForwardSliceSearcher.Invariants.isValidSearchFrom_toList`.
The 180-second worker diagnostic exits 124 at record 497,392 and 108,552 KiB.
Three of eleven sparse top-frame samples show the scalar eligibility traversal;
other samples include substitution/variable traversal, names, persistent lookup
and inference. This confirms the scalar worker is executed; it does not establish
time percentages or eliminate repeated scans.

The final controlled job uses the same 500,000-record historical Init prefix,
one runner, verified binary hashes, and the order baseline, candidate, candidate,
baseline:

| Final controlled variant | Wall seconds | Peak RSS KiB | Result |
|---|---:|---:|---|
| Repair baseline, first | 143.53 | 331,876 | Accepted prefix |
| Final sharing candidate, first | 180.00 | 99,232 | Timeout, exit 124 |
| Final sharing candidate, second | 180.00 | 98,552 | Timeout, exit 124 |
| Repair baseline, second | 142.83 | 332,012 | Accepted prefix |

The final candidate fails this performance comparison. Its lower observed RSS
is censored by timeout, so it is not a memory ratio for equal completed work.
This comparison measures the entire sharing layer against the repair baseline;
it does not isolate the scalar scan from the preceding sharing revision.
The candidate remains an unmerged native experiment and is not eligible for
default-provider promotion.

The preceding scratch/checkpoint revision,
`2e2068774b73b9affcc0852ed14caf96319d29e8`, provides a controlled warning
against equating sharing with speed. [Run 38000670791](https://github.com/dwijayuda/pskernel/actions/runs/38000670791)
ran the exact repair baseline and that candidate on one machine in the order
baseline, candidate, candidate, baseline. The same 500,000-record historical
Init prefix has SHA-256
`0d32781169f0374862e712910eb062568a8f1263aad42608b847ac353a91eb2c`.

| Earlier controlled variant | Wall seconds | Peak RSS KiB | Result |
|---|---:|---:|---|
| Repair baseline, first | 109.06 | 332,416 | Accepted prefix |
| Sharing/checkpoint candidate, first | 160.39 | 100,708 | Accepted prefix |
| Sharing/checkpoint candidate, second | 163.55 | 99,772 | Accepted prefix |
| Repair baseline, second | 109.74 | 332,024 | Accepted prefix |

The candidate reduced memory but was slower. Still earlier retained-Std.HashMap
and all-persistent-trie/cross-scope candidates timed out twice at 180 seconds on
that same prefix while their paired baselines completed in 143–145 seconds.
All these outcomes, including the abandoned storage/lifetime policies, remain
in the JSON receipt. They do not justify provider promotion.

The earlier sharing revision also timed out on complete fresh 4.35 exports:
Init contained 6,452,982 records (SHA-256
`42a17cf35c87380eb76c483de4cf3205d278a5a612047a6f90e8bd35c0a10164`);
Std contained 10,193,568 records (SHA-256
`c12663bb14aba57c4bd01699c4c90634a4432921d08f794b6736429522126dc3`).
The unchanged 500/590-second limits were enforced. Historical regression mode
and strict 4.35 mode are separate tests, not interchangeable evidence.

The architectural result is a proved execution layer and a clearer cost model,
not complete conformance. Stored constructor/name/level metadata, operation
cutoffs and batched binder transport remain the material gap from the reference
kernels. Overlay memo tables alone do not supply those properties. The next
representation/backend stage must address them with its denotation, lifetime
and context proofs; it is not claimed complete by this native checkpoint.

## Prior repair baseline

Code/proof revision: `e8ed888bb4f16153b9aac335872d770ac19bbb11`.
[Cloud run 37990758789](https://github.com/dwijayuda/pskernel/actions/runs/37990758789); native binary SHA-256
`9490526abc27b5a5e57f931613b027d1deeb72ae22787f5bf4189265f389660f`.

| Check | Result |
|---|---|
| Native foundations and reduction/cache/scope regressions | Passed |
| Existing metatheory proof suite | Passed, 195 build jobs |
| Companion proofs | 84/84 files passed |
| Tutorial | 141 correct verdicts, zero declines |
| Historical bugs | 18 correct rejections, zero accepts or declines |
| Fresh 4.35 Prelude | Accepted; 65,406 records / 1,840 declarations / 2,121 constants; 0.62 s |
| Fresh 4.35 UTF8 closure | Accepted; 159,345 / 2,146 / 2,353; 8.50 s |
| Fresh 4.35 XOR closure | Accepted; 333,731 / 3,413 / 3,752; 14.57 s |
| Fresh 4.35 Int64 closure | Accepted; 16,206 / 405 / 497; 0.21 s |
| Full historical Init | Timeout at 500.023 s; last progress 2,099,999 records / 17,010 declarations |
| Full historical Std | Timeout at 590.011 s; last progress 2,599,999 records / 19,259 declarations |
| Mathlib | Skipped because Init and Std gates failed |

The diagnostic Init job exits its checker with timeout code 124 after 600
seconds, although the workflow step succeeds to preserve its logs. Its last
entered declaration was record 4,188,018, `BitVec.getLsbD_srem`; maximum RSS
was 518,552 KiB. An entered declaration is not a completed check.

Timing/progress varies substantially across cloud runners: the runtime-equivalent
`d9b2e3e2da53406aeb727c05333f9ae0fe8e6127` run reached 3,199,999
Init records at its 500-second limit, and the same executable at
`dd354f30135b006f2f8342c866d82263d432b343` took 24.75 seconds for XOR
and 0.36 seconds for Int64. The two commits after d9b changed only proof files;
the dd354 and final e8ed native binary hashes agree. These measurements
establish focused acceptance and continuing corpus timeouts, not a stable
whole-corpus speedup.

The original migration checkpoint at
`05542332ab589314917cd67a7eb7b74e80557770` is retained as history in the JSON
receipt. Its 17-rejection/one-decline bug result and XOR reduction-budget
failure are superseded by the checks above. No merge, default-provider
promotion, selected-compiler change, joint self-host qualification, or
end-to-end consistency result is included.

That was the earlier requested stage boundary. Subsequent user authorization
started the native architectural work described above. Full Init/Std/Mathlib
conformance, portable graph/backend qualification and telescope transport remain
open requirements; proof success or a green diagnostic workflow does not close them.


[bundle]: https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/CMakeLists.txt
[official]: https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/type_checker.cpp
[replace]: https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/replace_fn.cpp
[instantiate]: https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/instantiate.cpp
[con-ops]: https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Cached/ExprOpsC.lean
[con-nodes]: https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Cached/ExprNodes.lean
[con-main]: https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/MainTheorem.lean
[nano-expr]: https://github.com/ammkrn/nanoda_lib/blob/4c544ed4099c8227f07d5de77ad1e69fb0740a27/src/expr.rs
[nano-tc]: https://github.com/ammkrn/nanoda_lib/blob/4c544ed4099c8227f07d5de77ad1e69fb0740a27/src/tc.rs
[l4l]: https://github.com/digama0/lean4lean/blob/bce3448115f7819fc12d647fadd3bb090666637e/Lean4Lean/TypeChecker.lean
[l4l-eq]: https://github.com/digama0/lean4lean/blob/bce3448115f7819fc12d647fadd3bb090666637e/Lean4Lean/EquivManager.lean
[eq-fix]: https://github.com/leanprover/lean4/pull/14806
[ron-readme]: https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/README.md
[ron-store]: https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/crates/con-ron-core/src/arena/store.rs
[ron-ops]: https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/crates/con-ron-core/src/arena/expr_ops.rs
[ron-capstone]: https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/proof/ConRon/Capstone.lean
[paper]: https://arxiv.org/html/2403.14064v1
[postmortem]: https://leodemoura.github.io/blog/2026-8-1-postmortem-for-kernel-soundness-bug-14576/
[psc0-guide]: ../../docs/selfhost-language/CURRENT.md
[trace]: https://github.com/dwijayuda/pskernel/actions/runs/37986278855
[open-experiment]: https://github.com/dwijayuda/pskernel/actions/runs/37986835891
[profile-report]: https://github.com/dwijayuda/pskernel/actions/runs/37989139275
[samples]: https://github.com/dwijayuda/pskernel/actions/runs/37988687879
[traversal-experiment]: https://github.com/dwijayuda/pskernel/actions/runs/37988845542

[persistent-map]: https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Data/PersistentHashMap.lean
