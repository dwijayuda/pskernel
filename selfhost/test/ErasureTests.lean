import Ps.Syntax.ParseLean
import Ps.Syntax.ParseProofScript
import Ps.Environment.Prelude
import Ps.Elab.Declaration
import Ps.Erasure.Definition
import Ps.BackendTs.Module

def psCompileLeanSourceToTypeScript
    (source : String) : Except String String :=
  match psParseLeanSource source with
  | Except.error _ => Except.error "parse"
  | Except.ok module =>
      match
          psElabModule
            psBootstrapPreludeEnvironment
            module with
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

def psCompileProofScriptSourceToTypeScript
    (source : String) : Except String String :=
  match psParseProofScriptSource source with
  | Except.error _ => Except.error "parse"
  | Except.ok module =>
      match
          psElabModule
            psBootstrapPreludeEnvironment
            module with
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

def psTestDualSourceLeanNativeIdentity : Bool :=
  match
      psCompileLeanSourceToTypeScript
        "def idNat (x : Nat) : Nat := x",
      psCompileProofScriptSourceToTypeScript
        "def idNat(x : Nat) : Nat := x;" with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      let expected :=
        "// generated from pskernel-admitted ProofScript checked core\n" ++
        "export function idNat(x: bigint): bigint { return x; }\n"
      leanOutput == expected
        && proofScriptOutput == expected
  | _, _ => false

def psTestDualSourceLeanNativeGenericIdentity : Bool :=
  match
      psCompileLeanSourceToTypeScript
        "def identity (α : Type) (x : α) : α := x",
      psCompileProofScriptSourceToTypeScript
        "def identity(α : Type)(x : α) : α := x;" with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      let expected :=
        "// generated from pskernel-admitted ProofScript checked core\n" ++
        "export function identity<T0>(x: T0): T0 { return x; }\n"
      leanOutput == expected
        && proofScriptOutput == expected
  | _, _ => false

def psTestDualSourceLeanNativeLet : Bool :=
  match
      psCompileLeanSourceToTypeScript
        "def one : Nat := let x : Nat := 1; x",
      psCompileProofScriptSourceToTypeScript
        "def one : Nat := let x : Nat := 1; x;" with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains
          "export const one: bigint = (() => { const x = 1n; return x; })();"
  | _, _ => false

def psTestDualSourceLeanNativeIf : Bool :=
  match
      psCompileLeanSourceToTypeScript
        "def choose (b : Bool) : Nat := if b then 1 else 2",
      psCompileProofScriptSourceToTypeScript
        "def choose(b : Bool) : Nat := if (b) { 1 } else { 2 };" with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains
          "export function choose(b: boolean): bigint { return (b ? 1n : 2n); }"
  | _, _ => false

def psTestDualSourceLeanNativeMaybeMatch : Bool :=
  let leanSource :=
    "inductive Maybe (α : Type) where | none | some (value : α)\n" ++
    "def present : Maybe Nat := Maybe.some 1\n" ++
    "def getOrZero (m : Maybe Nat) : Nat := " ++
    "match m with | Maybe.none => 0 | Maybe.some value => value"
  let proofScriptSource :=
    "inductive Maybe(α : Type) where { | none; | some(value : α); }; " ++
    "def present : Maybe(Nat) := Maybe.some(1); " ++
    "def getOrZero(m : Maybe(Nat)) : Nat := " ++
    "match m with { | Maybe.none => 0; | Maybe.some value => value; };"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains "export type Maybe<T0>"
        && leanOutput.contains "\"none\": <T0>(): Maybe<T0>"
        && leanOutput.contains "\"some\": <T0>(__field0: T0): Maybe<T0>"
        && leanOutput.contains "export const present: Maybe<bigint>"
        && leanOutput.contains "Maybe[\"some\"]<bigint>(1n)"
        && leanOutput.contains "export function getOrZero(m: Maybe<bigint>): bigint"
        && leanOutput.contains "case \"none\": return 0n;"
        && leanOutput.contains "case \"some\": return"
  | _, _ => false

structure PsErasureNamedTest where
  name : String
  passed : Bool

def psErasureTests : List PsErasureNamedTest := [
  { name := "dual-source Lean-native identity", passed := psTestDualSourceLeanNativeIdentity },
  { name := "dual-source Lean-native generic identity", passed := psTestDualSourceLeanNativeGenericIdentity },
  { name := "dual-source Lean-native let", passed := psTestDualSourceLeanNativeLet },
  { name := "dual-source Lean-native if", passed := psTestDualSourceLeanNativeIf },
  { name := "dual-source Lean-native Maybe match", passed := psTestDualSourceLeanNativeMaybeMatch }
]

def psRunErasureTests : List PsErasureNamedTest -> IO Bool
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSC1_ERASURE_PASS: " ++ test.name)
      else
        IO.println ("PSC1_ERASURE_FAIL: " ++ test.name)
      let restPassed ← psRunErasureTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psRunErasureTests psErasureTests
  if passed then
    IO.println "PSC1_ERASURE_TESTS: PASS"
  else
    throw (IO.userError "PSC1_ERASURE_TESTS: FAIL")
