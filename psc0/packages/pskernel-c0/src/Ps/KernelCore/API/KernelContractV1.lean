import Ps.KernelCore.API.Outcome
import Ps.KernelCore.Admission.Inductive.Nested.Admission

structure PsKernelTargetIdentity where
  contract : String
  leanVersion : String
  leanCommit : String

def psKernelTargetIdentityV1 : PsKernelTargetIdentity :=
  PsKernelTargetIdentity.mk "KernelContract-v1" "4.34.0" "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"

inductive PsKernelDeclarationRequest where
  | axiomDecl (value : PsKernelAxiomInfo)
  | definitionDecl (value : PsKernelDefinitionInfo)
  | theoremDecl (value : PsKernelTheoremInfo)
  | opaqueDecl (value : PsKernelOpaqueInfo)
  | mutualDefinitions (values : List PsKernelDefinitionInfo)
  | quot
  | ordinaryInductive (value : PsKernelSimpleInductiveDecl)
  | mutualInductive (value : PsKernelSimpleMutualInductiveDecl)
  | nestedInductive (value : PsKernelSimpleMutualInductiveDecl)
  | unsupported (feature : String)

/- Receipts are process-local observations, not serialized proof certificates or
   authority tokens. The portable source profile exposes value constructors;
   admitting a CheckedDeclaration always rechecks its request in the current
   session. Low-level environment/session construction remains trusted code. -/
structure PsKernelCheckingReceipt where
  target : PsKernelTargetIdentity
  declarationsBefore : Nat
  declarationsAfter : Nat

structure PsKernelCheckedDeclaration where
  request : PsKernelDeclarationRequest
  receipt : PsKernelCheckingReceipt

structure PsKernelCheckedExpression where
  expression : PsKernelExpr
  type : PsKernelExpr
