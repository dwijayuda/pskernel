import Lean
import Ps.BackendCommon.Plan

-- Native transport adapters stay outside every portable compiler closure.
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrPrimitiveType
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrType
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrMachineIntegerType
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrIntegerBinaryOp
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrIntegerCompareOp
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrFloatingType
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrFloatBinaryOp
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrFloatCompareOp
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrLiteral
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrIntrinsic
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrParameter
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrMatchBinding
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrExpr
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrTypeParameter
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrStructureField
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrStructure
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrConstructorField
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrConstructor
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrInductive
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrDeclaration
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrExternalImport
deriving instance Lean.ToJson, Lean.FromJson for PsVerifiedIrModule

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
  | ["emit", input] =>
      let text ← IO.FS.readFile input
      let (request, validated) ← match psBackendProviderDecode text target with
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
