import Ps.KernelCore.Research.ExprV2Validation
import Ps.KernelCore.Research.ExprV2Lift
import Ps.KernelCore.Research.ExprV2PortableHeadMachine
import Ps.KernelCore.Research.ExprV2PortableEquality
import Ps.KernelCore.Research.ExprV2PortableEqualityBatch
import Ps.KernelCore.Research.ExprV2PortableImport
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


private def testPagedSmartConstructors : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "pagedDemo"
  let mut arrayArena := psKernelExprV2Empty
  let mut pagedArena := psKernelExprV2PagedEmpty
  let mut cases : List (String × Nat × Nat) := List.nil

  let (a0, b0) := psKernelExprV2MkBVar arrayArena 0
  let (i0, j0) ← expectV2 (psKernelExprV2PagedMkBVar pagedArena 0)
  arrayArena := a0
  pagedArena := i0
  cases := ("bvar", b0, j0) :: cases

  let (a1, b1) := psKernelExprV2MkBVar arrayArena 2
  let (i1, j1) ← expectV2 (psKernelExprV2PagedMkBVar pagedArena 2)
  arrayArena := a1
  pagedArena := i1
  cases := ("bvar2", b1, j1) :: cases

  let (a2, b2) := psKernelExprV2MkFVar arrayArena name
  let (i2, j2) ← expectV2 (psKernelExprV2PagedMkFVar pagedArena name)
  arrayArena := a2
  pagedArena := i2
  cases := ("fvar", b2, j2) :: cases

  let (a3, b3) := psKernelExprV2MkMVar arrayArena name
  let (i3, j3) ← expectV2 (psKernelExprV2PagedMkMVar pagedArena name)
  arrayArena := a3
  pagedArena := i3
  cases := ("mvar", b3, j3) :: cases

  let (a4, b4) := psKernelExprV2MkSort arrayArena PsKernelLevel.zero
  let (i4, j4) ← expectV2 (psKernelExprV2PagedMkSort pagedArena PsKernelLevel.zero)
  arrayArena := a4
  pagedArena := i4
  cases := ("sort", b4, j4) :: cases

  let (a5, b5) := psKernelExprV2MkConst arrayArena name [PsKernelLevel.zero]
  let (i5, j5) ← expectV2 (psKernelExprV2PagedMkConst pagedArena name [PsKernelLevel.zero])
  arrayArena := a5
  pagedArena := i5
  cases := ("const", b5, j5) :: cases

  let (a6, b6) := psKernelExprV2MkLit arrayArena (.nat 42)
  let (i6, j6) ← expectV2 (psKernelExprV2PagedMkLit pagedArena (.nat 42))
  arrayArena := a6
  pagedArena := i6
  cases := ("lit", b6, j6) :: cases

  let (a7, b7) ← expectV2 (psKernelExprV2MkApp arrayArena b0 b2)
  let (i7, j7) ← expectV2 (psKernelExprV2PagedMkApp pagedArena j0 j2)
  arrayArena := a7
  pagedArena := i7
  cases := ("app", b7, j7) :: cases

  let (a8, b8) ← expectV2
    (psKernelExprV2MkLam arrayArena name b4 b1 PsKernelBinderInfo.default)
  let (i8, j8) ← expectV2
    (psKernelExprV2PagedMkLam pagedArena name j4 j1 PsKernelBinderInfo.default)
  arrayArena := a8
  pagedArena := i8
  cases := ("lambda", b8, j8) :: cases

  let (a9, b9) ← expectV2
    (psKernelExprV2MkForall arrayArena name b4 b0 PsKernelBinderInfo.implicit)
  let (i9, j9) ← expectV2
    (psKernelExprV2PagedMkForall pagedArena name j4 j0 PsKernelBinderInfo.implicit)
  arrayArena := a9
  pagedArena := i9
  cases := ("forall", b9, j9) :: cases

  let (a10, b10) ← expectV2 (psKernelExprV2MkLet arrayArena name b4 b2 b1 false)
  let (i10, j10) ← expectV2 (psKernelExprV2PagedMkLet pagedArena name j4 j2 j1 false)
  arrayArena := a10
  pagedArena := i10
  cases := ("let", b10, j10) :: cases

  let (a11, b11) ← expectV2 (psKernelExprV2MkMData arrayArena 31 b7)
  let (i11, j11) ← expectV2 (psKernelExprV2PagedMkMData pagedArena 31 j7)
  arrayArena := a11
  pagedArena := i11
  cases := ("mdata", b11, j11) :: cases

  let (a12, b12) ← expectV2 (psKernelExprV2MkProj arrayArena name 0 b11)
  let (i12, j12) ← expectV2 (psKernelExprV2PagedMkProj pagedArena name 0 j11)
  arrayArena := a12
  pagedArena := i12
  cases := ("proj", b12, j12) :: cases

  requireV2 "all-smart-builder-count-parity"
    (pagedArena.size == arrayArena.nodes.size)
  let _ ← expectV2 (psKernelExprV2ValidateLinear arrayArena)
  let _ ← expectV2 (psKernelExprV2PagedValidate pagedArena)
  for (label, a, b) in cases do
    requireV2 ("paged-smart-id-" ++ label) (a == b)
    let old ← expectV2 (psKernelExprV2Lookup arrayArena a)
    let newer ← expectV2 (psKernelExprV2PagedRequire pagedArena b)
    requireV2 ("paged-smart-metadata-" ++ label)
      (psKernelExprV2SameMetadata old newer)
  requireV2 "paged-smart-invalid-child"
    (match psKernelExprV2PagedMkApp pagedArena 7777 j2 with
      | Except.error _ => true
      | Except.ok _ => false)
  let mut shared := pagedArena
  let mut root := j0
  for _ in [:24] do
    let (next, id) ← expectV2 (psKernelExprV2PagedMkApp shared root root)
    shared := next
    root := id
  let finalEntry ← expectV2 (psKernelExprV2PagedRequire shared root)
  requireV2 "paged-smart-large-sharing-depth" (finalEntry.depth == 25)
  requireV2 "paged-smart-large-sharing-nodes"
    (shared.size == pagedArena.size + 24)
  IO.println "PSC1_EXPR_V2_PAGED_BUILDERS: PASS"



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

/-
Test-only comparison adapter. It does NOT bless source metadata: both
incoming chunks and the resulting paged arena must independently validate.
Each node is copied in topological ID order so the paged validator can
recompute every cached field using its own checked smart constructors.
-/
private def psKernelExprV2CopyPagedForTest
    (chunked : PsKernelExprV2ChunkedArena) :
    IO PsKernelExprV2PagedArena := do
  let _ ← expectV2 (psKernelExprV2PortableValidate chunked)
  let mut pages := psKernelExprV2PagedEmpty
  for id in [:chunked.size] do
    let entry ← expectV2 (psKernelExprV2ChunkedRequire chunked id)
    let (next,newId) := psKernelExprV2PagedPush pages entry
    unless newId == id do
      throw (IO.userError "PSC1_V2_PAGED_TEST_COPY_ID_MISMATCH")
    pages := next
  expectV2 (psKernelExprV2PagedValidate pages)

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
  let (a13,piNode) ← expectV2
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
    ("two-foralls-ignore-name-and-info",piNode,forallAlpha),
    ("lambda-vs-forall",lam,piNode),
    ("two-lets",letE,letCopy),
    ("let-nondep-different",letE,letDifferent),
    ("two-metadata",mdata,mdataCopy),
    ("two-projections",proj,projCopy),
    ("projection-vs-metadata",proj,mdata)
  ]
  let valid ← expectV2 (psKernelExprV2PortableValidate arena)
  let pages ← psKernelExprV2CopyPagedForTest arena
  for (label,left,right) in pairs do
    let oldLeft ← expectV2 (psKernelExprV2ChunkedDecode valid left)
    let oldRight ← expectV2 (psKernelExprV2ChunkedDecode valid right)
    let expected := psKernelExprEq oldLeft oldRight
    let observed ← expectV2
      (psKernelExprV2PortableEqChecked arena left right)
    requireV2 ("pair-eq-" ++ label) (observed == expected)
    let pagedAnswer ← expectV2
      (psKernelExprV2PagedEqChecked pages left right)
    requireV2 ("paged-pair-eq-" ++ label)
      (pagedAnswer == observed && pagedAnswer == expected)
  requireV2 "pair-eq-invalid-left"
    (match psKernelExprV2PortableEqChecked arena 99999 app with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "pair-eq-invalid-right"
    (match psKernelExprV2PortableEqChecked arena app 99999 with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "paged-pair-eq-invalid-left"
    (match psKernelExprV2PagedEqChecked pages 99999 app with
      | Except.error _ => true | Except.ok _ => false)
  requireV2 "paged-pair-eq-invalid-right"
    (match psKernelExprV2PagedEqChecked pages app 99999 with
      | Except.error _ => true | Except.ok _ => false)
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
  let (forgedPaged,pagedId) := psKernelExprV2PagedPush
    psKernelExprV2PagedEmpty corrupt
  requireV2 "paged-pair-eq-forged-metadata-rejected"
    (match psKernelExprV2PagedEqChecked forgedPaged pagedId pagedId with
      | Except.error _ => true | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_PAGED_PAIR_EQUALITY: PASS cases=16"
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
  let pages ← psKernelExprV2CopyPagedForTest arena
  let pagedEqual ← expectV2 (psKernelExprV2PagedEqChecked pages lhs rhs)
  requireV2 "paged-pair-eq-deep-sharing" (pagedEqual == equal && pagedEqual)
  requireV2 "pair-shared-distinct-ids-structurally-equal"
    (lhs != rhs && equal)
  let different ← expectV2
    (psKernelExprV2PortableEqChecked arena leaf lhs)
  requireV2 "pair-shared-shapes-distinct" (!different)
  IO.println "PSC1_EXPR_V2_PAIR_SHARING: PASS nodes=49 depth=24"


/-
Validated-once equality batch: the memo and its facts are scoped to the
canonical arena and discarded when this operation returns. Results retain
input order, and forged metadata or invalid references reject the batch.
-/
private def testPortableEqualityBatch : IO Unit := do
  let (a0,left) ← expectV2
    (psKernelExprV2ChunkedMkBVar psKernelExprV2ChunkedEmpty 0)
  let (a1,clone) ← expectV2
    (psKernelExprV2ChunkedMkBVar a0 0)
  let (a2,different) ← expectV2
    (psKernelExprV2ChunkedMkBVar a1 1)
  let (a3,app1) ← expectV2
    (psKernelExprV2ChunkedMkApp a2 left left)
  let (arena,app2) ← expectV2
    (psKernelExprV2ChunkedMkApp a3 clone clone)
  let pairs : List (Nat × Nat) := [
    (app1,app2),(left,different),(left,clone),
    (app1,left),(app2,app1)
  ]
  let expected : List Bool := [true,false,true,false,true]
  let observed ← expectV2
    (psKernelExprV2PortableEqBatchChecked arena pairs)
  requireV2 "pair-batch-ordered-results"
    (psKernelExprV2PortableBoolListEq observed expected)
  let pages ← psKernelExprV2CopyPagedForTest arena
  let pagedAnswers ← expectV2
    (psKernelExprV2PagedEqBatchChecked pages pairs)
  requireV2 "paged-pair-batch-ordered-results"
    (psKernelExprV2PortableBoolListEq pagedAnswers expected &&
      psKernelExprV2PortableBoolListEq pagedAnswers observed)
  let emptyResult ← expectV2
    (psKernelExprV2PortableEqBatchChecked arena List.nil)
  requireV2 "pair-batch-empty-input"
    (psKernelExprV2PortableBoolListEq emptyResult List.nil)
  requireV2 "pair-batch-rejects-invalid-node"
    (match psKernelExprV2PortableEqBatchChecked
        arena [(left,999999)] with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "paged-pair-batch-rejects-invalid-node"
    (match psKernelExprV2PagedEqBatchChecked
        pages [(left,999999)] with
      | Except.error _ => true | Except.ok _ => false)
  let rootEntry ← expectV2 (psKernelExprV2ChunkedRequire arena left)
  let forgedEntry : PsKernelExprV2Entry := {
    rootEntry with hasFVar := true
  }
  let (forged,forgedId) := psKernelExprV2ChunkedPush
    psKernelExprV2ChunkedEmpty forgedEntry
  requireV2 "pair-batch-forged-metadata-rejected"
    (match psKernelExprV2PortableEqBatchChecked
        forged [(forgedId,forgedId)] with
      | Except.error _ => true
      | Except.ok _ => false)
  let (forgedPage,pageId) := psKernelExprV2PagedPush
    psKernelExprV2PagedEmpty forgedEntry
  requireV2 "paged-pair-batch-forged-metadata-rejected"
    (match psKernelExprV2PagedEqBatchChecked
        forgedPage [(pageId,pageId)] with
      | Except.error _ => true | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_PAGED_PAIR_BATCH: PASS cases=5"
  let (separate,other) ← expectV2
    (psKernelExprV2ChunkedMkBVar psKernelExprV2ChunkedEmpty 0)
  let (separate,otherDifferent) ← expectV2
    (psKernelExprV2ChunkedMkBVar separate 1)
  let resultsOther ← expectV2
    (psKernelExprV2PortableEqBatchChecked separate
      [(other,otherDifferent)])
  requireV2 "pair-batch-scoped-to-distinct-arena"
    (psKernelExprV2PortableBoolListEq resultsOther [false])
  IO.println "PSC1_EXPR_V2_PAIR_BATCH: PASS cases=5"

private def testPortableEqualityBatchSharing : IO Unit := do
  let (initial,leaf) ← expectV2
    (psKernelExprV2ChunkedMkBVar psKernelExprV2ChunkedEmpty 0)
  let mut arena := initial
  let mut lhs := leaf
  let mut rhs := leaf
  for _ in [:20] do
    let (next,l) ← expectV2
      (psKernelExprV2ChunkedMkApp arena lhs lhs)
    let (next2,r) ← expectV2
      (psKernelExprV2ChunkedMkApp next rhs rhs)
    arena := next2
    lhs := l
    rhs := r
  let mut queries : List (Nat × Nat) := List.nil
  let mut expected : List Bool := List.nil
  for _ in [:16] do
    queries := List.cons (Prod.mk lhs rhs) queries
    expected := List.cons true expected
  let result ← expectV2
    (psKernelExprV2PortableEqBatchChecked arena queries)
  let pages ← psKernelExprV2CopyPagedForTest arena
  let pagedResult ← expectV2
    (psKernelExprV2PagedEqBatchChecked pages queries)
  requireV2 "paged-pair-batch-reuses-shared-comparisons"
    (psKernelExprV2PortableBoolListEq pagedResult expected &&
      psKernelExprV2PortableBoolListEq pagedResult result)
  requireV2 "pair-batch-reuses-shared-comparisons"
    (psKernelExprV2PortableBoolListEq result expected)
  IO.println "PSC1_EXPR_V2_PAIR_BATCH_SHARING: PASS nodes=41 comparisons=16"


/-
M4 interoperability: import existing kernel expressions with a checked
PSC1-portable adapter; decode only in this independent regression and
compare original expression structure, metadata, and structural equality.
-/
private def testPortableLegacyImport : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "legacyImport"
  let sort0 := PsKernelExpr.sort PsKernelLevel.zero
  let bvar0 := PsKernelExpr.bvar 0
  let bvar2 := PsKernelExpr.bvar 2
  let app := PsKernelExpr.app bvar0 bvar2
  let lam := PsKernelExpr.lam name sort0 app PsKernelBinderInfo.default
  let cases : List (String × PsKernelExpr) := [
    ("bvar",bvar2),
    ("fvar",PsKernelExpr.fvar name),
    ("mvar",PsKernelExpr.mvar name),
    ("sort",sort0),
    ("const",PsKernelExpr.const name [PsKernelLevel.zero]),
    ("nat-literal",PsKernelExpr.lit (PsKernelLiteral.nat 42)),
    ("string-literal",PsKernelExpr.lit (PsKernelLiteral.str "v2-import")),
    ("app",app),("lambda",lam),
    ("forall",PsKernelExpr.forallE name sort0 app PsKernelBinderInfo.implicit),
    ("let",PsKernelExpr.letE name sort0 sort0 app false),
    ("mdata",PsKernelExpr.mdata 7 app),
    ("projection",PsKernelExpr.proj name 0 app)
  ]
  for (label,expr) in cases do
    let (arena,root) ← expectV2
      (psKernelExprV2PortableImportChecked expr)
    let actual ← expectV2 (psKernelExprV2ChunkedDecode arena root)
    requireV2 ("legacy-import-roundtrip-" ++ label)
      (psKernelExprEq actual expr && psKernelExprEqual actual expr)
    let (paged,pageRoot) ← expectV2 (psKernelExprV2PagedImportChecked expr)
    let pagedExpr ← psKernelExprV2DecodePagedForTest paged pageRoot
    requireV2 ("paged-import-roundtrip-" ++ label)
      (psKernelExprEq pagedExpr expr && psKernelExprEqual pagedExpr expr)
    let (pagedCopyArena,pageCopy) ← expectV2
      (psKernelExprV2PagedImportIntoChecked paged expr)
    let pagedEqual ← expectV2
      (psKernelExprV2PagedEqChecked pagedCopyArena pageRoot pageCopy)
    requireV2 ("paged-import-cross-copy-" ++ label) pagedEqual
    let (joined,copy) ← expectV2
      (psKernelExprV2PortableImportIntoChecked arena expr)
    let isEqual ← expectV2
      (psKernelExprV2PortableEqChecked joined root copy)
    requireV2 ("legacy-import-cross-copy-" ++ label) isEqual
  let small : PsKernelExpr :=
    PsKernelExpr.app
      (PsKernelExpr.lam name sort0 bvar0 PsKernelBinderInfo.default)
      sort0
  let (arena,beta) ← expectV2 (psKernelExprV2PortableImportChecked small)
  let (resultArena,result) ← expectV2
    (psKernelExprV2PortableHeadMachineChecked 2 arena beta)
  let reduced ← expectV2 (psKernelExprV2ChunkedDecode resultArena result)
  requireV2 "legacy-import-checked-beta-reduction"
    (psKernelExprEq reduced sort0 && psKernelExprEqual reduced sort0)
  let (paged,pagedBeta) ← expectV2 (psKernelExprV2PagedImportChecked small)
  let (pagedOutput,pagedResult) ← expectV2
    (psKernelExprV2PagedHeadMachineChecked 2 paged pagedBeta)
  let pagedReduced ← psKernelExprV2DecodePagedForTest pagedOutput pagedResult
  requireV2 "paged-import-checked-beta"
    (psKernelExprEq pagedReduced sort0 &&
      psKernelExprEqual pagedReduced sort0)
  let entry ← expectV2 (psKernelExprV2ChunkedRequire arena beta)
  let corrupted : PsKernelExprV2Entry := { entry with hash := 0 }
  let (malformed,badRoot) := psKernelExprV2ChunkedPush
    psKernelExprV2ChunkedEmpty corrupted
  requireV2 "legacy-import-refuses-forged-source"
    (match psKernelExprV2PortableImportIntoChecked malformed sort0 with
      | Except.error _ => true
      | Except.ok _ => false)
  let (pagedMalformed,_) := psKernelExprV2PagedPush
    psKernelExprV2PagedEmpty corrupted
  requireV2 "paged-import-refuses-forged-source"
    (match psKernelExprV2PagedImportIntoChecked pagedMalformed sort0 with
      | Except.error _ => true | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_PAGED_LEGACY_IMPORT: PASS cases=13"
  IO.println "PSC1_EXPR_V2_LEGACY_IMPORT: PASS cases=13"


/-
Paged V2 native differential: full ID-index replay, old/middle/new lookups,
snapshot preservation, malformed-layout rejection and forged metadata.
-/
private def testPagedArena : IO Unit := do
  for limit in [0,1,8,32,64] do
    let mut legacy := psKernelExprV2Empty
    let mut paged := psKernelExprV2PagedEmptyWithLimit limit
    for index in [:512] do
      let (next,assigned) := psKernelExprV2MkBVar legacy index
      legacy := next
      let original ← expectV2 (psKernelExprV2Lookup legacy assigned)
      let (nextPaged,pagedId) := psKernelExprV2PagedPush paged original
      unless assigned == pagedId do
        throw (IO.userError "PSC1_V2_PAGED_ID_MISMATCH")
      paged := nextPaged
    requireV2 s!"paged-size-{limit}" (paged.size == legacy.nodes.size)
    let validated ← expectV2 (psKernelExprV2PagedValidate paged)
    requireV2 s!"paged-validation-{limit}"
      (validated.size == paged.size && validated.pageLimit == paged.pageLimit)
    for id in [:512] do
      let original ← expectV2 (psKernelExprV2Lookup legacy id)
      match psKernelExprV2PagedFind paged id with
      | Option.none => throw (IO.userError "PSC1_V2_PAGED_MISSING_NODE")
      | Option.some current =>
          unless psKernelExprV2SameMetadata original current do
            throw (IO.userError "PSC1_V2_PAGED_METADATA_MISMATCH")
    requireV2 s!"paged-out-of-range-{limit}"
      (match psKernelExprV2PagedFind paged 512 with
        | Option.none => true
        | Option.some _ => false)
    let prior := paged
    let first ← expectV2 (psKernelExprV2Lookup legacy 0)
    let (extended,newId) := psKernelExprV2PagedPush paged first
    requireV2 s!"paged-old-snapshot-{limit}"
      (match psKernelExprV2PagedFind prior newId with
        | Option.none => true
        | Option.some _ => false)
    requireV2 s!"paged-new-snapshot-{limit}"
      (match psKernelExprV2PagedFind extended newId with
        | Option.none => false
        | Option.some _ => true)
  let (legacy,id) := psKernelExprV2MkBVar psKernelExprV2Empty 0
  let valid ← expectV2 (psKernelExprV2Lookup legacy id)
  let corrupt : PsKernelExprV2Entry := { valid with hasFVar := true }
  let (forged,forgedId) := psKernelExprV2PagedPush
    psKernelExprV2PagedEmpty corrupt
  requireV2 "paged-forged-metadata-rejected"
    (match psKernelExprV2PagedValidate forged with
      | Except.error _ => true
      | Except.ok _ => false)
  requireV2 "paged-valid-size-not-trust-bypass" (forgedId == 0)
  let invalidNode : PsKernelExprV2Entry := {
    valid with node := PsKernelExprV2Node.app 77 0
  }
  let (forward,_) := psKernelExprV2PagedPush
    psKernelExprV2PagedEmpty invalidNode
  requireV2 "paged-forward-reference-rejected"
    (match psKernelExprV2PagedValidate forward with
      | Except.error _ => true
      | Except.ok _ => false)
  let noCapacity : PsKernelExprV2PagedArena := {
    pages := Array.emptyWithCapacity 0
    active := Array.emptyWithCapacity 0
    size := 0
    pageLimit := 0
  }
  requireV2 "paged-zero-capacity-rejected"
    (match psKernelExprV2PagedValidate noCapacity with
      | Except.error _ => true
      | Except.ok _ => false)
  let incomplete : PsKernelExprV2PagedArena := {
    pages := #[Array.emptyWithCapacity 0]
    active := Array.emptyWithCapacity 0
    size := 64
    pageLimit := 64
  }
  requireV2 "paged-incomplete-completed-page-rejected"
    (match psKernelExprV2PagedValidate incomplete with
      | Except.error _ => true
      | Except.ok _ => false)
  let impossibleSize : PsKernelExprV2PagedArena := {
    pages := Array.emptyWithCapacity 0
    active := Array.emptyWithCapacity 0
    size := 3
    pageLimit := 64
  }
  requireV2 "paged-mismatched-size-rejected"
    (match psKernelExprV2PagedValidate impossibleSize with
      | Except.error _ => true
      | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_PAGED: PASS nodes=512 capacities=5"


/-
A realistic DAG construction and lookup pattern: a deep App spine reuses
one very old leaf while extending a recent head. Both chunked and paged
arenas must compute identical hashes, flags, depths, loose-bvar ranges,
and node IDs. Neither a hash collision nor a fast node lookup grants
admission authority.
-/
private def testPagedSharedAppSpines : IO Unit := do
  let (firstChunk,leafChunk) ← expectV2
    (psKernelExprV2ChunkedMkBVar psKernelExprV2ChunkedEmpty 0)
  let (firstPaged,leafPaged) ← expectV2
    (psKernelExprV2PagedMkBVar psKernelExprV2PagedEmpty 0)
  let mut chunked := firstChunk
  let mut paged := firstPaged
  let mut chunkRoot := leafChunk
  let mut pageRoot := leafPaged
  let count : Nat := 1024
  for _ in [:count] do
    let (nextChunk,idChunk) ← expectV2
      (psKernelExprV2ChunkedMkApp chunked chunkRoot leafChunk)
    let (nextPage,idPage) ← expectV2
      (psKernelExprV2PagedMkApp paged pageRoot leafPaged)
    chunked := nextChunk
    paged := nextPage
    chunkRoot := idChunk
    pageRoot := idPage
    unless chunkRoot == pageRoot do
      throw (IO.userError "PSC1_V2_PAGED_APP_NODE_ID_MISMATCH")
  let validPage ← expectV2 (psKernelExprV2PagedValidate paged)
  let validChunk ← expectV2 (psKernelExprV2PortableValidate chunked)
  let old ← expectV2 (psKernelExprV2ChunkedRequire validChunk chunkRoot)
  let fresh ← expectV2 (psKernelExprV2PagedRequire validPage pageRoot)
  requireV2 "paged-shared-spine-root-metadata"
    (psKernelExprV2SameMetadata old fresh)
  requireV2 "paged-shared-spine-exact-depth" (fresh.depth == count + 1)
  requireV2 "paged-shared-spine-index-range" (fresh.looseRange == 1)
  requireV2 "paged-shared-spine-page-count" (paged.size == count + 1)
  requireV2 "paged-shared-spine-old-leaf-access"
    (match psKernelExprV2PagedFind paged leafPaged with
      | Option.some entry => entry.looseRange == 1
      | Option.none => false)
  IO.println "PSC1_EXPR_V2_PAGED_SPINE: PASS nodes=1025"


/-
Research-only independent materializer to compare a validated paged DAG
against the exact legacy expression oracle. Never use it in the fast path.
-/
private def psKernelExprV2DecodePagedForTest
    (source : PsKernelExprV2PagedArena) (root : Nat) :
    IO PsKernelExpr := do
  let paged ← expectV2 (psKernelExprV2PagedValidate source)
  let mut flat := psKernelExprV2Empty
  for id in [:paged.size] do
    let node ← expectV2 (psKernelExprV2PagedRequire paged id)
    flat := (psKernelExprV2Push flat node).fst
  expectV2 (psKernelExprV2Decode flat root)

private def testPagedLiftDifferential : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "pagedLift"
  let mut c := psKernelExprV2ChunkedEmpty
  let mut p := psKernelExprV2PagedEmpty
  let (c0,b0) ← expectV2 (psKernelExprV2ChunkedMkBVar c 0)
  let (p0,q0) ← expectV2 (psKernelExprV2PagedMkBVar p 0)
  c := c0
  p := p0
  let (c1,b2) ← expectV2 (psKernelExprV2ChunkedMkBVar c 2)
  let (p1,q2) ← expectV2 (psKernelExprV2PagedMkBVar p 2)
  c := c1
  p := p1
  let (c2,sort) ← expectV2 (psKernelExprV2ChunkedMkSort c PsKernelLevel.zero)
  let (p2,pageSort) ← expectV2 (psKernelExprV2PagedMkSort p PsKernelLevel.zero)
  c := c2
  p := p2
  let (c3,app) ← expectV2 (psKernelExprV2ChunkedMkApp c b0 b2)
  let (p3,pageApp) ← expectV2 (psKernelExprV2PagedMkApp p q0 q2)
  c := c3
  p := p3
  let (c4,lam) ← expectV2
    (psKernelExprV2ChunkedMkLam c name sort app PsKernelBinderInfo.default)
  let (p4,pageLam) ← expectV2
    (psKernelExprV2PagedMkLam p name pageSort pageApp PsKernelBinderInfo.default)
  c := c4
  p := p4
  let (c5,piNode) ← expectV2
    (psKernelExprV2ChunkedMkForall c name sort app PsKernelBinderInfo.implicit)
  let (p5,pagePi) ← expectV2
    (psKernelExprV2PagedMkForall p name pageSort pageApp PsKernelBinderInfo.implicit)
  c := c5
  p := p5
  let (c6,letE) ← expectV2
    (psKernelExprV2ChunkedMkLet c name sort app b0 false)
  let (p6,pageLet) ← expectV2
    (psKernelExprV2PagedMkLet p name pageSort pageApp q0 false)
  c := c6
  p := p6
  let (c7,mdata) ← expectV2 (psKernelExprV2ChunkedMkMData c 17 app)
  let (p7,pageMData) ← expectV2 (psKernelExprV2PagedMkMData p 17 pageApp)
  c := c7
  p := p7
  let (c8,proj) ← expectV2 (psKernelExprV2ChunkedMkProj c name 1 mdata)
  let (p8,pageProj) ← expectV2 (psKernelExprV2PagedMkProj p name 1 pageMData)
  c := c8
  p := p8
  let cases : List (String × Nat × Nat) := [
    ("bvar0",b0,q0),("bvar2",b2,q2),("sort",sort,pageSort),
    ("app",app,pageApp),("lambda",lam,pageLam),
    ("forall",piNode,pagePi),("let",letE,pageLet),
    ("metadata",mdata,pageMData),("projection",proj,pageProj)
  ]
  let _ ← expectV2 (psKernelExprV2PortableValidate c)
  let _ ← expectV2 (psKernelExprV2PagedValidate p)
  for (label,cId,pId) in cases do
    let old ← expectV2 (psKernelExprV2ChunkedDecode c cId)
    for cutoff in [0,1,2,3] do
      for amount in [0,1,2] do
        let expected := psKernelExprLiftLooseBVars old cutoff amount
        let (newChunk,chunkId) ← expectV2
          (psKernelExprV2PortableLiftChecked c cId cutoff amount)
        let (newPaged,pageId) ← expectV2
          (psKernelExprV2PagedLiftChecked p pId cutoff amount)
        let slow ← expectV2 (psKernelExprV2ChunkedDecode newChunk chunkId)
        let fast ← psKernelExprV2DecodePagedForTest newPaged pageId
        requireV2 s!"paged-lift-legacy-{label}-{cutoff}-{amount}"
          (psKernelExprEqual fast expected &&
            psKernelExprEq fast expected)
        requireV2 s!"paged-lift-chunked-{label}-{cutoff}-{amount}"
          (psKernelExprEqual fast slow && psKernelExprEq fast slow)
        if amount == 0 then
          requireV2 s!"paged-lift-preserves-zero-{label}"
            (newPaged.size == p.size && pageId == pId)
  requireV2 "paged-lift-invalid-root"
    (match psKernelExprV2PagedLiftChecked p 99999 0 1 with
      | Except.error _ => true
      | Except.ok _ => false)
  let forgedSource ← expectV2 (psKernelExprV2PagedRequire p b0)
  let invalid : PsKernelExprV2Entry := {
    forgedSource with looseRange := 0
  }
  let (forged,forgedId) := psKernelExprV2PagedPush psKernelExprV2PagedEmpty invalid
  requireV2 "paged-lift-forged-metadata-rejected"
    (match psKernelExprV2PagedLiftChecked forged forgedId 0 1 with
      | Except.error _ => true
      | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_PAGED_LIFT: PASS cases=108"


/-
Paged M3 instantiation against existing trusted PsKernelExpr instantiate1
AND the qualified V2 chunked worker. Both reconstructions are independent.
Differential cases cover binder depth, nondep let, projections, metadata,
open replacements, closed replacements, FVars, and repeated shared Apps.
-/
private def testPagedInstantiateDifferential : IO Unit := do
  let n := PsKernelName.str PsKernelName.anonymous "pagedInst"
  let mut chunked := psKernelExprV2ChunkedEmpty
  let mut paged := psKernelExprV2PagedEmpty
  let (c0,b0) ← expectV2 (psKernelExprV2ChunkedMkBVar chunked 0)
  let (p0,q0) ← expectV2 (psKernelExprV2PagedMkBVar paged 0)
  chunked := c0
  paged := p0
  let (c1,b1) ← expectV2 (psKernelExprV2ChunkedMkBVar chunked 1)
  let (p1,q1) ← expectV2 (psKernelExprV2PagedMkBVar paged 1)
  chunked := c1
  paged := p1
  let (c2,b2) ← expectV2 (psKernelExprV2ChunkedMkBVar chunked 2)
  let (p2,q2) ← expectV2 (psKernelExprV2PagedMkBVar paged 2)
  chunked := c2
  paged := p2
  let (c3,sort) ← expectV2
    (psKernelExprV2ChunkedMkSort chunked PsKernelLevel.zero)
  let (p3,pageSort) ← expectV2
    (psKernelExprV2PagedMkSort paged PsKernelLevel.zero)
  chunked := c3
  paged := p3
  let (c4,fv) ← expectV2 (psKernelExprV2ChunkedMkFVar chunked n)
  let (p4,pageFVar) ← expectV2 (psKernelExprV2PagedMkFVar paged n)
  chunked := c4
  paged := p4
  let (c5,app) ← expectV2 (psKernelExprV2ChunkedMkApp chunked b0 b2)
  let (p5,pageApp) ← expectV2 (psKernelExprV2PagedMkApp paged q0 q2)
  chunked := c5
  paged := p5
  let (c6,lam) ← expectV2
    (psKernelExprV2ChunkedMkLam chunked n sort app PsKernelBinderInfo.default)
  let (p6,pageLam) ← expectV2
    (psKernelExprV2PagedMkLam paged n pageSort pageApp PsKernelBinderInfo.default)
  chunked := c6
  paged := p6
  let (c7,piNode) ← expectV2
    (psKernelExprV2ChunkedMkForall chunked n b2 app PsKernelBinderInfo.implicit)
  let (p7,pagePi) ← expectV2
    (psKernelExprV2PagedMkForall paged n q2 pageApp PsKernelBinderInfo.implicit)
  chunked := c7
  paged := p7
  let (c8,letE) ← expectV2
    (psKernelExprV2ChunkedMkLet chunked n b2 app b1 false)
  let (p8,pageLet) ← expectV2
    (psKernelExprV2PagedMkLet paged n q2 pageApp q1 false)
  chunked := c8
  paged := p8
  let (c9,mdata) ← expectV2 (psKernelExprV2ChunkedMkMData chunked 9 app)
  let (p9,pageMData) ← expectV2 (psKernelExprV2PagedMkMData paged 9 pageApp)
  chunked := c9
  paged := p9
  let (c10,proj) ← expectV2
    (psKernelExprV2ChunkedMkProj chunked n 1 mdata)
  let (p10,pageProj) ← expectV2
    (psKernelExprV2PagedMkProj paged n 1 pageMData)
  chunked := c10
  paged := p10
  let (c11,shared) ← expectV2 (psKernelExprV2ChunkedMkApp chunked app app)
  let (p11,pageShared) ← expectV2 (psKernelExprV2PagedMkApp paged pageApp pageApp)
  chunked := c11
  paged := p11
  let cases : List (String × Nat × Nat) := [
    ("bvar0",b0,q0),("bvar1",b1,q1),("bvar2",b2,q2),
    ("sort",sort,pageSort),("fvar",fv,pageFVar),
    ("app",app,pageApp),("lambda",lam,pageLam),
    ("forall",piNode,pagePi),("let",letE,pageLet),
    ("mdata",mdata,pageMData),("projection",proj,pageProj),
    ("shared-app",shared,pageShared)
  ]
  let replacements : List (String × Nat × Nat) := [
    ("sort",sort,pageSort),("bvar2",b2,q2),
    ("open-app",app,pageApp),("fvar",fv,pageFVar)
  ]
  let _ ← expectV2 (psKernelExprV2PagedValidate paged)
  for (label,chunkId,pageId) in cases do
    let old ← expectV2 (psKernelExprV2ChunkedDecode chunked chunkId)
    for (replLabel,chunkRepl,pageRepl) in replacements do
      let oldRepl ← expectV2 (psKernelExprV2ChunkedDecode chunked chunkRepl)
      let expected := psKernelExprInstantiate1 old oldRepl
      let (chunkOut,chunkRoot) ← expectV2
        (psKernelExprV2PortableInstantiate1Checked chunked chunkId chunkRepl)
      let (pageOut,pageRoot) ← expectV2
        (psKernelExprV2PagedInstantiate1Checked paged pageId pageRepl)
      let chunkExpr ← expectV2 (psKernelExprV2ChunkedDecode chunkOut chunkRoot)
      let pageExpr ← psKernelExprV2DecodePagedForTest pageOut pageRoot
      requireV2 s!"paged-inst-legacy-{label}-{replLabel}"
        (psKernelExprEqual pageExpr expected &&
          psKernelExprEq pageExpr expected)
      requireV2 s!"paged-inst-chunked-{label}-{replLabel}"
        (psKernelExprEqual pageExpr chunkExpr &&
          psKernelExprEq pageExpr chunkExpr)
  requireV2 "paged-inst-invalid-root"
    (match psKernelExprV2PagedInstantiate1Checked paged 9999 pageSort with
      | Except.error _ => true | Except.ok _ => false)
  requireV2 "paged-inst-invalid-replacement"
    (match psKernelExprV2PagedInstantiate1Checked paged pageApp 9999 with
      | Except.error _ => true | Except.ok _ => false)
  let valid ← expectV2 (psKernelExprV2PagedRequire paged q0)
  let fake : PsKernelExprV2Entry := { valid with looseRange := 0 }
  let (forged,root) := psKernelExprV2PagedPush psKernelExprV2PagedEmpty fake
  requireV2 "paged-inst-forged-loose-range"
    (match psKernelExprV2PagedInstantiate1Checked forged root root with
      | Except.error _ => true | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_PAGED_INSTANTIATE: PASS cases=48"

private def testPagedHeadMachine : IO Unit := do
  let n := PsKernelName.str PsKernelName.anonymous "pagedHead"
  let (c0,b0) ← expectV2
    (psKernelExprV2ChunkedMkBVar psKernelExprV2ChunkedEmpty 0)
  let (p0,q0) ← expectV2
    (psKernelExprV2PagedMkBVar psKernelExprV2PagedEmpty 0)
  let (c1,sort) ← expectV2
    (psKernelExprV2ChunkedMkSort c0 PsKernelLevel.zero)
  let (p1,pageSort) ← expectV2
    (psKernelExprV2PagedMkSort p0 PsKernelLevel.zero)
  let (c2,lam) ← expectV2
    (psKernelExprV2ChunkedMkLam c1 n sort b0 PsKernelBinderInfo.default)
  let (p2,pageLam) ← expectV2
    (psKernelExprV2PagedMkLam p1 n pageSort q0 PsKernelBinderInfo.default)
  let (c3,beta) ← expectV2
    (psKernelExprV2ChunkedMkApp c2 lam sort)
  let (p3,pageBeta) ← expectV2
    (psKernelExprV2PagedMkApp p2 pageLam pageSort)
  let (c4,metadata) ← expectV2
    (psKernelExprV2ChunkedMkMData c3 17 beta)
  let (p4,pageMetadata) ← expectV2
    (psKernelExprV2PagedMkMData p3 17 pageBeta)
  let (c5,outerLet) ← expectV2
    (psKernelExprV2ChunkedMkLet c4 n sort sort metadata false)
  let (p5,pageOuterLet) ← expectV2
    (psKernelExprV2PagedMkLet p4 n pageSort pageSort pageMetadata false)
  let (chunkOut,chunkRoot) ← expectV2
    (psKernelExprV2PortableHeadMachineChecked 4 c5 outerLet)
  let (pageOut,pageRoot) ← expectV2
    (psKernelExprV2PagedHeadMachineChecked 4 p5 pageOuterLet)
  let chunkExpr ← expectV2 (psKernelExprV2ChunkedDecode chunkOut chunkRoot)
  let pageExpr ← psKernelExprV2DecodePagedForTest pageOut pageRoot
  requireV2 "paged-head-beta-zeta-mdata-equal"
    (psKernelExprEqual chunkExpr pageExpr &&
      psKernelExprEq pageExpr (PsKernelExpr.sort PsKernelLevel.zero))
  requireV2 "paged-head-step-budget-enforced"
    (match psKernelExprV2PagedHeadMachineChecked 3 p5 pageOuterLet with
      | Except.error _ => true | Except.ok _ => false)
  requireV2 "paged-head-invalid-root"
    (match psKernelExprV2PagedHeadMachineChecked 4 p5 99999 with
      | Except.error _ => true | Except.ok _ => false)
  let valid ← expectV2 (psKernelExprV2PagedRequire p5 pageOuterLet)
  let falseEntry : PsKernelExprV2Entry := {
    valid with hasFVar := true
  }
  let (bad,badRoot) := psKernelExprV2PagedPush
    psKernelExprV2PagedEmpty falseEntry
  requireV2 "paged-head-forged-metadata-rejected"
    (match psKernelExprV2PagedHeadMachineChecked 4 bad badRoot with
      | Except.error _ => true | Except.ok _ => false)
  for depth in [1,8,24,48] do
    let mut old := c1
    let mut fresh := p1
    let mut oldRoot := sort
    let mut freshRoot := pageSort
    for _ in [:depth] do
      let (next,idx) ← expectV2
        (psKernelExprV2ChunkedMkLet old n sort sort oldRoot false)
      let (newPage,pageIdx) ← expectV2
        (psKernelExprV2PagedMkLet fresh n pageSort pageSort freshRoot false)
      old := next
      fresh := newPage
      oldRoot := idx
      freshRoot := pageIdx
    let (oldOutput,oldResult) ← expectV2
      (psKernelExprV2PortableHeadMachineChecked (depth+1) old oldRoot)
    let (newOutput,newResult) ← expectV2
      (psKernelExprV2PagedHeadMachineChecked (depth+1) fresh freshRoot)
    requireV2 s!"paged-head-depth-{depth}-identical-result"
      (oldResult == sort && newResult == pageSort &&
        oldOutput.size == old.size && newOutput.size == fresh.size)
    requireV2 s!"paged-head-depth-{depth}-insufficient-budget"
      (match psKernelExprV2PagedHeadMachineChecked depth fresh freshRoot with
        | Except.error _ => true | Except.ok _ => false)
  IO.println "PSC1_EXPR_V2_PAGED_HEAD: PASS depths=1,8,24,48"

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
  testPagedSmartConstructors
  testPagedArena
  testPagedSharedAppSpines
  testPagedLiftDifferential
  testPagedInstantiateDifferential
  testPagedHeadMachine
  testChunkedLiftDifferential
  testSharedLift
  testPortableInstantiation
  testPortableSharedInstantiation
  testPortableHeadReduction
  testPortableHeadSequence
  testHeadMachineDeep
  testPortablePairEquality
  testPortablePairSharing
  testPortableEqualityBatch
  testPortableEqualityBatchSharing
  testPortableLegacyImport
  IO.println "PSC1_EXPR_V2_REGRESSION: PASS"
