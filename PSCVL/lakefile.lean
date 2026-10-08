import Lake
open Lake DSL

package pscvl where

lean_lib PSCVL where
  srcDir := "."

lean_exe pscvl where
  root := `Main
