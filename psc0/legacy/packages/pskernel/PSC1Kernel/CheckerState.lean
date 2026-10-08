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
Hash compatible with `Expr.eq`, not `Expr.equal`: binder display names and
binder annotations are intentionally ignored, while let nondep and metadata
remain structural. This matches the equality contract required by Lean's
kernel expression maps.
-/
partial def checkerExprHash : Expr → UInt64
  | .bvar index => checkerMixHash 47 (hash index)
  | .fvar name => checkerMixHash 53 (checkerNameHash name)
  | .mvar name => checkerMixHash 59 (checkerNameHash name)
  | .sort level => checkerMixHash 61 (checkerLevelHash level)
  | .const name levels =>
      checkerMixHash 67 (checkerMixHash (checkerNameHash name) (checkerLevelsHash levels))
  | .app fn arg =>
      checkerMixHash 71 (checkerMixHash (checkerExprHash fn) (checkerExprHash arg))
  | .lam _ type body _ =>
      checkerMixHash 73 (checkerMixHash (checkerExprHash type) (checkerExprHash body))
  | .forallE _ type body _ =>
      checkerMixHash 79 (checkerMixHash (checkerExprHash type) (checkerExprHash body))
  | .letE _ type value body nondep =>
      checkerMixHash 83 <|
        checkerMixHash (checkerExprHash type) <|
          checkerMixHash (checkerExprHash value) <|
            checkerMixHash (checkerExprHash body) (hash nondep)
  | .lit (.nat value) => checkerMixHash 89 (hash value)
  | .lit (.str value) => checkerMixHash 97 (hash value)
  | .mdata metadata expr =>
      checkerMixHash 101 (checkerMixHash (hash metadata) (checkerExprHash expr))
  | .proj typeName index expr =>
      checkerMixHash 103 <|
        checkerMixHash (checkerNameHash typeName) <|
          checkerMixHash (hash index) (checkerExprHash expr)

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
