import Ps.KernelCore.Core.ExprV2.TransformSpine

/-
C0-compatible beta-spine selection over one canonical owning arena.
Selected arguments are stored in reverse binder order. One simultaneous
instantiation opens every consumed syntactic lambda; leftover arguments are
then reapplied. The transformation's sufficient budget is independent of
checker fuel, exactly as in the original C0 beta operation.
-/
structure PsKernelExprV2BetaPlan where
  body : Nat
  selectedRev : List Nat
  remaining : List Nat

def psKernelExprV2BetaSpineWorker
    (args : List Nat) :
    PsKernelExprV2PagedArena -> Nat -> List Nat ->
    Except String (Option PsKernelExprV2BetaPlan) :=
  match args with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena)
          (_fn : Nat) (_reversed : List Nat) =>
        Except.ok Option.none
  | List.cons arg rest =>
      let smaller :=
        fun (nextArena : PsKernelExprV2PagedArena)
            (nextFn : Nat) (nextReversed : List Nat) =>
          let recur := psKernelExprV2BetaSpineWorker rest;
          recur nextArena nextFn nextReversed;
      fun (arena : PsKernelExprV2PagedArena) (fn : Nat) (reversed : List Nat) =>
        match psKernelExprV2PagedRequire arena fn with
        | Except.error error => Except.error error
        | Except.ok entry =>
            match entry.node with
            | PsKernelExprV2Node.lam _ _ body _ =>
                let selected := List.cons arg reversed;
                match rest with
                | List.nil =>
                    Except.ok
                      (Option.some (PsKernelExprV2BetaPlan.mk body selected List.nil))
                | List.cons _ _ =>
                    match psKernelExprV2PagedRequire arena body with
                    | Except.error error => Except.error error
                    | Except.ok bodyEntry =>
                        match bodyEntry.node with
                        | PsKernelExprV2Node.lam _ _ _ _ =>
                            smaller arena body selected
                        | _ =>
                            Except.ok
                              (Option.some (PsKernelExprV2BetaPlan.mk body selected rest))
            | _ => Except.ok Option.none

def psKernelExprV2BetaSpinePlanOnCanonical
    (arena : PsKernelExprV2PagedArena) (fn : Nat) (args : List Nat) :
    Except String (Option PsKernelExprV2BetaPlan) :=
  psKernelExprV2BetaSpineWorker args arena fn List.nil

def psKernelExprV2BetaSpineApplyOnCanonical
    (arena : PsKernelExprV2PagedArena) (plan : PsKernelExprV2BetaPlan) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  match psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 plan.selectedRev)
      arena plan.body 0 with
  | Except.error error => Except.error error
  | Except.ok opened =>
      psKernelExprV2TransformApplyArgsOnCanonical
        plan.remaining (Prod.fst opened) (Prod.snd opened)
