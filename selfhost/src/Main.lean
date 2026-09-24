import Ps.Foundation.Name
import Ps.Foundation.Diagnostic
import Ps.Syntax.Token
import Ps.Syntax.Translate
import Ps.Bridge.CheckedAdmissions
import Ps.Core.Declaration
import Ps.Core.Subst
import Ps.Core.Equality
import Ps.Core.LevelSubst
import Ps.Core.Builtin
import Ps.Core.Abstract
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Environment.Instances
import Ps.Environment.Resolve
import Ps.Environment.Prelude
import Ps.Meta.LevelContext
import Ps.Meta.Context
import Ps.Meta.Reduce
import Ps.Meta.Unify
import Ps.Meta.SynthInstance
import Ps.Meta.Infer
import Ps.Elab.Declaration
import Ps.Erasure.Definition
import Ps.BackendTs.Module
import Ps.BackendTs.Compiler
import Ps.Project.ModuleGraph

inductive PsCliSourceKind where
  | lean
  | proofScript

def psCliSourceKindFromPath
    (path : String) : Option PsCliSourceKind :=
  if path.endsWith ".lean" then
    some PsCliSourceKind.lean
  else if path.endsWith ".ps" then
    some PsCliSourceKind.proofScript
  else
    none

def psCliTranslationTarget
    (target : String) : Option PsCliSourceKind :=
  if target == "lean" || target == ".lean" then
    some PsCliSourceKind.lean
  else if target == "ps" || target == ".ps" then
    some PsCliSourceKind.proofScript
  else
    none

def psCliTranslate
    (inputPath : String)
    (targetText : String) : IO Unit := do
  let sourceKind ←
    match psCliSourceKindFromPath inputPath with
    | none =>
        throw
          (IO.userError
            ("PSC1_CLI_SOURCE_KIND: expected .lean or .ps input, got " ++
              inputPath))
    | some kind => pure kind
  let target ←
    match psCliTranslationTarget targetText with
    | none =>
        throw
          (IO.userError
            ("PSC1_CLI_TRANSLATION_TARGET: expected ps or lean, got " ++
              targetText))
    | some kind => pure kind
  let source ← IO.FS.readFile inputPath
  let translated :=
    match sourceKind, target with
    | .lean, .lean =>
        psCanonicalizeLeanSource source
    | .lean, .proofScript =>
        psTranslateLeanToProofScript source
    | .proofScript, .lean =>
        psTranslateProofScriptToLean source
    | .proofScript, .proofScript =>
        psCanonicalizeProofScriptSource source
  match translated with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_CLI_TRANSLATION_FAILED: source is outside the supported bootstrap subset")
  | Except.ok output =>
      IO.print output

def psCliElaborateSource
    (inputPath : String) : IO PsElabModuleResult := do
  let sourceKind ←
    match psCliSourceKindFromPath inputPath with
    | none =>
        throw
          (IO.userError
            ("PSC1_CLI_SOURCE_KIND: expected .lean or .ps input, got " ++
              inputPath))
    | some kind => pure kind
  let source ← IO.FS.readFile inputPath
  let parsed :=
    match sourceKind with
    | .lean =>
        match psParseLeanSource source with
        | Except.error _ =>
            Except.error "Lean parse failed"
        | Except.ok sourceModule =>
            Except.ok sourceModule
    | .proofScript =>
        match psParseProofScriptSource source with
        | Except.error _ =>
            Except.error "ProofScript parse failed"
        | Except.ok sourceModule =>
            Except.ok sourceModule
  let sourceModule ←
    match parsed with
    | Except.error message =>
        throw
          (IO.userError
            ("PSC1_CLI_PARSE_FAILED: " ++ message))
    | Except.ok sourceModule =>
        pure sourceModule
  if !sourceModule.imports.isEmpty then
    throw
      (IO.userError
        "PSC1_CLI_IMPORT_CONTEXT_REQUIRED: imports require the project pipeline")
  match
      psElabModule
        psBootstrapPreludeEnvironment
        sourceModule with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_CLI_ELAB_FAILED: source is outside the supported bootstrap subset")
  | Except.ok result =>
      pure result

def psCliAdmissions
    (inputPath : String) : IO Unit := do
  let elaborated ← psCliElaborateSource inputPath
  match psEncodeCheckedAdmissionsText elaborated.declarations with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_CLI_ADMISSION_CODEC_FAILED: elaborated source is not persistable")
  | Except.ok encoded =>
      IO.print encoded

def psCliCompileTypeScriptSource
    (inputPath : String) : IO String := do
  let elaborated ← psCliElaborateSource inputPath
  let ir ←
    match
        psEraseCoreModule
          elaborated.environment
          elaborated.declarations with
    | Except.error _ =>
        throw
          (IO.userError
            "PSC1_CLI_ERASURE_FAILED: executable source is outside the Lean-native backend subset")
    | Except.ok ir =>
        pure ir
  match psTsEmitModule ir with
  | Except.error _ =>
      throw
        (IO.userError
          "PSC1_CLI_TS_EMIT_FAILED: verified IR is outside the Lean-native TypeScript backend subset")
  | Except.ok output =>
      pure output

def psCliTypeScript
    (inputPath : String) : IO Unit := do
  IO.print (← psCliCompileTypeScriptSource inputPath)

def psCliCompile
    (inputPath outputPath : String) : IO Unit := do
  if !outputPath.endsWith ".ts" then
    throw
      (IO.userError
        "PSC1_CLI_OUTPUT_KIND: compile output must end in .ts")
  let source ← psCliCompileTypeScriptSource inputPath
  let result ← psWriteAndCompileTypeScript source outputPath
  IO.println
    ("PSC1_COMPILE: " ++ result.typeScriptPath ++
      " -> " ++ result.javascriptPath)
  IO.println
    ("PSC1_DECLARATION: " ++ result.declarationPath)
  IO.println
    ("PSC1_SOURCE_MAP: " ++ result.sourceMapPath)
  IO.println
    ("PSC1_TYPESCRIPT: " ++ result.typescriptVersion)

def psCliUsage : String :=
  "ProofScript PSC1 Lean bootstrap\n" ++
  "usage:\n" ++
  "  psc1 translate <input.lean|input.ps> --to <lean|ps>\n" ++
  "  psc1 admissions <input.lean|input.ps>\n" ++
  "  psc1 typescript <input.lean|input.ps>\n" ++
  "  psc1 compile <input.lean|input.ps> --out <output.ts>"

def main (args : List String) : IO Unit := do
  match args with
  | [] =>
      IO.println "ProofScript PSC1 Lean bootstrap"
  | ["translate", inputPath, "--to", target] =>
      psCliTranslate inputPath target
  | ["admissions", inputPath] =>
      psCliAdmissions inputPath
  | ["typescript", inputPath] =>
      psCliTypeScript inputPath
  | ["compile", inputPath, "--out", outputPath] =>
      psCliCompile inputPath outputPath
  | _ =>
      throw (IO.userError psCliUsage)
