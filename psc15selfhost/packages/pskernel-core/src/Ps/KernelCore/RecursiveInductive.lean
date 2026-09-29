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
    let shape : PsKernelCoreRecursiveFieldShape := {
      argCount := 0
      indices := psKernelCoreRecursiveExprListDrop numParams args
    };
    PsKernelCoreOption.some shape
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
                                  let nextShape : PsKernelCoreRecursiveFieldShape := {
                                    argCount := Nat.succ shape.argCount
                                    indices := shape.indices
                                  };
                                  PsKernelCoreResult.ok
                                    (PsKernelCoreOption.some nextShape)
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

structure PsKernelCoreRecursiveAdmissionState where
  env : PsKernelCoreEnvironment
  summary : PsKernelCoreRecursiveConstructorSummary

def psKernelCoreRecursiveValidateConstructorWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (info : PsKernelCoreInductiveInfo)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (ctor : PsKernelCoreConstructorInfo) :
    PsKernelCoreEnvironment -> Nat ->
    PsKernelCoreResult String PsKernelCoreRecursiveAdmissionState :=
  fun (workEnv : PsKernelCoreEnvironment) (expectedIndex : Nat) =>
    if psKernelCoreNameEq ctor.induct info.base.name then
      if Nat.beq ctor.cidx expectedIndex then
        if Nat.beq ctor.numParams info.numParams then
          if psKernelCoreBoolEq ctor.isUnsafe info.isUnsafe then
            if psKernelCoreInductiveNameListEq
                ctor.base.levelParams info.base.levelParams then
              let telescope :=
                psKernelCoreInductiveSummarizeTelescope ctor.base.type;
              if Nat.ble info.numParams telescope.binderCount then
                if Nat.beq
                    ctor.numFields
                    (Nat.sub telescope.binderCount info.numParams) then
                  if psKernelCoreInductiveResultMatches
                      info.base.name levels info.numParams info.numIndices
                      telescope.binderCount telescope.result then
                    match psKernelCoreAnalyzeRecursiveConstructorWithResources
                        budget resources workEnv info levels ctor with
                    | PsKernelCoreResult.error message =>
                        PsKernelCoreResult.error message
                    | PsKernelCoreResult.ok ctorSummary =>
                        let safety :=
                          if ctor.isUnsafe then
                            PsKernelCoreDefinitionSafety.unsafeDef
                          else
                            PsKernelCoreDefinitionSafety.safe;
                        match psKernelCoreAdmissionCheckBaseWithResources
                            budget resources workEnv ctor.base safety with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok _ =>
                            let nextEnv :=
                              psKernelCoreEnvironmentAddUnchecked
                                workEnv
                                (PsKernelCoreConstantInfo.ctorInfo ctor);
                            let state : PsKernelCoreRecursiveAdmissionState := {
                              env := nextEnv
                              summary := ctorSummary
                            };
                            PsKernelCoreResult.ok state
                  else
                    PsKernelCoreResult.error "invalid constructor result"
                else
                  PsKernelCoreResult.error "invalid constructor field count"
              else
                PsKernelCoreResult.error
                  "constructor has fewer parameters than declared"
            else
              PsKernelCoreResult.error
                "constructor universe parameters do not match"
          else
            PsKernelCoreResult.error "constructor safety does not match inductive"
        else
          PsKernelCoreResult.error "constructor parameter count does not match"
      else
        PsKernelCoreResult.error "constructor index does not match order"
    else
      PsKernelCoreResult.error "constructor does not belong to inductive"

def psKernelCoreRecursiveAddConstructorsWithResources
    (constructors : PsKernelCoreList PsKernelCoreConstructorInfo) :
    Nat ->
    PsKernelCoreResourceConfig ->
    PsKernelCoreInductiveInfo ->
    PsKernelCoreList PsKernelCoreLevel ->
    PsKernelCoreEnvironment ->
    Nat ->
    PsKernelCoreRecursiveConstructorSummary ->
    PsKernelCoreResult String PsKernelCoreRecursiveAdmissionState :=
  match constructors with
  | PsKernelCoreList.nil =>
      fun (_budget : Nat)
          (_resources : PsKernelCoreResourceConfig)
          (_info : PsKernelCoreInductiveInfo)
          (_levels : PsKernelCoreList PsKernelCoreLevel)
          (workEnv : PsKernelCoreEnvironment)
          (_index : Nat)
          (summary : PsKernelCoreRecursiveConstructorSummary) =>
        let state : PsKernelCoreRecursiveAdmissionState := {
          env := workEnv
          summary := summary
        };
        PsKernelCoreResult.ok state
  | PsKernelCoreList.cons ctor rest =>
      let addRest := psKernelCoreRecursiveAddConstructorsWithResources rest;
      fun (budget : Nat)
          (resources : PsKernelCoreResourceConfig)
          (info : PsKernelCoreInductiveInfo)
          (levels : PsKernelCoreList PsKernelCoreLevel)
          (workEnv : PsKernelCoreEnvironment)
          (index : Nat)
          (summary : PsKernelCoreRecursiveConstructorSummary) =>
        match psKernelCoreRecursiveValidateConstructorWithResources
            budget resources info levels ctor workEnv index with
        | PsKernelCoreResult.error message =>
            PsKernelCoreResult.error message
        | PsKernelCoreResult.ok current =>
            let nextSummary :=
              psKernelCoreRecursiveSummaryMerge summary current.summary;
            addRest budget resources info levels current.env
              (Nat.succ index) nextSummary

def psKernelCoreAddRecursiveInductiveWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig) :
    PsKernelCoreEnvironment ->
    PsKernelCoreInductiveInfo ->
    PsKernelCoreList PsKernelCoreConstructorInfo ->
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  match budget with
  | Nat.zero =>
      fun (_env : PsKernelCoreEnvironment)
          (_info : PsKernelCoreInductiveInfo)
          (_constructors : PsKernelCoreList PsKernelCoreConstructorInfo) =>
        PsKernelCoreResult.error "admission budget exhausted"
  | Nat.succ remaining =>
      fun (env : PsKernelCoreEnvironment)
          (info : PsKernelCoreInductiveInfo)
          (constructors : PsKernelCoreList PsKernelCoreConstructorInfo) =>
        if psKernelCoreInductiveSingleFamilyMetadataValid info then
          let ctorNames := psKernelCoreInductiveConstructorNames constructors;
          if psKernelCoreInductiveNameListEq info.ctors ctorNames then
            if psKernelCoreNameHasDuplicates info.ctors then
              PsKernelCoreResult.error "duplicate constructor name"
            else if psKernelCoreInductiveHeaderShapeValid info then
              let safety :=
                if info.isUnsafe then
                  PsKernelCoreDefinitionSafety.unsafeDef
                else
                  PsKernelCoreDefinitionSafety.safe;
              match psKernelCoreAdmissionCheckBaseWithResources
                  remaining resources env info.base safety with
              | PsKernelCoreResult.error message =>
                  PsKernelCoreResult.error message
              | PsKernelCoreResult.ok _ =>
                  let provisionalConstant :=
                    PsKernelCoreConstantInfo.inductInfo info;
                  let workEnv :=
                    psKernelCoreEnvironmentAddUnchecked env provisionalConstant;
                  let levels :=
                    psKernelCoreInductiveLevelsFromNames info.base.levelParams;
                  match psKernelCoreRecursiveAddConstructorsWithResources
                      constructors remaining resources info levels workEnv 0
                      psKernelCoreRecursiveSummaryEmpty with
                  | PsKernelCoreResult.error message =>
                      PsKernelCoreResult.error message
                  | PsKernelCoreResult.ok state =>
                      let finalInfo : PsKernelCoreInductiveInfo := {
                        base := info.base
                        numParams := info.numParams
                        numIndices := info.numIndices
                        all := info.all
                        ctors := info.ctors
                        numNested := info.numNested
                        isRec := state.summary.isRec
                        isReflexive := state.summary.isReflexive
                        isUnsafe := info.isUnsafe
                      };
                      let finalConstant :=
                        PsKernelCoreConstantInfo.inductInfo finalInfo;
                      PsKernelCoreResult.ok
                        (psKernelCoreEnvironmentReplaceUnchecked
                          state.env finalConstant)
            else
              PsKernelCoreResult.error "invalid inductive header"
          else
            PsKernelCoreResult.error "constructor list does not match metadata"
        else
          PsKernelCoreResult.error "unsupported inductive metadata"

def psKernelCoreAddRecursiveInductive
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreInductiveInfo)
    (constructors : PsKernelCoreList PsKernelCoreConstructorInfo) :
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  psKernelCoreAddRecursiveInductiveWithResources
    budget psKernelCoreResourceConfigDefault env info constructors
