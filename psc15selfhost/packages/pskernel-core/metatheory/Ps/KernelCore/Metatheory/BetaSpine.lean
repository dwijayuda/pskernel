import Lean.Elab.Tactic.Omega
import Ps.KernelCore.Metatheory.SubstitutionRefinement
import Ps.KernelCore.Metatheory.ReductionCongruence
import Ps.KernelCore.Metatheory.CheckerContracts

theorem psKernelNatLt_true_of_lt
    (left right : Nat)
    (hLt : left < right) :
    psKernelNatLt left right = true := by
  have hNe : left ≠ right :=
    Nat.ne_of_lt hLt
  have hBeq :
      Nat.beq left right = false := by
    cases hEq : Nat.beq left right with
    | false => rfl
    | true =>
        exact (hNe (Nat.eq_of_beq_eq_true hEq)).elim
  have hBle :
      Nat.ble left right = true :=
    Nat.ble_eq_true_of_le (Nat.le_of_lt hLt)
  simp [psKernelNatLt, hBeq, hBle]


theorem psKernelNatLt_false_of_le
    (left right : Nat)
    (hLe : right ≤ left) :
    psKernelNatLt left right = false := by
  cases hEq : Nat.beq left right with
  | true =>
      simp [psKernelNatLt, hEq]
  | false =>
      have hBle :
          Nat.ble left right = false := by
        cases h : Nat.ble left right with
        | false => rfl
        | true =>
            have hLeftLeRight :=
              Nat.le_of_ble_eq_true h
            have hEqual :=
              Nat.le_antisymm hLeftLeRight hLe
            subst right
            simp at hEq
      simp [psKernelNatLt, hEq, hBle]


/-
Metatheory for WHNF's optimized multi-lambda beta spine.

The executable worker contracts several ordinary beta steps at once using
InstantiateRev.  This module proves the substitution algebra independently and
then relates the optimization to the ordinary beta reduction closure.
-/

theorem psKernelExprLiftLooseBVarsReferenceChanged_false_fst
    (expr : PsKernelExpr)
    (start amount : Nat)
    (result : PsKernelExpr)
    (hRun :
      psKernelExprLiftLooseBVarsReferenceChanged
          expr start amount =
        Prod.mk result false) :
    result = expr := by
  have hFst := congrArg Prod.fst hRun
  have hSnd := congrArg Prod.snd hRun
  cases amount with
  | zero =>
      rw [
        psKernelExprLiftLooseBVarsReferenceChanged_zero_amount
      ] at hFst
      exact hFst.symm
  | succ remaining =>
      cases expr with
      | bvar index =>
          cases hGe : psKernelNatGe index start <;>
            simp [
              psKernelExprLiftLooseBVarsReferenceChanged,
              hGe
            ] at hFst hSnd
          exact hFst.symm
      | fvar name =>
          simp [psKernelExprLiftLooseBVarsReferenceChanged] at hFst
          exact hFst.symm
      | mvar name =>
          simp [psKernelExprLiftLooseBVarsReferenceChanged] at hFst
          exact hFst.symm
      | sort level =>
          simp [psKernelExprLiftLooseBVarsReferenceChanged] at hFst
          exact hFst.symm
      | const name levels =>
          simp [psKernelExprLiftLooseBVarsReferenceChanged] at hFst
          exact hFst.symm
      | lit literal =>
          simp [psKernelExprLiftLooseBVarsReferenceChanged] at hFst
          exact hFst.symm
      | app fn arg =>
          cases hFn :
              psKernelExprLiftLooseBVarsReferenceChanged
                fn start (Nat.succ remaining) with
          | mk fnResult fnChanged =>
              cases hArg :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    arg start (Nat.succ remaining) with
              | mk argResult argChanged =>
                  cases fnChanged <;>
                    cases argChanged <;>
                    simp [
                      psKernelExprLiftLooseBVarsReferenceChanged,
                      hFn,
                      hArg
                    ] at hFst hSnd
                  exact hFst.symm
      | lam name type body binderInfo =>
          cases hType :
              psKernelExprLiftLooseBVarsReferenceChanged
                type start (Nat.succ remaining) with
          | mk typeResult typeChanged =>
              cases hBody :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    body (Nat.succ start) (Nat.succ remaining) with
              | mk bodyResult bodyChanged =>
                  cases typeChanged <;>
                    cases bodyChanged <;>
                    simp [
                      psKernelExprLiftLooseBVarsReferenceChanged,
                      hType,
                      hBody
                    ] at hFst hSnd
                  exact hFst.symm
      | forallE name type body binderInfo =>
          cases hType :
              psKernelExprLiftLooseBVarsReferenceChanged
                type start (Nat.succ remaining) with
          | mk typeResult typeChanged =>
              cases hBody :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    body (Nat.succ start) (Nat.succ remaining) with
              | mk bodyResult bodyChanged =>
                  cases typeChanged <;>
                    cases bodyChanged <;>
                    simp [
                      psKernelExprLiftLooseBVarsReferenceChanged,
                      hType,
                      hBody
                    ] at hFst hSnd
                  exact hFst.symm
      | letE name type value body nondep =>
          cases hType :
              psKernelExprLiftLooseBVarsReferenceChanged
                type start (Nat.succ remaining) with
          | mk typeResult typeChanged =>
              cases hValue :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    value start (Nat.succ remaining) with
              | mk valueResult valueChanged =>
                  cases hBody :
                      psKernelExprLiftLooseBVarsReferenceChanged
                        body (Nat.succ start) (Nat.succ remaining) with
                  | mk bodyResult bodyChanged =>
                      cases typeChanged <;>
                        cases valueChanged <;>
                        cases bodyChanged <;>
                        simp [
                          psKernelExprLiftLooseBVarsReferenceChanged,
                          hType,
                          hValue,
                          hBody
                        ] at hFst hSnd
                      exact hFst.symm
      | mdata metadata body =>
          cases hBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body start (Nat.succ remaining) with
          | mk bodyResult bodyChanged =>
              cases bodyChanged <;>
                simp [
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hBody
                ] at hFst hSnd
              exact hFst.symm
      | proj typeName index body =>
          cases hBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body start (Nat.succ remaining) with
          | mk bodyResult bodyChanged =>
              cases bodyChanged <;>
                simp [
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hBody
                ] at hFst hSnd
              exact hFst.symm


theorem psKernelExprInstantiateAtReferenceChanged_false_fst
    (expr : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat)
    (result : PsKernelExpr)
    (hRun :
      psKernelExprInstantiateAtReferenceChanged
          expr start subst offset =
        Prod.mk result false) :
    result = expr := by
  have hFst := congrArg Prod.fst hRun
  have hSnd := congrArg Prod.snd hRun
  cases expr with
  | bvar index =>
      cases hBefore :
          psKernelNatLt index (Nat.add start offset) with
      | true =>
          simp only [
            psKernelExprInstantiateAtReferenceChanged
          ] at hFst
          rw [hBefore] at hFst
          simp at hFst
          exact hFst.symm
      | false =>
          cases hGet :
              psKernelExprListGet
                subst
                (Nat.sub index (Nat.add start offset)) with
          | some replacement =>
              simp only [
                psKernelExprInstantiateAtReferenceChanged
              ] at hSnd
              rw [hBefore] at hSnd
              simp only [
                Bool.false_eq_true,
                ite_false
              ] at hSnd
              rw [hGet] at hSnd
              simp at hSnd
          | none =>
              cases hEmpty :
                  psKernelExprListIsEmpty subst with
              | true =>
                  simp only [
                    psKernelExprInstantiateAtReferenceChanged
                  ] at hFst
                  rw [hBefore] at hFst
                  simp only [
                    Bool.false_eq_true,
                    ite_false
                  ] at hFst
                  rw [hGet] at hFst
                  rw [hEmpty] at hFst
                  simp at hFst
                  exact hFst.symm
              | false =>
                  simp only [
                    psKernelExprInstantiateAtReferenceChanged
                  ] at hSnd
                  rw [hBefore] at hSnd
                  simp only [
                    Bool.false_eq_true,
                    ite_false
                  ] at hSnd
                  rw [hGet] at hSnd
                  rw [hEmpty] at hSnd
                  simp at hSnd
  | fvar name =>
      simp [psKernelExprInstantiateAtReferenceChanged] at hFst
      exact hFst.symm
  | mvar name =>
      simp [psKernelExprInstantiateAtReferenceChanged] at hFst
      exact hFst.symm
  | sort level =>
      simp [psKernelExprInstantiateAtReferenceChanged] at hFst
      exact hFst.symm
  | const name levels =>
      simp [psKernelExprInstantiateAtReferenceChanged] at hFst
      exact hFst.symm
  | lit literal =>
      simp [psKernelExprInstantiateAtReferenceChanged] at hFst
      exact hFst.symm
  | app fn arg =>
      cases hFn :
          psKernelExprInstantiateAtReferenceChanged
            fn start subst offset with
      | mk fnResult fnChanged =>
          cases hArg :
              psKernelExprInstantiateAtReferenceChanged
                arg start subst offset with
          | mk argResult argChanged =>
              cases fnChanged <;>
                cases argChanged <;>
                simp [
                  psKernelExprInstantiateAtReferenceChanged,
                  hFn,
                  hArg
                ] at hFst hSnd
              exact hFst.symm
  | lam name type body binderInfo =>
      cases hType :
          psKernelExprInstantiateAtReferenceChanged
            type start subst offset with
      | mk typeResult typeChanged =>
          cases hBody :
              psKernelExprInstantiateAtReferenceChanged
                body start subst (Nat.succ offset) with
          | mk bodyResult bodyChanged =>
              cases typeChanged <;>
                cases bodyChanged <;>
                simp [
                  psKernelExprInstantiateAtReferenceChanged,
                  hType,
                  hBody
                ] at hFst hSnd
              exact hFst.symm
  | forallE name type body binderInfo =>
      cases hType :
          psKernelExprInstantiateAtReferenceChanged
            type start subst offset with
      | mk typeResult typeChanged =>
          cases hBody :
              psKernelExprInstantiateAtReferenceChanged
                body start subst (Nat.succ offset) with
          | mk bodyResult bodyChanged =>
              cases typeChanged <;>
                cases bodyChanged <;>
                simp [
                  psKernelExprInstantiateAtReferenceChanged,
                  hType,
                  hBody
                ] at hFst hSnd
              exact hFst.symm
  | letE name type value body nondep =>
      cases hType :
          psKernelExprInstantiateAtReferenceChanged
            type start subst offset with
      | mk typeResult typeChanged =>
          cases hValue :
              psKernelExprInstantiateAtReferenceChanged
                value start subst offset with
          | mk valueResult valueChanged =>
              cases hBody :
                  psKernelExprInstantiateAtReferenceChanged
                    body start subst (Nat.succ offset) with
              | mk bodyResult bodyChanged =>
                  cases typeChanged <;>
                    cases valueChanged <;>
                    cases bodyChanged <;>
                    simp [
                      psKernelExprInstantiateAtReferenceChanged,
                      hType,
                      hValue,
                      hBody
                    ] at hFst hSnd
                  exact hFst.symm
  | mdata metadata body =>
      cases hBody :
          psKernelExprInstantiateAtReferenceChanged
            body start subst offset with
      | mk bodyResult bodyChanged =>
          cases bodyChanged <;>
            simp [
              psKernelExprInstantiateAtReferenceChanged,
              hBody
            ] at hFst hSnd
          exact hFst.symm
  | proj typeName index body =>
      cases hBody :
          psKernelExprInstantiateAtReferenceChanged
            body start subst offset with
      | mk bodyResult bodyChanged =>
          cases bodyChanged <;>
            simp [
              psKernelExprInstantiateAtReferenceChanged,
              hBody
            ] at hFst hSnd
          exact hFst.symm

theorem psKernelExprLiftLooseBVarsReference_app
    (fn arg : PsKernelExpr)
    (start amount : Nat) :
    psKernelExprLiftLooseBVarsReference
        (PsKernelExpr.app fn arg)
        start amount =
      PsKernelExpr.app
        (psKernelExprLiftLooseBVarsReference fn start amount)
        (psKernelExprLiftLooseBVarsReference arg start amount) := by
  cases amount with
  | zero =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged_zero_amount
      ]
  | succ remaining =>
      cases hFn :
          psKernelExprLiftLooseBVarsReferenceChanged
            fn start (Nat.succ remaining) with
      | mk fnResult fnChanged =>
          cases hArg :
              psKernelExprLiftLooseBVarsReferenceChanged
                arg start (Nat.succ remaining) with
          | mk argResult argChanged =>
              cases fnChanged with
              | false =>
                  cases argChanged with
                  | false =>
                      have hFnOrig :=
                        psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                          fn start (Nat.succ remaining)
                          fnResult hFn
                      have hArgOrig :=
                        psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                          arg start (Nat.succ remaining)
                          argResult hArg
                      simp [
                        psKernelExprLiftLooseBVarsReference,
                        psKernelExprLiftLooseBVarsReferenceChanged,
                        hFn,
                        hArg,
                        hFnOrig,
                        hArgOrig
                      ]
                  | true =>
                      simp [
                        psKernelExprLiftLooseBVarsReference,
                        psKernelExprLiftLooseBVarsReferenceChanged,
                        hFn,
                        hArg
                      ]
              | true =>
                  cases argChanged <;>
                    simp [
                      psKernelExprLiftLooseBVarsReference,
                      psKernelExprLiftLooseBVarsReferenceChanged,
                      hFn,
                      hArg
                    ]


theorem psKernelExprLiftLooseBVarsReference_lam
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (start amount : Nat) :
    psKernelExprLiftLooseBVarsReference
        (PsKernelExpr.lam name type body binderInfo)
        start amount =
      PsKernelExpr.lam
        name
        (psKernelExprLiftLooseBVarsReference type start amount)
        (psKernelExprLiftLooseBVarsReference
          body (Nat.succ start) amount)
        binderInfo := by
  cases amount with
  | zero =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged_zero_amount
      ]
  | succ remaining =>
      cases hType :
          psKernelExprLiftLooseBVarsReferenceChanged
            type start (Nat.succ remaining) with
      | mk typeResult typeChanged =>
          cases hBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body (Nat.succ start) (Nat.succ remaining) with
          | mk bodyResult bodyChanged =>
              cases typeChanged with
              | false =>
                  cases bodyChanged with
                  | false =>
                      have hTypeOrig :=
                        psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                          type start (Nat.succ remaining)
                          typeResult hType
                      have hBodyOrig :=
                        psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                          body (Nat.succ start) (Nat.succ remaining)
                          bodyResult hBody
                      simp [
                        psKernelExprLiftLooseBVarsReference,
                        psKernelExprLiftLooseBVarsReferenceChanged,
                        hType,
                        hBody,
                        hTypeOrig,
                        hBodyOrig
                      ]
                  | true =>
                      simp [
                        psKernelExprLiftLooseBVarsReference,
                        psKernelExprLiftLooseBVarsReferenceChanged,
                        hType,
                        hBody
                      ]
              | true =>
                  cases bodyChanged <;>
                    simp [
                      psKernelExprLiftLooseBVarsReference,
                      psKernelExprLiftLooseBVarsReferenceChanged,
                      hType,
                      hBody
                    ]


theorem psKernelExprLiftLooseBVarsReference_forallE
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (start amount : Nat) :
    psKernelExprLiftLooseBVarsReference
        (PsKernelExpr.forallE name type body binderInfo)
        start amount =
      PsKernelExpr.forallE
        name
        (psKernelExprLiftLooseBVarsReference type start amount)
        (psKernelExprLiftLooseBVarsReference
          body (Nat.succ start) amount)
        binderInfo := by
  cases amount with
  | zero =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged_zero_amount
      ]
  | succ remaining =>
      cases hType :
          psKernelExprLiftLooseBVarsReferenceChanged
            type start (Nat.succ remaining) with
      | mk typeResult typeChanged =>
          cases hBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body (Nat.succ start) (Nat.succ remaining) with
          | mk bodyResult bodyChanged =>
              cases typeChanged with
              | false =>
                  cases bodyChanged with
                  | false =>
                      have hTypeOrig :=
                        psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                          type start (Nat.succ remaining)
                          typeResult hType
                      have hBodyOrig :=
                        psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                          body (Nat.succ start) (Nat.succ remaining)
                          bodyResult hBody
                      simp [
                        psKernelExprLiftLooseBVarsReference,
                        psKernelExprLiftLooseBVarsReferenceChanged,
                        hType,
                        hBody,
                        hTypeOrig,
                        hBodyOrig
                      ]
                  | true =>
                      simp [
                        psKernelExprLiftLooseBVarsReference,
                        psKernelExprLiftLooseBVarsReferenceChanged,
                        hType,
                        hBody
                      ]
              | true =>
                  cases bodyChanged <;>
                    simp [
                      psKernelExprLiftLooseBVarsReference,
                      psKernelExprLiftLooseBVarsReferenceChanged,
                      hType,
                      hBody
                    ]


theorem psKernelExprLiftLooseBVarsReference_letE
    (name : PsKernelName)
    (type value body : PsKernelExpr)
    (nondep : Bool)
    (start amount : Nat) :
    psKernelExprLiftLooseBVarsReference
        (PsKernelExpr.letE name type value body nondep)
        start amount =
      PsKernelExpr.letE
        name
        (psKernelExprLiftLooseBVarsReference type start amount)
        (psKernelExprLiftLooseBVarsReference value start amount)
        (psKernelExprLiftLooseBVarsReference
          body (Nat.succ start) amount)
        nondep := by
  cases amount with
  | zero =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged_zero_amount
      ]
  | succ remaining =>
      cases hType :
          psKernelExprLiftLooseBVarsReferenceChanged
            type start (Nat.succ remaining) with
      | mk typeResult typeChanged =>
          cases hValue :
              psKernelExprLiftLooseBVarsReferenceChanged
                value start (Nat.succ remaining) with
          | mk valueResult valueChanged =>
              cases hBody :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    body (Nat.succ start) (Nat.succ remaining) with
              | mk bodyResult bodyChanged =>
                  cases typeChanged with
                  | false =>
                      cases valueChanged with
                      | false =>
                          cases bodyChanged with
                          | false =>
                              have hTypeOrig :=
                                psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                                  type start (Nat.succ remaining)
                                  typeResult hType
                              have hValueOrig :=
                                psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                                  value start (Nat.succ remaining)
                                  valueResult hValue
                              have hBodyOrig :=
                                psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                                  body (Nat.succ start) (Nat.succ remaining)
                                  bodyResult hBody
                              simp [
                                psKernelExprLiftLooseBVarsReference,
                                psKernelExprLiftLooseBVarsReferenceChanged,
                                hType,
                                hValue,
                                hBody,
                                hTypeOrig,
                                hValueOrig,
                                hBodyOrig
                              ]
                          | true =>
                              simp [
                                psKernelExprLiftLooseBVarsReference,
                                psKernelExprLiftLooseBVarsReferenceChanged,
                                hType,
                                hValue,
                                hBody
                              ]
                      | true =>
                          cases bodyChanged <;>
                            simp [
                              psKernelExprLiftLooseBVarsReference,
                              psKernelExprLiftLooseBVarsReferenceChanged,
                              hType,
                              hValue,
                              hBody
                            ]
                  | true =>
                      cases valueChanged <;>
                        cases bodyChanged <;>
                        simp [
                          psKernelExprLiftLooseBVarsReference,
                          psKernelExprLiftLooseBVarsReferenceChanged,
                          hType,
                          hValue,
                          hBody
                        ]


theorem psKernelExprLiftLooseBVarsReference_mdata
    (metadata : Nat)
    (body : PsKernelExpr)
    (start amount : Nat) :
    psKernelExprLiftLooseBVarsReference
        (PsKernelExpr.mdata metadata body)
        start amount =
      PsKernelExpr.mdata
        metadata
        (psKernelExprLiftLooseBVarsReference body start amount) := by
  cases amount with
  | zero =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged_zero_amount
      ]
  | succ remaining =>
      cases hBody :
          psKernelExprLiftLooseBVarsReferenceChanged
            body start (Nat.succ remaining) with
      | mk bodyResult bodyChanged =>
          cases bodyChanged with
          | false =>
              have hBodyOrig :=
                psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                  body start (Nat.succ remaining)
                  bodyResult hBody
              simp [
                psKernelExprLiftLooseBVarsReference,
                psKernelExprLiftLooseBVarsReferenceChanged,
                hBody,
                hBodyOrig
              ]
          | true =>
              simp [
                psKernelExprLiftLooseBVarsReference,
                psKernelExprLiftLooseBVarsReferenceChanged,
                hBody
              ]


theorem psKernelExprLiftLooseBVarsReference_proj
    (typeName : PsKernelName)
    (index : Nat)
    (body : PsKernelExpr)
    (start amount : Nat) :
    psKernelExprLiftLooseBVarsReference
        (PsKernelExpr.proj typeName index body)
        start amount =
      PsKernelExpr.proj
        typeName
        index
        (psKernelExprLiftLooseBVarsReference body start amount) := by
  cases amount with
  | zero =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged_zero_amount
      ]
  | succ remaining =>
      cases hBody :
          psKernelExprLiftLooseBVarsReferenceChanged
            body start (Nat.succ remaining) with
      | mk bodyResult bodyChanged =>
          cases bodyChanged with
          | false =>
              have hBodyOrig :=
                psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                  body start (Nat.succ remaining)
                  bodyResult hBody
              simp [
                psKernelExprLiftLooseBVarsReference,
                psKernelExprLiftLooseBVarsReferenceChanged,
                hBody,
                hBodyOrig
              ]
          | true =>
              simp [
                psKernelExprLiftLooseBVarsReference,
                psKernelExprLiftLooseBVarsReferenceChanged,
                hBody
              ]


theorem psKernelExprInstantiateAtReference_app
    (fn arg : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAtReference
        (PsKernelExpr.app fn arg)
        start subst offset =
      PsKernelExpr.app
        (psKernelExprInstantiateAtReference fn start subst offset)
        (psKernelExprInstantiateAtReference arg start subst offset) := by
  cases hEmpty : psKernelExprListIsEmpty subst with
  | true =>
      simp [
        psKernelExprInstantiateAtReference,
        hEmpty
      ]
  | false =>
      cases hFn :
          psKernelExprInstantiateAtReferenceChanged
            fn start subst offset with
      | mk fnResult fnChanged =>
          cases hArg :
              psKernelExprInstantiateAtReferenceChanged
                arg start subst offset with
          | mk argResult argChanged =>
              cases fnChanged with
              | false =>
                  cases argChanged with
                  | false =>
                      have hFnOrig :=
                        psKernelExprInstantiateAtReferenceChanged_false_fst
                          fn start subst offset fnResult hFn
                      have hArgOrig :=
                        psKernelExprInstantiateAtReferenceChanged_false_fst
                          arg start subst offset argResult hArg
                      simp [
                        psKernelExprInstantiateAtReference,
                        hEmpty,
                        psKernelExprInstantiateAtReferenceChanged,
                        hFn,
                        hArg,
                        hFnOrig,
                        hArgOrig
                      ]
                  | true =>
                      simp [
                        psKernelExprInstantiateAtReference,
                        hEmpty,
                        psKernelExprInstantiateAtReferenceChanged,
                        hFn,
                        hArg
                      ]
              | true =>
                  cases argChanged <;>
                    simp [
                      psKernelExprInstantiateAtReference,
                      hEmpty,
                      psKernelExprInstantiateAtReferenceChanged,
                      hFn,
                      hArg
                    ]


theorem psKernelExprInstantiateAtReference_lam
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAtReference
        (PsKernelExpr.lam name type body binderInfo)
        start subst offset =
      PsKernelExpr.lam
        name
        (psKernelExprInstantiateAtReference
          type start subst offset)
        (psKernelExprInstantiateAtReference
          body start subst (Nat.succ offset))
        binderInfo := by
  cases hEmpty : psKernelExprListIsEmpty subst with
  | true =>
      simp [psKernelExprInstantiateAtReference, hEmpty]
  | false =>
      cases hType :
          psKernelExprInstantiateAtReferenceChanged
            type start subst offset with
      | mk typeResult typeChanged =>
          cases hBody :
              psKernelExprInstantiateAtReferenceChanged
                body start subst (Nat.succ offset) with
          | mk bodyResult bodyChanged =>
              cases typeChanged with
              | false =>
                  cases bodyChanged with
                  | false =>
                      have hTypeOrig :=
                        psKernelExprInstantiateAtReferenceChanged_false_fst
                          type start subst offset typeResult hType
                      have hBodyOrig :=
                        psKernelExprInstantiateAtReferenceChanged_false_fst
                          body start subst (Nat.succ offset)
                          bodyResult hBody
                      simp [
                        psKernelExprInstantiateAtReference,
                        hEmpty,
                        psKernelExprInstantiateAtReferenceChanged,
                        hType,
                        hBody,
                        hTypeOrig,
                        hBodyOrig
                      ]
                  | true =>
                      simp [
                        psKernelExprInstantiateAtReference,
                        hEmpty,
                        psKernelExprInstantiateAtReferenceChanged,
                        hType,
                        hBody
                      ]
              | true =>
                  cases bodyChanged <;>
                    simp [
                      psKernelExprInstantiateAtReference,
                      hEmpty,
                      psKernelExprInstantiateAtReferenceChanged,
                      hType,
                      hBody
                    ]


theorem psKernelExprInstantiateAtReference_forallE
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAtReference
        (PsKernelExpr.forallE name type body binderInfo)
        start subst offset =
      PsKernelExpr.forallE
        name
        (psKernelExprInstantiateAtReference
          type start subst offset)
        (psKernelExprInstantiateAtReference
          body start subst (Nat.succ offset))
        binderInfo := by
  cases hEmpty : psKernelExprListIsEmpty subst with
  | true =>
      simp [psKernelExprInstantiateAtReference, hEmpty]
  | false =>
      cases hType :
          psKernelExprInstantiateAtReferenceChanged
            type start subst offset with
      | mk typeResult typeChanged =>
          cases hBody :
              psKernelExprInstantiateAtReferenceChanged
                body start subst (Nat.succ offset) with
          | mk bodyResult bodyChanged =>
              cases typeChanged with
              | false =>
                  cases bodyChanged with
                  | false =>
                      have hTypeOrig :=
                        psKernelExprInstantiateAtReferenceChanged_false_fst
                          type start subst offset typeResult hType
                      have hBodyOrig :=
                        psKernelExprInstantiateAtReferenceChanged_false_fst
                          body start subst (Nat.succ offset)
                          bodyResult hBody
                      simp [
                        psKernelExprInstantiateAtReference,
                        hEmpty,
                        psKernelExprInstantiateAtReferenceChanged,
                        hType,
                        hBody,
                        hTypeOrig,
                        hBodyOrig
                      ]
                  | true =>
                      simp [
                        psKernelExprInstantiateAtReference,
                        hEmpty,
                        psKernelExprInstantiateAtReferenceChanged,
                        hType,
                        hBody
                      ]
              | true =>
                  cases bodyChanged <;>
                    simp [
                      psKernelExprInstantiateAtReference,
                      hEmpty,
                      psKernelExprInstantiateAtReferenceChanged,
                      hType,
                      hBody
                    ]


theorem psKernelExprInstantiateAtReference_letE
    (name : PsKernelName)
    (type value body : PsKernelExpr)
    (nondep : Bool)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAtReference
        (PsKernelExpr.letE name type value body nondep)
        start subst offset =
      PsKernelExpr.letE
        name
        (psKernelExprInstantiateAtReference type start subst offset)
        (psKernelExprInstantiateAtReference value start subst offset)
        (psKernelExprInstantiateAtReference
          body start subst (Nat.succ offset))
        nondep := by
  cases hEmpty : psKernelExprListIsEmpty subst with
  | true =>
      simp [psKernelExprInstantiateAtReference, hEmpty]
  | false =>
      cases hType :
          psKernelExprInstantiateAtReferenceChanged
            type start subst offset with
      | mk typeResult typeChanged =>
          cases hValue :
              psKernelExprInstantiateAtReferenceChanged
                value start subst offset with
          | mk valueResult valueChanged =>
              cases hBody :
                  psKernelExprInstantiateAtReferenceChanged
                    body start subst (Nat.succ offset) with
              | mk bodyResult bodyChanged =>
                  cases typeChanged with
                  | false =>
                      cases valueChanged with
                      | false =>
                          cases bodyChanged with
                          | false =>
                              have hTypeOrig :=
                                psKernelExprInstantiateAtReferenceChanged_false_fst
                                  type start subst offset typeResult hType
                              have hValueOrig :=
                                psKernelExprInstantiateAtReferenceChanged_false_fst
                                  value start subst offset valueResult hValue
                              have hBodyOrig :=
                                psKernelExprInstantiateAtReferenceChanged_false_fst
                                  body start subst (Nat.succ offset)
                                  bodyResult hBody
                              simp [
                                psKernelExprInstantiateAtReference,
                                hEmpty,
                                psKernelExprInstantiateAtReferenceChanged,
                                hType,
                                hValue,
                                hBody,
                                hTypeOrig,
                                hValueOrig,
                                hBodyOrig
                              ]
                          | true =>
                              simp [
                                psKernelExprInstantiateAtReference,
                                hEmpty,
                                psKernelExprInstantiateAtReferenceChanged,
                                hType,
                                hValue,
                                hBody
                              ]
                      | true =>
                          cases bodyChanged <;>
                            simp [
                              psKernelExprInstantiateAtReference,
                              hEmpty,
                              psKernelExprInstantiateAtReferenceChanged,
                              hType,
                              hValue,
                              hBody
                            ]
                  | true =>
                      cases valueChanged <;>
                        cases bodyChanged <;>
                        simp [
                          psKernelExprInstantiateAtReference,
                          hEmpty,
                          psKernelExprInstantiateAtReferenceChanged,
                          hType,
                          hValue,
                          hBody
                        ]


theorem psKernelExprInstantiateAtReference_mdata
    (metadata : Nat)
    (body : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAtReference
        (PsKernelExpr.mdata metadata body)
        start subst offset =
      PsKernelExpr.mdata
        metadata
        (psKernelExprInstantiateAtReference
          body start subst offset) := by
  cases hEmpty : psKernelExprListIsEmpty subst with
  | true =>
      simp [psKernelExprInstantiateAtReference, hEmpty]
  | false =>
      cases hBody :
          psKernelExprInstantiateAtReferenceChanged
            body start subst offset with
      | mk bodyResult bodyChanged =>
          cases bodyChanged with
          | false =>
              have hBodyOrig :=
                psKernelExprInstantiateAtReferenceChanged_false_fst
                  body start subst offset bodyResult hBody
              simp [
                psKernelExprInstantiateAtReference,
                hEmpty,
                psKernelExprInstantiateAtReferenceChanged,
                hBody,
                hBodyOrig
              ]
          | true =>
              simp [
                psKernelExprInstantiateAtReference,
                hEmpty,
                psKernelExprInstantiateAtReferenceChanged,
                hBody
              ]


theorem psKernelExprInstantiateAtReference_proj
    (typeName : PsKernelName)
    (index : Nat)
    (body : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAtReference
        (PsKernelExpr.proj typeName index body)
        start subst offset =
      PsKernelExpr.proj
        typeName
        index
        (psKernelExprInstantiateAtReference
          body start subst offset) := by
  cases hEmpty : psKernelExprListIsEmpty subst with
  | true =>
      simp [psKernelExprInstantiateAtReference, hEmpty]
  | false =>
      cases hBody :
          psKernelExprInstantiateAtReferenceChanged
            body start subst offset with
      | mk bodyResult bodyChanged =>
          cases bodyChanged with
          | false =>
              have hBodyOrig :=
                psKernelExprInstantiateAtReferenceChanged_false_fst
                  body start subst offset bodyResult hBody
              simp [
                psKernelExprInstantiateAtReference,
                hEmpty,
                psKernelExprInstantiateAtReferenceChanged,
                hBody,
                hBodyOrig
              ]
          | true =>
              simp [
                psKernelExprInstantiateAtReference,
                hEmpty,
                psKernelExprInstantiateAtReferenceChanged,
                hBody
              ]


theorem psKernelExprLiftOne_then_instantiateReference_cancel
    (expr replacement : PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAtReference
        (psKernelExprLiftLooseBVarsReference expr offset 1)
        0
        (List.cons replacement List.nil)
        offset =
      expr := by
  induction expr generalizing offset with
  | bvar index =>
      cases hGe : psKernelNatGe index offset with
      | false =>
          have hBleFalse :
              Nat.ble offset index = false := by
            simpa [psKernelNatGe] using hGe
          have hNotLe : ¬ offset ≤ index := by
            intro hLe
            have hBleTrue :
                Nat.ble offset index = true :=
              Nat.ble_eq_true_of_le hLe
            rw [hBleTrue] at hBleFalse
            contradiction
          have hLt : index < offset :=
            Nat.lt_of_not_ge hNotLe
          have hBeq :
              Nat.beq index offset = false := by
            cases hEq : Nat.beq index offset with
            | false => rfl
            | true =>
                have hEqual := Nat.eq_of_beq_eq_true hEq
                subst offset
                exact (Nat.lt_irrefl index hLt).elim
          have hBle :
              Nat.ble index offset = true :=
            Nat.ble_eq_true_of_le (Nat.le_of_lt hLt)
          have hNatLt :
              psKernelNatLt index offset = true := by
            simp [psKernelNatLt, hBeq, hBle]
          have hLift :
              psKernelExprLiftLooseBVarsReference
                  (PsKernelExpr.bvar index)
                  offset
                  1 =
                PsKernelExpr.bvar index := by
            simp [
              psKernelExprLiftLooseBVarsReference,
              psKernelExprLiftLooseBVarsReferenceChanged,
              hGe
            ]
          rw [hLift]
          simp [
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty,
            hNatLt
          ]
      | true =>
          have hBleTrue :
              Nat.ble offset index = true := by
            simpa [psKernelNatGe] using hGe
          have hLe : offset ≤ index :=
            Nat.le_of_ble_eq_true hBleTrue
          have hGt : offset < Nat.add index 1 :=
            Nat.lt_succ_of_le hLe
          have hBeq :
              Nat.beq (Nat.add index 1) offset = false := by
            cases hEq :
                Nat.beq (Nat.add index 1) offset with
            | false => rfl
            | true =>
                have hEqual :
                    Nat.add index 1 = offset :=
                  Nat.eq_of_beq_eq_true hEq
                rw [hEqual] at hGt
                exact (Nat.lt_irrefl offset hGt).elim
          have hBle :
              Nat.ble (Nat.add index 1) offset = false := by
            cases hEq :
                Nat.ble (Nat.add index 1) offset with
            | false => rfl
            | true =>
                have hWrong :
                    Nat.add index 1 ≤ offset :=
                  Nat.le_of_ble_eq_true hEq
                exact (Nat.not_le_of_gt hGt hWrong).elim
          have hNatLt :
              psKernelNatLt (Nat.add index 1) offset = false := by
            simp [psKernelNatLt, hBeq, hBle]
          have hRelative :
              Nat.sub (Nat.add index 1) offset =
                Nat.succ (Nat.sub index offset) := by
            have hAssoc :=
              Nat.add_sub_assoc hLe 1
            simpa [Nat.add_comm] using hAssoc
          have hLift :
              psKernelExprLiftLooseBVarsReference
                  (PsKernelExpr.bvar index)
                  offset
                  1 =
                PsKernelExpr.bvar (Nat.add index 1) := by
            simp [
              psKernelExprLiftLooseBVarsReference,
              psKernelExprLiftLooseBVarsReferenceChanged,
              hGe
            ]
          have hNatLt0 :
              psKernelNatLt
                  (Nat.add index 1)
                  (Nat.add 0 offset) =
                false := by
            simpa using hNatLt
          have hRelative0 :
              Nat.sub
                  (Nat.add index 1)
                  (Nat.add 0 offset) =
                Nat.succ (Nat.sub index offset) := by
            simpa using hRelative
          rw [hLift]
          simp only [
            psKernelExprInstantiateAtReference,
            psKernelExprListIsEmpty,
            Bool.false_eq_true,
            if_false
          ]
          simp only [
            psKernelExprInstantiateAtReferenceChanged
          ]
          rw [hNatLt0]
          simp only [
            Bool.false_eq_true,
            ite_false
          ]
          rw [hRelative0]
          simp [
            psKernelExprListGet,
            psKernelExprListLength,
            psKernelExprListIsEmpty
          ]
  | fvar name =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged,
        psKernelExprInstantiateAtReference,
        psKernelExprInstantiateAtReferenceChanged,
        psKernelExprListIsEmpty
      ]
  | mvar name =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged,
        psKernelExprInstantiateAtReference,
        psKernelExprInstantiateAtReferenceChanged,
        psKernelExprListIsEmpty
      ]
  | sort level =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged,
        psKernelExprInstantiateAtReference,
        psKernelExprInstantiateAtReferenceChanged,
        psKernelExprListIsEmpty
      ]
  | const name levels =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged,
        psKernelExprInstantiateAtReference,
        psKernelExprInstantiateAtReferenceChanged,
        psKernelExprListIsEmpty
      ]
  | lit literal =>
      simp [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged,
        psKernelExprInstantiateAtReference,
        psKernelExprInstantiateAtReferenceChanged,
        psKernelExprListIsEmpty
      ]
  | app fn arg ihFn ihArg =>
      rw [psKernelExprLiftLooseBVarsReference_app]
      rw [psKernelExprInstantiateAtReference_app]
      rw [ihFn offset, ihArg offset]
  | lam name type body binderInfo ihType ihBody =>
      rw [psKernelExprLiftLooseBVarsReference_lam]
      rw [psKernelExprInstantiateAtReference_lam]
      rw [ihType offset, ihBody (Nat.succ offset)]
  | forallE name type body binderInfo ihType ihBody =>
      rw [psKernelExprLiftLooseBVarsReference_forallE]
      rw [psKernelExprInstantiateAtReference_forallE]
      rw [ihType offset, ihBody (Nat.succ offset)]
  | letE name type value body nondep ihType ihValue ihBody =>
      rw [psKernelExprLiftLooseBVarsReference_letE]
      rw [psKernelExprInstantiateAtReference_letE]
      rw [
        ihType offset,
        ihValue offset,
        ihBody (Nat.succ offset)
      ]
  | mdata metadata body ihBody =>
      rw [psKernelExprLiftLooseBVarsReference_mdata]
      rw [psKernelExprInstantiateAtReference_mdata]
      rw [ihBody offset]
  | proj typeName index body ihBody =>
      rw [psKernelExprLiftLooseBVarsReference_proj]
      rw [psKernelExprInstantiateAtReference_proj]
      rw [ihBody offset]

theorem psKernelExprLiftOne_then_instantiate_cancel
    (expr replacement : PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAt
        (psKernelExprLiftLooseBVars expr offset 1)
        0
        (List.cons replacement List.nil)
        offset =
      expr := by
  rw [psKernelExprLiftLooseBVars_refines_reference_core]
  rw [psKernelExprInstantiateAt_refines_reference_core]
  exact
    psKernelExprLiftOne_then_instantiateReference_cancel
      expr replacement offset


theorem psKernelExprInstantiateRevReference_singleton
    (expr replacement : PsKernelExpr) :
    psKernelExprInstantiateRevReference
        expr
        (List.cons replacement List.nil) =
      psKernelExprInstantiate1Reference
        expr
        replacement := by
  cases hLoose : psKernelExprHasLooseBVar expr with
  | true =>
      simp [
        psKernelExprInstantiateRevReference,
        psKernelExprInstantiate1Reference,
        psKernelExprInstantiateReference,
        psKernelExprListReverse,
        psKernelExprListReverseWorker,
        hLoose
      ]
  | false =>
      have hClosed :
          psKernelExprHasLooseAt expr 0 = false := by
        simpa [psKernelExprHasLooseBVar] using hLoose
      have hInst :=
        psKernelExprInstantiateAtReference_closed_core
          expr
          (List.cons replacement List.nil)
          0
          hClosed
      simpa [
        psKernelExprInstantiateRevReference,
        psKernelExprInstantiateReference,
        psKernelExprInstantiate1Reference,
        psKernelExprListReverse,
        psKernelExprListReverseWorker,
        hLoose
      ] using hInst


theorem psKernelExprInstantiateRev_singleton
    (expr replacement : PsKernelExpr) :
    psKernelExprInstantiateRev
        expr
        (List.cons replacement List.nil) =
      psKernelExprInstantiate1
        expr
        replacement := by
  rw [psKernelExprInstantiateRev_refines_reference_core]
  rw [psKernelExprInstantiate1_refines_reference_core]
  exact
    psKernelExprInstantiateRevReference_singleton
      expr replacement


theorem psKernelExprListGet_none_length_le
    (values : List PsKernelExpr)
    (index : Nat)
    (hGet :
      psKernelExprListGet values index = Option.none) :
    psKernelExprListLength values ≤ index := by
  induction values generalizing index with
  | nil =>
      simp [psKernelExprListLength]
  | cons head tail ih =>
      cases index with
      | zero =>
          simp [psKernelExprListGet] at hGet
      | succ remaining =>
          have hTail :
              psKernelExprListGet tail remaining =
                Option.none := by
            simpa [psKernelExprListGet] using hGet
          have hBound := ih remaining hTail
          simp [psKernelExprListLength]
          omega


theorem psKernelExprInstantiateAtReference_bvar_before_cons
    (index start offset : Nat)
    (head : PsKernelExpr)
    (tail : List PsKernelExpr)
    (hBefore :
      psKernelNatLt
          index
          (Nat.add start offset) =
        true) :
    psKernelExprInstantiateAtReference
        (PsKernelExpr.bvar index)
        start
        (List.cons head tail)
        offset =
      PsKernelExpr.bvar index := by
  simp only [
    psKernelExprInstantiateAtReference,
    psKernelExprListIsEmpty,
    Bool.false_eq_true,
    ite_false,
    psKernelExprInstantiateAtReferenceChanged
  ]
  rw [hBefore]
  rfl


theorem psKernelExprInstantiateAtReference_bvar_hit_cons
    (index start offset : Nat)
    (head replacement : PsKernelExpr)
    (tail : List PsKernelExpr)
    (hBefore :
      psKernelNatLt
          index
          (Nat.add start offset) =
        false)
    (hGet :
      psKernelExprListGet
          (List.cons head tail)
          (Nat.sub index (Nat.add start offset)) =
        Option.some replacement) :
    psKernelExprInstantiateAtReference
        (PsKernelExpr.bvar index)
        start
        (List.cons head tail)
        offset =
      psKernelExprLiftLooseBVarsReference
        replacement
        0
        offset := by
  simp only [
    psKernelExprInstantiateAtReference,
    psKernelExprListIsEmpty,
    Bool.false_eq_true,
    ite_false,
    psKernelExprInstantiateAtReferenceChanged
  ]
  rw [hBefore, hGet]
  rfl


theorem psKernelExprInstantiateAtReference_bvar_miss_cons
    (index start offset : Nat)
    (head : PsKernelExpr)
    (tail : List PsKernelExpr)
    (hBefore :
      psKernelNatLt
          index
          (Nat.add start offset) =
        false)
    (hGet :
      psKernelExprListGet
          (List.cons head tail)
          (Nat.sub index (Nat.add start offset)) =
        Option.none) :
    psKernelExprInstantiateAtReference
        (PsKernelExpr.bvar index)
        start
        (List.cons head tail)
        offset =
      PsKernelExpr.bvar
        (Nat.sub
          index
          (psKernelExprListLength
            (List.cons head tail))) := by
  simp only [
    psKernelExprInstantiateAtReference,
    psKernelExprListIsEmpty,
    Bool.false_eq_true,
    ite_false,
    psKernelExprInstantiateAtReferenceChanged
  ]
  rw [hBefore, hGet]
  rfl


theorem psKernelExprInstantiateAtReference_singleton_above
    (index offset : Nat)
    (replacement : PsKernelExpr)
    (hAbove : offset < index) :
    psKernelExprInstantiateAtReference
        (PsKernelExpr.bvar index)
        0
        (List.cons replacement List.nil)
        offset =
      PsKernelExpr.bvar (Nat.sub index 1) := by
  have hZero :
      Nat.add 0 offset = offset :=
    Nat.zero_add offset
  have hBeq :
      Nat.beq index offset = false := by
    cases hEq : Nat.beq index offset with
    | false => rfl
    | true =>
        have hEqual := Nat.eq_of_beq_eq_true hEq
        exact (Nat.ne_of_gt hAbove hEqual).elim
  have hBle :
      Nat.ble index offset = false := by
    cases hEq : Nat.ble index offset with
    | false => rfl
    | true =>
        have hWrong := Nat.le_of_ble_eq_true hEq
        exact (Nat.not_le_of_gt hAbove hWrong).elim
  have hBeforeOffset :
      psKernelNatLt index offset = false := by
    simp [psKernelNatLt, hBeq, hBle]
  have hBefore :
      psKernelNatLt index (Nat.add 0 offset) = false := by
    rw [hZero]
    exact hBeforeOffset
  have hPositive :
      0 < Nat.sub index offset :=
    Nat.sub_pos_of_lt hAbove
  cases hRelative :
      Nat.sub index offset with
  | zero =>
      rw [hRelative] at hPositive
      exact (Nat.lt_irrefl 0 hPositive).elim
  | succ relative =>
      have hGet :
          psKernelExprListGet
              (List.cons replacement List.nil)
              (Nat.sub index (Nat.add 0 offset)) =
            Option.none := by
        rw [hZero, hRelative]
        rfl
      have hMiss :=
        psKernelExprInstantiateAtReference_bvar_miss_cons
          index
          0
          offset
          replacement
          List.nil
          hBefore
          hGet
      simpa [psKernelExprListLength] using hMiss


theorem psKernelExprLiftSucc_then_instantiateReference_lower
    (expr replacement : PsKernelExpr)
    (start amount : Nat) :
    psKernelExprInstantiateAtReference
        (psKernelExprLiftLooseBVarsReference
          expr
          start
          (Nat.succ amount))
        0
        (List.cons replacement List.nil)
        (Nat.add start amount) =
      psKernelExprLiftLooseBVarsReference
        expr
        start
        amount := by
  cases amount with
  | zero =>
      simpa [
        psKernelExprLiftLooseBVarsReference,
        psKernelExprLiftLooseBVarsReferenceChanged_zero_amount
      ] using
        psKernelExprLiftOne_then_instantiateReference_cancel
          expr replacement start
  | succ remaining =>
      induction expr generalizing start with
      | bvar index =>
          cases hGe : psKernelNatGe index start with
          | false =>
              have hBleFalse :
                  Nat.ble start index = false := by
                simpa [psKernelNatGe] using hGe
              have hNotLe : ¬ start ≤ index := by
                intro hLe
                have hBleTrue :
                    Nat.ble start index = true :=
                  Nat.ble_eq_true_of_le hLe
                rw [hBleTrue] at hBleFalse
                contradiction
              have hLt : index < start :=
                Nat.lt_of_not_ge hNotLe
              have hLiftBig :
                  psKernelExprLiftLooseBVarsReference
                      (PsKernelExpr.bvar index)
                      start
                      (Nat.succ (Nat.succ remaining)) =
                    PsKernelExpr.bvar index := by
                simp [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hGe
                ]
              have hLiftSmall :
                  psKernelExprLiftLooseBVarsReference
                      (PsKernelExpr.bvar index)
                      start
                      (Nat.succ remaining) =
                    PsKernelExpr.bvar index := by
                simp [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hGe
                ]
              rw [hLiftBig, hLiftSmall]
              apply
                psKernelExprInstantiateAtReference_closed_core
              have hStartLe :
                  start ≤
                    Nat.add start (Nat.succ remaining) :=
                Nat.le_add_right
                  start
                  (Nat.succ remaining)
              have hNotThreshold :
                  ¬ Nat.add start (Nat.succ remaining) ≤
                      index := by
                intro hThreshold
                exact hNotLe
                  (Nat.le_trans hStartLe hThreshold)
              have hThreshold :
                  Nat.ble
                      (Nat.add start (Nat.succ remaining))
                      index =
                    false := by
                cases hEq :
                    Nat.ble
                      (Nat.add start (Nat.succ remaining))
                      index with
                | false => rfl
                | true =>
                    exact
                      (hNotThreshold
                        (Nat.le_of_ble_eq_true hEq)).elim
              simpa [psKernelExprHasLooseAt] using hThreshold
          | true =>
              have hBleTrue :
                  Nat.ble start index = true := by
                simpa [psKernelNatGe] using hGe
              have hLe : start ≤ index :=
                Nat.le_of_ble_eq_true hBleTrue
              let big :=
                Nat.add index (Nat.succ (Nat.succ remaining))
              let threshold :=
                Nat.add start (Nat.succ remaining)
              let small :=
                Nat.add index (Nat.succ remaining)
              have hBaseLe :
                  Nat.add start (Nat.succ remaining) ≤
                    Nat.add index (Nat.succ remaining) :=
                Nat.add_le_add_right hLe (Nat.succ remaining)
              have hBigShape :
                  big =
                    Nat.succ
                      (Nat.add index (Nat.succ remaining)) := by
                dsimp [big]
                rw [Nat.add_succ]
              have hAbove : threshold < big := by
                dsimp [threshold]
                rw [hBigShape]
                exact Nat.lt_succ_of_le hBaseLe
              have hMinusOne :
                  Nat.sub big 1 = small := by
                calc
                  Nat.sub big 1 =
                      Nat.sub
                        (Nat.succ
                          (Nat.add index (Nat.succ remaining)))
                        1 :=
                    congrArg
                      (fun value => Nat.sub value 1)
                      hBigShape
                  _ = Nat.add index (Nat.succ remaining) :=
                    Nat.succ_sub_one _
                  _ = small := by
                    rfl
              have hLiftBig :
                  psKernelExprLiftLooseBVarsReference
                      (PsKernelExpr.bvar index)
                      start
                      (Nat.succ (Nat.succ remaining)) =
                    PsKernelExpr.bvar big := by
                dsimp [big]
                simp [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hGe
                ]
              have hLiftSmall :
                  psKernelExprLiftLooseBVarsReference
                      (PsKernelExpr.bvar index)
                      start
                      (Nat.succ remaining) =
                    PsKernelExpr.bvar small := by
                dsimp [small]
                simp [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hGe
                ]
              rw [hLiftBig, hLiftSmall]
              have hInst :=
                psKernelExprInstantiateAtReference_singleton_above
                  big threshold replacement hAbove
              rw [hInst, hMinusOne]
      | fvar name =>
          simp [
            psKernelExprLiftLooseBVarsReference,
            psKernelExprLiftLooseBVarsReferenceChanged,
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty
          ]
      | mvar name =>
          simp [
            psKernelExprLiftLooseBVarsReference,
            psKernelExprLiftLooseBVarsReferenceChanged,
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty
          ]
      | sort level =>
          simp [
            psKernelExprLiftLooseBVarsReference,
            psKernelExprLiftLooseBVarsReferenceChanged,
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty
          ]
      | const name levels =>
          simp [
            psKernelExprLiftLooseBVarsReference,
            psKernelExprLiftLooseBVarsReferenceChanged,
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty
          ]
      | lit literal =>
          simp [
            psKernelExprLiftLooseBVarsReference,
            psKernelExprLiftLooseBVarsReferenceChanged,
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty
          ]
      | app fn arg ihFn ihArg =>
          calc
            psKernelExprInstantiateAtReference
                (psKernelExprLiftLooseBVarsReference
                  (PsKernelExpr.app fn arg)
                  start
                  (Nat.succ (Nat.succ remaining)))
                0
                (List.cons replacement List.nil)
                (Nat.add start (Nat.succ remaining)) =
              PsKernelExpr.app
                (psKernelExprInstantiateAtReference
                  (psKernelExprLiftLooseBVarsReference
                    fn start (Nat.succ (Nat.succ remaining)))
                  0
                  (List.cons replacement List.nil)
                  (Nat.add start (Nat.succ remaining)))
                (psKernelExprInstantiateAtReference
                  (psKernelExprLiftLooseBVarsReference
                    arg start (Nat.succ (Nat.succ remaining)))
                  0
                  (List.cons replacement List.nil)
                  (Nat.add start (Nat.succ remaining))) := by
                    rw [
                      psKernelExprLiftLooseBVarsReference_app,
                      psKernelExprInstantiateAtReference_app
                    ]
            _ =
              PsKernelExpr.app
                (psKernelExprLiftLooseBVarsReference
                  fn start (Nat.succ remaining))
                (psKernelExprLiftLooseBVarsReference
                  arg start (Nat.succ remaining)) := by
                    rw [ihFn start, ihArg start]
            _ =
              psKernelExprLiftLooseBVarsReference
                (PsKernelExpr.app fn arg)
                start
                (Nat.succ remaining) := by
                  rw [psKernelExprLiftLooseBVarsReference_app]
      | lam name type body binderInfo ihType ihBody =>
          rw [
            psKernelExprLiftLooseBVarsReference_lam,
            psKernelExprInstantiateAtReference_lam,
            psKernelExprLiftLooseBVarsReference_lam,
            ihType start
          ]
          have hOffset :
              Nat.succ
                  (Nat.add start (Nat.succ remaining)) =
                Nat.add
                  (Nat.succ start)
                  (Nat.succ remaining) :=
            (Nat.succ_add
              start
              (Nat.succ remaining)).symm
          rw [hOffset]
          rw [ihBody (Nat.succ start)]
      | forallE name type body binderInfo ihType ihBody =>
          rw [
            psKernelExprLiftLooseBVarsReference_forallE,
            psKernelExprInstantiateAtReference_forallE,
            psKernelExprLiftLooseBVarsReference_forallE,
            ihType start
          ]
          have hOffset :
              Nat.succ
                  (Nat.add start (Nat.succ remaining)) =
                Nat.add
                  (Nat.succ start)
                  (Nat.succ remaining) :=
            (Nat.succ_add
              start
              (Nat.succ remaining)).symm
          rw [hOffset]
          rw [ihBody (Nat.succ start)]
      | letE name type value body nondep ihType ihValue ihBody =>
          rw [
            psKernelExprLiftLooseBVarsReference_letE,
            psKernelExprInstantiateAtReference_letE,
            psKernelExprLiftLooseBVarsReference_letE,
            ihType start,
            ihValue start
          ]
          have hOffset :
              Nat.succ
                  (Nat.add start (Nat.succ remaining)) =
                Nat.add
                  (Nat.succ start)
                  (Nat.succ remaining) :=
            (Nat.succ_add
              start
              (Nat.succ remaining)).symm
          rw [hOffset]
          rw [ihBody (Nat.succ start)]
      | mdata metadata body ihBody =>
          calc
            psKernelExprInstantiateAtReference
                (psKernelExprLiftLooseBVarsReference
                  (PsKernelExpr.mdata metadata body)
                  start
                  (Nat.succ (Nat.succ remaining)))
                0
                (List.cons replacement List.nil)
                (Nat.add start (Nat.succ remaining)) =
              PsKernelExpr.mdata metadata
                (psKernelExprInstantiateAtReference
                  (psKernelExprLiftLooseBVarsReference
                    body start (Nat.succ (Nat.succ remaining)))
                  0
                  (List.cons replacement List.nil)
                  (Nat.add start (Nat.succ remaining))) := by
                    rw [
                      psKernelExprLiftLooseBVarsReference_mdata,
                      psKernelExprInstantiateAtReference_mdata
                    ]
            _ =
              PsKernelExpr.mdata metadata
                (psKernelExprLiftLooseBVarsReference
                  body start (Nat.succ remaining)) := by
                    exact
                      congrArg
                        (fun e => PsKernelExpr.mdata metadata e)
                        (ihBody start)
            _ =
              psKernelExprLiftLooseBVarsReference
                (PsKernelExpr.mdata metadata body)
                start
                (Nat.succ remaining) := by
                  rw [psKernelExprLiftLooseBVarsReference_mdata]
      | proj typeName index body ihBody =>
          calc
            psKernelExprInstantiateAtReference
                (psKernelExprLiftLooseBVarsReference
                  (PsKernelExpr.proj typeName index body)
                  start
                  (Nat.succ (Nat.succ remaining)))
                0
                (List.cons replacement List.nil)
                (Nat.add start (Nat.succ remaining)) =
              PsKernelExpr.proj typeName index
                (psKernelExprInstantiateAtReference
                  (psKernelExprLiftLooseBVarsReference
                    body start (Nat.succ (Nat.succ remaining)))
                  0
                  (List.cons replacement List.nil)
                  (Nat.add start (Nat.succ remaining))) := by
                    rw [
                      psKernelExprLiftLooseBVarsReference_proj,
                      psKernelExprInstantiateAtReference_proj
                    ]
            _ =
              PsKernelExpr.proj typeName index
                (psKernelExprLiftLooseBVarsReference
                  body start (Nat.succ remaining)) := by
                    exact
                      congrArg
                        (fun e => PsKernelExpr.proj typeName index e)
                        (ihBody start)
            _ =
              psKernelExprLiftLooseBVarsReference
                (PsKernelExpr.proj typeName index body)
                start
                (Nat.succ remaining) := by
                  rw [psKernelExprLiftLooseBVarsReference_proj]


/-
Fuel-free reference semantics for the lambda-prefix counter used by WHNF.
The executable counter is fuel-bounded only for portability; semantically it
walks a structurally decreasing chain of nested lambda bodies.
-/
def psKernelWhnfCountLambdasReference
    (current : PsKernelExpr)
    (argCount count : Nat) :
    Prod PsKernelExpr Nat :=
  match current with
  | PsKernelExpr.lam _ _ body _ =>
      if psKernelNatLt count argCount then
        let nextCount := Nat.succ count
        if psKernelNatLt nextCount argCount then
          match body with
          | PsKernelExpr.lam _ _ _ _ =>
              psKernelWhnfCountLambdasReference
                body argCount nextCount
          | _ =>
              Prod.mk current nextCount
        else
          Prod.mk current nextCount
      else
        Prod.mk current count
  | _ =>
      Prod.mk current count
termination_by psKernelExprNodeCount current
decreasing_by
  simp [psKernelExprNodeCount]
  omega


theorem psKernelWhnfCountLambdasWithFuel_refines_reference
    (current : PsKernelExpr)
    (argCount count fuel : Nat)
    (hFuel :
      psKernelExprNodeCount current < fuel) :
    psKernelWhnfCountLambdasWithFuel
        fuel current argCount count =
      psKernelWhnfCountLambdasReference
        current argCount count := by
  induction current generalizing fuel count with
  | bvar index =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | fvar name =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | mvar name =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | sort level =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | const name levels =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | app fn arg ihFn ihArg =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | forallE name type body binderInfo ihType ihBody =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | letE name type value body nondep ihType ihValue ihBody =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | lit literal =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | mdata metadata body ihBody =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | proj typeName index body ihBody =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          rfl
  | lam name type body binderInfo ihType ihBody =>
      cases fuel with
      | zero =>
          simp [psKernelExprNodeCount] at hFuel
      | succ remaining =>
          cases hCount :
              psKernelNatLt count argCount with
          | false =>
              simp [
                psKernelWhnfCountLambdasWithFuel,
                psKernelWhnfCountLambdasReference,
                hCount
              ]
          | true =>
              let nextCount := Nat.succ count
              cases hNext :
                  psKernelNatLt nextCount argCount with
              | false =>
                  simp [
                    psKernelWhnfCountLambdasWithFuel,
                    psKernelWhnfCountLambdasReference,
                    hCount,
                    nextCount,
                    hNext
                  ]
              | true =>
                  cases body with
                  | lam bodyName bodyType bodyBody bodyInfo =>
                      have hBodyFuel :
                          psKernelExprNodeCount
                              (PsKernelExpr.lam
                                bodyName
                                bodyType
                                bodyBody
                                bodyInfo) <
                            remaining := by
                        simp [psKernelExprNodeCount] at hFuel
                        omega
                      have ih :=
                        ihBody
                          remaining
                          nextCount
                          hBodyFuel
                      simpa [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ] using ih
                  | bvar index =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]
                  | fvar bodyName =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]
                  | mvar bodyName =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]
                  | sort bodyLevel =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]
                  | const bodyName bodyLevels =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]
                  | app bodyFn bodyArg =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]
                  | forallE bodyName bodyType bodyBody bodyInfo =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]
                  | letE bodyName bodyType bodyValue bodyBody bodyNondep =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]
                  | lit bodyLiteral =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]
                  | mdata bodyMetadata bodyBody =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]
                  | proj bodyTypeName bodyIndex bodyBody =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        psKernelWhnfCountLambdasReference,
                        hCount,
                        nextCount,
                        hNext
                      ]


theorem psKernelWhnfCountLambdas_refines_reference
    (current : PsKernelExpr)
    (argCount : Nat) :
    psKernelWhnfCountLambdas current argCount =
      psKernelWhnfCountLambdasReference
        current argCount 0 := by
  unfold psKernelWhnfCountLambdas
  exact
    psKernelWhnfCountLambdasWithFuel_refines_reference
      current
      argCount
      0
      (Nat.succ (psKernelExprNodeCount current))
      (Nat.lt_succ_self
        (psKernelExprNodeCount current))


theorem psKernelExprInstantiateAtReference_bvar_fuse_singleton
    (index offset : Nat)
    (replacement head : PsKernelExpr)
    (tail : List PsKernelExpr) :
    psKernelExprInstantiateAtReference
        (psKernelExprInstantiateAtReference
          (PsKernelExpr.bvar index)
          0
          (List.cons head tail)
          (Nat.succ offset))
        0
        (List.cons replacement List.nil)
        offset =
      psKernelExprInstantiateAtReference
        (PsKernelExpr.bvar index)
        0
        (List.cons replacement (List.cons head tail))
        offset := by
  by_cases hLt : index < offset
  · have hInnerBefore :
        psKernelNatLt
            index
            (Nat.add 0 (Nat.succ offset)) =
          true := by
      simpa using
        psKernelNatLt_true_of_lt
          index
          (Nat.succ offset)
          (Nat.lt_trans hLt (Nat.lt_succ_self offset))
    have hOuterBefore :
        psKernelNatLt
            index
            (Nat.add 0 offset) =
          true := by
      simpa using
        psKernelNatLt_true_of_lt
          index
          offset
          hLt
    rw [
      psKernelExprInstantiateAtReference_bvar_before_cons
        index 0 (Nat.succ offset) head tail hInnerBefore,
      psKernelExprInstantiateAtReference_bvar_before_cons
        index 0 offset replacement List.nil hOuterBefore,
      psKernelExprInstantiateAtReference_bvar_before_cons
        index 0 offset replacement (List.cons head tail) hOuterBefore
    ]
  · by_cases hEq : index = offset
    · subst index
      have hInnerBefore :
          psKernelNatLt
              offset
              (Nat.add 0 (Nat.succ offset)) =
            true := by
        simpa using
          psKernelNatLt_true_of_lt
            offset
            (Nat.succ offset)
            (Nat.lt_succ_self offset)
      have hOuterBefore :
          psKernelNatLt
              offset
              (Nat.add 0 offset) =
            false := by
        simpa using
          psKernelNatLt_false_of_le
            offset
            offset
            (Nat.le_refl offset)
      have hSingletonGet :
          psKernelExprListGet
              (List.cons replacement List.nil)
              (Nat.sub offset (Nat.add 0 offset)) =
            Option.some replacement := by
        simp [psKernelExprListGet]
      have hCombinedGet :
          psKernelExprListGet
              (List.cons replacement (List.cons head tail))
              (Nat.sub offset (Nat.add 0 offset)) =
            Option.some replacement := by
        simp [psKernelExprListGet]
      rw [
        psKernelExprInstantiateAtReference_bvar_before_cons
          offset 0 (Nat.succ offset) head tail hInnerBefore,
        psKernelExprInstantiateAtReference_bvar_hit_cons
          offset 0 offset replacement replacement List.nil
          hOuterBefore hSingletonGet,
        psKernelExprInstantiateAtReference_bvar_hit_cons
          offset 0 offset replacement replacement (List.cons head tail)
          hOuterBefore hCombinedGet
      ]
    · have hGt : offset < index := by
        omega
      have hInnerLe :
          Nat.succ offset ≤ index :=
        Nat.succ_le_of_lt hGt
      have hInnerBefore :
          psKernelNatLt
              index
              (Nat.add 0 (Nat.succ offset)) =
            false := by
        simpa using
          psKernelNatLt_false_of_le
            index
            (Nat.succ offset)
            hInnerLe
      have hOuterBefore :
          psKernelNatLt
              index
              (Nat.add 0 offset) =
            false := by
        simpa using
          psKernelNatLt_false_of_le
            index
            offset
            (Nat.le_of_lt hGt)
      let relative :=
        Nat.sub index (Nat.succ offset)
      have hRelativeSucc :
          Nat.sub index offset =
            Nat.succ relative := by
        dsimp [relative]
        omega
      cases hGet :
          psKernelExprListGet
            (List.cons head tail)
            relative with
      | some found =>
          have hInnerGet :
              psKernelExprListGet
                  (List.cons head tail)
                  (Nat.sub index (Nat.add 0 (Nat.succ offset))) =
                Option.some found := by
            simpa [relative] using hGet
          have hInner :=
            psKernelExprInstantiateAtReference_bvar_hit_cons
              index
              0
              (Nat.succ offset)
              head
              found
              tail
              hInnerBefore
              hInnerGet
          rw [hInner]
          have hLower :
              psKernelExprInstantiateAtReference
                  (psKernelExprLiftLooseBVarsReference
                    found 0 (Nat.succ offset))
                  0
                  (List.cons replacement List.nil)
                  offset =
                psKernelExprLiftLooseBVarsReference
                  found 0 offset := by
            simpa using
              psKernelExprLiftSucc_then_instantiateReference_lower
                found
                replacement
                0
                offset
          rw [hLower]
          have hCombinedGet :
              psKernelExprListGet
                  (List.cons replacement (List.cons head tail))
                  (Nat.sub index (Nat.add 0 offset)) =
                Option.some found := by
            rw [Nat.zero_add, hRelativeSucc]
            simpa [psKernelExprListGet] using hGet
          rw [
            psKernelExprInstantiateAtReference_bvar_hit_cons
              index
              0
              offset
              replacement
              found
              (List.cons head tail)
              hOuterBefore
              hCombinedGet
          ]
      | none =>
          have hInnerGet :
              psKernelExprListGet
                  (List.cons head tail)
                  (Nat.sub index (Nat.add 0 (Nat.succ offset))) =
                Option.none := by
            simpa [relative] using hGet
          have hInner :=
            psKernelExprInstantiateAtReference_bvar_miss_cons
              index
              0
              (Nat.succ offset)
              head
              tail
              hInnerBefore
              hInnerGet
          rw [hInner]
          have hLengthBound :
              psKernelExprListLength (List.cons head tail) ≤
                relative :=
            psKernelExprListGet_none_length_le
              (List.cons head tail)
              relative
              hGet
          have hReducedAbove :
              offset <
                Nat.sub
                  index
                  (psKernelExprListLength
                    (List.cons head tail)) := by
            dsimp [relative] at hLengthBound
            omega
          rw [
            psKernelExprInstantiateAtReference_singleton_above
              (Nat.sub
                index
                (psKernelExprListLength
                  (List.cons head tail)))
              offset
              replacement
              hReducedAbove
          ]
          have hCombinedGet :
              psKernelExprListGet
                  (List.cons replacement (List.cons head tail))
                  (Nat.sub index (Nat.add 0 offset)) =
                Option.none := by
            rw [Nat.zero_add, hRelativeSucc]
            simpa [psKernelExprListGet] using hGet
          rw [
            psKernelExprInstantiateAtReference_bvar_miss_cons
              index
              0
              offset
              replacement
              (List.cons head tail)
              hOuterBefore
              hCombinedGet
          ]
          simp [psKernelExprListLength]
          omega
