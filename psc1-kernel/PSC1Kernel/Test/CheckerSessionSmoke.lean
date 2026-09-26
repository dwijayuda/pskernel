import PSC1Kernel

open PSC1Kernel

def expectSession (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("checker-session smoke failed: " ++ label)

def main : IO Unit := do
  let NatN : Name := .str .anonymous "SessionNat"
  let BoolN : Name := .str .anonymous "SessionBool"
  let F : Name := .str .anonymous "SessionF"
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

  -- A checker session is declaration-scoped: all operations below must use
  -- one shared checker boundary while preserving infer-only/full-check split.
  let session := Kernel.mkCheckerSession env [] .safe
  let malformed : Expr := .app (.const F []) (.const BoolN [])

  let inferred ←
    match session.infer malformed with
    | .ok value => pure value
    | .error err =>
        throw <| IO.userError ("session infer unexpectedly rejected malformed argument: " ++ err)
  expectSession "infer-only codomain" (Expr.eq inferred natT)

  let fullCheckRejects :=
    match session.check malformed with
    | .ok _ => false
    | .error _ => true
  expectSession "full check remains distinct from infer-only" fullCheckRejects

  let reflexive ←
    match session.isDefEq natT natT with
    | .ok value => pure value
    | .error err => throw <| IO.userError err
  expectSession "session defeq" reflexive

  -- Stateful session calls are explicit and pure: each call returns the next
  -- declaration-scoped session. Reusing that returned session must reuse the
  -- checker memo state without process-global mutation.
  let cacheInput : Expr := .sort .zero
  let cacheExpected : Expr := .sort (.succ .zero)
  match session.checkStateful cacheInput with
  | .error err =>
      throw <| IO.userError ("stateful session check failed: " ++ err)
  | .ok (actual1, session1) =>
      expectSession "stateful session checked result" (Expr.eq actual1 cacheExpected)
      expectSession "stateful session owns checked cache"
        (match CheckerExprMap.get? session1.state.checkedInfer cacheInput with
         | some cached => Expr.eq cached cacheExpected
         | none => false)
      let checkedSize := session1.state.checkedInfer.size
      match session1.checkStateful cacheInput with
      | .error err =>
          throw <| IO.userError ("second stateful session check failed: " ++ err)
      | .ok (actual2, session2) =>
          expectSession "stateful session second result" (Expr.eq actual2 cacheExpected)
          expectSession "stateful session reuses checked cache"
            (session2.state.checkedInfer.size == checkedSize)
          match session2.inferStateful cacheInput with
          | .error err =>
              throw <| IO.userError ("stateful session infer failed: " ++ err)
          | .ok (actual3, session3) =>
              expectSession "stateful session infer result" (Expr.eq actual3 cacheExpected)
              expectSession "stateful session keeps infer-only cache separate"
                ((CheckerExprMap.get? session3.state.inferOnly cacheInput).isSome &&
                 session3.state.checkedInfer.size == checkedSize)

  IO.println "PSC1 declaration checker-session smoke: PASS"
