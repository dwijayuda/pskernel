import Ps.KernelCore.Core.ExprV2.Transform

/- Frozen exact predecessor from f091db586dcbe4a31905d6edf1c8c7957082527d.
   This local refinement preserves complete Except/arena/memo output for all
   inputs, including zero/truncated fuel, forged owners and malformed roots.
   It does not assert global checker soundness or backend preservation. -/
def psKernelTransformEagerReference
    (fuel : Nat) :
    PsKernelExprV2Transform -> PsKernelExprV2TransformState -> Nat -> Nat ->
    Except String (Prod PsKernelExprV2TransformState Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_operation : PsKernelExprV2Transform)
        (state : PsKernelExprV2TransformState) (source _offset : Nat) =>
        match psKernelExprV2PagedFind state.arena source with
        | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
        | Option.some _ => Except.ok (Prod.mk state source)
  | Nat.succ remaining =>
      let smaller := psKernelTransformEagerReference remaining;
      fun (operation : PsKernelExprV2Transform)
        (state : PsKernelExprV2TransformState) (source offset : Nat) =>
        match psKernelExprV2PagedFind state.arena source with
        | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
        | Option.some entry =>
            let effective :=
              if Nat.ble (Nat.succ remaining) entry.depth then Nat.succ remaining
              else entry.depth;
            let depth : Nat :=
              match operation with
              | PsKernelExprV2Transform.levels _ _ => 0
              | _ => offset;
            match psKernelExprV2TransformMemoFind state.memo source depth effective with
            | Option.some result => Except.ok (Prod.mk state result)
            | Option.none =>
                match psKernelExprV2TransformLeaf operation state.arena source depth entry with
                | Except.error error => Except.error error
                | Except.ok leaf =>
                    match Prod.snd leaf with
                    | Option.some result =>
                        Except.ok (psKernelExprV2TransformRebuilt state source depth effective
                          (Prod.mk (Prod.fst leaf) result))
                    | Option.none =>
                        let children := psKernelExprV2TransformChildren entry.node depth;
                        match psKernelExprV2TransformMapChildren children
                            (smaller operation) state with
                        | Except.error error => Except.error error
                        | Except.ok mapped =>
                            let after := Prod.fst mapped;
                            if psKernelExprV2TransformSameChildren children (Prod.snd mapped) then
                              Except.ok (psKernelExprV2TransformFinish after source depth effective source)
                            else
                              match psKernelExprV2TransformBuild after.arena entry.node (Prod.snd mapped) with
                              | Except.error error => Except.error error
                              | Except.ok rebuilt =>
                                  Except.ok (psKernelExprV2TransformRebuilt after source depth effective rebuilt)


theorem psKernelTransformLazyPreservesAllInputs (fuel : Nat) :
    psKernelExprV2TransformWithFuel fuel = psKernelTransformEagerReference fuel := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      rw [psKernelExprV2TransformWithFuel, psKernelTransformEagerReference, ih]
      rfl

#print axioms psKernelTransformLazyPreservesAllInputs
