import Ps.KernelSelfHost.Theory.Nested.Restore

/-
Nested-inductive validation and environment admission.

This module validates restored constructor/recursor types and rules against the
flattened templates, installs the final user-visible declarations, and removes
auxiliary implementation details from the resulting environment.
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

def psKernelSimpleNestedValidateRules
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (rules : List PsKernelRecursorRule) :
    Except String Unit :=
  match rules with
  | List.nil =>
      Except.ok ()
  | List.cons rule rest =>
      match
          psKernelSessionCheck
            fuel
            session
            rule.rhs with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psKernelSimpleNestedValidateRules
            fuel
            session
            rest

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

def psKernelSimpleNestedCompareRuleTypesWithFuel
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
        psKernelSimpleNestedCompareRuleTypesWithFuel
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
                match
                    psKernelSessionCheck
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
  psKernelSimpleNestedCompareRuleTypesWithFuel
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
                              psKernelSimpleNestedCompareRuleTypes
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


def psKernelSimpleNestedMakeRenamesWorker
    (families : List PsKernelSimpleNestedAuxFamily) :
    PsKernelName ->
    Nat ->
    List (Prod PsKernelName PsKernelName) :=
  match families with
  | List.nil =>
      fun
        (_mainRec : PsKernelName)
        (_index : Nat) =>
        List.nil
  | List.cons family rest =>
      let smaller :
          PsKernelName ->
          Nat ->
          List (Prod PsKernelName PsKernelName) :=
        psKernelSimpleNestedMakeRenamesWorker
          rest;
      fun
        (mainRec : PsKernelName)
        (index : Nat) =>
        List.cons
          (Prod.mk
            (psKernelSimpleRecName
              family.auxName)
            (psKernelNameAppendIndexAfter
              mainRec
              index))
          (smaller
            mainRec
            (Nat.succ index))

def psKernelSimpleNestedMakeRenames
    (mainRec : PsKernelName)
    (families : List PsKernelSimpleNestedAuxFamily) :
    List (Prod PsKernelName PsKernelName) :=
  psKernelSimpleNestedMakeRenamesWorker
    families
    mainRec
    1

def psKernelSimpleNestedAddWithoutAux
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (types : List PsKernelSimpleMutualTypeDecl)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  match types with
  | List.nil =>
      Except.error
        "empty nested inductive declaration"
  | List.cons first rest =>
      match rest with
      | List.nil =>
          psKernelAddSimpleInductive
            fuel
            environment
            (PsKernelSimpleInductiveDecl.mk
              decl.levelParams
              first.name
              first.type
              first.ctors
              decl.isUnsafe
              decl.numParams)
            maxRecDepth
            maxNatSize
      | List.cons _ _ =>
          psKernelAddSimpleMutualInductive
            fuel
            environment
            (PsKernelSimpleMutualInductiveDecl.mk
              decl.levelParams
              decl.numParams
              types
              decl.isUnsafe)
            maxRecDepth
            maxNatSize

def psKernelAddSimpleNestedInductive
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  match
      psKernelSimpleNestedCheckReserved
        decl with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      let originalNames :=
        psKernelSimpleMutualNames
          decl.types;
      match
          psKernelSimpleCheckUniformOccurrences
            originalNames
            decl.levelParams
            decl.numParams
            (psKernelSimpleMutualCtorTypes
              decl.types) with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match decl.types with
          | List.nil =>
              Except.error
                "empty nested inductive declaration"
          | List.cons first _ =>
              let safety :=
                if decl.isUnsafe then
                  PsKernelDefinitionSafety.unsafeDef
                else
                  PsKernelDefinitionSafety.safe;
              let firstSession :=
                psKernelMkCheckerSession
                  environment
                  decl.levelParams
                  safety
                  maxRecDepth
                  maxNatSize;
              match
                  psKernelSessionCheck
                    fuel
                    firstSession
                    first.type with
              | Except.error error =>
                  Except.error error
              | Except.ok firstTypeType =>
                  match
                      psKernelSessionEnsureSort
                        fuel
                        (Prod.snd firstTypeType)
                        (Prod.fst firstTypeType) with
                  | Except.error error =>
                      Except.error error
                  | Except.ok firstSort =>
                      match
                          psKernelOpenSimpleHeaderParams
                            fuel
                            (Prod.snd firstSort)
                            first.type
                            decl.numParams with
                      | Except.error error =>
                          Except.error error
                      | Except.ok paramsResult =>
                          let canonicalParams :=
                            paramsResult.binders;
                          let initialState :=
                            PsKernelSimpleNestedMapState.mk
                              List.nil
                              1
                              List.nil;
                          match
                              psKernelSimpleNestedProcessQueue
                                fuel
                                environment
                                decl.levelParams
                                originalNames
                                canonicalParams
                                decl.numParams
                                decl.types
                                List.nil
                                initialState with
                          | Except.error error =>
                              Except.error
                                (String.Internal.append
                                  "nested preprocessing: "
                                  error)
                          | Except.ok processed =>
                              match processed.state.aux with
                              | List.nil =>
                                  psKernelSimpleNestedAddWithoutAux
                                    fuel
                                    environment
                                    decl
                                    processed.types
                                    maxRecDepth
                                    maxNatSize
                              | List.cons _ _ =>
                                  match
                                      psKernelAddSimpleMutualInductive
                                        fuel
                                        environment
                                        (PsKernelSimpleMutualInductiveDecl.mk
                                          decl.levelParams
                                          decl.numParams
                                          processed.types
                                          decl.isUnsafe)
                                        maxRecDepth
                                        maxNatSize with
                                  | Except.error error =>
                                      Except.error
                                        (String.Internal.append
                                          "nested transformed admission: "
                                          error)
                                  | Except.ok transformed =>
                                      let mainRec :=
                                        psKernelSimpleRecName
                                          first.name;
                                      let renames :=
                                        psKernelSimpleNestedMakeRenames
                                          mainRec
                                          processed.state.aux;
                                      match
                                          psKernelSimpleNestedAddOriginals
                                            transformed
                                            environment
                                            decl
                                            canonicalParams
                                            processed.state.aux
                                            renames with
                                      | Except.error error =>
                                          Except.error
                                            (String.Internal.append
                                              "nested original restoration: "
                                              error)
                                      | Except.ok restoredOriginals =>
                                          match
                                              psKernelSimpleNestedAddAuxRecursors
                                                transformed
                                                restoredOriginals
                                                originalNames
                                                canonicalParams
                                                decl.numParams
                                                processed.state.aux
                                                renames with
                                          | Except.error error =>
                                              Except.error
                                                (String.Internal.append
                                                  "nested auxiliary restoration: "
                                                  error)
                                          | Except.ok finalEnvironment =>
                                              match
                                                  psKernelSimpleNestedValidateRestored
                                                    fuel
                                                    transformed
                                                    finalEnvironment
                                                    decl
                                                    canonicalParams
                                                    processed.state.aux
                                                    renames
                                                    maxRecDepth
                                                    maxNatSize with
                                              | Except.error error =>
                                                  Except.error
                                                    (String.Internal.append
                                                      "nested restored validation: "
                                                      error)
                                              | Except.ok _ =>
                                                  Except.ok
                                                    finalEnvironment
