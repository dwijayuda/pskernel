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

end Level

end ProofScript.Kernel.PSC1
