import PSKernelFast.Spec.PropInterp
import PSKernelFast.Proof.PiModelRegime
import PSKernelFast.Proof.ErasureTotality

/-!
P1e first concrete source-to-conditional-set-denotation bridge.

Every conjunct of the concrete result is checked against:
1. the ACTUAL source inferClosedGeneralPi function (G4.3b);
2. its separately checked GeneralPiRule certificate;
3. the independent ground-universe eraseExpr implementation;
4. a proposition-only annotated semantic term, interpreted under a
   caller-supplied SetTheoryBasis V.

The particular checked formula is (forall P : Prop, P). The proof shows
its source result is a Prop type, its erasure matches the model term,
and its interpretation is FALSE and belongs to the modeled Prop carrier.
It does NOT assert that all checked Pi types, proofs or lambda/app/let
terms have set-theoretic interpretations, nor admit a declaration.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec

universe u

/-- Actual symbolic G4.3b source form: forall (P : Prop), P. -/
def forallPropPropSource (name : KName) : KExpr :=
  .forallE name (.sort .zero) (.bvar 0) .default

/-- Its exact SOURCE typing result, retaining symbolic imax syntax. -/
def forallPropPropSourceType : KExpr :=
  .sort (.imax (.succ .zero) .zero)

/--
The actual running six-rule inference algorithm accepts this source with
the precise result type. No trusted frontend annotation, imported axiom
or alternative checker is used.
-/
theorem forallPropProp_actual_inference (name : KName) :
    inferClosedGeneralPi [] (forallPropPropSource name) =
      .ok forallPropPropSourceType := by
  rfl

/--
Every valuation maps the real source Pi into the independent erased
term underlying the proposition-specific model AST.
-/
theorem forallPropProp_actual_erasure
    (ρ : KName → Nat) (name : KName) :
    eraseExpr ρ (forallPropPropSource name) =
      some forallPropPropTerm.forget := by
  rfl

/--
The checker does not syntactically normalize imax(1,0) to zero.
Its actual inferred type nevertheless erases under ALL level valuations
to the correct proposition sort.
-/
theorem forallPropProp_type_erases_to_Prop
    (ρ : KName → Nat) :
    eraseExpr ρ forallPropPropSourceType = some (.sort 0) := by
  rfl

/--
Actual CHECKED Pi typing carries a codomain-Sort(0) certificate. The
model can use it rather than trusting a user-supplied annotation.
-/
theorem forallPropProp_checked_body_prop (name : KName) :
    GeneralPiRule [] [.sort .zero] (.bvar 0) (.sort .zero) := by
  have hChecked :
      GeneralPiRule [] [] (forallPropPropSource name)
        forallPropPropSourceType :=
    (inferClosedGeneralPi_sound [] (forallPropPropSource name)
      forallPropPropSourceType
      (forallPropProp_actual_inference name)).2
  cases hChecked with
  | pi _ _ _ _ _ u v hDom hBody =>
      exact hBody

/--
End-to-end, FIRST REAL SOURCE-TO-SET CASE:
- the runtime accepted the exact source with its actual symbolic type;
- the source and inferred type independently erase to the asserted
  proposition-fragment semantics for ANY universe valuation;
- the interpretation of that verified source is an actual member of
  the denotation of its actual inferred type;
- its set-theoretic truth-value interpretation is FALSE.

All set-membership facts are CONDITIONAL on SetTheoryBasis V, which is
neither globally assumed as a new axiom nor constructed by this project.
This is NOT proof of full checker denotational soundness or consistency.
-/
theorem forallPropProp_checked_set_denotation
    (V : Type u) [SetTheoryBasis V]
    (name : KName) (ρ : KName → Nat) (env : Nat → V) :
    inferClosedGeneralPi [] (forallPropPropSource name) =
      .ok forallPropPropSourceType ∧
    eraseExpr ρ (forallPropPropSource name) =
      some forallPropPropTerm.forget ∧
    eraseExpr ρ forallPropPropSourceType = some (.sort 0) ∧
    SetTheoryBasis.Mem
      (interpProp V env forallPropPropTerm)
      (interpProp V env (.sort 0)) ∧
    interpProp V env forallPropPropTerm = propFalse V := by
  refine ⟨forallPropProp_actual_inference name,
    forallPropProp_actual_erasure ρ name,
    forallPropProp_type_erases_to_Prop ρ, ?_, ?_⟩
  · simpa [interpProp] using (forallPropProp_member_prop V env)
  · exact forallPropProp_is_false V env


/-- Second actual G4.3b source: forall (P : Prop), P -> P. -/
def forallPropIdentitySource (propName proofName : KName) : KExpr :=
  .forallE propName (.sort .zero)
    (.forallE proofName (.bvar 0) (.bvar 1) .default) .default

/-- Keep both nested imax nodes unnormalized in the source checker. -/
def forallPropIdentitySourceType : KExpr :=
  .sort (.imax (.succ .zero) (.imax .zero .zero))

/-- The ACTUAL executing G4.3b inference accepts the nested Pi formula. -/
theorem forallPropIdentity_actual_inference
    (propName proofName : KName) :
    inferClosedGeneralPi []
      (forallPropIdentitySource propName proofName) =
      .ok forallPropIdentitySourceType := by
  rfl

/--
Actual source erases into exactly the same nested proposition-valued Pi
syntax that the independent set interpretation evaluates. Erasure drops
both binder names but preserves all de Bruijn dependencies.
-/
theorem forallPropIdentity_actual_erasure (ρ : KName → Nat)
    (propName proofName : KName) :
    eraseExpr ρ (forallPropIdentitySource propName proofName) =
      some forallPropIdentityTerm.forget := by
  rfl

/--
Nested symbolic imax(1, imax(0,0)) has valuation zero, but the
executing checker makes no unproved full DefEq/normalization claim.
-/
theorem forallPropIdentity_type_erases_to_Prop (ρ : KName → Nat) :
    eraseExpr ρ forallPropIdentitySourceType = some (.sort 0) := by
  rfl

/--
A second genuine executable-checker-to-set-model theorem. The actual
checker types the nested dependent Pi proposition and its output type
erases to Prop. Its interpretation is true (whereas the previous
forall(P:Prop),P source has a false interpretation). There is still
NO typed proof-term interpretation or general kernel model theorem.
-/
theorem forallPropIdentity_checked_set_denotation
    (V : Type u) [SetTheoryBasis V]
    (propName proofName : KName)
    (ρ : KName → Nat) (env : Nat → V) :
    inferClosedGeneralPi []
      (forallPropIdentitySource propName proofName) =
      .ok forallPropIdentitySourceType ∧
    eraseExpr ρ (forallPropIdentitySource propName proofName) =
      some forallPropIdentityTerm.forget ∧
    eraseExpr ρ forallPropIdentitySourceType = some (.sort 0) ∧
    SetTheoryBasis.Mem
      (interpProp V env forallPropIdentityTerm)
      (interpProp V env (.sort 0)) ∧
    interpProp V env forallPropIdentityTerm = propTrue V := by
  refine ⟨forallPropIdentity_actual_inference propName proofName,
    forallPropIdentity_actual_erasure ρ propName proofName,
    forallPropIdentity_type_erases_to_Prop ρ, ?_, ?_⟩
  · simpa [interpProp] using (forallPropIdentity_member_prop V env)
  · exact forallPropIdentity_is_true V env

#print axioms forallPropProp_actual_inference
#print axioms forallPropProp_actual_erasure
#print axioms forallPropProp_type_erases_to_Prop
#print axioms forallPropProp_checked_body_prop
#print axioms forallPropProp_checked_set_denotation
#print axioms forallPropIdentity_actual_inference
#print axioms forallPropIdentity_actual_erasure
#print axioms forallPropIdentity_type_erases_to_Prop
#print axioms forallPropIdentity_checked_set_denotation

end PSKernelFast.Proof
