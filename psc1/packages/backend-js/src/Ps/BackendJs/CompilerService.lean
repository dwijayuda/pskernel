import Ps.Compiler.Service
import Ps.BackendJs.Print

namespace Ps.Internal.JsCompilerService
open Ps.Internal.CompilerService

def emit (module : PsValidatedIrModule) (publicNames : List String) :
    Except Error (Prod String (List String)) :=
  match psJsLowerValidatedModuleWithTargetProfile (PsJsTargetProfile.mk PsJsWordSize.bits64) module with
  | Except.error _ => Except.error (failure "js-lowering" "target-refused")
  | Except.ok jsIr =>
      match psJsValidateModule jsIr with
      | Except.error _ => Except.error (failure "js-validation" "target-refused")
      | Except.ok _ =>
          match psJsPrintDeclarationsWith
              (fun (declaration : PsJsIrDeclaration) =>
                psJsPrintDeclarationStackSafeWithVisibility
                  (psBackendNameSeen declaration.name publicNames) declaration)
              jsIr.declarations psTextBuilderEmpty with
          | Except.error _ => Except.error (failure "js-printing" "target-refused")
          | Except.ok declarations =>
              let suffix : String := if psListIsEmpty publicNames then "\nexport {};\n" else "";
              Except.ok (Prod.mk
                (psJsConcat3 (psJsPrintStackSafePrelude jsIr) declarations suffix)
                (psJsSelectedRuntimeRequirements jsIr))

end Ps.Internal.JsCompilerService

/-- Provisional output only; the external host independently admits the graph. -/
def psCompilerJsServiceCandidate (input : String) : String :=
  Ps.Internal.CompilerService.candidate PsBackendTarget.js Ps.Internal.JsCompilerService.emit input
