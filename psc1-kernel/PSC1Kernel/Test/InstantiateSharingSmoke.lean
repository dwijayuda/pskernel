import PSC1Kernel.Instantiate

open PSC1Kernel

def expectSharing (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("instantiate sharing smoke failed: " ++ label)

def main : IO Unit := do
  let x : Name := .str .anonymous "x"
  let k : Name := .str .anonymous "K"
  let untouched : Expr := .app (.const k []) (.sort .zero)

  let abstractInput : Expr := .app untouched (.fvar x)
  let abstracted := abstractInput.abstractFVars [x]
  match abstracted with
  | .app fn (.bvar 0) =>
      expectSharing "abstractFVars preserves untouched subtree identity" (ptrEq fn untouched)
  | _ =>
      throw <| IO.userError "abstractFVars produced unexpected result"

  let replacement : Expr := .const (.str .anonymous "R") []
  let instantiateInput : Expr := .app untouched (.bvar 0)
  let instantiated := instantiateInput.instantiate1 replacement
  match instantiated with
  | .app fn arg =>
      expectSharing "instantiate preserves untouched subtree identity" (ptrEq fn untouched)
      expectSharing "instantiate substitutes target" (Expr.eq arg replacement)
  | _ =>
      throw <| IO.userError "instantiate produced unexpected result"

  IO.println "PSC1 instantiate DAG-sharing smoke: PASS"
