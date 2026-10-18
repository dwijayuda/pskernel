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

def psExprApplyManyWorker
    (arguments : List PsExpr)
    (fn : PsExpr) : PsExpr :=
  match arguments with
  | [] => fn
  | argument :: rest =>
      psExprApplyManyWorker rest (PsExpr.app fn argument)

def psExprApplyMany
    (fn : PsExpr)
    (arguments : List PsExpr) :
    PsExpr :=
  psExprApplyManyWorker arguments fn


// Syntactic binder inference used by generated recursors. Lean 4.35.0
// kernel/expr.cpp infer_implicit(strict=true) follows dependencies through
// already implicit parameters, but never infers a binder from the result alone.
// This analysis does not perform reduction or alter any binder domain.
def psExprHasLooseBVar (expr : PsExpr) (index : Nat) : Bool :=
  match expr with
  | .bvar actual => actual == index
  | .app fn arg => psExprHasLooseBVar fn index || psExprHasLooseBVar arg index
  | .lam _ domain body _ | .forallE _ domain body _ =>
    psExprHasLooseBVar domain index || psExprHasLooseBVar body (index + 1)
  | .letE _ type value body => psExprHasLooseBVar type index ||
    psExprHasLooseBVar value index || psExprHasLooseBVar body (index + 1)
  | .proj _ _ value => psExprHasLooseBVar value index
  | _ => false

def psExprOccursInExplicitDomain (type : PsExpr) (index : Nat) : Bool :=
  match type with
  | .forallE _ domain body binder =>
    (psExprHasLooseBVar domain index &&
      (match binder with
       | .explicit => true
       | _ => psExprOccursInExplicitDomain body 0)) ||
      psExprOccursInExplicitDomain body (index + 1)
  | _ => false

def psExprInferImplicit (type : PsExpr) : PsExpr :=
  match type with
  | .forallE name domain body binder =>
    let body := psExprInferImplicit body
    let binder := match binder with
      | .explicit => if psExprOccursInExplicitDomain body 0 then .implicit else .explicit
      | _ => binder
    .forallE name domain body binder
  | _ => type
