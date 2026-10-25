import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_QUOT_ADMISSION_FAIL " ++ label))
  IO.println ("PSC1_QUOT_ADMISSION_ASSERT " ++ label)

private def expect {α : Type} : Except String α -> IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α -> IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError "public admission failed")

private def nm (value : String) := PsKernelName.str .anonymous value

private def compare (label : String)
    (actual : Option (Except String PsKernelEnvironment))
    (expected : Except String PsKernelEnvironment) : IO Unit := do
  match actual,expected with
  | some (.ok actual),.ok expected =>
      require label (actual.quotInitialized == expected.quotInitialized &&
        psKernelEnvironmentSize actual == psKernelEnvironmentSize expected &&
        (psKernelDagGeneratedPlanQuot actual).isSome ==
          (psKernelDagGeneratedPlanQuot expected).isSome)
  | some (.error actual),.error expected => require label (actual == expected)
  | _,_ => throw (IO.userError ("different result: " ++ label))

def main : IO Unit := do
  let u := nm "u"
  let eqType := psKernelExpectedEqType u
  let reflType := psKernelExpectedEqReflType u
  let reflName := PsKernelName.str psKernelEqName "refl"
  let empty ← expectPublic
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let eqDecl := PsKernelSimpleInductiveDecl.mk [u] psKernelEqName eqType
    [.mk reflName reflType] false 2
  let admitted ← expectPublic (psKernelV1AdmitDeclaration empty (.ordinaryInductive eqDecl))
  let (a,eqRoot) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty eqType)
  let (arena,reflRoot) ← expect (psKernelExprV2PagedImportIntoChecked a reflType)
  let refs := [
    PsKernelExprV2DeclarationRef.mk psKernelEqName [u] eqRoot none .inductiveDecl,
    PsKernelExprV2DeclarationRef.mk reflName [u] reflRoot none .constructorDecl]
  let environment := admitted.session.environment
  require "valid-Eq-owner-shape"
    (psKernelDagQuotMatchShape eqType arena eqRoot == some true)
  require "valid-refl-owner-shape"
    (psKernelDagQuotMatchShape reflType arena reflRoot == some true)
  compare "direct-complete-admission" (psKernelDagTryAdmitQuot environment arena refs)
    (psKernelAddQuot environment)
  require "absent-owner-declines"
    (psKernelDagTryAdmitQuot environment arena []).isNone
  let wrongKind := refs.map fun ref => { ref with kind := .axiomDecl }
  require "wrong-kind-declines"
    (psKernelDagTryAdmitQuot environment arena wrongKind).isNone
  let wrongLevels := refs.map fun ref => { ref with levelParams := [] }
  require "wrong-level-owner-declines"
    (psKernelDagTryAdmitQuot environment arena wrongLevels).isNone
  let wrongRoots := refs.map fun ref => { ref with type := arena.size + 1 }
  require "out-of-owner-root-declines"
    (psKernelDagTryAdmitQuot environment arena wrongRoots).isNone
  compare "missing-Eq-exact-error"
    (psKernelDagTryAdmitQuot empty.environment arena refs)
    (psKernelAddQuot empty.environment)
  let initialized ← expect (psKernelAddQuot environment)
  compare "initialized-bypass-preserves-environment"
    (psKernelDagTryAdmitQuot initialized psKernelExprV2PagedEmpty [])
    (.ok initialized)

  let eqInput := PsKernelDagInductive.mk psKernelEqName eqRoot
    [.mk reflName reflRoot]
  let result ← expectPublic
    (psKernelV1RunDag empty [] .safe arena
      [.admit (.ordinaryInductive [u] 2 eqInput false),.admit .quot,.admit .quot])
  require "public-same-batch-complete-and-idempotent"
    (result.replies.length == 3 &&
      result.session.environment.quotInitialized &&
      psKernelEnvironmentSize result.session.environment == psKernelEnvironmentSize initialized)

  for expected in [eqType,reflType] do
    let mutations : List PsKernelExpr := [
      .sort .zero,
      .mdata 0 expected,
      .forallE (nm "different") (.sort .zero) (.sort .zero) .default,
      .app (.const psKernelEqName []) (.bvar 17)]
    for mutation in mutations do
      let (owner,root) ← expect (psKernelExprV2PagedImportIntoChecked arena mutation)
      require "mutated-shape-exact-structural-result"
        (psKernelDagQuotMatchShape expected owner root ==
          some (psKernelExprEq mutation expected))

  for reserved in [psKernelQuotName,psKernelQuotMkName,
      psKernelQuotLiftName,psKernelQuotIndName] do
    let occupied ← expect (psKernelEnvironmentAdd environment
      (.axiomInfo (.mk (.mk reserved [] (.sort .zero)) false)))
    compare "reserved-name-exact-error-and-no-publication"
      (psKernelDagTryAdmitQuot occupied arena refs) (psKernelAddQuot occupied)
    require "reserved-failure-original-uninitialized" (!occupied.quotInitialized)

  IO.println "PSC1_QUOT_ADMISSION_PASS"
