import Ps.KernelCore.Admission.Declaration.Validation

/-
Checked declaration admission.

Each operation first performs the shared validation required by Lean 4.34 and
only then returns an extended environment. Unsafe recursive declarations use a
fresh checker session bound to the recursive work environment, matching Lean's
kernel admission boundary.
-/

def psKernelAddAxiom
    [cachePolicy : PsKernelSemanticCachePolicy]
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
    [cachePolicy : PsKernelSemanticCachePolicy]
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
    [cachePolicy : PsKernelSemanticCachePolicy]
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
    [cachePolicy : PsKernelSemanticCachePolicy]
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
    (values : List PsKernelDefinitionInfo) :
    PsKernelEnvironment -> PsKernelEnvironment :=
  match values with
  | List.nil =>
      fun (environment : PsKernelEnvironment) =>
        environment
  | List.cons value rest =>
      let smaller :
          PsKernelEnvironment -> PsKernelEnvironment :=
        psKernelMutualWorkEnvironment rest;
      fun (environment : PsKernelEnvironment) =>
        smaller
          (psKernelEnvironmentAddUnchecked
            environment
            (PsKernelConstantInfo.defnInfo value))

def psKernelCheckMutualHeaders
    [cachePolicy : PsKernelSemanticCachePolicy]
    (values : List PsKernelDefinitionInfo) :
    Nat ->
    PsKernelEnvironment ->
    PsKernelDefinitionInfo ->
    Nat ->
    Nat ->
    List PsKernelName ->
    Except String Unit :=
  match values with
  | List.nil =>
      fun
        (_fuel : Nat)
        (_environment : PsKernelEnvironment)
        (_first : PsKernelDefinitionInfo)
        (_maxRecDepth : Nat)
        (_maxNatSize : Nat)
        (_seen : List PsKernelName) =>
        Except.ok ()
  | List.cons value rest =>
      let smaller :=
        psKernelCheckMutualHeaders rest;
      fun
        (fuel : Nat)
        (environment : PsKernelEnvironment)
        (first : PsKernelDefinitionInfo)
        (maxRecDepth : Nat)
        (maxNatSize : Nat)
        (seen : List PsKernelName) =>
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
                  smaller
                    fuel
                    environment
                    first
                    maxRecDepth
                    maxNatSize
                    (List.cons value.base.name seen)
          else
            Except.error
              "invalid mutual definition, declarations must have the same universe level parameters"
        else
          Except.error
            "invalid mutual definition, declarations must have the same safety annotation"

def psKernelCheckMutualBodies
    [cachePolicy : PsKernelSemanticCachePolicy]
    (values : List PsKernelDefinitionInfo) :
    Nat ->
    PsKernelEnvironment ->
    PsKernelDefinitionSafety ->
    Nat ->
    Nat ->
    Except String Unit :=
  match values with
  | List.nil =>
      fun
        (_fuel : Nat)
        (_environment : PsKernelEnvironment)
        (_safety : PsKernelDefinitionSafety)
        (_maxRecDepth : Nat)
        (_maxNatSize : Nat) =>
        Except.ok ()
  | List.cons value rest =>
      let smaller :=
        psKernelCheckMutualBodies rest;
      fun
        (fuel : Nat)
        (environment : PsKernelEnvironment)
        (safety : PsKernelDefinitionSafety)
        (maxRecDepth : Nat)
        (maxNatSize : Nat) =>
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
            smaller
              fuel
              environment
              safety
              maxRecDepth
              maxNatSize

def psKernelAddMutualDefinitions
    [cachePolicy : PsKernelSemanticCachePolicy]
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
              values
              fuel
              environment
              first
              maxRecDepth
              maxNatSize
              List.nil with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            let work :=
              psKernelMutualWorkEnvironment
                values
                environment;
            match
                psKernelCheckMutualBodies
                  values
                  fuel
                  work
                  first.safety
                  maxRecDepth
                  maxNatSize with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                Except.ok work
