import Ps.Compiler.Api
import Ps.BackendTs.Module
import Ps.CompilerIr.Check
import Ps.CompilerIr.Construct

-- This entry checks the exact original IR passed to the existing emitter.
-- It establishes runtime IR typing, not provider acceptance or strict SH/1.
inductive PsTsCheckedEmitError where
  | check (report : PsIrCheckReport)
  | emit (error : PsTsEmitError)

structure PsTsCheckedEmission where
  report : PsIrCheckReport
  typeScript : String

-- The returned report is diagnostic data, not a transferable emission permit.
-- Composing entries call this function on their own exact IR, not on a report
-- supplied by a caller, and retain the same object until emission.
def psTsCheckModuleForEmission
    (options : PsIrCheckOptions)
    (ir : PsVerifiedIrModule) : Except PsTsCheckedEmitError PsIrCheckReport :=
  let report := psCheckVerifiedIrModule options ir;
  if report.accepted then
    if report.traversalComplete then Except.ok report
    else Except.error (PsTsCheckedEmitError.check report)
  else
    Except.error (PsTsCheckedEmitError.check report)

-- Return the actual check report without checking the module a second time.
def psTsEmitCheckedModuleWithReport
    (options : PsIrCheckOptions)
    (ir : PsVerifiedIrModule) : Except PsTsCheckedEmitError PsTsCheckedEmission :=
  match psTsCheckModuleForEmission options ir with
  | Except.error error => Except.error error
  | Except.ok report =>
      match psTsEmitModule ir with
      | Except.error error => Except.error (PsTsCheckedEmitError.emit error)
      | Except.ok output => Except.ok (PsTsCheckedEmission.mk report output)

def psTsEmitCheckedModule
    (options : PsIrCheckOptions)
    (ir : PsVerifiedIrModule) : Except PsTsCheckedEmitError String :=
  match psTsEmitCheckedModuleWithReport options ir with
  | Except.error error => Except.error error
  | Except.ok result => Except.ok result.typeScript

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
