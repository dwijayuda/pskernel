import Ps.KernelCore.Core.Declaration

/-
References retained only after successful complete declaration admission in one
checked DAG batch. Types and optional transparent bodies belong to its canonical
input arena and every append-only continuation. This is the single declaration
index used by constant inference and delta reduction.

The public boundary creates the table empty. It never escapes into a legacy
kernel session. These internal, forgeable records are not admission certificates.
Live environment metadata still decides constant kind, safety and universe arity.
Ordinary/mutual/nested recursor types/rules (including K) are installed once from
the newly admitted final-environment prefix, in an appended owning arena. Nested
restored types and constructors are imported from that same checked environment;
ordinary/mutual headers and constructors retain original admitted IDs. This
transitional import does not make inductive admission DAG-native. Preexisting
session constants still require a separately qualified owning-reference adapter.
-/
/- Generated rule IDs are private to one validated command batch. They are
   installed only from metadata produced by complete inductive admission. -/
structure PsKernelExprV2RecursorRuleRef where
  ctor : PsKernelName
  nFields : Nat
  rhs : Nat

inductive PsKernelExprV2DeclarationRefKind where
  | axiomDecl
  | definitionDecl
  | theoremDecl
  | opaqueDecl
  | inductiveDecl
  | constructorDecl
  | recursorDecl (rules : List PsKernelExprV2RecursorRuleRef)

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
  | PsKernelExprV2DeclarationRefKind.recursorDecl _ =>
      match info with
      | PsKernelConstantInfo.recInfo _ => true
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
