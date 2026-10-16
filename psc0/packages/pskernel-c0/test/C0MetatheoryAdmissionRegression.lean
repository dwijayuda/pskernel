import Ps.KernelCore.Admission.Inductive.Mutual.Analysis

/-!
Cross-branch negative conformance: a constructor outer Pi spine is parsed
without WHNF-manufactured binders, and externally supplied environment root
buckets preserve previously indexed declarations on insertion.
-/
def main : IO Unit := do
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let n : PsKernelName := .str .anonymous "p"
  let type : PsKernelExpr := .sort .zero
  let p : PsKernelOpenBinder := .mk n n type .default
  let rawPi : PsKernelExpr := .forallE n type type .default
  match psKernelOpenSimpleConstructorParams 4096 session [p] rawPi with
  | .error e => throw (IO.userError ("raw constructor Pi rejected: " ++ e))
  | .ok _ => pure ()
  match psKernelOpenSimpleConstructorParams 4096 session [p] (.mdata 0 rawPi) with
  | .ok _ =>
      throw (IO.userError "metadata-manufactured constructor Pi accepted")
  | .error _ => pure ()

  let oldName : PsKernelName := .str .anonymous "indexedOld"
  let newName : PsKernelName := .str .anonymous "indexedNew"
  let oldInfo : PsKernelConstantInfo :=
    .axiomInfo {base := {name := oldName, levelParams := [], type := type}
                isUnsafe := false}
  let newInfo : PsKernelConstantInfo :=
    .axiomInfo {base := {name := newName, levelParams := [], type := type}
                isUnsafe := false}
  let previous : PsKernelEnvironmentIndex := .bucket [oldInfo]
  let after := psKernelEnvironmentIndexInsert previous newInfo
  if !(psKernelEnvironmentIndexFind after oldName).any
      (fun info => psKernelConstantInfoName info == oldName) then
    throw (IO.userError "environment root bucket lost old declaration")
  if !(psKernelEnvironmentIndexFind after newName).any
      (fun info => psKernelConstantInfoName info == newName) then
    throw (IO.userError "environment root bucket lost inserted declaration")
  IO.println "C0_METATHEORY_ADMISSION raw_pi=preserved alias_pi=declined index_root_bucket=preserved"
