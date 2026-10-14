import Ps.Environment.StandardSignedIdentityData

/-!
Pinned Lean 4.35.0 SInt/Basic selected checked logical structure identities.
Every inductive family is replayed in the official kernel with regenerated
constructor and recursor metadata. This is NOT executable signed arithmetic.
-/
def psStandardSignedIdentityExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardSignedIdentityDeclarations.foldl psEnvironmentInsert environment
  psStandardSignedIdentityReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
