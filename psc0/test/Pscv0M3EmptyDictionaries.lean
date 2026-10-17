import Ps.Host.NativeV7
import Lean.Util.CollectAxioms

-- Independent native definitions at the required Lean pin. A relation is
-- type-valued and its law is a proof; the structure itself still has a value.
namespace M3EmptyDictionariesOracle

class EmptyRelation (A : Type) where
  rel : A → A → Prop
  lawful : ∀ a, rel a a

def produce (A : Type) (flag : Bool) : EmptyRelation A :=
  if flag then ⟨fun a b => a = b, fun a => Eq.refl a⟩
  else ⟨fun _ _ => True, fun _ => True.intro⟩

def forward {A : Type} (value : EmptyRelation A) : EmptyRelation A := value

def choose (A : Type) (flag : Bool) : EmptyRelation A :=
  forward (produce A flag)

def constant : EmptyRelation Nat := produce Nat false

def consume {A : Type} (_value : EmptyRelation A) (n : Nat) : Nat := n + 11

example : (produce Nat true).rel 7 9 = (7 = 9) := rfl
example : (produce Nat false).rel 7 9 = True := rfl
example (A : Type) (flag : Bool) : choose A flag = produce A flag := rfl

-- These controls have respectively no source fields and one retained field.
structure EmptyMarker (A : Type) where

def marker (A : Type) (flag : Bool) : EmptyMarker A :=
  if flag then ⟨⟩ else ⟨⟩

def markerConsume {A : Type} (_value : EmptyMarker A) (n : Nat) : Nat := n + 3

class ValueDictionary where
  value : Nat

def valueMake (flag : Bool) : ValueDictionary := ⟨if flag then 43 else 17⟩
def valueForward (value : ValueDictionary) : ValueDictionary := value

-- The generic Inhabited layout has a retained field. Its proof-only
-- specialization must keep the pre-existing specialized erasure behavior.
def proofDefault : Inhabited True := ⟨True.intro⟩

def dictionaryOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (consume (choose Nat flag) (if flag then 43 else 17))

def constantOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (consume constant (if flag then 46 else 20))

def markerOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (markerConsume (marker Nat flag) (if flag then 43 else 17))

def valueOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat ((valueForward (valueMake flag)).value + 5)

run_cmd do
  for name in #[``produce, ``forward, ``choose, ``constant, ``consume,
      ``marker, ``markerConsume, ``valueMake, ``valueForward, ``proofDefault,
      ``dictionaryOutput, ``constantOutput, ``markerOutput, ``valueOutput] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun name => name == ``propext || name == ``Quot.sound) do
      throwError "empty dictionary oracle uses an unapproved assumption: {name}: {axioms}"
  Lean.logInfo "PSCV0_M3_EMPTY_NATIVE: PASS checked relation/proof fields, nominal values and independent native outputs"

end M3EmptyDictionariesOracle

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def relationSource : String :=
  "class M3EmptyRelation(A: Type) where {\n" ++
  " rel: A -> A -> Prop\n" ++
  " lawful: forall(a: A), rel(a, a)\n}\n" ++
  "function m3emptyproduce(A: Type, flag: Bool): M3EmptyRelation A := if (flag) {\n" ++
  " M3EmptyRelation.mk((fun (a: A) => fun (b: A) => a = b), (fun (a: A) => Eq.refl(a)))\n" ++
  "} else {\n" ++
  " M3EmptyRelation.mk((fun (a: A) => fun (b: A) => True), (fun (a: A) => True.intro))\n}\n" ++
  "function m3emptyforward{A: Type}(value: M3EmptyRelation A): M3EmptyRelation A := value\n" ++
  "function m3emptychoose(A: Type, flag: Bool): M3EmptyRelation A := m3emptyforward(m3emptyproduce(A, flag))\n" ++
  "const m3emptyconstant: M3EmptyRelation Nat := m3emptyproduce(Nat, false)\n" ++
  "function m3emptyconsume{A: Type}(value: M3EmptyRelation A, n: Nat): Nat := n + 11\n" ++
  "function m3emptyforeign(flag: Bool): M3EmptyRelation Nat := m3emptychoose(Nat, flag)\n" ++
  "theorem m3emptyforwardEquation(A: Type, flag: Bool): m3emptychoose(A, flag) = m3emptyproduce(A, flag) := by { rfl }\n"

private def controlSource : String :=
  "structure M3EmptyMarker(A: Type) where { }\n" ++
  "function m3emptymarker(A: Type, flag: Bool): M3EmptyMarker A := if (flag) { M3EmptyMarker.mk } else { M3EmptyMarker.mk }\n" ++
  "function m3emptymarkerconsume{A: Type}(value: M3EmptyMarker A, n: Nat): Nat := n + 3\n" ++
  "class M3ValueDictionary where { value: Nat }\n" ++
  "function m3emptyvaluemake(flag: Bool): M3ValueDictionary := M3ValueDictionary.mk(if (flag) { 43 } else { 17 })\n" ++
  "function m3emptyvalueforward(value: M3ValueDictionary): M3ValueDictionary := value\n" ++
  "const m3emptyproofdefault: Inhabited True := Inhabited.mk(True.intro)\n"

private def source : String :=
  relationSource ++ controlSource ++
  "function m3emptydictionary(flag: Bool): UInt64 := UInt64.ofNat(m3emptyconsume(m3emptychoose(Nat, flag), if (flag) { 43 } else { 17 }))\n" ++
  "function m3emptyclosed(flag: Bool): UInt64 := UInt64.ofNat(m3emptyconsume(m3emptyconstant, if (flag) { 46 } else { 20 }))\n" ++
  "function m3emptymarkeroutput(flag: Bool): UInt64 := UInt64.ofNat(m3emptymarkerconsume(m3emptymarker(Nat, flag), if (flag) { 43 } else { 17 }))\n" ++
  "function m3emptyvalue(flag: Bool): UInt64 := UInt64.ofNat((m3emptyvalueforward(m3emptyvaluemake(flag))).value + 5)\n"

private def outputCases : List (String × (Bool → UInt64)) :=
  [("m3emptydictionary", M3EmptyDictionariesOracle.dictionaryOutput),
   ("m3emptyclosed", M3EmptyDictionariesOracle.constantOutput),
   ("m3emptymarkeroutput", M3EmptyDictionariesOracle.markerOutput),
   ("m3emptyvalue", M3EmptyDictionariesOracle.valueOutput)]

private def requireDeclaration (ir : PsVerifiedIrModule) (name : String) :
    IO PsVerifiedIrDeclaration :=
  match ir.declarations.find? (fun declaration => declaration.name == name) with
  | some declaration => pure declaration
  | none => throw (IO.userError ("missing ordinary empty-dictionary declaration: " ++ name))

private def isNamed (name : String) (type : PsVerifiedIrType) : Bool :=
  match type with
  | .named actual [_] => actual == name
  | _ => false

-- Inspect the output of the real checked-layout preparation and erasure
-- owners. Empty values keep nominal types, parameters, records and calls.
-- Merely emitting scalar wrapper outputs would not detect a lost producer.
private def checkConstruction : IO Unit := do
  let parsed ← fromExcept (psPscv0ParseProgram source)
  let elaborated ← fromExcept ((psElabProgramWithOrigins
    psSelfHostProdPreludeEnvironment parsed).mapError psCompilerPscv0ElabError)
  let environment := elaborated.result.environment
  let some constructor := psEnvironmentFindConstructor environment
      (psNameAppendStr (psRootName "M3EmptyRelation") "mk")
    | throw (IO.userError "missing logical empty relation constructor")
  ensure (constructor.numParams == 1 && constructor.numFields == 2 &&
      environment.classes.any (psNameEq (psRootName "M3EmptyRelation")))
    "empty runtime layout changed the actual logical class/constructor fields"
  for name in ["m3emptyproduce", "m3emptyforward", "m3emptychoose", "m3emptyconstant"] do
    match psEnvironmentFind environment (psRootName name) with
    | some (.definitionDecl _ _ type value) =>
      ensure (!psExprHasUnresolvedMeta type && !psExprHasUnresolvedMeta value &&
        (psExprFVarIds type).isEmpty && (psExprFVarIds value).isEmpty)
        ("ordinary dictionary has unresolved logical data: " ++ name)
    | _ => throw (IO.userError ("dictionary producer is not an ordinary checked definition: " ++ name))
  let prepared ← fromExcept ((psCompilerPrepareElaboratedWithOutput elaborated.result).mapError
    psCompilerPscv0Error)
  let ir : PsVerifiedIrModule ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError
    psCompilerPscv0Error)
  for name in ["M3EmptyRelation", "M3EmptyMarker"] do
    let some layout := ir.structures.find? (fun layout => layout.name == name)
      | throw (IO.userError ("missing nominal empty structure layout: " ++ name))
    ensure (layout.fields.isEmpty && layout.typeParameters.length == 1)
      ("empty structure lost its checked nominal generic layout: " ++ name)
  let some nonempty := ir.structures.find? (fun layout => layout.name == "M3ValueDictionary")
    | throw (IO.userError "missing nonempty control dictionary layout")
  match nonempty.fields with
  | [.mk _ (.primitive .nat)] => pure ()
  | _ => throw (IO.userError "nonempty control dictionary lost its retained Nat field")
  let producer ← requireDeclaration ir "m3emptyproduce"
  ensure (producer.typeParameters.length == 1 && producer.parameters.length == 1 &&
      isNamed "M3EmptyRelation" producer.resultType)
    "empty producer lost its generic nominal return or runtime Bool argument"
  match producer.parameters, producer.body with
  -- Bool source conditions retain their actual checked Decidable equality
  -- in raw IR; backend optimization has not simplified that guard here.
  | [parameter], .ifE (.intrinsic .boolEq [] [.var condition, .literal (.bool true)])
      (.record left [_] []) (.record right [_] []) =>
    ensure (parameter.name == condition && left == "M3EmptyRelation" && right == left)
      "empty producer changed its checked conditional construction"
  | _, _ => throw (IO.userError "empty producer no longer evaluates its runtime branch")
  let forward ← requireDeclaration ir "m3emptyforward"
  match forward.parameters, forward.body with
  | [parameter], .var returned =>
    ensure (parameter.name == returned && isNamed "M3EmptyRelation" parameter.type &&
      isNamed "M3EmptyRelation" forward.resultType)
      "empty forwarding function replaced the actual dictionary value"
  | _, _ => throw (IO.userError "empty forwarding function lost its ordinary value parameter")
  let choose ← requireDeclaration ir "m3emptychoose"
  ensure (isNamed "M3EmptyRelation" choose.resultType &&
    psErasureIrUsesNameWithFuel 4096 choose.body "m3emptyproduce" &&
    psErasureIrUsesNameWithFuel 4096 choose.body "m3emptyforward")
    "empty result replaced a producer/forwarding call with a guessed singleton"
  let constant ← requireDeclaration ir "m3emptyconstant"
  ensure (constant.parameters.isEmpty && isNamed "M3EmptyRelation" constant.resultType &&
    psErasureIrUsesNameWithFuel 4096 constant.body "m3emptyproduce")
    "closed empty dictionary lost its checked initializer"
  let consumer ← requireDeclaration ir "m3emptyconsume"
  match consumer.parameters with
  | [value, _] =>
    ensure (isNamed "M3EmptyRelation" value.type)
      "empty dictionary argument was reclassified as a proof slot"
  | _ => throw (IO.userError "empty dictionary call arity changed")
  let some inhabited := ir.structures.find? (fun layout => layout.name == "Inhabited")
    | throw (IO.userError "missing generic Inhabited control layout")
  ensure (inhabited.fields.length == 1 &&
    !(ir.declarations.any (fun declaration => declaration.name == "m3emptyproofdefault")))
    "nonempty generic dictionary specialization changed"
  for (name, expected) in [("M3EmptyRelation", false), ("M3EmptyMarker", true),
      ("M3ValueDictionary", true)] do
    let some (_, actual) := ir.foreignData.find? (fun entry => entry.1 == name)
      | throw (IO.userError ("missing checked foreign-layout evidence: " ++ name))
    ensure (actual == expected) ("empty layout weakened its foreign boundary: " ++ name)
  IO.println "PSCV0_M3_EMPTY_IR: PASS original logical fields, nominal empty records, ordinary producer/forwarder/initializer calls, retained argument slots, generic nonempty specialization and foreign evidence"

def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "empty dictionary checks require the pinned Lean"
  checkConstruction
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "emptydict.ps") source
  let request : PsV7Native.Request := {
    source, sourceName := "m3-empty-dictionaries.ps", outputStem := "emptydict"
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent]
    exports := .selected (outputCases.map Prod.fst) }
  let invalidProof := relationSource ++
    "function m3emptybad(A: Type): M3EmptyRelation A := M3EmptyRelation.mk((fun (a: A) => fun (b: A) => False), (fun (a: A) => True.intro))\n"
  let requests : Array PsV7Native.Request := #[request,
    { source := invalidProof },
    { source := relationSource, sourceName := "m3-empty-foreign.ps"
      targets := [.wasmComponent], exports := .selected ["m3emptyforeign"] }]
  let batch : PsV7Native.Batch ← match ← PsV7Native.runBatch requests with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  let some first := batch.results[0]? | throw (IO.userError "missing empty dictionary result")
  let result ← match first with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (result.artifacts.length == 5) "empty dictionaries did not emit every target"
  for artifact in result.artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  for (index, phase, expected) in [(1, "elaborate", "PSCV0-TYPE-MISMATCH"),
      (2, "ir/emit", "PSCV0-WIT-INVARIANT: dependent/proof-bearing data requires an explicit validating adapter")] do
    let some outcome := batch.results[index]?
      | throw (IO.userError "missing empty dictionary refusal")
    match outcome with
    | .ok _ => throw (IO.userError ("empty dictionary unexpectedly crossed " ++ phase))
    | .error error =>
      ensure (error.phase == phase && (error.message.splitOn expected).length > 1)
        ("empty dictionary failed at wrong boundary: " ++ error.phase ++ ": " ++ error.message)
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj (("flag", Lean.toJson flag) ::
      outputCases.map (fun (name, oracle) =>
        (name, Lean.toJson (toString (oracle flag).toNat))))
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_EMPTY_DICTIONARIES: PASS independent native/source dictionaries, checked logical proof refusal, nominal zero-field runtime calls, nonempty controls and validating-adapter refusal; five-target parity follows"
