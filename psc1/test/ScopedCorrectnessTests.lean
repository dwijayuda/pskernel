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
