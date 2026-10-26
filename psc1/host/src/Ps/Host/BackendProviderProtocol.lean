import Ps.Host.BackendProviderInstances
import Ps.Host.PortableIr

def psBackendProviderProtocol : String := "psc1-backend-provider/1"
def psBackendProviderMaxBytes : Nat := 67108864

structure PsBackendProviderRequest where
  protocol : String
  target : String
  leanVersion : String
  leanCommit : String
  ir : PsVerifiedIrModule
  publicNames : List String
  ioDispatcherAbi : Bool
  deriving Lean.ToJson, Lean.FromJson

/-- Emitters return candidates only. They cannot admit a graph or publish files. -/
structure PsBackendProviderResponse where
  protocol : String
  target : String
  leanVersion : String
  leanCommit : String
  requestSha256 : String
  publicNames : List String
  ioDispatcherAbi : Bool
  candidateOnly : Bool
  source : String
  auxiliary : String
  runtimeVersion : String
  runtimeSource : String
  runtimeRequirements : List String
  declarationLines : List (String × Nat)
  deriving Lean.ToJson, Lean.FromJson

def psBackendProviderDecode (text : String) (target : PsBackendTarget) :
    Except String (PsBackendProviderRequest × PsValidatedIrModule) := do
  if text.utf8ByteSize > psBackendProviderMaxBytes then throw "PSC1_PROVIDER_REQUEST_LIMIT"
  let value ← Lean.Json.parse text
  let request : PsBackendProviderRequest ← Lean.fromJson? value
  if value != Lean.toJson request then throw "PSC1_PROVIDER_REQUEST_SCHEMA"
  if request.protocol != psBackendProviderProtocol ||
      request.target != psBackendTargetName target then throw "PSC1_PROVIDER_REQUEST_IDENTITY"
  if request.leanVersion != Lean.versionString || request.leanCommit != Lean.githash then
    throw "PSC1_PROVIDER_LEAN_PIN"
  let validated ← match psStrictValidateModule request.ir with
    | .ok result => pure result
    | .error _ => throw "PSC1_PROVIDER_STRICT_IR"
  if request.ioDispatcherAbi then
    psBackendCheckIoPublicApi target validated request.publicNames
  else
    psBackendCheckPublicApi target validated request.publicNames
  return (request, validated)

def psBackendProviderRun (target : PsBackendTarget)
    (emit : PsValidatedIrModule → List String → Bool →
      Except String (String × String × String × List String × List (String × Nat)))
    (args : List String) : IO Unit := do
  match args with
  | ["--identity"] =>
      IO.println ((Lean.Json.mkObj [
        ("protocol", Lean.toJson psBackendProviderProtocol),
        ("target", Lean.toJson (psBackendTargetName target)),
        ("leanVersion", Lean.toJson Lean.versionString),
        ("leanCommit", Lean.toJson Lean.githash),
        ("candidateOnly", Lean.toJson true)]).compress)
  | [command, input] =>
      if command != "emit" && command != "emit-portable" then
        throw (IO.userError "PSC1_PROVIDER_COMMAND")
      let text ← IO.FS.readFile input
      let decoded := if command == "emit" then psBackendProviderDecode text target else do
        if text.utf8ByteSize > 33554432 then throw "PSC1_PORTABLE_PROVIDER_REQUEST_LIMIT"
        let value ← Lean.Json.parse text
        let [.str "psc1-portable-backend-provider/1", .str selected, ir, names, abi] ←
            Ps.Host.PortableIr.rows value | throw "PSC1_PORTABLE_PROVIDER_REQUEST_SCHEMA"
        if selected != psBackendTargetName target then throw "PSC1_PORTABLE_PROVIDER_TARGET"
        let raw ← Ps.Host.PortableIr.decode ir
        let publicNames ← (← Ps.Host.PortableIr.rows names).mapM Ps.Host.PortableIr.string
        if publicNames.isEmpty || publicNames.eraseDups.length != publicNames.length then
          throw "PSC1_PORTABLE_PROVIDER_PUBLIC_NAMES"
        let ioAbi ← abi.getBool?
        let request : PsBackendProviderRequest := {
          protocol := psBackendProviderProtocol, target := selected,
          leanVersion := Lean.versionString, leanCommit := Lean.githash,
          ir := raw, publicNames, ioDispatcherAbi := ioAbi }
        -- Reuse the identical strict IR and target-specific ABI checks.
        psBackendProviderDecode (Lean.toJson request).compress target
      let (request, validated) ← match decoded with
        | .ok result => pure result
        | .error reason => throw (IO.userError reason)
      let some digest ← IO.getEnv "PSC1_BACKEND_REQUEST_SHA256"
        | throw (IO.userError "PSC1_PROVIDER_REQUEST_DIGEST_REQUIRED")
      if digest.length != 64 || !digest.toList.all
          (fun c => c.isDigit || ('a' ≤ c && c ≤ 'f')) then
        throw (IO.userError "PSC1_PROVIDER_REQUEST_DIGEST_INVALID")
      let (source, auxiliary, runtimeSource, requirements, lines) ←
        match emit validated request.publicNames request.ioDispatcherAbi with
        | .ok result => pure result
        | .error reason => throw (IO.userError reason)
      let response : PsBackendProviderResponse := {
        protocol := psBackendProviderProtocol
        target := request.target
        leanVersion := Lean.versionString
        leanCommit := Lean.githash
        requestSha256 := digest
        publicNames := request.publicNames
        ioDispatcherAbi := request.ioDispatcherAbi
        candidateOnly := true
        source := source
        auxiliary := auxiliary
        runtimeVersion := "psc1-" ++ request.target ++ "-runtime/1"
        runtimeSource := runtimeSource
        runtimeRequirements := requirements
        declarationLines := lines
      }
      let result := (Lean.toJson response).compress
      if result.utf8ByteSize > psBackendProviderMaxBytes then
        throw (IO.userError "PSC1_PROVIDER_RESPONSE_LIMIT")
      IO.println result
  | _ => throw (IO.userError "PSC1_PROVIDER_USAGE: --identity | emit <request.json>")
