import PSKernelFast.EvalPrototype
import PSKernelFast.Substitution

/-!
# G4 closure reification for bounded evaluator comparisons only

Quote a lazily evaluated syntax view to an ordinary raw expression.
This materializes closure environments by exact lexical index lookup.
It is a test/reference bridge, not a checked proof-conversion result.
-/

namespace PSKernelFast

mutual
  /-- Reify a closure, preserving neutral applications. -/
  def quoteClosureFuel (fuel : Nat) (view : Closure) : Except Failure RawExpr :=
    match fuel with
    | 0 => .error .decodeBudget
    | Nat.succ smaller =>
        match view with
        | .term expr env => quoteExprFuel smaller expr env 0
        | .app fn arg => do
            let rawFn ← quoteClosureFuel smaller fn
            let rawArg ← quoteClosureFuel smaller arg
            pure (.app rawFn rawArg)

  /--
  Reify raw syntax within a lexical environment. Under binder depth d,
  indices below d are local binders and remain unchanged; other indices
  refer to environment slots and are lifted by d before insertion.
  -/
  def quoteExprFuel (fuel : Nat) (expr : RawExpr)
      (env : List Closure) (depth : Nat) : Except Failure RawExpr :=
    match fuel with
    | 0 => .error .decodeBudget
    | Nat.succ smaller =>
        match expr with
        | .bvar i =>
            if i < depth then pure (.bvar i)
            else
              match env[i - depth]? with
              | some value => do
                  let raw ← quoteClosureFuel smaller value
                  pure (liftBVars depth 0 raw)
              | none => .error .unscopedInput
        | .app fn arg => do
            let rawFn ← quoteExprFuel smaller fn env depth
            let rawArg ← quoteExprFuel smaller arg env depth
            pure (.app rawFn rawArg)
        | .lam n ty body bi => do
            let rawTy ← quoteExprFuel smaller ty env depth
            let rawBody ← quoteExprFuel smaller body env (depth + 1)
            pure (.lam n rawTy rawBody bi)
        | .pi n ty body bi => do
            let rawTy ← quoteExprFuel smaller ty env depth
            let rawBody ← quoteExprFuel smaller body env (depth + 1)
            pure (.pi n rawTy rawBody bi)
        | .letE n ty value body nd => do
            let rawTy ← quoteExprFuel smaller ty env depth
            let rawValue ← quoteExprFuel smaller value env depth
            let rawBody ← quoteExprFuel smaller body env (depth + 1)
            pure (.letE n rawTy rawValue rawBody nd)
        | .mdata m e => do
            let raw ← quoteExprFuel smaller e env depth
            pure (.mdata m raw)
        | .proj n i e => do
            let raw ← quoteExprFuel smaller e env depth
            pure (.proj n i raw)
        | e => pure e
end

/--
Compare two intentionally incomplete beta/zeta evaluators on the same
closed, meta-free raw syntax. True means exact raw-result agreement here,
NOT kernel DefEq, successful typing or proof acceptance.
-/
def referenceAgreesWithClosure (term : RawExpr) :
    Except Failure Bool := do
  if !term.scoped 0 then throw .unscopedInput
  if term.hasUntrustedMeta then throw .forbiddenMeta
  let expected ← referenceWhnfFuel 512 term
  let closure ← whnfFuel 512 (.term term [])
  let actual ← quoteClosureFuel 4096 closure
  pure (expected == actual)

end PSKernelFast
