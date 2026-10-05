import Ps.Project.QueryGraph

structure PsProjectSnapshotIdentity where
  schemaVersion : Nat
  projectIdentity : String
  languageEdition : String
  sourceProfile : String
  compilerIdentity : String
  runtimeSemantics : String
  kernelContract : String
  interfaceCodec : String
  sourceKeyCodec : String
  artifactAuthority : String
  artifactCodec : String

inductive PsProjectSnapshotIdentityField where
  | schemaVersion
  | projectIdentity
  | languageEdition
  | sourceProfile
  | compilerIdentity
  | runtimeSemantics
  | kernelContract
  | interfaceCodec
  | sourceKeyCodec
  | artifactAuthority
  | artifactCodec

inductive PsProjectSnapshotIdentityError where
  | emptyProjectIdentity
  | emptyCompilerIdentity
  | mismatch
      (field : PsProjectSnapshotIdentityField)

structure PsProjectSnapshotEnvelope where
  identity : PsProjectSnapshotIdentity
  query : PsQuerySnapshot

def psProjectSnapshotSchemaVersion : Nat :=
  1

def psProjectSnapshotLanguageEdition : String :=
  "ps-0.9-r3"

def psProjectSnapshotSourceProfile : String :=
  "ps-standard-0.9-r3"

def psProjectSnapshotRuntimeSemantics : String :=
  "RuntimeSemantics-v1"

def psProjectSnapshotKernelContract : String :=
  "proofscript-kernel-contract/1"

def psProjectSnapshotInterfaceCodec : String :=
  "proofscript-checked-admissions/2"

def psProjectSnapshotSourceKeyCodec : String :=
  "utf8-source-text/1"

def psProjectSnapshotArtifactAuthority : String :=
  "elaborated-declarations-unchecked/1"

def psProjectSnapshotArtifactCodec : String :=
  "elaborated-declarations/1"

def psProjectSnapshotIdentityV1
    (projectIdentity : String)
    (compilerIdentity : String) :
    PsProjectSnapshotIdentity :=
  {
    schemaVersion := psProjectSnapshotSchemaVersion
    projectIdentity := projectIdentity
    languageEdition := psProjectSnapshotLanguageEdition
    sourceProfile := psProjectSnapshotSourceProfile
    compilerIdentity := compilerIdentity
    runtimeSemantics := psProjectSnapshotRuntimeSemantics
    kernelContract := psProjectSnapshotKernelContract
    interfaceCodec := psProjectSnapshotInterfaceCodec
    sourceKeyCodec := psProjectSnapshotSourceKeyCodec
    artifactAuthority := psProjectSnapshotArtifactAuthority
    artifactCodec := psProjectSnapshotArtifactCodec
  }

def psProjectSnapshotIdentityValidate
    (identity : PsProjectSnapshotIdentity) :
    Except PsProjectSnapshotIdentityError Unit :=
  if psStringEq identity.projectIdentity "" then
    Except.error
      PsProjectSnapshotIdentityError.emptyProjectIdentity
  else if psStringEq identity.compilerIdentity "" then
    Except.error
      PsProjectSnapshotIdentityError.emptyCompilerIdentity
  else
    Except.ok Unit.unit

def psProjectSnapshotIdentityMatch
    (expected : PsProjectSnapshotIdentity)
    (actual : PsProjectSnapshotIdentity) :
    Except PsProjectSnapshotIdentityError Unit :=
  if Nat.beq expected.schemaVersion actual.schemaVersion then
    if psStringEq
        expected.projectIdentity
        actual.projectIdentity then
      if psStringEq
          expected.languageEdition
          actual.languageEdition then
        if psStringEq
            expected.sourceProfile
            actual.sourceProfile then
          if psStringEq
              expected.compilerIdentity
              actual.compilerIdentity then
            if psStringEq
                expected.runtimeSemantics
                actual.runtimeSemantics then
              if psStringEq
                  expected.kernelContract
                  actual.kernelContract then
                if psStringEq
                    expected.interfaceCodec
                    actual.interfaceCodec then
                  if psStringEq
                      expected.sourceKeyCodec
                      actual.sourceKeyCodec then
                    if psStringEq
                        expected.artifactAuthority
                        actual.artifactAuthority then
                      if psStringEq
                          expected.artifactCodec
                          actual.artifactCodec then
                        Except.ok Unit.unit
                      else
                        Except.error
                          (PsProjectSnapshotIdentityError.mismatch
                            PsProjectSnapshotIdentityField.artifactCodec)
                    else
                      Except.error
                        (PsProjectSnapshotIdentityError.mismatch
                          PsProjectSnapshotIdentityField.artifactAuthority)
                  else
                    Except.error
                      (PsProjectSnapshotIdentityError.mismatch
                        PsProjectSnapshotIdentityField.sourceKeyCodec)
                else
                  Except.error
                    (PsProjectSnapshotIdentityError.mismatch
                      PsProjectSnapshotIdentityField.interfaceCodec)
              else
                Except.error
                  (PsProjectSnapshotIdentityError.mismatch
                    PsProjectSnapshotIdentityField.kernelContract)
            else
              Except.error
                (PsProjectSnapshotIdentityError.mismatch
                  PsProjectSnapshotIdentityField.runtimeSemantics)
          else
            Except.error
              (PsProjectSnapshotIdentityError.mismatch
                PsProjectSnapshotIdentityField.compilerIdentity)
        else
          Except.error
            (PsProjectSnapshotIdentityError.mismatch
              PsProjectSnapshotIdentityField.sourceProfile)
      else
        Except.error
          (PsProjectSnapshotIdentityError.mismatch
            PsProjectSnapshotIdentityField.languageEdition)
    else
      Except.error
        (PsProjectSnapshotIdentityError.mismatch
          PsProjectSnapshotIdentityField.projectIdentity)
  else
    Except.error
      (PsProjectSnapshotIdentityError.mismatch
        PsProjectSnapshotIdentityField.schemaVersion)

def psProjectSnapshotEnvelopeV1
    (projectIdentity : String)
    (compilerIdentity : String)
    (query : PsQuerySnapshot) :
    Except
      PsProjectSnapshotIdentityError
      PsProjectSnapshotEnvelope :=
  let identity :=
    psProjectSnapshotIdentityV1
      projectIdentity
      compilerIdentity
  match psProjectSnapshotIdentityValidate identity with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      Except.ok {
        identity := identity
        query := query
      }

def psProjectSnapshotEnvelopeAccepts
    (expected : PsProjectSnapshotIdentity)
    (envelope : PsProjectSnapshotEnvelope) :
    Except PsProjectSnapshotIdentityError Unit :=
  match
      psProjectSnapshotIdentityValidate
        expected with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psProjectSnapshotIdentityValidate
            envelope.identity with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psProjectSnapshotIdentityMatch
            expected
            envelope.identity
