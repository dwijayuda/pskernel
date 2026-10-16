# PSCV0 — DecidableEq recursor-entry correction pending qualification

Updated 16 October 2026. **M3+B remains OPEN.** v7.2 only for forward .ps development; no legacy modes or native .lean grammar restrictions. Reapply attached stage prompt and docs/PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md before each coherent slice; fresh HEAD/CI/both handoffs/relevant clauses/pinned sources.

## Current correction and required evidence

This child of2407ff54e8dc61b471f7e395e95c0b91f9c71eed fixes a shared RecursorLift entry-boundary mismatch. The corrected DecidableEq native oracle and full source passed official kernel checking, then focused38909571471/job117001701333 failed at `runtime use of erased local: 5 (in M3HashTree.instDecidableEq)` during erasure. Read docs/PSCV0_M3_RECURSOR_ENTRY_BOUNDARY_2026-10-16.md.

Preparation previously extended root entry arguments through reduced result aliases; erasure owns only the raw aligned forall/lambda prefix. RecursorLift now preserves root eligibility only for a raw forall. Hidden function results are ordinary returned closures and use existing checked capture-preserving helper lifting. No class-name special case, changed call arity, erasure refusal weakening, new budget or axiom. Existing helper beta-restoration/alpha-equality checks and official kernel validation remain.

**Fetch this correction's actual SHA and all FIVE native/F1/F2/F3-F4/focused results.** No inherited BEq green. Recursive DecidableEq is still not accepted. Current focused fixture includes independent native-oracle Nat/Bool decisions, custom BEq disagreement, a recursive chain with scalar-dependent proof field, checked equal/different equations and intended-rule refusals. Eleven Bool-to-UInt64 exports keep recursive data internal. Tests/assertions/pins/budgets unchanged by this shared correction.

Earliercc499 compiled compiler code but failed native oracle's invalid recursive-child proof field. Corrected2407 uses value=value, a valid scalar-dependent proof in the same recursive chain, with identical observed values. Exact fixtureblob40a4e4496319d0361bc43693294382ac87c80615 and DerivingDecEqblob686f49440c47321c6f3b93117fc24053492a77dd were SHA-checked in prep38908918009/job116999487600. That temporary workflow was removed. The current observed failure is erasure, not that historical invalid fixture.

Studied pinned Lean Deriving/DecEq, tests/elab/derivingDecidableEq2, and LCNF/ToLCNF function-valued cases; local DerivingContext/Equality/Decision, Meta.Recursor, RecursorLift and Erasure Basic/Definition/Recursion/Expr. Preserve actual checked child decisions, projection/congruence/discriminator and dependent proof transport; no BEq axiom/LawfulBEq/self-instance/partial helper.

## Accepted baselines

BEq accepted at058fb67f1eec12add5adc1b3419644eb7e7363c5, native38905476639(all33none skipped), F1 38905476304, F2 38905476313, F3-F4-platform38905476451, focused38905476153 all SUCCESS. Exact BEq receipt records nativeartifact12049320144 and focused12048186682 with digests. Hashable/Repr4501164e/docsad47b42f and M2 originalprofile73 integration2a707206/acceptance280e1e4e remain accepted unchanged. Never repeat or relabel them fullv7.2.

v7.2blob694115223777599ba28ee175e14bb642b7b6aa4b/SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. Runtime133af061/paired38840337837/artifact12021226623 retain9.25–10.11xfromList, smaller indexing gains and unresolved deep-list/reversal. No new speedup/global preservation claim.

## Remaining work and contract

Finish exact DecidableEq qualification/receipts, then broader nested/indexed/mutual data/deriving, motives/pattern matrices, structural/well-founded recursion, strategy ownership/P0/P1. Partial independentinhabitant/publicopaque/privateactualbodymarker stays in prepared graph; all partial executable admission still fails. Never execute witness/dropmarker/invent equations/totality/addClassical/Nonempty/downgradeverified.

GitHub/cloud Linux ONLY; no local files/checkouts/shell/build/tests/DesktopCommander. Nativeportable.lean; official4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; onlypropext/Quot.sound. No pskernel-core/selfhosting/compiler-source migration/C5/sorry/unchecked admission/weaker gates/larger budgets. GCinternal/explicitABI memory. Fresh expectedHEAD/nonforcewrites, preservehistories, BOTHhandoffs eachslice. PR109draft/open/originalbase psc0/pscv0-v7-m1-parser-ownership-v1, nevermerge. M3+B -> M4+C/D -> M5+E; no fabricated qualification/percentages.
