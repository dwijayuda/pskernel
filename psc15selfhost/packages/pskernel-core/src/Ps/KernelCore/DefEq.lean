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

def psKernelCoreDefEqIsPropWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (typeExpr : PsKernelCoreExpr) :
    PsKernelCoreResult String Bool :=
  match psKernelCoreInferWithResources budget resources env lctx typeExpr with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error message
  | PsKernelCoreResult.ok inferredType =>
      match psKernelCoreWhnfWithResources budget resources env lctx inferredType with
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

def psKernelCoreDefEqEtaLeftPlanWithResources
    (remaining : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreDefEqPlan :=
  match psKernelCoreInferWithResources remaining resources env lctx right with
  | PsKernelCoreResult.error message =>
      psKernelCoreDefEqDoneError message
  | PsKernelCoreResult.ok rightType =>
      match psKernelCoreWhnfWithResources remaining resources env lctx rightType with
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

def psKernelCoreDefEqEtaRightPlanWithResources
    (remaining : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreDefEqPlan :=
  match psKernelCoreInferWithResources remaining resources env lctx left with
  | PsKernelCoreResult.error message =>
      psKernelCoreDefEqDoneError message
  | PsKernelCoreResult.ok leftType =>
      match psKernelCoreWhnfWithResources remaining resources env lctx leftType with
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

def psKernelCoreDefEqAfterProofPlanWithResources
    (remaining : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) :
    PsKernelCoreDefEqPlan :=
  match left with
  | PsKernelCoreExpr.lam _ _ _ _ =>
      psKernelCoreDefEqEtaLeftPlanWithResources
        remaining resources env lctx left right
  | _ =>
      match right with
      | PsKernelCoreExpr.lam _ _ _ _ =>
          psKernelCoreDefEqEtaRightPlanWithResources
            remaining resources env lctx left right
      | _ => psKernelCoreDefEqApplicationPlan lctx left right

def psKernelCoreDefEqFallbackPlanWithResources
    (remaining : Nat)
    (resources : PsKernelCoreResourceConfig)
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
          match psKernelCoreInferWithResources remaining resources env lctx left with
          | PsKernelCoreResult.error message =>
              psKernelCoreDefEqDoneError message
          | PsKernelCoreResult.ok leftType =>
              match psKernelCoreDefEqIsPropWithResources
                  remaining resources env lctx leftType with
              | PsKernelCoreResult.error message =>
                  psKernelCoreDefEqDoneError message
              | PsKernelCoreResult.ok isProof =>
                  if isProof then
                    match psKernelCoreInferWithResources
                        remaining resources env lctx right with
                    | PsKernelCoreResult.error message =>
                        psKernelCoreDefEqDoneError message
                    | PsKernelCoreResult.ok rightType =>
                        PsKernelCoreDefEqPlan.compare
                          lctx leftType rightType
                  else
                    psKernelCoreDefEqAfterProofPlanWithResources
                      remaining resources env lctx left right

def psKernelCoreDefEqReducedPlanWithResources
    (remaining : Nat)
    (resources : PsKernelCoreResourceConfig)
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
          psKernelCoreDefEqFallbackPlanWithResources
            remaining resources env lctx left right
  | PsKernelCoreExpr.lit leftLiteral =>
      match right with
      | PsKernelCoreExpr.lit rightLiteral =>
          psKernelCoreDefEqDoneBool
            (psKernelCoreLiteralEq leftLiteral rightLiteral)
      | _ =>
          psKernelCoreDefEqFallbackPlanWithResources
            remaining resources env lctx left right
  | PsKernelCoreExpr.lam _ leftDomain leftBody _ =>
      match right with
      | PsKernelCoreExpr.lam
          rightName rightDomain rightBody rightBinderInfo =>
          psKernelCoreDefEqCompareBinderPlan
            lctx
            leftDomain leftBody
            rightName rightDomain rightBody rightBinderInfo
      | _ =>
          psKernelCoreDefEqFallbackPlanWithResources
            remaining resources env lctx left right
  | PsKernelCoreExpr.forallE _ leftDomain leftBody _ =>
      match right with
      | PsKernelCoreExpr.forallE
          rightName rightDomain rightBody rightBinderInfo =>
          psKernelCoreDefEqCompareBinderPlan
            lctx
            leftDomain leftBody
            rightName rightDomain rightBody rightBinderInfo
      | _ =>
          psKernelCoreDefEqFallbackPlanWithResources
            remaining resources env lctx left right
  | PsKernelCoreExpr.const leftName leftLevels =>
      match right with
      | PsKernelCoreExpr.const rightName rightLevels =>
          if psKernelCoreNameEq leftName rightName then
            if psKernelCoreLevelListEquivalent leftLevels rightLevels then
              psKernelCoreDefEqDoneBool true
            else
              psKernelCoreDefEqFallbackPlanWithResources
                remaining resources env lctx left right
          else
            psKernelCoreDefEqFallbackPlanWithResources
              remaining resources env lctx left right
      | _ =>
          psKernelCoreDefEqFallbackPlanWithResources
            remaining resources env lctx left right
  | PsKernelCoreExpr.fvar leftName =>
      match right with
      | PsKernelCoreExpr.fvar rightName =>
          if psKernelCoreNameEq leftName rightName then
            psKernelCoreDefEqDoneBool true
          else
            psKernelCoreDefEqFallbackPlanWithResources
              remaining resources env lctx left right
      | _ =>
          psKernelCoreDefEqFallbackPlanWithResources
            remaining resources env lctx left right
  | _ =>
      psKernelCoreDefEqFallbackPlanWithResources
        remaining resources env lctx left right

def psKernelCoreIsDefEqWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig) :
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
        psKernelCoreIsDefEqWithResources remaining resources;
      fun (env : PsKernelCoreEnvironment)
          (lctx : PsKernelCoreLocalContext)
          (left : PsKernelCoreExpr)
          (right : PsKernelCoreExpr) =>
        if psKernelCoreExprEq left right then
          PsKernelCoreResult.ok true
        else
          match psKernelCoreWhnfWithResources remaining resources env lctx left with
          | PsKernelCoreResult.error message =>
              PsKernelCoreResult.error message
          | PsKernelCoreResult.ok leftReduced =>
              match psKernelCoreWhnfWithResources remaining resources env lctx right with
              | PsKernelCoreResult.error message =>
                  PsKernelCoreResult.error message
              | PsKernelCoreResult.ok rightReduced =>
                  if psKernelCoreExprEq leftReduced rightReduced then
                    PsKernelCoreResult.ok true
                  else
                    let plan :=
                      psKernelCoreDefEqReducedPlanWithResources
                        remaining resources env lctx leftReduced rightReduced;
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

def psKernelCoreDefEqIsProp
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (typeExpr : PsKernelCoreExpr) :
    PsKernelCoreResult String Bool :=
  psKernelCoreDefEqIsPropWithResources
    budget psKernelCoreResourceConfigDefault env lctx typeExpr

def psKernelCoreDefEqEtaLeftPlan
    (remaining : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) : PsKernelCoreDefEqPlan :=
  psKernelCoreDefEqEtaLeftPlanWithResources
    remaining psKernelCoreResourceConfigDefault env lctx left right

def psKernelCoreDefEqEtaRightPlan
    (remaining : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) : PsKernelCoreDefEqPlan :=
  psKernelCoreDefEqEtaRightPlanWithResources
    remaining psKernelCoreResourceConfigDefault env lctx left right

def psKernelCoreDefEqAfterProofPlan
    (remaining : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) : PsKernelCoreDefEqPlan :=
  psKernelCoreDefEqAfterProofPlanWithResources
    remaining psKernelCoreResourceConfigDefault env lctx left right

def psKernelCoreDefEqFallbackPlan
    (remaining : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) : PsKernelCoreDefEqPlan :=
  psKernelCoreDefEqFallbackPlanWithResources
    remaining psKernelCoreResourceConfigDefault env lctx left right

def psKernelCoreDefEqReducedPlan
    (remaining : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (left : PsKernelCoreExpr)
    (right : PsKernelCoreExpr) : PsKernelCoreDefEqPlan :=
  psKernelCoreDefEqReducedPlanWithResources
    remaining psKernelCoreResourceConfigDefault env lctx left right

def psKernelCoreIsDefEq
    (budget : Nat) :
    PsKernelCoreEnvironment ->
    PsKernelCoreLocalContext ->
    PsKernelCoreExpr ->
    PsKernelCoreExpr ->
    PsKernelCoreResult String Bool :=
  psKernelCoreIsDefEqWithResources budget psKernelCoreResourceConfigDefault
