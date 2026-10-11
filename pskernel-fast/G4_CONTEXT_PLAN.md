# G4.3 planning gate — scoped contexts and real typed checking

**Status:** independent G4.3 binder operations are structurally proved ([run 38115032789](https://github.com/dwijayuda/pskernel/actions/runs/38115032789)); a new **restricted dependent Sort/Pi fragment** with verified Sort-only contexts and an exact independent formation judgment passed [run 38115500178](https://github.com/dwijayuda/pskernel/actions/runs/38115500178). **General** dependent typing, type preservation, a protected checked environment, typed DefEq and proof admission remain unimplemented. Lean 4.35 pinned `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; old proof/API interfaces are not requirements.

## Validated bounded precursor

The independent `ScopedFrame params depth` prototype passed [G4.3 scoped-frame evidence](G4_SCOPED_EVIDENCE.md). It validates the exact domain's *structural* scope when pushing a binder and proves top lookup/depth progression. A raw domain read back from its original insertion context is NOT an inferred type. The [new G4.3 binder evidence](G4_BINDER_EVIDENCE.md) now validates precise lifting and executable fail-closed scope-preserving substitution. Even a lifted, scope-certified domain is NOT guaranteed to be a type; only a future genuine typed-context checking relation can grant that authority.

## Required design

The G4.2 source can only infer types for syntactically Sort-shaped closed terms. It does not handle a genuinely dependent term, so future additions need:

- A **validated local context** with stable binder identities or correct de Bruijn lifting, inferred domain types, exact opening/closing and scope exit.
- A **separate fully checked result grade** carrying the term, checked inferred type, environment epoch, universe parameter assumptions, and actual binder-sort observations; `InferOnly` is never silently upgraded.
- A strict **immutable checked environment** independent of the *untrusted* `CandidateCatalog`, and correctly checked constant arities, safety, reducibility hints and primitive rules.
- A **WHNF/DefEq engine** whose positive equality answers are provably sound and compatible with Lean's order-sensitive rules, including proof irrelevance, eta, reduction and symbolic universe equivalence. The current G4.0 `unresolved` result is not inequality.
- Explicit resource/error categories and atomic declaration admission; no partial publications on failure.

## Vertical implementation order

1. **G4.3 structural foundation GREEN:** exact original-scope and lifted current-scope lookup, total capture-avoiding reference substitution, machine-checked structural preservation and strict malformed-input handling. [Evidence](G4_BINDER_EVIDENCE.md). Do not upgrade it to a typing result.
2. **Partially GREEN:** `DependentSortFragment.lean` certifies `Sort`, bound variables and truly dependent `Pi` when every binder domain is syntactically `Sort u`. This is NOT general checked inference; see [exact CI](G4_DEPENDENT_SORT_EVIDENCE.md). **Next:** build an immutable, protected typed context for arbitrary checked domain expressions with actual sort observations and a full `Γ ⊢ e : A` judgment, keeping `InferOnly` and `FullyChecked` separate. Add lambda/application/let only with correct result-type substitution.
3. Implement actual WHNF and **typed** DefEq with positive-soundness evidence and exact symbolic universes; use G2 evaluators as non-authoritative research references only.
4. Create a protected immutable checked environment distinct from the untrusted candidate catalog. Only introduce atomic declaration admission after the full Lean kernel rule families, resource policies and required proofs/tests are qualified.
5. Run pinned Lean 4.35 independent positive/negative differential tests from the first typed-rule slices, then realistic checker performance/memory benchmarks; defer full Init/Std/Mathlib until correct coverage justifies them.

Until these are met, the most advanced executable success is a **restricted Sort/bound-variable/dependent-Pi fragment over Sort-only contexts**, not a general-purpose Lean kernel.
