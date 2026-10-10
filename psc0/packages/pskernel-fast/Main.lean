import PSKernelFast.Quote
import PSKernelFast.TinyTyping

open PSKernelFast

/-! Focused G0 runtime checks. NOT soundness or Lean compatibility evidence. -/

def check (condition : Bool) (description : String) : IO Unit := do
  unless condition do
    throw (IO.userError description)

/-- Deterministic well-scoped raw-expression family for evaluator regression.
    The terms are not claimed to be Lean-well-typed. -/
def generatedClosed : Nat → Nat → RawExpr
  | 0, seed => .const (.num (Name.simple "leaf") (seed % 13)) []
  | Nat.succ rest, seed =>
      let child := generatedClosed rest (seed / 2 + 7)
      let x := Name.simple "x"
      let y := Name.simple "y"
      let ty : RawExpr := .sort .zero
      match seed % 8 with
      | 0 => .app (.lam x ty (.bvar 0) .default) child
      | 1 => .letE x ty child (.bvar 0) false
      | 2 => .app (.const (Name.simple "f") []) child
      | 3 => .mdata "neutral-metadata" child
      | 4 =>
          .lam x ty (.app (.const (Name.simple "g") []) (.bvar 0)) .implicit
      | 5 =>
          .app (.lam x ty (.lam y ty (.bvar 1) .default) .default) child
      | 6 =>
          .app (.app (.lam x ty (.lam y ty (.bvar 0) .default) .default)
            child) (.const (Name.simple "other") [])
      | _ => .proj (Name.simple "P") (seed % 3) child

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

  let a : RawExpr := .const (Name.simple "a") []
  let b : RawExpr := .const (Name.simple "b") []
  let x : Name := Name.simple "x"
  let y : Name := Name.simple "y"
  let ty : RawExpr := .sort .zero

  let cases : List RawExpr := [
    betaTerm,
    letTerm,
    neutralTerm,
    .app (.lam x ty (.app (.const (Name.simple "f") []) (.bvar 0)) .default) a,
    .app (.app (.lam x ty (.lam y ty (.bvar 1) .default) .default) a) b,
    .app (.app (.lam x ty (.lam y ty (.bvar 0) .default) .default) a) b,
    .app (.lam x ty (.app (.bvar 0) b) .default) (.lam y ty (.bvar 0) .default),
    .letE x ty (.lam y ty (.bvar 0) .default)
      (.app (.bvar 0) a) false,
    .mdata "informational" betaTerm,
    .lam x ty (.letE y ty a (.bvar 0) false) .default
  ]
  for e in cases do
    match referenceAgreesWithClosure e with
    | .ok true => pure ()
    | .ok false =>
        throw (IO.userError s!"G4 reference/closure mismatch on {repr e}")
    | .error err =>
        throw (IO.userError s!"G4 evaluator unexpectedly declined {repr e}: {repr err}")

  match referenceAgreesWithClosure (.bvar 0) with
  | .error .unscopedInput => pure ()
  | _ => throw (IO.userError "G4 comparison failed to reject loose variable")

  match referenceWhnfFuel 0 betaTerm with
  | .error .reductionBudget => pure ()
  | _ => throw (IO.userError "reference WHNF ignored zero fuel")

  let sort0 : RawExpr := .sort .zero
  let sort1 : RawExpr := .sort (.succ .zero)
  let sort2 : RawExpr := .sort (.succ (.succ .zero))
  let typeIdentity : RawExpr := .lam x sort1 (.bvar 0) .default
  match tinyInferClosed 128 [] sort0 with
  | .ok typeResult => check (typeResult == sort1) "Sort 0 must have type Sort 1"
  | .error err => throw (IO.userError s!"Sort 0 inference failed: {repr err}")
  match tinyInferClosed 128 [] typeIdentity with
  | .ok (.pi _ dom codomain _) =>
      check (dom == sort1 && codomain == sort1)
        "Lambda type has incorrect Pi domain/codomain"
  | result => throw (IO.userError s!"lambda typing unexpected: {repr result}")

  let appliedIdentity : RawExpr := .app typeIdentity sort0
  match tinyInferClosed 128 [] appliedIdentity with
  | .ok inferred =>
      check (inferred == sort1) "identity application should have type Sort 1"
  | .error err => throw (IO.userError s!"identity application declined: {repr err}")

  let polymorphicIdentity : RawExpr :=
    .lam (Name.simple "A") sort1
      (.lam x (.bvar 0) (.bvar 0) .default) .default
  match tinyInferClosed 128 [] polymorphicIdentity with
  | .ok (.pi _ firstDom (.pi _ secondDom secondCodomain _) _) =>
      check (firstDom == sort1) "outer dependent Pi domain changed"
      check (secondDom == (.bvar 0)) "dependent inner domain was shifted"
      check (secondCodomain == (.bvar 1)) "dependent inner codomain was shifted"
  | result => throw (IO.userError s!"dependent identity typing failed: {repr result}")

  let wellTypedLet : RawExpr :=
    .letE x sort1 sort0 (.bvar 0) false
  match tinyInferClosed 128 [] wellTypedLet with
  | .ok inferred => check (inferred == sort1) "let result type is incorrect"
  | .error err => throw (IO.userError s!"typed let declined: {repr err}")

  match tinyInferClosed 128 [] (.app typeIdentity sort1) with
  | .error .typeMismatch => pure ()
  | other => throw (IO.userError s!"mismatched application accepted: {repr other}")

  match tinyInferClosed 128 [] (.app sort0 sort0) with
  | .error .expectedPi => pure ()
  | other => throw (IO.userError s!"applying a non-function was accepted: {repr other}")

  match tinyInferClosed 128 [] (.sort (.param (Name.simple "u"))) with
  | .error .invalidUniverseParam => pure ()
  | other => throw (IO.userError s!"undeclared level param allowed: {repr other}")
  match tinyInferClosed 128 [Name.simple "u"] (.sort (.param (Name.simple "u"))) with
  | .ok (.sort (.succ (.param _))) => pure ()
  | other => throw (IO.userError s!"declared universe parameter declined: {repr other}")

  match tinyInferClosed 0 [] sort0 with
  | .error .budget => pure ()
  | other => throw (IO.userError s!"type checker accepted with zero fuel: {repr other}")

  match tinyInferClosed 128 [] (.const (Name.simple "unspecified") []) with
  | .error .unsupported => pure ()
  | other => throw (IO.userError s!"untrusted constant accepted: {repr other}")

  match tinyInferClosed 128 [] (.app typeIdentity sort2) with
  | .error .typeMismatch => pure ()
  | other => throw (IO.userError s!"wrong universe type accepted: {repr other}")

  for seed in [:256] do
    let candidate := generatedClosed 6 seed
    match referenceAgreesWithClosure candidate with
    | .ok true => pure ()
    | .ok false =>
        throw (IO.userError s!"generated evaluator disagreement, seed={seed}")
    | .error err =>
        throw (IO.userError s!"generated evaluator error, seed={seed}: {repr err}")
    let (id, store) ←
      match encodeClosed candidate with
      | .ok output => pure output
      | .error err =>
          throw (IO.userError s!"generated scope/interner error, seed={seed}: {repr err}")
    match decodeClosed store id with
    | .ok restored =>
        check (restored == candidate) s!"generated interner changed seed={seed}"
    | .error err =>
        throw (IO.userError s!"generated reification error, seed={seed}: {repr err}")

  IO.println "PSKernel-Fast G7: 256 deterministic closed-term interner/evaluator cases passed (NOT Lean kernel acceptance)"
