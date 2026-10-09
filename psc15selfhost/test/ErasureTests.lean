import Ps.Syntax.ParseLean
import Ps.Syntax.ParseProofScript
import Ps.Syntax.Translate
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

def psCompileLeanSourceViaProofScriptToTypeScript
    (source : String) : Except String String :=
  match psTranslateLeanToProofScript source with
  | Except.error _ => Except.error "translate"
  | Except.ok proofScriptSource =>
      psCompileProofScriptSourceToTypeScript proofScriptSource

def psTestDualSourceLeanNativeIdentity : Bool :=
  match
      psCompileLeanSourceToTypeScript
        "def idNat (x : Nat) : Nat := x",
      psCompileLeanSourceViaProofScriptToTypeScript
        "def idNat (x : Nat) : Nat := x" with
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
      psCompileLeanSourceViaProofScriptToTypeScript
        "def identity (α : Type) (x : α) : α := x" with
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
      psCompileLeanSourceViaProofScriptToTypeScript
        "def one : Nat := let x : Nat := 1; x" with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains
          "export const one: bigint = __ps$run((function*(): __ps$Computation<bigint> { return (yield* (function*() { { const x: bigint = 1n; return x; } })()); })());"
  | _, _ => false

def psTestDualSourceLeanNativeIf : Bool :=
  match
      psCompileLeanSourceToTypeScript
        "def choose (b : Bool) : Nat := if b then 1 else 2",
      psCompileLeanSourceViaProofScriptToTypeScript
        "def choose (b : Bool) : Nat := if b then 1 else 2" with
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
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
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
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
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
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
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
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
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
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
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
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains "__ps_a.map"
  | _, _ => false

def psTestDualSourceLeanNativeArrayFoldl : Bool :=
  let leanSource :=
    "def arrayKeepLeftOnly (acc : Nat) (x : Nat) : Nat := acc\n" ++
    "def arrayFoldOnly (xs : Array Nat) : Nat := " ++
    "Array.foldl arrayKeepLeftOnly 0 xs 0 (Array.size xs)"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
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
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains ".map("
        && leanOutput.contains "for (let __ps_i"
  | _, _ => false

def psTestDualSourceLeanNativePartialApplication : Bool :=
  let leanSource :=
    "def addPair (a : Nat) (b : Nat) : Nat := Nat.add a b\n" ++
    "def addOne : Nat -> Nat := addPair 1"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
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
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
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
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains
          "export function rawPositionRoundTrip(p: bigint): bigint { while (true) { return p; } }"
        && leanOutput.contains
          "export function rawCharAt(s: string, p: bigint): string"
        && leanOutput.contains
          "export function rawNext(s: string, p: bigint): bigint"
  | _, _ => false

def psTestSpecifiedStringPrimitiveAliases : Bool :=
  let source :=
    "def appendAlias (a : String) (b : String) : String := String.append a b\n" ++
    "def nextAlias (s : String) (p : Nat) : Nat := " ++
    "String.Pos.Raw.byteIdx (String.Pos.Raw.next s (String.Pos.Raw.mk p))\n" ++
    "def endAlias (s : String) (p : Nat) : Bool := " ++
    "String.Pos.Raw.atEnd s (String.Pos.Raw.mk p)"
  let legacy := (source.replace "String.append" "String.Internal.append").replace
    "String.Pos.Raw.next" "String.Internal.next" |>.replace
    "String.Pos.Raw.atEnd" "String.Internal.atEnd"
  match psCompileLeanSourceToTypeScript source,
      psCompileLeanSourceViaProofScriptToTypeScript source,
      psCompileLeanSourceToTypeScript legacy with
  | Except.ok direct, Except.ok translated, Except.ok old =>
      direct == translated && direct == old
  | _, _, _ => false

def psTestDualSourceLeanNativePartialDefinition : Bool :=
  let leanSource :=
    "partial def loop (n : Nat) : Nat := loop n"
  match
      psCompileLeanSourceToTypeScript leanSource,
      psCompileLeanSourceViaProofScriptToTypeScript leanSource with
  | Except.ok leanOutput, Except.ok proofScriptOutput =>
      leanOutput == proofScriptOutput
        && leanOutput.contains
          "export function loop(n: bigint): bigint { while (true) { [n] = [n]; continue; } }"
  | _, _ => false



def psTestVerifiedIrValidationAcceptsResolved : Bool :=
  let raw :=
    PsVerifiedIrModule.mk
      []
      []
      []
      [
        PsVerifiedIrDeclaration.mk
          "answer"
          []
          []
          (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
          (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 42))
      ]
  match psValidateErasedIrModule (PsErasedIrModule.mk raw) with
  | Except.error _ => false
  | Except.ok validated =>
      validated.raw.declarations.length == 1

def psTestVerifiedIrValidationRejectsUnknownResult : Bool :=
  let raw :=
    PsVerifiedIrModule.mk
      []
      []
      []
      [
        PsVerifiedIrDeclaration.mk
          "bad"
          []
          []
          PsVerifiedIrType.unknown
          (PsVerifiedIrExpr.literal PsVerifiedIrLiteral.unit)
      ]
  match psValidateErasedIrModule (PsErasedIrModule.mk raw) with
  | Except.error PsVerifiedIrValidationError.unresolvedRuntimeType => true
  | _ => false

def psTestVerifiedIrValidationRejectsNestedUnknown : Bool :=
  let raw :=
    PsVerifiedIrModule.mk
      []
      [
        PsVerifiedIrStructure.mk
          "Box"
          []
          [
            PsVerifiedIrStructureField.mk
              "value"
              (PsVerifiedIrType.function
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                PsVerifiedIrType.unknown)
          ]
      ]
      []
      []
  match psValidateErasedIrModule (PsErasedIrModule.mk raw) with
  | Except.error PsVerifiedIrValidationError.unresolvedRuntimeType => true
  | _ => false

def psVerifiedIrValidationNatType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

def psVerifiedIrValidationBox : PsVerifiedIrStructure :=
  PsVerifiedIrStructure.mk
    "Box"
    (List.cons
      (PsVerifiedIrTypeParameter.mk "T")
      List.nil)
    (List.cons
      (PsVerifiedIrStructureField.mk
        "value"
        (PsVerifiedIrType.typeParameter "T"))
      List.nil)

def psVerifiedIrValidationMaybe : PsVerifiedIrInductive :=
  PsVerifiedIrInductive.mk
    "Maybe"
    (List.cons
      (PsVerifiedIrTypeParameter.mk "T")
      List.nil)
    (List.cons
      (PsVerifiedIrConstructor.mk
        "none"
        List.nil)
      (List.cons
        (PsVerifiedIrConstructor.mk
          "some"
          (List.cons
            (PsVerifiedIrConstructorField.mk
              "value"
              (PsVerifiedIrType.typeParameter "T"))
            List.nil))
        List.nil))

def psVerifiedIrValidationModule
    (body : PsVerifiedIrExpr) :
    PsVerifiedIrModule :=
  PsVerifiedIrModule.mk
    List.nil
    (List.cons psVerifiedIrValidationBox List.nil)
    (List.cons psVerifiedIrValidationMaybe List.nil)
    (List.cons
      (PsVerifiedIrDeclaration.mk
        "probe"
        List.nil
        List.nil
        psVerifiedIrValidationNatType
        body)
      List.nil)

def psTestVerifiedIrValidationAcceptsStructuralReferences : Bool :=
  let body :=
    PsVerifiedIrExpr.record
      "Box"
      (List.cons psVerifiedIrValidationNatType List.nil)
      (List.cons
        (Prod.mk
          "value"
          (PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.natural 42)))
        List.nil)
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psVerifiedIrValidationModule body)) with
  | Except.error _ => false
  | Except.ok _ => true

def psTestVerifiedIrValidationRejectsUnknownStructure : Bool :=
  let body :=
    PsVerifiedIrExpr.record
      "Missing"
      List.nil
      List.nil
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psVerifiedIrValidationModule body)) with
  | Except.error
      (PsVerifiedIrValidationError.unknownStructure name) =>
      psStringEq name "Missing"
  | _ => false

def psTestVerifiedIrValidationRejectsStructureArity : Bool :=
  let body :=
    PsVerifiedIrExpr.record
      "Box"
      List.nil
      (List.cons
        (Prod.mk
          "value"
          (PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.natural 42)))
        List.nil)
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psVerifiedIrValidationModule body)) with
  | Except.error
      (PsVerifiedIrValidationError.typeArgumentArity name) =>
      psStringEq name "Box"
  | _ => false

def psTestVerifiedIrValidationRejectsStructureField : Bool :=
  let body :=
    PsVerifiedIrExpr.record
      "Box"
      (List.cons psVerifiedIrValidationNatType List.nil)
      (List.cons
        (Prod.mk
          "missing"
          (PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.natural 42)))
        List.nil)
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psVerifiedIrValidationModule body)) with
  | Except.error
      (PsVerifiedIrValidationError.unknownStructureField
        structureName
        fieldName) =>
      if psStringEq structureName "Box" then
        psStringEq fieldName "missing"
      else
        false
  | _ => false

def psTestVerifiedIrValidationRejectsProjectionField : Bool :=
  let target :=
    PsVerifiedIrExpr.record
      "Box"
      (List.cons psVerifiedIrValidationNatType List.nil)
      (List.cons
        (Prod.mk
          "value"
          (PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.natural 42)))
        List.nil)
  let body :=
    PsVerifiedIrExpr.projection
      "Box"
      (List.cons psVerifiedIrValidationNatType List.nil)
      target
      "missing"
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psVerifiedIrValidationModule body)) with
  | Except.error
      (PsVerifiedIrValidationError.unknownStructureField
        structureName
        fieldName) =>
      if psStringEq structureName "Box" then
        psStringEq fieldName "missing"
      else
        false
  | _ => false

def psTestVerifiedIrValidationRejectsUnknownInductive : Bool :=
  let body :=
    PsVerifiedIrExpr.constructor
      "Missing"
      "none"
      List.nil
      List.nil
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psVerifiedIrValidationModule body)) with
  | Except.error
      (PsVerifiedIrValidationError.unknownInductive name) =>
      psStringEq name "Missing"
  | _ => false

def psTestVerifiedIrValidationRejectsUnknownConstructor : Bool :=
  let body :=
    PsVerifiedIrExpr.constructor
      "Maybe"
      "missing"
      (List.cons psVerifiedIrValidationNatType List.nil)
      List.nil
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psVerifiedIrValidationModule body)) with
  | Except.error
      (PsVerifiedIrValidationError.unknownConstructor
        inductiveName
        constructorName) =>
      if psStringEq inductiveName "Maybe" then
        psStringEq constructorName "missing"
      else
        false
  | _ => false

def psTestVerifiedIrValidationRejectsConstructorField : Bool :=
  let body :=
    PsVerifiedIrExpr.constructor
      "Maybe"
      "some"
      (List.cons psVerifiedIrValidationNatType List.nil)
      (List.cons
        (Prod.mk
          "missing"
          (PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.natural 42)))
        List.nil)
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psVerifiedIrValidationModule body)) with
  | Except.error
      (PsVerifiedIrValidationError.unknownConstructorField
        inductiveName
        constructorName
        fieldName) =>
      if psStringEq inductiveName "Maybe" then
        if psStringEq constructorName "some" then
          psStringEq fieldName "missing"
        else
          false
      else
        false
  | _ => false

def psTestVerifiedIrValidationRejectsMatchConstructor : Bool :=
  let alternative :=
    Prod.mk
      "missing"
      (Prod.mk
        List.nil
        (PsVerifiedIrExpr.literal
          (PsVerifiedIrLiteral.natural 0)))
  let body :=
    PsVerifiedIrExpr.matchE
      "Maybe"
      (List.cons psVerifiedIrValidationNatType List.nil)
      (PsVerifiedIrExpr.var "value")
      (List.cons alternative List.nil)
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psVerifiedIrValidationModule body)) with
  | Except.error
      (PsVerifiedIrValidationError.unknownConstructor
        inductiveName
        constructorName) =>
      if psStringEq inductiveName "Maybe" then
        psStringEq constructorName "missing"
      else
        false
  | _ => false

def psTestVerifiedIrValidationRejectsMatchBindingField : Bool :=
  let binding :=
    PsVerifiedIrMatchBinding.mk
      "missing"
      "value"
      psVerifiedIrValidationNatType
  let alternative :=
    Prod.mk
      "some"
      (Prod.mk
        (List.cons binding List.nil)
        (PsVerifiedIrExpr.var "value"))
  let body :=
    PsVerifiedIrExpr.matchE
      "Maybe"
      (List.cons psVerifiedIrValidationNatType List.nil)
      (PsVerifiedIrExpr.var "input")
      (List.cons alternative List.nil)
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psVerifiedIrValidationModule body)) with
  | Except.error
      (PsVerifiedIrValidationError.unknownConstructorField
        inductiveName
        constructorName
        fieldName) =>
      if psStringEq inductiveName "Maybe" then
        if psStringEq constructorName "some" then
          psStringEq fieldName "missing"
        else
          false
      else
        false
  | _ => false

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
  { name := "specified String primitive aliases preserve emitted code", passed := psTestSpecifiedStringPrimitiveAliases },
  { name := "dual-source Lean-native text primitives", passed := psTestDualSourceLeanNativeTextPrimitives },
  { name := "dual-source Lean-native String raw-position bridge", passed := psTestDualSourceLeanNativeStringRawPositionBridge },
  { name := "dual-source Lean-native controlled partial def", passed := psTestDualSourceLeanNativePartialDefinition },
  { name := "VerifiedIR accepts resolved construction IR", passed := psTestVerifiedIrValidationAcceptsResolved },
  { name := "VerifiedIR rejects unknown result type", passed := psTestVerifiedIrValidationRejectsUnknownResult },
  { name := "VerifiedIR rejects nested unknown runtime type", passed := psTestVerifiedIrValidationRejectsNestedUnknown },
  { name := "VerifiedIR accepts structural references", passed := psTestVerifiedIrValidationAcceptsStructuralReferences },
  { name := "VerifiedIR rejects unknown structure", passed := psTestVerifiedIrValidationRejectsUnknownStructure },
  { name := "VerifiedIR rejects structure type-argument arity", passed := psTestVerifiedIrValidationRejectsStructureArity },
  { name := "VerifiedIR rejects unknown structure field", passed := psTestVerifiedIrValidationRejectsStructureField },
  { name := "VerifiedIR rejects unknown projection field", passed := psTestVerifiedIrValidationRejectsProjectionField },
  { name := "VerifiedIR rejects unknown inductive", passed := psTestVerifiedIrValidationRejectsUnknownInductive },
  { name := "VerifiedIR rejects unknown constructor", passed := psTestVerifiedIrValidationRejectsUnknownConstructor },
  { name := "VerifiedIR rejects unknown constructor field", passed := psTestVerifiedIrValidationRejectsConstructorField },
  { name := "VerifiedIR rejects unknown match constructor", passed := psTestVerifiedIrValidationRejectsMatchConstructor },
  { name := "VerifiedIR rejects unknown match binding field", passed := psTestVerifiedIrValidationRejectsMatchBindingField }
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
