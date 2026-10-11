import PSKernelFast.DagReduction

namespace PSKernelFast

private def require (condition : Bool) (description : String) : IO Unit :=
  if condition then pure () else throw <| IO.userError description

/--
  Differential check: both evaluators consume precisely the same *decoded*
  closed DAG term and must return the independently specified WHNF result.
-/
private def checkWHNF (name : String) (original expected : RawExpr) : IO Unit := do
  let (root, store) ←
    match encodeClosed 2000 original with
    | .ok v => pure v
    | .error err => throw <| IO.userError s!"{name}: encode failed: {repr err}"
  let decoded ←
    match decodeForEvaluation store root (store.nodes.size + 10) with
    | .ok v => pure v
    | .error err => throw <| IO.userError s!"{name}: decode failed: {repr err}"
  require (decoded == original) s!"{name}: DAG input round-trip failed"
  match eagerWHNF 400 decoded with
  | .error err => throw <| IO.userError s!"{name}: eager failed: {repr err}"
  | .ok eager => do
      require (eager == expected) s!"{name}: eager result disagreed with reference expectation"
      match lazyWHNF 5000 5000 decoded with
      | .error err => throw <| IO.userError s!"{name}: lazy failed: {repr err}"
      | .ok lazy =>
          require (lazy == expected) s!"{name}: lazy result disagreed with reference expectation"
          require (lazy == eager) s!"{name}: eager/lazy diverged"
          match dagWHNFFromCheckedInput store root (store.nodes.size + 10) 5000 5000 with
          | .error err => throw <| IO.userError s!"{name}: DAG lazy failed: {repr err}"
          | .ok dag =>
              require (dag == expected) s!"{name}: DAG lazy differs from expected"
              require (dag == eager) s!"{name}: DAG lazy differs from eager"

/--
  Bounded, deterministic generated closed beta terms. This is a finite
  differential corpus, not a proof of full evaluator completeness.
-/
private def boundedRawTerms : Nat → Nat → List RawExpr
  | 0, depth =>
      if depth == 0 then
        [.sort 0, .sort 1]
      else
        [.sort 0, .sort 1, .bvar 0, .bvar (depth - 1)]
  | n + 1, depth =>
      let atoms := boundedRawTerms 0 depth
      let previous := (boundedRawTerms n depth).take 9
      let bodies := (boundedRawTerms n (depth + 1)).take 9
      atoms ++
        bodies.map (fun body => .lam (.sort 0) body) ++
        previous.flatMap (fun fn =>
          previous.map (fun arg => .app fn arg))

private def generatedDifferential : IO Unit := do
  let corpus := boundedRawTerms 4 0
  let mut checked : Nat := 0
  let mut bothExhausted : Nat := 0
  for term in corpus do
    let (root, store) ←
      match encodeClosed 1000 term with
      | .ok value => pure value
      | .error err => throw <| IO.userError s!"generated encode: {repr err}"
    let decoded ←
      match decodeForEvaluation store root (store.nodes.size + 10) with
      | .ok value => pure value
      | .error err => throw <| IO.userError s!"generated decode: {repr err}"
    require (decoded == term) "generated raw/DAG roundtrip mismatch"
    match eagerWHNF 100 decoded, lazyWHNF 5000 5000 decoded,
        dagWHNFOnValidatedGraph store root 5000 5000 with
    | .ok eager, .ok lazy, .ok dag =>
        require (eager == lazy && lazy == dag)
          "generated eager/tree-lazy/DAG-lazy WHNF mismatch"
        checked := checked + 1
    | .error .betaBudgetExhausted, .error .machineBudgetExhausted,
        .error .machineBudgetExhausted =>
        bothExhausted := bothExhausted + 1
    | _, _, _ =>
        throw <| IO.userError "generated 3-engine disagreement or resource failure"
  require (checked > 40) "generated differential coverage unexpectedly too small"
  IO.println s!"G2 bounded generated corpus: equal={checked}, both_exhausted={bothExhausted}"
  
/-- Root-level test executable. No checker/admission code is exposed. -/
def reductionSmoke : IO Unit := do
  let id := rawId
  let constFn : RawExpr := .lam (.sort 0) (.lam (.sort 0) (.bvar 1))
  let secondFn : RawExpr := .lam (.sort 0) (.lam (.sort 0) (.bvar 0))
  let applyCaptured : RawExpr :=
    .lam (.sort 0) (.lam (.sort 0) (.app (.bvar 1) (.bvar 0)))
  checkWHNF "sort" (.sort 0) (.sort 0)
  checkWHNF "id-sort" (.app id (.sort 7)) (.sort 7)
  checkWHNF "id-lambda" (.app id id) id
  checkWHNF "const-capture" (.app constFn (.sort 9))
    (.lam (.sort 0) (.sort 9))
  checkWHNF "second-binder" (.app secondFn (.sort 9))
    (.lam (.sort 0) (.bvar 0))
  checkWHNF "captured-application" (.app applyCaptured id)
    (.lam (.sort 0) (.app id (.bvar 0)))
  checkWHNF "multiple-beta" (.app (.app constFn (.sort 9)) (.sort 11)) (.sort 9)
  checkWHNF "neutral-do-not-normalize-argument"
    (.app (.sort 1) (.app id (.sort 7)))
    (.app (.sort 1) (.app id (.sort 7)))
  checkWHNF "duplicating-body" (.app (.lam (.sort 0) (.app (.bvar 0) (.bvar 0))) id) id
  checkWHNF "long-beta-chain" (identityChain 60 (.sort 13)) (.sort 13)

  let selfApply : RawExpr := .lam (.sort 0) (.app (.bvar 0) (.bvar 0))
  let omega : RawExpr := .app selfApply selfApply
  match encodeClosed 30 omega with
  | .error err => throw <| IO.userError s!"omega: invalid closed test input: {repr err}"
  | .ok (id, store) =>
    match decodeForEvaluation store id 100 with
    | .error err => throw <| IO.userError s!"omega: decode failed: {repr err}"
    | .ok decoded => do
        match eagerWHNF 40 decoded with
        | .error .betaBudgetExhausted => pure ()
        | _ => throw <| IO.userError "omega eager did not exhaust beta budget"
        match lazyWHNF 200 500 decoded with
        | .error .machineBudgetExhausted => pure ()
        | _ => throw <| IO.userError "omega lazy did not exhaust machine budget"
        match dagWHNFFromCheckedInput store id 100 200 500 with
        | .error .machineBudgetExhausted => pure ()
        | _ => throw <| IO.userError "omega DAG lazy did not exhaust machine budget"

  match decodeForEvaluation {} 777 10 with
  | .error (.invalidStore (.invalidHandle 777)) => pure ()
  | _ => throw <| IO.userError "forged DAG handle reached evaluation"

  generatedDifferential
  let forgedOpen : Store := { nodes := #[.bvar 0] }
  match decodeForEvaluation forgedOpen 0 10 with
  | .error (.invalidStore .invalidScope) => pure ()
  | _ => throw <| IO.userError "out-of-scope forged DAG term was not rejected"
  match dagWHNFFromCheckedInput forgedOpen 0 10 100 100 with
  | .error (.invalidStore .invalidScope) => pure ()
  | _ => throw <| IO.userError "DAG evaluator ignored scope preflight"
  let forgedNested : Store := {
    nodes := #[.sort 0, .bvar 2, .lam 0 1]
  }
  match decodeForEvaluation forgedNested 2 10 with
  | .error (.invalidStore .invalidScope) => pure ()
  | _ => throw <| IO.userError "nested escaped de Bruijn index was not rejected"

  IO.println "PSKernel-Fast V3 G2: eager/lazy beta WHNF differential corpus PASS"
end PSKernelFast

def main : IO Unit := PSKernelFast.reductionSmoke
