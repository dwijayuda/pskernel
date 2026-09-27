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
        let compareBinder :
            PsKernelCoreExpr ->
            PsKernelCoreExpr ->
            PsKernelCoreName ->
            PsKernelCoreExpr ->
            PsKernelCoreExpr ->
            PsKernelCoreBinderInfo ->
            PsKernelCoreResult String Bool :=
          fun (leftDomain : PsKernelCoreExpr)
              (leftBody : PsKernelCoreExpr)
              (rightName : PsKernelCoreName)
              (rightDomain : PsKernelCoreExpr)
              (rightBody : PsKernelCoreExpr)
              (rightBinderInfo : PsKernelCoreBinderInfo) =>
            match smaller env lctx leftDomain rightDomain with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok domainsEqual =>
                if domainsEqual then
                  let fresh := psKernelCoreInferFreshName lctx rightName;
                  let child :=
                    psKernelCoreLocalContextAddLocal
                      lctx fresh rightName rightDomain rightBinderInfo;
                  let freshExpr := PsKernelCoreExpr.fvar fresh;
                  let openedLeft :=
                    psKernelCoreExprInstantiate1 leftBody freshExpr;
                  let openedRight :=
                    psKernelCoreExprInstantiate1 rightBody freshExpr;
                  smaller env child openedLeft openedRight
                else
                  PsKernelCoreResult.ok false;
        let fallback :
            PsKernelCoreExpr ->
            PsKernelCoreExpr ->
            PsKernelCoreResult String Bool :=
          fun (leftReduced : PsKernelCoreExpr)
              (rightReduced : PsKernelCoreExpr) =>
            match leftReduced with
            | PsKernelCoreExpr.proj _ _ _ =>
                PsKernelCoreResult.error
                  "projection definitional equality unavailable before inductive metadata"
            | _ =>
                match rightReduced with
                | PsKernelCoreExpr.proj _ _ _ =>
                    PsKernelCoreResult.error
                      "projection definitional equality unavailable before inductive metadata"
                | _ =>
                    match psKernelCoreInfer remaining env lctx leftReduced with
                    | PsKernelCoreResult.error message =>
                        PsKernelCoreResult.error message
                    | PsKernelCoreResult.ok leftType =>
                        match psKernelCoreDefEqIsProp
                            remaining env lctx leftType with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok isProof =>
                            if isProof then
                              match psKernelCoreInfer
                                  remaining env lctx rightReduced with
                              | PsKernelCoreResult.error message =>
                                  PsKernelCoreResult.error message
                              | PsKernelCoreResult.ok rightType =>
                                  smaller env lctx leftType rightType
                            else
                              match leftReduced with
                              | PsKernelCoreExpr.lam _ _ _ _ =>
                                  match psKernelCoreInfer
                                      remaining env lctx rightReduced with
                                  | PsKernelCoreResult.error message =>
                                      PsKernelCoreResult.error message
                                  | PsKernelCoreResult.ok rightType =>
                                      match psKernelCoreWhnf
                                          remaining env lctx rightType with
                                      | PsKernelCoreResult.error message =>
                                          PsKernelCoreResult.error message
                                      | PsKernelCoreResult.ok exposed =>
                                          match exposed with
                                          | PsKernelCoreExpr.forallE
                                              name domain _ binderInfo =>
                                              let eta :=
                                                PsKernelCoreExpr.lam
                                                  name
                                                  domain
                                                  (PsKernelCoreExpr.app
                                                    rightReduced
                                                    (PsKernelCoreExpr.bvar 0))
                                                  binderInfo;
                                              smaller
                                                env lctx leftReduced eta
                                          | _ => PsKernelCoreResult.ok false
                              | _ =>
                                  match rightReduced with
                                  | PsKernelCoreExpr.lam _ _ _ _ =>
                                      match psKernelCoreInfer
                                          remaining env lctx leftReduced with
                                      | PsKernelCoreResult.error message =>
                                          PsKernelCoreResult.error message
                                      | PsKernelCoreResult.ok leftOrdinaryType =>
                                          match psKernelCoreWhnf
                                              remaining env lctx leftOrdinaryType with
                                          | PsKernelCoreResult.error message =>
                                              PsKernelCoreResult.error message
                                          | PsKernelCoreResult.ok exposed =>
                                              match exposed with
                                              | PsKernelCoreExpr.forallE
                                                  name domain _ binderInfo =>
                                                  let eta :=
                                                    PsKernelCoreExpr.lam
                                                      name
                                                      domain
                                                      (PsKernelCoreExpr.app
                                                        leftReduced
                                                        (PsKernelCoreExpr.bvar 0))
                                                      binderInfo;
                                                  smaller
                                                    env lctx eta rightReduced
                                              | _ => PsKernelCoreResult.ok false
                                  | _ =>
                                      match leftReduced with
                                      | PsKernelCoreExpr.app leftFn leftArg =>
                                          match rightReduced with
                                          | PsKernelCoreExpr.app rightFn rightArg =>
                                              match smaller
                                                  env lctx leftFn rightFn with
                                              | PsKernelCoreResult.error message =>
                                                  PsKernelCoreResult.error message
                                              | PsKernelCoreResult.ok functionsEqual =>
                                                  if functionsEqual then
                                                    smaller
                                                      env lctx leftArg rightArg
                                                  else
                                                    PsKernelCoreResult.ok false
                                          | _ => PsKernelCoreResult.ok false
                                      | _ => PsKernelCoreResult.ok false;
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
                        | _ => fallback leftReduced rightReduced
                    | PsKernelCoreExpr.lit leftLiteral =>
                        match rightReduced with
                        | PsKernelCoreExpr.lit rightLiteral =>
                            PsKernelCoreResult.ok
                              (psKernelCoreLiteralEq leftLiteral rightLiteral)
                        | _ => fallback leftReduced rightReduced
                    | PsKernelCoreExpr.lam _ leftDomain leftBody _ =>
                        match rightReduced with
                        | PsKernelCoreExpr.lam
                            rightName rightDomain rightBody rightBinderInfo =>
                            compareBinder
                              leftDomain leftBody
                              rightName rightDomain rightBody rightBinderInfo
                        | _ => fallback leftReduced rightReduced
                    | PsKernelCoreExpr.forallE _ leftDomain leftBody _ =>
                        match rightReduced with
                        | PsKernelCoreExpr.forallE
                            rightName rightDomain rightBody rightBinderInfo =>
                            compareBinder
                              leftDomain leftBody
                              rightName rightDomain rightBody rightBinderInfo
                        | _ => fallback leftReduced rightReduced
                    | PsKernelCoreExpr.const leftName leftLevels =>
                        match rightReduced with
                        | PsKernelCoreExpr.const rightName rightLevels =>
                            if psKernelCoreNameEq leftName rightName then
                              if psKernelCoreLevelListEquivalent
                                  leftLevels rightLevels then
                                PsKernelCoreResult.ok true
                              else
                                fallback leftReduced rightReduced
                            else
                              fallback leftReduced rightReduced
                        | _ => fallback leftReduced rightReduced
                    | PsKernelCoreExpr.fvar leftName =>
                        match rightReduced with
                        | PsKernelCoreExpr.fvar rightName =>
                            if psKernelCoreNameEq leftName rightName then
                              PsKernelCoreResult.ok true
                            else
                              fallback leftReduced rightReduced
                        | _ => fallback leftReduced rightReduced
                    | _ => fallback leftReduced rightReduced
