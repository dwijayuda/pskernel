import Ps.KernelCore.Admission

def psKernelCoreExprContainsConstName
    (target : PsKernelCoreName)
    (expr : PsKernelCoreExpr) : Bool :=
  match expr with
  | PsKernelCoreExpr.bvar _ => false
  | PsKernelCoreExpr.fvar _ => false
  | PsKernelCoreExpr.mvar _ => false
  | PsKernelCoreExpr.sort _ => false
  | PsKernelCoreExpr.const name _ => psKernelCoreNameEq target name
  | PsKernelCoreExpr.app fn arg =>
      if psKernelCoreExprContainsConstName target fn then
        true
      else
        psKernelCoreExprContainsConstName target arg
  | PsKernelCoreExpr.lam _ type body _ =>
      if psKernelCoreExprContainsConstName target type then
        true
      else
        psKernelCoreExprContainsConstName target body
  | PsKernelCoreExpr.forallE _ type body _ =>
      if psKernelCoreExprContainsConstName target type then
        true
      else
        psKernelCoreExprContainsConstName target body
  | PsKernelCoreExpr.letE _ type value body _ =>
      if psKernelCoreExprContainsConstName target type then
        true
      else if psKernelCoreExprContainsConstName target value then
        true
      else
        psKernelCoreExprContainsConstName target body
  | PsKernelCoreExpr.lit _ => false
  | PsKernelCoreExpr.mdata _ body =>
      psKernelCoreExprContainsConstName target body
  | PsKernelCoreExpr.proj typeName _ body =>
      if psKernelCoreNameEq target typeName then
        true
      else
        psKernelCoreExprContainsConstName target body

def psKernelCoreExprAppHead
    (expr : PsKernelCoreExpr) : PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.app fn _ => psKernelCoreExprAppHead fn
  | _ => expr

def psKernelCoreExprAppArgsRev
    (expr : PsKernelCoreExpr) : PsKernelCoreList PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.app fn arg =>
      PsKernelCoreList.cons arg (psKernelCoreExprAppArgsRev fn)
  | _ => PsKernelCoreList.nil

def psKernelCoreExprListReverseAppend
    (values : PsKernelCoreList PsKernelCoreExpr) :
    PsKernelCoreList PsKernelCoreExpr ->
    PsKernelCoreList PsKernelCoreExpr :=
  match values with
  | PsKernelCoreList.nil =>
      fun (acc : PsKernelCoreList PsKernelCoreExpr) => acc
  | PsKernelCoreList.cons head tail =>
      let next := psKernelCoreExprListReverseAppend tail;
      fun (acc : PsKernelCoreList PsKernelCoreExpr) =>
        next (PsKernelCoreList.cons head acc)

def psKernelCoreExprAppArgs
    (expr : PsKernelCoreExpr) : PsKernelCoreList PsKernelCoreExpr :=
  psKernelCoreExprListReverseAppend
    (psKernelCoreExprAppArgsRev expr)
    PsKernelCoreList.nil

def psKernelCoreInductiveExprListLength
    (values : PsKernelCoreList PsKernelCoreExpr) : Nat :=
  match values with
  | PsKernelCoreList.nil => 0
  | PsKernelCoreList.cons _ tail =>
      Nat.succ (psKernelCoreInductiveExprListLength tail)

def psKernelCoreExprListTake
    (count : Nat) :
    PsKernelCoreList PsKernelCoreExpr ->
    PsKernelCoreList PsKernelCoreExpr :=
  match count with
  | Nat.zero =>
      fun (_values : PsKernelCoreList PsKernelCoreExpr) =>
        PsKernelCoreList.nil
  | Nat.succ remaining =>
      let smaller := psKernelCoreExprListTake remaining;
      fun (values : PsKernelCoreList PsKernelCoreExpr) =>
        match values with
        | PsKernelCoreList.nil => PsKernelCoreList.nil
        | PsKernelCoreList.cons head tail =>
            PsKernelCoreList.cons head (smaller tail)

def psKernelCoreExprListContainsTarget
    (target : PsKernelCoreName)
    (values : PsKernelCoreList PsKernelCoreExpr) : Bool :=
  match values with
  | PsKernelCoreList.nil => false
  | PsKernelCoreList.cons head tail =>
      if psKernelCoreExprContainsConstName target head then
        true
      else
        psKernelCoreExprListContainsTarget target tail

def psKernelCoreInductiveUniformParamArgsMatch
    (binderDepth : Nat)
    (args : PsKernelCoreList PsKernelCoreExpr) : Nat -> Bool :=
  match args with
  | PsKernelCoreList.nil =>
      fun (_index : Nat) => true
  | PsKernelCoreList.cons head tail =>
      let restMatch :=
        psKernelCoreInductiveUniformParamArgsMatch binderDepth tail;
      fun (index : Nat) =>
        match head with
        | PsKernelCoreExpr.bvar bvarIndex =>
            if Nat.ble (Nat.succ index) binderDepth then
              if Nat.beq bvarIndex (Nat.sub (Nat.sub binderDepth 1) index) then
                restMatch (Nat.succ index)
              else
                false
            else
              false
        | _ => false

def psKernelCoreInductiveResultMatches
    (target : PsKernelCoreName)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (numParams : Nat)
    (numIndices : Nat)
    (binderDepth : Nat)
    (expr : PsKernelCoreExpr) : Bool :=
  let head := psKernelCoreExprAppHead expr;
  let args := psKernelCoreExprAppArgs expr;
  match head with
  | PsKernelCoreExpr.const name resultLevels =>
      if psKernelCoreNameEq target name then
        if psKernelCoreLevelListEq levels resultLevels then
          if Nat.beq
              (psKernelCoreInductiveExprListLength args)
              (Nat.add numParams numIndices) then
            let paramArgs := psKernelCoreExprListTake numParams args;
            if psKernelCoreInductiveUniformParamArgsMatch
                binderDepth paramArgs 0 then
              if psKernelCoreExprListContainsTarget target args then
                false
              else
                true
            else
              false
          else
            false
        else
          false
      else
        false
  | _ => false

def psKernelCoreInductiveConstructorRecursiveOccurrenceCore
    (target : PsKernelCoreName)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (numParams : Nat)
    (numIndices : Nat)
    (expr : PsKernelCoreExpr) : Nat -> Bool :=
  match expr with
  | PsKernelCoreExpr.forallE _ domain body _ =>
      let bodyCheck :=
        psKernelCoreInductiveConstructorRecursiveOccurrenceCore
          target levels numParams numIndices body;
      fun (binderDepth : Nat) =>
        if psKernelCoreExprContainsConstName target domain then
          true
        else
          bodyCheck (Nat.succ binderDepth)
  | _ =>
      fun (binderDepth : Nat) =>
        if psKernelCoreInductiveResultMatches
            target levels numParams numIndices binderDepth expr then
          false
        else
          psKernelCoreExprContainsConstName target expr

def psKernelCoreInductiveConstructorRecursiveOccurrence
    (target : PsKernelCoreName)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (numParams : Nat)
    (numIndices : Nat)
    (expr : PsKernelCoreExpr) : Bool :=
  psKernelCoreInductiveConstructorRecursiveOccurrenceCore
    target levels numParams numIndices expr 0

structure PsKernelCoreInductiveTelescopeSummary where
  binderCount : Nat
  result : PsKernelCoreExpr

def psKernelCoreInductiveSummarizeTelescope
    (expr : PsKernelCoreExpr) : PsKernelCoreInductiveTelescopeSummary :=
  match expr with
  | PsKernelCoreExpr.forallE _ _ body _ =>
      let rest := psKernelCoreInductiveSummarizeTelescope body;
      {
        binderCount := Nat.succ rest.binderCount
        result := rest.result
      }
  | _ =>
      {
        binderCount := 0
        result := expr
      }

def psKernelCoreInductiveNameListEq
    (left : PsKernelCoreList PsKernelCoreName) :
    PsKernelCoreList PsKernelCoreName -> Bool :=
  match left with
  | PsKernelCoreList.nil =>
      fun (right : PsKernelCoreList PsKernelCoreName) =>
        match right with
        | PsKernelCoreList.nil => true
        | PsKernelCoreList.cons _ _ => false
  | PsKernelCoreList.cons leftHead leftTail =>
      let restEq := psKernelCoreInductiveNameListEq leftTail;
      fun (right : PsKernelCoreList PsKernelCoreName) =>
        match right with
        | PsKernelCoreList.nil => false
        | PsKernelCoreList.cons rightHead rightTail =>
            if psKernelCoreNameEq leftHead rightHead then
              restEq rightTail
            else
              false

def psKernelCoreInductiveLevelsFromNames
    (names : PsKernelCoreList PsKernelCoreName) :
    PsKernelCoreList PsKernelCoreLevel :=
  match names with
  | PsKernelCoreList.nil => PsKernelCoreList.nil
  | PsKernelCoreList.cons name rest =>
      PsKernelCoreList.cons
        (PsKernelCoreLevel.param name)
        (psKernelCoreInductiveLevelsFromNames rest)

def psKernelCoreInductiveConstructorNames
    (constructors : PsKernelCoreList PsKernelCoreConstructorInfo) :
    PsKernelCoreList PsKernelCoreName :=
  match constructors with
  | PsKernelCoreList.nil => PsKernelCoreList.nil
  | PsKernelCoreList.cons ctor rest =>
      PsKernelCoreList.cons
        ctor.base.name
        (psKernelCoreInductiveConstructorNames rest)

def psKernelCoreInductiveSingleFamilyMetadataValid
    (info : PsKernelCoreInductiveInfo) : Bool :=
  match info.all with
  | PsKernelCoreList.cons onlyName PsKernelCoreList.nil =>
      if psKernelCoreNameEq onlyName info.base.name then
        if Nat.beq info.numNested 0 then
          if info.isRec then
            false
          else if info.isReflexive then
            false
          else
            true
        else
          false
      else
        false
  | _ => false

def psKernelCoreInductiveHeaderShapeValid
    (info : PsKernelCoreInductiveInfo) : Bool :=
  let summary := psKernelCoreInductiveSummarizeTelescope info.base.type;
  if Nat.beq summary.binderCount (Nat.add info.numParams info.numIndices) then
    match summary.result with
    | PsKernelCoreExpr.sort _ => true
    | _ => false
  else
    false

def psKernelCoreInductiveValidateConstructorWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (info : PsKernelCoreInductiveInfo)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (ctor : PsKernelCoreConstructorInfo) :
    PsKernelCoreEnvironment -> Nat ->
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  fun (workEnv : PsKernelCoreEnvironment) (expectedIndex : Nat) =>
    if psKernelCoreNameEq ctor.induct info.base.name then
      if Nat.beq ctor.cidx expectedIndex then
        if Nat.beq ctor.numParams info.numParams then
          if psKernelCoreBoolEq ctor.isUnsafe info.isUnsafe then
            if psKernelCoreInductiveNameListEq
                ctor.base.levelParams info.base.levelParams then
              let summary :=
                psKernelCoreInductiveSummarizeTelescope ctor.base.type;
              if Nat.ble info.numParams summary.binderCount then
                if Nat.beq
                    ctor.numFields
                    (Nat.sub summary.binderCount info.numParams) then
                  if psKernelCoreInductiveResultMatches
                      info.base.name levels info.numParams info.numIndices
                      summary.binderCount summary.result then
                    if psKernelCoreInductiveConstructorRecursiveOccurrence
                        info.base.name levels info.numParams info.numIndices
                        ctor.base.type then
                      PsKernelCoreResult.error
                        "recursive inductive occurrence is not supported"
                    else
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
                          PsKernelCoreResult.ok
                            (psKernelCoreEnvironmentAddUnchecked
                              workEnv
                              (PsKernelCoreConstantInfo.ctorInfo ctor))
                  else
                    PsKernelCoreResult.error "invalid constructor result"
                else
                  PsKernelCoreResult.error "invalid constructor field count"
              else
                PsKernelCoreResult.error "constructor has fewer parameters than declared"
            else
              PsKernelCoreResult.error "constructor universe parameters do not match"
          else
            PsKernelCoreResult.error "constructor safety does not match inductive"
        else
          PsKernelCoreResult.error "constructor parameter count does not match"
      else
        PsKernelCoreResult.error "constructor index does not match order"
    else
      PsKernelCoreResult.error "constructor does not belong to inductive"

def psKernelCoreInductiveAddConstructorsWithResources
    (constructors : PsKernelCoreList PsKernelCoreConstructorInfo) :
    Nat ->
    PsKernelCoreResourceConfig ->
    PsKernelCoreInductiveInfo ->
    PsKernelCoreList PsKernelCoreLevel ->
    PsKernelCoreEnvironment ->
    Nat ->
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  match constructors with
  | PsKernelCoreList.nil =>
      fun (_budget : Nat)
          (_resources : PsKernelCoreResourceConfig)
          (_info : PsKernelCoreInductiveInfo)
          (_levels : PsKernelCoreList PsKernelCoreLevel)
          (workEnv : PsKernelCoreEnvironment)
          (_index : Nat) =>
        PsKernelCoreResult.ok workEnv
  | PsKernelCoreList.cons ctor rest =>
      let addRest := psKernelCoreInductiveAddConstructorsWithResources rest;
      fun (budget : Nat)
          (resources : PsKernelCoreResourceConfig)
          (info : PsKernelCoreInductiveInfo)
          (levels : PsKernelCoreList PsKernelCoreLevel)
          (workEnv : PsKernelCoreEnvironment)
          (index : Nat) =>
        match psKernelCoreInductiveValidateConstructorWithResources
            budget resources info levels ctor workEnv index with
        | PsKernelCoreResult.error message =>
            PsKernelCoreResult.error message
        | PsKernelCoreResult.ok nextEnv =>
            addRest budget resources info levels nextEnv (Nat.succ index)

def psKernelCoreAddNonRecursiveInductiveWithResources
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
                  let workEnv :=
                    psKernelCoreEnvironmentAddUnchecked
                      env
                      (PsKernelCoreConstantInfo.inductInfo info);
                  let levels :=
                    psKernelCoreInductiveLevelsFromNames info.base.levelParams;
                  psKernelCoreInductiveAddConstructorsWithResources
                    constructors remaining resources info levels workEnv 0
            else
              PsKernelCoreResult.error "invalid inductive header"
          else
            PsKernelCoreResult.error "constructor list does not match metadata"
        else
          PsKernelCoreResult.error "unsupported inductive metadata"

def psKernelCoreAddNonRecursiveInductive
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreInductiveInfo)
    (constructors : PsKernelCoreList PsKernelCoreConstructorInfo) :
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  psKernelCoreAddNonRecursiveInductiveWithResources
    budget psKernelCoreResourceConfigDefault env info constructors
