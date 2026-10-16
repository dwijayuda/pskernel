# PSCV0 — recursive BEq accepted; DecidableEq candidate

Updated 16 October 2026. **M3+B remains OPEN.** v7.2 alone is the forward .ps reference. Reapply the attached stage prompt and docs/PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md before every coherent slice: fresh HEAD/CI/both handoffs, relevant v7.2 clauses and pinned Lean source/tests. No legacy modes or native .lean source restrictions.

## Accepted direct-recursive BEq

Qualified compiler/test **058fb67f1eec12add5adc1b3419644eb7e7363c5**, tree941632044351df01189f556c05859ea92e316f7d. Allfive same-commit workflows passed: native38905476639/job116988198551 (all33 reported steps, none skipped), F1 38905476304, F2 38905476313, F3/F4/platform38905476451, focused38905476153/job116987837831. Source/Standard/modules/GC/TS/Rust/native Wasmtime/post-return/measurement/publication passed. Full receipt: docs/PSCV0_M3_RECURSIVE_BEQ_QUALIFICATION_2026-10-16.md.

Nativeartifact12049320144,6704499bytes,SHA2568984490e21626bc591ed54ab567a7f2cc24a7deb66bc1c212b4ed0e0ff1e2061; focusedartifact12048186682,238569bytes,SHA256f0d21edbf82f50a5e84fd84f86e579ba7f0936d0885490fe66af68e73b432a13. Exact metadata identifies058f. Do not attach these results to the next compiler change.

BEq uses checked left-child comparison hypotheses and right case analysis, independent field dictionaries and no assumed reflexivity/pointer identity. Nat/Bool masks, non-reflexive field dictionary, checked defining law and all targets passed. Two obsolete direct-recursive negatives were migrated to unsupported nested fields with original assertions/phases/messages/budgets intact. Hashable/Repr and earlier partial logical checking remain preserved.

## Current DecidableEq candidate — exact qualification pending

This commit is the child of preparation-only4083dd05427acfc10a5c5a5d7201be21cedc5b84. Read docs/PSCV0_M3_RECURSIVE_DECEQ_2026-10-16.md. DerivingDecEq now explicitly plans erased/independent/recursive decisions and consumes actual checked left hypotheses of type forall right, Decidable (child = right). Right cases ignore their own hypotheses. Existing equality projection/congruence, constructor discrimination and positive dependent proof transport remain; no BEq-to-equality axiom, LawfulBEq assumption, partial helper or backend-specific code.

Focused fixture reuses the current tree and adds actual Nat/Bool decisions, equality independent of the deliberately non-reflexive BEq, a recursive chain with a proof field about its child, equal/different rfl equations and three exact refusal rules. Eleven Bool-to-UInt64 exports retain internal recursive data and the existing target ABI. All old Hashable/Repr/BEq observations/refusals and benchmark counts/checksums/budgets remain.

Successful prep38907346583/job116994153657 verified nativefixtureblobd4cee482039aa24575b476292c42cc30e28f09ff and focusedfixtureblobbcdd812511353892c43a3946230db446a5d7d3f6. Native negative changes exactly one direct recursive field to unsupported List Bad. .ps decisions use qualified Decidable.decide(self := decEq(...)); native oracle keeps native syntax. The completed temporary preparation workflow is removed. **Fetch this candidate's actual SHA and allfive native/F1/F2/F3-F4/focused results; never inherit BEq green.**

Pinned study completed: Lean Deriving/DecEq.lean and tests/elab/derivingDecidableEq2.lean at4.35.0 eb6cafb; local DerivingDecEq, DerivingContext, Equality and Decision. Broader upstream indexed/mutual examples are reference evidence, not capabilities claimed here.

## Remaining M3 and trust boundaries

Complete DecidableEq qualification before acceptance. Broader nested/indexed/mutual data/deriving, elimination/motives/pattern matrices, structural/well-founded total recursion, recursion-strategy ownership and selected P0/P1 remain open. Partial logical checking independently constructs an inhabitant, public opaque self and typed private partial marker retained in the prepared graph. All partial executable admission still fails across modules/targets. Never execute the witness, erase the marker, invent body equations/totality, introduce Classical/Nonempty fallback or downgrade a verified request.

v7.2 blob694115223777599ba28ee175e14bb642b7b6aa4b/SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. M2+A originalprofile73 integration2a707206/acceptance280e1e4e and Repr4501164e/docsad47b42f remain immutable accepted evidence. Runtime133af061/paired38840337837/artifact12021226623 remain9.25–10.11xfromList, smaller head/array gains, unresolved deep-list/reversal; these deriving slices claim no speedup or global preservation theorem.

GitHub/cloud Linux ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable .lean; official4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; onlypropext/Quot.sound. No sorry/unchecked admission/weaker tests/larger budgets/pskernel-core/self-hosting/compiler-source migration/immediate C5. GC internal/explicit ABI memory. Fresh expected-HEAD/non-force writes, preserve concurrent histories, BOTH handoffs and evidence each slice. PR109 draft/open/originalbase psc0/pscv0-v7-m1-parser-ownership-v1, nevermerge. Continue M3+B -> M4+C/D -> M5+E without fabricated results or percentages.
