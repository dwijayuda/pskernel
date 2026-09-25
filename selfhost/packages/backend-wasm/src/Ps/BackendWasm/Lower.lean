import Ps.BackendWasm.Binary
import Ps.BackendWasm.LowerInt
import Ps.BackendWasm.LowerFloat

inductive PsWasmLowerError where
  | unsupportedType
  | unsupportedExpression
  | unsupportedIntrinsic
  | invalidIntrinsicArity
  | unknownVariable (name : String)
  | unsupportedModuleFeature

def psWasmLowerParameterType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrType) :
    Except PsWasmLowerError PsWasmValueType :=
  match type with
  | .primitive primitive =>
      match psWasmValueTypeOfPrimitive profile primitive with
      | .noValue => Except.error PsWasmLowerError.unsupportedType
      | .refT _ => Except.error PsWasmLowerError.unsupportedType
      | valueType => Except.ok valueType
  | _ => Except.error PsWasmLowerError.unsupportedType

def psWasmLowerResultType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrType) :
    Except PsWasmLowerError (List PsWasmValueType) :=
  match type with
  | .primitive .unit => Except.ok []
  | .primitive primitive =>
      match psWasmValueTypeOfPrimitive profile primitive with
      | .noValue => Except.ok []
      | .refT _ => Except.error PsWasmLowerError.unsupportedType
      | valueType => Except.ok [valueType]
  | _ => Except.error PsWasmLowerError.unsupportedType

def psWasmLowerParameterTypes
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrParameter ->
    Except PsWasmLowerError (List PsWasmValueType)
  | [] => Except.ok []
  | parameter :: rest =>
      match psWasmLowerParameterType profile parameter.type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerParameterTypes profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered :: loweredRest)

def psWasmExpectedResultType :
    List PsWasmValueType ->
    Except PsWasmLowerError (Option PsWasmValueType)
  | [] => Except.ok none
  | [result] => Except.ok (some result)
  | _ => Except.error PsWasmLowerError.unsupportedType

def psWasmMachineIntegerValueType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType) :
    PsWasmValueType :=
  if psWasmMachineIntegerIs64 profile type then
    .i64
  else
    .i32

def psWasmFloatingValueType
    (type : PsVerifiedIrFloatingType) :
    PsWasmValueType :=
  match type with
  | .float32 => .f32
  | .float => .f64

def psWasmFindParameterIndexLoop
    (name : String) :
    Nat -> List PsVerifiedIrParameter -> Option Nat
  | _, [] => none
  | index, parameter :: rest =>
      if parameter.name == name then
        some index
      else
        psWasmFindParameterIndexLoop name (index + 1) rest

def psWasmFindParameterIndex
    (parameters : List PsVerifiedIrParameter)
    (name : String) : Option Nat :=
  psWasmFindParameterIndexLoop name 0 parameters

def psWasmLowerExprListWith
    (lower :
      Option PsWasmValueType ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError (List PsWasmInstruction))
    (expected : Option PsWasmValueType) :
    List PsVerifiedIrExpr ->
    Except PsWasmLowerError (List PsWasmInstruction)
  | [] => Except.ok []
  | expr :: rest =>
      match lower expected expr with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerExprListWith lower expected rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered ++ loweredRest)

def psWasmLowerIntrinsicWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError (List PsWasmInstruction))
    (operation : PsVerifiedIrIntrinsic)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError (List PsWasmInstruction) :=
  match operation with
  | .machineIntBinary type integerOperation =>
      match arguments with
      | [left, right] =>
          let expected :=
            some (psWasmMachineIntegerValueType profile type)
          match psWasmLowerExprListWith
              lower expected [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok
                (lowered ++
                  psWasmLowerMachineIntegerBinary
                    profile type integerOperation)
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity
  | .machineIntCompare type integerOperation =>
      match arguments with
      | [left, right] =>
          let expected :=
            some (psWasmMachineIntegerValueType profile type)
          match psWasmLowerExprListWith
              lower expected [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok
                (lowered ++
                  psWasmLowerMachineIntegerCompare
                    profile type integerOperation)
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity
  | .floatBinary type floatOperation =>
      match arguments with
      | [left, right] =>
          let expected := some (psWasmFloatingValueType type)
          match psWasmLowerExprListWith
              lower expected [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok
                (lowered ++ psWasmLowerFloatBinary type floatOperation)
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity
  | .floatCompare type floatOperation =>
      match arguments with
      | [left, right] =>
          let expected := some (psWasmFloatingValueType type)
          match psWasmLowerExprListWith
              lower expected [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok
                (lowered ++ psWasmLowerFloatCompare type floatOperation)
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity
  | _ => Except.error PsWasmLowerError.unsupportedIntrinsic

def psWasmLowerCallWith
    (lower :
      Option PsWasmValueType ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError (List PsWasmInstruction))
    (fn : PsVerifiedIrExpr)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError (List PsWasmInstruction) :=
  match fn with
  | .var name =>
      match psWasmLowerExprListWith lower none arguments with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok (lowered ++ [PsWasmInstruction.call name])
  | _ => Except.error PsWasmLowerError.unsupportedExpression

def psWasmLowerIfWith
    (lower :
      Option PsWasmValueType ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError (List PsWasmInstruction))
    (expected : Option PsWasmValueType)
    (condition thenBranch elseBranch : PsVerifiedIrExpr) :
    Except PsWasmLowerError (List PsWasmInstruction) :=
  match expected with
  | none => Except.error PsWasmLowerError.unsupportedType
  | some resultType =>
      match lower (some PsWasmValueType.i32) condition with
      | Except.error error => Except.error error
      | Except.ok conditionCode =>
          match lower expected thenBranch with
          | Except.error error => Except.error error
          | Except.ok thenCode =>
              match lower expected elseBranch with
              | Except.error error => Except.error error
              | Except.ok elseCode =>
                  Except.ok
                    (conditionCode
                      ++ [PsWasmInstruction.ifStart (some resultType)]
                      ++ thenCode
                      ++ [PsWasmInstruction.else_]
                      ++ elseCode
                      ++ [PsWasmInstruction.end_])

def psWasmLowerExprWithFuel
    (profile : PsWasmTargetProfile)
    (parameters : List PsVerifiedIrParameter)
    (expected : Option PsWasmValueType) :
    Nat -> PsVerifiedIrExpr ->
    Except PsWasmLowerError (List PsWasmInstruction)
  | 0, _ => Except.error PsWasmLowerError.unsupportedExpression
  | fuel + 1, expr =>
      let lower :=
        fun expectedType nestedExpr =>
          psWasmLowerExprWithFuel
            profile parameters expectedType fuel nestedExpr
      match expr with
      | .literal literal =>
          match literal with
          | .machineInteger type value =>
              Except.ok
                (psWasmLowerMachineIntegerLiteral profile type value)
          | .bool value =>
              Except.ok
                [PsWasmInstruction.i32Const (if value then 1 else 0)]
          | .unit => Except.ok []
          | _ => Except.error PsWasmLowerError.unsupportedExpression
      | .var name =>
          match psWasmFindParameterIndex parameters name with
          | none => Except.error (PsWasmLowerError.unknownVariable name)
          | some index =>
              Except.ok [PsWasmInstruction.localGet index]
      | .intrinsic operation arguments =>
          psWasmLowerIntrinsicWith profile lower operation arguments
      | .call fn _ arguments =>
          psWasmLowerCallWith lower fn arguments
      | .ifE condition thenBranch elseBranch =>
          psWasmLowerIfWith
            lower expected condition thenBranch elseBranch
      | _ => Except.error PsWasmLowerError.unsupportedExpression

def psWasmLowerExpr
    (profile : PsWasmTargetProfile)
    (parameters : List PsVerifiedIrParameter)
    (expected : Option PsWasmValueType)
    (expr : PsVerifiedIrExpr) :
    Except PsWasmLowerError (List PsWasmInstruction) :=
  psWasmLowerExprWithFuel
    profile parameters expected 4096 expr

def psWasmLowerDeclaration
    (profile : PsWasmTargetProfile)
    (declaration : PsVerifiedIrDeclaration) :
    Except PsWasmLowerError PsWasmFunction :=
  match psWasmLowerParameterTypes profile declaration.parameters with
  | Except.error error => Except.error error
  | Except.ok parameters =>
      match psWasmLowerResultType profile declaration.resultType with
      | Except.error error => Except.error error
      | Except.ok results =>
          match psWasmExpectedResultType results with
          | Except.error error => Except.error error
          | Except.ok expected =>
              match psWasmLowerExpr
                  profile
                  declaration.parameters
                  expected
                  declaration.body with
              | Except.error error => Except.error error
              | Except.ok body =>
                  Except.ok
                    {
                      name := declaration.name
                      parameters := parameters
                      results := results
                      body := body
                    }

def psWasmLowerDeclarations
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrDeclaration ->
    Except PsWasmLowerError (List PsWasmFunction)
  | [] => Except.ok []
  | declaration :: rest =>
      match psWasmLowerDeclaration profile declaration with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerDeclarations profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered :: loweredRest)

def psWasmExportsOfDeclarations :
    List PsVerifiedIrDeclaration -> List (String × String)
  | [] => []
  | declaration :: rest =>
      (declaration.name, declaration.name) ::
        psWasmExportsOfDeclarations rest

def psWasmModuleHasUnsupportedData
    (module : PsVerifiedIrModule) : Bool :=
  match module.imports with
  | _ :: _ => true
  | [] =>
      match module.structures with
      | _ :: _ => true
      | [] =>
          match module.inductives with
          | _ :: _ => true
          | [] => false

def psWasmLowerModule
    (profile : PsWasmTargetProfile)
    (module : PsVerifiedIrModule) :
    Except PsWasmLowerError PsWasmModule :=
  if psWasmModuleHasUnsupportedData module then
    Except.error PsWasmLowerError.unsupportedModuleFeature
  else
    match psWasmLowerDeclarations profile module.declarations with
    | Except.error error => Except.error error
    | Except.ok functions =>
        Except.ok
          {
            functions := functions
            exports := psWasmExportsOfDeclarations module.declarations
          }
