import PSC1Kernel.CheckerDefEqStatefulReduced

open PSC1Kernel

def expectDeltaStateful (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("stateful lazy-delta smoke failed: " ++ label)

def main : IO Unit := do
  let iName : Name := .str .anonymous "DeltaI"
  let ctorName : Name := .str iName "mk"
  let recName : Name := .str iName "rec"
  let defName : Name := .str iName "wrappedRec"
  let majorName : Name := .str .anonymous "h"
  let iType : Expr := .sort (.succ .zero)
  let iExpr : Expr := .const iName []

  let env0 :=
    Environment.empty.addUnchecked (.inductInfo {
      base := { name := iName, levelParams := [], type := iType }
      numParams := 0
      numIndices := 0
      all := [iName]
      ctors := [ctorName]
      numNested := 0
      isRec := false
      isReflexive := true
      isUnsafe := false
    })
  let env1 :=
    env0.addUnchecked (.ctorInfo {
      base := { name := ctorName, levelParams := [], type := iExpr }
      induct := iName
      cidx := 0
      numParams := 0
      numFields := 0
      isUnsafe := false
    })
  let env2 :=
    env1.addUnchecked (.recInfo {
      base := {
        name := recName
        levelParams := []
        type := .forallE majorName iExpr (.sort (.succ .zero)) .default
      }
      all := [iName]
      numParams := 0
      numIndices := 0
      numMotives := 0
      numMinors := 0
      rules := [{ ctor := ctorName, nFields := 0, rhs := .sort .zero }]
      k := true
      isUnsafe := false
    })
  let wrappedType : Expr :=
    .forallE majorName iExpr (.sort (.succ .zero)) .default
  let wrappedValue : Expr :=
    .lam majorName iExpr (.app (.const recName []) (.bvar 0)) .default
  let env :=
    env2.addUnchecked (.defnInfo {
      base := { name := defName, levelParams := [], type := wrappedType }
      value := wrappedValue
      hints := .regular 1
      safety := .safe
    })

  let lctx := LocalContext.empty.addLocal majorName majorName iExpr .default
  let ctx := { CheckerContext.empty env with lctx := lctx }
  let major : Expr := .fvar majorName
  let left : Expr := .app (.const defName []) major
  let right : Expr := .sort .zero

  match StatefulDefEqReduced.isDefEq ctx CheckerState.empty left right with
  | .error err =>
      throw <| IO.userError ("stateful lazy-delta defeq failed: " ++ err)
  | .ok (equal, state) =>
      expectDeltaStateful "definition unfolds through recursor" equal
      expectDeltaStateful "delta recursor reduction retains major inference"
        ((CheckerExprMap.get? state.inferOnly major).isSome)

  IO.println "PSC1 stateful lazy-delta recursor smoke: PASS"
