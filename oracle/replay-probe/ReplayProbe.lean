namespace ReplayProbe
axiom A : Prop
theorem id (p : A) : A := p

inductive MiniNat where
  | zero
  | succ : MiniNat → MiniNat

def one : MiniNat := MiniNat.succ MiniNat.zero

inductive MiniList (α : Type u) where
  | nil
  | cons : α → MiniList α → MiniList α

def singleton {α : Type u} (a : α) : MiniList α := MiniList.cons a MiniList.nil

inductive MiniVec (α : Type u) : MiniNat → Type u where
  | nil : MiniVec α MiniNat.zero
  | cons {n : MiniNat} : α → MiniVec α n → MiniVec α (MiniNat.succ n)

def vecOne {α : Type u} (a : α) : MiniVec α (MiniNat.succ MiniNat.zero) :=
  MiniVec.cons a MiniVec.nil
end ReplayProbe
