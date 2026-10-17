# PSCV0 M3+B — open Nat.sub right-zero strict-child qualification
**Accepted selected v7.2 slice, 16 October 2026. M3+B overall remains OPEN.**

## Exact checked implementation and all-five integration evidence

- Compiler/test SHA: `721b97038926db5f34e2da1cf7157c68c18234ff`; source tree and existing native tests are unchanged by this evidence-only child.
- Native full source/kernel/module/backend/GC/Wasmtime/benchmark qualification: [38931145719](https://github.com/dwijayuda/pskernel/actions/runs/38931145719): **SUCCESS**. Job `117075139150`, **33/33 reported steps successful including setup/cleanup**, none skipped.
- F1 canonical model: [38931145674](https://github.com/dwijayuda/pskernel/actions/runs/38931145674): SUCCESS.
- F2 logical operations: [38931145639](https://github.com/dwijayuda/pskernel/actions/runs/38931145639): SUCCESS.
- F3/F4/platform: [38931145711](https://github.com/dwijayuda/pskernel/actions/runs/38931145711): SUCCESS.
- Focused recursive derivation, positive/negative recursion and all target lanes: [38931145641](https://github.com/dwijayuda/pskernel/actions/runs/38931145641): SUCCESS.
- Native artifact `12060152036`, SHA-256 `9242904ea257b08897aad41611a1aa1d30f7bb7df373339f6a1f87b947fdbb02`.
- Focused artifact `12059600505`, SHA-256 `7827ba6487723a4f7c8aeba846cd60900e802283db5aa4674565093205e4d464`.

## Selected semantics actually qualified

In native portable `Ps.Meta.NatReduce`, reduce `Nat.sub a 0` to `a` even with open `a`, exactly as defined by pinned Lean 4.35.0 `Init/Prelude.lean`. This is a **definitional right-zero equation**, not a general decrease inference, new axiom or unchecked termination method. The existing structural IH still must be a genuine strict constructor child, and the recursively computed argument must pass the dependent telescope/invariant checks.

The existing focused suite compares an independent pinned Lean oracle `normalizedSubChild`, a PSCV source equation checked with `rfl`, and an additional scalar `m3suboutput` for both flags across direct JS, strict compiled TS, pinned Rust, V8 GC and Wasmtime component. A `Nat.sub(k,1)` non-child recursive major is rejected at the intended elaboration rule/phase. Original deriving, modules, proof erasure, refusal checks, artifact counts and performance gates are unchanged.

## Boundaries and history

This qualifies the above **selected structural recursion/conversion slice**, not unrestricted well-founded recursion, nested/mutual/indexed deriving, every motive/pattern, partial P0 executable semantics, fixedpoint P1, verified target correspondence or full M3+B. Source `k + 0` through HAdd instances is separately under focused test in newer test-only commit `3a2fbdfa3ec4c63e6134792892b6c1a26028c25e` and is **not** part of this accepted receipt.

Earlier accepted direct-recursive Hashable/Repr/BEq/DecidableEq, computed child `8e7f1888`, fixed/evolving-prefix recursion `8f8aa47f`, original M2+A profile 73 and performance-study evidence remain preserved. Sole forward `.ps` target v7.2 blob `694115223777599ba28ee175e14bb642b7b6aa4b`, pinned official Lean 4.35.0 SHA `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, approved logical principles only `propext` and `Quot.sound`. No pskernel-core, self-hosting or independent kernel changes. PR #109 remains draft/open/unmerged on its existing base.
