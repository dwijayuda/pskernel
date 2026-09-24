namespace PSC1Kernel

inductive Name where
  | anonymous
  | str (prefix : Name) (value : String)
  | num (prefix : Name) (value : Nat)

inductive NameComponent where
  | str (value : String)
  | num (value : Nat)

def Name.eq : Name → Name → Bool
  | .anonymous, .anonymous => true
  | .str p₁ s₁, .str p₂ s₂ => s₁ == s₂ && Name.eq p₁ p₂
  | .num p₁ n₁, .num p₂ n₂ => n₁ == n₂ && Name.eq p₁ p₂
  | _, _ => false

def Name.components : Name → List NameComponent
  | .anonymous => []
  | .str p s => p.components ++ [.str s]
  | .num p n => p.components ++ [.num n]

def NameComponent.cmp : NameComponent → NameComponent → Ordering
  | .num a, .num b => compare a b
  | .str a, .str b => compare a b
  | .num _, .str _ => .lt
  | .str _, .num _ => .gt

def compareComponents : List NameComponent → List NameComponent → Ordering
  | [], [] => .eq
  | [], _ :: _ => .lt
  | _ :: _, [] => .gt
  | a :: as, b :: bs =>
    match NameComponent.cmp a b with
    | .eq => compareComponents as bs
    | c => c

def Name.cmp (a b : Name) : Ordering :=
  compareComponents a.components b.components

end PSC1Kernel
