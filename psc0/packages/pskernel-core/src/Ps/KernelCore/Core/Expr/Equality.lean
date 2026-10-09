import Ps.KernelCore.Core.Expr.Shared
import Lean.Elab.Tactic.Omega

/-!
Exact syntactic equality, with node-pair memoization. This is separate from
kernel definitional equality: no transitive closure or inferred equality is
added to the checker. Even a memo hit must carry this exact pair's result.
-/
namespace PsKernelSharing

def PsKernelStringEqReflexiveLaw : Prop :=
  ∀ value : String,
    psKernelStringEq value value = true

theorem psKernelNameEq_refl_of_string_law
    (hString : PsKernelStringEqReflexiveLaw)
    (name : PsKernelName) :
    psKernelNameEq name name = true := by
  induction name with
  | anonymous =>
      rfl
  | str parent value ih =>
      simp [
        psKernelNameEq,
        hString value,
        ih
      ]
  | num parent value ih =>
      simp [psKernelNameEq, ih]

theorem psKernelLevelEq_refl_of_string_law
    (hString : PsKernelStringEqReflexiveLaw)
    (level : PsKernelLevel) :
    psKernelLevelEq level level = true := by
  induction level with
  | zero =>
      rfl
  | succ inner ih =>
      exact ih
  | max left right ihLeft ihRight =>
      simp [psKernelLevelEq, ihLeft, ihRight]
  | imax left right ihLeft ihRight =>
      simp [psKernelLevelEq, ihLeft, ihRight]
  | param name =>
      exact psKernelNameEq_refl_of_string_law hString name
  | mvar name =>
      exact psKernelNameEq_refl_of_string_law hString name

theorem psKernelLevelListEq_refl_of_string_law
    (hString : PsKernelStringEqReflexiveLaw)
    (levels : List PsKernelLevel) :
    psKernelLevelListEq levels levels = true := by
  induction levels with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [
        psKernelLevelListEq,
        psKernelLevelEq_refl_of_string_law hString,
        ih
      ]

theorem psKernelLiteralEq_refl_of_string_law
    (hString : PsKernelStringEqReflexiveLaw)
    (literal : PsKernelLiteral) :
    psKernelLiteralEq literal literal = true := by
  cases literal with
  | nat value =>
      simp [psKernelLiteralEq]
  | str value =>
      exact hString value

theorem psKernelExprEq_refl_of_string_law
    (hString : PsKernelStringEqReflexiveLaw)
    (expr : PsKernelExpr) :
    psKernelExprEq expr expr = true := by
  induction expr with
  | bvar index =>
      simp [psKernelExprEq]
  | fvar name =>
      exact psKernelNameEq_refl_of_string_law hString name
  | mvar name =>
      exact psKernelNameEq_refl_of_string_law hString name
  | sort level =>
      exact psKernelLevelEq_refl_of_string_law hString level
  | const name levels =>
      simp [
        psKernelExprEq,
        psKernelNameEq_refl_of_string_law hString,
        psKernelLevelListEq_refl_of_string_law hString
      ]
  | app fn arg ihFn ihArg =>
      simp [psKernelExprEq, ihFn, ihArg]
  | lam name type body binderInfo ihType ihBody =>
      simp [psKernelExprEq, ihType, ihBody]
  | forallE name type body binderInfo ihType ihBody =>
      simp [psKernelExprEq, ihType, ihBody]
  | letE name type value body nondep ihType ihValue ihBody =>
      cases nondep <;>
        simp [
          psKernelExprEq,
          ihType,
          ihValue,
          ihBody,
          psKernelBoolEq
        ]
  | lit literal =>
      exact psKernelLiteralEq_refl_of_string_law hString literal
  | mdata metadata body ihBody =>
      simp [psKernelExprEq, ihBody]
  | proj typeName index body ihBody =>
      simp [
        psKernelExprEq,
        psKernelNameEq_refl_of_string_law hString,
        ihBody
      ]


theorem psKernelStringEqFromWithFuel_self_of_cursor_progress
    (value : String)
    (hEnd : ∀ pos : Nat, value.utf8ByteSize ≤ pos ->
      String.Pos.Raw.atEnd value (String.Pos.Raw.mk pos) = true)
    (hStep : ∀ pos : Nat,
      String.Pos.Raw.atEnd value (String.Pos.Raw.mk pos) = false ->
        pos < (String.Pos.Raw.next value (String.Pos.Raw.mk pos)).byteIdx)
    (fuel : Nat) :
    ∀ pos : Nat, 0 < fuel -> value.utf8ByteSize < pos + fuel ->
      psKernelStringEqFromWithFuel fuel value value pos pos = true := by
  induction fuel with
  | zero => intro pos hFuel hBound; omega
  | succ remaining ih =>
      intro pos hFuel hBound
      cases hAtEnd : String.Pos.Raw.atEnd value (String.Pos.Raw.mk pos) with
      | true => simp [psKernelStringEqFromWithFuel, hAtEnd]
      | false =>
          have hBefore : pos < value.utf8ByteSize := by
            by_cases hBefore : pos < value.utf8ByteSize
            · exact hBefore
            · have hPast := hEnd pos (by omega)
              simp [hPast] at hAtEnd
          have hProgress := hStep pos hAtEnd
          have hTail := ih (String.Pos.Raw.next value (String.Pos.Raw.mk pos)).byteIdx
            (by omega) (by omega)
          simpa [psKernelStringEqFromWithFuel, hAtEnd] using hTail

theorem psKernelStringEq_self_of_cursor_progress
    (value : String)
    (hEnd : ∀ pos : Nat, value.utf8ByteSize ≤ pos ->
      String.Pos.Raw.atEnd value (String.Pos.Raw.mk pos) = true)
    (hStep : ∀ pos : Nat,
      String.Pos.Raw.atEnd value (String.Pos.Raw.mk pos) = false ->
        pos < (String.Pos.Raw.next value (String.Pos.Raw.mk pos)).byteIdx) :
    psKernelStringEq value value = true := by
  have h := psKernelStringEqFromWithFuel_self_of_cursor_progress value hEnd hStep
    (Nat.succ value.utf8ByteSize) 0 (by omega) (by omega)
  simpa [psKernelStringEq] using h

/-- Explicit conditional reduction of comparator reflexivity to two cursor properties. -/
theorem psKernelStringEqReflexiveLaw_of_cursor_progress
    (hEnd : ∀ (value : String) (pos : Nat), value.utf8ByteSize ≤ pos ->
      String.Pos.Raw.atEnd value (String.Pos.Raw.mk pos) = true)
    (hStep : ∀ (value : String) (pos : Nat),
      String.Pos.Raw.atEnd value (String.Pos.Raw.mk pos) = false ->
        pos < (String.Pos.Raw.next value (String.Pos.Raw.mk pos)).byteIdx) :
    PsKernelStringEqReflexiveLaw :=
  fun value => psKernelStringEq_self_of_cursor_progress value (hEnd value) (hStep value)


theorem string_reflexive : PsKernelStringEqReflexiveLaw :=
  psKernelStringEqReflexiveLaw_of_cursor_progress
    (fun value pos h => by simp [String.Pos.Raw.atEnd, h])
    (fun value pos _ => String.Pos.Raw.byteIdx_lt_byteIdx_next value (String.Pos.Raw.mk pos))

theorem expr_reflexive (e : PsKernelExpr) : psKernelExprEq e e = true :=
  psKernelExprEq_refl_of_string_law string_reflexive e

@[noinline] def eqSpec (pair : PsKernelExpr × PsKernelExpr) (_cursor : Nat) : Bool :=
  psKernelExprEq pair.1 pair.2

abbrev EqMemo := Memo (PsKernelExpr × PsKernelExpr) Bool eqSpec
abbrev EqResult (left right : PsKernelExpr) := Result eqSpec (left, right) 0

@[inline] def eqStep (left right : @& PsKernelExpr) (memo : EqMemo)
    (descend : Unit → Squash (EqResult left right)) : Squash (EqResult left right) :=
  withPtrAddr left (fun leftAddress =>
    withPtrAddr right (fun rightAddress =>
      let originalDecEq : DecidableEq PsKernelExpr := inferInstance
      letI : DecidableEq PsKernelExpr :=
        fun a b => withPtrEqDecEq a b (fun _ => originalDecEq a b)
      let probePair := fun _ : Unit =>
        probe (leftAddress, rightAddress.toNat) (left, right) 0 memo descend
      if leftAddress == rightAddress then
        match withPtrEqDecEq left right (fun _ => originalDecEq left right) with
        | isTrue h =>
            Squash.mk (⟨true, by subst right; exact (expr_reflexive left).symm⟩, memo)
        | isFalse _ => probePair ()
      else probePair ())
      (fun _ _ => Subsingleton.elim _ _))
    (fun _ _ => Subsingleton.elim _ _)

def eqWalk (left right : @& PsKernelExpr) (memo : EqMemo) :
    Squash (EqResult left right) :=
  let descend := fun _ : Unit =>
    match hl : left, hr : right with
    | .app f a, .app g b =>
      Squash.lift (eqWalk f g memo) fun (r0, memo) =>
      have hr0 : r0.1 = psKernelExprEq f g := r0.2
      if hr0t : r0.1 = true then
        Squash.lift (eqWalk a b memo) fun (r1, memo) =>
        have hr1 : r1.1 = psKernelExprEq a b := r1.2
        Squash.mk (⟨r1.1, by simp [eqSpec, hl, hr, psKernelExprEq, ←hr0, hr0t, ←hr1]⟩, memo)
      else Squash.mk (⟨false, by simp [eqSpec, hl, hr, psKernelExprEq, ←hr0, hr0t]⟩, memo)
    | .lam _ t b _, .lam _ u c _ =>
      Squash.lift (eqWalk t u memo) fun (r0, memo) =>
      have hr0 : r0.1 = psKernelExprEq t u := r0.2
      if hr0t : r0.1 = true then
        Squash.lift (eqWalk b c memo) fun (r1, memo) =>
        have hr1 : r1.1 = psKernelExprEq b c := r1.2
        Squash.mk (⟨r1.1, by simp [eqSpec, hl, hr, psKernelExprEq, ←hr0, hr0t, ←hr1]⟩, memo)
      else Squash.mk (⟨false, by simp [eqSpec, hl, hr, psKernelExprEq, ←hr0, hr0t]⟩, memo)
    | .forallE _ t b _, .forallE _ u c _ =>
      Squash.lift (eqWalk t u memo) fun (r0, memo) =>
      have hr0 : r0.1 = psKernelExprEq t u := r0.2
      if hr0t : r0.1 = true then
        Squash.lift (eqWalk b c memo) fun (r1, memo) =>
        have hr1 : r1.1 = psKernelExprEq b c := r1.2
        Squash.mk (⟨r1.1, by simp [eqSpec, hl, hr, psKernelExprEq, ←hr0, hr0t, ←hr1]⟩, memo)
      else Squash.mk (⟨false, by simp [eqSpec, hl, hr, psKernelExprEq, ←hr0, hr0t]⟩, memo)
    | .letE _ t v b nd, .letE _ u w c ne =>
      Squash.lift (eqWalk t u memo) fun (r0, memo) =>
      have hr0 : r0.1 = psKernelExprEq t u := r0.2
      if hr0t : r0.1 = true then
        Squash.lift (eqWalk v w memo) fun (r1, memo) =>
        have hr1 : r1.1 = psKernelExprEq v w := r1.2
        if hr1t : r1.1 = true then
          Squash.lift (eqWalk b c memo) fun (r2, memo) =>
          have hr2 : r2.1 = psKernelExprEq b c := r2.2
          if hr2t : r2.1 = true then
            Squash.mk (⟨psKernelBoolEq nd ne, by simp [eqSpec, hl, hr, psKernelExprEq, ←hr0, hr0t, ←hr1, hr1t, ←hr2, hr2t]⟩, memo)
          else Squash.mk (⟨false, by simp [eqSpec, hl, hr, psKernelExprEq, ←hr0, hr0t, ←hr1, hr1t, ←hr2, hr2t]⟩, memo)
        else Squash.mk (⟨false, by simp [eqSpec, hl, hr, psKernelExprEq, ←hr0, hr0t, ←hr1, hr1t]⟩, memo)
      else Squash.mk (⟨false, by simp [eqSpec, hl, hr, psKernelExprEq, ←hr0, hr0t]⟩, memo)
    | .mdata md b, .mdata me c =>
      if hg : Nat.beq md me = true then
        Squash.lift (eqWalk b c memo) fun (r0, memo) =>
        have hr0 : r0.1 = psKernelExprEq b c := r0.2
        Squash.mk (⟨r0.1, by simp [eqSpec, hl, hr, psKernelExprEq, hg, ←hr0]⟩, memo)
      else Squash.mk (⟨psKernelExprEq left right, by simp [eqSpec, hl, hr]⟩, memo)
    | .proj n i b, .proj m j c =>
      if hg : psKernelNameEq n m = true ∧ Nat.beq i j = true then
        Squash.lift (eqWalk b c memo) fun (r0, memo) =>
        have hr0 : r0.1 = psKernelExprEq b c := r0.2
        Squash.mk (⟨r0.1, by simp [eqSpec, hl, hr, psKernelExprEq, hg.1, hg.2, ←hr0]⟩, memo)
      else Squash.mk (⟨psKernelExprEq left right, by simp [eqSpec, hl, hr]⟩, memo)
    | _, _ => Squash.mk (⟨psKernelExprEq left right, by simp [eqSpec, hl, hr]⟩, memo)
  if isCompound left then eqStep left right memo descend else descend ()
termination_by structural left

end PsKernelSharing

def psKernelExprEqShared (left right : PsKernelExpr) : Bool :=
  PsKernelSharing.value (PsKernelSharing.eqWalk left right {})

@[csimp] theorem psKernelExprEq_shared_eq : psKernelExprEq = psKernelExprEqShared := by
  funext left right
  exact (PsKernelSharing.value_eq _).symm
