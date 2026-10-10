import PSC1Kernel

open PSC1Kernel

def expectInferOnly (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("infer-only smoke failed: " ++ label)

def main : IO Unit := do
  let NatN : Name := .str .anonymous "InferOnlyNat"
  let BoolN : Name := .str .anonymous "InferOnlyBool"
  let F : Name := .str .anonymous "InferOnlyF"
  let type1 : Expr := .sort (.succ .zero)
  let natT : Expr := .const NatN []
  let env0 :=
    Environment.empty.addUnchecked (.axiomInfo {
      base := { name := NatN, levelParams := [], type := type1 }
      isUnsafe := false
    })
  let env1 :=
    env0.addUnchecked (.axiomInfo {
      base := { name := BoolN, levelParams := [], type := type1 }
      isUnsafe := false
    })
  let env :=
    env1.addUnchecked (.axiomInfo {
      base := {
        name := F
        levelParams := []
        type := .forallE (.str .anonymous "x") natT natT .default
      }
      isUnsafe := false
    })
  let ctx := CheckerContext.empty env
  let malformed : Expr := .app (.const F []) (.const BoolN [])

  let inferred ←
    match infer ctx malformed with
    | .ok value => pure value
    | .error err =>
        throw <| IO.userError ("infer-only unexpectedly rejected malformed argument: " ++ err)
  expectInferOnly "infer-only codomain"
    (Expr.eq inferred natT)

  let fullCheckRejects :=
    match check ctx malformed with
    | .ok _ => false
    | .error _ => true
  expectInferOnly "full check must reject malformed argument" fullCheckRejects

  IO.println "PSC1 infer-only/check split smoke: PASS"
