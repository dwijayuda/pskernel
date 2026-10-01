import Ps.KernelCore.Name

inductive PsKernelCoreLevel where
  | zero
  | succ (of : PsKernelCoreLevel)
  | max (left : PsKernelCoreLevel) (right : PsKernelCoreLevel)
  | imax (left : PsKernelCoreLevel) (right : PsKernelCoreLevel)
  | param (name : PsKernelCoreName)
  | mvar (name : PsKernelCoreName)

inductive PsKernelCoreLevelSubst where
  | nil
  | cons
      (name : PsKernelCoreName)
      (value : PsKernelCoreLevel)
      (rest : PsKernelCoreLevelSubst)

def psKernelCoreLevelEq
    (left : PsKernelCoreLevel) : PsKernelCoreLevel -> Bool :=
  match left with
  | PsKernelCoreLevel.zero =>
      fun (right : PsKernelCoreLevel) =>
        match right with
        | PsKernelCoreLevel.zero => true
        | _ => false
  | PsKernelCoreLevel.succ leftChild =>
      let childEq : PsKernelCoreLevel -> Bool :=
        psKernelCoreLevelEq leftChild;
      fun (right : PsKernelCoreLevel) =>
        match right with
        | PsKernelCoreLevel.succ rightChild => childEq rightChild
        | _ => false
  | PsKernelCoreLevel.max leftA leftB =>
      let leftEq : PsKernelCoreLevel -> Bool :=
        psKernelCoreLevelEq leftA;
      let rightEq : PsKernelCoreLevel -> Bool :=
        psKernelCoreLevelEq leftB;
      fun (right : PsKernelCoreLevel) =>
        match right with
        | PsKernelCoreLevel.max rightA rightB =>
            if leftEq rightA then
              rightEq rightB
            else
              false
        | _ => false
  | PsKernelCoreLevel.imax leftA leftB =>
      let leftEq : PsKernelCoreLevel -> Bool :=
        psKernelCoreLevelEq leftA;
      let rightEq : PsKernelCoreLevel -> Bool :=
        psKernelCoreLevelEq leftB;
      fun (right : PsKernelCoreLevel) =>
        match right with
        | PsKernelCoreLevel.imax rightA rightB =>
            if leftEq rightA then
              rightEq rightB
            else
              false
        | _ => false
  | PsKernelCoreLevel.param leftName =>
      fun (right : PsKernelCoreLevel) =>
        match right with
        | PsKernelCoreLevel.param rightName =>
            psKernelCoreNameEq leftName rightName
        | _ => false
  | PsKernelCoreLevel.mvar leftName =>
      fun (right : PsKernelCoreLevel) =>
        match right with
        | PsKernelCoreLevel.mvar rightName =>
            psKernelCoreNameEq leftName rightName
        | _ => false

def psKernelCoreLevelIsZero (level : PsKernelCoreLevel) : Bool :=
  match level with
  | PsKernelCoreLevel.zero => true
  | _ => false

def psKernelCoreLevelIsNotZero (level : PsKernelCoreLevel) : Bool :=
  match level with
  | PsKernelCoreLevel.succ _ => true
  | PsKernelCoreLevel.max left right =>
      if psKernelCoreLevelIsNotZero left then
        true
      else
        psKernelCoreLevelIsNotZero right
  | PsKernelCoreLevel.imax _ right =>
      psKernelCoreLevelIsNotZero right
  | _ => false

def psKernelCoreLevelNormalizesToZero
    (level : PsKernelCoreLevel) : Bool :=
  match level with
  | PsKernelCoreLevel.zero => true
  | PsKernelCoreLevel.max left right =>
      if psKernelCoreLevelNormalizesToZero left then
        psKernelCoreLevelNormalizesToZero right
      else
        false
  | PsKernelCoreLevel.imax _ right =>
      psKernelCoreLevelNormalizesToZero right
  | _ => false

def psKernelCoreLevelAddOffset
    (level : PsKernelCoreLevel)
    (offset : Nat) : PsKernelCoreLevel :=
  match offset with
  | Nat.zero => level
  | Nat.succ remaining =>
      PsKernelCoreLevel.succ
        (psKernelCoreLevelAddOffset level remaining)

def psKernelCoreLevelMkMax
    (left right : PsKernelCoreLevel) : PsKernelCoreLevel :=
  if psKernelCoreLevelEq left right then
    left
  else if psKernelCoreLevelIsZero left then
    right
  else if psKernelCoreLevelIsZero right then
    left
  else
    PsKernelCoreLevel.max left right

def psKernelCoreLevelMkIMax
    (left right : PsKernelCoreLevel) : PsKernelCoreLevel :=
  if psKernelCoreLevelIsNotZero right then
    psKernelCoreLevelMkMax left right
  else if psKernelCoreLevelIsZero right then
    right
  else if psKernelCoreLevelIsZero left then
    right
  else
    match left with
    | PsKernelCoreLevel.succ child =>
        match child with
        | PsKernelCoreLevel.zero => right
        | _ =>
            if psKernelCoreLevelEq left right then
              left
            else
              PsKernelCoreLevel.imax left right
    | _ =>
        if psKernelCoreLevelEq left right then
          left
        else
          PsKernelCoreLevel.imax left right

def psKernelCoreLevelNormalize
    (level : PsKernelCoreLevel) : PsKernelCoreLevel :=
  match level with
  | PsKernelCoreLevel.zero => PsKernelCoreLevel.zero
  | PsKernelCoreLevel.param name => PsKernelCoreLevel.param name
  | PsKernelCoreLevel.mvar name => PsKernelCoreLevel.mvar name
  | PsKernelCoreLevel.succ child =>
      PsKernelCoreLevel.succ (psKernelCoreLevelNormalize child)
  | PsKernelCoreLevel.max left right =>
      psKernelCoreLevelMkMax
        (psKernelCoreLevelNormalize left)
        (psKernelCoreLevelNormalize right)
  | PsKernelCoreLevel.imax left right =>
      psKernelCoreLevelMkIMax
        (psKernelCoreLevelNormalize left)
        (psKernelCoreLevelNormalize right)

def psKernelCoreLevelEquivalentNormalized
    (left : PsKernelCoreLevel) : PsKernelCoreLevel -> Bool :=
  match left with
  | PsKernelCoreLevel.max leftA leftB =>
      let equivalentA : PsKernelCoreLevel -> Bool :=
        psKernelCoreLevelEquivalentNormalized leftA;
      let equivalentB : PsKernelCoreLevel -> Bool :=
        psKernelCoreLevelEquivalentNormalized leftB;
      fun (right : PsKernelCoreLevel) =>
        if psKernelCoreLevelEq left right then
          true
        else
          match right with
          | PsKernelCoreLevel.max rightA rightB =>
              if equivalentA rightA then
                equivalentB rightB
              else if equivalentA rightB then
                equivalentB rightA
              else
                false
          | _ => false
  | _ =>
      fun (right : PsKernelCoreLevel) =>
        psKernelCoreLevelEq left right

def psKernelCoreLevelEquivalent
    (left right : PsKernelCoreLevel) : Bool :=
  if psKernelCoreLevelEq left right then
    true
  else
    let normalizedLeft := psKernelCoreLevelNormalize left;
    let normalizedRight := psKernelCoreLevelNormalize right;
    psKernelCoreLevelEquivalentNormalized normalizedLeft normalizedRight

def psKernelCoreLevelSubstLookup
    (target : PsKernelCoreName)
    (subst : PsKernelCoreLevelSubst) : PsKernelCoreOption PsKernelCoreLevel :=
  match subst with
  | PsKernelCoreLevelSubst.nil => PsKernelCoreOption.none
  | PsKernelCoreLevelSubst.cons name value rest =>
      if psKernelCoreNameEq target name then
        PsKernelCoreOption.some value
      else
        psKernelCoreLevelSubstLookup target rest

def psKernelCoreLevelInstantiateParams
    (root : PsKernelCoreLevel)
    (subst : PsKernelCoreLevelSubst) : PsKernelCoreLevel :=
  match root with
  | PsKernelCoreLevel.zero => root
  | PsKernelCoreLevel.mvar _ => root
  | PsKernelCoreLevel.param name =>
      match psKernelCoreLevelSubstLookup name subst with
      | PsKernelCoreOption.some value => value
      | PsKernelCoreOption.none => root
  | PsKernelCoreLevel.succ child =>
      let next := psKernelCoreLevelInstantiateParams child subst;
      if psKernelCoreLevelEq child next then
        root
      else
        PsKernelCoreLevel.succ next
  | PsKernelCoreLevel.max left right =>
      let nextLeft := psKernelCoreLevelInstantiateParams left subst;
      let nextRight := psKernelCoreLevelInstantiateParams right subst;
      if psKernelCoreLevelEq left nextLeft then
        if psKernelCoreLevelEq right nextRight then
          root
        else
          psKernelCoreLevelMkMax nextLeft nextRight
      else
        psKernelCoreLevelMkMax nextLeft nextRight
  | PsKernelCoreLevel.imax left right =>
      let nextLeft := psKernelCoreLevelInstantiateParams left subst;
      let nextRight := psKernelCoreLevelInstantiateParams right subst;
      if psKernelCoreLevelEq left nextLeft then
        if psKernelCoreLevelEq right nextRight then
          root
        else
          psKernelCoreLevelMkIMax nextLeft nextRight
      else
        psKernelCoreLevelMkIMax nextLeft nextRight

def psKernelCoreLevelHasMVar
    (level : PsKernelCoreLevel) : Bool :=
  match level with
  | PsKernelCoreLevel.mvar _ => true
  | PsKernelCoreLevel.succ child =>
      psKernelCoreLevelHasMVar child
  | PsKernelCoreLevel.max left right =>
      if psKernelCoreLevelHasMVar left then
        true
      else
        psKernelCoreLevelHasMVar right
  | PsKernelCoreLevel.imax left right =>
      if psKernelCoreLevelHasMVar left then
        true
      else
        psKernelCoreLevelHasMVar right
  | _ => false
