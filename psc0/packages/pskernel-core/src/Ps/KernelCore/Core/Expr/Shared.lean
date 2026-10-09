import Ps.KernelCore.Core.Expr.Basic
import Ps.KernelCore.Core.SharedMemo

/-!
One certified, cursor-aware traversal for all expression syntax operations.
The pure fold is the specification. Memo keys include the binder cursor; each
operation fixes its algebra and creates its own table, so substitution parameters
cannot leak between invocations. Original nodes are retained in memo entries.
-/
deriving instance DecidableEq for PsKernelName
deriving instance DecidableEq for PsKernelLevel
deriving instance DecidableEq for PsKernelBinderInfo
deriving instance DecidableEq for PsKernelLiteral
deriving instance DecidableEq for PsKernelExpr

namespace PsKernelSharing

structure Algebra (β : Type) where
  atom : PsKernelExpr → Nat → β
  unary : PsKernelExpr → Nat → β → β
  binary : PsKernelExpr → Nat → β → β → β
  ternary : PsKernelExpr → Nat → β → β → β → β

def fold (a : Algebra β) (e : PsKernelExpr) (cursor : Nat) : β :=
  match e with
  | .app f x => a.binary e cursor (fold a f cursor) (fold a x cursor)
  | .lam _ t b _ | .forallE _ t b _ =>
      a.binary e cursor (fold a t cursor) (fold a b (cursor + 1))
  | .letE _ t v b _ =>
      a.ternary e cursor (fold a t cursor) (fold a v cursor) (fold a b (cursor + 1))
  | .mdata _ b | .proj _ _ b => a.unary e cursor (fold a b cursor)
  | _ => a.atom e cursor

def walk (a : Algebra β) (e : @& PsKernelExpr) (cursor : Nat)
    (memo : Memo PsKernelExpr β (fold a)) : Squash (Result (fold a) e cursor) :=
  match e with
  | .app f x =>
    step e cursor memo fun _ =>
      Squash.lift (walk a f cursor memo) fun (fr, m) =>
      Squash.lift (walk a x cursor m) fun (xr, m) =>
      Squash.mk (⟨a.binary e cursor fr.1 xr.1, by simp [fold, fr.2, xr.2]⟩, m)
  | .lam n t b bi =>
    step e cursor memo fun _ =>
      Squash.lift (walk a t cursor memo) fun (tr, m) =>
      Squash.lift (walk a b (cursor + 1) m) fun (br, m) =>
      Squash.mk (⟨a.binary e cursor tr.1 br.1, by simp [fold, tr.2, br.2]⟩, m)
  | .forallE n t b bi =>
    step e cursor memo fun _ =>
      Squash.lift (walk a t cursor memo) fun (tr, m) =>
      Squash.lift (walk a b (cursor + 1) m) fun (br, m) =>
      Squash.mk (⟨a.binary e cursor tr.1 br.1, by simp [fold, tr.2, br.2]⟩, m)
  | .letE n t v b nd =>
    step e cursor memo fun _ =>
      Squash.lift (walk a t cursor memo) fun (tr, m) =>
      Squash.lift (walk a v cursor m) fun (vr, m) =>
      Squash.lift (walk a b (cursor + 1) m) fun (br, m) =>
      Squash.mk (⟨a.ternary e cursor tr.1 vr.1 br.1,
        by simp [fold, tr.2, vr.2, br.2]⟩, m)
  | .mdata md b =>
    step e cursor memo fun _ =>
      Squash.lift (walk a b cursor memo) fun (br, m) =>
      Squash.mk (⟨a.unary e cursor br.1, by simp [fold, br.2]⟩, m)
  | .proj n i b =>
    step e cursor memo fun _ =>
      Squash.lift (walk a b cursor memo) fun (br, m) =>
      Squash.mk (⟨a.unary e cursor br.1, by simp [fold, br.2]⟩, m)
  | .bvar _ | .fvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ =>
      Squash.mk (⟨a.atom e cursor, rfl⟩, memo)

def run (a : Algebra β) (e : PsKernelExpr) (cursor : Nat) : β :=
  value (walk a e cursor {})

theorem run_eq (a : Algebra β) (e : PsKernelExpr) (cursor : Nat) :
    run a e cursor = fold a e cursor :=
  value_eq _

def countAlgebra : Algebra Nat where
  atom := fun _ _ => 1
  unary := fun _ _ n => Nat.succ n
  binary := fun _ _ l r => Nat.succ (l + r)
  ternary := fun _ _ t v b => Nat.succ (t + (v + b))

def looseAlgebra : Algebra Bool where
  atom := fun e d => match e with
    | .bvar i => Nat.ble d i
    | _ => false
  unary := fun _ _ b => b
  binary := fun _ _ l r => if l then true else r
  ternary := fun _ _ t v b => if t then true else if v then true else b

def fvarAlgebra : Algebra Bool where
  atom := fun e _ => match e with
    | .fvar _ => true
    | _ => false
  unary := fun _ _ b => b
  binary := fun _ _ l r => if l then true else r
  ternary := fun _ _ t v b => if t then true else if v then true else b

theorem count_fold (e : PsKernelExpr) (d : Nat) :
    fold countAlgebra e d = psKernelExprNodeCount e := by
  induction e generalizing d <;> simp_all [fold, countAlgebra, psKernelExprNodeCount]

theorem loose_fold (e : PsKernelExpr) (d : Nat) :
    fold looseAlgebra e d = psKernelExprHasLooseAt e d := by
  induction e generalizing d <;> simp_all [fold, looseAlgebra, psKernelExprHasLooseAt]

theorem fvar_fold (e : PsKernelExpr) (d : Nat) :
    fold fvarAlgebra e d = psKernelExprHasFVar e := by
  induction e generalizing d <;> simp_all [fold, fvarAlgebra, psKernelExprHasFVar]

end PsKernelSharing

def psKernelExprNodeCountShared (e : PsKernelExpr) : Nat :=
  PsKernelSharing.run PsKernelSharing.countAlgebra e 0

def psKernelExprHasLooseAtShared (e : PsKernelExpr) (d : Nat) : Bool :=
  PsKernelSharing.run PsKernelSharing.looseAlgebra e d

def psKernelExprHasFVarShared (e : PsKernelExpr) : Bool :=
  PsKernelSharing.run PsKernelSharing.fvarAlgebra e 0

@[csimp] theorem psKernelExprNodeCount_shared_eq :
    psKernelExprNodeCount = psKernelExprNodeCountShared := by
  funext e
  rw [psKernelExprNodeCountShared, PsKernelSharing.run_eq, PsKernelSharing.count_fold]

@[csimp] theorem psKernelExprHasLooseAt_shared_eq :
    psKernelExprHasLooseAt = psKernelExprHasLooseAtShared := by
  funext e d
  rw [psKernelExprHasLooseAtShared, PsKernelSharing.run_eq, PsKernelSharing.loose_fold]

@[csimp] theorem psKernelExprHasFVar_shared_eq :
    psKernelExprHasFVar = psKernelExprHasFVarShared := by
  funext e
  rw [psKernelExprHasFVarShared, PsKernelSharing.run_eq, PsKernelSharing.fvar_fold]

def psKernelExprHasLooseBVarShared (e : PsKernelExpr) : Bool :=
  psKernelExprHasLooseAtShared e 0

@[csimp] theorem psKernelExprHasLooseBVar_shared_eq :
    psKernelExprHasLooseBVar = psKernelExprHasLooseBVarShared := by
  funext e
  exact congrFun (congrFun psKernelExprHasLooseAt_shared_eq e) 0

def psKernelExprConsumeTypeAnnotationsShared (e : PsKernelExpr) : PsKernelExpr :=
  psKernelExprConsumeTypeAnnotationsWithFuel (Nat.succ (psKernelExprNodeCountShared e)) e

@[csimp] theorem psKernelExprConsumeTypeAnnotations_shared_eq :
    psKernelExprConsumeTypeAnnotations = psKernelExprConsumeTypeAnnotationsShared := by
  funext e
  simp only [psKernelExprConsumeTypeAnnotations, psKernelExprConsumeTypeAnnotationsShared,
    ← psKernelExprNodeCount_shared_eq]

namespace PsKernelSharing

abbrev Changed := PsKernelExpr × Bool

def rebuildUnary (e : PsKernelExpr) (_d : Nat) (r : Changed) : Changed :=
  if r.2 then
    match e with
    | .mdata md _ => (.mdata md r.1, true)
    | .proj n i _ => (.proj n i r.1, true)
    | _ => (e, false)
  else (e, false)

def rebuildBinary (e : PsKernelExpr) (_d : Nat) (l r : Changed) : Changed :=
  let rebuilt : PsKernelExpr := match e with
    | .app _ _ => .app l.1 r.1
    | .lam n _ _ bi => .lam n l.1 r.1 bi
    | .forallE n _ _ bi => .forallE n l.1 r.1 bi
    | _ => e
  if l.2 then (rebuilt, true)
  else if r.2 then (rebuilt, true)
  else (e, false)

def rebuildTernary (e : PsKernelExpr) (_d : Nat) (t v b : Changed) : Changed :=
  let rebuilt : PsKernelExpr := match e with
    | .letE n _ _ _ nd => .letE n t.1 v.1 b.1 nd
    | _ => e
  if t.2 then (rebuilt, true)
  else if v.2 then (rebuilt, true)
  else if b.2 then (rebuilt, true)
  else (e, false)

def changedAlgebra (atom : PsKernelExpr → Nat → Changed) : Algebra Changed :=
  ⟨atom, rebuildUnary, rebuildBinary, rebuildTernary⟩

end PsKernelSharing

namespace PsKernelSharing

def levelAlgebra (params : List PsKernelName) (levels : List PsKernelLevel) : Algebra PsKernelExpr where
  atom := fun e _ => match e with
    | .sort u => .sort (psKernelLevelInstantiateParams u params levels)
    | .const n us => .const n (psKernelInstantiateLevelList us params levels)
    | _ => e
  unary := fun e _ b => match e with
    | .mdata md _ => .mdata md b
    | .proj n i _ => .proj n i b
    | _ => e
  binary := fun e _ l r => match e with
    | .app _ _ => .app l r
    | .lam n _ _ bi => .lam n l r bi
    | .forallE n _ _ bi => .forallE n l r bi
    | _ => e
  ternary := fun e _ t v b => match e with
    | .letE n _ _ _ nd => .letE n t v b nd
    | _ => e

theorem level_fold (e : PsKernelExpr) (d : Nat)
    (params : List PsKernelName) (levels : List PsKernelLevel) :
    fold (levelAlgebra params levels) e d = psKernelExprInstantiateLevelParams e params levels := by
  induction e generalizing d <;>
    simp_all [fold, levelAlgebra, psKernelExprInstantiateLevelParams]

end PsKernelSharing

def psKernelExprInstantiateLevelParamsShared (e : PsKernelExpr)
    (params : List PsKernelName) (levels : List PsKernelLevel) : PsKernelExpr :=
  PsKernelSharing.run (PsKernelSharing.levelAlgebra params levels) e 0

@[csimp] theorem psKernelExprInstantiateLevelParams_shared_eq :
    psKernelExprInstantiateLevelParams = psKernelExprInstantiateLevelParamsShared := by
  funext e params levels
  rw [psKernelExprInstantiateLevelParamsShared, PsKernelSharing.run_eq,
    PsKernelSharing.level_fold]
