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
