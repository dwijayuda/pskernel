import Ps.Bridge.Codec

def psKernelBridgeProtocol : String :=
  "proofscript-kernel-bridge"

def psKernelBridgeVersion : Nat := 1

def psKernelBridgeKernelFingerprint : String :=
  "lean-ts-kernel@0.1.0"

def psKernelBridgeFoundationFingerprint : String :=
  "lean4:v4.34.0@293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"

inductive PsKernelBridgeRequest where
  | ping
  | lookup (name : PsName)
  | infer (expr : PsExpr)
  | defeq (left right : PsExpr)
  | replayAdmissions (declarations : List PsDeclaration)

inductive PsKernelBridgeProtocolError where
  | json (error : PsJsonParseError)
  | codec (error : PsCodecDecodeError)
  | encode (error : PsCheckedAdmissionCodecError)
  | missingField (name : String)
  | invalidField (name : String)
  | protocolMismatch
  | versionMismatch
  | kernelFingerprintMismatch
  | foundationFingerprintMismatch
  | remoteError (message : String)

structure PsKernelBridgeResponse where
  value : Option PsJsonValue

def psKernelBridgeEnvelope
    (op : String)
    (payload : String) : String :=
  psJsonObject [
    ("foundation",
      psJsonQuote psKernelBridgeFoundationFingerprint),
    ("kernel",
      psJsonQuote psKernelBridgeKernelFingerprint),
    ("op", psJsonQuote op),
    ("payload", payload),
    ("protocol", psJsonQuote psKernelBridgeProtocol),
    ("version", toString psKernelBridgeVersion)
  ]

def psEncodeKernelBridgeRequest
    (request : PsKernelBridgeRequest) :
    Except PsKernelBridgeProtocolError String :=
  match request with
  | .ping =>
      Except.ok
        (psKernelBridgeEnvelope
          "ping"
          (psJsonObject []))
  | .lookup name =>
      Except.ok
        (psKernelBridgeEnvelope
          "lookup"
          (psJsonObject [
            ("name", psEncodeCodecName name)
          ]))
  | .infer expr =>
      match psEncodeCodecExpr expr with
      | Except.error error =>
          Except.error (PsKernelBridgeProtocolError.encode error)
      | Except.ok encoded =>
          Except.ok
            (psKernelBridgeEnvelope
              "infer"
              (psJsonObject [
                ("expr", encoded)
              ]))
  | .defeq left right =>
      match
          psEncodeCodecExpr left,
          psEncodeCodecExpr right with
      | Except.ok encodedLeft, Except.ok encodedRight =>
          Except.ok
            (psKernelBridgeEnvelope
              "defeq"
              (psJsonObject [
                ("left", encodedLeft),
                ("right", encodedRight)
              ]))
      | Except.error error, _ =>
          Except.error (PsKernelBridgeProtocolError.encode error)
      | _, Except.error error =>
          Except.error (PsKernelBridgeProtocolError.encode error)
  | .replayAdmissions declarations =>
      match psEncodeCheckedAdmissionsCanonical declarations with
      | Except.error error =>
          Except.error (PsKernelBridgeProtocolError.encode error)
      | Except.ok encoded =>
          Except.ok
            (psKernelBridgeEnvelope
              "replay"
              encoded)

def psKernelBridgeRequireField
    (value : PsJsonValue)
    (name : String) :
    Except PsKernelBridgeProtocolError PsJsonValue :=
  match psJsonGetField value name with
  | none =>
      Except.error
        (PsKernelBridgeProtocolError.missingField name)
  | some field => Except.ok field

def psKernelBridgeRequireString
    (value : PsJsonValue)
    (name : String) :
    Except PsKernelBridgeProtocolError String :=
  match psKernelBridgeRequireField value name with
  | Except.error error => Except.error error
  | Except.ok field =>
      match psJsonAsString field with
      | none =>
          Except.error
            (PsKernelBridgeProtocolError.invalidField name)
      | some text => Except.ok text

def psKernelBridgeRequireNumberText
    (value : PsJsonValue)
    (name : String) :
    Except PsKernelBridgeProtocolError String :=
  match psKernelBridgeRequireField value name with
  | Except.error error => Except.error error
  | Except.ok field =>
      match psJsonAsNumberText field with
      | none =>
          Except.error
            (PsKernelBridgeProtocolError.invalidField name)
      | some text => Except.ok text

def psKernelBridgeValidateEnvelope
    (value : PsJsonValue) :
    Except PsKernelBridgeProtocolError Unit :=
  match
      psKernelBridgeRequireString value "protocol",
      psKernelBridgeRequireNumberText value "version",
      psKernelBridgeRequireString value "kernel",
      psKernelBridgeRequireString value "foundation" with
  | Except.ok protocol,
    Except.ok version,
    Except.ok kernel,
    Except.ok foundation =>
      if protocol != psKernelBridgeProtocol then
        Except.error PsKernelBridgeProtocolError.protocolMismatch
      else if version != toString psKernelBridgeVersion then
        Except.error PsKernelBridgeProtocolError.versionMismatch
      else if kernel != psKernelBridgeKernelFingerprint then
        Except.error
          PsKernelBridgeProtocolError.kernelFingerprintMismatch
      else if foundation != psKernelBridgeFoundationFingerprint then
        Except.error
          PsKernelBridgeProtocolError.foundationFingerprintMismatch
      else
        Except.ok ()
  | Except.error error, _, _, _ => Except.error error
  | _, Except.error error, _, _ => Except.error error
  | _, _, Except.error error, _ => Except.error error
  | _, _, _, Except.error error => Except.error error

def psDecodeKernelBridgeResponse
    (source : String) :
    Except PsKernelBridgeProtocolError PsKernelBridgeResponse :=
  match psJsonParse source with
  | Except.error error =>
      Except.error (PsKernelBridgeProtocolError.json error)
  | Except.ok value =>
      match psKernelBridgeValidateEnvelope value with
      | Except.error error => Except.error error
      | Except.ok _ =>
          match psKernelBridgeRequireField value "ok" with
          | Except.error error => Except.error error
          | Except.ok okValue =>
              match psJsonAsBool okValue with
              | none =>
                  Except.error
                    (PsKernelBridgeProtocolError.invalidField "ok")
              | some false =>
                  match psKernelBridgeRequireString value "error" with
                  | Except.error error => Except.error error
                  | Except.ok message =>
                      Except.error
                        (PsKernelBridgeProtocolError.remoteError
                          message)
              | some true =>
                  match psJsonGetField value "value" with
                  | none =>
                      Except.ok { value := none }
                  | some PsJsonValue.nullE =>
                      Except.ok { value := none }
                  | some responseValue =>
                      Except.ok { value := some responseValue }

def psKernelBridgeResponseExpr
    (response : PsKernelBridgeResponse) :
    Except PsKernelBridgeProtocolError PsExpr :=
  match response.value with
  | none =>
      Except.error
        (PsKernelBridgeProtocolError.missingField "value")
  | some value =>
      match psDecodeCodecExpr value with
      | Except.error error =>
          Except.error (PsKernelBridgeProtocolError.codec error)
      | Except.ok expr => Except.ok expr

def psKernelBridgeResponseBool
    (response : PsKernelBridgeResponse) :
    Except PsKernelBridgeProtocolError Bool :=
  match response.value with
  | some (PsJsonValue.bool value) => Except.ok value
  | _ =>
      Except.error
        (PsKernelBridgeProtocolError.invalidField "value")
