import Ps.CompilerIr.Link

def psInterfaceTestNat : PsVerifiedIrType := .primitive .nat
def psInterfaceTestBool : PsVerifiedIrType := .primitive .bool
def psInterfaceTestPolicy : PsInterfaceIrPolicy :=
  PsInterfaceIrPolicy.mk "javascript" ["filesystem"]

def psInterfaceTestDecl (name : String) (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration :=
  PsVerifiedIrDeclaration.mk name [] [] psInterfaceTestNat body

def psInterfaceTestImport (source : String) : PsVerifiedIrExternalImport :=
  PsVerifiedIrExternalImport.mk "dependency" source "value" psInterfaceTestNat

def psInterfaceTestUnit (name : String) (imports : List PsVerifiedIrExternalImport)
    (capabilities : List String) : PsIrLinkUnit :=
  PsIrLinkUnit.mk name
    (PsErasedIrModule.mk (PsVerifiedIrModule.mk imports [] []
      [psInterfaceTestDecl "value" (.literal (.natural 7))]))
    ["value"] capabilities

def psInterfaceTestHost : PsInterfaceIrContract :=
  PsInterfaceIrContract.mk "host" "psc-runtime-semantics/1" "psc-runtime-values/1"
    ["javascript"] ["filesystem"] (.host "test-host-assumption") [] []
    [PsInterfaceIrExport.mk "value" psInterfaceTestNat]

def psInterfaceTestModule : PsErasedIrModule :=
  (psInterfaceTestUnit "consumer" [psInterfaceTestImport "host"] ["filesystem"]).erased

def psInterfaceTestAccept {alpha : Type} (value : Except PsInterfaceIrError alpha) : Bool :=
  match value with
  | .ok _ => true
  | .error _ => false

def psInterfaceTestReject {alpha : Type} (value : Except PsInterfaceIrError alpha) : Bool :=
  if psInterfaceTestAccept value then false else true

def psInterfaceTestValidate (provider : PsInterfaceIrContract) :
    Except PsInterfaceIrError PsValidatedIrModule :=
  psValidateErasedIrModuleWithInterfaces psInterfaceTestPolicy [provider] psInterfaceTestModule

def psInterfaceTestDefaultReject : Bool :=
  match psValidateErasedIrModule psInterfaceTestModule with
  | .error (.invalidExternalImport _) => true
  | _ => false

def psInterfaceTestLayout (fieldType : PsVerifiedIrType) : Bool :=
  let box := PsVerifiedIrStructure.mk "Box" [] [PsVerifiedIrStructureField.mk "value" fieldType];
  let envelope := PsVerifiedIrStructure.mk "Envelope" []
    [PsVerifiedIrStructureField.mk "box" (.named "Box" [])];
  let goodBox := PsVerifiedIrStructure.mk "Box" []
    [PsVerifiedIrStructureField.mk "value" psInterfaceTestNat];
  let signature := PsVerifiedIrType.function [.named "Envelope" []] psInterfaceTestNat;
  let provider := { psInterfaceTestHost with
    structures := [box, envelope]
    exports := [PsInterfaceIrExport.mk "value" signature] };
  let module := PsErasedIrModule.mk (PsVerifiedIrModule.mk
    [PsVerifiedIrExternalImport.mk "read" "host" "value" signature] [goodBox, envelope] [] []);
  psInterfaceTestAccept (psValidateErasedIrModuleWithInterfaces psInterfaceTestPolicy [provider] module)

def psInterfaceTestRecursiveLayout : Bool :=
  let tree := PsVerifiedIrInductive.mk "Tree" []
    [PsVerifiedIrConstructor.mk "leaf" [],
      PsVerifiedIrConstructor.mk "node" [PsVerifiedIrConstructorField.mk "next" (.named "Tree" [])]];
  let signature := PsVerifiedIrType.function [.named "Tree" []] psInterfaceTestNat;
  let provider := { psInterfaceTestHost with
    inductives := [tree]
    exports := [PsInterfaceIrExport.mk "value" signature] };
  let module := PsErasedIrModule.mk (PsVerifiedIrModule.mk
    [PsVerifiedIrExternalImport.mk "read" "host" "value" signature] [] [tree] []);
  psInterfaceTestAccept (psValidateErasedIrModuleWithInterfaces psInterfaceTestPolicy [provider] module)

def psInterfaceTestLinkOrder : Bool :=
  let provider := psInterfaceTestUnit "provider" [] [];
  let consumer := psInterfaceTestUnit "consumer" [psInterfaceTestImport "provider"] [];
  match psValidateIrLink psInterfaceTestPolicy [] [consumer, provider] with
  | .ok linked =>
      match linked.modules with
      | [first, second] =>
          if psStringEq first.moduleId "provider" then psStringEq second.moduleId "consumer" else false
      | _ => false
  | .error _ => false

def psInterfaceTestCycle : Bool :=
  let left := psInterfaceTestUnit "left" [psInterfaceTestImport "right"] [];
  let right := psInterfaceTestUnit "right" [psInterfaceTestImport "left"] [];
  match psValidateIrLink psInterfaceTestPolicy [] [left, right] with
  | .error (.dependencyCycle _) => true
  | _ => false

def psInterfaceTestTransitiveCapability : Bool :=
  let provider := psInterfaceTestUnit "provider" [psInterfaceTestImport "host"] ["filesystem"];
  let consumer := psInterfaceTestUnit "consumer" [psInterfaceTestImport "provider"] [];
  match psValidateIrLink psInterfaceTestPolicy [psInterfaceTestHost] [provider, consumer] with
  | .error (.capabilityDenied _) => true
  | _ => false

def psInterfaceTestInvalidBody : Bool :=
  let unit := psInterfaceTestUnit "bad" [] [];
  let invalid := { unit with
    erased := PsErasedIrModule.mk
      (PsVerifiedIrModule.mk [] [] [] [psInterfaceTestDecl "value" (.literal (.bool true))]) };
  match psValidateIrLink psInterfaceTestPolicy [] [invalid] with
  | .error (.invalidIr _) => true
  | _ => false

def psInterfaceTestGenericExport : Bool :=
  let unit := psInterfaceTestUnit "generic" [] [];
  let declaration := { psInterfaceTestDecl "value" (.literal (.natural 1)) with
    typeParameters := [PsVerifiedIrTypeParameter.mk "A"] };
  let invalid := { unit with erased := PsErasedIrModule.mk (PsVerifiedIrModule.mk [] [] [] [declaration]) };
  match psValidateIrLink psInterfaceTestPolicy [] [invalid] with
  | .error (.unsupportedGenericExport _) => true
  | _ => false

def psInterfaceTestCases : List (String × Bool) :=
  [ ("explicit host contract", psInterfaceTestAccept (psInterfaceTestValidate psInterfaceTestHost)),
    ("default validator rejects unbound imports", psInterfaceTestDefaultReject),
    ("missing dependency", psInterfaceTestReject
      (psValidateErasedIrModuleWithInterfaces psInterfaceTestPolicy [] psInterfaceTestModule)),
    ("missing export", psInterfaceTestReject (psInterfaceTestValidate { psInterfaceTestHost with exports := [] })),
    ("signature mismatch", psInterfaceTestReject (psInterfaceTestValidate
      { psInterfaceTestHost with exports := [PsInterfaceIrExport.mk "value" psInterfaceTestBool] })),
    ("ABI mismatch", psInterfaceTestReject (psInterfaceTestValidate { psInterfaceTestHost with abiProfile := "other" })),
    ("semantic mismatch", psInterfaceTestReject (psInterfaceTestValidate { psInterfaceTestHost with semanticProfile := "other" })),
    ("unavailable target", psInterfaceTestReject (psInterfaceTestValidate { psInterfaceTestHost with targets := ["rust"] })),
    ("capability denied", psInterfaceTestReject (psValidateErasedIrModuleWithInterfaces
      (PsInterfaceIrPolicy.mk "javascript" []) [psInterfaceTestHost] psInterfaceTestModule)),
    ("duplicate providers", psInterfaceTestReject (psValidateErasedIrModuleWithInterfaces
      psInterfaceTestPolicy [psInterfaceTestHost, psInterfaceTestHost] psInterfaceTestModule)),
    ("nested layout accepted", psInterfaceTestLayout psInterfaceTestNat),
    ("nested layout drift rejected", if psInterfaceTestLayout psInterfaceTestBool then false else true),
    ("recursive layout accepted", psInterfaceTestRecursiveLayout),
    ("derived link order", psInterfaceTestLinkOrder),
    ("dependency cycle rejected", psInterfaceTestCycle),
    ("transitive capability required", psInterfaceTestTransitiveCapability),
    ("invalid implementation body rejected", psInterfaceTestInvalidBody),
    ("generic boundary is explicit", psInterfaceTestGenericExport),
    ("forged host origin rejected", psInterfaceTestReject (psValidateIrLink psInterfaceTestPolicy
      [{ psInterfaceTestHost with origin := .linkedModule }] [])),
    ("private export cannot link", psInterfaceTestReject (psValidateIrLink psInterfaceTestPolicy []
      [{ psInterfaceTestUnit "provider" [] [] with exportNames := [] },
        psInterfaceTestUnit "consumer" [psInterfaceTestImport "provider"] []])) ]

def main : IO Unit := do
  for (name, passed) in psInterfaceTestCases do
    if passed then IO.println ("PSCV_INTERFACE_IR_PASS: " ++ name)
    else throw (IO.userError ("PSCV_INTERFACE_IR_FAIL: " ++ name))
  IO.println "PSCV_INTERFACE_IR_TESTS: PASS"
