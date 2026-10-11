# First module correspondence: exact dependency audit

## Measured baseline, not an assumed axiom-free environment

At source `d510124ad9cbbaefab1dcabb51e2049352a5b6d4`, native Lean4.34 run `38112266804`, job `114390104605`, inspected the unchanged original declarations. `PsTranslationError` has no axioms. Both original parsers, both original module printers and all four original translation APIs have the exact reported axiom closure **`[propext]`**. The four readable-source correspondence equations closed, but the initially specified empty-closure test refused them for that same dependency.

That run remains failed. Artifact `11691727987` retains the observation (archive SHA-256 `6903cc573c49bd79419d775b3b8ad59cc546dc5d5554190f296a7c7e43516781`). The dependency is not evidence of a newly introduced axiom, and changing tactics from `unfold` to `delta` could not remove dependencies in the named original functions.

The earlier plan incorrectly assumed a theorem about the concrete compiler APIs would have the same empty dependency closure as the small standalone Except/Nat fixture. This is explicitly corrected here; no production proof-acceptance policy, kernel rule or source baseline is changed.

## Revised evidence obligations

1. Check both actual generated readable/lowered projections against the four original APIs for **every String input**, not just examples. Preserve the existing equations and source-function bytes.
2. Recompute the baseline under each pinned Lean version. Require exactly the observed `[propext]` dependency closure for the original parsers/printers/APIs; unexpected assumptions still fail.
3. Require each migrated API, each copied predecessor API and each concrete correspondence theorem to have **exactly that baseline closure**, with no added assumptions. A reflexivity theorem over the old API is audited separately to expose dependencies inherited from named functions.
4. Prove the generic error-map/bind and error-map/match transformations with abstract parser/printer results, using the actual generated `psTranslationMapError`. These two algebraic theorems and the helper must have **no axioms**.
5. Preserve the existing standalone do fixture's empty-axiom requirement, all38 generated bridge assertions, source identity checks and generated/runtime correspondence tests.

The source reference requires audited assumptions and faithful Lean-grounded terms, not removal of all assumptions from pre-existing native parser/library implementations. This narrower evidence claim is **no new assumptions from this refactoring**, not that the original compiler is axiom-free. It does not certify JavaScript code generation or the entire kernel.

## Cost discipline

All failed attempts so far stopped in cheap native preflight; no changed20-module bridge was generated. Source/semantic gates remain before retained-compiler preparation. Only after this audit succeeds may the two-stage shared-prefix candidate build run. No compiler/kernel fixed-point or public source-root change is implied.
