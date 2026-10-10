import Ps.KernelCore.Core.AnnotatedExpr

/-!
Annotation-preserving syntax operations for the checker's argument spines.
Substitution is simultaneous: replacements are lifted at the surrounding depth
and are not recursively rewritten by other entries. No typing or reduction
soundness is certified merely by calling these operations.
-/
namespace PsKernelSemantics.AnnotatedExpr

def instManyAt (e : AnnotatedExpr) (start : Nat)
    (subst : List AnnotatedExpr) (offset : Nat) : AnnotatedExpr :=
  match e with
  | .bvar i =>
      if psKernelNatLt i (start + offset) then .bvar i
      else match subst[i - (start + offset)]? with
        | some a => liftN offset a 0
        | none => .bvar (i - subst.length)
  | .app f a => .app (instManyAt f start subst offset) (instManyAt a start subst offset)
  | .lam n A b bi v =>
      .lam n (instManyAt A start subst offset)
        (instManyAt b start subst (offset + 1)) bi v
  | .forallE n A B bi v =>
      .forallE n (instManyAt A start subst offset)
        (instManyAt B start subst (offset + 1)) bi v
  | .letE n A a b nd =>
      .letE n (instManyAt A start subst offset) (instManyAt a start subst offset)
        (instManyAt b start subst (offset + 1)) nd
  | .mdata md b => .mdata md (instManyAt b start subst offset)
  | .proj n i b => .proj n i (instManyAt b start subst offset)
  | e => e

/-- Arguments are supplied from outermost to innermost binder, as in production. -/
def instantiateRev (e : AnnotatedExpr) (args : List AnnotatedExpr) : AnnotatedExpr :=
  instManyAt e 0 args.reverse 0

def applyArgs (fn : AnnotatedExpr) (args : List AnnotatedExpr) : AnnotatedExpr :=
  match args with
  | [] => fn
  | arg :: rest => applyArgs (.app fn arg) rest

/-- Syntax-only spine exposure. Dropping binders is not a beta-soundness theorem. -/
def consumeLambdas (fuel : Nat) (fn : AnnotatedExpr) (argc count : Nat) :
    AnnotatedExpr × Nat :=
  match fuel with
  | 0 => (fn, count)
  | fuel + 1 =>
      match fn with
      | .lam _ _ body _ _ =>
          if psKernelNatLt count argc then consumeLambdas fuel body argc (count + 1)
          else (fn, count)
      | _ => (fn, count)

end PsKernelSemantics.AnnotatedExpr
