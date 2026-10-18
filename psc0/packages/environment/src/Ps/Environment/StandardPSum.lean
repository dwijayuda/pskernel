import Ps.Environment.StandardPSumData

-- Exact pinned Sort-polymorphic sum, independently exported and replayed.
-- No class, instance, axiom or target intrinsic is registered by this extension.
def psStandardPSumExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardPSumDeclarations.foldl psEnvironmentInsert environment
  psStandardPSumReducibility.foldl
    (fun env (name, status) => psEnvironmentSetReducibility env name status) environment
