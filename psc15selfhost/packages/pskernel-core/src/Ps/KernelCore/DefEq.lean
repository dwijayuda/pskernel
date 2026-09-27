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

inductive PsKernelCoreDefEqPlan where
  | done (result : PsKernelCoreResult String Bool)
  | compare
      (lctx : PsKernelCoreLocalContext)
      (left : PsKernelCoreExpr)
      (right : PsKernelCoreExpr)
  | compareThen
      (firstLctx : PsKernelCoreLocalContext)
      (firstLeft : PsKernelCoreExpr)
      (firstRight : PsKernelCoreExpr)
      (secondLctx : PsKernelCoreLocalContext)
      (secondLeft : PsKernelCoreExpr)
      (secondRight : PsKernelCoreExpr)

def psKernelCoreDefEqDoneError
    (message : String) : PsKernelCoreDefEqPlan :=
  PsKernelCoreDefEqPlan.done (PsKernelCoreResult.error message)

def psKernelCoreDefEqDoneBool
    (value : Bool) : PsKernelCoreDefEqPlan :=
  PsKernelCoreDefEqPlan.done (PsKernelCoreResult.ok value)

def psKernelCoreDefEqCompareBinderPlan
    (lctx : PsKernelCoreLocalContext)
    (leftDomain : PsKernelCoreExpr)
    (leftBody : PsKernelCoreExpr)
    (rightName : PsKernelCoreName)
    (rightDomain : PsKernelCoreExpr)
    (rightBody : PsKernelCoreExpr)
    (rightBinderInfo : PsKernelCoreBinderInfo) :
    PsKernelCoreDefEqPlan :=
  let fresh := psKernelCoreInferFreshName lctx rightName;
  let child :=
    psKernelCoreLocalContextAddLocal
      lctx fresh rightName rightDomain rightBinderInfo;
  let freshExpr := PsKernelCoreExpr.fvar fresh;
  let openedLeft := psKernelCoreExprInstantiate1 leftBody freshExpr;
  let openedRight := psKernelCoreExprInstantiate1 rightBody freshExpr;
  PsKernelCoreDefEqPlan.compareThen
    lctx leftDomain rightDomain
    child openedLeft openedRight

def psKernelCoreDefEqEtaLeftPlan
    (remaining : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreDefEqPlan :=
  match psKernelCoreInfer remaining env lctx right with
  | PsKernelCoreResult.error message =>
      psKernelCoreDefEqDoneError message
  | PsKernelCoreResult.ok rightType =>
      match psKernelCoreWhnf remaining env lctx rightType with
      | PsKernelCoreResult.error message =>
          psKernelCoreDefEqDoneError message
      | PsKernelCoreResult.ok exposed =>
          match exposed with
          | PsKernelCoreExpr.forallE name domain _ binderInfo =>
              let eta :=
                PsKernelCoreExpr.lam
                  name
                  domain
                  (PsKernelCoreExpr.app right (PsKernelCoreExpr.bvar 0))
                  binderInfo;
              PsKernelCoreDefEqPlan.compare lctx left eta
          | _ => psKernelCoreDefEqDoneBool false

def psKernelCoreDefEqEtaRightPlan
    (remaining : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreDefEqPlan :=
  match psKernelCoreInfer remaining env lctx left with
  | PsKernelCoreResult.error message =>
      psKernelCoreDefEqDoneError message
  | PsKernelCoreResult.ok leftType =>
      match psKernelCoreWhnf remaining env lctx leftType with
      | PsKernelCoreResult.error message =>
          psKernelCoreDefEqDoneError message
      | PsKernelCoreResult.ok exposed =>
          match exposed with
          | PsKernelCoreExpr.forallE name domain _ binderInfo =>
              let eta :=
                PsKernelCoreExpr.lam
                  name
                  domain
                  (PsKernelCoreExpr.app left (PsKernelCoreExpr.bvar 0))
                  binderInfo;
              PsKernelCoreDefEqPlan.compare lctx eta right
          | _ => psKernelCoreDefEqDoneBool false

def psKernelCoreDefEqApplicationPlan
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreDefEqPlan :=
  match left with
  | PsKernelCoreExpr.app leftFn leftArg =>
      match right with
      | PsKernelCoreExpr.app rightFn rightArg =>
          PsKernelCoreDefEqPlan.compareThen
            lctx leftFn rightFn
            lctx leftArg rightArg
      | _ => psKernelCoreDefEqDoneBool false
  | _ => psKernelCoreDefEqDoneBool false

def psKernelCoreDefEqAfterProofPlan
    (remaining : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreDefEqPlan :=
  match left with
  | PsKernelCoreExpr.lam _ _ _ _ =>
      psKernelCoreDefEqEtaLeftPlan remaining env lctx left right
  | _ =>
      match right with
      | PsKernelCoreExpr.lam _ _ _ _ =>
          psKernelCoreDefEqEtaRightPlan remaining env lctx left right
      | _ => psKernelCoreDefEqApplicationPlan lctx left right

def psKernelCoreDefEqFallbackPlan
    (remaining : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreDefEqPlan :=
  match left with
  | PsKernelCoreExpr.proj _ _ _ =>
      psKernelCoreDefEqDoneError
        "projection definitional equality unavailable before inductive metadata"
  | _ =>
      match right with
      | PsKernelCoreExpr.proj _ _ _ =>
          psKernelCoreDefEqDoneError
            "projection definitional equality unavailable before inductive metadata"
      | _ =>
          match psKernelCoreInfer remaining env lctx left with
          | PsKernelCoreResult.error message =>
              psKernelCoreDefEqDoneError message
          | PsKernelCoreResult.ok leftType =>
              match psKernelCoreDefEqIsProp remaining env lctx leftType with
              | PsKernelCoreResult.error message =>
                  psKernelCoreDefEqDoneError message
              | PsKernelCoreResult.ok isProof =>
                  if isProof then
                    match psKernelCoreInfer remaining env lctx right with
                    | PsKernelCoreResult.error message =>
                        psKernelCoreDefEqDoneError message
                    | PsKernelCoreResult.ok rightType =>
                        PsKernelCoreDefEqPlan.compare
                          lctx leftType rightType
                  else
                    psKernelCoreDefEqAfterProofPlan
                      remaining env lctx left right

def psKernelCoreDefEqReducedPlan
    (remaining : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreDefEqPlan :=
  match left with
  | PsKernelCoreExpr.sort leftLevel =>
      match right with
      | PsKernelCoreExpr.sort rightLevel =>
          psKernelCoreDefEqDoneBool
            (psKernelCoreLevelEquivalent leftLevel rightLevel)
      | _ =>
          psKernelCoreDefEqFallbackPlan
            remaining env lctx left right
  | PsKernelCoreExpr.lit leftLiteral =>
      match right with
      | PsKernelCoreExpr.lit rightLiteral =>
          psKernelCoreDefEqDoneBool
            (psKernelCoreLiteralEq leftLiteral rightLiteral)
      | _ =>
          psKernelCoreDefEqFallbackPlan
            remaining env lctx left right
  | PsKernelCoreExpr.lam _ leftDomain leftBody _ =>
      match right with
      | PsKernelCoreExpr.lam
          rightName rightDomain rightBody rightBinderInfo =>
          psKernelCoreDefEqCompareBinderPlan
            lctx
            leftDomain leftBody
            rightName rightDomain rightBody rightBinderInfo
      | _ =>
          psKernelCoreDefEqFallbackPlan
            remaining env lctx left right
  | PsKernelCoreExpr.forallE _ leftDomain leftBody _ =>
      match right with
      | PsKernelCoreExpr.forallE
          rightName rightDomain rightBody rightBinderInfo =>
          psKernelCoreDefEqCompareBinderPlan
            lctx
            leftDomain leftBody
            rightName rightDomain rightBody rightBinderInfo
      | _ =>
          psKernelCoreDefEqFallbackPlan
            remaining env lctx left right
  | PsKernelCoreExpr.const leftName leftLevels =>
      match right with
      | PsKernelCoreExpr.const rightName rightLevels =>
          if psKernelCoreNameEq leftName rightName then
            if psKernelCoreLevelListEquivalent leftLevels rightLevels then
              psKernelCoreDefEqDoneBool true
            else
              psKernelCoreDefEqFallbackPlan
                remaining env lctx left right
          else
            psKernelCoreDefEqFallbackPlan
              remaining env lctx left right
      | _ =>
          psKernelCoreDefEqFallbackPlan
            remaining env lctx left right
  | PsKernelCoreExpr.fvar leftName =>
      match right with
      | PsKernelCoreExpr.fvar rightName =>
          if psKernelCoreNameEq leftName rightName then
            psKernelCoreDefEqDoneBool true
          else
            psKernelCoreDefEqFallbackPlan
              remaining env lctx left right
      | _ =>
          psKernelCoreDefEqFallbackPlan
            remaining env lctx left right
  | _ =>
      psKernelCoreDefEqFallbackPlan remaining env lctx left right

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
                    let plan :=
                      psKernelCoreDefEqReducedPlan
                        remaining env lctx leftReduced rightReduced;
                    match plan with
                    | PsKernelCoreDefEqPlan.done result => result
                    | PsKernelCoreDefEqPlan.compare
                        compareLctx compareLeft compareRight =>
                        smaller env compareLctx compareLeft compareRight
                    | PsKernelCoreDefEqPlan.compareThen
                        firstLctx firstLeft firstRight
                        secondLctx secondLeft secondRight =>
                        match smaller env firstLctx firstLeft firstRight with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok firstEqual =>
                            if firstEqual then
                              smaller env secondLctx secondLeft secondRight
                            else
                              PsKernelCoreResult.ok false
