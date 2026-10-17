import Ps.Erasure.Expr
import Ps.Erasure.Inductive
import Ps.Erasure.StructureRecursor

structure PsOpenedErasedDefinition where
  typeParameters : List PsVerifiedIrTypeParameter
  parameters : List PsVerifiedIrParameter
  resultType : PsVerifiedIrType
  body : PsVerifiedIrExpr

def psErasureStringInList (values : List String) : String -> Bool :=
  match values with
  | List.nil => fun (_target : String) => false
  | List.cons value rest =>
      let smaller : String -> Bool := psErasureStringInList rest;
      fun (target : String) =>
        if psStringEq value target then true else smaller target

def psErasureAddUniqueStringWorker
    (used : List String)
    (attempts : Nat)
    (base : String) : String :=
  match attempts with
  | Nat.zero => String.Internal.append base "_overflow"
  | Nat.succ remaining =>
      if psErasureStringInList used base then
        psErasureAddUniqueStringWorker used remaining
          (String.Internal.append base "_")
      else base

def psErasureAddUniqueString (used : List String) (base : String) (attempts : Nat) : String :=
  psErasureAddUniqueStringWorker used attempts base

structure PsErasureNameState where
  used : List String
  entriesRev : List (PsName × String)

def psBuildErasureDeclarationNamesWorker
    (declarations : List PsDeclaration)
    (state : PsErasureNameState) : PsErasureNameState :=
  match declarations with
  | List.nil =>
      state
  | List.cons declaration rest =>
      let sourceName : Option PsName :=
        match declaration with
        | PsDeclaration.definitionDecl name _ _ _ => Option.some name
        | PsDeclaration.opaqueDecl name _ _ _ => Option.some name
        | PsDeclaration.partialDecl name _ _ _ => Option.some name
        | PsDeclaration.theoremDecl name _ _ _ => Option.some name
        | PsDeclaration.inductiveDecl info => Option.some info.name
        | _ => Option.none;
      match sourceName with
      | Option.none => psBuildErasureDeclarationNamesWorker rest state
      | Option.some name =>
          let raw :=
            psErasureSafeIdentifier (psNameToString name) "decl";
          let candidate :=
            psErasureAddUniqueString state.used raw 4096;
          psBuildErasureDeclarationNamesWorker
            rest
            (PsErasureNameState.mk
              (List.cons candidate state.used)
              (List.cons (Prod.mk name candidate) state.entriesRev))

def psBuildErasureDeclarationNames
    (declarations : List PsDeclaration)
    (state : PsErasureNameState) : PsErasureNameState :=
  psBuildErasureDeclarationNamesWorker declarations state

def psErasureReverseDeclarationNamesAcc
    (entries : List (PsName × String)) :
    List (PsName × String) -> List (PsName × String) :=
  match entries with
  | List.nil =>
      fun (acc : List (PsName × String)) => acc
  | List.cons entry rest =>
      let smaller : List (PsName × String) -> List (PsName × String) :=
        psErasureReverseDeclarationNamesAcc rest;
      fun (acc : List (PsName × String)) =>
        smaller (List.cons entry acc)

def psErasureDeclarationNames
    (declarations : List PsDeclaration) :
    List (PsName × String) :=
  let state :=
    psBuildErasureDeclarationNames
      declarations
      (PsErasureNameState.mk List.nil List.nil);
  psErasureReverseDeclarationNamesAcc state.entriesRev List.nil

def psErasureReverseTypeParametersAcc
    (parameters : List PsVerifiedIrTypeParameter) :
    List PsVerifiedIrTypeParameter -> List PsVerifiedIrTypeParameter :=
  match parameters with
  | List.nil =>
      fun (acc : List PsVerifiedIrTypeParameter) => acc
  | List.cons parameter rest =>
      let smaller : List PsVerifiedIrTypeParameter -> List PsVerifiedIrTypeParameter :=
        psErasureReverseTypeParametersAcc rest;
      fun (acc : List PsVerifiedIrTypeParameter) =>
        smaller (List.cons parameter acc)

def psErasureReverseParametersAcc
    (parameters : List PsVerifiedIrParameter) :
    List PsVerifiedIrParameter -> List PsVerifiedIrParameter :=
  match parameters with
  | List.nil =>
      fun (acc : List PsVerifiedIrParameter) => acc
  | List.cons parameter rest =>
      let smaller : List PsVerifiedIrParameter -> List PsVerifiedIrParameter :=
        psErasureReverseParametersAcc rest;
      fun (acc : List PsVerifiedIrParameter) =>
        smaller (List.cons parameter acc)

def psErasureAppendRuntimeParameter
    (parameters : List String)
    (name : String) : List String :=
  match parameters with
  | List.nil => List.cons name List.nil
  | List.cons parameter rest =>
      List.cons parameter (psErasureAppendRuntimeParameter rest name)

def psEraseOpenDefinitionWithFuel
    (environment : PsEnvironment)
    (fuel : Nat) :
    PsErasureScope ->
    PsExpr ->
    PsExpr ->
    Nat ->
    List PsVerifiedIrTypeParameter ->
    List PsVerifiedIrParameter ->
    Except PsErasureError PsOpenedErasedDefinition :=
  match fuel with
  | Nat.zero =>
      fun (_scope : PsErasureScope)
          (_currentType : PsExpr)
          (_currentValue : PsExpr)
          (_typeIndex : Nat)
          (_typeParametersRev : List PsVerifiedIrTypeParameter)
          (_parametersRev : List PsVerifiedIrParameter) =>
        Except.error PsErasureError.fuelExhausted
  | Nat.succ remaining =>
      fun (scope : PsErasureScope)
          (currentType : PsExpr)
          (currentValue : PsExpr)
          (typeIndex : Nat)
          (typeParametersRev : List PsVerifiedIrTypeParameter)
          (parametersRev : List PsVerifiedIrParameter) =>
        let smaller :
            PsErasureScope ->
            PsExpr ->
            PsExpr ->
            Nat ->
            List PsVerifiedIrTypeParameter ->
            List PsVerifiedIrParameter ->
            Except PsErasureError PsOpenedErasedDefinition :=
          psEraseOpenDefinitionWithFuel environment remaining;
        match currentType with
        | PsExpr.forallE typeName domain typeBody binder =>
            match currentValue with
            | PsExpr.lam valueName _ valueBody _ =>
                let kind :=
                  psErasureClassifyBinder
                    environment
                    scope.localContext
                    domain;
                let pushed :=
                  psLocalPushBinding
                    scope.localContext
                    typeName
                    domain
                    binder;
                let openedVariable := PsExpr.fvar pushed.id;
                let scope := { scope with
                  currentDefinition := scope.currentDefinition.map fun current =>
                    { current with coreParametersRev := openedVariable :: current.coreParametersRev } };
                let nextType :=
                  psExprInstantiate1 typeBody openedVariable;
                let nextValue :=
                  psExprInstantiate1 valueBody openedVariable;
                match kind with
                | PsErasedBinderKind.index =>
                    -- This checked binder is a higher-kinded type former or
                    -- predicate. Its value may determine later Core types but
                    -- cannot be reified as a runtime generic or executable slot.
                    let nextScope := { scope with
                      localContext := pushed.context
                      erasedLocals := pushed.id :: scope.erasedLocals }
                    smaller nextScope nextType nextValue typeIndex
                      typeParametersRev parametersRev
                | PsErasedBinderKind.type =>
                    let parameterName :=
                      String.Internal.append "T" (psNatToString typeIndex);
                    let nextCurrentDefinition : Option PsErasureCurrentDefinition :=
                      match scope.currentDefinition with
                      | Option.none => Option.none
                      | Option.some current =>
                          Option.some
                            { current with
                              typeArgumentsRev :=
                                List.cons (PsVerifiedIrType.typeParameter parameterName) current.typeArgumentsRev };
                    let nextScope : PsErasureScope :=
                      { scope with
                        localContext := pushed.context
                        typeLocals := (List.cons (Prod.mk pushed.id parameterName) scope.typeLocals)
                        erasedLocals := (List.cons pushed.id scope.erasedLocals)
                        currentDefinition := nextCurrentDefinition };
                    smaller
                      nextScope
                      nextType
                      nextValue
                      (Nat.succ typeIndex)
                      (List.cons
                        (PsVerifiedIrTypeParameter.mk parameterName)
                        typeParametersRev)
                      parametersRev
                | PsErasedBinderKind.proof =>
                    let (parameter, proofScope) :=
                      psErasureOpenProofSlot scope pushed.context pushed.id
                    let current := proofScope.currentDefinition.map fun current =>
                      { current with
                        runtimeParameters :=
                          psErasureAppendRuntimeParameter current.runtimeParameters parameter.name }
                    smaller { proofScope with currentDefinition := current }
                      nextType nextValue typeIndex typeParametersRev
                      (parameter :: parametersRev)
                | PsErasedBinderKind.runtime =>
                    let parameterName :=
                      psErasureLocalName scope
                        (psNameToString valueName)
                        "arg" pushed.id;
                    match
                        psEraseRuntimeType
                          environment
                          scope
                          domain with
                    | Except.error error => Except.error error
                    | Except.ok parameterType =>
                        let nextCurrentDefinition : Option PsErasureCurrentDefinition :=
                          match scope.currentDefinition with
                          | Option.none => Option.none
                          | Option.some current =>
                              Option.some
                                { current with
                                  runtimeParameters :=
                                    psErasureAppendRuntimeParameter current.runtimeParameters parameterName };
                        let nextScope : PsErasureScope :=
                          { scope with
                            localContext := pushed.context
                            runtimeLocals := (List.cons (Prod.mk pushed.id parameterName) scope.runtimeLocals)
                            currentDefinition := nextCurrentDefinition };
                        smaller
                          nextScope
                          nextType
                          nextValue
                          typeIndex
                          typeParametersRev
                          (List.cons
                            (PsVerifiedIrParameter.mk parameterName parameterType)
                            parametersRev)
            | _ =>
                match
                    psEraseRuntimeType
                      environment
                      scope
                      currentType with
                | Except.error error => Except.error error
                | Except.ok resultType =>
                    match
                        psEraseRuntimeExpr
                          environment
                          scope
                          currentValue with
                    | Except.error error => Except.error error
                    | Except.ok body =>
                        Except.ok
                          (PsOpenedErasedDefinition.mk
                            (psErasureReverseTypeParametersAcc typeParametersRev List.nil)
                            (psErasureReverseParametersAcc parametersRev List.nil)
                            resultType
                            body)
        | _ =>
            match
                psEraseRuntimeType
                  environment
                  scope
                  currentType with
            | Except.error error => Except.error error
            | Except.ok resultType =>
                match
                    psEraseRuntimeExpr
                      environment
                      scope
                      currentValue with
                | Except.error error => Except.error error
                | Except.ok body =>
                    Except.ok
                      (PsOpenedErasedDefinition.mk
                        (psErasureReverseTypeParametersAcc typeParametersRev List.nil)
                        (psErasureReverseParametersAcc parametersRev List.nil)
                        resultType
                        body)

def psEraseOpenDefinition
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (type value : PsExpr) :
    Except PsErasureError PsOpenedErasedDefinition :=
  psEraseOpenDefinitionWithFuel
    environment
    4096
    scope
    type
    value
    0
    []
    []

-- A direct single-definition caller can supply a value before that definition
-- replaces its self axiom in the environment. Seed only this missing entry from
-- the supplied raw type/value; module erasure has already prepared the catalogue.
def psErasureEnsureDefinitionEntry
    (environment : PsEnvironment) (scope : PsErasureScope)
    (name : PsName) (type value : PsExpr) : Except PsErasureError PsErasureScope :=
  match psErasureLookupEntry scope.declarationNames name with
  | Option.some _ => Except.ok scope
  | Option.none =>
      match psErasureAddDeclarationEntry environment name type value
          scope.declarationNames.entries with
      | Except.error error => Except.error error
      | Except.ok entries =>
          let names := { scope.declarationNames with entries := entries };
          Except.ok
            ({ scope with declarationNames := names })

def psEraseDefinition
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (name : PsName)
    (type value : PsExpr) :
    Except PsErasureError (Option PsVerifiedIrDeclaration) :=
  if psErasureIsNonRuntimeDeclaration environment type ||
      (psErasureIsErasedDictionary environment 4096 psLocalEmpty type &&
        !psErasureHasEmptyStructureResult environment scope.runtimeStructures 4096 psLocalEmpty type) ||
      psErasureUnboxedProjection environment scope 4096 psLocalEmpty [] value then
    Except.ok Option.none
  else
    let outputName : String :=
      match psErasureLookupName
          scope.declarationNames
          name with
      | Option.some known => known
      | Option.none =>
          psErasureSafeIdentifier
            (psNameToString name)
            "decl";
    match psErasureEnsureDefinitionEntry environment scope name type value with
    | Except.error error => Except.error error
    | Except.ok entryScope =>
        let definitionScope : PsErasureScope :=
          { entryScope with
            currentDefinition := (Option.some {
              name := outputName, typeArgumentsRev := [], runtimeParameters := []
              coreName := some name }) };
        match psLowerStructureRecursors environment value with
        | Except.error error => Except.error error
        | Except.ok normalizedValue =>
            match
                psEraseOpenDefinition
                  environment
                  definitionScope
                  type
                  normalizedValue with
            | Except.error error => Except.error error
            | Except.ok opened =>
                -- This frozen Standard body is kernel-defeq to default, but
                -- is intentionally nonreturning in generated runtime code.
                let opened :=
                  if psNameEq name (psRootName "outOfBounds") then
                    { opened with body :=
                      PsVerifiedIrExpr.panic "index out of bounds" opened.resultType }
                  else opened
                -- Keep the actual aligned Core entry prefix. A computed function
                -- result is evaluated here and returned as a canonical unary value.
                if psListIsEmpty opened.parameters then
                  if psListIsEmpty opened.typeParameters then
                    Except.ok
                      (Option.some
                        (PsVerifiedIrDeclaration.mk outputName opened.typeParameters
                          opened.parameters opened.resultType opened.body))
                  else
                    match psErasureIgnoredUnitNameWithFuel
                        definitionScope opened.body 4096 0 with
                    | Except.error error => Except.error error
                    | Except.ok unitName =>
                        Except.ok
                          (Option.some
                            (PsVerifiedIrDeclaration.mk outputName opened.typeParameters
                              [PsVerifiedIrParameter.mk unitName
                                (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.unit)]
                              opened.resultType opened.body))
                else
                  Except.ok
                    (Option.some
                      (PsVerifiedIrDeclaration.mk outputName opened.typeParameters
                        opened.parameters opened.resultType opened.body))

def psErasureReverseIrDeclarationsAcc
    (declarations : List PsVerifiedIrDeclaration) :
    List PsVerifiedIrDeclaration -> List PsVerifiedIrDeclaration :=
  match declarations with
  | List.nil =>
      fun (acc : List PsVerifiedIrDeclaration) => acc
  | List.cons declaration rest =>
      let smaller : List PsVerifiedIrDeclaration -> List PsVerifiedIrDeclaration :=
        psErasureReverseIrDeclarationsAcc rest;
      fun (acc : List PsVerifiedIrDeclaration) =>
        smaller (List.cons declaration acc)

def psEraseDefinitionsLoopWorker
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (declarations : List PsDeclaration)
    (declarationsRev : List PsVerifiedIrDeclaration) :
    Except PsErasureError (List PsVerifiedIrDeclaration) :=
  match declarations with
  | List.nil =>
      Except.ok (psErasureReverseIrDeclarationsAcc declarationsRev List.nil)
  | List.cons declaration rest =>
      match declaration with
      | PsDeclaration.definitionDecl name _ type value =>
          match psEraseDefinition environment scope name type value with
          | Except.error error => Except.error (.inDeclaration name error)
          | Except.ok result =>
              match result with
              | Option.none =>
                  psEraseDefinitionsLoopWorker environment scope rest declarationsRev
              | Option.some lowered =>
                  psEraseDefinitionsLoopWorker environment scope rest
                    (List.cons lowered declarationsRev)
      | PsDeclaration.partialDecl name _ type value
      | PsDeclaration.opaqueDecl name _ type value =>
          match psEraseDefinition environment scope name type value with
          | Except.error error => Except.error (.inDeclaration name error)
          | Except.ok result =>
              match result with
              | Option.none =>
                  psEraseDefinitionsLoopWorker environment scope rest declarationsRev
              | Option.some lowered =>
                  psEraseDefinitionsLoopWorker environment scope rest
                    (List.cons lowered declarationsRev)
      | _ =>
          psEraseDefinitionsLoopWorker environment scope rest declarationsRev

def psEraseDefinitionsLoop
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (declarations : List PsDeclaration)
    (declarationsRev : List PsVerifiedIrDeclaration) :
    Except PsErasureError (List PsVerifiedIrDeclaration) :=
  psEraseDefinitionsLoopWorker environment scope declarations declarationsRev

def psErasureAppendDeclarations (declarations : List PsDeclaration) : List PsDeclaration -> List PsDeclaration :=
  match declarations with
  | List.nil => fun (tail : List PsDeclaration) => tail
  | List.cons declaration rest =>
      let smaller : List PsDeclaration -> List PsDeclaration := psErasureAppendDeclarations rest;
      fun (tail : List PsDeclaration) => List.cons declaration (smaller tail)

-- Foreign marshalling cannot reconstruct erased proof obligations. Preserve a
-- conservative algebraic-data classification while the source layout is still
-- available. Indices, value parameters and erased constructor fields require
-- an explicit validating adapter instead of an automatic structural export.
def psErasureForeignData (scope : PsErasureScope) (declarations : List PsDeclaration) :
    List (String × Bool) :=
  declarations.filterMap fun declaration =>
    match declaration with
    | .inductiveDecl info =>
      match psErasureLookupStructure scope.runtimeStructures info.name with
      | some runtime => if runtime.unboxed then none else some (runtime.name,
          info.numIndices == 0 && info.numParams == runtime.typeParameters.length &&
          runtime.numFields == runtime.fields.length)
      | none =>
        match psErasureLookupRecursor scope.runtimeRecursors (psNameAppendStr info.name "rec") with
        | none => none
        | some runtime => some (runtime.name,
            info.numIndices == 0 && info.numParams == runtime.typeParameters.length &&
            runtime.constructors.all (fun c => c.numFields == c.fields.length))
    | _ => none

def psEraseCoreModuleWithRuntimePrelude
    (environment : PsEnvironment)
    (runtimePreludeDeclarations : List PsDeclaration)
    (declarations : List PsDeclaration)
    (internalRuntimeNames : List PsName := [])
    (targetWordSize : Option PsVerifiedIrWordSize := none)
    (recursorWorkerGroups : List PsRecursorWorkerGroup := []) :
    Except PsErasureError PsVerifiedIrModule := do
  (psValidateRecursorWorkerGroups environment recursorWorkerGroups).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  let runtimeDeclarations :=
    psErasureAppendDeclarations runtimePreludeDeclarations declarations;
  -- An ordinary partial-runtime view may replace only its paired opaque body.
  -- Companion workers must still be the exact retained checked definitions,
  -- once each, even when this lower-level entry receives an explicit view.
  for worker in recursorWorkerGroups.flatMap (·.workers) do
    let [actual] := runtimeDeclarations.filter
      (fun declaration => psNameEq (psDeclarationName declaration) worker.name)
      | throw .unsupportedRuntimeTerm
    let some retained := psEnvironmentFind environment worker.name
      | throw .unsupportedRuntimeTerm
    match actual, retained with
    | .definitionDecl _ levels type value, .definitionDecl _ keptLevels keptType keptValue =>
      if !psInductiveGroupNamesEqual levels keptLevels || !psExprAlphaEq type keptType ||
          !psExprAlphaEq value keptValue then throw .unsupportedRuntimeTerm
    | _, _ => throw .unsupportedRuntimeTerm
  let names := psErasureDeclarationNames runtimeDeclarations;
  let baseScopeResult := PsFloatRuntime.reserve { (psErasureScopeEmpty names) with targetWordSize, recursorWorkerGroups }
  match baseScopeResult with
  | Except.error error => Except.error error
  | Except.ok baseScope =>
    match psErasurePrepareDeclarationEntries environment runtimeDeclarations baseScope with
    | Except.error error => Except.error error
    | Except.ok entryScope =>
        match
            psPrepareRuntimeStructures
              environment
              runtimeDeclarations
              runtimeDeclarations
              entryScope
              [] with
        | Except.error error => Except.error error
        | Except.ok preparedStructures =>
            match
                psPrepareRuntimeInductives
                  environment
                  runtimeDeclarations
                  runtimeDeclarations
                  preparedStructures.scope
                  [] with
            | Except.error error => Except.error error
            | Except.ok preparedInductives =>
                match
                    psEraseDefinitionsLoop
                      environment
                      preparedInductives.scope
                      runtimeDeclarations
                      [] with
                | Except.error error => Except.error error
                | Except.ok lowered => do
                    let support ← PsFloatRuntime.declarations preparedInductives.scope
                    -- Follow support dependencies to a fixed point, then emit only
                    -- reachable helpers. Their names were reserved before locals.
                    let used := (List.range support.length).foldl (fun (needed : List PsVerifiedIrDeclaration) _ =>
                      needed ++ support.filter (fun helper =>
                        !needed.any (fun d => d.name == helper.name) &&
                        (lowered ++ needed).any (fun d =>
                          psErasureIrUsesNameWithFuel 4096 d.body helper.name))) []
                    Except.ok {
                      foreignData := psErasureForeignData preparedInductives.scope runtimeDeclarations
                      -- The canonical Standard declaration roster includes
                      -- proof-valued class methods. They have no executable
                      -- representation and therefore no IR export identity.
                      -- Keep only names with actual checked runtime output;
                      -- never weaken the downstream internal-name validator.
                      internalNames := used.map (·.name) ++ (internalRuntimeNames.filterMap
                        (psErasureLookupName preparedInductives.scope.declarationNames)).filter
                        (fun name =>
                          lowered.any (fun entry => entry.name == name) ||
                          preparedStructures.ir.any (fun entry => entry.name == name) ||
                          preparedInductives.ir.any (fun entry => entry.name == name))
                      imports := []
                      structures := preparedStructures.ir
                      inductives := preparedInductives.ir
                      declarations := used ++ lowered
                    }
  
def psEraseCoreModule
    (environment : PsEnvironment)
    (declarations : List PsDeclaration) :
    Except PsErasureError PsVerifiedIrModule :=
  psEraseCoreModuleWithRuntimePrelude
    environment
    List.nil
    declarations

