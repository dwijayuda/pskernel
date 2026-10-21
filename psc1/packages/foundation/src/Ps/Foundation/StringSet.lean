import Ps.Foundation.Name

-- Persistent compiler index. Values produced by empty/add obey the 16-bit hash
-- trie placement invariant. Buckets always check full string equality; hashes
-- are never authority and collisions cannot produce false membership.
inductive PsStringSet where
  | empty
  | bucket (entries : List String)
  | branch (left right : PsStringSet)

def psStringSetHashWithFuel (fuel : Nat) : String -> Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (_value : String) (_position : Nat) (hash : Nat) => hash
  | Nat.succ remaining =>
      fun (value : String) (position : Nat) (hash : Nat) =>
        let smaller : String -> Nat -> Nat -> Nat := psStringSetHashWithFuel remaining;
        if String.Internal.atEnd value (String.Pos.Raw.mk position) then hash
        else
          let code : Nat := Char.toNat (String.Internal.get value (String.Pos.Raw.mk position));
          let next : Nat := String.Pos.Raw.byteIdx
            (String.Internal.next value (String.Pos.Raw.mk position));
          smaller value next (Nat.mod (Nat.add (Nat.mul hash 257) code) 65536)

def psStringSetHash (value : String) : Nat :=
  psStringSetHashWithFuel (Nat.succ (String.utf8ByteSize value)) value 0 0

def psStringSetBucketContains (entries : List String) : String -> Bool :=
  match entries with
  | List.nil => fun (_key : String) => false
  | List.cons entry rest =>
      fun (key : String) =>
        if psStringEq entry key then true else psStringSetBucketContains rest key

def psStringSetContainsWithDepth (depth : Nat) : PsStringSet -> Nat -> String -> Bool :=
  match depth with
  | Nat.zero =>
      fun (index : PsStringSet) (_hash : Nat) (key : String) =>
        match index with
        | PsStringSet.bucket entries => psStringSetBucketContains entries key
        | _ => false
  | Nat.succ remaining =>
      fun (index : PsStringSet) (hash : Nat) (key : String) =>
        let smaller : PsStringSet -> Nat -> String -> Bool :=
          psStringSetContainsWithDepth remaining;
        match index with
        | PsStringSet.empty => false
        | PsStringSet.bucket entries => psStringSetBucketContains entries key
        | PsStringSet.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then smaller left (Nat.div hash 2) key
            else smaller right (Nat.div hash 2) key

def psStringSetInsertWithDepth (depth : Nat) : PsStringSet -> Nat -> String -> PsStringSet :=
  match depth with
  | Nat.zero =>
      fun (index : PsStringSet) (_hash : Nat) (key : String) =>
        let entries : List String :=
          match index with
          | PsStringSet.bucket values => values
          | _ => [];
        PsStringSet.bucket (List.cons key entries)
  | Nat.succ remaining =>
      fun (index : PsStringSet) (hash : Nat) (key : String) =>
        let smaller : PsStringSet -> Nat -> String -> PsStringSet :=
          psStringSetInsertWithDepth remaining;
        match index with
        | PsStringSet.bucket entries => PsStringSet.bucket (List.cons key entries)
        | _ =>
            let left : PsStringSet :=
              match index with
              | PsStringSet.branch value _ => value
              | _ => PsStringSet.empty;
            let right : PsStringSet :=
              match index with
              | PsStringSet.branch _ value => value
              | _ => PsStringSet.empty;
            if Nat.beq (Nat.mod hash 2) 0 then
              PsStringSet.branch (smaller left (Nat.div hash 2) key) right
            else PsStringSet.branch left (smaller right (Nat.div hash 2) key)

def psStringSetContains (index : PsStringSet) (key : String) : Bool :=
  psStringSetContainsWithDepth 16 index (psStringSetHash key) key

-- Return true exactly when the key was newly inserted. Existing snapshots are
-- immutable, and reinsertion leaves their membership unchanged.
def psStringSetAdd (index : PsStringSet) (key : String) : Prod Bool PsStringSet :=
  let hash : Nat := psStringSetHash key;
  if psStringSetContainsWithDepth 16 index hash key then Prod.mk false index
  else Prod.mk true (psStringSetInsertWithDepth 16 index hash key)

def psStringSetInsert (index : PsStringSet) (key : String) : PsStringSet :=
  let added : Prod Bool PsStringSet := psStringSetAdd index key;
  added.snd

def psStringSetFromListWorker (keys : List String) : PsStringSet -> PsStringSet :=
  match keys with
  | List.nil => fun (index : PsStringSet) => index
  | List.cons key rest =>
      fun (index : PsStringSet) =>
        psStringSetFromListWorker rest (psStringSetInsert index key)

def psStringSetFromList (keys : List String) : PsStringSet :=
  psStringSetFromListWorker keys PsStringSet.empty
