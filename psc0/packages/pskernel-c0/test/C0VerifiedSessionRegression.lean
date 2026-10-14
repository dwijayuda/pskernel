import Ps.KernelCore.API.VerifiedSession

def main : IO Unit := do
  let some initial := psKernelC0VerifiedBegin 4096 psKernelLeanNatMaxSizeDefault
    | throw (IO.userError "verified session genesis failed")
  let _assumptions := psKernelC0VerifiedAxiomsApproved initial
  let _capabilities := psKernelC0VerifiedCapabilitiesApproved initial
  let sort0 : PsKernelExpr := .sort .zero
  let (normal, afterWhnf) ← match psKernelC0VerifiedWhnf
      4096 initial (.mdata 15 (.mdata 16 sort0)) with
    | .ok value => pure value
    | .error e => throw (IO.userError ("verified WHNF failed: " ++ e))
  if !psKernelExprEqual normal sort0 then
    throw (IO.userError "verified WHNF disagreed with source")
  let (type, afterInfer) ← match psKernelC0VerifiedInfer
      4096 afterWhnf sort0 with
    | .ok value => pure value
    | .error e => throw (IO.userError ("verified infer failed: " ++ e))
  if !psKernelExprEqual type (.sort (.succ .zero)) then
    throw (IO.userError "verified infer changed Sort type")
  let (checked, afterCheck) ← match psKernelC0VerifiedCheck
      4096 afterInfer sort0 with
    | .ok value => pure value
    | .error e => throw (IO.userError ("verified check failed: " ++ e))
  if !psKernelExprEqual checked type then
    throw (IO.userError "verified full check changed type")
  match psKernelC0VerifiedCheck 4096 afterCheck (.bvar 0) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "verified checker accepted loose variable")
  let (same, afterDefEq) ← match psKernelC0VerifiedDefEq
      4096 afterCheck sort0 sort0 with
    | .ok value => pure value
    | .error e => throw (IO.userError ("verified DefEq failed: " ++ e))
  if !same then throw (IO.userError "verified DefEq rejected identical types")
  match psKernelC0VerifiedWhnf 0 afterDefEq sort0 with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "verified WHNF ignored fuel exhaustion")

  let some staged := psKernelC0VerifiedStage afterDefEq sort0
    | throw (IO.userError "verified staging failed")
  let receipt ← match psKernelC0VerifiedCommitChecked 4096 staged with
    | .ok result => pure result
    | .error e => throw (IO.userError ("verified publication failed: " ++ e))
  let _exact := psKernelC0SealedAuditedPublicationExact receipt
  match receipt.roots with
  | [root] =>
      let _proof := psKernelC0SourceCheckedRootExact root
      if !psKernelExprEqual root.checkedType (.sort (.succ .zero)) then
        throw (IO.userError "verified publication altered source checked type")
  | _ => throw (IO.userError "verified publication omitted checked root")

  let some invalid := psKernelC0VerifiedStage initial (.bvar 0)
    | throw (IO.userError "verified negative staging failed")
  match psKernelC0VerifiedCommitChecked 4096 invalid with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "verified publication accepted invalid root")

  let proposed : PsKernelAxiomInfo := {
    base := {
      name := .str .anonymous "VerifiedSessionExplicitAxiom"
      levelParams := []
      type := .sort .zero
    }
    isUnsafe := false
  }
  match psKernelC0VerifiedAdmit 4096 staged (.axiomDecl proposed) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "unapproved axiom passed verified API")
  let some permitted := psKernelC0VerifiedChangePolicy staged [proposed] []
    | throw (IO.userError "verified explicit policy update failed")
  let admitted ← match psKernelC0VerifiedAdmit
      4096 permitted (.axiomDecl proposed) with
    | .ok next => pure next
    | .error e => throw (IO.userError ("verified signed axiom rejected: " ++ e))
  let _approved := psKernelC0VerifiedAxiomsApproved admitted
  let _caps := psKernelC0VerifiedCapabilitiesApproved admitted
  if (psKernelC0VerifiedChangePolicy admitted [] []).isSome then
    throw (IO.userError "verified API erased previously admitted assumption")
  if (psKernelC0HistoryAxiomSignatures
      admitted.sealed.audited.trusted.history).length != 1 then
    throw (IO.userError "verified API lost exact signed foundation history")
  IO.println "C0_VERIFIED_SESSION lineage_whnf_infer_check_defeq=pass"
  IO.println "C0_VERIFIED_SESSION exact_atomic_publication=pass"
  IO.println "C0_VERIFIED_SESSION explicit_trust_policy_and_failure_atomicity=pass"
