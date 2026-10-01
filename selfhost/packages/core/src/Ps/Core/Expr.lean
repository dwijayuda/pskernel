import Ps.Foundation.Name
import Ps.Core.Level

inductive PsBinderInfo where
  | explicit
  | implicit
  | strictImplicit
  | instanceImplicit

inductive PsLiteral where
  | natural (value : Nat)
  | string (value : String)

inductive PsExpr where
  | bvar (index : Nat)
  | fvar (id : Nat)
  | mvar (id : Nat)
  | sortE (level : PsLevel)
  | constE (name : PsName) (levels : List PsLevel)
  | app (fn : PsExpr) (arg : PsExpr)
  | lam (name : PsName) (type : PsExpr) (body : PsExpr) (binder : PsBinderInfo)
  | forallE (name : PsName) (type : PsExpr) (body : PsExpr) (binder : PsBinderInfo)
  | letE (name : PsName) (type : PsExpr) (value : PsExpr) (body : PsExpr)
  | lit (value : PsLiteral)
  | proj (typeName : PsName) (index : Nat) (value : PsExpr)
