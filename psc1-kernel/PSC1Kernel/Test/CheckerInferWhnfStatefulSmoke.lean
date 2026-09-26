import PSC1Kernel.CheckerDefEqStatefulReduced
import PSC1Kernel.CheckerInferenceStatefulReduced

open PSC1Kernel

def expectInferWhnfStateful (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("stateful infer-WHNF smoke failed: " ++ label)

def main : IO Unit := do
  let iName : Name := .str .anonymous "InferWhnfI"
  let ctorName : Name := .str iName "mk"
  let recName : Name := .str iName "rec"
  let majorName : Name := .str .anonymous "h"
  let fName : Name := .str .anonymous "f"
  let xName : Name := .str .anonymous "x"
  let iType : Expr := .sort (.succ .zero)
  let iExpr : Expr := .const iName []
  let exposedFnType : Expr :=
    .forallE xName (.sort (.succ .zero)) (.sort (.succ .zero)) .default

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
        type := .forallE majorName iExpr (.sort (.succ .zero)) .default
      }
      all := [iName]
      numParams := 0
      numIndices := 0
      numMotives := 0
      numMinors := 0
      rules := [{ ctor := ctorName, nFields := 0, rhs := exposedFnType }]
      k := true
      isUnsafe := false
    })

  let major : Expr := .fvar majorName
  let hiddenFnType : Expr := .app (.const recName []) major
  let lctx :=
    (LocalContext.empty.addLocal majorName majorName iExpr .default).addLocal
      fName fName hiddenFnType .default
  let ctx := { CheckerContext.empty env with lctx := lctx }
  let input : Expr := .app (.fvar fName) (.sort .zero)

  match StatefulInferenceReduced.check StatefulDefEqReduced.isDefEq
      ctx CheckerState.empty input with
  | .error err => throw <| IO.userError ("stateful checked application failed: " ++ err)
  | .ok (actual, state) =>
      expectInferWhnfStateful "checked application result"
        (Expr.eq actual (.sort (.succ .zero)))
      expectInferWhnfStateful "checked application caches outer term"
        ((CheckerExprMap.get? state.checkedInfer input).isSome)
      expectInferWhnfStateful "inference WHNF threads K-major inference into checker state"
        ((CheckerExprMap.get? state.inferOnly major).isSome)
      expectInferWhnfStateful "hidden function type is normalized in shared WHNF cache"
        (match CheckerExprMap.get? state.whnf hiddenFnType with
         | some cached => Expr.eq cached exposedFnType
         | none => false)

  IO.println "PSC1 stateful infer-WHNF checker smoke: PASS"
