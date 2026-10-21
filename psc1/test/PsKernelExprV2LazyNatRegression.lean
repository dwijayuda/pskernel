import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_V2_LAZY_NAT_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError "lazy-Nat fixture admission failed")

private def nm (value : String) := PsKernelName.str .anonymous value
private def s0 := PsKernelExpr.sort PsKernelLevel.zero
private def s1 := PsKernelExpr.sort (.succ .zero)
private def cn (value : String) := PsKernelExpr.const (nm value) []

private def initialState (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) :=
  psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
    (psKernelExprV2WhnfStateForDeclarations arena declarations)

private def compare (label : String)
    (original : Except String (Prod Bool PsKernelCheckerState))
    (actual : Option (Except String (Prod PsKernelExprV2CheckState Bool))) : IO Unit := do
  match original, actual with
  | .error expected, some (.error observed) =>
      require (label ++ "-exact-error") (expected == observed)
  | .ok expected, some (.ok observed) =>
      require (label ++ "-decision") (expected.fst == observed.snd)
      require (label ++ "-fresh-owner") (expected.snd.nextFresh == observed.fst.nextFresh)
  | _, none => throw (IO.userError ("unexpected lazy-Nat fallback: " ++ label))
  | _, _ => throw (IO.userError ("lazy-Nat outcome mismatch: " ++ label))

private def sameError : PsKernelError → PsKernelError → Bool
  | .rejectedInvalid a, .rejectedInvalid b => a == b
  | .declinedUnsupported a, .declinedUnsupported b => a == b
  | .internalError a, .internalError b => a == b
  | .resourceExhausted ra a, .resourceExhausted rb b =>
      let kinds := match ra, rb with
        | .fuel, .fuel => true
        | .recursionDepth, .recursionDepth => true
        | .natSize, .natSize => true
        | .cancelled, .cancelled => true
        | .declarationLimit, .declarationLimit => true
        | .hostStack, .hostStack => true
        | _, _ => false
      kinds && a == b
  | _, _ => false

private def samePublic (original : Except PsKernelError Bool)
    (actual : Except PsKernelError PsKernelDagBatchResult) : Bool :=
  match original, actual with
  | .error a, .error b => sameError a b
  | .ok a, .ok b =>
      match b.replies with
      | [.equal value] => a == value
      | _ => false
  | _, _ => false

private def inferOfficialName : PsKernelName → Lean.Name
  | .anonymous => .anonymous
  | .str parent value => .str (inferOfficialName parent) value
  | .num parent value => .num (inferOfficialName parent) value

private def inferOfficialLevel : PsKernelLevel → Option Lean.Level
  | .zero => some .zero
  | .succ value => (inferOfficialLevel value).map Lean.Level.succ
  | .max left right => do
      return .max (← inferOfficialLevel left) (← inferOfficialLevel right)
  | .imax left right => do
      return .imax (← inferOfficialLevel left) (← inferOfficialLevel right)
  | .param name => some (.param (inferOfficialName name))
  | .mvar _ => none

private def inferOfficialBinder : PsKernelBinderInfo → Lean.BinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

private def inferOfficialExpr : PsKernelExpr → Option Lean.Expr
  | .bvar index => some (.bvar index)
  | .sort level => (inferOfficialLevel level).map Lean.Expr.sort
  | .const name levels => do
      return .const (inferOfficialName name) (← levels.mapM inferOfficialLevel)
  | .app fn arg => do
      return .app (← inferOfficialExpr fn) (← inferOfficialExpr arg)
  | .lam name domain body binderInfo => do
      return .lam (inferOfficialName name) (← inferOfficialExpr domain)
        (← inferOfficialExpr body) (inferOfficialBinder binderInfo)
  | .forallE name domain body binderInfo => do
      return .forallE (inferOfficialName name) (← inferOfficialExpr domain)
        (← inferOfficialExpr body) (inferOfficialBinder binderInfo)
  | .letE name type value body nondep => do
      return .letE (inferOfficialName name) (← inferOfficialExpr type)
        (← inferOfficialExpr value) (← inferOfficialExpr body) nondep
  | .lit (.nat value) => some (.lit (.natVal value))
  | .lit (.str value) => some (.lit (.strVal value))
  | .mdata _ body => (inferOfficialExpr body).map (Lean.Expr.mdata {})
  | .proj name index body => do
      return .proj (inferOfficialName name) index (← inferOfficialExpr body)
  | _ => none



private def lit (value : Nat) := PsKernelExpr.lit (.nat value)
private def nat := PsKernelExpr.const psKernelNatName []
private def succ (value : PsKernelExpr) :=
  PsKernelExpr.app (.const psKernelNatSuccName []) value
private def binary (text : String) (left right : PsKernelExpr) :=
  PsKernelExpr.app (.app (.const (PsKernelName.str psKernelNatName text) []) left) right

private def compareLazy (label : String)
    (original : Except String (Prod PsKernelDeltaResult PsKernelCheckerState))
    (actual : Option (Except String (Prod PsKernelExprV2CheckState Bool))) : IO Unit := do
  match original, actual with
  | .error a, some (.error b) => require (label ++ "-exact-error") (a == b)
  | .ok (.mk (.decided a) old), some (.ok next) =>
      require (label ++ "-decision") (a == next.snd)
      require (label ++ "-fresh") (old.nextFresh == next.fst.nextFresh)
  | .ok (.mk (.residual _ _) _), none => pure ()
  | _, _ => throw (IO.userError ("lazy-Nat stage outcome mismatch: " ++ label))

private def originalLazy (fuel callbackFuel : Nat)
    (context : PsKernelCheckerContext) (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :=
  psKernelDefEqLazyReductionWithFuel fuel
    (psKernelIsDefEqWithFuel callbackFuel)
    (psKernelWhnfWithRecursorFuel callbackFuel (psKernelIsDefEqWithFuel callbackFuel))
    (psKernelWhnfCoreWithRecursorFuel callbackFuel (psKernelIsDefEqWithFuel callbackFuel))
    context state left right

private def directLazy (fuel callbackFuel : Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :=
  psKernelExprV2DefEqLazyNatWithFuel fuel
    (psKernelExprV2TryDefEqStateWithFuel callbackFuel)
    (fun c s r => psKernelExprV2CheckWhnfWithFuel callbackFuel c s r)
    context state left right

private def regression : IO Unit := do
  let empty ← expectPublic (psKernelKernelSessionEmpty
    psKernelResourcePolicyDefault psKernelProviderDefault)
  let natDecl := PsKernelSimpleInductiveDecl.mk [] psKernelNatName s1
    [PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
     PsKernelSimpleConstructorDecl.mk psKernelNatSuccName
       (.forallE (nm "n") nat nat .default)] false 0
  let admitted ← expectPublic (psKernelV1AdmitDeclaration empty (.ordinaryInductive natDecl))
  let mut session := admitted.session
  let (a, sortId) ← expect (psKernelExprV2PagedImportChecked s1)
  let (a, natId) ← expect (psKernelExprV2PagedImportIntoChecked a nat)
  let (a, succTypeId) ← expect (psKernelExprV2PagedImportIntoChecked a
    (.forallE (nm "n") nat nat .default))
  let request := PsKernelDagDeclarationRequest.ordinaryInductive [] 0
    (PsKernelDagInductive.mk psKernelNatName sortId
      [PsKernelDagConstructor.mk psKernelNatZeroName natId,
       PsKernelDagConstructor.mk psKernelNatSuccName succTypeId]) false
  let mut arena := a
  let mut declarations := psKernelDagDeclarationsAfterAdmission request []
  let mut requests := [PsKernelDagCommand.admit request]
  let binaryType := PsKernelExpr.forallE (nm "a") nat
    (.forallE (nm "b") nat nat .default) .default
  for text in ["add", "shiftLeft"] do
    let n := PsKernelName.str psKernelNatName text
    let next ← expectPublic (psKernelV1AdmitDeclaration session
      (.axiomDecl (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk n [] binaryType) false)))
    session := next.session
    let (nextArena, typeId) ← expect (psKernelExprV2PagedImportIntoChecked arena binaryType)
    arena := nextArena
    let request := PsKernelDagDeclarationRequest.axiomDecl
      (PsKernelDagConstantBase.mk n [] typeId) false
    declarations := psKernelDagDeclarationsAfterAdmission request declarations
    requests := requests ++ [.admit request]
  let zero := PsKernelExpr.const psKernelNatZeroName []
  let add := binary "add" (lit 1) (lit 2)
  let identity := PsKernelExpr.lam (nm "x") nat (.bvar 0) .default
  let fixtures : List (String × PsKernelExpr × PsKernelExpr × Option Bool) := [
    ("zero-literal", zero, lit 0, some true),
    ("literal-zero", lit 0, zero, some true),
    ("successor-literal", succ (lit 4), lit 5, some true),
    ("literal-successor", lit 5, succ (lit 4), some true),
    ("successor-mismatch", succ (lit 4), lit 6, some false),
    ("predecessors-mismatch", succ (lit 4), succ (lit 5), some false),
    ("left-add", add, lit 3, some true),
    ("right-add", lit 3, add, some true),
    ("left-add-mismatch", add, lit 4, some false),
    ("both-add", add, binary "add" (lit 2) (lit 1), some true),
    ("metadata-left", .mdata 7 add, lit 3, some true),
    ("beta-left", .app identity add, lit 3, some true),
    ("zeta-left", .letE (nm "x") nat add (.bvar 0) false, lit 3, some true),
    ("metadata-arguments", binary "add" (.mdata 7 (lit 1)) (.mdata 8 (lit 2)), lit 3, some true),
    ("count-overflow", binary "shiftLeft" (lit 1) (lit 4294967296), lit 0, none)]
  Lean.initSearchPath (← Lean.findSysroot)
  let official ← Lean.importModules #[{ module := `Init }] {}
  let base := psKernelKernelSessionChecker session [] .safe
  let mut comparisons := 0
  for (label, left, right, decision) in fixtures do
    let (next, leftId) ← expect (psKernelExprV2PagedImportIntoChecked arena left)
    let (owning, rightId) ← expect (psKernelExprV2PagedImportIntoChecked next right)
    for fuel in [0,1,2,3,4,5,6,8,16,64] do
      for maxRecDepth in [0,1,2] do
        for recDepth in [0,15,16] do
          let scalar := { base.context with maxRecDepth := maxRecDepth, recDepth := recDepth }
          compare label
            (psKernelIsDefEqWithFuel fuel scalar psKernelCheckerStateEmpty left right)
            (psKernelExprV2TryDefEqStateWithFuel fuel
              (psKernelExprV2CheckContextEmpty scalar)
              (initialState owning declarations) leftId rightId)
          comparisons := comparisons + 1
    let direct := psKernelExprV2TryDefEqWithDeclarationsFuel 64
      base.context owning declarations leftId rightId
    require (label ++ "-high-budget-direct")
      (match decision, direct with
       | some expected, some (.ok actual) => expected == actual
       | none, some (.error _) => true
       | _, _ => false)
    for fuel in [0,1,2,4,8,64] do
      let limited := { session with resources := { session.resources with fuel := fuel } }
      require (label ++ "-public-failure-protocol")
        (samePublic (psKernelV1IsDefEq limited [] .safe left right)
          (psKernelV1RunDag limited [] .safe owning [.isDefEq leftId rightId]))
    if let some expected := decision then
      let batch ← expectPublic (psKernelV1RunDag empty [] .safe owning
        (requests ++ [.isDefEq leftId rightId]))
      require (label ++ "-checked-same-batch")
        (batch.replies.length == requests.length + 1 &&
          match batch.replies.reverse with | .equal actual :: _ => actual == expected | _ => false)
      let some officialLeft := inferOfficialExpr left
        | throw (IO.userError "official Nat left conversion")
      let some officialRight := inferOfficialExpr right
        | throw (IO.userError "official Nat right conversion")
      require (label ++ "-official-left-check")
        (match Lean.Kernel.check official {} officialLeft with | .ok _ => true | _ => false)
      require (label ++ "-official-right-check")
        (match Lean.Kernel.check official {} officialRight with | .ok _ => true | _ => false)
      require (label ++ "-official-decision")
        (match Lean.Kernel.isDefEq official {} officialLeft officialRight with
         | .ok actual => actual == expected | _ => false)
  require "complete-raw-matrix" (comparisons == 1350)
  let directCases := [
    ("zero", zero, lit 0), ("predecessor", succ (lit 4), lit 5),
    ("left", add, lit 3), ("right", lit 3, add),
    ("negative", add, lit 4), ("both", add, binary "add" (lit 2) (lit 1))]
  let mut stageComparisons := 0
  for (label, left, right) in directCases do
    let (next, leftId) ← expect (psKernelExprV2PagedImportIntoChecked arena left)
    let (owning, rightId) ← expect (psKernelExprV2PagedImportIntoChecked next right)
    for fuel in [0,1] do
      for callbackFuel in [0,1,4,64] do
        for eagerReduce in [false,true] do
          for maxNatSize in [0,psKernelLeanNatMaxSizeDefault] do
            let scalar := { base.context with eagerReduce := eagerReduce, maxNatSize := maxNatSize }
            compareLazy label
              (originalLazy fuel callbackFuel scalar psKernelCheckerStateEmpty left right)
              (directLazy fuel callbackFuel (psKernelExprV2CheckContextEmpty scalar)
                (initialState owning declarations) leftId rightId)
            stageComparisons := stageComparisons + 1
  require "complete-stage-matrix" (stageComparisons == 192)
  let (a, addId) ← expect (psKernelExprV2PagedImportIntoChecked arena add)
  -- Literal WHNF is deliberately uncached. Nonterminal operands exercise the
  -- public-cache state carried through the proof-to-Nat continuation.
  let warmAdd := binary "add" (binary "add" (lit 1) (lit 0))
    (binary "add" (lit 2) (lit 0))
  let (a, warmAddId) ← expect (psKernelExprV2PagedImportIntoChecked a warmAdd)
  let (a, metadataId) ← expect (psKernelExprV2PagedImportIntoChecked a (.mdata 7 warmAdd))
  let (owning, threeId) ← expect (psKernelExprV2PagedImportIntoChecked a (lit 3))
  let context := psKernelExprV2CheckContextEmpty base.context
  let cold := initialState owning declarations
  let some (.ok warm) := psKernelExprV2TryDefEqStateWithFuel 64 context cold metadataId threeId
    | throw (IO.userError "warm lazy-Nat owner")
  let oldWarm ← expect (psKernelIsDefEqWithFuel 64 base.context
    psKernelCheckerStateEmpty (.mdata 7 warmAdd) (lit 3))
  require "nonprop-inference-state-survives-nat-continuation"
    (!(psKernelExprV2WhnfCacheEntries warm.fst.inferOnly).isEmpty && (psKernelExprV2WhnfCacheEntries warm.fst.checkedInfer).isEmpty &&
      !(psKernelExprV2WhnfCacheEntries warm.fst.whnf.publicCache).isEmpty)
  require "nat-success-publishes-original-pair"
    (← expect (psKernelExprV2DefEqPairContains warm.fst.whnf.arena
      warm.fst.success metadataId threeId))
  require "nat-success-does-not-publish-normalized-pair"
    (!(← expect (psKernelExprV2DefEqPairContains warm.fst.whnf.arena
      warm.fst.success warmAddId threeId)))
  let some (.ok rightReduced) := directLazy 1 64 context cold threeId addId
    | throw (IO.userError "right Nat reduction after discarded predecessor")
  require "unused-predecessor-not-retained-by-eager-reduction"
    (rightReduced.snd && rightReduced.fst.whnf.arena.size == owning.size + 1)
  let .app first arg2 := (← expect (psKernelExprV2PagedRequire warm.fst.whnf.arena warmAddId)).node
    | throw (IO.userError "Nat binary root shape")
  let .app _ arg1 := (← expect (psKernelExprV2PagedRequire warm.fst.whnf.arena first)).node
    | throw (IO.userError "Nat binary head shape")
  for argument in [arg1,arg2] do
    let entry ← expect (psKernelExprV2PagedRequire warm.fst.whnf.arena argument)
    let cached ← expect (psKernelExprV2WhnfPublicCacheFind warm.fst.whnf argument entry)
    require "Nat-operand-whnf-state-published" cached.isSome
  for fuel in [0,1,64] do
    for recDepth in [0,15,16] do
      let scalar := { base.context with maxRecDepth := 1, recDepth := recDepth }
      compare "warm-entry-guards"
        (psKernelIsDefEqWithFuel fuel scalar oldWarm.snd (.mdata 7 warmAdd) (lit 3))
        (psKernelExprV2TryDefEqStateWithFuel fuel
          (psKernelExprV2CheckContextEmpty scalar) warm.fst metadataId threeId)
  let (zeroArena, zeroId) ← expect (psKernelExprV2PagedImportIntoChecked owning zero)
  let (zeroArena, literalZeroId) ← expect (psKernelExprV2PagedImportIntoChecked zeroArena (lit 0))
  let blocked := { base.context with maxRecDepth := 1, recDepth := 16 }
  compareLazy "lazy-helper-has-no-extra-depth-entry"
    (originalLazy 1 0 blocked psKernelCheckerStateEmpty zero (lit 0))
    (directLazy 1 0 (psKernelExprV2CheckContextEmpty blocked)
      (initialState zeroArena declarations) zeroId literalZeroId)
  require "lazy-zero-fuel-precedes-root-access"
    (match directLazy 0 64 context cold (owning.size + 1) (owning.size + 2) with
     | some (.error error) => error == "kernel lazy-delta budget exhausted" | _ => false)
  let localName := nm "natLocal"
  let localExpr := PsKernelExpr.fvar localName
  let openAdd := binary "add" (.letE (nm "unused") nat localExpr (lit 1) false) (lit 2)
  let (a, openId) ← expect (psKernelExprV2PagedImportIntoChecked owning openAdd)
  let (a, localSuccId) ← expect (psKernelExprV2PagedImportIntoChecked a (succ localExpr))
  let oldLocals := psKernelLocalContextAddLocal base.context.localContext localName localName nat .default
  for eagerReduce in [false,true] do
    let scalar := { base.context with eagerReduce := eagerReduce }
    let oldContext := psKernelCheckerContextWithLocalContext scalar oldLocals
    let typed := psKernelExprV2CheckContextWithLocal
      (psKernelExprV2CheckContextEmpty scalar) localName localName natId .default
    let state := initialState a declarations
    let attempt := directLazy 1 64 typed state openId threeId
    compareLazy "eager-open-syntax"
      (originalLazy 1 64 oldContext psKernelCheckerStateEmpty openAdd (lit 3)) attempt
    require "open-terms-obey-eager-policy"
      (if eagerReduce then match attempt with | some (.ok value) => value.snd | _ => false
       else attempt.isNone)
    compareLazy "predecessor-before-eager-decision"
      (originalLazy 1 1 oldContext psKernelCheckerStateEmpty (succ localExpr) (succ localExpr))
      (directLazy 1 1 typed state localSuccId localSuccId)
  let predecessorTerms := [
    lit 0, lit 1, lit 18446744073709551616, PsKernelExpr.lit (.str "x"),
    succ (lit 0), succ localExpr, .const psKernelNatSuccName [],
    .app (.const psKernelNatSuccName [.zero]) (lit 1),
    .app (succ (lit 1)) (lit 2), .mdata 7 (succ (lit 1)),
    .app (.mdata 7 (.const psKernelNatSuccName [])) (lit 1)]
  for term in predecessorTerms do
    let (next, root) ← expect (psKernelExprV2PagedImportIntoChecked arena term)
    let actual ← expect (psKernelExprV2DefEqNatPred (initialState next declarations) root)
    match psKernelExprNatPred term, actual.snd with
    | none, none => pure ()
    | some expected, some result =>
        let decoded ← expect (psKernelExprV2DecodeChecked actual.fst.whnf.arena)
        let observed ← expect (psKernelExprV2DecodedRequire decoded result)
        require "exact-syntactic-predecessor" (psKernelExprEqual expected observed)
    | _, _ => throw (IO.userError "Nat predecessor shape mismatch")
  let unsupported := PsKernelExpr.app (.app (.const (nm "nonPrimitive") []) (lit 1)) (lit 2)
  let (a, unsupportedId) ← expect (psKernelExprV2PagedImportIntoChecked owning unsupported)
  let noDefinition := directLazy 1 64 context (initialState a declarations) unsupportedId threeId
  require "definition-selection-remains-unsupported" noDefinition.isNone
  let invalid := binary "add" s1 (lit 2)
  let (a, invalidId) ← expect (psKernelExprV2PagedImportIntoChecked a invalid)
  require "checked-api-rejects-invalid-primitive-argument"
    (match psKernelV1RunDag empty [] .safe a (requests ++ [.isDefEq invalidId threeId]) with
     | .error (.rejectedInvalid _) => true | _ => false)
  let some officialInvalid := inferOfficialExpr invalid
    | throw (IO.userError "official invalid Nat conversion")
  require "official-rejects-invalid-primitive-argument"
    (match Lean.Kernel.check official {} officialInvalid with | .error _ => true | _ => false)
  IO.println "PSC1_V2_DAG_LAZY_NAT: PASS comparisons=1350 stage=192"
  IO.println "PSC1_V2_DAG_OFFICIAL_LAZY_NAT: PASS cases=14 invalid=1"

def main : IO Unit := regression
