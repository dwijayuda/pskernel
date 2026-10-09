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


theorem psKernelNatLt_lt_of_true
    (left right : Nat)
    (hTrue :
      psKernelNatLt left right = true) :
    left < right := by
  cases hEq : Nat.beq left right with
  | true =>
      simp [psKernelNatLt, hEq] at hTrue
  | false =>
      have hBle :
          Nat.ble left right = true := by
        simpa [psKernelNatLt, hEq] using hTrue
      have hLe :
          left ≤ right :=
        Nat.le_of_ble_eq_true hBle
      have hNe : left ≠ right := by
        intro hEqual
        subst right
        simp at hEq
      exact Nat.lt_of_le_of_ne hLe hNe


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
Independent semantic relation for the lambda-priorArgs counter used by WHNF.

The executable counter carries fuel only for portability.  The Assurance Plane
records the observable counting decision as an inductive relation, so semantic
proofs do not depend on a second executable recursive function.
-/
def psKernelExprIsLambda
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.lam _ _ _ _ => true
  | _ => false


inductive PsKernelWhnfCountLambdasRelation :
    PsKernelExpr ->
    Nat ->
    Nat ->
    PsKernelExpr ->
    Nat ->
    Prop
  | nonLambda
      (current : PsKernelExpr)
      (argCount count : Nat)
      (hNotLam :
        psKernelExprIsLambda current = false) :
      PsKernelWhnfCountLambdasRelation
        current argCount count current count
  | lamNoArg
      (name : PsKernelName)
      (type body : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (argCount count : Nat)
      (hCount :
        psKernelNatLt count argCount = false) :
      PsKernelWhnfCountLambdasRelation
        (PsKernelExpr.lam name type body binderInfo)
        argCount
        count
        (PsKernelExpr.lam name type body binderInfo)
        count
  | lamLast
      (name : PsKernelName)
      (type body : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (argCount count : Nat)
      (hCount :
        psKernelNatLt count argCount = true)
      (hNext :
        psKernelNatLt (Nat.succ count) argCount = false) :
      PsKernelWhnfCountLambdasRelation
        (PsKernelExpr.lam name type body binderInfo)
        argCount
        count
        (PsKernelExpr.lam name type body binderInfo)
        (Nat.succ count)
  | lamBodyStop
      (name : PsKernelName)
      (type body : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (argCount count : Nat)
      (hCount :
        psKernelNatLt count argCount = true)
      (hNext :
        psKernelNatLt (Nat.succ count) argCount = true)
      (hBodyNotLam :
        psKernelExprIsLambda body = false) :
      PsKernelWhnfCountLambdasRelation
        (PsKernelExpr.lam name type body binderInfo)
        argCount
        count
        (PsKernelExpr.lam name type body binderInfo)
        (Nat.succ count)
  | lamRecurse
      (name : PsKernelName)
      (type body : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (argCount count : Nat)
      (lastLam : PsKernelExpr)
      (consumed : Nat)
      (hCount :
        psKernelNatLt count argCount = true)
      (hNext :
        psKernelNatLt (Nat.succ count) argCount = true)
      (hBodyLam :
        psKernelExprIsLambda body = true)
      (hRest :
        PsKernelWhnfCountLambdasRelation
          body
          argCount
          (Nat.succ count)
          lastLam
          consumed) :
      PsKernelWhnfCountLambdasRelation
        (PsKernelExpr.lam name type body binderInfo)
        argCount
        count
        lastLam
        consumed


theorem psKernelWhnfCountLambdasWithFuel_refines_relation_of_bound
    (fuel : Nat)
    (current : PsKernelExpr)
    (argCount count : Nat)
    (lastLam : PsKernelExpr)
    (consumed : Nat)
    (hFuel :
      psKernelExprNodeCount current < fuel ∨ argCount - count < fuel)
    (hRun :
      psKernelWhnfCountLambdasWithFuel
          fuel current argCount count =
        Prod.mk lastLam consumed) :
    PsKernelWhnfCountLambdasRelation
      current argCount count lastLam consumed := by
  induction fuel generalizing current count lastLam consumed with
  | zero =>
      rcases hFuel with hFuel | hFuel <;> omega
  | succ remaining ih =>
      cases current with
      | bvar index =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.bvar index)
              argCount
              count
              rfl
      | fvar name =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.fvar name)
              argCount
              count
              rfl
      | mvar name =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.mvar name)
              argCount
              count
              rfl
      | sort level =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.sort level)
              argCount
              count
              rfl
      | const name levels =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.const name levels)
              argCount
              count
              rfl
      | app fn arg =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.app fn arg)
              argCount
              count
              rfl
      | forallE name type body binderInfo =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.forallE name type body binderInfo)
              argCount
              count
              rfl
      | letE name type value body nondep =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.letE name type value body nondep)
              argCount
              count
              rfl
      | lit literal =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.lit literal)
              argCount
              count
              rfl
      | mdata metadata body =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.mdata metadata body)
              argCount
              count
              rfl
      | proj typeName index body =>
          simp [psKernelWhnfCountLambdasWithFuel] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            PsKernelWhnfCountLambdasRelation.nonLambda
              (PsKernelExpr.proj typeName index body)
              argCount
              count
              rfl
      | lam name type body binderInfo =>
          cases hCount :
              psKernelNatLt count argCount with
          | false =>
              simp [
                psKernelWhnfCountLambdasWithFuel,
                hCount
              ] at hRun
              rcases hRun with ⟨rfl, rfl⟩
              exact
                PsKernelWhnfCountLambdasRelation.lamNoArg
                  name type body binderInfo
                  argCount count hCount
          | true =>
              let nextCount := Nat.succ count
              cases hNext :
                  psKernelNatLt nextCount argCount with
              | false =>
                  simp [
                    psKernelWhnfCountLambdasWithFuel,
                    hCount,
                    nextCount,
                    hNext
                  ] at hRun
                  rcases hRun with ⟨rfl, rfl⟩
                  exact
                    PsKernelWhnfCountLambdasRelation.lamLast
                      name type body binderInfo
                      argCount count
                      hCount
                      (by simpa [nextCount] using hNext)
              | true =>
                  cases body with
                  | lam bodyName bodyType bodyBody bodyInfo =>
                      have hBodyFuel :
                          psKernelExprNodeCount
                            (PsKernelExpr.lam bodyName bodyType bodyBody bodyInfo)
                              < remaining ∨
                            argCount - nextCount < remaining := by
                        rcases hFuel with hSize | hArgs
                        · left
                          simp only [psKernelExprNodeCount] at hSize ⊢
                          omega
                        · right
                          have hNextLt : nextCount < argCount :=
                            psKernelNatLt_lt_of_true _ _ hNext
                          dsimp [nextCount] at *
                          omega
                      have hRecursive :
                          psKernelWhnfCountLambdasWithFuel
                              remaining
                              (PsKernelExpr.lam
                                bodyName
                                bodyType
                                bodyBody
                                bodyInfo)
                              argCount
                              nextCount =
                            Prod.mk lastLam consumed := by
                        simpa [
                          psKernelWhnfCountLambdasWithFuel,
                          hCount,
                          nextCount,
                          hNext
                        ] using hRun
                      have hRest :=
                        ih
                          (PsKernelExpr.lam
                            bodyName
                            bodyType
                            bodyBody
                            bodyInfo)
                          nextCount
                          lastLam
                          consumed
                          hBodyFuel
                          hRecursive
                      exact
                        PsKernelWhnfCountLambdasRelation.lamRecurse
                          name
                          type
                          (PsKernelExpr.lam
                            bodyName
                            bodyType
                            bodyBody
                            bodyInfo)
                          binderInfo
                          argCount
                          count
                          lastLam
                          consumed
                          hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                          hRest
                  | bvar index =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type (PsKernelExpr.bvar index) binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                  | fvar bodyName =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type (PsKernelExpr.fvar bodyName) binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                  | mvar bodyName =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type (PsKernelExpr.mvar bodyName) binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                  | sort bodyLevel =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type (PsKernelExpr.sort bodyLevel) binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                  | const bodyName bodyLevels =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type (PsKernelExpr.const bodyName bodyLevels) binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                  | app bodyFn bodyArg =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type (PsKernelExpr.app bodyFn bodyArg) binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                  | forallE bodyName bodyType bodyBody bodyInfo =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type
                          (PsKernelExpr.forallE
                            bodyName bodyType bodyBody bodyInfo)
                          binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                  | letE bodyName bodyType bodyValue bodyBody bodyNondep =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type
                          (PsKernelExpr.letE
                            bodyName bodyType bodyValue bodyBody bodyNondep)
                          binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                  | lit bodyLiteral =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type (PsKernelExpr.lit bodyLiteral) binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                  | mdata bodyMetadata bodyBody =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type
                          (PsKernelExpr.mdata bodyMetadata bodyBody)
                          binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl
                  | proj bodyTypeName bodyIndex bodyBody =>
                      simp [
                        psKernelWhnfCountLambdasWithFuel,
                        hCount,
                        nextCount,
                        hNext
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact
                        PsKernelWhnfCountLambdasRelation.lamBodyStop
                          name type
                          (PsKernelExpr.proj
                            bodyTypeName bodyIndex bodyBody)
                          binderInfo
                          argCount count hCount
                          (by simpa [nextCount] using hNext)
                          rfl


-- Compatibility theorem for clients using a structural bound.
theorem psKernelWhnfCountLambdasWithFuel_refines_relation
    (fuel : Nat) (current : PsKernelExpr) (argCount count : Nat)
    (lastLam : PsKernelExpr) (consumed : Nat)
    (hFuel : psKernelExprNodeCount current < fuel)
    (hRun : psKernelWhnfCountLambdasWithFuel fuel current argCount count =
      Prod.mk lastLam consumed) :
    PsKernelWhnfCountLambdasRelation current argCount count lastLam consumed :=
  psKernelWhnfCountLambdasWithFuel_refines_relation_of_bound
    fuel current argCount count lastLam consumed (Or.inl hFuel) hRun

theorem psKernelWhnfCountLambdas_refines_relation
    (current : PsKernelExpr)
    (argCount : Nat)
    (lastLam : PsKernelExpr)
    (consumed : Nat)
    (hRun :
      psKernelWhnfCountLambdas current argCount =
        Prod.mk lastLam consumed) :
    PsKernelWhnfCountLambdasRelation
      current argCount 0 lastLam consumed := by
  unfold psKernelWhnfCountLambdas at hRun
  exact
    psKernelWhnfCountLambdasWithFuel_refines_relation_of_bound
      (Nat.succ argCount)
      current
      argCount
      0
      lastLam
      consumed
      (Or.inr (by omega))
      hRun


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
            have hZero :
                Nat.add 0 offset = offset :=
              Nat.zero_add offset
            rw [hZero, hRelativeSucc]
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
          have hLengthPlusThreshold :
              Nat.add
                  (psKernelExprListLength (List.cons head tail))
                  (Nat.succ offset) ≤
                index := by
            have hThresholdLe : Nat.succ offset ≤ index :=
              hInnerLe
            have hBound :
                psKernelExprListLength (List.cons head tail) ≤
                  Nat.sub index (Nat.succ offset) := by
              simpa [relative] using hLengthBound
            exact
              (Nat.le_sub_iff_add_le hThresholdLe).1
                hBound
          have hLengthPlusOffsetLt :
              Nat.add
                  (psKernelExprListLength (List.cons head tail))
                  offset <
                index := by
            let listLength :=
              psKernelExprListLength (List.cons head tail)
            have hAddSucc :
                Nat.add listLength (Nat.succ offset) =
                  Nat.succ (Nat.add listLength offset) :=
              Nat.add_succ listLength offset
            have hThreshold :
                Nat.add listLength (Nat.succ offset) ≤
                  index := by
              simpa [listLength] using hLengthPlusThreshold
            have hSuccLe :
                Nat.succ (Nat.add listLength offset) ≤
                  index :=
              Eq.mp
                (congrArg
                  (fun value => value ≤ index)
                  hAddSucc)
                hThreshold
            simpa [listLength] using
              (Nat.lt_of_succ_le hSuccLe)
          have hOffsetPlusLengthLt :
              Nat.add
                  offset
                  (psKernelExprListLength (List.cons head tail)) <
                index := by
            simpa [Nat.add_comm] using hLengthPlusOffsetLt
          have hReducedAbove :
              offset <
                Nat.sub
                  index
                  (psKernelExprListLength
                    (List.cons head tail)) :=
            (Nat.lt_sub_iff_add_lt).2 hOffsetPlusLengthLt
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
            have hZero :
                Nat.add 0 offset = offset :=
              Nat.zero_add offset
            rw [hZero, hRelativeSucc]
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


theorem psKernelExprInstantiateAtReference_fuse_singleton
    (expr replacement : PsKernelExpr)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAtReference
        (psKernelExprInstantiateAtReference
          expr
          0
          subst
          (Nat.succ offset))
        0
        (List.cons replacement List.nil)
        offset =
      psKernelExprInstantiateAtReference
        expr
        0
        (List.cons replacement subst)
        offset := by
  cases subst with
  | nil =>
      have hEmpty :
          psKernelExprInstantiateAtReference
              expr
              0
              List.nil
              (Nat.succ offset) =
            expr := by
        simp [
          psKernelExprInstantiateAtReference,
          psKernelExprListIsEmpty
        ]
      rw [hEmpty]
  | cons head tail =>
      induction expr generalizing offset replacement head tail with
      | bvar index =>
          exact
            psKernelExprInstantiateAtReference_bvar_fuse_singleton
              index offset replacement head tail
      | fvar name =>
          simp [
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty
          ]
      | mvar name =>
          simp [
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty
          ]
      | sort level =>
          simp [
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty
          ]
      | const name levels =>
          simp [
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty
          ]
      | lit literal =>
          simp [
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty
          ]
      | app fn arg ihFn ihArg =>
          rw [
            psKernelExprInstantiateAtReference_app,
            psKernelExprInstantiateAtReference_app,
            psKernelExprInstantiateAtReference_app,
            ihFn,
            ihArg
          ]
      | lam name type body binderInfo ihType ihBody =>
          rw [
            psKernelExprInstantiateAtReference_lam,
            psKernelExprInstantiateAtReference_lam,
            psKernelExprInstantiateAtReference_lam,
            ihType,
            ihBody
          ]
      | forallE name type body binderInfo ihType ihBody =>
          rw [
            psKernelExprInstantiateAtReference_forallE,
            psKernelExprInstantiateAtReference_forallE,
            psKernelExprInstantiateAtReference_forallE,
            ihType,
            ihBody
          ]
      | letE name type value body nondep ihType ihValue ihBody =>
          rw [
            psKernelExprInstantiateAtReference_letE,
            psKernelExprInstantiateAtReference_letE,
            psKernelExprInstantiateAtReference_letE,
            ihType,
            ihValue,
            ihBody
          ]
      | mdata metadata body ihBody =>
          rw [
            psKernelExprInstantiateAtReference_mdata,
            psKernelExprInstantiateAtReference_mdata,
            psKernelExprInstantiateAtReference_mdata,
            ihBody
          ]
      | proj typeName index body ihBody =>
          rw [
            psKernelExprInstantiateAtReference_proj,
            psKernelExprInstantiateAtReference_proj,
            psKernelExprInstantiateAtReference_proj,
            ihBody
          ]


theorem psKernelExprInstantiateAt_fuse_singleton
    (expr replacement : PsKernelExpr)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAt
        (psKernelExprInstantiateAt
          expr
          0
          subst
          (Nat.succ offset))
        0
        (List.cons replacement List.nil)
        offset =
      psKernelExprInstantiateAt
        expr
        0
        (List.cons replacement subst)
        offset := by
  simp only [
    psKernelExprInstantiateAt_refines_reference_core
  ]
  exact
    psKernelExprInstantiateAtReference_fuse_singleton
      expr replacement subst offset


theorem psKernelExprList_split_at
    (args : List PsKernelExpr)
    (count : Nat)
    (hAvailable :
      count < psKernelExprListLength args) :
    ∃ (arg : PsKernelExpr) (rest : List PsKernelExpr),
      psKernelExprListDrop count args =
          List.cons arg rest ∧
      psKernelExprListDrop (Nat.succ count) args =
          rest ∧
      psKernelExprListTake (Nat.succ count) args =
          List.append
            (psKernelExprListTake count args)
            (List.cons arg List.nil) := by
  induction count generalizing args with
  | zero =>
      cases args with
      | nil =>
          simp [psKernelExprListLength] at hAvailable
      | cons head tail =>
          refine ⟨head, tail, ?_, ?_, ?_⟩
          · rfl
          · rfl
          · rfl
  | succ remaining ih =>
      cases args with
      | nil =>
          simp [psKernelExprListLength] at hAvailable
      | cons head tail =>
          have hTailAvailable :
              remaining <
                psKernelExprListLength tail := by
            simpa [psKernelExprListLength] using
              (Nat.lt_of_succ_lt_succ hAvailable)
          rcases ih tail hTailAvailable with
            ⟨arg, rest, hDrop, hDropNext, hTake⟩
          refine ⟨arg, rest, ?_, ?_, ?_⟩
          · simpa [psKernelExprListDrop] using hDrop
          · simpa [psKernelExprListDrop] using hDropNext
          · simpa [psKernelExprListTake, hTake]


theorem psKernelExprListReverseWorker_append_metatheory
    (values acc : List PsKernelExpr) :
    psKernelExprListReverseWorker values acc =
      List.append (List.reverse values) acc := by
  induction values generalizing acc with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [
        psKernelExprListReverseWorker,
        ih,
        List.append_assoc
      ]


theorem psKernelExprListReverse_eq_reverse_metatheory
    (values : List PsKernelExpr) :
    psKernelExprListReverse values =
      List.reverse values := by
  simp [
    psKernelExprListReverse,
    psKernelExprListReverseWorker_append_metatheory
  ]


theorem psKernelExprListReverse_append_singleton
    (values : List PsKernelExpr)
    (value : PsKernelExpr) :
    psKernelExprListReverse
        (List.append
          values
          (List.cons value List.nil)) =
      List.cons
        value
        (psKernelExprListReverse values) := by
  rw [
    psKernelExprListReverse_eq_reverse_metatheory,
    psKernelExprListReverse_eq_reverse_metatheory
  ]
  simp


theorem psKernelExprInstantiateAt_lam
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    psKernelExprInstantiateAt
        (PsKernelExpr.lam name type body binderInfo)
        start subst offset =
      PsKernelExpr.lam
        name
        (psKernelExprInstantiateAt
          type start subst offset)
        (psKernelExprInstantiateAt
          body start subst (Nat.succ offset))
        binderInfo := by
  simp only [
    psKernelExprInstantiateAt_refines_reference_core,
    psKernelExprInstantiateAtReference_lam
  ]


theorem psKernelExprInstantiateRev_lam
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (priorArgs : List PsKernelExpr) :
    psKernelExprInstantiateRev
        (PsKernelExpr.lam name type body binderInfo)
        priorArgs =
      PsKernelExpr.lam
        name
        (psKernelExprInstantiateAt
          type
          0
          (psKernelExprListReverse priorArgs)
          0)
        (psKernelExprInstantiateAt
          body
          0
          (psKernelExprListReverse priorArgs)
          1)
        binderInfo := by
  unfold psKernelExprInstantiateRev
  unfold psKernelExprInstantiate
  rw [psKernelExprInstantiateAt_lam]


theorem psKernelExprInstantiate1_eq_instantiateAt_singleton
    (expr replacement : PsKernelExpr) :
    psKernelExprInstantiate1 expr replacement =
      psKernelExprInstantiateAt
        expr
        0
        (List.cons replacement List.nil)
        0 := by
  calc
    psKernelExprInstantiate1 expr replacement =
        psKernelExprInstantiateRev
          expr
          (List.cons replacement List.nil) := by
      symm
      exact
        psKernelExprInstantiateRev_singleton
          expr replacement
    _ =
        psKernelExprInstantiateAt
          expr
          0
          (List.cons replacement List.nil)
          0 := by
      rfl


theorem psKernelExprInstantiateRev_append_singleton_beta
    (body arg : PsKernelExpr)
    (priorArgs : List PsKernelExpr) :
    psKernelExprInstantiate1
        (psKernelExprInstantiateAt
          body
          0
          (psKernelExprListReverse priorArgs)
          1)
        arg =
      psKernelExprInstantiateRev
        body
        (List.append
          priorArgs
          (List.cons arg List.nil)) := by
  rw [psKernelExprInstantiate1_eq_instantiateAt_singleton]
  have hFuse :=
    psKernelExprInstantiateAt_fuse_singleton
      body
      arg
      (psKernelExprListReverse priorArgs)
      0
  rw [hFuse]
  unfold psKernelExprInstantiateRev
  unfold psKernelExprInstantiate
  rw [psKernelExprListReverse_append_singleton]


theorem psKernelBetaPrefixStep
    (context : PsKernelCheckerContext)
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (priorArgs : List PsKernelExpr)
    (arg : PsKernelExpr)
    (rest : List PsKernelExpr) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      (psKernelExprApplyArgsCheap
        (psKernelExprInstantiateRev
          (PsKernelExpr.lam
            name type body binderInfo)
          priorArgs)
        (List.cons arg rest))
      (psKernelExprApplyArgsCheap
        (psKernelExprInstantiateRev
          body
          (List.append
            priorArgs
            (List.cons arg List.nil)))
        rest) := by
  let instantiatedType :=
    psKernelExprInstantiateAt
      type
      0
      (psKernelExprListReverse priorArgs)
      0
  let instantiatedBody :=
    psKernelExprInstantiateAt
      body
      0
      (psKernelExprListReverse priorArgs)
      1
  have hLam :
      psKernelExprInstantiateRev
          (PsKernelExpr.lam
            name type body binderInfo)
          priorArgs =
        PsKernelExpr.lam
          name
          instantiatedType
          instantiatedBody
          binderInfo := by
    simpa [
      instantiatedType,
      instantiatedBody
    ] using
      psKernelExprInstantiateRev_lam
        name type body binderInfo priorArgs
  have hResult :
      psKernelExprInstantiate1
          instantiatedBody
          arg =
        psKernelExprInstantiateRev
          body
          (List.append
            priorArgs
            (List.cons arg List.nil)) := by
    simpa [instantiatedBody] using
      psKernelExprInstantiateRev_append_singleton_beta
        body arg priorArgs
  have hStep :
      PsKernelReductionStep
        context.environment
        context.localContext
        (PsKernelExpr.app
          (PsKernelExpr.lam
            name
            instantiatedType
            instantiatedBody
            binderInfo)
          arg)
        (psKernelExprInstantiate1
          instantiatedBody
          arg) :=
    PsKernelReductionStep.beta
      name
      instantiatedType
      instantiatedBody
      arg
      binderInfo
  have hOne :
      PsKernelReductionClosure
        context.environment
        context.localContext
        (PsKernelExpr.app
          (PsKernelExpr.lam
            name
            instantiatedType
            instantiatedBody
            binderInfo)
          arg)
        (psKernelExprInstantiate1
          instantiatedBody
          arg) :=
    PsKernelReductionClosure.cons
      (PsKernelExpr.app
        (PsKernelExpr.lam
          name
          instantiatedType
          instantiatedBody
          binderInfo)
        arg)
      (psKernelExprInstantiate1
        instantiatedBody
        arg)
      (psKernelExprInstantiate1
        instantiatedBody
        arg)
      hStep
      (PsKernelReductionClosure.refl
        (psKernelExprInstantiate1
          instantiatedBody
          arg))
  have hLift :=
    psKernelReductionClosure_applyArgsCheap
      context.environment
      context.localContext
      rest
      (PsKernelExpr.app
        (PsKernelExpr.lam
          name
          instantiatedType
          instantiatedBody
          binderInfo)
        arg)
      (psKernelExprInstantiate1
        instantiatedBody
        arg)
      hOne
  simpa [
    psKernelExprApplyArgsCheap,
    psKernelExprApplyArgsCheapWorker,
    hLam,
    hResult
  ] using hLift


theorem psKernelExprInstantiateRev_nil_metatheory
    (expr : PsKernelExpr) :
    psKernelExprInstantiateRev expr List.nil = expr := by
  rfl


theorem psKernelWhnfCountLambdasRelation_refines_beta
    (context : PsKernelCheckerContext)
    (args : List PsKernelExpr)
    (current lastLam : PsKernelExpr)
    (argCount count consumed : Nat)
    (targetName : PsKernelName)
    (targetType targetBody : PsKernelExpr)
    (targetBinderInfo : PsKernelBinderInfo)
    (hRelation :
      PsKernelWhnfCountLambdasRelation
        current
        argCount
        count
        lastLam
        consumed)
    (hArgCount :
      argCount = psKernelExprListLength args)
    (hAvailable :
      count < argCount)
    (hLast :
      lastLam =
        PsKernelExpr.lam
          targetName
          targetType
          targetBody
          targetBinderInfo) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      (psKernelExprApplyArgsCheap
        (psKernelExprInstantiateRev
          current
          (psKernelExprListTake count args))
        (psKernelExprListDrop count args))
      (psKernelExprApplyArgsCheap
        (psKernelExprInstantiateRev
          targetBody
          (psKernelExprListTake consumed args))
        (psKernelExprListDrop consumed args)) := by
  induction hRelation
      generalizing
        args
        targetName
        targetType
        targetBody
        targetBinderInfo with
  | nonLambda current argCount count hNotLam =>
      rw [hLast] at hNotLam
      simp [psKernelExprIsLambda] at hNotLam
  | lamNoArg name type body binderInfo argCount count hCount =>
      have hCountTrue :
          psKernelNatLt count argCount = true :=
        psKernelNatLt_true_of_lt
          count
          argCount
          hAvailable
      rw [hCountTrue] at hCount
      contradiction
  | lamLast name type body binderInfo argCount count hCount hNext =>
      injection hLast with
        hName hType hBody hBinder
      subst targetName
      subst targetType
      subst targetBody
      subst targetBinderInfo
      have hAvailableArgs :
          count < psKernelExprListLength args := by
        simpa [hArgCount] using hAvailable
      rcases
          psKernelExprList_split_at
            args
            count
            hAvailableArgs with
        ⟨arg, rest, hDrop, hDropNext, hTake⟩
      have hStep :=
        psKernelBetaPrefixStep
          context
          name
          type
          body
          binderInfo
          (psKernelExprListTake count args)
          arg
          rest
      simpa [
        hDrop,
        hDropNext,
        hTake
      ] using hStep
  | lamBodyStop
      name type body binderInfo
      argCount count
      hCount hNext hBodyNotLam =>
      injection hLast with
        hName hType hBody hBinder
      subst targetName
      subst targetType
      subst targetBody
      subst targetBinderInfo
      have hAvailableArgs :
          count < psKernelExprListLength args := by
        simpa [hArgCount] using hAvailable
      rcases
          psKernelExprList_split_at
            args
            count
            hAvailableArgs with
        ⟨arg, rest, hDrop, hDropNext, hTake⟩
      have hStep :=
        psKernelBetaPrefixStep
          context
          name
          type
          body
          binderInfo
          (psKernelExprListTake count args)
          arg
          rest
      simpa [
        hDrop,
        hDropNext,
        hTake
      ] using hStep
  | lamRecurse
      name type body binderInfo
      argCount count
      lastLam consumed
      hCount hNext hBodyLam hRest ih =>
      have hNextAvailable :
          Nat.succ count < argCount :=
        psKernelNatLt_lt_of_true
          (Nat.succ count)
          argCount
          hNext
      have hRestReduction :=
        ih
          (args := args)
          (targetName := targetName)
          (targetType := targetType)
          (targetBody := targetBody)
          (targetBinderInfo := targetBinderInfo)
          hArgCount
          hNextAvailable
          hLast
      have hAvailableArgs :
          count < psKernelExprListLength args := by
        simpa [hArgCount] using hAvailable
      rcases
          psKernelExprList_split_at
            args
            count
            hAvailableArgs with
        ⟨arg, rest, hDrop, hDropNext, hTake⟩
      have hFirstRaw :=
        psKernelBetaPrefixStep
          context
          name
          type
          body
          binderInfo
          (psKernelExprListTake count args)
          arg
          rest
      have hFirst :
          PsKernelReductionClosure
            context.environment
            context.localContext
            (psKernelExprApplyArgsCheap
              (psKernelExprInstantiateRev
                (PsKernelExpr.lam
                  name type body binderInfo)
                (psKernelExprListTake count args))
              (psKernelExprListDrop count args))
            (psKernelExprApplyArgsCheap
              (psKernelExprInstantiateRev
                body
                (psKernelExprListTake
                  (Nat.succ count)
                  args))
              (psKernelExprListDrop
                (Nat.succ count)
                args)) := by
        simpa [
          hDrop,
          hDropNext,
          hTake
        ] using hFirstRaw
      exact
        psKernelReductionClosure_transitive
          context.environment
          context.localContext
          (psKernelExprApplyArgsCheap
            (psKernelExprInstantiateRev
              (PsKernelExpr.lam
                name type body binderInfo)
              (psKernelExprListTake count args))
            (psKernelExprListDrop count args))
          (psKernelExprApplyArgsCheap
            (psKernelExprInstantiateRev
              body
              (psKernelExprListTake
                (Nat.succ count)
                args))
            (psKernelExprListDrop
              (Nat.succ count)
              args))
          (psKernelExprApplyArgsCheap
            (psKernelExprInstantiateRev
              targetBody
              (psKernelExprListTake consumed args))
            (psKernelExprListDrop consumed args))
          hFirst
          hRestReduction

theorem psKernelBetaSpineSound_contract :
    PsKernelBetaSpineSoundLaw := by
  intro
    context
    fn
    lastLam
    body
    args
    consumed
    name
    type
    binderInfo
    hCount
    hArgsNonempty
    hLast
  have hRelation :=
    psKernelWhnfCountLambdas_refines_relation
      fn
      (psKernelExprListLength args)
      lastLam
      consumed
      hCount
  have hAvailable :
      0 < psKernelExprListLength args :=
    psKernelNatLt_lt_of_true
      0
      (psKernelExprListLength args)
      hArgsNonempty
  have hReduction :=
    psKernelWhnfCountLambdasRelation_refines_beta
      context
      args
      fn
      lastLam
      (psKernelExprListLength args)
      0
      consumed
      name
      type
      body
      binderInfo
      hRelation
      rfl
      hAvailable
      hLast
  simpa [
    psKernelExprListTake,
    psKernelExprListDrop,
    psKernelExprInstantiateRev_nil_metatheory
  ] using hReduction
