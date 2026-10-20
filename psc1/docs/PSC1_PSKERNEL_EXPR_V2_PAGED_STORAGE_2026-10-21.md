# PSKernel-Core Expression V2: Paged Storage Design and Validation

Date: 2026-10-21
Branch: research/psc1-pskernel-expr-v2-lean435-20261020
Lean pin: leanprover/lean4:v4.35.0
Status: **qualified research implementation; not the production kernel representation**

## Decision

**The two-level immutable paged arena is the leading V2 expression-storage candidate**, replacing the linked-list-of-chunks design at the eventual checked implementation boundary. This selection is based on identical-operation and metadata parity tests in both the native Lean 4.35.0 research harness and independently generated PSC1 TypeScript/JavaScript.

Do not yet remove the original V2 chunked implementation: it is an independent performance/correctness baseline. Do not copy the experimental paged graph directly into the 79-module trusted checker until all existing WHNF/DefEq operations, fuel policy, and self-hosting checks qualify.

## Three measured representations

1. **Flat immutable Array**: cheap indexed reads; generated TS/DirectJS implements immutable Array.push by copying the entire old array, causing O(N²) cumulative append copy work.
2. **Linked frozen chunks**: bounded active-chunk copy work but O(N/C) older-node lookup, where C is chunk size. Deeper DAG builders repeatedly access old children and therefore accumulate substantial lookup cost.
3. **Paged Arena (chosen research candidate)**: completed pages are stored in a directly indexed immutable Array of Arrays; the active page is separate. Append copies at most C active entries; only a page rollover copies the outer page-index array. Older-node lookup uses quotient/remainder and indexed Array.getD rather than walking frozen chunks.

For N nodes and fixed page size C, the paged scheme has O(1) indexed page lookup in the abstract collection model, bounded O(C) active append copies, and cumulative O(N*C + (N/C)^2) copied references. The outer table is still immutable/copy-on-append; at very large scales the quadratic term in page count remains relevant. Generated JavaScript also pays BigInt quotient/remainder and call-dispatch overhead.

Research files:
- packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2Paged.lean
- packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2PagedBuilder.lean
- packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2PagedValidation.lean

All twelve expression constructors preserve cached structural hash, exact loose-variable range, FVar/MVar flags and depth via previously qualified bottom-up metadata rules.

## Qualified correctness gates

[GitHub Actions run 39470758508](https://github.com/dwijayuda/pskernel/actions/runs/39470758508) **passed native and PSC1-generated JS jobs**.

The native regressions verify:
- Every expression smart constructor's metadata against the original flat V2 model.
- All 512 node IDs under five page capacities: 0 (clamped to 1), 1, 8, 32 and 64.
- Persistent snapshots, valid old/middle/recent indexed lookups and rejection of out-of-bounds node IDs.
- Full replay validation of metadata, topological child-ID order, the claimed arena size and page layout.
- Rejection of forged FVar metadata, forward references, zero-capacity payloads, incomplete completed pages and inconsistent node counts.

The generated JS job compiled the canonical V2 source with the real PSC1 compiler using TypeScript 7.0.2, and exercised paged lookup, validation, append, and old-node access without changing the trusted production checker.

[GitHub Actions run 39471446971](https://github.com/dwijayuda/pskernel/actions/runs/39471446971) **also passed native and portable JS jobs**, adding 1,024-node native sharing parity and checked generated-JS shared-application DAG construction at 1,024, 4,096 and 8,192 edges. Every benchmark validates node counts, metadata-derived depth and loose-variable range, old-leaf lookup, and matching expression hash checksums.

## Generated-JavaScript benchmarks (Node 22)

### Indexed older-node lookup

120 verified reads from an immutable 4,096-node arena, ordered chunked/paged/paged/chunked:

| Representation | First observation | Second observation |
|---|---:|---:|
| Linked chunks | 31.522 ms | 35.872 ms |
| Indexed pages | 0.832 ms | 0.520 ms |

Measured improvement: approximately **38–69x on this narrow lookup workload**.

### Real shared-application spine construction

Each fresh App references the previous expression root and a shared BVar leaf at node zero. Both implementations output identical node counts, hash checksums, depth, loose range and FVar flag. Two measurements per representation in A-B-B-A order:

| Arena nodes | Linked chunks | Indexed pages |
|---|---:|---:|
| 1,025 | 62.858 / 52.855 ms | 20.885 / 22.860 ms |
| 4,097 | 813.429 / 715.161 ms | 64.703 / 63.078 ms |
| 8,193 | 2571.855 / 2621.698 ms | 128.484 / 106.916 ms |

The 8,193-node data shows **approximately 20–24x faster construction** for this synthetic DAG workload.

### Allocation caveat

The 39471446971 process reported RSS and post-GC V8 heap for the entire generated V2 module and benchmark suite; these are **not** isolated per-representation heap measurements. This benchmark reports elapsed time of construction/lookup but does not compare worst-case page rollover under multiple live immutable snapshots or million-node graphs. Results cannot be interpreted as full-kernel performance improvements or a soundness proof.

## Soundness boundaries

- No cached structural hash authorizes expression equality or proof checking by itself. Hash collisions still require structural comparison.
- The paged graph's node ID denotes identity only within **one** immutable arena. It cannot be persisted into another context and used as proof.
- Public paged records can be forged. Only psKernelExprV2PagedValidate returns a canonical arena reconstructed from validated smart constructors. It rejects malformed layout and metadata; no arbitrary source arena can be treated as validated solely because its fields exist.
- Every binder transformation must preserve exact loose-bvar range and avoid false-negative FVar checks. **Both paged and chunked research workers now exist** for lift, capture-avoiding instantiate1 and bounded beta/zeta/metadata head reduction. Their finite differential tests passed, but no V2 worker is part of production checking.
- The 79-module production PSKernel-Core checker and all published fuel/axiom policies remain unchanged.

## Next acceptance steps

1. Benchmark larger arena sizes and **real shared-expression** workloads with retained snapshots and separately measured memory, selecting the optimal page size from stable evidence rather than one benchmark.
2. **Completed as a research gate:** paged lift, instantiate1, bounded head reduction, structural equality, batched equality and checked legacy-tree import all passed matched native and PSC1 .lean/.ps/JS regression. The next step is completing missing WHNF/DefEq semantics, not swapping these subset workers into production.
3. Run end-to-end checker workloads using equivalent inputs, identical checking decisions, and the published resource policy before claiming production speedups.
4. **Completed:** the canonical .ps reconstruction gate passed for the V2 ResearchAll closure, now 28 modules. The workflow independently checks source, generated PS declarations and executable TS7/JS output on Node22. This is not a repeated compiler self-host fixed point.
5. Preserve independent proofs/Lean Arena negative cases and memory regressions as hard blockers to promotion. Do not merge research V2 into the trusted kernel yet.


## Completed M4 semantic migration pilot (research only)

Pushed research sources: ExprV2PagedLift.lean, ExprV2PagedInstantiate.lean, ExprV2PagedHeadMachine.lean, ExprV2PagedEquality.lean, ExprV2PagedEqualityBatch.lean, and ExprV2PagedImport.lean. Each has a checked public gateway with full canonical replay validation; internal helpers operate only on the caller's already-validated immutable arena. Future integration must enforce that invariant at the type/API boundary.

Verified CI:
- [39483527403](https://github.com/dwijayuda/pskernel/actions/runs/39483527403): all 3 jobs passed; 48 paged instantiate1 cases against both original PsKernelExpr and chunked V2, bounded head sequences and adversarial fuel/error handling; 25-module canonical .ps source closure; TS7 and JS runtime smoke green.
- [39485265194](https://github.com/dwijayuda/pskernel/actions/runs/39485265194): all 3 jobs passed; 16 paged equality comparisons against the legacy oracle, memoized equality of structurally shared DAGs, sorted equality-batch parity and forged/colliding metadata rejection, plus all-constructor paged legacy import with beta reduction; full **28-module canonical .ps closure** and generated JavaScript green.

Controlled Node22 microbenchmark evidence from [39485265194](https://github.com/dwijayuda/pskernel/actions/runs/39485265194):
- Same 12 equal comparisons on 41-node shared DAG: chunked V2 3.589 / 9.252 ms; paged V2 3.850 / 3.615 ms. There is **no reproducibly demonstrated throughput win** for this small checked equality batch.
- Same direct head-reduction sequence at depth 48: chunked 8.818 / 11.874 ms, paged 14.921 / 9.713 ms in the prior [39483527403](https://github.com/dwijayuda/pskernel/actions/runs/39483527403). Again, no dependable advantage at this small size.
- By contrast, large DAG construction/lookup saw a clear V2 storage advantage for pages; this supports keeping **paged storage as the leading design**, not declaring every paged kernel operation faster.

Native and generated-JS differential tests are finite acceptance evidence, not mathematical proof of metatheory preservation. Copying old expressions into V2 remains expensive, can destroy preexisting sharing, and is not a viable per-operation migration strategy. Cache safety, fuel, recursors, delta, universes, proof irrelevance, polymorphic inference and full WHNF/DefEq have not been migrated. **Production kernel source is byte-identical** across the recent V2 feature commits; only isolated Research modules, test harnesses, Lake research registration, workflow paths and documentation changed.

### Updated next milestone: real kernel workloads

1. Design **one** reusable paged expression runtime with isolated validated ingress, smart constructors and checked query sessions, replacing duplicate research implementations only after verified semantic parity.
2. Implement full Lean-4.35-compatible WHNF mechanisms (application function, delta, projections, recursor/iota and supported primitive reductions) with exactly the existing checker fuel/soundness policy; do not treat the bounded beta/zeta model as complete.
3. Integrate paged structural equality only as a **verified** optimization behind a dual-check gate, with adversarial hash collisions, free-variable-context isolation and identical negative admission behavior.
4. Profile real complete-checker workloads including initial import/construction, cache effects, retained heap/RSS, TS/JS execution and direct comparison with official Lean 4.35. No source-only helper speedup qualifies a production promotion.
