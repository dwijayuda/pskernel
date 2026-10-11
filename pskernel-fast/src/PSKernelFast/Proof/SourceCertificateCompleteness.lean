import PSKernelFast.Proof.SourceCertificateSynthesis

/-!
P1t: certificate-search COMPLETENESS relative to the declared source relation.

For every SourceModelTyping derivation, there is a finite search-depth bound
such that EVERY larger fuel returns exactly its source type and structural
annotations. This is a proof about the actual synthesis algorithm, not a
finite generated test corpus. Proof irrelevance identifies only certificate
fields, never annotations or universe ranks.

Important boundary: this quantifies over SourceModelTyping, not every raw
GeneralPiRule/old checker success. Closing that older coverage gap still
requires source regularity and typed weakening/substitution arguments.
No model, semantic membership or consistency assumption appears here.
-/

namespace PSKernelFast.Proof
open PSKernelFast.Core PSKernelFast.Spec

private theorem validParams_complete (params : List KName)
    (level : ULevel) (h : ULevel.WellFormed params level) :
    level.validParams params = true := by
  induction level with
  | zero => rfl
  | succ level ih => exact ih h
  | max a b iha ihb =>
      simp only [ULevel.validParams, iha h.1, ihb h.2, Bool.and_self]
  | imax a b iha ihb =>
      simp only [ULevel.validParams, iha h.1, ihb h.2, Bool.and_self]
  | param name =>
      simpa only [ULevel.validParams, ULevel.WellFormed, decide_eq_true_eq] using h
  | mvar name => exact False.elim h

/-- Every certified source has an eventual, fuel-stable successful synthesis. -/
theorem synthesizeSourceCertificate_complete
    (params : List KName) (ρ : KName → Nat)
    {ctx : List KExpr} {ac : List AnnotatedModelTerm}
    {source ty : KExpr} {ann aTy : AnnotatedModelTerm}
    (h : SourceModelTyping params ρ ctx ac source ty ann aTy) :
    ∃ required : Nat, ∀ fuel : Nat, required ≤ fuel →
      synthesizeSourceCertificate params ρ fuel ctx ac source =
        .ok ⟨ty, ann, aTy, h⟩ := by
  induction h with
  | sort ctx ac level good =>
      refine ⟨1, ?_⟩
      intro fuel enough
      cases fuel with
      | zero => omega
      | succ fuel =>
          simp [synthesizeSourceCertificate, validParams_complete params level good]
  | bound ctx ac index domain ad found foundAnn erases =>
      refine ⟨1, ?_⟩
      intro fuel enough
      cases fuel with
      | zero => omega
      | succ fuel =>
          simp [synthesizeSourceCertificate, found, foundAnn, erases]
  | pi ctx ac name domain body style u v ad ab hd hb ihd ihb =>
      obtain ⟨kd, runD⟩ := ihd
      obtain ⟨kb, runB⟩ := ihb
      refine ⟨max kd kb + 1, ?_⟩
      intro fuel enough
      cases fuel with
      | zero => omega
      | succ fuel =>
          have hdRun := runD fuel (by omega)
          have hbRun := runB fuel (by omega)
          simp! [synthesizeSourceCertificate, hdRun, hbRun]
  | lam ctx ac name domain body bodyType style u v ad ab aType hd ht hb ihd iht ihb =>
      obtain ⟨kd, runD⟩ := ihd
      obtain ⟨kt, runT⟩ := iht
      obtain ⟨kb, runB⟩ := ihb
      refine ⟨max kd (max kt kb) + 1, ?_⟩
      intro fuel enough
      cases fuel with
      | zero => omega
      | succ fuel =>
          have hdRun := runD fuel (by omega)
          have htRun := runT fuel (by omega)
          have hbRun := runB fuel (by omega)
          simp! [synthesizeSourceCertificate, hdRun, htRun, hbRun]
  | app ctx ac fn arg name domain body style v af aa ad ab hf ha ihf iha =>
      obtain ⟨kf, runF⟩ := ihf
      obtain ⟨ka, runA⟩ := iha
      refine ⟨max kf ka + 1, ?_⟩
      intro fuel enough
      cases fuel with
      | zero => omega
      | succ fuel =>
          have hfRun := runF fuel (by omega)
          have haRun := runA fuel (by omega)
          simp! [synthesizeSourceCertificate, hfRun, haRun]
  | letE ctx ac name declared value body bodyType level ad av ab aType hd hv hb ihd ihv ihb =>
      obtain ⟨kd, runD⟩ := ihd
      obtain ⟨kv, runV⟩ := ihv
      obtain ⟨kb, runB⟩ := ihb
      refine ⟨max kd (max kv kb) + 1, ?_⟩
      intro fuel enough
      cases fuel with
      | zero => omega
      | succ fuel =>
          have hdRun := runD fuel (by omega)
          have hvRun := runV fuel (by omega)
          have hbRun := runB fuel (by omega)
          simp! [synthesizeSourceCertificate, hdRun, hvRun, hbRun]

#print axioms synthesizeSourceCertificate_complete

end PSKernelFast.Proof
