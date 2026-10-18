/-
Format algebra adapted from Lean 4 Init/Data/Format/Basic.lean.
Copyright (c) 2018 Microsoft Corporation. All rights reserved.
Author: Leonardo de Moura. Apache-2.0; see psc0/THIRD_PARTY_NOTICES.md.
Modified: checked portable Core declarations and fold authoring helpers.
-/
import Ps.Environment.StandardData

def psFormatName : PsName := psDecisionName "Std.Format"
def psFormatType : PsExpr := .constE psFormatName []
def psFormatBehaviorName : PsName := psNameAppendStr psFormatName "FlattenBehavior"
def psFormatBehaviorType : PsExpr := .constE psFormatBehaviorName []

def psFormatCall (suffix : String) (arguments : List PsExpr := []) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr psFormatName suffix) []) arguments

def psFormatBehavior (fill : Bool := false) : PsExpr :=
  .constE (psNameAppendStr psFormatBehaviorName (if fill then "fill" else "allOrNone")) []

def psFormatConstructors : List PsStandardDataConstructor :=
  let format := psFormatType
  let behavior := psLogicApply (.constE psOptParamName [.succ .zero])
    [psFormatBehaviorType, psFormatBehavior false]
  [ { name := "nil" },
    { name := "line" },
    { name := "align", fields := [{ name := "force", type := .constE psBoolName [] }] },
    { name := "text", fields := [{ name := "text", type := .constE psStringName [] }] },
    { name := "nest", fields :=
      [{ name := "indent", type := .constE psIntName [] },
       { name := "f", type := format, recursive := true }] },
    { name := "append", fields :=
      [{ name := "left", type := format, recursive := true },
       { name := "right", type := format, recursive := true }] },
    { name := "group", fields :=
      [{ name := "f", type := format, recursive := true },
       { name := "behavior", type := behavior }] },
    { name := "tag", fields :=
      [{ name := "tag", type := psOrderNat },
       { name := "f", type := format, recursive := true }] } ]

def psStandardFormatDataDeclarations : List PsDeclaration :=
  psStandardDataDeclarations psFormatBehaviorName
    [{ name := "allOrNone" }, { name := "fill" }] ++
  psStandardDataDeclarations psFormatName psFormatConstructors

-- Branch callbacks expose the exact pinned constructor shape. Computational
-- folds return a closed Type-0 result (possibly a function carrying context).
structure PsFormatBranches where
  nil : PsExpr
  line : PsExpr
  align : PsExpr → PsExpr
  text : PsExpr → PsExpr
  nest : PsExpr → PsExpr → PsExpr → PsExpr
  append : PsExpr → PsExpr → PsExpr → PsExpr → PsExpr
  group : PsExpr → PsExpr → PsExpr → PsExpr
  tag : PsExpr → PsExpr → PsExpr → PsExpr

def psFormatFold (result value : PsExpr) (offset : Nat)
    (branches : PsFormatBranches) : PsExpr :=
  let a := PsExpr.fvar offset
  let b := PsExpr.fvar (offset + 1)
  let ihA := PsExpr.fvar (offset + 2)
  let ihB := PsExpr.fvar (offset + 3)
  let bodies := [branches.nil, branches.line, branches.align a, branches.text a,
    branches.nest a b ihB, branches.append a b ihA ihB,
    branches.group a b ihA, branches.tag a b ihB]
  let minors := (psFormatConstructors.zip bodies).map fun (ctor, value) =>
    let recursive := ctor.fields.zipIdx |>.filterMap fun (field, i) =>
      if field.recursive then some i else none
    let value := recursive.foldr (fun i body =>
      psLogicLam (offset + ctor.fields.length + i) ("ih" ++ toString i) result body) value
    psStandardDataBind ctor.fields offset value true
  psLogicApply (.constE (psNameAppendStr psFormatName "rec") [.succ .zero])
    ([psLogicLam offset "_" psFormatType result] ++ minors ++ [value])

def psFormatBehaviorCase (result value allOrNone fill : PsExpr)
    (offset : Nat) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr psFormatBehaviorName "rec") [.succ .zero])
    [psLogicLam offset "_" psFormatBehaviorType result, allOrNone, fill, value]
