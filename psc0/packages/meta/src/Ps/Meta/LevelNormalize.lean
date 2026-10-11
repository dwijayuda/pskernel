import Ps.Core.Equality

-- Sound level simplification shared by inference, unification and read-only
-- conversion. Unknown imax branches stay symbolic; no constraint is guessed.
def psLevelAlwaysPositive : PsLevel → Bool
  | .succ _ => true
  | .max a b => psLevelAlwaysPositive a || psLevelAlwaysPositive b
  | .imax _ b => psLevelAlwaysPositive b
  | _ => false

def psLevelLeqWithFuel (fuel : Nat) (a b : PsLevel) : Bool :=
  if psLevelStructuralEq a b then true else
  match fuel with
  | 0 => false
  | fuel + 1 =>
    match a, b with
    | .zero, _ => true
    | .succ a, .succ b => psLevelLeqWithFuel fuel a b
    | .max a₁ a₂, b => psLevelLeqWithFuel fuel a₁ b && psLevelLeqWithFuel fuel a₂ b
    | a, .max b₁ b₂ => psLevelLeqWithFuel fuel a b₁ || psLevelLeqWithFuel fuel a b₂
    | a, .succ b => psLevelLeqWithFuel fuel a b
    | _, _ => false

def psLevelMax (a b : PsLevel) : PsLevel :=
  if psLevelLeqWithFuel 256 a b then b
  else if psLevelLeqWithFuel 256 b a then a
  else .max a b

def psLevelNormalize : PsLevel → PsLevel
  | .succ a => .succ (psLevelNormalize a)
  | .max a b => psLevelMax (psLevelNormalize a) (psLevelNormalize b)
  | .imax a b =>
    let a := psLevelNormalize a
    let b := psLevelNormalize b
    match b with
    | .zero => .zero
    | _ =>
      if psLevelAlwaysPositive b then psLevelMax a b
      else if psLevelLeqWithFuel 256 a b then b
      else .imax a b
  | level => level

def psLevelEquivalent (a b : PsLevel) : Bool :=
  let a := psLevelNormalize a
  let b := psLevelNormalize b
  psLevelLeqWithFuel 256 a b && psLevelLeqWithFuel 256 b a
