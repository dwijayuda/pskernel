import Lean
import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport

private def require (label : String) (ok : Bool) : IO Unit := do
  unless ok do throw (IO.userError ("PSC1_V2_DAG_FAIL " ++ label))

private def expect {α : Type} (value : Except String α) : IO α := do
  match value with
  | .ok result => return result
  | .error error => throw (IO.userError error)

private def errorText : PsKernelError → String
  | .rejectedInvalid message => "invalid:" ++ message
  | .declinedUnsupported message => "unsupported:" ++ message
  | .resourceExhausted _ message => "resource:" ++ message
  | .internalError message => "internal:" ++ message

private def expectPublic {α : Type} (value : Except PsKernelError α) : IO α := do
  match value with
  | .ok result => return result
  | .error error => throw (IO.userError (errorText error))

private def fresh (fuel : Nat := 4096) (depth : Nat := 0) :
    IO PsKernelKernelSession :=
  expectPublic (psKernelKernelSessionEmpty
    { psKernelResourcePolicyDefault with fuel := fuel, maxRecDepth := depth }
    psKernelProviderDefault)

private def sort0 := PsKernelExpr.sort PsKernelLevel.zero
private def sort1 := PsKernelExpr.sort (.succ .zero)
private def nm (text : String) := PsKernelName.str .anonymous text

private def checkReply (result : PsKernelDagBatchResult) : Option PsKernelCheckedExpression :=
  match result.replies with
  | .cons (.checked value) .nil => some value
  | _ => none

private def sameCheck
    (legacy : Except PsKernelError PsKernelCheckedExpression)
    (dag : Except PsKernelError PsKernelDagBatchResult) : Bool :=
  match legacy, dag with
  | .error a, .error b => errorText a == errorText b
  | .ok a, .ok b =>
      match checkReply b with
      | some value =>
          psKernelExprEqual a.expression value.expression &&
            psKernelExprEqual a.type value.type
      | none => false
  | _, _ => false

private def sameWhnf
    (legacy : Except PsKernelError PsKernelExpr)
    (dag : Except PsKernelError PsKernelDagBatchResult) : Bool :=
  match legacy, dag with
  | .error a, .error b => errorText a == errorText b
  | .ok a, .ok b =>
      match b.replies with
      | [.normalized value] => psKernelExprEqual a value
      | _ => false
  | _, _ => false

private def sameDefEq
    (legacy : Except PsKernelError Bool)
    (dag : Except PsKernelError PsKernelDagBatchResult) : Bool :=
  match legacy, dag with
  | .error a, .error b => errorText a == errorText b
  | .ok a, .ok b =>
      match b.replies with
      | [.equal value] => a == value
      | _ => false
  | _, _ => false

private def oneCheck
    (session : PsKernelKernelSession)
    (arena : PsKernelExprV2PagedArena) (root : Nat) :=
  psKernelV1RunDag session [] .safe arena [.check root]

private def constructorDecode : IO Unit := do
  let s0 := sort0
  let s1 := sort1
  let b := PsKernelExpr.bvar 0
  let terms := [
    b, PsKernelExpr.fvar (nm "f"), PsKernelExpr.mvar (nm "m"), s0,
    PsKernelExpr.const (nm "C") [.param (nm "u")],
    PsKernelExpr.app s0 b,
    PsKernelExpr.lam (nm "a") s1 b .implicit,
    PsKernelExpr.forallE (nm "b") s1 b .strictImplicit,
    PsKernelExpr.letE (nm "c") s1 s0 b true,
    PsKernelExpr.lit (.nat 15), PsKernelExpr.lit (.str "λ-雪"),
    PsKernelExpr.mdata 73 b, PsKernelExpr.proj (nm "S") 2 b
  ]
  for term in terms do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    let decoded ← expect (psKernelExprV2DecodeChecked arena)
    let actual ← expect (psKernelExprV2DecodedRequire decoded root)
    require "all-constructor-exact-decode" (psKernelExprEqual actual term)
    require "decode-once-count" (decoded.size == arena.size)
  let mut arena := psKernelExprV2PagedEmpty
  for i in [:257] do
    let (next, id) ← expect (psKernelExprV2PagedMkBVar arena i)
    require "stable-node-ids" (id == i)
    arena := next
  let decoded ← expect (psKernelExprV2DecodeChecked arena)
  require "paged-decoding" (decoded.size == 257 && decoded.pages.size == 4)
  for i in [0, 63, 64, 127, 128, 255, 256] do
    let term ← expect (psKernelExprV2DecodedRequire decoded i)
    require "paged-boundaries" (psKernelExprEqual term (.bvar i))
  require "decoded-invalid-reference"
    (match psKernelExprV2DecodedRequire decoded 257 with | .error _ => true | _ => false)

private def semanticParity : IO Unit := do
  let identity := PsKernelExpr.lam .anonymous sort1 (.bvar 0) .default
  let beta := PsKernelExpr.app identity sort0
  let zeta := PsKernelExpr.letE .anonymous sort1 sort0 (.bvar 0) false
  let hidden := PsKernelExpr.app
    (.letE .anonymous (.forallE .anonymous sort1 sort1 .default) identity (.bvar 0) false)
    sort0
  let invalid := PsKernelExpr.app sort0 sort0
  let terms := [sort0, sort1, identity, beta, zeta, hidden,
    .mdata 2 beta, invalid, .bvar 0, .mvar (nm "m"), .fvar (nm "f"),
    .const (nm "missing") [], .sort (.param (nm "undeclared"))]
  for term in terms do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,2,3,4,6,12,64] do
      for depth in [0,1,2,4] do
        let session ← fresh fuel depth
        require "exact-check-and-resource-parity"
          (sameCheck
            (psKernelV1CheckExpression session [] .safe term)
            (oneCheck session arena root))
        require "exact-whnf-and-resource-parity"
          (sameWhnf
            (psKernelV1Whnf session [] .safe term)
            (psKernelV1RunDag session [] .safe arena [.whnf root]))
        require "checked-identity-and-resource-parity"
          (sameDefEq
            (psKernelV1IsDefEq session [] .safe term term)
            (psKernelV1RunDag session [] .safe arena [.isDefEq root root]))
  let session ← fresh
  for term in [beta, zeta, hidden, .mdata 1 zeta] do
    let (a, root) ← expect (psKernelExprV2PagedImportChecked term)
    let (arena, target) ← expect (psKernelExprV2PagedMkSort a .zero)
    let result ← expectPublic
      (psKernelV1RunDag session [] .safe arena
        [.check root, .whnf root, .isDefEq root target])
    require "complete-check-whnf-defeq"
      (match result.replies with
       | [.checked checked, .normalized normalized, .equal equal] =>
           psKernelExprEq checked.type sort1 &&
             psKernelExprEq normalized sort0 && equal
       | _ => false)
  let (a, left) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
  let (arena, right) ← expect (psKernelExprV2PagedMkSort a (.succ .zero))
  let unequal ← expectPublic
    (psKernelV1RunDag session [] .safe arena [.isDefEq left right])
  require "negative-defeq"
    (match unequal.replies with | [.equal false] => true | _ => false)
  let (bad, root) ← expect (psKernelExprV2PagedImportChecked invalid)
  require "identical-id-does-not-authorize-illtyped-term"
    (match psKernelV1RunDag session [] .safe bad [.isDefEq root root] with
     | .error (.rejectedInvalid _) => true | _ => false)

private def metadataParity : IO Unit := do
  for depth in [0,1,8,16,17,32,96] do
    let mut term := sort0
    let (initial, initialRoot) ← expect
      (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
    let mut arena := initial
    let mut root := initialRoot
    for tag in [:depth] do
      term := .mdata tag term
      let (next, id) ← expect (psKernelExprV2PagedMkMData arena tag root)
      arena := next
      root := id
    for fuel in [0,1,depth,depth+1,depth+2,4096] do
      for maxDepth in [0,1,2,8] do
        let session ← fresh fuel maxDepth
        require "dag-native-metadata-fuel-and-depth-parity"
          (sameCheck
            (psKernelV1CheckExpression session [] .safe term)
            (oneCheck session arena root))
        require "metadata-whnf-fuel-and-depth-parity"
          (sameWhnf
            (psKernelV1Whnf session [] .safe term)
            (psKernelV1RunDag session [] .safe arena [.whnf root]))
        require "metadata-identity-fuel-and-depth-parity"
          (sameDefEq
            (psKernelV1IsDefEq session [] .safe term term)
            (psKernelV1RunDag session [] .safe arena [.isDefEq root root]))
  IO.println "PSC1_V2_DAG_NATIVE_INFERENCE: PASS"
  IO.println "PSC1_V2_DAG_NATIVE_WHNF_IDENTITY: PASS"

private def hostileInputs : IO Unit := do
  let session ← fresh
  let (a, root) ← expect
    (psKernelExprV2PagedMkFVar psKernelExprV2PagedEmpty (nm "x"))
  let entry ← expect (psKernelExprV2PagedRequire a root)
  for changed in [
      { entry with hash := entry.hash + 1 },
      { entry with looseRange := 1 },
      { entry with hasFVar := false },
      { entry with hasExprMVar := true },
      { entry with depth := 0 }] do
    let forged := (psKernelExprV2PagedPush psKernelExprV2PagedEmpty changed).fst
    require "forged-metadata"
      (match oneCheck session forged 0 with
       | .error (.rejectedInvalid _) => true | _ => false)
  for malformed in [{ a with size := 99 }, { a with pageLimit := 0 },
      { a with pages := #[a.active], active := #[] }] do
    require "malformed-layout"
      (match oneCheck session malformed 0 with
       | .error (.rejectedInvalid _) => true | _ => false)
  let bad := PsKernelExprV2Entry.mk (.mdata 0 0) 0 0 false false 1
  let cycle := (psKernelExprV2PagedPush psKernelExprV2PagedEmpty bad).fst
  require "cycle-rejection"
    (match oneCheck session cycle 0 with
     | .error (.rejectedInvalid _) => true | _ => false)
  require "root-rejection"
    (match oneCheck session a 1 with
     | .error (.rejectedInvalid _) => true | _ => false)
  -- Sibling arenas reuse ID zero. No memo or prior verdict can cross them.
  let (left, id) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
  let (right, id2) ← expect (psKernelExprV2PagedMkMVar psKernelExprV2PagedEmpty (nm "bad"))
  require "sibling-id-equal" (id == id2)
  let _ ← expectPublic (oneCheck session left id)
  require "sibling-arena-rejection"
    (match oneCheck session right id2 with
     | .error (.rejectedInvalid _) => true | _ => false)
  let cancelled := { session with resources := { session.resources with cancelled := true } }
  require "preflight-before-invalid-graph"
    (match oneCheck cancelled cycle 0 with
     | .error (.resourceExhausted .cancelled _) => true | _ => false)

private def admissions : IO Unit := do
  let session ← fresh
  let (a, s0) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
  let (b, s1) ← expect (psKernelExprV2PagedMkSort a (.succ .zero))
  let alias := nm "DagAlias"
  let (c, aliasId) ← expect (psKernelExprV2PagedMkConst b alias [])
  let defn := PsKernelDagDefinition.mk
    (PsKernelDagConstantBase.mk alias [] s1) s0 .abbrevHint .safe
  let unitName := nm "DagUnit"
  let ctorName := PsKernelName.str unitName "mk"
  let (d, unitId) ← expect (psKernelExprV2PagedMkConst c unitName [])
  let (arena, ctorId) ← expect (psKernelExprV2PagedMkConst d ctorName [])
  let unitDecl := PsKernelDagInductive.mk unitName s1
    [PsKernelDagConstructor.mk ctorName unitId]
  let result ← expectPublic
    (psKernelV1RunDag session [] .safe arena [
      .admit (.definitionDecl defn), .whnf aliasId,
      .admit (.ordinaryInductive [] 0 unitDecl false), .check ctorId])
  require "definition-and-inductive-admission"
    (match result.replies with
     | [.admitted _, .normalized value, .admitted _, .checked checked] =>
         psKernelExprEq value sort0 &&
           psKernelExprEq checked.type (.const unitName [])
     | _ => false)
  let original ← expectPublic
    (psKernelV1AdmitDeclaration session
      (.definitionDecl
        (PsKernelDefinitionInfo.mk (PsKernelConstantBase.mk alias [] sort1)
          sort0 .abbrevHint .safe)))
  let original ← expectPublic
    (psKernelV1AdmitDeclaration original.session
      (.ordinaryInductive
        (PsKernelSimpleInductiveDecl.mk [] unitName sort1
          [PsKernelSimpleConstructorDecl.mk ctorName (.const unitName [])] false 0)))
  require "environment-size-parity"
    (psKernelEnvironmentSize result.session.environment ==
      psKernelEnvironmentSize original.session.environment)
  require "invalid-definition-rejection"
    (match psKernelV1RunDag session [] .safe arena [
       .admit (.definitionDecl { defn with base := { defn.base with type := s0 } })] with
     | .error (.rejectedInvalid _) => true | _ => false)
  require "duplicate-definition-rejection"
    (match psKernelV1RunDag session [] .safe arena [
       .admit (.definitionDecl defn), .admit (.definitionDecl defn)] with
     | .error (.rejectedInvalid _) => true | _ => false)
  require "failed-batch-preserves-original-session"
    (psKernelEnvironmentSize session.environment == 0)
  let bounded := { session with resources := { session.resources with maxDeclarations := 1 } }
  require "declaration-limit-preserved"
    (match psKernelV1RunDag bounded [] .safe arena [
       .admit (.definitionDecl defn),
       .admit (.ordinaryInductive [] 0 unitDecl false)] with
     | .error (.resourceExhausted .declarationLimit _) => true | _ => false)

private def officialComparison : IO Unit := do
  let env ← Lean.mkEmptyEnvironment
  let session ← fresh
  let ls0 := Lean.Expr.sort .zero
  let ls1 := Lean.Expr.sort (.succ .zero)
  let leanTerm := Lean.Expr.app
    (.lam .anonymous ls1 (.bvar 0) .default) ls0
  let psTerm := PsKernelExpr.app
    (.lam .anonymous sort1 (.bvar 0) .default) sort0
  let (arena, root) ← expect (psKernelExprV2PagedImportChecked psTerm)
  let checked ← expectPublic (oneCheck session arena root)
  require "official-lean-check"
    (match Lean.Kernel.check env {} leanTerm, checkReply checked with
     | .ok type, some independent =>
         Lean.Expr.equal type ls1 && psKernelExprEq independent.type sort1
     | _, _ => false)
  require "official-lean-negative"
    (match Lean.Kernel.check env {} (.app ls0 ls0) with
     | .error _ => true | _ => false)
  IO.println "PSC1_V2_DAG_OFFICIAL_LEAN: PASS"

def main : IO Unit := do
  constructorDecode
  semanticParity
  metadataParity
  hostileInputs
  admissions
  officialComparison
  IO.println "PSC1_V2_DAG_REGRESSION: PASS"
