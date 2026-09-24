import Lean
import Std.Data.HashMap.Basic

open Lean
open Std (HashMap)

def mdataBucketKey (d : KVMap) : String := Id.run do
  let mut seen : NameSet := {}
  let mut keyCount : Nat := 0
  let mut keyHash : UInt64 := 0
  for (k, _) in d do
    unless seen.contains k do
      seen := seen.insert k
      keyCount := keyCount + 1
      keyHash := keyHash + k.hash
  return s!"{keyCount}:{keyHash}"

def check (label : String) (a b : KVMap) : IO Unit := do
  unless a == b do throw <| IO.userError s!"{label}: expected KVMap BEq"
  unless mdataBucketKey a == mdataBucketKey b do
    throw <| IO.userError s!"{label}: equal KVMaps received different bucket keys"

def main : IO Unit := do
  let k1 := `bucket.k1
  let k2 := `bucket.k2
  let v1 := DataValue.ofNat 1
  let v2 := DataValue.ofString "v"
  let single : KVMap := ⟨[(k1,v1)]⟩
  let duplicate : KVMap := ⟨[(k1,v1),(k1,v1)]⟩
  check "duplicate-key normalization" single duplicate
  let ordered : KVMap := ⟨[(k1,v1),(k2,v2)]⟩
  let reversed : KVMap := ⟨[(k2,v2),(k1,v1)]⟩
  check "entry-order normalization" ordered reversed
  IO.println "mdata-bucket-invariants: PASS"
