import Ps.Erasure.Expr
import Ps.Erasure.Inductive

structure PsOpenedErasedDefinition where
  typeParameters : List PsVerifiedIrTypeParameter
  parameters : List PsVerifiedIrParameter
  resultType : PsVerifiedIrType
  body : PsVerifiedIrExpr

def psErasureAddUniqueString
    (used : List String)
    (base : String) :
    Nat -> String
  | 0 => base ++ "_overflow"
  | attempts + 1 =>
      if used.contains base then
        psErasureAddUniqueString
          used
          (base ++ "_")
          attempts
      else
        base

structure PsErasureNameState where
  used : List String
  entriesRev : List (PsName × String)

def psBuildErasureDeclarationNames :
    List PsDeclaration ->
    PsErasureNameState ->
    PsErasureNameState
  | [], state => state
  | declaration :: rest, state =>
      let sourceName :=
        match declaration with
        | .definitionDecl name _ _ _ => some name
        | .theoremDecl name _ _ _ => some name
        | .inductiveDecl info => some info.name
        | _ => none
      match sourceName with
      | none =>
          psBuildErasureDeclarationNames rest state
      | some name =>
          let raw :=
            psErasureSafeIdentifier
              (psNameToString name)
              "decl"
          let candidate :=
            psErasureAddUniqueString state.used raw 4096
          psBuildErasureDeclarationNames
            rest
            {
              used := candidate :: state.used
              entriesRev := (name, candidate) :: state.entriesRev
            }

def psErasureDeclarationNames
    (declarations : List PsDeclaration) :
    List (PsName × String) :=
  let state :=
    psBuildErasureDeclarationNames
      declarations
      { used := [], entriesRev := [] }
  state.entriesRev.reverse

def psEraseOpenDefinitionWithFuel
    (environment : PsEnvironment) :
    Nat ->
    PsErasureScope ->
    PsExpr ->
    PsExpr ->
    Nat ->
    List PsVerifiedIrTypeParameter ->
    List PsVerifiedIrParameter ->
    Except PsErasureError PsOpenedErasedDefinition
  | 0, _, _, _, _, _, _ =>
      Except.error PsErasureError.fuelExhausted
  | fuel + 1,
    scope,
    currentType,
    currentValue,
    typeIndex,
    typeParametersRev,
    parametersRev =>
      match currentType with
      | .forallE typeName domain typeBody binder =>
          match currentValue with
          | .lam valueName _ valueBody _ =>
              let kind :=
                psErasureClassifyBinder
                  environment
                  scope.localContext
                  domain
              let pushed :=
                psLocalPushBinding
                  scope.localContext
                  typeName
                  domain
                  binder
              let openedVariable := PsExpr.fvar pushed.id
              let nextType :=
                psExprInstantiate1 typeBody openedVariable
              let nextValue :=
                psExprInstantiate1 valueBody openedVariable
              match kind with
              | .type =>
                  let parameterName :=
                    "T" ++ toString typeIndex
                  let nextScope : PsErasureScope := {
                    localContext := pushed.context
                    runtimeLocals := scope.runtimeLocals
                    typeLocals :=
                      (pushed.id, parameterName) ::
                        scope.typeLocals
                    erasedLocals :=
                      pushed.id :: scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors := scope.runtimeConstructors
                    runtimeRecursors := scope.runtimeRecursors
                  }
                  psEraseOpenDefinitionWithFuel
                    environment
                    fuel
                    nextScope
                    nextType
                    nextValue
                    (typeIndex + 1)
                    ({ name := parameterName } ::
                      typeParametersRev)
                    parametersRev
              | .proof =>
                  let nextScope : PsErasureScope := {
                    localContext := pushed.context
                    runtimeLocals := scope.runtimeLocals
                    typeLocals := scope.typeLocals
                    erasedLocals :=
                      pushed.id :: scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors := scope.runtimeConstructors
                    runtimeRecursors := scope.runtimeRecursors
                  }
                  psEraseOpenDefinitionWithFuel
                    environment
                    fuel
                    nextScope
                    nextType
                    nextValue
                    typeIndex
                    typeParametersRev
                    parametersRev
              | .runtime =>
                  let parameterName :=
                    psErasureSafeIdentifier
                      (psNameToString valueName)
                      "arg"
                  match
                      psEraseRuntimeType
                        environment
                        scope
                        domain with
                  | Except.error error => Except.error error
                  | Except.ok parameterType =>
                      let nextScope : PsErasureScope := {
                        localContext := pushed.context
                        runtimeLocals :=
                          (pushed.id, parameterName) ::
                            scope.runtimeLocals
                        typeLocals := scope.typeLocals
                        erasedLocals := scope.erasedLocals
                        declarationNames := scope.declarationNames
                        runtimeConstructors := scope.runtimeConstructors
                        runtimeRecursors := scope.runtimeRecursors
                      }
                      psEraseOpenDefinitionWithFuel
                        environment
                        fuel
                        nextScope
                        nextType
                        nextValue
                        typeIndex
                        typeParametersRev
                        ({
                          name := parameterName
                          type := parameterType
                        } :: parametersRev)
          | _ => Except.error PsErasureError.binderMismatch
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
                  Except.ok {
                    typeParameters := typeParametersRev.reverse
                    parameters := parametersRev.reverse
                    resultType := resultType
                    body := body
                  }

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

def psEraseDefinition
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (name : PsName)
    (type value : PsExpr) :
    Except PsErasureError (Option PsVerifiedIrDeclaration) :=
  if psErasureIsProp environment psLocalEmpty type then
    Except.ok none
  else
    match
        psEraseOpenDefinition
          environment
          scope
          type
          value with
    | Except.error error => Except.error error
    | Except.ok opened =>
        let outputName :=
          match psErasureLookupName
              scope.declarationNames
              name with
          | some known => known
          | none =>
              psErasureSafeIdentifier
                (psNameToString name)
                "decl"
        Except.ok
          (some {
            name := outputName
            typeParameters := opened.typeParameters
            parameters := opened.parameters
            resultType := opened.resultType
            body := opened.body
          })

def psEraseDefinitionsLoop
    (environment : PsEnvironment)
    (scope : PsErasureScope) :
    List PsDeclaration ->
    List PsVerifiedIrDeclaration ->
    Except PsErasureError (List PsVerifiedIrDeclaration)
  | [], declarationsRev =>
      Except.ok declarationsRev.reverse
  | declaration :: rest, declarationsRev =>
      match declaration with
      | .definitionDecl name _ type value =>
          match
              psEraseDefinition
                environment
                scope
                name
                type
                value with
          | Except.error error => Except.error error
          | Except.ok none =>
              psEraseDefinitionsLoop
                environment
                scope
                rest
                declarationsRev
          | Except.ok (some lowered) =>
              psEraseDefinitionsLoop
                environment
                scope
                rest
                (lowered :: declarationsRev)
      | _ =>
          psEraseDefinitionsLoop
            environment
            scope
            rest
            declarationsRev

def psEraseCoreModule
    (environment : PsEnvironment)
    (declarations : List PsDeclaration) :
    Except PsErasureError PsVerifiedIrModule :=
  let names := psErasureDeclarationNames declarations
  let baseScope := psErasureScopeEmpty names
  match
      psPrepareRuntimeInductives
        environment
        declarations
        declarations
        baseScope
        [] with
  | Except.error error => Except.error error
  | Except.ok prepared =>
      match
          psEraseDefinitionsLoop
            environment
            prepared.scope
            declarations
            [] with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            imports := []
            structures := []
            inductives := prepared.ir
            declarations := lowered
          }
