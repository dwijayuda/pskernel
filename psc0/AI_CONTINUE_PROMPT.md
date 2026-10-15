# Continue PSC0 / PSCV0 v7 M2 + Phase A

## F2 registry review; full runtime qualification pending — 15 October 2026

Research `6043e3e1891a326c2cd618925d5b5cfc8ec6c9e2` built the complete native compiler. Independent F1 replay [38729006486](https://github.com/dwijayuda/pskernel/actions/runs/38729006486) and byte-exact F2 replay [38729006492](https://github.com/dwijayuda/pskernel/actions/runs/38729006492) passed. F2 remains exactly 1,229 exported declarations /24 recursor rules /91,024 shared nodes, 11,179,796 source bytes, SHA-256 `ad82f59b48460a3b306312c3e9d72537e8b48201e432271a3be0424a576909df`. No new axioms or computational replacements.

[Native run38729006660](https://github.com/dwijayuda/pskernel/actions/runs/38729006660) passed the expanded primitive/reducibility audit and all 88 pinned native Float reference observations, then correctly refused the intentional selected-registry expansion. The independently observed exact pins are now reviewed: FNV `fnv1a64:2505184579072579125`, declaration SHA `sha256:387824db2d09a897d682b9e4f3d9695f4b31b30f2eca169d999e243dcfa38f66`, surface SHA `sha256:a90cd3d4ac970e2247329b79a748c5dc7d93b5c9f7d48c94cd0a565c8ec324c7`. Strict checks remain enabled.

The complete F2 code is on `psc0/pscv0-v7-f2-operations-research`; main remains qualified F1 at `262c5819c499256fcd2093746deae4ef3aa2012b`. Next run must qualify source elaboration/erasure, all 843 shared observations, GC Wasm/component execution, WIT/WAT and performance before integration. Do not call F2 or M2+A complete yet. Native .lean only; no pskernel-core, self-hosting/bootstrap or C5.

## Working contract

GitHub canonical: dwijayuda/pskernel. Main development branch `psc0/pscv0-v7-native-lean-v1`; draft PR109 keeps its original base and must not be merged. Inspect live branch HEAD and exact-commit CI before writes; preserve history with expected-HEAD, non-force updates. Use GitHub integration and cloud Linux CI only, no local checkout/files/builds or Desktop Commander. Keep research workflows contents: read.

Pinned Lean 4.35.0: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study corresponding official source and tests before every substantial feature. Native .lean; no pskernel-core, bootstrap/self-hosting, compiler-source .ps migration or C5. Application .ps fixtures are allowed. Only approved assumptions propext and Quot.sound. Original upstream Float correspondence imports Classical.choice and remains outside the selected portable closure.

Read the latest AI_WORK_STATE.md checkpoint, docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md and docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md; canonical v7 specifications govern completion. Continue M2+A -> M3+B -> M4+C/D -> M5/E. M1 is complete; M2+A is not.

## Immediate continuation

1. Inspect live research HEAD and current native/F1/F2 workflow results. The former Wasm fallback became redundant after exhaustive F2 dispatch; it was removed. The primitive audit now includes Model methods and Eq decision helpers. Do not redo qualified F1.
2. Finish coherent F2 qualification after the exact registry pins above. Fix root causes without weakening checks. Integrate the reviewed tree to fresh main only after all required lanes pass, restore workflow main-branch triggers, then qualify the exact main commit. Update BOTH handoff files, roadmap and PR evidence.
3. Continue F3 scientific syntax/defaults and scalar conversions, F4 complete Float qualification, USize/ISize explicit target profiles and remaining authoritative selected Standard/manifest obligations. Study the whole affected subsystem first.
4. F3 source study already covers pinned Parser/Basic.decimalNumberFn, Elab/BuiltinTerm.elabScientificLit, Init/Data/OfScientific{,/Basic}, Float/Model/Unpacked/Operations/OfScientific and tests/pkg/ofScientific (including doubleround.txt). Keep exact Nat mantissa, exponent sign and Nat exponent until the expected type/OfScientific instance is selected. Default Float priority is 501. Reuse exact rounding and exponent bounds; do not parse via binary64 before choosing Float32. No F3 implementation is staged yet.

## Verification and invariants

The F2 asset is selected behind frozen psSelfHostProdPreFloatOperationsPreludeEnvironment and psStandardFloatOperationsBoundary; proof dependencies stay out of runtime support. IEEE BEq identifies signed zeros and rejects NaN equality; logical DecidableEq compares canonical bits, distinguishes signed zero and identifies NaNs. All backends share typed IR; Wasm uses GC internally, with linear memory only at explicit Canonical ABI boundaries.

Use existing native build targets pscv0_native, pscv0_native_checks, pscv0_wasm_checks and pscv0_m1_performance. Follow current workflows for pinned commands/tools. Authoring must prepend the local Ps namespace root to Lake's LEAN_PATH. The awaited pooled-task helper resets the real C++ kernel heartbeat counter per independent authoring declaration; source requests keep cumulative 2,000,000-heartbeat/20,000-depth limits.

No new assumptions, proof placeholders, unchecked casts, fallback admission or increased budgets. Keep checked logical admission, runtime conformance and formal preservation claims separate. Prefer complete coherent features and compact differential validation, then the existing full backend suite. Update both handoffs each milestone slice.
