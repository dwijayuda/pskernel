import Ps.Project.Snapshot

def psSnapshotFieldEq
    (left right : PsProjectSnapshotIdentityField) :
    Bool :=
  match left with
  | PsProjectSnapshotIdentityField.schemaVersion =>
      match right with
      | PsProjectSnapshotIdentityField.schemaVersion => true
      | _ => false
  | PsProjectSnapshotIdentityField.projectIdentity =>
      match right with
      | PsProjectSnapshotIdentityField.projectIdentity => true
      | _ => false
  | PsProjectSnapshotIdentityField.languageEdition =>
      match right with
      | PsProjectSnapshotIdentityField.languageEdition => true
      | _ => false
  | PsProjectSnapshotIdentityField.sourceProfile =>
      match right with
      | PsProjectSnapshotIdentityField.sourceProfile => true
      | _ => false
  | PsProjectSnapshotIdentityField.compilerIdentity =>
      match right with
      | PsProjectSnapshotIdentityField.compilerIdentity => true
      | _ => false
  | PsProjectSnapshotIdentityField.runtimeSemantics =>
      match right with
      | PsProjectSnapshotIdentityField.runtimeSemantics => true
      | _ => false
  | PsProjectSnapshotIdentityField.kernelContract =>
      match right with
      | PsProjectSnapshotIdentityField.kernelContract => true
      | _ => false
  | PsProjectSnapshotIdentityField.interfaceCodec =>
      match right with
      | PsProjectSnapshotIdentityField.interfaceCodec => true
      | _ => false
  | PsProjectSnapshotIdentityField.sourceKeyCodec =>
      match right with
      | PsProjectSnapshotIdentityField.sourceKeyCodec => true
      | _ => false
  | PsProjectSnapshotIdentityField.artifactAuthority =>
      match right with
      | PsProjectSnapshotIdentityField.artifactAuthority => true
      | _ => false
  | PsProjectSnapshotIdentityField.artifactCodec =>
      match right with
      | PsProjectSnapshotIdentityField.artifactCodec => true
      | _ => false

def psSnapshotMismatchIs
    (expected : PsProjectSnapshotIdentity)
    (actual : PsProjectSnapshotIdentity)
    (field : PsProjectSnapshotIdentityField) :
    Bool :=
  match psProjectSnapshotIdentityMatch expected actual with
  | Except.error
      (PsProjectSnapshotIdentityError.mismatch actualField) =>
      psSnapshotFieldEq field actualField
  | _ =>
      false

def psSnapshotExpectedIdentity :
    PsProjectSnapshotIdentity :=
  psProjectSnapshotIdentityV1
    "project-a"
    "compiler-a"

def psTestSnapshotExactIdentity : Bool :=
  match
      psProjectSnapshotIdentityMatch
        psSnapshotExpectedIdentity
        psSnapshotExpectedIdentity with
  | Except.ok _ => true
  | Except.error _ => false

def psTestSnapshotRejectsEmptyProject : Bool :=
  match
      psProjectSnapshotIdentityValidate
        (psProjectSnapshotIdentityV1 "" "compiler-a") with
  | Except.error
      PsProjectSnapshotIdentityError.emptyProjectIdentity =>
      true
  | _ =>
      false

def psTestSnapshotRejectsEmptyCompiler : Bool :=
  match
      psProjectSnapshotIdentityValidate
        (psProjectSnapshotIdentityV1 "project-a" "") with
  | Except.error
      PsProjectSnapshotIdentityError.emptyCompilerIdentity =>
      true
  | _ =>
      false

def psTestSnapshotSchemaMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with schemaVersion := 2 }
    PsProjectSnapshotIdentityField.schemaVersion

def psTestSnapshotProjectMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with projectIdentity := "project-b" }
    PsProjectSnapshotIdentityField.projectIdentity

def psTestSnapshotLanguageMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with languageEdition := "ps-next" }
    PsProjectSnapshotIdentityField.languageEdition

def psTestSnapshotProfileMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with sourceProfile := "profile-next" }
    PsProjectSnapshotIdentityField.sourceProfile

def psTestSnapshotCompilerMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with compilerIdentity := "compiler-b" }
    PsProjectSnapshotIdentityField.compilerIdentity

def psTestSnapshotRuntimeMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with runtimeSemantics := "RuntimeSemantics-v2" }
    PsProjectSnapshotIdentityField.runtimeSemantics

def psTestSnapshotKernelMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with kernelContract := "kernel-contract-next" }
    PsProjectSnapshotIdentityField.kernelContract

def psTestSnapshotInterfaceCodecMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with interfaceCodec := "interface-codec-next" }
    PsProjectSnapshotIdentityField.interfaceCodec

def psTestSnapshotSourceKeyCodecMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with sourceKeyCodec := "source-key-next" }
    PsProjectSnapshotIdentityField.sourceKeyCodec

def psTestSnapshotArtifactAuthorityMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with
        artifactAuthority := "checked-declarations/1" }
    PsProjectSnapshotIdentityField.artifactAuthority

def psTestSnapshotArtifactCodecMismatch : Bool :=
  psSnapshotMismatchIs
    psSnapshotExpectedIdentity
    { psSnapshotExpectedIdentity with artifactCodec := "artifact-codec-next" }
    PsProjectSnapshotIdentityField.artifactCodec

def psTestSnapshotEnvelopeValidation : Bool :=
  match
      psProjectSnapshotEnvelopeV1
        "project-a"
        "compiler-a"
        psQuerySnapshotEmpty with
  | Except.error _ =>
      false
  | Except.ok envelope =>
      match
          psProjectSnapshotEnvelopeAccepts
            psSnapshotExpectedIdentity
            envelope with
      | Except.ok _ => true
      | Except.error _ => false

structure PsProjectSnapshotNamedTest where
  name : String
  passed : Bool

def psProjectSnapshotTests :
    List PsProjectSnapshotNamedTest :=
  [
    { name := "exact identity accepted", passed := psTestSnapshotExactIdentity },
    { name := "empty project rejected", passed := psTestSnapshotRejectsEmptyProject },
    { name := "empty compiler rejected", passed := psTestSnapshotRejectsEmptyCompiler },
    { name := "schema mismatch rejected", passed := psTestSnapshotSchemaMismatch },
    { name := "project mismatch rejected", passed := psTestSnapshotProjectMismatch },
    { name := "language mismatch rejected", passed := psTestSnapshotLanguageMismatch },
    { name := "profile mismatch rejected", passed := psTestSnapshotProfileMismatch },
    { name := "compiler mismatch rejected", passed := psTestSnapshotCompilerMismatch },
    { name := "runtime mismatch rejected", passed := psTestSnapshotRuntimeMismatch },
    { name := "kernel mismatch rejected", passed := psTestSnapshotKernelMismatch },
    { name := "interface codec mismatch rejected", passed := psTestSnapshotInterfaceCodecMismatch },
    { name := "source-key codec mismatch rejected", passed := psTestSnapshotSourceKeyCodecMismatch },
    { name := "artifact authority mismatch rejected", passed := psTestSnapshotArtifactAuthorityMismatch },
    { name := "artifact codec mismatch rejected", passed := psTestSnapshotArtifactCodecMismatch },
    { name := "envelope accepts exact identity", passed := psTestSnapshotEnvelopeValidation }
  ]

def psRunProjectSnapshotTests
    (tests : List PsProjectSnapshotNamedTest) :
    IO Bool :=
  match tests with
  | List.nil =>
      pure true
  | List.cons test rest => do
      if test.passed then
        IO.println
          (String.Internal.append
            "PSC1_PROJECT_SNAPSHOT_PASS: "
            test.name)
      else
        IO.println
          (String.Internal.append
            "PSC1_PROJECT_SNAPSHOT_FAIL: "
            test.name)
      let restPassed ←
        psRunProjectSnapshotTests rest
      pure
        (if test.passed then
          restPassed
        else
          false)

def main : IO Unit := do
  let passed ←
    psRunProjectSnapshotTests
      psProjectSnapshotTests
  if passed then
    IO.println
      "PSC1_PROJECT_SNAPSHOT_TESTS: PASS"
  else
    throw
      (IO.userError
        "PSC1_PROJECT_SNAPSHOT_TESTS: FAIL")
