import Ps.KernelCore.Metatheory.SemanticCheckedReading
import Ps.KernelCore.Metatheory.SemanticValidityScope
import Ps.KernelCore.Metatheory.SemanticScope

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


/-!
An executable-context frame invariant independent of semantic valuations.
Every *selected* stored declaration has a bounded numeric name, bounded
annotated type/value, and no loose bound variables. The lookup-only form
matches the checker and the semantic model: shadowed entries cannot be selected.
This is the syntactic binder-entry slice; preserving the frame across arbitrary
recursive checker callbacks is still an outstanding graded invariant.
-/

def NameBelow (limit : Nat) : PsKernelName → Prop
  | .num _ index => index < limit
  | _ => True

theorem nameBelow_mono (name : PsKernelName) {n m : Nat}
    (h : NameBelow n name) (hn : n ≤ m) : NameBelow m name := by
  cases name with
  | anonymous | str _ _ => trivial
  | num _ i => exact Nat.lt_of_lt_of_le h hn

theorem nameBelow_fresh (name : PsKernelName) (limit : Nat)
    (h : NameBelow limit name) (base : PsKernelName) :
    psKernelNameEq name (.num base limit) = false := by
  cases he : psKernelNameEq name (.num base limit) with
  | false => rfl
  | true =>
      have same : name = .num base limit :=
        psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435
          name (.num base limit) he
      subst name
      change limit < limit at h
      exact False.elim (Nat.lt_irrefl _ h)

/-- The semantic bound context cannot mention the next
numeric identity allocated by the checker. -/
def BoundFrame (limit : Nat) (Γ : List AnnotatedExpr) : Prop :=
  ∀ A, A ∈ Γ → NamesBelow limit A

theorem boundFrame_empty (limit : Nat) : BoundFrame limit [] := by
  intro A h
  cases h

theorem boundFrame_mono (limit next : Nat) (Γ : List AnnotatedExpr)
    (frame : BoundFrame limit Γ) (le : limit ≤ next) :
    BoundFrame next Γ := by
  intro A h
  exact namesBelow_mono A (frame A h) le

theorem boundFrame_fresh (limit : Nat) (Γ : List AnnotatedExpr)
    (base : PsKernelName) (frame : BoundFrame limit Γ) :
    FreshBoundContext (.num base limit) Γ := by
  induction Γ with
  | nil => trivial
  | cons A Γ ih =>
      refine ⟨namesBelow_fresh A limit (frame A (by simp)) base, ?_⟩
      apply ih
      intro B hB
      exact frame B (by simp [hB])

/-- A frame fact is stored about the actual first lookup result, not merely
some expression with the same erasure. -/
structure LocalDeclFrame (limit : Nat) (query : PsKernelName)
    (decl : AnnotatedLocalDecl) : Prop where
  queryBelow : NameBelow limit query
  typeBelow : NamesBelow limit (psKernelLocalDeclType decl)
  typeScoped : (psKernelLocalDeclType decl).Scoped 0
  valueBelow : ∀ value, psKernelLocalDeclValue decl = some value →
    NamesBelow limit value
  valueScoped : ∀ value, psKernelLocalDeclValue decl = some value →
    value.Scoped 0

def LocalFrame (limit : Nat) (locals : AnnotatedLocalContext) : Prop :=
  ∀ query decl, psKernelLocalContextFind locals query = some decl →
    LocalDeclFrame limit query decl

theorem localFrame_empty (limit : Nat) :
    LocalFrame limit annotatedLocalContextEmpty := by
  intro query decl found
  simp [annotatedLocalContextEmpty, psKernelLocalContextEmptyOf,
    psKernelLocalContextFind, psKernelLocalContextFindIn] at found

theorem localFrame_mono (limit next : Nat) (locals : AnnotatedLocalContext)
    (frame : LocalFrame limit locals) (le : limit ≤ next) :
    LocalFrame next locals := by
  intro query decl found
  have old := frame query decl found
  exact {
    queryBelow := nameBelow_mono query old.queryBelow le
    typeBelow := namesBelow_mono _ old.typeBelow le
    typeScoped := old.typeScoped
    valueBelow := fun value stored =>
      namesBelow_mono value (old.valueBelow value stored) le
    valueScoped := old.valueScoped
  }

theorem localFrame_fresh (limit : Nat) (locals : AnnotatedLocalContext)
    (base : PsKernelName) (frame : LocalFrame limit locals) :
    FreshLocalContext (.num base limit) locals := by
  intro query decl found
  have entry := frame query decl found
  exact {
    queryFresh := nameBelow_fresh query limit entry.queryBelow base
    typeFresh := namesBelow_fresh _ limit entry.typeBelow base
    valueFresh := fun value stored =>
      namesBelow_fresh value limit (entry.valueBelow value stored) base
  }

/-- The shared production local insertion retains the frame at the advanced
allocator counter; both scope and name bounds are explicit input invariants. -/
theorem localFrame_addLocal (limit : Nat)
    (locals : AnnotatedLocalContext) (base userName : PsKernelName)
    (A : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (frame : LocalFrame limit locals)
    (boundedA : NamesBelow limit A) (scopedA : A.Scoped 0) :
    LocalFrame (limit + 1)
      (psKernelLocalContextAddLocal locals (.num base limit) userName A bi) := by
  intro query decl found
  by_cases hMatches : psKernelNameEq (.num base limit) query = true
  · have same : (.num base limit : PsKernelName) = query :=
      psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435
        (.num base limit) query hMatches
    subst query
    have selected :
        PsKernelLocalDeclOf.localDecl locals.nextIndex (.num base limit)
          userName A bi = decl := by
      simpa only [psKernelLocalContextAddLocal, psKernelLocalContextFind,
        psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches, ite_true,
        Option.some.injEq] using found
    subst decl
    refine {
      queryBelow := ?_
      typeBelow := namesBelow_mono A boundedA (Nat.le_succ _)
      typeScoped := scopedA
      valueBelow := ?_
      valueScoped := ?_
    }
    · change limit < limit + 1
      omega
    · intro value stored
      cases stored
    · intro value stored
      cases stored
  · have oldFound : psKernelLocalContextFind locals query = some decl := by
      simpa only [psKernelLocalContextAddLocal, psKernelLocalContextFind,
        psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches,
        Bool.false_eq_true, ite_false] using found
    exact (localFrame_mono limit (limit + 1) locals frame
      (Nat.le_succ _)) query decl oldFound

/-- A let insertion also retains the checked value's exact syntactic frame. -/
theorem localFrame_addLet (limit : Nat)
    (locals : AnnotatedLocalContext) (base userName : PsKernelName)
    (A value : AnnotatedExpr)
    (frame : LocalFrame limit locals)
    (boundedA : NamesBelow limit A) (scopedA : A.Scoped 0)
    (boundedValue : NamesBelow limit value) (scopedValue : value.Scoped 0) :
    LocalFrame (limit + 1)
      (psKernelLocalContextAddLet locals (.num base limit) userName A value) := by
  intro query decl found
  by_cases hMatches : psKernelNameEq (.num base limit) query = true
  · have same : (.num base limit : PsKernelName) = query :=
      psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435
        (.num base limit) query hMatches
    subst query
    have selected :
        PsKernelLocalDeclOf.letDecl locals.nextIndex (.num base limit)
          userName A value = decl := by
      simpa only [psKernelLocalContextAddLet, psKernelLocalContextFind,
        psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches, ite_true,
        Option.some.injEq] using found
    subst decl
    refine {
      queryBelow := ?_
      typeBelow := namesBelow_mono A boundedA (Nat.le_succ _)
      typeScoped := scopedA
      valueBelow := ?_
      valueScoped := ?_
    }
    · change limit < limit + 1
      omega
    · intro stored foundValue
      have sameValue : value = stored := Option.some.inj foundValue
      subst stored
      exact namesBelow_mono value boundedValue (Nat.le_succ _)
    · intro stored foundValue
      have sameValue : value = stored := Option.some.inj foundValue
      subst stored
      exact scopedValue
  · have oldFound : psKernelLocalContextFind locals query = some decl := by
      simpa only [psKernelLocalContextAddLet, psKernelLocalContextFind,
        psKernelLocalContextFindIn, psKernelLocalDeclName, hMatches,
        Bool.false_eq_true, ite_false] using found
    exact (localFrame_mono limit (limit + 1) locals frame
      (Nat.le_succ _)) query decl oldFound

/-- Exiting a binder restores its parent locals. The production state exit
keeps a monotone counter, so no restored declaration becomes newly forgeable. -/
theorem localFrame_exitLocalScope
    (parent child : PsKernelCheckerState)
    (locals : AnnotatedLocalContext)
    (frame : LocalFrame parent.nextFresh locals) :
    LocalFrame (psKernelCheckerStateExitLocalScope parent child).nextFresh locals := by
  change LocalFrame (Nat.max parent.nextFresh child.nextFresh) locals
  exact localFrame_mono parent.nextFresh
    (Nat.max parent.nextFresh child.nextFresh) locals frame
    (Nat.le_max_left _ _)

end PsKernelSemantics.SetModel
