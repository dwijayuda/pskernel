import Ps.Core.Equality

inductive PsKernelOrder where
  | less
  | equal
  | greater

inductive PsKernelNameComponent where
  | text (value : String)
  | numeral (value : Nat)

structure PsKernelLevelOffset where
  base : PsLevel
  offset : Nat

structure PsKernelExplicitSplit where
  prefix : List PsLevel
  rest : List PsLevel

def psKernelNatCompare (left : Nat) (right : Nat) : PsKernelOrder :=
  if left < right then
    PsKernelOrder.less
  else if right < left then
    PsKernelOrder.greater
  else
    PsKernelOrder.equal

def psKernelCharCompare (left : Char) (right : Char) : PsKernelOrder :=
  psKernelNatCompare left.toNat right.toNat

def psKernelCharListCompare : List Char -> List Char -> PsKernelOrder
  | [], [] => PsKernelOrder.equal
  | [], _ :: _ => PsKernelOrder.less
  | _ :: _, [] => PsKernelOrder.greater
  | left :: leftRest, right :: rightRest =>
      match psKernelCharCompare left right with
      | PsKernelOrder.equal =>
          psKernelCharListCompare leftRest rightRest
      | order => order

def psKernelStringCompare (left : String) (right : String) : PsKernelOrder :=
  psKernelCharListCompare left.toList right.toList

def psKernelNameComponents : PsName -> List PsKernelNameComponent
  | .anonymous => []
  | .str parent value =>
      psKernelNameComponents parent ++ [PsKernelNameComponent.text value]
  | .num parent value =>
      psKernelNameComponents parent ++ [PsKernelNameComponent.numeral value]

def psKernelNameComponentCompare
    (left : PsKernelNameComponent)
    (right : PsKernelNameComponent) : PsKernelOrder :=
  match left, right with
  | .numeral leftValue, .numeral rightValue =>
      psKernelNatCompare leftValue rightValue
  | .text leftValue, .text rightValue =>
      psKernelStringCompare leftValue rightValue
  | .numeral _, .text _ => PsKernelOrder.less
  | .text _, .numeral _ => PsKernelOrder.greater

def psKernelNameComponentListCompare :
    List PsKernelNameComponent ->
    List PsKernelNameComponent ->
    PsKernelOrder
  | [], [] => PsKernelOrder.equal
  | [], _ :: _ => PsKernelOrder.less
  | _ :: _, [] => PsKernelOrder.greater
  | left :: leftRest, right :: rightRest =>
      match psKernelNameComponentCompare left right with
      | PsKernelOrder.equal =>
          psKernelNameComponentListCompare leftRest rightRest
      | order => order

def psKernelNameCompare (left : PsName) (right : PsName) : PsKernelOrder :=
  if psNameEq left right then
    PsKernelOrder.equal
  else
    psKernelNameComponentListCompare
      (psKernelNameComponents left)
      (psKernelNameComponents right)

def psKernelLevelIsZero : PsLevel -> Bool
  | .zero => true
  | _ => false

def psKernelLevelIsNotZero : PsLevel -> Bool
  | .succ _ => true
  | .max left right =>
      psKernelLevelIsNotZero left || psKernelLevelIsNotZero right
  | .imax _ right =>
      psKernelLevelIsNotZero right
  | _ => false

def psKernelLevelNormalizesToZero : PsLevel -> Bool
  | .zero => true
  | .max left right =>
      psKernelLevelNormalizesToZero left
        && psKernelLevelNormalizesToZero right
  | .imax _ right =>
      psKernelLevelNormalizesToZero right
  | _ => false

def psKernelLevelToOffset : PsLevel -> PsKernelLevelOffset
  | .succ level =>
      let result := psKernelLevelToOffset level
      { base := result.base, offset := result.offset + 1 }
  | level =>
      { base := level, offset := 0 }

def psKernelLevelAddOffset (level : PsLevel) : Nat -> PsLevel
  | 0 => level
  | amount + 1 =>
      PsLevel.succ (psKernelLevelAddOffset level amount)

def psKernelLevelMkMax (left : PsLevel) (right : PsLevel) : PsLevel :=
  if psLevelStructuralEq left right then
    left
  else if psKernelLevelIsZero left then
    right
  else if psKernelLevelIsZero right then
    left
  else
    match right with
    | .max a b =>
        if psLevelStructuralEq a left || psLevelStructuralEq b left then
          right
        else
          match left with
          | .max c d =>
              if psLevelStructuralEq c right || psLevelStructuralEq d right then
                left
              else
                let leftOffset := psKernelLevelToOffset left
                let rightOffset := psKernelLevelToOffset right
                if psLevelStructuralEq leftOffset.base rightOffset.base then
                  if rightOffset.offset < leftOffset.offset then left else right
                else
                  PsLevel.max left right
          | _ =>
              let leftOffset := psKernelLevelToOffset left
              let rightOffset := psKernelLevelToOffset right
              if psLevelStructuralEq leftOffset.base rightOffset.base then
                if rightOffset.offset < leftOffset.offset then left else right
              else
                PsLevel.max left right
    | _ =>
        match left with
        | .max a b =>
            if psLevelStructuralEq a right || psLevelStructuralEq b right then
              left
            else
              let leftOffset := psKernelLevelToOffset left
              let rightOffset := psKernelLevelToOffset right
              if psLevelStructuralEq leftOffset.base rightOffset.base then
                if rightOffset.offset < leftOffset.offset then left else right
              else
                PsLevel.max left right
        | _ =>
            let leftOffset := psKernelLevelToOffset left
            let rightOffset := psKernelLevelToOffset right
            if psLevelStructuralEq leftOffset.base rightOffset.base then
              if rightOffset.offset < leftOffset.offset then left else right
            else
              PsLevel.max left right

def psKernelLevelMkIMax (left : PsLevel) (right : PsLevel) : PsLevel :=
  if psKernelLevelIsNotZero right then
    psKernelLevelMkMax left right
  else if psKernelLevelIsZero right then
    right
  else if psKernelLevelIsZero left then
    right
  else
    match left with
    | .succ value =>
        if psKernelLevelIsZero value then
          right
        else if psLevelStructuralEq left right then
          left
        else
          PsLevel.imax left right
    | _ =>
        if psLevelStructuralEq left right then
          left
        else
          PsLevel.imax left right

def psKernelLevelPushMaxArgs : PsLevel -> List PsLevel
  | .max left right =>
      psKernelLevelPushMaxArgs left ++ psKernelLevelPushMaxArgs right
  | level => [level]

def psKernelLevelKindRank : PsLevel -> Nat
  | .zero => 0
  | .succ _ => 1
  | .max _ _ => 2
  | .imax _ _ => 3
  | .param _ => 4
  | .mvar _ => 5

def psKernelLevelIsExplicit (level : PsLevel) : Bool :=
  psKernelLevelIsZero (psKernelLevelToOffset level).base

partial def psKernelLevelNormCompare
    (left : PsLevel)
    (right : PsLevel) : PsKernelOrder :=
  if psLevelStructuralEq left right then
    PsKernelOrder.equal
  else
    let leftOffset := psKernelLevelToOffset left
    let rightOffset := psKernelLevelToOffset right
    if psLevelStructuralEq leftOffset.base rightOffset.base then
      psKernelNatCompare leftOffset.offset rightOffset.offset
    else
      let leftRank := psKernelLevelKindRank leftOffset.base
      let rightRank := psKernelLevelKindRank rightOffset.base
      match psKernelNatCompare leftRank rightRank with
      | PsKernelOrder.less => PsKernelOrder.less
      | PsKernelOrder.greater => PsKernelOrder.greater
      | PsKernelOrder.equal =>
          match leftOffset.base, rightOffset.base with
          | .param leftName, .param rightName =>
              psKernelNameCompare leftName rightName
          | .mvar leftId, .mvar rightId =>
              psKernelNatCompare leftId rightId
          | .max leftA leftB, .max rightA rightB =>
              match psKernelLevelNormCompare leftA rightA with
              | PsKernelOrder.equal =>
                  psKernelLevelNormCompare leftB rightB
              | order => order
          | .imax leftA leftB, .imax rightA rightB =>
              match psKernelLevelNormCompare leftA rightA with
              | PsKernelOrder.equal =>
                  psKernelLevelNormCompare leftB rightB
              | order => order
          | _, _ => PsKernelOrder.equal

partial def psKernelLevelInsertSorted
    (level : PsLevel) : List PsLevel -> List PsLevel
  | [] => [level]
  | current :: rest =>
      match psKernelLevelNormCompare level current with
      | PsKernelOrder.less => level :: current :: rest
      | PsKernelOrder.equal => level :: current :: rest
      | PsKernelOrder.greater =>
          current :: psKernelLevelInsertSorted level rest

def psKernelLevelSort : List PsLevel -> List PsLevel
  | [] => []
  | level :: rest =>
      psKernelLevelInsertSorted level (psKernelLevelSort rest)

def psKernelLevelSplitExplicit : List PsLevel -> PsKernelExplicitSplit
  | [] => { prefix := [], rest := [] }
  | level :: rest =>
      if psKernelLevelIsExplicit level then
        let split := psKernelLevelSplitExplicit rest
        { prefix := level :: split.prefix, rest := split.rest }
      else
        { prefix := [], rest := level :: rest }

def psKernelLevelLast : List PsLevel -> Option PsLevel
  | [] => none
  | [level] => some level
  | _ :: rest => psKernelLevelLast rest

def psKernelLevelAnyOffsetAtLeast
    (minimum : Nat) : List PsLevel -> Bool
  | [] => false
  | level :: rest =>
      if minimum <= (psKernelLevelToOffset level).offset then
        true
      else
        psKernelLevelAnyOffsetAtLeast minimum rest

def psKernelLevelPrepareSortedMax
    (levels : List PsLevel) : List PsLevel :=
  let split := psKernelLevelSplitExplicit levels
  match psKernelLevelLast split.prefix with
  | none => split.rest
  | some explicitLevel =>
      let explicitOffset := (psKernelLevelToOffset explicitLevel).offset
      if psKernelLevelAnyOffsetAtLeast explicitOffset split.rest then
        split.rest
      else
        explicitLevel :: split.rest

def psKernelLevelCollapseFrom
    (current : PsLevel) : List PsLevel -> List PsLevel
  | [] => [current]
  | next :: rest =>
      let currentOffset := psKernelLevelToOffset current
      let nextOffset := psKernelLevelToOffset next
      if psLevelStructuralEq currentOffset.base nextOffset.base then
        if currentOffset.offset < nextOffset.offset then
          psKernelLevelCollapseFrom next rest
        else
          psKernelLevelCollapseFrom current rest
      else
        current :: psKernelLevelCollapseFrom next rest

def psKernelLevelCollapseSameBase : List PsLevel -> List PsLevel
  | [] => []
  | level :: rest =>
      psKernelLevelCollapseFrom level rest

def psKernelLevelAddOffsetList
    (amount : Nat) : List PsLevel -> List PsLevel
  | [] => []
  | level :: rest =>
      psKernelLevelAddOffset level amount
        :: psKernelLevelAddOffsetList amount rest

def psKernelLevelFoldMax : List PsLevel -> PsLevel
  | [] => PsLevel.zero
  | [level] => level
  | level :: rest =>
      psKernelLevelMkMax level (psKernelLevelFoldMax rest)

partial def psKernelLevelNormalize (level : PsLevel) : PsLevel :=
  let outer := psKernelLevelToOffset level
  match outer.base with
  | .zero => level
  | .param _ => level
  | .mvar _ => level
  | .succ _ => level
  | .imax left right =>
      psKernelLevelAddOffset
        (psKernelLevelMkIMax
          (psKernelLevelNormalize left)
          (psKernelLevelNormalize right))
        outer.offset
  | .max _ _ =>
      let leaves := psKernelLevelPushMaxArgs outer.base
      let normalized := psKernelLevelNormalizeList leaves
      let flattened := psKernelLevelFlattenNormalized normalized
      let sorted := psKernelLevelSort flattened
      let prepared := psKernelLevelPrepareSortedMax sorted
      let collapsed := psKernelLevelCollapseSameBase prepared
      let shifted := psKernelLevelAddOffsetList outer.offset collapsed
      psKernelLevelFoldMax shifted
where
  psKernelLevelNormalizeList : List PsLevel -> List PsLevel
    | [] => []
    | value :: rest =>
        psKernelLevelNormalize value :: psKernelLevelNormalizeList rest

  psKernelLevelFlattenNormalized : List PsLevel -> List PsLevel
    | [] => []
    | value :: rest =>
        psKernelLevelPushMaxArgs value
          ++ psKernelLevelFlattenNormalized rest

partial def psKernelLevelGeqCore
    (left : PsLevel)
    (right : PsLevel) : Bool :=
  if psLevelStructuralEq left right || psKernelLevelIsZero right then
    true
  else
    match right with
    | .max rightA rightB =>
        psKernelLevelGeqCore left (psKernelLevelNormalize rightA)
          && psKernelLevelGeqCore left (psKernelLevelNormalize rightB)
    | _ =>
        let positiveMax :=
          match left with
          | .max leftA leftB =>
              psKernelLevelGeqCore
                  (psKernelLevelNormalize leftA)
                  right
                || psKernelLevelGeqCore
                  (psKernelLevelNormalize leftB)
                  right
          | _ => false
        if positiveMax then
          true
        else
          match right with
          | .imax rightA rightB =>
              psKernelLevelGeqCore left (psKernelLevelNormalize rightA)
                && psKernelLevelGeqCore left (psKernelLevelNormalize rightB)
          | _ =>
              match left with
              | .imax _ leftB =>
                  psKernelLevelGeqCore
                    (psKernelLevelNormalize leftB)
                    right
              | _ =>
                  let leftOffset := psKernelLevelToOffset left
                  let rightOffset := psKernelLevelToOffset right
                  if
                      psLevelStructuralEq leftOffset.base rightOffset.base
                        || psKernelLevelIsZero rightOffset.base then
                    rightOffset.offset <= leftOffset.offset
                  else if
                      leftOffset.offset == rightOffset.offset
                        && 0 < leftOffset.offset then
                    psKernelLevelGeqCore
                      (psKernelLevelNormalize leftOffset.base)
                      (psKernelLevelNormalize rightOffset.base)
                  else
                    false

def psKernelLevelGeq (left : PsLevel) (right : PsLevel) : Bool :=
  psKernelLevelGeqCore
    (psKernelLevelNormalize left)
    (psKernelLevelNormalize right)

def psKernelLevelLe (left : PsLevel) (right : PsLevel) : Bool :=
  psKernelLevelGeq right left

def psKernelLevelEquivalent (left : PsLevel) (right : PsLevel) : Bool :=
  if psLevelStructuralEq left right then
    true
  else
    psLevelStructuralEq
      (psKernelLevelNormalize left)
      (psKernelLevelNormalize right)
