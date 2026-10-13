/-
String.toFormat follows Lean 4.35.0 Init/Data/Format/Instances.lean.
Copyright (c) 2020 Microsoft Corporation. Author: Leonardo de Moura.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Modified: single total UTF-8 cursor scan instead of a split/list allocation.
-/
import Ps.Environment.StandardToFormat

def psFormatStringDeclarations : List PsDeclaration :=
  let str := PsExpr.constE psStringName []
  let nat := psOrderNat
  let format := psFormatType
  let source := PsExpr.fvar 0
  let pos := PsExpr.fvar 2
  let start := PsExpr.fvar 3
  let acc := PsExpr.fvar 4
  let segment := psFormatCall "text"
    [psLogicApply (.constE psStringExtractName []) [source, start, pos]]
  let done := psFormatCall "append" [acc, segment]
  let next := psLogicApply (.constE psStringNextName []) [source, pos]
  let scalar := psLogicApply (.constE psStringGetName []) [source, pos]
  let isLF := psOrderCall "Nat.beq" [.app (.constE psCharToNatName []) scalar, psFormatNat 10]
  let recurse := fun start acc => psLogicApply (.fvar 6) [next, start, acc]
  let step := psFormatIf format (psLogicApply (.constE psStringAtEndName []) [source, pos]) done
    (psFormatIf format isLF
      (recurse next (psFormatCall "append" [done, psFormatCall "line"]))
      (recurse start acc))
  let fields : List PsStandardDataField :=
    [{ name := "position", type := nat }, { name := "start", type := nat },
     { name := "document", type := format }]
  let arrow := psStandardDataBind fields 2 format
  let body := psOrderNatRec (.succ .zero) (psLogicLam 5 "_" nat arrow)
    (psStandardDataBind fields 2 done true)
    (psLogicLam 5 "remaining" nat (psLogicLam 6 "ih" arrow
      (psStandardDataBind fields 2 step true))) (.fvar 1)
  let worker := psFormatPrivateDefinition "stringFormat"
    [{ name := "source", type := str }, { name := "fuel", type := nat }] arrow body
  let publicDeclaration := psFormatDefinition "String.toFormat" [{ name := "source", type := str }] format
    (psFormatPrivateCall "stringFormat"
      [source, psOrderSucc (.app (.constE psStringUtf8ByteSizeName []) source),
       psFormatNat 0, psFormatNat 0, psFormatCall "nil"])
  [worker, publicDeclaration]

def psFormatAppendInstance : PsDeclaration :=
  psStandardBinaryInstance { className := "HAppend", fieldName := "hAppend" }
    psFormatName (psNameAppendStr psFormatName "append")

def psFormatCoeInstance : PsDeclaration :=
  let str := PsExpr.constE psStringName []
  let levels : List PsLevel := [.succ .zero, .succ .zero]
  .definitionDecl (psDecisionName "PsStandard.instCoeStringFormat") []
    (psLogicApply (.constE (psRootName "Coe") levels) [str, psFormatType])
    (psLogicApply (.constE (psDecisionName "Coe.mk") levels)
      [str, psFormatType, .constE (psNameAppendStr psFormatName "text") []])

def psFormatInhabitedInstances : List PsDeclaration :=
  [ psStandardInhabitedGround "Format" psFormatType (psFormatCall "nil"),
    psStandardInhabitedGround "FormatFlattenBehavior" psFormatBehaviorType psFormatBehavior ]

def psStandardFormatStringDeclarations : List PsDeclaration :=
  psFormatStringDeclarations ++ [psFormatAppendInstance, psFormatCoeInstance] ++ psFormatInhabitedInstances

def psStandardFormatStringExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardFormatStringDeclarations.foldl psPreludeAdd environment
  let environment := psFormatRegister environment "HAppend" [psFormatAppendInstance]
  let environment := psFormatRegister environment "Coe" [psFormatCoeInstance]
  psFormatRegister environment "Inhabited" psFormatInhabitedInstances
