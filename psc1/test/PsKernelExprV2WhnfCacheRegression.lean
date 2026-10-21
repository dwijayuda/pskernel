import Ps.KernelCore.API.Dag
import Ps.KernelCore.Checker.ExprV2.Knot
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- Raw cache rows below test exact internal scanner behavior, including malformed
   rows. They never authorize admission. Public fixtures use checked declarations;
   callback markers have hashes outside the kernel modulus. -/
private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_V2_INDEXED_CACHE_FAIL " ++ label))

private def expect {a : Type} : Except String a -> IO a
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {a : Type} : Except PsKernelError a -> IO a
  | .ok value => pure value
  | .error _ => throw (IO.userError "indexed cache checked fixture failed")

private def attempt {a : Type} (label : String) : Option (Except String a) -> IO a
  | some value => expect value
  | none => throw (IO.userError ("indexed cache unexpected fallback: " ++ label))

private def sameFind (left right : Except String (Option Nat)) : Bool :=
  match left, right with
  | .ok a, .ok b => a == b
  | .error a, .error b => a == b
  | _, _ => false

private def indexed (cache : PsKernelExprV2WhnfCache) : Bool :=
  cache.index.isSome && cache.small.isEmpty

private def nm (name : String) := PsKernelName.str .anonymous name
private def level : Nat -> PsKernelLevel
  | 0 => .zero
  | n + 1 => .succ (level n)
private def officialLevel : Nat -> Lean.Level
  | 0 => .zero
  | n + 1 => .succ (officialLevel n)

private def errorIs {a : Type} (label expected : String)
    (actual : Option (Except String a)) : IO Unit := do
  match actual with
  | some (.error error) => require label (error == expected)
  | _ => throw (IO.userError ("indexed cache expected error: " ++ label))

/- Frozen 5de radix routines below are executable native references only.
   The production workers are separately proved equal for every input. -/
private def radixReferenceBucket
    (levels : Nat) :
    PsKernelExprV2WhnfCacheIndex -> Nat -> List PsKernelExprV2WhnfCacheEntry :=
  match levels with
  | Nat.zero =>
      fun (index : PsKernelExprV2WhnfCacheIndex) (_hash : Nat) =>
        match index with
        | PsKernelExprV2WhnfCacheIndex.bucket entries => entries
        | _ => List.nil
  | Nat.succ remaining =>
      fun (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat) =>
        match index with
        | PsKernelExprV2WhnfCacheIndex.branch left right =>
            let worker := radixReferenceBucket remaining;
            if Nat.beq (Nat.mod hash 2) 0 then worker left (Nat.div hash 2)
            else worker right (Nat.div hash 2)
        | _ => List.nil

private def radixReferenceSet
    (levels : Nat) :
    PsKernelExprV2WhnfCacheIndex -> Nat -> List PsKernelExprV2WhnfCacheEntry ->
    PsKernelExprV2WhnfCacheIndex :=
  match levels with
  | Nat.zero =>
      fun (_index : PsKernelExprV2WhnfCacheIndex) (_hash : Nat)
          (entries : List PsKernelExprV2WhnfCacheEntry) =>
        PsKernelExprV2WhnfCacheIndex.bucket entries
  | Nat.succ remaining =>
      fun (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat)
          (entries : List PsKernelExprV2WhnfCacheEntry) =>
        let left : PsKernelExprV2WhnfCacheIndex :=
          match index with
          | PsKernelExprV2WhnfCacheIndex.branch value _ => value
          | _ => PsKernelExprV2WhnfCacheIndex.empty;
        let right : PsKernelExprV2WhnfCacheIndex :=
          match index with
          | PsKernelExprV2WhnfCacheIndex.branch _ value => value
          | _ => PsKernelExprV2WhnfCacheIndex.empty;
        let worker := radixReferenceSet remaining;
        if Nat.beq (Nat.mod hash 2) 0 then
          PsKernelExprV2WhnfCacheIndex.branch
            (worker left (Nat.div hash 2) entries) right
        else
          PsKernelExprV2WhnfCacheIndex.branch
            left (worker right (Nat.div hash 2) entries)


private def sameCacheRows : List PsKernelExprV2WhnfCacheEntry ->
    List PsKernelExprV2WhnfCacheEntry -> Bool
  | [], [] => true
  | a :: restA, b :: restB =>
      a.source == b.source && a.result == b.result && a.hash == b.hash &&
        sameCacheRows restA restB
  | _, _ => false

private def sameCacheIndex : PsKernelExprV2WhnfCacheIndex ->
    PsKernelExprV2WhnfCacheIndex -> Bool
  | .empty, .empty => true
  | .bucket a, .bucket b => sameCacheRows a b
  | .branch a b, .branch c d => sameCacheIndex a c && sameCacheIndex b d
  | _, _ => false

private def radixWorkers : IO Unit := do
  let first := PsKernelExprV2WhnfCacheEntry.mk 1 11 23
  let aliasEntry := PsKernelExprV2WhnfCacheEntry.mk 2 22 65559
  let large := PsKernelExprV2WhnfCacheEntry.mk
    1000000000000000000000000000001 33 1000000000000000000000000000023
  let rows := [first,aliasEntry,first,large]
  let reversed := rows.reverse
  let deep := radixReferenceSet 16
    (radixReferenceSet 16 .empty 23 rows) 1 reversed
  let deeper := radixReferenceSet 17 deep 65559 [large,first,large]
  let indices : List PsKernelExprV2WhnfCacheIndex := [
    .empty, .bucket rows, .branch .empty .empty,
    .branch (.bucket rows) .empty, .branch .empty (.bucket reversed),
    .branch (.branch (.bucket [large]) .empty) (.bucket rows),
    deep, deeper]
  let hashes : List Nat := [
    0,1,2,23,65535,65536,65559,1000000000000000000000000000023]
  let rowSets := [[],rows,[large,first,large]]
  let mut lookups := 0
  let mut updates := 0
  for levels in [0,1,2,8,16,17] do
    let bucket := psKernelExprV2WhnfCacheIndexBucket levels
    let setter := psKernelExprV2WhnfCacheIndexSet levels
    for index in indices do
      let bucketAt := bucket index
      let setterAt := setter index
      for hash in hashes do
        let expected := radixReferenceBucket levels index hash
        require "radix-flat-bucket-exact"
          (sameCacheRows expected (psKernelExprV2WhnfCacheIndexBucketWorker levels index hash))
        require "radix-staged-bucket-reuse" (sameCacheRows expected (bucketAt hash))
        lookups := lookups + 1
        let setRows := setterAt hash
        for replacement in rowSets do
          let expectedIndex := radixReferenceSet levels index hash replacement
          require "radix-flat-set-exact"
            (sameCacheIndex expectedIndex
              (psKernelExprV2WhnfCacheIndexSetWorker levels index hash replacement))
          require "radix-staged-set-reuse"
            (sameCacheIndex expectedIndex (setRows replacement))
          updates := updates + 1
  let replaced := psKernelExprV2WhnfCacheIndexSetWorker 16 deep 23 []
  require "radix-old-snapshot-retains-duplicate-publication"
    (sameCacheRows rows (psKernelExprV2WhnfCacheIndexBucketWorker 16 deep 23))
  require "radix-high-hash-route-keeps-full-records"
    (sameCacheRows rows (psKernelExprV2WhnfCacheIndexBucketWorker 16 deep 65559))
  require "radix-set-replaces-selected-bucket"
    (sameCacheRows [] (psKernelExprV2WhnfCacheIndexBucketWorker 16 replaced 23))
  require "radix-set-preserves-other-branch"
    (sameCacheRows reversed (psKernelExprV2WhnfCacheIndexBucketWorker 16 replaced 1))
  let inserted := psKernelExprV2WhnfCacheIndexInsert deep first
  require "radix-insert-retains-every-newest-first-record"
    (sameCacheRows (first :: rows)
      (psKernelExprV2WhnfCacheIndexBucketWorker 16 inserted 23))
  require "radix-set-zero-replaces-malformed-branch"
    (sameCacheIndex (.bucket [large])
      (psKernelExprV2WhnfCacheIndexSetWorker 0 deep 65559 [large]))
  require "radix-bucket-zero-keeps-raw-list"
    (sameCacheRows [large,first,large]
      (psKernelExprV2WhnfCacheIndexBucketWorker 0 (.bucket [large,first,large]) 0))
  require "radix-matrix-counts" (lookups == 384 && updates == 1152)
  IO.println "PSC1_V2_INDEXED_CACHE_RADIX_PASS lookups=384 updates=1152 levels=6 shapes=8"

private def rawMatrix : IO Unit := do
  let leftExpr := PsKernelExpr.letE (nm "x") (.sort (level 1))
    (.sort (level 0)) (.bvar 0) false
  let equalExpr := PsKernelExpr.letE (nm "y") (.sort (level 1))
    (.sort (level 0)) (.bvar 0) false
  let rightExpr := PsKernelExpr.letE (nm "x") (.sort (level 2))
    (.sort (level 1)) (.bvar 0) false
  let (arena,left) <- expect (psKernelExprV2PagedImportChecked leftExpr)
  let (arena,equal) <- expect (psKernelExprV2PagedImportIntoChecked arena equalExpr)
  let (arena,right) <- expect (psKernelExprV2PagedImportIntoChecked arena rightExpr)
  let missing := arena.size + 5
  require "distinct-alpha-equal-source-ids"
    (left != equal && (← expect (psKernelExprV2PagedEqOnCanonical arena left equal)))
  let mut comparisons := 0
  for size in [0,1,7,8,9,16,64,128] do
    for pattern in [0,1,2,3] do
      let mut rows : List PsKernelExprV2WhnfCacheEntry := []
      let mut incremental := psKernelExprV2WhnfCacheEmpty
      for i in [:size] do
        let hash := if pattern == 0 then 1000 + i else
          if pattern == 1 then 23 else
          if pattern == 2 then 23 + 65536 * i else
          if i % 3 == 0 then 23 else 1000 + i
        let source := if i % 5 == 0 then left else
          if i % 5 == 1 then right else if i % 5 == 2 then equal else
          if i % 5 == 3 then missing else left
        let entry := PsKernelExprV2WhnfCacheEntry.mk source
          (if i % 2 == 0 then left else right) hash
        rows := entry :: rows
        incremental := psKernelExprV2WhnfCacheInsert incremental entry
      let built := psKernelExprV2WhnfCacheFromList rows
      require "promotion-boundary-from-list" (built.index.isSome == (size > 8))
      require "promotion-boundary-incremental" (incremental.index.isSome == (size > 8))
      require "promotion-drops-flat-mirror" (size <= 8 || (indexed built && indexed incremental))
      require "publication-count-preserved"
        ((psKernelExprV2WhnfCacheEntries built).length == size &&
          (psKernelExprV2WhnfCacheEntries incremental).length == size)
      for source in [left,right,equal,missing] do
        for hash in [23,24,1000,1001,1000 + size,23 + 65536,
            23 + 65536 * size,1000000000000000000000000000023] do
          let original := psKernelExprV2WhnfCacheFindWorker rows arena source hash
          require "original-curried-scanner"
            (sameFind original (psKernelExprV2WhnfCacheFindIn rows arena source hash))
          require "from-list-exact-result"
            (sameFind original (psKernelExprV2WhnfCacheLookup built arena source hash))
          require "incremental-exact-result"
            (sameFind original (psKernelExprV2WhnfCacheLookup incremental arena source hash))
          comparisons := comparisons + 1
  let filler := (List.range 8).map fun i =>
    PsKernelExprV2WhnfCacheEntry.mk missing right (100000 + i)
  let row := fun source result hash => PsKernelExprV2WhnfCacheEntry.mk source result hash
  let badLeft : Except String (Option Nat) :=
    .error "PSKERNEL_V2_PAIR_CHECK_INVALID_LEFT"
  let badRight : Except String (Option Nat) :=
    .error "PSKERNEL_V2_PAIR_CHECK_INVALID_RIGHT"
  let cases : List (String × List PsKernelExprV2WhnfCacheEntry × Nat ×
      Except String (Option Nat)) := [
    ("latest-duplicate-wins",[row left right 23,row left left 23],left,.ok (some right)),
    ("first-error-before-later-hit",[row missing right 23,row left left 23],left,badLeft),
    ("first-hit-before-older-error",[row left left 23,row missing right 23],left,.ok (some left)),
    ("equal-hash-needs-exact-equality",[row right right 23],left,.ok none),
    ("full-hash-alias-skips-invalid-node",[row missing right 65559,row left left 23],left,.ok (some left)),
    ("invalid-query-still-errors",[row left right 23],missing,badRight),
    ("mismatched-hash-does-not-require-node",[row missing right 24],missing,.ok none)]
  for (label,head,query,expected) in cases do
    let rows := head ++ filler
    let cache := psKernelExprV2WhnfCacheFromList rows
    require (label ++ "-actually-indexed") (indexed cache)
    require label (sameFind expected (psKernelExprV2WhnfCacheLookup cache arena query 23))
    require (label ++ "-old-scanner")
      (sameFind expected (psKernelExprV2WhnfCacheFindWorker rows arena query 23))
  let old := psKernelExprV2WhnfCacheFromList (row left left 23 :: filler)
  let next := psKernelExprV2WhnfCacheInsert old (row left right 23)
  require "old-snapshot-unmodified"
    (sameFind (.ok (some left)) (psKernelExprV2WhnfCacheLookup old arena left 23))
  require "new-snapshot-newest-result"
    (sameFind (.ok (some right)) (psKernelExprV2WhnfCacheLookup next arena left 23))
  require "raw-matrix-count" (comparisons == 1024)
  IO.println "PSC1_V2_INDEXED_CACHE_RAW_PASS comparisons=1024 adversarial=7 snapshots=2"

private def caches (state : PsKernelExprV2CheckState) : List PsKernelExprV2WhnfCache :=
  [state.whnf.coreCache,state.whnf.publicCache,state.checkedInfer,state.inferOnly,state.unfold]

private def compareResult (label : String)
    (original : Except String (PsKernelExpr × PsKernelCheckerState))
    (actual : Option (Except String (PsKernelExprV2CheckState × Nat))) : IO Unit := do
  match original,actual with
  | .error a,some (.error b) => require (label ++ "-exact-error") (a == b)
  | .ok a,some (.ok b) =>
      let decoded <- expect (psKernelExprV2DecodeChecked b.fst.whnf.arena)
      let expression <- expect (psKernelExprV2DecodedRequire decoded b.snd)
      require (label ++ "-expression") (psKernelExprEqual a.fst expression)
      require (label ++ "-fresh-counter") (a.snd.nextFresh == b.fst.nextFresh)
  | _,_ => throw (IO.userError ("indexed cache reference mismatch: " ++ label))

private structure Fixture where
  root : Nat
  letRoot : Nat
  type : Nat
  value : Nat
  term : PsKernelExpr
  letTerm : PsKernelExpr

private structure WarmFixture where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  parent : PsKernelExprV2CheckState
  original : PsKernelCheckerState
  chosen : Fixture

private def warmOwners : IO WarmFixture := do
  let empty <- expectPublic
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let mut originalSession := empty
  let mut arena := psKernelExprV2PagedEmpty
  let mut fixtures : List Fixture := []
  let mut requests : List PsKernelDagDeclarationRequest := []
  Lean.initSearchPath (← Lean.findSysroot)
  let mut official <- Lean.importModules #[{ module := .str .anonymous "Init" }] {}
  for i in [:9] do
    let text := "IndexedCacheAlias" ++ toString i
    let name := nm text
    let type := PsKernelExpr.sort (level (i + 1))
    let value := PsKernelExpr.sort (level i)
    let term := PsKernelExpr.const name []
    let letTerm := PsKernelExpr.letE (nm "x") type value (.bvar 0) false
    let (a,t) <- expect (psKernelExprV2PagedImportIntoChecked arena type)
    let (a,v) <- expect (psKernelExprV2PagedImportIntoChecked a value)
    let (a,r) <- expect (psKernelExprV2PagedImportIntoChecked a term)
    let (a,l) <- expect (psKernelExprV2PagedImportIntoChecked a letTerm)
    arena := a
    fixtures := fixtures ++ [Fixture.mk r l t v term letTerm]
    requests := requests ++ [.definitionDecl
      (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk name [] t) v .abbrevHint .safe)]
    let old <- expectPublic (psKernelV1AdmitDeclaration originalSession (.definitionDecl
      (PsKernelDefinitionInfo.mk (PsKernelConstantBase.mk name [] type) value .abbrevHint .safe)))
    originalSession := old.session
    match official.addDeclCore 0 0
        (.defnDecl {
          name := .str .anonymous text, levelParams := [],
          type := .sort (officialLevel (i + 1)), value := .sort (officialLevel i),
          hints := .abbrev, safety := .safe }) none true with
    | .ok next => official := next
    | .error _ => throw (IO.userError "official indexed cache fixture refused")
  let canonical <- expect (psKernelExprV2PagedValidate arena)
  let built <- expect (psKernelExprV2DecodeChecked canonical)
  let batch <- expectPublic
    (psKernelV1RunDag empty [] .safe canonical (requests.map PsKernelDagCommand.admit))
  require "public-batch-nine-real-admissions" (batch.replies.length == 9 &&
    psKernelEnvironmentSize batch.session.environment == 9 &&
    psKernelEnvironmentSize originalSession.environment == 9)
  let mut execution := PsKernelDagExecutionState.mk empty []
  for request in requests do
    let result <- expectPublic
      (psKernelDagRunCommand execution [] .safe canonical built (.admit request))
    execution := result.snd
  let some first := fixtures.head? | throw (IO.userError "missing first cache fixture")
  let badName := nm "IndexedCacheBad"
  let badRequest := PsKernelDagDeclarationRequest.definitionDecl
    (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk badName [] first.value)
      first.value .abbrevHint .safe)
  require "public-batch-invalid-refused"
    (match psKernelV1RunDag empty [] .safe canonical [.admit badRequest] with
     | .error (.rejectedInvalid _) => true | _ => false)
  require "reference-invalid-refused"
    (match psKernelV1AdmitDeclaration empty (.definitionDecl
      (PsKernelDefinitionInfo.mk (PsKernelConstantBase.mk badName [] (.sort .zero))
        (.sort .zero) .abbrevHint .safe)) with
     | .error (.rejectedInvalid _) => true | _ => false)
  require "official-invalid-refused"
    (match official.addDeclCore 0 0 (.defnDecl {
      name := .str .anonymous "IndexedCacheBad", levelParams := [],
      type := .sort .zero, value := .sort .zero, hints := .abbrev, safety := .safe })
        none true with | .error _ => true | .ok _ => false)
  require "fresh-public-operation-cannot-import-owner"
    (match psKernelV1RunDag empty [] .safe canonical [.check first.root] with
     | .error (.rejectedInvalid _) => true | _ => false)
  let scalar := (psKernelKernelSessionChecker execution.session [] .safe).context
  let context := psKernelExprV2CheckContextEmpty scalar
  let mut state := psKernelExprV2CheckStateWithWhnf
    (psKernelExprV2CheckStateEmpty canonical)
    (psKernelExprV2WhnfStateForDeclarations canonical execution.declarations)
  let mut original := psKernelCheckerStateEmpty
  let mut parent := state
  let mut count := 0
  for fixture in fixtures do
    if count == 8 then parent := state
    let oldCheck <- expect (psKernelCheckerCheck 64 scalar original fixture.term)
    let checked <- attempt "warm-checked"
      (psKernelExprV2TryCheckStateWithFuel 64 context state fixture.root)
    compareResult "warm-checked" (.ok oldCheck) (some (.ok checked))
    let oldInfer <- expect (psKernelCheckerInfer 64 scalar oldCheck.snd fixture.term)
    let inferred <- attempt "warm-infer-only"
      (psKernelExprV2TryInferStateWithFuel 64 context checked.fst fixture.root)
    compareResult "warm-infer-only" (.ok oldInfer) (some (.ok inferred))
    let oldCore <- expect (psKernelWhnfCoreWithRecursorFuel 64 (psKernelIsDefEqWithFuel 64)
      scalar oldInfer.snd fixture.letTerm false false)
    let core <- attempt "warm-core" (psKernelExprV2CheckWhnfCoreOwnedWithFuel 64
      (psKernelExprV2TryDefEqStateWithFuel 64) context inferred.fst fixture.letRoot false)
    compareResult "warm-core" (.ok oldCore) (some (.ok core))
    let oldPublic <- expect (psKernelWhnfWithRecursorFuel 64 (psKernelIsDefEqWithFuel 64)
      scalar oldCore.snd fixture.letTerm)
    let reduced <- attempt "warm-public" (psKernelExprV2CheckWhnfOwnedWithFuel 64
      (psKernelExprV2TryDefEqStateWithFuel 64) context core.fst fixture.letRoot)
    compareResult "warm-public" (.ok oldPublic) (some (.ok reduced))
    let unfolded <- attempt "warm-unfold"
      (psKernelExprV2DefEqUnfold context reduced.fst fixture.root)
    let some value := unfolded.snd | throw (IO.userError "indexed owner did not unfold")
    require "real-unfold-body"
      (← expect (psKernelExprV2PagedEqOnCanonical unfolded.fst.whnf.arena value fixture.value))
    state := unfolded.fst
    original := oldPublic.snd
    count := count + 1
  require "all-five-real-caches-promoted" ((caches state).all indexed)
  require "all-five-eight-entry-parents-still-small"
    ((caches parent).all (fun cache => cache.index.isNone && cache.small.length == 8))
  require "all-five-nine-entry-publications"
    ((caches state).all (fun cache => (psKernelExprV2WhnfCacheEntries cache).length == 9))
  let some chosen := fixtures.getLast? | throw (IO.userError "missing final cache fixture")
  require "published-fuel-unchanged" (psKernelResourcePolicyDefault.fuel == 4096)
  IO.println "PSC1_V2_INDEXED_CACHE_REAL_PASS officialPositive=9 officialNegative=1 publicPositive=9 publicNegative=1 caches=5 entries=9"
  pure (WarmFixture.mk context state parent original chosen)

private def resourceOwners (fixture : WarmFixture) : IO Unit := do
  let warm := fixture.state
  let chosen := fixture.chosen
  let mut comparisons := 0
  for fuel in [0,1,64] do
    for depth in [0,15,16] do
      let scalar := { fixture.context.scalar with maxRecDepth := 1, recDepth := depth }
      let context := psKernelExprV2CheckContextEmpty scalar
      compareResult "indexed-checked-guards"
        (psKernelCheckerCheck fuel scalar fixture.original chosen.term)
        (psKernelExprV2TryCheckStateWithFuel fuel context warm chosen.root)
      compareResult "indexed-infer-only-guards"
        (psKernelCheckerInfer fuel scalar fixture.original chosen.term)
        (psKernelExprV2TryInferStateWithFuel fuel context warm chosen.root)
      compareResult "indexed-core-guards"
        (psKernelWhnfCoreWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel)
          scalar fixture.original chosen.letTerm false false)
        (psKernelExprV2CheckWhnfCoreOwnedWithFuel fuel (psKernelExprV2TryDefEqStateWithFuel fuel)
          context warm chosen.letRoot false)
      compareResult "indexed-public-guards"
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel)
          scalar fixture.original chosen.letTerm)
        (psKernelExprV2CheckWhnfOwnedWithFuel fuel (psKernelExprV2TryDefEqStateWithFuel fuel)
          context warm chosen.letRoot)
      comparisons := comparisons + 4
  let arena := warm.whnf.arena
  let missing := arena.size + 999
  let missingError <- match psKernelExprV2PagedRequire arena missing with
    | .error error => pure error
    | .ok _ => throw (IO.userError "missing indexed cache fixture existed")
  let aliasEntry <- expect (psKernelExprV2PagedRequire arena chosen.root)
  let letEntry <- expect (psKernelExprV2PagedRequire arena chosen.letRoot)
  let poison := fun cache hash => psKernelExprV2WhnfCacheInsert cache
    (PsKernelExprV2WhnfCacheEntry.mk missing chosen.value hash)
  let poisoned : PsKernelExprV2CheckState := {
    warm with
    whnf := { warm.whnf with
      coreCache := poison warm.whnf.coreCache letEntry.hash
      publicCache := poison warm.whnf.publicCache letEntry.hash }
    checkedInfer := poison warm.checkedInfer aliasEntry.hash
    inferOnly := poison warm.inferOnly aliasEntry.hash
    unfold := poison warm.unfold aliasEntry.hash }
  require "all-poison-controls-use-index" ((caches poisoned).all indexed)
  let exhausted := { fixture.context with scalar := {
    fixture.context.scalar with maxRecDepth := 1, recDepth := psKernelRecDepthFactor } }
  let defeq := psKernelExprV2TryDefEqStateWithFuel 64
  let whnf := fun c s r => psKernelExprV2CheckWhnfOwnedWithFuel 64 defeq c s r
  let depthError := "deep recursion detected, use maxRecDepth to increase the limit"
  let pairError := "PSKERNEL_V2_PAIR_CHECK_INVALID_LEFT"
  for mode in [false,true] do
    errorIs "indexed-inference-zero-before-source" "kernel inference budget exhausted"
      (psKernelExprV2TryInferCoreOwnedWithFuel 0 whnf defeq exhausted poisoned missing mode)
    errorIs "indexed-inference-cache-error-before-depth" pairError
      (psKernelExprV2TryInferCoreOwnedWithFuel 64 whnf defeq exhausted poisoned chosen.root mode)
    errorIs "indexed-inference-source-error-before-cache-and-depth" missingError
      (psKernelExprV2TryInferCoreOwnedWithFuel 64 whnf defeq exhausted poisoned missing mode)
  errorIs "indexed-core-zero-before-source" "kernel reduction budget exhausted"
    (psKernelExprV2CheckWhnfCoreOwnedWithFuel 0 defeq exhausted poisoned missing false)
  errorIs "indexed-core-depth-before-cache" depthError
    (psKernelExprV2CheckWhnfCoreOwnedWithFuel 64 defeq exhausted poisoned chosen.letRoot false)
  errorIs "indexed-core-depth-before-source" depthError
    (psKernelExprV2CheckWhnfCoreOwnedWithFuel 64 defeq exhausted poisoned missing false)
  errorIs "indexed-core-reports-cache-error" pairError
    (psKernelExprV2CheckWhnfCoreOwnedWithFuel 64 defeq fixture.context poisoned chosen.letRoot false)
  errorIs "indexed-core-reports-source-error" missingError
    (psKernelExprV2CheckWhnfCoreOwnedWithFuel 64 defeq fixture.context poisoned missing false)
  errorIs "indexed-public-zero-before-source" "kernel reduction budget exhausted"
    (psKernelExprV2CheckWhnfOwnedWithFuel 0 defeq exhausted poisoned missing)
  errorIs "indexed-public-existing-cache-order" pairError
    (psKernelExprV2CheckWhnfOwnedWithFuel 64 defeq exhausted poisoned chosen.letRoot)
  errorIs "indexed-public-source-before-cache" missingError
    (psKernelExprV2CheckWhnfOwnedWithFuel 64 defeq exhausted poisoned missing)
  errorIs "indexed-unfold-reports-cache-error" pairError
    (psKernelExprV2DefEqUnfold fixture.context poisoned chosen.root)
  errorIs "indexed-unfold-source-before-cache" missingError
    (psKernelExprV2DefEqUnfold fixture.context poisoned missing)
  let cheap <- attempt "indexed-cheap-cache-hit"
    (psKernelExprV2CheckWhnfCoreOwnedWithFuel 1 defeq fixture.context warm chosen.letRoot true)
  require "indexed-cheap-hit-does-not-publish"
    ((psKernelExprV2WhnfCacheEntries cheap.fst.whnf.coreCache).length == 9 &&
      (psKernelExprV2WhnfCacheEntries cheap.fst.whnf.publicCache).length == 9)
  let (childArena,_) <- expect (psKernelExprV2PagedMkLit arena (.nat 987654))
  let child := (psKernelExprV2CheckStateFreshName
    (psKernelExprV2CheckStateWithArena warm childArena) (nm "indexed")).snd
  let restored := psKernelExprV2CheckStateExitLocalScope fixture.parent child
  require "indexed-scope-restores-eight-entry-parents"
    ((caches restored).all (fun cache => cache.index.isNone && cache.small.length == 8))
  require "indexed-scope-retains-child-arena-and-fresh"
    (restored.whnf.arena.size == childArena.size && restored.nextFresh == child.nextFresh)
  for (before,after,root) in [
      (warm.whnf.coreCache,restored.whnf.coreCache,chosen.letRoot),
      (warm.whnf.publicCache,restored.whnf.publicCache,chosen.letRoot),
      (warm.checkedInfer,restored.checkedInfer,chosen.root),
      (warm.inferOnly,restored.inferOnly,chosen.root),
      (warm.unfold,restored.unfold,chosen.root)] do
    let entry <- expect (psKernelExprV2PagedRequire childArena root)
    require "indexed-child-publication-exists"
      (← expect (psKernelExprV2WhnfCacheLookup before childArena root entry.hash)).isSome
    require "indexed-child-publication-does-not-escape-scope"
      (sameFind (.ok none) (psKernelExprV2WhnfCacheLookup after childArena root entry.hash))
  let fresh := psKernelExprV2CheckStateEmpty childArena
  require "fresh-owner-all-five-empty"
    ((caches fresh).all (fun cache => cache.index.isNone && cache.small.isEmpty))
  require "resource-matrix-count" (comparisons == 36)
  IO.println "PSC1_V2_INDEXED_CACHE_RESOURCE_PASS reference=36 precedence=16 scope=5"

private def markerHash (tag index : Nat) := psKernelCacheHashModulus + 1000 + 16 * tag + index

private def markerCache (arena : PsKernelExprV2PagedArena)
    (cache : PsKernelExprV2WhnfCache) (key tag : Nat) : Bool :=
  indexed cache && (psKernelExprV2WhnfCacheEntries cache).length == 9 &&
    (psKernelExprV2WhnfCacheEntries cache).all (fun row => row.source == key) &&
    (List.range 9).all (fun i =>
      match psKernelExprV2WhnfCacheLookup cache arena key (markerHash tag i) with
      | .ok (some value) =>
          match psKernelExprV2PagedRequire arena value with
          | .ok entry =>
              match entry.node with
              | .lit (.nat n) => n == 9000 + tag
              | _ => false
          | .error _ => false
      | _ => false)

private def pairMarker (pairs : List PsKernelExprV2DefEqPair) (key tag : Nat) : Bool :=
  match pairs with
  | [pair] => pair.left == key && pair.right == key && pair.hash == markerHash tag 0
  | _ => false

private def marked (state : PsKernelExprV2CheckState) (key tag fresh : Nat) : Bool :=
  state.nextFresh == fresh &&
    (caches state).all (fun cache => markerCache state.whnf.arena cache key tag) &&
    pairMarker state.success key tag && pairMarker state.failure key tag &&
    (psKernelExprV2DeclarationRefFind state.whnf.declarations (nm "IndexedCacheAlias8")).isSome

private def stamp (state : PsKernelExprV2CheckState) (key tag : Nat) :
    Except String PsKernelExprV2CheckState := do
  let (arena,value) <- psKernelExprV2PagedMkLit state.whnf.arena (.nat (9000 + tag))
  let cache := psKernelExprV2WhnfCacheFromList ((List.range 9).map fun i =>
    PsKernelExprV2WhnfCacheEntry.mk key value (markerHash tag i))
  let pairs := [PsKernelExprV2DefEqPair.mk key key (markerHash tag 0)]
  pure (PsKernelExprV2CheckState.mk
    (PsKernelExprV2WhnfState.mk arena cache cache state.whnf.declarations)
    tag cache pairs cache cache pairs)

private def markedCallback (key input output tag failAt : Nat) (decline : Bool)
    (_context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  if root != input || !(marked state key tag tag) then
    some (.error "INDEXED_CALLBACK_STALE_STATE")
  else if failAt == tag + 1 then
    if decline then none else some (.error "INDEXED_CALLBACK_INJECTED")
  else some ((stamp state key (tag + 1)).map fun next => (next,output))

private def callbackOwners (fixture : WarmFixture) : IO Unit := do
  let key := fixture.chosen.root
  let (arena,prop) <- expect (psKernelExprV2PagedMkSort fixture.state.whnf.arena .zero)
  let initial <- expect (stamp (psKernelExprV2CheckStateWithArena fixture.state arena) key 20)
  require "all-five-callback-inputs-indexed" (marked initial key 20 20)
  let mut callbacks := 0
  for helper in [psKernelExprV2DefEqIsPropOwnedWith,psKernelExprV2CheckProjectionIsPropOwnedWith] do
    for (failAt,decline) in [(0,false),(21,false),(21,true),(22,false),(22,true)] do
      let result := helper
        (markedCallback key key prop 20 failAt decline)
        (markedCallback key prop prop 21 failAt decline)
        fixture.context initial key
      if failAt == 0 then
        let reduced <- attempt "indexed-callback-chain" result
        require "all-five-callback-outputs-indexed" (marked reduced.fst key 22 22 && reduced.snd)
      else if decline then require "indexed-callback-decline-propagates" result.isNone
      else errorIs "indexed-callback-error-propagates" "INDEXED_CALLBACK_INJECTED" result
      callbacks := callbacks + 1
  let child <- expect (stamp initial key 21)
  let restored := psKernelExprV2CheckStateExitLocalScope initial child
  require "indexed-parent-restored-from-indexed-child" (marked restored key 20 21)
  require "indexed-parent-snapshot-unchanged" (marked initial key 20 20)
  require "indexed-child-snapshot-unchanged" (marked child key 21 21)
  let lifted <- attempt "indexed-compatibility-lift"
    (psKernelExprV2LiftWhnfAttempt initial (some (.ok (child.whnf,prop))))
  require "indexed-lift-uses-returned-whnf"
    (markerCache lifted.fst.whnf.arena lifted.fst.whnf.coreCache key 21 &&
      markerCache lifted.fst.whnf.arena lifted.fst.whnf.publicCache key 21)
  require "indexed-lift-preserves-three-other-cache-owners"
    ([lifted.fst.checkedInfer,lifted.fst.inferOnly,lifted.fst.unfold].all
      (fun cache => markerCache lifted.fst.whnf.arena cache key 20) &&
      lifted.fst.nextFresh == 20 && pairMarker lifted.fst.success key 20 &&
      pairMarker lifted.fst.failure key 20)
  require "callback-matrix-count" (callbacks == 10)
  IO.println "PSC1_V2_INDEXED_CACHE_CALLBACK_PASS cases=10 caches=5 entries=9"

def main : IO Unit := do
  radixWorkers
  rawMatrix
  let fixture <- warmOwners
  resourceOwners fixture
  callbackOwners fixture
  IO.println "PSC1_V2_INDEXED_CACHE_PASS"
