import ProofScript.Compiler.Effect
import ProofScript.Data.Json

-- Host effects are explicit requests. No logical axiom, runtime intrinsic or
-- evaluation of effects is added to the independently checked source language.
inductive IoError where
  | capabilityDenied
  | pathDenied
  | notFound
  | wrongType
  | invalidUtf8
  | tooLarge
  | ioFailure
  | protocolError

inductive IoRequest where
  | readLine
  | writeLine (text : String)
  | readUtf8 (path : String)
  | writeUtf8 (path text : String)

inductive IoResponse where
  | line (value : Option String)
  | text (value : String)
  | done
  | failed (error : IoError)

def ioTextEq (left right : String) : Bool :=
  match orderingString left right with
  | Ordering.eq => true
  | _ => false

def ioEncodeRequest (request : IoRequest) : String :=
  match request with
  | IoRequest.readLine => "{\"op\":\"readLine\"}"
  | IoRequest.writeLine text =>
      jsonAppend "{\"op\":\"writeLine\",\"text\":" (jsonAppend (jsonQuote text) "}")
  | IoRequest.readUtf8 path =>
      jsonAppend "{\"op\":\"readUtf8\",\"path\":" (jsonAppend (jsonQuote path) "}")
  | IoRequest.writeUtf8 path text =>
      jsonAppend "{\"op\":\"writeUtf8\",\"path\":"
        (jsonAppend (jsonQuote path) (jsonAppend ",\"text\":" (jsonAppend (jsonQuote text) "}")))

def ioDecodeError (text : String) : IoError :=
  if ioTextEq text "capabilityDenied" then IoError.capabilityDenied
  else if ioTextEq text "pathDenied" then IoError.pathDenied
  else if ioTextEq text "notFound" then IoError.notFound
  else if ioTextEq text "wrongType" then IoError.wrongType
  else if ioTextEq text "invalidUtf8" then IoError.invalidUtf8
  else if ioTextEq text "tooLarge" then IoError.tooLarge
  else if ioTextEq text "ioFailure" then IoError.ioFailure
  else IoError.protocolError

def ioJsonStringField (value : JsonValue) (key : String) : Option String :=
  match jsonObjectFind value key with
  | Option.none => Option.none
  | Option.some field =>
      match field with
      | JsonValue.string text => Option.some text
      | _ => Option.none

def ioDecodeLine (value : JsonValue) : IoResponse :=
  match jsonObjectFind value "text" with
  | Option.none => IoResponse.failed IoError.protocolError
  | Option.some field =>
      match field with
      | JsonValue.nullE => IoResponse.line Option.none
      | JsonValue.string text => IoResponse.line (Option.some text)
      | _ => IoResponse.failed IoError.protocolError

def ioDecodeValue (kind : String) (value : JsonValue) : IoResponse :=
  if ioTextEq kind "unit" then IoResponse.done
  else if ioTextEq kind "error" then
    match ioJsonStringField value "error" with
    | Option.some text => IoResponse.failed (ioDecodeError text)
    | _ => IoResponse.failed IoError.protocolError
  else if ioTextEq kind "text" then
    match ioJsonStringField value "text" with
    | Option.some text => IoResponse.text text
    | _ => IoResponse.failed IoError.protocolError
  else if ioTextEq kind "line" then ioDecodeLine value
  else IoResponse.failed IoError.protocolError

def ioDecodeResponse (source : String) : IoResponse :=
  match jsonParse source with
  | Result.error _ => IoResponse.failed IoError.protocolError
  | Result.ok value =>
      match ioJsonStringField value "kind" with
      | Option.some kind => ioDecodeValue kind value
      | _ => IoResponse.failed IoError.protocolError

def ioReadTextResult (source : String) : Result String IoError :=
  match ioDecodeResponse source with
  | IoResponse.text text => Result.ok text
  | IoResponse.failed error => Result.error error
  | _ => Result.error IoError.protocolError

def ioReadLineResult (source : String) : Result (Option String) IoError :=
  match ioDecodeResponse source with
  | IoResponse.line value => Result.ok value
  | IoResponse.failed error => Result.error error
  | _ => Result.error IoError.protocolError

def ioWriteResult (source : String) : Result Unit IoError :=
  match ioDecodeResponse source with
  | IoResponse.done => Result.ok ()
  | IoResponse.failed error => Result.error error
  | _ => Result.error IoError.protocolError

-- Checked IO is Reader/Except over an explicit dispatcher input. Native effects
-- are supplied by the selected host adapter; source handlers consume IoError
-- values, never host exceptions. Completed host writes are not rolled back.
def Io (A : Type) : Type := CompilerM (String -> String) Unit IoError A

def ioPerformRun {A : Type}
    (request : IoRequest) (decode : String -> Result A IoError)
    (dispatch : String -> String) (state : Unit) : Result (Prod A Unit) IoError :=
  match decode (dispatch (ioEncodeRequest request)) with
  | Result.error error => Result.error error
  | Result.ok value => Result.ok (Prod.mk value state)

def ioPerform {A : Type}
    (request : IoRequest) (decode : String -> Result A IoError) : Io A :=
  CompilerM.mk (ioPerformRun request decode)

def ioReadLine (unit : Unit) : Io (Option String) :=
  ioPerform IoRequest.readLine ioReadLineResult

def ioWriteLine (text : String) : Io Unit :=
  ioPerform (IoRequest.writeLine text) ioWriteResult

def ioReadUtf8 (path : String) : Io String :=
  ioPerform (IoRequest.readUtf8 path) ioReadTextResult

def ioWriteUtf8 (path text : String) : Io Unit :=
  ioPerform (IoRequest.writeUtf8 path text) ioWriteResult

def ioRun {A : Type} (program : Io A) (dispatch : String -> String) : Result A IoError :=
  match program.run dispatch () with
  | Result.error error => Result.error error
  | Result.ok pair => Result.ok pair.fst
