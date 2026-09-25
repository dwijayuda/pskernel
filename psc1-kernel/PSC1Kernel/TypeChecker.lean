import Init.Data.Nat.Bitwise.Basic
import Init.Data.String.Basic
import PSC1Kernel.Environment
import PSC1Kernel.LocalContext
import PSC1Kernel.Instantiate

namespace PSC1Kernel

/--
Optional execution boundary for final Lean 4.34's deprecated in-kernel native
reduction markers. The semantic kernel does not execute compiler IR itself;
a host may supply this provider. Absence means fail closed/no native step.
-/
structure NativeEvaluator where
  evalBool : Name → Except String (Option Bool)
  evalNat : Name → Except String (Option Nat)

structure CheckerContext where
  env : Environment
  lctx : LocalContext
  levelParams : List Name
  safety : DefinitionSafety
  eagerReduce : Bool
  nativeEvaluator : Option NativeEvaluator

def CheckerContext.empty (env : Environment) : CheckerContext :=
  {
    env := env
    lctx := .empty
    levelParams := []
    safety := .safe
    eagerReduce := false
    nativeEvaluator := none
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

def kernelLeanName : Name :=
  .str .anonymous "Lean"

def kernelReduceBoolName : Name :=
  .str kernelLeanName "reduceBool"

def kernelReduceNatName : Name :=
  .str kernelLeanName "reduceNat"

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

def isNatZeroExpr (e : Expr) : Bool :=
  match e with
  | .lit (.nat value) => value == 0
  | .const name levels =>
      levels.length == 0 && Name.eq name kernelNatZeroName
  | _ => false

def natPredExpr? (e : Expr) : Option Expr :=
  match e with
  | .lit (.nat (n + 1)) => some (.lit (.nat n))
  | _ =>
      match e.getAppFn with
      | .const name levels =>
          if levels.length == 0 &&
              Name.eq name kernelNatSuccName &&
              e.getAppNumArgs == 1 then
            listGet? e.getAppArgs 0
          else
            none
      | _ => none

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
    if a > 1 then
      if b != 0 then
        if natSizeInBytes a > leanNatMaxSizeDefault / b then
          throw "the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size"
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

structure CheckerCloseBinder where
  internalName : Name
  userName : Name
  type : Expr
  binderInfo : BinderInfo
  value? : Option Expr := none
  nondep : Bool := false

partial def closeCheckerBinders
    (binders : List CheckerCloseBinder)
    (body : Expr)
    (removeDeadLets : Bool := false) : Expr :=
  match binders with
  | [] => body
  | binder :: rest =>
      let inner := closeCheckerBinders rest body removeDeadLets
      match binder.value? with
      | none =>
          .forallE binder.userName binder.type
            (inner.abstractFVars [binder.internalName])
            binder.binderInfo
      | some value =>
          let abstracted := inner.abstractFVars [binder.internalName]
          if removeDeadLets && !abstracted.hasLooseBVarAt 0 then
            inner
          else
            .letE binder.userName binder.type value abstracted binder.nondep

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

partial def recursorMajorInduct?
    (recursor : RecursorInfo) : Option Name :=
  let majorIdx :=
    recursor.numParams + recursor.numMotives +
      recursor.numMinors + recursor.numIndices
  let rec go : Expr → Nat → Option Name
    | .forallE _ domain _ _, 0 =>
        match domain.getAppFn with
        | .const name _ => some name
        | _ => none
    | .forallE _ _ body _, n + 1 => go body n
    | _, _ => none
  go recursor.base.type majorIdx

partial def kDebugNameString : Name → String
  | .anonymous => "_"
  | .str .anonymous value => value
  | .str parent value => kDebugNameString parent ++ "." ++ value
  | .num .anonymous value => toString value
  | .num parent value => kDebugNameString parent ++ "." ++ toString value

partial def kLevelListsEq : List Level → List Level → Bool
  | [], [] => true
  | left :: lefts, right :: rights =>
      Level.equivalent left right && kLevelListsEq lefts rights
  | _, _ => false

partial def kTypesEq
    (ctx : CheckerContext)
    (left right : Expr) : Except String Bool := do
  let left' ← whnf ctx left
  let right' ← whnf ctx right
  if Expr.eq left' right' then
    return true
  match left', right' with
  | .sort u, .sort v =>
      return Level.equivalent u v
  | .const leftName leftLevels, .const rightName rightLevels =>
      return Name.eq leftName rightName &&
        kLevelListsEq leftLevels rightLevels
  | .app leftFn leftArg, .app rightFn rightArg => do
      if !(← kTypesEq ctx leftFn rightFn) then
        return false
      kTypesEq ctx leftArg rightArg
  | .lam _ leftType leftBody _, .lam _ rightType rightBody _ => do
      if !(← kTypesEq ctx leftType rightType) then
        return false
      kTypesEq ctx leftBody rightBody
  | .forallE _ leftType leftBody _, .forallE _ rightType rightBody _ => do
      if !(← kTypesEq ctx leftType rightType) then
        return false
      kTypesEq ctx leftBody rightBody
  | .proj leftName leftIndex leftExpr,
      .proj rightName rightIndex rightExpr =>
      if !Name.eq leftName rightName || leftIndex != rightIndex then
        return false
      kTypesEq ctx leftExpr rightExpr
  | .bvar leftIndex, .bvar rightIndex =>
      return leftIndex == rightIndex
  | .fvar leftName, .fvar rightName =>
      return Name.eq leftName rightName
  | .mvar leftName, .mvar rightName =>
      return Name.eq leftName rightName
  | .lit leftLit, .lit rightLit =>
      return Literal.eq leftLit rightLit
  | _, _ => return false

partial def inferKLambdaSpine
    (ctx : CheckerContext)
    (e : Expr)
    (fvars : List Expr := [])
    (binders : List CheckerCloseBinder := []) :
    Except String (Option Expr) := do
  match e with
  | .lam name domain body binderInfo => do
      let openedDomain := domain.instantiateRev fvars
      let some domainType ← inferKMajorType? ctx openedDomain
        | return none
      let domainType' ← whnf ctx domainType
      let .sort _ := domainType'
        | return none
      let (fresh, child) := ctx.withLocal name openedDomain binderInfo
      let binder : CheckerCloseBinder := {
        internalName := fresh
        userName := name
        type := openedDomain
        binderInfo := binderInfo
      }
      inferKLambdaSpine
        child body (fvars ++ [.fvar fresh]) (binders ++ [binder])
  | tail => do
      let some result ← inferKMajorType? ctx (tail.instantiateRev fvars)
        | return none
      let result := result.cheapBetaReduce
      return some (closeCheckerBinders binders result)

partial def inferKForallSpine
    (ctx : CheckerContext)
    (e : Expr)
    (fvars : List Expr := [])
    (levels : List Level := []) :
    Except String (Option Expr) := do
  match e with
  | .forallE name domain body binderInfo => do
      let openedDomain := domain.instantiateRev fvars
      let some domainType ← inferKMajorType? ctx openedDomain
        | return none
      let domainType' ← whnf ctx domainType
      let .sort level := domainType'
        | return none
      let (fresh, child) := ctx.withLocal name openedDomain binderInfo
      inferKForallSpine
        child body (fvars ++ [.fvar fresh]) (levels ++ [level])
  | tail => do
      let some tailType ← inferKMajorType? ctx (tail.instantiateRev fvars)
        | return none
      let tailType' ← whnf ctx tailType
      let .sort resultLevel := tailType'
        | return none
      return some (.sort (levels.foldr Level.mkIMax resultLevel))

partial def inferKLetSpine
    (ctx : CheckerContext)
    (e : Expr)
    (fvars : List Expr := [])
    (binders : List CheckerCloseBinder := []) :
    Except String (Option Expr) := do
  match e with
  | .letE name type value body nondep => do
      let openedType := type.instantiateRev fvars
      let openedValue := value.instantiateRev fvars
      let some typeType ← inferKMajorType? ctx openedType
        | return none
      let typeType' ← whnf ctx typeType
      let .sort _ := typeType'
        | return none
      let some valueType ← inferKMajorType? ctx openedValue
        | return none
      unless ← kTypesEq ctx openedType valueType do
        return none
      let (fresh, child) := ctx.withLet name openedType openedValue
      let binder : CheckerCloseBinder := {
        internalName := fresh
        userName := name
        type := openedType
        binderInfo := .default
        value? := some openedValue
        nondep := nondep
      }
      inferKLetSpine
        child body (fvars ++ [.fvar fresh]) (binders ++ [binder])
  | tail => do
      let some result ← inferKMajorType? ctx (tail.instantiateRev fvars)
        | return none
      let result := result.cheapBetaReduce
      return some (closeCheckerBinders binders result true)

partial def inferKMajorType?
    (ctx : CheckerContext)
    (major : Expr) : Except String (Option Expr) := do
  match major with
  | .bvar _ | .mvar _ => return none
  | .sort level => return some (.sort (.succ level))
  | .fvar name =>
      match ctx.lctx.find? name with
      | some decl => return some decl.type
      | none => return none
  | .const name levels =>
      match ctx.env.find? name with
      | some info =>
          if info.levelParams.length == levels.length then
            return some
              (info.type.instantiateLevelParams info.levelParams levels)
          else
            return none
      | none => return none
  | .lit (.nat _) => return some (.const kernelNatName [])
  | .lit (.str _) => return some (.const kernelStringName [])
  | .mdata _ body => inferKMajorType? ctx body
  | .app _ _ => do
      -- Lean 4.34's `infer_type` uses infer-only application inference here:
      -- flatten the application, postpone binder substitution across an
      -- already-visible Pi spine, and do not type-check the arguments.
      let fn := major.getAppFn
      let args := major.getAppArgs
      let some fnType ← inferKMajorType? ctx fn
        | return none
      let rec go
          (current : Expr)
          (remaining : List Expr)
          (pending : List Expr) :
          Except String (Option Expr) := do
        match remaining with
        | [] =>
            return some (current.instantiateRev pending)
        | arg :: rest =>
            match current with
            | .forallE _ _ body _ =>
                go body rest (pending ++ [arg])
            | _ =>
                let applied := current.instantiateRev pending
                let reduced ← whnf ctx applied
                let .forallE _ _ body _ := reduced
                  | return none
                go body rest [arg]
      go fnType args []
  | .lam .. => inferKLambdaSpine ctx major
  | .forallE .. => inferKForallSpine ctx major
  | .letE .. => inferKLetSpine ctx major
  | .proj _ _ _ => return none

partial def exprHasMVarForK : Expr → Bool
  | .mvar _ => true
  | .sort level =>
      match level with
      | .mvar _ => true
      | _ => false
  | .const _ levels =>
      levels.any fun level =>
        match level with
        | .mvar _ => true
        | _ => false
  | .app fn arg =>
      exprHasMVarForK fn || exprHasMVarForK arg
  | .lam _ type body _ | .forallE _ type body _ =>
      exprHasMVarForK type || exprHasMVarForK body
  | .letE _ type value body _ =>
      exprHasMVarForK type ||
        exprHasMVarForK value ||
        exprHasMVarForK body
  | .mdata _ body | .proj _ _ body => exprHasMVarForK body
  | .bvar _ | .fvar _ | .lit _ => false

partial def consumeKConstructorParams
    (ctx : CheckerContext)
    (type : Expr)
    (params : List Expr) : Except String (Option Expr) := do
  match params with
  | [] => return some (← whnf ctx type)
  | param :: rest =>
      let reduced ← whnf ctx type
      let .forallE _ _ body _ := reduced
        | return none
      consumeKConstructorParams ctx (body.instantiate1 param) rest

partial def toConstructorWhenK
    (ctx : CheckerContext)
    (recursor : RecursorInfo)
    (major : Expr) : Except String Expr := do
  let eqRec : Name := .str (.str .anonymous "Eq") "rec"
  let debugEq := Name.eq recursor.base.name eqRec
  let some majorInduct := recursorMajorInduct? recursor
    | if debugEq then throw "Eq.rec K debug: missing major inductive" else return major
  let some rawType ← inferKMajorType? ctx major
    | if debugEq then
        match major with
        | .bvar index =>
            throw ("Eq.rec K debug: major type inference failed; major=bvar " ++ toString index)
        | .fvar name =>
            if (ctx.lctx.find? name).isSome then
              throw "Eq.rec K debug: major type inference failed; major=fvar-known"
            else
              throw "Eq.rec K debug: major type inference failed; major=fvar-missing"
        | .app _ _ =>
            let head :=
              match major.getAppFn with
              | .const name _ => kDebugNameString name
              | .fvar name => "fvar:" ++ kDebugNameString name
              | .bvar index => "bvar:" ++ toString index
              | _ => "non-constant"
            throw ("Eq.rec K debug: major type inference failed; major=app args=" ++
              toString major.getAppNumArgs ++ "; head=" ++ head)
        | .lam .. => throw "Eq.rec K debug: major type inference failed; major=lambda"
        | .forallE .. => throw "Eq.rec K debug: major type inference failed; major=forall"
        | .letE .. => throw "Eq.rec K debug: major type inference failed; major=let"
        | .proj _ _ _ => throw "Eq.rec K debug: major type inference failed; major=projection"
        | .const _ _ => throw "Eq.rec K debug: major type inference failed; major=const"
        | .sort _ => throw "Eq.rec K debug: major type inference failed; major=sort"
        | .mvar _ => throw "Eq.rec K debug: major type inference failed; major=mvar"
        | .lit _ => throw "Eq.rec K debug: major type inference failed; major=literal"
        | .mdata _ _ => throw "Eq.rec K debug: major type inference failed; major=mdata"
      else
        return major
  let appType ← whnf ctx rawType
  let .const typeInduct typeLevels := appType.getAppFn
    | if debugEq then throw "Eq.rec K debug: major type head is not constant" else return major
  if !Name.eq typeInduct majorInduct then
    if debugEq then throw "Eq.rec K debug: major inductive mismatch" else return major
  if exprHasMVarForK appType then
    if debugEq then throw "Eq.rec K debug: major type has metavariables" else return major
  let some (.inductInfo induct) := ctx.env.find? typeInduct
    | if debugEq then throw "Eq.rec K debug: inductive metadata missing" else return major
  let ctorName :: _ := induct.ctors
    | if debugEq then throw "Eq.rec K debug: no constructor" else return major
  let some (.ctorInfo ctor) := ctx.env.find? ctorName
    | if debugEq then throw "Eq.rec K debug: constructor metadata missing" else return major
  if ctor.numFields != 0 || ctor.numParams != recursor.numParams then
    if debugEq then throw "Eq.rec K debug: constructor arity mismatch" else return major
  if ctor.base.levelParams.length != typeLevels.length then
    if debugEq then throw "Eq.rec K debug: constructor universe arity mismatch" else return major
  let params := appType.getAppArgs.take recursor.numParams
  if params.length != recursor.numParams then
    if debugEq then throw "Eq.rec K debug: parameter arity mismatch" else return major
  let ctorType0 :=
    ctor.base.type.instantiateLevelParams ctor.base.levelParams typeLevels
  let some ctorType ← consumeKConstructorParams ctx ctorType0 params
    | if debugEq then throw "Eq.rec K debug: constructor parameter consumption failed" else return major
  unless ← kTypesEq ctx ctorType appType do
    if debugEq then throw "Eq.rec K debug: constructor result type mismatch" else return major
  pure (applyArgs (.const ctorName typeLevels) params)

partial def isConstructorApp
    (env : Environment)
    (e : Expr) : Bool :=
  match e.getAppFn with
  | .const name _ =>
      match env.find? name with
      | some (.ctorInfo _) => true
      | _ => false
  | _ => false

partial def isPropTypeForStructure
    (ctx : CheckerContext)
    (type : Expr) : Except String Bool := do
  let some sortType ← inferKMajorType? ctx type
    | return false
  let sortType' ← whnf ctx sortType
  match sortType' with
  | .sort level => return Level.normalizesToZero level
  | _ => return false

/--
Lean 4.34 `to_cnstr_when_structure`: when a recursor major is an arbitrary
value of a non-recursive, non-Prop structure, eta-expand it to the unique
constructor applied to its parameters and field projections. This lets iota
reduction proceed even when the major is not syntactically a constructor.
-/
partial def toConstructorWhenStructure
    (ctx : CheckerContext)
    (recursor : RecursorInfo)
    (major : Expr) : Except String Expr := do
  if isConstructorApp ctx.env major then
    return major
  let some inductName := recursorMajorInduct? recursor
    | return major
  if !ctx.env.isNonRecStructure inductName then
    return major
  let some rawType ← inferKMajorType? ctx major
    | return major
  let majorType ← whnf ctx rawType
  let .const typeName levels := majorType.getAppFn
    | return major
  if !Name.eq typeName inductName then
    return major
  if ← isPropTypeForStructure ctx majorType then
    return major
  let some (.inductInfo induct) := ctx.env.find? inductName
    | return major
  let [ctorName] := induct.ctors
    | return major
  let some (.ctorInfo ctor) := ctx.env.find? ctorName
    | return major
  let args := majorType.getAppArgs
  if args.length < ctor.numParams then
    return major
  let params := args.take ctor.numParams
  let rec fields (i : Nat) : List Expr :=
    if h : i < ctor.numFields then
      .proj inductName i major :: fields (i + 1)
    else
      []
  pure (applyArgs (.const ctorName levels) (params ++ fields 0))

partial def reduceInductiveRec
    (ctx : CheckerContext)
    (e : Expr)
    (cheapRec cheapProj : Bool) : Except String (Option Expr) := do
  let .const recName recLevels := e.getAppFn | return none
  let some (.recInfo recursor) := ctx.env.find? recName | return none
  let recArgs := e.getAppArgs
  let majorIdx :=
    recursor.numParams + recursor.numMotives +
      recursor.numMinors + recursor.numIndices
  if majorIdx >= recArgs.length then
    return none
  let some major0 := listGet? recArgs majorIdx | return none
  let majorK ←
    if recursor.k then toConstructorWhenK ctx recursor major0
    else pure major0
  let majorReduced ←
    if cheapRec then whnfCore ctx majorK cheapRec cheapProj
    else whnf ctx majorK
  let major ←
    match majorReduced with
    | .lit (.nat 0) =>
        .ok (Expr.const kernelNatZeroName [])
    | .lit (.nat (n + 1)) =>
        .ok (Expr.app (Expr.const kernelNatSuccName []) (.lit (.nat n)))
    | .lit (.str value) =>
        whnf ctx (stringLitToConstructor value)
    | _ =>
        toConstructorWhenStructure ctx recursor majorReduced
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
    (cheapRec cheapProj : Bool) : Except String (Option Expr) := do
  let quot ← reduceQuotRec ctx e
  match quot with
  | some value => return some value
  | none => reduceInductiveRec ctx e cheapRec cheapProj

partial def whnfCore
    (ctx : CheckerContext)
    (e : Expr)
    (cheapRec cheapProj : Bool) : Except String Expr :=
  match e with
  | .bvar _ | .sort _ | .mvar _ | .forallE _ _ _ _
  | .const _ _ | .lam _ _ _ _ | .lit _ => .ok e
  | .mdata _ body => whnfCore ctx body cheapRec cheapProj
  | .fvar name =>
    match ctx.lctx.find? name with
    | some decl =>
      match decl.value? with
      | some value => whnfCore ctx value cheapRec cheapProj
      | none => .ok e
    | none => .ok e
  | .letE _ _ value body _ =>
    whnfCore ctx (body.instantiate1 value) cheapRec cheapProj
  | .proj typeName idx struct => do
    let struct' ←
      if cheapProj then whnfCore ctx struct cheapRec cheapProj
      else whnf ctx struct
    let struct'' ←
      match struct' with
      | .lit (.str value) => whnf ctx (stringLitToConstructor value)
      | _ => .ok struct'
    match reduceProjCore ctx typeName idx struct'' with
    | some value => whnfCore ctx value cheapRec cheapProj
    | none => .ok e
  | .app fn arg => do
    let fn' ← whnfCore ctx fn cheapRec cheapProj
    match fn' with
    | .lam _ _ body _ =>
      whnfCore ctx (body.instantiate1 arg) cheapRec cheapProj
    | _ =>
      if Expr.eq fn fn' then
        let reduced ← reduceRecursor ctx e cheapRec cheapProj
        match reduced with
        | some value => whnfCore ctx value cheapRec cheapProj
        | none => .ok e
      else
        whnfCore ctx (.app fn' arg) cheapRec cheapProj

partial def reduceNative
    (ctx : CheckerContext)
    (e : Expr) : Except String (Option Expr) := do
  let some provider := ctx.nativeEvaluator
    | return none
  match e with
  | .app (.const marker levels) (.const target _) =>
      if levels.length != 0 then
        return none
      if Name.eq marker kernelReduceBoolName then
        match ← provider.evalBool target with
        | some value => return some (boolExpr value)
        | none => return none
      else if Name.eq marker kernelReduceNatName then
        match ← provider.evalNat target with
        | some value => return some (.lit (.nat value))
        | none => return none
      else
        return none
  | _ => return none

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
    let core ← whnfCore ctx t false false
    let native ← reduceNative ctx core
    match native with
    | some value => return value
    | none => pure ()
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

inductive DeltaStepResult where
  | continue (left : Expr) (right : Expr)
  | unknown (left : Expr) (right : Expr)
  | equal
  | different (left : Expr) (right : Expr)

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
  whnfCore ctx unfolded false true

partial def tryUnfoldProjApp
    (ctx : CheckerContext)
    (e : Expr) : Except String (Option Expr) := do
  match e.getAppFn with
  | .proj _ _ _ =>
      let reduced ← whnfCore ctx e false false
      if Expr.eq reduced e then
        return none
      else
        return some reduced
  | _ => return none

def sameDeltaDefinition (a b : DefinitionInfo) : Bool :=
  Name.eq a.base.name b.base.name

def appHeadLevelsEquivalent (a b : Expr) : Bool :=
  match a.getAppFn, b.getAppFn with
  | .const _ as, .const _ bs => levelListsEquivalent as bs
  | _, _ => false

mutual

/--
Lean 4.34 compares consecutive lambda binders as one spine.  Opening all
dependent binders with shared locals and delaying substitution is observable
because kernel definitional equality is deliberately incomplete.
-/
partial def isDefEqLambdaSpine
    (ctx : CheckerContext)
    (left right : Expr)
    (subst : List Expr := []) : Except String Bool := do
  match left, right with
  | .lam _ leftDomain leftBody _,
      .lam rightName rightDomain rightBody rightBinderInfo => do
      let leftDomain' := leftDomain.instantiateRev subst
      let rightDomain' := rightDomain.instantiateRev subst
      if !Expr.eq leftDomain rightDomain then
        if !(← isDefEq ctx leftDomain' rightDomain') then
          return false
      if leftBody.hasLooseBVar || rightBody.hasLooseBVar then
        let (fresh, child) :=
          ctx.withLocal rightName rightDomain' rightBinderInfo
        isDefEqLambdaSpine
          child leftBody rightBody (subst ++ [.fvar fresh])
      else
        -- Lean uses an internal don't-care term here.  The value cannot be
        -- observed because neither remaining body references this binder.
        isDefEqLambdaSpine
          ctx leftBody rightBody (subst ++ [.sort .zero])
  | _, _ =>
      isDefEq ctx
        (left.instantiateRev subst)
        (right.instantiateRev subst)

/--
Lean 4.34's corresponding whole-spine comparison for forall expressions.
-/
partial def isDefEqForallSpine
    (ctx : CheckerContext)
    (left right : Expr)
    (subst : List Expr := []) : Except String Bool := do
  match left, right with
  | .forallE _ leftDomain leftBody _,
      .forallE rightName rightDomain rightBody rightBinderInfo => do
      let leftDomain' := leftDomain.instantiateRev subst
      let rightDomain' := rightDomain.instantiateRev subst
      if !Expr.eq leftDomain rightDomain then
        if !(← isDefEq ctx leftDomain' rightDomain') then
          return false
      if leftBody.hasLooseBVar || rightBody.hasLooseBVar then
        let (fresh, child) :=
          ctx.withLocal rightName rightDomain' rightBinderInfo
        isDefEqForallSpine
          child leftBody rightBody (subst ++ [.fvar fresh])
      else
        isDefEqForallSpine
          ctx leftBody rightBody (subst ++ [.sort .zero])
  | _, _ =>
      isDefEq ctx
        (left.instantiateRev subst)
        (right.instantiateRev subst)

partial def isDefEqArgs
    (ctx : CheckerContext)
    (left right : Expr) : Except String Bool := do
  match left, right with
  | .app lf la, .app rf ra =>
      if !(← isDefEq ctx la ra) then
        return false
      isDefEqArgs ctx lf rf
  | .app _ _, _ => return false
  | _, .app _ _ => return false
  | _, _ => return true

partial def lazyDeltaReductionStep
    (ctx : CheckerContext)
    (left right : Expr) : Except String DeltaStepResult := do
  let finish (a b : Expr) : DeltaStepResult :=
    match quickReducedDefEq a b with
    | some true => .equal
    | some false => .different a b
    | none => .continue a b

  match deltaDefinition? ctx left, deltaDefinition? ctx right with
  | none, none =>
      return .unknown left right
  | some _, none =>
      match ← tryUnfoldProjApp ctx right with
      | some right' => return finish left right'
      | none =>
          let left' ← deltaOnce ctx left
          return finish left' right
  | none, some _ =>
      match ← tryUnfoldProjApp ctx left with
      | some left' => return finish left' right
      | none =>
          let right' ← deltaOnce ctx right
          return finish left right'
  | some da, some db =>
      if da.hints.lt db.hints then
        let left' ← deltaOnce ctx left
        return finish left' right
      else if db.hints.lt da.hints then
        let right' ← deltaOnce ctx right
        return finish left right'
      else
        if left.getAppNumArgs > 0 then
          if right.getAppNumArgs > 0 then
            if sameDeltaDefinition da db &&
                da.hints.isRegular &&
                appHeadLevelsEquivalent left right then
              if ← isDefEqArgs ctx left right then
                return .equal
        let left' ← deltaOnce ctx left
        let right' ← deltaOnce ctx right
        return finish left' right'

partial def lazyDeltaReduction
    (ctx : CheckerContext)
    (left right : Expr) : Except String DeltaResult := do
  let rec loop (a b : Expr) : Except String DeltaResult := do
    -- Final Lean 4.34 tries the Nat offset rule before ordinary Nat
    -- reduction, and does so regardless of syntactic free variables.
    if isNatZeroExpr a && isNatZeroExpr b then
      return .decided true
    match natPredExpr? a, natPredExpr? b with
    | some pa, some pb =>
        return .decided (← isDefEq ctx pa pb)
    | _, _ => pure ()

    if (!a.hasFVar && !b.hasFVar) || ctx.eagerReduce then
      let ar ← reduceNat ctx a
      match ar with
      | some value => return .decided (← isDefEq ctx value b)
      | none => pure ()
      let br ← reduceNat ctx b
      match br with
      | some value => return .decided (← isDefEq ctx a value)
      | none => pure ()

    let an ← reduceNative ctx a
    match an with
    | some value => return .decided (← isDefEq ctx value b)
    | none => pure ()
    let bn ← reduceNative ctx b
    match bn with
    | some value => return .decided (← isDefEq ctx a value)
    | none => pure ()

    match ← lazyDeltaReductionStep ctx a b with
    | .continue a' b' => loop a' b'
    | .unknown a' b' => return .residual a' b'
    | .equal => return .decided true
    | .different _ _ => return .decided false
  loop left right

partial def lazyDeltaProjReduction
    (ctx : CheckerContext)
    (left right : Expr)
    (typeName : Name)
    (index : Nat) : Except String Bool := do
  let rec finish (a b : Expr) : Except String Bool := do
    match reduceProjCore ctx typeName index a,
          reduceProjCore ctx typeName index b with
    | some lfield, some rfield => isDefEq ctx lfield rfield
    | _, _ => isDefEq ctx a b

  let rec loop (a b : Expr) : Except String Bool := do
    match ← lazyDeltaReductionStep ctx a b with
    | .continue a' b' => loop a' b'
    | .equal => return true
    | .unknown a' b' => finish a' b'
    | .different a' b' => finish a' b'
  loop left right

partial def isDefEq (ctx : CheckerContext) (a b : Expr) : Except String Bool := do
  if Expr.eq a b then return true

  -- Lean 4.34 handles binding expressions in the quick-defeq phase by
  -- opening both bodies with the same fresh local. Binder names/annotations
  -- are not part of definitional equality.
  match a, b with
  | .lam .., .lam .. =>
      return ← isDefEqLambdaSpine ctx a b
  | .forallE .., .forallE .. =>
      return ← isDefEqForallSpine ctx a b
  | _, _ => pure ()

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

  let aCore ← whnfCore ctx a false true
  let bCore ← whnfCore ctx b false true
  match quickReducedDefEq aCore bCore with
  | some value => return value
  | none => pure ()
  match aCore, bCore with
  | .lam .., .lam .. =>
      return ← isDefEqLambdaSpine ctx aCore bCore
  | .forallE .., .forallE .. =>
      return ← isDefEqForallSpine ctx aCore bCore
  | _, _ => pure ()

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
  let aFull ← whnfCore ctx aDelta false false
  let bFull ← whnfCore ctx bDelta false false
  if !Expr.eq aFull aDelta || !Expr.eq bFull bDelta then
    return ← isDefEq ctx aFull bFull

  match aFull, bFull with
  | .sort u, .sort v => return Level.equivalent u v
  | .lit x, .lit y => return Literal.eq x y
  | .app f₁ a₁, .app f₂ a₂ => do
    let hf ← isDefEq ctx f₁ f₂
    if hf then
      if ← isDefEq ctx a₁ a₂ then return true
  | .forallE .., .forallE .. => do
    if ← isDefEqForallSpine ctx aFull bFull then
      return true
  | .lam .., .lam .. => do
    if ← isDefEqLambdaSpine ctx aFull bFull then
      return true
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

partial def typeCheckerNameString : Name → String
  | .anonymous => "_"
  | .str .anonymous value => value
  | .str parent value => typeCheckerNameString parent ++ "." ++ value
  | .num .anonymous value => toString value
  | .num parent value => typeCheckerNameString parent ++ "." ++ toString value

partial def typeCheckerExprHead (e : Expr) : String :=
  let args := e.getAppNumArgs
  match e.getAppFn with
  | .const name _ =>
      "const " ++ typeCheckerNameString name ++
        " (args=" ++ toString args ++ ")"
  | .fvar name =>
      "fvar " ++ typeCheckerNameString name ++
        " (args=" ++ toString args ++ ")"
  | .bvar index =>
      "bvar " ++ toString index ++
        " (args=" ++ toString args ++ ")"
  | .mvar name =>
      "mvar " ++ typeCheckerNameString name ++
        " (args=" ++ toString args ++ ")"
  | .sort _ => "sort"
  | .lam _ _ _ _ => "lambda"
  | .forallE _ _ _ _ => "forall"
  | .letE _ _ _ _ _ => "let"
  | .lit _ => "literal"
  | .mdata _ _ => "metadata"
  | .proj name index _ =>
      "projection " ++ typeCheckerNameString name ++ "." ++ toString index
  | .app _ _ => "application"

partial def typeCheckerExprDiffAt
    (path : String) (left right : Expr) : Option String :=
  if Expr.eq left right then
    none
  else
    match left, right with
    | .app lf la, .app rf ra =>
        match typeCheckerExprDiffAt (path ++ ".fn") lf rf with
        | some diff => some diff
        | none => typeCheckerExprDiffAt (path ++ ".arg") la ra
    | .lam _ lt lb _, .lam _ rt rb _ =>
        match typeCheckerExprDiffAt (path ++ ".lamType") lt rt with
        | some diff => some diff
        | none => typeCheckerExprDiffAt (path ++ ".lamBody") lb rb
    | .forallE _ lt lb _, .forallE _ rt rb _ =>
        match typeCheckerExprDiffAt (path ++ ".forallType") lt rt with
        | some diff => some diff
        | none => typeCheckerExprDiffAt (path ++ ".forallBody") lb rb
    | .letE _ lt lv lb lnd, .letE _ rt rv rb rnd =>
        if lnd != rnd then
          some (path ++ ": let nondep mismatch")
        else
          match typeCheckerExprDiffAt (path ++ ".letType") lt rt with
          | some diff => some diff
          | none =>
              match typeCheckerExprDiffAt (path ++ ".letValue") lv rv with
              | some diff => some diff
              | none => typeCheckerExprDiffAt (path ++ ".letBody") lb rb
    | .mdata _ le, .mdata _ re =>
        typeCheckerExprDiffAt (path ++ ".mdata") le re
    | .proj ln li le, .proj rn ri re =>
        if Name.eq ln rn && li == ri then
          typeCheckerExprDiffAt (path ++ ".proj") le re
        else
          some (path ++ ": projection metadata mismatch")
    | _, _ =>
        some (path ++ ": " ++ typeCheckerExprHead left ++
          " != " ++ typeCheckerExprHead right)

partial def typeCheckerExprDiff (left right : Expr) : String :=
  (typeCheckerExprDiffAt "root" left right).getD "no structural difference"

partial def typeCheckerWhnfSpineDiff
    (ctx : CheckerContext)
    (left right : Expr)
    (depth : Nat := 0) : Except String String := do
  if depth > 16 then
    return "binder-aware diff exceeded depth"
  let leftWhnf ← whnf ctx left
  let rightWhnf ← whnf ctx right
  match leftWhnf, rightWhnf with
  | .forallE _ leftDomain leftBody leftBi,
      .forallE rightName rightDomain rightBody rightBi =>
      let (fresh, child) := ctx.withLocal rightName rightDomain rightBi
      let leftOpened := leftBody.instantiate1 (.fvar fresh)
      let rightOpened := rightBody.instantiate1 (.fvar fresh)
      typeCheckerWhnfSpineDiff child leftOpened rightOpened (depth + 1)
  | _, _ =>
      let projectionDetail ←
        match leftWhnf.getAppFn with
        | .proj typeName index struct => do
            let structWhnf ← whnf ctx struct
            let ctorDetail :=
              match structWhnf.getAppFn with
              | .const ctorName _ =>
                  match ctx.env.find? ctorName with
                  | some (.ctorInfo ctor) =>
                      "; ctor=" ++ typeCheckerNameString ctorName ++
                      "; ctor.induct=" ++ typeCheckerNameString ctor.induct ++
                      "; ctor.numParams=" ++ toString ctor.numParams ++
                      "; ctor.numFields=" ++ toString ctor.numFields ++
                      "; ctor.args=" ++ toString structWhnf.getAppNumArgs
                  | _ =>
                      "; head-const=" ++ typeCheckerNameString ctorName ++
                      " (not constructor)"
              | _ => ""
            pure (
              "; projection=" ++ typeCheckerNameString typeName ++ "." ++
              toString index ++
              "; projection-extra-args=" ++ toString leftWhnf.getAppNumArgs ++
              "; struct=" ++ typeCheckerExprHead struct ++
              "; struct-whnf=" ++ typeCheckerExprHead structWhnf ++
              ctorDetail)
        | _ => pure ""
      return (
        "depth=" ++ toString depth ++
        "; left=" ++ typeCheckerExprHead leftWhnf ++
        "; right=" ++ typeCheckerExprHead rightWhnf ++
        "; diff=" ++ typeCheckerExprDiff leftWhnf rightWhnf ++
        projectionDetail)

partial def inferLambdaSpine
    (ctx : CheckerContext)
    (e : Expr)
    (fvars : List Expr := [])
    (binders : List CheckerCloseBinder := []) : Except String Expr := do
  match e with
  | .lam name domain body binderInfo => do
      let openedDomain := domain.instantiateRev fvars
      let domainType ← infer ctx openedDomain
      let _ ← ensureSort ctx domainType
      let (fresh, child) := ctx.withLocal name openedDomain binderInfo
      let binder : CheckerCloseBinder := {
        internalName := fresh
        userName := name
        type := openedDomain
        binderInfo := binderInfo
      }
      inferLambdaSpine
        child body (fvars ++ [.fvar fresh]) (binders ++ [binder])
  | tail => do
      let result ← infer ctx (tail.instantiateRev fvars)
      let result := result.cheapBetaReduce
      pure (closeCheckerBinders binders result)

partial def inferForallSpine
    (ctx : CheckerContext)
    (e : Expr)
    (fvars : List Expr := [])
    (levels : List Level := []) : Except String Expr := do
  match e with
  | .forallE name domain body binderInfo => do
      let openedDomain := domain.instantiateRev fvars
      let domainType ← infer ctx openedDomain
      let level ← ensureSort ctx domainType
      let (fresh, child) := ctx.withLocal name openedDomain binderInfo
      inferForallSpine
        child body (fvars ++ [.fvar fresh]) (levels ++ [level])
  | tail => do
      let openedTail := tail.instantiateRev fvars
      let tailType ← infer ctx openedTail
      let resultLevel ← ensureSort ctx tailType
      pure (.sort (levels.foldr Level.mkIMax resultLevel))

partial def inferLetSpine
    (ctx : CheckerContext)
    (e : Expr)
    (fvars : List Expr := [])
    (binders : List CheckerCloseBinder := []) : Except String Expr := do
  match e with
  | .letE name type value body nondep => do
      let openedType := type.instantiateRev fvars
      let openedValue := value.instantiateRev fvars
      let typeType ← infer ctx openedType
      let _ ← ensureSort ctx typeType
      let valueType ← infer ctx openedValue
      if !(← isDefEq ctx valueType openedType) then
        throw "let value type mismatch"
      let (fresh, child) := ctx.withLet name openedType openedValue
      let binder : CheckerCloseBinder := {
        internalName := fresh
        userName := name
        type := openedType
        binderInfo := .default
        value? := some openedValue
        nondep := nondep
      }
      inferLetSpine
        child body (fvars ++ [.fvar fresh]) (binders ++ [binder])
  | tail => do
      let result ← infer ctx (tail.instantiateRev fvars)
      let result := result.cheapBetaReduce
      pure (closeCheckerBinders binders result true)

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
    let forallInfo ←
      match ensureForall ctx fnType with
      | .ok value => pure value
      | .error _ => do
          let reduced ← whnf ctx fnType
          throw (
            "expected function type while applying " ++
            typeCheckerExprHead fn ++
            "; reduced function type is " ++
            typeCheckerExprHead reduced)
    let (_, domain, body, _) := forallInfo
    let argType ← infer ctx arg
    let eqCtx :=
      if isEagerReduceExpr arg then
        { ctx with eagerReduce := true }
      else
        ctx
    let ok ← isDefEq eqCtx argType domain
    if !ok then
      let domainWhnf ← whnf eqCtx domain
      let argTypeWhnf ← whnf eqCtx argType
      let spineDiff ←
        typeCheckerWhnfSpineDiff eqCtx domain argType
      .error (
        "application type mismatch while applying " ++
        typeCheckerExprHead fn ++
        " to " ++ typeCheckerExprHead arg ++
        "; expected domain " ++ typeCheckerExprHead domain ++
        "; argument type " ++ typeCheckerExprHead argType ++
        "; first structural diff: " ++
        typeCheckerExprDiff domain argType ++
        "; full-whnf expected " ++ typeCheckerExprHead domainWhnf ++
        "; full-whnf argument " ++ typeCheckerExprHead argTypeWhnf ++
        "; full-whnf diff: " ++
        typeCheckerExprDiff domainWhnf argTypeWhnf ++
        "; binder-aware whnf: " ++ spineDiff)
    else
      .ok (body.instantiate1 arg)
  | .lam .. => inferLambdaSpine ctx e
  | .forallE .. => inferForallSpine ctx e
  | .letE .. => inferLetSpine ctx e
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
