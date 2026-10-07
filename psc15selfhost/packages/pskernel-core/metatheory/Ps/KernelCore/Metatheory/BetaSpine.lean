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
