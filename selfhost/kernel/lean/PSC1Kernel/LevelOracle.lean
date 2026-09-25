import Lean.Level
import PSC1Kernel.Level

namespace PSC1Kernel.LevelOracle

open PSC1Kernel

def toLean : Level → Lean.Level
  | .zero => .zero
  | .succ u => .succ (toLean u)
  | .max u v => .max (toLean u) (toLean v)
  | .imax u v => .imax (toLean u) (toLean v)
  | .param n => .param n
  | .mvar n => .mvar ⟨n⟩

def u : Name := `u
def v : Name := `v
def w : Name := `w

def samples : List Level := [
  .zero,
  .succ .zero,
  .succ (.succ .zero),
  .param u,
  .param v,
  .succ (.param u),
  .max (.param u) (.param v),
  .max (.succ (.param u)) (.param u),
  .imax (.param u) (.param v),
  .imax (.param u) (.succ (.param v)),
  .max (.max (.param u) (.param v)) (.succ (.param u)),
  .succ (.max (.param u) (.imax (.param v) (.param w)))
]

def all (p : α → Bool) : List α → Bool
  | [] => true
  | x :: xs => p x && all p xs

def allPairs (p : α → α → Bool) : List α → Bool
  | [] => true
  | x :: xs =>
    all (fun y => p x y && p y x) (x :: xs) &&
    allPairs p xs

def normalizeParity : Bool :=
  all (fun x => toLean (Level.normalize x) == Lean.Level.normalize (toLean x)) samples

def equivalenceParity : Bool :=
  allPairs
    (fun x y =>
      Level.isEquiv x y == Lean.Level.isEquiv (toLean x) (toLean y))
    samples

def geqParity : Bool :=
  allPairs
    (fun x y =>
      Level.geq x y == Lean.Level.geq (toLean x) (toLean y))
    samples

#guard normalizeParity
#guard equivalenceParity
#guard geqParity

-- Regression for the stable-4.34 max/imax fallthrough case that previously
-- exposed an incorrect early return in the TypeScript port.
def maxUV : Level := .max (.param u) (.param v)
def imaxUV : Level := .imax (.param u) (.param v)
#guard Level.geq maxUV imaxUV == Lean.Level.geq (toLean maxUV) (toLean imaxUV)

end PSC1Kernel.LevelOracle
