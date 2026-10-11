# PSKernel-Fast G4 — Symbolic universes and checked-inference plan

**Status:** prospective design gate; implementation NOT started. Lean semantics pinned to 4.35.0-rc4 at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. No old checker/proof interfaces constrain this work.

## Critical architectural choices

1. **Real symbolic universe equality**, not `ULevel.groundEval` and not a finite valuation grid. Model `zero/succ/max/imax/param` with exact canonical normalization and provable equivalence tests. Use official [level.cpp](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/level.cpp), [level.h](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/level.h) and Lean's [Level.lean](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/Lean/Level.lean) as rule sources. Unknown parameters and universe metavariables fail closed.
2. **Precisely graded type checking:** `InferOnly` is an internal computation with explicit premises; only `FullyChecked` can underpin admitted declarations. A checked result carries the exact inferred type, scope/universe/environment identity and binder sort witnesses from actual recursive execution; untrusted constructors cannot fabricate it.
3. **Typed local context and environment:** names, universe argument arity, statement type, declaration kind/unsafe/partial/opaque policies and a unique validated environment generation. No arbitrary unchecked axioms in verified-consistency mode; ordinary Lean mode and modeled axiom mode are distinct.
4. **One semantic DefEq authority:** any affirmative structural cache/normalization/relevance step must be justified by the correct typed context and appropriate symbolic universe regime. Lazy values are implementation strategies, not externally trusted proofs.
5. **Small coherent kernel module graph** rather than one file per test. No old `Checker/Knot` dependency, new theorem assumptions or plugin-injected equality facts.

## Vertical implementation slices in dependency order

| Slice | Scope | Minimum acceptance |
| --- | --- | --- |
| G4.0 | Specify `Level.isEquivalent` / `isGEq` obligations and parameter policy with official positive+negative universe matrix | Exact symbolic and valuation-independent agreement, tested under multiple parameter assignments and normalization cases |
| G4.1 | Immutable checked declaration environment and typed errors | Duplicate names, missing constants, wrong universe arities, safety/opacity and resource errors decline/reject; no unchecked mutation |
| G4.2 | Fully checked `Sort` and `Pi` under named parameters and scoped bound variables | Valid/invalid formation and universe typing; exact `imax` with Prop codomain |
| G4.3 | Lambda, application, let and capture-avoiding substitution | Check argument type by DefEq, no infer-only-to-checked privilege crossing |
| G4.4 | WHNF, stable typed conversion, proof irrelevance and eta with right transparency | Positive-result refinement and official differential conformance on reduced focused families |
| G4.5 | Lit Nat/String, projection, quotients and recursor computation/admission | Exact 4.35 primitive and inductive conditions, size/budget guard |
| G4.6 | Environment transaction and model soundness | Actual positive acceptance -> modeled checked declaration under explicit axioms |

At each stage, one actual source rule maps to an official file/function, direct positive/negative tests, negative malformed inputs, resource behavior and a proof or explicit proof debt. Keep extra host/JSON adapters outside the logical kernel.

## Safety and benchmark gates

- **No theorem-admission API while only structural preflight exists.** A constant lookup and sort inference are not sufficient proof validation.
- If a symbolic level operation cannot decide, report unsupported/resource/unknown; **never accept equality via finite sample valuations**.
- Cached positive results carry immutable environment identity, local scope and level assignment. No external extension can make a new kernel reduction/axiom rule.
- Compare actual inference/DefEq under identical pinned Lean exports and resource policies; G2's beta-only ratio is NOT a compiler/kernel speed target.
- First small differential corpus and formal slice, then package-level Init/Std, eventually full Mathlib when implementation complete.
- Native Lean first; then independently qualify generated JS/Wasm from the chosen single maintained semantic source without preserving the old PSC1 syntax subset.

## G4.0 validated partial checker status

Positive-only symbolic normalizer and universal-assignment proof are implemented and validated at source `4c37b7f`: [G4 evidence](G4_LEVEL_EVIDENCE.md). It recognizes 98 positive pairs of 1296 versus the pinned official oracle with **8 more official-positive cases unresolved**. The conservative `unresolved` result must never be treated as negative conversion. Full official normal-form equivalence and `isGEq` remain unimplemented; G4.0 is **partially implemented, not complete**, and does not enable theorem admission.

## Immediate next implementation

Create `Core/LevelNorm` and an executable symbolic universe equivalence **research-only** interface, paired with an oracle matrix and a proof that affirmative equality respects all parameter assignments. Do not mark it as a trusted kernel equality operation before that proof. Then build a strict immutable constant environment with an explicit checked/untrusted distinction.

G3 [validated evidence](G3_EVIDENCE.md) and G2 [performance evidence](G2_EVALUATION_EVIDENCE.md) remain the exact documented baselines.
