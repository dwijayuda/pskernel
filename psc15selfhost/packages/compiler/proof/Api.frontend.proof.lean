import Ps.Compiler.Api

/-!
PSCV compiler-package experiment: frontend orchestration proofs.

These theorems prove the exact wrapper/error-mapping behavior implemented in
`Ps.Compiler.Api`. They do not prove correctness of the parser or elaborator
algorithms imported by this package.
-/

theorem pscv_translate_lean_lean_error
    (source : String)
    (error : PsTranslationError)
    (h : psCanonicalizeLeanSource source = Except.error error) :
    psCompilerTranslateSource .lean .lean source =
      Except.error (.translation error) := by
  simp [psCompilerTranslateSource, h]

theorem pscv_translate_lean_lean_ok
    (source output : String)
    (h : psCanonicalizeLeanSource source = Except.ok output) :
    psCompilerTranslateSource .lean .lean source =
      Except.ok output := by
  simp [psCompilerTranslateSource, h]

theorem pscv_translate_lean_ps_error
    (source : String)
    (error : PsTranslationError)
    (h : psTranslateLeanToProofScript source = Except.error error) :
    psCompilerTranslateSource .lean .proofScript source =
      Except.error (.translation error) := by
  simp [psCompilerTranslateSource, h]

theorem pscv_translate_lean_ps_ok
    (source output : String)
    (h : psTranslateLeanToProofScript source = Except.ok output) :
    psCompilerTranslateSource .lean .proofScript source =
      Except.ok output := by
  simp [psCompilerTranslateSource, h]

theorem pscv_translate_ps_lean_error
    (source : String)
    (error : PsTranslationError)
    (h : psTranslateProofScriptToLean source = Except.error error) :
    psCompilerTranslateSource .proofScript .lean source =
      Except.error (.translation error) := by
  simp [psCompilerTranslateSource, h]

theorem pscv_translate_ps_lean_ok
    (source output : String)
    (h : psTranslateProofScriptToLean source = Except.ok output) :
    psCompilerTranslateSource .proofScript .lean source =
      Except.ok output := by
  simp [psCompilerTranslateSource, h]

theorem pscv_translate_ps_ps_error
    (source : String)
    (error : PsTranslationError)
    (h : psCanonicalizeProofScriptSource source = Except.error error) :
    psCompilerTranslateSource .proofScript .proofScript source =
      Except.error (.translation error) := by
  simp [psCompilerTranslateSource, h]

theorem pscv_translate_ps_ps_ok
    (source output : String)
    (h : psCanonicalizeProofScriptSource source = Except.ok output) :
    psCompilerTranslateSource .proofScript .proofScript source =
      Except.ok output := by
  simp [psCompilerTranslateSource, h]

theorem pscv_parse_lean_error
    (source : String)
    (error : PsLeanFrontendError)
    (h : psParseLeanSource source = Except.error error) :
    psCompilerParseSource .lean source =
      Except.error (.leanFrontend error) := by
  simp [psCompilerParseSource, h]

theorem pscv_parse_lean_ok
    (source : String)
    (module : PsSyntaxModule)
    (h : psParseLeanSource source = Except.ok module) :
    psCompilerParseSource .lean source = Except.ok module := by
  simp [psCompilerParseSource, h]

theorem pscv_parse_ps_error
    (source : String)
    (error : PsProofScriptFrontendError)
    (h : psParseProofScriptSource source = Except.error error) :
    psCompilerParseSource .proofScript source =
      Except.error (.proofScriptFrontend error) := by
  simp [psCompilerParseSource, h]

theorem pscv_parse_ps_ok
    (source : String)
    (module : PsSyntaxModule)
    (h : psParseProofScriptSource source = Except.ok module) :
    psCompilerParseSource .proofScript source = Except.ok module := by
  simp [psCompilerParseSource, h]

theorem pscv_elaborate_module_error
    (module : PsSyntaxModule)
    (error : PsElabError)
    (h :
      psElabModule psSelfHostProdPreludeEnvironment module =
        Except.error error) :
    psCompilerElaborateModule module =
      Except.error (.elaboration error) := by
  simp [psCompilerElaborateModule, h]

theorem pscv_elaborate_module_ok
    (module : PsSyntaxModule)
    (elaborated : PsElabModuleResult)
    (h :
      psElabModule psSelfHostProdPreludeEnvironment module =
        Except.ok elaborated) :
    psCompilerElaborateModule module = Except.ok elaborated := by
  simp [psCompilerElaborateModule, h]

theorem pscv_elaborate_source_parse_error
    (kind : PsCompilerSourceKind)
    (source : String)
    (error : PsCompilerError)
    (h : psCompilerParseSource kind source = Except.error error) :
    psCompilerElaborateSource kind source = Except.error error := by
  simp [psCompilerElaborateSource, h]

theorem pscv_elaborate_source_module_error
    (kind : PsCompilerSourceKind)
    (source : String)
    (module : PsSyntaxModule)
    (error : PsCompilerError)
    (hParse : psCompilerParseSource kind source = Except.ok module)
    (hElab : psCompilerElaborateModule module = Except.error error) :
    psCompilerElaborateSource kind source = Except.error error := by
  simp [psCompilerElaborateSource, hParse, hElab]

theorem pscv_elaborate_source_ok
    (kind : PsCompilerSourceKind)
    (source : String)
    (module : PsSyntaxModule)
    (elaborated : PsElabModuleResult)
    (hParse : psCompilerParseSource kind source = Except.ok module)
    (hElab : psCompilerElaborateModule module = Except.ok elaborated) :
    psCompilerElaborateSource kind source = Except.ok elaborated := by
  simp [psCompilerElaborateSource, hParse, hElab]
