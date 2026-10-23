# PSC1 active work state

Updated 2026-10-23. Draft [PR #172](https://github.com/dwijayuda/pskernel/pull/172),
active branch `fix/psc1-closure-normalization-20261021`.
Use connected GitHub tools and Linux Actions only. Fetch latest remote HEAD
before non-force, expected-HEAD commits. Preserve history. No merge or npm
publication is authorized.

## Verified production-source checkpoint

Qualified source `d0bef34de7d5d3c495f2a4a73af7eccd892d0d74`;
tested merge `6cc6c55b4785eebf70f27331610f9e949a3a84e5`.
[Linux run 39887884270](https://github.com/dwijayuda/pskernel/actions/runs/39887884270)
completed successfully: every selected job, all 47 full-job steps and all
37 finite Practical Core criteria. The benchmark lane was dependency-skipped.
Both grammars, all seven targets, applications, independent official Lean
admission, strict IR, negative tests, host boundaries, compiler closures,
minimum Python and installed native package qualification pass.

The frozen release authority remains
[PSC1_PRACTICAL_CORE_V1_CONTRACT.json](docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json):
14 families, 37 finite criteria, both grammars, seven targets, four application
categories. This is scoped qualification, not unrestricted language completeness
or a formal backend preservation theorem. The native package is unpublished;
its tarball SHA256 is
`037aeb87220f38d9d70ed01a8a6540ae58f751c2f8eaa168b30875ed8e052962`.

Exact source/tool/package identities, jobs/steps, artifacts and expiry are in
[the current machine receipt](docs/PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json).
The normal full artifact 12474609129 expires 2026-11-06T02:47:32Z.
Previous state, roadmap, receipt and every commit remain preserved.

## One compiler and genuine generation evidence

Rust native execution and TypeScript readable npm-compatible distribution lead
self-hosting. `Ps.Compiler.Service` shares the existing source/frontend/elaborator,
original checked IR, target planning, admissions and origin identities.
Thin target facades call existing production emitters; there is no handwritten
target compiler. A single native seed is followed by actual emitted compilers;
native compiler executables are removed before generated work. The host separately
admits exact canonical graphs with official Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

| Target / source | Actual completed qualification | Remaining boundary |
| --- | --- | --- |
| Rust baseline ea10eff9 / 39880803794 | G1 executable and all ten frozen cases | G2 timeout at 240031 ms |
| Integrated TypeScript annotation source / 39887064597 | Strict compilation, executing G1 and all ten cases | G2 timeout at 240091 ms |
| Isolated Rust ownership + private Drop / 39890802847 | Both grammar audits, G1 and all ten cases; 500000-node/drop-order stress tests | Later G2 stack failure at 186541 ms |
| Isolated TypeScript structured generator / 39889151346 | Both grammar audits, G1 and all ten cases; two all-input legacy equalities | G2 timeout at 240086 ms |

Neither target has completed G2/G3 or fixed-point qualification. No final binary
reproducibility claim is made. Integrated TS G1-tested source and qualified main
have identical blobs for all 489 PSC1 Lean files (recorded tree witness); its host
receipt-bookkeeping update does not change the compiler closure.

DirectJS G1 remains qualified as the normal reference/regression. Its diagnosed
G2 JavaScript heap defect remains tracked in
[the retained defect](docs/PSC1_G2_PERFORMANCE_DEFECT_2026-10-21.md).
DirectJS-specific G2 optimization is not prioritized.

## Measured corrections and current isolated work

TypeScript's strict checker stalled on contextual return/yield/conditional
inference. Explicit nested generator result annotations use checked IR types,
preserve all-input legacy rendering, and retain 264 old/current print/runtime
selection comparisons. That correction is integrated and normally qualified.
The isolated structured-generator follow-up reduces suspension overhead,
preserves ordinary typed/fuel preflight and legacy pure output by induction,
and refuses alias escape or unsafe shadowing. A 220-second exact replay's final
30-second profile shows active frontend instantiation/inference and string/name/
environment lookup, alongside generator dispatch. It is not a finished G2.

Rust exact replay exposed full String copying in request decoding. Borrowed
ordered intrinsic wrappers, last-use String aliases and tail transfers address
that class; changing arguments evaluate before unique owned locals move.
Capture analysis, duplicate/shadow guards and retained-old/current execution
tests preserve scope and evaluation order. The subsequent crash was recursive
`Rc::drop_slow`. Safe iterative destruction applies only to private, regular,
last-field linear recursion with an empty sentinel; public enum representation
is unchanged. Shared tails and original field-drop order are tested. No unsafe
code or stack increase is introduced.

[Exact later crash diagnosis 39891954467](https://github.com/dwijayuda/pskernel/actions/runs/39891954467)
identifies native recursion in `psLexStringToListFromWithFuel`.
The shared cursor accumulator/reverse correction keeps every original fuel,
source and raw-offset result. Its all-input equality proof and 100000-character
native stress case precede both grammar audits and actual generations.

Latest isolated shared-cursor qualifications are terminal. Both prove the all-input
equality, execute 306 offset/fuel cases and 100000 characters, pass both full
grammar audits and all ten actual G1 cases. Rust G2 still fails with stack
overflow at 14116 ms; TS G2 times out at 240086 ms. No G2 candidate is admitted,
G3/fixed point are not run. The next exact Rust crash replay is dispatched at
`f07845ad5cd300d1e5c61fa71949741263286cdf`; inspect its terminal stack before
choosing another source/backend correction.

Exact tested requests:

- Rust branch `fix/psc1-rust-owned-string-moves-20261023`: source
  `623384b5212576229a6caae474edcdb4e71e9c76`, request
  `62c8937e72ece94e774bcee33f691edd1c293260`,
  [run 39893147337](https://github.com/dwijayuda/pskernel/actions/runs/39893147337).
- TS branch `fix/psc1-ts-generator-result-types-20261023`: source
  `ee45ca9035698ca12f0c6814c91b615db01242ff`, request
  `541419592bc2a90ea2b79737ba7e64ba365c4108`,
  [run 39893184640](https://github.com/dwijayuda/pskernel/actions/runs/39893184640).

Both apply identical shared Cursor.lean/proof bytes. The cursor correction and
later backend prototypes are **not integrated or normally qualified** on PR #172.
Do not promote merely because native proofs or G1 pass; use actual workload
evidence and fresh normal seven-backend qualification after integration.

## Execution boundaries and next work

Follow the [dependency-ordered roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) and
[executable continuation prompt](docs/PSC1_RUST_TS_SELFHOST_CONTINUATION.md).
First diagnose the next post-cursor Rust stack path and the measured remaining TS
full-workload cost, then finish independent G2/G3 and exact source/admission/original-IR/
transformed-IR/corpus fixed points for each target. Then qualify reproducible
target build products and readable distribution. Source/IR fixed points and
native executable bit equality are distinct evidence.

Preserve strict checking, unsupported ABI refusals, all negatives, source/tool
identities and existing fuel/heap/stack policies. Manual jobs retain 15 minutes;
child process groups are killed at 240000 ms with 32 MiB per stream. The
245000 ms supervisor guard is cleanup only. Incremental failed attempts now
record terminal failure rather than remaining running. All historical G1,
failed self-host and performance evidence remains.

Expensive generations remain manual/release work, separate from normal
development. PSKernel-Core Expression V2 research remains independent;
official Lean admission continues to authorize checked compilation.
