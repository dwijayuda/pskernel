import Ps.KernelCore.API.Dag

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_ADMISSION_PUBLIC_FAIL " ++ label))
  IO.println ("PSC1_ADMISSION_PUBLIC_ASSERT " ++ label)

private def expect {α : Type} (label : String) : Except String α → IO α
  | .ok value => pure value
  | .error message => throw (IO.userError (label ++ ": " ++ message))

private def expectPublic {α : Type} (label : String) : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError ("PSC1_ADMISSION_PUBLIC_UNEXPECTED_ERROR " ++ label))

private def attempted {α : Type} (label : String) : Option (Except String α) → IO α
  | none => throw (IO.userError ("PSC1_ADMISSION_PUBLIC_UNEXPECTED_DECLINE " ++ label))
  | some value => expect label value

private def rejected {α : Type} : Except PsKernelError α → Bool
  | .error (.rejectedInvalid _) => true
  | _ => false

private def hasRecursor (name : PsKernelName) (refs : List PsKernelExprV2DeclarationRef) : Bool :=
  match refs with
  | [] => false
  | ref :: rest =>
      if psKernelNameEq ref.name name then
        match ref.kind with
        | .recursorDecl (_ :: []) => true
        | _ => false
      else hasRecursor name rest

private def sameReceipt (left right : PsKernelDagReply) : Bool :=
  match left,right with
  | .admitted a,.admitted b =>
      a.declarationsBefore == b.declarationsBefore &&
      a.declarationsAfter == b.declarationsAfter &&
      psKernelStringEq a.target.contract b.target.contract &&
      psKernelStringEq a.target.leanVersion b.target.leanVersion &&
      psKernelStringEq a.target.leanCommit b.target.leanCommit
  | _,_ => false

def main : IO Unit := do
  let harness ← try
    require "harness/forced-failure" false
    pure false
  catch _ => pure true
  require "harness/rejection-active" harness

  let name := PsKernelName.str .anonymous "T05PublicUnit"
  let ctorName := PsKernelName.str name "mk"
  let recName := psKernelSimpleRecName name
  let one := PsKernelLevel.succ .zero
  let s ← expect "sort" (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty one)
  let t ← expect "datatype" (psKernelExprV2PagedMkConst s.fst name [])
  let r ← expect "recursor" (psKernelExprV2PagedMkConst t.fst recName [one])
  let arena := r.fst
  let input ← expect "decode"
    (psKernelExprV2DecodeCanonicalFuel (Nat.succ arena.size) arena psKernelExprV2DecodedEmpty 0)
  let value := PsKernelDagInductive.mk name s.snd [PsKernelDagConstructor.mk ctorName t.snd]
  let request := PsKernelDagDeclarationRequest.ordinaryInductive [] 0 value false
  let declaration ← expect "request" (psKernelDagDecodeDeclaration input request)
  let session ← expectPublic "empty"
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let owner ← expect "session-owner" (psKernelDagGeneratedFromSession session arena input)
  let execution := PsKernelDagExecutionState.mk session owner.declarations
  let checked ← attempted "private"
    (psKernelExprV2OrdinaryAdmitWithFuel 4096 (psKernelKernelSessionEnvironment session)
      session.resources.maxRecDepth session.resources.maxNatSize
      input owner [] 0 value false)
  let direct ← expectPublic "direct"
    (psKernelDagRunOwnedCommandWithSource input execution [] .safe
      owner.arena owner.built (.admit request))
  require "routing/direct-owner-retained"
    (direct.owner.arena.size == checked.owner.arena.size &&
     direct.owner.built.size == checked.owner.built.size &&
     direct.owner.arena.size == direct.owner.built.size &&
     hasRecursor recName direct.owner.declarations &&
     psKernelEnvironmentContains direct.execution.session.environment name &&
     psKernelEnvironmentContains direct.execution.session.environment ctorName &&
     psKernelEnvironmentContains direct.execution.session.environment recName)

  let marker := PsKernelExpr.sort (.succ (.succ (.succ .zero)))
  let imported ← expect "marker" (psKernelDagGeneratedImport marker checked.owner)
  let marked := PsKernelExprV2OrdinaryAdmissionResult.mk checked.environment imported.fst
  let published ← expectPublic "finish-marker"
    (psKernelDagRunOrdinaryOwnedWith (fun _ => some (.ok marked)) input execution
      [] .safe owner.arena owner.built request declaration)
  let markerResult ← expect "marker-result"
    (psKernelExprV2DecodedRequire published.owner.built imported.snd)
  require "routing/finish-carries-injected-suffix"
    (published.owner.arena.size == imported.fst.arena.size &&
     published.owner.built.size == imported.fst.built.size &&
     psKernelExprEqual markerResult marker &&
     hasRecursor recName published.execution.declarations)

  let declined ← expectPublic "declined"
    (psKernelDagRunOrdinaryOwnedWith (fun _ => none) input execution
      [] .safe owner.arena owner.built request declaration)
  let fallback ← expectPublic "fallback"
    (psKernelDagRunFallbackOwnedCommandWithSource input execution
      [] .safe owner.arena owner.built (.admit request))
  require "routing/decline-restarts-original"
    (sameReceipt declined.reply fallback.reply &&
     declined.owner.arena.size == fallback.owner.arena.size &&
     declined.owner.built.size == fallback.owner.built.size &&
     hasRecursor recName declined.owner.declarations &&
     !psKernelEnvironmentContains session.environment name)

  let failed := psKernelDagRunOrdinaryOwnedWith (fun _ => some (.error "expected sort"))
    input execution [] .safe owner.arena owner.built request declaration
  require "routing/hard-error-does-not-fallback"
    (match failed with
     | .error (.rejectedInvalid message) => message == "expected sort"
     | _ => false)

  let limited := { session with resources := { session.resources with maxDeclarations := 1 } }
  let refused := psKernelDagFinishOwnedOrdinaryAdmission limited declaration checked
  require "routing/resource-limit-failure"
    (match refused with
     | .error (.resourceExhausted .declarationLimit message) =>
         message == "declaration limit exceeded"
     | _ => false)

  let batch ← expectPublic "batch"
    (psKernelV1RunDag session [] .safe arena [.admit request,.check r.snd])
  require "routing/same-batch-recursor-check"
    (match batch.replies with
     | [.admitted receipt,.checked _] =>
         receipt.declarationsBefore == 0 && receipt.declarationsAfter == 3
     | _ => false)

  let later ← expectPublic "cross-call"
    (psKernelV1RunDag batch.session [] .safe arena [.check r.snd])
  require "routing/cross-call-checked-recursor"
    (match later.replies with
     | [.checked _] => psKernelEnvironmentContains later.session.environment recName
     | _ => false)

  require "boundary/private-generated-id-not-external"
    (rejected (psKernelV1RunDag session [] .safe arena
      [.admit request,.check input.size]))
  require "boundary/later-command-failure-atomic"
    (rejected (psKernelV1RunDag session [] .safe arena [.admit request,.admit request]) &&
     !psKernelEnvironmentContains session.environment name &&
     psKernelEnvironmentSize session.environment == 0)

  let extra ← expect "original-owner-append"
    (psKernelDagGeneratedImport (.sort one) owner)
  let badValue := PsKernelDagInductive.mk name extra.snd []
  let badRequest := PsKernelDagDeclarationRequest.ordinaryInductive [] 0 badValue false
  let badDeclaration ← expect "internal-only-request"
    (psKernelDagDecodeDeclaration extra.fst.built badRequest)
  require "boundary/fallback-original-bounds"
    (rejected (psKernelDagRunOrdinaryOwnedWith (fun _ => none)
      input execution [] .safe extra.fst.arena extra.fst.built badRequest badDeclaration))

  let cancelled := { session with resources := { session.resources with cancelled := true } }
  let cancelledExecution := PsKernelDagExecutionState.mk cancelled owner.declarations
  let preflight := psKernelDagRunOrdinaryOwnedWith (fun _ => some (.error "expected sort"))
    input cancelledExecution [] .safe owner.arena owner.built request declaration
  require "boundary/preflight-precedence"
    (match preflight with
     | .error (.resourceExhausted .cancelled _) => true
     | _ => false)

  IO.println "PSC1_ADMISSION_PUBLIC_SECTION harness=1"
  IO.println "PSC1_ADMISSION_PUBLIC_SECTION routing=7"
  IO.println "PSC1_ADMISSION_PUBLIC_SECTION boundary=4"
  IO.println "PSC1_ORDINARY_ADMISSION_PUBLIC_NATIVE: PASS assertions=12 publicRoutingChanged=true ordinaryAdmission=true"
