import Ps.KernelCore.Research.ExprV2PagedEquality

/-
Research-only paged same-arena equality batch. One checked input validation;
operation-scoped memo is reused between comparisons, then discarded.
All error branches fail closed. Definitional equality and kernel admission
are intentionally out of scope.
-/

def psKernelExprV2PagedPairBatchWorker
    (canonical : PsKernelExprV2PagedArena)
    (memo : List PsKernelExprV2PairMemo)
    (pairs : List (Nat × Nat)) :
    Except String
      ((List Bool) × (List PsKernelExprV2PairMemo)) :=
  match pairs with
  | List.nil =>
      Except.ok (Prod.mk List.nil memo)
  | List.cons pair rest =>
      let left := Prod.fst pair;
      let right := Prod.snd pair;
      match psKernelExprV2PagedFind canonical left with
      | Option.none =>
          Except.error "PSKERNEL_V2_BATCH_INVALID_LEFT"
      | Option.some l =>
          match psKernelExprV2PagedFind canonical right with
          | Option.none =>
              Except.error "PSKERNEL_V2_BATCH_INVALID_RIGHT"
          | Option.some r =>
              let depth := psKernelExprV2NatMax l.depth r.depth;
              match
                  psKernelExprV2PagedPairCompareWithFuel
                    (Nat.succ depth)
                    canonical memo left right with
              | Except.error error =>
                  Except.error error
              | Except.ok checked =>
                  match
                      psKernelExprV2PagedPairBatchWorker
                        canonical
                        (Prod.snd checked)
                        rest with
                  | Except.error error =>
                      Except.error error
                  | Except.ok tail =>
                      Except.ok
                        (Prod.mk
                          (List.cons (Prod.fst checked) (Prod.fst tail))
                          (Prod.snd tail))

def psKernelExprV2PagedEqBatchChecked
    (source : PsKernelExprV2PagedArena)
    (pairs : List (Nat × Nat)) :
    Except String (List Bool) :=
  match psKernelExprV2PagedValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match
          psKernelExprV2PagedPairBatchWorker
            canonical
            List.nil
            pairs with
      | Except.error error =>
          Except.error error
      | Except.ok answers =>
          Except.ok (Prod.fst answers)


/- Small portable oracle helper for checking the batch's ordered results in
generated JS. It is not used as an admission predicate. -/
