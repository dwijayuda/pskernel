import Lean

open Lean

private unsafe def evalNative (env : Environment) (kind : String) (constName : Name) : IO Json := do
  let action : MetaM Json :=
    if kind == "nat" then do
      let value ← Meta.reduceNatNative constName
      return Json.mkObj [("kind", "nat"), ("value", s!"{value}")]
    else if kind == "bool" then do
      let value ← Meta.reduceBoolNative constName
      return Json.mkObj [("kind", "bool"), ("value", value)]
    else
      throwError "NativeEval: expected kind nat or bool, got '{kind}'"
  let (result, _, _) ← Meta.MetaM.toIO action
    { fileName := "<pskernel-native-eval>", fileMap := default }
    { env }
  return result

unsafe def main (args : List String) : IO Unit := do
  initSearchPath (← findSysroot)
  unless args.length == 3 do
    throw <| IO.userError "usage: NativeEval <module> <nat|bool> <constant>"
  let moduleName := args[0]!.toName
  let kind := args[1]!
  let constName := args[2]!.toName
  -- Native reduction is compiler execution. Load persistent environment
  -- extensions so attributes such as @[implemented_by] are visible to evalConstCheck.
  unsafe enableInitializersExecution
  let env ← importModules (loadExts := true) #[{module := moduleName}] {}
  IO.println (← evalNative env kind constName).compress
