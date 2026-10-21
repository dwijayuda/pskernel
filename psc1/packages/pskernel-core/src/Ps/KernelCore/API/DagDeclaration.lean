import Ps.KernelCore.API.DagTypes
import Ps.KernelCore.Core.ExprV2.Decode
import Ps.KernelCore.Checker.ExprV2.Environment

/-
Decode declaration references at the checked input boundary. This module
never installs an unchecked declaration or changes an admission rule.
-/
def psKernelDagDecodeBase
    (built : PsKernelExprV2Decoded)
    (base : PsKernelDagConstantBase) :
    Except String PsKernelConstantBase :=
  match psKernelExprV2DecodedRequire built base.type with
  | Except.error error => Except.error error
  | Except.ok type =>
      Except.ok (PsKernelConstantBase.mk base.name base.levelParams type)

def psKernelDagDecodeDefinition
    (built : PsKernelExprV2Decoded)
    (value : PsKernelDagDefinition) :
    Except String PsKernelDefinitionInfo :=
  match psKernelDagDecodeBase built value.base with
  | Except.error error => Except.error error
  | Except.ok base =>
      match psKernelExprV2DecodedRequire built value.value with
      | Except.error error => Except.error error
      | Except.ok body =>
          Except.ok
            (PsKernelDefinitionInfo.mk base body value.hints value.safety)

def psKernelDagDecodeDefinitions
    (built : PsKernelExprV2Decoded)
    (values : List PsKernelDagDefinition) :
    Except String (List PsKernelDefinitionInfo) :=
  match values with
  | List.nil => Except.ok List.nil
  | List.cons head rest =>
      match psKernelDagDecodeDefinition built head with
      | Except.error error => Except.error error
      | Except.ok value =>
          match psKernelDagDecodeDefinitions built rest with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (List.cons value tail)

def psKernelDagDecodeConstructors
    (built : PsKernelExprV2Decoded)
    (values : List PsKernelDagConstructor) :
    Except String (List PsKernelSimpleConstructorDecl) :=
  match values with
  | List.nil => Except.ok List.nil
  | List.cons head rest =>
      match psKernelExprV2DecodedRequire built head.type with
      | Except.error error => Except.error error
      | Except.ok type =>
          match psKernelDagDecodeConstructors built rest with
          | Except.error error => Except.error error
          | Except.ok tail =>
              Except.ok
                (List.cons (PsKernelSimpleConstructorDecl.mk head.name type) tail)

def psKernelDagDecodeInductive
    (built : PsKernelExprV2Decoded)
    (value : PsKernelDagInductive) :
    Except String PsKernelSimpleMutualTypeDecl :=
  match psKernelExprV2DecodedRequire built value.type with
  | Except.error error => Except.error error
  | Except.ok type =>
      match psKernelDagDecodeConstructors built value.ctors with
      | Except.error error => Except.error error
      | Except.ok ctors =>
          Except.ok (PsKernelSimpleMutualTypeDecl.mk value.name type ctors)

def psKernelDagDecodeInductives
    (built : PsKernelExprV2Decoded)
    (values : List PsKernelDagInductive) :
    Except String (List PsKernelSimpleMutualTypeDecl) :=
  match values with
  | List.nil => Except.ok List.nil
  | List.cons head rest =>
      match psKernelDagDecodeInductive built head with
      | Except.error error => Except.error error
      | Except.ok value =>
          match psKernelDagDecodeInductives built rest with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (List.cons value tail)

def psKernelDagDecodeGroup
    (built : PsKernelExprV2Decoded)
    (value : PsKernelDagInductiveGroup) :
    Except String PsKernelSimpleMutualInductiveDecl :=
  match psKernelDagDecodeInductives built value.types with
  | Except.error error => Except.error error
  | Except.ok types =>
      Except.ok
        (PsKernelSimpleMutualInductiveDecl.mk
          value.levelParams value.numParams types value.isUnsafe)

def psKernelDagDecodeDeclaration
    (built : PsKernelExprV2Decoded)
    (request : PsKernelDagDeclarationRequest) :
    Except String PsKernelDeclarationRequest :=
  match request with
  | PsKernelDagDeclarationRequest.axiomDecl value isUnsafe =>
      match psKernelDagDecodeBase built value with
      | Except.error error => Except.error error
      | Except.ok base =>
          Except.ok
            (PsKernelDeclarationRequest.axiomDecl
              (PsKernelAxiomInfo.mk base isUnsafe))
  | PsKernelDagDeclarationRequest.definitionDecl value =>
      match psKernelDagDecodeDefinition built value with
      | Except.error error => Except.error error
      | Except.ok definition =>
          Except.ok (PsKernelDeclarationRequest.definitionDecl definition)
  | PsKernelDagDeclarationRequest.theoremDecl value root =>
      match psKernelDagDecodeBase built value with
      | Except.error error => Except.error error
      | Except.ok base =>
          match psKernelExprV2DecodedRequire built root with
          | Except.error error => Except.error error
          | Except.ok proof =>
              Except.ok
                (PsKernelDeclarationRequest.theoremDecl
                  (PsKernelTheoremInfo.mk base proof))
  | PsKernelDagDeclarationRequest.opaqueDecl value root isUnsafe =>
      match psKernelDagDecodeBase built value with
      | Except.error error => Except.error error
      | Except.ok base =>
          match psKernelExprV2DecodedRequire built root with
          | Except.error error => Except.error error
          | Except.ok body =>
              Except.ok
                (PsKernelDeclarationRequest.opaqueDecl
                  (PsKernelOpaqueInfo.mk base body isUnsafe))
  | PsKernelDagDeclarationRequest.mutualDefinitions values =>
      match psKernelDagDecodeDefinitions built values with
      | Except.error error => Except.error error
      | Except.ok definitions =>
          Except.ok (PsKernelDeclarationRequest.mutualDefinitions definitions)
  | PsKernelDagDeclarationRequest.quot =>
      Except.ok PsKernelDeclarationRequest.quot
  | PsKernelDagDeclarationRequest.ordinaryInductive params count value isUnsafe =>
      match psKernelDagDecodeInductive built value with
      | Except.error error => Except.error error
      | Except.ok type =>
          Except.ok
            (PsKernelDeclarationRequest.ordinaryInductive
              (PsKernelSimpleInductiveDecl.mk
                params type.name type.type type.ctors isUnsafe count))
  | PsKernelDagDeclarationRequest.mutualInductive value =>
      match psKernelDagDecodeGroup built value with
      | Except.error error => Except.error error
      | Except.ok group =>
          Except.ok (PsKernelDeclarationRequest.mutualInductive group)
  | PsKernelDagDeclarationRequest.nestedInductive value =>
      match psKernelDagDecodeGroup built value with
      | Except.error error => Except.error error
      | Except.ok group =>
          Except.ok (PsKernelDeclarationRequest.nestedInductive group)
  | PsKernelDagDeclarationRequest.unsupported feature =>
      Except.ok (PsKernelDeclarationRequest.unsupported feature)

/-
Publish input IDs only after complete admission succeeds. For these declaration
families the checked environment installs the original type unchanged. Only
transparent definition requests publish a delta body. Ordinary/mutual inductive
headers and constructors retain their input types. API.DagGenerated separately
installs recursor types/rules and final restored nested metadata only after the
complete indicated admission succeeds.
-/
def psKernelDagDeclarationRef
    (base : PsKernelDagConstantBase)
    (deltaValue : Option Nat) (kind : PsKernelExprV2DeclarationRefKind) :
    PsKernelExprV2DeclarationRef :=
  PsKernelExprV2DeclarationRef.mk
    base.name base.levelParams base.type deltaValue kind

def psKernelDagDefinitionRef
    (value : PsKernelDagDefinition) : PsKernelExprV2DeclarationRef :=
  psKernelDagDeclarationRef value.base (Option.some value.value)
    PsKernelExprV2DeclarationRefKind.definitionDecl

def psKernelDagAddAdmittedDefinitions
    (values : List PsKernelDagDefinition) :
    List PsKernelExprV2DeclarationRef -> List PsKernelExprV2DeclarationRef :=
  match values with
  | List.nil =>
      fun (declarations : List PsKernelExprV2DeclarationRef) => declarations
  | List.cons first rest =>
      let smaller :=
        fun (next : List PsKernelExprV2DeclarationRef) =>
          let recur := psKernelDagAddAdmittedDefinitions rest;
          recur next;
      fun (declarations : List PsKernelExprV2DeclarationRef) =>
        smaller (List.cons (psKernelDagDefinitionRef first) declarations)

/- Original input types are installed unchanged by ordinary/mutual admission.
   Register only after the complete bundle, including generated recursors,
   succeeds. No generated or restored expression is imported here. -/
def psKernelDagAddAdmittedConstructors
    (constructors : List PsKernelDagConstructor) :
    List PsKernelName -> List PsKernelExprV2DeclarationRef ->
    List PsKernelExprV2DeclarationRef :=
  match constructors with
  | List.nil =>
      fun (_levelParams : List PsKernelName)
          (declarations : List PsKernelExprV2DeclarationRef) => declarations
  | List.cons first rest =>
      fun (levelParams : List PsKernelName)
          (declarations : List PsKernelExprV2DeclarationRef) =>
        let recur := psKernelDagAddAdmittedConstructors rest;
        recur levelParams
          (List.cons
            (psKernelDagDeclarationRef
              (PsKernelDagConstantBase.mk first.name levelParams first.type)
              Option.none PsKernelExprV2DeclarationRefKind.constructorDecl)
            declarations)

def psKernelDagAddAdmittedInductive
    (levelParams : List PsKernelName) (value : PsKernelDagInductive)
    (declarations : List PsKernelExprV2DeclarationRef) :
    List PsKernelExprV2DeclarationRef :=
  psKernelDagAddAdmittedConstructors value.ctors levelParams
    (List.cons
      (psKernelDagDeclarationRef
        (PsKernelDagConstantBase.mk value.name levelParams value.type)
        Option.none PsKernelExprV2DeclarationRefKind.inductiveDecl)
      declarations)

def psKernelDagAddAdmittedInductives
    (types : List PsKernelDagInductive) :
    List PsKernelName -> List PsKernelExprV2DeclarationRef ->
    List PsKernelExprV2DeclarationRef :=
  match types with
  | List.nil =>
      fun (_levelParams : List PsKernelName)
          (declarations : List PsKernelExprV2DeclarationRef) => declarations
  | List.cons first rest =>
      fun (levelParams : List PsKernelName)
          (declarations : List PsKernelExprV2DeclarationRef) =>
        let recur := psKernelDagAddAdmittedInductives rest;
        recur levelParams
          (psKernelDagAddAdmittedInductive levelParams first declarations)

def psKernelDagDeclarationsAfterAdmission
    (request : PsKernelDagDeclarationRequest)
    (declarations : List PsKernelExprV2DeclarationRef) :
    List PsKernelExprV2DeclarationRef :=
  match request with
  | PsKernelDagDeclarationRequest.axiomDecl base _ =>
      List.cons
        (psKernelDagDeclarationRef base Option.none
          PsKernelExprV2DeclarationRefKind.axiomDecl)
        declarations
  | PsKernelDagDeclarationRequest.definitionDecl value =>
      List.cons (psKernelDagDefinitionRef value) declarations
  | PsKernelDagDeclarationRequest.theoremDecl base _ =>
      List.cons
        (psKernelDagDeclarationRef base Option.none
          PsKernelExprV2DeclarationRefKind.theoremDecl)
        declarations
  | PsKernelDagDeclarationRequest.opaqueDecl base _ _ =>
      List.cons
        (psKernelDagDeclarationRef base Option.none
          PsKernelExprV2DeclarationRefKind.opaqueDecl)
        declarations
  | PsKernelDagDeclarationRequest.mutualDefinitions values =>
      psKernelDagAddAdmittedDefinitions values declarations
  | PsKernelDagDeclarationRequest.ordinaryInductive levelParams _ value _ =>
      psKernelDagAddAdmittedInductive levelParams value declarations
  | PsKernelDagDeclarationRequest.mutualInductive value =>
      psKernelDagAddAdmittedInductives value.types value.levelParams declarations
  | _ => declarations
