import Ps.CompilerIr.Specialize
import Ps.BackendWasm.Model

inductive PsWasmTranslationValidationError where
  | unsupportedSlice
  | missingFunction (name : String)
  | functionMismatch (name : String)
  | missingExport (name : String)

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
          | PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32 =>
              match declaration.body with
              | PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.machineInteger
                    PsVerifiedIrMachineIntegerType.uint32
                    value) =>
                  Option.some (PsWasmLiteralExpectation.i32 value)
              | _ =>
                  Option.none
          | PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int32 =>
              match declaration.body with
              | PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.machineInteger
                    PsVerifiedIrMachineIntegerType.int32
                    value) =>
                  Option.some (PsWasmLiteralExpectation.i32 value)
              | _ =>
                  Option.none
          | PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool =>
              match declaration.body with
              | PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.bool value) =>
                  if value then
                    Option.some
                      (PsWasmLiteralExpectation.i32 1)
                  else
                    Option.some
                      (PsWasmLiteralExpectation.i32 0)
              | _ =>
                  Option.none
          | _ =>
              Option.none

def psWasmValidationFunctionMatches
    (expectation : PsWasmLiteralExpectation)
    (function : PsWasmFunction) :
    Bool :=
  match expectation with
  | PsWasmLiteralExpectation.i32 expected =>
      match function with
      | {
          typeName := Option.none
          parameters := List.nil
          results := [PsWasmValueType.i32]
          locals := List.nil
          body := [PsWasmInstruction.i32Const actual]
          ..
        } =>
          psStringEq (Int.repr expected) (Int.repr actual)
      | _ =>
          false

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

def psWasmValidateSpecializedLiteralModule
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
