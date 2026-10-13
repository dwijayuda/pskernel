/-
Layout measurement adapted from Lean 4 Init/Data/Format/Basic.lean.
Copyright (c) 2018 Microsoft Corporation. All rights reserved.
Author: Leonardo de Moura. Apache-2.0; see psc0/THIRD_PARTY_NOTICES.md.
Modified: checked Core folds, explicit Unicode scan and pure records.
-/
import Ps.Environment.StandardFormatSupport

def psFormatSpaceType : PsExpr := psFormatPrivateType "SpaceResult"
def psFormatSpace (line hard space : PsExpr) : PsExpr :=
  psFormatRecord "SpaceResult" [line, hard, space]
def psFormatZeroSpace : PsExpr :=
  psFormatSpace (psFormatBool false) (psFormatBool false) (psFormatNat 0)
def psFormatSpaceField (index : Nat) (value : PsExpr) : PsExpr :=
  psFormatField "SpaceResult" index value
def psFormatSpaceArrow : PsExpr := psLogicPi 80 "width" psOrderNat psFormatSpaceType

def psFormatSpaceDeclarations : List PsDeclaration :=
  let bool := PsExpr.constE psBoolName []
  let record := psStandardRecordDeclarations (psFormatPrivateName "SpaceResult")
    [{ name := "foundLine", type := bool }, { name := "foundFlattenedHardLine", type := bool },
     { name := "space", type := psOrderNat }]
  let width := PsExpr.fvar 0
  let left := PsExpr.fvar 1
  let next := PsExpr.fvar 2
  let right := PsExpr.fvar 3
  let space := psFormatSpaceField 2 left
  let merged := psFormatLet 3 "right" psFormatSpaceType
    (.app next (psOrderCall "Nat.sub" [width, space]))
    (psFormatSpace (psFormatSpaceField 0 right) (psFormatSpaceField 1 right)
      (psOrderCall "Nat.add" [space, psFormatSpaceField 2 right]))
  let body := psFormatIf psFormatSpaceType (psOrderCall "Nat.blt" [width, space]) left
    (psFormatIf psFormatSpaceType (psFormatSpaceField 0 left) left merged)
  record ++ [psFormatPrivateDefinition "merge"
    [{ name := "width", type := psOrderNat }, { name := "left", type := psFormatSpaceType },
     { name := "next", type := psFormatSpaceArrow }] psFormatSpaceType body]

def psFormatMerge (width left next : PsExpr) : PsExpr :=
  psFormatPrivateCall "merge" [width, left, next]

def psFormatMeasureDeclaration : PsDeclaration :=
  let bool := PsExpr.constE psBoolName []
  let int := PsExpr.constE psIntName []
  let flatten := PsExpr.fvar 10
  let margin := PsExpr.fvar 11
  let width := PsExpr.fvar 12
  let arrow := psLogicPi 10 "flatten" bool
    (psLogicPi 11 "margin" int (psLogicPi 12 "width" psOrderNat psFormatSpaceType))
  let bind := fun body => psLogicLam 10 "flatten" bool
    (psLogicLam 11 "margin" int (psLogicLam 12 "width" psOrderNat body))
  let line := psFormatSpace (psFormatBool true) (psFormatBool false) (psFormatNat 0)
  let apply := fun ih m w => psLogicApply ih [flatten, m, w]
  let text := fun s =>
    let prefix := PsExpr.fvar 13
    let pos := psFormatField "TextPrefix" 0 prefix
    let found := psFormatNot (psLogicApply (.constE psStringAtEndName []) [s, pos])
    psFormatLet 13 "prefix" (psFormatPrivateType "TextPrefix")
      (psFormatPrivateCall "textPrefix" [s])
      (psFormatSpace found (psFormatAnd flatten found) (psFormatField "TextPrefix" 1 prefix))
  let body := psFormatFold arrow (.fvar 0) 100 {
    nil := bind psFormatZeroSpace
    line := bind (psFormatIf psFormatSpaceType flatten
      (psFormatSpace (psFormatBool false) (psFormatBool false) (psFormatNat 1)) line)
    align := fun force => bind (
      psFormatIf psFormatSpaceType (psFormatAnd flatten (psFormatNot force)) psFormatZeroSpace
        (let remaining := psOrderCall "Int.sub" [margin, psFormatInt width]
         psFormatIf psFormatSpaceType (psFormatPositive remaining)
           (psFormatSpace (psFormatBool false) (psFormatBool false)
             (psOrderCall "Int.toNat" [remaining])) line))
    text := fun s => bind (text s)
    nest := fun n _ ih => bind (apply ih (psOrderCall "Int.sub" [margin, n]) width)
    append := fun _ _ left right => bind (psFormatMerge width (apply left margin width)
      (psLogicLam 14 "remaining" psOrderNat (apply right margin (.fvar 14))))
    group := fun _ _ ih => bind (psLogicApply ih [psFormatBool true, margin, width])
    tag := fun _ _ ih => bind (apply ih margin width) }
  psFormatPrivateDefinition "spaceUptoLine" [{ name := "f", type := psFormatType }] arrow body
