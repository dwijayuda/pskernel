# PSKernel-Core Bounded Independent Checker Preview 1

The supervised interface described here is under qualification. A successful library test or package upload does not by itself complete the eight preview gates. Original strict Arena compatibility remains separately reported.

## Run

Qualified host: Linux and Node 22. Unpack the generated or canonical preview package and run:

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

The final package must carry its actual current supervisor/control/workload receipts, manifest, source provenance and complete limitation ledger. The original full gates are unchanged: both String routes require all 8,400 assertions, and the strict Arena gate requires all 193 cases to pass. The retained baseline has 174 strict passes, 17 timeouts and two safety-contract differences. A no-regression ledger does not convert that strict failure into success.

Global soundness, whole-kernel speedup, compiler declaration acceptance, compiler fixed points and backend preservation remain unfinished. No package publication or main merge is performed by this preview delivery.
