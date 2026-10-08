import Ps.DriverJs.Bootstrap
import Ps.CompilerIr.Encode
import Ps.BackendJs.Encode

inductive PsCompilerJavaScriptStagesError where
  | compiler (error : PsCompilerError)
  | javaScript (error : PsCompilerJavaScriptError)
  | encode (error : PsIrEncodeError)
  | targetValidation (error : PsJsIrValidationError)
  | targetSnapshot (error : PsJsIrEncodeError)

structure PsCompilerJavaScriptStages where
  javaScript : String
  runtimeIr : String
  verifiedIr : String
  specializedIr : String
  jsIr : String
  erasureCorrespondence : String
  generatedPositions : String

structure PsCompilerJavaScriptTargetProduct where
  javaScript : String
  jsIr : String
  generatedPositions : String

-- Both representation strategies use the same target validator and writer.
def psCompilerJavaScriptTargetFromIr
    (jsIr : PsJsIrModule) :
    Except PsCompilerJavaScriptStagesError PsCompilerJavaScriptTargetProduct :=
  match psJsValidateModule jsIr with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptStagesError.targetValidation error)
  | Except.ok _ =>
      match psJsIrEncodeModule jsIr with
      | Except.error error =>
          Except.error (PsCompilerJavaScriptStagesError.targetSnapshot error)
      | Except.ok targetIr =>
          match psJsPrintModuleStackSafeWithPositions jsIr with
          | Except.error error =>
              Except.error
                (PsCompilerJavaScriptStagesError.javaScript
                  (PsCompilerJavaScriptError.emit error))
          | Except.ok output =>
              Except.ok
                (PsCompilerJavaScriptTargetProduct.mk
                  output.text targetIr
                  (psJsEncodeGeneratedPositions output.spans))

structure PsCompilerJavaScriptValidatedInputs where
  runtimeIr : String
  verifiedIr : String
  erasureCorrespondence : String
  validated : PsValidatedIrModule

def psCompilerJavaScriptValidatedInputsFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerJavaScriptStagesError PsCompilerJavaScriptValidatedInputs :=
  match psCompilerErasureProductFromPrepared prepared with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptStagesError.compiler error)
  | Except.ok product =>
      match psIrEncodeModule product.erased.raw with
      | Except.error error =>
          Except.error (PsCompilerJavaScriptStagesError.encode error)
      | Except.ok runtime =>
          match psValidateErasedIrModule product.erased with
          | Except.error error =>
              Except.error
                (PsCompilerJavaScriptStagesError.compiler
                  (PsCompilerError.irValidation error))
          | Except.ok validated =>
              match psIrEncodeModule validated.raw with
              | Except.error error =>
                  Except.error (PsCompilerJavaScriptStagesError.encode error)
              | Except.ok verified =>
                  Except.ok
                    (PsCompilerJavaScriptValidatedInputs.mk
                      runtime verified product.correspondence validated)

-- The snapshots come from one actual pipeline execution. A checked host
-- capability is still required for production access to this internal API.
def psCompilerJavaScriptStagesFromValidated
    (runtime verified erasureCorrespondence : String)
    (validated : PsValidatedIrModule) :
    Except PsCompilerJavaScriptStagesError PsCompilerJavaScriptStages :=
  match psCompilerJavaScriptSpecializeValidatedIr validated with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptStagesError.javaScript error)
  | Except.ok specialized =>
      match psValidateErasedIrModule (PsErasedIrModule.mk specialized.raw) with
      | Except.error error =>
          Except.error
            (PsCompilerJavaScriptStagesError.compiler
              (PsCompilerError.irValidation error))
      | Except.ok _ =>
          match psIrEncodeModule specialized.raw with
          | Except.error error =>
              Except.error (PsCompilerJavaScriptStagesError.encode error)
          | Except.ok encoded =>
              match
                  psJsLowerSpecializedValidatedModuleWithProfile
                    (Option.some psCompilerJavaScriptTarget64) specialized with
              | Except.error error =>
                  Except.error
                    (PsCompilerJavaScriptStagesError.javaScript
                      (PsCompilerJavaScriptError.emit (PsJsEmitError.lower error)))
              | Except.ok jsIr =>
                  match psCompilerJavaScriptTargetFromIr jsIr with
                  | Except.error error => Except.error error
                  | Except.ok output =>
                      Except.ok
                        (PsCompilerJavaScriptStages.mk
                          output.javaScript runtime verified encoded output.jsIr
                          erasureCorrespondence output.generatedPositions)

def psCompilerJavaScriptStagesFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerJavaScriptStagesError PsCompilerJavaScriptStages :=
  match psCompilerJavaScriptValidatedInputsFromPrepared prepared with
  | Except.error error => Except.error error
  | Except.ok inputs =>
      psCompilerJavaScriptStagesFromValidated
        inputs.runtimeIr inputs.verifiedIr inputs.erasureCorrespondence inputs.validated

-- A different stage product prevents generic RuntimeIR from masquerading as
-- closed SpecializedIR. The uniform payload retains every validated definition.
structure PsCompilerUniformJavaScriptStages where
  javaScript : String
  runtimeIr : String
  verifiedIr : String
  uniformSpecializedIr : String
  jsIr : String
  erasureCorrespondence : String
  generatedPositions : String

def psCompilerUniformJavaScriptStagesFromValidated
    (runtime verified erasureCorrespondence : String)
    (validated : PsValidatedIrModule) :
    Except PsCompilerJavaScriptStagesError PsCompilerUniformJavaScriptStages :=
  let selected := psIrSelectUniformSpecialization validated;
  match psIrEncodeModule selected.raw with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptStagesError.encode error)
  | Except.ok raw =>
      let encoded :=
        psJsonArray
          (List.cons (psJsonQuote "psc-uniform-specialized-ir/1")
            (List.cons (psJsonQuote "psc-js-uniform-values/1")
              (List.cons raw List.nil)));
      match
          psJsLowerUniformSpecializedModuleWithProfile
            (Option.some psCompilerJavaScriptTarget64) selected with
      | Except.error error =>
          Except.error
            (PsCompilerJavaScriptStagesError.javaScript
              (PsCompilerJavaScriptError.emit (PsJsEmitError.lower error)))
      | Except.ok jsIr =>
          match psCompilerJavaScriptTargetFromIr jsIr with
          | Except.error error => Except.error error
          | Except.ok output =>
              Except.ok
                (PsCompilerUniformJavaScriptStages.mk
                  output.javaScript runtime verified encoded output.jsIr
                  erasureCorrespondence output.generatedPositions)

def psCompilerUniformJavaScriptStagesFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerJavaScriptStagesError PsCompilerUniformJavaScriptStages :=
  match psCompilerJavaScriptValidatedInputsFromPrepared prepared with
  | Except.error error => Except.error error
  | Except.ok inputs =>
      psCompilerUniformJavaScriptStagesFromValidated
        inputs.runtimeIr inputs.verifiedIr inputs.erasureCorrespondence inputs.validated
