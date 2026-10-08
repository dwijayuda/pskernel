import Ps.CompilerIr.Specialize
import Ps.CompilerIr.Validate
import Ps.BackendWasm.Model

inductive PsWasmTranslationValidationError where
  | unsupportedSlice
  | missingFunction (name : String)
  | functionMismatch (name : String)
  | missingExport (name : String)
  | invalidSource (error : PsVerifiedIrValidationError)
  | targetShapeMismatch

inductive PsWasmLiteralExpectation where
  | i32 (value : Int)

def psWasmValidationFindFunction
    (name : String)
    (functions : List PsWasmFunction) :
    Option PsWasmFunction :=
  match functions with
  | List.nil =>
      Option.none
  | List.cons function rest =>
      if psStringEq function.name name then
        Option.some function
      else
        psWasmValidationFindFunction name rest

def psWasmValidationHasExport
    (name : String)
    (exports : List (String × String)) :
    Bool :=
  match exports with
  | List.nil =>
      false
  | List.cons item rest =>
      if psStringEq (Prod.fst item) name then
        if psStringEq (Prod.snd item) name then
          true
        else
          psWasmValidationHasExport name rest
      else
        psWasmValidationHasExport name rest

def psWasmValidationMachineKindMatches
    (primitive : PsVerifiedIrPrimitiveType)
    (kind : PsVerifiedIrMachineIntegerType) : Bool :=
  match primitive with
  | .uint32 =>
      match kind with
      | .uint32 => true
      | _ => false
  | .int32 =>
      match kind with
      | .int32 => true
      | _ => false
  | _ => false

def psWasmValidationLiteralBody
    (primitive : PsVerifiedIrPrimitiveType)
    (body : PsVerifiedIrExpr) : Option PsWasmLiteralExpectation :=
  match body with
  | .literal literal =>
      match literal with
      | .machineInteger kind value =>
          if psWasmValidationMachineKindMatches primitive kind then
            Option.some (PsWasmLiteralExpectation.i32 value)
          else Option.none
      | .bool value =>
          match primitive with
          | .bool =>
              if value then Option.some (PsWasmLiteralExpectation.i32 1)
              else Option.some (PsWasmLiteralExpectation.i32 0)
          | _ => Option.none
      | _ => Option.none
  | _ => Option.none

def psWasmValidationLiteralExpectation
    (declaration : PsVerifiedIrDeclaration) :
    Option PsWasmLiteralExpectation :=
  match declaration.typeParameters with
  | List.cons _ _ =>
      Option.none
  | List.nil =>
      match declaration.parameters with
      | List.cons _ _ =>
          Option.none
      | List.nil =>
          match declaration.resultType with
          | .primitive primitive =>
              psWasmValidationLiteralBody primitive declaration.body
          | _ =>
              Option.none

def psWasmValidationI32Result (results : List PsWasmValueType) : Bool :=
  match results with
  | List.nil => false
  | List.cons result rest =>
      if psListIsEmpty rest then
        match result with
        | .i32 => true
        | _ => false
      else false

def psWasmValidationI32Body (expected : Int) (body : List PsWasmInstruction) : Bool :=
  match body with
  | List.nil => false
  | List.cons instruction rest =>
      if psListIsEmpty rest then
        match instruction with
        | .i32Const actual => psStringEq (Int.repr expected) (Int.repr actual)
        | _ => false
      else false

def psWasmValidationFunctionMatches
    (expectation : PsWasmLiteralExpectation)
    (function : PsWasmFunction) :
    Bool :=
  match expectation with
  | PsWasmLiteralExpectation.i32 expected =>
      match function.typeName with
      | Option.some _ => false
      | Option.none =>
          if psListIsEmpty function.parameters then
            if psListIsEmpty function.locals then
              if psWasmValidationI32Result function.results then
                psWasmValidationI32Body expected function.body
              else false
            else false
          else false

def psWasmValidateLiteralDeclaration
    (target : PsWasmModule)
    (declaration : PsVerifiedIrDeclaration) :
    Except PsWasmTranslationValidationError Unit :=
  match psWasmValidationLiteralExpectation declaration with
  | Option.none =>
      Except.error
        PsWasmTranslationValidationError.unsupportedSlice
  | Option.some expectation =>
      match
          psWasmValidationFindFunction
            declaration.name
            target.functions with
      | Option.none =>
          Except.error
            (PsWasmTranslationValidationError.missingFunction
              declaration.name)
      | Option.some function =>
          if psWasmValidationFunctionMatches expectation function then
            if
                psWasmValidationHasExport
                  declaration.name
                  target.exports then
              Except.ok Unit.unit
            else
              Except.error
                (PsWasmTranslationValidationError.missingExport
                  declaration.name)
          else
            Except.error
              (PsWasmTranslationValidationError.functionMismatch
                declaration.name)

def psWasmValidateLiteralDeclarations
    (target : PsWasmModule)
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsWasmTranslationValidationError Unit :=
  match declarations with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons declaration rest =>
      match
          psWasmValidateLiteralDeclaration
            target
            declaration with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psWasmValidateLiteralDeclarations
            target
            rest

def psWasmValidationFunctionName (function : PsWasmFunction) : String := function.name

def psWasmValidationExportName (item : Prod String String) : String := Prod.fst item

def psWasmValidationClosedTarget (source : PsVerifiedIrModule) (target : PsWasmModule) : Bool :=
  if psListIsEmpty target.structures then
    if psListIsEmpty target.arrays then
      if psListIsEmpty target.functionTypes then
        if psListIsEmpty target.functionRefs then
          if Nat.beq (psListLength target.functions) (psListLength source.declarations) then
            if Nat.beq (psListLength target.exports) (psListLength source.declarations) then
              if psStrictStringListUnique (psListMap psWasmValidationFunctionName target.functions) then
                psStrictStringListUnique (psListMap psWasmValidationExportName target.exports)
              else false
            else false
          else false
        else false
      else false
    else false
  else false

def psWasmValidateSpecializedLiteralShape
    (source : PsSpecializedIrModule)
    (target : PsWasmModule) :
    Except PsWasmTranslationValidationError Unit :=
  match source.raw.imports with
  | List.cons _ _ =>
      Except.error
        PsWasmTranslationValidationError.unsupportedSlice
  | List.nil =>
      match source.raw.structures with
      | List.cons _ _ =>
          Except.error
            PsWasmTranslationValidationError.unsupportedSlice
      | List.nil =>
          match source.raw.inductives with
          | List.cons _ _ =>
              Except.error
                PsWasmTranslationValidationError.unsupportedSlice
          | List.nil =>
              psWasmValidateLiteralDeclarations
                target
                source.raw.declarations

-- The public wrapper may be constructed by an untrusted producer. Recheck
-- source invariants, and reject duplicate/extra target definitions or exports.
def psWasmValidateSpecializedLiteralModule
    (source : PsSpecializedIrModule) (target : PsWasmModule) :
    Except PsWasmTranslationValidationError Unit :=
  match psStrictValidateModule source.raw with
  | Except.error error => Except.error (PsWasmTranslationValidationError.invalidSource error)
  | Except.ok _ =>
      if psWasmValidationClosedTarget source.raw target then psWasmValidateSpecializedLiteralShape source target
      else Except.error PsWasmTranslationValidationError.targetShapeMismatch
