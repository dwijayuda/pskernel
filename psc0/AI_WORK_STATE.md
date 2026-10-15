# PSCV0 v7 — AI work state (16 October 2026)

## Working contract

Repository dwijayuda/pskernel. Use GitHub connector and cloud Linux CI exclusively: no local files/checkouts/shell/build/tests/Desktop Commander. Fresh HEAD and relevant CI before writes; expected-HEAD, non-force updates. Native portable .lean and official Lean 4.35.0 kernel (eb6cafb7290e8bd5f2937522d8d804f58f02bafc). Study corresponding pinned sources/tests before each feature; document attribution. Approved foundation: propext and Quot.sound only. No sorry, unchecked admission, weakened gates, increased budgets, pskernel-core, self-hosting, compiler-source .ps migration or C5 execution. Application .ps fixtures are allowed.

Development psc0/pscv0-v7-native-lean-v1; draft PR109 targets psc0/pscv0-v7-m1-parser-ownership-v1. Keep draft, never merge. Research psc0/pscv0-v7-platform-words-research. Preserve both histories and newer development docs when integrating. Update both handoff files and roadmap/status every milestone. Interleave M2+A -> M3+B -> M4+C/D -> M5/E; current user asks to complete M2+A.

## Confirmed baseline and research boundary

Development HEAD 4fedd6cab8236c5f0f0a16dcffe8f7e10402972e is a receipt for executable f1bb4bb810b2397a42ee5d04e4cc2af7dfc4c9d3: native all32 run38793307283; exact F1/F2/F3-F4 runs38793307234/38793307180/38793307143 passed. 978 JS/TS/Rust observations, GC Wasm core/components, Wasmtime/postreturn, source/kernel/modules/assets/performance. This is scoped qualification, not full v7 or global semantics preservation.

Research parent58b1f0c8767926512ce0de7b9e416707e7db7793: native [38810569497](https://github.com/dwijayuda/pskernel/actions/runs/38810569497) passed compiler, frozen assets, strict3568 declarations/32classes/315instances, source/kernel (4 programs,92 refusals), module emission, deriving and shared synthetic/instance/default/rollback/scaling checks. Platform runtime fixture then refused before emission: missing Decidable (Int equality) in checkSignedShift. No all-backend qualification for research yet. Independent F3/F4/platform logical replay [38810569357](https://github.com/dwijayuda/pskernel/actions/runs/38810569357) passed.

Native38812863861 and replay38812863915 atffa1cab3 stopped in compilation: the new scanner used Lean's reserved `prefix` keyword as a parameter and the light-synthesis structure update had invalid layout. Corrected both native source syntax issues; semantic qualification is still pending.

Native38813384394/replay38813384395 at518f52d8 stopped at the new reference-event structure-update layout. The same multi-line expression layout is corrected at both reference and binder owners. No semantic qualification yet.

Native38813567007/replay38813567093 atc7b5d476 found the same layout family in the new data-batch initializer. Audited all new receipt initializers and normalized data, ordinary/partial declaration and normalized worker receipts together. Compilation and semantic qualification remain pending.

## Source retention checkpoint (profile71; qualification pending)

Native38813171316/replay38813171392 at583ea213 stopped in compilation because Operator referenced psExprAppView outside its owning later layer. It now uses the equivalent existing psInferAppView in the inference layer, preserving the acyclic dependency graph.

This checkpoint adds immutable source info receipts at shared elaboration owners: ordered binder groups, resolved references/projections, implicit/default insertions and dictionary selections. Local contexts and the final assignment context remain attached; immutable rollback and resumed-scope ownership are preserved. Declaration/constructor and batch/project origins retain them outside Core identity/admissions. No C5 emission. One compact fixture checks grouped binders, omitted defaults, resolved globals, constructor fields and a single scoped postponed projection. See docs/PSCV0_M2_SOURCE_INFO_2026-10-16.md. Compiler and complete source/kernel/runtime/performance evidence is pending.

## Current coherent implementation checkpoint (profile70; qualification pending)

Research includes explicit32/64 target words with opaque logical platform width; Array.filter; structural alpha-normalized instance keys; strict UTF8 and shared GC boundary validation; constructive logic/order; conditional and Prop-to-Bool decisions on the shared synthetic queue. This checkpoint adds Lean Extra.lean-style typed operator trees, read-only maximal-type/coercion analysis, heterogeneous guards, Pow/shift protocols and Nat/Int runtime primitives across readable JS/TS/Rust/GC Wasm. It also makes deriving/tactic/effect surface audits consume actual dispatch tables.

Int equality selects Int.instDecidableEq and Int.decEq with exact primitive signature audit and three differential observations. Their native asset presence is not yet confirmed: the strict complete-dependency audit must reject any missing roots; if absent, extend the existing official-native export mechanism and replay its complete checked closure. Do not assume presence or create a logical axiom.

Twenty operator observations plus three Int equality observations extend the planned shared count from1046 to1069. All compilation/source/runtime evidence for this checkpoint is pending. Strict previous pins remain intentionally selected until BOTH independent audit boundaries agree on new measurements:
FNV16326442589260407706; declaration SHA256ba31eac8de32f952e1e217ae65ab78402df3785df35617fb8dd442ddff52a25c; surface SHA256e45f0214b2532da66f5863f91a9a7aaadfb3dbe9af128d0e19c77f210f16f393.

Designs: docs/PSCV0_M2_OPERATOR_PROTOCOL_2026-10-16.md, PSCV0_M2_LIVE_SURFACE_2026-10-16.md, PSCV0_M2_A_TARGET_WORDS_2026-10-16.md, PSCV0_M2_A_ARRAY_FILTER_2026-10-16.md, PSCV0_M2_INSTANCE_KEYS_2026-10-16.md, PSCV0_M2_A_UTF8_2026-10-16.md, PSCV0_M2_A_LOGIC_INSTANCES_2026-10-16.md. Historical receipts remain in Git and PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md.

## Remaining M2+A exit work

1. Complete dependency/source/kernel/backend qualification of the coherent research changes; fix underlying capabilities without weakening fixtures, budgets or audits. Native asset export must use pinned Lean and strict admission.
2. Qualify the committed source info receipts and final-assignment/scope/rollback invariants, with the existing performance budget. No C5 execution.
3. Finish comprehensive selected manifest and project provenance. Existing --audit-project-graph/project-source-graph.json already owns module/import evidence; inspect/reuse it. Audit proof extension/effect/assumption closure, state later-phase unavailable capabilities honestly.
4. Compare actual M2+A exit criteria with exact evidence; integrate research into development preserving both parents, rerun exact integration CI, update roadmap and PR109. Do not declare completion before these gates.

General dependent/recursive deriving, full proof automation/effects, global backend preservation and source reconstruction belong to later roadmap phases unless the canonical exit criteria require their selected subset here.
