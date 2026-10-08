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


def psBehavioralModuleInterfaceContract : String :=
  "psc-behavioral-module-interface/1"

structure PsBehavioralModuleInterface where
  contract : String
  specificationKey : String
  effectKey : String
  resourceKey : String
  assumptionKey : String

def psBehavioralModuleInterfaceV1
    (specificationKey effectKey resourceKey assumptionKey : String) :
    PsBehavioralModuleInterface :=
  PsBehavioralModuleInterface.mk
    psBehavioralModuleInterfaceContract
    specificationKey
    effectKey
    resourceKey
    assumptionKey

def psBehavioralModuleInterfaceEq
    (left right : PsBehavioralModuleInterface) :
    Bool :=
  if psStringEq left.contract right.contract then
    if psStringEq left.specificationKey right.specificationKey then
      if psStringEq left.effectKey right.effectKey then
        if psStringEq left.resourceKey right.resourceKey then
          psStringEq left.assumptionKey right.assumptionKey
        else
          false
      else
        false
    else
      false
  else
    false

structure PsCertifiedModuleInterface where
  structural : PsModuleInterfaceFingerprint
  behavioral : Option PsBehavioralModuleInterface

def psCertifiedModuleInterfaceV1
    (structural : PsModuleInterfaceFingerprint)
    (behavioral : Option PsBehavioralModuleInterface) :
    PsCertifiedModuleInterface :=
  PsCertifiedModuleInterface.mk
    structural
    behavioral
