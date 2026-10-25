import Lean
import Ps.KernelCore.SelfHost

theorem psKernelUnaryPlanZero (arena : PsKernelExprV2PagedArena) (left right : Nat) :
    psKernelExprV2UnarySpinePlanWithFuel 0 arena left right = none := rfl

theorem psKernelUnaryPlanStops (fuel : Nat) (arena : PsKernelExprV2PagedArena)
    (left right : Nat) (h : psKernelExprV2UnarySpineView arena left right = none) :
    psKernelExprV2UnarySpinePlanWithFuel (fuel + 1) arena left right =
      some ⟨left, right, 0⟩ := by
  simp [psKernelExprV2UnarySpinePlanWithFuel, h]

theorem psKernelUnaryPlanPreserves
    (fuel : Nat) (arena : PsKernelExprV2PagedArena) (left right : Nat)
    (plan : PsKernelExprV2UnarySpinePlan)
    (found : psKernelExprV2UnarySpinePlanWithFuel fuel arena left right = some plan)
    (R : Nat → Nat → Prop)
    (congruence : ∀ l r la ra, psKernelExprV2UnarySpineView arena l r = some (la, ra) →
      R la ra → R l r)
    (residual : R plan.left plan.right) : R left right := by
  induction fuel generalizing left right plan with
  | zero => simp [psKernelExprV2UnarySpinePlanWithFuel] at found
  | succ fuel ih =>
      cases view : psKernelExprV2UnarySpineView arena left right with
      | none =>
          simp [psKernelExprV2UnarySpinePlanWithFuel, view] at found
          cases found
          exact residual
      | some pair =>
          rcases pair with ⟨la, ra⟩
          cases tail : psKernelExprV2UnarySpinePlanWithFuel fuel arena la ra with
          | none => simp [psKernelExprV2UnarySpinePlanWithFuel, view, tail] at found
          | some next =>
              simp [psKernelExprV2UnarySpinePlanWithFuel, view, tail] at found
              cases found
              exact congruence left right la ra view (ih la ra next tail residual)

theorem psKernelUnaryPlanSkippedBound
    (fuel : Nat) (arena : PsKernelExprV2PagedArena) (left right : Nat)
    (plan : PsKernelExprV2UnarySpinePlan)
    (found : psKernelExprV2UnarySpinePlanWithFuel fuel arena left right = some plan) :
    plan.skipped < fuel := by
  induction fuel generalizing left right plan with
  | zero => simp [psKernelExprV2UnarySpinePlanWithFuel] at found
  | succ fuel ih =>
      cases view : psKernelExprV2UnarySpineView arena left right with
      | none =>
          simp [psKernelExprV2UnarySpinePlanWithFuel, view] at found
          cases found
          exact Nat.zero_lt_succ fuel
      | some pair =>
          rcases pair with ⟨la, ra⟩
          cases tail : psKernelExprV2UnarySpinePlanWithFuel fuel arena la ra with
          | none => simp [psKernelExprV2UnarySpinePlanWithFuel, view, tail] at found
          | some next =>
              simp [psKernelExprV2UnarySpinePlanWithFuel, view, tail] at found
              cases found
              exact Nat.succ_lt_succ (ih la ra next tail)

theorem psKernelUnaryViewHasSharedHead
    (arena : PsKernelExprV2PagedArena) (left right la ra : Nat)
    (found : psKernelExprV2UnarySpineView arena left right = some (la, ra)) :
    ∃ fn name,
      (psKernelExprV2PagedFind arena left).map PsKernelExprV2Entry.node = some (.app fn la) ∧
      (psKernelExprV2PagedFind arena right).map PsKernelExprV2Entry.node = some (.app fn ra) ∧
      (psKernelExprV2PagedFind arena fn).map PsKernelExprV2Entry.node = some (.fvar name) := by
  cases hl : psKernelExprV2PagedFind arena left with
  | none => simp [psKernelExprV2UnarySpineView, hl] at found
  | some l =>
      cases hr : psKernelExprV2PagedFind arena right with
      | none => simp [psKernelExprV2UnarySpineView, hl, hr] at found
      | some r =>
          cases hln : l.node with
          | app lf larg =>
              cases hrn : r.node with
              | app rf rarg =>
                  by_cases sameHead : lf = rf
                  · subst rf
                    cases hh : psKernelExprV2PagedFind arena lf with
                    | none =>
                        simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh] at found
                    | some head =>
                        cases hhead : head.node with
                        | fvar name =>
                            have args : larg = la ∧ rarg = ra := by
                              simpa [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] using found
                            rcases args with ⟨rfl, rfl⟩
                            exact ⟨lf, name, by simp [hl, hln], by simp [hr, hrn], by simp [hh, hhead]⟩
                        | bvar index => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                        | mvar name => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                        | sort level => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                        | const name levels => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                        | app fn arg => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                        | lam name type body binderInfo => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                        | forallE name type body binderInfo => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                        | letE name type value body nondep => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                        | lit value => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                        | mdata metadata body => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                        | proj typeName index body => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, hh, hhead] at found
                  · simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn, sameHead] at found
              | bvar index => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
              | fvar name => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
              | mvar name => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
              | sort level => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
              | const name levels => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
              | lam name type body binderInfo => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
              | forallE name type body binderInfo => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
              | letE name type value body nondep => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
              | lit value => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
              | mdata metadata body => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
              | proj typeName index body => simp [psKernelExprV2UnarySpineView, hl, hr, hln, hrn] at found
          | bvar index => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found
          | fvar name => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found
          | mvar name => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found
          | sort level => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found
          | const name levels => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found
          | lam name type body binderInfo => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found
          | forallE name type body binderInfo => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found
          | letE name type value body nondep => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found
          | lit value => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found
          | mdata metadata body => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found
          | proj typeName index body => simp [psKernelExprV2UnarySpineView, hl, hr, hln] at found

theorem psKernelUnaryPlanExpressionCongruence
    (fuel : Nat) (arena : PsKernelExprV2PagedArena) (left right : Nat)
    (plan : PsKernelExprV2UnarySpinePlan)
    (found : psKernelExprV2UnarySpinePlanWithFuel fuel arena left right = some plan)
    (meaning : Nat → PsKernelExpr) (R : PsKernelExpr → PsKernelExpr → Prop)
    (apps : ∀ id fn arg,
      (psKernelExprV2PagedFind arena id).map PsKernelExprV2Entry.node = some (.app fn arg) →
      meaning id = .app (meaning fn) (meaning arg))
    (congruence : ∀ fn a b, R a b → R (.app fn a) (.app fn b))
    (residual : R (meaning plan.left) (meaning plan.right)) :
    R (meaning left) (meaning right) := by
  apply psKernelUnaryPlanPreserves fuel arena left right plan found
    (fun l r => R (meaning l) (meaning r)) ?_ residual
  intro l r la ra view hypothesis
  obtain ⟨fn, name, hl, hr, _⟩ := psKernelUnaryViewHasSharedHead arena l r la ra view
  rw [apps l fn la hl, apps r fn ra hr]
  exact congruence (meaning fn) (meaning la) (meaning ra) hypothesis

theorem psKernelUnaryContextZero (context : PsKernelExprV2CheckContext) :
    psKernelExprV2UnarySpineContext 0 context = .ok context := rfl

theorem psKernelUnaryPlanTerminates
    (fuel : Nat) (arena : PsKernelExprV2PagedArena) (left right : Nat)
    (rank : Nat → Nat)
    (descends : ∀ l r la ra, psKernelExprV2UnarySpineView arena l r = some (la, ra) →
      rank la + rank ra < rank l + rank r)
    (bound : rank left + rank right < fuel) :
    ∃ plan, psKernelExprV2UnarySpinePlanWithFuel fuel arena left right = some plan := by
  induction fuel generalizing left right with
  | zero => omega
  | succ fuel ih =>
      cases view : psKernelExprV2UnarySpineView arena left right with
      | none =>
          exact ⟨⟨left, right, 0⟩, by simp [psKernelExprV2UnarySpinePlanWithFuel, view]⟩
      | some pair =>
          rcases pair with ⟨la, ra⟩
          have decrease := descends left right la ra view
          have nextBound : rank la + rank ra < fuel := by omega
          obtain ⟨plan, found⟩ := ih la ra nextBound
          exact ⟨⟨plan.left, plan.right, plan.skipped + 1⟩,
            by simp [psKernelExprV2UnarySpinePlanWithFuel, view, found]⟩

theorem psKernelUnaryCallbackOwner
    (defeq : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →
      Option (Except String (PsKernelExprV2CheckState × Bool)))
    (context next : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) (l r : PsKernelExprV2Entry) (plan : PsKernelExprV2UnarySpinePlan)
    (hl : psKernelExprV2PagedFind state.whnf.arena left = some l)
    (hr : psKernelExprV2PagedFind state.whnf.arena right = some r)
    (hp : psKernelExprV2UnarySpinePlanWithFuel (Nat.succ (Nat.add l.depth r.depth))
      state.whnf.arena left right = some plan)
    (hs : Nat.ble 2 plan.skipped = true)
    (hc : psKernelExprV2UnarySpineContext (Nat.sub plan.skipped 1) context = .ok next) :
    psKernelExprV2TryUnarySpineWith defeq context state left right =
      defeq next state plan.left plan.right := by
  simp only [psKernelExprV2TryUnarySpineWith, hl, hr, hp, hs, hc] <;> simp

#print axioms psKernelUnaryPlanZero
#print axioms psKernelUnaryPlanStops
#print axioms psKernelUnaryPlanPreserves
#print axioms psKernelUnaryPlanSkippedBound
#print axioms psKernelUnaryViewHasSharedHead
#print axioms psKernelUnaryPlanExpressionCongruence
#print axioms psKernelUnaryContextZero
#print axioms psKernelUnaryPlanTerminates
#print axioms psKernelUnaryCallbackOwner
