# Continue PSC0 / PSCV0 v7 M2 + Phase A
## Projection oracle diagnosis — 15 October 2026

Native38753531404 compiled the portable reducer but its independent native WHNF oracle refused the assumed reduced shape before source qualification. The oracle now reports the exact mode, expression and native dictionary status so the native invariant can be reconstructed without weakening its assertion. The Lean-reserved local variable name in the portable test is corrected, and ordinary/default/all transparency now short-circuits projection metadata lookup. No selected source or expected runtime observation changed. Full qualification remains pending; do not integrate this research checkpoint as green.

Class-projection review refinement: only names directly owned by registered classes enter speculative projection beta reduction; ordinary constants keep their fast path. The focused oracle uses explicit empty contexts and a well-scoped local dictionary. Qualification pending.

## Shared class-projection reduction prerequisite — 15 October 2026

Native38751673594 reached the older `Numeric.generic` regression and exposed a general reduction gap: instance transparency could not reduce a checked class field such as `OfNat.ofNat Nat 857 instOfNatNat` inside a dependent instance index. Restoring raw Nat literal shortcuts would hide the defect and break local dictionaries. Pinned Lean `src/Lean/Meta/WHNF.lean` (`isProjInst`, `unfoldProjInst?`, `unfoldProjInstWhenInstances?`, `unfoldDefault`) provides the correct rule; `GetUnfoldableConst.lean`, `tests/elab/instanceReducibility.lean` and `tests/elab/isDefEqProjInstWithMVar.lean` were studied.

Portable WHNF now recognizes checked generated class fields through their class constructor telescope, delta-beta reduces only that field, and reduces its actual dictionary at instance transparency. Stuck class projections retain their original application; irreducible fields/dictionaries stay blocked. Ordinary definitions do not gain extra transparency. A small independent native WHNF oracle and the existing transparency suite validate reducible/instances/implicit behavior, custom evidence, stuck evidence and irreducibility; the full existing generic-numeral/backend suite remains mandatory. No Standard declaration, pin, assumption or resource budget changed. Qualification remains pending. Scientific syntax work is prepared in memory only and has not been published or selected.

## Literal fixture invocation alignment — 15 October 2026

Native38750864793 passed parsing, all prior gates, and integrated custom literal/operator declarations, then correctly refused `literalLocalNat`: its PSCV0 function has an explicit Unit parameter but its named-dictionary call omitted that argument. The fixture now supplies `()` and its independent native Lean oracle has the same Unit telescope. The shared application rule is unchanged: only a written empty invocation inserts Unit; a nonempty named call does not silently discard a required parameter. Expected value 42 and all other observations remain unchanged. Full backend qualification is pending.

## Literal qualification syntax correction — 15 October 2026

Native run 38749641509 accepted all 3179 selected declarations and passed the strengthened registry audit, native literal/operator oracles, previous scalar assets and source checks. The integrated fixture was refused during parsing because its heterogeneous-operation example used Lean-style `if b` instead of the canonical PSCV0 `if (b)`. Only that fixture spelling is corrected. Expectations, compiler behavior, foundation and budgets are unchanged; full source/backend qualification is still pending. Independent F1/F2/F3 replays at 39a1718a1ff47dbbd7dea91967a145bb7438c176 passed.


## Literal/operator metadata review — 15 October 2026

At `195a077f9f4747ce1731a382ba471b40974ab43e`, [native38748876958](https://github.com/dwijayuda/pskernel/actions/runs/38748876958) built the compiler and independent Lean literal/operator oracles, passed the strengthened native signature/reducibility audit, and regenerated the prior checked assets. Both strict boundaries independently refused the intentional selected registry expansion and reported the same values: FNV `2999019441064509306`, declaration SHA-256 `6d8074129e70b3bd01c9d18ab92701edadf5932061e13988a491fa00c0efef10`, surface SHA-256 `0386344f5ade3df16048d155d650a7f1a197117c72971fb55002de9172a88069`. Those reviewed values are now pinned. No check, assumption or budget is relaxed.

The source closure now explicitly registers the new portable Lake root; its explicit imports and record-update layout are complete. The architecture and 14 paired observations are unchanged. Full source/backend qualification remains pending; passing the native oracles and asset gates alone does not qualify the slice. Exact-development default-instance qualification remains complete at `5e07de1006ab3539888f68015b3470bdfd921cf8` (native38745398231, 858 observations, F1/F2/F3 replay green). F3 scientific/conversion runtime selection remains pending.

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
