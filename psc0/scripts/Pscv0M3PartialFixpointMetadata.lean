import Lean

-- Native metadata observations for the exact selected P1 order dictionaries.
-- This probe does not install a portable class or open a classical scope.
def main : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  unsafe Lean.enableInitializersExecution
  let native ← Lean.importModules #[{ module := `Init.Internal.Order.Basic }] {} (loadExts := true)
  unless Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" do
    throw (IO.userError "P1 metadata requires pinned Lean 4.35.0")
  for name in [`Lean.Order.PartialOrder, `Lean.Order.CCPO] do
    unless Lean.isClass native name do
      throw (IO.userError ("missing native P1 class: " ++ toString name))
    IO.println (Lean.Json.mkObj [
      ("schema", Lean.toJson ("pscv0-p1-native-class/1" : String)),
      ("name", Lean.toJson (toString name)),
      ("outputs", Lean.toJson ((Lean.getOutParamPositions? native name).map Array.toList)),
      ("outputLevels", Lean.toJson ((Lean.getOutLevelParamPositions? native name).map Array.toList))]).compress
  let registrations : List (Lean.Name × Lean.Name) := [
    (`Lean.Order.CCPO.toPartialOrder, `Lean.Order.PartialOrder),
    (`Lean.Order.instOrderPi, `Lean.Order.PartialOrder),
    (`Lean.Order.instCCPOPi, `Lean.Order.CCPO),
    (`Lean.Order.instPartialOrderPProd, `Lean.Order.PartialOrder),
    (`Lean.Order.instCCPOPProd, `Lean.Order.CCPO),
    (`Lean.Order.instPartialOrderOption, `Lean.Order.PartialOrder),
    (`Lean.Order.instCCPOOption, `Lean.Order.CCPO),
    (`Lean.Order.instPartialOrderUnit, `Lean.Order.PartialOrder),
    (`Lean.Order.instCCPOUnit, `Lean.Order.CCPO),
    (`Lean.Order.FlatOrder.instOrder, `Lean.Order.PartialOrder),
    (`Lean.Order.FlatOrder.instCCPO, `Lean.Order.CCPO)]
  for (name, className) in registrations do
    let some entry := (Lean.Meta.instanceExtension.getState native).instanceNames.find? name
      | throw (IO.userError ("missing native P1 instance: " ++ toString name))
    IO.println (Lean.Json.mkObj [
      ("schema", Lean.toJson ("pscv0-p1-native-instance/1" : String)),
      ("name", Lean.toJson (toString name)),
      ("class", Lean.toJson (toString className)),
      ("priority", Lean.toJson entry.priority)]).compress
  IO.println "PSCV0_M3_P1_NATIVE_METADATA: PASS selected native classes and ordinary instance registrations"
