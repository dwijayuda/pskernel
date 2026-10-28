# 29 October 2026 supervised checker implementation checkpoint

Date: 29 October 2026, Asia/Jakarta. This checkpoint delivers qualified supervised-file tooling and runnable development candidates. **PSKernel-Core Bounded Independent Checker Preview 1 is NOT complete. P5 is BLOCKED and P6 remains OPEN. Original global status remains B OPEN / C FAIL / D OPEN.**

## Implemented and source-qualified

- `psc1/scripts/pskernel-check-export.mjs`: documented file command, five outcome/exit categories, progress on stderr and a single JSON result on stdout. It rejects alternate-worker CLI flags and unqualified host profiles.
- `pskernel-preview-supervisor.mjs`: bounded regular-file snapshot, input/program/policy digests and request identity, direct child invocation with empty PATH, wall/cancellation/output enforcement, process-group cleanup and child reaping, exact worker-envelope validation and fail-closed exit handling.
- `pskernel-preview-worker.mjs`: strict assumption scan followed by the unchanged real stream decoder, checked empty-session construction and actual public V1RunDag admission/metadata validation. No official-Lean acceptance callback or native evaluator is introduced.
- `pskernel-preview-policy.mjs`: exact standard axiom schemas, universe parameters, canonical name segments and the required standard primitive declarations. Missing, altered, shadowed or unknown assumptions are explicit non-acceptance outcomes. Unsafe/partial input is outside the strict file profile.
- `test/PsKernelPreviewAxiomSchemas.lean` and committed `scripts/pskernel-preview-axioms.json`: schemas and exact fixture metadata derived from actual Lean 4.35.0 constants in Linux Actions. The committed 10,756-byte pin file is SHA-256 `3ad5dcd04963d296b079f41be90d1b647b948342e9992dd99fd0ad94222d312f`; CI regenerates and compares its exact bytes.
- Qualification, original-workload, diagnostic-replication and candidate-delivery workflows/scripts. Production kernel source, original adapters/harnesses, toolchain, proof statements, workloads, oracle outcomes and resource budgets are unchanged.

The qualification source is `8043c820bb670ae7a01249de7fd60112f21be2b5`, run [40759412487](https://github.com/dwijayuda/pskernel/actions/runs/40759412487), terminal SUCCESS. Each actual emitted route passes **67 distinct supervision/ingress controls** and every retained adapter control. Actual nonempty valid/invalid files, each standard axiom with its checked standard prelude, all-three assumption inventory and the fourth-unknown-axiom decline are included. Trusted fault fixtures test protocol/host failures; they are explicitly distinguished from real declaration checking and from formal proofs.

Controls cover missing/duplicate/invalid envelopes and JSON keys, wrong identities, absent checking evidence, misleading axiom names/types/primitives, unsafe/partial data, invalid UTF-8, fake receipts/sessions, absent/FIFO/oversized input, CPU-bound and idle deadlines, cancellation, child/descendant cleanup, launch/signal/heap/output faults and all five exit codes. Full details and the field-to-implementation/test mapping are in [the runtime guide](../PREVIEW_RUNTIME_2026-10-29.md).

The raw qualification artifact is `12848355088`, 3,106,055 bytes, SHA-256 `8d58977ce176697c614c66a53ec8f3d1654d71ddb3b0ba6ed5e1ffdafa7ab1c1`. Independent static inspection read every one of its 74 members, verified both manifests (29/30 files), actual source bindings to Git (10), pin bytes, actual logs/labels/results and identical 10,824,302-byte programs.

## Original workloads: both complete campaigns inspected, neither passes P5

All four sample-5 observations below use the same complete program bytes, same authentic fixture, same unmodified 1,400-assertion runner and fuel 4,096 / 1,500-second deadline / 2,048-MiB old-space / empty-PATH policy. Every other sample retains all its assertions. Two observations are right-censored and have no complete receipt.

| Campaign | Host Node | Route | Sample-5 seconds | Complete assertions in route | Result |
|---|---|---|---:|---:|---|
| [40757332144](https://github.com/dwijayuda/pskernel/actions/runs/40757332144) | 22.23.4 | Generated | at least 1,500; exit 137 | 7,000 / 8,400 | FAIL; no complete sample-5 receipt |
| Same | 22.23.4 | Canonical | 1,156.8552 | 8,400 / 8,400 | Route PASS |
| [40761853427](https://github.com/dwijayuda/pskernel/actions/runs/40761853427) | 22.23.3 | Generated | 1,260.5089 | 8,400 / 8,400 | Route PASS |
| Same | 22.23.3 | Canonical | at least 1,500; exit 137 | 7,000 / 8,400 | FAIL; no complete sample-5 receipt |

Both workflows are terminal FAILURE. Their separate strict Arena jobs retain failure, and their full passing-String ledgers correctly refuse completion. There are **22 completed samples and two censored samples out of 24 planned samples**, giving 30,800 confirmed assertions out of 33,600 planned assertions across these campaigns. The number actually executed inside either killed sample is unknown. Do not combine different campaigns' successful routes into a synthetic passing pair, drop either censored observation, or compute a passing performance median. The old scalar A-B-B-A's two censored observations remain historical failures too.

Each campaign independently reran the pinned official reference and all 193 original Arena bodies under the unchanged 60-second / 4,096-fuel / 2,048-MiB / two-worker policy. Both preserve exactly **174 strict passes, 17 timeouts and two safety-contract differences**. All 193 classifications/adaptations and all 176 completed raw stdout semantic envelopes equal the previously qualified nested baseline. No new Arena false acceptance or semantic/classification change was observed. This is finite Arena evidence, not a soundness theorem or a passing original strict gate.

Independent static review read **17 complete raw archives per campaign**, checking all digests/CRCs/members, original fixture/runner/program hashes, raw String logs and receipts, resource policies, official case-log digests and full Arena comparisons. The core program is byte-identical in every route and campaign: 10,824,302 bytes, SHA-256 `1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968`.

### Exact failure localization and uncertainty

The first generated timeout log records all 294 admission starts, completed admission at 53,911.0022 ms, completed validation of all 377 metadata records at 1,811.5714 ms, and `PSC1_T01F_JS_SINGLETON_PASS "Aé€😀"`. There is no final sample receipt. The unchanged harness emits this marker immediately before its remaining negative-input and distinct-string checks. The exact blocking API call is not established; use its existing opt-in per-API diagnostic tracing to determine it. Do not call this an admission timeout, claim a root cause, or count the missing receipt's 1,400 assertions.

The route that times out flips even though generated/canonical programs are identical. This rules out treating these observations as evidence of a generated/canonical code difference. Different runners, process behavior and the runtime patch all vary; no causal Node regression or stable speed ratio is established. [Node 22.23.4 is a security release](https://nodejs.org/en/blog/release/v22.23.4), so the 22.23.3 replication is diagnostic evidence, not a runtime-downgrade recommendation or a replacement for the blocked current-host gate. The tiny RSS/exit text emitted for the killed timeout wrapper is not Node peak RSS; the actual exit 137 and absent receipt determine classification.

## Candidate packages: usable, explicitly not completed Preview 1

Candidate producer `1e7443804448ee2583e9cddd23b6e29aa17ecc92`, run [40763702135](https://github.com/dwijayuda/pskernel/actions/runs/40763702135), is terminal SUCCESS for candidate delivery only. It reauthenticates the interface evidence, all 17 current-host workload archives and the retained native proof artifact, then checks current Git against every retained proof source and all qualified wrapper-source bindings.

| Artifact | ID | Bytes | SHA-256 | Members / current manifest files |
|---|---:|---:|---|---:|
| Generated candidate | 12849556440 | 1,726,975 | `078b93fbd4ab49cde82642c3118d5263a3f56daa33c2973a44b2b04263cb9bff` | 50 / 49 |
| Canonical candidate | 12848044294 | 1,882,791 | `06ac6aeb0f3c068f6d088623d41d7d6ce88e1152776c4d9a5a74090df8e0fc0f` | 51 / 50 |
| Candidate evidence | 12849316798 | 4,584,022 | `ad1beb68954445a906d3d6c9f7a05f386760da06c0058dc3a8ae5c1791f5da96` | 24 |

Both candidates include JS/TS/declarations/maps, source closures, wrapper/native-generator source snapshots, axiom pins, input examples, complete first-campaign limitation/Arena ledgers and the retained native evidence. Canonical additionally includes canonical source. Each passes five detached empty-PATH examples on Linux/Node 22.23.4: actual valid and invalid file commands, public API, retained checker smoke and complete public nested controls.

The default standalone worker deadline is 60 seconds. It enforces a 64-MiB regular-input limit and bounded output, and records explicit outcomes and identities. Fuel is recursive depth, not a global work counter. The old-space flag is not total RSS or an OS sandbox. Worker interruption and cleanup are finite-tested operating-system behavior, not a hard real-time theorem. Low-level JavaScript library embedding remains trusted integration; caller-created sessions/receipts are not serialized checking certificates.

The independently inspected candidate archives pass every current manifest member/hash, every bundled source/Git binding, example/log/provenance check and nested evidence digest/CRC check. The native archive `12706268210` (182,978 bytes / `1e53b134501d6fa1d0d828375b874bdcb7d554a33bb11364945626f4fd7aa930`) retains **814 distinct actual axiom reports and 61 source modules**, byte-identical to current Git, under the unchanged three-axiom allowlist. No new proof theorem or global checker soundness result is claimed.

`files.json` is the current package manifest. `baseline-files.json` and the old `provenance.json` describe the original runtime input; `candidate-provenance.json` and `limitations.json` describe the new candidate. The candidate's `fullPreviewQualified` is false, P5 is BLOCKED and P6 is OPEN. The later old-patch diagnostic is recorded in this Git evidence; it is not retroactively folded into the immutable current-host candidate receipt.

## Current acceptance matrix

| Goal gate | Current result |
|---|---|
| P1 | Interface/result/assumption/resource contract implemented and mapped to source, tests and evidence |
| P2 | Real independent file checking qualified in both packaged routes |
| P3 | 67 finite supervision/ingress controls per route; all retained adapter controls pass |
| P4 | Original production tree and all 814 reports/61 source modules preserved and authenticated |
| P5 | **BLOCKED**: neither fresh campaign passes both complete String routes |
| P6 | Original Arena semantics/classifications unchanged; **OPEN** for unresolved String deadline variability |
| P7 | Runnable development candidates delivered and audited; full Preview 1 product qualification remains OPEN |
| P8 | This implementation checkpoint is recorded/read back; full Preview 1 closeout remains OPEN |

## Immediate continuation

Investigate sample 5 on the current supported patched Node host with the existing `PSC1_T01F_TRACE=1` option in a separately labelled Linux diagnostic. Keep the real fixture, complete sample body, oracle outcomes, 1,400 assertions, fuel, deadline and heap budget. Record BEGIN/END calls around the post-singleton negative-input/distinct-string checks and measure the actual worker, distinguishing complete and censored observations. A diagnostic pass is not qualification because `diagnosticTracing:true` differs from the original qualification policy. Use an actual profile or exact call-boundary evidence to choose a fix; rerun the unchanged full gates for any changed program. Do not narrow the test matrix, splice successful routes across runs, downgrade the target to conceal failure, or adopt the isolated emitter/cache experiment without its retained full adoption evidence.

The 17 Arena timeout causes, two safety contracts, declaration/context/cache/checker logical invariants, compiler prelude/dependency replay (first missing constant Nat), fixed points and backend preservation remain unfinished. No main merge, force push, npm publication, local compiler/kernel execution or subagents occurred. All builds, tests, benchmarks and package generation ran in GitHub Linux Actions; local work was source editing, static archive/source inspection and byte-identical download/copy only.

## Reproducible independent static archive audits

The source includes `psc1/scripts/pskernel-preview-audit-supervisor.py`, `pskernel-preview-audit-candidate.py` and `pskernel-preview-audit-workloads.py`. These inspect downloaded bytes and logs without executing a compiler, kernel or workload. Save the GitHub artifact metadata array as JSON and place its raw `<artifact-id>.zip` files beside that JSON. Run the corresponding script with the metadata JSON path; workload auditing also requires baseline `12705990238.zip` beside it and `--allow-failed` for either failed campaign. Keep the two campaigns' metadata and audit summaries distinct. Supervisor/candidate audits fetch the exact pinned Git source for byte comparison. Do not run Python with assertions disabled. Missing or expired evidence requires explicit regeneration and qualification, not changing expected hashes.
