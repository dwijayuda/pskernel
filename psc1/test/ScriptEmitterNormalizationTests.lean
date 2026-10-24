import ScriptEmitterReference

private def natT : PsVerifiedIrType := .primitive .nat
private def boxT : PsVerifiedIrType := .named "Box" []
private def param (name : String) (type : PsVerifiedIrType) : PsVerifiedIrParameter :=
  { name := name, type := type }
private def natE (n : Nat) : PsVerifiedIrExpr := .literal (.natural n)

private def badModule : PsVerifiedIrModule :=
  { psVerifiedIrModuleEmpty with declarations := [{
      name := "forged"
      typeParameters := []
      parameters := []
      resultType := natT
      body := .literal (.bool true)
    }] }

private def boxLayout : PsVerifiedIrStructure := {
  name := "Box"
  typeParameters := []
  fields := [{ name := "value", type := natT }]
}

private def abiModule : PsVerifiedIrModule := {
  imports := []
  structures := [boxLayout]
  inductives := []
  declarations := [{
    name := "readBox"
    typeParameters := []
    parameters := [param "box" boxT]
    resultType := natT
    body := .projection "Box" [] (.var "box") "value"
  }]
}

private def captureBody : PsVerifiedIrExpr :=
  .letE "box" boxT (.record "Box" [] [("value", .var "n")])
    (.letE "closure" (.function [natT] natT)
      (.lambda [param "x" natT] natT
        (.intrinsic .natAdd [] [
          .projection "Box" [] (.var "box") "value", .var "x"]))
      (.letE "box" boxT (.record "Box" [] [("value", natE 1000)])
        (.call (.var "closure") [] [natE 1])))

private def captureModule : PsVerifiedIrModule := {
  imports := []
  structures := [boxLayout]
  inductives := []
  declarations := [{
    name := "answer"
    typeParameters := []
    parameters := [param "n" natT]
    resultType := natT
    body := captureBody
  }]
}

private def reorderedValues : PsVerifiedIrModule := {
  psVerifiedIrModuleEmpty with declarations := [
    { name := "answer", typeParameters := [], parameters := [], resultType := natT, body := .var "value" },
    { name := "value", typeParameters := [], parameters := [], resultType := natT, body := natE 42 }
  ]
}

private def shadowedValue : PsVerifiedIrModule := {
  psVerifiedIrModuleEmpty with declarations := [
    { name := "x", typeParameters := [], parameters := [], resultType := .primitive .bool,
      body := .literal (.bool true) },
    { name := "shadow", typeParameters := [], parameters := [param "x" (.primitive .bool)],
      resultType := .primitive .bool, body := .var "x" }
  ]
}

private def rejectWith (marker : String) (result : Except String α) : IO Unit :=
  match result with
  | .error message =>
      unless message.startsWith marker do
        throw (IO.userError ("wrong rejection: " ++ message))
  | .ok _ => throw (IO.userError ("unexpected acceptance: " ++ marker))

private def validate (raw : PsVerifiedIrModule) : IO PsValidatedIrModule :=
  match psStrictValidateModule raw with
  | .ok checked => pure checked
  | .error _ => throw (IO.userError "test fixture IR did not validate")

private def requireResult (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)


private def samePython (raw : PsVerifiedIrModule) (names : List String) (ioAbi : Bool) : IO Unit := do
  match psPythonEmitModule { raw := raw } names ioAbi,
      PsScriptEmitterReference.Python.psPythonEmitModule { raw := raw } names ioAbi with
  | Except.error a, Except.error b =>
      unless a == b do throw (IO.userError "Python error identity")
  | Except.ok a, Except.ok b =>
      unless a.source == b.source && a.stub == b.stub &&
          a.runtimeSource == b.runtimeSource && a.runtimeHelpers == b.runtimeHelpers &&
          a.declarationLines == b.declarationLines do
        throw (IO.userError "Python retained-emitter output identity")
  | _, _ => throw (IO.userError "Python acceptance changed")

private def samePhp (raw : PsVerifiedIrModule) (names : List String) (ioAbi : Bool)
    (label : Nat) : IO Unit := do
  let reference := PsScriptEmitterReference.Php.psPhpEmitValidatedModule { raw := raw } names ioAbi
  let legacy := psPhpEmitModuleWithIoAndCapturePolicy { raw := raw } names ioAbi false
  match legacy, reference with
  | Except.error a, Except.error b =>
      unless a == b do throw (IO.userError "PHP legacy error identity")
  | Except.ok a, Except.ok b =>
      unless a.source == b.source && a.composer == b.composer &&
          a.runtimeSource == b.runtimeSource && a.runtimeVersion == b.runtimeVersion &&
          a.runtimeRequirements == b.runtimeRequirements && a.declarations == b.declarations &&
          a.declarationLines == b.declarationLines do
        throw (IO.userError "PHP complete retained-emitter fallback identity")
  | _, _ => throw (IO.userError "PHP legacy acceptance changed")
  match psPhpEmitValidatedModule { raw := raw } names ioAbi, reference with
  | Except.error a, Except.error b =>
      unless a == b do throw (IO.userError "PHP production error identity")
  | Except.ok a, Except.ok b =>
      unless a.composer == b.composer && a.runtimeSource == b.runtimeSource &&
          a.runtimeVersion == b.runtimeVersion && a.runtimeRequirements == b.runtimeRequirements &&
          a.declarations == b.declarations && a.declarationLines == b.declarationLines do
        throw (IO.userError "PHP non-source metadata changed")
      IO.FS.createDirAll "dist/script-emitter-comparison"
      let actual := s!"dist/script-emitter-comparison/{label}.actual.php"
      let expected := s!"dist/script-emitter-comparison/{label}.reference.php"
      IO.FS.writeFile actual a.source
      IO.FS.writeFile expected b.source
      let result <- IO.Process.output {
        cmd := "php"
        args := #["scripts/php-capture-token-comparison.php", actual, expected]
      }
      unless result.exitCode == 0 do
        throw (IO.userError ("PHP token/capture delta: " ++ result.stdout ++ result.stderr))
  | _, _ => throw (IO.userError "PHP production acceptance changed")

def main : IO Unit := do
  let mut cases := 0
  for raw in [badModule, abiModule, captureModule, psVerifiedIrModuleEmpty, reorderedValues, shadowedValue] do
    for names in [[], ["answer"], ["readBox"], ["x", "shadow"], ["answer", "answer"], ["missing"]] do
      for ioAbi in [false, true] do
        samePython raw names ioAbi
        samePhp raw names ioAbi cases
        cases := cases + 2
  IO.println s!"PSC1_SCRIPT_EMITTER_NORMALIZATION: {cases} retained-emitter/fallback output/refusal comparisons and production global-capture token boundaries passed"
