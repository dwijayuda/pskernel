import Ps.BackendTs.Expr

structure PsTsFreshNameResult where
  name : String
  nextIndex : Nat

def psTsFreshInternalWithFuel
    (used : List String)
    (namePrefix : String) :
    Nat -> Nat -> PsTsFreshNameResult
  | index, 0 =>
      {
        name := namePrefix ++ "overflow"
        nextIndex := index + 1
      }
  | index, attempts + 1 =>
      let candidate := namePrefix ++ toString index
      if used.contains candidate then
        psTsFreshInternalWithFuel
          used
          namePrefix
          (index + 1)
          attempts
      else
        {
          name := candidate
          nextIndex := index + 1
        }

def psTsFreshInternal
    (used : List String)
    (namePrefix : String)
    (index : Nat) : PsTsFreshNameResult :=
  psTsFreshInternalWithFuel used namePrefix index 4096

structure PsTsSymbolMapState where
  used : List String
  nextIndex : Nat
  entriesRev : List (String × String)

def psTsBuildSymbolMap
    (namePrefix : String) :
    List String -> PsTsSymbolMapState -> PsTsSymbolMapState
  | [], state => state
  | name :: rest, state =>
      let fresh :=
        psTsFreshInternal state.used namePrefix state.nextIndex
      psTsBuildSymbolMap
        namePrefix
        rest
        {
          used := fresh.name :: state.used
          nextIndex := fresh.nextIndex
          entriesRev := (name, fresh.name) :: state.entriesRev
        }

def psTsModuleTopLevelNames
    (module : PsVerifiedIrModule) : List String :=
  module.declarations.map (fun declaration => declaration.name)
    ++ module.structures.map (fun structure => structureInfo.name)
    ++ module.inductives.map (fun inductive => inductiveInfo.name)

def psTsBuildBrandMap
    (module : PsVerifiedIrModule) :
    List (String × String) :=
  let state :=
    psTsBuildSymbolMap
      "__ps$brand$"
      (module.structures.map (fun structure => structureInfo.name))
      {
        used := psTsModuleTopLevelNames module
        nextIndex := 0
        entriesRev := []
      }
  state.entriesRev.reverse

def psTsBuildTagMap
    (module : PsVerifiedIrModule) :
    List (String × String) :=
  let state :=
    psTsBuildSymbolMap
      "__ps$tag$"
      (module.inductives.map (fun inductive => inductiveInfo.name))
      {
        used := psTsModuleTopLevelNames module
        nextIndex := 0
        entriesRev := []
      }
  state.entriesRev.reverse

def psTsGenericNames
    (parameters : List PsVerifiedIrTypeParameter) : String :=
  if parameters.isEmpty then
    ""
  else
    "<" ++
      psTsJoin ", " (parameters.map (fun parameter => parameter.name)) ++
      ">"

def psTsEmitStructure
    (brands : List (String × String))
    (structureInfo : PsVerifiedIrStructure) :
    Except PsTsEmitError (List String) :=
  match psTsLookup brands structureInfo.name with
  | none =>
      Except.error (PsTsEmitError.unknownStructure structureInfo.name)
  | some brand =>
      let printField :=
        fun field =>
          match psTsEmitType field.type with
          | Except.error error => Except.error error
          | Except.ok type =>
              Except.ok
                ("readonly " ++ field.name ++ ": " ++ type ++ ";")
      match structureInfo.fields.mapM printField with
      | Except.error error => Except.error error
      | Except.ok fields =>
          let generic :=
            psTsGenericNames structureInfo.typeParameters
          Except.ok [
            "const " ++ brand ++ ": unique symbol = Symbol(" ++
              psJsonQuote ("ProofScript." ++ structureInfo.name) ++ ");",
            "export interface " ++ structureInfo.name ++ generic ++
              " { readonly [" ++ brand ++ "]: true; " ++
              psTsJoin " " fields ++ " }"
          ]

def psTsEmitConstructorVariant
    (tag : String)
    (constructorInfo : PsVerifiedIrConstructor) :
    Except PsTsEmitError String :=
  let printField :=
    fun field =>
      match psTsEmitType field.type with
      | Except.error error => Except.error error
      | Except.ok type =>
          Except.ok
            ("readonly " ++ field.name ++ ": " ++ type ++ ";")
  match constructorInfo.fields.mapM printField with
  | Except.error error => Except.error error
  | Except.ok fields =>
      Except.ok
        ("{ readonly [" ++ tag ++ "]: " ++
          psJsonQuote constructorInfo.name ++ "; " ++
          psTsJoin " " fields ++ " }")

def psTsEmitConstructorValue
    (tag : String)
    (inductiveInfo : PsVerifiedIrInductive)
    (constructorInfo : PsVerifiedIrConstructor) :
    Except PsTsEmitError String :=
  let generic := psTsGenericNames inductiveInfo.typeParameters
  let resultType := inductiveInfo.name ++ generic
  if inductiveInfo.typeParameters.isEmpty && constructorInfo.fields.isEmpty then
    Except.ok
      ("  " ++ psJsonQuote constructorInfo.name ++
        ": { [" ++ tag ++ "]: " ++
        psJsonQuote constructorInfo.name ++ " } as " ++
        resultType ++ ",")
  else
    let printParameter :=
      fun field =>
        match psTsEmitType field.type with
        | Except.error error => Except.error error
        | Except.ok type =>
            Except.ok type
    match constructorInfo.fields.mapM printParameter with
    | Except.error error => Except.error error
    | Except.ok fieldTypes =>
        let parameterNames :=
          List.range constructorInfo.fields.length
            |>.map (fun index => "__field" ++ toString index)
        let parameters :=
          parameterNames.zip fieldTypes
            |>.map
              (fun entry =>
                entry.1 ++ ": " ++ entry.2)
        let fields :=
          constructorInfo.fields.zip parameterNames
            |>.map
              (fun entry =>
                entry.1.name ++ ": " ++ entry.2)
        let suffix :=
          if fields.isEmpty then ""
          else ", " ++ psTsJoin ", " fields
        Except.ok
          ("  " ++ psJsonQuote constructorInfo.name ++ ": " ++ generic ++
            "(" ++ psTsJoin ", " parameters ++ "): " ++
            resultType ++ " => ({ [" ++ tag ++ "]: " ++
            psJsonQuote constructorInfo.name ++ suffix ++
            " } as " ++ resultType ++ "),")

def psTsEmitInductive
    (tags : List (String × String))
    (inductiveInfo : PsVerifiedIrInductive) :
    Except PsTsEmitError (List String) :=
  match psTsLookup tags inductiveInfo.name with
  | none =>
      Except.error (PsTsEmitError.unknownInductive inductiveInfo.name)
  | some tag =>
      match inductiveInfo.constructors.mapM
          (psTsEmitConstructorVariant tag) with
      | Except.error error => Except.error error
      | Except.ok variants =>
          match inductiveInfo.constructors.mapM
              (psTsEmitConstructorValue tag inductiveInfo) with
          | Except.error error => Except.error error
          | Except.ok constructorValues =>
              let generic :=
                psTsGenericNames inductiveInfo.typeParameters
              let typeLine :=
                "export type " ++ inductiveInfo.name ++ generic ++
                  " =\n  | " ++ psTsJoin "\n  | " variants ++ ";"
              Except.ok
                ([
                  "const " ++ tag ++ ": unique symbol = Symbol(" ++
                    psJsonQuote
                      ("ProofScript." ++ inductiveInfo.name ++ ".tag") ++ ");",
                  typeLine,
                  "export const " ++ inductiveInfo.name ++ " = {"
                ] ++ constructorValues ++ ["} as const;"])

def psTsEmitImport
    (item : PsVerifiedIrExternalImport) : String :=
  "import { " ++ item.importedName ++
    (if item.importedName == item.localName then
      ""
    else
      " as " ++ item.localName) ++
    " } from " ++ psJsonQuote item.source ++ ";"

def psTsEmitDeclaration
    (brands : List (String × String))
    (tags : List (String × String))
    (declaration : PsVerifiedIrDeclaration) :
    Except PsTsEmitError String :=
  let generic := psTsGenericNames declaration.typeParameters
  match psTsEmitType declaration.resultType with
  | Except.error error => Except.error error
  | Except.ok resultType =>
      match psTsEmitExpr brands tags declaration.body with
      | Except.error error => Except.error error
      | Except.ok body =>
          if declaration.parameters.isEmpty then
            if declaration.typeParameters.isEmpty then
              Except.ok
                ("export const " ++ declaration.name ++ ": " ++
                  resultType ++ " = " ++ body ++ ";")
            else
              Except.error
                (PsTsEmitError.genericValueUnsupported declaration.name)
          else
            let printParameter :=
              fun parameter =>
                match psTsEmitType parameter.type with
                | Except.error error => Except.error error
                | Except.ok type =>
                    Except.ok
                      (parameter.name ++ ": " ++ type)
            match declaration.parameters.mapM printParameter with
            | Except.error error => Except.error error
            | Except.ok parameters =>
                Except.ok
                  ("export function " ++ declaration.name ++ generic ++
                    "(" ++ psTsJoin ", " parameters ++ "): " ++
                    resultType ++ " { return " ++ body ++ "; }")

def psTsFlattenLines : List (List String) -> List String
  | [] => []
  | lines :: rest => lines ++ psTsFlattenLines rest

def psTsEmitModule
    (module : PsVerifiedIrModule) :
    Except PsTsEmitError String :=
  let brands := psTsBuildBrandMap module
  let tags := psTsBuildTagMap module
  match module.structures.mapM (psTsEmitStructure brands) with
  | Except.error error => Except.error error
  | Except.ok structures =>
      match module.inductives.mapM (psTsEmitInductive tags) with
      | Except.error error => Except.error error
      | Except.ok inductives =>
          match module.declarations.mapM
              (psTsEmitDeclaration brands tags) with
          | Except.error error => Except.error error
          | Except.ok declarations =>
              let lines :=
                ["// generated from pskernel-admitted ProofScript checked core"]
                  ++ module.imports.map psTsEmitImport
                  ++ psTsFlattenLines structures
                  ++ psTsFlattenLines inductives
                  ++ declarations
              Except.ok (psTsJoin "\n" lines ++ "\n")
