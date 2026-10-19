/-
Repr follows Lean 4.35.0 Init/Data/Repr.lean and Init/Data/Int/Repr.lean.
Copyright (c) 2016 Microsoft Corporation. Author: Leonardo de Moura.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Modified: checked Core construction, ordinary shared runtime erasure.
-/
import Ps.Environment.StandardToFormat
import Ps.Environment.ReprExpr

def psReprMethodType (type : PsExpr) : PsExpr :=
  psLogicPi 2 "value" type (psLogicPi 3 "prec" psOrderNat psFormatType)

def psReprClassDeclarations : List PsDeclaration :=
  let name := psRootName "ReprAtom"
  let ctor := psNameAppendStr name "mk"
  let u := psRootName "u"
  let sort := PsExpr.sortE (.succ (.param u))
  let family := psFormatClassType "ReprAtom" (.fvar 0) (.param u)
  psStandardMethodClass (psRootName "Repr") "reprPrec" (psReprMethodType (.fvar 0)) ++
  [ .inductiveDecl (.mk name [u] (psLogicPi 0 "α" sort psPreludeTypeType) 1 0 [ctor] true),
    .constructorDecl (.mk ctor [u] (psLogicPi 0 "α" sort family .implicit)
      name 0 1 0 []) ]

def psReprPrec (type dictionary value precedence : PsExpr)
    (level : PsLevel := .zero) : PsExpr :=
  psLogicApply (psFormatClassMethod "Repr" "reprPrec" type dictionary level) [value, precedence]

def psReprApiDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  let dictionary := psFormatClassType "Repr" alpha level
  let api := fun (name : String) (precedence : Nat) (stringResult : Bool) =>
    let result := if stringResult then PsExpr.constE psStringName [] else psFormatType
    let rendered := psReprPrec alpha (.fvar 1) (.fvar 2) (psFormatNat precedence) level
    let body := if stringResult then psFormatCall "pretty"
        [rendered, psFormatNat 120, psFormatNat 0, psFormatNat 0] else rendered
    PsDeclaration.definitionDecl (psRootName name) [u]
      (psLogicPi 0 "α" (.sortE (.succ level))
        (psLogicPi 1 "self" dictionary (psLogicPi 2 "value" alpha result) .instanceImplicit) .implicit)
      (psLogicLam 0 "α" (.sortE (.succ level))
        (psLogicLam 1 "self" dictionary (psLogicLam 2 "value" alpha body) .instanceImplicit) .implicit)
  [ api "repr" 0 false, api "reprArg" 1024 false, api "reprStr" 0 true,
    psFormatDefinition "Repr.addAppParen"
      [{ name := "f", type := psFormatType }, { name := "prec", type := psOrderNat }] psFormatType
      (psFormatIf psFormatType (psOrderCall "Nat.ble" [psFormatNat 1024, .fvar 1])
        (psFormatCall "paren" [.fvar 0]) (.fvar 0)) ]

-- Public scalar methods and their dictionaries share one checked body.
def psReprScalarMethods : List PsDeclaration :=
  let bool := PsExpr.constE psBoolName []
  let str := PsExpr.constE psStringName []
  [ psFormatDefinition "Bool.repr"
      [{ name := "value", type := bool }, { name := "prec", type := psOrderNat }]
      psFormatType (psFormatIf psFormatType (.fvar 0) (psReprText "true") (psReprText "false")),
    psFormatDefinition "Nat.repr" [{ name := "value", type := psOrderNat }] str
      (.app (.constE psIntReprName []) (psFormatInt (.fvar 0))) ]

def psReprGroundInstances : List PsDeclaration :=
  let printer := fun (type body : PsExpr) =>
    psLogicLam 0 "value" type (psLogicLam 1 "prec" psOrderNat body)
  let ground := fun suffix type body => psFormatGroundInstance "Repr" ("Repr" ++ suffix)
    type (printer type body)
  let nat := psOrderNat
  let int := PsExpr.constE psIntName []
  let bool := PsExpr.constE psBoolName []
  let str := PsExpr.constE psStringName []
  let char := PsExpr.constE psCharName []
  let empty := PsExpr.constE (psRootName "Empty") []
  let intText := psFormatCall "text" [.app (.constE psIntReprName []) (.fvar 0)]
  let negative := psFormatPositive (.app (.constE psIntNegName []) (.fvar 0))
  let emptyBody := psLogicApply (.constE (psDecisionName "Empty.rec") [.succ .zero])
    [psLogicLam 2 "_" empty psFormatType, .fvar 0]
  [ ground "Bool" bool (psOrderCall "Bool.repr" [.fvar 0, .fvar 1]),
    ground "Unit" (.constE psUnitName []) (psReprText "()"),
    ground "Nat" nat (psFormatCall "text"
      [psOrderCall "Nat.repr" [.fvar 0]]),
    ground "Int" int (psFormatIf psFormatType negative
      (psReprAddAppParen intText (.fvar 1)) intText),
    ground "String" str (psFormatCall "text" [psOrderCall "String.quote" [.fvar 0]]),
    ground "Char" char (psFormatCall "text" [psOrderCall "Char.quote" [.fvar 0]]),
    ground "Empty" empty emptyBody ]

def psReprAtomInstances : List PsDeclaration :=
  ["Bool", "Nat", "Int", "Char", "String"].map fun suffix =>
    let type := PsExpr.constE (psRootName suffix) []
    PsDeclaration.definitionDecl (psDecisionName ("PsStandard.instReprAtom" ++ suffix)) []
      (psFormatClassType "ReprAtom" type)
      (.app (.constE (psDecisionName "ReprAtom.mk") [.zero]) type)

def psReprOptionMethod (level : PsLevel) : PsExpr :=
  let alpha := PsExpr.fvar 0
  let option := psSelfHostOptionOf alpha level
  let result := psLogicPi 3 "prec" psOrderNat psFormatType
  let someBody := psReprAddAppParen (psFormatCall "append"
    [psReprText "some ", psReprPrec alpha (.fvar 1) (.fvar 4) (psFormatNat 1024) level]) (.fvar 3)
  let body := psLogicApply (.constE psSelfHostOptionRecName [.succ .zero, level])
    [alpha, psLogicLam 5 "_" option result,
     psLogicLam 3 "prec" psOrderNat (psReprText "none"),
     psLogicLam 4 "value" alpha (psLogicLam 3 "prec" psOrderNat someBody), .fvar 2]
  psLogicLam 2 "value" option body

def psReprListMethod (level : PsLevel) (atomic : Bool) : PsExpr :=
  let alpha := PsExpr.fvar 0
  let list := psSelfHostListOf alpha level
  let printer := psLogicLam 8 "value" alpha
    (psReprPrec alpha (.fvar 1) (.fvar 8) (psFormatNat 0) level)
  let toFormat := psFormatClassValue "Std.ToFormat" alpha printer level
  let separator := psFormatCall "append" [psReprText ",", psFormatCall "line"]
  let joined := psLogicApply (.constE (psDecisionName "Std.Format.joinSep") [level])
    [alpha, toFormat, .fvar 2, separator]
  let document := psFormatCall (if atomic then "bracketFill" else "bracket")
    [.lit (.string "["), joined, .lit (.string "]")]
  let body := psLogicApply (psStandardListRecursor level)
    [alpha, psLogicLam 7 "_" list psFormatType, psReprText "[]",
     psLogicLam 4 "head" alpha (psLogicLam 5 "tail" list
       (psLogicLam 6 "unused" psFormatType document)), .fvar 2]
  psLogicLam 2 "xs" list (psLogicLam 3 "prec" psOrderNat body)

-- Atomic List rendering has an additional marker dictionary. Keep the
-- binder in the public method and instance even though its value is erased.
def psReprAtomicTelescope (body : PsExpr) (level : PsLevel) (lambda : Bool) : PsExpr :=
  let repr := psFormatClassType "Repr" (.fvar 0) level
  let atom := psFormatClassType "ReprAtom" (.fvar 0) level
  let bind := fun id name type body binder =>
    if lambda then psLogicLam id name type body binder else psLogicPi id name type body binder
  bind 0 "α" (.sortE (.succ level))
    (bind 1 "self" repr (bind 9 "atomic" atom body .instanceImplicit) .instanceImplicit) .implicit

def psReprPublicMethods : List PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let list := psSelfHostListOf (.fvar 0) level
  let methodType := fun type => psLogicPi 2 "value" type
    (psLogicPi 3 "prec" psOrderNat psFormatType)
  [ psFormatContainerMethodDeclaration "Option.repr" "Repr"
      (methodType (psSelfHostOptionOf (.fvar 0) level)) (psReprOptionMethod level) level [u],
    psFormatContainerMethodDeclaration "List.repr" "Repr"
      (methodType list) (psReprListMethod level false) level [u],
    .definitionDecl (psDecisionName "List.repr'") [u]
      (psReprAtomicTelescope (methodType list) level false)
      (psReprAtomicTelescope (psReprListMethod level true) level true) ]

def psReprContainerInstances : List PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  let list := psSelfHostListOf alpha level
  let method := fun name arguments =>
    psLogicApply (.constE (psDecisionName name) [level]) arguments
  let ordinary := psFormatContainerDeclaration "PsStandard.instReprList" "Repr" list
    (method "List.repr" [alpha, .fvar 1]) level [u]
  let atomic := PsDeclaration.definitionDecl (psDecisionName "PsStandard.instReprListAtom") [u]
    (psReprAtomicTelescope (psFormatClassType "Repr" list level) level false)
    (psReprAtomicTelescope
      (psFormatClassValue "Repr" list (method "List.repr'" [alpha, .fvar 1, .fvar 9]) level) level true)
  [ psFormatContainerDeclaration "PsStandard.instReprOption" "Repr"
      (psSelfHostOptionOf alpha level) (method "Option.repr" [alpha, .fvar 1]) level [u],
    ordinary, atomic ]

-- Upstream Decidable is a Bool with checked reflection evidence. Display
-- inspects that same Bool and never eliminates proof evidence into runtime data.
def psReprDecidableDeclarations : List PsDeclaration :=
  let prop := PsExpr.sortE .zero
  let decision := psDecisionType (.fvar 0)
  let methodType := psLogicPi 1 "value" decision (psLogicPi 2 "prec" psOrderNat psFormatType)
  let body := psReprAddAppParen
    (psFormatIf psFormatType (.proj psDecidableName 0 (.fvar 1))
      (psReprText "isTrue _") (psReprText "isFalse _")) (.fvar 2)
  [ .definitionDecl (psDecisionName "Decidable.repr") []
      (psLogicPi 0 "p" prop methodType .implicit)
      (psLogicLam 0 "p" prop
        (psLogicLam 1 "value" decision (psLogicLam 2 "prec" psOrderNat body)) .implicit),
    .definitionDecl (psDecisionName "PsStandard.instReprDecidable") []
      (psLogicPi 0 "p" prop (psFormatClassType "Repr" decision) .implicit)
      (psLogicLam 0 "p" prop (psFormatClassValue "Repr" decision
        (psOrderCall "Decidable.repr" [.fvar 0])) .implicit) ]

def psStandardReprDeclarations : List PsDeclaration :=
  psReprClassDeclarations ++ psReprApiDeclarations ++ psReprScalarMethods ++ psReprGroundInstances ++
    psReprAtomInstances ++ psReprPublicMethods ++ psReprContainerInstances ++ psReprDecidableDeclarations

def psStandardReprExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardReprDeclarations.foldl psPreludeAdd environment
  let environment := psStandardRegisterClass (psStandardRegisterClass environment "Repr") "ReprAtom"
  let environment := psStandardRegisterInstances environment "Repr" (psReprGroundInstances ++ psReprContainerInstances ++
      psReprDecidableDeclarations.filter (fun d =>
        psNameLastComponent (psDeclarationName d) == "instReprDecidable"))
  let environment := psStandardRegisterInstances environment "ReprAtom" psReprAtomInstances
  { environment with exportedAliases :=
      (psRootName "reprPrec", psDecisionName "Repr.reprPrec") :: environment.exportedAliases }
