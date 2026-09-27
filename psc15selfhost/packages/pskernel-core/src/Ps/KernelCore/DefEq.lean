import Ps.KernelCore.Infer

def psKernelCoreLevelListEquivalent
    (left : PsKernelCoreList PsKernelCoreLevel) :
    PsKernelCoreList PsKernelCoreLevel -> Bool :=
  match left with
  | PsKernelCoreList.nil =>
      fun (right : PsKernelCoreList PsKernelCoreLevel) =>
        match right with
        | PsKernelCoreList.nil => true
        | _ => false
  | PsKernelCoreList.cons leftHead leftTail =>
      let tailEquivalent : PsKernelCoreList PsKernelCoreLevel -> Bool :=
        psKernelCoreLevelListEquivalent leftTail;
      fun (right : PsKernelCoreList PsKernelCoreLevel) =>
        match right with
        | PsKernelCoreList.nil => false
        | PsKernelCoreList.cons rightHead rightTail =>
            if psKernelCoreLevelEquivalent leftHead rightHead then
              tailEquivalent rightTail
            else
              false

def psKernelCoreDefEqIsProp
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (typeExpr : PsKernelCoreExpr) :
    PsKernelCoreResult String Bool :=
  match psKernelCoreInfer budget env lctx typeExpr with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error message
  | PsKernelCoreResult.ok inferredType =>
      match psKernelCoreWhnf budget env lctx inferredType with
      | PsKernelCoreResult.error message =>
          PsKernelCoreResult.error message
      | PsKernelCoreResult.ok reduced =>
          match reduced with
          | PsKernelCoreExpr.sort level =>
              PsKernelCoreResult.ok
                (psKernelCoreLevelNormalizesToZero level)
          | _ => PsKernelCoreResult.error "expected sort"

def psKernelCoreDefEqEtaLeft
    (remaining : Nat)
    (smaller :
      PsKernelCoreEnvironment ->
      PsKernelCoreLocalContext ->
      PsKernelCoreExpr ->
      PsKernelCoreExpr ->
      PsKernelCoreResult String Bool)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (other : PsKernelCoreExpr) :
    PsKernelCoreResult String Bool :=
  match psKernelCoreInfer remaining env lctx other with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error message
  | PsKernelCoreResult.ok otherType =>
      match psKernelCoreWhnf remaining env lctx otherType with
      | PsKernelCoreResult.error message =>
          PsKernelCoreResult.error message
      | PsKernelCoreResult.ok exposed =>
          match exposed with
          | PsKernelCoreExpr.forallE name domain _ binderInfo =>
              let eta :=
                PsKernelCoreExpr.lam
                  name
                  domain
                  (PsKernelCoreExpr.app other (PsKernelCoreExpr.bvar 0))
                  binderInfo;
              smaller env lctx left eta
          | _ => PsKernelCoreResult.ok false

def psKernelCoreDefEqEtaRight
    (remaining : Nat)
    (smaller :
      PsKernelCoreEnvironment ->
      PsKernelCoreLocalContext ->
      PsKernelCoreExpr ->
      PsKernelCoreExpr ->
      PsKernelCoreResult String Bool)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (other : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreResult String Bool :=
  match psKernelCoreInfer remaining env lctx other with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error message
  | PsKernelCoreResult.ok otherType =>
      match psKernelCoreWhnf remaining env lctx otherType with
      | PsKernelCoreResult.error message =>
          PsKernelCoreResult.error message
      | PsKernelCoreResult.ok exposed =>
          match exposed with
          | PsKernelCoreExpr.forallE name domain _ binderInfo =>
              let eta :=
                PsKernelCoreExpr.lam
                  name
                  domain
                  (PsKernelCoreExpr.app other (PsKernelCoreExpr.bvar 0))
                  binderInfo;
              smaller env lctx eta right
          | _ => PsKernelCoreResult.ok false

def psKernelCoreDefEqAfterProof
    (remaining : Nat)
    (smaller :
      PsKernelCoreEnvironment ->
      PsKernelCoreLocalContext ->
      PsKernelCoreExpr ->
      PsKernelCoreExpr ->
      PsKernelCoreResult String Bool)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreResult String Bool :=
  match left with
  | PsKernelCoreExpr.lam _ _ _ _ =>
      psKernelCoreDefEqEtaLeft remaining smaller env lctx left right
  | _ =>
      match right with
      | PsKernelCoreExpr.lam _ _ _ _ =>
          psKernelCoreDefEqEtaRight remaining smaller env lctx left right
      | _ =>
          match left with
          | PsKernelCoreExpr.app leftFn leftArg =>
              match right with
              | PsKernelCoreExpr.app rightFn rightArg =>
                  match smaller env lctx leftFn rightFn with
                  | PsKernelCoreResult.error message =>
                      PsKernelCoreResult.error message
                  | PsKernelCoreResult.ok false =>
                      PsKernelCoreResult.ok false
                  | PsKernelCoreResult.ok true =>
                      smaller env lctx leftArg rightArg
              | _ => PsKernelCoreResult.ok false
          | _ => PsKernelCoreResult.ok false

def psKernelCoreDefEqFallback
    (remaining : Nat)
    (smaller :
      PsKernelCoreEnvironment ->
      PsKernelCoreLocalContext ->
      PsKernelCoreExpr ->
      PsKernelCoreExpr ->
      PsKernelCoreResult String Bool)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreResult String Bool :=
  match left with
  | PsKernelCoreExpr.proj _ _ _ =>
      PsKernelCoreResult.error
        "projection definitional equality unavailable before inductive metadata"
  | _ =>
      match right with
      | PsKernelCoreExpr.proj _ _ _ =>
          PsKernelCoreResult.error
            "projection definitional equality unavailable before inductive metadata"
      | _ =>
          match psKernelCoreInfer remaining env lctx left with
          | PsKernelCoreResult.error message =>
              PsKernelCoreResult.error message
          | PsKernelCoreResult.ok leftType =>
              match psKernelCoreDefEqIsProp remaining env lctx leftType with
              | PsKernelCoreResult.error message =>
                  PsKernelCoreResult.error message
              | PsKernelCoreResult.ok true =>
                  match psKernelCoreInfer remaining env lctx right with
                  | PsKernelCoreResult.error message =>
                      PsKernelCoreResult.error message
                  | PsKernelCoreResult.ok rightType =>
                      smaller env lctx leftType rightType
              | PsKernelCoreResult.ok false =>
                  psKernelCoreDefEqAfterProof
                    remaining smaller env lctx left right

def psKernelCoreDefEqCompareLambda
    (smaller :
      PsKernelCoreEnvironment ->
      PsKernelCoreLocalContext ->
      PsKernelCoreExpr ->
      PsKernelCoreExpr ->
      PsKernelCoreResult String Bool)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (leftDomain leftBody : PsKernelCoreExpr)
    (rightName : PsKernelCoreName)
    (rightDomain rightBody : PsKernelCoreExpr)
    (rightBinderInfo : PsKernelCoreBinderInfo) :
    PsKernelCoreResult String Bool :=
  match smaller env lctx leftDomain rightDomain with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error message
  | PsKernelCoreResult.ok false =>
      PsKernelCoreResult.ok false
  | PsKernelCoreResult.ok true =>
      let fresh := psKernelCoreInferFreshName lctx rightName;
      let child :=
        psKernelCoreLocalContextAddLocal
          lctx fresh rightName rightDomain rightBinderInfo;
      let freshExpr := PsKernelCoreExpr.fvar fresh;
      let openedLeft := psKernelCoreExprInstantiate1 leftBody freshExpr;
      let openedRight := psKernelCoreExprInstantiate1 rightBody freshExpr;
      smaller env child openedLeft openedRight

def psKernelCoreIsDefEq
    (budget : Nat) :
    PsKernelCoreEnvironment ->
    PsKernelCoreLocalContext ->
    PsKernelCoreExpr ->
    PsKernelCoreExpr ->
    PsKernelCoreResult String Bool :=
  match budget with
  | Nat.zero =>
      fun (_env : PsKernelCoreEnvironment)
          (_lctx : PsKernelCoreLocalContext)
          (_left : PsKernelCoreExpr)
          (_right : PsKernelCoreExpr) =>
        PsKernelCoreResult.error "defeq budget exhausted"
  | Nat.succ remaining =>
      let smaller :
          PsKernelCoreEnvironment ->
          PsKernelCoreLocalContext ->
          PsKernelCoreExpr ->
          PsKernelCoreExpr ->
          PsKernelCoreResult String Bool :=
        psKernelCoreIsDefEq remaining;
      fun (env : PsKernelCoreEnvironment)
          (lctx : PsKernelCoreLocalContext)
          (left : PsKernelCoreExpr)
          (right : PsKernelCoreExpr) =>
        if psKernelCoreExprEq left right then
          PsKernelCoreResult.ok true
        else
          match psKernelCoreWhnf remaining env lctx left with
          | PsKernelCoreResult.error message =>
              PsKernelCoreResult.error message
          | PsKernelCoreResult.ok leftReduced =>
              match psKernelCoreWhnf remaining env lctx right with
              | PsKernelCoreResult.error message =>
                  PsKernelCoreResult.error message
              | PsKernelCoreResult.ok rightReduced =>
                  if psKernelCoreExprEq leftReduced rightReduced then
                    PsKernelCoreResult.ok true
                  else
                    match leftReduced with
                    | PsKernelCoreExpr.sort leftLevel =>
                        match rightReduced with
                        | PsKernelCoreExpr.sort rightLevel =>
                            PsKernelCoreResult.ok
                              (psKernelCoreLevelEquivalent leftLevel rightLevel)
                        | _ =>
                            psKernelCoreDefEqFallback
                              remaining smaller env lctx leftReduced rightReduced
                    | PsKernelCoreExpr.lit leftLiteral =>
                        match rightReduced with
                        | PsKernelCoreExpr.lit rightLiteral =>
                            PsKernelCoreResult.ok
                              (psKernelCoreLiteralEq leftLiteral rightLiteral)
                        | _ =>
                            psKernelCoreDefEqFallback
                              remaining smaller env lctx leftReduced rightReduced
                    | PsKernelCoreExpr.lam _ leftDomain leftBody _ =>
                        match rightReduced with
                        | PsKernelCoreExpr.lam
                            rightName rightDomain rightBody rightBinderInfo =>
                            psKernelCoreDefEqCompareLambda
                              smaller env lctx
                              leftDomain leftBody
                              rightName rightDomain rightBody rightBinderInfo
                        | _ =>
                            psKernelCoreDefEqFallback
                              remaining smaller env lctx leftReduced rightReduced
                    | PsKernelCoreExpr.forallE _ leftDomain leftBody _ =>
                        match rightReduced with
                        | PsKernelCoreExpr.forallE
                            rightName rightDomain rightBody rightBinderInfo =>
                            psKernelCoreDefEqCompareLambda
                              smaller env lctx
                              leftDomain leftBody
                              rightName rightDomain rightBody rightBinderInfo
                        | _ =>
                            psKernelCoreDefEqFallback
                              remaining smaller env lctx leftReduced rightReduced
                    | PsKernelCoreExpr.const leftName leftLevels =>
                        match rightReduced with
                        | PsKernelCoreExpr.const rightName rightLevels =>
                            if psKernelCoreNameEq leftName rightName then
                              if psKernelCoreLevelListEquivalent
                                  leftLevels rightLevels then
                                PsKernelCoreResult.ok true
                              else
                                psKernelCoreDefEqFallback
                                  remaining smaller env lctx
                                  leftReduced rightReduced
                            else
                              psKernelCoreDefEqFallback
                                remaining smaller env lctx
                                leftReduced rightReduced
                        | _ =>
                            psKernelCoreDefEqFallback
                              remaining smaller env lctx leftReduced rightReduced
                    | PsKernelCoreExpr.fvar leftName =>
                        match rightReduced with
                        | PsKernelCoreExpr.fvar rightName =>
                            if psKernelCoreNameEq leftName rightName then
                              PsKernelCoreResult.ok true
                            else
                              psKernelCoreDefEqFallback
                                remaining smaller env lctx
                                leftReduced rightReduced
                        | _ =>
                            psKernelCoreDefEqFallback
                              remaining smaller env lctx leftReduced rightReduced
                    | _ =>
                        psKernelCoreDefEqFallback
                          remaining smaller env lctx leftReduced rightReduced
