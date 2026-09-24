import Ps.Foundation.Name
import Ps.Foundation.Diagnostic
import Ps.Syntax.Token
import Ps.Syntax.Translate
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
import Ps.Meta.LevelContext
import Ps.Meta.Context
import Ps.Meta.Reduce
import Ps.Meta.Unify
import Ps.Meta.SynthInstance
import Ps.Meta.Infer
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

def psCliUsage : String :=
  "ProofScript PSC1 Lean bootstrap\n" ++
  "usage:\n" ++
  "  psc1 translate <input.lean|input.ps> --to <lean|ps>"

def main : IO Unit := do
  let args ← IO.getArgs
  match args with
  | [] =>
      IO.println "ProofScript PSC1 Lean bootstrap"
  | ["translate", inputPath, "--to", target] =>
      psCliTranslate inputPath target
  | _ =>
      throw (IO.userError psCliUsage)
