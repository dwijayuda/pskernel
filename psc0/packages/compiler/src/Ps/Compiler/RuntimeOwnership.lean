import Ps.Compiler.RecursorLift

-- Shared ownership checks for logical-only auxiliaries and their prepared workers.
def psCompilerRuntimeLevelsEq (left right : List PsName) : Bool :=
  left.length == right.length &&
    (left.zip right).all (fun pair => psNameEq pair.fst pair.snd)

def psCompilerRuntimeClosed (expression : PsExpr) : Bool :=
  !psExprHasUnresolvedMeta expression && psExprFVarsInContext psLocalEmpty expression

def psCompilerRuntimeUnique (declarations : List PsDeclaration)
    (name : PsName) : Option PsDeclaration :=
  match declarations.filter (fun declaration => psNameEq (psDeclarationName declaration) name) with
  | [declaration] => some declaration
  | _ => none

def psCompilerRuntimeHelperOwned (auxiliary name : PsName) : Bool :=
  match name with
  | .num (.str owner "_rec") _ => psNameEq owner auxiliary
  | _ => false

-- Recursor preparation closes helpers and independently checks exact beta
-- restoration. Undo only those auxiliary-owned helper definitions, plus
-- beta/zeta; never unfold a public definition or a logical fixedpoint during this check.
def psCompilerRuntimeRestore (fuel : Nat)
    (declarations : List PsDeclaration) (auxiliary : PsName) (expression : PsExpr) :
    Except String PsExpr := do
  match fuel with
  | 0 => throw "restoration budget exhausted"
  | fuel + 1 =>
    match expression with
    | .constE name arguments =>
      if !psCompilerRuntimeHelperOwned auxiliary name then return expression
      let some (.definitionDecl _ parameters type value) :=
          psCompilerRuntimeUnique declarations name
        | throw "missing unique auxiliary recursor helper"
      if parameters.length != arguments.length ||
          !psCompilerRuntimeClosed type || !psCompilerRuntimeClosed value then
        throw "auxiliary recursor helper is not closed at its declared universes"
      psCompilerRuntimeRestore fuel declarations auxiliary
        (psExprInstantiateLevelParams parameters arguments value)
    | .app fn argument =>
      let fn ← psCompilerRuntimeRestore fuel declarations auxiliary fn
      let argument ← psCompilerRuntimeRestore fuel declarations auxiliary argument
      match fn with
      | .lam _ _ body _ =>
        psCompilerRuntimeRestore fuel declarations auxiliary (psExprInstantiate1 body argument)
      | _ => return .app fn argument
    | .letE _ _ value body =>
      let value ← psCompilerRuntimeRestore fuel declarations auxiliary value
      psCompilerRuntimeRestore fuel declarations auxiliary (psExprInstantiate1 body value)
    | .lam name type body binder =>
      return .lam name
        (← psCompilerRuntimeRestore fuel declarations auxiliary type)
        (← psCompilerRuntimeRestore fuel declarations auxiliary body) binder
    | .forallE name type body binder =>
      return .forallE name
        (← psCompilerRuntimeRestore fuel declarations auxiliary type)
        (← psCompilerRuntimeRestore fuel declarations auxiliary body) binder
    | .proj typeName index value =>
      return .proj typeName index
        (← psCompilerRuntimeRestore fuel declarations auxiliary value)
    | _ => return expression

def psCompilerRuntimeWorkerGroups
    (groups : List PsRecursorWorkerGroup) (auxiliaries : List PsName) :
    Except String (List PsRecursorWorkerGroup) := do
  let mut retained : List PsRecursorWorkerGroup := []
  for group in groups do
    let allOwned := !group.workers.isEmpty && auxiliaries.any (fun auxiliary =>
      group.workers.all (fun worker => psCompilerRuntimeHelperOwned auxiliary worker.name))
    let anyOwned := group.workers.any (fun worker => auxiliaries.any (fun auxiliary =>
      psCompilerRuntimeHelperOwned auxiliary worker.name))
    if allOwned then pure ()
    else if anyOwned then
      throw "logical auxiliary owns only part of a worker group"
    else retained := retained ++ [group]
  return retained
