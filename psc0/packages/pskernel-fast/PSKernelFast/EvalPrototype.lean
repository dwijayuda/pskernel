import PSKernelFast.Core

/-!
# G2: toy fuel-bounded closure *view*, NOT kernel WHNF

This representation lets beta and zeta extend an environment in O(1) instead
of building a fully substituted RawExpr. Stuck applications are retained as
closure applications over potentially different environments.

It intentionally does not implement Lean definitional equality, typing,
universe reductions, recursor rules, proof irrelevance, eta or admission.
Only G2 prototype tests may call this; it is not a trusted proof checker.
-/

namespace PSKernelFast

inductive Closure where
  | term (expr : RawExpr) (env : List Closure)
  | app (fn arg : Closure)
deriving Inhabited

/--
Partial *head* evaluator for a tiny untyped beta/let experiment.
A missing lexical binding and a resource limit are hard errors.
A rigid neutral application is retained without forcing its argument.
-/
def whnfFuel (fuel : Nat) (view : Closure) : Except Failure Closure :=
  match fuel with
  | 0 => .error .reductionBudget
  | Nat.succ remaining =>
      match view with
      | .term (.bvar i) env =>
          match env[i]? with
          | some replacement => whnfFuel remaining replacement
          | none => .error .unscopedInput
      | .term (.letE _ _ value body _) env =>
          whnfFuel remaining (.term body (.term value env :: env))
      | .term (.app fn arg) env =>
          whnfFuel remaining (.app (.term fn env) (.term arg env))
      | .app fn arg =>
          match whnfFuel remaining fn with
          | .error err => .error err
          | .ok (.term (.lam _ _ body _) env) =>
              whnfFuel remaining (.term body (arg :: env))
          | .ok reducedFn => .ok (.app reducedFn arg)
      | value => .ok value

end PSKernelFast
