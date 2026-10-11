import PSKernelFast.Proof.PropInterpreterBridge

/-!
P1e: proof-only CHECKED PROP-BINDER ANNOTATION relation.

Unlike an annotation supplied by an untrusted frontend, every annotated
Pi constructor carries the very same GeneralPiRule domain/codomain
premises the G4.3b checker executes, plus evidence that its CODOMAIN
sort denotes Prop under the *chosen* universe valuation.

This intentionally describes a proper SUBSET of the existing G4.3b
fragment: Sort, bound variables and semantically Prop-valued Pi.
Lambdas, apps, lets, and Pi whose codomain is Type-valued are NOT
annotated. Results do not authorize proof admission.

This is only a source-to-semantics annotation gate. The fibre
WellDenoted/semantic validity of arbitrary checked terms remains OPEN.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec

universe u

/--
Judgment-backed annotations: the Pi Prop-regime decision CANNOT be
invented from syntax or an arbitrary level valuation. Its domain and
codomain must actually be certified by the G4.3b declarative rules.
The recursive annotated domain/body must faithfully represent those
same source subterms and contexts. Unlike the prototype runtime,
this proof-only relation never changes the accepting checker.
-/
inductive CheckedPropAnnotation (params : List KName)
    (ρ : KName → Nat) : List KExpr → KExpr → PropInterpTerm → Prop where
  | sort (ctx : List KExpr) (level : ULevel)
      (good : ULevel.WellFormed params level) :
      CheckedPropAnnotation params ρ ctx
        (.sort level) (.sort (level.denote ρ))
  | bvar (ctx : List KExpr) (index : Nat) (domain : KExpr)
      (found : ctx[index]? = some domain) :
      CheckedPropAnnotation params ρ ctx
        (.bvar index) (.bvar index)
  | pi (ctx : List KExpr) (name : KName)
      (domain body : KExpr) (style : BinderStyle)
      (domainSort codomainSort : ULevel)
      (annotatedDomain annotatedBody : PropInterpTerm)
      (domainTyped :
        GeneralPiRule params ctx domain (.sort domainSort))
      (bodyTyped :
        GeneralPiRule params (domain :: ctx) body (.sort codomainSort))
      (codomainProp : codomainSort.denote ρ = 0)
      (domainAnnotated :
        CheckedPropAnnotation params ρ ctx domain annotatedDomain)
      (bodyAnnotated :
        CheckedPropAnnotation params ρ (domain :: ctx) body annotatedBody) :
      CheckedPropAnnotation params ρ ctx
        (.forallE name domain body style)
        (.propPi annotatedDomain annotatedBody)

/--
Independently confirm that every judgment-backed semantic annotation
forgets EXACTLY to the existing universe-grounded erasure of its
original source syntax. This is a structural proof over the annotation,
not over a user-supplied untyped metadata claim.
-/
theorem checkedPropAnnotation_erases (params : List KName)
    (ρ : KName → Nat) :
    ∀ {ctx expr annotation},
      CheckedPropAnnotation params ρ ctx expr annotation →
      eraseExpr ρ expr = some annotation.forget := by
  intro ctx expr annotation h
  induction h with
  | sort ctx level good => rfl
  | bvar ctx index domain found => rfl
  | pi ctx name domain body style u v annDom annBody
      hDomain hBody hProp hAnnDom hAnnBody ihDom ihBody =>
      simp [eraseExpr, PropInterpTerm.forget, ihDom, ihBody]

/--
The annotation syntax carries an ACTUAL G4.3b typing rule derivation.
The syntax-to-judgment direction does not rely on a forged frontend
annotation, a new axiom, or a cached unchecked reduction result.
-/
theorem checkedPropAnnotation_typed (params : List KName)
    (ρ : KName → Nat) :
    ∀ {ctx expr annotation},
      CheckedPropAnnotation params ρ ctx expr annotation →
      ∃ type, GeneralPiRule params ctx expr type := by
  intro ctx expr annotation h
  cases h with
  | sort ctx level good =>
      exact ⟨.sort (.succ level), .sort ctx level good⟩
  | bvar ctx index domain found =>
      exact ⟨domain.liftBVars (index + 1) 0,
        .bound ctx index domain found⟩
  | pi ctx name domain body style u v annDom annBody
      hDomain hBody hProp hAnnDom hAnnBody =>
      exact ⟨.sort (.imax u v),
        .pi ctx name domain body style u v hDomain hBody⟩

/--
GENERAL CHECKED PROP-PI MODEL MEMBERSHIP, but with an EXPLICIT and
not-yet-automatically-derived semantic fibre-validity premise.

The typed source Pi, its checked CODOMAIN Prop regime, and the matching
semantic term follow from the source-certified annotation. Given
well-denoted semantic fibres, the Pi denotation belongs to the model
of its actual inferred Sort(imax u v) at the chosen valuation.

This is NOT a theorem that every G4.3b-accepted Pi automatically
has WellDenoted body fibres, nor a proof of arbitrary source typing.
-/
theorem checkedPropAnnotation_pi_model_member
    (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat)
    (ctx : List KExpr) (name : KName)
    (domain body : KExpr) (style : BinderStyle)
    (annotatedDomain annotatedBody : PropInterpTerm)
    (hAnn : CheckedPropAnnotation params ρ ctx
      (.forallE name domain body style)
      (.propPi annotatedDomain annotatedBody))
    (env : Nat → V)
    (hValid : PropPiFibresValid V env
      annotatedDomain annotatedBody) :
    ∃ domainSort codomainSort : ULevel,
      GeneralPiRule params ctx (.forallE name domain body style)
        (.sort (.imax domainSort codomainSort)) ∧
      ((ULevel.imax domainSort codomainSort).denote ρ = 0) ∧
      SetTheoryBasis.Mem
        (interpProp V env (.propPi annotatedDomain annotatedBody))
        (sortSet V ((ULevel.imax domainSort codomainSort).denote ρ)) := by
  cases hAnn with
  | pi ctx name domain body style u v annDom annBody
      hDomain hBody hProp hAnnDom hAnnBody =>
      have hResultProp :
          ((ULevel.imax u v).denote ρ = 0) :=
        (piLevel_isProp_iff_codomain_isProp ρ u v).2 hProp
      refine ⟨u, v, .pi ctx name domain body style u v
        hDomain hBody, hResultProp, ?_⟩
      simpa only [hResultProp] using
        (interpProp_pi_member V env annDom annBody hValid)

#print axioms checkedPropAnnotation_erases
#print axioms checkedPropAnnotation_typed
#print axioms checkedPropAnnotation_pi_model_member

end PSKernelFast.Proof
