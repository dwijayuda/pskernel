import PSC1Kernel.CheckerSession

open PSC1Kernel

def expectInferenceMethods (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("stateful inference methods smoke failed: " ++ label)

def main : IO Unit := do
  let iName : Name := .str .anonymous "InferRecI"
  let ctorName : Name := .str iName "mk"
  let recName : Name := .str iName "rec"
  let majorName : Name := .str .anonymous "h"
  let fName : Name := .str .anonymous "f"
  let xName : Name := .str .anonymous "x"
  let iType : Expr := .sort (.succ .zero)
  let iExpr : Expr := .const iName []
  let reducedFnType : Expr :=
    .forallE xName (.sort .zero) (.sort .zero) .default

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
  let env :=
    env1.addUnchecked (.recInfo {
      base := {
        name := recName
        levelParams := []
        type := .forallE majorName iExpr reducedFnType .default
      }
      all := [iName]
      numParams := 0
      numIndices := 0
      numMotives := 0
      numMinors := 0
      rules := [{ ctor := ctorName, nFields := 0, rhs := reducedFnType }]
      k := true
      isUnsafe := false
    })

  let major : Expr := .fvar majorName
  let hiddenFnType : Expr := .app (.const recName []) major
  let lctx :=
    ((LocalContext.empty.addLocal majorName majorName iExpr .default).addLocal
      fName fName hiddenFnType .default).addLocal
      xName xName (.sort .zero) .default
  let ctx := { CheckerContext.empty env with lctx := lctx }
  let input : Expr := .app (.fvar fName) (.fvar xName)
  let session : CheckerSession := { context := ctx, state := .empty }

  match session.checkStateful input with
  | .error err =>
      throw <| IO.userError ("stateful inference with recursor-hidden function type failed: " ++ err)
  | .ok (actual, next) =>
      expectInferenceMethods "application type" (Expr.eq actual (.sort .zero))
      expectInferenceMethods "hidden function type WHNF cached"
        (match CheckerExprMap.get? next.state.whnf hiddenFnType with
         | some cached => Expr.eq cached reducedFnType
         | none => false)
      expectInferenceMethods "recursor major inference stays in declaration state"
        ((CheckerExprMap.get? next.state.inferOnly major).isSome)

  IO.println "PSC1 stateful inference reduction methods smoke: PASS"
