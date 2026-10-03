import Ps.KernelSelfHost.Name

inductive PsKernelLevel where
  | zero
  | succ (of : PsKernelLevel)
  | max (left : PsKernelLevel) (right : PsKernelLevel)
  | imax (left : PsKernelLevel) (right : PsKernelLevel)
  | param (name : PsKernelName)
  | mvar (name : PsKernelName)

def psKernelLevelEq
    (left : PsKernelLevel) :
    PsKernelLevel -> Bool :=
  match left with
  | PsKernelLevel.zero =>
      fun (right : PsKernelLevel) =>
        match right with
        | PsKernelLevel.zero => true
        | _ => false
  | PsKernelLevel.succ leftValue =>
      let smaller : PsKernelLevel -> Bool :=
        psKernelLevelEq leftValue;
      fun (right : PsKernelLevel) =>
        match right with
        | PsKernelLevel.succ rightValue =>
            smaller rightValue
        | _ => false
  | PsKernelLevel.max leftA leftB =>
      let compareLeft : PsKernelLevel -> Bool :=
        psKernelLevelEq leftA;
      let compareRight : PsKernelLevel -> Bool :=
        psKernelLevelEq leftB;
      fun (right : PsKernelLevel) =>
        match right with
        | PsKernelLevel.max rightA rightB =>
            if compareLeft rightA then
              compareRight rightB
            else
              false
        | _ => false
  | PsKernelLevel.imax leftA leftB =>
      let compareLeft : PsKernelLevel -> Bool :=
        psKernelLevelEq leftA;
      let compareRight : PsKernelLevel -> Bool :=
        psKernelLevelEq leftB;
      fun (right : PsKernelLevel) =>
        match right with
        | PsKernelLevel.imax rightA rightB =>
            if compareLeft rightA then
              compareRight rightB
            else
              false
        | _ => false
  | PsKernelLevel.param leftName =>
      fun (right : PsKernelLevel) =>
        match right with
        | PsKernelLevel.param rightName =>
            psKernelNameEq leftName rightName
        | _ => false
  | PsKernelLevel.mvar leftName =>
      fun (right : PsKernelLevel) =>
        match right with
        | PsKernelLevel.mvar rightName =>
            psKernelNameEq leftName rightName
        | _ => false

def psKernelLevelIsZero
    (level : PsKernelLevel) : Bool :=
  match level with
  | PsKernelLevel.zero => true
  | _ => false

def psKernelLevelIsNotZero
    (level : PsKernelLevel) : Bool :=
  match level with
  | PsKernelLevel.succ _ =>
      true
  | PsKernelLevel.max left right =>
      if psKernelLevelIsNotZero left then
        true
      else
        psKernelLevelIsNotZero right
  | PsKernelLevel.imax _ right =>
      psKernelLevelIsNotZero right
  | _ =>
      false

def psKernelLevelNormalizesToZero
    (level : PsKernelLevel) : Bool :=
  match level with
  | PsKernelLevel.zero =>
      true
  | PsKernelLevel.max left right =>
      if psKernelLevelNormalizesToZero left then
        psKernelLevelNormalizesToZero right
      else
        false
  | PsKernelLevel.imax _ right =>
      psKernelLevelNormalizesToZero right
  | _ =>
      false

def psKernelLevelToOffset
    (level : PsKernelLevel) :
    Prod PsKernelLevel Nat :=
  match level with
  | PsKernelLevel.succ inner =>
      let pair := psKernelLevelToOffset inner;
      Prod.mk pair.fst (pair.snd + 1)
  | _ =>
      Prod.mk level 0

def psKernelLevelAddOffset
    (level : PsKernelLevel)
    (amount : Nat) : PsKernelLevel :=
  match amount with
  | Nat.zero =>
      level
  | Nat.succ rest =>
      PsKernelLevel.succ
        (psKernelLevelAddOffset level rest)

def psKernelLevelIsExplicit
    (level : PsKernelLevel) : Bool :=
  psKernelLevelIsZero
    (psKernelLevelToOffset level).fst

def psKernelLevelMkMax
    (left : PsKernelLevel)
    (right : PsKernelLevel) : PsKernelLevel :=
  if
      if psKernelLevelIsExplicit left then
        psKernelLevelIsExplicit right
      else
        false then
    let leftPair := psKernelLevelToOffset left;
    let rightPair := psKernelLevelToOffset right;
    if psKernelNatGe leftPair.snd rightPair.snd then left else right
  else if psKernelLevelEq left right then
    left
  else if psKernelLevelIsZero left then
    right
  else if psKernelLevelIsZero right then
    left
  else
    match right with
    | PsKernelLevel.max rightLeft rightRight =>
        if
            if psKernelLevelEq rightLeft left then
              true
            else
              psKernelLevelEq rightRight left then
          right
        else
          match left with
          | PsKernelLevel.max leftLeft leftRight =>
              if
                  if psKernelLevelEq leftLeft right then
                    true
                  else
                    psKernelLevelEq leftRight right then
                left
              else
                let leftPair := psKernelLevelToOffset left;
                let rightPair := psKernelLevelToOffset right;
                if psKernelLevelEq leftPair.fst rightPair.fst then
                  if psKernelNatGt leftPair.snd rightPair.snd then left else right
                else
                  PsKernelLevel.max left right
          | _ =>
              let leftPair := psKernelLevelToOffset left;
              let rightPair := psKernelLevelToOffset right;
              if psKernelLevelEq leftPair.fst rightPair.fst then
                if psKernelNatGt leftPair.snd rightPair.snd then left else right
              else
                PsKernelLevel.max left right
    | _ =>
        match left with
        | PsKernelLevel.max leftLeft leftRight =>
            if
                if psKernelLevelEq leftLeft right then
                  true
                else
                  psKernelLevelEq leftRight right then
              left
            else
              let leftPair := psKernelLevelToOffset left;
              let rightPair := psKernelLevelToOffset right;
              if psKernelLevelEq leftPair.fst rightPair.fst then
                if psKernelNatGt leftPair.snd rightPair.snd then left else right
              else
                PsKernelLevel.max left right
        | _ =>
            let leftPair := psKernelLevelToOffset left;
            let rightPair := psKernelLevelToOffset right;
            if psKernelLevelEq leftPair.fst rightPair.fst then
              if psKernelNatGt leftPair.snd rightPair.snd then left else right
            else
              PsKernelLevel.max left right

def psKernelLevelMkIMax
    (left : PsKernelLevel)
    (right : PsKernelLevel) : PsKernelLevel :=
  if psKernelLevelIsNotZero right then
    psKernelLevelMkMax left right
  else if psKernelLevelIsZero right then
    right
  else if psKernelLevelIsZero left then
    right
  else
    match left with
    | PsKernelLevel.succ PsKernelLevel.zero =>
        right
    | _ =>
        if psKernelLevelEq left right then
          left
        else
          PsKernelLevel.imax left right

def psKernelLevelKindRank
    (level : PsKernelLevel) : Nat :=
  match level with
  | PsKernelLevel.zero => 0
  | PsKernelLevel.succ _ => 1
  | PsKernelLevel.max _ _ => 2
  | PsKernelLevel.imax _ _ => 3
  | PsKernelLevel.param _ => 4
  | PsKernelLevel.mvar _ => 5

partial def psKernelLevelNormCmp
    (left : PsKernelLevel)
    (right : PsKernelLevel) : Ordering :=
  if psKernelLevelEq left right then
    Ordering.eq
  else
    let leftPair := psKernelLevelToOffset left;
    let rightPair := psKernelLevelToOffset right;
    let leftRoot := leftPair.fst;
    let rightRoot := rightPair.fst;
    if psKernelLevelEq leftRoot rightRoot then
      psKernelNatCmp leftPair.snd rightPair.snd
    else if
        psKernelNatLt
          (psKernelLevelKindRank leftRoot)
          (psKernelLevelKindRank rightRoot) then
      Ordering.lt
    else if
        psKernelNatGt
          (psKernelLevelKindRank leftRoot)
          (psKernelLevelKindRank rightRoot) then
      Ordering.gt
    else
      match leftRoot with
      | PsKernelLevel.param leftName =>
          match rightRoot with
          | PsKernelLevel.param rightName =>
              psKernelNameCmp leftName rightName
          | _ =>
              Ordering.eq
      | PsKernelLevel.mvar leftName =>
          match rightRoot with
          | PsKernelLevel.mvar rightName =>
              psKernelNameCmp leftName rightName
          | _ =>
              Ordering.eq
      | PsKernelLevel.max leftA leftB =>
          match rightRoot with
          | PsKernelLevel.max rightA rightB =>
              match
                  psKernelLevelNormCmp
                    leftA
                    rightA with
              | Ordering.eq =>
                  psKernelLevelNormCmp
                    leftB
                    rightB
              | ordering =>
                  ordering
          | _ =>
              Ordering.eq
      | PsKernelLevel.imax leftA leftB =>
          match rightRoot with
          | PsKernelLevel.imax rightA rightB =>
              match
                  psKernelLevelNormCmp
                    leftA
                    rightA with
              | Ordering.eq =>
                  psKernelLevelNormCmp
                    leftB
                    rightB
              | ordering =>
                  ordering
          | _ =>
              Ordering.eq
      | _ =>
          Ordering.eq

def psKernelLevelListAppend
    (left : List PsKernelLevel)
    (right : List PsKernelLevel) :
    List PsKernelLevel :=
  match left with
  | List.nil =>
      right
  | List.cons head tail =>
      List.cons
        head
        (psKernelLevelListAppend tail right)

def psKernelLevelFlattenMax
    (level : PsKernelLevel) :
    List PsKernelLevel :=
  match level with
  | PsKernelLevel.max left right =>
      psKernelLevelListAppend
        (psKernelLevelFlattenMax left)
        (psKernelLevelFlattenMax right)
  | _ =>
      List.cons level List.nil

def psKernelLevelInsertSorted
    (value : PsKernelLevel)
    (values : List PsKernelLevel) :
    List PsKernelLevel :=
  match values with
  | List.nil =>
      List.cons value List.nil
  | List.cons head tail =>
      match psKernelLevelNormCmp value head with
      | Ordering.lt =>
          List.cons
            value
            (List.cons head tail)
      | Ordering.eq =>
          List.cons
            value
            (List.cons head tail)
      | Ordering.gt =>
          List.cons
            head
            (psKernelLevelInsertSorted
              value
              tail)

def psKernelLevelSortLevelsWorker
    (remaining : List PsKernelLevel) :
    List PsKernelLevel -> List PsKernelLevel :=
  match remaining with
  | List.nil =>
      fun (acc : List PsKernelLevel) =>
        acc
  | List.cons head tail =>
      let smaller :
          List PsKernelLevel -> List PsKernelLevel :=
        psKernelLevelSortLevelsWorker tail;
      fun (acc : List PsKernelLevel) =>
        smaller
          (psKernelLevelInsertSorted head acc)

def psKernelLevelSortLevels
    (values : List PsKernelLevel) :
    List PsKernelLevel :=
  psKernelLevelSortLevelsWorker
    values
    List.nil

def psKernelLevelTakeExplicit
    (values : List PsKernelLevel) :
    List PsKernelLevel :=
  match values with
  | List.nil =>
      List.nil
  | List.cons head tail =>
      if psKernelLevelIsExplicit head then
        List.cons
          head
          (psKernelLevelTakeExplicit tail)
      else
        List.nil

def psKernelLevelDropExplicit
    (values : List PsKernelLevel) :
    List PsKernelLevel :=
  match values with
  | List.nil =>
      List.nil
  | List.cons head tail =>
      if psKernelLevelIsExplicit head then
        psKernelLevelDropExplicit tail
      else
        values

def psKernelLevelLast
    (values : List PsKernelLevel) :
    Option PsKernelLevel :=
  match values with
  | List.nil =>
      Option.none
  | List.cons head tail =>
      match tail with
      | List.nil =>
          Option.some head
      | List.cons _ _ =>
          psKernelLevelLast tail

def psKernelLevelAnyOffsetAtLeast
    (values : List PsKernelLevel)
    (minimum : Nat) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons head tail =>
      if psKernelNatGe (psKernelLevelToOffset head).snd minimum then
        true
      else
        psKernelLevelAnyOffsetAtLeast
          tail
          minimum

def psKernelLevelTrimExplicit
    (values : List PsKernelLevel) :
    List PsKernelLevel :=
  let explicit := psKernelLevelTakeExplicit values;
  let rest := psKernelLevelDropExplicit values;
  match psKernelLevelLast explicit with
  | Option.none =>
      values
  | Option.some maximum =>
      let amount := (psKernelLevelToOffset maximum).snd;
      if psKernelLevelAnyOffsetAtLeast rest amount then
        rest
      else
        List.cons maximum rest

def psKernelLevelDedupOffsetsWorkerCore
    (rest : List PsKernelLevel) :
    PsKernelLevel ->
    List PsKernelLevel ->
    List PsKernelLevel :=
  match rest with
  | List.nil =>
      fun
        (current : PsKernelLevel)
        (rev : List PsKernelLevel) =>
        List.reverse
          (List.cons current rev)
  | List.cons next tail =>
      let smaller :
          PsKernelLevel ->
          List PsKernelLevel ->
          List PsKernelLevel :=
        psKernelLevelDedupOffsetsWorkerCore tail;
      fun
        (current : PsKernelLevel)
        (rev : List PsKernelLevel) =>
        if
            psKernelLevelEq
              (psKernelLevelToOffset current).fst
              (psKernelLevelToOffset next).fst then
          smaller next rev
        else
          smaller
            next
            (List.cons current rev)

def psKernelLevelDedupOffsetsWorker
    (current : PsKernelLevel)
    (rest : List PsKernelLevel)
    (rev : List PsKernelLevel) :
    List PsKernelLevel :=
  psKernelLevelDedupOffsetsWorkerCore
    rest
    current
    rev

def psKernelLevelDedupOffsets
    (values : List PsKernelLevel) :
    List PsKernelLevel :=
  match values with
  | List.nil =>
      List.nil
  | List.cons head tail =>
      psKernelLevelDedupOffsetsWorker
        head
        tail
        List.nil

def psKernelLevelMkMaxList
    (values : List PsKernelLevel) :
    PsKernelLevel :=
  match values with
  | List.nil =>
      PsKernelLevel.zero
  | List.cons head tail =>
      match tail with
      | List.nil =>
          head
      | List.cons _ _ =>
          psKernelLevelMkMax
            head
            (psKernelLevelMkMaxList tail)

partial def psKernelLevelNormalize
    (level : PsKernelLevel) : PsKernelLevel :=
  let pair := psKernelLevelToOffset level;
  let root := pair.fst;
  let amount := pair.snd;
  match root with
  | PsKernelLevel.zero =>
      level
  | PsKernelLevel.param _ =>
      level
  | PsKernelLevel.mvar _ =>
      level
  | PsKernelLevel.succ _ =>
      level
  | PsKernelLevel.imax left right =>
      psKernelLevelAddOffset
        (psKernelLevelMkIMax
          (psKernelLevelNormalize left)
          (psKernelLevelNormalize right))
        amount
  | PsKernelLevel.max _ _ =>
      let rec normalizeList
          (values : List PsKernelLevel) :
          List PsKernelLevel :=
        match values with
        | List.nil =>
            List.nil
        | List.cons head tail =>
            psKernelLevelListAppend
              (psKernelLevelFlattenMax
                (psKernelLevelNormalize head))
              (normalizeList tail);
      let normalized :=
        normalizeList
          (psKernelLevelFlattenMax root);
      let sorted :=
        psKernelLevelSortLevels normalized;
      let trimmed :=
        psKernelLevelTrimExplicit sorted;
      let unique :=
        psKernelLevelDedupOffsets trimmed;
      psKernelLevelAddOffset
        (psKernelLevelMkMaxList unique)
        amount

partial def psKernelLevelGeqCore
    (left : PsKernelLevel)
    (right : PsKernelLevel) : Bool :=
  let fallback :=
    fun
      (fallbackLeft : PsKernelLevel)
      (fallbackRight : PsKernelLevel) =>
      match fallbackRight with
      | PsKernelLevel.imax rightA rightB =>
          if psKernelLevelGeqCore fallbackLeft rightA then
            psKernelLevelGeqCore fallbackLeft rightB
          else
            false
      | _ =>
          match fallbackLeft with
          | PsKernelLevel.imax _ leftRight =>
              psKernelLevelGeqCore
                leftRight
                fallbackRight
          | _ =>
              let leftPair :=
                psKernelLevelToOffset fallbackLeft;
              let rightPair :=
                psKernelLevelToOffset fallbackRight;
              if
                  if psKernelLevelEq
                      leftPair.fst
                      rightPair.fst then
                    true
                  else
                    psKernelLevelIsZero
                      rightPair.fst then
                psKernelNatGe leftPair.snd rightPair.snd
              else if
                  if Nat.beq leftPair.snd rightPair.snd then
                    psKernelNatGt leftPair.snd 0
                  else
                    false then
                psKernelLevelGeqCore
                  leftPair.fst
                  rightPair.fst
              else
                false;
  if
      if psKernelLevelEq left right then
        true
      else
        psKernelLevelIsZero right then
    true
  else
    match right with
    | PsKernelLevel.max rightA rightB =>
        if psKernelLevelGeqCore left rightA then
          psKernelLevelGeqCore left rightB
        else
          false
    | _ =>
        match left with
        | PsKernelLevel.max leftA leftB =>
            if
                if psKernelLevelGeqCore leftA right then
                  true
                else
                  psKernelLevelGeqCore leftB right then
              true
            else
              fallback left right
        | _ =>
            fallback left right

def psKernelLevelLe
    (left : PsKernelLevel)
    (right : PsKernelLevel) : Bool :=
  psKernelLevelGeqCore
    (psKernelLevelNormalize right)
    (psKernelLevelNormalize left)

def psKernelLevelEquivalent
    (left : PsKernelLevel)
    (right : PsKernelLevel) : Bool :=
  if psKernelLevelEq left right then
    true
  else
    psKernelLevelEq
      (psKernelLevelNormalize left)
      (psKernelLevelNormalize right)

def psKernelNameLookupLevel
    (name : PsKernelName)
    (params : List PsKernelName) :
    List PsKernelLevel -> Option PsKernelLevel :=
  match params with
  | List.nil =>
      fun (_values : List PsKernelLevel) =>
        Option.none
  | List.cons param restParams =>
      let smaller :
          List PsKernelLevel -> Option PsKernelLevel :=
        psKernelNameLookupLevel
          name
          restParams;
      fun (values : List PsKernelLevel) =>
        match values with
        | List.nil =>
            Option.none
        | List.cons value restValues =>
            if psKernelNameEq name param then
              Option.some value
            else
              smaller restValues

def psKernelLevelInstantiateParams
    (root : PsKernelLevel)
    (params : List PsKernelName)
    (values : List PsKernelLevel) :
    PsKernelLevel :=
  match root with
  | PsKernelLevel.zero =>
      root
  | PsKernelLevel.mvar _ =>
      root
  | PsKernelLevel.param name =>
      match
          psKernelNameLookupLevel
            name
            params
            values with
      | Option.some value =>
          value
      | Option.none =>
          root
  | PsKernelLevel.succ inner =>
      let changed :=
        psKernelLevelInstantiateParams
          inner
          params
          values;
      if psKernelLevelEq inner changed then
        root
      else
        PsKernelLevel.succ changed
  | PsKernelLevel.max left right =>
      let changedLeft :=
        psKernelLevelInstantiateParams
          left
          params
          values;
      let changedRight :=
        psKernelLevelInstantiateParams
          right
          params
          values;
      if
          if psKernelLevelEq left changedLeft then
            psKernelLevelEq right changedRight
          else
            false then
        root
      else
        psKernelLevelMkMax
          changedLeft
          changedRight
  | PsKernelLevel.imax left right =>
      let changedLeft :=
        psKernelLevelInstantiateParams
          left
          params
          values;
      let changedRight :=
        psKernelLevelInstantiateParams
          right
          params
          values;
      if
          if psKernelLevelEq left changedLeft then
            psKernelLevelEq right changedRight
          else
            false then
        root
      else
        psKernelLevelMkIMax
          changedLeft
          changedRight
