import Ps.Elab.Postponed
import Ps.Elab.Operator
import Ps.Elab.Record
import Ps.Elab.Universe
import Ps.Elab.Proof
import Ps.Elab.WellFounded
import Ps.Elab.PatternMatrix

import Ps.Elab.Do

def psElabSyntaxLocalId
    (context : PsElabContext) :
    PsSyntaxTerm -> Option Nat
  | .reference sourceName =>
      match psSyntaxNameToName sourceName with
      | Option.none => Option.none
      | Option.some name =>
          match
              psResolveName
                context.localContext
                context.environment
                name with
          | Option.none => Option.none
          | Option.some resolved =>
              match resolved with
              | .local id =>
                  match psWhnf context.environment context.metaContext
                      context.localContext (.fvar id) with
                  | .fvar actual => some actual
                  | _ => none
              | .global _ => Option.none
  | _ => Option.none

def psElabNatListAtWorker
    (index : Nat) :
    List Nat -> Option Nat :=
  match index with
  | 0 =>
      fun (values : List Nat) =>
        match values with
        | [] =>
            Option.none
        | value :: _ =>
            Option.some value
  | nextIndex + 1 =>
      fun (values : List Nat) =>
        let smaller :
            List Nat -> Option Nat :=
          psElabNatListAtWorker nextIndex;
        match values with
        | [] =>
            Option.none
        | _ :: rest =>
            smaller rest

def psElabNatListAt
    (values : List Nat)
    (index : Nat) : Option Nat :=
  psElabNatListAtWorker
    index
    values
-- Permit an already-checked strict constructor child up to definitional equality.
-- Never manufacture an IH for an arbitrary arithmetic decrease.
def psElabStructuralDefEqChild (context : PsElabContext) (term : PsExpr) :
    List (Nat × Nat) → Option (Nat × Nat)
  | [] => none
  | (childId, hypothesisId) :: rest =>
    if psDefEqReadOnlyWithEnv context.environment context.metaContext
        context.localContext term (.fvar childId) then
      some (childId, hypothesisId)
    else
      psElabStructuralDefEqChild context term rest

-- An expected major type may guide implicit HAdd/instance elaboration,
-- but it may only come from actual, already checked recursive fields.
-- If the available field types vary by index, leave the argument inference
-- unchanged and rely on its subsequent child equality and telescope checks.
def psElabStructuralCommonChildType (context : PsElabContext)
    (calls : List (Nat × Nat)) : Option PsExpr := do
  let some first := calls.head? | none
  let some declaration := psLocalFindById context.localContext first.fst | none
  let result := psLocalDeclType declaration
  if calls.all (fun entry =>
      match psLocalFindById context.localContext entry.fst with
      | none => false
      | some child => psDefEqReadOnlyWithEnv
          context.environment context.metaContext context.localContext
          result (psLocalDeclType child)) then
    some result
  else none

-- Validate actual Core arguments against the child telescope, rather than
-- comparing source names. This admits computed indices while rejecting stale
-- indices and changes to invariant parameters.
def psElabValidateStructuralArguments (elaborate : PsElaborator)
    (substitutions : List (Nat × PsExpr)) (ids : List Nat)
    (arguments : List PsSyntaxTerm) (context : PsElabContext)
    (prechecked : Option (Nat × PsElabTermResult)) :
    Except PsElabError PsElabContext := do
  match ids, arguments with
  | [], [] => return context
  | id :: rest, source :: tail =>
    let some declaration := psLocalFindById context.localContext id
      | throw .structuralRecursionInternal
    let expected := psElabSubstituteLocals substitutions (psLocalDeclType declaration)
    let value ← match prechecked with
      | some (0, cached) => do
        -- Reuse exactly the previous Core term, but retain subsequent checked
        -- assignments from preceding invariant reference arguments.
        if !(psDefEqReadOnlyWithEnv context.environment context.metaContext
            context.localContext cached.type expected) then
          throw .structuralRecursionInvariantArgument
        pure { cached with context := context }
      | _ => elaborate context source (some expected)
    let required := psElabSubstituteLocals substitutions (.fvar id)
    if !(psDefEqReadOnlyWithEnv value.context.environment value.context.metaContext
        value.context.localContext value.term required) then
      throw .structuralRecursionInvariantArgument
    let later := prechecked.bind fun entry =>
      if entry.fst == 0 then none else some (entry.fst - 1, entry.snd)
    psElabValidateStructuralArguments elaborate substitutions rest tail value.context later
  | _, _ => throw .structuralRecursionArity

def psElabValidateStructuralCall (elaborate : PsElaborator)
    (context : PsElabContext) (recursion : PsElabStructuralRecursion)
    (arguments : List PsSyntaxTerm) : Except PsElabError (PsElabContext × Nat) := do
  let majorId ← psElabCheckStructuralTelescope context recursion
  let some source := arguments[recursion.recursiveParameterIndex]?
    | throw .structuralRecursionArity
  let (childId, hypothesisId, context, prechecked) ←
    match psElabSyntaxLocalId context source with
    | some childId => do
      let some hypothesisId := psElabStructuralRecursionFindCall recursion.calls childId
        | throw .structuralRecursionNotDecreasing
      pure (childId, hypothesisId, context, none)
    | none => do
      -- Earlier arguments must be unchanged, direct binder references.
      -- Prechecking the computed major cannot reorder any actual computation;
      -- the normal telescope still elaborates these references in order.
      -- Other changing-prefix calls may instead use the separately checked
      -- state-parameter worker normalization, never a synthetic IH.
      let fixedPrefix := recursion.explicitParameterIds.take recursion.recursiveParameterIndex
      let sourcePrefix := arguments.take recursion.recursiveParameterIndex
      if fixedPrefix.length != sourcePrefix.length ||
          !(fixedPrefix.zip sourcePrefix).all (fun entry =>
            psElabSyntaxLocalId context entry.snd == some entry.fst) then
        throw .structuralRecursionInvariantArgument
      let expected := psElabStructuralCommonChildType context recursion.calls
      let checked ← elaborate context source expected
      -- The operator's class dictionary may be a deferred ordinary
      -- synthetic constraint. Resolve available non-default evidence before
      -- comparing with existing induction hypotheses; never force default
      -- instances or resume a suspended source in the wrong lexical scope.
      -- No pending work needs a scheduler pass. The ordinary queue solver
      -- remains responsible for all non-default constraints when present.
      let progressed ← if checked.context.pending.isEmpty then pure checked.context
        else psElabProgressPending elaborate checked.context
      let checked := { checked with context := progressed }
      let some (childId, hypothesisId) :=
        psElabStructuralDefEqChild checked.context checked.term recursion.calls
        | throw .structuralRecursionNotDecreasing
      pure (childId, hypothesisId, checked.context,
        some (recursion.recursiveParameterIndex, checked))
  let some child := psLocalFindById context.localContext childId
    | throw .structuralRecursionInternal
  let childType := psExprAppView (psWhnf context.environment context.metaContext
    context.localContext (psLocalDeclType child))
  let .constE family _ := childType.head | throw .structuralRecursionInternal
  let some info := psEnvironmentFindInductive context.environment family
    | throw .structuralRecursionInternal
  let indices := childType.args.drop info.numParams
  let substitutions ← recursion.indices.mapM fun entry => do
    let some value := indices[entry.snd]? | throw .structuralRecursionInternal
    return (entry.fst, value)
  let context ← psElabValidateStructuralArguments elaborate
    (substitutions ++ [(majorId, .fvar childId)]) recursion.explicitParameterIds
    arguments context prechecked
  return (context, hypothesisId)

def psElabStructuralNameIsLocal (context : PsElabContext) (name : PsName) : Bool :=
  match psLocalFindUser context.localContext name with
  | Option.none => false
  | Option.some _ => true

def psTryElabStructuralSelfCall (elaborate : PsElaborator)
    (context : PsElabContext) (fn : PsSyntaxTerm) (arguments : List PsSyntaxTerm)
    (expected : Option PsExpr) : Except PsElabError (Option PsElabTermResult) := do
  let some recursion := context.structuralRecursion | return none
  let .reference sourceName := fn | return none
  let some calledName := psSyntaxNameToName sourceName | return none
  if !psNameEq calledName recursion.functionName || psElabStructuralNameIsLocal context calledName then
    return none
  if arguments.length != recursion.explicitParameterIds.length then throw .structuralRecursionArity
  let (context, hypothesisId) ← psElabValidateStructuralCall elaborate context recursion arguments
  let result ← psElabResolvedTerm context (.fvar hypothesisId) expected
  return some result

def psElabStructuralReferenceEscapes
    (context : PsElabContext) (sourceName : PsSyntaxName) : Bool :=
  match context.structuralRecursion with
  | Option.none => false
  | Option.some recursion =>
      match psSyntaxNameToName sourceName with
      | Option.none => false
      | Option.some name =>
          if psNameEq name recursion.functionName then
            match psLocalFindUser context.localContext name with
            | Option.none => true
            | Option.some _ => false
          else false

def psTryElabRecursionSelfCall (elaborate : PsElaborator)
    (context : PsElabContext) (fn : PsSyntaxTerm) (arguments : List PsSyntaxTerm)
    (expected : Option PsExpr) : Except PsElabError (Option PsElabTermResult) := do
  match ← psTryElabWellFoundedCall elaborate context fn
      (arguments.map fun value => (none, value)) expected with
  | some result => return some result
  | none => psTryElabStructuralSelfCall elaborate context fn arguments expected

def psElabTermWithFuel
    (fuel : Nat) :
    PsElabContext ->
    PsSyntaxTerm ->
    Option PsExpr ->
    Except PsElabError PsElabTermResult :=
  match fuel with
  | 0 =>
      fun (_context : PsElabContext) =>
        fun (_term : PsSyntaxTerm) =>
          fun (_expected : Option PsExpr) =>
            Except.error PsElabError.fuelExhausted
  | remaining + 1 =>
      fun (context : PsElabContext) =>
        fun (term : PsSyntaxTerm) =>
          fun (expected : Option PsExpr) =>
            let outerSpan := context.sourceSpan;
            let context := { context with sourceSpan := some (psSyntaxTermSpan term) };
            let smaller :
                PsElabContext ->
                PsSyntaxTerm ->
                Option PsExpr ->
                Except PsElabError PsElabTermResult :=
              psElabTermWithFuel remaining;
            let readHead : PsElaborator := fun ctx source target =>
              match source with
              | .reference name =>
                  if psElabWellFoundedReferenceEscapes ctx name then
                    Except.error (.data "PSCV0-WF-ESCAPE: a recursive reference must complete its source header")
                  else if psElabStructuralReferenceEscapes ctx name then
                    Except.error PsElabError.structuralRecursionEscapingReference
                  else psElabReference ctx name target
              | _ => smaller ctx source target
            (psElabWithPostponement (fun _ => match term with
            | .operatorE .. => psElabOperator smaller context term expected
            | .doE items _ => psElabDo smaller context items expected
            | .byE tactics scope _ => psElabProof smaller context tactics scope expected
            | .hole _ => Except.ok (psElabHole context expected)
            | .omittedType _ => Except.error (.data "PSCV0-RESULT-ANNOTATION: omitted result syntax is declaration-only")
            | .optionalType _ _ _ => Except.error PsElabError.unsupportedTerm
            | .ascription value type _ => psElabAscription smaller context value type expected
            | .call fn args span =>
                match psTryElabWellFoundedCall smaller context fn args expected with
                | .error error => .error error
                | .ok (some result) => .ok result
                | .ok none =>
                  if args.all (fun arg => arg.fst.isNone) && !args.isEmpty then
                    smaller context (.app fn (args.map Prod.snd) span) expected
                  else
                    match readHead context fn none with
                    | .error error => .error error
                    | .ok head => psElabCall smaller head args expected
            | .reference name =>
                if psElabWellFoundedReferenceEscapes context name then
                  Except.error (.data "PSCV0-WF-ESCAPE: a recursive reference must be a full positional call")
                else if psElabStructuralReferenceEscapes context name then
                  Except.error PsElabError.structuralRecursionEscapingReference
                else
                  match psElabReference context name Option.none with
                  | Except.error error => Except.error error
                  | Except.ok reference =>
                      match psElabApplyArgs
                          smaller
                          reference
                          []
                          [] expected with
                      | Except.error error => Except.error error
                      | Except.ok application =>
                          psElabFinishApplication application expected
            | .sortE isType level _ => psElabSort context isType level expected
            | .scientific text _ =>
                psElabScientific context text expected
            | .natural text _ =>
                psElabNatural context text expected
            | .string text _ =>
                psElabString context text expected
            | .character text _ =>
                psElabCharacter context text expected
            | .unit _ =>
                psElabUnit context expected
            | .record fields _ =>
                psElabRecord
                  smaller
                  context
                  fields
                  expected
            | .recordUpdate source fields _ =>
                psElabRecordUpdate smaller context source fields expected
            | .bool value _ =>
                psElabBool context value expected
            | .lambda binders body _ =>
                psElabLambda
                  smaller
                  context
                  binders
                  body
                  expected
            | .forallE binders body _ =>
                psElabForall
                  smaller
                  context
                  binders
                  body
                  expected
            | .haveE name declaredType value body _ =>
                psElabLet smaller context name declaredType value body expected true
            | .letE name declaredType value body _ =>
                psElabLet
                  smaller
                  context
                  name
                  declaredType
                  value
                  body
                  expected
            | .ifE name condition thenBranch elseBranch _ =>
                psElabIf
                  smaller
                  context
                  name
                  condition
                  thenBranch
                  elseBranch
                  expected
            | .matchMany scrutinee alternatives _ =>
                psElabMatchMatrix
                  smaller
                  context
                  scrutinee
                  alternatives
                  expected
            | .app fn args _ =>
                -- An adjacent empty call has its own completion path above.
                match args with
                | List.nil => Except.error PsElabError.emptyCallUnsupported
                | List.cons _ _ =>
                    match
                        psTryElabRecursionSelfCall
                          smaller
                          context
                          fn
                          args
                          expected with
                    | Except.error error => Except.error error
                    | Except.ok selfCall =>
                        match selfCall with
                        | Option.some result => Except.ok result
                        | Option.none =>
                            match readHead context fn Option.none with
                            | Except.error error => Except.error error
                            | Except.ok elaboratedFn =>
                                match psElabApplyArgs
                                    smaller
                                    elaboratedFn
                                    args
                                    [] expected with
                                | Except.error error => Except.error error
                                | Except.ok application =>
                                    psElabFinishApplication application expected) context term expected).map
              (fun result => { result with context := { result.context with sourceSpan := outerSpan } })

def psElabTerm
    (context : PsElabContext)
    (term : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  do
    let result ← psElabTermWithFuel 4096 { context with postponing := true } term expected
    let result ← psElabDrainPending (psElabTermWithFuel 4096) result
    return { result with context := { result.context with postponing := context.postponing } }

