import Ps.Elab.Application

-- Native PatternVar leaves resolved constructor parameters as ordinary terms.
-- A dot-head remains distinct: its arguments were collected as patterns before
-- the expected inductive family resolves the constructor.
def psElabPatternMarkParameterPrefix (count : Nat) (name : PsName)
    (context : PsElabContext) (type : PsExpr) (patterns : List PsSyntaxPattern) :
    Except PsElabError (List PsSyntaxPattern) := do
  match count with
  | 0 => return patterns
  | count + 1 =>
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext type).mapError PsElabError.infer
    let pushed := psLocalPushBinding context.localContext pi.name pi.domain pi.binder
    let next := psElabContextWithLocal context pushed.context
    let body := psExprInstantiate1 pi.body (.fvar pushed.id)
    if psBinderAcceptsExplicitArgument pi.binder then
      let pattern :: rest := patterns | throw (.matchConstructorArity name)
      let pattern := match pattern with
        | .inaccessible _ => pattern
        | _ => .inaccessible pattern
      return pattern :: (← psElabPatternMarkParameterPrefix count name next body rest)
    psElabPatternMarkParameterPrefix count name next body patterns

def psElabPatternMarkParameters (environment : PsEnvironment)
    (source : PsSyntaxName) (patterns : List PsSyntaxPattern) :
    Except PsElabError (List PsSyntaxPattern) := do
  let some name := psSyntaxNameToName source | throw .emptyName
  let some constructor := psEnvironmentFindConstructor environment name | return patterns
  psElabPatternMarkParameterPrefix constructor.numParams name
    (psElabContextEmpty environment constructor.levelParams) constructor.type patterns

def psElabPatternPrepare (fuel : Nat) (environment : PsEnvironment)
    (pattern : PsSyntaxPattern) : Except PsElabError PsSyntaxPattern := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .ctor name fields span =>
      let fields ← psElabPatternMarkParameters environment name fields
      return .ctor name (← fields.mapM (psElabPatternPrepare fuel environment)) span
    | .dotCtor name fields span =>
      return .dotCtor name (← fields.mapM (psElabPatternPrepare fuel environment)) span
    | _ => return pattern

def psElabPatternTerm (fuel : Nat) (pattern : PsSyntaxPattern) :
    Except PsElabError PsSyntaxTerm := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .variable name =>
      if psSyntaxNameIsAnonymous name then return .hole name.span
      return .reference name
    | .wildcard span => return .hole span
    | .natural value span => return .natural (toString value) span
    | .bool value span => return .bool value span
    | .inaccessible value => psElabPatternTerm fuel value
    | .ctor name fields span =>
      if fields.isEmpty then return .reference name
      return .app (.reference name) (← fields.mapM (psElabPatternTerm fuel)) span
    | .dotCtor .. => throw .matchPatternUnsupported

def psElabPatternFromTerm (fuel : Nat) (term : PsSyntaxTerm) :
    Except PsElabError PsSyntaxPattern := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match term with
    | .reference name => return .variable name
    | .hole span => return .wildcard span
    | .natural text span =>
      let some value := psParseNaturalText text | throw (.invalidNatural text)
      return .natural value span
    | .bool value span => return .bool value span
    | .app head arguments span =>
      let head ← psElabPatternFromTerm fuel head
      let arguments ← arguments.mapM (psElabPatternFromTerm fuel)
      match head with
      | .variable name => return .ctor name arguments span
      | .ctor name earlier _ => return .ctor name (earlier ++ arguments) span
      | _ => throw .matchPatternUnsupported
    | _ => throw .matchPatternUnsupported

-- This uses the ordinary ordered application owner, including its implicit,
-- instance, default and expected-type rules. Only dot-head resolution belongs
-- to the retained pattern syntax; no parameter is made into a pattern binder.
def psElabPatternParameter (branch : PsElaborator) (fuel : Nat)
    (context : PsElabContext) (pattern : PsSyntaxPattern) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .inaccessible value => psElabPatternParameter branch fuel context value expected
    | .ctor source arguments _ | .dotCtor source arguments _ =>
      let head ← match pattern with
        | .dotCtor .. => do
          let some expected := expected | throw .matchExpectedType
          let view := psReduceAppView
            (psWhnf context.environment context.metaContext context.localContext expected)
          let .constE family _ := view.head | throw .matchScrutineeUnsupported
          let some familyInfo := psEnvironmentFindInductive context.environment family
            | throw .matchScrutineeUnsupported
          let name ← match source.segments with
            | [] => throw .emptyName
            | [segment] => pure (psNameAppendStr family segment)
            | _ =>
              let some name := psSyntaxNameToName source | throw .emptyName
              pure name
          unless familyInfo.constructors.any (psNameEq name) do
            throw (.matchConstructorUnknown name)
          let (context, value) ← psElabResolvedReference context (.global name)
          psElabResolvedTerm context value none
        | _ => branch context (.reference source) none
      let application ← psElabApplyOrderedWith (psElabPatternParameter branch fuel) 4096
        head arguments [] [] (!arguments.isEmpty || expected.isSome) expected
      psElabFinishApplication application expected
    | _ => branch context (← psElabPatternTerm fuel pattern) expected
