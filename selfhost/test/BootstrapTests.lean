import Ps.Foundation.Name
import Ps.Core.Abstract
import Ps.Core.Builtin
import Ps.Core.Equality
import Ps.Core.Expr
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Meta.Context
import Ps.Meta.Infer
import Ps.Meta.Reduce
import Ps.Project.ModuleGraph

def psTestNatEnvironment : PsEnvironment :=
  let declaration :=
    PsDeclaration.axiomDecl
      psNatName
      []
      (PsExpr.sortE (PsLevel.succ PsLevel.zero))
  match psEnvironmentAdd psEnvironmentEmpty declaration with
  | some environment => environment
  | none => psEnvironmentEmpty

def psTestName (value : String) : PsName :=
  psRootName value

def psNameListEq : List PsName -> List PsName -> Bool
  | [], [] => true
  | left :: leftRest, right :: rightRest =>
      psNameEq left right && psNameListEq leftRest rightRest
  | _, _ => false

def psTestModuleGraph : Bool :=
  let a := psTestName "A"
  let b := psTestName "B"
  let nodes := [
    { name := b, imports := [a] : PsModuleNode },
    { name := a, imports := [] : PsModuleNode }
  ]
  match psCreateBuildPlan nodes with
  | Except.error _ => false
  | Except.ok plan => psNameListEq plan.order [a, b]

def psTestScopedMetaAssignment : Bool :=
  let natType := PsExpr.constE psNatName []
  let pushed :=
    psLocalPushBinding
      psLocalEmpty
      (psTestName "x")
      natType
      PsBinderInfo.explicit
  let fresh :=
    psMetaFresh
      psMetaEmpty
      pushed.context
      natType
      PsMetaVarKind.natural
  match fresh.expr with
  | .mvar id =>
      match psMetaAssign fresh.context id (PsExpr.fvar pushed.id) with
      | none => false
      | some _ => true
  | _ => false

def psTestRejectOutOfScopeMetaAssignment : Bool :=
  let natType := PsExpr.constE psNatName []
  let fresh :=
    psMetaFresh
      psMetaEmpty
      psLocalEmpty
      natType
      PsMetaVarKind.natural
  match fresh.expr with
  | .mvar id =>
      match psMetaAssign fresh.context id (PsExpr.fvar 99) with
      | none => true
      | some _ => false
  | _ => false

def psTestBetaWhnf : Bool :=
  let natType := PsExpr.constE psNatName []
  let identity :=
    PsExpr.lam
      (psTestName "x")
      natType
      (PsExpr.bvar 0)
      PsBinderInfo.explicit
  let value := PsExpr.lit (PsLiteral.natural 7)
  let reduced :=
    psWhnf
      psEnvironmentEmpty
      psMetaEmpty
      psLocalEmpty
      (PsExpr.app identity value)
  psExprAlphaEq reduced value

def psTestInferIdentity : Bool :=
  let natType := PsExpr.constE psNatName []
  let name := psTestName "x"
  let identity :=
    PsExpr.lam
      name
      natType
      (PsExpr.bvar 0)
      PsBinderInfo.explicit
  let expected :=
    PsExpr.forallE
      name
      natType
      natType
      PsBinderInfo.explicit
  match psInferType
      psTestNatEnvironment
      psMetaEmpty
      psLocalEmpty
      identity with
  | Except.error _ => false
  | Except.ok actual => psExprAlphaEq actual expected

def psBootstrapTests : Bool :=
  psTestModuleGraph
    && psTestScopedMetaAssignment
    && psTestRejectOutOfScopeMetaAssignment
    && psTestBetaWhnf
    && psTestInferIdentity

def main : IO Unit :=
  if psBootstrapTests then
    IO.println "PSC1_BOOTSTRAP_TESTS: PASS"
  else
    throw (IO.userError "PSC1_BOOTSTRAP_TESTS: FAIL")
