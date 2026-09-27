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
                    match leftReduced, rightReduced with
                    | PsKernelCoreExpr.sort leftLevel,
                        PsKernelCoreExpr.sort rightLevel =>
                        PsKernelCoreResult.ok
                          (psKernelCoreLevelEquivalent leftLevel rightLevel)
                    | PsKernelCoreExpr.lit leftLiteral,
                        PsKernelCoreExpr.lit rightLiteral =>
                        PsKernelCoreResult.ok
                          (psKernelCoreLiteralEq leftLiteral rightLiteral)
                    | PsKernelCoreExpr.lam _ leftDomain leftBody _,
                        PsKernelCoreExpr.lam rightName rightDomain rightBody rightBinderInfo =>
                        match smaller env lctx leftDomain rightDomain with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok false =>
                            PsKernelCoreResult.ok false
                        | PsKernelCoreResult.ok true =>
                            let fresh :=
                              psKernelCoreInferFreshName lctx rightName;
                            let child :=
                              psKernelCoreLocalContextAddLocal
                                lctx
                                fresh
                                rightName
                                rightDomain
                                rightBinderInfo;
                            let freshExpr := PsKernelCoreExpr.fvar fresh;
                            let openedLeft :=
                              psKernelCoreExprInstantiate1 leftBody freshExpr;
                            let openedRight :=
                              psKernelCoreExprInstantiate1 rightBody freshExpr;
                            smaller env child openedLeft openedRight
                    | PsKernelCoreExpr.forallE _ leftDomain leftBody _,
                        PsKernelCoreExpr.forallE rightName rightDomain rightBody rightBinderInfo =>
                        match smaller env lctx leftDomain rightDomain with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok false =>
                            PsKernelCoreResult.ok false
                        | PsKernelCoreResult.ok true =>
                            let fresh :=
                              psKernelCoreInferFreshName lctx rightName;
                            let child :=
                              psKernelCoreLocalContextAddLocal
                                lctx
                                fresh
                                rightName
                                rightDomain
                                rightBinderInfo;
                            let freshExpr := PsKernelCoreExpr.fvar fresh;
                            let openedLeft :=
                              psKernelCoreExprInstantiate1 leftBody freshExpr;
                            let openedRight :=
                              psKernelCoreExprInstantiate1 rightBody freshExpr;
                            smaller env child openedLeft openedRight
                    | PsKernelCoreExpr.proj _ _ _, _ =>
                        PsKernelCoreResult.error
                          "projection definitional equality unavailable before inductive metadata"
                    | _, PsKernelCoreExpr.proj _ _ _ =>
                        PsKernelCoreResult.error
                          "projection definitional equality unavailable before inductive metadata"
                    | _, _ =>
                        let cheapResidual : PsKernelCoreOption Bool :=
                          match leftReduced, rightReduced with
                          | PsKernelCoreExpr.const leftName leftLevels,
                              PsKernelCoreExpr.const rightName rightLevels =>
                              if psKernelCoreNameEq leftName rightName then
                                if psKernelCoreLevelListEquivalent
                                    leftLevels rightLevels then
                                  PsKernelCoreOption.some true
                                else
                                  PsKernelCoreOption.none
                              else
                                PsKernelCoreOption.none
                          | PsKernelCoreExpr.fvar leftName,
                              PsKernelCoreExpr.fvar rightName =>
                              if psKernelCoreNameEq leftName rightName then
                                PsKernelCoreOption.some true
                              else
                                PsKernelCoreOption.none
                          | _, _ => PsKernelCoreOption.none;
                        match cheapResidual with
                        | PsKernelCoreOption.some value =>
                            PsKernelCoreResult.ok value
                        | PsKernelCoreOption.none =>
                            match psKernelCoreInfer
                                remaining env lctx leftReduced with
                            | PsKernelCoreResult.error message =>
                                PsKernelCoreResult.error message
                            | PsKernelCoreResult.ok leftType =>
                                match psKernelCoreDefEqIsProp
                                    remaining env lctx leftType with
                                | PsKernelCoreResult.error message =>
                                    PsKernelCoreResult.error message
                                | PsKernelCoreResult.ok true =>
                                    match psKernelCoreInfer
                                        remaining env lctx rightReduced with
                                    | PsKernelCoreResult.error message =>
                                        PsKernelCoreResult.error message
                                    | PsKernelCoreResult.ok rightType =>
                                        smaller env lctx leftType rightType
                                | PsKernelCoreResult.ok false =>
                                    match leftReduced, rightReduced with
                                    | PsKernelCoreExpr.app leftFn leftArg,
                                        PsKernelCoreExpr.app rightFn rightArg =>
                                        match smaller env lctx leftFn rightFn with
                                        | PsKernelCoreResult.error message =>
                                            PsKernelCoreResult.error message
                                        | PsKernelCoreResult.ok false =>
                                            PsKernelCoreResult.ok false
                                        | PsKernelCoreResult.ok true =>
                                            smaller env lctx leftArg rightArg
                                    | PsKernelCoreExpr.lam _ _ _ _, other =>
                                        match psKernelCoreInfer
                                            remaining env lctx other with
                                        | PsKernelCoreResult.error message =>
                                            PsKernelCoreResult.error message
                                        | PsKernelCoreResult.ok otherType =>
                                            match psKernelCoreWhnf
                                                remaining env lctx otherType with
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
                                                          other
                                                          (PsKernelCoreExpr.bvar 0))
                                                        binderInfo;
                                                    smaller env lctx leftReduced eta
                                                | _ => PsKernelCoreResult.ok false
                                    | other, PsKernelCoreExpr.lam _ _ _ _ =>
                                        match psKernelCoreInfer
                                            remaining env lctx other with
                                        | PsKernelCoreResult.error message =>
                                            PsKernelCoreResult.error message
                                        | PsKernelCoreResult.ok otherType =>
                                            match psKernelCoreWhnf
                                                remaining env lctx otherType with
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
                                                          other
                                                          (PsKernelCoreExpr.bvar 0))
                                                        binderInfo;
                                                    smaller env lctx eta rightReduced
                                                | _ => PsKernelCoreResult.ok false
                                    | _, _ => PsKernelCoreResult.ok false
