import Ps.KernelCore.Research.ExprV2PortableReduction

/-
PSC1-portable, explicitly bounded composition of V2 head steps.

Only direct beta, zeta and metadata reductions are supported. This is NOT
general WHNF, full definitional equality, or the published kernel fuel
policy. A neutral final check consumes one unit of this research-specific
step budget; exhaustion returns an error instead of silently accepting a
partially reduced expression.

Each internal head step currently revalidates the entire arena. This is a
correctness reference, not a fast-path implementation or performance claim.
-/

def psKernelExprV2PortableHeadSequenceWithFuel
    (fuel : Nat) :
    PsKernelExprV2ChunkedArena ->
    Nat ->
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2ChunkedArena) =>
        fun (_root : Nat) =>
          Except.error "PSKERNEL_V2_HEAD_SEQUENCE_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2ChunkedArena ->
          Nat ->
          Except String (PsKernelExprV2ChunkedArena × Nat) :=
        psKernelExprV2PortableHeadSequenceWithFuel remaining;
      fun (arena : PsKernelExprV2ChunkedArena) =>
        fun (root : Nat) =>
          match psKernelExprV2PortableHeadStepChecked arena root with
          | Except.error error =>
              Except.error error
          | Except.ok step =>
              let nextArena := Prod.fst step;
              let nextRoot := Prod.snd step;
              if Nat.beq root nextRoot then
                Except.ok step
              else
                smaller nextArena nextRoot

def psKernelExprV2PortableHeadSequenceChecked
    (fuel : Nat) (arena : PsKernelExprV2ChunkedArena)
    (root : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) :=
  psKernelExprV2PortableHeadSequenceWithFuel fuel arena root
