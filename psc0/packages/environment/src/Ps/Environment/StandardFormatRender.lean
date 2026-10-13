/-
Pure layout transitions adapted from Lean 4 Init/Data/Format/Basic.lean.
Copyright (c) 2018 Microsoft Corporation. All rights reserved.
Author: Leonardo de Moura. Apache-2.0; see psc0/THIRD_PARTY_NOTICES.md.
Modified: a total input-bounded machine over checked Core data and definitions.
-/
import Ps.Environment.StandardFormatWork

def psFormatStateType : PsExpr := psFormatPrivateType "State"
def psFormatMachineType : PsExpr := psFormatPrivateType "Machine"
def psFormatColumn (state : PsExpr) : PsExpr := psFormatField "State" 1 state
def psFormatOutput (state : PsExpr) : PsExpr := psFormatField "State" 0 state
def psFormatMachine (groups state : PsExpr) : PsExpr := psFormatRecord "Machine" [groups, state]
def psFormatEmit (state text : PsExpr) : PsExpr := psFormatPrivateCall "emit" [state, text]
def psFormatNewline (state indent : PsExpr) : PsExpr := psFormatPrivateCall "newline" [state, indent]

-- A nonrecursive case over a checked List. The supplied tail hypothesis is
-- deliberately unused; actual recursive traversal belongs to its named worker.
def psFormatListCase (element result value nil : PsExpr) (offset : Nat) (cons : PsExpr) : PsExpr :=
  psLogicApply psStandardListRecursor
    [element, psLogicLam offset "_" (psSelfHostListOf element) result, nil,
     psLogicLam offset "head" element
       (psLogicLam (offset + 1) "tail" (psSelfHostListOf element)
         (psLogicLam (offset + 2) "_" result cons)), value]

def psFormatRenderStateDeclarations : List PsDeclaration :=
  let str := PsExpr.constE psStringName []
  let states := psStandardRecordDeclarations (psFormatPrivateName "State")
    [{ name := "out", type := str }, { name := "column", type := psOrderNat }] ++
    psStandardRecordDeclarations (psFormatPrivateName "Machine")
      [{ name := "groups", type := psFormatGroupsType }, { name := "state", type := psFormatStateType }]
  let spaces := psFormatPrivateDefinition "spaces" [{ name := "count", type := psOrderNat }] str
    (psOrderNatRec (.succ .zero) (psLogicLam 10 "_" psOrderNat str) (.lit (.string ""))
      (psLogicLam 11 "_" psOrderNat (psLogicLam 12 "previous" str
        (psFormatStringAppend (.fvar 12) (.lit (.string " "))))) (.fvar 0))
  let state := PsExpr.fvar 0
  let text := PsExpr.fvar 1
  let emit := psFormatPrivateDefinition "emit"
    [{ name := "state", type := psFormatStateType }, { name := "text", type := str }] psFormatStateType
    (psFormatRecord "State"
      [psFormatStringAppend (psFormatOutput state) text,
       psOrderCall "Nat.add" [psFormatColumn state, .app (.constE psStringLengthName []) text]])
  let indent := PsExpr.fvar 1
  let newline := psFormatPrivateDefinition "newline"
    [{ name := "state", type := psFormatStateType }, { name := "indent", type := psOrderNat }] psFormatStateType
    (psFormatRecord "State"
      [psFormatStringAppend (psFormatOutput state)
        (psFormatStringAppend (.lit (.string "\n")) (psFormatPrivateCall "spaces" [indent])), indent])
  states ++ [spaces, emit, newline]

def psFormatRenderItemDeclaration : PsDeclaration :=
  let width := PsExpr.fvar 0
  let state := PsExpr.fvar 1
  let group := PsExpr.fvar 2
  let rest := PsExpr.fvar 3
  let outer := PsExpr.fvar 4
  let item := PsExpr.fvar 5
  let indent := psFormatItemField 1 item
  let fla := psFormatGroupField 0 group
  let flb := psFormatGroupField 1 group
  let flatten := psFormatShouldFlatten fla
  let groups := fun items => psFormatConsGroup (psFormatGroup fla flb items) outer
  let same := fun items state => psFormatMachine (groups items) state
  let replace := fun f => psFormatConsItem (psFormatItem f indent) rest
  let push := fun behavior items outer width state =>
    psFormatPrivateCall "pushGroup" [behavior, items, outer, width, psFormatColumn state]
  let afterNewline := PsExpr.fvar 6
  let newline := psFormatNewline state (psOrderCall "Int.toNat" [indent])
  let breakFill := psFormatLet 6 "afterNewline" psFormatStateType newline
    (psFormatMachine (push (psFormatBehavior true) rest outer width afterNewline) afterNewline)
  let trial := PsExpr.fvar 7
  let trialFits := psFormatListCase psFormatGroupType (.constE psBoolName []) trial
    (psFormatBool false) 30 (psFormatShouldFlatten (psFormatGroupField 0 (.fvar 30)))
  let fillLine := psFormatIf psFormatMachineType flatten
    (psFormatLet 7 "trial" psFormatGroupsType
      (push (psFormatBehavior true) rest outer (psOrderCall "Nat.sub" [width, psFormatNat 1]) state)
      (psFormatIf psFormatMachineType trialFits
        (psFormatMachine trial (psFormatEmit state (.lit (.string " ")))) breakFill))
    breakFill
  let text := fun source =>
    let prefixInfo := PsExpr.fvar 8
    let position := psFormatField "TextPrefix" 0 prefixInfo
    let first := psLogicApply (.constE psStringExtractName []) [source, psFormatNat 0, position]
    let tail := psLogicApply (.constE psStringExtractName [])
      [source, psLogicApply (.constE psStringNextName []) [source, position],
       .app (.constE psStringUtf8ByteSizeName []) source]
    let items := replace (psFormatCall "text" [tail])
    let newState := psFormatNewline (psFormatEmit state first) (psOrderCall "Int.toNat" [indent])
    psFormatLet 8 "prefixInfo" (psFormatPrivateType "TextPrefix")
      (psFormatPrivateCall "textPrefix" [source])
      (psFormatIf psFormatMachineType
        (psLogicApply (.constE psStringAtEndName []) [source, position])
        (same rest (psFormatEmit state source))
        (psFormatLet 6 "afterNewline" psFormatStateType newState
          (psFormatIf psFormatMachineType (psFormatIsDisallowed fla)
            (same items afterNewline)
            (psFormatMachine (push flb items outer width afterNewline) afterNewline))))
  let body := psFormatFold psFormatMachineType (psFormatItemField 0 item) 100 {
    nil := same rest state
    line := psFormatBehaviorCase psFormatMachineType flb
      (psFormatIf psFormatMachineType flatten
        (same rest (psFormatEmit state (.lit (.string " ")))) (same rest newline))
      fillLine 30
    align := fun force =>
      let spaces := psOrderCall "Int.sub" [indent, psFormatInt (psFormatColumn state)]
      psFormatIf psFormatMachineType (psFormatAnd flatten (psFormatNot force)) (same rest state)
        (psFormatIf psFormatMachineType (psFormatPositive spaces)
          (same rest (psFormatEmit state
            (psFormatPrivateCall "spaces" [psOrderCall "Int.toNat" [spaces]])))
          (same rest newline))
    text := text
    nest := fun n f _ => same
      (psFormatConsItem (psFormatItem f (psOrderCall "Int.add" [indent, n])) rest) state
    append := fun left right _ _ => same
      (psFormatConsItem (psFormatItem left indent) (replace right)) state
    group := fun f behavior _ =>
      psFormatIf psFormatMachineType flatten (same (replace f) state)
        (psFormatMachine (push behavior
          (psFormatConsItem (psFormatItem f indent) (psSelfHostListNilOf psFormatItemType))
          (groups rest) width state) state)
    tag := fun _ f _ => same (replace f) state }
  psFormatPrivateDefinition "renderItem"
    [{ name := "width", type := psOrderNat }, { name := "state", type := psFormatStateType },
     { name := "group", type := psFormatGroupType }, { name := "rest", type := psFormatItemsType },
     { name := "outer", type := psFormatGroupsType }, { name := "item", type := psFormatItemType }]
    psFormatMachineType body

def psFormatRenderStepDeclaration : PsDeclaration :=
  let width := PsExpr.fvar 0
  let groups := PsExpr.fvar 1
  let state := PsExpr.fvar 2
  let group := PsExpr.fvar 10
  let outer := PsExpr.fvar 11
  let item := PsExpr.fvar 20
  let rest := PsExpr.fvar 21
  let body := psFormatListCase psFormatGroupType psFormatMachineType groups
    (psFormatMachine groups state) 10
    (psFormatListCase psFormatItemType psFormatMachineType (psFormatGroupField 2 group)
      (psFormatMachine outer state) 20
      (psFormatPrivateCall "renderItem" [width, state, group, rest, outer, item]))
  psFormatPrivateDefinition "renderStep"
    [{ name := "width", type := psOrderNat }, { name := "groups", type := psFormatGroupsType },
     { name := "state", type := psFormatStateType }] psFormatMachineType body

-- Remaining weight: two per document node, text UTF-8 bytes, one per group.
-- Each transition consumes positive weight; a pushed group costs one but
-- consumes a two-weight group node. A hard line consumes at least one byte.
-- Empty work terminates immediately, independent of unused text-byte budget.
def psFormatRenderWorkerDeclaration : PsDeclaration :=
  let width := PsExpr.fvar 0
  let fuel := PsExpr.fvar 1
  let groups := PsExpr.fvar 2
  let state := PsExpr.fvar 3
  let str := PsExpr.constE psStringName []
  let arrow := psLogicPi 2 "groups" psFormatGroupsType (psLogicPi 3 "state" psFormatStateType str)
  let bind := fun body => psLogicLam 2 "groups" psFormatGroupsType (psLogicLam 3 "state" psFormatStateType body)
  let machine := PsExpr.fvar 6
  let advance := psFormatLet 6 "next" psFormatMachineType
    (psFormatPrivateCall "renderStep" [width, groups, state])
    (psLogicApply (.fvar 5) [psFormatField "Machine" 0 machine, psFormatField "Machine" 1 machine])
  let step := psFormatListCase psFormatGroupType str groups (psFormatOutput state) 20 advance
  let body := psOrderNatRec (.succ .zero) (psLogicLam 4 "_" psOrderNat arrow)
    (bind (psFormatOutput state))
    (psLogicLam 4 "remaining" psOrderNat (psLogicLam 5 "ih" arrow (bind step))) fuel
  psFormatPrivateDefinition "renderWorker"
    [{ name := "width", type := psOrderNat }, { name := "remainingWeight", type := psOrderNat }] arrow body

def psFormatPrettyDeclaration : PsDeclaration :=
  let f := PsExpr.fvar 0
  let width := PsExpr.fvar 1
  let indent := PsExpr.fvar 2
  let column := PsExpr.fvar 3
  let option := fun defaultValue => psLogicApply (.constE psOptParamName [.succ .zero])
    [psOrderNat, defaultValue]
  let groups := psFormatConsGroup
    (psFormatGroup psFormatDisallow (psFormatBehavior false)
      (psFormatConsItem (psFormatItem f (psFormatInt indent)) (psSelfHostListNilOf psFormatItemType)))
    (psSelfHostListNilOf psFormatGroupType)
  let body := psFormatPrivateCall "renderWorker"
    [width, psOrderSucc (psOrderCall "$psc0Standard.formatWeight" [f]), groups,
     psFormatRecord "State" [.lit (.string ""), column]]
  psFormatDefinition "Std.Format.pretty"
    [{ name := "f", type := psFormatType },
     { name := "width", type := option (psFormatCall "defWidth") },
     { name := "indent", type := option (psFormatNat 0) },
     { name := "column", type := option (psFormatNat 0) }]
    (.constE psStringName []) body
