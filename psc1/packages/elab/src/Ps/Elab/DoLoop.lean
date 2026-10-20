import Ps.Core.Declaration
import Ps.Core.Builtin
import Ps.Elab.Basic

-- Internal ordinary partial iteration. This declaration is emitted into the
-- exact source graph only when a partial source body uses its private name.
-- It is never an axiom in the independently admitted graph, and its recursive
-- equation is never exposed as a logical reduction rule.
def psElabDoLoopName (owner : PsName) : PsName :=
  PsName.num (PsName.str owner "_psc1While") 0

def psElabDoLoopArrow (domain range : PsExpr) : PsExpr :=
  PsExpr.forallE (psRootName "_") domain (psExprLiftBVars 1 0 range)
    PsBinderInfo.explicit

def psElabDoLoopCloseType
    (binders : List (Prod Nat (Prod PsName PsExpr))) (body : PsExpr) : PsExpr :=
  match binders with
  | [] => body
  | entry :: rest =>
      psElabDoLoopCloseType rest
        (PsExpr.forallE entry.snd.fst entry.snd.snd
          (psExprAbstractFVar entry.fst body) PsBinderInfo.explicit)

def psElabDoLoopCloseValue
    (binders : List (Prod Nat (Prod PsName PsExpr))) (body : PsExpr) : PsExpr :=
  match binders with
  | [] => body
  | entry :: rest =>
      psElabDoLoopCloseValue rest
        (PsExpr.lam entry.snd.fst entry.snd.snd
          (psExprAbstractFVar entry.fst body) PsBinderInfo.explicit)

def psElabDoLoopBinders : List (Prod Nat (Prod PsName PsExpr)) :=
  let type0 := PsExpr.sortE (PsLevel.succ PsLevel.zero);
  let stateType := PsExpr.fvar 0;
  let resultType := PsExpr.fvar 1;
  let thunkType := psElabDoLoopArrow (PsExpr.constE psUnitName []) resultType;
  let loopType := psElabDoLoopArrow stateType thunkType;
  let bodyType := psElabDoLoopArrow loopType loopType;
  [Prod.mk 4 (Prod.mk (psRootName "state") stateType),
   Prod.mk 3 (Prod.mk (psRootName "body") bodyType),
   Prod.mk 2 (Prod.mk (psRootName "fallback") thunkType),
   Prod.mk 1 (Prod.mk (psRootName "Result") type0),
   Prod.mk 0 (Prod.mk (psRootName "State") type0)]

def psElabDoLoopType : PsExpr :=
  psElabDoLoopCloseType psElabDoLoopBinders
    (psElabDoLoopArrow (PsExpr.constE psUnitName []) (PsExpr.fvar 1))

def psElabDoLoopDeclaration (name : PsName) : PsDeclaration :=
  let recursiveCall := psExprApplyMany (PsExpr.constE name [])
    [PsExpr.fvar 0, PsExpr.fvar 1, PsExpr.fvar 2, PsExpr.fvar 3, PsExpr.fvar 5];
  let next := PsExpr.lam (psRootName "nextState") (PsExpr.fvar 0)
    (psExprAbstractFVar 5 recursiveCall) PsBinderInfo.explicit;
  let body := psExprApplyMany (PsExpr.fvar 3) [next, PsExpr.fvar 4];
  PsDeclaration.partialDecl name [] psElabDoLoopType
    (psElabDoLoopCloseValue psElabDoLoopBinders body)

def psElabDoLoopOccurs (name : PsName) (term : PsExpr) : Bool :=
  match term with
  | .constE found _ => psNameEq name found
  | .app fn arg => psElabDoLoopOccurs name fn || psElabDoLoopOccurs name arg
  | .lam _ type body _ =>
      psElabDoLoopOccurs name type || psElabDoLoopOccurs name body
  | .forallE _ type body _ =>
      psElabDoLoopOccurs name type || psElabDoLoopOccurs name body
  | .letE _ type value body =>
      psElabDoLoopOccurs name type || psElabDoLoopOccurs name value ||
        psElabDoLoopOccurs name body
  | .proj _ _ value => psElabDoLoopOccurs name value
  | _ => false
