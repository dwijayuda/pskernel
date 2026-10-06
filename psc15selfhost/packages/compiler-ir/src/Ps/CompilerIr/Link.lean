import Ps.CompilerIr.Interface

structure PsIrLinkUnit where
  moduleId : String
  erased : PsErasedIrModule
  exportNames : List String
  declaredCapabilities : List String

structure PsIrLinkedUnit where
  moduleId : String
  validated : PsValidatedIrModule

structure PsIrValidatedLink where
  policy : PsInterfaceIrPolicy
  interfaces : List PsInterfaceIrContract
  modules : List PsIrLinkedUnit

def psIrLinkExport (unit : PsIrLinkUnit) (name : String) :
    Except PsInterfaceIrError PsInterfaceIrExport :=
  match psStrictFindDeclaration unit.erased.raw.declarations name with
  | Option.none => Except.error (PsInterfaceIrError.missingExport unit.moduleId name)
  | Option.some declaration =>
      match declaration.typeParameters with
      | List.cons _ _ => Except.error (PsInterfaceIrError.unsupportedGenericExport name)
      | List.nil => Except.ok (PsInterfaceIrExport.mk name (psStrictDeclarationType declaration))

-- Export signatures are derived from actual declarations, never accepted as a
-- second, caller-supplied description of the compiled module.
def psIrLinkInterface (policy : PsInterfaceIrPolicy) (unit : PsIrLinkUnit) :
    Except PsInterfaceIrError PsInterfaceIrContract :=
  if psInterfaceNamesValid unit.exportNames then
    match psListMapExcept (psIrLinkExport unit) unit.exportNames with
    | Except.error error => Except.error error
    | Except.ok exports =>
        Except.ok (PsInterfaceIrContract.mk unit.moduleId
          "psc-runtime-semantics/1" "psc-runtime-values/1" [policy.target]
          unit.declaredCapabilities PsInterfaceIrOrigin.linkedModule
          unit.erased.raw.structures unit.erased.raw.inductives exports)
  else Except.error (PsInterfaceIrError.invalidContract unit.moduleId)

def psIrLinkValidateHost (value : PsInterfaceIrContract) :
    Except PsInterfaceIrError Unit :=
  match value.origin with
  | .linkedModule => Except.error (PsInterfaceIrError.invalidHostOrigin value.moduleId)
  | .host assumption =>
      if psInterfaceNonempty assumption then Except.ok Unit.unit
      else Except.error (PsInterfaceIrError.invalidHostOrigin value.moduleId)

def psIrLinkDependencyCapability (interfaces : List PsInterfaceIrContract)
    (unit : PsIrLinkUnit) (value : PsVerifiedIrExternalImport) :
    Except PsInterfaceIrError Unit :=
  match psInterfaceFind interfaces value.source with
  | Option.none => Except.error (PsInterfaceIrError.missingInterface value.source)
  | Option.some provider =>
      if psInterfaceSubset provider.requiredCapabilities unit.declaredCapabilities then
        Except.ok Unit.unit
      else Except.error (PsInterfaceIrError.capabilityDenied unit.moduleId)

def psIrLinkValidateUnit (policy : PsInterfaceIrPolicy)
    (interfaces : List PsInterfaceIrContract) (unit : PsIrLinkUnit) :
    Except PsInterfaceIrError PsIrLinkedUnit :=
  match psListMapExcept (psIrLinkDependencyCapability interfaces unit) unit.erased.raw.imports with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psValidateErasedIrModuleWithInterfaces policy interfaces unit.erased with
      | Except.error error => Except.error error
      | Except.ok validated => Except.ok (PsIrLinkedUnit.mk unit.moduleId validated)

def psIrLinkUnitName (unit : PsIrLinkUnit) : String := unit.moduleId

def psIrLinkDependencyReady (moduleNames ready : List String)
    (value : PsVerifiedIrExternalImport) : Bool :=
  if psStrictStringInList value.source moduleNames then
    psStrictStringInList value.source ready
  else true

structure PsIrLinkOrderState where
  readyNames : List String
  orderedReverse : List PsIrLinkUnit
  deferredReverse : List PsIrLinkUnit

def psIrLinkOrderPass (moduleNames : List String)
    (pending : List PsIrLinkUnit) : PsIrLinkOrderState -> PsIrLinkOrderState :=
  match pending with
  | List.nil => fun (state : PsIrLinkOrderState) => state
  | List.cons unit rest =>
      let smaller : PsIrLinkOrderState -> PsIrLinkOrderState := psIrLinkOrderPass moduleNames rest;
      fun (state : PsIrLinkOrderState) =>
        if psInterfaceAll (psIrLinkDependencyReady moduleNames state.readyNames) unit.erased.raw.imports then
          smaller (PsIrLinkOrderState.mk
            (List.cons unit.moduleId state.readyNames)
            (List.cons unit state.orderedReverse) state.deferredReverse)
        else
          smaller (PsIrLinkOrderState.mk state.readyNames state.orderedReverse
            (List.cons unit state.deferredReverse))

-- A stable topological order rejects cycles, including self imports. Each pass
-- resolves at least one module, or fails; the outer structural bound is N + 1.
def psIrLinkOrderWithFuel (moduleNames : List String) (fuel : Nat) :
    List PsIrLinkUnit -> List String -> List PsIrLinkUnit ->
      Except PsInterfaceIrError (List PsIrLinkUnit) :=
  match fuel with
  | Nat.zero =>
      fun (_pending : List PsIrLinkUnit) (_ready : List String) (_ordered : List PsIrLinkUnit) =>
        Except.error (PsInterfaceIrError.dependencyCycle "")
  | Nat.succ remaining =>
      let smaller := psIrLinkOrderWithFuel moduleNames remaining;
      fun (pending : List PsIrLinkUnit) (ready : List String) (ordered : List PsIrLinkUnit) =>
        match pending with
        | List.nil => Except.ok (psListReverse ordered)
        | List.cons first _ =>
            let next := psIrLinkOrderPass moduleNames pending
              (PsIrLinkOrderState.mk ready ordered List.nil);
            if Nat.beq (psListLength next.deferredReverse) (psListLength pending) then
              Except.error (PsInterfaceIrError.dependencyCycle first.moduleId)
            else smaller (psListReverse next.deferredReverse) next.readyNames next.orderedReverse

def psValidateIrLink (policy : PsInterfaceIrPolicy)
    (hostInterfaces : List PsInterfaceIrContract) (units : List PsIrLinkUnit) :
    Except PsInterfaceIrError PsIrValidatedLink :=
  match psListMapExcept psIrLinkValidateHost hostInterfaces with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psListMapExcept (psIrLinkInterface policy) units with
      | Except.error error => Except.error error
      | Except.ok moduleInterfaces =>
          let interfaces := psListAppend hostInterfaces moduleInterfaces;
          match psInterfaceValidateContext policy interfaces with
          | Except.error error => Except.error error
          | Except.ok _ =>
              match psIrLinkOrderWithFuel (psListMap psIrLinkUnitName units)
                  (Nat.succ (psListLength units)) units List.nil List.nil with
              | Except.error error => Except.error error
              | Except.ok ordered =>
                  match psListMapExcept (psIrLinkValidateUnit policy interfaces) ordered with
                  | Except.error error => Except.error error
                  | Except.ok modules => Except.ok (PsIrValidatedLink.mk policy interfaces modules)
