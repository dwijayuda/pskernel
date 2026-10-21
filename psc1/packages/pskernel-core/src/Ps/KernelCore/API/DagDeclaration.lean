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
Called only after the complete admission of this request succeeds. The decoded
request and these references came from the same validated input DAG. Failed
admission returns before this function is used; no index escapes a batch.
-/
def psKernelDagDefinitionRef
    (value : PsKernelDagDefinition) : PsKernelExprV2DefinitionRef :=
  PsKernelExprV2DefinitionRef.mk value.base.name value.base.levelParams value.value

def psKernelDagAddAdmittedDefinitions
    (values : List PsKernelDagDefinition) :
    List PsKernelExprV2DefinitionRef -> List PsKernelExprV2DefinitionRef :=
  match values with
  | List.nil =>
      fun (definitions : List PsKernelExprV2DefinitionRef) => definitions
  | List.cons first rest =>
      let smaller :=
        fun (next : List PsKernelExprV2DefinitionRef) =>
          let recur := psKernelDagAddAdmittedDefinitions rest;
          recur next;
      fun (definitions : List PsKernelExprV2DefinitionRef) =>
        smaller (List.cons (psKernelDagDefinitionRef first) definitions)

def psKernelDagDefinitionsAfterAdmission
    (request : PsKernelDagDeclarationRequest)
    (definitions : List PsKernelExprV2DefinitionRef) :
    List PsKernelExprV2DefinitionRef :=
  match request with
  | PsKernelDagDeclarationRequest.definitionDecl value =>
      List.cons (psKernelDagDefinitionRef value) definitions
  | PsKernelDagDeclarationRequest.mutualDefinitions values =>
      psKernelDagAddAdmittedDefinitions values definitions
  | _ => definitions
