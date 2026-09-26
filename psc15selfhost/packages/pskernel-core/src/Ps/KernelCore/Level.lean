import Ps.KernelCore.Name

inductive PsKernelCoreLevel where
  | zero
  | succ (of : PsKernelCoreLevel)
  | max (left : PsKernelCoreLevel) (right : PsKernelCoreLevel)
  | imax (left : PsKernelCoreLevel) (right : PsKernelCoreLevel)
  | param (name : PsKernelCoreName)
  | mvar (name : PsKernelCoreName)

def psKernelCoreLevelEq :
    PsKernelCoreLevel -> PsKernelCoreLevel -> Bool
  | PsKernelCoreLevel.zero, PsKernelCoreLevel.zero => true
  | PsKernelCoreLevel.succ left, PsKernelCoreLevel.succ right =>
      psKernelCoreLevelEq left right
  | PsKernelCoreLevel.max leftA leftB,
      PsKernelCoreLevel.max rightA rightB =>
      if psKernelCoreLevelEq leftA rightA then
        psKernelCoreLevelEq leftB rightB
      else
        false
  | PsKernelCoreLevel.imax leftA leftB,
      PsKernelCoreLevel.imax rightA rightB =>
      if psKernelCoreLevelEq leftA rightA then
        psKernelCoreLevelEq leftB rightB
      else
        false
  | PsKernelCoreLevel.param left, PsKernelCoreLevel.param right =>
      psKernelCoreNameEq left right
  | PsKernelCoreLevel.mvar left, PsKernelCoreLevel.mvar right =>
      psKernelCoreNameEq left right
  | _, _ => false

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
    | PsKernelCoreLevel.succ PsKernelCoreLevel.zero => right
    | _ =>
        if psKernelCoreLevelEq left right then
          left
        else
          PsKernelCoreLevel.imax left right

partial def psKernelCoreLevelNormalize
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

partial def psKernelCoreLevelEquivalent
    (left right : PsKernelCoreLevel) : Bool :=
  if psKernelCoreLevelEq left right then
    true
  else
    let normalizedLeft := psKernelCoreLevelNormalize left;
    let normalizedRight := psKernelCoreLevelNormalize right;
    if psKernelCoreLevelEq normalizedLeft normalizedRight then
      true
    else
      match normalizedLeft, normalizedRight with
      | PsKernelCoreLevel.max leftA leftB,
          PsKernelCoreLevel.max rightA rightB =>
          if psKernelCoreLevelEquivalent leftA rightA then
            psKernelCoreLevelEquivalent leftB rightB
          else if psKernelCoreLevelEquivalent leftA rightB then
            psKernelCoreLevelEquivalent leftB rightA
          else
            false
      | _, _ => false

def psKernelCoreNameLookupLevel
    (name : PsKernelCoreName)
    (params : List PsKernelCoreName)
    (values : List PsKernelCoreLevel) : Option PsKernelCoreLevel :=
  match params, values with
  | [], _ => none
  | _, [] => none
  | param :: remainingParams, value :: remainingValues =>
      if psKernelCoreNameEq name param then
        some value
      else
        psKernelCoreNameLookupLevel
          name
          remainingParams
          remainingValues

def psKernelCoreLevelInstantiateParams
    (root : PsKernelCoreLevel)
    (params : List PsKernelCoreName)
    (values : List PsKernelCoreLevel) : PsKernelCoreLevel :=
  match root with
  | PsKernelCoreLevel.zero => root
  | PsKernelCoreLevel.mvar _ => root
  | PsKernelCoreLevel.param name =>
      match psKernelCoreNameLookupLevel name params values with
      | some value => value
      | none => root
  | PsKernelCoreLevel.succ child =>
      let next := psKernelCoreLevelInstantiateParams child params values;
      if psKernelCoreLevelEq child next then
        root
      else
        PsKernelCoreLevel.succ next
  | PsKernelCoreLevel.max left right =>
      let nextLeft := psKernelCoreLevelInstantiateParams left params values;
      let nextRight := psKernelCoreLevelInstantiateParams right params values;
      if psKernelCoreLevelEq left nextLeft then
        if psKernelCoreLevelEq right nextRight then
          root
        else
          psKernelCoreLevelMkMax nextLeft nextRight
      else
        psKernelCoreLevelMkMax nextLeft nextRight
  | PsKernelCoreLevel.imax left right =>
      let nextLeft := psKernelCoreLevelInstantiateParams left params values;
      let nextRight := psKernelCoreLevelInstantiateParams right params values;
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
