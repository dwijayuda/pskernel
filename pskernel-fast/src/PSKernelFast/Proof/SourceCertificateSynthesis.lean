import PSKernelFast.Proof.SourceCertificateCoherence

/-!
P1q: executable construction of the EXISTING SourceModelTyping certificates.

No source annotations, model values, semantic fibre premises or externally
constructed certificates are accepted by the closed entry point. It first
runs the unchanged G4.3b checker, synthesizes the source certificate, then
certifies the inferred TYPE and checks annotation agreement. The returned
proof fields are in Prop and erased. The retained annotations are real data;
this research evidence generator is NOT a claimed low-cost production path.

Fuel bounds recursive certificate-search depth (including searches on the
body TYPE), not CPU, allocations or the original checker's structural work.
A failure is unresolved or exhausted, not an assertion of Lean ill-typing.
This does NOT show completeness for every old G4.3b success. There is no
constant/declaration admission, no new typing rule, and no model computation
in the executable generator. Conditional model soundness applies to EVERY
successful call of the NEW certified closed entry point.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core PSKernelFast.Spec
universe u

inductive ModelCertificateError where
  | malformed
  | unresolved
  | fuelExhausted
  deriving Repr, BEq, DecidableEq

/-- Retained syntax plus a proof of exactly the pre-existing source relation. -/
structure SynthesizedModel (params : List KName) (ρ : KName → Nat)
    (ctx : List KExpr) (ac : List AnnotatedModelTerm) (source : KExpr) where
  sourceType : KExpr
  termAnnotation : AnnotatedModelTerm
  typeAnnotation : AnnotatedModelTerm
  certificate : SourceModelTyping params ρ ctx ac source sourceType
    termAnnotation typeAnnotation

private structure SynthesizedSort (params : List KName) (ρ : KName → Nat)
    (ctx : List KExpr) (ac : List AnnotatedModelTerm) (source : KExpr) where
  level : ULevel
  annotation : AnnotatedModelTerm
  certificate : SourceModelTyping params ρ ctx ac source (.sort level)
    annotation (.sort (level.denote ρ))

/-- Require BOTH actual Sort shape and the canonical annotation of that Sort. -/
private def readSortCertificate
    {params : List KName} {ρ : KName → Nat}
    {ctx : List KExpr} {ac : List AnnotatedModelTerm} {source : KExpr}
    (candidate : SynthesizedModel params ρ ctx ac source) :
    Except ModelCertificateError (SynthesizedSort params ρ ctx ac source) :=
  match hs : candidate.sourceType with
  | .sort level =>
      if ha : candidate.typeAnnotation = .sort (level.denote ρ) then
        .ok {
          level := level
          annotation := candidate.termAnnotation
          certificate := by simpa only [hs, ha] using candidate.certificate
        }
      else .error .unresolved
  | _ => .error .unresolved

/--
Application's rank is already in the function-type annotation. An ordinary
ULevel witness exists for each Nat rank; the witness is constructed ONLY in
this erased proof, never by allocating a unary level in the running search.
-/
private theorem appCertificateAtRank
    (params : List KName) (ρ : KName → Nat)
    (ctx : List KExpr) (ac : List AnnotatedModelTerm)
    (fn arg : KExpr) (name : KName) (domain body : KExpr) (style : BinderStyle)
    (rank : Nat) (af aa ad ab : AnnotatedModelTerm)
    (hf : SourceModelTyping params ρ ctx ac fn (.forallE name domain body style)
      af (.pi rank ad ab))
    (ha : SourceModelTyping params ρ ctx ac arg domain aa ad) :
    SourceModelTyping params ρ ctx ac (.app fn arg)
      (body.instantiateBVar arg 0) (.app af aa) (ab.instantiate aa 0) := by
  have representable : ∃ level : ULevel, level.denote ρ = rank := by
    clear hf
    induction rank with
    | zero => exact ⟨.zero, rfl⟩
    | succ n ih =>
        obtain ⟨level, hLevel⟩ := ih
        refine ⟨.succ level, ?_⟩
        change level.denote ρ + 1 = n + 1
        rw [hLevel]
  obtain ⟨level, hLevel⟩ := representable
  exact .app ctx ac fn arg name domain body style level af aa ad ab
    (by simpa only [hLevel] using hf) ha

/--
Construct certificates over source syntax. Extra body-type recursion is
fuel-indexed rather than an unjustified structural recursion assertion.
The caller of this low-level routine is responsible for context validity;
certifyClosedModel below supplies EMPTY contexts, never caller metadata.
-/
def synthesizeSourceCertificate (params : List KName) (ρ : KName → Nat) :
    (fuel : Nat) → (ctx : List KExpr) → (ac : List AnnotatedModelTerm) →
    (source : KExpr) →
    Except ModelCertificateError (SynthesizedModel params ρ ctx ac source)
  | 0, _, _, _ => .error .fuelExhausted
  | _ + 1, ctx, ac, .sort level =>
      if good : level.validParams params = true then
        .ok {
          sourceType := .sort (.succ level)
          termAnnotation := .sort (level.denote ρ)
          typeAnnotation := .sort (level.denote ρ + 1)
          certificate := .sort ctx ac level (ULevel.validParams_sound params level good)
        }
      else .error .unresolved
  | _ + 1, ctx, ac, .bvar index =>
      match found : ctx[index]? with
      | none => .error .unresolved
      | some domain =>
          match foundAnn : ac[index]? with
          | none => .error .unresolved
          | some ad =>
              if he : eraseExpr ρ domain = some ad.forget then
                .ok {
                  sourceType := domain.liftBVars (index + 1) 0
                  termAnnotation := .bvar index
                  typeAnnotation := ad.lift (index + 1) 0
                  certificate := .bound ctx ac index domain ad found foundAnn he
                }
              else .error .unresolved
  | fuel + 1, ctx, ac, .forallE name domain body style => do
      let domainRaw ← synthesizeSourceCertificate params ρ fuel ctx ac domain
      let d ← readSortCertificate domainRaw
      let bodyRaw ← synthesizeSourceCertificate params ρ fuel
        (domain :: ctx) (d.annotation :: ac) body
      let b ← readSortCertificate bodyRaw
      return {
        sourceType := .sort (.imax d.level b.level)
        termAnnotation := .pi (b.level.denote ρ) d.annotation b.annotation
        typeAnnotation := .sort ((ULevel.imax d.level b.level).denote ρ)
        certificate := .pi ctx ac name domain body style d.level b.level
          d.annotation b.annotation d.certificate b.certificate
      }
  | fuel + 1, ctx, ac, .lam name domain body style => do
      let domainRaw ← synthesizeSourceCertificate params ρ fuel ctx ac domain
      let d ← readSortCertificate domainRaw
      let b ← synthesizeSourceCertificate params ρ fuel
        (domain :: ctx) (d.annotation :: ac) body
      let typeRaw ← synthesizeSourceCertificate params ρ fuel
        (domain :: ctx) (d.annotation :: ac) b.sourceType
      let t ← readSortCertificate typeRaw
      if sameAnnotation : t.annotation = b.typeAnnotation then
        return {
          sourceType := .forallE name domain b.sourceType style
          termAnnotation := .lam (t.level.denote ρ) d.annotation b.termAnnotation
          typeAnnotation := .pi (t.level.denote ρ) d.annotation b.typeAnnotation
          certificate := .lam ctx ac name domain body b.sourceType style
            d.level t.level d.annotation b.termAnnotation b.typeAnnotation
            d.certificate
            (by simpa only [sameAnnotation] using t.certificate)
            b.certificate
        }
      else .error .unresolved
  | fuel + 1, ctx, ac, .app fn arg => do
      let f ← synthesizeSourceCertificate params ρ fuel ctx ac fn
      match hType : f.sourceType with
      | .forallE name domain body style =>
          match hAnn : f.typeAnnotation with
          | .pi rank ad ab =>
              let a ← synthesizeSourceCertificate params ρ fuel ctx ac arg
              if sourceMatch : a.sourceType = domain then
                if annotationMatch : a.typeAnnotation = ad then
                  return {
                    sourceType := body.instantiateBVar arg 0
                    termAnnotation := .app f.termAnnotation a.termAnnotation
                    typeAnnotation := ab.instantiate a.termAnnotation 0
                    certificate := appCertificateAtRank params ρ ctx ac fn arg
                      name domain body style rank f.termAnnotation a.termAnnotation ad ab
                      (by simpa only [hType, hAnn] using f.certificate)
                      (by simpa only [sourceMatch, annotationMatch] using a.certificate)
                  }
                else .error .unresolved
              else .error .unresolved
          | _ => .error .unresolved
      | _ => .error .unresolved
  | fuel + 1, ctx, ac, .letE name declared value body false => do
      let domainRaw ← synthesizeSourceCertificate params ρ fuel ctx ac declared
      let d ← readSortCertificate domainRaw
      let v ← synthesizeSourceCertificate params ρ fuel ctx ac value
      if sourceMatch : v.sourceType = declared then
        if annotationMatch : v.typeAnnotation = d.annotation then
          let b ← synthesizeSourceCertificate params ρ fuel
            (declared :: ctx) (d.annotation :: ac) body
          return {
            sourceType := b.sourceType.instantiateBVar value 0
            termAnnotation := .letE d.annotation v.termAnnotation b.termAnnotation
            typeAnnotation := b.typeAnnotation.instantiate v.termAnnotation 0
            certificate := .letE ctx ac name declared value body b.sourceType
              d.level d.annotation v.termAnnotation b.termAnnotation b.typeAnnotation
              d.certificate
              (by simpa only [sourceMatch, annotationMatch] using v.certificate)
              b.certificate
          }
        else .error .unresolved
      else .error .unresolved
  | _ + 1, _, _, _ => .error .unresolved

/-- A real source success plus constructed term AND inferred-type certificates. -/
structure ClosedModelCertificate (params : List KName) (ρ : KName → Nat)
    (source : KExpr) where
  typing : SynthesizedModel params ρ [] [] source
  inferred : inferClosedGeneralPi params source = .ok typing.sourceType
  typeLevel : ULevel
  typeCertificate : SourceModelTyping params ρ [] [] typing.sourceType (.sort typeLevel)
    typing.typeAnnotation (.sort (typeLevel.denote ρ))

/--
No supplied certificate or annotation. The unchanged raw checker must succeed,
and then both syntax-directed certificate searches must agree. Zero fuel
returns before source inference; this bounds search depth, NOT total work.
No result here inserts a declaration into any environment.
-/
def certifyClosedModel (params : List KName) (ρ : KName → Nat)
    (source : KExpr) : (fuel : Nat) →
    Except ModelCertificateError (ClosedModelCertificate params ρ source)
  | 0 => .error .fuelExhausted
  | fuel + 1 =>
      match hRun : inferClosedGeneralPi params source with
      | .error .malformed => .error .malformed
      | .error _ => .error .unresolved
      | .ok inferred => do
          let term ← synthesizeSourceCertificate params ρ (fuel + 1) [] [] source
          if sameType : term.sourceType = inferred then
            let typeRaw ← synthesizeSourceCertificate params ρ (fuel + 1) [] [] term.sourceType
            let typeSort ← readSortCertificate typeRaw
            if sameAnn : typeSort.annotation = term.typeAnnotation then
              return {
                typing := term
                inferred := by simpa only [sameType] using hRun
                typeLevel := typeSort.level
                typeCertificate := by simpa only [sameAnn] using typeSort.certificate
              }
            else .error .unresolved
          else .error .unresolved

/-- Every successful search, at any fuel, uses the SAME structural annotations. -/
theorem synthesizedModel_unique
    {params : List KName} {ρ : KName → Nat}
    {ctx : List KExpr} {ac : List AnnotatedModelTerm} {source : KExpr}
    (first second : SynthesizedModel params ρ ctx ac source) :
    first.sourceType = second.sourceType ∧
    first.termAnnotation = second.termAnnotation ∧
    first.typeAnnotation = second.typeAnnotation := by
  exact ⟨generalPiRule_type_unique
    (sourceModelTyping_typed params ρ first.certificate)
    (sourceModelTyping_typed params ρ second.certificate),
    sourceModelTyping_annotations_unique params ρ first.certificate second.certificate⟩

/--
ACTUAL closed-entry-point soundness. The caller supplies only an execution
success, not SourceModelTyping/semantic-fibre/stepSound premises. All model
claims still require [SetTheoryBasis V]. The older raw checker alone is NOT
claimed complete or semantically sound by this wrapper theorem.
-/
theorem certifyClosedModel_sound (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat) (source : KExpr) (fuel : Nat)
    (result : ClosedModelCertificate params ρ source)
    (_success : certifyClosedModel params ρ source fuel = .ok result)
    (env : Nat → V) :
    inferClosedGeneralPi params source = .ok result.typing.sourceType ∧
    eraseExpr ρ source = some result.typing.termAnnotation.forget ∧
    eraseExpr ρ result.typing.sourceType = some result.typing.typeAnnotation.forget ∧
    SetTheoryBasis.member (interpAnnotated V env result.typing.termAnnotation)
      (interpAnnotated V env result.typing.typeAnnotation) := by
  have hErase := sourceModelTyping_erases params ρ result.typing.certificate
  exact ⟨result.inferred, hErase.1, hErase.2,
    sourceModelTyping_sound V params ρ result.typing.certificate env
      (AnnotatedContextValid.empty V env)⟩

private theorem falseTypeCertificate (params : List KName) (ρ : KName → Nat)
    (name : KName) :
    SourceModelTyping params ρ [] [] (forallPropPropSource name)
      (.sort (.imax (.succ .zero) .zero))
      (.pi 0 (.sort 0) (.bvar 0)) (.sort 0) := by
  exact .pi [] [] name (.sort .zero) (.bvar 0) .default
    (.succ .zero) .zero (.sort 0) (.bvar 0)
    (.sort [] [] .zero trivial)
    (.bound [(.sort .zero)] [(.sort 0)] 0 (.sort .zero) (.sort 0) rfl rfl rfl)

/--
Relative no-inhabitant result for EVERY successful NEW certified closed run.
No canonical annotation equality is assumed: inferred-type certification
and the general coherence theorem derive it. This is not whole-Lean/native
False/declaration consistency, nor proof of existence of SetTheoryBasis.
-/
theorem certifyClosedModel_no_false (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat) (source : KExpr) (fuel : Nat)
    (result : ClosedModelCertificate params ρ source)
    (_success : certifyClosedModel params ρ source fuel = .ok result)
    (name : KName) :
    result.typing.sourceType ≠ forallPropPropSource name := by
  intro hType
  have hTypeCert : SourceModelTyping params ρ [] [] (forallPropPropSource name)
      (.sort result.typeLevel) result.typing.typeAnnotation
      (.sort (result.typeLevel.denote ρ)) := by
    simpa only [hType] using result.typeCertificate
  have hCanonical := (sourceModelTyping_annotations_unique params ρ
    hTypeCert (falseTypeCertificate params ρ name)).1
  have hTerm : SourceModelTyping params ρ [] [] source (forallPropPropSource name)
      result.typing.termAnnotation (.pi 0 (.sort 0) (.bvar 0)) := by
    simpa only [hType, hCanonical] using result.typing.certificate
  exact sourceModelTyping_no_false V params ρ name source result.typing.termAnnotation hTerm

theorem certifyClosedModel_zero (params : List KName) (ρ : KName → Nat)
    (source : KExpr) :
    certifyClosedModel params ρ source 0 = .error .fuelExhausted := rfl

#print axioms synthesizedModel_unique
#print axioms certifyClosedModel_sound
#print axioms certifyClosedModel_no_false
#print axioms certifyClosedModel_zero

end PSKernelFast.Proof
