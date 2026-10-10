import Ps.KernelCore.Metatheory.SemanticReferenceLocalContext
import Ps.KernelCore.Checker.Session

/-!
The actual fully checked public checker-session free-variable case.

The real psKernelSessionCheck operation delegates through Checker/Knot,
psKernelCheckWithFuel and the shared inference core. With the semantic cache
policy fixed to reference mode, a successful free-variable check selects the
first stored local declaration, returns that exact type and does not change
the checker state. Under a concrete erasure/model witness, the returned
type is the *same annotated stored type*, not an existentially invented
interpretation of a raw expression.

This is a conditional branch-soundness lemma. Establishing the local-context
model for every recursive checker call, preserving annotations across WHNF/
DefEq, and the full public-admission consistency theorem remain open.
-/

namespace PsKernelSemantics.Reference
open PsKernelSemantics.SetModel ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- A real fully checked reference-session free-variable call selects the
first stored raw declaration. No recursive WHNF or DefEq claim is needed
for this syntax-directed branch. -/
theorem referenceSessionCheck_fvar_selected
    (fuel : Nat) (session next : PsKernelCheckerSession)
    (name : PsKernelName) (type : PsKernelExpr)
    (run : @psKernelSessionCheck psKernelReferenceCachePolicy
      fuel session (.fvar name) = .ok (type, next)) :
    ∃ decl : PsKernelLocalDecl,
      psKernelLocalContextFind session.context.localContext name = some decl ∧
      type = psKernelLocalDeclType decl ∧
      next.context = session.context ∧
      next.state = session.state := by
  cases hCore : @psKernelCheckerCheck psKernelReferenceCachePolicy
      fuel session.context session.state (.fvar name) with
  | error err =>
      simp [psKernelSessionCheck, hCore] at run
  | ok pair =>
      rcases pair with ⟨rawType, returnedState⟩
      have checked :
          @psKernelInferCoreWithFuel psKernelReferenceCachePolicy fuel
            (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
              (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
            (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
            session.context session.state (.fvar name) false =
              .ok (rawType, returnedState) := by
        simpa only [psKernelCheckerCheck, psKernelCheckWithFuel] using hCore
      obtain ⟨decl, found, rawTypeEq, stateEq⟩ :=
        inferCore_fvar_result fuel
          (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
            (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
          (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
          session.context session.state returnedState name rawType false checked
      have hPair :
          (rawType, PsKernelCheckerSession.mk session.context returnedState) =
            (type, next) := by
        simpa [psKernelSessionCheck, hCore] using run
      have hType : rawType = type := congrArg Prod.fst hPair
      have hNext :
          PsKernelCheckerSession.mk session.context returnedState = next :=
        congrArg Prod.snd hPair
      refine ⟨decl, found, hType.symm.trans rawTypeEq, ?_, ?_⟩
      · rw [← hNext]
      · rw [← hNext]
        exact stateEq

/-- The public checked fvar result carries the particular annotated type
from the exact first stored local declaration. It retains typing and both
hereditary validity invariants even if the semantic binder domain is empty.
No new annotation is selected from a vacuous semantic proposition. -/
theorem referenceSessionCheck_fvar_checked_reading (M : Reading V)
    (Γ : List AnnotatedExpr)
    (fuel : Nat) (session next : PsKernelCheckerSession)
    (name : PsKernelName) (type : PsKernelExpr)
    (locals : AnnotatedLocalContext)
    (erasure : eraseLocalContext locals = session.context.localContext)
    (localModel : ModelsLocalContext M Γ locals)
    (run : @psKernelSessionCheck psKernelReferenceCachePolicy
      fuel session (.fvar name) = .ok (type, next)) :
    ∃ decl : AnnotatedLocalDecl,
      psKernelLocalContextFind locals name = some decl ∧
      (psKernelLocalDeclType decl).erase = type ∧
      CheckedReading M Γ (.fvar name) (psKernelLocalDeclType decl) ∧
      next.context = session.context ∧ next.state = session.state := by
  obtain ⟨rawDecl, found, rawTypeEq, contextEq, stateEq⟩ :=
    referenceSessionCheck_fvar_selected fuel session next name type run
  have foundErased :
      psKernelLocalContextFind (eraseLocalContext locals) name = some rawDecl := by
    simpa only [erasure] using found
  obtain ⟨decl, foundAnnotated, erasureDecl⟩ :=
    eraseLocalContext_find_some locals name rawDecl foundErased
  have typeErasure : (psKernelLocalDeclType decl).erase = type := by
    calc
      (psKernelLocalDeclType decl).erase =
          psKernelLocalDeclType (eraseLocalDecl decl) :=
        (eraseLocalDecl_type decl).symm
      _ = psKernelLocalDeclType rawDecl :=
        congrArg psKernelLocalDeclType erasureDecl
      _ = type := rawTypeEq.symm
  exact ⟨decl, foundAnnotated, typeErasure,
    LocalDeclModel.checkedReading M Γ name decl
      (localModel name decl foundAnnotated), contextEq, stateEq⟩

/-- The infer-only session grade reaches the same concrete first local
declaration, without silently upgrading an unchecked result to a checked
recursive proof. The fvar branch is a separately justified model base case. -/
theorem referenceSessionInfer_fvar_selected
    (fuel : Nat) (session next : PsKernelCheckerSession)
    (name : PsKernelName) (type : PsKernelExpr)
    (run : @psKernelSessionInfer psKernelReferenceCachePolicy
      fuel session (.fvar name) = .ok (type, next)) :
    ∃ decl : PsKernelLocalDecl,
      psKernelLocalContextFind session.context.localContext name = some decl ∧
      type = psKernelLocalDeclType decl ∧
      next.context = session.context ∧
      next.state = session.state := by
  cases hCore : @psKernelCheckerInfer psKernelReferenceCachePolicy
      fuel session.context session.state (.fvar name) with
  | error err =>
      simp [psKernelSessionInfer, hCore] at run
  | ok pair =>
      rcases pair with ⟨rawType, returnedState⟩
      have inferred :
          @psKernelInferCoreWithFuel psKernelReferenceCachePolicy fuel
            (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
              (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
            (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
            session.context session.state (.fvar name) true =
              .ok (rawType, returnedState) := by
        simpa only [psKernelCheckerInfer, psKernelInferWithRecursorFuel,
          psKernelInferWithFuel] using hCore
      obtain ⟨decl, found, rawTypeEq, stateEq⟩ :=
        inferCore_fvar_result fuel
          (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
            (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
          (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
          session.context session.state returnedState name rawType true inferred
      have hPair :
          (rawType, PsKernelCheckerSession.mk session.context returnedState) =
            (type, next) := by
        simpa [psKernelSessionInfer, hCore] using run
      have hType : rawType = type := congrArg Prod.fst hPair
      have hNext :
          PsKernelCheckerSession.mk session.context returnedState = next :=
        congrArg Prod.snd hPair
      refine ⟨decl, found, hType.symm.trans rawTypeEq, ?_, ?_⟩
      · rw [← hNext]
      · rw [← hNext]
        exact stateEq

/-- Inference-only fvar acceptance is model-valid under exactly the same
fixed stored-local model as checked fvar acceptance. This is a special
syntax-directed case, not a claim that arbitrary infer-only inputs are safe. -/
theorem referenceSessionInfer_fvar_checked_reading (M : Reading V)
    (Γ : List AnnotatedExpr)
    (fuel : Nat) (session next : PsKernelCheckerSession)
    (name : PsKernelName) (type : PsKernelExpr)
    (locals : AnnotatedLocalContext)
    (erasure : eraseLocalContext locals = session.context.localContext)
    (localModel : ModelsLocalContext M Γ locals)
    (run : @psKernelSessionInfer psKernelReferenceCachePolicy
      fuel session (.fvar name) = .ok (type, next)) :
    ∃ decl : AnnotatedLocalDecl,
      psKernelLocalContextFind locals name = some decl ∧
      (psKernelLocalDeclType decl).erase = type ∧
      CheckedReading M Γ (.fvar name) (psKernelLocalDeclType decl) ∧
      next.context = session.context ∧ next.state = session.state := by
  obtain ⟨rawDecl, found, rawTypeEq, contextEq, stateEq⟩ :=
    referenceSessionInfer_fvar_selected fuel session next name type run
  have foundErased :
      psKernelLocalContextFind (eraseLocalContext locals) name = some rawDecl := by
    simpa only [erasure] using found
  obtain ⟨decl, foundAnnotated, erasureDecl⟩ :=
    eraseLocalContext_find_some locals name rawDecl foundErased
  have typeErasure : (psKernelLocalDeclType decl).erase = type := by
    calc
      (psKernelLocalDeclType decl).erase =
          psKernelLocalDeclType (eraseLocalDecl decl) :=
        (eraseLocalDecl_type decl).symm
      _ = psKernelLocalDeclType rawDecl :=
        congrArg psKernelLocalDeclType erasureDecl
      _ = type := rawTypeEq.symm
  exact ⟨decl, foundAnnotated, typeErasure,
    LocalDeclModel.checkedReading M Γ name decl
      (localModel name decl foundAnnotated), contextEq, stateEq⟩

/-- An initial public checker session has an empty local context; hence no
successful reference-mode free-variable *session check* can originate there.
Free variables become checkable only in explicitly constructed local scopes. -/
theorem referenceInitialSessionCheck_fvar_cannot_succeed
    (fuel : Nat) (env : PsKernelEnvironment)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat) (name : PsKernelName)
    (type : PsKernelExpr) (next : PsKernelCheckerSession) :
    @psKernelSessionCheck psKernelReferenceCachePolicy fuel
      (psKernelMkCheckerSession env params safety maxRecDepth maxNatSize)
      (.fvar name) ≠ .ok (type, next) := by
  intro run
  obtain ⟨decl, found, _, _, _⟩ :=
    referenceSessionCheck_fvar_selected fuel
      (psKernelMkCheckerSession env params safety maxRecDepth maxNatSize)
      next name type run
  simp [psKernelMkCheckerSession, psKernelCheckerContextEmpty,
    psKernelLocalContextEmpty, psKernelLocalContextEmptyOf,
    psKernelLocalContextFind, psKernelLocalContextFindIn] at found

end PsKernelSemantics.Reference
