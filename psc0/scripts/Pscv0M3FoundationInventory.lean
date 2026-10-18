import Ps.Environment.SelfHostProd
import PsKernelLean.Convert
import Lean

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
  let native ← Lean.importModules #[{ module := `Lean }] {}
  let mut compared := 0
  let mut differences := 0
  for declaration in psSelfHostProdPreludeEnvironment.declarations.reverse do
    let .recursorDecl info := declaration | continue
    let name := PsKernelLean.toLeanName info.name
    let some (.recInfo original) := native.find? name | continue
    let portable ← match PsKernelLean.toLeanExpr info.type with
      | .ok value => pure value
      | .error error => throw (IO.userError error.message)
    let actual := nativeRecursorBinders portable
    let expected := nativeRecursorBinders original.type
    compared := compared + 1
    if actual != expected then
      differences := differences + 1
      IO.println (Lean.Json.mkObj [
        ("recursor", Lean.toJson name.toString),
        ("portableBinders", Lean.toJson actual),
        ("nativeBinders", Lean.toJson expected)]).compress
  IO.println ("PSCV0_M3_RECURSOR_SURFACE_INVENTORY compared=" ++ toString compared ++
    " differences=" ++ toString differences ++ "; diagnostic only; selected bytes unchanged")

def main : IO Unit := do
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
