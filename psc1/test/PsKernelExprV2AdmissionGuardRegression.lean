import Lean
import Ps.KernelCore.API.Dag
import Ps.KernelCore.API.DagAdmissionGuards
import Ps.KernelCore.Research.ExprV2PagedImport

private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_V2_ADMISSION_GUARD_FAIL " ++ label))

private def expect {α : Type} (value : Except String α) : IO α := do
  match value with
  | .ok result => return result
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} (value : Except PsKernelError α) : IO α := do
  match value with
  | .ok result => return result
  | .error _ => throw (IO.userError "unexpected public admission failure")

private def nm (text : String) := PsKernelName.str .anonymous text
private def u := nm "guard-u"
private def v := nm "guard-v"
private def x := nm "guard-x"
private def s0 := PsKernelExpr.sort .zero
private def s1 := PsKernelExpr.sort (.succ .zero)
private def su := PsKernelExpr.sort (.param u)
private def sv := PsKernelExpr.sort (.param v)
private def sm := PsKernelExpr.sort (.mvar u)
private def fv := PsKernelExpr.fvar x
private def mv := PsKernelExpr.mvar x

private def fixtures : List (String × PsKernelExpr) := [
  ("bvar", .bvar 0), ("fvar", fv), ("mvar", mv), ("sort-zero", s0),
  ("sort-u", su), ("sort-v", sv), ("sort-universe-mvar", sm),
  ("sort-nested", .sort (.imax (.max .zero (.param u)) (.succ (.param v)))),
  ("constant-empty", .const (nm "C") []),
  ("constant-uv", .const (nm "C") [.param u, .param v]),
  ("constant-vu", .const (nm "C") [.param v, .param u]),
  ("constant-universe-mvar", .const (nm "C") [.param u, .mvar v]),
  ("nat-literal", .lit (.nat 42)), ("string-literal", .lit (.str "λ雪😀")),
  ("app-closed", .app s0 s1), ("app-uv", .app su sv), ("app-vu", .app sv su),
  ("fvar-before-universe-mvar", .app fv sm),
  ("undefined-before-expression-mvar", .app su mv),
  ("lambda-uv", .lam x su sv .implicit),
  ("forall-vu", .forallE x sv su .strictImplicit),
  ("let-uv-universe-mvar", .letE x su sv sm false),
  ("let-expression-mvar-fvar-u", .letE x mv fv su true),
  ("let-uv-closed", .letE x su sv s0 false),
  ("metadata-u", .mdata 73 su), ("projection-v", .proj (nm "S") 0 sv),
  ("fvar-before-undefined", .app fv su),
  ("repeated-subterm", .app (.app su sv) (.app su sv))
]

private def referenceGuard (expr : PsKernelExpr) (allowed : List PsKernelName) :
    Except String Unit :=
  match psKernelCheckNoMVarNoFVar expr with
  | .error error => .error error
  | .ok _ => psKernelCheckLevelParams expr allowed

private def sameGuard (left right : Except String Unit) : Bool :=
  match left, right with
  | .ok _, .ok _ => true
  | .error a, .error b => a == b
  | _, _ => false

private def sameNameOption (left right : Option PsKernelName) : Bool :=
  match left, right with
  | .none, .none => true
  | .some a, .some b => psKernelNameEq a b
  | _, _ => false

private def sameResource : PsKernelResourceError → PsKernelResourceError → Bool
  | .fuel, .fuel => true
  | .recursionDepth, .recursionDepth => true
  | .natSize, .natSize => true
  | .cancelled, .cancelled => true
  | .declarationLimit, .declarationLimit => true
  | .hostStack, .hostStack => true
  | _, _ => false

private def sameError : PsKernelError → PsKernelError → Bool
  | .rejectedInvalid a, .rejectedInvalid b => a == b
  | .declinedUnsupported a, .declinedUnsupported b => a == b
  | .internalError a, .internalError b => a == b
  | .resourceExhausted ka a, .resourceExhausted kb b => sameResource ka kb && a == b
  | _, _ => false

private def infoEqual (left right : PsKernelConstantInfo) : Bool :=
  let a := psKernelConstantInfoBase left
  let b := psKernelConstantInfoBase right
  let sameBase := psKernelNameEq a.name b.name &&
    psKernelNameListsEq a.levelParams b.levelParams && psKernelExprEqual a.type b.type
  sameBase && match left, right with
    | .axiomInfo a, .axiomInfo b => a.isUnsafe == b.isUnsafe
    | .defnInfo a, .defnInfo b =>
        psKernelExprEqual a.value b.value && psKernelSafetyEq a.safety b.safety &&
          match a.hints, b.hints with
          | .abbrevHint, .abbrevHint => true
          | .opaqueHint, .opaqueHint => true
          | .regular a, .regular b => a == b
          | _, _ => false
    | _, _ => false

private def sameEnvironment (left right : PsKernelEnvironment) : Bool :=
  left.quotInitialized == right.quotInitialized &&
    left.constants.length == right.constants.length &&
    (left.constants.zip right.constants).all (fun pair => infoEqual pair.1 pair.2)

private def sameAdmission
    (left : Except PsKernelError PsKernelAdmissionResult)
    (right : Except PsKernelError PsKernelDagBatchResult) : Bool :=
  match left, right with
  | .error a, .error b => sameError a b
  | .ok a, .ok b =>
      sameEnvironment a.session.environment b.session.environment &&
        match b.replies with
        | [.admitted receipt] =>
            a.declaration.receipt.target.contract == receipt.target.contract &&
            a.declaration.receipt.target.leanVersion == receipt.target.leanVersion &&
            a.declaration.receipt.target.leanCommit == receipt.target.leanCommit &&
            a.declaration.receipt.declarationsBefore == receipt.declarationsBefore &&
            a.declaration.receipt.declarationsAfter == receipt.declarationsAfter
        | _ => false
  | _, _ => false

private def fresh (fuel depth : Nat) : IO PsKernelKernelSession :=
  expectPublic (psKernelKernelSessionEmpty
    { psKernelResourcePolicyDefault with fuel := fuel, maxRecDepth := depth }
    psKernelProviderDefault)

private def staticMatrix : IO Unit := do
  require "fixture-count" (fixtures.length == 28)
  let mut comparisons := 0
  for pageLimit in [1,3,64] do
    for (label, expr) in fixtures do
      let empty := psKernelExprV2PagedEmptyWithLimit pageLimit
      let (arena, root) ← expect (psKernelExprV2PagedImportIntoChecked empty expr)
      for allowed in [[],[u],[v],[u,v],[u,u]] do
        let expected := referenceGuard expr allowed
        require ("static-canonical-" ++ label)
          (sameGuard expected (psKernelExprV2AdmissionStaticOnCanonical arena root allowed))
        require ("static-checked-" ++ label)
          (sameGuard expected (psKernelExprV2AdmissionStaticChecked arena root allowed))
        unless psKernelExprHasMVar expr do
          let entry ← expect (psKernelExprV2PagedRequire arena root)
          let scanned ← expect (psKernelExprV2AdmissionScanWithFuel
            (Nat.succ entry.depth) arena allowed .empty root .none)
          require ("first-undefined-" ++ label)
            (sameNameOption scanned.snd (psKernelFindUndefExprLevelParam expr allowed))
          require ("complete-root-is-memoized-" ++ label)
            (psKernelExprV2AdmissionSeenContains scanned.fst root)
        comparisons := comparisons + 1
  require "static-matrix-count" (comparisons == 420)
  IO.println "PSC1_V2_ADMISSION_GUARD_STATIC: PASS comparisons=420"

private def hostileAndBoundary : IO Unit := do
  let mut seen := PsKernelExprV2AdmissionSeen.empty
  for id in [0,65536,131072,1,65537,18446744073709551616] do
    require "collision-miss-before-insert"
      (!(psKernelExprV2AdmissionSeenContains seen id))
    seen := psKernelExprV2AdmissionSeenInsert seen id
    require "exact-id-after-insert" (psKernelExprV2AdmissionSeenContains seen id)
  for id in [0,65536,131072,1,65537,18446744073709551616] do
    require "earlier-collisions-retained" (psKernelExprV2AdmissionSeenContains seen id)
  require "uninserted-id-not-a-hash-hit" (!(psKernelExprV2AdmissionSeenContains seen 196608))
  require "zero-scan-before-memo"
    (match psKernelExprV2AdmissionScanWithFuel 0 psKernelExprV2PagedEmpty [] seen 0 none with
     | .error error => error == "PSKERNEL_V2_ADMISSION_GUARD_FUEL"
     | _ => false)
  let mut hostile := 0
  for pageLimit in [1,3,64] do
    for (label, leaf, allowed, expected) in [
        ("allowed", su, [u], Except.ok ()),
        ("undefined", su, [], Except.error "invalid reference to undefined universe level parameter"),
        ("level-mvar", sm, [], Except.error "declaration has metavariables"),
        ("fvar", fv, [], Except.error "declaration has free variables")] do
      let (initial, first) ← expect
        (psKernelExprV2PagedImportIntoChecked (psKernelExprV2PagedEmptyWithLimit pageLimit) leaf)
      let mut arena := initial
      let mut root := first
      for _ in [:128] do
        let (next, id) ← expect (psKernelExprV2PagedMkApp arena root root)
        arena := next
        root := id
      require ("shared-128-" ++ label)
        (arena.size == 129 &&
          sameGuard expected (psKernelExprV2AdmissionStaticChecked arena root allowed))
      hostile := hostile + 1
  require "hostile-matrix-count" (hostile == 12)
  let (arena, root) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty (.param u))
  for allowed in [[u],[],[u],[],[u]] do
    require "allowed-context-is-fresh"
      (sameGuard (referenceGuard su allowed)
        (psKernelExprV2AdmissionStaticOnCanonical arena root allowed))
  let scanned ← expect (psKernelExprV2AdmissionScanWithFuel 2 arena [] .empty root (.some v))
  require "earlier-undefined-name-retained" (sameNameOption scanned.snd (.some v))
  for (source, badRoot) in [(psKernelExprV2PagedEmpty,0),(arena,arena.size)] do
    require "empty-or-dangling-root"
      (match psKernelExprV2AdmissionStaticChecked source badRoot [] with
       | .error error => error == "PSKERNEL_V2_PAGED_INVALID_CHILD"
       | _ => false)
  let entry ← expect (psKernelExprV2PagedRequire arena root)
  let (fvarArena, fvarRoot) ← expect (psKernelExprV2PagedMkFVar psKernelExprV2PagedEmpty x)
  let fvarEntry ← expect (psKernelExprV2PagedRequire fvarArena fvarRoot)
  let (mvarArena, mvarRoot) ← expect (psKernelExprV2PagedMkMVar psKernelExprV2PagedEmpty x)
  let mvarEntry ← expect (psKernelExprV2PagedRequire mvarArena mvarRoot)
  let forged : List PsKernelExprV2PagedArena := [
    { arena with pageLimit := 0 },
    (psKernelExprV2PagedPush psKernelExprV2PagedEmpty
      { fvarEntry with hasFVar := false }).fst,
    (psKernelExprV2PagedPush psKernelExprV2PagedEmpty
      { mvarEntry with hasExprMVar := false }).fst,
    (psKernelExprV2PagedPush psKernelExprV2PagedEmpty
      { entry with depth := 0 }).fst,
    (psKernelExprV2PagedPush psKernelExprV2PagedEmpty
      { entry with node := .app 0 0 }).fst,
    (psKernelExprV2PagedPush psKernelExprV2PagedEmpty
      { entry with node := .app 999 0 }).fst
  ]
  for source in forged do
    match psKernelExprV2PagedValidate source,
        psKernelExprV2AdmissionStaticChecked source 0 [] with
    | .error a, .error b => require "validation-before-static-flags" (a == b)
    | _, _ => throw (IO.userError "forged arena escaped guard boundary")
  IO.println "PSC1_V2_ADMISSION_GUARD_HOSTILE: PASS sharedDepth=128 cases=12"

private def publicMatrix : IO Unit := do
  let target := nm "GuardAdmissionCase"
  let mut comparisons := 0
  for (label, expr) in fixtures do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked expr)
    let (arena, typeRoot) ← expect (psKernelExprV2PagedImportIntoChecked arena s1)
    let base := PsKernelDagConstantBase.mk target [u] root
    let bodyBase := PsKernelDagConstantBase.mk target [u] typeRoot
    let decoded ← expect (psKernelExprV2DecodeChecked arena)
    let requests := [
      PsKernelDagDeclarationRequest.axiomDecl base false,
      PsKernelDagDeclarationRequest.definitionDecl
        (PsKernelDagDefinition.mk bodyBase root .abbrevHint .safe)]
    for request in requests do
      let declaration ← expect (psKernelDagDecodeDeclaration decoded request)
      for fuel in [0,1,2,8,64,4096] do
        for depth in [0,1] do
          let session ← fresh fuel depth
          require ("public-" ++ label ++ "/" ++ toString fuel)
            (sameAdmission (psKernelV1AdmitDeclaration session declaration)
              (psKernelV1RunDag session [] .safe arena [.admit request]))
          comparisons := comparisons + 1
    let seed ← fresh 64 0
    let checker := psKernelKernelSessionChecker seed [u] .safe
    let context := psKernelExprV2CheckContextEmpty checker.context
    let state := psKernelExprV2CheckStateEmpty arena
    let scalarBase := PsKernelConstantBase.mk target [u] s1
    match referenceGuard expr [u] with
    | .ok _ => pure ()
    | .error expected =>
        require ("body-static-before-zero-checker-fuel-" ++ label)
          (match psKernelExprV2AdmissionCheckBodyWithFuel 0 context state
              scalarBase typeRoot expr root "mismatch" with
           | .some (.error actual) => actual == expected
           | _ => false)
  require "public-matrix-count" (comparisons == 672)
  let (arena, root) ← expect (psKernelExprV2PagedMkMVar psKernelExprV2PagedEmpty x)
  let seed ← fresh 64 0
  let checker := psKernelKernelSessionChecker seed [] .safe
  let context := psKernelExprV2CheckContextEmpty checker.context
  let state := psKernelExprV2CheckStateEmpty arena
  let duplicate := PsKernelConstantBase.mk target [u,u] mv
  require "duplicate-params-before-mvar-and-zero-fuel"
    (match psKernelExprV2AdmissionCheckHeaderWithFuel 0 context state duplicate root with
     | .some (.error error) => error == "duplicate universe parameter"
     | _ => false)
  IO.println "PSC1_V2_ADMISSION_GUARD_PUBLIC: PASS comparisons=672"

private def official : IO Unit := do
  let officialEnv ← Lean.mkEmptyEnvironment
  let lu := Lean.Name.str .anonymous "guard-u"
  let lx := Lean.Name.str .anonymous "guard-x"
  let target := nm "GuardOfficial"
  let cases : List (PsKernelExpr × Lean.Expr × List PsKernelName × List Lean.Name × Bool) := [
    (s1, .sort (.succ .zero), [], [], true),
    (su, .sort (.param lu), [u], [lu], true),
    (su, .sort (.param lu), [], [], false),
    (sm, .sort (.mvar (⟨lu⟩)), [u], [lu], false),
    (mv, .mvar (Lean.MVarId.mk lx), [], [], false),
    (fv, .fvar (Lean.FVarId.mk lx), [], [], false)]
  let mut count := 0
  for (type, officialType, params, officialParams, expected) in cases do
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked type)
    let request := PsKernelDagDeclarationRequest.axiomDecl
      (PsKernelDagConstantBase.mk target params root) false
    let declaration := Lean.Declaration.axiomDecl {
      name := Lean.Name.str .anonymous "GuardOfficial"
      levelParams := officialParams
      type := officialType
      isUnsafe := false
    }
    let result := officialEnv.addDeclCore 0 0 declaration none true
    let seed ← fresh 4096 0
    let actual := psKernelV1RunDag seed [] .safe arena [.admit request]
    require "official-header-verdict"
      ((match result with | .ok _ => true | .error _ => false) == expected &&
        (match actual with | .ok _ => expected | .error (.rejectedInvalid _) => !expected | _ => false))
    count := count + 1
  for (value, officialValue, expected) in [
      (s0, Lean.Expr.sort .zero, true), (s1, Lean.Expr.sort (.succ .zero), false)] do
    let (arena, typeRoot) ← expect (psKernelExprV2PagedImportChecked s1)
    let (arena, valueRoot) ← expect (psKernelExprV2PagedImportIntoChecked arena value)
    let request := PsKernelDagDeclarationRequest.definitionDecl
      (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk target [] typeRoot)
        valueRoot .abbrevHint .safe)
    let declaration := Lean.Declaration.defnDecl {
      name := Lean.Name.str .anonymous "GuardOfficial"
      levelParams := []
      type := Lean.Expr.sort (.succ .zero)
      value := officialValue
      hints := .abbrev
      safety := .safe
    }
    let result := officialEnv.addDeclCore 0 0 declaration none true
    let seed ← fresh 4096 0
    let actual := psKernelV1RunDag seed [] .safe arena [.admit request]
    require "official-body-verdict"
      ((match result with | .ok _ => true | .error _ => false) == expected &&
        (match actual with | .ok _ => expected | .error (.rejectedInvalid _) => !expected | _ => false))
    count := count + 1
  require "official-count" (count == 8)
  IO.println "PSC1_V2_ADMISSION_GUARD_OFFICIAL: PASS cases=8 doCheck=true"

def main : IO Unit := do
  staticMatrix
  hostileAndBoundary
  publicMatrix
  official
  IO.println "PSC1_V2_ADMISSION_GUARD: PASS"
