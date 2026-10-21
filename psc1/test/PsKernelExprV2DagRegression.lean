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
  require "delta-only-successfully-admitted-definitions-registered"
    (execution.definitions.length == 7)
  require "delta-reference-is-original-canonical-body-id"
    (match psKernelExprV2DefinitionRefFind execution.definitions polyName with
     | some definition => definition.value == polyBody | none => false)
  require "delta-theorem-and-opaque-not-registered"
    ((psKernelExprV2DefinitionRefFind execution.definitions theoremName).isNone &&
      (psKernelExprV2DefinitionRefFind execution.definitions opaqueName).isNone)
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
            (psKernelExprV2WhnfStateForDefinitions arena execution.definitions) root)
        let policySession := { execution.session with resources :=
          { execution.session.resources with fuel := fuel, maxRecDepth := depth } }
        require "delta-public-exact-fuel-depth-parity"
          (sameWhnfValue
            (psKernelV1Whnf policySession [] .unsafeDef term)
            (psKernelDagWhnfExpression policySession [] .unsafeDef arena built
              execution.definitions root term))
    for recDepth in [15,16] do
      let context := { checker.context with maxRecDepth := 1, recDepth := recDepth }
      rawStateWhnfParity "delta-exact-entry-recursion-boundary"
        (psKernelSessionWhnf 64 { checker with context := context } term)
        (psKernelExprV2TryWhnfStateWithFuel 64 context
          (psKernelExprV2WhnfStateForDefinitions arena execution.definitions) root)
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
        (psKernelExprV2WhnfStateForDefinitions arena execution.definitions) wrongArity)
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
        (psKernelExprV2WhnfStateForDefinitions arena execution.definitions) ca)
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
  require "delta-external-session-definitions-explicitly-fallback"
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
  let invalidRef := { aliasDef with base := { aliasDef.base with name := badName },
    value := arena.size }
  let illTyped := { aliasDef with base := { aliasDef.base with name := badName },
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
    (emptyExecution.definitions.isEmpty &&
      (psKernelEnvironmentFind initial.environment badName).isNone)
  let changedDuplicate := { aliasDef with value := s1 }
  require "delta-duplicate-cannot-replace-admitted-reference"
    (match psKernelDagRunCommand execution [] .safe arena built
       (.admit (.definitionDecl changedDuplicate)) with
     | .error (.rejectedInvalid _) =>
         match psKernelExprV2DefinitionRefFind execution.definitions aliasName with
         | some definition => definition.value == s0 | none => false
     | _ => false)
  let bounded := { firstAdmission.snd with session :=
    { firstAdmission.snd.session with resources :=
      { firstAdmission.snd.session.resources with maxDeclarations := 1 } } }
  require "delta-limit-failure-publishes-no-definition-reference"
    (match psKernelDagRunCommand bounded [] .safe arena built
       (.admit (.definitionDecl polyDef)) with
     | .error (.resourceExhausted .declarationLimit _) =>
         bounded.definitions.length == 1 &&
           (psKernelExprV2DefinitionRefFind bounded.definitions polyName).isNone
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
  for prefix in prefixes do
    let invalid := prefix ++ "invalid projection: structure type mismatch"
    require "nested-diagnostic-exact-invalid-with-original-message"
      (samePublicError (psKernelErrorFromMessage invalid) (.rejectedInvalid invalid))
    let unsupported := prefix ++ "nested or invalid mutual inductive occurrence is not supported"
    require "nested-diagnostic-exact-unsupported-with-original-message"
      (samePublicError (psKernelErrorFromMessage unsupported) (.declinedUnsupported unsupported))
    for (body, resource) in resources do
      let message := prefix ++ body
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
  officialComparison
  IO.println "PSC1_V2_DAG_REGRESSION: PASS"
