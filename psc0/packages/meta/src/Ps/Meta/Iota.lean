import Ps.Environment.Basic
import Ps.Core.Builtin
import Ps.Core.InductiveGroup
import Ps.Core.Subst
import Ps.Core.LevelSubst
import Ps.Meta.Context

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

def psReduceEliminationEqual (reduce : PsExpr → PsExpr) (left right : PsExpr) : Bool :=
  match reduce left, reduce right with
  | .constE leftName leftLevels, .constE rightName rightLevels =>
    psNameEq leftName rightName && leftLevels.length == rightLevels.length &&
      (leftLevels.zip rightLevels).all (fun pair => psLevelEquivalent pair.1 pair.2)
  | left, right => psExprAlphaEq left right

def psReduceEliminationHypothesis (reduce : PsExpr → PsExpr) (fuel : Nat)
    (plan : PsInductiveEliminationPlan) (target : Nat)
    (recursorLevels familyLevels : List PsLevel) (fixedArgs : List PsExpr)
    (domain field : PsExpr) : Option PsExpr := do
  match fuel with
  | 0 => none
  | fuel + 1 =>
    match reduce domain with
    | .forallE name parameter body binder =>
      let lift := psExprLiftBVars 1 0
      let hypothesis ← psReduceEliminationHypothesis reduce fuel plan target
        recursorLevels familyLevels (fixedArgs.map lift) body (.app (lift field) (.bvar 0))
      return .lam name parameter hypothesis binder
    | result =>
      let slot ← plan.slots[target]?
      let indices ← psInductiveEliminationIndicesAt (psReduceEliminationEqual reduce)
        plan slot familyLevels (fixedArgs.take plan.parameters.length) result
      return psReduceApply (.constE slot.recursorName recursorLevels) (fixedArgs ++ indices ++ [field])

-- Kernel K reduction is available exactly for a singleton inductive
-- predicate with one fieldless constructor (pinned inductive.cpp/init_K_target).
-- The registered recursor application supplies the expected major type, as
-- ordinary iota already assumes a typed application. Reconstruct the unique
-- constructor only when its actual instantiated result indices agree without
-- assigning metavariables. No proof body or arbitrary runtime value is erased.
def psReduceKConversion (reduce : PsExpr → PsExpr) (fuel : Nat)
    (left right : PsExpr) : Bool :=
  if psExprAlphaEq left right then true else
  match fuel with
  | 0 => false
  | fuel + 1 =>
    let left := reduce left
    let right := reduce right
    if psExprAlphaEq left right then true else
    let same := psReduceKConversion reduce fuel
    match left, right with
    | .sortE left, .sortE right => psLevelEquivalent left right
    | .constE leftName leftLevels, .constE rightName rightLevels =>
      psNameEq leftName rightName && leftLevels.length == rightLevels.length &&
        (leftLevels.zip rightLevels).all (fun pair => psLevelEquivalent pair.1 pair.2)
    | .app leftFn leftArg, .app rightFn rightArg =>
      same leftFn rightFn && same leftArg rightArg
    | .lam _ leftDomain leftBody leftBinder, .lam _ rightDomain rightBody rightBinder
    | .forallE _ leftDomain leftBody leftBinder, .forallE _ rightDomain rightBody rightBinder =>
      psBinderInfoEq leftBinder rightBinder && same leftDomain rightDomain && same leftBody rightBody
    | .proj leftName leftIndex leftValue, .proj rightName rightIndex rightValue =>
      psNameEq leftName rightName && leftIndex == rightIndex && same leftValue rightValue
    | _, _ => false

def psReduceKConstructor (reduce : PsExpr → PsExpr)
    (plan : PsInductiveEliminationPlan) (slot : PsInductiveEliminationSlot)
    (familyLevels : List PsLevel) (parameters indices : List PsExpr) :
    Option PsReduceAppView := do
  if plan.group.members.length != 1 || plan.slots.length != 1 ||
      !slot.publicMember || parameters.length != slot.family.numParams ||
      indices.length != slot.family.numIndices ||
      indices.any psExprHasUnresolvedMeta then none else do
    let [selected] := slot.constructors | none
    let ctor := selected.info
    if ctor.numFields != 0 || !ctor.recursiveFields.isEmpty ||
        ctor.numParams != slot.family.numParams then none else do
      let familyType := psExprInstantiateLevelParams slot.family.levelParams
        familyLevels slot.family.type
      let resultSort ← psReduceApplyType reduce familyType (parameters ++ indices)
      let .sortE level := reduce resultSort | none
      if !psLevelEquivalent level .zero then none else do
        let constructor ← psInductiveEliminationInstantiate plan familyLevels
          parameters selected.head
        let view := psReduceAppView constructor
        let .constE name levels := view.head | none
        if !psNameEq name ctor.name || levels.length != ctor.levelParams.length ||
            view.args.length != ctor.numParams then none else do
          let constructorType ← psReduceApplyType reduce
            (psExprInstantiateLevelParams ctor.levelParams levels ctor.type) view.args
          let actual := psReduceAppView (reduce constructorType)
          let expected := psReduceAppView
            (psReduceApply (.constE slot.family.name familyLevels) (parameters ++ indices))
          if !psReduceEliminationEqual reduce actual.head expected.head ||
              actual.args.length != expected.args.length ||
              !(actual.args.zip expected.args).all
                (fun (left, right) => psReduceKConversion reduce 256 left right) then none
          else some view

-- One reduction owner handles direct and nested slots. Slot identity comes
-- from the called registered recursor; a base constructor name alone cannot
-- select between different specializations of List/Option/Array/Prod.
def psReduceIota (reduce : PsExpr -> PsExpr) (environment : PsEnvironment)
    (expr : PsExpr) : Option PsExpr := do
  let view := psReduceAppView expr
  let .constE name levels := view.head | none
  let recursor ← psEnvironmentFindRecursor environment name
  let owner ← recursor.inductiveNames.head?
  let family ← psEnvironmentFindInductive environment owner
  let plan ← psInductiveEliminationPlanFor reduce
    (psEnvironmentFindInductive environment) (psEnvironmentFindConstructor environment)
    (psEnvironmentFindRecursor environment) family
  let (slotIndex, slot) ← psInductiveEliminationSlotFor plan name
  let familyLevels ← psInductiveEliminationFamilyLevels plan recursor levels
  if !psInductiveEliminationRecursorShapeValid plan slot recursor then none else do
    let prefixSize := recursor.numParams + recursor.numMotives + recursor.numMinors
    let majorPosition := prefixSize + slot.family.numIndices
    let major ← view.args[majorPosition]?
    -- Try the generic proof-irrelevant constructor before unfolding a proof.
    -- Native kernel/inductive.h uses the same order; opaque equality proofs
    -- must not obstruct computation when their endpoints already agree.
    let constructor ← match psReduceKConstructor reduce plan slot familyLevels
        (view.args.take recursor.numParams)
        ((view.args.drop prefixSize).take slot.family.numIndices) with
      | some constructor => pure constructor
      | none => pure (psReduceConstructorView (reduce major))
    let .constE ctorName ctorLevels := constructor.head | none
    let ctor ← psEnvironmentFindConstructor environment ctorName
    let selected ← slot.constructors[ctor.constructorIndex]?
    let expectedHead ← psInductiveEliminationInstantiate plan familyLevels
      (view.args.take recursor.numParams) selected.head
    let expected := psReduceAppView expectedHead
    if !psNameEq ctor.inductiveName slot.family.name || !psNameEq selected.info.name ctorName ||
        !psConstructorRecursiveFieldsOrdered ctor ||
        constructor.args.length != ctor.numParams + ctor.numFields ||
        ctorLevels.length != ctor.levelParams.length ||
        expected.args.length != ctor.numParams ||
        !psReduceEliminationEqual reduce constructor.head expected.head ||
        !(constructor.args.take ctor.numParams |>.zip expected.args).all
          (fun pair => psReduceEliminationEqual reduce pair.1 pair.2) then none else do
      let offset ← psInductiveEliminationMinorOffset plan slotIndex
      let minor ← view.args[recursor.numParams + recursor.numMotives + offset + ctor.constructorIndex]?
      let fields := constructor.args.drop ctor.numParams
      let hypotheses ← selected.recursiveFields.mapM fun (index, target) => do
        let field ← fields[index]?
        let fieldCursor ← psReduceApplyType reduce
          (psExprInstantiateLevelParams ctor.levelParams ctorLevels ctor.type)
          (constructor.args.take (ctor.numParams + index))
        let .forallE _ domain _ _ := reduce fieldCursor | none
        psReduceEliminationHypothesis reduce 4096 plan target levels familyLevels
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

