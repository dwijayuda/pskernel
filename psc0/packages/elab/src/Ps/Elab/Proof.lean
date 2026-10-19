import Ps.Elab.Elimination
import Ps.Elab.ProofApply
import Ps.Elab.Equality
import Ps.Elab.Postponed
import Ps.Elab.ProofTerm
import Ps.Elab.RCases
import Ps.Elab.ProofIntermediate
import Ps.Elab.ProofClassical
import Ps.Elab.ProofLogical
import Ps.Elab.ProofExt

def psProofExact (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) (refine : Bool) :
    Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let source ← psProofSource scope context source
  let value ← psProofWithTermSynthesis elaborate context
    (fun current => elaborate current source (some target))
  if !refine && psExprHasTermMeta (psMetaInstantiate value.context.metaContext value.term) then
    throw (.proof "exact left unresolved holes")
  let pending := psProofFreshGoals context.metaContext.nextId value.context
  let state ← psProofAssign (psProofUpdate state value.context) goal.id value.term
  psProofNormalize { state with goals := pending ++ state.goals.drop 1 }

def psProofAssumption (state : PsProofState) : Except PsElabError PsProofState := do
  let (goal, context, _) ← psProofMain state
  for declaration in context.localContext.declarations do
    match psProofAssign state goal.id (.fvar (psLocalDeclId declaration)) with
    | .ok next => return ← psProofNormalize next
    | .error error => if psElabErrorIsResource error then throw error else pure ()
  throw (.proof "assumption did not match a local declaration")

def psProofReflexivity (state : PsProofState) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let equation ← psElabEquationView context target (.mvar goal.id)
  let unified := psUnify context.environment context.localContext context.metaContext
    equation.left equation.right
  if unified.resourceExceeded then throw .fuelExhausted
  if !unified.success then throw (.proof "rfl requires definitionally equal sides")
  let context := psElabContextWithMeta context unified.context
  let value := psLogicRefl equation.level equation.type equation.left
  let next ← psProofAssign (psProofUpdate state context) goal.id value
  psProofNormalize next

def psProofConstructor (state : PsProofState) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let head := (psExprAppView (psWhnf context.environment context.metaContext context.localContext target)).head
  let .constE name _ := head | throw (.proof "constructor requires an inductive target")
  let some info := psEnvironmentFindInductive context.environment name
    | throw (.proof "constructor requires an inductive target")
  for constructor in info.constructors do
    let attempt := do
      let (context, term) ← psElabResolvedReference context (.global constructor)
      let value ← psElabResolvedTerm context term none
      let value ← psProofApplyTerm 4096 value target
      psProofApplied state goal state.context.metaContext.nextId value
    match attempt with
    | .ok next => return next
    | .error error => if psElabErrorIsResource error then throw error else pure ()
  throw (.proof "no constructor applies to the target")

def psProofLocalValue (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (nameSyntax : PsSyntaxName) (annotation : Option PsSyntaxTerm)
    (source : PsSyntaxTerm) (reducible : Bool) : Except PsElabError PsProofState := do
  let (_, context, _) ← psProofMain state
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let annotation ← annotation.mapM (psProofSource scope context)
  let source ← psProofSource scope context source
  let value ← psProofWithTermSynthesis elaborate context
    (fun current => psElabLocalValue elaborate current annotation source)
  psProofLocal state name value reducible

def psProofChange (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let source ← psProofSource scope context source
  let annotation ← psElabType elaborate context source
  let unified := psUnify annotation.context.environment annotation.context.localContext
    annotation.context.metaContext target annotation.type
  if unified.resourceExceeded then throw .fuelExhausted
  if !unified.success then throw (.proof "change requires a definitionally equal target")
  let context := psElabContextWithMeta annotation.context unified.context
  let fresh := psMetaFresh context.metaContext context.localContext
    (psMetaInstantiate context.metaContext annotation.type) .syntheticOpaque
  let .mvar child := fresh.expr | throw (.proof "invalid fresh goal")
  let state := psProofUpdate state (psElabContextWithMeta context fresh.context)
  let state ← psProofAssign state goal.id fresh.expr
  psProofNormalize { state with goals := { id := child, tag := goal.tag } :: state.goals.drop 1 }

-- Each candidate owns its source resolution and unification snapshot. A failed
-- show attempt cannot constrain a later goal. The selected goal moves first.
def psProofShow (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) : Except PsElabError PsProofState := do
  for goal in state.goals do
    let selected := { state with goals := goal :: state.goals.filter (fun other => other.id != goal.id) }
    match psProofChange elaborate scope selected source with
    | .ok next => return next
    | .error error => if psElabErrorIsResource error then throw error else pure ()
  throw (.proof "show did not match any goal")

-- A closed, fuel-bounded analogue of Lean RC4's introductory
-- get_elem_tactic/trivial rules. Attempts run against immutable proof states.
-- The recursion discharges *every* constructor-produced goal before success:
-- unification progress is never confused with a completed proof.
-- Arithmetic/omega and user-extensible tactics are separate pending rules.
-- A small proof-producing natural-order solver. It recognizes only the
-- checked Nat.le relation after definitional normalization. Closed bounds
-- use the reflection theorem; symbolic reasoning composes checked order
-- lemmas. No Boolean answer is treated as a proof, and failure is explicit.
def psProofNatLeView (context : PsElabContext) (type : PsExpr) :
    Option (PsExpr × PsExpr) :=
  let view := psExprAppView
    (psWhnf context.environment context.metaContext context.localContext type)
  match view.head, view.args with
  | .constE name [], [left, right] =>
    if psNameEq name (psNameAppendStr psNatName "le") then some (left, right)
    else none
  | _, _ => none

def psProofNatCall (name : String) (args : List PsExpr) : PsExpr :=
  psLogicApply (.constE ((name.splitOn ".").foldl psNameAppendStr psNatName) []) args

def psProofNatPrevious (expr : PsExpr) : Option PsExpr :=
  match expr with
  | .lit (.natural (n + 1)) => some (.lit (.natural n))
  | .app (.constE name []) previous =>
    if psNameEq name psNatSuccName then some previous else none
  | _ => none

def psProofNatBound (context : PsElabContext) (fuel : Nat)
    (left right : PsExpr) : Option PsExpr := do
  let fuel + 1 := fuel | none
  let norm := psWhnf context.environment context.metaContext context.localContext
  let left := norm left
  let right := norm right
  if psExprHasTermMeta left || psExprHasTermMeta right then none else
  if psExprAlphaEq left right then return psProofNatCall "le.refl" [left] else
  match left, right with
  | .lit (.natural a), .lit (.natural b) =>
    if a <= b then
      return psLogicApply
        (.constE (psNameAppendStr (psRootName "PsStandard") "natBleReflects") [])
        [left, right]
    else none
  | .lit (.natural 0), _ => return psProofNatCall "zero_le" [right]
  | _, _ =>
    match psProofNatPrevious left, psProofNatPrevious right with
    | some a, some b =>
      let proof ← psProofNatBound context fuel a b
      return psProofNatCall "succ_le_succ" [a, b, proof]
    | none, some b =>
      let proof ← psProofNatBound context fuel left b
      return psLogicApply
        (.constE (psNameAppendStr (psNameAppendStr psNatName "le") "step") [])
        [left, b, proof]
    | _, _ => none

-- Bounded graph search over the local order facts. Each endpoint is visited
-- once, avoiding recursive branching over the same transitivity chains.
-- Every edge carries its checked proof and retains the original local scope.
def psProofNatChain (context : PsElabContext) (fuel : Nat)
    (start target : PsExpr) (facts : List (PsExpr × PsExpr × PsExpr))
    (pending : List (PsExpr × PsExpr)) (visited : List PsExpr) : Option PsExpr := do
  let fuel + 1 := fuel | none
  let (endpoint, proof) :: rest := pending | none
  if visited.any (psExprAlphaEq endpoint) then
    psProofNatChain context fuel start target facts rest visited
  else
    if let some tail := psProofNatBound context 64 endpoint target then
      return psProofNatCall "le_trans" [start, endpoint, target, proof, tail]
    let next := facts.filterMap fun (left, right, evidence) =>
      if visited.any (psExprAlphaEq right) then none else do
        let reach ← psProofNatBound context 64 endpoint left
        let edge := psProofNatCall "le_trans" [endpoint, left, right, reach, evidence]
        return (right, psProofNatCall "le_trans" [start, endpoint, right, proof, edge])
    psProofNatChain context fuel start target facts (rest ++ next) (endpoint :: visited)

def psProofNaturalBounds (state : PsProofState) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let some (left, right) := psProofNatLeView context target
    | throw (.proof "not a natural-order goal")
  let facts := context.localContext.declarations.filterMap fun declaration => do
    let (a, b) ← psProofNatLeView context (psLocalDeclType declaration)
    return (a, b, PsExpr.fvar (psLocalDeclId declaration))
  let some proof := psProofNatChain context 64 left right facts
      [(left, psProofNatCall "le.refl" [left])] []
    | throw (.proof "natural-order facts do not establish this bound")
  psProofNormalize (← psProofAssign state goal.id proof)

def psProofIndexValiditySolve (fuel : Nat) (state : PsProofState) :
    Except PsElabError PsProofState := do
  match fuel with
  | 0 => throw (.proof "get_elem_tactic proof-search budget exhausted")
  | remaining + 1 =>
    let state ← psProofNormalize state
    if state.goals.isEmpty then return state
    let mut solved : Option PsProofState := none
    for candidate in [psProofAssumption, psProofReflexivity, psProofNaturalBounds] do
      if solved.isNone then
        match candidate state with
        | .ok progressed => solved := some progressed
        | .error error => if psElabErrorIsResource error then throw error else pure ()
    match solved with
    | some progressed => psProofIndexValiditySolve remaining progressed
    | none =>
      -- Constructor may introduce obligations: those obligations are not
      -- admitted until this same checked search closes the whole branch.
      match psProofConstructor state with
      | .ok progressed => psProofIndexValiditySolve remaining progressed
      | .error error =>
        if psElabErrorIsResource error then throw error
        throw (.proof "get_elem_tactic could not establish index validity; supply xs[i]'h or use xs[i]?")

def psProofIndexValidity (state : PsProofState) : Except PsElabError PsProofState := do
  let state ← psProofNormalize state
  let some goal := state.goals.head? | return state
  -- A generated validity proof may not capture/solve unrelated sibling goals.
  let saved := state.goals.drop 1
  let solved ← psProofIndexValiditySolve 64 { state with goals := [goal] }
  if !solved.goals.isEmpty then
    throw (.proof "get_elem_tactic left unresolved constructor obligations")
  psProofNormalize { solved with goals := saved }

def psProofRun (elaborate : PsElaborator) (scope : PsSyntaxProofScope) (fuel : Nat)
    (state : PsProofState) (tactics : List PsSyntaxTactic) : Except PsElabError PsProofState := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match tactics with
    | [] => psProofNormalize state
    | tactic :: rest =>
      let state ← psProofNormalize state
      let next ← match tactic with
        | .exactE source refine _ => psProofExact elaborate scope state source refine
        | .applyE source _ => psProofApply elaborate scope state source
        | .exfalso _ => psProofExfalso state
        | .decide _ => psProofDecide state
        | .byCases name proposition _ => psProofByCases elaborate scope state name proposition
        | .extE patterns depth span => psProofExt elaborate scope state patterns depth span
        | .localE name type source reducible _ =>
          psProofLocalValue elaborate scope state name type source reducible
        | .change source select _ =>
          if select then psProofShow elaborate scope state source
          else psProofChange elaborate scope state source
        | .eliminate source induction _ => psProofEliminate elaborate scope state source induction
        | .rcasesE targets pattern span => psProofRCases elaborate scope state targets pattern span
        | .rintroE patterns type _ => psProofRIntro elaborate scope state patterns type
        | .obtainE pattern type values span => psProofObtain elaborate scope state pattern type values span
        | .caseE tag names body _ => do
          let (selected, saved) ← psProofSelectCase state tag names
          let finished ← psProofRun elaborate scope fuel selected body
          if !finished.goals.isEmpty then throw (.proof "case left unsolved goals")
          pure { finished with goals := saved }
        | .suffices name type value _ => psProofSuffices elaborate scope state name type value
        | .classicalE body _ => do
          let context ← psElabClassicalContext state.context
          let finished ← psProofRun elaborate scope fuel { state with context } body
          pure { finished with context :=
            { finished.context with instances := state.context.instances } }
        | .intros names _ => psProofIntros state names
        | .intro names _ =>
          if names.isEmpty then psProofIntro state none
          else names.foldlM (fun current name => psProofIntro current (some name)) state
        | .assumption _ => psProofAssumption state
        | .indexValidity _ => psProofIndexValidity state
        | .reflexivity _ => psProofReflexivity state
        | .constructor _ | .constructorFirst _ => psProofConstructor state
        | .each body any _ => do
          let mut current := state
          let mut goals := []
          let mut succeeded := false
          for goal in state.goals do
            if (psMetaFindAssignment current.context.metaContext goal.id).isSome then continue
            match psProofRun elaborate scope fuel { current with goals := [goal] } body with
            | .ok next =>
              current := next
              goals := goals ++ next.goals
              succeeded := true
            | .error error =>
              if psElabErrorIsResource error || !any then throw error
              goals := goals ++ [goal]
          if any && !succeeded then throw (.proof "tactic failed on all goals")
          pure { current with goals }
        | .focus body mustClose _ => do
          let goal :: saved := state.goals | throw (.proof "no goal to focus")
          let focused ← psProofRun elaborate scope fuel { state with goals := [goal] } body
          if mustClose && !focused.goals.isEmpty then throw (.proof "focused branch left unsolved goals")
          pure { focused with goals := focused.goals ++ saved }
      psProofRun elaborate scope fuel next rest

def psElabProof (elaborate : PsElaborator) (context : PsElabContext)
    (tactics : List PsSyntaxTactic) (scope : PsSyntaxProofScope) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let some target := expected | throw (.proof "by requires an expected type")
  let fresh := psMetaFresh context.metaContext context.localContext target .syntheticOpaque
  let .mvar root := fresh.expr | throw (.proof "invalid fresh goal")
  let state ← psProofRun elaborate scope 4096 {
    context := psElabContextWithMeta context fresh.context, goals := [{ id := root }] } tactics
  if !state.goals.isEmpty then throw (.proof "unsolved goals")
  let value := psMetaInstantiate state.context.metaContext fresh.expr
  if psExprHasTermMeta value then throw (.proof "unresolved proof")
  let checked ← psElabResolvedTerm (psElabLeaveScope context state.context) value expected
  if !scope.abstractProofs then return checked
  let target := psMetaInstantiate checked.context.metaContext target
  let level ← psElabExpressionSort checked.context target
  if !psLevelEquivalent level .zero then return checked
  if let .fvar _ := checked.term then return checked
  -- Source names contain only string components; this numeric identity is
  -- allocated by the actual checked proof and retained in its source batch.
  let boundary := PsName.num psElabExposedProofBoundaryName root
  let context := { checked.context with
    proofBoundariesRev := boundary :: checked.context.proofBoundariesRev }
  psElabResolvedTerm context
    (.letE boundary target checked.term (.bvar 0)) (some target)
