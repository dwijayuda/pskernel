# M3+B — nested recursive parameter validation (accepted)

**Selected v7.2 M3+B compiler slice accepted; full M3+B remains OPEN.** 17 October 2026 (Jakarta-local reporting). The implementation/test commit is `e3c3f8b6b9b2231b4bf69f4ae37bd2aa234b1cf9`; acceptance documentation was committed separately and does not replace exact compiler CI.

## Required five-gate same-commit evidence

| Gate | GitHub run | Result |
| --- | --- | --- |
| Native portable Lean compiler + selected source, checked environment, IR, JS/TS/Rust, GC, component, native Wasmtime and performance | [38941232123](https://github.com/dwijayuda/pskernel/actions/runs/38941232123) | **SUCCESS**, 33/33 reported steps including setup/cleanup |
| F1 canonical model | [38941232184](https://github.com/dwijayuda/pskernel/actions/runs/38941232184) | **SUCCESS** |
| F2 logical operations | [38941232130](https://github.com/dwijayuda/pskernel/actions/runs/38941232130) | **SUCCESS** |
| F3/F4/platform | [38941232155](https://github.com/dwijayuda/pskernel/actions/runs/38941232155) | **SUCCESS** |
| Focused recursive deriving and source/target regression | [38941232165](https://github.com/dwijayuda/pskernel/actions/runs/38941232165) | **SUCCESS** |

Native artifact `12064315678`, digest `sha256:02e6a3f0c9d29857c090f1d3dd0626721af58bfb65589da71988d2ebf3266ed7`; focused artifact `12063602260`, digest `sha256:25ada00006cad08ffed182d2d9790eead839a863833c3e7f9e2a017657587857`. No acceptance was inferred from parent CI.

## Actually implemented

In `Ps.Elab.Data`, the previously permissive nested-recursion shape predicate is replaced by a bounded validation that reuses `psElabDataIndices` for each recursive family occurrence **under List/Option/Array/Prod**, with the same checked levels, arity and uniform parameter test as a direct occurrence. For a polymorphic `BadNested(A)` containing `List(BadNested(Nat))`, the focused test now refuses at the actual source-elaboration rule: `constructor parameters must remain uniform`. Existing positive data source and nested deriving refusals retain their exact owner and phase. Unsupported contravariant/indexed nested occurrences still refuse, and no checked nested induction hypothesis is manufactured.

Pinned Lean source: `Lean/Elab/MutualInductive.lean` stages constructor/elimination validation, and `Init/Prelude.lean` supplies the selected List/Option/Array/Prod definitions. The official kernel remains the final logical authority. This selected validation is **not** a general positivity theorem or a kernel replacement.

## Separate following evidence (not all-five at those SHAs)

- Test-only `bde3dccdb8d0eff88c344737c0cb9a4e15ff071f`: focused [38941701921](https://github.com/dwijayuda/pskernel/actions/runs/38941701921) SUCCESS for a zero-parameter nested `List Rose` with shallow match, using check-only kernel admission. No executable artifact for this separate request.
- Test-only `eb227eb6b8de70a49eaa7fdbb385d36e59e036a8`: focused [38942183166](https://github.com/dwijayuda/pskernel/actions/runs/38942183166) SUCCESS for the same nested family with a scalar `m3nestedoutput` oracle across JS, strict compiled TS, pinned Rust, V8 GC and Wasmtime. Artifact `12063597824`, `sha256:65755faed31bf22f4449446467fc7b4ef17dc85ab5dfdd93538c82103d796903`. This is *shallow runtime elimination*, not nested recursive traversal/deriving.

## Next bounded implementation and remaining architecture

The source frontend permits Array nested families but the canonical nested admission adapter previously handled List, Option and Prod only. A new **candidate** adds the pinned Array structure's `toList : List α` constructor shape, with a separate zero-parameter Array Rose check-only oracle; **no Array acceptance is claimed until the new candidate's own five same-commit gates**.

Still OPEN: parametric/polymorphic nested execution, nested recursive IH generation/traversal, indexed/mutual inductive groups, general elimination/deriving, well-founded recursion, full recursion-strategy grammar, partial P0 ordinary runtime, checked P1 fixedpoint and the complete selected M3+B six-criterion exit. Preserve original M2+A/Hashable/Repr/BEq/DecidableEq/structural-source receipts, no new speed claims, only `propext`/`Quot.sound`, no pskernel-core or self-hosting. PR #109 stays draft/open/unmerged on its original base.
