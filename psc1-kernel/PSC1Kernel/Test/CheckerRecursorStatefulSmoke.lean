import PSC1Kernel.CheckerStateful

open PSC1Kernel

def expectRecursorStateful (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("stateful recursor smoke failed: " ++ label)

def main : IO Unit := do
  let iName : Name := .str .anonymous "RecI"
  let ctorName : Name := .str iName "mk"
  let recName : Name := .str iName "rec"
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
      rules := [{ ctor := ctorName, nFields := 0, rhs := .sort .zero }]
      k := true
      isUnsafe := false
    })

  let lctx := LocalContext.empty.addLocal majorName majorName iExpr .default
  let ctx := { CheckerContext.empty env with lctx := lctx }
  let major : Expr := .fvar majorName
  let input : Expr := .app (.const recName []) major

  match whnfStateful ctx CheckerState.empty input with
  | .error err =>
      throw <| IO.userError ("stateful recursor reduction failed: " ++ err)
  | .ok (actual, state) =>
      expectRecursorStateful "K recursor reduces" (Expr.eq actual (.sort .zero))
      expectRecursorStateful "recursor reduction threads major inference into checker state"
        ((CheckerExprMap.get? state.inferOnly major).isSome)
      expectRecursorStateful "public WHNF result remains cached"
        (match CheckerExprMap.get? state.whnf input with
         | some cached => Expr.eq cached (.sort .zero)
         | none => false)

  IO.println "PSC1 stateful recursor checker smoke: PASS"
