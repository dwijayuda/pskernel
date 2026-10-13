import Ps.Elab.Basic

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

structure PsElabApplicationResult where
  result : PsElabTermResult
  constraintsRev : List PsSyntheticConstraint

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
    (expected : Option PsExpr) : PsElabTermResult :=
  match expected with
  | none => current
  | some target =>
    let target := psWhnf current.context.environment current.context.metaContext
      current.context.localContext target
    let enabled := match target with
      | .mvar _ => false
      | .sortE level => !psLevelEquivalent level .zero
      | _ => true
    if !enabled then current else
    match psElabApplicationResultType current.context 4096 current.type positions.length (names.map (·.fst)) with
    | none => current
    | some result =>
      let solved := psSyntheticSolve current.context.environment current.context.instances
        current.context.metaContext [.expectedType current.context.localContext result target] false
      psElabResultWithMeta current solved.context current.type

-- Drain scoped constraints before a dependent argument. Individually checked
-- progress is retained even when another item still needs a later argument.
def psElabResolveSynthetic (current : PsElabTermResult)
    (pending : List PsSyntheticConstraint) : PsElabApplicationResult :=
  let solved := psSyntheticSolve current.context.environment current.context.instances
    current.context.metaContext pending.reverse (!current.context.postponing)
  { result := psElabResultWithMeta current solved.context current.type
    constraintsRev := solved.pending.reverse }

-- One ordered engine owns positional/named arguments, defaults and implicits.
-- A matching expected function type preserves partial application. Explicit
-- empty invocation passes no expected type here and requests full completion.
def psElabApplyOrderedWith {α : Type}
    (elaborate : PsElabContext → α → Option PsExpr → Except PsElabError PsElabTermResult) (fuel : Nat)
    (current : PsElabTermResult) (positions : List α)
    (names : List (PsName × α)) (pending : List PsSyntheticConstraint)
    (complete : Bool := true) (expected : Option PsExpr := none) :
    Except PsElabError PsElabApplicationResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let currentType := psWhnf current.context.environment current.context.metaContext
      current.context.localContext current.type
    if positions.isEmpty && names.isEmpty then
      match expected with
      | some target =>
        -- An unconstrained expected metavariable is not evidence that an
        -- implicit Pi should be preserved as a polymorphic function value.
        -- Insert its implicit arguments before constraining that expected type.
        let targetType := psWhnf current.context.environment current.context.metaContext
          current.context.localContext target
        let preserve := match currentType, targetType with
          | .forallE _ _ _ binder, .mvar _ => psBinderAcceptsExplicitArgument binder
          | _, _ => true
        if preserve then
          match psElabUnifyExpected current (some target) with
          | .ok result => return { result, constraintsRev := pending }
          | .error _ => pure ()
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
        let current := psElabPropagateExpected current positions names expected
        let resolved := psElabResolveSynthetic current pending
        let current := resolved.result
        let pending := resolved.constraintsRev
        let argument ← elaborate current.context source
          (some (psMetaInstantiate current.context.metaContext domain))
        psElabApplyOrderedWith elaborate fuel (psElabApplyValue current argument body)
          selected.2.1 selected.2.2 pending complete expected
      | none =>
        if explicit && (complete || !names.isEmpty) then
          match psElabDefaultValue current.context domain with
          | some value =>
            -- An omitted default is mandatory, not a unification choice.
            let fresh := psMetaFresh current.context.metaContext current.context.localContext
              domain .syntheticOpaque
            let .mvar id := fresh.expr | throw .implicitApplicationUnsupported
            let argument : PsElabTermResult := {
              context := psElabContextWithMeta current.context fresh.context
              term := fresh.expr, type := domain }
            return ← psElabApplyOrderedWith elaborate fuel
              (psElabApplyValue current argument body) positions names
              (.defaultValue id value :: pending) complete expected
          | none => pure ()
        if (explicit || (psBinderIsStrictImplicit binder && !complete)) &&
            positions.isEmpty && names.isEmpty then
          return { result := current, constraintsRev := pending }
        let kind := if psBinderIsInstanceImplicit binder then
          PsMetaVarKind.synthetic else PsMetaVarKind.natural
        let fresh := psMetaFresh current.context.metaContext current.context.localContext domain kind
        let next : PsElabTermResult := {
          context := psElabContextWithMeta current.context fresh.context
          term := .app current.term fresh.expr
          type := psExprInstantiate1 body fresh.expr }
        let pending := if psBinderIsInstanceImplicit binder then
          match fresh.expr with | .mvar id => .instanceGoal id :: pending | _ => pending
          else pending
        psElabApplyOrderedWith elaborate fuel next positions names pending complete expected
    | _ =>
      if !positions.isEmpty || !names.isEmpty then
        let callable ← (psElabEnsureFunction current).mapError fun error =>
          if positions.isEmpty then .invalidArgument "unknown named argument" else error
        psElabApplyOrderedWith elaborate fuel callable positions names pending complete expected
      else return { result := current, constraintsRev := pending }

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

def psElabSolveSynthetic (current : PsElabTermResult)
    (pending : List PsSyntheticConstraint) : Except PsElabError PsElabTermResult := do
  let solved := psSyntheticSolve current.context.environment current.context.instances
    current.context.metaContext pending (!current.context.postponing)
  if solved.resourceExceeded then throw .fuelExhausted
  if current.context.postponing then
    for constraint in solved.pending do
      if !psSyntheticMayRetry solved.context constraint then
        match constraint with
        | .instanceGoal _ => throw .implicitApplicationUnsupported
        | _ => throw .typeMismatch
    let result := psElabResultWithMeta current solved.context current.type
    let scope := psElabSaveScope result.context
    return { result with context := { result.context with
      pending := solved.pending.reverse.map (PsElabPendingWork.core scope) ++
        result.context.pending } }
  -- Preserve the reason for failure at the elaborator boundary; a blocked
  -- expected/default equality is a type mismatch, not a missing dictionary.
  match solved.pending.head? with
  | some (.expectedType _ _ _) | some (.defaultValue _ _) => throw .typeMismatch
  | some (.instanceGoal _) => throw .implicitApplicationUnsupported
  | none => pure ()
  return psElabResultWithMeta current solved.context current.type

def psElabFinishApplication (application : PsElabApplicationResult)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult :=
  do
    -- Propagate convertible result information before dictionary/default work.
    -- A failed attempt is speculative; adaptation is retried after the queue.
    let current := (psElabUnifyExpected application.result expected).toOption.getD
      application.result
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
    let domain := psWhnf current.context.environment current.context.metaContext
      current.context.localContext domain
    if !psExprAlphaEq domain (.constE psUnitName []) then throw .emptyCallUnsupported
    let unit ← psElabUnit current.context (some domain)
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
