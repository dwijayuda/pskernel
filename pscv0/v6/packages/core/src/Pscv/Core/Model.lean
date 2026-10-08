import Lean.Declaration

/-!
Minimal PSCV Core implementation-boundary models, intentionally using Lean's
own Name, Expr and Declaration representations instead of recreating a kernel.
This is not a completed PSCV source frontend or a certification issuer.
-/
namespace Pscv

inductive Profile where
  | standard
  | verified
  | leanExtensible
  deriving Repr, BEq, Inhabited

def Profile.identity : Profile → String
  | .standard => "ps-standard-0.9-r3"
  | .verified => "pscv-v1"
  | .leanExtensible => "ps-lean-extensible-0.9-r3"

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
