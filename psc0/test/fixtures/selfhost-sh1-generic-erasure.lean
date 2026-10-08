-- The generated compiler consumes this source before inspecting its original IR.
-- These cases distinguish declaration generic order from local-context order.
def sh1GenericCopy {alpha : Type} (values : List alpha) : List alpha :=
  match values with
  | List.nil => List.nil
  | List.cons value rest => List.cons value (sh1GenericCopy rest)

def sh1GenericMap {alpha beta : Type}
    (convert : alpha -> beta) (values : List alpha) : List beta :=
  match values with
  | List.nil => List.nil
  | List.cons value rest => List.cons (convert value) (sh1GenericMap convert rest)

-- Type binders are interleaved with an erased proposition, erased proof, and
-- runtime values. Their call arguments must still be T0, T1, T2 in that order.
def sh1GenericTriple (alpha : Type) {p : Prop} (h : p)
    (first : alpha) (beta : Type) (second : beta)
    (gamma : Type) (third : gamma) (fuel : Nat) : Prod alpha (Prod beta gamma) :=
  match fuel with
  | Nat.zero => Prod.mk first (Prod.mk second third)
  | Nat.succ remaining =>
      sh1GenericTriple alpha h first beta second gamma third remaining

def sh1GenericMono (fuel : Nat) (value : Nat) : Nat :=
  match fuel with
  | Nat.zero => value
  | Nat.succ remaining => sh1GenericMono remaining value
