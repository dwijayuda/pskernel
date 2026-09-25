import Ps.BackendRust.Expr

def psRustTypeParameterNames
    (parameters : List PsVerifiedIrTypeParameter) : List String :=
  match parameters with
  | List.nil =>
      List.nil
  | List.cons parameter rest =>
      List.cons
        parameter.name
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
              field.name
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
          "pub struct "
          structureInfo.name
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
              field.name
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
            (psRustConcat2 constructorInfo.name " {}")
      | List.cons _ _ =>
          Except.ok
            (psRustConcat4
              constructorInfo.name
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
          "pub enum "
          inductiveInfo.name
          generic
          (psRustConcat4
            " { "
            (psRustJoin ", " printedConstructors)
            " }"
            ""))

def psRustEmitDeclarationParameterList
    (parameters : List PsVerifiedIrParameter) :
    Except PsRustEmitError (List String) :=
  match parameters with
  | List.nil =>
      Except.ok List.nil
  | List.cons parameter rest =>
      match psRustEmitType parameter.type with
      | Except.error error =>
          Except.error error
      | Except.ok printedType =>
          let rendered :=
            psRustConcat3
              parameter.name
              ": "
              printedType;
          match psRustEmitDeclarationParameterList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustEmitDeclaration
    (declaration : PsVerifiedIrDeclaration) :
    Except PsRustEmitError String :=
  match declaration.parameters with
  | List.nil =>
      Except.error
        (PsRustEmitError.valueDeclarationUnsupported declaration.name)
  | List.cons _ _ =>
      match psRustEmitDeclarationParameterList declaration.parameters with
      | Except.error error =>
          Except.error error
      | Except.ok printedParameters =>
          match psRustEmitType declaration.resultType with
          | Except.error error =>
              Except.error error
          | Except.ok printedResult =>
              match psRustEmitExpr declaration.body with
              | Except.error error =>
                  Except.error error
              | Except.ok printedBody =>
                  let generic :=
                    psRustGenericNames declaration.typeParameters;
                  Except.ok
                    (psRustConcat4
                      "pub fn "
                      declaration.name
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

def psRustEmitDeclarationList
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsRustEmitError (List String) :=
  match declarations with
  | List.nil =>
      Except.ok List.nil
  | List.cons declaration rest =>
      match psRustEmitDeclaration declaration with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitDeclarationList rest with
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

def psRustRuntimePrelude : String :=
  "#![forbid(unsafe_code)]\n" ++
  "use num_bigint::{BigInt as PsInt, BigUint as PsNat};\n" ++
  "use num_traits::Zero;\n" ++
  "use std::str::FromStr;\n" ++
  "fn __ps_nat_lit(text: &str) -> PsNat { PsNat::from_str(text).expect(\"valid generated Nat literal\") }\n" ++
  "fn __ps_int_lit(text: &str) -> PsInt { PsInt::from_str(text).expect(\"valid generated Int literal\") }\n" ++
  "fn __ps_nat_add(a: &PsNat, b: &PsNat) -> PsNat { a + b }\n" ++
  "fn __ps_nat_sub(a: &PsNat, b: &PsNat) -> PsNat { if a >= b { a - b } else { PsNat::zero() } }\n" ++
  "fn __ps_nat_mul(a: &PsNat, b: &PsNat) -> PsNat { a * b }\n" ++
  "fn __ps_nat_div(a: &PsNat, b: &PsNat) -> PsNat { if b.is_zero() { PsNat::zero() } else { a / b } }\n" ++
  "fn __ps_nat_mod(a: &PsNat, b: &PsNat) -> PsNat { if b.is_zero() { a.clone() } else { a % b } }\n" ++
  "fn __ps_int_of_nat(value: &PsNat) -> PsInt { PsInt::from(value.clone()) }\n" ++
  "fn __ps_int_neg_succ(value: &PsNat) -> PsInt { -(PsInt::from(value.clone()) + PsInt::from(1u8)) }\n" ++
  "fn __ps_int_neg(value: &PsInt) -> PsInt { -value }\n" ++
  "fn __ps_int_add(a: &PsInt, b: &PsInt) -> PsInt { a + b }\n" ++
  "fn __ps_int_sub(a: &PsInt, b: &PsInt) -> PsInt { a - b }\n" ++
  "fn __ps_int_mul(a: &PsInt, b: &PsInt) -> PsInt { a * b }\n"

def psRustEmitModule
    (module : PsVerifiedIrModule) :
    Except PsRustEmitError String :=
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
            match psRustEmitDeclarationList module.declarations with
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
