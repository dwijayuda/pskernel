import Ps.InterfaceTs.Declarations
import Ps.Bridge.Json

structure PsTsDeclarationCommand where
  profile : PsTsDeclarationProfile
  maxBytes : Nat
  requests : List PsTsDeclarationRequest

inductive PsTsDeclarationRequestError where
  | resource
  | schema
  | nonCanonical
  | parse (error : PsJsonParseError)
  | emit (error : PsTsDeclarationError)

-- The only admitted nesting is the root array, request list and request pair.
-- Bound depth and total arrays before the general JSON parser sees input.
structure PsTsDeclarationJsonScan where
  offset : Nat
  depth : Nat
  arrays : Nat
  quoted : Bool
  escaped : Bool

def psTsDeclarationJsonScanWorker (fuel : Nat) :
    String -> PsTsDeclarationJsonScan -> Bool :=
  match fuel with
  | Nat.zero => fun (_source : String) (_state : PsTsDeclarationJsonScan) => false
  | Nat.succ remaining =>
      let smaller : String -> PsTsDeclarationJsonScan -> Bool :=
        psTsDeclarationJsonScanWorker remaining;
      fun (source : String) (state : PsTsDeclarationJsonScan) =>
        if String.Internal.atEnd source (String.Pos.Raw.mk state.offset) then
          if state.quoted then false else Nat.beq state.depth 0
        else
          let code : Nat := Char.toNat (String.Internal.get source (String.Pos.Raw.mk state.offset));
          let next : Nat := String.Pos.Raw.byteIdx
            (String.Internal.next source (String.Pos.Raw.mk state.offset));
          if state.quoted then
            if state.escaped then
              smaller source (PsTsDeclarationJsonScan.mk next state.depth state.arrays true false)
            else if Nat.beq code 92 then
              smaller source (PsTsDeclarationJsonScan.mk next state.depth state.arrays true true)
            else if Nat.beq code 34 then
              smaller source (PsTsDeclarationJsonScan.mk next state.depth state.arrays false false)
            else
              smaller source (PsTsDeclarationJsonScan.mk next state.depth state.arrays true false)
          else if Nat.beq code 34 then
            smaller source (PsTsDeclarationJsonScan.mk next state.depth state.arrays true false)
          else if Nat.beq code 91 then
            if Nat.blt state.depth 3 then
              if Nat.blt state.arrays 4098 then
                smaller source
                  (PsTsDeclarationJsonScan.mk next (Nat.succ state.depth) (Nat.succ state.arrays) false false)
              else false
            else false
          else if Nat.beq code 93 then
            if Nat.blt 0 state.depth then
              smaller source (PsTsDeclarationJsonScan.mk next (Nat.sub state.depth 1) state.arrays false false)
            else false
          else if Nat.beq code 123 then false
          else if Nat.beq code 125 then false
          else smaller source (PsTsDeclarationJsonScan.mk next state.depth state.arrays false false)

def psTsDecodeDeclarationNatural (digits : Nat) (value : PsJsonValue) :
    Except PsTsDeclarationRequestError Nat :=
  match value with
  | PsJsonValue.string text =>
      if Nat.ble (String.utf8ByteSize text) digits then
        match psJsonDecodeNaturalString value with
        | Option.none => Except.error PsTsDeclarationRequestError.schema
        | Option.some result => Except.ok result
      else Except.error PsTsDeclarationRequestError.resource
  | _ => Except.error PsTsDeclarationRequestError.schema

def psTsDecodeDeclarationRequest (value : PsJsonValue) :
    Except PsTsDeclarationRequestError PsTsDeclarationRequest :=
  match value with
  | PsJsonValue.array values =>
      if Nat.beq (psListLength values) 2 then
        match psJsonArrayItem 1 values with
        | PsJsonValue.string name =>
            match psTsDecodeDeclarationNatural 7 (psJsonArrayItem 0 values) with
            | Except.error error => Except.error error
            | Except.ok sourceIndex =>
                if Nat.ble sourceIndex 1000000 then
                  Except.ok (PsTsDeclarationRequest.mk sourceIndex name)
                else Except.error PsTsDeclarationRequestError.resource
        | _ => Except.error PsTsDeclarationRequestError.schema
      else Except.error PsTsDeclarationRequestError.schema
  | _ => Except.error PsTsDeclarationRequestError.schema

def psTsDecodeDeclarationProfile (text : String) :
    Except PsTsDeclarationRequestError PsTsDeclarationProfile :=
  if psStringEq text "psc-direct-js-declarations-closed-structural/1" then
    Except.ok PsTsDeclarationProfile.closedJavaScript64
  else if psStringEq text "psc-direct-js-declarations-uniform-structural/1" then
    Except.ok PsTsDeclarationProfile.uniformJavaScript64
  else Except.error PsTsDeclarationRequestError.schema

def psTsDecodeDeclarationCommandFields
    (profileText : String) (byteLimit : PsJsonValue) (values : List PsJsonValue) :
    Except PsTsDeclarationRequestError PsTsDeclarationCommand :=
  match psTsDecodeDeclarationProfile profileText with
  | Except.error error => Except.error error
  | Except.ok profile =>
      match psTsDecodeDeclarationNatural 8 byteLimit with
      | Except.error error => Except.error error
      | Except.ok maxBytes =>
          if Nat.blt 0 maxBytes then
            if Nat.ble maxBytes 67108864 then
              match psListMapExcept psTsDecodeDeclarationRequest values with
              | Except.error error => Except.error error
              | Except.ok requests => Except.ok (PsTsDeclarationCommand.mk profile maxBytes requests)
            else Except.error PsTsDeclarationRequestError.resource
          else Except.error PsTsDeclarationRequestError.resource

def psTsDecodeDeclarationCommandValue (value : PsJsonValue) :
    Except PsTsDeclarationRequestError PsTsDeclarationCommand :=
  match value with
  | PsJsonValue.array fields =>
      if Nat.beq (psListLength fields) 4 then
        match psJsonArrayItem 0 fields with
        | PsJsonValue.string tag =>
            if psStringEq tag "psc-ts-declaration-request/1" then
              match psJsonArrayItem 1 fields with
              | PsJsonValue.string profileText =>
                  match psJsonArrayItem 3 fields with
                  | PsJsonValue.array values =>
                      psTsDecodeDeclarationCommandFields profileText (psJsonArrayItem 2 fields) values
                  | _ => Except.error PsTsDeclarationRequestError.schema
              | _ => Except.error PsTsDeclarationRequestError.schema
            else Except.error PsTsDeclarationRequestError.schema
        | _ => Except.error PsTsDeclarationRequestError.schema
      else Except.error PsTsDeclarationRequestError.schema
  | _ => Except.error PsTsDeclarationRequestError.schema

def psTsEncodeDeclarationProfile (profile : PsTsDeclarationProfile) : String :=
  match profile with
  | PsTsDeclarationProfile.closedJavaScript64 =>
      "psc-direct-js-declarations-closed-structural/1"
  | PsTsDeclarationProfile.uniformJavaScript64 =>
      "psc-direct-js-declarations-uniform-structural/1"

def psTsEncodeDeclarationRequest (request : PsTsDeclarationRequest) : String :=
  psJsonArray [psJsonQuote (psNatToString request.sourceIndex), psJsonQuote request.exportName]

def psTsEncodeDeclarationCommand (command : PsTsDeclarationCommand) : String :=
  psJsonArray [
    psJsonQuote "psc-ts-declaration-request/1",
    psJsonQuote (psTsEncodeDeclarationProfile command.profile),
    psJsonQuote (psNatToString command.maxBytes),
    psJsonArray (psListMap psTsEncodeDeclarationRequest command.requests)]

def psTsDecodeDeclarationCommand (source : String) :
    Except PsTsDeclarationRequestError PsTsDeclarationCommand :=
  if Nat.ble (String.utf8ByteSize source) 1048576 then
    if psTsDeclarationJsonScanWorker (Nat.succ (String.utf8ByteSize source))
        source (PsTsDeclarationJsonScan.mk 0 0 0 false false) then
      match psJsonParse source with
      | Except.error error => Except.error (PsTsDeclarationRequestError.parse error)
      | Except.ok value =>
          match psTsDecodeDeclarationCommandValue value with
          | Except.error error => Except.error error
          | Except.ok command =>
              if psStringEq (psTsEncodeDeclarationCommand command) source then Except.ok command
              else Except.error PsTsDeclarationRequestError.nonCanonical
    else Except.error PsTsDeclarationRequestError.resource
  else Except.error PsTsDeclarationRequestError.resource
