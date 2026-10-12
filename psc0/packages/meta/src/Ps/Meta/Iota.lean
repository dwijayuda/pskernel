import Ps.Environment.Basic
import Ps.Core.Builtin
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
  let inductive ← psEnvironmentFindInductive environment typeName
  if !inductive.isStructure || inductive.constructors.length != 1 then none else do
    let applied := psReduceConstructorView (reduce major)
    let .constE ctorName ctorLevels := applied.head | none
    let constructor ← psEnvironmentFindConstructor environment ctorName
    if !psNameEq constructor.inductiveName typeName ||
        !inductive.constructors.any (psNameEq ctorName) ||
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

-- Metadata-driven iota for a single family and direct recursive fields.
-- Unsupported nested/mutual recursors remain stuck; reduction never guesses.
def psReduceIota (reduce : PsExpr -> PsExpr) (environment : PsEnvironment)
    (expr : PsExpr) : Option PsExpr := do
  let view := psReduceAppView expr
  let .constE name levels := view.head | none
  let recursor ← psEnvironmentFindRecursor environment name
  if recursor.numMotives != 1 || recursor.inductiveNames.length != 1 then none else do
    let majorPosition := recursor.numParams + 1 + recursor.numMinors + recursor.numIndices
    let major ← view.args[majorPosition]?
    let constructor := psReduceConstructorView (reduce major)
    let .constE ctorName ctorLevels := constructor.head | none
    let ctor ← psEnvironmentFindConstructor environment ctorName
    if !(recursor.inductiveNames.any (psNameEq ctor.inductiveName)) ||
        ctor.numParams != recursor.numParams ||
        constructor.args.length != ctor.numParams + ctor.numFields ||
        levels.length != recursor.levelParams.length ||
        ctorLevels.length != ctor.levelParams.length then none else do
      let minor ← view.args[recursor.numParams + 1 + ctor.constructorIndex]?
      let fields := constructor.args.drop ctor.numParams
      let hypotheses ← ctor.recursiveFields.mapM fun index => do
        let field ← fields[index]?
        let fieldCursor ← psReduceApplyType reduce
          (psExprInstantiateLevelParams ctor.levelParams ctorLevels ctor.type)
          (constructor.args.take (ctor.numParams + index))
        let .forallE _ domain _ _ := reduce fieldCursor | none
        let fieldType := psReduceAppView (reduce domain)
        let .constE family _ := fieldType.head | none
        if !psNameEq family ctor.inductiveName ||
            fieldType.args.length != recursor.numParams + recursor.numIndices then none else
          return psReduceApply view.head
            (view.args.take (recursor.numParams + 1 + recursor.numMinors) ++
              fieldType.args.drop recursor.numParams ++ [field])
      return psReduceApply minor (fields ++ hypotheses ++ view.args.drop (majorPosition + 1))
