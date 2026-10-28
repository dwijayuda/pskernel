import Ps.BackendCommon.ServiceError
import Ps.BackendCommon.Plan
Ps.BackendJs.Print

-- Pure target emission only. Checked orchestration stays in the compiler driver.
namespace Ps.Internal.JsCompilerService

def emit (module : PsValidatedIrModule) (publicNames : List String) :
    Except Ps.Internal.CompilerService.Error (Prod String (List String)) :=
  match psJsLowerValidatedModuleWithTargetProfile (PsJsTargetProfile.mk PsJsWordSize.bits64) module with
  | Except.error _ => Except.error (Ps.Internal.CompilerService.failure "js-lowering" "target-refused")
  | Except.ok jsIr =>
      match psJsValidateModule jsIr with
      | Except.error _ => Except.error (Ps.Internal.CompilerService.failure "js-validation" "target-refused")
      | Except.ok _ =>
          match psJsPrintDeclarationsWith
              (fun (declaration : PsJsIrDeclaration) =>
                psJsPrintDeclarationStackSafeWithVisibility
                  (psBackendNameSeen declaration.name publicNames) declaration)
              jsIr.declarations psTextBuilderEmpty with
          | Except.error _ => Except.error (Ps.Internal.CompilerService.failure "js-printing" "target-refused")
          | Except.ok declarations =>
              let suffix : String := if psListIsEmpty publicNames then "\nexport {};\n" else "";
              Except.ok (Prod.mk
                (psJsConcat3 (psJsPrintStackSafePrelude jsIr) declarations suffix)
                (psJsSelectedRuntimeRequirements jsIr))

end Ps.Internal.JsCompilerService
