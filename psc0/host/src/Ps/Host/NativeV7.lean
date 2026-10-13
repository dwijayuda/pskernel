import Ps.Compiler.Pscv0Modules
import Ps.BackendTs.Readable
import Ps.BackendRust.Module
import Ps.BackendWasm.Module
import Ps.CompilerIr.Checked
import Ps.Codegen.Api
import Ps.Codegen.Provenance
import PsKernelLean.Protocol
import PsKernelLean.Prelude

open Lean (toJson)

namespace PsV7Native

-- Shared by diagnostics and the executable version response.
def profile : String := "pscv0-v7-native-bounded/51"

def leanVersion : String := "4.35.0-rc4"
def leanCommit : String := "c29b6dda4f7c20e3eeaa717c4e565663c5cfa364"

structure Diagnostic where
  phase : String
  message : String
  deriving Repr

structure Request where
  source : String
  sourceName : String := "application.ps"
  outputStem : String := "module"
  targets : List PsEmissionTarget := []
  exports : PsApiExposure := .allRuntime
  -- Optional explicitly named source dependencies. Empty preserves the
  -- original isolated single-file entry point and its strict import refusal.
  moduleName : String := "Main"
  modules : List PsPscv0ModuleSource := []

structure Timings where
  parseMs : Nat := 0
  elaborateMs : Nat := 0
  prepareMs : Nat := 0
  kernelMs : Nat := 0
  eraseMs : Nat := 0
  emitMs : Nat := 0

structure Result where
  declarationCount : Nat
  artifacts : List PsEmissionArtifact
  timings : Timings

structure Batch where
  preludeMs : Nat
  results : Array (Except Diagnostic Result)

private def fromResult {α : Type} (phase : String)
    (result : Except String α) : ExceptT Diagnostic IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw { phase, message }

-- Use the established canonical bridge, including nested-recursion adaptation.
-- Kernel submission is synchronous and explicitly enables checking.
-- No elaborator recovery, unchecked admission, or alternate checker fallback.
private def check (prelude : Lean.Environment) (admissions : String) :
    Except String Unit := do
  let declarations ← (PsKernelLean.decodeCanonicalAdmissions admissions).mapError
    (fun error => error.kind.code ++ ": " ++ error.message)
  let mut environment := prelude
  for declaration in declarations do
    match environment.addDeclCore 2000000 20000 declaration none true with
    | .ok next => environment := next
    | .error error => throw (PsKernelLean.kernelExceptionSummary error)
  pure ()

private def compile (prelude : Lean.Environment) (request : Request) :
    ExceptT Diagnostic IO Result := do
  let t0 ← IO.monoMsNow
  let project ← if request.modules.isEmpty then
    pure none
  else
    (fromResult "module" (psCompilerPreparePscv0Project request.moduleName
      (request.modules ++ [{ name := request.moduleName, source := request.source }]))).map some
  let parsed ← match project with
    | some _ => pure none
    | none => (fromResult "parse" (psCompilerParsePscv0 request.source)).map some
  let t1 ← IO.monoMsNow
  let elaborated ← match parsed with
    | none => pure none
    | some parsed =>
      (fromResult "elaborate" ((psElabProgramWithOrigins
        psSelfHostProdPreludeEnvironment parsed).mapError psCompilerPscv0ElabError)).map some
  let t2 ← IO.monoMsNow
  let output ← match project with
    | some value =>
      pure ({ prepared := value.prepared
              environment := psSelfHostProdPreludeEnvironment
              admissions := value.admissions
              originParents := value.origins.flatMap (·.parents) :
        PsCompilerPreparationOutput })
    | none =>
      match elaborated with
      | some value =>
        fromResult "prepare" ((psCompilerPrepareElaboratedWithOutput value.result).mapError
          psCompilerPscv0Error)
      | none => throw { phase := "prepare", message := "missing prepared source" }
  let t3 ← IO.monoMsNow
  let _ ← fromResult "kernel" (check prelude output.admissions)
  let t4 ← IO.monoMsNow
  let timings : Timings := if project.isSome then {
    -- The graph planner owns parsing and each module's elaboration/preparation.
    parseMs := 0, elaborateMs := 0,
    prepareMs := t3 - t0, kernelMs := t4 - t3 }
  else {
    parseMs := t1 - t0, elaborateMs := t2 - t1,
    prepareMs := t3 - t2, kernelMs := t4 - t3 }
  if request.targets.isEmpty then
    return {
      declarationCount := output.prepared.declarations.length
      artifacts := []
      timings := timings }
  -- Keep the same immutable prepared graph alive through checking and emission.
  -- Existing erasure validation is retained until profiling justifies changing it.
  let ir ← fromResult "erase"
    ((psCompilerVerifiedIrFromPrepared output.prepared).mapError psCompilerPscv0Error)
  let ir := match project with
    | none => ir
    | some value =>
      let libraryNames := value.libraryNames.map psNameToString
      let names := libraryNames.filter fun name =>
        ir.declarations.any (fun d => d.name == name) ||
        ir.structures.any (fun s => s.name == name) ||
        ir.inductives.any (fun i => i.name == name)
      { ir with internalNames := ir.internalNames ++ names }
  let originBatches : List (String × PsElabBatchOrigin) :=
    match project with
    | some value =>
      value.origins.flatMap fun file =>
        let sourceName := if file.moduleName == request.moduleName then
          request.sourceName else file.sourceName
        file.batches.map (fun batch => (sourceName, batch))
    | none =>
      match elaborated with
      | some value => value.origins.map (fun batch => (request.sourceName, batch))
      | none => []
  let origins := originBatches.flatMap fun (fileName, batch) =>
    batch.members.map fun member =>
      (psNameToString member.name, {
        identity := { file := fileName, declaration := psNameToString member.name }
        span := batch.span
        generatedReason := match member.role with
          | .sourceDeclaration | .inductiveType | .structureType => none
          | _ => some "elaboration member of source declaration" : PsSourceOrigin })
  let origins := output.originParents.foldl (fun origins (helper, parent) =>
    match origins.find? (fun entry => entry.fst == psNameToString parent) with
    | none => origins
    | some (_, origin) => (psNameToString helper, { origin with
        identity := { origin.identity with declaration := psNameToString helper }
        generatedReason := some ("recursor worker of " ++ psNameToString parent) }) :: origins) origins
  let sourceFiles := match project with
    | none => []
    | some value => value.origins.map fun file =>
      (if file.moduleName == request.moduleName then request.sourceName
       else file.sourceName, file.source)
  let context : PsEmissionContext := {
    sourceName := request.sourceName
    sourceText := request.source
    outputStem := request.outputStem
    origins := origins
    sourceFiles }
  let t5 ← IO.monoMsNow
  let (_, artifacts) ← fromResult "ir/emit" (psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← if request.targets.any (fun t => t == .typescript || t == .javascript) then
      (PsEcma.plan checked).map some else pure none
    request.targets.mapM fun target =>
      match target with
      | .typescript | .javascript =>
        match ecma with
        | none => .error "PSCV0-ECMA: missing planned program"
        | some program => PsEcma.emitProgram program
            (if target == .typescript then .typescript else .javascript) context
      | .rust => psRustEmitReadable checked request.outputStem origins
      | .wasmCore | .wasmComponent =>
          PsWasm.emit checked context (target == .wasmComponent) request.exports)
  let t6 ← IO.monoMsNow
  return {
    declarationCount := output.prepared.declarations.length
    artifacts := artifacts
    timings := { timings with eraseMs := t5 - t4, emitMs := t6 - t5 } }

-- A batch shares only the immutable checked prelude. Inputs remain independent:
-- successful or failed requests cannot leak declarations into the next source.
-- Callers supply source, never an environment or a claimed checked token.
def runBatch (requests : Array Request) : IO (Except Diagnostic Batch) := do
  if Lean.versionString != leanVersion || Lean.githash != leanCommit then
    return .error {
      phase := "toolchain"
      message := "expected Lean " ++ leanVersion ++ " at " ++ leanCommit ++
        ", got " ++ Lean.versionString ++ " at " ++ Lean.githash }
  -- Audit once per batch before either isolated single-file elaboration or
  -- the dependency graph is allowed to prepare executable admissions.
  if let .error message := psCompilerValidatePscv0Standard then
    return .error { phase := "prelude", message }
  let t0 ← IO.monoMsNow
  let initial ← PsKernelLean.buildLeanPreludeEnvironment
  let t1 ← IO.monoMsNow
  match initial with
  | .error error =>
      -- Old provider diagnostics carry its old version label; do not reuse that
      -- identity in this RC4 host. The error kind still identifies the boundary.
      return .error { phase := "prelude", message := error.kind.code ++ ": " ++ error.message }
  | .ok prelude =>
      let results ← requests.mapM (fun request => (compile prelude request).run)
      return .ok { preludeMs := t1 - t0, results }

def timingsJson (t : Timings) : Lean.Json :=
  Lean.Json.mkObj [
    ("parseMs", toJson t.parseMs), ("elaborateMs", toJson t.elaborateMs),
    ("prepareMs", toJson t.prepareMs), ("kernelMs", toJson t.kernelMs),
    ("eraseMs", toJson t.eraseMs), ("emitMs", toJson t.emitMs)]

def resultJson (sourceName : String) (result : Except Diagnostic Result) : Lean.Json :=
  let identity := [
    ("source", toJson sourceName), ("leanVersion", toJson Lean.versionString),
    ("leanCommit", toJson Lean.githash), ("provider", toJson ("lean4-cpp" : String)),
    ("profile", toJson profile)]
  match result with
  | .error error => Lean.Json.mkObj (identity ++ [
      ("accepted", toJson false), ("phase", toJson error.phase),
      ("message", toJson error.message)])
  | .ok value => Lean.Json.mkObj (identity ++ [
      ("accepted", toJson true), ("declarations", toJson value.declarationCount),
      ("timings", timingsJson value.timings)])

end PsV7Native
