import Ps.Environment.Basic
import Ps.Core.Builtin
import Ps.Core.InductiveGroup
import Ps.Core.Subst
import Ps.Core.LevelSubst

structure PsReduceAppView where
  head : PsExpr
  args : List PsExpr

def psReduceAppView (expr : PsExpr) (args : List PsExpr := []) : PsReduceAppView :=
  match expr with
  | .app fn value => psReduceAppView fn (value :: args)
  | _ => { head := expr, args }

def psReduceApply (head : PsExpr) (args : List PsExpr) : PsExpr :=
  args.foldl PsExpr.app head

-- Expose one Nat constructor at a time, without expanding a large literal.
def psReduceConstructorView (value : PsExpr) : PsReduceAppView :=
  match value with
  | .lit (.natural 0) => { head := .constE psNatZeroName [], args := [] }
  | .lit (.natural (n + 1)) =>
    { head := .constE psNatSuccName [], args := [.lit (.natural n)] }
  | _ => psReduceAppView value

-- Definitional iota for constructor-headed structure projections.
-- Validate the family's single constructor and saturated field telescope.
def psReduceProjectionIota (reduce : PsExpr → PsExpr)
    (environment : PsEnvironment) (typeName : PsName) (fieldIndex : Nat)
    (major : PsExpr) : Option PsExpr := do
  let inductiveInfo ← psEnvironmentFindInductive environment typeName
  if !inductiveInfo.isStructure || inductiveInfo.constructors.length != 1 then none else do
    let applied := psReduceConstructorView (reduce major)
    let .constE ctorName ctorLevels := applied.head | none
    let constructor ← psEnvironmentFindConstructor environment ctorName
    if !psNameEq constructor.inductiveName typeName ||
        !inductiveInfo.constructors.any (psNameEq ctorName) ||
        constructor.constructorIndex != 0 ||
        ctorLevels.length != constructor.levelParams.length ||
        applied.args.length != constructor.numParams + constructor.numFields ||
        fieldIndex >= constructor.numFields then none
    else applied.args[constructor.numParams + fieldIndex]?

def psReduceApplyType (reduce : PsExpr -> PsExpr) (type : PsExpr)
    (arguments : List PsExpr) : Option PsExpr := do
  match arguments with
  | [] => return type
  | value :: rest =>
    let .forallE _ _ body _ := reduce type | none
    psReduceApplyType reduce (psExprInstantiate1 body value) rest

-- Lean kernel/inductive.cpp mk_rec_rules: a recursive field may be a
-- dependent function returning any member of the group. Its induction
-- hypothesis abstracts the same telescope and calls that member's recursor
-- with its own indices and the shared parameters, motives and minors.
-- Bound variables are lifted when entering each lambda; no fresh free variable
-- can escape the caller's checked context.
def psReduceRecursorHypothesis (reduce : PsExpr → PsExpr) (fuel : Nat)
    (plan : PsInductiveGroupPlan) (levels : List PsLevel)
    (fixedArgs : List PsExpr) (domain field : PsExpr) : Option PsExpr := do
  match fuel with
  | 0 => none
  | fuel + 1 =>
    match reduce domain with
    | .forallE name parameter body binder =>
      let lift := psExprLiftBVars 1 0
      let hypothesis ← psReduceRecursorHypothesis reduce fuel plan levels
        (fixedArgs.map lift) body (.app (lift field) (.bvar 0))
      return .lam name parameter hypothesis binder
    | result =>
      let fieldType := psReduceAppView result
      let .constE owner fieldLevels := fieldType.head | none
      let family ← psInductiveGroupFind plan owner
      if fieldLevels.length != family.levelParams.length ||
          fieldType.args.length != family.numParams + family.numIndices then none
      else
        return psReduceApply (.constE (psNameAppendStr family.name "rec") levels)
          (fixedArgs ++ fieldType.args.drop family.numParams ++ [field])

-- Metadata-driven iota for a complete registered group, including singleton
-- and function-valued recursive fields. This is checked Core conversion;
-- multi-motive source match/runtime lowering require their own consumers.
def psReduceIota (reduce : PsExpr -> PsExpr) (environment : PsEnvironment)
    (expr : PsExpr) : Option PsExpr := do
  let view := psReduceAppView expr
  let .constE name levels := view.head | none
  let recursor ← psEnvironmentFindRecursor environment name
  let owner ← recursor.inductiveNames.find?
    (fun family => psNameEq name (psNameAppendStr family "rec"))
  let family ← psEnvironmentFindInductive environment owner
  let plan ← psInductiveGroupPlanFor
    (psEnvironmentFindInductive environment) (psEnvironmentFindRecursor environment) family
  if !psInductiveGroupRecursorShapeValid plan family recursor ||
      levels.length != recursor.levelParams.length then none else do
    let prefixSize := recursor.numParams + recursor.numMotives + recursor.numMinors
    let majorPosition := prefixSize + family.numIndices
    let major ← view.args[majorPosition]?
    let constructor := psReduceConstructorView (reduce major)
    let .constE ctorName ctorLevels := constructor.head | none
    let ctor ← psEnvironmentFindConstructor environment ctorName
    let orderedName ← family.constructors[ctor.constructorIndex]?
    if !psNameEq ctor.inductiveName family.name || !psNameEq orderedName ctorName ||
        ctor.numParams != recursor.numParams ||
        constructor.args.length != ctor.numParams + ctor.numFields ||
        ctorLevels.length != ctor.levelParams.length then none else do
      let offset ← psInductiveGroupMinorOffset plan family.name
      let minor ← view.args[recursor.numParams + recursor.numMotives + offset + ctor.constructorIndex]?
      let fields := constructor.args.drop ctor.numParams
      let hypotheses ← ctor.recursiveFields.mapM fun index => do
        let field ← fields[index]?
        let fieldCursor ← psReduceApplyType reduce
          (psExprInstantiateLevelParams ctor.levelParams ctorLevels ctor.type)
          (constructor.args.take (ctor.numParams + index))
        let .forallE _ domain _ _ := reduce fieldCursor | none
        psReduceRecursorHypothesis reduce 4096 plan levels
          (view.args.take prefixSize) domain field
      return psReduceApply minor (fields ++ hypotheses ++ view.args.drop (majorPosition + 1))


-- Lean Meta/WHNF.lean reduceQuotRec. Dispatch requires registered kernel
-- quotient metadata; a familiar spelling alone never grants reduction.
def psReduceQuotientIota (reduce : PsExpr → PsExpr) (environment : PsEnvironment)
    (expr : PsExpr) : Option PsExpr := do
  let view := psReduceAppView expr
  let .constE name levels := view.head | none
  let some (.quotientDecl _ parameters _ kind) := psEnvironmentFind environment name | none
  if levels.length != parameters.length then none else do
    let majorPosition ← match kind with | .lift => some 5 | .ind => some 4 | _ => none
    let major ← view.args[majorPosition]?
    let constructor := psReduceAppView (reduce major)
    let .constE ctorName ctorLevels := constructor.head | none
    let some (.quotientDecl _ ctorParameters _ .ctor) := psEnvironmentFind environment ctorName | none
    if ctorLevels.length != ctorParameters.length || constructor.args.length != 3 then none else do
      let field ← constructor.args[2]?
      let minor ← view.args[3]?
      return psReduceApply (.app minor field) (view.args.drop (majorPosition + 1))

