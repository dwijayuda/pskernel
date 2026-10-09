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

/-- An operation dictionary. Class specialization lets the native compiler erase
callback dispatch while retaining one proof of the traversal. -/
class Algebra (β : Type) where
  atom : PsKernelExpr → Nat → β
  unary : PsKernelExpr → Nat → β → β
  binary : PsKernelExpr → Nat → β → β → β
  ternary : PsKernelExpr → Nat → β → β → β → β
  binaryStop : (e : PsKernelExpr) → (d : Nat) → (l : β) →
    Option { v : β // ∀ r, v = binary e d l r } := fun _ _ _ => none
  ternaryStop1 : (e : PsKernelExpr) → (d : Nat) → (t : β) →
    Option { r : β // ∀ v b, r = ternary e d t v b } := fun _ _ _ => none
  ternaryStop2 : (e : PsKernelExpr) → (d : Nat) → (t v : β) →
    Option { r : β // ∀ b, r = ternary e d t v b } := fun _ _ _ _ => none

@[specialize a] def fold (a : Algebra β) (e : PsKernelExpr) (cursor : Nat) : β :=
  match e with
  | .app f x => a.binary e cursor (fold a f cursor) (fold a x cursor)
  | .lam _ t b _ | .forallE _ t b _ =>
      a.binary e cursor (fold a t cursor) (fold a b (cursor + 1))
  | .letE _ t v b _ =>
      a.ternary e cursor (fold a t cursor) (fold a v cursor) (fold a b (cursor + 1))
  | .mdata _ b | .proj _ _ b => a.unary e cursor (fold a b cursor)
  | _ => a.atom e cursor

def isCompound : PsKernelExpr → Bool
  | .app .. | .lam .. | .forallE .. | .letE .. | .mdata .. | .proj .. => true
  | _ => false

/-- A bounded shape check. This is only an execution policy: the pure fold is
cheaper than a memo for the bottom three constructor layers (at most 13 nodes). -/
def smallWithFuel (fuel : Nat) (e : PsKernelExpr) : Bool :=
  match fuel with
  | 0 => false
  | n + 1 =>
    match e with
    | .app f x => smallWithFuel n f && smallWithFuel n x
    | .lam _ t b _ | .forallE _ t b _ => smallWithFuel n t && smallWithFuel n b
    | .letE _ t v b _ => smallWithFuel n t && smallWithFuel n v && smallWithFuel n b
    | .mdata _ b | .proj _ _ b => smallWithFuel n b
    | _ => true

def small (e : PsKernelExpr) : Bool := smallWithFuel 3 e

@[specialize a] def walk (a : Algebra β) (e : @& PsKernelExpr) (cursor : Nat)
    (memo : Memo PsKernelExpr β (fold a)) : Squash (Result (fold a) e cursor) :=
  let descend := fun _ : Unit =>
    match h : e with
    | .app f x =>
      Squash.lift (walk a f cursor memo) fun (fr, m) =>
      match a.binaryStop e cursor fr.1 with
      | some cut =>
          Squash.mk (⟨cut.1, by
            simpa [h, fold, fr.2] using cut.2 (fold a x cursor)⟩, m)
      | none =>
          Squash.lift (walk a x cursor m) fun (xr, m) =>
          Squash.mk (⟨a.binary e cursor fr.1 xr.1, by simp [h, fold, fr.2, xr.2]⟩, m)
    | .lam n t b bi =>
      Squash.lift (walk a t cursor memo) fun (tr, m) =>
      match a.binaryStop e cursor tr.1 with
      | some cut =>
          Squash.mk (⟨cut.1, by
            simpa [h, fold, tr.2] using cut.2 (fold a b (cursor + 1))⟩, m)
      | none =>
          Squash.lift (walk a b (cursor + 1) m) fun (br, m) =>
          Squash.mk (⟨a.binary e cursor tr.1 br.1, by simp [h, fold, tr.2, br.2]⟩, m)
    | .forallE n t b bi =>
      Squash.lift (walk a t cursor memo) fun (tr, m) =>
      match a.binaryStop e cursor tr.1 with
      | some cut =>
          Squash.mk (⟨cut.1, by
            simpa [h, fold, tr.2] using cut.2 (fold a b (cursor + 1))⟩, m)
      | none =>
          Squash.lift (walk a b (cursor + 1) m) fun (br, m) =>
          Squash.mk (⟨a.binary e cursor tr.1 br.1, by simp [h, fold, tr.2, br.2]⟩, m)
    | .letE n t v b nd =>
      Squash.lift (walk a t cursor memo) fun (tr, m) =>
      match a.ternaryStop1 e cursor tr.1 with
      | some cut =>
          Squash.mk (⟨cut.1, by
            simpa [h, fold, tr.2] using cut.2 (fold a v cursor) (fold a b (cursor + 1))⟩, m)
      | none =>
          Squash.lift (walk a v cursor m) fun (vr, m) =>
          match a.ternaryStop2 e cursor tr.1 vr.1 with
          | some cut =>
              Squash.mk (⟨cut.1, by
                simpa [h, fold, tr.2, vr.2] using cut.2 (fold a b (cursor + 1))⟩, m)
          | none =>
              Squash.lift (walk a b (cursor + 1) m) fun (br, m) =>
              Squash.mk (⟨a.ternary e cursor tr.1 vr.1 br.1,
                by simp [h, fold, tr.2, vr.2, br.2]⟩, m)
    | .mdata md b =>
      Squash.lift (walk a b cursor memo) fun (br, m) =>
      Squash.mk (⟨a.unary e cursor br.1, by simp [h, fold, br.2]⟩, m)
    | .proj n i b =>
      Squash.lift (walk a b cursor memo) fun (br, m) =>
      Squash.mk (⟨a.unary e cursor br.1, by simp [h, fold, br.2]⟩, m)
    | .bvar _ | .fvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ =>
      Squash.mk (⟨a.atom e cursor, by simp [h, fold]⟩, memo)
  if small e then Squash.mk (⟨fold a e cursor, rfl⟩, memo)
  else step e cursor memo descend
termination_by structural e

@[inline] def run (a : Algebra β) (e : PsKernelExpr) (cursor : Nat) : β :=
  if small e then fold a e cursor else value (walk a e cursor {})

theorem run_eq (a : Algebra β) (e : PsKernelExpr) (cursor : Nat) :
    run a e cursor = fold a e cursor := by
  unfold run
  split
  · rfl
  · exact value_eq _

@[inline, instance_reducible] def countAlgebra : Algebra Nat where
  atom := fun _ _ => 1
  unary := fun _ _ n => Nat.succ n
  binary := fun _ _ l r => Nat.succ (l + r)
  ternary := fun _ _ t v b => Nat.succ (t + (v + b))

@[inline, instance_reducible] def looseAlgebra : Algebra Bool where
  atom := fun e d => match e with
    | .bvar i => Nat.ble d i
    | _ => false
  unary := fun _ _ b => b
  binary := fun _ _ l r => if l then true else r
  ternary := fun _ _ t v b => if t then true else if v then true else b

  binaryStop := fun _ _ l =>
    if h : l = true then some ⟨true, by intro r; simp [h]⟩ else none
  ternaryStop1 := fun _ _ t =>
    if h : t = true then some ⟨true, by intro v b; simp [h]⟩ else none
  ternaryStop2 := fun _ _ t v =>
    if h : v = true then some ⟨true, by intro b; cases t <;> simp [h]⟩ else none

@[inline, instance_reducible] def fvarAlgebra : Algebra Bool where
  atom := fun e _ => match e with
    | .fvar _ => true
    | _ => false
  unary := fun _ _ b => b
  binary := fun _ _ l r => if l then true else r
  ternary := fun _ _ t v b => if t then true else if v then true else b

  binaryStop := fun _ _ l =>
    if h : l = true then some ⟨true, by intro r; simp [h]⟩ else none
  ternaryStop1 := fun _ _ t =>
    if h : t = true then some ⟨true, by intro v b; simp [h]⟩ else none
  ternaryStop2 := fun _ _ t v =>
    if h : v = true then some ⟨true, by intro b; cases t <;> simp [h]⟩ else none

theorem count_fold (e : PsKernelExpr) (d : Nat) :
    fold countAlgebra e d = psKernelExprNodeCount e := by
  induction e generalizing d <;> simp_all [PsKernelSharing.Algebra.atom, PsKernelSharing.Algebra.unary,
      PsKernelSharing.Algebra.binary, PsKernelSharing.Algebra.ternary, fold, countAlgebra, psKernelExprNodeCount]

theorem loose_fold (e : PsKernelExpr) (d : Nat) :
    fold looseAlgebra e d = psKernelExprHasLooseAt e d := by
  induction e generalizing d <;> simp_all [PsKernelSharing.Algebra.atom, PsKernelSharing.Algebra.unary,
      PsKernelSharing.Algebra.binary, PsKernelSharing.Algebra.ternary, fold, looseAlgebra, psKernelExprHasLooseAt]

theorem fvar_fold (e : PsKernelExpr) (d : Nat) :
    fold fvarAlgebra e d = psKernelExprHasFVar e := by
  induction e generalizing d <;> simp_all [PsKernelSharing.Algebra.atom, PsKernelSharing.Algebra.unary,
      PsKernelSharing.Algebra.binary, PsKernelSharing.Algebra.ternary, fold, fvarAlgebra, psKernelExprHasFVar]

end PsKernelSharing

def psKernelExprNodeCountShared (e : PsKernelExpr) : Nat :=
  if PsKernelSharing.small e then psKernelExprNodeCount e
  else PsKernelSharing.run PsKernelSharing.countAlgebra e 0

def psKernelExprHasLooseAtShared (e : PsKernelExpr) (d : Nat) : Bool :=
  if PsKernelSharing.small e then psKernelExprHasLooseAt e d
  else PsKernelSharing.run PsKernelSharing.looseAlgebra e d

def psKernelExprHasFVarShared (e : PsKernelExpr) : Bool :=
  if PsKernelSharing.small e then psKernelExprHasFVar e
  else PsKernelSharing.run PsKernelSharing.fvarAlgebra e 0

@[csimp] theorem psKernelExprNodeCount_shared_eq :
    psKernelExprNodeCount = psKernelExprNodeCountShared := by
  funext e
  simp [psKernelExprNodeCountShared, PsKernelSharing.run_eq, PsKernelSharing.count_fold]

@[csimp] theorem psKernelExprHasLooseAt_shared_eq :
    psKernelExprHasLooseAt = psKernelExprHasLooseAtShared := by
  funext e d
  simp [psKernelExprHasLooseAtShared, PsKernelSharing.run_eq, PsKernelSharing.loose_fold]

@[csimp] theorem psKernelExprHasFVar_shared_eq :
    psKernelExprHasFVar = psKernelExprHasFVarShared := by
  funext e
  simp [psKernelExprHasFVarShared, PsKernelSharing.run_eq, PsKernelSharing.fvar_fold]

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

@[inline] def rebuildUnary (e : PsKernelExpr) (_d : Nat) (r : Changed) : Changed :=
  if r.2 then
    match e with
    | .mdata md _ => (.mdata md r.1, true)
    | .proj n i _ => (.proj n i r.1, true)
    | _ => (e, false)
  else (e, false)

@[inline] def rebuildBinary (e : PsKernelExpr) (_d : Nat) (l r : Changed) : Changed :=
  let rebuilt : PsKernelExpr := match e with
    | .app _ _ => .app l.1 r.1
    | .lam n _ _ bi => .lam n l.1 r.1 bi
    | .forallE n _ _ bi => .forallE n l.1 r.1 bi
    | _ => e
  if l.2 then (rebuilt, true)
  else if r.2 then (rebuilt, true)
  else (e, false)

@[inline] def rebuildTernary (e : PsKernelExpr) (_d : Nat) (t v b : Changed) : Changed :=
  let rebuilt : PsKernelExpr := match e with
    | .letE n _ _ _ nd => .letE n t.1 v.1 b.1 nd
    | _ => e
  if t.2 then (rebuilt, true)
  else if v.2 then (rebuilt, true)
  else if b.2 then (rebuilt, true)
  else (e, false)

@[inline, instance_reducible] def changedAlgebra (atom : PsKernelExpr → Nat → Changed) : Algebra Changed :=
  { atom := atom, unary := rebuildUnary, binary := rebuildBinary, ternary := rebuildTernary }

end PsKernelSharing

namespace PsKernelSharing

@[inline, instance_reducible] def levelAlgebra (params : List PsKernelName) (levels : List PsKernelLevel) : Algebra PsKernelExpr where
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
    simp_all [PsKernelSharing.Algebra.atom, PsKernelSharing.Algebra.unary,
      PsKernelSharing.Algebra.binary, PsKernelSharing.Algebra.ternary, fold, levelAlgebra, psKernelExprInstantiateLevelParams]

end PsKernelSharing

def psKernelExprInstantiateLevelParamsShared (e : PsKernelExpr)
    (params : List PsKernelName) (levels : List PsKernelLevel) : PsKernelExpr :=
  if PsKernelSharing.small e then psKernelExprInstantiateLevelParams e params levels
  else PsKernelSharing.run (PsKernelSharing.levelAlgebra params levels) e 0

@[csimp] theorem psKernelExprInstantiateLevelParams_shared_eq :
    psKernelExprInstantiateLevelParams = psKernelExprInstantiateLevelParamsShared := by
  funext e params levels
  simp [psKernelExprInstantiateLevelParamsShared, PsKernelSharing.run_eq,
    PsKernelSharing.level_fold]
