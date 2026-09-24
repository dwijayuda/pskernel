import Lake
open Lake DSL

package proofscriptSelfhost where
  srcDir := "src"

lean_lib ProofScript

@[default_target]
lean_exe psc1 where
  root := `Main
