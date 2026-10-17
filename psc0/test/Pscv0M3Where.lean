import Ps.Host.NativeV7
import Lean.Util.CollectAxioms
import Pscv0M3ResultInference

-- Independent pinned Lean where declarations. The portable compiler consumes
-- separate ProofScript below, including its owned local `def` introducers.
namespace M3WhereOracle

def capture (bias n : Nat) : Nat := first n
where
  first (k : Nat) := second k
  second (k : Nat) (delta : Nat := bias) : Nat := k + delta

universe u
section
variable {A : Type u} [Inhabited A] (fallback : A) (h : True)
def pick (n : Nat) : A := loop n
where
  loop (k : Nat) : A :=
    match k with
    | 0 => default
    | j + 1 => alternate j
  alternate (k : Nat) : A :=
    match k with
    | 0 => fallback
    | j + 1 => let _witness : True := h; loop j
end

def shadow (helper n : Nat) : Nat := by exact helper n
where
  helper (helper : Nat) : Nat := by exact helper + 7

def cycle (bias n : Nat) : Nat :=
  match n with
  | 0 => bias
  | k + 1 => helper k
where
  helper (k : Nat) : Nat :=
    match k with
    | 0 => bias + 1
    | j + 1 => cycle (bias + 2) j

partial def operational (base n : Nat) : Nat := loop n
where
  bump (k : Nat) : Nat := k + base
  loop (k : Nat) : Nat :=
    if k == 0 then bump 1 else loop (k - 1) + 1

section
variable (ignored : Nat)

-- Original main modifiers are checked before the dependency graph is split.
/-- error: invalid mutually recursive definitions, cannot mix partial and non-partial definitions -/
#guard_msgs (error, drop warning, substring := true) in
mutual
  partial def invalidPartial (n : Nat) : Nat := invalidPartial n
  def invalidPlain (n : Nat) : Nat := n
end

mutual
  partial def disconnectedPartial (n : Nat) : Nat :=
    if n == 0 then 0 else disconnectedPartial (n - 1) + 1
  partial def disconnected (n : Nat) : Nat :=
    let _witness : True := proof n
    loop n + bump n
  where
    loop (k : Nat) : Nat :=
      match k with
      | 0 => 0
      | j + 1 => loop j + 1
    termination_by k + ignored
    decreasing_by exact ignored
    bump (k : Nat) : Nat := k + 1
    partial_fixpoint
    measured (k : Nat) : Nat := k
    termination_by k + ignored
    decreasing_by exact ignored
    fixedLoop (k : Nat) : Nat :=
      if k == 0 then 0 else fixedLoop (k - 1)
    partial_fixpoint
    proof (k : Nat) := True.intro
end

mutual
  def redundantWF (n : Nat) : Nat := n
  termination_by n + ignored
  def redundantP1 (n : Nat) : Nat := n
  partial_fixpoint
end

end

-- Unused hints are retained source, but do not add section parameters.
example : Nat → Nat := disconnected
example : Nat → Nat := disconnected.loop
example : Nat → Nat := disconnected.measured
example : Nat → Nat := redundantWF

def measured (bias n : Nat) : Nat := descend n + walk n
where
  finish (value : Nat) : Nat := value + bias
  descend (k : Nat) : Nat :=
    if h : 0 < k then finish (descend 0) else bias
  termination_by k
  decreasing_by exact h
  walk (k : Nat) : Nat :=
    match k with
    | 0 => bias
    | j + 1 => finish (walk (j - 1))
  termination_by k
  decreasing_by exact Nat.lt_succ_of_le (Nat.sub_le j 1)

-- Pinned MutualDef closes checked type/body dependencies before hints are
-- elaborated in PreDefinition.Main's empty local context. A hint alone
-- cannot introduce an enclosing section parameter into the lifted helper.
section
variable (bias : Nat)

/-- error: Unknown identifier `bias` -/
#guard_msgs (error, drop warning, substring := true) in
def measureOnly (n : Nat) : Nat := walk n
where
  walk (k : Nat) : Nat :=
    match k with
    | 0 => 0
    | j + 1 => walk j + 1
  termination_by k + bias

end

section
variable (bound : ∀ k : Nat, k < Nat.succ k)

/-- error: Unknown identifier `bound` -/
#guard_msgs (error, drop warning, substring := true) in
def proofOnly (n : Nat) : Nat := walk n
where
  walk (k : Nat) : Nat :=
    match k with
    | 0 => 0
    | j + 1 => walk j + 1
  termination_by k
  decreasing_by exact bound _

end

def captureOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (capture (if flag then 7 else 13) (if flag then 3 else 4))
def genericOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (pick (if flag then 17 else 19) True.intro (if flag then 3 else 4))
def shadowOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (shadow 100 (if flag then 3 else 4))
def cycleOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (cycle (if flag then 7 else 13) (if flag then 3 else 4))
def operationalOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (operational (if flag then 7 else 13) (if flag then 3 else 4))
def measuredOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (measured (if flag then 7 else 13) (if flag then 3 else 0))

run_cmd do
  for name in #[``capture, ``pick, ``shadow, ``cycle, ``measured,
      ``disconnected.bump, ``disconnected.measured, ``disconnected.proof,
      ``redundantWF, ``redundantP1] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun name => name == ``propext || name == ``Quot.sound) do
      throwError "where oracle uses an unapproved assumption: {name}: {axioms}"
    Lean.logInfo m!"PSCV0_M3_WHERE_ASSUMPTIONS: {name}: {axioms}"
  let environment ← Lean.getEnv
  for name in [``operational.bump, ``disconnected.bump, ``disconnected.measured,
      ``disconnected, ``redundantWF, ``redundantP1] do
    match environment.find? name with
    | some (.defnInfo _) => pure ()
    | _ => throwError "a nonrecursive declaration did not remain an ordinary definition: {name}"
  for name in [``operational.loop, ``disconnected.loop, ``disconnected.fixedLoop] do
    match environment.find? name with
    | some (.opaqueInfo _) => pure ()
    | _ => throwError "a recursive local helper did not inherit the original main block's partial strategy: {name}"
  match environment.find? ``disconnected.proof with
  | some (.thmInfo _) => pure ()
  | _ => throwError "an inferred proof-valued local helper did not become a theorem"


-- Main chooses inherited partial before elaborating local hints. These names
-- are intentionally unknown; only warnings for unused hints are permitted.
section
variable (hintOnly : Nat)

#guard_msgs (drop warning) in
mutual
  partial def unknownHints (base n : Nat) : Nat := loop n + proofLoop n
  where
    loop (k : Nat) : Nat :=
      match k with
      | 0 => base + 1
      | j + 1 => loop j + 2
    termination_by missingMeasure
    decreasing_by exact hintOnly
    proofLoop (k : Nat) : Nat :=
      match k with
      | 0 => base + 3
      | j + 1 => proofLoop j + 3
    termination_by k + hintOnly
    decreasing_by exact missingProof
  partial def unknownHintsPeer (n : Nat) : Nat :=
    if n == 0 then 5 else unknownHintsPeer (n - 1) + 1
end
end

example : Nat → Nat → Nat := unknownHints.loop
example : Nat → Nat → Nat := unknownHints.proofLoop
example : Nat → Nat := unknownHintsPeer

/-- error: Unknown identifier `missingMeasure` -/
#guard_msgs (error, drop warning, substring := true) in
def activeUnknownMeasure (n : Nat) : Nat := loop n
where
  loop (k : Nat) : Nat :=
    match k with | 0 => 0 | j + 1 => loop j + 1
  termination_by missingMeasure

/-- error: Unknown identifier `missingProof` -/
#guard_msgs (error, drop warning, substring := true) in
def activeUnknownProof (n : Nat) : Nat := loop n
where
  loop (k : Nat) : Nat :=
    match k with | 0 => 0 | j + 1 => loop j + 1
  termination_by k
  decreasing_by exact missingProof

/-- error: Unknown identifier `missingHeader` -/
#guard_msgs (error, drop warning, substring := true) in
partial def unknownHintHeader (n : Nat) : Nat := loop n
where
  loop (k : missingHeader) : Nat := 0
  termination_by missingMeasure

/-- error: Unknown identifier `missingBody` -/
#guard_msgs (error, drop warning, substring := true) in
partial def unknownHintBody (n : Nat) : Nat := loop n
where
  loop (k : Nat) : Nat := missingBody
  termination_by missingMeasure

/-- error: invalid mutually recursive definitions, cannot mix partial and non-partial definitions -/
#guard_msgs (error, drop warning, substring := true) in
mutual
  partial def mixedUnknownHintPartial (n : Nat) : Nat := mixedUnknownHintPartial n
  def mixedUnknownHintPlain (n : Nat) : Nat := loop n
  where
    loop (k : Nat) : Nat := loop k
    termination_by missingMeasure
end

run_cmd do
  let environment ← Lean.getEnv
  for name in [``unknownHints.loop, ``unknownHints.proofLoop, ``unknownHintsPeer] do
    match environment.find? name with
    | some (.opaqueInfo _) => pure ()
    | _ => throwError "ignored unknown hints changed a native partial helper's strategy: {name}"
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun name => name == ``propext || name == ``Quot.sound) do
      throwError "unknown-hint native oracle uses an unapproved assumption: {name}: {axioms}"

end M3WhereOracle

namespace M3Where

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def captureSource : String :=
  "function wcapture(bias: Nat, n: Nat): Nat := first(n)\n" ++
  "where {\n" ++
  "  def first(k: Nat) := second(k)\n" ++
  "  def second(k: Nat, delta: Nat := bias): Nat := k + delta\n" ++
  "}\n"

private def genericSource : String :=
  "universe u\nsection\n" ++
  "variable {A: Type u} [dictionary: Inhabited A] (fallback: A) (h: True)\n" ++
  "function wpick(n: Nat): A := loop(n)\n" ++
  "where {\n" ++
  "  def loop(k: Nat): A := match k with { | 0 => Inhabited.default | j + 1 => alternate(j) }\n" ++
  "  def alternate(k: Nat): A := match k with { | 0 => fallback | j + 1 =>\n" ++
  "    let witness: True := h\n" ++
  "    loop(j) }\n" ++
  "}\nend\n"

private def shadowSource : String :=
  "namespace WScope\n" ++
  "private function shadow(helper: Nat, n: Nat): Nat := by { exact helper(n) }\n" ++
  "where {\n" ++
  "  def helper(helper: Nat): Nat := by { exact helper + 7 }\n" ++
  "}\n" ++
  "function use(n: Nat): Nat := shadow(100, n)\n" ++
  "end WScope\n"

private def cycleSource : String :=
  "function wcycle(bias: Nat, n: Nat): Nat := match n with { | 0 => bias | k + 1 => helper(k) }\n" ++
  "where {\n" ++
  "  def helper(k: Nat): Nat := match k with { | 0 => bias + 1 | j + 1 => wcycle(bias + 2, j) }\n" ++
  "}\n"

private def partialSource : String :=
  "partial function woperational(base: Nat, n: Nat): Nat := loop(n)\n" ++
  "where {\n" ++
  "  def bump(k: Nat): Nat := k + base\n" ++
  "  def loop(k: Nat): Nat := if (k == 0) { bump(1) } else { loop(k - 1) + 1 }\n" ++
  "}\n"

private def disconnectedSource : String :=
  "section\nvariable (ignored: Nat)\nmutual\n" ++
  "partial function wdisconnectedPartial(n: Nat): Nat := if (n == 0) { 0 } else { wdisconnectedPartial(n - 1) + 1 }\n" ++
  "partial function wdisconnected(n: Nat): Nat := {\n" ++
  "  let witness: True := proof(n)\n" ++
  "  loop(n) + bump(n)\n}\n" ++
  "where {\n" ++
  "  def loop(k: Nat): Nat := match k with { | 0 => 0 | j + 1 => loop(j) + 1 }\n" ++
  "  termination_by k + ignored\n" ++
  "  decreasing_by by { exact ignored }\n" ++
  "  def bump(k: Nat): Nat := k + 1\n" ++
  "  partial_fixpoint\n" ++
  "  def measured(k: Nat): Nat := k\n" ++
  "  termination_by k + ignored\n" ++
  "  decreasing_by by { exact ignored }\n" ++
  "  def fixedLoop(k: Nat): Nat := if (k == 0) { 0 } else { fixedLoop(k - 1) }\n" ++
  "  partial_fixpoint\n" ++
  "  def proof(k: Nat) := True.intro\n" ++
  "}\nend\nmutual\n" ++
  "function wredundantWF(n: Nat): Nat := n\ntermination_by n + ignored\n" ++
  "function wredundantP1(n: Nat): Nat := n\npartial_fixpoint\n" ++
  "end\nend\n"

private def measuredSource : String :=
  "function wmeasured(bias: Nat, n: Nat): Nat := descend(n) + walk(n)\n" ++
  "where {\n" ++
  "  def finish(value: Nat): Nat := value + bias\n" ++
  "  def descend(k: Nat): Nat := if (h: 0 < k) { finish(descend(0)) } else { bias }\n" ++
  "  termination_by k\n" ++
  "  decreasing_by by { exact h }\n" ++
  "  def walk(k: Nat): Nat := match k with { | 0 => bias | j + 1 => finish(walk(j - 1)) }\n" ++
  "  termination_by k\n" ++
  "  decreasing_by by { exact Nat.lt_succ_of_le(Nat.sub_le(j, 1)) }\n" ++
  "}\n"

private def hintScopeRefusals : List (String × String) := [
  ("bias",
    "section\nvariable (bias: Nat)\n" ++
    "function measureOnly(n: Nat): Nat := walk(n)\nwhere {\n" ++
    "  def walk(k: Nat): Nat := match k with { | 0 => 0 | j + 1 => walk(j) + 1 }\n" ++
    "  termination_by k + bias\n}\nend\n"),
  ("bound",
    "section\nvariable (bound: forall (k: Nat), k < Nat.succ(k))\n" ++
    "function proofOnly(n: Nat): Nat := walk(n)\nwhere {\n" ++
    "  def walk(k: Nat): Nat := match k with { | 0 => 0 | j + 1 => walk(j) + 1 }\n" ++
    "  termination_by k\n  decreasing_by by { exact bound(j) }\n}\nend\n")]

private def missingHintName (expected : String) : PsElabError → Bool
  | .unknownName name => psNameToString name == expected
  | .scope message => message == ("unknown name " ++ expected)
  | .atDeclaration _ error => missingHintName expected error
  | _ => false

private def equations : String :=
  "theorem captureEquation(bias: Nat, n: Nat): wcapture(bias, n) = wcapture.first(bias, n) := by { exact wcapture.eq_def(bias, n) }\n" ++
  "theorem helperEquation(bias: Nat, k: Nat): wcapture.first(bias, k) = wcapture.second(bias, k, bias) := by { exact wcapture.first.eq_def(bias, k) }\n" ++
  "theorem inferredProofEquation(k: Nat): wdisconnected.proof(k) = True.intro := by { exact wdisconnected.proof.eq_def(k) }\n" ++
  "theorem measuredHelperEquation(bias: Nat, k: Nat): wmeasured.descend(bias, k) = (if (h: 0 < k) { wmeasured.finish(bias, wmeasured.descend(bias, 0)) } else { bias }) := by { exact wmeasured.descend.eq_def(bias, k) }\n" ++
  "theorem measuredMatchEquation(bias: Nat, j: Nat): wmeasured.walk(bias, Nat.succ(j)) = wmeasured.finish(bias, wmeasured.walk(bias, j - 1)) := by { exact wmeasured.walk.eq_def(bias, Nat.succ(j)) }\n"

private def source : String :=
  captureSource ++ genericSource ++ shadowSource ++ cycleSource ++ partialSource ++ disconnectedSource ++ measuredSource

private def wrappers : String :=
  "function m3wherecapture(flag: Bool): UInt64 := UInt64.ofNat(wcapture(if (flag) { 7 } else { 13 }, if (flag) { 3 } else { 4 }))\n" ++
  "function m3wheregeneric(flag: Bool): UInt64 := UInt64.ofNat(wpick(if (flag) { 17 } else { 19 }, True.intro, if (flag) { 3 } else { 4 }))\n" ++
  "function m3whereshadow(flag: Bool): UInt64 := UInt64.ofNat(WScope.use(if (flag) { 3 } else { 4 }))\n" ++
  "function m3wherecycle(flag: Bool): UInt64 := UInt64.ofNat(wcycle(if (flag) { 7 } else { 13 }, if (flag) { 3 } else { 4 }))\n" ++
  "function m3wherepartial(flag: Bool): UInt64 := UInt64.ofNat(woperational(if (flag) { 7 } else { 13 }, if (flag) { 3 } else { 4 }))\n" ++
  "function m3wherewf(flag: Bool): UInt64 := UInt64.ofNat(wmeasured(if (flag) { 7 } else { 13 }, if (flag) { 3 } else { 0 }))\n"

private def outputs : List (String × (Bool → UInt64)) :=
  [("m3wherecapture", M3WhereOracle.captureOutput),
   ("m3wheregeneric", M3WhereOracle.genericOutput),
   ("m3whereshadow", M3WhereOracle.shadowOutput),
   ("m3wherecycle", M3WhereOracle.cycleOutput),
   ("m3wherepartial", M3WhereOracle.operationalOutput),
   ("m3wherewf", M3WhereOracle.measuredOutput)]

private def binderNames : PsExpr → List String
  | .forallE name _ body _ => psNameToString name :: binderNames body
  | _ => []

private def checkSource : IO Unit := do
  let parsed ← fromExcept (psPscv0ParseProgram (captureSource ++ "const following: Nat := 1\n"))
  let [.declaration (.whereDeclaration (.definition _ parentBinders _ _ parentSpan) locals span),
      .declaration (.definition following ..)] := parsed.commands
    | throw (IO.userError "where parser lost the following declaration or parent strategy")
  ensure (parentBinders.length == 2 && locals.length == 2 && following.segments == ["following"] &&
    parentSpan.stop.byteOffset < span.start.byteOffset && span.stop.byteOffset == captureSource.utf8ByteSize - 1)
    "where spans or original parent arity were not retained"
  let [first, second] := locals | throw (IO.userError "where lost local source order")
  ensure (first.type.isNone && second.type.isSome && first.binders.length == 1 &&
    second.binders.length == 2 && first.span.stop.byteOffset < second.span.start.byteOffset)
    "where erased omitted result annotations, default binders or local spans"
  let defaultBinder : Option (PsSyntaxBinderHead × PsSyntaxTerm) := second.binders[1]?
  match defaultBinder with
  | some (_, .optionalType _ (.reference name) _) =>
    ensure (name.segments == ["bias"]) "local default lost its enclosing parameter reference"
  | _ => throw (IO.userError "local default was not retained as an owned typed default")
  let declaration := PsSyntaxDeclaration.whereDeclaration
    (.definition (PsSyntaxName.mk ["wcapture"] parentSpan) parentBinders
      (.reference (PsSyntaxName.mk ["Nat"] parentSpan))
      (.natural "0" parentSpan) parentSpan) locals span
  let lean ← fromExcept ((psPrintLeanDeclaration declaration).mapError (fun _ => "where Lean printer refused"))
  ensure ((lean.splitOn "where\n  first").length > 1 &&
    (lean.splitOn "def first").length == 1 && (lean.splitOn "delta").length > 1)
    "Lean where printer retained ProofScript's local def/braces or lost a default"
  let text ← fromExcept ((psPrintProofScriptDeclaration declaration).mapError (fun _ => "where source printer refused"))
  let printed ← fromExcept (psPscv0ParseProgram (text ++ "\n"))
  match printed.commands with
  | [.declaration (.whereDeclaration _ [againFirst, againSecond] _)] =>
    ensure (againFirst.type.isNone && againSecond.type.isSome && againSecond.binders.length == 2)
      "where print/read changed optional result/default ownership"
  | _ => throw (IO.userError "where source print/read lost local definitions")
  let suffixed := "function suffix(n: Nat): Nat := helper(n)\nwhere {\n" ++
    "  def helper(k: Nat): Nat := helper(k)\n  termination_by k\n" ++
    "  decreasing_by by { exact Nat.lt_succ_self(k) }\n" ++
    "  def after(k: Nat): Nat := k\n}\nconst tail: Nat := 0\n"
  let suffixProgram ← fromExcept (psPscv0ParseProgram suffixed)
  match suffixProgram.commands with
  | [.declaration (.whereDeclaration _ [first, after] _), .declaration _] =>
    match first.recursion with
    | some (.total termination) =>
      ensure (termination.decreasing.isSome && termination.span.stop.byteOffset < after.span.start.byteOffset)
        "local suffix consumed the next helper or discarded its proof"
    | _ => throw (IO.userError "local total strategy was discarded")
  | _ => throw (IO.userError "local suffix lost following declaration ownership")
  let unusedProgram ← fromExcept (psPscv0ParseProgram disconnectedSource)
  let groupMembers := unusedProgram.commands.filterMap fun command =>
    match command with
    | .mutualDeclarations members _ => some members
    | _ => none
  let [[_, main], [wf, fixedpoint]] := groupMembers
    | throw (IO.userError "unused hints lost their compatible original mutual source owners")
  let .whereDeclaration (.partialDefinition ..) _ _ := main.declaration
    | throw (IO.userError "the inherited helper block lost its explicit partial main")
  let .whereDeclaration _ [loop, bump, measured, fixedLoop, proof] _ := main.declaration
    | throw (IO.userError "inherited helpers lost their local source order")
  for localDefinition in [loop, measured] do
    match localDefinition.recursion with
    | some (.total termination) =>
      let .operatorE .binary _ "+" [.reference measure, .reference ignored] _ := termination.measure
        | throw (IO.userError "an unused measure lost its source expression")
      ensure (measure.segments == ["k"] && ignored.segments == ["ignored"] &&
        termination.decreasing.isSome &&
        termination.span.stop.byteOffset == localDefinition.span.stop.byteOffset)
        "effective strategy erased an unused measure or its owned span"
    | _ => throw (IO.userError "an inherited unused total hint was discarded")
  for localDefinition in [bump, fixedLoop] do
    match localDefinition.recursion with
    | some (.fixedpoint span) =>
      ensure (span.stop.byteOffset == localDefinition.span.stop.byteOffset)
        "effective strategy erased an unused fixedpoint hint span"
    | _ => throw (IO.userError "an inherited unused fixedpoint hint was discarded")
  ensure (proof.type.isNone) "proof helper no longer exercises inferred result classification"
  match wf.declaration, fixedpoint.declaration with
  | .wellFoundedDefinition .., .fixedpointDefinition .. => pure ()
  | _, _ => throw (IO.userError "nonrecursive main hints were discarded before typed dependency analysis")
  for text in [
      "function bad(n: Nat): Nat := n\nwhere {}\n",
      "function bad(n: Nat): Nat := n\nwhere { function helper(k: Nat): Nat := k }\n",
      "function bad(n: Nat): Nat := n\nwhere { const helper: Nat := 0 }\n",
      "function bad(n: Nat): Nat := n\nwhere { partial def helper(k: Nat): Nat := k }\n",
      "function bad(n: Nat): Nat := n\nwhere { theorem helper: True := by { exact True.intro } }\n",
      "function bad(n: Nat): Nat := n\nwhere { def Outer.helper(k: Nat): Nat := k }\n",
      "function bad(n: Nat): Nat := n\nwhere { def helper(k: Nat): Nat := k\nwhere { def nested: Nat := 0 } }\n",
      "function bad(n: Nat): Nat := n\nwhere { def helper(k: Nat): Nat := k\ndef helper: Nat := 0 }\n",
      "function bad(n: Nat): Nat := n\nwhere { def helper(k: Nat): Nat := k def next: Nat := 0 }\n",
      "function bad(n: Nat): Nat := n\nwhere { def helper: Nat := 0 }\ntermination_by n\n",
      "function bad(n: Nat): Nat := n\nwhere { finally { | spec => { exact True.intro } } }\n"] do
    match psPscv0ParseProgram text with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "malformed or unselected local source was accepted")
  IO.println "PSCV0_M3_WHERE_SOURCE: PASS original header boundary, omitted local result, typed default, ordered local/suffix spans, printers and grammar refusals"


private def partialHintSource : String :=
  "section\nvariable (hintOnly: Nat)\nmutual\n" ++
  "partial function phMain(base: Nat, n: Nat): Nat := loop(n) + proofLoop(n)\n" ++
  "where {\n" ++
  "  def loop(k: Nat): Nat := match k with { | 0 => base + 1 | j + 1 => loop(j) + 2 }\n" ++
  "  termination_by missingMeasure\n" ++
  "  decreasing_by by { exact hintOnly }\n" ++
  "  def proofLoop(k: Nat): Nat := match k with { | 0 => base + 3 | j + 1 => proofLoop(j) + 3 }\n" ++
  "  termination_by k + hintOnly\n" ++
  "  decreasing_by by { exact missingProof }\n" ++
  "}\n" ++
  "partial function phPeer(n: Nat): Nat := if (n == 0) { 5 } else { phPeer(n - 1) + 1 }\n" ++
  "end\nend\n"

private def partialHintRefusals : List (String × String × String) := [
  ("active-unknown-measure",
    "function active(n: Nat): Nat := loop(n)\nwhere {\n" ++
    "  def loop(k: Nat): Nat := match k with { | 0 => 0 | j + 1 => loop(j) + 1 }\n" ++
    "  termination_by missingMeasure\n}\n", "PSCV0-SCOPE: unknown name missingMeasure"),
  ("active-unknown-proof",
    "function active(n: Nat): Nat := loop(n)\nwhere {\n" ++
    "  def loop(k: Nat): Nat := match k with { | 0 => 0 | j + 1 => loop(j) + 1 }\n" ++
    "  termination_by k\n  decreasing_by by { exact missingProof }\n}\n",
    "PSCV0-SCOPE: unknown name missingProof"),
  -- General nonrecursive hint parity is outside this bounded P0 change.
  ("ordinary-unused-unknown-measure",
    "function ordinary(n: Nat): Nat := loop(n)\nwhere {\n" ++
    "  def loop(k: Nat): Nat := k\n  termination_by missingMeasure\n}\n",
    "PSCV0-SCOPE: unknown name missingMeasure"),
  ("partial-local-header",
    "partial function header(n: Nat): Nat := loop(n)\nwhere {\n" ++
    "  def loop(k: missingHeader): Nat := 0\n  termination_by missingMeasure\n}\n",
    "PSCV0-SCOPE: unknown name missingHeader"),
  ("partial-main-header",
    "partial function header(n: missingHeader): Nat := loop(0)\nwhere {\n" ++
    "  def loop(k: Nat): Nat := 0\n  termination_by missingMeasure\n}\n",
    "PSCV0-SCOPE: unknown name missingHeader"),
  ("partial-local-body",
    "partial function body(n: Nat): Nat := loop(n)\nwhere {\n" ++
    "  def loop(k: Nat): Nat := missingBody\n  termination_by missingMeasure\n}\n",
    "PSCV0-SCOPE: unknown name missingBody"),
  ("mixed-original-main-before-hints",
    partialHintSource.replace "partial function phPeer" "function phPeer",
    "PSCV0-MUTUAL-STRATEGY: cannot mix partial and non-partial original main definitions")]

private def partialHintSpanEq (left right : PsSourceSpan) : Bool :=
  left.start.byteOffset == right.start.byteOffset &&
  left.start.line == right.start.line && left.start.column == right.start.column &&
  left.stop.byteOffset == right.stop.byteOffset &&
  left.stop.line == right.stop.line && left.stop.column == right.stop.column

private def partialHintText (suffix : PsSyntaxTermination) : IO String :=
  fromExcept ((psPrintProofScriptDeclaration (.wellFoundedDefinition
    (PsSyntaxName.mk ["hint"] suffix.span) []
    (.reference (PsSyntaxName.mk ["Nat"] suffix.span))
    (.natural "0" suffix.span) suffix suffix.span)).mapError
      (fun _ => "retained local hint could not be printed"))

private def checkPartialHintScopes : IO Unit := do
  ensure (M3WhereOracle.unknownHints 7 3 == 33 &&
    M3WhereOracle.unknownHints 13 4 == 50)
    "native ignored-hint bodies or real enclosing captures changed"
  let parsed ← fromExcept (psPscv0ParseProgram partialHintSource)
  let groups := parsed.commands.filterMap fun command =>
    match command with | .mutualDeclarations members _ => some members | _ => none
  let [members] := groups | throw (IO.userError "unknown hints lost their original mutual source block")
  let [main, _] := members | throw (IO.userError "unknown hints lost a compatible original main")
  let mainSources := members.map (fun member => PsElabPreDefinitionSource.declaration member.declaration)
  let _ ← fromExcept ((psElabPreDefinitionCheckMainModifiers mainSources).mapError psCompilerPscv0ElabError)
  let inheritedPartial := psElabPreDefinitionHasPartialMain mainSources
  ensure inheritedPartial "unknown hints no longer exercise inherited partial intent"
  let .whereDeclaration _ originals _ := main.declaration
    | throw (IO.userError "unknown hints lost their local source owners")
  let scopedMain ← fromExcept ((psScopePreDefinition
    { environment := psSelfHostProdPreludeEnvironment, scope := {} } main
    (PsSyntaxName.mk ["$partialHintMain"] (psElabOriginSource main.declaration).snd)
    inheritedPartial).mapError psCompilerPscv0ElabError)
  ensure (scopedMain.locals.length == 2 && !scopedMain.used.contains "hintOnly" &&
    !scopedMain.used.contains "missingMeasure" && !scopedMain.used.contains "missingProof")
    "unused local hints requested a section capture or unresolved dependency"
  for (original, scopedLocal) in originals.zip scopedMain.locals do
    let some (.total before) := original.recursion
      | throw (IO.userError "unknown hint lost its parsed total suffix")
    let some (.total after) := scopedLocal.source.recursion
      | throw (IO.userError "inherited partial discarded its unused suffix")
    let beforeText ← partialHintText before
    let afterText ← partialHintText after
    ensure (beforeText == afterText && partialHintSpanEq before.span after.span &&
      partialHintSpanEq (psSyntaxTermSpan before.measure) (psSyntaxTermSpan after.measure) &&
      partialHintSpanEq original.span scopedLocal.source.span)
      "unused local measure/proof syntax or source span changed during scope"
    match before.decreasing, after.decreasing with
    | some first, some second =>
      ensure (partialHintSpanEq (psSyntaxTermSpan first) (psSyntaxTermSpan second))
        "unused proof hint lost its original span"
    | _, _ => throw (IO.userError "unused proof hint was discarded")
  let compiled ← fromExcept ((psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed
    "PartialHintScope").mapError psCompilerPscv0ElabError)
  let environment := compiled.result.environment
  for (name, parameters) in [
      (psRootName "phMain", ["base", "n"]),
      (psNameAppendStr (psRootName "phMain") "loop", ["base", "k"]),
      (psNameAppendStr (psRootName "phMain") "proofLoop", ["base", "k"]),
      (psRootName "phPeer", ["n"])] do
    match psEnvironmentFind environment name,
        psEnvironmentFind environment (PsName.num name 0) with
    | some (.opaqueDecl _ levels type witness), some (.partialDecl _ bodyLevels bodyType body) =>
      ensure (levels.isEmpty && bodyLevels.isEmpty && binderNames type == parameters &&
        psExprAlphaEq type bodyType && !psExprHasUnresolvedMeta type &&
        !psExprHasUnresolvedMeta witness && !psExprHasUnresolvedMeta body &&
        (psExprFVarIds type).isEmpty && (psExprFVarIds witness).isEmpty &&
        (psExprFVarIds body).isEmpty && !psExprHasConst name witness)
        "unknown hints changed partial strategy, real captures or logical/body closure"
      if !psNameEq name (psRootName "phMain") then
        ensure (psExprHasConst name body)
          "ignored hints replaced an actual recursive body with its logical inhabitant"
    | _, _ => throw (IO.userError "unknown hints lost independently inhabited opaque/body ownership")
    ensure ((psEnvironmentFind environment (psNameAppendStr name "eq_def")).isNone)
      "ignored termination hints created a partial defining equation"
  let localOrigins := compiled.origins.flatMap (·.localDefinitions)
  ensure (localOrigins.length == 2) "unknown hints changed local provenance membership"
  for (original, origin) in originals.zip localOrigins do
    ensure (partialHintSpanEq original.span origin.span && !origin.declarations.isEmpty)
      "unknown hints moved a local span or discarded its emitted identities"
  let requests := #[({ source := partialHintSource, sourceName := "m3-partial-hint-scope.ps" } :
    PsV7Native.Request)] ++
    (partialHintRefusals.map fun (_, text, _) => ({ source := text } : PsV7Native.Request)).toArray
  let batch : PsV7Native.Batch ← match ← PsV7Native.runBatch requests with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  match (batch.results[0]? : Option (Except PsV7Native.Diagnostic PsV7Native.Result)) with
  | some (Except.ok result) =>
    ensure (result.declarationCount > 0 && result.artifacts.isEmpty)
      "source-only partial hint qualification returned an empty or executable result"
  | some (Except.error error) => throw (IO.userError (error.phase ++ ": " ++ error.message))
  | none => throw (IO.userError "missing partial hint qualification result")
  for ((label, _, rule), index) in partialHintRefusals.zipIdx do
    match batch.results[index + 1]? with
    | some (.error error) =>
      ensure (error.phase == "elaborate" && (error.message.splitOn rule).length > 1)
        (label ++ " refused at wrong owner: " ++ error.phase ++ ": " ++ error.message)
    | _ => throw (IO.userError ("unexpected partial hint acceptance: " ++ label))
  IO.println "PSCV0_M3_PARTIAL_HINT_SCOPE: PASS pinned native ignored measures/proofs, validated all-partial main ownership, raw local hint spans, actual captures and opaque/body identities; active hints, headers, bodies and mixed mains still refuse"

private def checkConstruction : IO Unit := do
  let parsed ← fromExcept (psPscv0ParseProgram source)
  let compiled ← fromExcept ((psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed
    "WhereFixture").mapError psCompilerPscv0ElabError)
  let environment := compiled.result.environment
  for (name, parameters) in [
      (psNameAppendStr (psRootName "wcapture") "first", ["bias", "k"]),
      (psNameAppendStr (psRootName "wcapture") "second", ["bias", "k", "delta"]),
      (psNameAppendStr (psRootName "wcycle") "helper", ["bias", "k"])] do
    let some (.definitionDecl _ _ type value) := psEnvironmentFind environment name
      | throw (IO.userError ("missing real lifted total helper " ++ psNameToString name))
    ensure (binderNames type == parameters && (psExprFVarIds value).isEmpty &&
      !psExprHasUnresolvedMeta type && !psExprHasUnresolvedMeta value)
      "lifted helper capture order, source arity or closed Core identity changed"
    match psEnvironmentFind environment (psNameAppendStr name "eq_def") with
    | some (.theoremDecl ..) => pure ()
    | _ => throw (IO.userError "lifted total helper lost its checked equation")
  for shortName in ["loop", "alternate"] do
    let name := psNameAppendStr (psRootName "wpick") shortName
    let some (.definitionDecl _ levels type _) := psEnvironmentFind environment name
      | throw (IO.userError "all-kind recursive helper was not constructed")
    ensure (binderNames type == ["A", "dictionary", "fallback", "h", "k"] &&
      levels.map psNameToString == ["u"])
      "helper clique lost transitive type/instance/value/proof captures or its shared universe"
  let parentName := psSyntaxNameAppendSegments ["$psc0Private", "WhereFixture", "WScope", "shadow"] .anonymous
  let helperName := psNameAppendStr parentName "helper"
  for name in [parentName, helperName, psNameAppendStr parentName "eq_def", psNameAppendStr helperName "eq_def"] do
    ensure ((psEnvironmentFind environment name).isSome && compiled.privateNames.any (psNameEq name))
      "private where declaration or helper equation escaped its module-qualified owner"
  let operational := psRootName "woperational"
  for name in [operational, psNameAppendStr operational "loop"] do
    match psEnvironmentFind environment name,
        psEnvironmentFind environment (PsName.num name 0) with
    | some (.opaqueDecl ..), some (.partialDecl ..) => pure ()
    | _, _ => throw (IO.userError "explicit/inherited recursive partial intent lost actual opaque/body ownership")
    ensure ((psEnvironmentFind environment (psNameAppendStr name "eq_def")).isNone)
      "partial helper acquired an invented defining equation"
  match psEnvironmentFind environment (psNameAppendStr operational "bump") with
  | some (.definitionDecl ..) => pure ()
  | _ => throw (IO.userError "plain nonrecursive helper inheriting partial intent did not remain total")
  let disconnected := psRootName "wdisconnected"
  for shortName in ["loop", "fixedLoop"] do
    let name := psNameAppendStr disconnected shortName
    match psEnvironmentFind environment name,
        psEnvironmentFind environment (PsName.num name 0) with
    | some (.opaqueDecl _ levels type _), some (.partialDecl ..) =>
      ensure (levels.isEmpty && binderNames type == ["k"])
        "an ignored hint added a section capture to a partial helper"
    | _, _ => throw (IO.userError "a retained local hint overrode block-wide inherited partial opacity")
    ensure ((psEnvironmentFind environment (psNameAppendStr name "eq_def")).isNone)
      "an inherited-partial helper acquired an equation from its unused hint"
  -- v7.2 preserves opacity for an explicit source partial main even when
  -- native Main's nonrecursive-first route makes its own main transparent.
  match psEnvironmentFind environment disconnected,
      psEnvironmentFind environment (PsName.num disconnected 0) with
  | some (.opaqueDecl _ levels type _), some (.partialDecl ..) =>
    ensure (levels.isEmpty && binderNames type == ["n"] &&
      (psEnvironmentFind environment (psNameAppendStr disconnected "eq_def")).isNone)
      "explicit-source partial opacity or ignored-hint header ownership changed"
  | _, _ => throw (IO.userError "the explicit partial main lost its logical/body identities")
  for name in [psNameAppendStr disconnected "bump",
      psNameAppendStr disconnected "measured", psRootName "wredundantWF", psRootName "wredundantP1"] do
    match psEnvironmentFind environment name,
        psEnvironmentFind environment (psNameAppendStr name "eq_def") with
    | some (.definitionDecl _ levels type value), some (.theoremDecl _ _ equationType proof) =>
      ensure (levels.isEmpty && (binderNames type).length == 1 &&
        !psExprHasConst psWellFoundedFixName value &&
        !psExprHasUnresolvedMeta type && !psExprHasUnresolvedMeta value &&
        !psExprHasUnresolvedMeta equationType && !psExprHasUnresolvedMeta proof)
        "an unused hint changed an ordinary value into a WF construction or left unchecked terms"
    | _, _ => throw (IO.userError "unused hints changed nonrecursive-first checked definition/equation ownership")
  let proofName := psNameAppendStr disconnected "proof"
  match psEnvironmentFind environment proofName,
      psEnvironmentFind environment (psNameAppendStr proofName "eq_def") with
  | some (.theoremDecl _ _ type value), some (.theoremDecl _ _ equationType proof) =>
    ensure (binderNames type == ["k"] && !psExprHasUnresolvedMeta type &&
      !psExprHasUnresolvedMeta value && !psExprHasUnresolvedMeta equationType &&
      !psExprHasUnresolvedMeta proof)
      "inferred local theorem or its exact proof equation lost its checked header"
  | _, _ => throw (IO.userError "an inferred proof-valued helper did not emit a checked theorem and equation")
  for shortName in ["descend", "walk"] do
    let measuredName := psNameAppendStr (psRootName "wmeasured") shortName
    match psEnvironmentFind environment measuredName,
        psEnvironmentFind environment (psNameAppendStr measuredName "eq_def") with
    | some (.definitionDecl _ _ type value), some (.theoremDecl _ _ _ proof) =>
      ensure (binderNames type == ["bias", "k"] && psExprHasConst psWellFoundedFixName value &&
        psExprHasConst psWellFoundedFixEqName proof && !psExprHasConst measuredName value)
        "local WF construction lost its checked captures, real fix/fix_eq or closed callback"
    | _, _ => throw (IO.userError "local total suffix did not construct its checked definition and source equation")
  -- Reuse the already checked prelude; these are source-scope checks, not
  -- additional backend requests. The named failure must be the missing
  -- hint-only local, after its ordinary typed body has elaborated.
  for (name, text) in hintScopeRefusals do
    let parsed ← fromExcept (psPscv0ParseProgram text)
    match psElabProgram psSelfHostProdPreludeEnvironment parsed with
    | .error error =>
      ensure (missingHintName name error)
        ("active hint-only local refused at the wrong owner: " ++ psCompilerPscv0ElabError error)
    | .ok _ => throw (IO.userError "an active hint silently added a section capture")
  let incompatible ← fromExcept (psPscv0ParseProgram (
    "mutual\npartial function invalidPartial(n: Nat): Nat := invalidPartial(n)\n" ++
    "function invalidPlain(n: Nat): Nat := n\nend\n"))
  match psElabProgram psSelfHostProdPreludeEnvironment incompatible with
  | .error error =>
    ensure (((psCompilerPscv0ElabError error).splitOn
      "PSCV0-MUTUAL-STRATEGY: cannot mix partial and non-partial original main definitions").length > 1)
      "disconnected mixed original mains did not refuse at the pinned modifier owner"
  | .ok _ => throw (IO.userError "SCC splitting admitted incompatible original main modifiers")
  let localCount := compiled.origins.foldl (fun count origin => count + origin.localDefinitions.length) 0
  ensure (localCount == 16) "source origins discarded local helper membership"
  for origin in compiled.origins do
    for localDefinition in origin.localDefinitions do
      ensure (localDefinition.span.start.byteOffset >= origin.span.start.byteOffset &&
        localDefinition.span.stop.byteOffset <= origin.span.stop.byteOffset &&
        !localDefinition.declarations.isEmpty &&
        localDefinition.declarations.all (fun name => origin.members.any (fun member => psNameEq member.name name)))
        "local span or emitted members escaped their actual parent origin"
    for (name, emitted) in PsV7Native.sourceOriginsForBatch "m3-where.ps" origin do
      let localOwner := origin.localDefinitions.find? fun localDefinition =>
        localDefinition.declarations.any (fun declaration => psNameToString declaration == name)
      let expectedSpan := (localOwner.map (·.span)).getD origin.span
      ensure (emitted.identity.file == "m3-where.ps" && emitted.identity.declaration == name &&
        emitted.span.start.byteOffset == expectedSpan.start.byteOffset &&
        emitted.span.stop.byteOffset == expectedSpan.stop.byteOffset)
        "emission used the enclosing declaration span for a local helper or changed its identity"
      let json := PsV7Native.sourceOriginJson name emitted
      if origin.localDefinitions.isEmpty then
        ensure (!(json.getObjVal? "localDefinitions").isOk &&
          (json.getObjVal? "sourceIndex").isOk == origin.mutualGroup.isSome)
          "origin JSON acquired local-helper fields or changed existing mutual source-index ownership"
      else
        let sourceIndex ← fromExcept (json.getObjValAs? Nat "sourceIndex")
        let localsJson ← fromExcept (json.getObjVal? "localDefinitions")
        let locals ← fromExcept localsJson.getArr?
        ensure (sourceIndex == origin.sourceIndex && locals.size == origin.localDefinitions.length)
          "local origin JSON lost its source index or local declaration order"
        for (localDefinition, serialized) in origin.localDefinitions.zip locals.toList do
          let semantic ← fromExcept (serialized.getObjValAs? String "semantic")
          let firstByte ← fromExcept (serialized.getObjValAs? Nat "sourceStartByte")
          let lastByte ← fromExcept (serialized.getObjValAs? Nat "sourceEndByte")
          let declarations ← fromExcept (serialized.getObjValAs? (List String) "declarations")
          ensure (semantic == psNameToString localDefinition.name &&
            firstByte == localDefinition.span.start.byteOffset && lastByte == localDefinition.span.stop.byteOffset &&
            declarations == localDefinition.declarations.map psNameToString)
            "serialized local origin changed its qualified name, exact span or emitted declaration membership"
  let equations ← fromExcept (psPscv0ParseProgram equations)
  let _ ← fromExcept ((psElabProgram environment equations).mapError psCompilerPscv0ElabError)
  IO.println "PSCV0_M3_WHERE_CONSTRUCTION: PASS actual helper captures and equations, forward inference/defaults, sibling recursion, parent/helper clique, inferred theorem helpers, proof shadowing, private identities, original-block P0 inheritance, ignored hints without captures, active hint-only scope refusals, checked local WF and exact local origins"

private def refusals : List (String × String × String) := [
  ("body-lambda-scope",
    "function bad(n: Nat): Nat -> Nat := fun (seed: Nat) => helper(n)\nwhere { def helper(k: Nat): Nat := seed }\n",
    "unknown name seed"),
  ("out-of-scope-helper",
    captureSource ++ "const bad: Nat := first(3)\n", "unknown name first"),
  ("local-nondecrease",
    "function bad(n: Nat): Nat := helper(n)\nwhere { def helper(k: Nat): Nat := match k with { | 0 => 0 | j + 1 => helper(k) } }\n",
    "PSCV0-MUTUAL-TOTAL: DECREASE"),
  ("local-fixedpoint-policy",
    "function bad(n: Nat): Nat := helper(n)\nwhere { def helper(k: Nat): Nat := helper(k) partial_fixpoint }\n",
    "PSCV0-FIXPOINT-ASSUMPTION"),
  ("local-wf-nondecrease",
    "function bad(n: Nat): Nat := helper(n)\nwhere { def helper(k: Nat): Nat := helper(k)\ntermination_by k\n}\n",
    "PSCV0-WF-DECREASE"),
  ("inferred-dependent-codomain",
    "function bad(n: Nat): Nat := Fin.val(helper(n))\nwhere { def helper(k: Nat) := Fin.mk(k, Nat.lt_succ_self(k)) }\n",
    "PSCV0-WHERE-INFER-TYPE")]

end M3Where

open M3Where in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "where qualification requires pinned Lean"
  M3ResultInference.check
  checkPartialHintScopes
  checkSource
  checkConstruction
  let request : PsV7Native.Request := {
    source := source ++ equations ++ wrappers
    sourceName := "m3-where.ps"
    outputStem := "wherefixture"
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent]
    exports := .selected (outputs.map Prod.fst) }
  let requests := #[request] ++ (refusals.map fun (_, text, _) =>
    ({ source := text } : PsV7Native.Request)).toArray
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  let some first := batch.results[0]? | throw (IO.userError "missing where result")
  let result ← match first with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (result.artifacts.length == 5) "where did not emit all five targets"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "wherefixture.ps") (source ++ equations ++ wrappers)
  for artifact in result.artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  for ((label, _, rule), index) in refusals.zipIdx do
    match batch.results[index + 1]? with
    | some (.error error) =>
      ensure (error.phase == "elaborate" && (error.message.splitOn rule).length > 1)
        (label ++ " refused at wrong owner: " ++ error.phase ++ ": " ++ error.message)
    | _ => throw (IO.userError ("unexpected where acceptance: " ++ label))
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj (("flag", Lean.toJson flag) ::
      outputs.map (fun (name, oracle) => (name, Lean.toJson (toString (oracle flag)))))
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_WHERE: PASS independent native where oracles, checked capture/SCC construction and five-target emission; runtime parity follows"
