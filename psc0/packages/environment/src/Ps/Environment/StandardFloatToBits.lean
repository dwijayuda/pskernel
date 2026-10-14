import Ps.Environment.StandardFloatToBitsData

/-!
Pinned Lean 4.35.0 checked Float/Float32 read-only bit projections.
No Float.ofBits, numeric runtime primitive or floating ABI enabled.
-/
def psStandardFloatToBitsExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardFloatToBitsDeclarations.foldl psEnvironmentInsert environment
  psStandardFloatToBitsReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
