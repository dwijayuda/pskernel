import Ps.Elab.Declaration

-- Lean 4.35.0 SyntheticMVars.runTactic and Meta.Closure.mkAuxTheorem:
-- an exporting `by` proof is closed over its actual typed dependencies and
-- retained as a checked theorem. The ordinary typed let below is only an
-- elaboration boundary; neither its spelling nor this pass grants authority.
-- Detect boundaries without rechecking unchanged modules.
def psElabExposedProofHasBoundary : PsExpr → Bool
  | .letE name type value body =>
    psElabExposedProofIsBoundaryName name ||
      psElabExposedProofHasBoundary type || psElabExposedProofHasBoundary value ||
        psElabExposedProofHasBoundary body
  | .app function argument =>
    psElabExposedProofHasBoundary function || psElabExposedProofHasBoundary argument
  | .lam _ type body _ | .forallE _ type body _ =>
    psElabExposedProofHasBoundary type || psElabExposedProofHasBoundary body
  | .proj _ _ value => psElabExposedProofHasBoundary value
  | _ => false

def psElabExposedProofDeclarationHasBoundary (declaration : PsDeclaration) : Bool :=
  psElabExposedProofHasBoundary (psDeclarationType declaration) ||
    match declaration with
    | .definitionDecl _ _ _ value | .theoremDecl _ _ _ value
    | .opaqueDecl _ _ _ value | .partialDecl _ _ _ value =>
      psElabExposedProofHasBoundary value
    | _ => false

structure PsElabExposedProofClosed where
  value : PsExpr
  type : PsExpr
  arguments : List PsExpr := []

-- The input has no loose bound variables. Opening/closing a free identity
-- therefore gives capture-avoiding substitution, including under binders.
def psElabExposedProofSubstitute (id : Nat) (value expression : PsExpr) : PsExpr :=
  psExprInstantiate1 (psExprAbstractFVar id expression) value

-- Newest-first closure retains precisely the used binding dependency closure.
-- Let-bound locals are expanded in value and type, matching zetaDelta := true;
-- a private computational value cannot escape as a new argument.
def psElabExposedProofClose (locals : PsLocalContext) (value type : PsExpr) :
    PsElabExposedProofClosed :=
  locals.declarations.foldl (fun (closed : PsElabExposedProofClosed) declaration =>
    match declaration with
    | .letDecl id _ _ value =>
      { closed with
        value := psElabExposedProofSubstitute id value closed.value
        type := psElabExposedProofSubstitute id value closed.type }
    | .binding id name type binder =>
      if (psExprFVarIds closed.value).contains id || (psExprFVarIds closed.type).contains id then
        { value := .lam name type (psExprAbstractFVar id closed.value) binder
          type := .forallE name type (psExprAbstractFVar id closed.type) binder
          arguments := .fvar id :: closed.arguments }
      else closed)
    { value, type }

structure PsElabExposedProofState where
  environment : PsEnvironment
  auxiliaries : List PsDeclaration := []
  owners : List (PsName × PsName) := []
  nextIndex : Nat := 0
  boundaries : List PsName := []

def psElabExposedProofFresh (fuel : Nat) (environment : PsEnvironment)
    (owner : PsName) (index : Nat) : Except PsElabError (PsName × Nat) := do
  match fuel with
  | 0 => throw (.data "PSCV0-PROOF-ABSTRACTION-NAME: auxiliary name budget")
  | fuel + 1 =>
    let name := PsName.num (psNameAppendStr owner "$proof") index
    if psEnvironmentContains environment name then
      psElabExposedProofFresh fuel environment owner (index + 1)
    else return (name, index + 1)

def psElabExposedProofVisit (fuel : Nat) (enabled : Bool)
    (owner : PsName) (levels : List PsName) (locals : PsLocalContext)
    (state : PsElabExposedProofState) (expression : PsExpr) :
    Except PsElabError (PsExpr × PsElabExposedProofState) := do
  match fuel with
  | 0 => throw (.data "PSCV0-PROOF-ABSTRACTION-BUDGET: expression traversal")
  | fuel + 1 =>
    match expression with
    | .app function argument =>
      let (function, state) ← psElabExposedProofVisit fuel enabled owner levels locals state function
      let (argument, state) ← psElabExposedProofVisit fuel enabled owner levels locals state argument
      return (.app function argument, state)
    | .lam name type body binder =>
      let (type, state) ← psElabExposedProofVisit fuel enabled owner levels locals state type
      let pushed := psLocalPushBinding locals name type binder
      let (body, state) ← psElabExposedProofVisit fuel enabled owner levels pushed.context state
        (psExprInstantiate1 body (.fvar pushed.id))
      return (.lam name type (psExprAbstractFVar pushed.id body) binder, state)
    | .forallE name type body binder =>
      let (type, state) ← psElabExposedProofVisit fuel enabled owner levels locals state type
      let pushed := psLocalPushBinding locals name type binder
      let (body, state) ← psElabExposedProofVisit fuel enabled owner levels pushed.context state
        (psExprInstantiate1 body (.fvar pushed.id))
      return (.forallE name type (psExprAbstractFVar pushed.id body) binder, state)
    | .letE name type value body =>
      if psElabExposedProofIsBoundaryName name then
        if !state.boundaries.any (psNameEq name) then
          throw (.data "PSCV0-PROOF-ABSTRACTION-ORIGIN: boundary has no checked source proof")
        let .bvar 0 := body
          | throw (.data "PSCV0-PROOF-ABSTRACTION-BOUNDARY: invalid typed proof boundary")
        if !enabled then
          return ← psElabExposedProofVisit fuel false owner levels locals state value
        -- Retain the expected type carried by the proof boundary, not a
        -- private inferred type that happens to be definitionally equal.
        let (type, state) ← psElabExposedProofVisit fuel true owner levels locals state type
        let (value, state) ← psElabExposedProofVisit fuel false owner levels locals state value
        let context := psElabContextWithLocal (psElabContextEmpty state.environment levels) locals
        let level ← psElabExpressionSort context type
        if !psLevelEquivalent level .zero then
          throw (.data "PSCV0-PROOF-ABSTRACTION-PROP: boundary is not a proposition")
        let checked ← psElabResolvedTerm context value (some type)
        let closed := psElabExposedProofClose locals checked.term type
        if psExprHasUnresolvedMeta closed.value || psExprHasUnresolvedMeta closed.type ||
            !psExprFVarsInContext psLocalEmpty closed.value ||
            !psExprFVarsInContext psLocalEmpty closed.type then
          throw (.data "PSCV0-PROOF-ABSTRACTION-CLOSURE: proof retains an unresolved dependency")
        let checked ← psElabResolvedTerm (psElabContextEmpty state.environment levels)
          closed.value (some closed.type)
        let (name, nextIndex) ← psElabExposedProofFresh 4096 state.environment owner state.nextIndex
        let declaration := PsDeclaration.theoremDecl name levels closed.type checked.term
        let environment ← psAddDeclarationList state.environment [declaration]
        let replacement := psExprApplyMany (.constE name (levels.map PsLevel.param)) closed.arguments
        let checked ← psElabResolvedTerm
          (psElabContextWithLocal (psElabContextEmpty environment levels) locals)
          replacement (some type)
        return (checked.term, {
          state with environment, nextIndex
          auxiliaries := state.auxiliaries ++ [declaration]
          owners := state.owners ++ [(name, owner)] })
      else
        let (type, state) ← psElabExposedProofVisit fuel enabled owner levels locals state type
        let (value, state) ← psElabExposedProofVisit fuel enabled owner levels locals state value
        let pushed := psLocalPushLet locals name type value
        let (body, state) ← psElabExposedProofVisit fuel enabled owner levels pushed.context state
          (psExprInstantiate1 body (.fvar pushed.id))
        return (.letE name type value (psExprAbstractFVar pushed.id body), state)
    | .proj typeName index value =>
      let (value, state) ← psElabExposedProofVisit fuel enabled owner levels locals state value
      return (.proj typeName index value, state)
    | _ => return (expression, state)

def psElabExposedProofDeclaration (hidden exposed : List PsName)
    (state : PsElabExposedProofState) (declaration : PsDeclaration) :
    Except PsElabError (PsDeclaration × PsElabExposedProofState) := do
  if !psElabExposedProofDeclarationHasBoundary declaration then return (declaration, state)
  let name := psDeclarationName declaration
  let levels := psDeclarationLevelParams declaration
  let publicSignature := !hidden.any (psNameEq name)
  let (type, state) ← psElabExposedProofVisit 4096 publicSignature name levels psLocalEmpty state
    (psDeclarationType declaration)
  match declaration with
  | .definitionDecl _ _ _ value =>
    let exposedValue := publicSignature && exposed.any (psNameEq name)
    let (value, state) ← psElabExposedProofVisit 4096 exposedValue name levels psLocalEmpty state value
    return (.definitionDecl name levels type value, state)
  | .theoremDecl _ _ _ value =>
    let (value, state) ← psElabExposedProofVisit 4096 false name levels psLocalEmpty state value
    return (.theoremDecl name levels type value, state)
  | .opaqueDecl _ _ _ value =>
    let (value, state) ← psElabExposedProofVisit 4096 false name levels psLocalEmpty state value
    return (.opaqueDecl name levels type value, state)
  | .partialDecl _ _ _ value =>
    let (value, state) ← psElabExposedProofVisit 4096 false name levels psLocalEmpty state value
    return (.partialDecl name levels type value, state)
  | .axiomDecl .. => return (.axiomDecl name levels type, state)
  | .quotientDecl _ _ _ kind => return (.quotientDecl name levels type kind, state)
  | .inductiveDecl info => return (.inductiveDecl { info with type }, state)
  | .constructorDecl info => return (.constructorDecl { info with type }, state)
  | .recursorDecl info => return (.recursorDecl { info with type }, state)

-- Every new declaration belongs to the original declaration's source batch.
-- Generated proof names have no source alias and are not reducible definitions.
def psElabExposedProofOrigins (owners : List (PsName × PsName))
    (origins : List PsElabBatchOrigin) : List PsElabBatchOrigin :=
  origins.map fun origin =>
    let members := origin.members.flatMap fun member =>
      let proofs := owners.filterMap fun (name, owner) =>
        if psNameEq owner member.name then
          some (PsElabMemberOrigin.mk 0 name .sourceDeclaration)
        else none
      proofs ++ [member]
    { origin with
      members := members.zipIdx.map fun (member, index) => { member with index }
      localDefinitions := origin.localDefinitions.map fun localDefinition =>
        { localDefinition with declarations := localDefinition.declarations.flatMap fun owner =>
            (owners.filterMap fun (name, parent) =>
              if psNameEq parent owner then some name else none) ++ [owner] } }

def psElabAbstractExposedProofs (imports : PsEnvironment)
    (elaborated : PsElabModuleWithOriginsResult) :
    Except PsElabError PsElabModuleWithOriginsResult := do
  if !elaborated.result.declarations.any psElabExposedProofDeclarationHasBoundary then
    return elaborated
  let hidden := elaborated.privateNames ++ elaborated.origins.flatMap (fun origin =>
    origin.members.filterMap fun member =>
      match member.role with | .normalizedWorker => some member.name | _ => none)
  let (declarations, state) ← elaborated.result.declarations.foldlM
    (fun (acc : List PsDeclaration × PsElabExposedProofState) declaration => do
      let boundaries := elaborated.origins.flatMap fun origin =>
        if origin.members.any (fun member => psNameEq member.name (psDeclarationName declaration)) then
          origin.sourceInfo.flatMap (·.proofBoundaries)
        else []
      let state := { acc.snd with auxiliaries := [], boundaries }
      let (declaration, state) ← (psElabExposedProofDeclaration hidden elaborated.exposedNames
        state declaration).mapError (.atDeclaration (psDeclarationName declaration))
      return (acc.fst ++ state.auxiliaries ++ [declaration], state))
    ([], { environment := elaborated.result.environment })
  -- Rebuild the real declaration index in its final admission order. Missing
  -- dependencies and invalid proofs still fail this check and kernel admission.
  -- The unchanged module owner separately checks public type/body availability.
  let checked ← psAddDeclarationList imports declarations
  let environment := { elaborated.result.environment with
    declarations := checked.declarations, index := checked.index }
  return { elaborated with
    result := { elaborated.result with environment, declarations }
    origins := psElabExposedProofOrigins state.owners elaborated.origins }
