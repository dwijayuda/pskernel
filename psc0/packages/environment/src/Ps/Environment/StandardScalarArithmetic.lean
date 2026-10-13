import Ps.Environment.StandardScalarArithmeticData

-- Reviewed logical library closure. Only Nat.mod replaces a former primitive
-- axiom; every other name was absent at the frozen export boundary. The
-- native exporter rejects collisions and kernel-checks the combined candidate.
-- These proof helpers are not added to the executable support catalogue and
-- their native class/instance registrations are not implicitly imported.
def psStandardScalarArithmeticExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardScalarArithmeticDeclarations.foldl
    psEnvironmentInsert environment
  psStandardScalarArithmeticReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
