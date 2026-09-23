import Lean

open Lean

private def kernelWhnf (env : Environment) (e : Expr) : IO Expr := do
  match Kernel.whnf env {} e with
  | .ok value => pure value
  | .error ex =>
    throw <| IO.userError (← ex.toMessageData {} |>.toString)

/--
Reference implementation for pskernel's optional native-reduction provider.

Do not route this through Meta.reduceNatNative / reduceBoolNative or
Environment.evalConstCheck: those Meta APIs add declaration-type and meta-IR
availability checks that the final Lean 4.34 C++ kernel does not perform.

Instead construct the exact kernel marker and ask Lean 4.34's own Kernel.whnf.
That enters type_checker.cpp::reduce_native, including its actual compiler-IR
execution and runtime object-shape validation. The helper only serializes the
already-validated WHNF result for the TypeScript oracle provider.
-/
private unsafe def evalNative (env : Environment) (kind : String) (constName : Name) : IO Json := do
  let arg := mkConst constName
  if kind == "nat" then
    let result ← kernelWhnf env (mkApp (mkConst ``Lean.reduceNat) arg)
    match result with
    | .lit (.natVal value) =>
      return Json.mkObj [("kind", "nat"), ("value", s!"{value}")]
    | _ =>
      throw <| IO.userError s!"NativeEval: kernel returned unexpected Nat WHNF for '{constName}': {result}"
  else if kind == "bool" then
    let result ← kernelWhnf env (mkApp (mkConst ``Lean.reduceBool) arg)
    if result.isConstOf ``Bool.true then
      return Json.mkObj [("kind", "bool"), ("value", true)]
    else if result.isConstOf ``Bool.false then
      return Json.mkObj [("kind", "bool"), ("value", false)]
    else
      throw <| IO.userError s!"NativeEval: kernel returned unexpected Bool WHNF for '{constName}': {result}"
  else
    throw <| IO.userError s!"NativeEval: expected kind nat or bool, got '{kind}'"

unsafe def main (args : List String) : IO Unit := do
  initSearchPath (← findSysroot)
  unless args.length == 3 do
    throw <| IO.userError "usage: NativeEval <module> <nat|bool> <constant>"
  let moduleName := args[0]!.toName
  let kind := args[1]!
  let constName := args[2]!.toName
  -- Native reduction is compiler execution. The imported kernel environment
  -- needs runtime IR and persistent extensions for @[implemented_by]/externs.
  unsafe enableInitializersExecution
  let env ← importModules (loadExts := true) #[{module := moduleName}] {}
  IO.println (← evalNative env kind constName).compress
