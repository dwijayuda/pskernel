import Ps.KernelCore.Research.ExprV2PortableEquality

/-
Expression V2 M4 / research-only scope-safe structural equality batch.

A single public checked entry validates an entire external arena exactly
once. All pairs are compared only in that same immutable canonical arena,
with memoized structural results reused throughout this one batch.
The memo is not stored in the environment, other sessions, or any global
cache. It is discarded on return.

Like the single-pair validator, equal cached hashes NEVER certify equality.
Only same-arena node identity or full structural comparison can succeed.
Malformed node references and forged metadata fail the complete batch.
This is NOT kernel definitional equality and grants no proof admission.
-/

def psKernelExprV2PairBatchWorker
    (canonical : PsKernelExprV2ChunkedArena)
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
      match psKernelExprV2ChunkedFind canonical left with
      | Option.none =>
          Except.error "PSKERNEL_V2_BATCH_INVALID_LEFT"
      | Option.some l =>
          match psKernelExprV2ChunkedFind canonical right with
          | Option.none =>
              Except.error "PSKERNEL_V2_BATCH_INVALID_RIGHT"
          | Option.some r =>
              let depth := psKernelExprV2NatMax l.depth r.depth;
              match
                  psKernelExprV2PairCompareWithFuel
                    (Nat.succ depth)
                    canonical memo left right with
              | Except.error error =>
                  Except.error error
              | Except.ok checked =>
                  match
                      psKernelExprV2PairBatchWorker
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

def psKernelExprV2PortableEqBatchChecked
    (source : PsKernelExprV2ChunkedArena)
    (pairs : List (Nat × Nat)) :
    Except String (List Bool) :=
  match psKernelExprV2PortableValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match
          psKernelExprV2PairBatchWorker
            canonical
            List.nil
            pairs with
      | Except.error error =>
          Except.error error
      | Except.ok answers =>
          Except.ok (Prod.fst answers)
