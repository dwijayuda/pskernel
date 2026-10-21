import Ps.Compiler.Api
import Ps.Compiler.Ordinary
import Ps.CompilerIr.Encode
import Ps.Bridge.CompilerHost
import Ps.BackendCommon.Plan
import Ps.BackendJs.Print

-- Scalar candidate transport. All semantic work remains in production compiler
-- APIs; independent admission and publication belong to the external host.
namespace Ps.Internal.JsCompilerService

structure Error where
  phase : String
  code : String
  moduleName : String
  declaration : String
  line : Nat
  column : Nat

def failure (phase code : String) : Error :=
  Error.mk phase code "" "" 0 0

structure Source where
  moduleName : String
  text : String

structure Request where
  requestId : String
  sourceClosureDigest : String
  kind : PsCompilerSourceKind
  grammar : String
  assurance : String
  entry : String
  sources : List Source

def atWorker (values : List PsJsonValue) : Nat -> Except Error PsJsonValue :=
  match values with
  | List.nil => fun (_index : Nat) => Except.error (failure "wire" "array-arity")
  | List.cons value rest =>
      let smaller : Nat -> Except Error PsJsonValue := atWorker rest;
      fun (index : Nat) =>
        match index with
        | Nat.zero => Except.ok value
        | Nat.succ remaining => smaller remaining

def readString (value : PsJsonValue) : Except Error String :=
  match value with
  | PsJsonValue.string text => Except.ok text
  | _ => Except.error (failure "wire" "expected-string")

def readArray (value : PsJsonValue) : Except Error (List PsJsonValue) :=
  match value with
  | PsJsonValue.array values => Except.ok values
  | _ => Except.error (failure "wire" "expected-array")

def stringAt (values : List PsJsonValue) (index : Nat) : Except Error String :=
  match atWorker values index with
  | Except.error error => Except.error error
  | Except.ok value => readString value

def decodeSource (value : PsJsonValue) : Except Error Source :=
  match readArray value with
  | Except.error error => Except.error error
  | Except.ok fields =>
      if !(Nat.beq (psListLength fields) 2) then
        Except.error (failure "wire" "source-arity")
      else
        match stringAt fields 0 with
        | Except.error error => Except.error error
        | Except.ok name =>
            if psStringEq name "" then Except.error (failure "wire" "empty-module")
            else
              match stringAt fields 1 with
              | Except.error error => Except.error error
              | Except.ok text => Except.ok (Source.mk name text)

def decodeRequestFields (fields : List PsJsonValue) : Except Error Request :=
  if !(Nat.beq (psListLength fields) 7) then Except.error (failure "wire" "request-arity")
  else
    match stringAt fields 0 with
    | Except.error error => Except.error error
    | Except.ok protocol =>
        if !psStringEq protocol "psc1-compiler-service/1" then
          Except.error (failure "wire" "protocol")
        else
          match stringAt fields 1 with
          | Except.error error => Except.error error
          | Except.ok requestId =>
              match stringAt fields 2 with
              | Except.error error => Except.error error
              | Except.ok digest =>
                  match stringAt fields 3 with
                  | Except.error error => Except.error error
                  | Except.ok grammar =>
                      let kind : Except Error PsCompilerSourceKind :=
                        if psStringEq grammar "lean" then Except.ok PsCompilerSourceKind.lean
                        else if psStringEq grammar "ps" then Except.ok PsCompilerSourceKind.proofScript
                        else Except.error (failure "wire" "grammar");
                      match kind with
                      | Except.error error => Except.error error
                      | Except.ok sourceKind =>
                          match stringAt fields 4 with
                          | Except.error error => Except.error error
                          | Except.ok assurance =>
                              if !(psStringEq assurance "checked" || psStringEq assurance "ordinary-checked") then
                                Except.error (failure "wire" "assurance-unavailable")
                              else
                                match stringAt fields 5 with
                                | Except.error error => Except.error error
                                | Except.ok entry =>
                                    match atWorker fields 6 with
                                    | Except.error error => Except.error error
                                    | Except.ok sourceValue =>
                                        match readArray sourceValue with
                                        | Except.error error => Except.error error
                                        | Except.ok sourceValues =>
                                            match psListMapExcept decodeSource sourceValues with
                                            | Except.error error => Except.error error
                                            | Except.ok sources =>
                                                if psStringEq requestId "" || psStringEq digest "" ||
                                                    psStringEq entry "" || psListIsEmpty sources then
                                                  Except.error (failure "wire" "empty-request-identity")
                                                else Except.ok (Request.mk requestId digest sourceKind
                                                  grammar assurance entry sources)

def decode (text : String) : Except Error Request :=
  match psJsonParse text with
  | Except.error _ => Except.error (failure "wire" "invalid-json")
  | Except.ok value =>
      match readArray value with
      | Except.error error => Except.error error
      | Except.ok fields => decodeRequestFields fields

structure Captured where
  state : PsCompilerPreparationState
  seen : List String
  graphRev : List (Prod String (List String))
  originsRev : List String
  entry : Option PsSyntaxModule

def originJson (origin : PsElabBatchOrigin) : String :=
  psJsonArray [
    psNatToString origin.sourceIndex,
    psJsonQuote (psParseNamespaceText origin.sourceName.segments),
    psNatToString origin.span.start.line,
    psNatToString origin.span.start.column,
    psJsonArray (psListMap (fun (member : PsElabMemberOrigin) =>
      psJsonArray [psNatToString member.index, psJsonQuote (psNameToString member.name)])
      origin.members)
  ]

def captureWorker (request : Request) (sources : List Source) :
    Captured -> Except Error Captured :=
  match sources with
  | List.nil => fun (captured : Captured) => Except.ok captured
  | List.cons source rest =>
      let smaller : Captured -> Except Error Captured := captureWorker request rest;
      fun (captured : Captured) =>
        if psBackendNameSeen source.moduleName captured.seen then
          Except.error (Error.mk "capture" "duplicate-module" source.moduleName "" 0 0)
        else
          match psCompilerParseSource request.kind source.text with
          | Except.error _ =>
              Except.error (Error.mk "parse" "source-refused" source.moduleName "" 0 0)
          | Except.ok parsed =>
              let imports : List String := psListMap
                (fun (item : PsSyntaxImport) => psParseNamespaceText item.moduleName.segments)
                parsed.imports;
              if psListAny (fun (name : String) => !psBackendNameSeen name captured.seen) imports then
                Except.error (Error.mk "capture" "import-order-or-missing" source.moduleName "" 0 0)
              else
                match psCompilerPreparationStepParsedWithOrigins captured.state parsed with
                | Except.error error =>
                    Except.error (Error.mk "elaboration" "source-refused" source.moduleName
                      (psParseNamespaceText error.sourceName.segments)
                      error.span.start.line error.span.start.column)
                | Except.ok next =>
                    let entry : Option PsSyntaxModule :=
                      if psStringEq source.moduleName request.entry then Option.some parsed
                      else captured.entry;
                    let origins : String := psJsonArray [
                      psJsonQuote source.moduleName, psNatToString (String.utf8ByteSize source.text),
                      psJsonArray (psListMap psJsonQuote imports),
                      psJsonArray (psListMap originJson next.origins)
                    ];
                    smaller (Captured.mk next.state (List.cons source.moduleName captured.seen)
                      (List.cons (Prod.mk source.moduleName imports) captured.graphRev)
                      (List.cons origins captured.originsRev) entry)

-- In reverse topological order, every needed caller has already contributed all
-- its imports. An unneeded row is an extra captured module and refuses.
def exactClosureWorker (graphRev : List (Prod String (List String))) :
    List String -> Except Error Unit :=
  match graphRev with
  | List.nil => fun (_needed : List String) => Except.ok Unit.unit
  | List.cons row rest =>
      let smaller : List String -> Except Error Unit := exactClosureWorker rest;
      fun (needed : List String) =>
        if psBackendNameSeen row.fst needed then
          smaller (psListAppend row.snd needed)
        else Except.error (Error.mk "capture" "extra-module" row.fst "" 0 0)

structure Semantic where
  admissions : String
  source : List PsDeclaration
  logicalCount : Nat
  partialNames : List PsName
  raw : PsVerifiedIrModule

def prepare (request : Request) (captured : Captured) : Except Error Semantic :=
  let source : PsElabModuleResult := psCompilerPreparationElaborated captured.state;
  if psStringEq request.assurance "checked" then
    match psCompilerPrepareElaboratedWithOutput source with
    | Except.error _ => Except.error (failure "preparation" "checked-preparation-refused")
    | Except.ok prepared =>
        match psCompilerVerifiedIrFromPrepared prepared.prepared with
        | Except.error _ => Except.error (failure "erasure" "checked-erasure-refused")
        | Except.ok raw =>
            Except.ok (Semantic.mk prepared.admissions prepared.prepared.declarations
              (psListLength prepared.prepared.declarations) [] raw)
  else
    match psCompilerPrepareOrdinary source with
    | Except.error code => Except.error (failure "preparation" code)
    | Except.ok prepared =>
        match psCompilerAdmissionsFromPrepared prepared.logical with
        | Except.error _ => Except.error (failure "preparation" "ordinary-admissions-refused")
        | Except.ok admissions =>
            match psCompilerOrdinaryIr prepared with
            | Except.error code => Except.error (failure "erasure" code)
            | Except.ok raw =>
                Except.ok (Semantic.mk admissions prepared.source.declarations
                  (psListLength prepared.logical.declarations) prepared.partialNames raw)

def runtimeName (name : PsName) (names : List (Prod PsName String)) : Option String :=
  match names with
  | List.nil => Option.none
  | List.cons row rest =>
      if psNameEq name row.fst then Option.some row.snd else runtimeName name rest

def authoredNames (names : List (Prod PsName String))
    (declarations : List PsSyntaxDeclaration) : List String :=
  match declarations with
  | List.nil => []
  | List.cons declaration rest =>
      let others : List String := authoredNames names rest;
      if psSyntaxDeclarationIsCompilerImplementation declaration then others
      else
        match psSyntaxDeclarationQualifiedName declaration with
        | Option.none => others
        | Option.some name =>
            match psSyntaxNameToName name with
            | Option.none => others
            | Option.some coreName =>
                match runtimeName coreName names with
                | Option.none => others
                | Option.some value => List.cons value others

def publicValues (authored : List String) (declarations : List PsVerifiedIrDeclaration) : List String :=
  match declarations with
  | List.nil => []
  | List.cons declaration rest =>
      let others : List String := publicValues authored rest;
      if psBackendNameSeen declaration.name authored then List.cons declaration.name others else others

def emit (module : PsValidatedIrModule) (publicNames : List String) :
    Except Error (Prod String (List String)) :=
  match psJsLowerValidatedModuleWithTargetProfile (PsJsTargetProfile.mk PsJsWordSize.bits64) module with
  | Except.error _ => Except.error (failure "js-lowering" "target-refused")
  | Except.ok jsIr =>
      match psJsValidateModule jsIr with
      | Except.error _ => Except.error (failure "js-validation" "target-refused")
      | Except.ok _ =>
          match psJsPrintDeclarationsWith
              (fun (declaration : PsJsIrDeclaration) =>
                psJsPrintDeclarationStackSafeWithVisibility
                  (psBackendNameSeen declaration.name publicNames) declaration)
              jsIr.declarations psTextBuilderEmpty with
          | Except.error _ => Except.error (failure "js-printing" "target-refused")
          | Except.ok declarations =>
              let suffix : String := if psListIsEmpty publicNames then "\nexport {};\n" else "";
              Except.ok (Prod.mk
                (psJsConcat3 (psJsPrintStackSafePrelude jsIr) declarations suffix)
                (psJsSelectedRuntimeRequirements jsIr))

def compilePrepared (request : Request) (captured : Captured)
    (entry : PsSyntaxModule) (work : Semantic) : Except Error String :=
  match psStrictValidateModule work.raw with
  | Except.error _ => Except.error (failure "original-ir" "strict-validation-refused")
  | Except.ok validated =>
      let names : List (Prod PsName String) := psErasureDeclarationNames
        (psErasureRuntimeDeclarations psSelfHostRuntimePreludeDeclarationsWithProd work.source);
      let selected : List String := publicValues (authoredNames names entry.declarations) work.raw.declarations;
      match psBackendCheckPublicApi PsBackendTarget.js validated selected with
      | Except.error code => Except.error (failure "public-api" code)
      | Except.ok _ =>
          match psBackendClosedPlan validated selected with
          | Except.error code => Except.error (failure "specialization" code)
          | Except.ok closed =>
              match psBackendCheckPublicApi PsBackendTarget.js closed selected with
              | Except.error code => Except.error (failure "public-api" code)
              | Except.ok _ =>
                  match psIrEncodeModule work.raw with
                  | Except.error _ => Except.error (failure "original-ir-encoding" "depth-exhausted")
                  | Except.ok originalIr =>
                      match psIrEncodeModule closed.raw with
                      | Except.error _ => Except.error (failure "specialized-ir-encoding" "depth-exhausted")
                      | Except.ok specializedIr =>
                          match emit closed selected with
                          | Except.error error => Except.error error
                          | Except.ok printed =>
                              Except.ok (psJsonObject [
                                ("admission", psJsonQuote "not-run"),
                                ("admissionRequest", psCompilerHostAdmissionRequest
                                  request.requestId request.sourceClosureDigest "js" work.admissions),
                                ("assurance", psJsonQuote request.assurance),
                                ("candidateOnly", "true"),
                                ("grammar", psJsonQuote request.grammar),
                                ("logicalDeclarations", psNatToString work.logicalCount),
                                ("originalIr", originalIr),
                                ("origins", psJsonArray (psListReverse captured.originsRev)),
                                ("partialNames", psJsonArray (psListMap
                                  (fun (name : PsName) => psJsonQuote (psNameToString name)) work.partialNames)),
                                ("protocol", psJsonQuote "psc1-compiler-service/1"),
                                ("publicNames", psJsonArray (psListMap psJsonQuote selected)),
                                ("requestId", psJsonQuote request.requestId),
                                ("runtimeRequirements", psJsonArray (psListMap psJsonQuote printed.snd)),
                                ("source", psJsonQuote printed.fst),
                                ("sourceClosureDigest", psJsonQuote request.sourceClosureDigest),
                                ("sourceDeclarations", psNatToString (psListLength work.source)),
                                ("specializedIr", specializedIr),
                                ("status", psJsonQuote "candidate"),
                                ("target", psJsonQuote "js")
                              ])

def compile (request : Request) : Except Error String :=
  let initial : Captured :=
    Captured.mk (psCompilerPreparationStart request.kind) [] [] [] Option.none;
  match captureWorker request request.sources initial with
  | Except.error error => Except.error error
  | Except.ok captured =>
      match captured.entry with
      | Option.none => Except.error (failure "capture" "entry-missing")
      | Option.some entry =>
          match exactClosureWorker captured.graphRev [request.entry] with
          | Except.error error => Except.error error
          | Except.ok _ =>
              match prepare request captured with
              | Except.error error => Except.error error
              | Except.ok work => compilePrepared request captured entry work

def refused (requestId digest : String) (error : Error) : String :=
  psJsonObject [
    ("admission", psJsonQuote "not-run"),
    ("candidateOnly", "true"),
    ("code", psJsonQuote error.code),
    ("column", psNatToString error.column),
    ("declaration", psJsonQuote error.declaration),
    ("line", psNatToString error.line),
    ("module", psJsonQuote error.moduleName),
    ("phase", psJsonQuote error.phase),
    ("protocol", psJsonQuote "psc1-compiler-service/1"),
    ("requestId", psJsonQuote requestId),
    ("sourceClosureDigest", psJsonQuote digest),
    ("status", psJsonQuote "refused"),
    ("target", psJsonQuote "js")
  ]

def candidate (input : String) : String :=
  match decode input with
  | Except.error error => refused "" "" error
  | Except.ok request =>
      match compile request with
      | Except.error error => refused request.requestId request.sourceClosureDigest error
      | Except.ok output => output

end Ps.Internal.JsCompilerService

/-- Scalar transport of provisional compiler work only. An external hash-pinned
host must independently admit the exact graph and validate targets before any
publication. No compiler/transport response can authorize that host operation. -/
def psCompilerJsServiceCandidate (input : String) : String :=
  Ps.Internal.JsCompilerService.candidate input
