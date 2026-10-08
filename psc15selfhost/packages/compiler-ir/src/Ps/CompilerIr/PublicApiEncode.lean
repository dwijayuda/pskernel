import Ps.CompilerIr.PublicApi
import Ps.Bridge.CheckedAdmissions

def psPublicApiEncodeConstantKind (kind : PsPublicApiConstantKind) : String :=
  match kind with
  | PsPublicApiConstantKind.axiomValue => "axiom"
  | PsPublicApiConstantKind.definitionValue => "definition"
  | PsPublicApiConstantKind.theoremValue => "theorem"
  | PsPublicApiConstantKind.partialValue => "partial"
  | PsPublicApiConstantKind.opaqueValue => "opaque"

def psPublicApiEncodeNaturals (values : List Nat) : List String :=
  match values with
  | List.nil => List.nil
  | List.cons value rest =>
      List.cons
        (psCheckedAdmissionNatToString value)
        (psPublicApiEncodeNaturals rest)

def psPublicApiEncodeBool (value : Bool) : String :=
  if value then "true" else "false"

def psPublicApiEncodeDeclaration
    (declaration : PsPublicApiDeclaration) :
    Except PsCheckedAdmissionCodecError String :=
  match declaration with
  | PsPublicApiDeclaration.constant kind name levels type =>
      match psEncodeCodecExpr type with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok
            (psJsonArray [
              psJsonQuote "constant",
              psJsonQuote (psPublicApiEncodeConstantKind kind),
              psEncodeCodecName name,
              psEncodeCodecNameList levels,
              encoded
            ])
  | PsPublicApiDeclaration.inductiveDecl info =>
      match psEncodeCodecExpr info.type with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok
            (psJsonArray [
              psJsonQuote "inductive",
              psEncodeCodecName info.name,
              psEncodeCodecNameList info.levelParams,
              encoded,
              psCheckedAdmissionNatToString info.numParams,
              psCheckedAdmissionNatToString info.numIndices,
              psEncodeCodecNameList info.constructors,
              psPublicApiEncodeBool info.isStructure
            ])
  | PsPublicApiDeclaration.constructorDecl info =>
      match psEncodeCodecExpr info.type with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok
            (psJsonArray [
              psJsonQuote "constructor",
              psEncodeCodecName info.name,
              psEncodeCodecNameList info.levelParams,
              encoded,
              psEncodeCodecName info.inductiveName,
              psCheckedAdmissionNatToString info.constructorIndex,
              psCheckedAdmissionNatToString info.numParams,
              psCheckedAdmissionNatToString info.numFields,
              psJsonArray (psPublicApiEncodeNaturals info.recursiveFields)
            ])
  | PsPublicApiDeclaration.recursorDecl info =>
      match psEncodeCodecExpr info.type with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok
            (psJsonArray [
              psJsonQuote "recursor",
              psEncodeCodecName info.name,
              psEncodeCodecNameList info.levelParams,
              encoded,
              psEncodeCodecNameList info.inductiveNames,
              psCheckedAdmissionNatToString info.numParams,
              psCheckedAdmissionNatToString info.numIndices,
              psCheckedAdmissionNatToString info.numMotives,
              psCheckedAdmissionNatToString info.numMinors
            ])

def psPublicApiEncodeDeclarations
    (declarations : List PsPublicApiDeclaration) :
    Except PsCheckedAdmissionCodecError (List String) :=
  match declarations with
  | List.nil => Except.ok List.nil
  | List.cons declaration rest =>
      match psPublicApiEncodeDeclaration declaration with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psPublicApiEncodeDeclarations rest with
          | Except.error error => Except.error error
          | Except.ok tail =>
              Except.ok (List.cons encoded tail)

def psPublicApiEncodeModule
    (api : PsPublicApiModule) : Except PsCheckedAdmissionCodecError String :=
  match psPublicApiEncodeDeclarations api.declarations with
  | Except.error error => Except.error error
  | Except.ok encoded =>
      Except.ok
        (psJsonArray [
          psJsonQuote "psc-public-api-ir/1",
          psJsonQuote "all-prepared-declarations",
          psJsonArray encoded
        ])
