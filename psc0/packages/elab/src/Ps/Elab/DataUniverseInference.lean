/-
Result-universe inference follows Lean 4.35.0
Lean/Elab/MutualInductive.lean, LevelInference, pinned at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright (c) Microsoft Corporation. Apache-2.0.
Constructor fields are inspected after fixed-index promotion. Result assignments
remain in the ordinary shared level context and are instantiated before admission.
-/
import Ps.Elab.Term
import Ps.Core.InductiveGroup

def psElabDataLevelIds : PsLevel → List Nat
  | .mvar id => [id]
  | .succ value => psElabDataLevelIds value
  | .max a b | .imax a b => psElabDataLevelIds a ++ psElabDataLevelIds b
  | _ => []

def psElabDataLevelBase : PsLevel → PsLevel × Nat
  | .succ value =>
    let (base, offset) := psElabDataLevelBase value
    (base, offset + 1)
  | value => (value, 0)

def psElabDataLevelAtoms (paramConst : Bool)
    (atoms : List (PsLevel × Nat)) : List (PsLevel × Nat) :=
  let merged := atoms.foldl (fun result (level, offset) =>
    match result.find? (fun entry => psLevelStructuralEq entry.fst level) with
    | none => result ++ [(level, offset)]
    | some entry => result.map fun old =>
      if psLevelStructuralEq old.fst level then (level, max entry.snd offset) else old) []
  let varies := fun level =>
    psLevelHasMVar level || (!paramConst && !(psElabLevelParams level).isEmpty)
  if merged.any (fun entry => varies entry.fst) then
    merged.filter (fun entry => varies entry.fst)
  else merged

def psElabDataLevelAtomsMax (atoms : List (PsLevel × Nat)) : PsLevel :=
  atoms.foldl (fun result (level, offset) =>
    psLevelMax result (psElabLevelOffset level offset)) .zero

-- The native representative agrees at infinity. It isolates the one result
-- metavariable without turning an arbitrary max/imax equation into an assignment.
def psElabDataLevelGerm (fuel : Nat) (paramConst : Bool)
    (level : PsLevel) (offset : Nat := 0) :
    Except PsElabError (List (PsLevel × Nat)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match psLevelNormalize level with
    | .succ value => psElabDataLevelGerm fuel paramConst value (offset + 1)
    | .max a b =>
      let left ← psElabDataLevelGerm fuel paramConst a offset
      let right ← psElabDataLevelGerm fuel paramConst b offset
      return psElabDataLevelAtoms paramConst (left ++ right)
    | .imax a b =>
      let left ← psElabDataLevelGerm fuel paramConst a
      let right ← psElabDataLevelGerm fuel paramConst b
      let joined := psElabDataLevelAtoms paramConst (left ++ right)
      let covered := joined.all fun entry => right.any fun bound =>
        psLevelStructuralEq entry.fst bound.fst && entry.snd <= bound.snd
      if covered then return right.map fun entry => (entry.fst, entry.snd + offset)
      return [(.imax (psElabDataLevelAtomsMax left) (psElabDataLevelAtomsMax right), offset)]
    | level => return [(level, offset)]

-- Pinned Level.geq, with explicit resource propagation. In particular,
-- imax a b is bounded by a common upper bound of a and b.
def psElabDataLevelGeq (fuel : Nat) (upper lower : PsLevel) :
    Except PsElabError Bool := do
  if psLevelStructuralEq upper lower then return true
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let tail := fun (_ : Unit) => do
      match lower with
      | .imax a b =>
        if !(← psElabDataLevelGeq fuel upper a) then return false
        psElabDataLevelGeq fuel upper b
      | _ =>
        let (a, m) := psElabDataLevelBase upper
        let (b, n) := psElabDataLevelBase lower
        return (psLevelStructuralEq a b || psLevelStructuralEq b .zero) && m >= n
    match upper, lower with
    | _, .zero => return true
    | _, .max a b =>
      if !(← psElabDataLevelGeq fuel upper a) then return false
      psElabDataLevelGeq fuel upper b
    | .max a b, _ =>
      if ← psElabDataLevelGeq fuel a lower then return true
      if ← psElabDataLevelGeq fuel b lower then return true
      tail ()
    | .imax _ b, _ => psElabDataLevelGeq fuel b lower
    | .succ a, .succ b => psElabDataLevelGeq fuel a b
    | _, _ => tail ()

def psElabDataLevelReplace (id : Nat) (value : PsLevel) : PsLevel → PsLevel
  | .mvar other => if other == id then value else .mvar other
  | .succ level => .succ (psElabDataLevelReplace id value level)
  | .max a b => .max (psElabDataLevelReplace id value a) (psElabDataLevelReplace id value b)
  | .imax a b => .imax (psElabDataLevelReplace id value a) (psElabDataLevelReplace id value b)
  | level => level

def psElabDataUniverseConstraint (constraints : List (PsLevel × Int))
    (level : PsLevel) (offset : Int) : List (PsLevel × Int) :=
  match constraints.find? (fun entry => psLevelStructuralEq entry.fst level) with
  | none => constraints ++ [(level, offset)]
  | some entry => constraints.map fun old =>
    if psLevelStructuralEq old.fst level then (level, min entry.snd offset) else old

def psElabDataUniverseAccumulate (result : Nat) (headerIds : List Nat)
    (level : PsLevel) (offset : Int) (constraints : List (PsLevel × Int)) :
    Except PsElabError (List (PsLevel × Int)) := do
  match level with
  | .max a b | .imax a b =>
    let constraints ← psElabDataUniverseAccumulate result headerIds a offset constraints
    psElabDataUniverseAccumulate result headerIds b offset constraints
  | .succ value =>
    psElabDataUniverseAccumulate result headerIds value (offset - 1) constraints
  | .param _ => return psElabDataUniverseConstraint constraints level offset
  | .zero =>
    return if offset < 0 then psElabDataUniverseConstraint constraints .zero offset else constraints
  | .mvar id =>
    if id == result then
      if offset < 0 then throw (.data "inductive resulting universe has an inconsistent recursive bound")
      return constraints
    if headerIds.contains id then
      return psElabDataUniverseConstraint constraints level offset
    return if offset < 0 then psElabDataUniverseConstraint constraints .zero offset else constraints

structure PsElabDataUniverseField where
  level : PsLevel
  recursive : Bool

def psElabDataUniverseFields (context : PsElabContext)
    (group : PsInductiveGroupPlan) (constructors : List PsDeclaration) :
    Except PsElabError (List PsElabDataUniverseField) := do
  let fields ← constructors.mapM fun declaration => do
    let .constructorDecl constructor := declaration
      | throw (.data "constructor plan contains another declaration")
    let opened ← psElabOpenCoreTelescope 4096 context constructor.type
      (some (constructor.numParams + constructor.numFields))
    (opened.bindersRev.reverse.drop constructor.numParams).mapM fun field => do
      let level ← psElabExpressionSort opened.context field.type
      let type := psMetaInstantiate opened.context.metaContext field.type
      return {
        level
        recursive := group.members.any (fun info => psExprHasConst info.name type)
        : PsElabDataUniverseField }
  return fields.flatten

def psElabDataResultLevel (context : PsElabContext) (type : PsExpr) :
    Except PsElabError PsLevel := do
  let opened ← psElabOpenCoreTelescope 4096 context type none
  let .sortE level := psWhnf opened.context.environment opened.context.metaContext
      opened.context.localContext opened.body
    | throw (.data "data family must end in a sort")
  return psLevelNormalize (psLevelInstantiate context.metaContext.levels level)

def psElabDataAssignLevel (context : PsElabContext) (id : Nat) (level : PsLevel) :
    Except PsElabError PsElabContext := do
  let level := psLevelNormalize (psLevelInstantiate context.metaContext.levels level)
  if let some previous := psLevelFindAssignment context.metaContext.levels id then
    if !psLevelEquivalent (psLevelInstantiate context.metaContext.levels previous) level then
      throw (.data "inductive resulting universe assignment is inconsistent")
    return context
  let some levels := psLevelAssign context.metaContext.levels id level
    | throw (.data "inductive resulting universe assignment is invalid")
  return psElabContextWithMeta context { context.metaContext with levels }

structure PsElabDataUniverseResult where
  level : PsLevel
  assignment? : Option (Nat × PsLevel) := none
  highUniverse : Bool := false

def psElabDataInferResultLevel (context : PsElabContext)
    (group : PsInductiveGroupPlan) (fields : List PsElabDataUniverseField) :
    Except PsElabError (PsElabContext × PsElabDataUniverseResult) := do
  let first :: _ := group.members | throw (.data "empty inductive group")
  let level ← psElabDataResultLevel context first.type
  if !psLevelHasMVar level then return (context, { level })
  if let .mvar id := level then
    let oneConstructor := group.members.all (fun info => info.constructors.length <= 1) &&
      group.members.any (fun info => info.constructors.length == 1)
    if oneConstructor && !fields.isEmpty &&
        fields.all (fun field => !field.recursive &&
          psLevelEquivalent (psLevelInstantiate context.metaContext.levels field.level) .zero) then
      return ((← psElabDataAssignLevel context id .zero), { level := .zero })
  let ids := (psElabDataLevelIds level).eraseDups
  if ids.length != 1 then
    throw (.data "cannot infer inductive resulting universe with multiple metavariables")
  let germ ← psElabDataLevelGerm 4096 true level
  let (.mvar result, offset) := psElabDataLevelBase (psElabDataLevelAtomsMax germ)
    | throw (.data "cannot isolate inductive resulting universe metavariable")
  let headerIds := group.members.flatMap fun info =>
    (psElabExprLevels (psMetaInstantiate context.metaContext info.type)).flatMap psElabDataLevelIds
  let constraints ← fields.foldlM (fun constraints field =>
    psElabDataUniverseAccumulate result headerIds
      (psLevelNormalize (psLevelInstantiate context.metaContext.levels field.level))
      (Int.ofNat offset) constraints) []
  let constraints := if offset == 0 then
      psElabDataUniverseConstraint constraints .zero (-1)
    else constraints
  let constraints ← constraints.filterM fun (lower, adjustment) => do
    return !(← psElabDataLevelGeq 4096 level
      (psLevelNormalize (psElabLevelOffset lower (Int.ofNat offset - adjustment).toNat)))
  let inferred := psLevelNormalize (constraints.foldl (fun result (lower, adjustment) =>
    psLevelMax result (psElabLevelOffset lower (-adjustment).toNat)) .zero)
  let inferredLevel := psLevelNormalize (psElabDataLevelReplace result inferred level)
  let highUniverse ← if constraints.any (fun entry => entry.snd > 0) then do
      let atZero := psElabDataLevelReplace result .zero level
      let ideal := psLevelNormalize (constraints.foldl (fun value (lower, adjustment) =>
        psLevelMax value (psElabLevelOffset lower (Int.ofNat offset - adjustment).toNat)) atZero)
      pure (!(← psElabDataLevelGeq 4096 ideal inferredLevel))
    else pure false
  return (context, {
    level := inferredLevel
    assignment? := some (result, inferred)
    highUniverse })

def psElabDataFieldUniverseConstraints (base : PsLevel)
    (level : PsLevel) (offset : Int) (lower : Bool)
    (constraints : List (PsLevel × Int)) (positive : List Nat) :
    List (PsLevel × Int) × List Nat :=
  if !psLevelHasMVar level then (constraints, positive) else
  match level with
  | .succ value =>
    psElabDataFieldUniverseConstraints base value (offset - 1) false constraints positive
  | .max a b =>
    let (constraints, positive) :=
      psElabDataFieldUniverseConstraints base a offset lower constraints positive
    psElabDataFieldUniverseConstraints base b offset lower constraints positive
  | .imax a b =>
    let (constraints, positive) := if lower then
        psElabDataFieldUniverseConstraints base a offset lower constraints positive
      else (constraints, positive)
    psElabDataFieldUniverseConstraints base b offset lower constraints positive
  | .mvar id =>
    if psLevelStructuralEq level base then (constraints, positive) else
      (psElabDataUniverseConstraint constraints level offset,
        if lower && !positive.contains id then positive ++ [id] else positive)
  | _ => (constraints, positive)

def psElabDataPropagateFieldLevels (context : PsElabContext)
    (result : PsLevel) (fields : List PsElabDataUniverseField) :
    Except PsElabError PsElabContext := do
  if psLevelEquivalent result .zero then return context
  let germ ← psElabDataLevelGerm 4096 false result
  let (base, offset) := psElabDataLevelBase (psElabDataLevelAtomsMax germ)
  match base with
  | .param _ | .mvar _ | .zero => pure ()
  | _ => return context
  let (constraints, positive) := fields.foldl (fun (constraints, positive) field =>
    psElabDataFieldUniverseConstraints base
      (psLevelNormalize (psLevelInstantiate context.metaContext.levels field.level))
      (Int.ofNat offset) true constraints positive) ([], [])
  constraints.foldlM (fun context (level, offset) => do
    let .mvar id := level | throw (.data "constructor universe constraint is not a metavariable")
    let target : Nat := if positive.contains id then 1 else 0
    if offset != Int.ofNat target then return context
    psElabDataAssignLevel context id (psElabLevelOffset base target)) context

-- Native LevelDefEq postpones max/imax versus successor constraints while
-- the inductive result universe is still provisional. Every retained equation
-- must be ground and equal after inference; no deferred equality enters Core.
def psElabDataFinishLevelConstraints (context : PsElabContext) :
    Except PsElabError PsElabContext := do
  let pending := context.metaContext.levels.pending
  let levels := { context.metaContext.levels with deferUnsolved := false, pending := [] }
  let levels ← pending.foldlM (fun levels (left, right) => do
    let left := psLevelNormalize (psLevelInstantiate levels left)
    let right := psLevelNormalize (psLevelInstantiate levels right)
    if psLevelHasMVar left || psLevelHasMVar right then throw .unresolvedMetavariable
    let checked := psLevelUnify levels left right
    if checked.resourceExceeded then throw .fuelExhausted
    if !checked.success then
      throw (.data "constructor sort constraint disagrees with the inferred resulting universe")
    return checked.context) levels
  return psElabContextWithMeta context { context.metaContext with levels }

def psElabDataInferUniverses (context : PsElabContext)
    (group : PsInductiveGroupPlan) (constructors : List PsDeclaration) :
    Except PsElabError (PsElabContext × Bool) := do
  let headerIds := (group.members.flatMap fun info =>
    (psElabExprLevels (psMetaInstantiate context.metaContext info.type)).flatMap
      psElabDataLevelIds).eraseDups
  let fields ← psElabDataUniverseFields context group constructors
  let (context, result) ← psElabDataInferResultLevel context group fields
  let context ← psElabDataPropagateFieldLevels context result.level fields
  let deferred := result.assignment?.map Prod.fst
  -- The inferred result assignment is delayed until its retained header
  -- metavariables have become parameters, exactly as in the native owner.
  let generalize := fun (context : PsElabContext) (levels : List PsLevel) => do
    let ids := (levels.flatMap fun level =>
      psElabDataLevelIds (psLevelInstantiate context.metaContext.levels level)).eraseDups
    ids.foldlM (fun context id =>
      if deferred == some id then pure context
      else psElabDataAssignLevel context id (psElabGeneralizeLevel (.mvar id))) context
  let context ← group.members.foldlM (fun context info => do
    let context ← generalize context (psElabExprLevels info.type)
    let context ← if deferred.isSome then generalize context [result.level] else pure context
    let constructors := constructors.filter fun declaration =>
      match declaration with
      | .constructorDecl constructor => psNameEq constructor.inductiveName info.name
      | _ => false
    constructors.foldlM (fun context declaration => do
      let ids := ((psElabExprLevels
        (psMetaInstantiate context.metaContext (psDeclarationType declaration))).flatMap
          psElabDataLevelIds).eraseDups
      ids.foldlM (fun context id =>
        if deferred == some id || !headerIds.contains id then pure context
        else psElabDataAssignLevel context id (psElabGeneralizeLevel (.mvar id))) context) context)
    context
  let context ← match result.assignment? with
    | none => pure context
    | some (id, value) => psElabDataAssignLevel context id value
  let context ← psElabDataFinishLevelConstraints context
  let level := psLevelNormalize (psLevelInstantiate context.metaContext.levels result.level)
  if !psLevelEquivalent level .zero && !psLevelAlwaysPositive level then
    throw (.data "inductive resulting universe may be Prop under a level assignment")
  for field in fields do
    let actual := psLevelNormalize (psLevelInstantiate context.metaContext.levels field.level)
    if psLevelHasMVar actual then throw .unresolvedMetavariable
    if !psLevelEquivalent level .zero && !(← psElabDataLevelGeq 4096 level actual) then
      throw (.data "constructor field universe exceeds the inductive resulting universe")
  return (context, result.highUniverse)
