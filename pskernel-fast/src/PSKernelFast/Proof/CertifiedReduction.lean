import PSKernelFast.Proof.SourceCertificateSynthesis

/-!
P1r: derive semantic preservation for every SOURCE-CERTIFIED weak-head step.

This uses the ACTUAL Core.WeakHeadStep and KExpr.instantiateBVar operation.
The output annotation is computed by the corresponding annotation step;
its ranks are preserved, not re-guessed from a reduct's erased shape.

The main theorem derives beta's body/fibre/argument premises by inverting
SourceModelTyping. Zeta uses already-proved actual-source substitution.
The function-spine case follows by induction and uniform modelApp congruence.
No assumed stepSound or semantic-membership premise is added except the
ordinary valid interpretation of an OPEN source context.

Typed substitution CLOSURE is not implied: the theorem does not assert
that the reduct has a SourceModelTyping certificate. A future executing
chain must either prove that closure or re-synthesize and check its carried
annotation. All conclusions remain conditional on SetTheoryBasis V.
-/

namespace PSKernelFast.Proof
open PSKernelFast.Core PSKernelFast.Spec
universe u

/-- The annotation analogue of the same beta/let/function-spine operation. -/
def stepModelAnnotation : AnnotatedModelTerm → Option AnnotatedModelTerm
  | .app (.lam _ _ body) arg => some (body.instantiate arg 0)
  | .app fn arg => (stepModelAnnotation fn).map (fun next => .app next arg)
  | .letE _ value body => some (body.instantiate value 0)
  | _ => none

private theorem stepModelAnnotation_app
    {fn next arg : AnnotatedModelTerm}
    (h : stepModelAnnotation fn = some next) :
    stepModelAnnotation (.app fn arg) = some (.app next arg) := by
  cases fn with
  | bvar i => simp [stepModelAnnotation] at h
  | sort n => simp [stepModelAnnotation] at h
  | lam n a b => simp [stepModelAnnotation] at h
  | pi n a b => simp [stepModelAnnotation] at h
  | app f a =>
      change (stepModelAnnotation (.app f a)).map (fun k => .app k arg) = _
      rw [h]
      rfl
  | letE a v b =>
      change (stepModelAnnotation (.letE a v b)).map (fun k => .app k arg) = _
      rw [h]
      rfl

/--
Every actual certified weak-head step has a COMPUTED annotation successor,
correct source erasure and equal model meaning. There is no stepSound
hypothesis. The source context may contain genuinely dependent/proof binders.
-/
theorem sourceModelTyping_step (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat)
    (ctx : List KExpr) (ac : List AnnotatedModelTerm)
    (env : Nat → V) (hCtx : AnnotatedContextValid V ac env)
    {source next ty : KExpr} {ann aTy : AnnotatedModelTerm}
    (typing : SourceModelTyping params ρ ctx ac source ty ann aTy)
    (step : WeakHeadStep source next) :
    ∃ nextAnn : AnnotatedModelTerm,
      stepModelAnnotation ann = some nextAnn ∧
      eraseExpr ρ next = some nextAnn.forget ∧
      interpAnnotated V env ann = interpAnnotated V env nextAnn := by
  induction step generalizing ty ann aTy with
  | beta name domain body style arg =>
      cases typing with
      | app _ _ _ _ fnName fnDomain fnBody fnStyle rank af aa ad ab hf ha =>
          cases hf with
          | lam _ _ _ _ _ bodyType _ a b ad' ab' aType hd ht hb =>
              have result := sourceModelTyping_beta V params ρ ctx ac env
                name style domain body bodyType arg a b ad' ab' aType aa
                hd ht hb ha hCtx
              exact ⟨ab'.instantiate aa 0, rfl, result.2.2.1, result.2.2.2⟩
  | zeta name declared value body =>
      cases typing with
      | letE _ _ _ _ _ _ bodyType level ad av ab aType hd hv hb =>
          have result := source_annotated_zeta V ρ env name declared value body ad av ab
            (sourceModelTyping_erases params ρ hd).1
            (sourceModelTyping_erases params ρ hv).1
            (sourceModelTyping_erases params ρ hb).1
          exact ⟨ab.instantiate av 0, rfl, result.2.2.1, result.2.2.2⟩
  | @app fn next step arg ih =>
      cases typing with
      | app _ _ _ _ name domain body style rank af aa ad ab hf ha =>
          obtain ⟨nextAnn, hNext, hErase, hMeaning⟩ := ih hf
          refine ⟨.app nextAnn aa, stepModelAnnotation_app hNext, ?_, ?_⟩
          · simp [eraseExpr, AnnotatedModelTerm.forget, hErase,
              (sourceModelTyping_erases params ρ ha).1]
          · exact congrArg (fun f => modelApp V f (interpAnnotated V env aa)) hMeaning

/--
A chain keeps the exact source type fixed. Every SOURCE of a step must have
its own genuine certificate and the successor annotation must be the
computed one. All historical evidence is Prop and is erased at runtime.
The final certificate is supplied separately by the eventual executor.
-/
inductive ModelSteps (params : List KName) (ρ : KName → Nat) (ty : KExpr) :
    Nat → KExpr → AnnotatedModelTerm → KExpr → AnnotatedModelTerm → Prop where
  | refl (source : KExpr) (ann : AnnotatedModelTerm) :
      ModelSteps params ρ ty 0 source ann source ann
  | snoc {source current next : KExpr}
      {sourceAnn currentAnn nextAnn typeAnn : AnnotatedModelTerm} {steps : Nat}
      (prior : ModelSteps params ρ ty steps source sourceAnn current currentAnn)
      (typed : SourceModelTyping params ρ [] [] current ty currentAnn typeAnn)
      (step : WeakHeadStep current next)
      (annotation : stepModelAnnotation currentAnn = some nextAnn) :
      ModelSteps params ρ ty (steps + 1) source sourceAnn next nextAnn

/-- A source-certified chain preserves the concrete model, with NO stepSound premise. -/
theorem ModelSteps.sound (V : Type u) [SetTheoryBasis V]
    {params : List KName} {ρ : KName → Nat} {ty source target : KExpr}
    {sourceAnn targetAnn : AnnotatedModelTerm} {steps : Nat}
    (path : ModelSteps params ρ ty steps source sourceAnn target targetAnn)
    (env : Nat → V) :
    interpAnnotated V env sourceAnn = interpAnnotated V env targetAnn := by
  induction path with
  | refl source ann => rfl
  | snoc prior typed step annotation ih =>
      obtain ⟨nextAnn, hNext, _, hMeaning⟩ :=
        sourceModelTyping_step V params ρ [] [] env
          (AnnotatedContextValid.empty V env) typed step
      have same : nextAnn = _ := Option.some.inj (hNext.symm.trans annotation)
      exact ih.trans (by simpa only [same] using hMeaning)

#print axioms sourceModelTyping_step
#print axioms ModelSteps.sound

end PSKernelFast.Proof
