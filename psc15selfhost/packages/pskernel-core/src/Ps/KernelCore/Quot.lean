import Ps.KernelCore.Environment

def psKernelCoreQuotName : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous "Quot"

def psKernelCoreQuotMkName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCoreQuotName "mk"

def psKernelCoreQuotLiftName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCoreQuotName "lift"

def psKernelCoreQuotIndName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCoreQuotName "ind"

def psKernelCoreQuotEqName : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous "Eq"

def psKernelCoreQuotEqReflName : PsKernelCoreName :=
  PsKernelCoreName.str psKernelCoreQuotEqName "refl"

def psKernelCoreQuotUName : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous "u"

def psKernelCoreQuotVName : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous "v"

def psKernelCoreQuotOneLevel
    (level : PsKernelCoreLevel) : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons level PsKernelCoreList.nil

def psKernelCoreQuotOneName
    (name : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons name PsKernelCoreList.nil

def psKernelCoreQuotTwoNames
    (first : PsKernelCoreName)
    (second : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons first
    (PsKernelCoreList.cons second PsKernelCoreList.nil)

def psKernelCoreQuotArrow
    (domain : PsKernelCoreExpr)
    (codomain : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE
    PsKernelCoreName.anonymous
    domain
    codomain
    PsKernelCoreBinderInfo.default

def psKernelCoreQuotExpectedEqType
    (uName : PsKernelCoreName) : PsKernelCoreExpr :=
  let u := PsKernelCoreLevel.param uName;
  PsKernelCoreExpr.forallE
    PsKernelCoreName.anonymous
    (PsKernelCoreExpr.sort u)
    (PsKernelCoreExpr.forallE
      PsKernelCoreName.anonymous
      (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.forallE
        PsKernelCoreName.anonymous
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.sort PsKernelCoreLevel.zero)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKernelCoreQuotExpectedEqReflType
    (uName : PsKernelCoreName) : PsKernelCoreExpr :=
  let u := PsKernelCoreLevel.param uName;
  let levels := psKernelCoreQuotOneLevel u;
  let result :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.app
          (PsKernelCoreExpr.const psKernelCoreQuotEqName levels)
          (PsKernelCoreExpr.bvar 1))
        (PsKernelCoreExpr.bvar 0))
      (PsKernelCoreExpr.bvar 0);
  PsKernelCoreExpr.forallE
    PsKernelCoreName.anonymous
    (PsKernelCoreExpr.sort u)
    (PsKernelCoreExpr.forallE
      PsKernelCoreName.anonymous
      (PsKernelCoreExpr.bvar 0)
      result
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKernelCoreQuotSingletonNameEq
    (values : PsKernelCoreList PsKernelCoreName)
    (expected : PsKernelCoreName) : Bool :=
  match values with
  | PsKernelCoreList.nil => false
  | PsKernelCoreList.cons head tail =>
      if psKernelCoreNameEq head expected then
        match tail with
        | PsKernelCoreList.nil => true
        | PsKernelCoreList.cons _ _ => false
      else
        false

def psKernelCoreQuotSingleName?
    (values : PsKernelCoreList PsKernelCoreName) :
    PsKernelCoreOption PsKernelCoreName :=
  match values with
  | PsKernelCoreList.nil => PsKernelCoreOption.none
  | PsKernelCoreList.cons head tail =>
      match tail with
      | PsKernelCoreList.nil => PsKernelCoreOption.some head
      | PsKernelCoreList.cons _ _ => PsKernelCoreOption.none

def psKernelCoreQuotEqMetadataOk
    (info : PsKernelCoreInductiveInfo) : Bool :=
  if Nat.beq info.numParams 1 then
    if Nat.beq info.numIndices 2 then
      if psKernelCoreQuotSingletonNameEq info.all psKernelCoreQuotEqName then
        if psKernelCoreQuotSingletonNameEq info.ctors psKernelCoreQuotEqReflName then
          if Nat.beq info.numNested 0 then
            if info.isRec then
              false
            else if info.isReflexive then
              false
            else if info.isUnsafe then
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
  else
    false

def psKernelCoreQuotReflMetadataOk
    (info : PsKernelCoreConstructorInfo) : Bool :=
  if psKernelCoreNameEq info.induct psKernelCoreQuotEqName then
    if Nat.beq info.cidx 0 then
      if Nat.beq info.numParams 1 then
        if Nat.beq info.numFields 1 then
          if info.isUnsafe then false else true
        else
          false
      else
        false
    else
      false
  else
    false

def psKernelCoreCheckEqReflForQuot
    (env : PsKernelCoreEnvironment)
    (reflName : PsKernelCoreName) : PsKernelCoreResult String Bool :=
  if psKernelCoreNameEq reflName psKernelCoreQuotEqReflName then
    match psKernelCoreEnvironmentFind? env reflName with
    | PsKernelCoreOption.none =>
        PsKernelCoreResult.error
          "failed to initialize quot module, missing Eq constructor"
    | PsKernelCoreOption.some info =>
        match info with
        | PsKernelCoreConstantInfo.ctorInfo reflInfo =>
            if psKernelCoreQuotReflMetadataOk reflInfo then
              match psKernelCoreQuotSingleName? reflInfo.base.levelParams with
              | PsKernelCoreOption.none =>
                  PsKernelCoreResult.error
                    "failed to initialize quot module, unexpected universe params at Eq constructor"
              | PsKernelCoreOption.some reflUName =>
                  if psKernelCoreExprEq
                      reflInfo.base.type
                      (psKernelCoreQuotExpectedEqReflType reflUName) then
                    PsKernelCoreResult.ok true
                  else
                    PsKernelCoreResult.error
                      "failed to initialize quot module, unexpected type for Eq constructor"
            else
              PsKernelCoreResult.error
                "failed to initialize quot module, unexpected Eq constructor metadata"
        | _ =>
            PsKernelCoreResult.error
              "failed to initialize quot module, Eq constructor has unexpected declaration kind"
  else
    PsKernelCoreResult.error
      "failed to initialize quot module, unexpected constructor for Eq type"

def psKernelCoreCheckEqForQuot
    (env : PsKernelCoreEnvironment) : PsKernelCoreResult String Bool :=
  match psKernelCoreEnvironmentFind? env psKernelCoreQuotEqName with
  | PsKernelCoreOption.none =>
      PsKernelCoreResult.error
        "failed to initialize quot module, environment does not have Eq type"
  | PsKernelCoreOption.some info =>
      match info with
      | PsKernelCoreConstantInfo.inductInfo eqInfo =>
          if psKernelCoreQuotEqMetadataOk eqInfo then
            match psKernelCoreQuotSingleName? eqInfo.base.levelParams with
            | PsKernelCoreOption.none =>
                PsKernelCoreResult.error
                  "failed to initialize quot module, unexpected number of universe params at Eq type"
            | PsKernelCoreOption.some uName =>
                if psKernelCoreExprEq
                    eqInfo.base.type
                    (psKernelCoreQuotExpectedEqType uName) then
                  match eqInfo.ctors with
                  | PsKernelCoreList.nil =>
                      PsKernelCoreResult.error
                        "failed to initialize quot module, unexpected number of constructors for Eq type"
                  | PsKernelCoreList.cons reflName tail =>
                      match tail with
                      | PsKernelCoreList.nil =>
                          psKernelCoreCheckEqReflForQuot env reflName
                      | PsKernelCoreList.cons _ _ =>
                          PsKernelCoreResult.error
                            "failed to initialize quot module, unexpected number of constructors for Eq type"
                else
                  PsKernelCoreResult.error
                    "failed to initialize quot module, Eq has an unexpected type"
          else
            PsKernelCoreResult.error
              "failed to initialize quot module, unexpected Eq metadata"
      | _ =>
          PsKernelCoreResult.error
            "failed to initialize quot module, environment does not have Eq inductive type"

def psKernelCoreMakeQuotType
    (uName : PsKernelCoreName) : PsKernelCoreExpr :=
  let u := PsKernelCoreLevel.param uName;
  let relationType :=
    psKernelCoreQuotArrow
      (PsKernelCoreExpr.bvar 0)
      (psKernelCoreQuotArrow
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.sort PsKernelCoreLevel.zero));
  PsKernelCoreExpr.forallE
    PsKernelCoreName.anonymous
    (PsKernelCoreExpr.sort u)
    (PsKernelCoreExpr.forallE
      PsKernelCoreName.anonymous
      relationType
      (PsKernelCoreExpr.sort u)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKernelCoreMakeQuotMkType
    (uName : PsKernelCoreName) : PsKernelCoreExpr :=
  let u := PsKernelCoreLevel.param uName;
  let levels := psKernelCoreQuotOneLevel u;
  let relationType :=
    psKernelCoreQuotArrow
      (PsKernelCoreExpr.bvar 0)
      (psKernelCoreQuotArrow
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.sort PsKernelCoreLevel.zero));
  let result :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psKernelCoreQuotName levels)
        (PsKernelCoreExpr.bvar 2))
      (PsKernelCoreExpr.bvar 1);
  PsKernelCoreExpr.forallE
    PsKernelCoreName.anonymous
    (PsKernelCoreExpr.sort u)
    (PsKernelCoreExpr.forallE
      PsKernelCoreName.anonymous
      relationType
      (PsKernelCoreExpr.forallE
        PsKernelCoreName.anonymous
        (PsKernelCoreExpr.bvar 1)
        result
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKernelCoreMakeQuotLiftType
    (uName : PsKernelCoreName)
    (vName : PsKernelCoreName) : PsKernelCoreExpr :=
  let u := PsKernelCoreLevel.param uName;
  let v := PsKernelCoreLevel.param vName;
  let quotLevels := psKernelCoreQuotOneLevel u;
  let eqLevels := psKernelCoreQuotOneLevel v;
  let relationType :=
    psKernelCoreQuotArrow
      (PsKernelCoreExpr.bvar 0)
      (psKernelCoreQuotArrow
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.sort PsKernelCoreLevel.zero));
  let fType :=
    psKernelCoreQuotArrow
      (PsKernelCoreExpr.bvar 2)
      (PsKernelCoreExpr.bvar 1);
  let relationAB :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.bvar 4)
        (PsKernelCoreExpr.bvar 1))
      (PsKernelCoreExpr.bvar 0);
  let fA :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.bvar 3)
      (PsKernelCoreExpr.bvar 2);
  let fB :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.bvar 3)
      (PsKernelCoreExpr.bvar 1);
  let eqFAB :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.app
          (PsKernelCoreExpr.const psKernelCoreQuotEqName eqLevels)
          (PsKernelCoreExpr.bvar 4))
        fA)
      fB;
  let sanityType :=
    psKernelCoreQuotArrow
      (PsKernelCoreExpr.bvar 3)
      (psKernelCoreQuotArrow
        (PsKernelCoreExpr.bvar 4)
        (psKernelCoreQuotArrow relationAB eqFAB));
  let quotR :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psKernelCoreQuotName quotLevels)
        (PsKernelCoreExpr.bvar 4))
      (PsKernelCoreExpr.bvar 3);
  PsKernelCoreExpr.forallE
    PsKernelCoreName.anonymous
    (PsKernelCoreExpr.sort u)
    (PsKernelCoreExpr.forallE
      PsKernelCoreName.anonymous
      relationType
      (PsKernelCoreExpr.forallE
        PsKernelCoreName.anonymous
        (PsKernelCoreExpr.sort v)
        (PsKernelCoreExpr.forallE
          PsKernelCoreName.anonymous
          fType
          (PsKernelCoreExpr.forallE
            PsKernelCoreName.anonymous
            sanityType
            (PsKernelCoreExpr.forallE
              PsKernelCoreName.anonymous
              quotR
              (PsKernelCoreExpr.bvar 3)
              PsKernelCoreBinderInfo.default)
            PsKernelCoreBinderInfo.default)
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.implicit)
      PsKernelCoreBinderInfo.implicit)
    PsKernelCoreBinderInfo.implicit

def psKernelCoreMakeQuotIndType
    (uName : PsKernelCoreName) : PsKernelCoreExpr :=
  let u := PsKernelCoreLevel.param uName;
  let levels := psKernelCoreQuotOneLevel u;
  let relationType :=
    psKernelCoreQuotArrow
      (PsKernelCoreExpr.bvar 0)
      (psKernelCoreQuotArrow
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.sort PsKernelCoreLevel.zero));
  let betaQuotR :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psKernelCoreQuotName levels)
        (PsKernelCoreExpr.bvar 1))
      (PsKernelCoreExpr.bvar 0);
  let betaType :=
    psKernelCoreQuotArrow
      betaQuotR
      (PsKernelCoreExpr.sort PsKernelCoreLevel.zero);
  let quotMkA :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.app
          (PsKernelCoreExpr.const psKernelCoreQuotMkName levels)
          (PsKernelCoreExpr.bvar 3))
        (PsKernelCoreExpr.bvar 2))
      (PsKernelCoreExpr.bvar 0);
  let allQuot :=
    psKernelCoreQuotArrow
      (PsKernelCoreExpr.bvar 2)
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.bvar 1)
        quotMkA);
  let quotR :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psKernelCoreQuotName levels)
        (PsKernelCoreExpr.bvar 3))
      (PsKernelCoreExpr.bvar 2);
  let result :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.bvar 2)
      (PsKernelCoreExpr.bvar 0);
  PsKernelCoreExpr.forallE
    PsKernelCoreName.anonymous
    (PsKernelCoreExpr.sort u)
    (PsKernelCoreExpr.forallE
      PsKernelCoreName.anonymous
      relationType
      (PsKernelCoreExpr.forallE
        PsKernelCoreName.anonymous
        betaType
        (PsKernelCoreExpr.forallE
          PsKernelCoreName.anonymous
          allQuot
          (PsKernelCoreExpr.forallE
            PsKernelCoreName.anonymous
            quotR
            result
            PsKernelCoreBinderInfo.default)
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.implicit)
      PsKernelCoreBinderInfo.implicit)
    PsKernelCoreBinderInfo.implicit

def psKernelCoreAddQuot
    (env : PsKernelCoreEnvironment) :
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  if env.quotInitialized then
    PsKernelCoreResult.ok env
  else
    match psKernelCoreCheckEqForQuot env with
    | PsKernelCoreResult.error message => PsKernelCoreResult.error message
    | PsKernelCoreResult.ok _ =>
        if psKernelCoreEnvironmentContains env psKernelCoreQuotName then
          PsKernelCoreResult.error
            "failed to initialize quot module, quotient name is already declared"
        else if psKernelCoreEnvironmentContains env psKernelCoreQuotMkName then
          PsKernelCoreResult.error
            "failed to initialize quot module, quotient name is already declared"
        else if psKernelCoreEnvironmentContains env psKernelCoreQuotLiftName then
          PsKernelCoreResult.error
            "failed to initialize quot module, quotient name is already declared"
        else if psKernelCoreEnvironmentContains env psKernelCoreQuotIndName then
          PsKernelCoreResult.error
            "failed to initialize quot module, quotient name is already declared"
        else
          let uName := psKernelCoreQuotUName;
          let vName := psKernelCoreQuotVName;
          let env1 :=
            psKernelCoreEnvironmentAddUnchecked env
              (PsKernelCoreConstantInfo.quotInfo {
                base := {
                  name := psKernelCoreQuotName
                  levelParams := psKernelCoreQuotOneName uName
                  type := psKernelCoreMakeQuotType uName
                }
                kind := PsKernelCoreQuotKind.typeQ
              });
          let env2 :=
            psKernelCoreEnvironmentAddUnchecked env1
              (PsKernelCoreConstantInfo.quotInfo {
                base := {
                  name := psKernelCoreQuotMkName
                  levelParams := psKernelCoreQuotOneName uName
                  type := psKernelCoreMakeQuotMkType uName
                }
                kind := PsKernelCoreQuotKind.ctorQ
              });
          let env3 :=
            psKernelCoreEnvironmentAddUnchecked env2
              (PsKernelCoreConstantInfo.quotInfo {
                base := {
                  name := psKernelCoreQuotLiftName
                  levelParams := psKernelCoreQuotTwoNames uName vName
                  type := psKernelCoreMakeQuotLiftType uName vName
                }
                kind := PsKernelCoreQuotKind.liftQ
              });
          let env4 :=
            psKernelCoreEnvironmentAddUnchecked env3
              (PsKernelCoreConstantInfo.quotInfo {
                base := {
                  name := psKernelCoreQuotIndName
                  levelParams := psKernelCoreQuotOneName uName
                  type := psKernelCoreMakeQuotIndType uName
                }
                kind := PsKernelCoreQuotKind.indQ
              });
          PsKernelCoreResult.ok
            (psKernelCoreEnvironmentMarkQuotInitialized env4)
