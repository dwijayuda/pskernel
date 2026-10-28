-- Native-only observer copied unchanged into both source-port comparisons.
import Ps.Bridge.Codec
import Ps.Bridge.Protocol
import Ps.Core.Builtin
import Lean.Data.Json

namespace NativeBridgeObserver

def codecError : PsCodecDecodeError -> String
  | .fuelExhausted => "fuelExhausted"
  | .expectedObject => "expectedObject"
  | .expectedArray => "expectedArray"
  | .expectedString => "expectedString"
  | .expectedNumber => "expectedNumber"
  | .missingField name => "missingField:" ++ name
  | .invalidNatural => "invalidNatural"
  | .invalidTag tag => "invalidTag:" ++ tag
  | .invalidBinder binder => "invalidBinder:" ++ binder

def encodeError : PsCheckedAdmissionCodecError -> String
  | .universeMetavariable => "universeMetavariable"
  | .freeVariable => "freeVariable"
  | .expressionMetavariable => "expressionMetavariable"
  | .missingConstructor name => "missingConstructor:" ++ psEncodeCodecName name
  | .mismatchedConstructor name => "mismatchedConstructor:" ++ psEncodeCodecName name
  | .unsupportedDeclaration => "unsupportedDeclaration"

def protocolError : PsKernelBridgeProtocolError -> String
  | .json _ => "unexpected-json-error"
  | .codec error => "codec:" ++ codecError error
  | .encode error => "encode:" ++ encodeError error
  | .missingField name => "missingField:" ++ name
  | .invalidField name => "invalidField:" ++ name
  | .protocolMismatch => "protocolMismatch"
  | .versionMismatch => "versionMismatch"
  | .kernelFingerprintMismatch => "kernelFingerprintMismatch"
  | .foundationFingerprintMismatch => "foundationFingerprintMismatch"
  | .remoteError message => "remoteError:" ++ message

def decoded {α : Type} (result : Except PsCodecDecodeError α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError (codecError error))

def encoded (result : Except PsCheckedAdmissionCodecError String) : IO String :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError (encodeError error))

def requestText (request : PsKernelBridgeRequest) : IO String :=
  match psEncodeKernelBridgeRequest request with
  | .ok value => pure value
  | .error error => throw (IO.userError (protocolError error))

def parse (text : String) : IO PsJsonValue :=
  match psJsonParse text with
  | .ok value => pure value
  | .error _ => throw (IO.userError "invalid observer JSON fixture")

def codecResult {α : Type} (result : Except PsCodecDecodeError α) : String :=
  match result with
  | .ok _ => "accepted"
  | .error error => codecError error

def protocolResult {α : Type} (result : Except PsKernelBridgeProtocolError α) : String :=
  match result with
  | .ok _ => "accepted"
  | .error error => protocolError error

def expect (label actual expected : String) : IO (String × String) := do
  if actual != expected then throw (IO.userError (label ++ ": " ++ actual ++ " != " ++ expected))
  return (label, actual)

def run : IO Unit := do
  let name := psNameAppendNum (psNameAppendStr (psRootName "Fixture") "λ") 42
  let nameText := psEncodeCodecName name
  let nameAgain ← decoded (psDecodeCodecName (← parse nameText))
  if psEncodeCodecName nameAgain != nameText then throw (IO.userError "name roundtrip")
  let level := PsLevel.imax (PsLevel.succ PsLevel.zero)
    (PsLevel.max (PsLevel.param (psRootName "u")) (PsLevel.succ (PsLevel.succ PsLevel.zero)))
  let levelText ← encoded (psEncodeCodecLevel level)
  let levelAgain ← decoded (psDecodeCodecLevel (← parse levelText))
  if (← encoded (psEncodeCodecLevel levelAgain)) != levelText then throw (IO.userError "level roundtrip")
  let natType := PsExpr.constE psNatName []
  let expr := PsExpr.lam (psRootName "x") natType
    (PsExpr.letE (psRootName "y") natType (PsExpr.lit (PsLiteral.natural 7))
      (PsExpr.app (PsExpr.constE (psRootName "f") [level]) (PsExpr.bvar 0))) .explicit
  let exprText ← encoded (psEncodeCodecExpr expr)
  let exprAgain ← decoded (psDecodeCodecExpr (← parse exprText))
  if (← encoded (psEncodeCodecExpr exprAgain)) != exprText then throw (IO.userError "expr roundtrip")
  let declaration := PsDeclaration.definitionDecl (psRootName "observedNat") [] natType
    (PsExpr.lit (PsLiteral.natural 1))
  let requests : List (String × PsKernelBridgeRequest) := [
    ("request-ping", .ping), ("request-lookup", .lookup name), ("request-infer", .infer expr),
    ("request-defeq", .defeq expr expr), ("request-replay", .replayAdmissions [declaration])]
  let requestRows ← requests.mapM fun (label, request) => do
    return (label, ← requestText request)
  let nameCases : List (String × String × String) := [
    ("name-missing-parent-first", "{\"k\":\"s\"}", "missingField:p"),
    ("name-missing-value-before-parent-decode", "{\"k\":\"s\",\"p\":{\"k\":\"bad-parent\"}}", "missingField:v"),
    ("name-parent-before-value-decode", "{\"k\":\"s\",\"p\":{\"k\":\"bad-parent\"},\"v\":0}", "invalidTag:bad-parent"),
    ("numeric-name-invalid-natural", "{\"k\":\"n\",\"p\":{\"k\":\"a\"},\"v\":\"01\"}", "invalidNatural")]
  let nameRows ← nameCases.mapM fun (label, text, expected) => do
    expect label (codecResult (psDecodeCodecName (← parse text))) expected
  let levelCases : List (String × String × String) := [
    ("level-missing-right-before-left-decode", "{\"k\":\"max\",\"l\":{\"k\":\"bad-left\"}}", "missingField:r"),
    ("level-left-before-right-decode", "{\"k\":\"imax\",\"l\":{\"k\":\"bad-left\"},\"r\":{\"k\":\"bad-right\"}}", "invalidTag:bad-left")]
  let levelRows ← levelCases.mapM fun (label, text, expected) => do
    expect label (codecResult (psDecodeCodecLevel (← parse text))) expected
  let exprCases : List (String × String × String) := [
    ("expr-missing-argument-before-function-decode", "{\"k\":\"app\",\"f\":{\"k\":\"bad-function\"}}", "missingField:a"),
    ("expr-function-before-argument-decode", "{\"k\":\"app\",\"f\":{\"k\":\"bad-function\"},\"a\":{\"k\":\"bad-argument\"}}", "invalidTag:bad-function"),
    ("expr-lambda-fields-before-decoding", "{\"k\":\"lam\",\"n\":{\"k\":\"bad-name\"},\"t\":{\"k\":\"bad-type\"},\"b\":{\"k\":\"bad-body\"}}", "missingField:bi"),
    ("expr-lambda-name-before-other-decodes", "{\"k\":\"lam\",\"n\":{\"k\":\"bad-name\"},\"t\":{\"k\":\"bad-type\"},\"b\":{\"k\":\"bad-body\"},\"bi\":0}", "invalidTag:bad-name"),
    ("expr-let-fields-before-decoding", "{\"k\":\"let\",\"n\":{\"k\":\"bad-name\"},\"t\":{\"k\":\"bad-type\"},\"v\":{\"k\":\"bad-value\"}}", "missingField:b"),
    ("expr-const-name-before-level-array", "{\"k\":\"const\",\"n\":{\"k\":\"bad-name\"},\"ls\":0}", "invalidTag:bad-name")]
  let exprRows ← exprCases.mapM fun (label, text, expected) => do
    expect label (codecResult (psDecodeCodecExpr (← parse text))) expected
  let firstBad ← parse "{\"k\":\"first-bad-level\"}"
  let secondBad ← parse "{\"k\":\"second-bad-level\"}"
  let levelsRow ← expect "levels-map-first-error"
    (codecResult (psDecodeCodecLevelsWithFuel 32 [firstBad,secondBad])) "invalidTag:first-bad-level"
  let envelope (protocol version kernel foundation : String) := psJsonObject [
    ("protocol", protocol), ("version", version), ("kernel", kernel), ("foundation", foundation)]
  let missingFoundation := psJsonObject [
    ("protocol", psJsonQuote "wrong"), ("version", "1"), ("kernel", psJsonQuote psKernelBridgeKernelFingerprint)]
  let protocolCases : List (String × String × String) := [
    ("protocol-missing-first", "{}", "missingField:protocol"),
    ("protocol-required-fields-before-values", missingFoundation, "missingField:foundation"),
    ("protocol-field-type-before-values",
      envelope (psJsonQuote "wrong") "1" (psJsonQuote psKernelBridgeKernelFingerprint) "0", "invalidField:foundation"),
    ("protocol-value-priority",
      envelope (psJsonQuote "wrong") "2" (psJsonQuote "wrong") (psJsonQuote "wrong"), "protocolMismatch"),
    ("protocol-version-priority",
      envelope (psJsonQuote psKernelBridgeProtocol) "2" (psJsonQuote "wrong") (psJsonQuote "wrong"), "versionMismatch"),
    ("protocol-kernel-priority",
      envelope (psJsonQuote psKernelBridgeProtocol) "1" (psJsonQuote "wrong") (psJsonQuote "wrong"), "kernelFingerprintMismatch")]
  let protocolRows ← protocolCases.mapM fun (label, text, expected) => do
    expect label (protocolResult (psKernelBridgeValidateEnvelope (← parse text))) expected
  let encodeLeft ← expect "defeq-encode-left-priority"
    (protocolResult (psEncodeKernelBridgeRequest (.defeq (.fvar 0) (.mvar 0)))) "encode:freeVariable"
  let encodeRight ← expect "defeq-encode-opposite-priority"
    (protocolResult (psEncodeKernelBridgeRequest (.defeq (.mvar 0) (.fvar 0)))) "encode:expressionMetavariable"
  let responseText := psJsonObject [
    ("protocol", psJsonQuote psKernelBridgeProtocol), ("version", "1"),
    ("kernel", psJsonQuote psKernelBridgeKernelFingerprint),
    ("foundation", psJsonQuote psKernelBridgeFoundationFingerprint), ("ok", "true"), ("value", exprText)]
  let response ← match psDecodeKernelBridgeResponse responseText with
    | .error error => throw (IO.userError (protocolError error))
    | .ok value => pure value
  let responseExpr ← match psKernelBridgeResponseExpr response with
    | .error error => throw (IO.userError (protocolError error))
    | .ok value => pure value
  let responseAgain ← encoded (psEncodeCodecExpr responseExpr)
  if responseAgain != exprText then throw (IO.userError "protocol expression roundtrip")
  let rows := [("name-roundtrip",nameText),("level-roundtrip",levelText),("expr-roundtrip",exprText),
    ("protocol-response-roundtrip",responseAgain)] ++ requestRows ++ nameRows ++ levelRows ++ exprRows ++
    [levelsRow] ++ protocolRows ++ [encodeLeft,encodeRight]
  IO.println (Lean.Json.mkObj [
    ("schema", .str "psc1-native-bridge-observer/1"), ("observations", Lean.toJson rows)]).compress

end NativeBridgeObserver

def main : IO Unit := NativeBridgeObserver.run
