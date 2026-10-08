import Ps.Compiler.Api
import Ps.BackendTs.Module

inductive PsCompilerTypeScriptError where
  | compiler (error : PsCompilerError)
  | emit (error : PsTsEmitError)

def psCompilerTypeScriptFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerTypeScriptError String :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | Except.error error =>
      Except.error (PsCompilerTypeScriptError.compiler error)
  | Except.ok ir =>
      match psTsEmitModule ir with
      | Except.error error =>
          Except.error (PsCompilerTypeScriptError.emit error)
      | Except.ok output =>
          Except.ok output

def psCompilerTypeScriptFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerTypeScriptError String :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error (PsCompilerTypeScriptError.compiler error)
  | Except.ok prepared =>
      psCompilerTypeScriptFromPrepared prepared

def psCompilerTypeScriptSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerTypeScriptError String :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error (PsCompilerTypeScriptError.compiler error)
  | Except.ok prepared =>
      psCompilerTypeScriptFromPrepared prepared
