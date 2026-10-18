import Ps.Host.NativeV7
import Ps.Elab.PreDefinition
import Ps.Elab.Where

-- Pinned ordinary Lean independently partitions these disconnected functions.
-- The original block's section parameters and body-only universe remain in
-- every public signature, including the Bool and nonrecursive components.
namespace M3PreDefinitionOracle

universe u v

def eraseType (_ : Type v) (n : Nat) : Nat := n

section
variable (A : Type u) (a : A) (bias : Nat)
mutual
  def caller (n : Nat) : Nat := countNat n + flag true
  def countNat (n : Nat) : Nat :=
    match n with
    | 0 => bias
    | k + 1 => eraseType (PUnit : Type v) (countNat k + 1)
  def countList (xs : List A) : Nat :=
    match xs with
    | [] => 0
    | _ :: tail => countList tail + 1
  def flag (value : Bool) : Nat :=
    match value with
    | false => 3
    | true => 7
  def pick (n : Nat) : A :=
    match n with
    | 0 => a
    | _ + 1 => a
end
end

example : ∀ (A : Type u), A → Nat → Bool → Nat := flag.{u, v}
example : ∀ (A : Type u), A → Nat → List A → Nat := countList.{u, v}
example : ∀ (A : Type u), A → Nat → Nat → A := pick.{u, v}
example : caller.{0, 0} Nat 11 5 3 = 15 := rfl
example : countNat.{0, 0} Nat 11 5 4 = 9 := rfl
example : countList.{0, 0} Nat 11 5 [2, 4] = 2 := rfl
example : flag.{0, 0} Nat 11 5 true = 7 := rfl
example : pick.{0, 0} Nat 11 5 4 = 11 := rfl

-- Pinned PreDefinition.Main partitions SCCs before Basic.checkCodomainsLevel.
-- The actual cyclic component must have compatible result universes; the
-- disconnected same-signature functions above are the positive control.
def retainA (A : Type u) (a : A) (_ : Nat) : A := a
def retainNat (A : Type u) (_ : A) (n : Nat) : Nat := n

/-- error: invalid mutual definition, result types must be in the same universe level -/
#guard_msgs (error, drop warning, substring := true) in
mutual
  def mixedNat (A : Type u) (a : A) (n : Nat) : Nat :=
    match n with
    | 0 => 0
    | k + 1 => retainNat A (mixedValue A a k) 1
  def mixedValue (A : Type u) (a : A) (n : Nat) : A :=
    match n with
    | 0 => a
    | k + 1 => retainA A a (mixedNat A a k)
end

end M3PreDefinitionOracle

namespace M3PreDefinitions

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def source : String :=
  "universe u v\n" ++
  "function pdEraseType(A: Type v, n: Nat): Nat := n\n" ++
  "section\nvariable (A: Type u) (a: A) (bias: Nat)\n" ++
  "mutual\n" ++
  "function pdCaller(n: Nat): Nat := pdCountNat(n) + pdFlag(true)\n" ++
  "function pdCountNat(n: Nat): Nat := match n with { | 0 => bias | k + 1 => pdEraseType((PUnit : Type v), pdCountNat(k) + 1) }\n" ++
  "function pdCountList(xs: List(A)): Nat := match xs with { | .nil => 0 | .cons head tail => pdCountList(tail) + 1 }\n" ++
  "function pdFlag(value: Bool): Nat := match value with { | .false => 3 | .true => 7 }\n" ++
  "function pdPick(n: Nat): A := match n with { | 0 => a | k + 1 => a }\n" ++
  "end\nend\n"

private def elaborate (text : String) : IO PsElabModuleWithOriginsResult := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  fromExcept ((psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed).mapError
    psCompilerPscv0ElabError)

private structure Prepared where
  environment : PsEnvironment
  block : PsElabPreDefinitionBlock

-- Reuse the real source scoper and typed capture producer. The fixture only
-- exposes its Core result so independent corruptions can target this boundary.
private def prepareCommands (state : PsCommandState) : List PsSyntaxCommand →
    Except PsElabError Prepared
  | [] => throw (.data "predefinition fixture expected one source mutual block")
  | .mutualDeclarations members span :: _ => do
    let names := members.map (fun member => (psElabOriginSource member.declaration).fst.segments)
    let aliases := names.zipIdx.map fun (name, index) =>
      (name, ["$psc0PreDefinitionFixture", psNatToString index])
    let resolver : PsScopeResolver := {
      environment := state.environment
      scope := state.scope
      mutualNames := names
      mutualAliases := aliases }
    let scopedMembers ← (members.zip aliases).mapM fun (member, alias) =>
      psScopePreDefinition resolver member
        (PsSyntaxName.mk alias.snd (psElabOriginSource member.declaration).snd)
    let used := scopedMembers.foldl (fun used member => psScopeUnion used member.used) []
    let captures := psScopeSelect state.scope used
    let block ← psElabPreparePreDefinitions state.environment
      (state.scope.levelNames.map psRootName) captures scopedMembers span
    return { environment := state.environment, block }
  | command :: rest => do
    let state ← psElabCommand state command
    prepareCommands state rest

private def prepare (text : String) : IO Prepared := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  fromExcept ((prepareCommands { environment := psSelfHostProdPreludeEnvironment }
    parsed.commands).mapError psCompilerPscv0ElabError)

private def binderNames : PsExpr → List String
  | .forallE name _ body _ => psNameToString name :: binderNames body
  | _ => []

private def refusal : PsElabError → String
  | .atDeclaration _ error => refusal error
  | .data message => message
  | error => psCompilerPscv0ElabError error

private def expectRefused (prepared : Prepared) (block : PsElabPreDefinitionBlock)
    (rule : String)
    (consumer : Option PsElabPreDefinitionWellFoundedConsumer := none) : IO Unit := do
  match psElabPreDefinitionBatch prepared.environment block consumer with
  | .ok _ => throw (IO.userError ("corrupt checked predefinition was accepted: " ++ rule))
  | .error error =>
    ensure ((refusal error).startsWith ("PSCV0-PREDEFINITION-" ++ rule ++ ":"))
      ("checked predefinition refused at the wrong rule: " ++ refusal error)

-- Change one actual, well-typed Nat capture argument inside a full peer call.
-- The resulting source term still typechecks; its capture identity is wrong.
private def changeCapture (peerId : Nat) : PsExpr → PsExpr
  | .app fn argument =>
    let value := PsExpr.app fn argument
    let view := psExprAppView value
    match view.head with
    | .fvar id =>
      if id == peerId && view.args.length >= 3 then
        psExprApplyMany view.head (view.args.zipIdx.map fun (arg, index) =>
          if index == 2 then .lit (.natural 0) else arg)
      else .app (changeCapture peerId fn) (changeCapture peerId argument)
    | _ => .app (changeCapture peerId fn) (changeCapture peerId argument)
  | .lam name domain body binder =>
    .lam name (changeCapture peerId domain) (changeCapture peerId body) binder
  | .forallE name domain body binder =>
    .forallE name (changeCapture peerId domain) (changeCapture peerId body) binder
  | .letE name type value body =>
    .letE name (changeCapture peerId type) (changeCapture peerId value) (changeCapture peerId body)
  | .proj name index value => .proj name index (changeCapture peerId value)
  | value => value

private def checkCorruptions (prepared : Prepared) : IO Unit := do
  let block := prepared.block
  let some caller := block.members[0]? | throw (IO.userError "missing caller input")
  let some count := block.members[1]? | throw (IO.userError "missing recursive input")
  let unknown := block.context.localContext.nextId + 100
  let escaped := { caller with
    value := psElabSubstituteLocals [(count.peerId, .fvar unknown)] caller.value }
  expectRefused prepared { block with members := escaped :: block.members.drop 1 } "CLOSURE"
  let rawLocals := block.context.localContext.declarations.map fun entry =>
    match entry with
    | .binding id name type binder =>
      .binding id name (if id == caller.peerId then .constE psNatName [] else type) binder
    | entry => entry
  expectRefused prepared {
    block with context := { block.context with
      localContext := { block.context.localContext with declarations := rawLocals } } } "OWNERSHIP"
  expectRefused prepared { block with
    members := { caller with sourceHeaderCount := caller.sourceHeaderCount + 1 } :: block.members.drop 1 }
    "HEADER"
  let changed := { count with value := changeCapture count.peerId count.value }
  ensure (!psExprAlphaEq changed.value count.value)
    "capture corruption did not reach the actual full recursive call"
  let peerContext ← fromExcept ((psElabPreDefinitionValidate prepared.environment block).mapError
    psCompilerPscv0ElabError)
  let _ ← fromExcept ((psElabResolvedTerm peerContext changed.value (some changed.type)).mapError
    psCompilerPscv0ElabError)
  expectRefused prepared { block with
    members := block.members.map (fun member => if member.peerId == count.peerId then changed else member) }
    "CAPTURE-CALL"
  expectRefused prepared { block with levelNames := [psRootName "u"] } "UNIVERSES"

private def natWitness (name label : String) (arguments : List PsExpr) (expected : Nat) : PsDeclaration :=
  let nat := PsExpr.constE psNatName []
  let actual := psExprApplyMany (.constE (psRootName name) [.zero, .zero]) arguments
  let value := PsExpr.lit (.natural expected)
  .theoremDecl (psRootName label) [] (psLogicEq (.succ .zero) nat actual value)
    (psLogicRefl (.succ .zero) nat value)

private def checkAccepted (prepared : Prepared) (compiled : PsElabModuleWithOriginsResult) :
    IO (List PsDeclaration) := do
  let block := prepared.block
  let names := ["pdCaller", "pdCountNat", "pdCountList", "pdFlag", "pdPick"]
  ensure (block.members.map (fun member => psNameToString member.name) == names &&
    block.members.map (·.sourceIndex) == List.range names.length &&
    psElabMutualLevelNamesEqual block.levelNames [psRootName "u", psRootName "v"] &&
    block.members.all (fun member => member.captures.length == 3 && member.sourceHeaderCount == 1))
    "typed source block lost whole-block captures, original arity/order or body-only universes"
  let groupOrigins := compiled.origins.filter (·.mutualGroup.isSome)
  ensure (groupOrigins.length == names.length &&
    groupOrigins.map (fun origin => psScopeKey origin.sourceName) == names)
    "SCC emission changed original source member order"
  let emitted := compiled.result.declarations.filterMap fun declaration =>
    match declaration with | .definitionDecl name .. => some (psNameToString name) | _ => none
  let position := fun name => (emitted.zipIdx.find? (fun entry => entry.fst == name)).map Prod.snd
  match position "pdCaller", position "pdCountNat", position "pdFlag" with
  | some caller, some count, some flag =>
    ensure (count < caller && flag < caller) "real predecessor definitions were not staged before their caller"
  | _, _, _ => throw (IO.userError "SCC output lost a dependency owner")
  for (name, parameter) in names.zip ["n", "n", "xs", "value", "n"] do
    let some (.definitionDecl actual levels type value) :=
        psEnvironmentFind compiled.result.environment (psRootName name)
      | throw (IO.userError "a total disconnected component did not become an ordinary definition")
    ensure (binderNames type == ["A", "a", "bias", parameter] &&
      psElabMutualLevelNamesEqual levels block.levelNames &&
      (psExprFVarIds value).isEmpty && !psExprHasUnresolvedMeta value)
      "SCC publication changed the original closed header or whole-block universe layout"
    let some (.theoremDecl equation equationLevels _ proof) :=
        psEnvironmentFind compiled.result.environment (psNameAppendStr actual "eq_def")
      | throw (IO.userError "a disconnected component lost its exact source equation")
    ensure (psNameEq equation (psNameAppendStr actual "eq_def") &&
      psElabMutualLevelNamesEqual equationLevels levels && (psExprFVarIds proof).isEmpty)
      "source equation lost its actual member, closed proof or fixed block universes"
  let nat := PsExpr.constE psNatName []
  let common := [nat, .lit (.natural 11), .lit (.natural 5)]
  let nil := PsExpr.app (.constE (psNameAppendStr psListName "nil") [.zero]) nat
  let cons := fun head tail => psExprApplyMany
    (.constE (psNameAppendStr psListName "cons") [.zero]) [nat, .lit (.natural head), tail]
  let witnesses := [
    natWitness "pdCaller" "pdCallerObserved" (common ++ [.lit (.natural 3)]) 15,
    natWitness "pdCountNat" "pdCountNatObserved" (common ++ [.lit (.natural 4)]) 9,
    natWitness "pdCountList" "pdCountListObserved" (common ++ [cons 2 (cons 4 nil)]) 2,
    natWitness "pdFlag" "pdFlagObserved" (common ++ [.constE (psNameAppendStr psBoolName "true") []]) 7,
    natWitness "pdPick" "pdPickObserved" (common ++ [.lit (.natural 4)]) 11 ]
  let _ ← fromExcept ((psAddDeclarationList compiled.result.environment witnesses).mapError
    psCompilerPscv0ElabError)
  return witnesses

-- A completely checked constant implementation and its true equation are
-- insufficient when they describe a different retained recursive source body.
private def wrongWellFounded : PsElabPreDefinitionWellFoundedConsumer :=
  fun environment levels members => do
    let [member] := members
      | throw (.data "singleton forged-source fixture requires one original owner")
    let value := PsExpr.lam (psRootName "n") (.constE psNatName []) (.lit (.natural 0)) .explicit
    let result ← psElabPreDefinitionNonrecursive environment levels { member with value }
    let [declaration, equation] := result.batch.declarations
      | throw (.data "malformed checked constant fixture")
    return { results := [{
      declaration, equation
      metaContext := (psElabContextEmpty environment levels).metaContext
      sourceInfo := member.sourceInfo }] }

-- The result lambda remains outside the one-argument source header. Its true
-- zero-body equation must still fail when case transport locates the retained
-- source match under that lambda and checks the complete function equality.
private def wrongFunctionWellFounded : PsElabPreDefinitionWellFoundedConsumer :=
  fun environment levels members => do
    let [member] := members
      | throw (.data "singleton forged-source fixture requires one original owner")
    let nat := PsExpr.constE psNatName []
    let value := PsExpr.lam (psRootName "n") nat
      (.lam (psRootName "seed") nat (.lit (.natural 0)) .explicit) .explicit
    let result ← psElabPreDefinitionNonrecursive environment levels { member with value }
    let [declaration, equation] := result.batch.declarations
      | throw (.data "malformed checked constant-function fixture")
    return { results := [{
      declaration, equation
      metaContext := (psElabContextEmpty environment levels).metaContext
      sourceInfo := member.sourceInfo }] }

private def checkWellFoundedIdentity : IO Unit := do
  let prepared ← prepare
    ("mutual\nfunction pdMeasured(n: Nat): Nat := match n with { | 0 => 1 | k + 1 => pdMeasured(k) + 1 }\n" ++
      "termination_by n\nend\n")
  expectRefused prepared prepared.block "WF"
  expectRefused prepared prepared.block "WF-EQUATION" (some wrongWellFounded)
  let functionPrepared ← prepare
    ("mutual\nfunction pdMeasuredFunction(n: Nat): Nat -> Nat := fun (seed: Nat) => " ++
      "match n with { | 0 => seed + 1 | k + 1 => pdMeasuredFunction(k)(seed + 1) }\n" ++
      "termination_by n\nend\n")
  ensure (functionPrepared.block.members.all (fun member =>
    member.sourceHeaderCount == 1 && member.captures.isEmpty))
    "result-lambda equation fixture changed the original source header or capture scope"
  match psElabPreDefinitionBatch functionPrepared.environment functionPrepared.block
      (some wrongFunctionWellFounded) with
  | .ok _ => throw (IO.userError "a checked zero function replaced the retained recursive function body")
  | .error error =>
    ensure (refusal error == "PSCV0-PREDEFINITION-WF-EQUATION: checked extensionality and constructor cases do not prove the actual RHS equals the retained source RHS")
      ("wrong function body did not reach the checked extensionality/case-proof refusal: " ++ refusal error)

private def checkInheritedStrategy : IO Unit := do
  let variants : List (String × PsElabPreDefinitionStrategy) := [
    ("", .total), ("\ntermination_by k", .wellFounded), ("\npartial_fixpoint", .fixedpoint) ]
  for (suffix, incorrect) in variants do
    let prepared ← prepare
      ("mutual\npartial function pdPartialMain(n: Nat): Nat := pdPartialMain(n)\n" ++
        "partial function pdLocalMain(n: Nat): Nat := loop(n)\n" ++
        "where { def loop(k: Nat): Nat := loop(k)" ++ suffix ++ "\n}\nend\n")
    let helperName := psNameAppendStr (psRootName "pdLocalMain") "loop"
    let some helper := prepared.block.members.find? (fun member => psNameEq member.name helperName)
      | throw (IO.userError "inherited strategy fixture lost the compatible main's plain local helper")
    ensure (psElabPreDefinitionStrategyEq helper.strategy .partial)
      "a local helper did not inherit the compatible original main block's partial intent"
    let corrupted := prepared.block.members.map fun member =>
      if psNameEq member.name helperName then { member with strategy := incorrect } else member
    expectRefused prepared { prepared.block with members := corrupted } "STRATEGY"
    if suffix.isEmpty then
      let _ ← fromExcept ((psElabPreDefinitionValidate prepared.environment prepared.block).mapError
        psCompilerPscv0ElabError)
      let first :: rest := prepared.block.members
        | throw (IO.userError "main-modifier corruption lost the first actual source member")
      let .declaration (.partialDefinition name binders type value span) := first.source
        | throw (IO.userError "main-modifier corruption lost the original partial source head")
      -- Core header/value/peer ownership stays identical, and the individual
      -- source strategy is changed consistently. Only the original-main
      -- compatibility invariant distinguishes this retained-provenance input.
      let first := { first with
        source := .declaration (.definition name binders type value span)
        strategy := .total }
      match psElabPreDefinitionBatch prepared.environment
          { prepared.block with members := first :: rest } with
      | .ok _ => throw (IO.userError "typed batch accepted corrupted mixed-main source provenance")
      | .error error =>
        ensure (refusal error == "PSCV0-MUTUAL-STRATEGY: cannot mix partial and non-partial original main definitions")
          ("corrupted main modifiers refused at the wrong owner: " ++ refusal error)

private def checkAtomicity : IO (List PsDeclaration) := do
  let sourcePrefix := "mutual\nfunction pdAtomicReady(flag: Bool): Nat := if (flag) { 3 } else { 7 }\n"
  let failed ← fromExcept (psPscv0ParseProgram
    (sourcePrefix ++ "function pdAtomicLater(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => pdAtomicLater(n) }\nend\n"))
  match psElabProgramWithOrigins psSelfHostProdPreludeEnvironment failed with
  | .ok _ => throw (IO.userError "a late invalid SCC published an earlier ready component")
  | .error error =>
    ensure ((refusal error).startsWith "PSCV0-MUTUAL-TOTAL: DECREASE:")
      ("late SCC failure lost its exact structural refusal: " ++ refusal error)
  for name in ["pdAtomicReady", "pdAtomicLater"] do
    ensure ((psEnvironmentFind psSelfHostProdPreludeEnvironment (psRootName name)).isNone)
      "failed typed block leaked an actual staged predecessor"
  let repaired ← elaborate
    (sourcePrefix ++ "function pdAtomicLater(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => pdAtomicLater(k) + 1 }\nend\n")
  ensure (repaired.result.declarations.length == 4)
    "atomic typed-block failure prevented reuse of the original names"
  return repaired.result.declarations

-- The caller admits these exact definitions, equations and observations
-- using its already-built fresh official-kernel prelude. No new runtime ABI.
def check : IO (List PsDeclaration) := do
  let prepared ← prepare source
  let compiled ← elaborate source
  let witnesses ← checkAccepted prepared compiled
  checkCorruptions prepared
  checkWellFoundedIdentity
  checkInheritedStrategy
  let repaired ← checkAtomicity
  IO.println "PSCV0_M3_PREDEFINITIONS: PASS native disconnected-family/result signatures, actual typed SCC dependency order, whole-block captures and body universes, source equations, full-peer/capture, original-main modifier and inherited-helper strategy corruption, WF body identity and late-component atomicity"
  return compiled.result.declarations ++ witnesses ++ repaired

end M3PreDefinitions
