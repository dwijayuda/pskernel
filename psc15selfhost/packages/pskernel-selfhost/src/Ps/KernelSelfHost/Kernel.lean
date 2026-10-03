import Ps.KernelSelfHost.CheckerSession

def psKernelSafetyEq
    (left : PsKernelDefinitionSafety)
    (right : PsKernelDefinitionSafety) : Bool :=
  match left with
  | PsKernelDefinitionSafety.unsafeDef =>
      match right with
      | PsKernelDefinitionSafety.unsafeDef => true
      | _ => false
  | PsKernelDefinitionSafety.safe =>
      match right with
      | PsKernelDefinitionSafety.safe => true
      | _ => false
  | PsKernelDefinitionSafety.partialDef =>
      match right with
      | PsKernelDefinitionSafety.partialDef => true
      | _ => false

def psKernelNameListsEq
    (left : List PsKernelName) :
    List PsKernelName -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsKernelName) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller :=
        psKernelNameListsEq leftTail;
      fun (right : List PsKernelName) =>
        match right with
        | List.nil =>
            false
        | List.cons rightHead rightTail =>
            if psKernelNameEq leftHead rightHead then
              smaller rightTail
            else
              false

def psKernelNameMember
    (target : PsKernelName)
    (values : List PsKernelName) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons head tail =>
      if psKernelNameEq target head then
        true
      else
        psKernelNameMember target tail

def psKernelFindUndefLevelParam
    (level : PsKernelLevel)
    (allowed : List PsKernelName) :
    Option PsKernelName :=
  match level with
  | PsKernelLevel.zero =>
      Option.none
  | PsKernelLevel.mvar _ =>
      Option.none
  | PsKernelLevel.param name =>
      if psKernelNameMember name allowed then
        Option.none
      else
        Option.some name
  | PsKernelLevel.succ inner =>
      psKernelFindUndefLevelParam
        inner
        allowed
  | PsKernelLevel.max left right =>
      match
          psKernelFindUndefLevelParam
            left
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefLevelParam
            right
            allowed
  | PsKernelLevel.imax left right =>
      match
          psKernelFindUndefLevelParam
            left
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefLevelParam
            right
            allowed

def psKernelFindUndefInLevels
    (levels : List PsKernelLevel)
    (allowed : List PsKernelName) :
    Option PsKernelName :=
  match levels with
  | List.nil =>
      Option.none
  | List.cons head tail =>
      match
          psKernelFindUndefLevelParam
            head
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefInLevels
            tail
            allowed

def psKernelFindUndefExprLevelParam
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) :
    Option PsKernelName :=
  match expr with
  | PsKernelExpr.sort level =>
      psKernelFindUndefLevelParam
        level
        allowed
  | PsKernelExpr.const _ levels =>
      psKernelFindUndefInLevels
        levels
        allowed
  | PsKernelExpr.app fn arg =>
      match
          psKernelFindUndefExprLevelParam
            fn
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            arg
            allowed
  | PsKernelExpr.lam _ type body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            body
            allowed
  | PsKernelExpr.forallE _ type body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            body
            allowed
  | PsKernelExpr.letE _ type value body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          match
              psKernelFindUndefExprLevelParam
                value
                allowed with
          | Option.some name =>
              Option.some name
          | Option.none =>
              psKernelFindUndefExprLevelParam
                body
                allowed
  | PsKernelExpr.mdata _ body =>
      psKernelFindUndefExprLevelParam
        body
        allowed
  | PsKernelExpr.proj _ _ body =>
      psKernelFindUndefExprLevelParam
        body
        allowed
  | _ =>
      Option.none

def psKernelLevelHasMVar
    (level : PsKernelLevel) : Bool :=
  match level with
  | PsKernelLevel.mvar _ =>
      true
  | PsKernelLevel.succ inner =>
      psKernelLevelHasMVar inner
  | PsKernelLevel.max left right =>
      if psKernelLevelHasMVar left then
        true
      else
        psKernelLevelHasMVar right
  | PsKernelLevel.imax left right =>
      if psKernelLevelHasMVar left then
        true
      else
        psKernelLevelHasMVar right
  | _ =>
      false

def psKernelLevelsHaveMVar
    (levels : List PsKernelLevel) : Bool :=
  match levels with
  | List.nil =>
      false
  | List.cons head tail =>
      if psKernelLevelHasMVar head then
        true
      else
        psKernelLevelsHaveMVar tail

def psKernelExprHasMVar
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.mvar _ =>
      true
  | PsKernelExpr.sort level =>
      psKernelLevelHasMVar level
  | PsKernelExpr.const _ levels =>
      psKernelLevelsHaveMVar levels
  | PsKernelExpr.app fn arg =>
      if psKernelExprHasMVar fn then
        true
      else
        psKernelExprHasMVar arg
  | PsKernelExpr.lam _ type body _ =>
      if psKernelExprHasMVar type then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelExprHasMVar type then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelExprHasMVar type then
        true
      else if psKernelExprHasMVar value then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasMVar body
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasMVar body
  | _ =>
      false

def psKernelCheckNoMVarNoFVar
    (expr : PsKernelExpr) :
    Except String Unit :=
  if psKernelExprHasMVar expr then
    Except.error
      "declaration has metavariables"
  else if psKernelExprHasFVar expr then
    Except.error
      "declaration has free variables"
  else
    Except.ok ()

def psKernelCheckLevelParams
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) :
    Except String Unit :=
  match
      psKernelFindUndefExprLevelParam
        expr
        allowed with
  | Option.some _ =>
      Except.error
        "invalid reference to undefined universe level parameter"
  | Option.none =>
      Except.ok ()

def psKernelCheckConstantBaseWithSession
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (base : PsKernelConstantBase) :
    Except String PsKernelCheckerSession :=
  if
      psKernelEnvironmentContains
        session.context.environment
        base.name then
    Except.error "already declared"
  else if
      psKernelNameHasDuplicates
        base.levelParams then
    Except.error
      "duplicate universe parameter"
  else
    match psKernelCheckNoMVarNoFVar base.type with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        match
            psKernelCheckLevelParams
              base.type
              base.levelParams with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            match
                psKernelSessionCheck
                  fuel
                  session
                  base.type with
            | Except.error error =>
                Except.error error
            | Except.ok typeType =>
                match
                    psKernelSessionEnsureSort
                      fuel
                      (Prod.snd typeType)
                      (Prod.fst typeType) with
                | Except.error error =>
                    Except.error error
                | Except.ok result =>
                    Except.ok
                      (Prod.snd result)

def psKernelCheckDefinitionBodyWithSession
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo) :
    Except String PsKernelCheckerSession :=
  match psKernelCheckNoMVarNoFVar value.value with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psKernelCheckLevelParams
            value.value
            value.base.levelParams with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match
              psKernelSessionCheck
                fuel
                session
                value.value with
          | Except.error error =>
              Except.error error
          | Except.ok valueType =>
              match
                  psKernelSessionIsDefEq
                    fuel
                    (Prod.snd valueType)
                    (Prod.fst valueType)
                    value.base.type with
              | Except.error error =>
                  Except.error error
              | Except.ok equal =>
                  if Prod.fst equal then
                    Except.ok
                      (Prod.snd equal)
                  else
                    Except.error
                      "definition type mismatch"

def psKernelAddAxiom
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelAxiomInfo)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  let safety :=
    if value.isUnsafe then
      PsKernelDefinitionSafety.unsafeDef
    else
      PsKernelDefinitionSafety.safe;
  let session :=
    psKernelMkCheckerSession
      environment
      value.base.levelParams
      safety
      maxRecDepth
      maxNatSize;
  match
      psKernelCheckConstantBaseWithSession
        fuel
        session
        value.base with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      psKernelEnvironmentAdd
        environment
        (PsKernelConstantInfo.axiomInfo value)

def psKernelAddDefinition
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  match value.safety with
  | PsKernelDefinitionSafety.unsafeDef =>
      let headerSession :=
        psKernelMkCheckerSession
          environment
          value.base.levelParams
          PsKernelDefinitionSafety.unsafeDef
          maxRecDepth
          maxNatSize;
      match
          psKernelCheckConstantBaseWithSession
            fuel
            headerSession
            value.base with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match
              psKernelEnvironmentAdd
                environment
                (PsKernelConstantInfo.defnInfo value) with
          | Except.error error =>
              Except.error error
          | Except.ok work =>
              let bodySession :=
                psKernelMkCheckerSession
                  work
                  value.base.levelParams
                  PsKernelDefinitionSafety.unsafeDef
                  maxRecDepth
                  maxNatSize;
              match
                  psKernelCheckDefinitionBodyWithSession
                    fuel
                    bodySession
                    value with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  Except.ok work
  | PsKernelDefinitionSafety.safe =>
      let session :=
        psKernelMkCheckerSession
          environment
          value.base.levelParams
          PsKernelDefinitionSafety.safe
          maxRecDepth
          maxNatSize;
      match
          psKernelCheckConstantBaseWithSession
            fuel
            session
            value.base with
      | Except.error error =>
          Except.error error
      | Except.ok afterHeader =>
          match
              psKernelCheckDefinitionBodyWithSession
                fuel
                afterHeader
                value with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              psKernelEnvironmentAdd
                environment
                (PsKernelConstantInfo.defnInfo value)
  | PsKernelDefinitionSafety.partialDef =>
      let session :=
        psKernelMkCheckerSession
          environment
          value.base.levelParams
          PsKernelDefinitionSafety.safe
          maxRecDepth
          maxNatSize;
      match
          psKernelCheckConstantBaseWithSession
            fuel
            session
            value.base with
      | Except.error error =>
          Except.error error
      | Except.ok afterHeader =>
          match
              psKernelCheckDefinitionBodyWithSession
                fuel
                afterHeader
                value with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              psKernelEnvironmentAdd
                environment
                (PsKernelConstantInfo.defnInfo value)

def psKernelAddTheorem
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelTheoremInfo)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  let session :=
    psKernelMkCheckerSession
      environment
      value.base.levelParams
      PsKernelDefinitionSafety.safe
      maxRecDepth
      maxNatSize;
  match
      psKernelCheckConstantBaseWithSession
        fuel
        session
        value.base with
  | Except.error error =>
      Except.error error
  | Except.ok afterHeader =>
      match
          psKernelSessionIsProp
            fuel
            afterHeader
            value.base.type with
      | Except.error error =>
          Except.error error
      | Except.ok propResult =>
          if Prod.fst propResult then
            match psKernelCheckNoMVarNoFVar value.value with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                match
                    psKernelCheckLevelParams
                      value.value
                      value.base.levelParams with
                | Except.error error =>
                    Except.error error
                | Except.ok _ =>
                    match
                        psKernelSessionCheck
                          fuel
                          (Prod.snd propResult)
                          value.value with
                    | Except.error error =>
                        Except.error error
                    | Except.ok valueType =>
                        match
                            psKernelSessionIsDefEq
                              fuel
                              (Prod.snd valueType)
                              (Prod.fst valueType)
                              value.base.type with
                        | Except.error error =>
                            Except.error error
                        | Except.ok equal =>
                            if Prod.fst equal then
                              psKernelEnvironmentAdd
                                environment
                                (PsKernelConstantInfo.thmInfo
                                  value)
                            else
                              Except.error
                                "theorem proof type mismatch"
          else
            Except.error
              "theorem type is not a proposition"

def psKernelAddOpaque
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelOpaqueInfo)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  let session :=
    psKernelMkCheckerSession
      environment
      value.base.levelParams
      PsKernelDefinitionSafety.safe
      maxRecDepth
      maxNatSize;
  match
      psKernelCheckConstantBaseWithSession
        fuel
        session
        value.base with
  | Except.error error =>
      Except.error error
  | Except.ok afterHeader =>
      match psKernelCheckNoMVarNoFVar value.value with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match
              psKernelCheckLevelParams
                value.value
                value.base.levelParams with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              match
                  psKernelSessionCheck
                    fuel
                    afterHeader
                    value.value with
              | Except.error error =>
                  Except.error error
              | Except.ok valueType =>
                  match
                      psKernelSessionIsDefEq
                        fuel
                        (Prod.snd valueType)
                        (Prod.fst valueType)
                        value.base.type with
                  | Except.error error =>
                      Except.error error
                  | Except.ok equal =>
                      if Prod.fst equal then
                        psKernelEnvironmentAdd
                          environment
                          (PsKernelConstantInfo.opaqueInfo
                            value)
                      else
                        Except.error
                          "opaque value type mismatch"

def psKernelMutualWorkEnvironment
    (values : List PsKernelDefinitionInfo)
    (environment : PsKernelEnvironment) :
    PsKernelEnvironment :=
  match values with
  | List.nil =>
      environment
  | List.cons value rest =>
      psKernelMutualWorkEnvironment
        rest
        (psKernelEnvironmentAddUnchecked
          environment
          (PsKernelConstantInfo.defnInfo value))

def psKernelCheckMutualHeaders
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (first : PsKernelDefinitionInfo)
    (maxRecDepth : Nat)
    (maxNatSize : Nat)
    (seen : List PsKernelName)
    (values : List PsKernelDefinitionInfo) :
    Except String Unit :=
  match values with
  | List.nil =>
      Except.ok ()
  | List.cons value rest =>
      if
          psKernelSafetyEq
            value.safety
            first.safety then
        if
            psKernelNameListsEq
              value.base.levelParams
              first.base.levelParams then
          if
              psKernelNameMember
                value.base.name
                seen then
            Except.error
              "invalid mutual definition, duplicate declaration name"
          else
            let session :=
              psKernelMkCheckerSession
                environment
                value.base.levelParams
                first.safety
                maxRecDepth
                maxNatSize;
            match
                psKernelCheckConstantBaseWithSession
                  fuel
                  session
                  value.base with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                psKernelCheckMutualHeaders
                  fuel
                  environment
                  first
                  maxRecDepth
                  maxNatSize
                  (List.cons value.base.name seen)
                  rest
        else
          Except.error
            "invalid mutual definition, declarations must have the same universe level parameters"
      else
        Except.error
          "invalid mutual definition, declarations must have the same safety annotation"

def psKernelCheckMutualBodies
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth : Nat)
    (maxNatSize : Nat)
    (values : List PsKernelDefinitionInfo) :
    Except String Unit :=
  match values with
  | List.nil =>
      Except.ok ()
  | List.cons value rest =>
      let session :=
        psKernelMkCheckerSession
          environment
          value.base.levelParams
          safety
          maxRecDepth
          maxNatSize;
      match
          psKernelCheckDefinitionBodyWithSession
            fuel
            session
            value with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psKernelCheckMutualBodies
            fuel
            environment
            safety
            maxRecDepth
            maxNatSize
            rest

def psKernelAddMutualDefinitions
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (values : List PsKernelDefinitionInfo)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  match values with
  | List.nil =>
      Except.error
        "invalid empty mutual definition"
  | List.cons first _ =>
      if
          psKernelDefinitionSafetyIsSafe
            first.safety then
        Except.error
          "invalid mutual definition, declaration is not tagged as unsafe/partial"
      else
        match
            psKernelCheckMutualHeaders
              fuel
              environment
              first
              maxRecDepth
              maxNatSize
              List.nil
              values with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            let work :=
              psKernelMutualWorkEnvironment
                values
                environment;
            match
                psKernelCheckMutualBodies
                  fuel
                  work
                  first.safety
                  maxRecDepth
                  maxNatSize
                  values with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                Except.ok work
