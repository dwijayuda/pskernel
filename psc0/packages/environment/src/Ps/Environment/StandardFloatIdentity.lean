import Ps.Environment.StandardFloatIdentityData

/-!
F0 checked logical Float/Float32 identities, with no executable Float intrinsics.
The 51-entry asset was exported and rechecked against the pinned Lean 4.35.0
kernel; replacing the two legacy type axioms does NOT implement Float.ofBits,
arithmetic, literals or any backend ABI.
-/
def psStandardFloatIdentityExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardFloatIdentityDeclarations.foldl psEnvironmentInsert environment
  psStandardFloatIdentityReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
