import Ps.BackendJs.CompilerService

open Ps.Internal.JsCompilerService

def profileMap {α ε : Type} (render : ε -> String) (value : Except ε α) : Except String α :=
  match value with
  | .error error => .error (render error)
  | .ok result => .ok result

def profileMark (file : System.FilePath) (rows : IO.Ref (List String))
    (phase status : String) (detail : String := "") : IO Unit := do
  let now <- IO.monoMsNow
  let row := psJsonObject [("phase", psJsonQuote phase), ("status", psJsonQuote status),
    ("elapsedClockMs", toString now), ("detail", psJsonQuote detail)]
  rows.modify (fun values => values ++ [row])
  IO.FS.writeFile file (psJsonArray (<- rows.get))
  IO.FS.writeFile (file.toString ++ ".proc-status") (<- IO.FS.readFile "/proc/self/status")
  IO.println ("PSC1_COMPILER_PROFILE: " ++ row)
  (<- IO.getStdout).flush

@[noinline] def profileStep {α : Type} (file : System.FilePath) (rows : IO.Ref (List String))
    (phase : String) (work : Unit -> Except String α) : IO α := do
  profileMark file rows phase "started"
  match work () with
  | .error error =>
      profileMark file rows phase "refused" error
      throw (IO.userError ("PSC1_PROFILE_REFUSED: " ++ phase ++ ": " ++ error))
  | .ok value =>
      profileMark file rows phase "completed"
      pure value

def main (args : List String) : IO Unit := do
  let [input, output] := args | throw (IO.userError "usage: profile request.json profile.json")
  let rows <- IO.mkRef ([] : List String)
  let text <- IO.FS.readFile input
  let request <- profileStep output rows "decode" (fun _ => profileMap (fun e : Error => e.code) (decode text))
  let initial := Captured.mk (psCompilerPreparationStart request.kind) [] [] [] none
  let captured <- profileStep output rows "parse-elaborate" (fun _ =>
    profileMap (fun e : Error => e.code) (captureWorker request request.sources initial))
  let entry <- match captured.entry with
    | none => throw (IO.userError "entry missing")
    | some value => pure value
  let _ <- profileStep output rows "exact-closure" (fun _ =>
    profileMap (fun e : Error => e.code) (exactClosureWorker captured.graphRev [request.entry]))
  let work <- profileStep output rows "prepare-erasure" (fun _ =>
    profileMap (fun e : Error => e.code) (prepare request captured))
  let inputIr <- profileStep output rows "strict-original" (fun _ =>
    profileMap (fun _ => "strict-original-refused") (psStrictValidateModule work.raw))
  let names := psErasureDeclarationNames
    (psErasureRuntimeDeclarations psSelfHostRuntimePreludeDeclarationsWithProd work.source)
  let selected := publicValues (authoredNames names entry.declarations) work.raw.declarations
  let _ <- profileStep output rows "public-original" (fun _ => psBackendCheckPublicApi .js inputIr selected)
  let validated <- profileStep output rows "strict-plan-input" (fun _ =>
    profileMap (fun _ => "strict-plan-input-refused") (psStrictValidateModule inputIr.raw))
  let _ <- profileStep output rows "specialize-input-recheck" (fun _ =>
    profileMap psIrSpecializeErrorCode (psIrSpecializeRecheck validated.raw true))
  let imports <- profileStep output rows "seed-imports" (fun _ =>
    profileMap psIrSpecializeErrorCode (psIrSpecializeRewriteImports validated.raw validated.raw.imports))
  let structures <- profileStep output rows "seed-structures" (fun _ =>
    profileMap psIrSpecializeDiagnosticText (psIrSpecializeSeedDetailed
      (psIrSpecializeSeedStructures validated.raw) (fun v => v.name) "seed-structure" validated.raw.structures))
  let inductives <- profileStep output rows "seed-inductives" (fun _ =>
    profileMap psIrSpecializeDiagnosticText (psIrSpecializeSeedDetailed
      (psIrSpecializeSeedInductives validated.raw) (fun v => v.name) "seed-inductive" validated.raw.inductives))
  let declarations <- profileStep output rows "seed-declarations" (fun _ =>
    profileMap psIrSpecializeDiagnosticText (psIrSpecializeSeedDetailed
      (psIrSpecializeSeedDeclarations validated.raw) (fun v => v.name) "seed-declaration" validated.raw.declarations))
  let pending := psListAppend imports.requests
    (psListAppend structures.snd (psListAppend inductives.snd declarations.snd))
  let scheduled <- profileStep output rows "initial-scheduling" (fun _ =>
    .ok (psIrSpecializeScheduleRequests pending PsStringSet.empty))
  profileMark output rows "initial-work" "observed"
    ("references=" ++ toString pending.length ++ " unique=" ++ toString scheduled.requests.length ++
      " duplicate=" ++ toString scheduled.duplicates)
  let initialState := PsIrSpecializeState.mk imports.imports structures.fst inductives.fst
    declarations.fst scheduled.requests []
  let final <- profileStep output rows "specialization-loop" (fun _ =>
    profileMap psIrSpecializeDiagnosticText
      (psIrSpecializeScheduledLoop validated.raw 16384 initialState scheduled.scheduled))
  profileMark output rows "completed-work" "observed"
    ("instances=" ++ toString final.seen.length ++ " declarations=" ++ toString final.declarations.length)
  let specialized := PsVerifiedIrModule.mk final.imports final.structures final.inductives final.declarations
  let _ <- profileStep output rows "specialize-output-recheck" (fun _ =>
    profileMap psIrSpecializeErrorCode (psIrSpecializeRecheck specialized false))
  let closed <- profileStep output rows "strict-plan-output" (fun _ =>
    profileMap (fun _ => "strict-plan-output-refused") (psStrictValidateModule specialized))
  let _ <- profileStep output rows "public-coverage" (fun _ => psBackendClosedNames closed selected)
  let _ <- profileStep output rows "public-specialized" (fun _ => psBackendCheckPublicApi .js closed selected)
  let originalText <- profileStep output rows "encode-original" (fun _ =>
    profileMap (fun _ => "encode-original-refused") (psIrEncodeModule work.raw))
  let specializedText <- profileStep output rows "encode-specialized" (fun _ =>
    profileMap (fun _ => "encode-specialized-refused") (psIrEncodeModule closed.raw))
  IO.FS.writeFile (output ++ ".original-ir.json") originalText
  IO.FS.writeFile (output ++ ".specialized-ir.json") specializedText
  let actualClosed <- profileStep output rows "actual-shared-closed-plan" (fun _ =>
    profileMap psBackendClosedPlanDiagnosticText (psBackendClosedPlanDetailed inputIr selected))
  let closedText <- profileStep output rows "encode-actual-closed-plan" (fun _ =>
    profileMap (fun _ => "encode-closed-refused") (psIrEncodeModule actualClosed.raw))
  IO.FS.writeFile (output ++ ".closed-ir.json") closedText
  let jsIr <- profileStep output rows "js-lower-including-existing-respecialization" (fun _ =>
    profileMap (fun _ => "js-lowering-refused")
      (psJsLowerValidatedModuleWithTargetProfile (PsJsTargetProfile.mk .bits64) actualClosed))
  let _ <- profileStep output rows "js-validate" (fun _ =>
    profileMap (fun _ => "js-validation-refused") (psJsValidateModule jsIr))
  let printed <- profileStep output rows "js-print-declarations" (fun _ =>
    profileMap (fun _ => "js-printing-refused") (psJsPrintDeclarationsWith
      (fun declaration => psJsPrintDeclarationStackSafeWithVisibility
        (psBackendNameSeen declaration.name selected) declaration) jsIr.declarations psTextBuilderEmpty))
  let prelude <- profileStep output rows "js-runtime-prelude" (fun _ => .ok (psJsPrintStackSafePrelude jsIr))
  let emitted := prelude ++ printed
  IO.FS.writeFile (output ++ ".source.mjs") emitted
  IO.FS.writeFile (output ++ ".admissions.json") work.admissions
  let admissionRequest <- profileStep output rows "encode-admission-request" (fun _ =>
    .ok (psCompilerHostAdmissionRequest request.requestId request.sourceClosureDigest "js" work.admissions))
  IO.FS.writeFile (output ++ ".admission-request.json") admissionRequest
  let quotedSource <- profileStep output rows "quote-generated-source" (fun _ => .ok (psJsonQuote emitted))
  IO.FS.writeFile (output ++ ".source-quoted.json") quotedSource
  let candidate <- profileStep output rows "actual-final-candidate" (fun _ =>
    profileMap (fun e : Error => e.code) (compilePrepared request captured entry work))
  IO.FS.writeFile (output ++ ".candidate.json") candidate
  profileMark output rows "profile-complete" "completed"
    ("diagnostic only; candidate bytes=" ++ toString (String.utf8ByteSize candidate))
