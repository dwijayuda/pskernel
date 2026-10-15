# Continue PSC0 / PSCV0 v7 M2 + Phase A

## Current qualified checkpoint — 15 October 2026

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

## Working contract

GitHub canonical: dwijayuda/pskernel, branch psc0/pscv0-v7-native-lean-v1, draft PR109; keep its current base and do not merge. Inspect live HEAD and exact-commit CI before edits. Preserve history with expected-HEAD, non-force pushes. Use GitHub integration/cloud Linux CI; no Desktop Commander or local checkout/build.

Pinned Lean 4.35.0: eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study corresponding official source/tests first. Native .lean only; no pskernel-core, self-hosting/bootstrap, compiler-source .ps migration or C5. Only approved foundation propext and Quot.sound. Native upstream Float correspondence imports Classical.choice and stays outside the selected portable closure.

Read AI_WORK_STATE.md's newest checkpoint, PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md and PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md (includes the studied F1 runtime continuation design). Canonical v7 reference/acceptance criteria govern completion. M1 is complete; M2+A is not. Do not equate green bounded CI with full language completion.

## Immediate continuation

1. Verify live main HEAD and preserve any later work. The exact implementation 38dbbfb9826490d02a44e6ab5b518a9946849345 passed both main workflows above; no rerun of that unchanged completed slice is needed.
2. Proceed directly to F1 executable semantics. Preserve the small selected constructor asset; do not import the entire 11 MB proof audit into the portable compiler.
3. Implement two shared typed bit-conversion intrinsics, checked Float/model erasure and partial applications, ECMA/Rust/Wasm scalar lowering, GC boxing, and the existing explicit Canonical ABI together. Account for signed zero, canonical NaN observation, generic data/closures, float variant joins and typed post-return aliases. CheckTypes currently refuses Float/Float32; keep that guard until the coherent feature is qualified.
4. Continue F2 arithmetic/equality, F3 scientific/conversions, F4 target/ABI evidence, explicit USize/ISize profiles and other authoritative M2+A obligations. Update BOTH handoff files at each slice.

Minimal meaningful tests should validate the design; reuse the existing native oracle and full backend suite at architectural milestones. Keep proof admission, runtime observations and formal preservation claims separate. Do not add assumptions, unchecked casts, fallback admission or increased limits to bypass a failure.

## Useful checks

From psc0/v7-native, native build targets: pscv0_native, pscv0_native_checks, pscv0_wasm_checks, pscv0_m1_performance. Follow current workflows for exact commands and pinned tool versions. Constructor authoring must prepend local .lake/build/lib/lean to Lake's LEAN_PATH because Ps.Host and the parent Ps namespace are split between package roots. Source application .ps fixtures are allowed; compiler-source translation is not.

Registry pins are deliberately strict. A future semantic update must first be independently measured, then reviewed and pinned; never disable the guard. The shared awaited pooled-task helper resets the actual C++ kernel counter per independent authoring declaration. IO.setNumHeartbeats only changes allocation telemetry. Source requests retain cumulative 2,000,000-heartbeat /20,000-depth limits.
