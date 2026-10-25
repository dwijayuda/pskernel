import Ps.BackendWasm.CompilerService
import WasmNatDivModReference
private def fixture : PsVerifiedIrModule := {
  imports := [],structures := [],inductives := []
  declarations := [
    { name := "quotient", typeParameters := [], parameters := [
        {name := "a",type := .primitive .nat},{name := "b",type := .primitive .nat}],
      resultType := .primitive .nat, body := .intrinsic .natDiv [] [.var "a",.var "b"] },
    { name := "remainder", typeParameters := [], parameters := [
        {name := "a",type := .primitive .nat},{name := "b",type := .primitive .nat}],
      resultType := .primitive .nat, body := .intrinsic .natMod [] [.var "a",.var "b"] }
  ]
}
def main : IO Unit := do
  match psStrictValidateModule fixture with
  | .error _ => throw (IO.userError "Nat divmod fixture strict IR refused")
  | .ok _ => pure ()
  let lowered <- match psWasmLowerSpecializedModule (.mk .wasm32) fixture with
    | .error _ => throw (IO.userError "Nat divmod fixture lower refused")
    | .ok value => pure value
  let target := psWasmServiceTransport lowered ["quotient","remainder"]
  if (target.functions.filter (fun f => f.name == psWasmNatDivModFn)).length != 1 then
    throw (IO.userError "Nat divmod single replacement boundary")
  IO.FS.createDirAll "dist/wasm-nat-divmod"
  for legacy in [false,true] do
    let actual := if legacy then
        {target with functions := target.functions.map (fun f =>
          if f.name == psWasmNatDivModFn then psWasmNatDivModReference else f)}
      else target
    match psWasmIrValidateModule actual with
    | .error _ => throw (IO.userError "Nat divmod target validation refused")
    | .ok _ => pure ()
    let bytes <- match Ps.Internal.WasmBinaryBytes.psWasmEncodeModule actual with
      | .error _ => throw (IO.userError "Nat divmod encoding refused")
      | .ok bytes => pure bytes
    let hex := "psc1-wasm-hex/1:" ++ Ps.Internal.WasmCompilerService.hexWorker bytes psTextBuilderEmpty
    IO.FS.writeFile ("dist/wasm-nat-divmod/" ++ (if legacy then "legacy" else "current") ++ ".wasm.hex") hex
  IO.println "PSC1_WASM_NAT_DIVMOD_NATIVE: strict source/target IR; exact original divmod function retained; all other runtime functions shared"
