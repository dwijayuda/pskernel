import Ps.CompilerIr.SourceSignature
import Ps.CompilerIr.PublicApiEncode

def psSourceSignatureScalarText (type : PsSourceScalarType) : String :=
  match type with
  | PsSourceScalarType.nat => "nat"
  | PsSourceScalarType.int => "int"
  | PsSourceScalarType.uint8 => "uint8"
  | PsSourceScalarType.uint16 => "uint16"
  | PsSourceScalarType.uint32 => "uint32"
  | PsSourceScalarType.uint64 => "uint64"
  | PsSourceScalarType.usize => "usize"
  | PsSourceScalarType.int8 => "int8"
  | PsSourceScalarType.int16 => "int16"
  | PsSourceScalarType.int32 => "int32"
  | PsSourceScalarType.int64 => "int64"
  | PsSourceScalarType.isize => "isize"
  | PsSourceScalarType.float => "float"
  | PsSourceScalarType.float32 => "float32"
  | PsSourceScalarType.bool => "bool"
  | PsSourceScalarType.char => "char"
  | PsSourceScalarType.string => "string"
  | PsSourceScalarType.unit => "unit"

def psSourceSignatureEncodeTypeWorker
    (fuel : Nat) : PsSourceSignatureType -> Except PsSourceSignatureError String :=
  match fuel with
  | Nat.zero =>
      fun (_type : PsSourceSignatureType) =>
        Except.error PsSourceSignatureError.resourceExhausted
  | Nat.succ remaining =>
      let smaller : PsSourceSignatureType -> Except PsSourceSignatureError String :=
        psSourceSignatureEncodeTypeWorker remaining;
      fun (type : PsSourceSignatureType) =>
        match type with
        | PsSourceSignatureType.scalar scalar =>
            Except.ok (psJsonArray [psJsonQuote "scalar", psJsonQuote (psSourceSignatureScalarText scalar)])
        | PsSourceSignatureType.parameter index =>
            Except.ok (psJsonArray [psJsonQuote "parameter", psCheckedAdmissionNatToString index])
        | PsSourceSignatureType.array element =>
            match smaller element with
            | Except.error error => Except.error error
            | Except.ok encoded =>
                Except.ok (psJsonArray [psJsonQuote "array", encoded])
        | PsSourceSignatureType.function parameters result =>
            match psListMapExcept smaller parameters with
            | Except.error error => Except.error error
            | Except.ok encodedParameters =>
                match smaller result with
                | Except.error error => Except.error error
                | Except.ok encodedResult =>
                    Except.ok
                      (psJsonArray [psJsonQuote "function", psJsonArray encodedParameters, encodedResult])

def psSourceSignatureEncodeParameter (parameter : PsSourceSignatureParameter) : String :=
  psJsonObject [
    Prod.mk "binderInfo" (psJsonQuote (psEncodeCodecBinderInfo parameter.binderInfo)),
    Prod.mk "name"
      (psJsonQuote (String.Internal.append "T" (psCheckedAdmissionNatToString parameter.index))),
    Prod.mk "sourceName" (psEncodeCodecName parameter.sourceName)
  ]

def psSourceSignatureEncode (signature : PsSourceSignature) :
    Except PsSourceSignatureError String :=
  match psSourceSignatureEncodeTypeWorker 129 signature.type with
  | Except.error error => Except.error error
  | Except.ok encoded =>
      Except.ok
        (psJsonObject [
          Prod.mk "profile" (psJsonQuote "psc-source-signature-structural/1"),
          Prod.mk "type" encoded,
          Prod.mk "typeParameters"
            (psJsonArray (psListMap psSourceSignatureEncodeParameter signature.typeParameters))
        ])

def psProjectSourceSignatureJson (type : PsExpr) :
    Except PsSourceSignatureError String :=
  match psProjectSourceSignature type with
  | Except.error error => Except.error error
  | Except.ok signature => psSourceSignatureEncode signature
