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
  cases amount with
  | zero =>
      simpa [
        psKernelExprLiftLooseBVarsReferenceChanged
      ] using hRun.symm
  | succ remaining =>
      cases expr with
      | bvar index =>
          cases hGe : psKernelNatGe index start with
          | false =>
              simp [
                psKernelExprLiftLooseBVarsReferenceChanged,
                hGe
              ] at hRun
              exact hRun.symm
          | true =>
              simp [
                psKernelExprLiftLooseBVarsReferenceChanged,
                hGe
              ] at hRun
      | fvar name =>
          simpa [psKernelExprLiftLooseBVarsReferenceChanged] using hRun.symm
      | mvar name =>
          simpa [psKernelExprLiftLooseBVarsReferenceChanged] using hRun.symm
      | sort level =>
          simpa [psKernelExprLiftLooseBVarsReferenceChanged] using hRun.symm
      | const name levels =>
          simpa [psKernelExprLiftLooseBVarsReferenceChanged] using hRun.symm
      | lit literal =>
          simpa [psKernelExprLiftLooseBVarsReferenceChanged] using hRun.symm
      | app fn arg =>
          cases hFn :
              psKernelExprLiftLooseBVarsReferenceChanged
                fn start (Nat.succ remaining) with
          | mk liftedFn fnChanged =>
              cases hArg :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    arg start (Nat.succ remaining) with
              | mk liftedArg argChanged =>
                  cases fnChanged <;>
                    cases argChanged <;>
                    simp [
                      psKernelExprLiftLooseBVarsReferenceChanged,
                      hFn,
                      hArg
                    ] at hRun
                  exact hRun.symm
      | lam name type body binderInfo =>
          cases hType :
              psKernelExprLiftLooseBVarsReferenceChanged
                type start (Nat.succ remaining) with
          | mk liftedType typeChanged =>
              cases hBody :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    body (Nat.succ start) (Nat.succ remaining) with
              | mk liftedBody bodyChanged =>
                  cases typeChanged <;>
                    cases bodyChanged <;>
                    simp [
                      psKernelExprLiftLooseBVarsReferenceChanged,
                      hType,
                      hBody
                    ] at hRun
                  exact hRun.symm
      | forallE name type body binderInfo =>
          cases hType :
              psKernelExprLiftLooseBVarsReferenceChanged
                type start (Nat.succ remaining) with
          | mk liftedType typeChanged =>
              cases hBody :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    body (Nat.succ start) (Nat.succ remaining) with
              | mk liftedBody bodyChanged =>
                  cases typeChanged <;>
                    cases bodyChanged <;>
                    simp [
                      psKernelExprLiftLooseBVarsReferenceChanged,
                      hType,
                      hBody
                    ] at hRun
                  exact hRun.symm
      | letE name type value body nondep =>
          cases hType :
              psKernelExprLiftLooseBVarsReferenceChanged
                type start (Nat.succ remaining) with
          | mk liftedType typeChanged =>
              cases hValue :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    value start (Nat.succ remaining) with
              | mk liftedValue valueChanged =>
                  cases hBody :
                      psKernelExprLiftLooseBVarsReferenceChanged
                        body (Nat.succ start) (Nat.succ remaining) with
                  | mk liftedBody bodyChanged =>
                      cases typeChanged <;>
                        cases valueChanged <;>
                        cases bodyChanged <;>
                        simp [
                          psKernelExprLiftLooseBVarsReferenceChanged,
                          hType,
                          hValue,
                          hBody
                        ] at hRun
                      exact hRun.symm
      | mdata metadata body =>
          cases hBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body start (Nat.succ remaining) with
          | mk liftedBody bodyChanged =>
              cases bodyChanged <;>
                simp [
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hBody
                ] at hRun
              exact hRun.symm
      | proj typeName index body =>
          cases hBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body start (Nat.succ remaining) with
          | mk liftedBody bodyChanged =>
              cases bodyChanged <;>
                simp [
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hBody
                ] at hRun
              exact hRun.symm

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
  cases expr with
  | bvar index =>
      cases hBefore :
          psKernelNatLt index (Nat.add start offset) with
      | true =>
          simpa [
            psKernelExprInstantiateAtReferenceChanged,
            hBefore
          ] using hRun
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
              ] at hRun
          | none =>
              cases hEmpty :
                  psKernelExprListIsEmpty subst with
              | true =>
                  simpa [
                    psKernelExprInstantiateAtReferenceChanged,
                    hBefore,
                    hGet,
                    hEmpty
                  ] using hRun
              | false =>
                  simp [
                    psKernelExprInstantiateAtReferenceChanged,
                    hBefore,
                    hGet,
                    hEmpty
                  ] at hRun
  | fvar name =>
      simpa [psKernelExprInstantiateAtReferenceChanged] using hRun
  | mvar name =>
      simpa [psKernelExprInstantiateAtReferenceChanged] using hRun
  | sort level =>
      simpa [psKernelExprInstantiateAtReferenceChanged] using hRun
  | const name levels =>
      simpa [psKernelExprInstantiateAtReferenceChanged] using hRun
  | lit literal =>
      simpa [psKernelExprInstantiateAtReferenceChanged] using hRun
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
                ] at hRun
              exact hRun.1
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
                ] at hRun
              exact hRun.1
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
                ] at hRun
              exact hRun.1
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
                    ] at hRun
                  exact hRun.1
  | mdata metadata body =>
      cases hBody :
          psKernelExprInstantiateAtReferenceChanged
            body start subst offset with
      | mk bodyResult bodyChanged =>
          cases bodyChanged <;>
            simp [
              psKernelExprInstantiateAtReferenceChanged,
              hBody
            ] at hRun
          exact hRun.1
  | proj typeName index body =>
      cases hBody :
          psKernelExprInstantiateAtReferenceChanged
            body start subst offset with
      | mk bodyResult bodyChanged =>
          cases bodyChanged <;>
            simp [
              psKernelExprInstantiateAtReferenceChanged,
              hBody
            ] at hRun
          exact hRun.1


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
                omega
          have hBle :
              Nat.ble index offset = true :=
            Nat.ble_eq_true_of_le (Nat.le_of_lt hLt)
          have hNatLt :
              psKernelNatLt index offset = true := by
            simp [psKernelNatLt, hBeq, hBle]
          simp [
            psKernelExprLiftLooseBVarsReference,
            psKernelExprLiftLooseBVarsReferenceChanged,
            hGe,
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
          rw [hRelative]
          simp [
            psKernelExprLiftLooseBVarsReference,
            psKernelExprLiftLooseBVarsReferenceChanged,
            hGe,
            psKernelExprInstantiateAtReference,
            psKernelExprInstantiateAtReferenceChanged,
            psKernelExprListIsEmpty,
            hNatLt,
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
      cases hLiftFn :
          psKernelExprLiftLooseBVarsReferenceChanged fn offset 1 with
      | mk liftedFn fnChanged =>
          cases hLiftArg :
              psKernelExprLiftLooseBVarsReferenceChanged arg offset 1 with
          | mk liftedArg argChanged =>
              have ihFnResult := ihFn offset
              have ihArgResult := ihArg offset
              simp [psKernelExprLiftLooseBVarsReference, hLiftFn] at ihFnResult
              simp [psKernelExprLiftLooseBVarsReference, hLiftArg] at ihArgResult
              cases fnChanged <;>
                cases argChanged <;>
                simp_all [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hLiftFn,
                  hLiftArg,
                  psKernelExprInstantiateAtReference,
                  psKernelExprInstantiateAtReferenceChanged,
                  psKernelExprListIsEmpty,
                  psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                ]
  | lam name type body binderInfo ihType ihBody =>
      cases hLiftType :
          psKernelExprLiftLooseBVarsReferenceChanged type offset 1 with
      | mk liftedType typeChanged =>
          cases hLiftBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body (Nat.succ offset) 1 with
          | mk liftedBody bodyChanged =>
              have ihTypeResult := ihType offset
              have ihBodyResult := ihBody (Nat.succ offset)
              simp [psKernelExprLiftLooseBVarsReference, hLiftType] at ihTypeResult
              simp [psKernelExprLiftLooseBVarsReference, hLiftBody] at ihBodyResult
              cases typeChanged <;>
                cases bodyChanged <;>
                simp_all [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hLiftType,
                  hLiftBody,
                  psKernelExprInstantiateAtReference,
                  psKernelExprInstantiateAtReferenceChanged,
                  psKernelExprListIsEmpty,
                  psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                ]
  | forallE name type body binderInfo ihType ihBody =>
      cases hLiftType :
          psKernelExprLiftLooseBVarsReferenceChanged type offset 1 with
      | mk liftedType typeChanged =>
          cases hLiftBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body (Nat.succ offset) 1 with
          | mk liftedBody bodyChanged =>
              have ihTypeResult := ihType offset
              have ihBodyResult := ihBody (Nat.succ offset)
              simp [psKernelExprLiftLooseBVarsReference, hLiftType] at ihTypeResult
              simp [psKernelExprLiftLooseBVarsReference, hLiftBody] at ihBodyResult
              cases typeChanged <;>
                cases bodyChanged <;>
                simp_all [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hLiftType,
                  hLiftBody,
                  psKernelExprInstantiateAtReference,
                  psKernelExprInstantiateAtReferenceChanged,
                  psKernelExprListIsEmpty,
                  psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                ]
  | letE name type value body nondep ihType ihValue ihBody =>
      cases hLiftType :
          psKernelExprLiftLooseBVarsReferenceChanged type offset 1 with
      | mk liftedType typeChanged =>
          cases hLiftValue :
              psKernelExprLiftLooseBVarsReferenceChanged value offset 1 with
          | mk liftedValue valueChanged =>
              cases hLiftBody :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    body (Nat.succ offset) 1 with
              | mk liftedBody bodyChanged =>
                  have ihTypeResult := ihType offset
                  have ihValueResult := ihValue offset
                  have ihBodyResult := ihBody (Nat.succ offset)
                  simp [psKernelExprLiftLooseBVarsReference, hLiftType] at ihTypeResult
                  simp [psKernelExprLiftLooseBVarsReference, hLiftValue] at ihValueResult
                  simp [psKernelExprLiftLooseBVarsReference, hLiftBody] at ihBodyResult
                  cases typeChanged <;>
                    cases valueChanged <;>
                    cases bodyChanged <;>
                    simp_all [
                      psKernelExprLiftLooseBVarsReference,
                      psKernelExprLiftLooseBVarsReferenceChanged,
                      hLiftType,
                      hLiftValue,
                      hLiftBody,
                      psKernelExprInstantiateAtReference,
                      psKernelExprInstantiateAtReferenceChanged,
                      psKernelExprListIsEmpty,
                      psKernelExprLiftLooseBVarsReferenceChanged_false_fst
                    ]
  | mdata metadata body ihBody =>
      cases hLiftBody :
          psKernelExprLiftLooseBVarsReferenceChanged body offset 1 with
      | mk liftedBody bodyChanged =>
          have ihBodyResult := ihBody offset
          simp [psKernelExprLiftLooseBVarsReference, hLiftBody] at ihBodyResult
          cases bodyChanged <;>
            simp_all [
              psKernelExprLiftLooseBVarsReference,
              psKernelExprLiftLooseBVarsReferenceChanged,
              hLiftBody,
              psKernelExprInstantiateAtReference,
              psKernelExprInstantiateAtReferenceChanged,
              psKernelExprListIsEmpty,
              psKernelExprLiftLooseBVarsReferenceChanged_false_fst
            ]
  | proj typeName index body ihBody =>
      cases hLiftBody :
          psKernelExprLiftLooseBVarsReferenceChanged body offset 1 with
      | mk liftedBody bodyChanged =>
          have ihBodyResult := ihBody offset
          simp [psKernelExprLiftLooseBVarsReference, hLiftBody] at ihBodyResult
          cases bodyChanged <;>
            simp_all [
              psKernelExprLiftLooseBVarsReference,
              psKernelExprLiftLooseBVarsReferenceChanged,
              hLiftBody,
              psKernelExprInstantiateAtReference,
              psKernelExprInstantiateAtReferenceChanged,
              psKernelExprListIsEmpty,
              psKernelExprLiftLooseBVarsReferenceChanged_false_fst
            ]


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
