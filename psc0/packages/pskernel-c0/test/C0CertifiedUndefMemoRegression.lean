import Ps.KernelCore.Admission.Declaration.Validation

/-!
Regression for source-exact first undefined universe parameter selection in
DAG syntax. The independent Lean theorem covers ALL expressions and allowed
parameter lists, not just the fixtures below.
-/

def c0UndefDag (n : Nat) (leaf : PsKernelExpr) : PsKernelExpr :=
  match n with
  | 0 => leaf
  | k + 1 =>
      let shared := c0UndefDag k leaf
      .app shared shared

def c0UndefEq (a b : Option PsKernelName) : Bool :=
  match a, b with
  | none, none => true
  | some x, some y => psKernelNameEq x y
  | _, _ => false

def main : IO Unit := do
  let u : PsKernelName := .str .anonymous "u"
  let v : PsKernelName := .str .anonymous "v"
  let f : PsKernelName := .str .anonymous "f"
  let zero : PsKernelExpr := .sort .zero
  let openU : PsKernelExpr := .sort (.param u)
  let openV : PsKernelExpr := .sort (.param v)
  let list : List (PsKernelExpr × List PsKernelName) := [
    (zero, []),
    (.const f [], []),
    (.const f [.param u], []),
    (.const f [.param u], [u]),
    (.const f [.param v, .param u], [u]),
    (.app openU openV, []),
    (.app openU openV, [u]),
    (.lam f zero openV .default, []),
    (.forallE f openV zero .default, []),
    (.letE f zero openU openV false, []),
    (.mdata 7 openU, []),
    (.proj f 0 openV, []),
    (c0UndefDag 8 zero, []),
    (c0UndefDag 8 openU, []),
    (c0UndefDag 8 openU, [u]),
    (c0UndefDag 10 (.app openU openV), [u])
  ]
  for (expr, allowed) in list do
    let source := psKernelFindUndefExprLevelParam expr allowed
    let memo := psKernelC0MemoizedFindUndefExprLevelParam expr allowed
    let adaptive := psKernelC0AdaptiveFindUndefExprLevelParam expr allowed
    if !c0UndefEq memo source || !c0UndefEq adaptive source then
      throw (IO.userError "certified DAG first undefined universe name differs from source")
  -- First-offender order is semantic diagnostic data and must remain stable.
  match psKernelC0AdaptiveFindUndefExprLevelParam (.app openU openV) [] with
  | some name =>
      if !psKernelNameEq name u then
        throw (IO.userError "the first invalid universe parameter was reordered")
  | none => throw (IO.userError "the first invalid universe parameter disappeared")
  match psKernelC0AdaptiveFindUndefExprLevelParam (.app openU openV) [u] with
  | some name =>
      if !psKernelNameEq name v then
        throw (IO.userError "universe membership ignored the allowed list")
  | none => throw (IO.userError "the second invalid universe parameter disappeared")
  -- The shared expression contains 2^24 expanded occurrences but only 25
  -- unique nodes. Never evaluate the exponential raw predicate in this test:
  -- psKernelC0MemoizedFindUndefExprLevelParam_source is the all-input proof.
  let huge := c0UndefDag 24 zero
  if !c0UndefEq (psKernelC0MemoizedFindUndefExprLevelParam huge []) none ||
      !c0UndefEq (psKernelC0AdaptiveFindUndefExprLevelParam huge []) none then
    throw (IO.userError "closed shared DAG has an invented undefined parameter")
  IO.println "C0_UNDEF_DAG all_input_source=Lean_proved cases=16 first_offender_preserved=true shared_depth=24 allowed_list_owned=true"
