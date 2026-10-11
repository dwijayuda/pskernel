import Ps.Compiler.Pscv0
import Ps.BackendTs.Readable
import Ps.BackendRust.Module
import Ps.CompilerIr.Checked
import PsKernelLean.Protocol
import PsKernelLean.Prelude

open Lean (toJson)

namespace PsV7Native

-- Shared by diagnostics and the executable version response.
def profile : String := "pscv0-v7-native-bounded/23"

def leanVersion : String := "4.35.0-rc4"
def leanCommit : String := "c29b6dda4f7c20e3eeaa717c4e565663c5cfa364"

structure Diagnostic where
  phase : String
  message : String
  deriving Repr

structure Request where
  source : String
  targets : List PsEmissionTarget := []

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
  let parsed ← fromResult "parse" (psCompilerParsePscv0 request.source)
  let t1 ← IO.monoMsNow
  let elaborated ← fromResult "elaborate"
    ((psCompilerElaboratePscv0 parsed).mapError psCompilerPscv0Error)
  let t2 ← IO.monoMsNow
  let output ← fromResult "prepare"
    ((psCompilerPrepareElaboratedWithOutput elaborated).mapError psCompilerPscv0Error)
  let t3 ← IO.monoMsNow
  let _ ← fromResult "kernel" (check prelude output.admissions)
  let t4 ← IO.monoMsNow
  let timings : Timings := {
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
  let t5 ← IO.monoMsNow
  let (_, artifacts) ← fromResult "ir/emit" (psWithCheckedIr psIrCheckDefaultOptions ir fun checked =>
    request.targets.mapM fun target =>
      match target with
      | .typescript => psTsEmitReadable checked
      | .rust => psRustEmitReadable checked)
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
  let t0 ← IO.monoMsNow
  let initial ← PsKernelLean.buildLeanPreludeEnvironment
  let t1 ← IO.monoMsNow
  match initial with
  | .error error =>
      -- Old provider diagnostics carry its old version label; do not reuse that
      -- identity in this RC4 host. The error kind still identifies the boundary.
      return .error { phase := "prelude", message := error.kind.code }
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
