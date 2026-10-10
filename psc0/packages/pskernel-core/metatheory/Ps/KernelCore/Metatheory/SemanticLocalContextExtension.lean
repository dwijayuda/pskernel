import Ps.KernelCore.Metatheory.SemanticCheckedReading
import Ps.KernelCore.Metatheory.SemanticValidityScope

/-!
Semantic local-context extension through the shared production operations.

Freshness is syntactic and independent of satisfying valuations. The stored
annotated expressions are fixed before semantic quantification. None of these
lemmas selects or validates a binder annotation from semantic membership.

The general insertion lemmas require membership under every satisfying bound
valuation. Their fresh-scope corollaries use the runtime scope invariant
(no loose bound variables) to obtain that membership from one actual value.
Allocator freshness and preservation of scope must still be proved by the
recursive checker; a numeric-looking name alone is not evidence of freshness.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

def FreshBoundContext (name : PsKernelName) : List AnnotatedExpr → Prop
  | [] => True
  | A :: Γ => Fresh name A ∧ FreshBoundContext name Γ

structure LocalDeclFresh (name query : PsKernelName)
    (decl : AnnotatedLocalDecl) : Prop where
  queryFresh : psKernelNameEq query name = false
  typeFresh : Fresh name (psKernelLocalDeclType decl)
  valueFresh : ∀ value, psKernelLocalDeclValue decl = some value → Fresh name value

def FreshLocalContext (name : PsKernelName)
    (context : AnnotatedLocalContext) : Prop :=
  ∀ query decl, psKernelLocalContextFind context query = some decl →
    LocalDeclFresh name query decl

theorem freshLocalContext_empty (name : PsKernelName) :
    FreshLocalContext name annotatedLocalContextEmpty := by
  intro query decl found
  simp [annotatedLocalContextEmpty, psKernelLocalContextEmptyOf,
    psKernelLocalContextFind, psKernelLocalContextFindIn] at found

theorem satisfies_withFree_fresh (M : Reading V) (Γ : List AnnotatedExpr)
    (name : PsKernelName) (fresh : FreshBoundContext name Γ)
    (x : V) (ρ : Nat → V) :
    Satisfies (M.withFree name x) Γ ρ ↔ Satisfies M Γ ρ := by
  induction Γ generalizing ρ with
  | nil => rfl
  | cons A Γ ih =>
      simp only [Satisfies, ih fresh.2,
        interp_withFree_fresh M A name fresh.1 x]

theorem checkedReading_withFree_fresh (M : Reading V) (Γ : List AnnotatedExpr)
    (term type : AnnotatedExpr) (name : PsKernelName) (x : V)
    (freshΓ : FreshBoundContext name Γ)
    (freshTerm : Fresh name term) (freshType : Fresh name type)
    (checked : CheckedReading M Γ term type) :
    CheckedReading (M.withFree name x) Γ term type where
  typed := by
    intro ρ hρ
    rw [interp_withFree_fresh M term name freshTerm x ρ,
      interp_withFree_fresh M type name freshType x ρ]
    exact checked.typed ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ)
  termAnnotation := by
    intro ρ hρ
    exact (annotationValid_withFree_fresh M term name freshTerm x ρ).mpr
      (checked.termAnnotation ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ))
  typeAnnotation := by
    intro ρ hρ
    exact (annotationValid_withFree_fresh M type name freshType x ρ).mpr
      (checked.typeAnnotation ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ))
  termFunction := by
    intro ρ hρ
    exact (functionValid_withFree_fresh M term name freshTerm x ρ).mpr
      (checked.termFunction ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ))
  typeFunction := by
    intro ρ hρ
    exact (functionValid_withFree_fresh M type name freshType x ρ).mpr
      (checked.typeFunction ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ))

theorem modelsLocalContext_withFree_fresh (M : Reading V) (Γ : List AnnotatedExpr)
    (locals : AnnotatedLocalContext) (name : PsKernelName) (x : V)
    (freshΓ : FreshBoundContext name Γ) (freshLocals : FreshLocalContext name locals)
    (model : ModelsLocalContext M Γ locals) :
    ModelsLocalContext (M.withFree name x) Γ locals := by
  intro query decl found
  have old := model query decl found
  have fresh := freshLocals query decl found
  refine {
    member := ?_
    typeAnnotation := ?_
    typeFunction := ?_
    letValue := ?_
  }
  · intro ρ hρ
    have freeValue : (M.withFree name x).freeVars query = M.freeVars query := by
      simp only [Reading.withFree, fresh.queryFresh, Bool.false_eq_true, ite_false]
    rw [freeValue, interp_withFree_fresh M (psKernelLocalDeclType decl)
      name fresh.typeFresh x ρ]
    exact old.member ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ)
  · intro ρ hρ
    exact (annotationValid_withFree_fresh M (psKernelLocalDeclType decl)
      name fresh.typeFresh x ρ).mpr
      (old.typeAnnotation ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ))
  · intro ρ hρ
    exact (functionValid_withFree_fresh M (psKernelLocalDeclType decl)
      name fresh.typeFresh x ρ).mpr
      (old.typeFunction ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ))
  · intro value stored
    obtain ⟨checked, equal⟩ := old.letValue value stored
    refine ⟨checkedReading_withFree_fresh M Γ value (psKernelLocalDeclType decl)
      name x freshΓ (fresh.valueFresh value stored) fresh.typeFresh checked, ?_⟩
    intro ρ hρ
    rw [interp_withFree_fresh M (.fvar query) name fresh.queryFresh x ρ,
      interp_withFree_fresh M value name (fresh.valueFresh value stored) x ρ]
    exact equal ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ)

/-- General insertion into the exact shared local-context implementation. -/
theorem modelsLocalContext_addLocal (M : Reading V) (Γ : List AnnotatedExpr)
    (locals : AnnotatedLocalContext) (name userName : PsKernelName)
    (A : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (model : ModelsLocalContext M Γ locals)
    (member : ∀ ρ, Satisfies M Γ ρ → M.freeVars name ∈ˢ interp M ρ A)
    (annotation : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ A)
    (function : ∀ ρ, Satisfies M Γ ρ → FunctionValid M ρ A) :
    ModelsLocalContext M Γ (psKernelLocalContextAddLocal locals name userName A bi) := by
  intro query decl found
  by_cases hMatches : psKernelNameEq name query = true
  · have same : name = query :=
      psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 name query hMatches
    subst query
    have selected :
        PsKernelLocalDeclOf.localDecl locals.nextIndex name userName A bi = decl := by
      simpa only [psKernelLocalContextAddLocal, psKernelLocalContextFind,
        psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches, ite_true,
        Option.some.injEq] using found
    subst decl
    exact {
      member := member
      typeAnnotation := annotation
      typeFunction := function
      letValue := by intro value stored; cases stored
    }
  · have oldFound : psKernelLocalContextFind locals query = some decl := by
      simpa only [psKernelLocalContextAddLocal, psKernelLocalContextFind,
        psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches, Bool.false_eq_true, ite_false] using found
    exact model query decl oldFound

theorem modelsLocalContext_addLet (M : Reading V) (Γ : List AnnotatedExpr)
    (locals : AnnotatedLocalContext) (name userName : PsKernelName)
    (A value : AnnotatedExpr) (model : ModelsLocalContext M Γ locals)
    (checked : CheckedReading M Γ value A)
    (valueEq : ModelsEqual M Γ (.fvar name) value) :
    ModelsLocalContext M Γ (psKernelLocalContextAddLet locals name userName A value) := by
  intro query decl found
  by_cases hMatches : psKernelNameEq name query = true
  · have same : name = query :=
      psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 name query hMatches
    subst query
    have selected :
        PsKernelLocalDeclOf.letDecl locals.nextIndex name userName A value = decl := by
      simpa only [psKernelLocalContextAddLet, psKernelLocalContextFind,
        psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches, ite_true,
        Option.some.injEq] using found
    subst decl
    refine {
      member := ?_
      typeAnnotation := checked.typeAnnotation
      typeFunction := checked.typeFunction
      letValue := ?_
    }
    · intro ρ hρ
      change interp M ρ (.fvar name) ∈ˢ interp M ρ A
      rw [valueEq ρ hρ]
      exact checked.typed ρ hρ
    · intro stored storedEq
      have selectedValue : value = stored := Option.some.inj storedEq
      subst stored
      exact ⟨checked, valueEq⟩
  · have oldFound : psKernelLocalContextFind locals query = some decl := by
      simpa only [psKernelLocalContextAddLet, psKernelLocalContextFind,
        psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches, Bool.false_eq_true, ite_false] using found
    exact model query decl oldFound

private theorem withFree_self (M : Reading V) (name : PsKernelName) (x : V) :
    (M.withFree name x).freeVars name = x := by
  have same : psKernelNameEq name name = true :=
    psKernelNameEq_refl_of_string_law (fun s => by simp [psKernelStringEq]) name
  simp only [Reading.withFree, same, ite_true]

/-- A scoped runtime domain is independent of the unused bound valuation.
The actual chosen value therefore supplies the membership required by insertion.
The selected annotation and the stored domain are unchanged. -/
theorem modelsLocalContext_addLocal_fresh (M : Reading V) (Γ : List AnnotatedExpr)
    (locals : AnnotatedLocalContext) (name userName : PsKernelName)
    (A U : AnnotatedExpr) (bi : PsKernelBinderInfo) (ρ₀ : Nat → V) (x : V)
    (freshΓ : FreshBoundContext name Γ) (freshLocals : FreshLocalContext name locals)
    (freshA : Fresh name A) (scopedA : A.Scoped 0)
    (model : ModelsLocalContext M Γ locals) (domain : CheckedReading M Γ A U)
    (member : x ∈ˢ interp M ρ₀ A) :
    ModelsLocalContext (M.withFree name x) Γ
      (psKernelLocalContextAddLocal locals name userName A bi) := by
  apply modelsLocalContext_addLocal (M.withFree name x) Γ locals name userName A bi
    (modelsLocalContext_withFree_fresh M Γ locals name x freshΓ freshLocals model)
  · intro ρ _
    rw [withFree_self M name x, interp_withFree_fresh M A name freshA x ρ,
      interp_closed M A scopedA ρ ρ₀]
    exact member
  · intro ρ hρ
    exact (annotationValid_withFree_fresh M A name freshA x ρ).mpr
      (domain.termAnnotation ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ))
  · intro ρ hρ
    exact (functionValid_withFree_fresh M A name freshA x ρ).mpr
      (domain.termFunction ρ ((satisfies_withFree_fresh M Γ name freshΓ x ρ).mp hρ))

/-- A checked, scoped let value determines the new free-variable assignment;
no extra value-typing or value-equality premise is supplied by the caller. -/
theorem modelsLocalContext_addLet_fresh (M : Reading V) (Γ : List AnnotatedExpr)
    (locals : AnnotatedLocalContext) (name userName : PsKernelName)
    (A value : AnnotatedExpr) (ρ₀ : Nat → V)
    (freshΓ : FreshBoundContext name Γ) (freshLocals : FreshLocalContext name locals)
    (freshA : Fresh name A) (freshValue : Fresh name value) (scopedValue : value.Scoped 0)
    (model : ModelsLocalContext M Γ locals) (checked : CheckedReading M Γ value A) :
    ModelsLocalContext (M.withFree name (interp M ρ₀ value)) Γ
      (psKernelLocalContextAddLet locals name userName A value) := by
  apply modelsLocalContext_addLet (M.withFree name (interp M ρ₀ value)) Γ locals
    name userName A value
    (modelsLocalContext_withFree_fresh M Γ locals name (interp M ρ₀ value)
      freshΓ freshLocals model)
    (checkedReading_withFree_fresh M Γ value A name (interp M ρ₀ value)
      freshΓ freshValue freshA checked)
  intro ρ _
  change (M.withFree name (interp M ρ₀ value)).freeVars name =
    interp (M.withFree name (interp M ρ₀ value)) ρ value
  rw [withFree_self M name (interp M ρ₀ value),
    interp_withFree_fresh M value name freshValue (interp M ρ₀ value) ρ,
    interp_closed M value scopedValue ρ ρ₀]

/-- Syntactic freshness for a later scope is preserved by actual insertion. -/
theorem freshLocalContext_addLocal (future : PsKernelName)
    (locals : AnnotatedLocalContext) (name userName : PsKernelName)
    (A : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (freshLocals : FreshLocalContext future locals)
    (freshName : psKernelNameEq name future = false) (freshA : Fresh future A) :
    FreshLocalContext future (psKernelLocalContextAddLocal locals name userName A bi) := by
  intro query decl found
  by_cases hMatches : psKernelNameEq name query = true
  · have same : name = query :=
      psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 name query hMatches
    subst query
    have selected :
        PsKernelLocalDeclOf.localDecl locals.nextIndex name userName A bi = decl := by
      simpa only [psKernelLocalContextAddLocal, psKernelLocalContextFind,
        psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches, ite_true,
        Option.some.injEq] using found
    subst decl
    exact ⟨freshName, freshA, by intro value stored; cases stored⟩
  · apply freshLocals query decl
    simpa only [psKernelLocalContextAddLocal, psKernelLocalContextFind,
      psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches, Bool.false_eq_true, ite_false] using found

theorem freshLocalContext_addLet (future : PsKernelName)
    (locals : AnnotatedLocalContext) (name userName : PsKernelName)
    (A value : AnnotatedExpr) (freshLocals : FreshLocalContext future locals)
    (freshName : psKernelNameEq name future = false)
    (freshA : Fresh future A) (freshValue : Fresh future value) :
    FreshLocalContext future (psKernelLocalContextAddLet locals name userName A value) := by
  intro query decl found
  by_cases hMatches : psKernelNameEq name query = true
  · have same : name = query :=
      psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 name query hMatches
    subst query
    have selected :
        PsKernelLocalDeclOf.letDecl locals.nextIndex name userName A value = decl := by
      simpa only [psKernelLocalContextAddLet, psKernelLocalContextFind,
        psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches, ite_true,
        Option.some.injEq] using found
    subst decl
    refine ⟨freshName, freshA, ?_⟩
    intro stored storedEq
    have selectedValue : value = stored := Option.some.inj storedEq
    subst stored
    exact freshValue
  · apply freshLocals query decl
    simpa only [psKernelLocalContextAddLet, psKernelLocalContextFind,
      psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches, Bool.false_eq_true, ite_false] using found

end PsKernelSemantics.SetModel
