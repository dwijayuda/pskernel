import Ps.KernelCore.Checker.Context
import Ps.KernelCore.Metatheory.Comparator
import Ps.KernelCore.Core.LocalContext
import Lean.Elab.Tactic.Omega

/-
Canonical local-context discipline used by checker-generated binders.

The executable LocalContext API accepts arbitrary names, but the checker itself
always generates internal names as userName.num nextIndex.  This Assurance
Plane invariant captures exactly that construction discipline, which is needed
to justify fresh-name generation and cache reuse under binder extension.
-/

def psKernelLocalDeclIndexMeta
    (decl : PsKernelLocalDecl) : Nat :=
  match decl with
  | PsKernelLocalDecl.localDecl index _ _ _ _ =>
      index
  | PsKernelLocalDecl.letDecl index _ _ _ _ =>
      index

def psKernelNameNumIndexMeta
    (name : PsKernelName) : Option Nat :=
  match name with
  | PsKernelName.num _ index =>
      Option.some index
  | _ =>
      Option.none

def PsKernelLocalContextCanonical
    (context : PsKernelLocalContext) : Prop :=
  ∀ (decl : PsKernelLocalDecl),
    List.Mem decl context.decls ->
      psKernelLocalDeclIndexMeta decl < context.nextIndex ∧
      psKernelLocalDeclName decl =
        PsKernelName.num
          (psKernelLocalDeclUserName decl)
          (psKernelLocalDeclIndexMeta decl)

theorem psKernelLocalContextEmpty_canonical :
    PsKernelLocalContextCanonical
      psKernelLocalContextEmpty := by
  intro decl hMem
  cases hMem

theorem psKernelLocalContextAddLocal_canonical
    (context : PsKernelLocalContext)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hCanonical :
      PsKernelLocalContextCanonical context) :
    PsKernelLocalContextCanonical
      (psKernelLocalContextAddLocal
        context
        (PsKernelName.num
          userName
          context.nextIndex)
        userName
        type
        binderInfo) := by
  intro decl hMem
  change
    List.Mem
      decl
      (List.cons
        (PsKernelLocalDecl.localDecl
          context.nextIndex
          (PsKernelName.num
            userName
            context.nextIndex)
          userName
          type
          binderInfo)
        context.decls) at hMem
  cases hMem with
  | head =>
      constructor
      · exact Nat.lt_succ_self context.nextIndex
      · rfl
  | tail _ hTail =>
      have hOld :=
        hCanonical decl hTail
      constructor
      · exact Nat.lt_succ_of_lt hOld.1
      · exact hOld.2

theorem psKernelLocalContextAddLet_canonical
    (context : PsKernelLocalContext)
    (userName : PsKernelName)
    (type value : PsKernelExpr)
    (hCanonical :
      PsKernelLocalContextCanonical context) :
    PsKernelLocalContextCanonical
      (psKernelLocalContextAddLet
        context
        (PsKernelName.num
          userName
          context.nextIndex)
        userName
        type
        value) := by
  intro decl hMem
  change
    List.Mem
      decl
      (List.cons
        (PsKernelLocalDecl.letDecl
          context.nextIndex
          (PsKernelName.num
            userName
            context.nextIndex)
          userName
          type
          value)
        context.decls) at hMem
  cases hMem with
  | head =>
      constructor
      · exact Nat.lt_succ_self context.nextIndex
      · rfl
  | tail _ hTail =>
      have hOld :=
        hCanonical decl hTail
      constructor
      · exact Nat.lt_succ_of_lt hOld.1
      · exact hOld.2

theorem psKernelLocalContextFindIn_some_mem_and_matches_meta
    (name : PsKernelName)
    (decls : List PsKernelLocalDecl)
    (decl : PsKernelLocalDecl)
    (hFind :
      psKernelLocalContextFindIn name decls =
        Option.some decl) :
    List.Mem decl decls ∧
    psKernelNameEq
        (psKernelLocalDeclName decl)
        name =
      true := by
  induction decls with
  | nil =>
      simp [psKernelLocalContextFindIn] at hFind
  | cons head tail ih =>
      cases hMatch :
          psKernelNameEq
            (psKernelLocalDeclName head)
            name with
      | true =>
          simp [
            psKernelLocalContextFindIn,
            hMatch
          ] at hFind
          subst decl
          exact
            ⟨List.Mem.head tail, hMatch⟩
      | false =>
          simp [
            psKernelLocalContextFindIn,
            hMatch
          ] at hFind
          have hTail :=
            ih hFind
          exact
            ⟨
              List.Mem.tail head hTail.1,
              hTail.2
            ⟩

theorem psKernelLocalContextFind_some_mem_and_matches_meta
    (context : PsKernelLocalContext)
    (name : PsKernelName)
    (decl : PsKernelLocalDecl)
    (hFind :
      psKernelLocalContextFind context name =
        Option.some decl) :
    List.Mem decl context.decls ∧
    psKernelNameEq
        (psKernelLocalDeclName decl)
        name =
      true := by
  exact
    psKernelLocalContextFindIn_some_mem_and_matches_meta
      name
      context.decls
      decl
      hFind

theorem psKernelLocalContextCanonical_fresh_absent
    (context : PsKernelLocalContext)
    (base : PsKernelName)
    (hString : PsKernelStringEqSoundLaw)
    (hCanonical :
      PsKernelLocalContextCanonical context) :
    psKernelLocalContextFind
        context
        (PsKernelName.num
          base
          context.nextIndex) =
      Option.none := by
  cases hFind :
      psKernelLocalContextFind
        context
        (PsKernelName.num
          base
          context.nextIndex) with
  | none =>
      rfl
  | some decl =>
      have hFound :=
        psKernelLocalContextFind_some_mem_and_matches_meta
          context
          (PsKernelName.num
            base
            context.nextIndex)
          decl
          hFind
      have hCanon :=
        hCanonical decl hFound.1
      have hNameEq :
          psKernelLocalDeclName decl =
            PsKernelName.num
              base
              context.nextIndex :=
        psKernelNameEq_sound_of_string_law
          hString
          (psKernelLocalDeclName decl)
          (PsKernelName.num
            base
            context.nextIndex)
          hFound.2
      rw [hCanon.2] at hNameEq
      have hIndexEq :
          psKernelLocalDeclIndexMeta decl =
            context.nextIndex := by
        have hProjected :=
          congrArg
            psKernelNameNumIndexMeta
            hNameEq
        simpa [psKernelNameNumIndexMeta] using hProjected
      omega

theorem psKernelLocalContextAddLocal_preserves_old_find
    (context : PsKernelLocalContext)
    (base userName query : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (decl : PsKernelLocalDecl)
    (hString : PsKernelStringEqSoundLaw)
    (hCanonical :
      PsKernelLocalContextCanonical context)
    (hFind :
      psKernelLocalContextFind context query =
        Option.some decl) :
    psKernelLocalContextFind
        (psKernelLocalContextAddLocal
          context
          (PsKernelName.num
            base
            context.nextIndex)
          userName
          type
          binderInfo)
        query =
      Option.some decl := by
  have hFreshNone :=
    psKernelLocalContextCanonical_fresh_absent
      context
      base
      hString
      hCanonical
  have hDifferent :
      psKernelNameEq
          (PsKernelName.num
            base
            context.nextIndex)
          query =
        false := by
    cases hEq :
        psKernelNameEq
          (PsKernelName.num
            base
            context.nextIndex)
          query with
    | false =>
        rfl
    | true =>
        have hName :
            PsKernelName.num
                base
                context.nextIndex =
              query :=
          psKernelNameEq_sound_of_string_law
            hString
            (PsKernelName.num
              base
              context.nextIndex)
            query
            hEq
        rw [← hName] at hFind
        rw [hFreshNone] at hFind
        contradiction
  change
    (if
        psKernelNameEq
          (PsKernelName.num
            base
            context.nextIndex)
          query then
      Option.some
        (PsKernelLocalDecl.localDecl
          context.nextIndex
          (PsKernelName.num
            base
            context.nextIndex)
          userName
          type
          binderInfo)
    else
      psKernelLocalContextFindIn
        query
        context.decls) =
      Option.some decl
  rw [hDifferent]
  change
    psKernelLocalContextFindIn
        query
        context.decls =
      Option.some decl at hFind
  exact hFind

theorem psKernelLocalContextAddLet_preserves_old_find
    (context : PsKernelLocalContext)
    (base userName query : PsKernelName)
    (type value : PsKernelExpr)
    (decl : PsKernelLocalDecl)
    (hString : PsKernelStringEqSoundLaw)
    (hCanonical :
      PsKernelLocalContextCanonical context)
    (hFind :
      psKernelLocalContextFind context query =
        Option.some decl) :
    psKernelLocalContextFind
        (psKernelLocalContextAddLet
          context
          (PsKernelName.num
            base
            context.nextIndex)
          userName
          type
          value)
        query =
      Option.some decl := by
  have hFreshNone :=
    psKernelLocalContextCanonical_fresh_absent
      context
      base
      hString
      hCanonical
  have hDifferent :
      psKernelNameEq
          (PsKernelName.num
            base
            context.nextIndex)
          query =
        false := by
    cases hEq :
        psKernelNameEq
          (PsKernelName.num
            base
            context.nextIndex)
          query with
    | false =>
        rfl
    | true =>
        have hName :
            PsKernelName.num
                base
                context.nextIndex =
              query :=
          psKernelNameEq_sound_of_string_law
            hString
            (PsKernelName.num
              base
              context.nextIndex)
            query
            hEq
        rw [← hName] at hFind
        rw [hFreshNone] at hFind
        contradiction
  change
    (if
        psKernelNameEq
          (PsKernelName.num
            base
            context.nextIndex)
          query then
      Option.some
        (PsKernelLocalDecl.letDecl
          context.nextIndex
          (PsKernelName.num
            base
            context.nextIndex)
          userName
          type
          value)
    else
      psKernelLocalContextFindIn
        query
        context.decls) =
      Option.some decl
  rw [hDifferent]
  change
    psKernelLocalContextFindIn
        query
        context.decls =
      Option.some decl at hFind
  exact hFind

theorem psKernelCheckerContextWithLocal_canonical
    (context : PsKernelCheckerContext)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hCanonical :
      PsKernelLocalContextCanonical
        context.localContext) :
    PsKernelLocalContextCanonical
      (Prod.snd
        (psKernelCheckerContextWithLocal
          context
          userName
          type
          binderInfo)).localContext := by
  simpa [
    psKernelCheckerContextWithLocal,
    psKernelCheckerContextFreshName
  ] using
    psKernelLocalContextAddLocal_canonical
      context.localContext
      userName
      type
      binderInfo
      hCanonical

theorem psKernelCheckerContextWithLet_canonical
    (context : PsKernelCheckerContext)
    (userName : PsKernelName)
    (type value : PsKernelExpr)
    (hCanonical :
      PsKernelLocalContextCanonical
        context.localContext) :
    PsKernelLocalContextCanonical
      (Prod.snd
        (psKernelCheckerContextWithLet
          context
          userName
          type
          value)).localContext := by
  simpa [
    psKernelCheckerContextWithLet,
    psKernelCheckerContextFreshName
  ] using
    psKernelLocalContextAddLet_canonical
      context.localContext
      userName
      type
      value
      hCanonical


def PsKernelLocalContextExtends
    (older newer : PsKernelLocalContext) : Prop :=
  ∀ (name : PsKernelName) (decl : PsKernelLocalDecl),
    psKernelLocalContextFind older name =
        Option.some decl ->
      psKernelLocalContextFind newer name =
        Option.some decl

theorem psKernelLocalContextExtends_refl
    (context : PsKernelLocalContext) :
    PsKernelLocalContextExtends
      context
      context := by
  intro name decl hFind
  exact hFind

theorem psKernelLocalContextExtends_trans
    (first second third : PsKernelLocalContext)
    (hFirst :
      PsKernelLocalContextExtends first second)
    (hSecond :
      PsKernelLocalContextExtends second third) :
    PsKernelLocalContextExtends first third := by
  intro name decl hFind
  exact
    hSecond
      name
      decl
      (hFirst name decl hFind)

theorem psKernelLocalContextAddLocal_extends
    (context : PsKernelLocalContext)
    (base userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hCanonical :
      PsKernelLocalContextCanonical context) :
    PsKernelLocalContextExtends
      context
      (psKernelLocalContextAddLocal
        context
        (PsKernelName.num
          base
          context.nextIndex)
        userName
        type
        binderInfo) := by
  intro name decl hFind
  exact
    psKernelLocalContextAddLocal_preserves_old_find
      context
      base
      userName
      name
      type
      binderInfo
      decl
      hString
      hCanonical
      hFind

theorem psKernelLocalContextAddLet_extends
    (context : PsKernelLocalContext)
    (base userName : PsKernelName)
    (type value : PsKernelExpr)
    (hString : PsKernelStringEqSoundLaw)
    (hCanonical :
      PsKernelLocalContextCanonical context) :
    PsKernelLocalContextExtends
      context
      (psKernelLocalContextAddLet
        context
        (PsKernelName.num
          base
          context.nextIndex)
        userName
        type
        value) := by
  intro name decl hFind
  exact
    psKernelLocalContextAddLet_preserves_old_find
      context
      base
      userName
      name
      type
      value
      decl
      hString
      hCanonical
      hFind

theorem psKernelCheckerContextWithLocal_extends
    (context : PsKernelCheckerContext)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hCanonical :
      PsKernelLocalContextCanonical
        context.localContext) :
    PsKernelLocalContextExtends
      context.localContext
      (Prod.snd
        (psKernelCheckerContextWithLocal
          context
          userName
          type
          binderInfo)).localContext := by
  simpa [
    psKernelCheckerContextWithLocal,
    psKernelCheckerContextFreshName
  ] using
    psKernelLocalContextAddLocal_extends
      context.localContext
      userName
      userName
      type
      binderInfo
      hString
      hCanonical

theorem psKernelCheckerContextWithLet_extends
    (context : PsKernelCheckerContext)
    (userName : PsKernelName)
    (type value : PsKernelExpr)
    (hString : PsKernelStringEqSoundLaw)
    (hCanonical :
      PsKernelLocalContextCanonical
        context.localContext) :
    PsKernelLocalContextExtends
      context.localContext
      (Prod.snd
        (psKernelCheckerContextWithLet
          context
          userName
          type
          value)).localContext := by
  simpa [
    psKernelCheckerContextWithLet,
    psKernelCheckerContextFreshName
  ] using
    psKernelLocalContextAddLet_extends
      context.localContext
      userName
      userName
      type
      value
      hString
      hCanonical


def PsKernelLocalContextFreshBound
    (context : PsKernelLocalContext)
    (nextFresh : Nat) : Prop :=
  ∀ (decl : PsKernelLocalDecl),
    List.Mem decl context.decls ->
      ∃ (base : PsKernelName) (index : Nat),
        psKernelLocalDeclName decl =
            PsKernelName.num base index ∧
          index < nextFresh

theorem psKernelLocalContextEmpty_freshBound
    (nextFresh : Nat) :
    PsKernelLocalContextFreshBound
      psKernelLocalContextEmpty
      nextFresh := by
  intro decl hMem
  cases hMem


theorem psKernelLocalContextFreshBound_mono
    (context : PsKernelLocalContext)
    (oldBound newBound : Nat)
    (hBound :
      PsKernelLocalContextFreshBound
        context
        oldBound)
    (hLe : oldBound ≤ newBound) :
    PsKernelLocalContextFreshBound
      context
      newBound := by
  intro decl hMem
  rcases hBound decl hMem with
    ⟨base, index, hName, hLt⟩
  exact
    ⟨
      base,
      index,
      hName,
      Nat.lt_of_lt_of_le hLt hLe
    ⟩

theorem psKernelLocalContextAddLocal_preserves_freshBound
    (context : PsKernelLocalContext)
    (counter : Nat)
    (base userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hBound :
      PsKernelLocalContextFreshBound
        context
        counter) :
    PsKernelLocalContextFreshBound
      (psKernelLocalContextAddLocal
        context
        (PsKernelName.num base counter)
        userName
        type
        binderInfo)
      (Nat.succ counter) := by
  intro decl hMem
  change
    List.Mem
      decl
      (List.cons
        (PsKernelLocalDecl.localDecl
          context.nextIndex
          (PsKernelName.num base counter)
          userName
          type
          binderInfo)
        context.decls) at hMem
  cases hMem with
  | head =>
      exact
        ⟨
          base,
          counter,
          rfl,
          Nat.lt_succ_self counter
        ⟩
  | tail _ hTail =>
      rcases hBound decl hTail with
        ⟨oldBase, oldIndex, hName, hLt⟩
      exact
        ⟨
          oldBase,
          oldIndex,
          hName,
          Nat.lt_succ_of_lt hLt
        ⟩

theorem psKernelLocalContextAddLet_preserves_freshBound
    (context : PsKernelLocalContext)
    (counter : Nat)
    (base userName : PsKernelName)
    (type value : PsKernelExpr)
    (hBound :
      PsKernelLocalContextFreshBound
        context
        counter) :
    PsKernelLocalContextFreshBound
      (psKernelLocalContextAddLet
        context
        (PsKernelName.num base counter)
        userName
        type
        value)
      (Nat.succ counter) := by
  intro decl hMem
  change
    List.Mem
      decl
      (List.cons
        (PsKernelLocalDecl.letDecl
          context.nextIndex
          (PsKernelName.num base counter)
          userName
          type
          value)
        context.decls) at hMem
  cases hMem with
  | head =>
      exact
        ⟨
          base,
          counter,
          rfl,
          Nat.lt_succ_self counter
        ⟩
  | tail _ hTail =>
      rcases hBound decl hTail with
        ⟨oldBase, oldIndex, hName, hLt⟩
      exact
        ⟨
          oldBase,
          oldIndex,
          hName,
          Nat.lt_succ_of_lt hLt
        ⟩

theorem psKernelLocalContextFreshBound_name_absent
    (context : PsKernelLocalContext)
    (counter : Nat)
    (base : PsKernelName)
    (hString : PsKernelStringEqSoundLaw)
    (hBound :
      PsKernelLocalContextFreshBound
        context
        counter) :
    psKernelLocalContextFind
        context
        (PsKernelName.num base counter) =
      Option.none := by
  cases hFind :
      psKernelLocalContextFind
        context
        (PsKernelName.num base counter) with
  | none =>
      rfl
  | some decl =>
      have hFound :=
        psKernelLocalContextFind_some_mem_and_matches_meta
          context
          (PsKernelName.num base counter)
          decl
          hFind
      rcases hBound decl hFound.1 with
        ⟨declBase, declIndex, hDeclName, hLt⟩
      have hNameEq :
          psKernelLocalDeclName decl =
            PsKernelName.num base counter :=
        psKernelNameEq_sound_of_string_law
          hString
          (psKernelLocalDeclName decl)
          (PsKernelName.num base counter)
          hFound.2
      rw [hDeclName] at hNameEq
      have hIndexEq :
          declIndex = counter := by
        have hProjected :=
          congrArg
            psKernelNameNumIndexMeta
            hNameEq
        simpa [psKernelNameNumIndexMeta] using hProjected
      omega

theorem psKernelLocalContextAddLocal_extends_freshBound
    (context : PsKernelLocalContext)
    (counter : Nat)
    (base userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hBound :
      PsKernelLocalContextFreshBound
        context
        counter) :
    PsKernelLocalContextExtends
      context
      (psKernelLocalContextAddLocal
        context
        (PsKernelName.num base counter)
        userName
        type
        binderInfo) := by
  intro query decl hFind
  have hFreshNone :=
    psKernelLocalContextFreshBound_name_absent
      context counter base hString hBound
  have hDifferent :
      psKernelNameEq
          (PsKernelName.num base counter)
          query =
        false := by
    cases hEq :
        psKernelNameEq
          (PsKernelName.num base counter)
          query with
    | false =>
        rfl
    | true =>
        have hName :
            PsKernelName.num base counter =
              query :=
          psKernelNameEq_sound_of_string_law
            hString
            (PsKernelName.num base counter)
            query
            hEq
        rw [← hName] at hFind
        rw [hFreshNone] at hFind
        contradiction
  change
    (if
        psKernelNameEq
          (PsKernelName.num base counter)
          query then
      Option.some
        (PsKernelLocalDecl.localDecl
          context.nextIndex
          (PsKernelName.num base counter)
          userName
          type
          binderInfo)
    else
      psKernelLocalContextFindIn
        query
        context.decls) =
      Option.some decl
  rw [hDifferent]
  change
    psKernelLocalContextFindIn
        query
        context.decls =
      Option.some decl at hFind
  exact hFind

theorem psKernelLocalContextAddLet_extends_freshBound
    (context : PsKernelLocalContext)
    (counter : Nat)
    (base userName : PsKernelName)
    (type value : PsKernelExpr)
    (hString : PsKernelStringEqSoundLaw)
    (hBound :
      PsKernelLocalContextFreshBound
        context
        counter) :
    PsKernelLocalContextExtends
      context
      (psKernelLocalContextAddLet
        context
        (PsKernelName.num base counter)
        userName
        type
        value) := by
  intro query decl hFind
  have hFreshNone :=
    psKernelLocalContextFreshBound_name_absent
      context counter base hString hBound
  have hDifferent :
      psKernelNameEq
          (PsKernelName.num base counter)
          query =
        false := by
    cases hEq :
        psKernelNameEq
          (PsKernelName.num base counter)
          query with
    | false =>
        rfl
    | true =>
        have hName :
            PsKernelName.num base counter =
              query :=
          psKernelNameEq_sound_of_string_law
            hString
            (PsKernelName.num base counter)
            query
            hEq
        rw [← hName] at hFind
        rw [hFreshNone] at hFind
        contradiction
  change
    (if
        psKernelNameEq
          (PsKernelName.num base counter)
          query then
      Option.some
        (PsKernelLocalDecl.letDecl
          context.nextIndex
          (PsKernelName.num base counter)
          userName
          type
          value)
    else
      psKernelLocalContextFindIn
        query
        context.decls) =
      Option.some decl
  rw [hDifferent]
  change
    psKernelLocalContextFindIn
        query
        context.decls =
      Option.some decl at hFind
  exact hFind


/--
Admission may retain ordinal allocation history from temporary function
arguments after restoring the active declarations. This relation changes no
lookup-visible declaration and cannot move the ordinal counter backwards.
It allocates no new local and relaxes no freshness or typing requirement.
-/
def PsKernelLocalContextOrdinalHistoryExtends
    (older newer : PsKernelLocalContext) : Prop :=
  older.decls = newer.decls ∧ older.nextIndex ≤ newer.nextIndex

theorem psKernelLocalContextOrdinalHistoryExtends_lookup_extends
    (older newer : PsKernelLocalContext)
    (hHistory : PsKernelLocalContextOrdinalHistoryExtends older newer) :
    PsKernelLocalContextExtends older newer := by
  intro name decl hFind
  unfold psKernelLocalContextFind at hFind ⊢
  simpa [hHistory.1] using hFind

theorem psKernelLocalContextOrdinalHistoryExtends_freshBound
    (older newer : PsKernelLocalContext)
    (nextFresh : Nat)
    (hHistory : PsKernelLocalContextOrdinalHistoryExtends older newer)
    (hBound : PsKernelLocalContextFreshBound older nextFresh) :
    PsKernelLocalContextFreshBound newer nextFresh := by
  intro decl hMember
  have hOld : List.Mem decl older.decls := by
    simpa [hHistory.1] using hMember
  exact hBound decl hOld

theorem psKernelLocalContextOrdinalHistoryExtends_trans
    (first second third : PsKernelLocalContext)
    (hFirst : PsKernelLocalContextOrdinalHistoryExtends first second)
    (hSecond : PsKernelLocalContextOrdinalHistoryExtends second third) :
    PsKernelLocalContextOrdinalHistoryExtends first third :=
  ⟨Eq.trans hFirst.1 hSecond.1, Nat.le_trans hFirst.2 hSecond.2⟩
