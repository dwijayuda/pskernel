import Ps.KernelCore.Metatheory.SemanticLocalContextExtension
import Ps.KernelCore.Metatheory.SemanticReferenceLocalContext
import Ps.KernelCore.Metatheory.SemanticReferenceBinders

/-!
Connect semantic context extension to the actual local contexts used by the
shared checker. The allocator result is the name in both erasure and semantics.
Freshness, scope and the domain/value's checked reading are explicit obligations
of binder entry. No recursive callback-soundness premise is added here.
-/
namespace PsKernelSemantics.Reference
open ConLeche ConLeche.SetTheory ConLeche.SetModel SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

theorem binderChild_localContext_model (M : Reading V) (Γ : List AnnotatedExpr)
    (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (locals : AnnotatedLocalContext) (n : PsKernelName)
    (A U : AnnotatedExpr) (bi : PsKernelBinderInfo) (ρ₀ : Nat → V) (x : V)
    (erasure : eraseLocalContext locals = c.localContext)
    (freshΓ : FreshBoundContext (psKernelCheckerStateFreshName s n).1 Γ)
    (freshLocals : FreshLocalContext (psKernelCheckerStateFreshName s n).1 locals)
    (freshA : Fresh (psKernelCheckerStateFreshName s n).1 A) (scopedA : A.Scoped 0)
    (model : ModelsLocalContext M Γ locals) (domain : CheckedReading M Γ A U)
    (member : x ∈ˢ interp M ρ₀ A) :
    let name := (psKernelCheckerStateFreshName s n).1
    let child := psKernelLocalContextAddLocal locals name n A bi
    eraseLocalContext child = (binderChild c s n A.erase bi).localContext ∧
      ModelsLocalContext (M.withFree name x) Γ child := by
  refine ⟨?_, modelsLocalContext_addLocal_fresh M Γ locals
    (psKernelCheckerStateFreshName s n).1 n A U bi ρ₀ x
    freshΓ freshLocals freshA scopedA model domain member⟩
  change eraseLocalContext
      (psKernelLocalContextAddLocal locals (psKernelCheckerStateFreshName s n).1 n A bi) =
    psKernelLocalContextAddLocal c.localContext (psKernelCheckerStateFreshName s n).1
      n A.erase bi
  rw [eraseLocalContext_addLocal, erasure]

/-- The actual let-branch context stores exactly the checked value and type.
The new assignment is constructed from that value's interpretation. -/
theorem letScope_localContext_model (M : Reading V) (Γ : List AnnotatedExpr)
    (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (locals : AnnotatedLocalContext) (n : PsKernelName)
    (A value : AnnotatedExpr) (ρ₀ : Nat → V)
    (erasure : eraseLocalContext locals = c.localContext)
    (freshΓ : FreshBoundContext (psKernelCheckerStateFreshName s n).1 Γ)
    (freshLocals : FreshLocalContext (psKernelCheckerStateFreshName s n).1 locals)
    (freshA : Fresh (psKernelCheckerStateFreshName s n).1 A)
    (freshValue : Fresh (psKernelCheckerStateFreshName s n).1 value)
    (scopedValue : value.Scoped 0)
    (model : ModelsLocalContext M Γ locals) (checked : CheckedReading M Γ value A) :
    let name := (psKernelCheckerStateFreshName s n).1
    let child := psKernelLocalContextAddLet locals name n A value
    let rawChild := psKernelCheckerContextWithLocalContext c
      (psKernelLocalContextAddLet c.localContext name n A.erase value.erase)
    eraseLocalContext child = rawChild.localContext ∧
      ModelsLocalContext (M.withFree name (interp M ρ₀ value)) Γ child := by
  refine ⟨?_, modelsLocalContext_addLet_fresh M Γ locals
    (psKernelCheckerStateFreshName s n).1 n A value ρ₀
    freshΓ freshLocals freshA freshValue scopedValue model checked⟩
  change eraseLocalContext
      (psKernelLocalContextAddLet locals (psKernelCheckerStateFreshName s n).1 n A value) =
    psKernelLocalContextAddLet c.localContext (psKernelCheckerStateFreshName s n).1
      n A.erase value.erase
  rw [eraseLocalContext_addLet, erasure]

/-- A free-variable visit inside the real binder child now obtains its context
model from the parent/domain premises. The caller does not assume that the
child context or any recursive callback is already sound. -/
theorem binderChild_fvar_checked_result (M : Reading V) (Γ : List AnnotatedExpr)
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (locals : AnnotatedLocalContext) (n query : PsKernelName)
    (A U : AnnotatedExpr) (bi : PsKernelBinderInfo) (ρ₀ : Nat → V) (x : V)
    (result : PsKernelExpr) (io : Bool)
    (erasure : eraseLocalContext locals = c.localContext)
    (freshΓ : FreshBoundContext (psKernelCheckerStateFreshName s n).1 Γ)
    (freshLocals : FreshLocalContext (psKernelCheckerStateFreshName s n).1 locals)
    (freshA : Fresh (psKernelCheckerStateFreshName s n).1 A) (scopedA : A.Scoped 0)
    (model : ModelsLocalContext M Γ locals) (domain : CheckedReading M Γ A U)
    (member : x ∈ˢ interp M ρ₀ A)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy fuel whnf defeq
      (binderChild c s n A.erase bi) (psKernelCheckerStateFreshName s n).2
      (.fvar query) io = .ok (result, next)) :
    let name := (psKernelCheckerStateFreshName s n).1
    let child := psKernelLocalContextAddLocal locals name n A bi
    ∃ decl : AnnotatedLocalDecl,
      psKernelLocalContextFind child query = some decl ∧
      let carried : AnnotatedInferenceResult :=
        { expr := .fvar query, type := psKernelLocalDeclType decl }
      carried.expr.erase = .fvar query ∧ eraseInferenceType carried = result ∧
        CheckedInferenceResult (M.withFree name x) Γ carried ∧
        next = (psKernelCheckerStateFreshName s n).2 := by
  obtain ⟨childErasure, childModel⟩ :=
    binderChild_localContext_model M Γ c s locals n A U bi ρ₀ x erasure
      freshΓ freshLocals freshA scopedA model domain member
  exact fvar_inference_checked_result
    (M.withFree (psKernelCheckerStateFreshName s n).1 x) Γ fuel whnf defeq
    (binderChild c s n A.erase bi) (psKernelCheckerStateFreshName s n).2 next
    query result io
    (psKernelLocalContextAddLocal locals (psKernelCheckerStateFreshName s n).1 n A bi)
    childErasure childModel run

end PsKernelSemantics.Reference
