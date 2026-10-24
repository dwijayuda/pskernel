import Ps.BackendPhp.Portable

-- Native compatibility metadata/defaults; the emitter implementation is shared
-- with the generated compiler and lives only in Portable.
structure PsPhpPrintedModule where
  source : String
  composer : String
  runtimeSource : String
  runtimeVersion : String := psPhpRuntimeVersion
  runtimeRequirements : List String
  declarations : List (String × String)
  declarationLines : List (String × Nat)

def psPhpEmitValidatedModule (validated : PsValidatedIrModule) (publicNames : List String)
    (ioAbi : Bool := false) : Except String PsPhpPrintedModule := do
  let printed <- psPhpEmitModuleWithIo validated publicNames ioAbi
  pure {
    source := printed.source
    composer := printed.composer
    runtimeSource := printed.runtimeSource
    runtimeVersion := printed.runtimeVersion
    runtimeRequirements := printed.runtimeRequirements
    declarations := printed.declarations
    declarationLines := printed.declarationLines
  }
