import Ps.MinKernel.Tests.IngressVectors

def main : IO Unit := do
  for index in List.range 64 do
    let result := psMinIngressVector index
    IO.println s!"PSC1_MIN_INGRESS_VECTOR {index} {result}"
    let canonical := String.ofList ((psMinCoreEncode (psMinIngressCandidate index)).map Char.ofNat)
    IO.println s!"PSC1_MIN_INGRESS_CANONICAL {index} {canonical}"
    if result != psMinIngressExpected index then
      throw (IO.userError s!"ingress vector {index} mismatch")
  IO.println "PSC1_MIN_INGRESS_PASS"
