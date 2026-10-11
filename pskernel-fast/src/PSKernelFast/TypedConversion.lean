import PSKernelFast.GeneralPiFormation

/-!
G4.4a: proof-carrying, INCOMPLETE typed head conversion.

Only exact reflexivity, one immediate beta contraction, and one
nondep=false let/zeta contraction are recognized. An Equal result contains
BOTH actual G4.3b type derivations of the SAME syntactic type, plus a
constructor of the reference head-contraction relation.

This is NOT full Lean 4.35 WHNF, typed DefEq, delta/iota, quotient,
proof irrelevance, eta, recursors, or set-model preservation. Distinct
valid cases are UNRESOLVED, never authoritative negative inequality.
Zero budget declines, and malformed input is checked before any reduction.
No declaration acceptance authority is implemented here.
-/

namespace PSKernelFast.Core

inductive HeadConversion : KExpr → KExpr → Type where
  | refl (e : KExpr) : HeadConversion e e
  | beta (name : KName) (domain body : KExpr)
      (style : BinderStyle) (arg : KExpr) :
      HeadConversion (.app (.lam name domain body style) arg)
        (body.instantiateBVar arg 0)
  | zeta (name : KName) (ty val body : KExpr) :
      HeadConversion (.letE name ty val body false)
        (body.instantiateBVar val 0)

/-- Construct actual operational evidence, never hash-only equivalence. -/
def checkHeadConversion (lhs rhs : KExpr) :
    Option (HeadConversion lhs rhs) :=
  if h : lhs = rhs then
    some (h ▸ HeadConversion.refl lhs)
  else
    match lhs with
    | .app (.lam name domain body style) arg =>
        if h : body.instantiateBVar arg 0 = rhs then
          some (h ▸ HeadConversion.beta name domain body style arg)
        else
          none
    | .letE name ty val body false =>
        if h : body.instantiateBVar val 0 = rhs then
          some (h ▸ HeadConversion.zeta name ty val body)
        else
          none
    | _ => none

/-- Source checker judgments for BOTH sides under the very same type. -/
structure TypedHeadCertificate (params : List KName) (ctx : List KExpr)
    (lhs rhs : KExpr) where
  ty : KExpr
  lhsTyped : GeneralPiRule params ctx lhs ty
  rhsTyped : GeneralPiRule params ctx rhs ty
  headStep : HeadConversion lhs rhs

/-- Unresolved never means that the terms are definitionally unequal. -/
inductive TypedHeadDecision (params : List KName) (ctx : List KExpr)
    (lhs rhs : KExpr) where
  | equal (cert : TypedHeadCertificate params ctx lhs rhs)
  | unresolved
  | malformed
  | resourceExhausted

def TypedHeadDecision.isEqual {params : List KName} {ctx : List KExpr}
    {lhs rhs : KExpr} :
    TypedHeadDecision params ctx lhs rhs → Bool
  | .equal _ => true
  | _ => false

/--
Explicitly bounded and TYPED one-head positive comparison.
No context/environment/scope evidence comes from unchecked frontend flags;
the context is the restricted actual G4.3b validated GeneralPiContext.
Unsupported conversions must not become negative DefEq assertions.
-/
def compareTypedHead {params : List KName}
    (ctx : GeneralPiContext params)
    (lhs rhs : KExpr) (budget : Nat) :
    TypedHeadDecision params ctx.entries lhs rhs :=
  if !lhs.validAt params ctx.entries.length ||
      !rhs.validAt params ctx.entries.length then
    .malformed
  else
    match budget with
    | 0 => .resourceExhausted
    | _ + 1 =>
        match ctx.infer lhs, ctx.infer rhs with
        | some lhsJudgment, some rhsJudgment =>
            if hSame : lhsJudgment.val = rhsJudgment.val then
              match checkHeadConversion lhs rhs with
              | some hStep =>
                  .equal {
                    ty := lhsJudgment.val
                    lhsTyped := lhsJudgment.property
                    rhsTyped := by
                      simpa only [hSame] using rhsJudgment.property
                    headStep := hStep
                  }
              | none => .unresolved
            else
              .unresolved
        | _, _ => .unresolved

end PSKernelFast.Core
