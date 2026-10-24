import BackendStateReference

def portableNext (value : Nat) : PsBackendStateExcept Nat String Nat :=
  psBackendStateBind (psBackendStateSet (value + 7))
    (fun _ => psBackendStateGet ())

def nativeNext (value : Nat) : StateT Nat (Except String) Nat := do
  set (value + 7)
  get

def main : IO Unit := do
  for state in [0, 1, 37, 1000000] do
    for value in [0, 7, 999] do
      let portable := psBackendStateBind (psBackendStatePure value) portableNext state
      let native := ((pure value >>= nativeNext) : StateT Nat (Except String) Nat) state
      unless portable == native do throw (IO.userError "state bind order")
    let first := psBackendStateBind (psBackendStateThrow "first")
      (fun (_ : Nat) => psBackendStateThrow "later") state
    unless first == (Except.error "first" : Except String (Nat × Nat)) do
      throw (IO.userError "first error priority")
    let lifted := psBackendStateLift (Except.ok 5 : Except String Nat) state
    unless lifted == Except.ok (5, state) do throw (IO.userError "lift state")
  IO.println "PSC1_BACKEND_STATE_CORRESPONDENCE: seven complete API equalities to StateT (Except), state sequencing/lift/first-error tests passed"
