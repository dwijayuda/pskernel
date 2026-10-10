import PSKernelFast.Quote

/-!
# PSKernel-Fast G6 diagnostic: untyped beta/let evaluator comparison

Both algorithms consume identical closed syntax and must return exactly the
same raw result. This is not a kernel benchmark, not a Lean conformance test,
and not a representative application performance claim. The measured time
includes head normalization and any closure reification, but excludes raw
input construction and export parsing.
-/

open PSKernelFast

def makeWorkload (depth : Nat) (leaf : RawExpr) : RawExpr :=
  (List.range depth).foldl (fun expr i =>
    if i % 2 == 0 then
      .app (.lam (Name.simple "x") (.sort .zero) (.bvar 0) .default) expr
    else
      .letE (Name.simple "x") (.sort .zero) expr (.bvar 0) false) leaf

def main : IO Unit := do
  let args ← IO.getArgs
  let mode := (args[0]?).getD "reference"
  let depth := ((args[1]?).getD "24").toNat?.getD 24
  let repetitions := ((args[2]?).getD "1500").toNat?.getD 1500

  if mode != "reference" && mode != "closure" then
    throw (IO.userError "mode must be reference or closure")
  if depth == 0 || depth > 96 || repetitions == 0 || repetitions > 10000 then
    throw (IO.userError "out-of-range diagnostic parameters")

  let leaves : Array RawExpr :=
    (List.range 16).toArray.map (fun i =>
      .const (.num (Name.simple "leaf") i) [])
  let inputs := leaves.map (makeWorkload depth)
  let fuel := 16 * depth + 128
  let mut checksum : Nat := 0
  for i in [:repetitions] do
    let input := inputs[i % inputs.size]!
    let result : Except Failure RawExpr :=
      if mode == "reference" then
        referenceWhnfFuel fuel input
      else
        match whnfFuel fuel (.term input []) with
        | .error err => .error err
        | .ok value => quoteClosureFuel (fuel * 2) value

    match result with
    | .ok (.const (.num (.str .anonymous "leaf") n) []) =>
        checksum := checksum + n + 1
    | .ok other =>
        throw (IO.userError s!"unexpected normalized form: {repr other}")
    | .error err =>
        throw (IO.userError s!"incomplete evaluator run: {repr err}")

  IO.println s!"mode={mode} depth={depth} iterations={repetitions} checksum={checksum}"
