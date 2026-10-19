import Ps.Compiler.Pscv0ModuleEngine
import Ps.Environment.Bootstrap
import Ps.Environment.CompilerSourceCandidate
import Ps.Environment.Fingerprint
import PsKernelLean.Replay
import PsKernelLean.Protocol

private def sourceRequire (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError ("CORE-COMPILER-SOURCE: " ++ message))

private def sourceEntry (kind : PsCompilerSourceKind) : String :=
  "import Ps.Foundation.Source\nimport Ps.Foundation.List\n" ++
    (match kind with
    | .lean =>
        "def psCompilerSourceMeasure (span : PsSourceSpan) (values : List Nat) : Nat := psListLength values\n"
    | .proofScript =>
        "function psCompilerSourceMeasure(span: PsSourceSpan, values: List(Nat)): Nat := psListLength(values)\n")

private def compilerSourceInputs (kind : PsCompilerSourceKind)
    (position list : String) : List PsPscv0ModuleSource :=
  let extension := psCompilerSourceKindExtension kind
  let sourcePrefix := match kind with
    | .lean => "packages/foundation/src/"
    | .proofScript => "selfhost/core-v7/"
  [{ name := "CompilerWorkload", sourceKind := kind
     sourceName := "selected/CompilerWorkload" ++ extension, source := sourceEntry kind },
   { name := "Ps.Foundation.Source", sourceKind := kind
     sourceName := sourcePrefix ++ "Ps/Foundation/Source" ++ extension, source := position },
   { name := "Ps.Foundation.List", sourceKind := kind
     sourceName := sourcePrefix ++ "Ps/Foundation/List" ++ extension, source := list }]

private def sourceReplay (declarations : List PsDeclaration) :
    IO Lean.Kernel.Environment := do
  let mut checked := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  sourceRequire checked.constants.toList.isEmpty "initial kernel is not empty"
  let mut pending := declarations.reverse
  while !pending.isEmpty do
    let before := pending.length
    let mut deferred : List PsDeclaration := []
    for declaration in pending do
      let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
        PsKernelLean.tryPreludeDeclaration declarations checked declaration 2000000 20000
      match attempt with
      | .ok (.admitted next) => checked := next
      | .ok .deferred => deferred := declaration :: deferred
      | .error error => throw (IO.userError error.message)
    pending := deferred.reverse
    sourceRequire (decide (pending.length < before))
      ("unresolved base dependencies: " ++ String.intercalate ", "
        (pending.map (psNameToString ∘ psDeclarationName)))
  let names := declarations.map (PsKernelLean.toLeanName ∘ psDeclarationName)
  let actual := checked.constants.toList.map Prod.fst
  sourceRequire (names.length == names.eraseDups.length &&
      actual.length == names.length && actual.all names.contains)
    "independent base replay has a missing or extra declaration"
  return checked

private def sourceAdmit (base : Lean.Kernel.Environment) (admissions : String) :
    IO Lean.Kernel.Environment := do
  let declarations ← match PsKernelLean.decodeCanonicalAdmissions admissions with
    | .ok value => pure value
    | .error error => throw (IO.userError error.message)
  let mut checked := base
  for declaration in declarations.toList do
    let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
      checked.addDeclCore 2000000 20000
        (PsKernelLean.psKernelWithDefinitionHeight checked declaration) none
    match attempt with
    | .ok next => checked := next
    | .error error =>
        throw (IO.userError ("CORE-COMPILER-SOURCE: kernel rejection: " ++
          PsKernelLean.kernelExceptionSummary error))
  return checked

private def compilerSourceNames : List String :=
  ["PsSourcePos", "PsSourceSpan",
   "psListLength", "psListIsEmpty", "psListAny", "psListReverseAcc",
   "psListReverse", "psListAppend", "psListMap", "psListMapExcept",
   "psListTake", "psListZip"]

private def sourceInputReceipt (input : PsPscv0ModuleSource) : Lean.Json :=
  Lean.Json.mkObj [
    ("module", Lean.toJson input.name),
    ("sourceKind", Lean.toJson (match input.sourceKind with
      | .lean => ("lean" : String) | .proofScript => "proofScript")),
    ("path", Lean.toJson input.sourceName),
    ("bytes", Lean.toJson input.source.utf8ByteSize),
    ("sha256", Lean.toJson (psStandardSnapshotSHA256 input.source))]

private def sourceCheckOutput (base : PsEnvironment)
    (inputs : List PsPscv0ModuleSource) (output : PsCompilerEngineProjectOutput) :
    IO Unit := do
  let actualBase := output.prepared.profile.baseEnvironment
  sourceRequire
    (psStandardSnapshotPayload actualBase == psStandardSnapshotPayload base)
    "project did not retain the exact source base"
  for declaration in base.declarations do
    let name := psDeclarationName declaration
    sourceRequire
      (psEnvironmentIsNoncomputable actualBase name == psEnvironmentIsNoncomputable base name)
      ("retained base lost noncomputability metadata: " ++ psNameToString name)
  sourceRequire
    ((output.moduleProfiles.map (·.name)) ==
      ["Ps.Foundation.Source", "Ps.Foundation.List", "CompilerWorkload"])
    "complete reachable source ownership changed"
  for input in inputs do
    let some profile := output.moduleProfiles.find? (fun item => item.name == input.name)
      | throw (IO.userError ("CORE-COMPILER-SOURCE: missing module " ++ input.name))
    sourceRequire (profile.sourceName == input.sourceName && profile.source == input.source)
      "source receipt was substituted or shortened"
  for spelling in compilerSourceNames do
    let name := psRootName spelling
    sourceRequire (output.prepared.declarations.any fun declaration =>
      psNameEq (psDeclarationName declaration) name)
      ("complete compiler file lost " ++ spelling)
  sourceRequire
    (output.mainNames.length == 1 &&
      output.mainNames.any (psNameEq (psRootName "psCompilerSourceMeasure")))
    "entry ownership changed"
  sourceRequire
    (!(output.prepared.declarations.any fun declaration =>
      match declaration with | .axiomDecl .. | .partialDecl .. => true | _ => false))
    "compiler source introduced an assumption or partial implementation"
  let canonical ← match psCompilerEngineAdmissionsFromPrepared output.prepared with
    | .ok value => pure value
    | .error error => throw (IO.userError (psCompilerPscv0Error error))
  sourceRequire (canonical == output.admissions) "retained project admissions changed"

private def sourcePrepare (profile : PsCompilerProfileContext)
    (inputs : List PsPscv0ModuleSource) : IO PsCompilerEngineProjectOutput := do
  for input in inputs do
    match psCompilerParsePscv0Program input.sourceKind input.source with
    | .ok _ => pure ()
    | .error reason =>
        throw (IO.userError ("CORE-COMPILER-SOURCE: parse " ++ input.sourceName ++ ": " ++ reason))
  match psCompilerEnginePreparePscv0Project profile "CompilerWorkload" inputs with
  | .ok output => pure output
  | .error reason =>
      IO.println (Lean.Json.mkObj [
        ("schema", Lean.toJson ("pscv0-core-compiler-source-refusal/1" : String)),
        ("sources", .arr (inputs.map sourceInputReceipt).toArray),
        ("failure", Lean.toJson reason),
        ("completeSourceAccepted", Lean.toJson false),
        ("compilerSelfhostQualified", Lean.toJson false)]).compress
      throw (IO.userError ("CORE-COMPILER-SOURCE: " ++ reason))

def main (args : List String) : IO Unit := do
  let [leanPositionPath, leanListPath, psPositionPath, psListPath, candidatePath, reportPath] := args
    | throw (IO.userError "usage: pscv0_core_compiler_source Source.lean List.lean Source.ps List.ps CANDIDATE.lean REPORT.json")
  let leanPosition ← IO.FS.readFile (System.FilePath.mk leanPositionPath)
  let leanList ← IO.FS.readFile (System.FilePath.mk leanListPath)
  let psPosition ← IO.FS.readFile (System.FilePath.mk psPositionPath)
  let psList ← IO.FS.readFile (System.FilePath.mk psListPath)
  let candidateSource ← IO.FS.readFile (System.FilePath.mk candidatePath)
  sourceRequire (leanPosition.utf8ByteSize == 148 &&
      psStandardSnapshotSHA256 leanPosition ==
        "33d898574406817537cc0c1a728e50eae2838a47178ad1fe4adba53d54d6c736")
    "the complete original Source.lean changed"
  sourceRequire (leanList.utf8ByteSize == 2386 &&
      psStandardSnapshotSHA256 leanList ==
        "0a73eb4dded33cd9fecf000996653746800ea5fb05956e46670a7d3579426680")
    "the complete original List.lean changed"
  sourceRequire (psPosition.utf8ByteSize == 151 && psList.utf8ByteSize == 2538 &&
      psStandardSnapshotSHA256 psPosition ==
        "fc810c943a3ef9d32a1e045ac499c70dcba92359e7ce747ecf54b7086af6f059" &&
      psStandardSnapshotSHA256 psList ==
        "b7f4a010829295e169fe3803e50f4fe59d703465e51db75b1a3e72e0e475cec8")
    "complete ProofScript counterparts changed"
  sourceRequire (psStandardSnapshotSHA256 candidateSource == "911e636ed19468f30d7bbba5d23988fca5433d00f4dc9060b15232dedc275de9")
    "independently authored source candidate changed"
  let environment ← match psCompilerSourceCandidateEnvironment with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  let declarations := psCoreFoundationCandidateDeclarations
  sourceRequire (declarations.length == 92 &&
      environment.declarations.length == declarations.length)
    "candidate assembly changed the declaration roster"
  for original in psCoreBootstrapCandidateDeclarations do
    let some installed := psEnvironmentFind environment (psDeclarationName original)
      | throw (IO.userError "CORE-COMPILER-SOURCE: original seed declaration missing")
    sourceRequire
      (psStandardSnapshotDeclaration installed == psStandardSnapshotDeclaration original &&
        psReducibilityName (psEnvironmentReducibility environment (psDeclarationName original)) ==
          psReducibilityName (psEnvironmentReducibility psBootstrapEnvironment (psDeclarationName original)))
      ("original seed declaration or policy changed: " ++ psNameToString (psDeclarationName original))
  let checkedBase ← sourceReplay declarations
  let profile : PsCompilerProfileContext := {
    baseEnvironment := environment, runtimePrelude := fun _ _ => [] }
  let pairs := [
    compilerSourceInputs .lean leanPosition leanList,
    compilerSourceInputs .proofScript psPosition psList]
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-core-compiler-source-workload/1" : String)),
    ("sourceFileCountPerSyntax", Lean.toJson (2 : Nat)),
    ("sourceDeclarationsPerSyntax", Lean.toJson (12 : Nat)),
    ("completeOriginalSourceBytes", Lean.toJson (leanPosition.utf8ByteSize + leanList.utf8ByteSize)),
    ("sourcePairs", .arr (pairs.map fun inputs =>
      Lean.Json.arr (inputs.map sourceInputReceipt).toArray).toArray),
    ("candidateDeclarations", Lean.toJson declarations.length),
    ("candidateSourceSHA256", Lean.toJson (psStandardSnapshotSHA256 candidateSource))]).compress
  let mut outputs : List PsCompilerEngineProjectOutput := []
  for inputs in pairs do
    let output ← sourcePrepare profile inputs
    sourceCheckOutput environment inputs output
    let admitted ← sourceAdmit checkedBase output.admissions
    for spelling in compilerSourceNames ++ ["psCompilerSourceMeasure"] do
      sourceRequire
        (admitted.find? (PsKernelLean.toLeanName (psRootName spelling))).isSome
        ("independent admission lost " ++ spelling)
    outputs := outputs ++ [output]
  let [leanOutput, psOutput] := outputs
    | throw (IO.userError "CORE-COMPILER-SOURCE: paired result count changed")
  sourceRequire (leanOutput.admissions == psOutput.admissions)
    "complete Lean and ProofScript canonical admissions differ"
  let basePayload := psStandardSnapshotPayload environment
  let report := Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-core-compiler-source-qualification/1" : String)),
    ("nativeCommit", Lean.toJson Lean.githash),
    ("scope", Lean.toJson ("complete Ps.Foundation.Source and Ps.Foundation.List plus an importing entry" : String)),
    ("sourceFilesPerSyntax", Lean.toJson (2 : Nat)),
    ("sourceDeclarationsPerSyntax", Lean.toJson (12 : Nat)),
    ("sourcePairs", .arr (pairs.map fun inputs =>
      Lean.Json.arr (inputs.map sourceInputReceipt).toArray).toArray),
    ("candidateSourceSHA256", Lean.toJson (psStandardSnapshotSHA256 candidateSource)),
    ("candidateDeclarations", Lean.toJson declarations.length),
    ("candidateNoncomputableNames", Lean.toJson
      (psCompilerSourceCandidateNoncomputableNames.map psNameToString)),
    ("candidateClasses", Lean.toJson (environment.classes.map psNameToString)),
    ("candidatePayloadBytes", Lean.toJson basePayload.utf8ByteSize),
    ("candidatePayloadSHA256", Lean.toJson (psStandardSnapshotSHA256 basePayload)),
    ("candidatePayloadFNV64Decimal", Lean.toJson (toString (psStandardSnapshotFNV64 basePayload))),
    ("retainedBootstrapDeclarations", Lean.toJson psCoreBootstrapCandidateDeclarations.length),
    ("preparedDeclarations", Lean.toJson leanOutput.prepared.declarations.length),
    ("preparedNames", Lean.toJson (leanOutput.prepared.declarations.map (psNameToString ∘ psDeclarationName))),
    ("recursorWorkerGroups", Lean.toJson leanOutput.prepared.recursorWorkerGroups.length),
    ("sourceNoncomputableNames", Lean.toJson (leanOutput.prepared.noncomputableNames.map psNameToString)),
    ("canonicalAdmissionsBytes", Lean.toJson leanOutput.admissions.utf8ByteSize),
    ("canonicalAdmissionsSHA256", Lean.toJson (psStandardSnapshotSHA256 leanOutput.admissions)),
    ("kernelTrustLevel", Lean.toJson (0 : Nat)),
    ("maxHeartbeatsPerDeclaration", Lean.toJson (2000000 : Nat)),
    ("maxRecDepthPerDeclaration", Lean.toJson (20000 : Nat)),
    ("completePairedSourceAccepted", Lean.toJson true),
    ("canonicalPairEqual", Lean.toJson true),
    ("nativeElaborationParityQualified", Lean.toJson false),
    ("compilerSelfhostQualified", Lean.toJson false),
    ("backendExecutionQualified", Lean.toJson false)]
  IO.FS.writeFile (System.FilePath.mk reportPath) (report.compress ++ "\n")
  IO.println report.compress
  IO.println "PSCV0_CORE_COMPILER_SOURCE: PASS complete two-file Lean/ProofScript source, exact seed inclusion and independent canonical admission"
