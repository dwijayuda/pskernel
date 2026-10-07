import Ps.CompilerIr.SourceSignature
import Ps.Foundation.Text

-- This is a descriptive candidate writer. The host must bind these requests to
-- the actual erasure/export inventory and check source/runtime correspondence.
-- Source signatures are never reconstructed from target code.
inductive PsTsDeclarationProfile where
  | closedJavaScript64
  | uniformJavaScript64

structure PsTsDeclarationRequest where
  sourceIndex : Nat
  exportName : String

inductive PsTsDeclarationError where
  | resourcePolicy
  | resourceExhausted
  | requestOrderOrRange
  | exportName
  | sourceDeclaration
  | sourceSignature (error : PsSourceSignatureError)
  | genericExportUnavailable
  | genericValueUnsupported
  | typeParameter

inductive PsTsDeclarationTask where
  | text (value : String)
  | typeNode (type : PsSourceSignatureType) (genericCount : Nat) (depth : Nat)
  | parameters
      (types : List PsSourceSignatureType) (index : Nat)
      (genericCount : Nat) (depth : Nat)
  | generics (parameters : List PsSourceSignatureParameter) (index : Nat)
  | declarations
      (values : List PsPublicApiDeclaration) (sourceIndex : Nat)
      (requests : List PsTsDeclarationRequest) (emitted : Bool)

structure PsTsDeclarationState where
  tasks : List PsTsDeclarationTask
  builder : PsTextBuilder
  byteCount : Nat

def psTsDeclarationScalar (type : PsSourceScalarType) : String :=
  match type with
  | PsSourceScalarType.nat => "bigint"
  | PsSourceScalarType.int => "bigint"
  | PsSourceScalarType.uint8 => "number"
  | PsSourceScalarType.uint16 => "number"
  | PsSourceScalarType.uint32 => "number"
  | PsSourceScalarType.uint64 => "bigint"
  | PsSourceScalarType.usize => "bigint"
  | PsSourceScalarType.int8 => "number"
  | PsSourceScalarType.int16 => "number"
  | PsSourceScalarType.int32 => "number"
  | PsSourceScalarType.int64 => "bigint"
  | PsSourceScalarType.isize => "bigint"
  | PsSourceScalarType.float => "number"
  | PsSourceScalarType.float32 => "number"
  | PsSourceScalarType.bool => "boolean"
  | PsSourceScalarType.char => "string"
  | PsSourceScalarType.string => "string"
  | PsSourceScalarType.unit => "undefined"

def psTsDeclarationIdentifierStart (code : Nat) : Bool :=
  if Nat.beq code 36 then true
  else if Nat.beq code 95 then true
  else if Nat.ble 65 code then
    if Nat.ble code 90 then true
    else if Nat.ble 97 code then Nat.ble code 122
    else false
  else false

def psTsDeclarationIdentifierContinue (code : Nat) : Bool :=
  if psTsDeclarationIdentifierStart code then true
  else if Nat.ble 48 code then Nat.ble code 57
  else false

def psTsDeclarationIdentifierWorker (fuel : Nat) : String -> Nat -> Bool :=
  match fuel with
  | Nat.zero => fun (_value : String) (_offset : Nat) => false
  | Nat.succ remaining =>
      let smaller : String -> Nat -> Bool :=
        psTsDeclarationIdentifierWorker remaining;
      fun (value : String) (offset : Nat) =>
        if String.Internal.atEnd value (String.Pos.Raw.mk offset) then
          Nat.blt 0 offset
        else
          let code : Nat := Char.toNat (String.Internal.get value (String.Pos.Raw.mk offset));
          let valid : Bool :=
            if Nat.beq offset 0 then psTsDeclarationIdentifierStart code
            else psTsDeclarationIdentifierContinue code;
          if valid then smaller value (Nat.succ offset)
          else false

def psTsDeclarationIdentifier (value : String) : Bool :=
  psTsDeclarationIdentifierWorker (Nat.succ (String.utf8ByteSize value)) value 0

def psTsDeclarationWrite
    (maxBytes : Nat) (value : String) (rest : List PsTsDeclarationTask)
    (builder : PsTextBuilder) (byteCount : Nat) :
    Except PsTsDeclarationError PsTsDeclarationState :=
  let nextCount : Nat := Nat.add byteCount (String.utf8ByteSize value);
  if Nat.ble nextCount maxBytes then
    Except.ok (PsTsDeclarationState.mk rest (psTextBuilderAppend builder value) nextCount)
  else Except.error PsTsDeclarationError.resourceExhausted

def psTsDeclarationTypeTasks
    (type : PsSourceSignatureType) (genericCount depth : Nat)
    (rest : List PsTsDeclarationTask) :
    Except PsTsDeclarationError (List PsTsDeclarationTask) :=
  if Nat.ble depth 128 then
    match type with
    | PsSourceSignatureType.scalar scalar =>
        Except.ok (List.cons (PsTsDeclarationTask.text (psTsDeclarationScalar scalar)) rest)
    | PsSourceSignatureType.parameter index =>
        if Nat.blt index genericCount then
          Except.ok
            (List.cons (PsTsDeclarationTask.text (String.Internal.append "T" (psNatToString index))) rest)
        else Except.error PsTsDeclarationError.typeParameter
    | PsSourceSignatureType.array element =>
        Except.ok
          (List.cons (PsTsDeclarationTask.text "Array<")
            (List.cons (PsTsDeclarationTask.typeNode element genericCount (Nat.succ depth))
              (List.cons (PsTsDeclarationTask.text ">") rest)))
    | PsSourceSignatureType.function parameters result =>
        Except.ok
          (List.cons (PsTsDeclarationTask.text "(")
            (List.cons (PsTsDeclarationTask.parameters parameters 0 genericCount (Nat.succ depth))
              (List.cons (PsTsDeclarationTask.text ") => ")
                (List.cons (PsTsDeclarationTask.typeNode result genericCount (Nat.succ depth)) rest))))
  else Except.error PsTsDeclarationError.resourceExhausted

def psTsDeclarationSignatureTasks
    (profile : PsTsDeclarationProfile) (signature : PsSourceSignature)
    (rest : List PsTsDeclarationTask) :
    Except PsTsDeclarationError (List PsTsDeclarationTask) :=
  let count : Nat := psListLength signature.typeParameters;
  let body : List PsTsDeclarationTask :=
    List.cons (PsTsDeclarationTask.typeNode signature.type count 0) rest;
  if Nat.beq count 0 then Except.ok body
  else
    match profile with
    | PsTsDeclarationProfile.closedJavaScript64 =>
        Except.error PsTsDeclarationError.genericExportUnavailable
    | PsTsDeclarationProfile.uniformJavaScript64 =>
        if Nat.ble count 128 then
          match signature.type with
          | PsSourceSignatureType.function parameters _ =>
              match parameters with
              | List.nil => Except.error PsTsDeclarationError.genericValueUnsupported
              | List.cons _ _ =>
                  Except.ok
                    (List.cons (PsTsDeclarationTask.text "<")
                      (List.cons (PsTsDeclarationTask.generics signature.typeParameters 0)
                        (List.cons (PsTsDeclarationTask.text ">") body)))
          | _ => Except.error PsTsDeclarationError.genericValueUnsupported
        else Except.error PsTsDeclarationError.resourceExhausted

def psTsDeclarationSelectedTasks
    (profile : PsTsDeclarationProfile) (maxBytes : Nat)
    (declaration : PsPublicApiDeclaration) (request : PsTsDeclarationRequest)
    (rest : List PsTsDeclarationTask) :
    Except PsTsDeclarationError (List PsTsDeclarationTask) :=
  if Nat.ble (String.utf8ByteSize request.exportName) maxBytes then
    if psTsDeclarationIdentifier request.exportName then
      match declaration with
      | PsPublicApiDeclaration.constant _ _ _ type =>
          match psProjectSourceSignature type with
          | Except.error error =>
              Except.error (PsTsDeclarationError.sourceSignature error)
          | Except.ok signature =>
              let aliasName : String :=
                String.Internal.append "$pscDeclaration" (psNatToString request.sourceIndex);
              let ending : String :=
                psTextJoin "" [";\nexport { ", aliasName, " as ", request.exportName, " };\n"];
              match psTsDeclarationSignatureTasks profile signature
                  (List.cons (PsTsDeclarationTask.text ending) rest) with
              | Except.error error => Except.error error
              | Except.ok body =>
                  Except.ok
                    (List.cons (PsTsDeclarationTask.text
                      (psTextJoin "" ["declare const ", aliasName, ": "])) body)
      | _ => Except.error PsTsDeclarationError.sourceDeclaration
    else Except.error PsTsDeclarationError.exportName
  else Except.error PsTsDeclarationError.resourceExhausted

def psTsDeclarationScanTasks
    (profile : PsTsDeclarationProfile) (maxBytes : Nat)
    (values : List PsPublicApiDeclaration) (sourceIndex : Nat)
    (requests : List PsTsDeclarationRequest) (emitted : Bool)
    (rest : List PsTsDeclarationTask) :
    Except PsTsDeclarationError (List PsTsDeclarationTask) :=
  match requests with
  | List.nil =>
      if emitted then Except.ok rest
      else Except.ok (List.cons (PsTsDeclarationTask.text "export {};\n") rest)
  | List.cons request remaining =>
      if Nat.blt request.sourceIndex sourceIndex then
        Except.error PsTsDeclarationError.requestOrderOrRange
      else
        match values with
        | List.nil => Except.error PsTsDeclarationError.requestOrderOrRange
        | List.cons declaration tail =>
            if Nat.beq request.sourceIndex sourceIndex then
              psTsDeclarationSelectedTasks profile maxBytes declaration request
                (List.cons
                  (PsTsDeclarationTask.declarations tail (Nat.succ sourceIndex) remaining true) rest)
            else
              Except.ok
                (List.cons
                  (PsTsDeclarationTask.declarations tail (Nat.succ sourceIndex) requests emitted) rest)

def psTsDeclarationTasks
    (profile : PsTsDeclarationProfile) (maxBytes : Nat)
    (task : PsTsDeclarationTask) (rest : List PsTsDeclarationTask) :
    Except PsTsDeclarationError (List PsTsDeclarationTask) :=
  match task with
  | PsTsDeclarationTask.typeNode type genericCount depth =>
      psTsDeclarationTypeTasks type genericCount depth rest
  | PsTsDeclarationTask.parameters types index genericCount depth =>
      match types with
      | List.nil => Except.ok rest
      | List.cons type tail =>
          let separator : String := if Nat.beq index 0 then "" else ", ";
          let label : String :=
            psTextJoin "" [separator, "_arg", psNatToString index, ": "];
          Except.ok
            (List.cons (PsTsDeclarationTask.text label)
              (List.cons (PsTsDeclarationTask.typeNode type genericCount depth)
                (List.cons (PsTsDeclarationTask.parameters tail (Nat.succ index) genericCount depth) rest)))
  | PsTsDeclarationTask.generics parameters index =>
      match parameters with
      | List.nil => Except.ok rest
      | List.cons parameter tail =>
          if Nat.beq parameter.index index then
            let separator : String := if Nat.beq index 0 then "" else ", ";
            let label : String :=
              psTextJoin "" [separator, "T", psNatToString index];
            Except.ok
              (List.cons (PsTsDeclarationTask.text label)
                (List.cons (PsTsDeclarationTask.generics tail (Nat.succ index)) rest))
          else Except.error PsTsDeclarationError.typeParameter
  | PsTsDeclarationTask.declarations values sourceIndex requests emitted =>
      psTsDeclarationScanTasks profile maxBytes values sourceIndex requests emitted rest
  | PsTsDeclarationTask.text _ =>
      Except.error PsTsDeclarationError.sourceDeclaration

def psTsDeclarationWorker
    (profile : PsTsDeclarationProfile) (maxBytes fuel : Nat) :
    PsTsDeclarationState -> Except PsTsDeclarationError String :=
  match fuel with
  | Nat.zero =>
      fun (_state : PsTsDeclarationState) => Except.error PsTsDeclarationError.resourceExhausted
  | Nat.succ remaining =>
      let smaller : PsTsDeclarationState -> Except PsTsDeclarationError String :=
        psTsDeclarationWorker profile maxBytes remaining;
      fun (state : PsTsDeclarationState) =>
        match state.tasks with
        | List.nil => Except.ok (psTextBuilderFinish state.builder)
        | List.cons task rest =>
            match task with
            | PsTsDeclarationTask.text value =>
                match psTsDeclarationWrite maxBytes value rest state.builder state.byteCount with
                | Except.error error => Except.error error
                | Except.ok next => smaller next
            | _ =>
                match psTsDeclarationTasks profile maxBytes task rest with
                | Except.error error => Except.error error
                | Except.ok tasks =>
                    smaller (PsTsDeclarationState.mk tasks state.builder state.byteCount)

def psTsEmitDeclarationsWithLimits
    (profile : PsTsDeclarationProfile) (maxSteps maxBytes : Nat)
    (api : PsPublicApiModule) (requests : List PsTsDeclarationRequest) :
    Except PsTsDeclarationError String :=
  if Nat.beq maxSteps 0 then Except.error PsTsDeclarationError.resourcePolicy
  else if Nat.beq maxBytes 0 then Except.error PsTsDeclarationError.resourcePolicy
  else
    psTsDeclarationWorker profile maxBytes maxSteps
      (PsTsDeclarationState.mk
        (List.cons (PsTsDeclarationTask.declarations api.declarations 0 requests false) List.nil)
        psTextBuilderEmpty 0)

def psTsEmitDeclarations
    (profile : PsTsDeclarationProfile) (api : PsPublicApiModule)
    (requests : List PsTsDeclarationRequest) : Except PsTsDeclarationError String :=
  psTsEmitDeclarationsWithLimits profile 1000000 67108864 api requests
