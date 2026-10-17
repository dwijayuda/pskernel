import Ps.Host.NativeV7
import Ps.Syntax.PrintLean
import Ps.Syntax.PrintProofScript
import Lean.Compiler.NoncomputableAttr
import Lean.Util.CollectAxioms

-- Pinned 4.35.0: NoncomputableAttr, PreDefinition/Basic, MutualDef and
-- Compiler/LCNF/ToLCNF; native controls mirror usesOfNoncomputable.lean.
namespace M3NoncomputableOracle

noncomputable def specNat (_ : Unit) : Nat := Classical.ofNonempty
noncomputable def SpecType : Type := Nat
noncomputable def specIdentity (n : Nat) : Nat := n
noncomputable def specProof (n : Nat) : n = n := rfl

def keep (n : SpecType) (_ : specNat () = specNat ()) : SpecType := n
def output (flag : Bool) : UInt64 :=
  UInt64.ofNat (keep (if flag then 17 else 29) rfl)

/-- error: depends on -/
#guard_msgs (error, drop warning, substring := true) in
def bad : Nat := specIdentity 3

/-- error: cannot mix computable and non-computable definitions -/
#guard_msgs (error, drop warning, substring := true) in
mutual
  noncomputable def mixedLeft (n : Nat) := n
  def mixedRight (n : Nat) := n
end

run_cmd do
  let environment ← Lean.getEnv
  unless Lean.isNoncomputable environment ``specNat &&
      Lean.isNoncomputable environment ``specIdentity do
    throwError "native noncomputable metadata disappeared"
  let axioms ← Lean.collectAxioms ``specNat
  unless axioms.contains ``Classical.choice &&
      axioms.all (fun name => name == ``propext || name == ``Quot.sound ||
        name == ``Classical.choice) do
    throwError "noncomputable choice escaped approved foundation: {axioms}"

end M3NoncomputableOracle

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def declarationsSource : String :=
  "noncomputable function specNat(): Nat := Classical.ofNonempty\n" ++
  "noncomputable def SpecType: Type := Nat\n" ++
  "noncomputable function specIdentity(n: Nat): Nat := n\n" ++
  "noncomputable function specProof(n: Nat): Eq(n, n) := by { rfl }\n" ++
  "function keep(n: SpecType, h: Eq(specNat(()), specNat(()))): SpecType := n\n"

private def source : String :=
  declarationsSource ++
  "theorem proofUse(n: Nat): Eq(n, n) := by { exact specProof(n) }\n" ++
  "function m3noncomp(flag: Bool): UInt64 := UInt64.ofNat(keep(if (flag) { 17 } else { 29 }, by { rfl }))\n"

private def genericSource : String :=
  "universe u\nsection\nvariable {A: Type u} [evidence: Nonempty(A)] (seed: A)\n" ++
  "noncomputable function scopedChoice(n: Nat): A := helper(n)\n" ++
  "where { def helper(k: Nat): A := Classical.ofNonempty }\n" ++
  "noncomputable function scopedValue(n: Nat): A := seed\nend\n"

private def checkMetadata : IO Unit := do
  let parsed ← fromExcept (psPscv0ParseProgram (source ++ genericSource))
  let compiled ← fromExcept ((psElabProgramWithOrigins
    psSelfHostProdPreludeEnvironment parsed).mapError psCompilerPscv0ElabError)
  let prepared ← fromExcept ((psCompilerPrepareElaborated compiled.result).mapError
    psCompilerPscv0Error)
  for name in ["specNat", "SpecType", "specIdentity", "specProof", "scopedChoice", "scopedValue"] do
    let name := psRootName name
    ensure (psEnvironmentIsNoncomputable compiled.result.environment name &&
      prepared.noncomputableNames.any (psNameEq name))
      ("noncomputable source policy was lost: " ++ psNameToString name)
    match psEnvironmentFind compiled.result.environment name with
    | some (.definitionDecl ..) => pure ()
    | _ => throw (IO.userError "noncomputable must remain a checked logical definition")
  let locals := compiled.origins.flatMap (fun origin => origin.localDefinitions)
  ensure (!locals.isEmpty && locals.all (fun localDefinition =>
      localDefinition.declarations.all (fun name =>
        prepared.noncomputableNames.any (psNameEq name))))
    "a noncomputable helper acquired an executable implementation"
  let ir ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared).mapError psCompilerPscv0Error)
  ensure (prepared.noncomputableNames.all (fun name =>
      !ir.declarations.any (fun declaration => declaration.name == psNameToString name)))
    "noncomputable implementation survived erasure"
  for command in parsed.commands do
    if let .declaration (.noncomputableDefinition name binders type value span) := command then
      let declaration := PsSyntaxDeclaration.noncomputableDefinition name binders type value span
      let .ok lean := psPrintLeanDeclaration declaration
        | throw (IO.userError "noncomputable Lean printing failed")
      let .ok proofscript := psPrintProofScriptDeclaration declaration
        | throw (IO.userError "noncomputable ProofScript printing failed")
      ensure (lean.startsWith "noncomputable def " && proofscript.startsWith "noncomputable def ")
        "source printer dropped the execution policy"
      let _ ← fromExcept (psPscv0ParseProgram (proofscript ++ "\n"))
      pure ()
  IO.println "PSCV0_M3_NONCOMP_METADATA: PASS native metadata, universe/section/helper ownership, preparation and proof/type erasure"

private def requestCases : List (String × PsV7Native.Request × Option (String × String)) :=
  let executable : PsV7Native.Request := {
    source, sourceName := "noncomputable.ps", outputStem := "noncomputable"
    exports := .selected ["m3noncomp"]
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] }
  let provider : PsPscv0ModuleSource := {
    name := "Spec", sourceName := "spec.ps"
    source := "private noncomputable function hidden(n: Nat): Nat := n\n" ++
      "noncomputable function visible(n: Nat): Nat := hidden(n)\n" }
  [("erased-proof-and-type", executable, none),
   ("generic-logical-only", { source := genericSource }, none),
   ("direct-computational-use", { executable with
      source := declarationsSource ++ "function bad(flag: Bool): Nat := specIdentity(3)\n" },
      some ("assurance", "PSCV0-NONCOMPUTABLE-EXEC:")),
   ("transitive-computational-use", { executable with
      source := declarationsSource ++ "function middle(n: Nat): Nat := specIdentity(n)\nfunction bad(flag: Bool): Nat := middle(3)\n" },
      some ("assurance", "PSCV0-NONCOMPUTABLE-EXEC:")),
   ("explicit-noncomputable-export", { executable with exports := .selected ["specIdentity"] },
      some ("assurance", "PSCV0-NONCOMPUTABLE-EXEC:")),
   ("imported-logical-only", { modules := [provider]
      source := "import Spec\ntheorem visibleRefl(n: Nat): Eq(visible(n), visible(n)) := by { rfl }\n" }, none),
   ("imported-computational-use", { executable with modules := [provider]
      source := "import Spec\nfunction bad(flag: Bool): Nat := visible(3)\n" },
      some ("assurance", "PSCV0-NONCOMPUTABLE-EXEC:")),
   ("mixed-main-modifiers", { source :=
      "mutual\nnoncomputable function left(n: Nat): Nat := n\nfunction right(n: Nat): Nat := n\nend\n" },
      some ("elaborate", "PSCV0-DATA: PSCV0-MUTUAL-STRATEGY:")),
   ("forbidden-recursion-suffix", { source :=
      "noncomputable function bad(n: Nat): Nat := n\npartial_fixpoint\n" },
      some ("parse", "PSCV0-REC-STRATEGY-01:")),
   ("verified-no-downgrade", { executable with assurance := .closedVerified },
      some ("assurance", "PSCV0-ASSURANCE-DOWNGRADE:"))]

def main (args : List String) : IO Unit := do
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "noncomputable fixture requires the pinned native toolchain"
  let [directory] := args | throw (IO.userError "usage: pscv0_m3_noncomputable DIRECTORY")
  checkMetadata
  let batch ← match ← PsV7Native.runBatch (requestCases.map (·.2.1)).toArray with
    | .ok batch => pure batch
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (batch.results.size == requestCases.length) "noncomputable batch omitted a case"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  for ((label, _, expected), result) in requestCases.zip batch.results.toList do
    match expected, result with
    | none, .ok result =>
      for artifact in result.artifacts do
        for file in artifact.files do
          match file.payload with
          | .text value => IO.FS.writeFile (directory / file.path) value
          | .binary value => IO.FS.writeBinFile (directory / file.path) value
    | some (phase, prefix), .error error =>
      ensure (error.phase == phase && error.message.startsWith prefix)
        (label ++ ": wrong boundary: " ++ error.phase ++ ": " ++ error.message)
    | none, .error error =>
      throw (IO.userError (label ++ ": " ++ error.phase ++ ": " ++ error.message))
    | some _, .ok _ => throw (IO.userError (label ++ ": invalid executable acquired artifacts"))
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj [("flag", Lean.toJson flag),
      ("m3noncomp", Lean.toJson (toString (M3NoncomputableOracle.output flag).toNat))]
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_NONCOMP: PASS checked logical definitions, erased proof/type use, imported/private policy retention, direct/transitive/export refusals and five-target emission; 10 runtime observations follow"
