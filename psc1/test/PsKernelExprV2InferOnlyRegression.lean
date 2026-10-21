import Ps.KernelCore.Checker.ExprV2.Check
import Lean
import Ps.KernelCore.API.Dag
import Ps.KernelCore.Research.ExprV2PagedImport

private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_V2_INFER_ONLY_FAIL " ++ label))

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def expectPublic {α : Type} : Except PsKernelError α → IO α
  | .ok value => pure value
  | .error _ => throw (IO.userError "inference-only fixture admission failed")

private def nm (value : String) := PsKernelName.str .anonymous value
private def s0 := PsKernelExpr.sort PsKernelLevel.zero
private def s1 := PsKernelExpr.sort (.succ .zero)

private def initialState
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) :=
  psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
    (psKernelExprV2WhnfStateForDeclarations arena declarations)

private def decodeResult
    (result : Prod PsKernelExprV2CheckState Nat) : IO PsKernelExpr := do
  let built ← expect (psKernelExprV2DecodeChecked result.fst.whnf.arena)
  expect (psKernelExprV2DecodedRequire built result.snd)

private def compare
    (label : String)
    (original : Except String (Prod PsKernelExpr PsKernelCheckerState))
    (actual : Option (Except String (Prod PsKernelExprV2CheckState Nat))) :
    IO Unit := do
  match original, actual with
  | .error expected, some (.error observed) =>
      require (label ++ "-exact-error") (expected == observed)
  | .ok expected, some (.ok observed) =>
      let result ← decodeResult observed
      require (label ++ "-exact-type") (psKernelExprEqual expected.fst result)
      require (label ++ "-fresh-counter") (expected.snd.nextFresh == observed.fst.nextFresh)
  | _, none => throw (IO.userError ("unexpected infer-only fallback: " ++ label))
  | _, _ => throw (IO.userError ("infer-only result mismatch: " ++ label))

private def regression : IO Unit := do
  let initial ← expectPublic
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let idType := PsKernelExpr.forallE (nm "A") s1
    (.forallE (nm "x") (.bvar 0) (.bvar 1) .default) .default
  let metadataType := PsKernelExpr.forallE (nm "A") s1
    (.mdata 9 (.mdata 8
      (.forallE (nm "x") (.bvar 0) (.bvar 1) .default))) .default
  let letType := PsKernelExpr.forallE (nm "A") s1
    (.letE (nm "T") s1 (.bvar 0)
      (.forallE (nm "x") (.bvar 0) (.bvar 1) .default) false) .default
  let mut session := initial
  let mut arena := psKernelExprV2PagedEmpty
  let mut declarations : List PsKernelExprV2DeclarationRef := []
  for (name, type, unsafeValue) in [
      (nm "inferId", idType, false), (nm "inferHidden", metadataType, false),
      (nm "inferLetType", letType, false), (nm "inferUnsafe", s1, true)] do
    let (next, typeId) ← expect (psKernelExprV2PagedImportIntoChecked arena type)
    let admitted ← expectPublic
      (psKernelV1AdmitDeclaration session
        (.axiomDecl (PsKernelAxiomInfo.mk (PsKernelConstantBase.mk name [] type) unsafeValue)))
    session := admitted.session
    arena := next
    declarations := psKernelDagDeclarationsAfterAdmission
      (.axiomDecl (PsKernelDagConstantBase.mk name [] typeId) unsafeValue) declarations
  let (next, partialType) ← expect (psKernelExprV2PagedImportIntoChecked arena s1)
  let (next, partialValue) ← expect (psKernelExprV2PagedImportIntoChecked next s0)
  let partialName := nm "inferPartial"
  let partialInfo := PsKernelDefinitionInfo.mk
    (PsKernelConstantBase.mk partialName [] s1) s0 .abbrevHint .partialDef
  let partialAdmitted ← expectPublic
    (psKernelV1AdmitDeclaration session (.definitionDecl partialInfo))
  session := partialAdmitted.session
  arena := next
  declarations := psKernelDagDeclarationsAfterAdmission
    (.definitionDecl
      (PsKernelDagDefinition.mk (PsKernelDagConstantBase.mk partialName [] partialType)
        partialValue .abbrevHint .partialDef)) declarations
  let idFn := PsKernelExpr.const (nm "inferId") []
  let missing := PsKernelExpr.mvar (nm "notCheckedArgument")
  let terms : List (String × PsKernelExpr) := [
    ("sort", s0), ("metadata", .mdata 5 (.mdata 6 s0)),
    ("lambda", .lam (nm "x") s1 (.bvar 0) .default),
    ("unchecked-lambda-domain", .lam (nm "x") missing s0 .implicit),
    ("forall", idType),
    ("one-argument", .app idFn s0),
    ("two-arguments", .app (.app idFn s0) missing),
    ("lazy-metadata-domain", .app (.app (.const (nm "inferHidden") []) s0) missing),
    ("lazy-let-domain", .app (.app (.const (nm "inferLetType") []) s0) missing),
    ("unused-let-value", .letE (nm "x") s1 missing s0 false),
    ("unused-let-type", .letE (nm "x") missing s0 s0 true),
    ("dependent-let-body", .letE (nm "x") s1 s0 (.bvar 0) false),
    ("nested-shadow", .lam (nm "x") s1
      (.letE (nm "x") s1 (.bvar 0) (.bvar 0) false) .default),
    ("unsafe-constant", .const (nm "inferUnsafe") []),
    ("partial-constant", .const partialName []),
    ("bad-head", .app s0 missing), ("loose", .bvar 0),
    ("unknown-local", .fvar (nm "absent")), ("metavariable", missing),
    ("nat-literal", .lit (.nat 17)), ("string-literal", .lit (.str "type"))]
  for (label, term) in terms do
    let (owning, root) ← expect (psKernelExprV2PagedImportIntoChecked arena term)
    for fuel in [0,1,2,3,4,5,6,8,12,16,32,64] do
      for maxDepth in [0,1,2] do
        for entryDepth in [0,13,14,15,16] do
          let base := psKernelKernelSessionChecker session [] .safe
          let scalar := { base.context with
            maxRecDepth := maxDepth
            recDepth := entryDepth }
          let original := psKernelCheckerInfer fuel scalar psKernelCheckerStateEmpty term
          let actual := psKernelExprV2TryInferStateWithFuel fuel
            (psKernelExprV2CheckContextEmpty scalar) (initialState owning declarations) root
          compare (label ++ "-" ++ toString fuel ++ "-" ++
            toString maxDepth ++ "-" ++ toString entryDepth) original actual
  -- An inference-only judgment cannot authorize a checked expression.
  let unchecked := PsKernelExpr.app (.app idFn s0) missing
  let (owning, root) ← expect (psKernelExprV2PagedImportIntoChecked arena unchecked)
  let base := psKernelKernelSessionChecker session [] .safe
  let context := psKernelExprV2CheckContextEmpty base.context
  let some (.ok inferred) := psKernelExprV2TryInferStateWithFuel 64
      context (initialState owning declarations) root
    | throw (IO.userError "inference-only skipped-argument fixture failed")
  require "infer-only-app-cache-populated" (!(psKernelExprV2WhnfCacheEntries inferred.fst.inferOnly).isEmpty)
  require "infer-only-cannot-populate-checked-cache" (psKernelExprV2WhnfCacheEntries inferred.fst.checkedInfer).isEmpty
  compare "warm-infer-cache-is-not-checked-authorization"
    (psKernelCheckerCheck 64 base.context psKernelCheckerStateEmpty unchecked)
    (psKernelExprV2TryCheckStateWithFuel 64 context inferred.fst root)
  let warmScalar := { base.context with maxRecDepth := 1, recDepth := 0 }
  let warmOriginal ← expect
    (psKernelCheckerInfer 64 warmScalar psKernelCheckerStateEmpty unchecked)
  let some (.ok warmDirect) := psKernelExprV2TryInferStateWithFuel 64
      (psKernelExprV2CheckContextEmpty warmScalar) (initialState owning declarations) root
    | throw (IO.userError "inference-only warm fixed-policy fixture failed")
  for fuel in [0,1,64] do
    for entryDepth in [0,15,16] do
      let scalar := { warmScalar with recDepth := entryDepth }
      compare ("warm-entry-" ++ toString fuel ++ "-" ++ toString entryDepth)
        (psKernelCheckerInfer fuel scalar warmOriginal.snd unchecked)
        (psKernelExprV2TryInferStateWithFuel fuel
          (psKernelExprV2CheckContextEmpty scalar) warmDirect.fst root)
  let tooLarge := PsKernelExpr.lit (.nat (2^128))
  let (owning, root) ← expect (psKernelExprV2PagedImportIntoChecked arena tooLarge)
  let limited := { base.context with maxNatSize := 1 }
  compare "infer-only-retains-nat-limit"
    (psKernelCheckerInfer 64 limited psKernelCheckerStateEmpty tooLarge)
    (psKernelExprV2TryInferStateWithFuel 64
      (psKernelExprV2CheckContextEmpty limited) (initialState owning declarations) root)
  IO.println "PSC1_V2_DAG_INFER_ONLY: PASS"

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


private def officialInferenceParity : IO Unit := do
  let official ← Lean.mkEmptyEnvironment
  let initial ← expectPublic
    (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let checker := psKernelKernelSessionChecker initial [] .safe
  let identity := PsKernelExpr.lam (nm "x") s1 (.bvar 0) .default
  let terms : List PsKernelExpr := [
    s0, identity,
    .forallE (nm "A") s1 (.forallE (nm "x") (.bvar 0) (.bvar 1) .default) .default,
    .letE (nm "x") s1 s0 (.bvar 0) false,
    .app identity s0, .mdata 7 (.app identity s0)]
  for term in terms do
    let some officialTerm := inferOfficialExpr term
      | throw (IO.userError "official infer-only fixture conversion failed")
    let officialType ←
      match Lean.Kernel.check official {} officialTerm with
      | .ok type => pure type
      | .error _ => throw (IO.userError "official Lean rejected valid inference fixture")
    let (arena, root) ← expect (psKernelExprV2PagedImportChecked term)
    let some (.ok inferred) := psKernelExprV2TryInferStateWithFuel 64
        (psKernelExprV2CheckContextEmpty checker.context) (initialState arena []) root
      | throw (IO.userError "valid inference fixture did not use direct DAG path")
    let type ← decodeResult inferred
    let some officialActual := inferOfficialExpr type
      | throw (IO.userError "official inferred-type conversion failed")
    require "official-Lean-inferred-type"
      (match Lean.Kernel.isDefEq official {} officialType officialActual with
       | .ok value => value | .error _ => false)
  IO.println "PSC1_V2_DAG_OFFICIAL_INFER_ONLY: PASS"

def main : IO Unit := do
  regression
  officialInferenceParity
