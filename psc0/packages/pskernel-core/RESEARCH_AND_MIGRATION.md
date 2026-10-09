# PSKernel Core: Lean 4.35 repairs and architecture review

Date: 2026-10-10 (Asia/Jakarta). Work was performed through GitHub and cloud CI.

## Decision and scope

The active package is `psc0/packages/pskernel-core`, targeting the user-selected
Lean **4.35.0-rc4**, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
The current repair stage addresses reduction order, resource accounting,
cache modes/scope, and redundant traversal. It does not establish complete
Arena or Mathlib conformance. Exact final results are recorded below and in
[MIGRATION_EVIDENCE.json](MIGRATION_EVIDENCE.json).

The remaining performance problem is architectural: PSKernel preserves
sharing when reading an export, but its semantic operations often traverse
that shared graph as an expanded tree. Increasing timeouts, adding a
declaration-name exception, or copying a native-only pointer optimization
does not resolve that mismatch. The next representation stage is specified
here and remains unimplemented at this checkpoint, honoring the request to
stop before the next stage.

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

## Next representation stage: coherent design, not fixture repair

This stage is deliberately not started in the current repair checkpoint.

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

## Latest repair checkpoint

Code/proof revision: `e8ed888bb4f16153b9aac335872d770ac19bbb11`.
[Cloud run 37990758789](https://github.com/dwijayuda/pskernel/actions/runs/37990758789); native binary SHA-256
`9490526abc27b5a5e57f931613b027d1deeb72ae22787f5bf4189265f389660f`.

| Check | Result |
|---|---|
| Native foundations and reduction/cache/scope regressions | Passed |
| Complete metatheory | Passed, 195 build jobs |
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

**Stage boundary:** the current repair and research checkpoint ends here.
The coherent graph/metadata/traversal redesign above is the next implementation
stage; full Init/Std/Mathlib conformance remains an open requirement.


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
