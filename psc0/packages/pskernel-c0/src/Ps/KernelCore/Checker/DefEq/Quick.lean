import Ps.KernelCore.Checker.DefEq.BinderSpines
import Ps.KernelCore.Core.ExprDecidableEq

/-
Lean 4.34 quick definitional-equality rules.

These checks run before expensive reduction:
- exact/semantic expression equality;
- successful pair cache lookup;
- Sort level equivalence;
- literals;
- constants with equivalent universe arguments;
- same free variable;
- same-shape applications/binders where the structural helpers can decide.

No transitive equivalence closure is permitted.
-/

/--
  Shape-specific quick checks when both structural equality and the
  successful-conversion cache have already been checked and missed.
  This internal entry avoids traversing large terms twice in the accepting
  DefEq orchestration. Call it only under those established guards.
-/
def psKernelDefEqQuickAfterCommon
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  match left with
  | PsKernelExpr.lam _ _ _ _ =>
      match right with
      | PsKernelExpr.lam _ _ _ _ =>
          match
              psKernelDefEqLambdaSpine
                defeq
                context
                state
                left
                right with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              Except.ok
                (Prod.mk
                  (Option.some
                    (Prod.fst result))
                  (Prod.snd result))
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.forallE _ _ _ _ =>
      match right with
      | PsKernelExpr.forallE _ _ _ _ =>
          match
              psKernelDefEqForallSpine
                defeq
                context
                state
                left
                right with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              Except.ok
                (Prod.mk
                  (Option.some
                    (Prod.fst result))
                  (Prod.snd result))
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.sort leftLevel =>
      match right with
      | PsKernelExpr.sort rightLevel =>
          Except.ok
            (Prod.mk
              (Option.some
                (psKernelLevelEquivalent
                  leftLevel
                  rightLevel))
              state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.mdata _ leftBody =>
      match right with
      | PsKernelExpr.mdata _ rightBody =>
          match
              defeq
                context
                state
                leftBody
                rightBody with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              Except.ok
                (Prod.mk
                  (Option.some
                    (Prod.fst result))
                  (Prod.snd result))
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.lit leftLiteral =>
      match right with
      | PsKernelExpr.lit rightLiteral =>
          Except.ok
            (Prod.mk
              (Option.some
                (psKernelLiteralEq
                  leftLiteral
                  rightLiteral))
              state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | _ =>
      Except.ok
        (Prod.mk Option.none state)

/-- Pure quick-DefEq success-cache guard with the cheap miss FIRST.
    Most comparisons are cache misses. Historically the guard scanned both
    expressions for FVars before querying the success pair, potentially
    expanding a shared DAG. The original guard is a pure conjunction,
    so the order can change cost but not the source Boolean judgment. -/
def psKernelC0CertifiedDefEqSuccessGuard
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) : Bool :=
  psKernelExprPairSetContains state.success left right &&
    psKernelC0CertifiedSemanticPairEligible left right

/-- Exact original source Boolean for EVERY checker state and pair,
    including local FVars and both cached and uncached comparisons. -/
theorem psKernelC0CertifiedDefEqSuccessGuard_source
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    psKernelC0CertifiedDefEqSuccessGuard state left right =
      (psKernelSemanticPairCacheEligible left right &&
        psKernelExprPairSetContains state.success left right) := by
  simp only [psKernelC0CertifiedDefEqSuccessGuard,
    psKernelC0CertifiedSemanticPairEligible_source]
  exact Bool.and_comm _ _

/-- General-purpose quick path retains its original guard semantics. -/
def psKernelDefEqQuick
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  if psKernelC0MemoizedExprEq left right then
    Except.ok
      (Prod.mk (Option.some true) state)
  -- The all-input source-equivalent certified pair guard avoids the
  -- historical exponential FVar traversal in quick DefEq cache screening.
  -- Actual equality/cache success remains checked by the original set.
  else if psKernelC0CertifiedDefEqSuccessGuard state left right then
    Except.ok
      (Prod.mk (Option.some true) state)
  else
    psKernelDefEqQuickAfterCommon defeq context state left right

def psKernelLevelListsEquivalent
    (left : List PsKernelLevel) :
    List PsKernelLevel -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsKernelLevel) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller :=
        psKernelLevelListsEquivalent leftTail;
      fun (right : List PsKernelLevel) =>
        match right with
        | List.nil =>
            false
        | List.cons rightHead rightTail =>
            if
                psKernelLevelEquivalent
                  leftHead
                  rightHead then
              smaller rightTail
            else
              false
