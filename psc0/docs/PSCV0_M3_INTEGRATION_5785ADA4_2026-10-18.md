# M3 native lambda input integration receipt

Compiler/test SHA: **5785ada4d0521eaa910a57adc8569dbe95d4c5fe**.
Lean4.35.0: eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Fresh GitHub run/job/artifact metadata on2026-10-18 confirms all five gates
completed SUCCESS at this exact SHA.

| Gate | Run | Job | Artifact | SHA256 |
| --- | --- | --- | --- | --- |
| Native | [39094184382](https://github.com/dwijayuda/pskernel/actions/runs/39094184382) | 117577050996 | 12124486992 | cf77e661cf62d80706deb676b811ba1c7715f7346b57957e95c0f04ee3311a3e |
| M3 | [39094184399](https://github.com/dwijayuda/pskernel/actions/runs/39094184399) | 117577051106 | 12123343932 | 618741f73dcdacfbb28fd5837bdba67e54e2fdd0df0db42117d9eeb4b61df717 |
| F1 | [39094184384](https://github.com/dwijayuda/pskernel/actions/runs/39094184384) | 117577051245 | 12123407989 | 3dac8fd3c93f34ac5dcf285aea5822a17b1ad2660b217a9fe75979acc983a99c |
| F2 | [39094184401](https://github.com/dwijayuda/pskernel/actions/runs/39094184401) | 117577051107 | 12123422972 | feb52405e6947e7a9e1230ac39f1c5ffe40d5b494dfcd35f8f2e33b73f6ed5a8 |
| F3 | [39094184409](https://github.com/dwijayuda/pskernel/actions/runs/39094184409) | 117577051109 | 12124106048 | 1df45124d28bd7819a90a429b8053d77fb46660ea0a3530cb9616293c9a50757 |

Preparation39093434191/job117575381994 also passed at this SHA; see
PSCV0_M3_NATIVE_LAMBDA_5785ADA4_2026-10-18.md. Native retains its kernel,
foundation, GC/component, TypeScript, Rust, Wasmtime and performance checks.
M3 retains direct JavaScript, TypeScript, Rust, GC core and component execution.
Paired native/ProofScript control observations remain6/8. No aggregate runtime
case count is inferred from step metadata.

This qualifies the owned native lambda argument extension and existing paired
input corpus, not arbitrary Lean syntax or full v7.2 completion. The later6cdb9a6e
preparation qualifies exact mutual WF equations only; source mutual dispatch,
executable recovery and strict PSum selection remain pending. No new foundation,
self-hosting or PSKernel-Core execution was introduced. M3+B remains OPEN.
