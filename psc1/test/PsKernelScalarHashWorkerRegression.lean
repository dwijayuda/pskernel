import Lean
import Ps.KernelCore.Runtime.Acceleration.ScalarHash

namespace PsKernelScalarHashWorkerRegression

/- Exact source recursion from 19fb; do not replace with a new specification. -/
def stringHashWorkerBefore
    (fuel : Nat) :
    String -> Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (_value : String)
        (_position : Nat)
        (hash : Nat) =>
        hash
  | Nat.succ remaining =>
      let smaller :
          String -> Nat -> Nat -> Nat :=
        stringHashWorkerBefore remaining;
      fun
        (value : String)
        (position : Nat)
        (hash : Nat) =>
        if
            String.Pos.Raw.atEnd
              value
              (String.Pos.Raw.mk position) then
          hash
        else
          let char :=
            String.Internal.get
              value
              (String.Pos.Raw.mk position);
          let next :=
            String.Pos.Raw.byteIdx
              (String.Pos.Raw.next
                value
                (String.Pos.Raw.mk position));
          smaller
            value
            next
            (psKernelCacheMix
              hash
              (Char.toNat char))


/- Frozen one-transition data recurrence from61deda; proof only, not runtime. -/
def stringHashStateBefore (fuel : Nat) (value : String)
    (initial : Prod Nat Nat) : Prod Nat Nat :=
  match fuel with
  | Nat.zero => initial
  | Nat.succ remaining =>
      psKernelCacheStringHashStep value (stringHashStateBefore remaining value initial)

theorem pairs_eq_before (pairs : Nat) (value : String) (initial : Prod Nat Nat) :
    psKernelCacheStringHashPairsWithFuel pairs value initial =
      stringHashStateBefore (pairs * 2) value initial := by
  induction pairs with
  | zero => rfl
  | succ remaining ih =>
      have count : (Nat.succ remaining) * 2 =
          Nat.succ (Nat.succ (remaining * 2)) := by omega
      rw [count]
      change psKernelCacheStringHashStep value
        (psKernelCacheStringHashStep value
          (psKernelCacheStringHashPairsWithFuel remaining value initial)) =
        psKernelCacheStringHashStep value
          (psKernelCacheStringHashStep value
            (stringHashStateBefore (remaining * 2) value initial))
      rw [ih]

theorem state_eq_before (fuel : Nat) (value : String) (initial : Prod Nat Nat) :
    psKernelCacheStringHashStateWithFuel fuel value initial =
      stringHashStateBefore fuel value initial := by
  change (if Nat.beq (fuel % 2) 0 then
      psKernelCacheStringHashPairsWithFuel (fuel / 2) value initial
    else psKernelCacheStringHashStep value
      (psKernelCacheStringHashPairsWithFuel (fuel / 2) value initial)) =
        stringHashStateBefore fuel value initial
  simp only [pairs_eq_before]
  by_cases even : fuel % 2 = 0
  · have count : (fuel / 2) * 2 = fuel := by omega
    simpa [even] using
      congrArg (fun count => stringHashStateBefore count value initial) count
  · have odd : fuel % 2 = 1 := by omega
    have count : Nat.succ ((fuel / 2) * 2) = fuel := by omega
    simpa [odd, stringHashStateBefore] using
      congrArg (fun count => stringHashStateBefore count value initial) count

theorem state_succ (fuel : Nat) (value : String) (initial : Prod Nat Nat) :
    psKernelCacheStringHashStateWithFuel (Nat.succ fuel) value initial =
      psKernelCacheStringHashStep value
        (psKernelCacheStringHashStateWithFuel fuel value initial) := by
  calc
    psKernelCacheStringHashStateWithFuel (Nat.succ fuel) value initial =
        stringHashStateBefore (Nat.succ fuel) value initial :=
      state_eq_before (Nat.succ fuel) value initial
    _ = psKernelCacheStringHashStep value (stringHashStateBefore fuel value initial) := rfl
    _ = psKernelCacheStringHashStep value
        (psKernelCacheStringHashStateWithFuel fuel value initial) :=
      congrArg (psKernelCacheStringHashStep value) (state_eq_before fuel value initial).symm

theorem state_step_commutes (fuel : Nat) (value : String) (state : Prod Nat Nat) :
    psKernelCacheStringHashStateWithFuel fuel value
        (psKernelCacheStringHashStep value state) =
      psKernelCacheStringHashStep value
        (psKernelCacheStringHashStateWithFuel fuel value state) := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      rw [state_succ, state_succ]
      exact congrArg (psKernelCacheStringHashStep value) ih

theorem state_fixed (fuel : Nat) (value : String) (state : Prod Nat Nat)
    (fixed : psKernelCacheStringHashStep value state = state) :
    psKernelCacheStringHashStateWithFuel fuel value state = state := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      rw [state_succ]
      rw [ih]
      exact fixed

theorem scan_eq_before (fuel : Nat) (value : String) (position hash : Nat) :
    psKernelCacheStringHashScan fuel value position hash =
      stringHashWorkerBefore fuel value position hash := by
  induction fuel generalizing position hash with
  | zero => rfl
  | succ remaining ih =>
      change (psKernelCacheStringHashStateWithFuel (Nat.succ remaining) value
        (Prod.mk position hash)).snd =
          stringHashWorkerBefore (Nat.succ remaining) value position hash
      rw [state_succ]
      rw [← state_step_commutes remaining value (Prod.mk position hash)]
      cases finished : String.Pos.Raw.atEnd value (String.Pos.Raw.mk position) with
      | false =>
          simpa [psKernelCacheStringHashScan, psKernelCacheStringHashStep,
            psKernelCacheMix, stringHashWorkerBefore, finished] using
              ih (String.Pos.Raw.byteIdx
                (String.Pos.Raw.next value (String.Pos.Raw.mk position)))
                (psKernelCacheMix hash
                  (Char.toNat (String.Internal.get value (String.Pos.Raw.mk position))))
      | true =>
          have fixed : psKernelCacheStringHashStep value (Prod.mk position hash) =
              Prod.mk position hash := by
            simp [psKernelCacheStringHashStep, finished]
          rw [fixed, state_fixed remaining value (Prod.mk position hash) fixed]
          simp [stringHashWorkerBefore, finished]

theorem worker_eq_before (fuel : Nat) :
    psKernelCacheStringHashWorker fuel = stringHashWorkerBefore fuel := by
  funext value position hash
  cases fuel with
  | zero => rfl
  | succ remaining =>
      exact scan_eq_before (Nat.succ remaining) value position hash

/- The pure short entry is exact on its selected bounded domain. -/
theorem short_pairs_eq (pairs : Nat) (value : String) (initial : Prod Nat Nat)
    (bounded : pairs <= 4) :
    psKernelCacheStringHashShortPairs pairs value initial =
      psKernelCacheStringHashPairsWithFuel pairs value initial := by
  cases pairs with
  | zero => rfl
  | succ first =>
      cases first with
      | zero => rfl
      | succ second =>
          cases second with
          | zero => rfl
          | succ third =>
              cases third with
              | zero => rfl
              | succ fourth =>
                  cases fourth with
                  | zero => rfl
                  | succ remaining => omega

theorem entry_pairs_eq (pairs : Nat) (value : String) (initial : Prod Nat Nat) :
    (if Nat.ble pairs 4 then psKernelCacheStringHashShortPairs pairs value initial
     else psKernelCacheStringHashPairsWithFuel pairs value initial) =
      psKernelCacheStringHashPairsWithFuel pairs value initial := by
  cases comparison : Nat.ble pairs 4 with
  | false => rfl
  | true =>
      have bounded : pairs <= 4 := by omega
      exact short_pairs_eq pairs value initial bounded

theorem hash_eq_before (value : String) :
    psKernelCacheStringHash value =
      stringHashWorkerBefore (Nat.succ (String.utf8ByteSize value)) value 0 0 := by
  unfold psKernelCacheStringHash
  rw [entry_pairs_eq]
  exact congrArg (fun worker => worker value 0 0)
    (worker_eq_before (Nat.succ (String.utf8ByteSize value)))

/- Entry specialization only; the public staged worker is unchanged. -/
theorem level_list_hash_eq_worker (values : List PsKernelLevel) :
    psKernelCacheLevelListHash values = psKernelCacheLevelListHashWorker values 18 := by
  cases values with
  | nil => rfl
  | cons first rest =>
      cases rest with
      | nil => rfl
      | cons second tail =>
          cases tail with
          | nil => rfl
          | cons third remaining => rfl

end PsKernelScalarHashWorkerRegression

#print axioms PsKernelScalarHashWorkerRegression.short_pairs_eq
#print axioms PsKernelScalarHashWorkerRegression.entry_pairs_eq
#print axioms PsKernelScalarHashWorkerRegression.level_list_hash_eq_worker
#print axioms PsKernelScalarHashWorkerRegression.pairs_eq_before
#print axioms PsKernelScalarHashWorkerRegression.state_eq_before
#print axioms PsKernelScalarHashWorkerRegression.state_succ
#print axioms PsKernelScalarHashWorkerRegression.state_step_commutes
#print axioms PsKernelScalarHashWorkerRegression.state_fixed
#print axioms PsKernelScalarHashWorkerRegression.scan_eq_before
#print axioms PsKernelScalarHashWorkerRegression.worker_eq_before
#print axioms PsKernelScalarHashWorkerRegression.hash_eq_before

def main : IO Unit := do
  let words : List String := ["", "a", "A", "é", "é", "€", "😀", "Aé€😀",
    String.ofList [Char.ofNat 0, 'x'], "_private", "Init.Prelude", "界∀∃"]
  let fuels : List Nat := [0, 1, 2, 4, 8, 32]
  let hashes : List Nat := [0, 65520, 65521, 1234567, 1000000000000000000000000000023]
  let mut count := 0
  for value in words do
    for fuel in fuels do
      for position in List.range (String.utf8ByteSize value + 3) do
        for hash in hashes do
          let expected := PsKernelScalarHashWorkerRegression.stringHashWorkerBefore fuel value position hash
          unless psKernelCacheStringHashScan fuel value position hash == expected do
            throw (IO.userError "scalar hash scan differs from frozen worker")
          unless psKernelCacheStringHashWorker fuel value position hash == expected do
            throw (IO.userError "scalar hash staged worker differs from frozen worker")
          count := count + 1
    unless psKernelCacheStringHash value ==
        PsKernelScalarHashWorkerRegression.stringHashWorkerBefore
          (String.utf8ByteSize value + 1) value 0 0 do
      throw (IO.userError "scalar hash public digest changed")
  let longWords := [
    String.ofList (List.replicate 4096 'A'),
    String.ofList (List.replicate 1024 '😀'),
    String.join (List.replicate 256 "Aé€😀")]
  for value in longWords do
    unless psKernelCacheStringHash value ==
        PsKernelScalarHashWorkerRegression.stringHashWorkerBefore
          (String.utf8ByteSize value + 1) value 0 0 do
      throw (IO.userError "long scalar hash digest changed")
  IO.println "PSC1_SCALAR_HASH_LONG_NATIVE: PASS cases=3"
  IO.println ("PSC1_SCALAR_HASH_WORKER_NATIVE: PASS cases=" ++ toString count ++ " strings=12")
