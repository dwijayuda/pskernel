import Ps.Elab.WhereMutualWellFounded
import Ps.Host.NativeV7
import Ps.Environment.StandardPSumData
import Ps.Meta.MutualPacking
import Ps.Meta.MutualWellFounded
import PsKernelLean.Admission
import Ps.Elab.FixedParameters
import Lean.Elab.PreDefinition.FixedParams

-- Native dependent/heterogeneous oracle for the same three owned slots.
namespace M3MutualPackingOracle
def first (n : Nat) : Fin (n + 1) := ⟨n, Nat.lt_succ_self n⟩
def second (b : Bool) : Bool := b
def third (s : PSum Nat Bool) : PSum Nat Bool := s
def packed (x : PSum Nat (PSum Bool (PSum Nat Bool))) :
    (match x with
      | .inl n => Fin (n + 1)
      | .inr (.inl _) => Bool
      | .inr (.inr _) => PSum Nat Bool) :=
  match x with
  | .inl n => first n
  | .inr (.inl b) => second b
  | .inr (.inr s) => third s
example (n : Nat) : packed (.inl n) = first n := rfl
example (b : Bool) : packed (.inr (.inl b)) = second b := rfl
example (s : PSum Nat Bool) : packed (.inr (.inr s)) = third s := rfl

-- Same original three-slot headers, reordered fixed type/value parameters,
-- local let aliases, and an overapplication belonging to a returned function.
mutual
def callFirst {A : Type} (a : A) (n : Nat) : Nat → A :=
  fun k => match n with
    | 0 => a
    | m + 1 => let kept := a; callSecond m A kept k
termination_by n
def callSecond (n : Nat) (B : Type) (b : B) : Nat → B :=
  fun k => match n with
    | 0 => b
    | m + 1 => callThird m b k
termination_by n
def callThird {C : Type} (n : Nat) (c : C) : Nat → C :=
  fun k => match n with
    | 0 => c
    | m + 1 => callFirst c m k
termination_by n
end
-- Native well-founded equations are propositional; decide cannot unfold
-- the opaque mutual fixedpoint. Use its checked generated equations.
example : callFirst 7 6 2 = 7 := by simp [callFirst, callSecond, callThird]

end M3MutualPackingOracle

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def checkFixedParameters : IO Unit := do
  let dependencies : List (List (List Nat)) :=
    [[[1], [], []], [[], [2], []], [[], [], [0]]]
  let calls : List PsFixedParameterCall := [
    { caller := 0, callee := 1, arguments := [none, some 0, some 1] },
    { caller := 1, callee := 2, arguments := [some 2, none, some 1] },
    { caller := 2, callee := 0, arguments := [some 2, some 0, none] }]
  let graph ← fromExcept (psFixedParameterAnalyze dependencies calls)
  let plan ← fromExcept (psFixedParameterPermutation graph)
  ensure (plan == { count := 2, permutations :=
      [[some 0, some 1, none], [none, some 0, some 1], [some 1, none, some 0]] })
    "fixed parameter permutations lost typed dependency or reordered ownership"
  let changed : PsFixedParameterCall :=
    { caller := 2, callee := 0, arguments := [none, some 0, none] }
  for observations in [calls, calls ++ [changed]] do
    let portable ← fromExcept (psFixedParameterAnalyze dependencies observations)
    let mut native := (Lean.Elab.FixedParams.Info.init
      (dependencies.toArray.map fun slots => slots.toArray.map List.toArray)).addSelfCalls
    for call in observations do
      for (argument, slot) in call.arguments.zipIdx do
        native := match argument with
          | none => native.setVarying call.callee slot
          | some parameter => native.setCallerParam call.callee slot call.caller parameter
    let expected := native.graph.toList.map fun slots =>
      slots.toList.map fun incoming => incoming.map Array.toList
    ensure (portable == expected)
      "fixed-parameter finite closure differs from pinned native correspondence"
  match psFixedParameterAnalyze dependencies
      [{ caller := 3, callee := 0, arguments := [none, none, none] }] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "fixed analysis accepted an unowned caller")
  IO.println "PSCV0_M3_FIXED_PARAMETERS: PASS pinned native graph differential, three reordered member headers, transitive variation and dependent-type propagation"

-- A source call uses the current lexical capture after refinement, and
-- records the actual callee. These are typed local probes, not permission
-- to admit a source mutual WF declaration or to adapt its runtime body.
private def checkCallbackScopes (environment : PsEnvironment) : Except String Unit := do
  let pos : PsSourcePos := { byteOffset := 0, line := 1, column := 1 }
  let span : PsSourceSpan := { start := pos, stop := pos }
  let sourceName := fun name => ({ segments := [name], span } : PsSyntaxName)
  let nat := PsExpr.constE psNatName []
  let unary := PsExpr.forallE (psRootName "n") nat nat .explicit
  let complete := PsExpr.forallE (psRootName "capture") nat unary .explicit
  let f := psLocalPushBinding psLocalEmpty (psRootName "_checkedF") complete .explicit
  let g := psLocalPushBinding f.context (psRootName "_checkedG") complete .explicit
  let hidden := psRootName "$psc0Capture"
  let original := psLocalPushLet g.context hidden nat (.lit (.natural 0))
  -- Match refinement shadows a lookup name with a fresh checked alias.
  let refined := psLocalPushLet original.context hidden nat (.lit (.natural 3))
  let context := { psElabContextEmpty environment [] with
    localContext := refined.context
    wellFoundedRecursions := [
      { functionName := psRootName "peerF", callbackName := psRootName "_checkedF"
        parameterIds := [100, 101], sourceType := some complete
        capturedNames := [hidden], collectCalls := true },
      { functionName := psRootName "peerG", callbackName := psRootName "_checkedG"
        parameterIds := [200, 201], sourceType := some complete
        capturedNames := [hidden], collectCalls := true }] }
  for (name, callback) in [("peerF", f.id), ("peerG", g.id)] do
    let source := PsSyntaxTerm.call (.reference (sourceName name))
      [(none, .natural "2" span)] span
    let checked ← (psElabTerm context source (some nat)).mapError psCompilerPscv0ElabError
    let expected := psExprApplyMany (.fvar callback)
      [.lit (.natural 3), .lit (.natural 2)]
    if !psDefEqReadOnlyWithEnv environment checked.context.metaContext
        checked.context.localContext checked.term expected then
      throw "callback selected a stale capture or another member"
    let [call] := checked.context.wellFoundedCallsRev
      | throw "callback observation lost its original call"
    if !psNameEq call.callee (psRootName name) || call.arguments.length != 2 then
      throw "callback observation changed callee or complete header"
  let identity := PsExpr.lam (psRootName "n") nat (.bvar 0) .explicit
  let shadow := psLocalPushLet context.localContext (psRootName "peerG") unary identity
  let shadowed := { context with localContext := shadow.context }
  let checked ← (psElabTerm shadowed
    (.call (.reference (sourceName "peerG")) [(none, .natural "2" span)] span)
    (some nat)).mapError psCompilerPscv0ElabError
  if !checked.context.wellFoundedCallsRev.isEmpty ||
      !psDefEqReadOnlyWithEnv environment checked.context.metaContext
        checked.context.localContext checked.term (.lit (.natural 2)) then
    throw "ordinary local shadow was misclassified as a recursive call"
  match psElabTerm context (.reference (sourceName "peerG")) none with
  | .error _ => pure ()
  | .ok _ => throw "proof-restricted member escaped as an ordinary value"
  let restored := psElabRestoreScope { context with wellFoundedRecursions := [] }
    (psElabSaveScope context)
  if restored.wellFoundedRecursions.length != 2 then
    throw "saved scope lost member callback authority"
  -- Equal numeric IDs in different owners remain unrelated. Only the actual
  -- cross-call arguments establish the reordered correspondence.
  let a := psLocalPushBinding psLocalEmpty (psRootName "a") nat .explicit
  let b := psLocalPushBinding a.context (psRootName "b") nat .explicit
  let first := { psElabContextEmpty environment [] with localContext := b.context }
  let b' := psLocalPushBinding psLocalEmpty (psRootName "b") nat .explicit
  let a' := psLocalPushBinding b'.context (psRootName "a") nat .explicit
  let second := { psElabContextEmpty environment [] with localContext := a'.context }
  let owners : List PsElabRecursionParameterOwner := [
    { name := psRootName "first", context := first, parameterIds := [a.id, b.id]
      calls := [{
        callee := psRootName "second"
        localContext := b.context
        arguments := [.fvar b.id, .fvar a.id]
        span := span }] },
    { name := psRootName "second", context := second, parameterIds := [b'.id, a'.id]
      calls := [{
        callee := psRootName "first"
        localContext := a'.context
        arguments := [.fvar a'.id, .fvar b'.id]
        span := span }] }]
  let plan ← (psElabRecursionComponentFixedParameterPlan owners).mapError psCompilerPscv0ElabError
  if plan != { count := 2, permutations := [[some 0, some 1], [some 1, some 0]] } then
    throw "typed member analysis confused cross-owner local identities"
  let some owner := owners.head? | throw "missing owned header"
  match psElabRecursionComponentFixedParameterPlan [owner] with
  | .error _ => pure ()
  | .ok _ => throw "typed member analysis accepted a callee outside the component"

-- Inspect source-owned Core before any recursive declaration is published.
-- Native controls above and the existing graph differential cover the same
-- parameter correspondence. This probe does not admit source mutual WF.
private def checkRetainedOwners (environment : PsEnvironment) : Except String Unit := do
  let source :=
    "mutual\n" ++
    "def callFirst {A : Type} (a : A, n : Nat) : Nat -> A := fun (k : Nat) => match n with { | 0 => a | m + 1 => let kept := a\ncallSecond(m, A, kept)(k) } termination_by n\n" ++
    "def callSecond (n : Nat, B : Type, b : B) : Nat -> B := fun (k : Nat) => match n with { | 0 => b | m + 1 => callThird(m, b)(k) } termination_by n\n" ++
    "def callThird {C : Type} (n : Nat, c : C) : Nat -> C := fun (k : Nat) => match n with { | 0 => c | m + 1 => callFirst(c, m)(k) } termination_by n\n" ++
    "end\n"
  let parsed ← psPscv0ParseProgram source
  let [.mutualDeclarations members span] := parsed.commands
    | throw "retained-call source lost its owned mutual block"
  let names := members.map fun member => (psElabOriginSource member.declaration).fst.segments
  let aliases := names.zipIdx.map fun (name, index) =>
    (name, ["$psc0Mutual", psNatToString index])
  let resolver : PsScopeResolver := {
    environment, scope := {}, mutualNames := names, mutualAliases := aliases }
  let scopedMembers ← (members.zip aliases).mapM fun (member, alias) =>
    (psScopePreDefinition resolver member
      (PsSyntaxName.mk alias.snd (psElabOriginSource member.declaration).snd)).mapError
        psCompilerPscv0ElabError
  let prepared ← (psElabPreparePreDefinitionsWithSource environment [] []
    scopedMembers span).mapError psCompilerPscv0ElabError
  let context ← (psElabPreDefinitionValidate environment prepared.block).mapError
    psCompilerPscv0ElabError
  let owners ← (psElabPreDefinitionParameterOwners environment prepared.block.levelNames
    context.localContext.nextId prepared.block.members).mapError psCompilerPscv0ElabError
  if owners.length != 3 || owners.any (fun owner =>
      owner.parameterIds.length != 3 || owner.calls.length != 1 ||
        owner.calls.any (fun call => call.arguments.length != 3)) then
    throw "retained-call analysis duplicated spines or consumed returned-function arguments"
  let plan ← (psElabRecursionComponentFixedParameterPlan owners).mapError psCompilerPscv0ElabError
  if plan != { count := 2, permutations :=
      [[some 0, some 1, none], [none, some 0, some 1], [some 0, none, some 1]] } then
    throw "retained source call analysis lost reordered dependent fixed parameters"
  let measured ← (psElabWherePrepareWellFoundedComponent prepared environment
    prepared.block.levelNames prepared.block.members).mapError psCompilerPscv0ElabError
  if measured.parameters != plan || measured.members.length != 3 ||
      measured.fixedBindersRev.length != 2 ||
      measured.members.any (fun member => member.varyingNames.length != 1 ||
        member.specialized.arguments.length != 3) then
    throw "source component measures changed fixed correspondence or original arity"
  for member in measured.members do
    let expected := PsExpr.lam (psRootName "n") (.constE psNatName []) (.bvar 0) .explicit
    if !psWellFoundedDefEq environment psMetaEmpty measured.context.localContext
        member.measure expected then
      throw "source component measure captured a returned function or another member header"
    let branch ← (psMutualWellFoundedBranchType environment psMetaEmpty
      measured.context.localContext measured.plan member.source.sourceIndex).mapError
        (fun _ => "source component lost its genuine dependent callback signature")
    let _ ← (psElabExpressionSort measured.context branch).mapError psCompilerPscv0ElabError
    pure ()
  -- Underapplication is conservative analysis, not permission to escape a
  -- proof-restricted callback. The omitted source slots must become varying.
  let some owner := owners.head? | throw "missing retained source owner"
  let some member := prepared.block.members.head? | throw "missing source member"
  let some typeId := owner.parameterIds.head? | throw "missing type parameter"
  let partialCall := PsExpr.app (.fvar member.peerId) (.fvar typeId)
  let _ ← (psElabResolvedTerm owner.context partialCall none).mapError psCompilerPscv0ElabError
  let calls ← (psElabRecursionCollectCalls 4096 owner.context
    [{ peerId := member.peerId, name := member.name, arity := 3 }] span partialCall).mapError
      psCompilerPscv0ElabError
  let partialPlan ← (psElabRecursionComponentFixedParameterPlan
    [{ owner with calls }]).mapError psCompilerPscv0ElabError
  if partialPlan != { count := 1, permutations := [[some 0, none, none]] } then
    throw "underapplication incorrectly treated missing arguments as fixed"
  let malformed := { member with value := .fvar context.localContext.nextId }
  match psElabPreDefinitionParameterOwners environment prepared.block.levelNames
      context.localContext.nextId [malformed] with
  | .error _ => pure ()
  | .ok _ => throw "retained-call analysis accepted an unowned Core value"

private def checkFixedScopes (environment : PsEnvironment) :
    Except String (List PsDeclaration) := do
  let u := psRootName "u"
  let nat := PsExpr.constE psNatName []
  let sort := PsExpr.sortE (.succ (.param u))
  let a := PsExpr.fvar 0
  let value := PsExpr.fvar 1
  let result := psLogicPi 3 "ignored" nat a
  let resultValue := psLogicLam 3 "ignored" nat value
  let firstType := psLogicPi 0 "A" sort
    (psLogicPi 1 "a" a (psLogicPi 2 "n" nat result)) .implicit
  let firstValue := psLogicLam 0 "A" sort
    (psLogicLam 1 "a" a (psLogicLam 2 "n" nat resultValue)) .implicit
  let secondType := psLogicPi 2 "n" nat
    (psLogicPi 0 "B" sort (psLogicPi 1 "b" a result) .implicit)
  let secondValue := psLogicLam 2 "n" nat
    (psLogicLam 0 "B" sort (psLogicLam 1 "b" a resultValue) .implicit)
  let thirdType := psLogicPi 0 "C" sort
    (psLogicPi 2 "n" nat (psLogicPi 1 "c" a result)) .implicit
  let thirdValue := psLogicLam 0 "C" sort
    (psLogicLam 2 "n" nat (psLogicLam 1 "c" a resultValue)) .implicit
  let entries : List (PsName × PsExpr × PsExpr × List (Option Nat)) := [
    (psRootName "packingFixedFirst", firstType, firstValue, [some 0, some 1, none]),
    (psRootName "packingFixedSecond", secondType, secondValue, [none, some 0, some 1]),
    (psRootName "packingFixedThird", thirdType, thirdValue, [some 0, none, some 1])]
  let declarations := entries.map fun (name, type, value, _) =>
    PsDeclaration.definitionDecl name [u] type value
  let environment ← (psAddDeclarationList environment declarations).mapError psCompilerPscv0ElabError
  let context := psElabContextEmpty environment [u]
  let fixed ← (psElabRecursionOpenFixedScope context firstType
    [some 0, some 1, none] 2).mapError psCompilerPscv0ElabError
  let fixedValues := psElabBinderArguments fixed.bindersRev
  let [fixedType, fixedValue] := fixedValues | throw "common fixed scope changed its order"
  let [valueBinder, typeBinder] := fixed.bindersRev | throw "fixed scope lost dependent binders"
  if !psBinderInfoEq typeBinder.binder .implicit ||
      !psBinderInfoEq valueBinder.binder .explicit ||
      !psExprAlphaEq valueBinder.type fixedType then
    throw "fixed scope changed binder kind or actual dependent domain"
  let mut equations := []
  for (name, type, _, permutation) in entries do
    let header ← (psElabRecursionSpecializeHeader fixed.context type permutation fixedValues).mapError
      psCompilerPscv0ElabError
    if header.bindersRev.length != 1 || header.arguments.length != 3 then
      throw "fixed specialization consumed a returned function or lost a source slot"
    let expectedType := psLogicPi header.context.localContext.nextId "ignored" nat fixedType
    if !psDefEqReadOnlyWithEnv environment psMetaEmpty header.context.localContext
        header.resultType expectedType then
      throw "fixed specialization changed the actual result family"
    let applied := psExprApplyMany (.constE name [.param u]) header.arguments
    let expected := psLogicLam header.context.localContext.nextId "ignored" nat fixedValue
    let proof ← (psElabWellFoundedExtensionalEquality 1 header.context header.resultType
      applied expected).mapError psCompilerPscv0ElabError
    let level ← (psElabExpressionSort header.context header.resultType).mapError psCompilerPscv0ElabError
    let bindersRev := header.bindersRev ++ fixed.bindersRev
    let proposition := psLogicEq level header.resultType applied expected
    equations := equations ++ [.theoremDecl (psNameAppendStr name "equation") [u]
      (psCloseElabForallBinders psMetaEmpty bindersRev proposition)
      (psCloseElabLambdaBinders psMetaEmpty bindersRev proof)]
  match psElabRecursionSpecializeHeader fixed.context firstType
      [some 0, some 0, none] fixedValues with
  | .error _ => pure ()
  | .ok _ => throw "fixed scope accepted a nonbijective permutation"
  match psElabRecursionSpecializeHeader fixed.context firstType
      [some 0, some 1, none] [fixedType, nat] with
  | .error _ => pure ()
  | .ok _ => throw "fixed scope accepted a value of the wrong dependent type"
  let indexed := PsExpr.app (.constE (psRootName "Fin") [])
    (.app (.constE psNatSuccName []) (.fvar 0))
  let changingType := psLogicPi 0 "n" nat (psLogicPi 1 "x" indexed nat)
  match psElabRecursionOpenFixedScope context changingType [none, some 0] 1 with
  | .error _ => pure ()
  | .ok _ => throw "fixed scope captured an unowned varying dependency"
  return declarations ++ equations

-- The result family may depend on the sum tag, but every measure must
-- land in one fixed codomain. Build the actual generic component fixpoint
-- and prove its three member equations independently through the kernel.
private def checkComponentConstruction (environment : PsEnvironment)
    (types values : List PsExpr) : Except String (List PsDeclaration) := do
  let measures ← (types.zipIdx).mapM fun (type, index) => do
    let parameter ← (psInferEnsureForall environment psMetaEmpty psLocalEmpty type).mapError
      (fun _ => "component source type is not unary")
    let body := if index == 0 then PsExpr.bvar 0 else .lit (.natural 0)
    return PsExpr.lam parameter.name parameter.domain body .explicit
  let plan ← (psMutualWellFoundedPlanFor environment psMetaEmpty psLocalEmpty
    types measures (.constE (psNameAppendStr psNatName "lt_wfRel") [])).mapError
      (fun _ => "common typed component measure construction failed")
  let mut branches := []
  for (source, index) in values.zipIdx do
    let branchType ← (psMutualWellFoundedBranchType environment psMetaEmpty psLocalEmpty
      plan index).mapError (fun _ => "component branch type failed")
    let parameter ← (psInferEnsureForall environment psMetaEmpty psLocalEmpty branchType).mapError
      (fun _ => "component branch lost original domain")
    let major := psLocalPushBinding psLocalEmpty parameter.name parameter.domain .explicit
    let result := psExprInstantiate1 parameter.body (.fvar major.id)
    let callback ← (psInferEnsureForall environment psMetaEmpty major.context result).mapError
      (fun _ => "component branch lost decreasing callback")
    let localCallback := psLocalPushBinding major.context callback.name callback.domain .explicit
    for target in List.range types.length do
      let _ ← (psMutualPackingProjection environment psMetaEmpty localCallback.context
        types.length target (.fvar localCallback.id)).mapError
          (fun _ => "typed heterogeneous callee callback projection failed")
      pure ()
    let body := PsExpr.app source (.fvar major.id)
    let branch := psLogicLam major.id "x" parameter.domain
      (psLogicLam localCallback.id "_rec" callback.domain body)
    let _ ← (psElabResolvedTerm (psElabContextEmpty environment []) branch
      (some branchType)).mapError psCompilerPscv0ElabError
    branches := branches ++ [branch]
  let built ← (psMutualWellFoundedBuild environment psMetaEmpty psLocalEmpty plan branches).mapError
    (fun _ => "checked component functional or fixpoint failed")
  let name := psRootName "packingWellFounded"
  let declaration := PsDeclaration.definitionDecl name [] plan.type built.value
  let environment := psEnvironmentInsert environment declaration
  let parameter ← (psInferEnsureForall environment psMetaEmpty psLocalEmpty plan.type).mapError
    (fun _ => "component fixedpoint lost unary type")
  let motive := PsExpr.lam parameter.name parameter.domain parameter.body .explicit
  let mut equations := []
  for ((type, source), index) in (types.zip values).zipIdx do
    let original ← (psInferEnsureForall environment psMetaEmpty psLocalEmpty type).mapError
      (fun _ => "component equation lost original header")
    let major := psLocalPushBinding psLocalEmpty original.name original.domain .explicit
    let result := psExprInstantiate1 original.body (.fvar major.id)
    let packed ← (psMutualPackingPack types.length parameter.domain index (.fvar major.id)).mapError
      (fun _ => "component equation injection failed")
    let context := { psElabContextEmpty environment [] with localContext := major.context }
    let domainLevel ← (psElabExpressionSort context parameter.domain).mapError psCompilerPscv0ElabError
    let resultLevel ← (psElabExpressionSort context result).mapError psCompilerPscv0ElabError
    let left := PsExpr.app (.constE name []) packed
    let right := PsExpr.app source (.fvar major.id)
    let expected := psLogicEq resultLevel result left right
    let proof := psWellFoundedEquation plan.relation [domainLevel, resultLevel]
      motive built.functional packed
    let checked ← (psElabResolvedTerm context proof (some expected)).mapError psCompilerPscv0ElabError
    equations := equations ++ [.theoremDecl
      (psNameAppendNum (psRootName "packingWellFoundedEquation") index) []
      (psLogicPi major.id "x" original.domain expected)
      (psLogicLam major.id "x" original.domain checked.term)]
  -- Fin(n+1) is a genuine dependent measure codomain, not a common relation
  -- domain. A missing member measure also cannot silently alter component arity.
  let some firstType := types.head? | throw "component probe lost its first member"
  match psMutualPackingUncurryTypeND environment psMetaEmpty psLocalEmpty [firstType] with
  | .error _ => pure ()
  | .ok _ => throw "component measure accepted a varying codomain"
  match psMutualWellFoundedPlanFor environment psMetaEmpty psLocalEmpty
      types (measures.drop 1) (.constE (psNameAppendStr psNatName "lt_wfRel") []) with
  | .error _ => pure ()
  | .ok _ => throw "component measure accepted an incomplete member list"
  return declaration :: equations

private def build : Except String (List PsDeclaration) := do
  let environment := psStandardPSumDeclarations.foldl psEnvironmentInsert
    psSelfHostProdPreludeEnvironment
  let environment := psStandardPSumReducibility.foldl
    (fun env (name, status) => psEnvironmentSetReducibility env name status) environment
  checkCallbackScopes environment
  checkRetainedOwners environment
  let fixedScopeDeclarations ← checkFixedScopes environment
  let source :=
    "function packingFirst(n: Nat): Fin(n + 1) := Fin.mk(n, Nat.lt_succ_self(n))\n" ++
    "function packingSecond(b: Bool): Bool := b\n" ++
    "function packingThird(s: PSum(Nat, Bool)): PSum(Nat, Bool) := s\n" ++
    "function packingDependent(n: Nat, x: Fin(n + 1), s: PSigma(fun (k: Nat) => Fin(k + 1))): Nat -> Fin(n + 1) := fun (ignored: Nat) => x\n"
  let parsed ← psPscv0ParseProgram source
  let elaborated ← (psElabProgramWithOrigins environment parsed).mapError psCompilerPscv0ElabError
  let environment := elaborated.result.environment
  let names := ["packingFirst", "packingSecond", "packingThird"].map psRootName
  let declarations ← names.mapM fun name =>
    match psEnvironmentFind environment name with
    | some declaration => pure declaration
    | none => throw "packing source declaration is missing"
  let types := declarations.map psDeclarationType
  let values := names.map fun name => PsExpr.constE name []
  let componentDeclarations ← checkComponentConstruction environment types values
  let type ← (psMutualPackingUncurryType environment psMetaEmpty psLocalEmpty types).mapError
    (fun _ => "packing dependent type construction failed")
  let body ← (psMutualPackingUncurry environment psMetaEmpty psLocalEmpty type values).mapError
    (fun _ => "packing heterogeneous function construction failed")
  let name := psRootName "packingCombined"
  let packed := PsDeclaration.definitionDecl name [] type body
  let environment := psEnvironmentInsert environment packed
  let mut proofs := []
  for index in [0, 1, 2] do
    let projected ← (psMutualPackingProjection environment psMetaEmpty psLocalEmpty
      3 index (.constE name [])).mapError (fun _ => "packing projection failed")
    let some originalType := types[index]? | throw "packing original type is missing"
    let some original := values[index]? | throw "packing original value is missing"
    let context := psElabContextEmpty environment []
    let checked ← (psElabResolvedTerm context projected (some originalType)).mapError psCompilerPscv0ElabError
    let equality ← (psElabWellFoundedExtensionalEquality 1 checked.context
      originalType projected original).mapError psCompilerPscv0ElabError
    let level ← (psElabExpressionSort checked.context originalType).mapError psCompilerPscv0ElabError
    proofs := proofs ++ [.theoremDecl (psNameAppendNum (psRootName "packingEquation") index) []
      (psLogicEq level originalType projected original) equality]
  -- A dependent three-slot source header has an original PSigma in its
  -- final slot and a returned function. Neither may be flattened by packing.
  let dependentName := psRootName "packingDependent"
  let some dependent := psEnvironmentFind environment dependentName
    | throw "missing original dependent source"
  let sourceType := psDeclarationType dependent
  let slotNames := ["n", "x", "s"].map psRootName
  let unaryType ← (psWellFoundedTupleUncurryType environment psMetaEmpty psLocalEmpty
    slotNames sourceType).mapError (fun _ => "dependent unary type failed")
  let unaryBody ← (psWellFoundedTupleUncurry environment psMetaEmpty psLocalEmpty
    slotNames unaryType (.constE dependentName [])).mapError
      (fun _ => "dependent unary body failed")
  let unaryName := psRootName "packingDependentUnary"
  let unary := PsDeclaration.definitionDecl unaryName [] unaryType unaryBody
  let environment := psEnvironmentInsert environment unary
  let curried ← (psWellFoundedTupleCurry environment psMetaEmpty psLocalEmpty
    slotNames sourceType (.constE unaryName [])).mapError
      (fun _ => "dependent original header reconstruction failed")
  let context := psElabContextEmpty environment []
  let proof ← (psElabWellFoundedExtensionalEquality 4 context sourceType
    curried (.constE dependentName [])).mapError psCompilerPscv0ElabError
  let level ← (psElabExpressionSort context sourceType).mapError psCompilerPscv0ElabError
  proofs := proofs ++ [.theoremDecl (psRootName "packingDependentEquation") []
    (psLogicEq level sourceType curried (.constE dependentName [])) proof]
  let parameter ← (psInferEnsureForall environment psMetaEmpty psLocalEmpty type).mapError
    (fun _ => "packing result is not unary")
  let originalDomains ← (psMutualPackingDomains 3 parameter.domain).mapError
    (fun _ => "packing original domains are missing")
  if originalDomains.length != 3 then throw "packing flattened a user PSum domain"
  let userSum := psExprApplyMany (.constE (psRootName "PSum") [.succ .zero, .succ .zero])
    [.constE psNatName [], .constE psBoolName []]
  let some lastDomain := originalDomains[2]? | throw "packing final domain is missing"
  if !psExprAlphaEq lastDomain userSum then throw "packing changed the final source PSum"
  let samples := [PsExpr.lit (.natural 3), .constE psBoolTrueName [],
    psExprApplyMany (.constE (psNameAppendStr (psRootName "PSum") "inr")
      [.succ .zero, .succ .zero])
      [.constE psNatName [], .constE psBoolName [], .constE psBoolFalseName []]]
  for (value, index) in samples.zipIdx do
    let injected ← (psMutualPackingPack 3 parameter.domain index value).mapError
      (fun _ => "packing injection failed")
    let some (observedIndex, observedValue) :=
      psMutualPackingUnpack 3 parameter.domain injected
      | throw "packing constructor round-trip failed"
    if observedIndex != index || !psExprAlphaEq value observedValue then
      throw "packing changed member index or user value"
  match psMutualPackingPack 3 parameter.domain 3 (.lit (.natural 0)) with
  | .error _ => pure ()
  | .ok _ => throw "packing accepted an unowned member index"
  if (psMutualPackingUnpack 3 parameter.domain (.lit (.natural 0))).isSome then
    throw "packing accepted a missing component constructor"
  -- Unlike Sum, the component encoding also accepts arbitrary Sorts,
  -- including Prop and heterogeneous universe parameters.
  let u := psRootName "u"
  let v := psRootName "v"
  let a := psLocalPushBinding psLocalEmpty (psRootName "A") (.sortE (.param u)) .implicit
  let b := psLocalPushBinding a.context (psRootName "B") (.sortE (.param v)) .implicit
  let x := psLocalPushBinding b.context (psRootName "x") (.fvar a.id) .explicit
  let sortDomain ← (psMutualPackingDomain environment psMetaEmpty x.context
    [.fvar a.id, .fvar b.id]).mapError (fun _ => "packing arbitrary Sorts failed")
  let sortBody ← (psMutualPackingPack 2 sortDomain 0 (.fvar x.id)).mapError
    (fun _ => "packing arbitrary Sort injection failed")
  let sortType := psLogicPi a.id "A" (.sortE (.param u))
    (psLogicPi b.id "B" (.sortE (.param v))
      (psLogicPi x.id "x" (.fvar a.id) sortDomain) .implicit) .implicit
  let sortValue := psLogicLam a.id "A" (.sortE (.param u))
    (psLogicLam b.id "B" (.sortE (.param v))
      (psLogicLam x.id "x" (.fvar a.id) sortBody) .implicit) .implicit
  let _ ← (psElabResolvedTerm (psElabContextEmpty environment [u, v])
    sortValue (some sortType)).mapError psCompilerPscv0ElabError
  let sorts := PsDeclaration.definitionDecl (psRootName "packingSorts") [u, v] sortType sortValue
  return psStandardPSumDeclarations ++ fixedScopeDeclarations ++ elaborated.result.declarations ++ componentDeclarations ++ [packed, sorts, unary] ++ proofs

def main : IO Unit := do
  ensure (Lean.githash == PsV7Native.leanCommit) "packing requires pinned Lean4.35.0"
  checkFixedParameters
  let declarations ← fromExcept build
  let admissions ← fromExcept ((psCompilerAdmissionsFromPrepared { declarations }).mapError
    psCompilerPscv0Error)
  let decoded ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions admissions).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  let prelude ← match ← PsKernelLean.buildLeanPreludeEnvironment with
    | .ok environment => pure environment
    | .error error => throw (IO.userError error.message)
  let checked ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    (do
      let mut environment := prelude
      for declaration in decoded do
        let declaration := PsKernelLean.psKernelWithDefinitionHeight environment declaration
        match environment.addDeclCore 2000000 20000 declaration none with
        | .ok next => environment := next
        | .error error => throw ("packing official kernel: " ++
            PsKernelLean.kernelExceptionSummary error ++ PsKernelLean.kernelExceptionContext error)
      pure () : Except String Unit)
  fromExcept checked
  IO.println "PSCV0_M3_RETAINED_CALLS: PASS source-owned reordered dependent headers, actual branch and let scopes, full application spines, returned-function arity and conservative underapplication; source mutual WF remains separate"
  IO.println "PSCV0_M3_FIXED_SCOPES: PASS three reordered polymorphic headers, dependent fixed values, implicit binder preservation, returned-function ownership, exact kernel equations and malformed/dependent mapping refusals"
  IO.println "PSCV0_M3_COMPONENT_FIX: PASS heterogeneous dependent result family, common Nat measure, three typed decreasing callbacks, actual checked fix_eq member equations and incomplete/dependent-measure refusals; source mutual WF is separate"
  IO.println "PSCV0_M3_CALLBACK_SCOPES: PASS two typed callees, current refined capture, ordinary local shadow, saved scope, escape refusal and cross-owner parameter correspondence"
  IO.println "PSCV0_M3_MUTUAL_PACKING: PASS three heterogeneous dependent components, complete unary currying with dependent header and returned function, exact checked projection equations, user PSum ownership and malformed index/constructor refusals; source mutual WF is separate"
