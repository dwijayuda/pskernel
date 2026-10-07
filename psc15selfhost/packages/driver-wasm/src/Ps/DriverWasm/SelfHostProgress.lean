import Ps.DriverWasm.Bootstrap

-- Bootstrap diagnostics only: explicit states expose phase boundaries to the
-- host without imports/callbacks inside the generated Wasm compiler. This is
-- candidate processing, never a kernel-checked production capability.
inductive PsCompilerWasmProgress where
  | failed
  | preparing (state : PsCompilerSourcePreparationState)
  | parsed (step : PsCompilerParsedSourceStep)
  | prepared (module : PsCompilerAdmissionReadyModule)
  | validated (module : PsValidatedIrModule)
  | specialized (module : PsSpecializedIrModule)
  | lowered (module : PsWasmModule)
  | encoded (bytes : List UInt8)

def psCompilerWasmProgressInitial : PsCompilerWasmProgress :=
  PsCompilerWasmProgress.preparing psCompilerSourcePreparationInitial

def psCompilerWasmProgressFailed (state : PsCompilerWasmProgress) : Bool :=
  match state with
  | PsCompilerWasmProgress.failed => true
  | _ => false

def psCompilerWasmProgressParse
    (state : PsCompilerWasmProgress)
    (source : String) :
    PsCompilerWasmProgress :=
  match state with
  | PsCompilerWasmProgress.preparing preparation =>
      match
          psCompilerParseSourceStep
            PsCompilerSourceKind.proofScript
            preparation
            source with
      | Except.error _ =>
          PsCompilerWasmProgress.failed
      | Except.ok parsed =>
          PsCompilerWasmProgress.parsed parsed
  | _ =>
      PsCompilerWasmProgress.failed

def psCompilerWasmProgressElaborate
    (state : PsCompilerWasmProgress) :
    PsCompilerWasmProgress :=
  match state with
  | PsCompilerWasmProgress.parsed parsed =>
      match psCompilerElaborateParsedSourceStep parsed with
      | Except.error _ =>
          PsCompilerWasmProgress.failed
      | Except.ok next =>
          PsCompilerWasmProgress.preparing next
  | _ =>
      PsCompilerWasmProgress.failed

def psCompilerWasmProgressPrepare
    (state : PsCompilerWasmProgress)
    (source : String) :
    PsCompilerWasmProgress :=
  match psCompilerWasmProgressParse state source with
  | PsCompilerWasmProgress.parsed parsed =>
      psCompilerWasmProgressElaborate
        (PsCompilerWasmProgress.parsed parsed)
  | _ =>
      PsCompilerWasmProgress.failed

def psCompilerWasmProgressFinish (state : PsCompilerWasmProgress) : PsCompilerWasmProgress :=
  match state with
  | PsCompilerWasmProgress.preparing preparation =>
      match psCompilerFinishSourcePreparation preparation with
      | Except.error _ => PsCompilerWasmProgress.failed
      | Except.ok module => PsCompilerWasmProgress.prepared module
  | _ => PsCompilerWasmProgress.failed

def psCompilerWasmProgressValidate (state : PsCompilerWasmProgress) : PsCompilerWasmProgress :=
  match state with
  | PsCompilerWasmProgress.prepared module =>
      match psCompilerVerifiedIrFromPrepared module with
      | Except.error _ => PsCompilerWasmProgress.failed
      | Except.ok validated => PsCompilerWasmProgress.validated validated
  | _ => PsCompilerWasmProgress.failed

def psCompilerWasmProgressSpecialize (state : PsCompilerWasmProgress) : PsCompilerWasmProgress :=
  match state with
  | PsCompilerWasmProgress.validated module =>
      match psIrSpecializeValidatedModule module with
      | Except.error _ => PsCompilerWasmProgress.failed
      | Except.ok specialized => PsCompilerWasmProgress.specialized specialized
  | _ => PsCompilerWasmProgress.failed

def psCompilerWasmProgressLower (state : PsCompilerWasmProgress) : PsCompilerWasmProgress :=
  match state with
  | PsCompilerWasmProgress.specialized module =>
      match psWasmLowerSpecializedValidatedModule psCompilerWasm32Target module with
      | Except.error _ =>
          PsCompilerWasmProgress.failed
      | Except.ok lowered =>
          let target : PsWasmModule :=
            psWasmAddSelfHostGcAbi lowered;
          match psWasmIrValidateModule target with
          | Except.error _ =>
              PsCompilerWasmProgress.failed
          | Except.ok _ =>
              PsCompilerWasmProgress.lowered target
  | _ =>
      PsCompilerWasmProgress.failed

def psCompilerWasmProgressEncode (state : PsCompilerWasmProgress) : PsCompilerWasmProgress :=
  match state with
  | PsCompilerWasmProgress.lowered module =>
      match psWasmEncodeModule module with
      | Except.error _ => PsCompilerWasmProgress.failed
      | Except.ok bytes => PsCompilerWasmProgress.encoded bytes
  | _ => PsCompilerWasmProgress.failed

def psCompilerWasmProgressOutput (state : PsCompilerWasmProgress) : List UInt8 :=
  match state with
  | PsCompilerWasmProgress.encoded bytes => bytes
  | _ => List.nil
