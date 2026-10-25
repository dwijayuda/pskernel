import Ps.KernelCore.Core.ExprV2.Transform
import Ps.KernelCore.Core.ExprV2.Lift

/- Frozen predecessor-construction workers copied byte-for-byte from source
   10144e2f9e8d223b5dcde275bd1f48d25df113b3. These equations compare complete
   results, states, diagnostics, and fuel behavior for arbitrary inputs. -/
namespace PsKernelDeferredTransformProofs

namespace Frozen

def psKernelExprV2TransformWithFuel
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
      let smaller := psKernelExprV2TransformWithFuel remaining;
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

def psKernelExprV2TransformCountWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> List PsKernelExprV2TransformCountMemo -> Nat ->
    Except String (Prod (List PsKernelExprV2TransformCountMemo) Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena)
          (_memo : List PsKernelExprV2TransformCountMemo) (_root : Nat) =>
        Except.error "PSKERNEL_V2_TRANSFORM_COUNT_FUEL"
  | Nat.succ remaining =>
      let smaller := psKernelExprV2TransformCountWithFuel remaining;
      fun (arena : PsKernelExprV2PagedArena)
          (memo : List PsKernelExprV2TransformCountMemo) (root : Nat) =>
        match psKernelExprV2TransformCountFind memo root with
        | Option.some count => Except.ok (Prod.mk memo count)
        | Option.none =>
            match psKernelExprV2PagedFind arena root with
            | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
            | Option.some entry =>
                match psKernelExprV2TransformCountChildren
                    (psKernelExprV2TransformChildren entry.node 0) (smaller arena) memo with
                | Except.error error => Except.error error
                | Except.ok result =>
                    let count := Nat.succ (Prod.snd result);
                    Except.ok (Prod.mk
                      (List.cons (PsKernelExprV2TransformCountMemo.mk root count) (Prod.fst result)) count)

def psKernelExprV2PagedLiftWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedLiftState -> Nat -> Nat -> Nat ->
    Except String (PsKernelExprV2PagedLiftState × Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_state : PsKernelExprV2PagedLiftState) =>
        fun (_source : Nat) =>
          fun (_cutoff : Nat) =>
            fun (_amount : Nat) =>
              Except.error "PSKERNEL_V2_PORTABLE_LIFT_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2PagedLiftState -> Nat -> Nat -> Nat ->
          Except String (PsKernelExprV2PagedLiftState × Nat) :=
        psKernelExprV2PagedLiftWithFuel remaining;
      fun (state : PsKernelExprV2PagedLiftState) =>
        fun (source : Nat) =>
          fun (cutoff : Nat) =>
            fun (amount : Nat) =>
              if Nat.beq amount 0 then
                Except.ok (Prod.mk state source)
              else
                match psKernelExprV2PagedFind state.arena source with
                | Option.none =>
                    Except.error "PSKERNEL_V2_PORTABLE_LIFT_INVALID_NODE"
                | Option.some entry =>
                    if Nat.ble entry.looseRange cutoff then
                      Except.ok (Prod.mk state source)
                    else
                      match psKernelExprV2PagedLiftMemoFind
                          state.memo source cutoff amount with
                      | Option.some prior =>
                          Except.ok (Prod.mk state prior)
                      | Option.none =>
                          match entry.node with
                          | PsKernelExprV2Node.bvar index =>
                              if Nat.blt index cutoff then
                                Except.ok
                                  (psKernelExprV2PagedLiftFinish
                                    state source cutoff amount source)
                              else
                                match psKernelExprV2PagedMkBVar
                                    state.arena (Nat.add index amount) with
                                | Except.error error => Except.error error
                                | Except.ok rebuilt =>
                                    Except.ok
                                      (psKernelExprV2PagedLiftRebuilt
                                        state source cutoff amount rebuilt)
                          | PsKernelExprV2Node.app fn arg =>
                              psKernelExprV2PagedLiftTwo
                                smaller
                                psKernelExprV2PagedMkApp
                                state source fn arg
                                cutoff cutoff cutoff amount
                          | PsKernelExprV2Node.lam name type body binderInfo =>
                              psKernelExprV2PagedLiftTwo
                                smaller
                                (psKernelExprV2PagedLiftMkLam name binderInfo)
                                state source type body
                                cutoff cutoff (Nat.succ cutoff) amount
                          | PsKernelExprV2Node.forallE name type body binderInfo =>
                              psKernelExprV2PagedLiftTwo
                                smaller
                                (psKernelExprV2PagedLiftMkForall name binderInfo)
                                state source type body
                                cutoff cutoff (Nat.succ cutoff) amount
                          | PsKernelExprV2Node.letE name type value body nondep =>
                              psKernelExprV2PagedLiftThree
                                smaller
                                (psKernelExprV2PagedLiftMkLet name nondep)
                                state source type value body cutoff amount
                          | PsKernelExprV2Node.mdata tag body =>
                              psKernelExprV2PagedLiftOne
                                smaller
                                (psKernelExprV2PagedLiftMkMData tag)
                                state source body cutoff cutoff amount
                          | PsKernelExprV2Node.proj typeName index body =>
                              psKernelExprV2PagedLiftOne
                                smaller
                                (psKernelExprV2PagedLiftMkProj typeName index)
                                state source body cutoff cutoff amount
                          | _ =>
                              Except.ok
                                (psKernelExprV2PagedLiftFinish
                                  state source cutoff amount source)

end Frozen

theorem transform_with_fuel_eq (fuel : Nat) :
    psKernelExprV2TransformWithFuel fuel =
      Frozen.psKernelExprV2TransformWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      funext operation state source offset
      simp only [psKernelExprV2TransformWithFuel,
        Frozen.psKernelExprV2TransformWithFuel, ih] <;> rfl

theorem count_with_fuel_eq (fuel : Nat) :
    psKernelExprV2TransformCountWithFuel fuel =
      Frozen.psKernelExprV2TransformCountWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      funext arena memo root
      simp only [psKernelExprV2TransformCountWithFuel,
        Frozen.psKernelExprV2TransformCountWithFuel, ih] <;> rfl

theorem lift_with_fuel_eq (fuel : Nat) :
    psKernelExprV2PagedLiftWithFuel fuel =
      Frozen.psKernelExprV2PagedLiftWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      funext state source cutoff amount
      simp only [psKernelExprV2PagedLiftWithFuel,
        Frozen.psKernelExprV2PagedLiftWithFuel, ih] <;> rfl

end PsKernelDeferredTransformProofs

#print axioms PsKernelDeferredTransformProofs.transform_with_fuel_eq
#print axioms PsKernelDeferredTransformProofs.count_with_fuel_eq
#print axioms PsKernelDeferredTransformProofs.lift_with_fuel_eq
