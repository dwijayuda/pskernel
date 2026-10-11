import Ps.KernelCore.Admission.Inductive.Nested.Restore

/-
Nested-inductive post-restoration validation.

After the transformed mutual bundle has been admitted and user-facing
constructors/recursors have been reconstructed, this module checks that the
restored types/rules agree with the original nested templates.

It contains only validation/comparison logic. Final environment rewriting is
separated into `Commit.lean`.
-/

def psKernelSimpleNestedSessionWithParamsWorker
    (params : List PsKernelOpenBinder) :
    PsKernelCheckerSession ->
    PsKernelCheckerSession :=
  match params with
  | List.nil =>
      fun
        (session : PsKernelCheckerSession) =>
        session
  | List.cons param rest =>
      let smaller :
          PsKernelCheckerSession ->
          PsKernelCheckerSession :=
        psKernelSimpleNestedSessionWithParamsWorker
          rest;
      fun
        (session : PsKernelCheckerSession) =>
        let nextLocal :=
          psKernelLocalContextAddLocal
            session.context.localContext
            param.internalName
            param.userName
            param.type
            param.binderInfo;
        let nextContext :=
          psKernelCheckerContextWithLocalContext
            session.context
            nextLocal;
        smaller
          (PsKernelCheckerSession.mk
            nextContext
            session.state)

def psKernelSimpleNestedSessionWithParams
    (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (params : List PsKernelOpenBinder)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    PsKernelCheckerSession :=
  psKernelSimpleNestedSessionWithParamsWorker
    params
    (psKernelMkCheckerSession
      environment
      levelParams
      safety
      maxRecDepth
      maxNatSize)

def psKernelSimpleNestedValidateTemplates
    (fuel : Nat)
    (finalEnvironment : PsKernelEnvironment)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (canonicalParams : List PsKernelOpenBinder)
    (maxRecDepth : Nat)
    (maxNatSize : Nat)
    (families : List PsKernelSimpleNestedAuxFamily) :
    Except String Unit :=
  match families with
  | List.nil =>
      Except.ok ()
  | List.cons family rest =>
      let session :=
        psKernelSimpleNestedSessionWithParams
          finalEnvironment
          levelParams
          safety
          canonicalParams
          maxRecDepth
          maxNatSize;
      match
          psKernelSessionCheck
            fuel
            session
            family.nestedTemplate with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psKernelSimpleNestedValidateTemplates
            fuel
            finalEnvironment
            levelParams
            safety
            canonicalParams
            maxRecDepth
            maxNatSize
            rest

def psKernelSimpleNestedValidateRulesWorker
    (rules : List PsKernelRecursorRule) :
    Nat ->
    PsKernelCheckerSession ->
    Except String PsKernelCheckerSession :=
  match rules with
  | List.nil =>
      fun
        (_fuel : Nat)
        (session : PsKernelCheckerSession) =>
        Except.ok session
  | List.cons rule rest =>
      let smaller :=
        psKernelSimpleNestedValidateRulesWorker
          rest;
      fun
        (fuel : Nat)
        (session : PsKernelCheckerSession) =>
        match
            psKernelSessionCheck
              fuel
              session
              rule.rhs with
        | Except.error error =>
            Except.error error
        | Except.ok checked =>
            smaller
              fuel
              (Prod.snd checked)

def psKernelSimpleNestedValidateRules
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (rules : List PsKernelRecursorRule) :
    Except String Unit :=
  match
      psKernelSimpleNestedValidateRulesWorker
        rules
        fuel
        session with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      Except.ok ()

def psKernelSimpleNestedValidateConstructorTypes
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth : Nat)
    (maxNatSize : Nat)
    (ctorNames : List PsKernelName) :
    Except String Unit :=
  match ctorNames with
  | List.nil =>
      Except.ok ()
  | List.cons ctorName rest =>
      match
          psKernelEnvironmentFind
            environment
            ctorName with
      | Option.none =>
          Except.error
            "restored constructor missing during validation"
      | Option.some infoValue =>
          match infoValue with
          | PsKernelConstantInfo.ctorInfo info =>
              let session :=
                psKernelMkCheckerSession
                  environment
                  levelParams
                  safety
                  maxRecDepth
                  maxNatSize;
              match
                  psKernelSessionCheck
                    fuel
                    session
                    info.base.type with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  psKernelSimpleNestedValidateConstructorTypes
                    fuel
                    environment
                    levelParams
                    safety
                    maxRecDepth
                    maxNatSize
                    rest
          | _ =>
              Except.error
                "restored constructor missing during validation"

def psKernelSimpleNestedValidateOriginals
    (fuel : Nat)
    (finalEnvironment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth : Nat)
    (maxNatSize : Nat)
    (types : List PsKernelSimpleMutualTypeDecl) :
    Except String Unit :=
  match types with
  | List.nil =>
      Except.ok ()
  | List.cons typeDecl rest =>
      match
          psKernelEnvironmentFind
            finalEnvironment
            typeDecl.name with
      | Option.none =>
          Except.error
            "restored inductive missing during validation"
      | Option.some infoValue =>
          match infoValue with
          | PsKernelConstantInfo.inductInfo info =>
              match
                  psKernelSimpleNestedValidateConstructorTypes
                    fuel
                    finalEnvironment
                    decl.levelParams
                    safety
                    maxRecDepth
                    maxNatSize
                    info.ctors with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  let recName :=
                    psKernelSimpleRecName
                      typeDecl.name;
                  match
                      psKernelEnvironmentFind
                        finalEnvironment
                        recName with
                  | Option.none =>
                      Except.error
                        "restored recursor missing during validation"
                  | Option.some recValue =>
                      match recValue with
                      | PsKernelConstantInfo.recInfo recInfo =>
                          let session :=
                            psKernelMkCheckerSession
                              finalEnvironment
                              recInfo.base.levelParams
                              safety
                              maxRecDepth
                              maxNatSize;
                          match
                              psKernelSessionCheck
                                fuel
                                session
                                recInfo.base.type with
                          | Except.error error =>
                              Except.error error
                          | Except.ok recTypeType =>
                              match
                                  psKernelSessionEnsureSort
                                    fuel
                                    (Prod.snd recTypeType)
                                    (Prod.fst recTypeType) with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok sorted =>
                                  match
                                      psKernelSimpleNestedValidateRules
                                        fuel
                                        (Prod.snd sorted)
                                        recInfo.rules with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok _ =>
                                      psKernelSimpleNestedValidateOriginals
                                        fuel
                                        finalEnvironment
                                        decl
                                        safety
                                        maxRecDepth
                                        maxNatSize
                                        rest
                      | _ =>
                          Except.error
                            "restored recursor missing during validation"
          | _ =>
              Except.error
                "restored inductive missing during validation"

def psKernelSimpleNestedRuleListLength
    (rules : List PsKernelRecursorRule) :
    Nat :=
  match rules with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ
        (psKernelSimpleNestedRuleListLength
          rest)

def psKernelSimpleNestedCompareValidatedRuleTypesWithFuel
    (steps : Nat) :
    Nat ->
    PsKernelEnvironment ->
    PsKernelEnvironment ->
    PsKernelDefinitionSafety ->
    Nat ->
    Nat ->
    List PsKernelSimpleNestedAuxFamily ->
    List (Prod PsKernelName PsKernelName) ->
    List PsKernelOpenBinder ->
    Nat ->
    List PsKernelName ->
    List PsKernelName ->
    List PsKernelRecursorRule ->
    List PsKernelRecursorRule ->
    Except String Unit :=
  match steps with
  | Nat.zero =>
      fun
        (_fuel : Nat)
        (_transformed : PsKernelEnvironment)
        (_finalEnvironment : PsKernelEnvironment)
        (_safety : PsKernelDefinitionSafety)
        (_maxRecDepth : Nat)
        (_maxNatSize : Nat)
        (_families : List PsKernelSimpleNestedAuxFamily)
        (_renames : List (Prod PsKernelName PsKernelName))
        (_canonicalParams : List PsKernelOpenBinder)
        (_numParams : Nat)
        (_oldLevelParams : List PsKernelName)
        (_newLevelParams : List PsKernelName)
        (oldRules : List PsKernelRecursorRule)
        (newRules : List PsKernelRecursorRule) =>
        match oldRules with
        | List.nil =>
            match newRules with
            | List.nil =>
                Except.ok ()
            | List.cons _ _ =>
                Except.error
                  "restored nested recursor rule count mismatch"
        | List.cons _ _ =>
            Except.error
              "nested rule comparison budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleNestedCompareValidatedRuleTypesWithFuel
          remaining;
      fun
        (fuel : Nat)
        (transformed : PsKernelEnvironment)
        (finalEnvironment : PsKernelEnvironment)
        (safety : PsKernelDefinitionSafety)
        (maxRecDepth : Nat)
        (maxNatSize : Nat)
        (families : List PsKernelSimpleNestedAuxFamily)
        (renames : List (Prod PsKernelName PsKernelName))
        (canonicalParams : List PsKernelOpenBinder)
        (numParams : Nat)
        (oldLevelParams : List PsKernelName)
        (newLevelParams : List PsKernelName)
        (oldRules : List PsKernelRecursorRule)
        (newRules : List PsKernelRecursorRule) =>
        match oldRules with
        | List.nil =>
            match newRules with
            | List.nil =>
                Except.ok ()
            | List.cons _ _ =>
                Except.error
                  "restored nested recursor rule count mismatch"
        | List.cons oldRule oldRest =>
            match newRules with
            | List.nil =>
                Except.error
                  "restored nested recursor rule count mismatch"
            | List.cons newRule newRest =>
                let oldSession :=
                  psKernelMkCheckerSession
                    transformed
                    oldLevelParams
                    safety
                    maxRecDepth
                    maxNatSize;
                let newSession :=
                  psKernelMkCheckerSession
                    finalEnvironment
                    newLevelParams
                    safety
                    maxRecDepth
                    maxNatSize;
                /-
                oldRule comes from the transformed mutual bundle returned by
                psKernelAddSimpleMutualInductive, whose recursor rules have
                already passed full checked validation. Here we only need its
                type as the source side of the restoration comparison; the
                restored newRule below is still fully checked before defeq.
                -/
                match
                    psKernelSessionInfer
                      fuel
                      oldSession
                      oldRule.rhs with
                | Except.error error =>
                    Except.error error
                | Except.ok oldType =>
                    match
                        psKernelSimpleNestedRestoreExpr
                          families
                          renames
                          canonicalParams
                          numParams
                          (Prod.fst oldType) with
                    | Except.error error =>
                        Except.error error
                    | Except.ok expected =>
                        match
                            psKernelSessionCheck
                              fuel
                              newSession
                              newRule.rhs with
                        | Except.error error =>
                            Except.error error
                        | Except.ok got =>
                            match
                                psKernelSessionIsDefEq
                                  fuel
                                  (Prod.snd got)
                                  (Prod.fst got)
                                  expected with
                            | Except.error error =>
                                Except.error error
                            | Except.ok equal =>
                                if Prod.fst equal then
                                  smaller
                                    fuel
                                    transformed
                                    finalEnvironment
                                    safety
                                    maxRecDepth
                                    maxNatSize
                                    families
                                    renames
                                    canonicalParams
                                    numParams
                                    oldLevelParams
                                    newLevelParams
                                    oldRest
                                    newRest
                                else
                                  Except.error
                                    "restored nested recursor rule is not type preserving"

def psKernelSimpleNestedCompareValidatedRuleTypes
    (fuel : Nat)
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth : Nat)
    (maxNatSize : Nat)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (oldLevelParams : List PsKernelName)
    (newLevelParams : List PsKernelName)
    (oldRules : List PsKernelRecursorRule)
    (newRules : List PsKernelRecursorRule) :
    Except String Unit :=
  psKernelSimpleNestedCompareValidatedRuleTypesWithFuel
    (Nat.succ
      (psKernelSimpleNestedRuleListLength
        oldRules))
    fuel
    transformed
    finalEnvironment
    safety
    maxRecDepth
    maxNatSize
    families
    renames
    canonicalParams
    numParams
    oldLevelParams
    newLevelParams
    oldRules
    newRules

def psKernelSimpleNestedCompareRuleTypes
    (fuel : Nat)
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth : Nat)
    (maxNatSize : Nat)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (oldLevelParams : List PsKernelName)
    (newLevelParams : List PsKernelName)
    (oldRules : List PsKernelRecursorRule)
    (newRules : List PsKernelRecursorRule) :
    Except String Unit :=
  let oldSession :=
    psKernelMkCheckerSession
      transformed
      oldLevelParams
      safety
      maxRecDepth
      maxNatSize;
  match
      psKernelSimpleNestedValidateRules
        fuel
        oldSession
        oldRules with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      psKernelSimpleNestedCompareValidatedRuleTypes
        fuel
        transformed
        finalEnvironment
        safety
        maxRecDepth
        maxNatSize
        families
        renames
        canonicalParams
        numParams
        oldLevelParams
        newLevelParams
        oldRules
        newRules

def psKernelSimpleNestedValidateAux
    (fuel : Nat)
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (safety : PsKernelDefinitionSafety)
    (canonicalParams : List PsKernelOpenBinder)
    (maxRecDepth : Nat)
    (maxNatSize : Nat)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (pending : List PsKernelSimpleNestedAuxFamily) :
    Except String Unit :=
  match pending with
  | List.nil =>
      Except.ok ()
  | List.cons family rest =>
      let oldName :=
        psKernelSimpleRecName
          family.auxName;
      match
          psKernelSimpleNestedFindRename
            oldName
            renames with
      | Option.none =>
          Except.error
            "nested auxiliary recursor rename missing during validation"
      | Option.some newName =>
          match
              psKernelEnvironmentFind
                transformed
                oldName with
          | Option.none =>
              Except.error
                "transformed nested auxiliary recursor missing"
          | Option.some oldValue =>
              match oldValue with
              | PsKernelConstantInfo.recInfo oldInfo =>
                  match
                      psKernelEnvironmentFind
                        finalEnvironment
                        newName with
                  | Option.none =>
                      Except.error
                        "restored nested auxiliary recursor missing"
                  | Option.some newValue =>
                      match newValue with
                      | PsKernelConstantInfo.recInfo newInfo =>
                          match
                              psKernelSimpleNestedCompareValidatedRuleTypes
                                fuel
                                transformed
                                finalEnvironment
                                safety
                                maxRecDepth
                                maxNatSize
                                families
                                renames
                                canonicalParams
                                decl.numParams
                                oldInfo.base.levelParams
                                newInfo.base.levelParams
                                oldInfo.rules
                                newInfo.rules with
                          | Except.error error =>
                              Except.error error
                          | Except.ok _ =>
                              let newSession :=
                                psKernelMkCheckerSession
                                  finalEnvironment
                                  newInfo.base.levelParams
                                  safety
                                  maxRecDepth
                                  maxNatSize;
                              match
                                  psKernelSessionCheck
                                    fuel
                                    newSession
                                    newInfo.base.type with
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
                                  | Except.ok _ =>
                                      psKernelSimpleNestedValidateAux
                                        fuel
                                        transformed
                                        finalEnvironment
                                        decl
                                        safety
                                        canonicalParams
                                        maxRecDepth
                                        maxNatSize
                                        families
                                        renames
                                        rest
                      | _ =>
                          Except.error
                            "restored nested auxiliary recursor missing"
              | _ =>
                  Except.error
                    "transformed nested auxiliary recursor missing"

def psKernelSimpleNestedValidateRestored
    (fuel : Nat)
    (transformed : PsKernelEnvironment)
    (finalEnvironment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (canonicalParams : List PsKernelOpenBinder)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String Unit :=
  let safety :=
    if decl.isUnsafe then
      PsKernelDefinitionSafety.unsafeDef
    else
      PsKernelDefinitionSafety.safe;
  match
      psKernelSimpleNestedValidateTemplates
        fuel
        finalEnvironment
        decl.levelParams
        safety
        canonicalParams
        maxRecDepth
        maxNatSize
        families with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psKernelSimpleNestedValidateOriginals
            fuel
            finalEnvironment
            decl
            safety
            maxRecDepth
            maxNatSize
            decl.types with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psKernelSimpleNestedValidateAux
            fuel
            transformed
            finalEnvironment
            decl
            safety
            canonicalParams
            maxRecDepth
            maxNatSize
            families
            renames
            families


