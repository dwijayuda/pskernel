import Ps.Erasure.Basic

structure PsPreparedInductiveParameters where
  scope : PsErasureScope
  values : List PsExpr
  typeParameters : List PsVerifiedIrTypeParameter

def psPrepareInductiveParametersWithFuel
    (environment : PsEnvironment) :
    Nat ->
    PsErasureScope ->
    PsExpr ->
    Nat ->
    Nat ->
    List PsExpr ->
    List PsVerifiedIrTypeParameter ->
    Except PsErasureError PsPreparedInductiveParameters
  | 0, _, _, _, _, _, _ =>
      Except.error PsErasureError.fuelExhausted
  | _ + 1, scope, _, 0, _, valuesRev, parametersRev =>
      Except.ok {
        scope := scope
        values := valuesRev.reverse
        typeParameters := parametersRev.reverse
      }
  | fuel + 1,
    scope,
    cursor,
    remaining + 1,
    index,
    valuesRev,
    parametersRev =>
      match
          psWhnf
            environment
            psMetaEmpty
            scope.localContext
            cursor with
      | .forallE name domain body binder =>
          match
              psErasureClassifyBinder
                environment
                scope.localContext
                domain with
          | .type =>
              let pushed :=
                psLocalPushBinding
                  scope.localContext
                  name
                  domain
                  binder
              let parameterName := "T" ++ toString index
              let value := PsExpr.fvar pushed.id
              let nextScope : PsErasureScope := {
                localContext := pushed.context
                runtimeLocals := scope.runtimeLocals
                typeLocals :=
                  (pushed.id, parameterName) :: scope.typeLocals
                erasedLocals := pushed.id :: scope.erasedLocals
                declarationNames := scope.declarationNames
                runtimeConstructors := scope.runtimeConstructors
                runtimeRecursors := scope.runtimeRecursors
                runtimeStructures := scope.runtimeStructures
                runtimeStructureConstructors := scope.runtimeStructureConstructors
              }
              psPrepareInductiveParametersWithFuel
                environment
                fuel
                nextScope
                (psExprInstantiate1 body value)
                remaining
                (index + 1)
                (value :: valuesRev)
                ({ name := parameterName } :: parametersRev)
          | _ =>
              Except.error PsErasureError.unsupportedRuntimeTerm
      | _ =>
          Except.error PsErasureError.binderMismatch

def psPrepareInductiveParameters
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (info : PsInductiveInfo) :
    Except PsErasureError PsPreparedInductiveParameters :=
  psPrepareInductiveParametersWithFuel
    environment
    4096
    scope
    info.type
    info.numParams
    0
    []
    []

def psApplyConstructorParameters
    (environment : PsEnvironment)
    (scope : PsErasureScope) :
    List PsExpr ->
    PsExpr ->
    Except PsErasureError PsExpr
  | [], cursor => Except.ok cursor
  | value :: rest, cursor =>
      match
          psWhnf
            environment
            psMetaEmpty
            scope.localContext
            cursor with
      | .forallE _ _ body _ =>
          psApplyConstructorParameters
            environment
            scope
            rest
            (psExprInstantiate1 body value)
      | _ => Except.error PsErasureError.binderMismatch

structure PsPreparedConstructorFields where
  fields : List PsRuntimeConstructorField

def psPrepareConstructorFieldsWithFuel
    (environment : PsEnvironment) :
    Nat ->
    PsErasureScope ->
    PsExpr ->
    Nat ->
    Nat ->
    List PsRuntimeConstructorField ->
    Except PsErasureError PsPreparedConstructorFields
  | 0, _, _, _, _, _ =>
      Except.error PsErasureError.fuelExhausted
  | _ + 1, _, _, 0, _, fieldsRev =>
      Except.ok { fields := fieldsRev.reverse }
  | fuel + 1,
    scope,
    cursor,
    remaining + 1,
    index,
    fieldsRev =>
      match
          psWhnf
            environment
            psMetaEmpty
            scope.localContext
            cursor with
      | .forallE name domain body binder =>
          match
              psErasureClassifyBinder
                environment
                scope.localContext
                domain with
          | .runtime =>
              match psEraseRuntimeType environment scope domain with
              | Except.error error => Except.error error
              | Except.ok fieldType =>
                  let fieldName :=
                    psErasureSafeIdentifier
                      (psNameToString name)
                      ("field" ++ toString index)
                  let pushed :=
                    psLocalPushBinding
                      scope.localContext
                      name
                      domain
                      binder
                  let nextScope : PsErasureScope := {
                    localContext := pushed.context
                    runtimeLocals :=
                      (pushed.id, fieldName) :: scope.runtimeLocals
                    typeLocals := scope.typeLocals
                    erasedLocals := scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors := scope.runtimeConstructors
                    runtimeRecursors := scope.runtimeRecursors
                    runtimeStructures := scope.runtimeStructures
                    runtimeStructureConstructors := scope.runtimeStructureConstructors
                  }
                  psPrepareConstructorFieldsWithFuel
                    environment
                    fuel
                    nextScope
                    (psExprInstantiate1
                      body
                      (PsExpr.fvar pushed.id))
                    remaining
                    (index + 1)
                    ({
                      sourceIndex := index
                      name := fieldName
                      type := fieldType
                    } :: fieldsRev)
          | _ =>
              Except.error PsErasureError.unsupportedRuntimeTerm
      | _ =>
          Except.error PsErasureError.binderMismatch

def psPrepareConstructorFields
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (cursor : PsExpr)
    (fieldCount : Nat) :
    Except PsErasureError PsPreparedConstructorFields :=
  psPrepareConstructorFieldsWithFuel
    environment
    4096
    scope
    cursor
    fieldCount
    0
    []

def psFindConstructorDeclaration :
    List PsDeclaration -> PsName -> Option PsConstructorInfo
  | [], _ => none
  | declaration :: rest, target =>
      match declaration with
      | .constructorDecl info =>
          if psNameEq info.name target then
            some info
          else
            psFindConstructorDeclaration rest target
      | _ =>
          psFindConstructorDeclaration rest target

def psFindRecursorDeclaration :
    List PsDeclaration -> PsName -> Option PsRecursorInfo
  | [], _ => none
  | declaration :: rest, target =>
      match declaration with
      | .recursorDecl info =>
          if psNameEq info.name target then
            some info
          else
            psFindRecursorDeclaration rest target
      | _ =>
          psFindRecursorDeclaration rest target

def psPrepareRuntimeConstructors
    (environment : PsEnvironment)
    (declarations : List PsDeclaration)
    (parameterScope : PsErasureScope)
    (parameterValues : List PsExpr)
    (inductiveName : String) :
    List PsName ->
    List PsRuntimeConstructorInfo ->
    Except PsErasureError (List PsRuntimeConstructorInfo)
  | [], constructorsRev =>
      Except.ok constructorsRev.reverse
  | coreName :: rest, constructorsRev =>
      match psFindConstructorDeclaration declarations coreName with
      | none => Except.error (PsErasureError.unknownConstant coreName)
      | some ctorInfo =>
          match
              psApplyConstructorParameters
                environment
                parameterScope
                parameterValues
                ctorInfo.type with
          | Except.error error => Except.error error
          | Except.ok fieldCursor =>
              match
                  psPrepareConstructorFields
                    environment
                    parameterScope
                    fieldCursor
                    ctorInfo.numFields with
              | Except.error error => Except.error error
              | Except.ok preparedFields =>
                  let fields :=
                    preparedFields.fields.map
                      (fun field => {
                        sourceIndex := ctorInfo.numParams + field.sourceIndex
                        name := field.name
                        type := field.type
                      })
                  let runtimeInfo : PsRuntimeConstructorInfo := {
                    inductiveName := inductiveName
                    name :=
                      psErasureSafeIdentifier
                        (psNameLastComponent coreName)
                        "constructor"
                    coreName := coreName
                    numParams := ctorInfo.numParams
                    fields := fields
                  }
                  psPrepareRuntimeConstructors
                    environment
                    declarations
                    parameterScope
                    parameterValues
                    inductiveName
                    rest
                    (runtimeInfo :: constructorsRev)

structure PsPreparedInductiveResult where
  scope : PsErasureScope
  ir : PsVerifiedIrInductive

def psPrepareRuntimeInductive
    (environment : PsEnvironment)
    (declarations : List PsDeclaration)
    (scope : PsErasureScope)
    (info : PsInductiveInfo) :
    Except PsErasureError PsPreparedInductiveResult :=
  if info.numIndices != 0 then
    Except.error PsErasureError.unsupportedRuntimeTerm
  else
    let outputName :=
      match psErasureLookupName scope.declarationNames info.name with
      | some known => known
      | none =>
          psErasureSafeIdentifier
            (psNameToString info.name)
            "Inductive"
    match
        psPrepareInductiveParameters
          environment
          scope
          info with
    | Except.error error => Except.error error
    | Except.ok parameters =>
        match
            psPrepareRuntimeConstructors
              environment
              declarations
              parameters.scope
              parameters.values
              outputName
              info.constructors
              [] with
        | Except.error error => Except.error error
        | Except.ok constructors =>
            let recursorName :=
              psNameAppendStr info.name "rec"
            match psFindRecursorDeclaration declarations recursorName with
            | none =>
                Except.error
                  (PsErasureError.unknownConstant recursorName)
            | some recInfo =>
                if
                    recInfo.numParams != info.numParams
                      || recInfo.numIndices != 0
                      || recInfo.numMotives != 1
                      || recInfo.numMinors != constructors.length then
                  Except.error PsErasureError.unsupportedRuntimeTerm
                else
                  let runtimeInfo : PsRuntimeInductiveInfo := {
                    name := outputName
                    coreName := info.name
                    recursorName := recursorName
                    numParams := info.numParams
                    typeParameters := parameters.typeParameters
                    constructors := constructors
                  }
                  let constructorEntries :=
                    constructors.map
                      (fun ctorInfo =>
                        (ctorInfo.coreName, ctorInfo))
                  let nextScope : PsErasureScope := {
                    localContext := scope.localContext
                    runtimeLocals := scope.runtimeLocals
                    typeLocals := scope.typeLocals
                    erasedLocals := scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors :=
                      constructorEntries ++ scope.runtimeConstructors
                    runtimeRecursors :=
                      (recursorName, runtimeInfo) ::
                        scope.runtimeRecursors
                  }
                  let irConstructors :=
                    constructors.map
                      (fun ctorInfo => {
                        name := ctorInfo.name
                        fields :=
                          ctorInfo.fields.map
                            (fun field => {
                              name := field.name
                              type := field.type
                            })
                      })
                  Except.ok {
                    scope := nextScope
                    ir := {
                      name := outputName
                      typeParameters := parameters.typeParameters
                      constructors := irConstructors
                    }
                  }

structure PsPreparedInductivesResult where
  scope : PsErasureScope
  ir : List PsVerifiedIrInductive

def psPrepareRuntimeInductives
    (environment : PsEnvironment)
    (declarations : List PsDeclaration) :
    List PsDeclaration ->
    PsErasureScope ->
    List PsVerifiedIrInductive ->
    Except PsErasureError PsPreparedInductivesResult
  | [], scope, irRev =>
      Except.ok {
        scope := scope
        ir := irRev.reverse
      }
  | declaration :: rest, scope, irRev =>
      match declaration with
      | .inductiveDecl info =>
          match
              psPrepareRuntimeInductive
                environment
                declarations
                scope
                info with
          | Except.error error => Except.error error
          | Except.ok prepared =>
              psPrepareRuntimeInductives
                environment
                declarations
                rest
                prepared.scope
                (prepared.ir :: irRev)
      | _ =>
          psPrepareRuntimeInductives
            environment
            declarations
            rest
            scope
            irRev
