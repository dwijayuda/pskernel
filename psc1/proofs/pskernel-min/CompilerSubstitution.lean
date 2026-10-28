import CompilerCaller

/- An independently stated, capture-avoiding de Bruijn substitution relation.
   This is syntax refinement for all Core constructors. It does not establish
   typing preservation, classifier soundness or a complete compiler theorem. -/
namespace Ps.MinKernel.CompilerSubstitution

inductive Lift (amount : Nat) : Nat → PsExpr → PsExpr → Prop where
  | bound {index cutoff : Nat} (h : index < cutoff) :
      Lift amount cutoff (.bvar index) (.bvar index)
  | above {index cutoff : Nat} (h : cutoff ≤ index) :
      Lift amount cutoff (.bvar index) (.bvar (Nat.add index amount))
  | fvar {cutoff identifier : Nat} :
      Lift amount cutoff (.fvar identifier) (.fvar identifier)
  | mvar {cutoff identifier : Nat} :
      Lift amount cutoff (.mvar identifier) (.mvar identifier)
  | sortE {cutoff : Nat} {level : PsLevel} :
      Lift amount cutoff (.sortE level) (.sortE level)
  | constE {cutoff : Nat} {name : PsName} {levels : List PsLevel} :
      Lift amount cutoff (.constE name levels) (.constE name levels)
  | lit {cutoff : Nat} {value : PsLiteral} :
      Lift amount cutoff (.lit value) (.lit value)
  | app {cutoff : Nat} {fn fn' arg arg' : PsExpr} (hfn : Lift amount cutoff fn fn') (harg : Lift amount cutoff arg arg') :
      Lift amount cutoff (.app fn arg) (.app fn' arg')
  | lam {cutoff : Nat} {name : PsName} {type type' body body' : PsExpr} {binder : PsBinderInfo} (htype : Lift amount cutoff type type') (hbody : Lift amount (Nat.succ cutoff) body body') :
      Lift amount cutoff (.lam name type body binder) (.lam name type' body' binder)
  | forallE {cutoff : Nat} {name : PsName} {type type' body body' : PsExpr} {binder : PsBinderInfo} (htype : Lift amount cutoff type type') (hbody : Lift amount (Nat.succ cutoff) body body') :
      Lift amount cutoff (.forallE name type body binder) (.forallE name type' body' binder)
  | letE {cutoff : Nat} {name : PsName} {type type' value value' body body' : PsExpr} (htype : Lift amount cutoff type type') (hvalue : Lift amount cutoff value value') (hbody : Lift amount (Nat.succ cutoff) body body') :
      Lift amount cutoff (.letE name type value body) (.letE name type' value' body')
  | proj {cutoff : Nat} {name : PsName} {index : Nat} {value value' : PsExpr} (hvalue : Lift amount cutoff value value') :
      Lift amount cutoff (.proj name index value) (.proj name index value')

inductive Substitute (replacement : PsExpr) : Nat → PsExpr → PsExpr → Prop where
  | bound {index depth : Nat} (h : index < depth) :
      Substitute replacement depth (.bvar index) (.bvar index)
  | hit {depth : Nat} {result : PsExpr} (lift : Lift depth 0 replacement result) :
      Substitute replacement depth (.bvar depth) result
  | above {index depth : Nat} (h : depth < index) :
      Substitute replacement depth (.bvar index) (.bvar (Nat.sub index 1))
  | fvar {depth identifier : Nat} :
      Substitute replacement depth (.fvar identifier) (.fvar identifier)
  | mvar {depth identifier : Nat} :
      Substitute replacement depth (.mvar identifier) (.mvar identifier)
  | sortE {depth : Nat} {level : PsLevel} :
      Substitute replacement depth (.sortE level) (.sortE level)
  | constE {depth : Nat} {name : PsName} {levels : List PsLevel} :
      Substitute replacement depth (.constE name levels) (.constE name levels)
  | lit {depth : Nat} {value : PsLiteral} :
      Substitute replacement depth (.lit value) (.lit value)
  | app {depth : Nat} {fn fn' arg arg' : PsExpr} (hfn : Substitute replacement depth fn fn') (harg : Substitute replacement depth arg arg') :
      Substitute replacement depth (.app fn arg) (.app fn' arg')
  | lam {depth : Nat} {name : PsName} {type type' body body' : PsExpr} {binder : PsBinderInfo} (htype : Substitute replacement depth type type') (hbody : Substitute replacement (Nat.succ depth) body body') :
      Substitute replacement depth (.lam name type body binder) (.lam name type' body' binder)
  | forallE {depth : Nat} {name : PsName} {type type' body body' : PsExpr} {binder : PsBinderInfo} (htype : Substitute replacement depth type type') (hbody : Substitute replacement (Nat.succ depth) body body') :
      Substitute replacement depth (.forallE name type body binder) (.forallE name type' body' binder)
  | letE {depth : Nat} {name : PsName} {type type' value value' body body' : PsExpr} (htype : Substitute replacement depth type type') (hvalue : Substitute replacement depth value value') (hbody : Substitute replacement (Nat.succ depth) body body') :
      Substitute replacement depth (.letE name type value body) (.letE name type' value' body')
  | proj {depth : Nat} {name : PsName} {index : Nat} {value value' : PsExpr} (hvalue : Substitute replacement depth value value') :
      Substitute replacement depth (.proj name index value) (.proj name index value')

theorem lift_constructive (expression : PsExpr) (amount cutoff : Nat) :
    Lift amount cutoff expression (psExprLiftBVarsWorker amount expression cutoff) := by
  induction expression generalizing cutoff with
  | bvar index =>
      by_cases h : cutoff ≤ index
      · have hb : Nat.ble cutoff index = true := by simpa only [Nat.ble_eq] using h
        simpa only [psExprLiftBVarsWorker, hb, ite_true] using (Lift.above h : Lift amount cutoff (.bvar index) _)
      · have hb : ¬ Nat.ble cutoff index = true := by simpa only [Nat.ble_eq] using h
        simpa only [psExprLiftBVarsWorker, ite_eq_right hb] using
          (Lift.bound (Nat.lt_of_not_ge h) : Lift amount cutoff (.bvar index) _)
  | fvar id =>
      exact .fvar
  | mvar id =>
      exact .mvar
  | sortE level =>
      exact .sortE
  | constE name levels =>
      exact .constE
  | lit value =>
      exact .lit
  | app fn arg ihfn iharg=>
      exact .app (ihfn cutoff) (iharg cutoff)
  | lam name type body binder ihtype ihbody=>
      exact .lam (ihtype cutoff) (ihbody (Nat.succ cutoff))
  | forallE name type body binder ihtype ihbody=>
      exact .forallE (ihtype cutoff) (ihbody (Nat.succ cutoff))
  | letE name type value body ihtype ihvalue ihbody=>
      exact .letE (ihtype cutoff) (ihvalue cutoff) (ihbody (Nat.succ cutoff))
  | proj name index value ihvalue=>
      exact .proj (ihvalue cutoff)

theorem lift_correct (h : Lift amount cutoff expression result) :
    psExprLiftBVarsWorker amount expression cutoff = result := by
  induction h with
  | @bound index cutoff h =>
      have hb : ¬ Nat.ble cutoff index = true := by
        simpa only [Nat.ble_eq] using Nat.not_le_of_gt h
      simp only [psExprLiftBVarsWorker, ite_eq_right hb]
  | @above index cutoff h =>
      have hb : Nat.ble cutoff index = true := by simpa only [Nat.ble_eq] using h
      simp only [psExprLiftBVarsWorker, hb, ite_true]
  | fvar => rfl
  | mvar => rfl
  | sortE => rfl
  | constE => rfl
  | lit => rfl
  | app hfn harg ihfn iharg=> simp only [psExprLiftBVarsWorker, ihfn, iharg]
  | lam htype hbody ihtype ihbody=> simp only [psExprLiftBVarsWorker, ihtype, ihbody]
  | forallE htype hbody ihtype ihbody=> simp only [psExprLiftBVarsWorker, ihtype, ihbody]
  | letE htype hvalue hbody ihtype ihvalue ihbody=> simp only [psExprLiftBVarsWorker, ihtype, ihvalue, ihbody]
  | proj hvalue ihvalue=> simp only [psExprLiftBVarsWorker, ihvalue]

theorem lift_iff : Lift amount cutoff expression result ↔
    psExprLiftBVarsWorker amount expression cutoff = result := by
  constructor
  · exact lift_correct
  · intro h
    rw [← h]
    exact lift_constructive expression amount cutoff

theorem lift_unique (left : Lift amount cutoff expression a)
    (right : Lift amount cutoff expression b) : a = b :=
  (lift_correct left).symm.trans (lift_correct right)

theorem substitution_constructive (expression replacement : PsExpr) (depth : Nat) :
    Substitute replacement depth expression
      (psExprInstantiateAtWorker replacement expression depth) := by
  induction expression generalizing depth with
  | bvar index =>
      by_cases he : index = depth
      · subst index
        have heq : Nat.beq depth depth = true := by simpa only [Nat.beq_eq] using (Eq.refl depth)
        simpa only [psExprInstantiateAtWorker, heq, ite_true,
          psExprLiftBVars] using
          (Substitute.hit (lift_constructive replacement depth 0) :
            Substitute replacement depth (.bvar depth) _)
      · have he' : ¬ Nat.beq index depth = true := by simpa only [Nat.beq_eq] using he
        by_cases hg : depth < index
        · have hg' : Nat.blt depth index = true := by simpa only [Nat.blt_eq] using hg
          simpa only [psExprInstantiateAtWorker, ite_eq_right he', hg', ite_true] using
            (Substitute.above hg : Substitute replacement depth (.bvar index) _)
        · have hg' : ¬ Nat.blt depth index = true := by simpa only [Nat.blt_eq] using hg
          have hl : index < depth :=
            Nat.lt_of_le_of_ne (Nat.le_of_not_gt hg) he
          simpa only [psExprInstantiateAtWorker, ite_eq_right he', ite_eq_right hg'] using
            (Substitute.bound hl : Substitute replacement depth (.bvar index) _)
  | fvar id =>
      exact .fvar
  | mvar id =>
      exact .mvar
  | sortE level =>
      exact .sortE
  | constE name levels =>
      exact .constE
  | lit value =>
      exact .lit
  | app fn arg ihfn iharg=>
      exact .app (ihfn depth) (iharg depth)
  | lam name type body binder ihtype ihbody=>
      exact .lam (ihtype depth) (ihbody (Nat.succ depth))
  | forallE name type body binder ihtype ihbody=>
      exact .forallE (ihtype depth) (ihbody (Nat.succ depth))
  | letE name type value body ihtype ihvalue ihbody=>
      exact .letE (ihtype depth) (ihvalue depth) (ihbody (Nat.succ depth))
  | proj name index value ihvalue=>
      exact .proj (ihvalue depth)

theorem substitution_correct (h : Substitute replacement depth expression result) :
    psExprInstantiateAtWorker replacement expression depth = result := by
  induction h with
  | @bound index depth h =>
      have he : ¬ Nat.beq index depth = true := by simpa only [Nat.beq_eq] using Nat.ne_of_lt h
      have hg : ¬ Nat.blt depth index = true := by simpa only [Nat.blt_eq] using Nat.not_lt_of_ge (Nat.le_of_lt h)
      simp only [psExprInstantiateAtWorker, ite_eq_right he, ite_eq_right hg]
  | @hit depth result lifted =>
      have heq : Nat.beq depth depth = true := by simpa only [Nat.beq_eq] using (Eq.refl depth)
      simpa only [psExprInstantiateAtWorker, heq, ite_true,
        psExprLiftBVars] using lift_correct lifted
  | @above index depth h =>
      have he : ¬ Nat.beq index depth = true := by simpa only [Nat.beq_eq] using (Nat.ne_of_gt h)
      have hg : Nat.blt depth index = true := by simpa only [Nat.blt_eq] using h
      simp only [psExprInstantiateAtWorker, ite_eq_right he, hg, ite_true]
  | fvar => rfl
  | mvar => rfl
  | sortE => rfl
  | constE => rfl
  | lit => rfl
  | app hfn harg ihfn iharg=> simp only [psExprInstantiateAtWorker, ihfn, iharg]
  | lam htype hbody ihtype ihbody=> simp only [psExprInstantiateAtWorker, ihtype, ihbody]
  | forallE htype hbody ihtype ihbody=> simp only [psExprInstantiateAtWorker, ihtype, ihbody]
  | letE htype hvalue hbody ihtype ihvalue ihbody=> simp only [psExprInstantiateAtWorker, ihtype, ihvalue, ihbody]
  | proj hvalue ihvalue=> simp only [psExprInstantiateAtWorker, ihvalue]

theorem substitution_iff : Substitute replacement depth expression result ↔
    psExprInstantiateAtWorker replacement expression depth = result := by
  constructor
  · exact substitution_correct
  · intro h
    rw [← h]
    exact substitution_constructive expression replacement depth

theorem substitution_unique (left : Substitute replacement depth expression a)
    (right : Substitute replacement depth expression b) : a = b :=
  (substitution_correct left).symm.trans (substitution_correct right)

theorem instantiate1_derives (body replacement : PsExpr) :
    Substitute replacement 0 body (psExprInstantiate1 body replacement) :=
  substitution_constructive body replacement 0

inductive SourceEval : PsExpr → Ps.MinKernel.CompilerCaller.Value → Prop where
  | natural (n) : SourceEval (.lit (.natural n)) (.natural n)
  | text (s) : SourceEval (.lit (.string s)) (.text s)
  | zeta (substitution : Substitute value 0 body opened)
      (evaluates : SourceEval opened result) :
      SourceEval (.letE name domain value body) result

theorem source_forward (h : Ps.MinKernel.CompilerCaller.SourceEval expression value) :
    SourceEval expression value := by
  induction h with
  | natural => exact .natural _
  | text => exact .text _
  | zeta h ih => exact .zeta (instantiate1_derives _ _) ih

theorem source_reverse (h : SourceEval expression value) :
    Ps.MinKernel.CompilerCaller.SourceEval expression value := by
  induction h with
  | natural => exact .natural _
  | text => exact .text _
  | zeta substitution evaluates ih =>
      apply Ps.MinKernel.CompilerCaller.SourceEval.zeta
      simpa only [psExprInstantiate1, psExprInstantiateAt,
        substitution_correct substitution] using ih

theorem source_iff : SourceEval expression value ↔
    Ps.MinKernel.CompilerCaller.SourceEval expression value :=
  ⟨source_reverse, source_forward⟩

theorem public_independent
    (h : Ps.MinKernel.CompilerCaller.Eligible environment fuel scope expression value) :
    ∃ ir, psEraseRuntimeExprWithFuel environment scope fuel expression = .ok ir ∧
      SourceEval expression value ∧ Ps.MinKernel.CompilerCaller.TargetEval ir value := by
  obtain ⟨ir, lowered, source, target⟩ := Ps.MinKernel.CompilerCaller.public_preserves h
  exact ⟨ir, lowered, source_forward source, target⟩

theorem entry_independent
    (h : Ps.MinKernel.CompilerCaller.Eligible environment 4096 scope expression value) :
    ∃ ir, psEraseRuntimeExpr environment scope expression = .ok ir ∧
      SourceEval expression value ∧ Ps.MinKernel.CompilerCaller.TargetEval ir value :=
  public_independent h

end Ps.MinKernel.CompilerSubstitution
