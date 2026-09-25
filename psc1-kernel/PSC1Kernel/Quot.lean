import PSC1Kernel.TypeChecker

namespace PSC1Kernel

namespace Kernel

structure OpenBinder where
  internalName : Name
  userName : Name
  type : Expr
  binderInfo : BinderInfo

def mkArrow (domain codomain : Expr) : Expr :=
  .forallE .anonymous domain codomain .default

def closeOpenBinders : List OpenBinder → Expr → Expr
  | [], body => body
  | binder :: rest, body =>
      let inner := closeOpenBinders rest body
      .forallE
        binder.userName
        binder.type
        (inner.abstractFVars [binder.internalName])
        binder.binderInfo

def quotInternalName (value : String) : Name :=
  .str (.str .anonymous "_psc1Quot") value

def kernelEqName : Name :=
  .str .anonymous "Eq"

def expectedEqType (uName : Name) : Expr :=
  let u : Level := .param uName
  let alphaName := quotInternalName "eq.alpha"
  let alpha : Expr := .fvar alphaName
  let alphaBinder : OpenBinder := {
    internalName := alphaName
    userName := .str .anonymous "α"
    type := .sort u
    binderInfo := .implicit
  }
  closeOpenBinders [alphaBinder]
    (mkArrow alpha (mkArrow alpha (.sort .zero)))

def expectedEqReflType (uName : Name) : Expr :=
  let u : Level := .param uName
  let alphaName := quotInternalName "eqRefl.alpha"
  let aName := quotInternalName "eqRefl.a"
  let alpha : Expr := .fvar alphaName
  let a : Expr := .fvar aName
  let alphaBinder : OpenBinder := {
    internalName := alphaName
    userName := .str .anonymous "α"
    type := .sort u
    binderInfo := .implicit
  }
  let aBinder : OpenBinder := {
    internalName := aName
    userName := .str .anonymous "a"
    type := alpha
    binderInfo := .default
  }
  let result :=
    applyArgs (.const kernelEqName [u]) [alpha, a, a]
  closeOpenBinders [alphaBinder, aBinder] result

def checkEqForQuot (env : Environment) : Except String Unit := do
  let some (.inductInfo eqInfo) := env.find? kernelEqName
    | throw "failed to initialize quot module, environment does not have Eq type"
  let [uName] := eqInfo.base.levelParams
    | throw "failed to initialize quot module, unexpected number of universe params at Eq type"
  let [reflName] := eqInfo.ctors
    | throw "failed to initialize quot module, unexpected number of constructors for Eq type"
  unless Expr.eq eqInfo.base.type (expectedEqType uName) do
    throw "failed to initialize quot module, Eq has an unexpected type"

  let some reflInfo := env.find? reflName
    | throw "failed to initialize quot module, missing Eq constructor"
  let [reflUName] := reflInfo.levelParams
    | throw "failed to initialize quot module, unexpected universe params at Eq constructor"
  unless Expr.eq reflInfo.type (expectedEqReflType reflUName) do
    throw "failed to initialize quot module, unexpected type for Eq constructor"

def makeQuotType (uName : Name) : Expr :=
  let u : Level := .param uName
  let alphaName := quotInternalName "quot.alpha"
  let rName := quotInternalName "quot.r"
  let alpha : Expr := .fvar alphaName
  let r : Expr := .fvar rName
  let alphaBinder : OpenBinder := {
    internalName := alphaName
    userName := .str .anonymous "α"
    type := .sort u
    binderInfo := .implicit
  }
  let rBinder : OpenBinder := {
    internalName := rName
    userName := .str .anonymous "r"
    type := mkArrow alpha (mkArrow alpha (.sort .zero))
    binderInfo := .default
  }
  closeOpenBinders [alphaBinder, rBinder] (.sort u)

def makeQuotMkType (uName : Name) : Expr :=
  let u : Level := .param uName
  let alphaName := quotInternalName "mk.alpha"
  let rName := quotInternalName "mk.r"
  let aName := quotInternalName "mk.a"
  let alpha : Expr := .fvar alphaName
  let r : Expr := .fvar rName
  let a : Expr := .fvar aName
  let alphaBinder : OpenBinder := {
    internalName := alphaName
    userName := .str .anonymous "α"
    type := .sort u
    binderInfo := .implicit
  }
  let rBinder : OpenBinder := {
    internalName := rName
    userName := .str .anonymous "r"
    type := mkArrow alpha (mkArrow alpha (.sort .zero))
    binderInfo := .default
  }
  let aBinder : OpenBinder := {
    internalName := aName
    userName := .str .anonymous "a"
    type := alpha
    binderInfo := .default
  }
  let quotR :=
    applyArgs (.const kernelQuotName [u]) [alpha, r]
  closeOpenBinders [alphaBinder, rBinder, aBinder] quotR

def makeQuotLiftType (uName vName : Name) : Expr :=
  let u : Level := .param uName
  let v : Level := .param vName
  let alphaName := quotInternalName "lift.alpha"
  let rName := quotInternalName "lift.r"
  let betaName := quotInternalName "lift.beta"
  let fName := quotInternalName "lift.f"
  let aName := quotInternalName "lift.a"
  let bName := quotInternalName "lift.b"
  let alpha : Expr := .fvar alphaName
  let r : Expr := .fvar rName
  let beta : Expr := .fvar betaName
  let f : Expr := .fvar fName
  let a : Expr := .fvar aName
  let b : Expr := .fvar bName
  let rType := mkArrow alpha (mkArrow alpha (.sort .zero))
  let quotR :=
    applyArgs (.const kernelQuotName [u]) [alpha, r]

  let alphaBinder : OpenBinder := {
    internalName := alphaName
    userName := .str .anonymous "α"
    type := .sort u
    binderInfo := .implicit
  }
  let rBinder : OpenBinder := {
    internalName := rName
    userName := .str .anonymous "r"
    type := rType
    binderInfo := .implicit
  }
  let betaBinder : OpenBinder := {
    internalName := betaName
    userName := .str .anonymous "β"
    type := .sort v
    binderInfo := .implicit
  }
  let fBinder : OpenBinder := {
    internalName := fName
    userName := .str .anonymous "f"
    type := mkArrow alpha beta
    binderInfo := .default
  }
  let aBinder : OpenBinder := {
    internalName := aName
    userName := .str .anonymous "a"
    type := alpha
    binderInfo := .default
  }
  let bBinder : OpenBinder := {
    internalName := bName
    userName := .str .anonymous "b"
    type := alpha
    binderInfo := .default
  }

  let rAB := applyArgs r [a, b]
  let fA := .app f a
  let fB := .app f b
  let eqFAB :=
    applyArgs (.const kernelEqName [v]) [beta, fA, fB]
  let sanity :=
    closeOpenBinders [aBinder, bBinder]
      (mkArrow rAB eqFAB)
  let result :=
    mkArrow sanity (mkArrow quotR beta)
  closeOpenBinders [alphaBinder, rBinder, betaBinder, fBinder] result

def makeQuotIndType (uName : Name) : Expr :=
  let u : Level := .param uName
  let alphaName := quotInternalName "ind.alpha"
  let rName := quotInternalName "ind.r"
  let betaName := quotInternalName "ind.beta"
  let aName := quotInternalName "ind.a"
  let mkProofName := quotInternalName "ind.mkProof"
  let qName := quotInternalName "ind.q"
  let alpha : Expr := .fvar alphaName
  let r : Expr := .fvar rName
  let beta : Expr := .fvar betaName
  let a : Expr := .fvar aName
  let q : Expr := .fvar qName
  let rType := mkArrow alpha (mkArrow alpha (.sort .zero))
  let quotR :=
    applyArgs (.const kernelQuotName [u]) [alpha, r]

  let alphaBinder : OpenBinder := {
    internalName := alphaName
    userName := .str .anonymous "α"
    type := .sort u
    binderInfo := .implicit
  }
  let rBinder : OpenBinder := {
    internalName := rName
    userName := .str .anonymous "r"
    type := rType
    binderInfo := .implicit
  }
  let betaBinder : OpenBinder := {
    internalName := betaName
    userName := .str .anonymous "β"
    type := mkArrow quotR (.sort .zero)
    binderInfo := .implicit
  }
  let aBinder : OpenBinder := {
    internalName := aName
    userName := .str .anonymous "a"
    type := alpha
    binderInfo := .default
  }
  let quotMkA :=
    applyArgs (.const kernelQuotMkName [u]) [alpha, r, a]
  let allQuot :=
    closeOpenBinders [aBinder] (.app beta quotMkA)
  let mkProofBinder : OpenBinder := {
    internalName := mkProofName
    userName := .str .anonymous "mk"
    type := allQuot
    binderInfo := .default
  }
  let qBinder : OpenBinder := {
    internalName := qName
    userName := .str .anonymous "q"
    type := quotR
    binderInfo := .default
  }
  let result :=
    closeOpenBinders [mkProofBinder, qBinder] (.app beta q)
  closeOpenBinders [alphaBinder, rBinder, betaBinder] result

def addQuot (env : Environment) : Except String Environment := do
  if env.quotInitialized then
    return env

  checkEqForQuot env

  let reserved :=
    [kernelQuotName, kernelQuotMkName, kernelQuotLiftName, kernelQuotIndName]
  let rec checkNames : List Name → Except String Unit
    | [] => pure ()
    | name :: rest => do
        if env.contains name then
          throw "failed to initialize quot module, quotient name is already declared"
        checkNames rest
  checkNames reserved

  let uName : Name := .str .anonymous "u"
  let vName : Name := .str .anonymous "v"
  let env1 := env.addUnchecked (.quotInfo {
    base := {
      name := kernelQuotName
      levelParams := [uName]
      type := makeQuotType uName
    }
    kind := .typeQ
  })
  let env2 := env1.addUnchecked (.quotInfo {
    base := {
      name := kernelQuotMkName
      levelParams := [uName]
      type := makeQuotMkType uName
    }
    kind := .ctorQ
  })
  let env3 := env2.addUnchecked (.quotInfo {
    base := {
      name := kernelQuotLiftName
      levelParams := [uName, vName]
      type := makeQuotLiftType uName vName
    }
    kind := .liftQ
  })
  let env4 := env3.addUnchecked (.quotInfo {
    base := {
      name := kernelQuotIndName
      levelParams := [uName]
      type := makeQuotIndType uName
    }
    kind := .indQ
  })
  return env4.markQuotInitialized

end Kernel

end PSC1Kernel
