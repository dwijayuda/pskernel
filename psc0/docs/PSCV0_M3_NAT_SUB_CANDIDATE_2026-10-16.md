# PSCV0 M3+B — open Nat.sub strict-child candidate
16 October 2026. **Candidate only; integrated acceptance pending exact native run.**

- Compiler/test: `721b97038926db5f34e2da1cf7157c68c18234ff`, descendant of accepted M3 prefix-recursion `8f8aa47f` / documentation `88931aa3`.
- Pinned official Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. `Init/Prelude.lean` defines `Nat.sub a 0 = a` by definitional computation on the second argument; `Init/Data/Nat/Basic.lean` states `Nat.sub_zero n` by `rfl`. No stronger arithmetic rule is assumed.
- Shared `Ps.Meta.NatReduce` now recognizes open `Nat.sub a 0 ↝ a` exactly like the separately accepted `Nat.add a 0 ↝ a`, while preserving the closed-literal Nat operations and refusing `Nat.sub k 1` as a strict direct child absent an actual checked IH.
- Native portable `.lean` independent `normalizedSubChild` oracle, checked `.ps` defining equation and `m3suboutput` Bool-to-UInt64 execution check extend the *existing* focused suite; one `badSubMajor` negative must fail at the intended elaboration rule. No new test suite or weakened budget.
- F1 [38931145674](https://github.com/dwijayuda/pskernel/actions/runs/38931145674): SUCCESS.
- F2 [38931145639](https://github.com/dwijayuda/pskernel/actions/runs/38931145639): SUCCESS.
- F3/F4/platform [38931145711](https://github.com/dwijayuda/pskernel/actions/runs/38931145711): SUCCESS.
- Focused [38931145641](https://github.com/dwijayuda/pskernel/actions/runs/38931145641): SUCCESS. Pinned native Lean, direct JS, strict compiled TS, locked Rust, V8 GC and Wasmtime.
- Full native [38931145719](https://github.com/dwijayuda/pskernel/actions/runs/38931145719): **IN PROGRESS at record time**. Do not mark the slice accepted until that same SHA's full native workflow passes. If it fails, inspect the exact failing stage without changing assertions, budgets or admission boundaries.

M3+B still needs broader nested/indexed/mutual data and deriving, motive/pattern elimination, measure/well-founded recursion, source strategy ownership and selected P0/P1 assurance/execution/fixedpoint obligations. Earlier M2 and deriving/performance receipts are unchanged; no performance improvement is claimed for this source-semantic conversion. PR109 stays open/draft on its original base.
