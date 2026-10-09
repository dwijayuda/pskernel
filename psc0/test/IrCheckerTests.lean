import Ps.BackendTs.Checked
import Ps.Host.ProjectCompiler

-- Native host tests are outside the portable bootstrap source closure.
-- The generated-compiler harness exercises a broader table of original IR.
def psIrNativeNat : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

def psIrNativeNatFunction : PsVerifiedIrType :=
  PsVerifiedIrType.function [psIrNativeNat] psIrNativeNat

def psIrNativeLambda : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.lambda [PsVerifiedIrParameter.mk "x" psIrNativeNat]
    psIrNativeNat (PsVerifiedIrExpr.var "x")

def psIrNativeModule (body : PsVerifiedIrExpr) : PsVerifiedIrModule :=
  PsVerifiedIrModule.mk [] [] []
    [PsVerifiedIrDeclaration.mk "nativeResult" [] [] psIrNativeNat body]

def psIrNativePositive : PsVerifiedIrModule :=
  psIrNativeModule
    (PsVerifiedIrExpr.call
      (PsVerifiedIrExpr.letE "functionValue" psIrNativeNatFunction
        psIrNativeLambda (PsVerifiedIrExpr.var "functionValue"))
      [] [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 17)])

def psIrNativeFalseAnnotation : PsVerifiedIrModule :=
  psIrNativeModule
    (PsVerifiedIrExpr.letE "value" psIrNativeNat
      (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool true))
      (PsVerifiedIrExpr.var "value"))

def psIrNativeGroupedCall : PsVerifiedIrModule :=
  psIrNativeModule
    (PsVerifiedIrExpr.call
      (PsVerifiedIrExpr.lambda [PsVerifiedIrParameter.mk "first" psIrNativeNat]
        psIrNativeNatFunction psIrNativeLambda)
      [] [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1),
          PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 2)])

def psIrNativeHasCode (report : PsIrCheckReport) (code : String) : Bool :=
  report.findings.any (fun finding => finding.code == code)

def psIrNativeRejects (ir : PsVerifiedIrModule) (code : String) : Bool :=
  let report := psCheckVerifiedIrModule psIrCheckDefaultOptions ir
  !report.accepted && report.traversalComplete && psIrNativeHasCode report code

def psIrNativeCases : List (String × Bool) :=
  let accepted := psCheckVerifiedIrModule psIrCheckDefaultOptions psIrNativePositive
  let noSteps := psCheckVerifiedIrModule
    { psIrCheckDefaultOptions with maxSteps := 0 } psIrNativePositive
  let noTypeSteps := psCheckVerifiedIrModule
    { psIrCheckDefaultOptions with maxTypeSteps := 0 } psIrNativePositive
  let noDetails := psCheckVerifiedIrModule
    { psIrCheckDefaultOptions with maxFindings := 0 } psIrNativeFalseAnnotation
  [
    ("function-valued let has compositional type",
      accepted.accepted && accepted.traversalComplete && accepted.findingCount == 0),
    ("checked emitter accepts the same valid IR",
      match psTsEmitCheckedModule psIrCheckDefaultOptions psIrNativePositive with
      | Except.ok output => !output.isEmpty
      | Except.error _ => false),
    ("false let annotation is rejected",
      psIrNativeRejects psIrNativeFalseAnnotation "type-mismatch"),
    ("checked emitter refuses invalid IR",
      match psTsEmitCheckedModule psIrCheckDefaultOptions psIrNativeFalseAnnotation with
      | Except.error (PsTsCheckedEmitError.check report) =>
          !report.accepted && psIrNativeHasCode report "type-mismatch"
      | _ => false),
    ("function parameter grouping is preserved",
      psIrNativeRejects psIrNativeGroupedCall "call-runtime-arity"),
    ("expression fuel exhaustion is explicit",
      !noSteps.accepted && !noSteps.traversalComplete &&
        psIrNativeHasCode noSteps "checker-input-resource-limit"),
    ("type fuel exhaustion is explicit",
      !noTypeSteps.accepted && psIrNativeHasCode noTypeSteps "type-resource-limit"),
    ("diagnostic cap preserves finding count",
      !noDetails.accepted && noDetails.findingCount > 0 && noDetails.findings.isEmpty)
  ]


inductive PsIrNativeTypeJsonTask where
  | type (value : PsVerifiedIrType)
  | items (values : List PsVerifiedIrType) (first : Bool)
  | text (value : String)

-- A single budget includes type nodes, list cells, and output fragments.
-- Exhaustion replaces this diagnostic type with an explicit marker.
def psIrNativeTypeJsonWorker
    (fuel : Nat) (pending : List PsIrNativeTypeJsonTask)
    (fragmentsRev : List String) : Option String :=
  match fuel with
  | 0 =>
      if pending.isEmpty then some (psJsonJoin "" fragmentsRev.reverse)
      else none
  | remaining + 1 =>
      match pending with
      | [] => some (psJsonJoin "" fragmentsRev.reverse)
      | task :: rest =>
          match task with
          | .text value =>
              psIrNativeTypeJsonWorker remaining rest (value :: fragmentsRev)
          | .items values first =>
              match values with
              | [] => psIrNativeTypeJsonWorker remaining rest fragmentsRev
              | value :: tail =>
                  psIrNativeTypeJsonWorker remaining
                    (.text (if first then "" else ",") ::
                     .type value :: .items tail false :: rest) fragmentsRev
          | .type value =>
              match value with
              | .unknown =>
                  psIrNativeTypeJsonWorker remaining rest
                    (psJsonObject [("kind", psJsonQuote "unknown")] :: fragmentsRev)
              | .typeParameter name =>
                  psIrNativeTypeJsonWorker remaining rest
                    (psJsonObject [("kind", psJsonQuote "typeParameter"),
                      ("name", psJsonQuote name)] :: fragmentsRev)
              | .primitive primitive =>
                  psIrNativeTypeJsonWorker remaining rest
                    (psJsonObject [("kind", psJsonQuote "primitive"),
                      ("name", psJsonQuote (psIrCheckPrimitiveName primitive))] :: fragmentsRev)
              | .function parameters result =>
                  psIrNativeTypeJsonWorker remaining
                    (.text "{\"kind\":\"function\",\"parameters\":[" ::
                     .items parameters true :: .text "],\"result\":" ::
                     .type result :: .text "}" :: rest) fragmentsRev
              | .named name arguments =>
                  psIrNativeTypeJsonWorker remaining
                    (.text ("{\"kind\":\"named\",\"name\":" ++ psJsonQuote name ++
                      ",\"arguments\":[") ::
                     .items arguments true :: .text "]}" :: rest) fragmentsRev

def psIrNativeTypeJson (fuel : Nat) (type : PsVerifiedIrType) : String :=
  match psIrNativeTypeJsonWorker fuel [.type type] [] with
  | some text => text
  | none => psJsonObject
      [("detailOmitted", psJsonQuote "diagnostic-type-node-limit"),
       ("maxSteps", toString fuel)]

def psIrNativeOptionalTypeJson (type : Option PsVerifiedIrType) : String :=
  match type with
  | none => "null"
  | some value => psIrNativeTypeJson 4096 value

def psIrNativeFindingJson (finding : PsIrCheckFinding) : String :=
  psJsonObject
    [("code", psJsonQuote finding.code),
     ("detail", psJsonQuote finding.detail),
     ("owner", psJsonQuote finding.owner),
     ("path", psJsonQuote finding.path),
     ("expected", psIrNativeOptionalTypeJson finding.expected),
     ("actual", psIrNativeOptionalTypeJson finding.actual)]

def psIrNativeReportFields (report : PsIrCheckReport) : List (String × String) :=
  [("schemaVersion", "1"),
   ("kind", psJsonQuote "psc0-native-original-ir-check"),
   ("accepted", if report.accepted then "true" else "false"),
   ("traversalComplete", if report.traversalComplete then "true" else "false"),
   ("visitedSteps", toString report.visitedSteps),
   ("expressionCount", toString report.expressionCount),
   ("findingCount", toString report.findingCount),
   ("retainedFindingCount", toString report.findings.length),
   ("omittedFindingDetails", toString (report.findingCount - report.findings.length)),
   ("strictSh1Qualified", "false")]

def psIrNativeLeanErrorText (error : PsLeanFrontendError) : String :=
  match error with
  | .lex failure => "lexer: " ++ psHostLexErrorText failure
  | .parse failure => "parser: " ++ psHostParseErrorText failure

def psIrNativeProofScriptErrorText (error : PsProofScriptFrontendError) : String :=
  match error with
  | .lex failure => "lexer: " ++ psHostLexErrorText failure
  | .parse failure => "parser: " ++ psHostParseErrorText failure

def psIrNativePrintErrorText (error : PsSourcePrintError) : String :=
  match error with
  | .fuelExhausted => "printer: fuel exhausted"
  | .unsupportedApplication => "printer: unsupported application"
  | .emptyName => "printer: empty name"
  | .unsupportedSourceForm message => "printer: unsupported source form: " ++ message

def psIrNativeTranslationErrorText (error : PsTranslationError) : String :=
  match error with
  | .leanFrontend failure => "Lean " ++ psIrNativeLeanErrorText failure
  | .proofScriptFrontend failure => "ProofScript " ++ psIrNativeProofScriptErrorText failure
  | .print failure => psIrNativePrintErrorText failure

def psIrNativeAdmissionErrorText (error : PsCheckedAdmissionCodecError) : String :=
  match error with
  | .universeMetavariable => "universe metavariable"
  | .freeVariable => "free variable"
  | .expressionMetavariable => "expression metavariable"
  | .missingConstructor name => "missing constructor: " ++ psNameToString name
  | .mismatchedConstructor name => "mismatched constructor: " ++ psNameToString name
  | .unsupportedDeclaration => "unsupported declaration"

def psIrNativeErasureErrorText (error : PsErasureError) : String :=
  match error with
  | .fuelExhausted => "fuel exhausted"
  | .binderMismatch => "binder mismatch"
  | .looseBoundVariable => "loose bound variable"
  | .unresolvedMetavariable => "unresolved metavariable"
  | .unknownLocal id => "unknown local: " ++ toString id
  | .erasedLocalUsed id => "erased local used: " ++ toString id
  | .unsupportedRuntimeTerm => "unsupported runtime term"
  | .unsupportedApplication => "unsupported application"
  | .unknownConstant name => "unknown constant: " ++ psNameToString name

def psIrNativeCompilerErrorText (error : PsCompilerError) : String :=
  match error with
  | .translation failure => "translation: " ++ psIrNativeTranslationErrorText failure
  | .leanFrontend failure => "Lean " ++ psIrNativeLeanErrorText failure
  | .proofScriptFrontend failure => "ProofScript " ++ psIrNativeProofScriptErrorText failure
  | .elaboration failure => "elaboration: " ++ psHostElabErrorText failure
  | .admission failure => "admission codec: " ++ psIrNativeAdmissionErrorText failure
  | .erasure failure => "erasure: " ++ psIrNativeErasureErrorText failure

def psIrNativeEmitErrorText (error : PsTsEmitError) : String :=
  match error with
  | .fuelExhausted => "fuel exhausted"
  | .unsupportedIntrinsic => "unsupported intrinsic"
  | .intrinsicArity => "intrinsic arity"
  | .unknownStructure name => "unknown structure: " ++ name
  | .unknownInductive name => "unknown inductive: " ++ name
  | .genericValueUnsupported name => "unsupported generic value: " ++ name
  | .targetWordSizeRequired => "target word size required"

def psIrNativeFailure {alpha : Type}
    (failurePath sourcePath stage detail : String) : IO alpha := do
  let evidence := psJsonObject
    [("schemaVersion", "1"),
     ("kind", psJsonQuote "psc0-native-original-ir-failure"),
     ("sourcePath", psJsonQuote sourcePath),
     ("stage", psJsonQuote stage),
     ("detail", psJsonQuote detail),
     ("strictSh1Qualified", "false")]
  IO.FS.writeFile failurePath (evidence ++ "\n")
  IO.println ("PSC0_SH1_IR_NATIVE_ERROR: " ++ evidence)
  throw (IO.userError ("PSC0_SH1_IR_NATIVE_CURRENT_" ++ stage ++ ": " ++ detail))

def psIrNativeCheckCurrentSource (sourcePath outputPath : String) : IO Unit := do
  let source ← IO.FS.readFile sourcePath
  let reportPath := outputPath ++ ".ir-report.json"
  let failurePath := outputPath ++ ".ir-error.json"
  let prepared ← match psCompilerPrepareSource PsCompilerSourceKind.lean source with
    | Except.error error =>
        psIrNativeFailure failurePath sourcePath "PREPARE" (psIrNativeCompilerErrorText error)
    | Except.ok value => pure value
  let ir ← match psCompilerVerifiedIrFromPrepared prepared with
    | Except.error error =>
        psIrNativeFailure failurePath sourcePath "ERASURE" (psIrNativeCompilerErrorText error)
    | Except.ok value => pure value
  let report := psCheckVerifiedIrModule psIrCheckDefaultOptions ir
  let summaryFields := psIrNativeReportFields report
  let evidence := psJsonObject
    (summaryFields ++
      [("sourcePath", psJsonQuote sourcePath),
       ("typeDiagnosticMaxSteps", "4096"),
       ("findings", psJsonArray (report.findings.map psIrNativeFindingJson))])
  -- Preserve the full typed report before any rejection or subsequent emission.
  IO.FS.writeFile reportPath (evidence ++ "\n")
  for finding in report.findings do
    IO.println ("PSC0_SH1_IR_NATIVE_FINDING: " ++ psIrNativeFindingJson finding)
  IO.println ("PSC0_SH1_IR_NATIVE_FULL: " ++ psJsonObject
    (summaryFields ++ [("reportPath", psJsonQuote reportPath)]))
  if !report.accepted || !report.traversalComplete then
    psIrNativeFailure failurePath sourcePath "REJECTED"
      ("runtime IR check rejected; findings=" ++ toString report.findingCount ++
       "; report=" ++ reportPath)
  -- The same native IR is emitted synchronously after successful checking.
  let output ← match psTsEmitModule ir with
    | Except.error error =>
        psIrNativeFailure failurePath sourcePath "EMIT" (psIrNativeEmitErrorText error)
    | Except.ok value => pure value
  IO.FS.writeFile outputPath output


def main (args : List String) : IO Unit := do
  let cases := psIrNativeCases
  for item in cases do
    if item.snd then
      IO.println ("PSC0_SH1_IR_NATIVE_PASS: " ++ item.fst)
    else
      throw (IO.userError ("PSC0_SH1_IR_NATIVE_FAIL: " ++ item.fst))
  IO.println ("PSC0_SH1_IR_NATIVE: {\"schemaVersion\":1,\"status\":\"pass\",\"cases\":" ++
    toString cases.length ++ ",\"checkedEmitterRejectsInvalidIr\":true,\"strictSh1Qualified\":false}")
  match args with
  | [] => pure ()
  | [sourcePath, outputPath] => psIrNativeCheckCurrentSource sourcePath outputPath
  | _ => throw (IO.userError "usage: psc1_ir_check_tests [source.lean checked.ts]")
