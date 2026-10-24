import ScriptRuntimeReference

-- Exact historical runtime remains immutable. Only this complete helper block
-- is neutralized; every other runtime byte retains its original comparison.
def psPhpExtractReferenceNeutral (source : String) : String :=
  source.replace (psPhpRuntimePart "stringExtract")
    (PsScriptRuntimeReference.Php.psPhpRuntimePart "stringExtract")

def psPhpExtractReferenceRequests (requested : List String) : List String :=
  if requested.contains "stringExtract" then "utf8Valid" :: requested else requested
