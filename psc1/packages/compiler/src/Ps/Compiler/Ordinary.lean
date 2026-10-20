import Ps.Compiler.Api

/-- An ordinary runtime view retains the original immutable declaration graph and
its exact independently checkable logical expansion. No behavioral certificate is
represented by this record. The host recomputes it from captured source. -/
structure PsCompilerOrdinaryModule where
  source : PsCompilerAdmissionReadyModule
  logical : PsCompilerAdmissionReadyModule
  runtimeEnvironment : PsEnvironment
  partialNames : List PsName

def psOrdinaryHasType
    (environment : PsEnvironment) (locals : PsLocalContext)
    (value type : PsExpr) : Bool :=
  match psInferType environment psMetaEmpty locals value with
  | .error _ => false
  | .ok actual =>
      let result := psUnify environment locals psMetaEmpty actual type
      result.success && !psExprHasUnresolvedMeta value && !psExprHasUnresolvedMeta type

def psOrdinaryLocalWitness
    (environment : PsEnvironment) (locals : PsLocalContext) (type : PsExpr) :
    List PsLocalDecl -> Option PsExpr
  | [] => none
  | declaration :: rest =>
      let value := PsExpr.fvar (psLocalDeclId declaration)
      if psOrdinaryHasType environment locals value type then some value
      else psOrdinaryLocalWitness environment locals type rest

/-- Bounded constructive inhabitant selection for the admitted core. Failure
means no inhabitant was found by this subset, not a proof of uninhabitedness.
The executable recursive body is never consulted, unfolded or run here. -/
-- The structural fuel bounds recursion depth; budget counts every attempted
-- witness expansion and is shared by siblings and failed alternatives.
def psOrdinaryWitnessBudgetWithFuel
    (fuel : Nat) (environment : PsEnvironment) (locals : PsLocalContext)
    (type : PsExpr) (budget : Nat) : Prod (Option PsExpr) Nat :=
  match fuel with
  | 0 => (none, budget)
  | remaining + 1 =>
      match budget with
      | 0 => (none, 0)
      | available + 1 =>
          let reduced := psWhnf environment psMetaEmpty locals type
          let candidate : Prod (Option PsExpr) Nat :=
            match psOrdinaryLocalWitness environment locals type locals.declarations with
            | some value => (some value, available)
            | none =>
              match reduced with
              | .forallE name domain body binder =>
                  let pushed := psLocalPushBinding locals name domain binder
                  let child := psOrdinaryWitnessBudgetWithFuel remaining environment
                    pushed.context (psExprInstantiate1 body (.fvar pushed.id)) available
                  match child.fst with
                  | none => (none, child.snd)
                  | some value =>
                      (some (.lam name domain (psExprAbstractFVar pushed.id value) binder),
                        child.snd)
              | .sortE .zero =>
                  (some (psExprApplyMany
                    (.constE psEqName [PsLevel.succ PsLevel.zero])
                    [.constE psNatName [], .lit (.natural 0), .lit (.natural 0)]), available)
              | .sortE (.succ .zero) => (some (.constE psNatName []), available)
              | .constE name _ =>
                  let value : Option PsExpr :=
                    if psNameEq name psNatName then some (.lit (.natural 0))
                    else if psNameEq name psIntName then
                      some (.app (.constE psIntOfNatName []) (.lit (.natural 0)))
                    else if psNameEq name psBoolName then some (.constE psBoolFalseName [])
                    else if psNameEq name psStringName then some (.lit (.string ""))
                    else if psNameEq name psCharName then
                      some (.app (.constE psCharOfNatName []) (.lit (.natural 0)))
                    else if psNameEq name psUnitName then some (.constE psUnitUnitName [])
                    else none
                  (value, available)
              | _ =>
                  let view := psExprAppView reduced
                  match view.head, view.args with
                  | .constE name _, [element] =>
                      let value : Option PsExpr :=
                        if psNameEq name psListName then
                          some (.app (.constE psSelfHostListNilName []) element)
                        else if psNameEq name psOptionName then
                          some (.app (.constE psSelfHostOptionNoneName []) element)
                        else if psNameEq name psArrayName then
                          some (psExprApplyMany (.constE psArrayEmptyWithCapacityName [])
                            [element, .lit (.natural 0)])
                        else none
                      (value, available)
                  | .constE name _, [first, second] =>
                      if psNameEq name psProdName then
                        let left := psOrdinaryWitnessBudgetWithFuel remaining
                          environment locals first available
                        match left.fst with
                        | none => (none, left.snd)
                        | some leftValue =>
                            let right := psOrdinaryWitnessBudgetWithFuel remaining
                              environment locals second left.snd
                            match right.fst with
                            | none => (none, right.snd)
                            | some rightValue =>
                                (some (psExprApplyMany (.constE psProdMkName [])
                                  [first, second, leftValue, rightValue]), right.snd)
                      else if psNameEq name psSelfHostExceptName then
                        let success := psOrdinaryWitnessBudgetWithFuel remaining
                          environment locals second available
                        match success.fst with
                        | some value =>
                            (some (psSelfHostExceptOkOf first second value), success.snd)
                        | none =>
                            let failure := psOrdinaryWitnessBudgetWithFuel remaining
                              environment locals first success.snd
                            match failure.fst with
                            | some error =>
                                (some (psSelfHostExceptErrorOf first second error), failure.snd)
                            | none => (none, failure.snd)
                      else (none, available)
                  | _, _ => (none, available)
          match candidate.fst with
          | none => candidate
          | some value =>
              if psOrdinaryHasType environment locals value type then candidate
              else (none, candidate.snd)

def psOrdinaryWitnessWithFuel
    (fuel : Nat) (environment : PsEnvironment) (locals : PsLocalContext)
    (type : PsExpr) : Option PsExpr :=
  (psOrdinaryWitnessBudgetWithFuel fuel environment locals type fuel).fst

def psOrdinaryBodyName (owner : PsName) : PsName :=
  -- Numeric name components cannot be authored by the source name parser.
  PsName.num (PsName.str owner "_psc1PartialBody") 0

def psOrdinaryAdd
    (environment : PsEnvironment) (declaration : PsDeclaration) :
    Except String PsEnvironment :=
  match psEnvironmentAdd environment declaration with
  | none => .error ("PSC1_ORDINARY_DUPLICATE: " ++ psNameToString (psDeclarationName declaration))
  | some result => .ok result

def psOrdinaryExpand
    (declarations : List PsDeclaration) (environment : PsEnvironment) :
    Except String (List PsDeclaration × List PsName) := do
  match declarations with
  | [] => return ([], [])
  | declaration :: rest =>
      match declaration with
      | .axiomDecl _ _ _ =>
          throw "PSC1_SOURCE_AXIOM_FORBIDDEN"
      | .opaqueDecl _ _ _ _ =>
          throw "PSC1_SOURCE_OPAQUE_NOT_SELECTED"
      | .partialDecl name levels type body =>
          match psWhnf environment psMetaEmpty psLocalEmpty type with
          | .forallE _ _ _ _ => pure ()
          | _ => throw ("PSC1_PARTIAL_EXPECTED_FUNCTION: " ++ psNameToString name)
          let some witness := psOrdinaryWitnessWithFuel 128 environment psLocalEmpty type
            | throw ("PSC1_PARTIAL_NO_CHECKED_INHABITANT: " ++ psNameToString name)
          let logical := PsDeclaration.opaqueDecl name levels type witness
          let withLogical ← psOrdinaryAdd environment logical
          let implementation := PsDeclaration.definitionDecl
            (psOrdinaryBodyName name) levels type body
          -- The body refers to the public opaque function, never to a temporary
          -- source axiom. The independent provider checks this exact definition.
          let withBody ← psOrdinaryAdd withLogical implementation
          let (tail, partials) ← psOrdinaryExpand rest withBody
          return (logical :: implementation :: tail, name :: partials)
      | _ =>
          let next ← psOrdinaryAdd environment declaration
          let (tail, partials) ← psOrdinaryExpand rest next
          return (declaration :: tail, partials)

def psCompilerPrepareOrdinary
    (elaborated : PsElabModuleResult) : Except String PsCompilerOrdinaryModule := do
  let (logical, partials) ←
    psOrdinaryExpand elaborated.declarations psSelfHostProdPreludeEnvironment
  -- Encoding checks every expression for forbidden free/unresolved variables.
  match psEncodeCheckedAdmissionsCanonical logical with
  | .error _ => throw "PSC1_ORDINARY_LOGICAL_ENCODING_FAILED"
  | .ok _ => pure ()
  let runtimeEnvironment ← match psAddDeclarationList
      psSelfHostProdPreludeEnvironment elaborated.declarations with
    | .error _ => throw "PSC1_ORDINARY_RUNTIME_CLOSURE_FAILED"
    | .ok value => pure value
  return {
    source := { declarations := elaborated.declarations }
    logical := { declarations := logical }
    runtimeEnvironment := runtimeEnvironment
    partialNames := partials
  }

/-- The compiler API has no authority to claim the host performed admission.
It only computes a typed runtime candidate from its exact source graph. -/
def psCompilerOrdinaryIr
    (prepared : PsCompilerOrdinaryModule) : Except String PsVerifiedIrModule := do
  -- Recompute the graph rather than trusting supplied pairing metadata.
  let repeated ← psCompilerPrepareOrdinary
    { environment := prepared.runtimeEnvironment
      declarations := prepared.source.declarations }
  let originalEncoded ← match psCompilerAdmissionsFromPrepared prepared.logical with
    | .error _ => throw "PSC1_ORDINARY_LOGICAL_INTEGRITY_FAILED"
    | .ok value => pure value
  let repeatedEncoded ← match psCompilerAdmissionsFromPrepared repeated.logical with
    | .error _ => throw "PSC1_ORDINARY_LOGICAL_INTEGRITY_FAILED"
    | .ok value => pure value
  if originalEncoded != repeatedEncoded then
    throw "PSC1_ORDINARY_BODY_BINDING_MISMATCH"
  match psEraseCoreModuleWithRuntimePrelude repeated.runtimeEnvironment
      psSelfHostRuntimePreludeDeclarationsWithProd repeated.source.declarations with
  | .error _ => throw "PSC1_ORDINARY_ERASURE_FAILED"
  | .ok ir => return ir
