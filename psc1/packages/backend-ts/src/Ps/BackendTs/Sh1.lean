import Ps.Compiler.Sh1
import Ps.BackendTs.Checked
import Ps.BackendTs.Sh1Target

inductive PsSh1EmitError where
  | source (error : PsSh1SourceError)
  | compiler (error : PsCompilerError)
  | checkedEmit (error : PsTsCheckedEmitError)
  | target (error : PsSh1TargetError)

-- These are exact objects from one atomic source-to-emission computation.
-- The host may observe them for ABI, carrier and provenance checks; their mere
-- serialization does not grant provider acceptance or semantic qualification.
structure PsSh1Emission where
  prepared : PsCompilerAdmissionReadyModule
  parsedModules : List PsSh1ParsedModule
  origins : List PsSh1ModuleOrigin
  originalIr : PsVerifiedIrModule
  checkReport : PsIrCheckReport
  typeScript : String
  admissions : String
  sourcePolicy : PsSh1SourceReport
  targetPolicy : PsSh1TargetReport
  strictSh1Qualified : Bool
  semanticContractQualified : Bool
  providerChecked : Bool

-- There is intentionally no strict FromPrepared/FromIr entry taking a caller's
-- accepted flag. Raw compiler/IR APIs keep their existing, weaker contracts.
-- No IO, suspension or mutation separates checking from the same-IR emitter.
def psCompilerSh1TypeScriptSources
    (sourceOptions : PsSh1SourceOptions) (irOptions : PsIrCheckOptions)
    (sourceKind : PsCompilerSourceKind) (inputs : List PsSh1SourceInput) :
    Except PsSh1EmitError PsSh1Emission :=
  match psCompilerSh1PrepareSources sourceOptions sourceKind inputs with
  | Except.error error => Except.error (PsSh1EmitError.source error)
  | Except.ok source =>
      -- These fields were produced together by the source preparation above.
      -- Reuse its actual environment and successful canonical admission bytes.
      -- Arbitrary prepared-result APIs still perform their existing validation.
      match psEraseCoreModuleWithRuntimePrelude
          source.environment psSelfHostRuntimePreludeDeclarationsWithProd
          source.prepared.declarations with
      | Except.error error =>
          Except.error (PsSh1EmitError.compiler (PsCompilerError.erasure error))
      | Except.ok ir =>
          match psTsCheckModuleForEmission irOptions ir with
          | Except.error error => Except.error (PsSh1EmitError.checkedEmit error)
          | Except.ok report =>
              match psSh1CheckTarget irOptions.maxSteps ir with
              | Except.error error => Except.error (PsSh1EmitError.target error)
              | Except.ok targetPolicy =>
                  let targetAccepted : Bool :=
                    if targetPolicy.accepted then targetPolicy.traversalComplete else false;
                  if targetAccepted then
                    match psTsEmitModule ir with
                    | Except.error error =>
                        Except.error (PsSh1EmitError.checkedEmit (PsTsCheckedEmitError.emit error))
                    | Except.ok typeScript =>
                        Except.ok (PsSh1Emission.mk source.prepared source.parsedModules
                          source.origins ir report typeScript source.admissions source.report targetPolicy
                          false false false)
                  else
                    Except.error (PsSh1EmitError.target
                      (PsSh1TargetError.mk "target-report-incomplete"
                        "target admission did not accept a complete traversal"
                        "" "" targetPolicy.visitedSteps))
