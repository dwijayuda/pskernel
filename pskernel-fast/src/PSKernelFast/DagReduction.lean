import PSKernelFast.Reduction

/-!
Third non-authoritative G2 evaluator: a call-by-name closure machine that
reads directly from the interned node store rather than reconstructed RawExpr.

Only dagWHNFFromCheckedInput validates an untrusted store. The lower-level
dagWHNFOnValidatedGraph is a benchmark experiment and must NEVER become a
trusted proof-acceptance API without a sealed validated store and proof.
-/

namespace PSKernelFast

inductive DagClosure where
  | mk (termId : Nat) (env : List DagClosure)

inductive DagHead where
  | lam (domain body : Nat) (env : List DagClosure)
  | sort (level : Nat) (pending : List DagClosure)

/-- Environment-based head evaluation, with checked handle bounds at each read. -/
def dagLazyRun : Nat → Store → DagClosure → List DagClosure →
    Except EvalError DagHead
  | 0, _, _, _ => .error .machineBudgetExhausted
  | fuel + 1, store, .mk termId env, pending =>
      match store.nodes[termId]? with
      | none => .error (.invalidStore (.invalidHandle termId))
      | some (.bvar index) =>
          match env[index]? with
          | some captured => dagLazyRun fuel store captured pending
          | none => .error (.unboundVariable index)
      | some (.app fn arg) =>
          dagLazyRun fuel store (.mk fn env) ((.mk arg env) :: pending)
      | some (.lam domain body) =>
          match pending with
          | [] => .ok (.lam domain body env)
          | arg :: rest => dagLazyRun fuel store (.mk body (arg :: env)) rest
      | some (.sort level) => .ok (.sort level pending)

/-- Exact de Bruijn readback for a closure whose term is a DAG handle. -/
def dagReadback : Nat → Nat → Store → DagClosure → Except EvalError RawExpr
  | 0, _, _, _ => .error .readbackBudgetExhausted
  | fuel + 1, depth, store, .mk termId env =>
      match store.nodes[termId]? with
      | none => .error (.invalidStore (.invalidHandle termId))
      | some (.bvar index) =>
          if index < depth then
            .ok (.bvar index)
          else
            match env[index - depth]? with
            | none => .error (.unboundVariable index)
            | some captured => do
                let raw ← dagReadback fuel 0 store captured
                pure (liftFrom depth 0 raw)
      | some (.sort level) => .ok (.sort level)
      | some (.app fn arg) => do
          let rawFn ← dagReadback fuel depth store (.mk fn env)
          let rawArg ← dagReadback fuel depth store (.mk arg env)
          pure (.app rawFn rawArg)
      | some (.lam domain body) => do
          let rawDomain ← dagReadback fuel depth store (.mk domain env)
          let rawBody ← dagReadback fuel (depth + 1) store (.mk body env)
          pure (.lam rawDomain rawBody)

/-- Quote a head, preserving inert application spines without forcing arguments. -/
def dagReadbackHead (fuel : Nat) (store : Store) :
    DagHead → Except EvalError RawExpr
  | .lam domain body env =>
      dagReadback fuel 0 store (.mk
        -- The lambda's original node may be interned but readback of its
        -- parts avoids allocating a new trusted node or assuming uniqueness.
        -- Construct the raw lambda explicitly from separately validated IDs.
        domain env) >>= fun rawDomain => do
          let rawBody ← dagReadback fuel 1 store (.mk body env)
          pure (.lam rawDomain rawBody)
  | .sort level pending => do
      let mut result : RawExpr := .sort level
      for arg in pending do
        let rawArg ← dagReadback fuel 0 store arg
        result := .app result rawArg
      return result

/--
  Engine-only entry: caller must have validated its entire store and root
  using decodeForEvaluation. It does not confer checking/admission authority.
-/
def dagWHNFOnValidatedGraph (store : Store) (root machineFuel quoteFuel : Nat) :
    Except EvalError RawExpr := do
  let head ← dagLazyRun machineFuel store (.mk root []) []
  dagReadbackHead quoteFuel store head

/-- Fail-closed host entry: decode first, check scopedness, then run on handles. -/
def dagWHNFFromCheckedInput
    (store : Store) (root decodeFuel machineFuel quoteFuel : Nat) :
    Except EvalError RawExpr := do
  let _ ← decodeForEvaluation store root decodeFuel
  dagWHNFOnValidatedGraph store root machineFuel quoteFuel

end PSKernelFast
