import Ps.KernelCore.Metatheory.Substitution

theorem psKernelExprLiftLooseBVarsChanged_zero_amount_core
    (expr : PsKernelExpr)
    (start : Nat) :
    psKernelExprLiftLooseBVarsChanged expr start 0 =
      Prod.mk expr false := by
  simp [psKernelExprLiftLooseBVarsChanged]

theorem psKernelExprLiftLooseBVarsChangedWithFuel_refines_reference_core
    (expr : PsKernelExpr)
    (fuel start amount : Nat)
    (hFuel : psKernelExprNodeCount expr < fuel) :
    psKernelExprLiftLooseBVarsChangedWithFuel
        fuel expr start amount =
      psKernelExprLiftLooseBVarsReferenceChanged
        expr start amount := by
  induction expr generalizing fuel start amount with
  | bvar index =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged
          ]
  | fvar name =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged
          ]
  | mvar name =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged
          ]
  | sort level =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged
          ]
  | const name levels =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged
          ]
  | app fn arg ihFn ihArg =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          have hTotal :
              Nat.succ
                  (Nat.add
                    (psKernelExprNodeCount fn)
                    (psKernelExprNodeCount arg)) <
                Nat.succ remaining := by
            simpa only [psKernelExprNodeCount] using hFuel
          have hSum :
              Nat.add
                  (psKernelExprNodeCount fn)
                  (psKernelExprNodeCount arg) <
                remaining :=
            Nat.lt_of_succ_lt_succ hTotal
          have hFnFuel :
              psKernelExprNodeCount fn < remaining :=
            Nat.lt_of_le_of_lt
              (Nat.le_add_right
                (psKernelExprNodeCount fn)
                (psKernelExprNodeCount arg))
              hSum
          have hArgFuel :
              psKernelExprNodeCount arg < remaining :=
            Nat.lt_of_le_of_lt
              (Nat.le_add_left
                (psKernelExprNodeCount arg)
                (psKernelExprNodeCount fn))
              hSum
          have hFn :=
            ihFn remaining start amount hFnFuel
          have hArg :=
            ihArg remaining start amount hArgFuel
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged,
            hFn,
            hArg
          ]
  | lam name type body binderInfo ihType ihBody =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          have hTotal :
              Nat.succ
                  (Nat.add
                    (psKernelExprNodeCount type)
                    (psKernelExprNodeCount body)) <
                Nat.succ remaining := by
            simpa only [psKernelExprNodeCount] using hFuel
          have hSum :
              Nat.add
                  (psKernelExprNodeCount type)
                  (psKernelExprNodeCount body) <
                remaining :=
            Nat.lt_of_succ_lt_succ hTotal
          have hTypeFuel :
              psKernelExprNodeCount type < remaining :=
            Nat.lt_of_le_of_lt
              (Nat.le_add_right
                (psKernelExprNodeCount type)
                (psKernelExprNodeCount body))
              hSum
          have hBodyFuel :
              psKernelExprNodeCount body < remaining :=
            Nat.lt_of_le_of_lt
              (Nat.le_add_left
                (psKernelExprNodeCount body)
                (psKernelExprNodeCount type))
              hSum
          have hType :=
            ihType remaining start amount hTypeFuel
          have hBody :=
            ihBody remaining (Nat.succ start) amount hBodyFuel
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged,
            hType,
            hBody
          ]
  | forallE name type body binderInfo ihType ihBody =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          have hTotal :
              Nat.succ
                  (Nat.add
                    (psKernelExprNodeCount type)
                    (psKernelExprNodeCount body)) <
                Nat.succ remaining := by
            simpa only [psKernelExprNodeCount] using hFuel
          have hSum :
              Nat.add
                  (psKernelExprNodeCount type)
                  (psKernelExprNodeCount body) <
                remaining :=
            Nat.lt_of_succ_lt_succ hTotal
          have hTypeFuel :
              psKernelExprNodeCount type < remaining :=
            Nat.lt_of_le_of_lt
              (Nat.le_add_right
                (psKernelExprNodeCount type)
                (psKernelExprNodeCount body))
              hSum
          have hBodyFuel :
              psKernelExprNodeCount body < remaining :=
            Nat.lt_of_le_of_lt
              (Nat.le_add_left
                (psKernelExprNodeCount body)
                (psKernelExprNodeCount type))
              hSum
          have hType :=
            ihType remaining start amount hTypeFuel
          have hBody :=
            ihBody remaining (Nat.succ start) amount hBodyFuel
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged,
            hType,
            hBody
          ]
  | letE name type value body nondep ihType ihValue ihBody =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          have hTotal :
              Nat.succ
                  (Nat.add
                    (psKernelExprNodeCount type)
                    (Nat.add
                      (psKernelExprNodeCount value)
                      (psKernelExprNodeCount body))) <
                Nat.succ remaining := by
            simpa only [psKernelExprNodeCount] using hFuel
          have hSum :
              Nat.add
                  (psKernelExprNodeCount type)
                  (Nat.add
                    (psKernelExprNodeCount value)
                    (psKernelExprNodeCount body)) <
                remaining :=
            Nat.lt_of_succ_lt_succ hTotal
          have hTypeFuel :
              psKernelExprNodeCount type < remaining :=
            Nat.lt_of_le_of_lt
              (Nat.le_add_right
                (psKernelExprNodeCount type)
                (Nat.add
                  (psKernelExprNodeCount value)
                  (psKernelExprNodeCount body)))
              hSum
          have hTailLe :
              Nat.add
                  (psKernelExprNodeCount value)
                  (psKernelExprNodeCount body) ≤
                Nat.add
                  (psKernelExprNodeCount type)
                  (Nat.add
                    (psKernelExprNodeCount value)
                    (psKernelExprNodeCount body)) :=
            Nat.le_add_left
              (Nat.add
                (psKernelExprNodeCount value)
                (psKernelExprNodeCount body))
              (psKernelExprNodeCount type)
          have hValueFuel :
              psKernelExprNodeCount value < remaining :=
            Nat.lt_of_le_of_lt
              (Nat.le_trans
                (Nat.le_add_right
                  (psKernelExprNodeCount value)
                  (psKernelExprNodeCount body))
                hTailLe)
              hSum
          have hBodyFuel :
              psKernelExprNodeCount body < remaining :=
            Nat.lt_of_le_of_lt
              (Nat.le_trans
                (Nat.le_add_left
                  (psKernelExprNodeCount body)
                  (psKernelExprNodeCount value))
                hTailLe)
              hSum
          have hType :=
            ihType remaining start amount hTypeFuel
          have hValue :=
            ihValue remaining start amount hValueFuel
          have hBody :=
            ihBody remaining (Nat.succ start) amount hBodyFuel
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged,
            hType,
            hValue,
            hBody
          ]
  | lit literal =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged
          ]
  | mdata metadata body ihBody =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          have hTotal :
              Nat.succ (psKernelExprNodeCount body) <
                Nat.succ remaining := by
            simpa only [psKernelExprNodeCount] using hFuel
          have hBodyFuel :
              psKernelExprNodeCount body < remaining :=
            Nat.lt_of_succ_lt_succ hTotal
          have hBody :=
            ihBody remaining start amount hBodyFuel
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged,
            hBody
          ]
  | proj typeName index body ihBody =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          have hTotal :
              Nat.succ (psKernelExprNodeCount body) <
                Nat.succ remaining := by
            simpa only [psKernelExprNodeCount] using hFuel
          have hBodyFuel :
              psKernelExprNodeCount body < remaining :=
            Nat.lt_of_succ_lt_succ hTotal
          have hBody :=
            ihBody remaining start amount hBodyFuel
          simp [
            psKernelExprLiftLooseBVarsChangedWithFuel,
            psKernelExprLiftLooseBVarsReferenceChanged,
            hBody
          ]

theorem psKernelExprLiftLooseBVarsChanged_refines_reference_core
    (expr : PsKernelExpr)
    (start amount : Nat) :
    psKernelExprLiftLooseBVarsChanged expr start amount =
      psKernelExprLiftLooseBVarsReferenceChanged
        expr start amount := by
  cases amount with
  | zero =>
      rw [psKernelExprLiftLooseBVarsChanged_zero_amount_core]
      symm
      exact
        psKernelExprLiftLooseBVarsReferenceChanged_zero_amount
          expr
          start
  | succ amount =>
      simpa [psKernelExprLiftLooseBVarsChanged] using
        psKernelExprLiftLooseBVarsChangedWithFuel_refines_reference_core
          expr
          (Nat.succ (psKernelExprNodeCount expr))
          start
          (Nat.succ amount)
          (Nat.lt_succ_self
            (psKernelExprNodeCount expr))

theorem psKernelExprLiftLooseBVars_refines_reference_core
    (expr : PsKernelExpr)
    (start amount : Nat) :
    psKernelExprLiftLooseBVars expr start amount =
      psKernelExprLiftLooseBVarsReference
        expr start amount := by
  unfold psKernelExprLiftLooseBVars
  unfold psKernelExprLiftLooseBVarsReference
  rw [psKernelExprLiftLooseBVarsChanged_refines_reference_core]
