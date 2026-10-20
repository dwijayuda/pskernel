# PSKernel-Core Expression V2 — Lean 4.35.0 architecture pivot

Status: **M1 research implementation; NOT a production kernel replacement**.
Branch: research/psc1-pskernel-expr-v2-lean435-20261020
Baseline: 45eb5ed24f13e15e192e79e6afba8cb1f9d5736f
Lean: leanprover/lean4:v4.35.0 (eb6cafb7290e8bd5f2937522d8d804f58f02bafc)

## Architectural decision

Adopt the **algorithms and invariants** of Lean 4.35's Expr architecture, independently implemented in PSC1, instead of continuing isolated beta/substitution micro-optimizations. Long-term, replace the canonical PsKernelExpr implementation once all portable and correctness gates qualify; do not leave a second permanent expression type or compatibility adapter.

The priority is end-to-end checker performance **and** soundness, memory bounds, and self-hostability. Native-only advantages are not sufficient for promotion.

Official reference sources:
- https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/expr.h
- https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/expr.cpp
- https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/instantiate.cpp
- https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/replace_fn.cpp
- https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/type_checker.cpp

Previous benchmark evidence: docs/PSC1_PSKERNEL_LEAN435_PERFORMANCE_GAP_2026-10-20.md. The existing native zeta-chain check was 4–9x slower on the tested deep checked types; repeated full-tree FVar eligibility and hash scans are a plausible quadratic cold-chain cost. Do not extrapolate this to a general Lean-vs-PSC1 speed ratio.

## V2 architecture under implementation (M1)

Research file: packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2.lean.

- **Immutable arena DAG** with a monotonically increasing Nat node ID. Each new node can reference *only pre-existing* node IDs. This makes the graph acyclic by construction and allows intentional subtree reuse without relying on runtime pointer or GC semantics.
- Full **twelve-constructor** expression representation mirroring the current PsKernelExpr: BVar, FVar, MVar, Sort, Const, App, Lambda, Forall, Let, Literal, MData, and Projection.
- Every node stores a **cached structural hash**, exact loose-bound-variable range, has-FVar, has-expression-MVar, and approximate/structural depth. Hash currently uses the *legacy* 65521-modulus algorithm only for fully differential qualification, not as the final optimized hash design.
- **Only smart constructors** compute new-node fields bottom-up after looking up its children. Invalid child IDs fail closed; the decoder also rejects forward or out-of-bounds references.
- The materializer creates each DAG node once in topological order, maintaining structural reuse in the resulting legacy representation. A fuel-bounded importer is a migration boundary, *not* the intended steady-state checking path.
- Same-arena identity can short-circuit valid equality; for other IDs, a matching hash triggers **actual structural comparison**, never unconditional equality. Binder annotations and display names intentionally follow PSC1 legacy semantic equality. Hashes are not proof certificates.
- A validator recalculates the hash, range, flags and depth from independently decoded *legacy* expressions for every DAG node, and rejects forged metadata. The public arena structure is not yet sealed; **no V2 result can be trusted by the kernel without validation**.

**Updated qualification:** The main Expression V2 module has now passed both native regression and a real PSC1 compiler check: [GitHub Actions 39380246845](https://github.com/dwijayuda/pskernel/actions/runs/39380246845), including 234 PSC1-checked declarations. A separate native Expr V2 run [39376416446](https://github.com/dwijayuda/pskernel/actions/runs/39376416446) passed 124 individual V2 assertions. This does **not** qualify generated JS, the alternative persistent index, full kernel M3–M5 integration, or independent soundness. The production SelfHost root continues to exclude V2.

## M2 discovery: array-backed DAG vs persistent indexed DAG

The TypeScript backend at psc1/packages/backend-ts/src/Ps/BackendTs/Expr.lean, intrinsic arrayPush case, emits the complete expression "[...(array), value]". The DirectJS backend in packages/backend-js/src/Ps/BackendJs/Print.lean similarly emits a spread-copy. Therefore building an immutable V2 arena with one array push per node copies the entire existing array each time: O(N²) total copied elements over N inserts. This is confirmed in the backend **source**, not guessed from native Lean timing.

The research implementation now includes packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2Index.lean, a persistent binary trie keyed by exact (node ID + 1), independent of cached *expression hash*. Each insert/lookup traverses O(log N) tree levels and reuses unchanged branches. The scheme prevents index-key collisions by construction, but it still needs benchmarks: generated JS executes Nat arithmetic as BigInt and uses a generator runtime for general recursion; its constant factors can be high.

The new test at test/PsKernelExprV2Regression.lean compares array-backed and index-backed metadata for 384 nodes, tests out-of-range access, verifies immutability after extension, and retains hash-collision/forged-metadata tests. The updated PSC1 Expression V2 GitHub workflow now checks this indexed source through PSC1, attempts TypeScript 7.0.2/JS emission, and runs runtime smoke with storage cost observations. These **additional gates are not complete** until the corresponding CI runs pass.

An indexed entry is not a permission to trust data: before V2 can reach the kernel, imported/serialized graph payloads must be recomputed and checked, with node-IDs scoped to their owning immutable arena.

## Migration milestones

**M1 (this branch):** Implement all constructors, metadata, DAG sharing, topological decode, importer, validation and structural equality. Validate equality against the old kernel, correct hash collisions, invalid and forged metadata, binder depth and growth. Native Lean 4.35 CI must be green.

**M2:** Convert the V2 research representation to PSC1-compatible source (or first implement only truly minimal Array/arena primitives). Build with the *real* PSC1 compiler. Generate and run JS and TypeScript code, check equivalence with the native Lean V2, and measure import, build, lookup, RSS and post-GC heap. Decide whether Array-backed immutable arenas are efficient enough in JS; do not assume persistent Array updates are cheap in every backend.

**M3:** Implement validated arena-native lift, instantiation, substitution, WHNF prerequisite traversal and equality *without repeatedly importing/materializing legacy trees*. Reuse nodes when unchanged, memoize (node ID, binder depth) transformations within an operation. Verify fuel/termination and context-cache eligibility on every source/output fixture.

**M4:** Replace source checker cache keys and local-context indexes with validated V2 metadata and improved persistent structures, first behind a dual-check research gate. Preserve no-false-negative FVar checks, exact binder-depth handling, universe normalization, failed/successful cache semantics, and scoped cache restoration.

**M5:** Migrate the 79-module checker source, remove old representation and conversion overhead when parity is qualified. Keep any external serialization version explicit; do not treat a V2 cached hash or NodeID as a proof, or accept unvalidated payloads. Complete native source equality, canonical .ps reconstruction, generated JS execution, current Lean 4.35 official cross-check fixtures, full Arena coverage if achievable, and whole-checker A-B-B-A memory/timing.

## Non-negotiable invariants

1. **Metadata must not become an admission authority.** Hash collisions require structural equality. Synthetic/interned IDs from external sources do not grant equality; equality-by-ID applies only inside the same validated, immutable arena.
2. **No false-negative free-variable flag.** A term containing local FVars must not be classified context-independent. V2's validator verifies this against the legacy recursive scan; invalid metadata fails closed.
3. **Loose-bvar range is exact** after accounting for binder depth. An underestimate can make substitution unsound. The validator independently recomputes it.
4. **Topological DAG construction:** child references must predate parents, and an untrusted serialized DAG must be fully validated before use. Cycles or invalid references fail closed.
5. **No semantic changes** to Lean 4.35 DefEq, WHNF, recursor/iota behavior, universe equalities, proof irrelevance, axioms, or unchanged resource policy. No inferred speedup from microbenchmarks alone.
6. **Native plus portable:** no host-only memory tricks that PSC1 cannot represent; do not sacrifice self-hosting for a Lean-native score. No Rust-only kernel implementation, shell-native executable shortcuts, or runtime compiler trust.
7. **Controlled benchmarks:** same compiler source and Lean pin, comparable input fixtures and verified verdicts, order-balanced native and JS measurements, high-water RSS and retained heap; regressions or statistically uncertain gains block promotion.

## Known risks / architecture decisions

- Array-backed arena lookup is efficient natively but persistent updates may copy arrays in generated JS. This is an open measured-design question; alternatives are chunked immutable arrays, persistent indexed vectors or a scoped builder that freezes before checking. Never assume O(1) immutable append on the JS backend without profiling.
- The current V2 hash deliberately matches legacy's limited 16-bit-ish 65521 modulus. It guarantees *legacy parity*, not low collision rates. The final hash must use an independently verified stable computation with full structural collision checking.
- Interning/hash-consing is optional until measured. Existing intentional node sharing is sufficient for first-stage identity lookup and avoiding duplicate term construction.
- The current V2 equality fallback is structurally recursive and bounded by arena size. A memoized pair cache can improve DAG equality later if semantics and memory support it.
- Materialization/validation recursively traverses the decoded legacy tree and is intentionally expensive; do not call it for every production operation.
- PSC1's JS codegen currently uses BigInt and a generator-stack runtime for general recursion; V2 cannot eliminate all backend overhead by itself.

**Exit criterion for M1:** independent native CI green, all constructor parity and explicit sharing, incorrect metadata/forward references rejected, hash collision not equated. Production checker code remains byte-identical to baseline; no automatic merge.


## Qualified V2 M2 and native M3 evidence

### V2 M1/M2: source and generated-JS qualification

- The full twelve-constructor immutable DAG with cached structural hash, exact loose-variable range, FVar/expression-MVar flags and depth, explicit subtree reuse, topological import/decode, collision-safe equality and metadata validation passed the native differential CI.
- [Expression V2 CI 39382990568](https://github.com/dwijayuda/pskernel/actions/runs/39382990568) **PASSED** native and PSC1 portability jobs, exercising both indexed and chunked all-constructor builders. Real PSC1-generated TypeScript 7.0.2 and Node22 JavaScript passed. The combined V2 source contains 271 PSC1-checked declarations.
- [Production PSC1 correctness 39382990460](https://github.com/dwijayuda/pskernel/actions/runs/39382990460) **PASSED** native and full 79-module self-hosting portability; the production checker does NOT import research V2.

### Storage ablation

PSC1-generated TypeScript and DirectJS implement Array.push by creating a new array with spread-copy. An Array-backed growing DAG can therefore incur quadratic copied elements. The persistent binary index avoids O(N)-per-append copies, but was extremely slow on Node22 because it invokes generated recursive and BigInt operations at each index level.

[CI 39382668149](https://github.com/dwijayuda/pskernel/actions/runs/39382668149) stored identical prevalidated metadata entries and verified readback of oldest, middle, and newest entries. Every timed snapshot remained live for forced-GC retained-heap observations.

| Size | Full array, ms | Chunk 16, ms | Chunk 32, ms | Chunk 64, ms | Binary index, ms |
|---|---|---|---|---|---|
| 256 | 0.955 / 0.217 | 0.544 / 0.299 | 0.240 / 0.329 | 0.234 / 0.190 | 75.935 / 65.204 |
| 1,024 | 1.237 / 0.979 | 1.022 / 1.147 | 0.800 / 1.526 | 0.725 / 0.259 | not checked |
| 4,096 | 8.198 / 8.017 | 2.053 / 2.124 | 1.613 / 1.015 | **1.031 / 0.733** | not checked |

The *research* chunk default is now 64. These are two synthetic, order-dependent samples per variant, not a statistical generalization or whole-kernel speedup. Whole-checker end-to-end memory and throughput still determine production promotion.

### M3 — validated sharing-aware binder lifting

Research module: packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2Lift.lean.

- The public liftChecked entry validates every input chunked-DAG node via independent smart-constructor replay and checks the exact root ID.
- A verified, cached loose-bound-variable range proves when a subtree can be reused unchanged.
- Recursive lift preserves all unchanged node IDs, updates only changed nodes through smart constructors and memoizes by original ID, binder cutoff, and lift amount. This prevents exponential repeated work on structurally shared subgraphs.
- The output DAG is fully replay-validated. Forged metadata and forward child references fail closed.
- [Native M3 CI 39383763403](https://github.com/dwijayuda/pskernel/actions/runs/39383763403) **PASSED** 108 finite oracle comparisons across nine expression shapes, four cutoffs and three amounts. It also verified unchanged-node identity, invalid-metadata rejection and the sharing bound: 21 input nodes grew only to 42 output nodes.

**M3 portability is NOT complete.** The native lifting reference uses Lean do/mutable-local constructs not accepted by PSC1's current source subset. It remains outside the portable V2 composition root and production checking. The next step is functional PSC1-source lowering for the lift and then independent generated PS/JS differential qualification, followed by capture-avoiding substitution, WHNF and DefEq integration.

### Promotion rules remain unchanged

No unvalidated metadata may grant proof admission or skip structural equality. Hash collisions require equality checks. Loose-bvar range must not underestimate and hasFVar must never be falsely negative. Keep Lean 4.35 semantics, the fixed fuel policy, scope-safe memoization, 79-module source self-hosting, generated JS and negative/adversarial regression gates. Do not merge research V2 into main until whole-checker measurements demonstrate a benefit and the correctness gates pass.
