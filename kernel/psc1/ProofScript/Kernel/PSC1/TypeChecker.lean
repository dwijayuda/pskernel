import ProofScript.Kernel.PSC1.Environment

namespace ProofScript.Kernel.PSC1

namespace TypeChecker

abbrev Result (α : Type) := Except String α
abbrev LocalContext := List Expr

def natName : Name := .str .anonymous "Nat"
def stringName : Name := .str .anonymous "String"

def get? {α : Type} : List α → Nat → Option α
  | [], _ => none
  | x :: _, 0 => some x
  | _ :: xs, i + 1 => get? xs i

def levelListEquivalent : List Level → List Level → Bool
  | [], [] => true
  | a :: as, b :: bs =>
      Level.isEquivalent a b && levelListEquivalent as bs
  | _, _ => false

def shiftType (e : Expr) : Expr :=
  Expr.liftLooseBVars e 0 1

def pushBinder (ctx : LocalContext) (domain : Expr) : LocalContext :=
  shiftType domain :: ctx.map shiftType

def inferBVar (ctx : LocalContext) (i : Nat) : Result Expr :=
  match get? ctx i with
  | some type => .ok type
  | none => .error "unknown bound variable"

def instantiateConstType (info : ConstantInfo) (levels : List Level) : Result Expr :=
  if info.levelParams.length == levels.length then
    .ok (Expr.instantiateLevelParams info.type info.levelParams levels)
  else
    .error "incorrect number of universe level parameters"

def instantiateConstValue (env : Environment) (name : Name) (levels : List Level) : Option Expr :=
  match env.find? name with
  | some info =>
      if info.levelParams.length == levels.length then
        match info.kind, info.value with
        | .definition, some value =>
            some (Expr.instantiateLevelParams value info.levelParams levels)
        | _, _ => none
      else
        none
  | none => none

partial def whnf (env : Environment) (e : Expr) : Result Expr :=
  match e with
  | .letE _ _ value body _ =>
      whnf env (Expr.instantiate1 body value)
  | .app fn arg =>
      match whnf env fn with
      | .error err => .error err
      | .ok fn' =>
          match fn' with
          | .lam _ _ body _ =>
              whnf env (Expr.instantiate1 body arg)
          | .const name levels =>
              match instantiateConstValue env name levels with
              | some value => whnf env (.app value arg)
              | none => .ok (.app fn' arg)
          | _ => .ok (.app fn' arg)
  | .const name levels =>
      match instantiateConstValue env name levels with
      | some value => whnf env value
      | none => .ok e
  | _ => .ok e

partial def isDefEq (env : Environment) (a b : Expr) : Result Bool := do
  if Expr.eqv a b then
    return true
  let a' ← whnf env a
  let b' ← whnf env b
  if Expr.eqv a' b' then
    return true
  match a', b' with
  | .sort u, .sort v =>
      return Level.isEquivalent u v
  | .const an aus, .const bn bus =>
      return Name.beq an bn && levelListEquivalent aus bus
  | .app af aa, .app bf ba =>
      if !(← isDefEq env af bf) then
        return false
      isDefEq env aa ba
  | .lam _ atype abody _, .lam _ btype bbody _ =>
      if !(← isDefEq env atype btype) then
        return false
      isDefEq env abody bbody
  | .forallE _ atype abody _, .forallE _ btype bbody _ =>
      if !(← isDefEq env atype btype) then
        return false
      isDefEq env abody bbody
  | .lit alit, .lit blit =>
      return Expr.literalBeq alit blit
  | .proj an ai ae, .proj bn bi be =>
      if !(Name.beq an bn && ai == bi) then
        return false
      isDefEq env ae be
  | _, _ => return false

partial def ensureSort (env : Environment) (ctx : LocalContext) (e : Expr) : Result Level := do
  let type ← infer env ctx e
  let type' ← whnf env type
  match type' with
  | .sort u => return u
  | _ => throw "type expected"

partial def ensurePiType (env : Environment) (type : Expr) : Result (Name × Expr × Expr × BinderInfo) := do
  let type' ← whnf env type
  match type' with
  | .forallE n domain body bi => return (n, domain, body, bi)
  | _ => throw "function expected"

partial def infer (env : Environment) (ctx : LocalContext) (e : Expr) : Result Expr := do
  match e with
  | .bvar i =>
      inferBVar ctx i
  | .fvar _ =>
      throw "portable closed-term checker does not accept free variables"
  | .mvar _ =>
      throw "kernel type checker does not support metavariables"
  | .sort u =>
      return .sort (.succ u)
  | .const name levels =>
      match env.find? name with
      | none => throw "unknown constant"
      | some info => instantiateConstType info levels
  | .app fn arg =>
      let fnType ← infer env ctx fn
      let (_, domain, body, _) ← ensurePiType env fnType
      let argType ← infer env ctx arg
      unless (← isDefEq env argType domain) do
        throw "application type mismatch"
      return Expr.instantiate1 body arg
  | .lam name domain body bi =>
      let _ ← ensureSort env ctx domain
      let bodyType ← infer env (pushBinder ctx domain) body
      return .forallE name domain bodyType bi
  | .forallE _ domain body _ =>
      let u ← ensureSort env ctx domain
      let v ← ensureSort env (pushBinder ctx domain) body
      return .sort (Level.mkIMax u v)
  | .letE _ type value body _ =>
      let _ ← ensureSort env ctx type
      let valueType ← infer env ctx value
      unless (← isDefEq env valueType type) do
        throw "let value type mismatch"
      infer env ctx (Expr.instantiate1 body value)
  | .lit (.natVal _) =>
      return .const natName []
  | .lit (.strVal _) =>
      return .const stringName []
  | .proj _ _ _ =>
      throw "projection inference requires the inductive kernel milestone"

def check (env : Environment) (e : Expr) : Result Expr :=
  if Expr.hasLooseBVars e then
    .error "top-level kernel check requires a closed expression"
  else
    infer env [] e

end TypeChecker

end ProofScript.Kernel.PSC1
