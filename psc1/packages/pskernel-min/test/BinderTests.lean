import Ps.MinKernel.Tests.BinderVectors

def main : IO Unit := do
  for index in List.range 36 do
    let expected : Nat := if index < 21 then 1 else if index < 34 then 0 else 3
    let actual := psMinBinderVector index
    if actual != expected then
      throw (IO.userError s!"binder vector {index}: expected {expected}, got {actual}")
    IO.println s!"PSC1_MIN_BINDER_VECTOR {index} {actual}"
  IO.println "PSC1_MIN_BINDER_NATIVE_PASS 34"
