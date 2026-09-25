import PSC1Kernel.Quot

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

partial def hasMVar : Expr → Bool
  | .mvar _ => true
  | .app f a => hasMVar f || hasMVar a
  | .lam _ type body _ | .forallE _ type body _ => hasMVar type || hasMVar body
  | .letE _ type value body _ => hasMVar type || hasMVar value || hasMVar body
  | .mdata _ body | .proj _ _ body => hasMVar body
  | .bvar _ | .fvar _ | .sort _ | .const _ _ | .lit _ => false

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
    (maxRecDepth : Nat := 0) : CheckerContext :=
  {
    env := env
    lctx := .empty
    levelParams := levelParams
    safety := safety
    eagerReduce := false
    nativeEvaluator := none
    maxRecDepth := maxRecDepth
    recDepth := 0
  }

def checkConstantBase
    (env : Environment)
    (base : ConstantBase)
    (safety : DefinitionSafety)
    (maxRecDepth : Nat := 0) : Except String Unit := do
  if env.contains base.name then
    throw "already declared"
  if Name.hasDuplicates base.levelParams then
    throw "duplicate universe parameter"
  checkNoMVarNoFVar base.type
  checkLevelParams base.type base.levelParams
  let ctx := mkChecker env base.levelParams safety maxRecDepth
  let typeType ← check ctx base.type
  let _ ← ensureSort ctx typeType
  pure ()

def checkDefinitionBody
    (env : Environment)
    (value : DefinitionInfo)
    (safety : DefinitionSafety)
    (maxRecDepth : Nat := 0) : Except String Unit := do
  checkNoMVarNoFVar value.value
  checkLevelParams value.value value.base.levelParams
  let ctx := mkChecker env value.base.levelParams safety maxRecDepth
  let valueType ← check ctx value.value
  unless ← isDefEq ctx valueType value.base.type do
    throw "definition type mismatch"

def addAxiom (env : Environment) (value : AxiomInfo) : Except String Environment := do
  let safety := if value.isUnsafe then DefinitionSafety.unsafeDef else DefinitionSafety.safe
  checkConstantBase env value.base safety
  env.add (.axiomInfo value)

def addDefinition
    (env : Environment)
    (value : DefinitionInfo)
    (maxRecDepth : Nat := 0) : Except String Environment := do
  match value.safety with
  | .unsafeDef =>
      -- Final Lean 4.34 adds the *full definition* before checking the body,
      -- so recursive unsafe code may unfold itself while being checked.
      checkConstantBase env value.base .unsafeDef maxRecDepth
      let work ← env.add (.defnInfo value)
      checkDefinitionBody work value .unsafeDef maxRecDepth
      pure work
  | .safe | .partialDef =>
      checkConstantBase env value.base .safe maxRecDepth
      checkDefinitionBody env value .safe maxRecDepth
      env.add (.defnInfo value)

def addTheorem (env : Environment) (value : TheoremInfo) : Except String Environment := do
  checkConstantBase env value.base .safe
  let ctx := mkChecker env value.base.levelParams .safe
  unless ← isProp ctx value.base.type do
    throw "theorem type is not a proposition"
  checkNoMVarNoFVar value.value
  checkLevelParams value.value value.base.levelParams
  let valueType ← check ctx value.value
  unless ← isDefEq ctx valueType value.base.type do
    throw "theorem proof type mismatch"
  env.add (.thmInfo value)

def addOpaque (env : Environment) (value : OpaqueInfo) : Except String Environment := do
  -- Matches final Lean 4.34 environment.cpp: opaque bodies are checked by the
  -- ordinary safe checker even though ConstantInfo retains an isUnsafe bit.
  checkConstantBase env value.base .safe
  checkNoMVarNoFVar value.value
  checkLevelParams value.value value.base.levelParams
  let ctx := mkChecker env value.base.levelParams .safe
  let valueType ← check ctx value.value
  unless ← isDefEq ctx valueType value.base.type do
    throw "opaque value type mismatch"
  env.add (.opaqueInfo value)

def addMutualDefinitions
    (env : Environment)
    (values : List DefinitionInfo) : Except String Environment := do
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
        checkConstantBase env value.base first.safety
        checkHeaders (value.base.name :: seen) rest
  checkHeaders [] values

  let work := values.foldl (fun current value => current.addUnchecked (.defnInfo value)) env
  let rec checkBodies : List DefinitionInfo → Except String Unit
    | [] => pure ()
    | value :: rest => do
        checkDefinitionBody work value first.safety
        checkBodies rest
  checkBodies values
  pure work

end Kernel

end PSC1Kernel
