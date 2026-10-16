# M3+B selected Array-nested recursor adaptation — qualified

**Accepted selected v7.2 compiler slice; the overall M3+B milestone remains OPEN.**
Reported 17 October 2026 in Asia/Jakarta.

## Exactly qualified implementation

- Compiler/test commit: `8f217a80a6010b5db83affb5f608d494521b44bf`; the later focused-only runtime test `59fa293d587e83c3c5fe6d9572debb82a385a30a` is a separate implementation identity.
- [Native Linux CI 38943289653](https://github.com/dwijayuda/pskernel/actions/runs/38943289653): **SUCCESS**; job `117116013565` passed all **33/33** reported steps, including setup and cleanup, none skipped. Artifact `12064219733`, SHA-256 `b3d2532d532d320c103d1c6a56bed8df8a26febeba320f02c0645349df444e54`.
- [F1 38943289504](https://github.com/dwijayuda/pskernel/actions/runs/38943289504): **SUCCESS**.
- [F2 38943289694](https://github.com/dwijayuda/pskernel/actions/runs/38943289694): **SUCCESS**.
- [F3/F4/platform 38943289454](https://github.com/dwijayuda/pskernel/actions/runs/38943289454): **SUCCESS**.
- [Focused recursive/native oracle and target qualification 38943289601](https://github.com/dwijayuda/pskernel/actions/runs/38943289601): **SUCCESS**.

The official Lean 4.35.0 kernel bridge now explicitly recognizes the pinned `Array α` single-constructor structure with `toList : List α` when adapting zero-parameter/zero-index nested family recursors. The bridge's array case uses the actual List-shaped constructor field; no new axiom, unchecked recursor or erasure acceptance was introduced.

## Separate subsequent runtime evidence

- Test-only `59fa293d587e83c3c5fe6d9572debb82a385a30a` adds a zero-parameter `M3NestedArrayRose` family and shallow scalar `m3nestedarrayoutput` for `leaf` and `node(#[])`.
- [Focused CI 38943635308](https://github.com/dwijayuda/pskernel/actions/runs/38943635308): **SUCCESS**, 15/15 job steps. Independent pinned Lean oracle and exact direct JavaScript, compiled TypeScript, pinned Rust, V8 GC and Wasmtime component outputs passed. Artifact `12064217472`, SHA-256 `3f28b0dd2bd76f6400dc07664a5fa20b84366a497b7a34053ff5d73589ab1a29`.
- This later test-only commit did **not** need a new full native integration qualification for unchanged compiler code. It does **not** prove nested recursive traversal or parameterized/container-generic backend support.

## Hard boundaries

The accepted result concerns selected monomorphic **shallow** pattern matching over a structurally nested List/Array field; existing negatives, positivity/uniform-parameter rules, kernel budgets, proof erasure, IR validation, original performance baselines and target ABI remain unchanged.

Pending: group-aware mutual/nested/indexed inductives and general recursors, nested recursive deriving/traversal, full source recursion strategies and well-founded evidence, ordinary partial P0, fixedpoint P1 and complete cross-stage M3 acceptance. No pskernel-core, compiler source self-hosting, independent checking kernel or assumption expansion. Only the official pinned Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc` is used. PR #109 remains draft/open/unmerged on its original base.
