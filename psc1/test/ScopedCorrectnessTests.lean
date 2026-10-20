import Ps.Host.WasmComponent

private def require (name : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_SCOPED_FAIL: " ++ name))
  IO.println ("PSC1_SCOPED_PASS: " ++ name)

def main : IO Unit := do
  require "negative VLQ -1" (psDirectVLQ (-1) == "D")
  require "negative VLQ -10" (psDirectVLQ (-10) == "V")
  require "minimum signed VLQ" (psDirectVLQ (-2147483648) == "B")
  require "positive VLQ unchanged" (psDirectVLQ 5 == "K")
  require "WIT ordinary name" (psHostWitIdent "idbool")
  require "WIT kebab name" (psHostWitIdent "read-value")
  require "WIT rejects trailing hyphen" (!psHostWitIdent "value-")
  require "WIT rejects consecutive hyphens" (!psHostWitIdent "read--value")
  require "WIT rejects reserved world" (!psHostWitIdent "world")
  require "WIT rejects uppercase" (!psHostWitIdent "Value")
  require "WIT accepts the active Bool scalar"
    (match psHostWitScalarType (.primitive .bool) with | .ok "bool" => true | _ => false)
  let unqualified : List PsVerifiedIrPrimitiveType :=
    [.uint8, .uint16, .uint32, .uint64, .int8, .int16, .int32, .int64, .float32, .float]
  for primitive in unqualified do
    require ("WIT cannot advertise unqualified " ++ psIrCheckPrimitiveName primitive)
      (match psHostWitScalarType (.primitive primitive) with
        | .error reason => reason.startsWith "PSC1_COMPONENT_SCALAR_PROFILE_UNQUALIFIED:"
        | .ok _ => false)
  let declaration : PsVerifiedIrDeclaration := {
    name := "forged"
    typeParameters := []
    parameters := []
    resultType := .primitive .nat
    body := .literal (.bool true)
  }
  let raw : PsVerifiedIrModule := {
    imports := []
    structures := []
    inductives := []
    declarations := [declaration]
  }
  let forged : PsValidatedIrModule := { raw := raw }
  require "forged validated wrapper rejected before specialization"
    (match psIrSpecializeValidatedModule forged with | .error _ => true | .ok _ => false)
  require "forged uniform wrapper rejected before specialization"
    (match psIrSpecializeUniformValidatedModule forged with | .error _ => true | .ok _ => false)

  let selected : PsValidatedIrModule := { raw := { raw with declarations := [{
    declaration with name := "visible", body := .literal (.natural 42)
  }] }}
  let privateRust ← match psRustEmitSelectedValidatedModule selected [] [] with
    | .ok source => pure source
    | .error reason => throw (IO.userError reason)
  require "Rust selects private function before printing"
    ((privateRust.splitOn "fn visible").length == 2 &&
      (privateRust.splitOn "pub fn visible").length == 1)
  let publicRust ← match psRustEmitSelectedValidatedModule selected ["visible"] [] with
    | .ok source => pure source
    | .error reason => throw (IO.userError reason)
  require "Rust selects public function before printing"
    ((publicRust.splitOn "pub fn visible").length == 2)
