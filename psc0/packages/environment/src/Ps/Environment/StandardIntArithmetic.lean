import Ps.Environment.StandardIntArithmeticData

-- Exact native Lean 4.35.0 logical arithmetic and its checked proof closure.
-- Replace the four historical Int computational axioms in the final selected
-- environment. Earlier frozen asset stages remain reproducible.
-- Proof helpers do not enter the executable support catalogue: Int operations
-- retain their existing typed runtime intrinsics and independent target gates.
def psStandardIntArithmeticExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardIntArithmeticModelDeclarations.foldl
    psEnvironmentInsert environment
  psStandardIntArithmeticModelReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
