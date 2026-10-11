import Ps.Meta.Infer

-- Family classification opens its telescope without assuming parameters are
-- runtime types. Proof families and indexed families use the same operation.
def psInductiveResultLevelWithFuel (environment : PsEnvironment) (meta : PsMetaContext)
    (fuel : Nat) (locals : PsLocalContext) (type : PsExpr) : Except PsInferError PsLevel := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match psWhnf environment meta locals type with
    | .sortE level => return psLevelNormalize level
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding locals name domain binder
      psInductiveResultLevelWithFuel environment meta fuel pushed.context
        (psExprInstantiate1 body (.fvar pushed.id))
    | _ => throw .expectedSort

def psInductiveResultLevel (environment : PsEnvironment) (info : PsInductiveInfo) :
    Except PsInferError PsLevel :=
  psInductiveResultLevelWithFuel environment psMetaEmpty 4096 psLocalEmpty info.type

def psInductiveIsProp (environment : PsEnvironment) (info : PsInductiveInfo) :
    Except PsInferError Bool := do
  return psLevelEquivalent (← psInductiveResultLevel environment info) .zero

-- Pinned kernel singleton elimination: every nonparameter field must be a
-- proof, or occur as an entire argument of the constructor's return family.
-- Merely occurring inside an index expression is insufficient.
def psInductiveSingletonFields (environment : PsEnvironment) (fuel parameters : Nat)
    (locals : PsLocalContext) (type : PsExpr) (exposed : List PsExpr) :
    Except PsInferError Bool := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match psWhnf environment psMetaEmpty locals type with
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding locals name domain binder
      let value := PsExpr.fvar pushed.id
      let exposed ← if parameters != 0 then pure exposed else do
        let sort ← psInferType environment psMetaEmpty locals domain
        let level ← psInferEnsureSort environment psMetaEmpty locals sort
        pure (if psLevelEquivalent level .zero then exposed else value :: exposed)
      psInductiveSingletonFields environment fuel (parameters - 1) pushed.context
        (psExprInstantiate1 body value) exposed
    | result =>
      let arguments := (psReduceAppView result).args
      return exposed.all fun value => arguments.any (psExprAlphaEq value)

def psInductiveLargeElimination (environment : PsEnvironment) (info : PsInductiveInfo) :
    Except PsInferError Bool := do
  if psLevelAlwaysPositive (← psInductiveResultLevel environment info) then return true
  match info.constructors with
  | [] => return true
  | [name] =>
    let some constructor := psEnvironmentFindConstructor environment name
      | throw (.unknownConstant name)
    psInductiveSingletonFields environment 4096 info.numParams psLocalEmpty constructor.type []
  | _ => return false
