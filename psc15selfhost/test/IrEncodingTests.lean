import Ps.CompilerIr.SourceSignatureEncode
import Ps.DriverTs.Stages
import Ps.DriverJs.Stages
import Ps.DriverWasm.Stages
import Ps.CompilerIr.InterfaceArtifact

def psIrEncodingFixture : PsVerifiedIrModule :=
  PsVerifiedIrModule.mk [] [] [] [
    PsVerifiedIrDeclaration.mk "huge" [] [] (.primitive .nat)
      (.literal (.natural 123456789012345678901234567890)),
    PsVerifiedIrDeclaration.mk "negative" [] [] (.primitive .int) (.literal (.integer (-123))),
    PsVerifiedIrDeclaration.mk "unicode" [] [] (.primitive .string) (.literal (.string "a\n\"😀")),
    PsVerifiedIrDeclaration.mk "unknown" [] [] .unknown (.var "unresolved")]


-- Native consumer fixture: the semantic producer above remains portable.
def psSourceSignatureFixtureJson (api : PsPublicApiModule) : IO String := do
  let entries <- api.declarations.mapM fun declaration => do
    match declaration with
    | .constant _ _ _ type =>
        let .ok encoded := psProjectSourceSignatureJson type
          | throw (IO.userError "SOURCE_SIGNATURE_PROJECTION_FAILED")
        pure encoded
    | _ => throw (IO.userError "SOURCE_SIGNATURE_FIXTURE_NON_CONSTANT")
  pure (psJsonArray entries)

def psSourceSignatureFailureFixture : IO Unit := do
  let nat := PsExpr.constE (PsName.str .anonymous "Nat") []
  let type := PsExpr.sortE (.succ .zero)
  let binder := PsName.str .anonymous "x"
  match psProjectSourceSignatureWithLimits 0 128 nat with
  | .error .resourcePolicy => pure ()
  | _ => throw (IO.userError "SIGNATURE_INVALID_POLICY")
  match psProjectSourceSignatureWithLimits 1 128 nat with
  | .error .resourceExhausted => pure ()
  | _ => throw (IO.userError "SIGNATURE_WORK_LIMIT")
  match psProjectSourceSignatureWithLimits 20 129 nat with
  | .error .resourcePolicy => pure ()
  | _ => throw (IO.userError "SIGNATURE_DEPTH_POLICY")
  match psProjectSourceSignature (.forallE binder nat (.bvar 0) .explicit) with
  | .error .dependentValueTypeUnsupported => pure ()
  | _ => throw (IO.userError "SIGNATURE_DEPENDENT_VALUE")
  match psProjectSourceSignature (.forallE binder (.sortE .zero) nat .explicit) with
  | .error .propositionOrAmbiguousSort => pure ()
  | _ => throw (IO.userError "SIGNATURE_PROP_GUESSED")
  let higherRank := PsExpr.forallE binder type (.bvar 0) .implicit
  match psProjectSourceSignature (.forallE binder higherRank nat .explicit) with
  | .error .higherRankTypeUnsupported => pure ()
  | _ => throw (IO.userError "SIGNATURE_HIGHER_RANK")
  let array := PsExpr.app (.constE (PsName.str .anonymous "Array") [.zero]) nat
  match psProjectSourceSignature array with
  | .error .typeFormUnsupported => pure ()
  | _ => throw (IO.userError "SIGNATURE_ARRAY_UNIVERSE")
  match psProjectSourceSignature (.constE (PsName.str (PsName.str .anonymous "Other") "Nat") []) with
  | .error .namedTypeUnsupported => pure ()
  | _ => throw (IO.userError "SIGNATURE_QUALIFIED_NAME")
  match psProjectSourceSignature (.fvar 0) with
  | .error .typeFormUnsupported => pure ()
  | _ => throw (IO.userError "SIGNATURE_FREE_VARIABLE")
  let deep := (List.range 129).foldl (fun acc _ => PsExpr.app (.constE (PsName.str .anonymous "Array") []) acc) nat
  match psProjectSourceSignature deep with
  | .error .resourceExhausted => pure ()
  | _ => throw (IO.userError "SIGNATURE_DEPTH_LIMIT")
  IO.println "PSCV_SOURCE_SIGNATURE_FAILURES: PASS"

def main (args : List String) : IO Unit := do
  if args == ["--source-signature-errors"] then
    psSourceSignatureFailureFixture
  else if args == ["--raw"] then
    match psIrEncodeModule psIrEncodingFixture with
    | .error _ => throw (IO.userError "IR_ENCODE_FAILED")
    | .ok encoded => IO.println encoded
  else if args == ["--generated-position-cursor"] then
    let .ok first := psJsAdvanceGeneratedText psJsGeneratedPositionZero "a😀"
      | throw (IO.userError "POSITION_FIRST_FAILED")
    let .ok middle := psJsAdvanceGeneratedText first "\r"
      | throw (IO.userError "POSITION_CR_FAILED")
    let .ok final := psJsAdvanceGeneratedText middle "\nx y z"
      | throw (IO.userError "POSITION_TAIL_FAILED")
    let .ok whole := psJsAdvanceGeneratedText psJsGeneratedPositionZero "a😀\r\nx y z"
      | throw (IO.userError "POSITION_WHOLE_FAILED")
    if psJsEncodeGeneratedPosition final != psJsEncodeGeneratedPosition whole then
      throw (IO.userError "POSITION_CHUNK_DRIFT")
    match psJsAdvanceGeneratedTextWorker 0 "x" 0 psJsGeneratedPositionZero with
    | .error .fuelExhausted => pure ()
    | _ => throw (IO.userError "POSITION_EXHAUSTION_IGNORED")
    IO.println (psJsonArray [psJsEncodeGeneratedPosition first, psJsEncodeGeneratedPosition final])
  else if args == ["--erasure-declarations"] then
    let source := "structure Box where\n  value : Nat\ndef forward (A : Type) (value : A) : A := value\ndef proofId (p : Prop) (h : p) : p := h\ndef answer : Nat := forward Nat 42\n"
    let .ok prepared := psCompilerPrepareSource .lean source
      | throw (IO.userError "ERASURE_MAP_PREPARE_FAILED")
    let .ok legacy := psCompilerErasedIrFromPrepared prepared
      | throw (IO.userError "ERASURE_MAP_LEGACY_FAILED")
    let .ok observed := psCompilerErasureProductFromPrepared prepared
      | throw (IO.userError "ERASURE_MAP_OBSERVED_FAILED")
    let .ok legacyIr := psIrEncodeModule legacy.raw
      | throw (IO.userError "ERASURE_MAP_LEGACY_ENCODE_FAILED")
    let .ok observedIr := psIrEncodeModule observed.erased.raw
      | throw (IO.userError "ERASURE_MAP_OBSERVED_ENCODE_FAILED")
    if legacyIr != observedIr then throw (IO.userError "OBSERVATION_CHANGED_ERASURE")
    let .ok api := psCompilerPublicApiFromPrepared prepared
      | throw (IO.userError "ERASURE_MAP_API_FAILED")
    IO.println (psJsonObject [
      ("publicApi", psJsonQuote api),
      ("runtimeIr", psJsonQuote observedIr),
      ("erasureCorrespondence", psJsonQuote observed.correspondence)])
  else if args == ["--origins"] then
    let sources := [
      "def greeting : String := \"😀\"\r\n",
      "structure Box where\n  value : Nat\ndef forward (A : Type) (value : A) : A := value\n"]
    let .ok legacy := psCompilerPrepareSources .lean sources
      | throw (IO.userError "ORIGIN_LEGACY_PREPARE_FAILED")
    let .ok product := psCompilerPrepareSourcesWithOrigins .lean sources
      | throw (IO.userError "ORIGIN_PREPARE_FAILED")
    let .ok legacyAdmissions := psCompilerAdmissionsFromPrepared legacy
      | throw (IO.userError "ORIGIN_LEGACY_ADMISSIONS_FAILED")
    let .ok admissions := psCompilerAdmissionsFromPrepared product.prepared
      | throw (IO.userError "ORIGIN_ADMISSIONS_FAILED")
    if legacyAdmissions != admissions then throw (IO.userError "ORIGINS_CHANGED_ADMISSIONS")
    let .ok api := psCompilerPublicApiFromPrepared product.prepared
      | throw (IO.userError "ORIGIN_API_FAILED")
    IO.println (psJsonObject [
      ("sources", psJsonArray (sources.map psJsonQuote)),
      ("publicApi", psJsonQuote api),
      ("origins", psJsonQuote product.origins)])
  else if args == ["--public-api"] then
    let source := "def forward (A : Type) (value : A) : A := value\ndef answer : Nat := 42\n"
    let changedBody := "def forward (A : Type) (value : A) : A := value\ndef answer : Nat := 43\n"
    let .ok prepared := psCompilerPrepareSource .lean source
      | throw (IO.userError "PUBLIC_API_PREPARE_FAILED")
    let .ok changed := psCompilerPrepareSource .lean changedBody
      | throw (IO.userError "PUBLIC_API_PREPARE_FAILED")
    let .ok api := psCompilerPublicApiFromPrepared prepared
      | throw (IO.userError "PUBLIC_API_PROJECTION_FAILED")
    let .ok changedApi := psCompilerPublicApiFromPrepared changed
      | throw (IO.userError "PUBLIC_API_PROJECTION_FAILED")
    if api != changedApi then throw (IO.userError "PUBLIC_API_RETAINS_IMPLEMENTATION_BODY")
    let .ok stages := psCompilerJavaScriptStagesFromPrepared prepared
      | throw (IO.userError "PUBLIC_API_JS_STAGES_FAILED")
    IO.println (psJsonObject [
      ("publicApi", psJsonQuote api),
      ("specializedIr", psJsonQuote stages.specializedIr)])
  else if args == ["--interface"] then
    let .ok prepared := psCompilerPrepareSource .lean "def answer : Nat := 42\n"
      | throw (IO.userError "PREPARE_FAILED")
    let .ok validated := psCompilerVerifiedIrFromPrepared prepared
      | throw (IO.userError "VALIDATION_FAILED")
    let .ok interface := psIrEncodeRuntimeInterface validated
      | throw (IO.userError "INTERFACE_FAILED")
    IO.println interface
  else if args == ["--js-stages"] || args == ["--js-declaration-stages"] then
    let source := if args == ["--js-declaration-stages"] then
      "def echoNat (value : Nat) : Nat := value\ndef applyNat (fn : Nat -> Nat) (value : Nat) : Nat := fn value\ndef echoArray (values : Array Nat) : Array Nat := values\ndef answer : Nat := applyNat echoNat 42\ndef greeting : String := \"hello\"\n"
      else "def forward (A : Type) (value : A) : A := value\ndef answer : Nat := forward Nat 42\n"
    let .ok observed := psCompilerPrepareSourceWithOrigins .lean source
      | throw (IO.userError "PREPARE_FAILED")
    let prepared := observed.prepared
    let .ok staged := psCompilerJavaScriptStagesFromPrepared prepared
      | throw (IO.userError "JS_STAGES_FAILED")
    let .ok legacy := psCompilerJavaScriptFromPrepared prepared
      | throw (IO.userError "JS_LEGACY_FAILED")
    if legacy != staged.javaScript || staged.runtimeIr != staged.verifiedIr then
      throw (IO.userError "JS_STAGES_CHANGED_OUTPUT")
    let .ok api := psCompilerPublicApiFromPrepared prepared
      | throw (IO.userError "STAGE_PUBLIC_API_FAILED")
    let signatures <- psSourceSignatureFixtureJson (psPublicApiProjectModule prepared.declarations)
    IO.println (psJsonObject [
      ("sourceSignatures", psJsonQuote signatures),
      ("source", psJsonQuote source),
      ("declarationOrigins", psJsonQuote observed.origins),
      ("publicApi", psJsonQuote api),
      ("erasureCorrespondence", psJsonQuote staged.erasureCorrespondence),
      ("runtimeIr", psJsonQuote staged.runtimeIr),
      ("javaScript", psJsonQuote staged.javaScript),
      ("generatedPositions", psJsonQuote staged.generatedPositions),
      ("verifiedIr", psJsonQuote staged.verifiedIr),
      ("specializedIr", psJsonQuote staged.specializedIr),
      ("jsIr", psJsonQuote staged.jsIr)])
  else if args == ["--js-uniform-stages"] then
    let source := "def forward (A : Type) (value : A) : A := value\ndef unused (A : Type) (value : A) : A := value\ndef applyValue (A : Type) (B : Type) (fn : A -> B) (value : A) : B := fn value\ndef echoArray (A : Type) (values : Array A) : Array A := values\ndef mapValues (A : Type) (B : Type) (fn : A -> B) (values : Array A) : Array B := Array.map fn values\ndef answer : Nat := forward Nat 42\ndef choice : Bool := forward Bool true\n"
    let .ok prepared := psCompilerPrepareSource .lean source
      | throw (IO.userError "UNIFORM_PREPARE_FAILED")
    let .ok inputs := psCompilerJavaScriptValidatedInputsFromPrepared prepared
      | throw (IO.userError "UNIFORM_VALIDATION_FAILED")
    if psJsTypeSupportedWithProfile (some psCompilerJavaScriptTarget64) (.typeParameter "T0") then
      throw (IO.userError "CLOSED_TYPE_POLICY_WEAKENED")
    if psJsTypeSupportedWithPolicy (some psCompilerJavaScriptTarget64) true .unknown then
      throw (IO.userError "UNIFORM_UNKNOWN_TYPE_ACCEPTED")
    let first :: _ := inputs.validated.raw.declarations
      | throw (IO.userError "UNIFORM_DECLARATIONS_MISSING")
    match psJsLowerDeclarationWithProfile (some psCompilerJavaScriptTarget64) first with
    | .error (.genericDeclarationUnsupported _) => pure ()
    | _ => throw (IO.userError "CLOSED_DECLARATION_POLICY_WEAKENED")
    let .ok staged := psCompilerUniformJavaScriptStagesFromValidated
        inputs.runtimeIr inputs.verifiedIr inputs.erasureCorrespondence inputs.validated
      | throw (IO.userError "UNIFORM_JS_STAGES_FAILED")
    let .ok closed := psCompilerJavaScriptStagesFromValidated
        inputs.runtimeIr inputs.verifiedIr inputs.erasureCorrespondence inputs.validated
      | throw (IO.userError "CLOSED_JS_STAGES_FAILED")
    let .ok api := psCompilerPublicApiFromPrepared prepared
      | throw (IO.userError "UNIFORM_PUBLIC_API_FAILED")
    let signatures <- psSourceSignatureFixtureJson (psPublicApiProjectModule prepared.declarations)
    IO.println (psJsonObject [
      ("sourceSignatures", psJsonQuote signatures),
      ("source", psJsonQuote source),
      ("publicApi", psJsonQuote api),
      ("erasureCorrespondence", psJsonQuote staged.erasureCorrespondence),
      ("runtimeIr", psJsonQuote staged.runtimeIr),
      ("verifiedIr", psJsonQuote staged.verifiedIr),
      ("uniformSpecializedIr", psJsonQuote staged.uniformSpecializedIr),
      ("jsIr", psJsonQuote staged.jsIr),
      ("javaScript", psJsonQuote staged.javaScript),
      ("generatedPositions", psJsonQuote staged.generatedPositions),
      ("closedJavaScript", psJsonQuote closed.javaScript)])
  else if args == ["--wasm-stages"] then
    let source := "def forward (A : Type) (value : A) : A := value\ndef answer (value : UInt32) : UInt32 := forward UInt32 value\n"
    let .ok prepared := psCompilerPrepareSource .lean source
      | throw (IO.userError "PREPARE_FAILED")
    let .ok staged := psCompilerWasmStagesFromPrepared psCompilerWasm32Target prepared
      | throw (IO.userError "WASM_STAGES_FAILED")
    let .ok legacy := psCompilerWasmFromPrepared psCompilerWasm32Target prepared
      | throw (IO.userError "WASM_LEGACY_FAILED")
    if legacy != staged.wasm || staged.runtimeIr != staged.verifiedIr then
      throw (IO.userError "WASM_STAGES_CHANGED_OUTPUT")
    let .ok api := psCompilerPublicApiFromPrepared prepared
      | throw (IO.userError "STAGE_PUBLIC_API_FAILED")
    IO.println (psJsonObject [
      ("publicApi", psJsonQuote api),
      ("erasureCorrespondence", psJsonQuote staged.erasureCorrespondence),
      ("runtimeIr", psJsonQuote staged.runtimeIr),
      ("wasm", psJsonArray (staged.wasm.map (fun byte => toString byte.toNat))),
      ("verifiedIr", psJsonQuote staged.verifiedIr),
      ("specializedIr", psJsonQuote staged.specializedIr),
      ("wasmIr", psJsonQuote staged.wasmIr)])
  else if args == ["--stages"] then
    let .ok prepared := psCompilerPrepareSource .lean "def answer : Nat := 42\n"
      | throw (IO.userError "PREPARE_FAILED")
    let .ok staged := psCompilerTypeScriptStagesFromPrepared prepared
      | throw (IO.userError "STAGES_FAILED")
    let .ok legacy := psCompilerTypeScriptFromPrepared prepared
      | throw (IO.userError "LEGACY_FAILED")
    if legacy != staged.typeScript || staged.runtimeIr != staged.verifiedIr then
      throw (IO.userError "STAGES_CHANGED_OUTPUT")
    let .ok api := psCompilerPublicApiFromPrepared prepared
      | throw (IO.userError "STAGE_PUBLIC_API_FAILED")
    IO.println (psJsonObject [
      ("publicApi", psJsonQuote api),
      ("erasureCorrespondence", psJsonQuote staged.erasureCorrespondence),
      ("runtimeIr", psJsonQuote staged.runtimeIr),
      ("typeScript", psJsonQuote staged.typeScript),
      ("verifiedIr", psJsonQuote staged.verifiedIr)])
  else
    match psIrJsonExprWithFuel 0 (.literal .unit), psIrJsonTypeWithFuel 0 .unknown with
    | .error .depthExhausted, .error .depthExhausted => IO.println "PSCV_IR_ENCODING_DEPTH: PASS"
    | _, _ => throw (IO.userError "IR_DEPTH_NOT_ENFORCED")
