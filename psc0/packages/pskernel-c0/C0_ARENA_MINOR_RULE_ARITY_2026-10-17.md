# PSKernel-C0 — Lean 4.35 independent generated-recursor minor application arity

**Date:** 2026-10-17 · **Status:** independently qualified in merged [PR #116](https://github.com/dwijayuda/pskernel/pull/116), commit `b17ce7f12905ec36d353a4f3d2fd1cc66f3150f8`.

## Confirmed specific defect class

In the immutable September 2026 Arena `bugs/rec-missing-ih.ndjson` export, the recorded `Native64TwoHashOwner.step` minor premise has a raw Π-type with **4** arguments, including one recursively generated induction hypothesis. Its recorded reduction RHS applies that minor to **3** arguments. C0 previously declined the source because its ordinary inductive admission did not recognize a recursive occurrence hidden behind a stuck K-like conversion, and thus never checked the inconsistency of the stored recursor rule.

This is a defect in that **historical generated rule**, not evidence that current official Lean 4.35 generates it. A direct archive analysis of the recursor `Native64TwoHashOwner.rec` (source expression handle `3972`, rule RHS handle `3981`) independently witnesses the 4-vs-3 mismatch. Its historical root involved nontransitive algorithmic conversion interacting with a hash-dependent union-find cache; see upstream [Arena reproducer](https://github.com/leanprover/lean-kernel-arena/blob/5d7ca987618f1136aaa296057b50a2c10c4ce77a/tests/bugs/rec-missing-ih.yaml).

## Source-backed necessary invariant

The actual pinned official Lean 4.35 `src/kernel/inductive.cpp::mk_rec_rules` builds each minor application by applying **both** lists `b_u` (constructor fields) and `v` (generated recursive induction hypotheses). Its corresponding minor premise type is constructed by `mk_pi(b_u, mk_pi(v, C_app))`. Therefore the minor type's raw Π arity **must equal** the complete number of arguments in a canonical generated rule RHS. The RHS is wrapped in lambdas over `params`, `Cs` (motives), `minors`, and `b_u`; the particular minor head is a deterministically indexed de Bruijn variable.

`test/C0OfficialNdjsonReplay.lean` introduces three conservative, syntax-only helpers: `c0ExportSkipMinorForalls`, `c0ExportSkipRuleLambdas` and `c0ExportRecursorRuleMinorArityMismatch`. The rule applies **only** when the export is a single ordinary, non-nested inductive group with one motive, exact exported constructor/field/rule alignment and the expected literal minor de Bruijn head. It strips a precisely calculated number of raw outer Π/Lambda binders, without WHNF, delta, proof irrelevance, fuel changes, or trusting hashes. A disparity is independently impossible in valid official generated source.

All unrecognized cases remain on the ordinary C0 fully source-checked admission/decline path. This is **only a narrow semantic rejection witness**, not a new accepting rule or complete verification of nested recursors.

## Exact pinned qualification

The full four-shard historical-body test-only Lean-4.35 differential [39013322401](https://github.com/dwijayuda/pskernel/actions/runs/39013322401) completed successfully on the exact final PR head `1aea9b3c694a3126955dfab504e93c20cd01daf1`. It verified **193/193 immutable declaration-body byte suffixes**, **177/193 genuine official/C0 matching verdicts**, including `rec-missing-ih` **rejected/rejected**, zero observed wrong verdicts, and exactly **16** distinct still-unqualified resource/reference cases. Source-necessary negative policy was also verified with native Arena adversarial [39013322409](https://github.com/dwijayuda/pskernel/actions/runs/39013322409), while focused negative diagnostics [39013322418](https://github.com/dwijayuda/pskernel/actions/runs/39013322418) now accept an *empty* remaining semantic-negative ledger (the 16 unrelated performance cases are never called checked).

## Still unresolved

The C0 ordinary admission subsystem still does **not** support every valid nested recursive occurrence; this change does not supply it. Full genuine native Lean 4.35 source re-export of all 193 historical cases, trusted source-checker and recursor formal soundness, the 16 resource/performance tests, complete Init/Std/Mathlib, and future PSC0 v7.2 selfhosting remain distinct open obligations. A bounded conformance gate is not a complete correctness or consistency theorem.
