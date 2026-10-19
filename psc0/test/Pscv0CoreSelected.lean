import Ps.Compiler.Pscv0Engine
import PsKernelLean.Replay
import PsKernelLean.Protocol

-- v7.2 §6 explicitly leaves syntax absent from pinned Standard to a
-- named extension. These are actual native parser controls, independently
-- of the portable selected-head table and its refusal diagnostics.
run_cmd do
  let environment ← Lean.getEnv
  for source in ["exfalso", "decide", "by_cases h : True", "ext x"] do
    match Lean.Parser.runParserCategory environment (Lean.Name.mkSimple "tactic") source with
    | .ok _ => pure ()
    | .error message => throwError "selected native proof head failed to parse: {source}: {message}"
  for source in ["use 0", "by_contra h"] do
    match Lean.Parser.runParserCategory environment (Lean.Name.mkSimple "tactic") source with
    | .error _ => pure ()
    | .ok _ => throwError "extension-only proof head is present in pinned Standard: {source}"

private def requireSelected (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError message)

private def baseName : PsName := psRootName "CoreSelectedIdentity"
private def sourceName (suffix : String) : PsName :=
  psNameAppendStr (psRootName "CoreSelected") suffix

private def identityType : PsExpr :=
  .forallE (psRootName "A") (.sortE (.succ .zero))
    (.forallE (psRootName "x") (.bvar 0) (.bvar 1) .explicit) .explicit

private def identityValue : PsExpr :=
  .lam (psRootName "A") (.sortE (.succ .zero))
    (.lam (psRootName "x") (.bvar 0) (.bvar 0) .explicit) .explicit

private def baseDeclaration : PsDeclaration :=
  .definitionDecl baseName [] identityType identityValue

private def leanSource : String :=
  "namespace CoreSelected\n" ++
  "def copy (A : Type) (x : A) : A := CoreSelectedIdentity A x\n" ++
  "def twice (A : Type) (f : A -> A) (x : A) : A := copy A (f (f x))\n" ++
  "end CoreSelected\n"

private def proofScriptSource : String :=
  "namespace CoreSelected\n" ++
  "function copy(A: Type, x: A): A := CoreSelectedIdentity(A, x)\n" ++
  "function twice(A: Type, f: A -> A, x: A): A := copy(A, f(f(x)))\n" ++
  "end CoreSelected\n"

-- The expected closed Core model retains both calls of the source parameter.
-- Equality here ignores binder spellings, not applications or binder kinds.
private def twiceValue : PsExpr :=
  .lam (psRootName "A") (.sortE (.succ .zero))
    (.lam (psRootName "f")
      (.forallE (psRootName "_") (.bvar 0) (.bvar 1) .explicit)
      (.lam (psRootName "x") (.bvar 1)
        (.app (.app (.constE (sourceName "copy") []) (.bvar 2))
          (.app (.bvar 1) (.app (.bvar 1) (.bvar 0)))) .explicit) .explicit) .explicit

private def prepareSelected (profile : PsCompilerProfileContext)
    (kind : PsCompilerSourceKind) (source : String) :
    IO PsCompilerEnginePreparationOutput :=
  match psCompilerEnginePreparePscv0WithOutput profile kind source with
  | .ok output => pure output
  | .error error => throw (IO.userError (psCompilerPscv0Error error))

private def requireElaborationRefusal (profile : PsCompilerProfileContext)
    (kind : PsCompilerSourceKind) (source : String) : IO Unit := do
  match psCompilerParsePscv0 source kind with
  | .error message =>
      throw (IO.userError ("CORE-SELECTED: refusal failed to parse: " ++ message))
  | .ok _ => pure ()
  match psCompilerEnginePreparePscv0WithOutput profile kind source with
  | .error (.elaboration _) => pure ()
  | .error error =>
      throw (IO.userError ("CORE-SELECTED: refusal changed phase: " ++
        psCompilerPscv0Error error))
  | .ok _ => throw (IO.userError "CORE-SELECTED: invalid source was prepared")

private def admitSelected (environment : Lean.Kernel.Environment)
    (admissions : String) : IO Lean.Kernel.Environment := do
  let declarations ← match PsKernelLean.decodeCanonicalAdmissions admissions with
    | .ok declarations => pure declarations
    | .error error => throw (IO.userError error.message)
  let checked ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    declarations.toList.foldlM (fun (current : Lean.Kernel.Environment)
        (declaration : Lean.Declaration) =>
      (current.addDeclCore 2000000 20000
        (PsKernelLean.psKernelWithDefinitionHeight current declaration) none).mapError
          PsKernelLean.kernelExceptionSummary) environment
  match checked with
  | .ok environment => pure environment
  | .error message => throw (IO.userError ("CORE-SELECTED: kernel rejection: " ++ message))

def main : IO Unit := do
  for (kind, source) in [
      (PsCompilerSourceKind.lean, "theorem extensionOnly : True := by use 0\n"),
      (.lean, "theorem extensionOnly : True := by by_contra h\n"),
      (.proofScript, "theorem extensionOnly: True := by { use 0 }\n"),
      (.proofScript, "theorem extensionOnly: True := by { by_contra h }\n")] do
    match psCompilerParsePscv0Program kind source with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "CORE-SELECTED: extension-only tactic entered the closed grammar")
  IO.println "PSCV0_CORE_PROOF_HEAD_BOUNDARY: PASS four native selected heads and paired native/portable use/by_contra grammar boundaries"
  -- The exact base roster is checked from empty, at trust zero and finite budgets.
  let checked ← PsKernelLean.buildLeanPreludeEnvironmentFromDeclarations [baseDeclaration]
  let kernel ← match checked with
    | .ok environment => pure environment
    | .error error => throw (IO.userError error.message)
  let some environment := psEnvironmentAdd psEnvironmentEmpty baseDeclaration
    | throw (IO.userError "CORE-SELECTED: duplicate base declaration")
  let profile : PsCompilerProfileContext := {
    baseEnvironment := environment
    runtimePrelude := fun _ _ => [] }
  let emptyProfile : PsCompilerProfileContext := {
    baseEnvironment := psEnvironmentEmpty
    runtimePrelude := fun _ _ => [] }
  requireSelected (environment.declarations.length == 1)
    "CORE-SELECTED: base roster changed"
  requireSelected (psEnvironmentFind environment psNatName).isNone
    "CORE-SELECTED: Full Nat leaked into the portable base"
  requireSelected (kernel.find? `Nat).isNone
    "CORE-SELECTED: Full Nat leaked into the independent kernel"
  let sources : List (PsCompilerSourceKind × String) :=
    [(.lean, leanSource), (.proofScript, proofScriptSource)]
  let outputs ← sources.mapM fun (kind, source) => do
    let output ← prepareSelected profile kind source
    let names := output.prepared.declarations.map psDeclarationName
    let expected := [sourceName "copy", sourceName "twice"]
    requireSelected (names.length == expected.length &&
      (names.zip expected).all (fun (a, b) => psNameEq a b))
      "CORE-SELECTED: prepared source roster changed"
    requireSelected (output.prepared.recursorWorkerGroups.isEmpty &&
      output.prepared.noncomputableNames.isEmpty)
      "CORE-SELECTED: ordinary source preparation added execution policy"
    let some (.definitionDecl _ levels _ value) :=
        output.prepared.declarations.find? (fun declaration =>
          psNameEq (psDeclarationName declaration) (sourceName "twice"))
      | throw (IO.userError "CORE-SELECTED: twice is not an ordinary definition")
    requireSelected (levels.isEmpty && psExprAlphaEq value twiceValue)
      "CORE-SELECTED: checked source body lost its two applications"
    let canonical ← match psCompilerEngineAdmissionsFromPrepared output.prepared with
      | .ok value => pure value
      | .error error => throw (IO.userError (psCompilerPscv0Error error))
    requireSelected (canonical == output.admissions)
      "CORE-SELECTED: retained profile changed canonical source admissions"
    let admitted ← admitSelected kernel output.admissions
    requireSelected (expected.all fun name =>
      (admitted.find? (PsKernelLean.toLeanName name)).isSome)
      "CORE-SELECTED: source declaration missing after independent admission"
    requireSelected (admitted.find? `Nat).isNone
      "CORE-SELECTED: Full Nat leaked into checked source admission"
    pure output
  let [leanOutput, psOutput] := outputs
    | throw (IO.userError "CORE-SELECTED: paired output count changed")
  requireSelected (leanOutput.admissions == psOutput.admissions)
    "CORE-SELECTED: selected Lean and PS canonical admissions differ"

  -- The same valid source cannot resolve its base from an empty profile.
  for (kind, source) in sources do
    requireElaborationRefusal emptyProfile kind source
    let imported := "import Missing.Core\n" ++ source
    match psCompilerParsePscv0Program kind imported with
    | .error message =>
        throw (IO.userError ("CORE-SELECTED: import control failed to parse: " ++ message))
    | .ok _ => pure ()
    match psCompilerEnginePreparePscv0WithOutput profile kind imported with
    | .error (.normalization "PSCV0-NATIVE-MODULE-IMPORTS-PENDING") => pure ()
    | .error error =>
        throw (IO.userError ("CORE-SELECTED: import refusal changed owner: " ++
          psCompilerPscv0Error error))
    | .ok _ => throw (IO.userError "CORE-SELECTED: bounded entry accepted imports")

  requireElaborationRefusal profile .lean
    "def bad (A : Type) (x : A) : A := A\n"
  requireElaborationRefusal profile .proofScript
    "function bad(A: Type, x: A): A := A\n"
  IO.println "PSCV0_CORE_SELECTED: paired selected source and independent canonical admission passed"
