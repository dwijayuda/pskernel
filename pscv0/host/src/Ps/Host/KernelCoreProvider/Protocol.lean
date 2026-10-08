import Ps.Bridge.Codec
import Ps.Host.KernelCoreProvider.Convert
import Ps.Host.KernelCoreProvider.Error

namespace PsKernelCoreProvider

def providerProtocol : String := "pskernel-core/1"
def providerName : String := "pskernel-core-native"
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

def malformedRequest (message : String) : PsKernelCoreProviderError :=
  { kind := .malformedRequest, message := message }

def protocolVersionError (message : String) : PsKernelCoreProviderError :=
  { kind := .protocolVersion, message := message }

def liftCodec {α : Type}
    (message : String)
    (result : Except PsCodecDecodeError α) :
    Except PsKernelCoreProviderError α :=
  match result with
  | .ok value => .ok value
  | .error _ => .error (malformedRequest message)

def jsonField (value : PsJsonValue) (name : String) :
    Except PsKernelCoreProviderError PsJsonValue :=
  liftCodec ("missing or invalid field: " ++ name) (psCodecField value name)

def jsonString (message : String) (value : PsJsonValue) :
    Except PsKernelCoreProviderError String :=
  liftCodec message (psCodecString value)

def jsonArray (message : String) (value : PsJsonValue) :
    Except PsKernelCoreProviderError (List PsJsonValue) :=
  liftCodec message (psCodecArray value)

def decodeCoreName (value : PsJsonValue) :
    Except PsKernelCoreProviderError PsKernelName := do
  let name ← liftCodec "invalid structured name" (psDecodeCodecName value)
  pure (toCoreName name)

def decodeLevelParamList (value : PsJsonValue) :
    Except PsKernelCoreProviderError (List PsKernelName) := do
  let raw ← jsonArray "level parameters must be an array" value
  raw.mapM decodeCoreName

def decodeCoreExpr (value : PsJsonValue) :
    Except PsKernelCoreProviderError PsKernelExpr := do
  let expr ← liftCodec "invalid core expression" (psDecodeCodecExpr value)
  toCoreExpr expr

def decodeRegularHints (value : PsJsonValue) :
    Except PsKernelCoreProviderError PsKernelReducibilityHints := do
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
  pure (.regular height)

def decodeDefinition (value : PsJsonValue) :
    Except PsKernelCoreProviderError PsKernelDeclarationRequest := do
  let levelParams ← decodeLevelParamList (← jsonField value "lp")
  let name ← decodeCoreName (← jsonField value "n")
  let safety ← jsonString "definition safety must be a string" (← jsonField value "s")
  if safety != "safe" then
    throw (malformedRequest "unsupported definition safety")
  let type ← decodeCoreExpr (← jsonField value "t")
  let body ← decodeCoreExpr (← jsonField value "v")
  let hints ← decodeRegularHints (← jsonField value "h")
  pure <| .definitionDecl {
    base := { name := name, levelParams := levelParams, type := type }
    value := body
    hints := hints
    safety := .safe
  }

def decodeTheorem (value : PsJsonValue) :
    Except PsKernelCoreProviderError PsKernelDeclarationRequest := do
  let levelParams ← decodeLevelParamList (← jsonField value "lp")
  let name ← decodeCoreName (← jsonField value "n")
  let type ← decodeCoreExpr (← jsonField value "t")
  let body ← decodeCoreExpr (← jsonField value "v")
  pure <| .theoremDecl {
    base := { name := name, levelParams := levelParams, type := type }
    value := body
  }

def decodeConstructor (value : PsJsonValue) :
    Except PsKernelCoreProviderError PsKernelSimpleConstructorDecl := do
  let name ← decodeCoreName (← jsonField value "n")
  let type ← decodeCoreExpr (← jsonField value "t")
  pure { name := name, type := type }

def decodeInductiveType (value : PsJsonValue) :
    Except PsKernelCoreProviderError PsKernelSimpleMutualTypeDecl := do
  let name ← decodeCoreName (← jsonField value "n")
  let type ← decodeCoreExpr (← jsonField value "t")
  let rawConstructors ← jsonArray "constructors must be an array" (← jsonField value "cs")
  let constructors ← rawConstructors.mapM decodeConstructor
  pure { name := name, type := type, ctors := constructors }

def decodeInductive (value : PsJsonValue) :
    Except PsKernelCoreProviderError PsKernelDeclarationRequest := do
  let levelParams ← decodeLevelParamList (← jsonField value "lp")
  let numParamsValue ← jsonField value "np"
  let numParams ← liftCodec "numParams must be a natural number" (psCodecNat numParamsValue)
  let rawTypes ← jsonArray "inductive types must be an array" (← jsonField value "ts")
  if rawTypes.isEmpty then
    throw (malformedRequest "inductive block must contain at least one type")
  let types ← rawTypes.mapM decodeInductiveType
  pure <| .nestedInductive { levelParams := levelParams, numParams := numParams, types := types, isUnsafe := false }

def decodeConstantAdmission (value : PsJsonValue) :
    Except PsKernelCoreProviderError PsKernelDeclarationRequest := do
  let declarationKind ←
    jsonString "constant declaration kind must be a string" (← jsonField value "k")
  if declarationKind == "definition" then
    decodeDefinition value
  else if declarationKind == "theorem" then
    decodeTheorem value
  else
    throw (malformedRequest "unsupported constant declaration kind")

def decodeAdmission (value : PsJsonValue) :
    Except PsKernelCoreProviderError PsKernelDeclarationRequest := do
  let kind ← jsonString "admission kind must be a string" (← jsonField value "kind")
  let declaration ← jsonField value "declaration"
  if kind == "constant" then
    decodeConstantAdmission declaration
  else if kind == "inductive" then
    decodeInductive declaration
  else
    throw (malformedRequest "unknown admission kind")

def decodeAdmissionsList (values : List PsJsonValue) :
    Except PsKernelCoreProviderError (List PsKernelDeclarationRequest) :=
  values.mapM decodeAdmission

def decodeCanonicalAdmissions (source : String) :
    Except PsKernelCoreProviderError (Array PsKernelDeclarationRequest) := do
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

end PsKernelCoreProvider
