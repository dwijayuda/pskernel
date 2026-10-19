import Ps.KernelCore.API.Outcome
import Ps.KernelCore.Admission.Inductive.Nested.Admission

structure PsKernelTargetIdentity where
  contract : String
  leanVersion : String
  leanCommit : String

def psKernelTargetIdentityV1 : PsKernelTargetIdentity :=
  PsKernelTargetIdentity.mk "KernelContract-v1" "4.35.0" "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"

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
