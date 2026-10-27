# PSC1 minimal-kernel proof status

The qualifying object is the safe Lean source checker in
`packages/pskernel-min/src/Ps/MinKernel/Check.lean`, with proofs in the separate
`proofs/pskernel-min/MainTheorem.lean` project. The current fragment is
Empty/Unit/Nat/simple arrows, scoped variables, checked positional constants,
literals, lambdas, applications and sequential closed definitions.

## Theorems and exact boundary

`Ps.MinKernel.Proofs.tyEq_sound` proves successful executable type equality implies
syntactic type equality. `inferModel` constructs a denotation directly from an
actual `psMinInfer` success equation. `checkDeclarationsModel` constructs the model of
the successful sequential fold from an initial model. `environmentModel` starts
that construction from the empty environment.

```lean
minKernel_hasModel
  (h : psMinCheckEnvironment termFuel declarationFuel declarations = some types) :
  Nonempty (Model types)

minKernel_consistent
  (h : psMinCheckEnvironment termFuel declarationFuel declarations = some types)
  (expression : PsMinExpr) :
  psMinInfer queryFuel types [] expression ≠ some PsMinTy.empty
```

The statements quantify over all input declarations, fuel choices, returned type
environments and closed query expressions. The caller cannot supply arbitrary
axioms in this calculus. The theorem does not assume that an unchecked foundation
already has a model. An Empty-to-Empty function is allowed; a closed Empty
inhabitant cannot pass. The contradiction type is this calculus's `PsMinTy.empty`,
interpreted as Lean `Empty`, not a name-based test against arbitrary Lean.False.

The model interprets types using Lean `Empty`, `Unit`, `Nat` and function types.
It requires no extra set-theory axioms or inaccessible-cardinal hypothesis.
It is relative to the ambient Lean logic and the theorem dependencies printed by
the pinned Lean 4.35 kernel. No metatheorem proves Lean's own absolute consistency.

## CI qualification

The exact qualifying commit, terminal run, theorem axiom output and measurements
are recorded in [work state](PSC1_MIN_KERNEL_WORK_STATE.md). Failed development
attempts remain in Git/Actions and do not qualify the final theorem. CI builds the
exact runtime source in place, then builds the proof; any Lean error fails the
job. It rejects `sorryAx` and only allows the reported standard `propext` dependency
(or no axioms) for the two capstone theorems. There are no added axiom declarations,
unsafe operations or proof modules in the executable import graph.

## Still unproved or unqualified

- Dependent PSC1 Core: universes, dependent Pi/conversion, inductive/recursor
  admission and computation, projections, polymorphic imported declarations.
- Interpretation of the actual PSC1 primitive foundation and its allowed axioms,
  including exact primitive identities and ordinary executable/logical pairing.
- A canonical PSC1 admission decoder/translation with proved preservation of
  declaration identities, types, bodies, scope and acceptance.
- Compiler semantic preservation from the Lean source function to PSC1-generated
  TypeScript/JS or Wasm. Source compilation, strict IR, official source admission
  and native/generated vectors are empirical evidence only.
- Complete compiler-closure checking by the generated minimal executable,
  G1/G2/G3 exact fixed points and hostile-input aggregate resource qualification.

Accordingly, the full PSC1 compiler and its Practical Core are **not** claimed
consistency-proven by this fragment. Canonical min/dual mode refuses rather than
grant admission using an unproved bridge. Official Lean checking remains intact.
