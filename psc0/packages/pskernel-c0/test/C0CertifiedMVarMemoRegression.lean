import Ps.KernelCore.Admission.Declaration.Validation

/-!
Proof-bearing DAG metavariable screening regression. All comparisons are
against the unchanged source psKernelExprHasMVar; proof theorem also covers
every input not enumerated here. No kernel admission is performed.
-/

def c0MVarDag (n : Nat) (leaf : PsKernelExpr) : PsKernelExpr :=
  match n with
  | 0 => leaf
  | k + 1 =>
      let child := c0MVarDag k leaf
      .app child child

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "mv"
  let ty : PsKernelExpr := .sort .zero
  let cases : List PsKernelExpr := [
    .bvar 0,
    .fvar name,
    .mvar name,
    .sort (.mvar name),
    .const name [.mvar name],
    .lit (.nat 4),
    .app (.const name []) (.mvar name),
    .lam name ty (.mvar name) .default,
    .forallE name (.sort (.mvar name)) ty .default,
    .letE name ty (.mvar name) (.bvar 0) false,
    .mdata 1 (.mvar name),
    .proj name 0 (.mvar name),
    c0MVarDag 8 ty,
    c0MVarDag 8 (.mvar name),
    c0MVarDag 12 (.sort (.mvar name))
  ]
  for expr in cases do
    let expected := psKernelExprHasMVar expr
    if psKernelC0MemoizedHasMVar expr != expected ||
        psKernelC0AdaptiveHasMVar expr != expected then
      throw (IO.userError "memoized MVar membership differs from original source")
  -- The combined declaration screen must retain the old error
  -- precedence with direct certified MVar and FVar checks. It may never
  -- decide positivity from a syntactic hash or a cache hit alone.
  for expr in cases do
    let expected : Except String Unit :=
      if psKernelExprHasMVar expr then
        .error "declaration has metavariables"
      else if psKernelExprHasFVar expr then
        .error "declaration has free variables"
      else .ok ()
    match psKernelCheckNoMVarNoFVar expr, expected with
    | .ok _, .ok _ => pure ()
    | .error actual, .error original =>
        if actual != original then
          throw (IO.userError "declaration screening altered historical error precedence")
    | _, _ =>
        throw (IO.userError "declaration screening changed accepted/rejected status")
  -- 2^24 *expanded* occurrences share only 25 physical source nodes.
  -- The type-level source theorem guarantees equivalence on this input too.
  let large := c0MVarDag 24 ty
  if psKernelC0MemoizedHasMVar large ||
      psKernelC0AdaptiveHasMVar large then
    throw (IO.userError "shared DAG with no metavariables was misclassified")
  IO.println "C0_MVAR_DAG source_equal=Lean_proved checked_cases=15 shared_depth=24 combined_MVar_FVar_error_order=pass no_admission=true"
