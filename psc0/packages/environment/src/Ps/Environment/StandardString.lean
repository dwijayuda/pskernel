/-
Quoting rules adapted from Lean 4 Init/Data/Repr.lean.
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Author: Leonardo de Moura. Apache-2.0; see psc0/THIRD_PARTY_NOTICES.md.
Modified: portable Core definitions and an input-bounded total string traversal.
-/
import Ps.Environment.StandardNatOrder

-- The pinned quoting rules are definitions over the existing audited Unicode
-- operations. They add no string primitive or formatting axiom.
def psStandardStringIf (type condition yes no : PsExpr) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
    [psLogicLam 90 "_" (.constE psBoolName []) type, no, yes, condition]

def psStandardHexDigit (n : PsExpr) : PsExpr :=
  let code := psStandardStringIf psOrderNat
    (psOrderCall "Nat.ble" [n, .lit (.natural 9)])
    (psOrderCall "Nat.add" [n, .lit (.natural 48)])
    (psOrderCall "Nat.add" [n, .lit (.natural 87)])
  .app (.constE psStringSingletonName []) (.app (.constE psCharOfNatName []) code)

def psStandardCharQuoteCore : PsDeclaration :=
  let char := PsExpr.constE psCharName []
  let bool := PsExpr.constE psBoolName []
  let str := PsExpr.constE psStringName []
  let c := PsExpr.fvar 0
  let inString := PsExpr.fvar 1
  let n := PsExpr.app (.constE psCharToNatName []) c
  let choose := psStandardStringIf str
  let eq := fun code => psOrderCall "Nat.beq" [n, .lit (.natural code)]
  let append := fun a b => psLogicApply (.constE psStringAppendName []) [a, b]
  let hex := append (.lit (.string "\\x"))
    (append (psStandardHexDigit (psOrderCall "Nat.div" [n, .lit (.natural 16)]))
      (psStandardHexDigit (psOrderCall "Nat.mod" [n, .lit (.natural 16)])))
  let ordinary := choose (psOrderCall "Nat.ble" [n, .lit (.natural 31)]) hex
    (choose (eq 127) hex (.app (.constE psStringSingletonName []) c))
  let single := choose inString ordinary (choose (eq 39) (.lit (.string "\\'")) ordinary)
  let body := choose (eq 10) (.lit (.string "\\n"))
    (choose (eq 9) (.lit (.string "\\t"))
      (choose (eq 92) (.lit (.string "\\\\"))
        (choose (eq 34) (.lit (.string "\\\"")) single)))
  let flagType := psLogicApply (.constE psOptParamName [.succ .zero])
    [bool, .constE psBoolFalseName []]
  psOrderDecl "Char.quoteCore"
    (psLogicPi 0 "c" char (psLogicPi 1 "inString" flagType str))
    (psLogicLam 0 "c" char (psLogicLam 1 "inString" flagType body))

def psStandardCharQuote : PsDeclaration :=
  let char := PsExpr.constE psCharName []
  let str := PsExpr.constE psStringName []
  let quote := PsExpr.lit (.string "'")
  let inner := psOrderCall "Char.quoteCore" [.fvar 0, .constE psBoolFalseName []]
  let body := psLogicApply (.constE psStringAppendName [])
    [psLogicApply (.constE psStringAppendName []) [quote, inner], quote]
  psOrderDecl "Char.quote" (psLogicPi 0 "c" char str) (psLogicLam 0 "c" char body)

-- A Unicode scalar consumes at least one UTF-8 byte. Thus utf8ByteSize is a
-- derived traversal bound, independent of any compiler/search fuel limit.
-- At end-of-string, the accumulator is returned without reading another scalar.
-- The helper's Nat.rec is an ordinary total checked definition.
def psStandardStringQuoteWorkerName : PsName :=
  psNameAppendStr (psRootName "$psc0Standard") "stringQuoteWorker"

def psStandardStringQuoteWorker : PsDeclaration :=
  let nat := psOrderNat
  let str := PsExpr.constE psStringName []
  let source := PsExpr.fvar 0
  let fuel := PsExpr.fvar 1
  let position := PsExpr.fvar 2
  let accumulator := PsExpr.fvar 3
  let ih := PsExpr.fvar 5
  let arrow := psLogicPi 2 "position" nat (psLogicPi 3 "accumulator" str str)
  let bind := fun body => psLogicLam 2 "position" nat (psLogicLam 3 "accumulator" str body)
  let scalar := psLogicApply (.constE psStringGetName []) [source, position]
  let quoted := psOrderCall "Char.quoteCore" [scalar, .constE psBoolTrueName []]
  let advanced := psLogicApply (.constE psStringNextName []) [source, position]
  let accumulated := psLogicApply (.constE psStringAppendName []) [accumulator, quoted]
  let stepBody := psStandardStringIf str
    (psLogicApply (.constE psStringAtEndName []) [source, position])
    accumulator (psLogicApply ih [advanced, accumulated])
  let body := psOrderNatRec (.succ .zero) (psLogicLam 4 "n" nat arrow)
    (bind accumulator)
    (psLogicLam 4 "n" nat (psLogicLam 5 "ih" arrow (bind stepBody))) fuel
  .definitionDecl psStandardStringQuoteWorkerName []
    (psLogicPi 0 "source" str (psLogicPi 1 "fuel" nat arrow))
    (psLogicLam 0 "source" str (psLogicLam 1 "fuel" nat body))

def psStandardStringQuote : PsDeclaration :=
  let str := PsExpr.constE psStringName []
  let source := PsExpr.fvar 0
  let quote := PsExpr.lit (.string "\"")
  let inner := psLogicApply (.constE psStandardStringQuoteWorkerName [])
    [source, .app (.constE psStringUtf8ByteSizeName []) source, .lit (.natural 0), quote]
  psOrderDecl "String.quote" (psLogicPi 0 "s" str str)
    (psLogicLam 0 "s" str (psLogicApply (.constE psStringAppendName []) [inner, quote]))

def psStandardStringDeclarations : List PsDeclaration :=
  [psStandardCharQuoteCore, psStandardCharQuote,
   psOrderDecl "Char.repr" (psLogicPi 0 "c" (.constE psCharName []) (.constE psStringName []))
     (.constE (psDecisionName "Char.quote") []),
   psStandardStringQuoteWorker, psStandardStringQuote]

def psStandardStringExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardStringDeclarations.foldl psPreludeAdd environment
