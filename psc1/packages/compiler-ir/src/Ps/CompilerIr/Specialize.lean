import Ps.CompilerIr.Check
import Ps.CompilerIr.Provenance
import Ps.Foundation.List
import Ps.Foundation.Name
import Ps.Foundation.StringSet

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

structure PsIrSpecializeDiagnostic where
  phase : String
  owner : String
  error : PsIrSpecializeError
  requestKey : Option String

def psIrSpecializeErrorCode (error : PsIrSpecializeError) : String := match error with
  | PsIrSpecializeError.fuelExhausted => "fuel-exhausted"
  | PsIrSpecializeError.unresolvedTypeParameter name => String.Internal.append "unresolved-type-parameter:" name
  | PsIrSpecializeError.nonGroundType name => String.Internal.append "non-ground-type:" name
  | PsIrSpecializeError.typeArgumentArity name => String.Internal.append "type-argument-arity:" name
  | PsIrSpecializeError.unknownTarget name => String.Internal.append "unknown-target:" name
  | PsIrSpecializeError.unsupportedGenericCall => "unsupported-generic-call"
  | PsIrSpecializeError.inputValidationFailed => "input-validation-failed"
  | PsIrSpecializeError.outputValidationFailed => "output-validation-failed"
  | PsIrSpecializeError.validationBudgetExhausted => "validation-budget-exhausted"

def psIrSpecializeDiagnosticText (diagnostic : PsIrSpecializeDiagnostic) : String := let key : String := (match diagnostic.requestKey with
  | Option.none => ""
  | Option.some value => String.Internal.append " request=" value); String.Internal.append diagnostic.phase (String.Internal.append " owner=" (String.Internal.append diagnostic.owner (String.Internal.append " error=" (String.Internal.append (psIrSpecializeErrorCode diagnostic.error) key))))

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

structure PsIrSpecializeStep where
  state : PsIrSpecializeState
  origin : PsIrTransformOrigin

structure PsIrSpecializeRun where
  state : PsIrSpecializeState
  reversedOrigins : List PsIrTransformOrigin

def psIrSpecializeConcat3 (first : String) (second : String) (third : String) : String := String.Internal.append first (String.Internal.append second third)

def psIrSpecializeConcat4 (first : String) (second : String) (third : String) (fourth : String) : String := String.Internal.append first (psIrSpecializeConcat3 second third fourth)

def psIrSpecializeLookupType (entries : List (Prod String PsVerifiedIrType)) (name : String) : Option PsVerifiedIrType := match entries with
  | List.nil => Option.none
  | List.cons entry rest => (if psStringEq entry.fst name then Option.some entry.snd else psIrSpecializeLookupType rest name)

def psIrSpecializeFindStructure (entries : List PsVerifiedIrStructure) (name : String) : Option PsVerifiedIrStructure := match entries with
  | List.nil => Option.none
  | List.cons entry rest => (if psStringEq entry.name name then Option.some entry else psIrSpecializeFindStructure rest name)

def psIrSpecializeFindInductive (entries : List PsVerifiedIrInductive) (name : String) : Option PsVerifiedIrInductive := match entries with
  | List.nil => Option.none
  | List.cons entry rest => (if psStringEq entry.name name then Option.some entry else psIrSpecializeFindInductive rest name)

def psIrSpecializeFindDeclaration (entries : List PsVerifiedIrDeclaration) (name : String) : Option PsVerifiedIrDeclaration := match entries with
  | List.nil => Option.none
  | List.cons entry rest => (if psStringEq entry.name name then Option.some entry else psIrSpecializeFindDeclaration rest name)

def psIrSpecializeJoinKeys (_sourceItems : List (Option String)) : Option String := match _sourceItems with
  | List.nil => Option.some ""
  | List.cons key rest => (match key with
    | Option.none => Option.none
    | Option.some head => (match psIrSpecializeJoinKeys rest with
      | Option.none => Option.none
      | Option.some tail => (if psStringEq tail "" then Option.some head else Option.some (psIrSpecializeConcat3 head "$" tail))))

def psIrSpecializePrimitiveKey (primitive : PsVerifiedIrPrimitiveType) : String := match primitive with
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

def psIrSpecializeTypeKeyWithFuel (fuel : Nat) : (_ : PsVerifiedIrType) -> Option String := match fuel with
  | _root_.Nat.zero => (fun (type : PsVerifiedIrType) => Option.none)
  | _root_.Nat.succ remaining => (fun (type : PsVerifiedIrType) => let smaller : (_ : PsVerifiedIrType) -> Option String := psIrSpecializeTypeKeyWithFuel remaining; match type with
    | PsVerifiedIrType.unknown => Option.none
    | PsVerifiedIrType.typeParameter _ => Option.none
    | PsVerifiedIrType.primitive primitive => Option.some (psIrSpecializePrimitiveKey primitive)
    | PsVerifiedIrType.function parameters result => (let parameterKeys : List (Option String) := psListMap smaller parameters; match psIrSpecializeJoinKeys parameterKeys with
      | Option.none => Option.none
      | Option.some parameterKey => (match smaller result with
        | Option.none => Option.none
        | Option.some resultKey => Option.some (psIrSpecializeConcat4 "Fn$" parameterKey "$To$" resultKey)))
    | PsVerifiedIrType.named name arguments => (let argumentKeys : List (Option String) := psListMap smaller arguments; match psIrSpecializeJoinKeys argumentKeys with
      | Option.none => Option.none
      | Option.some keys => (if psStringEq keys "" then Option.some (String.Internal.append "N$" name) else Option.some (psIrSpecializeConcat4 "N$" name "$" keys))))

def psIrSpecializeTypeKey (type : PsVerifiedIrType) : Option String := psIrSpecializeTypeKeyWithFuel 64 type

def psIrSpecializeArgumentsKey (arguments : List PsVerifiedIrType) : Option String := psIrSpecializeJoinKeys (psListMap psIrSpecializeTypeKey arguments)

def psIrSpecializedName (name : String) (arguments : List PsVerifiedIrType) : Option String := match psIrSpecializeArgumentsKey arguments with
  | Option.none => Option.none
  | Option.some key => (if psStringEq key "" then Option.some name else Option.some (psIrSpecializeConcat3 name "$spec$" key))

def psIrSpecializeKindPrefix (_sourceItems : PsIrSpecializeKind) : String := match _sourceItems with
  | PsIrSpecializeKind.structure => "S:"
  | PsIrSpecializeKind.inductive => "I:"
  | PsIrSpecializeKind.declaration => "D:"

def psIrSpecializeRequestKey (request : PsIrSpecializeRequest) : Option String := match psIrSpecializedName request.name request.arguments with
  | Option.none => Option.none
  | Option.some name => Option.some (String.Internal.append (psIrSpecializeKindPrefix request.kind) name)

def psIrSpecializeSeenContains (entries : List String) (key : String) : Bool := match entries with
  | List.nil => false
  | List.cons entry rest => (if psStringEq entry key then true else psIrSpecializeSeenContains rest key)

def psIrSpecializeIsGround (type : PsVerifiedIrType) : Bool := match psIrSpecializeTypeKey type with
  | Option.none => false
  | Option.some _ => true

def psIrSpecializeAllGround (_sourceItems : List PsVerifiedIrType) : Bool := match _sourceItems with
  | List.nil => true
  | List.cons type rest => (psIrSpecializeIsGround type && psIrSpecializeAllGround rest)

def psIrSpecializeTypeParameterNames (parameters : List PsVerifiedIrTypeParameter) : List String := psListMap (fun (parameter : PsVerifiedIrTypeParameter) => parameter.name) parameters

def psIrSpecializeMakeSubstitution (parameters : List PsVerifiedIrTypeParameter) (arguments : List PsVerifiedIrType) : Except PsIrSpecializeError (List (Prod String PsVerifiedIrType)) := if (!Nat.beq (psListLength parameters) (psListLength arguments)) then Except.error (PsIrSpecializeError.typeArgumentArity "") else (if (!psIrSpecializeAllGround arguments) then Except.error (PsIrSpecializeError.nonGroundType "") else Except.ok (psListZip (psIrSpecializeTypeParameterNames parameters) arguments))

def psIrSpecializeGenericTypeRequest (module : PsVerifiedIrModule) (name : String) (arguments : List PsVerifiedIrType) : Option PsIrSpecializeRequest := match psIrSpecializeFindStructure module.structures name with
  | Option.some structureInfo => (match structureInfo.typeParameters with
    | List.nil => Option.none
    | _ => Option.some ({ kind := PsIrSpecializeKind.structure, name := name, arguments := arguments }))
  | Option.none => (match psIrSpecializeFindInductive module.inductives name with
    | Option.some inductiveInfo => (match inductiveInfo.typeParameters with
      | List.nil => Option.none
      | _ => Option.some ({ kind := PsIrSpecializeKind.inductive, name := name, arguments := arguments }))
    | Option.none => Option.none)

def psIrSpecializeRewriteTypeListWith (rewrite : (_ : PsVerifiedIrType) -> Except PsIrSpecializeError PsIrSpecializeTypeResult) (_sourceItems : List PsVerifiedIrType) : Except PsIrSpecializeError PsIrSpecializeTypeListResult := match _sourceItems with
  | List.nil => Except.ok ({ types := _root_.List.nil, requests := _root_.List.nil })
  | List.cons type rest => (match rewrite type with
    | Except.error error => Except.error error
    | Except.ok lowered => (match psIrSpecializeRewriteTypeListWith rewrite rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest => Except.ok ({ types := List.cons lowered.type loweredRest.types, requests := psListAppend lowered.requests loweredRest.requests })))

def psIrSpecializeRewriteTypeWithFuel (module : PsVerifiedIrModule) (substitution : List (Prod String PsVerifiedIrType)) (depth : Nat) : (_ : PsVerifiedIrType) -> Except PsIrSpecializeError PsIrSpecializeTypeResult := match depth with
  | _root_.Nat.zero => (fun (type : PsVerifiedIrType) => Except.error PsIrSpecializeError.fuelExhausted)
  | _root_.Nat.succ fuel => (fun (type : PsVerifiedIrType) => let rewrite : (_ : PsVerifiedIrType) -> Except PsIrSpecializeError PsIrSpecializeTypeResult := psIrSpecializeRewriteTypeWithFuel module substitution fuel; match type with
    | PsVerifiedIrType.unknown => Except.error (PsIrSpecializeError.nonGroundType "unknown")
    | PsVerifiedIrType.typeParameter name => (match psIrSpecializeLookupType substitution name with
      | Option.none => Except.error (PsIrSpecializeError.unresolvedTypeParameter name)
      | Option.some value => Except.ok ({ type := value, requests := _root_.List.nil }))
    | PsVerifiedIrType.primitive primitive => Except.ok ({ type := PsVerifiedIrType.primitive primitive, requests := _root_.List.nil })
    | PsVerifiedIrType.function parameters result => (match psIrSpecializeRewriteTypeListWith rewrite parameters with
      | Except.error error => Except.error error
      | Except.ok loweredParameters => (match rewrite result with
        | Except.error error => Except.error error
        | Except.ok loweredResult => Except.ok ({ type := PsVerifiedIrType.function loweredParameters.types loweredResult.type, requests := psListAppend loweredParameters.requests loweredResult.requests })))
    | PsVerifiedIrType.named name arguments => (match psIrSpecializeRewriteTypeListWith rewrite arguments with
      | Except.error error => Except.error error
      | Except.ok loweredArguments => (match psIrSpecializeGenericTypeRequest module name loweredArguments.types with
        | Option.none => Except.ok ({ type := PsVerifiedIrType.named name loweredArguments.types, requests := loweredArguments.requests })
        | Option.some request => (if (!psIrSpecializeAllGround loweredArguments.types) then Except.error (PsIrSpecializeError.nonGroundType name) else (match psIrSpecializedName name loweredArguments.types with
          | Option.none => Except.error (PsIrSpecializeError.nonGroundType name)
          | Option.some specializedName => Except.ok ({ type := PsVerifiedIrType.named specializedName _root_.List.nil, requests := psListAppend loweredArguments.requests (_root_.List.cons request _root_.List.nil) }))))))

def psIrSpecializeRewriteType (module : PsVerifiedIrModule) (substitution : List (Prod String PsVerifiedIrType)) (type : PsVerifiedIrType) : Except PsIrSpecializeError PsIrSpecializeTypeResult := psIrSpecializeRewriteTypeWithFuel module substitution 128 type

def psIrSpecializeRewriteParameters (module : PsVerifiedIrModule) (substitution : List (Prod String PsVerifiedIrType)) (_sourceItems : List PsVerifiedIrParameter) : Except PsIrSpecializeError PsIrSpecializeParametersResult := match _sourceItems with
  | List.nil => Except.ok ({ parameters := _root_.List.nil, requests := _root_.List.nil })
  | List.cons parameter rest => (match psIrSpecializeRewriteType module substitution parameter.type with
    | Except.error error => Except.error error
    | Except.ok lowered => (match psIrSpecializeRewriteParameters module substitution rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest => Except.ok ({ parameters := List.cons (PsVerifiedIrParameter.mk parameter.name lowered.type) loweredRest.parameters, requests := psListAppend lowered.requests loweredRest.requests })))

def psIrSpecializeRewriteExprListWith (rewrite : (_ : PsVerifiedIrExpr) -> Except PsIrSpecializeError PsIrSpecializeExprResult) (_sourceItems : List PsVerifiedIrExpr) : Except PsIrSpecializeError PsIrSpecializeExprListResult := match _sourceItems with
  | List.nil => Except.ok ({ expressions := _root_.List.nil, requests := _root_.List.nil })
  | List.cons expression rest => (match rewrite expression with
    | Except.error error => Except.error error
    | Except.ok lowered => (match psIrSpecializeRewriteExprListWith rewrite rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest => Except.ok ({ expressions := List.cons lowered.expr loweredRest.expressions, requests := psListAppend lowered.requests loweredRest.requests })))

def psIrSpecializeRewriteFieldsWith (rewrite : (_ : PsVerifiedIrExpr) -> Except PsIrSpecializeError PsIrSpecializeExprResult) (_sourceItems : List (Prod String PsVerifiedIrExpr)) : Except PsIrSpecializeError PsIrSpecializeFieldsResult := match _sourceItems with
  | List.nil => Except.ok ({ fields := _root_.List.nil, requests := _root_.List.nil })
  | List.cons field rest => (match rewrite field.snd with
    | Except.error error => Except.error error
    | Except.ok lowered => (match psIrSpecializeRewriteFieldsWith rewrite rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest => Except.ok ({ fields := List.cons (Prod.mk field.fst lowered.expr) loweredRest.fields, requests := psListAppend lowered.requests loweredRest.requests })))

def psIrSpecializeRewriteMatchBindings (module : PsVerifiedIrModule) (substitution : List (Prod String PsVerifiedIrType)) (_sourceItems : List PsVerifiedIrMatchBinding) : Except PsIrSpecializeError PsIrSpecializeMatchBindingsResult := match _sourceItems with
  | List.nil => Except.ok ({ bindings := _root_.List.nil, requests := _root_.List.nil })
  | List.cons binding rest => (match psIrSpecializeRewriteType module substitution binding.type with
    | Except.error error => Except.error error
    | Except.ok lowered => (match psIrSpecializeRewriteMatchBindings module substitution rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest => Except.ok ({ bindings := List.cons (PsVerifiedIrMatchBinding.mk binding.field binding.name lowered.type) loweredRest.bindings, requests := psListAppend lowered.requests loweredRest.requests })))

def psIrSpecializeRewriteAlternativesWith (rewrite : (_ : PsVerifiedIrExpr) -> Except PsIrSpecializeError PsIrSpecializeExprResult) (module : PsVerifiedIrModule) (substitution : List (Prod String PsVerifiedIrType)) (_sourceItems : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) : Except PsIrSpecializeError PsIrSpecializeAlternativesResult := match _sourceItems with
  | List.nil => Except.ok ({ alternatives := _root_.List.nil, requests := _root_.List.nil })
  | List.cons alternative rest => (match psIrSpecializeRewriteMatchBindings module substitution alternative.snd.fst with
    | Except.error error => Except.error error
    | Except.ok loweredBindings => (match rewrite alternative.snd.snd with
      | Except.error error => Except.error error
      | Except.ok loweredBody => (match psIrSpecializeRewriteAlternativesWith rewrite module substitution rest with
        | Except.error error => Except.error error
        | Except.ok loweredRest => Except.ok ({ alternatives := List.cons (Prod.mk alternative.fst (Prod.mk loweredBindings.bindings loweredBody.expr)) loweredRest.alternatives, requests := psListAppend loweredBindings.requests (psListAppend loweredBody.requests loweredRest.requests) }))))

def psIrSpecializeRewriteExprWithFuel (module : PsVerifiedIrModule) (substitution : List (Prod String PsVerifiedIrType)) (depth : Nat) : (_ : PsVerifiedIrExpr) -> Except PsIrSpecializeError PsIrSpecializeExprResult := match depth with
  | _root_.Nat.zero => (fun (expression : PsVerifiedIrExpr) => Except.error PsIrSpecializeError.fuelExhausted)
  | _root_.Nat.succ fuel => (fun (expression : PsVerifiedIrExpr) => let rewrite : (_ : PsVerifiedIrExpr) -> Except PsIrSpecializeError PsIrSpecializeExprResult := psIrSpecializeRewriteExprWithFuel module substitution fuel; let rewriteType := psIrSpecializeRewriteType module substitution; match expression with
    | PsVerifiedIrExpr.literal literal => Except.ok ({ expr := PsVerifiedIrExpr.literal literal, requests := _root_.List.nil })
    | PsVerifiedIrExpr.var name => Except.ok ({ expr := PsVerifiedIrExpr.var name, requests := _root_.List.nil })
    | PsVerifiedIrExpr.intrinsic operation typeArguments arguments => (match psIrSpecializeRewriteTypeListWith rewriteType typeArguments with
      | Except.error error => Except.error error
      | Except.ok loweredTypes => (match psIrSpecializeRewriteExprListWith rewrite arguments with
        | Except.error error => Except.error error
        | Except.ok lowered => Except.ok ({ expr := PsVerifiedIrExpr.intrinsic operation loweredTypes.types lowered.expressions, requests := psListAppend loweredTypes.requests lowered.requests })))
    | PsVerifiedIrExpr.lambda parameters resultType body => (match psIrSpecializeRewriteParameters module substitution parameters with
      | Except.error error => Except.error error
      | Except.ok loweredParameters => (match rewriteType resultType with
        | Except.error error => Except.error error
        | Except.ok loweredResult => (match rewrite body with
          | Except.error error => Except.error error
          | Except.ok loweredBody => Except.ok ({ expr := PsVerifiedIrExpr.lambda loweredParameters.parameters loweredResult.type loweredBody.expr, requests := psListAppend loweredParameters.requests (psListAppend loweredResult.requests loweredBody.requests) }))))
    | PsVerifiedIrExpr.call fn typeArguments arguments => (match rewrite fn with
      | Except.error error => Except.error error
      | Except.ok loweredFn => (match psIrSpecializeRewriteTypeListWith rewriteType typeArguments with
        | Except.error error => Except.error error
        | Except.ok loweredTypes => (match psIrSpecializeRewriteExprListWith rewrite arguments with
          | Except.error error => Except.error error
          | Except.ok loweredArguments => (match fn with
            | PsVerifiedIrExpr.var name => (match psIrSpecializeFindDeclaration module.declarations name with
              | Option.some declaration => (match declaration.typeParameters with
                | List.nil => Except.ok ({ expr := PsVerifiedIrExpr.call loweredFn.expr loweredTypes.types loweredArguments.expressions, requests := psListAppend loweredFn.requests (psListAppend loweredTypes.requests loweredArguments.requests) })
                | _ => (if (!Nat.beq (psListLength declaration.typeParameters) (psListLength loweredTypes.types)) then Except.error (PsIrSpecializeError.typeArgumentArity name) else (if (!psIrSpecializeAllGround loweredTypes.types) then Except.error (PsIrSpecializeError.nonGroundType name) else (match psIrSpecializedName name loweredTypes.types with
                  | Option.none => Except.error (PsIrSpecializeError.nonGroundType name)
                  | Option.some specializedName => (let request : PsIrSpecializeRequest := { kind := PsIrSpecializeKind.declaration, name := name, arguments := loweredTypes.types }; Except.ok ({ expr := PsVerifiedIrExpr.call (PsVerifiedIrExpr.var specializedName) _root_.List.nil loweredArguments.expressions, requests := psListAppend loweredFn.requests (psListAppend loweredTypes.requests (psListAppend loweredArguments.requests (_root_.List.cons request _root_.List.nil))) }))))))
              | Option.none => Except.ok ({ expr := PsVerifiedIrExpr.call loweredFn.expr loweredTypes.types loweredArguments.expressions, requests := psListAppend loweredFn.requests (psListAppend loweredTypes.requests loweredArguments.requests) }))
            | _ => (if Nat.beq (psListLength loweredTypes.types) 0 then Except.ok ({ expr := PsVerifiedIrExpr.call loweredFn.expr _root_.List.nil loweredArguments.expressions, requests := psListAppend loweredFn.requests (psListAppend loweredTypes.requests loweredArguments.requests) }) else Except.error PsIrSpecializeError.unsupportedGenericCall)))))
    | PsVerifiedIrExpr.letE name type value body => (match rewriteType type with
      | Except.error error => Except.error error
      | Except.ok loweredType => (match rewrite value with
        | Except.error error => Except.error error
        | Except.ok loweredValue => (match rewrite body with
          | Except.error error => Except.error error
          | Except.ok loweredBody => Except.ok ({ expr := PsVerifiedIrExpr.letE name loweredType.type loweredValue.expr loweredBody.expr, requests := psListAppend loweredType.requests (psListAppend loweredValue.requests loweredBody.requests) }))))
    | PsVerifiedIrExpr.ifE condition thenBranch elseBranch => (match rewrite condition with
      | Except.error error => Except.error error
      | Except.ok loweredCondition => (match rewrite thenBranch with
        | Except.error error => Except.error error
        | Except.ok loweredThen => (match rewrite elseBranch with
          | Except.error error => Except.error error
          | Except.ok loweredElse => Except.ok ({ expr := PsVerifiedIrExpr.ifE loweredCondition.expr loweredThen.expr loweredElse.expr, requests := psListAppend loweredCondition.requests (psListAppend loweredThen.requests loweredElse.requests) }))))
    | PsVerifiedIrExpr.record structureName typeArguments fields => (match psIrSpecializeRewriteTypeListWith rewriteType typeArguments with
      | Except.error error => Except.error error
      | Except.ok loweredTypes => (match psIrSpecializeRewriteFieldsWith rewrite fields with
        | Except.error error => Except.error error
        | Except.ok loweredFields => (match psIrSpecializeFindStructure module.structures structureName with
          | Option.some structureInfo => (match structureInfo.typeParameters with
            | List.nil => Except.ok ({ expr := PsVerifiedIrExpr.record structureName _root_.List.nil loweredFields.fields, requests := psListAppend loweredTypes.requests loweredFields.requests })
            | _ => (if (!Nat.beq (psListLength structureInfo.typeParameters) (psListLength loweredTypes.types)) then Except.error (PsIrSpecializeError.typeArgumentArity structureName) else (match psIrSpecializedName structureName loweredTypes.types with
              | Option.none => Except.error (PsIrSpecializeError.nonGroundType structureName)
              | Option.some specializedName => (let request : PsIrSpecializeRequest := { kind := PsIrSpecializeKind.structure, name := structureName, arguments := loweredTypes.types }; Except.ok ({ expr := PsVerifiedIrExpr.record specializedName _root_.List.nil loweredFields.fields, requests := psListAppend loweredTypes.requests (psListAppend loweredFields.requests (_root_.List.cons request _root_.List.nil)) })))))
          | Option.none => Except.error (PsIrSpecializeError.unknownTarget structureName))))
    | PsVerifiedIrExpr.projection structureName typeArguments target field => (match psIrSpecializeRewriteTypeListWith rewriteType typeArguments with
      | Except.error error => Except.error error
      | Except.ok loweredTypes => (match rewrite target with
        | Except.error error => Except.error error
        | Except.ok loweredTarget => (match psIrSpecializeFindStructure module.structures structureName with
          | Option.some structureInfo => (match structureInfo.typeParameters with
            | List.nil => Except.ok ({ expr := PsVerifiedIrExpr.projection structureName _root_.List.nil loweredTarget.expr field, requests := psListAppend loweredTypes.requests loweredTarget.requests })
            | _ => (if (!Nat.beq (psListLength structureInfo.typeParameters) (psListLength loweredTypes.types)) then Except.error (PsIrSpecializeError.typeArgumentArity structureName) else (match psIrSpecializedName structureName loweredTypes.types with
              | Option.none => Except.error (PsIrSpecializeError.nonGroundType structureName)
              | Option.some specializedName => (let request : PsIrSpecializeRequest := { kind := PsIrSpecializeKind.structure, name := structureName, arguments := loweredTypes.types }; Except.ok ({ expr := PsVerifiedIrExpr.projection specializedName _root_.List.nil loweredTarget.expr field, requests := psListAppend loweredTypes.requests (psListAppend loweredTarget.requests (_root_.List.cons request _root_.List.nil)) })))))
          | Option.none => Except.error (PsIrSpecializeError.unknownTarget structureName))))
    | PsVerifiedIrExpr.constructor inductiveName constructorName typeArguments fields => (match psIrSpecializeRewriteTypeListWith rewriteType typeArguments with
      | Except.error error => Except.error error
      | Except.ok loweredTypes => (match psIrSpecializeRewriteFieldsWith rewrite fields with
        | Except.error error => Except.error error
        | Except.ok loweredFields => (match psIrSpecializeFindInductive module.inductives inductiveName with
          | Option.some inductiveInfo => (match inductiveInfo.typeParameters with
            | List.nil => Except.ok ({ expr := PsVerifiedIrExpr.constructor inductiveName constructorName _root_.List.nil loweredFields.fields, requests := psListAppend loweredTypes.requests loweredFields.requests })
            | _ => (if (!Nat.beq (psListLength inductiveInfo.typeParameters) (psListLength loweredTypes.types)) then Except.error (PsIrSpecializeError.typeArgumentArity inductiveName) else (match psIrSpecializedName inductiveName loweredTypes.types with
              | Option.none => Except.error (PsIrSpecializeError.nonGroundType inductiveName)
              | Option.some specializedName => (let request : PsIrSpecializeRequest := { kind := PsIrSpecializeKind.inductive, name := inductiveName, arguments := loweredTypes.types }; Except.ok ({ expr := PsVerifiedIrExpr.constructor specializedName constructorName _root_.List.nil loweredFields.fields, requests := psListAppend loweredTypes.requests (psListAppend loweredFields.requests (_root_.List.cons request _root_.List.nil)) })))))
          | Option.none => Except.error (PsIrSpecializeError.unknownTarget inductiveName))))
    | PsVerifiedIrExpr.matchE inductiveName typeArguments scrutinee alternatives => (match psIrSpecializeRewriteTypeListWith rewriteType typeArguments with
      | Except.error error => Except.error error
      | Except.ok loweredTypes => (match rewrite scrutinee with
        | Except.error error => Except.error error
        | Except.ok loweredScrutinee => (match psIrSpecializeRewriteAlternativesWith rewrite module substitution alternatives with
          | Except.error error => Except.error error
          | Except.ok loweredAlternatives => (match psIrSpecializeFindInductive module.inductives inductiveName with
            | Option.some inductiveInfo => (match inductiveInfo.typeParameters with
              | List.nil => Except.ok ({ expr := PsVerifiedIrExpr.matchE inductiveName _root_.List.nil loweredScrutinee.expr loweredAlternatives.alternatives, requests := psListAppend loweredTypes.requests (psListAppend loweredScrutinee.requests loweredAlternatives.requests) })
              | _ => (if (!Nat.beq (psListLength inductiveInfo.typeParameters) (psListLength loweredTypes.types)) then Except.error (PsIrSpecializeError.typeArgumentArity inductiveName) else (match psIrSpecializedName inductiveName loweredTypes.types with
                | Option.none => Except.error (PsIrSpecializeError.nonGroundType inductiveName)
                | Option.some specializedName => (let request : PsIrSpecializeRequest := { kind := PsIrSpecializeKind.inductive, name := inductiveName, arguments := loweredTypes.types }; Except.ok ({ expr := PsVerifiedIrExpr.matchE specializedName _root_.List.nil loweredScrutinee.expr loweredAlternatives.alternatives, requests := psListAppend loweredTypes.requests (psListAppend loweredScrutinee.requests (psListAppend loweredAlternatives.requests (_root_.List.cons request _root_.List.nil))) })))))
            | Option.none => Except.error (PsIrSpecializeError.unknownTarget inductiveName))))))

def psIrSpecializeRewriteExpr (module : PsVerifiedIrModule) (substitution : List (Prod String PsVerifiedIrType)) (expression : PsVerifiedIrExpr) : Except PsIrSpecializeError PsIrSpecializeExprResult := psIrSpecializeRewriteExprWithFuel module substitution 4096 expression

def psIrSpecializeRewriteStructureFields (module : PsVerifiedIrModule) (substitution : List (Prod String PsVerifiedIrType)) (_sourceItems : List PsVerifiedIrStructureField) : Except PsIrSpecializeError PsIrSpecializeStructureFieldsResult := match _sourceItems with
  | List.nil => Except.ok ({ fields := _root_.List.nil, requests := _root_.List.nil })
  | List.cons field rest => (match psIrSpecializeRewriteType module substitution field.type with
    | Except.error error => Except.error error
    | Except.ok lowered => (match psIrSpecializeRewriteStructureFields module substitution rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest => Except.ok ({ fields := List.cons (PsVerifiedIrStructureField.mk field.name lowered.type) loweredRest.fields, requests := psListAppend lowered.requests loweredRest.requests })))

def psIrSpecializeRewriteConstructorFields (module : PsVerifiedIrModule) (substitution : List (Prod String PsVerifiedIrType)) (_sourceItems : List PsVerifiedIrConstructorField) : Except PsIrSpecializeError PsIrSpecializeConstructorFieldsResult := match _sourceItems with
  | List.nil => Except.ok ({ fields := _root_.List.nil, requests := _root_.List.nil })
  | List.cons field rest => (match psIrSpecializeRewriteType module substitution field.type with
    | Except.error error => Except.error error
    | Except.ok lowered => (match psIrSpecializeRewriteConstructorFields module substitution rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest => Except.ok ({ fields := List.cons (PsVerifiedIrConstructorField.mk field.name lowered.type) loweredRest.fields, requests := psListAppend lowered.requests loweredRest.requests })))

def psIrSpecializeRewriteConstructors (module : PsVerifiedIrModule) (substitution : List (Prod String PsVerifiedIrType)) (_sourceItems : List PsVerifiedIrConstructor) : Except PsIrSpecializeError PsIrSpecializeConstructorsResult := match _sourceItems with
  | List.nil => Except.ok ({ constructors := _root_.List.nil, requests := _root_.List.nil })
  | List.cons constructorInfo rest => (match psIrSpecializeRewriteConstructorFields module substitution constructorInfo.fields with
    | Except.error error => Except.error error
    | Except.ok lowered => (match psIrSpecializeRewriteConstructors module substitution rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest => Except.ok ({ constructors := List.cons (PsVerifiedIrConstructor.mk constructorInfo.name lowered.fields) loweredRest.constructors, requests := psListAppend lowered.requests loweredRest.requests })))

def psIrSpecializeRewriteImports (module : PsVerifiedIrModule) (_sourceItems : List PsVerifiedIrExternalImport) : Except PsIrSpecializeError PsIrSpecializeImportsResult := match _sourceItems with
  | List.nil => Except.ok ({ imports := _root_.List.nil, requests := _root_.List.nil })
  | List.cons importInfo rest => (match psIrSpecializeRewriteType module _root_.List.nil importInfo.type with
    | Except.error error => Except.error error
    | Except.ok lowered => (match psIrSpecializeRewriteImports module rest with
      | Except.error error => Except.error error
      | Except.ok loweredRest => Except.ok ({ imports := List.cons (PsVerifiedIrExternalImport.mk importInfo.localName importInfo.source importInfo.importedName lowered.type) loweredRest.imports, requests := psListAppend lowered.requests loweredRest.requests })))

def psIrSpecializeSeedStructures (module : PsVerifiedIrModule) (sources : List PsVerifiedIrStructure) : Except PsIrSpecializeError (Prod (List PsVerifiedIrStructure) (List PsIrSpecializeRequest)) := match sources with
  | List.nil => Except.ok (Prod.mk List.nil List.nil)
  | List.cons structureInfo rest => (match psIrSpecializeSeedStructures module rest with
    | Except.error error => Except.error error
    | Except.ok loweredRest => (match structureInfo.typeParameters with
      | List.cons _ _ => Except.ok loweredRest
      | List.nil => (match psIrSpecializeRewriteStructureFields module _root_.List.nil structureInfo.fields with
        | Except.error error => Except.error error
        | Except.ok lowered => Except.ok (Prod.mk (List.cons (PsVerifiedIrStructure.mk structureInfo.name _root_.List.nil lowered.fields) loweredRest.fst) (psListAppend lowered.requests loweredRest.snd)))))

def psIrSpecializeSeedInductives (module : PsVerifiedIrModule) (sources : List PsVerifiedIrInductive) : Except PsIrSpecializeError (Prod (List PsVerifiedIrInductive) (List PsIrSpecializeRequest)) := match sources with
  | List.nil => Except.ok (Prod.mk List.nil List.nil)
  | List.cons inductiveInfo rest => (match psIrSpecializeSeedInductives module rest with
    | Except.error error => Except.error error
    | Except.ok loweredRest => (match inductiveInfo.typeParameters with
      | List.cons _ _ => Except.ok loweredRest
      | List.nil => (match psIrSpecializeRewriteConstructors module _root_.List.nil inductiveInfo.constructors with
        | Except.error error => Except.error error
        | Except.ok lowered => Except.ok (Prod.mk (List.cons (PsVerifiedIrInductive.mk inductiveInfo.name _root_.List.nil lowered.constructors) loweredRest.fst) (psListAppend lowered.requests loweredRest.snd)))))

def psIrSpecializeSeedDeclarations (module : PsVerifiedIrModule) (sources : List PsVerifiedIrDeclaration) : Except PsIrSpecializeError (Prod (List PsVerifiedIrDeclaration) (List PsIrSpecializeRequest)) := match sources with
  | List.nil => Except.ok (Prod.mk List.nil List.nil)
  | List.cons declaration rest => (match psIrSpecializeSeedDeclarations module rest with
    | Except.error error => Except.error error
    | Except.ok loweredRest => (match declaration.typeParameters with
      | List.cons _ _ => Except.ok loweredRest
      | List.nil => (match psIrSpecializeRewriteParameters module _root_.List.nil declaration.parameters with
        | Except.error error => Except.error error
        | Except.ok loweredParameters => (match psIrSpecializeRewriteType module _root_.List.nil declaration.resultType with
          | Except.error error => Except.error error
          | Except.ok loweredResult => (match psIrSpecializeRewriteExpr module _root_.List.nil declaration.body with
            | Except.error error => Except.error error
            | Except.ok loweredBody => Except.ok (Prod.mk (List.cons (PsVerifiedIrDeclaration.mk declaration.name _root_.List.nil loweredParameters.parameters loweredResult.type loweredBody.expr) loweredRest.fst) (psListAppend loweredParameters.requests (psListAppend loweredResult.requests (psListAppend loweredBody.requests loweredRest.snd)))))))))

def psIrSpecializeAppendRequest (state : PsIrSpecializeState) (requests : List PsIrSpecializeRequest) : PsIrSpecializeState := { imports := state.imports, structures := state.structures, inductives := state.inductives, declarations := state.declarations, pending := psListAppend state.pending requests, seen := state.seen }

def psIrSpecializeMarkSeen (state : PsIrSpecializeState) (key : String) : PsIrSpecializeState := { imports := state.imports, structures := state.structures, inductives := state.inductives, declarations := state.declarations, pending := state.pending, seen := List.cons key state.seen }

def psIrSpecializeAddStructure (state : PsIrSpecializeState) (structureInfo : PsVerifiedIrStructure) (requests : List PsIrSpecializeRequest) : PsIrSpecializeState := { imports := state.imports, structures := psListAppend state.structures (_root_.List.cons structureInfo _root_.List.nil), inductives := state.inductives, declarations := state.declarations, pending := psListAppend state.pending requests, seen := state.seen }

def psIrSpecializeAddInductive (state : PsIrSpecializeState) (inductiveInfo : PsVerifiedIrInductive) (requests : List PsIrSpecializeRequest) : PsIrSpecializeState := { imports := state.imports, structures := state.structures, inductives := psListAppend state.inductives (_root_.List.cons inductiveInfo _root_.List.nil), declarations := state.declarations, pending := psListAppend state.pending requests, seen := state.seen }

def psIrSpecializeAddDeclaration (state : PsIrSpecializeState) (declaration : PsVerifiedIrDeclaration) (requests : List PsIrSpecializeRequest) : PsIrSpecializeState := { imports := state.imports, structures := state.structures, inductives := state.inductives, declarations := psListAppend state.declarations (_root_.List.cons declaration _root_.List.nil), pending := psListAppend state.pending requests, seen := state.seen }

def psIrSpecializeProcessStructureWithOrigin (module : PsVerifiedIrModule) (state : PsIrSpecializeState) (request : PsIrSpecializeRequest) : Except PsIrSpecializeError PsIrSpecializeStep := match psIrSpecializeFindStructure module.structures request.name with
  | Option.none => Except.error (PsIrSpecializeError.unknownTarget request.name)
  | Option.some structureInfo => (if (!Nat.beq (psListLength structureInfo.typeParameters) (psListLength request.arguments)) then Except.error (PsIrSpecializeError.typeArgumentArity request.name) else (match psIrSpecializeMakeSubstitution structureInfo.typeParameters request.arguments with
    | Except.error _ => Except.error (PsIrSpecializeError.nonGroundType request.name)
    | Except.ok substitution => (match psIrSpecializedName request.name request.arguments with
      | Option.none => Except.error (PsIrSpecializeError.nonGroundType request.name)
      | Option.some specializedName => (match psIrSpecializeRewriteStructureFields module substitution structureInfo.fields with
        | Except.error error => Except.error error
        | Except.ok lowered => Except.ok (PsIrSpecializeStep.mk (psIrSpecializeAddStructure state (PsVerifiedIrStructure.mk specializedName _root_.List.nil lowered.fields) lowered.requests) (PsIrTransformOrigin.mk PsIrOriginKind.structure specializedName request.name request.arguments PsIrOriginRule.specialization))))))

def psIrSpecializeProcessInductiveWithOrigin (module : PsVerifiedIrModule) (state : PsIrSpecializeState) (request : PsIrSpecializeRequest) : Except PsIrSpecializeError PsIrSpecializeStep := match psIrSpecializeFindInductive module.inductives request.name with
  | Option.none => Except.error (PsIrSpecializeError.unknownTarget request.name)
  | Option.some inductiveInfo => (if (!Nat.beq (psListLength inductiveInfo.typeParameters) (psListLength request.arguments)) then Except.error (PsIrSpecializeError.typeArgumentArity request.name) else (match psIrSpecializeMakeSubstitution inductiveInfo.typeParameters request.arguments with
    | Except.error _ => Except.error (PsIrSpecializeError.nonGroundType request.name)
    | Except.ok substitution => (match psIrSpecializedName request.name request.arguments with
      | Option.none => Except.error (PsIrSpecializeError.nonGroundType request.name)
      | Option.some specializedName => (match psIrSpecializeRewriteConstructors module substitution inductiveInfo.constructors with
        | Except.error error => Except.error error
        | Except.ok lowered => Except.ok (PsIrSpecializeStep.mk (psIrSpecializeAddInductive state (PsVerifiedIrInductive.mk specializedName _root_.List.nil lowered.constructors) lowered.requests) (PsIrTransformOrigin.mk PsIrOriginKind.inductive specializedName request.name request.arguments PsIrOriginRule.specialization))))))

def psIrSpecializeProcessDeclarationWithOrigin (module : PsVerifiedIrModule) (state : PsIrSpecializeState) (request : PsIrSpecializeRequest) : Except PsIrSpecializeError PsIrSpecializeStep := match psIrSpecializeFindDeclaration module.declarations request.name with
  | Option.none => Except.error (PsIrSpecializeError.unknownTarget request.name)
  | Option.some declaration => (if (!Nat.beq (psListLength declaration.typeParameters) (psListLength request.arguments)) then Except.error (PsIrSpecializeError.typeArgumentArity request.name) else (match psIrSpecializeMakeSubstitution declaration.typeParameters request.arguments with
    | Except.error _ => Except.error (PsIrSpecializeError.nonGroundType request.name)
    | Except.ok substitution => (match psIrSpecializedName request.name request.arguments with
      | Option.none => Except.error (PsIrSpecializeError.nonGroundType request.name)
      | Option.some specializedName => (match psIrSpecializeRewriteParameters module substitution declaration.parameters with
        | Except.error error => Except.error error
        | Except.ok loweredParameters => (match psIrSpecializeRewriteType module substitution declaration.resultType with
          | Except.error error => Except.error error
          | Except.ok loweredResult => (match psIrSpecializeRewriteExpr module substitution declaration.body with
            | Except.error error => Except.error error
            | Except.ok loweredBody => Except.ok (PsIrSpecializeStep.mk (psIrSpecializeAddDeclaration state (PsVerifiedIrDeclaration.mk specializedName _root_.List.nil loweredParameters.parameters loweredResult.type loweredBody.expr) (psListAppend loweredParameters.requests (psListAppend loweredResult.requests loweredBody.requests))) (PsIrTransformOrigin.mk PsIrOriginKind.declaration specializedName request.name request.arguments PsIrOriginRule.specialization))))))))

def psIrSpecializeProcessRequestWithOrigin (module : PsVerifiedIrModule) (state : PsIrSpecializeState) (request : PsIrSpecializeRequest) : Except PsIrSpecializeError PsIrSpecializeStep := match request.kind with
  | PsIrSpecializeKind.structure => psIrSpecializeProcessStructureWithOrigin module state request
  | PsIrSpecializeKind.inductive => psIrSpecializeProcessInductiveWithOrigin module state request
  | PsIrSpecializeKind.declaration => psIrSpecializeProcessDeclarationWithOrigin module state request

def psIrSpecializeProcessStructure (module : PsVerifiedIrModule) (state : PsIrSpecializeState) (request : PsIrSpecializeRequest) : Except PsIrSpecializeError PsIrSpecializeState := match psIrSpecializeProcessStructureWithOrigin module state request with
  | Except.error error => Except.error error
  | Except.ok step => Except.ok step.state

def psIrSpecializeProcessInductive (module : PsVerifiedIrModule) (state : PsIrSpecializeState) (request : PsIrSpecializeRequest) : Except PsIrSpecializeError PsIrSpecializeState := match psIrSpecializeProcessInductiveWithOrigin module state request with
  | Except.error error => Except.error error
  | Except.ok step => Except.ok step.state

def psIrSpecializeProcessDeclaration (module : PsVerifiedIrModule) (state : PsIrSpecializeState) (request : PsIrSpecializeRequest) : Except PsIrSpecializeError PsIrSpecializeState := match psIrSpecializeProcessDeclarationWithOrigin module state request with
  | Except.error error => Except.error error
  | Except.ok step => Except.ok step.state

def psIrSpecializeProcessRequest (module : PsVerifiedIrModule) (state : PsIrSpecializeState) (request : PsIrSpecializeRequest) : Except PsIrSpecializeError PsIrSpecializeState := match psIrSpecializeProcessRequestWithOrigin module state request with
  | Except.error error => Except.error error
  | Except.ok step => Except.ok step.state

-- Preserve the original tail-first seed/error order. The original singleton
-- seed functions remain the only per-item transformation mechanism.
def psIrSpecializeSeedDetailed {alpha : Type} (seed : (_ : List alpha) -> Except PsIrSpecializeError (Prod (List alpha) (List PsIrSpecializeRequest))) (name : (_ : alpha) -> String) (phase : String) (values : List alpha) : Except PsIrSpecializeDiagnostic (Prod (List alpha) (List PsIrSpecializeRequest)) := match values with
  | List.nil => Except.ok (Prod.mk _root_.List.nil _root_.List.nil)
  | List.cons value rest => (match psIrSpecializeSeedDetailed seed name phase rest with
    | Except.error diagnostic => Except.error diagnostic
    | Except.ok tail => (match seed (_root_.List.cons value _root_.List.nil) with
      | Except.error error => Except.error (PsIrSpecializeDiagnostic.mk phase (name value) error Option.none)
      | Except.ok head => Except.ok (Prod.mk (psListAppend head.fst tail.fst) (psListAppend head.snd tail.snd))))

structure PsIrSpecializeSchedule where
  requests : List PsIrSpecializeRequest
  scheduled : PsStringSet
  duplicates : Nat

-- Keep the first occurrence and leave every malformed key in the queue so it
-- refuses at its original first-error position. No declaration is filtered.
def psIrSpecializeScheduleWorker (requests : List PsIrSpecializeRequest) : (_ : PsStringSet) -> (_ : List PsIrSpecializeRequest) -> (_ : Nat) -> PsIrSpecializeSchedule := match requests with
  | List.nil => (fun (scheduled : PsStringSet) (reversed : List PsIrSpecializeRequest) (duplicates : Nat) => PsIrSpecializeSchedule.mk (psListReverse reversed) scheduled duplicates)
  | List.cons request rest => (fun (scheduled : PsStringSet) (reversed : List PsIrSpecializeRequest) (duplicates : Nat) => let smaller : (_ : PsStringSet) -> (_ : List PsIrSpecializeRequest) -> (_ : Nat) -> PsIrSpecializeSchedule := psIrSpecializeScheduleWorker rest; match psIrSpecializeRequestKey request with
    | Option.none => smaller scheduled (List.cons request reversed) duplicates
    | Option.some key => (let added : Prod Bool PsStringSet := psStringSetAdd scheduled key; if added.fst then smaller added.snd (List.cons request reversed) duplicates else smaller scheduled reversed (Nat.succ duplicates)))

def psIrSpecializeScheduleRequests (requests : List PsIrSpecializeRequest) (scheduled : PsStringSet) : PsIrSpecializeSchedule := psIrSpecializeScheduleWorker requests scheduled _root_.List.nil 0

-- Request processing only appends dependencies; it never reads
-- the queue. Retain the old tail separately and capture exactly
-- the newly produced dependency batch.
def psIrSpecializeScheduledLoopWithOrigins (module : PsVerifiedIrModule) (depth : Nat) (tracing : Bool) : (_ : PsIrSpecializeState) -> (_ : PsStringSet) -> (_ : List PsIrTransformOrigin) -> Except PsIrSpecializeDiagnostic PsIrSpecializeRun := match depth with
  | Nat.zero => (fun (state : PsIrSpecializeState) (_scheduled : PsStringSet) (_origins : List PsIrTransformOrigin) => Except.error (PsIrSpecializeDiagnostic.mk "request-loop" (String.Internal.append "processed=" (String.Internal.append (psNatToString (psListLength state.seen)) (String.Internal.append " pending=" (psNatToString (psListLength state.pending))))) PsIrSpecializeError.fuelExhausted Option.none))
  | Nat.succ fuel => (fun (state : PsIrSpecializeState) (scheduled : PsStringSet) (origins : List PsIrTransformOrigin) => let smaller : (_ : PsIrSpecializeState) -> (_ : PsStringSet) -> (_ : List PsIrTransformOrigin) -> Except PsIrSpecializeDiagnostic PsIrSpecializeRun := psIrSpecializeScheduledLoopWithOrigins module fuel tracing; match state.pending with
    | List.nil => Except.ok (PsIrSpecializeRun.mk state origins)
    | List.cons request rest => (match psIrSpecializeRequestKey request with
      | Option.none => Except.error (PsIrSpecializeDiagnostic.mk "request-key" request.name (PsIrSpecializeError.nonGroundType request.name) Option.none)
      | Option.some key => (let isolated : PsIrSpecializeState := PsIrSpecializeState.mk state.imports state.structures state.inductives state.declarations _root_.List.nil state.seen; let marked : PsIrSpecializeState := psIrSpecializeMarkSeen isolated key; match psIrSpecializeProcessRequestWithOrigin module marked request with
        | Except.error error => Except.error (PsIrSpecializeDiagnostic.mk "process-request" request.name error (Option.some key))
        | Except.ok step => (let next : PsIrSpecializeState := step.state; let added : PsIrSpecializeSchedule := psIrSpecializeScheduleRequests next.pending scheduled; let combined : PsIrSpecializeState := PsIrSpecializeState.mk next.imports next.structures next.inductives next.declarations (psListAppend rest added.requests) next.seen; smaller combined added.scheduled (if tracing then List.cons step.origin origins else origins)))))

def psIrSpecializeLoopDetailedWithOrigins (module : PsVerifiedIrModule) (depth : Nat) (state : PsIrSpecializeState) (tracing : Bool) : Except PsIrSpecializeDiagnostic PsIrSpecializeRun := match depth with
  | Nat.zero => Except.error (PsIrSpecializeDiagnostic.mk "request-loop" "" PsIrSpecializeError.fuelExhausted Option.none)
  | Nat.succ _ => (let initial : PsIrSpecializeSchedule := psIrSpecializeScheduleRequests state.pending (psStringSetFromList state.seen); let prepared : PsIrSpecializeState := PsIrSpecializeState.mk state.imports state.structures state.inductives state.declarations initial.requests state.seen; psIrSpecializeScheduledLoopWithOrigins module depth tracing prepared initial.scheduled (if tracing then psListReverse (psIrRetainedOrigins (PsVerifiedIrModule.mk state.imports state.structures state.inductives state.declarations)) else _root_.List.nil))

def psIrSpecializeScheduledLoop (module : PsVerifiedIrModule) (depth : Nat) (state : PsIrSpecializeState) (scheduled : PsStringSet) : Except PsIrSpecializeDiagnostic PsIrSpecializeState := match psIrSpecializeScheduledLoopWithOrigins module depth false state scheduled _root_.List.nil with
  | Except.error diagnostic => Except.error diagnostic
  | Except.ok result => Except.ok result.state

def psIrSpecializeLoopDetailed (module : PsVerifiedIrModule) (depth : Nat) (state : PsIrSpecializeState) : Except PsIrSpecializeDiagnostic PsIrSpecializeState := match psIrSpecializeLoopDetailedWithOrigins module depth state false with
  | Except.error diagnostic => Except.error diagnostic
  | Except.ok result => Except.ok result.state

def psIrSpecializeLoop (module : PsVerifiedIrModule) (depth : Nat) (state : PsIrSpecializeState) : Except PsIrSpecializeError PsIrSpecializeState := match psIrSpecializeLoopDetailed module depth state with
  | Except.error diagnostic => Except.error diagnostic.error
  | Except.ok result => Except.ok result

def psIrSpecializeModuleDetailedWithMode (module : PsVerifiedIrModule) (tracing : Bool) : Except PsIrSpecializeDiagnostic PsIrTracedModule := match psIrSpecializeRewriteImports module module.imports with
  | Except.error error => Except.error (PsIrSpecializeDiagnostic.mk "imports" "" error Option.none)
  | Except.ok imports => (match psIrSpecializeSeedDetailed (fun (values : List PsVerifiedIrStructure) => psIrSpecializeSeedStructures module values) (fun (value : PsVerifiedIrStructure) => value.name) "seed-structure" module.structures with
    | Except.error diagnostic => Except.error diagnostic
    | Except.ok structures => (match psIrSpecializeSeedDetailed (fun (values : List PsVerifiedIrInductive) => psIrSpecializeSeedInductives module values) (fun (value : PsVerifiedIrInductive) => value.name) "seed-inductive" module.inductives with
      | Except.error diagnostic => Except.error diagnostic
      | Except.ok inductives => (match psIrSpecializeSeedDetailed (fun (values : List PsVerifiedIrDeclaration) => psIrSpecializeSeedDeclarations module values) (fun (value : PsVerifiedIrDeclaration) => value.name) "seed-declaration" module.declarations with
        | Except.error diagnostic => Except.error diagnostic
        | Except.ok declarations => (let initial : PsIrSpecializeState := PsIrSpecializeState.mk imports.imports structures.fst inductives.fst declarations.fst (psListAppend imports.requests (psListAppend structures.snd (psListAppend inductives.snd declarations.snd))) _root_.List.nil; match psIrSpecializeLoopDetailedWithOrigins module 16384 initial tracing with
          | Except.error diagnostic => Except.error diagnostic
          | Except.ok final => Except.ok (PsIrTracedModule.mk (PsVerifiedIrModule.mk final.state.imports final.state.structures final.state.inductives final.state.declarations) (psListReverse final.reversedOrigins))))))

def psIrSpecializeModuleDetailedWithOrigins (module : PsVerifiedIrModule) : Except PsIrSpecializeDiagnostic PsIrTracedModule := psIrSpecializeModuleDetailedWithMode module true

def psIrSpecializeModuleDetailed (module : PsVerifiedIrModule) : Except PsIrSpecializeDiagnostic PsVerifiedIrModule := match psIrSpecializeModuleDetailedWithMode module false with
  | Except.error diagnostic => Except.error diagnostic
  | Except.ok result => Except.ok result.raw

def psIrSpecializeModule (module : PsVerifiedIrModule) : Except PsIrSpecializeError PsVerifiedIrModule := match psIrSpecializeModuleDetailed module with
  | Except.error diagnostic => Except.error diagnostic.error
  | Except.ok result => Except.ok result

-- A public raw wrapper is not itself an authority token. Validate the exact
-- input AND the transformed output, including traversal-budget completion.
-- This establishes bounded typing, not semantic equivalence of specialization.
def psIrSpecializeRecheck (raw : PsVerifiedIrModule) (isInput : Bool) : Except PsIrSpecializeError Unit := let report := psCheckVerifiedIrModule psIrCheckDefaultOptions raw; if (!report.traversalComplete) then Except.error PsIrSpecializeError.validationBudgetExhausted else (if (!report.accepted) then (if isInput then Except.error PsIrSpecializeError.inputValidationFailed else Except.error PsIrSpecializeError.outputValidationFailed) else Except.ok ())

def psIrSpecializeValidatedModuleWithMode (validated : PsValidatedIrModule) (tracing : Bool) : Except PsIrSpecializeDiagnostic PsIrTracedModule := match psIrSpecializeRecheck validated.raw true with
  | Except.error error => Except.error (PsIrSpecializeDiagnostic.mk "validation-input" "" error Option.none)
  | Except.ok _ => (match psIrSpecializeModuleDetailedWithMode validated.raw tracing with
    | Except.error diagnostic => Except.error diagnostic
    | Except.ok raw => (match psIrSpecializeRecheck raw.raw false with
      | Except.error error => Except.error (PsIrSpecializeDiagnostic.mk "validation-output" "" error Option.none)
      | Except.ok _ => Except.ok raw))

def psIrSpecializeValidatedModuleWithOrigins (validated : PsValidatedIrModule) : Except PsIrSpecializeDiagnostic PsIrTracedModule := psIrSpecializeValidatedModuleWithMode validated true

def psIrSpecializeValidatedModuleDetailed (validated : PsValidatedIrModule) : Except PsIrSpecializeDiagnostic PsSpecializedIrModule := match psIrSpecializeValidatedModuleWithMode validated false with
  | Except.error diagnostic => Except.error diagnostic
  | Except.ok result => Except.ok (PsSpecializedIrModule.mk result.raw)

def psIrSpecializeValidatedModule (validated : PsValidatedIrModule) : Except PsIrSpecializeError PsSpecializedIrModule := match psIrSpecializeValidatedModuleDetailed validated with
  | Except.error diagnostic => Except.error diagnostic.error
  | Except.ok result => Except.ok result

def psIrSpecializeUniformValidatedModule (validated : PsValidatedIrModule) : Except PsIrSpecializeError PsUniformSpecializedIrModule := match psIrSpecializeValidatedModuleDetailed validated with
  | Except.error diagnostic => Except.error diagnostic.error
  | Except.ok result => Except.ok (PsUniformSpecializedIrModule.mk result.raw)
