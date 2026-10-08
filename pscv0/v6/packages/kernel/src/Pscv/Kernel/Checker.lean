import Lean.Environment
import Pscv.Core.Model

/-!
Official Lean 4.35 build-toolchain kernel checker in a separate native provider
package. No arbitrary source/extension can mint checked authority: this P0
accepts candidate Lean.Declaration values only and returns diagnostic results.
-/
namespace Pscv

structure CoreCandidate where
  sourceId : String
  declarations : Array Lean.Declaration

inductive EvidenceLevel where
  | candidate
  | kernelAdmissionsChecked
  deriving Repr, BEq

structure KernelAdmissionReport where
  provider : String
  checkedDeclarations : Nat
  evidenceLevel : EvidenceLevel

end Pscv

namespace Pscv.Kernel

-- Separate PSCV closed-profile axioms/unsafe policy from Lean kernel typing.
-- These guards are conservative P0 placeholders; they do not implement the
-- complete verified-assumption, effect, erasure, or specification coverage.
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
