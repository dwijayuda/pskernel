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

This version is a **Lean-native research model only**. The first native regression does not demonstrate acceptance by PSC1's portable .lean parser, generated .ps source, TypeScript backend, or the independent checker. The production SelfHost root does not import V2. Portable implementation and full self-host qualification are required before integration.

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
