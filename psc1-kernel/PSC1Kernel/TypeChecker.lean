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

def kernelBoolName : Name :=
  .str .anonymous "Bool"

def kernelBoolTrueName : Name :=
  .str kernelBoolName "true"

def kernelBoolFalseName : Name :=
  .str kernelBoolName "false"

def kernelNatZeroName : Name :=
  .str kernelNatName "zero"

def kernelNatSuccName : Name :=
  .str kernelNatName "succ"

def kernelNatAddName : Name :=
  .str kernelNatName "add"

def kernelNatSubName : Name :=
  .str kernelNatName "sub"

def kernelNatMulName : Name :=
  .str kernelNatName "mul"

def kernelNatPowName : Name :=
  .str kernelNatName "pow"

def kernelNatGcdName : Name :=
  .str kernelNatName "gcd"

def kernelNatModName : Name :=
  .str kernelNatName "mod"

def kernelNatDivName : Name :=
  .str kernelNatName "div"

def kernelNatBeqName : Name :=
  .str kernelNatName "beq"

def kernelNatBleName : Name :=
  .str kernelNatName "ble"

def natLiteralValue? : Expr → Option Nat
  | .lit (.nat value) => some value
  | .const name levels =>
    if levels.length == 0 && Name.eq name kernelNatZeroName then some 0 else none
  | _ => none

partial def kernelNatGcd (a b : Nat) : Nat :=
  if b == 0 then a else kernelNatGcd b (a % b)

def boolExpr (value : Bool) : Expr :=
  .const (if value then kernelBoolTrueName else kernelBoolFalseName) []

def reduceNatBinary (op : Name) (a b : Nat) : Option Expr :=
  if Name.eq op kernelNatAddName then
    some (.lit (.nat (a + b)))
  else if Name.eq op kernelNatSubName then
    some (.lit (.nat (a - b)))
  else if Name.eq op kernelNatMulName then
    some (.lit (.nat (a * b)))
  else if Name.eq op kernelNatPowName then
    if b > 16777216 then none else some (.lit (.nat (a ^ b)))
  else if Name.eq op kernelNatGcdName then
    some (.lit (.nat (kernelNatGcd a b)))
  else if Name.eq op kernelNatModName then
    some (.lit (.nat (if b == 0 then a else a % b)))
  else if Name.eq op kernelNatDivName then
    some (.lit (.nat (if b == 0 then 0 else a / b)))
  else if Name.eq op kernelNatBeqName then
    some (boolExpr (a == b))
  else if Name.eq op kernelNatBleName then
    some (boolExpr (a <= b))
  else
    none

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

def reduceProjCore
    (ctx : CheckerContext)
    (typeName : Name)
    (idx : Nat)
    (struct : Expr) : Option Expr :=
  let fn := struct.getAppFn
  let args := struct.getAppArgs
  match fn with
  | .const ctorName _ =>
    match ctx.env.find? ctorName with
    | some (.ctorInfo ctor) =>
      if !Name.eq ctor.induct typeName then
        none
      else
        listGet? args (ctor.numParams + idx)
    | _ => none
  | _ => none


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
  | .proj typeName idx struct => do
    let struct' ← whnf ctx struct
    match reduceProjCore ctx typeName idx struct' with
    | some value => whnf ctx value
    | none => .ok e
  | .app fn arg => do
    let natReduced ←
      match fn with
      | .const name levels =>
        if levels.length == 0 && Name.eq name kernelNatSuccName then
          let arg' ← whnf ctx arg
          match natLiteralValue? arg' with
          | some value => .ok (some (.lit (.nat (value + 1))))
          | none => .ok none
        else
          .ok none
      | .app (.const name levels) left =>
        if levels.length == 0 then
          let left' ← whnf ctx left
          let right' ← whnf ctx arg
          match natLiteralValue? left', natLiteralValue? right' with
          | some a, some b => .ok (reduceNatBinary name a b)
          | _, _ => .ok none
        else
          .ok none
      | _ => .ok none
    match natReduced with
    | some value => .ok value
    | none =>
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
  | .forallE _ d₁ b₁ _, .forallE _ d₂ b₂ _ => do
    let hd ← isDefEq ctx d₁ d₂
    if !hd then return false
    isDefEq ctx b₁ b₂
  | .lam _ d₁ b₁ _, .lam _ d₂ b₂ _ => do
    let hd ← isDefEq ctx d₁ d₂
    if !hd then return false
    isDefEq ctx b₁ b₂
  | .proj n₁ i₁ e₁, .proj n₂ i₂ e₂ => do
    if !Name.eq n₁ n₂ || i₁ != i₂ then return false
    isDefEq ctx e₁ e₂
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


mutual

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
      else if info.isUnsafe && !ctx.safety.isUnsafe then
        .error "safe declaration uses unsafe constant"
      else if info.isPartial && ctx.safety.isSafe then
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
  | .proj typeName idx struct => inferProj ctx typeName idx struct

partial def getSortLevel (ctx : CheckerContext) (e : Expr) : Except String Level := do
  let type ← infer ctx e
  ensureSort ctx type

partial def isProp (ctx : CheckerContext) (e : Expr) : Except String Bool := do
  let level ← getSortLevel ctx e
  .ok (Level.normalizesToZero level)

partial def inferProj
    (ctx : CheckerContext)
    (typeName : Name)
    (idx : Nat)
    (struct : Expr) : Except String Expr := do
  let type ← whnf ctx (← infer ctx struct)
  let fn := type.getAppFn
  let args := type.getAppArgs
  let (.const inductName inductLevels) := fn
    | .error "invalid projection: projected expression type is not an inductive application"
  if !Name.eq inductName typeName then
    .error "invalid projection: structure type mismatch"
  else
    let some (.inductInfo induct) := ctx.env.find? inductName
      | .error "invalid projection: structure name is not inductive"
    match induct.ctors with
    | [ctorName] =>
      if args.length != induct.numParams + induct.numIndices then
        .error "invalid projection: inductive type is not fully applied"
      else
        let some (.ctorInfo ctor) := ctx.env.find? ctorName
          | .error "invalid projection: constructor metadata missing"
        let r0 := ctor.base.type.instantiateLevelParams ctor.base.levelParams inductLevels
        let rec applyParams (i : Nat) (r : Expr) : Except String Expr := do
          if i < induct.numParams then
            let r' ← whnf ctx r
            let .forallE _ _ body _ := r'
              | .error "invalid projection: constructor parameter is not a forall"
            let some arg := listGet? args i
              | .error "invalid projection: missing structure parameter"
            applyParams (i + 1) (body.instantiate1 arg)
          else
            .ok r
        let r1 ← applyParams 0 r0
        let propType ← isProp ctx type
        let rec skipFields (i : Nat) (r : Expr) : Except String Expr := do
          if i < idx then
            let r' ← whnf ctx r
            let .forallE _ domain body _ := r'
              | .error "invalid projection index"
            if body.hasLooseBVar then
              if propType then
                let domainProp ← isProp ctx domain
                if !domainProp then
                  .error "invalid projection: proof structure depends on data field"
                else
                  skipFields (i + 1) (body.instantiate1 (.proj inductName i struct))
              else
                skipFields (i + 1) (body.instantiate1 (.proj inductName i struct))
            else
              skipFields (i + 1) body
          else
            .ok r
        let r2 ← skipFields 0 r1
        let r3 ← whnf ctx r2
        let .forallE _ domain _ _ := r3
          | .error "invalid projection index"
        if propType then
          let domainProp ← isProp ctx domain
          if !domainProp then
            .error "invalid projection: proof structure field is not a proposition"
          else
            .ok domain
        else
          .ok domain
    | _ => .error "invalid projection: inductive must have exactly one constructor"

end

def check (ctx : CheckerContext) (e : Expr) : Except String Expr :=
  infer ctx e

end PSC1Kernel
