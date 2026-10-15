# Continue PSC0 / PSCV0 v7 M2 + Phase A

## 15 October — List indexing / authoring scope coherent research candidate

Research only: `psc0/research-list-index-scope-v1`, based on qualified Int family plus the latest docs. Complete List indexing universe propagation covers the bang/public/internal getters, positive/negative law helpers, all three selected dictionaries and freshened instance levels. Existing proof/optional workers and array callers retain their algorithms. Pinned Lean 4.35.0 Init/GetElem.lean and Init/Data/List/Basic.lean provide semantics; tests/elab/getElemV.lean and tests/elab_fail/getElem.lean distinguish checked/optional/bang/lawful behavior (their Classical alternatives are not imported).

Host StandardExport and StandardClosure reuse the existing withFreshKernelHeartbeatScope for every independent kernel submission. Source: pinned src/runtime/interrupt.cpp, src/Lean/Util/Heartbeats.lean and tests/elab/kernel_maxheartbeats.lean. The unchanged kernel limits are 2,000,000 heartbeats and depth 20,000. Failures remain refused. One boundary check exercises dirty caller budget, invalid-type refusal and caller restoration; an existing source batch adds generic List indexing/lawful inference plus a Type-valued index, with an independent native oracle.

The expanded four Float mask bridge roots remain research-only. Full native CI first independently measures strict manifest drift; only measured values may be pinned before complete qualification. No new runtime/Float claim, axiom, theorem replacement, pskernel-core or self-hosting. Main remains qualified at e322eff; M2+A incomplete.

## 15 October — checked Int arithmetic family QUALIFIED

Exact qualified source: `e322eff798a96db14b5deed24824ccf3c2fcc783`. [Native Linux CI 38706796031](https://github.com/dwijayuda/pskernel/actions/runs/38706796031) and [independent portable Float replay 38706795768](https://github.com/dwijayuda/pskernel/actions/runs/38706795768) both **passed** at this SHA. All 28 native job steps passed, including exact regeneration, 699 shared observations on each JS/TS/Rust target, GC Wasm/component execution and repeated Wasmtime calls.

Selected Standard: **1,856 declarations /25 classes /226 instances**; FNV `fnv1a64:17912930455396537674`, declaration SHA `sha256:a0f90d4ba911bd9be249bd72f8f0443e582eea41f21a56d192f27efb6b24ff44`, surface SHA `sha256:6c4c0803cb69b893926325dccd19ca9930425c2a051e8fdd1770bbc3c2d71b6c`. The exact 28-declaration /9-root asset provides native checked Int.add/neg/sub/mul definitions and original symbolic laws, replacing four computational axioms with no new assumptions or theorem substitutions. Fast runtime overrides are unchanged and explicitly audited.

**Next causal blockers, isolated research only:** expanded four Float mask bridges at `cee61377f12fe465238ca5b474422e43575a3761`, [38706081222](https://github.com/dwijayuda/pskernel/actions/runs/38706081222), were refused. The first genuine mismatch is monomorphic selected `List.get!Internal` versus native universe-polymorphic use. Later timeout cascades require per-independent-admission heartbeat isolation already used by source admission. Investigate and strengthen the whole List indexing family and host audit scope; keep 2,000,000/20,000 limits, official kernel admission, and failed dependencies blocked. Do not select the 922-declaration expanded Float candidate or claim executable Float/M2+A completion. Update both handoffs at the next slice.

## Working contract

GitHub canonical: dwijayuda/pskernel, branch psc0/pscv0-v7-native-lean-v1,
draft PR109. Inspect actual HEAD and exact-commit CI before writes; preserve
history using non-force expected-HEAD updates. The entry above records a qualified Int slice, not M2+A completion. Historical audit details remain in
AI_WORK_STATE.md; use its newest entries and live evidence.

Native portable .lean, pinned Lean 4.35.0 at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study corresponding official
sources/tests before each substantial feature. No Desktop Commander,
pskernel-core, self-hosting, bootstrap, compiler-source .ps migration or C5.
Wasm GC internally, linear memory only at explicit ABI boundaries.
Only propext and Quot.sound are approved; do not ask again or expand them.
Classical.choice-dependent native research is not portable proof evidence.

## Next critical path

1. Complete universe-polymorphic List indexing and fresh heartbeat scope for
   independent host audit admissions. Study pinned Lean sources/tests, inspect
   the affected family, validate complete changes; keep kernel limits unchanged.
2. Re-evaluate expanded compact Float mask/field proof closure with the actual
   checked Int definitions. The existing 26-root /100-declaration Float
   candidate already passed and is integrated; do not repeat its implementation.
   Keep speculative proof cuts on research branches. Native all-input upstream
   correspondence currently imports Classical.choice and is not selected.
3. Complete F1 selected Float32/64 source constructors, proof-carrying validity,
   shared typed erasure/IR and canonical bits; then F2 arithmetic/equality,
   F3 literals/conversions/rounding, F4 all-target ABI. Keep logical equality
   distinct from IEEE BEq, preserve signed zero, normalize NaN per pinned Lean.
4. Continue independent M2+A requirements: explicit 32/64 USize/ISize profiles,
   selected Standard APIs, deriving/search/elaboration and comprehensive manifest.
   Follow existing M2+A → M3+B → M4+C/D roadmap; no unrelated later work.

Implement coherent features then validate at meaningful milestones. Before
advancing, update BOTH AI_WORK_STATE.md and this continuation prompt with exact
SHAs, CI results, remaining limitations and next dependencies. Never declare
M2+A complete from bounded green CI or Float proof research alone.
