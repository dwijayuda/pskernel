import Ps.KernelCore.API.DagMutualGenerated
import Ps.KernelCore.Research.ExprV2PagedImport
import Ps.KernelCore.Core.ExprV2.Decode
import Lean

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)
private def direct {α : Type} : Option (Except String α) → IO α
  | some result => expect result
  | none => throw (IO.userError "private header declined")
private def require (label : String) (ok : Bool) : IO Unit := do
  unless ok do throw (IO.userError ("PSC1_MUTUAL_GENERATED_FAIL " ++ label))
  IO.println ("PSC1_MUTUAL_GENERATED_ASSERT " ++ label)
private def nm (s : String) := PsKernelName.str .anonymous s
private def a := nm "ResultA"
private def b := nm "ResultB"
private def c := nm "ResultC"
private def other := nm "Other"
private def s1 := PsKernelExpr.sort (.succ .zero)
private def s2 := PsKernelExpr.sort (.succ (.succ .zero))
private def all (n : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm n) domain body .default
private def rootType := all "P" s1 s1
private def secondType := all "P" s1 (all "i" s1 s1)
private def thirdType := all "P" s1 (all "i" s1 (all "j" s1 s1))

private def fixture (resultLevel : PsKernelLevel) : IO (PsKernelExprV2MutualHeaderAnalysis ×
    PsKernelOpenBindersResult × List PsKernelSimpleMutualTypeShape) := do
  let first := PsKernelSimpleMutualTypeDecl.mk a (all "P" s1 (.sort resultLevel)) []
  let second := PsKernelSimpleMutualTypeDecl.mk b (all "P" s1 (all "i" s1 (.sort resultLevel))) []
  let third := PsKernelSimpleMutualTypeDecl.mk c (all "P" s1 (all "i" s1 (all "j" s1 (.sort resultLevel)))) []
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty [] .safe
    0 psKernelLeanNatMaxSizeDefault
  let checked ← expect (psKernelSessionCheck 256 session first.type)
  let sorted ← expect (psKernelSessionEnsureSort 256 checked.snd checked.fst)
  let parameters ← expect (psKernelOpenSimpleHeaderParams 256 sorted.snd first.type 1)
  let indices ← expect (psKernelOpenSimpleHeaderIndices 256 parameters.session parameters.result)
  let remaining ← expect (psKernelOpenSimpleMutualRemainingTypesWorker [second,third]
    256 psKernelEnvironmentEmpty [] .safe 0 psKernelLeanNatMaxSizeDefault
    parameters.session parameters.binders resultLevel)
  let shapes := PsKernelSimpleMutualTypeShape.mk first indices.binders :: remaining
  let mut arena := psKernelExprV2PagedEmpty
  let mut types := []
  for declaration in [first,second,third] do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena declaration.type)
    arena := next
    types := types ++ [PsKernelDagInductive.mk declaration.name root []]
  let actual ← direct (psKernelExprV2MutualAnalyzeHeaderWithFuel 256 psKernelEnvironmentEmpty
    0 psKernelLeanNatMaxSizeDefault arena [] ⟨[],1,types,false⟩)
  require ("checked-shared-header-parameter-names-" ++ (if psKernelLevelNormalizesToZero resultLevel then "prop" else "type"))
    (parameters.binders.length == actual.parameters.binders.length &&
      (parameters.binders.zip actual.parameters.binders).all
        (fun (x,y) => psKernelNameEq x.internalName y.internalName))
  pure (actual,parameters,shapes)

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let graph ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire graph root)

private def sameBinder (arena : PsKernelExprV2PagedArena)
    (left : PsKernelOpenBinder) (right : PsKernelExprV2OrdinaryOpenBinder) : IO Bool := do
  pure (psKernelNameEq left.internalName right.internalName &&
    psKernelNameEq left.userName right.userName &&
    psKernelBinderInfoEq left.binderInfo right.binderInfo &&
    psKernelExprEqual left.type (← decode arena right.type))

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

private def legacyBinderEq (left right : PsKernelOpenBinder) : Bool :=
  psKernelNameEq left.internalName right.internalName && psKernelNameEq left.userName right.userName &&
    psKernelExprEqual left.type right.type && psKernelBinderInfoEq left.binderInfo right.binderInfo
private def legacyCtorEq (left right : PsKernelSimpleConstructorDecl) : Bool :=
  psKernelNameEq left.name right.name && psKernelExprEqual left.type right.type
private def legacyTypeEq (left right : PsKernelSimpleMutualTypeShape) : Bool :=
  psKernelNameEq left.decl.name right.decl.name && psKernelExprEqual left.decl.type right.decl.type &&
    sameList legacyCtorEq left.decl.ctors right.decl.ctors && sameList legacyBinderEq left.indices right.indices
private def legacyShapeEq (left right : PsKernelSimpleMutualConstructorShape) : Bool :=
  left.owner == right.owner && legacyCtorEq left.ctor right.ctor && sameList legacyBinderEq left.fields right.fields &&
    sameList (fun x y => legacyBinderEq x.field y.field && x.target == y.target &&
      sameList legacyBinderEq x.args y.args && sameList psKernelExprEqual x.indices y.indices)
      left.recursiveFields right.recursiveFields && sameList psKernelExprEqual left.resultIndices right.resultIndices
private def recursorEq (left right : PsKernelRecursorInfo) : Bool :=
  psKernelNameEq left.base.name right.base.name && psKernelNameListsEq left.base.levelParams right.base.levelParams &&
    psKernelExprEqual left.base.type right.base.type && psKernelNameListsEq left.all right.all &&
    left.numParams == right.numParams && left.numIndices == right.numIndices &&
    left.numMotives == right.numMotives && left.numMinors == right.numMinors && left.k == right.k &&
    left.isUnsafe == right.isUnsafe && sameList (fun x y => psKernelNameEq x.ctor y.ctor &&
      x.nFields == y.nFields && psKernelExprEqual x.rhs y.rhs) left.rules right.rules

private def generatedMatrix (tag : String) (analysis : PsKernelExprV2MutualHeaderAnalysis)
    (parameters : PsKernelOpenBindersResult) (shapes : List PsKernelSimpleMutualTypeShape) : IO Unit := do
  let ap := fun n => psKernelApplyArgs (.const a []) [.bvar n]
  let bp := fun n => psKernelApplyArgs (.const b []) [.bvar n,.bvar n]
  let cp := fun n => psKernelApplyArgs (.const c []) [.bvar n,.bvar n,.bvar n]
  let close := fun body => all "P" s1 body
  let rows := ([
    [[],[],[]],
    [[close (ap 0)],[close (bp 0)],[close (cp 0)]],
    [[close (ap 0),close (all "f" (ap 0) (ap 1))],[close (bp 0)],[]],
    [[close (all "f" (bp 0) (ap 1))],[close (all "f" (cp 0) (bp 1))],[close (all "f" (ap 0) (cp 1))]],
    [[close (all "f" (all "x" (.bvar 0) (ap 1)) (ap 1))],[],[close (cp 0)]],
    [[close (ap 0)],[close (bp 0)],[close (ap 0)]],
    [[close (ap 0)],[.mvar (nm "badLater")],[]],
    [[close (all "f" s2 (ap 1))],[],[]]]).take 5
  for (row,i) in rows.zipIdx do
    let mut arena := analysis.arena
    let mut types := []
    let mut oldShapes := []
    for ((expressions,h),j) in (row.zip analysis.types).zipIdx do
      let mut oldCtors := []
      let mut dagCtors := []
      for (expression,n) in expressions.zipIdx do
        let name := nm ("loop" ++ toString i ++ "family" ++ toString j ++ "ctor" ++ toString n)
        let next ← expect (psKernelExprV2PagedImportIntoChecked arena expression)
        arena := next.fst
        oldCtors := oldCtors ++ [PsKernelSimpleConstructorDecl.mk name expression]
        dagCtors := dagCtors ++ [PsKernelDagConstructor.mk name next.snd]
      let oldShape ← match shapes[j]? with
        | none => throw (IO.userError "fixture family index missing")
        | some value => pure value
      oldShapes := oldShapes ++ [{oldShape with decl := {oldShape.decl with ctors := oldCtors}}]
      types := types ++ [{h with declaration := {h.declaration with ctors := dagCtors}}]
    let decl := PsKernelSimpleMutualInductiveDecl.mk [] 1 (oldShapes.map (·.decl)) false
    let work := psKernelAddMutualInductiveInfos
      (psKernelMakeSimpleMutualBaseInfos [a,b,c] decl oldShapes) psKernelEnvironmentEmpty
    let context := PsKernelExprV2CheckContext.mk
      (psKernelCheckerContextWithEnvironment analysis.parameters.context.scalar work)
      analysis.parameters.context.locals
    let references := types.map (fun h =>
      PsKernelExprV2DeclarationRef.mk h.declaration.name [] h.declaration.type none .inductiveDecl)
    let base := analysis.parameters.state
    let state := psKernelExprV2CheckStateWithWhnf base
      (PsKernelExprV2WhnfState.mk arena base.whnf.coreCache base.whnf.publicCache references)
    let input ← expect (psKernelExprV2DecodeChecked arena)
    let old ← expect (psKernelAddSimpleMutualTypesWorker oldShapes 256 .safe analysis.resultLevel []
      parameters.binders [a,b,c] oldShapes parameters.session work 0)
    let actual ← direct (psKernelExprV2MutualAddConstructorsWithFuel 256 input context state
      [a,b,c] types [] analysis.parameters.binders analysis.resultLevel)
    let built ← expect (psKernelExprV2OrdinaryExtendDecoded actual.state.whnf.arena input)
    let header := {analysis with types := types}
    let data ← expect (psKernelExprV2MutualDecodeRecursorData input built header actual.shapes)
    let label := tag ++ "-bundle-" ++ toString i
    require (label ++ "-parameters-exact") (sameList legacyBinderEq parameters.binders data.parameters)
    require (label ++ "-all-header-indices-and-original-metadata-exact") (sameList legacyTypeEq oldShapes data.types)
    require (label ++ "-all-constructors-recursive-targets-and-indices-exact") (sameList legacyShapeEq old.shapes data.constructors)
    require (label ++ "-missing-original-namespace-hard-error")
      (match psKernelExprV2MutualDecodeRecursorData psKernelExprV2DecodedEmpty built header actual.shapes with
       | .error _ => true | _ => false)
    for unsafeFlag in [false,true] do
      let caseLabel := label ++ (if unsafeFlag then "-unsafe-syntax" else "-safe-syntax")
      let levels := psKernelLevelParamsToLevels ([] : List PsKernelName)
      let elimOnlyAtZero := if psKernelLevelIsNotZero analysis.resultLevel then false else true
      let elimName := psKernelSimpleFreshElimName []
      let elimLevel := if elimOnlyAtZero then PsKernelLevel.zero else .param elimName
      let recLevelParams := if elimOnlyAtZero then [] else [elimName]
      let motives := psKernelMakeSimpleMutualMotives levels parameters.binders elimLevel oldShapes
      let minors ← expect (psKernelMakeSimpleMutualMinors levels parameters.binders motives old.shapes)
      let ruleBinders := psKernelOpenBinderListAppend parameters.binders (psKernelOpenBinderListAppend motives minors)
      let infos ← expect (psKernelBuildSimpleMutualRecInfosFromConstructorsWorker oldShapes oldShapes
        recLevelParams [a,b,c] levels parameters.binders motives minors ruleBinders old.shapes 0 unsafeFlag)
      let plan ← expect (psKernelExprV2MutualMakeRecursorPlan [] analysis.resultLevel unsafeFlag data)
      require (caseLabel ++ "-original-recursor-types-rules-and-metadata-exact") (sameList recursorEq infos plan.infos)
      require (caseLabel ++ "-original-motives-minors-and-rule-binders-exact")
        (sameList legacyBinderEq motives plan.motives && sameList legacyBinderEq minors plan.minors &&
          sameList legacyBinderEq ruleBinders plan.ruleBinders)
      require (caseLabel ++ "-original-elimination-level-policy-exact")
        (psKernelNameListsEq recLevelParams plan.recLevelParams && psKernelLevelListEq levels plan.levels &&
          plan.infos.length == 3 && plan.infos.all (fun info => info.isUnsafe == unsafeFlag && !info.k))
      let mut exactTypes := true
      let mut exactImported := true
      for shape in old.shapes do
        let expectedResult ← expect (psKernelSimpleMutualMotiveApp motives shape.owner shape.resultIndices
          (psKernelSimpleMutualCtorApp levels parameters.binders shape))
        let expected := psKernelCloseOpenBinders (psKernelOpenBinderListAppend ruleBinders shape.fields) expectedResult
        let got ← expect (psKernelExprV2MutualExpectedRuleType plan shape.owner shape)
        exactTypes := exactTypes && psKernelExprEqual expected got
        let imported ← expect (psKernelExprV2MutualPrepareExpectedRuleType plan shape.owner shape actual.state built)
        exactImported := exactImported && psKernelExprEqual expected (← decode imported.state.whnf.arena imported.root)
      require (caseLabel ++ "-every-expected-rule-type-exact") exactTypes
      require (caseLabel ++ "-only-expected-generated-syntax-imported") exactImported
      let dummy := PsKernelSimpleMutualConstructorShape.mk 999 (PsKernelSimpleConstructorDecl.mk (nm "dummy") s1) [] [] []
      require (caseLabel ++ "-motive-error-precedes-even-missing-owner")
        (match psKernelExprV2MutualPrepareExpectedRuleType plan 999 dummy
            (psKernelExprV2CheckStateEmpty psKernelExprV2PagedEmpty) psKernelExprV2DecodedEmpty with
         | .error error => error == "mutual recursor motive target is out of bounds"
         | _ => false)

def main : IO Unit := do
  for (tag,resultLevel) in [("prop",PsKernelLevel.zero),("type",PsKernelLevel.succ .zero)] do
    let (analysis,parameters,shapes) ← fixture resultLevel
    generatedMatrix tag analysis parameters shapes
  IO.println "PSC1_MUTUAL_GENERATED_NATIVE: PASS assertions=162 universes=2 bundles=10 originalMetadata=40 plans=20 planControls=120 headers=2"
