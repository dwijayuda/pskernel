import PSC1Kernel.Quot
import PSC1Kernel.CheckerSession

namespace PSC1Kernel

namespace Kernel

def safetyEq : DefinitionSafety → DefinitionSafety → Bool
  | .unsafeDef, .unsafeDef => true
  | .safe, .safe => true
  | .partialDef, .partialDef => true
  | _, _ => false

def namesEq : List Name → List Name → Bool
  | [], [] => true
  | a :: as, b :: bs => Name.eq a b && namesEq as bs
  | _, _ => false

def nameMember (target : Name) : List Name → Bool
  | [] => false
  | x :: xs => Name.eq target x || nameMember target xs

def arrayPushEqAppendName : Name :=
  .str (.str .anonymous "Array") "push_eq_append"

private def traceArrayPushStage
    (declName : Name)
    (stage : String)
    (k : Unit → α) : α :=
  if Name.eq declName arrayPushEqAppendName then
    dbgTrace ("[psc1-array-push] BEGIN " ++ stage) fun _ =>
      let result := k ()
      dbgTrace ("[psc1-array-push] END " ++ stage) fun _ => result
  else
    k ()

partial def findUndefLevelParam (u : Level) (allowed : List Name) : Option Name :=
  match u with
  | .zero | .mvar _ => none
  | .param n => if nameMember n allowed then none else some n
  | .succ a => findUndefLevelParam a allowed
  | .max a b | .imax a b =>
      match findUndefLevelParam a allowed with
      | some n => some n
      | none => findUndefLevelParam b allowed

def findUndefInLevels (levels : List Level) (allowed : List Name) : Option Name :=
  match levels with
  | [] => none
  | u :: us =>
      match findUndefLevelParam u allowed with
      | some n => some n
      | none => findUndefInLevels us allowed

partial def findUndefExprLevelParam (e : Expr) (allowed : List Name) : Option Name :=
  match e with
  | .bvar _ | .fvar _ | .mvar _ | .lit _ => none
  | .sort u => findUndefLevelParam u allowed
  | .const _ levels => findUndefInLevels levels allowed
  | .app f a =>
      match findUndefExprLevelParam f allowed with
      | some n => some n
      | none => findUndefExprLevelParam a allowed
  | .lam _ type body _ | .forallE _ type body _ =>
      match findUndefExprLevelParam type allowed with
      | some n => some n
      | none => findUndefExprLevelParam body allowed
  | .letE _ type value body _ =>
      match findUndefExprLevelParam type allowed with
      | some n => some n
      | none =>
          match findUndefExprLevelParam value allowed with
          | some n => some n
          | none => findUndefExprLevelParam body allowed
  | .mdata _ body | .proj _ _ body => findUndefExprLevelParam body allowed

partial def levelHasMVar : Level → Bool
  | .mvar _ => true
  | .succ level => levelHasMVar level
  | .max left right | .imax left right =>
      levelHasMVar left || levelHasMVar right
  | .zero | .param _ => false

def levelsHaveMVar : List Level → Bool
  | [] => false
  | level :: rest => levelHasMVar level || levelsHaveMVar rest

partial def hasMVar : Expr → Bool
  | .mvar _ => true
  | .sort level => levelHasMVar level
  | .const _ levels => levelsHaveMVar levels
  | .app f a => hasMVar f || hasMVar a
  | .lam _ type body _ | .forallE _ type body _ => hasMVar type || hasMVar body
  | .letE _ type value body _ => hasMVar type || hasMVar value || hasMVar body
  | .mdata _ body | .proj _ _ body => hasMVar body
  | .bvar _ | .fvar _ | .lit _ => false

def checkNoMVarNoFVar (e : Expr) : Except String Unit :=
  if hasMVar e then
    .error "declaration has metavariables"
  else if e.hasFVar then
    .error "declaration has free variables"
  else
    .ok ()

def checkLevelParams (e : Expr) (allowed : List Name) : Except String Unit :=
  match findUndefExprLevelParam e allowed with
  | some _ => .error "invalid reference to undefined universe level parameter"
  | none => .ok ()

def mkChecker
    (env : Environment)
    (levelParams : List Name)
    (safety : DefinitionSafety)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : CheckerContext :=
  (mkCheckerSession env levelParams safety maxRecDepth maxNatSize nativeEvaluator).context

private def checkConstantBaseWithSession
    (session : CheckerSession)
    (base : ConstantBase) : Except String Unit := do
  if session.context.env.contains base.name then
    throw "already declared"
  if Name.hasDuplicates base.levelParams then
    throw "duplicate universe parameter"
  checkNoMVarNoFVar base.type
  checkLevelParams base.type base.levelParams
  let typeType ← session.check base.type
  let _ ← session.ensureSort typeType
  pure ()

def checkConstantBase
    (env : Environment)
    (base : ConstantBase)
    (safety : DefinitionSafety)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : Except String Unit := do
  let session :=
    mkCheckerSession env base.levelParams safety maxRecDepth maxNatSize nativeEvaluator
  checkConstantBaseWithSession session base

private def checkDefinitionBodyWithSession
    (session : CheckerSession)
    (value : DefinitionInfo) : Except String Unit := do
  checkNoMVarNoFVar value.value
  checkLevelParams value.value value.base.levelParams
  let valueType ← session.check value.value
  unless ← session.isDefEq valueType value.base.type do
    throw "definition type mismatch"

def checkDefinitionBody
    (env : Environment)
    (value : DefinitionInfo)
    (safety : DefinitionSafety)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : Except String Unit := do
  let session :=
    mkCheckerSession env value.base.levelParams safety maxRecDepth maxNatSize nativeEvaluator
  checkDefinitionBodyWithSession session value

def addAxiom
    (env : Environment)
    (value : AxiomInfo)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : Except String Environment := do
  let safety := if value.isUnsafe then DefinitionSafety.unsafeDef else DefinitionSafety.safe
  checkConstantBase env value.base safety maxRecDepth maxNatSize nativeEvaluator
  env.add (.axiomInfo value)

def addDefinition
    (env : Environment)
    (value : DefinitionInfo)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : Except String Environment := do
  match value.safety with
  | .unsafeDef =>
      -- Final Lean 4.34 adds the *full definition* before checking the body,
      -- so recursive unsafe code may unfold itself while being checked.
      let headerSession :=
        mkCheckerSession env value.base.levelParams .unsafeDef maxRecDepth maxNatSize nativeEvaluator
      checkConstantBaseWithSession headerSession value.base
      let work ← env.add (.defnInfo value)
      -- The environment changed. A checker session must never cross this
      -- boundary; the recursive body gets a fresh session bound to `work`.
      let bodySession :=
        mkCheckerSession work value.base.levelParams .unsafeDef maxRecDepth maxNatSize nativeEvaluator
      checkDefinitionBodyWithSession bodySession value
      pure work
  | .safe | .partialDef =>
      let session :=
        mkCheckerSession env value.base.levelParams .safe maxRecDepth maxNatSize nativeEvaluator
      checkConstantBaseWithSession session value.base
      checkDefinitionBodyWithSession session value
      env.add (.defnInfo value)

def addTheorem
    (env : Environment)
    (value : TheoremInfo)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : Except String Environment := do
  let session :=
    mkCheckerSession env value.base.levelParams .safe maxRecDepth maxNatSize nativeEvaluator
  let _ ← traceArrayPushStage value.base.name "header" fun _ =>
    checkConstantBaseWithSession session value.base
  let theoremIsProp ← traceArrayPushStage value.base.name "isProp" fun _ =>
    session.isProp value.base.type
  unless theoremIsProp do
    throw "theorem type is not a proposition"
  checkNoMVarNoFVar value.value
  checkLevelParams value.value value.base.levelParams
  let valueType ← traceArrayPushStage value.base.name "proof-check" fun _ =>
    session.check value.value
  let proofTypeMatches ← traceArrayPushStage value.base.name "proof-defeq" fun _ =>
    session.isDefEq valueType value.base.type
  unless proofTypeMatches do
    throw "theorem proof type mismatch"
  traceArrayPushStage value.base.name "env-add" fun _ =>
    env.add (.thmInfo value)

def addOpaque
    (env : Environment)
    (value : OpaqueInfo)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : Except String Environment := do
  -- Matches final Lean 4.34 environment.cpp: opaque bodies are checked by the
  -- ordinary safe checker even though ConstantInfo retains an isUnsafe bit.
  let session :=
    mkCheckerSession env value.base.levelParams .safe maxRecDepth maxNatSize nativeEvaluator
  checkConstantBaseWithSession session value.base
  checkNoMVarNoFVar value.value
  checkLevelParams value.value value.base.levelParams
  let valueType ← session.check value.value
  unless ← session.isDefEq valueType value.base.type do
    throw "opaque value type mismatch"
  env.add (.opaqueInfo value)

def addMutualDefinitions
    (env : Environment)
    (values : List DefinitionInfo)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : Except String Environment := do
  let first :: _ := values
    | throw "invalid empty mutual definition"
  if first.safety.isSafe then
    throw "invalid mutual definition, declaration is not tagged as unsafe/partial"

  let rec checkHeaders (seen : List Name) : List DefinitionInfo → Except String Unit
    | [] => pure ()
    | value :: rest => do
        unless safetyEq value.safety first.safety do
          throw "invalid mutual definition, declarations must have the same safety annotation"
        unless namesEq value.base.levelParams first.base.levelParams do
          throw "invalid mutual definition, declarations must have the same universe level parameters"
        if nameMember value.base.name seen then
          throw "invalid mutual definition, duplicate declaration name"
        checkConstantBase env value.base first.safety maxRecDepth maxNatSize nativeEvaluator
        checkHeaders (value.base.name :: seen) rest
  checkHeaders [] values

  let work := values.foldl (fun current value => current.addUnchecked (.defnInfo value)) env
  let rec checkBodies : List DefinitionInfo → Except String Unit
    | [] => pure ()
    | value :: rest => do
        checkDefinitionBody work value first.safety maxRecDepth maxNatSize nativeEvaluator
        checkBodies rest
  checkBodies values
  pure work

end Kernel

end PSC1Kernel