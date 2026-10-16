# PSCV0 — accepted BEq; DecidableEq fixture correction

Updated 16 October 2026. **M3+B remains OPEN.** v7.2 alone is forward authority for .ps. Reapply attached stage prompt and docs/PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md before each coherent slice: fresh HEAD/CI/both handoffs, relevant clauses and matching pinned Lean source/tests. No old-version modes or host .lean grammar restrictions.

## Current DecidableEq candidate — qualification pending

Implementationcc49934afc3d8a83cac0f0de59325ba5c59c3cea compiled DerivingDecEq and the native compiler, but focused38908391093/job116997689233 failed building its native oracle: proof field `certificate : next = next` over a recursive child violates pinned Lean nested-inductive parameter validity. No new portable equality execution was reached. Read docs/PSCV0_M3_RECURSIVE_DECEQ_2026-10-16.md.

This correction is child of prep83cacc46c6be7d1236ecf708718505cd2f64de6a. It uses scalar-dependent `certificate : value = value` in both native and .ps versions of the same recursive chain. It retains the recursive structure, values, expected decisions, assertions and budgets. No changed equality algorithm; two source comments retain inductive validity ownership. Successful prep38908918009/job116999487600 produced exact focusedblob40a4e4496319d0361bc43693294382ac87c80615 and compilerblob686f49440c47321c6f3b93117fc24053492a77dd. The completed temporary workflow is removed.

**Fetch this correction's actual HEAD and all FIVE native/F1/F2/F3-F4/focused runs. Do not inherit accepted BEq results or call preparation/compiler compilation qualification.** Originalcandidate native38908390558/job116997687595 was last observed passing compile/native cases/assets and running source/Standard; its full result does not replace corrected-candidate qualification.

DecidableEq uses checked left-child hypotheses forall right, Decidable(child=right), inner right cases ignoring own hypotheses, independent dictionaries and existing checked equality projection/congruence/discriminator/dependent proof transport. No BEq axiom/LawfulBEq assumption/self instance/partial helper/backend-specific semantics. Existing fixture adds Nat/Bool masks, actual equality independent of custom nonreflexiveBEq, scalar-proof-bearing recursive chain, checked equal/different equations and three intended-rule refusals. Eleven Bool-to-UInt64 exports; existing Hashable/Repr/BEq observations, ABI, native negative assertion/phase and budgets remain.

Pinned study: Lean Deriving/DecEq and tests/elab/derivingDecidableEq2 at eb6cafb; local DerivingContext/Equality/Decision. Broader indexed/mutual/dependent examples are references, not implemented claims. Fix genuine errors without weakening proof/erasure/target obligations.

## Accepted BEq and preserved baselines

Accepted BEq compiler058fb67f1eec12add5adc1b3419644eb7e7363c5, tree941632044351df01189f556c05859ea92e316f7d. Same-commit native38905476639/job116988198551(all33none skipped), F1 38905476304, F2 38905476313, F3-F4-platform38905476451 and focused38905476153/job116987837831 all SUCCESS. Exact BEq receipt records nativeartifact12049320144/SHA2568984490e21626bc591ed54ab567a7f2cc24a7deb66bc1c212b4ed0e0ff1e2061 and focused12048186682/SHA256f0d21edbf82f50a5e84fd84f86e579ba7f0936d0885490fe66af68e73b432a13. Do not repeat this completed gate.

Hashable/Repr4501164e/docsad47b42f and M2+A originalprofile73 integration2a707206/acceptance280e1e4e remain accepted unchanged. v7.2 blob694115223777599ba28ee175e14bb642b7b6aa4b/SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. Runtime133af061/paired38840337837/artifact12021226623 remain9.25–10.11xfromList, smaller indexing gains, unresolved deep-list/reversal. No new speedup or general preservation theorem.

## Remaining work and contract

Finish current DecidableEq qualification/receipt, then broader nested/indexed/mutual data/deriving, elimination/motives/patterns, structural/well-founded recursion, strategy ownership and selected P0/P1. Partial logical checking preserves independent inhabitant/publicopaque/privateactualpartialmarker; every partial executable still fails shared admission across modules/targets. Never execute witness, remove marker, invent body equations/totality, add Classical/Nonempty fallback or downgrade verified requests.

GitHub/cloud Linux ONLY, no local files/checkouts/shell/build/tests/Desktop Commander. Native portable .lean, official4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; onlypropext/Quot.sound. No sorry/unchecked admission/weaker tests/larger budgets/pskernel-core/self-hosting/compiler-source migration/C5. GC internal/explicit ABI memory. Fresh expected-HEAD/non-force writes, preserve concurrent history, BOTH handoffs and exact evidence each slice. PR109 draft/open/originalbase psc0/pscv0-v7-m1-parser-ownership-v1, nevermerge. M3+B -> M4+C/D -> M5+E; no fabricated qualification/percentages.
