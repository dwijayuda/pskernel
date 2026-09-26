import Ps.Erasure.Inductive

structure PsPreparedStructureResult where
  scope : PsErasureScope
  ir : PsVerifiedIrStructure

def psPrepareRuntimeStructure
    (environment : PsEnvironment)
    (declarations : List PsDeclaration)
    (scope : PsErasureScope)
    (info : PsInductiveInfo) :
    Except PsErasureError PsPreparedStructureResult :=
  if !info.isStructure || info.numIndices != 0 then
    Except.error PsErasureError.unsupportedRuntimeTerm
  else
    match info.constructors with
    | [constructorName] =>
        match
            psFindConstructorDeclaration
              declarations
              constructorName with
        | none =>
            Except.error
              (PsErasureError.unknownConstant constructorName)
        | some constructorInfo =>
            if constructorInfo.numParams != info.numParams then
              Except.error PsErasureError.unsupportedRuntimeTerm
            else
              let outputName :=
                match
                    psErasureLookupName
                      scope.declarationNames
                      info.name with
                | some known => known
                | none =>
                    psErasureSafeIdentifier
                      (psNameToString info.name)
                      "Structure"
              match
                  psPrepareInductiveParameters
                    environment
                    scope
                    info with
              | Except.error error => Except.error error
              | Except.ok parameters =>
                  match
                      psApplyConstructorParameters
                        environment
                        parameters.scope
                        parameters.values
                        constructorInfo.type with
                  | Except.error error => Except.error error
                  | Except.ok fieldCursor =>
                      match
                          psPrepareConstructorFields
                            environment
                            parameters.scope
                            fieldCursor
                            constructorInfo.numFields with
                      | Except.error error => Except.error error
                      | Except.ok prepared =>
                          let fields :=
                            prepared.fields.map
                              (fun field => {
                                sourceIndex :=
                                  constructorInfo.numParams +
                                    field.sourceIndex
                                projectionIndex := field.sourceIndex
                                name := field.name
                                type := field.type
                              })
                          let runtimeInfo : PsRuntimeStructureInfo := {
                            name := outputName
                            coreName := info.name
                            constructorName := constructorName
                            numParams := info.numParams
                            typeParameters := parameters.typeParameters
                            fields := fields
                          }
                          let nextScope : PsErasureScope := {
                            localContext := scope.localContext
                            runtimeLocals := scope.runtimeLocals
                            typeLocals := scope.typeLocals
                            erasedLocals := scope.erasedLocals
                            declarationNames := scope.declarationNames
                            runtimeConstructors :=
                              scope.runtimeConstructors
                            runtimeRecursors := scope.runtimeRecursors
                            runtimeStructures :=
                              (info.name, runtimeInfo) ::
                                scope.runtimeStructures
                            runtimeStructureConstructors :=
                              (constructorName, runtimeInfo) ::
                                scope.runtimeStructureConstructors
                          }
                          Except.ok {
                            scope := nextScope
                            ir := {
                              name := outputName
                              typeParameters := parameters.typeParameters
                              fields :=
                                fields.map
                                  (fun field => {
                                    name := field.name
                                    type := field.type
                                  })
                            }
                          }
    | _ => Except.error PsErasureError.unsupportedRuntimeTerm

structure PsPreparedStructuresResult where
  scope : PsErasureScope
  ir : List PsVerifiedIrStructure

def psPrepareRuntimeStructures
    (environment : PsEnvironment)
    (declarations : List PsDeclaration) :
    List PsDeclaration ->
    PsErasureScope ->
    List PsVerifiedIrStructure ->
    Except PsErasureError PsPreparedStructuresResult
  | [], scope, structuresRev =>
      Except.ok {
        scope := scope
        ir := structuresRev.reverse
      }
  | declaration :: rest, scope, structuresRev =>
      match declaration with
      | .inductiveDecl info =>
          if info.isStructure then
            match
                psPrepareRuntimeStructure
                  environment
                  declarations
                  scope
                  info with
            | Except.error error => Except.error error
            | Except.ok prepared =>
                psPrepareRuntimeStructures
                  environment
                  declarations
                  rest
                  prepared.scope
                  (prepared.ir :: structuresRev)
          else
            psPrepareRuntimeStructures
              environment
              declarations
              rest
              scope
              structuresRev
      | _ =>
          psPrepareRuntimeStructures
            environment
            declarations
            rest
            scope
            structuresRev
