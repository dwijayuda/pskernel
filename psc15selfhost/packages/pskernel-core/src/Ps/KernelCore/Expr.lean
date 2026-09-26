import Ps.KernelCore.Level

inductive PsKernelCoreBinderInfo where
  | default
  | implicit
  | strictImplicit
  | instImplicit

inductive PsKernelCoreLiteral where
  | nat (value : Nat)
  | str (value : String)

inductive PsKernelCoreExpr where
  | bvar (index : Nat)
  | fvar (name : PsKernelCoreName)
  | mvar (name : PsKernelCoreName)
  | sort (level : PsKernelCoreLevel)
  | const
      (name : PsKernelCoreName)
      (levels : PsKernelCoreList PsKernelCoreLevel)
  | app
      (fn : PsKernelCoreExpr)
      (arg : PsKernelCoreExpr)
  | lam
      (name : PsKernelCoreName)
      (type : PsKernelCoreExpr)
      (body : PsKernelCoreExpr)
      (binderInfo : PsKernelCoreBinderInfo)
  | forallE
      (name : PsKernelCoreName)
      (type : PsKernelCoreExpr)
      (body : PsKernelCoreExpr)
      (binderInfo : PsKernelCoreBinderInfo)
  | letE
      (name : PsKernelCoreName)
      (type : PsKernelCoreExpr)
      (value : PsKernelCoreExpr)
      (body : PsKernelCoreExpr)
      (nondep : Bool)
  | lit (value : PsKernelCoreLiteral)
  | mdata
      (metadata : Nat)
      (expr : PsKernelCoreExpr)
  | proj
      (typeName : PsKernelCoreName)
      (index : Nat)
      (expr : PsKernelCoreExpr)
