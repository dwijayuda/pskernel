import Ps.BackendWasm.Binary

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

def psWasmLowerExprListWithFuel
    (profile : PsWasmTargetProfile)
    (parameters : List PsVerifiedIrParameter)
    (fuel : Nat) :
    List PsVerifiedIrExpr ->
    Except PsWasmLowerError (List PsWasmInstruction)
  | [] => Except.ok []
  | expr :: rest =>
      match psWasmLowerExprWithFuel profile parameters fuel expr with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerExprListWithFuel profile parameters fuel rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered ++ loweredRest)

def psWasmLowerIntrinsicWithFuel
    (profile : PsWasmTargetProfile)
    (parameters : List PsVerifiedIrParameter)
    (fuel : Nat)
    (operation : PsVerifiedIrIntrinsic)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError (List PsWasmInstruction) :=
  match operation with
  | .machineIntBinary type integerOperation =>
      match arguments with
      | [left, right] =>
          match psWasmLowerExprListWithFuel
              profile parameters fuel [left, right] with
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
          match psWasmLowerExprListWithFuel
              profile parameters fuel [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok
                (lowered ++
                  psWasmLowerMachineIntegerCompare
                    profile type integerOperation)
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity
  | _ => Except.error PsWasmLowerError.unsupportedIntrinsic

def psWasmLowerCallWithFuel
    (profile : PsWasmTargetProfile)
    (parameters : List PsVerifiedIrParameter)
    (fuel : Nat)
    (fn : PsVerifiedIrExpr)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError (List PsWasmInstruction) :=
  match fn with
  | .var name =>
      match psWasmLowerExprListWithFuel
          profile parameters fuel arguments with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok (lowered ++ [PsWasmInstruction.call name])
  | _ => Except.error PsWasmLowerError.unsupportedExpression

def psWasmLowerExprWithFuel
    (profile : PsWasmTargetProfile)
    (parameters : List PsVerifiedIrParameter) :
    Nat -> PsVerifiedIrExpr ->
    Except PsWasmLowerError (List PsWasmInstruction)
  | 0, _ => Except.error PsWasmLowerError.unsupportedExpression
  | fuel + 1, expr =>
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
          psWasmLowerIntrinsicWithFuel
            profile parameters fuel operation arguments
      | .call fn _ arguments =>
          psWasmLowerCallWithFuel
            profile parameters fuel fn arguments
      | _ => Except.error PsWasmLowerError.unsupportedExpression

def psWasmLowerExpr
    (profile : PsWasmTargetProfile)
    (parameters : List PsVerifiedIrParameter)
    (expr : PsVerifiedIrExpr) :
    Except PsWasmLowerError (List PsWasmInstruction) :=
  psWasmLowerExprWithFuel profile parameters 4096 expr

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
          match psWasmLowerExpr
              profile declaration.parameters declaration.body with
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
