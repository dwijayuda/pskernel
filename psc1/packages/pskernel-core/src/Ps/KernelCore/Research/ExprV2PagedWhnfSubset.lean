import Ps.KernelCore.Research.ExprV2PagedHeadMachine

/-
Expression V2: portable research WHNF subset with APPLICATION-FUNCTION
normalization. This is deliberately a restricted, total, fuel-bounded
algorithm. It handles:
  - direct beta on a lambda function,
  - zeta (let binders),
  - transparent metadata,
  - beta where the application function itself first reduces to a lambda,
  - rebuilding a neutral application when its function head changed.

It does NOT implement environment delta unfolding, recursor/iota, primitive
reductions, projection reduction, proof irrelevance, full DefEq, or the
published kernel fuel policy. A stuck neutral term is not a typing verdict.

The checked public entrypoint replay-validates the entire input DAG once
and the output DAG once. The private source operations use only canonical
immutably built entries and V2 paged smart constructors.

The recursion budget bounds depth, not Lean 4's real accumulated checker
fuel. No production checker may consume this result for proof acceptance.
-/

def psKernelExprV2PagedWhnfFunctionResult
    (recurse :
      PsKernelExprV2PagedArena ->
      Nat ->
      Except String (PsKernelExprV2PagedArena × Nat))
    (arena : PsKernelExprV2PagedArena)
    (originalRoot originalFn reducedFn argument : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match psKernelExprV2PagedFind arena reducedFn with
  | Option.none =>
      Except.error "PSKERNEL_V2_WHNF_SUBSET_BAD_FUNCTION"
  | Option.some entry =>
      match entry.node with
      | PsKernelExprV2Node.lam _ _ body _ =>
          match
              psKernelExprV2PagedInstOnCanonical
                arena body argument with
          | Except.error error =>
              Except.error error
          | Except.ok instantiated =>
              recurse (Prod.fst instantiated) (Prod.snd instantiated)
      | _ =>
          if Nat.beq originalFn reducedFn then
            Except.ok (Prod.mk arena originalRoot)
          else
            psKernelExprV2PagedMkApp
              arena reducedFn argument

def psKernelExprV2PagedWhnfSubsetWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena ->
    Nat ->
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) =>
        fun (_root : Nat) =>
          Except.error "PSKERNEL_V2_WHNF_SUBSET_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2PagedArena ->
          Nat ->
          Except String (PsKernelExprV2PagedArena × Nat) :=
        psKernelExprV2PagedWhnfSubsetWithFuel remaining;
      fun (arena : PsKernelExprV2PagedArena) =>
        fun (root : Nat) =>
          match psKernelExprV2PagedFind arena root with
          | Option.none =>
              Except.error "PSKERNEL_V2_WHNF_SUBSET_BAD_ROOT"
          | Option.some entry =>
              match entry.node with
              | PsKernelExprV2Node.app fn argument =>
                  match smaller arena fn with
                  | Except.error error =>
                      Except.error error
                  | Except.ok normalizedFn =>
                      psKernelExprV2PagedWhnfFunctionResult
                        smaller
                        (Prod.fst normalizedFn)
                        root fn (Prod.snd normalizedFn) argument
              | PsKernelExprV2Node.letE _ _ value body _ =>
                  match psKernelExprV2PagedInstOnCanonical
                      arena body value with
                  | Except.error error =>
                      Except.error error
                  | Except.ok reduced =>
                      smaller (Prod.fst reduced) (Prod.snd reduced)
              | PsKernelExprV2Node.mdata _ body =>
                  smaller arena body
              | _ =>
                  Except.ok (Prod.mk arena root)

def psKernelExprV2PagedWhnfSubsetChecked
    (fuel : Nat)
    (source : PsKernelExprV2PagedArena)
    (root : Nat) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match psKernelExprV2PagedValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match psKernelExprV2PagedFind canonical root with
      | Option.none =>
          Except.error "PSKERNEL_V2_WHNF_SUBSET_BAD_ROOT"
      | Option.some _ =>
          match psKernelExprV2PagedWhnfSubsetWithFuel
              fuel canonical root with
          | Except.error error =>
              Except.error error
          | Except.ok reduced =>
              match psKernelExprV2PagedValidate (Prod.fst reduced) with
              | Except.error error =>
                  Except.error error
              | Except.ok verified =>
                  Except.ok (Prod.mk verified (Prod.snd reduced))
