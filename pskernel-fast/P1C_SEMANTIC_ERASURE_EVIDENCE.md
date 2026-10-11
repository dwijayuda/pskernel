# PSKernel-Fast P1c — Independent semantic-syntax and typed beta/let bridge

**Status:** independently verified *pre-denotational* translation and selected typed subject-reduction rules, **NOT** a set-theoretic model, checker semantic-soundness proof, relative consistency theorem or complete Lean kernel.

## Exact source and completed CI

- **Qualified GitHub code/audit commit:** [`5b137281e8a0cc8306b335c0a40464248b4131d7`](https://github.com/dwijayuda/pskernel/commit/5b137281e8a0cc8306b335c0a40464248b4131d7).
- **Completed GitHub Actions:** [run 38121976529](https://github.com/dwijayuda/pskernel/actions/runs/38121976529), job `114418422585`, **SUCCESS**.
- **Compiler:** pinned Lean `4.35.0-rc4`, official commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- **Verified gate:** **68** completed Lake build jobs; import/placeholder audit of **29** independent Lean source modules; all earlier G1–G4.3b smoke and P1b proof tests, the added P1c nonempty-context beta/let regression, and exactly **24 theorem-assumption receipts** passed.
- **Assumptions:** the new P1c theorems report `propext` and `Quot.sound` (the full reviewed allowlist also permits `Classical.choice`). No `sorryAx`, `native_decide` or new project-specific soundness axiom was admitted by this **bounded theorem gate**.

## What is actually proved

### A. Typed dependent beta and let for an arbitrary *existing* binder index

[`Proof/TypedSubstitution.lean`](src/PSKernelFast/Proof/TypedSubstitution.lean) adds:

- `dependent_outer_variable_beta_preserves_type`
- `dependent_outer_variable_let_preserves_type`

Under an actually checked G4.3b context and a newly inserted binder, both terms can read an arbitrary *older* binder. The theorems establish that the original application or supported `nondep=false` let and its beta/zeta-contracted older variable retain the **same exact `GeneralPiRule` type**. The actual `liftBVars` and `instantiateBVar` code is used, with previously proved lift-composition and typed-variable-weakening lemmas. This extends P1b beyond the newest-variable identity cases but **does not prove generic subject reduction for arbitrary application/lambda/let bodies or set-theoretic typing**.

[`GeneralPiFormationSmoke.lean`](src/PSKernelFast/GeneralPiFormationSmoke.lean) adds a checked, nonempty dependent-context fixture that independently runs the fragment algorithm on both redexes and their contracted variable, validating exact type preservation at the tested binder depth. The mathematical proofs cover arbitrary old variable indices.

### B. Independent erased term language and substitution bridge

[`Spec/ErasedExpr.lean`](src/PSKernelFast/Spec/ErasedExpr.lean) imports the **logical syntax and symbolic level denotation**, not the G4.3b checker. It defines `ErasedExpr` with de Bruijn indices, **ground Nat universe levels** under explicit valuation `ρ : KName → Nat`, application, lambda, Pi and restricted let. Binder names/styles are erased. Unsupported free/meta variables, constants, literals, metadata/projections and `nondep=true` lets return **`none`** rather than fabricated meanings. The language defines independent `ErasedExpr.lift` and `ErasedExpr.instantiate` operations.

[`Proof/Erasure.lean`](src/PSKernelFast/Proof/Erasure.lean) separately imports the executing substitution and proves:

- `eraseExpr_lift`: erasure commutes with the **actual** binder lift at any depth.
- `eraseExpr_instantiate`: given supported erased replacement, erasure commutes with the **actual** binder instantiation at any depth.
- `eraseExpr_beta_redex`: the concrete lambda/app redex and its actual contraction translate exactly to the independent erased redex/contraction.
- `eraseExpr_let_redex`: the analogous precise correspondence for qualified `nondep=false` lets.

These bridge the syntactic checker implementation with an independent representation. They **do not** prove denotational equality of the redex and contraction in any set model.

### C. Totality of erasure for every G4.3b accepted type judgment

[`Proof/ErasureTotality.lean`](src/PSKernelFast/Proof/ErasureTotality.lean) defines an `Erasable` predicate and a checked-context `ContextErasable` predicate. It proves:

- `generalPiRule_erasable`: **all six G4.3b rule constructors** preserve the existence of erasure for both source expression and resulting type, assuming previously validated erasable context entries. The application and let cases consume the actual source-to-erasure substitution bridge, not an unverified synthesized result.
- `generalPiContextWF_erasable`: the existing true checked-binder context formation gives the required erasable-context invariant.
- `inferClosedGeneralPi_erasable`: **every actual successful closed G4.3b inference** admits independent erased syntax for its source and inferred type, for any ground universe valuation.

This is a sound, useful **translation totality** statement. It is not an assertion that the translated term inhabits its translated type.

## Where the model proof becomes genuinely difficult

**Critical missing tier:** the current `ErasedExpr` is only *syntax*, not `SetTheory V`, `Denotes`, or an interpreted type. In particular, Lean's impredicative/proof-irrelevant `Prop` needs **validated binder codomain sort/proposition regime information** (analogous to con-leche's `PropWhen` annotation) if the eventual model interprets dependent Pi/λ syntax-directionally. Erasure intentionally does not invent such annotations. Their source must be actual qualified type checking, and each annotation needs a semantic-correctness proof across **all** level valuations and binder environments.

Other model debts: universe hierarchy existence and cumulative typing; dependent function spaces, interpreting exact application, proof irrelevance, equality, eta and later quotient/inductive/primitive semantics; a `WellDenoted` hereditary semantic invariant and beta/let preservation proof; checked declaration/model extension and a conditional `False` exclusion theorem. The current arbitrary universe valuation `ρ` is NOT a set-theory model.

## Cheapest next soundness route

**Decision:** choose a hybrid. For the existing tiny six-rule fragment, retain cheap syntactic weakening/substitution lemmas as **local tests and proof ingredients**. For full Lean-style model/consistency, adopt a *con-leche-inspired direct denotational checker-to-model proof*, with an independently audited `WellDenoted` invariant and binder annotation certification, instead of requiring the full intensional normalization/inversion/syntactic subject-reduction metatheory first. Con-ron's representation-refinement approach remains optional until *real checker workloads* justify a separate Rust/DAG backend.

**Do not import con-leche's accepted-checker theorem as a theorem of this kernel.** The next P1d experiment is to define the minimal universe/set `Model V` interface and the distinct **annotation/denotation** term layer (not a second production checker), then prove actual `Sort` and one dependent `Pi` rule's **semantic membership** with explicit model assumptions. If the proof cost or runtime annotation tax is unacceptable, change the model-interface design before committing to the entire kernel. Preserve the previous fixed G4.3b semantic implementation while studying this; no proof authority for any external extension.

**No proof admission; no G4.4 WHNF/DefEq completion; no new actual-kernel performance measurement; no conditional consistency proof exists at this checkpoint.**
