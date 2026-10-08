import Ps.CompilerIr.Interface
import Ps.Bridge.Json

inductive PsJsAbiError where
  | interfaceError (error : PsInterfaceIrError)
  | unsupportedTarget
  | invalidWordSize
  | unsupportedImport (name : String)

def psJsAbiPrimitiveName (type : PsVerifiedIrPrimitiveType) : String :=
  match type with
  | .nat => "nat"
  | .int => "int"
  | .uint8 => "uint8"
  | .uint16 => "uint16"
  | .uint32 => "uint32"
  | .uint64 => "uint64"
  | .usize => "usize"
  | .int8 => "int8"
  | .int16 => "int16"
  | .int32 => "int32"
  | .int64 => "int64"
  | .isize => "isize"
  | .float => "float"
  | .float32 => "float32"
  | .bool => "bool"
  | .char => "char"
  | .string => "string"
  | .unit => "unit"

def psJsAbiScalar (name : String) (type : PsVerifiedIrType) : Except PsJsAbiError String :=
  match type with
  | .primitive primitive => Except.ok (psJsonQuote (psJsAbiPrimitiveName primitive))
  | _ => Except.error (PsJsAbiError.unsupportedImport name)

def psJsAbiImportJson (interfaces : List PsInterfaceIrContract)
    (value : PsVerifiedIrExternalImport) : Except PsJsAbiError String :=
  match psInterfaceFind interfaces value.source with
  | Option.none => Except.error (PsJsAbiError.interfaceError (PsInterfaceIrError.missingInterface value.source))
  | Option.some provider =>
      match value.type with
      | .function parameters result =>
          match psListMapExcept (psJsAbiScalar value.localName) parameters with
          | Except.error error => Except.error error
          | Except.ok arguments =>
              match psJsAbiScalar value.localName result with
              | Except.error error => Except.error error
              | Except.ok returned =>
                  Except.ok (psJsonObject [
                    Prod.mk "capabilities" (psJsonArray (psListMap psJsonQuote provider.requiredCapabilities)),
                    Prod.mk "exportName" (psJsonQuote value.importedName),
                    Prod.mk "localName" (psJsonQuote value.localName),
                    Prod.mk "moduleId" (psJsonQuote value.source),
                    Prod.mk "parameters" (psJsonArray arguments),
                    Prod.mk "result" returned])
      | _ => Except.error (PsJsAbiError.unsupportedImport value.localName)

def psJsAbiWordBitsValid (wordBits : Nat) : Bool :=
  if Nat.beq wordBits 32 then true else Nat.beq wordBits 64

-- The canonical plan is derived only after fresh module/interface validation.
-- It is adapter data, never a CheckedCore capability or behavioral proof.
def psJsAbiPlan (policy : PsInterfaceIrPolicy) (wordBits : Nat)
    (interfaces : List PsInterfaceIrContract) (erased : PsErasedIrModule) : Except PsJsAbiError String :=
  if psStringEq policy.target "javascript" then
    if psJsAbiWordBitsValid wordBits then
      match psValidateErasedIrModuleWithInterfaces policy interfaces erased with
      | Except.error error => Except.error (PsJsAbiError.interfaceError error)
      | Except.ok validated =>
          match psListMapExcept (psJsAbiImportJson interfaces) validated.raw.imports with
          | Except.error error => Except.error error
          | Except.ok imports =>
              Except.ok (psJsonObject [
                Prod.mk "contract" (psJsonQuote "psc-js-scalar-abi-plan/1"),
                Prod.mk "imports" (psJsonArray imports),
                Prod.mk "runtimeSemantics" (psJsonQuote "psc-runtime-semantics/1"),
                Prod.mk "target" (psJsonQuote "javascript"),
                Prod.mk "wordBits" (psNatToString wordBits)])
    else Except.error PsJsAbiError.invalidWordSize
  else Except.error PsJsAbiError.unsupportedTarget
