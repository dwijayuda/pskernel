import Ps.BackendTs.Sh1
import Ps.Host.ProjectCompiler

def minKernelCompilerFailure (error : PsCompilerError) : String :=
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
def minKernelSourceFailure (error : PsSh1EmitError) : String :=
  match error with
  | .source sourceError =>
    match sourceError with
    | .policy finding => finding.code ++ ": " ++ finding.detail
    | .origin moduleName failure =>
      moduleName ++ ": " ++ psHostElabErrorText failure.error
    | .compiler moduleName failure => moduleName ++ ": " ++ minKernelCompilerFailure failure
  | .compiler failure => minKernelCompilerFailure failure
  | .checkedEmit _ => "strict IR or emitter refused"
  | .target finding => finding.code ++ ": " ++ finding.detail


def minKernelOriginRole (role : PsElabOriginRole) : String :=
  match role with
  | .sourceDeclaration => "sourceDeclaration"
  | .inductiveType => "inductiveType"
  | .structureType => "structureType"
  | .constructor => "constructor"
  | .recursor => "recursor"
  | .normalizedWorker => "normalizedWorker"
  | .publicWrapper => "publicWrapper"

def minKernelOriginMember (member : PsElabMemberOrigin) : String :=
  psJsonObject [("index", toString member.index),
    ("nameWire", psEncodeCodecName member.name),
    ("role", psJsonQuote (minKernelOriginRole member.role))]

def minKernelOriginBatch (batch : PsElabBatchOrigin) : String :=
  psJsonObject [("sourceIndex", toString batch.sourceIndex),
    ("sourceName", psJsonArray (batch.sourceName.segments.map psJsonQuote)),
    ("members", psJsonArray (batch.members.map minKernelOriginMember))]

def minKernelOriginModule (origin : PsSh1ModuleOrigin) : String :=
  psJsonObject [("moduleName", psJsonArray (origin.moduleName.map psJsonQuote)),
    ("coreStart", toString origin.coreStart),
    ("batches", psJsonArray (origin.batches.map minKernelOriginBatch))]

def main (args : List String) : IO Unit := do
  let binderMode := args == ["binder"]
  let regularMode := args == ["regular"]
  let operationalMode := args == ["operational"]
  let ingressMode := args == ["ingress"]
  let regularIngressMode := args == ["regular-ingress"]
  if !args.isEmpty && !binderMode && !regularMode && !operationalMode && !ingressMode && !regularIngressMode then
    throw (IO.userError "expected no arguments, binder, regular, operational ingress or regular-ingress")
  let paths : List (List String × String) := if regularIngressMode then [
      (["Ps", "MinKernel", "Profile", "RegularProfile"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularProfile.lean"),
      (["Ps", "MinKernel", "Profile", "RegularCheck"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularCheck.lean"),
      (["Ps", "MinKernel", "Profile", "OperationalProfile"], "packages/pskernel-min/src/Ps/MinKernel/Profile/OperationalProfile.lean"),
      (["Ps", "MinKernel", "Profile", "OperationalCheck"], "packages/pskernel-min/src/Ps/MinKernel/Profile/OperationalCheck.lean"),
      (["Ps", "MinKernel", "Profile", "CoreBytes"], "packages/pskernel-min/src/Ps/MinKernel/Profile/CoreBytes.lean"),
      (["Ps", "MinKernel", "Profile", "CoreIngress"], "packages/pskernel-min/src/Ps/MinKernel/Profile/CoreIngress.lean"),
      (["Ps", "MinKernel", "Profile", "RegularIngressProfile"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularIngressProfile.lean"),
      (["Ps", "MinKernel", "Profile", "RegularIngressOperational"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularIngressOperational.lean"),
      (["Ps", "MinKernel", "Profile", "RegularIngressCheck"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularIngressCheck.lean"),
      (["Ps", "MinKernel", "Profile", "RegularIngressBytes"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularIngressBytes.lean"),
      (["Ps", "MinKernel", "Tests", "RegularIngressVectors"], "packages/pskernel-min/src/Ps/MinKernel/Tests/RegularIngressVectors.lean")]
    else if ingressMode then [
      (["Ps", "MinKernel", "Profile", "RegularProfile"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularProfile.lean"),
      (["Ps", "MinKernel", "Profile", "RegularCheck"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularCheck.lean"),
      (["Ps", "MinKernel", "Profile", "OperationalProfile"], "packages/pskernel-min/src/Ps/MinKernel/Profile/OperationalProfile.lean"),
      (["Ps", "MinKernel", "Profile", "OperationalCheck"], "packages/pskernel-min/src/Ps/MinKernel/Profile/OperationalCheck.lean"),
      (["Ps", "MinKernel", "Profile", "CoreBytes"], "packages/pskernel-min/src/Ps/MinKernel/Profile/CoreBytes.lean"),
      (["Ps", "MinKernel", "Profile", "CoreIngress"], "packages/pskernel-min/src/Ps/MinKernel/Profile/CoreIngress.lean"),
      (["Ps", "MinKernel", "Tests", "IngressVectors"], "packages/pskernel-min/src/Ps/MinKernel/Tests/IngressVectors.lean")]
    else if operationalMode then [
      (["Ps", "MinKernel", "Profile", "RegularProfile"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularProfile.lean"),
      (["Ps", "MinKernel", "Profile", "RegularCheck"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularCheck.lean"),
      (["Ps", "MinKernel", "Profile", "OperationalProfile"], "packages/pskernel-min/src/Ps/MinKernel/Profile/OperationalProfile.lean"),
      (["Ps", "MinKernel", "Profile", "OperationalCheck"], "packages/pskernel-min/src/Ps/MinKernel/Profile/OperationalCheck.lean"),
      (["Ps", "MinKernel", "Tests", "OperationalVectors"], "packages/pskernel-min/src/Ps/MinKernel/Tests/OperationalVectors.lean")]
    else if regularMode then [
      (["Ps", "Foundation", "Name"], "packages/foundation/src/Ps/Foundation/Name.lean"),
      (["Ps", "MinKernel", "Profile", "RegularProfile"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularProfile.lean"),
      (["Ps", "MinKernel", "Profile", "RegularCheck"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularCheck.lean"),
      (["Ps", "MinKernel", "Profile", "RegularNames"], "packages/pskernel-min/src/Ps/MinKernel/Profile/RegularNames.lean"),
      (["Ps", "MinKernel", "Tests", "RegularVectors"], "packages/pskernel-min/src/Ps/MinKernel/Tests/RegularVectors.lean")]
    else if binderMode then [
      (["Ps", "Foundation", "Name"], "packages/foundation/src/Ps/Foundation/Name.lean"),
      (["Ps", "Core", "Level"], "packages/core/src/Ps/Core/Level.lean"),
      (["Ps", "Core", "Expr"], "packages/core/src/Ps/Core/Expr.lean"),
      (["Ps", "Core", "Equality"], "packages/core/src/Ps/Core/Equality.lean"),
      (["Ps", "MinKernel", "Profile", "LowerUnusedBinder"], "packages/pskernel-min/src/Ps/MinKernel/Profile/LowerUnusedBinder.lean"),
      (["Ps", "MinKernel", "Tests", "BinderVectors"], "packages/pskernel-min/src/Ps/MinKernel/Tests/BinderVectors.lean")]
    else [
      (["Ps", "MinKernel", "Check"], "packages/pskernel-min/src/Ps/MinKernel/Check.lean"),
      (["Ps", "MinKernel", "Tests", "Vectors"], "packages/pskernel-min/src/Ps/MinKernel/Tests/Vectors.lean")]
  let inputs ← paths.mapM fun (moduleName, path) => do
    let source ← IO.FS.readFile path
    pure (psSh1SourceInput moduleName source)
  let stem := if regularIngressMode then "dist/pskernel-min/regular-ingress/vectors" else if ingressMode then "dist/pskernel-min/ingress/vectors" else if operationalMode then "dist/pskernel-min/operational/vectors" else if regularMode then "dist/pskernel-min/regular/vectors" else if binderMode then "dist/pskernel-min/binder/vectors" else "dist/pskernel-min/portable/vectors"
  match psCompilerSh1TypeScriptSources psSh1DefaultSourceOptions
      psIrCheckDefaultOptions PsCompilerSourceKind.lean inputs with
  | .error error => throw (IO.userError (minKernelSourceFailure error))
  | .ok result =>
    if !result.sourcePolicy.accepted || !result.targetPolicy.accepted ||
        !result.checkReport.accepted then
      throw (IO.userError "PSC1_MIN_SOURCE_OR_IR_REFUSED")
    IO.FS.writeFile (stem ++ ".ts") result.typeScript
    IO.FS.writeFile (stem ++ ".admissions.json") result.admissions
    IO.FS.writeFile (stem ++ ".source.json")
      (psJsonObject [("schema", psJsonQuote "psc1-min-source-compile/2"),
        ("sourceAccepted", "true"), ("targetAccepted", "true"),
        ("originalIrAccepted", "true"), ("providerChecked", "false"),
        ("moduleCount", toString result.sourcePolicy.moduleCount),
        ("origins", psJsonArray (result.origins.map minKernelOriginModule))] ++ "\n")
    IO.println "PSC1_MIN_SOURCE_COMPILE_PASS: candidate only; independent admission still required"
