import Ps.KernelCore.API.DagOrdinaryConstructorAnalysis
import Ps.KernelCore.API.DagOrdinaryHeader
import Ps.KernelCore.Admission.Inductive.Ordinary.ConstructorAdmission
import Ps.KernelCore.Core.ExprV2.Decode
import Ps.KernelCore.Research.ExprV2PagedImport

/- Private single-constructor analysis qualification.
   Each fixture first checks its header, then builds only the provisional
   target environment used by the existing V1 constructor phase. The original
   unopened constructor is checked by both workers. No public admission,
   generated recursor or atomic publication is claimed. -/

private def require (counter : IO.Ref Nat) (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_CONSTRUCTOR_ANALYSIS_NATIVE_FAIL " ++ label))
  counter.modify (fun n => n + 1)
  IO.println ("PSC1_CONSTRUCTOR_ANALYSIS_ASSERT " ++ label)

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def direct {α : Type} : Option (Except String α) → IO α
  | some (.ok value) => pure value
  | some (.error error) => throw (IO.userError error)
  | none => throw (IO.userError "unexpected private constructor analysis decline")

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ .zero
private def s0 := PsKernelExpr.sort .zero
private def s1 := PsKernelExpr.sort one
private def target := nm "CtorAnalysisT"
private def ctorName := nm "CtorAnalysisT.mk"
private def t := PsKernelExpr.const target []
private def all (name : String) (domain body : PsKernelExpr)
    (info : PsKernelBinderInfo := .default) :=
  PsKernelExpr.forallE (nm name) domain body info
private def ti (index : PsKernelExpr) := PsKernelExpr.app t index
private def ih := all "i" s1 s1
private def ph := all "A" s1 s1 .implicit

private structure AnalysisCase where
  label : String
  header : PsKernelExpr
  numParams : Nat
  ctorType : PsKernelExpr
  expected : Except String (Nat × Nat × Nat)

private def analysisCases : List AnalysisCase :=
  [ ⟨"empty",s1,0,t,.ok (0,0,0)⟩,
    ⟨"prop-field",s1,0,all "p" s0 t,.ok (1,0,0)⟩,
    ⟨"direct-recursive",s1,0,all "t" t t,.ok (1,1,0)⟩,
    ⟨"function-following",s1,0,all "f" (all "a" s0 t) (all "q" s0 t),.ok (2,1,0)⟩,
    ⟨"parameterized",ph,1,all "X" s1 (all "x" (.bvar 0) (ti (.bvar 1))) .implicit,.ok (1,0,0)⟩,
    ⟨"indexed",ih,0,all "t" (ti s0) (ti s0),.ok (1,1,1)⟩,
    ⟨"free-variable",s1,0,.fvar (nm "CtorAnalysisFree"),.error "declaration has free variables"⟩,
    ⟨"undefined-universe",s1,0,.sort (.param (nm "CtorAnalysisUndef")),
      .error "invalid reference to undefined universe level parameter"⟩,
    ⟨"ill-typed-domain",s1,0,all "x" (.app s0 s0) t,.error "expected function type"⟩,
    ⟨"wrong-result",s1,0,s0,
      .error "simple inductive constructor must return the declared datatype with matching parameters and index arity"⟩,
    ⟨"negative-function",s1,0,all "f" (all "x" t t) t,
      .error "recursive function argument contains a negative recursive occurrence"⟩,
    ⟨"recursive-result-index",ih,0,ti (ti s0),
      .error "simple inductive constructor return index contains a recursive occurrence"⟩ ]

private structure Fixture where
  decl : PsKernelSimpleInductiveDecl
  ctor : PsKernelSimpleConstructorDecl
  oldHeader : PsKernelCheckerSession
  oldParams : List PsKernelOpenBinder
  work : PsKernelEnvironment
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  params : List PsKernelExprV2OrdinaryOpenBinder
  numIndices : Nat
  resultLevel : PsKernelLevel
  dagCtor : PsKernelDagConstructor

private def prepare (row : AnalysisCase) : IO Fixture := do
  let initial := psKernelMkCheckerSession psKernelEnvironmentEmpty [] .safe 0 psKernelLeanNatMaxSizeDefault
  let checked ← expect (psKernelSessionCheck 4096 initial row.header)
  let sorted ← expect (psKernelSessionEnsureSort 4096 checked.snd checked.fst)
  let oldParams ← expect (psKernelOpenSimpleHeaderParams 4096 sorted.snd row.header row.numParams)
  let oldIndices ← expect (psKernelOpenSimpleHeaderIndices 4096 oldParams.session oldParams.result)
  let resultLevel ← match oldIndices.result with
    | .sort level => pure level
    | _ => throw (IO.userError "V1 header result is not a sort")
  let (arena,headerId) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty row.header)
  let analysis ← direct (psKernelExprV2OrdinaryAnalyzeHeaderWithFuel 4096 psKernelEnvironmentEmpty
    0 psKernelLeanNatMaxSizeDefault arena [] [] row.numParams ⟨target,headerId,[]⟩ false)
  unless psKernelLevelEq resultLevel analysis.resultLevel do
    throw (IO.userError "header result universe mismatch")
  let numIndices := analysis.indices.binders.length
  unless numIndices == oldIndices.binders.length do throw (IO.userError "header index arity mismatch")
  let info := PsKernelInductiveInfo.mk ⟨target,[],row.header⟩
    row.numParams numIndices [target] [ctorName] 0 false false false
  let work := psKernelEnvironmentAddUnchecked psKernelEnvironmentEmpty (.inductInfo info)
  let parent := psKernelExprV2OrdinaryConstructorState analysis
  let ctx := psKernelExprV2OrdinaryConstructorContext analysis
  let context := PsKernelExprV2CheckContext.mk (psKernelCheckerContextWithEnvironment ctx.scalar work) ctx.locals
  let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked parent.whnf.arena row.ctorType)
  let reference := PsKernelExprV2DeclarationRef.mk target [] headerId none .inductiveDecl
  let state := psKernelExprV2CheckStateWithWhnf parent
    ⟨arena,parent.whnf.coreCache,parent.whnf.publicCache,reference :: parent.whnf.declarations⟩
  let ctor := PsKernelSimpleConstructorDecl.mk ctorName row.ctorType
  let decl := PsKernelSimpleInductiveDecl.mk [] target row.header [ctor] false row.numParams
  pure ⟨decl,ctor,oldParams.session,oldParams.binders,work,context,state,
    analysis.parameters.binders,numIndices,resultLevel,⟨ctorName,root⟩⟩

private def sameList {α β : Type} (same : α → β → Bool) : List α → List β → Bool
  | [],[] => true
  | a :: rest,b :: tail => same a b && sameList same rest tail
  | _,_ => false

private def decodedEq (built : PsKernelExprV2Decoded) (left : PsKernelExpr) (right : Nat) : Bool :=
  match psKernelExprV2DecodedRequire built right with
  | .ok value => psKernelExprEqual left value
  | .error _ => false

private def binderEq (built : PsKernelExprV2Decoded)
    (left : PsKernelOpenBinder) (right : PsKernelExprV2OrdinaryOpenBinder) : Bool :=
  psKernelNameEq left.internalName right.internalName &&
    psKernelNameEq left.userName right.userName &&
    psKernelBinderInfoEq left.binderInfo right.binderInfo && decodedEq built left.type right.type

private def localsEq (built : PsKernelExprV2Decoded)
    (left : List PsKernelLocalDecl) (right : List PsKernelExprV2CheckLocal) : Bool :=
  sameList (fun old actual =>
    psKernelNameEq (psKernelLocalDeclName old) actual.name &&
    psKernelNameEq (psKernelLocalDeclUserName old) actual.userName &&
    psKernelBinderInfoEq (psKernelLocalDeclBinderInfo old) actual.binderInfo &&
    decodedEq built (psKernelLocalDeclType old) actual.type &&
    (psKernelLocalDeclValue old).isNone && actual.value.isNone) left right

private def referencesEq (left right : List PsKernelExprV2DeclarationRef) : Bool :=
  sameList (fun a b => psKernelNameEq a.name b.name &&
    psKernelNameListsEq a.levelParams b.levelParams && a.type == b.type &&
    a.deltaValue == b.deltaValue &&
    (match a.kind,b.kind with | .inductiveDecl,.inductiveDecl => true | _,_ => false))
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


private def shapeEq (built : PsKernelExprV2Decoded)
    (old : PsKernelSimpleConstructorShape)
    (actual : PsKernelExprV2OrdinaryConstructorShape) : Bool :=
  psKernelNameEq old.ctor.name actual.ctor.name &&
    decodedEq built old.ctor.type actual.ctor.type &&
    sameList (binderEq built) old.fields actual.fields &&
    sameList (fun a b => binderEq built a.field b.field &&
      sameList (binderEq built) a.args b.arguments &&
      sameList (decodedEq built) a.indices b.indices) old.recursiveFields actual.recursiveFields &&
    sameList (decodedEq built) old.resultIndices actual.resultIndices

private def analysisEq (fixture : Fixture) (phaseFuel : Nat)
    (old : Except String PsKernelAddConstructorsResult)
    (actual : Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis)) : Bool :=
  match old,actual with
  | .error left,some (.error right) => left == right
  | .ok left,some (.ok right) =>
      match left.shapes,psKernelExprV2DecodeChecked right.state.whnf.arena with
      | [shape],.ok built =>
          -- The full frozen constructor loop must succeed before the old
          -- parameter/field owner is recomputed for ownership comparison.
          let owner := psKernelSessionWithEnvironment fixture.oldHeader fixture.work
          match psKernelOpenSimpleConstructorParams phaseFuel owner fixture.oldParams fixture.ctor.type with
          | .error _ => false
          | .ok afterParams =>
              match psKernelOpenSimpleConstructorFields phaseFuel afterParams.session target []
                  fixture.oldParams fixture.numIndices fixture.resultLevel afterParams.result with
              | .error _ => false
              | .ok fields =>
                  shapeEq built shape right.shape &&
                  right.shape.ctor.type == fixture.dagCtor.type &&
                  fields.session.state.nextFresh == right.state.nextFresh &&
                  localsEq built fields.session.context.localContext.decls right.context.locals &&
                  referencesEq right.state.whnf.declarations fixture.state.whnf.declarations &&
                  arenaPrefix fixture.state.whnf.arena right.state.whnf.arena
      | _,_ => false
  | _,_ => false

private def analysisMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  unless analysisCases.length == 12 &&
      (analysisCases.filter (fun row => match row.expected with | .ok _ => true | _ => false)).length == 6 do
    throw (IO.userError "analysis fixture inventory requires twelve rows with six positive and six negative")
  for row in analysisCases do
    let fixture ← prepare row
    for phaseFuel in [0,1,2,3,8,4096] do
      let old := psKernelAddSimpleConstructorsWithFuel (Nat.succ phaseFuel)
        fixture.decl .safe fixture.resultLevel [] fixture.oldParams fixture.numIndices
        fixture.oldHeader fixture.work 0 [fixture.ctor]
      let actual := psKernelExprV2OrdinaryAnalyzeConstructorWithFuel phaseFuel fixture.context
        fixture.state target [] fixture.params fixture.numIndices fixture.resultLevel fixture.dagCtor
      require counter ("matrix/" ++ row.label ++ "/phaseFuel=" ++ toString phaseFuel)
        (analysisEq fixture phaseFuel old actual)
    let actual := psKernelExprV2OrdinaryAnalyzeConstructorWithFuel 4096 fixture.context fixture.state
      target [] fixture.params fixture.numIndices fixture.resultLevel fixture.dagCtor
    let correct := match row.expected,actual with
      | .error expected,some (.error got) => expected == got
      | .ok dimensions,some (.ok got) =>
          got.shape.fields.length == dimensions.fst &&
          got.shape.recursiveFields.length == dimensions.snd.fst &&
          got.shape.resultIndices.length == dimensions.snd.snd
      | _,_ => false
    require counter ("matrix/" ++ row.label ++ "/required-outcome") correct
  unless (← counter.get) - before == 84 do throw (IO.userError "analysis matrix assertion inventory")
  IO.println "PSC1_CONSTRUCTOR_ANALYSIS_SECTION matrix=84"

private abbrev CheckCallback := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
  Option (Except String (PsKernelExprV2CheckState × Nat))
private abbrev DefEqCallback := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →
  Option (Except String (PsKernelExprV2CheckState × Bool))

private def callbackDecline : CheckCallback := fun _ _ _ _ => none
private def callbackError (message : String) : CheckCallback := fun _ _ _ _ => some (.error message)
private def forbidden : CheckCallback := callbackError "UNEXPECTED_CALLBACK"
private def forbiddenDefEq : DefEqCallback := fun _ _ _ _ _ => some (.error "UNEXPECTED_DEFEQ")

private def errorIs {α : Type} (message : String) : Option (Except String α) → Bool
  | some (.error got) => message == got
  | _ => false

private def cacheEq (left right : List PsKernelExprV2WhnfCacheEntry) : Bool :=
  sameList (fun a b => a.source == b.source && a.result == b.result && a.hash == b.hash) left right

private def pairsEq (left right : List PsKernelExprV2DefEqPair) : Bool :=
  sameList (fun a b => a.left == b.left && a.right == b.right && a.hash == b.hash) left right

private def stateEq (left right : PsKernelExprV2CheckState) : Bool :=
  left.nextFresh == right.nextFresh &&
    left.whnf.arena.size == right.whnf.arena.size &&
    arenaPrefix left.whnf.arena right.whnf.arena &&
    cacheEq left.whnf.coreCache right.whnf.coreCache &&
    cacheEq left.whnf.publicCache right.whnf.publicCache &&
    referencesEq left.whnf.declarations right.whnf.declarations &&
    cacheEq left.checkedInfer right.checkedInfer &&
    pairsEq left.success right.success &&
    cacheEq left.inferOnly right.inferOnly &&
    cacheEq left.unfold right.unfold &&
    pairsEq left.failure right.failure

private def inductiveEq (left right : PsKernelInductiveInfo) : Bool :=
  psKernelNameEq left.base.name right.base.name &&
    psKernelNameListsEq left.base.levelParams right.base.levelParams &&
    psKernelExprEqual left.base.type right.base.type &&
    left.numParams == right.numParams && left.numIndices == right.numIndices &&
    psKernelNameListsEq left.all right.all && psKernelNameListsEq left.ctors right.ctors &&
    left.numNested == right.numNested && left.isRec == right.isRec &&
    left.isReflexive == right.isReflexive && left.isUnsafe == right.isUnsafe

/- The protocol uses precisely one provisional datatype and no local variables.
   Compare its complete inductive metadata and indexed lookup as well as every
   scalar context setting. The universal proofs separately establish exact
   context identity for arbitrary established owners. -/
private def protocolEnvironmentEq (left right : PsKernelEnvironment) : Bool :=
  left.quotInitialized == right.quotInitialized &&
    left.runtime.nativeEvaluator.isNone && right.runtime.nativeEvaluator.isNone &&
    (match left.constants,right.constants,
        psKernelEnvironmentFind left target,psKernelEnvironmentFind right target with
    | [.inductInfo a],[.inductInfo b],some (.inductInfo c),some (.inductInfo d) =>
        inductiveEq a b && inductiveEq a c && inductiveEq b d
    | _,_,_,_ => false)

private def protocolContextEq (left right : PsKernelExprV2CheckContext) : Bool :=
  left.locals.isEmpty && right.locals.isEmpty &&
    left.scalar.localContext.decls.isEmpty && right.scalar.localContext.decls.isEmpty &&
    left.scalar.localContext.nextIndex == right.scalar.localContext.nextIndex &&
    psKernelNameListsEq left.scalar.levelParams right.scalar.levelParams &&
    psKernelSafetyEq left.scalar.safety right.scalar.safety &&
    left.scalar.eagerReduce == right.scalar.eagerReduce &&
    left.scalar.nativeEvaluator.isNone && right.scalar.nativeEvaluator.isNone &&
    left.scalar.maxRecDepth == right.scalar.maxRecDepth &&
    left.scalar.maxNatSize == right.scalar.maxNatSize &&
    left.scalar.recDepth == right.scalar.recDepth &&
    protocolEnvironmentEq left.scalar.environment right.scalar.environment

/- Distinct protocol-only markers exercise all seven semantic collections.
   They are never supplied to the real checker or published as judgments. -/
private def stamp (state : PsKernelExprV2CheckState) (fresh source result : Nat)
    (references : List PsKernelExprV2DeclarationRef) : PsKernelExprV2CheckState :=
  ⟨⟨state.whnf.arena,[⟨source,result,fresh+1⟩],[⟨source,result,fresh+2⟩],references⟩,
    fresh,[⟨source,result,fresh+3⟩],[⟨source,result,fresh+4⟩],
    [⟨source,result,fresh+5⟩],[⟨source,result,fresh+6⟩],[⟨source,result,fresh+7⟩]⟩

private def protocolMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  let base ← prepare ⟨"protocol",s1,0,t,.ok (0,0,0)⟩
  let free ← prepare ⟨"protocol-free",s1,0,.fvar (nm "CtorAnalysisFree"),
    .error "declaration has free variables"⟩
  let (arena,sortId) ← expect (psKernelExprV2PagedMkSort base.state.whnf.arena one)
  let header := stamp (psKernelExprV2CheckStateWithArena base.state arena)
    37 base.dagCtor.type sortId base.state.whnf.declarations
  let run := fun check whnf =>
    psKernelExprV2OrdinaryAnalyzeConstructorWith check whnf forbiddenDefEq
      7 base.context header target [] base.params base.numIndices base.resultLevel base.dagCtor
  let checkedSort : CheckCallback := fun _ _ state _ => some (.ok (state,sortId))
  require counter "protocol/static-before-callbacks"
    (errorIs "declaration has free variables"
      (psKernelExprV2OrdinaryAnalyzeConstructorWith forbidden forbidden forbiddenDefEq
        7 free.context free.state target [] free.params free.numIndices free.resultLevel free.dagCtor))
  require counter "protocol/closed-check-decline" ((run callbackDecline forbidden).isNone)
  require counter "protocol/closed-check-error"
    (errorIs "closed-check-sentinel" (run (callbackError "closed-check-sentinel") forbidden))
  require counter "protocol/sort-decline" ((run checkedSort callbackDecline).isNone)
  require counter "protocol/sort-error"
    (errorIs "sort-sentinel" (run checkedSort (callbackError "sort-sentinel")))
  require counter "protocol/sort-required"
    (errorIs "expected sort" (run checkedSort (fun _ _ state _ => some (.ok (state,base.dagCtor.type)))))
  -- Build the expected fork independently of the production fork helpers.
  let closedSession := psKernelMkCheckerSession base.context.scalar.environment
    base.context.scalar.levelParams base.context.scalar.safety
    base.context.scalar.maxRecDepth base.context.scalar.maxNatSize
  let closedContext := psKernelExprV2CheckContextEmpty closedSession.context
  let closedState := PsKernelExprV2CheckState.mk
    ⟨header.whnf.arena,[],[],header.whnf.declarations⟩ 0 [] [] [] [] []
  let (checkArena,checkType) ← expect (psKernelExprV2PagedMkSort header.whnf.arena one)
  let checkedState := stamp (psKernelExprV2CheckStateWithArena closedState checkArena)
    101 base.dagCtor.type checkType []
  let (sortArena,sortType) ← expect (psKernelExprV2PagedMkSort checkArena one)
  let sortedState := stamp (psKernelExprV2CheckStateWithArena checkedState sortArena)
    201 checkType sortType []
  let check : CheckCallback := fun fuel context state root =>
    if fuel == 7 && root == base.dagCtor.type &&
        protocolContextEq context closedContext && stateEq state closedState then
      some (.ok (checkedState,checkType))
    else some (.error "CLOSED_CHECK_OWNER_PROTOCOL")
  let whnf : CheckCallback := fun fuel context state root =>
    if fuel == 7 && root == checkType &&
        protocolContextEq context closedContext && stateEq state checkedState then
      some (.ok (sortedState,sortType))
    else some (.error "CLOSED_SORT_OWNER_PROTOCOL")
  let got ← direct (run check whnf)
  let resumed := psKernelExprV2CheckStateWithArena header sortArena
  require counter "protocol/closed-owner-discard-and-header-resume"
    (protocolContextEq got.context base.context && stateEq got.state resumed &&
      psKernelNameEq got.shape.ctor.name base.dagCtor.name &&
      got.shape.ctor.type == base.dagCtor.type &&
      got.shape.fields.isEmpty && got.shape.recursiveFields.isEmpty &&
      got.shape.resultIndices.isEmpty && got.state.nextFresh == 37)
  -- Pure callbacks enforce the complete owner at each phase. These checks
  -- inspect the resulting append lineage; no mutable call counter is claimed.
  require counter "protocol/ordered-owner-lineage"
    (checkType == header.whnf.arena.size && sortType == checkArena.size &&
      got.state.whnf.arena.size == header.whnf.arena.size + 2 &&
      arenaPrefix header.whnf.arena got.state.whnf.arena &&
      arenaPrefix checkArena got.state.whnf.arena &&
      !stateEq closedState header && !stateEq checkedState sortedState &&
      !stateEq sortedState got.state &&
      referencesEq got.state.whnf.declarations header.whnf.declarations)
  unless (← counter.get) - before == 8 do throw (IO.userError "analysis protocol assertion inventory")
  IO.println "PSC1_CONSTRUCTOR_ANALYSIS_SECTION protocol=8"

def main : IO Unit := do
  let counter ← IO.mkRef 0
  require counter "harness/constructor-tags"
    (errorIs "same" (some (.error "same") : Option (Except String String)) &&
      !errorIs "same" (some (.ok "same") : Option (Except String String)) &&
      !errorIs "same" (none : Option (Except String String)))
  IO.println "PSC1_CONSTRUCTOR_ANALYSIS_SECTION harness=1"
  analysisMatrix counter
  protocolMatrix counter
  unless (← counter.get) == 93 do throw (IO.userError "exact93 constructor analysis assertions required")
  IO.println "PSC1_ORDINARY_CONSTRUCTOR_ANALYSIS_NATIVE: PASS assertions=93 rows=12 fuelValues=6 fullAdmission=false"
