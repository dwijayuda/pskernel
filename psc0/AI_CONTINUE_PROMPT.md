# Continue PSC0 / PSCV0 v7 M2 + Phase A

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


## Working contract

GitHub canonical: dwijayuda/pskernel, branch psc0/pscv0-v7-native-lean-v1, draft PR109; keep its current base and do not merge. Inspect live HEAD and exact-commit CI before edits. Preserve history with expected-HEAD, non-force pushes. Use GitHub integration/cloud Linux CI; no Desktop Commander or local checkout/build.

Pinned Lean 4.35.0: eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study corresponding official source/tests first. Native .lean only; no pskernel-core, self-hosting/bootstrap, compiler-source .ps migration or C5. Only approved foundation propext and Quot.sound. Native upstream Float correspondence imports Classical.choice and stays outside the selected portable closure.

Read AI_WORK_STATE.md's newest checkpoint, PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md and PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md (includes the studied F1 runtime continuation design). Canonical v7 reference/acceptance criteria govern completion. M1 is complete; M2+A is not. Do not equate green bounded CI with full language completion.

## Immediate continuation

1. Verify live main HEAD and preserve later work. F1 code 262c5819c499256fcd2093746deae4ef3aa2012b passed both workflows above. Do not redo the completed F1 implementation or unchanged qualification.
2. Continue F2 arithmetic, IEEE equality/comparison and classification. Study pinned Float/Float32, Model/Unpacked Operations, Round and tests/elab/floatModelDefeq.lean. First export and kernel-replay the genuine logical dependency closure; only the already checked theorem-only cuts for Nat.pow_eq_zero and BitVec.getLsbD_of_ge may be reused. Any additional proof adaptation needs its own checked type and proof evidence.
3. Keep the small selected F1 constructor asset. The independent 11 MB canonical proof audit remains outside selected Standard. F2 typed arithmetic/comparison IR is still refused pending logical admission and coherent backend qualification.
4. Then finish F3 scientific/conversions, F4 full Float evidence, explicit USize/ISize target-profile propagation and the remaining authoritative Standard/manifest obligations. Update BOTH handoffs at each slice.

Minimal meaningful tests should validate the design; reuse the existing native oracle and full backend suite at architectural milestones. Keep proof admission, runtime observations and formal preservation claims separate. Do not add assumptions, unchecked casts, fallback admission or increased limits to bypass a failure.

## Useful checks

From psc0/v7-native, native build targets: pscv0_native, pscv0_native_checks, pscv0_wasm_checks, pscv0_m1_performance. Follow current workflows for exact commands and pinned tool versions. Constructor authoring must prepend local .lake/build/lib/lean to Lake's LEAN_PATH because Ps.Host and the parent Ps namespace are split between package roots. Source application .ps fixtures are allowed; compiler-source translation is not.

Registry pins are deliberately strict. A future semantic update must first be independently measured, then reviewed and pinned; never disable the guard. The shared awaited pooled-task helper resets the actual C++ kernel counter per independent authoring declaration. IO.setNumHeartbeats only changes allocation telemetry. Source requests retain cumulative 2,000,000-heartbeat /20,000-depth limits.
