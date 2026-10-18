import Ps.Host.NativeV7

namespace M3InputParityOracle
namespace Shared
section
variable (seed : Nat)
def addSeed (n : Nat) : Nat := Nat.add seed n
end
def withDefault (n : Nat := 3) : Nat := Nat.succ n
end Shared
open Shared
def m3parity (flag : Bool) : UInt64 :=
  UInt64.ofNat (if flag then addSeed 8 5 else withDefault 3)
def grouped {T : Type} {first value : T} := value
example : @grouped Nat 3 4 = 4 := rfl
/-- error: type expected -/
#guard_msgs (error, drop warning, substring := true) in
def shadow {T : Type} {T value : T} := value
/-- error: type expected -/
#guard_msgs (error, drop warning, substring := true) in
def lambdaShadow : (T : Type) → T → T → T := fun (T : Type) (T value : T) => value
/-- error: type expected -/
#guard_msgs (error, drop warning, substring := true) in
def globalShadow : Nat → Nat → Nat := fun (Nat value : Nat) => value
example : m3parity false = 4 := rfl
example : m3parity true = 13 := rfl
structure ParityBox where
  value : Nat
  deriving Inhabited, BEq
inductive ParityMaybe where
  | none
  | some (value : Nat)
  deriving Inhabited, BEq
class Sized (A : Type) where
  size : A → Nat
@[default_instance 200]
instance (priority := high) sizedNat : Sized Nat where
  size n := n
def m3data (flag : Bool) : UInt64 :=
  let b := ParityBox.mk (keep (if flag then 6 else 9))
  let packed := ParityMaybe.some (Sized.size b.value)
  UInt64.ofNat (match packed with
    | ParityMaybe.none => 0
    | ParityMaybe.some value => if b == b then value else 0)

where
  keep (n : Nat) : Nat :=
    match n with
    | 0 => 0
    | Nat.succ k => Nat.succ (keep k)
  termination_by n
  decreasing_by exact Nat.lt_succ_self k

example : m3data true = 6 := by simp [m3data, m3data.keep]; rfl
example : m3data false = 9 := by simp [m3data, m3data.keep]; rfl
def m3control (flag : Bool) : UInt64 :=
  let (left, right) : Nat × Nat := (2, 3)
  let amount : Option Nat := do
    let (x, y) : Nat × Nat ← Option.some (left, right)
    if !flag then
      if let .some n := Option.some (x + y) then
        return n
    else if flag then
      return 7
    return 11
  let extra : Id Nat := do { let n := 1; return n; }
  let extraValue : Nat := extra
  let extraApplied : Nat := (fun (f : Nat → Nat) => f extraValue) fun (n : Nat) => n
  UInt64.ofNat (if let .some n := amount then n + extraApplied else 0)

example : m3control false = 6 := rfl
example : m3control true = 8 := rfl
def doArgument : Option Nat := (fun (value : Option Nat) => value) do return 1
example : doArgument = Option.some 1 := rfl
mutual
def parityFirst {A : Type} (a : A) (n : Nat) : Nat → A :=
  fun (k : Nat) => match n with
    | 0 => a
    | Nat.succ m => let kept := a; paritySecond m A kept k
termination_by n
def paritySecond (n : Nat) (B : Type) (b : B) : Nat → B :=
  fun (k : Nat) => match n with
    | 0 => b
    | Nat.succ m => parityThird m b k
termination_by n
def parityThird {C : Type} (n : Nat) (c : C) : Nat → C :=
  fun (k : Nat) => match n with
    | 0 => c
    | Nat.succ m => parityFirst c m k
termination_by n
end
def m3mutual (flag : Bool) : UInt64 :=
  UInt64.ofNat (parityFirst (if flag then 7 else 11) (if flag then 6 else 4) 2)

example : m3mutual true = 7 := by simp [m3mutual, parityFirst, paritySecond, parityThird]
example : m3mutual false = 11 := by simp [m3mutual, parityFirst, paritySecond, parityThird]
partial def parityPartial (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | Nat.succ k => Nat.succ (parityPartial k)
def parityFixed (seed : Nat) (n : Nat) : Nat :=
  match n with
  | 0 => seed
  | Nat.succ k => parityFixed seed k
partial_fixpoint
def m3strategies (flag : Bool) : UInt64 :=
  UInt64.ofNat (parityPartial (if flag then 4 else 3) +
    100 * parityFixed (if flag then 7 else 9) (if flag then 3 else 4))

instance parityFunctionHash {A : Type} : Hashable (forall (i : Nat), i = i → A) where
  hash (_ : forall (i : Nat), i = i → A) := UInt64.ofNat 17
inductive ParityBranch where
  | leaf (value : Nat)
  | node (children : forall (i : Nat), i = i → ParityBranch)
  deriving Hashable
def branchFold (tree : ParityBranch) : Nat :=
  match tree with
  | ParityBranch.leaf value => value
  | ParityBranch.node children => Nat.succ (branchFold (children 2 (Eq.refl 2)))
mutual
def branchFirst (bias : Nat) (tree : ParityBranch) : Nat :=
  match tree with
  | ParityBranch.leaf value => bias + value
  | ParityBranch.node children => branchSecond (children 3 (Eq.refl 3)) (bias + 1)
def branchSecond (tree : ParityBranch) (bias : Nat) : Nat :=
  match tree with
  | ParityBranch.leaf value => bias + value
  | ParityBranch.node children => branchFirst (bias + 2) (children 4 (Eq.refl 4))
end
noncomputable def branchByRec (tree : ParityBranch) : Nat :=
  ParityBranch.rec (motive := fun (_ : ParityBranch) => Nat)
    (fun (value : Nat) => value)
    (fun (children : forall (i : Nat), i = i → ParityBranch) (ih : forall (i : Nat), i = i → Nat) =>
      Nat.succ (ih 5 (Eq.refl 5))) tree
theorem branchRefl (tree : ParityBranch) : branchFold tree = branchFold tree :=
  ParityBranch.rec (motive := fun (t : ParityBranch) => branchFold t = branchFold t)
    (fun (value : Nat) => Eq.refl value)
    (fun (children : forall (i : Nat), i = i → ParityBranch)
      (ih : forall (i : Nat) (h : i = i), branchFold (children i h) = branchFold (children i h)) =>
      congrArg Nat.succ (ih 2 (Eq.refl 2))) tree
-- Lean's code generator does not execute this primitive recursor. Retain its
-- checked definition and prove the separately executable structural oracle.
def branchByRecExec (tree : ParityBranch) : Nat :=
  match tree with
  | ParityBranch.leaf value => value
  | ParityBranch.node children => Nat.succ (branchByRecExec (children 5 (Eq.refl 5)))

theorem branchByRec_agrees (tree : ParityBranch) : branchByRec tree = branchByRecExec tree := by
  induction tree with
  | leaf value => rfl
  | node children ih => exact congrArg Nat.succ (ih 5 (Eq.refl 5))

def m3fields (flag : Bool) : UInt64 :=
  let seed := if flag then 7 else 11
  let tree := ParityBranch.node (fun (i : Nat) (h : i = i) =>
    ParityBranch.node (fun (j : Nat) (g : j = j) => ParityBranch.leaf (seed + i + j)))
  let mark : Nat := if Hashable.hash tree == mixHash (UInt64.ofNat 1) (UInt64.ofNat 17) then 0 else 1
  UInt64.ofNat (branchFold tree + 100 * branchFirst 3 tree + 10000 * branchByRecExec tree + mark)

example : m3fields true = 192013 := rfl
example : m3fields false = 232417 := rfl

end M3InputParityOracle

namespace M3InputParity
private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (value : Except String α) : IO α :=
  match value with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def leanSource : String :=
  "namespace Shared\nsection\nvariable (seed : Nat)\n" ++
  "def addSeed (n : Nat) : Nat := Nat.add seed n\nend\n" ++
  "def withDefault (n : Nat := 3) : Nat := Nat.succ n\nend Shared\nopen Shared\n" ++
  "def m3parity (flag : Bool) : UInt64 := UInt64.ofNat (if flag then addSeed 8 5 else withDefault 3)\n"

private def psSource : String :=
  "namespace Shared\nsection\nvariable (seed: Nat)\n" ++
  "function addSeed(n: Nat): Nat := Nat.add(seed, n)\nend\n" ++
  "function withDefault(n: Nat := 3): Nat := Nat.succ(n)\nend Shared\nopen Shared\n" ++
  "function m3parity(flag: Bool): UInt64 := UInt64.ofNat(if (flag) { addSeed(8, 5) } else { withDefault(3) })\n"

private def dataLeanSource : String :=
  "structure ParityBox where\n  value : Nat\n  deriving Inhabited, BEq\ninductive ParityMaybe where\n  | none\n  | some (value : Nat)\n  deriving Inhabited, BEq\nclass Sized (A : Type) where\n  size : A → Nat\n@[default_instance 200]\ninstance (priority := high) sizedNat : Sized Nat where\n  size n := n\ndef m3data (flag : Bool) : UInt64 :=\n  let b := ParityBox.mk (keep (if flag then 6 else 9))\n  let packed := ParityMaybe.some (Sized.size b.value)\n  UInt64.ofNat (match packed with\n    | ParityMaybe.none => 0\n    | ParityMaybe.some value => if b == b then value else 0)\nwhere\n  keep (n : Nat) : Nat :=\n    match n with\n    | 0 => 0\n    | Nat.succ k => Nat.succ (keep k)\n  termination_by n\n  decreasing_by exact Nat.lt_succ_self k\n"

private def dataPsSource : String :=
  "structure ParityBox where {\n  value: Nat\n} deriving Inhabited, BEq\ninductive ParityMaybe where {\n  | none\n  | some(value: Nat)\n} deriving Inhabited, BEq\nclass Sized(A: Type) where {\n  size: A -> Nat\n}\n@[default_instance 200]\ninstance (priority := high) sizedNat: Sized Nat where {\n  size(n: Nat): Nat := n\n}\nfunction m3data(flag: Bool): UInt64 :=\n  let b := ParityBox.mk(keep(if (flag) { 6 } else { 9 }))\n  let packed := ParityMaybe.some(Sized.size(b.value))\n  UInt64.ofNat(match packed with {\n    | ParityMaybe.none => 0\n    | ParityMaybe.some value => if (b == b) { value } else { 0 }\n  })\nwhere {\n  def keep(n: Nat): Nat := match n with {\n    | 0 => 0\n    | Nat.succ k => Nat.succ(keep(k))\n  }\n  termination_by n\n  decreasing_by by { exact Nat.lt_succ_self(k) }\n}\n"

private def controlLeanSource : String :=
  "def m3control (flag : Bool) : UInt64 :=\n  let (left, right) : Nat × Nat := (2, 3)\n  let amount : Option Nat := do\n    let (x, y) : Nat × Nat ← Option.some (left, right)\n    if !flag then\n      if let .some n := Option.some (x + y) then\n        return n\n    else if flag then\n      return 7\n    return 11\n  let extra : Id Nat := do { let n := 1; return n; }\n  let extraValue : Nat := extra\n  let extraApplied : Nat := (fun (f : Nat → Nat) => f extraValue) fun (n : Nat) => n\n  UInt64.ofNat (if let .some n := amount then n + extraApplied else 0)\n"

private def controlPsSource : String :=
  "function m3control(flag: Bool): UInt64 :=\n  let (left, right): Nat × Nat := (2, 3)\n  let amount: Option Nat := do {\n    let (x, y): Nat × Nat ← Option.some((left, right))\n    if (!flag) {\n      if let .some n := Option.some(x + y) {\n        return n\n      }\n    } else {\n      if (flag) {\n        return 7\n      }\n    }\n    return 11\n  }\n  let extra: Id Nat := do {\n    let n := 1\n    return n\n  }\n  let extraValue: Nat := extra\n  let extraApplied: Nat := (fun (f: Nat -> Nat) => f(extraValue))(fun (n: Nat) => n)\n  UInt64.ofNat(if let .some n := amount { n + extraApplied } else { 0 })\n"

private def mutualLeanSource : String :=
  "mutual\ndef parityFirst {A : Type} (a : A) (n : Nat) : Nat → A :=\n  fun (k : Nat) => match n with\n    | 0 => a\n    | Nat.succ m => let kept := a; paritySecond m A kept k\ntermination_by n\ndef paritySecond (n : Nat) (B : Type) (b : B) : Nat → B :=\n  fun (k : Nat) => match n with\n    | 0 => b\n    | Nat.succ m => parityThird m b k\ntermination_by n\ndef parityThird {C : Type} (n : Nat) (c : C) : Nat → C :=\n  fun (k : Nat) => match n with\n    | 0 => c\n    | Nat.succ m => parityFirst c m k\ntermination_by n\nend\ndef m3mutual (flag : Bool) : UInt64 :=\n  UInt64.ofNat (parityFirst (if flag then 7 else 11) (if flag then 6 else 4) 2)\n"

private def mutualPsSource : String :=
  "mutual\ndef parityFirst {A : Type} (a : A, n : Nat) : Nat -> A := fun (k : Nat) => match n with { | 0 => a | Nat.succ m => let kept := a\nparitySecond(m, A, kept)(k) } termination_by n\ndef paritySecond (n : Nat, B : Type, b : B) : Nat -> B := fun (k : Nat) => match n with { | 0 => b | Nat.succ m => parityThird(m, b)(k) } termination_by n\ndef parityThird {C : Type} (n : Nat, c : C) : Nat -> C := fun (k : Nat) => match n with { | 0 => c | Nat.succ m => parityFirst(c, m)(k) } termination_by n\nend\nfunction m3mutual(flag: Bool): UInt64 := UInt64.ofNat(parityFirst(if (flag) { 7 } else { 11 }, if (flag) { 6 } else { 4 })(2))\n"

private def strategyLeanSource : String :=
  "partial def parityPartial (n : Nat) : Nat :=\n  match n with\n  | 0 => 0\n  | Nat.succ k => Nat.succ (parityPartial k)\ndef parityFixed (seed : Nat) (n : Nat) : Nat :=\n  match n with\n  | 0 => seed\n  | Nat.succ k => parityFixed seed k\npartial_fixpoint\ndef m3strategies (flag : Bool) : UInt64 :=\n  UInt64.ofNat (parityPartial (if flag then 4 else 3) +\n    100 * parityFixed (if flag then 7 else 9) (if flag then 3 else 4))\n"

private def strategyPsSource : String :=
  "partial def parityPartial(n: Nat): Nat := match n with { | 0 => 0 | Nat.succ k => Nat.succ(parityPartial(k)) }\ndef parityFixed(seed: Nat, n: Nat): Nat := match n with { | 0 => seed | Nat.succ k => parityFixed(seed, k) }\npartial_fixpoint\nfunction m3strategies(flag: Bool): UInt64 := UInt64.ofNat(parityPartial(if (flag) { 4 } else { 3 }) + 100 * parityFixed(if (flag) { 7 } else { 9 }, if (flag) { 3 } else { 4 }))\n"

private def fieldsLeanSource : String :=
  "instance parityFunctionHash {A : Type} : Hashable (forall (i : Nat), i = i → A) where\n  hash (_ : forall (i : Nat), i = i → A) := UInt64.ofNat 17\ninductive ParityBranch where\n  | leaf (value : Nat)\n  | node (children : forall (i : Nat), i = i → ParityBranch)\n  deriving Hashable\ndef branchFold (tree : ParityBranch) : Nat :=\n  match tree with\n  | ParityBranch.leaf value => value\n  | ParityBranch.node children => Nat.succ (branchFold (children 2 (Eq.refl 2)))\nmutual\ndef branchFirst (bias : Nat) (tree : ParityBranch) : Nat :=\n  match tree with\n  | ParityBranch.leaf value => bias + value\n  | ParityBranch.node children => branchSecond (children 3 (Eq.refl 3)) (bias + 1)\ndef branchSecond (tree : ParityBranch) (bias : Nat) : Nat :=\n  match tree with\n  | ParityBranch.leaf value => bias + value\n  | ParityBranch.node children => branchFirst (bias + 2) (children 4 (Eq.refl 4))\nend\ndef branchByRec (tree : ParityBranch) : Nat :=\n  ParityBranch.rec (motive := fun (_ : ParityBranch) => Nat)\n    (fun (value : Nat) => value)\n    (fun (children : forall (i : Nat), i = i → ParityBranch) (ih : forall (i : Nat), i = i → Nat) =>\n      Nat.succ (ih 5 (Eq.refl 5))) tree\ntheorem branchRefl (tree : ParityBranch) : branchFold tree = branchFold tree :=\n  ParityBranch.rec (motive := fun (t : ParityBranch) => branchFold t = branchFold t)\n    (fun (value : Nat) => Eq.refl value)\n    (fun (children : forall (i : Nat), i = i → ParityBranch)\n      (ih : forall (i : Nat) (h : i = i), branchFold (children i h) = branchFold (children i h)) =>\n      congrArg Nat.succ (ih 2 (Eq.refl 2))) tree\ndef m3fields (flag : Bool) : UInt64 :=\n  let seed := if flag then 7 else 11\n  let tree := ParityBranch.node (fun (i : Nat) (h : i = i) =>\n    ParityBranch.node (fun (j : Nat) (g : j = j) => ParityBranch.leaf (seed + i + j)))\n  let mark : Nat := if Hashable.hash tree == mixHash (UInt64.ofNat 1) (UInt64.ofNat 17) then 0 else 1\n  UInt64.ofNat (branchFold tree + 100 * branchFirst 3 tree + 10000 * branchByRec tree + mark)\n"

private def fieldsPsSource : String :=
  "instance parityFunctionHash {A: Type}: Hashable(forall (i: Nat), i = i -> A) where {\n  hash(value: forall (i: Nat), i = i -> A): UInt64 := UInt64.ofNat(17)\n}\ninductive ParityBranch where {\n  | leaf(value: Nat)\n  | node(children: forall (i: Nat), i = i -> ParityBranch)\n} deriving Hashable\nfunction branchFold(tree: ParityBranch): Nat := match tree with {\n  | ParityBranch.leaf value => value\n  | ParityBranch.node children => Nat.succ(branchFold(children(2, Eq.refl(2))))\n}\nmutual\nfunction branchFirst(bias: Nat, tree: ParityBranch): Nat := match tree with {\n  | ParityBranch.leaf value => bias + value\n  | ParityBranch.node children => branchSecond(children(3, Eq.refl(3)), bias + 1)\n}\nfunction branchSecond(tree: ParityBranch, bias: Nat): Nat := match tree with {\n  | ParityBranch.leaf value => bias + value\n  | ParityBranch.node children => branchFirst(bias + 2, children(4, Eq.refl(4)))\n}\nend\nfunction branchByRec(tree: ParityBranch): Nat :=\n  ParityBranch.rec(fun (value: Nat) => value,\n    fun (children: forall (i: Nat), i = i -> ParityBranch) (ih: forall (i: Nat), i = i -> Nat) =>\n      Nat.succ(ih(5, Eq.refl(5))), tree, motive := fun (_: ParityBranch) => Nat)\ntheorem branchRefl(tree: ParityBranch): branchFold(tree) = branchFold(tree) :=\n  ParityBranch.rec(fun (value: Nat) => Eq.refl(value),\n    fun (children: forall (i: Nat), i = i -> ParityBranch)\n      (ih: forall (i: Nat) (h: i = i), branchFold(children(i, h)) = branchFold(children(i, h))) =>\n      congrArg(Nat.succ, ih(2, Eq.refl(2))), tree, motive := fun (t: ParityBranch) => branchFold(t) = branchFold(t))\nfunction m3fields(flag: Bool): UInt64 :=\n  let seed := if (flag) { 7 } else { 11 }\n  let tree := ParityBranch.node(fun (i: Nat) (h: i = i) =>\n    ParityBranch.node(fun (j: Nat) (g: j = j) => ParityBranch.leaf(seed + i + j)))\n  let mark: Nat := if (Hashable.hash(tree) == mixHash(UInt64.ofNat(1), UInt64.ofNat(17))) { 0 } else { 1 }\n  UInt64.ofNat(branchFold(tree) + 100 * branchFirst(3, tree) + 10000 * branchByRec(tree) + mark)\n"

private def checkedDeclarations (kind : PsCompilerSourceKind) (source : String) :
    Except String (List PsDeclaration) := do
  let program ← psCompilerParsePscv0 source kind
  let elaborated ← (psCompilerElaboratePscv0 program).mapError psCompilerPscv0Error
  return elaborated.declarations

private def compareCheckedValues (left right : List PsDeclaration) : IO Unit := do
  ensure (left.length == right.length) "source adapters changed the declaration count"
  for (left, right) in left.zip right do
    match left, right with
    | .definitionDecl ln ll lt lv, .definitionDecl rn rl rt rv
    | .theoremDecl ln ll lt lv, .theoremDecl rn rl rt rv
    | .opaqueDecl ln ll lt lv, .opaqueDecl rn rl rt rv
    | .partialDecl ln ll lt lv, .partialDecl rn rl rt rv =>
      ensure (psNameEq ln rn && psElabMutualLevelNamesEqual ll rl &&
        psExprAlphaEq lt rt && psExprAlphaEq lv rv)
        ("source adapters changed checked value " ++ psNameToString ln)
    | .inductiveDecl l, .inductiveDecl r =>
      ensure (psNameEq l.name r.name && psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && l.numParams == r.numParams && l.numIndices == r.numIndices &&
        psElabMutualLevelNamesEqual l.constructors r.constructors && l.isStructure == r.isStructure)
        "source adapters changed an inductive family"
    | .constructorDecl l, .constructorDecl r =>
      ensure (psNameEq l.name r.name && psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && psNameEq l.inductiveName r.inductiveName &&
        l.constructorIndex == r.constructorIndex && l.numParams == r.numParams &&
        l.numFields == r.numFields && l.recursiveFields == r.recursiveFields)
        "source adapters changed constructor field metadata"
    | .recursorDecl l, .recursorDecl r =>
      ensure (psNameEq l.name r.name && psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && psElabMutualLevelNamesEqual l.inductiveNames r.inductiveNames &&
        l.numParams == r.numParams && l.numIndices == r.numIndices &&
        l.numMotives == r.numMotives && l.numMinors == r.numMinors)
        "source adapters changed a recursor telescope"
    | _, _ => throw (IO.userError "source adapters changed a checked declaration kind")

def check (root : System.FilePath) : IO Unit := do
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "input parity requires pinned Lean4.35.0"
  let native ← fromExcept (checkedDeclarations .lean leanSource)
  let proofscript ← fromExcept (checkedDeclarations .proofScript psSource)
  compareCheckedValues native proofscript
  compareCheckedValues (← fromExcept (checkedDeclarations .lean controlLeanSource))
    (← fromExcept (checkedDeclarations .proofScript controlPsSource))
  compareCheckedValues (← fromExcept (checkedDeclarations .lean mutualLeanSource))
    (← fromExcept (checkedDeclarations .proofScript mutualPsSource))
  -- Exercise total-only runtime admission independently of the combined
  -- ordinary P0/P1 host path used by the emitted paired module below.
  let totalProgram ← fromExcept (psCompilerParsePscv0 mutualLeanSource .lean)
  let totalElaborated ← fromExcept ((psCompilerElaboratePscv0 totalProgram).mapError psCompilerPscv0Error)
  let totalIr ← fromExcept ((psCompilerVerifiedIrFromElaborated totalElaborated).mapError psCompilerPscv0Error)
  let _ ← fromExcept (psWithCheckedIr psIrCheckDefaultOptions totalIr fun _ => pure ())
  compareCheckedValues (← fromExcept (checkedDeclarations .lean strategyLeanSource))
    (← fromExcept (checkedDeclarations .proofScript strategyPsSource))
  compareCheckedValues (← fromExcept (checkedDeclarations .lean fieldsLeanSource))
    (← fromExcept (checkedDeclarations .proofScript fieldsPsSource))
  for (kind, source) in [
      (PsCompilerSourceKind.lean, "inductive Negative where\n  | wrap (f : Negative → Nat)\n"),
      (.proofScript, "inductive Negative where { | wrap(f: Negative -> Nat) }\n")] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    match psCompilerElaboratePscv0 program with
    | .error error =>
      ensure (((psCompilerPscv0Error error).splitOn "recursive family occurs in a function-field domain").length > 1)
        "negative function-field occurrence lost its positivity diagnosis"
    | .ok _ => throw (IO.userError "negative function-field occurrence was admitted")
  let grouped := "def grouped {T : Type} {first value : T} := value\n"
  compareCheckedValues (← fromExcept (checkedDeclarations .lean grouped))
    (← fromExcept (checkedDeclarations .proofScript grouped))
  let richLean := "universe u\ndef identity {A : Type u} (a : A) : A := a\n" ++
    "def choose (x y : Nat) (flag : Bool) : Nat := if flag then x + y else x\n" ++
    "def chosen : Nat := choose (flag := true) (y := 4) (x := 3)\n" ++
    "def scalar : Float := 1.25\n" ++
    "def doArgument : Option Nat := (fun (value : Option Nat) => value) do return 1\n"
  let richPs := "universe u\nfunction identity{A: Type u}(a: A): A := a\n" ++
    "function choose(x: Nat, y: Nat, flag: Bool): Nat := if (flag) { x + y } else { x }\n" ++
    "const chosen: Nat := choose(flag := true, y := 4, x := 3)\n" ++
    "const scalar: Float := 1.25\n" ++
    "const doArgument: Option Nat := (fun (value: Option Nat) => value)(do { return 1 })\n"
  compareCheckedValues (← fromExcept (checkedDeclarations .lean richLean))
    (← fromExcept (checkedDeclarations .proofScript richPs))
  ensure (!(psCompilerParsePscv0 "def bad : Nat := Nat.succ(3)\n" .lean).isOk)
    "native application lost Lean's whitespace requirement"
  compareCheckedValues (← fromExcept (checkedDeclarations .lean "section\nvariable (x y : Nat)\ndef selected := y\nend\n"))
    (← fromExcept (checkedDeclarations .proofScript "section\nvariable (x y: Nat)\nconst selected: Nat := y\nend\n"))
  -- Real input routing, not a host oracle or source-printer round trip.
  for (kind, wrong) in [(PsCompilerSourceKind.lean, psSource),
      (PsCompilerSourceKind.proofScript, leanSource)] do
    ensure (!(psCompilerParsePscv0 wrong kind).isOk)
      "source-kind selection silently accepted the other grammar"
  for source in ["axiom unapproved : Nat\n",
      "def f (n : Nat) : Nat := n\ntermination_by structural n\n",
      "def f (n : Nat) : Nat := n\npartial_fixpoint monotonicity by exact id\n"] do
    ensure (!(psCompilerParsePscv0 source .lean).isOk)
      "native source selection admitted an unselected declaration or strategy"
  for (kind, text) in [
      (PsCompilerSourceKind.lean, "def shadow {T : Type} {T value : T} := value\n"),
      (.proofScript, "def shadow {T : Type} {T value : T} := value\n"),
      (.lean, "def bad : (T : Type) -> T -> T -> T := fun (T : Type) (T value : T) => value\n"),
      (.lean, "section\nvariable (Nat value : Nat)\nend\n"),
      (.proofScript, "section\nvariable (Nat value: Nat)\nend\n"),
      (.proofScript, "const bad: forall (T: Type), T -> T -> T := fun (T: Type) (T value: T) => value\n")] do
    ensure (!(checkedDeclarations kind text).isOk)
      "binder annotation ignored native prefix shadowing"
  for source in [
      "def bad : Option Nat := do\n  let mut n := 0\n  return n\n",
      "def bad : Option Nat := do\n  if let .some n ← Option.some 1 then\n    return n\n  return 0\n",
      "def bad : Nat := if let .some n := Option.some 1 then n\n"] do
    ensure (!(psCompilerParsePscv0 source .lean).isOk)
      "native control admitted unselected mutation, monadic if-let or incomplete term if"
  let provider : PsPscv0ModuleSource := {
    name := "Library", sourceKind := .lean
    source := "def library (n : Nat) : Nat := Nat.succ n\n" }
  let project ← fromExcept (psPscv0ProjectParse [provider,
    { name := "Main", source := "import Library\nconst answer: Nat := library(3)\n" }])
  ensure ((project.map (·.sourceName)) == ["Library.lean", "Main.ps"])
    "mixed input module planning lost source-kind provenance"
  let request := fun kind source stem => ({
    sourceKind := kind, source, sourceName := stem ++ psCompilerSourceKindExtension kind
    outputStem := "inputparity", exports := .selected ["m3parity", "m3data", "m3control", "m3mutual", "m3strategies", "m3fields"]
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] } : PsV7Native.Request)
  let requests := #[
    request .lean (fieldsLeanSource ++ dataLeanSource ++ controlLeanSource ++ mutualLeanSource ++ strategyLeanSource ++ leanSource ++ "theorem observed : m3parity true = 13 := by rfl\n") "native-input", request .proofScript (fieldsPsSource ++ dataPsSource ++ controlPsSource ++ mutualPsSource ++ strategyPsSource ++ psSource ++ "theorem observed: m3parity(true) = 13 := by { rfl }\n") "proofscript-input",
    { sourceKind := .lean, source := "import Library\ndef answer : Nat := library 3\n"
      modules := [{ name := "Library", source := "function library(n: Nat): Nat := Nat.succ(n)\n" }] },
    { source := "import Library\nconst answer: Nat := library(3)\n", modules := [provider] },
    { sourceKind := .lean, source := leanSource, assurance := .closedVerified },
    { sourceKind := .lean, source :=
      "noncomputable def hidden (n : Nat) : Nat := n\ndef bad : Nat := hidden 3\n"
      targets := [.javascript] }]
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok batch => pure batch
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (batch.results.size == requests.size) "input parity omitted a requested result"
  for (result, index) in batch.results.toList.zipIdx do
    if index >= 4 then
      match result with
      | .error error =>
        ensure (error.phase == "assurance" && error.message.startsWith
          (if index == 4 then "PSCV0-ASSURANCE-DOWNGRADE:" else "PSCV0-NONCOMPUTABLE-EXEC:"))
          ("native input escaped assurance policy: " ++ error.message)
      | .ok _ => throw (IO.userError "native input acquired an unauthorized executable")
    else
      let result ← match result with
        | .ok result => pure result
        | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
      if index < 2 then
        ensure (result.artifacts.length == 5) "native input lost a selected backend"
        let directory := root / (if index == 0 then "lean" else "ps")
        IO.FS.createDirAll directory
        for artifact in result.artifacts do
          for file in artifact.files do
            match file.payload with
            | .text value => IO.FS.writeFile (directory / file.path) value
            | .binary value => IO.FS.writeBinFile (directory / file.path) value
        let rows := [false, true].map fun flag => Lean.Json.mkObj [
          ("flag", Lean.toJson flag),
          ("m3parity", Lean.toJson (toString (M3InputParityOracle.m3parity flag).toNat)),
          ("m3data", Lean.toJson (toString (M3InputParityOracle.m3data flag).toNat)),
          ("m3control", Lean.toJson (toString (M3InputParityOracle.m3control flag).toNat)),
          ("m3mutual", Lean.toJson (toString (M3InputParityOracle.m3mutual flag).toNat)),
          ("m3strategies", Lean.toJson (toString (M3InputParityOracle.m3strategies flag).toNat)),
          ("m3fields", Lean.toJson (toString (M3InputParityOracle.m3fields flag).toNat))]
        IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_INPUT_PARITY: PASS native source routing, shared checked Core, universe/named/operator/scientific terms, native proofs, data/classes/instances/deriving, positive dependent function fields with singleton/mutual recursion and explicit induction, where, singleton/mutual WF, ordinary partial P0 and selected fixedpoint P1, pattern lets, conditional patterns and typed do control, ordered binder scope/default ownership, both mixed-module directions, official kernel, five-target emission and assurance refusals; full native term/command parity remains open"
end M3InputParity
