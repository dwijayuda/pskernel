import PSKernelFast.Proof.CertifiedReduction

/-!
P1s: an EXECUTABLE, model-sound closed weak-head comparison path.

Inputs are source expressions, a universe valuation and two fuel bounds.
The caller supplies NO source certificates, annotations, semantic context,
model or stepSound theorem. Certificates are generated for each source and
its type. Every actual Core.stepWeakHead reduct is re-certified and its
annotation is checked against the computed structural annotation reduct.
That guard is essential until typed substitution closure has been proved.

All historical paths are Prop and erased. Source/type/annotation trees are
retained data and repeated certificate construction is not claimed cheap.
The main loop is tail recursive. Reduction fuel counts inspections per side
including the final terminal inspection; certificate fuel bounds recursive
search depth. Neither is a total CPU, RSS or allocation bound.

Every positive result has the old Core.TypedSteps operational contract AND
concrete set-model equality with no assumed stepSound premise. This is a
CONSERVATIVE certified path, not a proof that all raw G4.4b positives are
covered. No declarations, new conversion rules, or model axioms are added.
-/

namespace PSKernelFast.Proof
open PSKernelFast.Core PSKernelFast.Spec
universe u

/-- The model-certified paths also refine the EXISTING operational path relation. -/
theorem ModelSteps.operational
    {params : List KName} {ρ : KName → Nat} {ty source target : KExpr}
    {sourceAnn targetAnn : AnnotatedModelTerm} {steps : Nat}
    (path : ModelSteps params ρ ty steps source sourceAnn target targetAnn)
    (targetTyped : GeneralPiRule params [] target ty) :
    TypedSteps params [] ty steps source target := by
  induction path with
  | refl source ann => exact .refl targetTyped
  | snoc prior typed step annotation ih =>
      exact .snoc (ih (sourceModelTyping_typed params ρ typed)) step targetTyped

/-- Final data and erased invariants for one source normalization. -/
structure ModelNormalForm (params : List KName) (ρ : KName → Nat)
    (source : KExpr) (initial : ClosedModelCertificate params ρ source)
    (fuel : Nat) where
  value : KExpr
  certificate : ClosedModelCertificate params ρ value
  sameType : certificate.typing.sourceType = initial.typing.sourceType
  steps : Nat
  path : ModelSteps params ρ initial.typing.sourceType steps
    source initial.typing.termAnnotation value certificate.typing.termAnnotation
  within : steps < fuel
  stable : stepWeakHead value = none

/-- Typed and annotation-checked tail recursion; no model values are computed. -/
private def normalizeModelLoop (params : List KName) (ρ : KName → Nat)
    (source : KExpr) (initial : ClosedModelCertificate params ρ source)
    (limit certificateFuel : Nat) :
    (remaining used : Nat) → (current : KExpr) →
    (candidate : ClosedModelCertificate params ρ current) →
    candidate.typing.sourceType = initial.typing.sourceType →
    used + remaining = limit →
    ModelSteps params ρ initial.typing.sourceType used source initial.typing.termAnnotation
      current candidate.typing.termAnnotation →
    Except ModelCertificateError (ModelNormalForm params ρ source initial limit)
  | 0, _, _, _, _, _, _ => .error .fuelExhausted
  | remaining + 1, used, current, candidate, currentType, balance, history =>
      match hNext : stepWeakHead current with
      | none => .ok {
          value := current
          certificate := candidate
          sameType := currentType
          steps := used
          path := history
          within := by omega
          stable := hNext
        }
      | some reduct => do
          let next ← certifyClosedModel params ρ reduct.val certificateFuel
          if sameType : next.typing.sourceType = initial.typing.sourceType then
            match hAnnotation : stepModelAnnotation candidate.typing.termAnnotation with
            | none => .error .unresolved
            | some expected =>
                if sameAnnotation : next.typing.termAnnotation = expected then
                  normalizeModelLoop params ρ source initial limit certificateFuel
                    remaining (used + 1) reduct.val next sameType (by omega)
                    (.snoc history
                      (by simpa only [currentType] using candidate.typing.certificate)
                      reduct.property
                      (by simpa only [sameAnnotation] using hAnnotation))
                else .error .unresolved
          else .error .unresolved

structure ModelNormalized (params : List KName) (ρ : KName → Nat)
    (source : KExpr) (fuel : Nat) where
  initial : ClosedModelCertificate params ρ source
  normal : ModelNormalForm params ρ source initial fuel

/-- Source-only entry: all certificates are produced, not requested as arguments. -/
def normalizeModelClosed (params : List KName) (ρ : KName → Nat)
    (source : KExpr) (certificateFuel : Nat) : (reductionFuel : Nat) →
    Except ModelCertificateError (ModelNormalized params ρ source reductionFuel)
  | 0 => .error .fuelExhausted
  | fuel + 1 => do
      let initial ← certifyClosedModel params ρ source certificateFuel
      let normal ← normalizeModelLoop params ρ source initial (fuel + 1) certificateFuel
        (fuel + 1) 0 source initial rfl (Nat.zero_add (fuel + 1))
        (.refl source initial.typing.termAnnotation)
      return { initial := initial, normal := normal }

/-- Two computed normalizations, exact source type, and one actual common head. -/
structure CertifiedModelJoin (params : List KName) (ρ : KName → Nat)
    (lhs rhs : KExpr) (fuel : Nat) where
  left : ModelNormalized params ρ lhs fuel
  right : ModelNormalized params ρ rhs fuel
  sameType : left.initial.typing.sourceType = right.initial.typing.sourceType
  sameHead : left.normal.value = right.normal.value

/--
Positive-only closed comparison. Errors and unresolved results are never
negative Lean definitional-equality judgments. No external proof witness.
-/
def compareCertifiedWH (params : List KName) (ρ : KName → Nat)
    (lhs rhs : KExpr) (reductionFuel certificateFuel : Nat) :
    Except ModelCertificateError (CertifiedModelJoin params ρ lhs rhs reductionFuel) := do
  let left ← normalizeModelClosed params ρ lhs certificateFuel reductionFuel
  let right ← normalizeModelClosed params ρ rhs certificateFuel reductionFuel
  if sameType : left.initial.typing.sourceType = right.initial.typing.sourceType then
    if sameHead : left.normal.value = right.normal.value then
      return { left := left, right := right, sameType := sameType, sameHead := sameHead }
    else .error .unresolved
  else .error .unresolved

private theorem equalSourceAnnotations (params : List KName) (ρ : KName → Nat)
    {source other ty otherTy : KExpr} {ann otherAnn aTy otherATy : AnnotatedModelTerm}
    (same : source = other)
    (left : SourceModelTyping params ρ [] [] source ty ann aTy)
    (right : SourceModelTyping params ρ [] [] other otherTy otherAnn otherATy) :
    ann = otherAnn := by
  cases same
  exact (sourceModelTyping_annotations_unique params ρ left right).1

/-- Common source heads have the same annotation by the proved coherence law. -/
theorem CertifiedModelJoin.meaning (V : Type u) [SetTheoryBasis V]
    {params : List KName} {ρ : KName → Nat} {lhs rhs : KExpr} {fuel : Nat}
    (join : CertifiedModelJoin params ρ lhs rhs fuel) (env : Nat → V) :
    interpAnnotated V env join.left.initial.typing.termAnnotation =
      interpAnnotated V env join.right.initial.typing.termAnnotation := by
  have common := equalSourceAnnotations params ρ join.sameHead
    join.left.normal.certificate.typing.certificate
    join.right.normal.certificate.typing.certificate
  have left := ModelSteps.sound V join.left.normal.path env
  have right := ModelSteps.sound V join.right.normal.path env
  exact left.trans ((congrArg (interpAnnotated V env) common).trans right.symm)

/--
Every ACTUAL successful certified comparison has actual source-checker
successes at one type, equal denotations, and both values in that type's
interpretation. Only the explicit mathematical model is assumed.
-/
theorem compareCertifiedWH_sound (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat) (lhs rhs : KExpr)
    (reductionFuel certificateFuel : Nat)
    (join : CertifiedModelJoin params ρ lhs rhs reductionFuel)
    (_success : compareCertifiedWH params ρ lhs rhs reductionFuel certificateFuel = .ok join)
    (env : Nat → V) :
    inferClosedGeneralPi params lhs = .ok join.left.initial.typing.sourceType ∧
    inferClosedGeneralPi params rhs = .ok join.left.initial.typing.sourceType ∧
    interpAnnotated V env join.left.initial.typing.termAnnotation =
      interpAnnotated V env join.right.initial.typing.termAnnotation ∧
    SetTheoryBasis.member (interpAnnotated V env join.left.initial.typing.termAnnotation)
      (interpAnnotated V env join.left.initial.typing.typeAnnotation) ∧
    SetTheoryBasis.member (interpAnnotated V env join.right.initial.typing.termAnnotation)
      (interpAnnotated V env join.left.initial.typing.typeAnnotation) := by
  have typeAnnotation := equalSourceAnnotations params ρ join.sameType
    join.left.initial.typeCertificate join.right.initial.typeCertificate
  have leftMember := sourceModelTyping_sound V params ρ
    join.left.initial.typing.certificate env (AnnotatedContextValid.empty V env)
  have rightMember := sourceModelTyping_sound V params ρ
    join.right.initial.typing.certificate env (AnnotatedContextValid.empty V env)
  refine ⟨join.left.initial.inferred, ?_, CertifiedModelJoin.meaning V join env,
    leftMember, ?_⟩
  · simpa only [join.sameType] using join.right.initial.inferred
  · simpa only [typeAnnotation] using rightMember

/-- The new certified path also proves the old bounded typed common-head contract. -/
theorem compareCertifiedWH_operational
    (params : List KName) (ρ : KName → Nat) (lhs rhs : KExpr)
    (reductionFuel certificateFuel : Nat)
    (join : CertifiedModelJoin params ρ lhs rhs reductionFuel)
    (_success : compareCertifiedWH params ρ lhs rhs reductionFuel certificateFuel = .ok join) :
    TypedSteps params [] join.left.initial.typing.sourceType join.left.normal.steps
      lhs join.left.normal.value ∧
    TypedSteps params [] join.left.initial.typing.sourceType join.right.normal.steps
      rhs join.left.normal.value ∧
    join.left.normal.steps + join.right.normal.steps < 2 * reductionFuel ∧
    stepWeakHead join.left.normal.value = none := by
  have leftTyped : GeneralPiRule params [] join.left.normal.value
      join.left.initial.typing.sourceType := by
    simpa only [join.left.normal.sameType] using
      (sourceModelTyping_typed params ρ join.left.normal.certificate.typing.certificate)
  have rightTyped : GeneralPiRule params [] join.right.normal.value
      join.right.initial.typing.sourceType := by
    simpa only [join.right.normal.sameType] using
      (sourceModelTyping_typed params ρ join.right.normal.certificate.typing.certificate)
  have left := ModelSteps.operational join.left.normal.path leftTyped
  have right := ModelSteps.operational join.right.normal.path rightTyped
  refine ⟨left, ?_, ?_, join.left.normal.stable⟩
  · simpa only [join.sameType, join.sameHead] using right
  · have hl := join.left.normal.within
    have hr := join.right.normal.within
    omega

theorem compareCertifiedWH_zero (params : List KName) (ρ : KName → Nat)
    (lhs rhs : KExpr) (certificateFuel : Nat) :
    compareCertifiedWH params ρ lhs rhs 0 certificateFuel = .error .fuelExhausted := rfl

#print axioms ModelSteps.operational
#print axioms compareCertifiedWH_sound
#print axioms compareCertifiedWH_operational
#print axioms compareCertifiedWH_zero

end PSKernelFast.Proof
