import Ps.BackendCommon.ServiceError
import Ps.BackendCommon.Plan
import Ps.BackendTs.Module

-- Pure target emission only. Checked orchestration stays in the compiler driver.
namespace Ps.Internal.TsCompilerService

def emit (module : PsValidatedIrModule) (publicNames : List String) :
    Except Ps.Internal.CompilerService.Error (Prod String (List String)) :=
  let raw : PsVerifiedIrModule := module.raw;
  let brands : List (Prod String String) := psTsBuildBrandMap raw;
  let tags : List (Prod String String) := psTsBuildTagMap raw;
  match psListMapExcept (psTsEmitStructureWithVisibility false brands) raw.structures with
  | Except.error _ => Except.error (Ps.Internal.CompilerService.failure "ts-printing" "structure-refused")
  | Except.ok structures =>
      match psListMapExcept (psTsEmitInductiveWithVisibility false tags) raw.inductives with
      | Except.error _ => Except.error (Ps.Internal.CompilerService.failure "ts-printing" "inductive-refused")
      | Except.ok inductives =>
          match psListMapExcept
              (fun (declaration : PsVerifiedIrDeclaration) =>
                psTsEmitDeclarationWithVisibility
                  (psBackendNameSeen declaration.name publicNames) brands tags declaration)
              raw.declarations with
          | Except.error _ => Except.error (Ps.Internal.CompilerService.failure "ts-printing" "declaration-refused")
          | Except.ok declarations =>
              let lines : List String := psTsFlattenLines [
                ["// PSC1 shared checked compiler service.", psTsSelectedRuntimeSource raw],
                psListMap psTsEmitImport raw.imports,
                psTsFlattenLines structures, psTsFlattenLines inductives, declarations];
              Except.ok (Prod.mk
                (String.Internal.append (psTsJoin "\n" lines)
                  (if psListIsEmpty publicNames then "\nexport {};\n" else "\n"))
                (psTsSelectedRuntimeRequirements raw))

end Ps.Internal.TsCompilerService
