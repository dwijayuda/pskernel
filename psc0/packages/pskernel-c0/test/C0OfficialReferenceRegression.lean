import Ps.KernelCore.API.Kernel

/-!
Exact same standalone Sort-level definitions as the two adjacent NDJSON files:
* accept: def C0OfficialReference : Sort 1 := Sort 0
* reject: def C0OfficialReference : Sort 0 := Sort 0

The CI job checks each NDJSON against official Lean 4.35.0 leanchecker
--from-export and checks the matching typed PsKernelExpr under C0. This
establishes a very small *external* cross-check, not general NDJSON support.
-/

def main : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "C0OfficialReference"
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let accepted : PsKernelDefinitionInfo := {
    base := { name := name, levelParams := [], type := sort1 }
    value := sort0
    hints := .abbrevHint
    safety := .safe
  }
  let rejected : PsKernelDefinitionInfo :=
    { accepted with base := { accepted.base with type := sort0 } }
  let empty := psKernelEnvironmentEmpty
  match psKernelAddDefinition 4096 empty accepted
      4096 psKernelLeanNatMaxSizeDefault with
  | Except.error error =>
      throw (IO.userError ("C0 rejected official valid Sort definition: " ++ error))
  | Except.ok env =>
      if !psKernelEnvironmentContains env name then
        throw (IO.userError "C0 lost officially checked definition")
      if psKernelEnvironmentContains empty name then
        throw (IO.userError "C0 modified the original environment")
  match psKernelAddDefinition 4096 empty rejected
      4096 psKernelLeanNatMaxSizeDefault with
  | Except.error _ => pure ()
  | Except.ok _ =>
      throw (IO.userError "C0 falsely accepted official invalid Sort definition")
  IO.println "C0_LEAN435 official_sort_export_crosscheck=pass"
