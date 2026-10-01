import Ps.Compiler.Api
import Ps.BackendRust.Module

inductive PsCompilerRustError where
  | compiler (error : PsCompilerError)
  | emit (error : PsRustEmitError)

def psCompilerRustFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerRustError String :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | Except.error error =>
      Except.error (PsCompilerRustError.compiler error)
  | Except.ok ir =>
      match psRustEmitModule ir with
      | Except.error error =>
          Except.error (PsCompilerRustError.emit error)
      | Except.ok output =>
          Except.ok output

def psCompilerRustFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerRustError String :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error (PsCompilerRustError.compiler error)
  | Except.ok prepared =>
      psCompilerRustFromPrepared prepared

def psCompilerRustSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerRustError String :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error (PsCompilerRustError.compiler error)
  | Except.ok prepared =>
      psCompilerRustFromPrepared prepared
