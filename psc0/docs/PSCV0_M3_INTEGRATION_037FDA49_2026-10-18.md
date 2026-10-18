# M3 integration receipt — 037fda49

Exact compiler/test commit:037fda4914ba30b5b8f2074e82ffbf9b0efeef0c.
All five exact-SHA GitHub jobs completed SUCCESS; their artifact metadata
independently identifies the same head SHA. PR109 remains draft/open/unmerged.
This is integrated-slice acceptance, not completion of all M3+B exits.

| Gate | Run | Job | Artifact | SHA256 |
|---|---:|---:|---:|---|
| Native | 39084512384 | 117548170383 | 12120536368 | 8c54252978520afa4313b411f000c6814c19c7b65e1782b700fcd1ded85b56b4 |
| Focused M3 | 39084512415 | 117548170536 | 12120496696 | 0d1f591f3e770e0d511947b7cf944410b92760d431a75887b1e6829bb180755a |
| F1 | 39084512357 | 117548170321 | 12119988875 | 00aaab4b71456063f595af08d474fae497cb69400ab0010d0979f6385a0759a9 |
| F2 | 39084512390 | 117548170448 | 12120660462 | 722859d524a7978e04074455d1b8f60c997b9d72ea93350c7fe04100aecd3970 |
| F3 | 39084512422 | 117548170367 | 12120162831 | 22d8b7474f3188a484c01a880594cceeef7531303d6635c753afc4ce584d91c9 |

The required JS, compiled TS, Rust, V8 GC and Wasmtime steps succeeded.
Whole focused-job log retrieval twice failed with a transport/tool error;
no newly measured aggregate runtime count is asserted. Artifact digests are
GitHub metadata, not an independent rehash or proof of compiler correctness.

In addition to the accepted abe1adc2 scope, this integrates the common finite
fixed-parameter graph, typed multi-callee source callbacks, fixed-major Eq/HEq
context refinement and impossible cases, complete unary dependent packing and
native nullary-predicate K computation. The unchanged omitted-result
riFixedIndexEq rfl requirement passes. Unequal and unresolved K indices retain
intended refusal. No new assumption or weakened assertion is introduced.

Preparation037 run39083926961/job117546418053 succeeded before main promotion.
Later3386891 component-functional construction andade87651 fixed scopes/shared
Where source preparation each passed their complete preparation, but are not
included in this main acceptance. Retained-call candidatea5287a1 remains separate.
Source mutual WF and its whole-functional runtime adaptation remain open.

Standard3752 declarations,44 classes,371 ordinary instances,13 defaults;
FNV7907908279927868945;
snapshot SHA855c1945851fc7983481cb271120ab12ceb78537ce6faef61e0b36f87ff99eec;
surface SHA24e975d8e8d8b61df05bcc78a488a7e9f7465f99972577110876f5f4e39d08d5.
Approved assumptions exactly propext, Quot.sound, Classical.choice.
Standalone PSum remains unselected. Official Lean4.35.0 is unchanged.

Both .ps and .lean compiler inputs must follow v7.2, as the user clarified.
This existing .ps-oriented integration does not establish complete .lean input
parity; read PSCV0_V72_INPUT_LANGUAGE_CONTRACT_2026-10-18.md. Native Lean oracle
code is not evidence that PSC0's .lean frontend accepts that source feature.
