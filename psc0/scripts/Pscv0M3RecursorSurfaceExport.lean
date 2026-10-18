import Ps.Host.StandardExport

-- Native kernel witnesses for the two representation distinctions. These do
-- not substitute for replay of the exported selected recursor declarations.
example : (@LT.lt Nat instLTNat) = Nat.lt := rfl
example (type : Type) (value : type) : optParam type value = type := rfl

private def expectCorrespondence (native : Lean.Environment) (label : String)
    (selected reference expected : Lean.Expr) : IO Unit := do
  match PsV7Native.RecursorSource.copy native selected reference with
  | .error error => throw (IO.userError (label ++ ": " ++ error))
  | .ok actual =>
    unless Lean.Expr.equal actual expected && actual == selected do
      throw (IO.userError (label ++ ": exact metadata or selected logical structure changed"))

private def expectRefusal (native : Lean.Environment) (label : String)
    (selected reference : Lean.Expr) : IO Unit := do
  match PsV7Native.RecursorSource.copy native selected reference with
  | .ok _ => throw (IO.userError (label ++ ": invalid source correspondence accepted"))
  | .error _ => pure ()

private def checkCorrespondenceControls (native : Lean.Environment) : IO Unit := do
  let nat := Lean.mkConst ``Nat
  let direct := Lean.mkConst ``Nat.lt
  let projected := Lean.mkApp2 (Lean.mkConst ``LT.lt [.zero]) nat (Lean.mkConst ``instLTNat)
  let wrongRelation := Lean.mkApp2 (Lean.mkConst ``LE.le [.zero]) nat (Lean.mkConst ``instLENat)
  let optional := Lean.mkApp2 (Lean.mkConst ``optParam [.succ .zero]) nat (Lean.mkNatLit 7)
  let otherDefault := Lean.mkApp2 (Lean.mkConst ``optParam [.succ .zero]) nat (Lean.mkNatLit 8)
  expectCorrespondence native "actual-native-dictionary-projection" direct projected direct
  expectCorrespondence native "preserved-applied-arguments"
    (Lean.mkApp2 direct (.bvar 1) (.bvar 0))
    (Lean.mkApp2 projected (.bvar 1) (.bvar 0))
    (Lean.mkApp2 direct (.bvar 1) (.bvar 0))
  expectCorrespondence native "selected-default-and-native-binder"
    (.forallE `old optional nat .default)
    (.forallE `value nat nat .implicit)
    (.forallE `value optional nat .implicit)
  expectCorrespondence native "native-annotation-view-keeps-selected-syntax" nat optional nat
  expectCorrespondence native "nested-minor-binder-metadata"
    (.forallE `old (.forallE `child nat nat .default) nat .default)
    (.forallE `step (.forallE `n nat nat .implicit) nat .default)
    (.forallE `step (.forallE `n nat nat .implicit) nat .default)
  expectRefusal native "wrong-relation" direct wrongRelation
  expectRefusal native "changed-index" (.bvar 0) (.bvar 1)
  expectRefusal native "reordered-dependent-arguments"
    (Lean.mkApp2 direct (.bvar 1) (.bvar 0))
    (Lean.mkApp2 projected (.bvar 0) (.bvar 1))
  expectRefusal native "wrong-projection-owner"
    (.proj ``Prod 0 (.bvar 0)) (.proj ``PProd 0 (.bvar 0))
  expectRefusal native "wrong-projection-index"
    (.proj ``PProd 0 (.bvar 0)) (.proj ``PProd 1 (.bvar 0))
  expectRefusal native "changed-selected-default" optional otherDefault
  expectRefusal native "no-axiom-unfolding" direct (Lean.mkConst ``Classical.choice [.zero])
  expectRefusal native "unrelated-type" nat (Lean.mkConst ``Bool)
  IO.println "PSCV0_M3_RECURSOR_CORRESPONDENCE: PASS five exact positive controls and eight structural/identity refusals; independent selected kernel replay follows"

-- Raw structural inventory is diagnostic only. The authorer separately checks
-- correspondence through pinned projections/optional-annotation views. Neither
-- inventory nor those views may select an asset or weaken official replay.
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
  checkCorrespondenceControls native
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
    "; raw structural inventory only; checked reference correspondence and strict authoring follow")

-- Native-only candidate authoring. All original kernel/layout/rule/closure
-- checks remain mandatory. Selected assets and fingerprints stay unchanged.
def main (args : List String) : IO Unit := do
  let [output] := args
    | throw (IO.userError "usage: Pscv0M3RecursorSurfaceExport OUTPUT")
  inspectShapeDifferences
  PsV7Native.exportRecursorSurfaceCandidate (System.FilePath.mk output)
  IO.println "PSCV0_M3_RECURSOR_SOURCE_CANDIDATE: PASS checked reference binder correspondence, preserved selected logical types, fresh kernel replay, symbolic iota rules and independently measured candidate digests; unselected"
