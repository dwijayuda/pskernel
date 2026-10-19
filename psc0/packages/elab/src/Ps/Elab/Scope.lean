import Ps.Elab.PatternSyntax

abbrev PsScopeBinder := Prod PsSyntaxBinderHead PsSyntaxTerm

structure PsScopeVariable where
  binder : PsScopeBinder
  dependencies : List String

structure PsCommandScope where
  levelNames : List String := []
  namePrefix : List String := []
  opened : List (List String) := []
  variables : List PsScopeVariable := []
  included : List String := []

structure PsScopeFrame where
  label : Option (List String)
  saved : PsCommandScope

structure PsScopeResolver where
  abstractProofs : Bool := false
  environment : PsEnvironment
  scope : PsCommandScope
  selfName : Option (List String) := none
  selfArguments : List PsSyntaxTerm := []
  deferProofNames : Bool := false
  -- Source-visible qualified private name to stable module-local kernel name.
  privateAliases : List (List String × List String) := []
  -- Joint headers are scope identities, never temporary environment axioms.
  mutualNames : List (List String) := []
  -- A body sees typed local lets applying each real opaque to common captures.
  mutualAliases : List (List String × List String) := []
  localAliases : List (String × List String) := []

def psScopeKey (name : PsSyntaxName) : String := String.intercalate "." name.segments

def psScopeBinderKeys (head : PsSyntaxBinderHead) : List String :=
  (psSyntaxBinderNames head).map psScopeKey

def psScopeHasVariable (scope : PsCommandScope) (key : String) : Bool :=
  scope.variables.any (fun entry => (psScopeBinderKeys entry.binder.fst).contains key)

def psScopeUnion (left right : List String) : List String :=
  right.foldl (fun acc name => if acc.contains name then acc else name :: acc) left

def psScopeReversedPrefixes (reversed : List String) : List (List String) :=
  match reversed with
  | [] => [[]]
  | _ :: rest => reversed.reverse :: psScopeReversedPrefixes rest

-- Remove the final component each time, keeping the nearest namespace first.
def psScopePrefixes (namePrefix : List String) : List (List String) :=
  psScopeReversedPrefixes namePrefix.reverse

def psScopeHasGlobal (resolver : PsScopeResolver) (segments : List String) : Bool :=
  resolver.selfName == some segments ||
    resolver.mutualNames.contains segments ||
    resolver.mutualAliases.any (fun entry => entry.fst == segments) ||
    psEnvironmentContains resolver.environment (psSyntaxNameAppendSegments segments .anonymous)

def psScopeExportedRewrite (resolver : PsScopeResolver)
    (segments : List String) : Option (List String) := do
  let requested := psSyntaxNameAppendSegments segments .anonymous
  -- A real declaration in the nearest namespace shadows an exported alias.
  if psScopeHasGlobal resolver segments then none
  else
    let alias ← resolver.environment.exportedAliases.find? (fun entry =>
      psNameEq entry.fst requested)
    return (psNameToString alias.snd).splitOn "."

-- A qualified global may be followed by projections. Match the longest namePrefix
-- through the environment index, using the same rule as term elaboration.
def psScopeGlobalBase (resolver : PsScopeResolver) (segments : List String) : Bool :=
  (psScopePrefixes segments).any fun namePrefix =>
    !namePrefix.isEmpty && (psScopeHasGlobal resolver namePrefix ||
      (psScopeExportedRewrite resolver namePrefix).isSome)

-- Resolve the longest private prefix first. This also preserves projection
-- suffixes on a private structure and recursive references to its members.
def psScopePrivateRewrite (resolver : PsScopeResolver)
    (segments : List String) : Option (List String) := do
  let matchPrefix ← (psScopePrefixes segments).find? (fun candidate =>
    resolver.privateAliases.any (fun entry => entry.fst == candidate))
  let alias ← resolver.privateAliases.find? (fun entry => entry.fst == matchPrefix)
  return alias.snd ++ segments.drop matchPrefix.length

-- Keep these references local, including qualified peer projections. The
-- aliases cannot be written by ordinary source and are checked local lets.
def psScopeMutualRewrite (resolver : PsScopeResolver)
    (segments : List String) : Option (List String) := do
  let matchPrefix ← (psScopePrefixes segments).find? (fun candidate =>
    resolver.mutualAliases.any (fun entry => entry.fst == candidate))
  let alias ← resolver.mutualAliases.find? (fun entry => entry.fst == matchPrefix)
  return alias.snd ++ segments.drop matchPrefix.length

def psScopeResolve (resolver : PsScopeResolver) (bound : List String)
    (name : PsSyntaxName) : Except PsElabError (Prod PsSyntaxName (List String)) := do
  let segments := psSyntaxNameRootSegments name.segments
  let some first := segments.head? | throw .emptyName
  let rooted := name.segments.head? == some "_root_"
  if !rooted then
    if bound.contains first then return (name, [])
    if let some (_, replacement) := resolver.localAliases.find? (fun entry => entry.fst == first) then
      return ({ name with segments := replacement ++ segments.drop 1 }, [])
    if psScopeHasVariable resolver.scope first then
      return (name, [first])
  if resolver.deferProofNames then return (name, [])
  if segments == ["Type"] || segments == ["Prop"] then
    return ({ name with segments := ["_root_"] ++ segments }, [])
  let candidates := if rooted then [segments]
    else (psScopePrefixes resolver.scope.namePrefix).map (· ++ segments)
  let available := fun (key : List String) =>
    (psScopePrivateRewrite resolver key).isSome || psScopeGlobalBase resolver key
  let canonical := fun key =>
    (psScopePrivateRewrite resolver key).getD
      ((psScopeExportedRewrite resolver key).getD key)
  let reference := fun key =>
    let resolved := canonical key
    { name with
      segments := (psScopeMutualRewrite resolver resolved).getD ("_root_" :: resolved) }
  match candidates.find? available with
  | some full =>
    return (reference full, [])
  | none => pure ()
  if rooted then throw (.scope ("unknown global " ++ psScopeKey name))
  let opened := (resolver.scope.opened.map (· ++ segments)).filter available
  let unique := opened.foldl (fun acc item => if acc.contains item then acc else item :: acc) []
  match unique with
  | [full] =>
    return (reference full, [])
  | [] => throw (.scope ("unknown name " ++ psScopeKey name))
  | _ => throw (.scope ("ambiguous open name " ++ psScopeKey name))

structure PsScopeTermResult where
  term : PsSyntaxTerm
  used : List String := []

abbrev PsScopeVisitor :=
  List String → PsSyntaxTerm → Except PsElabError PsScopeTermResult

structure PsScopeBindersResult where
  binders : List PsScopeBinder
  bound : List String
  used : List String

-- Pinned Lean 4.35.0 toBinderViews/elabBinderViews processes group names
-- in order. Resolve each annotation in that actual prefix; preserving a
-- pre-resolved shared type would hide shadowing from later binder views.
def psScopeBinderNames (visit : PsScopeVisitor) (bound : List String)
    (head : PsSyntaxBinderHead) (type : PsSyntaxTerm) (names : List PsSyntaxName) :
    Except PsElabError PsScopeBindersResult := do
  match names with
  | [] => return { binders := [], bound, used := [] }
  | name :: rest =>
    let annotation ← visit bound type
    let next ← psScopeBinderNames visit (psScopeKey name :: bound) head type rest
    let origin := head.origin.getD {
      names := psSyntaxBinderNames head
      index := (psSyntaxBinderNames head).length - names.length }
    return {
      binders := ({ head with name, moreNames := [], origin := some origin }, annotation.term) :: next.binders
      bound := next.bound
      used := psScopeUnion annotation.used next.used }

def psScopeBinders (visit : PsScopeVisitor) (bound : List String)
    (binders : List PsScopeBinder) : Except PsElabError PsScopeBindersResult := do
  match binders with
  | [] => return { binders := [], bound, used := [] }
  | (head, type) :: rest =>
    let group ← psScopeBinderNames visit bound head type (psSyntaxBinderNames head)
    let next ← psScopeBinders visit group.bound rest
    return {
      binders := group.binders ++ next.binders
      bound := next.bound
      used := psScopeUnion group.used next.used }

def psScopeSelfArguments (resolver : PsScopeResolver) (bound : List String)
    (fn : PsSyntaxTerm) : Except PsElabError (List PsSyntaxTerm) := do
  match fn with
  | .reference name =>
    if name.segments.head? != some "_root_" ||
        resolver.selfName != some (psSyntaxNameRootSegments name.segments) then return []
    if resolver.selfArguments.any (fun arg => match arg with
        | .reference parameter => bound.contains (psScopeKey parameter)
        | _ => false) then
      throw (.scope "recursive section parameter is shadowed; explicit fixed-parameter syntax is pending")
    return resolver.selfArguments
  | _ => return []

-- Constructor identity is resolved before matrix specialization; variables
-- remain lexical binders. An unqualified constructor head can be supplied by
-- the scrutinee's family during elaboration (including leading-dot patterns).
def psScopePattern (fuel : Nat) (resolver : PsScopeResolver)
    (pattern : PsSyntaxPattern) : Except PsElabError PsSyntaxPattern := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 => match pattern with
    | .variable name =>
      match psScopeResolve resolver [] name with
      | .ok (resolved, _) =>
        match psSyntaxNameToName resolved with
        | some core =>
          if (psEnvironmentFindConstructor resolver.environment core).isSome then
            return .ctor resolved [] name.span
          else return pattern
        | none => return pattern
      | .error _ => return pattern
    | .ctor name fields span =>
      let resolved ← match psScopeResolve resolver [] name with
        | .ok (resolved, _) => pure resolved
        | .error (.scope message) =>
          if name.segments.length == 1 && message.startsWith "unknown name" then pure name
          else throw (.scope message)
        | .error error => throw error
      let fields ← psElabPatternMarkParameters resolver.environment resolved fields
      return .ctor resolved (← fields.mapM (psScopePattern fuel resolver)) span
    | .dotCtor name fields span =>
      return .dotCtor name (← fields.mapM (psScopePattern fuel resolver)) span
    | _ => return pattern

-- Only resolved constructor parameter positions are ordinary term scopes.
-- Keep dot-heads in those terms until their actual expected type is available.
def psScopePatternParameterValues (fuel : Nat) (resolver : PsScopeResolver)
    (visit : PsScopeVisitor) (bound : List String) (pattern : PsSyntaxPattern) :
    Except PsElabError (PsSyntaxPattern × List String) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .variable name =>
      if name.segments == ["_"] then return (pattern, [])
      let result ← visit bound (.reference name)
      return (← psElabPatternFromTerm fuel result.term, result.used)
    | .ctor name arguments span =>
      let head ← visit bound (.reference name)
      let fixed ← psScopeSelfArguments resolver bound head.term
      let headUsed := head.used
      let head ← psElabPatternFromTerm fuel head.term
      let fixed ← fixed.mapM (psElabPatternFromTerm fuel)
      let arguments ← arguments.mapM
        (psScopePatternParameterValues fuel resolver visit bound)
      let (name, earlier) ← match head with
        | .variable name => pure (name, [])
        | .ctor name earlier _ => pure (name, earlier)
        | _ => throw .matchPatternUnsupported
      let used := arguments.foldl (fun acc argument => psScopeUnion acc argument.snd) headUsed
      return (.ctor name (earlier ++ fixed ++ arguments.map (·.fst)) span, used)
    | .dotCtor name arguments span =>
      let arguments ← arguments.mapM
        (psScopePatternParameterValues fuel resolver visit bound)
      return (.dotCtor name (arguments.map (·.fst)) span,
        arguments.foldl (fun acc argument => psScopeUnion acc argument.snd) [])
    | .inaccessible value =>
      let (value, used) ← psScopePatternParameterValues fuel resolver visit bound value
      return (.inaccessible value, used)
    | _ => return (pattern, [])

def psScopePatternValues (fuel : Nat) (resolver : PsScopeResolver)
    (visit : PsScopeVisitor) (bound : List String) (pattern : PsSyntaxPattern) :
    Except PsElabError (PsSyntaxPattern × List String) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .inaccessible value =>
      let (value, used) ← psScopePatternParameterValues fuel resolver visit bound value
      return (.inaccessible value, used)
    | .ctor name arguments span | .dotCtor name arguments span =>
      let arguments ← arguments.mapM (psScopePatternValues fuel resolver visit bound)
      let pattern := match pattern with
        | .dotCtor .. => PsSyntaxPattern.dotCtor name (arguments.map (·.fst)) span
        | _ => PsSyntaxPattern.ctor name (arguments.map (·.fst)) span
      return (pattern, arguments.foldl (fun acc argument => psScopeUnion acc argument.snd) [])
    | _ => return (pattern, [])

-- Static section capture follows explicit tactic binders. Actual proof-name
-- resolution is delayed until the goal's complete local context is available.
def psScopeTacticDependencies (fuel : Nat) (visit : PsScopeVisitor)
    (bound : List String) (tactics : List PsSyntaxTactic) :
    Except PsElabError (List String) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match tactics with
    | [] => return []
    | tactic :: rest =>
      let (used, next) ← match tactic with
        | .intro names _ => pure ([], names.map psScopeKey ++ bound)
        | .exactE value _ _ | .applyE value _ | .change value _ _ | .eliminate value _ _ => do
          let result ← visit bound value
          pure (result.used, bound)
        | .localE name type value _ _ => do
          let annotation ← type.mapM (visit bound)
          let value ← visit bound value
          pure (psScopeUnion (annotation.map (·.used) |>.getD []) value.used,
            psScopeKey name :: bound)
        | .caseE _ names body _ => do
          let used ← psScopeTacticDependencies fuel visit (names.map psScopeKey ++ bound) body
          pure (used, bound)
        | .focus body _ _ | .each body _ _ => do
          let used ← psScopeTacticDependencies fuel visit bound body
          pure (used, bound)
        | _ => pure ([], bound)
      return psScopeUnion used (← psScopeTacticDependencies fuel visit next rest)

structure PsScopeDoResult where
  items : List PsSyntaxDoItem
  used : List String

def psScopePatternKeys (patterns : List PsSyntaxPattern) : Except PsElabError (List String) := do
  let keys := (patterns.flatMap (psSyntaxPatternNames 4096)).map psScopeKey
  if keys.any (fun key => (keys.filter (· == key)).length > 1) then
    throw (.scope "duplicate pattern variable")
  return keys

def psScopeDo (fuel : Nat) (resolver : PsScopeResolver) (visit : PsScopeVisitor)
    (bound : List String) (items : List PsSyntaxDoItem) : Except PsElabError PsScopeDoResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 => match items with
    | [] => return { items := [], used := [] }
    | item :: rest =>
      let (item, used, nextBound) ← match item with
        | .binding pattern type value monadic span => do
          let pattern ← psScopePattern fuel resolver pattern
          let keys ← psScopePatternKeys [pattern]
          let (pattern, patternUsed) ←
            psScopePatternValues fuel resolver visit (keys ++ bound) pattern
          let type ← type.mapM (visit bound)
          let value ← visit bound value
          pure (.binding pattern (type.map (·.term)) value.term monadic span,
            psScopeUnion patternUsed (psScopeUnion (type.map (·.used) |>.getD []) value.used),
            keys ++ bound)
        | .action value span | .returnValue value span => do
          let value ← visit bound value
          let item := match item with
            | .action .. => PsSyntaxDoItem.action value.term span
            | _ => PsSyntaxDoItem.returnValue value.term span
          pure (item, value.used, bound)
        | .conditional name condition yes no span => do
          let condition ← visit bound condition
          let branchBound := name.toList.map psScopeKey ++ bound
          let yes ← psScopeDo fuel resolver visit branchBound yes
          let no ← psScopeDo fuel resolver visit branchBound no
          pure (.conditional name condition.term yes.items no.items span,
            psScopeUnion condition.used (psScopeUnion yes.used no.used), bound)
        | .conditionalPattern pattern value yes no span => do
          let pattern ← psScopePattern fuel resolver pattern
          let keys ← psScopePatternKeys [pattern]
          let (pattern, patternUsed) ←
            psScopePatternValues fuel resolver visit (keys ++ bound) pattern
          let value ← visit bound value
          let yes ← psScopeDo fuel resolver visit (keys ++ bound) yes
          let no ← psScopeDo fuel resolver visit bound no
          pure (.conditionalPattern pattern value.term yes.items no.items span,
            psScopeUnion patternUsed (psScopeUnion value.used (psScopeUnion yes.used no.used)),
            bound)
      let rest ← psScopeDo fuel resolver visit nextBound rest
      return { items := item :: rest.items, used := psScopeUnion used rest.used }

-- This single capture-aware walk qualifies references and collects section
-- dependencies. Labels/field names stay labels; binders and patterns delimit
-- visibility explicitly. It never rewrites printed text.
def psScopeTerm (fuel : Nat) (resolver : PsScopeResolver) (bound : List String)
    (source : PsSyntaxTerm) : Except PsElabError PsScopeTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let visit := psScopeTerm fuel resolver
    match source with
    | .doE items span =>
      let resolved ← psScopeDo fuel resolver visit bound items
      return { term := .doE resolved.items span, used := resolved.used }
    | .byE tactics _ span =>
      let used ← psScopeTacticDependencies fuel
        (psScopeTerm fuel { resolver with deferProofNames := true }) bound tactics
      return { term := .byE tactics {
        abstractProofs := resolver.abstractProofs
        namePrefix := resolver.scope.namePrefix, opened := resolver.scope.opened,
        privateAliases := resolver.privateAliases
        mutualAliases := resolver.mutualAliases
        localAliases := resolver.localAliases } span, used }
    | .reference name =>
      let resolved ← psScopeResolve resolver bound name
      return { term := .reference resolved.fst, used := resolved.snd }
    | .optionalType type value span =>
      let type ← visit bound type
      let value ← visit bound value
      return {
        term := .optionalType type.term value.term span
        used := psScopeUnion type.used value.used }
    | .ascription value type span =>
      let type ← visit bound type
      let value ← visit bound value
      return {
        term := .ascription value.term type.term span
        used := psScopeUnion type.used value.used }
    | .operatorE kind name spelling args span =>
      let fn ← psScopeResolve resolver bound name
      let args ← args.mapM (visit bound)
      return {
        term := .operatorE kind fn.fst spelling (args.map (·.term)) span
        used := args.foldl (fun acc arg => psScopeUnion acc arg.used) fn.snd }
    | .call fn args span =>
      let fn ← visit bound fn
      let fixed ← psScopeSelfArguments resolver bound fn.term
      let args ← args.mapM fun (label, value) => do
        let value ← visit bound value
        return (label, value)
      return {
        term := .call fn.term (fixed.map (fun arg => (none, arg)) ++
          args.map fun (label, value) => (label, value.term)) span
        used := args.foldl (fun acc arg => psScopeUnion acc arg.snd.used) fn.used }
    | .app fn args span =>
      let fn ← visit bound fn
      let fixed ← psScopeSelfArguments resolver bound fn.term
      let args ← args.mapM (visit bound)
      return {
        term := .app fn.term (fixed ++ args.map (·.term)) span
        used := args.foldl (fun acc arg => psScopeUnion acc arg.used) fn.used }
    | .record fields span =>
      let fields ← fields.mapM fun (name, value) => do
        let value ← visit bound value
        return (name, value)
      return {
        term := .record (fields.map fun (name, value) => (name, value.term)) span
        used := fields.foldl (fun acc field => psScopeUnion acc field.snd.used) [] }
    | .recordUpdate source fields span =>
      let source ← visit bound source
      let fields ← fields.mapM fun (name, value) => do
        let value ← visit bound value
        return (name, value)
      return {
        term := .recordUpdate source.term (fields.map fun (name, value) => (name, value.term)) span
        used := fields.foldl (fun acc field => psScopeUnion acc field.snd.used) source.used }
    | .lambda binders body span | .forallE binders body span =>
      let binders ← psScopeBinders visit bound binders
      let body ← visit binders.bound body
      let term := match source with
        | .lambda _ _ _ => PsSyntaxTerm.lambda binders.binders body.term span
        | _ => PsSyntaxTerm.forallE binders.binders body.term span
      return { term, used := psScopeUnion binders.used body.used }
    | .letE name type value body span | .haveE name type value body span =>
      let type ← type.mapM (visit bound)
      let value ← visit bound value
      let body ← visit (psScopeKey name :: bound) body
      let term := match source with
        | .haveE .. => PsSyntaxTerm.haveE name (type.map (·.term)) value.term body.term span
        | _ => PsSyntaxTerm.letE name (type.map (·.term)) value.term body.term span
      return {
        term
        used := psScopeUnion (type.map (·.used) |>.getD []) (psScopeUnion value.used body.used) }
    | .ifE name condition yes no span =>
      let condition ← visit bound condition
      let branchBound := name.toList.map psScopeKey ++ bound
      let yes ← visit branchBound yes
      let no ← visit branchBound no
      return {
        term := .ifE name condition.term yes.term no.term span
        used := psScopeUnion condition.used (psScopeUnion yes.used no.used) }
    | .matchMany discriminants alternatives generalizing? span =>
      let equationKeys := (psSyntaxMatchEquationNames discriminants).map psScopeKey
      let discriminants ← discriminants.mapM fun discriminant => do
        let term ← visit bound discriminant.term
        return (discriminant, term)
      let alternatives ← alternatives.mapM fun (patterns, body, bodySpan) => do
        let patterns ← patterns.mapM (psScopePattern fuel resolver)
        let names := patterns.flatMap (psSyntaxPatternNames 4096)
        let keys := names.map psScopeKey
        if keys.any (fun key => (keys.filter (· == key)).length > 1) then
          throw (.scope "duplicate pattern variable")
        let patterns ← patterns.mapM
          (psScopePatternValues fuel resolver visit (keys ++ bound))
        let patternUsed := patterns.foldl
          (fun acc pattern => psScopeUnion acc pattern.snd) []
        -- Native withEqs extends the RHS scope after every pattern binder.
        let body ← visit (equationKeys ++ keys ++ bound) body
        return (patterns.map (·.fst), { body with used := psScopeUnion patternUsed body.used }, bodySpan)
      return {
        term := .matchMany
          (discriminants.map fun (discriminant, term) => { discriminant with term := term.term })
          (alternatives.map fun (patterns, body, bodySpan) => (patterns, body.term, bodySpan))
          generalizing? span
        used := alternatives.foldl (fun acc alt => psScopeUnion acc alt.snd.fst.used)
          (discriminants.foldl (fun acc item => psScopeUnion acc item.snd.used) []) }
    | _ => return { term := source }

def psScopeQualified (scope : PsCommandScope) (name : PsSyntaxName) : PsSyntaxName :=
  { name with segments := if name.segments.head? == some "_root_" then
      psSyntaxNameRootSegments name.segments else scope.namePrefix ++ name.segments }

-- Canonical declaration names may begin with a literal _root_ namespace.
-- Protect that component when returning to syntax, where one leading marker
-- denotes an absolute name and is removed by psSyntaxNameToName.
def psScopeCanonicalNameSyntax (name : PsSyntaxName) : PsSyntaxName :=
  if name.segments.head? == some "_root_" then
    { name with segments := "_root_" :: name.segments }
  else name

-- Variable annotations only reference earlier variables. One reverse pass
-- closes dependencies; a forward pass then adds eligible instance variables.
-- No whole-scope fixed-point iteration or generalization by proof body.
def psScopeSelect (scope : PsCommandScope) (used : List String) : List PsScopeBinder :=
  let selected := scope.variables.reverse.foldl (fun acc entry =>
    if (psScopeBinderKeys entry.binder.fst).any acc.contains then
      psScopeUnion acc entry.dependencies else acc) used
  let selected := scope.variables.foldl (fun acc entry =>
    match entry.binder.fst.kind with
    | .instanceImplicit =>
      if entry.dependencies.all acc.contains then psScopeUnion acc (psScopeBinderKeys entry.binder.fst)
      else acc
    | _ => acc) selected
  scope.variables.filterMap fun entry =>
    (psSyntaxBinderSelectNames entry.binder.fst (fun name => selected.contains (psScopeKey name))).map
      (fun head => (head, entry.binder.snd))

