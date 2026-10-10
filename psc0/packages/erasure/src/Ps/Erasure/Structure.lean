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
  if if info.isStructure then psErasureNatNotEqual info.numIndices 0 else true then
    Except.error PsErasureError.unsupportedRuntimeTerm
  else
    match info.constructors with
    | List.cons constructorName rest =>
        match rest with
        | List.nil =>
            match
                psFindConstructorDeclaration
                  declarations
                  constructorName with
            | Option.none =>
                Except.error
                  (PsErasureError.unknownConstant constructorName)
            | Option.some constructorInfo =>
                if psErasureNatNotEqual constructorInfo.numParams info.numParams then
                  Except.error PsErasureError.unsupportedRuntimeTerm
                else
                  let outputName : String :=
                    match
                        psErasureLookupName
                          scope.declarationNames
                          info.name with
                    | Option.some known => known
                    | Option.none =>
                        psErasureScopedIdentifier scope
                          (psNameToString info.name)
                          "Structure";
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
                              let makeField : PsRuntimeConstructorField -> PsRuntimeStructureField :=
                                fun (field : PsRuntimeConstructorField) =>
                                  PsRuntimeStructureField.mk
                                    (Nat.add constructorInfo.numParams field.sourceIndex)
                                    field.sourceIndex field.name field.type;
                              let fields := psListMap makeField prepared.fields;
                              let makeIrField : PsRuntimeStructureField -> PsVerifiedIrStructureField :=
                                fun (field : PsRuntimeStructureField) =>
                                  PsVerifiedIrStructureField.mk field.name field.type;
                              let runtimeInfo : PsRuntimeStructureInfo := {
                                name := outputName
                                coreName := info.name
                                constructorName := constructorName
                                numParams := info.numParams
                                typeParameters := parameters.typeParameters
                                fields := fields
                              };
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
                                  psErasureIndexInsert PsRuntimeStructureInfo scope.runtimeStructures info.name runtimeInfo
                                runtimeStructureConstructors :=
                                  psErasureIndexInsert PsRuntimeStructureInfo scope.runtimeStructureConstructors constructorName runtimeInfo
                                runtimeExpressions := []
                                currentDefinition := Option.none
                              };
                              Except.ok (PsPreparedStructureResult.mk nextScope
                                (PsVerifiedIrStructure.mk outputName parameters.typeParameters (psListMap makeIrField fields)))
        | List.cons _ _ => Except.error PsErasureError.unsupportedRuntimeTerm
    | _ => Except.error PsErasureError.unsupportedRuntimeTerm

structure PsPreparedStructuresResult where
  scope : PsErasureScope
  ir : List PsVerifiedIrStructure

def psPrepareRuntimeStructures
    (environment : PsEnvironment)
    (declarations : List PsDeclaration)
    (inputs : List PsDeclaration)
    (scope : PsErasureScope)
    (structuresRev : List PsVerifiedIrStructure) :
    Except PsErasureError PsPreparedStructuresResult :=
  match inputs with
  | List.nil =>
      Except.ok (PsPreparedStructuresResult.mk scope (psListReverse structuresRev))
  | List.cons declaration rest =>
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
                  (List.cons prepared.ir structuresRev)
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
