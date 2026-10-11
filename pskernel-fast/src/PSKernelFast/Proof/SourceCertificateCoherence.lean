import PSKernelFast.Proof.SourceModelTyping

/-!
P1p: certificate coherence for the EXISTING six-form source relation.

For fixed source context, annotated context and universe valuation, any two
certificates for the same term agree on BOTH the term annotation and its
type annotation. Their source output types need not be assumed equal:
GeneralPiRule's independently proved exact type uniqueness supplies that.

This is structural annotation uniqueness, including every Prop/Type rank,
not just erasure equality or equality in a model. No model assumptions,
source regularity assumption, or semantic coherence hypothesis is added.
It does NOT yet prove that every raw checker success has a certificate,
nor typed substitution closure of SourceModelTyping.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core PSKernelFast.Spec

/-- All six constructors have a unique annotation for source and source type. -/
theorem sourceModelTyping_annotations_unique
    (params : List KName) (ρ : KName → Nat)
    {ctx : List KExpr} {ac : List AnnotatedModelTerm}
    {source ty otherTy : KExpr}
    {ann aTy otherAnn otherATy : AnnotatedModelTerm}
    (left : SourceModelTyping params ρ ctx ac source ty ann aTy)
    (right : SourceModelTyping params ρ ctx ac source otherTy otherAnn otherATy) :
    ann = otherAnn ∧ aTy = otherATy := by
  induction left generalizing otherTy otherAnn otherATy with
  | sort ctx ac level good =>
      cases right
      exact ⟨rfl, rfl⟩
  | bound ctx ac i domain ad found foundAnn erases =>
      cases right with
      | bound _ _ _ next nextAnn hNext hNextAnn hErase =>
          have ha : ad = nextAnn :=
            Option.some.inj (foundAnn.symm.trans hNextAnn)
          cases ha
          exact ⟨rfl, rfl⟩
  | pi ctx ac name domain body style u v ad ab hd hb ihd ihb =>
      cases right with
      | pi _ _ _ _ _ _ u' v' ad' ab' hd' hb' =>
          have hu : u = u' := KExpr.sort.inj
            (generalPiRule_type_unique
              (sourceModelTyping_typed params ρ hd)
              (sourceModelTyping_typed params ρ hd'))
          cases hu
          obtain ⟨hAd, _⟩ := ihd hd'
          cases hAd
          have hv : v = v' := KExpr.sort.inj
            (generalPiRule_type_unique
              (sourceModelTyping_typed params ρ hb)
              (sourceModelTyping_typed params ρ hb'))
          cases hv
          obtain ⟨hAb, _⟩ := ihb hb'
          cases hAb
          exact ⟨rfl, rfl⟩
  | lam ctx ac name domain body bodyType style u v ad ab aType
      hd ht hb ihd iht ihb =>
      cases right with
      | lam _ _ _ _ _ bodyType' _ u' v' ad' ab' aType' hd' ht' hb' =>
          obtain ⟨hAd, _⟩ := ihd hd'
          cases hAd
          have hType : bodyType = bodyType' := generalPiRule_type_unique
            (sourceModelTyping_typed params ρ hb)
            (sourceModelTyping_typed params ρ hb')
          cases hType
          have hv : v = v' := KExpr.sort.inj
            (generalPiRule_type_unique
              (sourceModelTyping_typed params ρ ht)
              (sourceModelTyping_typed params ρ ht'))
          cases hv
          obtain ⟨hATy, _⟩ := iht ht'
          cases hATy
          obtain ⟨hBody, _⟩ := ihb hb'
          cases hBody
          exact ⟨rfl, rfl⟩
  | app ctx ac fn arg name domain body style v af aa ad ab hf ha ihf iha =>
      cases right with
      | app _ _ _ _ name' domain' body' style' v' af' aa' ad' ab' hf' ha' =>
          have hType := generalPiRule_type_unique
            (sourceModelTyping_typed params ρ hf)
            (sourceModelTyping_typed params ρ hf')
          injection hType with hn hd hb hs
          cases hn
          cases hd
          cases hb
          cases hs
          obtain ⟨hFn, hFnTy⟩ := ihf hf'
          injection hFnTy with hRank hDomain hBody
          cases hDomain
          cases hBody
          cases hFn
          obtain ⟨hArg, _⟩ := iha ha'
          cases hArg
          exact ⟨rfl, rfl⟩
  | letE ctx ac name declared value body bodyType level ad av ab aType
      hd hv hb ihd ihv ihb =>
      cases right with
      | letE _ _ _ _ _ _ bodyType' level' ad' av' ab' aType' hd' hv' hb' =>
          obtain ⟨hAd, _⟩ := ihd hd'
          cases hAd
          obtain ⟨hValue, _⟩ := ihv hv'
          cases hValue
          obtain ⟨hBody, hBodyType⟩ := ihb hb'
          cases hBody
          cases hBodyType
          exact ⟨rfl, rfl⟩

#print axioms sourceModelTyping_annotations_unique

end PSKernelFast.Proof
