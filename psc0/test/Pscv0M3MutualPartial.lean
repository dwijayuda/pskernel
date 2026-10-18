import Ps.Host.NativeV7
import PsKernelLean.Admission
import Lean.Util.CollectAxioms

namespace M3MutualPartialOracle

def applyPeer (f : Nat → Nat) (n : Nat) : Nat := f n

-- Pinned MutualDef checks original main modifiers before it can split SCCs.
-- Main.anyPartial is downstream of this mandatory source compatibility gate.
/-- error: invalid mutually recursive definitions, cannot mix partial and non-partial definitions -/
#guard_msgs (error, drop warning, substring := true) in
mutual
  partial def mixedFirst (n : Nat) : Nat := mixedSecond n
  def mixedSecond (n : Nat) : Nat := mixedFirst n
end

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

run_cmd do
  let environment ← Lean.getEnv
  for name in [``left, ``right] do
    match environment.find? name with
    | some (.opaqueInfo _) => pure ()
    | _ => throwError "native compatible partial group member is not opaque: {name}"

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

-- Singleton syntax must retain a universe used only by the actual recursive body.
partial def universeSingleton (n : Nat) : Nat :=
  match n with
  | 0 => 17
  | k + 1 => eraseType (PUnit : Type u) (universeSingleton k + 1)

example : Nat → Nat := universeSingleton.{u}

run_cmd do
  let environment ← Lean.getEnv
  match environment.find? ``universeSingleton with
  | some (.opaqueInfo info) =>
    unless info.levelParams == [`u] do
      throwError "native singleton P0 lost its body-only universe"
  | _ => throwError "native recursive singleton P0 is not opaque"

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

-- Ordinary P0 generic runtime oracle. Both entries retain a common runtime
-- dictionary and seed; alternating entry/parity distinguishes the actual
-- bodies from their separately inhabited logical opaque values.
section
variable {A : Type u} [dictionary : Inhabited A] (seed : A)

mutual
  partial def p0Left (n : Nat) : A :=
    match n with
    | 0 => seed
    | k + 1 => p0Right k
  partial def p0Right (n : Nat) : A :=
    match n with
    | 0 => default
    | k + 1 => p0Left k
end
end

example : ∀ (A : Type u), Inhabited A → A → Nat → A := @p0Left
example : ∀ (A : Type u), Inhabited A → A → Nat → A := @p0Right

def p0NatOutput (flag : Bool) : UInt64 :=
  let dictionary : Inhabited Nat := ⟨if flag then 23 else 29⟩
  let seed : Nat := if flag then 41 else 47
  let n : Nat := if flag then 2 else 3
  let left := @p0Left Nat dictionary seed n
  let right := @p0Right Nat dictionary seed n
  UInt64.ofNat (100 * left + right)

def p0BoolOutput (flag : Bool) : UInt64 :=
  let dictionary : Inhabited Bool := ⟨true⟩
  let n : Nat := if flag then 2 else 3
  let left := @p0Left Bool dictionary false n
  let right := @p0Right Bool dictionary false n
  UInt64.ofNat ((if left then 10 else 20) + (if right then 1 else 2))

run_cmd do
  let environment ← Lean.getEnv
  for name in [``p0Left, ``p0Right] do
    match environment.find? name with
    | some (.opaqueInfo _) => pure ()
    | _ => throwError "native generic P0 member is not logically opaque: {name}"
  for name in [``p0Left, ``p0Right, ``p0NatOutput, ``p0BoolOutput] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun name => name == ``propext || name == ``Quot.sound) do
      throwError "generic P0 oracle uses an unapproved assumption: {name}: {axioms}"
  Lean.logInfo "PSCV0_M3_P0_GENERIC_NATIVE: PASS actual generic opaque entries, common instance/seed telescope and allowed native logical assumption closure"

-- The producer supplies executable results but no Inhabited A dictionary.
-- Only the independent Nonempty instance can inhabit the logical opaque.
partial def p0Nonempty {A : Type u} [evidence : Nonempty A]
    (producer : Nat → A) (n : Nat) : A :=
  match n with
  | 0 => producer 17
  | k + 1 => p0Nonempty (A := A) (evidence := evidence) producer k

example : ∀ (A : Type u), Nonempty A → (Nat → A) → Nat → A := @p0Nonempty

def p0NonemptyOutput (flag : Bool) : UInt64 :=
  let producer := fun (value : Nat) => value + (if flag then 41 else 53)
  UInt64.ofNat (@p0Nonempty Nat (Nonempty.intro 997) producer (if flag then 2 else 3))

run_cmd do
  let environment ← Lean.getEnv
  match environment.find? ``p0Nonempty with
  | some (.opaqueInfo _) => pure ()
  | _ => throwError "native Nonempty-only P0 entry is not logically opaque"
  for name in [``p0Nonempty, ``p0NonemptyOutput] do
    let axioms ← Lean.collectAxioms name
    unless axioms.contains ``Classical.choice &&
        axioms.all (fun name =>
          name == ``propext || name == ``Quot.sound || name == ``Classical.choice) do
      throwError "Nonempty-only P0 oracle lost its exact approved choice closure: {name}: {axioms}"
  Lean.logInfo "PSCV0_M3_P0_NONEMPTY_NATIVE: PASS opaque producer entry and approved Classical.choice closure"

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

private def singletonUniverseLeanSource : String :=
  "universe u v\n" ++
  "def eraseType (A : Type u) (n : Nat) : Nat := n\n" ++
  "partial def universeSingleton (n : Nat) : Nat :=\n" ++
  "  match n with\n" ++
  "  | 0 => 17\n" ++
  "  | k + 1 => eraseType (PUnit : Type u) (universeSingleton k + 1)\n"

private def singletonUniverseSource : String :=
  "universe u v\n" ++
  "function eraseType(A: Type u, n: Nat): Nat := n\n" ++
  "partial function universeSingleton(n: Nat): Nat := match n with {\n" ++
  "  | 0 => 17\n" ++
  "  | k + 1 => eraseType((PUnit : Type u), universeSingleton(k) + 1) }\n"

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
  let mut singletonPair : Option (PsExpr × PsExpr × PsExpr) := none
  for (kind, text) in [(PsCompilerSourceKind.lean, singletonUniverseLeanSource),
      (.proofScript, singletonUniverseSource)] do
    let parsed ← fromExcept (psCompilerParsePscv0 text kind)
    let singleton ← fromExcept
      ((psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed "").mapError
        psCompilerPscv0ElabError)
    let name := psRootName "universeSingleton"
    let some (.opaqueDecl logical levels type witness) :=
        psEnvironmentFind singleton.result.environment name
      | throw (IO.userError "singleton P0 lost its independently inhabited opaque")
    let some (.partialDecl implementation bodyLevels bodyType body) :=
        psEnvironmentFind singleton.result.environment (PsName.num name 0)
      | throw (IO.userError "singleton P0 lost its actual private body")
    ensure (psNameEq logical name && psNameEq implementation (PsName.num name 0) &&
      psElabMutualLevelNamesEqual levels [psRootName "u"] &&
      psElabMutualLevelNamesEqual bodyLevels levels && psExprAlphaEq type bodyType &&
      !psExprAlphaEq witness body && !psExprHasConst name witness &&
      psExprHasConst name body &&
      [type, witness, body].all (fun term =>
        (psExprFVarIds term).isEmpty && !psExprHasUnresolvedMeta term) &&
      (psEnvironmentFind singleton.result.environment (psNameAppendStr name "eq_def")).isNone)
      "singleton P0 changed body-universe closure, opacity or exact body ownership"
    match singletonPair with
    | none => singletonPair := some (type, witness, body)
    | some (originalType, originalWitness, originalBody) =>
      ensure (psExprAlphaEq type originalType && psExprAlphaEq witness originalWitness &&
        psExprAlphaEq body originalBody)
        "paired singleton P0 source kinds produced different checked identities"
  for text in [mixedSource,
      "mutual\npartial function first(n: Nat): Nat := n\nfunction second(n: Nat): Nat := n\nend\n",
      "mutual\npartial function first(n: Nat): Nat := second(n)\nfunction second(n: Nat): Nat := true\nend\n"] do
    let parsed ← parse text
    match psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed with
    | .error error =>
      ensure (((psCompilerPscv0ElabError error).splitOn
        "PSCV0-MUTUAL-STRATEGY: cannot mix partial and non-partial original main definitions").length > 1)
        "mixed main modifiers reached body checking or SCC dispatch before source compatibility"
    | .ok _ => throw (IO.userError "incompatible original main modifiers were accepted")
  -- Reuse the same names in a valid all-partial source block. The prior
  -- rejected blocks publish no logical identity or executable body.
  let repaired ← elaborate (mixedSource.replace "\nfunction second" "\npartial function second")
  ensure (repaired.result.declarations.length == 4 && repaired.origins.length == 2)
    "compatible partial group lost one logical/body owner after a rejected source block"
  for (name, peer) in [("first", "second"), ("second", "first")] do
    let name := psRootName name
    let peer := psRootName peer
    let some (.opaqueDecl logical logicalLevels logicalType witness) :=
        psEnvironmentFind repaired.result.environment name
      | throw (IO.userError "compatible partial group left a public member transparent")
    let some (.partialDecl implementation levels type value) :=
        psEnvironmentFind repaired.result.environment (PsName.num name 0)
      | throw (IO.userError "compatible partial group discarded the member's actual checked body")
    ensure (psNameEq logical name && psNameEq implementation (PsName.num name 0) &&
      psElabMutualLevelNamesEqual logicalLevels levels && psExprAlphaEq logicalType type &&
      !psExprAlphaEq witness value && psExprHasConst peer value &&
      (psExprFVarIds value).isEmpty && !psExprHasUnresolvedMeta value &&
      (psEnvironmentFind repaired.result.environment (psNameAppendStr name "eq_def")).isNone)
      "effective partial member changed opacity, exact body, peer closure or equation ownership"
    ensure (repaired.origins.any (fun origin => origin.members.length == 2 &&
      origin.members.any (fun member => psNameEq member.name name) &&
      origin.members.any (fun member => psNameEq member.name implementation)))
      "compatible partial group lost per-source logical/body provenance"
  let duplicate ← parse "mutual\npartial function same(n: Nat): Nat := n\npartial function same(n: Nat): Nat := n\nend\n"
  match psElabProgramWithOrigins psSelfHostProdPreludeEnvironment duplicate with
  | .error (.duplicateDeclaration name) =>
    ensure (psNameEq name (psRootName "same")) "duplicate mutual diagnostic lost its owner"
  | _ => throw (IO.userError "duplicate mutual headers were not refused atomically")
  IO.println "PSCV0_M3_MUTUAL_CONSTRUCTION: PASS atomic command/member origins, distinct inhabited opaque/body identities, native original-main modifier refusals, all-kind block captures, bare peers, shadowing, private aliases and common universe closure"
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
    { label := "singleton-body-universe-native-input", request := {
        sourceKind := .lean, source := singletonUniverseLeanSource } },
    { label := "singleton-body-universe-proofscript-input", request := {
        source := singletonUniverseSource } },
    { label := "singleton-no-defining-equation-native-input", request := {
        sourceKind := .lean
        source := singletonUniverseLeanSource ++
          "theorem singletonNotDefinition : universeSingleton 0 = 17 := by rfl\n" }
      failure := some ("elaborate", "PSCV0-PROOF:") },
    { label := "singleton-no-defining-equation-proofscript-input", request := {
        source := singletonUniverseSource ++
          "theorem singletonNotDefinition: universeSingleton(0) = 17 := by { rfl }\n" }
      failure := some ("elaborate", "PSCV0-PROOF:") },
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
    { label := "mixed-partial-main-refused", request := { source := mixedSource }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-MUTUAL-STRATEGY:") },
    { label := "partial-registration-refused", request := {
        source := "mutual\n@[default_instance] partial function first(n: Nat): Nat := n\nend\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-TERM-02-HEAD:") },
    -- The exact former policy refusal is now a kernel-checked logical-only
    -- positive in Pscv0M3PartialFixpoint; retain an actual semantic negative.
    { label := "p1-nonmonotone-refused", request := {
        source := "mutual\nfunction first(n: Nat): Nat := first(n) + 1\npartial_fixpoint\nend\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-FIXPOINT-MONOTONICITY:") },
    { label := "partial-wf-clique-refused", request := {
        source := "mutual\npartial function first(n: Nat): Nat := second(n)\nfunction second(n: Nat): Nat := first(n)\ntermination_by n\nend\n" }
      failure := some ("elaborate", "PSCV0-DATA: PSCV0-MUTUAL-STRATEGY:") },
    { label := "private-import-refused", request := {
        project with
        source := "import MutualLib\nfunction forbidden(n: Nat): Nat := MutualLib.right(n, n)\n"
        targets := [] }
      failure := some ("module", "PSCV0-SCOPE: unknown name MutualLib.right") },
    { label := "closed-verified-refused", request := { project with assurance := .closedVerified }
      failure := some ("assurance", "PSCV0-ASSURANCE-DOWNGRADE:") },
    { label := "boundary-qualified-verified-refused", request := { project with assurance := .boundaryQualifiedVerified }
      failure := some ("assurance", "PSCV0-ASSURANCE-DOWNGRADE:") } ]

-- This nested suite preserves the original imported mutual fixture, its five
-- exports and every refusal. It adds two concrete runtime specializations of
-- one generic P0 pair, with nonstandard dictionaries and both entry directions.
private def p0GenericSource : String :=
  "universe u\nsection\n" ++
  "variable {A: Type u} [dictionary: Inhabited A] (seed: A)\n" ++
  "mutual\n" ++
  "  partial function p0genericLeft(n: Nat): A := match n with { | 0 => seed | k + 1 => p0genericRight(k) }\n" ++
  "  partial function p0genericRight(n: Nat): A := match n with { | 0 => Inhabited.default | k + 1 => p0genericLeft(k) }\n" ++
  "end\nend\n" ++
  "function m3p0genericnat(flag: Bool): UInt64 := {\n" ++
  " let dictionary: Inhabited(Nat) := Inhabited.mk(if (flag) { 23 } else { 29 })\n" ++
  " let seed: Nat := if (flag) { 41 } else { 47 }\n" ++
  " let n: Nat := if (flag) { 2 } else { 3 }\n" ++
  " let left: Nat := p0genericLeft(seed, n, A := Nat, dictionary := dictionary)\n" ++
  " let right: Nat := p0genericRight(seed, n, A := Nat, dictionary := dictionary)\n" ++
  " UInt64.ofNat(100 * left + right) }\n" ++
  "function m3p0genericbool(flag: Bool): UInt64 := {\n" ++
  " let dictionary: Inhabited(Bool) := Inhabited.mk(true)\n" ++
  " let n: Nat := if (flag) { 2 } else { 3 }\n" ++
  " let left: Bool := p0genericLeft(false, n, A := Bool, dictionary := dictionary)\n" ++
  " let right: Bool := p0genericRight(false, n, A := Bool, dictionary := dictionary)\n" ++
  " UInt64.ofNat((if (left) { 10 } else { 20 }) + (if (right) { 1 } else { 2 })) }\n"

private def p0GenericExports : List (String × (Bool → UInt64)) :=
  [("m3p0genericnat", M3MutualPartialOracle.p0NatOutput),
   ("m3p0genericbool", M3MutualPartialOracle.p0BoolOutput)]

private def p0GenericCoreAny (predicate : PsExpr → Bool) (value : PsExpr) : Bool :=
  predicate value ||
    match value with
    | .app fn arg => p0GenericCoreAny predicate fn || p0GenericCoreAny predicate arg
    | .lam _ type body _ | .forallE _ type body _ =>
      p0GenericCoreAny predicate type || p0GenericCoreAny predicate body
    | .letE _ type assigned body =>
      p0GenericCoreAny predicate type || p0GenericCoreAny predicate assigned ||
        p0GenericCoreAny predicate body
    | .proj _ _ value => p0GenericCoreAny predicate value
    | _ => false

private def checkP0GenericConstruction : IO Unit := do
  let compiled ← elaborate p0GenericSource
  let environment := compiled.result.environment
  ensure ((compiled.result.declarations.filter (fun declaration =>
      match declaration with | .partialDecl .. => true | _ => false)).length == 2)
    "generic P0 pair lost one actual private body"
  for (name, peer) in [("p0genericLeft", "p0genericRight"), ("p0genericRight", "p0genericLeft")] do
    let name := psRootName name
    let peer := psRootName peer
    let some (.opaqueDecl logical logicalLevels logicalType witness) :=
        psEnvironmentFind environment name
      | throw (IO.userError "generic P0 member lost its logical opacity")
    let some (.partialDecl implementation levels type value) :=
        psEnvironmentFind environment (PsName.num name 0)
      | throw (IO.userError "generic P0 member lost its actual checked private body")
    ensure (psNameEq logical name && psNameEq implementation (PsName.num name 0) &&
      psElabMutualLevelNamesEqual logicalLevels levels &&
      psElabMutualLevelNamesEqual levels [psRootName "u"] &&
      psExprAlphaEq logicalType type && !psExprAlphaEq witness value &&
      binderNames type == ["A", "dictionary", "seed", "n"] &&
      !psExprHasUnresolvedMeta type && !psExprHasUnresolvedMeta value &&
      (psExprFVarIds type).isEmpty && (psExprFVarIds value).isEmpty &&
      compiled.privateNames.any (psNameEq implementation) &&
      (psEnvironmentFind environment (psNameAppendStr name "eq_def")).isNone)
      "generic P0 logical/body identity, universe, closure, ordered captures or equation policy changed"
    let opened ← fromExcept ((psElabPreDefinitionOpen 4
      (psElabContextEmpty environment levels) type value).mapError psCompilerPscv0ElabError)
    let [typeParameter, dictionary, seed, n] := opened.bindersRev.reverse
      | throw (IO.userError "generic P0 opening lost its four original binders")
    ensure (psBinderInfoEq typeParameter.binder .implicit &&
      psBinderInfoEq dictionary.binder .instanceImplicit &&
      psBinderInfoEq seed.binder .explicit && psBinderInfoEq n.binder .explicit &&
      psExprAlphaEq seed.type (.fvar typeParameter.id) &&
      psExprAlphaEq opened.type (.fvar typeParameter.id))
      "generic P0 opened result or runtime seed differs from its actual type parameter"
    let preservedPeer := p0GenericCoreAny (fun term =>
      let view := psExprAppView term
      match view.head, view.args with
      | .constE actual _, [.fvar actualType, .fvar actualDictionary, .fvar actualSeed, _] =>
        psNameEq actual peer && actualType == typeParameter.id &&
          actualDictionary == dictionary.id && actualSeed == seed.id
      | _, _ => false) opened.value
    ensure preservedPeer
      "generic P0 recursive peer call changed the actual type/dictionary/seed capture prefix"
    if psNameEq name (psRootName "p0genericRight") then
      let actualDefault := p0GenericCoreAny (fun term =>
        let view := psExprAppView term
        match view.head, view.args with
        | .constE actual _, [.fvar actualType, .fvar actualDictionary] =>
          psNameEq actual (psNameAppendStr (psRootName "Inhabited") "default") &&
            actualType == typeParameter.id && actualDictionary == dictionary.id
        | _, _ =>
          match term with
          | .proj actual 0 (.fvar actualDictionary) =>
            psNameEq actual (psRootName "Inhabited") && actualDictionary == dictionary.id
          | _ => false) opened.value
      ensure actualDefault
        "generic P0 default bypassed the actual retained Inhabited dictionary"
    ensure (compiled.origins.any (fun origin => origin.members.length == 2 &&
      origin.members.any (fun member => psNameEq member.name name) &&
      origin.members.any (fun member => psNameEq member.name implementation)))
      "generic P0 source member lost its exact logical/private-body ownership"
  IO.println "PSCV0_M3_P0_GENERIC_CONSTRUCTION: PASS two actual opaque/private-body pairs, complete generic headers, exact peer capture forwarding, retained dictionary projection and no logical equations"

private def checkP0GenericRuntime (directory : System.FilePath) : IO Unit := do
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "p0generic.ps") p0GenericSource
  ensure (M3MutualPartialOracle.p0NatOutput false == 2947 &&
    M3MutualPartialOracle.p0NatOutput true == 4123 &&
    M3MutualPartialOracle.p0BoolOutput false == 12 &&
    M3MutualPartialOracle.p0BoolOutput true == 21)
    "independent native P0 parity or supplied-dictionary observations changed"
  checkP0GenericConstruction
  let ordinary : PsV7Native.Request := {
    source := p0GenericSource, sourceName := "p0generic.ps", outputStem := "p0generic"
    assurance := .ordinaryChecked
    exports := .selected (p0GenericExports.map Prod.fst)
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] }
  let requests := #[ordinary,
    { ordinary with assurance := .closedVerified },
    { ordinary with assurance := .boundaryQualifiedVerified }]
  let batch : PsV7Native.Batch ← match ← PsV7Native.runBatch requests with
    | .ok batch => pure batch
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (batch.results.size == requests.size) "generic P0 batch omitted an assurance result"
  let some first := (batch.results[0]? : Option (Except PsV7Native.Diagnostic PsV7Native.Result))
    | throw (IO.userError "generic P0 ordinary result is missing")
  let result : PsV7Native.Result ← match first with
    | .ok result => pure result
    | .error error => throw (IO.userError ("generic P0 ordinary request failed at " ++
        error.phase ++ ": " ++ error.message))
  ensure (PsV7Native.assuranceLabel result.assurance == "ordinary-checked" &&
    result.declarationCount > 0 && result.artifacts.map (·.target) == ordinary.targets &&
    result.artifacts.all (fun artifact => !artifact.files.isEmpty))
    "generic P0 changed assurance or omitted one requested target bundle"
  for index in ([1, 2] : List Nat) do
    match (batch.results[index]? : Option (Except PsV7Native.Diagnostic PsV7Native.Result)) with
    | some (.error error) =>
      ensure (error.phase == "assurance" &&
        error.message.startsWith "PSCV0-ASSURANCE-DOWNGRADE:")
        ("generic P0 verified request failed at the wrong boundary: " ++
          error.phase ++ ": " ++ error.message)
    | _ => throw (IO.userError "generic P0 verified request acquired an ordinary fallback or artifacts")
  for artifact in result.artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj (("flag", Lean.toJson flag) ::
      p0GenericExports.map (fun (name, oracle) => (name, Lean.toJson (toString (oracle flag).toNat))))
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_P0_GENERIC: PASS native Nat/Bool parity oracles, fresh official-kernel ordinary five-target emission and both exact verified-assurance refusals; 20 runtime comparisons follow"

private def p0NonemptySource : String :=
  "universe u\n" ++
  "partial function p0nonempty{A: Type u}[evidence: Nonempty(A)](producer: Nat -> A, n: Nat): A := match n with { | 0 => producer(17) | k + 1 => p0nonempty(producer, k, A := A, evidence := evidence) }\n" ++
  "function p0producerTrue(n: Nat): Nat := n + 41\n" ++
  "function p0producerFalse(n: Nat): Nat := n + 53\n" ++
  "function m3p0nonempty(flag: Bool): UInt64 := {\n" ++
  " let producer: Nat -> Nat := if (flag) { p0producerTrue } else { p0producerFalse }\n" ++
  " let evidence: Nonempty(Nat) := Nonempty.intro(997)\n" ++
  " let n: Nat := if (flag) { 2 } else { 3 }\n" ++
  " UInt64.ofNat(p0nonempty(producer, n, A := Nat, evidence := evidence)) }\n"

private def checkClassicalFoundation : IO Unit := do
  let prior := psSelfHostProdPreClassicalPreludeEnvironment
  let environment := psSelfHostProdPreludeEnvironment
  let duplicates := psStandardClassicalDeclarations.filter fun declaration =>
    psEnvironmentContains prior (psDeclarationName declaration)
  for declaration in psStandardClassicalExpectedDeclarations do
    let name := psDeclarationName declaration
    IO.println ("PSCV0_M3_CLASSICAL_BASE: " ++ psNameToString name ++
      " present=" ++ toString (psEnvironmentContains prior name))
  ensure (psStandardClassicalPrerequisiteDeclarations.length == 3 &&
    psStandardClassicalDeclarations.length == 2 &&
    psStandardClassicalPrerequisiteDeclarations.all (fun declaration =>
      psEnvironmentContains prior (psDeclarationName declaration)))
    "Classical asset lost its three existing Nonempty prerequisites or two new declarations"
  for declaration in psStandardClassicalPrerequisiteDeclarations do
    fromExcept (psStandardAuditDeclaration prior declaration)
  ensure duplicates.isEmpty
    ("Classical asset duplicates declarations in its frozen base: " ++
      String.intercalate ", " (duplicates.map (fun declaration =>
        psNameToString (psDeclarationName declaration))))
  fromExcept (psStandardClassicalAudit environment)
  let nonemptyName := psRootName "Nonempty"
  ensure ((environment.classes.filter (psNameEq nonemptyName)).length == 1 &&
    (environment.classParameters.filter (fun entry => psNameEq entry.fst nonemptyName)).length == 1)
    "Nonempty class metadata was duplicated"
  let choiceNames := [coreName ["Classical", "choice"], coreName ["Classical", "ofNonempty"]]
  ensure (!(psSelfHostRuntimePreludeDeclarationsWithProd.any fun declaration =>
    choiceNames.any (psNameEq (psDeclarationName declaration))))
    "logical choice acquired an executable prelude entry"
  IO.println "PSCV0_M3_CLASSICAL_FOUNDATION: PASS three unchanged Nonempty prerequisites, two new exact classical declarations, unique Nonempty class and no choice runtime entry"

private def checkP0NonemptyConstruction : IO Unit := do
  let compiled ← elaborate p0NonemptySource
  let environment := compiled.result.environment
  let name := psRootName "p0nonempty"
  let some (.opaqueDecl logical logicalLevels logicalType witness) :=
      psEnvironmentFind environment name
    | throw (IO.userError "Nonempty-only P0 lost its logical opaque")
  let some (.partialDecl implementation levels type value) :=
      psEnvironmentFind environment (PsName.num name 0)
    | throw (IO.userError "Nonempty-only P0 lost its actual private body")
  let choice := coreName ["Classical", "choice"]
  let ofNonempty := coreName ["Classical", "ofNonempty"]
  ensure (psNameEq logical name && psNameEq implementation (PsName.num name 0) &&
    psElabMutualLevelNamesEqual logicalLevels levels &&
    psElabMutualLevelNamesEqual levels [psRootName "u"] &&
    psExprAlphaEq logicalType type && binderNames type == ["A", "evidence", "producer", "n"] &&
    !psExprAlphaEq witness value && psExprHasConst ofNonempty witness &&
    !psExprHasConst choice value && !psExprHasConst ofNonempty value &&
    !psExprHasConst (psRootName "Inhabited") type &&
    (psExprFVarIds type).isEmpty && (psExprFVarIds value).isEmpty &&
    (psExprFVarIds witness).isEmpty && !psExprHasUnresolvedMeta type &&
    !psExprHasUnresolvedMeta value && !psExprHasUnresolvedMeta witness &&
    compiled.privateNames.any (psNameEq implementation) &&
    (psEnvironmentFind environment (psNameAppendStr name "eq_def")).isNone)
    "Nonempty-only P0 changed its telescope, logical choice, actual body, closure or equation policy"
  let opened ← fromExcept ((psElabPreDefinitionOpen 4
    (psElabContextEmpty environment levels) type witness).mapError psCompilerPscv0ElabError)
  let [typeParameter, evidence, producer, n] := opened.bindersRev.reverse
    | throw (IO.userError "Nonempty-only P0 opening lost its four own binders")
  ensure (psBinderInfoEq typeParameter.binder .implicit &&
    psBinderInfoEq evidence.binder .instanceImplicit &&
    psBinderInfoEq producer.binder .explicit && psBinderInfoEq n.binder .explicit &&
    psExprAlphaEq opened.type (.fvar typeParameter.id))
    "Nonempty-only P0 changed an original binder kind or its generic result"
  let view := psExprAppView opened.value
  match view.head, view.args with
  | .constE actual _, [.fvar actualType, .fvar actualEvidence] =>
    ensure (psNameEq actual ofNonempty && actualType == typeParameter.id &&
      actualEvidence == evidence.id)
      "logical choice bypassed the retained Nonempty evidence"
  | _, _ => throw (IO.userError "Nonempty-only witness is not the checked ofNonempty application")
  IO.println "PSCV0_M3_P0_NONEMPTY_CONSTRUCTION: PASS exact generic opaque/private-body pair, retained Nonempty evidence, separate choice witness and no logical equation"

private def checkP0NonemptyRuntime (directory : System.FilePath) : IO Unit := do
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "p0nonempty.ps") p0NonemptySource
  ensure (M3MutualPartialOracle.p0NonemptyOutput false == 70 &&
    M3MutualPartialOracle.p0NonemptyOutput true == 58)
    "independent native Nonempty-only producer observations changed"
  checkP0NonemptyConstruction
  let ordinary : PsV7Native.Request := {
    source := p0NonemptySource
    sourceName := "p0nonempty.ps"
    outputStem := "p0nonempty"
    assurance := .ordinaryChecked
    exports := .selected ["m3p0nonempty"]
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] }
  let requests := #[ordinary,
    { ordinary with assurance := .closedVerified },
    { ordinary with assurance := .boundaryQualifiedVerified }]
  let batch : PsV7Native.Batch ← match ← PsV7Native.runBatch requests with
    | .ok batch => pure batch
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (batch.results.size == requests.size) "Nonempty-only P0 batch omitted an assurance result"
  let some first := (batch.results[0]? : Option (Except PsV7Native.Diagnostic PsV7Native.Result))
    | throw (IO.userError "Nonempty-only P0 ordinary result is missing")
  let result : PsV7Native.Result ← match first with
    | .ok result => pure result
    | .error error => throw (IO.userError ("Nonempty-only P0 ordinary request failed at " ++
        error.phase ++ ": " ++ error.message))
  ensure (PsV7Native.assuranceLabel result.assurance == "ordinary-checked" &&
    result.declarationCount > 0 && result.artifacts.map (·.target) == ordinary.targets &&
    result.artifacts.all (fun artifact => !artifact.files.isEmpty))
    "Nonempty-only P0 changed assurance or omitted a requested target bundle"
  for index in ([1, 2] : List Nat) do
    match (batch.results[index]? : Option (Except PsV7Native.Diagnostic PsV7Native.Result)) with
    | some (.error error) =>
      ensure (error.phase == "assurance" &&
        error.message.startsWith "PSCV0-ASSURANCE-DOWNGRADE:")
        ("Nonempty-only P0 verified request failed at the wrong boundary: " ++
          error.phase ++ ": " ++ error.message)
    | _ => throw (IO.userError "Nonempty-only P0 verified request acquired ordinary fallback or artifacts")
  for artifact in result.artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj [
      ("flag", Lean.toJson flag),
      ("m3p0nonempty", Lean.toJson (toString (M3MutualPartialOracle.p0NonemptyOutput flag).toNat))]
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_P0_NONEMPTY: PASS native producer oracle, fresh official-kernel ordinary five-target emission and both exact verified-assurance refusals; 10 runtime comparisons follow"

end M3MutualPartial

open M3MutualPartial in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "mutual qualification requires the pinned Lean"
  checkClassicalFoundation
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
  checkP0GenericRuntime (directory / "p0-generic")
  checkP0NonemptyRuntime (directory / "p0-nonempty")
  IO.println "PSCV0_M3_MUTUAL: PASS fresh official-kernel P0 groups, native section/universe signatures, imported ordinary five-target emission and exact strategy/assurance refusals; native runtime parity follows"

