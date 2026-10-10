import Ps.KernelCore.Metatheory.Substitution
import Ps.KernelCore.Core.Substitution.Instantiate
import Ps.KernelCore.Core.Substitution.Abstract
import Lean.Elab.Tactic.Omega

theorem psKernelExprLiftLooseBVarsChanged_zero_amount_core
    (expr : PsKernelExpr)
    (start : Nat) :
    psKernelExprLiftLooseBVarsChanged expr start 0 =
      Prod.mk expr false := by
  cases expr <;> rfl

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
  induction expr generalizing start amount <;>
    simp_all [psKernelExprLiftLooseBVarsChanged,
      psKernelExprLiftLooseBVarsReferenceChanged]

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
  induction expr generalizing start offset <;>
    simp_all [psKernelExprInstantiateAtChanged,
      psKernelExprInstantiateAtReferenceChanged,
      psKernelExprLiftLooseBVars_refines_reference_core] <;> try rfl

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


theorem psKernelNameLastIndexWorker_refines_reference_core
    (values : List PsKernelName)
    (needle : PsKernelName)
    (index : Nat)
    (answer : Option Nat) :
    psKernelNameLastIndexWorker values needle index answer =
      psKernelNameLastIndexReferenceWorker
        values needle index answer := by
  induction values generalizing index answer with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [
        psKernelNameLastIndexWorker,
        psKernelNameLastIndexReferenceWorker,
        ih
      ]

theorem psKernelNameLastIndex_refines_reference_core
    (needle : PsKernelName)
    (values : List PsKernelName) :
    psKernelNameLastIndex needle values =
      psKernelNameLastIndexReference needle values := by
  unfold psKernelNameLastIndex
  unfold psKernelNameLastIndexReference
  exact
    psKernelNameLastIndexWorker_refines_reference_core
      values needle 0 Option.none

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
          simp only [
            psKernelExprAbstractFVarsAtChangedWithFuel,
            psKernelExprAbstractFVarsAtReferenceChanged
          ]
          rw [psKernelNameLastIndex_refines_reference_core]
          rfl
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
  induction expr generalizing offset <;>
    simp_all [psKernelExprAbstractFVarsAtChanged,
      psKernelExprAbstractFVarsAtReferenceChanged,
      psKernelNameLastIndex_refines_reference_core] <;> try rfl

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


theorem psKernelExprInstantiateAtReferenceChanged_closed_core
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr)
    (offset : Nat)
    (hClosed :
      psKernelExprHasLooseAt expr offset = false) :
    psKernelExprInstantiateAtReferenceChanged
        expr 0 subst offset =
      Prod.mk expr false := by
  induction expr generalizing offset with
  | bvar index =>
      have hClosedBool :
          Nat.ble offset index = false := by
        simpa [psKernelExprHasLooseAt] using hClosed
      have hNotTrue :
          Nat.ble offset index ≠ true := by
        intro hTrue
        rw [hTrue] at hClosedBool
        contradiction
      have hNotLe :
          ¬ offset ≤ index :=
        Nat.not_le_of_not_ble_eq_true hNotTrue
      have hLt : index < offset :=
        Nat.lt_of_not_ge hNotLe
      have hBeq :
          Nat.beq index offset = false := by
        cases hEq : Nat.beq index offset with
        | false =>
            rfl
        | true =>
            have hEqual : index = offset :=
              Nat.eq_of_beq_eq_true hEq
            subst offset
            exact (Nat.lt_irrefl index hLt).elim
      have hBle :
          Nat.ble index offset = true :=
        Nat.ble_eq_true_of_le (Nat.le_of_lt hLt)
      have hNatLt :
          psKernelNatLt index offset = true := by
        simp [psKernelNatLt, hBeq, hBle]
      simp [
        psKernelExprInstantiateAtReferenceChanged,
        hNatLt
      ]
  | fvar name =>
      simp [psKernelExprInstantiateAtReferenceChanged]
  | mvar name =>
      simp [psKernelExprInstantiateAtReferenceChanged]
  | sort level =>
      simp [psKernelExprInstantiateAtReferenceChanged]
  | const name levels =>
      simp [psKernelExprInstantiateAtReferenceChanged]
  | app fn arg ihFn ihArg =>
      cases hFn :
          psKernelExprHasLooseAt fn offset with
      | true =>
          simp [psKernelExprHasLooseAt, hFn] at hClosed
      | false =>
          have hArg :
              psKernelExprHasLooseAt arg offset = false := by
            simpa [psKernelExprHasLooseAt, hFn] using hClosed
          have hFnClosed := ihFn offset hFn
          have hArgClosed := ihArg offset hArg
          simp [
            psKernelExprInstantiateAtReferenceChanged,
            hFnClosed,
            hArgClosed
          ]
  | lam name type body binderInfo ihType ihBody =>
      cases hType :
          psKernelExprHasLooseAt type offset with
      | true =>
          simp [psKernelExprHasLooseAt, hType] at hClosed
      | false =>
          have hBody :
              psKernelExprHasLooseAt body (Nat.succ offset) =
                false := by
            simpa [psKernelExprHasLooseAt, hType] using hClosed
          have hTypeClosed := ihType offset hType
          have hBodyClosed := ihBody (Nat.succ offset) hBody
          simp [
            psKernelExprInstantiateAtReferenceChanged,
            hTypeClosed,
            hBodyClosed
          ]
  | forallE name type body binderInfo ihType ihBody =>
      cases hType :
          psKernelExprHasLooseAt type offset with
      | true =>
          simp [psKernelExprHasLooseAt, hType] at hClosed
      | false =>
          have hBody :
              psKernelExprHasLooseAt body (Nat.succ offset) =
                false := by
            simpa [psKernelExprHasLooseAt, hType] using hClosed
          have hTypeClosed := ihType offset hType
          have hBodyClosed := ihBody (Nat.succ offset) hBody
          simp [
            psKernelExprInstantiateAtReferenceChanged,
            hTypeClosed,
            hBodyClosed
          ]
  | letE name type value body nondep ihType ihValue ihBody =>
      cases hType :
          psKernelExprHasLooseAt type offset with
      | true =>
          simp [psKernelExprHasLooseAt, hType] at hClosed
      | false =>
          cases hValue :
              psKernelExprHasLooseAt value offset with
          | true =>
              simp [psKernelExprHasLooseAt, hType, hValue] at hClosed
          | false =>
              have hBody :
                  psKernelExprHasLooseAt
                      body
                      (Nat.succ offset) =
                    false := by
                simpa [
                  psKernelExprHasLooseAt,
                  hType,
                  hValue
                ] using hClosed
              have hTypeClosed := ihType offset hType
              have hValueClosed := ihValue offset hValue
              have hBodyClosed :=
                ihBody (Nat.succ offset) hBody
              simp [
                psKernelExprInstantiateAtReferenceChanged,
                hTypeClosed,
                hValueClosed,
                hBodyClosed
              ]
  | lit literal =>
      simp [psKernelExprInstantiateAtReferenceChanged]
  | mdata metadata body ihBody =>
      have hBody :
          psKernelExprHasLooseAt body offset = false := by
        simpa [psKernelExprHasLooseAt] using hClosed
      have hBodyClosed := ihBody offset hBody
      simp [
        psKernelExprInstantiateAtReferenceChanged,
        hBodyClosed
      ]
  | proj typeName index body ihBody =>
      have hBody :
          psKernelExprHasLooseAt body offset = false := by
        simpa [psKernelExprHasLooseAt] using hClosed
      have hBodyClosed := ihBody offset hBody
      simp [
        psKernelExprInstantiateAtReferenceChanged,
        hBodyClosed
      ]

theorem psKernelExprInstantiateAtReference_closed_core
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr)
    (offset : Nat)
    (hClosed :
      psKernelExprHasLooseAt expr offset = false) :
    psKernelExprInstantiateAtReference
        expr 0 subst offset =
      expr := by
  cases hEmpty : psKernelExprListIsEmpty subst with
  | true =>
      simp [
        psKernelExprInstantiateAtReference,
        hEmpty
      ]
  | false =>
      simp [
        psKernelExprInstantiateAtReference,
        hEmpty,
        psKernelExprInstantiateAtReferenceChanged_closed_core,
        hClosed
      ]

theorem psKernelExprInstantiateAt_closed_core
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr)
    (offset : Nat)
    (hClosed :
      psKernelExprHasLooseAt expr offset = false) :
    psKernelExprInstantiateAt
        expr 0 subst offset =
      expr := by
  rw [
    psKernelExprInstantiateAt_refines_reference_core
  ]
  exact
    psKernelExprInstantiateAtReference_closed_core
      expr subst offset hClosed


theorem psKernelExprLiftLooseBVarsReference_fvar_core
    (name : PsKernelName)
    (start amount : Nat) :
    psKernelExprLiftLooseBVarsReference
        (PsKernelExpr.fvar name)
        start
        amount =
      PsKernelExpr.fvar name := by
  cases amount <;>
    simp [
      psKernelExprLiftLooseBVarsReference,
      psKernelExprLiftLooseBVarsReferenceChanged
    ]


theorem psKernelExprAbstractInstantiateReferenceChanged_fvar_core
    (name target : PsKernelName)
    (offset : Nat)
    (hNameSound : PsKernelNameEqSoundAgainst target) :
    psKernelExprInstantiateAtReferenceChanged
        (Prod.fst
          (psKernelExprAbstractFVarsAtReferenceChanged
            (PsKernelExpr.fvar name)
            (List.cons target List.nil)
            offset))
        0
        (List.cons (PsKernelExpr.fvar target) List.nil)
        offset =
      Prod.mk
        (PsKernelExpr.fvar name)
        (Prod.snd
          (psKernelExprAbstractFVarsAtReferenceChanged
            (PsKernelExpr.fvar name)
            (List.cons target List.nil)
            offset)) := by
  cases hEq : psKernelNameEq name target with
  | false =>
      have hClosed :
          psKernelExprHasLooseAt
              (PsKernelExpr.fvar name)
              offset =
            false := by
        rfl
      have hInst :=
        psKernelExprInstantiateAtReferenceChanged_closed_core
          (PsKernelExpr.fvar name)
          (List.cons (PsKernelExpr.fvar target) List.nil)
          offset
          hClosed
      simpa [
        psKernelExprAbstractFVarsAtReferenceChanged,
        psKernelNameLastIndexReference,
        psKernelNameLastIndexReferenceWorker,
        hEq
      ] using hInst
  | true =>
      have hName : name = target :=
        hNameSound name hEq
      subst name
      simp [
        psKernelExprAbstractFVarsAtReferenceChanged,
        psKernelNameLastIndexReference,
        psKernelNameLastIndexReferenceWorker,
        hEq,
        psKernelExprInstantiateAtReferenceChanged,
        psKernelExprLiftLooseBVarsReference_fvar_core,
        psKernelNatLt,
        psKernelExprListGet,
        psKernelExprListLength,
        psKernelNameListLength
      ]


theorem psKernelExprAbstractInstantiateReferenceChanged_roundtrip_singleton_core
    (expr : PsKernelExpr)
    (target : PsKernelName)
    (offset : Nat)
    (hClosed :
      psKernelExprHasLooseAt expr offset = false)
    (hNameSound :
      PsKernelNameEqSoundAgainst target) :
    psKernelExprInstantiateAtReferenceChanged
        (Prod.fst
          (psKernelExprAbstractFVarsAtReferenceChanged
            expr
            (List.cons target List.nil)
            offset))
        0
        (List.cons (PsKernelExpr.fvar target) List.nil)
        offset =
      Prod.mk
        expr
        (Prod.snd
          (psKernelExprAbstractFVarsAtReferenceChanged
            expr
            (List.cons target List.nil)
            offset)) := by
  induction expr generalizing offset with
  | bvar index =>
      have hInst :=
        psKernelExprInstantiateAtReferenceChanged_closed_core
          (PsKernelExpr.bvar index)
          (List.cons (PsKernelExpr.fvar target) List.nil)
          offset
          hClosed
      simpa [
        psKernelExprAbstractFVarsAtReferenceChanged
      ] using hInst
  | fvar name =>
      exact
        psKernelExprAbstractInstantiateReferenceChanged_fvar_core
          name target offset hNameSound
  | mvar name =>
      have hInst :=
        psKernelExprInstantiateAtReferenceChanged_closed_core
          (PsKernelExpr.mvar name)
          (List.cons (PsKernelExpr.fvar target) List.nil)
          offset
          hClosed
      simpa [
        psKernelExprAbstractFVarsAtReferenceChanged
      ] using hInst
  | sort level =>
      have hInst :=
        psKernelExprInstantiateAtReferenceChanged_closed_core
          (PsKernelExpr.sort level)
          (List.cons (PsKernelExpr.fvar target) List.nil)
          offset
          hClosed
      simpa [
        psKernelExprAbstractFVarsAtReferenceChanged
      ] using hInst
  | const name levels =>
      have hInst :=
        psKernelExprInstantiateAtReferenceChanged_closed_core
          (PsKernelExpr.const name levels)
          (List.cons (PsKernelExpr.fvar target) List.nil)
          offset
          hClosed
      simpa [
        psKernelExprAbstractFVarsAtReferenceChanged
      ] using hInst
  | app fn arg ihFn ihArg =>
      cases hFnLoose :
          psKernelExprHasLooseAt fn offset with
      | true =>
          simp [
            psKernelExprHasLooseAt,
            hFnLoose
          ] at hClosed
      | false =>
          have hArgLoose :
              psKernelExprHasLooseAt arg offset = false := by
            simpa [
              psKernelExprHasLooseAt,
              hFnLoose
            ] using hClosed
          have ihFnResult :=
            ihFn offset hFnLoose
          have ihArgResult :=
            ihArg offset hArgLoose
          have hWholeClosed :=
            psKernelExprInstantiateAtReferenceChanged_closed_core
              (PsKernelExpr.app fn arg)
              (List.cons (PsKernelExpr.fvar target) List.nil)
              offset
              hClosed
          cases hAFn :
              psKernelExprAbstractFVarsAtReferenceChanged
                fn
                (List.cons target List.nil)
                offset with
          | mk fnResult fnChanged =>
              cases hAArg :
                  psKernelExprAbstractFVarsAtReferenceChanged
                    arg
                    (List.cons target List.nil)
                    offset with
              | mk argResult argChanged =>
                  rw [hAFn] at ihFnResult
                  rw [hAArg] at ihArgResult
                  cases fnChanged <;>
                    cases argChanged <;>
                    simp [
                      psKernelExprAbstractFVarsAtReferenceChanged,
                      hAFn,
                      hAArg,
                      psKernelExprInstantiateAtReferenceChanged,
                      ihFnResult,
                      ihArgResult,
                      hWholeClosed
                    ]
  | lam name type body binderInfo ihType ihBody =>
      cases hTypeLoose :
          psKernelExprHasLooseAt type offset with
      | true =>
          simp [
            psKernelExprHasLooseAt,
            hTypeLoose
          ] at hClosed
      | false =>
          have hBodyLoose :
              psKernelExprHasLooseAt
                  body
                  (Nat.succ offset) =
                false := by
            simpa [
              psKernelExprHasLooseAt,
              hTypeLoose
            ] using hClosed
          have ihTypeResult :=
            ihType offset hTypeLoose
          have ihBodyResult :=
            ihBody (Nat.succ offset) hBodyLoose
          have hWholeClosed :=
            psKernelExprInstantiateAtReferenceChanged_closed_core
              (PsKernelExpr.lam name type body binderInfo)
              (List.cons (PsKernelExpr.fvar target) List.nil)
              offset
              hClosed
          cases hAType :
              psKernelExprAbstractFVarsAtReferenceChanged
                type
                (List.cons target List.nil)
                offset with
          | mk typeResult typeChanged =>
              cases hABody :
                  psKernelExprAbstractFVarsAtReferenceChanged
                    body
                    (List.cons target List.nil)
                    (Nat.succ offset) with
              | mk bodyResult bodyChanged =>
                  rw [hAType] at ihTypeResult
                  rw [hABody] at ihBodyResult
                  cases typeChanged <;>
                    cases bodyChanged <;>
                    simp [
                      psKernelExprAbstractFVarsAtReferenceChanged,
                      hAType,
                      hABody,
                      psKernelExprInstantiateAtReferenceChanged,
                      ihTypeResult,
                      ihBodyResult,
                      hWholeClosed
                    ]
  | forallE name type body binderInfo ihType ihBody =>
      cases hTypeLoose :
          psKernelExprHasLooseAt type offset with
      | true =>
          simp [
            psKernelExprHasLooseAt,
            hTypeLoose
          ] at hClosed
      | false =>
          have hBodyLoose :
              psKernelExprHasLooseAt
                  body
                  (Nat.succ offset) =
                false := by
            simpa [
              psKernelExprHasLooseAt,
              hTypeLoose
            ] using hClosed
          have ihTypeResult :=
            ihType offset hTypeLoose
          have ihBodyResult :=
            ihBody (Nat.succ offset) hBodyLoose
          have hWholeClosed :=
            psKernelExprInstantiateAtReferenceChanged_closed_core
              (PsKernelExpr.forallE name type body binderInfo)
              (List.cons (PsKernelExpr.fvar target) List.nil)
              offset
              hClosed
          cases hAType :
              psKernelExprAbstractFVarsAtReferenceChanged
                type
                (List.cons target List.nil)
                offset with
          | mk typeResult typeChanged =>
              cases hABody :
                  psKernelExprAbstractFVarsAtReferenceChanged
                    body
                    (List.cons target List.nil)
                    (Nat.succ offset) with
              | mk bodyResult bodyChanged =>
                  rw [hAType] at ihTypeResult
                  rw [hABody] at ihBodyResult
                  cases typeChanged <;>
                    cases bodyChanged <;>
                    simp [
                      psKernelExprAbstractFVarsAtReferenceChanged,
                      hAType,
                      hABody,
                      psKernelExprInstantiateAtReferenceChanged,
                      ihTypeResult,
                      ihBodyResult,
                      hWholeClosed
                    ]
  | letE name type value body nondep ihType ihValue ihBody =>
      cases hTypeLoose :
          psKernelExprHasLooseAt type offset with
      | true =>
          simp [
            psKernelExprHasLooseAt,
            hTypeLoose
          ] at hClosed
      | false =>
          cases hValueLoose :
              psKernelExprHasLooseAt value offset with
          | true =>
              simp [
                psKernelExprHasLooseAt,
                hTypeLoose,
                hValueLoose
              ] at hClosed
          | false =>
              have hBodyLoose :
                  psKernelExprHasLooseAt
                      body
                      (Nat.succ offset) =
                    false := by
                simpa [
                  psKernelExprHasLooseAt,
                  hTypeLoose,
                  hValueLoose
                ] using hClosed
              have ihTypeResult :=
                ihType offset hTypeLoose
              have ihValueResult :=
                ihValue offset hValueLoose
              have ihBodyResult :=
                ihBody (Nat.succ offset) hBodyLoose
              have hWholeClosed :=
                psKernelExprInstantiateAtReferenceChanged_closed_core
                  (PsKernelExpr.letE
                    name type value body nondep)
                  (List.cons (PsKernelExpr.fvar target) List.nil)
                  offset
                  hClosed
              cases hAType :
                  psKernelExprAbstractFVarsAtReferenceChanged
                    type
                    (List.cons target List.nil)
                    offset with
              | mk typeResult typeChanged =>
                  cases hAValue :
                      psKernelExprAbstractFVarsAtReferenceChanged
                        value
                        (List.cons target List.nil)
                        offset with
                  | mk valueResult valueChanged =>
                      cases hABody :
                          psKernelExprAbstractFVarsAtReferenceChanged
                            body
                            (List.cons target List.nil)
                            (Nat.succ offset) with
                      | mk bodyResult bodyChanged =>
                          rw [hAType] at ihTypeResult
                          rw [hAValue] at ihValueResult
                          rw [hABody] at ihBodyResult
                          cases typeChanged <;>
                            cases valueChanged <;>
                            cases bodyChanged <;>
                            simp [
                              psKernelExprAbstractFVarsAtReferenceChanged,
                              hAType,
                              hAValue,
                              hABody,
                              psKernelExprInstantiateAtReferenceChanged,
                              ihTypeResult,
                              ihValueResult,
                              ihBodyResult,
                              hWholeClosed
                            ]
  | lit literal =>
      have hInst :=
        psKernelExprInstantiateAtReferenceChanged_closed_core
          (PsKernelExpr.lit literal)
          (List.cons (PsKernelExpr.fvar target) List.nil)
          offset
          hClosed
      simpa [
        psKernelExprAbstractFVarsAtReferenceChanged
      ] using hInst
  | mdata metadata body ihBody =>
      have hBodyLoose :
          psKernelExprHasLooseAt body offset = false := by
        simpa [psKernelExprHasLooseAt] using hClosed
      have ihBodyResult :=
        ihBody offset hBodyLoose
      have hWholeClosed :=
        psKernelExprInstantiateAtReferenceChanged_closed_core
          (PsKernelExpr.mdata metadata body)
          (List.cons (PsKernelExpr.fvar target) List.nil)
          offset
          hClosed
      cases hABody :
          psKernelExprAbstractFVarsAtReferenceChanged
            body
            (List.cons target List.nil)
            offset with
      | mk bodyResult bodyChanged =>
          rw [hABody] at ihBodyResult
          cases bodyChanged <;>
            simp [
              psKernelExprAbstractFVarsAtReferenceChanged,
              hABody,
              psKernelExprInstantiateAtReferenceChanged,
              ihBodyResult,
              hWholeClosed
            ]
  | proj typeName index body ihBody =>
      have hBodyLoose :
          psKernelExprHasLooseAt body offset = false := by
        simpa [psKernelExprHasLooseAt] using hClosed
      have ihBodyResult :=
        ihBody offset hBodyLoose
      have hWholeClosed :=
        psKernelExprInstantiateAtReferenceChanged_closed_core
          (PsKernelExpr.proj typeName index body)
          (List.cons (PsKernelExpr.fvar target) List.nil)
          offset
          hClosed
      cases hABody :
          psKernelExprAbstractFVarsAtReferenceChanged
            body
            (List.cons target List.nil)
            offset with
      | mk bodyResult bodyChanged =>
          rw [hABody] at ihBodyResult
          cases bodyChanged <;>
            simp [
              psKernelExprAbstractFVarsAtReferenceChanged,
              hABody,
              psKernelExprInstantiateAtReferenceChanged,
              ihBodyResult,
              hWholeClosed
            ]

theorem psKernelExprAbstractInstantiateReference_roundtrip_singleton_core
    (expr : PsKernelExpr)
    (target : PsKernelName)
    (offset : Nat)
    (hClosed :
      psKernelExprHasLooseAt expr offset = false)
    (hNameSound :
      PsKernelNameEqSoundAgainst target) :
    psKernelExprInstantiateAtReference
        (psKernelExprAbstractFVarsAtReference
          expr
          (List.cons target List.nil)
          offset)
        0
        (List.cons (PsKernelExpr.fvar target) List.nil)
        offset =
      expr := by
  have h :=
    psKernelExprAbstractInstantiateReferenceChanged_roundtrip_singleton_core
      expr target offset hClosed hNameSound
  have hFst := congrArg Prod.fst h
  simpa [
    psKernelExprAbstractFVarsAtReference,
    psKernelExprInstantiateAtReference,
    psKernelExprListIsEmpty
  ] using hFst

theorem psKernelExprAbstractInstantiate_roundtrip_singleton_core
    (expr : PsKernelExpr)
    (target : PsKernelName)
    (offset : Nat)
    (hClosed :
      psKernelExprHasLooseAt expr offset = false)
    (hNameSound :
      PsKernelNameEqSoundAgainst target) :
    psKernelExprInstantiateAt
        (psKernelExprAbstractFVarsAt
          expr
          (List.cons target List.nil)
          offset)
        0
        (List.cons (PsKernelExpr.fvar target) List.nil)
        offset =
      expr := by
  rw [
    psKernelExprAbstractFVarsAt_refines_reference_core
  ]
  rw [
    psKernelExprInstantiateAt_refines_reference_core
  ]
  exact
    psKernelExprAbstractInstantiateReference_roundtrip_singleton_core
      expr target offset hClosed hNameSound
