import Ps.KernelCore.Runtime.Acceleration.Cache

/-
PSKernel-C0 portable indexed expression store.

This is a source-owned Lean performance representation, independent from
Rust code. Every composite node holds Nat handles rather than recursive
PsKernelExpr children. Arrays provide indexed reads, and persistent 16-bit
hash-bucket tries provide lookup. Cached child hashes avoid hashing whole
subtrees repeatedly. Exact structural equality is always checked on
hash matches; neither hash equality nor handle equality across stores is
proof-term equality. Never pass handles between independent stores.

This is an experimental representation layer, not a checked kernel API.
-/

inductive PsKernelC0Node where
  | bvar (index : Nat)
  | fvar (name : PsKernelName)
  | mvar (name : PsKernelName)
  | sort (level : PsKernelLevel)
  | const (name : PsKernelName) (levels : List PsKernelLevel)
  | app (fn : Nat) (arg : Nat)
  | lam (name : PsKernelName) (type : Nat) (body : Nat)
      (info : PsKernelBinderInfo)
  | forallE (name : PsKernelName) (type : Nat) (body : Nat)
      (info : PsKernelBinderInfo)
  | letE (name : PsKernelName) (type : Nat) (value : Nat)
      (body : Nat) (nondep : Bool)
  | lit (value : PsKernelLiteral)
  | mdata (metadata : Nat) (body : Nat)
  | proj (typeName : PsKernelName) (index : Nat) (body : Nat)

def psKernelC0NodeEq
    (left : PsKernelC0Node)
    (right : PsKernelC0Node) : Bool :=
  match left, right with
  | .bvar a, .bvar b => Nat.beq a b
  | .fvar a, .fvar b => psKernelNameEq a b
  | .mvar a, .mvar b => psKernelNameEq a b
  | .sort a, .sort b => psKernelLevelEq a b
  | .const n l, .const m r =>
      psKernelNameEq n m && psKernelLevelListEq l r
  | .app a b, .app c d => Nat.beq a c && Nat.beq b d
  | .lam n a b i, .lam m c d j =>
      psKernelNameEq n m && Nat.beq a c && Nat.beq b d &&
      psKernelBinderInfoEq i j
  | .forallE n a b i, .forallE m c d j =>
      psKernelNameEq n m && Nat.beq a c && Nat.beq b d &&
      psKernelBinderInfoEq i j
  | .letE n a b c d, .letE m e f g h =>
      psKernelNameEq n m && Nat.beq a e && Nat.beq b f &&
      Nat.beq c g && psKernelBoolEq d h
  | .lit a, .lit b => psKernelLiteralEq a b
  | .mdata m a, .mdata n b => Nat.beq m n && Nat.beq a b
  | .proj n i a, .proj m j b =>
      psKernelNameEq n m && Nat.beq i j && Nat.beq a b
  | _, _ => false

structure PsKernelC0StoredNode where
  node : PsKernelC0Node
  hash : Nat
  depth : Nat

/--
  Share the persistent radix-16 index with the checker caches.
  A term store keeps its full nodes in an immutable array; the index only
  stores candidate handles. Hash collisions always compare complete nodes.
-/
abbrev PsKernelC0Trie := PsKernelC0HashTrie Nat

structure PsKernelC0TermStore where
  nodes : Array PsKernelC0StoredNode
  index : PsKernelC0Trie

def psKernelC0StoreEmpty : PsKernelC0TermStore :=
  {
    nodes := Array.empty
    index := PsKernelC0HashTrie.empty
  }

def psKernelC0StoreGet
    (store : PsKernelC0TermStore)
    (id : Nat) : Option PsKernelC0StoredNode :=
  store.nodes[id]?

def psKernelC0StoreValid
    (store : PsKernelC0TermStore)
    (id : Nat) : Bool :=
  Nat.blt id store.nodes.size

def psKernelC0NodeValid
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) : Bool :=
  match node with
  | .app fn arg =>
      psKernelC0StoreValid store fn && psKernelC0StoreValid store arg
  | .lam _ type body _ =>
      psKernelC0StoreValid store type && psKernelC0StoreValid store body
  | .forallE _ type body _ =>
      psKernelC0StoreValid store type && psKernelC0StoreValid store body
  | .letE _ type value body _ =>
      psKernelC0StoreValid store type &&
      psKernelC0StoreValid store value &&
      psKernelC0StoreValid store body
  | .mdata _ body =>
      psKernelC0StoreValid store body
  | .proj _ _ body =>
      psKernelC0StoreValid store body
  | _ => true

def psKernelC0ChildHash
    (store : PsKernelC0TermStore)
    (id : Nat) : Nat :=
  match psKernelC0StoreGet store id with
  | Option.some entry => entry.hash
  | Option.none => 0

def psKernelC0ChildDepth
    (store : PsKernelC0TermStore)
    (id : Nat) : Nat :=
  match psKernelC0StoreGet store id with
  | Option.some entry => entry.depth
  | Option.none => 0

def psKernelC0NodeHash
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) : Nat :=
  match node with
  | .bvar i => psKernelCacheMix 21 i
  | .fvar n => psKernelCacheMix 22 (psKernelCacheNameHash n)
  | .mvar n => psKernelCacheMix 23 (psKernelCacheNameHash n)
  | .sort l => psKernelCacheMix 24 (psKernelCacheLevelHash l)
  | .const n ls =>
      psKernelCacheMix
        (psKernelCacheMix 25 (psKernelCacheNameHash n))
        (psKernelCacheLevelListHash ls)
  | .app fn arg =>
      psKernelCacheMix
        (psKernelCacheMix 26 (psKernelC0ChildHash store fn))
        (psKernelC0ChildHash store arg)
  | .lam _ ty body _ =>
      psKernelCacheMix
        (psKernelCacheMix 27 (psKernelC0ChildHash store ty))
        (psKernelC0ChildHash store body)
  | .forallE _ ty body _ =>
      psKernelCacheMix
        (psKernelCacheMix 28 (psKernelC0ChildHash store ty))
        (psKernelC0ChildHash store body)
  | .letE _ ty value body nondep =>
      psKernelCacheMix
        (psKernelCacheMix
          (psKernelCacheMix
            (psKernelCacheMix 29 (psKernelC0ChildHash store ty))
            (psKernelC0ChildHash store value))
          (psKernelC0ChildHash store body))
        (if nondep then 1 else 0)
  | .lit l => psKernelCacheMix 30 (psKernelCacheLiteralHash l)
  | .mdata m body =>
      psKernelCacheMix
        (psKernelCacheMix 31 m)
        (psKernelC0ChildHash store body)
  | .proj n i body =>
      psKernelCacheMix
        (psKernelCacheMix
          (psKernelCacheMix 32 (psKernelCacheNameHash n))
          i)
        (psKernelC0ChildHash store body)

def psKernelC0NodeDepth
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) : Nat :=
  let child := psKernelC0ChildDepth store
  match node with
  | .app fn arg => Nat.succ (Nat.max (child fn) (child arg))
  | .lam _ ty body _ => Nat.succ (Nat.max (child ty) (child body))
  | .forallE _ ty body _ => Nat.succ (Nat.max (child ty) (child body))
  | .letE _ ty value body _ =>
      Nat.succ (Nat.max (child ty) (Nat.max (child value) (child body)))
  | .mdata _ body => Nat.succ (child body)
  | .proj _ _ body => Nat.succ (child body)
  | _ => 1

/-- Radix-16 lookup over the four nibbles of the 16-bit node fingerprint. -/
def psKernelC0TermTrieBucket
    (fuel : Nat)
    (index : PsKernelC0Trie)
    (hash : Nat) : List Nat :=
  psKernelC0TrieBucket fuel index hash

/-- Persistent path update, sharing every untouched radix subtree. -/
def psKernelC0TermTrieReplace
    (fuel : Nat)
    (index : PsKernelC0Trie)
    (hash : Nat)
    (ids : List Nat) : PsKernelC0Trie :=
  psKernelC0TrieSet fuel index hash ids

def psKernelC0FindNode
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) :
    List Nat -> Option Nat
  | List.nil => Option.none
  | List.cons id rest =>
      match psKernelC0StoreGet store id with
      | Option.some entry =>
          if psKernelC0NodeEq entry.node node then
            Option.some id
          else
            psKernelC0FindNode store node rest
      | Option.none =>
          psKernelC0FindNode store node rest

def psKernelC0Intern
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) :
    Option (Prod PsKernelC0TermStore Nat) :=
  if psKernelC0NodeValid store node then
    let hash := psKernelC0NodeHash store node
    let bucket := psKernelC0TermTrieBucket psKernelC0IndexDepth store.index hash
    match psKernelC0FindNode store node bucket with
    | Option.some id =>
        Option.some (Prod.mk store id)
    | Option.none =>
        let id := store.nodes.size
        let entry : PsKernelC0StoredNode :=
          { node := node, hash := hash, depth := psKernelC0NodeDepth store node }
        let index :=
          psKernelC0TermTrieReplace
            psKernelC0IndexDepth store.index hash (List.cons id bucket)
        let next : PsKernelC0TermStore :=
          { nodes := store.nodes.push entry, index := index }
        Option.some (Prod.mk next id)
  else
    Option.none

/-
C0 expression bridge.

The accepting checker continues to use PsKernelExpr. This bridge is exact:
binder names, binder kinds, metadata, literals, universe arguments and let
nondependence all round-trip. The representation is *not* a defeq oracle.

Encode only creates children before parents. Decode is bounded by the stored
node depth, so malformed cycles or dangling IDs cannot silently become terms.
All identifiers are scoped to a single PsKernelC0TermStore.
-/

def psKernelC0EncodeExpr
    (store : PsKernelC0TermStore)
    (expr : PsKernelExpr) :
    Option (Prod PsKernelC0TermStore Nat) :=
  match expr with
  | .bvar i => psKernelC0Intern store (.bvar i)
  | .fvar n => psKernelC0Intern store (.fvar n)
  | .mvar n => psKernelC0Intern store (.mvar n)
  | .sort l => psKernelC0Intern store (.sort l)
  | .const n ls => psKernelC0Intern store (.const n ls)
  | .lit value => psKernelC0Intern store (.lit value)
  | .app fn arg => do
      let (s1, f) ← psKernelC0EncodeExpr store fn
      let (s2, a) ← psKernelC0EncodeExpr s1 arg
      psKernelC0Intern s2 (.app f a)
  | .lam name ty body info => do
      let (s1, t) ← psKernelC0EncodeExpr store ty
      let (s2, b) ← psKernelC0EncodeExpr s1 body
      psKernelC0Intern s2 (.lam name t b info)
  | .forallE name ty body info => do
      let (s1, t) ← psKernelC0EncodeExpr store ty
      let (s2, b) ← psKernelC0EncodeExpr s1 body
      psKernelC0Intern s2 (.forallE name t b info)
  | .letE name ty value body nondep => do
      let (s1, t) ← psKernelC0EncodeExpr store ty
      let (s2, v) ← psKernelC0EncodeExpr s1 value
      let (s3, b) ← psKernelC0EncodeExpr s2 body
      psKernelC0Intern s3 (.letE name t v b nondep)
  | .mdata metadata body => do
      let (s1, b) ← psKernelC0EncodeExpr store body
      psKernelC0Intern s1 (.mdata metadata b)
  | .proj name index body => do
      let (s1, b) ← psKernelC0EncodeExpr store body
      psKernelC0Intern s1 (.proj name index b)

/--
  Fail-closed decoder: the available depth strictly decreases along every
  legitimate interned edge. No unchecked array indexing or default terms.
-/
def psKernelC0DecodeExprWithFuel
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat) : Option PsKernelExpr :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet store id
      match stored.node with
      | .bvar i => some (.bvar i)
      | .fvar n => some (.fvar n)
      | .mvar n => some (.mvar n)
      | .sort l => some (.sort l)
      | .const n ls => some (.const n ls)
      | .lit value => some (.lit value)
      | .app fn arg => do
          let f ← psKernelC0DecodeExprWithFuel remaining store fn
          let a ← psKernelC0DecodeExprWithFuel remaining store arg
          some (.app f a)
      | .lam name ty body info => do
          let t ← psKernelC0DecodeExprWithFuel remaining store ty
          let b ← psKernelC0DecodeExprWithFuel remaining store body
          some (.lam name t b info)
      | .forallE name ty body info => do
          let t ← psKernelC0DecodeExprWithFuel remaining store ty
          let b ← psKernelC0DecodeExprWithFuel remaining store body
          some (.forallE name t b info)
      | .letE name ty value body nondep => do
          let t ← psKernelC0DecodeExprWithFuel remaining store ty
          let v ← psKernelC0DecodeExprWithFuel remaining store value
          let b ← psKernelC0DecodeExprWithFuel remaining store body
          some (.letE name t v b nondep)
      | .mdata metadata body => do
          let b ← psKernelC0DecodeExprWithFuel remaining store body
          some (.mdata metadata b)
      | .proj name index body => do
          let b ← psKernelC0DecodeExprWithFuel remaining store body
          some (.proj name index b)

/-- Public decode checks valid arena-local handles before decoding. -/
def psKernelC0DecodeExpr
    (store : PsKernelC0TermStore)
    (id : Nat) : Option PsKernelExpr := do
  let stored ← psKernelC0StoreGet store id
  psKernelC0DecodeExprWithFuel stored.depth store id

/-- Exact syntactic equality via same-store canonical IDs. -/
def psKernelC0EqualNodeIds
    (store : PsKernelC0TermStore)
    (left right : Nat) : Bool :=
  psKernelC0StoreValid store left &&
  psKernelC0StoreValid store right &&
  Nat.beq left right
