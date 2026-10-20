import Ps.KernelCore.Research.ExprV2Validation
import Ps.KernelCore.Research.ExprV2Lift
import Ps.KernelCore.Research.ExprV2PortableHeadMachine
import Ps.KernelCore.Research.ExprV2PortableEquality
import Ps.KernelCore.Research.ExprV2PortableLift
import Ps.KernelCore.Research.ExprV2PortableInstantiate
import Ps.KernelCore.Research.ExprV2PortableReduction
import Ps.KernelCore.Research.ExprV2PortableHeadSequence
import Ps.KernelCore.Core.Substitution.Instantiate
import Ps.KernelCore.Core.Substitution.Lift
import Ps.KernelCore.Research.ExprV2ResearchAll

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
  let checked ← expectV2 (psKernelExprV2ValidateLinear arena)
  requireV2 (label ++ "-linear-node-count")
    (checked.nodes.size == arena.nodes.size)
  let decoded ← expectV2 (psKernelExprV2Decode checked root)
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
  requireV2 "linear-forged-closedness-rejected"
    (match psKernelExprV2ValidateLinear altered with
      | .error _ => true
      | .ok _ => false)
  let forward : PsKernelExprV2Arena :=
    { nodes := #[{ good with node := .app 1 2 }] }
  requireV2 "forward-references-rejected"
    (match psKernelExprV2Validate forward with
      | .error _ => true
      | .ok _ => false)
  requireV2 "linear-forward-references-rejected"
    (match psKernelExprV2ValidateLinear forward with
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



/-
A DAG with D levels of repeated (x x) represents 2^D terminal
occurrences while retaining only D+1 nodes. Legacy whole-tree validation
would revisit exponentially many paths; linear replay never expands them.
-/
private def testExponentialSharing : IO Unit := do
  let (initial, leaf) := psKernelExprV2MkBVar psKernelExprV2Empty 0
  let mut arena := initial
  let mut root := leaf
  let depth : Nat := 28
  for _ in [:depth] do
    let (next, node) ← expectV2 (psKernelExprV2MkApp arena root root)
    arena := next
    root := node
  requireV2 "exponential-sharing-node-count"
    (arena.nodes.size == depth + 1)
  let begin ← IO.monoMsNow
  let checked ← expectV2 (psKernelExprV2ValidateLinear arena)
  let finish ← IO.monoMsNow
  requireV2 "exponential-sharing-replay-count"
    (checked.nodes.size == arena.nodes.size)
  let entry ← expectV2 (psKernelExprV2Lookup checked root)
  requireV2 "exponential-sharing-depth" (entry.depth == depth + 1)
  requireV2 "exponential-sharing-identity"
    (psKernelExprV2Eq checked root root)
  let _ ← expectV2 (psKernelExprV2Decode checked root)
  IO.println s!"PSC1_EXPR_V2_DAG_REPLAY nodes={arena.nodes.size} levels={depth} elapsed_ms={finish-begin}"

/-
Persistent-index regression tests. This index is intentionally not yet the
production V2 arena: the JS persistent array-copy issue must be measured.
-/
private def testIndexedArena : IO Unit := do
  let mut classic := psKernelExprV2Empty
  let mut indexed := psKernelExprV2IndexedEmpty
  for i in [:384] do
    let (nextClassic, id) := psKernelExprV2MkBVar classic i
    classic := nextClassic
    let entry ← expectV2 (psKernelExprV2Lookup classic id)
    let (nextIndexed, insertedId) ←
      expectV2 (psKernelExprV2IndexedPush indexed entry)
    indexed := nextIndexed
    unless insertedId == id do
      throw (IO.userError "PSC1_V2_INDEX_ID_MISMATCH")
  requireV2 "indexed-count-parity"
    (indexed.size == classic.nodes.size)
  let _ ← expectV2 (psKernelExprV2ValidateLinear classic)
  for i in [:384] do
    let c ← expectV2 (psKernelExprV2Lookup classic i)
    match psKernelExprV2IndexedFind indexed i with
    | Option.none =>
        throw (IO.userError "PSC1_V2_INDEX_LOOKUP_MISSING")
    | Option.some v =>
        unless psKernelExprV2SameMetadata c v do
          throw (IO.userError "PSC1_V2_INDEX_METADATA_MISMATCH")
  requireV2 "indexed-no-out-of-range-alias"
    (match psKernelExprV2IndexedFind indexed 384 with
      | Option.none => true
      | Option.some _ => false)
  let old := indexed
  let (newArena, newId) ← expectV2
    (psKernelExprV2IndexedPush indexed
      (← expectV2 (psKernelExprV2Lookup classic 0)))
  requireV2 "indexed-persistent-old-root"
    (match psKernelExprV2IndexedFind old newId with
      | Option.none => true
      | Option.some _ => false)
  requireV2 "indexed-new-root-has-entry"
    (match psKernelExprV2IndexedFind newArena newId with
      | Option.none => false
      | Option.some _ => true)
  IO.println "PSC1_EXPR_V2_INDEXED: PASS nodes=384"

private def testIndexedSmartConstructors : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "indexedDemo"
  let mut arrayArena := psKernelExprV2Empty
  let mut indexedArena := psKernelExprV2IndexedEmpty
  let mut cases : List (String × Nat × Nat) := List.nil

  let (a0, b0) := psKernelExprV2MkBVar arrayArena 0
  let (i0, j0) ← expectV2 (psKernelExprV2IndexedMkBVar indexedArena 0)
  arrayArena := a0
  indexedArena := i0
  cases := ("bvar", b0, j0) :: cases

  let (a1, b1) := psKernelExprV2MkBVar arrayArena 2
  let (i1, j1) ← expectV2 (psKernelExprV2IndexedMkBVar indexedArena 2)
  arrayArena := a1
  indexedArena := i1
  cases := ("bvar2", b1, j1) :: cases

  let (a2, b2) := psKernelExprV2MkFVar arrayArena name
  let (i2, j2) ← expectV2 (psKernelExprV2IndexedMkFVar indexedArena name)
  arrayArena := a2
  indexedArena := i2
  cases := ("fvar", b2, j2) :: cases

  let (a3, b3) := psKernelExprV2MkMVar arrayArena name
  let (i3, j3) ← expectV2 (psKernelExprV2IndexedMkMVar indexedArena name)
  arrayArena := a3
  indexedArena := i3
  cases := ("mvar", b3, j3) :: cases

  let (a4, b4) := psKernelExprV2MkSort arrayArena PsKernelLevel.zero
  let (i4, j4) ← expectV2 (psKernelExprV2IndexedMkSort indexedArena PsKernelLevel.zero)
  arrayArena := a4
  indexedArena := i4
  cases := ("sort", b4, j4) :: cases

  let (a5, b5) := psKernelExprV2MkConst arrayArena name [PsKernelLevel.zero]
  let (i5, j5) ← expectV2 (psKernelExprV2IndexedMkConst indexedArena name [PsKernelLevel.zero])
  arrayArena := a5
  indexedArena := i5
  cases := ("const", b5, j5) :: cases

  let (a6, b6) := psKernelExprV2MkLit arrayArena (.nat 42)
  let (i6, j6) ← expectV2 (psKernelExprV2IndexedMkLit indexedArena (.nat 42))
  arrayArena := a6
  indexedArena := i6
  cases := ("lit", b6, j6) :: cases

  let (a7, b7) ← expectV2 (psKernelExprV2MkApp arrayArena b0 b2)
  let (i7, j7) ← expectV2 (psKernelExprV2IndexedMkApp indexedArena j0 j2)
  arrayArena := a7
  indexedArena := i7
  cases := ("app", b7, j7) :: cases

  let (a8, b8) ← expectV2
    (psKernelExprV2MkLam arrayArena name b4 b1 PsKernelBinderInfo.default)
  let (i8, j8) ← expectV2
    (psKernelExprV2IndexedMkLam indexedArena name j4 j1 PsKernelBinderInfo.default)
  arrayArena := a8
  indexedArena := i8
  cases := ("lambda", b8, j8) :: cases

  let (a9, b9) ← expectV2
    (psKernelExprV2MkForall arrayArena name b4 b0 PsKernelBinderInfo.implicit)
  let (i9, j9) ← expectV2
    (psKernelExprV2IndexedMkForall indexedArena name j4 j0 PsKernelBinderInfo.implicit)
  arrayArena := a9
  indexedArena := i9
  cases := ("forall", b9, j9) :: cases

  let (a10, b10) ← expectV2 (psKernelExprV2MkLet arrayArena name b4 b2 b1 false)
  let (i10, j10) ← expectV2 (psKernelExprV2IndexedMkLet indexedArena name j4 j2 j1 false)
  arrayArena := a10
  indexedArena := i10
  cases := ("let", b10, j10) :: cases

  let (a11, b11) ← expectV2 (psKernelExprV2MkMData arrayArena 31 b7)
  let (i11, j11) ← expectV2 (psKernelExprV2IndexedMkMData indexedArena 31 j7)
  arrayArena := a11
  indexedArena := i11
  cases := ("mdata", b11, j11) :: cases

  let (a12, b12) ← expectV2 (psKernelExprV2MkProj arrayArena name 0 b11)
  let (i12, j12) ← expectV2 (psKernelExprV2IndexedMkProj indexedArena name 0 j11)
  arrayArena := a12
  indexedArena := i12
  cases := ("proj", b12, j12) :: cases

  requireV2 "all-smart-builder-count-parity"
    (indexedArena.size == arrayArena.nodes.size)
  let _ ← expectV2 (psKernelExprV2ValidateLinear arrayArena)
  for (label, a, b) in cases do
    requireV2 ("indexed-smart-id-" ++ label) (a == b)
    let old ← expectV2 (psKernelExprV2Lookup arrayArena a)
    let newer ← expectV2 (psKernelExprV2IndexedRequire indexedArena b)
    requireV2 ("indexed-smart-metadata-" ++ label)
      (psKernelExprV2SameMetadata old newer)
  requireV2 "indexed-smart-invalid-child"
    (match psKernelExprV2IndexedMkApp indexedArena 7777 j2 with
      | Except.error _ => true
      | Except.ok _ => false)
  let mut shared := indexedArena
  let mut root := j0
  for _ in [:24] do
    let (next, id) ← expectV2 (psKernelExprV2IndexedMkApp shared root root)
    shared := next
    root := id
  let finalEntry ← expectV2 (psKernelExprV2IndexedRequire shared root)
  requireV2 "indexed-smart-large-sharing-depth" (finalEntry.depth == 25)
  requireV2 "indexed-smart-large-sharing-nodes"
    (shared.size == indexedArena.size + 24)
  IO.println "PSC1_EXPR_V2_INDEXED_BUILDERS: PASS"

private def testChunkedSmartConstructors : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "chunkedDemo"
  let mut arrayArena := psKernelExprV2Empty
  let mut chunkedArena := psKernelExprV2ChunkedEmpty
  let mut cases : List (String × Nat × Nat) := List.nil

  let (a0, b0) := psKernelExprV2MkBVar arrayArena 0
  let (i0, j0) ← expectV2 (psKernelExprV2ChunkedMkBVar chunkedArena 0)
  arrayArena := a0
  chunkedArena := i0
  cases := ("bvar", b0, j0) :: cases

  let (a1, b1) := psKernelExprV2MkBVar arrayArena 2
  let (i1, j1) ← expectV2 (psKernelExprV2ChunkedMkBVar chunkedArena 2)
  arrayArena := a1
  chunkedArena := i1
  cases := ("bvar2", b1, j1) :: cases

  let (a2, b2) := psKernelExprV2MkFVar arrayArena name
  let (i2, j2) ← expectV2 (psKernelExprV2ChunkedMkFVar chunkedArena name)
  arrayArena := a2
  chunkedArena := i2
  cases := ("fvar", b2, j2) :: cases

  let (a3, b3) := psKernelExprV2MkMVar arrayArena name
  let (i3, j3) ← expectV2 (psKernelExprV2ChunkedMkMVar chunkedArena name)
  arrayArena := a3
  chunkedArena := i3
  cases := ("mvar", b3, j3) :: cases

  let (a4, b4) := psKernelExprV2MkSort arrayArena PsKernelLevel.zero
  let (i4, j4) ← expectV2 (psKernelExprV2ChunkedMkSort chunkedArena PsKernelLevel.zero)
  arrayArena := a4
  chunkedArena := i4
  cases := ("sort", b4, j4) :: cases

  let (a5, b5) := psKernelExprV2MkConst arrayArena name [PsKernelLevel.zero]
  let (i5, j5) ← expectV2 (psKernelExprV2ChunkedMkConst chunkedArena name [PsKernelLevel.zero])
  arrayArena := a5
  chunkedArena := i5
  cases := ("const", b5, j5) :: cases

  let (a6, b6) := psKernelExprV2MkLit arrayArena (.nat 42)
  let (i6, j6) ← expectV2 (psKernelExprV2ChunkedMkLit chunkedArena (.nat 42))
  arrayArena := a6
  chunkedArena := i6
  cases := ("lit", b6, j6) :: cases

  let (a7, b7) ← expectV2 (psKernelExprV2MkApp arrayArena b0 b2)
  let (i7, j7) ← expectV2 (psKernelExprV2ChunkedMkApp chunkedArena j0 j2)
  arrayArena := a7
  chunkedArena := i7
  cases := ("app", b7, j7) :: cases

  let (a8, b8) ← expectV2
    (psKernelExprV2MkLam arrayArena name b4 b1 PsKernelBinderInfo.default)
  let (i8, j8) ← expectV2
    (psKernelExprV2ChunkedMkLam chunkedArena name j4 j1 PsKernelBinderInfo.default)
  arrayArena := a8
  chunkedArena := i8
  cases := ("lambda", b8, j8) :: cases

  let (a9, b9) ← expectV2
    (psKernelExprV2MkForall arrayArena name b4 b0 PsKernelBinderInfo.implicit)
  let (i9, j9) ← expectV2
    (psKernelExprV2ChunkedMkForall chunkedArena name j4 j0 PsKernelBinderInfo.implicit)
  arrayArena := a9
  chunkedArena := i9
  cases := ("forall", b9, j9) :: cases

  let (a10, b10) ← expectV2 (psKernelExprV2MkLet arrayArena name b4 b2 b1 false)
  let (i10, j10) ← expectV2 (psKernelExprV2ChunkedMkLet chunkedArena name j4 j2 j1 false)
  arrayArena := a10
  chunkedArena := i10
  cases := ("let", b10, j10) :: cases

  let (a11, b11) ← expectV2 (psKernelExprV2MkMData arrayArena 31 b7)
  let (i11, j11) ← expectV2 (psKernelExprV2ChunkedMkMData chunkedArena 31 j7)
  arrayArena := a11
  chunkedArena := i11
  cases := ("mdata", b11, j11) :: cases

  let (a12, b12) ← expectV2 (psKernelExprV2MkProj arrayArena name 0 b11)
  let (i12, j12) ← expectV2 (psKernelExprV2ChunkedMkProj chunkedArena name 0 j11)
  arrayArena := a12
  chunkedArena := i12
  cases := ("proj", b12, j12) :: cases

  requireV2 "all-smart-builder-count-parity"
    (chunkedArena.size == arrayArena.nodes.size)
  let _ ← expectV2 (psKernelExprV2ValidateLinear arrayArena)
  for (label, a, b) in cases do
    requireV2 ("chunked-smart-id-" ++ label) (a == b)
    let old ← expectV2 (psKernelExprV2Lookup arrayArena a)
    let newer ← expectV2 (psKernelExprV2ChunkedRequire chunkedArena b)
    requireV2 ("chunked-smart-metadata-" ++ label)
      (psKernelExprV2SameMetadata old newer)
  requireV2 "chunked-smart-invalid-child"
    (match psKernelExprV2ChunkedMkApp chunkedArena 7777 j2 with
      | Except.error _ => true
      | Except.ok _ => false)
  let mut shared := chunkedArena
  let mut root := j0
  for _ in [:24] do
    let (next, id) ← expectV2 (psKernelExprV2ChunkedMkApp shared root root)
    shared := next
    root := id
  let finalEntry ← expectV2 (psKernelExprV2ChunkedRequire shared root)
  requireV2 "chunked-smart-large-sharing-depth" (finalEntry.depth == 25)
  requireV2 "chunked-smart-large-sharing-nodes"
    (shared.size == chunkedArena.size + 24)
  IO.println "PSC1_EXPR_V2_CHUNKED_BUILDERS: PASS"


private def testChunkedArena : IO Unit := do
  for limit in [0, 1, 8, 32, 64] do
    let mut classic := psKernelExprV2Empty
    let mut chunked := psKernelExprV2ChunkedEmptyWithLimit limit
    for i in [:512] do
      let (nextClassic, id) := psKernelExprV2MkBVar classic i
      classic := nextClassic
      let entry ← expectV2 (psKernelExprV2Lookup classic id)
      let (nextChunked, assigned) := psKernelExprV2ChunkedPush chunked entry
      chunked := nextChunked
      unless assigned == id do
        throw (IO.userError "PSC1_V2_CHUNKED_ID_MISMATCH")
    requireV2 s!"chunked-size-{limit}"
      (chunked.size == classic.nodes.size)
    let checkedPortable ← expectV2 (psKernelExprV2PortableValidate chunked)
    requireV2 s!"portable-replay-node-count-{limit}"
      (checkedPortable.size == chunked.size)
    requireV2 s!"portable-replay-chunk-limit-{limit}"
      (checkedPortable.chunkLimit == chunked.chunkLimit)
    let _ ← expectV2 (psKernelExprV2ValidateChunked chunked)
    requireV2 s!"chunked-replay-validated-{limit}" true
    for id in [:512] do
      let reference ← expectV2 (psKernelExprV2Lookup classic id)
      match psKernelExprV2ChunkedFind chunked id with
      | Option.none =>
          throw (IO.userError "PSC1_V2_CHUNKED_MISSING")
      | Option.some value =>
          unless psKernelExprV2SameMetadata reference value do
            throw (IO.userError "PSC1_V2_CHUNKED_METADATA_MISMATCH")
    requireV2 s!"chunked-no-out-of-bounds-{limit}"
      (match psKernelExprV2ChunkedFind chunked 512 with
        | Option.none => true
        | Option.some _ => false)
    let original := chunked
    let entry ← expectV2 (psKernelExprV2Lookup classic 0)
    let (extended, newId) := psKernelExprV2ChunkedPush chunked entry
    requireV2 s!"chunked-persistent-old-snapshot-{limit}"
      (match psKernelExprV2ChunkedFind original newId with
        | Option.none => true
        | Option.some _ => false)
    requireV2 s!"chunked-extended-{limit}"
      (match psKernelExprV2ChunkedFind extended newId with
        | Option.none => false
        | Option.some _ => true)
  let (single, id) := psKernelExprV2MkBVar psKernelExprV2Empty 0
  let validEntry ← expectV2 (psKernelExprV2Lookup single id)
  let corruptEntry : PsKernelExprV2Entry := {
    validEntry with hasFVar := true
  }
  let (bad, _) := psKernelExprV2ChunkedPush
    psKernelExprV2ChunkedEmpty corruptEntry
  requireV2 "chunked-forged-fvar-rejected"
    (match psKernelExprV2ValidateChunked bad with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "portable-forged-fvar-rejected"
    (match psKernelExprV2PortableValidate bad with
      | Except.error _ => true
      | Except.ok _ => false)
  let invalidReference : PsKernelExprV2Entry := {
    validEntry with node := PsKernelExprV2Node.app 42 0
  }
  let (forward, _) := psKernelExprV2ChunkedPush
    psKernelExprV2ChunkedEmpty invalidReference
  requireV2 "chunked-forward-reference-rejected"
    (match psKernelExprV2ValidateChunked forward with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "portable-forward-reference-rejected"
    (match psKernelExprV2PortableValidate forward with
      | Except.error _ => true
      | Except.ok _ => false)
  let badLimit : PsKernelExprV2ChunkedArena := {
    active := Array.emptyWithCapacity 0
    frozen := []
    size := 0
    chunkLimit := 0
  }
  requireV2 "portable-zero-chunk-limit-rejected"
    (match psKernelExprV2PortableValidate badLimit with
      | Except.error _ => true
      | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_CHUNKED: PASS nodes=512 limits=5"



/-
M3 lifted DAG oracle: exact legacy tree is built only for the finite test
fixtures; validated chunked V2 execution processes shared IDs directly.
-/
private def testChunkedLiftDifferential : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "lifted"
  let mut a := psKernelExprV2ChunkedEmpty
  let (a0,b0) ← expectV2 (psKernelExprV2ChunkedMkBVar a 0)
  a := a0
  let (a1,b2) ← expectV2 (psKernelExprV2ChunkedMkBVar a 2)
  a := a1
  let (a2,sort) ← expectV2 (psKernelExprV2ChunkedMkSort a PsKernelLevel.zero)
  a := a2
  let (a3,app) ← expectV2 (psKernelExprV2ChunkedMkApp a b0 b2)
  a := a3
  let (a4,lam) ← expectV2
    (psKernelExprV2ChunkedMkLam a name sort app PsKernelBinderInfo.default)
  a := a4
  let (a5,pi) ← expectV2
    (psKernelExprV2ChunkedMkForall a name b2 app PsKernelBinderInfo.implicit)
  a := a5
  let (a6,letE) ← expectV2
    (psKernelExprV2ChunkedMkLet a name b2 app b0 false)
  a := a6
  let (a7,mdata) ← expectV2 (psKernelExprV2ChunkedMkMData a 19 app)
  a := a7
  let (a8,proj) ← expectV2 (psKernelExprV2ChunkedMkProj a name 1 mdata)
  a := a8
  let cases : List (String × Nat) := [
    ("bvar-zero",b0),("bvar-two",b2),("sort",sort),
    ("app",app),("lambda",lam),("forall",pi),
    ("let",letE),("metadata",mdata),("projection",proj)
  ]
  let _ ← expectV2 (psKernelExprV2ValidateChunked a)
  for (label,id) in cases do
    let old ← expectV2 (psKernelExprV2ChunkedDecode a id)
    for cutoff in [0,1,2,3] do
      for amount in [0,1,2] do
        let expected := psKernelExprLiftLooseBVars old cutoff amount
        let (transformed,newId) ← expectV2
          (psKernelExprV2LiftChecked a id cutoff amount)
        let actual ← expectV2
          (psKernelExprV2ChunkedDecode transformed newId)
        requireV2 s!"lift-{label}-cutoff{cutoff}-amount{amount}"
          (psKernelExprEqual actual expected &&
            psKernelExprEq actual expected)
        let (portableArena,portableId) ← expectV2
          (psKernelExprV2PortableLiftChecked a id cutoff amount)
        let portableActual ← expectV2
          (psKernelExprV2ChunkedDecode portableArena portableId)
        requireV2 s!"portable-lift-{label}-cutoff{cutoff}-amount{amount}"
          (psKernelExprEqual portableActual expected &&
            psKernelExprEq portableActual expected)
        requireV2 s!"portable-vs-native-lift-{label}-cutoff{cutoff}-amount{amount}"
          (psKernelExprEq portableActual actual)
        if amount == 0 then
          requireV2 s!"lift-zero-allocation-{label}"
            (transformed.size == a.size && newId == id)
  IO.println "PSC1_EXPR_V2_LIFT_DIFFERENTIAL: PASS"

private def testSharedLift : IO Unit := do
  let (initial,leaf) ← expectV2
    (psKernelExprV2ChunkedMkBVar psKernelExprV2ChunkedEmpty 0)
  let mut a := initial
  let mut root := leaf
  let depth : Nat := 20
  for _ in [:depth] do
    let (next,newId) ← expectV2
      (psKernelExprV2ChunkedMkApp a root root)
    a := next
    root := newId
  requireV2 "lift-input-shared-node-count"
    (a.size == depth+1)
  let (transformed,newRoot) ← expectV2 (psKernelExprV2LiftChecked a root 0 1)
  let _ ← expectV2 (psKernelExprV2ValidateChunked transformed)
  let newEntry ← expectV2 (psKernelExprV2ChunkedRequire transformed newRoot)
  requireV2 "lift-shared-result-depth"
    (newEntry.depth == depth+1)
  requireV2 "lift-sharing-bounded-node-growth"
    (transformed.size <= a.size + depth + 1)
  let (unchanged,sameId) ← expectV2 (psKernelExprV2LiftChecked a root 0 0)
  requireV2 "lift-zero-preserves-identity"
    (unchanged.size == a.size && sameId == root)
  let valid ← expectV2 (psKernelExprV2ChunkedRequire a leaf)
  let corrupt : PsKernelExprV2Entry := { valid with looseRange := 0 }
  let (forged,forgedId) := psKernelExprV2ChunkedPush
    psKernelExprV2ChunkedEmpty corrupt
  requireV2 "lift-rejects-unvalidated-metadata"
    (match psKernelExprV2LiftChecked forged forgedId 0 1 with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "portable-lift-rejects-unvalidated-metadata"
    (match psKernelExprV2PortableLiftChecked forged forgedId 0 1 with
      | Except.error _ => true
      | Except.ok _ => false)
  let (portableArena,portableRoot) ← expectV2
    (psKernelExprV2PortableLiftChecked a root 0 1)
  let portableEntry ← expectV2
    (psKernelExprV2ChunkedRequire portableArena portableRoot)
  requireV2 "portable-shared-lift-depth"
    (portableEntry.depth == newEntry.depth)
  requireV2 "portable-shared-lift-bounded-growth"
    (portableArena.size <= a.size + depth + 1)
  IO.println s!"PSC1_EXPR_V2_LIFT_SHARING: PASS input_nodes={a.size} output_nodes={transformed.size}"



/- Finite, source-exact instantiate1 oracle over each V2 expression constructor.
Each replacement remains in the same validated arena; no conversion is
performed by the optimized instantiation worker. -/
private def testPortableInstantiation : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "instantiate"
  let mut arena := psKernelExprV2ChunkedEmpty
  let (a0,b0) ← expectV2 (psKernelExprV2ChunkedMkBVar arena 0)
  arena := a0
  let (a1,b1) ← expectV2 (psKernelExprV2ChunkedMkBVar arena 1)
  arena := a1
  let (a2,b2) ← expectV2 (psKernelExprV2ChunkedMkBVar arena 2)
  arena := a2
  let (a3,sort) ← expectV2
    (psKernelExprV2ChunkedMkSort arena PsKernelLevel.zero)
  arena := a3
  let (a4,fv) ← expectV2 (psKernelExprV2ChunkedMkFVar arena name)
  arena := a4
  let (a5,app) ← expectV2 (psKernelExprV2ChunkedMkApp arena b0 b2)
  arena := a5
  let (a6,lam) ← expectV2
    (psKernelExprV2ChunkedMkLam arena name sort app PsKernelBinderInfo.default)
  arena := a6
  let (a7,pi) ← expectV2
    (psKernelExprV2ChunkedMkForall arena name b2 app PsKernelBinderInfo.implicit)
  arena := a7
  let (a8,letE) ← expectV2
    (psKernelExprV2ChunkedMkLet arena name b2 app b1 false)
  arena := a8
  let (a9,mdata) ← expectV2 (psKernelExprV2ChunkedMkMData arena 17 app)
  arena := a9
  let (a10,proj) ← expectV2
    (psKernelExprV2ChunkedMkProj arena name 0 mdata)
  arena := a10
  let (a11,both) ← expectV2 (psKernelExprV2ChunkedMkApp arena app app)
  arena := a11
  let cases : List (String × Nat) := [
    ("bvar-zero",b0),("bvar-one",b1),("bvar-two",b2),
    ("sort",sort),("fvar",fv),("app",app),("lambda",lam),
    ("forall",pi),("let",letE),("mdata",mdata),
    ("projection",proj),("shared-app",both)
  ]
  let replacements : List (String × Nat) := [
    ("closed-sort",sort),("open-bvar2",b2),
    ("open-app",app),("free-var",fv)
  ]
  let _ ← expectV2 (psKernelExprV2PortableValidate arena)
  for (label,root) in cases do
    let source ← expectV2 (psKernelExprV2ChunkedDecode arena root)
    for (replacementLabel,replacement) in replacements do
      let oldReplacement ← expectV2
        (psKernelExprV2ChunkedDecode arena replacement)
      let expected := psKernelExprInstantiate1 source oldReplacement
      let (resultArena,resultId) ← expectV2
        (psKernelExprV2PortableInstantiate1Checked arena root replacement)
      let actual ← expectV2 (psKernelExprV2ChunkedDecode resultArena resultId)
      requireV2 s!"instantiate-{label}-{replacementLabel}"
        (psKernelExprEq actual expected && psKernelExprEqual actual expected)
  requireV2 "instantiate-invalid-root"
    (match psKernelExprV2PortableInstantiate1Checked arena 999 sort with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "instantiate-invalid-replacement"
    (match psKernelExprV2PortableInstantiate1Checked arena app 999 with
      | Except.error _ => true
      | Except.ok _ => false)
  let entry ← expectV2 (psKernelExprV2ChunkedRequire arena b0)
  let forgedEntry : PsKernelExprV2Entry := {
    entry with looseRange := 0
  }
  let (forged,id) := psKernelExprV2ChunkedPush
    psKernelExprV2ChunkedEmpty forgedEntry
  requireV2 "instantiate-rejects-forged-range"
    (match psKernelExprV2PortableInstantiate1Checked forged id id with
      | Except.error _ => true
      | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_INSTANTIATE_DIFFERENTIAL: PASS cases=48"

private def testPortableSharedInstantiation : IO Unit := do
  let (initial,leaf) ← expectV2
    (psKernelExprV2ChunkedMkBVar psKernelExprV2ChunkedEmpty 0)
  let (a0,sort) ← expectV2
    (psKernelExprV2ChunkedMkSort initial PsKernelLevel.zero)
  let mut arena := a0
  let mut root := leaf
  let depth : Nat := 20
  for _ in [:depth] do
    let (next,newId) ← expectV2
      (psKernelExprV2ChunkedMkApp arena root root)
    arena := next
    root := newId
  requireV2 "instantiate-shared-input-nodes" (arena.size == depth+2)
  let (resultArena,resultId) ← expectV2
    (psKernelExprV2PortableInstantiate1Checked arena root sort)
  let resultEntry ← expectV2
    (psKernelExprV2ChunkedRequire resultArena resultId)
  requireV2 "instantiate-shared-depth" (resultEntry.depth == depth+1)
  requireV2 "instantiate-shared-bound-variable-removed"
    (resultEntry.looseRange == 0)
  requireV2 "instantiate-shared-bounded-node-growth"
    (resultArena.size <= arena.size+depth+1)
  requireV2 "instantiate-shared-subtree-reused"
    (match resultEntry.node with
      | PsKernelExprV2Node.app left right => left == right
      | _ => false)
  IO.println s!"PSC1_EXPR_V2_INSTANTIATE_SHARING: PASS input_nodes={arena.size} output_nodes={resultArena.size}"



/- One-step beta/zeta/mdata semantic parity, without claiming full WHNF. -/
private def testPortableHeadReduction : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "head"
  let (a0,b0) ← expectV2
    (psKernelExprV2ChunkedMkBVar psKernelExprV2ChunkedEmpty 0)
  let (a1,b1) ← expectV2 (psKernelExprV2ChunkedMkBVar a0 1)
  let (a2,sort) ← expectV2
    (psKernelExprV2ChunkedMkSort a1 PsKernelLevel.zero)
  let (a3,lam) ← expectV2
    (psKernelExprV2ChunkedMkLam a2 name sort b0 PsKernelBinderInfo.default)
  let (a4,beta) ← expectV2
    (psKernelExprV2ChunkedMkApp a3 lam sort)
  let (a5,zeta) ← expectV2
    (psKernelExprV2ChunkedMkLet a4 name sort sort b0 false)
  let (a6,mdata) ← expectV2
    (psKernelExprV2ChunkedMkMData a5 77 beta)
  let (a7,neutral) ← expectV2
    (psKernelExprV2ChunkedMkApp a6 sort sort)
  let (a8,outerLam) ← expectV2
    (psKernelExprV2ChunkedMkLam a7 name sort b1 PsKernelBinderInfo.default)
  let (a9,outerBeta) ← expectV2
    (psKernelExprV2ChunkedMkApp a8 outerLam sort)
  let (a10,outerZeta) ← expectV2
    (psKernelExprV2ChunkedMkLet a9 name sort sort b1 false)
  let cases : List (String × Nat × PsKernelExpr) := [
    ("beta-identity",beta,PsKernelExpr.sort PsKernelLevel.zero),
    ("zeta-identity",zeta,PsKernelExpr.sort PsKernelLevel.zero),
    ("metadata-one-step",mdata,
      PsKernelExpr.app
        (PsKernelExpr.lam name
          (PsKernelExpr.sort PsKernelLevel.zero)
          (PsKernelExpr.bvar 0) PsKernelBinderInfo.default)
        (PsKernelExpr.sort PsKernelLevel.zero)),
    ("neutral-app",neutral,
      PsKernelExpr.app
        (PsKernelExpr.sort PsKernelLevel.zero)
        (PsKernelExpr.sort PsKernelLevel.zero)),
    ("beta-outer-decrement",outerBeta,PsKernelExpr.bvar 0),
    ("zeta-outer-decrement",outerZeta,PsKernelExpr.bvar 0),
    ("sort",sort,PsKernelExpr.sort PsKernelLevel.zero)
  ]
  for (label,root,expected) in cases do
    let (resultArena,resultId) ← expectV2
      (psKernelExprV2PortableHeadStepChecked a10 root)
    let actual ← expectV2
      (psKernelExprV2ChunkedDecode resultArena resultId)
    requireV2 s!"head-step-{label}"
      (psKernelExprEq actual expected && psKernelExprEqual actual expected)
  let (neutralArena,neutralRoot) ← expectV2
    (psKernelExprV2PortableHeadStepChecked a10 neutral)
  requireV2 "head-step-neutral-identity"
    (neutralRoot == neutral && neutralArena.size == a10.size)
  requireV2 "head-step-invalid-root"
    (match psKernelExprV2PortableHeadStepChecked a10 99999 with
      | Except.error _ => true
      | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_HEAD_REDUCTION: PASS cases=7"



private def testPortableHeadSequence : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "sequence"
  let (a0,b0) ← expectV2
    (psKernelExprV2ChunkedMkBVar psKernelExprV2ChunkedEmpty 0)
  let (a1,sort) ← expectV2
    (psKernelExprV2ChunkedMkSort a0 PsKernelLevel.zero)
  let (a2,lam) ← expectV2
    (psKernelExprV2ChunkedMkLam a1 name sort b0 PsKernelBinderInfo.default)
  let (a3,beta) ← expectV2
    (psKernelExprV2ChunkedMkApp a2 lam sort)
  let (a4,metadata) ← expectV2
    (psKernelExprV2ChunkedMkMData a3 7 beta)
  let (a5,outerLet) ← expectV2
    (psKernelExprV2ChunkedMkLet a4 name sort sort metadata false)
  let (doneArena,doneRoot) ← expectV2
    (psKernelExprV2PortableHeadSequenceChecked 4 a5 outerLet)
  let (fastArena,fastRoot) ← expectV2
    (psKernelExprV2PortableHeadMachineChecked 4 a5 outerLet)
  requireV2 "head-machine-matches-slow-root"
    (fastRoot == doneRoot && fastArena.size == doneArena.size)
  requireV2 "head-sequence-composed-normal-form"
    (doneRoot == sort && doneArena.size == a5.size)
  requireV2 "head-sequence-rejects-insufficient-fuel"
    (match psKernelExprV2PortableHeadSequenceChecked 3 a5 outerLet with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "head-machine-rejects-insufficient-fuel"
    (match psKernelExprV2PortableHeadMachineChecked 3 a5 outerLet with
      | Except.error _ => true
      | Except.ok _ => false)
  let (neutral,neutralRoot) ← expectV2
    (psKernelExprV2PortableHeadSequenceChecked 1 a5 sort)
  requireV2 "head-sequence-neutral-fuel-one"
    (neutralRoot == sort && neutral.size == a5.size)
  requireV2 "head-sequence-zero-fuel-rejected"
    (match psKernelExprV2PortableHeadSequenceChecked 0 a5 sort with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "head-machine-invalid-root"
    (match psKernelExprV2PortableHeadMachineChecked 4 a5 99999 with
      | Except.error _ => true
      | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_HEAD_SEQUENCE: PASS"


/-
Head sequences over nested let terms that do not depend on their binders.
Both implementations must reach the same root under identical research
step fuel; slow replays on every step, fast replays once at entry and exit.
Timings are observations, never proof of relative performance.
-/
private def testHeadMachineDeep : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "headMachine"
  for depth in [1,8,24,48] do
    let (start,sort) ← expectV2
      (psKernelExprV2ChunkedMkSort
        psKernelExprV2ChunkedEmpty PsKernelLevel.zero)
    let mut arena := start
    let mut root := sort
    for _ in [:depth] do
      let (next,id) ← expectV2
        (psKernelExprV2ChunkedMkLet
          arena name sort sort root false)
      arena := next
      root := id
    let sourceSize := arena.size
    let t0 ← IO.monoMsNow
    let (slowArena,slowRoot) ← expectV2
      (psKernelExprV2PortableHeadSequenceChecked
        (depth+1) arena root)
    let t1 ← IO.monoMsNow
    let (fastArena,fastRoot) ← expectV2
      (psKernelExprV2PortableHeadMachineChecked
        (depth+1) arena root)
    let t2 ← IO.monoMsNow
    requireV2 s!"head-machine-depth-{depth}-root-parity"
      (slowRoot == sort && fastRoot == sort)
    requireV2 s!"head-machine-depth-{depth}-arena-parity"
      (slowArena.size == sourceSize && fastArena.size == sourceSize)
    requireV2 s!"head-machine-depth-{depth}-fail-closed-fuel"
      (match psKernelExprV2PortableHeadMachineChecked depth arena root with
        | Except.error _ => true
        | Except.ok _ => false)
    let forged ← expectV2 (psKernelExprV2ChunkedRequire arena root)
    let invalid : PsKernelExprV2Entry := {
      forged with hasFVar := true
    }
    let falseArena : PsKernelExprV2ChunkedArena := {
      active := Array.push arena.active invalid
      frozen := arena.frozen
      size := arena.size + 1
      chunkLimit := arena.chunkLimit
    }
    requireV2 s!"head-machine-depth-{depth}-forged-rejected"
      (match psKernelExprV2PortableHeadMachineChecked
          (depth+1) falseArena root with
        | Except.error _ => true
        | Except.ok _ => false)
    IO.println s!"PSC1_EXPR_V2_HEAD_MACHINE_NATIVE depth={depth} slow_ms={t1-t0} fast_ms={t2-t1} root={fastRoot} size={sourceSize}"
  IO.println "PSC1_EXPR_V2_HEAD_MACHINE: PASS"


/-
Portable V2 alpha-insensitive structural equality, collision safety, and
pair memoization on a repeated DAG. Differentiation against the old
PsKernelExprEq is done only on finitely materialized small expressions.
-/
private def testPortablePairEquality : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "alphaLeft"
  let anotherName := PsKernelName.str PsKernelName.anonymous "alphaRight"
  let mut arena := psKernelExprV2ChunkedEmpty
  let (a0,bvar0) ← expectV2 (psKernelExprV2ChunkedMkBVar arena 0)
  arena := a0
  let (a1,bvarCopy) ← expectV2 (psKernelExprV2ChunkedMkBVar arena 0)
  arena := a1
  let (a2,bvarCollision) ← expectV2
    (psKernelExprV2ChunkedMkBVar arena 65521)
  arena := a2
  let (a3,sort) ← expectV2
    (psKernelExprV2ChunkedMkSort arena PsKernelLevel.zero)
  arena := a3
  let (a4,sortCopy) ← expectV2
    (psKernelExprV2ChunkedMkSort arena PsKernelLevel.zero)
  arena := a4
  let (a5,fvar) ← expectV2 (psKernelExprV2ChunkedMkFVar arena name)
  arena := a5
  let (a6,mvar) ← expectV2 (psKernelExprV2ChunkedMkMVar arena name)
  arena := a6
  let (a7,constant) ← expectV2
    (psKernelExprV2ChunkedMkConst arena name [PsKernelLevel.zero])
  arena := a7
  let (a8,lit) ← expectV2 (psKernelExprV2ChunkedMkLit arena (.nat 5))
  arena := a8
  let (a9,app) ← expectV2
    (psKernelExprV2ChunkedMkApp arena bvar0 sort)
  arena := a9
  let (a10,appCopy) ← expectV2
    (psKernelExprV2ChunkedMkApp arena bvarCopy sortCopy)
  arena := a10
  let (a11,lam) ← expectV2
    (psKernelExprV2ChunkedMkLam arena name sort bvar0 PsKernelBinderInfo.default)
  arena := a11
  let (a12,lamAlpha) ← expectV2
    (psKernelExprV2ChunkedMkLam arena anotherName sortCopy bvarCopy
      PsKernelBinderInfo.implicit)
  arena := a12
  let (a13,forall) ← expectV2
    (psKernelExprV2ChunkedMkForall arena name sort bvar0 PsKernelBinderInfo.default)
  arena := a13
  let (a14,forallAlpha) ← expectV2
    (psKernelExprV2ChunkedMkForall arena anotherName sortCopy bvarCopy
      PsKernelBinderInfo.implicit)
  arena := a14
  let (a15,letE) ← expectV2
    (psKernelExprV2ChunkedMkLet arena name sort sort bvar0 false)
  arena := a15
  let (a16,letCopy) ← expectV2
    (psKernelExprV2ChunkedMkLet arena anotherName sortCopy sortCopy
      bvarCopy false)
  arena := a16
  let (a17,letDifferent) ← expectV2
    (psKernelExprV2ChunkedMkLet arena name sort sort bvar0 true)
  arena := a17
  let (a18,mdata) ← expectV2 (psKernelExprV2ChunkedMkMData arena 22 app)
  arena := a18
  let (a19,mdataCopy) ← expectV2
    (psKernelExprV2ChunkedMkMData arena 22 appCopy)
  arena := a19
  let (a20,proj) ← expectV2 (psKernelExprV2ChunkedMkProj arena name 0 app)
  arena := a20
  let (a21,projCopy) ← expectV2
    (psKernelExprV2ChunkedMkProj arena name 0 appCopy)
  arena := a21
  let pairs : List (String × Nat × Nat) := [
    ("same-id",bvar0,bvar0),
    ("two-bvars",bvar0,bvarCopy),
    ("real-hash-collision",bvar0,bvarCollision),
    ("two-sorts",sort,sortCopy),
    ("sort-vs-const",sort,constant),
    ("fvar-vs-mvar",fvar,mvar),
    ("const-vs-literal",constant,lit),
    ("two-apps",app,appCopy),
    ("two-lambdas-ignore-name-and-info",lam,lamAlpha),
    ("two-foralls-ignore-name-and-info",forall,forallAlpha),
    ("lambda-vs-forall",lam,forall),
    ("two-lets",letE,letCopy),
    ("let-nondep-different",letE,letDifferent),
    ("two-metadata",mdata,mdataCopy),
    ("two-projections",proj,projCopy),
    ("projection-vs-metadata",proj,mdata)
  ]
  let valid ← expectV2 (psKernelExprV2PortableValidate arena)
  for (label,left,right) in pairs do
    let oldLeft ← expectV2 (psKernelExprV2ChunkedDecode valid left)
    let oldRight ← expectV2 (psKernelExprV2ChunkedDecode valid right)
    let expected := psKernelExprEq oldLeft oldRight
    let observed ← expectV2
      (psKernelExprV2PortableEqChecked arena left right)
    requireV2 ("pair-eq-"+label) (observed == expected)
  requireV2 "pair-eq-invalid-left"
    (match psKernelExprV2PortableEqChecked arena 99999 app with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "pair-eq-invalid-right"
    (match psKernelExprV2PortableEqChecked arena app 99999 with
      | Except.error _ => true
      | Except.ok _ => false)
  let forgedEntry ← expectV2 (psKernelExprV2ChunkedRequire arena bvar0)
  let corrupt : PsKernelExprV2Entry := {
    forgedEntry with hasFVar := true
  }
  let (forged,root) := psKernelExprV2ChunkedPush
    psKernelExprV2ChunkedEmpty corrupt
  requireV2 "pair-eq-forged-metadata-rejected"
    (match psKernelExprV2PortableEqChecked forged root root with
      | Except.error _ => true
      | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_PAIR_EQUALITY: PASS cases=16"

private def testPortablePairSharing : IO Unit := do
  let (start,leaf) ← expectV2
    (psKernelExprV2ChunkedMkBVar psKernelExprV2ChunkedEmpty 0)
  let mut arena := start
  let mut lhs := leaf
  let mut rhs := leaf
  let depth : Nat := 24
  for _ in [:depth] do
    let (next,left) ← expectV2
      (psKernelExprV2ChunkedMkApp arena lhs lhs)
    let (next2,right) ← expectV2
      (psKernelExprV2ChunkedMkApp next rhs rhs)
    arena := next2
    lhs := left
    rhs := right
  requireV2 "pair-shared-compact-node-count"
    (arena.size == depth*2+1)
  let equal ← expectV2 (psKernelExprV2PortableEqChecked arena lhs rhs)
  requireV2 "pair-shared-distinct-ids-structurally-equal"
    (lhs != rhs && equal)
  let different ← expectV2
    (psKernelExprV2PortableEqChecked arena leaf lhs)
  requireV2 "pair-shared-shapes-distinct" (!different)
  IO.println "PSC1_EXPR_V2_PAIR_SHARING: PASS nodes=49 depth=24"

def main : IO Unit := do
  testAllConstructors
  testHashCollision
  testInvalidInput
  testDeepSpines
  testExponentialSharing
  testIndexedArena
  testIndexedSmartConstructors
  testChunkedSmartConstructors
  testChunkedArena
  testChunkedLiftDifferential
  testSharedLift
  testPortableInstantiation
  testPortableSharedInstantiation
  testPortableHeadReduction
  testPortableHeadSequence
  testHeadMachineDeep
  testPortablePairEquality
  testPortablePairSharing
  IO.println "PSC1_EXPR_V2_REGRESSION: PASS"
