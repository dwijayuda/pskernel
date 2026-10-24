import Ps.KernelCore.API.DagOrdinaryHeader
import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- T05 infrastructure slice only. A successful direct header analysis is not
   complete inductive admission. No test below lets public fallback supply a
   direct-worker success. The V1 reference is the frozen header prefix of
   Admission/Inductive/Ordinary/Admission.lean at
   0d9f062846d109c362210d441df5fd407ca2cdd7, ending before initialInfo/work0.
   Frozen original Git blob: cb2e3a74cbf9ccc8a8484d1bc31d5ed82eda6490.
   It calls the retained V1 helpers, never the new DAG header helpers. -/

private def require (label : String) (ok : Bool) : IO Unit := do
  unless ok do throw (IO.userError ("PSC1_ORDINARY_HEADER_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def direct {α : Type} (label : String) : Option (Except String α) → IO α
  | some (.ok value) => pure value
  | some (.error error) => throw (IO.userError (label ++ ": " ++ error))
  | none => throw (IO.userError ("unexpected direct-header decline: " ++ label))

private def sameExcept {α : Type} (equal : α → α → Bool) :
    Except String α → Except String α → Bool
  | .error left,.error right => left == right
  | .ok left,.ok right => equal left right
  | _,_ => false
private def sameUnit := sameExcept (fun (_ _ : Unit) => true)

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ .zero
private def s0 := PsKernelExpr.sort .zero
private def s1 := PsKernelExpr.sort one
private def s2 := PsKernelExpr.sort (.succ one)
private def all (name : String) (domain body : PsKernelExpr)
    (info : PsKernelBinderInfo := .default) :=
  PsKernelExpr.forallE (nm name) domain body info
private def apps := psKernelApplyArgs
private def owner := nm "T05Header"
private def u := nm "u"
private def v := nm "v"
private def mkDecl (type : PsKernelExpr) (params : Nat := 0)
    (levels : List PsKernelName := []) (ctors : List PsKernelExpr := []) :=
  PsKernelSimpleInductiveDecl.mk levels owner type
    ((ctors.zipIdx).map (fun (type,index) =>
      PsKernelSimpleConstructorDecl.mk (.num (.str owner "mk") index) type)) false params

private structure OldHeader where
  parameters : PsKernelOpenBindersResult
  indices : PsKernelOpenBindersResult
  resultLevel : PsKernelLevel

private def frozenV1Header (fuel : Nat) (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl) (depth maxNat : Nat) : Except String OldHeader := do
  if psKernelNameHasDuplicates decl.levelParams then
    throw "duplicate universe parameter"
  let names := decl.name :: psKernelSimpleRecName decl.name :: psKernelSimpleCtorNames decl.ctors
  if !psKernelSimpleNameListUnique names then
    throw "duplicate inductive, constructor, or recursor name"
  psKernelCheckFreshInductiveNames names environment
  psKernelSimpleCheckUniformOccurrences [decl.name] decl.levelParams decl.numParams
    (psKernelSimpleCtorTypes decl.ctors)
  psKernelCheckNoMVarNoFVar decl.type
  psKernelCheckLevelParams decl.type decl.levelParams
  let safety := if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else .safe
  let session := psKernelMkCheckerSession environment decl.levelParams safety depth maxNat
  let checked ← psKernelSessionCheck fuel session decl.type
  let sorted ← psKernelSessionEnsureSort fuel checked.snd checked.fst
  let parameters ← psKernelOpenSimpleHeaderParams fuel sorted.snd decl.type decl.numParams
  let indices ← psKernelOpenSimpleHeaderIndices fuel parameters.session parameters.result
  match indices.result with
  | .sort level => pure ⟨parameters,indices,level⟩
  | _ => throw "simple inductive result must be a sort"

private def build (decl : PsKernelSimpleInductiveDecl) :
    IO (PsKernelExprV2PagedArena × PsKernelDagInductive) := do
  let (initial,root) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty decl.type)
  let mut arena := initial
  let mut ctors := []
  for ctor in decl.ctors do
    let (next,type) ← expect (psKernelExprV2PagedImportIntoChecked arena ctor.type)
    arena := next
    ctors := ctors ++ [PsKernelDagConstructor.mk ctor.name type]
  pure (arena,⟨decl.name,root,ctors⟩)

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let graph ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire graph root)

private def sameOpen (old : PsKernelOpenBindersResult)
    (actual : PsKernelExprV2OrdinaryOpenResult) : IO Bool := do
  if old.binders.length != actual.binders.length then return false
  if old.session.state.nextFresh != actual.state.nextFresh then return false
  if !psKernelExprEqual old.result (← decode actual.state.whnf.arena actual.result) then return false
  for (left,right) in old.binders.zip actual.binders do
    if !psKernelNameEq left.internalName right.internalName ||
        !psKernelNameEq left.userName right.userName ||
        !psKernelBinderInfoEq left.binderInfo right.binderInfo ||
        !psKernelExprEqual left.type (← decode actual.state.whnf.arena right.type) then return false
  pure true

private def compareHeader (label : String) (old : Except String OldHeader)
    (actual : Option (Except String PsKernelExprV2OrdinaryHeaderAnalysis)) : IO Unit := do
  match old,actual with
  | .error a,some (.error b) => require (label ++ "-exact-error") (a == b)
  | .ok a,some (.ok b) =>
      require (label ++ "-parameters") (← sameOpen a.parameters b.parameters)
      require (label ++ "-indices") (← sameOpen a.indices b.indices)
      require (label ++ "-level") (psKernelLevelEq a.resultLevel b.resultLevel)
  | _,none => throw (IO.userError ("header fallback is not a pass: " ++ label))
  | _,_ => throw (IO.userError ("header outcome mismatch: " ++ label))

private def positiveDecls : List (String × PsKernelSimpleInductiveDecl) :=
  let self := PsKernelExpr.const owner []
  let selfU := PsKernelExpr.const owner [.param u]
  [ ("enum",mkDecl s1 0 [] [self]),
    ("parameter",mkDecl (all "A" s1 s1 .implicit) 1 []
      [all "A" s1 (all "value" (.bvar 0) (apps self [.bvar 1]))]),
    ("dependent-index",mkDecl (all "A" s1 (all "a" (.bvar 0) s1 .strictImplicit)) 1 []
      [all "A" s1 (all "a" (.bvar 0) (apps self [.bvar 1,.bvar 0]))]),
    ("universe",mkDecl (all "A" (.sort (.param u)) (.sort (.param u))) 1 [u]
      [all "A" (.sort (.param u)) (all "value" (.bvar 0) (apps selfU [.bvar 1]))]),
    ("two-parameters",mkDecl (all "A" s1 (all "B" s1 s1 .instImplicit)) 2 []
      [all "A" s1 (all "B" s1 (apps self [.bvar 1,.bvar 0]))]),
    ("zero-parameter-index",mkDecl (all "A" s1 s1) 0),
    ("metadata",mkDecl (.mdata 71 s1) 0 [] [self]),
    ("beta",mkDecl (.app (.lam (nm "T") s2 (.bvar 0) .default) s1) 0 [] [self]),
    ("let",mkDecl (.letE (nm "T") s2 s1 (.bvar 0) false) 0 [] [self]),
    ("unsafe-header",{ mkDecl s1 0 [] [self] with isUnsafe := true }) ]

private def negativeDecls : List (String × PsKernelSimpleInductiveDecl) :=
  [ ("duplicate-level-first",mkDecl (.mvar (nm "m")) 1 [u,u] [.const owner []]),
    ("uniform-before-header-mvar",mkDecl (.mvar (nm "m")) 1 [] [.const owner []]),
    ("mvar-before-fvar-and-level",mkDecl (.app (.fvar (nm "x")) (.sort (.mvar u)))),
    ("fvar-before-undefined-level",mkDecl (.app (.fvar (nm "x")) (.sort (.param v)))),
    ("undefined-universe",mkDecl (.sort (.param v))),
    ("fewer-parameters",mkDecl s1 1),
    ("non-sort-result",mkDecl (all "A" s1 (.bvar 0))),
    ("illtyped-header",mkDecl (.app s0 s0)) ]

private def headerMatrix : IO Unit := do
  let mut count := 0
  for (label,decl) in positiveDecls ++ negativeDecls do
    let (arena,value) ← build decl
    for fuel in [0,1,2,3,4,8,32,4096] do
      for depth in [0,1,8] do
        compareHeader (label ++ ":" ++ toString fuel ++ ":" ++ toString depth)
          (frozenV1Header fuel psKernelEnvironmentEmpty decl depth psKernelLeanNatMaxSizeDefault)
          (psKernelExprV2OrdinaryAnalyzeHeaderWithFuel fuel psKernelEnvironmentEmpty depth
            psKernelLeanNatMaxSizeDefault arena [] decl.levelParams decl.numParams value decl.isUnsafe)
        count := count + 1
    if (positiveDecls.map Prod.fst).contains label then
      let result ← direct label (psKernelExprV2OrdinaryAnalyzeHeaderWithFuel 4096
        psKernelEnvironmentEmpty 0 psKernelLeanNatMaxSizeDefault arena []
        decl.levelParams decl.numParams value decl.isUnsafe)
      require (label ++ "-declared-parameter-count") (result.parameters.binders.length == decl.numParams)
  let collision := { mkDecl (.mvar (nm "m")) 1 [] [.const owner []] with
    ctors := [⟨owner,.const owner []⟩] }
  let (arena,value) ← build collision
  compareHeader "duplicate-name-before-uniform-and-header"
    (frozenV1Header 4096 psKernelEnvironmentEmpty collision 0 psKernelLeanNatMaxSizeDefault)
    (psKernelExprV2OrdinaryAnalyzeHeaderWithFuel 4096 psKernelEnvironmentEmpty 0
      psKernelLeanNatMaxSizeDefault arena [] collision.levelParams collision.numParams value false)
  let environment ← expect (psKernelAddAxiom 4096 psKernelEnvironmentEmpty
    (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk owner [] s1) false) 0 psKernelLeanNatMaxSizeDefault)
  let freshFault := mkDecl (.mvar (nm "m")) 1 [] [.const owner []]
  let (arena,value) ← build freshFault
  compareHeader "fresh-name-before-uniform-and-header"
    (frozenV1Header 4096 environment freshFault 0 psKernelLeanNatMaxSizeDefault)
    (psKernelExprV2OrdinaryAnalyzeHeaderWithFuel 4096 environment 0
      psKernelLeanNatMaxSizeDefault arena [] [] 1 value false)
  require "header-matrix-inventory" (count == 432)
  IO.println "PSC1_ORDINARY_HEADER_NATIVE: PASS matrix=432 positiveDirect=10 crossFault=2 headerOnly=true"

private def occurrenceCases : List PsKernelExpr :=
  let c := PsKernelExpr.const owner [.param u]
  let good := apps c [.bvar 0]
  [c,good,apps c [.bvar 1],apps c [s1],apps c [.bvar 0,s0],
   apps (.const owner []) [.bvar 0],apps (.const owner [.param u,.param u]) [.bvar 0],
   apps c [.bvar 1,.bvar 0],apps c [.bvar 0,.bvar 1],
   apps (.const owner [one]) [.bvar 0],apps (.const (nm "Other") []) [good],
   .app good good,all "x" s1 good,all "x" good s1,
   .lam (nm "x") s1 good .default,.letE (nm "x") s1 good good false,
   .mdata 72 good,.proj (nm "S") 0 good,s0]

private def occurrenceMatrix : IO Unit := do
  let mut count := 0
  for expr in occurrenceCases do
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty expr)
    for offset in [0,1,2] do
      for params in [0,1,2] do
        require "occurrence-head-exact" (sameExcept (fun (a b : Bool) => a == b)
          (psKernelExprV2OrdinaryUniformOccurrenceHead arena [owner] [.param u] params root offset)
          (psKernelSimpleCheckUniformOccurrenceHead [owner] [.param u] params expr offset))
        for fuel in [0,1,2,3,8,32] do
          require "occurrence-fuel-exact" (sameUnit
            (psKernelExprV2OrdinaryUniformOccurrenceWithFuel fuel arena [owner] [.param u] params root offset)
            (psKernelSimpleCheckUniformOccurrenceWithFuel fuel [owner] [.param u] params expr offset))
          count := count + 1
        require "occurrence-wrapper-bound" (sameUnit
          (psKernelExprV2OrdinaryUniformOccurrenceOnCanonical arena [owner] [.param u] params root offset)
          (psKernelSimpleCheckUniformOccurrence [owner] [.param u] params expr offset))
  -- One physically shared occurrence is valid at offset 1 and invalid at 2.
  let (a,c) ← expect (psKernelExprV2PagedMkConst psKernelExprV2PagedEmpty owner [.param u])
  let (a,b) ← expect (psKernelExprV2PagedMkBVar a 0)
  let (a,shared) ← expect (psKernelExprV2PagedMkApp a c b)
  let (a,s) ← expect (psKernelExprV2PagedMkSort a one)
  let (a,under) ← expect (psKernelExprV2PagedMkForall a (nm "x") s shared .default)
  let (a,both) ← expect (psKernelExprV2PagedMkApp a shared under)
  require "shared-id-first-offset-valid"
    (sameUnit (psKernelExprV2OrdinaryUniformOccurrenceOnCanonical a [owner] [.param u] 1 shared 1) (.ok ()))
  require "shared-id-different-offset-not-memoized"
    (sameUnit (psKernelExprV2OrdinaryUniformOccurrenceOnCanonical a [owner] [.param u] 1 both 1)
      (psKernelSimpleCheckUniformOccurrence [owner] [.param u] 1 (← decode a both) 1))
  require "occurrence-matrix-inventory" (count == 1026)
  IO.println "PSC1_ORDINARY_OCCURRENCE_NATIVE: PASS heads=171 fuelCases=1026 wrappers=171 sharedOffsets=2"

private def annotationCases : List PsKernelExpr :=
  let wrap := fun (name : PsKernelName) (args : List PsKernelExpr) => apps (.const name []) args
  let out := psKernelTypeAnnotationOutParamName
  let semi := psKernelTypeAnnotationSemiOutParamName
  let opt := psKernelTypeAnnotationOptParamName
  let auto := psKernelTypeAnnotationAutoParamName
  [s1,wrap out [],wrap out [s1],wrap semi [s1],wrap opt [s1,s0],wrap auto [s1,s0],
   wrap out [s1,s0],wrap semi [s1,s0],wrap opt [s1],wrap auto [s1],
   wrap opt [s1,s0,s0],wrap (.str (nm "Other") "outParam") [s1],
   wrap out [wrap auto [wrap semi [s1],s0]],.mdata 73 (wrap out [s1]),
   wrap out [.mdata 74 (wrap semi [s1])]]

private def annotationMatrix : IO Unit := do
  let mut count := 0
  for expr in annotationCases do
    let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty expr)
    for fuel in [0,1,2,3,8] do
      let result ← expect (psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel fuel arena root)
      require "annotation-exact-names-arities-nesting-mdata"
        (psKernelExprEqual (← decode arena result) (psKernelExprConsumeTypeAnnotationsWithFuel fuel expr))
      count := count + 1
    let result ← expect (psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical arena root)
    require "annotation-wrapper-bound"
      (psKernelExprEqual (← decode arena result) (psKernelExprConsumeTypeAnnotations expr))
  require "annotation-zero-before-invalid-id"
    (sameExcept Nat.beq (psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel 0 psKernelExprV2PagedEmpty 99) (.ok 99))
  require "annotation-positive-invalid-id"
    (sameExcept Nat.beq (psKernelExprV2OrdinaryConsumeTypeAnnotationsWithFuel 1 psKernelExprV2PagedEmpty 99)
      (.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"))
  require "annotation-matrix-inventory" (count == 75)
  IO.println "PSC1_ORDINARY_ANNOTATIONS_NATIVE: PASS fuelCases=75 wrappers=15 invalidIDs=2"

/- Deliberately private state markers. They are never submitted as a checked
   environment, cache hit, or admission certificate. Every callback changes
   every owner field, appends an arena node and checks the previous marker. -/
private def cacheTag (rows : List PsKernelExprV2WhnfCacheEntry) (tag : Nat) : Bool :=
  match rows with | [row] => row.hash == psKernelCacheHashModulus + tag | _ => false
private def pairTag (rows : List PsKernelExprV2DefEqPair) (tag : Nat) : Bool :=
  match rows with | [row] => row.hash == psKernelCacheHashModulus + tag | _ => false
private def stateTag (state : PsKernelExprV2CheckState) (tag extraFresh : Nat) : Bool :=
  state.nextFresh == 100 + 10 * tag + extraFresh &&
  cacheTag state.whnf.coreCache tag && cacheTag state.whnf.publicCache tag &&
  cacheTag state.checkedInfer tag && cacheTag state.inferOnly tag && cacheTag state.unfold tag &&
  pairTag state.success tag && pairTag state.failure tag &&
  (match state.whnf.declarations,state.checkedInfer with
   | [declaration],[row] =>
       psKernelNameEq declaration.name (.num (nm "state") tag) &&
       declaration.deltaValue == some row.result &&
       (match psKernelExprV2PagedRequire state.whnf.arena row.result with
        | .ok entry => match entry.node with | .lit (.nat value) => value == 12000 + tag | _ => false
        | _ => false)
   | _,_ => false)
private def stamp (state : PsKernelExprV2CheckState) (key tag : Nat) :
    Except String PsKernelExprV2CheckState := do
  let (arena,marker) ← psKernelExprV2PagedMkLit state.whnf.arena (.nat (12000 + tag))
  let cache := PsKernelExprV2WhnfCacheEntry.mk key marker (psKernelCacheHashModulus + tag)
  let pair := PsKernelExprV2DefEqPair.mk key key (psKernelCacheHashModulus + tag)
  let declaration := PsKernelExprV2DeclarationRef.mk (.num (nm "state") tag) [] key
    (some marker) .definitionDecl
  pure ⟨⟨arena,[cache],[cache],[declaration]⟩,100 + 10 * tag,[cache],[pair],[cache],[cache],[pair]⟩
private def currentTag (state : PsKernelExprV2CheckState) : Nat :=
  match state.checkedInfer with | row :: _ => row.hash - psKernelCacheHashModulus | _ => 999
private def orderedCallback (indexMode isCheck : Bool) (failAt : Nat) (decline : Bool)
    (header domain sort : Nat) (fuel : Nat) (_context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  let stage := currentTag state + 1
  let expectedFuel := if indexMode && stage == 4 then 6 else 7
  let expectedRoot := if stage == 1 then header else if stage == 2 then domain else sort
  let extraFresh := if stage == 4 then 1 else 0
  if fuel != expectedFuel || root != expectedRoot || isCheck != (stage == 2) ||
      !stateTag state (stage - 1) extraFresh then
    some (.error "T05_CALLBACK_WRONG_INPUT_OR_STALE_OWNER")
  else if failAt == stage then
    if decline then none else some (.error "T05_CALLBACK_INJECTED")
  else some ((stamp state sort stage).map (fun next => (next,if isCheck then sort else root)))

private def phaseCallback (isCheck : Bool) (failAt : Nat) (decline : Bool)
    (sort : Nat) (fuel : Nat) (_context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  let stage := currentTag state + 1
  if fuel != 7 || root != sort || isCheck != (stage == 1) ||
      !stateTag state (stage - 1) 0 then
    some (.error "T05_PHASE_WRONG_INPUT_OR_STALE_OWNER")
  else if failAt == stage then
    if decline then none else some (.error "T05_PHASE_INJECTED")
  else some (do
    let next ← stamp state sort stage
    if stage == 4 then
      let (arena,result) ← psKernelExprV2PagedMkSort next.whnf.arena (.succ one)
      pure (psKernelExprV2CheckStateWithArena next arena,result)
    else pure (next,root))

private def callbackAndForkControls : IO Unit := do
  let (arena,sort) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty one)
  let (arena,consumedDomain) ← expect (psKernelExprV2PagedMkMData arena 75 sort)
  let (arena,annotation) ← expect (psKernelExprV2PagedMkConst arena psKernelTypeAnnotationOutParamName [])
  let (arena,domain) ← expect (psKernelExprV2PagedMkApp arena annotation consumedDomain)
  let (arena,header) ← expect (psKernelExprV2PagedMkForall arena (nm "A") domain sort .implicit)
  let scalar := (psKernelMkCheckerSession psKernelEnvironmentEmpty [] .safe 0
    psKernelLeanNatMaxSizeDefault).context
  let context := psKernelExprV2CheckContextEmpty scalar
  let initial ← expect (stamp (psKernelExprV2CheckStateEmpty arena) sort 0)
  let mut propagated := 0
  for indexMode in [false,true] do
    let run := fun failAt decline =>
      let check := orderedCallback indexMode true failAt decline header domain sort
      let whnf := orderedCallback indexMode false failAt decline header domain sort
      if indexMode then
        psKernelExprV2OrdinaryOpenHeaderIndicesWith check whnf 7 context initial header
      else psKernelExprV2OrdinaryOpenHeaderParamsWith check whnf 7 context initial header 1
    let result ← direct "all-owner-fields-through-four-callbacks" (run 0 false)
    require "all-fields-and-arena-propagated" (stateTag result.state 4 0)
    require "fresh-name-after-domain-check-and-mandatory-whnf"
      (match result.binders with
       | [binder] => psKernelNameEq binder.internalName (.num (nm "A") 130) &&
           psKernelNameEq binder.userName (nm "A") && binder.type == consumedDomain &&
           psKernelBinderInfoEq binder.binderInfo .implicit &&
           (match result.context.locals with
            | [localDecl] => localDecl.type == consumedDomain && psKernelNameEq localDecl.name binder.internalName
            | _ => false)
       | _ => false)
    for failAt in [1,2,3,4] do
      for decline in [false,true] do
        require "callback-decline-error-short-circuit"
          (match run failAt decline with
           | none => decline
           | some (.error error) => !decline && error == "T05_CALLBACK_INJECTED"
           | _ => false)
        propagated := propagated + 1
    let indexState ← expect (stamp result.state sort 9)
    let indexId ← match indexState.checkedInfer with
      | [row] => pure row.result
      | _ => throw (IO.userError "missing private index sentinel")
    let indexContext := psKernelExprV2CheckContextWithLocal result.context
      (nm "index-only") (nm "index-user") sort .strictImplicit
    let indices := PsKernelExprV2OrdinaryOpenResult.mk indexContext indexState [] indexId
    let analysis := PsKernelExprV2OrdinaryHeaderAnalysis.mk result indices .zero
    let fork := psKernelExprV2OrdinaryConstructorState analysis
    let forkContext := psKernelExprV2OrdinaryConstructorContext analysis
    require "fork-keeps-parameter-owner" (stateTag fork 4 0)
    require "fork-keeps-index-appended-id"
      (psKernelExprEqual (← decode fork.whnf.arena indexId) (.lit (.nat 12009)))
    require "fork-keeps-parameter-context"
      (forkContext.locals.length == result.context.locals.length &&
        (psKernelExprV2CheckLocalFind forkContext.locals (nm "index-only")).isNone)
  let forbid := fun (_ : Nat) (_ : PsKernelExprV2CheckContext)
      (_ : PsKernelExprV2CheckState) (_ : Nat) =>
    (some (.error "T05_CALLBACK_FORBIDDEN") : Option (Except String (PsKernelExprV2CheckState × Nat)))
  require "index-zero-before-invalid-root-and-callback"
    (match psKernelExprV2OrdinaryOpenHeaderIndicesWorker 0 forbid forbid context initial 999 [] with
     | some (.error error) => error == "simple inductive index budget exhausted" | _ => false)
  require "parameter-zero-still-calls-terminal-whnf"
    (match psKernelExprV2OrdinaryOpenHeaderParamsWith forbid forbid 0 context initial sort 0 with
     | some (.error error) => error == "T05_CALLBACK_FORBIDDEN" | _ => false)
  require "public-index-zero-calls-whnf-at-predecessor"
    (match psKernelExprV2OrdinaryOpenHeaderIndicesWith forbid forbid 0 context initial sort with
     | some (.error error) => error == "T05_CALLBACK_FORBIDDEN" | _ => false)
  let runPhases := fun failAt decline =>
    psKernelExprV2OrdinaryHeaderPhasesWith
      (phaseCallback true failAt decline sort) (phaseCallback false failAt decline sort)
      7 context initial sort 0
  let analysis ← direct "complete-header-owner-chain" (runPhases 0 false)
  require "header-keeps-both-phase-owners"
    (stateTag analysis.parameters.state 3 0 && stateTag analysis.indices.state 4 0)
  require "header-reads-new-index-result-and-level"
    (psKernelLevelEq analysis.resultLevel (.succ one) &&
      psKernelExprEqual (← decode analysis.indices.state.whnf.arena analysis.indices.result) s2)
  require "actual-header-fork-restores-parameter-fields-with-index-arena"
    (stateTag (psKernelExprV2OrdinaryConstructorState analysis) 3 0 &&
      psKernelExprEqual (← decode (psKernelExprV2OrdinaryConstructorState analysis).whnf.arena
        analysis.indices.result) s2)
  for failAt in [1,2,3,4] do
    for decline in [false,true] do
      require "complete-header-callback-short-circuit"
        (match runPhases failAt decline with
         | none => decline
         | some (.error error) => !decline && error == "T05_PHASE_INJECTED"
         | _ => false)
      propagated := propagated + 1
  require "callback-inventory" (propagated == 24)
  IO.println "PSC1_ORDINARY_HEADER_STATE_NATIVE: PASS sequences=3 propagated=24 forkFields=all boundaries=3"

private def officialName : PsKernelName → Lean.Name
  | .anonymous => .anonymous
  | .str parent value => .str (officialName parent) value
  | .num parent value => .num (officialName parent) value
private def officialLevel : PsKernelLevel → Option Lean.Level
  | .zero => some .zero
  | .succ value => (officialLevel value).map Lean.Level.succ
  | .max a b => do return .max (← officialLevel a) (← officialLevel b)
  | .imax a b => do return .imax (← officialLevel a) (← officialLevel b)
  | .param name => some (.param (officialName name))
  | .mvar _ => none
private def officialBinder : PsKernelBinderInfo → Lean.BinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit
private def officialExpr : PsKernelExpr → Option Lean.Expr
  | .bvar index => some (.bvar index)
  | .sort level => (officialLevel level).map Lean.Expr.sort
  | .const name levels => do return .const (officialName name) (← levels.mapM officialLevel)
  | .app fn arg => do return .app (← officialExpr fn) (← officialExpr arg)
  | .forallE name domain body info => do
      return .forallE (officialName name) (← officialExpr domain) (← officialExpr body) (officialBinder info)
  | _ => none
private def officialAdd (environment : Lean.Environment) (decl : PsKernelSimpleInductiveDecl) :
    IO Bool := do
  let some type := officialExpr decl.type | throw (IO.userError "official header conversion")
  let mut ctors : List Lean.Constructor := []
  for ctor in decl.ctors do
    let some type := officialExpr ctor.type | throw (IO.userError "official constructor conversion")
    ctors := ctors ++ [{ name := officialName ctor.name, type }]
  let declaration := Lean.Declaration.inductDecl (decl.levelParams.map officialName)
    decl.numParams [{ name := officialName decl.name, type, ctors }] decl.isUnsafe
  pure (match environment.addDeclCore 0 0 declaration none true with | .ok _ => true | _ => false)
private def officialControls : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let environment ← Lean.importModules #[{ module := `Init }] {}
  for (_,decl) in positiveDecls.take 4 do
    require "official-enum-parameter-index-universe" (← officialAdd environment decl)
  let bad := mkDecl (all "A" s1 s1) 1 [] [all "A" s1 (.const owner [])]
  require "official-rejects-missing-uniform-parameter" (!(← officialAdd environment bad))
  require "official-rejects-non-sort-result"
    (!(← officialAdd environment (mkDecl (all "A" s1 (.bvar 0)))))
  IO.println "PSC1_ORDINARY_HEADER_ORACLE: PASS accepted=4 rejected=2 headerOnly=true"

def main : IO Unit := do
  headerMatrix
  occurrenceMatrix
  annotationMatrix
  callbackAndForkControls
  officialControls
  IO.println "PSC1_ORDINARY_HEADER_REGRESSION: PASS headerOnly=true fullAdmission=false"
