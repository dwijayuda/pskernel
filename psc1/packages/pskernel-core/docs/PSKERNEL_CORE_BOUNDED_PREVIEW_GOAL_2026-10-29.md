## Current implementation checkpoint — 29 October 2026 (Asia/Jakarta)

The supervised file interface is implemented, qualified and available in runnable **development candidates**. **Bounded Independent Checker Preview 1 remains incomplete: P5 is BLOCKED; P6 and full P7/P8 closeout remain OPEN.** See [implementation and complete evidence](evidence/2026-10-29-preview-supervisor-checkpoint.md) and [the runtime contract and test map](PREVIEW_RUNTIME_2026-10-29.md). The original acceptance criteria below are unchanged.

- **Interface qualification:** source `8043c820`, [run 40759412487](https://github.com/dwijayuda/pskernel/actions/runs/40759412487), SUCCESS. Both emitted routes pass 67 supervision/ingress controls plus all retained adapter controls. Actual nonempty valid/invalid files and standard-axiom inputs use the real public empty-session/V1RunDag checker. The parent supervises deadlines, cancellation, output and process cleanup and validates the identified complete receipt. Native-derived standard axiom schemas and their required primitive declarations are checked; a familiar axiom name supplies no authority.
- **Candidate delivery:** producer `1e744380`, [run 40763702135](https://github.com/dwijayuda/pskernel/actions/runs/40763702135), SUCCESS for development candidates only. Both packages pass all five detached empty-PATH examples on Linux/Node 22.23.4. Manifests, source/Git bindings, raw receipts and nested evidence were independently inspected. Current source preserves all 814 retained axiom reports and 61 proof modules. Generated artifact `12849556440`, canonical `12848044294`, evidence `12849316798`; all explicitly retain `fullPreviewQualified:false`.
- **Full workloads remain blocked:** [campaign 40757332144](https://github.com/dwijayuda/pskernel/actions/runs/40757332144) (Node 22.23.4) completed canonical 8,400/generated 7,000 String assertions; generated sample 5 timed out at 1,500 seconds. [Diagnostic replication 40761853427](https://github.com/dwijayuda/pskernel/actions/runs/40761853427) (Node 22.23.3) completed generated 8,400/canonical 7,000; canonical sample 5 timed out at the same deadline. Both campaigns are terminal FAILURE. There are 22 complete and two censored samples out of 24. All four emitted programs are byte-identical (10,824,302 bytes, SHA-256 `1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968`). No passing pair, passing median, Node-regression diagnosis or stable speedup follows from these observations.
- **Both complete 193-case Arena comparisons** preserve every classification and all 176 completed raw semantic envelopes: 174 strict passes, 17 timeouts and two safety-contract differences. The original comparator retains its failed exit status. Neither censored String result nor an Arena failure is excluded.

| Preview gate | Current checkpoint |
|---|---|
| P1/P2/P3 | Implemented contract and real independent file checking; 67 finite controls per route plus retained controls |
| P4 | Production source and 814 reports / 61 proof modules preserved and authenticated |
| P5 | **BLOCKED**: no fresh campaign passes both complete String routes |
| P6 | Arena unchanged; unresolved String deadline variability remains **OPEN** |
| P7 | Audited development candidates available; full product qualification OPEN |
| P8 | This implementation checkpoint recorded; full Preview 1 closeout OPEN |

**Original global status remains B OPEN / C FAIL / D OPEN.** Production source remains `bbe353e649feed5b796adb164dcec36eaca915ab`; integration remains `d746fb8cdcb47f2031ac6db483cf63b7debbcbef`. No kernel/compiler/toolchain/original harness/workload/oracle/proof-statement changes are introduced. The emitter/cache experiment remains isolated. Fetch both live refs before writes.

**Next task:** investigate actual mixed-Unicode sample 5 on Node 22.23.4 in a separately labelled GitHub Linux diagnostic using existing `PSC1_T01F_TRACE=1`. Keep the full 1,400-assertion sample, fixture, oracle, fuel 4,096, deadline 1,500 seconds and old-space 2,048 MiB. In the first failed log, admission (294), metadata (377) and the singleton marker all completed. Locate the exact blocking call among the following negative-input/distinct-string checks before choosing a fix. A traced diagnostic is not qualification. Preserve all complete/censored results, then requalify unchanged full gates for any changed program. Never splice passing routes across campaigns or use the old-patch diagnostic as a downgrade fix.

Candidate use on Linux/Node 22.23.4: `node check-export.mjs valid-example.ndjson`. The supervisor reports typed outcomes and host causes; timeout/crash/partial receipts/unknown assumptions cannot become acceptance. Fuel remains recursive depth, heap is not a total RSS cap, and JS embedding remains trusted integration. Global logical soundness, the 17 Arena timeouts/two safety differences, compiler replay, fixed points and backend preservation remain unfinished.

All compiler/kernel execution, tests, benchmarks and package generation ran in GitHub Linux Actions. Local work is source editing, static inspection and byte-identical artifact copying only. No main merge, force push, npm publication or subagents.

## Historical evidence retained verbatim

This checkpoint supersedes earlier pending statuses and execution order. All previous evidence, failures, censoring and original criteria remain append-only below.

# PSKernel-Core Bounded Independent Checker Preview 1

Normative next-delivery goal, revised 29 October 2026 (Asia/Jakarta).

## Goal

Deliver a reproducible Linux/Node 22 package that independently checks supported Lean 4.35.0 declaration-export files through PSKernel's real public checked-session/DAG path, reports its input assumptions, and returns a validated checking outcome or an explicit supervised non-answer under a documented resource policy.

The package must preserve the qualified nested implementation and original regression workload. It must ship the full evidence and limitations ledger. This milestone is an **engineering preview**, not the original fully compatible, globally proved sound, performant, self-hosting kernel. The full objective remains in the backlog with its original gates.

The release label must be `PSKernel-Core Bounded Independent Checker Preview 1`. Do not abbreviate it to "verified kernel", "complete kernel", "full Lean compatibility", "self-hosted compiler" or "performance-qualified release".

## Frozen scope and authority

| Item | Bound |
|---|---|
| Baseline code | Primary code checkpoint `a1a041b63ca4f2e34f5223240a7761e086f72f25`; production source tree `bbe353e649feed5b796adb164dcec36eaca915ab` |
| Lean target | 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`; this does not claim current-latest Lean compatibility |
| Host qualification | GitHub Linux Actions, Node 22; Windows/macOS operation is not qualified by these jobs |
| Input | The retained pinned `lean4export` stream profile as decoded by the real adapter; input is data, never executable JavaScript or a caller-supplied checked environment |
| Checking authority | `psKernelKernelSessionEmpty` with `psKernelProviderDefault`, then actual `psKernelV1RunDag`; the provider's native evaluator is absent |
| Public API | Retain KernelContract-v1, typed errors, ownership, original external IDs, resource/error order, atomic publication and supported original-state restart behavior |
| Artifact | Generated and canonical ZIPs, JS/TS/declarations/maps, complete source closures, examples, file runner, per-file hashes, provenance, test/limit ledger and Linux reproduction commands |
| Publication | Deliver ZIPs and Git evidence; no main merge, npm publication, external service deployment or forced ref update |

Use the already-qualified nested programs as the default. No emitter/cache/prelude experiment enters the baseline merely to satisfy this preview. If production source changes, preserve its full existing qualification and adopt only the reviewed diff with exact new-source evidence.

## User-facing behavior

A documented command of the form `node check-export.mjs input.ndjson` must be included in the unpacked package. The precise flags are frozen in batch 1. It must check a real input, not a smoke fixture selected by name. JS imports remain a low-level trusted integration surface; constructed session records and process-local checking receipts are not serialized proof certificates.

A supervisor invokes a detached worker with the current Node executable and explicit argument array. It starts an empty checked session, validates input, performs independent declaration admission and metadata checks, and emits one structured result. A source/compiler/Lean executable is not available to the runtime acceptance path. Official Lean is permitted only as the separate CI reference oracle.

Reuse the five kernel outcomes: `accepted`, `rejectedInvalid`, `declinedUnsupported`, `resourceExhausted`, `internalError`. The supervisor retains a separate host cause, such as wall deadline, heap failure, launch failure, output overflow, signal or invalid protocol. A malformed input is reported at the transport boundary. A timeout, crash, absent/duplicate envelope, malformed result or any non-success exit can never be upgraded to acceptance. A wall timeout is not a kernel-produced fuel error. These rules must have finite negative controls, not just documentation.

Every result binds the input digest, program digest, contract/toolchain identity, assumption policy, effective resource policy and diagnostic stage. `accepted` requires actual public admission and metadata validation, validated assumption policy, one well-formed complete worker result and the expected successful child termination. Progress logs are observations only. Output must not imply global logical soundness.

### Assumptions

Keep two separate audits:

1. PSKernel proof-build dependencies retain the strict allowlist `propext`, `Classical.choice`, `Quot.sound`, with every unknown axiom rejected and no `sorry` or native-evaluation shortcut.
2. Checked input files receive their own explicit assumption inventory. The default strict file profile admits only the pinned standard axiom schemas, including their universe parameters and types. A familiar name alone is insufficient. Derive the schema pins in Linux CI from the exact target source and retain them in Git. Unknown or altered axiom schemas, and unsafe/partial declarations outside the strict logical profile, are declined explicitly. Do not invent replacements or silently omit declarations.

The low-level kernel API continues to check declarations relative to its supplied environment and declared assumptions. Preserve that API. The strict product profile is an additional boundary, and its policy outcomes must not overwrite the original Arena kernel verdicts or turn original failures into passes. Any input containing additional assumptions cannot receive an unqualified strict acceptance. Dependency assumptions must be reported; a declaration called an axiom is not itself a proof.

### Resources

- Retained kernel fuel: 4,096. It is a recursive bound, not a global work counter.
- Original Arena deadline: 60 seconds per case, two workers, no exclusions.
- Original String deadline: 1,500 seconds per sample, all six samples, 1,400 assertions each.
- Node old-space: 2,048 MiB; collect actual peak RSS separately. Do not call the heap flag a total memory cap.
- Runtime worker PATH is empty; address Node explicitly. No runtime official-Lean callback.
- The standalone wrapper uses a 60-second default wall deadline, documented as a resource policy rather than an invalidity criterion. The unchanged String harness continues to use its own original 1,500-second deadline.
- Add a finite diagnostic-output cap and process cleanup policy in batch 1. The parent must terminate and reap the worker on deadline/cancellation/output overflow, then report non-acceptance. Validate cleanup on a pinned Linux runner. Host scheduling and OS failures are assumptions, not a hard real-time guarantee.
- Do not change original fuel, heap, deadlines, workers, inputs, expected verdicts or assertions to make the preview pass. Diagnostic counters must be opt-in and not redefine qualification time.

## Acceptance gates

All eight gates below need a source-bound receipt. "Existing evidence" means scoped evidence on unchanged bytes; it does not qualify a newly changed wrapper or program. As of this revision, the complete Preview 1 product is **OPEN**.

| Gate | Concrete exit criterion | Status at revision |
|---|---|---|
| P1 Contract | CLI, schema, exit behavior, input assumptions, resources, support limits and trusted surfaces documented and frozen; every field maps to implementation/test/evidence | Specified here; implementation bindings OPEN |
| P2 Independent execution | Both packaged routes check actual positive and negative inputs through the real empty-session/public DAG path in detached empty-PATH processes; no official Lean at runtime | Existing library/examples verified; packaged supervised file interface OPEN |
| P3 Failure discipline | Controls cover all five kernel categories plus malformed input, fake receipt/session input, changed axiom type under an allowed name, unknown axiom, unsafe/partial policy, child timeout/cancellation, launch/signal/abnormal exit, missing/duplicate/invalid envelope, conflicting success/nonzero exit and output overflow; worker cleanup demonstrated | Existing pieces exist; complete wrapper matrix OPEN |
| P4 Source/proof preservation | Reviewed production diff; all retained 814 named reports/61 proof modules and statement bindings preserved under the original axiom audit; full applicable native/emitted controls remain | Baseline gate SUCCESS at `40441811683`; changed-input qualification conditional |
| P5 Original workloads | Both routes pass all 8,400 unchanged String assertions; all original 193 Arena cases execute under original limits with every row retained; original strict result and all raw semantic envelopes are compared and published | Baseline String PASS; strict Arena FAIL at 174/193, 17 timeouts, two differences; final package bindings OPEN |
| P6 No new regression | No new false acceptance, missing case, unexplained semantic-envelope/classification change or lost retained control; original strict counts remain visible; any new non-pass is investigated and blocks completion until explained and reviewed | Baseline evidence retained; final wrapper/corpus comparison OPEN |
| P7 Consumable artifacts | Both complete packages have verified manifests, source-bound producers and runnable API/file/nested examples; Linux reproduction works; limitation ledger prominent; raw CI evidence independently inspected | Earlier library packages verified; supervised package extension OPEN |
| P8 Reviewable closeout | Per-gate implementation/test/artifact/result mapping, all terminal workflow results, exact expected-HEAD/non-force Git update and readback; continuation names the next unresolved goal | This roadmap is committed independently; product closeout OPEN |

P5 has two explicitly different outputs. **Preview evidence completeness** requires executing and publishing every case, preserving the baseline and investigating changes. **Original strict compatibility** requires 193 strict passes and remains FAIL while the 17 timeouts and two contract differences persist. This distinction does not change any original expected outcome, budget, comparator, failing exit code or acceptance criterion. Every preview closeout must print both statuses together.

The String requirement is not replaced by a few example successes. The original `pskernel-arena435-compare.py` continues returning failure for a non-complete strict gate. A workflow may produce a preview artifact while its separately reported strict compatibility gate is failed; it must never present aggregate strict failure as a passing full release.

A newly found false acceptance blocks this preview until fixed with qualification of the changed source. Known timeouts can remain disclosed limitations of this preview; they remain failures of the full practical goal. The milestone is not allowed to become a generic "document whatever happened" success if an acceptance gate fails.

## Four implementation batches

| Batch | Work | Stop/review boundary |
|---|---|---|
| 1 | Implement the package supervisor and worker by reusing the retained stream adapter/public API; freeze result/exit/schema/assumption/resource contract | Inspect Linux CI on actual checking, strict assumption pins and success/error paths; revise the remaining estimate from observed defects |
| 2 | Complete P3 failure/cleanup matrix and package examples; keep stdout verdict separate from stderr progress | Every new fault-injection control has a required result and proves no accidental acceptance; failures are fixed before the next batch |
| 3 | Bind the same final program/adapter to all original String/Arena controls; compare all rows and completed semantic envelopes; add diagnostic-only phase evidence for cases 83/82 | Audit terminal raw artifacts; no new regression or missing original assertion; strict Arena failures remain reported |
| 4 | Build both packages in Linux Actions, audit source/manifests/examples, freeze the limitation ledger and finish P8 | Stop Preview 1 only after P1–P8 are met and both preview and original-global statuses are published |

These are bounded work packages, not a calendar estimate or a guarantee that every gate will pass immediately. No numerical certainty percentage is justified. A discovered central checking defect requires a fix and requalification; it is not postponed through a release-label change. Re-run relevant checks after changes; avoid repeatedly rebuilding unchanged large programs without a new reason.

## Deferred from the preview critical path

- Resolving all 17 Arena timeouts and the two safety-contract differences: required for the original strict practical-compatibility goal, not declared solved here.
- Proving a whole-kernel speedup: optional future candidate qualification. Existing emitter/cache experiments remain isolated; their original full-gate adoption rule is unchanged.
- Accepting the compiler declaration closure: missing `Nat` is still the first observed replay blocker. No unchecked or dummy prelude is allowed.
- Compiler fixed points, global logical soundness and backend preservation: separate research/proof goals with no promised deadline.
- Upgrading the target Lean/toolchain, new wire formats, Mathlib-scale completeness, cross-platform qualification, parallel runtime changes and npm publication.

The immediate next task is batch 1. It supersedes the earlier instruction to put emitter qualification first, solely for the revised next-delivery milestone. This is the user's requested goal revision; it is not evidence that the original kernel assignment has been completed.

## Public completion wording

Use the following shape only when P1–P8 actually pass:

> PSKernel-Core Bounded Independent Checker Preview 1 is delivered for the pinned Linux/Node/Lean export profile. It independently checks supported files, reports assumptions and resource outcomes, and ships complete finite regression evidence. Original strict Arena compatibility is [actual result, all 193 cases and remaining differences]; global soundness, self-hosting and backend preservation remain [actual status].

At this revision, that product delivery statement is **not yet authorized by evidence**. Only the research and revised goal have been completed.
