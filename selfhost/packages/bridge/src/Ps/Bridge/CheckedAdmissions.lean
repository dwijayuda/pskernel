import Ps.Bridge.Json
import Ps.Core.Declaration

inductive PsCheckedAdmissionCodecError where
  | universeMetavariable
  | freeVariable
  | expressionMetavariable
  | missingConstructor (name : PsName)
  | mismatchedConstructor (name : PsName)
  | unsupportedDeclaration

def psEncodeCodecName : PsName -> String
  | .anonymous =>
      psJsonObject [
        ("k", psJsonQuote "a")
      ]
  | .str parent value =>
      psJsonObject [
        ("k", psJsonQuote "s"),
        ("p", psEncodeCodecName parent),
        ("v", psJsonQuote value)
      ]
  | .num parent value =>
      psJsonObject [
        ("k", psJsonQuote "n"),
        ("p", psEncodeCodecName parent),
        ("v", psJsonQuote (toString value))
      ]

def psEncodeCodecLevel :
    PsLevel -> Except PsCheckedAdmissionCodecError String
  | .zero =>
      Except.ok
        (psJsonObject [
          ("k", psJsonQuote "z")
        ])
  | .succ level =>
      match psEncodeCodecLevel level with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok
            (psJsonObject [
              ("k", psJsonQuote "s"),
              ("o", encoded)
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
                  ("k", psJsonQuote "max"),
                  ("l", encodedLeft),
                  ("r", encodedRight)
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
                  ("k", psJsonQuote "imax"),
                  ("l", encodedLeft),
                  ("r", encodedRight)
                ])
  | .param name =>
      Except.ok
        (psJsonObject [
          ("k", psJsonQuote "p"),
          ("n", psEncodeCodecName name)
        ])
  | .mvar _ =>
      Except.error PsCheckedAdmissionCodecError.universeMetavariable

def psEncodeCodecBinderInfo (binder : PsBinderInfo) : String :=
  match binder with
  | .explicit => "default"
  | .implicit => "implicit"
  | .strictImplicit => "strictImplicit"
  | .instanceImplicit => "instImplicit"

def psEncodeCodecLevels
    (levels : List PsLevel) :
    Except PsCheckedAdmissionCodecError String :=
  match levels.mapM psEncodeCodecLevel with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray encoded)

def psEncodeCodecExpr :
    PsExpr -> Except PsCheckedAdmissionCodecError String
  | .bvar index =>
      Except.ok
        (psJsonObject [
          ("i", toString index),
          ("k", psJsonQuote "b")
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
              ("k", psJsonQuote "sort"),
              ("l", encodedLevel)
            ])
  | .constE name levels =>
      match psEncodeCodecLevels levels with
      | Except.error error => Except.error error
      | Except.ok encodedLevels =>
          Except.ok
            (psJsonObject [
              ("k", psJsonQuote "const"),
              ("ls", encodedLevels),
              ("n", psEncodeCodecName name)
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
                  ("a", encodedArg),
                  ("f", encodedFn),
                  ("k", psJsonQuote "app")
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
                  ("b", encodedBody),
                  ("bi", psJsonQuote (psEncodeCodecBinderInfo binder)),
                  ("k", psJsonQuote "lam"),
                  ("n", psEncodeCodecName name),
                  ("t", encodedType)
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
                  ("b", encodedBody),
                  ("bi", psJsonQuote (psEncodeCodecBinderInfo binder)),
                  ("k", psJsonQuote "forall"),
                  ("n", psEncodeCodecName name),
                  ("t", encodedType)
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
                      ("b", encodedBody),
                      ("k", psJsonQuote "let"),
                      ("n", psEncodeCodecName name),
                      ("t", encodedType),
                      ("v", encodedValue)
                    ])
  | .lit literal =>
      match literal with
      | .natural value =>
          Except.ok
            (psJsonObject [
              ("k", psJsonQuote "nat"),
              ("v", psJsonQuote (toString value))
            ])
      | .string value =>
          Except.ok
            (psJsonObject [
              ("k", psJsonQuote "str"),
              ("v", psJsonQuote value)
            ])
  | .proj typeName index value =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          Except.ok
            (psJsonObject [
              ("e", encodedValue),
              ("i", toString index),
              ("k", psJsonQuote "proj"),
              ("n", psEncodeCodecName typeName)
            ])

def psEncodeCodecNameList (names : List PsName) : String :=
  psJsonArray (names.map psEncodeCodecName)

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
      if !psNameEq info.inductiveName inductiveName then
        Except.error
          (PsCheckedAdmissionCodecError.mismatchedConstructor constructorName)
      else
        match psEncodeCodecExpr info.type with
        | Except.error error => Except.error error
        | Except.ok encodedType =>
            Except.ok
              (psJsonObject [
                ("n", psEncodeCodecName info.name),
                ("t", encodedType)
              ])

def psEncodeCodecInductive
    (allDeclarations : List PsDeclaration)
    (info : PsInductiveInfo) :
    Except PsCheckedAdmissionCodecError String :=
  match info.constructors.mapM
      (psEncodeCodecConstructor allDeclarations info.name) with
  | Except.error error => Except.error error
  | Except.ok encodedConstructors =>
      match psEncodeCodecExpr info.type with
      | Except.error error => Except.error error
      | Except.ok encodedType =>
          let encodedTypeEntry :=
            psJsonObject [
              ("cs", psJsonArray encodedConstructors),
              ("n", psEncodeCodecName info.name),
              ("t", encodedType)
            ]
          Except.ok
            (psJsonObject [
              ("lp", psEncodeCodecNameList info.levelParams),
              ("np", toString info.numParams),
              ("ts", psJsonArray [encodedTypeEntry])
            ])

def psBridgeFindRegularHeight :
    List (PsName × Nat) -> PsName -> Nat
  | [], _ => 0
  | entry :: rest, name =>
      if psNameEq entry.1 name then
        entry.2
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
              ("h", psJsonQuote (toString height)),
              ("k", psJsonQuote "regular")
            ]
          Except.ok
            (psJsonObject [
              ("h", hints),
              ("k", psJsonQuote "definition"),
              ("lp", psEncodeCodecNameList levelParams),
              ("n", psEncodeCodecName name),
              ("s", psJsonQuote "safe"),
              ("t", encodedType),
              ("v", encodedValue)
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
              ("k", psJsonQuote "theorem"),
              ("lp", psEncodeCodecNameList levelParams),
              ("n", psEncodeCodecName name),
              ("t", encodedType),
              ("v", encodedValue)
            ])

def psEncodeConstantAdmission (declaration : String) : String :=
  psJsonObject [
    ("declaration", declaration),
    ("kind", psJsonQuote "constant")
  ]

def psEncodeInductiveAdmission (declaration : String) : String :=
  psJsonObject [
    ("declaration", declaration),
    ("kind", psJsonQuote "inductive")
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
            psBridgeExprMaxRegularHeight state.heights value + 1
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
          ("admissions", psJsonArray state.admissionsRev.reverse),
          ("format", psJsonQuote "proofscript-checked-admissions"),
          ("version", "2")
        ])

def psEncodeCheckedAdmissionsText
    (declarations : List PsDeclaration) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCheckedAdmissionsCanonical declarations with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (encoded ++ "\n")
