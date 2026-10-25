import Ps.KernelCore.API.Dag

private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_QUOT_SESSION_OWNER_FAIL " ++ label))
  IO.println ("PSC1_QUOT_SESSION_OWNER_ASSERT " ++ label)

private def expect {α : Type} : Except String α -> IO α
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def expectPublic {α : Type} : Except PsKernelError α -> IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError "unexpected expectPublic failure")

private def nm (name : String) := PsKernelName.str .anonymous name
private def invalidReference {α : Type} : Except PsKernelError α -> Bool
  | .error (.rejectedInvalid message) => message == "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
  | _ => false

private def sameReply (left right : PsKernelDagReply) : Bool :=
  match left,right with
  | .admitted a,.admitted b =>
      a.declarationsBefore == b.declarationsBefore &&
      a.declarationsAfter == b.declarationsAfter &&
      psKernelStringEq a.target.contract b.target.contract &&
      psKernelStringEq a.target.leanVersion b.target.leanVersion &&
      psKernelStringEq a.target.leanCommit b.target.leanCommit
  | _,_ => false

def main : IO Unit := do
  let empty ← expectPublic
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let u := nm "u"
  let reflName := PsKernelName.str psKernelEqName "refl"
  let eq := PsKernelSimpleInductiveDecl.mk [u] psKernelEqName (psKernelExpectedEqType u)
    [.mk reflName (psKernelExpectedEqReflType u)] false 2
  let withEq ← expectPublic (psKernelV1AdmitDeclaration empty (.ordinaryInductive eq))
  let session := withEq.session
  let owner0 := PsKernelDagGeneratedState.mk
    psKernelExprV2PagedEmpty psKernelExprV2DecodedEmpty []
  require "preexisting-session-starts-with-no-input-owners" owner0.declarations.isEmpty
  let prepared ← expect (psKernelDagGeneratedPrepareQuot session.environment owner0)
  require "demanded-Eq-and-constructor-owners-present"
    ((psKernelExprV2DeclarationRefFind prepared.declarations psKernelEqName).isSome &&
     (psKernelExprV2DeclarationRefFind prepared.declarations reflName).isSome &&
     prepared.arena.size == prepared.built.size && prepared.arena.size > 0)
  let some (.ok checked) := psKernelDagTryAdmitQuot session.environment
      prepared.arena prepared.declarations
    | throw (IO.userError "preexisting Eq did not enter direct admission")
  require "preexisting-owner-admission-direct-success" checked.quotInitialized
  let execution := PsKernelDagExecutionState.mk session []
  let direct ← expectPublic (psKernelDagRunOwnedCommandWithSource psKernelExprV2DecodedEmpty
    execution [] .safe owner0.arena owner0.built (.admit .quot))
  let fallback ← expectPublic (psKernelDagRunFallbackOwnedCommandWithSource psKernelExprV2DecodedEmpty
    execution [] .safe owner0.arena owner0.built (.admit .quot))
  require "direct-and-original-receipts-match" (sameReply direct.reply fallback.reply)
  require "direct-carries-prepared-Eq-owner"
    ((psKernelExprV2DeclarationRefFind direct.owner.declarations psKernelEqName).isSome &&
     direct.owner.arena.size == direct.owner.built.size)
  for name in [psKernelQuotName,psKernelQuotMkName,psKernelQuotLiftName,psKernelQuotIndName] do
    require "all-four-live-Quot-owners-published"
      ((psKernelExprV2DeclarationRefFind direct.owner.declarations name).isSome &&
       psKernelEnvironmentContains direct.execution.session.environment name)

  let result ← expectPublic (psKernelV1RunDag session [] .safe psKernelExprV2PagedEmpty
    [.admit .quot,.admit .quot])
  require "expectPublic-empty-input-cross-call-and-repeat"
    (result.replies.length == 2 && result.session.environment.quotInitialized &&
      psKernelEnvironmentSize result.session.environment == psKernelEnvironmentSize checked)
  let some quotient := psKernelExprV2DeclarationRefFind direct.owner.declarations psKernelQuotName
    | throw (IO.userError "missing quotient private owner")
  require "prepared-private-IDs-never-enter-input-namespace"
    (invalidReference (psKernelV1RunDag session [] .safe psKernelExprV2PagedEmpty
      [.admit .quot,.check quotient.type]))

  let marked ← expect (psKernelDagGeneratedImport (.sort (.succ (.succ (.succ .zero)))) prepared)
  let declined ← expectPublic (psKernelDagRunQuotOwnedWith (fun _ _ => .ok marked.fst)
    (fun _ _ _ => none) psKernelExprV2DecodedEmpty execution [] .safe owner0.arena owner0.built)
  require "decline-discards-prepared-suffix-and-restarts-original"
    (sameReply declined.reply fallback.reply &&
      declined.owner.arena.size == fallback.owner.arena.size &&
      declined.owner.built.size == fallback.owner.built.size)
  let failed := psKernelDagRunQuotOwnedWith (fun _ _ => .ok prepared)
    (fun _ _ _ => some (.error "expected sort"))
    psKernelExprV2DecodedEmpty execution [] .safe owner0.arena owner0.built
  require "hard-error-never-falls-back"
    (match failed with | .error (.rejectedInvalid message) => message == "expected sort" | _ => false)
  let importFailure := psKernelDagRunQuotOwnedWith (fun _ _ => .error "owner import marker")
    psKernelDagTryAdmitQuot psKernelExprV2DecodedEmpty execution [] .safe owner0.arena owner0.built
  require "import-error-publishes-no-session"
    (match importFailure with | .error (.internalError message) => message == "owner import marker" | _ => false)

  let limited := { session with resources := { session.resources with
    maxDeclarations := psKernelEnvironmentSize session.environment } }
  require "declaration-limit-is-hard-rejection"
    (match psKernelV1RunDag limited [] .safe psKernelExprV2PagedEmpty [.admit .quot] with
     | .error (.resourceExhausted .declarationLimit message) => message == "declaration limit exceeded"
     | _ => false)
  let original ← expect (psKernelDagGeneratedPrepareQuot checked owner0)
  require "initialized-preparation-does-not-import-Eq"
    (original.arena.size == 0 && original.built.size == 0 && original.declarations.isEmpty)
  require "failed-expectPublic-batches-do-not-mark-original-environment" (!session.environment.quotInitialized)
  IO.println "PSC1_QUOT_SESSION_OWNER_PASS"
