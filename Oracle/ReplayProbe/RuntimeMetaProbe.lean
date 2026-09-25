module

prelude
public import Lean.Meta.WHNF

public section

namespace ProofScript.RuntimeProbe

/--
Run the real Lean 4.34 `Lean.Meta.whnfImp` implementation with the smallest
source-faithful CoreM/MetaM harness needed by the JavaScript bootstrap.

The environment is created by Lean's own `mkEmptyEnvironment`; the JS runtime
does not synthesize Meta/WHNF semantics.  This first gate intentionally targets
closed beta/zeta expressions that do not require declaration lookup.  Later
WHNF tranches can replace the empty environment with a pskernel-admitted
runtime-environment bridge.
-/
def whnfWithEmptyEnv (e : Lean.Expr) : IO Lean.Expr := do
  let env ← Lean.mkEmptyEnvironment
  let result ← EIO.toBaseIO <|
    Lean.Core.CoreM.run
      (ctx := {
        fileName := "<ProofScript.RuntimeProbe.whnf>"
        fileMap := default
        maxHeartbeats := 0
      })
      (s := { env := env })
      ((Lean.Meta.whnfImp e).run' {} {})
  match result with
  | .ok (value, _) => pure value
  | .error _ => throw <| IO.userError "Lean.Meta.whnfImp failed"

end ProofScript.RuntimeProbe
