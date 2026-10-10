import Ps.KernelCore.API.Kernel

def dispatchContext : PsKernelCheckerContext :=
  psKernelCheckerContextEmpty psKernelEnvironmentEmpty

def binaryExpr (name : PsKernelName) (left right : PsKernelExpr) : PsKernelExpr :=
  PsKernelExpr.app (PsKernelExpr.app (PsKernelExpr.const name []) left) right

def poisonWhnf
    (_context : PsKernelCheckerContext) (_state : PsKernelCheckerState)
    (_expr : PsKernelExpr) : Except String (PsKernelExpr × PsKernelCheckerState) :=
  .error "unexpected operand evaluation"

def checkNoReduction (result : Except String (Option PsKernelExpr × PsKernelCheckerState)) : Bool :=
  match result with
  | .ok (none, _) => true
  | _ => false

def main : IO Unit := do
  let stuck := PsKernelExpr.const (PsKernelName.str .anonymous "stuck") []
  let rhs := PsKernelExpr.const (PsKernelName.str .anonymous "poison") []
  let unrelated := PsKernelName.str .anonymous "unrelated"
  unless checkNoReduction (psKernelReduceNatWith poisonWhnf dispatchContext
      psKernelCheckerStateEmpty (binaryExpr unrelated stuck rhs)) do
    throw (IO.userError "non-Nat application evaluated an operand")
  let leftOnly := fun (_c : PsKernelCheckerContext) (s : PsKernelCheckerState) (e : PsKernelExpr) =>
    if psKernelExprEq e stuck then Except.ok (stuck, s) else Except.error "right operand evaluated"
  unless checkNoReduction (psKernelReduceNatWith leftOnly dispatchContext
      psKernelCheckerStateEmpty (binaryExpr psKernelNatAddName stuck rhs)) do
    throw (IO.userError "non-numeral left operand did not short-circuit")
  match psKernelReduceNatWith poisonWhnf dispatchContext psKernelCheckerStateEmpty
      (binaryExpr psKernelNatAddName stuck rhs) with
  | .error "unexpected operand evaluation" => pure ()
  | _ => throw (IO.userError "supported operation swallowed left evaluation failure")
  let identity := fun (_c : PsKernelCheckerContext) (s : PsKernelCheckerState) (e : PsKernelExpr) =>
    Except.ok (e, s)
  match psKernelReduceNatWith identity dispatchContext psKernelCheckerStateEmpty
      (binaryExpr psKernelNatAddName (.lit (.nat 19)) (.lit (.nat 23))) with
  | .ok (some (.lit (.nat 42)), _) => pure ()
  | _ => throw (IO.userError "supported addition no longer reduces")
  IO.println "PSKERNEL_NAT_DISPATCH_435: PASS"
