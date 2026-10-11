import Ps.Elab.Basic

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
  environment : PsEnvironment
  scope : PsCommandScope
  selfName : Option (List String) := none
  selfArguments : List PsSyntaxTerm := []
  deferProofNames : Bool := false

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
    psEnvironmentContains resolver.environment (psSyntaxNameAppendSegments segments .anonymous)

-- A qualified global may be followed by projections. Match the longest namePrefix
-- through the environment index, using the same rule as term elaboration.
def psScopeGlobalBase (resolver : PsScopeResolver) (segments : List String) : Bool :=
  (psScopePrefixes segments).any fun namePrefix =>
    !namePrefix.isEmpty && psScopeHasGlobal resolver namePrefix

def psScopeResolve (resolver : PsScopeResolver) (bound : List String)
    (name : PsSyntaxName) : Except PsElabError (Prod PsSyntaxName (List String)) := do
  let segments := psSyntaxNameRootSegments name.segments
  let some first := segments.head? | throw .emptyName
  let rooted := name.segments.head? == some "_root_"
  if !rooted then
    if bound.contains first then return (name, [])
    if psScopeHasVariable resolver.scope first then
      return (name, [first])
  if resolver.deferProofNames then return (name, [])
  if segments == ["Type"] || segments == ["Prop"] then
    return ({ name with segments := ["_root_"] ++ segments }, [])
  let candidates := if rooted then [segments]
    else (psScopePrefixes resolver.scope.namePrefix).map (· ++ segments)
  match candidates.find? (psScopeGlobalBase resolver) with
  | some full => return ({ name with segments := "_root_" :: full }, [])
  | none => pure ()
  if rooted then throw (.scope ("unknown global " ++ psScopeKey name))
  let opened := (resolver.scope.opened.map (· ++ segments)).filter (psScopeGlobalBase resolver)
  let unique := opened.foldl (fun acc item => if acc.contains item then acc else item :: acc) []
  match unique with
  | [full] => return ({ name with segments := "_root_" :: full }, [])
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

-- An annotation sees preceding groups; all names of its group enter together.
def psScopeBinders (visit : PsScopeVisitor) (bound : List String)
    (binders : List PsScopeBinder) : Except PsElabError PsScopeBindersResult := do
  match binders with
  | [] => return { binders := [], bound, used := [] }
  | (head, type) :: rest =>
    let annotation ← visit bound type
    let next ← psScopeBinders visit (psScopeBinderKeys head ++ bound) rest
    return {
      binders := (head, annotation.term) :: next.binders
      bound := next.bound
      used := psScopeUnion annotation.used next.used }

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
      return .ctor resolved (← fields.mapM (psScopePattern fuel resolver)) span
    | _ => return pattern

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
        | .exactE value _ _ | .applyE value _ | .change value _ _ => do
          let result ← visit bound value
          pure (result.used, bound)
        | .localE name type value _ _ => do
          let annotation ← type.mapM (visit bound)
          let value ← visit bound value
          pure (psScopeUnion (annotation.map (·.used) |>.getD []) value.used,
            psScopeKey name :: bound)
        | .focus body _ _ | .each body _ _ => do
          let used ← psScopeTacticDependencies fuel visit bound body
          pure (used, bound)
        | _ => pure ([], bound)
      return psScopeUnion used (← psScopeTacticDependencies fuel visit next rest)

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
    | .byE tactics _ span =>
      let used ← psScopeTacticDependencies fuel
        (psScopeTerm fuel { resolver with deferProofNames := true }) bound tactics
      return { term := .byE tactics {
        namePrefix := resolver.scope.namePrefix, opened := resolver.scope.opened } span, used }
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
    | .ifE condition yes no span =>
      let condition ← visit bound condition
      let yes ← visit bound yes
      let no ← visit bound no
      return {
        term := .ifE condition.term yes.term no.term span
        used := psScopeUnion condition.used (psScopeUnion yes.used no.used) }
    | .matchMany scrutinees alternatives span =>
      let scrutinees ← scrutinees.mapM (visit bound)
      let alternatives ← alternatives.mapM fun (patterns, body, bodySpan) => do
        let patterns ← patterns.mapM (psScopePattern fuel resolver)
        let names := patterns.flatMap (psSyntaxPatternNames 4096)
        let keys := names.map psScopeKey
        if keys.any (fun key => (keys.filter (· == key)).length > 1) then
          throw (.scope "duplicate pattern variable")
        let body ← visit (keys ++ bound) body
        return (patterns, body, bodySpan)
      return {
        term := .matchMany (scrutinees.map (·.term))
          (alternatives.map fun (patterns, body, bodySpan) => (patterns, body.term, bodySpan)) span
        used := alternatives.foldl (fun acc alt => psScopeUnion acc alt.snd.fst.used)
          (scrutinees.foldl (fun acc item => psScopeUnion acc item.used) []) }
    | _ => return { term := source }

def psScopeQualified (scope : PsCommandScope) (name : PsSyntaxName) : PsSyntaxName :=
  { name with segments := if name.segments.head? == some "_root_" then
      psSyntaxNameRootSegments name.segments else scope.namePrefix ++ name.segments }

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
