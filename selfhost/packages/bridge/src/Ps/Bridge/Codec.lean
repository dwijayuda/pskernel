import Ps.Bridge.CheckedAdmissions

inductive PsCodecDecodeError where
  | fuelExhausted
  | expectedObject
  | expectedArray
  | expectedString
  | expectedNumber
  | missingField (name : String)
  | invalidNatural
  | invalidTag (tag : String)
  | invalidBinder (binder : String)

def psCodecField
    (value : PsJsonValue)
    (name : String) :
    Except PsCodecDecodeError PsJsonValue :=
  match psJsonGetField value name with
  | none =>
      Except.error (PsCodecDecodeError.missingField name)
  | some field => Except.ok field

def psCodecString
    (value : PsJsonValue) :
    Except PsCodecDecodeError String :=
  match psJsonAsString value with
  | some text => Except.ok text
  | none => Except.error PsCodecDecodeError.expectedString

def psCodecArray
    (value : PsJsonValue) :
    Except PsCodecDecodeError (List PsJsonValue) :=
  match psJsonAsArray value with
  | some values => Except.ok values
  | none => Except.error PsCodecDecodeError.expectedArray

def psCodecNaturalDigits :
    List Char -> Nat -> Option Nat
  | [], value => some value
  | char :: rest, value =>
      let code := char.val.toNat
      if code >= 48 && code <= 57 then
        psCodecNaturalDigits
          rest
          (value * 10 + (code - 48))
      else
        none

def psCodecNaturalText
    (text : String) : Option Nat :=
  match text.toList with
  | [] => none
  | '0' :: rest =>
      if rest.isEmpty then some 0 else none
  | first :: rest =>
      let code := first.val.toNat
      if code >= 49 && code <= 57 then
        psCodecNaturalDigits
          rest
          (code - 48)
      else
        none

def psCodecNat
    (value : PsJsonValue) :
    Except PsCodecDecodeError Nat :=
  match psJsonAsNumberText value with
  | none => Except.error PsCodecDecodeError.expectedNumber
  | some text =>
      match psCodecNaturalText text with
      | none => Except.error PsCodecDecodeError.invalidNatural
      | some natural => Except.ok natural

def psDecodeCodecNameWithFuel :
    Nat -> PsJsonValue -> Except PsCodecDecodeError PsName
  | 0, _ => Except.error PsCodecDecodeError.fuelExhausted
  | fuel + 1, value =>
      match psCodecField value "k" with
      | Except.error error => Except.error error
      | Except.ok tagValue =>
          match psCodecString tagValue with
          | Except.error error => Except.error error
          | Except.ok tag =>
              if tag == "a" then
                Except.ok PsName.anonymous
              else if tag == "s" then
                match
                    psCodecField value "p",
                    psCodecField value "v" with
                | Except.ok parentValue, Except.ok textValue =>
                    match
                        psDecodeCodecNameWithFuel fuel parentValue,
                        psCodecString textValue with
                    | Except.ok parent, Except.ok text =>
                        Except.ok (psNameAppendStr parent text)
                    | Except.error error, _ => Except.error error
                    | _, Except.error error => Except.error error
                | Except.error error, _ => Except.error error
                | _, Except.error error => Except.error error
              else if tag == "n" then
                match
                    psCodecField value "p",
                    psCodecField value "v" with
                | Except.ok parentValue, Except.ok textValue =>
                    match
                        psDecodeCodecNameWithFuel fuel parentValue,
                        psCodecString textValue with
                    | Except.ok parent, Except.ok text =>
                        match psCodecNaturalText text with
                        | none =>
                            Except.error
                              PsCodecDecodeError.invalidNatural
                        | some number =>
                            Except.ok (psNameAppendNum parent number)
                    | Except.error error, _ => Except.error error
                    | _, Except.error error => Except.error error
                | Except.error error, _ => Except.error error
                | _, Except.error error => Except.error error
              else
                Except.error (PsCodecDecodeError.invalidTag tag)

def psDecodeCodecName
    (value : PsJsonValue) :
    Except PsCodecDecodeError PsName :=
  psDecodeCodecNameWithFuel 4096 value

def psDecodeCodecLevelWithFuel :
    Nat -> PsJsonValue -> Except PsCodecDecodeError PsLevel
  | 0, _ => Except.error PsCodecDecodeError.fuelExhausted
  | fuel + 1, value =>
      match psCodecField value "k" with
      | Except.error error => Except.error error
      | Except.ok tagValue =>
          match psCodecString tagValue with
          | Except.error error => Except.error error
          | Except.ok tag =>
              if tag == "z" then
                Except.ok PsLevel.zero
              else if tag == "s" then
                match psCodecField value "o" with
                | Except.error error => Except.error error
                | Except.ok inner =>
                    match psDecodeCodecLevelWithFuel fuel inner with
                    | Except.error error => Except.error error
                    | Except.ok level =>
                        Except.ok (PsLevel.succ level)
              else if tag == "max" || tag == "imax" then
                match
                    psCodecField value "l",
                    psCodecField value "r" with
                | Except.ok leftValue, Except.ok rightValue =>
                    match
                        psDecodeCodecLevelWithFuel fuel leftValue,
                        psDecodeCodecLevelWithFuel fuel rightValue with
                    | Except.ok left, Except.ok right =>
                        if tag == "max" then
                          Except.ok (PsLevel.max left right)
                        else
                          Except.ok (PsLevel.imax left right)
                    | Except.error error, _ => Except.error error
                    | _, Except.error error => Except.error error
                | Except.error error, _ => Except.error error
                | _, Except.error error => Except.error error
              else if tag == "p" then
                match psCodecField value "n" with
                | Except.error error => Except.error error
                | Except.ok nameValue =>
                    match
                        psDecodeCodecNameWithFuel
                          fuel
                          nameValue with
                    | Except.error error => Except.error error
                    | Except.ok name =>
                        Except.ok (PsLevel.param name)
              else
                Except.error (PsCodecDecodeError.invalidTag tag)

def psDecodeCodecLevel
    (value : PsJsonValue) :
    Except PsCodecDecodeError PsLevel :=
  psDecodeCodecLevelWithFuel 4096 value

def psDecodeCodecBinder
    (value : PsJsonValue) :
    Except PsCodecDecodeError PsBinderInfo :=
  match psCodecString value with
  | Except.error error => Except.error error
  | Except.ok binder =>
      if binder == "default" then
        Except.ok PsBinderInfo.explicit
      else if binder == "implicit" then
        Except.ok PsBinderInfo.implicit
      else if binder == "strictImplicit" then
        Except.ok PsBinderInfo.strictImplicit
      else if binder == "instImplicit" then
        Except.ok PsBinderInfo.instanceImplicit
      else
        Except.error (PsCodecDecodeError.invalidBinder binder)

def psDecodeCodecLevelsWithFuel
    (fuel : Nat)
    (values : List PsJsonValue) :
    Except PsCodecDecodeError (List PsLevel) :=
  match
      values.mapM
        (psDecodeCodecLevelWithFuel fuel) with
  | Except.error error => Except.error error
  | Except.ok levels => Except.ok levels

def psDecodeCodecExprWithFuel :
    Nat -> PsJsonValue -> Except PsCodecDecodeError PsExpr
  | 0, _ => Except.error PsCodecDecodeError.fuelExhausted
  | fuel + 1, value =>
      match psCodecField value "k" with
      | Except.error error => Except.error error
      | Except.ok tagValue =>
          match psCodecString tagValue with
          | Except.error error => Except.error error
          | Except.ok tag =>
              if tag == "b" then
                match psCodecField value "i" with
                | Except.error error => Except.error error
                | Except.ok indexValue =>
                    match psCodecNat indexValue with
                    | Except.error error => Except.error error
                    | Except.ok index =>
                        Except.ok (PsExpr.bvar index)
              else if tag == "sort" then
                match psCodecField value "l" with
                | Except.error error => Except.error error
                | Except.ok levelValue =>
                    match
                        psDecodeCodecLevelWithFuel
                          fuel
                          levelValue with
                    | Except.error error => Except.error error
                    | Except.ok level =>
                        Except.ok (PsExpr.sortE level)
              else if tag == "const" then
                match
                    psCodecField value "n",
                    psCodecField value "ls" with
                | Except.ok nameValue, Except.ok levelsValue =>
                    match
                        psDecodeCodecNameWithFuel fuel nameValue,
                        psCodecArray levelsValue with
                    | Except.ok name, Except.ok rawLevels =>
                        match
                            psDecodeCodecLevelsWithFuel
                              fuel
                              rawLevels with
                        | Except.error error => Except.error error
                        | Except.ok levels =>
                            Except.ok (PsExpr.constE name levels)
                    | Except.error error, _ => Except.error error
                    | _, Except.error error => Except.error error
                | Except.error error, _ => Except.error error
                | _, Except.error error => Except.error error
              else if tag == "app" then
                match
                    psCodecField value "f",
                    psCodecField value "a" with
                | Except.ok fnValue, Except.ok argValue =>
                    match
                        psDecodeCodecExprWithFuel fuel fnValue,
                        psDecodeCodecExprWithFuel fuel argValue with
                    | Except.ok fn, Except.ok arg =>
                        Except.ok (PsExpr.app fn arg)
                    | Except.error error, _ => Except.error error
                    | _, Except.error error => Except.error error
                | Except.error error, _ => Except.error error
                | _, Except.error error => Except.error error
              else if tag == "lam" || tag == "forall" then
                match
                    psCodecField value "n",
                    psCodecField value "t",
                    psCodecField value "b",
                    psCodecField value "bi" with
                | Except.ok nameValue,
                  Except.ok typeValue,
                  Except.ok bodyValue,
                  Except.ok binderValue =>
                    match
                        psDecodeCodecNameWithFuel fuel nameValue,
                        psDecodeCodecExprWithFuel fuel typeValue,
                        psDecodeCodecExprWithFuel fuel bodyValue,
                        psDecodeCodecBinder binderValue with
                    | Except.ok name,
                      Except.ok type,
                      Except.ok body,
                      Except.ok binder =>
                        if tag == "lam" then
                          Except.ok
                            (PsExpr.lam name type body binder)
                        else
                          Except.ok
                            (PsExpr.forallE name type body binder)
                    | Except.error error, _, _, _ =>
                        Except.error error
                    | _, Except.error error, _, _ =>
                        Except.error error
                    | _, _, Except.error error, _ =>
                        Except.error error
                    | _, _, _, Except.error error =>
                        Except.error error
                | Except.error error, _, _, _ => Except.error error
                | _, Except.error error, _, _ => Except.error error
                | _, _, Except.error error, _ => Except.error error
                | _, _, _, Except.error error => Except.error error
              else if tag == "let" then
                match
                    psCodecField value "n",
                    psCodecField value "t",
                    psCodecField value "v",
                    psCodecField value "b" with
                | Except.ok nameValue,
                  Except.ok typeValue,
                  Except.ok bodyValue,
                  Except.ok valueValue =>
                    match
                        psDecodeCodecNameWithFuel fuel nameValue,
                        psDecodeCodecExprWithFuel fuel typeValue,
                        psDecodeCodecExprWithFuel fuel bodyValue,
                        psDecodeCodecExprWithFuel fuel valueValue with
                    | Except.ok name,
                      Except.ok type,
                      Except.ok body,
                      Except.ok boundValue =>
                        Except.ok
                          (PsExpr.letE
                            name
                            type
                            body
                            boundValue)
                    | Except.error error, _, _, _ =>
                        Except.error error
                    | _, Except.error error, _, _ =>
                        Except.error error
                    | _, _, Except.error error, _ =>
                        Except.error error
                    | _, _, _, Except.error error =>
                        Except.error error
                | Except.error error, _, _, _ => Except.error error
                | _, Except.error error, _, _ => Except.error error
                | _, _, Except.error error, _ => Except.error error
                | _, _, _, Except.error error => Except.error error
              else if tag == "nat" || tag == "str" then
                match psCodecField value "v" with
                | Except.error error => Except.error error
                | Except.ok literalValue =>
                    match psCodecString literalValue with
                    | Except.error error => Except.error error
                    | Except.ok text =>
                        if tag == "str" then
                          Except.ok
                            (PsExpr.lit
                              (PsLiteral.string text))
                        else
                          match psCodecNaturalText text with
                          | none =>
                              Except.error
                                PsCodecDecodeError.invalidNatural
                          | some natural =>
                              Except.ok
                                (PsExpr.lit
                                  (PsLiteral.natural natural))
              else if tag == "proj" then
                match
                    psCodecField value "n",
                    psCodecField value "i",
                    psCodecField value "e" with
                | Except.ok nameValue,
                  Except.ok indexValue,
                  Except.ok exprValue =>
                    match
                        psDecodeCodecNameWithFuel fuel nameValue,
                        psCodecNat indexValue,
                        psDecodeCodecExprWithFuel fuel exprValue with
                    | Except.ok name,
                      Except.ok index,
                      Except.ok expr =>
                        Except.ok (PsExpr.proj name index expr)
                    | Except.error error, _, _ => Except.error error
                    | _, Except.error error, _ => Except.error error
                    | _, _, Except.error error => Except.error error
                | Except.error error, _, _ => Except.error error
                | _, Except.error error, _ => Except.error error
                | _, _, Except.error error => Except.error error
              else
                Except.error (PsCodecDecodeError.invalidTag tag)

def psDecodeCodecExpr
    (value : PsJsonValue) :
    Except PsCodecDecodeError PsExpr :=
  psDecodeCodecExprWithFuel 4096 value
