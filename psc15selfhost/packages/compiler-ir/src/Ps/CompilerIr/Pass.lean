inductive PsPassEvidenceClass where
  | contract
  | validator
  | formalProof
  | differential

structure PsPassEvidenceRef where
  kind : PsPassEvidenceClass
  identity : String

structure PsPassDefinition where
  passId : String
  version : Nat
  inputContract : String
  outputContract : String
  semanticRelation : String
  resourceContract : String
  assuranceClass : String
  determinismClass : String
  totalityClass : String
  implementationId : String
  validatorId : Option String
  theoremIds : List String
  assumptionIds : List String

structure PsPassArtifactId where
  algorithm : String
  domain : String
  schemaVersion : Nat
  contract : String
  digest : String
  byteLength : Nat

structure PsPassSemanticFingerprint where
  contract : String
  sourceArtifact : PsPassArtifactId

structure PsPassResourceObservation where
  resource : String
  configured : Option Nat
  observed : Option Nat
  hostObserved : Bool

inductive PsPassBindingState where
  | unbound
  | requiresByteVerification

structure PsPassExecution where
  passDefinitionId : String
  inputIdentity : String
  outputIdentity : String
  evidence : List PsPassEvidenceRef
  bindingState : PsPassBindingState
  inputArtifacts : List PsPassArtifactId
  outputArtifacts : List PsPassArtifactId
  inputSemanticFingerprints : List PsPassSemanticFingerprint
  outputSemanticFingerprints : List PsPassSemanticFingerprint
  actionIdentity : Option PsPassArtifactId
  resourceObservation : List PsPassResourceObservation
  diagnostics : List String

def psPassExecution
    (definition : PsPassDefinition)
    (inputIdentity outputIdentity : String)
    (evidence : List PsPassEvidenceRef) :
    PsPassExecution :=
  PsPassExecution.mk
    definition.passId
    inputIdentity
    outputIdentity
    evidence
    PsPassBindingState.unbound
    List.nil
    List.nil
    List.nil
    List.nil
    Option.none
    List.nil
    List.nil

-- Portable transforms cannot certify caller-provided digests without bytes and
-- a hash implementation. This records supplied bindings explicitly as requiring
-- independent byte/evidence verification; it never mints checked authority.
def psPassExecutionWithArtifacts
    (definition : PsPassDefinition)
    (inputs outputs : List PsPassArtifactId)
    (inputFingerprints outputFingerprints : List PsPassSemanticFingerprint)
    (action : PsPassArtifactId)
    (resources : List PsPassResourceObservation)
    (diagnostics : List String)
    (evidence : List PsPassEvidenceRef) : PsPassExecution :=
  PsPassExecution.mk definition.passId "" "" evidence
    PsPassBindingState.requiresByteVerification inputs outputs
    inputFingerprints outputFingerprints (Option.some action) resources diagnostics
