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

/--
Run the same upstream WHNF implementation with a caller-supplied real
`MetavarContext`.  Returning the resulting context makes the smoke gate check
that MetaM state is threaded by Lean source rather than synthesized by the JS
host.
-/
def whnfWithEmptyEnvAndMCtx
    (mctx : Lean.MetavarContext)
    (e : Lean.Expr) : IO (Lean.Expr × Lean.MetavarContext) := do
  let env ← Lean.mkEmptyEnvironment
  let result ← EIO.toBaseIO <|
    Lean.Core.CoreM.run
      (ctx := {
        fileName := "<ProofScript.RuntimeProbe.whnf-mctx>"
        fileMap := default
        maxHeartbeats := 0
      })
      (s := { env := env })
      ((Lean.Meta.whnfImp e).run {} { mctx := mctx })
  match result with
  | .ok ((value, metaState), _) => pure (value, metaState.mctx)
  | .error _ => throw <| IO.userError "Lean.Meta.whnfImp with mctx failed"

end ProofScript.RuntimeProbe
