# Continue PSC0 / PSCV0 v7 M2 + Phase A

## 15 October — F1 minimal constructor closure research

The complete 30-root mask audit passed as a 922-declaration, 11 MB proof artifact. That evidence does not imply every proof dependency belongs in selected Standard. Pinned Float/Float32.lean separates logical model/Format.Valid from optimized runtime representation; PSC0 follows the same boundary.

Research `psc0/research-float-constructor-slice-v1` adds a two-root constructor exporter using the existing checked dependency-closure pipeline and only FloatCanonical (not the larger contracts module). It must independently replay the transitive validity proof and actual native constructor signatures, with no theorem substitutions or extra assumptions. The existing complete representation audit still runs first. Measure the resulting asset before selecting it. Runtime representation, public source aliases, typed erasure, IR and all backend/ABI paths remain pending; no constructor has yet been added to selected Standard.

This is F1 within M2+A, not a new roadmap milestone. Main e5d1bdd6 integration qualification is separate. No pskernel-core, self-hosting or C5.

## 15 October — complete List indexing and actual kernel-scope integration

Research `556904b96a9d70306a92278cebaaa358095c3749` passed [full native CI 38710034211](https://github.com/dwijayuda/pskernel/actions/runs/38710034211) and [expanded portable Float replay 38710034341](https://github.com/dwijayuda/pskernel/actions/runs/38710034341). All 28 native steps passed: higher-universe List indexing/lawful inference, the actual kernel-counter boundary, exact existing asset regeneration, 699 observations each on JS/TS/Rust, GC Wasm/components and repeated Wasmtime calls.

Integrated changes:
- All selected List index workers/public/internal bang aliases, positive/negative proofs, GetElem/GetElem?/LawfulGetElem dictionaries and instance registrations consistently carry universe u. No extra length pass or algorithm change.
- One awaited pooled native IO task owns each independent authoring admission. Source requests use the same helper and retain their existing cumulative 2,000,000-heartbeat /20,000-depth budget. No dedicated OS thread per declaration, unchecked admission, retry or limit increase.
- Lean has separate allocation and C++ kernel counters. IO.setNumHeartbeats only changes the former; runtime/object.cpp:run_task resets the latter. NativeV7's redundant dedicated-thread wrapper is removed; allocation telemetry is no longer mislabeled as kernel heartbeats.
- The four compact Float mask-equivalence bridges join the authoritative contractRoots roster used by native assumption auditing and portable replay. Duplicate mask audit lists are removed. Native upstream pack/unpack correspondence remains separately labelled and unselected.

Selected Standard remains **1,856 declarations /25 classes /226 instances**. Independently measured strict pins: `fnv1a64:14729641192328177589`, declaration `sha256:8b956d8f7b7f5bbebaf6480454e528380cd53f513772460a5a8f60648ad8bc2b`, surface `sha256:58d4afa2cb069f078ab68f358b4e1718edd10cbc9f316f90357faeca381cb77d`.

The expanded candidate checked **30 roots /922 declarations /11 recursor rules**, with only propext/Quot.sound, no new axioms or replaced-definition axioms. Research artifact: **11,097,675 bytes /83,125 shared nodes**, SHA-256 `564b48590fde9074679ec5e8d72f746fda4069f382b7cbcdd6101ba0c7bda622`. This candidate is **not** added wholesale to selected Standard or executable Float. Assess its proof dependency cost and integrate the minimal coherent F1 source/IR representation boundary next.

**This main integration still requires exact-commit native/backend and expanded Float CI.** The qualified research result is not substituted for that check. M2+A/F1-F4 remain incomplete. No pskernel-core, self-hosting, C5 or trust expansion.

Primary pinned Lean references studied: Init/GetElem.lean, Init/Data/List/Basic.lean; runtime/alloc.cpp, runtime/io.cpp, runtime/interrupt.cpp, runtime/object.cpp; Lean/AddDecl.lean and Compiler/LCNF/EmitC.lean. Relevant tests: elab/getElemV.lean, elab_fail/getElem.lean, elab/kernel_maxheartbeats.lean, elab/taskState.lean. task_test_io.lean exits early upstream and is not qualification evidence. The allocation-only first probe was insufficient; the final probe consumes actual C++ kernel work, observes unscoped timeout, checks fresh scoped acceptance and invalid-type rejection.

## Working contract

GitHub canonical: dwijayuda/pskernel, branch psc0/pscv0-v7-native-lean-v1,
draft PR109. Inspect actual HEAD and exact-commit CI before writes; preserve
history using non-force expected-HEAD updates. The entry above records qualified research and its main integration candidate, not M2+A completion. Historical audit details remain in
AI_WORK_STATE.md; use its newest entries and live evidence.

Native portable .lean, pinned Lean 4.35.0 at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study corresponding official
sources/tests before each substantial feature. No Desktop Commander,
pskernel-core, self-hosting, bootstrap, compiler-source .ps migration or C5.
Wasm GC internally, linear memory only at explicit ABI boundaries.
Only propext and Quot.sound are approved; do not ask again or expand them.
Classical.choice-dependent native research is not portable proof evidence.

## Next critical path

1. Qualify this main integration at its exact SHA in native/backend and expanded
   Float CI. The research already passed; investigate any genuine integration
   difference, without weakening checks. Record exact results in both handoffs.
2. The 30-root /922-declaration compact Float mask proof closure now replays.
   Do not repeat monomorphic List or cumulative-kernel-counter repairs. Native
   upstream-ofBits correspondence still includes Classical.choice and remains
   unselected. Keep proof audit roots centralized; inspect candidate size before
   selecting the F1 logical/constructor asset and runtime representation.
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
