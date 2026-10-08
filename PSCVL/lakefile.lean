import Lake
open Lake DSL

package pscvl where

lean_lib PSCVL where
  srcDir := "."

@[default_target] lean_exe pscvl where
  root := `Main
