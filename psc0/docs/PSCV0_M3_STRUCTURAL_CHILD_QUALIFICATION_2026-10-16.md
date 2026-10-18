# PSCV0 M3+B — definitionally equal strict-child recursion qualification
16 October 2026. Selected v7.2 M3+B slice **ACCEPTED**. M3+B overall remains **OPEN**.

## Exact implementation and evidence
- Implementation/test commit: `8e7f18885a3e917fbdf000d7d108842b2cc1f067`; parent candidate `f560a1df7f14caeaf8fe690dbaa3a7f10eee8388`.
- Same-commit native [38923349115](https://github.com/dwijayuda/pskernel/actions/runs/38923349115): **SUCCESS**. Native job `117048713342` passed **33/33 reported steps**, none skipped; setup and cleanup included.
- Independent F1 [38923349086](https://github.com/dwijayuda/pskernel/actions/runs/38923349086): SUCCESS.
- Independent F2 [38923349001](https://github.com/dwijayuda/pskernel/actions/runs/38923349001): SUCCESS.
- Independent F3/F4/platform [38923349042](https://github.com/dwijayuda/pskernel/actions/runs/38923349042): SUCCESS.
- Focused recursive deriving [38923349138](https://github.com/dwijayuda/pskernel/actions/runs/38923349138): SUCCESS, with native Lean oracle, emitted JavaScript, strict compiled TypeScript, pinned Rust, V8 GC core and Wasmtime component execution. Focused artifact `12055622292`, SHA-256 `02f9f2c70b882f6f20f42e360a1d241b4286733dde2d0fac9c8511e856e29d7e`.
- Native artifact `12056376919`, SHA-256 `4bb1b96340d0673e1e452af0d3355324d2a9504618e0768b793635690b4653b9`.

## Bounded admitted semantics
- Shared native `.lean` structural-call elaborator selects a computed *first-position* recursive major only when its once-elaborated Core term is read-only definitionally equal to an existing strict constructor field with an already-checked induction hypothesis. The actual child telescope, indices and invariant arguments remain checked. No hypothetical or untrusted recursive hypothesis is created.
- Shared primitive conversion recognizes the pinned Lean 4.35.0 `Nat.add a 0` definitional equation for open `a`. This is **not** a new `Nat.add 0 a` definitional equation and does not assume unrestricted arithmetic simplification.
- The focused independent Lean oracle checks `normalizedChild` recursively on `Nat.add k 0`, with a corresponding `.ps` checked defining equation. One additional `m3normoutput` Bool-to-UInt64 observation is emitted for two flags in each existing target lane; recursive values remain internal.
- The new `nondecreasing-major` negative deliberately attempts recursion on `Nat.succ k` and must fail in elaboration for the intended structural-decrease rule. Existing negative/positive cases, benchmark sizes, source/Standard/kernel/erasure/backend gates remain intact.

## Limits and history
- **Not qualified:** the infix `k + 0` instance-projection source path, computed decreasing majors in non-first positions, course-of-values recursion, general nested/mutual/indexed elimination, well-founded recursion, partial P0 ordinary execution, fixedpoint P1, verified artifacts or overall M3+B exit.
- Failed fixed-discriminant preparation at `9f15ef1` and its GitHub workflow `38920126614` remain *historical, unqualified experiments*. Early computed-child candidates `80d06544`, `9524c757` and `56068f19` failed their focused gates; focused-only `f560a1df` succeeded but was not independently sufficient for integrated acceptance.
- Accepted earlier M2+A `pscv0-v7-native-bounded/73`, direct-recursive Hashable/Repr/BEq/DecidableEq and runtime comparison receipts are unchanged. No pskernel-core, self-hosting, independent kernel, assumption expansion, weakened refusal, or new performance claim.
- The sole forward `.ps` target is v7.2 blob `694115223777599ba28ee175e14bb642b7b6aa4b`, with pinned official Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

Next slice: inspect remaining source-elaboration/recursion ownership and preserve exact five-gate validation. PR #109 must remain draft/open/unmerged on its existing base; use non-force expected-HEAD updates and maintain both handoffs.
