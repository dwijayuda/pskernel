import Init

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

end Name

end ProofScript.Kernel.PSC1
