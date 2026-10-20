import Ps.KernelCore.Runtime.Acceleration.Cache

/-
PSKernel-Core Expression V2 / M2 portable architectural core.
This is a same-arena immutable expression DAG, not an active checker.
Every node stores the legacy-compatible cached structural hash, exact
loose-bvar range, FVar/expr-MVar presence flags, and structural depth.
The only accepted normal construction path is a smart constructor.
Stable IDs refer to earlier nodes and allow explicit subtree sharing.
-/

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

structure PsKernelExprV2Arena where
  nodes : Array PsKernelExprV2Entry

def psKernelExprV2Empty : PsKernelExprV2Arena :=
  { nodes := Array.emptyWithCapacity 0 }

def psKernelExprV2DummyEntry : PsKernelExprV2Entry :=
  {
    node := PsKernelExprV2Node.bvar 0
    hash := 0
    looseRange := 0
    hasFVar := false
    hasExprMVar := false
    depth := 0
  }

def psKernelExprV2Lookup
    (arena : PsKernelExprV2Arena) (id : Nat) :
    Except String PsKernelExprV2Entry :=
  if Nat.blt id (Array.size arena.nodes) then
    Except.ok
      (Array.getD arena.nodes id psKernelExprV2DummyEntry)
  else
    Except.error "PSKERNEL_V2_INVALID_NODE_ID"

def psKernelExprV2Push
    (arena : PsKernelExprV2Arena) (entry : PsKernelExprV2Entry) :
    PsKernelExprV2Arena × Nat :=
  let next : PsKernelExprV2Arena := {
    nodes := Array.push arena.nodes entry
  };
  Prod.mk next (Array.size arena.nodes)

def psKernelExprV2With1
    (arena : PsKernelExprV2Arena) (child : Nat)
    (make : PsKernelExprV2Entry -> PsKernelExprV2Entry) :
    Except String (PsKernelExprV2Arena × Nat) :=
  match psKernelExprV2Lookup arena child with
  | Except.error error => Except.error error
  | Except.ok value =>
      Except.ok (psKernelExprV2Push arena (make value))

def psKernelExprV2With2
    (arena : PsKernelExprV2Arena) (left right : Nat)
    (make : PsKernelExprV2Entry -> PsKernelExprV2Entry -> PsKernelExprV2Entry) :
    Except String (PsKernelExprV2Arena × Nat) :=
  match psKernelExprV2Lookup arena left with
  | Except.error error => Except.error error
  | Except.ok l =>
      match psKernelExprV2Lookup arena right with
      | Except.error error => Except.error error
      | Except.ok r =>
          Except.ok (psKernelExprV2Push arena (make l r))

def psKernelExprV2With3
    (arena : PsKernelExprV2Arena) (first second third : Nat)
    (make :
      PsKernelExprV2Entry -> PsKernelExprV2Entry ->
      PsKernelExprV2Entry -> PsKernelExprV2Entry) :
    Except String (PsKernelExprV2Arena × Nat) :=
  match psKernelExprV2Lookup arena first with
  | Except.error error => Except.error error
  | Except.ok one =>
      match psKernelExprV2Lookup arena second with
      | Except.error error => Except.error error
      | Except.ok two =>
          match psKernelExprV2Lookup arena third with
          | Except.error error => Except.error error
          | Except.ok three =>
              Except.ok (psKernelExprV2Push arena (make one two three))

def psKernelExprV2MkBVar
    (arena : PsKernelExprV2Arena) (index : Nat) :
    PsKernelExprV2Arena × Nat :=
  psKernelExprV2Push arena {
    node := PsKernelExprV2Node.bvar index
    hash := psKernelCacheMix 21 index
    looseRange := Nat.succ index
    hasFVar := false
    hasExprMVar := false
    depth := 1
  }

def psKernelExprV2MkFVar
    (arena : PsKernelExprV2Arena) (name : PsKernelName) :
    PsKernelExprV2Arena × Nat :=
  psKernelExprV2Push arena {
    node := PsKernelExprV2Node.fvar name
    hash := psKernelCacheMix 22 (psKernelCacheNameHash name)
    looseRange := 0
    hasFVar := true
    hasExprMVar := false
    depth := 1
  }

def psKernelExprV2MkMVar
    (arena : PsKernelExprV2Arena) (name : PsKernelName) :
    PsKernelExprV2Arena × Nat :=
  psKernelExprV2Push arena {
    node := PsKernelExprV2Node.mvar name
    hash := psKernelCacheMix 23 (psKernelCacheNameHash name)
    looseRange := 0
    hasFVar := false
    hasExprMVar := true
    depth := 1
  }

def psKernelExprV2MkSort
    (arena : PsKernelExprV2Arena) (level : PsKernelLevel) :
    PsKernelExprV2Arena × Nat :=
  psKernelExprV2Push arena {
    node := PsKernelExprV2Node.sort level
    hash := psKernelCacheMix 24 (psKernelCacheLevelHash level)
    looseRange := 0
    hasFVar := false
    hasExprMVar := false
    depth := 1
  }

def psKernelExprV2MkConst
    (arena : PsKernelExprV2Arena)
    (name : PsKernelName) (levels : List PsKernelLevel) :
    PsKernelExprV2Arena × Nat :=
  psKernelExprV2Push arena {
    node := PsKernelExprV2Node.const name levels
    hash := psKernelCacheMix
      (psKernelCacheMix 25 (psKernelCacheNameHash name))
      (psKernelCacheLevelListHash levels)
    looseRange := 0
    hasFVar := false
    hasExprMVar := false
    depth := 1
  }

def psKernelExprV2MkLit
    (arena : PsKernelExprV2Arena) (value : PsKernelLiteral) :
    PsKernelExprV2Arena × Nat :=
  psKernelExprV2Push arena {
    node := PsKernelExprV2Node.lit value
    hash := psKernelCacheMix 30 (psKernelCacheLiteralHash value)
    looseRange := 0
    hasFVar := false
    hasExprMVar := false
    depth := 1
  }

/-
PSC1's portable parser accepts typed declarations and partial applications,
but not anonymous typed lambdas inside function arguments. Explicit worker
definitions also make each smart constructor's metadata rules auditable.
-/

/-
Semantic-independent metadata combinators. Use named functions rather than
inline if expressions in higher-order argument positions because PSC1's
portable frontend only accepts the simpler term grammar.
-/
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

def psKernelExprV2MkApp
    (arena : PsKernelExprV2Arena) (fn arg : Nat) :
    Except String (PsKernelExprV2Arena × Nat) :=
  psKernelExprV2With2 arena fn arg
    (psKernelExprV2AppEntry fn arg)

def psKernelExprV2MkLam
    (arena : PsKernelExprV2Arena)
    (name : PsKernelName) (type body : Nat) (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExprV2Arena × Nat) :=
  psKernelExprV2With2 arena type body
    (psKernelExprV2LamEntry name type body binderInfo)

def psKernelExprV2MkForall
    (arena : PsKernelExprV2Arena)
    (name : PsKernelName) (type body : Nat) (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExprV2Arena × Nat) :=
  psKernelExprV2With2 arena type body
    (psKernelExprV2ForallEntry name type body binderInfo)

def psKernelExprV2MkLet
    (arena : PsKernelExprV2Arena)
    (name : PsKernelName) (type value body : Nat) (nondep : Bool) :
    Except String (PsKernelExprV2Arena × Nat) :=
  psKernelExprV2With3 arena type value body
    (psKernelExprV2LetEntry name type value body nondep)

def psKernelExprV2MkMData
    (arena : PsKernelExprV2Arena) (metadata body : Nat) :
    Except String (PsKernelExprV2Arena × Nat) :=
  psKernelExprV2With1 arena body
    (psKernelExprV2MDataEntry metadata body)

def psKernelExprV2MkProj
    (arena : PsKernelExprV2Arena)
    (typeName : PsKernelName) (index body : Nat) :
    Except String (PsKernelExprV2Arena × Nat) :=
  psKernelExprV2With1 arena body
    (psKernelExprV2ProjEntry typeName index body)
