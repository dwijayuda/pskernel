/-
Work-group layout adapted from Lean 4 Init/Data/Format/Basic.lean.
Copyright (c) 2018 Microsoft Corporation. All rights reserved.
Author: Leonardo de Moura. Apache-2.0; see psc0/THIRD_PARTY_NOTICES.md.
Modified: pure checked folds; tag callbacks belong to the separate effectful API.
-/
import Ps.Environment.StandardFormatMeasure

def psFormatAllowName : PsName := psNameAppendStr psFormatName "FlattenAllowability"
def psFormatAllowType : PsExpr := .constE psFormatAllowName []
def psFormatAllowConstructors : List PsStandardDataConstructor :=
  [{ name := "allow", fields := [{ name := "fits", type := .constE psBoolName [] }] },
   { name := "disallow" }]
def psFormatAllow (fits : PsExpr) : PsExpr :=
  .app (.constE (psNameAppendStr psFormatAllowName "allow") []) fits
def psFormatDisallow : PsExpr := .constE (psNameAppendStr psFormatAllowName "disallow") []
def psFormatShouldFlatten (fla : PsExpr) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr psFormatAllowName "shouldFlatten") []) [fla]
def psFormatIsDisallowed (fla : PsExpr) : PsExpr :=
  psFormatPrivateCall "isDisallowed" [fla]
def psFormatItemType : PsExpr := psFormatPrivateType "WorkItem"
def psFormatItemsType : PsExpr := psSelfHostListOf psFormatItemType
def psFormatGroupType : PsExpr := psFormatPrivateType "WorkGroup"
def psFormatGroupsType : PsExpr := psSelfHostListOf psFormatGroupType
def psFormatItem (f indent : PsExpr) : PsExpr := psFormatRecord "WorkItem" [f, indent]
def psFormatGroup (fla flb items : PsExpr) : PsExpr := psFormatRecord "WorkGroup" [fla, flb, items]
def psFormatItemField (index : Nat) (value : PsExpr) : PsExpr := psFormatField "WorkItem" index value
def psFormatGroupField (index : Nat) (value : PsExpr) : PsExpr := psFormatField "WorkGroup" index value
def psFormatConsItem (item items : PsExpr) : PsExpr := psSelfHostListConsOf psFormatItemType item items
def psFormatConsGroup (group groups : PsExpr) : PsExpr := psSelfHostListConsOf psFormatGroupType group groups

def psFormatWorkDataDeclarations : List PsDeclaration :=
  let bool := PsExpr.constE psBoolName []
  let shouldFlatten := psFormatDefinition "Std.Format.FlattenAllowability.shouldFlatten"
    [{ name := "fla", type := psFormatAllowType }] bool
    (psStandardDataCase psFormatAllowName psFormatAllowConstructors bool (.fvar 0) 10
      [.fvar 10, psFormatBool false])
  let disallowed := psFormatPrivateDefinition "isDisallowed"
    [{ name := "fla", type := psFormatAllowType }] bool
    (psStandardDataCase psFormatAllowName psFormatAllowConstructors bool (.fvar 0) 10
      [psFormatBool false, psFormatBool true])
  psStandardDataDeclarations psFormatAllowName psFormatAllowConstructors ++
    [shouldFlatten, disallowed] ++
    psStandardRecordDeclarations (psFormatPrivateName "WorkItem")
      [{ name := "f", type := psFormatType }, { name := "indent", type := .constE psIntName [] }] ++
    psStandardRecordDeclarations (psFormatPrivateName "WorkGroup")
      [{ name := "fla", type := psFormatAllowType }, { name := "flb", type := psFormatBehaviorType },
       { name := "items", type := psFormatItemsType }]

-- List folds carry a width continuation, preserving merge's short circuit.
-- They do not pre-measure the entire remainder eagerly.
def psFormatMeasureItemsDeclaration : PsDeclaration :=
  let flatten := PsExpr.fvar 0
  let col := PsExpr.fvar 1
  let items := PsExpr.fvar 2
  let width := PsExpr.fvar 3
  let item := PsExpr.fvar 10
  let ih := PsExpr.fvar 12
  let margin := psOrderCall "Int.sub"
    [psFormatInt (psOrderCall "Nat.add" [width, col]), psFormatItemField 1 item]
  let measured := psFormatPrivateCall "spaceUptoLine"
    [psFormatItemField 0 item, flatten, margin, width]
  let body := psLogicApply (psStandardListRecursor .zero)
    [psFormatItemType, psLogicLam 20 "_" psFormatItemsType psFormatSpaceArrow,
     psLogicLam 3 "width" psOrderNat psFormatZeroSpace,
     psLogicLam 10 "item" psFormatItemType
       (psLogicLam 11 "rest" psFormatItemsType
         (psLogicLam 12 "next" psFormatSpaceArrow
           (psLogicLam 3 "width" psOrderNat (psFormatMerge width measured ih)))), items]
  psFormatPrivateDefinition "measureItems"
    [{ name := "flatten", type := .constE psBoolName [] }, { name := "column", type := psOrderNat },
     { name := "items", type := psFormatItemsType }] psFormatSpaceArrow body

def psFormatMeasureGroupsDeclaration : PsDeclaration :=
  let col := PsExpr.fvar 0
  let groups := PsExpr.fvar 1
  let width := PsExpr.fvar 2
  let group := PsExpr.fvar 10
  let ih := PsExpr.fvar 12
  let measured := psFormatPrivateCall "measureItems"
    [psFormatShouldFlatten (psFormatGroupField 0 group), col, psFormatGroupField 2 group, width]
  let body := psLogicApply (psStandardListRecursor .zero)
    [psFormatGroupType, psLogicLam 20 "_" psFormatGroupsType psFormatSpaceArrow,
     psLogicLam 2 "width" psOrderNat psFormatZeroSpace,
     psLogicLam 10 "group" psFormatGroupType
       (psLogicLam 11 "rest" psFormatGroupsType
         (psLogicLam 12 "next" psFormatSpaceArrow
           (psLogicLam 2 "width" psOrderNat (psFormatMerge width measured ih)))), groups]
  psFormatPrivateDefinition "measureGroups"
    [{ name := "column", type := psOrderNat }, { name := "groups", type := psFormatGroupsType }]
    psFormatSpaceArrow body

def psFormatPushGroupDeclaration : PsDeclaration :=
  let flb := PsExpr.fvar 0
  let items := PsExpr.fvar 1
  let groups := PsExpr.fvar 2
  let width := PsExpr.fvar 3
  let column := PsExpr.fvar 4
  let available := psOrderCall "Nat.sub" [width, column]
  let r := PsExpr.fvar 5
  let allOrNone := psFormatBehaviorCase (.constE psBoolName []) flb
    (psFormatBool true) (psFormatBool false) 30
  let fits := psFormatAnd (psFormatNot (psFormatSpaceField 1 r))
    (psOrderCall "Nat.ble"
      [psFormatSpaceField 2 (psFormatMerge available r
        (psLogicLam 6 "remaining" psOrderNat
          (psFormatPrivateCall "measureGroups" [column, groups, .fvar 6]))), available])
  let body := psFormatLet 5 "measured" psFormatSpaceType
    (psFormatPrivateCall "measureItems" [allOrNone, column, items, available])
    (psFormatConsGroup (psFormatGroup (psFormatAllow fits) flb items) groups)
  psFormatPrivateDefinition "pushGroup"
    [{ name := "behavior", type := psFormatBehaviorType }, { name := "items", type := psFormatItemsType },
     { name := "groups", type := psFormatGroupsType }, { name := "width", type := psOrderNat },
     { name := "column", type := psOrderNat }] psFormatGroupsType body
