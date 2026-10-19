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
        "def idNat(x : Nat) : Nat := x\n" with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      let expected :=
        "// generated from pskernel-admitted ProofScript checked core\n" ++
        psTsRuntimeSupport ++ "\n" ++
        "export function idNat(x: bigint): bigint { while (true) { return x; } }\n"
      leanOutput == expected
        && proofScriptOutput == expected
  | _, _ => false

def psTestDualSourceLeanNativeGenericIdentity : Bool :=
  match
      psCompileLeanSourceToTypeScript
        "def identity (α : Type) (x : α) : α := x",
      psCompileProofScriptSourceToTypeScript
        "def identity(α : Type, x : α) : α := x\n" with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      let expected :=
        "// generated from pskernel-admitted ProofScript checked core\n" ++
        psTsRuntimeSupport ++ "\n" ++
        "export function identity<T0>(x: T0): T0 { return __ps$run(__ps$impl$identity<T0>(x)); }\n" ++
        "function* __ps$impl$identity<T0>(x: T0): __ps$Computation<T0> { return x; }\n" ++
        "__ps$implementations.set(identity, __ps$impl$identity);\n"
      leanOutput == expected
        && proofScriptOutput == expected
  | _, _ => false

def psTestDualSourceLeanNativeLet : Bool :=
  match
      psCompileLeanSourceToTypeScript
        "def one : Nat := let x : Nat := 1; x",
      psCompileProofScriptSourceToTypeScript
        "def one : Nat := let x : Nat := 1\n x\n" with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains
          "export const one: bigint = __ps$run((function*(): __ps$Computation<bigint> { return (yield* (function*() { { const x: bigint = 1n; return x; } })()); })());"
  | _, _ => false

def psTestDualSourceLeanNativeIf : Bool :=
  match
      psCompileLeanSourceToTypeScript
        "def choose (b : Bool) : Nat := if b then 1 else 2",
      psCompileProofScriptSourceToTypeScript
        "def choose(b : Bool) : Nat := if (b) { 1 } else { 2 }\n" with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains
          "export function choose(b: boolean): bigint { while (true) { if (b) { return 1n; } else { return 2n; } } }"
  | _, _ => false

def psTestDualSourceLeanNativeMaybeMatch : Bool :=
  let leanSource :=
    "inductive Maybe (α : Type) where | none | some (value : α)\n" ++
    "def present : Maybe Nat := Maybe.some 1\n" ++
    "def getOrZero (m : Maybe Nat) : Nat := " ++
    "match m with | Maybe.none => 0 | Maybe.some value => value"
  let proofScriptSource :=
    "inductive Maybe(α : Type) where { | none\n | some(value : α)\n }\n " ++
    "def present : Maybe(Nat) := Maybe.some(1)\n " ++
    "def getOrZero(m : Maybe(Nat)) : Nat := " ++
    "match m with { | Maybe.none => 0\n | Maybe.some value => value\n }\n"
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
        && leanOutput.contains "case \"none\": {  return 0n; }"
        && leanOutput.contains "case \"some\": { const value: bigint ="
  | _, _ => false

def psTestDualSourceLeanNativeStructureProjection : Bool :=
  let leanSource :=
    "structure User where\n" ++
    "  age : Nat\n" ++
    "def user : User := User.mk 33\n" ++
    "def ageOf (u : User) : Nat := u.age"
  let proofScriptSource :=
    "structure User where { age : Nat\n }\n " ++
    "def user : User := User.mk(33)\n " ++
    "def ageOf(u : User) : Nat := u.age\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains "export interface User"
        && leanOutput.contains "readonly age: bigint;"
        && leanOutput.contains "export const user: User"
        && leanOutput.contains "age: 33n"
        && leanOutput.contains
          "export function ageOf(u: User): bigint { while (true) { return u.age; } }"
  | _, _ => false

def psTestDualSourceLeanNativeStructuralRecursion : Bool :=
  let leanSource :=
    "inductive ListR (α : Type) where | nil | cons (head : α) (tail : ListR α)\n" ++
    "def lengthR (xs : ListR Nat) : Nat := " ++
    "match xs with | ListR.nil => 0 | ListR.cons head tail => lengthR tail"
  let proofScriptSource :=
    "inductive ListR(α : Type) where { | nil\n | cons(head : α, tail : ListR(α))\n }\n " ++
    "def lengthR(xs : ListR(Nat)) : Nat := " ++
    "match xs with { | ListR.nil => 0\n | ListR.cons head tail => lengthR(tail)\n }\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains "export type ListR<T0>"
        && leanOutput.contains "export function lengthR(xs: ListR<bigint>): bigint"
        && leanOutput.contains "[xs] = [tail]; continue;"
  | _, _ => false

def psTestDualSourceLeanNativeInt : Bool :=
  let leanSource :=
    "def intOne : Int := 1\n" ++
    "def intCalc (x : Int) : Int := " ++
    "Int.sub (Int.add x (Int.ofNat 2)) (Int.neg (Int.ofNat 3))"
  let proofScriptSource :=
    "def intOne : Int := 1\n " ++
    "def intCalc(x : Int) : Int := " ++
    "Int.sub(Int.add(x, Int.ofNat(2)), Int.neg(Int.ofNat(3)))\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains "export const intOne: bigint = __ps$run((function*(): __ps$Computation<bigint> { return 1n; })());"
        && leanOutput.contains
          "export function intCalc(x: bigint): bigint"
        && leanOutput.contains "(x + 2n)"
        && leanOutput.contains "(-(3n))"
  | _, _ => false

def psTestDualSourceLeanNativeArrayBasics : Bool :=
  let leanSource :=
    "def arrayDemo (a : Nat) (b : Nat) : Nat := " ++
    "let xs : Array Nat := Array.push (Array.push (Array.emptyWithCapacity 2) a) b; " ++
    "let ys : Array Nat := Array.setIfInBounds xs 0 10; " ++
    "Array.getD ys 1 99"
  let proofScriptSource :=
    "def arrayDemo(a : Nat, b : Nat) : Nat := " ++
    "let xs : Array(Nat) := Array.push(Array.push(Array.emptyWithCapacity(2), a), b)\n " ++
    "let ys : Array(Nat) := Array.setIfInBounds(xs, 0, 10)\n " ++
    "Array.getD(ys, 1, 99)\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains
          "export function arrayDemo(a: bigint, b: bigint): bigint"
        && leanOutput.contains "[...("
        && leanOutput.contains "99n"
  | _, _ => false

def psTestDualSourceLeanNativeArrayMap : Bool :=
  let leanSource :=
    "def arrayIdOnly (x : Nat) : Nat := x\n" ++
    "def arrayMapDemo (xs : Array Nat) : Array Nat := Array.map arrayIdOnly xs"
  let proofScriptSource :=
    "def arrayIdOnly(x : Nat) : Nat := x\n " ++
    "def arrayMapDemo(xs : Array(Nat)) : Array(Nat) := Array.map(arrayIdOnly, xs)\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains "__ps_a.map"
  | _, _ => false

def psTestDualSourceLeanNativeArrayFoldl : Bool :=
  let leanSource :=
    "def arrayKeepLeftOnly (acc : Nat) (x : Nat) : Nat := acc\n" ++
    "def arrayFoldOnly (xs : Array Nat) : Nat := " ++
    "Array.foldl arrayKeepLeftOnly 0 xs 0 (Array.size xs)"
  let proofScriptSource :=
    "def arrayKeepLeftOnly(acc : Nat, x : Nat) : Nat := acc\n " ++
    "def arrayFoldOnly(xs : Array(Nat)) : Nat := " ++
    "Array.foldl(arrayKeepLeftOnly, 0, xs, 0, Array.size(xs))\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains "for (let __ps_i"
  | _, _ => false

def psTestDualSourceLeanNativeArrayHigherOrder : Bool :=
  let leanSource :=
    "def arrayId (x : Nat) : Nat := x\n" ++
    "def arrayKeepLeft (acc : Nat) (x : Nat) : Nat := acc\n" ++
    "def arrayFoldDemo (a : Nat) (b : Nat) : Nat := " ++
    "let xs : Array Nat := Array.push (Array.push (Array.emptyWithCapacity 2) a) b; " ++
    "let ys : Array Nat := Array.map arrayId xs; " ++
    "Array.foldl arrayKeepLeft 0 ys 0 (Array.size ys)"
  let proofScriptSource :=
    "def arrayId(x : Nat) : Nat := x\n " ++
    "def arrayKeepLeft(acc : Nat, x : Nat) : Nat := acc\n " ++
    "def arrayFoldDemo(a : Nat, b : Nat) : Nat := " ++
    "let xs : Array(Nat) := Array.push(Array.push(Array.emptyWithCapacity(2), a), b)\n " ++
    "let ys : Array(Nat) := Array.map(arrayId, xs)\n " ++
    "Array.foldl(arrayKeepLeft, 0, ys, 0, Array.size(ys))\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains ".map("
        && leanOutput.contains "for (let __ps_i"
  | _, _ => false

def psTestDualSourceLeanNativePartialApplication : Bool :=
  let leanSource :=
    "def addPair (a : Nat) (b : Nat) : Nat := Nat.add a b\n" ++
    "def addOne : Nat -> Nat := addPair 1"
  let proofScriptSource :=
    "def addPair(a : Nat, b : Nat) : Nat := Nat.add(a, b)\n " ++
    "def addOne : Nat -> Nat := addPair(1)\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains "export const addOne:"
        && leanOutput.contains "(yield* __ps$invoke(addPair, 1n,"
  | _, _ => false

def psTestDualSourceLeanNativeTextPrimitives : Bool :=
  let leanSource :=
    "def pushBang (s : String) : String := String.push s '!'\n" ++
    "def firstChar (s : String) : Char := String.Internal.get s 0\n" ++
    "def nextPos (s : String) (p : Nat) : Nat := String.Internal.next s p\n" ++
    "def textBytes (s : String) : Nat := String.utf8ByteSize s"
  let proofScriptSource :=
    "def pushBang(s : String) : String := String.push(s, '!')\n " ++
    "def firstChar(s : String) : Char := String.Internal.get(s, 0)\n " ++
    "def nextPos(s : String, p : Nat) : Nat := String.Internal.next(s, p)\n " ++
    "def textBytes(s : String) : Nat := String.utf8ByteSize(s)\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains "export function pushBang(s: string): string"
        && leanOutput.contains "String.fromCodePoint(Number(__ps_n))"
        && leanOutput.contains "33n"
        && leanOutput.contains "codePointAt(0)"
        && leanOutput.contains "export function nextPos(s: string, p: bigint): bigint"
        && leanOutput.contains "export function textBytes(s: string): bigint"
        && leanOutput.contains "__ps$stringGet(s, 0n)"
        && leanOutput.contains "__ps$utf8(s).size"
  | _, _ => false

def psTestDualSourceLeanNativeStringRawPositionBridge : Bool :=
  let leanSource :=
    "def rawPositionRoundTrip (p : Nat) : Nat := " ++
    "String.Pos.Raw.byteIdx (String.Pos.Raw.mk p)\n" ++
    "def rawCharAt (s : String) (p : Nat) : Char := " ++
    "String.Internal.get s (String.Pos.Raw.mk p)\n" ++
    "def rawNext (s : String) (p : Nat) : Nat := " ++
    "String.Pos.Raw.byteIdx " ++
    "(String.Internal.next s (String.Pos.Raw.mk p))"
  let proofScriptSource :=
    "def rawPositionRoundTrip(p : Nat) : Nat := " ++
    "String.Pos.Raw.byteIdx(String.Pos.Raw.mk(p))\n " ++
    "def rawCharAt(s : String, p : Nat) : Char := " ++
    "String.Internal.get(s, String.Pos.Raw.mk(p))\n " ++
    "def rawNext(s : String, p : Nat) : Nat := " ++
    "String.Pos.Raw.byteIdx(" ++
    "String.Internal.next(s, String.Pos.Raw.mk(p)))\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains
          "export function rawPositionRoundTrip(p: bigint): bigint { while (true) { return p; } }"
        && leanOutput.contains
          "export function rawCharAt(s: string, p: bigint): string"
        && leanOutput.contains
          "export function rawNext(s: string, p: bigint): bigint"
  | _, _ => false

def psTestDualSourceLeanNativePartialDefinition : Bool :=
  let leanSource :=
    "partial def loop (n : Nat) : Nat := loop n"
  let proofScriptSource :=
    "partial def loop(n : Nat) : Nat := loop(n)\n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileProofScriptSourceToTypeScript proofScriptSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains
          "export function loop(n: bigint): bigint { while (true) { [n] = [n]; continue; } }"
  | _, _ => false

structure PsErasureNamedTest where
  name : String
  passed : Bool

def psErasureTests : List PsErasureNamedTest := [
  { name := "dual-source Lean-native identity", passed := psTestDualSourceLeanNativeIdentity },
  { name := "dual-source Lean-native generic identity", passed := psTestDualSourceLeanNativeGenericIdentity },
  { name := "dual-source Lean-native let", passed := psTestDualSourceLeanNativeLet },
  { name := "dual-source Lean-native if", passed := psTestDualSourceLeanNativeIf },
  { name := "dual-source Lean-native Maybe match", passed := psTestDualSourceLeanNativeMaybeMatch },
  { name := "dual-source Lean-native structure projection", passed := psTestDualSourceLeanNativeStructureProjection },
  { name := "dual-source Lean-native structural recursion", passed := psTestDualSourceLeanNativeStructuralRecursion },
  { name := "dual-source Lean-native Int", passed := psTestDualSourceLeanNativeInt },
  { name := "dual-source Lean-native Array basics", passed := psTestDualSourceLeanNativeArrayBasics },
  { name := "dual-source Lean-native Array map", passed := psTestDualSourceLeanNativeArrayMap },
  { name := "dual-source Lean-native Array foldl", passed := psTestDualSourceLeanNativeArrayFoldl },
  { name := "dual-source Lean-native Array higher-order", passed := psTestDualSourceLeanNativeArrayHigherOrder },
  { name := "dual-source Lean-native partial application", passed := psTestDualSourceLeanNativePartialApplication },
  { name := "dual-source Lean-native text primitives", passed := psTestDualSourceLeanNativeTextPrimitives },
  { name := "dual-source Lean-native String raw-position bridge", passed := psTestDualSourceLeanNativeStringRawPositionBridge },
  { name := "dual-source Lean-native controlled partial def", passed := psTestDualSourceLeanNativePartialDefinition }
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
