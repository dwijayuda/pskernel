import Init
import Init.Data.Ord.String

namespace ProofScript.Kernel.PSC1

/--
Portable hierarchical name used by the PSC1-authored kernel.
This mirrors the semantic constructors of Lean's kernel `name`; it does not
copy Lean runtime hash/cache representation.
-/
inductive Name where
  | anonymous
  | str (parent : Name) (value : String)
  | num (parent : Name) (value : Nat)

namespace Name

def beq : Name → Name → Bool
  | .anonymous, .anonymous => true
  | .str p₁ s₁, .str p₂ s₂ => beq p₁ p₂ && s₁ == s₂
  | .num p₁ n₁, .num p₂ n₂ => beq p₁ p₂ && n₁ == n₂
  | _, _ => false


/-- Exact lexicographic component order used by Lean 4.34 `Name.cmp`. -/
def cmp : Name → Name → Ordering
  | .anonymous, .anonymous => .eq
  | .anonymous, _ => .lt
  | _, .anonymous => .gt
  | .num p₁ i₁, .num p₂ i₂ =>
      match cmp p₁ p₂ with
      | .eq => compare i₁ i₂
      | ord => ord
  | .num _ _, .str _ _ => .lt
  | .str _ _, .num _ _ => .gt
  | .str p₁ s₁, .str p₂ s₂ =>
      match cmp p₁ p₂ with
      | .eq => compare s₁ s₂
      | ord => ord

def lt (a b : Name) : Bool :=
  cmp a b == .lt

end Name

end ProofScript.Kernel.PSC1
