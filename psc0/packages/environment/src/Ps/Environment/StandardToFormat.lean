/-
ToFormat combinators adapted from Lean 4.35.0 Init/Data/Format/{Basic,Instances}.lean.
Copyright (c) Microsoft Corporation. Apache-2.0; see THIRD_PARTY_NOTICES.md.
Modified: checked polymorphic recursor/fold programs; no new runtime primitives.
-/
import Ps.Environment.StandardFormatClass

-- The API is polymorphic in the element universe. List.rec inspects only the
-- first node; the existing shared List.foldl owns the remaining traversal.
def psFormatJoinDeclaration (mode : Nat) : PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  let dictionary := psFormatClassType "Std.ToFormat" alpha level
  let list := psSelfHostListOf alpha level
  let format := psFormatType
  let printer := psFormatClassMethod "Std.ToFormat" "format" alpha (.fvar 1) level
  let separator := PsExpr.fvar 3
  let append := fun a b => psFormatCall "append" [a, b]
  let first := PsExpr.app printer (.fvar 4)
  let next := PsExpr.app printer (.fvar 8)
  let initial := if mode == 1 then append separator first
    else if mode == 2 then append first separator else first
  let combine := psLogicLam 7 "acc" format (psLogicLam 8 "item" alpha
    (if mode == 2 then append (append (.fvar 7) next) separator
     else append (append (.fvar 7) separator) next))
  let rest := psStandardListCall "foldl"
    [format, alpha, combine, initial, .fvar 5] [.zero, level]
  let step := psLogicLam 4 "head" alpha
    (psLogicLam 5 "tail" list (psLogicLam 6 "unused" format rest))
  let body := psLogicApply (psStandardListRecursor level)
    [alpha, psLogicLam 9 "_" list format, psFormatCall "nil", step, .fvar 2]
  let close := fun (body : PsExpr) (lambda : Bool) =>
    let bind := fun id name type body binder =>
      if lambda then psLogicLam id name type body binder else psLogicPi id name type body binder
    bind 0 "α" (.sortE (.succ level))
      (bind 1 "self" dictionary
        (if mode == 1 then bind 3 "pre" format (bind 2 "xs" list body .explicit) .explicit
         else bind 2 "xs" list (bind 3 "sep" format body .explicit) .explicit)
        .instanceImplicit) .implicit
  .definitionDecl (psNameAppendStr psFormatName
    (if mode == 1 then "prefixJoin" else if mode == 2 then "joinSuffix" else "joinSep"))
    [u] (close format false) (close body true)

def psFormatJoinDeclarations : List PsDeclaration :=
  let format := psFormatType
  let combine := psLogicLam 1 "left" format
    (psLogicLam 2 "right" format (psFormatCall "append" [.fvar 1, .fvar 2]))
  [psFormatJoinDeclaration 0, psFormatJoinDeclaration 1, psFormatJoinDeclaration 2,
   psFormatDefinition "Std.Format.join" [{ name := "xs", type := psSelfHostListOf format }]
     format (psStandardListCall "foldl"
       [format, format, combine, psFormatCall "text" [.lit (.string "")], .fvar 0]
       [.zero, .zero])]

-- Shared telescope for a unary container whose family universe follows α.
def psFormatContainerDeclaration (name className : String)
    (container method : PsExpr) (level : PsLevel) (parameters : List PsName) : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let dictionary := psFormatClassType className alpha level
  let result := psFormatClassType className container level
  .definitionDecl (psDecisionName name) parameters
    (psLogicPi 0 "α" (.sortE (.succ level))
      (psLogicPi 1 "self" dictionary result .instanceImplicit) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ level))
      (psLogicLam 1 "self" dictionary
        (psFormatClassValue className container method level) .instanceImplicit) .implicit)

-- A public unary-container method retains the same universe and dictionary
-- telescope as the corresponding instance, so explicit calls share its body.
def psFormatContainerMethodDeclaration (name className : String)
    (result method : PsExpr) (level : PsLevel) (parameters : List PsName) : PsDeclaration :=
  let dictionary := psFormatClassType className (.fvar 0) level
  .definitionDecl (psDecisionName name) parameters
    (psLogicPi 0 "α" (.sortE (.succ level))
      (psLogicPi 1 "self" dictionary result .instanceImplicit) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ level))
      (psLogicLam 1 "self" dictionary method .instanceImplicit) .implicit)

def psToFormatListMethod (level : PsLevel) : PsExpr :=
  let alpha := PsExpr.fvar 0
  let list := psSelfHostListOf alpha level
  let separator := psFormatCall "append" [psFormatCall "text" [.lit (.string ",")], psFormatCall "line"]
  let joined := psLogicApply (.constE (psDecisionName "Std.Format.joinSep") [level])
    [alpha, .fvar 1, .fvar 2, separator]
  let body := psLogicApply (psStandardListRecursor level)
    [alpha, psLogicLam 6 "_" list psFormatType,
     psFormatCall "text" [.lit (.string "[]")],
     psLogicLam 3 "head" alpha (psLogicLam 4 "tail" list
       (psLogicLam 5 "unused" psFormatType (psFormatCall "sbracket" [joined]))), .fvar 2]
  psLogicLam 2 "xs" list body

def psToFormatOptionMethod (level : PsLevel) : PsExpr :=
  let alpha := PsExpr.fvar 0
  let option := psSelfHostOptionOf alpha level
  let printer := psFormatClassMethod "Std.ToFormat" "format" alpha (.fvar 1) level
  let body := psLogicApply (.constE psSelfHostOptionRecName [.succ .zero, level])
    [alpha, psLogicLam 4 "_" option psFormatType,
     psFormatCall "text" [.lit (.string "none")],
     psLogicLam 3 "value" alpha (psFormatCall "append"
       [psFormatCall "text" [.lit (.string "some ")], .app printer (.fvar 3)]), .fvar 2]
  psLogicLam 2 "value" option body

def psToFormatContainerDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  [ psFormatContainerDeclaration "PsStandard.instToFormatList" "Std.ToFormat"
      (psSelfHostListOf alpha level) (psLogicApply (.constE (psDecisionName "List.format") [level]) [alpha, .fvar 1]) level [u],
    psFormatContainerDeclaration "PsStandard.instToFormatOption" "Std.ToFormat"
      (psSelfHostOptionOf alpha level) (psLogicApply (.constE (psDecisionName "Option.format") [level]) [alpha, .fvar 1]) level [u] ]

def psToFormatPublicMethods : List PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  [ ("List.format", psSelfHostListOf (.fvar 0) level, psToFormatListMethod level),
    ("Option.format", psSelfHostOptionOf (.fvar 0) level, psToFormatOptionMethod level) ].map fun (name, type, method) =>
      psFormatContainerMethodDeclaration name "Std.ToFormat"
        (psLogicPi 2 "value" type psFormatType) method level [u]

def psStandardToFormatDeclarations : List PsDeclaration :=
  psToFormatClassDeclarations ++ psToFormatGroundInstances ++ [psToFormatFallback] ++
    psFormatJoinDeclarations ++ psToFormatPublicMethods ++ psToFormatContainerDeclarations

def psStandardToFormatExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardToFormatDeclarations.foldl psPreludeAdd environment
  let environment := psStandardRegisterClass environment "Std.ToFormat"
  let environment := psStandardRegisterInstances environment "Std.ToFormat" [psToFormatFallback] 100
  let environment := psStandardRegisterInstances environment "Std.ToFormat"
    (psToFormatGroundInstances ++ psToFormatContainerDeclarations)
  { environment with exportedAliases :=
      (psDecisionName "Std.format", psDecisionName "Std.ToFormat.format") :: environment.exportedAliases }
