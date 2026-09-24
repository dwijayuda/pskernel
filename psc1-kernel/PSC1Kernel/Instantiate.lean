import PSC1Kernel.Expr

namespace PSC1Kernel

def listGet? : List α → Nat → Option α
  | [], _ => none
  | x :: _, 0 => some x
  | _ :: xs, n + 1 => listGet? xs n

partial def Expr.liftLooseBVars (e : Expr) (start amount : Nat) : Expr :=
  if amount == 0 then e
  else
    match e with
    | .bvar i => if i ≥ start then .bvar (i + amount) else e
    | .app f a => .app (f.liftLooseBVars start amount) (a.liftLooseBVars start amount)
    | .lam n t b bi =>
      .lam n
        (t.liftLooseBVars start amount)
        (b.liftLooseBVars (start + 1) amount)
        bi
    | .forallE n t b bi =>
      .forallE n
        (t.liftLooseBVars start amount)
        (b.liftLooseBVars (start + 1) amount)
        bi
    | .letE n t v b nd =>
      .letE n
        (t.liftLooseBVars start amount)
        (v.liftLooseBVars start amount)
        (b.liftLooseBVars (start + 1) amount)
        nd
    | .mdata m b => .mdata m (b.liftLooseBVars start amount)
    | .proj n i b => .proj n i (b.liftLooseBVars start amount)
    | .fvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ => e

def Expr.lift (e : Expr) (amount : Nat) : Expr :=
  e.liftLooseBVars 0 amount

partial def Expr.instantiateAt
    (e : Expr) (start : Nat) (subst : List Expr) (offset : Nat) : Expr :=
  match e with
  | .bvar i =>
    let s := start + offset
    if i < s then e
    else
      let relative := i - s
      match listGet? subst relative with
      | some replacement => replacement.liftLooseBVars 0 offset
      | none => .bvar (i - subst.length)
  | .app f a =>
    .app
      (f.instantiateAt start subst offset)
      (a.instantiateAt start subst offset)
  | .lam n t b bi =>
    .lam n
      (t.instantiateAt start subst offset)
      (b.instantiateAt start subst (offset + 1))
      bi
  | .forallE n t b bi =>
    .forallE n
      (t.instantiateAt start subst offset)
      (b.instantiateAt start subst (offset + 1))
      bi
  | .letE n t v b nd =>
    .letE n
      (t.instantiateAt start subst offset)
      (v.instantiateAt start subst offset)
      (b.instantiateAt start subst (offset + 1))
      nd
  | .mdata m b => .mdata m (b.instantiateAt start subst offset)
  | .proj n i b => .proj n i (b.instantiateAt start subst offset)
  | .fvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ => e

def Expr.instantiate (e : Expr) (subst : List Expr) : Expr :=
  e.instantiateAt 0 subst 0

def Expr.instantiate1 (e replacement : Expr) : Expr :=
  e.instantiate [replacement]

def Expr.reverseList : List Expr → List Expr
  | [] => []
  | x :: xs => Expr.reverseList xs ++ [x]

def Expr.instantiateRev (e : Expr) (subst : List Expr) : Expr :=
  e.instantiate (Expr.reverseList subst)

def Name.lastIndexOf (needle : Name) (xs : List Name) : Option Nat :=
  let rec go (rest : List Name) (index : Nat) (answer : Option Nat) : Option Nat :=
    match rest with
    | [] => answer
    | x :: tail =>
      let answer' := if Name.eq needle x then some index else answer
      go tail (index + 1) answer'
  go xs 0 none

partial def Expr.abstractFVarsAt
    (e : Expr) (fvars : List Name) (offset : Nat) : Expr :=
  match e with
  | .fvar n =>
    match Name.lastIndexOf n fvars with
    | none => e
    | some i => .bvar (offset + fvars.length - i - 1)
  | .app f a => .app (f.abstractFVarsAt fvars offset) (a.abstractFVarsAt fvars offset)
  | .lam n t b bi =>
    .lam n
      (t.abstractFVarsAt fvars offset)
      (b.abstractFVarsAt fvars (offset + 1))
      bi
  | .forallE n t b bi =>
    .forallE n
      (t.abstractFVarsAt fvars offset)
      (b.abstractFVarsAt fvars (offset + 1))
      bi
  | .letE n t v b nd =>
    .letE n
      (t.abstractFVarsAt fvars offset)
      (v.abstractFVarsAt fvars offset)
      (b.abstractFVarsAt fvars (offset + 1))
      nd
  | .mdata m b => .mdata m (b.abstractFVarsAt fvars offset)
  | .proj n i b => .proj n i (b.abstractFVarsAt fvars offset)
  | .bvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ => e

def Expr.abstractFVars (e : Expr) (fvars : List Name) : Expr :=
  e.abstractFVarsAt fvars 0

end PSC1Kernel
