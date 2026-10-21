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
  psKernelExprV2TryCheckStateWithFuel fuel
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
  let letTerm := PsKernelExpr.letE x sort1 sort0 (.bvar 0) false
  let (letArena, letRoot) ← expect (psKernelExprV2PagedImportChecked letTerm)
  compareBinderRaw "binder-let-now-direct"
    (psKernelSessionCheck 64 checker letTerm)
    (binderRaw 64 checker.context (psKernelExprV2CheckStateEmpty letArena) letRoot)
  require "binder-let-public-parity"
    (sameCheck (psKernelV1CheckExpression session [] .safe letTerm)
      (oneCheck session letArena letRoot))
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
  let fallbacks : List (String × PsKernelExpr × Bool) := [
    ("metadata-conversion",
      .app (.lam x (.mdata 900 sort1) (.bvar 0) .default) sort0, true)]
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
  | .fvar name => some (.fvar (Lean.FVarId.mk (quickOfficialName name)))
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
  let whnf := psKernelExprV2CheckWhnfWithFuel 64
  let check := psKernelExprV2TryCheckStateWithFuel 64
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
        (psKernelExprV2CheckWhnfWithFuel 0) context
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

private def letRaw
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :=
  psKernelExprV2TryCheckStateWithFuel fuel context state root

private def compareLetDefEq (label : String)
    (legacy : Except String (Prod Bool PsKernelCheckerSession))
    (attempted : Option (Except String (Prod PsKernelExprV2CheckState Bool))) : IO Unit := do
  match legacy, attempted with
  | .error left, some (.error right) => require (label ++ "-error") (left == right)
  | .ok left, some (.ok right) => require (label ++ "-value") (left.fst == right.snd)
  | _, _ => throw (IO.userError ("PSC1_V2_LET_DEFEQ_MISSING_RESULT " ++ label))

private def checkedLetParity : IO Unit := do
  let x := nm "let-x"
  let a := nm "let-a"
  let f := nm "let-f"
  let y := nm "let-y"
  let sort2 := PsKernelExpr.sort (.succ (.succ .zero))
  let one := PsKernelLevel.succ .zero
  let duplicateOne := PsKernelExpr.sort (.max one one)
  let functionType := PsKernelExpr.forallE x sort1 sort1 .default
  let mut hiddenFunctionType := functionType
  for tag in [:8] do hiddenFunctionType := .mdata (tag + 9100) hiddenFunctionType
  let fixtures : List (String × PsKernelExpr) := [
    ("unused", .letE a sort1 sort0 sort1 false),
    ("body-local", .letE a sort1 sort0 (.bvar 0) false),
    ("nondep-hint", .letE a sort1 sort0 sort1 true),
    ("dependent-result", .letE a sort1 sort0
      (.lam x (.bvar 0) (.bvar 0) .default) false),
    ("sort-local-value", .letE a sort2 sort1
      (.forallE x (.bvar 0) (.forallE y (.bvar 0) (.bvar 1) .default) .default) false),
    ("function-local-value", .letE a sort2 functionType
      (.lam f (.bvar 0) (.app (.bvar 0) sort0) .default) false),
    ("function-local-value-metadata", .letE a sort2 hiddenFunctionType
      (.lam f (.bvar 0) (.app (.bvar 0) sort0) .default) false),
    ("nested-same-name", .letE a sort1 sort0
      (.letE a sort1 (.bvar 0) (.bvar 0) false) false),
    ("inside-lambda", .lam x sort1
      (.letE y sort1 (.bvar 0) (.bvar 0) false) .default),
    ("sort-conversion", .letE a duplicateOne sort0 (.bvar 0) false),
    ("metadata-body", .letE a sort1 sort0 (.mdata 3 (.bvar 0)) false),
    ("bad-value-type", .letE a sort1 sort1 (.bvar 0) false),
    ("bad-declared-type", .letE a (.lam x sort1 (.bvar 0) .default)
      sort0 (.bvar 0) false),
    ("loose-value", .letE a sort1 (.bvar 0) (.bvar 0) false),
    ("unknown-body", .letE a sort1 sort0 (.fvar (nm "let-outside")) false),
    ("bad-body-app", .letE a sort1 sort0 (.app sort0 sort0) false)]
  let officialEnv ← Lean.mkEmptyEnvironment
  for (label, term) in fixtures do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,2,3,4,8,9,10,11,12,16,32,64] do
      for maxDepth in [0,1,2] do
        let session ← fresh fuel maxDepth
        let checker := psKernelKernelSessionChecker session [] .safe
        for recDepth in [0,13,14,15,16] do
          let context := { checker.context with recDepth := recDepth }
          compareBinderRaw ("let-" ++ label)
            (psKernelSessionCheck fuel { checker with context := context } term)
            (letRaw fuel (psKernelExprV2CheckContextEmpty context)
              (psKernelExprV2CheckStateEmpty arena) root)
        require ("let-public-" ++ label)
          (sameCheck (psKernelV1CheckExpression session [] .safe term)
            (oneCheck session arena root))
    let session ← fresh 64
    let independent := oneCheck session arena root
    let some officialTerm := projectionOfficialExpr term
      | throw (IO.userError ("let-official-conversion-" ++ label))
    match Lean.Kernel.check officialEnv {} officialTerm, independent with
    | .error _, .error _ => pure ()
    | .ok officialType, .ok batch =>
        let some checked := checkReply batch
          | throw (IO.userError ("let-official-missing-reply-" ++ label))
        let some convertedType := projectionOfficialExpr checked.type
          | throw (IO.userError ("let-official-type-conversion-" ++ label))
        require ("let-official-type-" ++ label)
          (match Lean.Kernel.isDefEq officialEnv {} officialType convertedType with
           | .ok equal => equal | .error _ => false)
    | _, _ => throw (IO.userError ("PSC1_V2_LET_OFFICIAL_MISMATCH " ++ label))
  let literalBody := PsKernelExpr.letE a sort1 sort0 (.lit (.nat 65521)) false
  let (arena, root) ← expect (psKernelExprV2PagedImportChecked literalBody)
  for fuel in [0,1,2,3,8] do
    for limit in [0,7,8,16] do
      let initial ← fresh fuel
      let session := { initial with resources := { initial.resources with maxNatSize := limit } }
      let checker := psKernelKernelSessionChecker session [] .safe
      compareBinderRaw "let-numeral-resource-order"
        (psKernelSessionCheck fuel checker literalBody)
        (letRaw fuel (psKernelExprV2CheckContextEmpty checker.context)
          (psKernelExprV2CheckStateEmpty arena) root)
      require "let-numeral-public-resource-order"
        (sameCheck (psKernelV1CheckExpression session [] .safe literalBody)
          (oneCheck session arena root))
  let term := PsKernelExpr.letE a sort1 sort0 (.bvar 0) false
  let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
  let session ← fresh 64 1
  let checker := psKernelKernelSessionChecker session [] .safe
  let legacy ← expect (psKernelSessionCheck 64 checker term)
  let direct ←
    match letRaw 64 (psKernelExprV2CheckContextEmpty checker.context)
        (psKernelExprV2CheckStateEmpty arena) root with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_LET_WARM_FALLBACK")
  for (fuel, recDepth) in [(0,0),(1,0),(1,15),(1,16)] do
    let context := { checker.context with recDepth := recDepth }
    compareBinderRaw "let-warm-inference-entry-guards"
      (psKernelSessionCheck fuel { legacy.snd with context := context } term)
      (letRaw fuel (psKernelExprV2CheckContextEmpty context) direct.fst root)
  let escaped := PsKernelName.num a 0
  let (arena, escapedId) ← expect (psKernelExprV2PagedMkFVar direct.fst.whnf.arena escaped)
  compareBinderRaw "let-local-value-does-not-escape"
    (psKernelSessionCheck 64 legacy.snd (.fvar escaped))
    (letRaw 64 (psKernelExprV2CheckContextEmpty checker.context)
      (psKernelExprV2CheckStateWithArena direct.fst arena) escapedId)
  IO.println "PSC1_V2_DAG_CHECK_LET: PASS"
  IO.println "PSC1_V2_DAG_OFFICIAL_CHECK_LET: PASS"

private def checkedLetCacheScope : IO Unit := do
  let x := nm "let-cache-x"
  let w := nm "let-cache-w"
  let a := nm "let-cache-a"
  let b := nm "let-cache-b"
  let one := PsKernelLevel.succ .zero
  let two := PsKernelLevel.succ one
  let mut outerLeft := PsKernelExpr.sort one
  let mut outerRight := PsKernelExpr.sort (.max one one)
  let mut innerLeft := PsKernelExpr.sort two
  let mut innerRight := PsKernelExpr.sort (.max two two)
  for tag in [:8] do
    outerLeft := .mdata (9200 + tag) outerLeft
    outerRight := .mdata (9300 + tag) outerRight
    innerLeft := .mdata (9400 + tag) innerLeft
    innerRight := .mdata (9500 + tag) innerRight
  let term := PsKernelExpr.letE a outerRight (.fvar x)
    (.letE b innerRight (.fvar w) sort0 false) false
  let (a0, outerLeftId) ← expect (psKernelExprV2PagedImportChecked outerLeft)
  let (a1, outerRightId) ← expect (psKernelExprV2PagedImportIntoChecked a0 outerRight)
  let (a2, innerLeftId) ← expect (psKernelExprV2PagedImportIntoChecked a1 innerLeft)
  let (a3, innerRightId) ← expect (psKernelExprV2PagedImportIntoChecked a2 innerRight)
  let (arena, root) ← expect (psKernelExprV2PagedImportIntoChecked a3 term)
  let initial ← fresh 64 1
  let base := psKernelKernelSessionChecker initial [] .safe
  let old1 := psKernelLocalContextAddLocal base.context.localContext x x outerLeft .default
  let old2 := psKernelLocalContextAddLocal old1 w w innerLeft .default
  let oldContext := psKernelCheckerContextWithLocalContext base.context old2
  let typed1 := psKernelExprV2CheckContextWithLocal
    (psKernelExprV2CheckContextEmpty base.context) x x outerLeftId .default
  let typed2 := psKernelExprV2CheckContextWithLocal typed1 w w innerLeftId .default
  let legacy ← expect (psKernelSessionCheck 64 { base with context := oldContext } term)
  let direct ←
    match letRaw 64 typed2 (psKernelExprV2CheckStateEmpty arena) root with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_LET_CACHE_SCOPE_FALLBACK")
  require "let-nested-scopes-preserve-monotone-fresh"
    (legacy.snd.state.nextFresh == 2 && direct.fst.nextFresh == 2)
  for (fuel, recDepth) in [(0,0),(1,0),(1,15),(1,16)] do
    let old := { oldContext with recDepth := recDepth }
    let typed := { typed2 with scalar := { base.context with recDepth := recDepth } }
    compareLetDefEq "let-parent-success-pair-entry-guards"
      (psKernelSessionIsDefEq fuel { legacy.snd with context := old } outerLeft outerRight)
      (psKernelExprV2TryDefEqStateWithFuel fuel typed direct.fst outerLeftId outerRightId)
  require "let-parent-comparison-survives-scope"
    (match psKernelExprV2TryDefEqStateWithFuel 1 typed2 direct.fst outerLeftId outerRightId with
     | some (.ok result) => result.snd | _ => false)
  compareLetDefEq "let-parent-cold-comparison-needs-recursion"
    (psKernelSessionIsDefEq 1 { base with context := oldContext } outerLeft outerRight)
    (psKernelExprV2TryDefEqStateWithFuel 1 typed2
      (psKernelExprV2CheckStateEmpty arena) outerLeftId outerRightId)
  require "let-parent-cold-comparison-is-not-syntax"
    (match psKernelExprV2TryDefEqStateWithFuel 1 typed2
        (psKernelExprV2CheckStateEmpty arena) outerLeftId outerRightId with
     | some (.error error) => error == "kernel definitional equality budget exhausted"
     | _ => false)
  compareLetDefEq "let-child-success-pair-restored-away"
    (psKernelSessionIsDefEq 1 legacy.snd innerLeft innerRight)
    (psKernelExprV2TryDefEqStateWithFuel 1 typed2 direct.fst innerLeftId innerRightId)
  require "let-child-comparison-cannot-authorize-parent"
    (match psKernelExprV2TryDefEqStateWithFuel 1 typed2 direct.fst innerLeftId innerRightId with
     | some (.error error) => error == "kernel definitional equality budget exhausted"
     | _ => false)
  IO.println "PSC1_V2_DAG_LET_CACHE_SCOPE: PASS"

private def checkedLocalValueWhnfParity : IO Unit := do
  let x := nm "let-whnf-x"
  let y := nm "let-whnf-y"
  let f := nm "let-whnf-f"
  let identity := PsKernelExpr.lam (nm "let-whnf-arg") sort1 (.bvar 0) .default
  let identityType := PsKernelExpr.forallE (nm "let-whnf-arg") sort1 sort1 .default
  let (a0, sort0Id) ← expect (psKernelExprV2PagedImportChecked sort0)
  let (a1, sort1Id) ← expect (psKernelExprV2PagedImportIntoChecked a0 sort1)
  let (a2, xId) ← expect (psKernelExprV2PagedMkFVar a1 x)
  let (a3, identityId) ← expect (psKernelExprV2PagedImportIntoChecked a2 identity)
  let (arena, identityTypeId) ← expect (psKernelExprV2PagedImportIntoChecked a3 identityType)
  let session ← fresh 64 1
  let base := psKernelKernelSessionChecker session [] .safe
  let old1 := psKernelLocalContextAddLet base.context.localContext x x sort1 sort0
  let old2 := psKernelLocalContextAddLet old1 y y sort1 (.fvar x)
  let old3 := psKernelLocalContextAddLet old2 f f identityType identity
  let typed1 := psKernelExprV2CheckContextWithLet
    (psKernelExprV2CheckContextEmpty base.context) x x sort1Id sort0Id
  let typed2 := psKernelExprV2CheckContextWithLet typed1 y y sort1Id xId
  let typed3 := psKernelExprV2CheckContextWithLet typed2 f f identityTypeId identityId
  let shadowOld := psKernelLocalContextAddLocal old3 x x sort1 .default
  let shadowTyped := psKernelExprV2CheckContextWithLocal typed3 x x sort1Id .default
  let mut metadataAlias := PsKernelExpr.fvar y
  for tag in [:8] do metadataAlias := .mdata tag metadataAlias
  let cases := [
    ("one-local", PsKernelExpr.fvar x, old3, typed3),
    ("alias-chain", PsKernelExpr.fvar y, old3, typed3),
    ("metadata-chain", metadataAlias, old3, typed3),
    ("local-function", PsKernelExpr.app (.fvar f) sort0, old3, typed3),
    ("value-free-shadow", PsKernelExpr.fvar x, shadowOld, shadowTyped)]
  for (label, term, oldLocals, typed) in cases do
    let (nextArena, root) ← expect (psKernelExprV2PagedImportIntoChecked arena term)
    for maxDepth in [0,1,2] do
      for recDepth in [0,13,14,15,16] do
        let oldContext := psKernelCheckerContextWithLocalContext
          { base.context with maxRecDepth := maxDepth, recDepth := recDepth } oldLocals
        let newContext := { typed with scalar :=
          { base.context with maxRecDepth := maxDepth, recDepth := recDepth } }
        for fuel in [0,1,2,3,4,8,10,11,12,16,64] do
          let localValue := fun name => psKernelExprV2CheckLocalValue newContext name
          let publicWhnf := fun context state expr =>
            psKernelExprV2TryWhnfStateWithLocalValuesFuel fuel localValue
              context state expr
          rawStateWhnfParity ("let-local-public-" ++ label)
            (psKernelSessionWhnf fuel { base with context := oldContext } term)
            (psKernelExprV2CheckWhnfWithFuel fuel newContext
              (psKernelExprV2WhnfStateEmpty nextArena) root)
          rawStateWhnfParity ("let-local-core-" ++ label)
            (psKernelWhnfCoreWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel)
              oldContext base.state term false false)
            (psKernelExprV2TryWhnfCoreWithLocalValuesFuel fuel localValue publicWhnf
              newContext.scalar (psKernelExprV2WhnfStateEmpty nextArena) root)
  require "let-local-public-predecessor-core-budget"
    (match psKernelExprV2CheckWhnfWithFuel 2 typed3
        (psKernelExprV2WhnfStateEmpty arena) xId with
     | some (.error error) => error == "kernel reduction budget exhausted"
     | _ => false)
  rawStateWhnfParity "let-local-public-budget-three"
    (psKernelSessionWhnf 3
      { base with context := psKernelCheckerContextWithLocalContext base.context old3 }
      (.fvar x))
    (psKernelExprV2CheckWhnfWithFuel 3 typed3
      (psKernelExprV2WhnfStateEmpty arena) xId)
  let mixed := { shadowTyped with scalar :=
    psKernelCheckerContextWithLocalContext base.context old3 }
  require "let-local-mixed-representations-request-fallback"
    (match psKernelExprV2CheckWhnfWithFuel 64 mixed
        (psKernelExprV2WhnfStateEmpty arena) xId with
     | none => true | _ => false)
  let (badArena, badBody) ← expect (psKernelExprV2PagedMkBVar arena 1)
  let state := psKernelExprV2CheckStateEmpty badArena
  let opened := PsKernelExprV2OpenedCheckBinder.mk
    (psKernelExprV2CheckContextEmpty base.context) state x badBody
  require "let-close-range-is-not-exact-index-occurrence"
    (!(psKernelExprHasLooseBVarAt (.bvar 1) 0))
  require "let-close-unproved-loose-context-requests-fallback"
    (match psKernelExprV2CheckCloseLet opened state badBody badBody
        y sort1Id sort0Id false with
     | none => true | _ => false)
  IO.println "PSC1_V2_DAG_LET_LOCAL_WHNF: PASS"

private def statefulDefEqPairParity : IO Unit := do
  let one := PsKernelLevel.succ .zero
  let equivalent := PsKernelExpr.sort (.max one one)
  let left := PsKernelExpr.mdata 0 sort1
  let right := PsKernelExpr.mdata 1 equivalent
  let collision := PsKernelExpr.mdata 65521 sort1
  let localExpr := PsKernelExpr.fvar (nm "pair-local")
  let (a0, leftId) ← expect (psKernelExprV2PagedImportChecked left)
  let (a1, rightId) ← expect (psKernelExprV2PagedImportIntoChecked a0 right)
  let (a2, collisionId) ← expect (psKernelExprV2PagedImportIntoChecked a1 collision)
  let (a3, copyLeft) ← expect (psKernelExprV2PagedImportIntoChecked a2 left)
  let (a4, copyRight) ← expect (psKernelExprV2PagedImportIntoChecked a3 right)
  let (arena, localId) ← expect (psKernelExprV2PagedImportIntoChecked a4 localExpr)
  let session ← fresh 64 1
  let checker := psKernelKernelSessionChecker session [] .safe
  let context := psKernelExprV2CheckContextEmpty checker.context
  let emptyState := psKernelExprV2CheckStateEmpty arena
  let legacy ← expect (psKernelSessionIsDefEq 64 checker left right)
  let direct ←
    match psKernelExprV2TryDefEqStateWithFuel 64 context emptyState leftId rightId with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_PAIR_PRIMING_FALLBACK")
  require "pair-prime-true" (legacy.fst && direct.snd)
  require "pair-prime-publishes-child-and-parent" (direct.fst.success.length == 2)
  require "pair-copy-uses-distinct-identifiers" (leftId != copyLeft && rightId != copyRight)
  for (label, l, r, lid, rid) in [
      ("forward", left, right, leftId, rightId),
      ("reverse", right, left, rightId, leftId),
      ("structural-copy", left, right, copyLeft, copyRight)] do
    for fuel in [0,1,2] do
      for recDepth in [0,15,16] do
        let scalar := { checker.context with recDepth := recDepth }
        compareLetDefEq ("pair-warm-" ++ label)
          (psKernelSessionIsDefEq fuel { legacy.snd with context := scalar } l r)
          (psKernelExprV2TryDefEqStateWithFuel fuel
            (psKernelExprV2CheckContextEmpty scalar) direct.fst lid rid)
  let duplicate ← expect
    (psKernelExprV2CheckStateDefEqFinish direct.fst copyRight copyLeft true)
  require "pair-success-set-does-not-grow-on-duplicate"
    (duplicate.snd && duplicate.fst.success.length == direct.fst.success.length)
  let untouched ← expect
    (psKernelExprV2CheckStateDefEqFinish direct.fst leftId rightId false)
  require "pair-false-does-not-publish"
    (!untouched.snd && untouched.fst.success.length == direct.fst.success.length)
  let leftEntry ← expect (psKernelExprV2PagedRequire arena leftId)
  let collisionEntry ← expect (psKernelExprV2PagedRequire arena collisionId)
  require "pair-real-hash-collision"
    (leftEntry.hash == collisionEntry.hash &&
      psKernelExprHash left == psKernelExprHash collision && !(psKernelExprEq left collision))
  let missed ← expect
    (psKernelExprV2DefEqPairContains arena direct.fst.success collisionId rightId)
  require "pair-hash-collision-cannot-authorize-hit" (!missed)
  compareLetDefEq "pair-hash-collision-low-fuel"
    (psKernelSessionIsDefEq 1 legacy.snd collision right)
    (psKernelExprV2TryDefEqStateWithFuel 1 context direct.fst collisionId rightId)
  require "pair-collision-retains-child-fuel-error"
    (match psKernelExprV2TryDefEqStateWithFuel 1 context direct.fst collisionId rightId with
     | some (.error error) => error == "kernel definitional equality budget exhausted"
     | _ => false)
  compareLetDefEq "pair-fresh-owner-has-no-warm-receipt"
    (psKernelSessionIsDefEq 1 checker left right)
    (psKernelExprV2TryDefEqStateWithFuel 1 context emptyState leftId rightId)
  let localResult ←
    match psKernelExprV2TryDefEqStateWithFuel 1 context emptyState localId localId with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_PAIR_LOCAL_SYNTAX_FALLBACK")
  require "pair-free-variable-syntax-does-not-publish"
    (localResult.snd && localResult.fst.success.length == 0)
  let localCached ← expect
    (psKernelExprV2DefEqPairContains arena localResult.fst.success localId localId)
  require "pair-free-variable-is-not-semantic-key" (!localCached)
  require "pair-invalid-query-id-is-rejected"
    (match psKernelExprV2DefEqPairContains arena direct.fst.success arena.size rightId with
     | .error _ => true | _ => false)
  for (label, l, r) in [
      ("sort-false", sort0, sort1),
      ("literal-false", PsKernelExpr.lit (.nat 7), PsKernelExpr.lit (.nat 8)),
      ("string-false", PsKernelExpr.lit (.str "a"), PsKernelExpr.lit (.str "b"))] do
    let (a0, lid) ← expect (psKernelExprV2PagedImportChecked l)
    let (graph, rid) ← expect (psKernelExprV2PagedImportIntoChecked a0 r)
    for fuel in [0,1,2,8] do
      for recDepth in [0,15,16] do
        let scalar := { checker.context with recDepth := recDepth }
        compareLetDefEq ("pair-" ++ label)
          (psKernelSessionIsDefEq fuel { checker with context := scalar } l r)
          (psKernelExprV2TryDefEqStateWithFuel fuel
            (psKernelExprV2CheckContextEmpty scalar)
            (psKernelExprV2CheckStateEmpty graph) lid rid)
    require ("pair-negative-does-not-publish-" ++ label)
      (match psKernelExprV2TryDefEqStateWithFuel 8 context
          (psKernelExprV2CheckStateEmpty graph) lid rid with
       | some (.ok result) => !result.snd && result.fst.success.length == 0
       | _ => false)
  let secondLegacy ← expect (psKernelSessionIsDefEq 64 legacy.snd right collision)
  let secondDirect ←
    match psKernelExprV2TryDefEqStateWithFuel 64 context direct.fst rightId collisionId with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_PAIR_SECOND_PRIMING_FALLBACK")
  let transitiveHit ← expect
    (psKernelExprV2DefEqPairContains arena secondDirect.fst.success leftId collisionId)
  require "pair-no-transitive-closure" (secondLegacy.fst && secondDirect.snd && !transitiveHit)
  compareLetDefEq "pair-transitivity-keeps-fuel-error"
    (psKernelSessionIsDefEq 1 secondLegacy.snd left collision)
    (psKernelExprV2TryDefEqStateWithFuel 1 context secondDirect.fst leftId collisionId)
  IO.println "PSC1_V2_DAG_STATEFUL_DEFEQ: PASS"


private def applicationConversionParity : IO Unit := do
  let x := nm "app-convert-x"
  let f := nm "app-convert-f"
  let one := PsKernelLevel.succ .zero
  let duplicate := PsKernelExpr.sort (.max one one)
  let leftType := PsKernelExpr.mdata 610 sort1
  let rightType := PsKernelExpr.mdata 611 duplicate
  let functionType := PsKernelExpr.forallE x rightType sort1 .default
  let fixtures : List (String × PsKernelExpr × Bool) := [
    ("sort-equivalent", .app (.lam x duplicate (.bvar 0) .default) sort0, true),
    ("sort-different", .app (.lam x sort1 (.bvar 0) .default) sort1, false),
    ("paired-metadata", .lam f functionType
      (.lam x leftType (.app (.bvar 1) (.bvar 0)) .default) .default, true),
    ("paired-metadata-different", .lam f functionType
      (.lam x (.mdata 610 (.sort (.succ one)))
        (.app (.bvar 1) (.bvar 0)) .default) .default, false)]
  let officialEnv ← Lean.mkEmptyEnvironment
  for (label, term, acceptedExpected) in fixtures do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    for fuel in [0,1,2,3,4,8,10,11,12,16,32,64] do
      for maxDepth in [0,1,2] do
        let session ← fresh fuel maxDepth
        let checker := psKernelKernelSessionChecker session [] .safe
        for recDepth in [0,13,14,15,16] do
          let context := { checker.context with recDepth := recDepth }
          compareBinderRaw ("application-conversion-" ++ label)
            (psKernelSessionCheck fuel { checker with context := context } term)
            (binderRaw fuel context (psKernelExprV2CheckStateEmpty arena) root)
        require ("application-conversion-public-" ++ label)
          (sameCheck (psKernelV1CheckExpression session [] .safe term)
            (oneCheck session arena root))
    let session ← fresh 64
    let independent := oneCheck session arena root
    require ("application-conversion-result-" ++ label)
      ((match independent with | .ok _ => true | .error _ => false) == acceptedExpected)
    let officialTerm ← projectionOfficialRequire term
    match Lean.Kernel.check officialEnv {} officialTerm, independent with
    | .error _, .error _ => pure ()
    | .ok officialType, .ok batch =>
        let some checked := checkReply batch
          | throw (IO.userError ("application-conversion-official-reply-" ++ label))
        let convertedType ← projectionOfficialRequire checked.type
        require ("application-conversion-official-type-" ++ label)
          (match Lean.Kernel.isDefEq officialEnv {} officialType convertedType with
           | .ok equal => equal | .error _ => false)
    | _, _ => throw (IO.userError ("PSC1_V2_APP_CONVERSION_OFFICIAL_MISMATCH " ++ label))
  IO.println "PSC1_V2_DAG_APP_CONVERSION: PASS"
  IO.println "PSC1_V2_DAG_OFFICIAL_APP_CONVERSION: PASS"

private def applicationConversionCacheParity : IO Unit := do
  let x := nm "app-cache-x"
  let f := nm "app-cache-f"
  let a := nm "app-cache-let"
  let one := PsKernelLevel.succ .zero
  let mut leftType := PsKernelExpr.sort one
  let mut rightType := PsKernelExpr.sort (.max one one)
  for tag in [:8] do
    leftType := .mdata (10100 + tag) leftType
    rightType := .mdata (10200 + tag) rightType
  let functionType := PsKernelExpr.forallE (nm "app-cache-domain") rightType sort1 .default
  let prime := PsKernelExpr.letE a rightType (.fvar x) sort0 false
  let term := PsKernelExpr.app (.fvar f) (.fvar x)
  let (a0, leftId) ← expect (psKernelExprV2PagedImportChecked leftType)
  let (a1, rightId) ← expect (psKernelExprV2PagedImportIntoChecked a0 rightType)
  let (a2, functionId) ← expect (psKernelExprV2PagedImportIntoChecked a1 functionType)
  let (a3, primeId) ← expect (psKernelExprV2PagedImportIntoChecked a2 prime)
  let (arena, root) ← expect (psKernelExprV2PagedImportIntoChecked a3 term)
  let session ← fresh 64 1
  let checker := psKernelKernelSessionChecker session [] .safe
  let old1 := psKernelLocalContextAddLocal checker.context.localContext x x leftType .default
  let old2 := psKernelLocalContextAddLocal old1 f f functionType .default
  let oldContext := psKernelCheckerContextWithLocalContext checker.context old2
  let typed1 := psKernelExprV2CheckContextWithLocal
    (psKernelExprV2CheckContextEmpty checker.context) x x leftId .default
  let typedContext := psKernelExprV2CheckContextWithLocal typed1 f f functionId .default
  let legacy ← expect (psKernelSessionCheck 64 { checker with context := oldContext } prime)
  let direct ←
    match psKernelExprV2TryCheckStateWithFuel 64 typedContext
        (psKernelExprV2CheckStateEmpty arena) primeId with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_APP_CACHE_PRIMING_FALLBACK")
  let hit ← expect
    (psKernelExprV2DefEqPairContains direct.fst.whnf.arena direct.fst.success leftId rightId)
  require "application-let-primes-own-success-pair" hit
  for fuel in [0,1,2,3,8,64] do
    for recDepth in [0,13,14,15,16] do
      let old := { oldContext with recDepth := recDepth }
      let typed := { typedContext with scalar := { checker.context with recDepth := recDepth } }
      compareBinderRaw "application-warm-conversion-entry"
        (psKernelSessionCheck fuel { legacy.snd with context := old } term)
        (psKernelExprV2TryCheckStateWithFuel fuel typed direct.fst root)
      compareBinderRaw "application-cold-conversion-entry"
        (psKernelSessionCheck fuel { checker with context := old } term)
        (psKernelExprV2TryCheckStateWithFuel fuel typed
          (psKernelExprV2CheckStateEmpty arena) root)
  require "application-warm-two-fuel-uses-own-pair"
    (match psKernelExprV2TryCheckStateWithFuel 2 typedContext direct.fst root with
     | some (.ok result) => result.fst.nextFresh == direct.fst.nextFresh
     | _ => false)
  require "application-cold-two-fuel-keeps-defeq-budget"
    (match psKernelExprV2TryCheckStateWithFuel 2 typedContext
        (psKernelExprV2CheckStateEmpty arena) root with
     | some (.error error) => error == "kernel definitional equality budget exhausted"
     | _ => false)
  let coldLegacy ← expect (psKernelSessionCheck 64 { checker with context := oldContext } term)
  let coldDirect ←
    match psKernelExprV2TryCheckStateWithFuel 64 typedContext
        (psKernelExprV2CheckStateEmpty arena) root with
    | some result => expect result
    | none => throw (IO.userError "PSC1_V2_APP_COLD_CONVERSION_FALLBACK")
  let published ← expect (psKernelExprV2DefEqPairContains
    coldDirect.fst.whnf.arena coldDirect.fst.success leftId rightId)
  require "application-retains-new-comparison-state" published
  compareBinderRaw "application-reuses-new-comparison-state"
    (psKernelSessionCheck 2 coldLegacy.snd term)
    (psKernelExprV2TryCheckStateWithFuel 2 typedContext coldDirect.fst root)
  let sx := nm "app-syntax-x"
  let sf := nm "app-syntax-f"
  let syntaxType := PsKernelExpr.forallE (nm "app-syntax-domain") sort1 sort1 .default
  let syntaxTerm := PsKernelExpr.app (.fvar sf) (.fvar sx)
  let (s0, sort1Id) ← expect (psKernelExprV2PagedImportChecked sort1)
  let (s1, syntaxTypeId) ← expect (psKernelExprV2PagedImportIntoChecked s0 syntaxType)
  let (syntaxArena, syntaxRoot) ← expect (psKernelExprV2PagedImportIntoChecked s1 syntaxTerm)
  let oldSyntax1 := psKernelLocalContextAddLocal checker.context.localContext sx sx sort1 .default
  let oldSyntax2 := psKernelLocalContextAddLocal oldSyntax1 sf sf syntaxType .default
  let oldSyntax := psKernelCheckerContextWithLocalContext checker.context oldSyntax2
  let typedSyntax1 := psKernelExprV2CheckContextWithLocal
    (psKernelExprV2CheckContextEmpty checker.context) sx sx sort1Id .default
  let typedSyntax := psKernelExprV2CheckContextWithLocal typedSyntax1 sf sf syntaxTypeId .default
  let syntaxState := psKernelExprV2CheckStateEmpty syntaxArena
  compareBinderRaw "application-syntax-original-shortcut"
    (psKernelSessionCheck 2 { checker with context := oldSyntax } syntaxTerm)
    (psKernelExprV2TryCheckStateWithFuel 2 typedSyntax syntaxState syntaxRoot)
  require "application-syntax-does-not-enter-defeq-or-publish-pair"
    (match psKernelExprV2TryCheckStateWithFuel 2 typedSyntax syntaxState syntaxRoot with
     | some (.ok result) => result.fst.success.length == 0
     | _ => false)
  IO.println "PSC1_V2_DAG_APP_CONVERSION_CACHE: PASS"

private def applicationEagerContextParity : IO Unit := do
  let marker := PsKernelExpr.const psKernelEagerReduceName []
  let markerWithLevels := PsKernelExpr.const psKernelEagerReduceName [.zero]
  let oneArg := PsKernelExpr.app marker sort0
  let twoArgs := PsKernelExpr.app oneArg sort1
  let fixtures : List (String × PsKernelExpr × Bool) := [
    ("arity-zero", marker, false),
    ("arity-one", oneArg, false),
    ("arity-two", twoArgs, true),
    ("arity-three", .app twoArgs sort0, false),
    ("levels-do-not-change-marker", .app (.app markerWithLevels sort0) sort1, true),
    ("metadata-head", .app (.app (.mdata 8 marker) sort0) sort1, false),
    ("metadata-whole", .mdata 8 twoArgs, false),
    ("metadata-argument", .app oneArg (.mdata 8 sort1), true),
    ("wrong-name", .app (.app (.const (nm "not-eagerReduce") []) sort0) sort1, false)]
  let session ← fresh 64 1
  let checker := psKernelKernelSessionChecker session [] .safe
  let localName := nm "app-marker-local"
  for (label, term, markerExpected) in fixtures do
    require ("application-original-marker-" ++ label)
      (psKernelExprIsEagerReduce term == markerExpected)
    let (baseArena, root) ← expect (psKernelExprV2PagedImportChecked term)
    let (arena, typeId) ← expect (psKernelExprV2PagedMkSort baseArena (.succ .zero))
    for initial in [false,true] do
      let scalar := { checker.context with
        eagerReduce := initial, recDepth := 7, maxNatSize := 1234 }
      let context := psKernelExprV2CheckContextWithLocal
        (psKernelExprV2CheckContextEmpty scalar) localName localName typeId .default
      let actual ← expect (psKernelExprV2CheckApplicationEqContext context arena root)
      require ("application-eager-marker-" ++ label)
        (actual.scalar.eagerReduce == (initial || markerExpected))
      require ("application-eager-preserves-resources-" ++ label)
        (actual.scalar.recDepth == 7 && actual.scalar.maxRecDepth == 1 &&
          actual.scalar.maxNatSize == 1234)
      require ("application-eager-preserves-typed-local-" ++ label)
        (actual.locals.length == 1 &&
          match psKernelExprV2CheckLocalFind actual.locals localName with
          | some declaration => declaration.type == typeId &&
              match declaration.value with | none => true | some _ => false
          | none => false)
      require ("application-eager-invalid-id-" ++ label)
        (match psKernelExprV2CheckApplicationEqContext context arena arena.size with
         | .error _ => true | .ok _ => false)
  IO.println "PSC1_V2_DAG_APP_EAGER_CONTEXT: PASS"

private def admissionInfoEqual (left right : PsKernelConstantInfo) : Bool :=
  let a := psKernelConstantInfoBase left
  let b := psKernelConstantInfoBase right
  let baseEqual := psKernelNameEq a.name b.name &&
    psKernelNameListsEq a.levelParams b.levelParams && psKernelExprEqual a.type b.type
  baseEqual && match left, right with
    | .axiomInfo x, .axiomInfo y => x.isUnsafe == y.isUnsafe
    | .defnInfo x, .defnInfo y =>
        psKernelExprEqual x.value y.value && psKernelSafetyEq x.safety y.safety &&
          match x.hints, y.hints with
          | .abbrevHint, .abbrevHint => true
          | .opaqueHint, .opaqueHint => true
          | .regular p, .regular q => p == q
          | _, _ => false
    | .thmInfo x, .thmInfo y => psKernelExprEqual x.value y.value
    | .opaqueInfo x, .opaqueInfo y =>
        psKernelExprEqual x.value y.value && x.isUnsafe == y.isUnsafe
    | _, _ => false

private def admissionEnvironmentEqual
    (left right : PsKernelEnvironment) : Bool :=
  left.quotInitialized == right.quotInitialized &&
    left.constants.length == right.constants.length &&
    (left.constants.zip right.constants).all (fun pair =>
      admissionInfoEqual pair.1 pair.2 &&
      match psKernelEnvironmentFind left (psKernelConstantInfoName pair.1),
          psKernelEnvironmentFind right (psKernelConstantInfoName pair.2) with
      | some a, some b => admissionInfoEqual a pair.1 && admissionInfoEqual b pair.2
      | _, _ => false)

private def admissionReceiptEqual
    (left right : PsKernelCheckingReceipt) : Bool :=
  left.target.contract == right.target.contract &&
    left.target.leanVersion == right.target.leanVersion &&
    left.target.leanCommit == right.target.leanCommit &&
    left.declarationsBefore == right.declarationsBefore &&
    left.declarationsAfter == right.declarationsAfter

private def admissionPublicParity
    (old : Except PsKernelError PsKernelAdmissionResult)
    (actual : Except PsKernelError PsKernelDagBatchResult) : Bool :=
  match old, actual with
  | .error a, .error b => samePublicError a b
  | .ok a, .ok b =>
      admissionEnvironmentEqual a.session.environment b.session.environment &&
        match b.replies with
        | [.admitted receipt] => admissionReceiptEqual a.declaration.receipt receipt
        | _ => false
  | _, _ => false

private def simpleAdmissionParity : IO Unit := do
  let declName := nm "AdmissionCase"
  let u := nm "admission-u"
  let x := nm "admission-x"
  let base := fun (params : List PsKernelName) (type : Nat) =>
    PsKernelDagConstantBase.mk declName params type
  let (arena, s0) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
  let (arena, s1) ← expect (psKernelExprV2PagedMkSort arena (.succ .zero))
  let (arena, equivalentS1) ← expect
    (psKernelExprV2PagedMkSort arena (.max (.succ .zero) (.succ .zero)))
  let (arena, su) ← expect (psKernelExprV2PagedMkSort arena (.param u))
  let (arena, sm) ← expect (psKernelExprV2PagedMkSort arena (.mvar u))
  let (arena, mv) ← expect (psKernelExprV2PagedMkMVar arena u)
  let (arena, fv) ← expect (psKernelExprV2PagedMkFVar arena u)
  let (arena, b0) ← expect (psKernelExprV2PagedMkBVar arena 0)
  let (arena, bothBad) ← expect (psKernelExprV2PagedMkApp arena mv fv)
  let (arena, unknown) ← expect (psKernelExprV2PagedMkConst arena (nm "admission-unknown") [])
  let (arena, identity) ← expect (psKernelExprV2PagedMkLam arena x s1 b0 .default)
  let (arena, identityType) ← expect (psKernelExprV2PagedMkForall arena x s1 s1 .default)
  let (arena, hiddenS1) ← expect (psKernelExprV2PagedMkMData arena 901 s1)
  let (arena, b1) ← expect (psKernelExprV2PagedMkBVar arena 1)
  let (arena, proofTailType) ← expect (psKernelExprV2PagedMkForall arena x b0 b1 .default)
  let (arena, proofTail) ← expect (psKernelExprV2PagedMkLam arena x b0 b0 .default)
  let (arena, proofType) ← expect (psKernelExprV2PagedMkForall arena u s0 proofTailType .default)
  let (arena, proof) ← expect (psKernelExprV2PagedMkLam arena u s0 proofTail .default)
  let defn := fun (type value : Nat) (safety : PsKernelDefinitionSafety) =>
    PsKernelDagDeclarationRequest.definitionDecl
      (PsKernelDagDefinition.mk (base [] type) value (.regular 7) safety)
  let fixtures : List (String × PsKernelDagDeclarationRequest × Bool) := [
    ("axiom-safe", .axiomDecl (base [] s1) false, true),
    ("axiom-unsafe", .axiomDecl (base [] s1) true, true),
    ("definition-safe", defn s1 s0 .safe, true),
    ("definition-partial", defn s1 s0 .partialDef, true),
    ("opaque-safe", .opaqueDecl (base [] s1) s0 false, true),
    ("opaque-unsafe-annotation", .opaqueDecl (base [] s1) s0 true, true),
    ("definition-mismatch", defn s1 s1 .safe, true),
    ("opaque-mismatch", .opaqueDecl (base [] s1) s1 false, true),
    ("universe-equivalence", defn equivalentS1 s0 .safe, true),
    ("lambda-body", defn identityType identity .safe, true),
    ("polymorphic-header", .axiomDecl (base [u] su) false, true),
    ("header-mvar-before-fvar", .axiomDecl (base [] bothBad) false, true),
    ("header-level-mvar", .axiomDecl (base [u] sm) false, true),
    ("header-fvar", .axiomDecl (base [] fv) false, true),
    ("duplicate-universe-before-mvar", .axiomDecl (base [u,u] mv) false, true),
    ("undefined-universe-before-body-mvar", defn su mv .safe, true),
    ("body-mvar-before-fvar", defn s1 bothBad .safe, true),
    ("body-fvar", defn s1 fv .safe, true),
    ("body-undefined-universe", defn s1 su .safe, true),
    ("header-loose-bvar", .axiomDecl (base [] b0) false, true),
    ("body-loose-bvar", defn s1 b0 .safe, true),
    ("unknown-header", .axiomDecl (base [] unknown) false, true),
    ("header-not-sort", .axiomDecl (base [] identity) false, true),
    ("final-defeq-fallback", defn hiddenS1 s0 .safe, false),
    ("unsafe-definition-fallback", defn s1 s0 .unsafeDef, false),
    ("theorem-fallback", .theoremDecl (base [] proofType) proof, false)]
  let built ← expect (psKernelExprV2DecodeChecked arena)
  let mut comparisons := 0
  for (label, request, directExpected) in fixtures do
    let decodedRequest ← expect (psKernelDagDecodeDeclaration built request)
    for fuel in [0,1,2,3,4,5,8,64] do
      for maxDepth in [0,1] do
        let seed ← fresh fuel maxDepth
        let direct := psKernelDagTryAdmitSimpleWithFuel fuel
          (psKernelKernelSessionEnvironment seed) maxDepth seed.resources.maxNatSize
          arena [] request decodedRequest
        match direct with
        | none => require ("admission-permitted-fallback-" ++ label) (!directExpected)
        | some attempted =>
            match psKernelV1DispatchDeclaration seed decodedRequest,
                psKernelV1EnvironmentOutcome attempted with
            | .error a, .error b =>
                require ("admission-raw-error-" ++ label) (samePublicError a b)
            | .ok a, .ok b =>
                require ("admission-raw-environment-" ++ label) (admissionEnvironmentEqual a b)
            | _, _ => throw (IO.userError ("admission raw mismatch " ++ label ++ "/" ++ toString fuel))
        require ("admission-public-" ++ label ++ "/" ++ toString fuel)
          (admissionPublicParity (psKernelV1AdmitDeclaration seed decodedRequest)
            (psKernelV1RunDag seed [] .safe arena [.admit request]))
        if fuel == 64 then
          require ("admission-explicit-path-" ++ label)
            ((match direct with | some _ => true | none => false) == directExpected)
        comparisons := comparisons + 1
  require "admission-matrix-count" (comparisons == 416)
  let official ← Lean.mkEmptyEnvironment
  for (label, typeRoot, valueRoot, expected) in [
      ("sort-definition", s1, s0, true),
      ("ill-typed-sort-definition", s1, s1, false),
      ("universe-equivalent-definition", equivalentS1, s0, true),
      ("lambda-definition", identityType, identity, true)] do
    let type ← expect (psKernelExprV2DecodedRequire built typeRoot)
    let value ← expect (psKernelExprV2DecodedRequire built valueRoot)
    let officialType ← projectionOfficialRequire type
    let officialValue ← projectionOfficialRequire value
    let declaration := Lean.Declaration.defnDecl {
      name := quickOfficialName declName
      levelParams := []
      type := officialType
      value := officialValue
      hints := .abbrev
      safety := .safe
    }
    let officialResult := official.addDeclCore 0 0 declaration none true
    let seed ← fresh 64 1
    let request := PsKernelDagDeclarationRequest.definitionDecl
      (PsKernelDagDefinition.mk (base [] typeRoot) valueRoot .abbrevHint .safe)
    let actual := psKernelV1RunDag seed [] .safe arena [.admit request]
    require ("official-Lean-simple-admission-" ++ label)
      ((match officialResult with | .ok _ => true | .error _ => false) == expected &&
        (match actual with | .ok _ => true | .error _ => false) == expected)
    if expected then
      let admitted ← expectPublic actual
      require ("official-simple-admission-stored-type-value-" ++ label)
        (match psKernelEnvironmentFind admitted.session.environment declName with
         | some (.defnInfo info) =>
             psKernelExprEqual info.base.type type && psKernelExprEqual info.value value
         | _ => false)
    else
      require ("official-simple-admission-precise-rejection-" ++ label)
        (match actual with
         | .error (.rejectedInvalid message) => message == "definition type mismatch"
         | _ => false)
  IO.println "PSC1_V2_DAG_OFFICIAL_SIMPLE_ADMISSION: PASS"
  IO.println "PSC1_V2_DAG_SIMPLE_ADMISSION_MATRIX: PASS"

private def admissionSharedStateSentinels : IO Unit := do
  for (layers, fuel, maxDepth, coldMessage) in [
      (4, 5, 0, "kernel inference budget exhausted"),
      (14, 64, 1, "deep recursion detected, use maxRecDepth to increase the limit")] do
    let seed ← fresh fuel maxDepth
    let aName := nm ("AdmissionHeaderA" ++ toString layers)
    let dName := nm ("AdmissionHeaderD" ++ toString layers)
    let xName := nm "admission-header-x"
    let (baseArena, s1) ← expect
      (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty (.succ .zero))
    let mut workingArena := baseArena
    let mut typeRoot := s1
    for tag in [:layers] do
      let next ← expect (psKernelExprV2PagedMkMData workingArena tag typeRoot)
      workingArena := next.fst
      typeRoot := next.snd
    let (arena, b0) ← expect (psKernelExprV2PagedMkBVar workingArena 0)
    let (arena, fn) ← expect (psKernelExprV2PagedMkLam arena xName typeRoot b0 .default)
    let (arena, aRoot) ← expect (psKernelExprV2PagedMkConst arena aName [])
    let (arena, bodyRoot) ← expect (psKernelExprV2PagedMkApp arena fn aRoot)
    let built ← expect (psKernelExprV2DecodeChecked arena)
    let type ← expect (psKernelExprV2DecodedRequire built typeRoot)
    let body ← expect (psKernelExprV2DecodedRequire built bodyRoot)
    let aRequest := PsKernelDagDeclarationRequest.axiomDecl
      (PsKernelDagConstantBase.mk aName [] typeRoot) false
    let dRequest := PsKernelDagDeclarationRequest.definitionDecl
      (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk dName [] typeRoot)
        bodyRoot .abbrevHint .safe)
    let admitted ← expectPublic
      (psKernelDagRunCommand (PsKernelDagExecutionState.mk seed []) [] .safe
        arena built (.admit aRequest))
    let owner := admitted.snd
    let checker := psKernelKernelSessionChecker owner.session [] .safe
    let context := psKernelExprV2CheckContextEmpty checker.context
    let initial := psKernelExprV2CheckStateWithWhnf
      (psKernelExprV2CheckStateEmpty arena)
      (psKernelExprV2WhnfStateForDeclarations arena owner.declarations)
    let base := PsKernelConstantBase.mk dName [] type
    let value := PsKernelDefinitionInfo.mk base body .abbrevHint .safe
    let oldHeader ← expect (psKernelCheckConstantBaseWithSession fuel checker base)
    let afterHeader ←
      match psKernelExprV2AdmissionCheckHeaderWithFuel fuel context initial base typeRoot with
      | some attempted => expect attempted
      | none => throw (IO.userError "direct admission header unexpectedly declined")
    let oldBody ← expect (psKernelCheckDefinitionBodyWithSession fuel oldHeader value)
    let warmBody := psKernelExprV2AdmissionCheckBodyWithFuel fuel context afterHeader
      base typeRoot body bodyRoot "definition type mismatch"
    require "admission-shared-header-cache-required"
      (match warmBody with | some (.ok _) => true | _ => false)
    require "admission-shared-header-fresh-counter" (oldBody.state.nextFresh == 1)
    let coldLegacy := psKernelCheckDefinitionBodyWithSession fuel checker value
    let coldDag := psKernelExprV2AdmissionCheckBodyWithFuel fuel context initial
      base typeRoot body bodyRoot "definition type mismatch"
    require "admission-fresh-body-would-change-resource-result"
      (match coldLegacy, coldDag with
       | .error left, some (.error right) => left == right && left == coldMessage
       | _, _ => false)
    let decodedRequest ← expect (psKernelDagDecodeDeclaration built dRequest)
    require "admission-shared-state-direct-attempt-selected"
      (match psKernelDagTryAdmitSimpleWithFuel fuel
          (psKernelKernelSessionEnvironment owner.session) maxDepth
          owner.session.resources.maxNatSize arena owner.declarations
          dRequest decodedRequest with
       | some (.ok _) => true | _ => false)
    let original ← expectPublic (psKernelV1AdmitDeclaration owner.session decodedRequest)
    let actual ← expectPublic
      (psKernelV1RunDag seed [] .safe arena [.admit aRequest, .admit dRequest])
    require "admission-shared-state-public-complete-parity"
      (admissionEnvironmentEqual actual.session.environment original.session.environment)
    require "admission-shared-state-stored-definition"
      (match psKernelEnvironmentFind actual.session.environment dName with
       | some (.defnInfo info) =>
           psKernelExprEqual info.base.type type && psKernelExprEqual info.value body &&
             psKernelDefinitionSafetyIsSafe info.safety
       | _ => false)
    require "admission-shared-state-ordered-receipts"
      (match actual.replies with
       | [.admitted first, .admitted second] =>
           first.declarationsBefore == 0 && first.declarationsAfter == 1 &&
             second.declarationsBefore == 1 && second.declarationsAfter == 2
       | _ => false)
  IO.println "PSC1_V2_DAG_ADMISSION_SHARED_STATE: PASS"

private def admissionPolicyAndSafety : IO Unit := do
  let seed ← fresh 64 1
  let uName := nm "AdmissionUnsafe"
  let pName := nm "AdmissionPartial"
  let aName := nm "AdmissionSafetyTarget"
  let (arena, s0) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
  let (arena, s1) ← expect (psKernelExprV2PagedMkSort arena (.succ .zero))
  let (arena, unsafeRoot) ← expect (psKernelExprV2PagedMkConst arena uName [])
  let (arena, partialRoot) ← expect (psKernelExprV2PagedMkConst arena pName [])
  let (arena, mv) ← expect (psKernelExprV2PagedMkMVar arena (nm "admission-policy-mvar"))
  let built ← expect (psKernelExprV2DecodeChecked arena)
  let base := fun (type : Nat) => PsKernelDagConstantBase.mk aName [] type
  let unsafeRequest := PsKernelDagDeclarationRequest.axiomDecl
    (PsKernelDagConstantBase.mk uName [] s1) true
  let partialRequest := PsKernelDagDeclarationRequest.definitionDecl
    (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk pName [] s1)
      s0 .abbrevHint .partialDef)
  let first ← expectPublic (psKernelDagRunCommand
    (PsKernelDagExecutionState.mk seed []) [] .safe arena built (.admit unsafeRequest))
  let second ← expectPublic (psKernelDagRunCommand first.snd [] .safe arena built (.admit partialRequest))
  let owner := second.snd
  let defn := fun (value : Nat) (safety : PsKernelDefinitionSafety) =>
    PsKernelDagDeclarationRequest.definitionDecl
      (PsKernelDagDefinition.mk (base s1) value .abbrevHint safety)
  let safetyCases : List (String × PsKernelDagDeclarationRequest × Bool × Bool) := [
      ("unsafe-header-safe", .axiomDecl (base unsafeRoot) false, false, true),
      ("unsafe-header-unsafe", .axiomDecl (base unsafeRoot) true, true, true),
      ("partial-header-safe", .axiomDecl (base partialRoot) false, false, true),
      ("partial-header-unsafe", .axiomDecl (base partialRoot) true, true, true),
      ("unsafe-body-safe", defn unsafeRoot .safe, false, true),
      ("unsafe-body-partial", defn unsafeRoot .partialDef, false, true),
      ("partial-body-partial", defn partialRoot .partialDef, false, true),
      ("unsafe-body-opaque", .opaqueDecl (base s1) unsafeRoot true, false, true),
      ("unsafe-body-unsafe", defn unsafeRoot .unsafeDef, true, false)]
  for (label, request, acceptedExpected, directExpected) in safetyCases do
    let declaration ← expect (psKernelDagDecodeDeclaration built request)
    let attempted := psKernelDagTryAdmitSimpleWithFuel 64
      (psKernelKernelSessionEnvironment owner.session) 1 owner.session.resources.maxNatSize
      arena owner.declarations request declaration
    require ("admission-safety-path-" ++ label)
      ((match attempted with | none => false | some _ => true) == directExpected)
    require ("admission-safety-direct-decision-" ++ label)
      (match attempted with
       | none => true
       | some result => (match result with | .ok _ => true | .error _ => false) == acceptedExpected)
    let original := psKernelV1AdmitDeclaration owner.session declaration
    require ("admission-safety-original-decision-" ++ label)
      ((match original with | .ok _ => true | .error _ => false) == acceptedExpected)
    require ("admission-safety-public-parity-" ++ label)
      (admissionPublicParity original
        (psKernelV1RunDag owner.session [] .safe arena [.admit request]))
    let whole := psKernelV1RunDag seed [] .safe arena
      [.admit unsafeRequest, .admit partialRequest, .admit request]
    require ("admission-safety-complete-same-batch-" ++ label)
      (match original, whole with
       | .error a, .error b => samePublicError a b
       | .ok a, .ok b => admissionEnvironmentEqual a.session.environment b.session.environment
       | _, _ => false)
  let duplicate := PsKernelDagDeclarationRequest.axiomDecl
    (PsKernelDagConstantBase.mk uName [aName,aName] mv) false
  let duplicateDecl ← expect (psKernelDagDecodeDeclaration built duplicate)
  require "admission-existing-name-before-universe-and-metavariable"
    (match psKernelDagAdmitDeclaration owner.session arena owner.declarations duplicate duplicateDecl with
     | .error (.rejectedInvalid message) => message == "already declared"
     | _ => false)
  let valid := defn s0 .safe
  let bad := defn s1 .safe
  for request in [valid,bad] do
    let declaration ← expect (psKernelDagDecodeDeclaration built request)
    let limited := { owner.session with resources := { owner.session.resources with maxDeclarations := 2 } }
    require "admission-limit-after-complete-check"
      (admissionPublicParity (psKernelV1AdmitDeclaration limited declaration)
        (psKernelV1RunDag limited [] .safe arena [.admit request]))
  let validDecl ← expect (psKernelDagDecodeDeclaration built valid)
  let limited := { owner.session with resources := { owner.session.resources with maxDeclarations := 2 } }
  require "admission-limit-exact-outcome"
    (match psKernelDagAdmitDeclaration limited arena owner.declarations valid validDecl with
     | .error (.resourceExhausted .declarationLimit message) => message == "declaration limit exceeded"
     | _ => false)
  let malformed := PsKernelDagDeclarationRequest.axiomDecl
    (PsKernelDagConstantBase.mk uName [] arena.size) false
  require "admission-malformed-id-before-duplicate-name"
    (match psKernelDagDecodeDeclaration built malformed,
        psKernelV1RunDag owner.session [] .safe arena [.admit malformed] with
     | .error a, .error (.rejectedInvalid b) => a == b
     | _, _ => false)
  let cancelled := { owner.session with resources := { owner.session.resources with cancelled := true } }
  require "admission-preflight-before-malformed-id"
    (match psKernelV1RunDag cancelled [] .safe arena [.admit malformed] with
     | .error (.resourceExhausted .cancelled _) => true | _ => false)
  require "admission-failure-does-not-publish-request-index"
    (owner.declarations.length == 2 &&
      match psKernelExprV2DeclarationRefFind owner.declarations aName with
      | none => true | _ => false)
  require "admission-failure-does-not-install-target"
    (match psKernelEnvironmentFind owner.session.environment aName with | none => true | _ => false)
  IO.println "PSC1_V2_DAG_ADMISSION_POLICY_SAFETY: PASS"

private def admissionFinalComparisonGuards : IO Unit := do
  let seed ← fresh 64 1
  let aName := nm "AdmissionGuardA"
  let dName := nm "AdmissionGuardD"
  let (arena, s1) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty (.succ .zero))
  let (arena, leftType) ← expect (psKernelExprV2PagedMkMData arena 11 s1)
  let (arena, rightType) ← expect (psKernelExprV2PagedMkMData arena 12 s1)
  let (arena, bodyRoot) ← expect (psKernelExprV2PagedMkConst arena aName [])
  let built ← expect (psKernelExprV2DecodeChecked arena)
  let request := PsKernelDagDeclarationRequest.axiomDecl
    (PsKernelDagConstantBase.mk aName [] leftType) false
  let owner := (← expectPublic (psKernelDagRunCommand
    (PsKernelDagExecutionState.mk seed []) [] .safe arena built (.admit request))).snd
  let declaredType ← expect (psKernelExprV2DecodedRequire built rightType)
  let body ← expect (psKernelExprV2DecodedRequire built bodyRoot)
  let base := PsKernelConstantBase.mk dName [] declaredType
  let value := PsKernelDefinitionInfo.mk base body .abbrevHint .safe
  for (fuel, recDepth, expected) in [
      (1, 0, some "kernel definitional equality budget exhausted"),
      (64, 15, some "deep recursion detected, use maxRecDepth to increase the limit"),
      (64, 14, none)] do
    let checker := psKernelKernelSessionChecker owner.session [] .safe
    let scalar := { checker.context with recDepth := recDepth }
    let context := psKernelExprV2CheckContextEmpty scalar
    let state := psKernelExprV2CheckStateWithWhnf
      (psKernelExprV2CheckStateEmpty arena)
      (psKernelExprV2WhnfStateForDeclarations arena owner.declarations)
    let legacy := psKernelCheckDefinitionBodyWithSession fuel { checker with context := scalar } value
    let actual := psKernelExprV2AdmissionCheckBodyWithFuel fuel context state
      base rightType body bodyRoot "definition type mismatch"
    require "admission-final-defeq-original-entry-guards"
      (match legacy, actual, expected with
       | .error a, some (.error b), some wanted => a == b && a == wanted
       | .ok _, some (.ok _), none => true
       | _, _, _ => false)
  let checker := psKernelKernelSessionChecker owner.session [] .safe
  require "admission-ensure-sort-always-enters-whnf-even-sort"
    (match psKernelSessionEnsureSort 0 checker sort1,
        psKernelExprV2AdmissionEnsureSortWithFuel 0
          (psKernelExprV2CheckContextEmpty checker.context)
          (psKernelExprV2CheckStateEmpty arena) s1 with
     | .error a, some (.error b) => a == b && a == "kernel reduction budget exhausted"
     | _, _ => false)
  let leftExpression ← expect (psKernelExprV2DecodedRequire built leftType)
  let oldWarm ← expect (psKernelSessionIsDefEq 64 checker leftExpression declaredType)
  let initial := psKernelExprV2CheckStateWithWhnf
    (psKernelExprV2CheckStateEmpty arena)
    (psKernelExprV2WhnfStateForDeclarations arena owner.declarations)
  let dagWarm ←
    match psKernelExprV2TryDefEqStateWithFuel 64
        (psKernelExprV2CheckContextEmpty checker.context) initial leftType rightType with
    | some result => expect result
    | none => throw (IO.userError "admission warm pair unexpectedly declined")
  require "admission-final-warm-pair-established" (oldWarm.fst && dagWarm.snd)
  let scalar := { checker.context with recDepth := 15 }
  let oldBody := psKernelCheckDefinitionBodyWithSession 64
    { oldWarm.snd with context := scalar } value
  let dagBody := psKernelExprV2AdmissionCheckBodyWithFuel 64
    (psKernelExprV2CheckContextEmpty scalar) dagWarm.fst
    base rightType body bodyRoot "definition type mismatch"
  require "admission-final-comparison-retains-existing-success-owner"
    (match oldBody, dagBody with
     | .ok _, some (.ok _) => true
     | _, _ => false)
  IO.println "PSC1_V2_DAG_ADMISSION_FINAL_GUARDS: PASS"

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
  checkedLetParity
  checkedLetCacheScope
  checkedLocalValueWhnfParity
  statefulDefEqPairParity
  applicationConversionParity
  applicationConversionCacheParity
  applicationEagerContextParity
  simpleAdmissionParity
  admissionSharedStateSentinels
  admissionPolicyAndSafety
  admissionFinalComparisonGuards
  officialComparison
  IO.println "PSC1_V2_DAG_REGRESSION: PASS"
