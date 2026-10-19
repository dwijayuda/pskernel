import ProofScript.Data.Json

def selfhostJsonSource : String :=
  "{\"z\":2,\"a\":[true,\"x\\ny\"],\"m\":null}"

def selfhostJsonParsed : Result JsonValue JsonError :=
  jsonParse selfhostJsonSource

def selfhostJsonBuild : Result JsonValue JsonError :=
  jsonObjectFromTwo
    "z"
    (JsonValue.number "2")
    "a"
    (JsonValue.string "ok")

def selfhostJsonEncodeParsed
    (parsed : Result JsonValue JsonError) :
    Result String JsonError :=
  match parsed with
  | Result.error error => Result.error error
  | Result.ok value => jsonEncodeCanonical value

def selfhostJsonCanonical : Result String JsonError :=
  selfhostJsonEncodeParsed selfhostJsonParsed

def selfhostJsonLookup
    (parsed : Result JsonValue JsonError) :
    Option JsonValue :=
  match parsed with
  | Result.error error => Option.none
  | Result.ok value => jsonObjectFind value "a"

def selfhostJsonA : Option JsonValue :=
  selfhostJsonLookup selfhostJsonParsed


def selfhostJsonAIsSome : Bool :=
  optionIsSome selfhostJsonA
