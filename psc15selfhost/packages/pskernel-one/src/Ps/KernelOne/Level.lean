import Ps.KernelOne.Name

inductive PsKernelOneLevel where
  | zero
  | succ (of : PsKernelOneLevel)
  | max (left : PsKernelOneLevel) (right : PsKernelOneLevel)
  | imax (left : PsKernelOneLevel) (right : PsKernelOneLevel)
  | param (name : PsKernelOneName)
  | mvar (name : PsKernelOneName)

inductive PsKernelOneLevelSubst where
  | nil
  | cons
      (name : PsKernelOneName)
      (value : PsKernelOneLevel)
      (rest : PsKernelOneLevelSubst)

def psKernelOneLevelEq
    (left : PsKernelOneLevel) : PsKernelOneLevel -> Bool :=
  match left with
  | PsKernelOneLevel.zero =>
      fun (right : PsKernelOneLevel) =>
        match right with
        | PsKernelOneLevel.zero => true
        | _ => false
  | PsKernelOneLevel.succ leftChild =>
      let childEq : PsKernelOneLevel -> Bool :=
        psKernelOneLevelEq leftChild;
      fun (right : PsKernelOneLevel) =>
        match right with
        | PsKernelOneLevel.succ rightChild => childEq rightChild
        | _ => false
  | PsKernelOneLevel.max leftA leftB =>
      let leftEq : PsKernelOneLevel -> Bool :=
        psKernelOneLevelEq leftA;
      let rightEq : PsKernelOneLevel -> Bool :=
        psKernelOneLevelEq leftB;
      fun (right : PsKernelOneLevel) =>
        match right with
        | PsKernelOneLevel.max rightA rightB =>
            if leftEq rightA then
              rightEq rightB
            else
              false
        | _ => false
  | PsKernelOneLevel.imax leftA leftB =>
      let leftEq : PsKernelOneLevel -> Bool :=
        psKernelOneLevelEq leftA;
      let rightEq : PsKernelOneLevel -> Bool :=
        psKernelOneLevelEq leftB;
      fun (right : PsKernelOneLevel) =>
        match right with
        | PsKernelOneLevel.imax rightA rightB =>
            if leftEq rightA then
              rightEq rightB
            else
              false
        | _ => false
  | PsKernelOneLevel.param leftName =>
      fun (right : PsKernelOneLevel) =>
        match right with
        | PsKernelOneLevel.param rightName =>
            psKernelOneNameEq leftName rightName
        | _ => false
  | PsKernelOneLevel.mvar leftName =>
      fun (right : PsKernelOneLevel) =>
        match right with
        | PsKernelOneLevel.mvar rightName =>
            psKernelOneNameEq leftName rightName
        | _ => false

def psKernelOneLevelIsZero (level : PsKernelOneLevel) : Bool :=
  match level with
  | PsKernelOneLevel.zero => true
  | _ => false

def psKernelOneLevelIsNotZero (level : PsKernelOneLevel) : Bool :=
  match level with
  | PsKernelOneLevel.succ _ => true
  | PsKernelOneLevel.max left right =>
      if psKernelOneLevelIsNotZero left then
        true
      else
        psKernelOneLevelIsNotZero right
  | PsKernelOneLevel.imax _ right =>
      psKernelOneLevelIsNotZero right
  | _ => false

def psKernelOneLevelNormalizesToZero
    (level : PsKernelOneLevel) : Bool :=
  match level with
  | PsKernelOneLevel.zero => true
  | PsKernelOneLevel.max left right =>
      if psKernelOneLevelNormalizesToZero left then
        psKernelOneLevelNormalizesToZero right
      else
        false
  | PsKernelOneLevel.imax _ right =>
      psKernelOneLevelNormalizesToZero right
  | _ => false

def psKernelOneLevelAddOffset
    (level : PsKernelOneLevel)
    (offset : Nat) : PsKernelOneLevel :=
  match offset with
  | Nat.zero => level
  | Nat.succ remaining =>
      PsKernelOneLevel.succ
        (psKernelOneLevelAddOffset level remaining)

def psKernelOneLevelExplicitOffset?
    (level : PsKernelOneLevel) : PsKernelOneOption Nat :=
  match level with
  | PsKernelOneLevel.zero => PsKernelOneOption.some Nat.zero
  | PsKernelOneLevel.succ child =>
      match psKernelOneLevelExplicitOffset? child with
      | PsKernelOneOption.none => PsKernelOneOption.none
      | PsKernelOneOption.some offset =>
          PsKernelOneOption.some (Nat.succ offset)
  | _ => PsKernelOneOption.none

def psKernelOneLevelMkMaxFallback
    (left right : PsKernelOneLevel) : PsKernelOneLevel :=
  if psKernelOneLevelEq left right then
    left
  else if psKernelOneLevelIsZero left then
    right
  else if psKernelOneLevelIsZero right then
    left
  else
    PsKernelOneLevel.max left right

def psKernelOneLevelMkMax
    (left right : PsKernelOneLevel) : PsKernelOneLevel :=
  match psKernelOneLevelExplicitOffset? left with
  | PsKernelOneOption.none =>
      psKernelOneLevelMkMaxFallback left right
  | PsKernelOneOption.some leftOffset =>
      match psKernelOneLevelExplicitOffset? right with
      | PsKernelOneOption.none =>
          psKernelOneLevelMkMaxFallback left right
      | PsKernelOneOption.some rightOffset =>
          if Nat.ble rightOffset leftOffset then left else right

def psKernelOneLevelMkIMax
    (left right : PsKernelOneLevel) : PsKernelOneLevel :=
  if psKernelOneLevelIsNotZero right then
    psKernelOneLevelMkMax left right
  else if psKernelOneLevelIsZero right then
    right
  else if psKernelOneLevelIsZero left then
    right
  else
    match left with
    | PsKernelOneLevel.succ child =>
        match child with
        | PsKernelOneLevel.zero => right
        | _ =>
            if psKernelOneLevelEq left right then
              left
            else
              PsKernelOneLevel.imax left right
    | _ =>
        if psKernelOneLevelEq left right then
          left
        else
          PsKernelOneLevel.imax left right

def psKernelOneLevelNormalize
    (level : PsKernelOneLevel) : PsKernelOneLevel :=
  match level with
  | PsKernelOneLevel.zero => PsKernelOneLevel.zero
  | PsKernelOneLevel.param name => PsKernelOneLevel.param name
  | PsKernelOneLevel.mvar name => PsKernelOneLevel.mvar name
  | PsKernelOneLevel.succ child =>
      PsKernelOneLevel.succ (psKernelOneLevelNormalize child)
  | PsKernelOneLevel.max left right =>
      psKernelOneLevelMkMax
        (psKernelOneLevelNormalize left)
        (psKernelOneLevelNormalize right)
  | PsKernelOneLevel.imax left right =>
      psKernelOneLevelMkIMax
        (psKernelOneLevelNormalize left)
        (psKernelOneLevelNormalize right)

def psKernelOneLevelEquivalentNormalized
    (left : PsKernelOneLevel) : PsKernelOneLevel -> Bool :=
  match left with
  | PsKernelOneLevel.max leftA leftB =>
      let equivalentA : PsKernelOneLevel -> Bool :=
        psKernelOneLevelEquivalentNormalized leftA;
      let equivalentB : PsKernelOneLevel -> Bool :=
        psKernelOneLevelEquivalentNormalized leftB;
      fun (right : PsKernelOneLevel) =>
        if psKernelOneLevelEq left right then
          true
        else
          match right with
          | PsKernelOneLevel.max rightA rightB =>
              if equivalentA rightA then
                equivalentB rightB
              else if equivalentA rightB then
                equivalentB rightA
              else
                false
          | _ => false
  | _ =>
      fun (right : PsKernelOneLevel) =>
        psKernelOneLevelEq left right

def psKernelOneLevelEquivalent
    (left right : PsKernelOneLevel) : Bool :=
  if psKernelOneLevelEq left right then
    true
  else
    let normalizedLeft := psKernelOneLevelNormalize left;
    let normalizedRight := psKernelOneLevelNormalize right;
    psKernelOneLevelEquivalentNormalized normalizedLeft normalizedRight

def psKernelOneLevelSubstLookup
    (target : PsKernelOneName)
    (subst : PsKernelOneLevelSubst) : PsKernelOneOption PsKernelOneLevel :=
  match subst with
  | PsKernelOneLevelSubst.nil => PsKernelOneOption.none
  | PsKernelOneLevelSubst.cons name value rest =>
      if psKernelOneNameEq target name then
        PsKernelOneOption.some value
      else
        psKernelOneLevelSubstLookup target rest

def psKernelOneLevelInstantiateParams
    (root : PsKernelOneLevel)
    (subst : PsKernelOneLevelSubst) : PsKernelOneLevel :=
  match root with
  | PsKernelOneLevel.zero => root
  | PsKernelOneLevel.mvar _ => root
  | PsKernelOneLevel.param name =>
      match psKernelOneLevelSubstLookup name subst with
      | PsKernelOneOption.some value => value
      | PsKernelOneOption.none => root
  | PsKernelOneLevel.succ child =>
      let next := psKernelOneLevelInstantiateParams child subst;
      if psKernelOneLevelEq child next then
        root
      else
        PsKernelOneLevel.succ next
  | PsKernelOneLevel.max left right =>
      let nextLeft := psKernelOneLevelInstantiateParams left subst;
      let nextRight := psKernelOneLevelInstantiateParams right subst;
      if psKernelOneLevelEq left nextLeft then
        if psKernelOneLevelEq right nextRight then
          root
        else
          psKernelOneLevelMkMax nextLeft nextRight
      else
        psKernelOneLevelMkMax nextLeft nextRight
  | PsKernelOneLevel.imax left right =>
      let nextLeft := psKernelOneLevelInstantiateParams left subst;
      let nextRight := psKernelOneLevelInstantiateParams right subst;
      if psKernelOneLevelEq left nextLeft then
        if psKernelOneLevelEq right nextRight then
          root
        else
          psKernelOneLevelMkIMax nextLeft nextRight
      else
        psKernelOneLevelMkIMax nextLeft nextRight

def psKernelOneLevelHasMVar
    (level : PsKernelOneLevel) : Bool :=
  match level with
  | PsKernelOneLevel.mvar _ => true
  | PsKernelOneLevel.succ child =>
      psKernelOneLevelHasMVar child
  | PsKernelOneLevel.max left right =>
      if psKernelOneLevelHasMVar left then
        true
      else
        psKernelOneLevelHasMVar right
  | PsKernelOneLevel.imax left right =>
      if psKernelOneLevelHasMVar left then
        true
      else
        psKernelOneLevelHasMVar right
  | _ => false
