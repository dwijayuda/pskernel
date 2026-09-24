import Lake
open Lake DSL

package proofscriptSelfhost where
  srcDir := "src"

lean_lib ProofScriptCompiler where
  srcDir := "../packages/compiler/src"
  roots := #[`ProofScript.Compiler.Data]

@[default_target]
lean_exe psc1 where
  root := `Main
