# PSCV0 v7 — AI work state

## F2 executable family: research qualified, main integration — 15 October 2026

[Native38734252078](https://github.com/dwijayuda/pskernel/actions/runs/38734252078) passed completely at `9ffdd799a05ee256368266831bbaec74bee18ed2`: **843 shared runtime observations** across readable JS/TS/Rust and GC Wasm/core/component, native oracles, official-kernel source admission, exact asset regeneration, ABI/WIT/WAT checks, multi-module programs, repeated Wasmtime calls and unchanged performance gates. Independent [F1 replay38733051176](https://github.com/dwijayuda/pskernel/actions/runs/38733051176) and [F2 replay38733051136](https://github.com/dwijayuda/pskernel/actions/runs/38733051136) pass at `c3081a0e0c102ba8f8fad16940301af893dcfe5b`; the descendant only corrects six constant observations to the established `args: null` schema and updates handoffs. No expected values changed.

This integration selects Float/Float32 add/sub/mul/div, neg/abs, IEEE equality/order, NaN/infinity classification and checked logical equality decisions, including generic, partial and Model calls. The original Lean logical family contains 1,229 declarations /24 recursor rules /91,024 shared nodes /11,179,796 UTF-8 bytes, SHA-256 `ad82f59b48460a3b306312c3e9d72537e8b48201e432271a3be0424a576909df`. Only approved propext/Quot.sound are assumed; no new axioms or proof replacements. Proof dependencies stay out of runtime support.

The typed IR adds float unary/test operations; ECMA enforces binary32 rounding per operation, Rust uses safe scalar operations, and Wasm uses native arithmetic plus memory-free classification helpers. Canonical NaN observation and signed-zero behavior follow F1. The shared constant/application erasure path now handles nullary primitives and preserves partial application. Its design follows pinned Lean `Lean/Compiler/LCNF/ToLCNF.lean` (visitCore/visitAppCore/etaIfUnderApplied). The instance registry now validates each key against the reduced result class, following `Lean/Meta/Instances.lean`; DecidableEq registers under Decidable.

Reviewed selected Standard: **3,122 declarations /25 classes /250 instances**; FNV `11971833863653521941`, declaration SHA-256 `8a3fbf1e59845739e6926b7e52add0059a33054cf74625f64923d4f360c43c7e`, surface SHA-256 `ff2b3e2ed6e043cb11a332d5175ff1116f8e4c1a4c13a91baca71bb53a917fc3`. All guards remain strict. Native prelude initialization measured 7.608s separately; performance gates passing does not establish optimal performance or a backend preservation theorem.

**Exact-main qualification is pending on this integration commit.** F1 remains previously main-qualified at `262c5819c499256fcd2093746deae4ef3aa2012b`. Do not call all M2+A complete. Next: finish exact-main F2 checks; qualify/integrate the universe-polymorphic Array prerequisite from `psc0/pscv0-v7-f3-conversions-research`; then scientific literals, shared priority-ordered default instances and numeric conversions (F3), display (F4), and remaining M2+A exits. The F3 logical candidate already passes [38734094036](https://github.com/dwijayuda/pskernel/actions/runs/38734094036) but remains unselected. No pskernel-core, self-hosting, compiler-source translation or C5 work.


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


## F2 registry review; full runtime qualification pending — 15 October 2026

Research `6043e3e1891a326c2cd618925d5b5cfc8ec6c9e2` built the complete native compiler. Independent F1 replay [38729006486](https://github.com/dwijayuda/pskernel/actions/runs/38729006486) and byte-exact F2 replay [38729006492](https://github.com/dwijayuda/pskernel/actions/runs/38729006492) passed. F2 remains exactly 1,229 exported declarations /24 recursor rules /91,024 shared nodes, 11,179,796 source bytes, SHA-256 `ad82f59b48460a3b306312c3e9d72537e8b48201e432271a3be0424a576909df`. No new axioms or computational replacements.

[Native run38729006660](https://github.com/dwijayuda/pskernel/actions/runs/38729006660) passed the expanded primitive/reducibility audit and all 88 pinned native Float reference observations, then correctly refused the intentional selected-registry expansion. The independently observed exact pins are now reviewed: FNV `fnv1a64:2505184579072579125`, declaration SHA `sha256:387824db2d09a897d682b9e4f3d9695f4b31b30f2eca169d999e243dcfa38f66`, surface SHA `sha256:a90cd3d4ac970e2247329b79a748c5dc7d93b5c9f7d48c94cd0a565c8ec324c7`. Strict checks remain enabled.

The complete F2 code is on `psc0/pscv0-v7-f2-operations-research`; main remains qualified F1 at `262c5819c499256fcd2093746deae4ef3aa2012b`. Next run must qualify source elaboration/erasure, all 843 shared observations, GC Wasm/component execution, WIT/WAT and performance before integration. Do not call F2 or M2+A complete yet. Native .lean only; no pskernel-core, self-hosting/bootstrap or C5.

## Earlier checkpoints (historical; current status above)

## F2 coherent implementation staged; qualification pending — 15 October 2026

The expanded native logical family passed at research `7393a31700c8aefe8843c4eb92476342786f45be`, [run38724434988](https://github.com/dwijayuda/pskernel/actions/runs/38724434988): **1,229 declarations /24 recursor rules /91,024 shared nodes /11,179,796 source bytes**, SHA-256 `ad82f59b48460a3b306312c3e9d72537e8b48201e432271a3be0424a576909df`. This includes native Float.decLt/decLe and DecidableEq at both widths. Only the two existing theorem cuts and approved propext/Quot.sound are used. Original upstream correspondence proofs still retain their recorded native-only assumption boundary.

The staged source selects that exact checked logical asset behind a frozen pre-F2 environment, registers arithmetic/Neg/BEq/Inhabited and native order/Eq decisions through the existing class index, and keeps the proof closure out of runtime support. Shared typed IR owns unary/classification signatures alongside arithmetic/comparison. Canonical-bit equality reuses existing bit conversions and integer equality; IEEE equality remains a distinct operation. Model-level operations use the same typed boundary and ordinary proof-erased record representation.

Readable JS/TS retain binary64 operations and explicit binary32 rounding. Rust uses safe native floating operations. Wasm emits native arithmetic/comparison and shared scalar descriptors for abs/neg; classification remains memory-free. F1 GC boxing and explicit ABI ownership are unchanged. **88 additional native-reference observations** cover rounding ties, subnormals, infinities, NaNs, signed zero, comparison/equality, partial/generic and Model calls. The full target corpus is intended to reach 843 observations, pending CI.

Strict declaration/surface pins remain at the prior qualified values until the intentional expansion is independently measured and reviewed. Do not weaken those checks. Run full native/backend CI, byte-exact F2 regeneration and independent F1 proof replay before claiming runtime qualification. No pskernel-core, self-hosting/bootstrap or C5. Main F1 remains qualified at 262c5819c499256fcd2093746deae4ef3aa2012b. Update both handoffs at the next slice.

## F2 logical family checked; runtime pending — 15 October 2026

Research commit `d4528f27e45917b5d63edd84b0feb15d5e812bf6` on `psc0/pscv0-v7-f2-operations-research` passed [logical closure replay 38722766782](https://github.com/dwijayuda/pskernel/actions/runs/38722766782). All 28 Float/Float32 arithmetic/comparison/classification roots plus the two existing constructive theorem roots passed: **1,169 new declarations, 24 recursor rules, 89,183 shared source nodes, 10,941,261 source bytes**. SHA-256 `711ef5ecd08df8442c986b6df2cc9135ea79b9842ec0100cf517b289488b9acf`. No new axioms, quotient primitives or definition replacements; only the approved propext/Quot.sound foundation.

This candidate is not selected Standard and F2 runtime operations remain refused. Next: freeze the pre-F2 boundary, select the checked logical family and source class metadata, keep proof dependencies out of runtime support, implement shared typed arithmetic/unary/classification/equality lowering across all active backends, then qualify one compact native differential corpus. F1 remains main-qualified at 262c5819c499256fcd2093746deae4ef3aa2012b (native38721711653, Float38721711679, 755 shared observations). M2+A is incomplete.

## F1 executable MAIN QUALIFIED — 15 October 2026

**Main implementation qualified:** `262c5819c499256fcd2093746deae4ef3aa2012b`.
[Full native/backend run 38721711653](https://github.com/dwijayuda/pskernel/actions/runs/38721711653) and
[independent Float proof replay 38721711679](https://github.com/dwijayuda/pskernel/actions/runs/38721711679) both passed at that exact SHA; all 29 native steps passed. Research `bcd102cdac80b19367b461c204d6663e8526e2f7` passed native38720893666 and Float38720893532 before integration. This receipt changes documentation only.

F1 implements checked `UInt64 ↔ Float` / `UInt32 ↔ Float32` bit transport, model construction/projection/elimination and partial applications. Logical Model records retain real validity proofs in checked Core and ordinary record layout after proof erasure. JS and TS share readable DataView helpers; Rust uses safe f32/f64 bit APIs; Wasm uses native scalars and GC boxes only at generic crossings. Every NaN denotes the unique logical NaN; bit/model/explicit ABI observations canonicalize it. Other patterns, including signed zero, are preserved.

The one Canonical ABI plan now supports f32/f64 scalar, aggregate, list, generic-record and indirect signatures. Variant joins restore payloads by reinterpretation/wrapping. Typed post-return metadata drives runtime definitions, binary alias indices and readable WAT together; linear memory remains ABI-only. The primitive audit explicitly records Float bit/model runtime overrides. No proof closure was added to runtime support.

Qualification passed **755 shared observations** (56 new F1 cases) on JS/TS/Rust and GC Wasm/core/component paths, native Lean bit-corpus checks, wrong source/IR width refusals, full WIT extraction and binary/WAT agreement, mixed float/integer ABI variants, indirect parameters, signed-zero/NaN memory observations, repeated Wasmtime calls, exact proof-asset regeneration and existing performance gates. This is scoped conformance evidence, not a backend preservation theorem or full M2+A completion.

Selected Standard and its exact hashes are unchanged: **1,879 declarations /25 classes /226 instances**; FNV `fnv1a64:9256054256618924345`; declaration SHA `0f62a5df0a7273a183e10700bf8eb49563afd0ff8d03b7be3935d4d310a12f04`; surface SHA `240050e325b7c7d06827c36bffe7ed017ef18680b61ccf4fa7701807a62874b4`. Foundation remains exactly approved propext/Quot.sound.

**Next: remaining M2+A in the existing order.** F2 arithmetic/equality/classification needs checked native logical dependencies before enabling its still-refused IR operations; F3 scientific/conversions, F4 complete Float qualification, explicit target-word profile propagation and authoritative Standard/manifest exits remain open. Pinned Lean 4.35.0 Float/Model/Unpacked Operations Add/Mul/Div/Compare and Round plus tests/elab/floatModelDefeq.lean were studied: reuse unpack/operate/round/pack; ties-to-even residual bits and IEEE versus propositional equality are semantic requirements. Do not substitute bit-helper observations for checked floating definitions. Keep M2+A → M3+B → M4+C/D → M5/E.

Native .lean only; no pskernel-core, self-hosting/bootstrap or C5. PR109 stays draft on its original base. Update BOTH handoff files each slice, preserve expected-HEAD history, and report exact completed/pending evidence.


## Previous qualified checkpoint — 15 October 2026

**Qualified implementation: `38dbbfb9826490d02a44e6ab5b518a9946849345`.** [Native compiler/backend CI 38715710210](https://github.com/dwijayuda/pskernel/actions/runs/38715710210) and [independent portable Float replay 38715710273](https://github.com/dwijayuda/pskernel/actions/runs/38715710273) both passed at this exact commit. The subsequent handoff update changes documentation only.

Completed this continuation:
- **Checked Int arithmetic:** 28 native declarations/laws replace exactly four historical computational axioms; existing runtime intrinsics remain independently audited. Main `e322eff798a96db14b5deed24824ccf3c2fcc783` passed native38706796031 and Float38706795768.
- **Complete universe-polymorphic List indexing and actual kernel-counter isolation:** main `e5d1bdd6d667057bfd5376e8b39f3069f1dfc93c` passed native38711192827 and Float38711192777. One shared awaited pooled-task mechanism owns independent admission; source requests keep the cumulative 2,000,000-heartbeat /20,000-depth budget. IO allocation telemetry is a separate counter.
- **Logical Float constructors:** only 21 checked validity/constructor declarations plus Float.ofBits/Float32.ofBits typed wrappers are selected. The 307,290-byte source asset regenerates exactly (SHA-256 `3042b3db951a1c68f8df24c5161889841082f9f4ee03783e1e5b4da918b3f9a7`). Checked source accepts both widths and bit projections; wrong-width arguments and unsupported executable Float are refused.
- **Independent proof closure:** 30 roots /922 declarations /11 recursor rules, including the four mask-equivalence bridges, replay successfully with only propext/Quot.sound. The 11,097,675-byte audit asset (SHA-256 `564b48590fde9074679ec5e8d72f746fda4069f382b7cbcdd6101ba0c7bda622`) stays outside selected Standard.

The native workflow passed all 29 steps, including **699 existing observations each for JS, TypeScript and Rust**, GC Wasm/core and component validation, repeated native Wasmtime calls, asset byte comparison, source refusals and performance checks. These observations are scoped evidence, not backend metatheory or full v7 conformance.

Selected Standard: **1,879 declarations /25 classes /226 instances**. FNV `fnv1a64:9256054256618924345`; declaration SHA-256 `0f62a5df0a7273a183e10700bf8eb49563afd0ff8d03b7be3935d4d310a12f04`; surface SHA-256 `240050e325b7c7d06827c36bffe7ed017ef18680b61ccf4fa7701807a62874b4`.

**M2 + Phase A is NOT complete.** Next required work is F1 executable model erasure, typed IR, GC boxing, all backends and explicit ABI, followed by F2 arithmetic/equality, F3 scientific/conversions, F4 qualification, target-sized words and remaining authoritative language/Standard exits. The existing scalar-completion design records the studied Lean runtime representation and Canonical ABI dependencies. C5, self-hosting/bootstrap, compiler-source .ps translation and pskernel-core remain excluded.

No new trusted assumptions or proof placeholders. Native upstream Float correspondence still transitively imports Classical.choice and remains unselected. PR109 stays draft on its original base. Read live HEAD before further writes.

### Preserved research refusals

- `dd532710`: [native38712915969](https://github.com/dwijayuda/pskernel/actions/runs/38712915969) correctly reported all three old-pin mismatches; [Float38712916118](https://github.com/dwijayuda/pskernel/actions/runs/38712916118) rejected a selected root cutting its own audit. Pins were independently measured; Float authoring now uses the frozen pre-constructor stage.
- `1e45a3dd`: [Float38713950619](https://github.com/dwijayuda/pskernel/actions/runs/38713950619) passed. Native38713950473 passed source checks but authoring lacked a module search path. `44fd5eeb` native38714549468 then identified parent/local Ps namespace precedence. Pinned Lean/Util/Path.lean confirms first-root resolution; the final invocation reuses the successful proof workflow's explicit local-root-first LEAN_PATH.
- Qualified research `41a4474b7cbbb04c9e83b4a7fae111631be58e7a`: native38715004637 and Float38715004629 both passed before integration. No guards, budgets or byte comparisons were weakened.

## Historical checkpoints (superseded by the current receipt)

## 15 October — minimal logical Float constructors integrated; main qualification pending

Research `41a4474b7cbbb04c9e83b4a7fae111631be58e7a` passed both [full native integration 38715004637](https://github.com/dwijayuda/pskernel/actions/runs/38715004637) and [independent full proof replay 38715004629](https://github.com/dwijayuda/pskernel/actions/runs/38715004629). All 29 native steps passed, including exact asset regeneration, source/type/runtime boundaries, 699 observations each on JS/TS/Rust, GC Wasm/component validation, repeated Wasmtime calls and performance checks. This main integration still requires the same exact-commit pair before main qualification is claimed.

The selected constructor layer adds **21 checked declarations plus two public typed wrappers**, retaining actual Format.Valid evidence. Asset: **307,290 UTF-8 bytes /1,702 shared nodes**, SHA-256 `3042b3db951a1c68f8df24c5161889841082f9f4ee03783e1e5b4da918b3f9a7`. Regeneration uses its frozen pre-constructor declaration boundary and mandatory byte comparison. The independent **30-root /922-declaration /11 MB** representation audit remains separate from selected Standard. No new assumptions, axioms or runtime overrides.

Standard now has **1,879 declarations /25 classes /226 instances**. Strict independently measured pins: `fnv1a64:9256054256618924345`; declaration `sha256:0f62a5df0a7273a183e10700bf8eb49563afd0ff8d03b7be3935d4d310a12f04`; surface `sha256:240050e325b7c7d06827c36bffe7ed017ef18680b61ccf4fa7701807a62874b4`. Logical Float.ofBits/Float32.ofBits and toBits source admission is checked, a wrong-width argument is refused, and executable Float remains refused at the shared IR gate.

The full audit's pre-constructor boundary prevents selected roots from cutting their own replay. Host authoring uses the local Ps namespace first: Lean/Util/Path.lean resolves the first root directory, so plain lake env alone is insufficient when both parent and native packages use Ps. This ordering matches the independently qualified proof workflow.

M2+A remains incomplete. Next: coherent F1 model erasure, typed IR, all backends and explicit ABI; then F2-F4, target-sized words and remaining selected language/Standard obligations. Continue M2+A -> M3+B -> M4+C/D. No pskernel-core, self-hosting, C5 or trust expansion.

## 15 October — List/kernel scope MAIN QUALIFIED; F1 constructor closure minimized

**Qualified main code `e5d1bdd6d667057bfd5376e8b39f3069f1dfc93c`** passed [native 38711192827](https://github.com/dwijayuda/pskernel/actions/runs/38711192827) and [portable mask proof audit 38711192777](https://github.com/dwijayuda/pskernel/actions/runs/38711192777). All native/backend gates passed at the same SHA. Complete List indexing is universe-polymorphic; actual C++ kernel counters are isolated by one shared awaited pooled-task mechanism. Standard stays 1,856 declarations /25 classes /226 instances, with the measured List pins recorded below. No test or kernel limit was weakened.

The next architectural cut has independent evidence: research `412697cf6811e32a37cf79ef955ed0c6c5a14b8c`, [38711557857](https://github.com/dwijayuda/pskernel/actions/runs/38711557857), passed both the full 30-root /922-declaration representation audit and the **two-root /21-declaration constructor closure**. The latter has 1,702 shared nodes, **307,290 UTF-8 bytes**, SHA-256 `3042b3db951a1c68f8df24c5161889841082f9f4ee03783e1e5b4da918b3f9a7`, only approved propext/Quot.sound, no axioms/replaced axioms and no theorem substitutions. Keep the 11 MB representation proof audit out of the selected constructor dependency closure.

Next: integrate only that small logical constructor/Format.Valid asset behind a frozen regeneration boundary, expose checked Float.ofBits/Float32.ofBits aliases, and validate logical source admission while runtime Float remains refused. Then complete F1 typed representation/erasure/IR and JS/TS/Rust/Wasm/ABI together, followed by F2-F4 and remaining M2+A. No runtime Float or M2+A completion claim. No pskernel-core, self-hosting or C5.

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

## 15 October — checked Int arithmetic family QUALIFIED

Exact qualified source: `e322eff798a96db14b5deed24824ccf3c2fcc783`. [Native Linux CI 38706796031](https://github.com/dwijayuda/pskernel/actions/runs/38706796031) and [independent portable Float replay 38706795768](https://github.com/dwijayuda/pskernel/actions/runs/38706795768) both **passed** at this SHA. All 28 native job steps passed, including exact regeneration, 699 shared observations on each JS/TS/Rust target, GC Wasm/component execution and repeated Wasmtime calls.

Selected Standard: **1,856 declarations /25 classes /226 instances**; FNV `fnv1a64:17912930455396537674`, declaration SHA `sha256:a0f90d4ba911bd9be249bd72f8f0443e582eea41f21a56d192f27efb6b24ff44`, surface SHA `sha256:6c4c0803cb69b893926325dccd19ca9930425c2a051e8fdd1770bbc3c2d71b6c`. The exact 28-declaration /9-root asset provides native checked Int.add/neg/sub/mul definitions and original symbolic laws, replacing four computational axioms with no new assumptions or theorem substitutions. Fast runtime overrides are unchanged and explicitly audited.

**Next causal blockers, isolated research only:** expanded four Float mask bridges at `cee61377f12fe465238ca5b474422e43575a3761`, [38706081222](https://github.com/dwijayuda/pskernel/actions/runs/38706081222), were refused. The first genuine mismatch is monomorphic selected `List.get!Internal` versus native universe-polymorphic use. Later timeout cascades require per-independent-admission heartbeat isolation already used by source admission. Investigate and strengthen the whole List indexing family and host audit scope; keep 2,000,000/20,000 limits, official kernel admission, and failed dependencies blocked. Do not select the 922-declaration expanded Float candidate or claim executable Float/M2+A completion. Update both handoffs at the next slice.

## 15 October — measured surface pin, complete qualification pending

Native [38706356401](https://github.com/dwijayuda/pskernel/actions/runs/38706356401) at `8d50fdab04fea2825064220bf9842820ab03554e` passed the reviewed declaration FNV/SHA pins and byte-for-byte arithmetic regeneration, then correctly refused the separate surface manifest pin. Its independently reported new value is **sha256:6c4c0803cb69b893926325dccd19ca9930425c2a051e8fdd1770bbc3c2d71b6c**, now pinned exactly. Independent Float replay [38706356864](https://github.com/dwijayuda/pskernel/actions/runs/38706356864) passed.

The older a1bc8... value was the **surface manifest** digest, not the declaration SHA-256. Future drift failures now report all three candidate fingerprints in the first refused audit, avoiding sequential authoring runs; acceptance still fails and no emission is authorized. This is diagnostic reporting only, not automatic repinning or relaxed validation. Complete native/backend qualification of this commit remains required. M2+A remains incomplete.

## 15 October — Int arithmetic asset reproduced; strict hashes measured

Integration `5cffe9280f2f2bed07eb1f1a230eb1e924160bdd` compiled and regenerated the 28-declaration Int asset **byte-for-byte** in [native CI 38705958851](https://github.com/dwijayuda/pskernel/actions/runs/38705958851). The existing strict registry guard correctly refused the previous snapshot and independently measured **fnv1a64:17912930455396537674** and **sha256:a0f90d4ba911bd9be249bd72f8f0443e582eea41f21a56d192f27efb6b24ff44**. Both values are now pinned unchanged; no check is relaxed. The separate compact Float kernel replay [38705958724](https://github.com/dwijayuda/pskernel/actions/runs/38705958724) passed at that same integration SHA.

This snapshot update still requires complete native/backend and independent Float qualification at its own commit. The expanded mask bridge is isolated on `psc0/research-float-mask-int-model-v1`, commit `cee61377f12fe465238ca5b474422e43575a3761`, [CI 38706081222](https://github.com/dwijayuda/pskernel/actions/runs/38706081222), pending at this checkpoint. No executable Float, new assumption or M2+A completion is claimed.

## 15 October — coherent Int logical arithmetic integration candidate

Baseline: `bc613bc47f63e1fd3a9f1cb714317da46d78f12f`, following qualified `7742b4cd9599af315da4a1af1ba5c8f97a6ac290` (native [38701305472](https://github.com/dwijayuda/pskernel/actions/runs/38701305472), Float replay [38701305530](https://github.com/dwijayuda/pskernel/actions/runs/38701305530)). Actual baseline Standard: **1,832 declarations /25 classes /226 instances**, FNV `fnv1a64:8516648619442707737`, SHA-256 `sha256:606ab4df1a8517d7e3323d49ee4050cadc62612e433c541fd322f44e0b626f05`. The earlier 1bc8... SHA below was a documentation error; the source and successful exact-commit CI agree on 606ab4.... Existing 699 JS/TS/Rust observations and Wasm/Wasmtime passed.

Research `ab031712d4cf75c4860bb53ae76ca753d7b61b67`, [38705122100](https://github.com/dwijayuda/pskernel/actions/runs/38705122100), independently checked **28 declarations /9 roots /1 recursor rule**, replacing exactly Int.add/neg/sub/mul computational axioms. The actual native add_zero, neg_neg, add_neg_eq_sub, natCast_add and natCast_mul proofs replay without theorem cuts or new axioms; assumptions remain exactly propext/Quot.sound. This fixes the missing logical definitions behind the earlier Int proof refusal. Native Float constructors and all Float runtime features remain separate.

Integrated candidate: exact checked asset, frozen pre-arithmetic export boundary, recorded native reducibility, required byte-for-byte regeneration, and explicit checked-runtime-model audit entries. Fast Int intrinsics remain the executable implementation; proof dependencies are not runtime support. The strict old FNV/SHA pins are intentionally retained until independent candidate measurements; do not infer new fingerprints. **Main integration is pending complete native/backend and independent Float qualification at the same SHA.**

Pinned Lean sources studied: Init/Data/Int/Basic.lean and Lemmas.lean; tests/elab/intNegSucc.lean and test_extern_int.lean. Source references/design are in the existing scalar completion document. No pskernel-core, self-hosting, C5, unchecked proofs or trust expansion. M2+A remains incomplete.

## 15 October — M2+A checked universe-polymorphic List.get QUALIFIED at 7742b4cd

**Exact qualified selected Standard and executable:** `7742b4cd9599af315da4a1af1ba5c8f97a6ac290`.
[Full native Linux CI 38701305472](https://github.com/dwijayuda/pskernel/actions/runs/38701305472)
and [independent portable Float replay 38701305530](https://github.com/dwijayuda/pskernel/actions/runs/38701305530)
both **passed on this same SHA**; the 27-step native job and nine-step
independent replay job each completed without failure. The separate
[combined research CI 38700154739](https://github.com/dwijayuda/pskernel/actions/runs/38700154739)
and [portable research replay 38700154737](https://github.com/dwijayuda/pskernel/actions/runs/38700154737)
also passed before main integration.

The pinned Lean 4.35.0 `List.get` proof worker, dependent index,
reconstructor and checked signature are now consistently polymorphic
over universe `u`, rather than constrained to monomorphic `Type`.
This repairs genuine selected Standard semantics; the independent
optional list-index worker and existing checked runtime behavior are
preserved. The independently measured and qualified Standard digests are
`fnv1a64:8516648619442707737` and
`sha256:a1bc8d8587566b98c3c8bdfc3eacfdb7ea28372093b23365f0469f708b14cbfa`.
The full 26-root / 100-declaration compact F1 candidate still returns
`kernelChecked: true`, `axioms: []`,
`replacedDefinitionAxioms: []`,
`importedAssumptions: ["propext","Quot.sound"]`.
The Float replay workflow now also watches changes in the selected
Standard, portable packages and manifest/checker dependencies.

**Further research explicitly not selected:** native constructive
`Int.add_zero` and `Int.add_neg_eq_sub` proofs passed their native
oracle, but the strict [portable candidate replay 38700736202](https://github.com/dwijayuda/pskernel/actions/runs/38700736202)
refused their proof types against the legacy selected Int arithmetic
model. This is a real model/definitional-equality incompatibility,
not a reason to admit an axiom, bypass kernel checks or change native
semantic requirements. An isolated research branch is evaluating
the *logical Int.add definition itself* before any further migration.

Source-level Float constructors, verified erasure, numeric F2/F3,
runtime/ABI F4, target-sized portable profiles and the full selected
Phase A manifest remain open. Neither M2+A nor PSCV0 v7 is complete.
No pskernel-core, self-hosting or C5.

## 15 October — F1 constructive 26-root / 100-declaration integration candidate

An expanded **strict independent portable kernel** research replay passed
at `800dc1ba3780bf44a3f6c0a63e60212a0e09f4ac`, [CI 38699328933](https://github.com/dwijayuda/pskernel/actions/runs/38699328933).
The bounded F1 proof candidate now combines the previous 21 roots,
four exact fixed-width constructive all-ones proofs, and a
`BitVec.getLsbD_of_ge` **theorem-only** constructive replacement.
The actual official Lean 4.35.0 kernel verifies the replacement has the
same pinned native theorem type; PSC0 independently replays the proof,
not an axiom. Receipt: **100 declarations / 26 roots**,
`kernelChecked: true`, `axioms: []`,
`replacedDefinitionAxioms: []`,
`importedAssumptions: ["propext","Quot.sound"]`.

**This main-branch integration is unqualified pending full Linux/native
and portable Float replay at the exact new commit.** No selected Standard
declarations, intrinsic registry, language syntax, typed erasure, executable
Float runtime, JS/TS/Rust/Wasm/Wasmtime floating ABI, or trust policy were
changed. The theorem-only proof cut exists in the **candidate exporter**;
it is not silently enabled in production. Its exact origin and independent
check must remain auditable.

This proof progress does not discharge other large upstream
`Lean.Omega → List.get / Int` proof-closure incompatibilities. Finish
selected source F1 constructors and safe erasure separately, then F2–F4
and the remaining M2+A/Phase A obligations. Do not assert completion.

## 15 October — Float F1 21-root compact candidate QUALIFIED at 7af2c508

**Exactly qualified executable source:** `7af2c5080c9d21192d1ccc8a91d2de2013223f9f`. Both
[full native Linux CI 38680587949](https://github.com/dwijayuda/pskernel/actions/runs/38680587949)
and independent
[portable F1 replay 38680587932](https://github.com/dwijayuda/pskernel/actions/runs/38680587932)
succeeded on the **same commit**.

The checked compact candidate now contains **21 roots / 46 declarations**:
the previous 17-root Float construction and representation closure, plus
`canonicalMask64`, `canonicalMask32`,
`packedNaN64_eq_constant`, and `packedNaN32_eq_constant`.
These are ordinary, checked canonical-bit carrier definitions and fixed
canonical NaN proofs; they do **not** admit source-level Float execution.
The unchanged exporter reports `kernelChecked: true`, `axioms: []`,
`replacedDefinitionAxioms: []` and imported assumptions exactly
`["propext","Quot.sound"]`. Target JS/TS/Rust/Wasm and native Wasmtime
CI gates remain green at this checkpoint.

**Separate constructive theorem-cut research:** the host-only proof
`PsV7Native.FloatConstructive.getLsbDOfGe`, already committed in this
working tree, passed native Lean CI 38680234876 and an **independent
theorem-only type-and-kernel replay** at
[CI 38680361737](https://github.com/dwijayuda/pskernel/actions/runs/38680361737).
Its exact pinned `BitVec.getLsbD_of_ge` statement was checked with a
replacement proof that avoids `Lean.Omega` and imports no new axioms.
Receipt: `kernelChecked: true`, one replayed declaration,
`axioms: []`, and only `propext` / `Quot.sound`. The replacement is
**not published into the selected Standard**. A separate isolated
research branch tests whether that checked proof cut can support wider
IEEE field theorems.

**Remaining blocker:** upstream BitVec splitting/injectivity proofs
transitively import incompatible `Lean.Omega → List.get / Int` proof
dependencies. Extended proof roots that fail independent kernel replay
must stay out of the published candidate. No trust expansion, unsound
casting or artificial proof evidence is permitted. Selected source Float
constructors, erased typed Float IR, runtime/ABI and F2–F4 are still
disabled/unqualified; M2+A is incomplete. Continue F1 selected source,
proof erasure and separate backend evidence only when fail-closed gates
are satisfied. No pskernel-core, self-hosting or C5.

## 15 October — Constructive IEEE mask proof milestone QUALIFIED

**Exactly qualified source and executable:** `7f2b68304d8aea26df08e3a75e7641cb12313d66`.
[Native Linux CI 38678408984](https://github.com/dwijayuda/pskernel/actions/runs/38678408984)
and independent [Float model replay 38678408985](https://github.com/dwijayuda/pskernel/actions/runs/38678408985)
both completed successfully at this SHA.

The pinned source now reconstructs Float32/Float64 exponent and fraction
masks through exact BitVec splitting and four constructive all-ones proofs
(widths 8, 11, 23 and 52), rather than `bv_decide`. Native
`Lean.collectAxioms` rejects any unapproved assumption in the new
mask/field theorem roots. The existing selected UInt32/UInt64 normalized
bit-helper behavior and cross-target regressions remain green.

**Strict portable boundary remains unchanged:** only the 17-root compact
Float proof closure (42 checked declarations, `propext`/`Quot.sound`)
is exported. Enlarged [research replay 38677739506](https://github.com/dwijayuda/pskernel/actions/runs/38677739506)
proved the new roots do not introduce `Classical.choice`, but rejected
924 upstream dependencies for actual `List.get` universe and `Int`
kernel-signature mismatches. Dependency diagnostics identified native
`BitVec.eq_of_getLsbD_eq` and extract/append proof bodies, which reach
`Lean.Omega` internals and then the mismatching declarations.

A separate `psc0/research-list-get-universe-v1` branch is testing a
coherent universe-polymorphic List.get implementation, without modifying
this qualified executable. Source Float construction, erasure, ABI and
backend floating execution are not enabled; F1-F4 and M2+A remain open.
No soundness, trust or assumption exception was granted.

## 15 October — F1 selected UInt mask semantics qualified at 9f0ffbaa

**Exact-commit qualification:** `9f0ffbaa5e88eb78265f0350a0dfca0b600a1c57`,
full [native Linux CI 38674864244](https://github.com/dwijayuda/pskernel/actions/runs/38674864244)
**passed**; independent [compact Float CI 38674864220](https://github.com/dwijayuda/pskernel/actions/runs/38674864220)
**passed**. The native model's `canonicalUIntMask64_eq_logical` and
`canonicalUIntMask32_eq_logical` prove that the selected UInt-land/Nat-beq
algorithm produces the same canonical bits as the Lean logical Float model
**for every UInt64/UInt32 input**. These are symbolic all-input proofs,
not finite test-only evidence.

**Newest native research improvement:** two short theorems connecting that
algorithm all the way to pinned upstream
`(Float.ofBits bits).toBits` and `(Float32.ofBits bits).toBits`
passed focused [Lean CI 38675504040](https://github.com/dwijayuda/pskernel/actions/runs/38675504040)
at `b6d67b913db6358116b0b3b905ea470ecd51d8c3`.
This new PR integration is **not itself qualified until its exact-commit
native/full CI succeeds**.

**Trust boundary unchanged:** The upstream and `bv_decide` native proof
closures transitively import `Classical.choice`; expanded portable roots
were correctly refused by [research replay 38674185003](https://github.com/dwijayuda/pskernel/actions/runs/38674185003).
Only the original 42-declaration compact model, with approved
`propext` and `Quot.sound`, is portably replayed. Native mask/upstream
theorems are NOT published selected Standard roots. Source-level Float
construction, typed erasure/IR, ABI and JS/TS/Rust/Wasm execution remain
unqualified and disabled. No F1–F4/M2+A completion claim.

**Next:** resolve F1 source constructors with a kernel-replayable portable
proof term and explicit erasure, without widening assumptions. Validate
target semantics and the remaining F2/F3/F4 obligations; keep kernel
replacement, bootstrap, self-hosting and C5 out of scope.

## 15 October — Native all-input Float correspondence QUALIFIED at d7d267bf

**Exactly qualified native executable:** `d7d267bf55b99ffc2a692075573b1bb96ae4f52c`.
Full [native Linux CI 38672491640](https://github.com/dwijayuda/pskernel/actions/runs/38672491640)
and independent [compact Float replay CI 38672491698](https://github.com/dwijayuda/pskernel/actions/runs/38672491698)
**passed** at this same commit. The separate native all-input source theorem
research completed at `343d1ef8074ab573fa38441a7bb2e8ad4d327b52`,
[focused Lean CI 38672309292](https://github.com/dwijayuda/pskernel/actions/runs/38672309292).

The host-only source proves for **all raw UInt64/UInt32 inputs** that pinned
upstream `UnpackedFloat.pack (unpack bits)` produces exactly the
`canonicalPacked` bit pattern. The exhaustive proof partitions NaNs, positive
and negative infinities, signed zeros, all subnormals and all normal
encodings. The corresponding native typed `fromBits64_eq_upstream_ofBits_all`
and `fromBits32_eq_upstream_ofBits_all` theorems check under Lean 4.35.0.

**Trust separation remains mandatory:** those upstream-dependent roots
transitively import `Classical.choice` (logged in native oracle CI).
They are **not** in portable `contractRoots` or selected Standard; the
independent compact portable candidate replay checked **42 declarations**
with `kernelChecked: true`, `axioms: []`, and
`importedAssumptions: ["propext","Quot.sound"]`. No new axioms,
fake proof evidence, source Float constructors, F2/F3 operations, ABI/runtime
Float support, or verified Float emission were enabled.

**Remaining F1 critical path:** establish an admitted selected source
constructor and safe proof erasure without importing `Classical.choice`
or the known incompatible upstream List/Int dependency graph, then
qualify JS/TS/Rust/Wasm/Wasmtime/ABI Float source observations. F2-F4
and the rest of M2+A remain incomplete. No pskernel-core, bootstrap,
self-hosting or C5.

## 15 October — F1 compact representation contracts qualified at 2f89b567

**Exact qualified executable:** `2f89b567586b8a21787df64609396e9ff742d32a`.
All steps of [native Linux CI 38662608990](https://github.com/dwijayuda/pskernel/actions/runs/38662608990)
and [F1 canonical-model research CI 38662609097](https://github.com/dwijayuda/pskernel/actions/runs/38662609097)
succeeded at this SHA. The qualification fixes the initially missing
`PsV7Host` Lake root; the earlier failed run 38662428954 was a missing
module build product, not a proof rejection.

The pinned Lean 4.35.0 oracle compiled the nine new representation theorems,
then the unchanged native/portable authoring policy independently replayed
**39 declarations** from the fourteen-root compact Float proof model.
The exporter reported `kernelChecked: true`, `axioms: []`,
`importedAssumptions: ["propext","Quot.sound"]`, with no quotient
primitives or replacement axioms. Exported candidate SHA-256:
`85add6c8006e4107db248f65537149b3596a3a0be965357783ea7ed019d02b9e`.
The full native workflow also passed its existing source, checked Standard,
JS/TypeScript/Rust/Wasm/Wasmtime, component and resource gates.
This qualifies the narrow *proof/representation candidate only*.
Neither Float construction in selected source nor Float arithmetic,
scientific conversion, ABI or cross-target floating execution is enabled.

**Independent unresolved requirement:** prove for every raw UInt64/UInt32
that the compact constructors exactly match the *upstream*
`Float.ofBits`/`Float32.ofBits` unpack/repack semantics. The checked
round trips only reconstruct already-valid Float values, not this
all-input equivalence. Do not bypass the previous full-upstream
List/Int dependency incompatibility, expand assumptions or publish
Float based on the 39-declaration compact closure alone.

**Next implementation critical path:** prove exact all-input upstream
correspondence; integrate checked F1 source construction and safe erasure;
then F2 arithmetic/equality, F3 scientific and numeric conversions, F4
JS/TS/Rust/Wasm/Wasmtime/ABI, explicit target-size USize/ISize through
the shared IR and all backends, and the remaining selected Phase A
environment/deriving/instance/import obligations. No completion claim;
no pskernel-core, bootstrap, self-hosting or C5.

## 15 October — F1 candidate CI identified missing Lake module root

At `28de17ebfc75f3071088543004c72c81c1b6c3d7`,
[Linux CI 38662428954](https://github.com/dwijayuda/pskernel/actions/runs/38662428954)
failed in the native compilation step because the new
`Ps.Host.FloatCanonicalContracts` module was imported but not listed
among the explicit `PsV7Host` Lake library roots. The error was a missing
`.olean` file, not yet a reported theorem/type error.
This follow-up adds the root to the existing host library without changing
the proof scripts, the frozen Standard or any trust policy.
The candidate remains unqualified pending exact-commit native compilation
and positive portable kernel replay; Float F1–F4 and M2+A remain incomplete.

## 15 October — F1 representation-contract integration candidate (not qualified)

**Last confirmed green executable:** `ffa1460341bc6e3ec24b8ede5c586743fb9f4abf`,
[Linux CI 38656809748](https://github.com/dwijayuda/pskernel/actions/runs/38656809748).
PR #109 and the branch HEAD were verified before authoring; no newer branch history was overwritten.

**Submitted source candidate:** preserve `Ps.Host.FloatCanonical` unchanged; add
nine native Lean proof scripts in `Ps.Host.FloatCanonicalContracts` for canonical
validity/fixed points, constructor bit representations, logical Float/Float32
reconstruction and equality through canonical bits. A single fourteen-root
roster now drives both the existing portable exporter and the native
transitive axiom audit. The existing positive research replay workflow builds
the oracle and checks out test sources. Existing selected Standard and runtime
capability refusals remain unchanged; the full upstream Float export remains
manual-only, with its previous List/Int incompatibility explicitly unresolved.

**Unqualified at this checkpoint:** this is an implementation candidate under
the existing CI gate, not nine proven theorems. No new Lean compilation,
portable replay, runtime correspondence, performance receipt or M2+A acceptance
has been verified for these changes yet. A compact model replay, if green,
would still not prove equality to upstream `Float.ofBits` for all raw bits.

**Next gates:** check the native proof scripts and entire roster with exact
Lean 4.35.0, reject every axiom outside `propext` and `Quot.sound`, replay
the compact closure through the existing portable kernel, then prove the
separate upstream all-input constructor correspondence. Subsequently close
Float F1–F4, target-explicit USize/ISize profiles and selected Phase A.
No pskernel-core, self-hosting, bootstrap, C5 or later milestones.

## 15 October — target-word semantic ownership and fast-gate policy

**Last qualified executable:** `f5f9c7f87b77d9700bc52ca02882ae1f1dbab73e`,
[27-gate Linux CI 38654008436](https://github.com/dwijayuda/pskernel/actions/runs/38654008436);
[canonical Float kernel replay 38654008396](https://github.com/dwijayuda/pskernel/actions/runs/38654008396) also passed.

**New candidate:** `Ps.CompilerIr.Model` owns the *only* typed-IR
USize/ISize width selector (`bits32`/`bits64`) and exact canonical signed/
unsigned literal range. `CheckTypes` delegates fixed-width validation to
the same policy while still refusing unprofiled target-sized IR. The JS
profile-specific literal path reuses the shared selector rather than
duplicating 32/64-bit numeric limits. A short native boundary suite checks
signed minima/maxima, unsigned limits, fixed width and absent-profile
rejection against pinned `Init/System/Platform.lean` and `Init/Data/SInt/Basic.lean`.
No platform word capability is newly admitted and no backend semantic
promise is inferred. The original upstream F1 import's **known negative**
research-only workflow remains dispatchable by hand but no longer runs and
fails on each ordinary source change; the successful small canonical-model
replay and main CI are unchanged.

**Remaining:** carry this explicit target profile through compiler IR
admission and each JS/TS/Rust/Wasm execution/ABI lane; implement Float F1-F4,
scientific, the remaining selected P0 APIs and complete assurance/manifest.
Do not claim M2+A finished. No pskernel-core, self-hosting or C5.

## 15 October — surface digest frozen and per-project source graph candidate

The selected source-surface SHA-256 from complete CI 38653018583
(commit 078ec135da8b205400ba14a8ac3d68ac3fd23f71) is now frozen
to sha256:0bc4bfaa0f9afb9e0c1c58d652c51db8732530cd1b50b9e8772cca90f5bac0cf.
That independent strict gate complements both existing FNV/SHA checks
over the underlying selected Standard Core/instances/aliases.

New candidate: the native --audit-project-graph command consumes the
same path-safe source manifest and source-owned imports as the real project
compiler, refuses duplicate/missing/cyclic dependencies, resolves a
deterministic topological order and entry reachability, and hashes
actual source bytes, imported module identities, source paths, and the
selected global Standard-surface SHA into one project source-graph SHA-256.
The three-module CI fixture now emits project-source-graph.json.
This is a source-graph identity receipt, not a kernel proof, published
ABI-equivalence claim, or full transitive Lean import manifest.
Full M2+A remains incomplete; no pskernel-core, self-hosting, C5.

## 15 October — canonical Float model replay qualified; full selected-surface digest candidate

The native Float canonical proof model produced 24 officially checked
portable declarations and **no new axioms** at
[research CI 38652410627](https://github.com/dwijayuda/pskernel/actions/runs/38652410627),
commit `42eb74a26121be7f355ca273a959d475c166a3a1`.
This does not enable runtime Float or resolve the original full F1
List/Int incompatibility. The normal 27-gate executable CI runs separately.

**New native Phase A manifest candidate:** record a canonical length-delimited
digest over the selected operator/notation table, the actual deriving
handler roster, selected tactics, source/elaboration effect policies,
module policies, and ordered checked instances with class/priority/universes.
The human-readable JSON reports the new surface SHA-256 and underlying strict
Standard SHA-256 independently. `--audit-standard-surface` and native CI
publish this artifact; its deriving registry is checked against the *actual*
elaborator-owned handler list. This is still a **selected** manifest, not
a claim of complete transitive Lean module imports, all available effects,
or a full compiled-language semantics proof. The per-project import graph
remains validated separately. No trust/instance/class extension and no
pskernel-core, self-hosting or C5.

## 15 October — reusable constructive Float proof-model candidate

The last green executable checkpoint is `1fd22ead9f5c32e57e189251be94db7c1245a542`,
[27-step CI 38648695550](https://github.com/dwijayuda/pskernel/actions/runs/38648695550).
A native all-bitpattern `Format.Valid` theorem and real Float32/Float64
constructors passed kernel, axiom and existing runtime regression gates.

**New unqualified authoring batch:** move this proof and constructors from
the native oracle into `Ps.Host.FloatCanonical`; add universal
`canonicalPacked_of_valid` and `canonicalPacked_idempotent` theorems.
An isolated research workflow attempts portable-kernel replay of this
small proof-bearing model against the unmodified frozen Standard, instead
of importing the 1,038-declaration original Float.ofBits dependency graph
that was correctly refused for List/Int model mismatches. Never weaken
the strict assumption allowlist or publisher. Source-level Float
construction, F2 arithmetic, F3 scientific syntax, F4 ABI/runtime and
full Phase A/M2+A remain unqualified. No pskernel-core/self-hosting/C5.

## 15 October — F2 bit equalities green; constructive Format.Valid candidate

The checked Float32/Float64 *bit-level* two-equality models passed all
[27 Linux CI 38647823991](https://github.com/dwijayuda/pskernel/actions/runs/38647823991)
steps at `ecdff92f3b59981f78aaadbf2c6022178d8ce8d3`.
IEEE Bool equality (NaN unequal, signed zeros equal) is kept distinct
from canonical logical bit identity (all NaN payloads normalized,
signed zeros distinct). Sixteen native-reference/cross-target observations
passed, without declaring source Float instances or additional axioms.

**Research-only next candidate:** direct constructive Lean 4.35.0 proof
for `Format.Valid spec (canonicalPacked spec bits)` for *all*
bitvectors in any permitted Float.Model.Format. The definition branches
on the original pinned `unpackExponent`/`unpackMantissa`, preserving
non-NaN bits and mapping NaNs to `packedNaN spec`. This avoids the
previous 1,038-declaration original Float.ofBits import and its
independently refused List/Int proof-model mismatch. The native oracle
also constructs actual Float and Float32 values with proof-bearing
model fields and checks a handful of reference bit patterns.

This does **not** publish Float.ofBits into the selected Standard, prove
all-input equivalence to the full original upstream ofBits, or qualify
JS/TS/Rust/Wasm floating runtime/ABI behavior. Strict transitive
assumption auditing forbids Classical.choice/sorryAx; kernel/erasure and
all native CI still apply. No pskernel-core, self-hosting or C5.

## 15 October — Float32/64 bit classification fully qualified; two equalities candidate

Commit `5bb8c9c9f3c731263d910cfed8eda394b1d75ac6` passed all
[27 Linux CI 38646612366](https://github.com/dwijayuda/pskernel/actions/runs/38646612366)
steps, qualifying four additional `isInf*` and `isFinite*` checked
UInt32/UInt64 bit helper declarations and sixteen shared target observations
against pinned native Lean 4.35.0 reference behavior. The earlier
`canonical*` and `isNaN*` helpers are unchanged, and full Float F1,
arithmetic and scientific syntax remain unimplemented.

**Next candidate only:** two distinct Bool-valued bit models per width:
`beqFloat32/64Bits` reflects upstream IEEE BEq (NaN never equal,
positive/negative zero equal, other canonical bit encodings compared);
`logicalEqFloat32/64Bits` models *canonical structural bit identity*
(NaN payloads normalize, signed zero distinct). Both use checked existing
UInt, Nat.beq and Bool.rec definitions with one shared recursion helper.
They **do not** supply an Eq proof or selected BEq/DecidableEq Float
instance and must pass separate native reference, kernel/erasure,
JS/TS/Rust/Wasm GC/Wasmtime and performance checks. The strict Standard
FNV/SHA changes must first be measured independently, never guessed.
Full M2+A remains open; no pskernel-core, self-hosting, or C5.

## 15 October — checked F1 bit canonicalization fully qualified; finite/inf candidate

Commit `832764c6ec47b34e330e25441c258c4f4cbcfe05` passed all 27
[Linux CI 38644795298](https://github.com/dwijayuda/pskernel/actions/runs/38644795298)
gates, including independent native official Lean 4.35.0 bit reference cases,
strict FNV/SHA review, kernel admissions, JS/TypeScript/Rust/Wasm GC/Wasmtime
and resource qualification. The four selected `PsStandard.isNaN*` and
`canonical*` UInt32/UInt64 bit definitions are executable and checked; no
`Float.ofBits` or floating arithmetic is published.

**New pending candidate:** extend the same generic native checked bit helper
family with four `isInf*` and `isFinite*` definitions. Their exact IEEE
predicates come from pinned Lean 4.35.0 `Float.Model.UnpackedFloat.unpack`:
all exponent bits set with a zero fraction is ±infinity; any exponent other
than all ones is finite (including signed zero/subnormals). The selected
`Float.Model.isFinite`/`isInf` delegates to this unpacked model. A
small independent pinned native oracle and 16 cross-target observations cover
±infinity, both NaNs, positive/negative zero and subnormals.

No Float constructors, proof fabrication, unchecked runtime cast, platform
word-size assumption, pskernel-core, self-hosting or C5 are involved.
**Do not qualify** until CI independently measures the new strict FNV/SHA
and the entire runtime/Wasmtime/performance gate passes. Full F1–F4 and
remaining M2+A are still open.

## 15 October — native checked Float32/64 bit canonicalization candidate

The upstream F1 export at
[research CI 38643459231](https://github.com/dwijayuda/pskernel/actions/runs/38643459231)
reached 1,038 original Lean declarations but *correctly refused* their
portable replay: the current selected List.get universe signature and
multiple Int addition/ordering theorem bodies differ from the upstream
kernel dependencies. This is a real architecture/semantic boundary, not
an opportunity to weaken checking or mark the full F1 import complete.

**New coherent F1 bit-layer candidate:** native
`StandardFloatCanonical.lean` contains four ordinary checked UInt32/64
helper definitions, shared by the entire runtime prelude. IEEE exponent
and mantissa masks normalize any NaN sign/payload to the positive quiet
NaN while preserving all non-NaN bits (including signed zero/infinity).
Their exact observable cases are checked against independent pinned
Lean 4.35.0 Float/Float32 native oracles and twelve common-source
JS/TS/Rust/Wasm observations. Neither a Float constructor, unchecked
Validity witness nor an executable float arithmetic operation is added.
The new Standard fingerprints require an independent CI observation,
then a full green native/backends/Wasmtime/performance run. Candidate only.

## 15 October — full Float proof-cut root collision corrected (candidate)

[Linux research 38642547802](https://github.com/dwijayuda/pskernel/actions/runs/38642547802)
independently replayed the unchanged two-declaration constructive theorem
successfully, then refused the larger F1 experiment because `Float.toBits`
is already in the selected checked Standard boundary. This refusal is
correct: a selected declaration must not be silently duplicated.

The native F1 authoring candidate now explicitly requires the selected
`Float.toBits` and `Float32.toBits` declarations to exist at the frozen
boundary and exports only the missing `ofBits/isNaN/isFinite` roots plus
the constructive theorem proof. Original `Nat.pow_eq_zero` is still cut
only as a theorem, all other dependencies remain checked, and the
allowed assumption list stays `propext`/`Quot.sound`. No executable
Float was enabled; the new full-F1 experiment remains **unqualified**.

## 15 October — checked Float-bit native reference vectors (qualification pending)

The independent theorem-only F1 authoring cut passed
[CI 38641629995](https://github.com/dwijayuda/pskernel/actions/runs/38641629995)
with two official-kernel/portable-kernel checked declarations and no new
axioms. Commit `8e42d13ff92f58872ae36639ff1cec7b46b9258d` also
passed all 27 [main native regression gates](https://github.com/dwijayuda/pskernel/actions/runs/38642547796)
after extending research entry points to the full F1 model graph.

This next **reference-oracle candidate** adds ten small independent
Lean 4.35.0 cases for NaN normalization, negative zero, subnormals,
IEEE Boolean BEq and distinct propositional equality. They are not
compiler Float support; target parity remains unqualified until F1–F4
complete. The full proof closure research is independently running
under the existing no-`Classical.choice` approval policy.

## 15 October — checked constructive theorem cut green; full F1 closure research

The isolated theorem-only authoring/export candidate passed
[Linux research CI 38641629995](https://github.com/dwijayuda/pskernel/actions/runs/38641629995)
at `4d1a4a5896471ea92c8a8fdce25b05de6e333bff`.
It generated two independently portable-kernel-checked declarations with no
new axioms; the official Lean 4.35.0 kernel checked the theorem type at the
original `Nat.pow_eq_zero` signature. `propext` and `Quot.sound` remain
the only permitted imported assumptions. This proves the authoring
replacement mechanism works, not yet that Float F1 is usable.

**Next experimental research candidate:** extend the same *theorem-only*
cut to `Float.ofBits/toBits/isNaN/isFinite` and Float32 counterparts.
The upstream `Nat.pow_eq_zero` dependency is closed at its original
theorem name and replaced with a separately checked constructive proof.
All further upstream definitions and proof dependencies must still be
replayed by the official native/portable kernels. Refuse unknown axioms,
unsupported dependencies and any target runtime emission; record independent
CI evidence before promotion. Float F1–F4, platform sizes and complete
M2+A/Phase A remain incomplete.

## 15 October — constructive Float F1 theorem green; proof-only exporter research

Commit `2677ba11f240f950c96be95e3ad5e9bf35b19393` passed all
[27 Linux CI 38636902147](https://github.com/dwijayuda/pskernel/actions/runs/38636902147)
checks, including the native Lean 4.35.0 theorem and strict transitive
`Classical.choice`/`sorryAx` refusal. Selected Standard and all
JS/TS/Rust/Wasm GC/Wasmtime behavior remained unchanged.

**Unqualified experimental authoring:** move the constructive theorem to
host-only `Ps.Host.FloatConstructive` and supply a theorem-only proof cut.
The official Lean native kernel must check signature definitional equality
with `Nat.pow_eq_zero`, then the portable kernel independently replays the
renamed proof with the existing approved assumption allowlist. A separate
research CI workflow qualifies this study; no F1 acceptance or executable
Float is implied. No new axiom, pskernel-core, self-hosting or C5.

## 15 October — selected Standard manifest qualified; F1 constructive oracle candidate

Commit `2f97571130954eeadb9d9941f0c8fb4bdfef81b8` passed all 27
[Linux CI 38635410220](https://github.com/dwijayuda/pskernel/actions/runs/38635410220)
steps. The host-only selected Standard surface manifest is now qualified:
live notation precedence audit (22 spellings), five deriving handlers, 19
proof tactic spellings, bounded effects, module policy, registered axioms
and the existing strict FNV/SHA roster. This is **selected**, not complete
Lean-wide module/notation/effect closure.

**F1 constructive research candidate (not qualified):** separately prove
the exact pinned `Nat.pow_eq_zero` logical statement in native Lean 4.35.0
using Nat constructor and positivity cases, then invoke the official
`Lean.collectAxioms` on its complete proof dependency graph, strictly
rejecting `Classical.choice` and `sorryAx`. Historical native F1 export
[CI 38543575033](https://github.com/dwijayuda/pskernel/actions/runs/38543575033)
reported the upstream path via a generated private `Nat.pow_eq_zero`
simp proof. Passing this independent proof does **not** authorize
replacement of upstream theorem bodies, construction of floats or changes
to the F1 publisher; those remain explicitly blocked until separate kernel
and runtime acceptance. No pskernel-core, self-hosting, C5 or new assumptions.

## 15 October — checked ByteArray copySlice fully qualified

Commit `e871e4024d7ca9e3e3b85adc2b028ea7f9c33173` passed
[Linux CI 38634048433](https://github.com/dwijayuda/pskernel/actions/runs/38634048433)
with all 27 steps. Source, exact optional `copySlice` argument, checked
`extract` delegation, independently frozen FNV/SHA, official kernel
replay, negative conformance, JS/TS/Rust, Wasm GC/Wasmtime and performance
gates all passed. This is the latest fully qualified executable checkpoint.

**Next manifest candidate:** native `Ps.Host.StandardManifest` validates
the existing strict Standard roster *and* the selected infix operator
spelling/precedence table against the live parser, records deriving and
proof tactics, bounded effects and module boundaries, and inventories actual
registered axioms separately from the approved source-proof assumptions.
It must pass its own CI. This is an auditable **selected** manifest, not
full Lean 4.35.0 or all M2+A: Float F1–F4/scientific, USize/ISize width
profiles, remaining deriving/search and complete imported notation/effects
still require implementation. No pskernel-core, self-hosting or C5.

## 15 October — append fully qualified; shared copySlice candidate

Commit `13595a906abec60b39dccf54567d83d53e730fa0` passed all
[27 Linux CI 38620235817](https://github.com/dwijayuda/pskernel/actions/runs/38620235817)
steps, qualifying the native checked `ByteArray.append` model, the
general Lean 4.35.0 model proofs, JS/TypeScript/Rust/Wasm GC, Wasmtime and
resource gates. This is the last **fully accepted executable checkpoint**
until newer independent CI evidence.

**Next candidate (not qualified):** implement `ByteArray.copySlice` as
a pure checked List/Array sequence of prefix, clipped source middle and
remaining destination suffix; refactor `ByteArray.extract` to reuse
`copySlice` as in pinned Lean 4.35.0. Preserve default
`exact : Bool := true` as real `optParam Bool true` and do not pretend
the capacity hint changes logical bytes or that packed runtime performance
is implemented. Add all-input native Lean proof that exact true/false
produces the same logical result, plus bounded source/oracle/runtime cases.
Keep the unchanged strict registry guard until independent CI measures both
new fingerprints. No new axiom, pskernel-core, self-hosting or C5.

## 15 October — list conversion/extract fully qualified; append candidate

Commit `070d7d4d2c72b52cecc39f576128119ed2261b19` passed
[Linux CI 38618782594](https://github.com/dwijayuda/pskernel/actions/runs/38618782594),
all 27 gates (official Lean, replay, strict registry, native oracle,
direct JS/TS/Rust, Wasm GC/components/Wasmtime, performance). Selected
`List.toByteArray` and `ByteArray.extract` are now the last **fully
qualified executable** extension; no packed-buffer performance claim.

**Next pending candidate:** `ByteArray.append` follows the exact native
Lean 4.35.0 `Init/Data/ByteArray/Bootstrap.lean` logical expression:
`⟨⟨a.data.toList ++ b.data.toList⟩⟩`, reusing checked List.append
and List.toArray without a new backend primitive. General native
Lean proofs of list-to-byte-array representation and append
definitional equality complement three shared target observations.
Do not promote until separate strict FNV/SHA review and full CI.
Remaining Float F1–F4, USize/ISize profiles, selected deriving/search,
and comprehensive Standard manifest are still open.

## 15 October — qualified toList and next checked conversion/slice candidate

Commit `314b0cd67d70a4664da1957fd96f4676ad6e1524` passed all 27
[Linux CI 38616800244](https://github.com/dwijayuda/pskernel/actions/runs/38616800244)
steps: the selected logical `ByteArray.toList` passed official kernel,
strict FNV/SHA, native oracle, shared JS/TS/Rust/Wasm GC/Wasmtime and
performance gates. It is the last fully green executable checkpoint.

**Next candidate only:** add the Lean 4.35.0-pinned
`List.toByteArray : List UInt8 → ByteArray` and
`ByteArray.extract : ByteArray → Nat → Nat → ByteArray`.
Use checked List/Array conversions and `take (stop-start) (drop start xs)`
for exact half-open, bounded index semantics; no packed-buffer shortcut,
unchecked assumption, new kernel, self-hosting or C5. Native oracle and
shared-target cases cover order, empty/reversed range and out-of-range stop.
Qualify independently; the next registry FNV/SHA must be measured by
strict CI before updating its expected values. This new slice is not green.

## 15 October — checked ByteArray indexed API fully qualified

Commit `05d4c1cec39bf7cb93089041982e60f802563c5d` passed all 27
[Linux CI 38607736899](https://github.com/dwijayuda/pskernel/actions/runs/38607736899)
steps. The approved selected Standard fingerprint is FNV
`fnv1a64:18073559988743207974`, SHA-256
`sha256:bbf06e5a2091c8cb1af14a0b7c35177b9ce029aea402e853072cccc1d43abfac`.
Native Lean checked the proof-indexed `ByteArray.get`/`set`, genuine
`GetElem ByteArray Nat UInt8`/`GetElem?`/`LawfulGetElem` dictionaries,
registered instances and metadata. Independent native checks and shared
JS/TypeScript/Rust/Wasm executions (including Wasmtime) passed. It is the
last fully qualified executable checkpoint until a newer run succeeds.

**Next checked candidate:** the logical `ByteArray.toList` conversion
reuses the existing checked Array/List representation and has bounded
native / cross-target observations. It remains pending full kernel,
registry, erasure, runtime and performance qualification. The logical
construction alone is not a proof of general equivalence with Lean's
native optimized toList loop.

Outstanding M2+A: further pinned collection APIs; Float/Float32 F1–F4
without unapproved `Classical.choice`; explicit USize/ISize profiles;
selected deriving corner cases; remaining instance/search fidelity;
a reproducible complete Standard module/notation/effect/assumption
manifest. No pskernel-core, self-hosting or C5 has been started.

## 15 October — ByteArray cross-target green and indexed API next

**Last fully qualified executable:** `4ae7631c18ef9062f8a552015624b6af2d2a341d`;
[Linux CI 38606086921](https://github.com/dwijayuda/pskernel/actions/runs/38606086921)
passed all 27 steps, including official Lean 4.35.0 checking, both strict
Standard fingerprints, native ByteArray oracles, source and negative
conformance, JS/TS/Rust runtime, Wasm GC/components/Wasmtime and
resource measurements. The earlier Standard drift and JS top-level
initialization ordering were corrected without bypassing checks; the
shared Wasm trap oracle now preserves the checked UInt8 result type.

**New pending candidate:** native proof-indexed `ByteArray.get` and
`ByteArray.set` plus real checked `GetElem`, `GetElem?` and
`LawfulGetElem` instances and minimal independent source/runtime cases.
The existing checked Array and index-lawfulness machinery are reused.
This new slice is **not qualified** until its *own* strict registry
and full cross-target CI run succeed; new fingerprints must be measured,
not inferred from the previous green. Continue other M2+A tasks only
while retaining the green baseline and strict assumptions boundary.

## 14 October — ByteArray checked read/write, equality and defaults candidate

Pinned Lean 4.35.0 `Init/Data/ByteArray/Basic.lean` declares
`ByteArray.get!`, `set!`, `isEmpty`, `beq` and an
`Inhabited ByteArray` instance. A new portable native
`StandardByteArrayCollection.lean` maps these through the already
checked `Array.get!Internal`, `Array.setIfInBounds`,
`Array.toList`/`List.beq`, `Nat.beq` and the ordinary
Inhabited dictionary. The `BEq` instance compares canonical bytes,
not host object identity. Ordinary checked declarations and explicit
instance indexes preserve class ownership; there is no new primitive,
unchecked cast, duplicate array datatype, or kernel assumption.

Seven native oracle checks and eight common-source JS/TS/Rust/Wasm
observations cover successful byte reads and replacements, preserved
contents after out-of-bounds writes, empty/nonempty tests, defaults,
and equal/different byte sequences. A fifth negative runtime panic
contract checks `get!` out of bounds. **Candidate only:**
do not promote until the native source and kernel audits, independent
FNV/SHA drift measurements and every existing runtime/Wasm/Wasmtime
gate pass. Generalized `GetElem` proof and optional-index APIs,
packed-buffer optimization and remaining ByteArray methods are
separate Phase A obligations.

## 14 October — ByteArray baseline fully qualified

Commit `a92f5ad8a0670d0077ec47080d75446675ab90fc`
passed [native CI 38596014627](https://github.com/dwijayuda/pskernel/actions/runs/38596014627).
Selected Standard: 1,803 declarations, 25 classes, 221 instances,
629 JS/TypeScript/Rust common-source observations, 175 native
integer oracle values, seven strict IR refusals and a separate
ByteArray empty/push/size/data native oracle. Wasm GC and Wasmtime
component/host, source admission, recursor metadata, strict digest
and existing performance checks passed. FNV
`fnv1a64:3178543072286617803`, SHA-256
`sha256:6d0c19b50e0074b4cd59361c25a4d3c3630da49855c39e6615994b9da73ebe48`.
The packed-byte runtime optimization is not claimed; ByteArray is
still erased as a distinct checked one-field structure. M2+A,
Float F1-F4, platform words and full Phase A manifest remain open.


## 14 October — native ByteArray structure and basic APIs (candidate)

Pinned `Init/Prelude.lean` and `Init/Data/ByteArray/Basic.lean` in
Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`
define ByteArray as a separate one-field structure holding
`Array UInt8`, with an externally optimized packed byte buffer.
The new native portable `StandardByteArray.lean` models its real
inductive constructor/recursor, `data` projection, checked
`emptyWithCapacity`, `empty`, `push` and `size`. It reuses
the existing selected Array logic, including capacity being only an
allocation hint, rather than adding a second array primitive.
No axiom, unchecked cast, self-hosting or pskernel-core code.

Three source/target observations and a native three-case oracle
cover empty size, two pushes and retrieved byte; see
`docs/PSCV0_A_BYTEARRAY_2026-10-14.md`. **Not yet qualified.**
Keep native signature/reducibility, constructor/recursor metadata,
strict FNV/SHA, source erasure, JS/TS/Rust/Wasm GC/Wasmtime and
performance gates unchanged. Packed-byte backend optimization is
a separate runtime fidelity/performance qualification, not assumed.

## 14 October — Lean Sum two-constructor baseline qualified

Commit `e055b2e5340eab08d4acc569355e2e022b023e9e` passed
[Linux CI 38594035519](https://github.com/dwijayuda/pskernel/actions/runs/38594035519).
Selected Standard: **1,795 declarations / 25 classes / 221 instances**;
626 shared JS/TypeScript/Rust observations and 2 independent
native Sum constructor/match oracle cases. Wasm GC, Wasmtime
component/host and all mandatory native kernel and syntax checks
passed. Lean-compatible `Sum` preserves its independent `u/v`
and recursor `w` universes. FNV
`fnv1a64:14927995082305765806`, SHA
`sha256:f77eb6d54d68a9f3036d0d69213f5f45f5d0e1f688e93f347c97466f9226ae53`.
This is bounded evidence, not full M2+A/Phase A completion.


## 14 October — native Lean 4.35 Sum type/recursor candidate (not yet qualified)

Official Lean 4.35.0 `Init/Core.lean`, pinned
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, defines
`Sum (α : Type u) (β : Type v)` as a two-constructor disjoint union.
`StandardSum.lean` adds the actual kernel inductive, `Sum.inl`,
`Sum.inr` and dependent `Sum.rec`, retaining the independent
element universes, motive universe, exact constructor indices and
two one-field minor premises. Source uses the ordinary `match` and
typed erasure paths already qualified for Option/Except rather than
inventing a new syntax or target-specific union representation.
See `docs/PSCV0_A_SUM_CORE_2026-10-14.md`.

Two native Lean and shared JS/TS/Rust/Wasm source observations cover
both constructors and match branches. **Candidate only** until the
official-kernel constructor/recursor/iota replay, native signature
audit, independently measured strict registry fingerprints and full
target/component CI pass. No new axioms, pskernel-core, C5 or
self-hosting. Float F1-F4, platform-sized integers, ByteArray and the
complete Phase A manifest still remain outside this narrow slice.

## 14 October — unsigned Nat saturation qualified

Commit `893e323dda53a741f78c6de707b12ac05e42587b`, full
[Linux run 38592521197](https://github.com/dwijayuda/pskernel/actions/runs/38592521197),
passed kernel checks, source/asset audits, direct JS/TypeScript/Rust,
Wasm GC/Wasmtime and performance gates. Selected Standard:
1,791 declarations, 25 classes and 221 instances. The same 624
shared runtime observations passed across native targets and 175
native Lean scalar oracle cases plus seven IR negative checks passed.
`UInt8/16/32/64.ofNatClamp` saturate to the largest representable
value; deprecated `ofNatTruncate` is the same clamp, **not** a
wrapping alias. FNV `fnv1a64:10558131214179396941`;
SHA-256 `sha256:5385a2bab77090b84ce8c7483be0c88726ed8a9382b739078d741e07f7d6ac50`.
No trust expansion or change to the native .lean-only policy.


## 14 October — native unsigned saturating conversions candidate

Source study: pinned official Lean 4.35.0
`Init/Data/UInt/BasicAux.lean` and `Init/Data/BitVec/BasicAux.lean`,
commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Unlike `UIntN.ofNat` (wrapping), `UIntN.ofNatClamp` saturates:
`n < 2^width ? n : (2^width - 1)`. In the same pinned version,
`UIntN.ofNatTruncate` is a deprecated synonym for the clamp,
not the ordinary wrapping conversion.

The selected candidate builds eight checked `.lean` definitions for
four fixed unsigned widths using existing `Nat.lt`/`Nat.decLt`,
`ite` and `UIntN.ofNat`. Sixteen pinned native Lean and
common-source JS/TypeScript/Rust/Wasm observations cover zero,
largest representable value, first overflowing Nat and the alias.
No new axiom, unchecked runtime operation, compiler backend or
platform-sized assumption. **Pending** fresh official kernel replay,
native metadata audit, independent strict FNV/SHA snapshot measurement
and all full Linux runtime gates before qualification.

## 14 October — unsigned power and wrapping-ofInt fully qualified

Commit `b28ccbe8ddf0fc6528bbae04e50a2f485373121b` passed
[Linux 38590570467](https://github.com/dwijayuda/pskernel/actions/runs/38590570467).
The selected Standard contains 1,783 declarations, 25 classes and
221 instances; 608 shared JS/TS/Rust runtime observations and
159 independent native fixed-width reference cases passed, alongside
seven strict IR refusals, Wasm GC and Wasmtime component gates.
Both checked power-recursion and Int-wrapping builders are shared
between the four signed and four unsigned widths. Frozen FNV
`fnv1a64:16486742924065107304` and SHA-256
`sha256:c991c6c6f80bc9575c0d1a9dcaf89816380469464fd9424b063aec7bbeeaf2ed`.
This does not complete M2+A, Float F1-F4, USize/ISize or the
comprehensive Phase A/standard manifest. No pskernel-core or self-hosting.


## 14 October — unsigned power and Int wrapping source candidate (not qualified)

Official Lean 4.35.0 `Init/Data/UInt/Basic.lean` defines
`UInt8/16/32/64.pow` by primitive recursion on Nat and
`UInt8/16/32/64.ofInt` by nonnegative remainder modulo `2^width`.
The native-only `.lean` closure adds the four UInt powers and four
unsigned `ofInt` constructors without a compiler primitive or
new foundation assumption. Reuse exactly the already checked Core
builders for the corresponding signed word methods:
`psStandardFixedWidthPower` and `psStandardWrappingOfIntDeclaration`.
The signed declarations retain identical ordered binder/recursor terms
and their original reducibility status.

Twenty-one independent native Lean reference values and twenty-one
common-source JS/TS/Rust/Wasm vectors cover exponent zero, modulo-width
overflow, negative Int wrapping and 64-bit boundaries. Structural
recursion uses the same typed erasure as the qualified signed methods.

**Candidate only:** no new Standard fingerprints are guessed. Independently
measure the strict FNV/SHA refusal, retain official kernel/source audits,
then pass the complete native, JS/TS/Rust and Wasmtime component workflow.
This does not complete Phase A, Float F1-F4, USize/ISize or the v7
assurance scope. No pskernel-core, self-hosting or C5.

## 14 October — unsigned fixed-width LT/LE qualified

Commit `2021d7cd673622aacaf528b1161654393403fa4d` passed
[Linux 38588137709](https://github.com/dwijayuda/pskernel/actions/runs/38588137709):
1,775 checked declarations, 25 classes, 221 registered instances,
587 shared target runtime observations, 138 pinned native word oracle
values and seven strict typed-IR refusals. Checked `UIntN.lt/le`,
`UIntN.decLt/decLe` and explicit LT/LE dictionary registrations
preserve the unsigned bit-carrier order at every fixed width, with
no additional axiom. FNV `fnv1a64:8114939059249220600`, SHA-256
`sha256:fd5b96380ccec059f57a3210374cad31778d93d720be913508ddfb4f1edb12f8`.
This is bounded runtime differential conformance, not compiler-wide
semantic preservation.


## 14 October — unsigned machine comparison source/decision candidate

Pinned official Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`:
`Init/Prelude.lean` defines `UInt8.lt/le/decLt/decLe`, and
`Init/Data/UInt/Basic.lean` defines the corresponding 16/32/64-bit
families over `BitVec`. The unsigned carrier `UIntN.toNat` preserves
their unsigned order; the existing checked Nat comparisons and
`Nat.decLt/decLe` provide their portable propositions/decisions.

`StandardUnsignedOrder.lean` stages 8 checked relation declarations,
8 checked deciders, 8 ordinary LT/LE dictionary definitions and explicit
class/Decidable registrations, with no new axiom, trust permission or
target-specific primitive. The native oracle and the common-source
JS/TypeScript/Rust/Wasm observations exercise 16 unsigned equal/extreme
and reversed-order boundaries, including the full UInt64 range.
This is a coherent native `.lean` feature family, not a new backend.

**Not qualified:** independently capture any actual strict FNV/SHA
registry drift, preserve signature/reducibility and native-kernel replay,
then require every Linux/source/target/Wasmtime gate to pass before
promotion. M2+A, F1-F4 Float, explicit platform-width ABI and full Phase A
manifest/library closure remain open. No pskernel-core, self-hosting or C5.

## 14 October — Bool-to-fixed-width stage fully qualified

Commit `aab53c217d244884c39a13436db7fef5ed1815eb` passed
[Linux 38586225475](https://github.com/dwijayuda/pskernel/actions/runs/38586225475):
1,751 declarations, 25 classes, 205 instances, 571 common-source
runtime observations across JS, TS7 and Rust, official kernel checks,
V8/Wasmtime GC component and linked-project qualification. The checked
Bool recursor supplies all eight fixed-width conversions with no new
assumptions; shared observation marshalling preserves unsigned scalars.
Native signed oracle: 122 reference cases and seven strict typed-IR
refusals. The result is bounded and does not imply M2+A completion.


## 14 October — signed M2+A order/numeric fully qualified

Executable commit `930e48d330d5d67da0911eba083a83aa730ef70d`,
[Linux run 38583446893](https://github.com/dwijayuda/pskernel/actions/runs/38583446893)
passed all native/kernel, strict-source, JSON/WIT/WAT/Wasm GC component,
V8/Wasmtime, TypeScript 7, direct JS, Rust, and performance CI steps.
**1,743 declarations, 25 classes, 205 instances; 555 shared runtime
observations; 106 native Lean signed oracle values and seven negative
typed-IR checks.** Snapshot FNV `fnv1a64:4732508156583495274`;
SHA-256 `sha256:4b7d09a378f650f9b5a3fc0ecf28553331380a3f7dfde07a6980d0fce2608222`.
Native Lean metadata audit requalified all signed order deciders as
`instance_reducible` and signed size/extrema abbreviations as
`reducible`. The changed root families and cross-target observations
passed without adding any axioms, pskernel-core or self-hosting.

## 14 October — native Bool-to-eight-fixed-word conversions (candidate only)

The new portable `.lean` module composes exactly the native Lean
4.35.0 `Bool.toUInt8/16/32/64` and `Bool.toInt8/16/32/64`
true/false equations using the already checked Bool.rec and word
constructors. Eight ordinary definitions enter selected Standard and
the shared executable prelude; sixteen native Lean/runtime observations
test both possible inputs for every target width. No new primitive,
axiom, backend-specific operator, source edition or target-size promise.

**Unqualified until:** first compile and official metadata/source audit,
independently observe strict FNV/SHA registry drift, pin unchanged guard
values, and pass the full existing multi-target Linux pipeline. Float
F1-F4, explicit USize/ISize profiles and full Phase A manifest/libraries
remain separate exit gates.


## 14 October — native signed numeric boundaries and power candidate

Study: Lean 4.35.0 pinned `Init/Data/SInt/Basic.lean`.
The existing checked `IntN.ofNat`, `IntN.mul` and `Nat.rec`
provide one ordinary portable Lean construction for four widths'
`size`, `minValue`, `maxValue` and `pow`. Power follows the
actual upstream recursion equations, and minimum and maximum are
two's-complement residues at the sign bit boundary. This adds sixteen
portable Core declarations in one new native `.lean` module rather
than backend-specific numeric operator cases. Runtime support reuses
the existing target-neutral IR, and twenty signed-boundary/power
vectors are independently specified by native Lean 4.35.0 and the
shared runtime observations.

**Candidate, not qualified:** preserve the strict FNV/SHA guards
until CI independently measures the new selected Standard, then
fully requalify JS/TS/Rust/Wasm GC/Wasmtime and official native
replay. If a structural Nat recursion cannot be lowered faithfully,
do not replace it with a guessed primitive or weaken source checks.
This does not activate platform-sized integers or float F1-F4, and
does not start pskernel-core, compiler self-hosting or C5.


## 14 October — signed < / ≤ / LT/LE and native deciders (qualification pending)

Pinned Lean 4.35.0 `SInt/Basic.lean` defines each fixed-width
`IntN.lt/le` using `BitVec.slt/sle`. `BitVec.slt/sle` compare the
two's-complement mathematical values. The native portable
`StandardSignedOrder.lean` implements their exact finite-width ordering
using sign-biased canonical Nat carriers and existing kernel-checked
`Nat.lt/le/decLt/decLe`. It adds per-width checked `lt/le` propositions,
`decLt/decLe` decisions and ordinary `LT/LE` dictionaries, with
explicit class and Decidable registration. No new axiom, runtime
primitive, parser-specific dispatch, pskernel-core, self-hosting or C5.
The 16 differential native Lean and shared-target observations cover
minimum/maximum, equal, negative/positive and reversed-order boundaries.

**Candidate only.** Confirm the exact checked native signatures, strict
independently observed Standard fingerprints, source/IR erasure and
full JS/TS/Rust/Wasm GC/Wasmtime CI before promoting this scope.
Native class relations and actual source operation semantics remain
subject to qualification; backend preservation remains bounded evidence.
F1–F4 Float, portable size, general Phase A manifest, other M2 work
remain incomplete.

## 14 October — signed abs stage qualified

Commit `f6d70dfbb256c1ca19a402eb75c8d28b9d568a74` passed
[Linux CI 38578021600](https://github.com/dwijayuda/pskernel/actions/runs/38578021600).
Qualified Standard: 1,703 declarations, 23 classes, 189 instances;
519 shared runtime observations in JS/strict TS/Rust, native 70 SInt
values plus seven typed IR refusals, Wasm GC and Wasmtime component,
all ordinary Linux steps. Measured FNV
`fnv1a64:8243444543599524808`, SHA-256
`sha256:bcd5911445946ad2960d1ac35861dbb009e577985e51679db83ec82c940361b3`.
The four checked `IntN.abs` definitions preserve minimum signed
wraparound; this is bounded, not whole-compiler proof evidence.


## 14 October — checked signed fixed-width abs candidate (qualification pending)

Pinned Lean 4.35.0 `BitVec.abs` is sign-conditional fixed-width
negation; `Int8/16/32/64.abs` preserve the minimum signed value.
The new native portable `.lean` module composes the existing checked
unsigned carriers, `Nat.lt`/`Nat.decLt`, `ite` and `IntN.neg`
and registers four ordinary definitions in the selected Standard and
runtime support. No new target primitive, axiom, `pskernel-core`,
self-hosting or C5 code. Twelve signed-extrema, -3, positive-boundary
values are checked against the independent pinned native Lean oracle
and by common-source JS/TypeScript/Rust/Wasm observations.

**Not yet qualified:** Require actual compiled drift values for the FNV/SHA
registry guards and complete green Linux CI before claiming this stage
as implemented and released. Native signed comparison classes and
deciders, Float F1-F4, platform size and the Phase A manifest remain open.

## 14 October — signed Nat clamps qualified

Commit `e0a86361b53b0b2688e26ab6aeae20f4a1a7c560`
passed [Linux CI 38576409867](https://github.com/dwijayuda/pskernel/actions/runs/38576409867):
1,699 declarations / 23 classes / 189 instances, 507 JS/direct-JS/TS/Rust
shared observations, native oracle 58 signed values plus seven strict
IR refusals, qualified Wasm GC/Wasmtime component and host. The independently
measured strict registry values were FNV
`fnv1a64:9945284948184117163` and SHA-256
`sha256:fb98de4265c1206139fd2859f317de035156391bc926c0ee3f8f3b01147b9056`.
This evidence qualifies the four signed `toNatClampNeg` methods within
the declared executable scope, not M2+A or full v7.


## 14 October — four checked signed Nat clamping methods (qualification pending)

An M2+A native portable `.lean` stage implements Lean 4.35.0
`Int8/16/32/64.toNatClampNeg`, using exactly the already selected
kernel-checked `IntN.toInt` and `Int.toNat` bodies. Twelve values
at the signed limits, zero and minus one are covered both in the
pinned native Lean oracle and in shared JS/TS/Rust/Wasm observations.
There is no new trusted assumption, extra runtime primitive, host-width
dependency, `pskernel-core`, self-hosting or C5 feature.

**Pending:** Native official-kernel qualification, independently observed
FNV/SHA Standard fingerprint drift and the complete Linux backend gates.
Do not claim this candidate qualified until the new exact digests are
measured and full CI passes. The preceding selected signed-shift stage
passed all Linux gates at `86faead` in
[Actions 38569444828](https://github.com/dwijayuda/pskernel/actions/runs/38569444828).
Signed comparisons, Float F1–F4, portable target-sized integer profiles and
comprehensive Phase A exit remain open.


## 14 October — signed shift candidate; ofInt now qualified

The four wrapping `Int8/16/32/64.ofInt` declarations are **fully green** at commit `75b8787584339f3ea54d5b673aa3211f37589329`, [Linux 38567308280](https://github.com/dwijayuda/pskernel/actions/runs/38567308280). Selected Standard 1,687 declarations, 23 classes, 189 instances; independently measured FNV `fnv1a64:18408272372580449619` and SHA-256 `sha256:52a6343fe02345259225f17386182d73cf452bb6df5b44987e79b80468aee543`; 479 JS/TS/Rust shared observations, Wasm GC and Wasmtime component host qualified. Pinned native Lean signed oracle 30 values, seven typed-IR negative checks.

**New candidate, NOT yet qualified:** Int8/16/32/64.shiftLeft/shiftRight via constructive fixed-width Nat arithmetic that implements the pinned signed shift count `b.toBitVec.smod width` using bit-pattern modulo (width divides 2^width), modulo-width left shift, and arithmetic right shift with high-bit sign fill. Generic typed signed machine shifts already exist in JS/Rust/Wasm and are enabled in signed erasure; 16 official native Lean reference cases and 16 source/executable all-target vectors were added. Any snapshot drift must be independently observed, the root causes of any failures resolved, and full CI green before claiming support. No new axioms, extra TCB, host-width assumption, pskernel-core, self-hosting or C5.

## 14 October — M2+A signed ofInt candidate (qualification pending)

Last fully green branch HEAD is `b4f52e25973d1c9e5623ed8f247757b739a9939d`, [Linux 38564371025](https://github.com/dwijayuda/pskernel/actions/runs/38564371025): strict selected Standard 1,683 declarations / 23 classes / 189 instances, independently checked FNV `fnv1a64:12853239104520417295` and SHA-256 `sha256:7b6a29baea2279dc88dd94de1635937a23befd79830330874daeb5fdad778c43`; 467 common-source runtime observations through JS/TS/Rust, Wasm GC and Wasmtime qualification passed. The preceding signed `toInt` semantic drift and source-newline failures have been resolved without relaxing any guard.

**New candidate pending strict native kernel and all-target qualification:** four explicit `Int8/16/32/64.ofInt` definitions using the existing checked `Int.rec` and modular `IntN.ofNat/neg` closure, with independently expected native Lean integer-boundary oracle cases and common-source runtime comparisons. This is a proposed constructive implementation of the pinned BitVec two's-complement wrapping semantics; its open-term semantic equivalence is not yet a separately verified theorem. Do not call it qualified until strict independent source/snapshot/kernel and JS/TS/Rust/Wasm/Wasmtime checks pass. No new axioms, target-size assumptions, full C5, pskernel-core, self-hosting or trust changes. Remaining signed shifts/comparisons, Float, explicit size profiles, and Phase A exit criteria remain open.

## M2+A selected signed-to-Int snapshot — independently observed (14 October 2026)

The native Lean 4.35.0 kernel compiled all four `IntN.toInt` implementations and the source-model equality certificates at `09965258ad0fb0c206fe7ea7a0386241b5078496`. The pinned semantic audit independently refused a missing `implicit_reducible` status at `6fe1a56`; commit `09965258` corrected it to the exact upstream metadata without relaxing any checks. [Linux 38563557310](https://github.com/dwijayuda/pskernel/actions/runs/38563557310) then correctly refused the previous Standard fingerprint and independently observed **FNV `fnv1a64:12853239104520417295`** and **SHA-256 `sha256:7b6a29baea2279dc88dd94de1635937a23befd79830330874daeb5fdad778c43`**. Both are now pinned unchanged in the strict registry guards. The projected selected Standard is **1,683 declarations, 23 classes, 189 ordered instances** (previously 1,679 declarations). The four definitions add no search instance or axiom and are generated from the identical native `BitVec.toInt` two's-complement formula. **Full execution qualification is still pending**: next Linux run must pass ten common-source conversion vectors and all other JS/TS/Rust/Wasm GC/Wasmtime checks. Last fully green is the earlier `fe88e7f` signed/bitvector model proof checkpoint (27 steps, 457 runtime observations). Signed shifts, comparisons, `IntN.ofInt`, Float, platform-width integers and comprehensive Phase A exit remain incomplete.



## M2+A native-checked signed toInt conversion stage — pending independent qualification

Pinned Lean 4.35.0 `BitVec.toInt` defines mathematical signed conversion
using exactly `if 2 * encodedBits < 2 ^ width then encodedBits else
encodedBits - 2 ^ width`. Four kernel-definitional-equality (`rfl`)
certificates are accepted at `fe88e7fcd388ef036f64dd03228574cf5c7efcf9`
([Linux run 38562328951](https://github.com/dwijayuda/pskernel/actions/runs/38562328951)).
`StandardSignedToInt.lean` now implements that precise formula over the
already checked unsigned `UIntN.toNat`, `Nat.mul/Nat.lt/Nat.decLt`
and `Int.ofNat/Int.sub` Core definitions using a single explicit
`ite` with native decision evidence. It adds four checked definitions,
with no external proof import, axiom, untrusted cast or new search instance,
and includes them in runtime support. Ten common-source JS/TS/Rust/Wasm
comparison vectors cover zero, sign transition, min and max for every
fixed width, including 64-bit extremes. **This integration still
requires the independently observed FNV/SHA registry update and full
Linux runtime and native-kernel requalification; it is not yet a
qualified release.** Platform-width Int and Float remain separate.


## M2+A signed dictionary candidate — independently measured strict registry (14 October 2026)

Linux [run 38556955048](https://github.com/dwijayuda/pskernel/actions/runs/38556955048)
at `a4fdce4089f544311487048c6d773e4754eff1d7` compiled
the complete new signed dictionary source, regenerated all prior
reviewed logical assets, and correctly refused the outdated Standard
hashes before source/runtime admission. The newly observed selected
Standard fingerprints are **FNV
`fnv1a64:11697716145196202262`** and **SHA-256
`sha256:47b1598e2faa1ccbe80d183aeeaaa9f1a5444d1fd2878ae40f4bbe21c3d25cc4`**.
These exact independent values are now pinned in both strict snapshot
guards; **the new stage is not yet fully qualified**. Its 36 checked
HAdd/HSub/HMul/HDiv/HMod/Neg/OfNat/BEq/Inhabited dictionary declarations
and 36 explicit registrations should extend the preceding
1,643-declaration /23-class /153-instance roster; do not assert
new counts or cross-target parity until the next full green Linux run.
The previous fully green accepted executable remains `514f537`,
[CI 38555495881](https://github.com/dwijayuda/pskernel/actions/runs/38555495881)
(448 shared observations, native Lean signed oracle, V8 GC and Wasmtime).
No new axioms, psKernel-core, self-hosting, or Float-ofBits approval.



## M2+A signed typeclasses: current authoring/qualification checkpoint (14 October 2026)

**Latest fully green native four-width signed runtime:** `514f53785b7c2aa1717d000efa5c64a08ccfe9a8`,
[Linux 38555495881](https://github.com/dwijayuda/pskernel/actions/runs/38555495881).
All 27 Linux steps passed, including the official Lean 4.35.0 oracle (22
signed bit-level vectors, seven strict IR negative checks), **448 shared
JS/strict TS/Rust runtime observations**, full signed GC Wasm/Wasmtime
component interop, WIT s8/s16/s32/s64 scalar flattening and round trips.
The selected Standard remains **1,643 declarations / 23 classes / 153
instances**, strict FNV `fnv1a64:2992617569121253333` and SHA-256
`sha256:4fc70a9fac595be03500185122459263e1a9e75141bc8fd39a680785d682e8a3`.
This is bounded differential evidence, not a formal backend-preservation proof.

**New checked generic signed typeclass stage (qualification pending):**
ordinary portable Lean dictionaries now provide HAdd/HSub/HMul/HDiv/HMod,
Neg, OfNat, BEq and Inhabited for all four pinned Int8/16/32/64 logical
wrappers, reusing precisely the general unsigned architecture and the
kernel-checked signed methods. BEq compares the canonical unsigned carrier
as Nat (sign-independent bit identity); Inhabited uses checked zero.
The stage adds **36 dictionary declarations and registrations** to the
selected environment and executable prelude, without extending the trusted
axiom set. Source fixture exercises generic operators, negative/literal
syntax, equality and defaults. **Do not mark the new selected stage qualified
until its strict fingerprint is independently observed and its full Linux
regression passes.** Signed shifts/lt/le/Int-valued conversions, ISize/USize,
Float ofBits/BEq/arithmetic/scientific and remaining Phase A manifest/library
closure remain open. No pskernel-core, self-hosting or C5.


## M2+A checked signed operations and Float bit reads — snapshot review (14 October 2026)

At commit `7bea16a0614be79e51c1ebbb99f926eda342b1fa`, [Linux CI 38549762258](https://github.com/dwijayuda/pskernel/actions/runs/38549762258) compiled and independently regenerated the two disjoint selected Core assets **byte-for-byte**: 62 checked Int8/Int16/Int32/Int64/BitVec method definitions and six Float/Float32 read-only bit-model definitions. The original frozen /61+signed identity prelude was preserved as the noncircular export boundary; no axiom, choice, source acceptance exception, instance or class was added. Official kernel replay and candidate checks passed before the selected Standard correctly refused the old digest. The observed next snapshot is **FNV `fnv1a64:2992617569121253333`** and **SHA-256 `sha256:4fc70a9fac595be03500185122459263e1a9e75141bc8fd39a680785d682e8a3`**. The expected 1,643 declarations (previously 1,575 plus 68, unchanged 23 classes and 153 instances) are subject to full regression confirmation; this edit pins only these independently measured hashes.

**Important remaining work:** These imported definitions are logical Core, not yet executable signed/Float operations. F1 `ofBits`, NaN canonicalization, arithmetic and scientific literals, signed Int-valued conversions, signed shifts and comparisons, typed signed/float IR and ABI, all-target runtime evidence, selected arrays/bytes/library and comprehensive environment manifest remain open. The latest fully green selected Standard before this digest edit remains `d112580` in CI 38546207955. Continue M2+A in native portable `.lean`; no pskernel-core, self-hosting or unsound foundation expansion.




## 14 October — signed proof closure diagnosis and coherent BitVec selection

CI [38547078451](https://github.com/dwijayuda/pskernel/actions/runs/38547078451) at `189b89b94d9d2f9bf705c6a7eda6ed30aca96d90` independently accepted six `Float.toBits`/`Float32.toBits` Core declarations, zero new axioms, but **refused** the larger signed root selection. The error is real: native `Int.add_zero`, `Int.neg_neg`, `Int.natCast_*` and similar proof bodies exhibit application/declaration type mismatches against PSCV0's selected Int model, leaving other recursive arithmetic dependencies blocked. It is not a reason to turn Int lemmas into axioms or to disable kernel validation.

The next isolated candidate selects the pure BitVec-backed signed width operations (`ofNat`, `toBitVec`, `ofBitVec`, add/sub/mul/div/mod, neg/complement and bitwise Boolean operators) for Int8/16/32/64. Int-valued conversion, signed shifts, comparisons and general `OfNat` registrations remain unselected until their exact native logical and checked-Int dependencies can be reconciled. A green candidate alone does not grant runtime execution. F1 read-only Float projections are captured as an independently reproducible native asset.


## M2+A logical-operation dependency qualification — 14 October 2026

**Latest green selected Standard:** `d1125803720ceb347a23acdd6f21f8140355fac5`, [Linux 38546207955](https://github.com/dwijayuda/pskernel/actions/runs/38546207955), full 25-step workflow passed. The selected environment includes checked native Float/Float32 models and `Int8/Int16/Int32/Int64/ISize` identity structures: **1,575 declarations, 23 classes, 153 instances** and unchanged 426 prior cross-target observations. FNV `fnv1a64:545524655185859287`, SHA-256 `sha256:2675059835d6278a4c7ac8871a3df937835d2ee57912dfd7b9b296576df30c1f`. Source/runtime Float and signed arithmetic remain disabled until qualified.

Next independent native Lean 4.35.0 reference slices, now under strict candidate review: (1) F1a logical `Float.toBits` and `Float32.toBits` projections, deliberately excluding `ofBits` whose full proof closure needs unapproved `Classical.choice`; and (2) a four-width coherent signed `ofNat/ofInt/toInt`, BitVec, arithmetic, division, modulus, bitwise, shift, comparison and `OfNat` root family. The 20 source methods per width are selected directly from pinned `src/Init/Data/SInt/Basic.lean` and checked against `tests/elab/test_extern_int.lean`. A green candidate would qualify source/Core authoring only; complete typed erasure, integer/Float IR validation, JS/TS/Rust/Wasm GC/ABI behavior and official native runtime observations are separate mandatory gates. No new trusted foundation assumptions, pskernel-core, self-hosting or release claim.



## Current signed selected Standard — independent digest review (14 October 2026)

At commit `8bee79d6c116ef102d0bc5bc4b4be7ae97f135e7`, [Linux 38545886718](https://github.com/dwijayuda/pskernel/actions/runs/38545886718) compiled the checked 15-entry SInt family asset, regenerated it **byte-for-byte** from the original pre-signed Standard, and rechecked all five recursor rule contracts. Its selected-Standard guard correctly refused the previous snapshot and independently reported **1,575 declarations, 23 classes and 153 instances** (net +10 actual declarations replacing five axioms); FNV `fnv1a64:545524655185859287`; SHA-256 `sha256:2675059835d6278a4c7ac8871a3df937835d2ee57912dfd7b9b296576df30c1f`. These precise observed values are now pinned without weakening the two strict registry guards. **This revision still needs its next complete green Linux regression.** No new trusted axioms, signed runtime arithmetic, portable USize/ISize execution or F1 Float bit interfaces are claimed. F1 awaits a sound resolution of the `Classical.choice` proof dependency; other M2+A exits remain open.



## Signed checked Standard integration — digest qualification required (14 October 2026)

The native candidate at `4c42b5b1ca4e7fccfc84d56dab20e2fb293ac976` passed [Linux 38544426724](https://github.com/dwijayuda/pskernel/actions/runs/38544426724) and source-transport run `7486f326f2f65da9d9ebff433ed24d83ff7ba5ce` passed [Linux 38545090626](https://github.com/dwijayuda/pskernel/actions/runs/38545090626), each with all 25 checks. The signed logical identity candidate has **15 checked declarations, five compared recursor rules, no new axioms, 93 shared nodes and 106,050 UTF-8 source bytes**, replacing the five old `Int8/Int16/Int32/Int64/ISize` type axioms. The signed stage is now imported after F0 Float logical identities using a separately frozen pre-signed export boundary, preserving byte-for-byte native regeneration. Prospective selected Standard count: 1,575 declarations (formerly 1,565); 23 classes and 153 instances unchanged. **This selected change is not yet qualified until independently observed new FNV/SHA hashes and full kernel/runtime regression pass.** F1 Float bits still cannot import unapproved `Classical.choice`; signed arithmetic and portable platform-width execution remain incomplete.



## M2+A next dependency: signed logical wrappers and F1 constructive Float blocker (14 October 2026)

The selected F0 Float/Float32 logical identity environment passed all 24 Linux gates at commit fbda73e1635fe35a5b7c31e2eda59a39f5e64b21, [CI 38534425757](https://github.com/dwijayuda/pskernel/actions/runs/38534425757). The F1 native bit/classification candidate at 5fc60b939efe0d509e9f98035bbee57a72369d2e failed its mandatory gate at [CI 38543575033](https://github.com/dwijayuda/pskernel/actions/runs/38543575033): its 1,075-declaration closure requires unapproved Classical.choice along Float.ofBits → Float.Model.ofBits → Float.Model.UnpackedFloat.unpack → Nat.pow_eq_zero. No source bit APIs or new trusted axioms were admitted. The native authoring command remains for constructive research; its unapproved candidate is not a mandatory regression gate.

Pinned Lean 4.35.0 src/Init/Data/SInt/Basic.lean provides an independent completion path: Int8/16/32/64 and ISize are genuine one-carrier checked inductives over their unsigned counterparts. A strict signed identity exporter is being qualified now, without runtime enabling, pskernel-core or self-hosting. Next: validate exported metadata and original-kernel replay, then sign-correct conversions and runtime operations. Remaining M2+A and F1–F4 are incomplete.



## F0 selected Standard digest — independently observed (14 October 2026)

Linux [run #38534047864](https://github.com/dwijayuda/pskernel/actions/runs/38534047864) at `bdfdb6b6402618908c1d52aa6494f37df7483713` compiled the newly selected 51-entry Float/Float32 Core model, independently regenerated its 254,044-byte source **byte-for-byte**, passed the F0 annotation and native-kernel negative probes, and correctly refused the previous /61 Standard digest. The run's independent candidate for the new selected Standard fingerprint was **FNV `fnv1a64:4585335486592655667`** and **SHA-256 `sha256:3bed7c1104a6209f6af124e932ce7c7ae6401f0f9483896e6730c51ffd35d0ca`**. These are now pinned in `StandardSnapshot.lean` without weakening either validation guard. The new selected environment is **pending full official kernel, source, runtime and CI qualification**; the last fully green regression remains `bb2dbbcc` on the unchanged /61 environment. F1–F4 executable Float, M2+A and later milestones remain open.



## F0 logical identity asset selected — kernel/registry qualification in progress (14 October 2026)

The pinned native F0 candidate passed all 24 Linux regression steps at `bb2dbbcc6432401fedf7f73f1b174d7ee765c3ab`, [CI #38532887281](https://github.com/dwijayuda/pskernel/actions/runs/38532887281), including rejection of a forged Format.mk signature. Exactly 51 logical entries were generated, with 8 independently compared recursor rules, no new axioms, and only pre-approved `propext` and `Quot.sound` in the existing foundation. Frozen candidate source: 254,044 UTF-8 bytes / SHA-256 `47e9e2ac59dc256d108e801e38c57a238c7cdfa1d1f06c16df2fd3390cf50501`. New pre-F0 exporter stage keeps the original /61 boundary. Integrating the selected source replaces exactly 2 legacy type axioms, so the prospective Standard declaration count is 1,565 (previously 1,516); classes and instances are not modified. **Selection is not qualified until a new independently observed FNV/SHA registry snapshot, official kernel replay, negative conformance and broad Linux workflow pass.** Float ofBits/equality/arithmetic/scientific/runtime/ABI (F1–F4), M2+A and later milestones are still incomplete.



## F0 Float identity — checked candidate qualification (14 October 2026)

Commit [`9b5f04e`](https://github.com/dwijayuda/pskernel/commit/9b5f04ed5b87707410dd859a247e0d724f326cc8) completed all 24 Linux gates in [Actions run 38531327231](https://github.com/dwijayuda/pskernel/actions/runs/38531327231). Native authoring exported **51 dependency-closed Float/Float32 logical identity declarations**, replaced exactly the legacy `Float`/`Float32` type axioms inside a discarded candidate, compared **8 recursor computation rules**, and independently replayed the candidate through the official pinned Lean 4.35.0 kernel. Imported candidate axioms: **none**; approved pre-existing foundation: exactly `propext` and `Quot.sound`. Source: 254,044 bytes / 1,444 shared source nodes. The **/61 selected Standard remains unchanged**, with 1,516 declarations / 23 classes / 153 instances, 426 cross-target observations and original frozen fingerprints. **F0 is not yet selected/published; runtime Float functionality, F1–F4 and M2+A remain incomplete.**

Root cause: pinned `Float.Model.Format.mk` constructor carries elaborator-generated `autoParam` tactic annotations. These transitively refer to `Lean.Syntax` but are definitionally equivalent to their annotated proof types. The native F0-only exporter removes only fully applied `autoParam` wrappers, proves each transformed signature in the original native environment with an ephemeral official-kernel typed alias, refuses altered term bodies, and separately replays the portable Core with exact regenerated metadata. Unrelated `optParam`/real Syntax dependencies remain untouched. The next authoring checkpoint adds negative policy probes and publishes the full verified candidate source through Linux Actions text logs for review; **no snapshot or release capability change is claimed until integration and requalification.**



## Current F0 implementation/audit slice — 14 October 2026

Verified last full-green executable: `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e`, Linux [38515443060](https://github.com/dwijayuda/pskernel/actions/runs/38515443060), selected /61 1516 declarations / 23 classes / 153 instances and 426 shared runtime observations. Draft PR 109 remains open. Do not call F0 or M2+A complete.

New F0 design/inventory checkpoint: [Float logical/runtime boundary plan](docs/PSCV0_FLOAT_LOGICAL_RUNTIME_BOUNDARY_PLAN_2026-10-14.md), updated at `5675dafa`. Explicitly separates existing Float/Float32 name and IR scaffolding from the absent checked Standard logical families. Audits pinned Lean 4.35.0 Model/Float, Model/Float32, bits, IEEE-vs-structural equality, scientific literals and runtime/ABI proof obligations. No new source Float support is claimed.

New executable F0 *read-only closure discovery* at `64a79a738d279e973839c624468fbec222212eb5` expands the existing native `--audit-standard-closure` to both Float wrappers, bit transports, BEq and OfScientific. Linux [38521251051](https://github.com/dwijayuda/pskernel/actions/runs/38521251051) **completed successfully** at executable `64a79a738d279e973839c624468fbec222212eb5`. Its read-only F0 closure audit, official checker, parser/refusal suite, JS/TS/Rust, GC/Wasmtime component and existing performance gates passed. This certifies only audit tooling and unchanged /61 behavior; **Float and Float32 source/runtime are not yet implemented or qualified**. This does not import, assume, or emit floating declarations. Next, select a complete closed Lean logical model F0 candidate and replay it in the official kernel with strict assumptions/snapshot boundaries; then implement F1–F4 in dependency order. Preserve no C5/self-hosting/pskernel-core scope, no new assumptions, and existing cross-target baseline.

## Post-/61 research checkpoint — Float/Float32 semantic closure

Reviewed pinned Lean 4.35.0 `Init/Data/Float/{Float,Float32,Model/Float}.lean`, `Init/Data/OfScientific.lean` and the upstream floating conformance tests. The new [Float logical/runtime boundary plan](docs/PSCV0_FLOAT_LOGICAL_RUNTIME_BOUNDARY_PLAN_2026-10-14.md) pins canonical NaN bits, Boolean vs propositional equality, signed zero, f32 rounding, exact scientific literals, cross-target runtime/ABI responsibilities and negative conformance. **Research only: no Float implementation or new proof assurance is claimed.** Next dependency order is F0 selected Core closure, F1 bits/classification, F2 arithmetic/BEq, F3 conversion/literals, F4 all-target qualification. /61 remains last green executable at `34ff236b`, CI `38515443060`.


## New qualified /61 checkpoint — 14 October 2026

Executable commit `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e` passed the full Linux workflow
[38515443060](https://github.com/dwijayuda/pskernel/actions/runs/38515443060).
Profile `pscv0-v7-native-bounded/61` is **green for its declared selected scope**; this
does NOT mean M2+A, all v7, C5, full compiler metatheory, or formal backend preservation
are complete. Standard selected 1516 declarations / 23 classes / 153 instances, FNV
`fnv1a64:6333670853941549394`; SHA candidate
`sha256:ebf02f5f8dfecf3769cbaeaa52e39dac3ba9c8dc034ea5284655da324bc75d60`.
426 shared cross-target runtime observations passed for TypeScript, JS and Rust;
Wasm GC/Wasmtime component, linked projects, parser/negative conformance, official kernel,
asset regeneration and performance gates passed. These are bounded runtime observations,
not a proof that every possible backend program preserves Lean semantics.

Resolution: the official Lean 4.35.0 `Init/Prelude.lean` defines
`Unit : Type := PUnit` and `Unit.unit := PUnit.unit`, but PSC0's APP-03
empty-call path rejected a fresh *universe metavariable* in the
`PUnit` argument domain before checked unification. The source check
now distinguishes unresolved term types (still refused) from the known
Unit/PUnit family, solves the universe using ordinary checked unification,
then rechecks definitional equality and inserts an ordinary typed Unit inhabitant.
All positive APP-03 cases (including `PUnit`) and the existing negatives passed.
No new axiom, untrusted cast, permissive fallback or relaxation of source/kernel
acceptance. Previous historical /61 failures and /60 baseline below remain for
audit but are superseded by this independently qualified executable checkpoint.

Further upstream sources studied for preceding /61 root fixes:
`src/runtime/interrupt.cpp` (thread-local heartbeats),
`src/kernel/environment.cpp` (checked `lean_add_decl`),
`src/Lean/Environment.lean` (`Kernel.Environment` checked replay),
`src/Lean/Declaration.lean` (kernel reducibility hints),
`src/Init/Data/UInt/Basic.lean`, `src/Init/Data/Hashable.lean`,
and `src/Init/Data/String/Defs.lean`.
Use pinned commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Upstream licensing is acknowledged in the adapted source and
`psc0/THIRD_PARTY_NOTICES.md`.

Next: make `/61` the qualified baseline, update the latest frozen snapshot and
milestone status documentation consistently, audit hot-path performance/resource
telemetry, and continue the remaining M2+A language/standard exit criteria
without starting C5 or self-hosting.


Checkpoint: 14 October 2026. This file and [AI_CONTINUE_PROMPT.md](AI_CONTINUE_PROMPT.md)
are the active handoff. **Update both after every milestone slice**, as requested
by the user because usage is low. Record the exact code revision, CI evidence,
remaining work and next action before beginning another slice.

## Latest continuation: kernel-only replay, awaiting qualification

Run [38479812733](https://github.com/dwijayuda/pskernel/actions/runs/38479812733)
at `15cea236` passed build, quotient probes, frozen regeneration and GetElem
erasure. It failed later on a malformed new List.foldl fixture; it also exposed
AsyncConsts collisions between distinct imported private names.
The next code commit moves standalone checking/replay to official
`Lean.Kernel.Environment.addDeclCore` at trust zero, preserving full names and
all kernel checks. It fixes the fixture's APP-03 argument order and compiles the
provider Admission module to validate the changed API. No new assumptions.
The earlier quotient/Unit failure descriptions below are historical diagnoses.
Fetch the new run and inspect complete results; /60 remains the last full green.

## Active repair slice — implemented, awaiting CI

The next code commit after checkpoint `85b35cd` implements quotient group
admission once with per-descriptor validation, shared nullary literal handling
before definition lookup, normalized PUnit's unit carrier, and removal of the
temporary cache fallback. The existing quotient probe covers repeated/reversed
descriptors, forged existing signatures and provider collisions.
[Design and pinned source references](docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md).
These changes are **not yet qualified**. Fetch live HEAD and its native workflow;
record results in both handoff files. Historical failure details below identify
the causes addressed by this slice, not a new observed result.

## Current state: M2+A incomplete; /61 qualification pending

- Repository: `dwijayuda/pskernel`; branch: `psc0/pscv0-v7-native-lean-v1`.
- Existing draft [PR 109](https://github.com/dwijayuda/pskernel/pull/109).
- Latest code: **`1f54142c6225020c39265254a582860bd4169937`**.
  A documentation-only checkpoint follows this revision; fetch live HEAD.
- Latest [Linux run 38478159236](https://github.com/dwijayuda/pskernel/actions/runs/38478159236),
  job `115573914577`: **completed, failure**.
- Profile `pscv0-v7-native-bounded/61` is **under qualification**.
  Build, asset regeneration and strict registry digest checks passed; source
  checking failed in erasure. Native/backend integration was not reached.
- Failure: `PSCV0-ERASURE: unknown constant Unit.unit (in PsStandard.instInhabitedUnit)`.
- The same log contains repeated **PANIC: duplicate normalized declaration name
  Quot vs. Quot**, from official Lean environment admission. These panics are
  unresolved even though execution continued.
- No new full-green result, M2+A completion, formal runtime equivalence or
  performance parity is claimed.

The user **explicitly approved exactly Lean 4.35.0's `propext` and `Quot.sound`**
for the audited foundation. Approval is already published. **Do not ask again.**
All dependent proof declarations still require official Lean kernel checking.
No other additional assumptions were approved.

## Execution contract and source of truth

Use GitHub connector source reads/writes and Linux Actions only; no local
checkout, shell/build or Desktop Commander. Work natively in portable `.lean`.
No `pskernel-core`, self-hosting tests or compiler-source `.ps` migration yet.
Wasm GC internally; linear memory only at explicit ABI boundaries.

Fetch live remote HEAD and relevant CI before writes. Preserve concurrent work
with expected-HEAD, non-force updates. Keep PR 109; do not merge.
Do not weaken acceptance, fabricate axioms, add unchecked kernel fallbacks or
hide runtime representation errors with arbitrary casts.

Study corresponding official **Lean 4.35.0** source and tests before feature
design/implementation/redesign, at commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Record semantics, algorithms, invariants, data structures and justified
simplifications. Preserve attribution/licensing when adapting code.
Prefer coherent shared mechanisms, then focused validation and existing
integration gates. Preserve required behavior, not obsolete internals.

Canonical references:

- [Language reference](PSCV0_LANGUAGE_REFERENCE.md)
- [M0–M5 architecture](docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md)
- [Phase A–E exit gates](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md)
- [Readable-output audit](docs/PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md)
- [Pinned Lean migration](docs/PSCV0_LEAN_435_PIN_2026-10-14.md)
- [Active scalar design and source study](docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md)
- [Format/Repr/Hashable design and qualification](docs/PSCV0_A_FORMAT_REPR_2026-10-14.md)

## Last fully qualified boundary: /60

Executable **`d72fc7779b2e8d130915dfe4ace339634ba0addd`**;
[green Linux 38466179341](https://github.com/dwijayuda/pskernel/actions/runs/38466179341),
job `115533442925`.

- 399 shared runtime observations and four panic contracts.
- 217 portable / 227 native modules.
- Standard: 672 declarations / 23 classes / 109 instances.
- FNV: `fnv1a64:10680386315174967875`.
- SHA: `sha256:9a54d5747d3047abff68e3bd872b791f3489f719cf83e8aba6776d342f045cc0`.

Official kernel, independent pinned native oracle, semantic/refusal/search,
strict IR, JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, projects and
existing performance gates passed at that boundary.

Qualified: ToFormat/Repr and selected nonrecursive deriving; UInt/BitVec
construction/conversions; unsigned Canonical ABI widths; Hashable class,
17 checked instances and selected nonrecursive deriving; native-compatible pair
and UTF-8 string hashes. Hash runtime algorithms are audited implementations
of checked opaque declarations, not formally proved equivalent.

Shared Int.rec erasure evaluates its sign discriminator once. Generic calls
retain original declaration binder masks when Sort parameters specialize to
Prop; irrelevant carriers/proof slots use Unit. Complete-spine WHNF and
reflexivity-before-evaluation repairs remain. Frozen proof assets regenerate
exactly. The /60 qualification predates the newly approved two-axiom /61 closure.

## Implemented /61 slice, with limited qualification

### Checked unsigned operation asset and dictionaries

Commit `e9fde4e3ff88b1e83c8c59e7b531403f6eb5d154` admitted
`packages/environment/src/Ps/Environment/StandardUnsignedOperationsData.lean`:

- 803 declarations; 49,978 shared typed source nodes; 6,457,592 UTF-8 bytes.
- Source SHA256:
  `b33dc2e256f17da29a3236a24c2d8267bf04de4338d73c568cafc44ee686f2de`.
- Exactly the two approved axioms and four kernel-generated quotient descriptors.
- UInt8/16/32/64 add/sub/mul/div/mod/neg/complement/land/lor/xor/shiftLeft/shiftRight
  (48 operations), and the actual Nat.div logical model.
- Six former axiom declarations replaced by native checked definitions:
  Nat.decEq, Bool.decEq, Unit.unit, Unit, Nat.blt and Nat.div.
- `StandardUnsignedOperations.lean` adds 24 explicit HAdd/HSub/HMul/HDiv/HMod/Neg
  dictionaries. Logical proof dependencies do not enter runtime support.
- Frozen `psSelfHostProdHashPreludeEnvironment` feeds the operation stage.
  Export boundary is `psStandardUnsignedOperationsBoundary`; source sharing is
  enabled and definition-to-axiom replacement is disabled.
- Both new portable Lake roots are registered. Primitive audit covers all 48.
- Isolated quotient probes deliberately use the pre-admission Hash stage.
- Fifteen observations were added to the existing shared native/all-target
  harness: width vectors, higher-order shift, generic wrapping addition and
  exact UInt32 maximum-times-maximum multiplication. They are **not yet fully
  qualified**. Temporary artifact transport jobs were removed; regeneration
  compares admitted and fresh sources byte-for-byte.

Earlier /61 work also includes native two-universe Prod and product dictionaries;
alpha-renamed/normalized universe signature audit; right-discriminating Bool.beq;
native List.foldl telescope and List.reverseAux equations; 16 UInt default/display
dictionaries; general logical iota beneath recursive function telescopes; quotient
descriptors and lift/ind reduction. Product/display observations also await full
integration. Unsigned div/mod/shifts use shared IR plus ECMA/Rust/Wasm plans,
including exact UInt32 multiplication, UInt64 BigInt, zero guards and width-masked
shifts; this does not enable signed/platform/Float support.

[Run 38476108793](https://github.com/dwijayuda/pskernel/actions/runs/38476108793)
compiled 220 portable / 231 native modules; all four frozen assets regenerated
exactly; 803 candidate declarations were kernel checked and 33 recursor rules
compared. Its old /60 snapshot deliberately refused the changed registry.
Do not interpret the kernel receipt as proof that repeated quotient admission
is clean: the later production replay exposed the duplicate-registration panic.

### Reviewed strict digests and faster native validation

Commit `1f54142c6225020c39265254a582860bd4169937` pins the new payload values
independently reported by the previous Nat-arithmetic implementation:

- FNV: `fnv1a64:16613033526791726173`.
- SHA: `sha256:8aea3c6be714db09f4a5a442e9fab57a40bdf13c11d86e811c2574165d55b04d`.

The checksum implementation now uses UInt64 FNV, UInt32 SHA-256 and packed
ByteArray storage; joint validation serializes the canonical payload once.
Digest/padding semantics and strict drift refusal remain unchanged. No hash
FFI, new assumptions or automatic snapshot acceptance.

Latest run passed the full-payload strict checks. Existing four SHA known-answer
vectors remain, but their later `projectBoundaries` gate was not reached because
erasure failed first.

Bounded CI measurements: previous cold build 222,087 ms, warm 595 ms; latest
native rebuild 12,317 ms, warm 561 ms. Audit/export commands fell from roughly
73 seconds each to 2–5 seconds; unsigned regeneration was approximately 4.95
seconds including startup versus 75 seconds. This is evidence for this workload,
not a full parity claim.

Cache keys now use OS/architecture/toolchain hashes; Lake's traces track module
changes. The exact old-key fallback in
`.github/workflows/psc0-pscv0-native-v7.yml` was temporary migration scaffolding.
The latest run saved the new cache; remove that fallback in the next code slice.

## Next slice: fix two shared boundary invariants

### 1. Admit the quotient group once; validate every descriptor

Owner: `packages/pskernel-lean/provider/PsKernelLean/Prelude.lean`.

`toLeanPreludeDeclaration` converts each of Quot, Quot.mk, Quot.lift and Quot.ind
to the same generative Lean `.quotDecl`. `tryPreludeDeclaration` unconditionally
calls `env.addDeclCore 2000000 20000 converted none true`, then validates the
member's kind/type/universe metadata. Each descriptor and replay retry therefore
tries to generate all four constants again. Lean's AsyncConsts uniqueness
invariant panics on the repeated declaration.

Study pinned `src/kernel/quot.cpp`, `src/Lean/Environment.lean`,
`src/Lean/Declaration.lean`, `tests/elab/quotInd.lean` and locate the
`kernelQuotNameCollision.lean` test before editing.

Design direction: separate **ensure the kernel quotient group exists once**
from **validate this supplied member**. Inspect the checked environment for the
group; generate it once when absent, otherwise validate exact existing kernel
quotient kinds/types/level parameters without re-adding. Reject partial groups,
collisions and forged metadata. Share member validation across both paths.
Do not introduce general name-based duplicate skipping for other declarations.
Use this same mechanism for candidate authoring and production prelude replay.
Retain the isolated Hash-stage signature/collision refusal probes.

### 2. Resolve builtin runtime identities before ordinary definitions

Owner: `packages/erasure/src/Ps/Erasure/Expr.lean` and shared erasure helpers.

Unit.unit was formerly an axiom, so the late nullary-literal fallback handled it.
Its admitted native definition now resolves as an ordinary runtime entry first;
it is intentionally absent from runtime support, so lookup fails before reaching
the existing fallback. Adding its proof closure to runtime would fix the symptom,
not the invariant.

Inspect the complete constant/application/eta-completion paths, especially
`psErasureSpecialEntry`, `psEraseSpecialBoundary`, `psEraseGeneralApplication`
and `psErasureResolveEntry`. Centralize existing builtin literal/runtime identity
classification before ordinary definition lookup, consistently for constants and
applications. Check the related Bool.true/Bool.false/Nat.zero family; preserve
arity and overapplication refusal. Native Unit is an alias to PUnit.
Keep logical checked definitions separate from their audited runtime treatment.

After implementing both coherent fixes, run existing focused official-kernel/
erasure gates and the full native workflow. Check logs for panics explicitly,
not just process exit status. Re-run remaining checksum vectors and all-target
observations through that workflow. Do not call /61 qualified before the complete
matrix passes. Update both handoff files with exact evidence at this slice.

## Next unsigned-interface slice (design only, not published)

A prior session prepared parser buffers in memory only. They were **not applied,
compiled or published**; no future chat should depend on those transient stores.
The branch contains all other active code described above. Reconstruct the design
from pinned sources rather than assuming a missing working-tree patch exists.

After /61 qualification:

- Export a separate frozen native comparison/conversion interface stage against
  the unsigned-operation boundary, with no new assumptions.
- Study UInt decEq/decLt/decLe, native LT/LE instances, all twelve cross-width
  conversions, Nat.toUInt aliases, GE.ge/GT.gt and DecidableLT/LE.
- Register actual checked class/instance metadata separately from proof data.
  Existing LT/LE and Nat instances are present in scalar data but absent from the
  curated source class roster. HAnd/HOr/HXor/HShiftLeft/HShiftRight/Complement
  declarations already occur in the operation proof asset.
- Reuse the existing typed machine comparison plan; comparison proof fields erase.
  Evaluate width-conversion composition against an explicit typed cast for
  correctness and performance; this decision is not implemented yet.
- Study native priority-500 `instBEqOfDecidableEq` and generic Pi search/runtime
  support before reusing it.
- Parser plan: one bounded longest-adjacent-token reader shared by prefix/infix,
  at most three existing lexer tokens; preserve spans, reject gap fusion and
  never consume empty EOF. Ordinary class applications own semantics.
  Relations at precedence 50, nonassociative; bitwise OR 55, XOR 58, AND 60;
  shifts 75 left-associative; complement prefix 100.
- Relevant PSC0 owners:
  `packages/syntax/src/Ps/Syntax/Pscv0/Operators.lean`,
  `packages/syntax/src/Ps/Syntax/Pscv0/TermRead.lean`.
  Pinned references: Init/Prelude, UInt/Basic, UInt/BasicAux, Init/Notation,
  Lean/Parser/Basic tokenFnAux; tests bv_uint, uint_fold, uintMatch, fold_uint.
- Validate a compact set of boundaries, generic and partial applications through
  the existing conformance table. Keep proof closure out of runtime support.

Checksum source study also covered pinned
`src/Lean/Compiler/LCNF/ExtractClosed.lean`,
`src/Lean/Compiler/NeverExtractAttr.lean`,
`src/Init/Data/ByteArray/Basic.lean`, UInt Basic/BasicAux and
[NIST FIPS 180-4](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf)
sections 4.1.2 and 6.2.

## Roadmap and preserved architecture

Interleave **M2+A → M3+B → M4+C/D → M5/E**. M1's selected checked
GetElem/Fin/List/Array/optional-lawfulness closure is complete.
Recursive/indexed/dependent deriving belongs with M3's data/transport/termination
mechanisms. Effects/specifications/VCs belong to M4/C-D.
Collect E evidence and measured M5 improvements throughout.

Remaining M2+A includes unsigned comparisons/conversions/dictionaries,
signed/platform words, Float/Float32/scientific, expanded BitVec/bytes/selected
library APIs, the comprehensive cryptographic module/public/import/notation/
handler/class/instance/tactic/effect/axiom manifest, broader scope/depth/resource
evidence and C5 semantic retention. A declaration snapshot is not the complete
manifest. Do not move incomplete gates merely to declare M2+A finished.

Shared instance search uses generator/consumer tables, exact checked keys,
fresh term/universe answer templates and independent budgets. Only an answer
owner adopts its speculative context; consumers instantiate/recheck in their own
contexts. Closed identical local signatures are required for sharing. Output
preferences reconcile after selection without lower-priority backtracking.
Limits remain 4096 generators/candidates/answers, 32768 transitions, height 64.

One transactional synthetic queue handles Core constraints, saved syntax,
tactics/defaults/numeral fallback and expected-term adaptation. Ordinary work
quiesces before defaults; declarations drain pending work. Defaults use checked
opaque holes, failed retries roll back lexical authority, and reducibility
policy remains explicit. Genuine OfNat and direct Coe/CoeFun/CoeSort use shared
typed application; no coercion chains/auto-lifting, and APP-03 stays strict.
The SynthInstance facade must not acquire another retry engine.

See [instance graph](docs/PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md),
[generalized constraints](docs/PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md),
[postponed elaboration](docs/PSCV0_M2_POSTPONED_ELABORATION_2026-10-13.md),
[coercions](docs/PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md),
[deriving](docs/PSCV0_M2_A_DERIVING_2026-10-13.md) and
[equality/defaults](docs/PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md).

Parameter/universe-aware Inhabited/BEq/DecidableEq share family/field/recursor
mechanisms. Selected deriving handles non-indexed/nonrecursive families with
independent computational fields. Proof-only fields erase; dependent runtime
existentials and general higher-rank dictionaries remain explicit refusals.
Do not bypass unknown-type IR checks.

Readable JS/TS/Rust/WAT/WIT are implemented for the qualified subset; extend the
shared plans. Historical bounded Lean/PS printers are reusable, not complete C5.
Retain checked pre-erasure binder/resolution/implicit/default/occurrence semantics
during M2–M4; publish reconstruction/correspondence under M5/E. Coarse declaration
maps or source replay do not establish reconstruction, and two checked outputs
are not a proof of equivalence.
