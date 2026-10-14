import Ps.KernelCore.Architecture.AuditedAssumptions

/-!
E.4AI: real admitted Lean 4.35-safe definitions through a full
source-proved independent public β/ζ/δ WHNF recursion, with separate
cache policies and unchanged trusted source admission.
-/
def c0DeltaName (s : String) : PsKernelName := .str .anonymous s

def c0DeltaDef (name : PsKernelName) (value : PsKernelExpr) :
    PsKernelDefinitionInfo := {
  base := {
    name := name
    levelParams := []
    type := .sort (.succ .zero)
  }
  value := value
  hints := .abbrevHint
  safety := .safe
}

def main : IO Unit := do
  let binder := c0DeltaName "deltaBinder"
  let a := c0DeltaName "deltaAliasA"
  let b := c0DeltaName "deltaAliasB"
  let c := c0DeltaName "deltaAliasC"
  let type : PsKernelExpr := .sort (.succ .zero)
  let value : PsKernelExpr := .sort .zero
  let id : PsKernelExpr := .lam binder type (.bvar 0) .default
  let defs : List (PsKernelDefinitionInfo) := [
    c0DeltaDef a (.const b []),
    c0DeltaDef b (.const c []),
    c0DeltaDef c (.app id value)
  ]
  -- Definitions are source-admitted in dependency order. Source checking
  -- and signature/axiom policy, not candidate WHNF, establish admission.
  let mut env := psKernelEnvironmentEmpty
  for declaration in defs.reverse do
    env ← match psKernelAddDefinition 4096 env declaration
        4096 psKernelLeanNatMaxSizeDefault with
      | .ok next => pure next
      | .error reason =>
          throw (IO.userError ("source definition admission failed: " ++ reason))
  let source := psKernelMkCheckerSession env [] .safe
    4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "recursive delta work genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "recursive delta work certificate failed")

  let root : PsKernelExpr := .const a []
  let betaDelta : PsKernelExpr := .app id root
  let zetaDelta : PsKernelExpr :=
    .letE binder type root (.bvar 0) false
  let metadata : PsKernelExpr := .mdata 15 (.mdata 23 betaDelta)
  for expr in [root, betaDelta, zetaDelta, metadata] do
    let some (reduced, nextState) :=
        psKernelC0RecursiveDeltaWhnfWithFuel
          4096 source.context source.state expr
      | throw (IO.userError "independent delta/beta/zeta normalization declined")
    if !psKernelExprEqual reduced value then
      throw (IO.userError "delta/beta/zeta result mismatched expected term")
    let receipt ← match psKernelC0CertifiedWorkWhnfDeltaOwned
        4096 work expr with
      | .ok proof => pure proof
      | .error e => throw (IO.userError ("qualified delta WHNF failed: " ++ e))
    let _exact : psKernelC0CertifiedWorkWhnf 4096 work expr =
        .ok receipt.val := receipt.property
    let (sourceValue, _) ← match psKernelCheckerWhnf
        4096 source.context source.state expr with
      | .ok next => pure next
      | .error e => throw (IO.userError ("source WHNF failed: " ++ e))
    if !psKernelExprEqual sourceValue reduced ||
        !psKernelExprEqual receipt.val.fst sourceValue then
      throw (IO.userError "delta whole-source differential mismatch")
    if (psKernelExprMapGet nextState.whnf a).isSome then
      throw (IO.userError "unrelated source cache key unexpectedly inserted")

  let some (deltaValue, deltaState) :=
      psKernelC0RecursiveDeltaWhnfWithFuel
        4096 source.context source.state root
    | throw (IO.userError "multi-hop delta source refinement declined")
  if !psKernelExprEqual deltaValue value ||
      (psKernelExprMapGet deltaState.whnf root).isNone ||
      (psKernelExprMapGet deltaState.whnf (.const b [])).isNone ||
      (psKernelExprMapGet deltaState.whnf (.const c [])).isNone then
    throw (IO.userError "intermediate delta-expanded public WHNF cache lost")
  -- Strictly unqualified app-headed definition/recursor paths fall back.
  let unsupported : PsKernelExpr := .app (.const a []) value
  if (psKernelC0RecursiveDeltaWhnfWithFuel
      4096 source.context source.state unsupported).isSome then
    throw (IO.userError "unknown application falsely gained delta authority")
  for fuel in [0, 1, 2, 3] do
    if (psKernelC0RecursiveDeltaWhnfWithFuel
        fuel source.context source.state root).isSome then
      throw (IO.userError "delta chain ignored source reduction budget")
  match psKernelC0CertifiedWorkWhnfDeltaOwned
      0 work root, psKernelC0CertifiedWorkWhnf 0 work root with
  | .error a, .error b =>
      if a != b then
        throw (IO.userError "zero-fuel source error changed")
  | _, _ => throw (IO.userError "zero fuel unexpectedly accepted delta")

  let blocked : PsKernelCheckerSession := {
    source with context :=
      { source.context with recDepth := 1000000, maxRecDepth := 1 }
  }
  if (psKernelC0RecursiveDeltaWhnfWithFuel
      4096 blocked.context blocked.state root).isSome then
    throw (IO.userError "delta bypassed maxRecDepth")
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "blocked delta genesis failed")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "blocked delta certified work failed")
  match psKernelC0CertifiedWorkWhnfDeltaOwned 4096 blockedWork root,
    psKernelC0CertifiedWorkWhnf 4096 blockedWork root with
  | .error observed, .error expected =>
      if observed != expected then
        throw (IO.userError "source delta recursion error changed")
  | _, _ => throw (IO.userError "delta bypassed source recursion policy")

  let some genesis := psKernelC0AuditedSourceBegin
      4096 psKernelLeanNatMaxSizeDefault []
    | throw (IO.userError "audited delta genesis failed")
  let mut audited := genesis
  for declaration in defs.reverse do
    audited ← match psKernelC0AuditedSourceAdmit
        4096 audited (.definition declaration) with
      | .ok next => pure next
      | .error reason =>
          throw (IO.userError ("audited delta definition failed: " ++ reason))
  let (auditedValue, after) ← match psKernelC0AuditedSourceWhnf
      4096 audited betaDelta with
    | .ok result => pure result
    | .error e => throw (IO.userError ("audited delta source WHNF failed: " ++ e))
  if !psKernelExprEqual auditedValue value ||
      !(psKernelC0HistoryAxiomSignatures after.trusted.history).isEmpty ||
      !(psKernelC0HistoryTrustCapabilities after.trusted.history).isEmpty then
    throw (IO.userError "delta WHNF changed trusted axiom/capability history")
  let _axioms := psKernelC0AuditedSourceAxiomsApproved after
  let _capabilities := psKernelC0AuditedSourceCapabilitiesApproved after
  IO.println "C0_DELTA_WHNF nested_delta_beta_zeta_source_refinement=pass"
  IO.println "C0_DELTA_WHNF intermediate_public_core_cache_policy=pass"
  IO.println "C0_DELTA_WHNF resource_negative_audited_history=pass"
