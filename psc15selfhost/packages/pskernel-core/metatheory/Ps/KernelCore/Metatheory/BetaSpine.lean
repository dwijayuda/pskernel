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
          have hLt : index < offset := by
            simp [psKernelNatGe] at hGe
            omega
          have hNatLt :
              psKernelNatLt index offset = true := by
            simp [psKernelNatLt]
            omega
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
          have hLe : offset ≤ index := by
            simp [psKernelNatGe] at hGe
            omega
          have hNatLt :
              psKernelNatLt (Nat.add index 1) offset = false := by
            simp [psKernelNatLt]
            omega
          have hRelative :
              0 <
                Nat.sub
                  (Nat.add index 1)
                  offset := by
            omega
          cases hRel :
              Nat.sub (Nat.add index 1) offset with
          | zero =>
              omega
          | succ relative =>
              simp [
                psKernelExprLiftLooseBVarsReference,
                psKernelExprLiftLooseBVarsReferenceChanged,
                hGe,
                psKernelExprInstantiateAtReference,
                psKernelExprInstantiateAtReferenceChanged,
                psKernelExprListIsEmpty,
                hNatLt,
                hRel,
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
          psKernelExprLiftLooseBVarsReferenceChanged
            fn offset 1 with
      | mk liftedFn fnChanged =>
          cases hLiftArg :
              psKernelExprLiftLooseBVarsReferenceChanged
                arg offset 1 with
          | mk liftedArg argChanged =>
              have ihFnResult := ihFn offset
              have ihArgResult := ihArg offset
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftFn
              ] at ihFnResult
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftArg
              ] at ihArgResult
              cases fnChanged <;>
                cases argChanged <;>
                simp_all [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hLiftFn,
                  hLiftArg,
                  psKernelExprInstantiateAtReference,
                  psKernelExprInstantiateAtReferenceChanged,
                  psKernelExprListIsEmpty
                ]
  | lam name type body binderInfo ihType ihBody =>
      cases hLiftType :
          psKernelExprLiftLooseBVarsReferenceChanged
            type offset 1 with
      | mk liftedType typeChanged =>
          cases hLiftBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body (Nat.succ offset) 1 with
          | mk liftedBody bodyChanged =>
              have ihTypeResult := ihType offset
              have ihBodyResult := ihBody (Nat.succ offset)
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftType
              ] at ihTypeResult
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftBody
              ] at ihBodyResult
              cases typeChanged <;>
                cases bodyChanged <;>
                simp_all [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hLiftType,
                  hLiftBody,
                  psKernelExprInstantiateAtReference,
                  psKernelExprInstantiateAtReferenceChanged,
                  psKernelExprListIsEmpty
                ]
  | forallE name type body binderInfo ihType ihBody =>
      cases hLiftType :
          psKernelExprLiftLooseBVarsReferenceChanged
            type offset 1 with
      | mk liftedType typeChanged =>
          cases hLiftBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body (Nat.succ offset) 1 with
          | mk liftedBody bodyChanged =>
              have ihTypeResult := ihType offset
              have ihBodyResult := ihBody (Nat.succ offset)
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftType
              ] at ihTypeResult
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftBody
              ] at ihBodyResult
              cases typeChanged <;>
                cases bodyChanged <;>
                simp_all [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hLiftType,
                  hLiftBody,
                  psKernelExprInstantiateAtReference,
                  psKernelExprInstantiateAtReferenceChanged,
                  psKernelExprListIsEmpty
                ]
  | letE name type value body nondep ihType ihValue ihBody =>
      cases hLiftType :
          psKernelExprLiftLooseBVarsReferenceChanged
            type offset 1 with
      | mk liftedType typeChanged =>
          cases hLiftValue :
              psKernelExprLiftLooseBVarsReferenceChanged
                value offset 1 with
          | mk liftedValue valueChanged =>
              cases hLiftBody :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    body (Nat.succ offset) 1 with
              | mk liftedBody bodyChanged =>
                  have ihTypeResult := ihType offset
                  have ihValueResult := ihValue offset
                  have ihBodyResult := ihBody (Nat.succ offset)
                  simp [
                    psKernelExprLiftLooseBVarsReference,
                    hLiftType
                  ] at ihTypeResult
                  simp [
                    psKernelExprLiftLooseBVarsReference,
                    hLiftValue
                  ] at ihValueResult
                  simp [
                    psKernelExprLiftLooseBVarsReference,
                    hLiftBody
                  ] at ihBodyResult
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
                      psKernelExprListIsEmpty
                    ]
  | mdata metadata body ihBody =>
      cases hLiftBody :
          psKernelExprLiftLooseBVarsReferenceChanged
            body offset 1 with
      | mk liftedBody bodyChanged =>
          have ihBodyResult := ihBody offset
          simp [
            psKernelExprLiftLooseBVarsReference,
            hLiftBody
          ] at ihBodyResult
          cases bodyChanged <;>
            simp_all [
              psKernelExprLiftLooseBVarsReference,
              psKernelExprLiftLooseBVarsReferenceChanged,
              hLiftBody,
              psKernelExprInstantiateAtReference,
              psKernelExprInstantiateAtReferenceChanged,
              psKernelExprListIsEmpty
            ]
  | proj typeName index body ihBody =>
      cases hLiftBody :
          psKernelExprLiftLooseBVarsReferenceChanged
            body offset 1 with
      | mk liftedBody bodyChanged =>
          have ihBodyResult := ihBody offset
          simp [
            psKernelExprLiftLooseBVarsReference,
            hLiftBody
          ] at ihBodyResult
          cases bodyChanged <;>
            simp_all [
              psKernelExprLiftLooseBVarsReference,
              psKernelExprLiftLooseBVarsReferenceChanged,
              hLiftBody,
              psKernelExprInstantiateAtReference,
              psKernelExprInstantiateAtReferenceChanged,
              psKernelExprListIsEmpty
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
  induction expr generalizing start amount with
  | bvar index =>
      cases hGe : psKernelNatGe index start with
      | false =>
          have hLt : index < start := by
            simp [psKernelNatGe] at hGe
            omega
          have hBelow :
              psKernelNatLt
                  index
                  (Nat.add start amount) =
                true := by
            simp [psKernelNatLt]
            omega
          cases amount with
          | zero =>
              simp [
                psKernelExprLiftLooseBVarsReference,
                psKernelExprLiftLooseBVarsReferenceChanged,
                hGe,
                psKernelExprInstantiateAtReference,
                psKernelExprInstantiateAtReferenceChanged,
                psKernelExprListIsEmpty,
                hBelow
              ]
          | succ remaining =>
              simp [
                psKernelExprLiftLooseBVarsReference,
                psKernelExprLiftLooseBVarsReferenceChanged,
                hGe,
                psKernelExprInstantiateAtReference,
                psKernelExprInstantiateAtReferenceChanged,
                psKernelExprListIsEmpty,
                hBelow
              ]
      | true =>
          have hLe : start ≤ index := by
            simp [psKernelNatGe] at hGe
            omega
          have hNotBelow :
              psKernelNatLt
                  (Nat.add index (Nat.succ amount))
                  (Nat.add start amount) =
                false := by
            simp [psKernelNatLt]
            omega
          have hRelative :
              Nat.sub
                  (Nat.add index (Nat.succ amount))
                  (Nat.add start amount) =
                Nat.succ (Nat.sub index start) := by
            omega
          cases amount with
          | zero =>
              simp [
                psKernelExprLiftLooseBVarsReference,
                psKernelExprLiftLooseBVarsReferenceChanged,
                hGe,
                psKernelExprInstantiateAtReference,
                psKernelExprInstantiateAtReferenceChanged,
                psKernelExprListIsEmpty,
                hNotBelow,
                hRelative,
                psKernelExprListGet,
                psKernelExprListLength
              ]
              omega
          | succ remaining =>
              simp [
                psKernelExprLiftLooseBVarsReference,
                psKernelExprLiftLooseBVarsReferenceChanged,
                hGe,
                psKernelExprInstantiateAtReference,
                psKernelExprInstantiateAtReferenceChanged,
                psKernelExprListIsEmpty,
                hNotBelow,
                hRelative,
                psKernelExprListGet,
                psKernelExprListLength
              ]
              omega
  | fvar name =>
      cases amount <;>
        simp [
          psKernelExprLiftLooseBVarsReference,
          psKernelExprLiftLooseBVarsReferenceChanged,
          psKernelExprInstantiateAtReference,
          psKernelExprInstantiateAtReferenceChanged,
          psKernelExprListIsEmpty
        ]
  | mvar name =>
      cases amount <;>
        simp [
          psKernelExprLiftLooseBVarsReference,
          psKernelExprLiftLooseBVarsReferenceChanged,
          psKernelExprInstantiateAtReference,
          psKernelExprInstantiateAtReferenceChanged,
          psKernelExprListIsEmpty
        ]
  | sort level =>
      cases amount <;>
        simp [
          psKernelExprLiftLooseBVarsReference,
          psKernelExprLiftLooseBVarsReferenceChanged,
          psKernelExprInstantiateAtReference,
          psKernelExprInstantiateAtReferenceChanged,
          psKernelExprListIsEmpty
        ]
  | const name levels =>
      cases amount <;>
        simp [
          psKernelExprLiftLooseBVarsReference,
          psKernelExprLiftLooseBVarsReferenceChanged,
          psKernelExprInstantiateAtReference,
          psKernelExprInstantiateAtReferenceChanged,
          psKernelExprListIsEmpty
        ]
  | lit literal =>
      cases amount <;>
        simp [
          psKernelExprLiftLooseBVarsReference,
          psKernelExprLiftLooseBVarsReferenceChanged,
          psKernelExprInstantiateAtReference,
          psKernelExprInstantiateAtReferenceChanged,
          psKernelExprListIsEmpty
        ]
  | app fn arg ihFn ihArg =>
      cases hLiftFn :
          psKernelExprLiftLooseBVarsReferenceChanged
            fn start (Nat.succ amount) with
      | mk liftedFn fnChanged =>
          cases hLiftArg :
              psKernelExprLiftLooseBVarsReferenceChanged
                arg start (Nat.succ amount) with
          | mk liftedArg argChanged =>
              have ihFnResult := ihFn replacement start amount
              have ihArgResult := ihArg replacement start amount
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftFn
              ] at ihFnResult
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftArg
              ] at ihArgResult
              cases fnChanged <;>
                cases argChanged <;>
                simp_all [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hLiftFn,
                  hLiftArg,
                  psKernelExprInstantiateAtReference,
                  psKernelExprInstantiateAtReferenceChanged,
                  psKernelExprListIsEmpty
                ]
  | lam name type body binderInfo ihType ihBody =>
      cases hLiftType :
          psKernelExprLiftLooseBVarsReferenceChanged
            type start (Nat.succ amount) with
      | mk liftedType typeChanged =>
          cases hLiftBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body (Nat.succ start) (Nat.succ amount) with
          | mk liftedBody bodyChanged =>
              have ihTypeResult := ihType replacement start amount
              have ihBodyResult :=
                ihBody replacement (Nat.succ start) amount
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftType
              ] at ihTypeResult
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftBody
              ] at ihBodyResult
              cases typeChanged <;>
                cases bodyChanged <;>
                simp_all [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hLiftType,
                  hLiftBody,
                  psKernelExprInstantiateAtReference,
                  psKernelExprInstantiateAtReferenceChanged,
                  psKernelExprListIsEmpty
                ]
  | forallE name type body binderInfo ihType ihBody =>
      cases hLiftType :
          psKernelExprLiftLooseBVarsReferenceChanged
            type start (Nat.succ amount) with
      | mk liftedType typeChanged =>
          cases hLiftBody :
              psKernelExprLiftLooseBVarsReferenceChanged
                body (Nat.succ start) (Nat.succ amount) with
          | mk liftedBody bodyChanged =>
              have ihTypeResult := ihType replacement start amount
              have ihBodyResult :=
                ihBody replacement (Nat.succ start) amount
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftType
              ] at ihTypeResult
              simp [
                psKernelExprLiftLooseBVarsReference,
                hLiftBody
              ] at ihBodyResult
              cases typeChanged <;>
                cases bodyChanged <;>
                simp_all [
                  psKernelExprLiftLooseBVarsReference,
                  psKernelExprLiftLooseBVarsReferenceChanged,
                  hLiftType,
                  hLiftBody,
                  psKernelExprInstantiateAtReference,
                  psKernelExprInstantiateAtReferenceChanged,
                  psKernelExprListIsEmpty
                ]
  | letE name type value body nondep ihType ihValue ihBody =>
      cases hLiftType :
          psKernelExprLiftLooseBVarsReferenceChanged
            type start (Nat.succ amount) with
      | mk liftedType typeChanged =>
          cases hLiftValue :
              psKernelExprLiftLooseBVarsReferenceChanged
                value start (Nat.succ amount) with
          | mk liftedValue valueChanged =>
              cases hLiftBody :
                  psKernelExprLiftLooseBVarsReferenceChanged
                    body (Nat.succ start) (Nat.succ amount) with
              | mk liftedBody bodyChanged =>
                  have ihTypeResult := ihType replacement start amount
                  have ihValueResult := ihValue replacement start amount
                  have ihBodyResult :=
                    ihBody replacement (Nat.succ start) amount
                  simp [
                    psKernelExprLiftLooseBVarsReference,
                    hLiftType
                  ] at ihTypeResult
                  simp [
                    psKernelExprLiftLooseBVarsReference,
                    hLiftValue
                  ] at ihValueResult
                  simp [
                    psKernelExprLiftLooseBVarsReference,
                    hLiftBody
                  ] at ihBodyResult
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
                      psKernelExprListIsEmpty
                    ]
  | mdata metadata body ihBody =>
      cases hLiftBody :
          psKernelExprLiftLooseBVarsReferenceChanged
            body start (Nat.succ amount) with
      | mk liftedBody bodyChanged =>
          have ihBodyResult := ihBody replacement start amount
          simp [
            psKernelExprLiftLooseBVarsReference,
            hLiftBody
          ] at ihBodyResult
          cases bodyChanged <;>
            simp_all [
              psKernelExprLiftLooseBVarsReference,
              psKernelExprLiftLooseBVarsReferenceChanged,
              hLiftBody,
              psKernelExprInstantiateAtReference,
              psKernelExprInstantiateAtReferenceChanged,
              psKernelExprListIsEmpty
            ]
  | proj typeName index body ihBody =>
      cases hLiftBody :
          psKernelExprLiftLooseBVarsReferenceChanged
            body start (Nat.succ amount) with
      | mk liftedBody bodyChanged =>
          have ihBodyResult := ihBody replacement start amount
          simp [
            psKernelExprLiftLooseBVarsReference,
            hLiftBody
          ] at ihBodyResult
          cases bodyChanged <;>
            simp_all [
              psKernelExprLiftLooseBVarsReference,
              psKernelExprLiftLooseBVarsReferenceChanged,
              hLiftBody,
              psKernelExprInstantiateAtReference,
              psKernelExprInstantiateAtReferenceChanged,
              psKernelExprListIsEmpty
            ]
