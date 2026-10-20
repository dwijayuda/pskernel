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
  let warmOriginal ← expect (psKernelSessionWhnf 4 checker shared)
  let warmDag ← expect
    (match psKernelExprV2TryWhnfStateWithFuel 4 checker.context
        (psKernelExprV2WhnfStateEmpty warmArena) warmRoot with
     | some value => value | none => .error "missing warm DAG result")
  let blockedContext := { checker.context with maxRecDepth := 1, recDepth := 16 }
  for context in [checker.context, blockedContext] do
    for fuel in [0,1] do
      rawStateWhnfParity "warm-cache-entry-guards"
        (psKernelWhnfCoreWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel)
          context warmOriginal.snd.state shared false false)
        (psKernelExprV2TryWhnfCoreStateWithFuel fuel context warmDag.fst warmRoot)
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
  require "fvar-containing-source-cache-ineligible" openResult.fst.coreCache.isEmpty
  let localLet := psKernelLocalContextAddLet checker.context.localContext
    localName localName sort1 sort0
  let letContext := psKernelCheckerContextWithLocalContext checker.context localLet
  let (fvarArena, fvarRoot) ← expect (psKernelExprV2PagedImportChecked (.fvar localName))
  require "legacy-local-let-value-remains-explicit-fallback"
    (match psKernelExprV2TryWhnfWithFuel 64 letContext fvarArena fvarRoot with
     | none => true | _ => false)
  IO.println "PSC1_V2_DAG_NATIVE_WHNF_STATE: PASS"

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
    require "structural-false-falls-back-to-complete-defeq"
      (sameDefEq
        (psKernelV1IsDefEq session [] .safe (.mdata 0 sort0) (.mdata 65521 sort0))
        (psKernelV1RunDag session [] .safe a [.isDefEq tagA tagB]))
  let (a, badA) ← expect (psKernelExprV2PagedMkApp a s s)
  let (a, badB) ← expect (psKernelExprV2PagedMkApp a s s)
  require "different-id-equal-illtyped-terms-rejected"
    (match psKernelV1RunDag session [] .safe a [.isDefEq badA badB] with
     | .error (.rejectedInvalid _) => true | _ => false)
  IO.println "PSC1_V2_DAG_STRUCTURAL_SHORTCUT: PASS"

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
  zetaWhnfParity
  betaWhnfParity
  whnfFunctionStateParity
  structuralShortcutParity
  hostileInputs
  admissions
  officialComparison
  IO.println "PSC1_V2_DAG_REGRESSION: PASS"
