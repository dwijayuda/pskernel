import Ps.KernelCore.Runtime.Acceleration.Cache
import Lean
private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_FLAT_BUCKET_FAIL " ++ label))
  IO.println ("PSC1_FLAT_BUCKET_ASSERT " ++ label)
private def sameEntries : List (Prod PsKernelExpr PsKernelExpr) → List (Prod PsKernelExpr PsKernelExpr) → Bool
  | [],[] => true
  | x::xs,y::ys => psKernelExprEqual x.fst y.fst && psKernelExprEqual x.snd y.snd && sameEntries xs ys
  | _,_ => false
private def originalMapBucket
    (fuel : Nat) :
    PsKernelExprMapIndex ->
    Nat ->
    List (Prod PsKernelExpr PsKernelExpr) :=
  match fuel with
  | Nat.zero =>
      fun
        (index : PsKernelExprMapIndex)
        (_hash : Nat) =>
        match index with
        | PsKernelExprMapIndex.bucket entries =>
            entries
        | _ =>
            List.nil
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprMapIndex ->
          Nat ->
          List (Prod PsKernelExpr PsKernelExpr) :=
        originalMapBucket remaining;
      fun
        (index : PsKernelExprMapIndex)
        (hash : Nat) =>
        match index with
        | PsKernelExprMapIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then
              smaller
                left
                (Nat.div hash 2)
            else
              smaller
                right
                (Nat.div hash 2)
        | _ =>
            List.nil


private def originalPairBucket
    (fuel : Nat) :
    PsKernelExprPairSetIndex ->
    Nat ->
    List (Prod PsKernelExpr PsKernelExpr) :=
  match fuel with
  | Nat.zero =>
      fun
        (index : PsKernelExprPairSetIndex)
        (_hash : Nat) =>
        match index with
        | PsKernelExprPairSetIndex.bucket entries =>
            entries
        | _ =>
            List.nil
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprPairSetIndex ->
          Nat ->
          List (Prod PsKernelExpr PsKernelExpr) :=
        originalPairBucket remaining;
      fun
        (index : PsKernelExprPairSetIndex)
        (hash : Nat) =>
        match index with
        | PsKernelExprPairSetIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then
              smaller
                left
                (Nat.div hash 2)
            else
              smaller
                right
                (Nat.div hash 2)
        | _ =>
            List.nil

def main : IO Unit := do
  let mut failed := false
  try require "forced-failure" false catch _ => failed := true
  require "harness-rejection-active" failed
  let a : List (Prod PsKernelExpr PsKernelExpr) := [(.lit (.nat 1),.lit (.nat 2))]
  let b : List (Prod PsKernelExpr PsKernelExpr) := [(.lit (.nat 3),.lit (.nat 4)),(.lit (.nat 5),.lit (.nat 6))]
  let ma := PsKernelExprMapIndex.bucket a
  let mb := PsKernelExprMapIndex.bucket b
  let pa := PsKernelExprPairSetIndex.bucket a
  let pb := PsKernelExprPairSetIndex.bucket b
  let mut fixtures : List (PsKernelExprMapIndex × PsKernelExprPairSetIndex) :=
    [(.empty,.empty),(ma,pa),(mb,pb),(.branch .empty .empty,.branch .empty .empty),
      (.branch ma mb,.branch pa pb),(.branch (.branch ma .empty) mb,.branch (.branch pa .empty) pb)]
  for depth in [0,1,2,4,8,16,17,32] do
    let mut m := ma
    let mut p := pa
    for _ in List.range depth do
      m := .branch m mb
      p := .branch p pb
    fixtures := fixtures ++ [(m,p)]
  for fuel in [0,1,2,3,4,8,16,17,32] do
    for hi in List.range 10 do
      let hashes := [0,1,2,3,7,15,16,65520,65521,2^128+3]
      let hash := hashes[hi]!
      for i in List.range fixtures.length do
        let some indexes := fixtures[i]? | throw (IO.userError "missing indexed fixture")
        require ("map/" ++ toString fuel ++ "/" ++ toString hi ++ "/" ++ toString i)
          (sameEntries (psKernelExprMapIndexBucket fuel indexes.fst hash)
            (originalMapBucket fuel indexes.fst hash))
        require ("pair/" ++ toString fuel ++ "/" ++ toString hi ++ "/" ++ toString i)
          (sameEntries (psKernelExprPairSetIndexBucket fuel indexes.snd hash)
            (originalPairBucket fuel indexes.snd hash))
  IO.println "PSC1_FLAT_BUCKET_NATIVE: PASS controls=2521 fixtures=14 fuels=9 hashes=10 exactOriginal=true publicCurriedABI=true cachePolicyChanged=false performanceQualified=false"
