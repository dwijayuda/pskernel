import Ps.Host.BackendProviderProtocol
import Ps.CompilerIr.Encode
import Ps.BackendPython.Module
import Ps.BackendPhp.Module

private def ensure (condition : Bool) (message : String) : IO Unit := do
  unless condition do throw (IO.userError message)

private def fixture : PsVerifiedIrModule := {
  imports := []
  structures := []
  inductives := []
  declarations := [
    { name := "answer", typeParameters := [], parameters := [],
      resultType := .primitive .nat, body := .literal (.natural 42) },
    { name := "huge", typeParameters := [], parameters := [],
      resultType := .primitive .int, body := .literal (.integer (-12345678901234567890123456789)) },
    { name := "text", typeParameters := [], parameters := [],
      resultType := .primitive .string, body := .literal (.string "λ🙂") },
    { name := "next", typeParameters := [],
      parameters := [{ name := "x", type := .primitive .nat }],
      resultType := .primitive .nat,
      body := .intrinsic .natAdd [] [.var "x", .literal (.natural 1)] }
  ]
}

private def request (target : String) : PsBackendProviderRequest := {
  protocol := psBackendProviderProtocol, target := target,
  leanVersion := Lean.versionString, leanCommit := Lean.githash,
  ir := fixture, publicNames := ["answer", "huge", "text", "next"],
  ioDispatcherAbi := false
}

private def encode (value : PsBackendProviderRequest) : String :=
  (Lean.toJson value).compress

private def expectRefusal (text : String) (target : PsBackendTarget) : IO Unit := do
  match psBackendProviderDecode text target with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "PSC1_PROVIDER_NEGATIVE_ACCEPTED")

def main (args : List String) : IO Unit := do
  let out := System.FilePath.mk (args.headD "dist/backend-providers/fixtures")
  IO.FS.createDirAll out
  for target in [PsBackendTarget.python, .php] do
    let name := psBackendTargetName target
    let req := request name
    let (_, validated) ← match psBackendProviderDecode (encode req) target with
      | .ok value => pure value
      | .error reason => throw (IO.userError reason)
    let portable ← match psIrEncodeModule fixture with
      | .ok value => pure value
      | .error _ => throw (IO.userError "PSC1_PROVIDER_PORTABLE_ENCODE")
    let decoded ← match Ps.Host.PortableIr.decode (← match Lean.Json.parse portable with
        | .ok value => pure value
        | .error reason => throw (IO.userError reason)) with
      | .ok value => pure value
      | .error reason => throw (IO.userError reason)
    ensure ((Lean.toJson decoded) == Lean.toJson fixture) "PSC1_PROVIDER_PORTABLE_ROUND_TRIP"
    IO.FS.writeFile (out / (name ++ ".portable.json"))
      ("[\"psc1-portable-backend-provider/1\",\"" ++ name ++ "\"," ++ portable ++ "," ++
        (Lean.toJson req.publicNames).compress ++ ",false]")
    let source ← match psIrEncodeModule validated.raw, psIrEncodeModule fixture with
      | .ok actual, .ok expected => pure (actual == expected)
      | _, _ => pure false
    ensure source "PSC1_PROVIDER_IR_ROUND_TRIP_CHANGED"
    IO.FS.writeFile (out / (name ++ ".request.json")) (encode req)
    let (body, auxiliary, runtime, requirements, lines) ←
      if name == "python" then
        match psPythonEmitModule validated req.publicNames false with
        | .ok printed => pure (printed.source, printed.stub, printed.runtimeSource,
            printed.runtimeHelpers, printed.declarationLines)
        | .error reason => throw (IO.userError reason)
      else
        match psPhpEmitValidatedModule validated req.publicNames false with
        | .ok printed => pure (printed.source, printed.composer, printed.runtimeSource,
            printed.runtimeRequirements, printed.declarationLines)
        | .error reason => throw (IO.userError reason)
    let expected : PsBackendProviderResponse := {
      protocol := psBackendProviderProtocol, target := name,
      leanVersion := Lean.versionString, leanCommit := Lean.githash,
      requestSha256 := "", publicNames := req.publicNames, ioDispatcherAbi := false,
      candidateOnly := true, source := body, auxiliary := auxiliary,
      runtimeVersion := "psc1-" ++ name ++ "-runtime/1", runtimeSource := runtime,
      runtimeRequirements := requirements, declarationLines := lines
    }
    IO.FS.writeFile (out / (name ++ ".expected.json")) (Lean.toJson expected).compress
    expectRefusal "{" target
    expectRefusal (encode {req with protocol := "other/1"}) target
    expectRefusal (encode {req with target := if name == "python" then "php" else "python"}) target
    expectRefusal (encode {req with leanCommit := "wrong"}) target
    expectRefusal (encode {req with publicNames := ["missing"]}) target
    expectRefusal (encode {req with publicNames := ["answer", "answer"]}) target
    let bad : PsVerifiedIrModule := {fixture with declarations := [{
      name := "answer", typeParameters := [], parameters := [],
      resultType := .primitive .nat, body := .var "unbound"
    }]}
    expectRefusal (encode {req with ir := bad, publicNames := ["answer"]}) target
    expectRefusal (((encode req).dropEnd 1).toString ++ ",\"unexpected\":0}") target
  IO.println "PSC1_PROVIDER_NATIVE: exact IR round trips, retained emitter payloads and16 malformed/identity/IR/ABI refusals passed"
