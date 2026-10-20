import Ps.KernelCore.Runtime.Acceleration.Cache

/-
PSKernel-Core Expression V2 / M1: isolated typed DAG plus eagerly computed
metadata. This is NOT wired into admission, WHNF, inference, or DefEq.

Nodes reference older node IDs in the same immutable arena. No pointer identity,
unsafe casting, external runtime state, or unchecked axiom is required. Stable
IDs provide same-arena sharing and a cheap sufficient identity equality test;
hash collisions must still fall back to structural equality.

The legacy hash formula is retained intentionally, solely for differential
testing. Hash is an index hint, never a proof or a cache verdict.
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
  { nodes := #[] }

def psKernelExprV2Lookup
    (arena : PsKernelExprV2Arena) (id : Nat) :
    Except String PsKernelExprV2Entry :=
  match arena.nodes[id]? with
  | some entry => Except.ok entry
  | none => Except.error "PSKERNEL_V2_INVALID_NODE_ID"

def psKernelExprV2Push
    (arena : PsKernelExprV2Arena) (entry : PsKernelExprV2Entry) :
    PsKernelExprV2Arena × Nat :=
  ({ nodes := arena.nodes.push entry }, arena.nodes.size)

def psKernelExprV2MkBVar
    (arena : PsKernelExprV2Arena) (index : Nat) :
    PsKernelExprV2Arena × Nat :=
  psKernelExprV2Push arena {
    node := .bvar index
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
    node := .fvar name
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
    node := .mvar name
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
    node := .sort level
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
    node := .const name levels
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
    node := .lit value
    hash := psKernelCacheMix 30 (psKernelCacheLiteralHash value)
    looseRange := 0
    hasFVar := false
    hasExprMVar := false
    depth := 1
  }

def psKernelExprV2MkApp
    (arena : PsKernelExprV2Arena) (fn arg : Nat) :
    Except String (PsKernelExprV2Arena × Nat) := do
  let f ← psKernelExprV2Lookup arena fn
  let a ← psKernelExprV2Lookup arena arg
  return psKernelExprV2Push arena {
    node := .app fn arg
    hash := psKernelCacheMix (psKernelCacheMix 26 f.hash) a.hash
    looseRange := Nat.max f.looseRange a.looseRange
    hasFVar := f.hasFVar || a.hasFVar
    hasExprMVar := f.hasExprMVar || a.hasExprMVar
    depth := Nat.succ (Nat.max f.depth a.depth)
  }

def psKernelExprV2MkLam
    (arena : PsKernelExprV2Arena)
    (name : PsKernelName) (type body : Nat) (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExprV2Arena × Nat) := do
  let t ← psKernelExprV2Lookup arena type
  let b ← psKernelExprV2Lookup arena body
  return psKernelExprV2Push arena {
    node := .lam name type body binderInfo
    hash := psKernelCacheMix (psKernelCacheMix 27 t.hash) b.hash
    looseRange := Nat.max t.looseRange (Nat.sub b.looseRange 1)
    hasFVar := t.hasFVar || b.hasFVar
    hasExprMVar := t.hasExprMVar || b.hasExprMVar
    depth := Nat.succ (Nat.max t.depth b.depth)
  }

def psKernelExprV2MkForall
    (arena : PsKernelExprV2Arena)
    (name : PsKernelName) (type body : Nat) (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExprV2Arena × Nat) := do
  let t ← psKernelExprV2Lookup arena type
  let b ← psKernelExprV2Lookup arena body
  return psKernelExprV2Push arena {
    node := .forallE name type body binderInfo
    hash := psKernelCacheMix (psKernelCacheMix 28 t.hash) b.hash
    looseRange := Nat.max t.looseRange (Nat.sub b.looseRange 1)
    hasFVar := t.hasFVar || b.hasFVar
    hasExprMVar := t.hasExprMVar || b.hasExprMVar
    depth := Nat.succ (Nat.max t.depth b.depth)
  }

def psKernelExprV2MkLet
    (arena : PsKernelExprV2Arena)
    (name : PsKernelName) (type value body : Nat) (nondep : Bool) :
    Except String (PsKernelExprV2Arena × Nat) := do
  let t ← psKernelExprV2Lookup arena type
  let v ← psKernelExprV2Lookup arena value
  let b ← psKernelExprV2Lookup arena body
  let flag := if nondep then 1 else 0
  return psKernelExprV2Push arena {
    node := .letE name type value body nondep
    hash := psKernelCacheMix
      (psKernelCacheMix
        (psKernelCacheMix
          (psKernelCacheMix 29 t.hash) v.hash) b.hash) flag
    looseRange := Nat.max
      (Nat.max t.looseRange v.looseRange) (Nat.sub b.looseRange 1)
    hasFVar := t.hasFVar || v.hasFVar || b.hasFVar
    hasExprMVar := t.hasExprMVar || v.hasExprMVar || b.hasExprMVar
    depth := Nat.succ (Nat.max (Nat.max t.depth v.depth) b.depth)
  }

def psKernelExprV2MkMData
    (arena : PsKernelExprV2Arena) (metadata body : Nat) :
    Except String (PsKernelExprV2Arena × Nat) := do
  let b ← psKernelExprV2Lookup arena body
  return psKernelExprV2Push arena {
    node := .mdata metadata body
    hash := psKernelCacheMix (psKernelCacheMix 31 metadata) b.hash
    looseRange := b.looseRange
    hasFVar := b.hasFVar
    hasExprMVar := b.hasExprMVar
    depth := Nat.succ b.depth
  }

def psKernelExprV2MkProj
    (arena : PsKernelExprV2Arena)
    (typeName : PsKernelName) (index body : Nat) :
    Except String (PsKernelExprV2Arena × Nat) := do
  let b ← psKernelExprV2Lookup arena body
  return psKernelExprV2Push arena {
    node := .proj typeName index body
    hash := psKernelCacheMix
      (psKernelCacheMix
        (psKernelCacheMix 32 (psKernelCacheNameHash typeName))
        index) b.hash
    looseRange := b.looseRange
    hasFVar := b.hasFVar
    hasExprMVar := b.hasExprMVar
    depth := Nat.succ b.depth
  }

/- Decode in node-insertion order. Every child ID is earlier than its parent,
so each unique arena node is materialized ONCE and reused by later nodes. -/
private def psKernelExprV2ReadDecoded
    (built : Array PsKernelExpr) (id : Nat) :
    Except String PsKernelExpr :=
  match built[id]? with
  | some value => .ok value
  | none => .error "PSKERNEL_V2_FORWARD_OR_INVALID_REFERENCE"

def psKernelExprV2DecodeNode
    (built : Array PsKernelExpr)
    (node : PsKernelExprV2Node) :
    Except String PsKernelExpr := do
  match node with
  | .bvar index => return .bvar index
  | .fvar name => return .fvar name
  | .mvar name => return .mvar name
  | .sort level => return .sort level
  | .const name levels => return .const name levels
  | .lit literal => return .lit literal
  | .app fn arg =>
      return .app (← psKernelExprV2ReadDecoded built fn)
        (← psKernelExprV2ReadDecoded built arg)
  | .lam name type body binderInfo =>
      return .lam name
        (← psKernelExprV2ReadDecoded built type)
        (← psKernelExprV2ReadDecoded built body) binderInfo
  | .forallE name type body binderInfo =>
      return .forallE name
        (← psKernelExprV2ReadDecoded built type)
        (← psKernelExprV2ReadDecoded built body) binderInfo
  | .letE name type value body nondep =>
      return .letE name
        (← psKernelExprV2ReadDecoded built type)
        (← psKernelExprV2ReadDecoded built value)
        (← psKernelExprV2ReadDecoded built body) nondep
  | .mdata metadata body =>
      return .mdata metadata (← psKernelExprV2ReadDecoded built body)
  | .proj typeName index body =>
      return .proj typeName index (← psKernelExprV2ReadDecoded built body)

def psKernelExprV2Decode
    (arena : PsKernelExprV2Arena) (root : Nat) :
    Except String PsKernelExpr := do
  let mut built : Array PsKernelExpr := #[]
  for entry in arena.nodes do
    let expr ← psKernelExprV2DecodeNode built entry.node
    built := built.push expr
  psKernelExprV2ReadDecoded built root

/-
Independent reference calculations, used exclusively by validation.
The slow reference traverses the materialized tree, not V2 metadata.
-/
def psKernelExprV2LegacyLooseRange : PsKernelExpr → Nat
  | .bvar index => Nat.succ index
  | .app fn arg =>
      Nat.max (psKernelExprV2LegacyLooseRange fn)
        (psKernelExprV2LegacyLooseRange arg)
  | .lam _ type body _ =>
      Nat.max (psKernelExprV2LegacyLooseRange type)
        (Nat.sub (psKernelExprV2LegacyLooseRange body) 1)
  | .forallE _ type body _ =>
      Nat.max (psKernelExprV2LegacyLooseRange type)
        (Nat.sub (psKernelExprV2LegacyLooseRange body) 1)
  | .letE _ type value body _ =>
      Nat.max
        (Nat.max (psKernelExprV2LegacyLooseRange type)
          (psKernelExprV2LegacyLooseRange value))
        (Nat.sub (psKernelExprV2LegacyLooseRange body) 1)
  | .mdata _ body => psKernelExprV2LegacyLooseRange body
  | .proj _ _ body => psKernelExprV2LegacyLooseRange body
  | _ => 0

def psKernelExprV2LegacyDepth : PsKernelExpr → Nat
  | .app fn arg =>
      Nat.succ (Nat.max (psKernelExprV2LegacyDepth fn)
        (psKernelExprV2LegacyDepth arg))
  | .lam _ type body _ =>
      Nat.succ (Nat.max (psKernelExprV2LegacyDepth type)
        (psKernelExprV2LegacyDepth body))
  | .forallE _ type body _ =>
      Nat.succ (Nat.max (psKernelExprV2LegacyDepth type)
        (psKernelExprV2LegacyDepth body))
  | .letE _ type value body _ =>
      Nat.succ (Nat.max
        (Nat.max (psKernelExprV2LegacyDepth type)
          (psKernelExprV2LegacyDepth value))
        (psKernelExprV2LegacyDepth body))
  | .mdata _ body => Nat.succ (psKernelExprV2LegacyDepth body)
  | .proj _ _ body => Nat.succ (psKernelExprV2LegacyDepth body)
  | _ => 1

def psKernelExprV2LegacyHasMVar : PsKernelExpr → Bool
  | .mvar _ => true
  | .app fn arg =>
      psKernelExprV2LegacyHasMVar fn || psKernelExprV2LegacyHasMVar arg
  | .lam _ type body _ =>
      psKernelExprV2LegacyHasMVar type || psKernelExprV2LegacyHasMVar body
  | .forallE _ type body _ =>
      psKernelExprV2LegacyHasMVar type || psKernelExprV2LegacyHasMVar body
  | .letE _ type value body _ =>
      psKernelExprV2LegacyHasMVar type ||
        psKernelExprV2LegacyHasMVar value ||
          psKernelExprV2LegacyHasMVar body
  | .mdata _ body => psKernelExprV2LegacyHasMVar body
  | .proj _ _ body => psKernelExprV2LegacyHasMVar body
  | _ => false

/-
Validation MUST be performed before any untrusted, serialized, or externally
constructed V2 graph becomes eligible for a kernel acceleration path.
Does not trust metadata to validate metadata; recomputes from legacy structure.
-/
def psKernelExprV2Validate
    (arena : PsKernelExprV2Arena) :
    Except String Unit := do
  let mut built : Array PsKernelExpr := #[]
  for entry in arena.nodes do
    let expr ← psKernelExprV2DecodeNode built entry.node
    if entry.hash != psKernelExprHash expr then
      throw "PSKERNEL_V2_HASH_INVALID"
    if entry.looseRange != psKernelExprV2LegacyLooseRange expr then
      throw "PSKERNEL_V2_LOOSE_RANGE_INVALID"
    if entry.hasFVar != psKernelExprHasFVar expr then
      throw "PSKERNEL_V2_FVAR_FLAG_INVALID"
    if entry.hasExprMVar != psKernelExprV2LegacyHasMVar expr then
      throw "PSKERNEL_V2_MVAR_FLAG_INVALID"
    if entry.depth != psKernelExprV2LegacyDepth expr then
      throw "PSKERNEL_V2_DEPTH_INVALID"
    if (entry.looseRange > 0) != psKernelExprHasLooseBVar expr then
      throw "PSKERNEL_V2_LEGACY_LOOSE_FLAG_INVALID"
    built := built.push expr

/-
Same-arena equality: node ID equality is sufficient; a different hash is a
sufficient inequality only for validated graphs; otherwise inspect exact node
structure recursively. Names and binder-info on Lam/Pi are intentionally
ignored, precisely matching PSC1's semantic psKernelExprEq.
-/
def psKernelExprV2EqWithFuel
    (fuel : Nat) (arena : PsKernelExprV2Arena)
    (left right : Nat) : Bool :=
  match fuel with
  | 0 => false
  | Nat.succ remaining =>
      if left == right then
        match arena.nodes[left]? with
        | some _ => true
        | none => false
      else
        match arena.nodes[left]?, arena.nodes[right]? with
        | some a, some b =>
            if a.hash != b.hash then false
            else
              let eqChild := psKernelExprV2EqWithFuel remaining arena
              match a.node, b.node with
              | .bvar x, .bvar y => x == y
              | .fvar x, .fvar y => psKernelNameEq x y
              | .mvar x, .mvar y => psKernelNameEq x y
              | .sort x, .sort y => psKernelLevelEq x y
              | .const n ls, .const m rs =>
                  psKernelNameEq n m && psKernelLevelListEq ls rs
              | .lit x, .lit y => psKernelLiteralEq x y
              | .app f x, .app g y =>
                  eqChild f g && eqChild x y
              | .lam _ t v _, .lam _ u w _ =>
                  eqChild t u && eqChild v w
              | .forallE _ t v _, .forallE _ u w _ =>
                  eqChild t u && eqChild v w
              | .letE _ t v b nd, .letE _ u w c md =>
                  eqChild t u && eqChild v w && eqChild b c && nd == md
              | .mdata x b, .mdata y c =>
                  x == y && eqChild b c
              | .proj n x b, .proj m y c =>
                  psKernelNameEq n m && x == y && eqChild b c
              | _, _ => false
        | _, _ => false

def psKernelExprV2Eq
    (arena : PsKernelExprV2Arena) (left right : Nat) : Bool :=
  psKernelExprV2EqWithFuel (Nat.succ arena.nodes.size) arena left right

/-
Import old expressions only at a migration boundary; the new normal path
must use smart constructors, not repeatedly import for each checker operation.
A fuel bound makes this adapter total even on unknown source inputs.
-/
def psKernelExprV2ImportFuel
    (fuel : Nat) (arena : PsKernelExprV2Arena)
    (expr : PsKernelExpr) :
    Except String (PsKernelExprV2Arena × Nat) :=
  match fuel with
  | 0 => .error "PSKERNEL_V2_IMPORT_FUEL_EXHAUSTED"
  | Nat.succ remaining =>
      let recurse := psKernelExprV2ImportFuel remaining
      match expr with
      | .bvar index => .ok (psKernelExprV2MkBVar arena index)
      | .fvar name => .ok (psKernelExprV2MkFVar arena name)
      | .mvar name => .ok (psKernelExprV2MkMVar arena name)
      | .sort level => .ok (psKernelExprV2MkSort arena level)
      | .const name levels => .ok (psKernelExprV2MkConst arena name levels)
      | .lit literal => .ok (psKernelExprV2MkLit arena literal)
      | .app fn arg => do
          let (a, f) ← recurse arena fn
          let (b, x) ← recurse a arg
          psKernelExprV2MkApp b f x
      | .lam name type body binderInfo => do
          let (a, t) ← recurse arena type
          let (b, v) ← recurse a body
          psKernelExprV2MkLam b name t v binderInfo
      | .forallE name type body binderInfo => do
          let (a, t) ← recurse arena type
          let (b, v) ← recurse a body
          psKernelExprV2MkForall b name t v binderInfo
      | .letE name type value body nondep => do
          let (a, t) ← recurse arena type
          let (b, v) ← recurse a value
          let (c, d) ← recurse b body
          psKernelExprV2MkLet c name t v d nondep
      | .mdata metadata body => do
          let (a, b) ← recurse arena body
          psKernelExprV2MkMData a metadata b
      | .proj name index body => do
          let (a, b) ← recurse arena body
          psKernelExprV2MkProj a name index b

def psKernelExprV2Import
    (arena : PsKernelExprV2Arena) (expr : PsKernelExpr) :
    Except String (PsKernelExprV2Arena × Nat) :=
  psKernelExprV2ImportFuel
    (Nat.succ (psKernelExprNodeCount expr)) arena expr
