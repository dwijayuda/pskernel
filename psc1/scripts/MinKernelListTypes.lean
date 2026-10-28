import Ps.MinKernel.Profile.RankOneTypes
import Ps.BackendTs.Sh1
import Ps.Host.ProjectCompiler
import Lean

def sourceModuleCompilerFailure (error : PsCompilerError) : String :=
  match error with
  | .elaboration failure => psHostElabErrorText failure
  | .leanFrontend failure =>
    match failure with
    | .lex error => psHostLexErrorText error
    | .parse error => psHostParseErrorText error
  | .proofScriptFrontend failure =>
    match failure with
    | .lex error => psHostLexErrorText error
    | .parse error => psHostParseErrorText error
  | .translation _ => "translation refused"
  | .admission _ => "canonical admission encoding refused"
  | .erasure _ => "erasure refused"

-- Linux CI transport only. The source-owned compiler performs all frontend,
-- canonical preparation and strict original/transformed IR checks.
def sourceModuleFailure (error : PsSh1EmitError) : String :=
  match error with
  | .source sourceError =>
    match sourceError with
    | .policy finding => finding.code ++ ": " ++ finding.detail
    | .origin moduleName failure =>
      moduleName ++ ": " ++ psHostElabErrorText failure.error
    | .compiler moduleName failure => moduleName ++ ": " ++ sourceModuleCompilerFailure failure
  | .compiler failure => sourceModuleCompilerFailure failure
  | .checkedEmit _ => "strict IR or emitter refused"
  | .target finding => finding.code ++ ": " ++ finding.detail




def rankLevel (fuel : Nat) (value : Lean.Json) : Except String Nat := do
  match fuel with
  | 0 => throw "level depth"
  | Nat.succ rest =>
    match ← value.getObjValAs? String "k" with
    | "z" => pure 0
    | "s" => return Nat.succ (← rankLevel rest (← value.getObjVal? "o"))
    | _ => throw "unsupported level"

def rankName (fuel : Nat) (value : Lean.Json) : Except String PsMinCoreName := do
  match fuel with
  | 0 => throw "name depth"
  | Nat.succ rest =>
    match ← value.getObjValAs? String "k" with
    | "a" => pure .anonymous
    | "s" =>
      let parent ← rankName rest (← value.getObjVal? "p")
      let text ← value.getObjValAs? String "v"
      pure (.str parent (text.toUTF8.toList.map UInt8.toNat))
    | "n" => pure (.num (← rankName rest (← value.getObjVal? "p"))
        (← value.getObjValAs? Nat "v"))
    | _ => throw "unsupported name"

def rankBinder (value : String) : Except String Nat :=
  match value with
  | "default" => .ok 0
  | "implicit" => .ok 1
  | "strictImplicit" => .ok 2
  | "instImplicit" => .ok 3
  | _ => .error "unsupported binder"

-- Untrusted CI adapter, not an admission rule or part of the model proof.
def rankExpr (fuel : Nat) (value : Lean.Json) : Except String PsMinCoreExpr := do
  match fuel with
  | 0 => throw "expression depth"
  | Nat.succ rest =>
    match ← value.getObjValAs? String "k" with
    | "b" => pure (.bvar (← value.getObjValAs? Nat "i"))
    | "sort" => pure (.sort (← rankLevel rest (← value.getObjVal? "l")))
    | "const" =>
      let name ← rankName rest (← value.getObjVal? "n")
      let levels ← value.getObjValAs? (Array Lean.Json) "ls"
      pure (.constant name (← levels.toList.mapM (rankLevel rest)))
    | "app" => pure (.app (← rankExpr rest (← value.getObjVal? "f"))
        (← rankExpr rest (← value.getObjVal? "a")))
    | "forall" => pure (.forallE (← rankName rest (← value.getObjVal? "n"))
        (← rankBinder (← value.getObjValAs? String "bi"))
        (← rankExpr rest (← value.getObjVal? "t"))
        (← rankExpr rest (← value.getObjVal? "b")))
    | _ => throw "unsupported signature expression"

def rankTypeJson : PsMinRankTy → Lean.Json
  | .tvar index => Lean.Json.mkObj [("kind",Lean.toJson "var"),("index",Lean.toJson (toString index))]
  | .natural => Lean.Json.mkObj [("kind",Lean.toJson "nat")]
  | .boolean => Lean.Json.mkObj [("kind",Lean.toJson "bool")]
  | .unit => Lean.Json.mkObj [("kind",Lean.toJson "unit")]
  | .arr domain result => Lean.Json.mkObj [("kind",Lean.toJson "arr"),("domain",rankTypeJson domain),("result",rankTypeJson result)]
  | .list element => Lean.Json.mkObj [("kind",Lean.toJson "list"),("element",rankTypeJson element)]
  | .option element => Lean.Json.mkObj [("kind",Lean.toJson "option"),("element",rankTypeJson element)]
  | .except error result => Lean.Json.mkObj [("kind",Lean.toJson "except"),("error",rankTypeJson error),("result",rankTypeJson result)]
  | .prod left right => Lean.Json.mkObj [("kind",Lean.toJson "prod"),("left",rankTypeJson left),("right",rankTypeJson right)]

def rankSchemeJson : Option PsMinRankScheme → Lean.Json
  | .none => Lean.Json.null
  | .some scheme => Lean.Json.mkObj [("arity",Lean.toJson (toString scheme.arity)),("body",rankTypeJson scheme.body)]

def main : IO Unit := do
  let dir := "dist/pskernel-min/list-types"
  let casesText ← IO.FS.readFile (dir ++ "/cases.json")
  let json ← match Lean.Json.parse casesText with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  let cases ← match json.getArr? with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  let rows ← cases.toList.mapM fun row => do
    let decoded := do
      let source ← rankExpr 512 (← row.getObjVal? "source")
      let fuel ← row.getObjValAs? Nat "fuel"
      let label ← row.getObjValAs? String "id"
      pure (Lean.Json.mkObj [("id",Lean.toJson label),("scheme",rankSchemeJson (psMinRankSignature fuel source))])
    match decoded with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  IO.FS.writeFile (dir ++ "/native.json") (Lean.toJson rows).compress
  let inputsText ← IO.FS.readFile (dir ++ "/inputs.json")
  let inputJson ← match Lean.Json.parse inputsText with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  let array ← match inputJson.getArr? with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  let inputs ← array.toList.mapM fun row => do
    let decoded := do
      let names ← row.getObjValAs? (Array String) "moduleName"
      let text ← row.getObjValAs? String "source"
      pure (psSh1SourceInput names.toList text)
    match decoded with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  match psCompilerSh1TypeScriptSources psSh1DefaultSourceOptions psIrCheckDefaultOptions PsCompilerSourceKind.lean inputs with
  | .error error => throw (IO.userError (sourceModuleFailure error))
  | .ok result =>
    unless result.sourcePolicy.accepted && result.targetPolicy.accepted &&
        result.checkReport.accepted && result.checkReport.traversalComplete do
      throw (IO.userError "RANK_TYPE_SOURCE_IR_GUARD")
    IO.FS.writeFile (dir ++ "/runtime.ts") result.typeScript
    IO.FS.writeFile (dir ++ "/runtime.admissions.json") result.admissions
    IO.FS.writeFile (dir ++ "/source-policy.json") (Lean.Json.mkObj [
      ("sourceAccepted",Lean.toJson result.sourcePolicy.accepted),
      ("targetAccepted",Lean.toJson result.targetPolicy.accepted),
      ("originalIrAccepted",Lean.toJson result.checkReport.accepted),
      ("moduleCount",Lean.toJson result.sourcePolicy.moduleCount),
      ("providerChecked",Lean.toJson result.providerChecked),
      ("semanticContractQualified",Lean.toJson result.semanticContractQualified),
      ("strictSh1Qualified",Lean.toJson result.strictSh1Qualified)]).compress
  IO.println "PSC1_ACTUAL_LIST_SIGNATURE_NATIVE_SOURCE_PASS"
