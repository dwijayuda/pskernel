import Ps.Host.NativeV7
import PsKernelLean.Admission

namespace M3MutualPartialOracle

def applyPeer (f : Nat → Nat) (n : Nat) : Nat := f n

-- Pinned Main applies the partial strategy to this complete recursive clique,
-- including the plain member. This divergent logical oracle is never run.
mutual
  partial def mixedFirst (n : Nat) : Nat := mixedSecond n
  def mixedSecond (n : Nat) : Nat := mixedFirst n
end

run_cmd do
  let environment ← Lean.getEnv
  for name in [``mixedFirst, ``mixedSecond] do
    match environment.find? name with
    | some (.opaqueInfo _) => pure ()
    | _ => throwError "native mixed partial clique member is not opaque: {name}"

mutual
  partial def left (bias n : Nat) : Nat :=
    match n with
    | 0 => bias + 3
    | k + 1 => right (bias + 2) k
  partial def right (bias n : Nat) : Nat :=
    match n with
    | 0 => bias + 7
    | k + 1 => left (bias + 1) k
end

section
variable (seed : Nat)
mutual
  partial def capturedLeft (n : Nat) : Nat :=
    match n with
    | 0 => seed
    | k + 1 => applyPeer capturedRight k
  partial def capturedRight (n : Nat) : Nat :=
    match n with
    | 0 => seed + 5
    | k + 1 => capturedLeft k + 2
  partial def disconnected (n : Nat) : Nat := n + 11
end
end

-- Pinned Lean closes the used section telescope over the whole source block,
-- before it splits disconnected functions into compilation components.
example : Nat → Nat → Nat := disconnected

mutual
  partial def nullLeft (_ : Unit) : Nat := nullRight ()
  partial def nullRight (_ : Unit) : Nat := 17
end

section
variable (bias : Nat)
mutual
  partial def shadowLeft (bias n : Nat) : Nat := shadowRight n
  partial def shadowRight (n : Nat) : Nat := bias + n
end
end

-- Both occurrences of bias belong to real, distinct entry binders.
example : Nat → Nat → Nat → Nat := shadowLeft

universe u v
section
variable {A : Type u} [dictionary : Inhabited A] (fallback : A) (bias : Nat)
mutual
  partial def genericKeep (n : Nat) : A :=
    match n with
    | 0 => default
    | k + 1 => genericRecover k
  partial def genericRecover (n : Nat) : A := by exact genericKeep n
  partial def genericValue (_ : Nat) : A := fallback
  partial def genericCount (n : Nat) : Nat := bias + n
end
end

example : ∀ (A : Type u), Inhabited A → A → Nat → Nat → A := @genericKeep
example : ∀ (A : Type u), Inhabited A → A → Nat → Nat → Nat := @genericCount

def eraseType (_ : Type u) (n : Nat) : Nat := n
mutual
  partial def universeLeft (n : Nat) : Nat := eraseType (PUnit : Type u) (universeRight n)
  partial def universeRight (n : Nat) : Nat := n
end
example : Nat → Nat := universeRight.{u}

def output (flag : Bool) : UInt64 :=
  UInt64.ofNat (left (if flag then 7 else 11) (if flag then 3 else 4))
def captureOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (capturedLeft (if flag then 7 else 13) (if flag then 3 else 4))
def disconnectedOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (disconnected (if flag then 7 else 13) (if flag then 3 else 4))
def nullaryOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (if flag then nullLeft () else nullLeft () + 1)
def shadowOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (shadowLeft (if flag then 7 else 11) (if flag then 100 else 200)
    (if flag then 3 else 4))

end M3MutualPartialOracle

namespace M3MutualPartial

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def source : String :=
  "namespace MutualLib\n" ++
  "function applyPeer(f: Nat -> Nat, n: Nat): Nat := f(n)\n" ++
  "mutual\n" ++
  "  partial function left(bias: Nat, n: Nat): Nat := match n with { | 0 => bias + 3 | k + 1 => right(bias + 2, k) }\n" ++
  "  private partial function right(bias: Nat, n: Nat): Nat := match n with { | 0 => bias + 7 | k + 1 => left(bias + 1, k) }\n" ++
  "end\n" ++
  "section\nvariable (seed: Nat)\n" ++
  "mutual\n" ++
  "  partial function capturedLeft(n: Nat): Nat := match n with { | 0 => seed | k + 1 => applyPeer(capturedRight, k) }\n" ++
  "  private partial function capturedRight(n: Nat): Nat := match n with { | 0 => seed + 5 | k + 1 => capturedLeft(k) + 2 }\n" ++
  "  partial function disconnected(n: Nat): Nat := n + 11\n" ++
  "end\nend\n" ++
  "mutual\n" ++
  "  partial function nullLeft(): Nat := nullRight()\n" ++
  "  private partial function nullRight(): Nat := 17\n" ++
  "end\n" ++
  "section\nvariable (bias: Nat)\n" ++
  "mutual\n" ++
  "  partial function shadowLeft(bias: Nat, n: Nat): Nat := shadowRight(n)\n" ++
  "  partial function shadowRight(n: Nat): Nat := bias + n\n" ++
  "end\nend\nend MutualLib\n"

private def wrappers : String :=
  "function m3mutualoutput(flag: Bool): UInt64 := UInt64.ofNat(MutualLib.left(if (flag) { 7 } else { 11 }, if (flag) { 3 } else { 4 }))\n" ++
  "function m3mutualcaptureoutput(flag: Bool): UInt64 := UInt64.ofNat(MutualLib.capturedLeft(if (flag) { 7 } else { 13 }, if (flag) { 3 } else { 4 }))\n" ++
  "function m3mutualdisconnectedoutput(flag: Bool): UInt64 := UInt64.ofNat(MutualLib.disconnected(if (flag) { 7 } else { 13 }, if (flag) { 3 } else { 4 }))\n" ++
  "function m3mutualnullaryoutput(flag: Bool): UInt64 := UInt64.ofNat(if (flag) { MutualLib.nullLeft() } else { MutualLib.nullLeft() + 1 })\n" ++
  "function m3mutualshadowoutput(flag: Bool): UInt64 := UInt64.ofNat(MutualLib.shadowLeft(if (flag) { 7 } else { 11 }, if (flag) { 100 } else { 200 }, if (flag) { 3 } else { 4 }))\n"

private def genericSource : String :=
  "universe u v\nsection\n" ++
  "variable {A: Type u} [dictionary: Inhabited A] (fallback: A) (bias: Nat)\n" ++
  "mutual\n" ++
  "  partial function genericKeep(n: Nat): A := match n with { | 0 => Inhabited.default | k + 1 => genericRecover(k) }\n" ++
  "  partial def genericRecover(n: Nat): A := by { exact genericKeep(n) }\n" ++
  "  partial function genericValue(n: Nat): A := fallback\n" ++
  "  partial function genericCount(n: Nat): Nat := bias + n\n" ++
  "end\nend\n"

private def universeSource : String :=
  "universe u v\n" ++
  "function eraseType(A: Type u, n: Nat): Nat := n\n" ++
  "mutual\n" ++
  "  partial function universeLeft(n: Nat): Nat := eraseType((PUnit : Type u), universeRight(n))\n" ++
  "  partial function universeRight(n: Nat): Nat := n\n" ++
  "end\n"

private def mixedSource : String :=
  "mutual\n" ++
  "partial function first(n: Nat): Nat := second(n)\n" ++
  "function second(n: Nat): Nat := first(n)\n" ++
  "end\n"

private def exports : List (String × (Bool → UInt64)) :=
  [("m3mutualoutput", M3MutualPartialOracle.output),
   ("m3mutualcaptureoutput", M3MutualPartialOracle.captureOutput),
   ("m3mutualdisconnectedoutput", M3MutualPartialOracle.disconnectedOutput),
   ("m3mutualnullaryoutput", M3MutualPartialOracle.nullaryOutput),
   ("m3mutualshadowoutput", M3MutualPartialOracle.shadowOutput)]

private def parse (text : String) : IO PsSyntaxProgram :=
  fromExcept (psPscv0ParseProgram text)

private def elaborate (text : String) (moduleIdentity : String := "") :
    IO PsElabModuleWithOriginsResult := do
  let parsed ← parse text
  fromExcept ((psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed moduleIdentity).mapError
    psCompilerPscv0ElabError)

private def binderNames : PsExpr → List String
  | .forallE name _ body _ => psNameToString name :: binderNames body
  | _ => []

private def coreName (segments : List String) : PsName :=
  psSyntaxNameAppendSegments segments .anonymous

private def sameSpan (left right : PsSourceSpan) : Bool :=
  left.start.byteOffset == right.start.byteOffset &&
  left.start.line == right.start.line && left.start.column == right.start.column &&
  left.stop.byteOffset == right.stop.byteOffset &&
  left.stop.line == right.stop.line && left.stop.column == right.stop.column

private def checkConstruction : IO (List PsElabBatchOrigin) := do
  let parsed ← parse (source ++ wrappers)
  let groups := parsed.commands.filterMap fun command =>
    match command with | .mutualDeclarations members span => some (members, span) | _ => none
  ensure (groups.length == 4 && groups.all (fun entry => !entry.fst.isEmpty))
    "mutual parser lost an atomic nonempty command"
  ensure (groups.any (fun entry => entry.fst.any (·.isPrivate)))
    "mutual parser discarded per-member privacy"
  match parsed.commands.getLast? with
  | some (.declaration (.definition name ..)) =>
    ensure (name.segments == ["m3mutualshadowoutput"])
      "mutual parser consumed the following ordinary command"
  | _ => throw (IO.userError "following ordinary command shape changed")
  let compiled ← elaborate source "MutualLib"
  ensure (compiled.origins.map (·.sourceIndex) == List.range 10)
    "mutual groups changed surrounding declaration source indices"
  ensure ((compiled.origins.filter (·.mutualGroup.isSome)).length == 9)
    "mutual source origin lost its enclosing group"
  let mut firstSourceIndex := 1
  for (members, span) in groups do
    for (member, memberIndex) in members.zipIdx do
      let some origin := compiled.origins.find? (fun origin =>
          origin.sourceIndex == firstSourceIndex + memberIndex)
        | throw (IO.userError "mutual member source origin missing")
      let some group := origin.mutualGroup
        | throw (IO.userError "mutual group span discarded after elaboration")
      ensure (group.firstSourceIndex == firstSourceIndex && group.memberIndex == memberIndex &&
        group.memberCount == members.length && sameSpan group.span span &&
        sameSpan origin.span (psElabOriginSource member.declaration).snd &&
        group.span.start.byteOffset < origin.span.start.byteOffset &&
        origin.span.stop.byteOffset < group.span.stop.byteOffset)
        "mutual command/member spans or ordered source ownership changed"
    firstSourceIndex := firstSourceIndex + members.length
  let partials := compiled.result.declarations.filterMap fun declaration =>
    match declaration with
    | .partialDecl implementation levels type value => some (implementation, levels, type, value)
    | _ => none
  ensure (partials.length == 9) "mutual source lost one of its nine implementation bodies"
  for (implementation, levels, type, value) in partials do
    let .num name 0 := implementation | throw (IO.userError "partial body identity is source-spellable")
    let some (.opaqueDecl logical logicalLevels logicalType witness) :=
        psEnvironmentFind compiled.result.environment name
      | throw (IO.userError "mutual body has no separately inhabited opaque owner")
    ensure (psNameEq name logical && psElabMutualLevelNamesEqual levels logicalLevels &&
      psExprAlphaEq type logicalType && !psExprAlphaEq witness value)
      "mutual logical identity, witness and actual typed body were conflated"
    ensure (compiled.privateNames.any (psNameEq implementation) &&
      (psExprFVarIds value).isEmpty)
      "mutual local alias escaped or implementation visibility changed"
    let owners := compiled.origins.filter (fun origin =>
      origin.members.any (fun member => psNameEq member.name implementation))
    ensure (owners.length == 1 && owners.all (fun origin =>
      origin.members.length == 2 && origin.members.any (fun member => psNameEq member.name name)))
      "mutual source member does not own its exact logical/body pair"
  let some (.opaqueDecl _ _ disconnectedType _) :=
      psEnvironmentFind compiled.result.environment (coreName ["MutualLib", "disconnected"])
    | throw (IO.userError "missing disconnected mutual member")
  ensure (binderNames disconnectedType == ["seed", "n"])
    "disconnected member lost pinned block-wide section capture"
  let some (.opaqueDecl _ _ shadowType _) :=
      psEnvironmentFind compiled.result.environment (coreName ["MutualLib", "shadowLeft"])
    | throw (IO.userError "missing shadowing mutual member")
  ensure (binderNames shadowType == ["bias", "bias", "n"])
    "section capture and shadowing source parameter lost distinct binders"
  ensure ((psEnvironmentFind compiled.result.environment (coreName ["MutualLib", "right"])).isNone)
    "private mutual member acquired a public project identity"
  let generic ← elaborate genericSource
  for name in ["genericKeep", "genericRecover", "genericValue", "genericCount"] do
    let some (.opaqueDecl _ levels type _) := psEnvironmentFind generic.result.environment (psRootName name)
      | throw (IO.userError "missing generic mutual logical identity")
    ensure (psElabMutualLevelNamesEqual levels [psRootName "u"] &&
      binderNames type == ["A", "dictionary", "fallback", "bias", "n"])
      "generic mutual member lost common ordered captures or retained unused universe v"
    match type with
    | .forallE _ _ (.forallE _ _ _ .instanceImplicit) .implicit => pure ()
    | _ => throw (IO.userError "mutual capture changed implicit or instance binder kind")
  let universeBatch ← elaborate universeSource
  for name in ["universeLeft", "universeRight"] do
    let some (.opaqueDecl _ levels _ _) := psEnvironmentFind universeBatch.result.environment (psRootName name)
      | throw (IO.userError "missing body-universe mutual identity")
    ensure (psElabMutualLevelNamesEqual levels [psRootName "u"])
      "body-only universe did not enter every final mutual signature"
  let mixed ← elaborate mixedSource
  ensure (mixed.result.declarations.length == 4 && mixed.origins.length == 2)
    "mixed partial clique lost one effective logical/body owner"
  for (name, peer) in [("first", "second"), ("second", "first")] do
    let name := psRootName name
    let peer := psRootName peer
    let some (.opaqueDecl logical logicalLevels logicalType witness) :=
        psEnvironmentFind mixed.result.environment name
      | throw (IO.userError "mixed partial clique left a public member transparent")
    let some (.partialDecl implementation levels type value) :=
        psEnvironmentFind mixed.result.environment (PsName.num name 0)
      | throw (IO.userError "mixed partial clique discarded the member's actual checked body")
    ensure (psNameEq logical name && psNameEq implementation (PsName.num name 0) &&
      psElabMutualLevelNamesEqual logicalLevels levels && psExprAlphaEq logicalType type &&
      !psExprAlphaEq witness value && psExprHasConst peer value &&
      (psExprFVarIds value).isEmpty && !psExprHasUnresolvedMeta value &&
      (psEnvironmentFind mixed.result.environment (psNameAppendStr name "eq_def")).isNone)
      "effective partial member changed opacity, exact body, peer closure or equation ownership"
    ensure (mixed.origins.any (fun origin => origin.members.length == 2 &&
      origin.members.any (fun member => psNameEq member.name name) &&
      origin.members.any (fun member => psNameEq member.name implementation)))
      "mixed partial clique lost per-source logical/body provenance"
  let duplicate ← parse "mutual\npartial function same(n: Nat): Nat := n\npartial function same(n: Nat): Nat := n\nend\n"
  match psElabProgramWithOrigins psSelfHostProdPreludeEnvironment duplicate with
  | .error (.duplicateDeclaration name) =>
    ensure (psNameEq name (psRootName "same")) "duplicate mutual diagnostic lost its owner"
  | _ => throw (IO.userError "duplicate mutual headers were not refused atomically")
  IO.println "PSCV0_M3_MUTUAL_CONSTRUCTION: PASS atomic command/member origins, distinct inhabited opaque/body identities, native mixed-clique effective opacity, all-kind block captures, bare peers, shadowing, private aliases and common universe closure"
  return compiled.origins

private def checkPublishedOrigins (expected : List PsElabBatchOrigin)
    (artifact : PsEmissionArtifact) : IO Unit := do
  for batch in expected do
    for member in batch.members do
      let name := psNameToString member.name
      let some (_, origin) := artifact.origins.find? (fun entry => entry.fst == name)
        | throw (IO.userError ("emission lost mutual library origin for " ++ name))
      ensure (origin.identity.file == "MutualLib.ps" && origin.sourceIndex == some batch.sourceIndex &&
        sameSpan origin.span batch.span)
        "emission changed a mutual member's own source index or declaration span"
      let json := PsV7Native.sourceOriginJson name origin
      match batch.mutualGroup, origin.mutualGroup with
      | none, none =>
        ensure (!(json.getObjVal? "mutualGroup").isOk && !(json.getObjVal? "sourceIndex").isOk)
          "ordinary origin serialization gained mutual-only metadata"
      | some expected, some group =>
        ensure (expected.firstSourceIndex == group.firstSourceIndex &&
          expected.memberIndex == group.memberIndex && expected.memberCount == group.memberCount &&
          sameSpan expected.span group.span)
          "emission changed complete mutual command provenance"
        let serialized ← fromExcept (json.getObjVal? "mutualGroup")
        let sourceIndex ← fromExcept (json.getObjValAs? Nat "sourceIndex")
        let firstSourceIndex ← fromExcept (serialized.getObjValAs? Nat "firstSourceIndex")
        let memberIndex ← fromExcept (serialized.getObjValAs? Nat "memberIndex")
        let memberCount ← fromExcept (serialized.getObjValAs? Nat "memberCount")
        let firstByte ← fromExcept (serialized.getObjValAs? Nat "sourceStartByte")
        let lastByte ← fromExcept (serialized.getObjValAs? Nat "sourceEndByte")
        ensure (sourceIndex == batch.sourceIndex && firstSourceIndex == expected.firstSourceIndex &&
          memberIndex == expected.memberIndex && memberCount == expected.memberCount &&
          firstByte == expected.span.start.byteOffset && lastByte == expected.span.stop.byteOffset)
          "published mutual origin JSON lost checked source ownership"
      | _, _ => throw (IO.userError "emission added or discarded mutual group ownership")

private def checkParserRefusals : IO Unit := do
  for (text, diagnostic) in [
      ("mutual\nend\n", "PSCV0-MUTUAL-EMPTY:"),
      ("mutual\npartial function left(n: Nat): Nat := n\n", "PSCV0-MUTUAL-END:"),
      ("mutual\nconst value: Nat := 0\nend\n", "PSCV0-MUTUAL-HEAD:"),
      ("mutual\nmutual\nend\nend\n", "PSCV0-MUTUAL-HEAD:"),
      ("mutual\npartial def left(): Nat := 0\nend\n", "PSCV0-PARSE: nonempty binder group")] do
    match psPscv0ParseProgram text with
    | .error message => ensure (message.startsWith diagnostic) ("unexpected mutual parse diagnostic: " ++ message)
    | .ok _ => throw (IO.userError "malformed mutual source was accepted")

structure Check where
  label : String
  request : PsV7Native.Request
  failure : Option (String × String) := none

private def checks : Array Check :=
  let library : PsPscv0ModuleSource := {
    name := "MutualLib", sourceName := "MutualLib.ps", source }
  let project : PsV7Native.Request := {
    source := "import MutualLib\n" ++ wrappers
    sourceName := "mutual.ps", outputStem := "mutual", moduleName := "Main"
    modules := [library], assurance := .ordinaryChecked
    exports := .selected (exports.map Prod.fst)
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] }
  let cycle := "mutual\npartial function first(n: Nat): Nat := second(n)\npartial function second(n: Nat): Nat := first(n)\nend\n"
  #[
    { label := "ordinary-imported-runtime", request := project },
    { label := "single-file-logical", request := {
        source := source ++ wrappers, sourceName := "single-mutual.ps" } },
    { label := "implicit-instance-and-proof-aliases", request := { source := genericSource } },
    { label := "body-universe-closure", request := { source := universeSource } },
    -- Compile/check divergence; no runtime runner invokes this pair.
    { label := "opaque-reflexivity", request := {
        source := cycle ++ "theorem reflexive(n: Nat): first(n) = first(n) := by { rfl }\n" } },
    { label := "no-defining-equation", request := {
        source := cycle ++ "theorem bad: first(0) = 0 := by { rfl }\n" }
      failure := some ("elaborate", "PSCV0-PROOF:") },
    { label := "no-peer-inhabitant", request := {
        source := "mutual\npartial function first(n: Nat): False := second(n)\npartial function second(n: Nat): False := first(n)\nend\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-TERM-02-INHABITED:") },
    { label := "later-body-type", request := {
        source := "mutual\npartial function first(n: Nat): Nat := second(n)\npartial function second(n: Nat): Nat := true\nend\n" }
      failure := some ("elaborate", "PSCV0-TYPE-MISMATCH") },
    { label := "total-strategy-refused", request := {
        source := "mutual\nfunction first(n: Nat): Nat := second(n)\nfunction second(n: Nat): Nat := first(n)\nend\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-MUTUAL-TOTAL:") },
    { label := "mixed-partial-clique", request := { source := mixedSource } },
    { label := "partial-registration-refused", request := {
        source := "mutual\n@[default_instance] partial function first(n: Nat): Nat := n\nend\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-TERM-02-HEAD:") },
    { label := "p1-assumption-refused", request := {
        source := "mutual\nfunction first(n: Nat): Nat := first(n)\npartial_fixpoint\nend\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-FIXPOINT-ASSUMPTION:") },
    { label := "partial-wf-clique-refused", request := {
        source := "mutual\npartial function first(n: Nat): Nat := second(n)\nfunction second(n: Nat): Nat := first(n)\ntermination_by n\nend\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-MUTUAL-WF:") },
    { label := "private-import-refused", request := {
        project with
        source := "import MutualLib\nfunction forbidden(n: Nat): Nat := MutualLib.right(n, n)\n"
        targets := [] }
      failure := some ("module", "PSCV0-SCOPE: unknown name MutualLib.right") },
    { label := "closed-verified-refused", request := { project with assurance := .closedVerified }
      failure := some ("assurance", "PSCV0-ASSURANCE-DOWNGRADE:") },
    { label := "boundary-qualified-verified-refused", request := { project with assurance := .boundaryQualifiedVerified }
      failure := some ("assurance", "PSCV0-ASSURANCE-DOWNGRADE:") } ]

end M3MutualPartial

open M3MutualPartial in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "mutual qualification requires the pinned Lean"
  checkParserRefusals
  let expectedOrigins ← checkConstruction
  let selected := checks
  let batch ← match ← PsV7Native.runBatch (selected.map (·.request)) with
    | .ok batch => pure batch
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (batch.results.size == selected.size) "mutual batch omitted an outcome"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "MutualLib.ps") source
  IO.FS.writeFile (directory / "Main.ps") ("import MutualLib\n" ++ wrappers)
  for index in [:selected.size] do
    let some check := selected[index]? | throw (IO.userError "mutual request index missing")
    let some result := batch.results[index]? | throw (IO.userError "mutual outcome index missing")
    match check.failure, result with
    | none, .ok result =>
      ensure (PsV7Native.assuranceLabel result.assurance == "ordinary-checked")
        "mutual request changed its assurance identity"
      ensure (result.artifacts.map (·.target) == check.request.targets &&
        result.artifacts.all (fun artifact => !artifact.files.isEmpty))
        "mutual request lost requested artifact bundles"
      if index == 0 then
        for artifact in result.artifacts do
          checkPublishedOrigins expectedOrigins artifact
          for file in artifact.files do
            match file.payload with
            | .text value => IO.FS.writeFile (directory / file.path) value
            | .binary value => IO.FS.writeBinFile (directory / file.path) value
    | some (phase, diagnostic), .error error =>
      ensure (error.phase == phase && error.message.startsWith diagnostic)
        ("wrong mutual refusal for " ++ check.label ++ ": " ++ error.phase ++ ": " ++ error.message)
    | none, .error error =>
      throw (IO.userError ("mutual expected acceptance for " ++ check.label ++ ": " ++ error.phase ++ ": " ++ error.message))
    | some _, .ok _ => throw (IO.userError ("mutual expected refusal for " ++ check.label))
    IO.println ("PSCV0_M3_MUTUAL_CHECK: PASS " ++ check.label)
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj (("flag", Lean.toJson flag) ::
      exports.map (fun (name, oracle) => (name, Lean.toJson (toString (oracle flag).toNat))))
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_MUTUAL: PASS fresh official-kernel P0 groups, native section/universe signatures, imported ordinary five-target emission and exact strategy/assurance refusals; native runtime parity follows"

