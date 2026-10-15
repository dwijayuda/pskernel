# Continue PSC0 / PSCV0 v7 M2 + Phase A

## F2 executable family: research qualified, main integration — 15 October 2026

[Native38734252078](https://github.com/dwijayuda/pskernel/actions/runs/38734252078) passed completely at `9ffdd799a05ee256368266831bbaec74bee18ed2`: **843 shared runtime observations** across readable JS/TS/Rust and GC Wasm/core/component, native oracles, official-kernel source admission, exact asset regeneration, ABI/WIT/WAT checks, multi-module programs, repeated Wasmtime calls and unchanged performance gates. Independent [F1 replay38733051176](https://github.com/dwijayuda/pskernel/actions/runs/38733051176) and [F2 replay38733051136](https://github.com/dwijayuda/pskernel/actions/runs/38733051136) pass at `c3081a0e0c102ba8f8fad16940301af893dcfe5b`; the descendant only corrects six constant observations to the established `args: null` schema and updates handoffs. No expected values changed.

This integration selects Float/Float32 add/sub/mul/div, neg/abs, IEEE equality/order, NaN/infinity classification and checked logical equality decisions, including generic, partial and Model calls. The original Lean logical family contains 1,229 declarations /24 recursor rules /91,024 shared nodes /11,179,796 UTF-8 bytes, SHA-256 `ad82f59b48460a3b306312c3e9d72537e8b48201e432271a3be0424a576909df`. Only approved propext/Quot.sound are assumed; no new axioms or proof replacements. Proof dependencies stay out of runtime support.

The typed IR adds float unary/test operations; ECMA enforces binary32 rounding per operation, Rust uses safe scalar operations, and Wasm uses native arithmetic plus memory-free classification helpers. Canonical NaN observation and signed-zero behavior follow F1. The shared constant/application erasure path now handles nullary primitives and preserves partial application. Its design follows pinned Lean `Lean/Compiler/LCNF/ToLCNF.lean` (visitCore/visitAppCore/etaIfUnderApplied). The instance registry now validates each key against the reduced result class, following `Lean/Meta/Instances.lean`; DecidableEq registers under Decidable.

Reviewed selected Standard: **3,122 declarations /25 classes /250 instances**; FNV `11971833863653521941`, declaration SHA-256 `8a3fbf1e59845739e6926b7e52add0059a33054cf74625f64923d4f360c43c7e`, surface SHA-256 `ff2b3e2ed6e043cb11a332d5175ff1116f8e4c1a4c13a91baca71bb53a917fc3`. All guards remain strict. Native prelude initialization measured 7.608s separately; performance gates passing does not establish optimal performance or a backend preservation theorem.

**Exact-main qualification is pending on this integration commit.** F1 remains previously main-qualified at `262c5819c499256fcd2093746deae4ef3aa2012b`. Do not call all M2+A complete. Next: finish exact-main F2 checks; qualify/integrate the universe-polymorphic Array prerequisite from `psc0/pscv0-v7-f3-conversions-research`; then scientific literals, shared priority-ordered default instances and numeric conversions (F3), display (F4), and remaining M2+A exits. The F3 logical candidate already passes [38734094036](https://github.com/dwijayuda/pskernel/actions/runs/38734094036) but remains unselected. No pskernel-core, self-hosting, compiler-source translation or C5 work.


## F2 logical family checked; runtime pending — 15 October 2026

Research commit `d4528f27e45917b5d63edd84b0feb15d5e812bf6` on `psc0/pscv0-v7-f2-operations-research` passed [logical closure replay 38722766782](https://github.com/dwijayuda/pskernel/actions/runs/38722766782). All 28 Float/Float32 arithmetic/comparison/classification roots plus the two existing constructive theorem roots passed: **1,169 new declarations, 24 recursor rules, 89,183 shared source nodes, 10,941,261 source bytes**. SHA-256 `711ef5ecd08df8442c986b6df2cc9135ea79b9842ec0100cf517b289488b9acf`. No new axioms, quotient primitives or definition replacements; only the approved propext/Quot.sound foundation.

This candidate is not selected Standard and F2 runtime operations remain refused. Next: freeze the pre-F2 boundary, select the checked logical family and source class metadata, keep proof dependencies out of runtime support, implement shared typed arithmetic/unary/classification/equality lowering across all active backends, then qualify one compact native differential corpus. F1 remains main-qualified at 262c5819c499256fcd2093746deae4ef3aa2012b (native38721711653, Float38721711679, 755 shared observations). M2+A is incomplete.


## F2 emission passed; observation metadata corrected — 15 October 2026

At `c3081a0e0c102ba8f8fad16940301af893dcfe5b`, [native38733051228](https://github.com/dwijayuda/pskernel/actions/runs/38733051228) passed checked semantics, all exact proof regenerations, shared constant/application erasure and full application emission (1,291 declarations), and the three-module application. Standard measured 3,122 declarations / 25 classes / 250 instances at the unchanged reviewed pins. The subsequent Wasm wrapper elaboration exposed six constants (`f2Default/Nan/Infinity{32,64}`) incorrectly recorded with `args: []` (function-call syntax) instead of the table's existing `args: null` constant discriminator. Correct those six metadata entries; retain every expected bit pattern and all 843 observations. This changes no compiler semantics or acceptance criteria. Full runtime qualification remains pending.


## F2 shared constant/application lowering — 15 October 2026

Research `cbdb554fa9209361cd72217432fb8435d1a15022` passed all checked native source tests, the strict 3,122-declaration manifest and shared instance-key invariant. Independent [F1 replay 38731576332](https://github.com/dwijayuda/pskernel/actions/runs/38731576332) and [F2 replay 38731576255](https://github.com/dwijayuda/pskernel/actions/runs/38731576255) passed. [Native 38731576337](https://github.com/dwijayuda/pskernel/actions/runs/38731576337) then found bare `Float.nan` bypassed primitive erasure.

Pinned Lean 4.35.0 `src/Lean/Compiler/LCNF/ToLCNF.lean` (`visitCore`, `visitAppCore`, `etaIfUnderApplied`) routes constants and applications through the same lowering. PSC0 now follows that invariant: zero-argument constants use the same special/decision/primitive/structure/constructor dispatch as applications; the general unresolved-head case terminates directly instead of recursively erasing the same constant. Duplicate constructor/entry handling is removed. Existing NaN/infinity and ordinary constant/constructor fixtures validate the design; full backend qualification is pending. No logical assets, strict pins, assumptions or budgets changed.

F3 gate [38731735348](https://github.com/dwijayuda/pskernel/actions/runs/38731735348) examined 134 additional declarations and found the next general dependency: selected Array is monomorphic but pinned Lean scientific fast-path arrays and indexing proofs are universe-polymorphic. Complete the Array family coherently before selecting F3; never drop native universe arguments or replace scientific semantics to bypass admission. F3 remains unselected on `psc0/pscv0-v7-f3-conversions-research` at `f1d2c51104aca2b25c77f1771c226af1772eb99d`.


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
