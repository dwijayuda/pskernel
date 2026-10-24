import Ps.KernelCore.API.DagOrdinaryConstructorLoop
import Ps.KernelCore.API.DagOrdinaryHeader
import Ps.KernelCore.Admission.Inductive.Ordinary.ConstructorAdmission
import Ps.KernelCore.Core.ExprV2.Decode
import Ps.KernelCore.Research.ExprV2PagedImport

/- Private constructor-loop qualification. Real-wrapper cases use the frozen
   V1 outer loop at the same RAW fuel. Callback protocols below test sequencing
   and ownership only; their fabricated analysis results are not admissions.
   No generated recursor or public atomic publication is claimed. -/

private def require (counter : IO.Ref Nat) (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_CONSTRUCTOR_LOOP_NATIVE_FAIL " ++ label))
  counter.modify (fun n => n + 1)
  IO.println ("PSC1_CONSTRUCTOR_LOOP_ASSERT " ++ label)

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def direct {α : Type} : Option (Except String α) → IO α
  | some (.ok value) => pure value
  | some (.error error) => throw (IO.userError error)
  | none => throw (IO.userError "unexpected private constructor loop decline")

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ .zero
private def s0 := PsKernelExpr.sort .zero
private def s1 := PsKernelExpr.sort one
private def target := nm "LoopT"
private def ctorName (index : Nat) := nm ("LoopT.c" ++ toString index)
private def t := PsKernelExpr.const target []
private def all (name : String) (domain body : PsKernelExpr)
    (info : PsKernelBinderInfo := .default) :=
  PsKernelExpr.forallE (nm name) domain body info
private def ti (index : PsKernelExpr) := PsKernelExpr.app t index
private def ph := all "A" s1 s1 .implicit
private def ih := all "i" s1 s1
private def parameterCtor := all "X" s1 (all "x" (.bvar 0) (ti (.bvar 1))) .implicit
private def admissionBudget := "simple inductive constructor admission budget exhausted"
private def resultError :=
  "simple inductive constructor must return the declared datatype with matching parameters and index arity"
private def nestedError :=
  "simple inductive admission does not yet support nested recursive occurrences"

private structure LoopCase where
  label : String
  header : PsKernelExpr
  numParams : Nat
  ctors : List PsKernelExpr
  expected : Except String (List (Nat × Nat × Nat))

private def loopCases : List LoopCase :=
  [ ⟨"empty-list",s1,0,[],.ok []⟩,
    ⟨"single-empty",s1,0,[t],.ok [(0,0,0)]⟩,
    ⟨"two-fields",s1,0,[all "p" s0 t,all "q" s0 (all "r" s0 t)],
      .ok [(1,0,0),(2,0,0)]⟩,
    ⟨"two-parameterized",ph,1,[parameterCtor,parameterCtor],
      .ok [(1,0,0),(1,0,0)]⟩,
    ⟨"indexed-recursive",ih,0,[ti s0,all "t" (ti s0) (ti s0)],
      .ok [(0,0,1),(1,1,1)]⟩,
    ⟨"late-free-variable",s1,0,[t,.fvar (nm "LoopFree")],
      .error "declaration has free variables"⟩,
    ⟨"late-wrong-result",s1,0,[t,s0],.error resultError⟩,
    ⟨"late-previous-reference",s1,0,
      [t,all "p" (.letE (nm "z") t (.const (ctorName 0) []) s0 false) t],
      .error nestedError⟩ ]

private structure Fixture where
  decl : PsKernelSimpleInductiveDecl
  oldHeader : PsKernelCheckerSession
  oldParams : List PsKernelOpenBinder
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  params : List PsKernelExprV2OrdinaryOpenBinder
  numIndices : Nat
  resultLevel : PsKernelLevel
  dagCtors : List PsKernelDagConstructor
  built : PsKernelExprV2Decoded

private def prepare (row : LoopCase) : IO Fixture := do
  -- Capture the validated original input before header-checker appends.
  let (headerArena,headerId) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty row.header)
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
  let built ← expect (psKernelExprV2DecodeChecked sourceArena)
  let initial := psKernelMkCheckerSession psKernelEnvironmentEmpty [] .safe 0 psKernelLeanNatMaxSizeDefault
  let checked ← expect (psKernelSessionCheck 4096 initial row.header)
  let sorted ← expect (psKernelSessionEnsureSort 4096 checked.snd checked.fst)
  let oldParams ← expect (psKernelOpenSimpleHeaderParams 4096 sorted.snd row.header row.numParams)
  let oldIndices ← expect (psKernelOpenSimpleHeaderIndices 4096 oldParams.session oldParams.result)
  let resultLevel ← match oldIndices.result with
    | .sort level => pure level
    | _ => throw (IO.userError "V1 header result is not a sort")
  let analysis ← direct (psKernelExprV2OrdinaryAnalyzeHeaderWithFuel 4096 psKernelEnvironmentEmpty
    0 psKernelLeanNatMaxSizeDefault sourceArena [] [] row.numParams ⟨target,headerId,[]⟩ false)
  let numIndices := analysis.indices.binders.length
  unless psKernelLevelEq resultLevel analysis.resultLevel && numIndices == oldIndices.binders.length do
    throw (IO.userError "header result universe or index arity mismatch")
  let info := PsKernelInductiveInfo.mk ⟨target,[],row.header⟩ row.numParams numIndices
    [target] (oldCtors.map (fun ctor => ctor.name)) 0 false false false
  let work := psKernelEnvironmentAddUnchecked psKernelEnvironmentEmpty (.inductInfo info)
  let parent := psKernelExprV2OrdinaryConstructorState analysis
  let ctx := psKernelExprV2OrdinaryConstructorContext analysis
  let context := PsKernelExprV2CheckContext.mk (psKernelCheckerContextWithEnvironment ctx.scalar work) ctx.locals
  let reference := PsKernelExprV2DeclarationRef.mk target [] headerId none .inductiveDecl
  let state := psKernelExprV2CheckStateWithWhnf parent
    ⟨parent.whnf.arena,parent.whnf.coreCache,parent.whnf.publicCache,reference :: parent.whnf.declarations⟩
  let decl := PsKernelSimpleInductiveDecl.mk [] target row.header oldCtors false row.numParams
  pure ⟨decl,oldParams.session,oldParams.binders,context,state,
    analysis.parameters.binders,numIndices,resultLevel,dagCtors,built⟩

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

private def ctorReference (levelParams : List PsKernelName) (ctor : PsKernelDagConstructor) :=
  PsKernelExprV2DeclarationRef.mk ctor.name levelParams ctor.type none .constructorDecl

private def expectedReferences (fixture : Fixture) :=
  fixture.dagCtors.foldl
    (fun refs ctor => ctorReference fixture.decl.levelParams ctor :: refs)
    fixture.state.whnf.declarations

private def loopEq (fixture : Fixture)
    (old : Except String PsKernelAddConstructorsResult)
    (actual : Option (Except String PsKernelExprV2OrdinaryConstructorsResult)) : Bool :=
  match old,actual with
  | .error left,some (.error right) => left == right
  | .ok left,some (.ok right) =>
      match psKernelExprV2DecodeChecked right.state.whnf.arena with
      | .error _ => false
      | .ok built =>
          sameList (shapeEq built) left.shapes right.shapes &&
          sameList (fun source shape => psKernelNameEq source.name shape.ctor.name &&
            source.type == shape.ctor.type) fixture.dagCtors right.shapes &&
          environmentEq left.environment right.context.scalar.environment &&
          contextSettingsEq fixture.context right.context &&
          semanticEq fixture.state right.state &&
          referencesEq (expectedReferences fixture) right.state.whnf.declarations &&
          arenaPrefix fixture.state.whnf.arena right.state.whnf.arena
  | _,_ => false

private def loopMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  unless loopCases.length == 8 &&
      (loopCases.filter (fun row => match row.expected with | .ok _ => true | _ => false)).length == 5 do
    throw (IO.userError "loop fixture inventory requires five positive and three negative rows")
  for row in loopCases do
    let fixture ← prepare row
    for fuel in [0,1,2,3,8,4096] do
      let old := psKernelAddSimpleConstructorsWithFuel fuel fixture.decl .safe fixture.resultLevel []
        fixture.oldParams fixture.numIndices fixture.oldHeader fixture.context.scalar.environment
        0 fixture.decl.ctors
      let actual := psKernelExprV2OrdinaryAddConstructorsWithFuel fuel fixture.built target
        fixture.decl.numParams false [] fixture.params fixture.numIndices fixture.resultLevel
        fixture.context fixture.state 0 fixture.dagCtors
      require counter ("matrix/" ++ row.label ++ "/rawFuel=" ++ toString fuel)
        (loopEq fixture old actual)
    let actual := psKernelExprV2OrdinaryAddConstructorsWithFuel 4096 fixture.built target
      fixture.decl.numParams false [] fixture.params fixture.numIndices fixture.resultLevel
      fixture.context fixture.state 0 fixture.dagCtors
    let correct := match row.expected,actual with
      | .error expected,some (.error got) => expected == got
      | .ok dimensions,some (.ok got) =>
          sameList (fun d shape => shape.fields.length == d.fst &&
            shape.recursiveFields.length == d.snd.fst &&
            shape.resultIndices.length == d.snd.snd) dimensions got.shapes &&
          (if row.label == "two-parameterized" then
            match got.shapes with
            | [first,second] =>
                match first.fields,second.fields with
                | [a],[b] => psKernelNameEq a.internalName b.internalName
                | _,_ => false
            | _ => false
          else true)
      | _,_ => false
    require counter ("matrix/" ++ row.label ++ "/required-outcome") correct
  unless (← counter.get) - before == 56 do throw (IO.userError "loop matrix assertion inventory")
  IO.println "PSC1_CONSTRUCTOR_LOOP_SECTION matrix=56"

private abbrev AnalysisCallback :=
  Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → PsKernelName →
  List PsKernelLevel → List PsKernelExprV2OrdinaryOpenBinder → Nat → PsKernelLevel →
  PsKernelDagConstructor → Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis)

private def callbackDecline : AnalysisCallback := fun _ _ _ _ _ _ _ _ _ => none
private def callbackError (message : String) : AnalysisCallback :=
  fun _ _ _ _ _ _ _ _ _ => some (.error message)
private def forbidden : AnalysisCallback := callbackError "UNEXPECTED_ANALYSIS"

private def errorIs {α : Type} (message : String) : Option (Except String α) → Bool
  | some (.error got) => message == got
  | _ => false

private def binderIdEq (left right : PsKernelExprV2OrdinaryOpenBinder) : Bool :=
  psKernelNameEq left.internalName right.internalName &&
    psKernelNameEq left.userName right.userName &&
    left.type == right.type && psKernelBinderInfoEq left.binderInfo right.binderInfo

private def shapeIdEq (left right : PsKernelExprV2OrdinaryConstructorShape) : Bool :=
  psKernelNameEq left.ctor.name right.ctor.name && left.ctor.type == right.ctor.type &&
    sameList binderIdEq left.fields right.fields &&
    sameList (fun a b => binderIdEq a.field b.field &&
      sameList binderIdEq a.arguments b.arguments && a.indices == b.indices)
      left.recursiveFields right.recursiveFields &&
    left.resultIndices == right.resultIndices

/- Distinct protocol-only markers exercise all seven semantic collections.
   They are never supplied to the real checker or published as judgments. -/
private def stamp (state : PsKernelExprV2CheckState) (fresh source result : Nat)
    (references : List PsKernelExprV2DeclarationRef) : PsKernelExprV2CheckState :=
  ⟨⟨state.whnf.arena,[⟨source,result,fresh+1⟩],[⟨source,result,fresh+2⟩],references⟩,
    fresh,[⟨source,result,fresh+3⟩],[⟨source,result,fresh+4⟩],
    [⟨source,result,fresh+5⟩],[⟨source,result,fresh+6⟩],[⟨source,result,fresh+7⟩]⟩

private def protocolMatrix (counter : IO.Ref Nat) : IO Unit := do
  let before ← counter.get
  let base ← prepare ⟨"protocol",s1,0,[t,t],.ok [(0,0,0),(0,0,0)]⟩
  let (first,second) ← match base.dagCtors with
    | [a,b] => pure (a,b)
    | _ => throw (IO.userError "two protocol constructors required")
  let (arena,sortId) ← expect (psKernelExprV2PagedMkSort base.state.whnf.arena one)
  let header := stamp (psKernelExprV2CheckStateWithArena base.state arena)
    37 first.type sortId base.state.whnf.declarations
  let (arena0,sort0) ← expect (psKernelExprV2PagedMkSort header.whnf.arena one)
  let fields0 : List PsKernelExprV2OrdinaryOpenBinder :=
    [⟨nm "LoopFake0",nm "f0",sortId,.default⟩]
  let fields1 : List PsKernelExprV2OrdinaryOpenBinder :=
    [⟨nm "LoopFake1",nm "f1",sortId,.default⟩,⟨nm "LoopFake2",nm "f2",sortId,.implicit⟩]
  let shape0 := PsKernelExprV2OrdinaryConstructorShape.mk first fields0 [] []
  let shape1 := PsKernelExprV2OrdinaryConstructorShape.mk second fields1 [] []
  let child0 := PsKernelExprV2OrdinaryConstructorAnalysis.mk
    (psKernelExprV2CheckContextWithLocal base.context (nm "LoopChild0") (nm "child") sort0 .default)
    (stamp (psKernelExprV2CheckStateWithArena header arena0) 101 first.type sort0 []) shape0
  -- Independent expected first publication, using fixed protocol field count1.
  let type0 ← expect (psKernelExprV2DecodedRequire base.built first.type)
  let info0 := PsKernelConstructorInfo.mk
    ⟨first.name,base.context.scalar.levelParams,type0⟩ target 0 0 1 false
  let work0 := psKernelEnvironmentAddUnchecked base.context.scalar.environment (.ctorInfo info0)
  let context0 := PsKernelExprV2CheckContext.mk
    (psKernelCheckerContextWithEnvironment base.context.scalar work0) base.context.locals
  let state0 := psKernelExprV2CheckStateWithWhnf header
    ⟨arena0,header.whnf.coreCache,header.whnf.publicCache,
      ctorReference base.context.scalar.levelParams first :: header.whnf.declarations⟩
  let (arena1,sort1) ← expect (psKernelExprV2PagedMkSort arena0 one)
  let child1 := PsKernelExprV2OrdinaryConstructorAnalysis.mk
    (psKernelExprV2CheckContextWithLocal context0 (nm "LoopChild1") (nm "child") sort1 .default)
    (stamp (psKernelExprV2CheckStateWithArena state0 arena1) 201 second.type sort1 []) shape1
  let type1 ← expect (psKernelExprV2DecodedRequire base.built second.type)
  let info1 := PsKernelConstructorInfo.mk
    ⟨second.name,base.context.scalar.levelParams,type1⟩ target 1 0 2 false
  let work1 := psKernelEnvironmentAddUnchecked work0 (.ctorInfo info1)
  let context1 := PsKernelExprV2CheckContext.mk
    (psKernelCheckerContextWithEnvironment base.context.scalar work1) base.context.locals
  let state1 := psKernelExprV2CheckStateWithWhnf header
    ⟨arena1,header.whnf.coreCache,header.whnf.publicCache,
      ctorReference base.context.scalar.levelParams second ::
        ctorReference base.context.scalar.levelParams first :: header.whnf.declarations⟩
  let run := fun fuel analyze built ctors =>
    psKernelExprV2OrdinaryAddConstructorsWorker fuel analyze built target 0 false [] []
      0 base.resultLevel base.context header 0 ctors
  let acceptFirst : AnalysisCallback := fun _ _ _ _ _ _ _ _ _ => some (.ok child0)
  let stages := fun (secondRoot : Nat)
      (secondResult : Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis)) =>
    (fun fuel context state nextTarget levels parameters numIndices resultLevel ctor =>
      if psKernelNameEq nextTarget target && levels.isEmpty && parameters.isEmpty &&
          numIndices == 0 && psKernelLevelEq resultLevel base.resultLevel then
        if psKernelNameEq ctor.name first.name then
          if fuel == 2 && ctor.type == first.type &&
              contextEq context base.context && stateEq state header then
            some (.ok child0)
          else some (.error "LOOP_FIRST_OWNER_OR_FUEL")
        else if psKernelNameEq ctor.name second.name then
          if fuel == 1 && ctor.type == secondRoot &&
              contextEq context context0 && stateEq state state0 then
            secondResult
          else some (.error "LOOP_SECOND_OWNER_OR_FUEL")
        else some (.error "LOOP_UNEXPECTED_CONSTRUCTOR")
      else some (.error "LOOP_ARGUMENT_PROTOCOL") : AnalysisCallback)
  -- These invalid snapshots/roots intentionally test internal error propagation;
  -- they do not satisfy the real-wrapper ownership precondition.
  require counter "protocol/zero-before-callbacks"
    (errorIs admissionBudget
      (run 0 forbidden psKernelExprV2DecodedEmpty [{ first with type := 999999 }]))
  let empty ← direct (run 1 forbidden psKernelExprV2DecodedEmpty [])
  require counter "protocol/positive-empty-identity"
    (contextEq empty.context base.context && stateEq empty.state header && empty.shapes.isEmpty)
  require counter "protocol/single-fuel-one-tail-exhaustion"
    (errorIs admissionBudget (run 1 acceptFirst base.built [first]))
  require counter "protocol/first-decline"
    ((run 3 callbackDecline psKernelExprV2DecodedEmpty [first,second]).isNone)
  require counter "protocol/first-error"
    (errorIs "first-sentinel"
      (run 3 (callbackError "first-sentinel") psKernelExprV2DecodedEmpty [first,second]))
  require counter "protocol/first-snapshot-error"
    (errorIs "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
      (run 3 acceptFirst psKernelExprV2DecodedEmpty [first,second]))
  require counter "protocol/second-decline-after-prefix"
    ((run 3 (stages second.type none) base.built [first,second]).isNone)
  require counter "protocol/second-error-after-prefix"
    (errorIs "second-sentinel"
      (run 3 (stages second.type (some (.error "second-sentinel"))) base.built [first,second]))
  require counter "protocol/second-snapshot-error-after-prefix"
    (errorIs "PSKERNEL_V2_DECODE_INVALID_REFERENCE"
      (run 3 (stages 999999 (some (.ok child1))) base.built
        [first,{ second with type := 999999 }]))
  let got ← direct (run 3 (stages second.type (some (.ok child1))) base.built [first,second])
  require counter "protocol/success-metadata-shape-order"
    (environmentEq got.context.scalar.environment work1 &&
      sameList shapeIdEq [shape0,shape1] got.shapes)
  require counter "protocol/success-header-owner-reset"
    (contextEq got.context context1 && stateEq got.state state1 &&
      got.state.nextFresh == 37 && got.state.whnf.arena.size == header.whnf.arena.size + 2 &&
      arenaPrefix header.whnf.arena got.state.whnf.arena &&
      !semanticEq got.state child0.state && !semanticEq got.state child1.state)
  let decoy := { child0 with shape := { shape0 with ctor := ⟨nm "LoopDecoy",sortId⟩ } }
  let installed ← expect (psKernelExprV2OrdinaryInstallConstructor
    base.built target 0 false 0 base.context header first decoy)
  require counter "protocol/install-original-root-pairing"
    (contextEq installed.fst context0 && stateEq installed.snd state0 &&
      (psKernelEnvironmentFind installed.fst.scalar.environment (nm "LoopDecoy")).isNone)
  unless (← counter.get) - before == 12 do throw (IO.userError "loop protocol assertion inventory")
  IO.println "PSC1_CONSTRUCTOR_LOOP_SECTION protocol=12"

def main : IO Unit := do
  let counter ← IO.mkRef 0
  require counter "harness/constructor-tags"
    (errorIs "same" (some (.error "same") : Option (Except String String)) &&
      !errorIs "same" (some (.ok "same") : Option (Except String String)) &&
      !errorIs "same" (none : Option (Except String String)))
  IO.println "PSC1_CONSTRUCTOR_LOOP_SECTION harness=1"
  loopMatrix counter
  protocolMatrix counter
  unless (← counter.get) == 69 do throw (IO.userError "exact69 constructor loop assertions required")
  IO.println "PSC1_ORDINARY_CONSTRUCTOR_LOOP_NATIVE: PASS assertions=69 rows=8 fuelValues=6 fullAdmission=false"
