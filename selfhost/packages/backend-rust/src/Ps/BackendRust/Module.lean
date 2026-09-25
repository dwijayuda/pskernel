import Ps.BackendRust.Expr
import Ps.BackendRust.ValueRefs
import Ps.BackendRust.Runtime

def psRustTypeParameterNames
    (parameters : List PsVerifiedIrTypeParameter) : List String :=
  match parameters with
  | List.nil =>
      List.nil
  | List.cons parameter rest =>
      List.cons
        (psRustConcat3
          (psRustIdentifier parameter.name)
          ": "
          "Clone")
        (psRustTypeParameterNames rest)

def psRustGenericNames
    (parameters : List PsVerifiedIrTypeParameter) : String :=
  match parameters with
  | List.nil =>
      ""
  | List.cons _ _ =>
      let names :=
        psRustTypeParameterNames parameters;
      psRustConcat4
        "<"
        (psRustJoin ", " names)
        ">"
        ""

def psRustEmitStructureFieldList
    (fields : List PsVerifiedIrStructureField) :
    Except PsRustEmitError (List String) :=
  match fields with
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      match psRustEmitType field.type with
      | Except.error error =>
          Except.error error
      | Except.ok printedType =>
          let rendered :=
            psRustConcat4
              "pub "
              (psRustIdentifier field.name)
              ": "
              printedType;
          match psRustEmitStructureFieldList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustEmitStructure
    (structureInfo : PsVerifiedIrStructure) :
    Except PsRustEmitError String :=
  match psRustEmitStructureFieldList structureInfo.fields with
  | Except.error error =>
      Except.error error
  | Except.ok printedFields =>
      let generic :=
        psRustGenericNames structureInfo.typeParameters;
      Except.ok
        (psRustConcat4
          "#[derive(Clone)]\npub struct "
          (psRustIdentifier structureInfo.name)
          generic
          (psRustConcat4
            " { "
            (psRustJoin ", " printedFields)
            " }"
            ""))

def psRustEmitConstructorFieldList
    (fields : List PsVerifiedIrConstructorField) :
    Except PsRustEmitError (List String) :=
  match fields with
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      match psRustEmitType field.type with
      | Except.error error =>
          Except.error error
      | Except.ok printedType =>
          let rendered :=
            psRustConcat3
              (psRustIdentifier field.name)
              ": "
              printedType;
          match psRustEmitConstructorFieldList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustEmitConstructor
    (constructorInfo : PsVerifiedIrConstructor) :
    Except PsRustEmitError String :=
  match psRustEmitConstructorFieldList constructorInfo.fields with
  | Except.error error =>
      Except.error error
  | Except.ok printedFields =>
      match printedFields with
      | List.nil =>
          Except.ok
            (psRustConcat2
              (psRustIdentifier constructorInfo.name)
              " {}")
      | List.cons _ _ =>
          Except.ok
            (psRustConcat4
              (psRustIdentifier constructorInfo.name)
              " { "
              (psRustJoin ", " printedFields)
              " }")

def psRustEmitConstructorList
    (constructors : List PsVerifiedIrConstructor) :
    Except PsRustEmitError (List String) :=
  match constructors with
  | List.nil =>
      Except.ok List.nil
  | List.cons constructorInfo rest =>
      match psRustEmitConstructor constructorInfo with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitConstructorList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons printed printedRest)

def psRustEmitInductive
    (inductiveInfo : PsVerifiedIrInductive) :
    Except PsRustEmitError String :=
  match psRustEmitConstructorList inductiveInfo.constructors with
  | Except.error error =>
      Except.error error
  | Except.ok printedConstructors =>
      let generic :=
        psRustGenericNames inductiveInfo.typeParameters;
      Except.ok
        (psRustConcat4
          "#[derive(Clone)]\npub enum "
          (psRustIdentifier inductiveInfo.name)
          generic
          (psRustConcat4
            " { "
            (psRustJoin ", " printedConstructors)
            " }"
            ""))

def psRustEmitHigherOrderParameterType
    (type : PsVerifiedIrType) :
    Except PsRustEmitError String :=
  match type with
  | PsVerifiedIrType.function parameters result =>
      match psRustEmitTypeListWith psRustEmitType parameters with
      | Except.error error =>
          Except.error error
      | Except.ok printedParameters =>
          match psRustEmitType result with
          | Except.error error =>
              Except.error error
          | Except.ok printedResult =>
              Except.ok
                (psRustConcat4
                  "impl Fn("
                  (psRustJoin ", " printedParameters)
                  ") -> "
                  printedResult)
  | _ =>
      psRustEmitType type

def psRustEmitDeclarationParameterList
    (parameters : List PsVerifiedIrParameter) :
    Except PsRustEmitError (List String) :=
  match parameters with
  | List.nil =>
      Except.ok List.nil
  | List.cons parameter rest =>
      match psRustEmitHigherOrderParameterType parameter.type with
      | Except.error error =>
          Except.error error
      | Except.ok printedType =>
          let rendered :=
            psRustConcat3
              (psRustIdentifier parameter.name)
              ": "
              printedType;
          match psRustEmitDeclarationParameterList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustDeclarationIsGenericValue
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  match declaration.parameters with
  | List.nil =>
      match declaration.typeParameters with
      | List.nil => false
      | List.cons _ _ => true
  | List.cons _ _ =>
      false

def psRustEmitDeclaration
    (valueNames : List String)
    (declaration : PsVerifiedIrDeclaration) :
    Except PsRustEmitError String :=
  if psRustDeclarationIsGenericValue declaration then
    Except.error
      (PsRustEmitError.genericValueUnsupported declaration.name)
  else
    match psRustEmitDeclarationParameterList declaration.parameters with
    | Except.error error =>
        Except.error error
    | Except.ok printedParameters =>
        match psRustEmitType declaration.resultType with
        | Except.error error =>
            Except.error error
        | Except.ok printedResult =>
            let locals :=
              psRustAddParameterNames
                declaration.parameters
                List.nil;
            match
                psRustRewriteValueRefs
                  valueNames
                  locals
                  declaration.body with
            | Except.error error =>
                Except.error error
            | Except.ok rewrittenBody =>
                match psRustEmitExpr rewrittenBody with
                | Except.error error =>
                    Except.error error
                | Except.ok printedBody =>
                    let generic :=
                      psRustGenericNames declaration.typeParameters;
                    Except.ok
                      (psRustConcat4
                        "pub fn "
                        (psRustIdentifier declaration.name)
                        generic
                        (psRustConcat4
                          "("
                          (psRustJoin ", " printedParameters)
                          ") -> "
                          (psRustConcat4
                            printedResult
                            " { "
                            printedBody
                            " }")))

def psRustEmitStructureList
    (structures : List PsVerifiedIrStructure) :
    Except PsRustEmitError (List String) :=
  match structures with
  | List.nil =>
      Except.ok List.nil
  | List.cons structureInfo rest =>
      match psRustEmitStructure structureInfo with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitStructureList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons printed printedRest)

def psRustEmitInductiveList
    (inductives : List PsVerifiedIrInductive) :
    Except PsRustEmitError (List String) :=
  match inductives with
  | List.nil =>
      Except.ok List.nil
  | List.cons inductiveInfo rest =>
      match psRustEmitInductive inductiveInfo with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitInductiveList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons printed printedRest)

def psRustValueDeclarationNames
    (declarations : List PsVerifiedIrDeclaration) :
    List String :=
  match declarations with
  | List.nil =>
      List.nil
  | List.cons declaration rest =>
      match declaration.parameters with
      | List.nil =>
          List.cons
            declaration.name
            (psRustValueDeclarationNames rest)
      | List.cons _ _ =>
          psRustValueDeclarationNames rest

def psRustEmitDeclarationList
    (valueNames : List String)
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsRustEmitError (List String) :=
  match declarations with
  | List.nil =>
      Except.ok List.nil
  | List.cons declaration rest =>
      match psRustEmitDeclaration valueNames declaration with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitDeclarationList valueNames rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons printed printedRest)

def psRustModuleHasImports
    (imports : List PsVerifiedIrExternalImport) : Bool :=
  match imports with
  | List.nil =>
      false
  | List.cons _ _ =>
      true

def psRustEmitModule
    (module : PsVerifiedIrModule) :
    Except PsRustEmitError String :=
  let valueNames :=
    psRustValueDeclarationNames module.declarations;
  if psRustModuleHasImports module.imports then
    Except.error PsRustEmitError.externalImportUnsupported
  else
    match psRustEmitStructureList module.structures with
    | Except.error error =>
        Except.error error
    | Except.ok structures =>
        match psRustEmitInductiveList module.inductives with
        | Except.error error =>
            Except.error error
        | Except.ok inductives =>
            match psRustEmitDeclarationList valueNames module.declarations with
            | Except.error error =>
                Except.error error
            | Except.ok declarations =>
                let sections :=
                  List.cons
                    psRustRuntimePrelude
                    (List.append
                      structures
                      (List.append inductives declarations));
                Except.ok
                  (psRustConcat2
                    (psRustJoin "\n" sections)
                    "\n")
