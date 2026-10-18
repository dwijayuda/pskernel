/-
Selected algorithms adapted from Lean 4.35.0 (eb6cafb7290e8bd5f2937522d8d804f58f02bafc).
Copyright (c) 2024 Lean FRO, LLC. All rights reserved.
Released under Apache 2.0; see THIRD_PARTY_NOTICES.md.
Upstream author: Joachim Breitner.
-/
import Ps.Elab.Mutual
import Ps.Elab.Monotonicity
import Ps.Elab.RecursorEquation

-- Selected fixedpoint construction uses only checked portable declarations.
-- Source peer identities are replaced inside their retained Core bodies;
-- neither an equation axiom nor a provisional public declaration is used.
def psElabFixedpointError (rule message : String) : PsElabError :=
  .data ("PSCV0-FIXPOINT-" ++ rule ++ ": " ++ message)

def psElabFixedpointGlobal (context : PsElabContext) (name : PsName)
    (arguments : List PsExpr) : Except PsElabError PsElabTermResult := do
  let (context, head) ← psElabResolvedReference context (.global name)
  (psElabApplyCore context head arguments).mapError
    (.atContext ("partial_fixpoint application " ++ psNameToString name))

def psElabFixedpointOrder (context : PsElabContext) (suffix : String)
    (arguments : List PsExpr) : Except PsElabError PsElabTermResult :=
  psElabFixedpointGlobal context (psElabMonotonicityName suffix) arguments

-- Pinned instCCPOPi lifts a real result order through the complete function
-- telescope. Only an ordinary no-instance result permits the flat fallback.
-- The independent inhabitant is requested lazily: an existing CCPO does not
-- require an extra Inhabited dictionary.
def psElabFixedpointCCPO (fuel : Nat) (context : PsElabContext)
    (rootType type : PsExpr) (arguments : List PsExpr) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match psWhnf context.environment context.metaContext context.localContext type with
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding context.localContext name domain binder
      let opened := psElabContextWithLocal context pushed.context
      let resultType := psExprInstantiate1 body (.fvar pushed.id)
      let result ← psElabFixedpointCCPO fuel opened rootType resultType
        (arguments ++ [.fvar pushed.id])
      let parameter : PsElabTypedBinder := { id := pushed.id, name, type := domain, binder }
      let family := psCloseElabLambdaBinders result.context.metaContext [parameter] resultType
      let instances := psCloseElabLambdaBinders result.context.metaContext [parameter] result.term
      psElabFixedpointOrder (psElabLeaveScope context result.context) "instCCPOPi"
        [domain, family, instances]
    | _ =>
      let target ← psElabFixedpointOrder context "CCPO" [type]
      match psElabSynthesizeInstance target.context target.term with
      | .ok dictionary => pure dictionary
      | .error .implicitApplicationUnsupported => do
        let witness ← psElabPartialInhabitant context.environment context.levelNames rootType
        let value ← psElabApplyCore target.context witness arguments
        let evidence ← psElabFixedpointGlobal value.context
          (psNameAppendStr (psRootName "Nonempty") "intro") [type, value.term]
        let chosen ← psElabFixedpointGlobal evidence.context
          (psNameAppendStr (psRootName "Classical") "ofNonempty") [type, evidence.term]
        psElabFixedpointOrder chosen.context "FlatOrder.instCCPO" [type, chosen.term]
      | .error error => throw error

structure PsElabFixedpointCarrier where
  type : PsExpr
  instanceValue : PsExpr

structure PsElabFixedpointPackedCarrier where
  context : PsElabContext
  carrier : PsElabFixedpointCarrier

def psElabFixedpointPackCarrier (context : PsElabContext)
    (carriers : List PsElabFixedpointCarrier) :
    Except PsElabError PsElabFixedpointPackedCarrier := do
  match carriers with
  | [] => throw (psElabFixedpointError "EMPTY" "fixedpoint component has no carrier")
  | [carrier] => return { context, carrier }
  | first :: rest =>
    let tail ← psElabFixedpointPackCarrier context rest
    let type ← psElabFixedpointGlobal tail.context (psRootName "PProd")
      [first.type, tail.carrier.type]
    let packedOrder ← psElabFixedpointOrder type.context "instCCPOPProd"
      [first.type, tail.carrier.type, first.instanceValue, tail.carrier.instanceValue]
    return {
      context := packedOrder.context
      carrier := { type := type.term, instanceValue := packedOrder.term } }

-- Right-associated products have one unambiguous source-member order. A
-- singleton is represented by its own carrier, with an identity projection.
def psElabFixedpointProjection (count index : Nat) (value : PsExpr) : PsExpr :=
  match count with
  | 0 | 1 => value
  | count + 2 =>
    match index with
    | 0 => .proj (psRootName "PProd") 0 value
    | index + 1 =>
      psElabFixedpointProjection (count + 1) index
        (.proj (psRootName "PProd") 1 value)

def psElabFixedpointPackValues (context : PsElabContext)
    (values : List PsExpr) : Except PsElabError PsElabTermResult := do
  match values with
  | [] => throw (psElabFixedpointError "EMPTY" "fixedpoint component has no body")
  | [value] => psElabResolvedTerm context value none
  | first :: rest =>
    let head ← psElabResolvedTerm context first none
    let tail ← psElabFixedpointPackValues head.context rest
    psElabFixedpointGlobal tail.context
      (psNameAppendStr (psRootName "PProd") "mk")
      [head.type, tail.type, head.term, tail.term]

def psElabFixedpointSourceValue (value : PsExpr) (arguments : List PsExpr) :
    Except PsElabError PsExpr :=
  arguments.foldlM (fun value argument =>
    match value with
    | .lam _ _ body _ => pure (psExprInstantiate1 body argument)
    | _ => throw (psElabFixedpointError "HEADER"
        "retained source value lost an actual capture or source-header lambda")) value

-- Specialize an already checked equality through each genuine argument.
-- congFun handles dependent codomains; source binder names are retained by
-- the final closure, including implicit types and instance dictionaries.
def psElabFixedpointCongrArguments (context : PsElabContext)
    (proof : PsExpr) (arguments : List PsExpr) :
    Except PsElabError PsElabTermResult := do
  let initial ← psElabResolvedTerm context proof none
  arguments.foldlM (fun current argument => do
    let equation ← psElabRecursorEquationView current.context current.type
    let pi ← (psInferEnsureForall current.context.environment current.context.metaContext
      current.context.localContext equation.type).mapError PsElabError.infer
    let family := PsExpr.lam pi.name pi.domain pi.body pi.binder
    psElabFixedpointGlobal current.context (psRootName "congrFun")
      [pi.domain, family, equation.left, equation.right, current.term, argument]) initial

def psElabFixedpointSourceEquation (environment : PsEnvironment)
    (levels : List PsName) (member : PsElabPreDefinition) (sourceValue : PsExpr) :
    Except PsElabError PsDeclaration := do
  let context := psElabContextEmpty environment levels
  let opened ← psElabOpenCoreTelescope 4096 context member.type
    (some (psElabPreDefinitionHeaderCount member))
  let arguments := psElabBinderArguments opened.bindersRev
  let left ← psElabApplyCore opened.context (.constE member.name (levels.map PsLevel.param))
    arguments
  let right ← psElabFixedpointSourceValue sourceValue arguments
  let level ← psElabExpressionSort left.context opened.body
  let expected := psLogicEq level opened.body left.term right
  let applied ← psElabFixedpointCongrArguments left.context
    (.constE (PsName.num member.name 2) (levels.map PsLevel.param)) arguments
  let proof ← psElabResolvedTerm applied.context applied.term (some expected)
  let closed := psCloseElabTypedBinders proof.context.metaContext opened.bindersRev
    proof.term expected
  if psExprHasUnresolvedMeta closed.fst || psExprHasUnresolvedMeta closed.snd ||
      !psExprFVarsInContext psLocalEmpty closed.fst ||
      !psExprFVarsInContext psLocalEmpty closed.snd then
    throw (psElabFixedpointError "EQUATION" "source equation did not close over its exact header")
  let checked ← psElabResolvedTerm context closed.fst (some closed.snd)
  return .theoremDecl (psNameAppendStr member.name "eq_def") levels closed.snd checked.term

def psElabFixedpointFromChecked (environment : PsEnvironment) (levels : List PsName)
    (nextId : Nat) (members : List PsElabPreDefinition) :
    Except PsElabError PsElabMutualBatchResult := do
  let first :: _ := members
    | throw (psElabFixedpointError "EMPTY" "fixedpoint component has no members")
  for member in members do
    match member.strategy with
    | .fixedpoint => pure ()
    | _ => throw (psElabFixedpointError "STRATEGY"
        "every member of a recursive fixedpoint component must have the selected fixedpoint strategy")
  let auxiliaryName := PsName.num first.name 1
  let allNames := auxiliaryName :: members.flatMap fun member =>
    [member.name, PsName.num member.name 0, PsName.num member.name 2,
      psNameAppendStr member.name "eq_def"]
  for name in allNames do
    if (psEnvironmentFind environment name).isSome then
      throw (.duplicateDeclaration name)
  let initial := { psElabContextEmpty environment levels with
    localContext := { psLocalEmpty with nextId } }
  let (context, carriers) ← members.foldlM
    (fun (state : PsElabContext × List PsElabFixedpointCarrier) member => do
      let order ← psElabFixedpointCCPO 4096 state.fst member.type member.type []
      let value := psMetaInstantiate order.context.metaContext order.term
      if psExprHasUnresolvedMeta value || !psExprFVarsInContext psLocalEmpty value then
        throw (psElabFixedpointError "ORDER" "result order retains a metavariable or local")
      return (order.context, state.snd ++ [{ type := member.type, instanceValue := value }]))
    (initial, [])
  let packed ← psElabFixedpointPackCarrier context carriers
  let packedType := packed.carrier.type
  let packedInstance := packed.carrier.instanceValue
  let pushed := psLocalPushBinding packed.context.localContext (psRootName "$psc0Fix")
    packedType .explicit
  let functionalContext := psElabContextWithLocal packed.context pushed.context
  let replacements := members.zipIdx.map fun (member, index) =>
    (member.peerId, psElabFixedpointProjection members.length index (.fvar pushed.id))
  let bodies := members.map fun member => psElabSubstituteLocals replacements member.value
  let body ← psElabFixedpointPackValues functionalContext bodies
  let checkedBody ← psElabResolvedTerm body.context body.term (some packedType)
  let binder : PsElabTypedBinder := {
    id := pushed.id, name := psRootName "$psc0Fix", type := packedType, binder := .explicit }
  let functional := psCloseElabLambdaBinders checkedBody.context.metaContext [binder] checkedBody.term
  let context := psElabLeaveScope packed.context checkedBody.context
  let order ← psElabFixedpointOrder context "CCPO.toPartialOrder" [packedType, packedInstance]
  let monotone ← psElabFixedpointOrder order.context "monotone"
    [packedType, order.term, packedType, order.term, functional]
  let monotonicity ← (psElabMonotonicityProof monotone.context monotone.term).mapError
    (fun error => if psElabErrorIsResource error then error else
      psElabFixedpointError "MONOTONICITY" "the retained recursive functional has no selected checked monotonicity proof")
  let fixed ← psElabFixedpointOrder monotone.context "fix"
    [packedType, packedInstance, functional, monotonicity]
  let fixedValue := psMetaInstantiate fixed.context.metaContext fixed.term
  let _ ← psElabResolvedTerm initial fixedValue (some packedType)
  let auxiliary := PsDeclaration.definitionDecl auxiliaryName levels packedType fixedValue
  let withAuxiliary ← psAddDeclarationList environment [auxiliary]
  let auxiliaryValue := PsExpr.constE auxiliaryName (levels.map PsLevel.param)
  let publicDeclarations ← members.zipIdx.mapM fun (member, index) => do
    let value := psElabFixedpointProjection members.length index auxiliaryValue
    let checked ← psElabResolvedTerm (psElabContextEmpty withAuxiliary levels)
      value (some member.type)
    return PsDeclaration.definitionDecl member.name levels member.type checked.term
  let withPublic ← psAddDeclarationList withAuxiliary publicDeclarations
  let publicContext := psElabContextEmpty withPublic levels
  let equation ← psElabFixedpointOrder publicContext "fix_eq"
    [packedType, packedInstance, functional, monotonicity]
  let publicReplacements := members.map fun member =>
    (member.peerId, PsExpr.constE member.name (levels.map PsLevel.param))
  let sourceValues := members.map fun member => psElabSubstituteLocals publicReplacements member.value
  let wholeEquations ← (members.zip sourceValues).zipIdx.mapM fun ((member, sourceValue), index) => do
    let projection := PsExpr.lam (psRootName "$psc0Fix") packedType
      (psElabFixedpointProjection members.length index (.bvar 0)) .explicit
    let fixedApplication ← psElabApplyCore equation.context functional [fixedValue]
    let proof ← psElabFixedpointGlobal fixedApplication.context (psRootName "congrArg")
      [packedType, member.type, fixedValue, fixedApplication.term, projection, equation.term]
    let level ← psElabExpressionSort proof.context member.type
    let expected := psLogicEq level member.type
      (.constE member.name (levels.map PsLevel.param)) sourceValue
    let checked ← (psElabResolvedTerm proof.context proof.term (some expected)).mapError
      (.atContext ("partial_fixpoint equation " ++ psNameToString member.name))
    let value := psMetaInstantiate checked.context.metaContext checked.term
    if psExprHasUnresolvedMeta value || !psExprFVarsInContext psLocalEmpty value then
      throw (psElabFixedpointError "EQUATION" "whole-function unfolding proof is not closed")
    return PsDeclaration.theoremDecl (PsName.num member.name 2) levels expected value
  let withWholeEquations ← psAddDeclarationList withPublic wholeEquations
  let sourceEquations ← (members.zip sourceValues).mapM fun (member, sourceValue) =>
    psElabFixedpointSourceEquation withWholeEquations levels member sourceValue
  let withEquations ← psAddDeclarationList withWholeEquations sourceEquations
  let implementations ← (members.zip sourceValues).mapM fun (member, sourceValue) => do
    let checked ← psElabResolvedTerm (psElabContextEmpty withEquations levels)
      sourceValue (some member.type)
    if psExprHasUnresolvedMeta checked.term || !psExprFVarsInContext psLocalEmpty checked.term then
      throw (psElabFixedpointError "BODY" "retained executable body contains an unowned peer")
    return PsDeclaration.partialDecl (PsName.num member.name 0) levels member.type checked.term
  let _ ← psAddDeclarationList withEquations implementations
  let results := (((members.zip publicDeclarations).zip wholeEquations).zip
    (sourceEquations.zip implementations)).zipIdx.map
      fun ((((member, publicDeclaration), wholeEquation), (sourceEquation, implementation)), index) =>
        ({
          declarations := (if index == 0 then [auxiliary] else []) ++
            [publicDeclaration, wholeEquation, sourceEquation, implementation]
          sourceInfo := [{ member.sourceInfo with owner := PsName.num member.name 0 }]
        } : PsElabDeclarationBatchResult)
  return {
    batch := {
      declarations := [auxiliary] ++ publicDeclarations ++ wholeEquations ++
        sourceEquations ++ implementations
      sourceInfo := results.flatMap (·.sourceInfo) }
    members := results }
