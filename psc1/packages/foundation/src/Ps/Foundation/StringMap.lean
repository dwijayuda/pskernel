import Ps.Foundation.StringSet

/-! Persistent compiler lookup. The fixed 16-bit trie is an index only: every
bucket lookup checks full String equality. Insertion returns a new snapshot and
replaces only an exactly equal key. No host map, hash primitive or FFI is used. -/

inductive PsStringMap (alpha : Type) where
  | empty
  | bucket (entries : List (Prod String alpha))
  | branch (left right : PsStringMap alpha)

def psStringMapBucketGet {alpha : Type} (entries : List (Prod String alpha))
    (key : String) : Option alpha :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq entry.fst key then Option.some entry.snd
      else psStringMapBucketGet rest key

def psStringMapBucketPut {alpha : Type} (entries : List (Prod String alpha))
    (key : String) (value : alpha) : List (Prod String alpha) :=
  match entries with
  | List.nil => [Prod.mk key value]
  | List.cons entry rest =>
      if psStringEq entry.fst key then List.cons (Prod.mk key value) rest
      else List.cons entry (psStringMapBucketPut rest key value)

def psStringMapGetWithDepth {alpha : Type} (depth : Nat) :
    PsStringMap alpha -> Nat -> String -> Option alpha :=
  match depth with
  | Nat.zero =>
      fun (index : PsStringMap alpha) (_hash : Nat) (key : String) =>
        match index with
        | PsStringMap.bucket entries => psStringMapBucketGet entries key
        | _ => Option.none
  | Nat.succ remaining =>
      fun (index : PsStringMap alpha) (hash : Nat) (key : String) =>
        match index with
        | PsStringMap.empty => Option.none
        | PsStringMap.bucket entries => psStringMapBucketGet entries key
        | PsStringMap.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then
              psStringMapGetWithDepth remaining left (Nat.div hash 2) key
            else psStringMapGetWithDepth remaining right (Nat.div hash 2) key

def psStringMapPutWithDepth {alpha : Type} (depth : Nat) :
    PsStringMap alpha -> Nat -> String -> alpha -> PsStringMap alpha :=
  match depth with
  | Nat.zero =>
      fun (index : PsStringMap alpha) (_hash : Nat) (key : String) (value : alpha) =>
        let entries : List (Prod String alpha) := match index with
          | PsStringMap.bucket values => values
          | _ => [];
        PsStringMap.bucket (psStringMapBucketPut entries key value)
  | Nat.succ remaining =>
      fun (index : PsStringMap alpha) (hash : Nat) (key : String) (value : alpha) =>
        match index with
        | PsStringMap.bucket entries =>
            PsStringMap.bucket (psStringMapBucketPut entries key value)
        | _ =>
            let left : PsStringMap alpha := match index with
              | PsStringMap.branch current _ => current
              | _ => PsStringMap.empty;
            let right : PsStringMap alpha := match index with
              | PsStringMap.branch _ current => current
              | _ => PsStringMap.empty;
            if Nat.beq (Nat.mod hash 2) 0 then
              PsStringMap.branch
                (psStringMapPutWithDepth remaining left (Nat.div hash 2) key value) right
            else PsStringMap.branch left
                (psStringMapPutWithDepth remaining right (Nat.div hash 2) key value)

def psStringMapGet {alpha : Type} (index : PsStringMap alpha)
    (key : String) : Option alpha :=
  psStringMapGetWithDepth 16 index (psStringSetHash key) key

def psStringMapPut {alpha : Type} (index : PsStringMap alpha)
    (key : String) (value : alpha) : PsStringMap alpha :=
  psStringMapPutWithDepth 16 index (psStringSetHash key) key value

def psStringMapContains {alpha : Type} (index : PsStringMap alpha) (key : String) : Bool :=
  match psStringMapGet index key with
  | Option.none => false
  | Option.some _ => true

