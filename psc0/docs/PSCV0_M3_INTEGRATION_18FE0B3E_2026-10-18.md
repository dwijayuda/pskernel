# M3 native input control integration receipt

Compiler/test SHA: **18fe0b3e3efd6f63ee0a6d1b0d851e40882fe290**.
Lean4.35.0: eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Fresh GitHub job/artifact metadata on2026-10-18 confirms all five gates completed
SUCCESS at this exact SHA. This is now the latest fully qualified checkpoint.

| Gate | Run | Job | Artifact | SHA256 |
| --- | --- | --- | --- | --- |
| Native | [39092425439](https://github.com/dwijayuda/pskernel/actions/runs/39092425439) | 117571787461 | 12123471638 | 970b2800894b611441605de0105183441134933b26e650786d7462e29e1a0447 |
| M3 | [39092425489](https://github.com/dwijayuda/pskernel/actions/runs/39092425489) | 117571787842 | 12122559367 | 0b6649b0820a6641ba51e497a3b4f018865a2d2284824ac94f8af54d41d0873f |
| F1 | [39092425401](https://github.com/dwijayuda/pskernel/actions/runs/39092425401) | 117571787347 | 12123028725 | ed8dc24787ba10465ad1861326b5c75182b7f4abeba72b826ebf103f9fb533dc |
| F2 | [39092425419](https://github.com/dwijayuda/pskernel/actions/runs/39092425419) | 117571787385 | 12123013845 | a52de3a288a1efdd9caad7878510a26d626215484969ff14889b2e511dcc9d2a |
| F3 | [39092425556](https://github.com/dwijayuda/pskernel/actions/runs/39092425556) | 117571788518 | 12123540859 | 5816149e5c814919bfae4cf3e4a4990df2587c1ef68dbaaa42450b6b062b3dfe |

Preparation39091873814/job117570152485 passed at the same SHA; see
PSCV0_M3_NATIVE_CONTROL_18FE0B3E_2026-10-18.md.
The Native job retained all kernel, selected foundation, runtime, component,
native Wasmtime and cost gates. The M3 job retained source/proof checks,
JavaScript/TypeScript execution, actual Rust execution, GC core and component
observations. Artifact digests identify retained evidence; no aggregate runtime
observation count is claimed from job-step metadata.

The paired compiler-input fixture includes m3parity, m3data and m3control through
both native .lean and ProofScript .ps grammars, sharing exact checked Core and
generated equations. Local where/WF, native layout and semicolon do, expected
effects, pattern lets and if-let, early returns and else-if are included.
This extends qualifiedb95c6293; both mixed-module directions and assurance
refusals remain. Correct P1 Rust producer/run ordering remains included.

This does not close M3+B. Public source mutual WF, remaining native adapter
coverage and the full six-exit reconciliation remain open. The separate source
component body candidate on preparation is not qualified by these main runs.
No PSKernel-Core, self-hosting, new assumption or budget expansion was used.
