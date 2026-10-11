# PSKernel-Fast G4 — Symbolic universes and checked-inference plan

**Status:** Partial G4 implementation. G4.0 is proven positive-only symbolic universe equality with known completeness gaps; G4.1 is an UNTRUSTED catalog; G4.2 is restricted Sort/Pi; G4.3 structurally proves binders/substitution, and **G4.3b** additionally validates a bounded general-domain Pi/lambda/exact-application/restricted-let fragment, including source/result scope certificates. Latest [G4.3b evidence](G4_GENERAL_PI_EVIDENCE.md), [green run 38116916150](https://github.com/dwijayuda/pskernel/actions/runs/38116916150). **G4.4 typed WHNF/DefEq, complete universe equivalence, general production checked inference, verified substitution typing, a protected checked declaration environment and admission are NOT completed.** Lean 4.35.0-rc4 remains pinned to `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; legacy proof-preservation does not constrain the kernel.

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

## G4.2 validated limited formation status

The [G4.2 certified fragment](G4_SORT_EVIDENCE.md) supports only closed `Sort` and syntactic nondependent `Pi` over `Sort` declarations and proves successful execution entails independent structural + fragment formation judgments. All other well-formed terms are **unsupported**, not checked. The G4.3 local-context/DefEq roadmap is documented at [G4_CONTEXT_PLAN.md](G4_CONTEXT_PLAN.md); never claim full checker or admission readiness.

## G4.1 validated input-indexing status

An independent persistent, **untrusted candidate catalog** passed [G4.1 CI](G4_CATALOG_EVIDENCE.md). It validates duplicate names/level parameters, known constant names/arity, reference safety and transactional snapshot behavior. It does **not** perform type checking or prove a declaration, and is not an admitted checker environment. Any future G4.2+ checked environment must be distinct.

## G4.0 validated partial checker status

Positive-only symbolic normalizer and universal-assignment proof are implemented and validated at source `4c37b7f`: [G4 evidence](G4_LEVEL_EVIDENCE.md). It recognizes 98 positive pairs of 1296 versus the pinned official oracle with **8 more official-positive cases unresolved**. The conservative `unresolved` result must never be treated as negative conversion. Full official normal-form equivalence and `isGEq` remain unimplemented; G4.0 is **partially implemented, not complete**, and does not enable theorem admission.

## P0/P1 invariant foundation — validated but NOT model consistency

The new [soundness contract](PSKERNEL_FAST_SOUNDNESS_CONTRACT_V1.md) and [source-matched P1 proof checkpoint](P1_SOUNDNESS_EVIDENCE.md) establish **independent structural** context/source/type validity of all six G4.3b rule constructors and exact reflection of the real G3 scope checker. Proofs show the extra inferred-result structural validation cannot reject a successfully inferred type. [Cloud run 38118786036](https://github.com/dwijayuda/pskernel/actions/runs/38118786036) passed 60 build jobs and a fail-closed 7-theorem axiom whitelist gate. These are prerequisites, NOT independently justified denotational typing, model consistency or a complete acceptance theorem.

The next theorem must cover **typing-preserving application/let substitution**, not another restatement of `GeneralPiRule`. The following set-theoretic interpretation and `checkDecls` model-extension theorem remain major open tasks; do not report con-leche's theorem as a theorem of this independent checker.

## Immediate next implementation

1. **G4.3b bounded source GREEN, NOT a general checker:** [exact evidence](G4_GENERAL_PI_EVIDENCE.md). `GeneralPiRule` has six guarded constructors, `GeneralPiContextWF` admits only previously checked Sort-domain binders, and `inferClosedGeneralPiCertified` performs source+output scope checks. Untrusted catalog headers never mint witnesses.
2. **G4.4 next:** define one canonical typed `ConversionDecision = equal | unresolved | malformed/resource` contract whose positive outcomes are *proved* and version-correct. Complete symbolic `isEquiv/isGEq`, safe WHNF and guarded context/environment/cache identity. Do not interpret syntactic inequality as negative DefEq.
3. Prove the typing substitution/context correctness of the actual application/let implementation (G4.3's current theorem covers **structural** substitution only). Only after source-specific typed refinement may conversion-backed shortcuts become acceptance-capable.
4. Introduce sealed `InferOnly` versus `FullyChecked` and immutable checked declaration environments under exact axiom/opacity/primitive policies. Run independent official Lean positive and negative typed differential fixtures and real kernel-only benchmarks before implementing admission.

G3 [validated evidence](G3_EVIDENCE.md) and G2 [performance evidence](G2_EVALUATION_EVIDENCE.md) remain the exact documented baselines.
