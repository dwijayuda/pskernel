# PSC1 minimal-kernel proof status

## R3 operational profile qualified — continue with R4

The normalized R3 operational profile passes standalone Linux
[40486405765](https://github.com/dwijayuda/pskernel/actions/runs/40486405765) at
**`695c68701437899b17a39205300cf26988322b15`**:
proof/native **122129166896**, source/portability/census **122129166670**.
The user-confirmed continuation setting is GPT-6.1 Sol / High. All project builds,
proof checks, source compilation and tests ran on GitHub Actions Linux.

Read the [R3 profile and exact boundary](PSC1_MIN_KERNEL_R3_PROFILE.md) and
[dated R3 receipt](PSC1_MIN_KERNEL_R3_QUALIFICATION_2026-10-27.json).
The separate operational layer adds annotated lets, descriptor-derived
single-constructor projections, and closed Nat/List/Option/Bool-decision schemas.
Every actual inference/admission success has a concrete model and Empty
consistency proof. R2 source/proofs remain intact.

The actual typed projection-model iota equation is proved for arbitrary supported
fields. The sequential fold carries DefinitionHistory for actual checked bodies;
checked_definition_unfold relates real constant interpretation to that body.
Conversion is structural code equality with a model-soundness theorem. There is
no general beta/delta type-conversion engine or dependent-alias acceptance.

All **26** new printed reports are no axioms or exactly `[propext]`.
The actual native/generated corpus passes **36 positives, 40 refusals and two
out-of-range probes**. Fifteen initial contracts were expanded to **29** exact
selected foundation declarations, including required types and constructors.
The actual source-owned ite/Decidable.rec AST equations and constructive
conditional model are checked. Canonical primitive contract comparisons are CI
evidence, never fixture/hash admission rules.

The checker closure is four source modules, 518 lines/22339 B; the two added
modules are 211 lines/10071 B. The five-module source/test graph is independently
admitted by official Lean 4.35. Its bundle is 134690 B TS/318436 B JS, including the
test/shared runtime, not an isolated checker payload or performance measurement.

Historical broader-regression snapshot at 2026-10-27 10:14 UTC: main 40486414934
and installed 40483267987 were still in progress. A reporting push may supersede
main; requery live PR checks. The source/standalone theorem qualification above
is complete; terminal broader outcomes are recorded separately.

**Next is R4:** bounded exact byte decoding, exact source-name/slot binding and
profile translation, then the actual generated checker acceptance-to-model path.
Check matching Eq Bool operands and Bool.decEq operands before constructing
boolEqIte; no arbitrary proof/decision term may be erased. Recompute the complete
connected R1/R2/R3/naming/ingress closure and required String/Char semantics.
The old Check-only 12 records and R2's 37-record view are not this enlarged checker.

R3 does not prove a general raw-Core translator/byte decoder or full foundation
closure. Generated-code preservation and hostile-input aggregate/heap/stack
bounds remain open. Canonical min/dual still refuse; full min coverage remains
0/124 modules, 0/37 Practical Core and no qualified min G1/G2/G3. Preserve official
Lean Wasm as default. Do not repeat R1/R2/R3 or promote official generations.

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

## Actual Core scope theorem, qualified separately

At579642626daa67bd167dd1af626f5b0e0401cb00, Linux40455022116/proof-job122026221969
also checks `proofs/pskernel-min/CoreScope.lean`. Its three printed dependency
reports are exactly `[propext]`:

- `Ps.MinKernel.CoreScope.instantiate_lift`: instantiating a freshly inserted
  binder in the actual lifted expression returns the original expression.
- `constant_motive_body`: the actual instantiation step on a lifted result is
  independent of the supplied major, including open outer references.
- `constant_motive_argument_irrelevant`: two such instantiations agree.

The proof imports the existing `Ps.Core.Subst` implementation and covers every
`PsExpr` constructor. It is a syntactic inverse law, not a typing, conversion,
recursor, raw-input or compiler-preservation theorem. Successful recognition of
an arbitrary constant-motive body as a lifted result is still unproved. This
adds no runtime imports, acceptance rule or new permitted foundation.
See the [current measured profile](PSC1_MIN_KERNEL_RUNTIME_PROFILE.md) for exact
statements, scope pitfalls and the next executable-recognizer proof gate.

## R1 executable recognizer inverse, qualified

Linux40459838298 at8b33b3a17b241d3b264600dd9616cc195933df65 qualifies the
actual Profile/LowerUnusedBinder.lean worker and BinderLowering.lean proof:
`lower_sound` proves successful lowering has the exact Core lifting inverse;
`lower_instantiate` derives actual Core instantiation at any depth;
`lower_motive_body` specializes depth0. All3 print exactly[propext]. No new
axiom declaration, sorryAx, unsafe admission or runtime proof import is added.
The34-case native/generated corpus plus2 out-of-range probes and independent
exact-source admission pass. The theorem covers syntax, not typing, recursor
semantics, the actual foundation, arbitrary JSON/JS objects or compiler preservation.
The old source fragment's consistency theorem and min/dual refusal are unchanged.
