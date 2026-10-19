import Ps.Elab.RCasesGeneralize

structure PsProofRCasesAlternative where
  constructor : PsName
  patterns : List PsSyntaxRCasesPattern
  names : List PsSyntaxName
  span : PsSourceSpan

def psProofRCasesAlternatives (context : PsElabContext) (span : PsSourceSpan)
    (constructors : List PsName) (patterns : List PsSyntaxRCasesPattern) :
    Except PsElabError (List PsProofRCasesAlternative) := do
  match constructors with
  | [] => return []
  | name :: constructors =>
    let some constructor := psEnvironmentFindConstructor context.environment name
      | throw (.matchConstructorUnknown name)
    let pattern := patterns.headD (psProofRCasesDefault span)
    let remaining := patterns.drop 1
    let ((explicit, fields), remaining) :=
      if constructors.isEmpty && !remaining.isEmpty then
        ((false, [PsSyntaxRCasesPattern.alternatives patterns span]), [])
      else (psProofRCasesAsTuple pattern, remaining)
    let binders ← psProofRCasesConstructorBinders context constructor
    let fields := psProofRCasesFields (psSyntaxRCasesPatternSpan pattern) explicit binders fields
    let names := fields.zipIdx.map fun (pattern, index) =>
      match psProofRCasesName? pattern with
      | some name => name
      | none => { PsSyntaxName.mk ["$psc0RCasesField"] (psSyntaxRCasesPatternSpan pattern) with
          resolvedName := some
            (psNameAppendNum (psRootName "$psc0RCasesField") (context.localContext.nextId + index)) }
    let rest ← psProofRCasesAlternatives context span constructors remaining
    return { constructor := name, patterns := fields, names
      span := psSyntaxRCasesPatternSpan pattern } :: rest

-- Quot has its own checked primitive kind. Its selected elimination target is
-- Prop, and all dependent hypotheses are reverted/reopened before the minor.
def psProofRCasesQuotient
    (visit : PsProofRCasesItem → PsProofRCasesContinuation)
    (frame : PsProofRCasesFrame)
    (value type : PsExpr) (pattern : PsSyntaxRCasesPattern) :
    Except PsElabError PsElabTermResult := do
  let context := frame.context
  let .fvar majorId := value | throw (.proof "rcases requires a local quotient target")
  let view := psExprAppView type
  let .constE family levels := view.head
    | throw (.proof "rcases requires a checked quotient type")
  let some (.quotientDecl _ _ _ .type) := psEnvironmentFind context.environment family
    | throw (.proof "rcases requires a checked quotient type")
  let [domain, relation] := view.args | throw .matchParameterArity
  let dependents := psElabDependentLocals context [majorId] []
  let telescope := psElabCloseDependentType dependents frame.target
  let level ← psElabExpressionSort context telescope
  if !psLevelEquivalent level .zero then
    throw (.proof "rcases quotient elimination requires a proposition")
  let qName := psNameAppendNum (psRootName "$psc0RCasesQuotient") context.localContext.nextId
  let q := psLocalPushBinding context.localContext qName type .explicit
  let motive := psCloseElabLambdaBinders context.metaContext
    [PsElabTypedBinder.mk q.id qName type .explicit]
    (psElabSubstituteLocals [(majorId, .fvar q.id)] telescope)
  let context := psElabContextWithLocal context
    { context.localContext with nextId := q.context.nextId }
  let alternative := (psProofRCasesAsAlternatives pattern).headD
    (psProofRCasesDefault (psSyntaxRCasesPatternSpan pattern))
  let (explicit, patterns) := psProofRCasesAsTuple alternative
  let [pattern] := psProofRCasesFields (psSyntaxRCasesPatternSpan alternative)
      explicit [.explicit] patterns | throw .matchRecursorUnsupported
  let name ← match psProofRCasesName? pattern with
    | some source => match psSyntaxNameToName source with
      | some name => pure name
      | none => throw .emptyName
    | none => pure (psNameAppendNum (psRootName "$psc0RCasesField") context.localContext.nextId)
  let field := psLocalPushBinding context.localContext name domain .explicit
  let fieldContext := psElabContextWithLocal context field.context
  let constructor := psExprApplyMany (.constE (psQuotientKindName .ctor) levels)
    [domain, relation, .fvar field.id]
  let _ ← psElabResolvedTerm fieldContext constructor (some type)
  let specialized := psElabSubstituteLocals [(majorId, constructor)] telescope
  let opened ← psElabOpenDependents dependents {
    context := fieldContext, body := specialized, bindersRev := [], aliasesRev := []
    replacements := [(majorId, constructor)] }
  let inner := psProofRCasesRemoveLocals opened.context
    (majorId :: dependents.map (·.binder.id))
  let body ← visit { value := .fvar field.id, pattern } {
    frame with context := inner, target := opened.body
    tag := psProofTag frame.tag "mk"
    refinements := frame.refinements ++ opened.replacements }
  let body ← psElabCloseDependents fieldContext opened body specialized
  let minorType : PsExpr := .forallE name domain (psExprAbstractFVar field.id specialized) .explicit
  let minor ← psElabAbstract context body.context
    [.lambdaE field.id name domain .explicit] body.term minorType
  let result := psExprApplyMany (.constE (psQuotientKindName .ind) levels)
    [domain, relation, motive, minor.term, value]
  -- The continuation has already run in the real minor; it is not retried
  -- after application of the reverted original hypotheses.
  psElabResolvedTerm minor.context
    (psExprApplyMany result (psElabDependentArguments dependents)) (some frame.target)

mutual
def psProofRCasesCore (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (fuel : Nat) (frame : PsProofRCasesFrame) (item : PsProofRCasesItem)
    (finish : PsProofRCasesContinuation) : Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let value := psProofRCasesCurrent frame item.value
    match item.pattern with
    | .one name =>
      let some name := psSyntaxNameToName name | throw .emptyName
      if psNameEq name (psRootName "rfl") then
        let checked ← psElabResolvedTerm frame.context value none
        let checked ← psElabDrainPending elaborate checked
        psProofRCasesSubstitute finish { frame with context := checked.context } checked.term
      else finish frame
    | .clear _ => finish { frame with clears := item.value :: frame.clears }
    | .typed pattern source _ =>
      let frame ← match item.annotation? with
        | some type => psProofRCasesAscribeType frame value (psProofRCasesCurrent frame type)
        | none => psProofRCasesAscribe elaborate scope frame value source
      psProofRCasesCore elaborate scope fuel frame
        { item with pattern, annotation? := none } finish
    | .paren pattern _ | .alternatives [pattern] _ =>
      psProofRCasesCore elaborate scope fuel frame { item with pattern } finish
    | pattern =>
      let .fvar _ := value | throw (.proof "rcases pattern requires a local variable")
      let checked ← psElabResolvedTerm frame.context value none
      let checked ← psElabDrainPending elaborate checked
      let type := psWhnf checked.context.environment checked.context.metaContext
        checked.context.localContext checked.type
      let frame := { frame with context := checked.context }
      let typeView := psExprAppView type
      let .constE name _ := typeView.head
        | throw (.proof "rcases pattern requires an inductive datatype")
      if let some (.quotientDecl _ _ _ .type) :=
          psEnvironmentFind checked.context.environment name then
        return ← psProofRCasesQuotient
          (fun item frame => psProofRCasesCore elaborate scope fuel frame item finish)
          frame checked.term type pattern
      psElabMatchTypedWith (fun current info => do
        let alternatives ← psProofRCasesAlternatives current (psSyntaxRCasesPatternSpan pattern)
          info.constructors (psProofRCasesAsAlternatives pattern)
        alternatives.mapM fun alternative => do
          pure {
            constructorName := alternative.constructor
            fieldNames := alternative.names
            allowDuplicateFieldNames := true
            span := alternative.span
            elaborate := fun branch => do
              let context := psProofRCasesRemoveLocals branch.context
                (branch.clearedIds ++ branch.hypotheses.map (·.id))
              let inner : PsProofRCasesFrame := { frame with
                context, target := branch.target
                tag := psProofTag frame.tag (psNameLastComponent alternative.constructor)
                refinements := frame.refinements ++ branch.refinements }
              let items := (alternative.patterns.zip branch.fields).map fun (pattern, field) =>
                ({ value := .fvar field.id, pattern } : PsProofRCasesItem)
              psProofRCasesContinue elaborate scope fuel inner items finish })
        checked (some frame.target)

def psProofRCasesContinue (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (fuel : Nat) (frame : PsProofRCasesFrame) (items : List PsProofRCasesItem)
    (finish : PsProofRCasesContinuation) : Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match items with
    | [] => finish frame
    | item :: rest =>
      psProofRCasesCore elaborate scope fuel frame item
        (fun next => psProofRCasesContinue elaborate scope fuel next rest finish)
end

def psProofRCasesTargets (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (frame : PsProofRCasesFrame)
    (targets : List (PsSyntaxMatchDiscriminant PsSyntaxTerm))
    (pattern : PsSyntaxRCasesPattern) : Except PsElabError PsElabTermResult := do
  let patterns := if targets.length == 1 then [pattern] else
    psProofRCasesFields (psSyntaxRCasesPatternSpan pattern) false
      (List.replicate targets.length .explicit) (psProofRCasesAsTuple pattern).2
  let (context, inputs) ← psProofRCasesReadInputs elaborate scope frame.context targets patterns
  psProofRCasesGeneralize
    (fun items frame => psProofRCasesContinue elaborate scope 4096 frame items psProofRCasesFinish)
    { frame with context } inputs

def psProofRCases (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (targets : List (PsSyntaxMatchDiscriminant PsSyntaxTerm))
    (pattern : Option PsSyntaxRCasesPattern) (span : PsSourceSpan) :
    Except PsElabError PsProofState :=
  psProofRCasesComplete elaborate state fun frame =>
    psProofRCasesTargets elaborate scope frame targets
      (pattern.getD (.tuple [] span))

mutual
def psProofRIntroCore (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (fuel : Nat) (frame : PsProofRCasesFrame) (pattern : PsSyntaxRIntroPattern)
    (annotation : Option PsSyntaxTerm) (finish : PsProofRCasesContinuation) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .group patterns type _ =>
      psProofRIntroContinue elaborate scope fuel frame patterns (if type.isSome then type else annotation) finish
    | .pattern pattern =>
      let prepared ← psProofPrepareIntro frame.context frame.target (psProofRCasesName? pattern)
      let pattern := match annotation with
        | none => pattern
        | some type => .typed pattern type (psSyntaxRCasesPatternSpan pattern)
      let result ← psProofRCasesCore elaborate scope fuel
        { frame with context := prepared.context, target := prepared.body }
        { value := .fvar prepared.id, pattern } finish
      psElabAbstract frame.context result.context [prepared.abstraction] result.term frame.target

def psProofRIntroContinue (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (fuel : Nat) (frame : PsProofRCasesFrame) (patterns : List PsSyntaxRIntroPattern)
    (annotation : Option PsSyntaxTerm) (finish : PsProofRCasesContinuation) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match patterns with
    | [] => finish frame
    | pattern :: rest =>
      psProofRIntroCore elaborate scope fuel frame pattern annotation
        (fun next => psProofRIntroContinue elaborate scope fuel next rest annotation finish)
end

def psProofRIntro (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (patterns : List PsSyntaxRIntroPattern)
    (annotation : Option PsSyntaxTerm) : Except PsElabError PsProofState :=
  psProofRCasesComplete elaborate state fun frame =>
    psProofRIntroContinue elaborate scope 4096 frame patterns annotation psProofRCasesFinish

def psProofObtain (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (pattern : Option PsSyntaxRCasesPattern)
    (annotation : Option PsSyntaxTerm) (values : Option (List PsSyntaxTerm))
    (span : PsSourceSpan) : Except PsElabError PsProofState :=
  psProofRCasesComplete elaborate state fun frame => do
    match values with
    | some values =>
      if values.isEmpty then throw (.proof "obtain requires a value after :=")
      let pattern := pattern.getD (psProofRCasesDefault span)
      let pattern := match annotation with
        | none => pattern
        | some type => .typed pattern type span
      psProofRCasesTargets elaborate scope frame (values.map fun term => { term }) pattern
    | none =>
      let some source := annotation
        | throw (.proof "obtain requires an expected type or a value")
      let type ← psProofRCasesType elaborate scope frame.context source
      let fresh := psMetaFresh type.context.metaContext type.context.localContext type.term
        .syntheticOpaque { tag := psProofTag frame.tag "obtain" }
      let context := psElabContextWithMeta type.context fresh.context
      let pattern := pattern.getD (.one (PsSyntaxName.mk ["this"] span))
      let name ← match psProofRCasesName? pattern with
        | some source => match psSyntaxNameToName source with
          | some name => pure name
          | none => throw .emptyName
        | none => pure (psNameAppendNum (psRootName "$psc0Obtain") context.localContext.nextId)
      let pushed := psLocalPushBinding context.localContext name type.term .explicit
      let result ← psProofRCasesCore elaborate scope 4096
        { frame with context := psElabContextWithLocal context pushed.context }
        { value := .fvar pushed.id, pattern } psProofRCasesFinish
      psElabAbstract context result.context
        [.letE pushed.id name type.term fresh.expr] result.term frame.target
