import Ps.Codegen.Doc
import Ps.Codegen.Names

inductive PsEmissionTarget where
  | typescript
  | rust
  deriving BEq

structure PsEmissionArtifact where
  target : PsEmissionTarget
  source : PsRenderedDoc
  symbols : List PsCodegenSymbol
  runtime : String := ""

def psEmissionTargetName : PsEmissionTarget → String
  | .typescript => "typescript"
  | .rust => "rust"
