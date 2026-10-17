# M3 well-founded foundation audit and activation candidate

## Observed evidence

The independently audited compiler/test SHA is
`078fb1e2c22f79e7f4eae2f21863e2cad4fa1434`.
[Native Linux run 38998692067](https://github.com/dwijayuda/pskernel/actions/runs/38998692067),
job `117296813544`, completed successfully on 2026-10-17 at 03:38:34 UTC.
All 34 reported steps succeeded. This includes exact foundation regeneration and
the initialized metadata audit, followed by every original source/Standard,
three-module application, GC/component, TypeScript, Rust, repeated Wasmtime and
measurement workload.

The following object was printed by the independent audit at
03:27:35.1112375 UTC, after all of its checks passed:

```json
{
  "activeFoundationDeclarations": 0,
  "candidateAxioms": [],
  "candidateDeclarations": 34,
  "kernelChecked": true,
  "leanCommit": "eb6cafb7290e8bd5f2937522d8d804f58f02bafc",
  "proposedClasses": 41,
  "proposedDeclarations": 3633,
  "proposedInstances": 359,
  "proposedStandardFNV": "fnv1a64:4990397000639020696",
  "proposedStandardSHA256": "sha256:5e96678b7ca94ac8dcb63d36cee81c5997287f507ce8c0c26d28321b37ce97d7",
  "proposedSurfaceSHA256": "sha256:7a996cfc6253693799d43fdcf78dd7f30eb0713a3eb31831daa9d804faf818c6",
  "recursorRulesCompared": 3,
  "runtimeQualified": false,
  "schema": "pscv0-well-founded-foundation-audit/1"
}
```

The audit's `runtimeQualified: false` is deliberate. At this audited SHA, the
active Standard contained zero foundation additions; the audit constructed and
checked a proposed extension. Successful audit and native execution of the old
active Standard do not qualify the newly selected foundation or generic recursion.

## Reproducible asset and selected identities

The frozen input is
`psSelfHostProdPreWellFoundedPreludeEnvironment`. The authoring command regenerated
`StandardWellFoundedData.lean` and compared it byte-for-byte with the committed
asset. The export reports 34 declarations, 2,329 shared source nodes, 466,947 bytes,
three recursor rules and only the approved imported assumptions `propext` and
`Quot.sound`. The candidate adds no axiom.

Asset SHA-256:
`b6bd56c4ab6378905d1d3ac2f0155eb5bc4742be3e19e684d64ac1a3007716f3`.

| Property | Active at audited SHA | Independently observed proposed selection |
| --- | --- | --- |
| Declarations | 3,599 | 3,633 |
| Classes | 39 | 41 |
| Ordinary instances | 355 | 359 |
| Standard FNV | `fnv1a64:10704736494700616048` | `fnv1a64:4990397000639020696` |
| Standard SHA-256 | `sha256:a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f` | `sha256:5e96678b7ca94ac8dcb63d36cee81c5997287f507ce8c0c26d28321b37ce97d7` |
| Source-surface SHA-256 | `sha256:117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8` | `sha256:7a996cfc6253693799d43fdcf78dd7f30eb0713a3eb31831daa9d804faf818c6` |

The audit compares all native Core declarations and reducibility entries, exact
class/out-parameter/output-level metadata, ordinary instance priorities and class
keys, named non-instance definitions, aliases, selected proof closure, instance
indexing and actual dictionary synthesis. It independently kernel-checks the
proposed extension and compares three native recursor rules. Native import uses
the pinned initializer lifecycle with `loadExts := true`; the native executable
exports interpreter support so imported persistent extensions can initialize.
Missing metadata is an error.

The twelve newly selected roots are `WellFounded.fix_eq`, `invImage`, `SizeOf`,
`SizeOf.sizeOf`, `instSizeOfNat`, `instSizeOfDefault`, `sizeOfWFRel`,
`Prod.instWellFoundedRelation`, `Prod.Lex.left`, `Prod.Lex.right`, `emptyWf`
and `Nat.succ_lt_succ`. Already selected roots remain in the frozen input.
The wrapper registers the two classes, four ordinary instances at their pinned
priorities and the `sizeOf` alias. `Nat.lt_wfRel` and `emptyWf` remain named
definitions, not newly registered ordinary instances.

Native artifact `12088616845`:
`pscv0-v7-native-078fb1e2c22f79e7f4eae2f21863e2cad4fa1434`,
6,796,418 bytes, SHA-256
`148cf6839a45bd7474ddf9ef1a3a0f1004616f90e28d513ecdbc336a6006ce7a`.
It includes the regenerated candidate, export report and audit JSON.

## Activation and same-SHA qualification

This activation imports `Ps.Environment.StandardWellFounded`, selects
`psStandardWellFoundedExtend psSelfHostProdPreWellFoundedPreludeEnvironment`,
and replaces the three exact pins above with the observed proposed values.
The frozen authoring input is unchanged; no asset regenerates from its own output.

The candidate follows two linear commits:

1. [75be0cab](https://github.com/dwijayuda/pskernel/commit/75be0cabaa4885e98362712b61b88be5fd0cd5d5)
   repairs the sole remaining native indexed fixture pattern with a generalized
   parent observer. Its complete portable fixture is unchanged.
2. [490a4dfc](https://github.com/dwijayuda/pskernel/commit/490a4dfcac81e42a56eeb6121112c3e20e2731e2)
   adds reviewed fixed-codomain relation selection and shared typed fix
   construction/erasure at the existing unary changing-argument boundary.
   It retains the precise Nat optimization rule and checks the actual generic
   relation, well-founded proof and public equation.

All five gates must complete successfully at the final activated compiler/test
SHA. At the audited SHA, F1
[38998692100](https://github.com/dwijayuda/pskernel/actions/runs/38998692100), F2
[38998692059](https://github.com/dwijayuda/pskernel/actions/runs/38998692059) and F3/F4
[38998692085](https://github.com/dwijayuda/pskernel/actions/runs/38998692085) passed,
but focused
[38998692088](https://github.com/dwijayuda/pskernel/actions/runs/38998692088) failed
at the native indexed parent pattern repaired above. Therefore this receipt is
audit evidence, not a new five-gate acceptance.

Accepted compiler/test SHA remains
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`; weighted engineering estimate remains
**74/100**, M3+B open. Dependent argument packing is separately reviewed and
unqualified. P1 remains blocked by `Classical.choice`; only `propext` and
`Quot.sound` are approved. Lean stays at 4.35.0,
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. PR 109 stays draft/open/unmerged.

## Activated native replay completed — 2026-10-17

The later compiler/test SHA
`3c5f51a2ffdc9cabfe386ab6fd1c7a1bb82e6ff5` selects the audited extension.
[Native run 39000431708](https://github.com/dwijayuda/pskernel/actions/runs/39000431708),
job `117302002147`, completed successfully: all 34 reported steps passed,
including every original source/Standard, module, GC/component, TypeScript, Rust,
repeated Wasmtime and measurement workload. The independent audit now reports
`activeFoundationDeclarations: 34`; its other inventory and pin values agree
exactly with the earlier proposed audit.

```json
{
  "activeFoundationDeclarations": 34,
  "candidateAxioms": [],
  "candidateDeclarations": 34,
  "kernelChecked": true,
  "leanCommit": "eb6cafb7290e8bd5f2937522d8d804f58f02bafc",
  "proposedClasses": 41,
  "proposedDeclarations": 3633,
  "proposedInstances": 359,
  "proposedStandardFNV": "fnv1a64:4990397000639020696",
  "proposedStandardSHA256": "sha256:5e96678b7ca94ac8dcb63d36cee81c5997287f507ce8c0c26d28321b37ce97d7",
  "proposedSurfaceSHA256": "sha256:7a996cfc6253693799d43fdcf78dd7f30eb0713a3eb31831daa9d804faf818c6",
  "recursorRulesCompared": 3,
  "runtimeQualified": false,
  "schema": "pscv0-well-founded-foundation-audit/1"
}
```

Native artifact `12088873997`, `pscv0-v7-native-3c5f51a2ffdc9cabfe386ab6fd1c7a1bb82e6ff5`,
6,797,540 bytes, digest `sha256:ea7b06cce1a363b24de67f9a9441531ab93121e1b69cbaddc2adfa32085af7f4`.
The artifact was created on 2026-10-17 at 04:06:40 UTC.
The helper retains `runtimeQualified: false` because it certifies its own
foundation audit only; successful runtime workloads are separate evidence.

F1 [39000431683](https://github.com/dwijayuda/pskernel/actions/runs/39000431683),
F2 [39000431695](https://github.com/dwijayuda/pskernel/actions/runs/39000431695)
and F3/F4 [39000431730](https://github.com/dwijayuda/pskernel/actions/runs/39000431730)
also passed. Focused
[39000431684](https://github.com/dwijayuda/pskernel/actions/runs/39000431684)
compiled all 668 jobs and passed all prior source-construction checks, including
generic lexicographic fix/equations and indexed Inhabited. It failed the new
empty-dictionary fixture's expected raw guard shape before target comparisons.
That fixture-only error is repaired by requiring the actual checked Bool equality
guard. The combined next candidate includes separately reviewed dependent packing
and inherited-partial hint scoping, with all five gates still required together.

This activated native replay is preserved evidence, not a five-gate acceptance.
Accepted compiler/test SHA remains
`03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`, **74/100**, M3+B open.

