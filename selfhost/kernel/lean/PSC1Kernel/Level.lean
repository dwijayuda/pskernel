import Init.Data.List.Basic

namespace PSC1Kernel

/--
Portable universe-level representation for the PSC1-authored Lean 4.34 kernel.

Constructor shape is intentionally the same as Lean 4.34's kernel `level`:
zero, succ, max, imax, param, mvar. Runtime hash/depth caches from Lean's
object representation are deliberately not semantic fields.
-/
inductive Level where
  | zero
  | succ (u : Level)
  | max (u v : Level)
  | imax (u v : Level)
  | param (name : Name)
  | mvar (name : Name)

namespace Level

protected def beq : Level → Level → Bool
  | .zero, .zero => true
  | .succ a, .succ b => Level.beq a b
  | .max a₁ a₂, .max b₁ b₂ => Level.beq a₁ b₁ && Level.beq a₂ b₂
  | .imax a₁ a₂, .imax b₁ b₂ => Level.beq a₁ b₁ && Level.beq a₂ b₂
  | .param a, .param b => a == b
  | .mvar a, .mvar b => a == b
  | _, _ => false

instance : BEq Level := ⟨Level.beq⟩

def isZero : Level → Bool
  | .zero => true
  | _ => false

def isSucc : Level → Bool
  | .succ _ => true
  | _ => false

def isMax : Level → Bool
  | .max _ _ => true
  | _ => false

def isIMax : Level → Bool
  | .imax _ _ => true
  | _ => false

def hasParam : Level → Bool
  | .zero => false
  | .succ u => hasParam u
  | .max u v => hasParam u || hasParam v
  | .imax u v => hasParam u || hasParam v
  | .param _ => true
  | .mvar _ => false

def hasMVar : Level → Bool
  | .zero => false
  | .succ u => hasMVar u
  | .max u v => hasMVar u || hasMVar v
  | .imax u v => hasMVar u || hasMVar v
  | .param _ => false
  | .mvar _ => true

/-- C++ `is_not_zero` / Lean `Level.isNeverZero`. -/
def isNeverZero : Level → Bool
  | .zero => false
  | .param _ => false
  | .mvar _ => false
  | .succ _ => true
  | .max u v => isNeverZero u || isNeverZero v
  | .imax _ v => isNeverZero v

/-- C++ `normalizes_to_zero` / Lean `Level.isAlwaysZero`. -/
def isAlwaysZero : Level → Bool
  | .zero => true
  | .param _ => false
  | .mvar _ => false
  | .succ _ => false
  | .max u v => isAlwaysZero u && isAlwaysZero v
  | .imax _ v => isAlwaysZero v

def isExplicit : Level → Bool
  | .zero => true
  | .succ u => isExplicit u
  | _ => false

def getOffset : Level → Nat
  | .succ u => getOffset u + 1
  | _ => 0

def getLevelOffset : Level → Level
  | .succ u => getLevelOffset u
  | u => u

def toOffset (u : Level) : Level × Nat :=
  (getLevelOffset u, getOffset u)

def addOffset : Level → Nat → Level
  | u, 0 => u
  | u, n + 1 => addOffset (.succ u) n

/--
Lean 4.34 `mk_max` smart constructor semantics. This is not merely the raw
`Level.max` constructor.
-/
def mkMax (u v : Level) : Level :=
  if u.isExplicit && v.isExplicit then
    if u.getOffset ≥ v.getOffset then u else v
  else if u == v then
    u
  else if u.isZero then
    v
  else if v.isZero then
    u
  else
    match v with
    | .max a b =>
      if u == a || u == b then v
      else
        match u with
        | .max c d =>
          if v == c || v == d then u
          else
            let (ub, uk) := u.toOffset
            let (vb, vk) := v.toOffset
            if ub == vb then if uk > vk then u else v else .max u v
        | _ =>
          let (ub, uk) := u.toOffset
          let (vb, vk) := v.toOffset
          if ub == vb then if uk > vk then u else v else .max u v
    | _ =>
      match u with
      | .max a b =>
        if v == a || v == b then u
        else
          let (ub, uk) := u.toOffset
          let (vb, vk) := v.toOffset
          if ub == vb then if uk > vk then u else v else .max u v
      | _ =>
        let (ub, uk) := u.toOffset
        let (vb, vk) := v.toOffset
        if ub == vb then if uk > vk then u else v else .max u v

/-- Lean 4.34 `mk_imax` smart constructor semantics. -/
def mkIMax (u v : Level) : Level :=
  if v.isNeverZero then
    mkMax u v
  else if v.isZero then
    v
  else if u.isZero then
    v
  else if u == .succ .zero then
    v
  else if u == v then
    u
  else
    .imax u v

def ctorRank : Level → Nat
  | .zero => 0
  | .param _ => 1
  | .mvar _ => 2
  | .succ _ => 3
  | .max _ _ => 4
  | .imax _ _ => 5

/--
Ordering used by Lean 4.34 universe normalization. The offset is compared only
after removing leading succ constructors, matching `is_norm_lt`.
-/
partial def normLt (a b : Level) : Bool :=
  let (aBase, aOff) := a.toOffset
  let (bBase, bOff) := b.toOffset
  if aBase == bBase then
    aOff < bOff
  else
    match aBase, bBase with
    | .param x, .param y => Name.lt x y
    | .mvar x, .mvar y => Name.lt x y
    | .max a₁ a₂, .max b₁ b₂ =>
      if a₁ != b₁ then normLt a₁ b₁ else normLt a₂ b₂
    | .imax a₁ a₂, .imax b₁ b₂ =>
      if a₁ != b₁ then normLt a₁ b₁ else normLt a₂ b₂
    | _, _ => ctorRank aBase < ctorRank bBase

def insertSorted (x : Level) : List Level → List Level
  | [] => [x]
  | y :: ys =>
    if normLt x y then x :: y :: ys
    else y :: insertSorted x ys

def sortLevels : List Level → List Level
  | [] => []
  | x :: xs => insertSorted x (sortLevels xs)

partial def getMaxArgsAux
    (normalize : Level → Level) : Level → Bool → List Level → List Level
  | .max u v, already, out =>
    getMaxArgsAux normalize v already
      (getMaxArgsAux normalize u already out)
  | u, false, out => getMaxArgsAux normalize (normalize u) true out
  | u, true, out => u :: out

def splitExplicit : List Level → List Level × List Level
  | [] => ([], [])
  | x :: xs =>
    if x.isExplicit then
      let (a, b) := splitExplicit xs
      (x :: a, b)
    else
      ([], x :: xs)

def lastOrZero : List Level → Level
  | [] => .zero
  | [x] => x
  | _ :: xs => lastOrZero xs

def anyOffsetAtLeast (k : Nat) : List Level → Bool
  | [] => false
  | x :: xs => x.getOffset ≥ k || anyOffsetAtLeast k xs

partial def dedupBases : List Level → List Level
  | [] => []
  | x :: xs =>
    let rec go (prev : Level) (rest : List Level) : List Level :=
      match rest with
      | [] => [prev]
      | y :: ys =>
        if prev.getLevelOffset == y.getLevelOffset then
          go y ys
        else
          prev :: go y ys
    go x xs

def mkMaxList : List Level → Level
  | [] => .zero
  | x :: xs => xs.foldl mkMax x

partial def normalize (u : Level) : Level :=
  let k := u.getOffset
  let base := u.getLevelOffset
  match base with
  | .zero | .param _ | .mvar _ => u
  | .succ _ => u
  | .imax a b =>
    if b.isNeverZero then
      addOffset (normalize (mkMax a b)) k
    else
      addOffset (mkIMax (normalize a) (normalize b)) k
  | .max a b =>
    let args :=
      sortLevels
        (getMaxArgsAux normalize b false
          (getMaxArgsAux normalize a false []))
    let (explicit, nonExplicit) := splitExplicit args
    let selected :=
      match explicit with
      | [] => nonExplicit
      | _ =>
        let e := lastOrZero explicit
        if anyOffsetAtLeast e.getOffset nonExplicit then
          nonExplicit
        else
          e :: nonExplicit
    let unique := dedupBases selected
    mkMaxList (unique.map (fun x => addOffset x k))

def isEquiv (u v : Level) : Bool :=
  u == v || normalize u == normalize v

partial def geqCore (u v : Level) : Bool :=
  if u == v || v.isZero then
    true
  else
    match v with
    | .max a b => geqCore u a && geqCore u b
    | .imax a b => geqCore u a && geqCore u b
    | _ =>
      match u with
      | .max a b =>
        if geqCore a v || geqCore b v then true
        else
          let (ub, uk) := u.toOffset
          let (vb, vk) := v.toOffset
          (ub == vb || vb.isZero) && uk ≥ vk
      | .imax _ b => geqCore b v
      | _ =>
        let (ub, uk) := u.toOffset
        let (vb, vk) := v.toOffset
        if ub == vb || vb.isZero then
          uk ≥ vk
        else if uk == vk && uk > 0 then
          geqCore ub vb
        else
          false

def geq (u v : Level) : Bool :=
  geqCore (normalize u) (normalize v)

def lookupParam (name : Name) : List (Name × Level) → Option Level
  | [] => none
  | (n, v) :: rest => if n == name then some v else lookupParam name rest

partial def instantiateParams (u : Level) (subst : List (Name × Level)) : Level :=
  match u with
  | .zero => .zero
  | .succ v => .succ (instantiateParams v subst)
  | .max a b => mkMax (instantiateParams a subst) (instantiateParams b subst)
  | .imax a b => mkIMax (instantiateParams a subst) (instantiateParams b subst)
  | .param n =>
    match lookupParam n subst with
    | some v => v
    | none => u
  | .mvar _ => u

end Level
end PSC1Kernel
