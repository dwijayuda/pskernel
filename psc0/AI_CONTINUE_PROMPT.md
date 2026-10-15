# Continue PSC0 / PSCV0 v7 M2 + Phase A

## 15 October — minimal logical Float constructors integrated; main qualification pending

Research `41a4474b7cbbb04c9e83b4a7fae111631be58e7a` passed both [full native integration 38715004637](https://github.com/dwijayuda/pskernel/actions/runs/38715004637) and [independent full proof replay 38715004629](https://github.com/dwijayuda/pskernel/actions/runs/38715004629). All 29 native steps passed, including exact asset regeneration, source/type/runtime boundaries, 699 observations each on JS/TS/Rust, GC Wasm/component validation, repeated Wasmtime calls and performance checks. This main integration still requires the same exact-commit pair before main qualification is claimed.

The selected constructor layer adds **21 checked declarations plus two public typed wrappers**, retaining actual Format.Valid evidence. Asset: **307,290 UTF-8 bytes /1,702 shared nodes**, SHA-256 `3042b3db951a1c68f8df24c5161889841082f9f4ee03783e1e5b4da918b3f9a7`. Regeneration uses its frozen pre-constructor declaration boundary and mandatory byte comparison. The independent **30-root /922-declaration /11 MB** representation audit remains separate from selected Standard. No new assumptions, axioms or runtime overrides.

Standard now has **1,879 declarations /25 classes /226 instances**. Strict independently measured pins: `fnv1a64:9256054256618924345`; declaration `sha256:0f62a5df0a7273a183e10700bf8eb49563afd0ff8d03b7be3935d4d310a12f04`; surface `sha256:240050e325b7c7d06827c36bffe7ed017ef18680b61ccf4fa7701807a62874b4`. Logical Float.ofBits/Float32.ofBits and toBits source admission is checked, a wrong-width argument is refused, and executable Float remains refused at the shared IR gate.

The full audit's pre-constructor boundary prevents selected roots from cutting their own replay. Host authoring uses the local Ps namespace first: Lean/Util/Path.lean resolves the first root directory, so plain lake env alone is insufficient when both parent and native packages use Ps. This ordering matches the independently qualified proof workflow.

M2+A remains incomplete. Next: coherent F1 model erasure, typed IR, all backends and explicit ABI; then F2-F4, target-sized words and remaining selected language/Standard obligations. Continue M2+A -> M3+B -> M4+C/D. No pskernel-core, self-hosting, C5 or trust expansion.

## Working contract

GitHub canonical: dwijayuda/pskernel, branch psc0/pscv0-v7-native-lean-v1, draft PR109; keep its current base and do not merge. Inspect live HEAD and exact-commit CI before edits. Preserve history with expected-HEAD, non-force pushes. Use GitHub integration/cloud Linux CI; no Desktop Commander or local checkout/build.

Pinned Lean 4.35.0: eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study corresponding official source/tests first. Native .lean only; no pskernel-core, self-hosting/bootstrap, compiler-source .ps migration or C5. Only approved foundation propext and Quot.sound. Native upstream Float correspondence imports Classical.choice and stays outside the selected portable closure.

Read AI_WORK_STATE.md's newest checkpoint, PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md and PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md (includes the studied F1 runtime continuation design). Canonical v7 reference/acceptance criteria govern completion. M1 is complete; M2+A is not. Do not equate green bounded CI with full language completion.

## Immediate continuation

1. Verify this integration's exact main native and independent Float CI; record qualification when complete. Last previously qualified main code e5d1bdd6 had native38711192827 and Float38711192777 success.
2. Proceed directly to F1 executable semantics. Preserve the small selected constructor asset; do not import the entire 11 MB proof audit into the portable compiler.
3. Implement two shared typed bit-conversion intrinsics, checked Float/model erasure and partial applications, ECMA/Rust/Wasm scalar lowering, GC boxing, and the existing explicit Canonical ABI together. Account for signed zero, canonical NaN observation, generic data/closures, float variant joins and typed post-return aliases. CheckTypes currently refuses Float/Float32; keep that guard until the coherent feature is qualified.
4. Continue F2 arithmetic/equality, F3 scientific/conversions, F4 target/ABI evidence, explicit USize/ISize profiles and other authoritative M2+A obligations. Update BOTH handoff files at each slice.

Minimal meaningful tests should validate the design; reuse the existing native oracle and full backend suite at architectural milestones. Keep proof admission, runtime observations and formal preservation claims separate. Do not add assumptions, unchecked casts, fallback admission or increased limits to bypass a failure.

## Useful checks

From psc0/v7-native, native build targets: pscv0_native, pscv0_native_checks, pscv0_wasm_checks, pscv0_m1_performance. Follow current workflows for exact commands and pinned tool versions. Constructor authoring must prepend local .lake/build/lib/lean to Lake's LEAN_PATH because Ps.Host and the parent Ps namespace are split between package roots. Source application .ps fixtures are allowed; compiler-source translation is not.

Registry pins are deliberately strict. A future semantic update must first be independently measured, then reviewed and pinned; never disable the guard. The shared awaited pooled-task helper resets the actual C++ kernel counter per independent authoring declaration. IO.setNumHeartbeats only changes allocation telemetry. Source requests retain cumulative 2,000,000-heartbeat /20,000-depth limits.
