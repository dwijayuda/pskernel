import Ps.Compiler.Api
import Ps.Compiler.Pscv0Engine
import Ps.Environment.StandardSnapshot

-- The existing Full entry path validates its selected Standard seed before
-- elaborating a term. The SHA-256 digest is integrity evidence for this bounded
-- roster, not proof authority or a final notation/tactic/effect manifest.
def psCompilerValidatePscv0Standard : Except String Unit :=
  psStandardSnapshotValidate psSelfHostProdPreludeEnvironment
    psStandardSnapshotExpected

def psCompilerElaboratePscv0 (program : PsSyntaxProgram) :
    Except PsCompilerError PsElabModuleResult := do
  (psCompilerValidatePscv0Standard).mapError PsCompilerError.normalization
  let result ← psCompilerEngineElaboratePscv0 psCompilerFullProfileContext program
  pure (PsElabModuleResult.mk result.environment result.declarations result.commandDiagnostics)
