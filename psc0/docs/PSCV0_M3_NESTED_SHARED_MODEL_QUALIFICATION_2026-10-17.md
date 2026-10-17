# Selected nested positive container shared model — qualified (M3+B)

**Compiler/test:** `a7c6dade87a9d8df74d5248e8276623e7870078c`. **Selected slice ACCEPTED**, full M3+B OPEN. 17 October 2026 (Jakarta reporting).

## Five same-commit qualifications

| Gate | Workflow | Exact result |
| --- | --- | --- |
| Full native source/kernel/IR/JS/TS/Rust/GC/Wasm/module/measurement | [38946629082](https://github.com/dwijayuda/pskernel/actions/runs/38946629082) | **SUCCESS** — native job `117127286663` 33/33 steps including setup/cleanup, no skips |
| F1 canonical model | [38946629149](https://github.com/dwijayuda/pskernel/actions/runs/38946629149) | **SUCCESS** |
| F2 logical operations | [38946629024](https://github.com/dwijayuda/pskernel/actions/runs/38946629024) | **SUCCESS** |
| F3/F4/platform | [38946629155](https://github.com/dwijayuda/pskernel/actions/runs/38946629155) | **SUCCESS** |
| Focused independent Lean oracle, refusal matrix, five runtime lanes | [38946629090](https://github.com/dwijayuda/pskernel/actions/runs/38946629090) | **SUCCESS** |

Native artifact `12065898831`, SHA-256 `c988cbed4f846eb17567662258015cdf7c882e1192e6f6ae44b41ba639f3e1af`. Focused artifact `12067240660`, SHA-256 `65870b33dc1dea56453f317cacd0593883ef71e05c468433b5c97ed60489c328`.

## Actual implementation

Introduced `Ps.Core.Nested` as one portable, pure description of the selected pinned Lean 4.35.0 List, Option, Array and Prod shapes. `Ps.Elab.Data` consumes its positive child arguments when checking recursive family uniformity; `Ps.Bridge.CheckedAdmissions` consumes the *same* representation for exact nested-constructor field telescopes. There is no second hand-maintained whitelist, no generated induction hypothesis and no new proof axiom. The official kernel checks the resulting source admissions.

The existing List/Array Rose shallow scalar backends and all negative cases remained. The focused suite adds a check-only `Option Rose` and `Prod Rose` shallow constructor/match oracle; these are *not* new executable Option/Prod traversal guarantees.

## Distinctions and next dependencies

- This is selected strictly-positive **nested representation/checking**, **not** arbitrary generalized nested/mutual/indexed groups or nested recursive deriving, universal positivity, well-founded termination, or backend semantic preservation.
- The selected P0 partial *logical* admission remains separate from its executable body and has not yet passed ordinary runtime emission; P1 fixedpoints and closed/boundary verified artifacts are still unavailable.
- The next candidate explicitly pairs independently kernel-checked logical opaque partial declarations with the actual separately checked runtime body, only for ordinary outputs after host checking. Verified requests remain fail-closed. **Do not mark this design accepted before new exact-commit qualifications.**
- M2+A original profile and prior M3 Hashable/Repr/BEq/DecidableEq, nested List/Array, performance and assumption receipts remain unchanged. No pskernel-core, independent kernel, selfhosting, new assumptions, weakened CI or altered performance baselines. PR109 remains draft/open/unmerged on original base.
