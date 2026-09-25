namespace PSC1Kernel

inductive Name where
  | anonymous
  | str (parent : Name) (value : String)
  | num (parent : Name) (value : Nat)

inductive NameComponent where
  | str (value : String)
  | num (value : Nat)

def Name.eq : Name → Name → Bool
  | .anonymous, .anonymous => true
  | .str p₁ s₁, .str p₂ s₂ => s₁ == s₂ && Name.eq p₁ p₂
  | .num p₁ n₁, .num p₂ n₂ => n₁ == n₂ && Name.eq p₁ p₂
  | _, _ => false

def Name.appendAfter (name : Name) (suffix : String) : Name :=
  match name with
  | .str parent value => .str parent (value ++ suffix)
  | other => .str other suffix

def Name.append : Name → Name → Name
  | prefix, .anonymous => prefix
  | prefix, .str parent value =>
      .str (Name.append prefix parent) value
  | prefix, .num parent value =>
      .num (Name.append prefix parent) value

def Name.appendIndexAfter (name : Name) (index : Nat) : Name :=
  name.appendAfter ("_" ++ toString index)

partial def Name.isPrefixOf (prefix : Name) : Name → Bool
  | .anonymous => Name.eq prefix .anonymous
  | name@(.str parent _) =>
      Name.eq prefix name || Name.isPrefixOf prefix parent
  | name@(.num parent _) =>
      Name.eq prefix name || Name.isPrefixOf prefix parent

partial def Name.replacePrefix
    (name oldPrefix newPrefix : Name) : Option Name :=
  if Name.eq name oldPrefix then
    some newPrefix
  else
    match name with
    | .str parent value =>
        match Name.replacePrefix parent oldPrefix newPrefix with
        | some parent' => some (.str parent' value)
        | none => none
    | .num parent value =>
        match Name.replacePrefix parent oldPrefix newPrefix with
        | some parent' => some (.num parent' value)
        | none => none
    | .anonymous => none

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
