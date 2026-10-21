import Ps.Environment.SelfHostPrelude
import Ps.Core.Abstract
import Ps.Core.Subst

-- These are ordinary total Core definitions, independently replayed by the
-- official Lean provider. Numeric name components cannot be authored by source.
-- Keeping the recursor major as a declaration parameter lets checked erasure
-- map each induction hypothesis to the correct helper call.
def psControlListFoldName : PsName :=
  PsName.num (psRootName "_psc1ForList") 0

def psControlNatFoldName : PsName :=
  PsName.num (psRootName "_psc1ForNat") 0

structure PsControlBinder where
  id : Nat
  name : PsName
  type : PsExpr

def psControlApplyArguments (arguments : List PsExpr) : PsExpr -> PsExpr :=
  match arguments with
  | List.nil => fun (fn : PsExpr) => fn
  | List.cons argument rest =>
      fun (fn : PsExpr) =>
        let smaller : PsExpr -> PsExpr := psControlApplyArguments rest;
        smaller (PsExpr.app fn argument)

def psControlApply (fn : PsExpr) (arguments : List PsExpr) : PsExpr :=
  psControlApplyArguments arguments fn

def psControlClose
    (lambda : Bool) (binders : List PsControlBinder) (body : PsExpr) : PsExpr :=
  match binders with
  | List.nil => body
  | List.cons binder rest =>
      let inner := psControlClose lambda rest body;
      let closed := psExprAbstractFVar binder.id inner;
      if lambda then
        PsExpr.lam binder.name binder.type closed PsBinderInfo.explicit
      else
        PsExpr.forallE binder.name binder.type closed PsBinderInfo.explicit

def psControlListFoldDeclaration : PsDeclaration :=
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);
  let alpha := PsExpr.fvar 0;
  let result := PsExpr.fvar 1;
  let base := PsExpr.fvar 2;
  let step := PsExpr.fvar 3;
  let major := PsExpr.fvar 4;
  let listType := psSelfHostListOf alpha;
  let stepType := psControlClose false
    [PsControlBinder.mk 8 (psRootName "element") alpha,
      PsControlBinder.mk 9 (psRootName "rest") result] result;
  let binders :=
    [PsControlBinder.mk 0 (psRootName "Element") typeType,
      PsControlBinder.mk 1 (psRootName "Result") typeType,
      PsControlBinder.mk 2 (psRootName "base") result,
      PsControlBinder.mk 3 (psRootName "step") stepType,
      PsControlBinder.mk 4 (psRootName "values") listType];
  let motive := psControlClose true
    [PsControlBinder.mk 10 (psRootName "_major") listType] result;
  let minor := psControlClose true
    [PsControlBinder.mk 5 (psRootName "element") alpha,
      PsControlBinder.mk 6 (psRootName "tail") listType,
      PsControlBinder.mk 7 (psRootName "rest") result]
    (psControlApply step [PsExpr.fvar 5, PsExpr.fvar 7]);
  let value := psControlApply
    (PsExpr.constE psSelfHostListRecName [PsLevel.succ PsLevel.zero])
    [alpha, motive, base, minor, major];
  PsDeclaration.definitionDecl psControlListFoldName []
    (psControlClose false binders result) (psControlClose true binders value)

def psControlNatFoldDeclaration : PsDeclaration :=
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);
  let natType := PsExpr.constE psNatName [];
  let result := PsExpr.fvar 0;
  let base := PsExpr.fvar 1;
  let step := PsExpr.fvar 2;
  let major := PsExpr.fvar 3;
  let stepType := psControlClose false
    [PsControlBinder.mk 8 (psRootName "index") natType,
      PsControlBinder.mk 9 (psRootName "rest") result] result;
  let binders :=
    [PsControlBinder.mk 0 (psRootName "Result") typeType,
      PsControlBinder.mk 1 (psRootName "base") result,
      PsControlBinder.mk 2 (psRootName "step") stepType,
      PsControlBinder.mk 3 (psRootName "count") natType];
  let motive := psControlClose true
    [PsControlBinder.mk 10 (psRootName "_major") natType] result;
  let minor := psControlClose true
    [PsControlBinder.mk 4 (psRootName "index") natType,
      PsControlBinder.mk 5 (psRootName "rest") result]
    (psControlApply step [PsExpr.fvar 4, PsExpr.fvar 5]);
  let value := psControlApply
    (PsExpr.constE psNatRecName [PsLevel.succ PsLevel.zero])
    [motive, base, minor, major];
  PsDeclaration.definitionDecl psControlNatFoldName []
    (psControlClose false binders result) (psControlClose true binders value)

-- Deferred IHs keep iterator continuations behind explicit Unit thunks.
-- These are total recursor definitions, not partial loops or runtime axioms.
def psControlLazyListFoldName : PsName :=
  PsName.num (psRootName "_psc1ForListDeferred") 0

def psControlLazyNatFoldName : PsName :=
  PsName.num (psRootName "_psc1ForNatDeferred") 0

def psControlListReverseName : PsName :=
  PsName.num (psRootName "_psc1ForArrayReverse") 0

def psControlArrayToListName : PsName :=
  PsName.num (psRootName "_psc1ForArrayItems") 0

def psControlDeferredType (result : PsExpr) : PsExpr :=
  PsExpr.forallE (psRootName "_unit") (PsExpr.constE psUnitName [])
    (psExprLiftBVars 1 0 result) PsBinderInfo.explicit

def psControlLazyListFoldDeclaration : PsDeclaration :=
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);
  let alpha := PsExpr.fvar 0;
  let result := PsExpr.fvar 1;
  let listType := psSelfHostListOf alpha;
  let stepType := psControlClose false
    [PsControlBinder.mk 8 (psRootName "element") alpha,
      PsControlBinder.mk 9 (psRootName "rest") (psControlDeferredType result)] result;
  let binders :=
    [PsControlBinder.mk 0 (psRootName "Element") typeType,
      PsControlBinder.mk 1 (psRootName "Result") typeType,
      PsControlBinder.mk 2 (psRootName "base") result,
      PsControlBinder.mk 3 (psRootName "step") stepType,
      PsControlBinder.mk 4 (psRootName "values") listType];
  let motive := psControlClose true
    [PsControlBinder.mk 10 (psRootName "_major") listType] result;
  let deferred := psControlClose true
    [PsControlBinder.mk 8 (psRootName "_unit") (PsExpr.constE psUnitName [])]
    (PsExpr.fvar 7);
  let minor := psControlClose true
    [PsControlBinder.mk 5 (psRootName "element") alpha,
      PsControlBinder.mk 6 (psRootName "tail") listType,
      PsControlBinder.mk 7 (psRootName "rest") result]
    (psControlApply (PsExpr.fvar 3) [PsExpr.fvar 5, deferred]);
  let value := psControlApply
    (PsExpr.constE psSelfHostListRecName [PsLevel.succ PsLevel.zero])
    [alpha, motive, PsExpr.fvar 2, minor, PsExpr.fvar 4];
  PsDeclaration.definitionDecl psControlLazyListFoldName []
    (psControlClose false binders result) (psControlClose true binders value)

def psControlLazyNatFoldDeclaration : PsDeclaration :=
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);
  let natType := PsExpr.constE psNatName [];
  let result := PsExpr.fvar 0;
  let stepType := psControlClose false
    [PsControlBinder.mk 8 (psRootName "index") natType,
      PsControlBinder.mk 9 (psRootName "rest") (psControlDeferredType result)] result;
  let binders :=
    [PsControlBinder.mk 0 (psRootName "Result") typeType,
      PsControlBinder.mk 1 (psRootName "base") result,
      PsControlBinder.mk 2 (psRootName "step") stepType,
      PsControlBinder.mk 3 (psRootName "count") natType];
  let motive := psControlClose true
    [PsControlBinder.mk 10 (psRootName "_major") natType] result;
  let deferred := psControlClose true
    [PsControlBinder.mk 6 (psRootName "_unit") (PsExpr.constE psUnitName [])]
    (PsExpr.fvar 5);
  let minor := psControlClose true
    [PsControlBinder.mk 4 (psRootName "index") natType,
      PsControlBinder.mk 5 (psRootName "rest") result]
    (psControlApply (PsExpr.fvar 2) [PsExpr.fvar 4, deferred]);
  let value := psControlApply (PsExpr.constE psNatRecName [PsLevel.succ PsLevel.zero])
    [motive, PsExpr.fvar 1, minor, PsExpr.fvar 3];
  PsDeclaration.definitionDecl psControlLazyNatFoldName []
    (psControlClose false binders result) (psControlClose true binders value)

-- Reversal returns its accumulator function before consuming the tail.
-- The array view is linear data, never a materialized chain of user actions.
def psControlListReverseDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0;
  let listType := psSelfHostListOf alpha;
  let resultType := psControlClose false
    [PsControlBinder.mk 9 (psRootName "accumulator") listType] listType;
  let binders :=
    [PsControlBinder.mk 0 (psRootName "Element") psPreludeTypeType,
      PsControlBinder.mk 1 (psRootName "values") listType];
  let motive := psControlClose true
    [PsControlBinder.mk 2 (psRootName "_major") listType] resultType;
  let base := psControlClose true
    [PsControlBinder.mk 2 (psRootName "accumulator") listType] (PsExpr.fvar 2);
  let next := psSelfHostListConsOf alpha (PsExpr.fvar 3) (PsExpr.fvar 6);
  let minor := psControlClose true
    [PsControlBinder.mk 3 (psRootName "element") alpha,
      PsControlBinder.mk 4 (psRootName "tail") listType,
      PsControlBinder.mk 5 (psRootName "rest") resultType,
      PsControlBinder.mk 6 (psRootName "accumulator") listType]
    (PsExpr.app (PsExpr.fvar 5) next);
  let value := psControlApply
    (PsExpr.constE psSelfHostListRecName [PsLevel.succ PsLevel.zero])
    [alpha, motive, base, minor, PsExpr.fvar 1];
  PsDeclaration.definitionDecl psControlListReverseName []
    (psControlClose false binders resultType) (psControlClose true binders value)

def psControlArrayToListDeclaration : PsDeclaration :=
  let alpha := PsExpr.fvar 0;
  let listType := psSelfHostListOf alpha;
  let arrayType := PsExpr.app (PsExpr.constE psArrayName []) alpha;
  let binders :=
    [PsControlBinder.mk 0 (psRootName "Element") psPreludeTypeType,
      PsControlBinder.mk 1 (psRootName "values") arrayType];
  let step := psControlClose true
    [PsControlBinder.mk 2 (psRootName "accumulator") listType,
      PsControlBinder.mk 3 (psRootName "element") alpha]
    (psSelfHostListConsOf alpha (PsExpr.fvar 3) (PsExpr.fvar 2));
  let empty := psSelfHostListNilOf alpha;
  let size := psControlApply (PsExpr.constE psArraySizeName []) [alpha, PsExpr.fvar 1];
  let reversed := psControlApply (PsExpr.constE psArrayFoldlName [])
    [alpha, listType, step, empty, PsExpr.fvar 1, PsExpr.lit (PsLiteral.natural 0), size];
  let value := psControlApply (PsExpr.constE psControlListReverseName []) [alpha, reversed, empty];
  PsDeclaration.definitionDecl psControlArrayToListName []
    (psControlClose false binders listType) (psControlClose true binders value)

def psControlLoopDeclarations : List PsDeclaration :=
  [psControlListFoldDeclaration, psControlNatFoldDeclaration,
    psControlLazyListFoldDeclaration, psControlLazyNatFoldDeclaration,
    psControlListReverseDeclaration, psControlArrayToListDeclaration]

def psControlAddLoopDeclarations (declarations : List PsDeclaration) :
    PsEnvironment -> PsEnvironment :=
  match declarations with
  | List.nil => fun (environment : PsEnvironment) => environment
  | List.cons declaration rest =>
      let smaller := psControlAddLoopDeclarations rest;
      fun (environment : PsEnvironment) => smaller (psPreludeAdd environment declaration)

def psControlPreludeEnvironment (environment : PsEnvironment) : PsEnvironment :=
  psControlAddLoopDeclarations psControlLoopDeclarations environment
