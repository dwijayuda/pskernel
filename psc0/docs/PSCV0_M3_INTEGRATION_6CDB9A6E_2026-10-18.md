# M3 exact component equation integration receipt

Compiler/test SHA: **6cdb9a6ee36b3262b366d80f36c238b50fd9676d**.
Lean4.35.0: eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Fresh GitHub run/job/artifact metadata on2026-10-18 confirms all five gates
completed SUCCESS at this exact SHA.

| Gate | Run | Job | Artifact | SHA256 |
| --- | --- | --- | --- | --- |
| Native | [39095176453](https://github.com/dwijayuda/pskernel/actions/runs/39095176453) | 117580011384 | 12124433843 | 2a61ddb2e4a88940a1fa76a4e8eefe53ddb0b73e7ac6384f6e3e0520065aee19 |
| M3 | [39095176451](https://github.com/dwijayuda/pskernel/actions/runs/39095176451) | 117580011365 | 12124197592 | 26ddcd1954b777f31f92f62bb72c5af8061d3052d19c1b6dace49dbec829cce8 |
| F1 | [39095176460](https://github.com/dwijayuda/pskernel/actions/runs/39095176460) | 117580011395 | 12123839551 | 9890aa066fd9aed8e269b9309fe3ec17a0c068a06d4cba3b28fd9ae258603dbd |
| F2 | [39095176458](https://github.com/dwijayuda/pskernel/actions/runs/39095176458) | 117580011381 | 12123988942 | dbc357e87ade7f6b47039da9a906d33059320f14d424994df80008e442f8a016 |
| F3 | [39095176455](https://github.com/dwijayuda/pskernel/actions/runs/39095176455) | 117580011437 | 12123774792 | 8453b64fdb50315688b8a5fc5fbf825c25dc96ed33d7799c92aab2b4210ea245 |

Preparation39093766354/job117576869290 passed the new internal three-member
source construction and exact equation kernel checks at this SHA. See
PSCV0_M3_EXACT_COMPONENT_6CDB9A6E_2026-10-18.md. Integration retains the full
Native/M3/F1/F2/F3 source, logical and runtime gates; it does not turn an internal
construction fixture into executable mutual WF source support.

Later runtime ownership candidates8d1132c7/3e226c69 are not covered by this receipt.
The first had a fixture-only missing BEq instance; the second built and passed
all retained preparation checks except its new runtime packing check. That check
exposed overlapping original/common header IDs, now corrected on preparation by
allocating disjoint fresh IDs. Candidate9b5cc7c7 is pending qualification.
Selected PSum, source activation and backend mutual WF observations remain pending.
M3+B remains OPEN. Foundation selection and approved assumptions are unchanged.
