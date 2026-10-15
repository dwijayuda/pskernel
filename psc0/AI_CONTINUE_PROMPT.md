# Continue PSC0 / PSCV0 v7 M2 + Phase A

## F3 logical dependency gate prepared — 15 October 2026

Research branch `psc0/pscv0-v7-f3-conversions-research` was based on F2 candidate `d70fe6c562d7643f9b42a13d72f718ae146b1d7c` and now incorporates its class-key audit and corrected metadata pins through `cbdb554fa9209361cd72217432fb8435d1a15022` while F2 full runtime qualification continues independently. This branch adds only native authoring/export and a read-only cloud replay workflow; it does not select any F3 declaration or enable new syntax/runtime operations.

Pinned Lean 4.35.0 sources studied: Init/Data/OfScientific{,/Basic}; Float/{Float,Float32}, Model/{Float,Float32}, Model/Unpacked/Operations/{OfNat,ToNat,OfScientific}; SInt/Float{,32}; Lean/Parser/Basic.decimalNumberFn and Lean/Elab/BuiltinTerm.elabScientificLit. Relevant tests: elab/float_conversions.lean, elab_fail/scientific.lean, pkg/ofScientific/{Main.lean,test-data/README.md,doubleround.txt}. Existing scalar-completion design remains the roadmap.

The coherent logical candidate has 42 roots: both widths' ofScientific/ofNat/ofInt and conversions to eight fixed signed/unsigned word types, and conversions from those words plus Nat/Int into both floats. It uses the current selected F2 declarations as its dependency cut, original native definitions/proofs, shared source serialization and official kernel replay. Platform words and opaque Float/Float32 cross-width conversions remain separate contracts. No new assumptions, theorem replacements, computational axioms or budgets.

Semantic design: scientific lexing retains an exact mantissa, signed decimal exponent and source span; expected type and the shared OfScientific synthetic constraint determine interpretation. Float's default priority is 501. Native fast paths require exactly representable operands; model fallback bounds extreme exponents before powers of ten and rounds once to the selected width. Numeric integer-to-float conversion uses nearest-even; float-to-fixed-integer truncates toward zero, clamps at bounds and maps NaN to zero. Never convert an arbitrary UInt64/Int64 to binary64 before rounding to binary32: that can double-round. Reuse the shared typed conversion boundary across backends, canonical NaN observation and existing ABI plan.

Next: inspect this gate's proof/closure result, assess any dependency-family mismatches, finish F2 exact main qualification, then implement F3 coherently. No F3 acceptance/runtime claim. Keep both handoffs current.

F3 first run38730356496 built the exporter but stopped on a missing CLI success return in the adjacent F2 branch. This return is restored; no logical candidate result was produced by that run.


## F2 instance-index invariant reviewed — 15 October 2026

Research `49a38a118b6ed2b0fa5955bac4b8d9399c4b6466` fixes the Float equality registration: DecidableEq is a reducible Pi alias, so its result-class key is Decidable. Pinned Lean Meta/Instances.{mkInstanceKey,checkNonClassInstance} and SynthInstance were studied. A shared Standard manifest audit now reduces every registered instance telescope and checks its explicit key against the actual registered result class, preventing this entire metadata failure family. The unchanged native logical asset still passes independent F2 replay [38730889909](https://github.com/dwijayuda/pskernel/actions/runs/38730889909), and F1 replay [38730889978](https://github.com/dwijayuda/pskernel/actions/runs/38730889978) passes.

[Native38730889997](https://github.com/dwijayuda/pskernel/actions/runs/38730889997) built successfully, passed the new class-key audit and all 88 native Float oracle observations, then independently reported the metadata-only digest change. Reviewed current pins: `fnv1a64:11971833863653521941`; declaration `sha256:8a3fbf1e59845739e6926b7e52add0059a33054cf74625f64923d4f360c43c7e`; surface `sha256:ff2b3e2ed6e043cb11a332d5175ff1116f8e4c1a4c13a91baca71bb53a917fc3`. Standard remains 3,122 declarations. The older pin checkpoint below is superseded. Full runtime/backend qualification is still required.

F3 dependency research proceeds separately at `cafabfdadf0453cb9e8e7355bb8a952bc39a644a`, [38730356496](https://github.com/dwijayuda/pskernel/actions/runs/38730356496), with 42 scientific/fixed-word conversion roots and no F3 selection. Its gate is based on F2's declaration roster; after F2 qualification synchronize metadata before F3 integration. Main F1 remains unchanged and qualified. No new assumptions, pskernel-core, self-hosting or C5.


## Working contract

GitHub canonical: dwijayuda/pskernel. Main development branch `psc0/pscv0-v7-native-lean-v1`; draft PR109 keeps its original base and must not be merged. Inspect live branch HEAD and exact-commit CI before writes; preserve history with expected-HEAD, non-force updates. Use GitHub integration and cloud Linux CI only, no local checkout/files/builds or Desktop Commander. Keep research workflows contents: read.

Pinned Lean 4.35.0: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study corresponding official source and tests before every substantial feature. Native .lean; no pskernel-core, bootstrap/self-hosting, compiler-source .ps migration or C5. Application .ps fixtures are allowed. Only approved assumptions propext and Quot.sound. Original upstream Float correspondence imports Classical.choice and remains outside the selected portable closure.

Read the latest AI_WORK_STATE.md checkpoint, docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md and docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md; canonical v7 specifications govern completion. Continue M2+A -> M3+B -> M4+C/D -> M5/E. M1 is complete; M2+A is not.

## Immediate continuation

1. Inspect live research HEAD and current native/F1/F2 workflow results. The former Wasm fallback became redundant after exhaustive F2 dispatch; it was removed. The primitive audit now includes Model methods and Eq decision helpers. Do not redo qualified F1.
2. Finish coherent F2 qualification after the exact registry pins above. Fix root causes without weakening checks. Integrate the reviewed tree to fresh main only after all required lanes pass, restore workflow main-branch triggers, then qualify the exact main commit. Update BOTH handoff files, roadmap and PR evidence.
3. Continue F3 scientific syntax/defaults and scalar conversions, F4 complete Float qualification, USize/ISize explicit target profiles and remaining authoritative selected Standard/manifest obligations. Study the whole affected subsystem first.
4. F3 research at cafabfdadf0453cb9e8e7355bb8a952bc39a644a (run38730356496) covers pinned Parser/Basic.decimalNumberFn, Elab/BuiltinTerm.elabScientificLit, Init/Data/OfScientific{,/Basic}, Float/Model/Unpacked/Operations/OfScientific and tests/pkg/ofScientific (including doubleround.txt). Keep exact Nat mantissa, exponent sign and Nat exponent until the expected type/OfScientific instance is selected. Default Float priority is 501. Reuse exact rounding and exponent bounds; do not parse via binary64 before choosing Float32. Only the isolated F3 logical exporter gate is staged; syntax/runtime remain pending.

## Verification and invariants

The F2 asset is selected behind frozen psSelfHostProdPreFloatOperationsPreludeEnvironment and psStandardFloatOperationsBoundary; proof dependencies stay out of runtime support. IEEE BEq identifies signed zeros and rejects NaN equality; logical DecidableEq compares canonical bits, distinguishes signed zero and identifies NaNs. All backends share typed IR; Wasm uses GC internally, with linear memory only at explicit Canonical ABI boundaries.

Use existing native build targets pscv0_native, pscv0_native_checks, pscv0_wasm_checks and pscv0_m1_performance. Follow current workflows for pinned commands/tools. Authoring must prepend the local Ps namespace root to Lake's LEAN_PATH. The awaited pooled-task helper resets the real C++ kernel heartbeat counter per independent authoring declaration; source requests keep cumulative 2,000,000-heartbeat/20,000-depth limits.

No new assumptions, proof placeholders, unchecked casts, fallback admission or increased budgets. Keep checked logical admission, runtime conformance and formal preservation claims separate. Prefer complete coherent features and compact differential validation, then the existing full backend suite. Update both handoffs each milestone slice.
