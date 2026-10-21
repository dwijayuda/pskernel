import Lean.Data.Json
import Ps.KernelCore.API.Kernel
import Ps.KernelCore.API.DagDeclaration
import Ps.KernelCore.Core.ExprV2.Builder
import NativeChurchInput

/- Host-only diagnostic. The fixture contains the original input DAG and original
   admission requests, not an environment or exported recursor metadata. Every
   request is decoded against the same validated input table and is submitted to
   the independent V1 admission API in its original order. Exported metadata
   validation is deliberately outside this diagnostic; admission completion is
   not an Arena match or a proof of metadata compatibility. -/
namespace NativeChurchHost

open Lean

private structure Failure where
  phase : String
  index : Option Nat
  acceptedRequests : Nat
  kernelError : Option PsKernelError
  message : String

private abbrev BatchResult :=
  Except Failure (Nat × PsKernelKernelSession)

private def checkRequests (built : PsKernelExprV2Decoded) :
    List PsKernelDagDeclarationRequest →
    PsKernelKernelSession → Nat → BatchResult
  | [], session, index => .ok (index, session)
  | request :: rest, session, index =>
      match psKernelDagDecodeDeclaration built request with
      | .error message =>
          .error (Failure.mk "request-decode" (some index) index none message)
      | .ok declaration =>
          match psKernelV1AdmitDeclaration session declaration with
          | .error error =>
              .error (Failure.mk "kernel-admission" (some index) index
                (some error) "")
          | .ok admitted =>
              checkRequests built rest admitted.session (index + 1)

private def checkBatch (policy : PsKernelResourcePolicy)
    (arena : PsKernelExprV2PagedArena)
    (requests : List PsKernelDagDeclarationRequest) : BatchResult :=
  match psKernelKernelSessionEmpty policy psKernelProviderDefault with
  | .error error =>
      .error (Failure.mk "session" none 0 (some error) "")
  | .ok session =>
      match psKernelExprV2DecodeChecked arena with
      | .error message =>
          .error (Failure.mk "dag-validation" none 0 none message)
      | .ok built => checkRequests built requests session 0

private def resourceName : PsKernelResourceError → String
  | .fuel => "fuel"
  | .recursionDepth => "recursionDepth"
  | .natSize => "natSize"
  | .cancelled => "cancelled"
  | .declarationLimit => "declarationLimit"
  | .hostStack => "hostStack"

private def indexJson : Option Nat → Json
  | none => Json.null
  | some index => toJson index

private def kernelErrorFields : PsKernelError → List (String × Json)
  | .rejectedInvalid message =>
      [("outcome", toJson "rejectedInvalid"), ("accepted", toJson false),
       ("complete", toJson true), ("message", toJson message)]
  | .declinedUnsupported message =>
      [("outcome", toJson "declinedUnsupported"), ("accepted", Json.null),
       ("complete", toJson false), ("message", toJson message)]
  | .resourceExhausted resource message =>
      [("outcome", toJson "resourceExhausted"), ("accepted", Json.null),
       ("complete", toJson false), ("resource", toJson (resourceName resource)),
       ("message", toJson message)]
  | .internalError message =>
      [("outcome", toJson "internalError"), ("accepted", Json.null),
       ("complete", toJson false), ("message", toJson message)]

private def resultFields : BatchResult → List (String × Json)
  | .ok (count, session) =>
      [("outcome", toJson "native_admission_complete"),
       ("accepted", toJson true), ("complete", toJson true),
       ("phase", toJson "kernel-admission"), ("declarationIndex", Json.null),
       ("acceptedRequests", toJson count),
       ("environmentDeclarations", toJson (psKernelEnvironmentSize session.environment))]
  | .error failure =>
      let common :=
        [("phase", toJson failure.phase),
         ("declarationIndex", indexJson failure.index),
         ("acceptedRequests", toJson failure.acceptedRequests)]
      match failure.kernelError with
      | some error => common ++ kernelErrorFields error
      | none => common ++
          [("outcome", toJson "malformedInput"), ("accepted", Json.null),
           ("complete", toJson false), ("message", toJson failure.message)]

private def policyJson (policy : PsKernelResourcePolicy) : Json :=
  Json.mkObj
    [("fuel", toJson policy.fuel), ("maxRecDepth", toJson policy.maxRecDepth),
     ("maxNatSize", toJson policy.maxNatSize),
     ("maxDeclarations", toJson policy.maxDeclarations),
     ("cancelled", toJson policy.cancelled)]

private def envelope (label : String) (policy : PsKernelResourcePolicy)
    (arena : PsKernelExprV2PagedArena)
    (requests : List PsKernelDagDeclarationRequest)
    (result : BatchResult) : Json :=
  let bodyIdentity := if label == "church-numerals" then toJson nativeChurchBodySha256 else Json.null
  let adaptedIdentity := if label == "church-numerals" then toJson nativeChurchAdaptedSha256 else Json.null
  Json.mkObj (
    [("protocol", toJson "pskernel-arena-native-v1/1"),
     ("case", toJson label), ("sourceSha", toJson nativeChurchSourceSha),
     ("bodySha256", bodyIdentity),
     ("adaptedSourceSha256", adaptedIdentity),
     ("engine", toJson "psKernelV1AdmitDeclaration"),
     ("metadataValidated", toJson false), ("arenaMatchClaimed", toJson false),
     ("policy", policyJson policy), ("inputNodes", toJson arena.size),
     ("inputRequests", toJson requests.length)] ++ resultFields result)

private def require (condition : Bool) (label : String) : IO Unit := do
  unless condition do
    throw (IO.userError ("native Church diagnostic control failed: " ++ label))

private def requireString {α : Type} (label : String)
    (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError (label ++ ": " ++ message))

private def controlDefinition (name : String) (typeId valueId : Nat) :
    PsKernelDagDeclarationRequest :=
  .definitionDecl (PsKernelDagDefinition.mk
    (PsKernelDagConstantBase.mk (.str .anonymous name) [] typeId)
    valueId (.regular 0) .safe)

private def runControls : IO Unit := do
  let (firstArena, sortZero) ← requireString "control Sort0"
    (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
  let (arena, sortOne) ← requireString "control Sort1"
    (psKernelExprV2PagedMkSort firstArena (.succ .zero))
  let good := controlDefinition "NativeChurchControlGood" sortOne sortZero
  let bad := controlDefinition "NativeChurchControlBad" sortZero sortZero
  let policy := psKernelResourcePolicyDefault
  let zeroPolicy : PsKernelResourcePolicy := { policy with fuel := 0 }
  let positive := checkBatch policy arena [good]
  let invalid := checkBatch policy arena [bad]
  let resource := checkBatch zeroPolicy arena [good]
  let positiveOkay :=
    match positive with
    | .ok (count, session) =>
        count == 1 && psKernelEnvironmentSize session.environment == 1
    | .error _ => false
  let invalidOkay :=
    match invalid with
    | .ok _ => false
    | .error failure =>
        failure.phase == "kernel-admission" &&
        failure.index == some 0 && failure.acceptedRequests == 0 &&
        match failure.kernelError with
        | some (.rejectedInvalid message) => message == "definition type mismatch"
        | _ => false
  let resourceOkay :=
    match resource with
    | .ok _ => false
    | .error failure =>
        failure.phase == "kernel-admission" &&
        failure.index == some 0 && failure.acceptedRequests == 0 &&
        match failure.kernelError with
        | some (.resourceExhausted .fuel message) =>
            message == "resource policy declined operation before entry"
        | _ => false
  require positiveOkay
    ("positive " ++ (envelope "positive" policy arena [good] positive).compress)
  require invalidOkay
    ("invalid " ++ (envelope "invalid" policy arena [bad] invalid).compress)
  require resourceOkay
    ("resource " ++ (envelope "resource" zeroPolicy arena [good] resource).compress)
  let report := Json.mkObj
    [("protocol", toJson "pskernel-arena-native-v1-controls/1"),
     ("sourceSha", toJson nativeChurchSourceSha),
     ("metadataValidated", toJson false),
     ("arenaMatchClaimed", toJson false),
     ("count", toJson (3 : Nat)),
     ("cases", Json.arr #[
       envelope "positive" policy arena [good] positive,
       envelope "invalid" policy arena [bad] invalid,
       envelope "resource" zeroPolicy arena [good] resource])]
  IO.println ("PSC1_ARENA_NATIVE_V1 " ++ report.compress)
  IO.println "PSC1_ARENA_NATIVE_V1_CONTROLS: PASS count=3"

private def runCase : IO Unit := do
  require (nativeChurchSourceSha ==
    "369bee5801bd5e4476837684fad3f7e1ca8c422c") "fixture source identity"
  require (nativeChurchBodySha256 ==
    "85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47")
    "fixture authenticated body identity"
  require (nativeChurchAdaptedSha256 ==
    "443428491e773dc131b1655bf72312517ddc29010112bb8bb241a48ab55c51c1")
    "fixture adapted source identity"
  let policy := psKernelResourcePolicyDefault
  require (policy.fuel == 4096 && policy.maxRecDepth == 0 &&
    policy.maxNatSize == 134217728 && policy.maxDeclarations == 0 &&
    policy.cancelled == false) "pinned default policy"
  let result := checkBatch policy nativeChurchArena nativeChurchRequests
  IO.println ("PSC1_ARENA_NATIVE_V1 " ++
    (envelope "church-numerals" policy nativeChurchArena nativeChurchRequests result).compress)

end NativeChurchHost

def main (args : List String) : IO UInt32 := do
  match args with
  | [] =>
      NativeChurchHost.runCase
      return 0
  | ["--controls"] =>
      NativeChurchHost.runControls
      return 0
  | _ =>
      IO.eprintln "usage: psc1_arena_native_v1_church [--controls]"
      return 2
