import ProofScript.Kernel.PSC1.Instantiate

namespace ProofScript.Kernel.PSC1

inductive ReducibilityHints where
  | opaque
  | abbrev
  | regular (height : Nat)

inductive DefinitionSafety where
  | unsafeDef
  | safeDef
  | partialDef

inductive ConstantKind where
  | axiomK
  | definitionK
  | theoremK
  | opaqueK

structure ConstantInfo where
  name : Name
  levelParams : List Name
  type : Expr
  value : Option Expr := none
  hints : ReducibilityHints := .opaque
  safety : DefinitionSafety := .safeDef
  kind : ConstantKind := .axiomK

structure Environment where
  constants : List ConstantInfo := []

namespace Environment

def findIn : List ConstantInfo → Name → Option ConstantInfo
  | [], _ => none
  | c :: cs, target =>
      if Name.beq c.name target then some c else findIn cs target

def find? (env : Environment) (target : Name) : Option ConstantInfo :=
  findIn env.constants target

def contains (env : Environment) (target : Name) : Bool :=
  (find? env target).isSome

def addUnchecked (env : Environment) (info : ConstantInfo) : Environment :=
  { constants := info :: env.constants }

def unfoldableValue? (env : Environment) (target : Name) : Option (List Name × Expr) :=
  match find? env target with
  | some info =>
      match info.kind, info.value with
      | .definitionK, some value => some (info.levelParams, value)
      | _, _ => none
  | none => none

end Environment

end ProofScript.Kernel.PSC1
