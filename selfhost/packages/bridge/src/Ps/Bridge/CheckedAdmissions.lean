import Ps.Bridge.Json
import Ps.Core.Declaration

inductive PsCheckedAdmissionCodecError where
  | universeMetavariable
  | freeVariable
  | expressionMetavariable
  | missingConstructor (name : PsName)
  | mismatchedConstructor (name : PsName)
  | unsupportedDeclaration

def psCheckedAdmissionBoolNot (value : Bool) : Bool :=
  if value then false else true

def psCheckedAdmissionJsonField
    (key value : String) : Prod String String :=
  Prod.mk key value

def psEncodeCodecName : PsName -> String
  | .anonymous =>
      psJsonObject [
        Prod.mk "k" (psJsonQuote "a")
      ]
  | .str parent value =>
      psJsonObject [
        psCheckedAdmissionJsonField "k" (psJsonQuote "s"),
        psCheckedAdmissionJsonField "p" (psEncodeCodecName parent),
        psCheckedAdmissionJsonField "v" (psJsonQuote value)
      ]
  | .num parent value =>
      psJsonObject [
        psCheckedAdmissionJsonField "k" (psJsonQuote "n"),
        psCheckedAdmissionJsonField "p" (psEncodeCodecName parent),
        psCheckedAdmissionJsonField "v" (psJsonQuote (toString value))
      ]

def psEncodeCodecLevel :
    PsLevel -> Except PsCheckedAdmissionCodecError String
  | .zero =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "k" (psJsonQuote "z")
        ])
  | .succ level =>
      match psEncodeCodecLevel level with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "s"),
              psCheckedAdmissionJsonField "o" (encoded)
            ])
  | .max left right =>
      match psEncodeCodecLevel left with
      | Except.error error => Except.error error
      | Except.ok encodedLeft =>
          match psEncodeCodecLevel right with
          | Except.error error => Except.error error
          | Except.ok encodedRight =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "k" (psJsonQuote "max"),
                  psCheckedAdmissionJsonField "l" (encodedLeft),
                  psCheckedAdmissionJsonField "r" (encodedRight)
                ])
  | .imax left right =>
      match psEncodeCodecLevel left with
      | Except.error error => Except.error error
      | Except.ok encodedLeft =>
          match psEncodeCodecLevel right with
          | Except.error error => Except.error error
          | Except.ok encodedRight =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "k" (psJsonQuote "imax"),
                  psCheckedAdmissionJsonField "l" (encodedLeft),
                  psCheckedAdmissionJsonField "r" (encodedRight)
                ])
  | .param name =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "k" (psJsonQuote "p"),
          psCheckedAdmissionJsonField "n" (psEncodeCodecName name)
        ])
  | .mvar _ =>
      Except.error PsCheckedAdmissionCodecError.universeMetavariable

def psEncodeCodecBinderInfo (binder : PsBinderInfo) : String :=
  match binder with
  | .explicit => "default"
  | .implicit => "implicit"
  | .strictImplicit => "strictImplicit"
  | .instanceImplicit => "instImplicit"

def psEncodeCodecLevelList
    (levels : List PsLevel) :
    Except PsCheckedAdmissionCodecError (List String) :=
  match levels with
  | List.nil =>
      Except.ok List.nil
  | List.cons level rest =>
      match psEncodeCodecLevel level with
      | Except.error error =>
          Except.error error
      | Except.ok encodedHead =>
          match psEncodeCodecLevelList rest with
          | Except.error error =>
              Except.error error
          | Except.ok encodedTail =>
              Except.ok (List.cons encodedHead encodedTail)

def psEncodeCodecLevels
    (levels : List PsLevel) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCodecLevelList levels with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray encoded)

def psEncodeCodecExpr :
    PsExpr -> Except PsCheckedAdmissionCodecError String
  | .bvar index =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "i" (toString index),
          psCheckedAdmissionJsonField "k" (psJsonQuote "b")
        ])
  | .fvar _ =>
      Except.error PsCheckedAdmissionCodecError.freeVariable
  | .mvar _ =>
      Except.error PsCheckedAdmissionCodecError.expressionMetavariable
  | .sortE level =>
      match psEncodeCodecLevel level with
      | Except.error error => Except.error error
      | Except.ok encodedLevel =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "sort"),
              psCheckedAdmissionJsonField "l" (encodedLevel)
            ])
  | .constE name levels =>
      match psEncodeCodecLevels levels with
      | Except.error error => Except.error error
      | Except.ok encodedLevels =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "const"),
              psCheckedAdmissionJsonField "ls" (encodedLevels),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName name)
            ])
  | .app fn arg =>
      match psEncodeCodecExpr arg with
      | Except.error error => Except.error error
      | Except.ok encodedArg =>
          match psEncodeCodecExpr fn with
          | Except.error error => Except.error error
          | Except.ok encodedFn =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "a" (encodedArg),
                  psCheckedAdmissionJsonField "f" (encodedFn),
                  psCheckedAdmissionJsonField "k" (psJsonQuote "app")
                ])
  | .lam name type body binder =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "b" (encodedBody),
                  psCheckedAdmissionJsonField "bi" (psJsonQuote (psEncodeCodecBinderInfo binder)),
                  psCheckedAdmissionJsonField "k" (psJsonQuote "lam"),
                  psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
                  psCheckedAdmissionJsonField "t" (encodedType)
                ])
  | .forallE name type body binder =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "b" (encodedBody),
                  psCheckedAdmissionJsonField "bi" (psJsonQuote (psEncodeCodecBinderInfo binder)),
                  psCheckedAdmissionJsonField "k" (psJsonQuote "forall"),
                  psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
                  psCheckedAdmissionJsonField "t" (encodedType)
                ])
  | .letE name type value body =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              match psEncodeCodecExpr value with
              | Except.error error => Except.error error
              | Except.ok encodedValue =>
                  Except.ok
                    (psJsonObject [
                      psCheckedAdmissionJsonField "b" (encodedBody),
                      psCheckedAdmissionJsonField "k" (psJsonQuote "let"),
                      psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
                      psCheckedAdmissionJsonField "t" (encodedType),
                      psCheckedAdmissionJsonField "v" (encodedValue)
                    ])
  | .lit literal =>
      match literal with
      | .natural value =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "nat"),
              psCheckedAdmissionJsonField "v" (psJsonQuote (toString value))
            ])
      | .string value =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "str"),
              psCheckedAdmissionJsonField "v" (psJsonQuote value)
            ])
  | .proj typeName index value =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "e" (encodedValue),
              psCheckedAdmissionJsonField "i" (toString index),
              psCheckedAdmissionJsonField "k" (psJsonQuote "proj"),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName typeName)
            ])

def psEncodeCodecNames
    (names : List PsName) : List String :=
  match names with
  | List.nil =>
      List.nil
  | List.cons name rest =>
      List.cons
        (psEncodeCodecName name)
        (psEncodeCodecNames rest)

def psEncodeCodecNameList (names : List PsName) : String :=
  psJsonArray (psEncodeCodecNames names)

def psBridgeFindConstructor :
    List PsDeclaration -> PsName -> Option PsConstructorInfo
  | [], _ => none
  | declaration :: rest, name =>
      match declaration with
      | .constructorDecl info =>
          if psNameEq info.name name then
            some info
          else
            psBridgeFindConstructor rest name
      | _ =>
          psBridgeFindConstructor rest name

def psEncodeCodecConstructor
    (allDeclarations : List PsDeclaration)
    (inductiveName : PsName)
    (constructorName : PsName) :
    Except PsCheckedAdmissionCodecError String :=
  match psBridgeFindConstructor allDeclarations constructorName with
  | none =>
      Except.error
        (PsCheckedAdmissionCodecError.missingConstructor constructorName)
  | some info =>
      if psCheckedAdmissionBoolNot (psNameEq info.inductiveName inductiveName) then
        Except.error
          (PsCheckedAdmissionCodecError.mismatchedConstructor constructorName)
      else
        match psEncodeCodecExpr info.type with
        | Except.error error => Except.error error
        | Except.ok encodedType =>
            Except.ok
              (psJsonObject [
                psCheckedAdmissionJsonField "n" (psEncodeCodecName info.name),
                psCheckedAdmissionJsonField "t" (encodedType)
              ])

def psEncodeCodecConstructors
    (allDeclarations : List PsDeclaration)
    (inductiveName : PsName)
    (constructors : List PsName) :
    Except PsCheckedAdmissionCodecError (List String) :=
  match constructors with
  | List.nil =>
      Except.ok List.nil
  | List.cons constructorName rest =>
      match
          psEncodeCodecConstructor
            allDeclarations
            inductiveName
            constructorName with
      | Except.error error =>
          Except.error error
      | Except.ok encodedHead =>
          match
              psEncodeCodecConstructors
                allDeclarations
                inductiveName
                rest with
          | Except.error error =>
              Except.error error
          | Except.ok encodedTail =>
              Except.ok (List.cons encodedHead encodedTail)

def psEncodeCodecInductive
    (allDeclarations : List PsDeclaration)
    (info : PsInductiveInfo) :
    Except PsCheckedAdmissionCodecError String :=
  match
      psEncodeCodecConstructors
        allDeclarations
        info.name
        info.constructors with
  | Except.error error => Except.error error
  | Except.ok encodedConstructors =>
      match psEncodeCodecExpr info.type with
      | Except.error error => Except.error error
      | Except.ok encodedType =>
          let encodedTypeEntry :=
            psJsonObject [
              psCheckedAdmissionJsonField "cs" (psJsonArray encodedConstructors),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName info.name),
              psCheckedAdmissionJsonField "t" (encodedType)
            ];
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList info.levelParams),
              psCheckedAdmissionJsonField "np" (toString info.numParams),
              psCheckedAdmissionJsonField "ts" (psJsonArray [encodedTypeEntry])
            ])

def psBridgeFindRegularHeight :
    List (PsName × Nat) -> PsName -> Nat
  | [], _ => 0
  | entry :: rest, name =>
      if psNameEq (Prod.fst entry) name then
        Prod.snd entry
      else
        psBridgeFindRegularHeight rest name

def psBridgeNatMax (left right : Nat) : Nat :=
  if left < right then right else left

def psBridgeExprMaxRegularHeight
    (heights : List (PsName × Nat)) : PsExpr -> Nat
  | .constE name _ =>
      psBridgeFindRegularHeight heights name
  | .app fn arg =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights fn)
        (psBridgeExprMaxRegularHeight heights arg)
  | .lam _ type body _ =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights type)
        (psBridgeExprMaxRegularHeight heights body)
  | .forallE _ type body _ =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights type)
        (psBridgeExprMaxRegularHeight heights body)
  | .letE _ type value body =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights type)
        (psBridgeNatMax
          (psBridgeExprMaxRegularHeight heights value)
          (psBridgeExprMaxRegularHeight heights body))
  | .proj _ _ value =>
      psBridgeExprMaxRegularHeight heights value
  | _ => 0

def psEncodeCodecDefinition
    (name : PsName)
    (levelParams : List PsName)
    (type value : PsExpr)
    (height : Nat) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCodecExpr type with
  | Except.error error => Except.error error
  | Except.ok encodedType =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          let hints :=
            psJsonObject [
              psCheckedAdmissionJsonField "h" (psJsonQuote (toString height)),
              psCheckedAdmissionJsonField "k" (psJsonQuote "regular")
            ];
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "h" (hints),
              psCheckedAdmissionJsonField "k" (psJsonQuote "definition"),
              psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList levelParams),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
              psCheckedAdmissionJsonField "s" (psJsonQuote "safe"),
              psCheckedAdmissionJsonField "t" (encodedType),
              psCheckedAdmissionJsonField "v" (encodedValue)
            ])

def psEncodeCodecTheorem
    (name : PsName)
    (levelParams : List PsName)
    (type value : PsExpr) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCodecExpr type with
  | Except.error error => Except.error error
  | Except.ok encodedType =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "theorem"),
              psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList levelParams),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
              psCheckedAdmissionJsonField "t" (encodedType),
              psCheckedAdmissionJsonField "v" (encodedValue)
            ])

def psEncodeConstantAdmission (declaration : String) : String :=
  psJsonObject [
    psCheckedAdmissionJsonField "declaration" (declaration),
    psCheckedAdmissionJsonField "kind" (psJsonQuote "constant")
  ]

def psEncodeInductiveAdmission (declaration : String) : String :=
  psJsonObject [
    psCheckedAdmissionJsonField "declaration" (declaration),
    psCheckedAdmissionJsonField "kind" (psJsonQuote "inductive")
  ]

structure PsCheckedAdmissionEncodeState where
  heights : List (PsName × Nat)
  admissionsRev : List String

def psEncodeCheckedAdmissionsLoop
    (allDeclarations : List PsDeclaration) :
    List PsDeclaration ->
    PsCheckedAdmissionEncodeState ->
    Except PsCheckedAdmissionCodecError PsCheckedAdmissionEncodeState
  | [], state => Except.ok state
  | declaration :: rest, state =>
      match declaration with
      | .definitionDecl name levelParams type value =>
          let height :=
            psBridgeExprMaxRegularHeight state.heights value + 1;
          match
              psEncodeCodecDefinition
                name
                levelParams
                type
                value
                height with
          | Except.error error => Except.error error
          | Except.ok encoded =>
              psEncodeCheckedAdmissionsLoop
                allDeclarations
                rest
                {
                  heights := (name, height) :: state.heights
                  admissionsRev :=
                    psEncodeConstantAdmission encoded ::
                      state.admissionsRev
                }
      | .theoremDecl name levelParams type value =>
          match psEncodeCodecTheorem name levelParams type value with
          | Except.error error => Except.error error
          | Except.ok encoded =>
              psEncodeCheckedAdmissionsLoop
                allDeclarations
                rest
                {
                  heights := state.heights
                  admissionsRev :=
                    psEncodeConstantAdmission encoded ::
                      state.admissionsRev
                }
      | .inductiveDecl info =>
          match psEncodeCodecInductive allDeclarations info with
          | Except.error error => Except.error error
          | Except.ok encoded =>
              psEncodeCheckedAdmissionsLoop
                allDeclarations
                rest
                {
                  heights := state.heights
                  admissionsRev :=
                    psEncodeInductiveAdmission encoded ::
                      state.admissionsRev
                }
      | .constructorDecl _ =>
          psEncodeCheckedAdmissionsLoop allDeclarations rest state
      | .recursorDecl _ =>
          psEncodeCheckedAdmissionsLoop allDeclarations rest state
      | .axiomDecl _ _ _ =>
          Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
      | .opaqueDecl _ _ _ _ =>
          Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
      | .partialDecl _ _ _ _ =>
          Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration

def psCheckedAdmissionReverseStringsAcc
    (values : List String)
    (acc : List String) : List String :=
  match values with
  | List.nil =>
      acc
  | List.cons head tail =>
      psCheckedAdmissionReverseStringsAcc
        tail
        (List.cons head acc)

def psCheckedAdmissionReverseStrings
    (values : List String) : List String :=
  psCheckedAdmissionReverseStringsAcc values List.nil

def psEncodeCheckedAdmissionsCanonical
    (declarations : List PsDeclaration) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCheckedAdmissionsLoop
      declarations
      declarations
      {
        heights := []
        admissionsRev := []
      } with
  | Except.error error => Except.error error
  | Except.ok state =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "admissions" (psJsonArray (psCheckedAdmissionReverseStrings state.admissionsRev)),
          psCheckedAdmissionJsonField "format" (psJsonQuote "proofscript-checked-admissions"),
          psCheckedAdmissionJsonField "version" ("2")
        ])

def psEncodeCheckedAdmissionsText
    (declarations : List PsDeclaration) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCheckedAdmissionsCanonical declarations with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (encoded ++ "\n")
