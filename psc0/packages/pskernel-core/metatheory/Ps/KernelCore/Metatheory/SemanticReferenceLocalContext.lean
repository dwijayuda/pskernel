import Ps.KernelCore.Metatheory.SemanticCheckedReading
import Ps.KernelCore.Metatheory.AnnotatedLocalContextErasure
import Ps.KernelCore.Metatheory.SemanticReference

/-!
A complete model theorem for the actual reference checker's free-variable
branch, in both inference modes. It needs no correctness premise for WHNF,
definitional equality, recursive inference or semantic caches: none of those
operations determines the result of this branch in reference mode.

The local-context model is the explicit induction invariant to establish on
binder entry and preserve through the shared recursive interfaces. This theorem
does not establish that invariant for arbitrary raw contexts or close the whole
recursive checker.
-/
namespace PsKernelSemantics.Reference

private theorem entered_localContext (c entered : PsKernelCheckerContext)
    (h : psKernelCheckerContextEnterRecDepth c = .ok entered) :
    entered.localContext = c.localContext := by
  by_cases hz : Nat.beq c.maxRecDepth 0 = true
  · simp only [psKernelCheckerContextEnterRecDepth, hz, ite_true, Except.ok.injEq] at h
    exact (congrArg PsKernelCheckerContext.localContext h).symm
  · by_cases hl : psKernelNatGt (Nat.succ c.recDepth)
        (Nat.mul c.maxRecDepth psKernelRecDepthFactor) = true
    · simp only [psKernelCheckerContextEnterRecDepth, hz, hl,
        Bool.false_eq_true, ite_false, ite_true] at h
      cases h
    · simp only [psKernelCheckerContextEnterRecDepth, hz, hl,
        Bool.false_eq_true, ite_false, Except.ok.injEq] at h
      exact (congrArg PsKernelCheckerContext.localContext h).symm

/-- Every successful free-variable visit returns the actual stored type.
Reference-mode publication also leaves the complete state unchanged. -/
theorem inferCore_fvar_result
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (name : PsKernelName) (result : PsKernelExpr) (io : Bool)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      fuel whnf defeq c s (.fvar name) io = .ok (result, next)) :
    ∃ decl, psKernelLocalContextFind c.localContext name = some decl ∧
      result = psKernelLocalDeclType decl ∧ next = s := by
  cases fuel with
  | zero => simp [psKernelInferCoreWithFuel] at run
  | succ fuel =>
      cases he : psKernelCheckerContextEnterRecDepth c with
      | error error =>
          simp [psKernelInferCoreWithFuel, psKernelSemanticCacheGet,
            psKernelReferenceCachePolicy, he] at run
      | ok entered =>
          have hlocal := entered_localContext c entered he
          cases hd : psKernelLocalContextFind entered.localContext name with
          | none =>
              simp [psKernelInferCoreWithFuel, psKernelSemanticCacheGet,
                psKernelReferenceCachePolicy, he, hd] at run
          | some decl =>
              have hr : psKernelLocalDeclType decl = result ∧ s = next := by
                simpa only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                  ite_self, he, hd, infer_publication_noop,
                  Except.ok.injEq, Prod.mk.injEq] using run
              refine ⟨decl, ?_, hr.1.symm, hr.2.symm⟩
              simpa only [hlocal] using hd

open ConLeche SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- The returned reading is exactly the stored annotated type, with all four
hereditary facts. No fresh existential re-annotation of that type is permitted. -/
theorem fvar_inference_checked_reading (M : Reading V) (Γ : List AnnotatedExpr)
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (name : PsKernelName) (result : PsKernelExpr) (io : Bool)
    (locals : AnnotatedLocalContext)
    (erasure : eraseLocalContext locals = c.localContext)
    (localModel : ModelsLocalContext M Γ locals)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      fuel whnf defeq c s (.fvar name) io = .ok (result, next)) :
    ∃ decl : AnnotatedLocalDecl,
      psKernelLocalContextFind locals name = some decl ∧
      (psKernelLocalDeclType decl).erase = result ∧
      CheckedReading M Γ (.fvar name) (psKernelLocalDeclType decl) ∧ next = s := by
  obtain ⟨rawDecl, found, resultEq, stateEq⟩ :=
    inferCore_fvar_result fuel whnf defeq c s next name result io run
  have foundErased :
      psKernelLocalContextFind (eraseLocalContext locals) name = some rawDecl := by
    simpa only [erasure] using found
  obtain ⟨decl, hd, rawEq⟩ :=
    eraseLocalContext_find_some locals name rawDecl foundErased
  refine ⟨decl, hd, ?_,
    LocalDeclModel.checkedReading M Γ name decl (localModel name decl hd), stateEq⟩
  calc
    (psKernelLocalDeclType decl).erase =
        psKernelLocalDeclType (eraseLocalDecl decl) :=
      (eraseLocalDecl_type decl).symm
    _ = psKernelLocalDeclType rawDecl := congrArg psKernelLocalDeclType rawEq
    _ = result := resultEq.symm

/-- The same concrete run supplies the new carried-result contract. -/
theorem fvar_inference_checked_result (M : Reading V) (Γ : List AnnotatedExpr)
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (name : PsKernelName) (result : PsKernelExpr) (io : Bool)
    (locals : AnnotatedLocalContext)
    (erasure : eraseLocalContext locals = c.localContext)
    (localModel : ModelsLocalContext M Γ locals)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      fuel whnf defeq c s (.fvar name) io = .ok (result, next)) :
    ∃ decl : AnnotatedLocalDecl,
      psKernelLocalContextFind locals name = some decl ∧
      let carried : AnnotatedInferenceResult :=
        { expr := .fvar name, type := psKernelLocalDeclType decl }
      carried.expr.erase = .fvar name ∧
        eraseInferenceType carried = result ∧
        CheckedInferenceResult M Γ carried ∧ next = s := by
  obtain ⟨decl, found, typeEq, checked, stateEq⟩ :=
    fvar_inference_checked_reading M Γ fuel whnf defeq c s next name result io
      locals erasure localModel run
  exact ⟨decl, found, rfl, typeEq, checked, stateEq⟩

end PsKernelSemantics.Reference
