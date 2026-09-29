import Ps.KernelCore.Inductive

structure PsKernelCoreRecursiveFieldShape where
  argCount : Nat
  indices : PsKernelCoreList PsKernelCoreExpr

structure PsKernelCoreRecursiveConstructorSummary where
  isRec : Bool
  isReflexive : Bool

def psKernelCoreRecursiveSummaryEmpty : PsKernelCoreRecursiveConstructorSummary :=
  {
    isRec := false
    isReflexive := false
  }

def psKernelCoreRecursiveSummaryMerge
    (left : PsKernelCoreRecursiveConstructorSummary)
    (right : PsKernelCoreRecursiveConstructorSummary) :
    PsKernelCoreRecursiveConstructorSummary :=
  {
    isRec := if left.isRec then true else right.isRec
    isReflexive := if left.isReflexive then true else right.isReflexive
  }

def psKernelCoreRecursiveExprListDrop
    (count : Nat) :
    PsKernelCoreList PsKernelCoreExpr -> PsKernelCoreList PsKernelCoreExpr :=
  match count with
  | Nat.zero =>
      fun (items : PsKernelCoreList PsKernelCoreExpr) => items
  | Nat.succ remaining =>
      let dropRemaining := psKernelCoreRecursiveExprListDrop remaining;
      fun (items : PsKernelCoreList PsKernelCoreExpr) =>
        match items with
        | PsKernelCoreList.nil => PsKernelCoreList.nil
        | PsKernelCoreList.cons _ rest => dropRemaining rest

def psKernelCoreRecursiveDirectShape?
    (target : PsKernelCoreName)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (numParams : Nat)
    (numIndices : Nat)
    (binderDepth : Nat)
    (expr : PsKernelCoreExpr) :
    PsKernelCoreOption PsKernelCoreRecursiveFieldShape :=
  if psKernelCoreInductiveResultMatches
      target levels numParams numIndices binderDepth expr then
    let args := psKernelCoreExprAppArgs expr;
    PsKernelCoreOption.some {
      argCount := 0
      indices := psKernelCoreRecursiveExprListDrop numParams args
    }
  else
    PsKernelCoreOption.none

def psKernelCoreRecursiveHeadIsTarget
    (target : PsKernelCoreName)
    (expr : PsKernelCoreExpr) : Bool :=
  match psKernelCoreExprAppHead expr with
  | PsKernelCoreExpr.const name _ => psKernelCoreNameEq name target
  | _ => false

def psKernelCoreRecursiveFieldShapeFuel
    (fuel : Nat) :
    PsKernelCoreResourceConfig ->
    PsKernelCoreEnvironment ->
    PsKernelCoreName ->
    PsKernelCoreList PsKernelCoreLevel ->
    Nat -> Nat -> Nat -> PsKernelCoreExpr ->
    PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreRecursiveFieldShape) :=
  match fuel with
  | Nat.zero =>
      fun (_resources : PsKernelCoreResourceConfig)
          (_env : PsKernelCoreEnvironment)
          (_target : PsKernelCoreName)
          (_levels : PsKernelCoreList PsKernelCoreLevel)
          (_numParams : Nat)
          (_numIndices : Nat)
          (_binderDepth : Nat)
          (_fieldType : PsKernelCoreExpr) =>
        PsKernelCoreResult.error "recursive field budget exhausted"
  | Nat.succ remaining =>
      let smaller := psKernelCoreRecursiveFieldShapeFuel remaining;
      fun (resources : PsKernelCoreResourceConfig)
          (env : PsKernelCoreEnvironment)
          (target : PsKernelCoreName)
          (levels : PsKernelCoreList PsKernelCoreLevel)
          (numParams : Nat)
          (numIndices : Nat)
          (binderDepth : Nat)
          (fieldType : PsKernelCoreExpr) =>
        match psKernelCoreWhnfWithResources
            (Nat.succ remaining) resources env
            psKernelCoreLocalContextEmpty fieldType with
        | PsKernelCoreResult.error message =>
            PsKernelCoreResult.error message
        | PsKernelCoreResult.ok reduced =>
            match psKernelCoreRecursiveDirectShape?
                target levels numParams numIndices binderDepth reduced with
            | PsKernelCoreOption.some shape =>
                PsKernelCoreResult.ok (PsKernelCoreOption.some shape)
            | PsKernelCoreOption.none =>
                match reduced with
                | PsKernelCoreExpr.forallE _ domain body _ =>
                    match psKernelCoreWhnfWithResources
                        (Nat.succ remaining) resources env
                        psKernelCoreLocalContextEmpty domain with
                    | PsKernelCoreResult.error message =>
                        PsKernelCoreResult.error message
                    | PsKernelCoreResult.ok reducedDomain =>
                        if psKernelCoreExprContainsConstName target domain then
                          PsKernelCoreResult.error "negative recursive occurrence"
                        else if psKernelCoreExprContainsConstName target reducedDomain then
                          PsKernelCoreResult.error "negative recursive occurrence"
                        else
                          match smaller
                              resources env target levels numParams numIndices
                              (Nat.succ binderDepth) body with
                          | PsKernelCoreResult.error message =>
                              PsKernelCoreResult.error message
                          | PsKernelCoreResult.ok recursiveResult =>
                              match recursiveResult with
                              | PsKernelCoreOption.none =>
                                  PsKernelCoreResult.ok PsKernelCoreOption.none
                              | PsKernelCoreOption.some shape =>
                                  PsKernelCoreResult.ok
                                    (PsKernelCoreOption.some {
                                      argCount := Nat.succ shape.argCount
                                      indices := shape.indices
                                    })
                | _ =>
                    if psKernelCoreRecursiveHeadIsTarget target reduced then
                      PsKernelCoreResult.error "invalid recursive result"
                    else if psKernelCoreExprContainsConstName target fieldType then
                      PsKernelCoreResult.error "nested recursive occurrence is not supported"
                    else if psKernelCoreExprContainsConstName target reduced then
                      PsKernelCoreResult.error "nested recursive occurrence is not supported"
                    else
                      PsKernelCoreResult.ok PsKernelCoreOption.none

def psKernelCoreRecursiveFieldShapeWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (target : PsKernelCoreName)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (numParams : Nat)
    (numIndices : Nat)
    (binderDepth : Nat)
    (fieldType : PsKernelCoreExpr) :
    PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreRecursiveFieldShape) :=
  psKernelCoreRecursiveFieldShapeFuel
    budget resources env target levels numParams numIndices binderDepth fieldType

def psKernelCoreAnalyzeRecursiveConstructorTelescopeFuel
    (fuel : Nat) :
    PsKernelCoreResourceConfig ->
    PsKernelCoreEnvironment ->
    PsKernelCoreInductiveInfo ->
    PsKernelCoreList PsKernelCoreLevel ->
    PsKernelCoreExpr ->
    Nat -> Nat ->
    PsKernelCoreResult String PsKernelCoreRecursiveConstructorSummary :=
  match fuel with
  | Nat.zero =>
      fun (_resources : PsKernelCoreResourceConfig)
          (_env : PsKernelCoreEnvironment)
          (_info : PsKernelCoreInductiveInfo)
          (_levels : PsKernelCoreList PsKernelCoreLevel)
          (_expr : PsKernelCoreExpr)
          (_remainingParams : Nat)
          (_binderDepth : Nat) =>
        PsKernelCoreResult.error "recursive constructor budget exhausted"
  | Nat.succ remaining =>
      let smaller := psKernelCoreAnalyzeRecursiveConstructorTelescopeFuel remaining;
      fun (resources : PsKernelCoreResourceConfig)
          (env : PsKernelCoreEnvironment)
          (info : PsKernelCoreInductiveInfo)
          (levels : PsKernelCoreList PsKernelCoreLevel)
          (expr : PsKernelCoreExpr)
          (remainingParams : Nat)
          (binderDepth : Nat) =>
        match psKernelCoreWhnfWithResources
            (Nat.succ remaining) resources env
            psKernelCoreLocalContextEmpty expr with
        | PsKernelCoreResult.error message =>
            PsKernelCoreResult.error message
        | PsKernelCoreResult.ok reduced =>
            match reduced with
            | PsKernelCoreExpr.forallE _ domain body _ =>
                match remainingParams with
                | Nat.succ paramsRest =>
                    smaller resources env info levels body
                      paramsRest (Nat.succ binderDepth)
                | Nat.zero =>
                    match psKernelCoreRecursiveFieldShapeWithResources
                        (Nat.succ remaining) resources env
                        info.base.name levels info.numParams info.numIndices
                        binderDepth domain with
                    | PsKernelCoreResult.error message =>
                        PsKernelCoreResult.error message
                    | PsKernelCoreResult.ok fieldShape =>
                        match smaller resources env info levels body
                            Nat.zero (Nat.succ binderDepth) with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok restSummary =>
                            match fieldShape with
                            | PsKernelCoreOption.none =>
                                PsKernelCoreResult.ok restSummary
                            | PsKernelCoreOption.some shape =>
                                let fieldSummary : PsKernelCoreRecursiveConstructorSummary := {
                                  isRec := true
                                  isReflexive :=
                                    match shape.argCount with
                                    | Nat.zero => false
                                    | Nat.succ _ => true
                                };
                                PsKernelCoreResult.ok
                                  (psKernelCoreRecursiveSummaryMerge
                                    fieldSummary restSummary)
            | _ =>
                match remainingParams with
                | Nat.zero =>
                    PsKernelCoreResult.ok psKernelCoreRecursiveSummaryEmpty
                | Nat.succ _ =>
                    PsKernelCoreResult.error
                      "constructor has fewer parameters than declared"

def psKernelCoreAnalyzeRecursiveConstructorWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreInductiveInfo)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (ctor : PsKernelCoreConstructorInfo) :
    PsKernelCoreResult String PsKernelCoreRecursiveConstructorSummary :=
  psKernelCoreAnalyzeRecursiveConstructorTelescopeFuel
    budget resources env info levels ctor.base.type info.numParams 0
