import Ps.Elab.Record
import Ps.Elab.Universe
import Ps.Elab.Proof
import Ps.Elab.PatternMatrix

def psElabIf
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (condition : PsSyntaxTerm)
    (thenBranch : PsSyntaxTerm)
    (elseBranch : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let boolType := PsExpr.constE psBoolName [];
  match elaborate context condition (Option.some boolType) with
  | Except.error error => Except.error error
  | Except.ok conditionResult =>
      let trueTerm := PsExpr.constE psBoolTrueName [];
      let conditionProp :=
        psExprApplyMany
          (PsExpr.constE
            psEqName
            [PsLevel.succ PsLevel.zero])
          [boolType, conditionResult.term, trueTerm];
      let decider :=
        psExprApplyMany
          (PsExpr.constE psBoolDecEqName [])
          [conditionResult.term, trueTerm];
      match elaborate
          conditionResult.context
          thenBranch
          expected with
      | Except.error error => Except.error error
      | Except.ok thenResult =>
          let resultType : PsExpr :=
            match expected with
            | some type => type
            | none => thenResult.type;
          match elaborate
              thenResult.context
              elseBranch
              (Option.some resultType) with
          | Except.error error => Except.error error
          | Except.ok elseResult =>
              let metaContext := elseResult.context.metaContext;
              let instantiatedType :=
                psMetaInstantiate metaContext resultType;
              match psInferType
                  elseResult.context.environment
                  metaContext
                  elseResult.context.localContext
                  instantiatedType with
              | Except.error error =>
                  Except.error (PsElabError.infer error)
              | Except.ok typeType =>
                  match psInferEnsureSort
                      elseResult.context.environment
                      metaContext
                      elseResult.context.localContext
                      typeType with
                  | Except.error error =>
                      Except.error (PsElabError.infer error)
                  | Except.ok universeLevel =>
                      let term :=
                        psExprApplyMany
                          (PsExpr.constE psIteName [universeLevel])
                          [
                            instantiatedType,
                            psMetaInstantiate metaContext conditionProp,
                            psMetaInstantiate metaContext decider,
                            psMetaInstantiate metaContext thenResult.term,
                            psMetaInstantiate metaContext elseResult.term
                          ];
                      let restoredContext :=
                        psElabLeaveScope context elseResult.context;
                      psElabResolvedTerm
                        restoredContext
                        term
                        expected

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
-- Validate actual Core arguments against the child telescope, rather than
-- comparing source names. This admits computed indices while rejecting stale
-- indices and changes to invariant parameters.
def psElabValidateStructuralArguments (elaborate : PsElaborator)
    (substitutions : List (Nat × PsExpr)) (ids : List Nat)
    (arguments : List PsSyntaxTerm) (context : PsElabContext) :
    Except PsElabError PsElabContext := do
  match ids, arguments with
  | [], [] => return context
  | id :: rest, source :: tail =>
    let some declaration := psLocalFindById context.localContext id
      | throw .structuralRecursionInternal
    let expected := psElabSubstituteLocals substitutions (psLocalDeclType declaration)
    let value ← elaborate context source (some expected)
    let required := psElabSubstituteLocals substitutions (.fvar id)
    if !(psDefEqReadOnlyWithEnv value.context.environment value.context.metaContext
        value.context.localContext value.term required) then
      throw .structuralRecursionInvariantArgument
    psElabValidateStructuralArguments elaborate substitutions rest tail value.context
  | _, _ => throw .structuralRecursionArity

def psElabValidateStructuralCall (elaborate : PsElaborator)
    (context : PsElabContext) (recursion : PsElabStructuralRecursion)
    (arguments : List PsSyntaxTerm) : Except PsElabError (PsElabContext × Nat) := do
  let majorId ← psElabCheckStructuralTelescope context recursion
  let some source := arguments[recursion.recursiveParameterIndex]?
    | throw .structuralRecursionArity
  let some childId := psElabSyntaxLocalId context source
    | throw .structuralRecursionNotDecreasing
  let some hypothesisId := psElabStructuralRecursionFindCall recursion.calls childId
    | throw .structuralRecursionNotDecreasing
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
    (substitutions ++ [(majorId, .fvar childId)]) recursion.explicitParameterIds arguments context
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
            let smaller :
                PsElabContext ->
                PsSyntaxTerm ->
                Option PsExpr ->
                Except PsElabError PsElabTermResult :=
              psElabTermWithFuel remaining;
            let readHead : PsElaborator := fun ctx source target =>
              match source with
              | .reference name =>
                  if psElabStructuralReferenceEscapes ctx name then
                    Except.error PsElabError.structuralRecursionEscapingReference
                  else psElabReference ctx name target
              | _ => smaller ctx source target
            match term with
            | .byE tactics scope _ => psElabProof smaller context tactics scope expected
            | .hole _ => Except.ok (psElabHole context expected)
            | .optionalType _ _ _ => Except.error PsElabError.unsupportedTerm
            | .ascription value type _ => psElabAscription smaller context value type expected
            | .call fn args span =>
                if args.all (fun arg => arg.fst.isNone) && !args.isEmpty then
                  -- Reuse the structural-call path for positional applications.
                  smaller context (.app fn (args.map Prod.snd) span) expected
                else
                  match readHead context fn none with
                  | .error error => .error error
                  | .ok head => psElabCall smaller head args expected
            | .reference name =>
                if psElabStructuralReferenceEscapes context name then
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
            | .ifE condition thenBranch elseBranch _ =>
                psElabIf
                  smaller
                  context
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
                        psTryElabStructuralSelfCall
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
                                    psElabFinishApplication application expected

def psElabTerm
    (context : PsElabContext)
    (term : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabTermWithFuel 4096 context term expected
