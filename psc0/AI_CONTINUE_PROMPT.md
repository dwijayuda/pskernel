# Continue PSC0 / PSCV0 v7 M2 + Phase A

## Literal constraints and homogeneous operators prepared — 15 October 2026

This F3 prerequisite now reuses the six native checked homogeneous classes and H* bridges already present in the selected logical assets. The selected final instance catalogue replaces redundant ground H* search entries with homogeneous ground dictionaries built from the same checked operation values. No class or bridge body is copied or replaced. Six native bridges are ordinary/default instances at priority 1000; OfNat Nat defaults at 100 and Neg Int at 500. Earlier logical asset boundaries remain immutable, and the final runtime catalogue emits the selected dictionaries and native bridges.

Numerals now follow pinned Lean `Lean/Elab/BuiltinTerm.elabNumLit`: a fresh Type-valued target, expected-type constraint, raw Nat parameter and shared synthetic OfNat goal. Applications and literals share one constraint-completion operation. The special source-level Nat fallback and its unused defaulting flag are removed. This preserves local OfNat dictionaries, enables adjacent-operand inference and allows generic Add/Sub/Mul/Div/Mod/Append code.

Primary references: pinned `Init/Prelude.lean`, `Init/Data/Int/Basic.lean`, `Lean/Elab/BuiltinTerm.lean`; tests `elab/{hmulDefaultInstance,dotNotationAndDefaultInstance,ofNat_class}.lean` and the previously qualified default-instance tests. The native signature audit now checks all 24 selected class/constructor/projection/bridge identities. The registry audit checks the replacement rules and exact default priorities.

One paired native/source fixture adds 14 shared observations (intended total **872**): all six bridges, custom numeric operands on either side, local OfNat Nat override, Nat/negative defaulting, a higher universe, executable Float generic addition and heterogeneous multiplication. Existing refusal checks and full backend/integration/performance gates remain mandatory. Strict registry/surface pins intentionally retain the previous qualified values until independent cloud measurement is reviewed. **This slice is prepared, not qualified.**

Default-instance integration is fully qualified at `5e07de1006ab3539888f68015b3470bdfd921cf8`: [native38745398231](https://github.com/dwijayuda/pskernel/actions/runs/38745398231) passed all 30 steps and 858 shared observations; independent F1 38745397954, F2 38745398267 and F3 logical 38745398095 are green at the same commit. Main docs receipt: `899f3e295e544955ace2b58c6c24d28cda3f22b5`.

Literal qualification correction: native38747708333 refused the missing portable Lake root; that root is registered. Native38747984746 then reported one missing explicit import and a record-update lambda layout error in the new module; both are corrected together. No semantic test, pin or budget has been weakened. Full qualification remains pending.

F1/F2 and the Array prerequisite are already qualified. F3 scientific syntax and executable conversion IR remain pending; its 134-declaration logical candidate is still unselected. Next: finish this literal-family qualification, then exact scientific syntax/OfScientific and cross-target conversions, F4 display and remaining M2+A exits. No new assumptions, budgets, pskernel-core, self-hosting or C5.

## Working contract

GitHub canonical: dwijayuda/pskernel. Main development branch `psc0/pscv0-v7-native-lean-v1`; draft PR109 keeps its original base and must not be merged. Inspect live branch HEAD and exact-commit CI before writes; preserve history with expected-HEAD, non-force updates. Use GitHub integration and cloud Linux CI only, no local checkout/files/builds or Desktop Commander. Keep research workflows contents: read.

Pinned Lean 4.35.0: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study corresponding official source and tests before every substantial feature. Native .lean; no pskernel-core, bootstrap/self-hosting, compiler-source .ps migration or C5. Application .ps fixtures are allowed. Only approved assumptions propext and Quot.sound. Original upstream Float correspondence imports Classical.choice and remains outside the selected portable closure.

Read the latest AI_WORK_STATE.md checkpoint, docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md and docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md; canonical v7 specifications govern completion. Continue M2+A -> M3+B -> M4+C/D -> M5/E. M1 is complete; M2+A is not.

## Immediate continuation

1. Inspect fresh development/research HEAD and exact-commit CI. Record the default-instance exact-development gate, then qualify the prepared literal/homogeneous family: native oracle, explicit metadata measurements, reviewed strict pins, all existing backends and proof replays. Integrate only after qualification and update both handoffs, roadmap and PR109. Do not redo qualified F1/F2 or Array.
2. Continue the F3 numeric-literal/conversion family described above. Study the whole affected subsystem and pinned Lean source/tests before changes; implement a coherent mechanism, then use compact differential validation and the existing full backend suite.
3. F3 candidate: 42 roots /134 declarations /one recursor /3,286 shared nodes /617,019 UTF-8 bytes, SHA-256 `45e6c8b81fbd971c891d173acef36c2ce6f6c59b674a06ffc9bfbe2e8cff6391`. It covers scientific, Nat/Int and eight fixed signed/unsigned word conversions for both Float widths. OfNat dictionaries still require review; cross-width and platform-word conversions are separate logical contracts. Never silently select unchecked native opaque declarations.
4. Complete F4 display, explicit USize/ISize target profiles, authoritative Standard/manifest and remaining M2+A gates. Continue M2+A -> M3+B -> M4+C/D -> M5/E without redefining exits.

## Invariants and validation

All executable targets share typed IR. Wasm uses GC internally and linear memory only at explicit Canonical ABI boundaries. Preserve readable JS/TS/Rust/WAT/WIT. C5 Lean/ProofScript reconstruction stays deferred while retaining source information.

IEEE BEq identifies signed zeros and rejects NaN equality; logical DecidableEq compares canonical bits, distinguishes signed zero and identifies NaNs. Proof dependencies stay outside executable runtime support. Integer-to-float uses nearest-even at the selected width; float-to-fixed-integer truncates toward zero, clamps and maps NaN to zero. Scientific text never passes through host floating-point parsing.

Use existing native build targets and current cloud workflows. Authoring prepends the local Ps namespace root to Lake's LEAN_PATH. The awaited pooled-task helper resets native kernel heartbeat per independent authoring declaration; source requests retain cumulative 2,000,000-heartbeat/20,000-depth limits. No placeholders, computational axioms, unchecked casts, admission fallback or budget increases. Keep checked logical admission, runtime conformance and formal preservation claims separate.

Update AI_WORK_STATE.md and AI_CONTINUE_PROMPT.md at each milestone slice. Older checkpoint prose in the work state and roadmap is historical; this current prompt is authoritative for resumption.
