import Ps.Codegen.Doc
import Ps.Codegen.Names
import Ps.Codegen.Provenance

inductive PsEmissionTarget where
  | typescript | javascript | rust | wasmCore | wasmComponent
  deriving BEq

inductive PsArtifactRole where
  | implementation | declaration | sourceMap | runtime | interface | debugText
  deriving BEq

inductive PsArtifactPayload where
  | text (value : String)
  | binary (value : ByteArray)

structure PsArtifactFile where
  path : String
  role : PsArtifactRole
  payload : PsArtifactPayload

structure PsApiExport where
  semanticName : String
  typeParameters : List PsVerifiedIrTypeParameter
  parameters : List PsVerifiedIrParameter
  result : PsVerifiedIrType
  witReason : Option String

structure PsEmissionArtifact where
  target : PsEmissionTarget
  targetWordSize : Option PsVerifiedIrWordSize := none
  source : PsRenderedDoc
  symbols : List PsCodegenSymbol
  files : List PsArtifactFile := []
  dependencies : List String := []
  exports : List PsApiExport := []
  origins : List (String × PsSourceOrigin) := []

def psEmissionTargetName : PsEmissionTarget → String
  | .typescript => "typescript"
  | .javascript => "javascript"
  | .rust => "rust"
  | .wasmCore => "wasm-core"
  | .wasmComponent => "wasm-component"

-- Portable paths only. A host joins these validated names to its output root.
-- Reject Windows aliases as well as POSIX traversal and case-folded collisions.
def psArtifactPathValid (path : String) : Bool :=
  !path.isEmpty && !(path.toList.any fun c => c == '\\' || c == ':' || ['?', '*', '<', '>', '\"', '|'].contains c || c.toNat < 32) &&
  (path.splitOn "/").all (fun part =>
    !part.isEmpty && part != "." && part != ".." &&
    !part.endsWith "." && !part.endsWith " " &&
    !["con", "prn", "aux", "nul", "com1", "com2", "com3", "com4", "com5",
      "com6", "com7", "com8", "com9", "lpt1", "lpt2", "lpt3", "lpt4", "lpt5",
      "lpt6", "lpt7", "lpt8", "lpt9"].contains ((part.splitOn ".").head!.toLower))

def psValidateArtifact (artifact : PsEmissionArtifact) : Except String PsEmissionArtifact := do
  let _ ← artifact.files.foldlM (fun seen file => do
    if !psArtifactPathValid file.path then throw ("PSCV0-ARTIFACT-PATH: " ++ file.path)
    let key := file.path.toLower
    if seen.contains key then throw ("PSCV0-ARTIFACT-COLLISION: " ++ file.path)
    return key :: seen) ([] : List String)
  if artifact.files.isEmpty then throw "PSCV0-ARTIFACT: empty bundle"
  return artifact
