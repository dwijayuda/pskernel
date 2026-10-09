import Ps.KernelCore.API.Kernel

-- Exercise the projection shortcut's resource contract independently of
-- structural size. Each constant node unfolds through a much longer chain.
def fuelChainName (side : String) (n : Nat) : PsKernelName :=
  .num (.str .anonymous side) n

def fuelBase : PsKernelExpr := .const (.str .anonymous "base") []

def fuelChain (side : String) : Nat → PsKernelExpr
  | 0 => fuelBase
  | n + 1 => .const (fuelChainName side (n + 1)) []

def addFuelChain (side : String) : Nat → PsKernelEnvironment → PsKernelEnvironment
  | 0, env => env
  | n + 1, env =>
      let prior := addFuelChain side n env
      psKernelEnvironmentAddUnchecked prior (.defnInfo {
        base := { name := fuelChainName side (n + 1), levelParams := [],
          type := .sort (.succ .zero) }
        value := fuelChain side n
        hints := .regular (n + 1)
        safety := .safe })

def main : IO Unit := do
  let env := addFuelChain "left" 20 (addFuelChain "right" 20 psKernelEnvironmentEmpty)
  let ctx := psKernelCheckerContextEmpty env
  let left := PsKernelExpr.proj (.str .anonymous "Fixture") 0 (fuelChain "left" 20)
  let right := PsKernelExpr.proj (.str .anonymous "Fixture") 0 (fuelChain "right" 20)
  let eq := fun (_c : PsKernelCheckerContext) (s : PsKernelCheckerState)
      (a b : PsKernelExpr) => Except.ok (psKernelExprEq a b, s)
  match psKernelDefEqProjectionShortcut 3 eq ctx psKernelCheckerStateEmpty left right with
  | .error _ => pure ()
  | _ => throw (IO.userError "small projection budget unexpectedly succeeded")
  match psKernelDefEqProjectionShortcut 128 eq ctx psKernelCheckerStateEmpty left right with
  | .ok (some true, _) => pure ()
  | .error e => throw (IO.userError ("caller projection budget was ignored: " ++ e))
  | _ => throw (IO.userError "alias-chain projections did not compare equal")
  IO.println "PSKERNEL_PROJECTION_CALLER_FUEL: PASS"
