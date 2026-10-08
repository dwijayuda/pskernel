import Lean.Environment
import Pscv.Core.Model

/-!
Build-toolchain Lean kernel checking for immutable declaration candidates.
This is a **different** provider than pskernel-lean@4.34.0: the build is pinned
to Lean 4.35.0-rc3. P0 reports only admission checking, never PSCV-CERT.
The external npm native/Wasm 4.34 providers remain independent oracles.
-/
namespace Pscv.Kernel

def checkCandidate (candidate : Pscv.CoreCandidate) : IO (Except String Pscv.KernelAdmissionReport) := do
  let mut env ← Lean.mkEmptyEnvironment 0
  for declaration in candidate.declarations do
    match env.addDeclCore 2000000 20000 declaration none true with
    | .ok next => env := next
    | .error _ => return .error "PSCV_KERNEL_ADMISSION_REJECTED"
  return .ok {
    provider := "lean4.35.0-rc3-build-host"
    checkedDeclarations := candidate.declarations.size
    evidenceLevel := .kernelAdmissionsChecked
  }

end Pscv.Kernel
