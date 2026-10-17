# Unused termination-hint qualification — 17 October 2026 (UTC)

Accepted compiler/test SHA:
[`e6b7f11750fdde6e1feacab86cfb32f2a82be8a5`](https://github.com/dwijayuda/pskernel/commit/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5).

**All five gates passed at this exact compiler/test SHA.** This qualifies the bounded typed nonrecursive Where unused-hint correction, successful-result diagnostics, and section-context/capture regressions. It retains **960 actual runtime comparisons** and the **78/100** engineering estimate. M3+B, M4 and M5 remain open.

Qualification and receipt preparation completed on 17 October 2026 UTC, corresponding to 18 October in Asia/Jakarta. The preceding qualified compiler/test was `0e2f5c461d30457caee322b8135293597f55ac4b`, recorded by documentation checkpoint `e00f189cd4ce13da8cf37bf503884b339b553ec5`. Historical gates are not mixed into this acceptance.

## Complete same-SHA gate and artifact receipts

| Gate | Run | Job | Result |
| --- | --- | --- | --- |
| Native Linux | [39051402014](https://github.com/dwijayuda/pskernel/actions/runs/39051402014) | [117450565117](https://github.com/dwijayuda/pskernel/actions/runs/39051402014/job/117450565117) | SUCCESS; 34/34 reported steps |
| Focused M3 | [39051402005](https://github.com/dwijayuda/pskernel/actions/runs/39051402005) | [117450565084](https://github.com/dwijayuda/pskernel/actions/runs/39051402005/job/117450565084) | SUCCESS; 15/15 reported steps |
| F1 | [39051401994](https://github.com/dwijayuda/pskernel/actions/runs/39051401994) | [117450565166](https://github.com/dwijayuda/pskernel/actions/runs/39051401994/job/117450565166) | SUCCESS; 10/10 reported steps |
| F2 | [39051401917](https://github.com/dwijayuda/pskernel/actions/runs/39051401917) | [117450564916](https://github.com/dwijayuda/pskernel/actions/runs/39051401917/job/117450564916) | SUCCESS; 9/9 reported steps |
| F3 | [39051402080](https://github.com/dwijayuda/pskernel/actions/runs/39051402080) | [117450565404](https://github.com/dwijayuda/pskernel/actions/runs/39051402080/job/117450565404) | SUCCESS; 11/11 reported steps |

All completed run metadata, checkout logs and artifact metadata identify the accepted SHA. The final documentation checkpoint records this identity without modifying compiler/test files.

Each exact artifact name is the prefix below, followed by a hyphen and the complete accepted SHA `e6b7f11750fdde6e1feacab86cfb32f2a82be8a5`. File counts are from the completed upload step; IDs, sizes, digests, run IDs, branch and head SHA were independently matched against artifact API metadata.

| Gate / artifact-name prefix | Artifact ID | Files | Bytes | ZIP SHA-256 |
| --- | --- | ---: | ---: | --- |
| Native Linux: `pscv0-v7-native` | [12108620469](https://github.com/dwijayuda/pskernel/actions/runs/39051402014/artifacts/12108620469) | 236 | 6,797,200 | `4ea2ae002fd68890264ef1fd4211b10ee2895084cea9e000c456e340cc31297d` |
| Focused M3: `pscv0-m3-recursive-hash` | [12107707424](https://github.com/dwijayuda/pskernel/actions/runs/39051402005/artifacts/12107707424) | 286 | 3,038,633 | `59cab631d76df888bc8169ca597462ea11318a05da32f854fe7771e13ff23a83` |
| F1: `pscv0-f1-canonical-model` | [12107647180](https://github.com/dwijayuda/pskernel/actions/runs/39051401994/artifacts/12107647180) | 6 | 1,674,681 | `bf8c94a52cfd538b084c760564097be961294288fa5f4b7cd896006f7af11c77` |
| F2: `pscv0-f2-operations` | [12107716900](https://github.com/dwijayuda/pskernel/actions/runs/39051401917/artifacts/12107716900) | 3 | 1,798,323 | `7f9f8d228cbc171a9a65aa6bed18fa4357477e190fbd0c80d58950d9487b5b37` |
| F3: `pscv0-f3-conversions` | [12107284712](https://github.com/dwijayuda/pskernel/actions/runs/39051402080/artifacts/12107284712) | 7 | 295,038 | `3f0511060e7f8399f9ddfb47b8b444790c809b4c263b167e213ea8b9967c40e9` |

All five artifacts were unexpired at inspection. Their upload receipts completed successfully. The ZIP bytes were not independently downloaded, reopened or rehashed. All 79 reported gate steps succeeded (34 + 15 + 10 + 9 + 11). Full decoded logs inspected: Native 4,475,706 characters; Focused M3 8,261,669; F1 414,714; F2 84,990; F3 91,965.

## Concrete problem and checked owner

An ordinary nonrecursive Where helper could be rejected while resolving an unused measure, before typed dependency analysis determined its recursion strategy:

```text
function ordinary(n: Nat): Nat := loop(n)
where {
  def loop(k: Nat): Nat := k
  termination_by missingMeasure
}
```

The accepted behavior is an ordinary checked definition and exact `eq_def`, followed by ``unused `termination_by`, function is not recursive``. The missing name is inside unused hint syntax; invalid declaration headers and bodies still fail. This decision follows the actual checked body graph. The separate `uhShadow.shadow(shadow: Nat)` case deliberately shadows the helper name with its own argument, so source-name resemblance cannot supply the recursion decision. See the [native controls and portable source](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/test/Pscv0M3Where.lean#L264).

Pinned Lean's [PreDefinition.Main](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/Main.lean#L288) instantiates checked predefinitions, partitions their dependency graph, completes a nonrecursive member, and then diagnoses redundant hints. Its partial branch also constructs the members before the corresponding warnings. Active recursive strategies elaborate their hints. [TerminationHint.ensureNone](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/TerminationHint.lean#L101) supplies the single-clause, combined-clause and represented fixedpoint message choices. Parsing and validation of the suffix syntax remain earlier obligations; ignoring an unused payload does not create new grammar.

### Scope, captures and active recursion

[WhereScope](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/WhereScope.lean#L5) adds a small `PsWhereTerminationScope` sidecar containing the original resolver and the actual header-bound names. Main/local total suffixes keep their raw syntax and source spans. Hints contribute no `.used` keys. The saved local scope is the original resolver with local header bounds, rather than the body resolver that adds the helper frame. Inherited-partial helpers retain raw suffixes without an active total-hint sidecar.

[Where](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/Where.lean#L30) carries the sidecar through the existing headers. Actual typed SCC analysis and the checked type/body capture closure remain the construction authority. The selected [well-founded consumer](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/WhereWellFounded.lean#L108) resolves its saved raw suffix before the existing proof-alias rewrite; it discards hint-derived source-use metadata. Active measures/proofs are still checked against actual captures and the member's own telescope. Existing hint-only section-name scope refusals, active unknown-name refusals and original-main compatibility refusals remain.

Ordinary value predefinitions now receive the full already checked section telescope at [Command](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/Command.lean#L191), including local instances, before actual typed capture pruning. This corresponds to pinned [MutualDef.elabFunValues](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/MutualDef.lean#L515) and its later instantiated-body capture closure. The theorem-specific header section-variable restriction remains separate.

This context change matters for `d : UhHintDictionary tag`, where the retained reducible alias is `Inhabited Nat`. The body selects the real local dictionary. Its stored type legitimately retains `tag`, so both plain and hinted Where functions close over `tag, d`. A separate `{A : Type u} [Inhabited A]` fixture proves that a hint alone does not add a type, instance or universe to an explicit `Nat → Nat` helper. The change is bounded to typed predefinitions; the remaining legacy ordinary-definition route is recorded below.

### Diagnostic construction and transport

[PreDefinition](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/PreDefinition.lean#L291) constructs ordinary nonrecursive definitions and their exact equations before attaching warnings. Partial construction must succeed before its member warnings are attached, and a member-count guard precedes the zip. The final batch collects diagnostics in original member order. The existing checked construction is not replaced by a warning or by termination evidence from an ignored hint.

Default diagnostic fields in declaration batches and origins preserve source ownership. [Command](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/Command.lean#L202) transfers each owned member's diagnostics to its origin. [NativeV7](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/host/src/Ps/Host/NativeV7.lean#L270) obtains those source-origin batches for both source-only and emitted successes. Each `SourceDiagnostic` retains its own source filename; an imported provider is not relabeled as the entry file.

Successful result JSON now includes a `diagnostics` array. Every item retains `source`, `phase = "elaborate"`, `severity`, `message`, and these six coordinates:

| Start fields | End fields |
| --- | --- |
| `sourceStartByte` | `sourceEndByte` |
| `sourceStartLine` | `sourceEndLine` |
| `sourceStartColumn` | `sourceEndColumn` |

The existing error result is unchanged. Diagnostics are transactional with an overall successful result. This qualifies successful-result warning transport, without claiming parity with Lean's cumulative message log before a later component fails.

## New and retained source assertions

The [Where fixture](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/test/Pscv0M3Where.lean) adds **five exact native warning guards**, **eleven independent native/source `rfl` pairs**, **four complete native `@` helper type controls**, and checks **thirteen portable parent/helper definition-and-`eq_def` pairs**. These counts describe different obligations; thirteen headers are not thirteen native warning guards.

The portable header checks require the expected complete binder names, empty unused universe lists, closed types/bodies/equations/proofs, no unresolved metavariables, no unintended `WellFounded.fix`, and no private numeric partial-body identity. The ordinary parent/helper cases retain `Nat → Nat` where no real capture is needed. The matched dictionary functions and helpers must have alpha-equivalent types.

| New source family | Independent observations | Capture or ownership obligation |
| --- | --- | --- |
| `ordinary` and `ordinary.loop` | Both return 7 on 7 | Unknown unused measure is ignored; ordinary exact equations remain |
| `uhShadow` and `uhShadow.shadow` | Both return 8 on 8 | Own argument shadows helper name; ignored measure/proof supply no captures |
| `uhMain` | Returns 9 on 9 | Main nonrecursive unknown measure is ignored |
| `hintDictPlain` / `hintDictIgnored` | Dictionary 41 with n = 3 gives 44; dictionary 7 gives 10, with and without the hint | Both select the actual local dictionary and retain the genuine tag/d type dependency |
| `uhTypePlain` / `uhTypeHinted` | Both return 0 on 3 | Complete Nat-to-Nat headers exclude hint-only A, its instance and universe |

The four dictionary source calls explicitly name `tag`, `d` and `n`. Captured `tag` remains explicit, so mixed positional/named calls would invoke the existing duplicate-argument refusal. The native `@` controls and the portable complete headers prevent accidental success through an extra hidden implicit parameter.

### Warning sites, exact messages and provenance

Expected messages are explicit static fixture observations. Expected source spans are selected independently from retained parser nodes by main/helper ownership; the checker does not reuse the warning producer. It verifies exact list length, a unique source/message/span match for each expected site, warning severity, and every JSON field above.

| Fixture / owner | Exact warning message |
| --- | --- |
| New: `ordinary.loop`, `uhMain`, `hintDictIgnored.helper`, `uhTypeHinted.helper` | ``unused `termination_by`, function is not recursive`` |
| New: `uhShadow.shadow` | `unused termination hints, function is not recursive` |
| Retained partial: `phMain.loop`, `phMain.proofLoop` | `unused termination hints, function is partial` |
| Retained emitted: `wdisconnected.loop` | `unused termination hints, function is partial` |
| Retained emitted: `wdisconnected.bump`, `wredundantP1` | ``unused `partial_fixpoint`, function is not recursive`` |
| Retained emitted: `wdisconnected.measured` | `unused termination hints, function is not recursive` |
| Retained emitted: `wdisconnected.fixedLoop` | ``unused `partial_fixpoint`, function is partial`` |
| Retained emitted: `wredundantWF` | ``unused `termination_by`, function is not recursive`` |

There are **thirteen unique source warning sites across the three fixtures**: five new ordinary, two retained partial and six retained emitted sites. Only the five new native guards directly compare exact warning messages with pinned Lean. The new five sites are checked on direct compiled origins, on a standalone source-only result named `m3-unused-hints.ps`, and again on a project result. The project entry is `hint-entry.ps`; all five warnings must identify the actual provider `hint-provider.ps`.

Raw total suffix text, local/main ownership, measure span, optional decreasing-proof span and enclosing helper span are preserved. A scope-only assertion confirms no `hintOnly`, `missingMeasure` or `missingProof` use key is introduced by those unused suffixes.

### Positive and refusal batches

| Batch | Positive requests | Required refusals | Additional diagnostic checks |
| --- | ---: | ---: | --- |
| New unused hints | 2 source-only | 4 | Five warnings in each successful standalone/provider result, plus direct-origin checks |
| Retained inherited-partial hints | 1 source-only | 6 | Two warnings, opaque/private-body ownership, no partial defining equation |
| Original Where main | 1 five-target | 6 | Six warnings through emission and JSON; original exports retained |

The four new refusal controls require `phase = "elaborate"` and the designated rule text: unknown `missingHeader`, unknown `missingBody`, `PSCV0-TYPE-MISMATCH`, and unknown `missingMain` for an actively recursive main. Rule text is checked as a substring of the full diagnostic; these are not assertions that every surrounding error character equals a fixed string. The obsolete nonrecursive unknown-measure refusal becomes a positive. The other six inherited-partial refusals remain, including active measures/proofs, checked headers/bodies and incompatible original mains.

The existing main fixture retains its five source equations, sixteen local-origin membership checks, active hint-only measure/proof scope refusals, parser refusals, original-main compatibility checks and ten native assumption closures. `M3ResultInference.check` still runs inside the Where executable. Its retained nineteen native equations, nineteen source theorems, eighteen closed total definitions, three opaque/private partial pairs and six refusals remain covered by this same completed focused gate.

## Completed focused source, trust and runtime evidence

Focused [run 39051402005](https://github.com/dwijayuda/pskernel/actions/runs/39051402005), job [117450565084](https://github.com/dwijayuda/pskernel/actions/runs/39051402005/job/117450565084), passed **all fifteen reported steps** and a successful **670-job build**. Its decoded completed log has **8,261,669 characters**. The same **fourteen outer fixture commands** are present in the existing workflow; no new standalone workflow was substituted.

The actual completed output contains both new markers:

```text
PSCV0_M3_UNUSED_HINTS: PASS five exact pinned native warnings, eleven matched rfl equations, thirteen closed ordinary definition/equation headers, ignored measure/proof capture exclusion, body-selected dictionary parity, retained raw spans, source-only/project diagnostic JSON and four exact refusals
PSCV0_M3_HINT_DIAGNOSTICS: PASS two inherited-partial warnings and six emitted warnings with exact source-owned text, severity and coordinates
```

Retained result-family inference, Where parsing/construction, inherited-partial scope, well-founded construction and emission markers also pass. The WF source fixture still has **twenty-one requests: two positives and nineteen required refusals**. All **thirty-eight WF** and **ten Where** printed assumption closures remain within propext/Quot.sound. The generic P0 native closure and two ordinary five-target generic exports remain checked; the audited P1 marker still refuses Classical.choice.

After stripping only timestamps/ANSI presentation, an anchored scan finds exactly **56 actual runtime PASS lines**, byte-for-byte and order-identical to the accepted preceding baseline: **26 scalar ECMA, 13 scalar Rust, 13 scalar Wasm, and 2/1/1 original deriving**. Each Wasm marker represents both V8 GC core and Wasmtime component execution.

The two existing runners compare both Boolean flags against the corresponding native oracle in **direct JavaScript, strict compiled TypeScript, locked Rust, V8 GC core and Wasmtime components**. The actual total remains **960 comparisons**: 72 scalar exports × 2 flags × 5 lanes = 720, plus 24 original deriving exports × 2 × 5 = 240.

| Runtime suite | Exports | Flags | Lanes | Actual comparisons |
| --- | ---: | ---: | ---: | ---: |
| groupfold | 2 | 2 | 5 | 20 |
| wellfounded | 16 | 2 | 5 | 160 |
| groupmatch | 4 | 2 | 5 | 40 |
| mutual | 5 | 2 | 5 | 50 |
| groupderive | 6 | 2 | 5 | 60 |
| mutualstructural | 6 | 2 | 5 | 60 |
| nestedfold | 7 | 2 | 5 | 70 |
| wherefixture | 6 | 2 | 5 | 60 |
| nestedderive | 6 | 2 | 5 | 60 |
| groupproof | 4 | 2 | 5 | 40 |
| emptydict | 4 | 2 | 5 | 40 |
| indexedinhabited | 4 | 2 | 5 | 40 |
| p0generic | 2 | 2 | 5 | 20 |
| Original recursive deriving | 24 | 2 | 5 | 240 |
| **Total** | **96** | **2** | **5** | **960** |

The new warning and source-only equations add **zero runtime exports or comparisons**. The retained Where executable contributes its existing sixty comparisons. Generic P0 still observes Nat false/true **2947/4123** and Bool false/true **12/21**, with actual dictionaries/seeds and both entry directions. Its opaque/private implementation bodies, complete type/universe telescopes and both verified-assurance refusals remain. Ordinary runtime agreement supplies neither a logical partial-body equation nor a verified backend correspondence claim; the historical Wasm marker's phrase about checked equations does not extend that assurance.

## Completed F1/F2/F3 proof and retained-asset evidence

Each of F1/F2/F3 passed a **625-job build**. Six actual Core-export JSON receipts report `kernelChecked: true`, pinned Lean commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, and imported assumptions exactly `["propext", "Quot.sound"]`.

| Export | Declarations | Roots | Recursor rules | Shared source nodes | Source bytes |
| --- | ---: | ---: | ---: | ---: | ---: |
| F1: Canonical model | 922 | 30 | 11 | 83,125 | 11,097,675 |
| F1: Independent constructor/validity | 21 | 2 | 0 | 1,702 | 307,290 |
| F2: Logical operations | 1229 | 36 | 24 | 91,024 | 11,179,796 |
| F3: Numeric conversions | 134 | 42 | 1 | 3,286 | 620,103 |
| F3: Display/cross-width | 16 | 12 | 0 | 234 | 238,111 |
| F3: Platform words | 196 | 91 | 2 | 4,775 | 773,868 |

All six corresponding candidate-policy receipts contain empty `axioms` and `quotientPrimitives` lists. The platform-word receipt explicitly records `replacedDefinitionAxioms: ["USize"]`; the other five have empty replacement lists.

F1 passed both canonical and independent constructor/validity replay. The independent roots are exactly `fromBits64` and `fromBits32`. F2 passed the strict comparison against retained `StandardFloatOperationsData.lean`. F3 passed strict retained comparisons for conversions, display and platform words. The conversion mismatch branch did not execute; an echoed script containing `PSCV0_F3_ASSET_DIFF` is not an actual mismatch result.

The actual float annotation-policy PASS marker and `PSCV0_KERNEL_HEARTBEAT_AUDIT: task allocations=50` each occur three times across F2 and F3. Their coverage includes true annotation removal, preserved ordinary Syntax/optParam and partial application, and official-kernel forged-type refusal. Completed decoded log lengths are **414,714** characters for F1, **84,990** for F2 and **91,965** for F3.

## Completed Native Linux evidence

Native [run 39051402014](https://github.com/dwijayuda/pskernel/actions/runs/39051402014), job [117450565117](https://github.com/dwijayuda/pskernel/actions/runs/39051402014/job/117450565117), passed **all thirty-four reported steps** without a failed or skipped step. Its completed decoded log has **4,475,706 characters**, and both checkout and final M1 performance JSON identify `e6b7f11750fdde6e1feacab86cfb32f2a82be8a5`. The performance record's `sourceSha` and `leanCommit` match the accepted compiler and pin.

| Native runtime / integration check | Actual completed result |
| --- | --- |
| Direct JavaScript | 1,069 shared observations |
| Compiled TypeScript | 1,069 shared observations |
| Rust | 1,069 shared observations |
| Generic Nat / Bool recursion | 100,000 / 50,000 steps |
| Three-module application | App.compute(7) = 18, entry exports and three-file provenance; JS/TS and Rust checks pass |
| Four-module GC application | V8 and Wasmtime execution passes, with one entry-only Boolean export |
| ECMAScript recursion paths | Uniform tail/alias, type-changing fallback, callback suspension, budget fallback and direct lambda pass |
| Native Wasmtime host | Shared observations, aggregates, normalization, indirect parameters, repeated calls and post-return marker pass |

The retained result-family, synthetic-resource, expected-instance, synthetic, default-instance and instance-graph markers all pass. Their coverage includes checked dependent-family resumption, preserved pending-index scope, public equality rollback, inference fuel and postponement ownership, saved instance scope, replay, quiescence, module visibility and resource limits.

The actual Standard snapshot is **3,633 declarations / 41 classes / 359 instances**. The selected identities are unchanged:

| Standard identity | Exact value |
| --- | --- |
| FNV-1a 64 | `4990397000639020696` |
| Standard SHA-256 | `5e96678b7ca94ac8dcb63d36cee81c5997287f507ce8c0c26d28321b37ce97d7` |
| Selected surface SHA-256 | `7a996cfc6253693799d43fdcf78dd7f30eb0713a3eb31831daa9d804faf818c6` |

All seven actual checked-project profiles retain the pinned Lean commit and selected-surface hash. Their interface-check status remains distinct from the separately executed runtime markers. The foundation audit records thirty-four checked candidate and active foundation declarations, empty candidate axioms, and `runtimeQualified: false` for that audit record. It is not relabeled as runtime-qualified by this receipt.

The C4b memory32 record retains **64 repeated calls, four UTF-8 refusals, nine boundary refusals**, `postReturn: true` and `completeWorldEqual: true`. The C4 GC record retains **1,069 shared observations, five scalar worlds and ten natural-limb checks**, with GC inside the component and core binary/WAT equality. It records Node 22.23.3, V8 12.4.254.21-node.57, wasm-tools 1.261.0 and Wasmtime 49.0.2.

**Existing host qualification:** the Native log includes two deprecation warnings that explicit `wasmtime::component::Func::post_return` calls have no effect in the pinned version. The successful repeated-call/host marker is retained; it does not establish an independent cleanup effect of that deprecated API call.


## Failed candidates and bounded repairs

The compiler correction was introduced once, at `9af377a8da017d0ef3440968e353010063fb9481`. Neither subsequent repair changed compiler logic.

| Attempt | Focused run / job | Actual result and response |
| --- | --- | --- |
| Initial `9af377a8da017d0ef3440968e353010063fb9481` | [39047098395](https://github.com/dwijayuda/pskernel/actions/runs/39047098395) / `117437900445` | The 104,970-character completed log reported reserved Lean local names `matches` at line 736 and `scoped` at line 830. Six lines were renamed to `matchingDiagnostics` / `scopedMain` and their uses. |
| First repair `81413f4052ccb0ca89c605d7aec6a99fa35ec3eb` | [39048426579](https://github.com/dwijayuda/pskernel/actions/runs/39048426579) / `117441769021` | The 104,783-character completed log reported unresolved expected type for the new indexed result's `.ok` pattern at line 869, followed by an inaccessible-pattern error. The next repair explicitly typed Batch, the Nat-index list and Option (Except Diagnostic Result), with qualified Except patterns. |
| Second repair `e6b7f11750fdde6e1feacab86cfb32f2a82be8a5` | [39051402005](https://github.com/dwijayuda/pskernel/actions/runs/39051402005) / `117450565084` | The completed focused gate passed all fifteen steps; its exact assertions and runtime observations are recorded above and below. |

Source review before the final repair push also caught the four mixed named/positional dictionary calls. Those calls now name `tag`, `d` and `n`, preserving dictionaries 41/7 and expected values 44/10. This was a pre-push review finding, not a third executed fixture failure. The final repair changes **+13/-12 fixture lines** relative to the first repair. No acceptance assertions, compiler logic, native oracle results, workflows or budgets were weakened.

Both failed focused attempts stopped during host fixture compilation, before the fourteen outer fixture commands and portable source batches/runtime comparisons, and produced no focused artifact. Native warning guards, run_cmd controls and type checks may execute during host module elaboration before a later host error; this history does not imply that no compile-time native controls ran. A log line reaching a final numbered Lake job does not make that build successful. Their Native/F1/F2/F3 passes are retained as failed-candidate history, without qualifying any later compiler revision.

| Failed candidate | Native | F1 | F2 | F3 |
| --- | --- | --- | --- | --- |
| `9af377a8…` | [39047098412](https://github.com/dwijayuda/pskernel/actions/runs/39047098412), 34/34 successful steps | [39047098462](https://github.com/dwijayuda/pskernel/actions/runs/39047098462), success | [39047098424](https://github.com/dwijayuda/pskernel/actions/runs/39047098424), success | [39047098380](https://github.com/dwijayuda/pskernel/actions/runs/39047098380), success |
| `81413f40…` | [39048426570](https://github.com/dwijayuda/pskernel/actions/runs/39048426570), 34/34 successful steps | [39048426699](https://github.com/dwijayuda/pskernel/actions/runs/39048426699), success | [39048426649](https://github.com/dwijayuda/pskernel/actions/runs/39048426649), success | [39048426595](https://github.com/dwijayuda/pskernel/actions/runs/39048426595), success |

Each healthy Native run was allowed to complete before the next compiler/test push. No healthy job was canceled. The original static fixture review missed the reserved local names; the actual CI failures and their repairs are preserved here. An independent bounded constructor audit also found one pre-push positional `PsElabDeclarationBatchResult.mk` call affected by the new field. It was changed to a named record before the first candidate. The other inspected batch/origin/native and Where/header producers use compatible named records. These source reviews supplement the completed gates.

## Exact implementation scope

Relative to the preceding accepted documentation checkpoint `e00f189cd4ce13da8cf37bf503884b339b553ec5`, the candidate series changes eight compiler files by **+136/-43 lines**, and the existing Where fixture by **+356/-5 lines**. Four current work documents and the migration checkpoint accompany the changes. All eight compiler blobs are identical across the three attempted compiler/test revisions.

| File | Exact blob | Added / removed |
| --- | --- | ---: |
| [host/src/Ps/Host/NativeV7.lean](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/host/src/Ps/Host/NativeV7.lean) | `33412ab00a540b35ed22e9b95e4ca8ce51fc9a8f` | +41 / -11 |
| [packages/elab/src/Ps/Elab/Command.lean](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/Command.lean) | `f738fd39cf0ed53875224fe4b390875b7c86b804` | +6 / -3 |
| [packages/elab/src/Ps/Elab/Data.lean](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/Data.lean) | `ef7d437313e619c2c503b744de3b013e22e1de94` | +2 / -0 |
| [packages/elab/src/Ps/Elab/Declaration.lean](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/Declaration.lean) | `62738338ab034dd9a339b215c2fb5d96d18a18c3` | +5 / -2 |
| [packages/elab/src/Ps/Elab/PreDefinition.lean](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/PreDefinition.lean) | `58f0ad754b8986b23cb12a40a03f419e18e991f0` | +42 / -3 |
| [packages/elab/src/Ps/Elab/Where.lean](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/Where.lean) | `0966fa5a563ec7dd2542bef2beade1cee7fe25ab` | +5 / -2 |
| [packages/elab/src/Ps/Elab/WhereScope.lean](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/WhereScope.lean) | `cf3f3098603fd768128b534c58647b82dd0210ed` | +27 / -22 |
| [packages/elab/src/Ps/Elab/WhereWellFounded.lean](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/WhereWellFounded.lean) | `371c5bdda7cb584d49e8f93c10b51ae287b80e1c` | +8 / -0 |
| [test/Pscv0M3Where.lean](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/test/Pscv0M3Where.lean) | `7f4d1c18a10a54e7db84226e33fc0e88e018a21c` | +356 / -5 |

No workflow, runtime export, shared runner, Lean pin, language-authority blob, trust policy or resource budget changed. The focused workflow remains blob `cd49fea4c0b17e140c109da294fd127bfe413ef4`; scalar and original deriving runners remain blobs `83f069245f7b94fa5a9bce4779ab6619b46512c3` and `b3898fc6d889ab05af9c676342c4f34059f9bbc8`.

## Precise limits and next obligation

Warnings retain ProofScript's stored source spans. This is not a claim that the byte/token coordinates equal Lean's own syntax coordinates. A main `partial_fixpoint` currently retains the whole declaration span, and that actual span is reported. No narrower keyword span is invented. Standalone `decreasing_by`, `termination_by?`, and structural-hint grammar are not newly represented.

Ignored hints add neither proof nor capture evidence. Invalid actual headers/bodies, active termination obligations and strategy compatibility checks remain required. Successful-result warning transport does not establish cumulative-message parity for later failures.

The prior result-family rollback statement means restoration of the **public equality/family transaction** on failure. A low-level worker can still return partial context under its pre-existing API. This checkpoint does not rewrite every raw worker's return contract.

### Next: plain ordinary section-instance parity

A source audit identifies a separate route gap at [Command](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/packages/elab/src/Ps/Elab/Command.lean#L235): an explicit-result ordinary function without a Where block or hint still uses legacy `psScopeDeclaration`. Its source-used-key selection can omit a local dictionary whose alias type depends on a section tag when neither the tag nor dictionary name appears in the header/body. The equivalent hinted function takes typed predefinitions and sees the full section context. This is a conclusion from source ownership, not a newly executed plain/hinted sentinel in this checkpoint.

The next bounded implementation candidate is to route an ordinary explicit-result `.definition` with no registration and a nonempty section context through the existing typed predefinition owner. Qualify matching native/portable plain and hinted functions using two nonzero actual dictionaries, complete capture headers and exact equations. Preserve private flags/aliases, registered abbrev/attribute/instance behavior, theorem include/omit policy and actual typed recursion analysis. Use all-named portable `tag`, `d`, `n` calls. The current dictionary regression is explicitly a Where/predefinition pair, so it does not close this legacy route.

### Progress rubric

| Area | Retained estimate |
| --- | ---: |
| Data | 25/30 |
| Source | 14/15 |
| Total recursion | 16/20 |
| P0 | 13/15 |
| P1 | 1/10 |
| Integration | 9/10 |
| **Total** | **78/100** |

This bounded source diagnostic correction earns no automatic score point or runtime comparison. Complete source parity, broader inference, indexed binary deriving, nested/source induction, larger changing well-founded state packs, arbitrary measure telescopes, general mutual well-founded recursion and the full P0 matrix remain open. M3+B, M4 and M5 remain open.

## Authority and evidence method

The sole forward language authority remains [PSCV0_LANGUAGE_REFERENCE_v7.2.md](https://github.com/dwijayuda/pskernel/blob/e6b7f11750fdde6e1feacab86cfb32f2a82be8a5/psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md), blob `694115223777599ba28ee175e14bb642b7b6aa4b`. Lean remains **4.35.0**, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Only **propext** and **Quot.sound** are approved. P1 remains unavailable because its audited construction/equations depend on **Classical.choice**.

All repository reads/writes and completed-log retrieval used connected GitHub and cloud Linux CI. There was no local clone, filesystem build or local execution. Live branch HEAD was checked before each nonforce expected-HEAD ref update. Each new compiler/test candidate required all five gates at one exact SHA. PR [#109](https://github.com/dwijayuda/pskernel/pull/109) remains draft/open/unmerged on original base `psc0/pscv0-v7-m1-parser-ownership-v1`.

Artifact IDs, names, sizes, digests and exact run/head identities were checked against both the artifact API and completed upload receipts. Archive contents were not independently downloaded, reopened or rehashed. Runtime and source observations come from actual completed-log output, separated from echoed shell commands, generated source strings and historical results.

The preceding [result-family receipt](PSCV0_M3_RESULT_FAMILY_QUALIFICATION_2026-10-17.md), [generic P0 receipt](PSCV0_M3_GENERIC_P0_RUNTIME_QUALIFICATION_2026-10-17.md) and [independent WF receipt](PSCV0_M3_INDEPENDENT_WF_QUALIFICATION_2026-10-17.md) preserve earlier accepted cells and their exact evidence. This receipt records the later compiler/test identity rather than mixing those earlier gates.
