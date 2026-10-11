import PSKernelFast.Spec.PropPi

/-!
P1e: a NON-AUTHORITATIVE, explicitly PROP-VALUED semantic term tier.

This syntax cannot denote Type-valued Pi or executable lambdas. Every
Pi constructor here is a claimed proposition-valued binder, and callers
must separately supply actual checker-derived codomain-sort evidence
and valid semantic fibres before it can be used for checked typing
soundness. Mere erasure into this syntax does NOT certify source terms.

The interpreter is a genuine mathematical V-valued interpretation under
a caller-supplied SetTheoryBasis V (not a SetTheoryBasis instance
constructed by PSKernel-Fast). The only dependent function operator is
the already proven impredicative propPi. It is NOT full Lean semantics,
a hereditary WellDenoted proof, or a verified proof-admission API.
-/

namespace PSKernelFast.Spec

open PSKernelFast.Core

universe u

/--
Proof-only *candidate* proposition-valued semantic language:
- bvar: de Bruijn model-environment variable;
- sort: interpreted set universe;
- propPi: dependent proposition-valued product, never a Type-valued Pi.
A source-side checked Pi codomain-sort witness must justify this
constructor when relating real checked syntax to this model.
-/
inductive PropInterpTerm where
  | bvar (index : Nat)
  | sort (level : Nat)
  | propPi (domain body : PropInterpTerm)
  deriving Repr, Inhabited, BEq, DecidableEq

/-- De Bruijn environment extension, independent of kernel source storage. -/
def extendSetEnv {V : Type u} (value : V) (env : Nat → V) : Nat → V
  | 0 => value
  | n + 1 => env n

/--
Actual V-valued model interpretation of the small semantic syntax.
No symbolic binder hint, proof script, unchecked cache or runtime kernel
expression participates. Annotations are explicit in the syntax itself.
-/
noncomputable def interpProp (V : Type u) [SetTheoryBasis V] :
    (Nat → V) → PropInterpTerm → V
  | env, .bvar index => env index
  | _, .sort level => sortSet V level
  | env, .propPi domain body =>
      propPi V (interpProp V env domain)
        (fun x => interpProp V (extendSetEnv x env) body)

/--
Independent erasure from the proposition-specific semantic syntax to the
previous source-independent erased syntax. This FORGETS the Prop-regime
claim: nothing can recover a checked witness from this erasure.
-/
def PropInterpTerm.forget : PropInterpTerm → ErasedExpr
  | .bvar i => .bvar i
  | .sort u => .sort u
  | .propPi A B => .pi A.forget B.forget

/--
A HEREDITARY semantic-fibre obligation. The product's body is required
to denote a genuine proposition for every element of its domain.
This is a hypothesis about actual semantic values, NOT an assumption
that arbitrary source terms satisfy it.
-/
def PropPiFibresValid (V : Type u) [SetTheoryBasis V]
    (env : Nat → V) (domain body : PropInterpTerm) : Prop :=
  ∀ x : V, SetTheoryBasis.Mem x (interpProp V env domain) →
    SetTheoryBasis.Mem
      (interpProp V (extendSetEnv x env) body) (sortSet V 0)

/-- Sort denotes the exact model universe for every model environment. -/
theorem interpProp_sort (V : Type u) [SetTheoryBasis V]
    (env : Nat → V) (rank : Nat) :
    interpProp V env (.sort rank) = sortSet V rank := rfl

/-- Variables denote exactly the saved model-set environment value. -/
theorem interpProp_bvar (V : Type u) [SetTheoryBasis V]
    (env : Nat → V) (index : Nat) :
    interpProp V env (.bvar index) = env index := rfl

/-- The newest model variable denotes precisely the binder's domain member. -/
theorem interpProp_top_var (V : Type u) [SetTheoryBasis V]
    (env : Nat → V) (value : V) :
    interpProp V (extendSetEnv value env) (.bvar 0) = value := rfl

/--
A genuine mathematical *Π membership* statement for any annotated
proposition product, provided the (separately checkable) semantic
fibre-validity premise holds. This does NOT yet prove the premise for
arbitrary G4.3b typing derivations.
-/
theorem interpProp_pi_member (V : Type u) [SetTheoryBasis V]
    (env : Nat → V) (domain body : PropInterpTerm)
    (_valid : PropPiFibresValid V env domain body) :
    SetTheoryBasis.Mem
      (interpProp V env (.propPi domain body))
      (sortSet V 0) := by
  simpa only [interpProp] using
    (propPi_member_prop V (interpProp V env domain)
      (fun x => interpProp V (extendSetEnv x env) body))

/-- Specialized, genuinely interpreted model of the closed source
    proposition: for every proposition P, P. -/
def forallPropPropTerm : PropInterpTerm :=
  .propPi (.sort 0) (.bvar 0)

/--
The DOMAIN is the set of all proposition truth values, and the body is
the proposition x itself. Thus every genuine domain member has a
well-formed proposition-valued codomain fibre, *without assuming it*.
-/
theorem forallPropProp_fibres_valid (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    PropPiFibresValid V env (.sort 0) (.bvar 0) := by
  intro x hx
  simpa [PropPiFibresValid, interpProp, extendSetEnv] using hx

/-- The dependent formula forall(P:Prop),P is a proposition in the model. -/
theorem forallPropProp_member_prop (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    SetTheoryBasis.Mem (interpProp V env forallPropPropTerm)
      (sortSet V 0) :=
  interpProp_pi_member V env (.sort 0) (.bvar 0)
    (forallPropProp_fibres_valid V env)

/--
Its denotation is FALSE: choose the false proposition itself as the
counterexample to the universal quantification. This uses the actual
set-model truth-value constructions, not a fabricated domain witness.
-/
theorem forallPropProp_is_false (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    interpProp V env forallPropPropTerm = propFalse V := by
  have hNotTrue : propFalse V ≠ propTrue V := propFalse_ne_true V
  have hMember : SetTheoryBasis.Mem (propFalse V) (sortSet V 0) := by
    simpa [sortSet, propFalse] using (propFalse_mem V)
  simpa [forallPropPropTerm, interpProp, extendSetEnv] using
    (propPi_false_of_counterexample V
      (sortSet V 0) (fun x => x) (propFalse V) hMember hNotTrue)


/--
Another closed proposition fragment: forall (P : Prop), P -> P.
The first binder is a proposition, the second binder is a proof of P
at the source level; at this PROP-SET interpretation tier the body
denotes the model value P. This statement DOES NOT interpret a proof term.
-/
def forallPropIdentityTerm : PropInterpTerm :=
  .propPi (.sort 0) (.propPi (.bvar 0) (.bvar 1))

/--
In the two-valued carrier, the truth-value implication P -> P is true
for either P. A false proposition has no elements, while a true one
gives the same true fibre at every domain member.
-/
theorem prop_imp_self_true (V : Type u) [SetTheoryBasis V]
    (P : V) (hP : SetTheoryBasis.Mem P (sortSet V 0)) :
    propPi V P (fun _ => P) = propTrue V := by
  apply (propPi_true_iff V P (fun _ => P)).2
  intro x hx
  have hInCarrier : SetTheoryBasis.Mem P (propTruthUniverse V) := by
    simpa only [sortSet] using hP
  rcases (propUniverse_exactly_two V P).mp hInCarrier with hFalse | hTrue
  · have hMemberEmpty : SetTheoryBasis.Mem x
        (SetTheoryBasis.emptySet V) := by
      simpa only [hFalse] using hx
    exact False.elim (SetTheoryBasis.not_member_empty V x hMemberEmpty)
  · exact hTrue

/--
For every model proposition P, the nested implication product has a
well-formed Prop-valued semantic fibre. This is derived from the actual
two-valued candidate set-model definition, not assumed on the source.
-/
theorem forallPropIdentity_fibres_valid (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    PropPiFibresValid V env (.sort 0)
      (.propPi (.bvar 0) (.bvar 1)) := by
  intro P hP
  apply interpProp_pi_member V
    (extendSetEnv P env) (.bvar 0) (.bvar 1)
  intro x hx
  simpa [interpProp, extendSetEnv] using hP

/-- The nested dependent identity-implication proposition is modelled Prop. -/
theorem forallPropIdentity_member_prop (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    SetTheoryBasis.Mem (interpProp V env forallPropIdentityTerm)
      (sortSet V 0) :=
  interpProp_pi_member V env (.sort 0)
    (.propPi (.bvar 0) (.bvar 1))
    (forallPropIdentity_fibres_valid V env)

/--
The second fully interpreted proposition is TRUE, as the semantic
implication P -> P is true for both false and true model propositions.
-/
theorem forallPropIdentity_is_true (V : Type u)
    [SetTheoryBasis V] (env : Nat → V) :
    interpProp V env forallPropIdentityTerm = propTrue V := by
  change propPi V (sortSet V 0)
      (fun P => propPi V P (fun _ => P)) = propTrue V
  apply (propPi_true_iff V (sortSet V 0)
    (fun P => propPi V P (fun _ => P))).2
  intro P hP
  exact prop_imp_self_true V P hP

#print axioms interpProp_pi_member
#print axioms forallPropProp_fibres_valid
#print axioms forallPropProp_member_prop
#print axioms forallPropProp_is_false
#print axioms prop_imp_self_true
#print axioms forallPropIdentity_fibres_valid
#print axioms forallPropIdentity_member_prop
#print axioms forallPropIdentity_is_true

end PSKernelFast.Spec
