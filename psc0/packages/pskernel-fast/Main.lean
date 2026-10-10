import PSKernelFast.EvalPrototype

open PSKernelFast

/-! Focused G0 runtime checks. NOT soundness or Lean compatibility evidence. -/

def check (condition : Bool) (description : String) : IO Unit := do
  unless condition do
    throw (IO.userError description)

def main : IO Unit := do
  let term : RawExpr :=
    .lam (Name.simple "x") (.sort .zero) (.app (.bvar 0) (.const (Name.simple "x") [])) .default

  let (root, store) ←
    match encodeClosed term with
    | .ok result => pure result
    | .error err =>
        throw (IO.userError s!"failed to encode closed expression: {repr err}")

  check (store.nodes.size == 5) "incorrect hash-consed node count"

  let decoded ←
    match decodeClosed store root with
    | .ok value => pure value
    | .error err =>
        throw (IO.userError s!"failed to decode expression: {repr err}")
  check (decoded == term) "round-trip erased expression differs"

  let (secondRoot, secondStore) ←
    match encode term store with
    | .ok result => pure result
    | .error err =>
        throw (IO.userError s!"re-encoding failed: {repr err}")
  check (secondRoot == root) "identical syntax did not share its root ID"
  check (secondStore.nodes.size == store.nodes.size)
    "re-encoding allocated duplicate nodes"

  match encodeClosed (.bvar 0) with
  | .error .unscopedInput => pure ()
  | _ => throw (IO.userError "unbound variable was not rejected")

  match store.intern (.app (root + 100) root) with
  | .error .invalidChild => pure ()
  | _ => throw (IO.userError "invalid child reference was not rejected")

  match decodeClosed store (root + 100) with
  | .error (.invalidHandle _) => pure ()
  | _ => throw (IO.userError "invalid handle was not rejected")

  match decodeFuel 0 store root with
  | .error .decodeBudget => pure ()
  | _ => throw (IO.userError "exhausted decode budget was not rejected")

  let u : Level := .param (Name.simple "u")
  let symbolic : RawExpr := .sort (.imax .zero u)
  let successor : RawExpr := .sort (.succ (.imax .zero u))
  let universeTerm : RawExpr := .pi (Name.simple "p") symbolic successor .implicit
  let (universeRoot, universeStore) ←
    match encodeClosed universeTerm with
    | .ok result => pure result
    | .error err =>
        throw (IO.userError s!"symbolic universe syntax was rejected: {repr err}")
  check (universeStore.nodes.size == 3)
    "different imax and successor expressions were incorrectly interned as one"
  match decodeClosed universeStore universeRoot with
  | .ok restored =>
      check (restored == universeTerm) "symbolic universe round-trip changed syntax"
  | .error err =>
      throw (IO.userError s!"failed to decode symbolic universe: {repr err}")

  let betaTerm : RawExpr :=
    .app (.lam (Name.simple "v") (.sort .zero) (.bvar 0) .default) (.const (Name.simple "identity") [])
  check (betaTerm.scoped 0) "beta input is unexpectedly unscoped"
  let betaValue ←
    match whnfFuel 64 (.term betaTerm []) with
    | .ok result => pure result
    | .error err => throw (IO.userError s!"beta closure failed: {repr err}")
  match betaValue with
  | .term (.const name _) _ =>
      check (name == Name.simple "identity") "beta closure evaluation returned the wrong head"
  | _ => throw (IO.userError "beta closure did not reach rigid head")

  let letTerm : RawExpr :=
    .letE (Name.simple "l") (.sort .zero) (.const (Name.simple "letResult") []) (.bvar 0) false
  let letValue ←
    match whnfFuel 64 (.term letTerm []) with
    | .ok result => pure result
    | .error err => throw (IO.userError s!"let closure failed: {repr err}")
  match letValue with
  | .term (.const name _) _ =>
      check (name == Name.simple "letResult") "let closure returned wrong head"
  | _ => throw (IO.userError "let closure did not expose a rigid head")

  let neutralTerm : RawExpr :=
    .app (.const (Name.simple "f") []) (.const (Name.simple "argument") [])
  match whnfFuel 64 (.term neutralTerm []) with
  | .ok (.app (.term (.const (.str .anonymous "f") _) _) _) => pure ()
  | _ => throw (IO.userError "stuck neutral application did not retain spine")

  match whnfFuel 0 (.term betaTerm []) with
  | .error .reductionBudget => pure ()
  | _ => throw (IO.userError "zero reduction fuel did not fail closed")

  let largeSyntax : RawExpr :=
    .letE (Name.simple "let")
      (.sort (.max (.param (Name.simple "u")) (.succ .zero)))
      (.lit (.nat 27))
      (.mdata "inert" (.proj (Name.simple "P") 0
        (.app (.const (Name.simple "Mk") [.imax (.param (Name.simple "u")) .zero])
          (.bvar 0)))) false
  let (extendedId, extendedStore) ←
    match encodeClosed largeSyntax with
    | .ok result => pure result
    | .error err => throw (IO.userError s!"extended raw syntax failed: {repr err}")
  match decodeClosed extendedStore extendedId with
  | .ok restored =>
      check (restored == largeSyntax) "extended constructors lost syntax data"
  | .error err => throw (IO.userError s!"extended syntax decode failed: {repr err}")

  match encodeClosed (.fvar (Name.simple "untrusted")) with
  | .error .forbiddenMeta => pure ()
  | _ => throw (IO.userError "untrusted free variable was not declined")
  match encodeClosed (.mvar (Name.simple "hole")) with
  | .error .forbiddenMeta => pure ()
  | _ => throw (IO.userError "metavariable was not declined")
  match encodeClosed (.sort (.imax .zero (.mvar (Name.simple "U")))) with
  | .error .forbiddenMeta => pure ()
  | _ => throw (IO.userError "metavariable level was not declined")
  match encodeClosed (.lam (Name.simple "x") (.sort .zero) (.bvar 1) .default) with
  | .error .unscopedInput => pure ()
  | _ => throw (IO.userError "invalid binder index was not declined")

  IO.println "PSKernel-Fast G3: expanded Lean raw syntax, scope, meta guards and closures passed (NOT proof checking)"
