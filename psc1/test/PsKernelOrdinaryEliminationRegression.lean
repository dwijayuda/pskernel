import Ps.KernelCore.API.DagOrdinaryElimination
import Ps.KernelCore.API.DagOrdinaryHeader
import Ps.KernelCore.Admission.Inductive.Ordinary.ConstructorAdmission
import Ps.KernelCore.Core.ExprV2.Decode
import Ps.KernelCore.Research.ExprV2PagedImport

/- Private elimination-policy qualification. Policy fixtures first pass the
   frozen V1 header and constructor phase, including final inductive flags.
   Raw WHNF-spine probes and fabricated callback owners are separate helper
   compatibility controls; they establish no constructor admission. No
   generated recursor or public atomic publication is claimed. -/

private def require (counter : IO.Ref Nat) (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_ELIMINATION_NATIVE_FAIL " ++ label))
  counter.modify (fun n => n + 1)
  IO.println ("PSC1_ELIMINATION_ASSERT " ++ label)

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def direct {α : Type} : Option (Except String α) → IO α
  | some (.ok value) => pure value
  | some (.error error) => throw (IO.userError error)
  | none => throw (IO.userError "unexpected private elimination decline")

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ .zero
private def s0 := PsKernelExpr.sort .zero
private def s1 := PsKernelExpr.sort one
private def target := nm "ElimT"
private def ctorName (index : Nat) := nm ("ElimT.c" ++ toString index)
private def t := PsKernelExpr.const target []
private def ti (index : PsKernelExpr) := PsKernelExpr.app t index
private def all (name : String) (domain body : PsKernelExpr)
    (info : PsKernelBinderInfo := .default) :=
  PsKernelExpr.forallE (nm name) domain body info
private def indexedHeader := all "A" s1 s0
private def indexedCtor := all "A" s1 (ti (.bvar 0))
private def parameterHeader := all "P" s0 s0 .implicit
private def parameterCtor :=
  all "P" s0 (all "p" (.bvar 0) (ti (.bvar 1))) .implicit

private structure PolicyCase where
  label : String
  header : PsKernelExpr
  numParams : Nat
  ctors : List PsKernelExpr
  expected : Bool

private def policyCases : List PolicyCase :=
  [ ⟨"nonprop-fast",s1,0,[all "P" s0 t],false⟩,
    ⟨"prop-empty",s0,0,[],false⟩,
    ⟨"prop-multiple",s0,0,[t,t],true⟩,
    ⟨"prop-empty-ctor",s0,0,[t],false⟩,
    ⟨"proof-field",s0,0,[all "p" t t],false⟩,
    ⟨"proposition-field",s0,0,[all "P" s0 t],true⟩,
    ⟨"indexed-exact",indexedHeader,0,[indexedCtor],false⟩,
    ⟨"indexed-beta",indexedHeader,0,
      [all "A" s1 (ti (.app (.lam (nm "Z") s1 (.bvar 0) .default) (.bvar 0)))],true⟩,
    ⟨"parameter-proof",parameterHeader,1,[parameterCtor],false⟩ ]

private structure Fixture where
  oldSession : PsKernelCheckerSession
  oldParams : List PsKernelOpenBinder
  oldCtors : List PsKernelSimpleConstructorDecl
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  params : List PsKernelExprV2OrdinaryOpenBinder
  resultLevel : PsKernelLevel
  dagCtors : List PsKernelDagConstructor

private def prepare (row : PolicyCase) : IO Fixture := do
  let (headerArena,headerId) ← expect
    (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty row.header)
  let mut sourceArena := headerArena
  let mut dagCtors : List PsKernelDagConstructor := []
  let mut oldCtors : List PsKernelSimpleConstructorDecl := []
  let mut index := 0
  for ctorType in row.ctors do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked sourceArena ctorType)
    sourceArena := next
    dagCtors := dagCtors ++ [⟨ctorName index,root⟩]
    oldCtors := oldCtors ++ [⟨ctorName index,ctorType⟩]
    index := index + 1
  let initial := psKernelMkCheckerSession psKernelEnvironmentEmpty [] .safe 0 psKernelLeanNatMaxSizeDefault
  let checked ← expect (psKernelSessionCheck 4096 initial row.header)
  let sorted ← expect (psKernelSessionEnsureSort 4096 checked.snd checked.fst)
  let oldParams ← expect (psKernelOpenSimpleHeaderParams 4096 sorted.snd row.header row.numParams)
  let oldIndices ← expect (psKernelOpenSimpleHeaderIndices 4096 oldParams.session oldParams.result)
  let resultLevel ← match oldIndices.result with
    | .sort level => pure level
    | _ => throw (IO.userError "V1 elimination header result is not a sort")
  let analysis ← direct (psKernelExprV2OrdinaryAnalyzeHeaderWithFuel 4096 psKernelEnvironmentEmpty
    0 psKernelLeanNatMaxSizeDefault sourceArena [] [] row.numParams ⟨target,headerId,[]⟩ false)
  let numIndices := analysis.indices.binders.length
  unless psKernelLevelEq resultLevel analysis.resultLevel && numIndices == oldIndices.binders.length do
    throw (IO.userError "elimination header universe or index arity mismatch")
  let info := PsKernelInductiveInfo.mk ⟨target,[],row.header⟩ row.numParams numIndices
    [target] (oldCtors.map (fun ctor => ctor.name)) 0 false false false
  let work0 := psKernelEnvironmentAddUnchecked psKernelEnvironmentEmpty (.inductInfo info)
  let decl := PsKernelSimpleInductiveDecl.mk [] target row.header oldCtors false row.numParams
  -- This is the real frozen closed-type/constructor checker, not a shape stub.
  let admitted ← expect (psKernelAddSimpleConstructorsWithFuel 4097 decl .safe resultLevel []
    oldParams.binders numIndices oldParams.session work0 0 oldCtors)
  let finalInfo := PsKernelInductiveInfo.mk info.base info.numParams info.numIndices
    info.all info.ctors info.numNested (psKernelSimpleHasRecursiveFields admitted.shapes)
    (psKernelSimpleHasReflexiveFields admitted.shapes) info.isUnsafe
  let work1 := psKernelEnvironmentReplaceUnchecked admitted.environment (.inductInfo finalInfo)
  let parent := psKernelExprV2OrdinaryConstructorState analysis
  let ctx := psKernelExprV2OrdinaryConstructorContext analysis
  let context := PsKernelExprV2CheckContext.mk (psKernelCheckerContextWithEnvironment ctx.scalar work1) ctx.locals
  let reference := PsKernelExprV2DeclarationRef.mk target [] headerId none .inductiveDecl
  let refs := dagCtors.foldl
    (fun refs ctor => PsKernelExprV2DeclarationRef.mk ctor.name [] ctor.type none .constructorDecl :: refs)
    (reference :: parent.whnf.declarations)
  let state := psKernelExprV2CheckStateWithWhnf parent
    ⟨parent.whnf.arena,parent.whnf.coreCache,parent.whnf.publicCache,refs⟩
  pure ⟨psKernelSessionWithEnvironment oldParams.session work1,oldParams.binders,oldCtors,
    context,state,analysis.parameters.binders,resultLevel,dagCtors⟩

private def resultEq (old : Except String Bool)
    (actual : Option (Except String Bool)) : Bool :=
  match old,actual with
  | .ok left,some (.ok right) => left == right
  | .error left,some (.error right) => left == right
  | _,_ => false

private def boolIs (expected : Bool) : Option (Except String Bool) → Bool
  | some (.ok actual) => expected == actual
  | _ => false

private def policyMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  unless policyCases.length == 9 do throw (IO.userError "elimination policy row inventory")
  for row in policyCases do
    let fixture ← prepare row
    for fuel in [0,1,2,3,8,4096] do
      let old := psKernelSimpleElimOnlyAtZero fuel fixture.oldSession
        fixture.oldParams fixture.resultLevel fixture.oldCtors
      let actual := psKernelExprV2OrdinaryElimOnlyAtZeroWithFuel fuel fixture.context
        fixture.state fixture.params fixture.resultLevel fixture.dagCtors
      require counter ("policy/" ++ row.label ++ "/fuel=" ++ toString fuel) (resultEq old actual)
    require counter ("policy/" ++ row.label ++ "/required-outcome")
      (boolIs row.expected (psKernelExprV2OrdinaryElimOnlyAtZeroWithFuel 4096 fixture.context
        fixture.state fixture.params fixture.resultLevel fixture.dagCtors))
  unless (← counter.get) - before == 63 do throw (IO.userError "elimination policy assertion inventory")
  IO.println "PSC1_ELIMINATION_SECTION policy=63"

private def rawCases : List (String × PsKernelExpr) :=
  [ ("plain",indexedCtor),
    ("metadata",.mdata "outer" indexedCtor),
    ("let",.letE (nm "unused") s1 s0 indexedCtor true),
    ("beta",.app (.lam (nm "unused") s1 indexedCtor .default) s0) ]

private def rawMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  let fixture ← prepare ⟨"raw-owner",indexedHeader,0,[indexedCtor],false⟩
  for (label,type) in rawCases do
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked fixture.state.whnf.arena type)
    let state := psKernelExprV2CheckStateWithArena fixture.state arena
    for fuel in [0,1,2,3,8,4096] do
      let old := psKernelSimpleCtorAllowsLargeElimWithFuel fuel fixture.oldSession type []
      let actual := psKernelExprV2OrdinaryCtorAllowsLargeElimWorker fuel
        psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
        fixture.context state root []
      require counter ("raw/" ++ label ++ "/fuel=" ++ toString fuel) (resultEq old actual)
    require counter ("raw/" ++ label ++ "/required-outcome")
      (boolIs true (psKernelExprV2OrdinaryCtorAllowsLargeElimWorker 4096
        psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
        fixture.context state root []))
  unless (← counter.get) - before == 28 do throw (IO.userError "elimination raw assertion inventory")
  IO.println "PSC1_ELIMINATION_SECTION raw=28"

private def memberIs (expected : Bool) : Except String Bool → Bool
  | .ok actual => expected == actual
  | _ => false

private def memberErrorIs (expected : String) : Except String Bool → Bool
  | .error actual => expected == actual
  | _ => false

private def memberPair (counter : IO.Ref Nat) (label : String)
    (left right : PsKernelExpr) (expected : Bool) (distinct : Bool := false) : IO Unit := do
  let (arena0,a) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty left)
  let (arena,b) ← expect (psKernelExprV2PagedImportIntoChecked arena0 right)
  require counter ("member/" ++ label)
    (psKernelSimpleExprMember left [right] == expected &&
      memberIs expected (psKernelExprV2OrdinaryEliminationMember arena a [b]) &&
      (!distinct || a != b))

private def memberMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  let (arena0,a) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty s0)
  let (arena,b) ← expect (psKernelExprV2PagedImportIntoChecked arena0 s1)
  let bad := arena.size + 100
  require counter "member/shared-ID"
    (psKernelSimpleExprMember s0 [s0] &&
      memberIs true (psKernelExprV2OrdinaryEliminationMember arena a [a]))
  memberPair counter "duplicate-ID" s0 s0 true true
  memberPair counter "renamed-forall-info"
    (all "x" s0 (.bvar 0)) (all "y" s0 (.bvar 0) .implicit) true
  memberPair counter "renamed-lam-info"
    (.lam (nm "x") s0 (.bvar 0) .default) (.lam (nm "y") s0 (.bvar 0) .instImplicit) true
  memberPair counter "renamed-let"
    (.letE (nm "x") s1 s0 (.bvar 0) false) (.letE (nm "y") s1 s0 (.bvar 0) false) true
  memberPair counter "let-nondep"
    (.letE (nm "x") s1 s0 (.bvar 0) false) (.letE (nm "x") s1 s0 (.bvar 0) true) false
  memberPair counter "mdata-tags" (.mdata "left" s0) (.mdata "right" s0) false
  memberPair counter "beta-syntax" (.app (.lam (nm "x") s1 (.bvar 0) .default) s0) s0 false
  require counter "member/nil-boundaries"
    (!psKernelSimpleExprMember s0 [] && psKernelSimpleAllExprsMember [] [s0] &&
      memberIs false (psKernelExprV2OrdinaryEliminationMember arena bad []) &&
      memberIs true (psKernelExprV2OrdinaryEliminationAllMembers arena [] [bad]))
  require counter "member/repeated-all"
    (psKernelSimpleAllExprsMember [s0,s1,s0] [s1,s0] &&
      memberIs true (psKernelExprV2OrdinaryEliminationAllMembers arena [a,b,a] [b,a]))
  require counter "member/missing-all"
    (!psKernelSimpleAllExprsMember [s0,s1] [s0] &&
      memberIs false (psKernelExprV2OrdinaryEliminationAllMembers arena [a,b] [a]))
  require counter "member/invalid-short-circuit"
    (memberIs true (psKernelExprV2OrdinaryEliminationMember arena a [a,bad]) &&
      memberErrorIs "PSKERNEL_V2_PAIR_CHECK_INVALID_LEFT"
        (psKernelExprV2OrdinaryEliminationMember arena bad [a]) &&
      memberErrorIs "PSKERNEL_V2_PAIR_CHECK_INVALID_RIGHT"
        (psKernelExprV2OrdinaryEliminationMember arena a [bad]))
  unless (← counter.get) - before == 12 do throw (IO.userError "elimination member assertion inventory")
  IO.println "PSC1_ELIMINATION_SECTION member=12"

private def sameList {α β : Type} (same : α → β → Bool) : List α → List β → Bool
  | [],[] => true
  | a :: rest,b :: tail => same a b && sameList same rest tail
  | _,_ => false

private def referencesEq (left right : List PsKernelExprV2DeclarationRef) : Bool :=
  sameList (fun a b => psKernelNameEq a.name b.name &&
    psKernelNameListsEq a.levelParams b.levelParams && a.type == b.type &&
    a.deltaValue == b.deltaValue &&
    (match a.kind,b.kind with
    | .inductiveDecl,.inductiveDecl => true
    | .constructorDecl,.constructorDecl => true
    | _,_ => false))
    left right

private def sameNode : PsKernelExprV2Node → PsKernelExprV2Node → Bool
  | .bvar a,.bvar b => a == b
  | .fvar a,.fvar b => psKernelNameEq a b
  | .mvar a,.mvar b => psKernelNameEq a b
  | .sort a,.sort b => psKernelLevelEq a b
  | .const a us,.const b vs => psKernelNameEq a b && psKernelLevelListEq us vs
  | .app a b,.app c d => a == c && b == d
  | .lam a b c i,.lam d e f j =>
      psKernelNameEq a d && b == e && c == f && psKernelBinderInfoEq i j
  | .forallE a b c i,.forallE d e f j =>
      psKernelNameEq a d && b == e && c == f && psKernelBinderInfoEq i j
  | .letE a b c d n,.letE e f g h m =>
      psKernelNameEq a e && b == f && c == g && d == h && n == m
  | .lit a,.lit b => psKernelExprEqual (.lit a) (.lit b)
  | .mdata a b,.mdata c d => a == c && b == d
  | .proj a b c,.proj d e f => psKernelNameEq a d && b == e && c == f
  | _,_ => false

private def arenaPrefix (before after : PsKernelExprV2PagedArena) : Bool :=
  Nat.ble before.size after.size && before.pageLimit == after.pageLimit &&
    (List.range before.size).all (fun id =>
      match psKernelExprV2PagedFind before id,psKernelExprV2PagedFind after id with
      | some left,some right => sameNode left.node right.node &&
          psKernelExprV2PortableSameMetadata left right
      | _,_ => false)


private def cacheEq (left right : List PsKernelExprV2WhnfCacheEntry) : Bool :=
  sameList (fun a b => a.source == b.source && a.result == b.result && a.hash == b.hash) left right

private def pairsEq (left right : List PsKernelExprV2DefEqPair) : Bool :=
  sameList (fun a b => a.left == b.left && a.right == b.right && a.hash == b.hash) left right

private def semanticEq (left right : PsKernelExprV2CheckState) : Bool :=
  left.nextFresh == right.nextFresh &&
    cacheEq left.whnf.coreCache right.whnf.coreCache &&
    cacheEq left.whnf.publicCache right.whnf.publicCache &&
    cacheEq left.checkedInfer right.checkedInfer && pairsEq left.success right.success &&
    cacheEq left.inferOnly right.inferOnly && cacheEq left.unfold right.unfold &&
    pairsEq left.failure right.failure

private def stateEq (left right : PsKernelExprV2CheckState) : Bool :=
  semanticEq left right && referencesEq left.whnf.declarations right.whnf.declarations &&
    left.whnf.arena.size == right.whnf.arena.size && arenaPrefix left.whnf.arena right.whnf.arena

private def inductiveEq (left right : PsKernelInductiveInfo) : Bool :=
  psKernelNameEq left.base.name right.base.name &&
    psKernelNameListsEq left.base.levelParams right.base.levelParams &&
    psKernelExprEqual left.base.type right.base.type &&
    left.numParams == right.numParams && left.numIndices == right.numIndices &&
    psKernelNameListsEq left.all right.all && psKernelNameListsEq left.ctors right.ctors &&
    left.numNested == right.numNested && left.isRec == right.isRec &&
    left.isReflexive == right.isReflexive && left.isUnsafe == right.isUnsafe

private def constantEq (left right : PsKernelConstantInfo) : Bool :=
  match left,right with
  | .inductInfo a,.inductInfo b => inductiveEq a b
  | .ctorInfo a,.ctorInfo b =>
      psKernelNameEq a.base.name b.base.name &&
      psKernelNameListsEq a.base.levelParams b.base.levelParams &&
      psKernelExprEqual a.base.type b.base.type &&
      psKernelNameEq a.induct b.induct && a.cidx == b.cidx &&
      a.numParams == b.numParams && a.numFields == b.numFields && a.isUnsafe == b.isUnsafe
  | _,_ => false

private def environmentEq (left right : PsKernelEnvironment) : Bool :=
  left.quotInitialized == right.quotInitialized &&
    left.runtime.nativeEvaluator.isNone && right.runtime.nativeEvaluator.isNone &&
    sameList constantEq left.constants right.constants &&
    left.constants.all (fun original =>
      match psKernelEnvironmentFind left (psKernelConstantInfoName original),
          psKernelEnvironmentFind right (psKernelConstantInfoName original) with
      | some a,some b => constantEq original a && constantEq original b
      | _,_ => false)

private def contextSettingsEq (left right : PsKernelExprV2CheckContext) : Bool :=
  sameList (fun a b => psKernelNameEq a.name b.name && psKernelNameEq a.userName b.userName &&
    a.type == b.type && psKernelBinderInfoEq a.binderInfo b.binderInfo && a.value == b.value)
    left.locals right.locals &&
    left.scalar.localContext.decls.isEmpty && right.scalar.localContext.decls.isEmpty &&
    left.scalar.localContext.nextIndex == right.scalar.localContext.nextIndex &&
    psKernelNameListsEq left.scalar.levelParams right.scalar.levelParams &&
    psKernelSafetyEq left.scalar.safety right.scalar.safety &&
    left.scalar.eagerReduce == right.scalar.eagerReduce &&
    left.scalar.nativeEvaluator.isNone && right.scalar.nativeEvaluator.isNone &&
    left.scalar.maxRecDepth == right.scalar.maxRecDepth &&
    left.scalar.maxNatSize == right.scalar.maxNatSize && left.scalar.recDepth == right.scalar.recDepth

private def contextEq (left right : PsKernelExprV2CheckContext) : Bool :=
  contextSettingsEq left right && environmentEq left.scalar.environment right.scalar.environment

/- Distinct protocol-only markers exercise all seven semantic collections.
   They are never supplied to the real checker or published as judgments. -/
private def stamp (state : PsKernelExprV2CheckState) (fresh source result : Nat)
    (references : List PsKernelExprV2DeclarationRef) : PsKernelExprV2CheckState :=
  ⟨⟨state.whnf.arena,[⟨source,result,fresh+1⟩],[⟨source,result,fresh+2⟩],references⟩,
    fresh,[⟨source,result,fresh+3⟩],[⟨source,result,fresh+4⟩],
    [⟨source,result,fresh+5⟩],[⟨source,result,fresh+6⟩],[⟨source,result,fresh+7⟩]⟩


private abbrev Callback :=
  Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
    Option (Except String (PsKernelExprV2CheckState × Nat))

private abbrev DefEqCallback :=
  Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →
    Option (Except String (PsKernelExprV2CheckState × Bool))

private def decline : Callback := fun _ _ _ _ => none
private def fail (message : String) : Callback := fun _ _ _ _ => some (.error message)
private def forbidden : Callback := fail "UNEXPECTED_ELIMINATION_CALLBACK"
private def defeqForbidden : DefEqCallback :=
  fun _ _ _ _ _ => some (.error "UNEXPECTED_ELIMINATION_DEFEQ")
private def same : Callback := fun _ _ state root => some (.ok (state,root))

private def errorIs {α : Type} (message : String) : Option (Except String α) → Bool
  | some (.error got) => message == got
  | _ => false

private def decodedEq (built : PsKernelExprV2Decoded) (expected : PsKernelExpr) (root : Nat) : Bool :=
  match psKernelExprV2DecodedRequire built root with
  | .ok got => psKernelExprEqual expected got
  | .error _ => false

private def protocolMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  let fixture ← prepare ⟨"protocol-owner",indexedHeader,0,[indexedCtor],false⟩
  let (sortArena,sortId) ← expect (psKernelExprV2PagedImportIntoChecked fixture.state.whnf.arena s1)
  let (targetArena,targetId) ← expect (psKernelExprV2PagedImportIntoChecked sortArena t)
  let originalDomain := PsKernelExpr.app (.const psKernelTypeAnnotationOutParamName []) s1
  let originalBody := ti (.bvar 0)
  let (domainArena,domainId) ← expect (psKernelExprV2PagedImportIntoChecked targetArena originalDomain)
  let (bodyArena,bodyId) ← expect (psKernelExprV2PagedImportIntoChecked domainArena originalBody)
  let user := nm "field"
  let (arena,forallId) ← expect (psKernelExprV2PagedMkForall bodyArena user domainId bodyId .implicit)
  let context := fixture.context
  let parent := stamp (psKernelExprV2CheckStateWithArena fixture.state arena)
    37 sortId targetId fixture.state.whnf.declarations
  let bad := arena.size + 100
  let badCtor := PsKernelDagConstructor.mk (nm "invalid-root") bad
  let policy := psKernelExprV2OrdinaryElimOnlyAtZeroWith
    forbidden forbidden defeqForbidden 0 context parent []
  require counter "protocol/policy-shortcuts"
    (boolIs false (policy one [badCtor]) && boolIs false (policy .zero []) &&
      boolIs true (policy .zero [badCtor,badCtor]))
  require counter "protocol/zero-before-callback"
    (errorIs "simple inductive elimination budget exhausted"
      (psKernelExprV2OrdinaryCtorAllowsLargeElimWorker 0 forbidden forbidden context parent bad [bad]))
  require counter "protocol/whnf-decline"
    ((psKernelExprV2OrdinaryCtorAllowsLargeElimWorker 8 forbidden decline context parent bad []).isNone)
  require counter "protocol/whnf-error-before-invalid-root"
    (errorIs "WHNF_SENTINEL" (psKernelExprV2OrdinaryCtorAllowsLargeElimWorker
      8 forbidden (fail "WHNF_SENTINEL") context parent bad []))
  require counter "protocol/check-decline-before-sort"
    ((psKernelExprV2OrdinaryEliminationStepWith decline forbidden
      7 context parent user domainId bodyId .implicit []).isNone)
  require counter "protocol/check-error-before-sort"
    (errorIs "CHECK_SENTINEL" (psKernelExprV2OrdinaryEliminationStepWith
      (fail "CHECK_SENTINEL") forbidden 7 context parent user domainId bodyId .implicit []))
  let checkSort : Callback := fun _ _ state _ => some (.ok (state,sortId))
  require counter "protocol/sort-decline"
    ((psKernelExprV2OrdinaryEliminationStepWith checkSort decline
      7 context parent user domainId bodyId .implicit []).isNone)
  require counter "protocol/sort-error"
    (errorIs "SORT_SENTINEL" (psKernelExprV2OrdinaryEliminationStepWith checkSort
      (fail "SORT_SENTINEL") 7 context parent user domainId bodyId .implicit []))
  let nonSort : Callback := fun _ _ state _ => some (.ok (state,targetId))
  require counter "protocol/sort-nonsort"
    (errorIs "expected sort" (psKernelExprV2OrdinaryEliminationStepWith checkSort
      nonSort 7 context parent user domainId bodyId .implicit []))
  let parameterFixture ← prepare ⟨"protocol-parameter",parameterHeader,1,[parameterCtor],false⟩
  let parameterRoot ← match parameterFixture.dagCtors with
    | [ctor] => pure ctor.type
    | _ => throw (IO.userError "one parameter protocol constructor required")
  let withParameter := fun (defeq : DefEqCallback) =>
    psKernelExprV2OrdinaryCtorAllowsLargeElimWith forbidden forbidden defeq 8
      parameterFixture.context parameterFixture.state parameterFixture.params parameterRoot
  require counter "protocol/parameter-failures"
    ((withParameter (fun _ _ _ _ _ => none)).isNone &&
      errorIs "DEFEQ_SENTINEL" (withParameter (fun _ _ _ _ _ => some (.error "DEFEQ_SENTINEL"))) &&
      errorIs "simple inductive constructor parameter does not match the datatype parameter"
        (withParameter (fun _ _ state _ _ => some (.ok (state,false)))))
  -- Append distinct checked/sorted roots and change every semantic collection.
  -- No synthetic cache below is passed to a real checker.
  let (checkedArena,checkedType) ← expect (psKernelExprV2PagedMkSort parent.whnf.arena one)
  let checkedRef := PsKernelExprV2DeclarationRef.mk (nm "protocol-check") [] checkedType none .constructorDecl
  let checked := stamp (psKernelExprV2CheckStateWithArena parent checkedArena)
    101 domainId checkedType [checkedRef]
  let (sortedArena0,sortedType) ← expect (psKernelExprV2PagedMkSort checked.whnf.arena one)
  let (sortedArena,propType) ← expect (psKernelExprV2PagedMkSort sortedArena0 .zero)
  let sortedRef := PsKernelExprV2DeclarationRef.mk (nm "protocol-sort") [] sortedType none .constructorDecl
  let sorted := stamp (psKernelExprV2CheckStateWithArena checked sortedArena)
    201 checkedType sortedType [sortedRef,checkedRef]
  let checkStep : Callback := fun fuel ctx owner root =>
    if fuel == 7 && contextEq ctx context && stateEq owner parent && root == domainId then
      some (.ok (checked,checkedType))
    else some (.error "STEP_CHECK_OWNER")
  let sortStep : Callback := fun fuel ctx owner root =>
    if fuel == 7 && contextEq ctx context && stateEq owner checked && root == checkedType then
      some (.ok (sorted,sortedType))
    else some (.error "STEP_SORT_OWNER")
  let step ← direct (psKernelExprV2OrdinaryEliminationStepWith checkStep sortStep
    7 context parent user domainId bodyId .implicit [sortId])
  let propStep ← expect (psKernelExprV2OrdinaryEliminationAfterSort
    context (sorted,.zero) user domainId bodyId .implicit [sortId])
  let domainEntry ← expect (psKernelExprV2PagedRequire parent.whnf.arena domainId)
  let localDomain ← match domainEntry.node with
    | .app _ argument => pure argument
    | _ => throw (IO.userError "protocol annotation application required")
  let fresh := PsKernelName.num user 201
  let expectedContext := psKernelExprV2CheckContextWithLocal context fresh user localDomain .implicit
  let expectedSemantic := (psKernelExprV2CheckStateFreshName sorted user).snd
  let expectedBody := ti (.fvar fresh)
  let decoded ← expect (psKernelExprV2DecodeChecked step.state.whnf.arena)
  let decodedProp ← expect (psKernelExprV2DecodeChecked propStep.state.whnf.arena)
  let nonPropList := match step.revNonProp with
    | [newField,seed] => seed == sortId && newField != sortId &&
        decodedEq decoded (.fvar fresh) newField
    | _ => false
  require counter "protocol/step-full-owner"
    (contextEq step.context expectedContext && contextEq propStep.context expectedContext &&
      semanticEq step.state expectedSemantic && semanticEq propStep.state expectedSemantic &&
      referencesEq step.state.whnf.declarations sorted.whnf.declarations &&
      referencesEq propStep.state.whnf.declarations sorted.whnf.declarations &&
      arenaPrefix sorted.whnf.arena step.state.whnf.arena &&
      arenaPrefix sorted.whnf.arena propStep.state.whnf.arena &&
      step.state.whnf.arena.size > sorted.whnf.arena.size &&
      decodedEq decoded s1 localDomain && decodedEq decoded expectedBody step.body &&
      decodedEq decodedProp expectedBody propStep.body &&
      nonPropList && propStep.revNonProp == [sortId] &&
      parent.nextFresh == 37 && checked.nextFresh == 101 && sorted.nextFresh == 201 &&
      step.state.nextFresh == 202 && propStep.state.nextFresh == 202)
  let outerRef := PsKernelExprV2DeclarationRef.mk (nm "protocol-outer") [] forallId none .constructorDecl
  let outer := stamp parent 61 forallId domainId [outerRef]
  let checkWorker : Callback := fun fuel ctx owner root =>
    if fuel == 7 && contextEq ctx context && stateEq owner outer && root == domainId then
      some (.ok (checked,checkedType))
    else some (.error "WORKER_CHECK_OWNER")
  let whnfWorker := fun (proofField wholeArgument : Bool) =>
    fun (fuel : Nat) (ctx : PsKernelExprV2CheckContext)
        (owner : PsKernelExprV2CheckState) (root : Nat) =>
      if fuel == 7 && contextEq ctx context && stateEq owner parent && root == forallId then
        some (.ok (outer,forallId))
      else if fuel == 7 && contextEq ctx context && stateEq owner checked && root == checkedType then
        some (.ok (sorted,if proofField then propType else sortedType))
      else if fuel == 6 && contextEq ctx expectedContext &&
          stateEq owner step.state && root == step.body then
        some (.ok (owner,if wholeArgument then root else targetId))
      else some (.error "WORKER_WHNF_OWNER")
  let runWorker := fun (proofField wholeArgument : Bool) =>
    psKernelExprV2OrdinaryCtorAllowsLargeElimWorker 8 checkWorker
      (whnfWorker proofField wholeArgument) context parent forallId []
  require counter "protocol/worker-full-owner"
    (boolIs true (runWorker false true) && boolIs false (runWorker false false) &&
      boolIs true (runWorker true false))
  unless (← counter.get) - before == 12 do throw (IO.userError "elimination protocol assertion inventory")
  IO.println "PSC1_ELIMINATION_SECTION protocol=12"

def main : IO Unit := do
  let counter ← IO.mkRef 0
  require counter "harness/negative-control" (!boolIs true (some (.ok false)))
  IO.println "PSC1_ELIMINATION_SECTION harness=1"
  policyMatrix counter
  rawMatrix counter
  memberMatrix counter
  protocolMatrix counter
  unless (← counter.get) == 116 do throw (IO.userError "elimination complete assertion inventory")
  IO.println "PSC1_ORDINARY_ELIMINATION_NATIVE: PASS assertions=116 policyRows=9 rawRows=4 fuelValues=6 fullAdmission=false"
