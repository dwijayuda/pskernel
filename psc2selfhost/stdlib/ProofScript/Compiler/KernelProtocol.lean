import ProofScript.Data.Json

def kernelBridgeProtocol : String :=
  "proofscript-kernel-bridge"

def kernelBridgeVersionText : String :=
  "1"

def kernelBridgeKernelFingerprint : String :=
  "lean-ts-kernel@0.1.0"

def kernelBridgeFoundationFingerprint : String :=
  "lean4:v4.34.0@293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"

inductive KernelRequest where
  | ping
  | lookup (name : String)

structure KernelResponse where
  ok : Bool
  value : Option JsonValue
  error : Option String

inductive KernelProtocolError where
  | json (error : JsonError)
  | missingField (name : String)
  | invalidField (name : String)
  | protocolMismatch
  | versionMismatch
  | kernelFingerprintMismatch
  | foundationFingerprintMismatch

def kernelStringEq (left : String) (right : String) : Bool :=
  match orderingString left right with
  | Ordering.lt => false
  | Ordering.eq => true
  | Ordering.gt => false

def kernelJsonAsString (value : JsonValue) : Option String :=
  match value with
  | JsonValue.string text => Option.some text
  | _ => Option.none

def kernelJsonAsBool (value : JsonValue) : Option Bool :=
  match value with
  | JsonValue.bool flag => Option.some flag
  | _ => Option.none

def kernelJsonAsNumberText (value : JsonValue) : Option String :=
  match value with
  | JsonValue.number text => Option.some text
  | _ => Option.none

def kernelObjectAdd
    (fields : Result JsonValue JsonError)
    (key : String)
    (value : JsonValue) :
    Result JsonValue JsonError :=
  match fields with
  | Result.error error => Result.error error
  | Result.ok object => jsonObjectInsert key value object

def kernelLookupPayload
    (name : String) :
    Result JsonValue JsonError :=
  match
      jsonObjectInsert
        "name"
        (JsonValue.string name)
        JsonValue.objectNil with
  | Result.error error => Result.error error
  | Result.ok fields => Result.ok fields

def kernelRequestPayload
    (request : KernelRequest) :
    Result JsonValue JsonError :=
  match request with
  | KernelRequest.ping =>
      Result.ok JsonValue.objectNil
  | KernelRequest.lookup name =>
      kernelLookupPayload name

def kernelRequestOp (request : KernelRequest) : String :=
  match request with
  | KernelRequest.ping => "ping"
  | KernelRequest.lookup name => "lookup"

def kernelEnvelope
    (request : KernelRequest) :
    Result JsonValue JsonError :=
  match kernelRequestPayload request with
  | Result.error error => Result.error error
  | Result.ok payload =>
      let fields0 : Result JsonValue JsonError :=
        Result.ok JsonValue.objectNil;
      let fields1 : Result JsonValue JsonError :=
        kernelObjectAdd
          fields0
          "foundation"
          (JsonValue.string kernelBridgeFoundationFingerprint);
      let fields2 : Result JsonValue JsonError :=
        kernelObjectAdd
          fields1
          "kernel"
          (JsonValue.string kernelBridgeKernelFingerprint);
      let fields3 : Result JsonValue JsonError :=
        kernelObjectAdd
          fields2
          "op"
          (JsonValue.string (kernelRequestOp request));
      let fields4 : Result JsonValue JsonError :=
        kernelObjectAdd
          fields3
          "payload"
          payload;
      let fields5 : Result JsonValue JsonError :=
        kernelObjectAdd
          fields4
          "protocol"
          (JsonValue.string kernelBridgeProtocol);
      let fields6 : Result JsonValue JsonError :=
        kernelObjectAdd
          fields5
          "version"
          (JsonValue.number kernelBridgeVersionText);
      match fields6 with
      | Result.error error => Result.error error
      | Result.ok fields => Result.ok fields

def kernelEncodeRequest
    (request : KernelRequest) :
    Result String KernelProtocolError :=
  match kernelEnvelope request with
  | Result.error error =>
      Result.error (KernelProtocolError.json error)
  | Result.ok envelope =>
      match jsonEncodeCanonical envelope with
      | Result.error error =>
          Result.error (KernelProtocolError.json error)
      | Result.ok text => Result.ok text

def kernelRequireField
    (value : JsonValue)
    (name : String) :
    Result JsonValue KernelProtocolError :=
  match jsonObjectFind value name with
  | Option.none =>
      Result.error (KernelProtocolError.missingField name)
  | Option.some field => Result.ok field

def kernelRequireString
    (value : JsonValue)
    (name : String) :
    Result String KernelProtocolError :=
  match kernelRequireField value name with
  | Result.error error => Result.error error
  | Result.ok field =>
      match kernelJsonAsString field with
      | Option.none =>
          Result.error (KernelProtocolError.invalidField name)
      | Option.some text => Result.ok text

def kernelRequireBool
    (value : JsonValue)
    (name : String) :
    Result Bool KernelProtocolError :=
  match kernelRequireField value name with
  | Result.error error => Result.error error
  | Result.ok field =>
      match kernelJsonAsBool field with
      | Option.none =>
          Result.error (KernelProtocolError.invalidField name)
      | Option.some flag => Result.ok flag

def kernelRequireNumberText
    (value : JsonValue)
    (name : String) :
    Result String KernelProtocolError :=
  match kernelRequireField value name with
  | Result.error error => Result.error error
  | Result.ok field =>
      match kernelJsonAsNumberText field with
      | Option.none =>
          Result.error (KernelProtocolError.invalidField name)
      | Option.some text => Result.ok text

def kernelValidateEnvelope
    (value : JsonValue) :
    Result Unit KernelProtocolError :=
  match kernelRequireString value "protocol" with
  | Result.error error => Result.error error
  | Result.ok protocol =>
      if kernelStringEq protocol kernelBridgeProtocol then
        match kernelRequireNumberText value "version" with
        | Result.error error => Result.error error
        | Result.ok version =>
            if kernelStringEq version kernelBridgeVersionText then
              match kernelRequireString value "kernel" with
              | Result.error error => Result.error error
              | Result.ok kernel =>
                  if kernelStringEq kernel kernelBridgeKernelFingerprint then
                    match kernelRequireString value "foundation" with
                    | Result.error error => Result.error error
                    | Result.ok foundation =>
                        if
                            kernelStringEq
                              foundation
                              kernelBridgeFoundationFingerprint then
                          Result.ok Unit.unit
                        else
                          Result.error
                            KernelProtocolError.foundationFingerprintMismatch
                  else
                    Result.error
                      KernelProtocolError.kernelFingerprintMismatch
            else
              Result.error KernelProtocolError.versionMismatch
      else
        Result.error KernelProtocolError.protocolMismatch

def kernelDecodeResponseValue
    (value : JsonValue) :
    Result KernelResponse KernelProtocolError :=
  match kernelValidateEnvelope value with
  | Result.error error => Result.error error
  | Result.ok unit =>
      match kernelRequireBool value "ok" with
      | Result.error error => Result.error error
      | Result.ok ok =>
          let responseValue : Option JsonValue :=
            jsonObjectFind value "value";
          let responseError : Option String :=
            match jsonObjectFind value "error" with
            | Option.none => Option.none
            | Option.some errorValue =>
                kernelJsonAsString errorValue;
          Result.ok
            (KernelResponse.mk
              ok
              responseValue
              responseError)

def kernelDecodeResponse
    (source : String) :
    Result KernelResponse KernelProtocolError :=
  match jsonParse source with
  | Result.error error =>
      Result.error (KernelProtocolError.json error)
  | Result.ok value =>
      kernelDecodeResponseValue value
