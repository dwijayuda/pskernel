import Ps.Environment.StandardFloatToBitsData

/-!
Pinned Lean 4.35.0 checked Float/Float32 read-only bit projections.
This layer owns checked projections. Executable bit/model transport is owned
by the shared typed erasure/IR boundary, separately from arithmetic/literals.
-/
def psStandardFloatToBitsExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardFloatToBitsDeclarations.foldl psEnvironmentInsert environment
  psStandardFloatToBitsReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment

def psStandardFloatModelProjectionRuntimeDeclarations : List PsDeclaration :=
  psStandardFloatToBitsDeclarations.filter fun d =>
    ["Float.Model.toBits", "Float32.Model.toBits"].contains
      (psNameToString (psDeclarationName d))
