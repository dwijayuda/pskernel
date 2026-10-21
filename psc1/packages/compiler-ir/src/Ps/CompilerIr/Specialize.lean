import Ps.CompilerIr.Check
import Ps.Foundation.List
import Ps.Foundation.Name

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
  | inputValidationFailed
  | outputValidationFailed
  | validationBudgetExhausted

structure PsIrSpecializeTypeResult where
  type : PsVerifiedIrType
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeTypeListResult where
  types : List PsVerifiedIrType
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeExprResult where
  expr : PsVerifiedIrExpr
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeExprListResult where
  expressions : List PsVerifiedIrExpr
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeFieldsResult where
  fields : List (Prod String PsVerifiedIrExpr)
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeMatchBindingsResult where
  bindings : List PsVerifiedIrMatchBinding
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeAlternativesResult where
  alternatives : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))
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

def psIrSpecializeConcat3 (first second third : String) : String :=
  String.Internal.append first (String.Internal.append second third)

def psIrSpecializeConcat4 (first second third fourth : String) : String :=
  String.Internal.append first (psIrSpecializeConcat3 second third fourth)

def psIrSpecializeLookupType
    (entries : List (Prod String PsVerifiedIrType)) (name : String) : Option PsVerifiedIrType :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq entry.fst name then Option.some entry.snd
      else psIrSpecializeLookupType rest name

def psIrSpecializeFindStructure
    (entries : List PsVerifiedIrStructure) (name : String) : Option PsVerifiedIrStructure :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq entry.name name then Option.some entry
      else psIrSpecializeFindStructure rest name

def psIrSpecializeFindInductive
    (entries : List PsVerifiedIrInductive) (name : String) : Option PsVerifiedIrInductive :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq entry.name name then Option.some entry
      else psIrSpecializeFindInductive rest name

def psIrSpecializeFindDeclaration
    (entries : List PsVerifiedIrDeclaration) (name : String) : Option PsVerifiedIrDeclaration :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq entry.name name then Option.some entry
      else psIrSpecializeFindDeclaration rest name

def psIrSpecializeJoinKeys
    (_sourceItems : List (Option String)) :
    Option String :=
  match _sourceItems with
  | List.nil => Option.some ""
  | List.cons key rest =>
      match key with
      | Option.none => Option.none
      | Option.some head =>
          match psIrSpecializeJoinKeys rest with
          | Option.none => Option.none
          | Option.some tail =>
              if psStringEq tail "" then
                Option.some head
              else
                Option.some (psIrSpecializeConcat3 head "$" tail)

def psIrSpecializePrimitiveKey (primitive : PsVerifiedIrPrimitiveType) : String :=
  match primitive with
  | PsVerifiedIrPrimitiveType.nat => "Nat"
  | PsVerifiedIrPrimitiveType.int => "Int"
  | PsVerifiedIrPrimitiveType.uint8 => "U8"
  | PsVerifiedIrPrimitiveType.uint16 => "U16"
  | PsVerifiedIrPrimitiveType.uint32 => "U32"
  | PsVerifiedIrPrimitiveType.uint64 => "U64"
  | PsVerifiedIrPrimitiveType.usize => "USize"
  | PsVerifiedIrPrimitiveType.int8 => "I8"
  | PsVerifiedIrPrimitiveType.int16 => "I16"
  | PsVerifiedIrPrimitiveType.int32 => "I32"
  | PsVerifiedIrPrimitiveType.int64 => "I64"
  | PsVerifiedIrPrimitiveType.isize => "ISize"
  | PsVerifiedIrPrimitiveType.float => "F64"
  | PsVerifiedIrPrimitiveType.float32 => "F32"
  | PsVerifiedIrPrimitiveType.bool => "Bool"
  | PsVerifiedIrPrimitiveType.char => "Char"
  | PsVerifiedIrPrimitiveType.string => "String"
  | PsVerifiedIrPrimitiveType.unit => "Unit"

def psIrSpecializeTypeKeyWithFuel (fuel : Nat) : PsVerifiedIrType -> Option String :=
  match fuel with
  | 0 => fun (type : PsVerifiedIrType) => Option.none
  | remaining + 1 =>
      let smaller : PsVerifiedIrType -> Option String := psIrSpecializeTypeKeyWithFuel remaining;
      fun (type : PsVerifiedIrType) =>
        match type with
        | PsVerifiedIrType.unknown => Option.none
        | PsVerifiedIrType.typeParameter _ => Option.none
        | PsVerifiedIrType.primitive primitive => Option.some (psIrSpecializePrimitiveKey primitive)
        | PsVerifiedIrType.function parameters result =>
            let parameterKeys : List (Option String) := psListMap smaller parameters;
            match psIrSpecializeJoinKeys parameterKeys with
            | Option.none => Option.none
            | Option.some parameterKey =>
                match smaller result with
                | Option.none => Option.none
                | Option.some resultKey =>
                    Option.some (psIrSpecializeConcat4 "Fn$" parameterKey "$To$" resultKey)
        | PsVerifiedIrType.named name arguments =>
            let argumentKeys : List (Option String) := psListMap smaller arguments;
            match psIrSpecializeJoinKeys argumentKeys with
            | Option.none => Option.none
            | Option.some keys =>
                if psStringEq keys "" then Option.some (String.Internal.append "N$" name)
                else Option.some (psIrSpecializeConcat4 "N$" name "$" keys)

def psIrSpecializeTypeKey
    (type : PsVerifiedIrType) : Option String :=
  psIrSpecializeTypeKeyWithFuel 64 type

def psIrSpecializeArgumentsKey
    (arguments : List PsVerifiedIrType) : Option String :=
  psIrSpecializeJoinKeys
    (psListMap psIrSpecializeTypeKey arguments)

def psIrSpecializedName
    (name : String)
    (arguments : List PsVerifiedIrType) : Option String :=
  match psIrSpecializeArgumentsKey arguments with
  | Option.none => Option.none
  | Option.some key =>
      if psStringEq key "" then Option.some name
      else Option.some (psIrSpecializeConcat3 name "$spec$" key)

def psIrSpecializeKindPrefix
    (_sourceItems : PsIrSpecializeKind) :
    String :=
  match _sourceItems with
  | PsIrSpecializeKind.structure => "S:"
  | PsIrSpecializeKind.inductive => "I:"
  | PsIrSpecializeKind.declaration => "D:"

def psIrSpecializeRequestKey
    (request : PsIrSpecializeRequest) : Option String :=
  match
      psIrSpecializedName
        request.name
        request.arguments with
  | Option.none => Option.none
  | Option.some name =>
      Option.some
        (String.Internal.append (psIrSpecializeKindPrefix request.kind) name)

def psIrSpecializeSeenContains (entries : List String) (key : String) : Bool :=
  match entries with
  | List.nil => false
  | List.cons entry rest =>
      if psStringEq entry key then true else psIrSpecializeSeenContains rest key

def psIrSpecializeIsGround
    (type : PsVerifiedIrType) : Bool :=
  match psIrSpecializeTypeKey type with
  | Option.none => false
  | Option.some _ => true

def psIrSpecializeAllGround
    (_sourceItems : List PsVerifiedIrType) :
    Bool :=
  match _sourceItems with
  | List.nil => true
  | List.cons type rest =>
      psIrSpecializeIsGround type
        && psIrSpecializeAllGround rest

def psIrSpecializeTypeParameterNames (parameters : List PsVerifiedIrTypeParameter) : List String :=
  psListMap (fun (parameter : PsVerifiedIrTypeParameter) => parameter.name) parameters

def psIrSpecializeMakeSubstitution
    (parameters : List PsVerifiedIrTypeParameter)
    (arguments : List PsVerifiedIrType) :
    Except PsIrSpecializeError
      (List (Prod String PsVerifiedIrType)) :=
  if !(Nat.beq (psListLength parameters) (psListLength arguments)) then
    Except.error
      (PsIrSpecializeError.typeArgumentArity "")
  else if !psIrSpecializeAllGround arguments then
    Except.error
      (PsIrSpecializeError.nonGroundType "")
  else
    Except.ok
      (psListZip (psIrSpecializeTypeParameterNames parameters) arguments)

def psIrSpecializeGenericTypeRequest
    (module : PsVerifiedIrModule)
    (name : String)
    (arguments : List PsVerifiedIrType) :
    Option PsIrSpecializeRequest :=
  match psIrSpecializeFindStructure module.structures name with
  | Option.some structureInfo =>
      match structureInfo.typeParameters with
      | List.nil => Option.none
      | _ =>
          Option.some {
            kind := PsIrSpecializeKind.structure
            name := name
            arguments := arguments
          }
  | Option.none =>
      match psIrSpecializeFindInductive module.inductives name with
      | Option.some inductiveInfo =>
          match inductiveInfo.typeParameters with
          | List.nil => Option.none
          | _ =>
              Option.some {
                kind := PsIrSpecializeKind.inductive
                name := name
                arguments := arguments
              }
      | Option.none => Option.none

def psIrSpecializeRewriteTypeListWith
    (rewrite :
      PsVerifiedIrType ->
      Except PsIrSpecializeError PsIrSpecializeTypeResult)
    (_sourceItems : List PsVerifiedIrType) :
    Except PsIrSpecializeError PsIrSpecializeTypeListResult :=
  match _sourceItems with
  | List.nil =>
      Except.ok {
        types := []
        requests := []
      }
  | List.cons type rest =>
      match rewrite type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psIrSpecializeRewriteTypeListWith rewrite rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                types := List.cons lowered.type loweredRest.types
                requests :=
                  (psListAppend lowered.requests loweredRest.requests)
              }

def psIrSpecializeRewriteTypeWithFuel
    (module : PsVerifiedIrModule)
    (substitution : List (Prod String PsVerifiedIrType))
    (depth : Nat) :
    PsVerifiedIrType -> Except PsIrSpecializeError PsIrSpecializeTypeResult :=
  match depth with
  | 0 => fun (type : PsVerifiedIrType) => Except.error PsIrSpecializeError.fuelExhausted
  | fuel + 1 =>
      fun (type : PsVerifiedIrType) =>
        let rewrite : PsVerifiedIrType -> Except PsIrSpecializeError PsIrSpecializeTypeResult :=
          psIrSpecializeRewriteTypeWithFuel
            module
            substitution
            fuel;
        match type with
        | PsVerifiedIrType.unknown =>
            Except.error
              (PsIrSpecializeError.nonGroundType "unknown")
        | PsVerifiedIrType.typeParameter name =>
            match
                psIrSpecializeLookupType
                  substitution
                  name with
            | Option.none =>
                Except.error
                  (PsIrSpecializeError.unresolvedTypeParameter name)
            | Option.some value =>
                Except.ok {
                  type := value
                  requests := []
                }
        | PsVerifiedIrType.primitive primitive =>
            Except.ok {
              type := PsVerifiedIrType.primitive primitive
              requests := []
            }
        | PsVerifiedIrType.function parameters result =>
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
                        (psListAppend loweredParameters.requests loweredResult.requests)
                    }
        | PsVerifiedIrType.named name arguments =>
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
                | Option.none =>
                    Except.ok {
                      type :=
                        PsVerifiedIrType.named
                          name
                          loweredArguments.types
                      requests := loweredArguments.requests
                    }
                | Option.some request =>
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
                      | Option.none =>
                          Except.error
                            (PsIrSpecializeError.nonGroundType name)
                      | Option.some specializedName =>
                          Except.ok {
                            type :=
                              PsVerifiedIrType.named
                                specializedName
                                []
                            requests :=
                              (psListAppend loweredArguments.requests [request])
                          }

def psIrSpecializeRewriteType
    (module : PsVerifiedIrModule)
    (substitution : List (Prod String PsVerifiedIrType))
    (type : PsVerifiedIrType) :
    Except PsIrSpecializeError PsIrSpecializeTypeResult :=
  psIrSpecializeRewriteTypeWithFuel
    module
    substitution
    128
    type

def psIrSpecializeRewriteParameters
    (module : PsVerifiedIrModule)
    (substitution : List (Prod String PsVerifiedIrType))
    (_sourceItems : List PsVerifiedIrParameter) :
    Except PsIrSpecializeError PsIrSpecializeParametersResult :=
  match _sourceItems with
  | List.nil =>
      Except.ok {
        parameters := []
        requests := []
      }
  | List.cons parameter rest =>
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
                  List.cons (PsVerifiedIrParameter.mk parameter.name lowered.type) loweredRest.parameters
                requests :=
                  (psListAppend lowered.requests loweredRest.requests)
              }

def psIrSpecializeRewriteExprListWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsIrSpecializeError PsIrSpecializeExprResult)
    (_sourceItems : List PsVerifiedIrExpr) :
    Except PsIrSpecializeError PsIrSpecializeExprListResult :=
  match _sourceItems with
  | List.nil =>
      Except.ok {
        expressions := []
        requests := []
      }
  | List.cons expression rest =>
      match rewrite expression with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psIrSpecializeRewriteExprListWith rewrite rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                expressions :=
                  List.cons lowered.expr loweredRest.expressions
                requests :=
                  (psListAppend lowered.requests loweredRest.requests)
              }

def psIrSpecializeRewriteFieldsWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsIrSpecializeError PsIrSpecializeExprResult)
    (_sourceItems : List (Prod String PsVerifiedIrExpr)) :
    Except PsIrSpecializeError PsIrSpecializeFieldsResult :=
  match _sourceItems with
  | List.nil =>
      Except.ok {
        fields := []
        requests := []
      }
  | List.cons field rest =>
      match rewrite field.snd with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psIrSpecializeRewriteFieldsWith rewrite rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                fields :=
                  List.cons (Prod.mk field.fst lowered.expr) loweredRest.fields
                requests :=
                  (psListAppend lowered.requests loweredRest.requests)
              }

def psIrSpecializeRewriteMatchBindings
    (module : PsVerifiedIrModule)
    (substitution : List (Prod String PsVerifiedIrType))
    (_sourceItems : List PsVerifiedIrMatchBinding) :
    Except PsIrSpecializeError
      PsIrSpecializeMatchBindingsResult :=
  match _sourceItems with
  | List.nil =>
      Except.ok {
        bindings := []
        requests := []
      }
  | List.cons binding rest =>
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
                  List.cons (PsVerifiedIrMatchBinding.mk binding.field binding.name lowered.type) loweredRest.bindings
                requests :=
                  (psListAppend lowered.requests loweredRest.requests)
              }

def psIrSpecializeRewriteAlternativesWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsIrSpecializeError PsIrSpecializeExprResult)
    (module : PsVerifiedIrModule)
    (substitution : List (Prod String PsVerifiedIrType))
    (_sourceItems : List
      (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) :
    Except PsIrSpecializeError
      PsIrSpecializeAlternativesResult :=
  match _sourceItems with
  | List.nil =>
      Except.ok {
        alternatives := []
        requests := []
      }
  | List.cons alternative rest =>
      match
          psIrSpecializeRewriteMatchBindings
            module
            substitution
            alternative.snd.fst with
      | Except.error error => Except.error error
      | Except.ok loweredBindings =>
          match rewrite alternative.snd.snd with
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
                      List.cons (Prod.mk alternative.fst (Prod.mk loweredBindings.bindings loweredBody.expr)) loweredRest.alternatives
                    requests :=
                      (psListAppend loweredBindings.requests (psListAppend loweredBody.requests loweredRest.requests))
                  }

def psIrSpecializeRewriteExprWithFuel
    (module : PsVerifiedIrModule)
    (substitution : List (Prod String PsVerifiedIrType))
    (depth : Nat) :
    PsVerifiedIrExpr -> Except PsIrSpecializeError PsIrSpecializeExprResult :=
  match depth with
  | 0 => fun (expression : PsVerifiedIrExpr) => Except.error PsIrSpecializeError.fuelExhausted
  | fuel + 1 =>
      fun (expression : PsVerifiedIrExpr) =>
        let rewrite : PsVerifiedIrExpr -> Except PsIrSpecializeError PsIrSpecializeExprResult :=
          psIrSpecializeRewriteExprWithFuel
            module
            substitution
            fuel;
        let rewriteType :=
          psIrSpecializeRewriteType
            module
            substitution;
        match expression with
        | PsVerifiedIrExpr.literal literal =>
            Except.ok {
              expr := PsVerifiedIrExpr.literal literal
              requests := []
            }
        | PsVerifiedIrExpr.var name =>
            Except.ok {
              expr := PsVerifiedIrExpr.var name
              requests := []
            }
        | PsVerifiedIrExpr.intrinsic operation typeArguments arguments =>
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
                | Except.ok lowered =>
                    Except.ok {
                      expr :=
                        PsVerifiedIrExpr.intrinsic
                          operation
                          loweredTypes.types
                          lowered.expressions
                      requests :=
                        (psListAppend loweredTypes.requests lowered.requests)
                    }
        | PsVerifiedIrExpr.lambda parameters resultType body =>
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
                            (psListAppend loweredParameters.requests (psListAppend loweredResult.requests loweredBody.requests))
                        }
        | PsVerifiedIrExpr.call fn typeArguments arguments =>
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
                        | PsVerifiedIrExpr.var name =>
                            match
                                psIrSpecializeFindDeclaration
                                  module.declarations
                                  name with
                            | Option.some declaration =>
                                match declaration.typeParameters with
                                | List.nil =>
                                    Except.ok {
                                      expr :=
                                        PsVerifiedIrExpr.call
                                          loweredFn.expr
                                          loweredTypes.types
                                          loweredArguments.expressions
                                      requests :=
                                        (psListAppend loweredFn.requests (psListAppend loweredTypes.requests loweredArguments.requests))
                                    }
                                | _ =>
                                    if
                                        !(Nat.beq (psListLength declaration.typeParameters) (psListLength loweredTypes.types))
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
                                      | Option.none =>
                                          Except.error
                                            (PsIrSpecializeError.nonGroundType
                                              name)
                                      | Option.some specializedName =>
                                          let request : PsIrSpecializeRequest := {
                                            kind :=
                                              PsIrSpecializeKind.declaration
                                            name := name
                                            arguments := loweredTypes.types
                                          };
                                          Except.ok {
                                            expr :=
                                              PsVerifiedIrExpr.call
                                                (PsVerifiedIrExpr.var
                                                  specializedName)
                                                []
                                                loweredArguments.expressions
                                            requests :=
                                              (psListAppend loweredFn.requests (psListAppend loweredTypes.requests (psListAppend loweredArguments.requests [request])))
                                          }
                            | Option.none =>
                                Except.ok {
                                  expr :=
                                    PsVerifiedIrExpr.call
                                      loweredFn.expr
                                      loweredTypes.types
                                      loweredArguments.expressions
                                  requests :=
                                    (psListAppend loweredFn.requests (psListAppend loweredTypes.requests loweredArguments.requests))
                                }
                        | _ =>
                            if Nat.beq (psListLength loweredTypes.types) 0 then
                              Except.ok {
                                expr :=
                                  PsVerifiedIrExpr.call
                                    loweredFn.expr
                                    []
                                    loweredArguments.expressions
                                requests :=
                                  (psListAppend loweredFn.requests (psListAppend loweredTypes.requests loweredArguments.requests))
                              }
                            else
                              Except.error
                                PsIrSpecializeError.unsupportedGenericCall
        | PsVerifiedIrExpr.letE name type value body =>
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
                            (psListAppend loweredType.requests (psListAppend loweredValue.requests loweredBody.requests))
                        }
        | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
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
                            (psListAppend loweredCondition.requests (psListAppend loweredThen.requests loweredElse.requests))
                        }
        | PsVerifiedIrExpr.record structureName typeArguments fields =>
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
                    | Option.some structureInfo =>
                        match structureInfo.typeParameters with
                        | List.nil =>
                            Except.ok {
                              expr :=
                                PsVerifiedIrExpr.record
                                  structureName
                                  []
                                  loweredFields.fields
                              requests :=
                                (psListAppend loweredTypes.requests loweredFields.requests)
                            }
                        | _ =>
                            if
                                !(Nat.beq (psListLength structureInfo.typeParameters) (psListLength loweredTypes.types))
                            then
                              Except.error
                                (PsIrSpecializeError.typeArgumentArity
                                  structureName)
                            else
                              match
                                  psIrSpecializedName
                                    structureName
                                    loweredTypes.types with
                              | Option.none =>
                                  Except.error
                                    (PsIrSpecializeError.nonGroundType
                                      structureName)
                              | Option.some specializedName =>
                                  let request : PsIrSpecializeRequest := {
                                    kind := PsIrSpecializeKind.structure
                                    name := structureName
                                    arguments := loweredTypes.types
                                  };
                                  Except.ok {
                                    expr :=
                                      PsVerifiedIrExpr.record
                                        specializedName
                                        []
                                        loweredFields.fields
                                    requests :=
                                      (psListAppend loweredTypes.requests (psListAppend loweredFields.requests [request]))
                                  }
                    | Option.none =>
                        Except.error
                          (PsIrSpecializeError.unknownTarget structureName)
        | PsVerifiedIrExpr.projection structureName typeArguments target field =>
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
                    | Option.some structureInfo =>
                        match structureInfo.typeParameters with
                        | List.nil =>
                            Except.ok {
                              expr :=
                                PsVerifiedIrExpr.projection
                                  structureName
                                  []
                                  loweredTarget.expr
                                  field
                              requests :=
                                (psListAppend loweredTypes.requests loweredTarget.requests)
                            }
                        | _ =>
                            if
                                !(Nat.beq (psListLength structureInfo.typeParameters) (psListLength loweredTypes.types))
                            then
                              Except.error
                                (PsIrSpecializeError.typeArgumentArity
                                  structureName)
                            else
                              match
                                  psIrSpecializedName
                                    structureName
                                    loweredTypes.types with
                              | Option.none =>
                                  Except.error
                                    (PsIrSpecializeError.nonGroundType
                                      structureName)
                              | Option.some specializedName =>
                                  let request : PsIrSpecializeRequest := {
                                    kind := PsIrSpecializeKind.structure
                                    name := structureName
                                    arguments := loweredTypes.types
                                  };
                                  Except.ok {
                                    expr :=
                                      PsVerifiedIrExpr.projection
                                        specializedName
                                        []
                                        loweredTarget.expr
                                        field
                                    requests :=
                                      (psListAppend loweredTypes.requests (psListAppend loweredTarget.requests [request]))
                                  }
                    | Option.none =>
                        Except.error
                          (PsIrSpecializeError.unknownTarget structureName)
        | PsVerifiedIrExpr.constructor inductiveName constructorName typeArguments fields =>
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
                    | Option.some inductiveInfo =>
                        match inductiveInfo.typeParameters with
                        | List.nil =>
                            Except.ok {
                              expr :=
                                PsVerifiedIrExpr.constructor
                                  inductiveName
                                  constructorName
                                  []
                                  loweredFields.fields
                              requests :=
                                (psListAppend loweredTypes.requests loweredFields.requests)
                            }
                        | _ =>
                            if
                                !(Nat.beq (psListLength inductiveInfo.typeParameters) (psListLength loweredTypes.types))
                            then
                              Except.error
                                (PsIrSpecializeError.typeArgumentArity
                                  inductiveName)
                            else
                              match
                                  psIrSpecializedName
                                    inductiveName
                                    loweredTypes.types with
                              | Option.none =>
                                  Except.error
                                    (PsIrSpecializeError.nonGroundType
                                      inductiveName)
                              | Option.some specializedName =>
                                  let request : PsIrSpecializeRequest := {
                                    kind := PsIrSpecializeKind.inductive
                                    name := inductiveName
                                    arguments := loweredTypes.types
                                  };
                                  Except.ok {
                                    expr :=
                                      PsVerifiedIrExpr.constructor
                                        specializedName
                                        constructorName
                                        []
                                        loweredFields.fields
                                    requests :=
                                      (psListAppend loweredTypes.requests (psListAppend loweredFields.requests [request]))
                                  }
                    | Option.none =>
                        Except.error
                          (PsIrSpecializeError.unknownTarget inductiveName)
        | PsVerifiedIrExpr.matchE inductiveName typeArguments scrutinee alternatives =>
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
                        | Option.some inductiveInfo =>
                            match inductiveInfo.typeParameters with
                            | List.nil =>
                                Except.ok {
                                  expr :=
                                    PsVerifiedIrExpr.matchE
                                      inductiveName
                                      []
                                      loweredScrutinee.expr
                                      loweredAlternatives.alternatives
                                  requests :=
                                    (psListAppend loweredTypes.requests (psListAppend loweredScrutinee.requests loweredAlternatives.requests))
                                }
                            | _ =>
                                if
                                    !(Nat.beq (psListLength inductiveInfo.typeParameters) (psListLength loweredTypes.types))
                                then
                                  Except.error
                                    (PsIrSpecializeError.typeArgumentArity
                                      inductiveName)
                                else
                                  match
                                      psIrSpecializedName
                                        inductiveName
                                        loweredTypes.types with
                                  | Option.none =>
                                      Except.error
                                        (PsIrSpecializeError.nonGroundType
                                          inductiveName)
                                  | Option.some specializedName =>
                                      let request : PsIrSpecializeRequest := {
                                        kind := PsIrSpecializeKind.inductive
                                        name := inductiveName
                                        arguments := loweredTypes.types
                                      };
                                      Except.ok {
                                        expr :=
                                          PsVerifiedIrExpr.matchE
                                            specializedName
                                            []
                                            loweredScrutinee.expr
                                            loweredAlternatives.alternatives
                                        requests :=
                                          (psListAppend loweredTypes.requests (psListAppend loweredScrutinee.requests (psListAppend loweredAlternatives.requests [request])))
                                      }
                        | Option.none =>
                            Except.error
                              (PsIrSpecializeError.unknownTarget
                                inductiveName)

def psIrSpecializeRewriteExpr
    (module : PsVerifiedIrModule)
    (substitution : List (Prod String PsVerifiedIrType))
    (expression : PsVerifiedIrExpr) :
    Except PsIrSpecializeError PsIrSpecializeExprResult :=
  psIrSpecializeRewriteExprWithFuel
    module
    substitution
    4096
    expression

def psIrSpecializeRewriteStructureFields
    (module : PsVerifiedIrModule)
    (substitution : List (Prod String PsVerifiedIrType))
    (_sourceItems : List PsVerifiedIrStructureField) :
    Except PsIrSpecializeError
      PsIrSpecializeStructureFieldsResult :=
  match _sourceItems with
  | List.nil =>
      Except.ok {
        fields := []
        requests := []
      }
  | List.cons field rest =>
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
                  List.cons (PsVerifiedIrStructureField.mk field.name lowered.type) loweredRest.fields
                requests :=
                  (psListAppend lowered.requests loweredRest.requests)
              }

def psIrSpecializeRewriteConstructorFields
    (module : PsVerifiedIrModule)
    (substitution : List (Prod String PsVerifiedIrType))
    (_sourceItems : List PsVerifiedIrConstructorField) :
    Except PsIrSpecializeError
      PsIrSpecializeConstructorFieldsResult :=
  match _sourceItems with
  | List.nil =>
      Except.ok {
        fields := []
        requests := []
      }
  | List.cons field rest =>
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
                  List.cons (PsVerifiedIrConstructorField.mk field.name lowered.type) loweredRest.fields
                requests :=
                  (psListAppend lowered.requests loweredRest.requests)
              }

def psIrSpecializeRewriteConstructors
    (module : PsVerifiedIrModule)
    (substitution : List (Prod String PsVerifiedIrType))
    (_sourceItems : List PsVerifiedIrConstructor) :
    Except PsIrSpecializeError
      PsIrSpecializeConstructorsResult :=
  match _sourceItems with
  | List.nil =>
      Except.ok {
        constructors := []
        requests := []
      }
  | List.cons constructorInfo rest =>
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
                  List.cons (PsVerifiedIrConstructor.mk constructorInfo.name lowered.fields) loweredRest.constructors
                requests :=
                  (psListAppend lowered.requests loweredRest.requests)
              }

def psIrSpecializeRewriteImports
    (module : PsVerifiedIrModule)
    (_sourceItems : List PsVerifiedIrExternalImport) :
    Except PsIrSpecializeError PsIrSpecializeImportsResult :=
  match _sourceItems with
  | List.nil =>
      Except.ok {
        imports := []
        requests := []
      }
  | List.cons importInfo rest =>
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
                  List.cons (PsVerifiedIrExternalImport.mk importInfo.localName importInfo.source importInfo.importedName lowered.type) loweredRest.imports
                requests :=
                  (psListAppend lowered.requests loweredRest.requests)
              }

def psIrSpecializeSeedStructures
    (module : PsVerifiedIrModule) (sources : List PsVerifiedIrStructure) :
    Except PsIrSpecializeError (Prod (List PsVerifiedIrStructure) (List PsIrSpecializeRequest)) :=
  match sources with
  | List.nil => Except.ok (Prod.mk List.nil List.nil)
  | List.cons structureInfo rest =>
      match psIrSpecializeSeedStructures module rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest =>
          match structureInfo.typeParameters with
          | List.cons _ _ => Except.ok loweredRest
          | List.nil =>
              match psIrSpecializeRewriteStructureFields module [] structureInfo.fields with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok (Prod.mk
                    (List.cons (PsVerifiedIrStructure.mk structureInfo.name [] lowered.fields) loweredRest.fst)
                    (psListAppend lowered.requests loweredRest.snd))

def psIrSpecializeSeedInductives
    (module : PsVerifiedIrModule) (sources : List PsVerifiedIrInductive) :
    Except PsIrSpecializeError (Prod (List PsVerifiedIrInductive) (List PsIrSpecializeRequest)) :=
  match sources with
  | List.nil => Except.ok (Prod.mk List.nil List.nil)
  | List.cons inductiveInfo rest =>
      match psIrSpecializeSeedInductives module rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest =>
          match inductiveInfo.typeParameters with
          | List.cons _ _ => Except.ok loweredRest
          | List.nil =>
              match psIrSpecializeRewriteConstructors module [] inductiveInfo.constructors with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok (Prod.mk
                    (List.cons (PsVerifiedIrInductive.mk inductiveInfo.name [] lowered.constructors) loweredRest.fst)
                    (psListAppend lowered.requests loweredRest.snd))

def psIrSpecializeSeedDeclarations
    (module : PsVerifiedIrModule) (sources : List PsVerifiedIrDeclaration) :
    Except PsIrSpecializeError (Prod (List PsVerifiedIrDeclaration) (List PsIrSpecializeRequest)) :=
  match sources with
  | List.nil => Except.ok (Prod.mk List.nil List.nil)
  | List.cons declaration rest =>
      match psIrSpecializeSeedDeclarations module rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest =>
          match declaration.typeParameters with
          | List.cons _ _ => Except.ok loweredRest
          | List.nil =>
              match psIrSpecializeRewriteParameters module [] declaration.parameters with
              | Except.error error => Except.error error
              | Except.ok loweredParameters =>
                  match psIrSpecializeRewriteType module [] declaration.resultType with
                  | Except.error error => Except.error error
                  | Except.ok loweredResult =>
                      match psIrSpecializeRewriteExpr module [] declaration.body with
                      | Except.error error => Except.error error
                      | Except.ok loweredBody =>
                          Except.ok (Prod.mk
                            (List.cons (PsVerifiedIrDeclaration.mk declaration.name []
                              loweredParameters.parameters loweredResult.type loweredBody.expr) loweredRest.fst)
                            (psListAppend loweredParameters.requests
                              (psListAppend loweredResult.requests
                                (psListAppend loweredBody.requests loweredRest.snd))))

def psIrSpecializeAppendRequest
    (state : PsIrSpecializeState)
    (requests : List PsIrSpecializeRequest) :
    PsIrSpecializeState :=
  {
    imports := state.imports
    structures := state.structures
    inductives := state.inductives
    declarations := state.declarations
    pending := (psListAppend state.pending requests)
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
    seen := List.cons key state.seen
  }

def psIrSpecializeAddStructure
    (state : PsIrSpecializeState)
    (structureInfo : PsVerifiedIrStructure)
    (requests : List PsIrSpecializeRequest) :
    PsIrSpecializeState :=
  {
    imports := state.imports
    structures := (psListAppend state.structures [structureInfo])
    inductives := state.inductives
    declarations := state.declarations
    pending := (psListAppend state.pending requests)
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
    inductives := (psListAppend state.inductives [inductiveInfo])
    declarations := state.declarations
    pending := (psListAppend state.pending requests)
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
    declarations := (psListAppend state.declarations [declaration])
    pending := (psListAppend state.pending requests)
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
  | Option.none =>
      Except.error
        (PsIrSpecializeError.unknownTarget request.name)
  | Option.some structureInfo =>
      if
          !(Nat.beq (psListLength structureInfo.typeParameters) (psListLength request.arguments))
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
            | Option.none =>
                Except.error
                  (PsIrSpecializeError.nonGroundType request.name)
            | Option.some specializedName =>
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
  | Option.none =>
      Except.error
        (PsIrSpecializeError.unknownTarget request.name)
  | Option.some inductiveInfo =>
      if
          !(Nat.beq (psListLength inductiveInfo.typeParameters) (psListLength request.arguments))
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
            | Option.none =>
                Except.error
                  (PsIrSpecializeError.nonGroundType request.name)
            | Option.some specializedName =>
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
  | Option.none =>
      Except.error
        (PsIrSpecializeError.unknownTarget request.name)
  | Option.some declaration =>
      if
          !(Nat.beq (psListLength declaration.typeParameters) (psListLength request.arguments))
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
            | Option.none =>
                Except.error
                  (PsIrSpecializeError.nonGroundType request.name)
            | Option.some specializedName =>
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
                                ((psListAppend loweredParameters.requests (psListAppend loweredResult.requests loweredBody.requests))))

def psIrSpecializeProcessRequest
    (module : PsVerifiedIrModule)
    (state : PsIrSpecializeState)
    (request : PsIrSpecializeRequest) :
    Except PsIrSpecializeError PsIrSpecializeState :=
  match request.kind with
  | PsIrSpecializeKind.structure =>
      psIrSpecializeProcessStructure module state request
  | PsIrSpecializeKind.inductive =>
      psIrSpecializeProcessInductive module state request
  | PsIrSpecializeKind.declaration =>
      psIrSpecializeProcessDeclaration module state request

def psIrSpecializeLoop
    (module : PsVerifiedIrModule)
    (depth : Nat) :
    PsIrSpecializeState -> Except PsIrSpecializeError PsIrSpecializeState :=
  match depth with
  | 0 => fun (state : PsIrSpecializeState) => Except.error PsIrSpecializeError.fuelExhausted
  | fuel + 1 =>
      fun (state : PsIrSpecializeState) =>
        let smaller : PsIrSpecializeState -> Except PsIrSpecializeError PsIrSpecializeState := psIrSpecializeLoop module fuel;
        match state.pending with
        | List.nil => Except.ok state
        | List.cons request rest =>
            match psIrSpecializeRequestKey request with
            | Option.none =>
                Except.error
                  (PsIrSpecializeError.nonGroundType request.name)
            | Option.some key =>
                let withoutHead : PsIrSpecializeState := {
                  imports := state.imports
                  structures := state.structures
                  inductives := state.inductives
                  declarations := state.declarations
                  pending := rest
                  seen := state.seen
                };
                if psIrSpecializeSeenContains state.seen key then
                  smaller withoutHead
                else
                  let marked :=
                    psIrSpecializeMarkSeen withoutHead key;
                  match
                      psIrSpecializeProcessRequest
                        module
                        marked
                        request with
                  | Except.error error => Except.error error
                  | Except.ok next =>
                      smaller next

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
                    structures := structures.fst
                    inductives := inductives.fst
                    declarations := declarations.fst
                    pending :=
                      (psListAppend imports.requests (psListAppend structures.snd (psListAppend inductives.snd declarations.snd)))
                    seen := []
                  };
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

-- A public raw wrapper is not itself an authority token. Validate the exact
-- input AND the transformed output, including traversal-budget completion.
-- This establishes bounded typing, not semantic equivalence of specialization.
def psIrSpecializeRecheck
    (raw : PsVerifiedIrModule) (isInput : Bool) :
    Except PsIrSpecializeError Unit :=
  let report := psCheckVerifiedIrModule psIrCheckDefaultOptions raw;
  if !report.traversalComplete then
    Except.error PsIrSpecializeError.validationBudgetExhausted
  else if !report.accepted then
    if isInput then Except.error PsIrSpecializeError.inputValidationFailed
    else Except.error PsIrSpecializeError.outputValidationFailed
  else
    Except.ok ()

def psIrSpecializeValidatedModule
    (validated : PsValidatedIrModule) :
    Except PsIrSpecializeError PsSpecializedIrModule :=
  match psIrSpecializeRecheck validated.raw true with
  | Except.error error => Except.error error
  | Except.ok checkedInput =>
      match psIrSpecializeModule validated.raw with
      | Except.error error => Except.error error
      | Except.ok raw =>
          match psIrSpecializeRecheck raw false with
          | Except.error error => Except.error error
          | Except.ok checkedOutput => Except.ok (PsSpecializedIrModule.mk raw)

def psIrSpecializeUniformValidatedModule
    (validated : PsValidatedIrModule) :
    Except PsIrSpecializeError PsUniformSpecializedIrModule :=
  match psIrSpecializeRecheck validated.raw true with
  | Except.error error => Except.error error
  | Except.ok checkedInput =>
      match psIrSpecializeModule validated.raw with
      | Except.error error => Except.error error
      | Except.ok raw =>
          match psIrSpecializeRecheck raw false with
          | Except.error error => Except.error error
          | Except.ok checkedOutput => Except.ok (PsUniformSpecializedIrModule.mk raw)
