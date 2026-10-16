import Ps.Core.Declaration

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
def psInductiveGroupPlanFor
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
          if !psInductiveGroupRecursorShapeValid plan member recursor then none
          else pure ()
          -- Every recursive call reuses the caller's universe arguments.
          -- Pinned mk_rec_rules uses one ordered recursor level layout for
          -- the entire group; a differing retained layout must stay stuck.
          if let some anchor := ownRecursor then
            if !psInductiveGroupNamesEqual recursor.levelParams anchor.levelParams then none
            else pure ()
        | none =>
          -- Constructor-only singleton declarations are used by the checked
          -- nested bridge's private unit family. A group always has recursors.
          if members.length != 1 then none else pure ()
      return plan
