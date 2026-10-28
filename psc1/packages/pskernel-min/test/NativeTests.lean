import Ps.MinKernel.Tests.Vectors


def main : IO Unit := do
  for index in List.range 16 do
    let expected := decide (index < 5)
    let actual := psMinRawVector index
    if actual != expected then
      throw (IO.userError s!"PSC1 min fragment vector {index}: expected {expected}, got {actual}")
    IO.println s!"PSC1_MIN_VECTOR {index} {actual}"
  IO.println "PSC1_MIN_NATIVE_VECTORS_PASS 16"
