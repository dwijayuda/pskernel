import Ps.KernelCore.Checker.DefEq.Quick
import Ps.KernelCore.Core.ExprV2.Equality

/-
The definitive entry rules of the complete checker on a canonical DAG.

The public caller fully checks both operands first, then starts a fresh DefEq
operation. Fuel and recursion-depth guards precede every syntax comparison.
After collision-safe structural equality, Sort/Sort and Lit/Lit are decisive;
paired metadata recurses with the predecessor DefEq fuel and entered context.

Some (ok false) is a definitive negative result of an original quick rule.
None requests the complete algorithm; structural inequality alone never decides
DefEq. Unsupported descendants discard this attempt and restart the complete
operation with its original fuel and context.

This worker is only for a fresh operation. A paired-metadata descent is linear:
no successful-pair cache is populated before the child returns, and no sibling
can reuse its result. No context or semantic memo crosses an operation boundary.
It is not a replacement for recursive DefEq callbacks with an existing state.
-/
def psKernelExprV2TryQuickDefEqWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext ->
    PsKernelExprV2PagedArena ->
    Nat -> Nat ->
    Option (Except String Bool) :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsKernelCheckerContext)
          (_arena : PsKernelExprV2PagedArena)
          (_left _right : Nat) =>
        Option.some
          (Except.error "kernel definitional equality budget exhausted")
  | Nat.succ remaining =>
      let smaller :
          PsKernelCheckerContext ->
          PsKernelExprV2PagedArena ->
          Nat -> Nat ->
          Option (Except String Bool) :=
        fun (nextContext : PsKernelCheckerContext)
            (nextArena : PsKernelExprV2PagedArena)
            (nextLeft nextRight : Nat) =>
          let recur := psKernelExprV2TryQuickDefEqWithFuel remaining;
          recur nextContext nextArena nextLeft nextRight;
      fun (context : PsKernelCheckerContext)
          (arena : PsKernelExprV2PagedArena)
          (left right : Nat) =>
        match psKernelCheckerContextEnterRecDepth context with
        | Except.error error =>
            Option.some (Except.error error)
        | Except.ok nextContext =>
            match psKernelExprV2PagedEqOnCanonical arena left right with
            | Except.error error =>
                Option.some (Except.error error)
            | Except.ok equal =>
                if equal then
                  Option.some (Except.ok true)
                else
                  match psKernelExprV2PagedRequire arena left with
                  | Except.error error =>
                      Option.some (Except.error error)
                  | Except.ok leftEntry =>
                      match psKernelExprV2PagedRequire arena right with
                      | Except.error error =>
                          Option.some (Except.error error)
                      | Except.ok rightEntry =>
                          match leftEntry.node with
                          | PsKernelExprV2Node.sort leftLevel =>
                              match rightEntry.node with
                              | PsKernelExprV2Node.sort rightLevel =>
                                  Option.some
                                    (Except.ok
                                      (psKernelLevelEquivalent
                                        leftLevel rightLevel))
                              | _ => Option.none
                          | PsKernelExprV2Node.lit leftLiteral =>
                              match rightEntry.node with
                              | PsKernelExprV2Node.lit rightLiteral =>
                                  Option.some
                                    (Except.ok
                                      (psKernelLiteralEq
                                        leftLiteral rightLiteral))
                              | _ => Option.none
                          | PsKernelExprV2Node.mdata _ leftBody =>
                              match rightEntry.node with
                              | PsKernelExprV2Node.mdata _ rightBody =>
                                  smaller nextContext arena leftBody rightBody
                              | _ => Option.none
                          | _ => Option.none
