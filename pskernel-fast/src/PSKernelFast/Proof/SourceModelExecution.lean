import PSKernelFast.Proof.SourceModelTyping

/-!
P1o execution qualification, not a replacement for the general typing proof.

Instantiate the new source-only relation with actual lambda/app/let terms,
use its general soundness theorem rather than separately assuming model
membership, and prove the running inference/conversion equations by rfl.
The matching source beta theorem derives its semantic premises from those
certificates. This does NOT prove certificate synthesis or reduction
coherence for every G4.3b/G4.4b success, nor a full consistency capstone.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec
universe u

private def fixtureName : KName := .str .anonymous "x"
private def sortZero : KExpr := .sort .zero
private def sortOne : KExpr := .sort (.succ .zero)
private def sortTwo : KExpr := .sort (.succ (.succ .zero))

/-- Actual source terms from the supported runtime fragment. -/
def sourceBetaFixture : KExpr :=
  .app (.lam fixtureName sortOne (.bvar 0) .default) sortZero

def sourceZetaFixture : KExpr :=
  .letE fixtureName sortOne sortZero (.bvar 0) false

/-- The body TYPE is Sort 1 : Sort 2, hence codomain annotation TWO. -/
def betaFixtureAnnotation : AnnotatedModelTerm :=
  .app (.lam 2 (.sort 1) (.bvar 0)) (.sort 0)

def zetaFixtureAnnotation : AnnotatedModelTerm :=
  .letE (.sort 1) (.sort 0) (.bvar 0)

private theorem fixtureDomain (ρ : KName → Nat) :
    SourceModelTyping [] ρ [] [] sortOne sortTwo (.sort 1) (.sort 2) :=
  .sort [] [] (.succ .zero) trivial

private theorem fixtureBodyType (ρ : KName → Nat) :
    SourceModelTyping [] ρ [sortOne] [(.sort 1)]
      sortOne sortTwo (.sort 1) (.sort 2) :=
  .sort [sortOne] [(.sort 1)] (.succ .zero) trivial

private theorem fixtureBody (ρ : KName → Nat) :
    SourceModelTyping [] ρ [sortOne] [(.sort 1)]
      (.bvar 0) sortOne (.bvar 0) (.sort 1) :=
  .bound [sortOne] [(.sort 1)] 0 sortOne (.sort 1) rfl rfl rfl

private theorem fixtureArg (ρ : KName → Nat) :
    SourceModelTyping [] ρ [] [] sortZero sortOne (.sort 0) (.sort 1) :=
  .sort [] [] .zero trivial

/-- Explicit inhabitants of the source certificate relation for app AND let. -/
theorem sourceBetaZeta_certificates (ρ : KName → Nat) :
    SourceModelTyping [] ρ [] [] sourceBetaFixture sortOne
        betaFixtureAnnotation (.sort 1) ∧
    SourceModelTyping [] ρ [] [] sourceZetaFixture sortOne
        zetaFixtureAnnotation (.sort 1) := by
  have hLam : SourceModelTyping [] ρ [] []
      (.lam fixtureName sortOne (.bvar 0) .default)
      (.forallE fixtureName sortOne sortOne .default)
      (.lam 2 (.sort 1) (.bvar 0)) (.pi 2 (.sort 1) (.sort 1)) :=
    .lam [] [] fixtureName sortOne (.bvar 0) sortOne .default
      (.succ (.succ .zero)) (.succ (.succ .zero))
      (.sort 1) (.bvar 0) (.sort 1)
      (fixtureDomain ρ) (fixtureBodyType ρ) (fixtureBody ρ)
  constructor
  · exact .app [] [] (.lam fixtureName sortOne (.bvar 0) .default) sortZero
      fixtureName sortOne sortOne .default (.succ (.succ .zero))
      (.lam 2 (.sort 1) (.bvar 0)) (.sort 0) (.sort 1) (.sort 1)
      hLam (fixtureArg ρ)
  · exact .letE [] [] fixtureName sortOne sortZero (.bvar 0) sortOne
      (.succ (.succ .zero)) (.sort 1) (.sort 0) (.bvar 0) (.sort 1)
      (fixtureDomain ρ) (fixtureArg ρ) (fixtureBody ρ)

/--
The actual checker and actual two-sided G4.4b converter agree on these
examples. Both erasures and inferred-type memberships follow from the
GENERAL source-model theorem. No assumed runtime success or native_decide.
-/
theorem sourceBetaZeta_executed_model (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V) :
    inferClosedGeneralPi [] sourceBetaFixture = .ok sortOne ∧
    inferClosedGeneralPi [] sourceZetaFixture = .ok sortOne ∧
    (compareTypedWH (GeneralPiContext.empty []) sourceBetaFixture sourceZetaFixture 2).isEqual = true ∧
    eraseExpr ρ sourceBetaFixture = some betaFixtureAnnotation.forget ∧
    eraseExpr ρ sourceZetaFixture = some zetaFixtureAnnotation.forget ∧
    SetTheoryBasis.member (interpAnnotated V env betaFixtureAnnotation) (taggedSortSet V 1) ∧
    SetTheoryBasis.member (interpAnnotated V env zetaFixtureAnnotation) (taggedSortSet V 1) := by
  have hB := sourceModelTyping_executed V [] ρ sourceBetaFixture sortOne sortOne
    betaFixtureAnnotation (.sort 1) env (by rfl) (sourceBetaZeta_certificates ρ).1
  have hZ := sourceModelTyping_executed V [] ρ sourceZetaFixture sortOne sortOne
    zetaFixtureAnnotation (.sort 1) env (by rfl) (sourceBetaZeta_certificates ρ).2
  exact ⟨rfl, rfl, rfl, hB.2.1, hZ.2.1, hB.2.2.2, hZ.2.2.2⟩

/--
Use the SOURCE-CERTIFIED beta theorem, not just a standalone model equation.
Its fibre/body/argument membership premises are derived from actual source
certificates. Zeta uses the same actual-substitution erasure/semantics link.
-/
theorem sourceBetaZeta_equal_denotations (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V) :
    interpAnnotated V env betaFixtureAnnotation = taggedSortSet V 0 ∧
    interpAnnotated V env zetaFixtureAnnotation = taggedSortSet V 0 := by
  have hB := sourceModelTyping_beta V [] ρ [] [] env fixtureName .default
    sortOne (.bvar 0) sortOne sortZero
    (.succ (.succ .zero)) (.succ (.succ .zero))
    (.sort 1) (.bvar 0) (.sort 1) (.sort 0)
    (fixtureDomain ρ) (fixtureBodyType ρ) (fixtureBody ρ) (fixtureArg ρ)
    (AnnotatedContextValid.empty V env)
  have hZ := source_annotated_zeta V ρ env fixtureName sortOne sortZero (.bvar 0)
    (.sort 1) (.sort 0) (.bvar 0) rfl rfl rfl
  exact ⟨hB.2.2.2, hZ.2.2.2⟩

/--
The previously checked Prop/Type identity lambda terms now instantiate the
same GENERAL six-form typing theorem, including x:P in the proof case.
-/
theorem polyIdentity_executed_via_sourceModelTyping
    (V : Type u) [SetTheoryBasis V] (ρ : KName → Nat) (env : Nat → V) :
    inferClosedGeneralPi [] (polyIdentitySource .zero) =
      .ok (polyIdentitySourceType .zero) ∧
    inferClosedGeneralPi [] (polyIdentitySource (.succ .zero)) =
      .ok (polyIdentitySourceType (.succ .zero)) ∧
    SetTheoryBasis.member (interpAnnotated V env (polyIdentityAnnotation 0))
      (interpAnnotated V env (polyIdentityTypeAnnotation 0)) ∧
    SetTheoryBasis.member (interpAnnotated V env (polyIdentityAnnotation 1))
      (interpAnnotated V env (polyIdentityTypeAnnotation 1)) := by
  have h0 := sourceModelTyping_executed V [] ρ (polyIdentitySource .zero)
    (polyIdentitySourceType .zero) (polyIdentitySourceType .zero)
    (polyIdentityAnnotation 0) (polyIdentityTypeAnnotation 0) env (by rfl)
    (polyIdentity_sourceModelTyping [] ρ .zero trivial)
  have h1 := sourceModelTyping_executed V [] ρ (polyIdentitySource (.succ .zero))
    (polyIdentitySourceType (.succ .zero)) (polyIdentitySourceType (.succ .zero))
    (polyIdentityAnnotation 1) (polyIdentityTypeAnnotation 1) env (by rfl)
    (polyIdentity_sourceModelTyping [] ρ (.succ .zero) trivial)
  exact ⟨rfl, rfl, h0.2.2.2, h1.2.2.2⟩

#print axioms sourceBetaZeta_certificates
#print axioms sourceBetaZeta_executed_model
#print axioms sourceBetaZeta_equal_denotations
#print axioms polyIdentity_executed_via_sourceModelTyping

end PSKernelFast.Proof
