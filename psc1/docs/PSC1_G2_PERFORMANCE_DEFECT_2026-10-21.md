# Resumed G2 performance defect

Status: OPEN; manual qualification resumed after frozen Practical Core v1.
Latest actual manual run 39864113546/job 120121869892 at source 573bf485 passes
the frozen ten-case G1 corpus; G2 times out at 240197 ms before admission or
publication. G3 is not run. Exact replay 240346 ms, artifact 12462609800 and
read-only inspection 39865901653 preserve all source/request/profile identities.
See PSC1_G2_STABLE_CAPTURE_FAILURE_QUALIFICATION_2026-10-23.json.

Diagnostic copy only: run 39866505167 enters 29/86 modules by 240 seconds,
last entering CheckedAdmissions declaration index 59 with observed RSS
2381944 KiB at that point. Logging affects timing; entries are not completion.
No diagnostic response is admitted, adopted or published.

Final compiler source 7732e978 narrows capture elision to initialized locals and
literals, preserving nonlocal read timing. All-input visitor/source proofs,
old and new runtime/order/divergence/refusal tests, all-seven Practical Core,
complete closures, G1, minimum-Python/package and aggregate pass in fresh run
39867567126 (37/37 criteria; all 47 full-job steps). This is normal compiler
qualification, not G2/G3. G2 has not been executed after that final guard change.

Next: address measured general frontend/elaboration throughput and lifetime;
verify normal large-source improvement before another expensive manual attempt.
No heap/stack/deadline/fuel/checker/strict-IR/manifest boundary is raised.
All earlier retries and their dated receipts remain preserved.

## Preserved earlier evidence

Original actual G2 attempt at 3b189f589b0a4ad06eb1bcc666014220e72268df:
run39545154962/job119041551702 aborted before publication (SIGABRT131880ms).
Exact replay39546176974/job119044756251 confirmed V8 heap exhaustion at125656ms.
See PSC1_G2_FIRST_ATTEMPT_2026-10-21.json and PSC1_G2_CPU_FAILURE_2026-10-21.json.
89848 samples identified wrapped returned-state closures in the JSON scanner
(WeakCollectionSet26.1%, WeakMapLookupHashIndex10.1%).

The general typed worker fusion fix and its capture/order/strictness/refusal
regressions remain. See PSC1_TYPED_WORKER_FUSION_RUNTIME_2026-10-21.json.
The regenerated G1 (84 modules) passes all8 corpus cases; SHA256
5d30b5552896fbe4f90eadc7cc71564a61bec7f586a6ef4f38deedfeb8456f6f.
Run39551686967 artifact12324336359 retains its exact source/graphs/service/tests.
It times out at240s on G2 rather than showing the prior heap-abort diagnostic.
That observation does not establish a memory bound or resolve the defect.

Latest exact replay: run39552904187/job119065906904, source head
1d5c45e01f9016365a440c8b8c05916249cfaa4c, tested merge
26c1bbebed7ed5f553a35f280ca26b2000fa5d2a. SIGTERM/ETIMEDOUT240278ms,
no response, no admission/publication.203183 ticks; leading named JS functions
are psParseListLength and psLeanNomatchConsumedStop; JSON scanner0.1%.
Retained sampled log artifact12324637615, zip SHA256
6fa6be11127115f37738bf0da04af94cfcca6057d24e72ae40cb8e33bc15e9c4.
These are samples, not a complete allocation/cost proof.

Current-head actual execution39552904167/job119065907152 repeats all8 G1
cases then G2 times out240177ms before publication. Scoped39552904242 and
all3 whole-closure jobs39552904236 pass. Independent checking and strict IR
remain mandatory. Do not enlarge stack/heap/deadlines or substitute native
compiler semantics. Resume only deliberately with manual qualification after
feature freeze, or a measured normal-compilation regression.
