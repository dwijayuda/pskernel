import Ps.KernelCore.Checker.Session

/-
Core declaration validation shared by all admission operations.

This module checks universe-parameter discipline, rejects metavariables/free
variables, validates declaration headers as sorts, and checks definition bodies
against their declared types. It does not mutate the global environment.
-/


def psKernelSafetyEq
    (left : PsKernelDefinitionSafety)
    (right : PsKernelDefinitionSafety) : Bool :=
  match left with
  | PsKernelDefinitionSafety.unsafeDef =>
      match right with
      | PsKernelDefinitionSafety.unsafeDef => true
      | _ => false
  | PsKernelDefinitionSafety.safe =>
      match right with
      | PsKernelDefinitionSafety.safe => true
      | _ => false
  | PsKernelDefinitionSafety.partialDef =>
      match right with
      | PsKernelDefinitionSafety.partialDef => true
      | _ => false

def psKernelNameListsEq
    (left : List PsKernelName) :
    List PsKernelName -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsKernelName) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller :=
        psKernelNameListsEq leftTail;
      fun (right : List PsKernelName) =>
        match right with
        | List.nil =>
            false
        | List.cons rightHead rightTail =>
            if psKernelNameEq leftHead rightHead then
              smaller rightTail
            else
              false

def psKernelFindUndefExprLevelParam
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) :
    Option PsKernelName :=
  match expr with
  | PsKernelExpr.sort level =>
      psKernelFindUndefLevelParam
        level
        allowed
  | PsKernelExpr.const _ levels =>
      psKernelFindUndefInLevels
        levels
        allowed
  | PsKernelExpr.app fn arg =>
      match
          psKernelFindUndefExprLevelParam
            fn
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            arg
            allowed
  | PsKernelExpr.lam _ type body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            body
            allowed
  | PsKernelExpr.forallE _ type body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            body
            allowed
  | PsKernelExpr.letE _ type value body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          match
              psKernelFindUndefExprLevelParam
                value
                allowed with
          | Option.some name =>
              Option.some name
          | Option.none =>
              psKernelFindUndefExprLevelParam
                body
                allowed
  | PsKernelExpr.mdata _ body =>
      psKernelFindUndefExprLevelParam
        body
        allowed
  | PsKernelExpr.proj _ _ body =>
      psKernelFindUndefExprLevelParam
        body
        allowed
  | _ =>
      Option.none

def psKernelExprHasMVar
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.mvar _ =>
      true
  | PsKernelExpr.sort level =>
      psKernelLevelHasMVar level
  | PsKernelExpr.const _ levels =>
      psKernelLevelsHaveMVar levels
  | PsKernelExpr.app fn arg =>
      if psKernelExprHasMVar fn then
        true
      else
        psKernelExprHasMVar arg
  | PsKernelExpr.lam _ type body _ =>
      if psKernelExprHasMVar type then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelExprHasMVar type then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelExprHasMVar type then
        true
      else if psKernelExprHasMVar value then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasMVar body
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasMVar body
  | _ =>
      false

/-- The native node's MVar presence is **exactly** the original
recursive syntactic predicate on every possible expression, including
universe MVars on sorts and constants. This is a theorem about the pure
computed-field definition, not an assertion about unvalidated metadata,
pointer identity or the Lean native compiler's runtime correctness. -/
theorem psKernelC0MVarFlag_source (expr : PsKernelExpr) :
    expr.psKernelC0MVarFlag = psKernelExprHasMVar expr := by
  induction expr <;>
    simp [PsKernelExpr.psKernelC0MVarFlag, psKernelExprHasMVar, *]

def psKernelCheckNoMVarNoFVar
    (expr : PsKernelExpr) :
    Except String Unit :=
  -- Source-certified constant-time node metadata eliminates an exponential
  -- syntax traversal on shared closed declaration DAGs. The original
  -- MVar-before-FVar error precedence and pure source predicate remain.
  if expr.psKernelC0MVarFlag then
    Except.error
      "declaration has metavariables"
  else if psKernelExprHasFVar expr then
    Except.error
      "declaration has free variables"
  else
    Except.ok ()

/-- Exact old declaration preflight, including original MVar-before-FVar
error precedence. Only the syntactic MVar predicate implementation differs.
No new allowed axiom, proof admission or cache result is introduced. -/
theorem psKernelC0NodeFlagAdmission_source (expr : PsKernelExpr) :
    psKernelCheckNoMVarNoFVar expr =
      (if psKernelExprHasMVar expr then
         (Except.error "declaration has metavariables" : Except String Unit)
       else if psKernelExprHasFVar expr then
         Except.error "declaration has free variables"
       else Except.ok ()) := by
  simp only [psKernelCheckNoMVarNoFVar, psKernelC0MVarFlag_source]


/-- Original recursive syntactic oracle; deliberately independent of the
    native computed-field getter. -/
def psKernelExprHasLevelParam (expr : PsKernelExpr) : Bool :=
  match expr with
  | .sort level => psKernelLevelHasParam level
  | .const _ levels => psKernelLevelsHaveParam levels
  | .app fn arg => psKernelExprHasLevelParam fn || psKernelExprHasLevelParam arg
  | .lam _ ty body _ =>
      psKernelExprHasLevelParam ty || psKernelExprHasLevelParam body
  | .forallE _ ty body _ =>
      psKernelExprHasLevelParam ty || psKernelExprHasLevelParam body
  | .letE _ ty value body _ =>
      psKernelExprHasLevelParam ty ||
        psKernelExprHasLevelParam value || psKernelExprHasLevelParam body
  | .mdata _ body => psKernelExprHasLevelParam body
  | .proj _ _ body => psKernelExprHasLevelParam body
  | _ => false

/-- Pure-source equality for every expression, independent of DAG identity,
    pointer hints, hash functions, allowed levels or source resource budgets. -/
theorem psKernelC0LevelParamFlag_source (expr : PsKernelExpr) :
    expr.psKernelC0LevelParamFlag = psKernelExprHasLevelParam expr := by
  induction expr <;>
    simp [PsKernelExpr.psKernelC0LevelParamFlag, psKernelExprHasLevelParam, *]

/-- No parameter anywhere in a level implies the first-undefined-level
    search has no possible offender, for every allowed list. -/
theorem psKernelLevelNoParamUndef (level : PsKernelLevel)
    (allowed : List PsKernelName)
    (h : psKernelLevelHasParam level = false) :
    psKernelFindUndefLevelParam level allowed = none := by
  induction level <;>
    simp_all [psKernelLevelHasParam, psKernelFindUndefLevelParam]

theorem psKernelLevelsNoParamUndef (levels : List PsKernelLevel)
    (allowed : List PsKernelName)
    (h : psKernelLevelsHaveParam levels = false) :
    psKernelFindUndefInLevels levels allowed = none := by
  induction levels <;>
    simp_all [psKernelLevelsHaveParam, psKernelFindUndefInLevels,
      psKernelLevelNoParamUndef]

/-- This is the only permitted skipping criterion: absent universe parameters
    make an undefined-parameter error impossible. If one is present, the
    existing left-to-right diagnostic search still runs unchanged. -/
theorem psKernelExprNoParamUndef (expr : PsKernelExpr)
    (allowed : List PsKernelName)
    (h : psKernelExprHasLevelParam expr = false) :
    psKernelFindUndefExprLevelParam expr allowed = none := by
  induction expr <;>
    simp_all [psKernelExprHasLevelParam, psKernelFindUndefExprLevelParam,
      psKernelLevelNoParamUndef, psKernelLevelsNoParamUndef]

def psKernelC0FindUndefWithNodeFlag
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) : Option PsKernelName :=
  if expr.psKernelC0LevelParamFlag then
    psKernelFindUndefExprLevelParam expr allowed
  else
    none

theorem psKernelC0FindUndefWithNodeFlag_source
    (expr : PsKernelExpr) (allowed : List PsKernelName) :
    psKernelC0FindUndefWithNodeFlag expr allowed =
      psKernelFindUndefExprLevelParam expr allowed := by
  unfold psKernelC0FindUndefWithNodeFlag
  by_cases h : expr.psKernelC0LevelParamFlag = true
  · simp [h]
  · have hf : expr.psKernelC0LevelParamFlag = false := by
      cases hv : expr.psKernelC0LevelParamFlag <;> simp_all
    have hn : psKernelExprHasLevelParam expr = false := by
      simpa [psKernelC0LevelParamFlag_source] using hf
    simp [hf, psKernelExprNoParamUndef expr allowed hn]

def psKernelCheckLevelParams
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) :
    Except String Unit :=
  match
      psKernelFindUndefExprLevelParam
        expr
        allowed with
  | Option.some _ =>
      Except.error
        "invalid reference to undefined universe level parameter"
  | Option.none =>
      Except.ok ()

def psKernelCheckConstantBaseWithSession
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (base : PsKernelConstantBase) :
    Except String PsKernelCheckerSession :=
  if
      psKernelEnvironmentContains
        session.context.environment
        base.name then
    Except.error "already declared"
  else if
      psKernelNameHasDuplicates
        base.levelParams then
    Except.error
      "duplicate universe parameter"
  else
    match psKernelCheckNoMVarNoFVar base.type with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        match
            psKernelCheckLevelParams
              base.type
              base.levelParams with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            match
                psKernelSessionCheck
                  fuel
                  session
                  base.type with
            | Except.error error =>
                Except.error error
            | Except.ok typeType =>
                match
                    psKernelSessionEnsureSort
                      fuel
                      (Prod.snd typeType)
                      (Prod.fst typeType) with
                | Except.error error =>
                    Except.error error
                | Except.ok result =>
                    Except.ok
                      (Prod.snd result)

def psKernelCheckDefinitionBodyWithSession
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo) :
    Except String PsKernelCheckerSession :=
  match psKernelCheckNoMVarNoFVar value.value with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psKernelCheckLevelParams
            value.value
            value.base.levelParams with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match
              psKernelSessionCheck
                fuel
                session
                value.value with
          | Except.error error =>
              Except.error error
          | Except.ok valueType =>
              match
                  psKernelSessionIsDefEq
                    fuel
                    (Prod.snd valueType)
                    (Prod.fst valueType)
                    value.base.type with
              | Except.error error =>
                  Except.error error
              | Except.ok equal =>
                  if Prod.fst equal then
                    Except.ok
                      (Prod.snd equal)
                  else
                    Except.error
                      "definition type mismatch"
