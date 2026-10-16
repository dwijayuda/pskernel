import Ps.KernelCore.Core.ExprDecidableEq

/-!
Experimental proof-producing exact expression equality for shared application
DAGs. This is not the kernel's binder-insensitive DefEq: it decides precise
propositional source AST equality, including source binder metadata.

Lean 4.35's proof-constrained withPtrEqDecEq can skip comparisons for
physically shared subtrees without ever asserting unequal syntax is equal.
Only application children recurse through this optimization at first; all
other constructors retain the original structural DecidableEq instance.

This module contains NO unsafe, axioms, admits or new trusted acceptance.
The result is a Decidable (left = right) witness, and the all-input
source-equivalence theorem uses proof irrelevance of Decidable.
-/

/-- Proof-producing pointer sharing shortcut recursively across nested
application nodes. When pointers differ, compare exact source structure;
a mismatch never uses a raw pointer-inequality judgment. -/
def psKernelC0FastAppDecEq :
    (left right : PsKernelExpr) → Decidable (left = right)
  | .app fn arg, right =>
      withPtrEqDecEq (.app fn arg) right (fun _ =>
        match right with
        | .app otherFn otherArg =>
            letI : Decidable (fn = otherFn) :=
              psKernelC0FastAppDecEq fn otherFn
            if hfn : fn = otherFn then
              letI : Decidable (arg = otherArg) :=
                psKernelC0FastAppDecEq arg otherArg
              if harg : arg = otherArg then
                .isTrue (by cases hfn; cases harg; rfl)
              else
                .isFalse (by intro heq; cases heq; exact harg rfl)
            else
              .isFalse (by intro heq; cases heq; exact hfn rfl)
        | .bvar _ => .isFalse (by intro h; cases h)
        | .fvar _ => .isFalse (by intro h; cases h)
        | .mvar _ => .isFalse (by intro h; cases h)
        | .sort _ => .isFalse (by intro h; cases h)
        | .const _ _ => .isFalse (by intro h; cases h)
        | .lam _ _ _ _ => .isFalse (by intro h; cases h)
        | .forallE _ _ _ _ => .isFalse (by intro h; cases h)
        | .letE _ _ _ _ _ => .isFalse (by intro h; cases h)
        | .lit _ => .isFalse (by intro h; cases h)
        | .mdata _ _ => .isFalse (by intro h; cases h)
        | .proj _ _ _ => .isFalse (by intro h; cases h))
  | left, right =>
      withPtrEqDecEq left right (fun _ => inferInstance)

/-- Complete independent source semantics. Only a Decidable *proof*, never
its Boolean tag, is reused, so the result cannot be an unchecked false
equality even for pointer sharing or hash-bucket collisions. -/
theorem psKernelC0FastAppDecEq_source
    (left right : PsKernelExpr) :
    psKernelC0FastAppDecEq left right =
      (inferInstance : Decidable (left = right)) :=
  Subsingleton.allEq _ _
