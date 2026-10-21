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

/- Host-only instrumentation. These exact structural instances compare semantic
   declaration history; they are never used by the compiled production checker. -/
deriving instance BEq for PsKernelName
deriving instance BEq for PsKernelLevel
deriving instance BEq for PsKernelBinderInfo
deriving instance BEq for PsKernelLiteral
deriving instance BEq for PsKernelExpr
deriving instance BEq for PsKernelDefinitionSafety
deriving instance BEq for PsKernelReducibilityHints
deriving instance BEq for PsKernelConstantBase
deriving instance BEq for PsKernelAxiomInfo
deriving instance BEq for PsKernelDefinitionInfo
deriving instance BEq for PsKernelTheoremInfo
deriving instance BEq for PsKernelOpaqueInfo
deriving instance BEq for PsKernelInductiveInfo
deriving instance BEq for PsKernelConstructorInfo
deriving instance BEq for PsKernelRecursorRule
deriving instance BEq for PsKernelRecursorInfo
deriving instance BEq for PsKernelQuotKind
deriving instance BEq for PsKernelQuotInfo
deriving instance BEq for PsKernelConstantInfo

private structure StageFailure where
  stage : String
  error : PsKernelError

private def sameError (left right : PsKernelError) : Bool :=
  (Json.mkObj (kernelErrorFields left)).compress ==
    (Json.mkObj (kernelErrorFields right)).compress

private def indexedHistoryAgrees (environment : PsKernelEnvironment) : Bool :=
  environment.constants.all fun info =>
    match psKernelEnvironmentFind environment (psKernelConstantInfoName info) with
    | none => false
    | some found => found == info

private def sameEnvironment (left right : PsKernelEnvironment) : Bool :=
  left.constants == right.constants &&
    left.quotInitialized == right.quotInitialized &&
    indexedHistoryAgrees left && indexedHistoryAgrees right

private def stageEvent (label : String) (index : Nat)
    (policy : PsKernelResourcePolicy) (stage phase : String)
    (error : Option PsKernelError := none) : IO Unit := do
  let extra := match error with
    | none => []
    | some value => kernelErrorFields value
  let report := Json.mkObj (
    [("protocol", toJson "pskernel-arena-native-stage-event/1"),
     ("case", toJson label), ("sourceSha", toJson nativeChurchSourceSha),
     ("declarationIndex", toJson index), ("fuel", toJson policy.fuel),
     ("stage", toJson stage), ("phase", toJson phase)] ++ extra)
  let stream ← IO.getStderr
  stream.putStrLn ("PSC1_ARENA_NATIVE_STAGE_EVENT " ++ report.compress)
  stream.flush

/- The thunk runs only after the entry marker has been flushed. No observer
   enters the checker or supplies a callback, cache entry or proof result. -/
private def stageKernel {α : Type} (label : String) (index : Nat)
    (policy : PsKernelResourcePolicy) (stage : String)
    (action : Unit → Except PsKernelError α) : ExceptT StageFailure IO α :=
  ExceptT.mk do
    stageEvent label index policy stage "enter"
    match action () with
    | .error error =>
        stageEvent label index policy stage "error" (some error)
        return .error (StageFailure.mk stage error)
    | .ok value =>
        stageEvent label index policy stage "ok"
        return .ok value

private def stageString {α : Type} (label : String) (index : Nat)
    (policy : PsKernelResourcePolicy) (stage : String)
    (action : Unit → Except String α) : ExceptT StageFailure IO α :=
  stageKernel label index policy stage fun _ =>
    match action () with
    | .error message => .error (psKernelErrorFromMessage message)
    | .ok value => .ok value

/- This mirrors pinned Admission/Declaration/Admission.lean:145-214 and the
   API preflight/size checks, threading each real returned checker session.
   The publication call occurs only after successful header/body/equality work.
   The reference operation is still psKernelV1AdmitDeclaration, separately run
   from the same immutable input session. -/
private def theoremStages (label : String) (index : Nat)
    (session : PsKernelKernelSession) (value : PsKernelTheoremInfo) :
    ExceptT StageFailure IO PsKernelEnvironment := do
  let policy := session.resources
  let _ ← stageKernel label index policy "preflight" fun _ =>
    psKernelKernelSessionPreflight session
  let environment := psKernelKernelSessionEnvironment session
  let checker := psKernelMkCheckerSession environment value.base.levelParams
    .safe policy.maxRecDepth policy.maxNatSize
  let afterHeader ← stageString label index policy "header-check" fun _ =>
    psKernelCheckConstantBaseWithSession policy.fuel checker value.base
  let afterProp ← stageString label index policy "proposition-check" fun _ =>
    match psKernelSessionIsProp policy.fuel afterHeader value.base.type with
    | .error message => .error message
    | .ok checked =>
        if checked.fst then .ok checked.snd
        else .error "theorem type is not a proposition"
  let _ ← stageString label index policy "body-closed" fun _ =>
    psKernelCheckNoMVarNoFVar value.value
  let _ ← stageString label index policy "body-universes" fun _ =>
    psKernelCheckLevelParams value.value value.base.levelParams
  let bodyType ← stageString label index policy "body-check" fun _ =>
    psKernelSessionCheck policy.fuel afterProp value.value
  let _ ← stageString label index policy "type-defeq" fun _ =>
    match psKernelSessionIsDefEq policy.fuel bodyType.snd bodyType.fst value.base.type with
    | .error message => .error message
    | .ok checked =>
        if checked.fst then .ok ()
        else .error "theorem proof type mismatch"
  let published ← stageString label index policy "publication" fun _ =>
    psKernelEnvironmentAdd environment (.thmInfo value)
  stageKernel label index policy "resource-limit" fun _ =>
    if psKernelResourceAllowsSize policy (psKernelEnvironmentSize published) then
      .ok (psKernelEnvironmentWithNativeEvaluator published none)
    else .error (.resourceExhausted .declarationLimit "declaration limit exceeded")

private def compareStages (label : String) (index : Nat)
    (session : PsKernelKernelSession) (value : PsKernelTheoremInfo) :
    IO Json := do
  let before := session.environment
  let beforeSize := psKernelEnvironmentSize before
  let absentBefore := !(psKernelEnvironmentContains before value.base.name)
  require absentBefore (label ++ " source theorem must be absent")
  let observed ← (theoremStages label index session value).run
  stageEvent label index session.resources "reference-operation" "enter"
  let original := psKernelV1AdmitDeclaration session (.theoremDecl value)
  match original with
  | .error error =>
      stageEvent label index session.resources "reference-operation" "error" (some error)
  | .ok _ => stageEvent label index session.resources "reference-operation" "ok"
  let firstFailure := match observed with
    | .error failure => toJson failure.stage
    | .ok _ => Json.null
  let outcomeEqual := match original, observed with
    | .error left, .error right => sameError left right.error
    | .ok left, .ok right => sameEnvironment left.session.environment right
    | _, _ => false
  require outcomeEqual (label ++ " staged outcome differs from unchanged API")
  require (psKernelEnvironmentSize before == beforeSize &&
    !(psKernelEnvironmentContains before value.base.name))
    (label ++ " input session changed or failed theorem published")
  let finalFields := match observed with
    | .error failure => kernelErrorFields failure.error
    | .ok result =>
        [("outcome", toJson "native_admission_complete"), ("accepted", toJson true),
         ("complete", toJson true),
         ("environmentDeclarations", toJson (psKernelEnvironmentSize result))]
  let referenceFields := match original with
    | .error error => kernelErrorFields error
    | .ok result =>
        [("outcome", toJson "native_admission_complete"), ("accepted", toJson true),
         ("complete", toJson true),
         ("environmentDeclarations", toJson (psKernelEnvironmentSize result.session.environment))]
  return Json.mkObj (
    [("protocol", toJson "pskernel-arena-native-theorem-stages/1"),
     ("case", toJson label), ("sourceSha", toJson nativeChurchSourceSha),
     ("bodySha256", if label == "church-numerals" then toJson nativeChurchBodySha256 else Json.null),
     ("adaptedSourceSha256", if label == "church-numerals" then toJson nativeChurchAdaptedSha256 else Json.null),
     ("declarationIndex", toJson index), ("policy", policyJson session.resources),
     ("firstFailingStage", firstFailure), ("sameAsUnmodifiedAPI", toJson outcomeEqual),
     ("inputEnvironmentDeclarations", toJson beforeSize),
     ("inputSessionUnchanged", toJson true), ("noPartialPublication", toJson true),
     ("metadataValidated", toJson false), ("arenaMatchClaimed", toJson false),
     ("reference", Json.mkObj referenceFields)] ++ finalFields)

private def stageControlTheorem (label : String) (invalid : Bool) : PsKernelTheoremInfo :=
  let prop := PsKernelExpr.sort .zero
  let nameP := PsKernelName.str .anonymous "P"
  let nameH := PsKernelName.str .anonymous "h"
  let type := PsKernelExpr.forallE nameP prop
    (.forallE nameH (.bvar 0) (.bvar 1) .default) .default
  let proof := PsKernelExpr.lam nameP prop
    (.lam nameH (.bvar 0) (.bvar 0) .default) .default
  PsKernelTheoremInfo.mk
    (PsKernelConstantBase.mk (.str .anonymous label) [] type)
    (if invalid then prop else proof)

private def runStageControls : IO Unit := do
  let session ← match psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault with
    | .ok value => pure value
    | .error _ => throw (IO.userError "stage control session failed")
  let positive ← compareStages "stage-positive" 0 session (stageControlTheorem "StagePositive" false)
  let invalid ← compareStages "stage-invalid" 0 session (stageControlTheorem "StageInvalid" true)
  let zero : PsKernelKernelSession :=
    { session with resources := { session.resources with fuel := 0 } }
  let resource ← compareStages "stage-resource" 0 zero (stageControlTheorem "StageResource" false)
  let report := Json.mkObj
    [("protocol", toJson "pskernel-arena-native-stage-controls/1"),
     ("sourceSha", toJson nativeChurchSourceSha), ("count", toJson (3 : Nat)),
     ("metadataValidated", toJson false), ("arenaMatchClaimed", toJson false),
     ("cases", Json.arr #[positive, invalid, resource])]
  IO.println ("PSC1_ARENA_NATIVE_STAGES " ++ report.compress)
  IO.println "PSC1_ARENA_NATIVE_STAGE_CONTROLS: PASS count=3"

private def runStages : IO Unit := do
  require (nativeChurchSourceSha ==
    "369bee5801bd5e4476837684fad3f7e1ca8c422c" &&
    nativeChurchBodySha256 ==
    "85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47" &&
    nativeChurchAdaptedSha256 ==
    "443428491e773dc131b1655bf72312517ddc29010112bb8bb241a48ab55c51c1")
    "stage fixture source/body identity"
  require (nativeChurchArena.size == 197 && nativeChurchRequests.length == 4)
    "stage fixture shape"
  let policy := psKernelResourcePolicyDefault
  require (policy.fuel == 4096 && policy.maxRecDepth == 0 &&
    policy.maxNatSize == 134217728 && policy.maxDeclarations == 0 &&
    policy.cancelled == false) "stage pinned default policy"
  let built ← requireString "stage original DAG validation" (psKernelExprV2DecodeChecked nativeChurchArena)
  let empty ← match psKernelKernelSessionEmpty policy psKernelProviderDefault with
    | .ok value => pure value
    | .error _ => throw (IO.userError "stage original session failed")
  let prefix := nativeChurchRequests.take 3
  let before ← match checkRequests built prefix empty 0 with
    | .ok (count, value) => do
        require (count == 3) "stage prefix admission count"
        pure value
    | .error _ => throw (IO.userError "stage original three-request prefix failed")
  let request ← match nativeChurchRequests.drop 3 with
    | [value] => pure value
    | _ => throw (IO.userError "stage original request3 missing")
  let declaration ← requireString "stage request3 decode" (psKernelDagDecodeDeclaration built request)
  let report ← match declaration with
    | .theoremDecl value => compareStages "church-numerals" 3 before value
    | _ => throw (IO.userError "stage original request3 is not a theorem")
  IO.println ("PSC1_ARENA_NATIVE_STAGES " ++ report.compress)

end NativeChurchHost

def main (args : List String) : IO UInt32 := do
  match args with
  | [] =>
      NativeChurchHost.runCase
      return 0
  | ["--controls"] =>
      NativeChurchHost.runControls
      return 0
  | ["--stage-controls"] =>
      NativeChurchHost.runStageControls
      return 0
  | ["--stages"] =>
      NativeChurchHost.runStages
      return 0
  | _ =>
      IO.eprintln "usage: psc1_arena_native_v1_church [--controls|--stage-controls|--stages]"
      return 2

