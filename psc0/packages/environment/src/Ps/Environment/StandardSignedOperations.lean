import Ps.Environment.StandardSignedOperationsData

/-!
Pinned Lean 4.35.0 native checked signed fixed-width BitVec models.
The generated declarations do NOT enable executable signed IR or ABI.
-/
def psStandardSignedOperationsExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardSignedOperationsDeclarations.foldl psEnvironmentInsert environment
  psStandardSignedOperationsReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
