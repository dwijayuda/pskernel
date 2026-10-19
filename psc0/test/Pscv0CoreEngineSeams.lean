import Ps.Compiler.Engine
import Ps.CompilerIr.Checked
import PsKernelLean.Replay
import PsKernelLean.Protocol

-- These closed identity declarations are an isolated probe seed, not a Core
-- Standard candidate. No axiom, primitive, selected asset or profile label is used.
private def baseName : PsName := .str .anonymous "CoreEngineIdentity"
private def marker32Name : PsName := .str .anonymous "CoreEngineMarker32"
private def marker64Name : PsName := .str .anonymous "CoreEngineMarker64"
private def sourceName : PsName := .str .anonymous "coreEngineUse"

private def identityType : PsExpr :=
  .forallE (.str .anonymous "A") (.sortE (.succ .zero))
    (.forallE (.str .anonymous "x") (.bvar 0) (.bvar 1) .explicit)
    .explicit

private def identityValue : PsExpr :=
  .lam (.str .anonymous "A") (.sortE (.succ .zero))
    (.lam (.str .anonymous "x") (.bvar 0) (.bvar 0) .explicit)
    .explicit

private def identityDeclaration (name : PsName) : PsDeclaration :=
  .definitionDecl name [] identityType identityValue

private def baseDeclarations : List PsDeclaration :=
  [identityDeclaration baseName, identityDeclaration marker32Name,
    identityDeclaration marker64Name]

private def probeProfile : PsCompilerProfileContext := {
  baseEnvironment := baseDeclarations.foldl psEnvironmentInsert psEnvironmentEmpty
  runtimePrelude := fun environment wordSize =>
    if psEnvironmentContains environment sourceName then
      identityDeclaration baseName :: (match wordSize with
        | none => []
        | some .bits32 => [identityDeclaration marker32Name]
        | some .bits64 => [identityDeclaration marker64Name])
    else [] }

private def emptyProfile : PsCompilerProfileContext := {
  baseEnvironment := psEnvironmentEmpty
  runtimePrelude := fun _ _ => [] }

private def requireEngine (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError ("CORE-ENGINE: " ++ message))

private def compilerFailure : PsCompilerError → String
  | .normalization message => message
  | .elaboration (.scope message) => message
  | .elaboration (.data message) => message
  | .elaboration (.unknownName name) => "unknown name " ++ psNameToString name
  | .elaboration (.infer (.unknownConstant name)) =>
      "unknown constant " ++ psNameToString name
  | .erasure (.unknownConstant name) => "runtime constant " ++ psNameToString name
  | _ => "compiler refusal"

private def takeEngine {α : Type} (phase : String)
    (result : Except PsCompilerError α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError
      ("CORE-ENGINE: " ++ phase ++ ": " ++ compilerFailure error))

-- Consume the actual canonical wire output under the independently replayed
-- seed. The existing protocol module is used only as a decoder; its historical
-- provider metadata strings are not selected or treated as authority.
private def checkAdmissions (seed : Lean.Kernel.Environment)
    (admissions : String) : IO Unit := do
  let checked ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    (do
      let declarations ← (PsKernelLean.decodeCanonicalAdmissions admissions).mapError
        (fun error => error.message)
      let mut environment := seed
      for original in declarations do
        let declaration := PsKernelLean.psKernelWithDefinitionHeight environment original
        match environment.addDeclCore 2000000 20000 declaration none with
        | .ok next => environment := next
        | .error error =>
            throw ("official kernel rejected canonical source: " ++
              PsKernelLean.kernelExceptionSummary error)
      pure () : Except String Unit)
  match checked with
  | .ok _ => pure ()
  | .error error => throw (IO.userError ("CORE-ENGINE: " ++ error))

-- The exact canonical dependency must survive preparation and serialization.
-- An internal environment rebuild only inserts declarations; admission occurs
-- in the official kernel under the actual supplied base.
private def checkMissingBaseAdmission (admissions : String) : IO Unit := do
  let declarations ← match PsKernelLean.decodeCanonicalAdmissions admissions with
    | .ok declarations => pure declarations
    | .error error => throw (IO.userError ("CORE-ENGINE: " ++ error.message))
  let [.defnDecl info] := declarations.toList
    | throw (IO.userError "CORE-ENGINE: unexpected canonical source declaration")
  let retainsBase := info.value.foldConsts false fun name seen =>
    seen || name == PsKernelLean.toLeanName baseName
  requireEngine (info.name == PsKernelLean.toLeanName sourceName && retainsBase)
    "canonical source lost its explicit base dependency"
  let emptyKernel := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  let result ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    emptyKernel.addDeclCore 2000000 20000
      (PsKernelLean.psKernelWithDefinitionHeight emptyKernel (.defnDecl info)) none
  match result with
  | .error (.unknownConstant _ missing) =>
      requireEngine (missing == PsKernelLean.toLeanName baseName)
        "empty-base admission refused a different dependency"
  | .error error => throw (IO.userError
      ("CORE-ENGINE: unexpected empty-base refusal: " ++
        PsKernelLean.kernelExceptionSummary error))
  | .ok _ => throw (IO.userError
      "CORE-ENGINE: the official empty kernel admitted a missing base dependency")

private def checkRuntime (prepared : PsCompilerEnginePrepared)
    (wordSize : Option PsVerifiedIrWordSize) (marker : Option String) : IO Unit := do
  let ir ← takeEngine "typed erasure"
    (psCompilerEngineVerifiedIrFromPrepared prepared wordSize)
  let report := psCheckVerifiedIrModule psIrCheckDefaultOptions ir
  requireEngine (report.accepted && report.traversalComplete)
    "typed IR validation failed"
  let expected := ["CoreEngineIdentity", "coreEngineUse"] ++ marker.toList
  requireEngine (ir.declarations.length == expected.length &&
      expected.all (fun name => ir.declarations.any (fun declaration =>
        declaration.name == name)))
    "runtime selector received the wrong final environment or word size"
  requireEngine (ir.internalNames.contains "CoreEngineIdentity" &&
      !ir.internalNames.contains "coreEngineUse")
    "runtime support lost its internal ownership"

private def checkSource (seed : Lean.Kernel.Environment)
    (kind : PsCompilerSourceKind) (source natSource : String) : IO Unit := do
  let prepared ← takeEngine "prepare" (psCompilerEnginePrepareSource probeProfile kind source)
  requireEngine (prepared.declarations.length == 1)
    "source declaration roster changed"
  requireEngine (psEnvironmentContains prepared.profile.baseEnvironment baseName &&
      !psEnvironmentContains prepared.profile.baseEnvironment sourceName &&
      !psEnvironmentContains prepared.profile.baseEnvironment (.str .anonymous "Nat"))
    "prepared value did not retain the original isolated base"
  let environment ← takeEngine "rebuild" (psCompilerEngineEnvironmentFromPrepared prepared)
  requireEngine (psEnvironmentContains environment baseName &&
      psEnvironmentContains environment sourceName &&
      !psEnvironmentContains environment (.str .anonymous "Nat"))
    "rebuilding the prepared value selected another base"
  let admissions ← takeEngine "admissions" (psCompilerEngineAdmissionsFromPrepared prepared)
  checkAdmissions seed admissions
  let started := psCompilerEnginePreparationStart probeProfile kind
  let stepped ← takeEngine "preparation step"
    (psCompilerEnginePreparationStep started source)
  let finished ← takeEngine "preparation finish"
    (psCompilerEnginePreparationFinish stepped)
  let resumedAdmissions ← takeEngine "resumed admissions"
    (psCompilerEngineAdmissionsFromPrepared finished)
  requireEngine (resumedAdmissions == admissions)
    "incremental preparation changed the canonical source"
  requireEngine (psEnvironmentContains finished.profile.baseEnvironment baseName &&
      !psEnvironmentContains finished.profile.baseEnvironment sourceName)
    "incremental preparation changed the original profile base"
  checkRuntime prepared none none
  checkRuntime prepared (some .bits32) (some "CoreEngineMarker32")
  checkRuntime prepared (some .bits64) (some "CoreEngineMarker64")
  -- The empty profile must not inherit a dependency or fall back to Full.
  match psCompilerEnginePrepareSource emptyProfile kind source with
  | .error (.elaboration _) => pure ()
  | _ => throw (IO.userError "CORE-ENGINE: missing explicit base was not refused")
  match psCompilerEnginePrepareSource emptyProfile kind natSource with
  | .error (.elaboration _) => pure ()
  | _ => throw (IO.userError "CORE-ENGINE: Nat silently inherited a selected prelude")
  -- Serialization and environment insertion do not authenticate a record.
  -- Require the same retained wire graph to fail at actual kernel admission
  -- without its base; a future artifact loader must also bind its authorized
  -- context and manifest, independently of a caller-claimed name or digest.
  let detached := { prepared with profile := emptyProfile }
  let detachedAdmissions ← takeEngine "detached admissions"
    (psCompilerEngineAdmissionsFromPrepared detached)
  requireEngine (detachedAdmissions == admissions)
    "detaching the base changed the canonical source graph"
  checkMissingBaseAdmission detachedAdmissions

def main : IO Unit := do
  let result ← PsKernelLean.buildLeanPreludeEnvironmentFromDeclarations baseDeclarations
  let seed ← match result with
    | .ok environment => pure environment
    | .error error => throw (IO.userError error.message)
  requireEngine (!(seed.find? `Nat).isSome)
    "the isolated native seed contains Nat"
  checkSource seed .lean
    "def coreEngineUse (A : Type) (x : A) : A := CoreEngineIdentity A x"
    "def coreEngineNat (x : Nat) : Nat := x"
  checkSource seed .proofScript
    "function coreEngineUse(A: Type, x: A): A := CoreEngineIdentity(A, x)"
    "function coreEngineNat(x: Nat): Nat := x"
  IO.println "PSCV0_CORE_ENGINE: paired source, retained context, canonical kernel admission, runtime selector and no-fallback controls passed"
