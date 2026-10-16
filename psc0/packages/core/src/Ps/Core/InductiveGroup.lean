import Ps.Core.Declaration
import Ps.Core.Nested
import Ps.Core.Equality
import Ps.Core.Subst
import Ps.Core.LevelSubst
import Ps.Core.LevelNormalize

-- Ordered declaration-group shape, shared by elaboration, canonical admission
-- and reduction. This is a plan, not kernel acceptance or a proof capability.
-- Family order owns motive order; constructor order within each family owns
-- its segment of the common minor telescope (Lean kernel/inductive.cpp).
structure PsInductiveGroupPlan where
  members : List PsInductiveInfo

-- Kernel minor hypotheses follow constructor-field order. The retained
-- positions must be strictly increasing and bounded; uniqueness alone would
-- allow equal-typed hypotheses to be silently associated with another child.
def psConstructorRecursiveFieldsOrdered (constructor : PsConstructorInfo) : Bool :=
  let checked := constructor.recursiveFields.foldl
    (fun (state : Bool × Nat) position =>
      (state.fst && state.snd <= position && position < constructor.numFields,
        position + 1)) (true, 0)
  checked.fst

def psInductiveGroupNames (plan : PsInductiveGroupPlan) : List PsName :=
  plan.members.map (·.name)

def psInductiveGroupNamesEqual (left right : List PsName) : Bool :=
  left.length == right.length && (left.zip right).all (fun pair => psNameEq pair.fst pair.snd)

def psInductiveGroupFind (plan : PsInductiveGroupPlan) (name : PsName) : Option PsInductiveInfo :=
  plan.members.find? (fun info => psNameEq info.name name)

def psInductiveGroupNumMinors (plan : PsInductiveGroupPlan) : Nat :=
  plan.members.foldl (fun count info => count + info.constructors.length) 0

def psInductiveGroupMinorOffsetFrom : List PsInductiveInfo → PsName → Nat → Option Nat
  | [], _, _ => none
  | member :: rest, name, offset =>
    if psNameEq member.name name then some offset
    else psInductiveGroupMinorOffsetFrom rest name (offset + member.constructors.length)

def psInductiveGroupMinorOffset (plan : PsInductiveGroupPlan) (name : PsName) : Option Nat :=
  psInductiveGroupMinorOffsetFrom plan.members name 0

def psInductiveGroupHeaderShapeValid (plan : PsInductiveGroupPlan) : Bool :=
  match plan.members with
  | [] => false
  | first :: _ =>
    let names := psInductiveGroupNames plan
    names.all (fun name => (names.filter (psNameEq name)).length == 1) &&
      plan.members.all (fun info => info.numParams == first.numParams &&
        psInductiveGroupNamesEqual info.levelParams first.levelParams)

-- The recursor already retains group identity; do not add a second group ID
-- to every family or infer groups from an arbitrary dependency cycle.
def psInductiveGroupRecursorShapeValid (plan : PsInductiveGroupPlan)
    (family : PsInductiveInfo) (recursor : PsRecursorInfo) : Bool :=
  psNameEq recursor.name (psNameAppendStr family.name "rec") &&
    psInductiveGroupNamesEqual recursor.inductiveNames (psInductiveGroupNames plan) &&
    recursor.numParams == family.numParams && recursor.numIndices == family.numIndices &&
    recursor.numMotives == plan.members.length &&
    recursor.numMinors == psInductiveGroupNumMinors plan

-- Lookup is supplied by the owning environment/transport. Structural checks
-- here only prevent splitting, dropping or reordering an explicit group.
-- Its types, positivity and generated recursors are checked by official Lean.
def psInductiveGroupIdentityFor
    (findInductive : PsName → Option PsInductiveInfo)
    (findRecursor : PsName → Option PsRecursorInfo)
    (family : PsInductiveInfo) : Option PsInductiveGroupPlan := do
  let ownRecursor := findRecursor (psNameAppendStr family.name "rec")
  let names := ownRecursor.map (·.inductiveNames) |>.getD [family.name]
  if !names.any (psNameEq family.name) then none else do
    let members ← names.mapM findInductive
    let plan : PsInductiveGroupPlan := { members }
    if !psInductiveGroupHeaderShapeValid plan then none else do
      for member in members do
        match findRecursor (psNameAppendStr member.name "rec") with
        | some recursor =>
          if !psNameEq recursor.name (psNameAppendStr member.name "rec") ||
              !psInductiveGroupNamesEqual recursor.inductiveNames names ||
              recursor.numParams != member.numParams || recursor.numIndices != member.numIndices then none
          else pure ()
          -- Every recursive call reuses the caller's universe arguments.
          -- Pinned mk_rec_rules uses one ordered recursor level layout for
          -- the entire group; a differing retained layout must stay stuck.
          if let some anchor := ownRecursor then
            if !psInductiveGroupNamesEqual recursor.levelParams anchor.levelParams then none
            else pure ()
        | none =>
          -- Constructor-only singleton batches retain no explicit mutual
          -- membership claim. A retained group always has recursors.
          if members.length != 1 then none else pure ()
      return plan

-- Compatibility view for consumers whose contract is a direct group. Nested
-- recursors have more motives than public members and cannot enter this view.
def psInductiveGroupPlanFor
    (findInductive : PsName → Option PsInductiveInfo)
    (findRecursor : PsName → Option PsRecursorInfo)
    (family : PsInductiveInfo) : Option PsInductiveGroupPlan := do
  let plan ← psInductiveGroupIdentityFor findInductive findRecursor family
  for member in plan.members do
    if let some recursor := findRecursor (psNameAppendStr member.name "rec") then
      if !psInductiveGroupRecursorShapeValid plan member recursor then none else pure ()
  return plan

-- A nested slot describes an existing, specialized container. It is not an
-- additional declaration of List/Option/Array/Prod. Closed templates abstract
-- the visible group's common parameters; the underlying constructor still
-- receives its own actual parameters (which need not have the same count).
structure PsInductiveEliminationBinder where
  name : PsName
  type : PsExpr
  binder : PsBinderInfo

structure PsInductiveEliminationConstructor where
  info : PsConstructorInfo
  type : PsExpr
  head : PsExpr
  -- Field order is kernel IH order. The second component identifies the
  -- actual elimination slot, including distinct specializations of one List.
  recursiveFields : List (Nat × Nat) := []

structure PsInductiveEliminationSlot where
  family : PsInductiveInfo
  publicMember : Bool
  recursorName : PsName
  type : PsExpr
  typeFormer : PsExpr
  constructors : List PsInductiveEliminationConstructor

structure PsInductiveEliminationPlan where
  group : PsInductiveGroupPlan
  parameters : List PsInductiveEliminationBinder
  slots : List PsInductiveEliminationSlot

structure PsInductiveEliminationAppView where
  head : PsExpr
  args : List PsExpr

def psInductiveEliminationAppView (expr : PsExpr)
    (args : List PsExpr := []) : PsInductiveEliminationAppView :=
  match expr with
  | .app fn arg => psInductiveEliminationAppView fn (arg :: args)
  | _ => { head := expr, args }

def psInductiveEliminationBind (lambda : Bool)
    (binders : List PsInductiveEliminationBinder) (body : PsExpr) : PsExpr :=
  binders.foldr (fun binder body =>
    if lambda then .lam binder.name binder.type body binder.binder
    else .forallE binder.name binder.type body binder.binder) body

-- Dropping binders deliberately leaves de Bruijn references to the common
-- parameters. Unlike synthetic fvar IDs this cannot alias a caller's locals.
def psInductiveEliminationOpenParameters (count : Nat) (type : PsExpr) :
    Option (List PsInductiveEliminationBinder × PsExpr) := do
  match count with
  | 0 => return ([], type)
  | count + 1 =>
    let .forallE name domain body binder := type | none
    let (binders, result) ← psInductiveEliminationOpenParameters count body
    return ({ name, type := domain, binder } :: binders, result)

-- Consumers of a registered telescope may expose an index/field binder
-- through an ordinary reducible alias. Discovery above/below still examines
-- the original constructor syntax for structural specialization identity.
def psInductiveEliminationOpenTelescope (reduce : PsExpr → PsExpr)
    (count : Nat) (type : PsExpr) :
    Option (List PsInductiveEliminationBinder × PsExpr) := do
  match count with
  | 0 => return ([], type)
  | count + 1 =>
    let .forallE name domain body binder := reduce type | none
    let (binders, result) ← psInductiveEliminationOpenTelescope reduce count body
    return ({ name, type := domain, binder } :: binders, result)

def psInductiveEliminationApplyParameters (type : PsExpr) (arguments : List PsExpr) :
    Option PsExpr := do
  match arguments with
  | [] => return type
  | argument :: rest =>
    let .forallE _ _ body _ := type | none
    psInductiveEliminationApplyParameters (psExprInstantiate1 body argument) rest

def psInductiveEliminationApplyTemplate (template : PsExpr) (arguments : List PsExpr) :
    Option PsExpr := do
  match arguments with
  | [] => return template
  | argument :: rest =>
    let .lam _ _ body _ := template | none
    psInductiveEliminationApplyTemplate (psExprInstantiate1 body argument) rest

def psInductiveEliminationParameterArguments (count depth : Nat) : List PsExpr :=
  (List.range count).map (fun index => .bvar (depth + count - index - 1))

-- Remove surrounding constructor/field binders from a specialization key.
-- Their variables may occur in container indices, but never in the fixed
-- parameters Ds of I Ds is (kernel/inductive.cpp is_nested_inductive_app).
def psInductiveEliminationRebase (count removed : Nat) (expr : PsExpr)
    (depth : Nat := 0) : Option PsExpr := do
  match expr with
  | .bvar index =>
    if index < depth then return expr
    else if index < depth + removed || index >= depth + removed + count then none
    else return .bvar (index - removed)
  | .fvar _ | .mvar _ => none
  | .app fn arg => return .app
      (← psInductiveEliminationRebase count removed fn depth)
      (← psInductiveEliminationRebase count removed arg depth)
  | .lam name domain body binder => return .lam name
      (← psInductiveEliminationRebase count removed domain depth)
      (← psInductiveEliminationRebase count removed body (depth + 1)) binder
  | .forallE name domain body binder => return .forallE name
      (← psInductiveEliminationRebase count removed domain depth)
      (← psInductiveEliminationRebase count removed body (depth + 1)) binder
  | .letE name domain value body => return .letE name
      (← psInductiveEliminationRebase count removed domain depth)
      (← psInductiveEliminationRebase count removed value depth)
      (← psInductiveEliminationRebase count removed body (depth + 1))
  | .proj name index value => return .proj name index
      (← psInductiveEliminationRebase count removed value depth)
  | _ => return expr

def psInductiveEliminationContains (names : List PsName) (expr : PsExpr) : Bool :=
  match expr with
  | .constE name _ => names.any (psNameEq name)
  | .app fn arg => psInductiveEliminationContains names fn || psInductiveEliminationContains names arg
  | .lam _ type body _ | .forallE _ type body _ =>
      psInductiveEliminationContains names type || psInductiveEliminationContains names body
  | .letE _ type value body => psInductiveEliminationContains names type ||
      psInductiveEliminationContains names value || psInductiveEliminationContains names body
  | .proj _ _ value => psInductiveEliminationContains names value
  | _ => false

-- Pinned check_uniform_ind_occs runs before any WHNF or nested replacement.
-- Every syntactic occurrence, including one erased by beta reduction, must
-- use the declared levels and the actual outer common parameter variables.
def psInductiveGroupOccurrencesUniform (group : PsInductiveGroupPlan)
    (expr : PsExpr) (depth : Nat := 0) : Bool :=
  match group.members with
  | [] => false
  | first :: _ =>
    let view := psInductiveEliminationAppView expr
    let occurrence := match view.head with
      | .constE name levels =>
        if (psInductiveGroupNames group).any (psNameEq name) &&
            view.args.length <= first.numParams then
          some (view.args.length == first.numParams && depth >= first.numParams &&
            levels.length == first.levelParams.length &&
            (levels.zip first.levelParams).all
              (fun pair => psLevelStructuralEq pair.1 (.param pair.2)) &&
            view.args.zipIdx.all (fun (argument, index) =>
              match argument with
              | .bvar actual => actual == depth - index - 1
              | _ => false))
        else none
      | _ => none
    match occurrence with
    | some valid => valid
    | none =>
      match expr with
      | .app fn arg =>
        psInductiveGroupOccurrencesUniform group fn depth &&
          psInductiveGroupOccurrencesUniform group arg depth
      | .lam _ type body _ | .forallE _ type body _ =>
        psInductiveGroupOccurrencesUniform group type depth &&
          psInductiveGroupOccurrencesUniform group body (depth + 1)
      | .letE _ type value body =>
        psInductiveGroupOccurrencesUniform group type depth &&
          psInductiveGroupOccurrencesUniform group value depth &&
          psInductiveGroupOccurrencesUniform group body (depth + 1)
      | .proj _ _ value => psInductiveGroupOccurrencesUniform group value depth
      | _ => true

def psInductiveEliminationNumMinors (plan : PsInductiveEliminationPlan) : Nat :=
  plan.slots.foldl (fun count slot => count + slot.constructors.length) 0

def psInductiveEliminationSlotFor (plan : PsInductiveEliminationPlan) (name : PsName) :
    Option (Nat × PsInductiveEliminationSlot) :=
  (plan.slots.zipIdx).findSome? (fun (slot, index) =>
    if psNameEq slot.recursorName name then some (index, slot) else none)

def psInductiveEliminationMinorOffset (plan : PsInductiveEliminationPlan) (slot : Nat) :
    Option Nat :=
  if slot >= plan.slots.length then none
  else some ((plan.slots.take slot).foldl (fun count member => count + member.constructors.length) 0)

def psInductiveEliminationInstantiate (plan : PsInductiveEliminationPlan)
    (levels : List PsLevel) (parameters : List PsExpr) (template : PsExpr) : Option PsExpr := do
  let first :: _ := plan.group.members | none
  if levels.length != first.levelParams.length || parameters.length != first.numParams then none
  else psInductiveEliminationApplyTemplate
    (psExprInstantiateLevelParams first.levelParams levels template) parameters

-- With the target slot already fixed, compare its real parameter prefix and
-- return only that slot's own indices. Never find a nested child by base name:
-- List (Tree A) and List (List (Tree A)) have the same List.cons constructor.
def psInductiveEliminationIndicesAt (equal : PsExpr → PsExpr → Bool)
    (plan : PsInductiveEliminationPlan) (slot : PsInductiveEliminationSlot)
    (levels : List PsLevel) (parameters : List PsExpr) (type : PsExpr) : Option (List PsExpr) := do
  let specializedPrefix ← psInductiveEliminationInstantiate plan levels parameters slot.typeFormer
  let expected := psInductiveEliminationAppView specializedPrefix
  let actual := psInductiveEliminationAppView type
  if actual.args.length != expected.args.length + slot.family.numIndices ||
      !equal actual.head expected.head ||
      !(actual.args.take expected.args.length |>.zip expected.args).all
        (fun pair => equal pair.1 pair.2) then none
  else return actual.args.drop expected.args.length

-- Closed telescope comparison ignores binder spelling/kind, as kernel
-- definitional equality of types does, while preserving every domain, level,
-- bound reference and application. Reduction is supplied by the consumer.
def psInductiveEliminationTypeEqual (reduce : PsExpr → PsExpr) (fuel : Nat)
    (left right : PsExpr) : Bool :=
  if psExprAlphaEq left right then true else match fuel with
  | 0 => false
  | fuel + 1 =>
    let left := reduce left
    let right := reduce right
    match left, right with
    | .forallE _ leftType leftBody _, .forallE _ rightType rightBody _
    | .lam _ leftType leftBody _, .lam _ rightType rightBody _ =>
      psInductiveEliminationTypeEqual reduce fuel leftType rightType &&
        psInductiveEliminationTypeEqual reduce fuel leftBody rightBody
    | .app leftFn leftArg, .app rightFn rightArg =>
      psInductiveEliminationTypeEqual reduce fuel leftFn rightFn &&
        psInductiveEliminationTypeEqual reduce fuel leftArg rightArg
    | .sortE left, .sortE right => psLevelEquivalent left right
    | .constE leftName leftLevels, .constE rightName rightLevels =>
      psNameEq leftName rightName && leftLevels.length == rightLevels.length &&
        (leftLevels.zip rightLevels).all (fun pair => psLevelEquivalent pair.1 pair.2)
    | _, _ => psExprAlphaEq left right

def psInductiveEliminationConstructors
    (findConstructor : PsName → Option PsConstructorInfo)
    (parameters : List PsInductiveEliminationBinder) (family : PsInductiveInfo)
    (levels : List PsLevel) (arguments : List PsExpr) :
    Option (List PsInductiveEliminationConstructor) :=
  (family.constructors.zipIdx).mapM fun (name, index) => do
    let info ← findConstructor name
    if !psNameEq info.inductiveName family.name || info.constructorIndex != index ||
        info.numParams != family.numParams ||
        !psInductiveGroupNamesEqual info.levelParams family.levelParams then none else do
      let type ← psInductiveEliminationApplyParameters
        (psExprInstantiateLevelParams info.levelParams levels info.type) arguments
      return {
        info
        type := psInductiveEliminationBind false parameters type
        head := psInductiveEliminationBind true parameters
          (psExprApplyMany (.constE info.name levels) arguments) }

def psInductiveEliminationPublicSlots
    (findConstructor : PsName → Option PsConstructorInfo)
    (group : PsInductiveGroupPlan) (parameters : List PsInductiveEliminationBinder) :
    Option (List PsInductiveEliminationSlot) := do
  let first :: _ := group.members | none
  let arguments := psInductiveEliminationParameterArguments first.numParams 0
  let levels := first.levelParams.map PsLevel.param
  group.members.mapM fun family => do
    let constructors ← psInductiveEliminationConstructors findConstructor parameters family levels arguments
    return {
      family, publicMember := true
      recursorName := psNameAppendStr family.name "rec"
      type := family.type
      typeFormer := psInductiveEliminationBind true parameters
        (psExprApplyMany (.constE family.name levels) arguments)
      constructors }

-- Queue discovery uses the ORIGINAL expression, not its WHNF. Pinned Lean
-- deduplicates I Ds structurally after rebinding common parameters; indices
-- are not part of the key, and definitionally equal keys are not merged.
def psInductiveEliminationDiscover (fuel : Nat)
    (findInductive : PsName → Option PsInductiveInfo)
    (findConstructor : PsName → Option PsConstructorInfo)
    (plan : PsInductiveEliminationPlan) (expr : PsExpr) (depth : Nat) :
    Option PsInductiveEliminationPlan := do
  match fuel with
  | 0 => none
  | fuel + 1 =>
    let first :: _ := plan.group.members | none
    let names := psInductiveGroupNames plan.group
    let view := psInductiveEliminationAppView expr
    let candidate := match view.head with
      | .constE name levels =>
        if names.any (psNameEq name) then none
        else (findInductive name).map (fun family => (family, levels))
      | _ => none
    if let some (family, levels) := candidate then
      let arguments := view.args.take family.numParams
      if view.args.length >= family.numParams &&
          arguments.any (psInductiveEliminationContains names) then
        let specializedPrefix := psExprApplyMany view.head arguments
        let some _ := psSelectedNestedContainer? specializedPrefix | none
        if family.numIndices != 0 || levels.length != family.levelParams.length then none else do
          let rebased ← psInductiveEliminationRebase first.numParams depth specializedPrefix
          let key := psInductiveEliminationBind true plan.parameters rebased
          if plan.slots.any (fun slot => !slot.publicMember && psExprAlphaEq slot.typeFormer key) then
            return plan
          let specialized := psInductiveEliminationAppView rebased
          let type ← psInductiveEliminationApplyParameters
            (psExprInstantiateLevelParams family.levelParams levels family.type) specialized.args
          let constructors ← psInductiveEliminationConstructors findConstructor plan.parameters
            family levels specialized.args
          let index := plan.slots.length - plan.group.members.length + 1
          let slot : PsInductiveEliminationSlot := {
            family, publicMember := false
            recursorName := psNameAppendStr first.name ("rec_" ++ psNatToString index)
            type := psInductiveEliminationBind false plan.parameters type
            typeFormer := key, constructors }
          return { plan with slots := plan.slots ++ [slot] }
    match expr with
    | .app fn arg =>
      let plan ← psInductiveEliminationDiscover fuel findInductive findConstructor plan fn depth
      psInductiveEliminationDiscover fuel findInductive findConstructor plan arg depth
    | .lam _ type body _ | .forallE _ type body _ =>
      let plan ← psInductiveEliminationDiscover fuel findInductive findConstructor plan type depth
      psInductiveEliminationDiscover fuel findInductive findConstructor plan body (depth + 1)
    | .letE _ type value body =>
      let plan ← psInductiveEliminationDiscover fuel findInductive findConstructor plan type depth
      let plan ← psInductiveEliminationDiscover fuel findInductive findConstructor plan value depth
      psInductiveEliminationDiscover fuel findInductive findConstructor plan body (depth + 1)
    | .proj _ _ value => psInductiveEliminationDiscover fuel findInductive findConstructor plan value depth
    | _ => return plan

def psInductiveEliminationExpand (fuel : Nat)
    (findInductive : PsName → Option PsInductiveInfo)
    (findConstructor : PsName → Option PsConstructorInfo)
    (plan : PsInductiveEliminationPlan) (index : Nat) : Option PsInductiveEliminationPlan := do
  match fuel with
  | 0 => none
  | fuel + 1 =>
    match plan.slots[index]? with
    | none => return plan
    | some slot =>
      let plan ← slot.constructors.foldlM (fun plan constructor => do
        let (_, type) ← psInductiveEliminationOpenParameters plan.parameters.length constructor.type
        psInductiveEliminationDiscover 4096 findInductive findConstructor plan type 0) plan
      psInductiveEliminationExpand fuel findInductive findConstructor plan (index + 1)

def psInductiveEliminationFieldTarget (reduce : PsExpr → PsExpr) (fuel : Nat)
    (plan : PsInductiveEliminationPlan) (type : PsExpr) (depth : Nat) : Option Nat := do
  match fuel with
  | 0 => none
  | fuel + 1 =>
    -- Preserve the raw specialization before reducing an alias around it.
    let target := (plan.slots.zipIdx).findSome? fun (slot, index) => do
      let view := psInductiveEliminationAppView type
      if view.args.length != slot.family.numParams + slot.family.numIndices then none else do
        let specializedPrefix ← psInductiveEliminationRebase plan.parameters.length depth
          (psExprApplyMany view.head (view.args.take slot.family.numParams))
        let actual := psInductiveEliminationBind true plan.parameters specializedPrefix
        if psExprAlphaEq actual slot.typeFormer ||
            (slot.publicMember && psInductiveEliminationTypeEqual reduce 4096 actual slot.typeFormer) then
          some index else none
    if target.isSome then return ← target
    let normalized := reduce type
    match normalized with
    | .forallE _ _ body _ => psInductiveEliminationFieldTarget reduce fuel plan body (depth + 1)
    | _ =>
      if psExprAlphaEq type normalized then none
      else psInductiveEliminationFieldTarget reduce fuel plan normalized depth

def psInductiveEliminationFieldEdges (reduce : PsExpr → PsExpr) (fuel : Nat)
    (plan : PsInductiveEliminationPlan) (count index : Nat) (type : PsExpr) :
    Option (List (Nat × Nat)) := do
  match count, fuel with
  | 0, _ => return []
  | _, 0 => none
  | count + 1, fuel + 1 =>
    let .forallE _ domain body _ := reduce type | none
    let tail ← psInductiveEliminationFieldEdges reduce fuel plan count (index + 1) body
    match psInductiveEliminationFieldTarget reduce 4096 plan domain index with
    | some target => return (index, target) :: tail
    | none =>
      if psInductiveEliminationContains (psInductiveGroupNames plan.group) (reduce domain) then none
      else return tail

-- Formation is independent of recursor registration: Data uses this before
-- generating recursors. Registered consumers additionally check all retained
-- descriptors below. Thus no recursor can certify its own specialization key.
def psBuildInductiveEliminationPlan (reduce : PsExpr → PsExpr)
    (findInductive : PsName → Option PsInductiveInfo)
    (findConstructor : PsName → Option PsConstructorInfo)
    (group : PsInductiveGroupPlan) : Option PsInductiveEliminationPlan := do
  if !psInductiveGroupHeaderShapeValid group then none else do
    let first :: _ := group.members | none
    let (parameters, _) ← psInductiveEliminationOpenParameters first.numParams first.type
    let slots ← psInductiveEliminationPublicSlots findConstructor group parameters
    if !slots.all (fun slot => slot.constructors.all
        (fun constructor => psInductiveGroupOccurrencesUniform group constructor.info.type)) then none
    else pure ()
    let plan ← psInductiveEliminationExpand 4096 findInductive findConstructor
      { group, parameters, slots } 0
    let slots ← plan.slots.mapM fun slot => do
      let constructors ← slot.constructors.mapM fun constructor => do
        let (_, type) ← psInductiveEliminationOpenParameters parameters.length constructor.type
        let recursiveFields ← psInductiveEliminationFieldEdges reduce 4096 plan
          constructor.info.numFields 0 type
        return { constructor with recursiveFields }
      return { slot with constructors }
    return { plan with slots }

def psInductiveEliminationConstructorMetadataValid (slot : PsInductiveEliminationSlot)
    (constructor : PsInductiveEliminationConstructor) : Bool :=
  psConstructorRecursiveFieldsOrdered constructor.info &&
    (!slot.publicMember || constructor.info.recursiveFields == constructor.recursiveFields.map Prod.fst)

-- All indices and majors are built in raw de Bruijn contexts. Common
-- parameters already lie outside the cursor; no invented free-variable IDs
-- can collide with a reduction caller's local context.
def psInductiveEliminationMotiveType (reduce : PsExpr → PsExpr) (plan : PsInductiveEliminationPlan)
    (slot : PsInductiveEliminationSlot) (prior : Nat) (level : PsLevel) : Option PsExpr := do
  let arguments := psInductiveEliminationParameterArguments plan.parameters.length prior
  let type ← psInductiveEliminationApplyParameters slot.type arguments
  let (indices, _) ← psInductiveEliminationOpenTelescope reduce slot.family.numIndices type
  let family ← psInductiveEliminationApplyTemplate slot.typeFormer arguments
  let major := psExprApplyMany (psExprLiftBVars indices.length 0 family)
    (psInductiveEliminationParameterArguments indices.length 0)
  return psInductiveEliminationBind false indices
    (.forallE (psRootName "_major") major (.sortE level) .explicit)

def psInductiveEliminationMotiveApplication (reduce : PsExpr → PsExpr)
    (plan : PsInductiveEliminationPlan) (target : Nat) (parameters : List PsExpr)
    (motive value type : PsExpr) : Option PsExpr := do
  let first :: _ := plan.group.members | none
  let slot ← plan.slots[target]?
  let indices ← psInductiveEliminationIndicesAt
    (psInductiveEliminationTypeEqual reduce 4096) plan slot
    (first.levelParams.map PsLevel.param) parameters (reduce type)
  return psExprApplyMany motive (indices ++ [value])

def psInductiveEliminationHypothesisType (reduce : PsExpr → PsExpr) (fuel : Nat)
    (plan : PsInductiveEliminationPlan) (target : Nat) (parameters : List PsExpr)
    (motive value type : PsExpr) : Option PsExpr := do
  match fuel with
  | 0 => none
  | fuel + 1 =>
    match reduce type with
    | .forallE name domain body binder =>
      let lift := psExprLiftBVars 1 0
      let body ← psInductiveEliminationHypothesisType reduce fuel plan target
        (parameters.map lift) (lift motive) (.app (lift value) (.bvar 0)) body
      return .forallE name domain body binder
    | type => psInductiveEliminationMotiveApplication reduce plan target parameters motive value type

def psInductiveEliminationMinorType (reduce : PsExpr → PsExpr)
    (plan : PsInductiveEliminationPlan) (slotIndex minorIndex : Nat)
    (constructor : PsInductiveEliminationConstructor) : Option PsExpr := do
  let offset := plan.slots.length + minorIndex
  let parameters := psInductiveEliminationParameterArguments plan.parameters.length offset
  let type ← psInductiveEliminationApplyParameters constructor.type parameters
  let (fields, conclusionType) ← psInductiveEliminationOpenTelescope reduce constructor.info.numFields type
  let head ← psInductiveEliminationApplyTemplate constructor.head parameters
  let fieldValues := psInductiveEliminationParameterArguments fields.length 0
  let value := psExprApplyMany (psExprLiftBVars fields.length 0 head) fieldValues
  let parameters := parameters.map (psExprLiftBVars fields.length 0)
  let motive := fun target => PsExpr.bvar (fields.length + offset - target - 1)
  let conclusion ← psInductiveEliminationMotiveApplication reduce plan slotIndex parameters
    (motive slotIndex) value conclusionType
  let hypotheses ← constructor.recursiveFields.mapM fun (index, target) => do
    let field ← fields[index]?
    let value ← fieldValues[index]?
    let type := psExprLiftBVars (fields.length - index) 0 field.type
    psInductiveEliminationHypothesisType reduce 4096 plan target parameters (motive target) value type
  let binders := hypotheses.zipIdx.map fun (type, index) =>
    PsInductiveEliminationBinder.mk (psNameAppendNum (psRootName "_ih") index)
      (psExprLiftBVars index 0 type) .explicit
  return psInductiveEliminationBind false fields
    (psInductiveEliminationBind false binders (psExprLiftBVars hypotheses.length 0 conclusion))

def psInductiveEliminationRecursorType (reduce : PsExpr → PsExpr)
    (plan : PsInductiveEliminationPlan) (target : Nat) (level : PsLevel) : Option PsExpr := do
  let slot ← plan.slots[target]?
  let motives ← plan.slots.zipIdx.mapM fun (slot, index) => do
    let type ← psInductiveEliminationMotiveType reduce plan slot index level
    let name := if plan.slots.length == 1 then psRootName "_motive"
      else psNameAppendNum (psRootName "_motive") index
    return PsInductiveEliminationBinder.mk name type .explicit
  let constructors := plan.slots.zipIdx.flatMap fun (slot, index) =>
    slot.constructors.map (fun constructor => (index, constructor))
  let minors ← constructors.zipIdx.mapM fun ((owner, constructor), index) => do
    let type ← psInductiveEliminationMinorType reduce plan owner index constructor
    return PsInductiveEliminationBinder.mk (psNameAppendNum (psRootName "_minor") index) type .explicit
  let offset := motives.length + minors.length
  let parameters := psInductiveEliminationParameterArguments plan.parameters.length offset
  let type ← psInductiveEliminationApplyParameters slot.type parameters
  let (indices, _) ← psInductiveEliminationOpenTelescope reduce slot.family.numIndices type
  let family ← psInductiveEliminationApplyTemplate slot.typeFormer parameters
  let indexValues := psInductiveEliminationParameterArguments indices.length 0
  let majorType := psExprApplyMany (psExprLiftBVars indices.length 0 family) indexValues
  let motive := PsExpr.bvar (indices.length + offset - target)
  let result := psExprApplyMany motive (indexValues.map (psExprLiftBVars 1 0) ++ [.bvar 0])
  let body := psInductiveEliminationBind false
    (indices.map (fun index => { index with binder := .implicit }))
    (.forallE (psRootName "_major") majorType result .explicit)
  return psInductiveEliminationBind false
    (plan.parameters.map (fun parameter => { parameter with binder := .implicit }))
    (psInductiveEliminationBind false motives (psInductiveEliminationBind false minors body))

def psInductiveEliminationRecursorShapeValid (plan : PsInductiveEliminationPlan)
    (slot : PsInductiveEliminationSlot) (recursor : PsRecursorInfo) : Bool :=
  psNameEq recursor.name slot.recursorName &&
    psInductiveGroupNamesEqual recursor.inductiveNames (psInductiveGroupNames plan.group) &&
    recursor.numParams == plan.parameters.length && recursor.numIndices == slot.family.numIndices &&
    recursor.numMotives == plan.slots.length && recursor.numMinors == psInductiveEliminationNumMinors plan

def psInductiveEliminationFamilyLevels (plan : PsInductiveEliminationPlan)
    (recursor : PsRecursorInfo) (levels : List PsLevel) : Option (List PsLevel) := do
  let first :: _ := plan.group.members | none
  if levels.length != recursor.levelParams.length then none
  else if psInductiveGroupNamesEqual recursor.levelParams first.levelParams then some levels
  else if recursor.levelParams.length == first.levelParams.length + 1 &&
      psInductiveGroupNamesEqual (recursor.levelParams.drop 1) first.levelParams then
    some (levels.drop 1)
  else none

def psInductiveEliminationRecursorsRegistered (reduce : PsExpr → PsExpr)
    (findRecursor : PsName → Option PsRecursorInfo)
    (plan : PsInductiveEliminationPlan) : Bool :=
  match plan.slots with
  | [] => false
  | anchor :: _ =>
    match findRecursor anchor.recursorName with
    | none => false
    | some first =>
      let familyLevels := psInductiveEliminationFamilyLevels plan first (first.levelParams.map PsLevel.param)
      let level := if familyLevels.any (fun levels => levels.length == first.levelParams.length) then
          PsLevel.zero
        else first.levelParams.head?.map PsLevel.param |>.getD .zero
      familyLevels.isSome &&
      plan.slots.zipIdx.all fun (slot, index) =>
        match findRecursor slot.recursorName with
        | none => false
        | some recursor => psInductiveEliminationRecursorShapeValid plan slot recursor &&
            psInductiveGroupNamesEqual recursor.levelParams first.levelParams &&
            (psInductiveEliminationRecursorType reduce plan index level).any
              (fun type => psInductiveEliminationTypeEqual reduce 4096 type recursor.type)

def psInductiveEliminationRegistered (reduce : PsExpr → PsExpr)
    (findRecursor : PsName → Option PsRecursorInfo)
    (plan : PsInductiveEliminationPlan) : Bool :=
  psInductiveEliminationRecursorsRegistered reduce findRecursor plan &&
    plan.slots.all (fun slot =>
      slot.constructors.all (psInductiveEliminationConstructorMetadataValid slot))

def psInductiveEliminationPlanFor (reduce : PsExpr → PsExpr)
    (findInductive : PsName → Option PsInductiveInfo)
    (findConstructor : PsName → Option PsConstructorInfo)
    (findRecursor : PsName → Option PsRecursorInfo)
    (family : PsInductiveInfo) : Option PsInductiveEliminationPlan := do
  let group ← psInductiveGroupIdentityFor findInductive findRecursor family
  let plan ← psBuildInductiveEliminationPlan reduce findInductive findConstructor group
  if psInductiveEliminationRegistered reduce findRecursor plan then some plan else none
