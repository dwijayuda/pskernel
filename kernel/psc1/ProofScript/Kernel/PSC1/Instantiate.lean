import ProofScript.Kernel.PSC1.Expr

namespace ProofScript.Kernel.PSC1
namespace Expr

def listGet? {α : Type} : List α → Nat → Option α
  | [], _ => none
  | x :: _, 0 => some x
  | _ :: xs, i + 1 => listGet? xs i

def listLength {α : Type} : List α → Nat
  | [] => 0
  | _ :: xs => listLength xs + 1

/--
Lean 4.34 instantiate semantics with an explicit binder depth.
The substitution list uses de Bruijn indexing, matching
`Lean.Expr.instantiate`.
-/
def instantiateAt : Expr → List Expr → Nat → Expr
  | .bvar i, subst, depth =>
      if i < depth then
        .bvar i
      else
        let j := i - depth
        match listGet? subst j with
        | some value => liftLooseBVars value 0 depth
        | none => .bvar (i - listLength subst)
  | .fvar n, _, _ => .fvar n
  | .mvar n, _, _ => .mvar n
  | .sort u, _, _ => .sort u
  | .const n us, _, _ => .const n us
  | .app f a, subst, depth =>
      .app
        (instantiateAt f subst depth)
        (instantiateAt a subst depth)
  | .lam n type body bi, subst, depth =>
      .lam n
        (instantiateAt type subst depth)
        (instantiateAt body subst (depth + 1))
        bi
  | .forallE n type body bi, subst, depth =>
      .forallE n
        (instantiateAt type subst depth)
        (instantiateAt body subst (depth + 1))
        bi
  | .letE n type value body nondep, subst, depth =>
      .letE n
        (instantiateAt type subst depth)
        (instantiateAt value subst depth)
        (instantiateAt body subst (depth + 1))
        nondep
  | .lit l, _, _ => .lit l
  | .proj n i e, subst, depth =>
      .proj n i (instantiateAt e subst depth)

def instantiate (e : Expr) (subst : List Expr) : Expr :=
  instantiateAt e subst 0

def instantiate1 (e value : Expr) : Expr :=
  instantiate e [value]

def instantiateRev (e : Expr) (subst : List Expr) : Expr :=
  instantiate e subst.reverse

/--
Single-free-variable abstraction, matching the n=1 case of Lean 4.34
`abstract.cpp`. Existing bound variables are preserved; only the matching
free variable is replaced using the current binder offset.
-/
def abstractFVarAt : Expr → Name → Nat → Expr
  | .bvar i, _, _ => .bvar i
  | .fvar n, target, depth =>
      if Name.beq n target then .bvar depth else .fvar n
  | .mvar n, _, _ => .mvar n
  | .sort u, _, _ => .sort u
  | .const n us, _, _ => .const n us
  | .app f a, target, depth =>
      .app
        (abstractFVarAt f target depth)
        (abstractFVarAt a target depth)
  | .lam n type body bi, target, depth =>
      .lam n
        (abstractFVarAt type target depth)
        (abstractFVarAt body target (depth + 1))
        bi
  | .forallE n type body bi, target, depth =>
      .forallE n
        (abstractFVarAt type target depth)
        (abstractFVarAt body target (depth + 1))
        bi
  | .letE n type value body nondep, target, depth =>
      .letE n
        (abstractFVarAt type target depth)
        (abstractFVarAt value target depth)
        (abstractFVarAt body target (depth + 1))
        nondep
  | .lit l, _, _ => .lit l
  | .proj n i e, target, depth =>
      .proj n i (abstractFVarAt e target depth)

def abstractFVar (e : Expr) (target : Name) : Expr :=
  abstractFVarAt e target 0

end Expr
end ProofScript.Kernel.PSC1
