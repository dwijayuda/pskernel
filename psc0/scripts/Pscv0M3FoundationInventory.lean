import Ps.Environment.SelfHostProd
import PsKernelLean.Convert
import Lean

-- A runtime-catalogue edit must not change the frozen scientific/F4 boundary.
example : psSelfHostProdPreFloatDisplayPreludeEnvironment =
    psStandardScientificExtend psSelfHostProdPreFloatConversionsPreludeEnvironment := rfl

-- PProd's logical presence does not register its runtime datatype. Check the
-- actual shared catalogue, not a parallel test-only declaration list. Missing
-- lookups or duplicate registrations fail before source/backend qualification.
private def inspectPProdRuntimeData : IO Unit := do
  let names := ["PProd", "PProd.mk", "PProd.rec"]
  if psSelfHostPProdRuntimeDataDeclarations.length != names.length then
    throw (IO.userError "PSCV0_M3_PPROD_RUNTIME_DATA: incomplete checked data catalogue")
  for text in names do
    let name := psDecisionName text
    if (psEnvironmentFind psSelfHostProdPreludeEnvironment name).isNone then
      throw (IO.userError ("PSCV0_M3_PPROD_RUNTIME_DATA: missing selected " ++ text))
    let occurrences := psSelfHostRuntimePreludeDeclarationsWithProd.filter
      (fun declaration => psNameEq (psDeclarationName declaration) name)
    if occurrences.length != 1 then
      throw (IO.userError ("PSCV0_M3_PPROD_RUNTIME_DATA: expected one runtime " ++
        text ++ ", found " ++ toString occurrences.length))
  IO.println "PSCV0_M3_PPROD_RUNTIME_DATA: PASS complete selected data and unique shared runtime registrations; source emission and execution checked separately"

-- Source calling conventions are observable even when kernel type equality
-- ignores binder annotations. Inventory every selected public recursor against
-- pinned Lean before choosing a metadata change; this is diagnostic evidence,
-- never publication or a substitute for the existing signature/closure audit.
private def nativeRecursorBinders : Lean.Expr → List String
  | .forallE name _ body binder =>
    let kind := match binder with
      | .default => "explicit" | .implicit => "implicit"
      | .strictImplicit => "strict" | .instImplicit => "instance"
    (name.toString ++ ":" ++ kind) :: nativeRecursorBinders body
  | _ => []

private def inspectRecursorSurface : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let native ← Lean.importModules #[{ module := `Lean }, { module := `Init.Internal.Order.Basic }] {}
  let mut compared := 0
  let mut differences := 0
  let mut unavailable : List String := []
  for declaration in psSelfHostProdPreludeEnvironment.declarations.reverse do
    let .recursorDecl info := declaration | continue
    let name := PsKernelLean.toLeanName info.name
    let expected := match native.find? name with
      | some (.recInfo original) => some (nativeRecursorBinders original.type)
      | _ => none
    if expected.isNone then unavailable := name.toString :: unavailable
    let some expected := expected | continue
    let portable ← match PsKernelLean.toLeanExpr info.type with
      | .ok value => pure value
      | .error error => throw (IO.userError error.message)
    let actual := nativeRecursorBinders portable
    compared := compared + 1
    if actual != expected then
      differences := differences + 1
      IO.println (Lean.Json.mkObj [
        ("recursor", Lean.toJson name.toString),
        ("portableBinders", Lean.toJson actual),
        ("nativeBinders", Lean.toJson expected)]).compress
  IO.println ("PSCV0_M3_RECURSOR_SURFACE_INVENTORY compared=" ++ toString compared ++
    " differences=" ++ toString differences ++ "; diagnostic only; selected bytes unchanged")
  IO.println (Lean.Json.mkObj [("unavailableNativeRecursors", Lean.toJson unavailable.reverse)]).compress

def main : IO Unit := do
  inspectPProdRuntimeData
  inspectRecursorSurface
  let before := psSelfHostProdPreClassicalPreludeEnvironment
  let after := psSelfHostProdPreludeEnvironment
  for declaration in psStandardClassicalExpectedDeclarations do
    let name := psDeclarationName declaration
    IO.println ("PSCV0_M3_FOUNDATION_INVENTORY " ++ psNameToString name ++
      " before=" ++ toString (psEnvironmentFind before name).isSome ++
      " after=" ++ toString (psEnvironmentFind after name).isSome)
  for text in ["PSum", "PSum.inl", "PSum.inr", "PSum.rec", "PSum.casesOn",
      "PSigma", "PSigma.mk", "PSigma.casesOn"] do
    IO.println ("PSCV0_M3_PACKING_INVENTORY " ++ text ++
      " selected=" ++ toString (psEnvironmentFind after (psDecisionName text)).isSome)
  let className := psRootName "Nonempty"
  IO.println ("PSCV0_M3_NONEMPTY_CLASS before=" ++
    toString (before.classes.filter (psNameEq className)).length ++ " after=" ++
    toString (after.classes.filter (psNameEq className)).length)
  match psStandardClassicalAudit after with
  | .ok _ => IO.println "PSCV0_M3_CLASSICAL_ASSET: PASS exact selected declaration audit"
  | .error error => throw (IO.userError error)
