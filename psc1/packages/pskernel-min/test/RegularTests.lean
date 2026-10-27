import Ps.MinKernel.Tests.RegularVectors

def main : IO Unit := do
  let expectedIndices : List Nat := (List.cons 0 (List.cons 1 (List.cons 2 (List.cons 3 (List.cons 4 (List.cons 5 (List.cons 6 (List.cons 7 (List.cons 8 (List.cons 9 (List.cons 10 (List.cons 11 (List.cons 12 (List.cons 13 (List.cons 14 (List.cons 15 (List.cons 16 (List.cons 17 (List.cons 18 (List.cons 19 List.nil))))))))))))))))))))
  for index in List.range 59 do
    let expected := expectedIndices.contains index
    let actual := psMinRegVector index
    if actual != expected then
      throw (IO.userError s!"regular profile vector {index}: expected {expected}, got {actual}")
    IO.println s!"PSC1_MIN_REGULAR_VECTOR {index} {actual}"
  IO.println "PSC1_MIN_REGULAR_NATIVE_PASS 57"
