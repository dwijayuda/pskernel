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
  let session := withQuot.session
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
  let (arena,wrappedSort) ← expect (psKernelExprV2PagedMkMData arena 61 s0Id)
  let (arena,aType) ← expect (psKernelExprV2PagedMkFVar arena (nm "A"))
  let (arena,aValue) ← expect (psKernelExprV2PagedMkFVar arena (nm "a"))
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
  let declarations := psKernelDagDeclarationsAfterAdmission request []
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
  require "published-fuel-unchanged" (psKernelResourcePolicyDefault.fuel == 4096)
  IO.println s!"PSC1_V2_OWNED_STATE_PASS carrier={probes} propagated={propagated} differential={comparisons}"

def main : IO Unit := regression
