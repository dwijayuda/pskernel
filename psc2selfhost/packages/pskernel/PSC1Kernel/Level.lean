import PSC1Kernel.Name

namespace PSC1Kernel

inductive Level where
  | zero
  | succ (of : Level)
  | max (left : Level) (right : Level)
  | imax (left : Level) (right : Level)
  | param (name : Name)
  | mvar (name : Name)

def Level.eq : Level → Level → Bool
  | .zero, .zero => true
  | .succ a, .succ b => Level.eq a b
  | .max a₁ a₂, .max b₁ b₂ => Level.eq a₁ b₁ && Level.eq a₂ b₂
  | .imax a₁ a₂, .imax b₁ b₂ => Level.eq a₁ b₁ && Level.eq a₂ b₂
  | .param a, .param b => Name.eq a b
  | .mvar a, .mvar b => Name.eq a b
  | _, _ => false

def Level.isZero : Level → Bool
  | .zero => true
  | _ => false

def Level.isNotZero : Level → Bool
  | .succ _ => true
  | .max a b => a.isNotZero || b.isNotZero
  | .imax _ b => b.isNotZero
  | .zero | .param _ | .mvar _ => false

def Level.normalizesToZero : Level → Bool
  | .zero => true
  | .max a b => a.normalizesToZero && b.normalizesToZero
  | .imax _ b => b.normalizesToZero
  | .succ _ | .param _ | .mvar _ => false

def Level.toOffset : Level → Level × Nat
  | .succ l =>
    let p := l.toOffset
    (p.1, p.2 + 1)
  | l => (l, 0)

def Level.addOffset (l : Level) : Nat → Level
  | 0 => l
  | n + 1 => .succ (l.addOffset n)

def Level.isExplicit (l : Level) : Bool :=
  l.toOffset.1.isZero

def Level.mkMax (a b : Level) : Level :=
  if a.isExplicit && b.isExplicit then
    if a.toOffset.2 ≥ b.toOffset.2 then a else b
  else if Level.eq a b then a
  else if a.isZero then b
  else if b.isZero then a
  else
    match b with
    | .max l r =>
      if Level.eq l a || Level.eq r a then b
      else
        match a with
        | .max l' r' =>
          if Level.eq l' b || Level.eq r' b then a
          else
            let pa := a.toOffset
            let pb := b.toOffset
            if Level.eq pa.1 pb.1 then
              if pa.2 > pb.2 then a else b
            else .max a b
        | _ =>
          let pa := a.toOffset
          let pb := b.toOffset
          if Level.eq pa.1 pb.1 then
            if pa.2 > pb.2 then a else b
          else .max a b
    | _ =>
      match a with
      | .max l r =>
        if Level.eq l b || Level.eq r b then a
        else
          let pa := a.toOffset
          let pb := b.toOffset
          if Level.eq pa.1 pb.1 then
            if pa.2 > pb.2 then a else b
          else .max a b
      | _ =>
        let pa := a.toOffset
        let pb := b.toOffset
        if Level.eq pa.1 pb.1 then
          if pa.2 > pb.2 then a else b
        else .max a b

def Level.mkIMax (a b : Level) : Level :=
  if b.isNotZero then Level.mkMax a b
  else if b.isZero then b
  else if a.isZero then b
  else
    match a with
    | .succ .zero => b
    | _ => if Level.eq a b then a else .imax a b

def Level.kindRank : Level → Nat
  | .zero => 0
  | .succ _ => 1
  | .max _ _ => 2
  | .imax _ _ => 3
  | .param _ => 4
  | .mvar _ => 5

partial def Level.normCmp (a b : Level) : Ordering :=
  if Level.eq a b then .eq
  else
    let pa := a.toOffset
    let pb := b.toOffset
    let a₀ := pa.1
    let b₀ := pb.1
    if Level.eq a₀ b₀ then compare pa.2 pb.2
    else if a₀.kindRank < b₀.kindRank then .lt
    else if a₀.kindRank > b₀.kindRank then .gt
    else
      match a₀, b₀ with
      | .param n₁, .param n₂ => Name.cmp n₁ n₂
      | .mvar n₁, .mvar n₂ => Name.cmp n₁ n₂
      | .max a₁ a₂, .max b₁ b₂ =>
        match Level.normCmp a₁ b₁ with
        | .eq => Level.normCmp a₂ b₂
        | c => c
      | .imax a₁ a₂, .imax b₁ b₂ =>
        match Level.normCmp a₁ b₁ with
        | .eq => Level.normCmp a₂ b₂
        | c => c
      | _, _ => .eq

def Level.flattenMax : Level → List Level
  | .max a b => a.flattenMax ++ b.flattenMax
  | l => [l]

partial def Level.insertSorted (x : Level) : List Level → List Level
  | [] => [x]
  | y :: ys =>
    match Level.normCmp x y with
    | .lt => x :: y :: ys
    | .eq => x :: y :: ys
    | .gt => y :: Level.insertSorted x ys

def Level.sortLevels (xs : List Level) : List Level :=
  xs.foldl (fun acc x => Level.insertSorted x acc) []

def Level.takeExplicit : List Level → List Level
  | [] => []
  | x :: xs => if x.isExplicit then x :: Level.takeExplicit xs else []

def Level.dropExplicit : List Level → List Level
  | [] => []
  | x :: xs => if x.isExplicit then Level.dropExplicit xs else x :: xs

def Level.last? : List Level → Option Level
  | [] => none
  | [x] => some x
  | _ :: xs => Level.last? xs

def Level.trimExplicit (xs : List Level) : List Level :=
  let ex := Level.takeExplicit xs
  let rest := Level.dropExplicit xs
  match Level.last? ex with
  | none => xs
  | some m =>
    let k := m.toOffset.2
    if rest.any (fun x => x.toOffset.2 ≥ k) then rest else m :: rest

partial def Level.dedupOffsets : List Level → List Level
  | [] => []
  | x :: xs =>
    let rec go (current : Level) (rest : List Level) (rev : List Level) : List Level :=
      match rest with
      | [] => (current :: rev).reverse
      | y :: ys =>
        if Level.eq current.toOffset.1 y.toOffset.1 then go y ys rev
        else go y ys (current :: rev)
    go x xs []

def Level.mkMaxList : List Level → Level
  | [] => .zero
  | [x] => x
  | x :: xs => Level.mkMax x (Level.mkMaxList xs)

partial def Level.normalize (l : Level) : Level :=
  let p := l.toOffset
  let root := p.1
  let offset := p.2
  match root with
  | .zero | .param _ | .mvar _ => l
  | .succ _ => l
  | .imax a b =>
    (Level.mkIMax (Level.normalize a) (Level.normalize b)).addOffset offset
  | .max _ _ =>
    let normalized :=
      root.flattenMax.foldl
        (fun acc x => acc ++ (Level.normalize x).flattenMax)
        []
    let sorted := Level.sortLevels normalized
    let trimmed := Level.trimExplicit sorted
    let unique := Level.dedupOffsets trimmed
    let shifted := unique.map (fun x => x.addOffset offset)
    Level.mkMaxList shifted

mutual
  partial def Level.kernelGeqCore (a b : Level) : Bool :=
    if Level.eq a b || b.isZero then true
    else
      match b with
      | .max b₁ b₂ => Level.kernelGeqCore a b₁ && Level.kernelGeqCore a b₂
      | _ =>
        match a with
        | .max a₁ a₂ =>
          if Level.kernelGeqCore a₁ b || Level.kernelGeqCore a₂ b then true
          else Level.kernelGeqFallback a b
        | _ => Level.kernelGeqFallback a b

  partial def Level.kernelGeqFallback (a b : Level) : Bool :=
    match b with
    | .imax b₁ b₂ => Level.kernelGeqCore a b₁ && Level.kernelGeqCore a b₂
    | _ =>
      match a with
      | .imax _ a₂ => Level.kernelGeqCore a₂ b
      | _ =>
        let pa := a.toOffset
        let pb := b.toOffset
        if Level.eq pa.1 pb.1 || pb.1.isZero then pa.2 ≥ pb.2
        else if pa.2 == pb.2 && pa.2 > 0 then Level.kernelGeqCore pa.1 pb.1
        else false
end

def Level.le (a b : Level) : Bool :=
  Level.kernelGeqCore (Level.normalize b) (Level.normalize a)

def Level.equivalent (a b : Level) : Bool :=
  Level.eq a b || Level.eq (Level.normalize a) (Level.normalize b)

def Name.lookupLevel (name : Name) : List Name → List Level → Option Level
  | [], _ => none
  | _, [] => none
  | p :: ps, v :: vs =>
    if Name.eq name p then some v else Name.lookupLevel name ps vs

def Level.instantiateParams (root : Level) (params : List Name) (values : List Level) : Level :=
  match root with
  | .zero | .mvar _ => root
  | .param n => (Name.lookupLevel n params values).getD root
  | .succ a =>
    let a' := a.instantiateParams params values
    if Level.eq a a' then root else .succ a'
  | .max a b =>
    let a' := a.instantiateParams params values
    let b' := b.instantiateParams params values
    if Level.eq a a' && Level.eq b b' then root else Level.mkMax a' b'
  | .imax a b =>
    let a' := a.instantiateParams params values
    let b' := b.instantiateParams params values
    if Level.eq a a' && Level.eq b b' then root else Level.mkIMax a' b'

end PSC1Kernel
