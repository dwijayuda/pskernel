import Ps.KernelCore.Architecture.SealedState

def main : IO Unit := do
  let some genesis := psKernelC0SealedSourceBegin
      4096 psKernelLeanNatMaxSizeDefault
    | throw (IO.userError "sealed state genesis failed")
  let _root := psKernelC0SealedSourceHasLineage genesis
  let _envProof := psKernelC0SealedSourceEnvironmentHistory genesis
  let sort0 : PsKernelExpr := .sort .zero
  let (normal, normalized) ← match psKernelC0SealedSourceWhnf 4096 genesis
      (.mdata 31 (.mdata 32 sort0)) with
    | .ok result => pure result
    | .error e => throw (IO.userError ("sealed WHNF failed: " ++ e))
  if !psKernelExprEqual normal sort0 then
    throw (IO.userError "sealed source WHNF changed source result")
  let _normalizedLineage := psKernelC0SealedSourceHasLineage normalized
  let (inferred, afterInfer) ← match psKernelC0SealedSourceInfer
      4096 normalized sort0 with
    | .ok result => pure result
    | .error e => throw (IO.userError ("sealed inference failed: " ++ e))
  if !psKernelExprEqual inferred (.sort (.succ .zero)) then
    throw (IO.userError "sealed source inference changed Sort type")
  let (checked, afterCheck) ← match psKernelC0SealedSourceCheck
      4096 afterInfer sort0 with
    | .ok result => pure result
    | .error e => throw (IO.userError ("sealed checking failed: " ++ e))
  if !psKernelExprEqual checked inferred then
    throw (IO.userError "sealed full source check changed inferred type")
  let (same, afterDefEq) ← match psKernelC0SealedSourceDefEq
      4096 afterCheck sort0 sort0 with
    | .ok result => pure result
    | .error e => throw (IO.userError ("sealed DefEq failed: " ++ e))
  if !same then throw (IO.userError "sealed DefEq rejected identical Sorts")
  match psKernelC0SealedSourceCheck 4096 afterDefEq (.bvar 0) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "sealed checker accepted loose bvar")
  match psKernelC0SealedSourceWhnf 0 afterDefEq sort0 with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "sealed WHNF bypassed fuel")
  let some staged := psKernelC0SealedSourceStage afterDefEq sort0
    | throw (IO.userError "sealed syntax staging failed")
  let _stageHistory := psKernelC0SealedSourceHasLineage staged
  -- Publication must be tied to this exact checked state and preserve the
  -- source proof and immutable input even when root syntax is staged.
  let published ← match psKernelC0SealedSourceCommitChecked 4096 staged with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("sealed checked publication failed: " ++ e))
  let _publicationExact :=
    psKernelC0SealedPublicationExact published
  match published.roots with
  | [root] =>
      let _sourceProof := psKernelC0SourceCheckedRootExact root
      if !psKernelExprEqual root.root.expression sort0 then
        throw (IO.userError "sealed publication changed exact root syntax")
  | _ => throw (IO.userError "sealed publication omitted checked root")
  if psKernelEnvironmentSize
      staged.trusted.certified.raw.checker.context.environment != 0 then
    throw (IO.userError "sealed publication changed original environment")
  let declName : PsKernelName := .str .anonymous "SealedCheckedDefinition"
  let info : PsKernelDefinitionInfo := {
    base := {
      name := declName
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := sort0
    hints := .abbrevHint
    safety := .safe
  }
  let admitted ← match psKernelC0SealedSourceAdmit
      4096 staged (.definition info) with
    | .ok next => pure next
    | .error e => throw (IO.userError ("sealed checked admission failed: " ++ e))
  let (unfolded, final) ← match psKernelC0SealedSourceWhnf
      4096 admitted (.const declName []) with
    | .ok result => pure result
    | .error e => throw (IO.userError ("sealed checked delta failed: " ++ e))
  if !psKernelExprEqual unfolded sort0 then
    throw (IO.userError "sealed checked delta changed source definition")
  let _finalHistory := psKernelC0SealedSourceHasLineage final
  match psKernelC0SealedSourceAdmit 4096 admitted (.definition info) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "sealed duplicate admission succeeded")
  if psKernelEnvironmentSize
      genesis.trusted.certified.raw.checker.context.environment != 0 then
    throw (IO.userError "sealed admission mutated immutable genesis")
  IO.println "C0_SEALED exact_state_lineage_genesis_to_admission=pass"
  IO.println "C0_SEALED exact_source_whnf_infer_check_defeq_stage=pass"
  IO.println "C0_SEALED failures_do_not_publish_lineage=pass"
