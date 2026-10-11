import PSKernelFast.Proof.TaggedWellDenoted

/-!
P1i: SOURCE-CONSTRAINED CONTEXT / TAGGED MODEL BRIDGE (proof-only).

Conservative accepting-direction semantics: only a source-checked Sort,
a variable whose actual source context binder domain IS a Sort, and a
source-checked proposition-valued Pi may enter this subfragment.

Critically, a bound proof x : P is NOT confused with a bound proposition
P : Prop. Source bvars with non-Sort domain are deliberately outside this
fragment. This is necessary: the tagged distinguished proof point is not
itself an element of the Prop universe.

The semantic context is tied to the actual SOURCE binder declarations,
not an arbitrary annotation of the environment or a trusted plugin.
Every inference certificate is from GeneralPiRule, the exact executable
G4.3b source relation. Source ranks are verified against source rules
and the selected universe valuation. No admission or runtime imports.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec

universe u

/--
For each source binder whose declared domain is syntactically Sort u,
the corresponding model value must lie in exactly the tagged Sort u
denotation. Other (proof-valued or general Type-valued) binders have no
unjustified interpretation imposed by this partial contract.
-/
def TaggedSortContextValid (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (ctx : List KExpr) (env : Nat → V) : Prop :=
  ∀ (i : Nat) (level : ULevel),
    ctx[i]? = some (.sort level) →
      SetTheoryBasis.member (env i) (taggedSortSet V (level.denote ρ))

/-- Closed syntax has no model variable obligations. -/
theorem taggedSortContextValid_empty (V : Type u)
    [SetTheoryBasis V] (ρ : KName → Nat) (env : Nat → V) :
    TaggedSortContextValid V ρ [] env := by
  intro i level hFound
  simp [TaggedSortContextValid] at hFound

/-- A checked syntactic Sort necessarily has the corresponding annotation. -/
theorem checkedPropAnnotation_sort_exact
    (params : List KName) (ρ : KName → Nat) (ctx : List KExpr)
    (level : ULevel) (ann : PropInterpTerm)
    (h : CheckedPropAnnotation params ρ ctx (.sort level) ann) :
    ann = .sort (level.denote ρ) := by
  cases h
  rfl

/--
Extending an ACTUAL checked source binder preserves source-to-model context
validity for all Sort binders, because the semantic binder argument was
proved a member of the annotated domain. This does NOT assign any
unsupported sort rank to a proof variable of type P.
-/
theorem taggedSortContextValid_extend (V : Type u)
    [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat)
    (ctx : List KExpr) (env : Nat → V)
    (domain : KExpr) (annDomain : PropInterpTerm)
    (hCtx : TaggedSortContextValid V ρ ctx env)
    (hAnn : CheckedPropAnnotation params ρ ctx domain annDomain)
    (x : V)
    (hx : SetTheoryBasis.member x
      (interpTaggedProp V env annDomain)) :
    TaggedSortContextValid V ρ (domain :: ctx)
      (extendSetEnv x env) := by
  intro i level hFound
  cases i with
  | zero =>
      have hSource : domain = .sort level := by
        simpa using hFound
      have hAnnSort : annDomain = .sort (level.denote ρ) := by
        cases hSource
        exact checkedPropAnnotation_sort_exact params ρ ctx level annDomain hAnn
      have hVal : SetTheoryBasis.member x
          (taggedSortSet V (level.denote ρ)) := by
        simpa only [hAnnSort, interpTaggedProp] using hx
      simpa only [extendSetEnv] using hVal
  | succ j =>
      have hTail : ctx[j]? = some (.sort level) := by
        simpa using hFound
      simpa only [extendSetEnv] using hCtx j level hTail

/--
A TYPED source/semantic bridge, more restrictive than generic
CheckedPropAnnotation: each used bound variable MUST originate from a
source Sort-domain binder, so it denotes a Type/Prop element rather
than an unchecked proof value. The proposition-Pi case has actual
GeneralPiRule certificates for both domain and body and a VERIFIED
codomain-Prop numerical regime. No new kernel acceptance constructors.
-/
inductive SourceRankedTagged (params : List KName)
    (ρ : KName → Nat) :
    List KExpr → KExpr → PropInterpTerm → Nat → Prop where
  | sort (ctx : List KExpr) (level : ULevel)
      (good : ULevel.WellFormed params level) :
      SourceRankedTagged params ρ ctx
        (.sort level) (.sort (level.denote ρ)) (level.denote ρ + 1)
  | bvar (ctx : List KExpr) (index : Nat) (level : ULevel)
      (found : ctx[index]? = some (.sort level)) :
      SourceRankedTagged params ρ ctx
        (.bvar index) (.bvar index) (level.denote ρ)
  | pi (ctx : List KExpr) (name : KName)
      (domain body : KExpr) (style : BinderStyle)
      (domainSort bodySort : ULevel)
      (annDomain annBody : PropInterpTerm)
      (domainTyped :
        GeneralPiRule params ctx domain (.sort domainSort))
      (bodyTyped :
        GeneralPiRule params (domain :: ctx) body (.sort bodySort))
      (bodyProp : bodySort.denote ρ = 0)
      (domainSupported :
        SourceRankedTagged params ρ ctx domain annDomain
          (domainSort.denote ρ))
      (bodySupported :
        SourceRankedTagged params ρ (domain :: ctx) body annBody 0) :
      SourceRankedTagged params ρ ctx
        (.forallE name domain body style)
        (.propPi annDomain annBody) 0

/--
No frontend can forge a new source typing rule: the restricted predicate
ALWAYS reconstructs an existing recursively checked G4.3b annotation.
-/
theorem sourceRankedTagged_checked (params : List KName)
    (ρ : KName → Nat) :
    ∀ {ctx expr ann rank},
      SourceRankedTagged params ρ ctx expr ann rank →
        CheckedPropAnnotation params ρ ctx expr ann := by
  intro ctx expr ann rank h
  induction h with
  | sort ctx level good =>
      exact .sort ctx level good
  | bvar ctx index level found =>
      exact .bvar ctx index (.sort level) found
  | pi ctx name domain body style u v annDom annBody
      hDomain hBody hProp hDomSupported hBodySupported ihDom ihBody =>
      exact .pi ctx name domain body style u v annDom annBody
        hDomain hBody hProp ihDom ihBody

/--
The KEY P1i theorem: prove model membership by induction on actually
source-checked syntax and source-validated semantic environments. Pi
fibres follow recursively from binder extension and the model induction,
NOT from postulated 'all fibres valid' premises.
-/
theorem sourceRankedTagged_wellDenoted
    (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat) :
    ∀ {ctx expr ann rank},
      SourceRankedTagged params ρ ctx expr ann rank →
        ∀ env : Nat → V,
          TaggedSortContextValid V ρ ctx env →
            TaggedWellDenoted V env ann rank := by
  intro ctx expr ann rank h
  induction h with
  | sort ctx level good =>
      intro env hCtx
      exact .sort env (level.denote ρ)
  | bvar ctx index level found =>
      intro env hCtx
      exact .bvar env index (level.denote ρ) (hCtx index level found)
  | pi ctx name domain body style u v annDom annBody
      hDomain hBody hProp hDomSupported hBodySupported ihDom ihBody =>
      intro env hCtx
      refine .propPi env annDom annBody (u.denote ρ) (ihDom env hCtx) ?_
      intro x hx
      have hAnnDom : CheckedPropAnnotation params ρ ctx domain annDom :=
        sourceRankedTagged_checked params ρ hDomSupported
      exact ihBody (extendSetEnv x env)
        (taggedSortContextValid_extend V params ρ ctx env
          domain annDom hCtx hAnnDom x hx)

/-- General source-certified fragment gives independent semantic membership. -/
theorem sourceRankedTagged_model_member
    (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat)
    {ctx : List KExpr} {expr : KExpr}
    {ann : PropInterpTerm} {rank : Nat}
    (hSupported : SourceRankedTagged params ρ ctx expr ann rank)
    (env : Nat → V) (hCtx : TaggedSortContextValid V ρ ctx env) :
    SetTheoryBasis.member
      (interpTaggedProp V env ann) (taggedSortSet V rank) :=
  taggedWellDenoted_sound V
    (sourceRankedTagged_wellDenoted V params ρ hSupported env hCtx)

/--
A REAL EXECUTING G4.3b closed success, if its syntax is in the certified
restricted fragment, has an independently validated source typing rule,
exact checked erasure, and hereditary TAGGED model membership. The
semantic rank comes from SourceRankedTagged; this does NOT yet identify
every arbitrary inferred type with the model rank.
-/
theorem sourceRankedTagged_executed_closed
    (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat)
    (env : Nat → V) (expr result : KExpr)
    (ann : PropInterpTerm) (rank : Nat)
    (hRun : inferClosedGeneralPi params expr = .ok result)
    (hSupported : SourceRankedTagged params ρ [] expr ann rank) :
    GeneralPiRule params [] expr result ∧
    CheckedPropAnnotation params ρ [] expr ann ∧
    eraseExpr ρ expr = some ann.forget ∧
    SetTheoryBasis.member
      (interpTaggedProp V env ann) (taggedSortSet V rank) := by
  have hRule := (inferClosedGeneralPi_sound params expr result hRun).2
  have hAnnotation := sourceRankedTagged_checked params ρ hSupported
  have hErase := checkedPropAnnotation_erases params ρ hAnnotation
  have hModel : SetTheoryBasis.member
      (interpTaggedProp V env ann) (taggedSortSet V rank) :=
    sourceRankedTagged_model_member V params ρ hSupported env
      (taggedSortContextValid_empty V ρ env)
  exact ⟨hRule, hAnnotation, hErase, hModel⟩

/-- The first ACTUALLY accepted closed proposition is in the fragment. -/
theorem forallPropProp_sourceRanked
    (ρ : KName → Nat) (name : KName) :
    SourceRankedTagged [] ρ [] (forallPropPropSource name)
      forallPropPropTerm 0 := by
  refine .pi [] name (.sort .zero) (.bvar 0) .default
    (.succ .zero) .zero (.sort 0) (.bvar 0)
    (.sort [] .zero trivial)
    (.bound [(.sort .zero)] 0 (.sort .zero) rfl)
    rfl ?_ ?_
  · exact .sort [] .zero trivial
  · exact .bvar [(.sort .zero)] 0 .zero rfl

/-- The nested identity proposition reuses the SAME general source bridge. -/
theorem forallPropIdentity_sourceRanked
    (ρ : KName → Nat) (propName proofName : KName) :
    SourceRankedTagged [] ρ []
      (forallPropIdentitySource propName proofName)
      forallPropIdentityTerm 0 := by
  have hInnerDomain : GeneralPiRule [] [(.sort .zero)]
      (.bvar 0) (.sort .zero) :=
    .bound [(.sort .zero)] 0 (.sort .zero) rfl
  have hInnerBody : GeneralPiRule [] [(.bvar 0), (.sort .zero)]
      (.bvar 1) (.sort .zero) :=
    .bound [(.bvar 0), (.sort .zero)] 1 (.sort .zero) rfl
  have hInner : GeneralPiRule [] [(.sort .zero)]
      (.forallE proofName (.bvar 0) (.bvar 1) .default)
      (.sort (.imax .zero .zero)) :=
    .pi [(.sort .zero)] proofName (.bvar 0) (.bvar 1)
      .default .zero .zero hInnerDomain hInnerBody
  have hSupportedInner : SourceRankedTagged [] ρ [(.sort .zero)]
      (.forallE proofName (.bvar 0) (.bvar 1) .default)
      (.propPi (.bvar 0) (.bvar 1)) 0 := by
    refine .pi [(.sort .zero)] proofName (.bvar 0) (.bvar 1)
      .default .zero .zero (.bvar 0) (.bvar 1)
      hInnerDomain hInnerBody (by rfl) ?_ ?_
    · exact .bvar [(.sort .zero)] 0 .zero rfl
    · exact .bvar [(.bvar 0), (.sort .zero)] 1 .zero rfl
  refine .pi [] propName (.sort .zero)
    (.forallE proofName (.bvar 0) (.bvar 1) .default)
    .default (.succ .zero) (.imax .zero .zero)
    (.sort 0) (.propPi (.bvar 0) (.bvar 1))
    (.sort [] .zero trivial) hInner (by rfl) ?_ ?_
  · exact .sort [] .zero trivial
  · exact hSupportedInner

/-- An actual false-source run now has reusable source-env soundness. -/
theorem forallPropProp_executed_source_model
    (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V) (name : KName) :
    GeneralPiRule [] [] (forallPropPropSource name)
      forallPropPropSourceType ∧
    CheckedPropAnnotation [] ρ []
      (forallPropPropSource name) forallPropPropTerm ∧
    eraseExpr ρ (forallPropPropSource name) =
      some forallPropPropTerm.forget ∧
    SetTheoryBasis.member
      (interpTaggedProp V env forallPropPropTerm) (taggedSortSet V 0) :=
  sourceRankedTagged_executed_closed V [] ρ env
    (forallPropPropSource name) forallPropPropSourceType
    forallPropPropTerm 0 (forallPropProp_actual_inference name)
    (forallPropProp_sourceRanked ρ name)

/-- Same reusable source-env soundness for the nested true-source run. -/
theorem forallPropIdentity_executed_source_model
    (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V)
    (propName proofName : KName) :
    GeneralPiRule [] []
      (forallPropIdentitySource propName proofName)
      forallPropIdentitySourceType ∧
    CheckedPropAnnotation [] ρ []
      (forallPropIdentitySource propName proofName)
      forallPropIdentityTerm ∧
    eraseExpr ρ (forallPropIdentitySource propName proofName) =
      some forallPropIdentityTerm.forget ∧
    SetTheoryBasis.member
      (interpTaggedProp V env forallPropIdentityTerm) (taggedSortSet V 0) :=
  sourceRankedTagged_executed_closed V [] ρ env
    (forallPropIdentitySource propName proofName)
    forallPropIdentitySourceType forallPropIdentityTerm 0
    (forallPropIdentity_actual_inference propName proofName)
    (forallPropIdentity_sourceRanked ρ propName proofName)

/--
TYPE-RANK COHERENCE: every G4.3b source typing certificate for a supported
term returns an actual Sort whose interpreted level equals the model rank.
The source term fixes the relevant rank; no untrusted cast from an
annotation to an inferred type is permitted.
-/
theorem sourceRankedTagged_rule_sort_rank
    (params : List KName) (ρ : KName → Nat) :
    ∀ {ctx expr ann rank},
      SourceRankedTagged params ρ ctx expr ann rank →
        ∀ {result},
          GeneralPiRule params ctx expr result →
            ∃ level : ULevel,
              result = .sort level ∧ level.denote ρ = rank := by
  intro ctx expr ann rank h
  induction h with
  | sort ctx level good =>
      intro result hTyped
      cases hTyped
      exact ⟨.succ level, rfl, rfl⟩
  | bvar ctx index level found =>
      intro result hTyped
      cases hTyped with
      | bound _ _ domain hFound =>
          have hDomain : domain = .sort level :=
            Option.some.inj (hFound.symm.trans found)
          subst domain
          refine ⟨level, ?_, rfl⟩
          simp [KExpr.liftBVars]
  | pi ctx name domain body style u v annDom annBody
      hDomain hBody hProp hDomSupported hBodySupported ihDom ihBody =>
      intro result hTyped
      cases hTyped with
      | pi _ _ _ _ _ uOther vOther hDomOther hBodyOther =>
          obtain ⟨vRank, hBodyType, hZero⟩ := ihBody hBodyOther
          have hEq : vOther = vRank := by
            injection hBodyType with hv
            exact hv
          have hBodyZero : vOther.denote ρ = 0 := by
            simpa only [hEq] using hZero
          refine ⟨.imax uOther vOther, rfl, ?_⟩
          exact (piLevel_isProp_iff_codomain_isProp
            ρ uOther vOther).2 hBodyZero

/--
Real closed G4.3b successes in the guarded fragment now have an inferred
Sort whose exact universe level erases to the same numerical rank as the
set-model membership judgment. This joins ACTUAL inferred output to the
semantic rank; no auxiliary rank equality premise is supplied by a caller.
-/
theorem sourceRankedTagged_executed_exact_inferred_model
    (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat)
    (env : Nat → V) (expr result : KExpr)
    (ann : PropInterpTerm) (rank : Nat)
    (hRun : inferClosedGeneralPi params expr = .ok result)
    (hSupported : SourceRankedTagged params ρ [] expr ann rank) :
    ∃ level : ULevel,
      result = .sort level ∧
      level.denote ρ = rank ∧
      eraseExpr ρ result = some (.sort rank) ∧
      SetTheoryBasis.member
        (interpTaggedProp V env ann)
        (interpTaggedProp V env (.sort rank)) := by
  have hRule := (inferClosedGeneralPi_sound params expr result hRun).2
  obtain ⟨level, hType, hRank⟩ :=
    sourceRankedTagged_rule_sort_rank params ρ hSupported hRule
  have hMember : SetTheoryBasis.member
      (interpTaggedProp V env ann) (taggedSortSet V rank) :=
    sourceRankedTagged_model_member V params ρ hSupported env
      (taggedSortContextValid_empty V ρ env)
  refine ⟨level, hType, hRank, ?_, ?_⟩
  · subst result
    simp [eraseExpr, hRank]
  · simpa only [interpTaggedProp] using hMember

#print axioms taggedSortContextValid_empty
#print axioms sourceRankedTagged_rule_sort_rank
#print axioms sourceRankedTagged_executed_exact_inferred_model
#print axioms checkedPropAnnotation_sort_exact
#print axioms taggedSortContextValid_extend
#print axioms sourceRankedTagged_checked
#print axioms sourceRankedTagged_wellDenoted
#print axioms sourceRankedTagged_model_member
#print axioms sourceRankedTagged_executed_closed
#print axioms forallPropProp_sourceRanked
#print axioms forallPropIdentity_sourceRanked
#print axioms forallPropProp_executed_source_model
#print axioms forallPropIdentity_executed_source_model

end PSKernelFast.Proof
