# PSC1 minimal-kernel proof status

## R2 qualified normalized-profile checkpoint — continue with R3

R2 passes both standalone Linux jobs at
**`028dcd98fabcb0bf196c0d6f27a80bad3b666745`**, run
[40469648092](https://github.com/dwijayuda/pskernel/actions/runs/40469648092):
proof/native **122073398746**, portability/census/source witness **122073398515**.
The user-confirmed setting is GPT-6.1 Sol / High. All project builds, proof checks,
source compilation and tests in this batch ran on GitHub Actions Linux.

Read the [R2 profile and precise boundary](PSC1_MIN_KERNEL_R2_PROFILE.md) before
editing. The isolated executable checks closed Type-0 codes and ordered regular
datatype descriptors, derives constructor/fixed-result recursor signatures, and
checks sequential declarations from an empty environment. The generic concrete
tree model discharges the signature model; actual inference/admission success
gives a model and Empty consistency. The iota law covers the entire declared
descriptor family. Stable chronological quotation names are proved injective
and preserved when relative slots rebase.

All **24** new printed model/validation/name/source bridge reports contain
no axioms or exactly `[propext]`. The native and actual PSC1-generated corpus
passes **23 positives, 38 refusals and two out-of-range probes**. The complete
five-module source/test graph is admitted by official Lean 4.35. Its bundle is
105087 B TS / 221393 B JS; these include test/shared runtime code. The two-module
checker source has 307 lines/12268 B; naming adds Foundation.Name and
RegularNames (four-module checker-plus-naming closure 17081 B). The original
Check.lean remains 93 lines/3322 B with its original source SHA.

The concrete source-image theorem connects the checked normalized recursor to
the exact retained PsMinTy.rec spine, with its actual host PsMinTy/Bool model and
R1 motive-instantiation law. CI locates the native proof witness structurally
once in the current source-origin-bound psMinTyEq worker. This is a representative
typed source-image result, not a general decoder, external name resolver or proof
for all 115 canonical foundation declarations. Internal quotation names do not
authorize arbitrary canonical source-name binding.

Previous R1 main 40460549124 and installed 40459838431 are terminal success.
**R2 terminal regressions:** [main 40470311636](https://github.com/dwijayuda/pskernel/actions/runs/40470311636)
passes at reporting commit `48810244a9d6d449f71bc0d10dcbdbb45f4e2e63`,
full-job 122080382138 and gate-job 122087862294. Every selected dependency passes;
the benchmark is deliberately unselected. The tested merge and reporting head
have the same tree `44291047885b84101167ffa404d3bad059b2fb8a`.
[Installed 40468550390](https://github.com/dwijayuda/pskernel/actions/runs/40468550390)
passes preflight 122070225396 and installed 122070428136 at d0810a57. Only three
proof files and documentation changed afterward; runtime/test/driver bytes match
the qualified R2 runtime. The dated receipt preserves these separate exact scopes.
Verified 2026-10-27 08:32:58 UTC. Later documentation-only reports retain these source
identities; requery live HEAD and checks before starting the next proof batch.

**Next batch is R3:** measured lets, declaration projections and exact pinned
foundation instance semantics, keeping the real acceptance-to-model bridge.
Any delta conversion needs a definition-body/evaluation invariant. R4 still
owns general canonical ingress/name binding/translation and generated execution/
resource obligations. Canonical min/dual still refuse; full min coverage remains
0/124 compiler modules, 0/37 Practical Core and no qualified min G1/G2/G3.
Do not repeat R1/R2 or promote the representative witness to full self-check.


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
