import Ps.KernelCore.API.DagMutualRecursorValidation
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
  unless ok do throw (IO.userError ("PSC1_MUTUAL_RECURSOR_FAIL " ++ label))
  IO.println ("PSC1_MUTUAL_RECURSOR_ASSERT " ++ label)
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

private def fixture (resultLevel : PsKernelLevel) (isUnsafe : Bool) (fixtureTag : String) : IO (PsKernelExprV2MutualHeaderAnalysis ×
    PsKernelOpenBindersResult × List PsKernelSimpleMutualTypeShape) := do
  let first := PsKernelSimpleMutualTypeDecl.mk a (all "P" s1 (.sort resultLevel)) []
  let second := PsKernelSimpleMutualTypeDecl.mk b (all "P" s1 (all "i" s1 (.sort resultLevel))) []
  let third := PsKernelSimpleMutualTypeDecl.mk c (all "P" s1 (all "i" s1 (all "j" s1 (.sort resultLevel)))) []
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty [] (if isUnsafe then .unsafeDef else .safe)
    0 psKernelLeanNatMaxSizeDefault
  let checked ← expect (psKernelSessionCheck 256 session first.type)
  let sorted ← expect (psKernelSessionEnsureSort 256 checked.snd checked.fst)
  let parameters ← expect (psKernelOpenSimpleHeaderParams 256 sorted.snd first.type 1)
  let indices ← expect (psKernelOpenSimpleHeaderIndices 256 parameters.session parameters.result)
  let remaining ← expect (psKernelOpenSimpleMutualRemainingTypesWorker [second,third]
    256 psKernelEnvironmentEmpty [] (if isUnsafe then .unsafeDef else .safe) 0 psKernelLeanNatMaxSizeDefault
    parameters.session parameters.binders resultLevel)
  let shapes := PsKernelSimpleMutualTypeShape.mk first indices.binders :: remaining
  let mut arena := psKernelExprV2PagedEmpty
  let mut types := []
  for declaration in [first,second,third] do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena declaration.type)
    arena := next
    types := types ++ [PsKernelDagInductive.mk declaration.name root []]
  let actual ← direct (psKernelExprV2MutualAnalyzeHeaderWithFuel 256 psKernelEnvironmentEmpty
    0 psKernelLeanNatMaxSizeDefault arena [] ⟨[],1,types,isUnsafe⟩)
  require ("checked-shared-header-parameter-names-" ++ fixtureTag ++ "-" ++ (if psKernelLevelNormalizesToZero resultLevel then "prop" else "type") ++ (if isUnsafe then "-unsafe" else "-safe"))
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

private def fullConstantEq (left right : PsKernelConstantInfo) : Bool :=
  match left,right with
  | .recInfo x,.recInfo y => recursorEq x y
  | _,_ => constantEq left right
private def fullEnvironmentEq (left right : PsKernelEnvironment) : Bool :=
  left.quotInitialized == right.quotInitialized && left.runtime.nativeEvaluator.isNone &&
    right.runtime.nativeEvaluator.isNone && sameList fullConstantEq left.constants right.constants &&
    left.constants.all (fun original =>
      match psKernelEnvironmentFind left (psKernelConstantInfoName original),
          psKernelEnvironmentFind right (psKernelConstantInfoName original) with
      | some x,some y => fullConstantEq original x && fullConstantEq original y
      | _,_ => false)
private def validationEq (left : Except String Unit)
    (right : Option (Except String PsKernelExprV2OrdinaryAdmissionResult)) : Bool :=
  match left,right with
  | .ok _,some (.ok _) => true
  | .error a,some (.error b) => a == b
  | _,_ => false

private def recursorMatrix (tag : String) (isUnsafe : Bool)
    (analysis : PsKernelExprV2MutualHeaderAnalysis)
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
    let decl := PsKernelSimpleMutualInductiveDecl.mk [] 1 (oldShapes.map (·.decl)) isUnsafe
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
    let safety := if isUnsafe then PsKernelDefinitionSafety.unsafeDef else .safe
    let old ← expect (psKernelAddSimpleMutualTypesWorker oldShapes 256 safety analysis.resultLevel []
      parameters.binders [a,b,c] oldShapes parameters.session work 0)
    let actual ← direct (psKernelExprV2MutualAddConstructorsWithFuel 256 input context state
      [a,b,c] types [] analysis.parameters.binders analysis.resultLevel)
    let built ← expect (psKernelExprV2OrdinaryExtendDecoded actual.state.whnf.arena input)
    let header := {analysis with types := types}
    let data ← expect (psKernelExprV2MutualDecodeRecursorData input built header actual.shapes)
    let plan ← expect (psKernelExprV2MutualMakeRecursorPlan [] analysis.resultLevel isUnsafe data)
    let baseInfos := psKernelMakeSimpleMutualBaseInfos [a,b,c] decl oldShapes
    let originalWork1 := psKernelReplaceMutualInductiveInfos baseInfos
      (psKernelSimpleMutualHasRecursiveFields old.shapes)
      (psKernelSimpleMutualHasReflexiveFields old.shapes) old.environment
    let work1 := psKernelReplaceMutualInductiveInfos baseInfos
      (psKernelSimpleMutualHasRecursiveFields data.constructors)
      (psKernelSimpleMutualHasReflexiveFields data.constructors) actual.context.scalar.environment
    let owner := PsKernelDagGeneratedState.mk actual.state.whnf.arena built actual.state.whnf.declarations
    let originalWork2 := psKernelAddMutualRecursorInfos plan.infos originalWork1
    let label := tag ++ "-bundle-" ++ toString i
    for fuel in [0,1,8,256] do
      let left := psKernelValidateMutualRecursorInfosWorker plan.infos fuel originalWork2 plan.recLevelParams
        safety 0 psKernelLeanNatMaxSizeDefault plan.levels parameters.binders plan.motives plan.minors
        plan.ruleBinders old.shapes 0
      let right := psKernelExprV2MutualCheckRecursorsWithFuel fuel work1 0 psKernelLeanNatMaxSizeDefault isUnsafe owner plan
      require (label ++ "-actual-original-validation-fuel-" ++ toString fuel) (validationEq left right)
      if fuel == 256 then
        let result ← direct right
        require (label ++ "-all-generated-types-and-rules-checked")
          (match left with | .ok _ => true | _ => false)
        require (label ++ "-exact-original-final-environment") (fullEnvironmentEq originalWork2 result.environment)
        require (label ++ "-all-staged-type-and-rule-owners-live")
          (plan.infos.all (fun info =>
            match psKernelExprV2DeclarationRefFind result.owner.declarations info.base.name with
            | none => false
            | some reference =>
                psKernelNameListsEq reference.levelParams info.base.levelParams &&
                decodedEq result.owner.built info.base.type reference.type &&
                (match reference.kind with
                 | .recursorDecl rules => sameList (fun x y => psKernelNameEq x.ctor y.ctor &&
                     x.nFields == y.nFields && decodedEq result.owner.built x.rhs y.rhs) info.rules rules
                 | _ => false)))
    if i == 1 then
      let (first,later) ← match plan.infos with
        | [] => throw (IO.userError "missing generated infos")
        | head :: tail => pure (head,tail)
      let (firstRule,laterRules) ← match first.rules with
        | [] => throw (IO.userError "missing generated rule")
        | head :: tail => pure (head,tail)
      let changes := [
        ("bad-type",{first with base := {first.base with type := .mvar (nm "badType")}}),
        ("missing-rule",{first with rules := laterRules}),
        ("extra-rule",{first with rules := firstRule :: first.rules}),
        ("bad-rhs",{first with rules := {firstRule with rhs := .sort .zero} :: laterRules})]
      for (mutation,changed) in changes do
        let badPlan := {plan with infos := changed :: later}
        let badEnvironment := psKernelAddMutualRecursorInfos badPlan.infos originalWork1
        let left := psKernelValidateMutualRecursorInfosWorker badPlan.infos 256 badEnvironment badPlan.recLevelParams
          safety 0 psKernelLeanNatMaxSizeDefault badPlan.levels parameters.binders badPlan.motives badPlan.minors
          badPlan.ruleBinders old.shapes 0
        let right := psKernelExprV2MutualCheckRecursorsWithFuel 256 work1 0 psKernelLeanNatMaxSizeDefault isUnsafe owner badPlan
        require (label ++ "-reject-" ++ mutation ++ "-exact-original-error-no-success")
          (validationEq left right && (match left,right with | .error _,some (.error _) => true | _,_ => false))

private def protocols : IO Unit := do
  let (analysis,parameters,shapes) ← fixture (.succ .zero) false "protocol"
  let input ← expect (psKernelExprV2DecodeChecked analysis.arena)
  let data ← expect (psKernelExprV2MutualDecodeRecursorData input input analysis [])
  let plan ← expect (psKernelExprV2MutualMakeRecursorPlan [] analysis.resultLevel false data)
  let decl := PsKernelSimpleMutualInductiveDecl.mk [] 1 (shapes.map (·.decl)) false
  let environment := psKernelAddMutualInductiveInfos (psKernelMakeSimpleMutualBaseInfos [a,b,c] decl shapes) psKernelEnvironmentEmpty
  let references := analysis.types.map (fun h => PsKernelExprV2DeclarationRef.mk h.declaration.name [] h.declaration.type none .inductiveDecl)
  let parent := PsKernelDagGeneratedState.mk analysis.arena input references
  let staged ← expect (psKernelExprV2MutualStageRecursorsWorker plan.infos environment parent)
  let task ← match staged.tasks with | [] => throw (IO.userError "missing task") | head :: _ => pure head
  let context := psKernelExprV2OrdinaryFreshContext staged.environment plan.recLevelParams false 0 psKernelLeanNatMaxSizeDefault
  let state := psKernelExprV2OrdinaryFreshState staged.owner
  let poison := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (_state : PsKernelExprV2CheckState) (_root : Nat) => some (Except.error "UNEXPECTED_CHECK")
  let poisonEq := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (_state : PsKernelExprV2CheckState) (_left _right : Nat) => some (Except.error "UNEXPECTED_DEFEQ")
  require "protocol-empty-task-success-at-zero-no-callback"
    (match psKernelExprV2MutualCheckRecursorTasksWorker [] poison poison poisonEq 0 environment 0
        psKernelLeanNatMaxSizeDefault false plan parent 0 with | some (.ok _) => true | _ => false)
  let extra := PsKernelExprV2RecursorRuleRef.mk (nm "extra") 0 state.whnf.arena.size
  require "protocol-extra-rule-count-before-check"
    (match psKernelExprV2MutualValidateRulesWorker [] poison poisonEq 0 context state input plan 0 [extra] with
     | some (.error error) => error == "mutual recursor rule count mismatch" | _ => false)
  let ignored := PsKernelSimpleMutualConstructorShape.mk 1 (PsKernelSimpleConstructorDecl.mk (nm "ignored") s1) [] [] []
  require "protocol-skipped-other-family-preserves-empty-pending-and-fuel"
    (match psKernelExprV2MutualValidateRulesWorker [ignored] poison poisonEq 0 context state input plan 0 [] with
     | some (.ok _) => true | _ => false)
  let seeAll := fun (_fuel : Nat) (nextContext : PsKernelExprV2CheckContext)
      (nextState : PsKernelExprV2CheckState) (_root : Nat) =>
    let complete := plan.infos.all (fun info =>
      (match psKernelEnvironmentFind nextContext.scalar.environment info.base.name with | some (.recInfo _) => true | _ => false) &&
      (psKernelExprV2DeclarationRefFind nextState.whnf.declarations info.base.name).isSome)
    some (Except.error (if complete then "ALL_STAGED_BEFORE_FIRST_CHECK" else "MISSING_STAGED"))
  require "protocol-all-family-metadata-and-refs-before-first-type-check"
    (match psKernelExprV2MutualCheckRecursorsWith seeAll poison poisonEq 256 environment 0 psKernelLeanNatMaxSizeDefault false parent plan with
     | some (.error error) => error == "ALL_STAGED_BEFORE_FIRST_CHECK" | _ => false)
  let grow := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (next : PsKernelExprV2CheckState) (root : Nat) => some (Except.ok ({next with nextFresh := 777},root))
  let seeSort := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (next : PsKernelExprV2CheckState) (_root : Nat) => some (Except.error
        (if next.nextFresh == 777 then "SORT_SAW_CHECKED_OWNER" else "WRONG_SORT_OWNER"))
  require "protocol-mandatory-sort-uses-complete-post-check-owner"
    (match psKernelExprV2MutualCheckRecursorsWith grow seeSort poisonEq 256 environment 0 psKernelLeanNatMaxSizeDefault false parent plan with
     | some (.error error) => error == "SORT_SAW_CHECKED_OWNER" | _ => false)
  let sort ← expect (psKernelExprV2PagedMkSort staged.owner.arena (.succ .zero))
  let stagedOwner := {staged.owner with arena := sort.fst}
  let sortWhnf := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (next : PsKernelExprV2CheckState) (_root : Nat) => some (Except.ok
        (psKernelExprV2CheckStateWithArena next sort.fst,sort.snd))
  let seeFresh := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (next : PsKernelExprV2CheckState) (root : Nat) =>
    if root == task.type then some (Except.ok ({next with nextFresh := 999},sort.snd))
    else some (Except.error (if next.nextFresh == 0 then "NEXT_TYPE_OWNER_FRESH" else "LEAKED_FRESHNESS"))
  require "protocol-next-recursor-has-fresh-caches-and-counter"
    (match psKernelExprV2MutualCheckRecursorTasksWorker staged.tasks seeFresh sortWhnf poisonEq 256 staged.environment
        0 psKernelLeanNatMaxSizeDefault false plan stagedOwner 0 with
     | some (.error error) => error == "NEXT_TYPE_OWNER_FRESH" | _ => false)
  require "protocol-private-error-does-not-publish-to-input-environment"
    (plan.infos.all (fun info => (psKernelEnvironmentFind environment info.base.name).isNone))
  require "protocol-original-parameter-owner-remains-unmodified"
    (analysis.parameters.state.nextFresh == parameters.session.state.nextFresh && parent.declarations.length == 3)

def main : IO Unit := do
  for (kind,resultLevel) in [("prop",PsKernelLevel.zero),("type",PsKernelLevel.succ .zero)] do
    for unsafeFlag in [false,true] do
      let tag := kind ++ (if unsafeFlag then "-unsafe" else "-safe")
      let (analysis,parameters,shapes) ← fixture resultLevel unsafeFlag "matrix"
      recursorMatrix tag unsafeFlag analysis parameters shapes
  protocols
  IO.println "PSC1_MUTUAL_RECURSOR_NATIVE: PASS assertions=169 actualValidation=80 checkedBundles=20 finalOwners=40 mutations=16 protocols=8 headers=5"
