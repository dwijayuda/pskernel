import Ps.KernelCore.API.Kernel

/-!
Version-pinned, source-identical declaration fixtures for the official Lean
4.35.0 leanchecker --from-export and C0. Adjacent *.ndjson files encode the
same syntax and have corresponding expected outcomes.

This is a selected external checker differential *corpus*, not a general
NDJSON importer or a claim of exhaustive official Lean compatibility.
-/

def c0OfficialCheckDefinition
    (info : PsKernelDefinitionInfo)
    (mustAccept : Bool) : IO Unit := do
  let empty := psKernelEnvironmentEmpty
  match psKernelAddDefinition 4096 empty info
      4096 psKernelLeanNatMaxSizeDefault with
  | Except.error message =>
      if mustAccept then
        throw (IO.userError
          ("C0 rejected officially valid declaration: " ++ message))
  | Except.ok environment =>
      if !mustAccept then
        throw (IO.userError
          "C0 falsely accepted officially invalid declaration")
      if !psKernelEnvironmentContains environment info.base.name ||
          psKernelEnvironmentContains empty info.base.name then
        throw (IO.userError
          "C0 acceptance mutated the wrong environment")

def main : IO Unit := do
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)

  -- C0OfficialAccept / C0OfficialReject:
  -- def C0OfficialReference : Sort 1 := Sort 0
  let baseName := PsKernelName.str PsKernelName.anonymous
    "C0OfficialReference"
  let baseInfo : PsKernelDefinitionInfo := {
    base := { name := baseName, levelParams := [], type := sort1 }
    value := sort0
    hints := .abbrevHint
    safety := .safe
  }
  c0OfficialCheckDefinition baseInfo true
  c0OfficialCheckDefinition
    { baseInfo with base := { baseInfo.base with type := sort0 } } false
  IO.println "C0_LEAN435 official_sort_export_crosscheck=pass"

  -- C0OfficialBinderAccept / C0OfficialBinderReject:
  -- fun (x : Sort 0) => x : (x : Sort 0) → Sort 0
  -- A source Sort 0 body instead has type Sort 1 and must be rejected.
  let binderName := PsKernelName.str PsKernelName.anonymous "x"
  let identity : PsKernelExpr :=
    .lam binderName sort0 (.bvar 0) .default
  let invalidIdentity : PsKernelExpr :=
    .lam binderName sort0 sort0 .default
  let binderNameRoot := PsKernelName.str PsKernelName.anonymous
    "C0OfficialBinder"
  let binderInfo : PsKernelDefinitionInfo := {
    base := {
      name := binderNameRoot
      levelParams := []
      type := .forallE binderName sort0 sort0 .default
    }
    value := identity
    hints := .abbrevHint
    safety := .safe
  }
  c0OfficialCheckDefinition binderInfo true
  c0OfficialCheckDefinition
    { binderInfo with value := invalidIdentity } false
  IO.println "C0_LEAN435 official_binder_export_crosscheck=pass"

  -- C0OfficialLetAccept / C0OfficialLetReject:
  -- let u : Sort 1 := Sort 0; u
  -- A checked let annotation Sort 0 is invalid for value Sort 0.
  let letBinder := PsKernelName.str PsKernelName.anonymous "u"
  let letInfo : PsKernelDefinitionInfo := {
    base := {
      name := PsKernelName.str PsKernelName.anonymous "C0OfficialLet"
      levelParams := []
      type := sort1
    }
    value := .letE letBinder sort1 sort0 (.bvar 0) false
    hints := .abbrevHint
    safety := .safe
  }
  c0OfficialCheckDefinition letInfo true
  c0OfficialCheckDefinition
    { letInfo with value := .letE letBinder sort0 sort0 (.bvar 0) false }
    false
  IO.println "C0_LEAN435 official_let_export_crosscheck=pass"

  -- C0OfficialUniverseAccept / C0OfficialUniverseReject:
  -- def C0OfficialUniverse.{u} : Sort (u+1) := Sort u
  let uName := PsKernelName.str PsKernelName.anonymous "u"
  let uSort : PsKernelExpr := .sort (.param uName)
  let uSortSucc : PsKernelExpr := .sort (.succ (.param uName))
  let universeInfo : PsKernelDefinitionInfo := {
    base := {
      name := PsKernelName.str PsKernelName.anonymous "C0OfficialUniverse"
      levelParams := [uName]
      type := uSortSucc
    }
    value := uSort
    hints := .abbrevHint
    safety := .safe
  }
  c0OfficialCheckDefinition universeInfo true
  c0OfficialCheckDefinition
    { universeInfo with base := { universeInfo.base with type := uSort } }
    false
  IO.println "C0_LEAN435 official_universe_export_crosscheck=pass"
