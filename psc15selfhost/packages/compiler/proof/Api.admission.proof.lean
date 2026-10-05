import Ps.Compiler.Api

/-!
PSCV compiler-package experiment: admission/preparation proofs.

These theorems establish fail-closed propagation and exact success construction
for the package's preparation/admissions orchestration. They deliberately retain
the current honest `AdmissionReady` meaning; none claims kernel admission.
-/

theorem pscv_prepare_elaborated_rejects_codec_error
    (elaborated : PsElabModuleResult)
    (error : PsCheckedAdmissionCodecError)
    (h :
      psEncodeCheckedAdmissionsCanonical elaborated.declarations =
        Except.error error) :
    psCompilerPrepareElaborated elaborated =
      Except.error (.admission error) := by
  simp [psCompilerPrepareElaborated, h]

theorem pscv_prepare_elaborated_success
    (elaborated : PsElabModuleResult)
    (canonical : String)
    (h :
      psEncodeCheckedAdmissionsCanonical elaborated.declarations =
        Except.ok canonical) :
    psCompilerPrepareElaborated elaborated =
      Except.ok
        (PsCompilerAdmissionReadyModule.mk elaborated.declarations) := by
  simp [psCompilerPrepareElaborated, h]

theorem pscv_check_elaborated_is_prepare
    (elaborated : PsElabModuleResult) :
    psCompilerCheckElaborated elaborated =
      psCompilerPrepareElaborated elaborated := by
  rfl

theorem pscv_prepare_source_elaboration_error
    (kind : PsCompilerSourceKind)
    (source : String)
    (error : PsCompilerError)
    (h : psCompilerElaborateSource kind source = Except.error error) :
    psCompilerPrepareSource kind source = Except.error error := by
  simp [psCompilerPrepareSource, h]

theorem pscv_prepare_source_success
    (kind : PsCompilerSourceKind)
    (source : String)
    (elaborated : PsElabModuleResult)
    (prepared : PsCompilerAdmissionReadyModule)
    (hElab :
      psCompilerElaborateSource kind source = Except.ok elaborated)
    (hPrepare :
      psCompilerPrepareElaborated elaborated = Except.ok prepared) :
    psCompilerPrepareSource kind source = Except.ok prepared := by
  simp [psCompilerPrepareSource, hElab, hPrepare]

theorem pscv_check_source_is_prepare
    (kind : PsCompilerSourceKind)
    (source : String) :
    psCompilerCheckSource kind source =
      psCompilerPrepareSource kind source := by
  rfl

theorem pscv_elaborate_sources_worker_empty
    (kind : PsCompilerSourceKind)
    (environment : PsEnvironment)
    (declarationsRev : List PsDeclaration) :
    psCompilerElaborateSourcesWorker
        kind
        List.nil
        environment
        declarationsRev =
      Except.ok
        (PsElabModuleResult.mk
          environment
          (psListReverse declarationsRev)) := by
  rfl

theorem pscv_elaborate_sources_worker_head_parse_error
    (kind : PsCompilerSourceKind)
    (source : String)
    (rest : List String)
    (environment : PsEnvironment)
    (declarationsRev : List PsDeclaration)
    (error : PsCompilerError)
    (hParse :
      psCompilerParseSource kind source = Except.error error) :
    psCompilerElaborateSourcesWorker
        kind
        (List.cons source rest)
        environment
        declarationsRev =
      Except.error error := by
  simp [psCompilerElaborateSourcesWorker, hParse]

theorem pscv_prepare_sources_worker_error
    (kind : PsCompilerSourceKind)
    (sources : List String)
    (error : PsCompilerError)
    (h :
      psCompilerElaborateSourcesWorker
          kind
          sources
          psSelfHostProdPreludeEnvironment
          List.nil =
        Except.error error) :
    psCompilerPrepareSources kind sources = Except.error error := by
  simp [psCompilerPrepareSources, h]

theorem pscv_prepare_sources_success
    (kind : PsCompilerSourceKind)
    (sources : List String)
    (elaborated : PsElabModuleResult)
    (prepared : PsCompilerAdmissionReadyModule)
    (hWorker :
      psCompilerElaborateSourcesWorker
          kind
          sources
          psSelfHostProdPreludeEnvironment
          List.nil =
        Except.ok elaborated)
    (hPrepare :
      psCompilerPrepareElaborated elaborated = Except.ok prepared) :
    psCompilerPrepareSources kind sources = Except.ok prepared := by
  simp [psCompilerPrepareSources, hWorker, hPrepare]

theorem pscv_validate_prepared_rejects_codec_error
    (prepared : PsCompilerAdmissionReadyModule)
    (error : PsCheckedAdmissionCodecError)
    (h :
      psEncodeCheckedAdmissionsCanonical prepared.declarations =
        Except.error error) :
    psCompilerValidatePrepared prepared =
      Except.error (.admission error) := by
  simp [psCompilerValidatePrepared, h]

theorem pscv_validate_prepared_success
    (prepared : PsCompilerAdmissionReadyModule)
    (canonical : String)
    (h :
      psEncodeCheckedAdmissionsCanonical prepared.declarations =
        Except.ok canonical) :
    psCompilerValidatePrepared prepared = Except.ok Unit.unit := by
  simp [psCompilerValidatePrepared, h]

theorem pscv_admissions_prepared_rejects_codec_error
    (prepared : PsCompilerAdmissionReadyModule)
    (error : PsCheckedAdmissionCodecError)
    (h :
      psEncodeCheckedAdmissionsCanonical prepared.declarations =
        Except.error error) :
    psCompilerAdmissionsFromPrepared prepared =
      Except.error (.admission error) := by
  simp [psCompilerAdmissionsFromPrepared, h]

theorem pscv_admissions_prepared_success
    (prepared : PsCompilerAdmissionReadyModule)
    (canonical : String)
    (h :
      psEncodeCheckedAdmissionsCanonical prepared.declarations =
        Except.ok canonical) :
    psCompilerAdmissionsFromPrepared prepared =
      Except.ok (String.Internal.append canonical "\n") := by
  simp [psCompilerAdmissionsFromPrepared, h]

theorem pscv_admissions_elaborated_prepare_error
    (elaborated : PsElabModuleResult)
    (error : PsCompilerError)
    (hPrepare :
      psCompilerPrepareElaborated elaborated = Except.error error) :
    psCompilerAdmissionsFromElaborated elaborated =
      Except.error error := by
  simp [psCompilerAdmissionsFromElaborated, hPrepare]

theorem pscv_admissions_elaborated_success
    (elaborated : PsElabModuleResult)
    (prepared : PsCompilerAdmissionReadyModule)
    (admissions : String)
    (hPrepare :
      psCompilerPrepareElaborated elaborated = Except.ok prepared)
    (hAdmissions :
      psCompilerAdmissionsFromPrepared prepared = Except.ok admissions) :
    psCompilerAdmissionsFromElaborated elaborated =
      Except.ok admissions := by
  simp [psCompilerAdmissionsFromElaborated, hPrepare, hAdmissions]

theorem pscv_admissions_source_prepare_error
    (kind : PsCompilerSourceKind)
    (source : String)
    (error : PsCompilerError)
    (hPrepare :
      psCompilerPrepareSource kind source = Except.error error) :
    psCompilerAdmissionsSource kind source = Except.error error := by
  simp [psCompilerAdmissionsSource, hPrepare]

theorem pscv_admissions_source_success
    (kind : PsCompilerSourceKind)
    (source : String)
    (prepared : PsCompilerAdmissionReadyModule)
    (admissions : String)
    (hPrepare :
      psCompilerPrepareSource kind source = Except.ok prepared)
    (hAdmissions :
      psCompilerAdmissionsFromPrepared prepared = Except.ok admissions) :
    psCompilerAdmissionsSource kind source = Except.ok admissions := by
  simp [psCompilerAdmissionsSource, hPrepare, hAdmissions]
