import Std.Data.HashMap
import PSC1Kernel.Expr

namespace PSC1Kernel

/-- Small structural-hash combiner used only for checker memo-table keys. -/
def checkerMixHash (a b : UInt64) : UInt64 :=
  a * 1099511628211 + b + 1469598103934665603

partial def checkerNameHash : Name → UInt64
  | .anonymous => 11
  | .str parent value =>
      checkerMixHash 13 (checkerMixHash (checkerNameHash parent) (hash value))
  | .num parent value =>
      checkerMixHash 17 (checkerMixHash (checkerNameHash parent) (hash value))

partial def checkerLevelHash : Level → UInt64
  | .zero => 19
  | .succ level => checkerMixHash 23 (checkerLevelHash level)
  | .max left right =>
      checkerMixHash 29 (checkerMixHash (checkerLevelHash left) (checkerLevelHash right))
  | .imax left right =>
      checkerMixHash 31 (checkerMixHash (checkerLevelHash left) (checkerLevelHash right))
  | .param name => checkerMixHash 37 (checkerNameHash name)
  | .mvar name => checkerMixHash 41 (checkerNameHash name)

partial def checkerLevelsHash (levels : List Level) : UInt64 :=
  levels.foldl (fun acc level => checkerMixHash acc (checkerLevelHash level)) 43

/--
Lean stores an expression hash in every native Expr node, so `expr_hash` is an
O(1) read after construction. PSC1's portable Expr is deliberately a plain
inductive value and has no host identity/cache field. Bound the amount of tree
inspection performed by a checker-table hash instead of recursively traversing
an arbitrarily large term on every memo lookup. Structural `Expr.eq` remains the
final key discriminator, so additional hash collisions cannot change semantics.
-/
def checkerExprHashDepth : Nat := 4

def checkerExprTagHash : Expr → UInt64
  | .bvar _ => 47
  | .fvar _ => 53
  | .mvar _ => 59
  | .sort _ => 61
  | .const _ _ => 67
  | .app _ _ => 71
  | .lam _ _ _ _ => 73
  | .forallE _ _ _ _ => 79
  | .letE _ _ _ _ _ => 83
  | .lit (.nat _) => 89
  | .lit (.str _) => 97
  | .mdata _ _ => 101
  | .proj _ _ _ => 103

def checkerExprHashCore : Nat → Expr → UInt64
  | 0, expr => checkerExprTagHash expr
  | fuel + 1, expr =>
      match expr with
      | .bvar index => checkerMixHash 47 (hash index)
      | .fvar name => checkerMixHash 53 (checkerNameHash name)
      | .mvar name => checkerMixHash 59 (checkerNameHash name)
      | .sort level => checkerMixHash 61 (checkerLevelHash level)
      | .const name levels =>
          checkerMixHash 67
            (checkerMixHash (checkerNameHash name) (checkerLevelsHash levels))
      | .app fn arg =>
          checkerMixHash 71
            (checkerMixHash
              (checkerExprHashCore fuel fn)
              (checkerExprHashCore fuel arg))
      | .lam _ type body _ =>
          checkerMixHash 73
            (checkerMixHash
              (checkerExprHashCore fuel type)
              (checkerExprHashCore fuel body))
      | .forallE _ type body _ =>
          checkerMixHash 79
            (checkerMixHash
              (checkerExprHashCore fuel type)
              (checkerExprHashCore fuel body))
      | .letE _ type value body nondep =>
          checkerMixHash 83 <|
            checkerMixHash (checkerExprHashCore fuel type) <|
              checkerMixHash (checkerExprHashCore fuel value) <|
                checkerMixHash (checkerExprHashCore fuel body) (hash nondep)
      | .lit (.nat value) => checkerMixHash 89 (hash value)
      | .lit (.str value) => checkerMixHash 97 (hash value)
      | .mdata metadata body =>
          checkerMixHash 101
            (checkerMixHash (hash metadata) (checkerExprHashCore fuel body))
      | .proj typeName index body =>
          checkerMixHash 103 <|
            checkerMixHash (checkerNameHash typeName) <|
              checkerMixHash (hash index) (checkerExprHashCore fuel body)

/--
Bounded structural hash compatible with `Expr.eq`, not `Expr.equal`. Equal
expressions always hash equally. Unequal deep expressions may intentionally
collide; `Std.HashMap` resolves such collisions with the `BEq` instance below.
-/
def checkerExprHash (expr : Expr) : UInt64 :=
  checkerExprHashCore checkerExprHashDepth expr

structure CheckerExprKey where
  value : Expr

instance : BEq CheckerExprKey where
  beq left right := Expr.eq left.value right.value

instance : Hashable CheckerExprKey where
  hash key := checkerExprHash key.value

structure CheckerExprPairKey where
  left : Expr
  right : Expr

instance : BEq CheckerExprPairKey where
  beq a b :=
    (Expr.eq a.left b.left && Expr.eq a.right b.right) ||
    (Expr.eq a.left b.right && Expr.eq a.right b.left)

instance : Hashable CheckerExprPairKey where
  hash key :=
    let left := checkerExprHash key.left
    let right := checkerExprHash key.right
    -- Commutative combination because defeq-pair membership is symmetric.
    checkerMixHash 107 (left + right + left * right)

abbrev CheckerExprMap (α : Type) := Std.HashMap CheckerExprKey α

namespace CheckerExprMap

def empty : CheckerExprMap α :=
  Std.HashMap.emptyWithCapacity 64

def get? (cache : CheckerExprMap α) (expr : Expr) : Option α :=
  Std.HashMap.get? cache (CheckerExprKey.mk expr)

def insert (cache : CheckerExprMap α) (expr : Expr) (value : α) : CheckerExprMap α :=
  Std.HashMap.insert cache (CheckerExprKey.mk expr) value

end CheckerExprMap

structure CheckerExprPairSet where
  entries : Std.HashMap CheckerExprPairKey Unit

namespace CheckerExprPairSet

def empty : CheckerExprPairSet :=
  { entries := Std.HashMap.emptyWithCapacity 64 }

def contains (set : CheckerExprPairSet) (left right : Expr) : Bool :=
  (Std.HashMap.get? set.entries (CheckerExprPairKey.mk left right)).isSome

def insert (set : CheckerExprPairSet) (left right : Expr) : CheckerExprPairSet :=
  { entries := Std.HashMap.insert set.entries (CheckerExprPairKey.mk left right) () }

end CheckerExprPairSet

/--
Pure declaration-scoped counterpart of final Lean 4.34 `type_checker::state`.
No cache in this structure is valid across an environment mutation.
-/
structure CheckerState where
  nextFresh : Nat
  inferOnly : CheckerExprMap Expr
  checkedInfer : CheckerExprMap Expr
  whnfCore : CheckerExprMap Expr
  whnf : CheckerExprMap Expr
  unfold : CheckerExprMap Expr
  success : CheckerExprPairSet
  failure : CheckerExprPairSet

namespace CheckerState

def empty : CheckerState :=
  {
    nextFresh := 0
    inferOnly := CheckerExprMap.empty
    checkedInfer := CheckerExprMap.empty
    whnfCore := CheckerExprMap.empty
    whnf := CheckerExprMap.empty
    unfold := CheckerExprMap.empty
    success := CheckerExprPairSet.empty
    failure := CheckerExprPairSet.empty
  }

/-- Session-global fresh names: sibling local scopes cannot reuse an FVar id. -/
def freshName (state : CheckerState) (base : Name) : Name × CheckerState :=
  let name := Name.num base state.nextFresh
  (name, { state with nextFresh := state.nextFresh + 1 })

end CheckerState

end PSC1Kernel
