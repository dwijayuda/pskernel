import Ps.KernelCore.API.DagMutualConstructorLoop
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
  unless ok do throw (IO.userError ("PSC1_MUTUAL_LOOP_FAIL " ++ label))
  IO.println ("PSC1_MUTUAL_LOOP_ASSERT " ++ label)
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

private def fixture : IO (PsKernelExprV2MutualHeaderAnalysis ×
    PsKernelOpenBindersResult × List PsKernelSimpleMutualTypeShape) := do
  let first := PsKernelSimpleMutualTypeDecl.mk a rootType []
  let second := PsKernelSimpleMutualTypeDecl.mk b secondType []
  let third := PsKernelSimpleMutualTypeDecl.mk c thirdType []
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty [] .safe
    0 psKernelLeanNatMaxSizeDefault
  let checked ← expect (psKernelSessionCheck 256 session first.type)
  let sorted ← expect (psKernelSessionEnsureSort 256 checked.snd checked.fst)
  let parameters ← expect (psKernelOpenSimpleHeaderParams 256 sorted.snd first.type 1)
  let indices ← expect (psKernelOpenSimpleHeaderIndices 256 parameters.session parameters.result)
  let remaining ← expect (psKernelOpenSimpleMutualRemainingTypesWorker [second,third]
    256 psKernelEnvironmentEmpty [] .safe 0 psKernelLeanNatMaxSizeDefault
    parameters.session parameters.binders (.succ .zero))
  let shapes := PsKernelSimpleMutualTypeShape.mk first indices.binders :: remaining
  let mut arena := psKernelExprV2PagedEmpty
  let mut types := []
  for declaration in [first,second,third] do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena declaration.type)
    arena := next
    types := types ++ [PsKernelDagInductive.mk declaration.name root []]
  let actual ← direct (psKernelExprV2MutualAnalyzeHeaderWithFuel 256 psKernelEnvironmentEmpty
    0 psKernelLeanNatMaxSizeDefault arena [] ⟨[],1,types,false⟩)
  require "checked-shared-header-parameter-names"
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

private def sameLoop (left : Except String PsKernelAddMutualConstructorsResult)
    (right : Option (Except String PsKernelExprV2MutualConstructorsResult)) : IO Bool := do
  match left,right with
  | .error a,some (.error b) => pure (a == b)
  | .ok a,some (.ok b) =>
      let arena := b.state.whnf.arena
      let mut equal := environmentEq a.environment b.context.scalar.environment && a.shapes.length == b.shapes.length
      for (x,y) in a.shapes.zip b.shapes do
        equal := equal && x.owner == y.owner && psKernelNameEq x.ctor.name y.ctor.name &&
          psKernelExprEqual x.ctor.type (← decode arena y.ctor.type) &&
          x.fields.length == y.fields.length && x.recursiveFields.length == y.recursiveFields.length &&
          x.resultIndices.length == y.resultIndices.length
        for (v,w) in x.fields.zip y.fields do equal := equal && (← sameBinder arena v w)
        for (v,w) in x.resultIndices.zip y.resultIndices do
          equal := equal && psKernelExprEqual v (← decode arena w)
        for (v,w) in x.recursiveFields.zip y.recursiveFields do
          equal := equal && (← sameBinder arena v.field w.field) && v.target == w.target &&
            v.args.length == w.arguments.length && v.indices.length == w.indices.length
          for (z,t) in v.args.zip w.arguments do equal := equal && (← sameBinder arena z t)
          for (z,t) in v.indices.zip w.indices do
            equal := equal && psKernelExprEqual z (← decode arena t)
      pure equal
  | _,_ => pure false

private def loopMatrix (analysis : PsKernelExprV2MutualHeaderAnalysis)
    (parameters : PsKernelOpenBindersResult) (shapes : List PsKernelSimpleMutualTypeShape) : IO Unit := do
  let ap := fun n => psKernelApplyArgs (.const a []) [.bvar n]
  let bp := fun n => psKernelApplyArgs (.const b []) [.bvar n,.bvar n]
  let cp := fun n => psKernelApplyArgs (.const c []) [.bvar n,.bvar n,.bvar n]
  let close := fun body => all "P" s1 body
  let rows := [
    [[],[],[]],
    [[close (ap 0)],[close (bp 0)],[close (cp 0)]],
    [[close (ap 0),close (all "f" (ap 0) (ap 1))],[close (bp 0)],[]],
    [[close (all "f" (bp 0) (ap 1))],[close (all "f" (cp 0) (bp 1))],[close (all "f" (ap 0) (cp 1))]],
    [[close (all "f" (all "x" (.bvar 0) (ap 1)) (ap 1))],[],[close (cp 0)]],
    [[close (ap 0)],[close (bp 0)],[close (ap 0)]],
    [[close (ap 0)],[.mvar (nm "badLater")],[]],
    [[close (all "f" s2 (ap 1))],[],[]]]
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
    for fuel in [0,1,8,256] do
      let left := psKernelAddSimpleMutualTypesWorker oldShapes fuel .safe analysis.resultLevel []
        parameters.binders [a,b,c] oldShapes parameters.session work 0
      let right := psKernelExprV2MutualAddConstructorsWithFuel fuel input context state
        [a,b,c] types [] analysis.parameters.binders analysis.resultLevel
      require ("frozen-original-loop-" ++ toString i ++ "-fuel-" ++ toString fuel) (← sameLoop left right)
      if i == 0 && fuel == 0 then
        require "empty-families-succeed-at-zero-checker-fuel"
          (match right with | some (.ok _) => true | _ => false)
      if fuel == 256 then
        if i < 5 then
          let result ← direct right
          require ("all-header-semantic-caches-and-freshness-retained-" ++ toString i)
            (semanticEq state result.state && result.context.locals.length == context.locals.length &&
              (context.locals.zip result.context.locals).all (fun (x,y) => psKernelNameEq x.name y.name && x.type == y.type))
          require ("original-constructor-root-references-retained-" ++ toString i)
            (types.all (fun h => h.declaration.ctors.all (fun ctor =>
              match psKernelExprV2DeclarationRefFind result.state.whnf.declarations ctor.name with
              | none => false
              | some reference => reference.type == ctor.type && reference.deltaValue.isNone)))
          require ("constructor-indices-reset-per-family-" ++ toString i)
            ((types.zipIdx).all (fun (h,owner) => (h.declaration.ctors.zipIdx).all (fun (ctor,index) =>
              match psKernelEnvironmentFind result.context.scalar.environment ctor.name with
              | some (.ctorInfo info) => info.cidx == index && psKernelNameEq info.induct h.declaration.name &&
                  info.numParams == 1 && (result.shapes.any (fun shape => shape.owner == owner && psKernelNameEq shape.ctor.name ctor.name))
              | _ => false)))
        else
          require ("late-original-error-has-no-private-success-" ++ toString i)
            (match right with | some (.error _) => true | _ => false)

def main : IO Unit := do
  let (analysis,parameters,shapes) ← fixture
  loopMatrix analysis parameters shapes
  IO.println "PSC1_MUTUAL_LOOP_NATIVE: PASS assertions=52 frozen=32 owners=15 errors=3 zero=1 header=1"
