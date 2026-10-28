# PSKernel-Core Bounded Independent Checker Preview 1

The supervised interface is qualified as a development candidate. Full Preview 1 is incomplete: P5 is BLOCKED by fresh full-workload String timeouts and P6 remains OPEN. Candidate delivery and passing interface controls do not complete the eight preview gates. See [the implementation checkpoint and complete failure ledger](evidence/2026-10-29-preview-supervisor-checkpoint.md). Original strict Arena compatibility remains FAIL at 174/193, with 17 timeouts and two safety-contract differences.

## Run

Candidate-tested host: Linux and Node 22.23.4. Unpack the generated or canonical development candidate and run:

```sh
node check-export.mjs valid-example.ndjson
node check-export.mjs invalid-example.ndjson
node check-export.mjs --progress --timeout-ms 60000 your-export.ndjson
node api-example.mjs
node nested-example.mjs ./kernel.js
```

The command checks actual declaration-export files through PSKernel's checked empty session and public DAG admission. It also checks supplied metadata against independently admitted/regenerated declarations. It never invokes official Lean or a compiler at runtime. The input must carry the pinned Lean 4.35.0 identity and the supported lean4export 3.1.0 wire profile; this interface does not create missing prelude declarations.

`--progress` writes diagnostic stage observations to stderr. Stdout contains exactly one JSON result. Progress is not a checking result. A file cannot supply a checked session, receipt, native evaluator, worker program or alternate kernel. JavaScript library embedding remains a trusted integration surface.

## Outcomes and exit codes

| Outcome | Exit | Meaning |
|---|---:|---|
| accepted | 0 | The strict input policy passed, actual public admission and metadata validation succeeded, and the identified worker returned one complete valid result and exited successfully |
| rejectedInvalid | 1 | An invalid checking/metadata result, or malformed transport input; inspect `stage` to distinguish them |
| declinedUnsupported | 2 | The input target or strict assumption/safety profile is unsupported; no claim of logical invalidity |
| resourceExhausted | 3 | A kernel resource result or supervised host limit/cancellation; no claim of invalidity |
| internalError | 4 | An unexpected kernel/host/configuration/protocol failure; no acceptance |

The result binds the input, emitted program and policy hashes when those bytes were successfully read, plus target identity, configured limits, assumption inventory and checking/host observations. Hashes are null on failures before the bytes are available. Missing or invalid worker results, contradictory exit status, duplicate envelopes, unknown result categories and missing checking evidence never produce acceptance.

`host.cause` records wall deadline, cancellation, output limit, heap diagnostic, signal, launch failure or protocol error separately from the typed kernel outcome. A wall timeout is not a kernel fuel error. `host.workerReaped` says whether an actual child exit was observed; false is expected when launch never occurred. Non-success batches publish no reusable session.

## Assumptions and supported profile

The strict file profile admits only the pinned standard axiom schemas for `propext`, `Classical.choice` and `Quot.sound`. It checks universe parameters and structural types rather than names alone, and requires the corresponding standard primitive declarations. The pins are derived from the actual Lean 4.35.0 constants in Linux CI, retained with provenance, and checked again on qualification.

Declarations and primitive data still pass the original kernel checker. The policy provides no authority for absent prelude declarations or metadata. Unknown axioms, modified standard schemas, misleading dotted-name segments, shadowed primitive dependencies and unsafe/partial declarations outside this profile decline explicitly. This policy is additional to the retained low-level API, which checks relative to its supplied environment and assumptions.

The three-axiom audit of PSKernel's own native proof modules is a separate boundary. Neither input-policy success nor a proof-report count establishes global logical soundness of PSKernel or preservation by its compiler/backend.

## Resource policy

- Worker default wall deadline: 60,000 ms. The supervisor starts this clock at worker launch; preflight file/identity I/O precedes it. `--timeout-ms` accepts 1 through 1,500,000 ms. Changing a user's operation budget does not change the original qualification budgets.
- Kernel recursive fuel: 4,096. This is not a total instruction counter. The kernel's existing depth/natural-size/declaration policies are unchanged.
- Worker Node old-space: 2,048 MiB. This is not a total-process RSS limit or OS sandbox.
- Input: regular files up to 64 MiB. The parent reads a bounded snapshot once and passes those exact bytes to the worker. Program, worker and policy paths are trusted package contents.
- Worker stdout cap: 262,144 bytes. Worker stderr cap: 1,048,576 bytes. Exceeding either terminates the worker group and reports non-acceptance.
- Cancellation and wall/output limits kill the Linux process group and wait for the child close. CI checks worker cleanup and a descendant-process case. The host OS and scheduling remain assumptions; there is no hard real-time or OS-isolation theorem.
- The worker runs with empty PATH and a clean environment. Node is addressed through the current executable. Production execution has no test-worker override flag.

## Evidence and limits

The baseline emitted kernel is exactly 10,824,302 bytes, SHA-256 `1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968`, generated from the previously qualified nested producer. Its Lean source tree is `bbe353e649feed5b796adb164dcec36eaca915ab`. The wrapper adds no production Lean or compiler changes.

Each candidate carries its actual supervisor/control/workload receipts, manifest, source provenance and limitation ledger, and explicitly records `fullPreviewQualified:false`. Both original String routes require all 8,400 assertions; neither fresh campaign passed both routes. The strict Arena gate requires all 193 cases to pass. Preview P5 requires retaining every Arena case and its actual result; it does not require concealing the retained strict failure. The retained baseline has 174 strict passes, 17 timeouts and two safety-contract differences. A no-regression ledger does not convert that strict failure into success.

Global soundness, whole-kernel speedup, compiler declaration acceptance, compiler fixed points and backend preservation remain unfinished. No package publication or main merge is performed by this preview delivery.

## Implementation and test mapping

| Contract surface | Implementation | Required observed controls/evidence |
|---|---|---|
| CLI syntax and exit codes 0–4 | `check-export.mjs`, `exitCodeFor` in supervisor | Actual valid/invalid file invocations; five outcome exit-code controls; alternate-worker option rejected |
| Input snapshot, program/policy hashes and request identity | Supervisor input reader/digest and worker rehash; `validateWorkerResult` | Actual identity receipt; altered input/policy identity faults; source and manifest audit |
| Target identity and public checking authority | Policy `TARGET`; retained adapter's default-policy/provider preflight and V1RunDag | Target mismatch; actual nonempty valid definition and ill-typed body; retained adapter controls |
| Standard input assumptions and primitive binding | `scanAssumptions`; native schema generator and committed pins | Three independently admitted standard-axiom files; alpha-renamed universe schemas; all-three inventory; fourth unknown axiom; altered type; missing/shadowed primitive; dotted-name spoof |
| No receipt/session authority from input | Unchanged stream decoder plus public empty-session construction | Fake receipt and fake session records never accept |
| Regular input and byte budget | `boundedInput`, `LIMITS.inputLimitBytes` | Invalid UTF-8; FIFO nonblocking rejection; absent file; 64-MiB-plus-one resource result |
| Kernel outcome categories | Worker outcome mapping and retained constructor-aware `kernelErrorVerdict` | Actual valid/invalid declarations and unsupported input; retained real V1 unsupported/resource controls; separately labelled trusted protocol fixtures for resource/internal results |
| Acceptance receipt discipline | `validateWorkerResult`, child exit/close handling | Missing/duplicate/invalid JSON; duplicate keys; absent core/metadata/policy evidence; unknown assumption; success/nonzero-exit conflict; signal |
| Deadlines, cancellation and cleanup | Detached worker group, parent timer, SIGKILL and child close | CPU-bound and idle deadlines; inflight/prelaunch cancellation; descendant cannot survive; child reaped |
| Output and host failures | Bounded stdout/stderr collection, launch/error handling | Both output caps; missing executable; heap-diagnostic fixture; abnormal child termination |
| Resource and trust claims | Supervisor result fields and this guide | Original 4096-fuel/2048-MiB-old-space policies retained; old-space is not total RSS; no hard real-time, OS-isolation or global logical-soundness claim |

The 67 controls are finite supervision/ingress tests, including explicitly trusted fault fixtures. They are not 67 formal soundness theorems or a replacement for the original 193-case comparison. The 814 preserved proof reports and 61 proof sources are authenticated separately; they do not close global checker soundness.

## Reproduce in GitHub Linux Actions

For the original kernel source build, use `SOURCE_BUILD.md` in the package (the repository source is `QUALIFIED_RUNTIME_2026-10-27.md`). It names the exact producer source, Lean commit, compiler routes and retained full build workflow. Keep compiler/kernel execution in GitHub Linux Actions.

For the new interface, use `.github/workflows/psc1-pskernel-preview-supervisor.yml` from the qualified wrapper source. It installs exact Lean only to derive the standard schemas, compares regenerated pins against the committed file, authenticates both original runtime artifacts, and runs all interface/retained adapter controls in detached empty-PATH processes. The native derivation command, from `psc1/`, is:

```sh
test "$(lean --githash)" = eb6cafb7290e8bd5f2937522d8d804f58f02bafc
lake env lean --run test/PsKernelPreviewAxiomSchemas.lean > "$RUNNER_TEMP/preview-axioms.json"
cmp scripts/pskernel-preview-axioms.json "$RUNNER_TEMP/preview-axioms.json"
```

The qualification script is `psc1/scripts/pskernel-preview-qualification.py`; candidate packaging is `psc1/scripts/pskernel-preview-candidate-delivery.py` with its exact committed artifact input manifest and candidate workflow. Run these only in Linux Actions with the job's read-only repository/actions token. Source snapshots of the qualified interface and native generator are included under `preview-source/` in the candidate.

Artifact IDs are evidence for exact prior runs, not interchangeable dependencies. When a referenced artifact expires or a producer changes, regenerate and independently qualify its evidence and update the pins explicitly. Do not substitute an unchecked binary, update expected digests silently, or mutate old qualification runs to look like new source qualification.
