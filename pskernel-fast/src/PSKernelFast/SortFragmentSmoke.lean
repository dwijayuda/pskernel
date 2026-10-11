import PSKernelFast.SortFragment

namespace PSKernelFast.Core

private def require (ok : Bool) (label : String) : IO Unit :=
  if ok then pure () else throw <| IO.userError label

private def expectFormed (params : List KName) (expr : KExpr)
    (expected : ULevel) : IO Unit :=
  match inferClosedSortFragment params expr with
  | .error issue =>
      throw <| IO.userError s!"valid formation unexpectedly failed: {repr issue}"
  | .ok level =>
      require (level == expected) "fragment inferred wrong resulting universe"

private def expectFailed (params : List KName) (expr : KExpr)
    (expected : FormationError) : IO Unit :=
  match inferClosedSortFragment params expr with
  | .ok _ => throw <| IO.userError "unimplemented/invalid formation returned success"
  | .error actual =>
      require (actual == expected)
        s!"fragment error classification mismatch: {repr actual}"

/-- A finite typed-formation check, with no proof/axiom-admission path. -/
def sortFragmentSmoke : IO Unit := do
  let x : KName := .str .anonymous "x"
  let u : KName := .str .anonymous "u"
  let v : KName := .str .anonymous "v"
  let lu : ULevel := .param u
  let lv : ULevel := .param v

  expectFormed [] (.sort .zero) (.succ .zero)
  expectFormed [u] (.sort lu) (.succ lu)
  expectFormed [u] (.sort (.imax lu (.succ .zero)))
    (.succ (.imax lu (.succ .zero)))

  let simplePi : KExpr :=
    .forallE x (.sort .zero) (.sort .zero) .default
  expectFormed [] simplePi (.imax (.succ .zero) (.succ .zero))
  let symbolicPi : KExpr :=
    .forallE x (.sort lu) (.sort lv) .implicit
  expectFormed [u, v] symbolicPi (.imax (.succ lu) (.succ lv))
  match inferClosedSortType [u, v] symbolicPi with
  | .ok (.sort level) =>
      require (level == .imax (.succ lu) (.succ lv))
        "inferred Pi output lost exact symbolic universe"
  | _ => throw <| IO.userError "typed sort output not preserved"

  expectFailed [] (.sort lu) .malformed
  expectFailed [u] (.sort (.mvar u)) .malformed
  expectFailed [] (.bvar 0) .malformed
  expectFailed [] (.fvar x) .malformed
  expectFailed [] (.mvar x) .malformed
  expectFailed [] (.forallE x (.sort .zero) (.bvar 1) .default)
    .malformed

  expectFailed [] (.forallE x (.sort .zero) (.bvar 0) .default)
    .unsupported
  expectFailed [] (.lam x (.sort .zero) (.bvar 0) .default)
    .unsupported
  expectFailed [] (.app (.sort .zero) (.sort .zero))
    .unsupported
  expectFailed [] (.letE x (.sort .zero) (.sort .zero) (.bvar 0) false)
    .unsupported

  IO.println "PSKernel-Fast G4.2: certified Sort / syntactic-Pi formation fragment PASS"
  IO.println "G4.2 limit: no general term typing, no DefEq, no theorem admission"
end PSKernelFast.Core

def main : IO Unit := PSKernelFast.Core.sortFragmentSmoke
