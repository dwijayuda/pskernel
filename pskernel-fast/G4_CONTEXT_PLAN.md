# G4.3 planning gate — scoped contexts and real typed checking

**Status:** G4.3 structural binder context implemented and independently CI-validated in its narrow scope; capture-avoiding shifting has a newly committed source/proof/test **candidate pending CI qualification**. True dependent typed inference and checked environment are still unimplemented. Lean 4.35 pinned `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; no obligation to preserve old PSKernel proof/code interfaces.

## Validated bounded precursor

The independent `ScopedFrame params depth` prototype passed [G4.3 scoped-frame evidence](G4_SCOPED_EVIDENCE.md). It validates the exact domain's *structural* scope when pushing a binder and proves top lookup/depth progression. A raw domain read back from its original insertion context is NOT an inferred type; the next operation must explicitly shift under newer binders. No dependent typing or proof acceptance was added.

## Required design

The G4.2 source can only infer types for syntactically Sort-shaped closed terms. It does not handle a genuinely dependent term, so future additions need:

- A **validated local context** with stable binder identities or correct de Bruijn lifting, inferred domain types, exact opening/closing and scope exit.
- A **separate fully checked result grade** carrying the term, checked inferred type, environment epoch, universe parameter assumptions, and actual binder-sort observations; `InferOnly` is never silently upgraded.
- A strict **immutable checked environment** independent of the *untrusted* `CandidateCatalog`, and correctly checked constant arities, safety, reducibility hints and primitive rules.
- A **WHNF/DefEq engine** whose positive equality answers are provably sound and compatible with Lean's order-sensitive rules, including proof irrelevance, eta, reduction and symbolic universe equivalence. The current G4.0 `unresolved` result is not inequality.
- Explicit resource/error categories and atomic declaration admission; no partial publications on failure.

## Vertical implementation order

1. Formally specify and test local-context entries and lifting/substitution under binders; prove checked lookup/scoping correctness.
2. Infer/check `Sort`, free/bound variables and `Pi` under actual context, then lambda/application/let; use actual sort-exposure observations.
3. Integrate a strict WHNF and conversion interface; keep the current G2 evaluators research-only and compare their behavior against the evolving real semantic checker.
4. Introduce an environment admission API **only after** full syntax/typing/DefEq/inductive/quotient and safety policy is implemented. No old proof obligation may constrain a better new representation, but a new correctness argument is mandatory.
5. Compare official Lean 4.35 positive/negative exports and cost *inside actual checker operations*, not just a toy beta benchmark.

Until these are met, the most advanced executable success in V3 is a **two-rule formation fragment**, not a general-purpose Lean kernel.
