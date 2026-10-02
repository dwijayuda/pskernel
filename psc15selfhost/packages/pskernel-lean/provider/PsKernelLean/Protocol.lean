import Lean
import Ps.Bridge.Codec
import PsKernelLean.Convert
import PsKernelLean.Error

namespace PsKernelLean

def providerProtocol : String := "pskernel-lean/1"
def providerName : String := "lean4-cpp"
def providerVersion : String := "4.34.0"
def providerCommit : String := "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
def providerProfile : String := "lean4.34-core"

def providerIdentityJsonFields : String :=
  "\"protocol\":" ++ psJsonQuote providerProtocol ++
  ",\"provider\":" ++ psJsonQuote providerName ++
  ",\"leanVersion\":" ++ psJsonQuote providerVersion ++
  ",\"leanCommit\":" ++ psJsonQuote providerCommit ++
  ",\"profile\":" ++ psJsonQuote providerProfile

def providerMetadataJson (status : String) : String :=
  "{" ++ providerIdentityJsonFields ++
  ",\"status\":" ++ psJsonQuote status ++ "}"

def providerNotReadyJson : String :=
  "{" ++ providerIdentityJsonFields ++
  ",\"accepted\":false" ++
  ",\"errorKind\":\"provider-internal-error\"" ++
  ",\"message\":\"kernel admission not initialized\"}"

def malformedRequest (message : String) : PsKernelLeanError :=
  { kind := .malformedRequest, message := message }

def protocolVersionError (message : String) : PsKernelLeanError :=
  { kind := .protocolVersion, message := message }

def liftCodec {α : Type}
    (message : String)
    (result : Except PsCodecDecodeError α) :
    Except PsKernelLeanError α :=
  match result with
  | .ok value => .ok value
  | .error _ => .error (malformedRequest message)

def jsonField (value : PsJsonValue) (name : String) :
    Except PsKernelLeanError PsJsonValue :=
  liftCodec ("missing or invalid field: " ++ name) (psCodecField value name)

def jsonString (message : String) (value : PsJsonValue) :
    Except PsKernelLeanError String :=
  liftCodec message (psCodecString value)

def jsonArray (message : String) (value : PsJsonValue) :
    Except PsKernelLeanError (List PsJsonValue) :=
  liftCodec message (psCodecArray value)

def decodeLeanName (value : PsJsonValue) :
    Except PsKernelLeanError Lean.Name := do
  let name ← liftCodec "invalid structured name" (psDecodeCodecName value)
  pure (toLeanName name)

def decodeLevelParamList (value : PsJsonValue) :
    Except PsKernelLeanError (List Lean.Name) := do
  let raw ← jsonArray "level parameters must be an array" value
  raw.mapM decodeLeanName

def decodeLeanExpr (value : PsJsonValue) :
    Except PsKernelLeanError Lean.Expr := do
  let expr ← liftCodec "invalid core expression" (psDecodeCodecExpr value)
  toLeanExpr expr

def decodeRegularHints (value : PsJsonValue) :
    Except PsKernelLeanError Lean.ReducibilityHints := do
  let kindValue ← jsonField value "k"
  let kind ← jsonString "definition hint kind must be a string" kindValue
  if kind != "regular" then
    throw (malformedRequest "unsupported definition hint kind")
  let heightValue ← jsonField value "h"
  let heightText ← jsonString "definition hint height must be a string" heightValue
  let some height := psCodecNaturalText heightText
    | throw (malformedRequest "invalid definition hint height")
  let height32 := UInt32.ofNat height
  if UInt32.toNat height32 != height then
    throw (malformedRequest "definition hint height exceeds UInt32")
  pure (.regular height32)

def decodeDefinition (value : PsJsonValue) :
    Except PsKernelLeanError Lean.Declaration := do
  let levelParams ← decodeLevelParamList (← jsonField value "lp")
  let name ← decodeLeanName (← jsonField value "n")
  let safety ← jsonString "definition safety must be a string" (← jsonField value "s")
  if safety != "safe" then
    throw (malformedRequest "unsupported definition safety")
  let type ← decodeLeanExpr (← jsonField value "t")
  let body ← decodeLeanExpr (← jsonField value "v")
  let hints ← decodeRegularHints (← jsonField value "h")
  pure <| .defnDecl {
    name := name
    levelParams := levelParams
    type := type
    value := body
    hints := hints
    safety := .safe
  }

def decodeTheorem (value : PsJsonValue) :
    Except PsKernelLeanError Lean.Declaration := do
  let levelParams ← decodeLevelParamList (← jsonField value "lp")
  let name ← decodeLeanName (← jsonField value "n")
  let type ← decodeLeanExpr (← jsonField value "t")
  let body ← decodeLeanExpr (← jsonField value "v")
  pure <| .thmDecl {
    name := name
    levelParams := levelParams
    type := type
    value := body
  }

def decodeConstructor (value : PsJsonValue) :
    Except PsKernelLeanError Lean.Constructor := do
  let name ← decodeLeanName (← jsonField value "n")
  let type ← decodeLeanExpr (← jsonField value "t")
  pure { name := name, type := type }

def decodeInductiveType (value : PsJsonValue) :
    Except PsKernelLeanError Lean.InductiveType := do
  let name ← decodeLeanName (← jsonField value "n")
  let type ← decodeLeanExpr (← jsonField value "t")
  let rawConstructors ← jsonArray "constructors must be an array" (← jsonField value "cs")
  let constructors ← rawConstructors.mapM decodeConstructor
  pure { name := name, type := type, ctors := constructors }

def decodeInductive (value : PsJsonValue) :
    Except PsKernelLeanError Lean.Declaration := do
  let levelParams ← decodeLevelParamList (← jsonField value "lp")
  let numParamsValue ← jsonField value "np"
  let numParams ← liftCodec "numParams must be a natural number" (psCodecNat numParamsValue)
  let rawTypes ← jsonArray "inductive types must be an array" (← jsonField value "ts")
  if rawTypes.isEmpty then
    throw (malformedRequest "inductive block must contain at least one type")
  let types ← rawTypes.mapM decodeInductiveType
  pure <| .inductDecl levelParams numParams types false

def decodeConstantAdmission (value : PsJsonValue) :
    Except PsKernelLeanError Lean.Declaration := do
  let declarationKind ←
    jsonString "constant declaration kind must be a string" (← jsonField value "k")
  if declarationKind == "definition" then
    decodeDefinition value
  else if declarationKind == "theorem" then
    decodeTheorem value
  else
    throw (malformedRequest "unsupported constant declaration kind")

def decodeAdmission (value : PsJsonValue) :
    Except PsKernelLeanError Lean.Declaration := do
  let kind ← jsonString "admission kind must be a string" (← jsonField value "kind")
  let declaration ← jsonField value "declaration"
  if kind == "constant" then
    decodeConstantAdmission declaration
  else if kind == "inductive" then
    decodeInductive declaration
  else
    throw (malformedRequest "unknown admission kind")

def decodeAdmissionsList (values : List PsJsonValue) :
    Except PsKernelLeanError (List Lean.Declaration) :=
  values.mapM decodeAdmission

def decodeCanonicalAdmissions (source : String) :
    Except PsKernelLeanError (Array Lean.Declaration) := do
  let parsed ←
    match psJsonParse source with
    | .ok value => pure value
    | .error error =>
        let detail := match error with
          | .fuelExhausted => "fuel exhausted"
          | .unexpectedEnd => "unexpected end"
          | .expected text => "expected " ++ text
          | .invalidEscape => "invalid escape"
          | .invalidUnicodeEscape => "invalid Unicode escape"
          | .invalidNumber => "invalid number"
          | .invalidLiteral => "invalid literal"
          | .trailingInput => "trailing input"
        throw (malformedRequest ("invalid JSON: " ++ detail))
  let format ← jsonString "format must be a string" (← jsonField parsed "format")
  if format != "proofscript-checked-admissions" then
    throw (malformedRequest "unexpected admissions format")
  let versionValue ← jsonField parsed "version"
  match psJsonAsNumberText versionValue with
  | some "2" => pure ()
  | _ => throw (protocolVersionError "expected canonical admissions version 2")
  let admissions ← jsonArray "admissions must be an array" (← jsonField parsed "admissions")
  let decoded ← decodeAdmissionsList admissions
  pure decoded.toArray

end PsKernelLean
