import Ps.KernelCore.Runtime.Acceleration.ScalarHash

/- The single expression DAG node and cached-metadata definition.
Fields in externally supplied records remain untrusted until replay validation.
Smart construction/replay derives every field from already validated children. -/

inductive PsKernelExprV2Node where
  | bvar (index : Nat)
  | fvar (name : PsKernelName)
  | mvar (name : PsKernelName)
  | sort (level : PsKernelLevel)
  | const (name : PsKernelName) (levels : List PsKernelLevel)
  | app (fn arg : Nat)
  | lam (name : PsKernelName) (type body : Nat) (binderInfo : PsKernelBinderInfo)
  | forallE (name : PsKernelName) (type body : Nat) (binderInfo : PsKernelBinderInfo)
  | letE (name : PsKernelName) (type value body : Nat) (nondep : Bool)
  | lit (value : PsKernelLiteral)
  | mdata (metadata : Nat) (body : Nat)
  | proj (typeName : PsKernelName) (index : Nat) (body : Nat)

structure PsKernelExprV2Entry where
  node : PsKernelExprV2Node
  hash : Nat
  looseRange : Nat
  hasFVar : Bool
  hasExprMVar : Bool
  depth : Nat

def psKernelExprV2DummyEntry : PsKernelExprV2Entry :=
  {
    node := PsKernelExprV2Node.bvar 0
    hash := 0
    looseRange := 0
    hasFVar := false
    hasExprMVar := false
    depth := 0
  }

def psKernelExprV2NatMax
    (left right : Nat) : Nat :=
  if Nat.ble left right then right else left

def psKernelExprV2BoolOr
    (left right : Bool) : Bool :=
  if left then true else right

def psKernelExprV2AppEntry
    (fn arg : Nat)
    (f a : PsKernelExprV2Entry) : PsKernelExprV2Entry :=
  PsKernelExprV2Entry.mk
    (PsKernelExprV2Node.app fn arg)
    (psKernelCacheMix (psKernelCacheMix 26 f.hash) a.hash)
    (psKernelExprV2NatMax f.looseRange a.looseRange)
    (psKernelExprV2BoolOr f.hasFVar a.hasFVar)
    (psKernelExprV2BoolOr f.hasExprMVar a.hasExprMVar)
    (Nat.succ (psKernelExprV2NatMax f.depth a.depth))

def psKernelExprV2LamEntry
    (name : PsKernelName)
    (type body : Nat) (binderInfo : PsKernelBinderInfo)
    (t b : PsKernelExprV2Entry) : PsKernelExprV2Entry :=
  PsKernelExprV2Entry.mk
    (PsKernelExprV2Node.lam name type body binderInfo)
    (psKernelCacheMix (psKernelCacheMix 27 t.hash) b.hash)
    (psKernelExprV2NatMax t.looseRange (Nat.sub b.looseRange 1))
    (psKernelExprV2BoolOr t.hasFVar b.hasFVar)
    (psKernelExprV2BoolOr t.hasExprMVar b.hasExprMVar)
    (Nat.succ (psKernelExprV2NatMax t.depth b.depth))

def psKernelExprV2ForallEntry
    (name : PsKernelName)
    (type body : Nat) (binderInfo : PsKernelBinderInfo)
    (t b : PsKernelExprV2Entry) : PsKernelExprV2Entry :=
  PsKernelExprV2Entry.mk
    (PsKernelExprV2Node.forallE name type body binderInfo)
    (psKernelCacheMix (psKernelCacheMix 28 t.hash) b.hash)
    (psKernelExprV2NatMax t.looseRange (Nat.sub b.looseRange 1))
    (psKernelExprV2BoolOr t.hasFVar b.hasFVar)
    (psKernelExprV2BoolOr t.hasExprMVar b.hasExprMVar)
    (Nat.succ (psKernelExprV2NatMax t.depth b.depth))

def psKernelExprV2LetEntry
    (name : PsKernelName) (type value body : Nat) (nondep : Bool)
    (t v b : PsKernelExprV2Entry) : PsKernelExprV2Entry :=
  let flag : Nat := if nondep then 1 else 0;
  PsKernelExprV2Entry.mk
    (PsKernelExprV2Node.letE name type value body nondep)
    (psKernelCacheMix
      (psKernelCacheMix
        (psKernelCacheMix
          (psKernelCacheMix 29 t.hash) v.hash) b.hash) flag)
    (psKernelExprV2NatMax
      (psKernelExprV2NatMax t.looseRange v.looseRange) (Nat.sub b.looseRange 1))
    (psKernelExprV2BoolOr (psKernelExprV2BoolOr t.hasFVar v.hasFVar) b.hasFVar)
    (psKernelExprV2BoolOr (psKernelExprV2BoolOr t.hasExprMVar v.hasExprMVar) b.hasExprMVar)
    (Nat.succ (psKernelExprV2NatMax (psKernelExprV2NatMax t.depth v.depth) b.depth))

def psKernelExprV2MDataEntry
    (metadata body : Nat) (b : PsKernelExprV2Entry) :
    PsKernelExprV2Entry :=
  PsKernelExprV2Entry.mk
    (PsKernelExprV2Node.mdata metadata body)
    (psKernelCacheMix (psKernelCacheMix 31 metadata) b.hash)
    b.looseRange
    b.hasFVar
    b.hasExprMVar
    (Nat.succ b.depth)

def psKernelExprV2ProjEntry
    (typeName : PsKernelName) (index body : Nat)
    (b : PsKernelExprV2Entry) : PsKernelExprV2Entry :=
  PsKernelExprV2Entry.mk
    (PsKernelExprV2Node.proj typeName index body)
    (psKernelCacheMix
      (psKernelCacheMix
        (psKernelCacheMix 32 (psKernelCacheNameHash typeName))
        index) b.hash)
    b.looseRange
    b.hasFVar
    b.hasExprMVar
    (Nat.succ b.depth)

def psKernelExprV2PortableSameMetadata
    (left right : PsKernelExprV2Entry) : Bool :=
  if Nat.beq left.hash right.hash then
    if Nat.beq left.looseRange right.looseRange then
      if psKernelBoolEq left.hasFVar right.hasFVar then
        if psKernelBoolEq left.hasExprMVar right.hasExprMVar then
          Nat.beq left.depth right.depth
        else false
      else false
    else false
  else false

