import Ps.KernelCore.Research.ExprV2

private def requireV2 (label : String) (ok : Bool) : IO Unit := do
  unless ok do
    throw (IO.userError ("PSC1_EXPR_V2_FAILED: " ++ label))
  IO.println ("PSC1_EXPR_V2_PASS " ++ label)

private def expectV2 {α : Type} (x : Except String α) : IO α := do
  match x with
  | .ok v => return v
  | .error error => throw (IO.userError ("PSC1_EXPR_V2_UNEXPECTED_ERROR: " ++ error))

private def buildSpine (depth : Nat) :
    Except String (PsKernelExprV2Arena × Nat) := do
  let (a, first) := psKernelExprV2MkBVar psKernelExprV2Empty 0
  let (a, arg) := psKernelExprV2MkBVar a 1
  let mut arena := a
  let mut root := first
  for _ in [:depth] do
    let (next, child) ← psKernelExprV2MkApp arena root arg
    arena := next
    root := child
  return (arena, root)

private def verifyV2Arena
    (label : String) (arena : PsKernelExprV2Arena) (root : Nat)
    (reference : PsKernelExpr) : IO Unit := do
  let _ ← expectV2 (psKernelExprV2Validate arena)
  let decoded ← expectV2 (psKernelExprV2Decode arena root)
  requireV2 (label ++ "-roundtrip") (psKernelExprEq decoded reference)
  let head ← expectV2 (psKernelExprV2Lookup arena root)
  requireV2 (label ++ "-hash") (head.hash == psKernelExprHash decoded)
  requireV2 (label ++ "-loose") (head.looseRange ==
    psKernelExprV2LegacyLooseRange decoded)
  requireV2 (label ++ "-depth") (head.depth ==
    psKernelExprV2LegacyDepth decoded)
  requireV2 (label ++ "-fvar") (head.hasFVar ==
    psKernelExprHasFVar decoded)
  requireV2 (label ++ "-self-equality")
    (psKernelExprV2Eq arena root root)

private def testAllConstructors : IO Unit := do
  let n := PsKernelName.str PsKernelName.anonymous "v2n"
  let n2 := PsKernelName.str PsKernelName.anonymous "v2Other"
  let (a, bv0) := psKernelExprV2MkBVar psKernelExprV2Empty 0
  let (a, bv2) := psKernelExprV2MkBVar a 2
  let (a, fv) := psKernelExprV2MkFVar a n
  let (a, mv) := psKernelExprV2MkMVar a n
  let (a, sort0) := psKernelExprV2MkSort a PsKernelLevel.zero
  let (a, cst) := psKernelExprV2MkConst a n [PsKernelLevel.zero]
  let (a, litN) := psKernelExprV2MkLit a (.nat 42)
  let (a, litS) := psKernelExprV2MkLit a (.str "expression-v2")
  let (a, app) ← expectV2 (psKernelExprV2MkApp a bv0 fv)
  let (a, lam) ← expectV2
    (psKernelExprV2MkLam a n sort0 bv2 PsKernelBinderInfo.default)
  let (a, forallE) ← expectV2
    (psKernelExprV2MkForall a n sort0 bv0 PsKernelBinderInfo.implicit)
  let (a, letE) ← expectV2
    (psKernelExprV2MkLet a n sort0 fv bv2 false)
  let (a, mdata) ← expectV2 (psKernelExprV2MkMData a 123 app)
  let (a, proj) ← expectV2 (psKernelExprV2MkProj a n 1 mdata)
  let (a, lamOther) ← expectV2
    (psKernelExprV2MkLam a n2 sort0 bv2 PsKernelBinderInfo.implicit)
  let cases : List (String × Nat × PsKernelExpr) := [
    ("bvar", bv0, .bvar 0),
    ("fvar", fv, .fvar n),
    ("mvar", mv, .mvar n),
    ("sort", sort0, .sort PsKernelLevel.zero),
    ("const", cst, .const n [PsKernelLevel.zero]),
    ("nat-lit", litN, .lit (.nat 42)),
    ("string-lit", litS, .lit (.str "expression-v2")),
    ("app", app, .app (.bvar 0) (.fvar n)),
    ("lambda", lam, .lam n (.sort .zero) (.bvar 2) .default),
    ("forall", forallE, .forallE n (.sort .zero) (.bvar 0) .implicit),
    ("let", letE, .letE n (.sort .zero) (.fvar n) (.bvar 2) false),
    ("metadata", mdata, .mdata 123 (.app (.bvar 0) (.fvar n))),
    ("projection", proj, .proj n 1 (.mdata 123 (.app (.bvar 0) (.fvar n))))
  ]
  let _ ← expectV2 (psKernelExprV2Validate a)
  for (label, id, original) in cases do
    let decoded ← expectV2 (psKernelExprV2Decode a id)
    requireV2 ("constructor-" ++ label) (psKernelExprEq decoded original)
    let (imported, newId) ← expectV2 (psKernelExprV2Import psKernelExprV2Empty original)
    verifyV2Arena ("import-" ++ label) imported newId original
  requireV2 "ignored-binder-name-and-info"
    (psKernelExprV2Eq a lam lamOther)
  requireV2 "different-constructor-not-equal"
    (!psKernelExprV2Eq a lam forallE)
  let (a, copyApp) ← expectV2 (psKernelExprV2MkApp a bv0 fv)
  requireV2 "structural-equality-distinct-ids"
    (psKernelExprV2Eq a app copyApp)
  let (a, both) ← expectV2 (psKernelExprV2MkApp a app app)
  match (← expectV2 (psKernelExprV2Lookup a both)).node with
  | .app x y =>
      requireV2 "explicit-subtree-sharing" (x == app && y == app)
  | _ => throw (IO.userError "PSC1_EXPR_V2_SHARED_NODE_WRONG_SHAPE")
  requireV2 "valid-duplicate-sharing-equality" (psKernelExprV2Eq a both both)

private def testHashCollision : IO Unit := do
  let (a, small) := psKernelExprV2MkBVar psKernelExprV2Empty 0
  let (a, large) := psKernelExprV2MkBVar a 65521
  let one ← expectV2 (psKernelExprV2Lookup a small)
  let two ← expectV2 (psKernelExprV2Lookup a large)
  requireV2 "legacy-hash-collision-present" (one.hash == two.hash)
  requireV2 "collision-not-deemed-equal"
    (!psKernelExprV2Eq a small large)

private def testInvalidInput : IO Unit := do
  let invalid := psKernelExprV2MkApp psKernelExprV2Empty 0 1
  requireV2 "invalid-child-rejected"
    (match invalid with | .error _ => true | .ok _ => false)
  let (a, root) := psKernelExprV2MkFVar psKernelExprV2Empty
    (PsKernelName.str PsKernelName.anonymous "fvarHere")
  let good ← expectV2 (psKernelExprV2Lookup a root)
  let altered : PsKernelExprV2Arena :=
    { nodes := #[{ good with hasFVar := false }] }
  requireV2 "forged-closedness-rejected"
    (match psKernelExprV2Validate altered with
      | .error _ => true
      | .ok _ => false)
  let forward : PsKernelExprV2Arena :=
    { nodes := #[{ good with node := .app 1 2 }] }
  requireV2 "forward-references-rejected"
    (match psKernelExprV2Validate forward with
      | .error _ => true
      | .ok _ => false)
  requireV2 "invalid-root-rejected"
    (match psKernelExprV2Decode a 99 with
      | .error _ => true
      | .ok _ => false)

private def testDeepSpines : IO Unit := do
  for depth in [1, 8, 32, 128] do
    let (arena, root) ← expectV2 (buildSpine depth)
    let expectedNodes := depth + 2
    requireV2 s!"dag-node-count-{depth}" (arena.nodes.size == expectedNodes)
    let decoded ← expectV2 (psKernelExprV2Decode arena root)
    let last ← expectV2 (psKernelExprV2Lookup arena root)
    requireV2 s!"dag-hash-{depth}" (last.hash == psKernelExprHash decoded)
    requireV2 s!"dag-flags-{depth}"
      (last.hasFVar == psKernelExprHasFVar decoded &&
       last.looseRange == psKernelExprV2LegacyLooseRange decoded)
    requireV2 s!"dag-identity-{depth}" (psKernelExprV2Eq arena root root)
  let (arena, root) ← expectV2 (buildSpine 32)
  verifyV2Arena "spine-32-full-validation" arena root
    (← expectV2 (psKernelExprV2Decode arena root))

def main : IO Unit := do
  testAllConstructors
  testHashCollision
  testInvalidInput
  testDeepSpines
  IO.println "PSC1_EXPR_V2_REGRESSION: PASS"
