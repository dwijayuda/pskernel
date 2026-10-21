import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_V2_PROOF_IRREL_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError "proof-irrelevance fixture admission failed")

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
  | _, none => throw (IO.userError ("unexpected proof-irrelevance fallback: " ++ label))
  | _, _ => throw (IO.userError ("proof-irrelevance outcome mismatch: " ++ label))

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



private def regression : IO Unit := do
  let empty ← expectPublic
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let mut session := empty
  let mut arena := psKernelExprV2PagedEmpty
  let mut declarations : List PsKernelExprV2DeclarationRef := []
  let mut requests : List PsKernelDagCommand := []
  let universal := PsKernelExpr.forallE (nm "p") s0 (.bvar 0) .default
  let otherUniversal := PsKernelExpr.forallE (nm "A") s1 universal .default
  let specifications : List (String × PsKernelExpr × Bool) := [
    ("proofP", s0, false), ("proofMax", .sort (.max .zero .zero), false),
    ("proofLeft", cn "proofP", false), ("proofRight", cn "proofP", false),
    ("proofMaxLeft", cn "proofMax", false), ("proofMaxRight", cn "proofMax", false),
    ("proofAllLeft", universal, false), ("proofAllRight", universal, false),
    ("proofOther", otherUniversal, false), ("proofUnsafe", cn "proofP", true),
    ("proofFunction", .forallE (nm "x") (cn "proofP") (cn "proofP") .default, false),
    ("proofQ", s0, false), ("proofQRight", cn "proofQ", false),
    ("nonProofLeft", s1, false), ("nonProofRight", s1, false)]
  let mut official ← Lean.mkEmptyEnvironment
  for (text, type, isUnsafe) in specifications do
    let name := nm text
    let (next, root) ← expect (psKernelExprV2PagedImportIntoChecked arena type)
    let admitted ← expectPublic (psKernelV1AdmitDeclaration session
      (.axiomDecl (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk name [] type) isUnsafe)))
    session := admitted.session
    arena := next
    let request := PsKernelDagDeclarationRequest.axiomDecl
      (PsKernelDagConstantBase.mk name [] root) isUnsafe
    declarations := psKernelDagDeclarationsAfterAdmission request declarations
    requests := requests ++ [.admit request]
    let some officialType := inferOfficialExpr type
      | throw (IO.userError "official proof type conversion")
    match official.addDeclCore 0 0
        (.axiomDecl { name := inferOfficialName name, levelParams := [],
          type := officialType, isUnsafe := isUnsafe }) none true with
    | .ok next => official := next
    | .error _ => throw (IO.userError ("official axiom fixture " ++ text))
  let p := cn "proofLeft"
  let q := cn "proofRight"
  let prop := cn "proofP"
  let mvar := PsKernelExpr.mvar (nm "untrusted")
  let unchecked := PsKernelExpr.app (cn "proofFunction") mvar
  let identity := PsKernelExpr.lam (nm "x") prop (.bvar 0) .default
  let fixtures : List (String × PsKernelExpr × PsKernelExpr × Option Bool) := [
    ("proof-constants", p, q, some true),
    ("metadata-left", .mdata 7 p, q, some true),
    ("metadata-both", .mdata 7 p, .mdata 8 q, some true),
    ("beta-left", .app identity p, q, some true),
    ("zeta-left", .letE (nm "x") prop p (.bvar 0) false, q, some true),
    ("normalized-zero", cn "proofMaxLeft", cn "proofMaxRight", some true),
    ("forall-proofs", cn "proofAllLeft", cn "proofAllRight", some true),
    ("different-propositions", cn "proofAllLeft", cn "proofOther", some false),
    ("right-metavariable", p, mvar, none),
    ("left-metavariable", mvar, p, none),
    ("loose-variable", .bvar 0, p, none),
    ("illtyped-left", .app s0 s0, p, none),
    ("unknown-left-before-right", cn "notAdmitted", mvar, none),
    ("unsafe-inference-only", p, cn "proofUnsafe", some true),
    ("unchecked-argument-is-not-admission", p, unchecked, some true)]
  let mut comparisons := 0
  for (label, left, right, decision) in fixtures do
    let (next, leftId) ← expect (psKernelExprV2PagedImportIntoChecked arena left)
    let (owning, rightId) ← expect (psKernelExprV2PagedImportIntoChecked next right)
    let base := psKernelKernelSessionChecker session [] .safe
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
    let raw := psKernelExprV2TryDefEqWithDeclarationsFuel 64
      base.context owning declarations leftId rightId
    require (label ++ "-high-budget-direct")
      (match decision, raw with
       | some expected, some (.ok actual) => expected == actual
       | none, some (.error _) => true
       | _, _ => false)
    for fuel in [0,1,2,4,8,64] do
      let limited := { session with resources := { session.resources with fuel := fuel } }
      require (label ++ "-checked-public")
        (samePublic (psKernelV1IsDefEq limited [] .safe left right)
          (psKernelV1RunDag limited [] .safe owning [.isDefEq leftId rightId]))
    if label == "unsafe-inference-only" || label == "unchecked-argument-is-not-admission" then
      require (label ++ "-public-mandatory-check")
        (match psKernelV1RunDag session [] .safe owning [.isDefEq leftId rightId] with
         | .error (.rejectedInvalid _) => true | _ => false)
    if (fixtures.take 8).any (fun item => item.1 == label) then
      let some officialLeft := inferOfficialExpr left
        | throw (IO.userError "official left conversion")
      let some officialRight := inferOfficialExpr right
        | throw (IO.userError "official right conversion")
      require (label ++ "-official-left-check")
        (match Lean.Kernel.check official {} officialLeft with | .ok _ => true | _ => false)
      require (label ++ "-official-right-check")
        (match Lean.Kernel.check official {} officialRight with | .ok _ => true | _ => false)
      require (label ++ "-official-decision")
        (match decision, Lean.Kernel.isDefEq official {} officialLeft officialRight with
         | some expected, .ok actual => expected == actual | _, _ => false)
  require "complete-raw-matrix" (comparisons == 1350)
  let (next, leftId) ← expect (psKernelExprV2PagedImportIntoChecked arena p)
  let (next, rightId) ← expect (psKernelExprV2PagedImportIntoChecked next q)
  let (next, metadataId) ← expect (psKernelExprV2PagedImportIntoChecked next (.mdata 7 p))
  let (next, uncheckedId) ← expect (psKernelExprV2PagedImportIntoChecked next unchecked)
  let (next, nonLeftId) ← expect (psKernelExprV2PagedImportIntoChecked next (cn "nonProofLeft"))
  let (next, nonRightId) ← expect (psKernelExprV2PagedImportIntoChecked next (cn "nonProofRight"))
  let (owning, distinctId) ← expect (psKernelExprV2PagedImportIntoChecked next (cn "proofQRight"))
  let base := psKernelKernelSessionChecker session [] .safe
  let context := psKernelExprV2CheckContextEmpty base.context
  let cold := initialState owning declarations
  let oldWarm ← expect (psKernelIsDefEqWithFuel 64 base.context
    psKernelCheckerStateEmpty p q)
  let some (.ok warm) := psKernelExprV2TryDefEqStateWithFuel 64 context cold leftId rightId
    | throw (IO.userError "proof warm owner")
  require "proof-populates-infer-only-not-checked"
    (!warm.fst.inferOnly.isEmpty && warm.fst.checkedInfer.isEmpty)
  for fuel in [0,1,64] do
    for recDepth in [0,15,16] do
      let scalar := { base.context with maxRecDepth := 1, recDepth := recDepth }
      compare "warm-entry-guards"
        (psKernelIsDefEqWithFuel fuel scalar oldWarm.snd p q)
        (psKernelExprV2TryDefEqStateWithFuel fuel
          (psKernelExprV2CheckContextEmpty scalar) warm.fst leftId rightId)
  require "cold-fuel-one-retains-predecessor-core"
    (match psKernelExprV2TryDefEqStateWithFuel 1 context cold leftId rightId with
     | some (.error error) => error == "kernel reduction budget exhausted" | _ => false)
  let some (.ok normalized) := psKernelExprV2TryDefEqStateWithFuel 64
      context cold metadataId rightId
    | throw (IO.userError "normalized proof owner")
  require "success-publishes-original-pair"
    (← expect (psKernelExprV2DefEqPairContains normalized.fst.whnf.arena
      normalized.fst.success metadataId rightId))
  require "success-does-not-publish-normalized-proof-pair"
    (!(← expect (psKernelExprV2DefEqPairContains normalized.fst.whnf.arena
      normalized.fst.success leftId rightId)))
  let some (.ok rawUnchecked) := psKernelExprV2TryDefEqStateWithFuel 64
      context cold leftId uncheckedId
    | throw (IO.userError "unchecked proof comparison fixture")
  require "raw-infer-only-does-not-authorize-check"
    (match psKernelExprV2TryCheckStateWithFuel 64 context rawUnchecked.fst uncheckedId,
        psKernelCheckerCheck 64 base.context psKernelCheckerStateEmpty unchecked with
     | some (.error a), .error b => a == b | _, _ => false)
  require "non-proposition-retains-lazy-delta-fallback"
    (psKernelExprV2TryDefEqStateWithFuel 64 context cold nonLeftId nonRightId).isNone
  require "unsupported-descendant-discards-whole-proof-attempt"
    (psKernelExprV2TryDefEqStateWithFuel 64 context cold leftId distinctId).isNone
  require "unsupported-descendant-public-negative-parity"
    (samePublic (psKernelV1IsDefEq session [] .safe p (cn "proofQRight"))
      (psKernelV1RunDag session [] .safe owning [.isDefEq leftId distinctId]))
  require "missing-owning-index-retains-fallback"
    (psKernelExprV2TryDefEqWithDeclarationsFuel 64 base.context owning [] leftId rightId).isNone
  let (withProp, propId) ← expect (psKernelExprV2PagedImportIntoChecked owning prop)
  let state := initialState withProp declarations
  let inferType := fun c s r => psKernelExprV2TryInferStateWithFuel 64 c s r
  let noWhnf := fun c s r => psKernelExprV2CheckWhnfWithFuel 0 c s r
  require "isprop-whnf-remains-mandatory"
    (match psKernelExprV2DefEqIsPropWith inferType noWhnf context state propId with
     | some (.error error) => error == "kernel reduction budget exhausted" | _ => false)
  let (localArena, localLeft) ← expect (psKernelExprV2PagedMkFVar withProp (nm "proofLocalLeft"))
  let (localArena, localRight) ← expect (psKernelExprV2PagedMkFVar localArena (nm "proofLocalRight"))
  let oldLocals := psKernelLocalContextAddLocal base.context.localContext
    (nm "proofLocalLeft") (nm "proofLocalLeft") prop .default
  let oldLocals := psKernelLocalContextAddLocal oldLocals
    (nm "proofLocalRight") (nm "proofLocalRight") prop .default
  let oldContext := psKernelCheckerContextWithLocalContext base.context oldLocals
  require "external-scalar-locals-decline-before-typed-inference"
    (psKernelExprV2TryDefEqWithDeclarationsFuel 64 oldContext localArena
      declarations localLeft localRight).isNone
  require "external-locals-compatibility-wrapper-declines"
    (psKernelExprV2TryQuickDefEqWithFuel 64 oldContext localArena localLeft localRight).isNone
  require "external-locals-zero-fuel-keeps-entry-error"
    (match psKernelExprV2TryQuickDefEqWithFuel 0 oldContext localArena localLeft localRight with
     | some (.error error) => error == "kernel definitional equality budget exhausted"
     | _ => false)
  let typed := psKernelExprV2CheckContextWithLocal context
    (nm "proofLocalLeft") (nm "proofLocalLeft") propId .default
  let typed := psKernelExprV2CheckContextWithLocal typed
    (nm "proofLocalRight") (nm "proofLocalRight") propId .default
  let localAttempt := psKernelExprV2TryDefEqStateWithFuel 64 typed
    (initialState localArena declarations) localLeft localRight
  compare "local-proof-irrelevance"
    (psKernelIsDefEqWithFuel 64 oldContext psKernelCheckerStateEmpty
      (.fvar (nm "proofLocalLeft")) (.fvar (nm "proofLocalRight"))) localAttempt
  let some (.ok localResult) := localAttempt
    | throw (IO.userError "local proof irrelevance")
  require "local-proof-pair-never-published"
    (!(← expect (psKernelExprV2DefEqPairContains localResult.fst.whnf.arena
      localResult.fst.success localLeft localRight)))
  let batch ← expectPublic (psKernelV1RunDag empty [] .safe owning
    (requests ++ [.isDefEq leftId rightId]))
  require "real-same-batch-admission-and-proof-check"
    (batch.replies.length == requests.length + 1 &&
      match batch.replies.reverse with | .equal true :: _ => true | _ => false)
  let some invalid := inferOfficialExpr (.app s0 s0)
    | throw (IO.userError "official invalid conversion")
  require "official-rejects-invalid-proof-input"
    (match Lean.Kernel.check official {} invalid with | .error _ => true | _ => false)
  IO.println "PSC1_V2_DAG_PROOF_IRRELEVANCE: PASS comparisons=1350"
  IO.println "PSC1_V2_DAG_OFFICIAL_PROOF_IRRELEVANCE: PASS cases=8 invalid=1"

def main : IO Unit := regression
