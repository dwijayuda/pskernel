import Ps.Elab.InspectionReduce

/-!
Actual stored declaration closure, following Lean 4.35.0 Util/CollectAxioms.lean
(Apache-2.0, Microsoft Corporation). The result is diagnostic data; it does not
replace release auditing or supply new proof authority.
-/

def psInspectionConstants (fuel : Nat) (expression : PsExpr) :
    Except PsElabError (List PsName) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let visit := psInspectionConstants fuel
    match expression with
    | .constE name _ => return [name]
    | .app fn arg => return (← visit fn) ++ (← visit arg)
    | .lam _ type body _ | .forallE _ type body _ => return (← visit type) ++ (← visit body)
    | .letE _ type value body => return (← visit type) ++ (← visit value) ++ (← visit body)
    | .proj owner _ major => return owner :: (← visit major)
    | _ => return []

def psInspectionAxioms (fuel : Nat) (environment : PsEnvironment)
    (pending visited axioms : List PsName) : Except PsElabError (List PsName) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pending with
    | [] => return axioms
    | name :: rest =>
      if visited.any (psNameEq name) then
        return ← psInspectionAxioms fuel environment rest visited axioms
      let some declaration := psEnvironmentFind environment name
        | throw (psInspectionError ("missing actual axiom dependency " ++ psNameToString name))
      let (dependencies, axioms) ← do
        match declaration with
        | .quotientDecl .. => pure ([], axioms)
        | .axiomDecl _ _ type => return ((← psInspectionConstants 4096 type), name :: axioms)
        | .definitionDecl _ _ type body | .theoremDecl _ _ type body
        | .opaqueDecl _ _ type body | .partialDecl _ _ type body =>
          return ((← psInspectionConstants 4096 type) ++ (← psInspectionConstants 4096 body), axioms)
        | .inductiveDecl info =>
          return ((← psInspectionConstants 4096 info.type) ++ info.constructors, axioms)
        | _ => return ((← psInspectionConstants 4096 (psDeclarationType declaration)), axioms)
      psInspectionAxioms fuel environment (dependencies ++ rest) (name :: visited) axioms

def psInspectionRuntimeErased (context : PsElabContext) (expression : PsExpr) :
    Except PsElabError Bool := do
  let type ← (psInferType context.environment context.metaContext
    context.localContext expression).mapError PsElabError.infer
  (psTypeViewIsErased context.environment context.localContext
    (psMetaInstantiate context.metaContext type)).mapError PsElabError.infer

-- Constructor parameters and recursor parameters, motives and indices have
-- registered erasure ownership even when a parameter has type Nat.
def psInspectionErasedArgument (environment : PsEnvironment)
    (head : PsExpr) (position : Nat) : Bool :=
  match head with
  | .constE name _ =>
    match psEnvironmentFind environment name with
    | some (.constructorDecl info) => position < info.numParams
    | some (.recursorDecl info) =>
      position < info.numParams + info.numMotives ||
        (info.numParams + info.numMotives + info.numMinors ≤ position &&
          position < info.numParams + info.numMotives + info.numMinors + info.numIndices)
    | _ => false
  | _ => false

-- Inspect before beta/let reduction: a discarded executable argument still
-- belongs to the requested computation. Proofs and type families use the
-- checked erasure classification already used by runtime preparation.
def psInspectionExecutable (fuel : Nat) (context : PsElabContext)
    (visited : List PsName) (expression : PsExpr) :
    Except PsElabError (List PsName) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let expression := psMetaInstantiate context.metaContext expression
    if ← psInspectionRuntimeErased context expression then return visited
    let visit := psInspectionExecutable fuel context
    match expression with
    | .constE name levels =>
      if psEnvironmentIsNoncomputable context.environment name then
        throw (psInspectionError ("#eval depends computationally on noncomputable " ++ psNameToString name))
      let some declaration := psEnvironmentFind context.environment name
        | throw (psInspectionError ("#eval missing actual implementation " ++ psNameToString name))
      match declaration with
      | .partialDecl .. =>
        throw (psInspectionError ("#eval depends computationally on partial " ++ psNameToString name))
      | .axiomDecl .. =>
        if (psInspectionScalarArity name).isSome || (psReduceNatBinary name).isSome ||
            psNameEq name psNatZeroName || psNameEq name psNatSuccName then return visited
        throw (psInspectionError ("#eval depends computationally on axiom " ++ psNameToString name))
      | _ => pure ()
      if visited.any (psNameEq name) then return visited
      let visited := name :: visited
      if (psInspectionScalarArity name).isSome then return visited
      match psInspectionBody true declaration with
      | none => return visited
      | some body =>
        let parameters := psDeclarationLevelParams declaration
        if parameters.length != levels.length then throw .typeMismatch
        visit visited (psExprInstantiateLevelParams parameters levels body)
    | .app .. =>
      let view := psReduceAppView expression
      let visited ← visit visited view.head
      view.args.zipIdx.foldlM (fun seen (argument, position) => do
        if psInspectionErasedArgument context.environment view.head position then return seen
        visit seen argument) visited
    | .fvar id =>
      match psLocalFindById context.localContext id with
      | some (.letDecl _ _ _ value) => visit visited value
      | some _ => return visited
      | none => throw (psInspectionError "#eval has an unbound local")
    | .mvar _ => throw .unresolvedMetavariable
    | .bvar _ => throw (psInspectionError "#eval has a loose bound variable")
    | .lam name type body binder =>
      let pushed := psLocalPushBinding context.localContext name type binder
      psInspectionExecutable fuel (psElabContextWithLocal context pushed.context)
        visited (psExprInstantiate1 body (.fvar pushed.id))
    | .letE name type value body =>
      let visited ← visit visited value
      let pushed := psLocalPushLet context.localContext name type value
      psInspectionExecutable fuel (psElabContextWithLocal context pushed.context)
        visited (psExprInstantiate1 body (.fvar pushed.id))
    | .proj _ _ major => visit visited major
    | .lit _ => return visited
    | .sortE _ | .forallE .. => return visited
