import Ps.Compiler.Api
import Ps.BackendJs.Print

inductive PsCompilerJavaScriptError where
  | compiler (error : PsCompilerError)
  | emit (error : PsJsEmitError)

def psCompilerJavaScriptTarget64 : PsJsTargetProfile :=
  { wordSize := PsJsWordSize.bits64 }

def psCompilerJavaScriptFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerJavaScriptError String :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok ir =>
      match
          psJsEmitValidatedModuleWithTargetProfile
            psCompilerJavaScriptTarget64
            ir with
      | Except.error error =>
          Except.error (PsCompilerJavaScriptError.emit error)
      | Except.ok output =>
          Except.ok output

def psCompilerJavaScriptFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerJavaScriptError String :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok prepared =>
      psCompilerJavaScriptFromPrepared prepared

def psCompilerJavaScriptSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerJavaScriptError String :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok prepared =>
      psCompilerJavaScriptFromPrepared prepared

def psCompilerJavaScriptProofScriptSource
    (source : String) :
    Except PsCompilerJavaScriptError String :=
  psCompilerJavaScriptSource
    PsCompilerSourceKind.proofScript
    source

def psCompilerJavaScriptProofScriptSources
    (sources : List String) :
    Except PsCompilerJavaScriptError String :=
  match
      psCompilerPrepareSources
        PsCompilerSourceKind.proofScript
        sources with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok prepared =>
      psCompilerJavaScriptFromPrepared prepared
