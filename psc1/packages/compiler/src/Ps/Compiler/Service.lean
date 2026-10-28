import Ps.BackendCommon.ServiceError
import Ps.Compiler.Api
import Ps.Compiler.Ordinary
import Ps.CompilerIr.Encode
import Ps.Bridge.CompilerHost
import Ps.BackendCommon.Plan

-- Scalar candidate transport. All semantic work remains in production compiler
-- APIs; independent admission and publication belong to the external host.
namespace Ps.Internal.CompilerService

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

def decodeRequestFieldsForProtocol (expectedProtocol : String) (arity : Nat)
    (fields : List PsJsonValue) : Except Error Request :=
  if !(Nat.beq (psListLength fields) arity) then Except.error (failure "wire" "request-arity")
  else
    match stringAt fields 0 with
    | Except.error error => Except.error error
    | Except.ok protocol =>
        if !psStringEq protocol expectedProtocol then
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


-- Keep the seven-cell scalar protocol exact. IO is a closed, explicit new
-- request variant; it selects an existing signature ABI, never host authority.
def decodeRequestFields (fields : List PsJsonValue) : Except Error Request :=
  decodeRequestFieldsForProtocol "psc1-compiler-service/1" 7 fields

def decodeOutputRequestFields (fields : List PsJsonValue) :
    Except Error (Prod Request Bool) :=
  let ioProtocol : Bool := match stringAt fields 0 with
    | Except.ok protocol => psStringEq protocol "psc1-compiler-service/2"
    | Except.error _ => false;
  if ioProtocol then
    match decodeRequestFieldsForProtocol "psc1-compiler-service/2" 8 fields with
    | Except.error error => Except.error error
    | Except.ok request =>
        match stringAt fields 7 with
        | Except.error error => Except.error error
        | Except.ok abi =>
            if psStringEq abi "io-dispatcher" then Except.ok (Prod.mk request true)
            else Except.error (failure "wire" "output-abi-unavailable")
  else
    match decodeRequestFields fields with
    | Except.error error => Except.error error
    | Except.ok request => Except.ok (Prod.mk request false)

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

def planFailure (diagnostic : PsBackendClosedPlanDiagnostic) : Error :=
  let owner : String :=
    match diagnostic.specialization with
    | Option.none => ""
    | Option.some detail => detail.owner;
  Error.mk diagnostic.phase (psBackendClosedPlanDiagnosticText diagnostic) "" owner 0 0

-- Public scalar interfaces need no open nominal/generic ABI. Reuse the
-- existing checked closed plan to expose polymorphic structural workers.
-- Other interfaces keep their existing generic route and ABI/refusal rules.
def scalarType (type : PsVerifiedIrType) : Bool :=
  match type with
  | PsVerifiedIrType.primitive _ => true
  | _ => false

def scalarInterface (selected : List String) (declarations : List PsVerifiedIrDeclaration) : Bool :=
  if psListIsEmpty selected then false
  else
    !psListAny
      (fun (declaration : PsVerifiedIrDeclaration) =>
        if psListAny (fun (name : String) => psStringEq name declaration.name) selected then
          !psListIsEmpty declaration.typeParameters ||
            !scalarType declaration.resultType ||
            psListAny (fun (parameter : PsVerifiedIrParameter) => !scalarType parameter.type) declaration.parameters
        else false)
      declarations

def genericTargetPlan (source : PsValidatedIrModule) : Except Error PsValidatedIrModule :=
  match psFuseClosedWorkers source with
  | Except.error code => Except.error (failure "worker-fusion" code)
  | Except.ok result => Except.ok result

def targetPlan (target : PsBackendTarget) (source : PsValidatedIrModule)
    (selected : List String) : Except Error PsValidatedIrModule :=
  if psBackendTargetEq target PsBackendTarget.rust || psBackendTargetEq target PsBackendTarget.ts then
    if scalarInterface selected source.raw.declarations then
      match psBackendClosedPlanDetailed source selected with
      | Except.error _ => genericTargetPlan source
      | Except.ok result => Except.ok result
    else genericTargetPlan source
  else
    match psBackendClosedPlanDetailed source selected with
    | Except.error diagnostic => Except.error (planFailure diagnostic)
    | Except.ok result => Except.ok result

def checkOutputPublicApi (ioDispatcher : Bool) (target : PsBackendTarget)
    (source : PsValidatedIrModule) (selected : List String) : Except String Unit :=
  if ioDispatcher then psBackendCheckIoPublicApi target source selected
  else psBackendCheckPublicApi target source selected

def outputTargetPlan (ioDispatcher : Bool) (target : PsBackendTarget)
    (source : PsValidatedIrModule) (selected : List String) : Except Error PsValidatedIrModule :=
  if ioDispatcher then
    match psBackendClosedPlanDetailed source selected with
    | Except.error diagnostic => Except.error (planFailure diagnostic)
    | Except.ok result => Except.ok result
  else targetPlan target source selected

def compilePreparedWithOutputAbi (ioDispatcher : Bool) (target : PsBackendTarget)
    (emit : PsValidatedIrModule -> List String -> Except Error (Prod String (List String)))
    (request : Request) (captured : Captured)
    (entry : PsSyntaxModule) (work : Semantic) : Except Error String :=
  match psStrictValidateModule work.raw with
  | Except.error _ => Except.error (failure "original-ir" "strict-validation-refused")
  | Except.ok validated =>
      let names : List (Prod PsName String) := psErasureDeclarationNames
        (psErasureRuntimeDeclarations psSelfHostRuntimePreludeDeclarationsWithProd work.source);
      let selected : List String := publicValues (authoredNames names entry.declarations) work.raw.declarations;
      match checkOutputPublicApi ioDispatcher target validated selected with
      | Except.error code => Except.error (failure "public-api" code)
      | Except.ok _ =>
          match outputTargetPlan ioDispatcher target validated selected with
          | Except.error error => Except.error error
          | Except.ok closed =>
              match checkOutputPublicApi ioDispatcher target closed selected with
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
                              let fields : List (Prod String String) := [
                                ("admission", psJsonQuote "not-run"),
                                ("admissionRequest", psCompilerHostAdmissionRequest
                                  request.requestId request.sourceClosureDigest (psBackendTargetName target) work.admissions),
                                ("assurance", psJsonQuote request.assurance),
                                ("candidateOnly", "true"),
                                ("grammar", psJsonQuote request.grammar),
                                ("logicalDeclarations", psNatToString work.logicalCount),
                                ("originalIr", originalIr),
                                ("origins", psJsonArray (psListReverse captured.originsRev)),
                                ("partialNames", psJsonArray (psListMap
                                  (fun (name : PsName) => psJsonQuote (psNameToString name)) work.partialNames)),
                                ("protocol", psJsonQuote
                                  (if ioDispatcher then "psc1-compiler-service/2" else "psc1-compiler-service/1")),
                                ("publicNames", psJsonArray (psListMap psJsonQuote selected)),
                                ("requestId", psJsonQuote request.requestId),
                                ("runtimeRequirements", psJsonArray (psListMap psJsonQuote printed.snd)),
                                ("source", psJsonQuote printed.fst),
                                ("sourceClosureDigest", psJsonQuote request.sourceClosureDigest),
                                ("sourceDeclarations", psNatToString (psListLength work.source)),
                                ("specializedIr", specializedIr),
                                ("status", psJsonQuote "candidate"),
                                ("target", psJsonQuote (psBackendTargetName target))
                              ];
                              let fields : List (Prod String String) :=
                                if ioDispatcher then
                                  List.cons (Prod.mk "outputAbi" (psJsonQuote "io-dispatcher")) fields
                                else fields;
                              Except.ok (psJsonObject fields)

def compilePrepared (target : PsBackendTarget)
    (emit : PsValidatedIrModule -> List String -> Except Error (Prod String (List String)))
    (request : Request) (captured : Captured)
    (entry : PsSyntaxModule) (work : Semantic) : Except Error String :=
  compilePreparedWithOutputAbi false target emit request captured entry work

def compileWithOutputAbi (ioDispatcher : Bool) (target : PsBackendTarget)
    (emit : PsValidatedIrModule -> List String -> Except Error (Prod String (List String)))
    (request : Request) : Except Error String :=
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
              | Except.ok work => compilePreparedWithOutputAbi ioDispatcher target emit request captured entry work

def compile (target : PsBackendTarget)
    (emit : PsValidatedIrModule -> List String -> Except Error (Prod String (List String)))
    (request : Request) : Except Error String :=
  compileWithOutputAbi false target emit request

def refused (target : PsBackendTarget) (requestId digest : String) (error : Error) : String :=
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
    ("target", psJsonQuote (psBackendTargetName target))
  ]

def candidateFields (target : PsBackendTarget)
    (emit : PsValidatedIrModule -> List String -> Except Error (Prod String (List String)))
    (fields : List PsJsonValue) : String :=
  match decodeOutputRequestFields fields with
  | Except.error error => refused target "" "" error
  | Except.ok selected =>
      let request := selected.fst;
      match compileWithOutputAbi selected.snd target emit request with
      | Except.error error => refused target request.requestId request.sourceClosureDigest error
      | Except.ok output => output

def candidate (target : PsBackendTarget)
    (emit : PsValidatedIrModule -> List String -> Except Error (Prod String (List String)))
    (input : String) : String :=
  match psJsonParse input with
  | Except.error _ => refused target "" "" (failure "wire" "invalid-json")
  | Except.ok value =>
      match readArray value with
      | Except.error error => refused target "" "" error
      | Except.ok fields => candidateFields target emit fields

end Ps.Internal.CompilerService
