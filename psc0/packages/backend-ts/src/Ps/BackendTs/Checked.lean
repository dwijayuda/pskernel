import Ps.Compiler.Api
import Ps.BackendTs.Module
import Ps.CompilerIr.Check
import Ps.CompilerIr.Construct

-- This entry checks the exact original IR passed to the existing emitter.
-- It establishes runtime IR typing, not provider acceptance or strict SH/1.
inductive PsTsCheckedEmitError where
  | check (report : PsIrCheckReport)
  | emit (error : PsTsEmitError)

def psTsEmitCheckedModule
    (options : PsIrCheckOptions)
    (ir : PsVerifiedIrModule) : Except PsTsCheckedEmitError String :=
  let report := psCheckVerifiedIrModule options ir;
  if report.accepted then
    if report.traversalComplete then
      match psTsEmitModule ir with
      | Except.error error => Except.error (PsTsCheckedEmitError.emit error)
      | Except.ok output => Except.ok output
    else
      Except.error (PsTsCheckedEmitError.check report)
  else
    Except.error (PsTsCheckedEmitError.check report)

inductive PsCompilerCheckedTypeScriptError where
  | compiler (error : PsCompilerError)
  | checkedEmit (error : PsTsCheckedEmitError)

def psCompilerCheckedTypeScriptFromPrepared
    (options : PsIrCheckOptions)
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerCheckedTypeScriptError String :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | Except.error error =>
      Except.error (PsCompilerCheckedTypeScriptError.compiler error)
  | Except.ok ir =>
      match psTsEmitCheckedModule options ir with
      | Except.error error =>
          Except.error (PsCompilerCheckedTypeScriptError.checkedEmit error)
      | Except.ok output =>
          Except.ok output
