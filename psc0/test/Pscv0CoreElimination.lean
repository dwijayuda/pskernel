import Ps.Compiler.Pscv0Engine
import Ps.Environment.CompilerSourceCandidate
import Ps.Environment.Fingerprint
import PsKernelLean.Replay
import PsKernelLean.Protocol

-- Actual native Lean sources, independent of the selected readers.
namespace CoreEliminationOracle
def coreElimCasesComputed (n : Nat) : Nat := by
  cases Nat.succ n
  case zero => exact 41
  case succ k => exact k
theorem coreElimCasesComputedZero : coreElimCasesComputed 0 = 0 := by rfl
theorem coreElimCasesComputedSeven : coreElimCasesComputed 7 = 7 := by rfl
theorem coreElimComputedProof (n : Nat) : Nat.succ n = Nat.succ n := by
  cases Nat.succ n
  case zero => rfl
  case succ k => rfl

def coreElimCasesLet (n : Nat) : Nat := by
  let value : Nat := Nat.succ n
  cases value
  case zero => exact 43
  case succ k => exact k
theorem coreElimCasesLetZero : coreElimCasesLet 0 = 0 := by rfl
theorem coreElimCasesLetEight : coreElimCasesLet 8 = 8 := by rfl
theorem coreElimLetProof (n : Nat) : Nat.succ n = Nat.succ n := by
  let value : Nat := Nat.succ n
  change value = value
  cases value
  case zero => rfl
  case succ k => rfl

def coreElimInductionComputed (n : Nat) : Nat := by
  induction Nat.succ n
  case zero => exact 0
  case succ k ih => exact Nat.succ ih
theorem coreElimInductionComputedZero : coreElimInductionComputed 0 = 1 := by rfl
theorem coreElimInductionComputedSeven : coreElimInductionComputed 7 = 8 := by rfl
theorem coreElimInductionComputedProof (n : Nat) : True := by
  induction Nat.succ n
  case zero => constructor
  case succ k ih => exact ih

def coreElimInductionLet (n : Nat) : Nat := by
  let value : Nat := Nat.succ n
  induction value
  case zero => exact 0
  case succ k ih => exact Nat.succ ih
theorem coreElimInductionLetZero : coreElimInductionLet 0 = 1 := by rfl
theorem coreElimInductionLetEight : coreElimInductionLet 8 = 9 := by rfl
theorem coreElimInductionLetProof (n : Nat) : True := by
  let value : Nat := Nat.succ n
  induction value
  case zero => constructor
  case succ k ih => exact ih

theorem coreElimComputedDependent (n : Nat) :
    forall (h : Nat.succ n = Nat.succ n), h = h := by
  cases Nat.succ n
  case zero =>
    intro h
    rfl
  case succ k =>
    intro h
    rfl
theorem coreElimShadowedBinder (n : Nat) : forall (k : Nat), Nat.succ k = Nat.succ k := by
  cases Nat.succ n
  case zero =>
    intro k
    rfl
  case succ k =>
    intro other
    rfl
theorem coreElimInferredTarget (n : Nat) : Nat.succ n = Nat.succ n := by
  cases Nat.succ _
  case zero => rfl
  case succ k => rfl

def coreElimHidden (n : Nat) : Nat := n
theorem coreElimOpaqueKey (n : Nat)
    (h : Nat.succ (coreElimHidden n) = Nat.succ (coreElimHidden n)) : h = h := by
  cases Nat.succ n
  case zero => rfl
  case succ k => rfl

inductive CoreElimIndexed : Nat -> Type where
  | intro (n : Nat) : CoreElimIndexed n
  | fixed : CoreElimIndexed 0
theorem coreElimCasesFixed (x : CoreElimIndexed 0) : x = x := by
  cases x
  case intro => rfl
  case fixed => rfl
theorem coreElimCasesCompound (n : Nat) (x : CoreElimIndexed (Nat.succ n)) : x = x := by
  cases x
  case intro => rfl
theorem coreElimInductionIndex (n : Nat) (x : CoreElimIndexed n) : x = x := by
  induction x
  case intro k => rfl
  case fixed => rfl

inductive CoreElimRepeated : Nat -> Nat -> Type where
  | intro (n : Nat) : CoreElimRepeated n n
  | fixed : CoreElimRepeated 0 0
theorem coreElimCasesRepeated (n : Nat) (x : CoreElimRepeated n n) : x = x := by
  cases x
  case intro => rfl
  case fixed => rfl

-- Native failed target preparation restores the original checked goal.
example (x : CoreElimIndexed 0) : x = x := by
  fail_if_success induction x
  rfl
example (n : Nat) (x : CoreElimIndexed (Nat.succ n)) : x = x := by
  fail_if_success induction x
  rfl
example (n : Nat) (x : CoreElimRepeated n n) : x = x := by
  fail_if_success induction x
  rfl
example (n : Nat) (h : Nat.succ n = Nat.succ n) : h = h := by
  fail_if_success cases Nat.succ n
  rfl
abbrev coreElimVisible (n : Nat) : Nat := n
example (n : Nat) (h : Nat.succ (coreElimVisible n) = Nat.succ (coreElimVisible n)) : h = h := by
  fail_if_success cases Nat.succ n
  rfl
#guard coreElimCasesComputed 0 == 0
#guard coreElimCasesComputed 7 == 7
#guard coreElimCasesLet 0 == 0
#guard coreElimCasesLet 8 == 8
#guard coreElimInductionComputed 0 == 1
#guard coreElimInductionComputed 7 == 8
#guard coreElimInductionLet 0 == 1
#guard coreElimInductionLet 8 == 9

inductive CoreElimFunction : Type where
  | leaf (value : Nat) : CoreElimFunction
  | node (children : Nat -> CoreElimFunction) : CoreElimFunction
noncomputable def coreElimFunctionFold (x : CoreElimFunction) : Nat := by
  induction x
  case leaf value => exact value
  case node children ih => exact ih 0
theorem coreElimFunctionLeaf : coreElimFunctionFold (CoreElimFunction.leaf 13) = 13 := by rfl
theorem coreElimFunctionNode : coreElimFunctionFold (CoreElimFunction.node (fun _ : Nat => CoreElimFunction.leaf 17)) = 17 := by rfl

inductive CoreElimFunctionIndexed : Nat -> Type where
  | leaf (n : Nat) : CoreElimFunctionIndexed n
  | node (children : (n : Nat) -> CoreElimFunctionIndexed n) : CoreElimFunctionIndexed 0
noncomputable def coreElimDependentFold (n : Nat) (x : CoreElimFunctionIndexed n) : Nat := by
  induction x
  case leaf k => exact k
  case node children ih => exact ih 19
theorem coreElimDependentFunctionNode : coreElimDependentFold 0 (CoreElimFunctionIndexed.node (fun n : Nat => CoreElimFunctionIndexed.leaf n)) = 19 := by rfl

inductive CoreElimRecursiveFunction : Type where
  | leaf (value : Nat) : CoreElimRecursiveFunction
  | node (children : Nat -> CoreElimRecursiveFunction) : CoreElimRecursiveFunction
def coreElimRecursiveField (key : Nat) (x : CoreElimRecursiveFunction) : Nat :=
  match x with
  | CoreElimRecursiveFunction.leaf value => value
  | CoreElimRecursiveFunction.node children => Nat.succ (coreElimRecursiveField key (children key))
theorem coreElimRecursiveFieldLeaf : coreElimRecursiveField 4 (CoreElimRecursiveFunction.leaf 13) = 13 := by rfl
theorem coreElimRecursiveFieldZero : coreElimRecursiveField 0 (CoreElimRecursiveFunction.node (fun n : Nat => CoreElimRecursiveFunction.leaf (Nat.succ n))) = 2 := by rfl
theorem coreElimRecursiveFieldSeven : coreElimRecursiveField 7 (CoreElimRecursiveFunction.node (fun n : Nat => CoreElimRecursiveFunction.leaf (Nat.succ n))) = 9 := by rfl

inductive CoreElimRecursivePredicate : Prop where
  | intro (children : Nat -> CoreElimRecursivePredicate) : CoreElimRecursivePredicate
def coreElimRecursivePredicateRebuild (x : CoreElimRecursivePredicate) : CoreElimRecursivePredicate :=
  match x with
  | CoreElimRecursivePredicate.intro children => coreElimRecursivePredicateRebuild (children 0)
theorem coreElimRecursivePredicateProof (x : CoreElimRecursivePredicate) : coreElimRecursivePredicateRebuild x = coreElimRecursivePredicateRebuild x := by rfl

#guard coreElimRecursiveField 4 (CoreElimRecursiveFunction.leaf 13) == 13
#guard coreElimRecursiveField 0 (CoreElimRecursiveFunction.node (fun n => CoreElimRecursiveFunction.leaf (Nat.succ n))) == 2
#guard coreElimRecursiveField 7 (CoreElimRecursiveFunction.node (fun n => CoreElimRecursiveFunction.leaf (Nat.succ n))) == 9
end CoreEliminationOracle

private def requireElimination (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError ("CORE-ELIMINATION: " ++ message))

private def eliminationReplay (declarations : List PsDeclaration) :
    IO Lean.Kernel.Environment := do
  let mut checked := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  requireElimination checked.constants.toList.isEmpty "initial kernel is not empty"
  let mut pending := declarations.reverse
  while !pending.isEmpty do
    let before := pending.length
    let mut deferred : List PsDeclaration := []
    for declaration in pending do
      let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
        PsKernelLean.tryPreludeDeclaration declarations checked declaration 2000000 20000
      match attempt with
      | .ok (.admitted next) => checked := next
      | .ok .deferred => deferred := declaration :: deferred
      | .error error => throw (IO.userError error.message)
    pending := deferred.reverse
    requireElimination (decide (pending.length < before))
      ("unresolved base dependencies: " ++ String.intercalate ", "
        (pending.map (psNameToString ∘ psDeclarationName)))
  let names := declarations.map (PsKernelLean.toLeanName ∘ psDeclarationName)
  let actual := checked.constants.toList.map Prod.fst
  requireElimination (names.length == names.eraseDups.length &&
      actual.length == names.length && actual.all names.contains)
    "independent base replay has a missing or extra declaration"
  return checked

private def eliminationAdmit (base : Lean.Kernel.Environment) (admissions : String) :
    IO Lean.Kernel.Environment := do
  let declarations ← match PsKernelLean.decodeCanonicalAdmissions admissions with
    | .ok value => pure value
    | .error error => throw (IO.userError error.message)
  let mut checked := base
  for declaration in declarations.toList do
    let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
      checked.addDeclCore 2000000 20000
        (PsKernelLean.psKernelWithDefinitionHeight checked declaration) none
    match attempt with
    | .ok next => checked := next
    | .error error =>
        throw (IO.userError ("CORE-ELIMINATION: kernel rejection: " ++
          PsKernelLean.kernelExceptionSummary error))
  return checked


private structure EliminationFixture where
  label : String
  leanSource : String
  psSource : String
  names : List String

private structure EliminationRefusal where
  label : String
  leanSource : String
  psSource : String
  expected : String

private def fixtures : List EliminationFixture := [
  { label := "computed cases", leanSource := "def coreElimCasesComputed (n : Nat) : Nat := by\n  cases Nat.succ n\n  case zero => exact 41\n  case succ k => exact k\ntheorem coreElimCasesComputedZero : coreElimCasesComputed 0 = 0 := by rfl\ntheorem coreElimCasesComputedSeven : coreElimCasesComputed 7 = 7 := by rfl\ntheorem coreElimComputedProof (n : Nat) : Nat.succ n = Nat.succ n := by\n  cases Nat.succ n\n  case zero => rfl\n  case succ k => rfl\n"
    psSource := "function coreElimCasesComputed(n: Nat): Nat := by {\n  cases Nat.succ(n)\n  case zero => exact 41\n  case succ k => exact k\n}\ntheorem coreElimCasesComputedZero: coreElimCasesComputed(0) = 0 := by { rfl }\ntheorem coreElimCasesComputedSeven: coreElimCasesComputed(7) = 7 := by { rfl }\ntheorem coreElimComputedProof(n: Nat): Nat.succ(n) = Nat.succ(n) := by {\n  cases Nat.succ(n)\n  case zero => rfl\n  case succ k => rfl\n}\n", names := ["coreElimCasesComputed", "coreElimCasesComputedZero", "coreElimCasesComputedSeven", "coreElimComputedProof"] },
  { label := "let cases", leanSource := "def coreElimCasesLet (n : Nat) : Nat := by\n  let value : Nat := Nat.succ n\n  cases value\n  case zero => exact 43\n  case succ k => exact k\ntheorem coreElimCasesLetZero : coreElimCasesLet 0 = 0 := by rfl\ntheorem coreElimCasesLetEight : coreElimCasesLet 8 = 8 := by rfl\ntheorem coreElimLetProof (n : Nat) : Nat.succ n = Nat.succ n := by\n  let value : Nat := Nat.succ n\n  change value = value\n  cases value\n  case zero => rfl\n  case succ k => rfl\n"
    psSource := "function coreElimCasesLet(n: Nat): Nat := by {\n  let value: Nat := Nat.succ(n)\n  cases value\n  case zero => exact 43\n  case succ k => exact k\n}\ntheorem coreElimCasesLetZero: coreElimCasesLet(0) = 0 := by { rfl }\ntheorem coreElimCasesLetEight: coreElimCasesLet(8) = 8 := by { rfl }\ntheorem coreElimLetProof(n: Nat): Nat.succ(n) = Nat.succ(n) := by {\n  let value: Nat := Nat.succ(n)\n  change value = value\n  cases value\n  case zero => rfl\n  case succ k => rfl\n}\n", names := ["coreElimCasesLet", "coreElimCasesLetZero", "coreElimCasesLetEight", "coreElimLetProof"] },
  { label := "computed induction", leanSource := "def coreElimInductionComputed (n : Nat) : Nat := by\n  induction Nat.succ n\n  case zero => exact 0\n  case succ k ih => exact Nat.succ ih\ntheorem coreElimInductionComputedZero : coreElimInductionComputed 0 = 1 := by rfl\ntheorem coreElimInductionComputedSeven : coreElimInductionComputed 7 = 8 := by rfl\ntheorem coreElimInductionComputedProof (n : Nat) : True := by\n  induction Nat.succ n\n  case zero => constructor\n  case succ k ih => exact ih\n"
    psSource := "function coreElimInductionComputed(n: Nat): Nat := by {\n  induction Nat.succ(n)\n  case zero => exact 0\n  case succ k ih => exact Nat.succ(ih)\n}\ntheorem coreElimInductionComputedZero: coreElimInductionComputed(0) = 1 := by { rfl }\ntheorem coreElimInductionComputedSeven: coreElimInductionComputed(7) = 8 := by { rfl }\ntheorem coreElimInductionComputedProof(n: Nat): True := by {\n  induction Nat.succ(n)\n  case zero => constructor\n  case succ k ih => exact ih\n}\n", names := ["coreElimInductionComputed", "coreElimInductionComputedZero", "coreElimInductionComputedSeven", "coreElimInductionComputedProof"] },
  { label := "let induction", leanSource := "def coreElimInductionLet (n : Nat) : Nat := by\n  let value : Nat := Nat.succ n\n  induction value\n  case zero => exact 0\n  case succ k ih => exact Nat.succ ih\ntheorem coreElimInductionLetZero : coreElimInductionLet 0 = 1 := by rfl\ntheorem coreElimInductionLetEight : coreElimInductionLet 8 = 9 := by rfl\ntheorem coreElimInductionLetProof (n : Nat) : True := by\n  let value : Nat := Nat.succ n\n  induction value\n  case zero => constructor\n  case succ k ih => exact ih\n"
    psSource := "function coreElimInductionLet(n: Nat): Nat := by {\n  let value: Nat := Nat.succ(n)\n  induction value\n  case zero => exact 0\n  case succ k ih => exact Nat.succ(ih)\n}\ntheorem coreElimInductionLetZero: coreElimInductionLet(0) = 1 := by { rfl }\ntheorem coreElimInductionLetEight: coreElimInductionLet(8) = 9 := by { rfl }\ntheorem coreElimInductionLetProof(n: Nat): True := by {\n  let value: Nat := Nat.succ(n)\n  induction value\n  case zero => constructor\n  case succ k ih => exact ih\n}\n", names := ["coreElimInductionLet", "coreElimInductionLetZero", "coreElimInductionLetEight", "coreElimInductionLetProof"] },
  { label := "complete generalized telescope", leanSource := "theorem coreElimComputedDependent (n : Nat) :\n    forall (h : Nat.succ n = Nat.succ n), h = h := by\n  cases Nat.succ n\n  case zero =>\n    intro h\n    rfl\n  case succ k =>\n    intro h\n    rfl\ntheorem coreElimShadowedBinder (n : Nat) : forall (k : Nat), Nat.succ k = Nat.succ k := by\n  cases Nat.succ n\n  case zero =>\n    intro k\n    rfl\n  case succ k =>\n    intro other\n    rfl\ntheorem coreElimInferredTarget (n : Nat) : Nat.succ n = Nat.succ n := by\n  cases Nat.succ _\n  case zero => rfl\n  case succ k => rfl\n"
    psSource := "theorem coreElimComputedDependent(n: Nat): forall (h: Nat.succ(n) = Nat.succ(n)), h = h := by {\n  cases Nat.succ(n)\n  case zero => intro h; rfl\n  case succ k => intro h; rfl\n}\ntheorem coreElimShadowedBinder(n: Nat): forall (k: Nat), Nat.succ(k) = Nat.succ(k) := by {\n  cases Nat.succ(n)\n  case zero => intro k; rfl\n  case succ k => intro other; rfl\n}\ntheorem coreElimInferredTarget(n: Nat): Nat.succ(n) = Nat.succ(n) := by {\n  cases Nat.succ(_)\n  case zero => rfl\n  case succ k => rfl\n}\n", names := ["coreElimComputedDependent", "coreElimShadowedBinder", "coreElimInferredTarget"] },
  { label := "native keyed transparency", leanSource := "def coreElimHidden (n : Nat) : Nat := n\ntheorem coreElimOpaqueKey (n : Nat)\n    (h : Nat.succ (coreElimHidden n) = Nat.succ (coreElimHidden n)) : h = h := by\n  cases Nat.succ n\n  case zero => rfl\n  case succ k => rfl\n"
    psSource := "function coreElimHidden(n: Nat): Nat := n\ntheorem coreElimOpaqueKey(n: Nat, h: Nat.succ(coreElimHidden(n)) = Nat.succ(coreElimHidden(n))): h = h := by {\n  cases Nat.succ(n)\n  case zero => rfl\n  case succ k => rfl\n}\n", names := ["coreElimHidden", "coreElimOpaqueKey"] },
  { label := "cases fixed and computed indices; induction variable index", leanSource := "inductive CoreElimIndexed : Nat -> Type where\n  | intro (n : Nat) : CoreElimIndexed n\n  | fixed : CoreElimIndexed 0\ntheorem coreElimCasesFixed (x : CoreElimIndexed 0) : x = x := by\n  cases x\n  case intro => rfl\n  case fixed => rfl\ntheorem coreElimCasesCompound (n : Nat) (x : CoreElimIndexed (Nat.succ n)) : x = x := by\n  cases x\n  case intro => rfl\ntheorem coreElimInductionIndex (n : Nat) (x : CoreElimIndexed n) : x = x := by\n  induction x\n  case intro k => rfl\n  case fixed => rfl\n"
    psSource := "inductive CoreElimIndexed: Nat -> Type where { | intro(n: Nat): CoreElimIndexed(n) | fixed: CoreElimIndexed(0) }\ntheorem coreElimCasesFixed(x: CoreElimIndexed(0)): x = x := by {\n  cases x\n  case intro => rfl\n  case fixed => rfl\n}\ntheorem coreElimCasesCompound(n: Nat, x: CoreElimIndexed(Nat.succ(n))): x = x := by {\n  cases x\n  case intro => rfl\n}\ntheorem coreElimInductionIndex(n: Nat, x: CoreElimIndexed(n)): x = x := by {\n  induction x\n  case intro k => rfl\n  case fixed => rfl\n}\n", names := ["CoreElimIndexed", "coreElimCasesFixed", "coreElimCasesCompound", "coreElimInductionIndex"] },
  { label := "cases repeated indices", leanSource := "inductive CoreElimRepeated : Nat -> Nat -> Type where\n  | intro (n : Nat) : CoreElimRepeated n n\n  | fixed : CoreElimRepeated 0 0\ntheorem coreElimCasesRepeated (n : Nat) (x : CoreElimRepeated n n) : x = x := by\n  cases x\n  case intro => rfl\n  case fixed => rfl\n"
    psSource := "inductive CoreElimRepeated: Nat -> Nat -> Type where { | intro(n: Nat): CoreElimRepeated(n, n) | fixed: CoreElimRepeated(0, 0) }\ntheorem coreElimCasesRepeated(n: Nat, x: CoreElimRepeated(n, n)): x = x := by {\n  cases x\n  case intro => rfl\n  case fixed => rfl\n}\n", names := ["CoreElimRepeated", "coreElimCasesRepeated"] },
  { label := "positive recursive function field and computed induction hypothesis", leanSource := "inductive CoreElimFunction : Type where\n  | leaf (value : Nat) : CoreElimFunction\n  | node (children : Nat -> CoreElimFunction) : CoreElimFunction\ndef coreElimFunctionFold (x : CoreElimFunction) : Nat := by\n  induction x\n  case leaf value => exact value\n  case node children ih => exact ih 0\ntheorem coreElimFunctionLeaf : coreElimFunctionFold (CoreElimFunction.leaf 13) = 13 := by rfl\ntheorem coreElimFunctionNode : coreElimFunctionFold (CoreElimFunction.node (fun _ : Nat => CoreElimFunction.leaf 17)) = 17 := by rfl\n"
    psSource := "inductive CoreElimFunction: Type where {\n  | leaf(value: Nat): CoreElimFunction\n  | node(children: Nat -> CoreElimFunction): CoreElimFunction\n}\nfunction coreElimFunctionFold(x: CoreElimFunction): Nat := by {\n  induction x\n  case leaf value => exact value\n  case node children ih => exact ih(0)\n}\ntheorem coreElimFunctionLeaf: coreElimFunctionFold(CoreElimFunction.leaf(13)) = 13 := by { rfl }\ntheorem coreElimFunctionNode: coreElimFunctionFold(CoreElimFunction.node(fun (_: Nat) => CoreElimFunction.leaf(17))) = 17 := by { rfl }\n", names := ["CoreElimFunction", "coreElimFunctionFold", "coreElimFunctionLeaf", "coreElimFunctionNode"] },
  { label := "dependent recursive function field telescope and indexed induction", leanSource := "inductive CoreElimFunctionIndexed : Nat -> Type where\n  | leaf (n : Nat) : CoreElimFunctionIndexed n\n  | node (children : (n : Nat) -> CoreElimFunctionIndexed n) : CoreElimFunctionIndexed 0\ndef coreElimDependentFold (n : Nat) (x : CoreElimFunctionIndexed n) : Nat := by\n  induction x\n  case leaf k => exact k\n  case node children ih => exact ih 19\ntheorem coreElimDependentFunctionNode : coreElimDependentFold 0 (CoreElimFunctionIndexed.node (fun n : Nat => CoreElimFunctionIndexed.leaf n)) = 19 := by rfl\n"
    psSource := "inductive CoreElimFunctionIndexed: Nat -> Type where {\n  | leaf(n: Nat): CoreElimFunctionIndexed(n)\n  | node(children: (n: Nat) -> CoreElimFunctionIndexed(n)): CoreElimFunctionIndexed(0)\n}\nfunction coreElimDependentFold(n: Nat, x: CoreElimFunctionIndexed(n)): Nat := by {\n  induction x\n  case leaf k => exact k\n  case node children ih => exact ih(19)\n}\ntheorem coreElimDependentFunctionNode: coreElimDependentFold(0, CoreElimFunctionIndexed.node(fun (n: Nat) => CoreElimFunctionIndexed.leaf(n))) = 19 := by { rfl }\n", names := ["CoreElimFunctionIndexed", "coreElimDependentFold", "coreElimDependentFunctionNode"] },
  { label := "source recursion on actual positive function-field applications", leanSource := "inductive CoreElimRecursiveFunction : Type where\n  | leaf (value : Nat) : CoreElimRecursiveFunction\n  | node (children : Nat -> CoreElimRecursiveFunction) : CoreElimRecursiveFunction\ndef coreElimRecursiveField (key : Nat) (x : CoreElimRecursiveFunction) : Nat :=\n  match x with\n  | CoreElimRecursiveFunction.leaf value => value\n  | CoreElimRecursiveFunction.node children => Nat.succ (coreElimRecursiveField key (children key))\ntheorem coreElimRecursiveFieldLeaf : coreElimRecursiveField 4 (CoreElimRecursiveFunction.leaf 13) = 13 := by rfl\ntheorem coreElimRecursiveFieldZero : coreElimRecursiveField 0 (CoreElimRecursiveFunction.node (fun n : Nat => CoreElimRecursiveFunction.leaf (Nat.succ n))) = 2 := by rfl\ntheorem coreElimRecursiveFieldSeven : coreElimRecursiveField 7 (CoreElimRecursiveFunction.node (fun n : Nat => CoreElimRecursiveFunction.leaf (Nat.succ n))) = 9 := by rfl\n"
    psSource := "inductive CoreElimRecursiveFunction: Type where {\n  | leaf(value: Nat): CoreElimRecursiveFunction\n  | node(children: Nat -> CoreElimRecursiveFunction): CoreElimRecursiveFunction\n}\nfunction coreElimRecursiveField(key: Nat, x: CoreElimRecursiveFunction): Nat := match x {\n  | CoreElimRecursiveFunction.leaf value => value\n  | CoreElimRecursiveFunction.node children => Nat.succ(coreElimRecursiveField(key, children(key)))\n}\ntheorem coreElimRecursiveFieldLeaf: coreElimRecursiveField(4, CoreElimRecursiveFunction.leaf(13)) = 13 := by { rfl }\ntheorem coreElimRecursiveFieldZero: coreElimRecursiveField(0, CoreElimRecursiveFunction.node(fun (n: Nat) => CoreElimRecursiveFunction.leaf(Nat.succ(n)))) = 2 := by { rfl }\ntheorem coreElimRecursiveFieldSeven: coreElimRecursiveField(7, CoreElimRecursiveFunction.node(fun (n: Nat) => CoreElimRecursiveFunction.leaf(Nat.succ(n)))) = 9 := by { rfl }\n", names := ["CoreElimRecursiveFunction", "coreElimRecursiveField", "coreElimRecursiveFieldLeaf", "coreElimRecursiveFieldZero", "coreElimRecursiveFieldSeven"] },
  { label := "source recursive predicate field stays in Prop", leanSource := "inductive CoreElimRecursivePredicate : Prop where\n  | intro (children : Nat -> CoreElimRecursivePredicate) : CoreElimRecursivePredicate\ndef coreElimRecursivePredicateRebuild (x : CoreElimRecursivePredicate) : CoreElimRecursivePredicate :=\n  match x with\n  | CoreElimRecursivePredicate.intro children => coreElimRecursivePredicateRebuild (children 0)\ntheorem coreElimRecursivePredicateProof (x : CoreElimRecursivePredicate) : coreElimRecursivePredicateRebuild x = coreElimRecursivePredicateRebuild x := by rfl\n"
    psSource := "inductive CoreElimRecursivePredicate: Prop where { | intro(children: Nat -> CoreElimRecursivePredicate): CoreElimRecursivePredicate }\nfunction coreElimRecursivePredicateRebuild(x: CoreElimRecursivePredicate): CoreElimRecursivePredicate := match x {\n  | CoreElimRecursivePredicate.intro children => coreElimRecursivePredicateRebuild(children(0))\n}\ntheorem coreElimRecursivePredicateProof(x: CoreElimRecursivePredicate): coreElimRecursivePredicateRebuild(x) = coreElimRecursivePredicateRebuild(x) := by { rfl }\n", names := ["CoreElimRecursivePredicate", "coreElimRecursivePredicateRebuild", "coreElimRecursivePredicateProof"] } ]

private def refusals : List EliminationRefusal := [
  { label := "induction fixed index", leanSource := "inductive CoreElimIndexed : Nat -> Type where\n  | intro (n : Nat) : CoreElimIndexed n\n  | fixed : CoreElimIndexed 0\ntheorem bad (x : CoreElimIndexed 0) : x = x := by\n  induction x\n"
    psSource := "inductive CoreElimIndexed: Nat -> Type where { | intro(n: Nat): CoreElimIndexed(n) | fixed: CoreElimIndexed(0) }\ntheorem bad(x: CoreElimIndexed(0)): x = x := by { induction x }\n", expected := "proof:induction target indices must be variables" },
  { label := "induction computed index", leanSource := "inductive CoreElimIndexed : Nat -> Type where\n  | intro (n : Nat) : CoreElimIndexed n\n  | fixed : CoreElimIndexed 0\ntheorem bad (n : Nat) (x : CoreElimIndexed (Nat.succ n)) : x = x := by\n  induction x\n"
    psSource := "inductive CoreElimIndexed: Nat -> Type where { | intro(n: Nat): CoreElimIndexed(n) | fixed: CoreElimIndexed(0) }\ntheorem bad(n: Nat, x: CoreElimIndexed(Nat.succ(n))): x = x := by { induction x }\n", expected := "proof:induction target indices must be variables" },
  { label := "induction repeated index", leanSource := "inductive CoreElimRepeated : Nat -> Nat -> Type where\n  | intro (n : Nat) : CoreElimRepeated n n\n  | fixed : CoreElimRepeated 0 0\ntheorem bad (n : Nat) (x : CoreElimRepeated n n) : x = x := by\n  induction x\n"
    psSource := "inductive CoreElimRepeated: Nat -> Nat -> Type where { | intro(n: Nat): CoreElimRepeated(n, n) | fixed: CoreElimRepeated(0, 0) }\ntheorem bad(n: Nat, x: CoreElimRepeated(n, n)): x = x := by { induction x }\n", expected := "proof:induction target and indices must be distinct" },
  { label := "fixed dependent hypothesis cannot be relabeled", leanSource := "theorem bad (n : Nat) (h : Nat.succ n = Nat.succ n) : h = h := by\n  cases Nat.succ n\n"
    psSource := "theorem bad(n: Nat, h: Nat.succ(n) = Nat.succ(n)): h = h := by { cases Nat.succ(n) }\n", expected := "infer:application" },
  { label := "keyed reducible definition requires complete telescope", leanSource := "abbrev coreElimVisible (n : Nat) : Nat := n\ntheorem bad (n : Nat) (h : Nat.succ (coreElimVisible n) = Nat.succ (coreElimVisible n)) : h = h := by\n  cases Nat.succ n\n"
    psSource := "abbrev coreElimVisible(n: Nat): Nat := n\ntheorem bad(n: Nat, h: Nat.succ(coreElimVisible(n)) = Nat.succ(coreElimVisible(n))): h = h := by { cases Nat.succ(n) }\n", expected := "infer:application" },
  { label := "computed cases cannot omit proof branches", leanSource := "theorem bad (n : Nat) : Nat.succ n = Nat.succ n := by\n  cases Nat.succ n\n"
    psSource := "theorem bad(n: Nat): Nat.succ(n) = Nat.succ(n) := by { cases Nat.succ(n) }\n", expected := "proof:unsolved goals" },
  { label := "computed branch value must have checked type", leanSource := "def bad (n : Nat) : Nat := by\n  cases Nat.succ n\n  case zero => exact True.intro\n  case succ k => exact k\n"
    psSource := "function bad(n: Nat): Nat := by {\n  cases Nat.succ(n)\n  case zero => exact True.intro\n  case succ k => exact k\n}\n", expected := "type" },
  { label := "cases cannot expose an induction hypothesis", leanSource := "def bad (n : Nat) : Nat := by\n  cases Nat.succ n\n  case zero => exact 0\n  case succ k ih => exact ih\n"
    psSource := "function bad(n: Nat): Nat := by {\n  cases Nat.succ(n)\n  case zero => exact 0\n  case succ k ih => exact ih\n}\n", expected := "proof:too many case binder names" },
  { label := "negative recursive function-field domain", leanSource := "inductive CoreElimNegativeFunction : Type where\n  | node (children : CoreElimNegativeFunction -> Nat) : CoreElimNegativeFunction\n"
    psSource := "inductive CoreElimNegativeFunction: Type where { | node(children: CoreElimNegativeFunction -> Nat): CoreElimNegativeFunction }\n", expected := "data:recursive family occurs in a function-field domain" },
  { label := "negative recursive domain below function telescope", leanSource := "inductive CoreElimNegativeNestedFunction : Type where\n  | node (children : Nat -> CoreElimNegativeNestedFunction -> Nat) : CoreElimNegativeNestedFunction\n"
    psSource := "inductive CoreElimNegativeNestedFunction: Type where { | node(children: Nat -> CoreElimNegativeNestedFunction -> Nat): CoreElimNegativeNestedFunction }\n", expected := "data:recursive family occurs in a function-field domain" },
  { label := "nonuniform recursive function-field parameters", leanSource := "inductive CoreElimNonuniformFunction (A : Type) : Type where\n  | node (children : Nat -> CoreElimNonuniformFunction Nat) : CoreElimNonuniformFunction A\n"
    psSource := "inductive CoreElimNonuniformFunction(A: Type): Type where { | node(children: Nat -> CoreElimNonuniformFunction(Nat)): CoreElimNonuniformFunction(A) }\n", expected := "data:constructor parameters must remain uniform" },
  { label := "source applied function is not a registered strict field", leanSource := "inductive CoreElimRecursiveFunction : Type where\n  | leaf (value : Nat) : CoreElimRecursiveFunction\n  | node (children : Nat -> CoreElimRecursiveFunction) : CoreElimRecursiveFunction\ndef bad (foreign : Nat -> CoreElimRecursiveFunction) (x : CoreElimRecursiveFunction) : Nat :=\n  match x with\n  | CoreElimRecursiveFunction.leaf value => value\n  | CoreElimRecursiveFunction.node children => bad foreign (foreign 0)\n"
    psSource := "inductive CoreElimRecursiveFunction: Type where {\n  | leaf(value: Nat): CoreElimRecursiveFunction\n  | node(children: Nat -> CoreElimRecursiveFunction): CoreElimRecursiveFunction\n}\nfunction bad(foreign: Nat -> CoreElimRecursiveFunction, x: CoreElimRecursiveFunction): Nat := match x {\n  | CoreElimRecursiveFunction.leaf value => value\n  | CoreElimRecursiveFunction.node children => bad(foreign, foreign(0))\n}\n", expected := "structural:decrease" },
  { label := "automatic source predicate function-field recursion cannot eliminate to Type", leanSource := "inductive CoreElimRecursivePredicate : Prop where\n  | intro (children : Nat -> CoreElimRecursivePredicate) : CoreElimRecursivePredicate\ndef bad (x : CoreElimRecursivePredicate) : Nat :=\n  match x with\n  | CoreElimRecursivePredicate.intro children => bad (children 0)\n"
    psSource := "inductive CoreElimRecursivePredicate: Prop where { | intro(children: Nat -> CoreElimRecursivePredicate): CoreElimRecursivePredicate }\nfunction bad(x: CoreElimRecursivePredicate): Nat := match x {\n  | CoreElimRecursivePredicate.intro children => bad(children(0))\n}\n", expected := "structural:decrease" } ]

private def refusalKind : PsElabError → String
  | .atDeclaration _ error | .atContext _ error => refusalKind error
  | .typeMismatch => "type"
  | .structuralRecursionNotDecreasing => "structural:decrease"
  | .infer .applicationTypeMismatch => "infer:application"
  | .proof message => "proof:" ++ message
  | .data message => "data:" ++ message
  | error => psCompilerPscv0ElabError error

private def prepareElimination (profile : PsCompilerProfileContext)
    (kind : PsCompilerSourceKind) (source : String) : IO PsCompilerEnginePreparationOutput := do
  match psCompilerParsePscv0 source kind with
  | .ok _ => pure ()
  | .error error => throw (IO.userError ("CORE-ELIMINATION: selected parser: " ++ error))
  match psCompilerEnginePreparePscv0WithOutput profile kind source with
  | .ok output => pure output
  | .error error => throw (IO.userError ("CORE-ELIMINATION: " ++ psCompilerPscv0Error error))

private def checkEliminationRefusal (profile : PsCompilerProfileContext)
    (fixture : EliminationRefusal) (kind : PsCompilerSourceKind) (source : String) : IO Unit := do
  match psCompilerParsePscv0 source kind with
  | .ok _ => pure ()
  | .error error => throw (IO.userError (fixture.label ++ " did not parse: " ++ error))
  match psCompilerEnginePreparePscv0WithOutput profile kind source with
  | .error (.elaboration error) =>
      requireElimination (refusalKind error == fixture.expected)
        (fixture.label ++ " refused at wrong owner: " ++ refusalKind error)
  | .error error => throw (IO.userError (fixture.label ++ " refused at wrong phase: " ++ psCompilerPscv0Error error))
  | .ok _ => throw (IO.userError (fixture.label ++ " was incorrectly accepted"))

def main : IO Unit := do
  requireElimination (Lean.versionString == "4.35.0" &&
    Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc") "native pin changed"
  let environment ← match psCompilerSourceCandidateEnvironment with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  let declarations := psCoreFoundationCandidateDeclarations
  requireElimination (declarations.length == 92 && environment.declarations.length == 92)
    "Foundation context roster changed"
  requireElimination (!(declarations.any fun declaration =>
    match declaration with | .axiomDecl .. | .partialDecl .. => true | _ => false))
    "Foundation context acquired an assumption or partial body"
  let checkedBase ← eliminationReplay declarations
  let profile : PsCompilerProfileContext := {
    baseEnvironment := environment, runtimePrelude := fun _ _ => [] }
  let mut records : List Lean.Json := []
  for fixture in fixtures do
    let mut outputs : List PsCompilerEnginePreparationOutput := []
    for (kind, source) in [(PsCompilerSourceKind.lean, fixture.leanSource),
        (.proofScript, fixture.psSource)] do
      let output ← prepareElimination profile kind source
      requireElimination (psStandardSnapshotPayload output.prepared.profile.baseEnvironment ==
        psStandardSnapshotPayload environment) "caller Foundation context changed"
      requireElimination (!(output.prepared.declarations.any fun declaration =>
        match declaration with | .axiomDecl .. | .partialDecl .. => true | _ => false))
        (fixture.label ++ " introduced an axiom or partial declaration")
      requireElimination output.prepared.noncomputableNames.isEmpty
        (fixture.label ++ " introduced noncomputable execution")
      let canonical ← match psCompilerEngineAdmissionsFromPrepared output.prepared with
        | .ok value => pure value
        | .error error => throw (IO.userError (psCompilerPscv0Error error))
      requireElimination (canonical == output.admissions) "canonical admissions changed"
      let admitted ← eliminationAdmit checkedBase output.admissions
      for name in fixture.names do
        requireElimination (output.prepared.declarations.any fun declaration =>
            psNameEq (psDeclarationName declaration) (psRootName name))
          (fixture.label ++ " missing prepared declaration " ++ name)
        requireElimination (admitted.find? (PsKernelLean.toLeanName (psRootName name))).isSome
          (fixture.label ++ " missing independently admitted declaration " ++ name)
      outputs := outputs ++ [output]
    let [leanOutput, psOutput] := outputs
      | throw (IO.userError "CORE-ELIMINATION: paired result count changed")
    requireElimination (leanOutput.admissions == psOutput.admissions)
      (fixture.label ++ " selected canonical pair differs")
    records := records ++ [Lean.Json.mkObj [
      ("label", Lean.toJson fixture.label),
      ("leanSourceSHA256", Lean.toJson (psStandardSnapshotSHA256 fixture.leanSource)),
      ("proofScriptSourceSHA256", Lean.toJson (psStandardSnapshotSHA256 fixture.psSource)),
      ("preparedDeclarations", Lean.toJson leanOutput.prepared.declarations.length),
      ("canonicalBytes", Lean.toJson leanOutput.admissions.utf8ByteSize),
      ("canonicalSHA256", Lean.toJson (psStandardSnapshotSHA256 leanOutput.admissions)),
      ("canonicalPairEqual", Lean.toJson true),
      ("independentlyAdmitted", Lean.toJson true)]]
  for fixture in refusals do
    checkEliminationRefusal profile fixture .lean fixture.leanSource
    checkEliminationRefusal profile fixture .proofScript fixture.psSource
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-core-elimination-qualification/1" : String)),
    ("nativeVersion", Lean.toJson Lean.versionString),
    ("nativeCommit", Lean.toJson Lean.githash),
    ("baseDeclarations", Lean.toJson declarations.length),
    ("basePayloadSHA256", Lean.toJson (psStandardSnapshotSHA256 (psStandardSnapshotPayload environment))),
    ("axioms", Lean.toJson ([] : List String)),
    ("kernelTrustLevel", Lean.toJson (0 : Nat)),
    ("maxHeartbeatsPerDeclaration", Lean.toJson (2000000 : Nat)),
    ("maxRecDepthPerDeclaration", Lean.toJson (20000 : Nat)),
    ("positiveSourceProjects", Lean.toJson (2 * fixtures.length)),
    ("ownedRefusals", Lean.toJson (2 * refusals.length)),
    ("nativeValueObservations", Lean.toJson (11 : Nat)),
    ("nativeKernelReductionObservations", Lean.toJson (3 : Nat)),
    ("nativeRefusalControls", Lean.toJson (5 : Nat)),
    ("cases", Lean.Json.arr records.toArray),
    ("completeCoreProfileQualified", Lean.toJson false),
    ("backendExecutionQualified", Lean.toJson false),
    ("compilerSelfhostQualified", Lean.toJson false)]).compress
  IO.println "PSCV0_CORE_ELIMINATION: PASS 24 paired source projects and independent canonical admissions; 26 owned refusals; pinned native sources, eleven executable observations, three primitive kernel reductions and five target-rule refusals"
