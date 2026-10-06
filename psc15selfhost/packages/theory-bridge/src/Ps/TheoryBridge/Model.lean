import Ps.Foundation.Name

def psTheoryBridgeContract : String :=
  "psc-theory-bridge/1"

structure PsTheorySymbolMap where
  sourceSymbol : String
  destinationSymbol : String

structure PsTheoryAxiomMap where
  sourceAxiom : String
  destinationAxiom : String

structure PsTheoryBridge where
  contract : String
  sourceTheoryId : String
  destinationTheoryId : String
  symbolMap : List PsTheorySymbolMap
  axiomMap : List PsTheoryAxiomMap
  unsupportedFeatures : List String
  preservationClaim : String
  preservationEvidence : List String

def psTheoryBridgeV1
    (sourceTheoryId destinationTheoryId : String)
    (symbolMap : List PsTheorySymbolMap)
    (axiomMap : List PsTheoryAxiomMap)
    (unsupportedFeatures : List String)
    (preservationClaim : String)
    (preservationEvidence : List String) :
    PsTheoryBridge :=
  PsTheoryBridge.mk
    psTheoryBridgeContract
    sourceTheoryId
    destinationTheoryId
    symbolMap
    axiomMap
    unsupportedFeatures
    preservationClaim
    preservationEvidence

def psTheoryBridgeWellFormed
    (bridge : PsTheoryBridge) :
    Bool :=
  if psStringEq bridge.contract psTheoryBridgeContract then
    if psStringEq bridge.sourceTheoryId "" then
      false
    else if psStringEq bridge.destinationTheoryId "" then
      false
    else if psStringEq bridge.preservationClaim "" then
      false
    else
      true
  else
    false

def psTheoryBridgeIdentity
    (theoryId : String) :
    PsTheoryBridge :=
  psTheoryBridgeV1
    theoryId
    theoryId
    List.nil
    List.nil
    List.nil
    "identity"
    (List.cons "definitionally-identical-theory-id" List.nil)
