import Ps.Host.StandardExport

-- Diagnostic only: inventory the structural correspondence failures before
-- the unchanged strict exporter runs. Do not retry with a weaker comparison,
-- normalize or replace selected declarations, or select candidate fingerprints.
-- Ignore binder annotations and universe spellings exactly as the existing
-- annotation walk does; report its first shape/identity mismatch per recursor.
private partial def firstShapeDifference (path : String)
    (selected reference : Lean.Expr) : Option (String × Lean.Expr × Lean.Expr) :=
  let selected := selected.consumeMData
  let reference := reference.consumeMData
  let difference := some (path, selected, reference)
  match selected, reference with
  | .forallE _ type body _, .forallE _ nativeType nativeBody _
  | .lam _ type body _, .lam _ nativeType nativeBody _ =>
    firstShapeDifference (path ++ ".domain") type nativeType <|>
      firstShapeDifference (path ++ ".body") body nativeBody
  | .app fn arg, .app nativeFn nativeArg =>
    firstShapeDifference (path ++ ".fn") fn nativeFn <|>
      firstShapeDifference (path ++ ".arg") arg nativeArg
  | .letE _ type value body _, .letE _ nativeType nativeValue nativeBody _ =>
    firstShapeDifference (path ++ ".type") type nativeType <|>
      firstShapeDifference (path ++ ".value") value nativeValue <|>
      firstShapeDifference (path ++ ".body") body nativeBody
  | .proj owner index value, .proj nativeOwner nativeIndex nativeValue =>
    if owner != nativeOwner || index != nativeIndex then difference
    else firstShapeDifference (path ++ ".projected") value nativeValue
  | .const name _, .const nativeName _ =>
    if name == nativeName then none else difference
  | .sort _, .sort _ => none
  | .bvar index, .bvar nativeIndex =>
    if index == nativeIndex then none else difference
  | .lit value, .lit nativeValue =>
    if value == nativeValue then none else difference
  | _, _ => difference

private def inspectShapeDifferences : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  unless Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" do
    throw (IO.userError "recursor shape inventory requires pinned Lean 4.35.0")
  let native ← Lean.importModules #[{ module := `Lean },
    { module := `Init.Internal.Order.Basic }] {}
  let mut compared := 0
  let mut differences := 0
  for declaration in psSelfHostProdPreRecursorSurfacePreludeEnvironment.declarations.reverse do
    let .recursorDecl info := declaration | continue
    let name := PsKernelLean.toLeanName info.name
    let some (.recInfo original) := native.find? name | continue
    let selected ← match PsKernelLean.toLeanExpr info.type with
      | .ok value => pure value
      | .error error => throw (IO.userError error.message)
    compared := compared + 1
    let some (path, actual, expected) := firstShapeDifference "type" selected original.type
      | continue
    differences := differences + 1
    IO.println (Lean.Json.mkObj [
      ("schema", Lean.toJson ("pscv0-recursor-source-shape-difference/1" : String)),
      ("recursor", Lean.toJson name.toString), ("path", Lean.toJson path),
      ("selectedSubexpression", Lean.toJson (reprStr actual)),
      ("nativeSubexpression", Lean.toJson (reprStr expected)),
      ("diagnosticOnly", Lean.toJson true)]).compress
  IO.println ("PSCV0_M3_RECURSOR_SHAPE_INVENTORY compared=" ++ toString compared ++
    " differences=" ++ toString differences ++
    "; diagnostic only; unchanged strict authoring follows")

-- Native-only candidate authoring. The selected foundation and its strict
-- fingerprints remain unchanged until independently qualified publication.
def main (args : List String) : IO Unit := do
  let [output] := args
    | throw (IO.userError "usage: Pscv0M3RecursorSurfaceExport OUTPUT")
  inspectShapeDifferences
  PsV7Native.exportRecursorSurfaceCandidate (System.FilePath.mk output)
  IO.println "PSCV0_M3_RECURSOR_SOURCE_CANDIDATE: PASS pinned complete binder metadata, preserved selected logical types, fresh kernel replay and symbolic iota rules and independently measured candidate digests; unselected"
