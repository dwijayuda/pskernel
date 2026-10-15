# M2+A scalar completion design — Lean 4.35.0

## Shared default instances prepared for qualification — 15 October 2026

The Array prerequisite passed [native38737651266](https://github.com/dwijayuda/pskernel/actions/runs/38737651266) at `3642e8835f36f238c88e4097914df55b199fd58e`: 851 shared observations and all required gates. It is integrated to main `e3902f3d91556af40b85f65566ff6787620346ee`, pending exact-main qualification. F2 is already exact-main qualified at `ef5c5e342015bfabcb58ae1f3291f0fe544cec5a` (native38736277605, F138736277937, F238736278026).

This coherent F3 prerequisite implements a separate priority-ordered default-instance registry, selected declaration `@[default_instance priority]` syntax, checked class-result registration, captured-scope resolution, transactional dependency solving, one-default-at-a-time quiescence scheduling, and public/private module propagation. Ordinary instance priority remains independent. Both imported registries preserve newest-first tie order and deduplicate import diamonds. Candidate preparation, type checking and tabled ordinary synthesis are reused; default search is bounded and resource exhaustion rolls back the whole worklist rather than selecting a lower-priority fallback.

Primary reference: pinned Lean 4.35.0 `Lean/Meta/Instances.lean` (DefaultInstances/addDefaultInstance) and `Lean/Elab/SyntheticMVars.lean` (synthesizeUsingDefaultPrio/synthesizePending/synthesizeUsingDefault). Tests studied: `tests/elab/defaultInstanceWithPrio.lean`, `defaultInstBacktrackIssue.lean`, and `tests/elab_fail/defaultInstance.lean`. The adapted algorithm's upstream Apache-2.0 authorship is recorded in Synthetic.lean. PSC0 retains its immutable scoped contexts and bounded tabled search rather than importing Lean elaborator state.

One source fixture and seven shared observations exercise priorities across goals, failed-candidate rollback, recursive defaults, tie order, surrounding type information, rigid default-only dictionaries and universe instantiation. Matching native Lean guards provide an independent semantic oracle. Compact checks additionally cover ordinary-search separation, resource rollback, imported ordering/diamond deduplication, private visibility and nonclass rejection. Existing whole-subsystem and backend gates remain required. Intended total: 858 shared observations.

The strict declaration snapshot format becomes v3 to include default registrations; the source-surface payload becomes v2 to include the actual selected attribute registry and defaults. Existing pins intentionally refuse until independent cloud measurement is reviewed. No new Standard declarations/defaults, assumptions, runtime operations or budgets. Scientific syntax and OfNat/OfScientific literal integration are still next, followed by F3 numeric conversions; existing delayed numeral fallback is not claimed to implement the new literal policy. F3's 134-declaration checked conversion candidate remains unselected. This default-instance implementation is prepared, not yet qualified; M2+A remains open.


## Array universe prerequisite: logical gate qualified, strict pins reviewed — 15 October 2026

At `ae8f17d4d264cdd9be02cbd466f9ffd94ed07b73`, [F3 logical replay38734094036](https://github.com/dwijayuda/pskernel/actions/runs/38734094036) passes: 42 roots, 134 declarations, one recursor rule, 3,286 shared nodes and 617,019 UTF-8 bytes; SHA-256 `45e6c8b81fbd971c891d173acef36c2ce6f6c59b674a06ffc9bfbe2e8cff6391`. No new assumptions, replaced definitions or quotient primitives. The candidate remains unselected. Independent [F1 replay38734094050](https://github.com/dwijayuda/pskernel/actions/runs/38734094050) and [F2 replay38734094025](https://github.com/dwijayuda/pskernel/actions/runs/38734094025) also pass.

[Native38734094047](https://github.com/dwijayuda/pskernel/actions/runs/38734094047) compiled the complete Array family and oracles, passed the strengthened signature audit, and regenerated the prior assets. Both strict checks independently refused the intentional registry change with FNV `14544844717468498892`, declaration SHA-256 `373b27a0b77083baa58810055d68b6639ec00c2038da7641d3dd5c042e8f4e0d`, and surface SHA-256 `579f461576427a5daf711943613979e4517803475779e40b0200f359450744fa`. These reviewed values are now pinned; no guard is relaxed. Full Array source/runtime qualification remains pending.

F2 [native38734252078](https://github.com/dwijayuda/pskernel/actions/runs/38734252078) is green at `9ffdd799a05ee256368266831bbaec74bee18ed2`, including 843 shared observations across JS, TS, Rust and GC Wasm/component. Incorporate its six constant-observation metadata corrections (`args: null`) while preserving the eight new Array observations. Finish F2 exact-main qualification separately.

Next F3 work: shared priority-ordered default instances and exact scientific syntax, followed by checked conversion selection and typed backend conversion lowering. Pinned Lean `Lean/Meta/Instances.lean` and `Lean/Elab/SyntheticMVars.lean` establish descending priorities, transactional candidate attempts, and return to ordinary synthesis after one successful default. Float's OfScientific priority 501 must precede Neg Int's 500; surrounding expected types take precedence. Do not hardcode a Float literal fallback. M2+A remains open.


## F3 logical dependency gate prepared — 15 October 2026

Research branch `psc0/pscv0-v7-f3-conversions-research` starts from F2 candidate `d70fe6c562d7643f9b42a13d72f718ae146b1d7c` while F2 full runtime qualification continues independently. This branch adds only native authoring/export and a read-only cloud replay workflow; it does not select any F3 declaration or enable new syntax/runtime operations.

Pinned Lean 4.35.0 sources studied: Init/Data/OfScientific{,/Basic}; Float/{Float,Float32}, Model/{Float,Float32}, Model/Unpacked/Operations/{OfNat,ToNat,OfScientific}; SInt/Float{,32}; Lean/Parser/Basic.decimalNumberFn and Lean/Elab/BuiltinTerm.elabScientificLit. Relevant tests: elab/float_conversions.lean, elab_fail/scientific.lean, pkg/ofScientific/{Main.lean,test-data/README.md,doubleround.txt}. Existing scalar-completion design remains the roadmap.

The coherent logical candidate has 42 roots: both widths' ofScientific/ofNat/ofInt and conversions to eight fixed signed/unsigned word types, and conversions from those words plus Nat/Int into both floats. It uses the current selected F2 declarations as its dependency cut, original native definitions/proofs, shared source serialization and official kernel replay. Platform words and opaque Float/Float32 cross-width conversions remain separate contracts. No new assumptions, theorem replacements, computational axioms or budgets.

Semantic design: scientific lexing retains an exact mantissa, signed decimal exponent and source span; expected type and the shared OfScientific synthetic constraint determine interpretation. Float's default priority is 501. Native fast paths require exactly representable operands; model fallback bounds extreme exponents before powers of ten and rounds once to the selected width. Numeric integer-to-float conversion uses nearest-even; float-to-fixed-integer truncates toward zero, clamps at bounds and maps NaN to zero. Never convert an arbitrary UInt64/Int64 to binary64 before rounding to binary32: that can double-round. Reuse the shared typed conversion boundary across backends, canonical NaN observation and existing ABI plan.

Next: inspect this gate's proof/closure result, assess any dependency-family mismatches, finish F2 exact main qualification, then implement F3 coherently. No F3 acceptance/runtime claim. Keep both handoffs current.

## Prior checkpoint (F2 runtime still pending)

## F2 coherent implementation staged; qualification pending — 15 October 2026

The expanded native logical family passed at research `7393a31700c8aefe8843c4eb92476342786f45be`, [run38724434988](https://github.com/dwijayuda/pskernel/actions/runs/38724434988): **1,229 declarations /24 recursor rules /91,024 shared nodes /11,179,796 source bytes**, SHA-256 `ad82f59b48460a3b306312c3e9d72537e8b48201e432271a3be0424a576909df`. This includes native Float.decLt/decLe and DecidableEq at both widths. Only the two existing theorem cuts and approved propext/Quot.sound are used. Original upstream correspondence proofs still retain their recorded native-only assumption boundary.

The staged source selects that exact checked logical asset behind a frozen pre-F2 environment, registers arithmetic/Neg/BEq/Inhabited and native order/Eq decisions through the existing class index, and keeps the proof closure out of runtime support. Shared typed IR owns unary/classification signatures alongside arithmetic/comparison. Canonical-bit equality reuses existing bit conversions and integer equality; IEEE equality remains a distinct operation. Model-level operations use the same typed boundary and ordinary proof-erased record representation.

Readable JS/TS retain binary64 operations and explicit binary32 rounding. Rust uses safe native floating operations. Wasm emits native arithmetic/comparison and shared scalar descriptors for abs/neg; classification remains memory-free. F1 GC boxing and explicit ABI ownership are unchanged. **88 additional native-reference observations** cover rounding ties, subnormals, infinities, NaNs, signed zero, comparison/equality, partial/generic and Model calls. The full target corpus is intended to reach 843 observations, pending CI.

Strict declaration/surface pins remain at the prior qualified values until the intentional expansion is independently measured and reviewed. Do not weaken those checks. Run full native/backend CI, byte-exact F2 regeneration and independent F1 proof replay before claiming runtime qualification. No pskernel-core, self-hosting/bootstrap or C5. Main F1 remains qualified at 262c5819c499256fcd2093746deae4ef3aa2012b. Update both handoffs at the next slice.

## F2 logical family checked; runtime pending — 15 October 2026

Research commit `d4528f27e45917b5d63edd84b0feb15d5e812bf6` on `psc0/pscv0-v7-f2-operations-research` passed [logical closure replay 38722766782](https://github.com/dwijayuda/pskernel/actions/runs/38722766782). All 28 Float/Float32 arithmetic/comparison/classification roots plus the two existing constructive theorem roots passed: **1,169 new declarations, 24 recursor rules, 89,183 shared source nodes, 10,941,261 source bytes**. SHA-256 `711ef5ecd08df8442c986b6df2cc9135ea79b9842ec0100cf517b289488b9acf`. No new axioms, quotient primitives or definition replacements; only the approved propext/Quot.sound foundation.

This candidate is not selected Standard and F2 runtime operations remain refused. Next: freeze the pre-F2 boundary, select the checked logical family and source class metadata, keep proof dependencies out of runtime support, implement shared typed arithmetic/unary/classification/equality lowering across all active backends, then qualify one compact native differential corpus. F1 remains main-qualified at 262c5819c499256fcd2093746deae4ef3aa2012b (native38721711653, Float38721711679, 755 shared observations). M2+A is incomplete.

## F2 logical dependency gate — 15 October 2026

F1 is complete and qualified at 262c5819c499256fcd2093746deae4ef3aa2012b. Current F2 research is isolated on `psc0/pscv0-v7-f2-operations-research`; no arithmetic runtime enablement or selected Standard change is claimed.

Before implementation, studied pinned Lean 4.35.0 [Model/Float.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Float/Model/Float.lean), Float32 counterpart, Unpacked/Operations/{Add,Sub,Mul,Div,Compare,Sign,Status}.lean, [Round.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Float/Model/Unpacked/Round.lean) and [floatModelDefeq.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/floatModelDefeq.lean).

The implementation reference is unpack/operate/round/pack, not mathematical real arithmetic. Add/sub align signed integer mantissas; mul preserves the exact product; div retains quotient/remainder accuracy; round tracks round/sticky bits with ties to even and carry renormalization. IEEE beq is non-reflexive at NaN and identifies both zero signs; propositional equality uses the canonical model and is a separate capability. Classification observes unpacked constructors.

The first coherent gate exports 14 methods for each width: add/sub/mul/div/neg/abs/beq/lt/le/isNaN/isInf/isFinite/nan/inf. It reuses StandardExport's dependency closure, exact native theorem-type witnesses, portable official-kernel replay, recursor comparison and Apache-2.0 attribution. Only existing checked constructive proofs of Nat.pow_eq_zero and BitVec.getLsbD_of_ge may replace theorem bodies, when outside the selected cut. No computation replacement, increased budgets, Classical.choice admission or proof placeholder is permitted.

The research workflow checks the complete logical family before selecting assets or enabling F2 IR. Dependency or replay failures are evidence about the shared logical boundary, not permission to patch operations or weaken checking. Once the closure is accepted, freeze its pre-admission boundary, minimize runtime support independently, implement the shared typed operations and all active backends together, then qualify against pinned native bit observations. F3/scientific, F4, target-word propagation and the remaining Standard/manifest exits stay in M2+A.

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

## Historical checkpoints (superseded by the current receipt)

## 15 October — minimal logical Float constructors integrated; main qualification pending

Research `41a4474b7cbbb04c9e83b4a7fae111631be58e7a` passed both [full native integration 38715004637](https://github.com/dwijayuda/pskernel/actions/runs/38715004637) and [independent full proof replay 38715004629](https://github.com/dwijayuda/pskernel/actions/runs/38715004629). All 29 native steps passed, including exact asset regeneration, source/type/runtime boundaries, 699 observations each on JS/TS/Rust, GC Wasm/component validation, repeated Wasmtime calls and performance checks. This main integration still requires the same exact-commit pair before main qualification is claimed.

The selected constructor layer adds **21 checked declarations plus two public typed wrappers**, retaining actual Format.Valid evidence. Asset: **307,290 UTF-8 bytes /1,702 shared nodes**, SHA-256 `3042b3db951a1c68f8df24c5161889841082f9f4ee03783e1e5b4da918b3f9a7`. Regeneration uses its frozen pre-constructor declaration boundary and mandatory byte comparison. The independent **30-root /922-declaration /11 MB** representation audit remains separate from selected Standard. No new assumptions, axioms or runtime overrides.

Standard now has **1,879 declarations /25 classes /226 instances**. Strict independently measured pins: `fnv1a64:9256054256618924345`; declaration `sha256:0f62a5df0a7273a183e10700bf8eb49563afd0ff8d03b7be3935d4d310a12f04`; surface `sha256:240050e325b7c7d06827c36bffe7ed017ef18680b61ccf4fa7701807a62874b4`. Logical Float.ofBits/Float32.ofBits and toBits source admission is checked, a wrong-width argument is refused, and executable Float remains refused at the shared IR gate.

The full audit's pre-constructor boundary prevents selected roots from cutting their own replay. Host authoring uses the local Ps namespace first: Lean/Util/Path.lean resolves the first root directory, so plain lake env alone is insufficient when both parent and native packages use Ps. This ordering matches the independently qualified proof workflow.

M2+A remains incomplete. Next: coherent F1 model erasure, typed IR, all backends and explicit ABI; then F2-F4, target-sized words and remaining selected language/Standard obligations. Continue M2+A -> M3+B -> M4+C/D. No pskernel-core, self-hosting, C5 or trust expansion.

## F1 runtime continuation: one representation boundary (15 October research)

This extends the existing F1-F4 dependency order; it is not a new milestone track or an executable capability claim.

Pinned Lean 4.35.0 references studied:
- [runtime/object.cpp](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/runtime/object.cpp): lean_float_of_bits/to_bits and Float32 counterparts.
- [include/lean/lean.h](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/include/lean/lean.h): native arithmetic and Boolean comparisons.
- [Compiler/IR/ToIRType.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Compiler/IR/ToIRType.lean), [LCNF/MonoTypes.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Compiler/LCNF/MonoTypes.lean) and [LCNF/ExplicitBoxing.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Compiler/LCNF/ExplicitBoxing.lean): primitive Float identity, relevance erasure and scalar/object crossings.
- tests/elab/floatBits.lean and floatEquality.lean: canonical observation of both NaN signs, NaNs from arithmetic/negation, IEEE versus propositional equality.

Lean's C runtime does not require an identical physical NaN payload after every arithmetic operation. Ordinary add/sub/mul/div/neg use native operations; toBits returns exactly positive canonical quiet NaN on any native NaN. ofBits discards arbitrary NaN payload/sign. Adapt the representation relation: every non-NaN preserves its IEEE bits (including signed zero); every physical NaN represents the unique logical canonical NaN. Enforce canonical bits at observable conversion/model and explicit ABI boundaries. This avoids unnecessary per-operation canonicalization while preserving language observations. It is a design inferred from the pinned runtime, not a PSC0 backend preservation proof.

Implement the whole F1 executable boundary coherently:
1. Add two width-parameterized typed IR intrinsics for bit construction and bit observation. The exact signatures are UInt64 <-> Float and UInt32 <-> Float32; arithmetic/comparison capability remains separately gated until F2. Check malformed intrinsic widths/types centrally.
2. Extend checked erasure for direct/partial applications, Float.ofModel/toModel, model constructors/projections and structure recursors. Reuse prepared Model record fields and existing proof erasure. Do not identify an arbitrary UInt with a logical Float, bypass Format.Valid, or translate proof dependencies into runtime support. Keep Float.Model's ordinary checked representation separate from the primitive Float representation; use typed conversion at that boundary.
3. JS/TS share the ECMA runtime and readable helper names; exact bit conversions use DataView with explicit endianness and canonical NaN observation. Rust uses f32/f64 from_bits/to_bits with canonical observation. Wasm uses native reinterpret operations and f32/f64 GC boxes only at generic/closure crossings. All direct data and closure paths must be qualified before shared IR admission.
4. Extend the existing Wasm instruction model, validation, binary and WAT emitters together where reinterpret or floating memory instructions are missing. Active Value.lean currently admits integer boxes only. Legacy LowerFloat.lean arithmetic opcode mappings are not evidence that the active GC runtime supports Float.
5. Extend the existing Canonical ABI plan, marshal and schema emitters, rather than adding another adapter. Include f32/f64 WIT identities, 4/8-byte alignment, direct/indirect memory slots, generic aggregate fields, variant slot joins/bit reinterpretation and matching post-return signatures. Existing AbiComponent.lean hard-codes four core-function aliases and indices; derive the alias/index plan from shared typed post-return metadata when adding float results.

The [Canonical ABI reference at 2e7895c76905cd3fb7e6be4ac632258972b1f688](https://github.com/WebAssembly/component-model/blob/2e7895c76905cd3fb7e6be4ac632258972b1f688/design/mvp/CanonicalABI.md) specifies equal scalar slots keep their type; i32/f32 join to i32; other differing scalar slots join to i64. Restore variant payloads with bit reinterpretation and integer wrapping, never numeric float/integer conversion. NaN payloads are not preserved by the component abstraction. Linear memory remains restricted to explicit ABI marshaling. This reference is for those synchronous scalar/aggregate rules; it does not authorize unrelated newer async features or replace the project's pinned runtime/tool profile.

Validation should extend the existing shared native oracle and backend harness with one compact IEEE boundary corpus: signed zeros, signed infinities, subnormal/normal boundaries, several quiet/signaling NaN patterns; checked model elimination, partial applications, generic records/arrays and closures; flat and indirect mixed variants and repeated component calls. Add a wrong-width/type rejection and retain malformed ABI rejection. Reuse existing full target observations, no self-hosting. Only after all paths pass may Float/Float32 admission be enabled in CheckTypes. F2 arithmetic, F3 scientific/conversions and remaining M2+A acceptance stay distinct.

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

## 15 October — replace opaque Int arithmetic with pinned logical definitions

Pinned upstream [Int/Basic.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Int/Basic.lean)
uses Int.ofNat/negSucc, negOfNat/subNatNat, four sign cases for add/mul,
and sub defined as add with negation. These logical definitions coexist with
fast extern runtime implementations. [Int/Lemmas.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Int/Lemmas.lean)
proves add_zero/neg_neg/cast equations by definitional reduction. PSC0's
remaining Int arithmetic axioms prevented that reduction, explaining a whole
family of imported proof refusals. Matching signatures cannot solve it.

Decision: reuse the existing native-to-portable checked asset pipeline for the
entire add/neg/sub/mul family and five symbolic laws. The strict research gate
[38705122100](https://github.com/dwijayuda/pskernel/actions/runs/38705122100)
accepted 28 declarations, replacing precisely four axioms and comparing one
recursor rule. No theorem-only replacement, new assumption, or new source
syntax. Tests inspected: pinned tests/elab/intNegSucc.lean and
test_extern_int.lean (logical/native representation boundary).

The final selected stage has a separate frozen pre-arithmetic environment.
CI regenerates the exact asset including the recorded dependency cut and native
reducibility. Existing primitive audit retains the four operations as explicit
checked-logical-model/runtime-override entries. Existing typed Int erasure and
all backend intrinsics are unchanged; proof terms do not enter runtime support.
This keeps proof compatibility independent of runtime performance. Apache-2.0
attribution stays in the asset. Full integration qualification and independently
observed registry digests remain mandatory. Float F1-F4/M2+A are still open.

### New qualified /61 integration receipt

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


Status: unsigned conversion /59 and Hashable /60 are qualified. Shared word
lowering and logical foundation support are under qualification; the complete
unsigned operation slice is under native kernel qualification after explicit foundation approval. Float, signed words and expanded BitVec operations
are not enabled by this document.

All Lean references below use commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

## Dependency order and reuse

1. Retain the checked UInt/BitVec/Fin logical foundation and its typed scalar
   representation boundary. Complete word operations and BitVec numeric
   registrations using converted closed native declarations where compatible.
2. Reuse the same fixed-width operation family for arithmetic, comparison,
   division/modulus and shifts. Zero division and oversize shift behavior must
   match the native methods, rather than target operator accidents.
3. Preserve Float/Float32 logical models, then implement typed floating runtime
   representation, exact bit conversion, classification and scientific literals.
   The lexer and shared synthetic-default scheduler own token decomposition
   and OfScientific defaulting, not individual backends.
4. Complete scalar display dictionaries and selected byte/collection APIs.
   Keep the manifest and C5 occurrence/binder retention with their semantic
   owners. No additional milestone track or self-hosting requirement.

Current Standard arithmetic uses ordinary HAdd/HSub/HMul/HDiv/HMod classes
with explicit out-parameter positions. Add fixed-width instances there via
shared registrations; do not add per-type operator cases in the parser or
elaborator. The existing strict IR already has machine binary/comparison
operations and rejects unqualified scalar families.

## Unsigned and bitvector invariants

[UInt/Basic](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/UInt/Basic.lean)
and [BasicAux](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/UInt/BasicAux.lean)
define unsigned values through actual BitVec structures. Arithmetic wraps.
Unsigned division by zero gives zero; modulus by zero retains the dividend.
UInt shifts reduce the shift operand modulo the width. General
[BitVec operations](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/BitVec/Basic.lean)
accept Nat or bitvector shifts and have their own width semantics; a UInt shift
plan cannot silently stand in for arbitrary-width BitVec shifting.

The native exporter refuses unapproved new axioms, unsafe/partial declarations,
and unsupported primitives. The reviewed unsigned slice permits exactly the
two approved logical assumptions and four checked quotient descriptors. It rechecks converted data with the official kernel, and compares regenerated
constructor/recursor signatures. A name collision is not evidence of semantic
compatibility. Keep every exported asset's exact pre-admission declaration
stage and frozen name boundary.

## Floating semantics that must survive lowering

[Float](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Float/Float.lean),
[Float32](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Float/Float32.lean)
and [Float.Model](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Float/Model/Float.lean)
define wrappers around checked bit-pattern models. NaNs normalize to a chosen
canonical NaN. The model carries a validity proof; it is not a free UInt64
substitute or a newly assumed real-number theory.

- Boolean BEq treats positive/negative zero as equal and NaN as unequal to
  itself.
- Propositional/DecidableEq preserves signed zero distinction and equates
  canonical NaNs.
- ofBits/toBits and arithmetic/negation must preserve the canonical observable
  bit rules; backend-native NaN payload/sign behavior is not sufficient.
- Float-to-unsigned conversions truncate and clamp, with zero for negative/NaN.
- Binary32 operations round at each binary32 operation, including conversions.
  Float64 arithmetic followed by one final cast may double-round.

Independent reference tests:
[floatEquality](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/floatEquality.lean),
[floatBits](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/floatBits.lean),
[floatModelDefeq](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/floatModelDefeq.lean).
The last demonstrates kernel reduction of concrete arithmetic; opaque placeholder
definitions would lose required behavior.

## Scientific conversion

[OfScientific](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/OfScientific.lean)
has an exactly-representable fast path and a checked model fallback.
Float's default OfScientific priority is 501, above Neg Int's 500.
The fallback bounds huge exponents before computing powers of ten and handles
subnormal rounding. Reuse these semantics and the pinned
`tests/pkg/ofScientific` oracle; avoid parsing into host floating values before
type selection or treating scientific tokens as already-rounded binary64 data.

Wasm floating values remain scalar f32/f64 and GC boxes at generic crossings.
Linear memory is permitted only by the explicit component ABI. Extend the
existing typed Canonical ABI flat-slot plan for floats, including its join and
bit-reinterpretation rules; do not build a second ABI planner.

This research does not establish implementation, runtime parity or full M2+A
completion. Native logical admission, runtime conformance and performance
remain distinct evidence.

## Unsigned operation closure review

The native-only authoring candidate selects all four widths' add/sub/mul,
div/mod, neg/complement, bitwise and/or/xor, and left/right shifts together.
It also selects the actual Nat.div logical definition, replacing the earlier
axiom in the candidate replay base. Native division bound proofs unfold that
model; retaining an axiom at this dependency cut would be invalid reuse.

References additionally studied: `Init/Data/BitVec/BasicAux.lean`,
`Init/Data/Nat/Div/Basic.lean`, `tests/compile/uint_fold.lean` and
`tests/elab/bv_uint.lean` at the pinned commit. Logical export, instance
registration and runtime selection remain separate. The authoring command
cannot modify the compiler's admitted environment. All candidates undergo
fresh trust-zero kernel replay before source transport. No qualification or
public availability of this operation closure is claimed until it is reviewed,
integrated and checked across the existing target matrix.

### Shared integer operation lowering

The existing machine-integer operation family now carries division, remainder
and shifts. Division/remainder guard zero; signed minimum / -1 wraps without
trapping. Shift amounts reduce modulo the value width, including 8/16-bit
values on a 32-bit Wasm stack. Operands evaluate once. Negation and complement
reuse subtraction and xor with width-correct constants.

Direct JS/TS and the legacy TS printer share one ECMAScript numeric expression
plan. Rust uses wrapping operations and explicit zero guards. Wasm uses pure
scalar helpers, with no memory allocation; its word descriptor continues to
supply one mnemonic/opcode/signature to both WAT and binary output. Pinned
`src/include/lean/lean.h` supplies runtime edge-case semantics. Additional
signed helper coverage remains gated by the signed Standard/IR milestone.
Opcodes were verified against the official
[Wasm numeric instruction encoding](https://webassembly.github.io/spec/core/binary/instructions.html).
Source exposure and all-target conformance await logical closure review.

### Required logical recursion dependency

Candidate run38466911457 passed all existing /60 qualification gates, then
refused `Acc` at the authoring policy. The complete unsigned bound-proof
closure uses function-valued recursive fields in this proposition. This is a
missing logical iota mechanism, not a reason to replace the proof with an axiom.

At the pinned Lean commit, `kernel/inductive.cpp` (`is_rec_argument`,
`mk_rec_rules`) abstracts each recursive field's dependent function telescope,
then recurses at its instantiated indices and applied field value.
`Lean/Meta/WHNF.lean:reduceRec` applies the generated rule to parameters,
motives, minors and fields. Relevant upstream tests include
`tests/elab/casesOnAcc.lean` and `indPredRecursion.lean`.

PSC0's single-family iota now constructs that telescope using capture-avoiding
bound-variable lifting. Its existing recursive-field indices suffice; no new
wire schema or stored rule language is needed. The exporter admits reflexive
**propositions** only, still refusing nested/mutual families and computational
reflexive datatypes. Every exported constructor iota rule is now compared
symbolically with the actual pinned native rule after fresh kernel replay.
This does not enable general source well-founded or higher-order recursive
runtime compilation; those remain M3+B with their full acceptance criteria.

## Required Lean logical foundation (reviewed dependency, qualification pending)

The complete 48-operation unsigned candidate at Linux 38469424406 contains
794 declarations beyond the old boundary. Its only imported axioms are
Lean's `propext` and `Quot.sound`; quotient primitives support the checked
`funext` theorem in native arithmetic proof dependencies. A fully populated
quotient family adds the previously unused `Quot.ind` metadata. The canonical
language inventory already requires Lean's quotient foundation with restricted
source use. This dependency is implemented here; general runtime quotient
support and source proof automation are not implied.

Studied pinned `src/kernel/quot.cpp`, `Lean/Declaration.lean`,
`Lean/Meta/WHNF.lean:reduceQuotRec`, `Init/Prelude.lean:Quot.sound/funext`,
`Init/Core.lean:propext`, `tests/elab/quotInd.lean` and the security regression
`tests/elab_fail/kernelQuotNameCollision.lean`. The latter requires collision
rejection before kernel insertion; a quotient is not an ordinary axiom or
inductive. The upstream quotInd example uses admit, so it is a semantic source
reference, not accepted validation evidence.

Portable Core now distinguishes four kernel quotient descriptor kinds. The
official provider submits Lean's generative `quotDecl`, then checks every
regenerated signature and kind. No unchecked insertion or overwrite is used.
WHNF reduces registered lift/ind applications on registered quotient
constructors, retaining trailing arguments. Arbitrary familiar names do not
activate reduction. The checked-admission wire format refuses these descriptors
instead of silently pretending that another provider supports them.

A proposed per-slice assumption allowlist would permit exactly pinned
`propext` and `Quot.sound`, with their original signatures. **Publishing this
trust expansion was rejected by automatic approval review; explicit user
approval is pending.** No assumption has been added to the active environment.
The exporter still refuses all new axioms. CI verifies refusal of the full
unsigned candidate and continues the existing /60 integration suite. The
candidate is not qualified or admitted. If approved, these imported Lean
foundation assumptions must appear in the strict snapshot and manifest. No arbitrary/source axiom,
`Classical.choice`, sorry, unsafe definition or proof replacement is allowed.
Previous “no new axioms” receipts describe their historical snapshots; they
must not be used to conceal this intentional trust-boundary expansion.

### Concrete pending assumption change

If authorized, the native export specification would allow exactly
`[`propext, `Quot.sound]` for this slice and no other axioms. Native signatures:

```lean
axiom propext {a b : Prop} : (a ↔ b) → a = b
axiom Quot.sound : ∀ {α : Sort u} {r : α → α → Prop} {a b : α},
  r a b → Eq (Quot.mk r a) (Quot.mk r b)
```

The signatures come from pinned Init/Core.lean and Init/Prelude.lean. The
exported proof bodies would remain unchanged; all converted declarations
would undergo fresh official kernel replay. The snapshot and final assumption
manifest would distinguish these two foundations from ordinary definitions
and from the four generative quotient primitives. Arbitrary axiom import,
source axioms and runtime quotient emission remain refused. Approval covers
this explicit logical assumption delta; it does not certify compiler soundness
or native/backend semantic equivalence.

### Approval received

On 14 October 2026 the user explicitly approved: “Approve these two pinned
Lean assumptions.” The unsigned candidate now has exactly this per-slice
allowlist. Earlier blocked/pending statements above record the review history;
there is no remaining approval blocker for this delta. Candidate export,
public admission and full qualification remain separate subsequent steps.

## Signed and platform-word study (implementation still pending)

Pinned sources studied: `Init/Data/SInt/Basic.lean`, `SInt/Bitwise.lean`,
`SInt/IntToBitVec.lean`, `Init/System/Platform.lean`, and the `USize` and
`System.Platform.getNumBits` sections of `Init/Prelude.lean`. Independent
references include `tests/elab/sint_basic.lean`, `sint_conversions.lean`
and `sint_div_overflow.lean`.

Signed wrappers contain the corresponding unsigned bit pattern. ofInt wraps,
toInt interprets the sign, toNatClampNeg clamps negatives, and widening signed
conversions sign-extend. Division truncates toward zero and remainder follows
the dividend sign. MIN/-1 wraps and MIN%-1 is zero. Signed shifts take a
nonnegative modulo-width count and right shift sign-extends. Reuse the shared
word-operation lowering; give conversions explicit typed semantics rather than
silently reusing unsigned conversions.

Platform width is a separate semantic input. Native getNumBits is a checked
opaque function returning a subtype whose witness proves width is 32 or 64;
its 64-valued inhabitant is not a theorem that the runtime width is 64. The
existing Rust usize/isize printers and Wasm host stack width must not silently
decide source semantics. Before enabling USize/ISize, select and record the
portable target's word width in one shared configuration and carry that choice
to IR normalization, all emitters, ABI planning and conformance metadata. A
64-bit qualification does not establish 32-bit behavior. No new platform
assumption is authorized by the propext/Quot.sound approval.

## Universe-general product foundation

Candidate replay38470857650 validated the isolated quotient foundation,
including lift/ind kernel computation, forged-signature refusal and primitive
name-collision refusal. It then rejected a native arithmetic proof using
Prod.{u,v}: PSC0's existing Prod was restricted to Type0. This is a shared
foundation mismatch, not a property of that individual proof.

Pinned references: Init/Prelude.lean:Prod, Init/Data/Repr.lean:Prod.reprTuple,
Init/Data/Format/Instances.lean, Init/Data/Hashable.lean, and
Lean/Elab/Structure.lean's projection reducibility. The native regression
tests/elab/grind_product_eta_and_split.lean also exercises product
elimination/eta, but is not evidence for PSC0's universe implementation.

One shared builder now owns Prod, mk, rec and its two checked projections.
Element levels are independent, the result is Type(max u v), and the recursor
has an independent motive sort. The same levels flow through Inhabited, BEq,
ReprTuple, Repr, ToFormat and Hashable. Remove the old projection assumptions
and exact Type0 signature exceptions; native signature comparison now audits
all five product declarations. Ground consumers still instantiate zero levels.

The focused fixture compares mixed-universe left/right projections and pattern
elimination, defaults, equality/inequality, display and hash composition with
the official pinned native classes. Existing all-target observations are
retained. This change awaits native compilation, strict snapshot review,
candidate replay and the broader integration gate; no completed qualification
or M2+A completion is claimed here.

The native signature audit canonicalizes universe arithmetic with pinned
Lean/Level.lean:Level.normalize after parameter renaming. This respects
Level.isEquiv's normalization rule (including successor/max distribution);
it does not delta-unfold declarations or accept arbitrary type mismatches.
Failure diagnostics retain both original signatures. The compiler and
independent mixed-universe native oracle compiled at Linux38472091325;
full replay and integration remain pending.

## Native definition cuts, not name-only reuse

Linux38472303998 passed normalized product signatures and the isolated
quotient gate. The next proof refused was instDecidableIff._proof_1:
its decision must compute Bool equality, but PSC0's old Bool.decEq was an
axiom. Pinned Init/Prelude.lean:Bool.decEq and Init/Core.lean's
Decidable-Iff instance show the required reduction through the reflected Bool.

Candidate closure selection now traverses reached native safe definitions or
theorems that had been represented as portable axioms. It replaces exactly
those reached declarations, records the replacement list, and retains unused
base primitives. Conversion and fresh official kernel replay remain mandatory;
proof bodies and acceptance are unchanged. Actual native opaque primitives
retain their existing boundary. This removes the general invalid cut, including
Nat.div and Bool.decEq, without a growing list of failing-proof exceptions.
After review/admission, the asset's resulting name cut is frozen as before.

The same Prelude study also identified a source-level mismatch in the existing
portable BEq Bool dictionary: it split the left operand, whereas Bool.beq
splits the right. Closed truth tables coincide, but the required open reduction
(a == true) = a does not. The shared dictionary now uses the native orientation,
with one independent native/portable rfl conformance witness. No new primitive
or specialized elaborator rewrite is involved.

The next replay (38472745065) found List.reverse_cons, exposing definition
rather than assumption compatibility. Before changing collection algorithms,
the native authoring replay now collects all independent kernel failures and
their blocked dependents. No rejected declaration is inserted, and any failure
prohibits source export. The production checker is unchanged. Separate CI
steps run candidate diagnostics and current-source checks after a successful
build; the workflow still fails if either gate fails. This gives one complete
dependency picture and independent snapshot evidence in the same run.

## Complete List computation-boundary repair

The aggregate inventory38473183392 found exactly one independent kernel
failure (List.reverse_cons), with 25 blocked dependents. It also independently
reported the strict digest drift from the reviewed product/Boolean changes.

Pinned Init/Prelude.lean:List.foldl orders the accumulator type/universe before
the element type/universe. PSC0's public declaration and all explicit Standard
callers (Array.foldl, formatting and hashing) now follow that order. The private
structural worker remains an implementation detail. A mixed-universe named-type
fold case checks this convention against native Lean and all runtime targets.

Pinned Init/Data/List/Basic.lean:reverseAux/reverse and the accompanying
reverseAux_cons/reverse_cons proofs require a named accumulator recursion.
The checked portable reverseAux now has those same open equations, and reverse
calls it with []. This keeps linear traversal and shared structural lowering.
Native signatures of foldl/reverse/reverseAux join the audit. The imported
native proof closure checks the general equations beyond the compact fixture.

Frozen export cuts remain exact name sets. Fresh replay uses the complete
explicit pre-admission stage so checked implementations may acquire helper
dependencies without dropping them from replay. Candidates/replacements are
removed from that stage before insertion, preventing collisions. New helpers
do not silently change old asset cuts; all three prior assets must still
regenerate byte-for-byte. Standard snapshot drift remains a separate strict gate.

Large candidate source transport exceeded the GitHub job-log connector's
response capacity at run38473683098. Source review therefore uses eight
bounded read-only artifact log parts, each carrying its position, full length
and SHA256. The native compiler still emits and kernel-checks the whole asset
once; these readers neither compile nor admit it. The main log retains concise
replay/snapshot receipts. Full byte-for-byte regeneration remains required
after source admission. This is transport infrastructure, not a new compiler
milestone or an acceptance relaxation.

## Complete unsigned scalar display dictionaries

Pinned Init/Data/Repr.lean delegates UInt8/16/32/64 rendering to toNat and
marks those types ReprAtom. Init/Data/ToString/Basic.lean uses the same natural
display; the existing lower-priority ToFormat fallback must therefore work
without a UInt-specific formatter. Init/Prelude.lean gives each a zero default.

Sixteen checked ground dictionaries provide Inhabited, ToString, Repr and
ReprAtom for the four qualified widths. They reuse the existing conversion,
natural renderer, class registration and runtime erasure paths. No new
rendering intrinsic or backend formatter. Three compact observations plus the
independent native oracle cover all widths, fallback formatting, zero defaults
and atomic list layout. Qualification is pending. Signed/platform and floating
display remain dependent on their own faithful scalar models.

## Structural sharing before large asset admission

Linux38474304332 fully kernel-checked the 803-declaration unsigned candidate,
with exactly two approved imported assumptions and all 33 recursor rules
matching the native generated rules. The List repair removed the last replay
failure. Strict current-source digest drift was independently reported; the
candidate has not yet entered the compiler environment.

The initial source renderer expanded repeated proof expression trees into
23,489,134 bytes. Before admission, the host-only renderer now interns exact
name/level/expression nodes into shared ordinary Lean constants. The design
follows pinned Lean/Util/ShareCommon.lean and Init/ShareCommon.lean's
map/set architecture; it deliberately avoids their unsafe pointer/object
primitives. Keys include constructor tags, exact names and all child identities,
so it preserves binding and declaration contents rather than alpha-collapsing
proofs. Postorder creation gives deterministic, acyclic references.

Earlier small frozen assets retain their existing textual format and must
still regenerate byte-for-byte. New large slices opt into sharing through
the same source renderer. No decoder, new Core constructor, native-host
dependency or trust bypass enters the portable compiler. Official replay,
native recursor comparison, later compiled-asset replay and exact regeneration
remain required. Record the measured reduction after qualification.

## Unsigned operation admission candidate, 14 October

Linux [38475351678](https://github.com/dwijayuda/pskernel/actions/runs/38475351678)
checked 803 converted declarations, exactly propext/Quot.sound, four generated
quotient primitives and 33 symbolic recursor equations. Source interning emits
49,978 exact typed nodes and reduces 23,489,134 bytes to 6,457,592 bytes.
The complete source was retrieved through eight bounded read-only artifact
receipts with common SHA-256 b33dc2e256f17da29a3236a24c2d8267bf04de4338d73c568cafc44ee686f2de.
Temporary transport jobs are removed after review. Regeneration now freezes the
hash-stage cut and requires byte-for-byte identity with the admitted source.

The operation stage replaces six old axioms with checked native definitions,
adds the approved proof closure and 24 ordinary arithmetic/Neg dictionaries.
Only dictionaries join runtime support; the proof closure remains logical data.
One shared compact vector family covers all 48 methods, wrapping, zero divisors,
shift masking, exact 32-bit multiplication, generic dictionaries and partial
application, independently checked against the pinned native library. Product,
List and unsigned display additions remain in the same qualification batch.
This is profile /61 under qualification; /60 is the last fully green boundary.
M2+A remains incomplete, including unsigned comparison/conversion dictionaries,
signed/platform words, Float/scientific, expanded BitVec and selected APIs.

## Native digest cost and /61 snapshot review

Linux38476108793 compiled the data module in 180 s (28 s C compilation), with
222,087 ms total cold build and 595 ms no-change build. All four frozen source
assets regenerated byte-for-byte; the unsigned slice passed fresh kernel
replay and 33 recursor comparisons after compiled admission. The strict pins
then refused the deliberately changed registry, reporting FNV
`fnv1a64:16613033526791726173` and SHA-256
`sha256:8aea3c6be714db09f4a5a442e9fab57a40bdf13c11d86e811c2574165d55b04d`.
These observed values are now reviewed and pinned; neither gate auto-accepts.

Every CLI invocation spent about 73 seconds before producing output. Source
inspection identified the closed Standard validator and boxed-Nat checksum
arithmetic. Pinned Lean LCNF/ExtractClosed.lean and NeverExtractAttr.lean explain
why closed pure computations can move into initialization. The direct fix is
to express the existing FNV-1a and SHA-256 algorithms with native UInt64/UInt32
words and packed bytes, and serialize once for joint validation. This retains
the canonical payload and the independently observed digest values, with all
existing known-answer and drift-refusal gates. No checksum primitive or
assumption is added. [FIPS 180-4](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf)
sections 4.1.2/6.2 specify the same word arithmetic. Native operations were
studied in the pinned UInt and ByteArray sources. Runtime timing remains to be
measured; do not claim a speedup before CI evidence.

Build cache keys now retain the exact toolchain identity while Lake validates
changed module/configuration traces. One exact old-key fallback seeds this
transition; remove it after the new cache is populated. Source/ABI checks stay
mandatory.

## Quotient admission and runtime identity boundaries

Run38478159236 passed build, exact asset regeneration and reviewed strict
digests, then exposed two integration invariants. This repair is under
qualification; /60 remains the last full green.

Pinned Lean `src/kernel/quot.cpp:environment::add_quot` generates four constants
atomically, checking all names first. The kernel operation itself is idempotent,
but `src/Lean/Environment.lean:addDeclCore` publishes declaration names to
AsyncConsts on each call, where duplicates panic. PSC0 now checks for a complete
kernel quotient group before generation, refuses partial/colliding groups and
validates every supplied member's type, universe parameters and kind against
the generated metadata. Repeated descriptor validation never re-adds the group.
Other declaration duplicate semantics are unchanged. The existing isolated probe
now also validates reverse replay and rejects forged existing signatures/provider
collisions. References: pinned `Lean/Declaration.lean:getNames`,
`tests/elab/quotInd.lean`, `tests/elab_fail/kernelQuotNameCollision.lean`.

Pinned `Init/Prelude.lean` defines Unit/Unit.unit as PUnit/PUnit.unit
abbreviations. Native proof-closure admission converted PSC0's previous axioms
to those checked definitions. Ordinary definition lookup then hid the old late
Unit literal fallback. Nullary runtime identities now have one shared boundary,
before definition resolution for constants and applications; overapplication
is refused. Unit/PUnit share the existing unit carrier after type normalization.
Bool and Nat nullaries use the same mechanism. The obsolete late fallback is
removed; no proof closure is pulled into runtime support.

Pinned `Lean/Compiler/LCNF/Types.lean:toLCNFType` expands type definitions;
`ToLCNF.lean` separates proof/type erasure, constant handling and eta saturation.
PSC0 retains its smaller typed IR and explicit audited builtin representation,
rather than importing host LCNF or its erased/any runtime convention.
Implementation is original; no copied upstream source.

Latest digest optimization evidence: run38478159236 native rebuild12,317ms,
warm561ms; audit/export calls roughly2–5s versus about73s previously. The
migration cache fallback is removed now that the new cache is populated.
Complete backend qualification remains required.

## Kernel environment owns checked replay

Run38479812733 passed the quotient probe, exact asset regeneration and the
GetElem source/erasure gate. It then exposed imported private-name collisions
in Lean's elaborator AsyncConsts index: Nat.bitwise.eq_def from two different
native modules has distinct full names but the same normalized display name.

The checker and authoring replay now retain `Lean.Kernel.Environment` directly.
Pinned `Lean/Environment.lean` exposes the official checked
`Kernel.Environment.addDeclCore` (`lean_add_decl`) independently of elaborator
asynchronous publication. Start from `(← Lean.mkEmptyEnvironment 0).toKernelEnv`;
every insertion still goes through the official kernel with the existing limits.
No raw/unchecked insertion, renaming, proof alteration or additional assumptions.
The imported native environment remains a Lean environment for source metadata;
only the standalone checker/replay state changes. The provider admission caller,
native batch checker and dependency probe share this boundary. Its legacy
admission module is compiled as an additional native root to check API coherence.

This removes the entire family of display-name collisions while preserving exact
kernel identities. Quotient group/member validation remains, including checking
the kernel's quotInit invariant. The admitted asset itself already contains both
distinct private declarations and exercises the behavior.

That run also reached a newly added fixture whose List.foldl call put named
arguments before positional ones. PSCV0 APP-03 deliberately requires the opposite
order. The fixture now places α/β last; parser acceptance criteria are unchanged.
The full /61 integration matrix remains pending.

## Four-width signed operations and checked Float toBits candidates

The pinned `src/Init/Data/SInt/Basic.lean` defines Int8/16/32/64
as wrappers over UInt8/16/32/64 and implements add/sub/mul modulo 2^width;
sdiv/srem via `BitVec.sdiv/srem`; shifts via signed modular reduction.
The pinned `src/Init/Data/BitVec/Basic.lean` defines `smod` as Euclidean
signed modulus; `src/include/lean/lean.h` applies the matching
`((int8_t)amount % 8 + 8) % 8` rule before shifting.
This justifies using a width mask for power-of-two signed shift counts
in the checked runtime planner, **but does not qualify it without differential
tests including negative shift amounts**.

The native-only current candidate selects all source operation families
for four fixed widths while keeping ISize target width separate. Independent
F1a `toBits` projection export probes whether checked read-only bit
transport can avoid the `Classical.choice` dependency of `ofBits`.
Both are subject to official kernel replay, exact assumption review and
all existing negative conformance; neither automatically enables runtime IR.

## 14 October — signed proof closure diagnosis and coherent BitVec selection

CI [38547078451](https://github.com/dwijayuda/pskernel/actions/runs/38547078451) at `189b89b94d9d2f9bf705c6a7eda6ed30aca96d90` independently accepted six `Float.toBits`/`Float32.toBits` Core declarations, zero new axioms, but **refused** the larger signed root selection. The error is real: native `Int.add_zero`, `Int.neg_neg`, `Int.natCast_*` and similar proof bodies exhibit application/declaration type mismatches against PSCV0's selected Int model, leaving other recursive arithmetic dependencies blocked. It is not a reason to turn Int lemmas into axioms or to disable kernel validation.

The next isolated candidate selects the pure BitVec-backed signed width operations (`ofNat`, `toBitVec`, `ofBitVec`, add/sub/mul/div/mod, neg/complement and bitwise Boolean operators) for Int8/16/32/64. Int-valued conversion, signed shifts, comparisons and general `OfNat` registrations remain unselected until their exact native logical and checked-Int dependencies can be reconciled. A green candidate alone does not grant runtime execution. F1 read-only Float projections are captured as an independently reproducible native asset.

## M2+A signed fixed-width runtime implementation — qualification pending

After the 62-declaration checked signed BitVec operation stage, the common typed
IR now admits portable signed `Int8/16/32/64`, still **refusing** target-sized
`ISize/USize` and floating primitives. The same machine arithmetic intrinsic
and width plan serve unsigned and signed values; a new `signedOfNat` intrinsic
is explicitly typed, uses two's-complement low bits, and has target-specific
ECMAScript BigInt.asIntN, Rust wrapping casts and Wasm GC natural-limb
low-word lowering. Signed literal ranges are independently checked; a signed
complement constant uses canonical -1, not an illegal unsigned all-ones
literal. Canonical ABI planning, WIT primitive codes and signed narrow loads
share one signed scalar descriptor, extending i8/i16 from linear ABI memory
via sign extension. This is an **implementation checkpoint**, not qualified
backend parity or a completed M2+A exit; Linux integration and differential
native-oracle checks remain mandatory. Primary pinned sources:
`Init/Data/SInt/Basic.lean`, `Init/Data/BitVec/Basic.lean`,
`src/include/lean/lean.h`, `tests/elab/test_extern_int.lean`.

## Signed native oracle and cross-target regression slice

The selected checked Int8/Int16/Int32/Int64 BitVec operations are exercised
by one source fixture that is independently compiled to JS, strict TS and
Rust. Twenty-two signed value observations cover wrapping overflow, unsigned
source bit input, signed /0 and %0, min/-1, negative remainder, negation of
minValue, complement and bitwise operations. A native Lean 4.35.0 oracle
runs these same numerical cases using the original pinned Int8/16/32/64
methods and checks exact expected signed results. Separate IR negative
gates refuse an unsigned `signedOfNat`, platform-width operations without
a profile, and signed literals outside the canonical range. This is
regression qualification, not a theorem of compiler-wide semantic preservation;
Wasm GC and component transport need their own execution evidence.

## Dedicated signed Wasm GC and Canonical ABI conformance

One compiled nine-function signed source fixture now exercises direct GC
Wasm and generated signed WIT component exports for i8/i16/i32/i64.
Eleven edge vectors cover min/-1, divide/modulo by zero, signed
remainder, wrapping addition/subtraction/multiplication, and i64
limits, with direct binary↔WAT roundtrips and signed WAVE values.
The signed scalar ABI is checked against Wasmtime as well as V8 GC.
The underlying checked Standard remains strictly hashed; no
floating arithmetic or platform-width scalar is enabled by this test.

## Signed core-to-canonical-bits conversion and Wasm observation repair

The 22 native-oracle-observed signed results revealed a genuine missing IR
edge: the generated Wasm Bool comparison wrappers had treated every numeric
result as Nat, incorrectly applying Nat.beq to signed Int8/16/32/64 output.
Instead of skipping observations, the typed IR now exposes
`signedToUnsigned` only for the four pinned fixed widths; its checked
signature maps signed iN to the corresponding unsigned uN bit carrier.
The signed constructor projection and `toBitVec` use this same explicit
representation operation. JS uses exact `BigInt.asUintN` on source values,
Rust uses the same-width unsigned bitcast, and Wasm masks narrow signed
words on its unboxed i32/i64 stack. The Wasm observation source checks
`UIntN.toNat(IntN.toUIntN(result))` against the native oracle's exact
low N bits, retaining every signed case. Unsized ISize and arbitrary
floating operations remain refused. An independent nine-function Wasm
GC/component fixture also exercises signed s8/s16/s32/s64 with negative
edges and direct binary/WAT round trips.

## Generic fixed-width signed class registration (M2+A)

The signed class-registration stage intentionally shares
`psStandardBinarySpecs`, `psStandardBinaryInstance` and
`psStandardRegisterInstances` with UInt and Nat. It declares per-width
HAdd/HSub/HMul/HDiv/HMod/Neg using real kernel-checked signed BitVec
methods and `OfNat` via the checked `IntN.ofNat` construction.
`BEq` compares the exact canonical two's-complement `UIntN` carrier,
which is injective for signed wrappers; `Inhabited` constructs zero.
No parser-specific behavior, fabricated proofs, unsafe coercions or new
assumptions. Source/operator and runtime parity await a full Linux pass
and newly independently observed Standard snapshot digests.

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

## M2+A selected signed-to-Int snapshot — independently observed (14 October 2026)

The native Lean 4.35.0 kernel compiled all four `IntN.toInt` implementations and the source-model equality certificates at `09965258ad0fb0c206fe7ea7a0386241b5078496`. The pinned semantic audit independently refused a missing `implicit_reducible` status at `6fe1a56`; commit `09965258` corrected it to the exact upstream metadata without relaxing any checks. [Linux 38563557310](https://github.com/dwijayuda/pskernel/actions/runs/38563557310) then correctly refused the previous Standard fingerprint and independently observed **FNV `fnv1a64:12853239104520417295`** and **SHA-256 `sha256:7b6a29baea2279dc88dd94de1635937a23befd79830330874daeb5fdad778c43`**. Both are now pinned unchanged in the strict registry guards. The projected selected Standard is **1,683 declarations, 23 classes, 189 ordered instances** (previously 1,679 declarations). The four definitions add no search instance or axiom and are generated from the identical native `BitVec.toInt` two's-complement formula. **Full execution qualification is still pending**: next Linux run must pass ten common-source conversion vectors and all other JS/TS/Rust/Wasm GC/Wasmtime checks. Last fully green is the earlier `fe88e7f` signed/bitvector model proof checkpoint (27 steps, 457 runtime observations). Signed shifts, comparisons, `IntN.ofInt`, Float, platform-width integers and comprehensive Phase A exit remain incomplete.


## 15 October — checked Int arithmetic family QUALIFIED

Exact qualified source: `e322eff798a96db14b5deed24824ccf3c2fcc783`. [Native Linux CI 38706796031](https://github.com/dwijayuda/pskernel/actions/runs/38706796031) and [independent portable Float replay 38706795768](https://github.com/dwijayuda/pskernel/actions/runs/38706795768) both **passed** at this SHA. All 28 native job steps passed, including exact regeneration, 699 shared observations on each JS/TS/Rust target, GC Wasm/component execution and repeated Wasmtime calls.

Selected Standard: **1,856 declarations /25 classes /226 instances**; FNV `fnv1a64:17912930455396537674`, declaration SHA `sha256:a0f90d4ba911bd9be249bd72f8f0443e582eea41f21a56d192f27efb6b24ff44`, surface SHA `sha256:6c4c0803cb69b893926325dccd19ca9930425c2a051e8fdd1770bbc3c2d71b6c`. The exact 28-declaration /9-root asset provides native checked Int.add/neg/sub/mul definitions and original symbolic laws, replacing four computational axioms with no new assumptions or theorem substitutions. Fast runtime overrides are unchanged and explicitly audited.

**Next causal blockers, isolated research only:** expanded four Float mask bridges at `cee61377f12fe465238ca5b474422e43575a3761`, [38706081222](https://github.com/dwijayuda/pskernel/actions/runs/38706081222), were refused. The first genuine mismatch is monomorphic selected `List.get!Internal` versus native universe-polymorphic use. Later timeout cascades require per-independent-admission heartbeat isolation already used by source admission. Investigate and strengthen the whole List indexing family and host audit scope; keep 2,000,000/20,000 limits, official kernel admission, and failed dependencies blocked. Do not select the 922-declaration expanded Float candidate or claim executable Float/M2+A completion. Update both handoffs at the next slice.


## Array universe family prepared; F3 remains unselected — 15 October 2026

F3 [38731735348](https://github.com/dwijayuda/pskernel/actions/runs/38731735348) found 134 candidate declarations, no new assumptions, and one general dependency mismatch: PSC0's monomorphic Array versus Lean's universe-polymorphic Array. The native `ofScientific` fast-path tables and their proofs require the native family. The repair preserves the checked list-backed logical model and existing runtime layouts.

Studied pinned Lean 4.35.0 `Init/Prelude.lean` (Array, mk/toList, size, getInternal, push), `Init/Data/Array/Basic.lean` (map/foldl), and tests `compile/{array,arrayMk}.lean`, `elab/{arrayGetU,array_map_module}.lean`. Element universe u is propagated through Array and its complete selected operation family; recursor motive and map/fold result universes are independent. GetElem/GetElem?/LawfulGetElem, Inhabited, Hashable, Repr and ToFormat dictionaries carry the same universe parameters. ByteArray specializes to universe zero. Seven obsolete Type-0 signature exceptions are replaced by exact normalized native signature checks; the explicit fold-bound default policy remains separately recorded.

One shared fixture adds eight cross-universe runtime observations (map both ways, fold both ways, default, formatting, repr, hash), plus generic checked list/size identities. Existing Array, ByteArray, proof assets and all-backend suites remain required. Strict manifest pins are intentionally unchanged until the independent CI measurement is reviewed. No limits, logical assumptions, runtime layout, self-hosting or C5 changes.

This research branch also incorporates F2 shared constant/application erasure from `c3081a0e0c102ba8f8fad16940301af893dcfe5b`. Its independent [F1 replay38733051176](https://github.com/dwijayuda/pskernel/actions/runs/38733051176) and [F2 replay38733051136](https://github.com/dwijayuda/pskernel/actions/runs/38733051136) pass; [full native38733051228](https://github.com/dwijayuda/pskernel/actions/runs/38733051228) is still in progress. Finish F2 exact-main qualification before integrating this Array/F3 work. Current Array changes are prepared, not yet qualified; F3 scalar declarations and source syntax remain unselected.

