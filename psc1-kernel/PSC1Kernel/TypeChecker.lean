import PSC1Kernel.Environment
import PSC1Kernel.LocalContext
import PSC1Kernel.Instantiate

namespace PSC1Kernel

structure CheckerContext where
  env : Environment
  lctx : LocalContext
  levelParams : List Name
  safety : DefinitionSafety

def CheckerContext.empty (env : Environment) : CheckerContext :=
  {
    env := env
    lctx := .empty
    levelParams := []
    safety := .safe
  }

def kernelNatName : Name :=
  .str .anonymous "Nat"

def kernelStringName : Name :=
  .str .anonymous "String"

def CheckerContext.freshName (ctx : CheckerContext) (base : Name) : Name :=
  .num base ctx.lctx.nextIndex

def CheckerContext.withLocal
    (ctx : CheckerContext)
    (userName : Name)
    (type : Expr)
    (binderInfo : BinderInfo) : Name × CheckerContext :=
  let fresh := ctx.freshName userName
  let lctx := ctx.lctx.addLocal fresh userName type binderInfo
  (fresh, { ctx with lctx := lctx })

def CheckerContext.withLet
    (ctx : CheckerContext)
    (userName : Name)
    (type value : Expr) : Name × CheckerContext :=
  let fresh := ctx.freshName userName
  let lctx := ctx.lctx.addLet fresh userName type value
  (fresh, { ctx with lctx := lctx })

partial def whnf (ctx : CheckerContext) (e : Expr) : Except String Expr :=
  match e with
  | .mdata _ body => whnf ctx body
  | .letE _ _ value body _ =>
    whnf ctx (body.instantiate1 value)
  | .fvar name =>
    match ctx.lctx.find? name with
    | some decl =>
      match decl.value? with
      | some value => whnf ctx value
      | none => .ok e
    | none => .ok e
  | .const name levels =>
    match ctx.env.find? name with
    | some info =>
      match info.deltaValue? with
      | some value =>
        if info.levelParams.length == levels.length then
          whnf ctx (value.instantiateLevelParams info.levelParams levels)
        else
          .ok e
      | none => .ok e
    | none => .ok e
  | .app fn arg => do
    let fn' ← whnf ctx fn
    match fn' with
    | .lam _ _ body _ => whnf ctx (body.instantiate1 arg)
    | .const name levels =>
      match ctx.env.find? name with
      | some info =>
        match info.deltaValue? with
        | some value =>
          if info.levelParams.length == levels.length then
            whnf ctx (.app (value.instantiateLevelParams info.levelParams levels) arg)
          else
            .ok (.app fn' arg)
        | none => .ok (.app fn' arg)
      | none => .ok (.app fn' arg)
    | _ =>
      if Expr.eq fn fn' then .ok e else .ok (.app fn' arg)
  | _ => .ok e

partial def isDefEq (ctx : CheckerContext) (a b : Expr) : Except String Bool := do
  if Expr.eq a b then return true
  let a' ← whnf ctx a
  let b' ← whnf ctx b
  if Expr.eq a' b' then return true
  match a', b' with
  | .sort u, .sort v => return Level.equivalent u v
  | .app f₁ a₁, .app f₂ a₂ => do
    let hf ← isDefEq ctx f₁ f₂
    if !hf then return false
    isDefEq ctx a₁ a₂
  | .forallE _ d₁ b₁ i₁, .forallE _ d₂ b₂ i₂ => do
    if !BinderInfo.eq i₁ i₂ then return false
    let hd ← isDefEq ctx d₁ d₂
    if !hd then return false
    isDefEq ctx b₁ b₂
  | .lam _ d₁ b₁ i₁, .lam _ d₂ b₂ i₂ => do
    if !BinderInfo.eq i₁ i₂ then return false
    let hd ← isDefEq ctx d₁ d₂
    if !hd then return false
    isDefEq ctx b₁ b₂
  | _, _ => return false

partial def ensureSort (ctx : CheckerContext) (e : Expr) : Except String Level := do
  let reduced ← whnf ctx e
  match reduced with
  | .sort level => .ok level
  | _ => .error "expected sort"

partial def ensureForall
    (ctx : CheckerContext) (e : Expr) :
    Except String (Name × Expr × Expr × BinderInfo) := do
  let reduced ← whnf ctx e
  match reduced with
  | .forallE name domain body binderInfo => .ok (name, domain, body, binderInfo)
  | _ => .error "expected function type"

partial def infer (ctx : CheckerContext) (e : Expr) : Except String Expr :=
  match e with
  | .bvar _ => .error "loose bound variable in type checker"
  | .mvar _ => .error "kernel type checker does not support metavariables"
  | .fvar name =>
    match ctx.lctx.find? name with
    | some decl => .ok decl.type
    | none => .error "unknown free variable"
  | .sort level => .ok (.sort (.succ level))
  | .const name levels =>
    match ctx.env.find? name with
    | none => .error "unknown constant"
    | some info =>
      if info.levelParams.length != levels.length then
        .error "incorrect number of universe levels"
      else if info.isUnsafe && ctx.safety != .unsafeDef then
        .error "safe declaration uses unsafe constant"
      else if info.isPartial && ctx.safety == .safe then
        .error "safe declaration uses partial constant"
      else
        .ok (info.type.instantiateLevelParams info.levelParams levels)
  | .lit literal =>
    match literal with
    | .nat _ => .ok (.const kernelNatName [])
    | .str _ => .ok (.const kernelStringName [])
  | .mdata _ body => infer ctx body
  | .app fn arg => do
    let fnType ← infer ctx fn
    let (_, domain, body, _) ← ensureForall ctx fnType
    let argType ← infer ctx arg
    let ok ← isDefEq ctx argType domain
    if !ok then
      .error "application type mismatch"
    else
      .ok (body.instantiate1 arg)
  | .lam name type body binderInfo => do
    let typeType ← infer ctx type
    let _ ← ensureSort ctx typeType
    let (fresh, child) := ctx.withLocal name type binderInfo
    let bodyType ← infer child (body.instantiate1 (.fvar fresh))
    .ok (.forallE name type (bodyType.abstractFVars [fresh]) binderInfo)
  | .forallE name type body binderInfo => do
    let typeType ← infer ctx type
    let u ← ensureSort ctx typeType
    let (fresh, child) := ctx.withLocal name type binderInfo
    let bodyType ← infer child (body.instantiate1 (.fvar fresh))
    let v ← ensureSort child bodyType
    .ok (.sort (Level.mkIMax u v))
  | .letE name type value body _ => do
    let typeType ← infer ctx type
    let _ ← ensureSort ctx typeType
    let valueType ← infer ctx value
    let ok ← isDefEq ctx valueType type
    if !ok then
      .error "let value type mismatch"
    else
      let (fresh, child) := ctx.withLet name type value
      let bodyType ← infer child (body.instantiate1 (.fvar fresh))
      .ok (bodyType.abstractFVars [fresh])
  | .proj _ _ _ => .error "projection inference not implemented in K2"

def check (ctx : CheckerContext) (e : Expr) : Except String Expr :=
  infer ctx e

end PSC1Kernel
