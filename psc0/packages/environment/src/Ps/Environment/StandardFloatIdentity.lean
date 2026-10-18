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

-- Runtime support contains only the checked Model record layouts. Primitive
-- Float and conversions use the typed erasure boundary, not proof closures.
def psStandardFloatModelRuntimeDeclarations : List PsDeclaration :=
  psStandardFloatIdentityDeclarations.filter fun d =>
    ["Float.Model", "Float.Model.mk", "Float.Model.rec",
     "Float32.Model", "Float32.Model.mk", "Float32.Model.rec"].contains
      (psNameToString (psDeclarationName d))
