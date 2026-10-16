import Ps.Host.NativeV7
import Lean.Util.CollectAxioms

-- Independent pinned Lean definitions. The portable compiler consumes the
-- distinct .ps source below; neither side uses the other's elaborated body.
namespace M3WellFoundedOracle

def skip (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => skip (k - 1) + 1
termination_by n
decreasing_by exact Nat.lt_succ_of_le (Nat.sub_le _ _)

theorem skip_step (k : Nat) : skip (Nat.succ k) = skip (k - 1) + 1 :=
  skip.eq_def (Nat.succ k)

def branches (n : Nat) : Nat :=
  match n with
  | 0 => 1
  | k + 1 => branches (k - 1) + branches k
termination_by n
decreasing_by
  · exact Nat.lt_succ_of_le (Nat.sub_le _ _)
  · exact Nat.lt_succ_self _

def shiftedMeasure (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => shiftedMeasure (k - 1) + 1
termination_by n + 1
decreasing_by exact Nat.succ_le_succ (Nat.succ_le_succ (Nat.sub_le _ _))

def defaultDecrease (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => defaultDecrease k + 1
termination_by n

run_cmd do
  for name in #[``WellFounded.Nat.fix, ``WellFounded.Nat.fix_eq,
      ``skip, ``skip_step, ``branches, ``shiftedMeasure, ``defaultDecrease] do
    let axioms ← Lean.collectAxioms name
    unless axioms.all (fun name => name == ``propext || name == ``Quot.sound) do
      throwError "WF oracle uses an unapproved assumption: {name}: {axioms}"
    Lean.logInfo m!"PSCV0_M3_WF_ASSUMPTIONS: {name}: {axioms}"

end M3WellFoundedOracle

private def skipSource : String :=
  "function m3wfskip(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => m3wfskip(k - 1) + 1 }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n"

private def branchBody : String :=
  "function m3wfbranches(n: Nat): Nat := match n with { | 0 => 1 | k + 1 => m3wfbranches(k - 1) + m3wfbranches(k) }\n" ++
  "termination_by n\n"

private def scopeSource : String :=
  "namespace M3WFScope\n" ++
  "private theorem bound(k: Nat): Nat.lt(k - 1, Nat.succ(k)) := by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n" ++
  "private function loop(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => loop(k - 1) + 1 }\n" ++
  "termination_by n\n" ++
  "decreasing_by by { exact bound(k) }\n" ++
  "function use(n: Nat): Nat := loop(n)\n" ++
  "end M3WFScope\n"

private def source : String :=
  skipSource ++
  "theorem m3wfskipStep(k: Nat): m3wfskip(Nat.succ(k)) = m3wfskip(k - 1) + 1 := by { exact m3wfskip.eq_def(Nat.succ(k)) }\n" ++
  branchBody ++
  "decreasing_by by {\n" ++
  "  · exact Nat.lt_succ_of_le(Nat.sub_le(k, 1))\n" ++
  "  · exact Nat.lt_succ_self(k)\n" ++
  "}\n" ++
  "function m3wfshift(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => m3wfshift(k - 1) + 1 }\n" ++
  "termination_by n + 1\n" ++
  "decreasing_by by { exact Nat.succ_le_succ(Nat.succ_le_succ(Nat.sub_le(k, 1))) }\n" ++
  "function m3wfdefault(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => m3wfdefault(k) + 1 }\n" ++
  "termination_by n\n" ++
  scopeSource ++
  "function m3wfskipoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfskip(if (flag) { 17 } else { 10 }))\n" ++
  "function m3wfbranchesoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfbranches(if (flag) { 9 } else { 6 }))\n" ++
  "function m3wfshiftoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfshift(if (flag) { 17 } else { 10 }))\n" ++
  "function m3wfdefaultoutput(flag: Bool): UInt64 := UInt64.ofNat(m3wfdefault(if (flag) { 17 } else { 10 }))\n"

-- Suffix ownership is checked before elaboration. Malformed selected syntax
-- must fail here, while a well-formed strategy survives into its semantic owner.
private def checkSource : IO Unit := do
  let plain := "termination_by n\n"
  let proved := plain ++ "decreasing_by by { exact Nat.lt_succ_self(n) }\n"
  for (sourcePrefix, suffix, privacy, registration) in [
      ("def fixed(n: Nat): Nat := fixed(n)\n", plain, false, ""),
      ("function fixed(n: Nat): Nat := fixed(n) ", proved, false, ""),
      ("function fixed(n: Nat): Nat := fixed(n)\n  ", proved, false, ""),
      ("private function fixed(n: Nat): Nat := fixed(n)\n", proved, true, ""),
      ("abbrev fixed(n: Nat): Nat := fixed(n)\n", plain, false, "abbrev"),
      ("opaque fixed(n: Nat): Nat := fixed(n)\n", plain, false, "opaque")] do
    let text := sourcePrefix ++ suffix
    let program ← match psPscv0ParseProgram (text ++ "const following: Nat := 1\n") with
      | .ok value => pure value
      | .error message => throw (IO.userError ("WF source: " ++ message))
    let (declaration, actualPrivacy, actualRegistration) ← match program.commands with
      | [.declaration value, .declaration (.definition ..)] => pure (value, false, "")
      | [.privateDeclaration value, .declaration (.definition ..)] => pure (value, true, "")
      | [.registeredDeclaration value .abbrevDecl, .declaration (.definition ..)] =>
        pure (value, false, "abbrev")
      | [.registeredDeclaration value .opaqueDecl, .declaration (.definition ..)] =>
        pure (value, false, "opaque")
      | _ => throw (IO.userError "WF suffix consumed the following command or its registration")
    if actualPrivacy != privacy || actualRegistration != registration then
      throw (IO.userError "WF command lost its privacy/registration")
    let .wellFoundedDefinition name _ _ body termination span := declaration
      | throw (IO.userError "WF strategy was discarded or relabeled")
    let .reference measure := termination.measure
      | throw (IO.userError "WF measure was changed")
    if name.segments != ["fixed"] || measure.segments != ["n"] ||
        span.start.byteOffset != (if privacy then 8 else 0) ||
        span.stop.byteOffset != text.utf8ByteSize - 1 ||
        termination.span.start.byteOffset != sourcePrefix.utf8ByteSize ||
        termination.span.stop.byteOffset != span.stop.byteOffset ||
        (psSyntaxTermSpan body).stop.byteOffset > termination.span.start.byteOffset then
      throw (IO.userError "WF body/measure/suffix source spans were not retained")
    if suffix == plain then
      if termination.decreasing.isSome then
        throw (IO.userError "WF parser invented a decreasing proof")
    else
      match termination.decreasing with
      | some (.byE [.exactE _ false _] _ proofSpan) =>
        if proofSpan.stop.byteOffset != span.stop.byteOffset ||
            proofSpan.start.byteOffset <= measure.span.stop.byteOffset then
          throw (IO.userError "WF proof span was not retained")
      | _ => throw (IO.userError "WF proof sequence was discarded")
  let body := "function fixed(n: Nat): Nat := fixed(n)\n"
  for (text, expected) in [
      (body ++ "termination_by structural n\n", "PSCV0-TERM-01"),
      (body ++ plain ++ "decreasing_by exact Nat.lt_succ_self(n)\n", "PSCV0-TERM-01"),
      (body ++ plain ++ "decreasing_by by exact Nat.lt_succ_self(n)\n", "PSCV0-TERM-01"),
      (body ++ "decreasing_by by { rfl }\n", "PSCV0-TERM-01"),
      (body ++ plain ++ plain, "PSCV0-REC-STRATEGY-01"),
      (body ++ proved ++ "decreasing_by by { rfl }\n", "PSCV0-REC-STRATEGY-01"),
      (body ++ plain ++ "partial_fixpoint\n", "PSCV0-REC-STRATEGY-01"),
      (body ++ "partial_fixpoint\n" ++ plain, "PSCV0-REC-STRATEGY-01"),
      ("theorem fixed: True := True.intro\n" ++ plain, "PSCV0-REC-STRATEGY-01"),
      ("partial " ++ body ++ plain, "PSCV0-REC-STRATEGY-01")] do
    match psPscv0ParseProgram text with
    | .ok _ => throw (IO.userError ("invalid WF source accepted: " ++ text))
    | .error message =>
      if !message.startsWith expected then
        throw (IO.userError ("WF source failed at wrong rule: " ++ message))
  let parsed ← match psPscv0ParseProgram skipSource with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let [.declaration declaration] := parsed.commands
    | throw (IO.userError "unexpected WF print input")
  let lean ← match psPrintLeanDeclaration declaration with
    | .ok value => pure value
    | .error _ => throw (IO.userError "WF native printing failed")
  if (lean.splitOn "\ntermination_by n").length != 2 ||
      (lean.splitOn "\ndecreasing_by\n  exact ").length != 2 ||
      (lean.splitOn "decreasing_by by").length != 1 then
    throw (IO.userError "WF native printer retained the source by wrapper")
  let printed ← match psPrintProofScriptDeclaration declaration with
    | .ok value => pure value
    | .error _ => throw (IO.userError "WF proofscript printing failed")
  let reparsed ← match psPscv0ParseProgram (printed ++ "\n") with
    | .ok value => pure value
    | .error message => throw (IO.userError ("WF proofscript round-trip: " ++ message))
  let [.declaration (.wellFoundedDefinition name binders type value termination span)] := reparsed.commands
    | throw (IO.userError "WF proofscript round-trip lost its strategy")
  let reprinted ← match psPrintProofScriptDeclaration
      (.wellFoundedDefinition name binders type value termination span) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "WF proofscript reprinting failed")
  if reprinted != printed then throw (IO.userError "WF proofscript round-trip changed the declaration")
  let surface ← match psPscv0ParseSource true skipSource with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let lowered ← match psPscv0LowerModule surface with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  match lowered.declarations with
  | [.wellFoundedDefinition ..] => pure ()
  | _ => throw (IO.userError "WF flat source lowering discarded its strategy")
  IO.println "PSCV0_M3_WF_SOURCE: PASS measure/proof/span and following-command ownership, selected heads, strategy refusals and both printers"

-- Inspect the real typed construction separately from runtime observations.
-- In particular an opaque P0 declaration, an axiom, or a self-referential
-- definition cannot stand in for WellFounded.Nat.fix or its checked equation.
private def checkConstruction : IO Unit := do
  let parsed ← match psCompilerParsePscv0 (skipSource ++ scopeSource) with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  let result ← match psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed with
    | .ok value => pure value
    | .error error => throw (IO.userError (psCompilerPscv0ElabError error))
  let name := psRootName "m3wfskip"
  let equationName := psNameAppendStr name "eq_def"
  match psEnvironmentFind result.result.environment name with
  | some (.definitionDecl _ _ type value) =>
    if !psExprHasConst psWellFoundedFixName value || psExprHasConst name value ||
        psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta value then
      throw (IO.userError "WF declaration lost its checked fixedpoint construction")
  | _ => throw (IO.userError "WF declaration is not an ordinary checked definition")
  match psEnvironmentFind result.result.environment equationName with
  | some (.theoremDecl _ _ type value) =>
    if !psExprHasConst psWellFoundedFixEqName value ||
        psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta value then
      throw (IO.userError "WF equation did not use the checked fix_eq theorem")
  | _ => throw (IO.userError "WF equation is missing or unproved")
  match result.result.declarations with
  | [_, _, .theoremDecl boundName .., .definitionDecl loopName _ _ loopBody,
      .theoremDecl loopEquation .., .definitionDecl publicName _ _ publicBody] =>
    if !psNameEq loopEquation (psNameAppendStr loopName "eq_def") ||
        !psNameEq publicName (psNameAppendStr (psRootName "M3WFScope") "use") ||
        !psExprHasConst boundName loopBody || !psExprHasConst loopName publicBody ||
        ![boundName, loopName, loopEquation].all (fun name => result.privateNames.any (psNameEq name)) ||
        result.privateNames.any (psNameEq publicName) then
      throw (IO.userError "WF namespace/private proof or generated-equation ownership was lost")
  | _ => throw (IO.userError "WF private declaration batch changed shape")
  IO.println "PSCV0_M3_WF_CONSTRUCTION: PASS real Nat.fix, resolved call proofs, checked fix_eq equation, no recursive axiom or P0 marker"

private def refusals : List (String × String × String) := [
  ("same-size",
    "function bad(n: Nat): Nat := bad(n)\ntermination_by n\n",
    "PSCV0-WF-DECREASE"),
  ("false-measure",
    "function bad(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => bad(k) }\ntermination_by 0\n",
    "PSCV0-WF-DECREASE"),
  ("only-first-goal",
    branchBody ++ "decreasing_by by { exact Nat.lt_succ_of_le(Nat.sub_le(k, 1)) }\n",
    "PSCV0-WF-DECREASE"),
  ("unresolved-proof",
    skipSource.replace "exact Nat.lt_succ_of_le(Nat.sub_le(k, 1))" "refine _",
    "PSCV0-WF-DECREASE"),
  ("nonrecursive",
    "function bad(n: Nat): Nat := n\ntermination_by n\n",
    "PSCV0-WF-NOT-RECURSIVE"),
  ("wrong-domain",
    "function bad(n: Bool): Nat := bad(n)\ntermination_by 0\n",
    "PSCV0-WF-DOMAIN"),
  ("wrong-result",
    "function bad(n: Nat): Bool := bad(n)\ntermination_by n\n",
    "PSCV0-WF-RESULT"),
  ("extra-parameter",
    "function bad(n: Nat, k: Nat): Nat := bad(n, k)\ntermination_by n\n",
    "PSCV0-WF-TELESCOPE"),
  ("escaping-self",
    "function bad(n: Nat): Nat := (fun (f: Nat -> Nat) => f(n))(bad)\ntermination_by n\n",
    "PSCV0-WF-ESCAPE")]

def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  checkSource
  checkConstruction
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "wellfounded.ps") source
  let request : PsV7Native.Request := {
    source, sourceName := "m3-well-founded.ps", outputStem := "wellfounded"
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent]
    exports := .selected ["m3wfskipoutput", "m3wfbranchesoutput",
      "m3wfshiftoutput", "m3wfdefaultoutput"] }
  let requests := #[request] ++ (refusals.map fun (_, text, _) =>
    ({ source := text } : PsV7Native.Request)).toArray
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  let some first := batch.results[0]? | throw (IO.userError "missing WF result")
  let result ← match first with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  if result.artifacts.length != request.targets.length then
    throw (IO.userError "WF did not emit every requested target")
  for artifact in result.artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  for ((label, _, expected), index) in refusals.zipIdx do
    let some outcome := batch.results[index + 1]?
      | throw (IO.userError ("missing WF refusal: " ++ label))
    match outcome with
    | .ok _ => throw (IO.userError ("WF unexpectedly accepted " ++ label))
    | .error error =>
      if error.phase != "elaborate" || (error.message.splitOn expected).length < 2 then
        throw (IO.userError (label ++ " failed at wrong phase/rule: " ++
          error.phase ++ ": " ++ error.message))
  let rows := [false, true].map fun flag =>
    let n := if flag then 17 else 10
    let branchN := if flag then 9 else 6
    Lean.Json.mkObj [
      ("flag", Lean.toJson flag),
      ("m3wfskipoutput", Lean.toJson (toString (M3WellFoundedOracle.skip n))),
      ("m3wfbranchesoutput", Lean.toJson (toString (M3WellFoundedOracle.branches branchN))),
      ("m3wfshiftoutput", Lean.toJson (toString (M3WellFoundedOracle.shiftedMeasure n))),
      ("m3wfdefaultoutput", Lean.toJson (toString (M3WellFoundedOracle.defaultDecrease n)))]
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_WELL_FOUNDED: PASS checked arithmetic decreases, ordered proof goals, nonidentity measure, default proof, successor equation, semantic refusals and five-target emission; runtime parity follows"
