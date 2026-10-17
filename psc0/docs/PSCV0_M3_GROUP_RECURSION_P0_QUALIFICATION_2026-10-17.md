# Selected group elimination, measured recursion and P0 execution — qualified

**Compiler/test:** `e03a99d1f45f2127372ee556ffe866d304d103e3`. **Selected slices ACCEPTED; full M3+B OPEN.** 17 October 2026 (Jakarta reporting).

This exact compiler/test commit replaces `a7c6dade87a9d8df74d5248e8276623e7870078c` as the latest five-gate accepted compiler baseline. Earlier production/fixture passes on different SHAs did not establish that acceptance.

## Five qualifications on the same commit

| Gate | Workflow | Exact result |
| --- | --- | --- |
| Full native Linux | [38964433671](https://github.com/dwijayuda/pskernel/actions/runs/38964433671) | SUCCESS; job `117187265460`, all 33 reported steps successful, none skipped |
| F1 canonical model | [38964433756](https://github.com/dwijayuda/pskernel/actions/runs/38964433756) | SUCCESS |
| F2 logical operations | [38964433572](https://github.com/dwijayuda/pskernel/actions/runs/38964433572) | SUCCESS |
| F3/F4/platform | [38964433857](https://github.com/dwijayuda/pskernel/actions/runs/38964433857) | SUCCESS |
| Focused source/kernel/native oracle and five target lanes | [38964433806](https://github.com/dwijayuda/pskernel/actions/runs/38964433806) | SUCCESS; job `117187265950`, all 15 reported steps successful, none skipped |

| Retained artifact | ID | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Native | [12074054451](https://github.com/dwijayuda/pskernel/actions/runs/38964433671/artifacts/12074054451) | 6,705,923 | `efdd6c94ad60a6af715695ca099fc03acd280d838583cfa5ffc0a613d2c1d386` |
| Focused | [12073888075](https://github.com/dwijayuda/pskernel/actions/runs/38964433806/artifacts/12073888075) | 1,017,685 | `fa8a33735a7a94200c7955332feaf5314521b96d84c24b2df9634ba644610aae` |

The run metadata, completed job steps, full native/focused logs and artifact metadata were inspected. All five workflow records name the exact compiler/test SHA above.

## Accepted construction and execution

### Complete direct inductive groups and source cases

`Ps.Core.InductiveGroup` retains ordered visible family identity, common parameters/universe layout, per-family indices and constructor/minor offsets. Native group formation stages every header before constructor elaboration; canonical admission carries one atomic group to the official kernel. Portable iota reduction uses the actual child family and its indices.

`Ps.Compiler.RecursorLift` creates ordinary checked companion definitions for the complete group. Before erasure, the retained equations, shared captures, member order, levels and actual runtime declaration identities are reconstructed and checked. Worker descriptors locate definitions; they do not grant admission. The focused oracle covers dependent common A/a parameters, alpha-renaming, unequal family index counts, distinct Nat/Bool motives and a kernel-accepted stale equation that runtime identity validation must refuse.

Source `match`, pattern matrices and `cases` use the actual recursor argument telescope through `Ps.Elab.GroupElimination`. The selected family retains its dependent motive and reverted context; companion families use checked PUnit at the actual result universe. Case branches expose no fabricated recursive hypotheses. Fresh official-kernel equations, portable reduction, Prop/universe restrictions and scalar behavior pass all five runtime lanes.

The selected .ps mutual grammar remains def/function-only. No mutual-inductive source syntax was introduced. The native group API and checked imported declarations supply group data. Default source `induction` on mutual/nested types remains refused; pinned Lean's default tactic also refuses these without a selected explicit eliminator.

### Total measured-state recursion

`termination_by` and optional `decreasing_by by { ... }` retain measure/proof ownership and source spans. `Ps.Elab.RecursionParameters` observes typed calls, closes dependencies and separates fixed arguments from one changing measured Nat and independent evolving Nat state. At this accepted SHA, all explicit header parameters and the result are Nat.

The definition is an actual `WellFounded.Nat.fix` whose motive returns the state function. Checked Core lets evaluate recursive source arguments in their original order; fixed arguments are revalidated at each call. Body lambda parameters never become termination-header parameters. Every recursive call has a scoped checked decrease proof, and one proof sequence runs over the creation-ordered goals.

The public `f.eq_def` follows from actual `Nat.fix_eq`. Checked `funext`, `congrArg` and `Eq.trans` identify the callback with calls to the real public definition; no conversion rule or recursive proof axiom was added. Runtime lowering revalidates the actual definition and complete entry telescope, constructs the typed proof-restricted public callback in original argument order and uses ordinary erasure.

The eight well-founded outputs cover predecessor/branch behavior, shifted/default measures, nonprefix fixed and evolving arguments, beta-equivalent fixed measure dependencies, two evolving states using the original values, and a no-state case. Source ownership, proof ordering, public successor equations and exact semantic refusals also pass.

### Ordinary P0 partial functions and mutual groups

The public logical declaration is opaque and independently inhabited. Its separately checked private numeric body identity retains the actual recursive implementation. The ordinary native host checks the original logical/body graph before selecting actual bodies for execution. Logical opacity, the absence of invented defining equations and explicit refusal of unimplemented verified grades remain intact.

The selected source `mutual ... end` owner retains ordered members, each member's modifiers/span and the whole group span. Compatible P0 blocks close their section telescope and universe union over the complete block, including disconnected members. All independent real opaque headers are staged before bodies. Typed local peer aliases apply the exact captured telescope, including implicit, instance and proof slots, and are removed before final body checking.

The focused batch passes sixteen request outcomes and separate construction/provenance checks. It exercises imported ordinary execution, privacy, all-kind captures, disconnected members, nullary functions, higher-order bare peers, shadowing, delayed proof scopes and body-only universe closure. Potentially divergent pairs are checked without invoking them. All five emitted targets use independent native scalar observations. Per-member and complete mutual-group provenance survive target artifacts and CLI origin JSON.

## Integration and repair evidence

Native source/Standard qualification, modules, GC core/components, direct JS, compiled TS, Rust and repeated Wasmtime calls all pass. Existing native runtime checks record 1,069 shared observations, platform checks remain intact, and the existing M1 measurement step succeeds with its original workload/sample counts and budgets. This is execution and qualification evidence for the selected matrix, not a proof of general target preservation or a new performance-parity claim.

The earlier `34f43e6b` source-case candidate failed native case 64 because earlier motive checking changed the category of the existing forbidden Or-to-Nat elimination diagnostic. The shared argument cursor now reports the same Core application-type error, without changing native expected results. The focused fixture also checks that category for singleton and group Prop elimination.

The joint `d0c6ee3d` candidate then failed compilation at a new local named with the reserved keyword `scoped`. Exact accepted `e03a99d1` renames it to `scopedMembers` and the analogous new fixture local to `universeBatch`. No semantic assertion or expected diagnostic was weakened.

## Remaining exits and engineering estimate

All six M3+B exit areas remain in the estimate. The weighted engineering assessment is approximately **55% complete, with a broad 45–65% uncertainty interval**. This is planning judgment about remaining implementation and qualification effort, not a measured conformance percentage.

| Exit area | Weight | Approximate contribution | Material remaining work |
| --- | ---: | ---: | --- |
| General data/elimination/deriving | 30% | 14 points | Nested specialized motives/traversal, broader dependent consumers, expanded deriving |
| v7.2 source strategies | 15% | 10 points | Total compatible mutual and local where construction; complete selected strategy interactions |
| Total structural/WF recursion | 20% | 10 points | Broader typed domains/state/results, compatible mutual termination and selected relation coverage |
| P0 ordinary execution | 15% | 13 points | Remaining local/source interactions and full selected closure matrix |
| P1 fixedpoint | 10% | 1 point | Construction unavailable under the current assumption policy; exact dependency audit completed |
| Cross-stage acceptance | 10% | 6 points | Remaining selected positive/negative matrix and one final integrated compiler SHA |

The next reviewed group Hashable/Repr/BEq implementation is **not part of this acceptance**. It needs its own five-gate compiler/test qualification. General typed measured recursion, total mutual structural recursion and the shared nested auxiliary plan are also separate work.

Pinned `Lean.Order.fix`/`CCPO.csup` and their equations require `Classical.choice`. The approved assumptions remain only `propext` and `Quot.sound`; P1 source requests fail closed at that exact boundary. No P1 executable or theorem construction is claimed.

## Fixed authority

Native portable .lean; official Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The sole forward source specification is `psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md`, blob `694115223777599ba28ee175e14bb642b7b6aa4b`.

The matching primary implementations are pinned `src/kernel/inductive.cpp`, `Lean/Elab/MutualInductive.lean`, `Lean/Elab/MutualDef.lean`, `Lean/Elab/PreDefinition/Structural`, `Lean/Elab/PreDefinition/WF/Fix.lean` and `Init/WF.lean`. The P1 dependency oracle remains outside admitted Standard.

Historical receipts, original benchmarks/checksums, toolchain/dependency pins and approved assumptions remain intact. No pskernel-core, independent kernel, self-hosting, compiler-source migration, LLVM integration or milestone promotion is included. PR #109 remains draft/open/unmerged on its original base.
