import ProofScript.Kernel.PSC1.Instantiate

namespace ProofScript.Kernel.PSC1

inductive ReducibilityHints where
  | opaque
  | abbrev
  | regular (height : Nat)

inductive DefinitionSafety where
  | unsafe
  | safe
  | partial

inductive ConstantKind where
  | axiom
  | definition
  | theorem
  | opaque

structure ConstantInfo where
  name : Name
  levelParams : List Name
  type : Expr
  value : Option Expr := none
  hints : ReducibilityHints := .opaque
  safety : DefinitionSafety := .safe
  kind : ConstantKind := .axiom

structure Environment where
  constants : List ConstantInfo := []

namespace Environment

def find? (env : Environment) (target : Name) : Option ConstantInfo :=
  env.constants.find? (fun c => Name.beq c.name target)

def contains (env : Environment) (target : Name) : Bool :=
  (find? env target).isSome

def addUnchecked (env : Environment) (info : ConstantInfo) : Environment :=
  { constants := info :: env.constants }

def unfoldableValue? (env : Environment) (target : Name) : Option (List Name × Expr) :=
  match find? env target with
  | some info =>
      match info.kind, info.value with
      | .definition, some value => some (info.levelParams, value)
      | _, _ => none
  | none => none

end Environment

end ProofScript.Kernel.PSC1
