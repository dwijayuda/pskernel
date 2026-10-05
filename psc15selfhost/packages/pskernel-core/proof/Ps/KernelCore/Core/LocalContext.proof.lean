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
