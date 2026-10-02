import Ps.Foundation.List
import Ps.Foundation.Name
import Ps.CompilerIr.Model
import Ps.Bridge.Json

inductive PsTsEmitError where
  | fuelExhausted
  | unsupportedIntrinsic
  | intrinsicArity
  | unknownStructure (name : String)
  | unknownInductive (name : String)
  | genericValueUnsupported (name : String)
  | targetWordSizeRequired

def psTsJoin (separator : String) (values : List String) : String :=
  match values with
  | List.nil => ""
  | List.cons value rest =>
      match rest with
      | List.nil => value
      | List.cons _ _ =>
          String.Internal.append value (String.Internal.append separator (psTsJoin separator rest))


def psTsEmitPrimitiveType
    (type : PsVerifiedIrPrimitiveType) : String :=
  match type with
  | .nat => "bigint"
  | .int => "bigint"
  | .uint8 => "number"
  | .uint16 => "number"
  | .uint32 => "number"
  | .uint64 => "bigint"
  | .usize => "bigint"
  | .int8 => "number"
  | .int16 => "number"
  | .int32 => "number"
  | .int64 => "bigint"
  | .isize => "bigint"
  | .float => "number"
  | .float32 => "number"
  | .bool => "boolean"
  | .char => "string"
  | .string => "string"
  | .unit => "undefined"

def psTsIndexTypesWorker (values : List String) : Nat -> List String :=
  match values with
  | List.nil => fun (_index : Nat) => List.nil
  | List.cons value rest =>
      let smaller : Nat -> List String := psTsIndexTypesWorker rest;
      fun (index : Nat) =>
        List.cons (psTsJoin "" ["_arg", psNatToString index, ": ", value]) (smaller (Nat.succ index))

def psTsIndexTypes (index : Nat) (values : List String) : List String :=
  psTsIndexTypesWorker values index

def psTsEmitTypeWithFuel (fuel : Nat) : PsVerifiedIrType -> Except PsTsEmitError String :=
  match fuel with
  | Nat.zero => fun (_type : PsVerifiedIrType) => Except.error PsTsEmitError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrType -> Except PsTsEmitError String := psTsEmitTypeWithFuel remaining;
      fun (type : PsVerifiedIrType) =>
        match type with
        | .unknown => Except.ok "unknown"
        | .typeParameter name => Except.ok name
        | .primitive primitive => Except.ok (psTsEmitPrimitiveType primitive)
        | .function parameters result =>
            match psListMapExcept smaller parameters with
            | Except.error error => Except.error error
            | Except.ok printedParameters =>
                match smaller result with
                | Except.error error => Except.error error
                | Except.ok printedResult =>
                    let indexed := psTsIndexTypes 0 printedParameters;
                    Except.ok (psTsJoin "" ["(", psTsJoin ", " indexed, ") => ", printedResult])
        | .named name arguments =>
            match psListMapExcept smaller arguments with
            | Except.error error => Except.error error
            | Except.ok printedArguments =>
                if psListIsEmpty printedArguments then Except.ok name
                else Except.ok (psTsJoin "" [name, "<", psTsJoin ", " printedArguments, ">"])


def psTsEmitType
    (type : PsVerifiedIrType) :
    Except PsTsEmitError String :=
  psTsEmitTypeWithFuel 4096 type

def psTsMachineIntegerUsesBigInt (type : PsVerifiedIrMachineIntegerType) : Bool :=
  match type with
  | .uint64 => true
  | .int64 => true
  | .usize => true
  | .isize => true
  | _ => false

def psTsEmitLiteral
    (literal : PsVerifiedIrLiteral) :
    Except PsTsEmitError String :=
  match literal with
  | .natural value => Except.ok (String.Internal.append (psNatToString value) "n")
  | .integer value => Except.ok (String.Internal.append (Int.repr value) "n")
  | .machineInteger type value =>
      match type with
      | .usize => Except.error PsTsEmitError.targetWordSizeRequired
      | .isize => Except.error PsTsEmitError.targetWordSizeRequired
      | _ =>
          if psTsMachineIntegerUsesBigInt type then
            Except.ok (String.Internal.append (Int.repr value) "n")
          else
            Except.ok (Int.repr value)
  | .string value => Except.ok (psJsonQuote value)
  | .bool value =>
      if value then Except.ok "true" else Except.ok "false"
  | .unit => Except.ok "undefined"
