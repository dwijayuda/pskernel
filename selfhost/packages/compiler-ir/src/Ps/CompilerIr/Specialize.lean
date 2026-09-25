import Ps.CompilerIr.Model

inductive PsIrSpecializeKind where
  | structure
  | inductive
  | declaration

structure PsIrSpecializeRequest where
  kind : PsIrSpecializeKind
  name : String
  arguments : List PsVerifiedIrType

inductive PsIrSpecializeError where
  | fuelExhausted
  | unresolvedTypeParameter (name : String)
  | nonGroundType (name : String)
  | typeArgumentArity (name : String)
  | unknownTarget (name : String)
  | unsupportedGenericCall

structure PsIrSpecializeTypeResult where
  type : PsVerifiedIrType
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeTypeListResult where
  types : List PsVerifiedIrType
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeIntrinsicResult where
  operation : PsVerifiedIrIntrinsic
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeExprResult where
  expr : PsVerifiedIrExpr
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeExprListResult where
  expressions : List PsVerifiedIrExpr
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeFieldsResult where
  fields : List (String × PsVerifiedIrExpr)
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeMatchBindingsResult where
  bindings : List PsVerifiedIrMatchBinding
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeAlternativesResult where
  alternatives :
    List
      (String ×
        List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr)
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeStructureFieldsResult where
  fields : List PsVerifiedIrStructureField
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeConstructorFieldsResult where
  fields : List PsVerifiedIrConstructorField
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeConstructorsResult where
  constructors : List PsVerifiedIrConstructor
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeParametersResult where
  parameters : List PsVerifiedIrParameter
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeImportsResult where
  imports : List PsVerifiedIrExternalImport
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeState where
  imports : List PsVerifiedIrExternalImport
  structures : List PsVerifiedIrStructure
  inductives : List PsVerifiedIrInductive
  declarations : List PsVerifiedIrDeclaration
  pending : List PsIrSpecializeRequest
  seen : List String

def psIrSpecializeLookupType :
    List (String × PsVerifiedIrType) ->
    String ->
    Option PsVerifiedIrType
  | [], _ => none
  | entry :: rest, name =>
      if entry.1 == name then
        some entry.2
      else
        psIrSpecializeLookupType rest name

def psIrSpecializeFindStructure :
    List PsVerifiedIrStructure ->
    String ->
    Option PsVerifiedIrStructure
  | [], _ => none
  | entry :: rest, name =>
      if entry.name == name then
        some entry
      else
        psIrSpecializeFindStructure rest name

def psIrSpecializeFindInductive :
    List PsVerifiedIrInductive ->
    String ->
    Option PsVerifiedIrInductive
  | [], _ => none
  | entry :: rest, name =>
      if entry.name == name then
        some entry
      else
        psIrSpecializeFindInductive rest name

def psIrSpecializeFindDeclaration :
    List PsVerifiedIrDeclaration ->
    String ->
    Option PsVerifiedIrDeclaration
  | [], _ => none
  | entry :: rest, name =>
      if entry.name == name then
        some entry
      else
        psIrSpecializeFindDeclaration rest name

def psIrSpecializeJoinKeys :
    List (Option String) -> Option String
  | [] => some ""
  | key :: rest =>
      match key with
      | none => none
      | some head =>
          match psIrSpecializeJoinKeys rest with
          | none => none
          | some tail =>
              if tail == "" then
                some head
              else
                some (head ++ "$" ++ tail)

def psIrSpecializeTypeKeyWithFuel :
    Nat -> PsVerifiedIrType -> Option String
  | 0, _ => none
  | fuel + 1, type =>
      match type with
      | .unknown => none
      | .typeParameter _ => none
      | .primitive primitive =>
          some
            (match primitive with
            | .nat => "Nat"
            | .int => "Int"
            | .uint8 => "U8"
            | .uint16 => "U16"
            | .uint32 => "U32"
            | .uint64 => "U64"
            | .usize => "USize"
            | .int8 => "I8"
            | .int16 => "I16"
            | .int32 => "I32"
            | .int64 => "I64"
            | .isize => "ISize"
            | .float => "F64"
            | .float32 => "F32"
            | .bool => "Bool"
            | .char => "Char"
            | .string => "String"
            | .unit => "Unit")
      | .function parameters result =>
          let parameterKeys :=
            parameters.map
              (psIrSpecializeTypeKeyWithFuel fuel)
          match psIrSpecializeJoinKeys parameterKeys with
          | none => none
          | some parameterKey =>
              match psIrSpecializeTypeKeyWithFuel fuel result with
              | none => none
              | some resultKey =>
                  some
                    ("Fn$" ++ parameterKey ++ "$To$" ++ resultKey)
      | .named name arguments =>
          let argumentKeys :=
            arguments.map
              (psIrSpecializeTypeKeyWithFuel fuel)
          match psIrSpecializeJoinKeys argumentKeys with
          | none => none
          | some "" => some ("N$" ++ name)
          | some keys => some ("N$" ++ name ++ "$" ++ keys)

def psIrSpecializeTypeKey
    (type : PsVerifiedIrType) : Option String :=
  psIrSpecializeTypeKeyWithFuel 64 type

def psIrSpecializeArgumentsKey
    (arguments : List PsVerifiedIrType) : Option String :=
  psIrSpecializeJoinKeys
    (arguments.map psIrSpecializeTypeKey)

def psIrSpecializedName
    (name : String)
    (arguments : List PsVerifiedIrType) : Option String :=
  match psIrSpecializeArgumentsKey arguments with
  | none => none
  | some "" => some name
  | some key => some (name ++ "$spec$" ++ key)

def psIrSpecializeKindPrefix :
    PsIrSpecializeKind -> String
  | .structure => "S:"
  | .inductive => "I:"
  | .declaration => "D:"

def psIrSpecializeRequestKey
    (request : PsIrSpecializeRequest) : Option String :=
  match
      psIrSpecializedName
        request.name
        request.arguments with
  | none => none
  | some name =>
      some
        (psIrSpecializeKindPrefix request.kind ++ name)

def psIrSpecializeSeenContains :
    List String -> String -> Bool
  | [], _ => false
  | entry :: rest, key =>
      if entry == key then
        true
      else
        psIrSpecializeSeenContains rest key

def psIrSpecializeIsGround
    (type : PsVerifiedIrType) : Bool :=
  match psIrSpecializeTypeKey type with
  | none => false
  | some _ => true

def psIrSpecializeAllGround :
    List PsVerifiedIrType -> Bool
  | [] => true
  | type :: rest =>
      psIrSpecializeIsGround type
        && psIrSpecializeAllGround rest

def psIrSpecializeTypeParameterNames :
    List PsVerifiedIrTypeParameter -> List String
  | [] => []
  | parameter :: rest =>
      parameter.name ::
        psIrSpecializeTypeParameterNames rest

def psIrSpecializeMakeSubstitution
    (parameters : List PsVerifiedIrTypeParameter)
    (arguments : List PsVerifiedIrType) :
    Except PsIrSpecializeError
      (List (String × PsVerifiedIrType)) :=
  if parameters.length != arguments.length then
    Except.error
      (PsIrSpecializeError.typeArgumentArity "")
  else if !psIrSpecializeAllGround arguments then
    Except.error
      (PsIrSpecializeError.nonGroundType "")
  else
    Except.ok
      ((psIrSpecializeTypeParameterNames parameters).zip arguments)

def psIrSpecializeGenericTypeRequest
    (module : PsVerifiedIrModule)
    (name : String)
    (arguments : List PsVerifiedIrType) :
    Option PsIrSpecializeRequest :=
  match psIrSpecializeFindStructure module.structures name with
  | some structureInfo =>
      match structureInfo.typeParameters with
      | [] => none
      | _ =>
          some {
            kind := PsIrSpecializeKind.structure
            name := name
            arguments := arguments
          }
  | none =>
      match psIrSpecializeFindInductive module.inductives name with
      | some inductiveInfo =>
          match inductiveInfo.typeParameters with
          | [] => none
          | _ =>
              some {
                kind := PsIrSpecializeKind.inductive
                name := name
                arguments := arguments
              }
      | none => none

def psIrSpecializeRewriteTypeListWith
    (rewrite :
      PsVerifiedIrType ->
      Except PsIrSpecializeError PsIrSpecializeTypeResult) :
    List PsVerifiedIrType ->
    Except PsIrSpecializeError PsIrSpecializeTypeListResult
  | [] =>
      Except.ok {
        types := []
        requests := []
      }
  | type :: rest =>
      match rewrite type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psIrSpecializeRewriteTypeListWith rewrite rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                types := lowered.type :: loweredRest.types
                requests :=
                  lowered.requests ++ loweredRest.requests
              }

def psIrSpecializeRewriteTypeWithFuel
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType)) :
    Nat ->
    PsVerifiedIrType ->
    Except PsIrSpecializeError PsIrSpecializeTypeResult
  | 0, _ =>
      Except.error PsIrSpecializeError.fuelExhausted
  | fuel + 1, type =>
      let rewrite :=
        psIrSpecializeRewriteTypeWithFuel
          module
          substitution
          fuel
      match type with
      | .unknown =>
          Except.error
            (PsIrSpecializeError.nonGroundType "unknown")
      | .typeParameter name =>
          match
              psIrSpecializeLookupType
                substitution
                name with
          | none =>
              Except.error
                (PsIrSpecializeError.unresolvedTypeParameter name)
          | some value =>
              Except.ok {
                type := value
                requests := []
              }
      | .primitive primitive =>
          Except.ok {
            type := PsVerifiedIrType.primitive primitive
            requests := []
          }
      | .function parameters result =>
          match
              psIrSpecializeRewriteTypeListWith
                rewrite
                parameters with
          | Except.error error => Except.error error
          | Except.ok loweredParameters =>
              match rewrite result with
              | Except.error error => Except.error error
              | Except.ok loweredResult =>
                  Except.ok {
                    type :=
                      PsVerifiedIrType.function
                        loweredParameters.types
                        loweredResult.type
                    requests :=
                      loweredParameters.requests
                        ++ loweredResult.requests
                  }
      | .named name arguments =>
          match
              psIrSpecializeRewriteTypeListWith
                rewrite
                arguments with
          | Except.error error => Except.error error
          | Except.ok loweredArguments =>
              match
                  psIrSpecializeGenericTypeRequest
                    module
                    name
                    loweredArguments.types with
              | none =>
                  Except.ok {
                    type :=
                      PsVerifiedIrType.named
                        name
                        loweredArguments.types
                    requests := loweredArguments.requests
                  }
              | some request =>
                  if
                      !psIrSpecializeAllGround
                        loweredArguments.types
                  then
                    Except.error
                      (PsIrSpecializeError.nonGroundType name)
                  else
                    match
                        psIrSpecializedName
                          name
                          loweredArguments.types with
                    | none =>
                        Except.error
                          (PsIrSpecializeError.nonGroundType name)
                    | some specializedName =>
                        Except.ok {
                          type :=
                            PsVerifiedIrType.named
                              specializedName
                              []
                          requests :=
                            loweredArguments.requests ++ [request]
                        }

def psIrSpecializeRewriteType
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (type : PsVerifiedIrType) :
    Except PsIrSpecializeError PsIrSpecializeTypeResult :=
  psIrSpecializeRewriteTypeWithFuel
    module
    substitution
    128
    type

def psIrSpecializeRewriteIntrinsic
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (operation : PsVerifiedIrIntrinsic) :
    Except PsIrSpecializeError PsIrSpecializeIntrinsicResult :=
  let rewriteType :=
    psIrSpecializeRewriteType module substitution
  match operation with
  | .arrayEmptyWithCapacity elementType =>
      match rewriteType elementType with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            operation :=
              PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
                lowered.type
            requests := lowered.requests
          }
  | .arraySize elementType =>
      match rewriteType elementType with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            operation := PsVerifiedIrIntrinsic.arraySize lowered.type
            requests := lowered.requests
          }
  | .arrayPush elementType =>
      match rewriteType elementType with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            operation := PsVerifiedIrIntrinsic.arrayPush lowered.type
            requests := lowered.requests
          }
  | .arrayGet elementType =>
      match rewriteType elementType with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            operation := PsVerifiedIrIntrinsic.arrayGet lowered.type
            requests := lowered.requests
          }
  | .arrayGetD elementType =>
      match rewriteType elementType with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            operation := PsVerifiedIrIntrinsic.arrayGetD lowered.type
            requests := lowered.requests
          }
  | .arraySet elementType =>
      match rewriteType elementType with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            operation := PsVerifiedIrIntrinsic.arraySet lowered.type
            requests := lowered.requests
          }
  | .arraySetIfInBounds elementType =>
      match rewriteType elementType with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            operation :=
              PsVerifiedIrIntrinsic.arraySetIfInBounds
                lowered.type
            requests := lowered.requests
          }
  | .arrayMap sourceType resultType =>
      match rewriteType sourceType with
      | Except.error error => Except.error error
      | Except.ok loweredSource =>
          match rewriteType resultType with
          | Except.error error => Except.error error
          | Except.ok loweredResult =>
              Except.ok {
                operation :=
                  PsVerifiedIrIntrinsic.arrayMap
                    loweredSource.type
                    loweredResult.type
                requests :=
                  loweredSource.requests
                    ++ loweredResult.requests
              }
  | .arrayFoldl elementType accumulatorType =>
      match rewriteType elementType with
      | Except.error error => Except.error error
      | Except.ok loweredElement =>
          match rewriteType accumulatorType with
          | Except.error error => Except.error error
          | Except.ok loweredAccumulator =>
              Except.ok {
                operation :=
                  PsVerifiedIrIntrinsic.arrayFoldl
                    loweredElement.type
                    loweredAccumulator.type
                requests :=
                  loweredElement.requests
                    ++ loweredAccumulator.requests
              }
  | _ =>
      Except.ok {
        operation := operation
        requests := []
      }

def psIrSpecializeRewriteParameters
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType)) :
    List PsVerifiedIrParameter ->
    Except PsIrSpecializeError PsIrSpecializeParametersResult
  | [] =>
      Except.ok {
        parameters := []
        requests := []
      }
  | parameter :: rest =>
      match
          psIrSpecializeRewriteType
            module
            substitution
            parameter.type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match
              psIrSpecializeRewriteParameters
                module
                substitution
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                parameters :=
                  {
                    name := parameter.name
                    type := lowered.type
                  } :: loweredRest.parameters
                requests :=
                  lowered.requests ++ loweredRest.requests
              }

def psIrSpecializeRewriteExprListWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsIrSpecializeError PsIrSpecializeExprResult) :
    List PsVerifiedIrExpr ->
    Except PsIrSpecializeError PsIrSpecializeExprListResult
  | [] =>
      Except.ok {
        expressions := []
        requests := []
      }
  | expression :: rest =>
      match rewrite expression with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psIrSpecializeRewriteExprListWith rewrite rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                expressions :=
                  lowered.expr :: loweredRest.expressions
                requests :=
                  lowered.requests ++ loweredRest.requests
              }

def psIrSpecializeRewriteFieldsWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsIrSpecializeError PsIrSpecializeExprResult) :
    List (String × PsVerifiedIrExpr) ->
    Except PsIrSpecializeError PsIrSpecializeFieldsResult
  | [] =>
      Except.ok {
        fields := []
        requests := []
      }
  | field :: rest =>
      match rewrite field.2 with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psIrSpecializeRewriteFieldsWith rewrite rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                fields :=
                  (field.1, lowered.expr) ::
                    loweredRest.fields
                requests :=
                  lowered.requests ++ loweredRest.requests
              }

def psIrSpecializeRewriteMatchBindings
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType)) :
    List PsVerifiedIrMatchBinding ->
    Except PsIrSpecializeError
      PsIrSpecializeMatchBindingsResult
  | [] =>
      Except.ok {
        bindings := []
        requests := []
      }
  | binding :: rest =>
      match
          psIrSpecializeRewriteType
            module
            substitution
            binding.type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match
              psIrSpecializeRewriteMatchBindings
                module
                substitution
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                bindings :=
                  {
                    field := binding.field
                    name := binding.name
                    type := lowered.type
                  } :: loweredRest.bindings
                requests :=
                  lowered.requests ++ loweredRest.requests
              }

def psIrSpecializeRewriteAlternativesWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsIrSpecializeError PsIrSpecializeExprResult)
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType)) :
    List
      (String ×
        List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr) ->
    Except PsIrSpecializeError
      PsIrSpecializeAlternativesResult
  | [] =>
      Except.ok {
        alternatives := []
        requests := []
      }
  | alternative :: rest =>
      match
          psIrSpecializeRewriteMatchBindings
            module
            substitution
            alternative.2.1 with
      | Except.error error => Except.error error
      | Except.ok loweredBindings =>
          match rewrite alternative.2.2 with
          | Except.error error => Except.error error
          | Except.ok loweredBody =>
              match
                  psIrSpecializeRewriteAlternativesWith
                    rewrite
                    module
                    substitution
                    rest with
              | Except.error error => Except.error error
              | Except.ok loweredRest =>
                  Except.ok {
                    alternatives :=
                      (
                        alternative.1,
                        loweredBindings.bindings,
                        loweredBody.expr
                      ) :: loweredRest.alternatives
                    requests :=
                      loweredBindings.requests
                        ++ loweredBody.requests
                        ++ loweredRest.requests
                  }

def psIrSpecializeRewriteExprWithFuel
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType)) :
    Nat ->
    PsVerifiedIrExpr ->
    Except PsIrSpecializeError PsIrSpecializeExprResult
  | 0, _ =>
      Except.error PsIrSpecializeError.fuelExhausted
  | fuel + 1, expression =>
      let rewrite :=
        psIrSpecializeRewriteExprWithFuel
          module
          substitution
          fuel
      let rewriteType :=
        psIrSpecializeRewriteType
          module
          substitution
      match expression with
      | .literal literal =>
          Except.ok {
            expr := PsVerifiedIrExpr.literal literal
            requests := []
          }
      | .var name =>
          Except.ok {
            expr := PsVerifiedIrExpr.var name
            requests := []
          }
      | .intrinsic operation arguments =>
          match
              psIrSpecializeRewriteIntrinsic
                module
                substitution
                operation with
          | Except.error error => Except.error error
          | Except.ok loweredOperation =>
              match
                  psIrSpecializeRewriteExprListWith
                    rewrite
                    arguments with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok {
                    expr :=
                      PsVerifiedIrExpr.intrinsic
                        loweredOperation.operation
                        lowered.expressions
                    requests :=
                      loweredOperation.requests
                        ++ lowered.requests
                  }
      | .lambda parameters resultType body =>
          match
              psIrSpecializeRewriteParameters
                module
                substitution
                parameters with
          | Except.error error => Except.error error
          | Except.ok loweredParameters =>
              match rewriteType resultType with
              | Except.error error => Except.error error
              | Except.ok loweredResult =>
                  match rewrite body with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      Except.ok {
                        expr :=
                          PsVerifiedIrExpr.lambda
                            loweredParameters.parameters
                            loweredResult.type
                            loweredBody.expr
                        requests :=
                          loweredParameters.requests
                            ++ loweredResult.requests
                            ++ loweredBody.requests
                      }
      | .call fn typeArguments arguments =>
          match rewrite fn with
          | Except.error error => Except.error error
          | Except.ok loweredFn =>
              match
                  psIrSpecializeRewriteTypeListWith
                    rewriteType
                    typeArguments with
              | Except.error error => Except.error error
              | Except.ok loweredTypes =>
                  match
                      psIrSpecializeRewriteExprListWith
                        rewrite
                        arguments with
                  | Except.error error => Except.error error
                  | Except.ok loweredArguments =>
                      match fn with
                      | .var name =>
                          match
                              psIrSpecializeFindDeclaration
                                module.declarations
                                name with
                          | some declaration =>
                              match declaration.typeParameters with
                              | [] =>
                                  Except.ok {
                                    expr :=
                                      PsVerifiedIrExpr.call
                                        loweredFn.expr
                                        loweredTypes.types
                                        loweredArguments.expressions
                                    requests :=
                                      loweredFn.requests
                                        ++ loweredTypes.requests
                                        ++ loweredArguments.requests
                                  }
                              | _ =>
                                  if
                                      declaration.typeParameters.length !=
                                        loweredTypes.types.length
                                  then
                                    Except.error
                                      (PsIrSpecializeError.typeArgumentArity
                                        name)
                                  else if
                                      !psIrSpecializeAllGround
                                        loweredTypes.types
                                  then
                                    Except.error
                                      (PsIrSpecializeError.nonGroundType name)
                                  else
                                    match
                                        psIrSpecializedName
                                          name
                                          loweredTypes.types with
                                    | none =>
                                        Except.error
                                          (PsIrSpecializeError.nonGroundType
                                            name)
                                    | some specializedName =>
                                        let request : PsIrSpecializeRequest := {
                                          kind :=
                                            PsIrSpecializeKind.declaration
                                          name := name
                                          arguments := loweredTypes.types
                                        }
                                        Except.ok {
                                          expr :=
                                            PsVerifiedIrExpr.call
                                              (PsVerifiedIrExpr.var
                                                specializedName)
                                              []
                                              loweredArguments.expressions
                                          requests :=
                                            loweredFn.requests
                                              ++ loweredTypes.requests
                                              ++ loweredArguments.requests
                                              ++ [request]
                                        }
                          | none =>
                              Except.ok {
                                expr :=
                                  PsVerifiedIrExpr.call
                                    loweredFn.expr
                                    loweredTypes.types
                                    loweredArguments.expressions
                                requests :=
                                  loweredFn.requests
                                    ++ loweredTypes.requests
                                    ++ loweredArguments.requests
                              }
                      | _ =>
                          if loweredTypes.types.length == 0 then
                            Except.ok {
                              expr :=
                                PsVerifiedIrExpr.call
                                  loweredFn.expr
                                  []
                                  loweredArguments.expressions
                              requests :=
                                loweredFn.requests
                                  ++ loweredTypes.requests
                                  ++ loweredArguments.requests
                            }
                          else
                            Except.error
                              PsIrSpecializeError.unsupportedGenericCall
      | .letE name type value body =>
          match rewriteType type with
          | Except.error error => Except.error error
          | Except.ok loweredType =>
              match rewrite value with
              | Except.error error => Except.error error
              | Except.ok loweredValue =>
                  match rewrite body with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      Except.ok {
                        expr :=
                          PsVerifiedIrExpr.letE
                            name
                            loweredType.type
                            loweredValue.expr
                            loweredBody.expr
                        requests :=
                          loweredType.requests
                            ++ loweredValue.requests
                            ++ loweredBody.requests
                      }
      | .ifE condition thenBranch elseBranch =>
          match rewrite condition with
          | Except.error error => Except.error error
          | Except.ok loweredCondition =>
              match rewrite thenBranch with
              | Except.error error => Except.error error
              | Except.ok loweredThen =>
                  match rewrite elseBranch with
                  | Except.error error => Except.error error
                  | Except.ok loweredElse =>
                      Except.ok {
                        expr :=
                          PsVerifiedIrExpr.ifE
                            loweredCondition.expr
                            loweredThen.expr
                            loweredElse.expr
                        requests :=
                          loweredCondition.requests
                            ++ loweredThen.requests
                            ++ loweredElse.requests
                      }
      | .record structureName typeArguments fields =>
          match
              psIrSpecializeRewriteTypeListWith
                rewriteType
                typeArguments with
          | Except.error error => Except.error error
          | Except.ok loweredTypes =>
              match
                  psIrSpecializeRewriteFieldsWith
                    rewrite
                    fields with
              | Except.error error => Except.error error
              | Except.ok loweredFields =>
                  match
                      psIrSpecializeFindStructure
                        module.structures
                        structureName with
                  | some structureInfo =>
                      match structureInfo.typeParameters with
                      | [] =>
                          Except.ok {
                            expr :=
                              PsVerifiedIrExpr.record
                                structureName
                                []
                                loweredFields.fields
                            requests :=
                              loweredTypes.requests
                                ++ loweredFields.requests
                          }
                      | _ =>
                          if
                              structureInfo.typeParameters.length !=
                                loweredTypes.types.length
                          then
                            Except.error
                              (PsIrSpecializeError.typeArgumentArity
                                structureName)
                          else
                            match
                                psIrSpecializedName
                                  structureName
                                  loweredTypes.types with
                            | none =>
                                Except.error
                                  (PsIrSpecializeError.nonGroundType
                                    structureName)
                            | some specializedName =>
                                let request : PsIrSpecializeRequest := {
                                  kind := PsIrSpecializeKind.structure
                                  name := structureName
                                  arguments := loweredTypes.types
                                }
                                Except.ok {
                                  expr :=
                                    PsVerifiedIrExpr.record
                                      specializedName
                                      []
                                      loweredFields.fields
                                  requests :=
                                    loweredTypes.requests
                                      ++ loweredFields.requests
                                      ++ [request]
                                }
                  | none =>
                      Except.error
                        (PsIrSpecializeError.unknownTarget structureName)
      | .projection structureName typeArguments target field =>
          match
              psIrSpecializeRewriteTypeListWith
                rewriteType
                typeArguments with
          | Except.error error => Except.error error
          | Except.ok loweredTypes =>
              match rewrite target with
              | Except.error error => Except.error error
              | Except.ok loweredTarget =>
                  match
                      psIrSpecializeFindStructure
                        module.structures
                        structureName with
                  | some structureInfo =>
                      match structureInfo.typeParameters with
                      | [] =>
                          Except.ok {
                            expr :=
                              PsVerifiedIrExpr.projection
                                structureName
                                []
                                loweredTarget.expr
                                field
                            requests :=
                              loweredTypes.requests
                                ++ loweredTarget.requests
                          }
                      | _ =>
                          if
                              structureInfo.typeParameters.length !=
                                loweredTypes.types.length
                          then
                            Except.error
                              (PsIrSpecializeError.typeArgumentArity
                                structureName)
                          else
                            match
                                psIrSpecializedName
                                  structureName
                                  loweredTypes.types with
                            | none =>
                                Except.error
                                  (PsIrSpecializeError.nonGroundType
                                    structureName)
                            | some specializedName =>
                                let request : PsIrSpecializeRequest := {
                                  kind := PsIrSpecializeKind.structure
                                  name := structureName
                                  arguments := loweredTypes.types
                                }
                                Except.ok {
                                  expr :=
                                    PsVerifiedIrExpr.projection
                                      specializedName
                                      []
                                      loweredTarget.expr
                                      field
                                  requests :=
                                    loweredTypes.requests
                                      ++ loweredTarget.requests
                                      ++ [request]
                                }
                  | none =>
                      Except.error
                        (PsIrSpecializeError.unknownTarget structureName)
      | .constructor inductiveName constructorName typeArguments fields =>
          match
              psIrSpecializeRewriteTypeListWith
                rewriteType
                typeArguments with
          | Except.error error => Except.error error
          | Except.ok loweredTypes =>
              match
                  psIrSpecializeRewriteFieldsWith
                    rewrite
                    fields with
              | Except.error error => Except.error error
              | Except.ok loweredFields =>
                  match
                      psIrSpecializeFindInductive
                        module.inductives
                        inductiveName with
                  | some inductiveInfo =>
                      match inductiveInfo.typeParameters with
                      | [] =>
                          Except.ok {
                            expr :=
                              PsVerifiedIrExpr.constructor
                                inductiveName
                                constructorName
                                []
                                loweredFields.fields
                            requests :=
                              loweredTypes.requests
                                ++ loweredFields.requests
                          }
                      | _ =>
                          if
                              inductiveInfo.typeParameters.length !=
                                loweredTypes.types.length
                          then
                            Except.error
                              (PsIrSpecializeError.typeArgumentArity
                                inductiveName)
                          else
                            match
                                psIrSpecializedName
                                  inductiveName
                                  loweredTypes.types with
                            | none =>
                                Except.error
                                  (PsIrSpecializeError.nonGroundType
                                    inductiveName)
                            | some specializedName =>
                                let request : PsIrSpecializeRequest := {
                                  kind := PsIrSpecializeKind.inductive
                                  name := inductiveName
                                  arguments := loweredTypes.types
                                }
                                Except.ok {
                                  expr :=
                                    PsVerifiedIrExpr.constructor
                                      specializedName
                                      constructorName
                                      []
                                      loweredFields.fields
                                  requests :=
                                    loweredTypes.requests
                                      ++ loweredFields.requests
                                      ++ [request]
                                }
                  | none =>
                      Except.error
                        (PsIrSpecializeError.unknownTarget inductiveName)
      | .matchE inductiveName typeArguments scrutinee alternatives =>
          match
              psIrSpecializeRewriteTypeListWith
                rewriteType
                typeArguments with
          | Except.error error => Except.error error
          | Except.ok loweredTypes =>
              match rewrite scrutinee with
              | Except.error error => Except.error error
              | Except.ok loweredScrutinee =>
                  match
                      psIrSpecializeRewriteAlternativesWith
                        rewrite
                        module
                        substitution
                        alternatives with
                  | Except.error error => Except.error error
                  | Except.ok loweredAlternatives =>
                      match
                          psIrSpecializeFindInductive
                            module.inductives
                            inductiveName with
                      | some inductiveInfo =>
                          match inductiveInfo.typeParameters with
                          | [] =>
                              Except.ok {
                                expr :=
                                  PsVerifiedIrExpr.matchE
                                    inductiveName
                                    []
                                    loweredScrutinee.expr
                                    loweredAlternatives.alternatives
                                requests :=
                                  loweredTypes.requests
                                    ++ loweredScrutinee.requests
                                    ++ loweredAlternatives.requests
                              }
                          | _ =>
                              if
                                  inductiveInfo.typeParameters.length !=
                                    loweredTypes.types.length
                              then
                                Except.error
                                  (PsIrSpecializeError.typeArgumentArity
                                    inductiveName)
                              else
                                match
                                    psIrSpecializedName
                                      inductiveName
                                      loweredTypes.types with
                                | none =>
                                    Except.error
                                      (PsIrSpecializeError.nonGroundType
                                        inductiveName)
                                | some specializedName =>
                                    let request : PsIrSpecializeRequest := {
                                      kind := PsIrSpecializeKind.inductive
                                      name := inductiveName
                                      arguments := loweredTypes.types
                                    }
                                    Except.ok {
                                      expr :=
                                        PsVerifiedIrExpr.matchE
                                          specializedName
                                          []
                                          loweredScrutinee.expr
                                          loweredAlternatives.alternatives
                                      requests :=
                                        loweredTypes.requests
                                          ++ loweredScrutinee.requests
                                          ++ loweredAlternatives.requests
                                          ++ [request]
                                    }
                      | none =>
                          Except.error
                            (PsIrSpecializeError.unknownTarget
                              inductiveName)

def psIrSpecializeRewriteExpr
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (expression : PsVerifiedIrExpr) :
    Except PsIrSpecializeError PsIrSpecializeExprResult :=
  psIrSpecializeRewriteExprWithFuel
    module
    substitution
    4096
    expression

def psIrSpecializeRewriteStructureFields
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType)) :
    List PsVerifiedIrStructureField ->
    Except PsIrSpecializeError
      PsIrSpecializeStructureFieldsResult
  | [] =>
      Except.ok {
        fields := []
        requests := []
      }
  | field :: rest =>
      match
          psIrSpecializeRewriteType
            module
            substitution
            field.type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match
              psIrSpecializeRewriteStructureFields
                module
                substitution
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                fields :=
                  {
                    name := field.name
                    type := lowered.type
                  } :: loweredRest.fields
                requests :=
                  lowered.requests ++ loweredRest.requests
              }

def psIrSpecializeRewriteConstructorFields
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType)) :
    List PsVerifiedIrConstructorField ->
    Except PsIrSpecializeError
      PsIrSpecializeConstructorFieldsResult
  | [] =>
      Except.ok {
        fields := []
        requests := []
      }
  | field :: rest =>
      match
          psIrSpecializeRewriteType
            module
            substitution
            field.type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match
              psIrSpecializeRewriteConstructorFields
                module
                substitution
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                fields :=
                  {
                    name := field.name
                    type := lowered.type
                  } :: loweredRest.fields
                requests :=
                  lowered.requests ++ loweredRest.requests
              }

def psIrSpecializeRewriteConstructors
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType)) :
    List PsVerifiedIrConstructor ->
    Except PsIrSpecializeError
      PsIrSpecializeConstructorsResult
  | [] =>
      Except.ok {
        constructors := []
        requests := []
      }
  | constructorInfo :: rest =>
      match
          psIrSpecializeRewriteConstructorFields
            module
            substitution
            constructorInfo.fields with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match
              psIrSpecializeRewriteConstructors
                module
                substitution
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                constructors :=
                  {
                    name := constructorInfo.name
                    fields := lowered.fields
                  } :: loweredRest.constructors
                requests :=
                  lowered.requests ++ loweredRest.requests
              }

def psIrSpecializeRewriteImports
    (module : PsVerifiedIrModule) :
    List PsVerifiedIrExternalImport ->
    Except PsIrSpecializeError PsIrSpecializeImportsResult
  | [] =>
      Except.ok {
        imports := []
        requests := []
      }
  | importInfo :: rest =>
      match
          psIrSpecializeRewriteType
            module
            []
            importInfo.type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psIrSpecializeRewriteImports module rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                imports :=
                  {
                    localName := importInfo.localName
                    source := importInfo.source
                    importedName := importInfo.importedName
                    type := lowered.type
                  } :: loweredRest.imports
                requests :=
                  lowered.requests ++ loweredRest.requests
              }

def psIrSpecializeSeedStructures
    (module : PsVerifiedIrModule) :
    List PsVerifiedIrStructure ->
    Except PsIrSpecializeError
      (List PsVerifiedIrStructure × List PsIrSpecializeRequest)
  | [] => Except.ok ([], [])
  | structureInfo :: rest =>
      match psIrSpecializeSeedStructures module rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest =>
          match structureInfo.typeParameters with
          | _ :: _ => Except.ok loweredRest
          | [] =>
              match
                  psIrSpecializeRewriteStructureFields
                    module
                    []
                    structureInfo.fields with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok
                    (
                      {
                        name := structureInfo.name
                        typeParameters := []
                        fields := lowered.fields
                      } :: loweredRest.1,
                      lowered.requests ++ loweredRest.2
                    )

def psIrSpecializeSeedInductives
    (module : PsVerifiedIrModule) :
    List PsVerifiedIrInductive ->
    Except PsIrSpecializeError
      (List PsVerifiedIrInductive × List PsIrSpecializeRequest)
  | [] => Except.ok ([], [])
  | inductiveInfo :: rest =>
      match psIrSpecializeSeedInductives module rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest =>
          match inductiveInfo.typeParameters with
          | _ :: _ => Except.ok loweredRest
          | [] =>
              match
                  psIrSpecializeRewriteConstructors
                    module
                    []
                    inductiveInfo.constructors with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok
                    (
                      {
                        name := inductiveInfo.name
                        typeParameters := []
                        constructors := lowered.constructors
                      } :: loweredRest.1,
                      lowered.requests ++ loweredRest.2
                    )

def psIrSpecializeSeedDeclarations
    (module : PsVerifiedIrModule) :
    List PsVerifiedIrDeclaration ->
    Except PsIrSpecializeError
      (List PsVerifiedIrDeclaration × List PsIrSpecializeRequest)
  | [] => Except.ok ([], [])
  | declaration :: rest =>
      match psIrSpecializeSeedDeclarations module rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest =>
          match declaration.typeParameters with
          | _ :: _ => Except.ok loweredRest
          | [] =>
              match
                  psIrSpecializeRewriteParameters
                    module
                    []
                    declaration.parameters with
              | Except.error error => Except.error error
              | Except.ok loweredParameters =>
                  match
                      psIrSpecializeRewriteType
                        module
                        []
                        declaration.resultType with
                  | Except.error error => Except.error error
                  | Except.ok loweredResult =>
                      match
                          psIrSpecializeRewriteExpr
                            module
                            []
                            declaration.body with
                      | Except.error error => Except.error error
                      | Except.ok loweredBody =>
                          Except.ok
                            (
                              {
                                name := declaration.name
                                typeParameters := []
                                parameters :=
                                  loweredParameters.parameters
                                resultType := loweredResult.type
                                body := loweredBody.expr
                              } :: loweredRest.1,
                              loweredParameters.requests
                                ++ loweredResult.requests
                                ++ loweredBody.requests
                                ++ loweredRest.2
                            )

def psIrSpecializeAppendRequest
    (state : PsIrSpecializeState)
    (requests : List PsIrSpecializeRequest) :
    PsIrSpecializeState :=
  {
    imports := state.imports
    structures := state.structures
    inductives := state.inductives
    declarations := state.declarations
    pending := state.pending ++ requests
    seen := state.seen
  }

def psIrSpecializeMarkSeen
    (state : PsIrSpecializeState)
    (key : String) :
    PsIrSpecializeState :=
  {
    imports := state.imports
    structures := state.structures
    inductives := state.inductives
    declarations := state.declarations
    pending := state.pending
    seen := key :: state.seen
  }

def psIrSpecializeAddStructure
    (state : PsIrSpecializeState)
    (structureInfo : PsVerifiedIrStructure)
    (requests : List PsIrSpecializeRequest) :
    PsIrSpecializeState :=
  {
    imports := state.imports
    structures := state.structures ++ [structureInfo]
    inductives := state.inductives
    declarations := state.declarations
    pending := state.pending ++ requests
    seen := state.seen
  }

def psIrSpecializeAddInductive
    (state : PsIrSpecializeState)
    (inductiveInfo : PsVerifiedIrInductive)
    (requests : List PsIrSpecializeRequest) :
    PsIrSpecializeState :=
  {
    imports := state.imports
    structures := state.structures
    inductives := state.inductives ++ [inductiveInfo]
    declarations := state.declarations
    pending := state.pending ++ requests
    seen := state.seen
  }

def psIrSpecializeAddDeclaration
    (state : PsIrSpecializeState)
    (declaration : PsVerifiedIrDeclaration)
    (requests : List PsIrSpecializeRequest) :
    PsIrSpecializeState :=
  {
    imports := state.imports
    structures := state.structures
    inductives := state.inductives
    declarations := state.declarations ++ [declaration]
    pending := state.pending ++ requests
    seen := state.seen
  }

def psIrSpecializeProcessStructure
    (module : PsVerifiedIrModule)
    (state : PsIrSpecializeState)
    (request : PsIrSpecializeRequest) :
    Except PsIrSpecializeError PsIrSpecializeState :=
  match
      psIrSpecializeFindStructure
        module.structures
        request.name with
  | none =>
      Except.error
        (PsIrSpecializeError.unknownTarget request.name)
  | some structureInfo =>
      if
          structureInfo.typeParameters.length !=
            request.arguments.length
      then
        Except.error
          (PsIrSpecializeError.typeArgumentArity request.name)
      else
        match
            psIrSpecializeMakeSubstitution
              structureInfo.typeParameters
              request.arguments with
        | Except.error _ =>
            Except.error
              (PsIrSpecializeError.nonGroundType request.name)
        | Except.ok substitution =>
            match
                psIrSpecializedName
                  request.name
                  request.arguments with
            | none =>
                Except.error
                  (PsIrSpecializeError.nonGroundType request.name)
            | some specializedName =>
                match
                    psIrSpecializeRewriteStructureFields
                      module
                      substitution
                      structureInfo.fields with
                | Except.error error => Except.error error
                | Except.ok lowered =>
                    Except.ok
                      (psIrSpecializeAddStructure
                        state
                        {
                          name := specializedName
                          typeParameters := []
                          fields := lowered.fields
                        }
                        lowered.requests)

def psIrSpecializeProcessInductive
    (module : PsVerifiedIrModule)
    (state : PsIrSpecializeState)
    (request : PsIrSpecializeRequest) :
    Except PsIrSpecializeError PsIrSpecializeState :=
  match
      psIrSpecializeFindInductive
        module.inductives
        request.name with
  | none =>
      Except.error
        (PsIrSpecializeError.unknownTarget request.name)
  | some inductiveInfo =>
      if
          inductiveInfo.typeParameters.length !=
            request.arguments.length
      then
        Except.error
          (PsIrSpecializeError.typeArgumentArity request.name)
      else
        match
            psIrSpecializeMakeSubstitution
              inductiveInfo.typeParameters
              request.arguments with
        | Except.error _ =>
            Except.error
              (PsIrSpecializeError.nonGroundType request.name)
        | Except.ok substitution =>
            match
                psIrSpecializedName
                  request.name
                  request.arguments with
            | none =>
                Except.error
                  (PsIrSpecializeError.nonGroundType request.name)
            | some specializedName =>
                match
                    psIrSpecializeRewriteConstructors
                      module
                      substitution
                      inductiveInfo.constructors with
                | Except.error error => Except.error error
                | Except.ok lowered =>
                    Except.ok
                      (psIrSpecializeAddInductive
                        state
                        {
                          name := specializedName
                          typeParameters := []
                          constructors := lowered.constructors
                        }
                        lowered.requests)

def psIrSpecializeProcessDeclaration
    (module : PsVerifiedIrModule)
    (state : PsIrSpecializeState)
    (request : PsIrSpecializeRequest) :
    Except PsIrSpecializeError PsIrSpecializeState :=
  match
      psIrSpecializeFindDeclaration
        module.declarations
        request.name with
  | none =>
      Except.error
        (PsIrSpecializeError.unknownTarget request.name)
  | some declaration =>
      if
          declaration.typeParameters.length !=
            request.arguments.length
      then
        Except.error
          (PsIrSpecializeError.typeArgumentArity request.name)
      else
        match
            psIrSpecializeMakeSubstitution
              declaration.typeParameters
              request.arguments with
        | Except.error _ =>
            Except.error
              (PsIrSpecializeError.nonGroundType request.name)
        | Except.ok substitution =>
            match
                psIrSpecializedName
                  request.name
                  request.arguments with
            | none =>
                Except.error
                  (PsIrSpecializeError.nonGroundType request.name)
            | some specializedName =>
                match
                    psIrSpecializeRewriteParameters
                      module
                      substitution
                      declaration.parameters with
                | Except.error error => Except.error error
                | Except.ok loweredParameters =>
                    match
                        psIrSpecializeRewriteType
                          module
                          substitution
                          declaration.resultType with
                    | Except.error error => Except.error error
                    | Except.ok loweredResult =>
                        match
                            psIrSpecializeRewriteExpr
                              module
                              substitution
                              declaration.body with
                        | Except.error error => Except.error error
                        | Except.ok loweredBody =>
                            Except.ok
                              (psIrSpecializeAddDeclaration
                                state
                                {
                                  name := specializedName
                                  typeParameters := []
                                  parameters :=
                                    loweredParameters.parameters
                                  resultType := loweredResult.type
                                  body := loweredBody.expr
                                }
                                (loweredParameters.requests
                                  ++ loweredResult.requests
                                  ++ loweredBody.requests))

def psIrSpecializeProcessRequest
    (module : PsVerifiedIrModule)
    (state : PsIrSpecializeState)
    (request : PsIrSpecializeRequest) :
    Except PsIrSpecializeError PsIrSpecializeState :=
  match request.kind with
  | .structure =>
      psIrSpecializeProcessStructure module state request
  | .inductive =>
      psIrSpecializeProcessInductive module state request
  | .declaration =>
      psIrSpecializeProcessDeclaration module state request

def psIrSpecializeLoop
    (module : PsVerifiedIrModule) :
    Nat ->
    PsIrSpecializeState ->
    Except PsIrSpecializeError PsIrSpecializeState
  | 0, _ =>
      Except.error PsIrSpecializeError.fuelExhausted
  | fuel + 1, state =>
      match state.pending with
      | [] => Except.ok state
      | request :: rest =>
          match psIrSpecializeRequestKey request with
          | none =>
              Except.error
                (PsIrSpecializeError.nonGroundType request.name)
          | some key =>
              let withoutHead : PsIrSpecializeState := {
                imports := state.imports
                structures := state.structures
                inductives := state.inductives
                declarations := state.declarations
                pending := rest
                seen := state.seen
              }
              if psIrSpecializeSeenContains state.seen key then
                psIrSpecializeLoop module fuel withoutHead
              else
                let marked :=
                  psIrSpecializeMarkSeen withoutHead key
                match
                    psIrSpecializeProcessRequest
                      module
                      marked
                      request with
                | Except.error error => Except.error error
                | Except.ok next =>
                    psIrSpecializeLoop module fuel next

def psIrSpecializeModule
    (module : PsVerifiedIrModule) :
    Except PsIrSpecializeError PsVerifiedIrModule :=
  match psIrSpecializeRewriteImports module module.imports with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match
          psIrSpecializeSeedStructures
            module
            module.structures with
      | Except.error error => Except.error error
      | Except.ok structures =>
          match
              psIrSpecializeSeedInductives
                module
                module.inductives with
          | Except.error error => Except.error error
          | Except.ok inductives =>
              match
                  psIrSpecializeSeedDeclarations
                    module
                    module.declarations with
              | Except.error error => Except.error error
              | Except.ok declarations =>
                  let initial : PsIrSpecializeState := {
                    imports := imports.imports
                    structures := structures.1
                    inductives := inductives.1
                    declarations := declarations.1
                    pending :=
                      imports.requests
                        ++ structures.2
                        ++ inductives.2
                        ++ declarations.2
                    seen := []
                  }
                  match
                      psIrSpecializeLoop
                        module
                        16384
                        initial with
                  | Except.error error => Except.error error
                  | Except.ok final =>
                      Except.ok {
                        imports := final.imports
                        structures := final.structures
                        inductives := final.inductives
                        declarations := final.declarations
                      }
