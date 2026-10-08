import Ps.BackendWasm.Validate
import Ps.Bridge.Json

inductive PsWasmLiteralEvidenceError where
  | invalidSource (error : PsVerifiedIrValidationError)
  | unsupportedSlice
  | encoding (error : PsJsonEncodeError)

def psWasmLiteralScalarName (type : PsVerifiedIrType) : Option String :=
  match type with
  | .primitive primitive =>
      match primitive with
      | .uint32 => Option.some "uint32"
      | .int32 => Option.some "int32"
      | .bool => Option.some "bool"
      | _ => Option.none
  | _ => Option.none

def psWasmLiteralExpectationEntry (declaration : PsVerifiedIrDeclaration) : Except PsWasmLiteralEvidenceError PsJsonValue :=
  match psWasmValidationLiteralExpectation declaration with
  | Option.none => Except.error PsWasmLiteralEvidenceError.unsupportedSlice
  | Option.some expectation =>
      match psWasmLiteralScalarName declaration.resultType with
      | Option.none => Except.error PsWasmLiteralEvidenceError.unsupportedSlice
      | Option.some type =>
          match expectation with
          | .i32 value => Except.ok (PsJsonValue.object [
              Prod.mk "name" (PsJsonValue.string declaration.name),
              Prod.mk "type" (PsJsonValue.string type),
              Prod.mk "value" (PsJsonValue.string (Int.repr value))])

-- Compute the binary checker's expectation from actual strictly validated
-- source declarations. No caller-supplied assertion of the expected values is
-- used. A host must still bind this operation's exact source/output artifacts.
def psWasmEncodeLiteralExpectation (source : PsSpecializedIrModule) : Except PsWasmLiteralEvidenceError String :=
  match psStrictValidateModule source.raw with
  | Except.error error => Except.error (PsWasmLiteralEvidenceError.invalidSource error)
  | Except.ok _ =>
      if psListIsEmpty source.raw.imports then
        if psListIsEmpty source.raw.structures then
          if psListIsEmpty source.raw.inductives then
            match psListMapExcept psWasmLiteralExpectationEntry source.raw.declarations with
            | Except.error error => Except.error error
            | Except.ok entries =>
                match psJsonEncodeCanonical (PsJsonValue.object [
                    Prod.mk "contract" (PsJsonValue.string "psc-wasm-literal-expectation/1"),
                    Prod.mk "exports" (PsJsonValue.array entries)]) with
                | Except.error error => Except.error (PsWasmLiteralEvidenceError.encoding error)
                | Except.ok text => Except.ok text
          else Except.error PsWasmLiteralEvidenceError.unsupportedSlice
        else Except.error PsWasmLiteralEvidenceError.unsupportedSlice
      else Except.error PsWasmLiteralEvidenceError.unsupportedSlice
