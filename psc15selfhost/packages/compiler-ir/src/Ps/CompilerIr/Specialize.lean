import Ps.CompilerIr.Model
import Ps.CompilerIr.Pass
import Ps.Foundation.List

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

def psIrSpecializeBoolNot (value : Bool) : Bool :=
  if value then false else true

def psIrSpecializeNatNe (left : Nat) (right : Nat) : Bool :=
  if Nat.beq left right then false else true

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
  fields : List (String × PsVerifiedIrExpr)
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeMatchBindingsResult where
  bindings : List PsVerifiedIrMatchBinding
  requests : List PsIrSpecializeRequest

structure PsIrSpecializeAlternativesResult where
  alternatives : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)
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

def psIrSpecializeLookupType
    (entries : List (String × PsVerifiedIrType))
    (name : String) :
    Option PsVerifiedIrType :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq (Prod.fst entry) name then
        Option.some (Prod.snd entry)
      else
        psIrSpecializeLookupType rest name

def psIrSpecializeFindStructure
    (entries : List PsVerifiedIrStructure)
    (name : String) :
    Option PsVerifiedIrStructure :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq entry.name name then
        Option.some entry
      else
        psIrSpecializeFindStructure rest name

def psIrSpecializeFindInductive
    (entries : List PsVerifiedIrInductive)
    (name : String) :
    Option PsVerifiedIrInductive :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq entry.name name then
        Option.some entry
      else
        psIrSpecializeFindInductive rest name

def psIrSpecializeFindDeclaration
    (entries : List PsVerifiedIrDeclaration)
    (name : String) :
    Option PsVerifiedIrDeclaration :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq entry.name name then
        Option.some entry
      else
        psIrSpecializeFindDeclaration rest name

def psIrSpecializeScopeContains (locals : List String) (name : String) : Bool :=
  match locals with
  | List.nil => false
  | List.cons boundName rest =>
      if psStringEq boundName name then true else psIrSpecializeScopeContains rest name

def psIrSpecializeParameterNames (parameters : List PsVerifiedIrParameter) : List String :=
  match parameters with
  | List.nil => List.nil
  | List.cons parameter rest => List.cons parameter.name (psIrSpecializeParameterNames rest)

def psIrSpecializeBindingNames (bindings : List PsVerifiedIrMatchBinding) : List String :=
  match bindings with
  | List.nil => List.nil
  | List.cons binding rest => List.cons binding.name (psIrSpecializeBindingNames rest)

def psIrSpecializeFindFreeDeclaration
    (declarations : List PsVerifiedIrDeclaration) (locals : List String)
    (name : String) : Option PsVerifiedIrDeclaration :=
  if psIrSpecializeScopeContains locals name then Option.none
  else psIrSpecializeFindDeclaration declarations name

-- Generated global names must not change a call's lexical binding. The
-- current naming contract rejects capture instead of silently renaming locals.
def psIrSpecializeInstanceCall
    (locals : List String) (name : String) (arguments : List PsVerifiedIrExpr)
    (requests : List PsIrSpecializeRequest) : Except PsIrSpecializeError PsIrSpecializeExprResult :=
  if psIrSpecializeScopeContains locals name then
    Except.error PsIrSpecializeError.unsupportedGenericCall
  else
    Except.ok (PsIrSpecializeExprResult.mk
      (PsVerifiedIrExpr.call (PsVerifiedIrExpr.var name) List.nil arguments) requests)

def psIrSpecializeJoinKeys
    (keys : List (Option String)) : Option String :=
  match keys with
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
                Option.some (String.Internal.append head (String.Internal.append "$" tail))

def psIrSpecializeTypeKeyWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType -> Option String :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) => Option.none
  | fuel + 1 =>
      let smaller : PsVerifiedIrType -> Option String :=
        psIrSpecializeTypeKeyWithFuel fuel;
      fun (type : PsVerifiedIrType) =>
        match type with
        | .unknown => Option.none
        | .typeParameter _ => Option.none
        | .primitive primitive =>
            match primitive with
            | .nat => Option.some "Nat"
            | .int => Option.some "Int"
            | .uint8 => Option.some "U8"
            | .uint16 => Option.some "U16"
            | .uint32 => Option.some "U32"
            | .uint64 => Option.some "U64"
            | .usize => Option.some "USize"
            | .int8 => Option.some "I8"
            | .int16 => Option.some "I16"
            | .int32 => Option.some "I32"
            | .int64 => Option.some "I64"
            | .isize => Option.some "ISize"
            | .float => Option.some "F64"
            | .float32 => Option.some "F32"
            | .bool => Option.some "Bool"
            | .char => Option.some "Char"
            | .string => Option.some "String"
            | .unit => Option.some "Unit"
        | .function parameters result =>
            let parameterKeys :=
              psListMap
                (smaller)
                parameters;
            match psIrSpecializeJoinKeys parameterKeys with
            | Option.none => Option.none
            | Option.some parameterKey =>
                match smaller result with
                | Option.none => Option.none
                | Option.some resultKey =>
                    Option.some
                      (String.Internal.append
          "Fn$"
          (String.Internal.append
            parameterKey
            (String.Internal.append "$To$" resultKey)))
        | .named name arguments =>
            let argumentKeys :=
              psListMap
                (smaller)
                arguments;
            match psIrSpecializeJoinKeys argumentKeys with
            | Option.none => Option.none
            | Option.some keys =>
                if psStringEq keys "" then
                  Option.some (String.Internal.append "N$" name)
                else
                  Option.some
                    (String.Internal.append
                      "N$"
                      (String.Internal.append
                        name
                        (String.Internal.append "$" keys)))

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
      if psStringEq key "" then
        Option.some name
      else
        Option.some
          (String.Internal.append
            name
            (String.Internal.append "$spec$" key))

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
  | Option.none => Option.none
  | Option.some name =>
      Option.some
        (String.Internal.append
          (psIrSpecializeKindPrefix request.kind)
          name)

def psIrSpecializeSeenContains
    (entries : List String)
    (key : String) : Bool :=
  match entries with
  | List.nil => false
  | List.cons entry rest =>
      if psStringEq entry key then
        true
      else
        psIrSpecializeSeenContains rest key

def psIrSpecializeIsGround
    (type : PsVerifiedIrType) : Bool :=
  match psIrSpecializeTypeKey type with
  | Option.none => false
  | Option.some _ => true

def psIrSpecializeAllGround
    (types : List PsVerifiedIrType) : Bool :=
  match types with
  | List.nil => true
  | List.cons type rest =>
      if psIrSpecializeIsGround type then
        psIrSpecializeAllGround rest
      else
        false

def psIrSpecializeTypeParameterNames
    (parameters : List PsVerifiedIrTypeParameter) :
    List String :=
  match parameters with
  | List.nil => []
  | List.cons parameter rest =>
      List.cons
        parameter.name
        (psIrSpecializeTypeParameterNames rest)

def psIrSpecializeMakeSubstitution
    (parameters : List PsVerifiedIrTypeParameter)
    (arguments : List PsVerifiedIrType) :
    Except PsIrSpecializeError (List (String × PsVerifiedIrType)) :=
  if psIrSpecializeNatNe (psListLength parameters) (psListLength arguments) then
    Except.error
      (PsIrSpecializeError.typeArgumentArity "")
  else if psIrSpecializeBoolNot (psIrSpecializeAllGround arguments) then
    Except.error
      (PsIrSpecializeError.nonGroundType "")
  else
    Except.ok
      (psListZip
        (psIrSpecializeTypeParameterNames parameters)
        arguments)

def psIrSpecializeGenericTypeRequest
    (module : PsVerifiedIrModule)
    (name : String)
    (arguments : List PsVerifiedIrType) :
    Option PsIrSpecializeRequest :=
  match psIrSpecializeFindStructure module.structures name with
  | Option.some structureInfo =>
      match structureInfo.typeParameters with
      | [] => Option.none
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
          | [] => Option.none
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
    (types : List PsVerifiedIrType) :
    Except PsIrSpecializeError PsIrSpecializeTypeListResult :=
  match types with
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
                types :=
                  List.cons lowered.type loweredRest.types
                requests :=
                  psListAppend lowered.requests loweredRest.requests
              }

def psIrSpecializeRewriteTypeWithFuel
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (remainingFuel : Nat) :
    PsVerifiedIrType ->
    Except PsIrSpecializeError PsIrSpecializeTypeResult :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) =>
        Except.error PsIrSpecializeError.fuelExhausted
  | fuel + 1 =>
      let rewrite : PsVerifiedIrType -> Except PsIrSpecializeError PsIrSpecializeTypeResult :=
        psIrSpecializeRewriteTypeWithFuel
          module
          substitution
          fuel;
      fun (type : PsVerifiedIrType) =>
        match type with
        | .unknown =>
            Except.error
              (PsIrSpecializeError.nonGroundType "unknown")
        | .typeParameter name =>
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
                        psListAppend loweredParameters.requests loweredResult.requests
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
                        psIrSpecializeBoolNot
                          (psIrSpecializeAllGround loweredArguments.types)
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
                              psListAppend loweredArguments.requests [request]
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

def psIrSpecializeRewriteParameters
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (parameters : List PsVerifiedIrParameter) :
    Except PsIrSpecializeError PsIrSpecializeParametersResult :=
  match parameters with
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
                  List.cons
                    (PsVerifiedIrParameter.mk
                      parameter.name
                      lowered.type)
                    loweredRest.parameters
                requests :=
                  psListAppend lowered.requests loweredRest.requests
              }

def psIrSpecializeRewriteExprListWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsIrSpecializeError PsIrSpecializeExprResult)
    (expressions : List PsVerifiedIrExpr) :
    Except PsIrSpecializeError PsIrSpecializeExprListResult :=
  match expressions with
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
                  psListAppend lowered.requests loweredRest.requests
              }

def psIrSpecializeRewriteFieldsWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsIrSpecializeError PsIrSpecializeExprResult)
    (fields : List (String × PsVerifiedIrExpr)) :
    Except PsIrSpecializeError PsIrSpecializeFieldsResult :=
  match fields with
  | List.nil =>
      Except.ok
        (PsIrSpecializeFieldsResult.mk
          List.nil
          List.nil)
  | List.cons field rest =>
      match rewrite (Prod.snd field) with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psIrSpecializeRewriteFieldsWith rewrite rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok
                (PsIrSpecializeFieldsResult.mk
                  (List.cons
                    (Prod.mk (Prod.fst field) lowered.expr)
                    loweredRest.fields)
                  (psListAppend
                    lowered.requests
                    loweredRest.requests))

def psIrSpecializeRewriteMatchBindings
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (bindings : List PsVerifiedIrMatchBinding) :
    Except PsIrSpecializeError PsIrSpecializeMatchBindingsResult :=
  match bindings with
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
                  List.cons
                    (PsVerifiedIrMatchBinding.mk
                      binding.field
                      binding.name
                      lowered.type)
                    loweredRest.bindings
                requests :=
                  psListAppend lowered.requests loweredRest.requests
              }

def psIrSpecializeRewriteAlternativesWith
    (rewrite :
      List String ->
      PsVerifiedIrExpr ->
      Except PsIrSpecializeError PsIrSpecializeExprResult)
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (locals : List String)
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr)) :
    Except PsIrSpecializeError PsIrSpecializeAlternativesResult :=
  match alternatives with
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
            (Prod.fst (Prod.snd alternative)) with
      | Except.error error => Except.error error
      | Except.ok loweredBindings =>
          match rewrite
              (psListAppend (psIrSpecializeBindingNames (Prod.fst (Prod.snd alternative))) locals)
              (Prod.snd (Prod.snd alternative)) with
          | Except.error error => Except.error error
          | Except.ok loweredBody =>
              match
                  psIrSpecializeRewriteAlternativesWith
                    rewrite
                    module
                    substitution
                    locals
                    rest with
              | Except.error error => Except.error error
              | Except.ok loweredRest =>
                  Except.ok {
                    alternatives :=
                      List.cons
                        (Prod.mk
                          (Prod.fst alternative)
                          (Prod.mk
                            loweredBindings.bindings
                            loweredBody.expr))
                        loweredRest.alternatives
                    requests :=
                      psListAppend loweredBindings.requests (psListAppend loweredBody.requests loweredRest.requests)
                  }

-- Fuel decreases before the scope/expression continuation, following the
-- PSC1 portable worker pattern. Binder scopes apply only to their bodies.
def psIrSpecializeRewriteExprScopedWithFuel
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (remainingFuel : Nat) :
    List String ->
    PsVerifiedIrExpr ->
    Except PsIrSpecializeError PsIrSpecializeExprResult :=
  match remainingFuel with
  | 0 =>
      fun (_locals : List String) (_expression : PsVerifiedIrExpr) =>
        Except.error PsIrSpecializeError.fuelExhausted
  | fuel + 1 =>
      let rewriteScoped : List String -> PsVerifiedIrExpr -> Except PsIrSpecializeError PsIrSpecializeExprResult :=
        psIrSpecializeRewriteExprScopedWithFuel
          module
          substitution
          fuel;
      let rewriteType :=
        psIrSpecializeRewriteType
          module
          substitution;
      fun (locals : List String) (expression : PsVerifiedIrExpr) =>
        let rewrite : PsVerifiedIrExpr -> Except PsIrSpecializeError PsIrSpecializeExprResult := rewriteScoped locals;
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
        | .intrinsic operation typeArguments arguments =>
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
                        psListAppend loweredTypes.requests lowered.requests
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
                    match rewriteScoped (psListAppend (psIrSpecializeParameterNames parameters) locals) body with
                    | Except.error error => Except.error error
                    | Except.ok loweredBody =>
                        Except.ok {
                          expr :=
                            PsVerifiedIrExpr.lambda
                              loweredParameters.parameters
                              loweredResult.type
                              loweredBody.expr
                          requests :=
                            psListAppend loweredParameters.requests (psListAppend loweredResult.requests loweredBody.requests)
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
                                psIrSpecializeFindFreeDeclaration
                                  module.declarations
                                  locals
                                  name with
                            | Option.some declaration =>
                                match declaration.typeParameters with
                                | [] =>
                                    Except.ok {
                                      expr :=
                                        PsVerifiedIrExpr.call
                                          loweredFn.expr
                                          loweredTypes.types
                                          loweredArguments.expressions
                                      requests :=
                                        psListAppend loweredFn.requests (psListAppend loweredTypes.requests loweredArguments.requests)
                                    }
                                | _ =>
                                    if
                                        psIrSpecializeNatNe (psListLength declaration.typeParameters)
                                          (psListLength loweredTypes.types)
                                    then
                                      Except.error
                                        (PsIrSpecializeError.typeArgumentArity
                                          name)
                                    else if
                                        psIrSpecializeBoolNot
                                          (psIrSpecializeAllGround loweredTypes.types)
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
                                          psIrSpecializeInstanceCall locals specializedName loweredArguments.expressions
                                            (psListAppend loweredFn.requests (psListAppend loweredTypes.requests (psListAppend loweredArguments.requests [request])))
                            | Option.none =>
                                Except.ok {
                                  expr :=
                                    PsVerifiedIrExpr.call
                                      loweredFn.expr
                                      loweredTypes.types
                                      loweredArguments.expressions
                                  requests :=
                                    psListAppend loweredFn.requests (psListAppend loweredTypes.requests loweredArguments.requests)
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
                                  psListAppend loweredFn.requests (psListAppend loweredTypes.requests loweredArguments.requests)
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
                    match rewriteScoped (List.cons name locals) body with
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
                            psListAppend loweredType.requests (psListAppend loweredValue.requests loweredBody.requests)
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
                            psListAppend loweredCondition.requests (psListAppend loweredThen.requests loweredElse.requests)
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
                    | Option.some structureInfo =>
                        match structureInfo.typeParameters with
                        | [] =>
                            Except.ok {
                              expr :=
                                PsVerifiedIrExpr.record
                                  structureName
                                  []
                                  loweredFields.fields
                              requests :=
                                psListAppend loweredTypes.requests loweredFields.requests
                            }
                        | _ =>
                            if
                                psIrSpecializeNatNe (psListLength structureInfo.typeParameters)
                                  (psListLength loweredTypes.types)
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
                                      psListAppend loweredTypes.requests (psListAppend loweredFields.requests [request])
                                  }
                    | Option.none =>
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
                    | Option.some structureInfo =>
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
                                psListAppend loweredTypes.requests loweredTarget.requests
                            }
                        | _ =>
                            if
                                psIrSpecializeNatNe (psListLength structureInfo.typeParameters)
                                  (psListLength loweredTypes.types)
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
                                      psListAppend loweredTypes.requests (psListAppend loweredTarget.requests [request])
                                  }
                    | Option.none =>
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
                    | Option.some inductiveInfo =>
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
                                psListAppend loweredTypes.requests loweredFields.requests
                            }
                        | _ =>
                            if
                                psIrSpecializeNatNe (psListLength inductiveInfo.typeParameters)
                                  (psListLength loweredTypes.types)
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
                                      psListAppend loweredTypes.requests (psListAppend loweredFields.requests [request])
                                  }
                    | Option.none =>
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
                          rewriteScoped
                          module
                          substitution
                          locals
                          alternatives with
                    | Except.error error => Except.error error
                    | Except.ok loweredAlternatives =>
                        match
                            psIrSpecializeFindInductive
                              module.inductives
                              inductiveName with
                        | Option.some inductiveInfo =>
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
                                    psListAppend loweredTypes.requests (psListAppend loweredScrutinee.requests loweredAlternatives.requests)
                                }
                            | _ =>
                                if
                                    psIrSpecializeNatNe (psListLength inductiveInfo.typeParameters)
                                      (psListLength loweredTypes.types)
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
                                          psListAppend loweredTypes.requests (psListAppend loweredScrutinee.requests (psListAppend loweredAlternatives.requests [request]))
                                      }
                        | Option.none =>
                            Except.error
                              (PsIrSpecializeError.unknownTarget
                                inductiveName)

def psIrSpecializeRewriteExprWithFuel
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (remainingFuel : Nat)
    (expression : PsVerifiedIrExpr) :
    Except PsIrSpecializeError PsIrSpecializeExprResult :=
  psIrSpecializeRewriteExprScopedWithFuel module substitution remainingFuel List.nil expression

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
    (substitution : List (String × PsVerifiedIrType))
    (fields : List PsVerifiedIrStructureField) :
    Except PsIrSpecializeError PsIrSpecializeStructureFieldsResult :=
  match fields with
  | List.nil =>
      Except.ok
        (PsIrSpecializeStructureFieldsResult.mk
          List.nil
          List.nil)
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
              Except.ok
                (PsIrSpecializeStructureFieldsResult.mk
                  (List.cons
                    (PsVerifiedIrStructureField.mk
                      field.name
                      lowered.type)
                    loweredRest.fields)
                  (psListAppend
                    lowered.requests
                    loweredRest.requests))

def psIrSpecializeRewriteConstructorFields
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (fields : List PsVerifiedIrConstructorField) :
    Except PsIrSpecializeError PsIrSpecializeConstructorFieldsResult :=
  match fields with
  | List.nil =>
      Except.ok
        (PsIrSpecializeConstructorFieldsResult.mk
          List.nil
          List.nil)
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
              Except.ok
                (PsIrSpecializeConstructorFieldsResult.mk
                  (List.cons
                    (PsVerifiedIrConstructorField.mk
                      field.name
                      lowered.type)
                    loweredRest.fields)
                  (psListAppend
                    lowered.requests
                    loweredRest.requests))

def psIrSpecializeRewriteConstructors
    (module : PsVerifiedIrModule)
    (substitution : List (String × PsVerifiedIrType))
    (constructors : List PsVerifiedIrConstructor) :
    Except PsIrSpecializeError PsIrSpecializeConstructorsResult :=
  match constructors with
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
                  List.cons
                    (PsVerifiedIrConstructor.mk
                      constructorInfo.name
                      lowered.fields)
                    loweredRest.constructors
                requests :=
                  psListAppend lowered.requests loweredRest.requests
              }

def psIrSpecializeRewriteImports
    (module : PsVerifiedIrModule)
    (imports : List PsVerifiedIrExternalImport) :
    Except PsIrSpecializeError PsIrSpecializeImportsResult :=
  match imports with
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
                  List.cons
                    (PsVerifiedIrExternalImport.mk
                      importInfo.localName
                      importInfo.source
                      importInfo.importedName
                      lowered.type)
                    loweredRest.imports
                requests :=
                  psListAppend lowered.requests loweredRest.requests
              }

def psIrSpecializeSeedStructures
    (module : PsVerifiedIrModule)
    (structures : List PsVerifiedIrStructure) :
    Except PsIrSpecializeError (List PsVerifiedIrStructure × List PsIrSpecializeRequest) :=
  match structures with
  | List.nil => Except.ok (Prod.mk List.nil List.nil)
  | List.cons structureInfo rest =>
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
                    (Prod.mk
                      (List.cons
                        (PsVerifiedIrStructure.mk
                          structureInfo.name
                          List.nil
                          lowered.fields)
                        (Prod.fst loweredRest))
                      (psListAppend
                        lowered.requests
                        (Prod.snd loweredRest)))

def psIrSpecializeSeedInductives
    (module : PsVerifiedIrModule)
    (inductives : List PsVerifiedIrInductive) :
    Except PsIrSpecializeError (List PsVerifiedIrInductive × List PsIrSpecializeRequest) :=
  match inductives with
  | List.nil => Except.ok (Prod.mk List.nil List.nil)
  | List.cons inductiveInfo rest =>
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
                    (Prod.mk
                      (List.cons
                        (PsVerifiedIrInductive.mk
                          inductiveInfo.name
                          List.nil
                          lowered.constructors)
                        (Prod.fst loweredRest))
                      (psListAppend
                        lowered.requests
                        (Prod.snd loweredRest)))

def psIrSpecializeSeedDeclarations
    (module : PsVerifiedIrModule)
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsIrSpecializeError (List PsVerifiedIrDeclaration × List PsIrSpecializeRequest) :=
  match declarations with
  | List.nil => Except.ok (Prod.mk List.nil List.nil)
  | List.cons declaration rest =>
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
                          psIrSpecializeRewriteExprScopedWithFuel
                            module
                            []
                            4096
                            (psIrSpecializeParameterNames declaration.parameters)
                            declaration.body with
                      | Except.error error => Except.error error
                      | Except.ok loweredBody =>
                          Except.ok
                            (Prod.mk
                              (List.cons
                                (PsVerifiedIrDeclaration.mk
                                  declaration.name
                                  List.nil
                                  loweredParameters.parameters
                                  loweredResult.type
                                  loweredBody.expr)
                                (Prod.fst loweredRest))
                              (psListAppend
                                loweredParameters.requests
                                (psListAppend
                                  loweredResult.requests
                                  (psListAppend
                                    loweredBody.requests
                                    (Prod.snd loweredRest)))))

def psIrSpecializePendingContainsKey
    (requests : List PsIrSpecializeRequest)
    (key : String) : Bool :=
  match requests with
  | List.nil => false
  | List.cons request rest =>
      match psIrSpecializeRequestKey request with
      | Option.none =>
          psIrSpecializePendingContainsKey rest key
      | Option.some requestKey =>
          if psStringEq requestKey key then
            true
          else
            psIrSpecializePendingContainsKey rest key

def psIrSpecializeAppendOneRequest
    (state : PsIrSpecializeState)
    (request : PsIrSpecializeRequest) :
    PsIrSpecializeState :=
  match psIrSpecializeRequestKey request with
  | Option.none =>
      {
        imports := state.imports
        structures := state.structures
        inductives := state.inductives
        declarations := state.declarations
        pending := psListAppend state.pending [request]
        seen := state.seen
      }
  | Option.some key =>
      if psIrSpecializeSeenContains state.seen key then
        state
      else
        {
          imports := state.imports
          structures := state.structures
          inductives := state.inductives
          declarations := state.declarations
          pending := psListAppend state.pending [request]
          seen := List.cons key state.seen
        }

def psIrSpecializeAppendRequestWorker
    (requests : List PsIrSpecializeRequest) :
    PsIrSpecializeState -> PsIrSpecializeState :=
  match requests with
  | List.nil =>
      fun (state : PsIrSpecializeState) => state
  | List.cons request rest =>
      let smaller :
          PsIrSpecializeState -> PsIrSpecializeState :=
        psIrSpecializeAppendRequestWorker rest;
      fun (state : PsIrSpecializeState) =>
        let nextState : PsIrSpecializeState :=
          psIrSpecializeAppendOneRequest state request;
        smaller nextState

def psIrSpecializeAppendRequest
    (state : PsIrSpecializeState)
    (requests : List PsIrSpecializeRequest) :
    PsIrSpecializeState :=
  psIrSpecializeAppendRequestWorker requests state

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
  let nextState : PsIrSpecializeState := {
    imports := state.imports
    structures := psListAppend state.structures [structureInfo]
    inductives := state.inductives
    declarations := state.declarations
    pending := state.pending
    seen := state.seen
  };
  psIrSpecializeAppendRequest nextState requests

def psIrSpecializeAddInductive
    (state : PsIrSpecializeState)
    (inductiveInfo : PsVerifiedIrInductive)
    (requests : List PsIrSpecializeRequest) :
    PsIrSpecializeState :=
  let nextState : PsIrSpecializeState := {
    imports := state.imports
    structures := state.structures
    inductives := psListAppend state.inductives [inductiveInfo]
    declarations := state.declarations
    pending := state.pending
    seen := state.seen
  };
  psIrSpecializeAppendRequest nextState requests

def psIrSpecializeAddDeclaration
    (state : PsIrSpecializeState)
    (declaration : PsVerifiedIrDeclaration)
    (requests : List PsIrSpecializeRequest) :
    PsIrSpecializeState :=
  let nextState : PsIrSpecializeState := {
    imports := state.imports
    structures := state.structures
    inductives := state.inductives
    declarations := psListAppend state.declarations [declaration]
    pending := state.pending
    seen := state.seen
  };
  psIrSpecializeAppendRequest nextState requests

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
          psIrSpecializeNatNe (psListLength structureInfo.typeParameters)
            (psListLength request.arguments)
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
                        (PsVerifiedIrStructure.mk
                          specializedName
                          List.nil
                          lowered.fields)
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
          psIrSpecializeNatNe (psListLength inductiveInfo.typeParameters)
            (psListLength request.arguments)
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
                        (PsVerifiedIrInductive.mk
                          specializedName
                          List.nil
                          lowered.constructors)
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
          psIrSpecializeNatNe (psListLength declaration.typeParameters)
            (psListLength request.arguments)
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
                            psIrSpecializeRewriteExprScopedWithFuel
                              module
                              substitution
                              4096
                              (psIrSpecializeParameterNames declaration.parameters)
                              declaration.body with
                        | Except.error error => Except.error error
                        | Except.ok loweredBody =>
                            Except.ok
                              (psIrSpecializeAddDeclaration
                                state
                                (PsVerifiedIrDeclaration.mk
                                  specializedName
                                  List.nil
                                  loweredParameters.parameters
                                  loweredResult.type
                                  loweredBody.expr)
                                (psListAppend
                                  loweredParameters.requests
                                  (psListAppend
                                    loweredResult.requests
                                    loweredBody.requests)))

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
    (module : PsVerifiedIrModule)
    (remainingFuel : Nat) :
    PsIrSpecializeState ->
    Except PsIrSpecializeError PsIrSpecializeState :=
  match remainingFuel with
  | 0 =>
      fun (_state : PsIrSpecializeState) =>
        Except.error PsIrSpecializeError.fuelExhausted
  | fuel + 1 =>
      let smaller : PsIrSpecializeState -> Except PsIrSpecializeError PsIrSpecializeState :=
        psIrSpecializeLoop module fuel;
      fun (state : PsIrSpecializeState) =>
        match state.pending with
        | [] => Except.ok state
        | request :: rest =>
            match psIrSpecializeRequestKey request with
            | Option.none =>
                Except.error
                  (PsIrSpecializeError.nonGroundType request.name)
            | Option.some _ =>
                let withoutHead : PsIrSpecializeState := {
                  imports := state.imports
                  structures := state.structures
                  inductives := state.inductives
                  declarations := state.declarations
                  pending := rest
                  seen := state.seen
                };
                match
                    psIrSpecializeProcessRequest
                      module
                      withoutHead
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
                  let initialBase : PsIrSpecializeState := {
                    imports := imports.imports
                    structures := (Prod.fst structures)
                    inductives := (Prod.fst inductives)
                    declarations := (Prod.fst declarations)
                    pending := []
                    seen := []
                  };
                  let inductiveAndDeclarationRequests :
                      List PsIrSpecializeRequest :=
                    psListAppend
                      (Prod.snd inductives)
                      (Prod.snd declarations);
                  let structureAndLaterRequests :
                      List PsIrSpecializeRequest :=
                    psListAppend
                      (Prod.snd structures)
                      inductiveAndDeclarationRequests;
                  let allRequests : List PsIrSpecializeRequest :=
                    psListAppend
                      imports.requests
                      structureAndLaterRequests;
                  let initial : PsIrSpecializeState :=
                    psIrSpecializeAppendRequest
                      initialBase
                      allRequests;
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


/- Explicit post-validation specialization capability.
This wrapper is deliberately simple so it remains inside the PSC1 portable
self-host profile. Raw psIrSpecializeModule remains a low-level/bootstrap/test
operation; certified target paths should consume PsSpecializedIrModule. -/
structure PsSpecializedIrModule where
  raw : PsVerifiedIrModule

def psIrSpecializeValidatedModule
    (validated : PsValidatedIrModule) :
    Except PsIrSpecializeError PsSpecializedIrModule :=
  match psIrSpecializeModule validated.raw with
  | Except.error error =>
      Except.error error
  | Except.ok specialized =>
      Except.ok (PsSpecializedIrModule.mk specialized)


def psSpecializationPassDefinition : PsPassDefinition :=
  PsPassDefinition.mk
    "psc-pass-specialize/1"
    1
    "psc-verified-ir/1"
    "psc-specialized-ir/1"
    "psc-specialization-runtime-refinement/1"
    "psc-resource-specialization/1"
    "contract-regression-unproved"
    "deterministic-under-declared-inputs"
    "bounded-partial"
    "source:packages/compiler-ir/src/Ps/CompilerIr/Specialize.lean"
    Option.none
    List.nil
    ["trusted-specialization-implementation"]

structure PsSpecializedIrExecutionResult where
  specialized : PsSpecializedIrModule
  execution : PsPassExecution

def psIrSpecializeValidatedModuleWithExecution
    (inputIdentity outputIdentity : String)
    (validated : PsValidatedIrModule) :
    Except PsIrSpecializeError PsSpecializedIrExecutionResult :=
  match psIrSpecializeValidatedModule validated with
  | Except.error error =>
      Except.error error
  | Except.ok specialized =>
      Except.ok
        (PsSpecializedIrExecutionResult.mk
          specialized
          (psPassExecution
            psSpecializationPassDefinition
            inputIdentity
            outputIdentity
            List.nil))

-- A distinct representation strategy: retain every validated generic body and
-- its static type parameters for a target with uniform runtime values. This is
-- an identity selection, not closed monomorphization or a live authority token.
-- Target lowering must explicitly accept the uniform representation contract.
structure PsUniformSpecializedIrModule where
  raw : PsVerifiedIrModule

def psIrSelectUniformSpecialization
    (validated : PsValidatedIrModule) : PsUniformSpecializedIrModule :=
  PsUniformSpecializedIrModule.mk validated.raw

def psUniformSpecializationPassDefinition : PsPassDefinition :=
  PsPassDefinition.mk
    "psc-pass-uniform-specialize/1"
    1
    "psc-verified-ir/1"
    "psc-uniform-specialized-ir/1"
    "psc-uniform-representation-selection/1"
    "psc-resource-specialization/1"
    "identity-selection-target-representation-unproved"
    "deterministic-under-declared-inputs"
    "total-selection"
    "source:packages/compiler-ir/src/Ps/CompilerIr/Specialize.lean"
    Option.none
    List.nil
    ["target-uniform-runtime-representation"]
