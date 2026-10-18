import Ps.Host.NativeV7
import Ps.Environment.StandardPSumData
import Ps.Meta.MutualPacking
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

private def build : Except String (List PsDeclaration) := do
  let environment := psStandardPSumDeclarations.foldl psEnvironmentInsert
    psSelfHostProdPreludeEnvironment
  let environment := psStandardPSumReducibility.foldl
    (fun env (name, status) => psEnvironmentSetReducibility env name status) environment
  checkCallbackScopes environment
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
  return psStandardPSumDeclarations ++ elaborated.result.declarations ++ [packed, sorts, unary] ++ proofs

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
  IO.println "PSCV0_M3_CALLBACK_SCOPES: PASS two typed callees, current refined capture, ordinary local shadow, saved scope, escape refusal and cross-owner parameter correspondence"
  IO.println "PSCV0_M3_MUTUAL_PACKING: PASS three heterogeneous dependent components, complete unary currying with dependent header and returned function, exact checked projection equations, user PSum ownership and malformed index/constructor refusals; source mutual WF is separate"
