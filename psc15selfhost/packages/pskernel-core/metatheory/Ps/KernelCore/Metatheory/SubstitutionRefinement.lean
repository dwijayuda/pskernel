import Ps.KernelCore.Metatheory.Substitution
import Ps.KernelCore.Core.Substitution.Instantiate

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


theorem psKernelExprInstantiateAtChangedWithFuel_refines_reference_core
    (expr : PsKernelExpr)
    (fuel start offset : Nat)
    (subst : List PsKernelExpr)
    (hFuel : psKernelExprNodeCount expr < fuel) :
    psKernelExprInstantiateAtChangedWithFuel
        fuel expr start subst offset =
      psKernelExprInstantiateAtReferenceChanged
        expr start subst offset := by
  induction expr generalizing fuel start offset subst with
  | bvar index =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp only [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged
          ]
          cases hBefore :
              psKernelNatLt index (Nat.add start offset) with
          | true =>
              simp [hBefore]
          | false =>
              simp [hBefore]
              cases hGet :
                  psKernelExprListGet
                    subst
                    (Nat.sub
                      index
                      (Nat.add start offset)) with
              | none =>
                  simp [hGet]
              | some replacement =>
                  simp [
                    hGet,
                    psKernelExprLiftLooseBVars_refines_reference_core
                  ]
  | fvar name =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged
          ]
  | mvar name =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged
          ]
  | sort level =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged
          ]
  | const name levels =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged
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
            ihFn remaining start offset subst hFnFuel
          have hArg :=
            ihArg remaining start offset subst hArgFuel
          simp [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged,
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
            ihType remaining start offset subst hTypeFuel
          have hBody :=
            ihBody remaining start (Nat.succ offset) subst hBodyFuel
          simp [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged,
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
            ihType remaining start offset subst hTypeFuel
          have hBody :=
            ihBody remaining start (Nat.succ offset) subst hBodyFuel
          simp [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged,
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
            ihType remaining start offset subst hTypeFuel
          have hValue :=
            ihValue remaining start offset subst hValueFuel
          have hBody :=
            ihBody remaining start (Nat.succ offset) subst hBodyFuel
          simp [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged,
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
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged
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
            ihBody remaining start offset subst hBodyFuel
          simp [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged,
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
            ihBody remaining start offset subst hBodyFuel
          simp [
            psKernelExprInstantiateAtChangedWithFuel,
            psKernelExprInstantiateAtReferenceChanged,
            hBody
          ]

theorem psKernelExprInstantiateAtChanged_refines_reference_core
    (expr : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAtChanged
        expr start subst offset =
      psKernelExprInstantiateAtReferenceChanged
        expr start subst offset := by
  unfold psKernelExprInstantiateAtChanged
  exact
    psKernelExprInstantiateAtChangedWithFuel_refines_reference_core
      expr
      (Nat.succ (psKernelExprNodeCount expr))
      start
      offset
      subst
      (Nat.lt_succ_self
        (psKernelExprNodeCount expr))

theorem psKernelExprInstantiateAt_refines_reference_core
    (expr : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAt
        expr start subst offset =
      psKernelExprInstantiateAtReference
        expr start subst offset := by
  cases hEmpty : psKernelExprListIsEmpty subst with
  | false =>
      simp [
        psKernelExprInstantiateAt,
        psKernelExprInstantiateAtReference,
        hEmpty,
        psKernelExprInstantiateAtChanged_refines_reference_core
      ]
  | true =>
      simp [
        psKernelExprInstantiateAt,
        psKernelExprInstantiateAtReference,
        hEmpty
      ]

theorem psKernelExprInstantiate_refines_reference_core
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr) :
    psKernelExprInstantiate expr subst =
      psKernelExprInstantiateReference expr subst := by
  unfold psKernelExprInstantiate
  unfold psKernelExprInstantiateReference
  exact
    psKernelExprInstantiateAt_refines_reference_core
      expr 0 subst 0

theorem psKernelExprInstantiate1_refines_reference_core
    (expr replacement : PsKernelExpr) :
    psKernelExprInstantiate1 expr replacement =
      psKernelExprInstantiate1Reference
        expr replacement := by
  cases hLoose : psKernelExprHasLooseBVar expr with
  | false =>
      simp [
        psKernelExprInstantiate1,
        psKernelExprInstantiate1Reference,
        hLoose
      ]
  | true =>
      simp [
        psKernelExprInstantiate1,
        psKernelExprInstantiate1Reference,
        hLoose,
        psKernelExprInstantiate_refines_reference_core
      ]

theorem psKernelExprInstantiateRev_refines_reference_core
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr) :
    psKernelExprInstantiateRev expr subst =
      psKernelExprInstantiateRevReference
        expr subst := by
  unfold psKernelExprInstantiateRev
  unfold psKernelExprInstantiateRevReference
  rw [psKernelExprInstantiate_refines_reference_core]


theorem psKernelExprAbstractFVarsAtChangedWithFuel_refines_reference_core
    (expr : PsKernelExpr)
    (fuel offset : Nat)
    (fvars : List PsKernelName)
    (hFuel : psKernelExprNodeCount expr < fuel) :
    psKernelExprAbstractFVarsAtChangedWithFuel
        fuel expr fvars offset =
      psKernelExprAbstractFVarsAtReferenceChanged
        expr fvars offset := by
  induction expr generalizing fuel offset fvars with
  | bvar index =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged
          ]
  | fvar name =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged
          ]
  | mvar name =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged
          ]
  | sort level =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged
          ]
  | const name levels =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged
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
            ihFn remaining offset fvars hFnFuel
          have hArg :=
            ihArg remaining offset fvars hArgFuel
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged,
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
            ihType remaining offset fvars hTypeFuel
          have hBody :=
            ihBody remaining (Nat.succ offset) fvars hBodyFuel
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged,
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
            ihType remaining offset fvars hTypeFuel
          have hBody :=
            ihBody remaining (Nat.succ offset) fvars hBodyFuel
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged,
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
            ihType remaining offset fvars hTypeFuel
          have hValue :=
            ihValue remaining offset fvars hValueFuel
          have hBody :=
            ihBody remaining (Nat.succ offset) fvars hBodyFuel
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged,
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
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged
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
            ihBody remaining offset fvars hBodyFuel
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged,
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
            ihBody remaining offset fvars hBodyFuel
          simp [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged,
            hBody
          ]

theorem psKernelExprAbstractFVarsAtChanged_refines_reference_core
    (expr : PsKernelExpr)
    (fvars : List PsKernelName)
    (offset : Nat) :
    psKernelExprAbstractFVarsAtChanged
        expr fvars offset =
      psKernelExprAbstractFVarsAtReferenceChanged
        expr fvars offset := by
  unfold psKernelExprAbstractFVarsAtChanged
  exact
    psKernelExprAbstractFVarsAtChangedWithFuel_refines_reference_core
      expr
      (Nat.succ (psKernelExprNodeCount expr))
      offset
      fvars
      (Nat.lt_succ_self
        (psKernelExprNodeCount expr))

theorem psKernelExprAbstractFVarsAt_refines_reference_core
    (expr : PsKernelExpr)
    (fvars : List PsKernelName)
    (offset : Nat) :
    psKernelExprAbstractFVarsAt
        expr fvars offset =
      psKernelExprAbstractFVarsAtReference
        expr fvars offset := by
  cases fvars with
  | nil =>
      rfl
  | cons head tail =>
      unfold psKernelExprAbstractFVarsAt
      unfold psKernelExprAbstractFVarsAtReference
      rw [psKernelExprAbstractFVarsAtChanged_refines_reference_core]

theorem psKernelExprAbstractFVars_refines_reference_core
    (expr : PsKernelExpr)
    (fvars : List PsKernelName) :
    psKernelExprAbstractFVars expr fvars =
      psKernelExprAbstractFVarsReference
        expr fvars := by
  unfold psKernelExprAbstractFVars
  unfold psKernelExprAbstractFVarsReference
  exact
    psKernelExprAbstractFVarsAt_refines_reference_core
      expr fvars 0
