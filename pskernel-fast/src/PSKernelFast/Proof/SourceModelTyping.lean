import PSKernelFast.Proof.SourceSubstitutionModel

/-!
P1o: source-only certificates for ALL SIX supported term constructors.

SourceModelTyping contains source terms/types, their annotations, universe
valuations and binder lookup equations. It contains NO model values,
semantic-fibre assumptions, or assumed denotation-preservation laws.
The semantic typing theorem is derived by induction, using P1n's actual
substitution correspondence and dependent semantic-context invariant.

This is a PROOF-SIDE supported-source relation, not a new accepting kernel.
Existence/coherence of these certificates for EVERY G4.3b success and
preservation through arbitrary runtime reduction are NOT yet established.
Lambda additionally certifies the sort of its body TYPE, fixing the actual
Prop/Type annotation. GeneralPiRule itself does not demand that certificate.
All model conclusions require the unchanged supplied SetTheoryBasis V.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec
universe u

/-- Exact inferred type is unique even for the raw six-rule relation. -/
theorem generalPiRule_type_unique
    {params : List KName} {ctx : List KExpr} {expr first second : KExpr}
    (h : GeneralPiRule params ctx expr first)
    (other : GeneralPiRule params ctx expr second) : first = second := by
  induction h generalizing second with
  | sort ctx level good => cases other; rfl
  | bound ctx index domain found =>
      cases other with
      | bound _ _ next foundNext =>
          have hd : domain = next := Option.some.inj (found.symm.trans foundNext)
          cases hd
          rfl
  | pi ctx name domain body style a b hd hb ihd ihb =>
      cases other with
      | pi _ _ _ _ _ a' b' hd' hb' =>
          have ha := ihd hd'
          have hb := ihb hb'
          injection ha with ea
          injection hb with eb
          cases ea
          cases eb
          rfl
  | lam ctx name domain body style a bodyType hd hb ihd ihb =>
      cases other with
      | lam _ _ _ _ _ a' bodyType' hd' hb' =>
          have ht := ihb hb'
          cases ht
          rfl
  | app ctx fn arg name domain body style hf ha ihf iha =>
      cases other with
      | app _ _ _ name' domain' body' style' hf' ha' =>
          have ht := ihf hf'
          injection ht with hn hd hb hs
          cases hn
          cases hd
          cases hb
          cases hs
          rfl
  | letE ctx name declared value body flag hFlag level bodyType ht hv hb iht ihv ihb =>
      cases other with
      | letE _ _ _ _ _ _ _ level' bodyType' ht' hv' hb' =>
          have hSame := ihb hb'
          cases hSame
          rfl

/-- Source typing plus coherent structural annotations; no semantic premises. -/
inductive SourceModelTyping (params : List KName) (ρ : KName → Nat) :
    List KExpr → List AnnotatedModelTerm →
    KExpr → KExpr → AnnotatedModelTerm → AnnotatedModelTerm → Prop where
  | sort (ctx : List KExpr) (ac : List AnnotatedModelTerm) (level : ULevel)
      (good : ULevel.WellFormed params level) :
      SourceModelTyping params ρ ctx ac (.sort level) (.sort (.succ level))
        (.sort (level.denote ρ)) (.sort (level.denote ρ + 1))
  | bound (ctx : List KExpr) (ac : List AnnotatedModelTerm)
      (index : Nat) (domain : KExpr) (ad : AnnotatedModelTerm)
      (found : ctx[index]? = some domain)
      (foundAnn : ac[index]? = some ad)
      (erases : eraseExpr ρ domain = some ad.forget) :
      SourceModelTyping params ρ ctx ac (.bvar index)
        (domain.liftBVars (index + 1) 0) (.bvar index) (ad.lift (index + 1) 0)
  | pi (ctx : List KExpr) (ac : List AnnotatedModelTerm) (name : KName)
      (domain body : KExpr) (style : BinderStyle) (a b : ULevel)
      (ad ab : AnnotatedModelTerm)
      (domainTyped : SourceModelTyping params ρ ctx ac domain (.sort a)
        ad (.sort (a.denote ρ)))
      (bodyTyped : SourceModelTyping params ρ (domain :: ctx) (ad :: ac)
        body (.sort b) ab (.sort (b.denote ρ))) :
      SourceModelTyping params ρ ctx ac (.forallE name domain body style)
        (.sort (.imax a b)) (.pi (b.denote ρ) ad ab)
        (.sort ((ULevel.imax a b).denote ρ))
  | lam (ctx : List KExpr) (ac : List AnnotatedModelTerm) (name : KName)
      (domain body bodyType : KExpr) (style : BinderStyle) (a b : ULevel)
      (ad ab aType : AnnotatedModelTerm)
      (domainTyped : SourceModelTyping params ρ ctx ac domain (.sort a)
        ad (.sort (a.denote ρ)))
      (bodyTypeTyped : SourceModelTyping params ρ (domain :: ctx) (ad :: ac)
        bodyType (.sort b) aType (.sort (b.denote ρ)))
      (bodyTyped : SourceModelTyping params ρ (domain :: ctx) (ad :: ac)
        body bodyType ab aType) :
      SourceModelTyping params ρ ctx ac (.lam name domain body style)
        (.forallE name domain bodyType style)
        (.lam (b.denote ρ) ad ab) (.pi (b.denote ρ) ad aType)
  | app (ctx : List KExpr) (ac : List AnnotatedModelTerm)
      (fn arg : KExpr) (name : KName) (domain body : KExpr)
      (style : BinderStyle) (b : ULevel) (af aa ad ab : AnnotatedModelTerm)
      (fnTyped : SourceModelTyping params ρ ctx ac fn
        (.forallE name domain body style) af (.pi (b.denote ρ) ad ab))
      (argTyped : SourceModelTyping params ρ ctx ac arg domain aa ad) :
      SourceModelTyping params ρ ctx ac (.app fn arg)
        (body.instantiateBVar arg 0) (.app af aa) (ab.instantiate aa 0)
  | letE (ctx : List KExpr) (ac : List AnnotatedModelTerm) (name : KName)
      (declared value body bodyType : KExpr) (level : ULevel)
      (ad av ab aType : AnnotatedModelTerm)
      (declaredTyped : SourceModelTyping params ρ ctx ac declared (.sort level)
        ad (.sort (level.denote ρ)))
      (valueTyped : SourceModelTyping params ρ ctx ac value declared av ad)
      (bodyTyped : SourceModelTyping params ρ (declared :: ctx) (ad :: ac)
        body bodyType ab aType) :
      SourceModelTyping params ρ ctx ac (.letE name declared value body false)
        (bodyType.instantiateBVar value 0) (.letE ad av ab) (aType.instantiate av 0)

/-- Every certificate reconstructs the EXISTING source checker judgment. -/
theorem sourceModelTyping_typed (params : List KName) (ρ : KName → Nat) :
    ∀ {ctx ac expr type ann aType},
      SourceModelTyping params ρ ctx ac expr type ann aType →
      GeneralPiRule params ctx expr type := by
  intro ctx ac expr type ann aType h
  induction h with
  | sort ctx ac level good => exact .sort ctx level good
  | bound ctx ac i d ad found foundAnn erases => exact .bound ctx i d found
  | pi ctx ac name d b style u v ad ab hd hb ihd ihb =>
      exact .pi ctx name d b style u v ihd ihb
  | lam ctx ac name d b type style u v ad ab at hd ht hb ihd iht ihb =>
      exact .lam ctx name d b style u type ihd ihb
  | app ctx ac fn arg name d b style v af aa ad ab hf ha ihf iha =>
      exact .app ctx fn arg name d b style ihf iha
  | letE ctx ac name d value b type level ad av ab at hd hv hb ihd ihv ihb =>
      exact .letE ctx name d value b false rfl level type ihd ihv ihb

private theorem erasePi_parts (ρ : KName → Nat)
    (name : KName) (domain body : KExpr) (style : BinderStyle)
    (ad ab : ErasedExpr)
    (h : eraseExpr ρ (.forallE name domain body style) = some (.pi ad ab)) :
    eraseExpr ρ domain = some ad ∧ eraseExpr ρ body = some ab := by
  cases hd : eraseExpr ρ domain with
  | none => simp [eraseExpr, hd] at h
  | some d =>
      cases hb : eraseExpr ρ body with
      | none => simp [eraseExpr, hd, hb] at h
      | some b =>
          have heq : ErasedExpr.pi d b = .pi ad ab := by
            simpa [eraseExpr, hd, hb] using h
          injection heq with ed eb
          cases ed
          cases eb
          exact ⟨hd, hb⟩

/-- Both source TERM and source TYPE erase to their certified annotations. -/
theorem sourceModelTyping_erases (params : List KName) (ρ : KName → Nat) :
    ∀ {ctx ac expr type ann aType},
      SourceModelTyping params ρ ctx ac expr type ann aType →
      eraseExpr ρ expr = some ann.forget ∧ eraseExpr ρ type = some aType.forget := by
  intro ctx ac expr type ann aType h
  induction h with
  | sort ctx ac level good => exact ⟨rfl, rfl⟩
  | bound ctx ac i d ad found foundAnn erases =>
      exact ⟨rfl, source_annotated_lift ρ d ad (i + 1) 0 erases⟩
  | pi ctx ac name d b style u v ad ab hd hb ihd ihb =>
      refine ⟨?_, rfl⟩
      simp [eraseExpr, AnnotatedModelTerm.forget, ihd.1, ihb.1]
  | lam ctx ac name d b type style u v ad ab at hd ht hb ihd iht ihb =>
      constructor
      · simp [eraseExpr, AnnotatedModelTerm.forget, ihd.1, ihb.1]
      · simp [eraseExpr, AnnotatedModelTerm.forget, ihd.1, ihb.2]
  | app ctx ac fn arg name d b style v af aa ad ab hf ha ihf iha =>
      constructor
      · simp [eraseExpr, AnnotatedModelTerm.forget, ihf.1, iha.1]
      · have hParts := erasePi_parts ρ name d b style ad.forget ab.forget ihf.2
        exact source_annotated_instantiate ρ b arg ab aa 0 hParts.2 iha.1
  | letE ctx ac name d value b type level ad av ab at hd hv hb ihd ihv ihb =>
      constructor
      · simp [eraseExpr, AnnotatedModelTerm.forget, ihd.1, ihv.1, ihb.1]
      · exact source_annotated_instantiate ρ type value at av 0 ihb.2 ihv.1

/--
MAIN semantic typing induction. All Pi fibres, lambda body membership,
application validity and let substitution are DERIVED from source-only
certificates, under a valid dependent semantic context. No stepSound or
all-fibres-valid assumption is supplied to this theorem.
-/
theorem sourceModelTyping_sound (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat) :
    ∀ {ctx ac expr type ann aType},
      SourceModelTyping params ρ ctx ac expr type ann aType →
      ∀ env : Nat → V, AnnotatedContextValid V ac env →
        SetTheoryBasis.member (interpAnnotated V env ann) (interpAnnotated V env aType) := by
  intro ctx ac expr type ann aType h
  induction h with
  | sort ctx ac level good =>
      intro env hCtx
      exact taggedSort_nat_member_succ V (level.denote ρ)
  | bound ctx ac i d ad found foundAnn erases =>
      intro env hCtx
      change SetTheoryBasis.member (env i) (interpAnnotated V env (ad.lift (i + 1) 0))
      rw [interpAnnotated_lift]
      have he : pullLiftEnv (i + 1) 0 env = dropModelEnv (i + 1) env := by
        funext j
        simp [pullLiftEnv, dropModelEnv]
      rw [he]
      exact hCtx i ad foundAnn
  | pi ctx ac name d b style u v ad ab hd hb ihd ihb =>
      intro env hCtx
      exact modelPi_member_sort V (u.denote ρ) (v.denote ρ)
        (interpAnnotated V env ad)
        (fun x => interpAnnotated V (extendSetEnv x env) ab)
        (ihd env hCtx)
        (fun x hx => ihb (extendSetEnv x env)
          (AnnotatedContextValid.extend V ac env ad x hCtx hx))
  | lam ctx ac name d b type style u v ad ab at hd ht hb ihd iht ihb =>
      intro env hCtx
      exact modelLam_intro V (v.denote ρ) (interpAnnotated V env ad)
        (fun x => interpAnnotated V (extendSetEnv x env) at)
        (fun x => interpAnnotated V (extendSetEnv x env) ab)
        (fun x hx => iht (extendSetEnv x env)
          (AnnotatedContextValid.extend V ac env ad x hCtx hx))
        (fun x hx => ihb (extendSetEnv x env)
          (AnnotatedContextValid.extend V ac env ad x hCtx hx))
  | app ctx ac fn arg name d b style v af aa ad ab hf ha ihf iha =>
      intro env hCtx
      change SetTheoryBasis.member
        (modelApp V (interpAnnotated V env af) (interpAnnotated V env aa))
        (interpAnnotated V env (ab.instantiate aa 0))
      rw [interpAnnotated_instantiate_zero]
      exact modelPi_elim V (v.denote ρ) (interpAnnotated V env ad)
        (fun x => interpAnnotated V (extendSetEnv x env) ab)
        (interpAnnotated V env af) (interpAnnotated V env aa)
        (ihf env hCtx) (iha env hCtx)
  | letE ctx ac name d value b type level ad av ab at hd hv hb ihd ihv ihb =>
      intro env hCtx
      change SetTheoryBasis.member
        (interpAnnotated V (extendSetEnv (interpAnnotated V env av) env) ab)
        (interpAnnotated V env (at.instantiate av 0))
      rw [interpAnnotated_instantiate_zero]
      exact ihb (extendSetEnv (interpAnnotated V env av) env)
        (AnnotatedContextValid.extend V ac env ad (interpAnnotated V env av)
          hCtx (ihv env hCtx))

/-- The ACTUAL checker output is the certified type, not a caller's rank hint. -/
theorem sourceModelTyping_executed (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat) (source result type : KExpr)
    (ann aType : AnnotatedModelTerm) (env : Nat → V)
    (hRun : inferClosedGeneralPi params source = .ok result)
    (h : SourceModelTyping params ρ [] [] source type ann aType) :
    result = type ∧ eraseExpr ρ source = some ann.forget ∧
      eraseExpr ρ result = some aType.forget ∧
      SetTheoryBasis.member (interpAnnotated V env ann) (interpAnnotated V env aType) := by
  have hActual := (inferClosedGeneralPi_sound params source result hRun).2
  have hExpected := sourceModelTyping_typed params ρ h
  have hSame : result = type := generalPiRule_type_unique hActual hExpected
  have hErased := sourceModelTyping_erases params ρ h
  refine ⟨hSame, hErased.1, ?_, sourceModelTyping_sound V params ρ h env
    (AnnotatedContextValid.empty V env)⟩
  simpa only [hSame] using hErased.2

/-- Source beta: semantic premises are NOW derived from source certificates. -/
theorem sourceModelTyping_beta (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat) (ctx : List KExpr)
    (ac : List AnnotatedModelTerm) (env : Nat → V)
    (name : KName) (style : BinderStyle) (domain body bodyType arg : KExpr)
    (u v : ULevel) (ad ab at aa : AnnotatedModelTerm)
    (hd : SourceModelTyping params ρ ctx ac domain (.sort u) ad (.sort (u.denote ρ)))
    (ht : SourceModelTyping params ρ (domain :: ctx) (ad :: ac)
      bodyType (.sort v) at (.sort (v.denote ρ)))
    (hb : SourceModelTyping params ρ (domain :: ctx) (ad :: ac) body bodyType ab at)
    (ha : SourceModelTyping params ρ ctx ac arg domain aa ad)
    (hCtx : AnnotatedContextValid V ac env) :
    WeakHeadStep (.app (.lam name domain body style) arg) (body.instantiateBVar arg 0) ∧
    eraseExpr ρ (.app (.lam name domain body style) arg) =
      some (AnnotatedModelTerm.app (.lam (v.denote ρ) ad ab) aa).forget ∧
    eraseExpr ρ (body.instantiateBVar arg 0) = some (ab.instantiate aa 0).forget ∧
    interpAnnotated V env (.app (.lam (v.denote ρ) ad ab) aa) =
      interpAnnotated V env (ab.instantiate aa 0) := by
  exact source_annotated_beta V ρ env name style domain body arg ad ab aa (v.denote ρ)
    (fun x => interpAnnotated V (extendSetEnv x env) at)
    (sourceModelTyping_erases params ρ hd).1
    (sourceModelTyping_erases params ρ hb).1
    (sourceModelTyping_erases params ρ ha).1
    (fun x hx => sourceModelTyping_sound V params ρ ht (extendSetEnv x env)
      (AnnotatedContextValid.extend V ac env ad x hCtx hx))
    (fun x hx => sourceModelTyping_sound V params ρ hb (extendSetEnv x env)
      (AnnotatedContextValid.extend V ac env ad x hCtx hx))
    (sourceModelTyping_sound V params ρ ha env hCtx)

/--
Conditional no-inhabitant theorem for this SOURCE-CERTIFIED six-form fragment.
This is NOT the full kernel consistency capstone: certificate synthesis for
all accepted terms, reduction coherence, declarations and model existence
remain open. The empty proposition here is the literal forall P:Prop, P.
-/
theorem sourceModelTyping_no_false (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat) (name : KName)
    (source : KExpr) (ann : AnnotatedModelTerm)
    (h : SourceModelTyping params ρ [] [] source (forallPropPropSource name)
      ann (.pi 0 (.sort 0) (.bvar 0))) : False := by
  let env : Nat → V := fun _ => SetTheoryBasis.emptySet V
  have hm := sourceModelTyping_sound V params ρ h env
    (AnnotatedContextValid.empty V env)
  have hFalse : interpAnnotated V env (.pi 0 (.sort 0) (.bvar 0)) =
      SetTheoryBasis.emptySet V :=
    tagged_forallPropProp_is_false V env
  rw [hFalse] at hm
  exact SetTheoryBasis.not_member_empty V (interpAnnotated V env ann) hm

/-- Nonvacuous generic certificate, including proof variables x:P at rank zero. -/
theorem polyIdentity_sourceModelTyping (params : List KName) (ρ : KName → Nat)
    (level : ULevel) (good : ULevel.WellFormed params level) :
    SourceModelTyping params ρ [] [] (polyIdentitySource level) (polyIdentitySourceType level)
      (polyIdentityAnnotation (level.denote ρ)) (polyIdentityTypeAnnotation (level.denote ρ)) := by
  let rank := level.denote ρ
  have hd : SourceModelTyping params ρ [] [] (.sort level) (.sort (.succ level))
      (.sort rank) (.sort (rank + 1)) := .sort [] [] level good
  have hA : SourceModelTyping params ρ [(.sort level)] [(.sort rank)]
      (.bvar 0) (.sort level) (.bvar 0) (.sort rank) :=
    .bound [(.sort level)] [(.sort rank)] 0 (.sort level) (.sort rank) rfl rfl rfl
  have hOuter : SourceModelTyping params ρ [(.bvar 0), (.sort level)]
      [(.bvar 0), (.sort rank)] (.bvar 1) (.sort level) (.bvar 1) (.sort rank) :=
    .bound [(.bvar 0), (.sort level)] [(.bvar 0), (.sort rank)]
      1 (.sort level) (.sort rank) rfl rfl rfl
  have hX : SourceModelTyping params ρ [(.bvar 0), (.sort level)]
      [(.bvar 0), (.sort rank)] (.bvar 0) (.bvar 1) (.bvar 0) (.bvar 1) :=
    .bound [(.bvar 0), (.sort level)] [(.bvar 0), (.sort rank)]
      0 (.bvar 0) (.bvar 0) rfl rfl rfl
  have hPi := SourceModelTyping.pi [(.sort level)] [(.sort rank)]
    (.str .anonymous "x") (.bvar 0) (.bvar 1) .default level level
    (.bvar 0) (.bvar 1) hA hOuter
  have hInner := SourceModelTyping.lam [(.sort level)] [(.sort rank)]
    (.str .anonymous "x") (.bvar 0) (.bvar 0) (.bvar 1) .default level level
    (.bvar 0) (.bvar 0) (.bvar 1) hA hOuter hX
  have hWhole := SourceModelTyping.lam [] [] (.str .anonymous "A") (.sort level)
    (.lam (.str .anonymous "x") (.bvar 0) (.bvar 0) .default)
    (.forallE (.str .anonymous "x") (.bvar 0) (.bvar 1) .default)
    .default (.succ level) (.imax level level) (.sort rank)
    (.lam rank (.bvar 0) (.bvar 0)) (.pi rank (.bvar 0) (.bvar 1)) hd hPi hInner
  have hRank : (ULevel.imax level level).denote ρ = rank := by
    change numericImax rank rank = rank
    cases rank <;> simp [numericImax]
  simpa only [hRank, polyIdentitySource, polyIdentitySourceType,
    polyIdentityAnnotation, polyIdentityTypeAnnotation] using hWhole

#print axioms generalPiRule_type_unique
#print axioms sourceModelTyping_typed
#print axioms sourceModelTyping_erases
#print axioms sourceModelTyping_sound
#print axioms sourceModelTyping_executed
#print axioms sourceModelTyping_beta
#print axioms sourceModelTyping_no_false
#print axioms polyIdentity_sourceModelTyping

end PSKernelFast.Proof
