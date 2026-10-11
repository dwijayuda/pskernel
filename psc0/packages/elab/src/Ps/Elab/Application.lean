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
  pendingInstancesRev : List Nat

def psSyntaxTermListIsEmpty
    (values : List PsSyntaxTerm) : Bool :=
  match values with
  | [] =>
      true
  | _ :: _ =>
      false

abbrev PsElabNamedArguments := List (Prod PsName PsSyntaxTerm)

def psElabTakeNamed (name : PsName) (args : PsElabNamedArguments) :
    Prod (Option PsSyntaxTerm) PsElabNamedArguments :=
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

-- A single telescope engine owns positional/named consumption and implicit
-- insertion. It preserves binder order and opens each dependent codomain only
-- after the corresponding argument has been checked.
def psElabApplyOrdered (elaborate : PsElaborator) (fuel : Nat)
    (current : PsElabTermResult) (positions : List PsSyntaxTerm)
    (names : PsElabNamedArguments) (pending : List Nat) :
    Except PsElabError PsElabApplicationResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match psWhnf current.context.environment current.context.metaContext
        current.context.localContext current.type with
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
        let argument ← elaborate current.context source (some domain)
        psElabApplyOrdered elaborate fuel (psElabApplyValue current argument body)
          selected.2.1 selected.2.2 pending
      | none =>
        if (explicit || psBinderIsStrictImplicit binder) &&
            positions.isEmpty && names.isEmpty then
          return { result := current, pendingInstancesRev := pending }
        let kind := if psBinderIsInstanceImplicit binder then
          PsMetaVarKind.synthetic else PsMetaVarKind.natural
        let fresh := psMetaFresh current.context.metaContext current.context.localContext domain kind
        let next : PsElabTermResult := {
          context := psElabContextWithMeta current.context fresh.context
          term := .app current.term fresh.expr
          type := psExprInstantiate1 body fresh.expr }
        let pending := if psBinderIsInstanceImplicit binder then
          match fresh.expr with | .mvar id => id :: pending | _ => pending
          else pending
        psElabApplyOrdered elaborate fuel next positions names pending
    | _ =>
      if !names.isEmpty then throw (.invalidArgument "unknown named argument")
      if !positions.isEmpty then throw (.infer .expectedFunction)
      return { result := current, pendingInstancesRev := pending }

def psElabApplyArgsWithFuelWorker (elaborate : PsElaborator) (fuel : Nat)
    (current : PsElabTermResult) (arguments : List PsSyntaxTerm) (pending : List Nat) :
    Except PsElabError PsElabApplicationResult :=
  psElabApplyOrdered elaborate fuel current arguments [] pending

def psElabApplyArgsWithFuel := psElabApplyArgsWithFuelWorker

def psElabApplyArgs (elaborate : PsElaborator) (current : PsElabTermResult)
    (arguments : List PsSyntaxTerm) (pending : List Nat) :
    Except PsElabError PsElabApplicationResult :=
  psElabApplyOrdered elaborate 4096 current arguments [] pending

def psElabSolvePendingInstancesWorker
    (pendingInstances : List Nat) :
    PsElabTermResult ->
    Except PsElabError PsElabTermResult :=
  match pendingInstances with
  | [] =>
      fun (current : PsElabTermResult) =>
        let metaContext := current.context.metaContext;
        Except.ok {
          context := current.context
          term := psMetaInstantiate metaContext current.term
          type := psMetaInstantiate metaContext current.type
        }
  | id :: rest =>
      let smaller :
          PsElabTermResult ->
          Except PsElabError PsElabTermResult :=
        psElabSolvePendingInstancesWorker rest;
      fun (current : PsElabTermResult) =>
        let metaContext := current.context.metaContext;
        match psMetaFindAssignment metaContext id with
        | some _ =>
            smaller current
        | none =>
            match psMetaFindDecl metaContext id with
            | none =>
                Except.error PsElabError.implicitApplicationUnsupported
            | some declaration =>
                let target :=
                  psMetaInstantiate metaContext declaration.type;
                if psExprHasUnresolvedMeta target then
                  Except.error PsElabError.implicitApplicationUnsupported
                else
                  let synthesized :=
                    psSynthInstance
                      current.context.environment
                      current.context.localContext
                      current.context.instances
                      metaContext
                      target;
                  match synthesized.value with
                  | none =>
                      Except.error PsElabError.implicitApplicationUnsupported
                  | some value =>
                      match psMetaAssign
                          synthesized.context
                          id
                          value with
                      | none =>
                          Except.error
                            PsElabError.implicitApplicationUnsupported
                      | some assigned =>
                          let assignedResult : PsElabTermResult := {
                            context :=
                              psElabContextWithMeta
                                current.context
                                assigned
                            term := current.term
                            type := current.type
                          };
                          smaller assignedResult

def psElabSolvePendingInstances
    (current : PsElabTermResult)
    (pendingInstances : List Nat) :
    Except PsElabError PsElabTermResult :=
  psElabSolvePendingInstancesWorker
    pendingInstances
    current

def psElabFinishApplication
    (application : PsElabApplicationResult)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabFinalizeExpected application.result expected with
  | Except.error error => Except.error error
  | Except.ok finalized =>
      psElabSolvePendingInstances
        finalized
        application.pendingInstancesRev

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
      (psElabApplyValue current unit body) [] [] application.pendingInstancesRev
    match psWhnf completed.result.context.environment completed.result.context.metaContext
        completed.result.context.localContext completed.result.type with
    | .forallE _ _ _ _ => throw .emptyCallUnsupported
    | _ => return completed
  | _ => return application

def psElabCall (elaborate : PsElaborator) (head : PsElabTermResult)
    (args : List (Prod (Option PsSyntaxName) PsSyntaxTerm))
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  if args.isEmpty then
    match psWhnf head.context.environment head.context.metaContext head.context.localContext head.type with
    | .forallE _ _ _ _ => pure ()
    | _ => throw (.infer .expectedFunction)
  let arguments ← psElabCallArguments args [] []
  let application ← psElabApplyOrdered elaborate 4096 head arguments.fst arguments.snd []
  let application ← if args.isEmpty then psElabCompleteEmpty elaborate application else pure application
  psElabFinishApplication application expected
