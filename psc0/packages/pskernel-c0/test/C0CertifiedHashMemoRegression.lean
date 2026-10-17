import Ps.KernelCore.Runtime.Acceleration.CertifiedHashMemo

/-!
Exact source hash conformance. The large shared DAG is intentionally
checked against a closed-form recurrence, never expanded by the old
exponential source-hash oracle. Lean separately proves the equation for
every source expression in psKernelC0ExactMemoizedExprHash_source.
-/

def c0HashMemoMakeShared (base : PsKernelExpr) (depth : Nat) : PsKernelExpr :=
  (List.range depth).foldl (fun x (_ : Nat) => .app x x) base

def c0HashMemoExpected (base : Nat) (depth : Nat) : Nat :=
  (List.range depth).foldl
    (fun x (_ : Nat) => psKernelCacheMix (psKernelCacheMix 26 x) x)
    base

def c0HashMemoCheck (expr : PsKernelExpr) : IO Unit := do
  let source := psKernelExprHash expr
  let cached := psKernelC0ExactMemoizedExprHash expr
  let _eq : psKernelC0ExactMemoizedExprHash expr =
      psKernelExprHash expr :=
    psKernelC0ExactMemoizedExprHash_source expr
  if cached != source then
    throw (IO.userError "certified memo hash differs from historical exact source hash")

/-- Real Array proof bodies contain many application nodes whose first
four shape layers coincide even though deeper function heads differ.
Force the exact same kind of bucket expansion without any library proof
special-casing or unchecked equality. -/
def c0HashMemoDeepHead (i : Nat) : PsKernelExpr :=
  let head : PsKernelExpr := .const (.num .anonymous i) []
  let arg : PsKernelExpr := .lit (.nat 1)
  .app (.app (.app (.app head arg) arg) arg) arg

def c0HashMemoNameErasureCollision (i : Nat) : PsKernelExpr :=
  .lam (.num .anonymous i) (.sort .zero) (.bvar 0) .default

def main : IO Unit := do
  let one : PsKernelName := .str .anonymous "one"
  let two : PsKernelName := .str .anonymous "two"
  let type : PsKernelExpr := .sort (.succ .zero)
  let f : PsKernelExpr := .fvar one
  let x : PsKernelExpr := .bvar 0
  let base : PsKernelExpr := .app (.const one [.zero]) (.lit (.nat 2))
  let all : List PsKernelExpr := [
    .bvar 0, .bvar 13, .fvar one, .mvar one,
    .sort .zero, .sort (.max .zero (.succ .zero)),
    .const two [.zero, .succ .zero],
    .lit (.nat 7), .lit (.str "é"),
    .app f base,
    .lam one type (.app x f) .default,
    .forallE one type (.app f x) .implicit,
    .letE two type f (.app x x) false,
    .letE one type (.lit (.nat 3)) f true,
    .mdata 17 (.app f (.mdata 11 base)),
    .proj two 1 (.const two []),
    c0HashMemoMakeShared base 12,
    c0HashMemoMakeShared (.app base f) 15,
    .app (c0HashMemoMakeShared base 11)
         (c0HashMemoMakeShared (.mdata 3 base) 11)
  ]
  for expression in all do
    c0HashMemoCheck expression

  -- Fifty distinct deep function heads have the identical depth-4
  -- hash bucket and exceed the optional secondary-index threshold.
  -- A full source hash differs when a deep head differs, so false memo
  -- hits would be detected. Lambda names separately stress exact-syntax
  -- collision handling although binder display names are hash-erased.
  let repeatedShallow : List PsKernelExpr :=
    (List.range 50).map c0HashMemoDeepHead
  let firstShallow := psKernelC0MemoShapeHash 4 (c0HashMemoDeepHead 0)
  for term in repeatedShallow do
    if psKernelC0MemoShapeHash 4 term != firstShallow then
      throw (IO.userError "synthetic depth-four memo collision was not formed")
  let sameBinderShape : List PsKernelExpr :=
    (List.range 50).map c0HashMemoNameErasureCollision
  let root : PsKernelExpr := .const (.str .anonymous "hashMemoRoot") []
  let collisionDAG :=
    (repeatedShallow ++ sameBinderShape).foldl
      (fun acc e => .app acc e) root
  c0HashMemoCheck collisionDAG
  IO.println "C0_CERTIFIED_HASH_MEMO secondary_collision_upgrade=source_exact threshold_exceeded=true"

  -- 26 shared parent levels represent over 134 million tree nodes.
  -- Computing the *historical* pure hash here would expand the full
  -- tree, so compare the memo result to an independent numerical fold.
  let depth := 26
  let big := c0HashMemoMakeShared base depth
  let expected := c0HashMemoExpected (psKernelExprHash base) depth
  let before ← IO.monoNanosNow
  let memoized := psKernelC0ExactMemoizedExprHash big
  let after ← IO.monoNanosNow
  if memoized != expected then
    throw (IO.userError "large shared hash memo differs from exact hash recurrence")
  IO.println s!"C0_CERTIFIED_HASH_MEMO small_source=pass collision_safety=source_proved shared_depth={depth} memo_ms={(after - before)/1000000} exact_source_proof=Lean"
