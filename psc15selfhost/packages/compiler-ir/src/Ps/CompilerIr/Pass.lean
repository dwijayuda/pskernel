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

structure PsPassExecution where
  passDefinitionId : String
  inputIdentity : String
  outputIdentity : String
  evidence : List PsPassEvidenceRef

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
