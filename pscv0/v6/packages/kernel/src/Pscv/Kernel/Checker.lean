import Lean.Environment
import Pscv.Core.Model

/-!
Build-toolchain Lean kernel checking for immutable declaration candidates.
This is a **different** provider than pskernel-lean@4.34.0: the build is pinned
to Lean 4.35.0-rc3. P0 reports only admission checking, never PSCV-CERT.
The external npm native/Wasm 4.34 providers remain independent oracles.
-/
namespace Pscv.Kernel

-- Profile-owned guard, independent of Lean's logical kernel. Lean permits
-- axioms by design, but arbitrary user/extension axioms cannot enter pscv-closed-v1.
-- Boundary policy exceptions will need distinct explicit assumption contracts.
def checkClosedDeclaration : Lean.Declaration → Except String Unit
  | .axiomDecl _ => .error "PSCV_CLOSED_PROFILE_AXIOM_DENIED"
  | .quotDecl => .error "PSCV_FOUNDATION_REVISION_REQUIRED"
  | .mutualDefnDecl _ => .error "PSCV_CLOSED_PROFILE_PARTIAL_DENIED"
  | .defnDecl value =>
      if value.safety == .safe then .ok ()
      else .error "PSCV_CLOSED_PROFILE_UNSAFE_DEFINITION"
  | .opaqueDecl value =>
      if value.isUnsafe then .error "PSCV_CLOSED_PROFILE_UNSAFE_OPAQUE"
      else .ok ()
  | .inductDecl _ _ _ isUnsafe =>
      if isUnsafe then .error "PSCV_CLOSED_PROFILE_UNSAFE_INDUCTIVE"
      else .ok ()
  | .thmDecl _ => .ok ()

def checkCandidate (candidate : Pscv.CoreCandidate) : IO (Except String Pscv.KernelAdmissionReport) := do
  let mut env ← Lean.mkEmptyEnvironment 0
  for declaration in candidate.declarations do
    match checkClosedDeclaration declaration with
    | .error error => return .error error
    | .ok _ => pure ()
    match env.addDeclCore 2000000 20000 declaration none true with
    | .ok next => env := next
    | .error _ => return .error "PSCV_KERNEL_ADMISSION_REJECTED"
  return .ok {
    provider := "lean4.35.0-rc3-build-host"
    checkedDeclarations := candidate.declarations.size
    evidenceLevel := .kernelAdmissionsChecked
  }

end Pscv.Kernel
