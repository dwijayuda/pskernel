import Ps.KernelCore.Checker.ExprV2.Check
import Lean
import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport

private def require (label : String) (ok : Bool) : IO Unit := do
  unless ok do throw (IO.userError ("PSC1_V2_DAG_FAIL " ++ label))

private def expect {α : Type} (value : Except String α) : IO α := do
  match value with
  | .ok result => return result
  | .error error => throw (IO.userError error)

private def resourceText : PsKernelResourceError → String
  | .fuel => "fuel"
  | .recursionDepth => "recursionDepth"
  | .natSize => "natSize"
  | .cancelled => "cancelled"
  | .declarationLimit => "declarationLimit"
  | .hostStack => "hostStack"

private def errorText : PsKernelError → String
  | .rejectedInvalid message => "invalid:" ++ message
  | .declinedUnsupported message => "unsupported:" ++ message
  | .resourceExhausted kind message => "resource:" ++ resourceText kind ++ ":" ++ message
  | .internalError message => "internal:" ++ message

private def sameResourceError : PsKernelResourceError → PsKernelResourceError → Bool
  | .fuel, .fuel => true
  | .recursionDepth, .recursionDepth => true
  | .natSize, .natSize => true
  | .cancelled, .cancelled => true
  | .declarationLimit, .declarationLimit => true
  | .hostStack, .hostStack => true
  | _, _ => false

private def samePublicError : PsKernelError → PsKernelError → Bool
  | .rejectedInvalid a, .rejectedInvalid b => a == b
  | .declinedUnsupported a, .declinedUnsupported b => a == b
  | .resourceExhausted ra a, .resourceExhausted rb b =>
      sameResourceError ra rb && a == b
  | .internalError a, .internalError b => a == b
  | _, _ => false

private def errorComparatorRegression : IO Unit := do
  let cases : List (PsKernelError × Nat) := [
    (.rejectedInvalid "same", 0), (.declinedUnsupported "same", 1),
    (.internalError "same", 2), (.resourceExhausted .fuel "same", 3),
    (.resourceExhausted .recursionDepth "same", 4),
    (.resourceExhausted .natSize "same", 5),
    (.resourceExhausted .cancelled "same", 6),
    (.resourceExhausted .declarationLimit "same", 7),
    (.resourceExhausted .hostStack "same", 8)]
  for (left, leftTag) in cases do
    for (right, rightTag) in cases do
      require "typed-error-comparator-tags"
        (samePublicError left right == (leftTag == rightTag))
  require "typed-error-comparator-message"
    (!(samePublicError (.resourceExhausted .fuel "a") (.resourceExhausted .fuel "b")))

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
  | .error a, .error b => samePublicError a b
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
  | .error a, .error b => samePublicError a b
  | .ok a, .ok b =>
      match b.replies with
      | [.normalized value] => psKernelExprEqual a value
      | _ => false
  | _, _ => false

private def sameDefEq
    (legacy : Except PsKernelError Bool)
    (dag : Except PsKernelError PsKernelDagBatchResult) : Bool :=
  match legacy, dag with
  | .error a, .error b => samePublicError a b
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


private def zetaWhnfParity : IO Unit := do
  let lambdaBody := PsKernelExpr.lam (nm "inner") sort1 (.bvar 1) .implicit
  let forallBody := PsKernelExpr.forallE (nm "inner") sort1 (.bvar 1) .default
  let nested := PsKernelExpr.letE (nm "outer") sort1 sort0
    (.letE (nm "inner") sort1 (.bvar 0) (.mdata 21 (.bvar 0)) false) false
  let seeds := [
    PsKernelExpr.letE (nm "x") sort1 sort0 (.bvar 0) false,
    .letE (nm "x") sort1 sort0 lambdaBody false,
    .letE (nm "x") sort1 sort0 forallBody true, nested
  ]
  for seed in seeds do
    for wrappers in [0,1,3,8] do
      let mut term := seed
      for tag in [:wrappers] do term := .mdata tag term
      let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
      for fuel in [0,1,2,3,4,5,8,12,32,64] do
        for depth in [0,1,2] do
          let session ← fresh fuel depth
          require "zeta-public-whnf-fuel-depth-parity"
            (sameWhnf
              (psKernelV1Whnf session [] .safe term)
              (psKernelV1RunDag session [] .safe arena [.whnf root]))
          let checker := psKernelKernelSessionChecker session [] .safe
          let original := psKernelSessionWhnf fuel checker term
          match psKernelExprV2TryWhnfWithFuel fuel checker.context arena root with
          | none => throw (IO.userError "zeta fixture unexpectedly used legacy fallback")
          | some (.error error) =>
              require "zeta-core-error-parity"
                (match original with | .error old => old == error | _ => false)
          | some (.ok (next, reduced)) =>
              let _ ← expect (psKernelExprV2PagedValidate next)
              let decoded ← expect (psKernelExprV2DecodeChecked next)
              let value ← expect (psKernelExprV2DecodedRequire decoded reduced)
              require "zeta-core-value-parity"
                (match original with | .ok old => psKernelExprEqual old.fst value | _ => false)
  IO.println "PSC1_V2_DAG_NATIVE_ZETA: PASS"

private def betaWhnfParity : IO Unit := do
  let sort2 := PsKernelExpr.sort (.succ (.succ .zero))
  let identity := PsKernelExpr.lam (nm "x") sort1 (.bvar 0) .default
  let partialTerm := PsKernelExpr.app
    (.lam (nm "x") sort1 (.lam (nm "y") sort1 (.bvar 1) .implicit) .default)
    sort0
  let reversed := PsKernelExpr.app
    (.app (.lam (nm "x") sort2
      (.lam (nm "y") sort1 (.bvar 1) .default) .default) sort1)
    sort0
  let zetaBody := PsKernelExpr.app
    (.lam (nm "x") sort1
      (.letE (nm "y") sort1 (.bvar 0) (.mdata 9 (.bvar 0)) false) .default)
    sort0
  let oversaturated := PsKernelExpr.app
    (.app (.lam (nm "x") sort1
      (.app (.lam (nm "y") sort1
        (.lam (nm "z") sort1 (.bvar 1) .default) .default) (.bvar 0)) .default)
      sort0)
    sort0
  let zetaOuter := PsKernelExpr.letE (nm "x") sort1 sort0
    (.app identity (.bvar 0)) false
  let mut deep := sort0
  for _ in [:20] do deep := .app identity deep
  let seeds := [
    PsKernelExpr.app identity sort0, partialTerm, reversed, zetaBody,
    oversaturated, zetaOuter, deep
  ]
  for seed in seeds do
    for wrappers in [0,1,3] do
      let mut term := seed
      for tag in [:wrappers] do term := .mdata tag term
      let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
      for fuel in [0,1,2,3,4,5,6,8,12,24,64,128] do
        for depth in [0,1,2] do
          let session ← fresh fuel depth
          require "beta-public-whnf-fuel-depth-parity"
            (sameWhnf
              (psKernelV1Whnf session [] .safe term)
              (psKernelV1RunDag session [] .safe arena [.whnf root]))
          let checker := psKernelKernelSessionChecker session [] .safe
          let original := psKernelSessionWhnf fuel checker term
          match psKernelExprV2TryWhnfWithFuel fuel checker.context arena root with
          | none => throw (IO.userError "syntactic-lambda beta fixture unexpectedly used fallback")
          | some (.error error) =>
              require "beta-core-error-parity"
                (match original with | .error old => old == error | _ => false)
          | some (.ok (next, reduced)) =>
              let _ ← expect (psKernelExprV2PagedValidate next)
              let decoded ← expect (psKernelExprV2DecodeChecked next)
              let value ← expect (psKernelExprV2DecodedRequire decoded reduced)
              require "beta-core-value-parity"
                (match original with | .ok old => psKernelExprEqual old.fst value | _ => false)
  -- A completed function normalization can publish a cache needed by the
  -- second occurrence of the same let head. That hit matters at fuel four.
  let functionType := PsKernelExpr.forallE .anonymous sort1 sort1 .default
  let cachedHead := PsKernelExpr.letE (nm "f") functionType identity (.bvar 0) false
  let cacheSensitive := PsKernelExpr.app cachedHead (.app cachedHead sort0)
  let (arena, root) ← expect (psKernelExprV2PagedImportChecked cacheSensitive)
  let session ← fresh
  let checker := psKernelKernelSessionChecker session [] .safe
  let original ← expect (psKernelSessionWhnf 4 checker cacheSensitive)
  require "beta-cache-sensitive-oracle-low-budget"
    (psKernelExprEqual original.fst sort0)
  let (next, reduced) ← expect
    (match psKernelExprV2TryWhnfWithFuel 4 checker.context arena root with
     | some value => value | none => .error "cache-sensitive function head used fallback")
  let decoded ← expect (psKernelExprV2DecodeChecked next)
  let value ← expect (psKernelExprV2DecodedRequire decoded reduced)
  require "beta-cache-sensitive-function-head-is-dag-native"
    (psKernelExprEqual value sort0)
  for fuel in [0,1,2,3,4,5,8,16,64] do
    let session ← fresh fuel
    require "beta-cache-sensitive-public-parity"
      (sameWhnf
        (psKernelV1Whnf session [] .safe cacheSensitive)
        (psKernelV1RunDag session [] .safe arena [.whnf root]))
  IO.println "PSC1_V2_DAG_NATIVE_BETA: PASS"

private def rawStateWhnfParity {alpha : Type}
    (label : String)
    (original : Except String (Prod PsKernelExpr alpha))
    (attempt : Option (Except String (Prod PsKernelExprV2WhnfState Nat))) :
    IO Unit := do
  match attempt with
  | none => throw (IO.userError ("unexpected DAG WHNF fallback: " ++ label))
  | some (.error error) =>
      require label (match original with | .error old => old == error | _ => false)
  | some (.ok (state, root)) =>
      let decoded ← expect (psKernelExprV2DecodeChecked state.arena)
      let value ← expect (psKernelExprV2DecodedRequire decoded root)
      require label
        (match original with | .ok old => psKernelExprEqual old.fst value | _ => false)

private def whnfPublicCacheParity : IO Unit := do
  let session ← fresh 4096 1
  let checker := psKernelKernelSessionChecker session [] .safe
  let alphaA := PsKernelExpr.lam (nm "public-a") sort1 (.bvar 0) .default
  let alphaB := PsKernelExpr.lam (nm "public-b") sort1 (.bvar 0) .implicit
  let collisionA := PsKernelExpr.lam (nm "public-c") sort1
    (.mdata 0 (.bvar 0)) .default
  let collisionB := PsKernelExpr.lam (nm "public-c") sort1
    (.mdata 65521 (.bvar 0)) .default
  let (arena, typeId) ← expect
    (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty (.succ .zero))
  let (arena, bodyId) ← expect (psKernelExprV2PagedMkBVar arena 0)
  let (arena, alphaAId) ← expect
    (psKernelExprV2PagedMkLam arena (nm "public-a") typeId bodyId .default)
  let (arena, alphaBId) ← expect
    (psKernelExprV2PagedMkLam arena (nm "public-b") typeId bodyId .implicit)
  let (arena, collisionBodyA) ← expect (psKernelExprV2PagedMkMData arena 0 bodyId)
  let (arena, collisionBodyB) ← expect (psKernelExprV2PagedMkMData arena 65521 bodyId)
  let (arena, collisionAId) ← expect
    (psKernelExprV2PagedMkLam arena (nm "public-c") typeId collisionBodyA .default)
  let (arena, collisionBId) ← expect
    (psKernelExprV2PagedMkLam arena (nm "public-c") typeId collisionBodyB .default)
  require "public-cache-distinct-alpha-keys" (alphaAId != alphaBId)
  require "public-cache-alpha-key-equality"
    (← expect (psKernelExprV2PagedEqOnCanonical arena alphaAId alphaBId))
  let ca ← expect (psKernelExprV2PagedRequire arena collisionAId)
  let cb ← expect (psKernelExprV2PagedRequire arena collisionBId)
  require "public-cache-real-collision"
    (ca.hash == cb.hash &&
      psKernelExprHash collisionA == psKernelExprHash collisionB)
  require "public-cache-unequal-collision-keys"
    (!(← expect (psKernelExprV2PagedEqOnCanonical arena collisionAId collisionBId)))
  for (term, root) in
      [(alphaA, alphaAId), (alphaB, alphaBId),
       (collisionA, collisionAId), (collisionB, collisionBId)] do
    let _ ← expectPublic (psKernelV1CheckExpression session [] .safe term)
    let _ ← expectPublic (oneCheck session arena root)
    pure ()
  let warmOriginal ← expect (psKernelSessionWhnf 2 checker alphaA)
  let warmDag ← expect
    (match psKernelExprV2TryWhnfStateWithFuel 2 checker.context
        (psKernelExprV2WhnfStateEmpty arena) alphaAId with
     | some value => value | none => .error "public alpha priming used fallback")
  let blockedContext := { checker.context with recDepth := 16 }
  for context in [checker.context, blockedContext] do
    let original := psKernelWhnfWithRecursorFuel 1 (psKernelIsDefEqWithFuel 1)
      context warmOriginal.snd.state alphaB
    let exactResult ← expect original
    require "public-cache-hit-retains-first-lambda-syntax"
      (psKernelExprEqual exactResult.fst alphaA &&
        !psKernelExprEqual exactResult.fst alphaB)
    rawStateWhnfParity "public-cache-hit-precedes-core-depth"
      original
      (psKernelExprV2TryWhnfStateWithFuel 1 context warmDag.fst alphaBId)
    let exhausted := psKernelWhnfWithRecursorFuel 0 (psKernelIsDefEqWithFuel 0)
      context warmOriginal.snd.state alphaB
    require "public-cache-hit-does-not-bypass-zero-fuel"
      (match exhausted with
       | .error "kernel reduction budget exhausted" => true | _ => false)
    rawStateWhnfParity "public-cache-zero-fuel-parity"
      exhausted
      (psKernelExprV2TryWhnfStateWithFuel 0 context warmDag.fst alphaBId)
  let collisionOriginal ← expect (psKernelSessionWhnf 2 checker collisionA)
  let collisionDag ← expect
    (match psKernelExprV2TryWhnfStateWithFuel 2 checker.context
        (psKernelExprV2WhnfStateEmpty arena) collisionAId with
     | some value => value | none => .error "public collision priming used fallback")
  let collisionMiss := psKernelWhnfWithRecursorFuel 1 (psKernelIsDefEqWithFuel 1)
    checker.context collisionOriginal.snd.state collisionB
  require "public-cache-collision-cannot-authorize-low-fuel-hit"
    (match collisionMiss with
     | .error "kernel reduction budget exhausted" => true | _ => false)
  rawStateWhnfParity "public-cache-collision-miss-parity"
    collisionMiss
    (psKernelExprV2TryWhnfStateWithFuel 1 checker.context collisionDag.fst collisionBId)
  IO.println "PSC1_V2_DAG_NATIVE_PUBLIC_CACHE: PASS"

private def whnfFunctionStateParity : IO Unit := do
  let identityA := PsKernelExpr.lam (nm "a") sort1 (.bvar 0) .default
  let identityB := PsKernelExpr.lam (nm "b") sort1 (.bvar 0) .implicit
  let functionType := PsKernelExpr.forallE .anonymous sort1 sort1 .default
  let headA := PsKernelExpr.letE (nm "fa") functionType identityA (.bvar 0) false
  let headB := PsKernelExpr.letE (nm "fb") functionType identityB (.bvar 0) false
  let shared := PsKernelExpr.app headA (.app headA sort0)
  let copied := PsKernelExpr.app headA (.app headB sort0)
  let exactSyntax := PsKernelExpr.app headA headB
  let collisionA := PsKernelExpr.letE (nm "c") functionType
    (.mdata 0 identityA) (.bvar 0) false
  let collisionB := PsKernelExpr.letE (nm "c") functionType
    (.mdata 65521 identityA) (.bvar 0) false
  let collision := PsKernelExpr.app collisionA (.app collisionB sort0)
  let metadataHead := PsKernelExpr.app (.mdata 73 identityA) sort0
  let fixtures := [shared, copied, exactSyntax, collision, metadataHead]
  for term in fixtures do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,2,3,4,5,6,7,8,12,24,64] do
      for depth in [0,1,2] do
        let session ← fresh fuel depth
        let checker := psKernelKernelSessionChecker session [] .safe
        rawStateWhnfParity "function-normalization-state-and-resource-parity"
          (psKernelSessionWhnf fuel checker term)
          (psKernelExprV2TryWhnfStateWithFuel fuel checker.context
            (psKernelExprV2WhnfStateEmpty arena) root)
        require "function-normalization-complete-public-parity"
          (sameWhnf
            (psKernelV1Whnf session [] .safe term)
            (psKernelV1RunDag session [] .safe arena [.whnf root]))
  let session ← fresh
  let checker := psKernelKernelSessionChecker session [] .safe
  for term in [shared, copied] do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    let (first, args) ← expect (psKernelExprV2TransformAppSpineOnCanonical arena root)
    let arg ← expect
      (match args with | .cons a _ => .ok a | _ => .error "missing cache fixture argument")
    let (second, _) ← expect (psKernelExprV2TransformAppSpineOnCanonical arena arg)
    require "cache-fixture-distinct-source-ids" (first != second)
    require "cache-fixture-alpha-equivalent-keys"
      (← expect (psKernelExprV2PagedEqOnCanonical arena first second))
    let original ← expect (psKernelSessionWhnf 4 checker term)
    require "cache-fixture-low-fuel-oracle-success" (psKernelExprEqual original.fst sort0)
    rawStateWhnfParity "cache-fixture-low-fuel-dag-success"
      (.ok original)
      (psKernelExprV2TryWhnfStateWithFuel 4 checker.context
        (psKernelExprV2WhnfStateEmpty arena) root)
  let (syntaxArena, syntaxRoot) ← expect (psKernelExprV2PagedImportChecked exactSyntax)
  let syntaxOracle ← expect (psKernelSessionWhnf 4 checker exactSyntax)
  require "cache-hit-retains-first-result-syntax"
    (psKernelExprEqual syntaxOracle.fst identityA &&
      !psKernelExprEqual syntaxOracle.fst identityB)
  rawStateWhnfParity "dag-cache-hit-retains-first-result-syntax"
    (.ok syntaxOracle)
    (psKernelExprV2TryWhnfStateWithFuel 4 checker.context
      (psKernelExprV2WhnfStateEmpty syntaxArena) syntaxRoot)
  require "raw-cache-syntax-fixture-is-not-publicly-admitted"
    (match psKernelV1RunDag session [] .safe syntaxArena [.whnf syntaxRoot] with
     | .error (.rejectedInvalid _) => true | _ => false)
  let (collisionArena, collisionRoot) ← expect (psKernelExprV2PagedImportChecked collision)
  let (first, args) ← expect
    (psKernelExprV2TransformAppSpineOnCanonical collisionArena collisionRoot)
  let arg ← expect
    (match args with | .cons a _ => .ok a | _ => .error "missing collision fixture argument")
  let (second, _) ← expect (psKernelExprV2TransformAppSpineOnCanonical collisionArena arg)
  let firstEntry ← expect (psKernelExprV2PagedRequire collisionArena first)
  let secondEntry ← expect (psKernelExprV2PagedRequire collisionArena second)
  require "cache-fixture-real-hash-collision" (firstEntry.hash == secondEntry.hash)
  require "cache-fixture-collision-structurally-unequal"
    (!(← expect (psKernelExprV2PagedEqOnCanonical collisionArena first second)))
  require "collision-must-not-create-low-fuel-cache-hit"
    (match psKernelSessionWhnf 5 checker collision with
     | .error "kernel reduction budget exhausted" => true | _ => false)
  rawStateWhnfParity "collision-rejection-retains-original-fuel"
    (psKernelSessionWhnf 5 checker collision)
    (psKernelExprV2TryWhnfStateWithFuel 5 checker.context
      (psKernelExprV2WhnfStateEmpty collisionArena) collisionRoot)
  -- Even a warm cache cannot bypass the core entry's fuel or depth checks.
  let (warmArena, warmRoot) ← expect (psKernelExprV2PagedImportChecked shared)
  let warmContext := { checker.context with maxRecDepth := 1 }
  let warmChecker := { checker with context := warmContext }
  let warmOriginal ← expect (psKernelSessionWhnf 4 warmChecker shared)
  let warmDag ← expect
    (match psKernelExprV2TryWhnfStateWithFuel 4 warmContext
        (psKernelExprV2WhnfStateEmpty warmArena) warmRoot with
     | some value => value | none => .error "missing warm DAG result")
  let blockedContext := { warmContext with recDepth := 16 }
  for context in [warmContext, blockedContext] do
    for fuel in [0,1] do
      rawStateWhnfParity "warm-cache-entry-guards"
        (psKernelWhnfCoreWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel)
          context warmOriginal.snd.state shared false false)
        (psKernelExprV2TryWhnfCoreStateWithFuel fuel context warmDag.fst warmRoot)
  -- The public cache is checked before entering the core depth guard, while
  -- public fuel zero is still checked first.
  for context in [warmContext, blockedContext] do
    for fuel in [0,1] do
      rawStateWhnfParity "warm-public-cache-entry-guards"
        (psKernelSessionWhnf fuel { warmOriginal.snd with context := context } shared)
        (psKernelExprV2TryWhnfStateWithFuel fuel context warmDag.fst warmRoot)
  -- Open source expressions never publish a semantic entry.
  let localName := nm "local"
  let locals := psKernelLocalContextAddLocal checker.context.localContext
    localName localName sort1 .default
  let localContext := psKernelCheckerContextWithLocalContext checker.context locals
  let openTerm := PsKernelExpr.app identityA (.fvar localName)
  let (openArena, openRoot) ← expect (psKernelExprV2PagedImportChecked openTerm)
  let openResult ← expect
    (match psKernelExprV2TryWhnfStateWithFuel 64 localContext
        (psKernelExprV2WhnfStateEmpty openArena) openRoot with
     | some value => value | none => .error "missing open DAG result")
  require "fvar-containing-source-cache-ineligible"
    (openResult.fst.coreCache.isEmpty && openResult.fst.publicCache.isEmpty)
  let localLet := psKernelLocalContextAddLet checker.context.localContext
    localName localName sort1 sort0
  let letContext := psKernelCheckerContextWithLocalContext checker.context localLet
  let (fvarArena, fvarRoot) ← expect (psKernelExprV2PagedImportChecked (.fvar localName))
  require "legacy-local-let-value-remains-explicit-fallback"
    (match psKernelExprV2TryWhnfWithFuel 64 letContext fvarArena fvarRoot with
     | none => true | _ => false)
  IO.println "PSC1_V2_DAG_NATIVE_WHNF_STATE: PASS"

private def projectionUnselectedFieldFuel
    (context : PsKernelCheckerContext) (state : PsKernelCheckerState)
    (typeName ctorName : PsKernelName) : IO Unit := do
  let (initial, s0) ← expect
    (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
  let (initial, ctor) ← expect (psKernelExprV2PagedMkConst initial ctorName [])
  let mut workingArena := initial
  let mut hidden := s0
  let mut hiddenTerm := sort0
  for tag in [:4] do
    let (next, root) ← expect (psKernelExprV2PagedMkMData workingArena tag hidden)
    workingArena := next
    hidden := root
    hiddenTerm := .mdata tag hiddenTerm
  let (arena, first) ← expect (psKernelExprV2PagedMkApp workingArena ctor s0)
  let (arena, major) ← expect (psKernelExprV2PagedMkApp arena first hidden)
  let (arena, root) ← expect (psKernelExprV2PagedMkProj arena typeName 0 major)
  let term := PsKernelExpr.proj typeName 0
    (.app (.app (.const ctorName []) sort0) hiddenTerm)
  for fuel in [6,7] do
    let original := psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel)
      context state term
    require "projection-unselected-field-original-budget-boundary"
      (if fuel == 6 then
         match original with
         | .error "kernel reduction budget exhausted" => true | _ => false
       else
         match original with
         | .ok result => psKernelExprEqual result.fst sort0 | _ => false)
    rawStateWhnfParity "projection-unselected-field-budget-parity"
      original
      (psKernelExprV2TryWhnfStateWithFuel fuel context
        (psKernelExprV2WhnfStateEmpty arena) root)
  IO.println "PSC1_V2_DAG_NATIVE_PROJECTION_UNSELECTED_FIELD: PASS"

private def natProjectionWhnfParity : IO Unit := do
  let initial ← fresh
  let checker := psKernelKernelSessionChecker initial [] .safe
  let numeral (n : Nat) := PsKernelExpr.lit (.nat n)
  let operation (name : String) (a b : Nat) :=
    PsKernelExpr.app (.app (.const (PsKernelName.str psKernelNatName name) [])
      (.mdata 13 (numeral a))) (.mdata 17 (numeral b))
  let results : List (String × PsKernelExpr) := [
    ("add", numeral 13), ("sub", numeral 5), ("mul", numeral 36),
    ("pow", numeral 6561), ("gcd", numeral 1), ("mod", numeral 1),
    ("div", numeral 2), ("beq", .const psKernelBoolFalseName []),
    ("ble", .const psKernelBoolFalseName []), ("land", numeral 0),
    ("lor", numeral 13), ("xor", numeral 13), ("shiftLeft", numeral 144),
    ("shiftRight", numeral 0)]
  Lean.initSearchPath (← Lean.findSysroot)
  let officialEnv ← Lean.importModules #[{ module := `Init }] {}
  for (name, expected) in results do
    let official := Lean.Expr.app
      (.app (.const (Lean.Name.str `Nat name) []) (.lit (.natVal 9)))
      (.lit (.natVal 4))
    let officialExpected : Lean.Expr :=
      match expected with
      | .lit (.nat value) => .lit (.natVal value)
      | _ => .const `Bool.false []
    require "official-Lean-Nat-reduction"
      (match Lean.Kernel.whnf officialEnv {} official with
       | .ok value => Lean.Expr.equal value officialExpected | _ => false)
    let term := operation name 9 4
    let old ← expect (psKernelSessionWhnf 64 checker term)
    require "nat-independent-expected-result" (psKernelExprEqual old.fst expected)
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,2,3,4,5,6,8,16,64] do
      for depth in [0,1,2] do
        for size in [0,1,psKernelLeanNatMaxSizeDefault] do
          let context := { checker.context with maxRecDepth := depth, maxNatSize := size }
          let session := { checker with context := context }
          rawStateWhnfParity "nat-full-pipeline-resource-parity"
            (psKernelSessionWhnf fuel session term)
            (psKernelExprV2TryWhnfStateWithFuel fuel context
              (psKernelExprV2WhnfStateEmpty arena) root)
  -- These branches reject/count-bound before any expensive arithmetic.
  for term in [operation "pow" 2 4294967296, operation "shiftLeft" 1 4294967296,
      operation "div" 9 0, operation "mod" 9 0, operation "pow" 0 0] do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    rawStateWhnfParity "nat-count-and-zero-division-parity"
      (psKernelSessionWhnf 64 checker term)
      (psKernelExprV2TryWhnfStateWithFuel 64 checker.context
        (psKernelExprV2WhnfStateEmpty arena) root)
  -- A nonprimitive binary constant still normalizes both arguments under the
  -- published PSKernel policy, even though the resulting application stays put.
  let deep := PsKernelExpr.mdata 1 (.mdata 2 (.mdata 3 sort0))
  let unknown := PsKernelExpr.app (.app (.const (nm "notNat") []) sort0) deep
  let (unknownArena, unknownRoot) ← expect (psKernelExprV2PagedImportChecked unknown)
  for fuel in [0,1,2,3,4,5,6,16] do
    rawStateWhnfParity "nonprimitive-binary-argument-order-and-fuel"
      (psKernelSessionWhnf fuel checker unknown)
      (psKernelExprV2TryWhnfStateWithFuel fuel checker.context
        (psKernelExprV2WhnfStateEmpty unknownArena) unknownRoot)
  require "nonprimitive-still-exhausts-argument-budget"
    (match psKernelSessionWhnf 3 checker unknown with
     | .error "kernel reduction budget exhausted" => true | _ => false)
  -- Nat.succ is checked through a real admitted Nat declaration.
  let nat := PsKernelExpr.const psKernelNatName []
  let natDecl := PsKernelSimpleInductiveDecl.mk [] psKernelNatName sort1
    [PsKernelSimpleConstructorDecl.mk psKernelNatZeroName nat,
     PsKernelSimpleConstructorDecl.mk psKernelNatSuccName
       (.forallE (nm "n") nat nat .default)] false 0
  let natAdmitted ← expectPublic
    (psKernelV1AdmitDeclaration initial (.ordinaryInductive natDecl))
  let natSession := natAdmitted.session
  let succ := PsKernelExpr.app (.const psKernelNatSuccName [])
    (.mdata 3 (.app (.const psKernelNatSuccName []) (numeral 4)))
  let (natArena, natRoot) ← expect (psKernelExprV2PagedImportChecked succ)
  for fuel in [0,1,2,3,4,5,6,8,16,64] do
    for depth in [0,1,2] do
      let session := { natSession with resources :=
        { natSession.resources with fuel := fuel, maxRecDepth := depth } }
      require "checked-nat-successor-resource-parity"
        (sameWhnf (psKernelV1Whnf session [] .safe succ)
          (psKernelV1RunDag session [] .safe natArena [.whnf natRoot]))
  let natNormalized ← expectPublic
    (psKernelV1RunDag natSession [] .safe natArena [.whnf natRoot])
  require "checked-nat-successor-value"
    (match natNormalized.replies with
     | [.normalized value] => psKernelExprEqual value (numeral 6) | _ => false)
  -- Projection reads only constructor layout metadata from the admitted
  -- environment; fields and reductions remain IDs in the owning arena.
  let box := nm "DagProjectionBox"
  let ctor := PsKernelName.str box "mk"
  let boxType := PsKernelExpr.const box []
  let ctorType := PsKernelExpr.forallE (nm "A") sort1
    (.forallE (nm "B") sort1 boxType .default) .default
  let boxDecl := PsKernelSimpleInductiveDecl.mk [] box (.sort (.succ (.succ .zero)))
    [PsKernelSimpleConstructorDecl.mk ctor ctorType] false 0
  let boxAdmitted ← expectPublic
    (psKernelV1AdmitDeclaration initial (.ordinaryInductive boxDecl))
  let boxSession := boxAdmitted.session
  let boxChecker := psKernelKernelSessionChecker boxSession [] .safe
  projectionUnselectedFieldFuel boxChecker.context boxChecker.state box ctor
  let value := PsKernelExpr.app (.app (.const ctor []) (.mdata 7 sort0)) (.mdata 9 sort0)
  let betaValue := PsKernelExpr.app (.lam .anonymous boxType (.bvar 0) .default) value
  let hiddenCtor := PsKernelExpr.app (.app (.mdata 71 (.const ctor [])) sort0) sort0
  let p0 := PsKernelExpr.proj box 0 value
  let p1 := PsKernelExpr.proj box 1 betaValue
  let changedHead := PsKernelExpr.proj box 1 hiddenCtor
  let invalidIndex := PsKernelExpr.proj box 2 value
  let hugeIndex := PsKernelExpr.proj box 4294967296 betaValue
  let wrongType := PsKernelExpr.proj (nm "OtherBox") 0 value
  for term in [p0,p1,changedHead,invalidIndex,hugeIndex,wrongType] do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,2,3,4,5,6,8,12,64] do
      for depth in [0,1,2] do
        let session := { boxSession with resources :=
          { boxSession.resources with fuel := fuel, maxRecDepth := depth } }
        let context := { boxChecker.context with maxRecDepth := depth }
        rawStateWhnfParity "projection-raw-exact-resource-parity"
          (psKernelSessionWhnf fuel { boxChecker with context := context } term)
          (psKernelExprV2TryWhnfStateWithFuel fuel context
            (psKernelExprV2WhnfStateEmpty arena) root)
        require "projection-public-exact-resource-parity"
          (sameWhnf (psKernelV1Whnf session [] .safe term)
            (psKernelV1RunDag session [] .safe arena [.whnf root]))
  for term in [p0,p1,changedHead] do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    let reduced ← expectPublic
      (psKernelV1RunDag boxSession [] .safe arena [.whnf root])
    require "checked-projection-selected-field"
      (match reduced.replies with
       | [.normalized result] => psKernelExprEqual result sort0 | _ => false)
  for term in [invalidIndex,hugeIndex,wrongType] do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    require "checked-invalid-projection-rejected"
      (match psKernelV1RunDag boxSession [] .safe arena [.whnf root] with
       | .error (.rejectedInvalid _) => true | _ => false)
  -- A second owner with the same IDs cannot reuse this environment or cache.
  let emptyChecker := psKernelKernelSessionChecker initial [] .safe
  let (arena, root) ← expect (psKernelExprV2PagedImportChecked p0)
  rawStateWhnfParity "projection-context-does-not-leak"
    (psKernelSessionWhnf 64 emptyChecker p0)
    (psKernelExprV2TryWhnfStateWithFuel 64 emptyChecker.context
      (psKernelExprV2WhnfStateEmpty arena) root)
  require "projection-empty-environment-rejects"
    (match psKernelV1RunDag initial [] .safe arena [.whnf root] with
     | .error (.rejectedInvalid _) => true | _ => false)
  let parameterBox := nm "DagParameterBox"
  let parameterCtor := PsKernelName.str parameterBox "mk"
  let parameterType := PsKernelExpr.forallE (nm "A") sort1 sort1 .default
  let parameterCtorType := PsKernelExpr.forallE (nm "A") sort1
    (.forallE (nm "value") (.bvar 0)
      (.app (.const parameterBox []) (.bvar 1)) .default) .default
  let parameterDecl := PsKernelSimpleInductiveDecl.mk [] parameterBox parameterType
    [PsKernelSimpleConstructorDecl.mk parameterCtor parameterCtorType] false 1
  let parameterAdmitted ← expectPublic
    (psKernelV1AdmitDeclaration natSession (.ordinaryInductive parameterDecl))
  let parameterSession := parameterAdmitted.session
  let parameterChecker := psKernelKernelSessionChecker parameterSession [] .safe
  let parameterTerm := PsKernelExpr.proj parameterBox 0
    (.app (.app (.const parameterCtor []) nat) (numeral 4))
  let (parameterArena, parameterRoot) ← expect (psKernelExprV2PagedImportChecked parameterTerm)
  for fuel in [0,1,2,3,4,5,6,8,16,64] do
    rawStateWhnfParity "projection-skips-admitted-parameters"
      (psKernelSessionWhnf fuel parameterChecker parameterTerm)
      (psKernelExprV2TryWhnfStateWithFuel fuel parameterChecker.context
        (psKernelExprV2WhnfStateEmpty parameterArena) parameterRoot)
    let session := { parameterSession with resources :=
      { parameterSession.resources with fuel := fuel } }
    require "parameterized-projection-public-parity"
      (sameWhnf (psKernelV1Whnf session [] .safe parameterTerm)
        (psKernelV1RunDag session [] .safe parameterArena [.whnf parameterRoot]))
  let parameterResult ← expectPublic
    (psKernelV1RunDag parameterSession [] .safe parameterArena [.whnf parameterRoot])
  require "parameterized-projection-returns-field-not-type-argument"
    (match parameterResult.replies with
     | [.normalized value] => psKernelExprEqual value (numeral 4) | _ => false)
  IO.println "PSC1_V2_DAG_NATIVE_OFFICIAL_NAT: PASS"
  IO.println "PSC1_V2_DAG_NATIVE_NAT_PROJECTION: PASS"

private def structuralShortcutParity : IO Unit := do
  let (a, zero) ← expect (psKernelExprV2PagedMkLit psKernelExprV2PagedEmpty (.nat 0))
  let (b, collision) ← expect (psKernelExprV2PagedMkLit a (.nat 65521))
  let left ← expect (psKernelExprV2PagedRequire b zero)
  let right ← expect (psKernelExprV2PagedRequire b collision)
  require "real-closed-term-hash-collision" (left.hash == right.hash)
  let equal ← expect (psKernelExprV2PagedEqChecked b zero collision)
  require "closed-term-collision-not-syntactically-equal" (!equal)
  for fuel in [0,1,2,3,8,64] do
    let session ← fresh fuel
    require "hash-collision-defeq-resource-parity"
      (sameDefEq
        (psKernelV1IsDefEq session [] .safe (.lit (.nat 0)) (.lit (.nat 65521)))
        (psKernelV1RunDag session [] .safe b [.isDefEq zero collision]))
  let session ← fresh
  let result ← expectPublic (psKernelV1RunDag session [] .safe b [.isDefEq zero collision])
  require "closed-term-hash-collision-not-admitted-equal"
    (match result.replies with | [.equal false] => true | _ => false)
  let (a, ty) ← expect (psKernelExprV2PagedMkSort b (.succ .zero))
  let (a, bound) ← expect (psKernelExprV2PagedMkBVar a 0)
  let (a, lamA) ← expect (psKernelExprV2PagedMkLam a (nm "a") ty bound .default)
  let (a, lamB) ← expect (psKernelExprV2PagedMkLam a (nm "b") ty bound .implicit)
  require "alpha-lambdas-have-distinct-ids" (lamA != lamB)
  for fuel in [0,1,2,3,4,8,64] do
    let session ← fresh fuel
    require "alpha-structural-shortcut-exact-resource-parity"
      (sameDefEq
        (psKernelV1IsDefEq session [] .safe
          (.lam (nm "a") sort1 (.bvar 0) .default)
          (.lam (nm "b") sort1 (.bvar 0) .implicit))
        (psKernelV1RunDag session [] .safe a [.isDefEq lamA lamB]))
  let (a, s) ← expect (psKernelExprV2PagedMkSort a .zero)
  let (a, tagA) ← expect (psKernelExprV2PagedMkMData a 0 s)
  let (a, tagB) ← expect (psKernelExprV2PagedMkMData a 65521 s)
  let structural ← expect (psKernelExprV2PagedEqChecked a tagA tagB)
  require "metadata-tags-structurally-distinct" (!structural)
  for fuel in [0,1,2,3,4,8,64] do
    let session ← fresh fuel
    require "paired-metadata-exact-defeq-parity"
      (sameDefEq
        (psKernelV1IsDefEq session [] .safe (.mdata 0 sort0) (.mdata 65521 sort0))
        (psKernelV1RunDag session [] .safe a [.isDefEq tagA tagB]))
  let (a, badA) ← expect (psKernelExprV2PagedMkApp a s s)
  let (a, badB) ← expect (psKernelExprV2PagedMkApp a s s)
  require "different-id-equal-illtyped-terms-rejected"
    (match psKernelV1RunDag session [] .safe a [.isDefEq badA badB] with
     | .error (.rejectedInvalid _) => true | _ => false)
  IO.println "PSC1_V2_DAG_STRUCTURAL_SHORTCUT: PASS"

private def quickOfficialName : PsKernelName → Lean.Name
  | .anonymous => .anonymous
  | .str parent value => .str (quickOfficialName parent) value
  | .num parent value => .num (quickOfficialName parent) value

private def quickOfficialLevel : PsKernelLevel → Option Lean.Level
  | .zero => some .zero
  | .succ value => (quickOfficialLevel value).map Lean.Level.succ
  | .max left right => do
      return .max (← quickOfficialLevel left) (← quickOfficialLevel right)
  | .imax left right => do
      return .imax (← quickOfficialLevel left) (← quickOfficialLevel right)
  | .param name => some (.param (quickOfficialName name))
  | .mvar _ => none

private def quickOfficialExpr : PsKernelExpr → Option Lean.Expr
  | .sort level => (quickOfficialLevel level).map Lean.Expr.sort
  | .lit (.nat value) => some (.lit (.natVal value))
  | .lit (.str value) => some (.lit (.strVal value))
  | .mdata _ body => (quickOfficialExpr body).map (Lean.Expr.mdata {})
  | _ => none

private def sameQuickDefEq
    (legacy : Except String (Prod Bool PsKernelCheckerSession))
    (attempted : Option (Except String Bool)) : Bool :=
  match legacy, attempted with
  | .error left, some (.error right) => left == right
  | .ok left, some (.ok right) => left.fst == right
  | _, _ => false

private def quickDefEqParity : IO Unit := do
  let u := PsKernelLevel.param (nm "quick-u")
  let v := PsKernelLevel.param (nm "quick-v")
  let params := [nm "quick-u", nm "quick-v"]
  let maxZero := PsKernelExpr.sort (.max .zero .zero)
  let imaxZero := PsKernelExpr.sort (.imax (.succ .zero) .zero)
  let mut nestedLeft := maxZero
  let mut nestedRight := sort0
  for tag in [:17] do
    nestedLeft := .mdata tag nestedLeft
    nestedRight := .mdata (tag + 65521) nestedRight
  let fixtures : List (String × PsKernelExpr × PsKernelExpr × Bool) := [
    ("sort-max-zero", maxZero, sort0, true),
    ("sort-imax-zero", imaxZero, sort0, true),
    ("sort-max-commute", .sort (.max u v), .sort (.max v u), true),
    ("sort-distinct", sort0, sort1, false),
    ("sort-param-succ", .sort u, .sort (.succ u), false),
    ("literal-equal", .lit (.nat 7), .lit (.nat 7), true),
    ("literal-hash-collision", .lit (.nat 0), .lit (.nat 65521), false),
    ("literal-kinds", .lit (.nat 0), .lit (.str "0"), false),
    ("literal-strings", .lit (.str "λ-雪"), .lit (.str "λ-雨"), false),
    ("metadata-equivalent", .mdata 0 maxZero, .mdata 65521 sort0, true),
    ("metadata-distinct", .mdata 0 sort0, .mdata 1 sort1, false),
    ("metadata-nested", nestedLeft, nestedRight, true)]
  let officialEnv ← Lean.mkEmptyEnvironment
  for (label, left, right, expected) in fixtures do
    let some officialLeft := quickOfficialExpr left
      | throw (IO.userError ("official-quick-left-conversion-" ++ label))
    let some officialRight := quickOfficialExpr right
      | throw (IO.userError ("official-quick-right-conversion-" ++ label))
    require ("official-Lean-quick-defeq-" ++ label)
      (match Lean.Kernel.isDefEq officialEnv {} officialLeft officialRight with
       | .ok value => value == expected | .error _ => false)
    let (initial, leftId) ← expect (psKernelExprV2PagedImportChecked left)
    let (arena, rightId) ← expect (psKernelExprV2PagedImportIntoChecked initial right)
    for fuel in [0,1,2,3,4,8,16,17,18,64] do
      for maxDepth in [0,1,2] do
        let session ← fresh fuel maxDepth
        let checker := psKernelKernelSessionChecker session params .safe
        for entryDepth in [0,15,16] do
          let context := { checker.context with recDepth := entryDepth }
          require ("quick-defeq-raw-" ++ label)
            (sameQuickDefEq
              (psKernelSessionIsDefEq fuel { checker with context := context } left right)
              (psKernelExprV2TryQuickDefEqWithFuel fuel context arena leftId rightId))
        require ("quick-defeq-public-" ++ label)
          (sameDefEq
            (psKernelV1IsDefEq session params .safe left right)
            (psKernelV1RunDag session params .safe arena [.isDefEq leftId rightId]))
    let session ← fresh
    let checker := psKernelKernelSessionChecker session params .safe
    require ("quick-defeq-direct-answer-" ++ label)
      (match psKernelExprV2TryQuickDefEqWithFuel 64 checker.context arena leftId rightId with
       | some (.ok value) => value == expected
       | _ => false)
    let result ← expectPublic
      (psKernelV1RunDag session params .safe arena [.isDefEq leftId rightId])
    require ("quick-defeq-checked-answer-" ++ label)
      (match result.replies with | [.equal value] => value == expected | _ => false)
  let redex := PsKernelExpr.app
    (.lam (nm "quick-x") sort1 (.bvar 0) .default) sort0
  let fallback : List (String × PsKernelExpr × PsKernelExpr) := [
    ("metadata-one-sided", .mdata 9 sort0, sort0),
    ("metadata-composite", .mdata 9 redex, .mdata 10 sort0),
    ("mixed-constructors", sort0, .lit (.nat 0)),
    ("constant-level-rule", .const (nm "quick-missing") [.max .zero .zero],
      .const (nm "quick-missing") [.zero])]
  for (label, left, right) in fallback do
    let (initial, leftId) ← expect (psKernelExprV2PagedImportChecked left)
    let (arena, rightId) ← expect (psKernelExprV2PagedImportIntoChecked initial right)
    let session ← fresh
    let checker := psKernelKernelSessionChecker session params .safe
    require ("quick-defeq-explicit-fallback-" ++ label)
      (match psKernelExprV2TryQuickDefEqWithFuel 64 checker.context arena leftId rightId with
       | none => true | _ => false)
    for fuel in [0,1,2,3,4,8,64] do
      for maxDepth in [0,1,2] do
        let session ← fresh fuel maxDepth
        require ("quick-defeq-fallback-parity-" ++ label)
          (sameDefEq
            (psKernelV1IsDefEq session params .safe left right)
            (psKernelV1RunDag session params .safe arena [.isDefEq leftId rightId]))
  let bad := PsKernelExpr.app sort0 sort0
  let badLeft := PsKernelExpr.mdata 0 bad
  let badRight := PsKernelExpr.mdata 1 bad
  let (initial, leftId) ← expect (psKernelExprV2PagedImportChecked badLeft)
  let (arena, rightId) ← expect (psKernelExprV2PagedImportIntoChecked initial badRight)
  let session ← fresh
  let checker := psKernelKernelSessionChecker session params .safe
  require "quick-defeq-raw-rule-is-not-an-admission"
    (match psKernelExprV2TryQuickDefEqWithFuel 64 checker.context arena leftId rightId with
     | some (.ok true) => true | _ => false)
  require "quick-defeq-checks-both-metadata-operands-before-shortcut"
    (match psKernelV1RunDag session params .safe arena [.isDefEq leftId rightId] with
     | .error (.rejectedInvalid _) => true | _ => false)
  let (arena, goodId) ← expect (psKernelExprV2PagedImportIntoChecked arena sort0)
  for (left, right, a, b) in [
      (leftId, goodId, badLeft, sort0), (goodId, rightId, sort0, badRight)] do
    require "quick-defeq-neither-invalid-operand-can-be-skipped"
      (sameDefEq
        (psKernelV1IsDefEq session params .safe a b)
        (psKernelV1RunDag session params .safe arena [.isDefEq left right]))
  IO.println "PSC1_V2_DAG_OFFICIAL_QUICK_DEFEQ: PASS"
  IO.println "PSC1_V2_DAG_QUICK_DEFEQ: PASS"

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

private def sameWhnfValue
    (left right : Except PsKernelError PsKernelExpr) : Bool :=
  match left, right with
  | .error a, .error b => samePublicError a b
  | .ok a, .ok b => psKernelExprEqual a b
  | _, _ => false

private def constantTypeAttemptParity
    (label : String)
    (legacy : Except String PsKernelExpr)
    (attempted : Option (Except String (Prod PsKernelExprV2PagedArena Nat))) :
    IO Unit := do
  match legacy, attempted with
  | .error left, some (.error right) => require label (left == right)
  | .ok left, some (.ok result) =>
      let graph ← expect (psKernelExprV2DecodeChecked result.fst)
      let right ← expect (psKernelExprV2DecodedRequire graph result.snd)
      require label (psKernelExprEqual left right)
  | _, _ => throw (IO.userError ("PSC1_V2_DAG_CONSTANT_FALLBACK " ++ label))

private def deltaBatchParity : IO Unit := do
  let initial ← fresh
  let u := nm "delta-u"
  let polyName := nm "DagDeltaPoly"
  let firstName := nm "DagDeltaFirst"
  let aliasName := nm "DagDeltaAlias"
  let opaqueName := nm "DagDeltaOpaque"
  let theoremName := nm "DagDeltaTheorem"
  let mutualA := nm "DagDeltaMutualA"
  let mutualB := nm "DagDeltaMutualB"
  let cycleA := nm "DagDeltaCycleA"
  let cycleB := nm "DagDeltaCycleB"
  let level2 := PsKernelLevel.succ (.succ .zero)
  let (arena, s0) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
  let (arena, s1) ← expect (psKernelExprV2PagedMkSort arena (.succ .zero))
  let (arena, su) ← expect (psKernelExprV2PagedMkSort arena (.param u))
  let (arena, b0) ← expect (psKernelExprV2PagedMkBVar arena 0)
  let (arena, b1) ← expect (psKernelExprV2PagedMkBVar arena 1)
  let (arena, innerType) ← expect (psKernelExprV2PagedMkForall arena (nm "x") b0 b1 .default)
  let (arena, innerBody) ← expect (psKernelExprV2PagedMkLam arena (nm "x") b0 b0 .default)
  let (arena, polyType) ← expect (psKernelExprV2PagedMkForall arena (nm "A") su innerType .default)
  let (arena, polyBody) ← expect (psKernelExprV2PagedMkLam arena (nm "A") su innerBody .default)
  let (arena, firstTypeTail) ← expect (psKernelExprV2PagedMkForall arena (nm "b") s1 s1 .default)
  let (arena, firstType) ← expect (psKernelExprV2PagedMkForall arena (nm "a") s1 firstTypeTail .default)
  let (arena, firstBodyTail) ← expect (psKernelExprV2PagedMkLam arena (nm "b") s1 b1 .default)
  let (arena, firstBody) ← expect (psKernelExprV2PagedMkLam arena (nm "a") s1 firstBodyTail .default)
  let (arena, proofType) ← expect (psKernelExprV2PagedMkForall arena (nm "P") s0 innerType .default)
  let (arena, proofBody) ← expect (psKernelExprV2PagedMkLam arena (nm "P") s0 innerBody .default)
  let (arena, poly) ← expect (psKernelExprV2PagedMkConst arena polyName [level2])
  let (arena, wrongArity) ← expect (psKernelExprV2PagedMkConst arena polyName [])
  let (arena, partialPoly) ← expect (psKernelExprV2PagedMkApp arena poly s1)
  let (arena, appliedPoly) ← expect (psKernelExprV2PagedMkApp arena partialPoly s0)
  let (arena, first) ← expect (psKernelExprV2PagedMkConst arena firstName [])
  let (arena, alias) ← expect (psKernelExprV2PagedMkConst arena aliasName [])
  let (arena, opaqueRoot) ← expect (psKernelExprV2PagedMkConst arena opaqueName [])
  let (arena, theoremRoot) ← expect (psKernelExprV2PagedMkConst arena theoremName [])
  let (arena, ma) ← expect (psKernelExprV2PagedMkConst arena mutualA [])
  let (arena, mb) ← expect (psKernelExprV2PagedMkConst arena mutualB [])
  let (arena, ca) ← expect (psKernelExprV2PagedMkConst arena cycleA [])
  let (arena, cb) ← expect (psKernelExprV2PagedMkConst arena cycleB [])
  let mut workingArena := arena
  let mut hidden := s0
  for tag in [0,1,2,3] do
    let result ← expect (psKernelExprV2PagedMkMData workingArena tag hidden)
    workingArena := result.fst
    hidden := result.snd
  let (arena, firstApplied) ← expect (psKernelExprV2PagedMkApp workingArena first s0)
  let (arena, ignoredArgument) ← expect (psKernelExprV2PagedMkApp arena firstApplied hidden)
  let aliasDef := PsKernelDagDefinition.mk
    (PsKernelDagConstantBase.mk aliasName [] s1) s0 .abbrevHint .safe
  let polyDef := PsKernelDagDefinition.mk
    (PsKernelDagConstantBase.mk polyName [u] polyType) polyBody .abbrevHint .safe
  let firstDef := PsKernelDagDefinition.mk
    (PsKernelDagConstantBase.mk firstName [] firstType) firstBody .abbrevHint .safe
  let requests : List PsKernelDagDeclarationRequest := [
    .definitionDecl aliasDef, .definitionDecl polyDef, .definitionDecl firstDef,
    .opaqueDecl (PsKernelDagConstantBase.mk opaqueName [] s1) s0 false,
    .theoremDecl (PsKernelDagConstantBase.mk theoremName [] proofType) proofBody,
    .mutualDefinitions [
      PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk mutualA [] s1) mb .abbrevHint .unsafeDef,
      PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk mutualB [] s1) s0 .abbrevHint .unsafeDef],
    .mutualDefinitions [
      PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk cycleA [] s1) cb .abbrevHint .unsafeDef,
      PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk cycleB [] s1) ca .abbrevHint .unsafeDef]]
  let built ← expect (psKernelExprV2DecodeChecked arena)
  let emptyExecution := PsKernelDagExecutionState.mk initial []
  let firstAdmission ← expectPublic (psKernelDagRunCommand emptyExecution [] .safe
    arena built (.admit (.definitionDecl aliasDef)))
  let mut execution := firstAdmission.snd
  for request in requests.tail do
    let result ← expectPublic (psKernelDagRunCommand execution [] .unsafeDef
      arena built (.admit request))
    execution := result.snd
  require "delta-only-successfully-admitted-declarations-registered"
    (execution.declarations.length == 9)
  require "delta-reference-is-original-canonical-body-id"
    (match psKernelExprV2DeclarationRefFind execution.declarations polyName with
     | some definition => definition.deltaValue == some polyBody | none => false)
  require "delta-theorem-type-index-does-not-authorize-unfolding"
    (match psKernelExprV2DeclarationRefFind execution.declarations theoremName with
     | some declaration =>
         declaration.deltaValue.isNone && declaration.type == proofType &&
           (match declaration.kind with | .theoremDecl => true | _ => false)
     | none => false)
  require "delta-opaque-type-index-does-not-authorize-unfolding"
    (match psKernelExprV2DeclarationRefFind execution.declarations opaqueName with
     | some declaration =>
         declaration.deltaValue.isNone && declaration.type == s1 &&
           (match declaration.kind with | .opaqueDecl => true | _ => false)
     | none => false)
  let checker := psKernelKernelSessionChecker execution.session [] .unsafeDef
  let expectedPoly := PsKernelExpr.lam (nm "A") (.sort level2)
    (.lam (nm "x") (.bvar 0) (.bvar 0) .default) .default
  let expectedPartial := PsKernelExpr.lam (nm "x") sort1 (.bvar 0) .default
  let cases : List (Nat × PsKernelExpr) := [
    (poly, expectedPoly), (partialPoly, expectedPartial), (appliedPoly, sort0),
    (ignoredArgument, sort0), (alias, sort0),
    (opaqueRoot, .const opaqueName []), (theoremRoot, .const theoremName []),
    (ma, sort0)]
  for (root, expected) in cases do
    let term ← expect (psKernelExprV2DecodedRequire built root)
    let original ← expect (psKernelSessionWhnf 64 checker term)
    require "delta-reference-result-sanity" (psKernelExprEqual original.fst expected)
    for fuel in [0,1,2,3,4,5,6,8,12,32,64] do
      for depth in [0,1,2] do
        let context := { checker.context with maxRecDepth := depth }
        rawStateWhnfParity "delta-raw-exact-fuel-depth-parity"
          (psKernelSessionWhnf fuel { checker with context := context } term)
          (psKernelExprV2TryWhnfStateWithFuel fuel context
            (psKernelExprV2WhnfStateForDeclarations arena execution.declarations) root)
        let policySession := { execution.session with resources :=
          { execution.session.resources with fuel := fuel, maxRecDepth := depth } }
        -- RunDag preflights once before this internal helper. Match that same
        -- public boundary when comparing it with the standalone V1 operation.
        let actualPublic : Except PsKernelError PsKernelExpr :=
          match psKernelKernelSessionPreflight policySession with
          | .error error => .error error
          | .ok _ => psKernelDagWhnfExpression policySession [] .unsafeDef arena built
              execution.declarations root term
        require ("delta-public-exact-fuel-depth-parity-root-" ++ toString root ++
            "-fuel-" ++ toString fuel ++ "-depth-" ++ toString depth)
          (sameWhnfValue
            (psKernelV1Whnf policySession [] .unsafeDef term) actualPublic)
    for recDepth in [15,16] do
      let context := { checker.context with maxRecDepth := 1, recDepth := recDepth }
      rawStateWhnfParity "delta-exact-entry-recursion-boundary"
        (psKernelSessionWhnf 64 { checker with context := context } term)
        (psKernelExprV2TryWhnfStateWithFuel 64 context
          (psKernelExprV2WhnfStateForDeclarations arena execution.declarations) root)
  let ignored ← expect (psKernelExprV2DecodedRequire built ignoredArgument)
  require "delta-ignored-argument-still-normalized-before-unfolding"
    (match psKernelSessionWhnf 5 checker ignored with
     | .error error => error == "kernel reduction budget exhausted" | _ => false)
  let ignoredResult ← expect (psKernelSessionWhnf 6 checker ignored)
  require "delta-ignored-argument-exact-threshold"
    (psKernelExprEqual ignoredResult.fst sort0)
  let wrong ← expect (psKernelExprV2DecodedRequire built wrongArity)
  for fuel in [0,1,2,3,8] do
    rawStateWhnfParity "delta-wrong-universe-arity-stays-stuck"
      (psKernelSessionWhnf fuel checker wrong)
      (psKernelExprV2TryWhnfStateWithFuel fuel checker.context
        (psKernelExprV2WhnfStateForDeclarations arena execution.declarations) wrongArity)
  require "delta-public-rejects-wrong-universe-arity"
    (match psKernelV1RunDag execution.session [] .safe arena [.whnf wrongArity] with
     | .error (.rejectedInvalid _) => true | _ => false)
  let cycle ← expect (psKernelExprV2DecodedRequire built ca)
  for fuel in [0,1,2,3,4,8,16] do
    require "delta-mutual-cycle-preserves-resource-exhaustion"
      (match psKernelSessionWhnf fuel checker cycle with
       | .error error => error == "kernel reduction budget exhausted" | _ => false)
    rawStateWhnfParity "delta-mutual-cycle-exact-error"
      (psKernelSessionWhnf fuel checker cycle)
      (psKernelExprV2TryWhnfStateWithFuel fuel checker.context
        (psKernelExprV2WhnfStateForDeclarations arena execution.declarations) ca)
  let commands := requests.map PsKernelDagCommand.admit
  for (root, safety) in [(appliedPoly, PsKernelDefinitionSafety.safe),
      (ma, PsKernelDefinitionSafety.unsafeDef)] do
    let result ← expectPublic (psKernelV1RunDag initial [] safety arena
      (commands ++ [.whnf root]))
    require "delta-complete-public-batch"
      (match result.replies.reverse with
       | .normalized value :: _ => psKernelExprEqual value sort0 | _ => false)
  require "delta-command-order-does-not-see-future-admissions"
    (match psKernelV1RunDag initial [] .safe arena
       [.whnf alias, .admit (.definitionDecl aliasDef)] with
     | .error (.rejectedInvalid _) => true | _ => false)
  require "delta-external-session-declarations-explicitly-fallback"
    ((psKernelExprV2TryWhnfWithFuel 64 checker.context arena appliedPoly).isNone)
  let (foreign, foreignZero) ← expect
    (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty (.succ .zero))
  require "delta-foreign-arena-reuses-old-body-id" (foreignZero == s0)
  let (foreign, foreignAlias) ← expect (psKernelExprV2PagedMkConst foreign aliasName [])
  let foreignResult ← expectPublic
    (psKernelV1RunDag execution.session [] .safe foreign [.whnf foreignAlias])
  require "delta-definition-reference-does-not-escape-batch-arena"
    (match foreignResult.replies with
     | [.normalized value] => psKernelExprEqual value sort0 | _ => false)
  let badName := nm "DagDeltaUnadmitted"
  let invalidRef := { aliasDef with
    base := { aliasDef.base with name := badName }
    value := arena.size }
  let illTyped := { aliasDef with
    base := { aliasDef.base with name := badName }
    value := s1 }
  for bad in [invalidRef, illTyped] do
    require "delta-failed-admission-does-not-produce-execution"
      (match psKernelDagRunCommand emptyExecution [] .safe arena built
         (.admit (.definitionDecl bad)) with
       | .error (.rejectedInvalid _) => true | _ => false)
    require "delta-public-rejects-malformed-or-illtyped-admission"
      (match psKernelV1RunDag initial [] .safe arena [.admit (.definitionDecl bad)] with
       | .error (.rejectedInvalid _) => true | _ => false)
  require "delta-failed-admission-preserves-empty-owner"
    (emptyExecution.declarations.isEmpty &&
      (psKernelEnvironmentFind initial.environment badName).isNone)
  let changedDuplicate := { aliasDef with value := s1 }
  require "delta-duplicate-cannot-replace-admitted-reference"
    (match psKernelDagRunCommand execution [] .safe arena built
       (.admit (.definitionDecl changedDuplicate)) with
     | .error (.rejectedInvalid _) =>
         match psKernelExprV2DeclarationRefFind execution.declarations aliasName with
         | some definition => definition.deltaValue == some s0 | none => false
     | _ => false)
  let bounded := { firstAdmission.snd with session :=
    { firstAdmission.snd.session with resources :=
      { firstAdmission.snd.session.resources with maxDeclarations := 1 } } }
  require "delta-limit-failure-publishes-no-definition-reference"
    (match psKernelDagRunCommand bounded [] .safe arena built
       (.admit (.definitionDecl polyDef)) with
     | .error (.resourceExhausted .declarationLimit _) =>
         bounded.declarations.length == 1 &&
           (psKernelExprV2DeclarationRefFind bounded.declarations polyName).isNone
     | _ => false)
  Lean.initSearchPath (← Lean.findSysroot)
  let officialEnv ← Lean.importModules
    #[{ module := Lean.Name.str .anonymous "Init" }] {}
  let official := Lean.Expr.app
    (.app (.const (Lean.Name.str .anonymous "id") [.succ (.succ .zero)])
      (.sort (.succ .zero))) (.sort .zero)
  require "delta-official-polymorphic-identity-type"
    (match Lean.Kernel.check officialEnv {} official with
     | .ok value => Lean.Expr.equal value (.sort (.succ .zero)) | _ => false)
  require "delta-official-polymorphic-identity-whnf"
    (match Lean.Kernel.whnf officialEnv {} official with
     | .ok value => Lean.Expr.equal value (.sort .zero) | _ => false)
  IO.println "PSC1_V2_DAG_NATIVE_OFFICIAL_POLY_DELTA: PASS"
  let safeAxiomName := nm "DagIndexedType"
  let unsafeAxiomName := nm "DagIndexedUnsafeType"
  let partialName := nm "DagIndexedPartial"
  let unsafeOpaqueName := nm "DagIndexedUnsafeOpaque"
  let (typedArena, safeAxiom) ← expect (psKernelExprV2PagedMkConst arena safeAxiomName [])
  let (typedArena, unsafeAxiom) ← expect (psKernelExprV2PagedMkConst typedArena unsafeAxiomName [])
  let (typedArena, partialRoot) ← expect (psKernelExprV2PagedMkConst typedArena partialName [])
  let (typedArena, unsafeOpaque) ← expect (psKernelExprV2PagedMkConst typedArena unsafeOpaqueName [])
  let (typedArena, unsafeWrongArity) ← expect (psKernelExprV2PagedMkConst typedArena mutualA [.zero])
  let unknownName := nm "DagIndexedUnknown"
  let (typedArena, unknownRoot) ← expect (psKernelExprV2PagedMkConst typedArena unknownName [.zero])
  let typedBuilt ← expect (psKernelExprV2DecodeChecked typedArena)
  let extraRequests : List PsKernelDagDeclarationRequest := [
    .axiomDecl (PsKernelDagConstantBase.mk safeAxiomName [] s1) false,
    .axiomDecl (PsKernelDagConstantBase.mk unsafeAxiomName [] s1) true,
    .definitionDecl (PsKernelDagDefinition.mk
      (PsKernelDagConstantBase.mk partialName [] s1) s0 .abbrevHint .partialDef),
    .opaqueDecl (PsKernelDagConstantBase.mk unsafeOpaqueName [] s1) s0 true]
  let mut typedExecution := execution
  for request in extraRequests do
    let result ← expectPublic (psKernelDagRunCommand typedExecution [] .safe
      typedArena typedBuilt (.admit request))
    typedExecution := result.snd
  require "constant-index-single-table-count" (typedExecution.declarations.length == 13)
  for declaration in typedExecution.declarations do
    let actual := psKernelEnvironmentFind typedExecution.session.environment declaration.name
    match actual with
    | none => throw (IO.userError "indexed declaration missing from checked environment")
    | some info =>
        require "constant-index-live-metadata-correspondence"
          (psKernelExprV2DeclarationRefMatches declaration info)
        let sourceType ← expect (psKernelExprV2DecodedRequire typedBuilt declaration.type)
        require "constant-index-source-type-installed-unchanged"
          (psKernelExprEqual sourceType (psKernelConstantInfoType info))
  let constantCases : List (Nat × PsKernelName × List PsKernelLevel) := [
    (poly, polyName, [level2]), (alias, aliasName, []),
    (opaqueRoot, opaqueName, []), (theoremRoot, theoremName, []),
    (ma, mutualA, []), (safeAxiom, safeAxiomName, []),
    (unsafeAxiom, unsafeAxiomName, []), (partialRoot, partialName, []),
    (unsafeOpaque, unsafeOpaqueName, [])]
  for (root, constantName, levels) in constantCases do
    let term ← expect (psKernelExprV2DecodedRequire typedBuilt root)
    for safety in [PsKernelDefinitionSafety.safe, .unsafeDef, .partialDef] do
      let typedChecker := psKernelKernelSessionChecker typedExecution.session [] safety
      for inferOnly in [false,true] do
        constantTypeAttemptParity "constant-index-shared-reference-rule"
          (psKernelInferConstantType typedChecker.context constantName levels inferOnly)
          (psKernelExprV2TryInferConstantType typedChecker.context typedArena
            typedExecution.declarations constantName levels inferOnly)
      for fuel in [0,1,2,3,4,8,64] do
        for recDepth in [0,15,16] do
          let context := { typedChecker.context with
            maxRecDepth := 1
            recDepth := recDepth }
          let original := psKernelSessionCheck fuel { typedChecker with context := context } term
          let originalType :=
            match original with
            | .error error => Except.error error
            | .ok result => Except.ok result.fst
          constantTypeAttemptParity "constant-index-exact-fuel-and-depth"
            originalType
            (psKernelExprV2TryCheckWithDeclarationsFuel fuel context typedArena
              typedExecution.declarations root)
  let safeChecker := psKernelKernelSessionChecker typedExecution.session [] .safe
  for (constantName, expected) in [
      (mutualA, "safe declaration uses unsafe constant"),
      (unsafeAxiomName, "safe declaration uses unsafe constant"),
      (unsafeOpaqueName, "safe declaration uses unsafe constant"),
      (partialName, "safe declaration uses partial constant")] do
    require "constant-index-live-safety-rejection"
      (match psKernelExprV2TryInferConstantType safeChecker.context typedArena
          typedExecution.declarations constantName [] false with
       | some (.error error) => error == expected | _ => false)
    let unchecked ← expect (psKernelInferConstantType safeChecker.context constantName [] true)
    require "constant-index-infer-only-keeps-original-safety-skip"
      (psKernelExprEqual unchecked sort1)
  require "constant-index-arity-error-precedes-unsafe-error"
    (match psKernelExprV2TryInferConstantType safeChecker.context typedArena
        typedExecution.declarations mutualA [.zero] false with
     | some (.error error) => error == "incorrect number of universe levels" | _ => false)
  require "constant-index-lookup-error-precedes-level-arity"
    (match psKernelExprV2TryInferConstantType safeChecker.context typedArena
        typedExecution.declarations unknownName [.zero] false with
     | some (.error error) => error == "unknown constant" | _ => false)
  for root in [unsafeWrongArity, unknownRoot, wrongArity] do
    let term ← expect (psKernelExprV2DecodedRequire typedBuilt root)
    let original := psKernelSessionCheck 8 safeChecker term
    let originalType :=
      match original with
      | .error error => Except.error error
      | .ok result => Except.ok result.fst
    constantTypeAttemptParity "constant-index-negative-direct-check-parity" originalType
      (psKernelExprV2TryCheckWithDeclarationsFuel 8 safeChecker.context typedArena
        typedExecution.declarations root)
  require "constant-index-valid-external-session-explicit-fallback"
    ((psKernelExprV2TryCheckWithFuel 8 safeChecker.context typedArena alias).isNone)
  let aliasReference ←
    match psKernelExprV2DeclarationRefFind typedExecution.declarations aliasName with
    | some value => pure value
    | none => throw (IO.userError "missing alias reference")
  for changed in [
      { aliasReference with kind := .axiomDecl },
      { aliasReference with levelParams := [nm "wrong-universe-owner"] }] do
    require "constant-index-kind-or-parameter-mismatch-explicit-fallback"
      ((psKernelExprV2TryInferConstantType safeChecker.context typedArena [changed]
        aliasName [] false).isNone)
  let checkedBatch ← expectPublic (psKernelV1RunDag initial [] .safe typedArena
    ((requests ++ extraRequests).map PsKernelDagCommand.admit ++ [.check poly]))
  let expectedPolyType := PsKernelExpr.forallE (nm "A") (.sort level2)
    (.forallE (nm "x") (.bvar 0) (.bvar 1) .default) .default
  require "constant-index-complete-public-polymorphic-check"
    (match checkedBatch.replies.reverse with
     | .checked value :: _ => psKernelExprEqual value.type expectedPolyType
     | _ => false)
  for root in [ma, unsafeAxiom, partialRoot, unsafeOpaque] do
    require "constant-index-complete-public-safe-rejection"
      (match psKernelV1RunDag initial [] .safe typedArena
          ((requests ++ extraRequests).map PsKernelDagCommand.admit ++ [.check root]) with
       | .error (.rejectedInvalid _) => true | _ => false)
  let foreignCheck ← expectPublic
    (psKernelV1RunDag typedExecution.session [] .safe foreign [.check foreignAlias])
  require "constant-index-does-not-escape-owning-batch"
    (match foreignCheck.replies with
     | [.checked value] => psKernelExprEqual value.type sort1 | _ => false)
  IO.println "PSC1_V2_DAG_NATIVE_CONSTANT_INDEX: PASS"
  IO.println "PSC1_V2_DAG_NATIVE_DELTA: PASS"

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

private def nestedDiagnosticClassification : IO Unit := do
  let prefixes := ["", "nested preprocessing: ", "nested transformed admission: ",
    "nested original restoration: ", "nested auxiliary restoration: ",
    "nested restored validation: "]
  let resources : List (String × PsKernelResourceError) := [
    ("kernel reduction budget exhausted", .fuel),
    ("kernel inference budget exhausted", .fuel),
    ("deep recursion detected, use maxRecDepth to increase the limit", .recursionDepth),
    ("the kernel refused a Nat numeral because its size exceeds the maximum", .natSize),
    ("the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size", .natSize)]
  for messagePrefix in prefixes do
    let invalid := messagePrefix ++ "invalid projection: structure type mismatch"
    require "nested-diagnostic-exact-invalid-with-original-message"
      (samePublicError (psKernelErrorFromMessage invalid) (.rejectedInvalid invalid))
    let unsupported := messagePrefix ++ "nested or invalid mutual inductive occurrence is not supported"
    require "nested-diagnostic-exact-unsupported-with-original-message"
      (samePublicError (psKernelErrorFromMessage unsupported) (.declinedUnsupported unsupported))
    for (body, resource) in resources do
      let message := messagePrefix ++ body
      require "nested-diagnostic-preserves-resource-category-and-message"
        (samePublicError (psKernelErrorFromMessage message)
          (.resourceExhausted resource message))
  for message in [
      "unrecognized diagnostic",
      "provider: invalid projection: structure type mismatch",
      "nested restored validation: unrecognized diagnostic",
      "nested restored validation: ",
      "nested restored validation:invalid projection: structure type mismatch",
      "nested restored validation: invalid projection: structure type mismatch trailing",
      "nested restored validation: nested restored validation: invalid projection: structure type mismatch",
      "nested preprocessing: nested restored validation: kernel reduction budget exhausted"] do
    require "nested-diagnostic-unknown-or-double-wrapper-remains-internal"
      (samePublicError (psKernelErrorFromMessage message) (.internalError message))
  require "resource-message-bare-api-remains-bare"
    ((psKernelResourceMessage "nested restored validation: kernel reduction budget exhausted").isNone)
  IO.println "PSC1_V2_DAG_NATIVE_NESTED_OUTCOMES: PASS"

private def binderRaw
    (fuel : Nat) (context : PsKernelCheckerContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :=
  psKernelExprV2TryCheckCoreWithFuel fuel
    (psKernelExprV2TryWhnfStateWithFuel fuel)
    (psKernelExprV2CheckContextEmpty context) state root

private def compareBinderRaw (label : String)
    (legacy : Except String (Prod PsKernelExpr PsKernelCheckerSession))
    (attempted : Option (Except String (Prod PsKernelExprV2CheckState Nat))) : IO Unit := do
  match legacy, attempted with
  | .error left, some (.error right) => require (label ++ "-error") (left == right)
  | .ok left, some (.ok right) =>
      let graph ← expect (psKernelExprV2DecodeChecked right.fst.whnf.arena)
      let type ← expect (psKernelExprV2DecodedRequire graph right.snd)
      require (label ++ "-type") (psKernelExprEqual left.fst type)
      require (label ++ "-fresh") (left.snd.state.nextFresh == right.fst.nextFresh)
  | _, _ => throw (IO.userError ("PSC1_V2_BINDER_MISSING_DIRECT_RESULT " ++ label))

private def binderParity : IO Unit := do
  let x := nm "binder-x"
  let a := nm "binder-a"
  let y := nm "binder-y"
  let fixtures : List (String × PsKernelExpr) := [
    ("sort", sort0),
    ("literal-nat", .lit (.nat 65521)),
    ("literal-string", .lit (.str "λ-雪")),
    ("loose", .bvar 0),
    ("unknown", .fvar (nm "binder-outside")),
    ("metavariable", .mvar (nm "binder-meta")),
    ("identity", .lam x sort1 (.bvar 0) .default),
    ("dependent-lambda", .lam a sort0
      (.lam x (.bvar 0) (.bvar 0) .instImplicit) .implicit),
    ("dependent-forall", .forallE a sort0
      (.forallE x (.bvar 0) (.bvar 1) .strictImplicit) .default),
    ("lambda-forall", .lam a sort0
      (.forallE x (.bvar 0) (.bvar 1) .default) .implicit),
    ("metadata-body", .lam x sort1 (.mdata 7 (.bvar 0)) .implicit),
    ("bad-domain", .forallE x (.lam y sort1 (.bvar 0) .default) sort0 .default),
    ("bad-codomain", .forallE x sort0 (.lam y sort1 (.bvar 0) .default) .default),
    ("raw-forged-fresh-name", .lam x sort1 (.fvar (.num x 0)) .default),
    ("unknown-under-binder", .lam x sort1 (.fvar (nm "binder-outside")) .default)]
  for (label, term) in fixtures do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,2,3,4,8,16,32,64] do
      for maxDepth in [0,1,2] do
        let session ← fresh fuel maxDepth
        let checker := psKernelKernelSessionChecker session [] .safe
        for recDepth in [0,15,16] do
          let context := { checker.context with recDepth := recDepth }
          compareBinderRaw ("binder-" ++ label)
            (psKernelSessionCheck fuel { checker with context := context } term)
            (binderRaw fuel context (psKernelExprV2CheckStateEmpty arena) root)
        require ("binder-public-" ++ label)
          (sameCheck
            (psKernelV1CheckExpression session [] .safe term)
            (oneCheck session arena root))
  let mut domain := sort0
  for tag in [:8] do domain := .mdata tag domain
  let reused := PsKernelExpr.forallE x domain
    (.forallE y domain domain .default) .default
  let callback := PsKernelExpr.lam a domain
    (.forallE x (.bvar 0) (.bvar 1) .default) .implicit
  for (label, term) in [("cache-reuse", reused), ("fixed-whnf-fuel", callback)] do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,7,8,9,10,11,12,16,64] do
      let session ← fresh fuel
      let checker := psKernelKernelSessionChecker session [] .safe
      compareBinderRaw label (psKernelSessionCheck fuel checker term)
        (binderRaw fuel checker.context (psKernelExprV2CheckStateEmpty arena) root)
      require (label ++ "-public")
        (sameCheck (psKernelV1CheckExpression session [] .safe term)
          (oneCheck session arena root))
    let session ← fresh 10
    require (label ++ "-exact-boundary-accepts")
      (match psKernelV1RunDag session [] .safe arena [.check root] with
       | .ok _ => true | _ => false)
  let (initial, reusedId) ← expect (psKernelExprV2PagedImportChecked reused)
  let (arena, domainId) ← expect (psKernelExprV2PagedImportIntoChecked initial domain)
  let session ← fresh 10 1
  let checker := psKernelKernelSessionChecker session [] .safe
  let legacy ← expect (psKernelSessionCheck 10 checker reused)
  let direct ←
    match binderRaw 10 checker.context (psKernelExprV2CheckStateEmpty arena) reusedId with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_BINDER_CACHE_FALLBACK")
  require "binder-fresh-counter-after-two-scopes" (direct.fst.nextFresh == 2)
  require "binder-scope-restores-public-whnf-cache"
    (match direct.fst.whnf.publicCache with | [] => true | _ => false)
  for (fuel, recDepth) in [(0,0), (1,0), (1,16)] do
    let context := { checker.context with recDepth := recDepth }
    compareBinderRaw "binder-warm-cache-entry-guards"
      (psKernelSessionCheck fuel { legacy.snd with context := context } domain)
      (binderRaw fuel context direct.fst domainId)
  require "binder-cold-domain-fuel-one-fails"
    (match binderRaw 1 checker.context
        (psKernelExprV2CheckStateEmpty direct.fst.whnf.arena) domainId with
     | some (.error error) => error == "kernel inference budget exhausted" | _ => false)
  let mut hiddenBody := sort1
  for tag in [:8] do hiddenBody := .mdata (tag + 100) hiddenBody
  let scopedTerm := PsKernelExpr.lam x sort0 hiddenBody .default
  let (initial, scopedId) ← expect (psKernelExprV2PagedImportChecked scopedTerm)
  let (arena, hiddenId) ← expect (psKernelExprV2PagedImportIntoChecked initial hiddenBody)
  let scopedLegacy ← expect (psKernelSessionCheck 10 checker scopedTerm)
  let scopedDirect ←
    match binderRaw 10 checker.context (psKernelExprV2CheckStateEmpty arena) scopedId with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_BINDER_SCOPE_FALLBACK")
  let hiddenEntry ← expect (psKernelExprV2PagedRequire scopedDirect.fst.whnf.arena hiddenId)
  let hiddenCached ← expect (psKernelExprV2CheckedInferFind scopedDirect.fst hiddenId hiddenEntry)
  require "binder-closed-child-cache-does-not-escape"
    (match hiddenCached with | none => true | _ => false)
  compareBinderRaw "binder-child-cache-cannot-change-parent-fuel"
    (psKernelSessionCheck 1 scopedLegacy.snd hiddenBody)
    (binderRaw 1 checker.context scopedDirect.fst hiddenId)
  let escapedName := PsKernelName.num x 0
  let (escapedArena, escapedId) ← expect
    (psKernelExprV2PagedMkFVar scopedDirect.fst.whnf.arena escapedName)
  compareBinderRaw "binder-local-context-does-not-escape"
    (psKernelSessionCheck 64 scopedLegacy.snd (.fvar escapedName))
    (binderRaw 64 checker.context
      (psKernelExprV2CheckStateWithArena scopedDirect.fst escapedArena) escapedId)
  let oneName := PsKernelName.num (nm "binder-level") 0
  let twoName := PsKernelName.num (nm "binder-level") 65521
  let leftTerm := PsKernelExpr.sort (.param oneName)
  let rightTerm := PsKernelExpr.sort (.param twoName)
  let (arena, leftId) ← expect (psKernelExprV2PagedImportChecked leftTerm)
  let (arena, rightId) ← expect (psKernelExprV2PagedImportIntoChecked arena rightTerm)
  let leftEntry ← expect (psKernelExprV2PagedRequire arena leftId)
  let rightEntry ← expect (psKernelExprV2PagedRequire arena rightId)
  require "binder-real-sort-hash-collision" (leftEntry.hash == rightEntry.hash)
  let session ← fresh
  let checker := psKernelKernelSessionChecker session [oneName,twoName] .safe
  let legacy ← expect (psKernelSessionCheck 1 checker leftTerm)
  let direct ←
    match binderRaw 1 checker.context (psKernelExprV2CheckStateEmpty arena) leftId with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_BINDER_SORT_FALLBACK")
  compareBinderRaw "binder-hash-collision-does-not-reuse-wrong-type"
    (psKernelSessionCheck 1 legacy.snd rightTerm)
    (binderRaw 1 checker.context direct.fst rightId)
  let locals := psKernelLocalContextAddLocal checker.context.localContext
    x x sort0 .default
  let outside := psKernelCheckerContextWithLocalContext checker.context locals
  require "binder-does-not-drop-existing-legacy-locals"
    (match psKernelExprV2TryCheckWithFuel 64 outside arena leftId with
     | none => true | _ => false)
  for term in [PsKernelExpr.lit (.nat 0), .lit (.nat 65521), .lit (.str "λ-雪")] do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,2,8] do
      for limit in [0,7,8,16] do
        let initial ← fresh fuel
        let session := { initial with resources := { initial.resources with maxNatSize := limit } }
        let checker := psKernelKernelSessionChecker session [] .safe
        compareBinderRaw "binder-literal-resource-order"
          (psKernelSessionCheck fuel checker term)
          (binderRaw fuel checker.context (psKernelExprV2CheckStateEmpty arena) root)
        require "binder-literal-public-resource-parity"
          (sameCheck (psKernelV1CheckExpression session [] .safe term)
            (oneCheck session arena root))
    let session ← fresh 8
    let checker := psKernelKernelSessionChecker session [] .safe
    require "binder-literal-does-not-publish-inference-cache"
      (match binderRaw 8 checker.context (psKernelExprV2CheckStateEmpty arena) root with
       | some (.ok result) =>
           match result.fst.checkedInfer with | [] => true | _ => false
       | _ => false)
  let unsupported : List PsKernelExpr := [
    .letE x sort1 sort0 (.bvar 0) false]
  for term in unsupported do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    require "binder-explicit-complete-checker-fallback"
      (match psKernelExprV2TryCheckWithFuel 64 checker.context arena root with
       | none => true | _ => false)
    require "binder-fallback-public-parity"
      (sameCheck (psKernelV1CheckExpression session [] .safe term)
        (oneCheck session arena root))
  let invalidProjection := PsKernelExpr.proj (nm "binder-unknown-structure") 0 sort0
  let (invalidArena, invalidRoot) ← expect (psKernelExprV2PagedImportChecked invalidProjection)
  require "binder-projection-now-direct-negative"
    (match psKernelExprV2TryCheckWithFuel 64 checker.context invalidArena invalidRoot with
     | some (.error _) => true | _ => false)
  require "binder-projection-public-negative-parity"
    (sameCheck (psKernelV1CheckExpression session [] .safe invalidProjection)
      (oneCheck session invalidArena invalidRoot))
  let cheapFixtures : List PsKernelExpr := [
    sort0, .lam x sort1 (.bvar 0) .default,
    .app (.lam x sort1 (.bvar 0) .default) sort0,
    .app (.lam x sort1 sort0 .default) sort1,
    .app (.lam x sort1 (.bvar 1) .default) sort0,
    .app (.lam x sort1 (.mdata 7 (.bvar 0)) .default) sort0,
    .app (.app (.lam x sort1 (.lam y sort1 (.bvar 1) .default) .default)
      sort0) sort1,
    .app (.app (.lam x sort1 (.bvar 0) .default) sort0) sort1]
  for term in cheapFixtures do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    let (next, result) ← expect (psKernelExprV2CheapBetaOnCanonical arena root)
    let decoded ← expect (psKernelExprV2DecodeChecked next)
    let actual ← expect (psKernelExprV2DecodedRequire decoded result)
    require "binder-exact-cheap-beta"
      (psKernelExprEqual (psKernelExprCheapBetaReduce term) actual)
  let env ← Lean.mkEmptyEnvironment
  let la := Lean.Name.str .anonymous "binder-a"
  let lx := Lean.Name.str .anonymous "binder-x"
  let officialTerm := Lean.Expr.lam la (.sort .zero)
    (.lam lx (.bvar 0) (.bvar 0) .default) .implicit
  let officialType := Lean.Expr.forallE la (.sort .zero)
    (.forallE lx (.bvar 0) (.bvar 1) .default) .implicit
  let independentTerm := PsKernelExpr.lam a sort0
    (.lam x (.bvar 0) (.bvar 0) .default) .implicit
  let independentType := PsKernelExpr.forallE a sort0
    (.forallE x (.bvar 0) (.bvar 1) .default) .implicit
  let (arena, root) ← expect (psKernelExprV2PagedImportChecked independentTerm)
  let session ← fresh
  let actual ← expectPublic (oneCheck session arena root)
  require "binder-official-dependent-lambda"
    (match Lean.Kernel.check env {} officialTerm, checkReply actual with
     | .ok type, some checked =>
         Lean.Expr.equal type officialType && psKernelExprEqual checked.type independentType
     | _, _ => false)
  let (arena, root) ← expect (psKernelExprV2PagedImportChecked independentType)
  let actual ← expectPublic (oneCheck session arena root)
  require "binder-official-dependent-forall"
    (match Lean.Kernel.check env {} officialType, checkReply actual with
     | .ok type, some checked =>
         Lean.Expr.equal type (.sort .zero) && psKernelExprEqual checked.type sort0
     | _, _ => false)
  IO.println "PSC1_V2_DAG_OFFICIAL_BINDER: PASS"
  IO.println "PSC1_V2_DAG_BINDER: PASS"

private def applicationCheckParity : IO Unit := do
  let x := nm "app-x"
  let a := nm "app-a"
  let y := nm "app-y"
  let f := nm "app-f"
  let identity := PsKernelExpr.lam x sort1 (.bvar 0) .default
  let family := PsKernelExpr.lam a sort1
    (.lam x (.bvar 0) (.bvar 0) .default) .implicit
  let proposition := PsKernelExpr.forallE x sort0 (.bvar 0) .default
  let mut functionType := PsKernelExpr.forallE x sort1 sort1 .default
  for tag in [:8] do functionType := .mdata (tag + 800) functionType
  let fixtures : List (String × PsKernelExpr) := [
    ("identity", .app identity sort0),
    ("dependent", .app family sort0),
    ("dependent-second-argument", .app (.app family sort0) proposition),
    ("metadata-function", .app (.mdata 5 identity) sort0),
    ("under-local-binders", .lam a sort0
      (.lam x (.bvar 0)
        (.app (.lam y (.bvar 1) (.bvar 0) .default) (.bvar 0)) .default) .default),
    ("function-type-whnf", .lam f functionType (.app (.bvar 0) sort0) .default),
    ("function-type-whnf-under-binder", .lam f functionType
      (.lam x sort0 (.app (.bvar 1) sort0) .default) .default),
    ("invalid-function", .app sort0 sort0),
    ("invalid-argument", .app identity (.bvar 0))]
  for (label, term) in fixtures do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,2,3,4,8,10,11,12,16,32,64] do
      for maxDepth in [0,1,2] do
        let session ← fresh fuel maxDepth
        let checker := psKernelKernelSessionChecker session [] .safe
        for recDepth in [0,13,14,15,16] do
          let context := { checker.context with recDepth := recDepth }
          compareBinderRaw ("application-" ++ label)
            (psKernelSessionCheck fuel { checker with context := context } term)
            (binderRaw fuel context (psKernelExprV2CheckStateEmpty arena) root)
        require ("application-public-" ++ label)
          (sameCheck (psKernelV1CheckExpression session [] .safe term)
            (oneCheck session arena root))
  let universeOne := PsKernelLevel.succ .zero
  let duplicateUniverse := PsKernelExpr.sort (.max universeOne universeOne)
  let fallbacks : List (String × PsKernelExpr × Bool) := [
    ("universe-conversion",
      .app (.lam x duplicateUniverse (.bvar 0) .default) sort0, true),
    ("metadata-conversion",
      .app (.lam x (.mdata 900 sort1) (.bvar 0) .default) sort0, true),
    ("unequal-types", .app identity sort1, false)]
  for (label, term, acceptedExpected) in fallbacks do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,2,3,4,8,16,64] do
      let session ← fresh fuel 1
      let checker := psKernelKernelSessionChecker session [] .safe
      for recDepth in [0,15,16] do
        let context := { checker.context with recDepth := recDepth }
        match binderRaw fuel context (psKernelExprV2CheckStateEmpty arena) root with
        | none => pure ()
        | some result =>
            compareBinderRaw ("application-fallback-guard-" ++ label)
              (psKernelSessionCheck fuel { checker with context := context } term)
              (some result)
      require ("application-full-defeq-fallback-" ++ label)
        (sameCheck (psKernelV1CheckExpression session [] .safe term)
          (oneCheck session arena root))
    let session ← fresh 64 1
    let checker := psKernelKernelSessionChecker session [] .safe
    require ("application-explicit-defeq-fallback-" ++ label)
      (match binderRaw 64 checker.context (psKernelExprV2CheckStateEmpty arena) root with
       | none => true | _ => false)
    require ("application-defeq-result-" ++ label)
      ((match psKernelV1CheckExpression session [] .safe term with
        | .ok _ => true | .error _ => false) == acceptedExpected)
  let numeralArgument := PsKernelExpr.app identity (.lit (.nat 0))
  let (arena, root) ← expect (psKernelExprV2PagedImportChecked numeralArgument)
  for fuel in [0,1,2,3,4,8] do
    for limit in [0,7] do
      let initial ← fresh fuel 1
      let session := { initial with resources := { initial.resources with maxNatSize := limit } }
      let checker := psKernelKernelSessionChecker session [] .safe
      compareBinderRaw "application-nat-limit-before-type-comparison"
        (psKernelSessionCheck fuel checker numeralArgument)
        (binderRaw fuel checker.context (psKernelExprV2CheckStateEmpty arena) root)
      require "application-public-nat-limit-before-type-comparison"
        (sameCheck (psKernelV1CheckExpression session [] .safe numeralArgument)
          (oneCheck session arena root))
  let term := PsKernelExpr.app identity sort0
  let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
  let session ← fresh 64 1
  let checker := psKernelKernelSessionChecker session [] .safe
  let legacy ← expect (psKernelSessionCheck 64 checker term)
  let direct ←
    match binderRaw 64 checker.context (psKernelExprV2CheckStateEmpty arena) root with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_CHECK_APP_MISSING_DIRECT_RESULT")
  let entry ← expect (psKernelExprV2PagedRequire direct.fst.whnf.arena root)
  let cached ← expect (psKernelExprV2CheckedInferFind direct.fst root entry)
  require "application-ineligible-for-checked-cache"
    (match cached with | none => true | _ => false)
  for recDepth in [0,15,16] do
    let context := { checker.context with recDepth := recDepth }
    compareBinderRaw "application-cannot-skip-function-check-on-warm-result"
      (psKernelSessionCheck 1 { legacy.snd with context := context } term)
      (binderRaw 1 context direct.fst root)
  let env ← Lean.mkEmptyEnvironment
  let lx := Lean.Name.str .anonymous "app-x"
  let officialTerm := Lean.Expr.app
    (.lam lx (.sort (.succ .zero)) (.bvar 0) .default) (.sort .zero)
  let actual ← expectPublic (oneCheck session arena root)
  require "application-official-checked-identity"
    (match Lean.Kernel.check env {} officialTerm, checkReply actual with
     | .ok type, some checked =>
         Lean.Expr.equal type (.sort (.succ .zero)) &&
           psKernelExprEqual checked.type sort1
     | _, _ => false)
  IO.println "PSC1_V2_DAG_OFFICIAL_CHECK_APP: PASS"
  IO.println "PSC1_V2_DAG_CHECK_APP: PASS"


private def mutualDeclarationIndexParity : IO Unit := do
  let initial ← fresh
  let aName := nm "DagIndexMutualA"
  let bName := nm "DagIndexMutualB"
  let aCtor := PsKernelName.str aName "mk"
  let bCtor := PsKernelName.str bName "mk"
  let (arena, header) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty (.succ .zero))
  let (arena, a) ← expect (psKernelExprV2PagedMkConst arena aName [])
  let (arena, b) ← expect (psKernelExprV2PagedMkConst arena bName [])
  let (arena, ca) ← expect (psKernelExprV2PagedMkConst arena aCtor [])
  let (arena, cb) ← expect (psKernelExprV2PagedMkConst arena bCtor [])
  let first := PsKernelDagInductive.mk aName header [PsKernelDagConstructor.mk aCtor a]
  let second := PsKernelDagInductive.mk bName header [PsKernelDagConstructor.mk bCtor b]
  let group := PsKernelDagInductiveGroup.mk [] 0 [first, second] false
  let request := PsKernelDagDeclarationRequest.mutualInductive group
  let built ← expect (psKernelExprV2DecodeChecked arena)
  let emptyOwner := PsKernelDagExecutionState.mk initial []
  let admitted ← expectPublic (psKernelDagRunCommand emptyOwner [] .safe arena built (.admit request))
  let execution := admitted.snd
  require "mutual-index-exact-input-entry-count" (execution.declarations.length == 4)
  for declaration in execution.declarations do
    let info ← match psKernelEnvironmentFind execution.session.environment declaration.name with
      | some value => pure value
      | none => throw (IO.userError "missing admitted mutual constant")
    let originalType ← expect (psKernelExprV2DecodedRequire built declaration.type)
    require "mutual-index-source-correspondence"
      (psKernelExprV2DeclarationRefMatches declaration info && declaration.deltaValue.isNone &&
        psKernelExprEqual originalType (psKernelConstantInfoType info))
  let checker := psKernelKernelSessionChecker execution.session [] .safe
  for root in [a,b,ca,cb] do
    let term ← expect (psKernelExprV2DecodedRequire built root)
    for fuel in [0,1,2,8] do
      for recDepth in [0,15,16] do
        let context := { checker.context with
          maxRecDepth := 1
          recDepth := recDepth }
        let original := psKernelSessionCheck fuel { checker with context := context } term
        let originalType := match original with
          | .error error => Except.error error
          | .ok result => Except.ok result.fst
        constantTypeAttemptParity "mutual-index-direct-fuel-depth-parity" originalType
          (psKernelExprV2TryCheckWithDeclarationsFuel fuel context arena execution.declarations root)
  let recName := psKernelSimpleRecName aName
  let recInfo ← match psKernelEnvironmentFind execution.session.environment recName with
    | some value => pure value
    | none => throw (IO.userError "missing generated mutual recursor")
  let recLevels := (psKernelConstantInfoLevelParams recInfo).map (fun _ => PsKernelLevel.zero)
  let (withRec, recRoot) ← expect (psKernelExprV2PagedMkConst arena recName recLevels)
  require "mutual-index-generated-recursor-not-published"
    ((psKernelExprV2DeclarationRefFind execution.declarations recName).isNone)
  require "mutual-index-generated-recursor-explicit-fallback"
    ((psKernelExprV2TryCheckWithDeclarationsFuel 64 checker.context withRec
      execution.declarations recRoot).isNone)
  let publicResult ← expectPublic (psKernelV1RunDag initial [] .safe withRec
    [.admit request, .check a, .check ca, .check b, .check cb, .check recRoot])
  require "mutual-index-complete-public-checks" (publicResult.replies.length == 6)
  let malformedFirst := PsKernelDagInductive.mk aName header [PsKernelDagConstructor.mk aCtor b]
  let malformed := PsKernelDagDeclarationRequest.mutualInductive
    (PsKernelDagInductiveGroup.mk [] 0 [malformedFirst, second] false)
  require "mutual-index-failed-bundle-publishes-no-owner"
    (match psKernelDagRunCommand emptyOwner [] .safe arena built (.admit malformed) with
     | .error (.rejectedInvalid _) => emptyOwner.declarations.isEmpty
     | _ => false)
  require "mutual-index-nested-restoration-remains-unregistered"
    ((psKernelDagDeclarationsAfterAdmission (.nestedInductive group) []).isEmpty)
  let unsafeRequest := PsKernelDagDeclarationRequest.mutualInductive { group with isUnsafe := true }
  require "mutual-index-live-unsafe-constructor-rejection"
    (match psKernelV1RunDag initial [] .safe arena [.admit unsafeRequest, .check ca] with
     | .error (.rejectedInvalid _) => true | _ => false)
  let ordinary := PsKernelDagDeclarationRequest.ordinaryInductive [] 0 first false
  let ordinaryResult ← expectPublic
    (psKernelDagRunCommand emptyOwner [] .safe arena built (.admit ordinary))
  let ordinaryOwner := ordinaryResult.snd
  require "ordinary-index-exact-input-entry-count" (ordinaryOwner.declarations.length == 2)
  for declaration in ordinaryOwner.declarations do
    let info ← match psKernelEnvironmentFind ordinaryOwner.session.environment declaration.name with
      | some value => pure value
      | none => throw (IO.userError "missing admitted ordinary constant")
    let originalType ← expect (psKernelExprV2DecodedRequire built declaration.type)
    require "ordinary-index-source-correspondence"
      (psKernelExprV2DeclarationRefMatches declaration info && declaration.deltaValue.isNone &&
        psKernelExprEqual originalType (psKernelConstantInfoType info))
  let ordinaryChecker := psKernelKernelSessionChecker ordinaryOwner.session [] .safe
  for root in [a,ca] do
    let term ← expect (psKernelExprV2DecodedRequire built root)
    for fuel in [0,1,2,8] do
      for recDepth in [0,15,16] do
        let context := { ordinaryChecker.context with
          maxRecDepth := 1
          recDepth := recDepth }
        let original := psKernelSessionCheck fuel { ordinaryChecker with context := context } term
        let originalType := match original with
          | .error error => Except.error error
          | .ok result => Except.ok result.fst
        constantTypeAttemptParity "ordinary-index-direct-fuel-depth-parity" originalType
          (psKernelExprV2TryCheckWithDeclarationsFuel fuel context arena
            ordinaryOwner.declarations root)
  IO.println "PSC1_V2_DAG_NATIVE_MUTUAL_INDEX: PASS"


private def sameProjectionCheckedValue
    (left right : Except PsKernelError PsKernelCheckedExpression) : Bool :=
  match left, right with
  | .error a, .error b => samePublicError a b
  | .ok a, .ok b =>
      psKernelExprEqual a.expression b.expression && psKernelExprEqual a.type b.type
  | _, _ => false

private def projectionOfficialBinder : PsKernelBinderInfo → Lean.BinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

private def projectionOfficialExpr : PsKernelExpr → Option Lean.Expr
  | .bvar index => some (.bvar index)
  | .sort level => (quickOfficialLevel level).map Lean.Expr.sort
  | .const name levels => do
      return .const (quickOfficialName name) (← levels.mapM quickOfficialLevel)
  | .app fn arg => do
      return .app (← projectionOfficialExpr fn) (← projectionOfficialExpr arg)
  | .lam name domain body binderInfo => do
      return .lam (quickOfficialName name) (← projectionOfficialExpr domain)
        (← projectionOfficialExpr body) (projectionOfficialBinder binderInfo)
  | .forallE name domain body binderInfo => do
      return .forallE (quickOfficialName name) (← projectionOfficialExpr domain)
        (← projectionOfficialExpr body) (projectionOfficialBinder binderInfo)
  | .letE name type value body nondep => do
      return .letE (quickOfficialName name) (← projectionOfficialExpr type)
        (← projectionOfficialExpr value) (← projectionOfficialExpr body) nondep
  | .lit (.nat value) => some (.lit (.natVal value))
  | .lit (.str value) => some (.lit (.strVal value))
  | .mdata _ body => (projectionOfficialExpr body).map (Lean.Expr.mdata {})
  | .proj name index body => do
      return .proj (quickOfficialName name) index (← projectionOfficialExpr body)
  | _ => none

private def projectionOfficialRequire (term : PsKernelExpr) : IO Lean.Expr := do
  match projectionOfficialExpr term with
  | some expression => pure expression
  | none => throw (IO.userError "projection official converter does not cover fixture")

private def projectionCheckParity : IO Unit := do
  let initial ← fresh
  let a := nm "projection-A"
  let x := nm "projection-x"
  let p := nm "projection-P"
  let u := nm "projection-u"
  let pairName := nm "DagCheckDependentPair"
  let polyName := nm "DagCheckPolyBox"
  let dataPropName := nm "DagCheckDataProp"
  let proofName := nm "DagCheckProofBox"
  let pairCtor := PsKernelName.str pairName "mk"
  let polyCtor := PsKernelName.str polyName "mk"
  let dataPropCtor := PsKernelName.str dataPropName "mk"
  let proofCtor := PsKernelName.str proofName "mk"
  let levelOne := PsKernelLevel.succ .zero
  let levelU := PsKernelLevel.param u
  let pairType := PsKernelExpr.const pairName []
  let dataPropType := PsKernelExpr.const dataPropName []
  let dependentCtor := fun (result : PsKernelExpr) =>
    PsKernelExpr.forallE a sort1
      (.forallE x (.bvar 0) result .default) .default
  let polyType := PsKernelExpr.forallE a (.sort levelU) (.sort levelU) .default
  let polyCtorType := PsKernelExpr.forallE a (.sort levelU)
    (.forallE x (.bvar 0)
      (.app (.const polyName [levelU]) (.bvar 1)) .default) .default
  let proofType := PsKernelExpr.forallE p sort0 sort0 .default
  let proofCtorType := PsKernelExpr.forallE p sort0
    (.forallE x (.bvar 0)
      (.app (.const proofName []) (.bvar 1)) .default) .default
  let specifications : List
      (PsKernelName × List PsKernelName × PsKernelExpr × PsKernelExpr × Nat) := [
    (pairName, [], .sort (.succ levelOne), dependentCtor pairType, 0),
    (polyName, [u], polyType, polyCtorType, 1),
    (dataPropName, [], sort0, dependentCtor dataPropType, 0),
    (proofName, [], proofType, proofCtorType, 1)]
  let mut arena := psKernelExprV2PagedEmpty
  let mut requests : List PsKernelDagDeclarationRequest := []
  for (inductName, levels, type, ctorType, numParams) in specifications do
    let typeBuilt ← expect (psKernelExprV2PagedImportIntoChecked arena type)
    let ctorBuilt ← expect (psKernelExprV2PagedImportIntoChecked typeBuilt.fst ctorType)
    arena := ctorBuilt.fst
    requests := requests ++ [
      .ordinaryInductive levels numParams
        (PsKernelDagInductive.mk inductName typeBuilt.snd [
          PsKernelDagConstructor.mk (PsKernelName.str inductName "mk") ctorBuilt.snd])
        false]
  let tautology := PsKernelExpr.forallE p sort0
    (.forallE x (.bvar 0) (.bvar 1) .default) .default
  let tautologyProof := PsKernelExpr.lam p sort0
    (.lam x (.bvar 0) (.bvar 0) .default) .default
  let pairValue := PsKernelExpr.app (.app (.const pairCtor []) sort0) tautology
  let polyValue := PsKernelExpr.app
    (.app (.const polyCtor [levelOne]) sort0) tautology
  let dataPropValue := PsKernelExpr.app
    (.app (.const dataPropCtor []) sort0) tautology
  let proofValue := PsKernelExpr.app
    (.app (.const proofCtor []) tautology) tautologyProof
  let pairFirst := PsKernelExpr.proj pairName 0 pairValue
  let pairSecond := PsKernelExpr.proj pairName 1 pairValue
  let mut hiddenPair := pairValue
  for tag in [:8] do hiddenPair := .mdata (tag + 910) hiddenPair
  let fixtures : List (String × PsKernelExpr) := [
    ("dependent-first", pairFirst), ("dependent-second", pairSecond),
    ("parameter-and-universe", .proj polyName 0 polyValue),
    ("proof-field", .proj proofName 0 proofValue),
    ("proof-data-field", .proj dataPropName 0 dataPropValue),
    ("proof-dependent-data-field", .proj dataPropName 1 dataPropValue),
    ("metadata-value", .proj pairName 1 hiddenPair),
    ("under-binder", .lam x pairType (.proj pairName 1 (.bvar 0)) .default),
    ("wrong-type-name", .proj polyName 0 pairValue),
    ("invalid-index", .proj pairName 2 pairValue),
    ("large-index", .proj pairName 4294967296 pairValue),
    ("non-structure", .proj pairName 0 sort0),
    ("invalid-value-before-index", .proj pairName 4294967296 (.bvar 0))]
  let mut roots : List (String × Nat × PsKernelExpr) := []
  for (label, term) in fixtures do
    let result ← expect (psKernelExprV2PagedImportIntoChecked arena term)
    arena := result.fst
    roots := roots ++ [(label, result.snd, term)]
  let built ← expect (psKernelExprV2DecodeChecked arena)
  let mut execution := PsKernelDagExecutionState.mk initial []
  for request in requests do
    let result ← expectPublic
      (psKernelDagRunCommand execution [] .safe arena built (.admit request))
    execution := result.snd
  require "projection-index-original-input-types-only" (execution.declarations.length == 8)
  for declaration in execution.declarations do
    match psKernelEnvironmentFind execution.session.environment declaration.name with
    | none => throw (IO.userError "projection indexed declaration is missing")
    | some info =>
        let type ← expect (psKernelExprV2DecodedRequire built declaration.type)
        require "projection-index-type-correspondence"
          (psKernelExprV2DeclarationRefMatches declaration info &&
            psKernelExprEqual type (psKernelConstantInfoType info))
        require "projection-index-has-no-delta-body" declaration.deltaValue.isNone
  let checker := psKernelKernelSessionChecker execution.session [] .safe
  let stateFor := fun (graph : PsKernelExprV2PagedArena) =>
    psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty graph)
      (psKernelExprV2WhnfStateForDeclarations graph execution.declarations)
  for (label, root, term) in roots do
    for fuel in [0,1,2,3,4,5,6,8,10,12,16,32,64] do
      for maxDepth in [0,1,2] do
        for recDepth in [0,13,14,15,16] do
          let context := { checker.context with
            maxRecDepth := maxDepth
            recDepth := recDepth }
          compareBinderRaw ("projection-check-" ++ label ++ "-" ++ toString fuel)
            (psKernelSessionCheck fuel { checker with context := context } term)
            (binderRaw fuel context (stateFor arena) root)
        let resources := { execution.session.resources with
          fuel := fuel
          maxRecDepth := maxDepth }
        let session := { execution.session with resources := resources }
        let actual : Except PsKernelError PsKernelCheckedExpression :=
          match psKernelKernelSessionPreflight session with
          | .error error => .error error
          | .ok _ =>
              psKernelDagCheckExpression session [] .safe arena built
                execution.declarations root term
        require ("projection-public-fuel-" ++ label ++ "-" ++ toString fuel)
          (sameProjectionCheckedValue
            (psKernelV1CheckExpression session [] .safe term) actual)
    let original := psKernelV1CheckExpression execution.session [] .safe term
    let actual := psKernelV1RunDag initial [] .safe arena
      (requests.map PsKernelDagCommand.admit ++ [.check root])
    match original, actual with
    | .error left, .error right =>
        require ("projection-real-batch-negative-" ++ label) (samePublicError left right)
    | .ok left, .ok right =>
        match right.replies.reverse with
        | .checked checked :: _ =>
            require ("projection-real-batch-positive-" ++ label)
              (psKernelExprEqual left.type checked.type &&
                psKernelExprEqual left.expression checked.expression)
        | _ => throw (IO.userError "projection batch has no checked reply")
    | _, _ => throw (IO.userError ("projection batch mismatch: " ++ label))
  let (firstRoot, firstTerm) ←
    match roots with
    | (_, root, term) :: _ => pure (root, term)
    | [] => throw (IO.userError "missing projection fixture")
  let boundedContext := { checker.context with maxRecDepth := 1 }
  let legacyWarm ← expect
    (psKernelSessionCheck 64 { checker with context := boundedContext } firstTerm)
  let dagWarm ←
    match binderRaw 64 boundedContext (stateFor arena) firstRoot with
    | some value => expect value
    | none => throw (IO.userError "projection direct inference unexpectedly fell back")
  for (fuel, recDepth) in [(0,0),(1,0),(1,15),(1,16)] do
    let context := { boundedContext with recDepth := recDepth }
    compareBinderRaw "projection-warm-cache-entry-guards"
      (psKernelSessionCheck fuel { legacyWarm.snd with context := context } firstTerm)
      (binderRaw fuel context dagWarm.fst firstRoot)
  let secondType ← expect (psKernelSessionCheck 64 checker pairSecond)
  require "projection-dependent-result-keeps-earlier-projection"
    (psKernelExprEqual secondType.fst pairFirst)
  for (term, message) in [
      (PsKernelExpr.proj dataPropName 0 dataPropValue,
        "invalid projection: proof structure field is not a proposition"),
      (PsKernelExpr.proj dataPropName 1 dataPropValue,
        "invalid projection: proof structure depends on data field")] do
    require "projection-proof-structure-rejection"
      (match psKernelSessionCheck 64 checker term with
       | .error error => error == message | _ => false)
  require "projection-external-owner-remains-fallback"
    ((psKernelExprV2TryCheckWithFuel 64 checker.context arena firstRoot).isNone)
  let whnf := psKernelExprV2TryWhnfStateWithFuel 64
  let check := psKernelExprV2TryCheckCoreWithFuel 64 whnf
  let context := psKernelExprV2CheckContextEmpty checker.context
  require "projection-parameter-zero-budget"
    (match psKernelExprV2CheckProjectionApplyParamsWithFuel 0
        whnf context (stateFor arena) [] 0 0 firstRoot with
     | some (.error error) => error == "kernel projection parameter budget exhausted"
     | _ => false)
  require "projection-field-zero-budget"
    (match psKernelExprV2CheckProjectionSkipFieldsWithFuel 0
        check whnf context (stateFor arena) pairName firstRoot false 0 0 firstRoot with
     | some (.error error) => error == "kernel projection field budget exhausted"
     | _ => false)
  let sortBuilt ← expect (psKernelExprV2PagedMkSort arena .zero)
  require "projection-sort-does-not-skip-whnf-budget"
    (match psKernelExprV2CheckProjectionSortWith
        (psKernelExprV2TryWhnfStateWithFuel 0) context
        (stateFor sortBuilt.fst) sortBuilt.snd with
     | some (.error error) => error == "kernel reduction budget exhausted"
     | _ => false)
  let emptyOfficial ← Lean.mkEmptyEnvironment
  let mut official := emptyOfficial
  for (inductName, levels, type, ctorType, numParams) in specifications do
    let officialType ← projectionOfficialRequire type
    let officialCtor ← projectionOfficialRequire ctorType
    let declaration := Lean.Declaration.inductDecl
      (levels.map quickOfficialName) numParams
      [{ name := quickOfficialName inductName
         type := officialType
         ctors := [{ name := quickOfficialName (PsKernelName.str inductName "mk")
                     type := officialCtor }] }] false
    match official.addDeclCore 0 0 declaration none true with
    | .error _ =>
        throw (IO.userError
          ("official Lean rejected projection inductive " ++ toString (quickOfficialName inductName)))
    | .ok next => official := next
  for (label, root, term) in roots do
    let officialTerm ← projectionOfficialRequire term
    let independent := psKernelDagCheckExpression execution.session [] .safe arena built
      execution.declarations root term
    match Lean.Kernel.check official {} officialTerm, independent with
    | .error _, .error _ => pure ()
    | .ok expected, .ok checked =>
        let actual ← projectionOfficialRequire checked.type
        require ("projection-official-type-" ++ label) (Lean.Expr.equal expected actual)
    | _, _ => throw (IO.userError ("projection official outcome mismatch: " ++ label))
  IO.println "PSC1_V2_DAG_OFFICIAL_CHECK_PROJECTION: PASS"
  IO.println "PSC1_V2_DAG_CHECK_PROJECTION: PASS"

def main : IO Unit := do
  errorComparatorRegression
  nestedDiagnosticClassification
  constructorDecode
  semanticParity
  metadataParity
  zetaWhnfParity
  betaWhnfParity
  whnfFunctionStateParity
  whnfPublicCacheParity
  natProjectionWhnfParity
  structuralShortcutParity
  quickDefEqParity
  hostileInputs
  admissions
  deltaBatchParity
  mutualDeclarationIndexParity
  binderParity
  applicationCheckParity
  projectionCheckParity
  officialComparison
  IO.println "PSC1_V2_DAG_REGRESSION: PASS"
