import PSC1Kernel.Expr

namespace PSC1Kernel

def listGet? : List α → Nat → Option α
  | [], _ => none
  | x :: _, 0 => some x
  | _ :: xs, n + 1 => listGet? xs n

/--
Portable DAG-preserving implementation of loose-bvar lifting.

The Bool reports whether this subtree changed. When no descendant changes we
return the original node, preserving the sharing Lean's kernel relies on,
without pointer APIs or host-specific mutation.
-/
private partial def Expr.liftLooseBVarsChanged
    (e : Expr) (start amount : Nat) : Expr × Bool :=
  if amount == 0 then
    (e, false)
  else
    match e with
    | .bvar i =>
        if i ≥ start then (.bvar (i + amount), true) else (e, false)
    | .app f a =>
        let (f', fc) := f.liftLooseBVarsChanged start amount
        let (a', ac) := a.liftLooseBVarsChanged start amount
        if fc || ac then (.app f' a', true) else (e, false)
    | .lam n t b bi =>
        let (t', tc) := t.liftLooseBVarsChanged start amount
        let (b', bc) := b.liftLooseBVarsChanged (start + 1) amount
        if tc || bc then (.lam n t' b' bi, true) else (e, false)
    | .forallE n t b bi =>
        let (t', tc) := t.liftLooseBVarsChanged start amount
        let (b', bc) := b.liftLooseBVarsChanged (start + 1) amount
        if tc || bc then (.forallE n t' b' bi, true) else (e, false)
    | .letE n t v b nd =>
        let (t', tc) := t.liftLooseBVarsChanged start amount
        let (v', vc) := v.liftLooseBVarsChanged start amount
        let (b', bc) := b.liftLooseBVarsChanged (start + 1) amount
        if tc || vc || bc then (.letE n t' v' b' nd, true) else (e, false)
    | .mdata m b =>
        let (b', bc) := b.liftLooseBVarsChanged start amount
        if bc then (.mdata m b', true) else (e, false)
    | .proj n i b =>
        let (b', bc) := b.liftLooseBVarsChanged start amount
        if bc then (.proj n i b', true) else (e, false)
    | .fvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ => (e, false)

partial def Expr.liftLooseBVars (e : Expr) (start amount : Nat) : Expr :=
  (e.liftLooseBVarsChanged start amount).1

def Expr.lift (e : Expr) (amount : Nat) : Expr :=
  e.liftLooseBVars 0 amount

/--
Portable DAG-preserving instantiation. The changed bit lets parents reuse their
original node when substitution does not affect the subtree, matching the
sharing behavior of Lean's `replace`-based implementation without `unsafe` or
`implemented_by`.
-/
private partial def Expr.instantiateAtChanged
    (e : Expr) (start : Nat) (subst : List Expr) (offset : Nat) : Expr × Bool :=
  match e with
  | .bvar i =>
      let s := start + offset
      if i < s then
        (e, false)
      else
        let relative := i - s
        match listGet? subst relative with
        | some replacement =>
            (replacement.liftLooseBVars 0 offset, true)
        | none =>
            if subst.isEmpty then
              (e, false)
            else
              (.bvar (i - subst.length), true)
  | .app f a =>
      let (f', fc) := f.instantiateAtChanged start subst offset
      let (a', ac) := a.instantiateAtChanged start subst offset
      if fc || ac then (.app f' a', true) else (e, false)
  | .lam n t b bi =>
      let (t', tc) := t.instantiateAtChanged start subst offset
      let (b', bc) := b.instantiateAtChanged start subst (offset + 1)
      if tc || bc then (.lam n t' b' bi, true) else (e, false)
  | .forallE n t b bi =>
      let (t', tc) := t.instantiateAtChanged start subst offset
      let (b', bc) := b.instantiateAtChanged start subst (offset + 1)
      if tc || bc then (.forallE n t' b' bi, true) else (e, false)
  | .letE n t v b nd =>
      let (t', tc) := t.instantiateAtChanged start subst offset
      let (v', vc) := v.instantiateAtChanged start subst offset
      let (b', bc) := b.instantiateAtChanged start subst (offset + 1)
      if tc || vc || bc then (.letE n t' v' b' nd, true) else (e, false)
  | .mdata m b =>
      let (b', bc) := b.instantiateAtChanged start subst offset
      if bc then (.mdata m b', true) else (e, false)
  | .proj n i b =>
      let (b', bc) := b.instantiateAtChanged start subst offset
      if bc then (.proj n i b', true) else (e, false)
  | .fvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ => (e, false)

partial def Expr.instantiateAt
    (e : Expr) (start : Nat) (subst : List Expr) (offset : Nat) : Expr :=
  if subst.isEmpty then e else (e.instantiateAtChanged start subst offset).1

def Expr.instantiate (e : Expr) (subst : List Expr) : Expr :=
  e.instantiateAt 0 subst 0

def Expr.instantiate1 (e replacement : Expr) : Expr :=
  e.instantiate [replacement]

def Expr.reverseList : List Expr → List Expr
  | [] => []
  | x :: xs => Expr.reverseList xs ++ [x]

def Expr.instantiateRev (e : Expr) (subst : List Expr) : Expr :=
  e.instantiate (Expr.reverseList subst)

def Expr.applyArgsCheap (fn : Expr) (args : List Expr) : Expr :=
  args.foldl (fun acc arg => .app acc arg) fn

/--
Lean 4.34 `cheap_beta_reduce`.

This intentionally performs only the two cheap head-beta cases used by the
kernel type checker:
* a consumed lambda body that no longer contains loose bound variables;
* a consumed lambda body that is exactly one of the consumed bound variables.

All other applications are left unchanged.
-/
partial def Expr.cheapBetaReduce (e : Expr) : Expr :=
  match e.getAppFn with
  | .lam _ _ _ _ =>
      let args := e.getAppArgs
      let rec consume (fn : Expr) (count : Nat) : Expr × Nat :=
        match fn with
        | .lam _ _ body _ =>
            if count < args.length then
              consume body (count + 1)
            else
              (fn, count)
        | _ => (fn, count)
      let (body, consumed) := consume e.getAppFn 0
      if consumed == 0 then
        e
      else if !body.hasLooseBVar then
        Expr.applyArgsCheap body (args.drop consumed)
      else
        match body with
        | .bvar index =>
            if index < consumed then
              match listGet? args (consumed - index - 1) with
              | some selected => Expr.applyArgsCheap selected (args.drop consumed)
              | none => e
            else
              e
        | _ => e
  | _ => e

def Name.lastIndexOf (needle : Name) (xs : List Name) : Option Nat :=
  let rec go (rest : List Name) (index : Nat) (answer : Option Nat) : Option Nat :=
    match rest with
    | [] => answer
    | x :: tail =>
      let answer' := if Name.eq needle x then some index else answer
      go tail (index + 1) answer'
  go xs 0 none

/--
Portable DAG-preserving FVar abstraction. Unaffected subtrees are returned
verbatim instead of being rebuilt. This recovers the important sharing property
of Lean's pointer-memoized abstraction while staying inside the PSC1 source
profile.
-/
private partial def Expr.abstractFVarsAtChanged
    (e : Expr) (fvars : List Name) (offset : Nat) : Expr × Bool :=
  match e with
  | .fvar n =>
      match Name.lastIndexOf n fvars with
      | none => (e, false)
      | some i => (.bvar (offset + fvars.length - i - 1), true)
  | .app f a =>
      let (f', fc) := f.abstractFVarsAtChanged fvars offset
      let (a', ac) := a.abstractFVarsAtChanged fvars offset
      if fc || ac then (.app f' a', true) else (e, false)
  | .lam n t b bi =>
      let (t', tc) := t.abstractFVarsAtChanged fvars offset
      let (b', bc) := b.abstractFVarsAtChanged fvars (offset + 1)
      if tc || bc then (.lam n t' b' bi, true) else (e, false)
  | .forallE n t b bi =>
      let (t', tc) := t.abstractFVarsAtChanged fvars offset
      let (b', bc) := b.abstractFVarsAtChanged fvars (offset + 1)
      if tc || bc then (.forallE n t' b' bi, true) else (e, false)
  | .letE n t v b nd =>
      let (t', tc) := t.abstractFVarsAtChanged fvars offset
      let (v', vc) := v.abstractFVarsAtChanged fvars offset
      let (b', bc) := b.abstractFVarsAtChanged fvars (offset + 1)
      if tc || vc || bc then (.letE n t' v' b' nd, true) else (e, false)
  | .mdata m b =>
      let (b', bc) := b.abstractFVarsAtChanged fvars offset
      if bc then (.mdata m b', true) else (e, false)
  | .proj n i b =>
      let (b', bc) := b.abstractFVarsAtChanged fvars offset
      if bc then (.proj n i b', true) else (e, false)
  | .bvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ => (e, false)

partial def Expr.abstractFVarsAt
    (e : Expr) (fvars : List Name) (offset : Nat) : Expr :=
  if fvars.isEmpty then e else (e.abstractFVarsAtChanged fvars offset).1

def Expr.abstractFVars (e : Expr) (fvars : List Name) : Expr :=
  e.abstractFVarsAt fvars 0

end PSC1Kernel
