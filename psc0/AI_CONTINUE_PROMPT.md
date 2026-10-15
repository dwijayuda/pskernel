# Continue PSC0 / PSCV0 v7 M2 + Phase A

## Shared default instances qualified on development branch — 15 October 2026

Research commit `144da8fb916c63eb7057e6f2d5b6b43d465d9d87` passed [native38743248005](https://github.com/dwijayuda/pskernel/actions/runs/38743248005): **858 shared runtime observations** on TypeScript, direct JavaScript and Rust, GC Wasm/core/component execution, repeated Wasmtime calls, source/kernel/IR checks, module integration, exact assets and unchanged performance gates. Independent [F1 replay38743110807](https://github.com/dwijayuda/pskernel/actions/runs/38743110807), [F2 replay38743111243](https://github.com/dwijayuda/pskernel/actions/runs/38743111243) and [F3 logical replay38743111380](https://github.com/dwijayuda/pskernel/actions/runs/38743111380) passed at parent `9823ce526bad037e1de7da40c2485e91e7a9825b`; the sole descendant changes two fixture declarations to normative `where` syntax. Exact-development commit `5e07de1006ab3539888f68015b3470bdfd921cf8` passed all 30 native job steps in [native38745398231](https://github.com/dwijayuda/pskernel/actions/runs/38745398231), including the same 858 observations and every existing integration/performance gate. Independent [F1 replay38745397954](https://github.com/dwijayuda/pskernel/actions/runs/38745397954), [F2 replay38745398267](https://github.com/dwijayuda/pskernel/actions/runs/38745398267) and [F3 logical replay38745398095](https://github.com/dwijayuda/pskernel/actions/runs/38745398095) passed at this exact commit.

Implemented together: separate ordered ordinary/default registries; `@[default_instance priority]`; checked class-result registration; scoped, transactional dependency solving; ordinary quiescence before one default commitment; universe instantiation; public/private imports, newest-first ties and diamond deduplication. Search exhaustion rolls back rather than choosing a lower-priority fallback. Lean distinguishes success, definite failure and stuck synthesis: top-level defaults apply only to stuck goals with compatible ordinary candidates. Nested default dependencies follow Lean's reverse-telescope, goal-first policy. Native differential oracles and compact negative/budget/module checks enforce these boundaries.

Primary reference: pinned Lean 4.35.0 `Lean/Meta/{Instances,SynthInstance}.lean`, `Lean/Elab/SyntheticMVars.lean`, `Lean/Elab/Term/TermElabM.lean`; tests `elab/{defaultInstanceWithPrio,defaultInstBacktrackIssue}.lean`, `elab_fail/defaultInstance.lean`. Adaptation attribution is recorded in Synthetic.lean. PSC0 retains its immutable portable contexts and bounded tabled search.

Reviewed selected pins: FNV `7059557959118648847`; declaration SHA-256 `2b0475103206285b3107cd646ea04a365bf682aef2c4c0c8bf16d21e67c65995`; surface SHA-256 `babd8330a9143aad468400ffdf5ae27fe8b5b389e0dbe087ad83cbb4056f1388`. Snapshot v3 / surface v2 explicitly record the default registry and attribute. Roster remains **3,122 declarations /25 classes /250 ordinary instances /zero Standard defaults**. The strict pins were independently measured at both existing boundaries, not relaxed.

Array prerequisite is already exact-development qualified at `e3902f3d91556af40b85f65566ff6787620346ee` ([native38739411239](https://github.com/dwijayuda/pskernel/actions/runs/38739411239), 851 observations, F1/F2/F3 replays green). F1 and F2 executable families are complete. F3's 134-declaration logical candidate remains **unselected**; scientific syntax, literal constraints, numeric conversions, F4 display, target-sized profiles and remaining M2+A exits remain open.

Next coherent F3 work (prepared on research; not yet qualified): replace eager Nat fallback with shared OfNat constraints; implement pinned homogeneous operator/default bridges (Add/Sub/Mul/Div/Mod/Append -> heterogeneous operations) so surrounding operands constrain literals; retain exact scientific mantissa/exponent until OfScientific is chosen. Inspect existing logical declarations before adding any class. Then implement shared typed conversion IR across all backends, with direct target-width rounding. Do not implement Float32 by a potentially double-rounded binary64 intermediate. No new assumptions, budgets, pskernel-core, self-hosting or C5.

## Working contract

GitHub canonical: dwijayuda/pskernel. Main development branch `psc0/pscv0-v7-native-lean-v1`; draft PR109 keeps its original base and must not be merged. Inspect live branch HEAD and exact-commit CI before writes; preserve history with expected-HEAD, non-force updates. Use GitHub integration and cloud Linux CI only, no local checkout/files/builds or Desktop Commander. Keep research workflows contents: read.

Pinned Lean 4.35.0: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study corresponding official source and tests before every substantial feature. Native .lean; no pskernel-core, bootstrap/self-hosting, compiler-source .ps migration or C5. Application .ps fixtures are allowed. Only approved assumptions propext and Quot.sound. Original upstream Float correspondence imports Classical.choice and remains outside the selected portable closure.

Read the latest AI_WORK_STATE.md checkpoint, docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md and docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md; canonical v7 specifications govern completion. Continue M2+A -> M3+B -> M4+C/D -> M5/E. M1 is complete; M2+A is not.

## Immediate continuation

1. Inspect fresh development and research HEAD and exact-commit CI. The default-instance integration is qualified. Continue qualification of the prepared shared literal/homogeneous-operator slice on research, then record exact evidence in both handoffs, roadmap and PR109. Do not redo qualified F1/F2 or Array.
2. Continue the F3 numeric-literal/conversion family described above. Study the whole affected subsystem and pinned Lean source/tests before changes; implement a coherent mechanism, then use compact differential validation and the existing full backend suite.
3. F3 candidate: 42 roots /134 declarations /one recursor /3,286 shared nodes /617,019 UTF-8 bytes, SHA-256 `45e6c8b81fbd971c891d173acef36c2ce6f6c59b674a06ffc9bfbe2e8cff6391`. It covers scientific, Nat/Int and eight fixed signed/unsigned word conversions for both Float widths. OfNat dictionaries still require review; cross-width and platform-word conversions are separate logical contracts. Never silently select unchecked native opaque declarations.
4. Complete F4 display, explicit USize/ISize target profiles, authoritative Standard/manifest and remaining M2+A gates. Continue M2+A -> M3+B -> M4+C/D -> M5/E without redefining exits.

## Invariants and validation

All executable targets share typed IR. Wasm uses GC internally and linear memory only at explicit Canonical ABI boundaries. Preserve readable JS/TS/Rust/WAT/WIT. C5 Lean/ProofScript reconstruction stays deferred while retaining source information.

IEEE BEq identifies signed zeros and rejects NaN equality; logical DecidableEq compares canonical bits, distinguishes signed zero and identifies NaNs. Proof dependencies stay outside executable runtime support. Integer-to-float uses nearest-even at the selected width; float-to-fixed-integer truncates toward zero, clamps and maps NaN to zero. Scientific text never passes through host floating-point parsing.

Use existing native build targets and current cloud workflows. Authoring prepends the local Ps namespace root to Lake's LEAN_PATH. The awaited pooled-task helper resets native kernel heartbeat per independent authoring declaration; source requests retain cumulative 2,000,000-heartbeat/20,000-depth limits. No placeholders, computational axioms, unchecked casts, admission fallback or budget increases. Keep checked logical admission, runtime conformance and formal preservation claims separate.

Update AI_WORK_STATE.md and AI_CONTINUE_PROMPT.md at each milestone slice. Older checkpoint prose in the work state and roadmap is historical; this current prompt is authoritative for resumption.
