import Ps.Foundation.Name

structure PsModuleInterfaceFingerprint where
  contract : String
  semanticKey : String
  assumptionKey : String

def psStructuralModuleInterfaceContract : String :=
  "psc-structural-module-interface/1"

def psModuleInterfaceFingerprintV1
    (semanticKey : String) :
    PsModuleInterfaceFingerprint :=
  PsModuleInterfaceFingerprint.mk
    psStructuralModuleInterfaceContract
    semanticKey
    ""

def psModuleInterfaceFingerprintEq
    (left right : PsModuleInterfaceFingerprint) :
    Bool :=
  if psStringEq left.contract right.contract then
    if psStringEq left.semanticKey right.semanticKey then
      psStringEq left.assumptionKey right.assumptionKey
    else
      false
  else
    false
