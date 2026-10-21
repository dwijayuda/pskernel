import Ps.KernelCore.Core.Declaration

/-
References retained only after successful complete declaration admission in one
checked DAG batch. Types and optional transparent bodies belong to its canonical
input arena and every append-only continuation. This is the single declaration
index used by constant inference and delta reduction.

The public boundary creates the table empty. It never escapes into a legacy
kernel session. These internal, forgeable records are not admission certificates.
Live environment metadata still decides constant kind, safety and universe arity.
Generated recursor types, nested-inductive restoration and preexisting-session
constants remain unsupported until their own DAG types exist. Ordinary/mutual
inductive headers and constructor types retain their original admitted IDs.
-/
inductive PsKernelExprV2DeclarationRefKind where
  | axiomDecl
  | definitionDecl
  | theoremDecl
  | opaqueDecl
  | inductiveDecl
  | constructorDecl

structure PsKernelExprV2DeclarationRef where
  name : PsKernelName
  levelParams : List PsKernelName
  type : Nat
  deltaValue : Option Nat
  kind : PsKernelExprV2DeclarationRefKind

def psKernelExprV2DeclarationRefFind
    (declarations : List PsKernelExprV2DeclarationRef) :
    PsKernelName -> Option PsKernelExprV2DeclarationRef :=
  match declarations with
  | List.nil =>
      fun (_name : PsKernelName) => Option.none
  | List.cons first rest =>
      let smaller :=
        fun (nextName : PsKernelName) =>
          let recur := psKernelExprV2DeclarationRefFind rest;
          recur nextName;
      fun (name : PsKernelName) =>
        if psKernelNameEq first.name name then Option.some first
        else smaller name

def psKernelExprV2DeclarationRefKindMatches
    (kind : PsKernelExprV2DeclarationRefKind) (info : PsKernelConstantInfo) :
    Bool :=
  match kind with
  | PsKernelExprV2DeclarationRefKind.axiomDecl =>
      match info with
      | PsKernelConstantInfo.axiomInfo _ => true
      | _ => false
  | PsKernelExprV2DeclarationRefKind.definitionDecl =>
      match info with
      | PsKernelConstantInfo.defnInfo _ => true
      | _ => false
  | PsKernelExprV2DeclarationRefKind.theoremDecl =>
      match info with
      | PsKernelConstantInfo.thmInfo _ => true
      | _ => false
  | PsKernelExprV2DeclarationRefKind.opaqueDecl =>
      match info with
      | PsKernelConstantInfo.opaqueInfo _ => true
      | _ => false

  | PsKernelExprV2DeclarationRefKind.inductiveDecl =>
      match info with
      | PsKernelConstantInfo.inductInfo _ => true
      | _ => false
  | PsKernelExprV2DeclarationRefKind.constructorDecl =>
      match info with
      | PsKernelConstantInfo.ctorInfo _ => true
      | _ => false

def psKernelExprV2DeclarationRefMatches
    (declaration : PsKernelExprV2DeclarationRef)
    (info : PsKernelConstantInfo) : Bool :=
  if psKernelNameEq declaration.name (psKernelConstantInfoName info) then
    if psKernelNameListsEq declaration.levelParams
        (psKernelConstantInfoLevelParams info) then
      psKernelExprV2DeclarationRefKindMatches declaration.kind info
    else false
  else false
