import Ps.Environment.SelfHostPrelude
import Ps.Core.Abstract

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

def psControlApply (fn : PsExpr) (arguments : List PsExpr) : PsExpr :=
  match arguments with
  | [] => fn
  | argument :: rest => psControlApply (PsExpr.app fn argument) rest

def psControlClose
    (lambda : Bool) (binders : List PsControlBinder) (body : PsExpr) : PsExpr :=
  match binders with
  | [] => body
  | binder :: rest =>
      let inner := psControlClose lambda rest body
      let closed := psExprAbstractFVar binder.id inner
      if lambda then
        PsExpr.lam binder.name binder.type closed PsBinderInfo.explicit
      else
        PsExpr.forallE binder.name binder.type closed PsBinderInfo.explicit

def psControlListFoldDeclaration : PsDeclaration :=
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let alpha := PsExpr.fvar 0
  let result := PsExpr.fvar 1
  let base := PsExpr.fvar 2
  let step := PsExpr.fvar 3
  let major := PsExpr.fvar 4
  let listType := psSelfHostListOf alpha
  let stepType := psControlClose false
    [PsControlBinder.mk 8 (psRootName "element") alpha,
      PsControlBinder.mk 9 (psRootName "rest") result] result
  let binders :=
    [PsControlBinder.mk 0 (psRootName "Element") typeType,
      PsControlBinder.mk 1 (psRootName "Result") typeType,
      PsControlBinder.mk 2 (psRootName "base") result,
      PsControlBinder.mk 3 (psRootName "step") stepType,
      PsControlBinder.mk 4 (psRootName "values") listType]
  let motive := psControlClose true
    [PsControlBinder.mk 10 (psRootName "_major") listType] result
  let minor := psControlClose true
    [PsControlBinder.mk 5 (psRootName "element") alpha,
      PsControlBinder.mk 6 (psRootName "tail") listType,
      PsControlBinder.mk 7 (psRootName "rest") result]
    (psControlApply step [PsExpr.fvar 5, PsExpr.fvar 7])
  let value := psControlApply
    (PsExpr.constE psSelfHostListRecName [PsLevel.succ PsLevel.zero])
    [alpha, motive, base, minor, major]
  PsDeclaration.definitionDecl psControlListFoldName []
    (psControlClose false binders result) (psControlClose true binders value)

def psControlNatFoldDeclaration : PsDeclaration :=
  let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let natType := PsExpr.constE psNatName []
  let result := PsExpr.fvar 0
  let base := PsExpr.fvar 1
  let step := PsExpr.fvar 2
  let major := PsExpr.fvar 3
  let stepType := psControlClose false
    [PsControlBinder.mk 8 (psRootName "index") natType,
      PsControlBinder.mk 9 (psRootName "rest") result] result
  let binders :=
    [PsControlBinder.mk 0 (psRootName "Result") typeType,
      PsControlBinder.mk 1 (psRootName "base") result,
      PsControlBinder.mk 2 (psRootName "step") stepType,
      PsControlBinder.mk 3 (psRootName "count") natType]
  let motive := psControlClose true
    [PsControlBinder.mk 10 (psRootName "_major") natType] result
  let minor := psControlClose true
    [PsControlBinder.mk 4 (psRootName "index") natType,
      PsControlBinder.mk 5 (psRootName "rest") result]
    (psControlApply step [PsExpr.fvar 4, PsExpr.fvar 5])
  let value := psControlApply
    (PsExpr.constE psNatRecName [PsLevel.succ PsLevel.zero])
    [motive, base, minor, major]
  PsDeclaration.definitionDecl psControlNatFoldName []
    (psControlClose false binders result) (psControlClose true binders value)

def psControlLoopDeclarations : List PsDeclaration :=
  [psControlListFoldDeclaration, psControlNatFoldDeclaration]

def psControlPreludeEnvironment (environment : PsEnvironment) : PsEnvironment :=
  psPreludeAdd (psPreludeAdd environment psControlListFoldDeclaration)
    psControlNatFoldDeclaration
