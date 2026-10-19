import Ps.BackendWasm.CanonicalExports
import Ps.Bridge.Json

-- A compact canonical wire request avoids dependence on a host's generated
-- constructor layout. Names are policy; source types still come from checked IR.
structure PsWasmCanonicalRequest where
  profile : PsWasmTargetProfile
  selection : PsWasmCanonicalSelection

inductive PsWasmCanonicalRequestError where
  | resource
  | schema
  | nonCanonical
  | parse (error : PsJsonParseError)

def psWasmCanonicalRequestString (value : PsJsonValue) :
    Except PsWasmCanonicalRequestError String :=
  match value with
  | PsJsonValue.string text =>
      if Nat.ble (String.utf8ByteSize text) 4096 then Except.ok text
      else Except.error PsWasmCanonicalRequestError.resource
  | _ => Except.error PsWasmCanonicalRequestError.schema

def psWasmCanonicalRequestExport (value : PsJsonValue) :
    Except PsWasmCanonicalRequestError PsWasmCanonicalExport :=
  match value with
  | PsJsonValue.array fields =>
      if Nat.beq (psListLength fields) 2 then
        match psWasmCanonicalRequestString (psJsonArrayItem 0 fields) with
        | Except.error error => Except.error error
        | Except.ok sourceName =>
            match psWasmCanonicalRequestString (psJsonArrayItem 1 fields) with
            | Except.error error => Except.error error
            | Except.ok foreignName =>
                Except.ok (PsWasmCanonicalExport.mk sourceName foreignName)
      else Except.error PsWasmCanonicalRequestError.schema
  | _ => Except.error PsWasmCanonicalRequestError.schema

def psWasmCanonicalRequestProfile (value : PsJsonValue) :
    Except PsWasmCanonicalRequestError PsWasmTargetProfile :=
  match value with
  | PsJsonValue.string text =>
      if psStringEq text "32" then Except.ok (PsWasmTargetProfile.mk PsWasmWordSize.wasm32)
      else if psStringEq text "64" then Except.ok (PsWasmTargetProfile.mk PsWasmWordSize.wasm64)
      else Except.error PsWasmCanonicalRequestError.schema
  | _ => Except.error PsWasmCanonicalRequestError.schema

def psWasmCanonicalRequestSelection (fields : List PsJsonValue) :
    Except PsWasmCanonicalRequestError PsWasmCanonicalSelection :=
  match psWasmCanonicalRequestString (psJsonArrayItem 2 fields) with
  | Except.error error => Except.error error
  | Except.ok packageNamespace =>
      match psWasmCanonicalRequestString (psJsonArrayItem 3 fields) with
      | Except.error error => Except.error error
      | Except.ok packageName =>
          match psWasmCanonicalRequestString (psJsonArrayItem 4 fields) with
          | Except.error error => Except.error error
          | Except.ok worldName =>
              match psWasmCanonicalRequestString (psJsonArrayItem 5 fields) with
              | Except.error error => Except.error error
              | Except.ok interfaceName =>
                  match psJsonArrayItem 6 fields with
                  | PsJsonValue.array values =>
                      if psListIsEmpty values then Except.error PsWasmCanonicalRequestError.schema
                      else if Nat.ble (psListLength values) 1024 then
                        match psListMapExcept psWasmCanonicalRequestExport values with
                        | Except.error error => Except.error error
                        | Except.ok exports =>
                            Except.ok (PsWasmCanonicalSelection.mk
                              packageNamespace packageName worldName interfaceName exports)
                      else Except.error PsWasmCanonicalRequestError.resource
                  | _ => Except.error PsWasmCanonicalRequestError.schema

def psWasmCanonicalRequestValue (value : PsJsonValue) :
    Except PsWasmCanonicalRequestError PsWasmCanonicalRequest :=
  match value with
  | PsJsonValue.array fields =>
      if Nat.beq (psListLength fields) 7 then
        match psJsonArrayItem 0 fields with
        | PsJsonValue.string tag =>
            if psStringEq tag "psc-wasm-canonical-request/1" then
              match psWasmCanonicalRequestProfile (psJsonArrayItem 1 fields) with
              | Except.error error => Except.error error
              | Except.ok profile =>
                  match psWasmCanonicalRequestSelection fields with
                  | Except.error error => Except.error error
                  | Except.ok selection => Except.ok (PsWasmCanonicalRequest.mk profile selection)
            else Except.error PsWasmCanonicalRequestError.schema
        | _ => Except.error PsWasmCanonicalRequestError.schema
      else Except.error PsWasmCanonicalRequestError.schema
  | _ => Except.error PsWasmCanonicalRequestError.schema

def psWasmCanonicalRequestExportJson (selection : PsWasmCanonicalExport) : String :=
  psJsonArray [psJsonQuote selection.sourceName, psJsonQuote selection.foreignName]

def psWasmCanonicalEncodeRequest (request : PsWasmCanonicalRequest) : String :=
  let wordBits : String :=
    match request.profile.wordSize with
    | PsWasmWordSize.wasm32 => "32"
    | PsWasmWordSize.wasm64 => "64";
  psJsonArray [
    psJsonQuote "psc-wasm-canonical-request/1",
    psJsonQuote wordBits,
    psJsonQuote request.selection.packageNamespace,
    psJsonQuote request.selection.packageName,
    psJsonQuote request.selection.worldName,
    psJsonQuote request.selection.interfaceName,
    psJsonArray (psListMap psWasmCanonicalRequestExportJson request.selection.exports)]

def psWasmCanonicalDecodeRequest (source : String) :
    Except PsWasmCanonicalRequestError PsWasmCanonicalRequest :=
  if psJsonArrayRequestWithinLimits 1048576 3 1026 source then
    match psJsonParse source with
    | Except.error error => Except.error (PsWasmCanonicalRequestError.parse error)
    | Except.ok value =>
        match psWasmCanonicalRequestValue value with
        | Except.error error => Except.error error
        | Except.ok request =>
            if psStringEq (psWasmCanonicalEncodeRequest request) source then Except.ok request
            else Except.error PsWasmCanonicalRequestError.nonCanonical
  else Except.error PsWasmCanonicalRequestError.resource
