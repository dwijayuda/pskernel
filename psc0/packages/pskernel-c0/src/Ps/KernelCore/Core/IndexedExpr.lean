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
  -- Exact interning fingerprint, including binder user names and info.
  hash : Nat
  -- Fingerprint compatible with the accepting source expression caches.
  -- Unlike 'hash', this deliberately ignores binder names and binder info.
  -- It is an index hint, NEVER an equality/DefEq/typing decision.
  checkerHash : Nat
  depth : Nat
  -- Exact upper bound for loose de Bruijn variables: max loose index + 1.
  -- Zero means no loose variables. Derived only from canonical children.
  looseBVarRange : Nat

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

/-- Term-store-local loose-variable metadata, never a checked typing oracle. -/
def psKernelC0ChildLooseRange
    (store : PsKernelC0TermStore)
    (id : Nat) : Nat :=
  match psKernelC0StoreGet store id with
  | Option.some entry => entry.looseBVarRange
  | Option.none => 0

/-- Maximum loose de Bruijn variable + 1 in the exact indexed node.
    Binder bodies close the zero-index variable and shift all others down.
    Computation is O(arity) using already checked child metadata. -/
def psKernelC0NodeLooseRange
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) : Nat :=
  let range := psKernelC0ChildLooseRange store
  match node with
  | .bvar i => i + 1
  | .app fn arg => Nat.max (range fn) (range arg)
  | .lam _ ty body _ => Nat.max (range ty) (range body - 1)
  | .forallE _ ty body _ => Nat.max (range ty) (range body - 1)
  | .letE _ ty value body _ =>
      Nat.max (range ty) (Nat.max (range value) (range body - 1))
  | .mdata _ body => range body
  | .proj _ _ body => range body
  | _ => 0

/-- Include every binder identity field in the canonical-node hash.
    This is only an acceleration hint: exact node equality still guards
    every hash collision. -/
def psKernelC0BinderInfoHash (info : PsKernelBinderInfo) : Nat :=
  match info with
  | .default => 0
  | .implicit => 1
  | .strictImplicit => 2
  | .instImplicit => 3

/--
  Produce both fingerprints from immutable, already-interned child nodes.

  The first hash identifies exact syntax for canonical node interning,
  including binder user names and binder information. The second matches
  psKernelExprHash exactly, which intentionally omits those binder fields
  because checker cache keys use psKernelExprEq. A cache lookup still checks
  the full applicable equality predicate on hash collisions. Neither hash
  establishes definitional equality or a checked judgment.
-/
def psKernelC0ChildCheckerHash
    (store : PsKernelC0TermStore)
    (id : Nat) : Nat :=
  match psKernelC0StoreGet store id with
  | some entry => entry.checkerHash
  | none => 0

def psKernelC0NodeHashes
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) : Prod Nat Nat :=
  let exact := psKernelC0ChildHash store
  let checked := psKernelC0ChildCheckerHash store
  match node with
  | .bvar i =>
      let hash := psKernelCacheMix 21 i
      (hash, hash)
  | .fvar n =>
      let hash := psKernelCacheMix 22 (psKernelCacheNameHash n)
      (hash, hash)
  | .mvar n =>
      let hash := psKernelCacheMix 23 (psKernelCacheNameHash n)
      (hash, hash)
  | .sort l =>
      let hash := psKernelCacheMix 24 (psKernelCacheLevelHash l)
      (hash, hash)
  | .const n ls =>
      let hash := psKernelCacheMix
        (psKernelCacheMix 25 (psKernelCacheNameHash n))
        (psKernelCacheLevelListHash ls)
      (hash, hash)
  | .app fn arg =>
      (psKernelCacheMix (psKernelCacheMix 26 (exact fn)) (exact arg),
       psKernelCacheMix (psKernelCacheMix 26 (checked fn)) (checked arg))
  | .lam name ty body info =>
      (psKernelCacheMix
         (psKernelCacheMix
           (psKernelCacheMix
             (psKernelCacheMix 27 (psKernelCacheNameHash name))
             (exact ty))
           (exact body))
         (psKernelC0BinderInfoHash info),
       psKernelCacheMix
         (psKernelCacheMix 27 (checked ty))
         (checked body))
  | .forallE name ty body info =>
      (psKernelCacheMix
         (psKernelCacheMix
           (psKernelCacheMix
             (psKernelCacheMix 28 (psKernelCacheNameHash name))
             (exact ty))
           (exact body))
         (psKernelC0BinderInfoHash info),
       psKernelCacheMix
         (psKernelCacheMix 28 (checked ty))
         (checked body))
  | .letE name ty value body nondep =>
      let flag := if nondep then 1 else 0
      (psKernelCacheMix
         (psKernelCacheMix
           (psKernelCacheMix
             (psKernelCacheMix
               (psKernelCacheMix 29 (psKernelCacheNameHash name))
               (exact ty))
             (exact value))
           (exact body))
         flag,
       psKernelCacheMix
         (psKernelCacheMix
           (psKernelCacheMix
             (psKernelCacheMix 29 (checked ty))
             (checked value))
           (checked body))
         flag)
  | .lit l =>
      let hash := psKernelCacheMix 30 (psKernelCacheLiteralHash l)
      (hash, hash)
  | .mdata m body =>
      (psKernelCacheMix (psKernelCacheMix 31 m) (exact body),
       psKernelCacheMix (psKernelCacheMix 31 m) (checked body))
  | .proj n i body =>
      (psKernelCacheMix
         (psKernelCacheMix
           (psKernelCacheMix 32 (psKernelCacheNameHash n))
           i)
         (exact body),
       psKernelCacheMix
         (psKernelCacheMix
           (psKernelCacheMix 32 (psKernelCacheNameHash n))
           i)
         (checked body))

/-- Exact syntactic interning hash; do not substitute checker cache hash. -/
def psKernelC0NodeHash
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) : Nat :=
  (psKernelC0NodeHashes store node).fst

/-- Source checker cache hash; used only as a candidate bucket selector. -/
def psKernelC0NodeCheckerHash
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) : Nat :=
  (psKernelC0NodeHashes store node).snd

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
    let (hash, checkerHash) := psKernelC0NodeHashes store node
    let bucket := psKernelC0TermTrieBucket psKernelC0IndexDepth store.index hash
    match psKernelC0FindNode store node bucket with
    | Option.some id =>
        Option.some (Prod.mk store id)
    | Option.none =>
        let id := store.nodes.size
        let entry : PsKernelC0StoredNode :=
          { node := node, hash := hash, checkerHash := checkerHash,
            depth := psKernelC0NodeDepth store node,
            looseBVarRange := psKernelC0NodeLooseRange store node }
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

/-
  Indexed-to-source conversion is a DAG traversal, not an AST tree walk.
  A canonical node may appear exponentially often in the unfolded term.
  Memoize decoded immutable source subterms within *one* decode operation.

  The remaining recursion budget is part of the key. This matters for
  malformed/stale/cyclic externally constructed stores: a result decoded
  with generous fuel must never authorize the same node under less fuel.
  No memo or term handle crosses stores or decode operations. The historical
  pure recursive decoder above stays an independent exact oracle.
-/
abbrev PsKernelC0DecodeMemo :=
  PsKernelC0HashTrie (Nat × Nat × PsKernelExpr)

/-- Exact key comparison; hash collisions never authorize a decoded term. -/
def psKernelC0DecodeMemoFind
    (id fuel : Nat) :
    List (Nat × Nat × PsKernelExpr) → Option PsKernelExpr
  | [] => none
  | (savedId, savedFuel, expr) :: rest =>
      if savedId == id && savedFuel == fuel then some expr
      else psKernelC0DecodeMemoFind id fuel rest

def psKernelC0DecodeMemoHash (id fuel : Nat) : Nat :=
  psKernelCacheMix (psKernelCacheMix 67 id) fuel

def psKernelC0DecodeMemoLookup
    (memo : PsKernelC0DecodeMemo)
    (id fuel : Nat) : Option PsKernelExpr :=
  psKernelC0DecodeMemoFind id fuel
    (psKernelC0TrieBucket psKernelC0IndexDepth memo
      (psKernelC0DecodeMemoHash id fuel))

def psKernelC0DecodeMemoInsert
    (memo : PsKernelC0DecodeMemo)
    (id fuel : Nat)
    (expr : PsKernelExpr) : PsKernelC0DecodeMemo :=
  let hash := psKernelC0DecodeMemoHash id fuel
  let bucket := psKernelC0TrieBucket psKernelC0IndexDepth memo hash
  psKernelC0TrieSet psKernelC0IndexDepth memo hash
    ((id, fuel, expr) :: bucket)

/-- Decode with the exact historical fuel-bound semantics, sharing already
    decoded immutable subexpressions of the same canonical store. -/
def psKernelC0DecodeMemoWithFuel
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (memo : PsKernelC0DecodeMemo)
    (id : Nat) : Option (PsKernelExpr × PsKernelC0DecodeMemo) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet store id
      match psKernelC0DecodeMemoLookup memo id fuel with
      | some cached => some (cached, memo)
      | none => do
          let (decoded, nextMemo) ←
            match stored.node with
            | .bvar i => some (.bvar i, memo)
            | .fvar n => some (.fvar n, memo)
            | .mvar n => some (.mvar n, memo)
            | .sort l => some (.sort l, memo)
            | .const n ls => some (.const n ls, memo)
            | .lit value => some (.lit value, memo)
            | .app fn arg => do
                let (f, memo1) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo fn
                let (a, memo2) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo1 arg
                some (.app f a, memo2)
            | .lam name ty body info => do
                let (t, memo1) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo ty
                let (b, memo2) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo1 body
                some (.lam name t b info, memo2)
            | .forallE name ty body info => do
                let (t, memo1) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo ty
                let (b, memo2) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo1 body
                some (.forallE name t b info, memo2)
            | .letE name ty value body nondep => do
                let (t, memo1) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo ty
                let (v, memo2) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo1 value
                let (b, memo3) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo2 body
                some (.letE name t v b nondep, memo3)
            | .mdata metadata body => do
                let (b, memo1) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo body
                some (.mdata metadata b, memo1)
            | .proj name index body => do
                let (b, memo1) ← psKernelC0DecodeMemoWithFuel
                  remaining store memo body
                some (.proj name index b, memo1)
          some (decoded, psKernelC0DecodeMemoInsert nextMemo id fuel decoded)

/-- Memo storage is intentionally fresh for every operation, and never
    determines DefEq, typing, or environment-specific reduction. -/
def psKernelC0DecodeExprMemoizedWithFuel
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat) : Option PsKernelExpr := do
  let (expr, _) ← psKernelC0DecodeMemoWithFuel
    fuel store PsKernelC0HashTrie.empty id
  some expr

/-- Public decode checks valid arena-local handles before decoding. -/
def psKernelC0DecodeExpr
    (store : PsKernelC0TermStore)
    (id : Nat) : Option PsKernelExpr := do
  let stored ← psKernelC0StoreGet store id
  psKernelC0DecodeExprMemoizedWithFuel stored.depth store id

/-- Exact syntactic equality via same-store canonical IDs. -/
def psKernelC0EqualNodeIds
    (store : PsKernelC0TermStore)
    (left right : Nat) : Bool :=
  psKernelC0StoreValid store left &&
  psKernelC0StoreValid store right &&
  Nat.beq left right
