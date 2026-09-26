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

  -- Lean 4.34 infer-only application inference is recursive: the application
  -- and the function head are both inferred through the same checker state.
  let inferApp : Expr := .app (.const F []) (.const NatN [])
  match session.inferStateful inferApp with
  | .error err =>
      throw <| IO.userError ("stateful infer-only application failed: " ++ err)
  | .ok (actual, next) =>
      expectSession "stateful infer-only application result" (Expr.eq actual natT)
      expectSession "stateful infer-only caches outer application"
        ((CheckerExprMap.get? next.state.inferOnly inferApp).isSome)
      expectSession "stateful infer-only recursively caches function head"
        ((CheckerExprMap.get? next.state.inferOnly (.const F [])).isSome)

  -- Metadata is semantically transparent to inference. It must forward through
  -- the same stateful infer path rather than escaping to the pure checker.
  let metadataBody : Expr := .app (.const F []) (.const NatN [])
  let metadataInput : Expr := .mdata 7 metadataBody
  match session.inferStateful metadataInput with
  | .error err =>
      throw <| IO.userError ("stateful metadata inference failed: " ++ err)
  | .ok (actual, next) =>
      expectSession "stateful metadata result" (Expr.eq actual natT)
      expectSession "stateful metadata caches wrapper"
        ((CheckerExprMap.get? next.state.inferOnly metadataInput).isSome)
      expectSession "stateful metadata recursively caches body"
        ((CheckerExprMap.get? next.state.inferOnly metadataBody).isSome)

  -- Binder spines must recurse through the same state as well. These tests use
  -- a fresh session each time so the first generated FVar is deterministic.
  let xName : Name := .str .anonymous "binderX"
  let openedX : Expr := .fvar (.num xName 0)

  let lambdaInput : Expr :=
    .lam xName (.sort .zero) (.bvar 0) .default
  let lambdaExpected : Expr :=
    .forallE xName (.sort .zero) (.sort .zero) .default
  match session.inferStateful lambdaInput with
  | .error err =>
      throw <| IO.userError ("stateful lambda inference failed: " ++ err)
  | .ok (actual, next) =>
      expectSession "stateful lambda result" (Expr.eq actual lambdaExpected)
      expectSession "stateful lambda caches opened body"
        ((CheckerExprMap.get? next.state.inferOnly openedX).isSome)
      expectSession "stateful lambda advances fresh-name state" (next.state.nextFresh == 1)

  let forallInput : Expr :=
    .forallE xName (.sort .zero) (.sort .zero) .default
  let forallExpected : Expr := .sort (.succ .zero)
  match session.inferStateful forallInput with
  | .error err =>
      throw <| IO.userError ("stateful forall inference failed: " ++ err)
  | .ok (actual, next) =>
      expectSession "stateful forall result" (Expr.eq actual forallExpected)
      expectSession "stateful forall caches binder domain"
        ((CheckerExprMap.get? next.state.inferOnly (.sort .zero)).isSome)
      expectSession "stateful forall advances fresh-name state" (next.state.nextFresh == 1)

  let letInput : Expr :=
    .letE xName (.sort (.succ .zero)) (.sort .zero) (.bvar 0) false
  let letExpected : Expr := .sort (.succ .zero)
  match session.inferStateful letInput with
  | .error err =>
      throw <| IO.userError ("stateful let inference failed: " ++ err)
  | .ok (actual, next) =>
      expectSession "stateful let result" (Expr.eq actual letExpected)
      expectSession "stateful let caches opened body"
        ((CheckerExprMap.get? next.state.inferOnly openedX).isSome)
      expectSession "stateful let advances fresh-name state" (next.state.nextFresh == 1)

  -- Projection inference must recursively infer the projected structure through
  -- the same CheckerState. A pure inferProj fallback caches only the outer
  -- projection and therefore misses this inner structure application.
  let BoxN : Name := .str .anonymous "SessionBox"
  let BoxMkN : Name := .str BoxN "mk"
  let fieldN : Name := .str .anonymous "field"
  let boxT : Expr := .const BoxN []
  let boxCtorType : Expr :=
    .forallE fieldN (.sort .zero) boxT .default
  let projEnv0 :=
    Environment.empty.addUnchecked (.inductInfo {
      base := { name := BoxN, levelParams := [], type := .sort (.succ .zero) }
      numParams := 0
      numIndices := 0
      all := [BoxN]
      ctors := [BoxMkN]
      numNested := 0
      isRec := false
      isReflexive := false
      isUnsafe := false
    })
  let projEnv :=
    projEnv0.addUnchecked (.ctorInfo {
      base := { name := BoxMkN, levelParams := [], type := boxCtorType }
      induct := BoxN
      cidx := 0
      numParams := 0
      numFields := 1
      isUnsafe := false
    })
  let projSession := Kernel.mkCheckerSession projEnv [] .safe
  let structTerm : Expr := .app (.const BoxMkN []) (.sort .zero)
  let projection : Expr := .proj BoxN 0 structTerm
  match projSession.inferStateful projection with
  | .error err =>
      throw <| IO.userError ("stateful projection inference failed: " ++ err)
  | .ok (actual, next) =>
      expectSession "stateful projection result" (Expr.eq actual (.sort .zero))
      expectSession "stateful projection caches outer projection"
        ((CheckerExprMap.get? next.state.inferOnly projection).isSome)
      expectSession "stateful projection recursively caches structure"
        ((CheckerExprMap.get? next.state.inferOnly structTerm).isSome)

  IO.println "PSC1 declaration checker-session smoke: PASS"
