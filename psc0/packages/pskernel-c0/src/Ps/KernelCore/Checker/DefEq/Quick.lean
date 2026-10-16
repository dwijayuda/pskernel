import Ps.KernelCore.Checker.DefEq.BinderSpines

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
  if psKernelExprEq left right then
    Except.ok
      (Prod.mk (Option.some true) state)
  else if psKernelSemanticPairCacheEligible left right &&
      psKernelExprPairSetContains state.success left right then
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
