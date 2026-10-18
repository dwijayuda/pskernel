import Ps.Environment.StandardFloatDisplayData
import Ps.Environment.StandardClass

/-!
Pinned Lean 4.35.0 Float/Float32 opaque display and cross-width contracts.
The generated asset keeps actual checked opaque inhabitants. They do not
reduce in the kernel and are not logical specifications of foreign execution.
Runtime display follows runtime/object.cpp; its shared typed-IR implementation
and native differential checks are separate from logical admission.
-/

def psStandardFloatDisplayInstances : List (String × PsDeclaration) :=
  psStandardFloatDisplayDeclarations.filterMap fun declaration =>
    let name := psNameToString (psDeclarationName declaration)
    let className :=
      if ["instToStringFloat", "instToStringFloat32"].contains name then some "ToString"
      else if ["instReprFloat", "instReprFloat32"].contains name then some "Repr"
      else if ["instReprAtomFloat", "instReprAtomFloat32"].contains name then some "ReprAtom"
      else none
    className.map (fun className => (className, declaration))

def psStandardFloatDisplayExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardFloatDisplayDeclarations.foldl psEnvironmentInsert environment
  let environment := psStandardFloatDisplayReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
  psStandardFloatDisplayInstances.foldl (fun env (className, declaration) =>
    psStandardRegisterInstances env className [declaration]) environment

-- Native opaque inhabitants and their Inhabited dependencies stay logical-only.
-- Only ordinary dictionaries/Repr methods enter the executable prelude.
def psStandardFloatDisplayRuntimeDeclarations : List PsDeclaration :=
  psStandardFloatDisplayDeclarations.filter fun declaration =>
    ["instToStringFloat", "instToStringFloat32", "instReprFloat", "instReprFloat32",
     "instReprAtomFloat", "instReprAtomFloat32", "Float.repr", "Float32.repr"].contains
      (psNameToString (psDeclarationName declaration))

def psStandardFloatDisplayAudit (environment : PsEnvironment) : Except String Unit := do
  if psStandardFloatDisplayDeclarations.length != 16 ||
      psStandardFloatDisplayInstances.length != 6 then
    throw "PSCV0-STANDARD: native display/cross-width family drift"
  for declaration in psStandardFloatDisplayDeclarations do
    psStandardAuditDeclaration environment declaration
  for (_, declaration) in psStandardFloatDisplayInstances do
    psStandardAuditInstance environment declaration
