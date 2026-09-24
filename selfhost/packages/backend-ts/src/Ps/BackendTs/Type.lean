import Ps.CompilerIr.Model
import Ps.Bridge.Json

inductive PsTsEmitError where
  | fuelExhausted
  | unsupportedIntrinsic
  | intrinsicArity
  | unknownStructure (name : String)
  | unknownInductive (name : String)
  | genericValueUnsupported (name : String)

def psTsJoin (separator : String) : List String -> String
  | [] => ""
  | [value] => value
  | value :: rest =>
      value ++ separator ++ psTsJoin separator rest

def psTsEmitPrimitiveType
    (type : PsVerifiedIrPrimitiveType) : String :=
  match type with
  | .nat => "bigint"
  | .int => "bigint"
  | .bool => "boolean"
  | .char => "string"
  | .string => "string"
  | .unit => "undefined"

def psTsIndexTypes : Nat -> List String -> List String
  | _, [] => []
  | index, value :: rest =>
      ("_arg" ++ toString index ++ ": " ++ value) ::
        psTsIndexTypes (index + 1) rest

def psTsEmitTypeWithFuel :
    Nat -> PsVerifiedIrType -> Except PsTsEmitError String
  | 0, _ => Except.error PsTsEmitError.fuelExhausted
  | fuel + 1, type =>
      match type with
      | .unknown => Except.ok "unknown"
      | .typeParameter name => Except.ok name
      | .primitive primitive =>
          Except.ok (psTsEmitPrimitiveType primitive)
      | .function parameters result =>
          match parameters.mapM (psTsEmitTypeWithFuel fuel) with
          | Except.error error => Except.error error
          | Except.ok printedParameters =>
              match psTsEmitTypeWithFuel fuel result with
              | Except.error error => Except.error error
              | Except.ok printedResult =>
                  let indexed :=
                    psTsIndexTypes 0 printedParameters
                  Except.ok
                    ("(" ++ psTsJoin ", " indexed ++
                      ") => " ++ printedResult)
      | .named name arguments =>
          match arguments.mapM (psTsEmitTypeWithFuel fuel) with
          | Except.error error => Except.error error
          | Except.ok printedArguments =>
              if printedArguments.isEmpty then
                Except.ok name
              else
                Except.ok
                  (name ++ "<" ++
                    psTsJoin ", " printedArguments ++ ">")

def psTsEmitType
    (type : PsVerifiedIrType) :
    Except PsTsEmitError String :=
  psTsEmitTypeWithFuel 4096 type

def psTsEmitLiteral
    (literal : PsVerifiedIrLiteral) : String :=
  match literal with
  | .natural value => toString value ++ "n"
  | .integer value => toString value ++ "n"
  | .string value => psJsonQuote value
  | .bool value => if value then "true" else "false"
  | .unit => "undefined"
