import Ps.Environment.StandardPlatformWordsData
import Ps.Environment.StandardUnsigned
import Ps.Environment.StandardSignedNumeric
import Ps.Environment.StandardHashable

/-!
Selected native abstract-width family, pinned Lean 4.35.0.
Dictionary constructions adapt Init/Prelude, UInt/Basic, SInt/Basic,
Data/Repr and ToString/Basic (Microsoft Corporation / Lean FRO, LLC,
Apache-2.0; see THIRD_PARTY_NOTICES.md). All are ordinary checked Core.
Dependency instances are not automatically registered. The execution profile
does not enter this file or specialize the logical environment.
-/
def psStandardPlatformInstances : List (String × PsDeclaration) :=
  ["USize", "ISize"].flatMap fun owner =>
    let type := PsExpr.constE (psRootName owner) []
    let signed := owner == "ISize"
    let raw := fun value => psOrderCall "USize.toNat"
      [if signed then psOrderCall "ISize.toUSize" [value] else value]
    let value := if signed then psOrderCall "ISize.toInt" [.fvar 0] else raw (.fvar 0)
    let text := if signed then psOrderCall "Int.repr" [value] else psOrderCall "Nat.repr" [value]
    let document := psFormatCall "text" [text]
    let document := if signed then psFormatIf psFormatType
        (psFormatPositive (psOrderCall "Int.neg" [value]))
        (psReprAddAppParen document (.fvar 1)) document
      else document
    let method := fun className body =>
      let name := psDecisionName ("PsStandard.inst" ++ className ++ owner)
      (className, PsDeclaration.definitionDecl name []
        (psFormatClassType className type)
        (psLogicApply (.constE (psDecisionName (className ++ ".mk")) [.zero])
          [type, body]))
    let arithmetic := [("Add", "add"), ("Sub", "sub"), ("Mul", "mul"),
      ("Div", "div"), ("Mod", "mod"), ("Neg", "neg"), ("LT", "lt"), ("LE", "le")].map
      fun (className, operation) => method className
        (.constE (psDecisionName (owner ++ "." ++ operation)) [])
    let equal := psLogicLam 0 "left" type (psLogicLam 1 "right" type
      (psOrderCall "Nat.beq" [raw (.fvar 0), raw (.fvar 1)]))
    let atom := PsDeclaration.definitionDecl
      (psDecisionName ("PsStandard.instReprAtom" ++ owner)) []
      (psFormatClassType "ReprAtom" type)
      (.app (.constE (psDecisionName "ReprAtom.mk") [.zero]) type)
    arithmetic ++ [
      ("BEq", psStandardBEqInstance owner type equal),
      ("Inhabited", psStandardInhabitedGround owner type
        (psOrderCall (owner ++ ".ofNat") [.lit (.natural 0)])),
      ("ToString", psStandardToStringInstance owner type (psLogicLam 0 "value" type text)),
      ("Repr", psFormatGroundInstance "Repr" ("Repr" ++ owner) type
        (psLogicLam 0 "value" type (psLogicLam 1 "prec" psOrderNat document))),
      ("ReprAtom", atom),
      ("Hashable", psHashGround owner type (psHashOfNat (raw (.fvar 0))))]

-- Native pow uses Nat.brecOn. Reuse the already checked Nat.rec equation
-- builder for a private executable adapter, preserving the native public
-- definition and its proof dependencies unchanged.
def psStandardPlatformPowerDeclarations : List PsDeclaration :=
  ["USize", "ISize"].map fun owner =>
    match psStandardFixedWidthPower owner with
    | .definitionDecl _ levels type value =>
        .definitionDecl (psDecisionName ("PsStandard." ++ owner ++ "Pow")) levels type value
    | declaration => declaration

def psStandardPlatformNativeInstances : List (String × PsDeclaration) :=
  psStandardPlatformWordsDeclarations.filterMap fun declaration =>
    let name := psNameToString (psDeclarationName declaration)
    let className :=
      if ["USize.instOfNat", "ISize.instOfNat"].contains name then some "OfNat"
      else if ["USize.decLt", "USize.decLe", "ISize.decLt", "ISize.decLe"].contains name then some "Decidable"
      else if ["instDecidableEqUSize", "ISize.decEq"].contains name then some "Decidable"
      else none
    className.map (fun className => (className, declaration))

def psStandardPlatformExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := (psStandardPlatformWordsDeclarations ++
    psStandardPlatformPowerDeclarations ++ psStandardPlatformInstances.map Prod.snd).foldl
      psEnvironmentInsert environment
  let environment := psStandardPlatformWordsReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
  (psStandardPlatformNativeInstances ++ psStandardPlatformInstances).foldl
    (fun env (className, declaration) =>
      psStandardRegisterInstances env className [declaration]) environment

-- Only profile-dependent executable support is conditional. The full checked
-- logical environment and source admission are identical for both profiles.
def psStandardPlatformRuntimeDeclarations : List PsDeclaration :=
  psStandardPlatformWordsDeclarations.filter (fun declaration =>
    ["Subtype", "Subtype.mk", "Subtype.rec", "USize.instOfNat", "ISize.instOfNat"].contains (psNameToString (psDeclarationName declaration))) ++
    psStandardPlatformPowerDeclarations ++ psStandardPlatformInstances.map Prod.snd

def psStandardPlatformAudit (environment : PsEnvironment) : Except String Unit := do
  if psStandardPlatformWordsDeclarations.length != 196 ||
      psStandardPlatformInstances.length != 28 ||
      psStandardPlatformNativeInstances.length != 8 then
    throw "PSCV0-STANDARD: platform-word family drift"
  for declaration in psStandardPlatformWordsDeclarations ++
      psStandardPlatformPowerDeclarations ++ psStandardPlatformInstances.map Prod.snd do
    psStandardAuditDeclaration environment declaration
  for (_, declaration) in psStandardPlatformNativeInstances ++ psStandardPlatformInstances do
    psStandardAuditInstance environment declaration
