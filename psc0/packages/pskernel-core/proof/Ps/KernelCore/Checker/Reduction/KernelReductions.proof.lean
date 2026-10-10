import Ps.KernelCore.Checker.Reduction.KernelReductions
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelNoRecursorReduction_none
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    psKernelNoRecursorReduction
        context state expr cheapRec cheapProj =
      Except.ok (Prod.mk Option.none state) := by
  rfl


theorem psKernelReduceQuotWith_not_initialized
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (h : context.environment.quotInitialized = false) :
    psKernelReduceQuotWith
        publicWhnf
        context
        state
        expr =
      Except.ok
        (Prod.mk Option.none state) := by
  simp [psKernelReduceQuotWith, h]


theorem psKernelReduceNatWith_add_literals_refines
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state state1 state2 : PsKernelCheckerState)
    (op : PsKernelName)
    (left right : Nat)
    (hAdd :
      psKernelNameEq op psKernelNatAddName = true)
    (hLeft :
      publicWhnf
          context
          state
          (PsKernelExpr.lit
            (PsKernelLiteral.nat left)) =
        Except.ok
          (Prod.mk
            (PsKernelExpr.lit
              (PsKernelLiteral.nat left))
            state1))
    (hRight :
      publicWhnf
          context
          state1
          (PsKernelExpr.lit
            (PsKernelLiteral.nat right)) =
        Except.ok
          (Prod.mk
            (PsKernelExpr.lit
              (PsKernelLiteral.nat right))
            state2))
    (hSize :
      psKernelCheckNatSize
          context.maxNatSize
          (Nat.add left right) =
        Except.ok Unit.unit) :
    let original :=
      PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit
            (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat right))
    let result :=
      PsKernelExpr.lit
        (PsKernelLiteral.nat
          (Nat.add left right))
    psKernelReduceNatWith
        publicWhnf
        context
        state
        original =
      Except.ok
        (Prod.mk
          (Option.some result)
          state2) ∧
    PsKernelReductionStep
      context.environment
      context.localContext
      original
      result := by
  dsimp
  constructor
  · cases hCheck :
        psKernelCheckNatSize
          context.maxNatSize
          (left + right) with
    | error error =>
        simp [hCheck] at hSize
    | ok checked =>
        cases checked
        simp [
          psKernelReduceNatWith,
      psKernelNatBinarySupported,
      hAdd,
          hLeft,
          hRight,
          psKernelExprNatLiteralValue,
          psKernelReduceNatBinary,
          hAdd,
          hCheck
        ]
  · exact
      PsKernelReductionStep.natAdd
        op
        left
        right
        hAdd


theorem psKernelReduceNatWith_succ_literal_refines
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (op : PsKernelName)
    (value : Nat)
    (hSucc :
      psKernelNameEq op psKernelNatSuccName = true)
    (hWhnf :
      publicWhnf
          context
          state
          (PsKernelExpr.lit (PsKernelLiteral.nat value)) =
        Except.ok
          (Prod.mk
            (PsKernelExpr.lit (PsKernelLiteral.nat value))
            nextState))
    (hSize :
      psKernelCheckNatSize
          context.maxNatSize
          (Nat.succ value) =
        Except.ok Unit.unit) :
    let original :=
      PsKernelExpr.app
        (PsKernelExpr.const op List.nil)
        (PsKernelExpr.lit (PsKernelLiteral.nat value))
    let result :=
      PsKernelExpr.lit (PsKernelLiteral.nat (Nat.succ value))
    psKernelReduceNatWith publicWhnf context state original =
      Except.ok (Prod.mk (Option.some result) nextState) ∧
    PsKernelReductionStep
      context.environment
      context.localContext
      original
      result := by
  dsimp
  constructor
  · cases hCheck :
        psKernelCheckNatSize
          context.maxNatSize
          (Nat.succ value) with
    | error error =>
        simp [hCheck] at hSize
    | ok checked =>
        cases checked
        simp [
          psKernelReduceNatWith,
          hSucc,
          hWhnf,
          psKernelExprNatLiteralValue,
          hCheck
        ]
  · exact
      PsKernelReductionStep.natSucc
        op value hSucc


theorem psKernelReduceNatWith_sub_literals_refines
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state state1 state2 : PsKernelCheckerState)
    (op : PsKernelName)
    (left right : Nat)
    (hNotAdd :
      psKernelNameEq op psKernelNatAddName = false)
    (hSub :
      psKernelNameEq op psKernelNatSubName = true)
    (hLeft :
      publicWhnf
          context
          state
          (PsKernelExpr.lit
            (PsKernelLiteral.nat left)) =
        Except.ok
          (Prod.mk
            (PsKernelExpr.lit
              (PsKernelLiteral.nat left))
            state1))
    (hRight :
      publicWhnf
          context
          state1
          (PsKernelExpr.lit
            (PsKernelLiteral.nat right)) =
        Except.ok
          (Prod.mk
            (PsKernelExpr.lit
              (PsKernelLiteral.nat right))
            state2))
    (hSize :
      psKernelCheckNatSize
          context.maxNatSize
          (Nat.sub left right) =
        Except.ok Unit.unit) :
    let original :=
      PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit
            (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat right))
    let result :=
      PsKernelExpr.lit
        (PsKernelLiteral.nat
          (Nat.sub left right))
    psKernelReduceNatWith
        publicWhnf
        context
        state
        original =
      Except.ok
        (Prod.mk
          (Option.some result)
          state2) ∧
    PsKernelReductionStep
      context.environment
      context.localContext
      original
      result := by
  dsimp
  constructor
  · have hBinary :
        psKernelReduceNatBinary
            context.maxNatSize
            op
            left
            right =
          Except.ok
            (Option.some
              (PsKernelExpr.lit
                (PsKernelLiteral.nat
                  (Nat.sub left right)))) := by
      unfold psKernelReduceNatBinary
      simp only [
        hNotAdd,
        Bool.false_eq_true,
        if_false,
        hSub,
        if_true
      ]
      rw [hSize]
    simp [
      psKernelReduceNatWith,
      psKernelNatBinarySupported,
      hNotAdd, hSub,
      hLeft,
      hRight,
      psKernelExprNatLiteralValue,
      hBinary
    ]
  · exact
      PsKernelReductionStep.natSub
        op
        left
        right
        hSub

theorem psKernelReduceNatWith_mul_literals_refines
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state state1 state2 : PsKernelCheckerState)
    (op : PsKernelName)
    (left right : Nat)
    (hNotAdd :
      psKernelNameEq op psKernelNatAddName = false)
    (hNotSub :
      psKernelNameEq op psKernelNatSubName = false)
    (hMul :
      psKernelNameEq op psKernelNatMulName = true)
    (hLeft :
      publicWhnf
          context
          state
          (PsKernelExpr.lit
            (PsKernelLiteral.nat left)) =
        Except.ok
          (Prod.mk
            (PsKernelExpr.lit
              (PsKernelLiteral.nat left))
            state1))
    (hRight :
      publicWhnf
          context
          state1
          (PsKernelExpr.lit
            (PsKernelLiteral.nat right)) =
        Except.ok
          (Prod.mk
            (PsKernelExpr.lit
              (PsKernelLiteral.nat right))
            state2))
    (hSize :
      psKernelCheckNatSize
          context.maxNatSize
          (Nat.mul left right) =
        Except.ok Unit.unit) :
    let original :=
      PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit
            (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat right))
    let result :=
      PsKernelExpr.lit
        (PsKernelLiteral.nat
          (Nat.mul left right))
    psKernelReduceNatWith
        publicWhnf
        context
        state
        original =
      Except.ok
        (Prod.mk
          (Option.some result)
          state2) ∧
    PsKernelReductionStep
      context.environment
      context.localContext
      original
      result := by
  dsimp
  constructor
  · have hBinary :
        psKernelReduceNatBinary
            context.maxNatSize
            op
            left
            right =
          Except.ok
            (Option.some
              (PsKernelExpr.lit
                (PsKernelLiteral.nat
                  (Nat.mul left right)))) := by
      unfold psKernelReduceNatBinary
      simp only [
        hNotAdd,
        Bool.false_eq_true,
        if_false,
        hNotSub,
        hMul,
        if_true
      ]
      rw [hSize]
    simp [
      psKernelReduceNatWith,
      psKernelNatBinarySupported,
      hNotAdd, hNotSub, hMul,
      hLeft,
      hRight,
      psKernelExprNatLiteralValue,
      hBinary
    ]
  · exact
      PsKernelReductionStep.natMul
        op
        left
        right
        hMul
