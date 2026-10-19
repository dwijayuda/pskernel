/-
Core expression builders shared by Repr deriving and Standard declaration authors.
Moved unchanged from the existing collection, order, Format, and Repr owners.
Format/Repr material follows Lean 4.35.0; Microsoft Corporation, 2016 and 2018.
Apache-2.0; see psc0/THIRD_PARTY_NOTICES.md.
-/
import Ps.Environment.Decision

def psSelfHostListNilName : PsName :=
  psNameAppendStr psListName "nil"

def psSelfHostListConsName : PsName :=
  psNameAppendStr psListName "cons"

def psSelfHostListRecName : PsName :=
  psNameAppendStr psListName "rec"

def psSelfHostListOf (alpha : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  PsExpr.app
    (PsExpr.constE psListName [level])
    alpha

def psSelfHostListNilOf (alpha : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  PsExpr.app
    (PsExpr.constE psSelfHostListNilName [level])
    alpha

def psSelfHostListConsOf
    (alpha head tail : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  PsExpr.app
    (PsExpr.app
      (PsExpr.app
        (PsExpr.constE psSelfHostListConsName [level])
        alpha)
      head)
    tail

def psStandardListCall (suffix : String) (arguments : List PsExpr)
    (levels : List PsLevel := [.zero]) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr psListName suffix) levels) arguments

def psStandardStringIf (type condition yes no : PsExpr) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
    [psLogicLam 90 "_" (.constE psBoolName []) type, no, yes, condition]

def psOrderNat : PsExpr := .constE psNatName []

def psOrderCall (name : String) (args : List PsExpr) : PsExpr :=
  psLogicApply (.constE (psDecisionName name) []) args

def psFormatName : PsName := psDecisionName "Std.Format"

def psFormatType : PsExpr := .constE psFormatName []

def psFormatBehaviorName : PsName := psNameAppendStr psFormatName "FlattenBehavior"

def psFormatCall (suffix : String) (arguments : List PsExpr := []) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr psFormatName suffix) []) arguments

def psFormatBehavior (fill : Bool := false) : PsExpr :=
  .constE (psNameAppendStr psFormatBehaviorName (if fill then "fill" else "allOrNone")) []

def psFormatNat (n : Nat) : PsExpr := .lit (.natural n)

def psFormatIf (type condition yes no : PsExpr) : PsExpr :=
  psStandardStringIf type condition yes no

def psFormatInt (n : PsExpr) : PsExpr := .app (.constE psIntOfNatName []) n

def psFormatClassValue (name : String) (type method : PsExpr)
    (level : PsLevel := .zero) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr (psDecisionName name) "mk") [level]) [type, method]

def psReprText (text : String) : PsExpr :=
  psFormatCall "text" [.lit (.string text)]

def psReprAddAppParen (document precedence : PsExpr) : PsExpr :=
  psOrderCall "Repr.addAppParen" [document, precedence]
