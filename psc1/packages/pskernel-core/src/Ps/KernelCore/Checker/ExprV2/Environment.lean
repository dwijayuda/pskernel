import Ps.KernelCore.Core.Declaration

/-
References retained only after successful complete declaration admission in one
checked DAG batch. Types and optional transparent bodies belong to its canonical
input arena and every append-only continuation. This is the single declaration
index used by constant inference and delta reduction.

The public boundary derives the private table from demanded declarations in the
actual admitted session. It never escapes into a legacy kernel session. These internal, forgeable records are not admission certificates.
Live environment metadata still decides constant kind, safety and universe arity.
Ordinary/mutual/nested recursor types/rules (including K) are installed once from
the newly admitted final-environment prefix, in an appended owning arena. Nested
restored types and constructors are imported from that same checked environment;
ordinary/mutual headers and constructors retain original admitted IDs. This
transitional import does not make inductive admission DAG-native. Quot headers
are installed from all four live constants after successful checked Quot admission.
Repeated explicit Quot commands retain exact existing owners. Preexisting
session declarations are imported on demand into the same private appended arena,
including checked transparent bodies and actual recursor rules. References are
never reused across session identities; live immutable environment indexes and
fresh operation caches remain authoritative.
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
  | quotDecl (kind : PsKernelQuotKind)

structure PsKernelExprV2DeclarationRef where
  name : PsKernelName
  levelParams : List PsKernelName
  type : Nat
  deltaValue : Option Nat
  kind : PsKernelExprV2DeclarationRefKind

/- Keep the immutable declaration list and its exact first-match semantics.
   The internal scan receives the queried name explicitly, avoiding a new
   curried argument closure for each visited owner in generated code. -/
def psKernelExprV2DeclarationRefFindWorker
    (declarations : List PsKernelExprV2DeclarationRef)
    (name : PsKernelName) : Option PsKernelExprV2DeclarationRef :=
  match declarations with
  | List.nil => Option.none
  | List.cons first rest =>
      if psKernelNameEq first.name name then Option.some first
      else psKernelExprV2DeclarationRefFindWorker rest name

/- Retain the original curried public ABI, including partial applications. -/
def psKernelExprV2DeclarationRefFind
    (declarations : List PsKernelExprV2DeclarationRef) :
    PsKernelName -> Option PsKernelExprV2DeclarationRef :=
  match declarations with
  | List.nil =>
      fun (_name : PsKernelName) => Option.none
  | List.cons _ _ =>
      fun (name : PsKernelName) =>
        psKernelExprV2DeclarationRefFindWorker declarations name

def psKernelExprV2QuotKindEq
    (left right : PsKernelQuotKind) : Bool :=
  match left with
  | PsKernelQuotKind.typeQ =>
      match right with
      | PsKernelQuotKind.typeQ => true
      | _ => false
  | PsKernelQuotKind.ctorQ =>
      match right with
      | PsKernelQuotKind.ctorQ => true
      | _ => false
  | PsKernelQuotKind.liftQ =>
      match right with
      | PsKernelQuotKind.liftQ => true
      | _ => false
  | PsKernelQuotKind.indQ =>
      match right with
      | PsKernelQuotKind.indQ => true
      | _ => false

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
  | PsKernelExprV2DeclarationRefKind.quotDecl kind =>
      match info with
      | PsKernelConstantInfo.quotInfo value =>
          psKernelExprV2QuotKindEq kind value.kind
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
