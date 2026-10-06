import Ps.KernelCore.Core.LocalContext

theorem psKernelLocalContextFindIn_nil
    (name : PsKernelName) :
    psKernelLocalContextFindIn name List.nil = Option.none := by
  rfl

theorem psKernelLocalContextEmpty_find
    (name : PsKernelName) :
    psKernelLocalContextFind psKernelLocalContextEmpty name =
      Option.none := by
  rfl

theorem psKernelLocalContextAddLocal_nextIndex
    (context : PsKernelLocalContext)
    (name userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    (psKernelLocalContextAddLocal
      context name userName type binderInfo).nextIndex =
      Nat.succ context.nextIndex := by
  rfl

theorem psKernelLocalContextAddLet_nextIndex
    (context : PsKernelLocalContext)
    (name userName : PsKernelName)
    (type value : PsKernelExpr) :
    (psKernelLocalContextAddLet
      context name userName type value).nextIndex =
      Nat.succ context.nextIndex := by
  rfl

theorem psKernelLocalDeclValue_local_none
    (index : Nat)
    (name userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelLocalDeclValue
      (PsKernelLocalDecl.localDecl
        index name userName type binderInfo) =
      Option.none := by
  rfl

theorem psKernelLocalDeclValue_let_some
    (index : Nat)
    (name userName : PsKernelName)
    (type value : PsKernelExpr) :
    psKernelLocalDeclValue
      (PsKernelLocalDecl.letDecl
        index name userName type value) =
      Option.some value := by
  rfl


theorem psKernelLocalContextFindIn_some_mem_and_matches
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
          constructor
          · exact List.Mem.head tail
          · exact hMatch
      | false =>
          simp [
            psKernelLocalContextFindIn,
            hMatch
          ] at hFind
          have hTail := ih hFind
          constructor
          · exact List.mem_cons_of_mem head hTail.1
          · exact hTail.2

theorem psKernelLocalContextFind_some_mem_and_matches
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
    psKernelLocalContextFindIn_some_mem_and_matches
      name
      context.decls
      decl
      hFind
