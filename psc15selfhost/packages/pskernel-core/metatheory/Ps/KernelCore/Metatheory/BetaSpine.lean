import Lean.Elab.Tactic.Omega
import Ps.KernelCore.Metatheory.SubstitutionRefinement
import Ps.KernelCore.Metatheory.ReductionCongruence
import Ps.KernelCore.Metatheory.CheckerContracts

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
          simp [
            psKernelExprInstantiateAtReferenceChanged,
            hBefore
          ] at hFst
          exact hFst.symm
      | false =>
          cases hGet :
              psKernelExprListGet
                subst
                (Nat.sub index (Nat.add start offset)) with
          | some replacement =>
              simp [
                psKernelExprInstantiateAtReferenceChanged,
                hBefore,
                hGet
              ] at hSnd
          | none =>
              cases hEmpty :
                  psKernelExprListIsEmpty subst with
              | true =>
                  simp [
                    psKernelExprInstantiateAtReferenceChanged,
                    hBefore,
                    hGet,
                    hEmpty
                  ] at hFst
                  exact hFst.symm
              | false =>
                  simp [
                    psKernelExprInstantiateAtReferenceChanged,
                    hBefore,
                    hGet,
                    hEmpty
                  ] at hSnd
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
          rw [hLift]
          simp [
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty,
            hNatLt,
            hRelative,
            psKernelExprListGet,
            psKernelExprListLength
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
