import Init.Data.Nat.Bitwise.Basic
import Init.Data.String.Basic
import PSC1Kernel.Environment
import PSC1Kernel.LocalContext
import PSC1Kernel.Instantiate

namespace PSC1Kernel

structure CheckerContext where
  env : Environment
  lctx : LocalContext
  levelParams : List Name
  safety : DefinitionSafety
  eagerReduce : Bool

def CheckerContext.empty (env : Environment) : CheckerContext :=
  {
    env := env
    lctx := .empty
    levelParams := []
    safety := .safe
    eagerReduce := false
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

def kernelEagerReduceName : Name :=
  .str .anonymous "eagerReduce"

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

def kernelNatLandName : Name :=
  .str kernelNatName "land"

def kernelNatLorName : Name :=
  .str kernelNatName "lor"

def kernelNatXorName : Name :=
  .str kernelNatName "xor"

def kernelNatShiftLeftName : Name :=
  .str kernelNatName "shiftLeft"

def kernelNatShiftRightName : Name :=
  .str kernelNatName "shiftRight"

def kernelCharName : Name :=
  .str .anonymous "Char"

def kernelListName : Name :=
  .str .anonymous "List"

def kernelListNilName : Name :=
  .str kernelListName "nil"

def kernelListConsName : Name :=
  .str kernelListName "cons"

def kernelStringOfListName : Name :=
  .str kernelStringName "ofList"

def kernelCharOfNatName : Name :=
  .str kernelCharName "ofNat"

def isEagerReduceExpr (e : Expr) : Bool :=
  match e.getAppFn with
  | .const name _ =>
      Name.eq name kernelEagerReduceName && e.getAppNumArgs == 2
  | _ => false

def natLiteralValue? : Expr → Option Nat
  | .lit (.nat value) => some value
  | .const name levels =>
    if levels.length == 0 && Name.eq name kernelNatZeroName then some 0 else none
  | _ => none

partial def kernelNatGcd (a b : Nat) : Nat :=
  if b == 0 then a else kernelNatGcd b (a % b)

/-- Final Lean 4.34 default from `type_checker.cpp`: 128 MiB. -/
def leanNatMaxSizeDefault : Nat :=
  128 * 1024 * 1024

/-- Final Lean 4.34 runtime count boundary for Nat.pow/Nat.shiftLeft. -/
def leanUInt32Max : Nat :=
  4294967295

/-- Largest Nat encoded as an immediate scalar by the 64-bit Lean runtime. -/
def leanMaxSmallNat : Nat :=
  9223372036854775807

/--
Portable model of Lean 4.34 `lean_nat_size_in_bytes` on the supported
64-bit runtime: one word for scalars, whole 64-bit limbs for heap naturals.
-/
partial def natHeapWordCount (n : Nat) : Nat :=
  if n == 0 then
    0
  else
    1 + natHeapWordCount (Nat.shiftRight n 64)

def natSizeInBytes (n : Nat) : Nat :=
  if n <= leanMaxSmallNat then 8 else natHeapWordCount n * 8

def checkNatSize (n : Nat) : Except String Unit :=
  if natSizeInBytes n > leanNatMaxSizeDefault then
    .error "the kernel refused a Nat numeral because its size exceeds the maximum"
  else
    .ok ()

def checkCountArg (op : String) (count : Nat) : Except String Unit :=
  if count > leanUInt32Max then
    .error ("the kernel refused to evaluate " ++ op ++
      " because its second argument does not fit in a 32-bit unsigned integer")
  else
    .ok ()

def boolExpr (value : Bool) : Expr :=
  .const (if value then kernelBoolTrueName else kernelBoolFalseName) []

/--
Final Lean 4.34 string-literal expansion used by recursor/projection reduction
and the special string-literal definitional-equality case.
-/
def stringLitToConstructor (value : String) : Expr :=
  let charType : Expr := .const kernelCharName []
  let listNil : Expr :=
    .app (.const kernelListNilName [.zero]) charType
  let listCons : Expr :=
    .app (.const kernelListConsName [.zero]) charType
  let charOfNat : Expr := .const kernelCharOfNatName []
  let chars : List Char := value.toList
  let data :=
    chars.foldr
      (fun c rest =>
        .app
          (.app listCons (.app charOfNat (.lit (.nat c.toNat))))
          rest)
      listNil
  .app (.const kernelStringOfListName []) data

def isStringOfListApp : Expr → Bool
  | .app (.const name levels) _ =>
      levels.length == 0 && Name.eq name kernelStringOfListName
  | _ => false

def reduceNatBinary (op : Name) (a b : Nat) : Except String (Option Expr) := do
  if Name.eq op kernelNatAddName then
    let r := a + b
    checkNatSize r
    return some (.lit (.nat r))
  else if Name.eq op kernelNatSubName then
    let r := a - b
    checkNatSize r
    return some (.lit (.nat r))
  else if Name.eq op kernelNatMulName then
    let r := a * b
    checkNatSize r
    return some (.lit (.nat r))
  else if Name.eq op kernelNatPowName then
    checkCountArg "Nat.pow" b
    if a > 1 && b != 0 && natSizeInBytes a > leanNatMaxSizeDefault / b then
      throw "the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size"
    else
      return some (.lit (.nat (a ^ b)))
  else if Name.eq op kernelNatGcdName then
    return some (.lit (.nat (kernelNatGcd a b)))
  else if Name.eq op kernelNatModName then
    return some (.lit (.nat (if b == 0 then a else a % b)))
  else if Name.eq op kernelNatDivName then
    return some (.lit (.nat (if b == 0 then 0 else a / b)))
  else if Name.eq op kernelNatBeqName then
    return some (boolExpr (a == b))
  else if Name.eq op kernelNatBleName then
    return some (boolExpr (a <= b))
  else if Name.eq op kernelNatLandName then
    return some (.lit (.nat (Nat.land a b)))
  else if Name.eq op kernelNatLorName then
    return some (.lit (.nat (Nat.lor a b)))
  else if Name.eq op kernelNatXorName then
    return some (.lit (.nat (Nat.xor a b)))
  else if Name.eq op kernelNatShiftLeftName then
    if a == 0 then
      return some (.lit (.nat 0))
    checkCountArg "Nat.shiftLeft" b
    if natSizeInBytes a + b / 8 + 1 > leanNatMaxSizeDefault then
      throw "the kernel refused a Nat numeral because its size exceeds the maximum"
    return some (.lit (.nat (Nat.shiftLeft a b)))
  else if Name.eq op kernelNatShiftRightName then
    return some (.lit (.nat (Nat.shiftRight a b)))
  else
    return none

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
  if idx > leanUInt32Max then
    none
  else
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


def applyArgs (fn : Expr) (args : List Expr) : Expr :=
  args.foldl (fun acc arg => .app acc arg) fn

def unfoldDefinition (ctx : CheckerContext) (e : Expr) : Option Expr :=
  let fn := e.getAppFn
  let args := e.getAppArgs
  match fn with
  | .const name levels =>
    match ctx.env.find? name with
    | some info =>
      match info.deltaValue? with
      | some value =>
        if info.levelParams.length == levels.length then
          some (applyArgs
            (value.instantiateLevelParams info.levelParams levels)
            args)
        else
          none
      | none => none
    | none => none
  | _ => none

def kernelQuotName : Name := .str .anonymous "Quot"
def kernelQuotMkName : Name := .str kernelQuotName "mk"
def kernelQuotLiftName : Name := .str kernelQuotName "lift"
def kernelQuotIndName : Name := .str kernelQuotName "ind"

mutual

partial def reduceQuotRec
    (ctx : CheckerContext)
    (e : Expr) : Except String (Option Expr) := do
  if !ctx.env.quotInitialized then
    return none
  let .const fnName _ := e.getAppFn | return none
  let isLift := Name.eq fnName kernelQuotLiftName
  let isInd := Name.eq fnName kernelQuotIndName
  if !isLift && !isInd then
    return none
  let mkPos : Nat := if isLift then 5 else 4
  let argPos : Nat := 3
  let args := e.getAppArgs
  if args.length <= mkPos then
    return none
  let some major := listGet? args mkPos | return none
  let major' ← whnf ctx major
  let .const mkName _ := major'.getAppFn | return none
  if !Name.eq mkName kernelQuotMkName || major'.getAppNumArgs != 3 then
    return none
  let mkArgs := major'.getAppArgs
  let some representative := listGet? mkArgs 2 | return none
  let some f := listGet? args argPos | return none
  let base := Expr.app f representative
  let elimArity := mkPos + 1
  return some (applyArgs base (args.drop elimArity))

partial def findRecursorRule (ctorName : Name) : List RecursorRule → Option RecursorRule
  | [] => none
  | rule :: rest =>
      if Name.eq rule.ctor ctorName then some rule
      else findRecursorRule ctorName rest

partial def reduceInductiveRec
    (ctx : CheckerContext)
    (e : Expr)
    (cheapRec : Bool) : Except String (Option Expr) := do
  let .const recName recLevels := e.getAppFn | return none
  let some (.recInfo recursor) := ctx.env.find? recName | return none
  let recArgs := e.getAppArgs
  let majorIdx :=
    recursor.numParams + recursor.numMotives +
      recursor.numMinors + recursor.numIndices
  if majorIdx >= recArgs.length then
    return none
  let some major0 := listGet? recArgs majorIdx | return none
  let majorReduced ←
    if cheapRec then whnfCore ctx major0 true
    else whnf ctx major0
  let major ←
    match majorReduced with
    | .lit (.nat 0) =>
        .ok (Expr.const kernelNatZeroName [])
    | .lit (.nat (n + 1)) =>
        .ok (Expr.app (Expr.const kernelNatSuccName []) (.lit (.nat n)))
    | .lit (.str value) =>
        whnf ctx (stringLitToConstructor value)
    | _ => .ok majorReduced
  let .const ctorName _ := major.getAppFn | return none
  let some rule := findRecursorRule ctorName recursor.rules | return none
  let majorArgs := major.getAppArgs
  if rule.nFields > majorArgs.length then
    return none
  if recLevels.length != recursor.base.levelParams.length then
    return none
  let rhs0 :=
    rule.rhs.instantiateLevelParams recursor.base.levelParams recLevels
  let fixedCount :=
    recursor.numParams + recursor.numMotives + recursor.numMinors
  let rhs1 := applyArgs rhs0 (recArgs.take fixedCount)
  let ctorParamCount := majorArgs.length - rule.nFields
  let rhs2 :=
    applyArgs rhs1 ((majorArgs.drop ctorParamCount).take rule.nFields)
  return some (applyArgs rhs2 (recArgs.drop (majorIdx + 1)))

partial def reduceRecursor
    (ctx : CheckerContext)
    (e : Expr)
    (cheapRec : Bool) : Except String (Option Expr) := do
  let quot ← reduceQuotRec ctx e
  match quot with
  | some value => return some value
  | none => reduceInductiveRec ctx e cheapRec

partial def whnfCore
    (ctx : CheckerContext)
    (e : Expr)
    (cheapProj : Bool) : Except String Expr :=
  match e with
  | .bvar _ | .sort _ | .mvar _ | .forallE _ _ _ _
  | .const _ _ | .lam _ _ _ _ | .lit _ => .ok e
  | .mdata _ body => whnfCore ctx body cheapProj
  | .fvar name =>
    match ctx.lctx.find? name with
    | some decl =>
      match decl.value? with
      | some value => whnfCore ctx value cheapProj
      | none => .ok e
    | none => .ok e
  | .letE _ _ value body _ =>
    whnfCore ctx (body.instantiate1 value) cheapProj
  | .proj typeName idx struct => do
    let struct' ←
      if cheapProj then whnfCore ctx struct true
      else whnf ctx struct
    let struct'' ←
      match struct' with
      | .lit (.str value) => whnf ctx (stringLitToConstructor value)
      | _ => .ok struct'
    match reduceProjCore ctx typeName idx struct'' with
    | some value => whnfCore ctx value cheapProj
    | none => .ok e
  | .app fn arg => do
    let fn' ← whnfCore ctx fn cheapProj
    match fn' with
    | .lam _ _ body _ =>
      whnfCore ctx (body.instantiate1 arg) cheapProj
    | _ =>
      if Expr.eq fn fn' then
        let reduced ← reduceRecursor ctx e cheapProj
        match reduced with
        | some value => whnfCore ctx value cheapProj
        | none => .ok e
      else
        whnfCore ctx (.app fn' arg) cheapProj

partial def reduceNat
    (ctx : CheckerContext)
    (e : Expr) : Except String (Option Expr) :=
  match e with
  | .app (.const name levels) arg =>
    if levels.length == 0 && Name.eq name kernelNatSuccName then do
      let arg' ← whnf ctx arg
      match natLiteralValue? arg' with
      | some value => do
          let result := value + 1
          checkNatSize result
          .ok (some (.lit (.nat result)))
      | none => .ok none
    else
      .ok none
  | .app (.app (.const name levels) left) right =>
    if levels.length == 0 then do
      let left' ← whnf ctx left
      let right' ← whnf ctx right
      match natLiteralValue? left', natLiteralValue? right' with
      | some a, some b => reduceNatBinary name a b
      | _, _ => .ok none
    else
      .ok none
  | _ => .ok none

partial def whnf (ctx : CheckerContext) (e : Expr) : Except String Expr := do
  match e with
  | .bvar _ | .sort _ | .mvar _ | .forallE _ _ _ _ | .lit _ => return e
  | .mdata _ body => return ← whnf ctx body
  | .fvar name =>
    match ctx.lctx.find? name with
    | some decl =>
      if decl.value?.isNone then return e
    | none => return e
  | .lam _ _ _ _ | .app _ _ | .const _ _ | .letE _ _ _ _ _ | .proj _ _ _ =>
    pure ()
  let rec loop (t : Expr) : Except String Expr := do
    let core ← whnfCore ctx t false
    let nat ← reduceNat ctx core
    match nat with
    | some value => .ok value
    | none =>
      match unfoldDefinition ctx core with
      | some value => loop value
      | none => .ok core
  loop e

end

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


def levelListsEquivalent : List Level → List Level → Bool
  | [], [] => true
  | a :: as, b :: bs =>
    Level.equivalent a b && levelListsEquivalent as bs
  | _, _ => false

inductive DeltaResult where
  | decided (value : Bool)
  | residual (left : Expr) (right : Expr)

def deltaDefinition? (ctx : CheckerContext) (e : Expr) : Option DefinitionInfo :=
  match e.getAppFn with
  | .const name levels =>
    match ctx.env.find? name with
    | some (.defnInfo info) =>
      if info.base.levelParams.length == levels.length then some info else none
    | _ => none
  | _ => none

def quickReducedDefEq (a b : Expr) : Option Bool :=
  if Expr.eq a b then
    some true
  else
    match a, b with
    | .sort u, .sort v => some (Level.equivalent u v)
    | .lit x, .lit y => some (Literal.eq x y)
    | _, _ => none

partial def deltaOnce
    (ctx : CheckerContext)
    (e : Expr) : Except String Expr := do
  let some unfolded := unfoldDefinition ctx e
    | .error "internal lazy-delta request for non-definition"
  whnfCore ctx unfolded true


mutual

partial def lazyDeltaReduction
    (ctx : CheckerContext)
    (left right : Expr) : Except String DeltaResult := do
  let rec loop (a b : Expr) : Except String DeltaResult := do
    match quickReducedDefEq a b with
    | some value => return .decided value
    | none => pure ()

    if (!a.hasFVar && !b.hasFVar) || ctx.eagerReduce then
      let ar ← reduceNat ctx a
      match ar with
      | some value => return .decided (← isDefEq ctx value b)
      | none => pure ()
      let br ← reduceNat ctx b
      match br with
      | some value => return .decided (← isDefEq ctx a value)
      | none => pure ()

    match deltaDefinition? ctx a, deltaDefinition? ctx b with
    | none, none => return .residual a b
    | some _, none =>
      loop (← deltaOnce ctx a) b
    | none, some _ =>
      loop a (← deltaOnce ctx b)
    | some da, some db =>
      if da.hints.lt db.hints then
        loop (← deltaOnce ctx a) b
      else if db.hints.lt da.hints then
        loop a (← deltaOnce ctx b)
      else
        loop (← deltaOnce ctx a) (← deltaOnce ctx b)
  loop left right


partial def lazyDeltaProjReduction
    (ctx : CheckerContext)
    (left right : Expr)
    (typeName : Name)
    (index : Nat) : Except String Bool := do
  let delta ← lazyDeltaReduction ctx left right
  match delta with
  | .decided value => return value
  | .residual left' right' =>
      match reduceProjCore ctx typeName index left',
            reduceProjCore ctx typeName index right' with
      | some lfield, some rfield => isDefEq ctx lfield rfield
      | _, _ => isDefEq ctx left' right'

partial def isDefEq (ctx : CheckerContext) (a b : Expr) : Except String Bool := do
  if Expr.eq a b then return true

  -- Final Lean 4.34 reflection fast path. eagerReduce deliberately extends
  -- this path to expressions containing free variables.
  if !a.hasFVar || ctx.eagerReduce then
    match b with
    | .const name levels =>
        if levels.length == 0 && Name.eq name kernelBoolTrueName then
          let reduced ← whnf ctx a
          match reduced with
          | .const reducedName reducedLevels =>
              if reducedLevels.length == 0 &&
                  Name.eq reducedName kernelBoolTrueName then
                return true
          | _ => pure ()
    | _ => pure ()

  let aCore ← whnfCore ctx a true
  let bCore ← whnfCore ctx b true
  match quickReducedDefEq aCore bCore with
  | some value => return value
  | none => pure ()

  -- Final Lean 4.34 applies proof irrelevance before lazy delta.
  let aType ← infer ctx aCore
  let aIsProof ← isProp ctx aType
  if aIsProof then
    let bType ← infer ctx bCore
    return ← isDefEq ctx aType bType

  let delta ← lazyDeltaReduction ctx aCore bCore
  let (aDelta, bDelta) ←
    match delta with
    | .decided value => return value
    | .residual left right => pure (left, right)

  match aDelta, bDelta with
  | .const n₁ ls₁, .const n₂ ls₂ =>
    if Name.eq n₁ n₂ && levelListsEquivalent ls₁ ls₂ then return true
  | .fvar n₁, .fvar n₂ =>
    if Name.eq n₁ n₂ then return true
  | .proj n₁ i₁ e₁, .proj n₂ i₂ e₂ =>
    if Name.eq n₁ n₂ && i₁ == i₂ then
      if ← lazyDeltaProjReduction ctx e₁ e₂ n₁ i₁ then return true
  | _, _ => pure ()

  -- Cheap projection normalization has now had its chance. Retry core WHNF
  -- with full projection reduction, as final Lean 4.34 does.
  let aFull ← whnfCore ctx aDelta false
  let bFull ← whnfCore ctx bDelta false
  if !Expr.eq aFull aDelta || !Expr.eq bFull bDelta then
    return ← isDefEq ctx aFull bFull

  match aFull, bFull with
  | .sort u, .sort v => return Level.equivalent u v
  | .lit x, .lit y => return Literal.eq x y
  | .app f₁ a₁, .app f₂ a₂ => do
    let hf ← isDefEq ctx f₁ f₂
    if hf then
      if ← isDefEq ctx a₁ a₂ then return true
  | .forallE _ d₁ body₁ _, .forallE _ d₂ body₂ _ => do
    if ← isDefEq ctx d₁ d₂ then
      if ← isDefEq ctx body₁ body₂ then return true
  | .lam _ d₁ body₁ _, .lam _ d₂ body₂ _ => do
    if ← isDefEq ctx d₁ d₂ then
      if ← isDefEq ctx body₁ body₂ then return true
  | .lam _ _ _ _, other => do
    let otherType ← whnf ctx (← infer ctx other)
    match otherType with
    | .forallE name domain _ binderInfo =>
      if ← isDefEq ctx aFull (.lam name domain (.app other (.bvar 0)) binderInfo) then
        return true
    | _ => pure ()
  | other, .lam _ _ _ _ => do
    let otherType ← whnf ctx (← infer ctx other)
    match otherType with
    | .forallE name domain _ binderInfo =>
      if ← isDefEq ctx (.lam name domain (.app other (.bvar 0)) binderInfo) bFull then
        return true
    | _ => pure ()
  | _, _ => pure ()

  if ← tryEtaStruct ctx aFull bFull then return true
  match ← tryStringLitExpansion ctx aFull bFull with
  | some value => return value
  | none => pure ()
  if ← isDefEqUnitLike ctx aFull bFull then return true
  return false

partial def tryEtaStructCore
    (ctx : CheckerContext)
    (t s : Expr) : Except String Bool := do
  let fn := s.getAppFn
  let args := s.getAppArgs
  let .const ctorName _ := fn | return false
  let some (.ctorInfo ctor) := ctx.env.find? ctorName | return false
  if args.length != ctor.numParams + ctor.numFields then return false
  if !ctx.env.isNonRecStructure ctor.induct then return false
  if !(← isDefEq ctx (← infer ctx t) (← infer ctx s)) then return false
  let rec loop (i : Nat) : Except String Bool := do
    if i < ctor.numFields then
      let some arg := listGet? args (ctor.numParams + i) | return false
      let ok ← isDefEq ctx (.proj ctor.induct i t) arg
      if !ok then return false
      loop (i + 1)
    else
      return true
  loop 0

partial def tryEtaStruct
    (ctx : CheckerContext)
    (t s : Expr) : Except String Bool := do
  if ← tryEtaStructCore ctx t s then return true
  tryEtaStructCore ctx s t

partial def tryStringLitExpansionCore
    (ctx : CheckerContext)
    (t s : Expr) : Except String (Option Bool) := do
  match t with
  | .lit (.str value) =>
      if isStringOfListApp s then
        let expanded ← whnf ctx (stringLitToConstructor value)
        return some (← isDefEq ctx expanded s)
      else
        return none
  | _ => return none

partial def tryStringLitExpansion
    (ctx : CheckerContext)
    (t s : Expr) : Except String (Option Bool) := do
  match ← tryStringLitExpansionCore ctx t s with
  | some value => return some value
  | none => tryStringLitExpansionCore ctx s t

partial def isDefEqUnitLike
    (ctx : CheckerContext)
    (t s : Expr) : Except String Bool := do
  let tType ← whnf ctx (← infer ctx t)
  let .const inductName _ := tType.getAppFn | return false
  if !ctx.env.isNonRecStructure inductName then return false
  let some (.inductInfo induct) := ctx.env.find? inductName | return false
  let [ctorName] := induct.ctors | return false
  let some (.ctorInfo ctor) := ctx.env.find? ctorName | return false
  if ctor.numFields != 0 then return false
  isDefEq ctx tType (← infer ctx s)

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
    | .nat value => do
        checkNatSize value
        .ok (.const kernelNatName [])
    | .str _ => .ok (.const kernelStringName [])
  | .mdata _ body => infer ctx body
  | .app fn arg => do
    let fnType ← infer ctx fn
    let (_, domain, body, _) ← ensureForall ctx fnType
    let argType ← infer ctx arg
    let eqCtx :=
      if isEagerReduceExpr arg then
        { ctx with eagerReduce := true }
      else
        ctx
    let ok ← isDefEq eqCtx argType domain
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
  if idx > leanUInt32Max then
    throw "invalid projection index"
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
