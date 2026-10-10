import Lean
import Ps.KernelCore.API.Reference

/-!
Audit elaborated executable definitions, including callbacks and admission.
Reject accidental synthesis of the cached default anywhere reachable from the
fixed reference API. Raw cache operations must occur only behind their policy
gates. This is a structural audit, not a substitute for a soundness theorem.
-/
private def referenceConstants : Lean.Expr → List Lean.Name
  | .const n _ => [n]
  | .app f a => referenceConstants f ++ referenceConstants a
  | .lam _ t b _ | .forallE _ t b _ => referenceConstants t ++ referenceConstants b
  | .letE _ t v b _ => referenceConstants t ++ referenceConstants v ++ referenceConstants b
  | .mdata _ b | .proj _ _ b => referenceConstants b
  | _ => []

open Lean Elab Command in
run_cmd do
  let env ← getEnv
  let mut todo : Array Name := #[
    ``psKernelReferenceCheckExpression, ``psKernelReferenceWhnf,
    ``psKernelReferenceIsDefEq, ``psKernelReferenceCheckDeclaration,
    ``psKernelReferenceAdmitDeclaration, ``psKernelReferenceAdmitChecked]
  let raw : Array Name := #[``psKernelExprMapGet, ``psKernelExprMapInsert,
    ``psKernelExprPairSetContains, ``psKernelExprPairSetInsert]
  let gates : Array Name := #[``psKernelSemanticCacheGet, ``psKernelSemanticCacheInsert,
    ``psKernelSemanticCacheContains, ``psKernelSemanticCacheInsertPair]
  let mut seen : NameSet := {}
  let mut count := 0
  while !todo.isEmpty do
    let n := todo.back!
    todo := todo.pop
    if seen.contains n then continue
    seen := seen.insert n
    let some info := env.find? n | throwError "Missing reference dependency: {n}"
    let some body := info.value? | continue
    count := count + 1
    for dep in referenceConstants body do
      if dep == ``psKernelCachedCachePolicy then
        throwError "Reference path falls back to cached policy: {n}"
      if raw.contains dep && !gates.contains n then
        throwError "Reference path bypasses cache policy: {n} -> {dep}"
      if dep.toString.startsWith "psKernel" || dep.toString.startsWith "PsKernel" then
        todo := todo.push dep
  logInfo m!"PSKERNEL_REFERENCE_POLICY: PASS definitions={count} cachedFallbacks=0"
