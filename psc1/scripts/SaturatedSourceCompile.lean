import Ps.BackendTs.Saturate
import Ps.Host.CompilerDriver

/- Native IO adapter for an explicit experiment. Both outputs come from the
   same source-admitted, erased IR object; the default CLI/emitter is unchanged.
   Compiler input may be the real complete .lean or canonical .ps entry. -/

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_SATURATION_BUILD: " ++ label))

private def failCheck {α : Type} (error : PsTsCheckedEmitError) : IO α := do
  match error with
  | .check report =>
      for finding in report.findings do
        IO.eprintln (finding.code ++ ": " ++ finding.detail)
      throw (IO.userError "PSC1_SATURATION_BUILD: exact original IR check failed")
  | .emit _ => throw (IO.userError "PSC1_SATURATION_BUILD: original emitter failed")

def main (arguments : List String) : IO Unit := do
  let (input,baselinePath,candidatePath,requiredStems) ←
    match arguments with
    | input :: baselinePath :: candidatePath :: requiredStems =>
        pure (input,baselinePath,candidatePath,requiredStems)
    | _ => throw (IO.userError
        "usage: psc1_ts_saturate_build input.lean|input.ps original.ts optimized.ts [required-worker-stem ...]")
  require "both explicit .ts paths required"
    (baselinePath.endsWith ".ts" && candidatePath.endsWith ".ts" &&
      baselinePath != candidatePath)
  let elaborated ← psHostCompilerElaborateProject input
  let ir ←
    match psCompilerVerifiedIrFromElaborated elaborated with
    | .ok ir => pure ir
    | .error _ => throw (IO.userError "PSC1_SATURATION_BUILD: actual source admission/erasure failed")
  let original ←
    match psTsEmitCheckedModule psIrCheckDefaultOptions ir with
    | .ok text => pure text
    | .error error => failCheck error
  let candidate ←
    match psTsEmitSaturatedCheckedModule psIrCheckDefaultOptions ir with
    | .ok value => pure value
    | .error error => failCheck error
  IO.println ("PSC1_SATURATION_PLAN: reason=" ++ candidate.reason ++
    " helpers=" ++ toString candidate.helperCount ++ " calls=" ++ toString candidate.rewrittenCalls)
  require "actual eligible plan required for experimental artifact"
    (candidate.optimized && candidate.helperCount > 0 && candidate.rewrittenCalls > 0)
  require "candidate IR completely checked"
    (match candidate.candidateReport with
     | some report => report.accepted && report.traversalComplete | none => false)
  require "candidate target completely checked"
    (match candidate.candidateTarget with
     | some report => report.accepted && report.traversalComplete | none => false)
  let collected := psTsSatCollect ir.declarations (psTsModuleTopLevelNames ir)
    (PsTsSatCollection.mk PsErasureNameIndex.empty [] 0)
  let mut selected : List (String × Nat × Nat) := []
  for declaration in ir.declarations do
    match psTsSatFindCandidate collected.candidates declaration.name with
    | none => pure ()
    | some item =>
        let rewritten ←
          match psTsSatRewriteDeclaration collected.candidates item.helper with
          | some result => pure result
          | none => throw (IO.userError "PSC1_SATURATION_BUILD: selected helper rewrite declined")
        require "selected helper has saturated rewritten calls" (rewritten.snd > 0)
        require "selected helper has no original recursive reference"
          (!(psTsExprUsesNameWithFuel 4096 rewritten.fst.body declaration.name))
        selected := selected ++ [(declaration.name,item.stages,rewritten.snd)]
        IO.println ("PSC1_SATURATION_WORKER: " ++ declaration.name ++
          " -> " ++ item.helper.name ++ " stages=" ++ toString item.stages ++
          " rewrittenCalls=" ++ toString rewritten.snd)
  require "all selected helper identities recorded" (selected.length == candidate.helperCount)
  for stem in requiredStems do
    require ("required real worker was not specialized: " ++ stem)
      (selected.any (fun (name,_,_) => name.startsWith stem))
  let workers := String.intercalate "," (selected.map (fun (name,stages,calls) =>
    "{\"name\":" ++ psJsonQuote name ++ ",\"stages\":" ++ toString stages ++
      ",\"rewrittenCalls\":" ++ toString calls ++ "}"))
  let baseline ← psWriteAndCompileTypeScript original baselinePath
  let optimized ← psWriteAndCompileTypeScript candidate.typeScript candidatePath
  require "public .d.ts identical"
    ((← IO.FS.readFile baseline.declarationPath) == (← IO.FS.readFile optimized.declarationPath))
  let sourceKind := if input.endsWith ".ps" then "canonical-ps" else "lean"
  let report := "{\"schema\":\"psc1-saturated-checked-backend-v1\",\"input\":" ++
    psJsonQuote input ++ ",\"sourceKind\":" ++ psJsonQuote sourceKind ++
    ",\"declarations\":" ++ toString ir.declarations.length ++
    ",\"helpers\":" ++ toString candidate.helperCount ++
    ",\"rewrittenCalls\":" ++ toString candidate.rewrittenCalls ++
    ",\"workers\":[" ++ workers ++ "]" ++
    ",\"originalChecked\":true,\"candidateChecked\":true,\"candidateTargetChecked\":true" ++
    ",\"declarationsIdentical\":true,\"typescriptVersion\":" ++
    psJsonQuote optimized.typescriptVersion ++ "}\n"
  IO.FS.writeFile (candidatePath ++ ".receipt.json") report
  IO.println ("PSC1_SATURATION_BUILD: PASS source=" ++ sourceKind ++
    " helpers=" ++ toString candidate.helperCount ++
    " calls=" ++ toString candidate.rewrittenCalls ++ " TypeScript=" ++ optimized.typescriptVersion)
