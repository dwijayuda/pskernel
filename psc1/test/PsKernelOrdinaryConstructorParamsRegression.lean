import Ps.KernelCore.API.DagOrdinaryConstructorParams
import Ps.KernelCore.API.DagOrdinaryHeader
import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/-
Future native-only constructor-parameter prefix regression. This file is not
registered in the current header candidate and has not run in Actions.

The V1 worker below is frozen from Constructor.lean at
0d9f062846d109c362210d441df5fd407ca2cdd7, Git blob
56a70b8ac94283694bf375a8d5c8e7adfd3859b7. Only its declaration/recursive name
and private visibility change. Its retained SessionIsDefEq and Instantiate1
dependencies are the original V1 helpers, never the new DAG worker.

Direct cases use real header owners and full owned DefEq. Callback sentinels
are separate private protocol tests; their cache/reference markers are never
used as checking evidence. Broken-owner rows deliberately violate lineage to
test exact error propagation, and establish no canonical-arena invariant.
No constructor metadata, ordinary admission receipt or publication is made.
-/

private def require (counter : IO.Ref Nat) (label : String) (ok : Bool) : IO Unit := do
  unless ok do throw (IO.userError ("PSC1_ORDINARY_CONSTRUCTOR_PARAMS_FAIL " ++ label))
  counter.modify (fun count => count + 1)
  IO.println ("PSC1_ORDINARY_CONSTRUCTOR_PARAMS_ASSERT " ++ label)

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def direct {α : Type} (label : String) : Option (Except String α) → IO α
  | some (.ok value) => pure value
  | some (.error error) => throw (IO.userError (label ++ ": " ++ error))
  | none => throw (IO.userError ("unexpected constructor-parameter decline: " ++ label))

private def groupDone (counter : IO.Ref Nat) (before expected : Nat)
    (marker : String) : IO Unit := do
  let actual ← counter.get
  unless actual - before == expected do
    throw (IO.userError ("constructor-parameter inventory mismatch: " ++ marker))
  IO.println (marker ++ " assertions=" ++ toString expected)

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ .zero
private def s0 := PsKernelExpr.sort .zero
private def s1 := PsKernelExpr.sort one
private def s2 := PsKernelExpr.sort (.succ one)
private def u := nm "CtorParamU"
private def v := nm "CtorParamV"
private def all (name : String) (domain body : PsKernelExpr)
    (info : PsKernelBinderInfo := .default) :=
  PsKernelExpr.forallE (nm name) domain body info

-- FROZEN_V1_WORKER_BEGIN
private def frozenV1ConstructorParamsWorker
    (fuel : Nat) :
    PsKernelCheckerSession ->
    List PsKernelOpenBinder ->
    PsKernelExpr ->
    Except String PsKernelExprSessionResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_params : List PsKernelOpenBinder)
        (_type : PsKernelExpr) =>
        Except.error
          "simple inductive constructor parameter budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        frozenV1ConstructorParamsWorker remaining;
      fun
        (session : PsKernelCheckerSession)
        (params : List PsKernelOpenBinder)
        (type : PsKernelExpr) =>
        match params with
        | List.nil =>
            Except.ok
              (PsKernelExprSessionResult.mk
                session
                type)
        | List.cons param rest =>
            match type with
            | PsKernelExpr.forallE _ domain body _ =>
                match
                    psKernelSessionIsDefEq
                      remaining
                      session
                      domain
                      param.type with
                | Except.error error =>
                    Except.error error
                | Except.ok equal =>
                    if Prod.fst equal then
                      smaller
                        (Prod.snd equal)
                        rest
                        (psKernelExprInstantiate1
                          body
                          (PsKernelExpr.fvar
                            param.internalName))
                    else
                      Except.error
                        "simple inductive constructor parameter does not match the datatype parameter"
            | _ =>
                Except.error
                  "simple inductive constructor has fewer parameters than the datatype"
-- FROZEN_V1_WORKER_END

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let graph ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire graph root)

private structure DirectCase where
  label : String
  header : PsKernelExpr
  numParams : Nat
  ctor : PsKernelExpr
  levels : List PsKernelName
  supported : Bool

private def directCases : List DirectCase :=
  let h1 := all "A" s1 s1 .implicit
  let h2 := all "A" s1 (all "B" s1 s1 .strictImplicit) .implicit
  let hd := all "A" s1 (all "a" (.bvar 0) s1 .strictImplicit) .implicit
  let ctor := all "X" s1 (.bvar 0)
  [ ⟨"empty",s1,0,s1,[],true⟩,
    ⟨"one",h1,1,ctor,[],true⟩,
    ⟨"renamed-info",h1,1,all "Different" s1 (.bvar 0) .instImplicit,[],true⟩,
    ⟨"two-independent",h2,2,
      all "X" s1 (all "Y" s1 (all "z" (.bvar 1) (.bvar 1))),[],true⟩,
    ⟨"two-dependent",hd,2,all "X" s1 (all "x" (.bvar 0) (.bvar 1)),[],true⟩,
    ⟨"under-binder",h1,1,all "X" s1 (all "z" (.bvar 0) (.bvar 1)),[],true⟩,
    ⟨"metadata-body",h1,1,all "X" s1 (.mdata 177 (all "z" (.bvar 0) (.bvar 1))),[],true⟩,
    ⟨"let-body",h1,1,all "X" s1 (.letE (nm "T") s1 (.bvar 0) (.bvar 0) false),[],true⟩,
    ⟨"beta-domain",h1,1,
      all "X" (.app (.lam (nm "T") s2 (.bvar 0) .default) s1) (.bvar 0),[],true⟩,
    ⟨"metadata-domain",h1,1,all "X" (.mdata 178 s1) (.bvar 0),[],true⟩,
    ⟨"universe",all "A" (.sort (.param u)) (.sort (.param u)),1,
      all "X" (.sort (.param u)) (.bvar 0),[u],true⟩,
    ⟨"wrong-domain",h1,1,all "X" s0 (.bvar 0),[],false⟩,
    ⟨"fewer-at-root",h1,1,s1,[],false⟩,
    ⟨"fewer-after-one",h2,2,all "X" s1 s1,[],false⟩,
    ⟨"whole-metadata",h1,1,.mdata 179 ctor,[],false⟩,
    ⟨"whole-beta",h1,1,.app (.lam (nm "T") s2 ctor .default) s1,[],false⟩,
    ⟨"whole-let",h1,1,.letE (nm "T") s2 s1 ctor false,[],false⟩,
    ⟨"whole-annotation",h1,1,.app (.const psKernelTypeAnnotationOutParamName []) ctor,[],false⟩ ]

private structure DirectFixture where
  old : PsKernelOpenBindersResult
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  parameters : List PsKernelExprV2OrdinaryOpenBinder
  root : Nat

private def prepareDirect (row : DirectCase) : IO DirectFixture := do
  let initial := psKernelMkCheckerSession psKernelEnvironmentEmpty row.levels .safe 0
    psKernelLeanNatMaxSizeDefault
  let checked ← expect (psKernelSessionCheck 4096 initial row.header)
  let sorted ← expect (psKernelSessionEnsureSort 4096 checked.snd checked.fst)
  let old ← expect (psKernelOpenSimpleHeaderParams 4096 sorted.snd row.header row.numParams)
  let (arena,header) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty row.header)
  let declaration := PsKernelDagInductive.mk (nm "CtorParamHeader") header []
  let analysis ← direct (row.label ++ ":header")
    (psKernelExprV2OrdinaryAnalyzeHeaderWithFuel 4096 psKernelEnvironmentEmpty 0
      psKernelLeanNatMaxSizeDefault arena [] row.levels row.numParams declaration false)
  let state := psKernelExprV2OrdinaryConstructorState analysis
  let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked state.whnf.arena row.ctor)
  pure ⟨old,psKernelExprV2OrdinaryConstructorContext analysis,
    psKernelExprV2CheckStateWithArena state arena,analysis.parameters.binders,root⟩

private def sameResult (old : Except String PsKernelExprSessionResult)
    (actual : Option (Except String (PsKernelExprV2CheckState × Nat))) : IO Bool := do
  match old,actual with
  | .error left,some (.error right) => pure (left == right)
  | .ok left,some (.ok right) =>
      pure (psKernelExprEqual left.result (← decode right.fst.whnf.arena right.snd) &&
        left.session.state.nextFresh == right.fst.nextFresh)
  | _,_ => pure false

private def directMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  for row in directCases do
    let fixture ← prepareDirect row
    for fuel in [0,1,2,3,8,4096] do
      require counter ("v1/worker/" ++ row.label ++ "/" ++ toString fuel)
        (← sameResult
          (frozenV1ConstructorParamsWorker fuel fixture.old.session fixture.old.binders row.ctor)
          (psKernelExprV2OrdinaryOpenConstructorParamsWorker fuel
            psKernelExprV2TryDefEqStateWithFuel fixture.context fixture.state fixture.parameters fixture.root))
      require counter ("v1/wrapper/" ++ row.label ++ "/" ++ toString fuel)
        (← sameResult
          (frozenV1ConstructorParamsWorker (Nat.succ fuel)
            fixture.old.session fixture.old.binders row.ctor)
          (psKernelExprV2OrdinaryOpenConstructorParamsWithFuel fuel
            fixture.context fixture.state fixture.parameters fixture.root))
    if row.supported then
      let old ← expect (frozenV1ConstructorParamsWorker 4097
        fixture.old.session fixture.old.binders row.ctor)
      let actual ← direct (row.label ++ ":required-direct")
        (psKernelExprV2OrdinaryOpenConstructorParamsWithFuel 4096
          fixture.context fixture.state fixture.parameters fixture.root)
      require counter ("direct/" ++ row.label)
        (psKernelExprEqual old.result (← decode actual.fst.whnf.arena actual.snd) &&
          actual.fst.nextFresh == fixture.state.nextFresh &&
          old.session.state.nextFresh == fixture.old.session.state.nextFresh &&
          old.session.context.localContext.nextIndex == fixture.old.session.context.localContext.nextIndex &&
          old.session.context.localContext.decls.length == fixture.old.session.context.localContext.decls.length)
  groupDone counter before 227
    "PSC1_ORDINARY_CONSTRUCTOR_PARAMS_V1_NATIVE: PASS comparisons=216 directSuccess=11"

private def sameNames : List PsKernelName → List PsKernelName → Bool
  | [],[] => true
  | a :: rest,b :: tail => psKernelNameEq a b && sameNames rest tail
  | _,_ => false

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

private def sameLocals : List PsKernelExprV2CheckLocal → List PsKernelExprV2CheckLocal → Bool
  | [],[] => true
  | a :: rest,b :: tail =>
      psKernelNameEq a.name b.name && psKernelNameEq a.userName b.userName &&
        a.type == b.type && psKernelBinderInfoEq a.binderInfo b.binderInfo &&
        a.value == b.value && sameLocals rest tail
  | _,_ => false

private def contextSentinel (expected actual : PsKernelExprV2CheckContext) : Bool :=
  sameLocals expected.locals actual.locals &&
    sameNames expected.scalar.levelParams actual.scalar.levelParams &&
    actual.scalar.localContext.decls.isEmpty && actual.scalar.localContext.nextIndex == 891 &&
    actual.scalar.environment.constants.isEmpty && !actual.scalar.environment.quotInitialized &&
    actual.scalar.nativeEvaluator.isNone && actual.scalar.eagerReduce &&
    actual.scalar.maxRecDepth == 73 && actual.scalar.maxNatSize == 991 && actual.scalar.recDepth == 5 &&
    (match actual.scalar.safety with | .unsafeDef => true | _ => false)

/- Each field has a distinct hash slot, so a field permutation fails too.
   These markers are callback data, not successful checking/cache entries. -/
private def tagHash (tag slot : Nat) := psKernelCacheHashModulus + 100 * tag + slot
private def cacheTag (rows : List PsKernelExprV2WhnfCacheEntry) (key marker tag slot : Nat) : Bool :=
  match rows with
  | [row] => row.source == key && row.result == marker && row.hash == tagHash tag slot
  | _ => false
private def pairTag (rows : List PsKernelExprV2DefEqPair) (key marker tag slot : Nat) : Bool :=
  match rows with
  | [row] => row.left == key && row.right == marker && row.hash == tagHash tag slot
  | _ => false
private def markerId (state : PsKernelExprV2CheckState) : Nat :=
  match state.whnf.declarations with
  | [declaration] => match declaration.deltaValue with | some id => id | none => state.whnf.arena.size
  | _ => state.whnf.arena.size
private def declarationTag (state : PsKernelExprV2CheckState) (key marker tag : Nat) : Bool :=
  match state.whnf.declarations with
  | [declaration] =>
      psKernelNameEq declaration.name (.num (nm "CtorParamOwner") tag) &&
        sameNames declaration.levelParams [u,.num v tag] && declaration.type == key &&
        declaration.deltaValue == some marker &&
        (match declaration.kind with | .definitionDecl => true | _ => false)
  | _ => false
private def markerTag (arena : PsKernelExprV2PagedArena) (marker tag : Nat) : Bool :=
  match psKernelExprV2PagedFind arena marker with
  | some entry => match entry.node with | .lit (.nat value) => value == 24000 + tag | _ => false
  | none => false
private def stateTag (state : PsKernelExprV2CheckState) (key tag : Nat) : Bool :=
  let marker := markerId state
  state.nextFresh == 700 + 17 * tag &&
    cacheTag state.whnf.coreCache key marker tag 1 &&
    cacheTag state.whnf.publicCache key marker tag 2 &&
    cacheTag state.checkedInfer key marker tag 3 &&
    cacheTag state.inferOnly key marker tag 4 &&
    cacheTag state.unfold key marker tag 5 &&
    pairTag state.success key marker tag 6 && pairTag state.failure key marker tag 7 &&
    declarationTag state key marker tag && markerTag state.whnf.arena marker tag
private def currentTag (state : PsKernelExprV2CheckState) : Nat :=
  match state.whnf.declarations with
  | [declaration] => match declaration.name with | .num _ tag => tag | _ => 999
  | _ => 999
private def stamp (state : PsKernelExprV2CheckState) (key tag : Nat) :
    Except String PsKernelExprV2CheckState := do
  let (arena,marker) ← psKernelExprV2PagedMkLit state.whnf.arena (.nat (24000 + tag))
  let cache := fun slot => PsKernelExprV2WhnfCacheEntry.mk key marker (tagHash tag slot)
  let pair := fun slot => PsKernelExprV2DefEqPair.mk key marker (tagHash tag slot)
  let declaration := PsKernelExprV2DeclarationRef.mk (.num (nm "CtorParamOwner") tag)
    [u,.num v tag] key (some marker) .definitionDecl
  pure ⟨⟨arena,[cache 1],[cache 2],[declaration]⟩,700 + 17 * tag,
    [cache 3],[pair 6],[cache 4],[cache 5],[pair 7]⟩

private def p0 := PsKernelName.num (nm "HeaderParam") 11
private def p1 := PsKernelName.num (nm "HeaderParam") 12
private def p2 := PsKernelName.num (nm "HeaderParam") 13
private def firstDomain := PsKernelExpr.app (.const psKernelTypeAnnotationOutParamName []) (.mdata 201 s1)
private def sentinelBody := psKernelApplyArgs (.const (nm "CtorParamBody") []) [.bvar 2,.bvar 1,.bvar 0]
private def sentinelCtor := all "CtorFirst" firstDomain
  (all "CtorSecond" (.mdata 202 (.bvar 0))
    (all "CtorThird" (.mdata 203 (.bvar 1)) sentinelBody .instImplicit) .default) .strictImplicit

private structure SentinelFixture where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  parameters : List PsKernelExprV2OrdinaryOpenBinder
  root : Nat
  key : Nat

private def prepareSentinel : IO SentinelFixture := do
  let (arena,key) ← expect (psKernelExprV2PagedMkSort (psKernelExprV2PagedEmptyWithLimit 3) one)
  let (arena,parameterType) ← expect (psKernelExprV2PagedMkFVar arena p0)
  let parameters :=
    [PsKernelExprV2OrdinaryOpenBinder.mk p0 (nm "HeaderA") key .implicit,
     PsKernelExprV2OrdinaryOpenBinder.mk p1 (nm "HeaderValue") parameterType .strictImplicit,
     PsKernelExprV2OrdinaryOpenBinder.mk p2 (nm "HeaderOther") parameterType .default]
  let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked arena sentinelCtor)
  let scalar := { psKernelCheckerContextEmpty psKernelEnvironmentEmpty with
    localContext := PsKernelLocalContext.mk [] 891
    levelParams := [u,v]
    safety := .unsafeDef
    eagerReduce := true
    maxRecDepth := 73
    maxNatSize := 991
    recDepth := 5 }
  let context := PsKernelExprV2CheckContext.mk scalar
    (PsKernelExprV2CheckLocal.mk (nm "ExistingLet") (nm "ExistingUser") key .instImplicit (some key) ::
      parameters.reverse.map (fun parameter => PsKernelExprV2CheckLocal.mk
        parameter.internalName parameter.userName parameter.type parameter.binderInfo none))
  let state ← expect (stamp (psKernelExprV2CheckStateEmpty arena) key 0)
  pure ⟨context,state,parameters,root,key⟩

private def decodedIs (arena : PsKernelExprV2PagedArena) (root : Nat) (expr : PsKernelExpr) : Bool :=
  match psKernelExprV2DecodeChecked arena with
  | .error _ => false
  | .ok graph => match psKernelExprV2DecodedRequire graph root with
    | .error _ => false
    | .ok actual => psKernelExprEqual actual expr

private def callbackError (stage : Nat) := "T05_CONSTRUCTOR_CALLBACK_INJECTED_" ++ toString stage
private def wrongCallback := "T05_CONSTRUCTOR_CALLBACK_WRONG_INPUT_OR_OWNER"
private def budgetError := "simple inductive constructor parameter budget exhausted"
private def mismatchError := "simple inductive constructor parameter does not match the datatype parameter"
private def fewerError := "simple inductive constructor has fewer parameters than the datatype"

private def orderedCallback (fixture : SentinelFixture) (startFuel failAt mode : Nat)
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) : Option (Except String (PsKernelExprV2CheckState × Bool)) :=
  let previous := currentTag state
  let stage := previous + 1
  let expectedLeft := if stage == 1 then firstDomain
    else if stage == 2 then PsKernelExpr.mdata 202 (.fvar p0)
    else PsKernelExpr.mdata 203 (.fvar p0)
  let expectedRight := psKernelExprV2TransformNatGet (fixture.parameters.map (fun parameter => parameter.type)) previous
  if Nat.blt 3 stage || fuel != startFuel + 1 - stage ||
      !contextSentinel fixture.context context || !stateTag state fixture.key previous ||
      !arenaPrefix fixture.state.whnf.arena state.whnf.arena ||
      expectedRight != some right || !decodedIs state.whnf.arena left expectedLeft then
    some (.error wrongCallback)
  else if stage == failAt then
    if mode == 1 then none
    else if mode == 2 then some (.error (callbackError stage))
    else some (.ok (psKernelExprV2CheckStateWithArena state psKernelExprV2PagedEmpty,false))
  else if failAt != 0 && Nat.blt failAt stage then
    some (.error "T05_CONSTRUCTOR_CALLBACK_AFTER_STOP")
  else some ((stamp state fixture.key stage).map (fun next => (next,true)))

private def errorIs {α : Type} (result : Option (Except String α)) (error : String) : Bool :=
  match result with | some (.error actual) => actual == error | _ => false

private def appendedFVarsAreExisting (fixture : SentinelFixture) (arena : PsKernelExprV2PagedArena) : Bool :=
  let appended := (List.range (arena.size - fixture.state.whnf.arena.size)).map
    (fun index => index + fixture.state.whnf.arena.size)
  let names := fixture.parameters.map (fun parameter => parameter.internalName)
  appended.all (fun id => match psKernelExprV2PagedFind arena id with
    | none => false
    | some entry => match entry.node with
      | .fvar name => names.any (fun old => psKernelNameEq old name)
      | _ => true) &&
    names.all (fun name => appended.any (fun id => match psKernelExprV2PagedFind arena id with
      | some entry => match entry.node with | .fvar actual => psKernelNameEq actual name | _ => false
      | none => false))

private def ownerControls (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  let fixture ← prepareSentinel
  let run := fun failAt mode => psKernelExprV2OrdinaryOpenConstructorParamsWith
    (orderedCallback fixture 7 failAt mode) 7 fixture.context fixture.state fixture.parameters fixture.root
  let (state,root) ← direct "three-ordered-defeq-owner-callbacks" (run 0 0)
  let marker := markerId state
  for (label,ok) in
      [("core-cache",cacheTag state.whnf.coreCache fixture.key marker 3 1),
       ("public-cache",cacheTag state.whnf.publicCache fixture.key marker 3 2),
       ("checked-infer",cacheTag state.checkedInfer fixture.key marker 3 3),
       ("infer-only",cacheTag state.inferOnly fixture.key marker 3 4),
       ("unfold",cacheTag state.unfold fixture.key marker 3 5),
       ("success-pairs",pairTag state.success fixture.key marker 3 6),
       ("failure-pairs",pairTag state.failure fixture.key marker 3 7),
       ("declarations",declarationTag state fixture.key marker 3),
       ("freshness",state.nextFresh == 751),
       ("arena",arenaPrefix fixture.state.whnf.arena state.whnf.arena && markerTag state.whnf.arena marker 3)] do
    require counter ("owner/" ++ label) ok
  require counter "owner/instantiated-existing-names"
    (decodedIs state.whnf.arena root (psKernelApplyArgs (.const (nm "CtorParamBody") []) [.fvar p0,.fvar p1,.fvar p2]))
  require counter "owner/no-new-fvar-names" (appendedFVarsAreExisting fixture state.whnf.arena)
  for stage in [1,2,3] do
    for mode in [1,2,3] do
      let result := run stage mode
      require counter ("callback/stop/" ++ toString stage ++ "/" ++ toString mode)
        (if mode == 1 then result.isNone
         else errorIs result (if mode == 2 then callbackError stage else mismatchError))
  groupDone counter before 21
    "PSC1_ORDINARY_CONSTRUCTOR_PARAMS_OWNER_NATIVE: PASS ownerFields=10 callbacks=3 propagated=9"

private def singleCallback (fixture : SentinelFixture) (expectedFuel mode : Nat)
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) : Option (Except String (PsKernelExprV2CheckState × Bool)) :=
  if fuel != expectedFuel || !contextSentinel fixture.context context ||
      !stateTag state fixture.key 0 || right != fixture.key ||
      !decodedIs state.whnf.arena left firstDomain then
    some (.error wrongCallback)
  else if mode == 1 then none
  else if mode == 2 then some (.error "T05_CONSTRUCTOR_BOUNDARY_CALLBACK_ERROR")
  else if mode == 3 then
    some (.ok (psKernelExprV2CheckStateWithArena state psKernelExprV2PagedEmpty,false))
  else some (.ok (state,true))

private def forbid (_ : Nat) (_ : PsKernelExprV2CheckContext) (_ : PsKernelExprV2CheckState)
    (_ _ : Nat) : Option (Except String (PsKernelExprV2CheckState × Bool)) :=
  some (.error "T05_CONSTRUCTOR_CALLBACK_FORBIDDEN")

private def identityResult (fixture : SentinelFixture) (state : PsKernelExprV2CheckState) (root : Nat)
    (result : Option (Except String (PsKernelExprV2CheckState × Nat))) : Bool :=
  match result with
  | some (.ok actual) => actual.snd == root && stateTag actual.fst fixture.key 0 &&
      actual.fst.whnf.arena.size == state.whnf.arena.size && arenaPrefix state.whnf.arena actual.fst.whnf.arena
  | _ => false

private def firstOpened : PsKernelExpr :=
  match sentinelCtor with
  | .forallE _ _ body _ => psKernelExprInstantiate1 body (.fvar p0)
  | _ => sentinelCtor

private def oneParameterSuccess (fixture : SentinelFixture)
    (result : Option (Except String (PsKernelExprV2CheckState × Nat))) : Bool :=
  match result with
  | some (.ok actual) => stateTag actual.fst fixture.key 0 &&
      arenaPrefix fixture.state.whnf.arena actual.fst.whnf.arena &&
      decodedIs actual.fst.whnf.arena actual.snd firstOpened
  | _ => false

private def nonForallCases : List (String × PsKernelExpr) :=
  let ctor := all "X" s1 (.bvar 0)
  [ ("bvar",.bvar 0), ("fvar",.fvar p0), ("mvar",.mvar (nm "UninspectedMeta")),
    ("sort",s1), ("const",.const (nm "UninspectedConst") []),
    ("app-beta",.app (.lam (nm "T") s2 ctor .default) s1),
    ("lambda",.lam (nm "x") s1 (.bvar 0) .default),
    ("let-forall",.letE (nm "T") s2 s1 ctor false),
    ("literal",.lit (.nat 91)), ("metadata-forall",.mdata 204 ctor),
    ("projection",.proj (nm "UninspectedProjection") 0 s1) ]

private def boundaryControls (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  let fixture ← prepareSentinel
  let parameters := fixture.parameters.take 1
  let badRoot := fixture.state.whnf.arena.size + 100
  let worker := fun fuel callback state params root =>
    psKernelExprV2OrdinaryOpenConstructorParamsWorker fuel callback fixture.context state params root
  let wrapper := fun fuel callback state params root =>
    psKernelExprV2OrdinaryOpenConstructorParamsWith callback fuel fixture.context state params root
  require counter "boundary/zero-empty-invalid-root"
    (errorIs (worker 0 forbid fixture.state [] badRoot) budgetError)
  require counter "boundary/zero-nonempty-invalid-root"
    (errorIs (worker 0 forbid fixture.state parameters badRoot) budgetError)
  require counter "boundary/zero-valid-forall"
    (errorIs (worker 0 forbid fixture.state parameters fixture.root) budgetError)
  require counter "boundary/successor-empty-invalid-root"
    (identityResult fixture fixture.state badRoot (worker 1 forbid fixture.state [] badRoot))
  require counter "boundary/wrapper-zero-empty-invalid-root"
    (identityResult fixture fixture.state badRoot (wrapper 0 forbid fixture.state [] badRoot))
  let (arena,wrappedRoot) ← expect (psKernelExprV2PagedImportIntoChecked fixture.state.whnf.arena
    (.mdata 205 (.app (.lam (nm "T") s2 sentinelCtor .default) s1)))
  let wrappedState := psKernelExprV2CheckStateWithArena fixture.state arena
  require counter "boundary/empty-preserves-unreduced-root"
    (identityResult fixture wrappedState wrappedRoot (worker 1 forbid wrappedState [] wrappedRoot))
  require counter "boundary/invalid-root-before-defeq"
    (errorIs (worker 8 forbid fixture.state parameters badRoot) "PSKERNEL_V2_PAGED_INVALID_CHILD")
  require counter "boundary/worker-one-true-still-zero-before-empty"
    (errorIs (worker 1 (singleCallback fixture 0 0) fixture.state parameters fixture.root) budgetError)
  require counter "boundary/wrapper-zero-true-still-zero-before-empty"
    (errorIs (wrapper 0 (singleCallback fixture 0 0) fixture.state parameters fixture.root) budgetError)
  require counter "boundary/worker-two-one-parameter"
    (oneParameterSuccess fixture (worker 2 (singleCallback fixture 1 0) fixture.state parameters fixture.root))
  require counter "boundary/wrapper-one-one-parameter"
    (oneParameterSuccess fixture (wrapper 1 (singleCallback fixture 1 0) fixture.state parameters fixture.root))
  require counter "boundary/actual-defeq-zero-precedes-tail-budget"
    (errorIs (psKernelExprV2OrdinaryOpenConstructorParamsWithFuel 0
      fixture.context fixture.state parameters fixture.root) "kernel definitional equality budget exhausted")
  require counter "boundary/three-parameters-wrapper-two-exhausts"
    (errorIs (wrapper 2 (orderedCallback fixture 2 0 0) fixture.state fixture.parameters fixture.root) budgetError)
  let three := wrapper 3 (orderedCallback fixture 3 0 0) fixture.state fixture.parameters fixture.root
  require counter "boundary/three-parameters-wrapper-three-finishes"
    (match three with
     | some (.ok result) => stateTag result.fst fixture.key 3 &&
         decodedIs result.fst.whnf.arena result.snd
           (psKernelApplyArgs (.const (nm "CtorParamBody") []) [.fvar p0,.fvar p1,.fvar p2])
     | _ => false)
  require counter "boundary/decline-before-zero-tail"
    (worker 1 (singleCallback fixture 0 1) fixture.state parameters fixture.root).isNone
  require counter "boundary/error-before-zero-tail"
    (errorIs (worker 1 (singleCallback fixture 0 2) fixture.state parameters fixture.root)
      "T05_CONSTRUCTOR_BOUNDARY_CALLBACK_ERROR")
  require counter "boundary/false-before-zero-tail"
    (errorIs (worker 1 (singleCallback fixture 0 3) fixture.state parameters fixture.root) mismatchError)
  for (label,expr) in nonForallCases do
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked fixture.state.whnf.arena expr)
    let state := psKernelExprV2CheckStateWithArena fixture.state arena
    require counter ("boundary/syntactic-nonforall/" ++ label)
      (errorIs (worker 8 forbid state parameters root) fewerError)
  groupDone counter before 28
    "PSC1_ORDINARY_CONSTRUCTOR_PARAMS_BOUNDARY_NATIVE: PASS boundaries=17 nonForall=11"

/- These arenas are deliberate protocol faults. They are NOT inputs admitted
   by replay validation or claimed valid counterexamples to canonicality.
   The source root is canonical before DefEq; the injected return owner breaks
   its lineage, so the existing transform must report its first actual error.
   MkFVar itself is unconditionally Except.ok in the frozen production source;
   no invented executable fvar-construction error is counted here. -/
private def brokenBodyArena (body : Nat) (dangling : Bool) : IO PsKernelExprV2PagedArena := do
  let mut arena := psKernelExprV2PagedEmptyWithLimit (body + 32)
  for _ in List.range body do
    let (next,_) ← expect (psKernelExprV2PagedMkSort arena one)
    arena := next
  if dangling then
    pure (psKernelExprV2PagedPush arena
      (PsKernelExprV2Entry.mk (.app (body + 1000) (body + 1000)) 0 1 false false 2)).fst
  else
    let (next,_) ← expect (psKernelExprV2PagedMkBVar arena 0)
    pure { next with size := next.size + 7 }

private def faultControls (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  let fixture ← prepareSentinel
  let entry ← expect (psKernelExprV2PagedRequire fixture.state.whnf.arena fixture.root)
  let body ← match entry.node with
    | .forallE _ _ body _ => pure body
    | _ => throw (IO.userError "constructor-parameter fault fixture is not forall")
  let dangling ← brokenBodyArena body true
  let missingReplacement ← brokenBodyArena body false
  let zeroCapacity := { fixture.state.whnf.arena with pageLimit := 0 }
  for (label,fuel,broken,equal,error) in
      [("empty-owner",2,psKernelExprV2PagedEmpty,true,"PSKERNEL_V2_TRANSFORM_BAD_ROOT"),
       ("empty-owner-zero-tail",1,psKernelExprV2PagedEmpty,true,"PSKERNEL_V2_TRANSFORM_BAD_ROOT"),
       ("empty-owner-false",2,psKernelExprV2PagedEmpty,false,mismatchError),
       ("zero-capacity-owner",2,zeroCapacity,true,"PSKERNEL_V2_TRANSFORM_BAD_ROOT"),
       ("dangling-child-owner",2,dangling,true,"PSKERNEL_V2_TRANSFORM_BAD_ROOT"),
       ("dangling-child-false",2,dangling,false,mismatchError),
       ("unaddressable-replacement",2,missingReplacement,true,"PSKERNEL_V2_TRANSFORM_BAD_REFERENCE"),
       ("unaddressable-replacement-zero-tail",1,missingReplacement,true,"PSKERNEL_V2_TRANSFORM_BAD_REFERENCE")] do
    let callback := fun currentFuel context state left right =>
      match singleCallback fixture (fuel - 1) 0 currentFuel context state left right with
      | some (.ok next) => some (.ok (psKernelExprV2CheckStateWithArena next.fst broken,equal))
      | failed => failed
    require counter ("fault/" ++ label)
      (errorIs (psKernelExprV2OrdinaryOpenConstructorParamsWorker fuel callback
        fixture.context fixture.state (fixture.parameters.take 1) fixture.root) error)
  groupDone counter before 8
    "PSC1_ORDINARY_CONSTRUCTOR_PARAMS_FAULT_NATIVE: PASS injectedBrokenOwners=8"

def main : IO Unit := do
  let counter ← IO.mkRef 0
  directMatrix counter
  ownerControls counter
  boundaryControls counter
  faultControls counter
  let actual ← counter.get
  unless actual == 284 do
    throw (IO.userError ("constructor-parameter total inventory mismatch: " ++ toString actual))
  IO.println "PSC1_ORDINARY_CONSTRUCTOR_PARAMS_REGRESSION: PASS assertions=284 directSuccess=11 prefixOnly=true fullAdmission=false"
