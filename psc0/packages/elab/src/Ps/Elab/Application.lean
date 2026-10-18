import Ps.Elab.Basic
import Ps.Elab.Postponed

def psBinderAcceptsExplicitArgument (binder : PsBinderInfo) : Bool :=
  match binder with
  | .explicit => true
  | _ => false

def psBinderIsStrictImplicit (binder : PsBinderInfo) : Bool :=
  match binder with
  | .strictImplicit => true
  | _ => false

def psBinderIsInstanceImplicit (binder : PsBinderInfo) : Bool :=
  match binder with
  | .instanceImplicit => true
  | _ => false

-- A consumer may own a finite source header and retain each actual argument
-- exactly once before rearranging it. Ordinary applications leave this off.
structure PsElabApplicationCapture where
  remaining : Nat
  valuesRev : List PsExpr := []
  abstractionsRev : List PsMetaAbstraction := []

structure PsElabApplicationResult (α : Type := PsSyntaxTerm) where
  result : PsElabTermResult
  constraintsRev : List PsSyntheticConstraint
  capture : Option PsElabApplicationCapture := none
  remainingPositions : List α := []
  remainingNames : List (PsName × α) := []

def psSyntaxTermListIsEmpty
    (values : List PsSyntaxTerm) : Bool :=
  match values with
  | [] =>
      true
  | _ :: _ =>
      false

abbrev PsElabNamedArguments := List (Prod PsName PsSyntaxTerm)

def psElabTakeNamed {α : Type} (name : PsName) (args : List (PsName × α)) :
    Prod (Option α) (List (PsName × α)) :=
  match args with
  | [] => (none, [])
  | (key, value) :: rest =>
    if psNameEq key name then (some value, rest)
    else
      let found := psElabTakeNamed name rest
      (found.fst, (key, value) :: found.snd)

def psElabCallArguments
    (args : List (Prod (Option PsSyntaxName) PsSyntaxTerm))
    (positionsRev : List PsSyntaxTerm) (namesRev : PsElabNamedArguments) :
    Except PsElabError (Prod (List PsSyntaxTerm) PsElabNamedArguments) := do
  match args with
  | [] => return (positionsRev.reverse, namesRev.reverse)
  | (none, value) :: rest =>
    if !namesRev.isEmpty then throw (.invalidArgument "positional argument after named argument")
    psElabCallArguments rest (value :: positionsRev) namesRev
  | (some label, value) :: rest =>
    let some name := psSyntaxNameToName label | throw .emptyName
    if (psElabTakeNamed name namesRev).fst.isSome then
      throw (.invalidArgument "duplicate named argument")
    psElabCallArguments rest positionsRev ((name, value) :: namesRev)

def psElabApplyValue (current argument : PsElabTermResult) (body : PsExpr) :
    PsElabTermResult :=
  { context := argument.context
    term := .app current.term argument.term
    type := psExprInstantiate1 body argument.term }

def psElabApplyCapturedValue (current argument : PsElabTermResult) (body : PsExpr)
    (capture : Option PsElabApplicationCapture) :
    PsElabTermResult × Option PsElabApplicationCapture :=
  match capture with
  | none => (psElabApplyValue current argument body, none)
  | some capture =>
    let type := psMetaInstantiate argument.context.metaContext argument.type
    let name := psNameAppendNum (psRootName "_psc0CallArgument") argument.context.localContext.nextId
    let pushed := psLocalPushLet argument.context.localContext name type argument.term
    let reference := PsExpr.fvar pushed.id
    let retained := { argument with
      context := { argument.context with localContext := pushed.context }, term := reference }
    (psElabApplyValue current retained body, some {
      remaining := capture.remaining - 1
      valuesRev := reference :: capture.valuesRev
      abstractionsRev := .letE pushed.id name type argument.term :: capture.abstractionsRev })

-- Defaults are closed with the declaration telescope as optParam applications.
-- Instantiating a preceding codomain therefore substitutes preceding arguments
-- into its default without looking up source names in the caller's scope.
def psElabDefaultValue (context : PsElabContext) (domain : PsExpr) : Option PsExpr :=
  match psMetaInstantiate context.metaContext domain with
  | .app (.app (.constE name _) _) value =>
    if psNameEq name psOptParamName then some value else none
  | _ => none

def psElabHasLooseBound (term : PsExpr) (depth : Nat := 0) : Bool :=
  match term with
  | .bvar index => index >= depth
  | .app fn value => psElabHasLooseBound fn depth || psElabHasLooseBound value depth
  | .lam _ domain body _ | .forallE _ domain body _ =>
    psElabHasLooseBound domain depth || psElabHasLooseBound body (depth + 1)
  | .letE _ type value body => psElabHasLooseBound type depth ||
      psElabHasLooseBound value depth || psElabHasLooseBound body (depth + 1)
  | .proj _ _ value => psElabHasLooseBound value depth
  | _ => false

-- Inspect the result without allocating speculative argument metavariables.
-- A loose binder means a source argument must be elaborated before expected
-- type information can safely flow back into the remaining argument domains.
def psElabApplicationResultType (context : PsElabContext) (fuel : Nat)
    (type : PsExpr) (positions : Nat) (names : List PsName) : Option PsExpr :=
  match fuel with
  | 0 => none
  | fuel + 1 =>
    if positions == 0 && names.isEmpty then
      if psElabHasLooseBound type then none else some type
    else match psWhnf context.environment context.metaContext context.localContext type with
    | .forallE name _ body binder =>
      let named := names.any (psNameEq name)
      if named then psElabApplicationResultType context fuel body positions
        (names.filter (fun other => !psNameEq name other))
      else if psBinderAcceptsExplicitArgument binder then
        if positions == 0 then none else
          psElabApplicationResultType context fuel body (positions - 1) names
      else psElabApplicationResultType context fuel body positions names
    | _ => none

def psElabPropagateExpected {α : Type} (current : PsElabTermResult)
    (positions : List α) (names : List (PsName × α))
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  match expected with
  | none => return current
  | some target =>
    let targetShape := psWhnf current.context.environment current.context.metaContext
      current.context.localContext target
    let enabled := if psElabExpectedTypeIsUnconstrained current.context targetShape then false else
      match targetShape with
      | .sortE level => !psLevelEquivalent level .zero
      | _ => true
    if !enabled then return current
    match psElabApplicationResultType current.context 4096 current.type positions.length (names.map (·.fst)) with
    | none => return current
    | some result =>
      let context ← psElabProgressInstancePending current.context
      let current := { current with context }
      let solved := psUnifyWithRecovery (psElabRecoverPendingProjection current.context)
        current.context.environment current.context.localContext
        current.context.metaContext result target
      if solved.resourceExceeded then throw .fuelExhausted
      return psElabResultWithMeta current solved.context current.type

-- Drain scoped constraints before a dependent argument. Individually checked
-- progress is retained even when another item still needs a later argument.
def psElabResolveSyntheticChecked {α : Type} (current : PsElabTermResult)
    (pending : List PsSyntheticConstraint) : Except PsElabError (PsElabApplicationResult α) := do
  let solved := psSyntheticSolve current.context.environment current.context.instances
    current.context.metaContext pending.reverse (!current.context.postponing)
  if solved.resourceExceeded then throw .fuelExhausted
  return {
    result := psElabResultWithMeta current solved.context current.type
    constraintsRev := solved.pending.reverse
  }

-- Retain the original result-only interface for existing callers.
def psElabResolveSynthetic (current : PsElabTermResult)
    (pending : List PsSyntheticConstraint) : PsElabApplicationResult :=
  (psElabResolveSyntheticChecked current pending).toOption.getD {
    result := psElabResultWithMeta current current.context.metaContext current.type
    constraintsRev := pending }

-- One ordered engine owns positional/named arguments, defaults and implicits.
-- A matching expected function type preserves partial application. Explicit
-- empty invocation passes no expected type here and requests full completion.
def psElabApplyOrderedWith {α : Type}
    (elaborate : PsElabContext → α → Option PsExpr → Except PsElabError PsElabTermResult) (fuel : Nat)
    (current : PsElabTermResult) (positions : List α)
    (names : List (PsName × α)) (pending : List PsSyntheticConstraint)
    (complete : Bool := true) (expected : Option PsExpr := none)
    (capture : Option PsElabApplicationCapture := none) :
    Except PsElabError (PsElabApplicationResult α) := do
  if capture.any (fun capture => capture.remaining == 0) then
    -- The owner transforms only its original header. The returned function
    -- keeps the remaining ordinary arguments, including their names/order.
    -- They are elaborated after that owner supplies the real checked head.
    return { result := current, constraintsRev := pending, capture
             remainingPositions := positions, remainingNames := names }
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let currentType := psWhnf current.context.environment current.context.metaContext
      current.context.localContext current.type
    if positions.isEmpty && names.isEmpty then
      match expected with
      | some target =>
        -- An unconstrained expected type cannot request a polymorphic or
        -- default-parameter function value. As in Lean Elab/App processExplicitArg,
        -- fill omitted defaults before inferring that type. A concrete expected
        -- function type still preserves PSCV0's existing partial-application rule.
        let targetType := psWhnf current.context.environment current.context.metaContext
          current.context.localContext target
        let preserve := match currentType with
          | .forallE _ domain _ binder =>
            if psElabExpectedTypeIsUnconstrained current.context targetType then
              psBinderAcceptsExplicitArgument binder &&
                (!complete || (psElabDefaultValue current.context domain).isNone)
            else true
          | _ => true
        if preserve then
          match psElabUnifyExpected current (some target) with
          | .ok result => return { result, constraintsRev := pending, capture }
          | .error error => if psElabErrorIsResource error then throw error else pure ()
      | none => pure ()
    match currentType with
    | .forallE name domain body binder =>
      let named := psElabTakeNamed name names
      let explicit := psBinderAcceptsExplicitArgument binder
      let selected ← match named.fst, positions with
        | some value, _ =>
          if explicit && !positions.isEmpty then
            throw (.invalidArgument "argument supplied both positionally and by name")
          pure (some value, positions, named.snd)
        | none, value :: rest =>
          if explicit then pure (some value, rest, names)
          else pure (none, positions, names)
        | none, [] => pure (none, [], names)
      match selected.1 with
      | some source =>
        let current ← psElabPropagateExpected current positions names expected
        let resolved ← psElabResolveSyntheticChecked (α := α) current pending
        let current := resolved.result
        let pending := resolved.constraintsRev
        let argument ← elaborate current.context source
          (some (psMetaInstantiate current.context.metaContext domain))
        let (next, capture) := psElabApplyCapturedValue current argument body capture
        psElabApplyOrderedWith elaborate fuel next
          selected.2.1 selected.2.2 pending complete expected capture
      | none =>
        if explicit && (complete || !names.isEmpty) then
          match psElabDefaultValue current.context domain with
          | some value =>
            -- An omitted default is mandatory, not a unification choice.
            let fresh := psMetaFresh current.context.metaContext current.context.localContext
              domain .syntheticOpaque
            let .mvar id := fresh.expr | throw .implicitApplicationUnsupported
            let argument : PsElabTermResult := {
              context := psElabRecordInfo
                (psElabContextWithMeta current.context fresh.context)
                (.insertedArgument current.context.sourceSpan .defaultValue name
                  current.term fresh.expr domain)
              term := fresh.expr, type := domain }
            let (next, capture) := psElabApplyCapturedValue current argument body capture
            return ← psElabApplyOrderedWith elaborate fuel next positions names
              (.defaultValue id value :: pending) complete expected capture
          | none => pure ()
        if (explicit || (psBinderIsStrictImplicit binder && !complete)) &&
            positions.isEmpty && names.isEmpty then
          return { result := current, constraintsRev := pending, capture }
        let kind := if psBinderIsInstanceImplicit binder then
          PsMetaVarKind.synthetic else PsMetaVarKind.natural
        let fresh := psMetaFresh current.context.metaContext current.context.localContext domain kind
        let argument : PsElabTermResult := {
          context := psElabRecordInfo
            (psElabContextWithMeta current.context fresh.context)
            (.insertedArgument current.context.sourceSpan
              (if psBinderIsInstanceImplicit binder then .instanceImplicit
               else if psBinderIsStrictImplicit binder then .strictImplicit
               else if explicit then .inferredExplicit else .implicit)
              name current.term fresh.expr domain)
          term := fresh.expr
          type := domain }
        let (next, capture) := psElabApplyCapturedValue current argument body capture
        let pending := if psBinderIsInstanceImplicit binder then
          match fresh.expr with | .mvar id => .instanceGoal id :: pending | _ => pending
          else pending
        psElabApplyOrderedWith elaborate fuel next positions names pending complete expected capture
    | _ =>
      if !positions.isEmpty || !names.isEmpty then
        let callable ← (psElabEnsureFunction current).mapError fun error =>
          if psElabErrorIsResource error then error
          else if positions.isEmpty then .invalidArgument "unknown named argument" else error
        psElabApplyOrderedWith elaborate fuel callable positions names pending complete expected capture
      else return { result := current, constraintsRev := pending, capture }

-- Ordinary calls and records share the same telescope walk. A record update
-- supplies either source syntax or an already typed Core projection.
def psElabApplyOrdered (elaborate : PsElaborator) (fuel : Nat)
    (current : PsElabTermResult) (positions : List PsSyntaxTerm)
    (names : PsElabNamedArguments) (pending : List PsSyntheticConstraint)
    (complete : Bool := true) (expected : Option PsExpr := none) :
    Except PsElabError PsElabApplicationResult :=
  psElabApplyOrderedWith elaborate fuel current positions names pending complete expected

def psElabApplyArgsWithFuelWorker (elaborate : PsElaborator) (fuel : Nat)
    (current : PsElabTermResult) (arguments : List PsSyntaxTerm) (pending : List PsSyntheticConstraint) :
    Except PsElabError PsElabApplicationResult :=
  psElabApplyOrdered elaborate fuel current arguments [] pending

def psElabApplyArgsWithFuel := psElabApplyArgsWithFuelWorker

def psElabApplyArgs (elaborate : PsElaborator) (current : PsElabTermResult)
    (arguments : List PsSyntaxTerm) (pending : List PsSyntheticConstraint)
    (expected : Option PsExpr := none) :
    Except PsElabError PsElabApplicationResult :=
  psElabApplyOrdered elaborate 4096 current arguments [] pending
    (!arguments.isEmpty || expected.isSome) expected

def psElabFinishApplication {α : Type} (application : PsElabApplicationResult α)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult :=
  do
    if !application.remainingPositions.isEmpty || !application.remainingNames.isEmpty then
      throw (.invalidArgument "unconsumed arguments after an owned source telescope")
    -- Propagate convertible result information before dictionary/default work.
    -- A failed attempt is speculative; adaptation is retried after the queue.
    let current ← match psElabUnifyExpected application.result expected with
      | .ok result => pure result
      | .error error =>
        if psElabErrorIsResource error then throw error else pure application.result
    let current ← psElabSolveSynthetic current application.constraintsRev.reverse
    psElabFinalizeExpected current expected

-- APP-03 is an elaboration request, distinct from a written Unit argument.
-- Only a callable head may be completed. An unresolved domain is never guessed
-- to be Unit, and a second required explicit binder cannot be left behind.
def psElabCompleteEmpty (elaborate : PsElaborator) (application : PsElabApplicationResult) :
    Except PsElabError PsElabApplicationResult := do
  let current := application.result
  match psWhnf current.context.environment current.context.metaContext
      current.context.localContext current.type with
  | .forallE _ domain body binder =>
    if !psBinderAcceptsExplicitArgument binder then throw .emptyCallUnsupported
    -- Pinned Lean 4.35.0 Init/Prelude.lean defines `Unit := PUnit`
    -- and `Unit.unit := PUnit.unit` as reducible abbreviations. An empty
    -- invocation is legal precisely when the explicit domain is DEFINITIONALLY
    -- Unit, not only when its weak-head normal form still prints "Unit".
    -- Reuse the same checked read-only conversion as typed applications.
    -- Reject unconstrained metavariables and non-Unit domains; do not insert
    -- Unit for unrelated functions or change the APP-03 acceptance policy.
    -- Lean's PUnit is universe-polymorphic: a fresh *universe* variable
    -- produced by elaborating `PUnit` in a binder must be unified with the
    -- Unit alias's fixed universe. It is not an unresolved term argument.
    -- Never solve an unknown term type to Unit merely to accept `f()`.
    let instantiated := psMetaInstantiate current.context.metaContext domain
    if psExprHasTermMeta instantiated then throw .emptyCallUnsupported
    let normalized := psWhnf current.context.environment current.context.metaContext
      current.context.localContext instantiated
    let isUnitFamily := match normalized with
      | .constE name _ =>
        psNameEq name psUnitName || psNameEq name (psRootName "PUnit")
      | _ => false
    if !isUnitFamily then throw .emptyCallUnsupported
    let unified := psUnify current.context.environment current.context.localContext
      current.context.metaContext domain (.constE psUnitName [])
    if unified.resourceExceeded then throw .fuelExhausted
    if !unified.success then throw .emptyCallUnsupported
    let context := psElabContextWithMeta current.context unified.context
    let domain := psMetaInstantiate unified.context domain
    if !psDefEqReadOnlyWithEnv context.environment context.metaContext
        context.localContext domain (.constE psUnitName []) then
      throw .emptyCallUnsupported
    let current := { current with context }
    let unit ← psElabUnit context (some domain)
    let completed ← psElabApplyOrdered elaborate 4096
      (psElabApplyValue current unit body) [] [] application.constraintsRev
    match psWhnf completed.result.context.environment completed.result.context.metaContext
        completed.result.context.localContext completed.result.type with
    | .forallE _ _ _ _ => throw .emptyCallUnsupported
    | _ => return completed
  | _ => return application

def psElabCall (elaborate : PsElaborator) (head : PsElabTermResult)
    (args : List (Prod (Option PsSyntaxName) PsSyntaxTerm))
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  let head ← if args.isEmpty then psElabEnsureFunction head else pure head
  let arguments ← psElabCallArguments args [] []
  let application ← psElabApplyOrdered elaborate 4096 head arguments.fst arguments.snd [] true
    (if args.isEmpty then none else expected)
  let application ← if args.isEmpty then psElabCompleteEmpty elaborate application else pure application
  psElabFinishApplication application expected
