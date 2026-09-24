import ProofScript.Kernel.PSC1.Name

namespace ProofScript.Kernel.PSC1

/--
Universe level syntax for the portable kernel.

The algorithms below are transcribed from the semantics in pinned Lean 4.34
`src/kernel/level.cpp`, while intentionally omitting runtime hash/depth caches.
-/
inductive Level where
  | zero
  | succ (level : Level)
  | max (left right : Level)
  | imax (left right : Level)
  | param (name : Name)
  | mvar (name : Name)

namespace Level

def beq : Level → Level → Bool
  | .zero, .zero => true
  | .succ a, .succ b => beq a b
  | .max a₁ a₂, .max b₁ b₂ => beq a₁ b₁ && beq a₂ b₂
  | .imax a₁ a₂, .imax b₁ b₂ => beq a₁ b₁ && beq a₂ b₂
  | .param a, .param b => Name.beq a b
  | .mvar a, .mvar b => Name.beq a b
  | _, _ => false

def depth : Level → Nat
  | .zero => 0
  | .param _ => 0
  | .mvar _ => 0
  | .succ u => depth u + 1
  | .max u v => Nat.max (depth u) (depth v) + 1
  | .imax u v => Nat.max (depth u) (depth v) + 1

def isZero : Level → Bool
  | .zero => true
  | _ => false

def isExplicit : Level → Bool
  | .zero => true
  | .succ u => isExplicit u
  | _ => false

def toOffset : Level → Level × Nat
  | .succ u =>
      let p := toOffset u
      (p.1, p.2 + 1)
  | u => (u, 0)

/-- Lean 4.34 `mk_max` smart-constructor behavior. -/
def mkMax (u v : Level) : Level :=
  if isExplicit u && isExplicit v then
    if depth u >= depth v then u else v
  else if beq u v then
    u
  else if isZero u then
    v
  else if isZero v then
    u
  else
    match v with
    | .max a b =>
        if beq a u || beq b u then v
        else
          match u with
          | .max a' b' =>
              if beq a' v || beq b' v then u
              else
                let p₁ := toOffset u
                let p₂ := toOffset v
                if beq p₁.1 p₂.1 then
                  if p₁.2 > p₂.2 then u else v
                else
                  .max u v
          | _ =>
              let p₁ := toOffset u
              let p₂ := toOffset v
              if beq p₁.1 p₂.1 then
                if p₁.2 > p₂.2 then u else v
              else
                .max u v
    | _ =>
        match u with
        | .max a b =>
            if beq a v || beq b v then u
            else
              let p₁ := toOffset u
              let p₂ := toOffset v
              if beq p₁.1 p₂.1 then
                if p₁.2 > p₂.2 then u else v
              else
                .max u v
        | _ =>
            let p₁ := toOffset u
            let p₂ := toOffset v
            if beq p₁.1 p₂.1 then
              if p₁.2 > p₂.2 then u else v
            else
              .max u v

/-- Lean 4.34 `is_not_zero`. -/
def isNotZero : Level → Bool
  | .zero => false
  | .param _ => false
  | .mvar _ => false
  | .succ _ => true
  | .max u v => isNotZero u || isNotZero v
  | .imax _ v => isNotZero v

/-- Lean 4.34 `normalizes_to_zero`. -/
def normalizesToZero : Level → Bool
  | .zero => true
  | .param _ => false
  | .mvar _ => false
  | .succ _ => false
  | .max u v => normalizesToZero u && normalizesToZero v
  | .imax _ v => normalizesToZero v

/-- Lean 4.34 `mk_imax` smart-constructor behavior. -/
def mkIMax (u v : Level) : Level :=
  if isNotZero v then
    mkMax u v
  else if isZero v then
    v
  else if isZero u then
    v
  else
    match u with
    | .succ .zero => v
    | _ => if beq u v then u else .imax u v


def addOffset : Level → Nat → Level
  | u, 0 => u
  | u, n + 1 => addOffset (.succ u) n

def getOffset : Level → Nat
  | .succ u => getOffset u + 1
  | _ => 0

def getLevelOffset : Level → Level
  | .succ u => getLevelOffset u
  | u => u

def ctorRank : Level → Nat
  | .zero => 0
  | .param _ => 1
  | .mvar _ => 2
  | .succ _ => 3
  | .max _ _ => 4
  | .imax _ _ => 5

/--
Total order used by the Lean 4.34 kernel universe normalizer.
This follows `src/kernel/level.cpp:is_norm_lt`.
-/
def normLtAux : Level → Nat → Level → Nat → Bool
  | .succ a, ka, b, kb => normLtAux a (ka + 1) b kb
  | a, ka, .succ b, kb => normLtAux a ka b (kb + 1)
  | a@(.max a₁ a₂), ka, b@(.max b₁ b₂), kb =>
      if beq a b then ka < kb
      else if !beq a₁ b₁ then normLtAux a₁ 0 b₁ 0
      else normLtAux a₂ 0 b₂ 0
  | a@(.imax a₁ a₂), ka, b@(.imax b₁ b₂), kb =>
      if beq a b then ka < kb
      else if !beq a₁ b₁ then normLtAux a₁ 0 b₁ 0
      else normLtAux a₂ 0 b₂ 0
  | .param a, ka, .param b, kb =>
      if Name.beq a b then ka < kb else Name.lt a b
  | .mvar a, ka, .mvar b, kb =>
      if Name.beq a b then ka < kb else Name.lt a b
  | a, ka, b, kb =>
      if beq a b then ka < kb else ctorRank a < ctorRank b

def normLt (a b : Level) : Bool :=
  normLtAux a 0 b 0

def insertSorted (x : Level) : List Level → List Level
  | [] => [x]
  | y :: ys =>
      if normLt x y then x :: y :: ys
      else y :: insertSorted x ys

def sortLevels : List Level → List Level
  | [] => []
  | x :: xs => insertSorted x (sortLevels xs)

def flattenMax : Level → List Level
  | .max a b => flattenMax a ++ flattenMax b
  | u => [u]

def splitExplicit : List Level → List Level × List Level
  | [] => ([], [])
  | x :: xs =>
      if isExplicit x then
        let p := splitExplicit xs
        (x :: p.1, p.2)
      else
        ([], x :: xs)

def last? {α : Type} : List α → Option α
  | [] => none
  | [x] => some x
  | _ :: xs => last? xs

def anyOffsetGe : List Level → Nat → Bool
  | [], _ => false
  | x :: xs, k => getOffset x >= k || anyOffsetGe xs k

def selectExplicitPrefix (xs : List Level) : List Level :=
  let p := splitExplicit xs
  match last? p.1 with
  | none => p.2
  | some e =>
      if anyOffsetGe p.2 (getOffset e) then p.2
      else e :: p.2

def collapseSameBase : List Level → List Level
  | [] => []
  | x :: xs =>
      let rec loop (best : Level) : List Level → List Level
        | [] => [best]
        | y :: ys =>
            if beq (getLevelOffset best) (getLevelOffset y) then
              loop y ys
            else
              best :: loop y ys
      loop x xs

def mkMaxList : List Level → Level
  | [] => .zero
  | [x] => x
  | x :: xs => mkMax x (mkMaxList xs)

def isAlreadyNormalizedCheap : Level → Bool
  | .zero => true
  | .param _ => true
  | .mvar _ => true
  | .succ u => isAlreadyNormalizedCheap u
  | _ => false

/--
Exact Lean-4.34-kernel universe normal form, expressed with portable lists
instead of the C++ temporary buffers/Lean Array qsort implementation.
-/
partial def normalize (u : Level) : Level :=
  if isAlreadyNormalizedCheap u then
    u
  else
    let outer := getOffset u
    match getLevelOffset u with
    | .imax a b =>
        addOffset (mkIMax (normalize a) (normalize b)) outer
    | .max a b =>
        let raw := flattenMax a ++ flattenMax b
        let normalized := raw.map normalize
        let flattened := normalized.foldl
          (fun acc x => acc ++ flattenMax x) []
        let sorted := sortLevels flattened
        let selected := selectExplicitPrefix sorted
        let collapsed := collapseSameBase selected
        let shifted := collapsed.map (fun x => addOffset x outer)
        mkMaxList shifted
    | other => addOffset other outer

def isEquivalent (a b : Level) : Bool :=
  beq a b || beq (normalize a) (normalize b)

/--
Final Lean 4.34 kernel `is_geq`.
The max-left case is only a positive shortcut. If both branches fail, the
algorithm deliberately falls through to the remaining imax/offset rules.
-/
partial def isGeqCore (a b : Level) : Bool :=
  if beq a b || isZero b then
    true
  else
    match b with
    | .max b₁ b₂ => isGeq a b₁ && isGeq a b₂
    | _ =>
        match a with
        | .max a₁ a₂ =>
            if isGeq a₁ b || isGeq a₂ b then
              true
            else
              isGeqCoreRest a b
        | _ => isGeqCoreRest a b
where
  isGeqCoreRest (a b : Level) : Bool :=
    match b with
    | .imax b₁ b₂ => isGeq a b₁ && isGeq a b₂
    | _ =>
        match a with
        | .imax _ a₂ => isGeq a₂ b
        | _ =>
            let pa := toOffset a
            let pb := toOffset b
            if beq pa.1 pb.1 || isZero pb.1 then
              pa.2 >= pb.2
            else if pa.2 == pb.2 && pa.2 > 0 then
              isGeq pa.1 pb.1
            else
              false
  isGeq (a b : Level) : Bool :=
    isGeqCore (normalize a) (normalize b)

def geq (a b : Level) : Bool :=
  isGeqCore (normalize a) (normalize b)


def findParam : Name → List Name → List Level → Option Level
  | _, [], _ => none
  | _, _, [] => none
  | target, p :: ps, v :: vs =>
      if Name.beq target p then some v else findParam target ps vs

/--
Lean 4.34 kernel level-parameter substitution. Rebuilt max/imax nodes use the
kernel smart constructors, matching `instantiate` + `update_max`.
-/
def instantiateParams (u : Level) (params : List Name) (values : List Level) : Level :=
  match u with
  | .zero => .zero
  | .succ a => .succ (instantiateParams a params values)
  | .max a b => mkMax (instantiateParams a params values) (instantiateParams b params values)
  | .imax a b => mkIMax (instantiateParams a params values) (instantiateParams b params values)
  | .param n =>
      match findParam n params values with
      | some v => v
      | none => u
  | .mvar n => .mvar n

end Level

end ProofScript.Kernel.PSC1
