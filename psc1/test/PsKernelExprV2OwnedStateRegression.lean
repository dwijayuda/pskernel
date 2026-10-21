import Ps.KernelCore.API.Dag
import Ps.KernelCore.Checker.ExprV2.Knot
import Ps.KernelCore.Research.ExprV2PagedImport

/- Carrier probes deliberately use unreachable diagnostic cache rows: their
   hashes are outside the kernel hash modulus. They can never establish a
   judgment or cause a cache hit. These probes test full-state transport and
   callback order; the separate real-expression matrix checks V1 outcomes.
   Existing official, admission, Quot and recursor regressions remain required. -/

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_V2_OWNED_STATE_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError "owned-state checked fixture failed")

private def attempt {α : Type} (label : String) : Option (Except String α) → IO α
  | some value => expect value
  | none => throw (IO.userError ("unexpected owned-state fallback: " ++ label))

private def reduction (value : Option (Except String
    (PsKernelExprV2CheckState × Option Nat))) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  match value with
  | none => none
  | some (.error error) => some (.error error)
  | some (.ok (state,some root)) => some (.ok (state,root))
  | some (.ok (_,none)) => some (.error "carrier expected reduction")

private def nm (text : String) := PsKernelName.str .anonymous text
private def one := PsKernelLevel.succ PsKernelLevel.zero
private def nat := PsKernelExpr.const psKernelNatName []
private def lit (value : Nat) := PsKernelExpr.lit (.nat value)
private def lam (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.lam (nm name) type body .default
private def all (name : String) (type body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm name) type body .default
private def apps (head : PsKernelExpr) (args : List PsKernelExpr) := psKernelApplyArgs head args

private def cacheMark (rows : List PsKernelExprV2WhnfCacheEntry) (tag : Nat) : Bool :=
  match rows with
  | [entry] => entry.hash == psKernelCacheHashModulus + tag
  | _ => false

private def pairMark (rows : List PsKernelExprV2DefEqPair) (tag : Nat) : Bool :=
  match rows with
  | [entry] => entry.hash == psKernelCacheHashModulus + tag
  | _ => false

private def outerMark (state : PsKernelExprV2CheckState) (tag fresh : Nat) : Bool :=
  state.nextFresh == fresh &&
    cacheMark state.checkedInfer tag && pairMark state.success tag &&
    cacheMark state.inferOnly tag && cacheMark state.unfold tag && pairMark state.failure tag

private def stamp (key : Nat) (state : PsKernelExprV2CheckState) (tag : Nat) :
    Except String PsKernelExprV2CheckState := do
  let (arena,_) ← psKernelExprV2PagedMkLit state.whnf.arena (.nat (9000 + tag))
  let cache := PsKernelExprV2WhnfCacheEntry.mk key key (psKernelCacheHashModulus + tag)
  let pair := PsKernelExprV2DefEqPair.mk key key (psKernelCacheHashModulus + tag)
  let whnf := PsKernelExprV2WhnfState.mk arena
    (cache :: state.whnf.coreCache) (cache :: state.whnf.publicCache) state.whnf.declarations
  pure (PsKernelExprV2CheckState.mk whnf tag [cache] [pair] [cache] [cache] [pair])

private def advance (key : Nat) (state : PsKernelExprV2CheckState)
    (tag fresh next : Nat) : Except String PsKernelExprV2CheckState :=
  if outerMark state tag fresh then stamp key state next
  else .error "carrier callback received stale state"

private def whnfStep (key tag fresh next result : Nat)
    (_context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) (_root : Nat) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  some ((advance key state tag fresh next).map (fun updated => (updated,result)))

private def decode (state : PsKernelExprV2CheckState) (root : Nat) : IO PsKernelExpr := do
  let built ← expect (psKernelExprV2DecodeChecked state.whnf.arena)
  expect (psKernelExprV2DecodedRequire built root)

private def marked (label : String) (tag fresh : Nat)
    (value : Option (Except String (PsKernelExprV2CheckState × Nat))) :
    IO (PsKernelExprV2CheckState × Nat) := do
  let result ← attempt label value
  require (label ++ "-all-six-outer-fields") (outerMark result.fst tag fresh)
  require (label ++ "-core-marker")
    (result.fst.whnf.coreCache.any (fun entry => entry.hash == psKernelCacheHashModulus + tag))
  require (label ++ "-public-marker")
    (result.fst.whnf.publicCache.any (fun entry => entry.hash == psKernelCacheHashModulus + tag))
  require (label ++ "-declaration-owner")
    (psKernelExprV2DeclarationRefFind result.fst.whnf.declarations
      (psKernelSimpleRecName psKernelNatName)).isSome
  let _ ← expect (psKernelExprV2PagedValidate result.fst.whnf.arena)
  let _ ← expect (psKernelExprV2PagedRequire result.fst.whnf.arena result.snd)
  pure result

private def compareWhnf (label : String)
    (original : Except String (PsKernelExpr × PsKernelCheckerState))
    (observed : Option (Except String (PsKernelExprV2CheckState × Nat))) : IO Unit := do
  match original,observed with
  | .error expected,some (.error actual) => require (label ++ "-exact-error") (expected == actual)
  | .ok expected,some (.ok actual) =>
      require (label ++ "-expression") (psKernelExprEqual expected.fst (← decode actual.fst actual.snd))
  | _,none => throw (IO.userError ("unexpected differential fallback: " ++ label))
  | _,_ => throw (IO.userError ("owned-state differential mismatch: " ++ label))

private def propagation {α : Type} (label : String) (declined : Bool)
    (value : Option (Except String α)) : IO Unit := do
  match value with
  | none => require (label ++ "-outer-None") declined
  | some (.error error) => require (label ++ "-exact-propagation") (!declined && error == "carrier injected")
  | some (.ok _) => throw (IO.userError ("carrier failure accepted: " ++ label))

private def errorIs {α : Type} (label expected : String)
    (value : Option (Except String α)) : IO Unit := do
  match value with
  | some (.error actual) => require label (actual == expected)
  | _ => throw (IO.userError ("carrier error contract failed: " ++ label))

private def boolRoot (root : Nat) (expected : Bool)
    (value : Option (Except String (PsKernelExprV2CheckState × Bool))) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  match value with
  | none => none
  | some (.error error) => some (.error error)
  | some (.ok (state,answer)) =>
      if answer == expected then some (.ok (state,root))
      else some (.error "carrier Boolean decision changed")

private def optionalBoolRoot (root : Nat) (expected : Option Bool)
    (value : Option (Except String (PsKernelExprV2CheckState × Option Bool))) :
    Option (Except String (PsKernelExprV2CheckState × Nat)) :=
  match value with
  | none => none
  | some (.error error) => some (.error error)
  | some (.ok (state,answer)) =>
      if answer == expected then some (.ok (state,root))
      else some (.error "carrier optional decision changed")

/- Keep the same per-seed probes in a separate elaboration scope.
   Callback values, case order and exact assertions are unchanged; only
   the three observational counters are returned to the outer matrix. -/
private def runDefEqAndFailureProbes
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (seed s0Id s1Id natId zeroId oneId twoId aliasId
      unitType unitLeft unitRight boolTrue strId strBuilt addId
      wrappedSort aType aValue bValue fnId fnType wrappedFn
      applicationId lambdaId quotId recId projMajor projId : Nat)
    (first second : Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
      Option (Except String (PsKernelExprV2CheckState × Nat)))
    (binary forbidden : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
      Option (Except String (PsKernelExprV2CheckState × Nat)))
    (forbiddenEq : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →
      Option (Except String (PsKernelExprV2CheckState × Bool))) : IO (Nat × Nat × Nat) := do
  let mut defeqProbes := 0
  let mut propagated := 0
  let mut defeqPropagation := 0
  let eqStep :=
    fun (tag fresh next : Nat) (answer : Bool)
        (_c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (_l _r : Nat) =>
      some ((advance zeroId s tag fresh next).map (fun updated => (updated,answer)))
  let assertBool :=
    fun (label : String) (tag : Nat) (answer : Bool)
        (value : Option (Except String (PsKernelExprV2CheckState × Bool))) => do
      let _ ← marked label tag tag (boolRoot zeroId answer value)
      pure ()
  let assertOptional :=
    fun (label : String) (tag : Nat) (answer : Option Bool)
        (value : Option (Except String (PsKernelExprV2CheckState × Option Bool))) => do
      let _ ← marked label tag tag (optionalBoolRoot zeroId answer value)
      pure ()
  assertOptional "reflection-whnf-state" (seed + 1) (some true)
    (psKernelExprV2DefEqReflectionOwnedWith (first boolTrue) context state boolTrue boolTrue)
  defeqProbes := defeqProbes + 1
  let orderedCore :=
    fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
      if root == fnId then first fnId c s root
      else if root == bValue then second bValue c s root
      else some (.error "DefEq core operand order changed")
  assertBool "prefix-left-right-continuation-state" (seed + 3) false
    (psKernelExprV2DefEqCoreQuickContinueOwnedWith
      (eqStep (seed + 2) (seed + 2) (seed + 3) false)
      forbiddenEq orderedCore context state fnId bValue)
  defeqProbes := defeqProbes + 1
  assertBool "is-prop-inference-whnf-state" (seed + 2) true
    (psKernelExprV2DefEqIsPropOwnedWith (first s0Id) (second s0Id) context state aType)
  defeqProbes := defeqProbes + 1
  let proofInfer :=
    fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
      if root == aValue then first aType c s root
      else if root == aType then second s0Id c s root
      else if root == bValue then
        whnfStep zeroId (seed + 3) (seed + 3) (seed + 4) aType c s root
      else some (.error "proof irrelevance inference order changed")
  assertBool "proof-irrelevance-all-callback-state" (seed + 5) true
    (psKernelExprV2DefEqProofIrrelevanceContinueOwnedWith forbiddenEq
      (eqStep (seed + 4) (seed + 4) (seed + 5) true) proofInfer
      (whnfStep zeroId (seed + 2) (seed + 2) (seed + 3) s0Id)
      context state aValue bValue)
  defeqProbes := defeqProbes + 1
  let nonPropInfer :=
    fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
      if root == oneId then first natId c s root
      else if root == natId then second s1Id c s root
      else some (.error "non-proposition inference order changed")
  assertBool "non-proposition-continuation-state" (seed + 4) false
    (psKernelExprV2DefEqProofIrrelevanceContinueOwnedWith
      (eqStep (seed + 3) (seed + 3) (seed + 4) false) forbiddenEq nonPropInfer
      (whnfStep zeroId (seed + 2) (seed + 2) (seed + 3) s1Id)
      context state oneId twoId)
  defeqProbes := defeqProbes + 1
  assertBool "lazy-nat-left-retains-both-operands" (seed + 3) false
    (psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith forbiddenEq
      (eqStep (seed + 2) (seed + 2) (seed + 3) false) binary context state addId zeroId)
  defeqProbes := defeqProbes + 1
  assertBool "lazy-nat-right-retains-both-operands" (seed + 3) false
    (psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith forbiddenEq
      (eqStep (seed + 2) (seed + 2) (seed + 3) false) binary context state zeroId addId)
  defeqProbes := defeqProbes + 1
  let aliasEntry ← expect (psKernelExprV2PagedRequire state.whnf.arena aliasId)
  let unfoldedMark :=
    fun (s : PsKernelExprV2CheckState) (root : Nat) =>
      outerMark (psKernelExprV2CheckStateWithUnfold s state.unfold) seed seed &&
        match s.unfold with
        | entry :: rest => cacheMark rest seed && entry.source == aliasId &&
            entry.result == root && entry.hash == aliasEntry.hash
        | [] => false
  let deltaCore :=
    fun (_c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
        (root : Nat) (cheapProj : Bool) =>
      if cheapProj && unfoldedMark s root then
        match psKernelExprV2PagedEqOnCanonical s.whnf.arena root twoId with
        | .error error => some (.error error)
        | .ok same => if same then some ((stamp zeroId s (seed + 1)).map
            (fun updated => (updated,twoId)))
          else some (.error "delta callback body changed")
      else some (.error "delta unfolding publication or callback owner changed")
  let _ ← marked "delta-once-retains-full-core-state" (seed + 1) (seed + 1)
    (psKernelExprV2DefEqDeltaOnceOwnedWith deltaCore context state aliasId)
  defeqProbes := defeqProbes + 1
  let projectionCore :=
    fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
        (root : Nat) (cheapProj : Bool) =>
      if root == projId && !cheapProj then first oneId c s root
      else some (.error "projection core flags changed")
  let _ ← marked "delta-projection-core-state" (seed + 1) (seed + 1)
    (reduction (psKernelExprV2DefEqTryUnfoldProjAppOwnedWith projectionCore context state projId))
  defeqProbes := defeqProbes + 1
  assertBool "lazy-delta-loop-retains-core-state" (seed + 1) true
    (psKernelExprV2DefEqLazyDeltaContinueOwnedWithFuel 2 forbiddenEq forbiddenEq
      forbidden deltaCore context state aliasId twoId)
  defeqProbes := defeqProbes + 1
  assertBool "lazy-projection-loop-retains-core-state" (seed + 1) true
    (psKernelExprV2DefEqLazyProjReductionOwnedWithFuel 2
      forbiddenEq deltaCore context state aliasId twoId psKernelNatName 0)
  defeqProbes := defeqProbes + 1
  for lambdaOnLeft in [false,true] do
    assertOptional "function-eta-retains-infer-whnf-defeq-state" (seed + 3) none
      (psKernelExprV2DefEqFullShapeEtaOwnedWith lambdaOnLeft
        (eqStep (seed + 2) (seed + 2) (seed + 3) false)
        (first wrappedFn) (second fnType) context state lambdaId fnId)
    defeqProbes := defeqProbes + 1
  let changedCore :=
    fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
        (root : Nat) (cheapProj : Bool) =>
      if cheapProj then some (.error "residual core must disable cheap projection")
      else if root == wrappedSort then first s0Id c s root
      else if root == s1Id then second s1Id c s root
      else some (.error "residual core order changed")
  assertBool "residual-full-whnf-changed-state" (seed + 3) false
    (psKernelExprV2DefEqResidualOwnedWith
      (eqStep (seed + 2) (seed + 2) (seed + 3) false)
      forbidden forbidden changedCore context state wrappedSort s1Id)
  defeqProbes := defeqProbes + 1
  let unchangedCore :=
    fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
        (root : Nat) (cheapProj : Bool) =>
      if cheapProj then some (.error "residual core must disable cheap projection")
      else orderedCore c s root
  assertBool "residual-final-unit-negative-keeps-whnf-state" (seed + 4) false
    (psKernelExprV2DefEqResidualOwnedWith forbiddenEq
      (whnfStep zeroId (seed + 2) (seed + 2) (seed + 3) wrappedFn)
      (whnfStep zeroId (seed + 3) (seed + 3) (seed + 4) fnType)
      unchangedCore context state fnId bValue)
  defeqProbes := defeqProbes + 1
  for reverse in [false,true] do
    let left := if reverse then strBuilt else strId
    let right := if reverse then strId else strBuilt
    assertOptional "string-expansion-keeps-whnf-defeq-state" (seed + 2) (some true)
      (psKernelExprV2DefEqStringLitExpansionOwnedWith
        (eqStep (seed + 1) (seed + 1) (seed + 2) true)
        (first strBuilt) context state left right)
    defeqProbes := defeqProbes + 1
  let unitInfer :=
    fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
      if root == unitLeft then first unitType c s root
      else if root == unitRight then
        whnfStep zeroId (seed + 2) (seed + 2) (seed + 3) unitType c s root
      else some (.error "unit-like inference order changed")
  assertBool "unit-like-all-callback-state" (seed + 4) true
    (psKernelExprV2DefEqUnitLikeOwnedWith
      (eqStep (seed + 3) (seed + 3) (seed + 4) true)
      unitInfer (second unitType) context state unitLeft unitRight)
  defeqProbes := defeqProbes + 1
  assertBool "final-rules-all-callback-state" (seed + 4) true
    (psKernelExprV2DefEqFinalRulesOwnedWith
      (eqStep (seed + 3) (seed + 3) (seed + 4) true)
      unitInfer (second unitType) context state unitLeft unitRight)
  defeqProbes := defeqProbes + 1
  for declined in [false,true] do
    let failing : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
        Option (Except String (PsKernelExprV2CheckState × Nat)) :=
      fun _ _ _ => if declined then none else some (.error "carrier injected")
    let failingReducer : PsKernelExprV2CheckContext → PsKernelExprV2CheckState →
        Nat → Bool → Bool → Option (Except String (PsKernelExprV2CheckState × Option Nat)) :=
      fun _ _ _ _ _ => if declined then none else some (.error "carrier injected")
    let failingCore :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
          (root : Nat) (_cheapRec _cheapProj : Bool) => failing c s root
    let failures := [
      ("nat-succ",reduction (psKernelExprV2TryReduceNatSuccOwnedWith failing context state oneId)),
      ("nat-binary",reduction (psKernelExprV2TryReduceNatBinaryOwnedWith failing context state
        (PsKernelName.str psKernelNatName "add") oneId twoId)),
      ("quot",reduction (psKernelExprV2TryReduceQuotOwnedWith failing context state quotId)),
      ("recursor",reduction (psKernelExprV2TryReduceRecursorOwnedWith
        failing failingCore forbidden forbiddenEq context state recId false false)),
      ("projection",psKernelExprV2TryWhnfProjectionOwnedWith failing failing
        context state projId psKernelNatName 0 projMajor false),
      ("application",psKernelExprV2TryWhnfAppOwnedWithReducer failing failingReducer
        context state applicationId false false),
      ("public",psKernelExprV2TryWhnfOwnedWithReducerFuel 8
        failingReducer psKernelExprV2CheckLocalValue context state applicationId),
      ("core",psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel 8 false false
        psKernelExprV2CheckLocalValue failing failingReducer context state applicationId),
      ("lambda",psKernelExprV2TryInferCoreOwnedWithFuel 8
        failing forbiddenEq context state lambdaId false),
      ("checked-app",psKernelExprV2TryInferCoreOwnedWithFuel 8
        failing forbiddenEq context state applicationId false),
      ("infer-app",psKernelExprV2TryInferCoreOwnedWithFuel 8
        failing forbiddenEq context state applicationId true)]
    for (label,value) in failures do
      propagation label declined value
      propagated := propagated + 1
    propagation "ensure-sort" declined
      (psKernelExprV2CheckEnsureSortOwnedWith failing context state wrappedSort)
    propagation "ensure-forall" declined
      (psKernelExprV2CheckEnsureForallOwnedWith failing context state wrappedFn)
    propagated := propagated + 2
    let failRight :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
        if root == oneId then first oneId c s root
        else if root == twoId && outerMark s (seed + 1) (seed + 1) then failing c s root
        else some (.error "carrier callback received stale state")
    propagation "Nat-right-failure-after-left-effects" declined
      (psKernelExprV2TryReduceNatBinaryOwnedWith failRight context state
        (PsKernelName.str psKernelNatName "add") oneId twoId)
    propagated := propagated + 1
    let afterOneFail :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
        if outerMark s (seed + 1) (seed + 1) then failing c s root
        else some (.error "DefEq failure callback received stale first state")
    let afterTwoFail :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
        if outerMark s (seed + 2) (seed + 2) then failing c s root
        else some (.error "DefEq failure callback received stale second state")
    let coreFailRight :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
        if root == fnId then first fnId c s root
        else if root == bValue then afterOneFail c s root
        else some (.error "DefEq failure core order changed")
    let failDeltaCore :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
          (root : Nat) (cheapProj : Bool) =>
        if cheapProj && unfoldedMark s root then failing c s root
        else some (.error "DefEq failure lost unfolding state")
    let failProjectionCore :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
          (root : Nat) (cheapProj : Bool) =>
        if root == projId && !cheapProj && outerMark s seed seed then failing c s root
        else some (.error "DefEq projection failure flags changed")
    let failResidualCore :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
          (root : Nat) (cheapProj : Bool) =>
        if cheapProj then some (.error "DefEq residual failure flags changed")
        else coreFailRight c s root
    let defeqFailures := [
      ("prefix-right",boolRoot zeroId false
        (psKernelExprV2DefEqCoreQuickContinueOwnedWith forbiddenEq forbiddenEq
          coreFailRight context state fnId bValue)),
      ("proof-whnf",boolRoot zeroId false
        (psKernelExprV2DefEqProofIrrelevanceContinueOwnedWith forbiddenEq forbiddenEq
          proofInfer afterTwoFail context state aValue bValue)),
      ("lazy-nat-right",boolRoot zeroId false
        (psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith forbiddenEq forbiddenEq
          failRight context state addId zeroId)),
      ("delta-core",psKernelExprV2DefEqDeltaOnceOwnedWith failDeltaCore context state aliasId),
      ("projection-core",reduction
        (psKernelExprV2DefEqTryUnfoldProjAppOwnedWith failProjectionCore context state projId)),
      ("eta-whnf",optionalBoolRoot zeroId none
        (psKernelExprV2DefEqFullShapeEtaOwnedWith true forbiddenEq
          (first wrappedFn) afterOneFail context state lambdaId fnId)),
      ("residual-right",boolRoot zeroId false
        (psKernelExprV2DefEqResidualOwnedWith forbiddenEq forbidden forbidden
          failResidualCore context state fnId bValue)),
      ("string-whnf",optionalBoolRoot zeroId none
        (psKernelExprV2DefEqStringLitExpansionOwnedWith forbiddenEq failing
          context state strId strBuilt)),
      ("unit-whnf",boolRoot zeroId false
        (psKernelExprV2DefEqUnitLikeOwnedWith forbiddenEq
          unitInfer afterOneFail context state unitLeft unitRight)),
      ("lazy-projection-core",boolRoot zeroId false
        (psKernelExprV2DefEqLazyProjReductionOwnedWithFuel 2 forbiddenEq
          failDeltaCore context state aliasId twoId psKernelNatName 0)),
      ("lazy-delta-core",boolRoot zeroId false
        (psKernelExprV2DefEqLazyDeltaContinueOwnedWithFuel 2 forbiddenEq
          forbiddenEq forbidden failDeltaCore context state aliasId twoId))]
    for (label,value) in defeqFailures do
      propagation ("DefEq-" ++ label) declined value
      defeqPropagation := defeqPropagation + 1
  pure (defeqProbes, propagated, defeqPropagation)

private def admissionOwnedRegression
    (scalar : PsKernelCheckerContext) (initial : PsKernelExprV2CheckState)
    (context : PsKernelExprV2CheckContext)
    (differential : List (String × PsKernelExpr × Nat))
    (zeroId oneId s0Id s1Id wrappedSort : Nat) : IO Unit := do
  let forbidden : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
      Option (Except String (PsKernelExprV2CheckState × Nat)) :=
    fun _ _ _ => some (.error "unexpected admission callback")

  -- Admission must carry callback effects through its mandatory normalization,
  -- even when the inferred type is already a syntactic sort.
  let mut admissionProbes := 0
  let mut admissionPropagation := 0
  for seed in [2,11] do
    let state ← expect (stamp zeroId initial seed)
    let first := whnfStep zeroId seed seed (seed + 1)
    let second := whnfStep zeroId (seed + 1) (seed + 1) (seed + 2)
    for (sortRoot,level,answer) in [(s0Id,PsKernelLevel.zero,true),(s1Id,one,false)] do
      let sorted ← attempt "admission-sort-owner"
        (psKernelExprV2AdmissionEnsureSortOwnedWith (first sortRoot) context state sortRoot)
      require "admission-sort-exact-level" (psKernelExprEqual (.sort sorted.snd) (.sort level))
      let _ ← marked "admission-sort-all-callback-effects" (seed + 1) (seed + 1)
        (some (.ok (sorted.fst,sortRoot)))
      admissionProbes := admissionProbes + 1
      let _ ← marked "admission-proposition-all-callback-effects" (seed + 2) (seed + 2)
        (boolRoot sortRoot answer
          (psKernelExprV2AdmissionIsPropOwnedWith
            (first sortRoot) (second sortRoot) context state oneId))
      admissionProbes := admissionProbes + 1
    let invalid := state.whnf.arena.size + 1000
    let invalidOwner ← expect (advance zeroId state seed seed (seed + 1))
    let .error invalidError := psKernelExprV2PagedRequire invalidOwner.whnf.arena invalid
      | throw (IO.userError "admission malformed-result fixture is valid")
    errorIs "admission-sort-refuses-invalid-callback-result" invalidError
      (psKernelExprV2AdmissionEnsureSortOwnedWith (first invalid) context state s0Id)
    errorIs "admission-sort-refuses-nonsort" "expected sort"
      (psKernelExprV2AdmissionEnsureSortOwnedWith (first oneId) context state s0Id)
    errorIs "admission-proposition-refuses-nonsort" "expected sort"
      (psKernelExprV2AdmissionIsPropOwnedWith
        (first s0Id) (second oneId) context state oneId)
    for declined in [false,true] do
      let failing : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
          Option (Except String (PsKernelExprV2CheckState × Nat)) :=
        fun _ _ _ => if declined then none else some (.error "carrier injected")
      let afterInfer :=
        fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
          if outerMark s (seed + 1) (seed + 1) && root == invalid then
            failing c s root
          else some (.error "admission callback owner/order changed")
      propagation "admission-sort-whnf-before-malformed-root" declined
        (psKernelExprV2AdmissionEnsureSortOwnedWith failing context state invalid)
      propagation "admission-proposition-inference-first" declined
        (psKernelExprV2AdmissionIsPropOwnedWith failing forbidden context state invalid)
      propagation "admission-proposition-whnf-owner" declined
        (psKernelExprV2AdmissionIsPropOwnedWith
          (first invalid) afterInfer context state oneId)
      admissionPropagation := admissionPropagation + 3
  let proposition := all "P" (.sort .zero) (.bvar 0)
  let (admissionArena,propositionRoot) ← expect
    (psKernelExprV2PagedImportIntoChecked initial.whnf.arena proposition)
  let admissionState := psKernelExprV2CheckStateWithArena initial admissionArena
  let admissionTerms : List (String × PsKernelExpr × Nat) :=
    [("sort-zero",.sort .zero,s0Id),("sort-one",.sort one,s1Id),
     ("metadata-sort",.mdata 61 (.sort .zero),wrappedSort),
     ("proposition",proposition,propositionRoot),("literal",lit 1,oneId)] ++
      differential.filter (fun row => row.1 == "beta" || row.1 == "zeta" || row.1 == "iota")
  require "admission-real-fixture-count" (admissionTerms.length == 8)
  let mut admissionComparisons := 0
  let mut publicWhnfComparisons := 0
  for (label,term,root) in admissionTerms do
    for fuel in [0,1,2,3,4,8,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let limited := { scalar with maxRecDepth := limit, recDepth := depth }
        let c := psKernelExprV2CheckContextEmpty limited
        let reference := PsKernelCheckerSession.mk limited psKernelCheckerStateEmpty
        let tag := s!"admission-{label}-fuel{fuel}-depth{depth}-limit{limit}"
        match psKernelSessionEnsureSort fuel reference term,
            psKernelExprV2AdmissionEnsureSortWithFuel fuel c admissionState root with
        | .error expected,some (.error actual) =>
            require (tag ++ "-sort-exact-error") (expected == actual)
        | .ok _,some (.ok _) => pure ()
        | _,none => throw (IO.userError (tag ++ "-sort-fallback"))
        | _,_ => throw (IO.userError (tag ++ "-sort-outcome"))
        admissionComparisons := admissionComparisons + 1
        match psKernelSessionIsProp fuel reference term,
            psKernelExprV2AdmissionIsPropWithFuel fuel c admissionState root with
        | .error expected,some (.error actual) =>
            require (tag ++ "-proposition-exact-error") (expected == actual)
        | .ok expected,some (.ok actual) =>
            require (tag ++ "-proposition-answer") (expected.fst == actual.snd)
        | _,none => throw (IO.userError (tag ++ "-proposition-fallback"))
        | _,_ => throw (IO.userError (tag ++ "-proposition-outcome"))
        admissionComparisons := admissionComparisons + 1
        match psKernelSessionWhnf fuel reference term,
            psKernelExprV2TryWhnfOwnedWithDeclarationsFuel fuel limited admissionArena
              initial.whnf.declarations root with
        | .error expected,some (.error actual) =>
            require (tag ++ "-public-whnf-exact-error") (expected == actual)
        | .ok expected,some (.ok actual) =>
            let decoded ← expect (psKernelExprV2DecodeChecked actual.fst)
            let actualTerm ← expect (psKernelExprV2DecodedRequire decoded actual.snd)
            require (tag ++ "-public-whnf-result") (psKernelExprEqual expected.fst actualTerm)
        | _,none => throw (IO.userError (tag ++ "-public-whnf-fallback"))
        | _,_ => throw (IO.userError (tag ++ "-public-whnf-outcome"))
        publicWhnfComparisons := publicWhnfComparisons + 1
  let bare := psKernelExprV2CheckContextEmpty scalar
  errorIs "admission-sort-zero-before-syntactic-sort" "kernel reduction budget exhausted"
    (psKernelExprV2AdmissionEnsureSortWithFuel 0 bare admissionState s0Id)
  errorIs "admission-proposition-zero-is-inference" "kernel inference budget exhausted"
    (psKernelExprV2AdmissionIsPropWithFuel 0 bare admissionState propositionRoot)
  let legacyName := nm "admissionLegacy"
  let legacy := psKernelLocalContextAddLet psKernelLocalContextEmpty
    legacyName legacyName nat (lit 1)
  let mixed := psKernelExprV2CheckContextEmpty { scalar with localContext := legacy }
  for fuel in [0,1,8] do
    require "admission-sort-mixed-context-refusal"
      (psKernelExprV2AdmissionEnsureSortWithFuel fuel mixed initial s0Id).isNone
    require "public-owned-whnf-mixed-context-refusal"
      (psKernelExprV2TryWhnfOwnedWithDeclarationsFuel fuel mixed.scalar
        initial.whnf.arena initial.whnf.declarations s0Id).isNone
  require "admission-carrier-complete" (admissionProbes == 8 && admissionPropagation == 12)
  require "admission-differential-complete"
    (admissionComparisons == 336 && publicWhnfComparisons == 168)
  IO.println s!"PSC1_V2_ADMISSION_OWNED_STATE_PASS carrier={admissionProbes} propagated={admissionPropagation} differential={admissionComparisons} publicWhnf={publicWhnfComparisons}"

private def regression : IO Unit := do
  let empty ← expectPublic (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let natDecl := PsKernelSimpleInductiveDecl.mk [] psKernelNatName (.sort one)
    [PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
     PsKernelSimpleConstructorDecl.mk psKernelNatSuccName (all "n" nat nat)] false 0
  let withNat ← expectPublic (psKernelV1AdmitDeclaration empty (.ordinaryInductive natDecl))
  let universeName := nm "u"
  let eqDecl := PsKernelSimpleInductiveDecl.mk [universeName] psKernelEqName
    (psKernelExpectedEqType universeName)
    [PsKernelSimpleConstructorDecl.mk (PsKernelName.str psKernelEqName "refl")
      (psKernelExpectedEqReflType universeName)] false 2
  let withEq ← expectPublic (psKernelV1AdmitDeclaration withNat.session (.ordinaryInductive eqDecl))
  let withQuot ← expectPublic (psKernelV1AdmitDeclaration withEq.session .quot)
  let unitName := nm "CarrierUnit"
  let unitCtorName := PsKernelName.str unitName "mk"
  let unitDecl := PsKernelSimpleInductiveDecl.mk [] unitName (.sort one)
    [PsKernelSimpleConstructorDecl.mk unitCtorName (.const unitName [])] false 0
  let withUnit ← expectPublic (psKernelV1AdmitDeclaration withQuot.session (.ordinaryInductive unitDecl))
  let aliasName := nm "carrierAlias"
  let aliasInfo := PsKernelDefinitionInfo.mk
    (PsKernelConstantBase.mk aliasName [] nat) (lit 2) (.regular 1) .safe
  let withAlias ← expectPublic (psKernelV1AdmitDeclaration withUnit.session (.definitionDecl aliasInfo))
  let session := withAlias.session
  let scalar := (psKernelKernelSessionChecker session [] .safe).context
  let (arena,s0Id) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
  let (arena,s1Id) ← expect (psKernelExprV2PagedMkSort arena one)
  let (arena,natId) ← expect (psKernelExprV2PagedMkConst arena psKernelNatName [])
  let (arena,succTypeId) ← expect (psKernelExprV2PagedMkForall arena (nm "n") natId natId .default)
  let request := PsKernelDagDeclarationRequest.ordinaryInductive [] 0
    (PsKernelDagInductive.mk psKernelNatName s1Id
      [PsKernelDagConstructor.mk psKernelNatZeroName natId,
       PsKernelDagConstructor.mk psKernelNatSuccName succTypeId]) false
  let (arena,zeroId) ← expect (psKernelExprV2PagedMkLit arena (.nat 0))
  let (arena,oneId) ← expect (psKernelExprV2PagedMkLit arena (.nat 1))
  let (arena,twoId) ← expect (psKernelExprV2PagedMkLit arena (.nat 2))
  let (arena,aliasId) ← expect (psKernelExprV2PagedMkConst arena aliasName [])
  let (arena,unitType) ← expect (psKernelExprV2PagedMkConst arena unitName [])
  let (arena,unitLeft) ← expect (psKernelExprV2PagedMkFVar arena (nm "unitLeft"))
  let (arena,unitRight) ← expect (psKernelExprV2PagedMkFVar arena (nm "unitRight"))
  let (arena,boolTrue) ← expect (psKernelExprV2PagedMkConst arena psKernelBoolTrueName [])
  let (arena,strId) ← expect (psKernelExprV2PagedMkLit arena (.str "λ😀"))
  let (arena,strBuilt) ← expect (psKernelExprV2StringLitToConstructorOnCanonical arena "λ😀")
  let (arena,addHead) ← expect (psKernelExprV2PagedMkConst arena (PsKernelName.str psKernelNatName "add") [])
  let (arena,addPartial) ← expect (psKernelExprV2PagedMkApp arena addHead oneId)
  let (arena,addId) ← expect (psKernelExprV2PagedMkApp arena addPartial twoId)
  let (arena,wrappedSort) ← expect (psKernelExprV2PagedMkMData arena 61 s0Id)
  let (arena,aType) ← expect (psKernelExprV2PagedMkFVar arena (nm "A"))
  let (arena,aValue) ← expect (psKernelExprV2PagedMkFVar arena (nm "a"))
  let (arena,bValue) ← expect (psKernelExprV2PagedMkFVar arena (nm "b"))
  let (arena,fnId) ← expect (psKernelExprV2PagedMkFVar arena (nm "f"))
  let (arena,boundId) ← expect (psKernelExprV2PagedMkBVar arena 0)
  let (arena,fnType) ← expect (psKernelExprV2PagedMkForall arena (nm "x") aType aType .default)
  let (arena,wrappedFn) ← expect (psKernelExprV2PagedMkMData arena 62 fnType)
  let (arena,applicationId) ← expect (psKernelExprV2PagedMkApp arena fnId aValue)
  let (arena,lambdaId) ← expect (psKernelExprV2PagedMkLam arena (nm "x") aType boundId .default)
  let (arena,forallId) ← expect (psKernelExprV2PagedMkForall arena (nm "x") aType aType .default)
  let (arena,letId) ← expect (psKernelExprV2PagedMkLet arena (nm "x") aType aValue boundId false)
  let (arena,dependentForall) ← expect (psKernelExprV2PagedMkForall arena (nm "x") natId boundId .default)
  let relation := apps (.const psKernelEqName [one]) [nat]
  let identity := lam "x" nat (.bvar 0)
  let respect := lam "a" nat (lam "b" nat
    (lam "h" (apps relation [.bvar 1,.bvar 0]) (.bvar 0)))
  let quotientMajor := apps (.const psKernelQuotMkName [one]) [nat,relation,lit 0]
  let quotientLift := apps (.const psKernelQuotLiftName [one,one])
    [nat,relation,nat,identity,respect,quotientMajor]
  let recursorName := psKernelSimpleRecName psKernelNatName
  let recursor := apps (.const recursorName [one])
    [lam "n" nat nat,lit 2,lam "n" nat (lam "ih" nat (.bvar 0)),lit 0]
  let projectionMajor : PsKernelExpr := .app (.const psKernelNatSuccName []) (lit 1)
  let (arena,quotId) ← expect (psKernelExprV2PagedImportIntoChecked arena quotientLift)
  let (arena,recId) ← expect (psKernelExprV2PagedImportIntoChecked arena recursor)
  let (arena,projMajor) ← expect (psKernelExprV2PagedImportIntoChecked arena projectionMajor)
  let (arena,projId) ← expect (psKernelExprV2PagedMkProj arena psKernelNatName 0 projMajor)
  let (_,quotArgs) ← expect (psKernelExprV2TransformAppSpineOnCanonical arena quotId)
  let some quotMajor := psKernelExprV2TransformNatGet quotArgs 5
    | throw (IO.userError "missing quotient major")
  let (_,recArgs) ← expect (psKernelExprV2TransformAppSpineOnCanonical arena recId)
  let some recMajor := psKernelExprV2TransformNatGet recArgs 3
    | throw (IO.userError "missing recursor major")
  let (_,projArgs) ← expect (psKernelExprV2TransformAppSpineOnCanonical arena projMajor)
  let some projField := psKernelExprV2TransformNatGet projArgs 0
    | throw (IO.userError "missing projection field")
  let terms : List (String × PsKernelExpr) := [
    ("metadata",.mdata 71 (.sort .zero)),
    ("beta",.app identity (lit 1)),
    ("zeta",.letE (nm "x") nat (lit 2) (.bvar 0) false),
    ("nat",apps (.const (PsKernelName.str psKernelNatName "add") []) [lit 1,lit 2]),
    ("quot",quotientLift),("iota",recursor)]
  let mut input := arena
  let mut differential : List (String × PsKernelExpr × Nat) := []
  for (label,term) in terms do
    let (updated,root) ← expect (psKernelExprV2PagedImportIntoChecked input term)
    input := updated
    differential := differential ++ [(label,term,root)]
  let decoded ← expect (psKernelExprV2DecodeChecked input)
  let unitRequest := PsKernelDagDeclarationRequest.ordinaryInductive [] 0
    (PsKernelDagInductive.mk unitName s1Id [PsKernelDagConstructor.mk unitCtorName unitType]) false
  let aliasRequest := PsKernelDagDeclarationRequest.definitionDecl
    (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk aliasName [] natId)
      twoId (.regular 1) .safe)
  let declarations := psKernelDagDeclarationsAfterAdmission aliasRequest
    (psKernelDagDeclarationsAfterAdmission unitRequest
      (psKernelDagDeclarationsAfterAdmission request []))
  let generated ← expect (psKernelDagGeneratedAfterCommand (.admit request) session.environment
    (PsKernelDagGeneratedState.mk input decoded declarations))
  let initial := psKernelExprV2CheckStateWithWhnf
    (psKernelExprV2CheckStateEmpty generated.arena)
    (psKernelExprV2WhnfStateForDeclarations generated.arena generated.declarations)
  let context := psKernelExprV2CheckContextWithLocal
    (psKernelExprV2CheckContextWithLocal
      (psKernelExprV2CheckContextWithLocal (psKernelExprV2CheckContextEmpty scalar)
        (nm "A") (nm "A") wrappedSort .default)
      (nm "a") (nm "a") aType .default)
    (nm "f") (nm "f") wrappedFn .default
  let context := psKernelExprV2CheckContextWithLocal
    (psKernelExprV2CheckContextWithLocal
      (psKernelExprV2CheckContextWithLocal context (nm "b") (nm "b") aType .default)
      (nm "unitLeft") (nm "unitLeft") unitType .default)
    (nm "unitRight") (nm "unitRight") unitType .default
  let forbidden : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
      Option (Except String (PsKernelExprV2CheckState × Nat)) :=
    fun (_c : PsKernelExprV2CheckContext) (_s : PsKernelExprV2CheckState) (_r : Nat) =>
      some (Except.error "unexpected carrier callback")
  let forbiddenEq : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →
      Option (Except String (PsKernelExprV2CheckState × Bool)) :=
    fun (_c : PsKernelExprV2CheckContext) (_s : PsKernelExprV2CheckState) (_a _b : Nat) =>
      some (Except.error "unexpected carrier DefEq callback")
  let mut probes := 0
  let mut propagated := 0
  let mut comparisons := 0
  let mut defeqProbes := 0
  let mut defeqPropagation := 0
  for seed in [2,11] do
    let state ← expect (stamp zeroId initial seed)
    let first := whnfStep zeroId seed seed (seed + 1)
    let second := whnfStep zeroId (seed + 1) (seed + 1) (seed + 2)
    let single := first oneId
    let natSucc ← marked "nat-successor" (seed + 1) (seed + 1)
      (reduction (psKernelExprV2TryReduceNatSuccOwnedWith single context state oneId))
    require "nat-successor-value" (psKernelExprEqual (← decode natSucc.fst natSucc.snd) (lit 2))
    probes := probes + 1
    let binary :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
        if root == oneId then first oneId c s root
        else if root == twoId then second twoId c s root
        else some (.error "unexpected Nat operand")
    let natBinary ← marked "nat-binary-second-sees-first" (seed + 2) (seed + 2)
      (reduction (psKernelExprV2TryReduceNatBinaryOwnedWith binary context state
        (PsKernelName.str psKernelNatName "add") oneId twoId))
    require "nat-binary-value" (psKernelExprEqual (← decode natBinary.fst natBinary.snd) (lit 3))
    probes := probes + 1
    let _ ← marked "quot-major-state" (seed + 1) (seed + 1)
      (reduction (psKernelExprV2TryReduceQuotOwnedWith (first quotMajor) context state quotId))
    probes := probes + 1
    let noCore : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Bool → Bool →
        Option (Except String (PsKernelExprV2CheckState × Nat)) :=
      fun (_c : PsKernelExprV2CheckContext) (_s : PsKernelExprV2CheckState)
          (_r : Nat) (_cheapRec _cheapProj : Bool) =>
        some (Except.error "unexpected carrier core callback")
    let _ ← marked "recursor-public-major" (seed + 1) (seed + 1)
      (reduction (psKernelExprV2TryReduceRecursorOwnedWith
        (first recMajor) noCore forbidden forbiddenEq context state recId false false))
    probes := probes + 1
    let cheapCore :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
          (root : Nat) (cheapRec cheapProj : Bool) =>
        if cheapRec && cheapProj then first recMajor c s root
        else some (.error "recursor flags were changed")
    let _ ← marked "recursor-cheap-major" (seed + 1) (seed + 1)
      (reduction (psKernelExprV2TryReduceRecursorOwnedWith
        forbidden cheapCore forbidden forbiddenEq context state recId true true))
    probes := probes + 1
    let projected ← marked "projection-selected-state" (seed + 2) (seed + 2)
      (psKernelExprV2TryWhnfProjectionOwnedWith (second projField) (first projMajor)
        context state projId psKernelNatName 0 projMajor false)
    require "projection-field" (psKernelExprEqual (← decode projected.fst projected.snd) (lit 1))
    probes := probes + 1
    let recurse :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
        if root == fnId then first fnId c s root
        else if root == zeroId then
          whnfStep zeroId (seed + 2) (seed + 2) (seed + 3) zeroId c s root
        else some (.error "application recursion order changed")
    let reduced :=
      fun (_c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
          (root : Nat) (cheapRec cheapProj : Bool) =>
        if root == applicationId && !cheapRec && !cheapProj then
          some ((advance zeroId s (seed + 1) (seed + 1) (seed + 2)).map
            (fun updated => (updated,some zeroId)))
        else some (.error "application reducer flags changed")
    let _ ← marked "app-function-reducer-result-chain" (seed + 3) (seed + 3)
      (psKernelExprV2TryWhnfAppOwnedWithReducer recurse reduced context state
        applicationId false false)
    probes := probes + 1
    let rootReducer :=
      fun (_c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState)
          (root : Nat) (cheapRec cheapProj : Bool) =>
        if root == applicationId && !cheapRec && !cheapProj then
          some ((advance zeroId s seed seed (seed + 1)).map (fun updated => (updated,some zeroId)))
        else some (.error "root reducer arguments changed")
    let _ ← marked "whole-public-reducer-state" (seed + 1) (seed + 1)
      (psKernelExprV2TryWhnfOwnedWithReducerFuel 8 rootReducer psKernelExprV2CheckLocalValue
        context state applicationId)
    probes := probes + 1
    let _ ← marked "whole-core-reducer-state" (seed + 1) (seed + 1)
      (psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel 8 false false
        psKernelExprV2CheckLocalValue forbidden rootReducer context state applicationId)
    probes := probes + 1
    let sortResult ← attempt "ensure-sort"
      (psKernelExprV2CheckEnsureSortOwnedWith (first s0Id) context state wrappedSort)
    require "ensure-sort-universe" (psKernelLevelNormalizesToZero sortResult.snd)
    let _ ← marked "ensure-sort-state" (seed + 1) (seed + 1)
      (some (.ok (sortResult.fst,s0Id)))
    probes := probes + 1
    let forallResult ← attempt "ensure-forall"
      (psKernelExprV2CheckEnsureForallOwnedWith (first fnType) context state wrappedFn)
    require "ensure-forall-domain" (forallResult.snd.domain == aType)
    let _ ← marked "ensure-forall-state" (seed + 1) (seed + 1)
      (some (.ok (forallResult.fst,forallResult.snd.body)))
    probes := probes + 1
    let typedWhnf :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
        if root == wrappedSort then first s0Id c s root
        else if root == wrappedFn then first fnType c s root
        else some (.error "unexpected typed WHNF root")
    let lambdaResult ← marked "inference-lambda-restores-updated-parent" (seed + 1) (seed + 2)
      (psKernelExprV2TryInferCoreOwnedWithFuel 8 typedWhnf forbiddenEq context state lambdaId false)
    require "lambda-returned-type-owned"
      (lambdaResult.fst.whnf.arena.size > state.whnf.arena.size)
    probes := probes + 1
    let applicationResult ← marked "checked-application-retains-whnf-state" (seed + 1) (seed + 1)
      (psKernelExprV2TryInferCoreOwnedWithFuel 8 typedWhnf forbiddenEq context state applicationId false)
    require "checked-application-type" (applicationResult.snd == aType)
    probes := probes + 1
    let letDefEq :=
      fun (_c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (left right : Nat) =>
        if left == aType && right == aType then
          some ((advance zeroId s (seed + 1) (seed + 1) (seed + 2)).map (fun updated => (updated,true)))
        else some (.error "let comparison arguments changed")
    let letResult ← marked "let-defeq-and-local-scope-state" (seed + 2) (seed + 3)
      (psKernelExprV2TryInferCoreOwnedWithFuel 8 typedWhnf letDefEq context state letId false)
    require "let-returned-type" (letResult.snd == aType)
    probes := probes + 1
    let forallWhnf :=
      fun (c : PsKernelExprV2CheckContext) (s : PsKernelExprV2CheckState) (root : Nat) =>
        if root == wrappedSort then
          if s.nextFresh == seed then first s0Id c s root
          else whnfStep zeroId (seed + 1) (seed + 2) (seed + 3) s0Id c s root
        else some (.error "forall callback root changed")
    let forallType ← marked "forall-close-keeps-child-arena-and-restores-parent" (seed + 1) (seed + 3)
      (psKernelExprV2TryInferCoreOwnedWithFuel 8 forallWhnf forbiddenEq context state forallId false)
    require "forall-child-arena-retained"
      ((List.range forallType.fst.whnf.arena.size).any (fun index =>
        match psKernelExprV2PagedRequire forallType.fst.whnf.arena index with
        | .ok entry => match entry.node with | .lit (.nat value) => value == 9000 + seed + 3 | _ => false
        | .error _ => false))
    probes := probes + 1
    let parameter ← marked "projection-parameter-instantiation-state" (seed + 1) (seed + 1)
      (psKernelExprV2CheckProjectionApplyParamsOwnedWithFuel 2 (first dependentForall)
        context state [twoId] 0 1 dependentForall)
    require "projection-parameter-value" (parameter.snd == twoId)
    probes := probes + 1
    let _ ← marked "projection-field-instantiation-state" (seed + 1) (seed + 1)
      (psKernelExprV2CheckProjectionSkipFieldsOwnedWithFuel 2 forbidden (first dependentForall)
        context state psKernelNatName projMajor false 1 0 dependentForall)
    probes := probes + 1
    let projectedSort ← attempt "projection-sort"
      (psKernelExprV2CheckProjectionSortOwnedWith (first s0Id) context state s0Id)
    require "projection-sort-universe" (psKernelLevelNormalizesToZero projectedSort.snd)
    let _ ← marked "projection-sort-always-calls-whnf" (seed + 1) (seed + 1)
      (some (.ok (projectedSort.fst,s0Id)))
    probes := probes + 1
    let projectedProp ← attempt "projection-prop"
      (psKernelExprV2CheckProjectionIsPropOwnedWith (first s0Id) (second s0Id)
        context state aType)
    require "projection-prop-decision" projectedProp.snd
    let _ ← marked "projection-prop-callback-chain" (seed + 2) (seed + 2)
      (some (.ok (projectedProp.fst,s0Id)))
    probes := probes + 1
    let finalField ← marked "projection-final-domain-state" (seed + 1) (seed + 1)
      (psKernelExprV2CheckProjectionFinalOwnedWith forbidden (first dependentForall)
        context state false dependentForall)
    require "projection-final-domain" (finalField.snd == natId)
    probes := probes + 1
    let inferredApp ← marked "inference-only-application-retains-whnf-state" (seed + 1) (seed + 1)
      (psKernelExprV2TryInferCoreOwnedWithFuel 8 typedWhnf forbiddenEq context state applicationId true)
    require "inference-only-application-type" (inferredApp.snd == aType)
    probes := probes + 1
    let (defeqCount, propagatedCount, defeqPropagationCount) ←
      runDefEqAndFailureProbes context state seed
        s0Id s1Id natId zeroId oneId twoId aliasId
        unitType unitLeft unitRight boolTrue strId strBuilt addId
        wrappedSort aType aValue bValue fnId fnType wrappedFn
        applicationId lambdaId quotId recId projMajor projId
        first second binary forbidden forbiddenEq
    defeqProbes := defeqProbes + defeqCount
    propagated := propagated + propagatedCount
    defeqPropagation := defeqPropagation + defeqPropagationCount
  for (label,term,root) in differential do
    for fuel in [0,1,2,3,8,64] do
      for (limit,depth) in [(0,0),(1,15),(1,16)] do
        let limited := { scalar with maxRecDepth := limit, recDepth := depth }
        let c := psKernelExprV2CheckContextEmpty limited
        let oldDefEq := psKernelIsDefEqWithFuel fuel
        let newDefEq := psKernelExprV2TryDefEqStateWithFuel fuel
        compareWhnf (label ++ "-public")
          (psKernelWhnfWithRecursorFuel fuel oldDefEq limited psKernelCheckerStateEmpty term)
          (psKernelExprV2CheckWhnfOwnedWithFuel fuel newDefEq c initial root)
        comparisons := comparisons + 1
        for cheapRec in [false,true] do
          for cheapProj in [false,true] do
            compareWhnf (label ++ "-core")
              (psKernelWhnfCoreWithRecursorFuel fuel oldDefEq limited psKernelCheckerStateEmpty
                term cheapRec cheapProj)
              (psKernelExprV2TryWhnfCoreOwnedWithLocalValuesFuel fuel newDefEq
                psKernelExprV2CheckLocalValue c initial root cheapRec cheapProj)
            comparisons := comparisons + 1
  require "complete-carrier-count" (probes == 42)
  require "complete-propagation-count" (propagated == 56)
  require "complete-resource-differential" (comparisons == 540)
  require "complete-DefEq-carrier-count" (defeqProbes == 38)
  require "complete-DefEq-propagation-count" (defeqPropagation == 44)
  let bare := psKernelExprV2CheckContextEmpty scalar
  let rootDefEq := psKernelExprV2TryDefEqStateWithFuel 32
  let some (_,_,betaRoot) := differential.find? (fun row => row.1 == "beta")
    | throw (IO.userError "missing beta fixture")
  let warmed ← attempt "warm-public"
    (psKernelExprV2CheckWhnfOwnedWithFuel 32 rootDefEq bare initial betaRoot)
  require "public-cache-really-warm" (!warmed.fst.whnf.publicCache.isEmpty)
  errorIs "public-zero-before-warm-cache" "kernel reduction budget exhausted"
    (psKernelExprV2CheckWhnfOwnedWithFuel 0 rootDefEq bare warmed.fst betaRoot)
  errorIs "core-zero-before-warm-cache" "kernel reduction budget exhausted"
    (psKernelExprV2CheckWhnfCoreOwnedWithFuel 0 rootDefEq bare warmed.fst betaRoot false)
  let exhausted := { bare with scalar := { scalar with maxRecDepth := 1, recDepth := psKernelRecDepthFactor } }
  errorIs "core-depth-before-warm-cache"
    "deep recursion detected, use maxRecDepth to increase the limit"
    (psKernelExprV2CheckWhnfCoreOwnedWithFuel 32 rootDefEq exhausted warmed.fst betaRoot false)
  let inferred ← attempt "warm-inference"
    (psKernelExprV2TryInferCoreOwnedWithFuel 8 forbidden forbiddenEq bare initial wrappedSort false)
  require "inference-cache-really-warm" (!inferred.fst.checkedInfer.isEmpty)
  errorIs "inference-zero-before-cache" "kernel inference budget exhausted"
    (psKernelExprV2TryInferCoreOwnedWithFuel 0 forbidden forbiddenEq bare inferred.fst wrappedSort false)
  errorIs "inference-depth-before-cache"
    "deep recursion detected, use maxRecDepth to increase the limit"
    (psKernelExprV2TryInferCoreOwnedWithFuel 8 forbidden forbiddenEq exhausted inferred.fst wrappedSort false)
  errorIs "recursor-zero-before-syntax" "kernel recursor budget exhausted"
    (psKernelExprV2TryReduceRecursorOwnedWithFuel 0 forbiddenEq psKernelExprV2CheckLocalValue
      bare initial (initial.whnf.arena.size + 1) false false)
  let shadowName := nm "ownedShadow"
  let (shadowArena,shadowId) ← expect (psKernelExprV2PagedMkFVar initial.whnf.arena shadowName)
  let shadowState := psKernelExprV2CheckStateWithArena initial shadowArena
  let oldLocal := psKernelExprV2CheckContextWithLet bare shadowName shadowName natId oneId
  let newLocal := psKernelExprV2CheckContextWithLet oldLocal shadowName shadowName natId twoId
  let noValue := psKernelExprV2CheckContextWithLocal oldLocal shadowName shadowName natId .default
  for (label,c,expected) in [("old",oldLocal,oneId),("new",newLocal,twoId),("no-value",noValue,shadowId)] do
    let result ← attempt ("context-aware-local-" ++ label)
      (psKernelExprV2CheckWhnfOwnedWithFuel 8 rootDefEq c shadowState shadowId)
    require ("context-aware-local-result-" ++ label) (result.snd == expected)
  let legacy := psKernelLocalContextAddLet psKernelLocalContextEmpty shadowName shadowName nat (lit 1)
  let mixed := { noValue with scalar := { scalar with localContext := legacy } }
  for fuel in [0,1,8] do
    require "owned-legacy-refusal-precedes-fuel"
      (psKernelExprV2CheckWhnfOwnedWithFuel fuel rootDefEq mixed shadowState shadowId).isNone
    require "raw-legacy-refusal-precedes-fuel"
      (psKernelExprV2CheckWhnfWithFuel fuel mixed shadowState.whnf shadowId).isNone
    for cheapProj in [false,true] do
      require "owned-core-legacy-refusal"
        (psKernelExprV2CheckWhnfCoreOwnedWithFuel fuel rootDefEq mixed shadowState shadowId cheapProj).isNone
      require "raw-core-legacy-refusal"
        (psKernelExprV2CheckWhnfCoreWithFuel fuel mixed shadowState.whnf shadowId cheapProj).isNone
  admissionOwnedRegression scalar initial context differential zeroId oneId s0Id s1Id wrappedSort
  require "published-fuel-unchanged" (psKernelResourcePolicyDefault.fuel == 4096)
  IO.println s!"PSC1_V2_OWNED_STATE_PASS carrier={probes} propagated={propagated} differential={comparisons} defeqCarrier={defeqProbes} defeqPropagated={defeqPropagation}"

def main : IO Unit := regression
