import Ps.CompilerIr.Link
import Ps.CompilerIr.Decode

-- Construction data only: consumers choose the policy and pin host contracts.
structure PsIrLinkArtifact where
  policy : PsInterfaceIrPolicy
  hostInterfaces : List PsInterfaceIrContract
  units : List PsIrLinkUnit

def psIrJsonTexts (values : List String) : Except PsIrEncodeError String :=
  psIrJsonValues (psListMap psIrJsonText values)

def psIrJsonLinkOrigin (value : PsInterfaceIrOrigin) : Except PsIrEncodeError String :=
  match value with
  | PsInterfaceIrOrigin.host assumption => psIrJsonNode "host" [psIrJsonText assumption]
  | PsInterfaceIrOrigin.linkedModule => psIrJsonNode "linked" []

def psIrJsonLinkExport (value : PsInterfaceIrExport) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.name, psIrJsonType value.type]

def psIrJsonLinkHost (value : PsInterfaceIrContract) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.moduleId, psIrJsonText value.semanticProfile,
    psIrJsonText value.abiProfile, psIrJsonTexts value.targets,
    psIrJsonTexts value.requiredCapabilities, psIrJsonLinkOrigin value.origin,
    psIrJsonValues (psListMap psIrJsonStructure value.structures),
    psIrJsonValues (psListMap psIrJsonInductive value.inductives),
    psIrJsonValues (psListMap psIrJsonLinkExport value.exports)]

def psIrJsonLinkUnit (value : PsIrLinkUnit) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.moduleId, psIrJsonTexts value.exportNames,
    psIrJsonTexts value.declaredCapabilities, psIrEncodeModule value.erased.raw]

def psIrEncodeLinkArtifact (value : PsIrLinkArtifact) : Except PsIrEncodeError String :=
  psIrJsonNode "psc-ir-link-json/1" [
    psIrJsonValues [psIrJsonText value.policy.target, psIrJsonTexts value.policy.allowedCapabilities],
    psIrJsonValues (psListMap psIrJsonLinkHost value.hostInterfaces),
    psIrJsonValues (psListMap psIrJsonLinkUnit value.units)]

def psIrDecodeLinkPolicy (value : PsJsonValue) : Except PsIrDecodeError PsInterfaceIrPolicy :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsInterfaceIrPolicy :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap2 PsInterfaceIrPolicy.mk (psIrDecodeText (psIrDecodeItem 0 values))
        (psIrDecodeArray psIrDecodeText (psIrDecodeItem 1 values));
  psIrDecodeTuple 2 build value

def psIrDecodeLinkOrigin (value : PsJsonValue) : Except PsIrDecodeError PsInterfaceIrOrigin :=
  match value with
  | PsJsonValue.array values =>
      match psIrDecodeItem 0 values with
      | PsJsonValue.string tag =>
          if psStringEq tag "linked" then
            let build : List PsJsonValue -> Except PsIrDecodeError PsInterfaceIrOrigin :=
              fun (_items : List PsJsonValue) => Except.ok PsInterfaceIrOrigin.linkedModule;
            psIrDecodeTuple 1 build value
          else if psStringEq tag "host" then
            let build : List PsJsonValue -> Except PsIrDecodeError PsInterfaceIrOrigin :=
              fun (items : List PsJsonValue) =>
                psIrDecodeMap1 PsInterfaceIrOrigin.host (psIrDecodeText (psIrDecodeItem 1 items));
            psIrDecodeTuple 2 build value
          else Except.error PsIrDecodeError.schema
      | _ => Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeLinkExport (value : PsJsonValue) : Except PsIrDecodeError PsInterfaceIrExport :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsInterfaceIrExport :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap2 PsInterfaceIrExport.mk (psIrDecodeText (psIrDecodeItem 0 values))
        (psIrDecodeType (psIrDecodeItem 1 values));
  psIrDecodeTuple 2 build value

def psIrDecodeLinkHost (value : PsJsonValue) : Except PsIrDecodeError PsInterfaceIrContract :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsInterfaceIrContract :=
    fun (values : List PsJsonValue) =>
      match psIrDecodeText (psIrDecodeItem 0 values) with
      | Except.error error => Except.error error
      | Except.ok field0 =>
          match psIrDecodeText (psIrDecodeItem 1 values) with
          | Except.error error => Except.error error
          | Except.ok field1 =>
              match psIrDecodeText (psIrDecodeItem 2 values) with
              | Except.error error => Except.error error
              | Except.ok field2 =>
                  match psIrDecodeArray psIrDecodeText (psIrDecodeItem 3 values) with
                  | Except.error error => Except.error error
                  | Except.ok field3 =>
                      match psIrDecodeArray psIrDecodeText (psIrDecodeItem 4 values) with
                      | Except.error error => Except.error error
                      | Except.ok field4 =>
                          match psIrDecodeLinkOrigin (psIrDecodeItem 5 values) with
                          | Except.error error => Except.error error
                          | Except.ok field5 =>
                              match psIrDecodeArray psIrDecodeStructure (psIrDecodeItem 6 values) with
                              | Except.error error => Except.error error
                              | Except.ok field6 =>
                                  match psIrDecodeArray psIrDecodeInductive (psIrDecodeItem 7 values) with
                                  | Except.error error => Except.error error
                                  | Except.ok field7 =>
                                      match psIrDecodeArray psIrDecodeLinkExport (psIrDecodeItem 8 values) with
                                      | Except.error error => Except.error error
                                      | Except.ok field8 =>
                                          Except.ok (PsInterfaceIrContract.mk field0 field1 field2 field3 field4 field5 field6 field7 field8);
  psIrDecodeTuple 9 build value

def psIrDecodeLinkErased (value : PsJsonValue) : Except PsIrDecodeError PsErasedIrModule :=
  psIrDecodeMap1 PsErasedIrModule.mk (psIrDecodeModuleValue value)

def psIrDecodeLinkUnit (value : PsJsonValue) : Except PsIrDecodeError PsIrLinkUnit :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsIrLinkUnit :=
    fun (values : List PsJsonValue) =>
      let make : String -> List String -> List String -> PsErasedIrModule -> PsIrLinkUnit :=
        fun (name : String) (exports : List String) (capabilities : List String) (erased : PsErasedIrModule) =>
          PsIrLinkUnit.mk name erased exports capabilities;
      psIrDecodeMap4 make (psIrDecodeText (psIrDecodeItem 0 values))
        (psIrDecodeArray psIrDecodeText (psIrDecodeItem 1 values))
        (psIrDecodeArray psIrDecodeText (psIrDecodeItem 2 values))
        (psIrDecodeLinkErased (psIrDecodeItem 3 values));
  psIrDecodeTuple 4 build value

def psIrDecodeLinkArtifactValue (value : PsJsonValue) : Except PsIrDecodeError PsIrLinkArtifact :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsIrLinkArtifact :=
    fun (values : List PsJsonValue) =>
      match psIrDecodeItem 0 values with
      | PsJsonValue.string tag =>
          if psStringEq tag "psc-ir-link-json/1" then
            psIrDecodeMap3 PsIrLinkArtifact.mk (psIrDecodeLinkPolicy (psIrDecodeItem 1 values))
              (psIrDecodeArray psIrDecodeLinkHost (psIrDecodeItem 2 values))
              (psIrDecodeArray psIrDecodeLinkUnit (psIrDecodeItem 3 values))
          else Except.error PsIrDecodeError.schema
      | _ => Except.error PsIrDecodeError.schema;
  psIrDecodeTuple 4 build value

def psIrDecodeLinkArtifact (source : String) : Except PsIrDecodeError PsIrLinkArtifact :=
  if Nat.ble (String.utf8ByteSize source) 134217728 then
    match psJsonParse source with
    | Except.error error => Except.error (PsIrDecodeError.parse error)
    | Except.ok json =>
        match psIrDecodeLinkArtifactValue json with
        | Except.error error => Except.error error
        | Except.ok value =>
            match psIrEncodeLinkArtifact value with
            | Except.error _ => Except.error PsIrDecodeError.depthExhausted
            | Except.ok encoded =>
                if psStringEq encoded source then Except.ok value
                else Except.error PsIrDecodeError.nonCanonical
  else Except.error PsIrDecodeError.bytesExhausted

inductive PsIrLinkArtifactValidationError where
  | decode (error : PsIrDecodeError)
  | invalidLink (error : PsInterfaceIrError)

def psIrValidateEncodedLink (source : String) : Except PsIrLinkArtifactValidationError PsIrValidatedLink :=
  match psIrDecodeLinkArtifact source with
  | Except.error error => Except.error (PsIrLinkArtifactValidationError.decode error)
  | Except.ok value =>
      match psValidateIrLink value.policy value.hostInterfaces value.units with
      | Except.error error => Except.error (PsIrLinkArtifactValidationError.invalidLink error)
      | Except.ok linked => Except.ok linked
