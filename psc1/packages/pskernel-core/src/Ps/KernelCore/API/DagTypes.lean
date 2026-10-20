import Ps.KernelCore.API.KernelContractV1

/-
Node IDs below belong only to the single graph supplied to psKernelV1RunDag.
These are untrusted requests, never checked terms, cache keys across sessions,
or proof receipts. Declaration fields retain KernelContract-v1 semantics.
-/
structure PsKernelDagConstantBase where
  name : PsKernelName
  levelParams : List PsKernelName
  type : Nat

structure PsKernelDagDefinition where
  base : PsKernelDagConstantBase
  value : Nat
  hints : PsKernelReducibilityHints
  safety : PsKernelDefinitionSafety

structure PsKernelDagConstructor where
  name : PsKernelName
  type : Nat

structure PsKernelDagInductive where
  name : PsKernelName
  type : Nat
  ctors : List PsKernelDagConstructor

structure PsKernelDagInductiveGroup where
  levelParams : List PsKernelName
  numParams : Nat
  types : List PsKernelDagInductive
  isUnsafe : Bool

inductive PsKernelDagDeclarationRequest where
  | axiomDecl (base : PsKernelDagConstantBase) (isUnsafe : Bool)
  | definitionDecl (value : PsKernelDagDefinition)
  | theoremDecl (base : PsKernelDagConstantBase) (value : Nat)
  | opaqueDecl (base : PsKernelDagConstantBase) (value : Nat) (isUnsafe : Bool)
  | mutualDefinitions (values : List PsKernelDagDefinition)
  | quot
  | ordinaryInductive
      (levelParams : List PsKernelName) (numParams : Nat)
      (value : PsKernelDagInductive) (isUnsafe : Bool)
  | mutualInductive (value : PsKernelDagInductiveGroup)
  | nestedInductive (value : PsKernelDagInductiveGroup)
  | unsupported (feature : String)

inductive PsKernelDagCommand where
  | check (root : Nat)
  | whnf (root : Nat)
  | isDefEq (left right : Nat)
  | admit (request : PsKernelDagDeclarationRequest)

inductive PsKernelDagReply where
  | checked (value : PsKernelCheckedExpression)
  | normalized (value : PsKernelExpr)
  | equal (value : Bool)
  | admitted (receipt : PsKernelCheckingReceipt)
