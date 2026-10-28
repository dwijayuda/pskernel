import Ps.MinKernel.Tests.OperationalVectors

def main : IO Unit := do
  let positive : List Nat := (List.cons 0 (List.cons 1 (List.cons 2 (List.cons 3 (List.cons 4 (List.cons 5 (List.cons 6 (List.cons 7 (List.cons 8 (List.cons 9 (List.cons 10 (List.cons 11 (List.cons 12 (List.cons 13 (List.cons 14 (List.cons 15 (List.cons 16 (List.cons 17 (List.cons 18 (List.cons 19 (List.cons 20 (List.cons 21 (List.cons 22 (List.cons 23 (List.cons 24 (List.cons 25 (List.cons 26 (List.cons 27 (List.cons 28 (List.cons 29 (List.cons 30 (List.cons 31 (List.cons 32 (List.cons 33 (List.cons 34 (List.cons 35 List.nil))))))))))))))))))))))))))))))))))))
  for index in List.range 78 do
    let expected := positive.contains index
    let actual := psMinOpVector index
    if actual != expected then
      throw (IO.userError s!"operational vector {index}: expected {expected}, got {actual}")
    IO.println s!"PSC1_MIN_OPERATIONAL_VECTOR {index} {actual}"
  IO.println "PSC1_MIN_OPERATIONAL_NATIVE_PASS 76"
