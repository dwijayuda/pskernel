import Ps.CompilerIr.ValidateArtifact
import Ps.CompilerIr.LinkArtifact

def psHostIrDecodeCode (error : PsIrDecodeError) : String :=
  match error with
  | .schema => "schema"
  | .depthExhausted => "resource-depth"
  | .bytesExhausted => "resource-bytes"
  | .parse .fuelExhausted => "resource-parse"
  | .parse _ => "parse"
  | .nonCanonical => "non-canonical"

-- The bounded host adapter sends preflighted canonical bytes over stdin.
-- This executable contains only the decoder/strict validator and their closure.
def main (args : List String) : IO UInt32 := do
  let source ← (← IO.getStdin).readToEnd
  if args == ["--roundtrip"] then
    match psIrDecodeModule source with
    | .error error => IO.println (psHostIrDecodeCode error); return 1
    | .ok value =>
        match psIrEncodeModule value with
        | .error _ => IO.println "resource-encode"; return 1
        | .ok output => IO.print output; return 0
  else if args == ["--validate"] then
    match psIrValidateEncodedModule source with
    | .error (.decode error) => IO.println (psHostIrDecodeCode error); return 1
    | .error (.invalidIr _) => IO.println "invalid-ir"; return 1
    | .ok _ => IO.println "valid-closed-ir"; return 0
  else if args == ["--validate-link"] then
    match psIrValidateEncodedLink source with
    | .error (.decode error) => IO.println (psHostIrDecodeCode error); return 1
    | .error (.invalidLink _) => IO.println "invalid-link"; return 1
    | .ok _ => IO.println "valid-linked-ir"; return 0
  else if args == ["--roundtrip-link"] then
    match psIrDecodeLinkArtifact source with
    | .error error => IO.println (psHostIrDecodeCode error); return 1
    | .ok value =>
        match psIrEncodeLinkArtifact value with
        | .error _ => IO.println "resource-encode"; return 1
        | .ok output => IO.print output; return 0
  else IO.println "unsupported-operation"; return 2
