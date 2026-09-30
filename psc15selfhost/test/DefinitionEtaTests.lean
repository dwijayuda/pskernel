import Ps.Syntax.ParseLean
import Ps.Environment.Prelude
import Ps.Elab.Declaration
import Ps.Erasure.Definition
import Ps.BackendTs.Module

def psDefinitionEtaCompileLean
    (source : String) : Except String String :=
  match psParseLeanSource source with
  | Except.error _ => Except.error "parse"
  | Except.ok sourceModule =>
      match psElabModule psBootstrapPreludeEnvironment sourceModule with
      | Except.error _ => Except.error "elab"
      | Except.ok elaborated =>
          match
              psEraseCoreModule
                elaborated.environment
                elaborated.declarations with
          | Except.error _ => Except.error "erase"
          | Except.ok ir =>
              match psTsEmitModule ir with
              | Except.error _ => Except.error "emit"
              | Except.ok output => Except.ok output

def psTestDefinitionEtaExpansion : Bool :=
  let source :=
    "def addPair (a : Nat) (b : Nat) : Nat := Nat.add a b\n" ++
    "def stage (a : Nat) : Nat -> Nat := addPair a\n" ++
    "def useStage : Nat := stage 1 2"
  match psDefinitionEtaCompileLean source with
  | Except.error _ => false
  | Except.ok output =>
      output.contains "export function stage(a: bigint,"
        && !output.contains "export function stage(a: bigint): ("
        && output.contains "stage(1n, 2n)"

def main : IO Unit := do
  if psTestDefinitionEtaExpansion then
    IO.println "PSC1_DEFINITION_ETA_PASS: staged function arity"
  else
    throw
      (IO.userError
        "PSC1_DEFINITION_ETA_FAIL: staged function arity")
