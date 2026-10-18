/-
Formatting classes adapted from Lean 4.35.0 Init/Data/Format/Basic.lean.
Copyright (c) Microsoft Corporation. Apache-2.0; see THIRD_PARTY_NOTICES.md.
Modified: ordinary portable Core declarations and shared dictionary registration.
-/
import Ps.Environment.StandardFormat
import Ps.Environment.StandardClass

-- One-field Type-universe class. alpha is local 0, dictionary local 1;
-- method builders own their remaining locals. No host elaborator is imported.
def psStandardMethodClass (name : PsName) (method : String)
    (methodType : PsExpr) : List PsDeclaration :=
  let u := psRootName "u"
  let sort := PsExpr.sortE (.succ (.param u))
  let family := PsExpr.app (.constE name [.param u]) (.fvar 0)
  let params := fun body => psLogicPi 0 "α" sort body .implicit
  let lams := fun body => psLogicLam 0 "α" sort body .implicit
  let ctor := psNameAppendStr name "mk"
  [ .inductiveDecl (.mk name [u] (psLogicPi 0 "α" sort sort) 1 0 [ctor] true),
    .constructorDecl (.mk ctor [u] (params (psLogicPi 2 method methodType family))
      name 0 1 1 []),
    .definitionDecl (psNameAppendStr name method) [u]
      (params (psLogicPi 1 "self" family methodType .instanceImplicit))
      (lams (psLogicLam 1 "self" family (.proj name 0 (.fvar 1)) .instanceImplicit)) ]

def psFormatClassType (name : String) (type : PsExpr) (level : PsLevel := .zero) : PsExpr :=
  .app (.constE (psDecisionName name) [level]) type

def psFormatClassValue (name : String) (type method : PsExpr)
    (level : PsLevel := .zero) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr (psDecisionName name) "mk") [level]) [type, method]

def psFormatClassMethod (name method : String) (type dictionary : PsExpr)
    (level : PsLevel := .zero) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr (psDecisionName name) method) [level]) [type, dictionary]

def psToFormatName : PsName := psDecisionName "Std.ToFormat"

def psToFormatClassDeclarations : List PsDeclaration :=
  psStandardMethodClass psToFormatName "format"
    (psLogicPi 3 "value" (.fvar 0) psFormatType)

def psFormatGroundInstance (className suffix : String) (type method : PsExpr) : PsDeclaration :=
  .definitionDecl (psDecisionName ("PsStandard.inst" ++ suffix)) []
    (psFormatClassType className type) (psFormatClassValue className type method)

def psToFormatGroundInstances : List PsDeclaration :=
  let str := PsExpr.constE psStringName []
  [ psFormatGroundInstance "Std.ToFormat" "ToFormatFormat" psFormatType
      (psLogicLam 0 "value" psFormatType (.fvar 0)),
    psFormatGroundInstance "Std.ToFormat" "ToFormatString" str
      (.constE (psNameAppendStr psFormatName "text") []) ]

-- Generic fallback is lower-priority than structural and identity formatting.
def psToFormatFallback : PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  let dictionary := psFormatClassType "ToString" alpha level
  let result := psFormatClassType "Std.ToFormat" alpha level
  let printer := psFormatClassMethod "ToString" "toString" alpha (.fvar 1) level
  let method := psLogicLam 2 "value" alpha (psFormatCall "text" [.app printer (.fvar 2)])
  .definitionDecl (psDecisionName "PsStandard.instToFormatOfToString") [u]
    (psLogicPi 0 "α" (.sortE (.succ level))
      (psLogicPi 1 "self" dictionary result .instanceImplicit) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ level))
      (psLogicLam 1 "self" dictionary
        (psFormatClassValue "Std.ToFormat" alpha method level) .instanceImplicit) .implicit)
