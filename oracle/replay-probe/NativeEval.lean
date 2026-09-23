import Lean

open Lean

private def checkConstType (env : Environment) (typeName constName : Name) : Except String Unit :=
  match env.find? constName with
  | none => throw s!"NativeEval: unknown constant '{constName}'"
  | some info =>
    match info.type with
    | .const c _ =>
      if c == typeName then
        pure ()
      else
        throw s!"NativeEval: unexpected type at '{constName}', '{typeName}' expected"
    | _ =>
      throw s!"NativeEval: unexpected type at '{constName}', '{typeName}' expected"

/--
Mirror the final Lean 4.34 kernel native-reduction boundary.

The kernel's `ir::run_boxed_kernel` executes ordinary runtime IR directly and
does not apply `evalCheckMeta`. `Meta.reduceNatNative` / `reduceBoolNative`
route through `Environment.evalConstCheck`, whose default `evalConst` call
does apply that meta-only guard and can reject imported runtime declarations.

We therefore perform the same exact Nat/Bool declaration-head check here, then
call the same IR interpreter through `Environment.evalConst` with
`checkMeta := false` and empty options, matching the kernel execution path.
-/
private unsafe def evalNative (env : Environment) (kind : String) (constName : Name) : IO Json := do
  if kind == "nat" then
    IO.ofExcept <| checkConstType env `Nat constName
    let value ← IO.ofExcept <| env.evalConst Nat {} constName (checkMeta := false)
    return Json.mkObj [("kind", "nat"), ("value", s!"{value}")]
  else if kind == "bool" then
    IO.ofExcept <| checkConstType env `Bool constName
    let value ← IO.ofExcept <| env.evalConst Bool {} constName (checkMeta := false)
    return Json.mkObj [("kind", "bool"), ("value", value)]
  else
    throw <| IO.userError s!"NativeEval: expected kind nat or bool, got '{kind}'"

unsafe def main (args : List String) : IO Unit := do
  initSearchPath (← findSysroot)
  unless args.length == 3 do
    throw <| IO.userError "usage: NativeEval <module> <nat|bool> <constant>"
  let moduleName := args[0]!.toName
  let kind := args[1]!
  let constName := args[2]!.toName
  -- Native reduction is compiler execution. Load persistent environment
  -- extensions so @[implemented_by] and runtime compiler IR are visible.
  unsafe enableInitializersExecution
  let env ← importModules (loadExts := true) #[{module := moduleName}] {}
  IO.println (← evalNative env kind constName).compress
