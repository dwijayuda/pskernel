import Ps.PSCKernel.Core.Name

inductive PsCKernelLevel where
  | zero
  | succ (of : PsCKernelLevel)
  | max (left : PsCKernelLevel) (right : PsCKernelLevel)
  | imax (left : PsCKernelLevel) (right : PsCKernelLevel)
  | param (name : PsCKernelName)
  | mvar (name : PsCKernelName)

structure PsCKernelLevelOffset where
  base : PsCKernelLevel
  offset : Nat

structure PsCKernelLevelChange where
  level : PsCKernelLevel
  changed : Bool

def psCKernelLevelZero : PsCKernelLevel :=
  PsCKernelLevel.zero

def psCKernelLevelSucc (of : PsCKernelLevel) : PsCKernelLevel :=
  PsCKernelLevel.succ of

def psCKernelLevelParam (name : PsCKernelName) : PsCKernelLevel :=
  PsCKernelLevel.param name

def psCKernelLevelMVar (name : PsCKernelName) : PsCKernelLevel :=
  PsCKernelLevel.mvar name

def psCKernelLevelMaxRaw
    (left : PsCKernelLevel)
    (right : PsCKernelLevel) : PsCKernelLevel :=
  PsCKernelLevel.max left right

def psCKernelLevelIMaxRaw
    (left : PsCKernelLevel)
    (right : PsCKernelLevel) : PsCKernelLevel :=
  PsCKernelLevel.imax left right

def psCKernelLevelEqStructural
    (left : PsCKernelLevel) : PsCKernelLevel -> Bool :=
  match left with
  | PsCKernelLevel.zero =>
      fun (right : PsCKernelLevel) =>
        match right with
        | PsCKernelLevel.zero => true
        | _ => false
  | PsCKernelLevel.succ leftOf =>
      fun (right : PsCKernelLevel) =>
        match right with
        | PsCKernelLevel.succ rightOf =>
            psCKernelLevelEqStructural leftOf rightOf
        | _ => false
  | PsCKernelLevel.max leftA leftB =>
      fun (right : PsCKernelLevel) =>
        match right with
        | PsCKernelLevel.max rightA rightB =>
            if psCKernelLevelEqStructural leftA rightA then
              psCKernelLevelEqStructural leftB rightB
            else
              false
        | _ => false
  | PsCKernelLevel.imax leftA leftB =>
      fun (right : PsCKernelLevel) =>
        match right with
        | PsCKernelLevel.imax rightA rightB =>
            if psCKernelLevelEqStructural leftA rightA then
              psCKernelLevelEqStructural leftB rightB
            else
              false
        | _ => false
  | PsCKernelLevel.param leftName =>
      fun (right : PsCKernelLevel) =>
        match right with
        | PsCKernelLevel.param rightName =>
            psCKernelNameEq leftName rightName
        | _ => false
  | PsCKernelLevel.mvar leftName =>
      fun (right : PsCKernelLevel) =>
        match right with
        | PsCKernelLevel.mvar rightName =>
            psCKernelNameEq leftName rightName
        | _ => false

def psCKernelLevelHasMVar (level : PsCKernelLevel) : Bool :=
  match level with
  | PsCKernelLevel.zero => false
  | PsCKernelLevel.succ of => psCKernelLevelHasMVar of
  | PsCKernelLevel.max left right =>
      if psCKernelLevelHasMVar left then
        true
      else
        psCKernelLevelHasMVar right
  | PsCKernelLevel.imax left right =>
      if psCKernelLevelHasMVar left then
        true
      else
        psCKernelLevelHasMVar right
  | PsCKernelLevel.param _ => false
  | PsCKernelLevel.mvar _ => true

def psCKernelNameListContains
    (names : List PsCKernelName)
    (query : PsCKernelName) : Bool :=
  match names with
  | [] => false
  | head :: tail =>
      if psCKernelNameEq head query then
        true
      else
        psCKernelNameListContains tail query

def psCKernelNameListAppendUnique
    (names : List PsCKernelName)
    (name : PsCKernelName) : List PsCKernelName :=
  if psCKernelNameListContains names name then
    names
  else
    List.append names [name]

def psCKernelLevelParamNamesInto
    (level : PsCKernelLevel)
    (names : List PsCKernelName) : List PsCKernelName :=
  match level with
  | PsCKernelLevel.zero => names
  | PsCKernelLevel.succ of =>
      psCKernelLevelParamNamesInto of names
  | PsCKernelLevel.max left right =>
      let afterLeft : List PsCKernelName :=
        psCKernelLevelParamNamesInto left names
      psCKernelLevelParamNamesInto right afterLeft
  | PsCKernelLevel.imax left right =>
      let afterLeft : List PsCKernelName :=
        psCKernelLevelParamNamesInto left names
      psCKernelLevelParamNamesInto right afterLeft
  | PsCKernelLevel.param name =>
      psCKernelNameListAppendUnique names name
  | PsCKernelLevel.mvar _ => names

def psCKernelLevelParamNames (level : PsCKernelLevel) : List PsCKernelName :=
  psCKernelLevelParamNamesInto level []

def psCKernelLevelIsZero (level : PsCKernelLevel) : Bool :=
  match level with
  | PsCKernelLevel.zero => true
  | _ => false

def psCKernelLevelIsNotZero (level : PsCKernelLevel) : Bool :=
  match level with
  | PsCKernelLevel.zero => false
  | PsCKernelLevel.succ _ => true
  | PsCKernelLevel.max left right =>
      if psCKernelLevelIsNotZero left then
        true
      else
        psCKernelLevelIsNotZero right
  | PsCKernelLevel.imax _ right =>
      psCKernelLevelIsNotZero right
  | PsCKernelLevel.param _ => false
  | PsCKernelLevel.mvar _ => false

def psCKernelLevelNormalizesToZero (level : PsCKernelLevel) : Bool :=
  match level with
  | PsCKernelLevel.zero => true
  | PsCKernelLevel.succ _ => false
  | PsCKernelLevel.max left right =>
      if psCKernelLevelNormalizesToZero left then
        psCKernelLevelNormalizesToZero right
      else
        false
  | PsCKernelLevel.imax _ right =>
      psCKernelLevelNormalizesToZero right
  | PsCKernelLevel.param _ => false
  | PsCKernelLevel.mvar _ => false

def psCKernelLevelToOffsetGo
    (level : PsCKernelLevel)
    (offset : Nat) : PsCKernelLevelOffset :=
  match level with
  | PsCKernelLevel.succ of =>
      psCKernelLevelToOffsetGo of (Nat.add offset 1)
  | _ =>
      { base := level, offset := offset }

def psCKernelLevelToOffset (level : PsCKernelLevel) : PsCKernelLevelOffset :=
  psCKernelLevelToOffsetGo level 0

def psCKernelLevelAddOffset
    (level : PsCKernelLevel)
    (offset : Nat) : PsCKernelLevel :=
  match offset with
  | 0 => level
  | Nat.succ rest =>
      PsCKernelLevel.succ (psCKernelLevelAddOffset level rest)

def psCKernelLevelIsOne (level : PsCKernelLevel) : Bool :=
  match level with
  | PsCKernelLevel.succ PsCKernelLevel.zero => true
  | _ => false

def psCKernelLevelMkMax
    (left : PsCKernelLevel)
    (right : PsCKernelLevel) : PsCKernelLevel :=
  if psCKernelLevelEqStructural left right then
    left
  else if psCKernelLevelIsZero left then
    right
  else if psCKernelLevelIsZero right then
    left
  else
    match right with
    | PsCKernelLevel.max rightLeft rightRight =>
        if psCKernelLevelEqStructural rightLeft left then
          right
        else if psCKernelLevelEqStructural rightRight left then
          right
        else
          match left with
          | PsCKernelLevel.max leftLeft leftRight =>
              if psCKernelLevelEqStructural leftLeft right then
                left
              else if psCKernelLevelEqStructural leftRight right then
                left
              else
                let leftOffset : PsCKernelLevelOffset :=
                  psCKernelLevelToOffset left
                let rightOffset : PsCKernelLevelOffset :=
                  psCKernelLevelToOffset right
                if psCKernelLevelEqStructural leftOffset.base rightOffset.base then
                  if Nat.ble rightOffset.offset leftOffset.offset then left else right
                else
                  PsCKernelLevel.max left right
          | _ =>
              let leftOffset : PsCKernelLevelOffset :=
                psCKernelLevelToOffset left
              let rightOffset : PsCKernelLevelOffset :=
                psCKernelLevelToOffset right
              if psCKernelLevelEqStructural leftOffset.base rightOffset.base then
                if Nat.ble rightOffset.offset leftOffset.offset then left else right
              else
                PsCKernelLevel.max left right
    | _ =>
        match left with
        | PsCKernelLevel.max leftLeft leftRight =>
            if psCKernelLevelEqStructural leftLeft right then
              left
            else if psCKernelLevelEqStructural leftRight right then
              left
            else
              let leftOffset : PsCKernelLevelOffset :=
                psCKernelLevelToOffset left
              let rightOffset : PsCKernelLevelOffset :=
                psCKernelLevelToOffset right
              if psCKernelLevelEqStructural leftOffset.base rightOffset.base then
                if Nat.ble rightOffset.offset leftOffset.offset then left else right
              else
                PsCKernelLevel.max left right
        | _ =>
            let leftOffset : PsCKernelLevelOffset :=
              psCKernelLevelToOffset left
            let rightOffset : PsCKernelLevelOffset :=
              psCKernelLevelToOffset right
            if psCKernelLevelEqStructural leftOffset.base rightOffset.base then
              if Nat.ble rightOffset.offset leftOffset.offset then left else right
            else
              PsCKernelLevel.max left right

def psCKernelLevelMkIMax
    (left : PsCKernelLevel)
    (right : PsCKernelLevel) : PsCKernelLevel :=
  if psCKernelLevelIsNotZero right then
    psCKernelLevelMkMax left right
  else if psCKernelLevelIsZero right then
    right
  else if psCKernelLevelIsZero left then
    right
  else if psCKernelLevelIsOne left then
    right
  else if psCKernelLevelEqStructural left right then
    left
  else
    PsCKernelLevel.imax left right

def psCKernelLevelLookupParam
    (query : PsCKernelName)
    (params : List PsCKernelName)
    (values : List PsCKernelLevel) : Option PsCKernelLevel :=
  match params, values with
  | [], _ => none
  | _, [] => none
  | paramName :: paramTail, value :: valueTail =>
      if psCKernelNameEq query paramName then
        some value
      else
        psCKernelLevelLookupParam query paramTail valueTail

def psCKernelInstantiateLevelChange
    (level : PsCKernelLevel)
    (params : List PsCKernelName)
    (values : List PsCKernelLevel) : PsCKernelLevelChange :=
  match level with
  | PsCKernelLevel.zero =>
      { level := level, changed := false }
  | PsCKernelLevel.param name =>
      match psCKernelLevelLookupParam name params values with
      | none => { level := level, changed := false }
      | some value =>
          if psCKernelLevelEqStructural level value then
            { level := level, changed := false }
          else
            { level := value, changed := true }
  | PsCKernelLevel.mvar _ =>
      { level := level, changed := false }
  | PsCKernelLevel.succ of =>
      let result : PsCKernelLevelChange :=
        psCKernelInstantiateLevelChange of params values
      if result.changed then
        { level := PsCKernelLevel.succ result.level, changed := true }
      else
        { level := level, changed := false }
  | PsCKernelLevel.max left right =>
      let leftResult : PsCKernelLevelChange :=
        psCKernelInstantiateLevelChange left params values
      let rightResult : PsCKernelLevelChange :=
        psCKernelInstantiateLevelChange right params values
      if leftResult.changed then
        { level := psCKernelLevelMkMax leftResult.level rightResult.level, changed := true }
      else if rightResult.changed then
        { level := psCKernelLevelMkMax leftResult.level rightResult.level, changed := true }
      else
        { level := level, changed := false }
  | PsCKernelLevel.imax left right =>
      let leftResult : PsCKernelLevelChange :=
        psCKernelInstantiateLevelChange left params values
      let rightResult : PsCKernelLevelChange :=
        psCKernelInstantiateLevelChange right params values
      if leftResult.changed then
        { level := psCKernelLevelMkIMax leftResult.level rightResult.level, changed := true }
      else if rightResult.changed then
        { level := psCKernelLevelMkIMax leftResult.level rightResult.level, changed := true }
      else
        { level := level, changed := false }

def psCKernelInstantiateLevel
    (level : PsCKernelLevel)
    (params : List PsCKernelName)
    (values : List PsCKernelLevel) : PsCKernelLevel :=
  match params with
  | [] => level
  | _ =>
      (psCKernelInstantiateLevelChange level params values).level

def psCKernelLevelToString (level : PsCKernelLevel) : String :=
  match level with
  | PsCKernelLevel.zero => "0"
  | PsCKernelLevel.succ of =>
      String.Internal.append
        "("
        (String.Internal.append
          (psCKernelLevelToString of)
          "+1)")
  | PsCKernelLevel.max left right =>
      String.Internal.append
        "max "
        (String.Internal.append
          (psCKernelLevelToString left)
          (String.Internal.append " " (psCKernelLevelToString right)))
  | PsCKernelLevel.imax left right =>
      String.Internal.append
        "imax "
        (String.Internal.append
          (psCKernelLevelToString left)
          (String.Internal.append " " (psCKernelLevelToString right)))
  | PsCKernelLevel.param name =>
      psCKernelNameToString name
  | PsCKernelLevel.mvar name =>
      String.Internal.append "?" (psCKernelNameToString name)

def psCKernelLevelKindRank (level : PsCKernelLevel) : Nat :=
  match level with
  | PsCKernelLevel.zero => 0
  | PsCKernelLevel.succ _ => 1
  | PsCKernelLevel.max _ _ => 2
  | PsCKernelLevel.imax _ _ => 3
  | PsCKernelLevel.param _ => 4
  | PsCKernelLevel.mvar _ => 5

def psCKernelLevelIsExplicit (level : PsCKernelLevel) : Bool :=
  psCKernelLevelIsZero (psCKernelLevelToOffset level).base

def psCKernelLevelPushMaxArgs (level : PsCKernelLevel) : List PsCKernelLevel :=
  match level with
  | PsCKernelLevel.max left right =>
      List.append
        (psCKernelLevelPushMaxArgs left)
        (psCKernelLevelPushMaxArgs right)
  | _ => [level]

partial def psCKernelLevelNormLt
    (left : PsCKernelLevel)
    (right : PsCKernelLevel) : Bool :=
  let leftOffset : PsCKernelLevelOffset := psCKernelLevelToOffset left
  let rightOffset : PsCKernelLevelOffset := psCKernelLevelToOffset right
  if psCKernelLevelEqStructural leftOffset.base rightOffset.base then
    Nat.blt leftOffset.offset rightOffset.offset
  else
    let leftRank : Nat := psCKernelLevelKindRank leftOffset.base
    let rightRank : Nat := psCKernelLevelKindRank rightOffset.base
    if Nat.blt leftRank rightRank then
      true
    else if Nat.blt rightRank leftRank then
      false
    else
      match leftOffset.base, rightOffset.base with
      | PsCKernelLevel.param leftName, PsCKernelLevel.param rightName =>
          psCKernelNameCmp leftName rightName == -1
      | PsCKernelLevel.mvar leftName, PsCKernelLevel.mvar rightName =>
          psCKernelNameCmp leftName rightName == -1
      | PsCKernelLevel.max leftA leftB, PsCKernelLevel.max rightA rightB =>
          if psCKernelLevelEqStructural leftA rightA then
            psCKernelLevelNormLt leftB rightB
          else
            psCKernelLevelNormLt leftA rightA
      | PsCKernelLevel.imax leftA leftB, PsCKernelLevel.imax rightA rightB =>
          if psCKernelLevelEqStructural leftA rightA then
            psCKernelLevelNormLt leftB rightB
          else
            psCKernelLevelNormLt leftA rightA
      | _, _ => false

def psCKernelLevelInsertNorm
    (level : PsCKernelLevel)
    (levels : List PsCKernelLevel) : List PsCKernelLevel :=
  match levels with
  | [] => [level]
  | head :: tail =>
      if psCKernelLevelNormLt level head then
        level :: head :: tail
      else
        head :: psCKernelLevelInsertNorm level tail

def psCKernelLevelSortNorm
    (levels : List PsCKernelLevel) : List PsCKernelLevel :=
  match levels with
  | [] => []
  | head :: tail =>
      psCKernelLevelInsertNorm head (psCKernelLevelSortNorm tail)

def psCKernelLevelNormalizeAndFlatten
    (normalize : PsCKernelLevel -> PsCKernelLevel)
    (levels : List PsCKernelLevel) : List PsCKernelLevel :=
  match levels with
  | [] => []
  | head :: tail =>
      List.append
        (psCKernelLevelPushMaxArgs (normalize head))
        (psCKernelLevelNormalizeAndFlatten normalize tail)

def psCKernelLevelListHasOffsetAtLeast
    (levels : List PsCKernelLevel)
    (threshold : Nat) : Bool :=
  match levels with
  | [] => false
  | head :: tail =>
      let offset : Nat := (psCKernelLevelToOffset head).offset
      if Nat.ble threshold offset then
        true
      else
        psCKernelLevelListHasOffsetAtLeast tail threshold

def psCKernelLevelDropExplicitSubsumedGo
    (candidate : Option PsCKernelLevel)
    (levels : List PsCKernelLevel) : List PsCKernelLevel :=
  match levels with
  | [] =>
      match candidate with
      | none => []
      | some level => [level]
  | head :: tail =>
      if psCKernelLevelIsExplicit head then
        psCKernelLevelDropExplicitSubsumedGo (some head) tail
      else
        match candidate with
        | none => levels
        | some explicitLevel =>
            let explicitOffset : Nat :=
              (psCKernelLevelToOffset explicitLevel).offset
            if psCKernelLevelListHasOffsetAtLeast levels explicitOffset then
              levels
            else
              explicitLevel :: levels

def psCKernelLevelDropExplicitSubsumed
    (levels : List PsCKernelLevel) : List PsCKernelLevel :=
  psCKernelLevelDropExplicitSubsumedGo none levels

def psCKernelLevelCollapseSortedGo
    (current : PsCKernelLevel)
    (levels : List PsCKernelLevel) : List PsCKernelLevel :=
  match levels with
  | [] => [current]
  | head :: tail =>
      let currentOffset : PsCKernelLevelOffset :=
        psCKernelLevelToOffset current
      let headOffset : PsCKernelLevelOffset :=
        psCKernelLevelToOffset head
      if psCKernelLevelEqStructural currentOffset.base headOffset.base then
        psCKernelLevelCollapseSortedGo head tail
      else
        current :: psCKernelLevelCollapseSortedGo head tail

def psCKernelLevelCollapseSorted
    (levels : List PsCKernelLevel) : List PsCKernelLevel :=
  match levels with
  | [] => []
  | head :: tail => psCKernelLevelCollapseSortedGo head tail

def psCKernelLevelAddOffsetList
    (levels : List PsCKernelLevel)
    (offset : Nat) : List PsCKernelLevel :=
  match levels with
  | [] => []
  | head :: tail =>
      psCKernelLevelAddOffset head offset ::
        psCKernelLevelAddOffsetList tail offset

def psCKernelLevelRebuildMax
    (levels : List PsCKernelLevel) : PsCKernelLevel :=
  match levels with
  | [] => psCKernelLevelZero
  | head :: tail =>
      match tail with
      | [] => head
      | _ => psCKernelLevelMkMax head (psCKernelLevelRebuildMax tail)

partial def psCKernelNormalizeLevel
    (level : PsCKernelLevel) : PsCKernelLevel :=
  let outer : PsCKernelLevelOffset := psCKernelLevelToOffset level
  match outer.base with
  | PsCKernelLevel.zero => level
  | PsCKernelLevel.param _ => level
  | PsCKernelLevel.mvar _ => level
  | PsCKernelLevel.succ _ => level
  | PsCKernelLevel.imax left right =>
      psCKernelLevelAddOffset
        (psCKernelLevelMkIMax
          (psCKernelNormalizeLevel left)
          (psCKernelNormalizeLevel right))
        outer.offset
  | PsCKernelLevel.max _ _ =>
      let leaves : List PsCKernelLevel :=
        psCKernelLevelPushMaxArgs outer.base
      let normalizedLeaves : List PsCKernelLevel :=
        psCKernelLevelNormalizeAndFlatten psCKernelNormalizeLevel leaves
      let sorted : List PsCKernelLevel :=
        psCKernelLevelSortNorm normalizedLeaves
      let withoutSubsumedExplicit : List PsCKernelLevel :=
        psCKernelLevelDropExplicitSubsumed sorted
      let collapsed : List PsCKernelLevel :=
        psCKernelLevelCollapseSorted withoutSubsumedExplicit
      let shifted : List PsCKernelLevel :=
        psCKernelLevelAddOffsetList collapsed outer.offset
      psCKernelLevelRebuildMax shifted

def psCKernelLevelEquivalent
    (left : PsCKernelLevel)
    (right : PsCKernelLevel) : Bool :=
  if psCKernelLevelEqStructural left right then
    true
  else
    psCKernelLevelEqStructural
      (psCKernelNormalizeLevel left)
      (psCKernelNormalizeLevel right)

def psCKernelLevelGeqRemainder
    (geq : PsCKernelLevel -> PsCKernelLevel -> Bool)
    (left : PsCKernelLevel)
    (right : PsCKernelLevel) : Bool :=
  match right with
  | PsCKernelLevel.imax rightLeft rightRight =>
      if geq left rightLeft then
        geq left rightRight
      else
        false
  | _ =>
      match left with
      | PsCKernelLevel.imax _ leftRight =>
          geq leftRight right
      | _ =>
          let leftOffset : PsCKernelLevelOffset :=
            psCKernelLevelToOffset left
          let rightOffset : PsCKernelLevelOffset :=
            psCKernelLevelToOffset right
          if psCKernelLevelEqStructural leftOffset.base rightOffset.base then
            Nat.ble rightOffset.offset leftOffset.offset
          else if psCKernelLevelIsZero rightOffset.base then
            Nat.ble rightOffset.offset leftOffset.offset
          else if Nat.beq leftOffset.offset rightOffset.offset then
            if Nat.beq leftOffset.offset 0 then
              false
            else
              geq leftOffset.base rightOffset.base
          else
            false

partial def psCKernelLevelGeq
    (leftInput : PsCKernelLevel)
    (rightInput : PsCKernelLevel) : Bool :=
  let left : PsCKernelLevel := psCKernelNormalizeLevel leftInput
  let right : PsCKernelLevel := psCKernelNormalizeLevel rightInput
  if psCKernelLevelEqStructural left right then
    true
  else if psCKernelLevelIsZero right then
    true
  else
    match right with
    | PsCKernelLevel.max rightLeft rightRight =>
        if psCKernelLevelGeq left rightLeft then
          psCKernelLevelGeq left rightRight
        else
          false
    | _ =>
        match left with
        | PsCKernelLevel.max leftLeft leftRight =>
            if psCKernelLevelGeq leftLeft right then
              true
            else if psCKernelLevelGeq leftRight right then
              true
            else
              psCKernelLevelGeqRemainder psCKernelLevelGeq left right
        | _ =>
            psCKernelLevelGeqRemainder psCKernelLevelGeq left right

def psCKernelLevelLe
    (left : PsCKernelLevel)
    (right : PsCKernelLevel) : Bool :=
  psCKernelLevelGeq right left
