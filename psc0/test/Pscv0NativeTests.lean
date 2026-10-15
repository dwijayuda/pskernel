import Pscv0PlatformTests
import Ps.Host.NativeV7
import Ps.Host.StandardManifest
import Ps.Compiler.Pscv0Modules
import Ps.Environment.StandardSnapshot
import Pscv0M1Harness
import Pscv0GetElemOracle
import Pscv0FloatConstructiveOracle
import Init.Data.ByteArray.Lemmas


-- Pinned native decisions, independent of the portable parser and registry.
private def nativeLogicDecisions (a b : Nat) : List Bool :=
  [decide (a < b ∧ a ≤ b), decide (a < b ∨ a = b), decide (a ≠ b),
   decide (a < b → a ≤ b), decide (a < b ↔ a ≤ b), decide True, decide False]
#guard nativeLogicDecisions 1 2 == [true, true, true, true, true, true, false]
#guard nativeLogicDecisions 2 2 == [false, true, false, true, false, true, false]
#guard nativeLogicDecisions 3 2 == [false, false, true, true, true, true, false]
#guard decide ((-4 : Int) = -4)
#guard !(decide ((-4 : Int) = 4))
#guard !(decide ((4 : Int) = 5))
private def nativeIntComparison (a b : Int) : List Bool :=
  [decide (a < b), decide (a ≤ b), decide (a > b), decide (a ≥ b)]
#guard nativeIntComparison (-3) 2 == [true, true, false, false]
#guard nativeIntComparison (-2) (-2) == [false, true, false, true]
#guard nativeIntComparison 3 (-2) == [false, false, true, true]

-- Independent Lean 4.35.0 Extra/Notation references for the operator slice.
example (n : Nat) (i : Int) : (n + 0) + i = Int.add (Int.add (Int.ofNat n) 0) i := rfl
example (a : Int) (n : Nat) : a ^ n = Int.pow a n := rfl
#guard (2 ^ 3 ^ 2 : Nat) == 512
#guard ((-3 : Int) ^ 5) == -243
#guard ((-3 : Int) ^ 6) == 729
#guard ((129 : UInt8) <<< 1).toNat == 2
#guard ((-9 : Int64) >>> 2).toInt == -3
#guard ((3 : UInt8) ^ 6).toNat == 217
#guard (18446744073709551617 : Nat) <<< 33 == 158456325028528675195677835264
#guard (158456325028528675195677835264 : Nat) >>> 33 == 18446744073709551617
#guard (18446744073709551617 : Nat) >>> 1000000000000000000000 == 0
#guard (0 : Nat) <<< 1000000000000000000000 == 0

-- Independent pinned native WHNF oracle for class projection transparency.
run_meta do
  let n := Lean.mkRawNatLit 857
  let nat := Lean.mkConst ``Nat
  let project := fun dictionary =>
    Lean.mkApp3 (Lean.mkConst ``OfNat.ofNat [Lean.Level.zero]) nat n dictionary
  let concrete := project (Lean.mkApp (Lean.mkConst ``instOfNatNat) n)
  let explicit := project (Lean.mkApp3 (Lean.mkConst ``OfNat.mk [Lean.Level.zero])
    nat n (Lean.mkRawNatLit 42))
  for mode in [Lean.Meta.TransparencyMode.instances, .implicit] do
    let reduced ← Lean.Meta.withTransparency mode (Lean.Meta.whnf concrete)
    unless reduced == n do
      throwError ("native class projection did not expose the indexed numeral: " ++
        toString mode ++ "; value=" ++ reduced.dbgToString ++
        "; input=" ++ concrete.dbgToString ++
        "; dictionary status=" ++ toString (← Lean.getReducibilityStatus ``instOfNatNat).toAttrString)
    unless (← Lean.Meta.withTransparency mode (Lean.Meta.whnf explicit)) == Lean.mkRawNatLit 42 do
      throwError "native class projection ignored explicit dictionary evidence"
  unless (← Lean.Meta.withTransparency .reducible (Lean.Meta.whnf concrete)) == concrete do
    throwError "native semireducible class field unfolded at reducible transparency"

-- Native boundary cases from Lean 4.35.0 System.Platform.numBits_eq,
-- UInt/ISize two's-complement model; target width is explicitly selected.
#guard (psIrMachineIntegerWidthWithTarget none .usize).isNone
#guard (psIrMachineIntegerWidthWithTarget (some .bits32) .usize) == some 32
#guard (psIrMachineIntegerWidthWithTarget (some .bits64) .isize) == some 64
#guard psIrMachineIntegerLiteralInRangeWithTarget (some .bits32) .usize 4294967295
#guard !psIrMachineIntegerLiteralInRangeWithTarget (some .bits32) .usize 4294967296
#guard psIrMachineIntegerLiteralInRangeWithTarget (some .bits32) .isize (-2147483648)
#guard !psIrMachineIntegerLiteralInRangeWithTarget (some .bits32) .isize (-2147483649)
#guard !psIrMachineIntegerLiteralInRangeWithTarget (some .bits32) .isize 2147483648
#guard psIrMachineIntegerLiteralInRangeWithTarget (some .bits64) .usize 18446744073709551615
#guard !psIrMachineIntegerLiteralInRangeWithTarget (some .bits64) .usize 18446744073709551616
#guard psIrMachineIntegerLiteralInRangeWithTarget (some .bits64) .isize (-9223372036854775808)
#guard !psIrMachineIntegerLiteralInRangeWithTarget (some .bits64) .isize 9223372036854775808
#guard !psIrMachineIntegerLiteralInRangeWithTarget none .usize 0
#guard psIrMachineIntegerLiteralInRangeWithTarget none .uint8 255
#guard !psIrMachineIntegerLiteralInRangeWithTarget none .uint8 256

-- General Lean 4.35.0 kernel proofs for the canonical selected ByteArray
-- representation; they are independent of the bounded runtime observations.
private theorem pscv0ByteArrayFromListModelExact (xs : List UInt8) :
    (⟨xs.toArray⟩ : ByteArray) = xs.toByteArray := by
  apply ByteArray.ext
  exact (List.data_toByteArray (l := xs)).symm

private theorem pscv0ByteArrayAppendModelExact (a b : ByteArray) :
    (⟨⟨a.data.toList ++ b.data.toList⟩⟩ : ByteArray) = a.append b := rfl

private theorem pscv0ByteArrayCopySliceExactLogical (src dest : ByteArray)
    (srcOff destOff len : Nat) :
    src.copySlice srcOff dest destOff len false =
      src.copySlice srcOff dest destOff len true := rfl

private theorem pscv0ByteArrayExtractCopyLogical (bytes : ByteArray)
    (start stop : Nat) :
    bytes.extract start stop =
      bytes.copySlice start ByteArray.empty 0 (stop - start) := rfl

-- Pinned Lean 4.35.0 default-instance priority, rollback and nested search.
-- Independent source oracle; the PSC0 fixture below uses the same cases.
namespace ScientificLiteralOracle
structure Decimal where
  mantissa : Nat
  negative : Bool
  exponent : Nat
instance : OfScientific Decimal where ofScientific m s e := ⟨m, s, e⟩
structure High : Type 1 where
  value : Decimal
instance : OfScientific High where ofScientific m s e := ⟨⟨m, s, e⟩⟩
def describe (value : Decimal) : String :=
  toString value.mantissa ++ ":" ++ (if value.negative then "-" else "+") ++ toString value.exponent
def generic {A : Type u} [OfScientific A] (_ : Unit) : A := 9.87
def raw [zero : OfNat Nat 0] (_ : Unit) : Decimal := 0.0
#guard describe 1.23 == "123:-2"
#guard describe 1.2e3 == "12:+2"
#guard describe 1.2E-3 == "12:-4"
#guard describe 1_2.3__4e+0_2 == "1234:+0"
#guard describe 1. == "1:-0"
#guard describe 1e0 == "1:+0"
#guard describe (raw (zero := ⟨42⟩) ()) == "0:-1"
#guard describe (generic ()) == "987:-2"
#guard describe (High.value (generic ())) == "987:-2"
end ScientificLiteralOracle

run_meta do
  let environment ← Lean.getEnv
  for source in ["1e","1e+","1.2e-","1_.0","1.0_","1._0","1.foo","1.«x»"] do
    if (Lean.Parser.runParserCategory environment `term source).isOk then
      throwError ("native scientific parser unexpectedly accepted " ++ source)

namespace LiteralConstraintOracle
structure Ticket where
  value : Nat
instance {n : Nat} : OfNat Ticket n where ofNat := ⟨n⟩
instance : Add Ticket where add a b := ⟨a.value + b.value + 1⟩
structure High : Type 1 where
  value : Nat
instance : Add High where add a b := ⟨a.value + b.value⟩
instance : HMul Nat Bool Nat where hMul a b := if b then a else 0
def add {A : Type u} [Add A] (a b : A) : A := a + b
def sub {A : Type u} [Sub A] (a b : A) : A := a - b
def mul {A : Type u} [Mul A] (a b : A) : A := a * b
def div {A : Type u} [Div A] (a b : A) : A := a / b
def mod {A : Type u} [Mod A] (a b : A) : A := a % b
def append {A : Type u} [Append A] (a b : A) : A := a ++ b
def withZero [zero : OfNat Nat 0] (_ : Unit) : Nat := 0
def inferredNatural : String := let value := 17; toString value
def inferredNegative : String := let value := -7; toString value
#guard (2 + Ticket.mk 5).value == 8
#guard (Ticket.mk 5 + 2).value == 8
#guard add (6 : Nat) 5 == 11
#guard sub (9 : Nat) 2 == 7
#guard mul (3 : Nat) 6 == 18
#guard div (10 : Nat) 3 == 3
#guard mod (11 : Nat) 3 == 2
#guard append "a" "b" == "ab"
#guard withZero (zero := ⟨42⟩) () == 42
#guard inferredNatural == "17"
#guard inferredNegative == "-7"
#guard (add (High.mk 5) (High.mk 7)).value == 12
#guard (add (Float.ofBits 4607182418800017408) (Float.ofBits 4611686018427387904)).toBits.toNat == 4613937818241073152
#guard ((9 : Nat) * true) == 9
end LiteralConstraintOracle

namespace DefaultInstanceOracle
class Choice (A : Type) where
  pick : Nat
class Missing (A : Type) where
  marker : Nat
instance ordinaryBool : Choice Bool where
  pick := 37
@[default_instance 600] instance fallbackNat : Choice Nat where
  pick := 31
@[default_instance 700] def unavailable [Missing Bool] : Choice Bool := ⟨47⟩
class Preference (A : Type) where
  pick : Nat
instance ordinaryPreference : Preference Nat := ⟨23⟩
@[default_instance 1000] def preferBool : Preference Bool := ⟨99⟩
class Outer (A : Type) where
  pick : Nat
@[default_instance 800] instance outer {A : Type} [Choice A] : Outer A :=
  ⟨Choice.pick (A := A)⟩
class Tie (A : Type) where
  pick : Nat
@[default_instance 200] instance tieNat : Tie Nat where
  pick := 1
@[default_instance 200] instance tieBool : Tie Bool where
  pick := 2
def choose {A : Type} [Choice A] (_ : Unit) : Nat := Choice.pick (A := A)
def competing {A : Type} [Choice A] [Preference A] (_ : Unit) : Nat := Choice.pick (A := A)
def nested {A : Type} [Outer A] (_ : Unit) : Nat := Outer.pick (A := A)
def tie {A : Type} [Tie A] (_ : Unit) : Nat := Tie.pick (A := A)
def anchored {A : Type} [Choice A] (_ : A) : Nat := Choice.pick (A := A)
def preference {A : Type} [Preference A] (_ : Unit) : Nat := Preference.pick (A := A)
#guard choose () == 31
#guard competing () == 37
#guard nested () == 31
#guard tie () == 2
#guard anchored true == 37
#guard preference () == 99
-- A fixed goal with no ordinary candidate is a definite failure, not defaulting.
example : Nat := by
  fail_if_success exact Preference.pick (A := Bool)
  exact 0
universe u
class Poly (A : Type u) where
  pick : Nat
@[default_instance] instance poly {A : Type u} [Inhabited A] : Poly A := ⟨91⟩
structure High : Type 1 where
  value : Nat
  deriving Inhabited
#guard Poly.pick (A := High) == 91
class OnlyDefault (A : Type) where
  pick : Nat
@[default_instance] def onlyDefault : OnlyDefault Nat := ⟨83⟩
example : Nat := by
  fail_if_success exact OnlyDefault.pick
  exact 0
end DefaultInstanceOracle

open Lean (toJson)

private def get {α : Type} (label : String) (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError (label ++ ": " ++ error))

private def parserCases : IO Unit := do
  -- Exact scientific decoding and malformed-token refusal are paired with
  -- pinned native syntax, independently of any floating runtime implementation.
  for source in ["1.23","1.2e3","1.2E-3","1_2.3__4e+0_2","1.","1e0","123.E+3","1e-0","0.0","9007199254740993123456789e-400"] do
    unless psParseScientificText source == Lean.Syntax.decodeScientificLitVal? source do
      throw (IO.userError ("scientific decoder mismatch: " ++ source))
    let tokens ← match psLexProofScript source with
      | .ok tokens => pure tokens
      | .error _ => throw (IO.userError ("scientific lexer refused " ++ source))
    let some token := tokens.head? | throw (IO.userError "missing scientific token")
    unless psTokenKindEq token.kind .scientific && token.text == source &&
        token.span.start.byteOffset == 0 && token.span.stop.byteOffset == source.utf8ByteSize do
      throw (IO.userError ("scientific token/span drift: " ++ source))
  for source in ["1e","1e+","1.2e-","1_.0","1.0_","1._0","1.foo","1.«x»"] do
    if (psLexProofScript source).isOk then
      throw (IO.userError ("malformed scientific token accepted: " ++ source))
  let .ok rangeTokens := psLexProofScript "1..2"
    | throw (IO.userError "range tokenization refused")
  unless rangeTokens.head?.any (fun token =>
      psTokenKindEq token.kind .natural && token.text == "1") do
    throw (IO.userError "decimal lexer consumed the first range dot")
  -- Exact source ownership for all four Lean RC4 index spellings.
  -- These are parser cases, not a claim that List/Array GetElem instances or
  -- automatic arithmetic proof discharge are already installed.
  for (label, input) in [
      ("checked indexing", "function sample(xs: List Nat, i: Nat, h: True): Nat := xs[i]'h\n"),
      ("implicit proof indexing", "function sample(xs: List Nat, i: Nat): Nat := xs[i]\n"),
      ("safe optional indexing", "const result: Option Nat := xs[0]?\n"),
      ("panic/default indexing", "const result: Nat := xs[0]!\n"),
      ("nested optional indexing", "const result: Option Nat := nested[0][1]?\n"),
      ("ordinary char literal", "const mark: Char := 'x'\n"),
      ("projection on parenthesized call",
        "structure Container where { value: Nat }\nconst result: Nat := (Container.mk(21)).value\n"),
      ("chained projection on computed expression",
        "structure Inner where { value: Nat }\nstructure Outer where { inner: Inner }\nconst result: Nat := (Outer.mk(Inner.mk(34))).inner.value\n"),
      ("projection following a call",
        "structure Container where { value: Nat }\nfunction make(): Container := Container.mk(55)\nconst result: Nat := make().value\n")] do
    unless (psPscv0ParseProgram input).isOk do
      throw (IO.userError ("GetElem parser rejected " ++ label))
  -- Lean's trailing projection is deliberately adjacent on BOTH sides.
  -- The parser must refuse whitespace rather than interpreting it as
  -- implicit application or silently selecting a different field.
  for input in [
      "structure Container where { value: Nat }\nconst result: Nat := (Container.mk(21)) .value\n",
      "structure Container where { value: Nat }\nconst result: Nat := (Container.mk(21)). value\n"] do
    if (psPscv0ParseProgram input).isOk then
      throw (IO.userError "nonadjacent postfix field was accepted")
  let json ← get "parser corpus" (Lean.Json.parse
    (← IO.FS.readFile "../scripts/pscv0-m1-cases.json"))
  let good ← get "good cases" ((json.getObjVal? "good").bind Lean.Json.getArr?)
  let bad ← get "bad cases" ((json.getObjVal? "bad").bind Lean.Json.getArr?)
  for c in good do
    m1Good
      (← get "name" (c.getObjValAs? String "name"))
      (← get "source" (c.getObjValAs? String "source"))
      (← get "result" (c.getObjValAs? String "result"))
      (← get "locals" (c.getObjValAs? (List String) "locals"))
  for c in bad do
    m1Bad
      (← get "name" (c.getObjValAs? String "name"))
      (← get "source" (c.getObjValAs? String "source"))
      (← get "error" (c.getObjValAs? String "error"))

-- A user-defined GetElem instance demonstrates genuine Prop-indexed,
-- class-driven lookup without a trusted bounds shortcut. The selected
-- builtin collection instances and dictionary coherence are exercised below.
private def getElemFoundationCases : IO Unit := do
  let source :=
    "structure IndexBox where { value: Nat }\n" ++
    "instance indexBoxGet: GetElem(IndexBox, Nat, Nat, fun (_: IndexBox) => fun (i: Nat) => i = 0) where {\n" ++
    "  getElem(xs: IndexBox, i: Nat, h: i = 0): Nat := xs.value\n" ++
    "}\n" ++
    "function implicitLookup(xs: IndexBox, i: Nat, h: i = 0): Nat := xs[i]\n" ++
    "function explicitLookup(xs: IndexBox, i: Nat, h: i = 0): Nat := xs[i]'h\n" ++
    "function reflectedIndex(xs: IndexBox): Nat := xs[0]\n" ++
    "structure AlwaysBox where { value: Nat }\n" ++
    "instance alwaysGet: GetElem(AlwaysBox, Nat, Nat, fun (_: AlwaysBox) => fun (_: Nat) => True) where {\n" ++
    "  getElem(xs: AlwaysBox, i: Nat, h: True): Nat := xs.value\n" ++
    "}\n" ++
    "function triviallyValid(xs: AlwaysBox): Nat := xs[42]\n" ++

    -- The selected Type-0 optional class carries its checked GetElem
    -- superclass dictionary; no unchecked validity proof is introduced.
    "instance alwaysOptional: GetElem?(AlwaysBox, Nat, Nat, fun (_: AlwaysBox) => fun (_: Nat) => True) where {\n" ++
    "  toGetElem := alwaysGet\n" ++
    "  getElem?(xs: AlwaysBox, i: Nat): Option Nat := Option.some(xs.value)\n" ++
    "  getElem![inhabited: Inhabited Nat](xs: AlwaysBox, i: Nat): Nat := GetElem?.getElem!Default(Option.some(xs.value))\n" ++
    "}\n" ++
    -- Reflection is a checked proof, not an unchecked Bool-to-Prop cast.
    -- Test dependent elimination before proving two decisions are equal.
    "theorem psDecisionReflectsAsOr(P: Prop, decision: Decidable P): P ∨ ¬P := by {\n" ++
    "  cases decision\n" ++
    "  case intro flag reflects =>\n" ++
    "    cases flag\n" ++
    "    case false => exact Or.inr(reflects)\n" ++
    "    case true => exact Or.inl(reflects)\n" ++
    "}\n" ++

    -- The official Lean kernel supports proof irrelevance: two inhabitants
    -- of the same checked proposition are propositionally equal.
    -- Keep arbitrary Decidable uniqueness pending rather than admitting it
    -- without a checked dependent reflection proof.
    "theorem psPropProofIrrelevance(P: Prop, a: P, b: P): a = b := by { rfl }\n" ++

    -- RC4 Nat.lt unfolds to the kernel-checked Nat.le inductive. These
    -- witnesses are actual proofs, not the value of Nat.blt or a cast.
    "theorem orderPositive: Nat.le(2, 5) := PsStandard.natBleReflects(2, 5)\n" ++
    "theorem orderNegative: ¬Nat.le(5, 2) := PsStandard.natBleReflects(5, 2)\n" ++
    "theorem orderZero(n: Nat): Nat.le(0, n) := Nat.zero_le(n)\n" ++
    "theorem modZero(n: Nat): Nat.mod(0, n) = 0 := by { rfl }\n" ++
    "theorem modBound(x: Nat, y: Nat, h: Nat.lt(0, y)): Nat.lt(Nat.mod(x, y), y) := Nat.mod_lt(x, h)\n" ++
    "function boundedMod(x: Nat, y: Nat, h: Nat.lt(0, y)): Fin(y) := Fin.mk(Nat.mod(x, y), Nat.mod_lt(x, h))\n" ++
    "theorem conditionalKnown(P: Prop, h: P, n: Nat): ite(P, n, 0, h := Decidable.isTrue(h)) = n := by { rfl }\n" ++
    "theorem conditionalRefuted(P: Prop, h: Not P, n: Nat): ite(P, 0, n, h := Decidable.isFalse(h)) = n := by { rfl }\n" ++
    "theorem booleanEqualsTrue(a: Bool): (a == true) = a := by { rfl }\n" ++
    "theorem addZeroRight(n: Nat): Nat.add(n, 0) = n := by { rfl }\n" ++
    "theorem addSuccessor(n: Nat, m: Nat): Nat.add(n, Nat.succ(m)) = Nat.succ(Nat.add(n, m)) := by { rfl }\n" ++
    "theorem subZeroRight(n: Nat): Nat.sub(n, 0) = n := by { rfl }\n" ++
    "theorem subSuccessor(n: Nat, m: Nat): Nat.sub(n, Nat.succ(m)) = Nat.pred(Nat.sub(n, m)) := by { rfl }\n" ++
    "theorem mulSuccessor(n: Nat, m: Nat): Nat.mul(n, Nat.succ(m)) = Nat.add(Nat.mul(n, m), n) := by { rfl }\n" ++
    "theorem beqSuccessors(n: Nat, m: Nat): Nat.beq(Nat.succ(n), Nat.succ(m)) = Nat.beq(n, m) := by { rfl }\n" ++
    "theorem orderRaise(n: Nat, m: Nat, h: Nat.le(n, m)): Nat.le(Nat.succ(n), Nat.succ(m)) := Nat.succ_le_succ(h)\n" ++
    "theorem orderLower(n: Nat, m: Nat, h: Nat.le(Nat.succ(n), Nat.succ(m))): Nat.le(n, m) := Nat.le_of_succ_le_succ(h)\n" ++
    "theorem orderImpossible(n: Nat): ¬Nat.lt(n, 0) := Nat.not_lt_zero(n)\n" ++
    "theorem orderCompose(n: Nat, m: Nat, k: Nat, h: Nat.le(n, m), q: Nat.le(m, k)): Nat.le(n, k) := Nat.le_trans(h, q)\n" ++
    "theorem orderStrictLower(n: Nat, m: Nat, h: Nat.lt(Nat.succ(n), Nat.succ(m))): Nat.lt(n, m) := Nat.lt_of_succ_lt_succ(h)\n" ++
    "theorem naturalBoundDirect: Nat.lt(0, Nat.succ(0)) := Nat.le.refl\n" ++
    "theorem naturalBoundConstructor: Nat.lt(0, Nat.succ(0)) := by { constructor }\n" ++
    "const optionalResult: Option Nat := (AlwaysBox.mk(37))[42]?\n" ++
    "const bangResult: Nat := (AlwaysBox.mk(41))[42]!\n" ++
    "structure ProductProofBox where { value: Nat }\n" ++
    "instance productProofGet: GetElem(ProductProofBox, Nat, Nat, fun (_: ProductProofBox) => fun (_: Nat) => True ∧ True) where {\n" ++
    "  getElem(xs: ProductProofBox, i: Nat, h: True ∧ True): Nat := xs.value\n" ++
    "}\n" ++
    "function constructorProof(xs: ProductProofBox): Nat := xs[42]\n" ++
    "const constructorResult: Nat := constructorProof(ProductProofBox.mk(31))\n" ++
    "const reflexiveResult: Nat := reflectedIndex(IndexBox.mk(23))\n" ++
    "const trivialResult: Nat := triviallyValid(AlwaysBox.mk(29))\n" ++
    "const selected: Nat := implicitLookup(IndexBox.mk(17), 0, by { rfl })\n" ++
    "const selectedExplicit: Nat := explicitLookup(IndexBox.mk(19), 0, by { rfl })\n"
  let unproved := source ++
    "const unproved: Nat := (IndexBox.mk(4))[1]\n"
  let batch ← PsV7Native.runBatch #[
    { source := source, targets := [.javascript, .typescript, .rust],
      sourceName := "GetElemGood.ps" },
    { source := unproved, targets := [], sourceName := "GetElemUnproved.ps" },
    { source := "theorem bad: Nat.le(5, 2) := PsStandard.natBleReflects(5, 2)\n",
      targets := [], sourceName := "OrderFalse.ps" },
    { source := "const i: Fin(10) := Fin.mk(1, PsStandard.natBleReflects(2, 10))\nconst bad: Nat := [1][i]\n", targets := [], sourceName := "FinWrongCollection.ps" },
    { source := "const bad: Nat := [1, 2][2]\n", targets := [], sourceName := "ListOutOfBounds.ps" },
    { source := "const bad: Nat := #[1, 2][2]\n", targets := [], sourceName := "ArrayOutOfBounds.ps" },
    { source := "const i: Fin(10) := Fin.mk(1, PsStandard.natBleReflects(2, 10))\nconst bad: Nat := #[1][i]\n", targets := [], sourceName := "FinWrongArray.ps" },
    { source := "structure CustomIndex where { value: Nat }\ninstance customChecked: GetElem(CustomIndex, Nat, Nat, fun (_: CustomIndex) => fun (_: Nat) => True) where { getElem(xs: CustomIndex, i: Nat, h: True): Nat := xs.value }\ninstance (priority := high) customOptional: GetElem?(CustomIndex, Nat, Nat, fun (_: CustomIndex) => fun (_: Nat) => True) where {\n  toGetElem := customChecked\n  getElem?(xs: CustomIndex, i: Nat): Option Nat := Option.none\n  getElem![inhabited: Inhabited Nat](xs: CustomIndex, i: Nat): Nat := GetElem?.getElem!Default((Option.none : Option Nat))\n}\nfunction requireLaw[LawfulGetElem(CustomIndex, Nat, Nat, fun (_: CustomIndex) => fun (_: Nat) => True, optional := customOptional)](xs: CustomIndex): Nat := xs.value\nconst bad: Nat := requireLaw(CustomIndex.mk(701))\n", targets := [], sourceName := "UnlawfulOptional.ps" },
    { source := "structure CustomIndex where { value: Nat }\ninstance customChecked: GetElem(CustomIndex, Nat, Nat, fun (_: CustomIndex) => fun (_: Nat) => True) where { getElem(xs: CustomIndex, i: Nat, h: True): Nat := xs.value }\ninstance (priority := high) customOptional: GetElem?(CustomIndex, Nat, Nat, fun (_: CustomIndex) => fun (_: Nat) => True) where {\n  toGetElem := customChecked\n  getElem?(xs: CustomIndex, i: Nat): Option Nat := Option.none\n  getElem![inhabited: Inhabited Nat](xs: CustomIndex, i: Nat): Nat := GetElem?.getElem!Default((Option.none : Option Nat))\n}\nfunction requireFinLaw[LawfulGetElem(CustomIndex, Fin(10), Nat, fun (_: CustomIndex) => fun (_: Fin(10)) => True)](xs: CustomIndex): Nat := xs.value\nconst bad: Nat := requireFinLaw(CustomIndex.mk(701))\n", targets := [], sourceName := "UnlawfulFinOptional.ps" }]
  let result ← match batch with
    | .ok result => pure result
    | .error reason => throw (IO.userError ("native GetElem batch failed: " ++
        reason.phase ++ ": " ++ reason.message))
  let some admitted := result.results[0]?
    | throw (IO.userError "GetElem checked-source result missing")
  match admitted with
  | .error reason =>
    throw (IO.userError ("proof-carrying GetElem source not accepted: " ++
      reason.phase ++ ": " ++ reason.message))
  | .ok accepted =>
    unless accepted.declarationCount > 0 do
      throw (IO.userError "GetElem checked source emitted no declarations")
    unless accepted.artifacts.length == 3 do
      throw (IO.userError "GetElem checked source missing JS/TS/Rust artifacts")
  let some rejected := result.results[1]?
    | throw (IO.userError "GetElem negative result missing")
  match rejected with
  | .ok _ => throw (IO.userError "unproved indexed term was admitted")
  | .error refused =>
    unless refused.phase == "elaborate" do
      throw (IO.userError ("unproved indexed term failed in wrong phase: " ++ refused.phase))
  for i in [2:9] do
    match result.results[i]? with
    | some (.error error) =>
      unless error.phase == "elaborate" do
        throw (IO.userError s!"invalid bound {i} failed outside elaboration")
    | _ => throw (IO.userError s!"false natural or collection bound {i} was accepted")
  IO.println "PSCV0_NATIVE_GETELEM: checked indexed proof/instance admitted; missing proof refused"

private def generalizedFixture : String :=
  "namespace Generalized\nuniverse u\nclass Evidence(A: outParam(Type u)): Type u where { value: Nat }\nfunction generic(A: Type u): Evidence A := { value := 773 }\nclass Select(n: Nat, A: outParam(Type)) where { value: Nat }\ninstance selectNat: Select 0 Nat where { value := 5 }\ninstance selectBool: Select 1 Bool where { value := 7 }\nclass Branch(n: Nat) where { value: Nat }\ninstance branch{n: Nat}{A: Type}[Evidence A][Select n A]: Branch n where { value := Nat.add(Evidence.value(A := A), Select.value(n := n, A := A)) }\nclass Result where { value: Nat }\ninstance combine[Branch 0][Branch 1]: Result where { value := Nat.add(Branch.value(n := 0), Branch.value(n := 1)) }\nfunction combined[poly: forall(A: Type), Evidence A](unit: Unit): Nat := Result.value\nfunction selected(A: Type := Nat)[Inhabited A](value: A := Inhabited.default): A := value\nfunction expected{A: Type}[Inhabited A](unit: Unit, value: A := Inhabited.default): A := value\nend Generalized\n"

private def generalizedRuntimeFixture : String :=
  "namespace GeneralizedRuntime\nclass Evidence(n: outParam(Nat)) where { value: Nat }\nfunction generic(n: Nat): Evidence n := { value := n }\nclass Select(key: Nat, n: outParam(Nat)) where { value: Nat }\ninstance selectFirst: Select 0 5 where { value := 773 }\ninstance selectSecond: Select 1 7 where { value := 773 }\nclass Branch(key: Nat) where { value: Nat }\ninstance branch{key: Nat}{n: Nat}[Evidence n][Select key n]: Branch key where { value := Nat.add(Evidence.value(n := n), Select.value(key := key, n := n)) }\nclass Result where { value: Nat }\ninstance combine[Branch 0][Branch 1]: Result where { value := Nat.add(Branch.value(key := 0), Branch.value(key := 1)) }\nfunction combined[poly: forall(n: Nat), Evidence n](unit: Unit): Nat := Result.value\nfunction selected(A: Type := Nat)[Inhabited A](value: A := Inhabited.default): A := value\nfunction expected{A: Type}[Inhabited A](unit: Unit, value: A := Inhabited.default): A := value\nend GeneralizedRuntime\n"

private def reprFixture : String :=
  "namespace Display\nuniverse u\nstructure Box(A: Type u): Type u where { value: A } deriving Repr\nstructure Checked where { count: Nat\n witness: count = count } deriving Repr\nstructure Types: Type 1 where { carrier: Type\n witness: True } deriving Repr\ninductive Event(A: Type u): Type u where { | empty | value(payload: A) } deriving Repr\ninductive Hidden where { | item{secret: Nat}(value: Nat) } deriving Repr\ninductive Void where { } deriving Repr\nend Display\nconst displayQuoted: String := reprStr(\"λ😀\\n\")\nconst displayNegative: String := Std.Format.pretty(reprArg((-17 : Int)))\nconst displayOption: String := reprStr(Option.some(Option.some((17 : Nat))))\nconst displayRecord: String := reprStr(Display.Box.mk(\"x\"))\nconst displayProof: String := reprStr(Display.Checked.mk(19, by { rfl }))\nconst displayTypes: String := reprStr(Display.Types.mk(Nat, True.intro))\nconst displayCtor: String := reprStr(Display.Event.value(Option.some((23 : Nat))))\nconst displayNullary: String := Std.Format.pretty(reprArg((Display.Event.empty : Display.Event Nat)))\nconst displayImplicit: String := reprStr(Display.Hidden.item(secret := 41, value := 43))\nconst displayAtomic: String := Std.Format.pretty(repr([1, 2, 3, 4]), 8)\nconst displayNonAtomic: String := Std.Format.pretty(repr([Option.some((1 : Nat)), Option.some(2), Option.some(3)]), 18)\nconst displayIdentity: String := Std.Format.pretty(Std.format(Std.Format.group(Std.Format.append(Std.Format.text(\"a\"), Std.Format.append(Std.Format.line, Std.Format.text(\"b\"))))), 3)\nconst displayFallback: String := Std.Format.pretty(Std.format((29 : Nat)))\nconst displayJoin: String := Std.Format.pretty(Std.Format.joinSep([\"a\", \"b\", \"c\"], Std.Format.text(\"|\")))\nconst displayPrefix: String := Std.Format.pretty(Std.Format.prefixJoin(Std.Format.text(\">\"), [\"a\", \"b\"]))\nconst displaySuffix: String := Std.Format.pretty(Std.Format.joinSuffix([\"a\", \"b\"], Std.Format.text(\"!\")))\nconst displayHigh: String := reprStr(Display.Box.mk(Display.Types.mk(Nat, True.intro)))\nconst displayTuple: String := reprStr(Prod.mk((3 : Nat), Prod.mk(\"x\", true)))\nconst displayArray: String := Std.Format.pretty(repr(Array.mk([Option.some((1 : Nat)), Option.some(2), Option.some(3)])), 20)\nconst displayFin: String := reprStr(Fin.mk(n := 4, val := 3, isLt := Nat.lt_succ_self(3)))\nconst displaySoftLines: String := Std.Format.pretty(Std.Format.group(String.toFormat(\"λ\\n\\nx\")))\nconst displayTypedFormat: Std.Format := (\"a\" : Std.Format) ++ Std.Format.line ++ (\"b\" : Std.Format)\nconst displayAppend: String := Std.Format.pretty(Std.Format.group(displayTypedFormat), 3)\nconst displayTupleFormat: String := Std.Format.pretty(Std.format(Prod.mk(\"x\", true)))\nconst displayArrayFormat: String := Std.Format.pretty(Std.format(Array.mk([1, 2, 3])))\nconst displayId: String := reprStr((31 : Id Nat))\nconst displayDecision: String := Std.Format.pretty(reprArg(Decidable.isTrue(True.intro)))\nconst displayFalseDecision: String := reprStr(Nat.decLt(4, 3))\nconst displayPublic: String := Nat.repr(47)\n"

private def formatFixture : String :=
  "function formatPair(a: Std.Format, b: Std.Format): Std.Format := Std.Format.append(a, Std.Format.append(Std.Format.line, b))\nconst formatHardDoc: Std.Format := formatPair(Std.Format.text(\"A\\nB\"), Std.Format.text(\"C\"))\nconst formatHardOutside: String := Std.Format.pretty(formatHardDoc)\nconst formatHardInside: String := Std.Format.pretty(Std.Format.group(formatHardDoc), 10)\nconst formatFillDoc: Std.Format := Std.Format.append(Std.Format.fill(formatPair(Std.Format.text(\"a\"), formatPair(Std.Format.text(\"b\\nlooooooooong\"), Std.Format.text(\"c\")))), Std.Format.append(Std.Format.line, Std.Format.text(\"d\")))\nconst formatFillResult: String := Std.Format.pretty(formatFillDoc, 5)\nfunction formatUnicode(width: Nat): String := Std.Format.pretty(Std.Format.group(formatPair(Std.Format.text(\"λ😀\"), Std.Format.text(\"x\"))), width)\nconst formatNegativeNest: String := Std.Format.pretty(Std.Format.nest((-4 : Int), Std.Format.group(formatPair(Std.Format.text(\"a\"), Std.Format.text(\"b\")))), 1, 2)\nconst formatAlignment: String := Std.Format.pretty(Std.Format.nest((2 : Int), Std.Format.append(Std.Format.text(\".\"), Std.Format.append(Std.Format.align(false), formatPair(Std.Format.text(\"a\"), Std.Format.text(\"b\"))))))\nconst formatForcedAlignment: String := Std.Format.pretty(Std.Format.nest((2 : Int), Std.Format.group(Std.Format.append(Std.Format.text(\".\"), Std.Format.append(Std.Format.align(true), formatPair(Std.Format.text(\"a\"), Std.Format.text(\"b\")))))))\nconst formatInitialColumn: String := Std.Format.pretty(Std.Format.group(formatPair(Std.Format.text(\"a\"), Std.Format.text(\"b\"))), 3, 2, 1)\nconst formatEmptyTagged: Bool := Std.Format.isEmpty(Std.Format.tag(17, Std.Format.append(Std.Format.text(\"\"), Std.Format.align(false))))\nconst formatTextNotNil: Bool := Std.Format.isNil(Std.Format.text(\"\"))\n"

private def productUniverseFixture : String :=
  "namespace ProductLevels\nuniverse u v\nstructure High: Type 1 where { value: Nat } deriving Inhabited, BEq, Repr, Hashable\ninstance highFormat: Std.ToFormat(High) where { format(value: High): Std.Format := Std.Format.text(\"hi\") }\nfunction first{A: Type u}{B: Type v}(pair: Prod(A, B)): A := pair.fst\nfunction second{A: Type u}{B: Type v}(pair: Prod(A, B)): B := match pair with { | Prod.mk a b => b }\ntheorem firstPair{A: Type u}{B: Type v}(a: A, b: B): Prod.fst(Prod.mk(a, b)) = a := by { rfl }\ntheorem reverseDefinition{A: Type u}(xs: List A): List.reverse(xs) = List.reverseAux(xs, []) := by { rfl }\nend ProductLevels\nconst productHighFold: Nat := (List.foldl(fun (acc: ProductLevels.High) => fun (n: Nat) => ProductLevels.High.mk(acc.value + n), ProductLevels.High.mk(0), [1, 2, 3], α := ProductLevels.High, β := Nat)).value\nconst productHighLeft: Nat := ProductLevels.first(Prod.mk(ProductLevels.High.mk(5), true)).value\nconst productHighRight: Nat := ProductLevels.second(Prod.mk(true, ProductLevels.High.mk(7))).value\nconst productHighDefault: Nat := (Inhabited.default : Prod(ProductLevels.High, Nat)).fst.value\nconst productHighEqual: Bool := Prod.mk(ProductLevels.High.mk(5), true) == Prod.mk(ProductLevels.High.mk(5), true)\nconst productHighUnequal: Bool := Prod.mk(true, ProductLevels.High.mk(5)) == Prod.mk(true, ProductLevels.High.mk(7))\nconst productHighRepr: String := reprStr(Prod.mk(ProductLevels.High.mk(5), true))\nconst productHighFormat: String := Std.Format.pretty(Std.format(Prod.mk(true, ProductLevels.High.mk(5))))\nconst productHighHash: Bool := hash(Prod.mk(ProductLevels.High.mk(5), true)) == mixHash(hash(ProductLevels.High.mk(5)), hash(true))\n"

-- A single pinned-Lean differential family checks the Hashable class on a
-- higher-universe structure, an ordinary Bool and a mixed-universe product.
-- These independent requests distinguish a missing derived dictionary from
-- broken product instance matching or numeric result elaboration. Each
-- request must be kernel accepted, with no fallback or silent omission.
private def highUniverseHashableCases : IO Unit := do
  let [sourcePrefix, _] := productUniverseFixture.splitOn "end ProductLevels\n"
    | throw (IO.userError "mixed-universe Hashable fixture lacks namespace terminator")
  let base := sourcePrefix ++ "end ProductLevels\n"
  let samples := #[
    ("high structure",
      "const highValueHash: UInt64 := hash(ProductLevels.High.mk(5))\n"),
    ("ordinary Boolean",
      "const boolValueHash: UInt64 := hash(true)\n"),
    ("mixed-universe product",
      "const mixedPairHash: UInt64 := hash(Prod.mk(ProductLevels.High.mk(5), true))\n"),
    ("mixed-universe hash equality",
      "const mixedPairCheck: Bool := hash(Prod.mk(ProductLevels.High.mk(5), true)) == mixHash(hash(ProductLevels.High.mk(5)), hash(true))\n")]
  let requests : Array PsV7Native.Request := samples.map fun (_, source) =>
    { source := base ++ source }
  let result ← PsV7Native.runBatch requests
  let batch ← match result with
    | .error error => throw (IO.userError ("Hashable universe batch: " ++ error.message))
    | .ok batch => pure batch
  for i in [:samples.size] do
    let some (label, _) := samples[i]? | throw (IO.userError "missing Hashable case label")
    let some answer := batch.results[i]? | throw (IO.userError "missing Hashable batch result")
    match answer with
    | .ok _ => IO.println ("PSCV0_HASHABLE_UNIVERSE: PASS " ++ label)
    | .error problem => throw (IO.userError ("PSCV0_HASHABLE_UNIVERSE: " ++
        label ++ " refused at " ++ problem.phase ++ ": " ++ problem.message))

-- One cross-universe family exercises the shared logical and runtime boundary.
private def floatDisplayFixture : String :=
  "function f4Display64(bits: Nat): String := Float.toString(Float.ofBits(UInt64.ofNat(bits)))\nfunction f4Display32(bits: Nat): String := Float32.toString(Float32.ofBits(UInt32.ofNat(bits)))\nfunction f4Repr64(bits: Nat, prec: Nat): String := Std.Format.pretty(Float.repr(Float.ofBits(UInt64.ofNat(bits)), prec))\nfunction f4Repr32(bits: Nat, prec: Nat): String := Std.Format.pretty(Float32.repr(Float32.ofBits(UInt32.ofNat(bits)), prec))\nfunction f4Narrow(bits: Nat): Nat := UInt32.toNat(Float32.toBits(Float.toFloat32(Float.ofBits(UInt64.ofNat(bits)))))\nfunction f4Widen(bits: Nat): Nat := UInt64.toNat(Float.toBits(Float32.toFloat(Float32.ofBits(UInt32.ofNat(bits)))))\nfunction f4Generic{A: Type}[ToString A](value: A): String := toString(value)\nfunction f4Apply(fn: Float -> String, value: Float): String := fn(value)\nconst f4GenericResult: String := f4Generic((1.5 : Float32))\nconst f4PartialResult: String := f4Apply(Float.toString, -1.5)\nconst f4Interpolation: String := s!\"float={(-0.0 : Float)}\"\nconst f4AtomicList: String := reprStr([(1.5 : Float), -2.25])\nconst f4Format: String := Std.Format.pretty(Std.format((1.5 : Float)))\n"

private def floatConversionsFixture : String :=
  "function f3Scientific64(m: Nat, s: Bool, e: Nat): Nat := UInt64.toNat(Float.toBits(Float.ofScientific(m, s, e)))\nfunction f3ModelScientific64(m: Nat, s: Bool, e: Nat): Nat := UInt64.toNat(Float.toBits(Float.ofModel(Float.Model.ofScientific(m, if (s) { -Int.ofNat(e) } else { Int.ofNat(e) }))))\nfunction f3Natural64(n: Nat): Nat := UInt64.toNat(Float.toBits(Nat.toFloat(n)))\nfunction f3Integer64(n: Int): Nat := UInt64.toNat(Float.toBits(Int.toFloat(n)))\nfunction f3Scientific32(m: Nat, s: Bool, e: Nat): Nat := UInt32.toNat(Float32.toBits(Float32.ofScientific(m, s, e)))\nfunction f3ModelScientific32(m: Nat, s: Bool, e: Nat): Nat := UInt32.toNat(Float32.toBits(Float32.ofModel(Float32.Model.ofScientific(m, if (s) { -Int.ofNat(e) } else { Int.ofNat(e) }))))\nfunction f3Natural32(n: Nat): Nat := UInt32.toNat(Float32.toBits(Nat.toFloat32(n)))\nfunction f3Integer32(n: Int): Nat := UInt32.toNat(Float32.toBits(Int.toFloat32(n)))\nconst f3FloatUInt8: Bool := (Float.toUInt8(Float.nan) == UInt8.ofNat(0)) && (Float.toUInt8(Float.inf) == UInt8.ofNat(255)) && (Float.toUInt8(-Float.inf) == UInt8.ofNat(0)) && (Float.toUInt8(-7.9) == UInt8.ofNat(0)) && (UInt8.toFloat(UInt8.ofNat(247)) == 247.0)\nconst f3FloatUInt16: Bool := (Float.toUInt16(Float.nan) == UInt16.ofNat(0)) && (Float.toUInt16(Float.inf) == UInt16.ofNat(65535)) && (Float.toUInt16(-Float.inf) == UInt16.ofNat(0)) && (Float.toUInt16(-7.9) == UInt16.ofNat(0)) && (UInt16.toFloat(UInt16.ofNat(247)) == 247.0)\nconst f3FloatUInt32: Bool := (Float.toUInt32(Float.nan) == UInt32.ofNat(0)) && (Float.toUInt32(Float.inf) == UInt32.ofNat(4294967295)) && (Float.toUInt32(-Float.inf) == UInt32.ofNat(0)) && (Float.toUInt32(-7.9) == UInt32.ofNat(0)) && (UInt32.toFloat(UInt32.ofNat(247)) == 247.0)\nconst f3FloatUInt64: Bool := (Float.toUInt64(Float.nan) == UInt64.ofNat(0)) && (Float.toUInt64(Float.inf) == UInt64.ofNat(18446744073709551615)) && (Float.toUInt64(-Float.inf) == UInt64.ofNat(0)) && (Float.toUInt64(-7.9) == UInt64.ofNat(0)) && (UInt64.toFloat(UInt64.ofNat(247)) == 247.0)\nconst f3FloatInt8: Bool := (Float.toInt8(Float.nan) == Int8.ofInt(0)) && (Float.toInt8(Float.inf) == Int8.ofInt(127)) && (Float.toInt8(-Float.inf) == Int8.ofInt(-128)) && (Float.toInt8(-7.9) == Int8.ofInt(-7)) && (Int8.toFloat(Int8.ofInt(-7)) == -7.0)\nconst f3FloatInt16: Bool := (Float.toInt16(Float.nan) == Int16.ofInt(0)) && (Float.toInt16(Float.inf) == Int16.ofInt(32767)) && (Float.toInt16(-Float.inf) == Int16.ofInt(-32768)) && (Float.toInt16(-7.9) == Int16.ofInt(-7)) && (Int16.toFloat(Int16.ofInt(-7)) == -7.0)\nconst f3FloatInt32: Bool := (Float.toInt32(Float.nan) == Int32.ofInt(0)) && (Float.toInt32(Float.inf) == Int32.ofInt(2147483647)) && (Float.toInt32(-Float.inf) == Int32.ofInt(-2147483648)) && (Float.toInt32(-7.9) == Int32.ofInt(-7)) && (Int32.toFloat(Int32.ofInt(-7)) == -7.0)\nconst f3FloatInt64: Bool := (Float.toInt64(Float.nan) == Int64.ofInt(0)) && (Float.toInt64(Float.inf) == Int64.ofInt(9223372036854775807)) && (Float.toInt64(-Float.inf) == Int64.ofInt(-9223372036854775808)) && (Float.toInt64(-7.9) == Int64.ofInt(-7)) && (Int64.toFloat(Int64.ofInt(-7)) == -7.0)\nconst f3Float32UInt8: Bool := (Float32.toUInt8(Float32.nan) == UInt8.ofNat(0)) && (Float32.toUInt8(Float32.inf) == UInt8.ofNat(255)) && (Float32.toUInt8(-Float32.inf) == UInt8.ofNat(0)) && (Float32.toUInt8(-7.9) == UInt8.ofNat(0)) && (UInt8.toFloat32(UInt8.ofNat(247)) == 247.0)\nconst f3Float32UInt16: Bool := (Float32.toUInt16(Float32.nan) == UInt16.ofNat(0)) && (Float32.toUInt16(Float32.inf) == UInt16.ofNat(65535)) && (Float32.toUInt16(-Float32.inf) == UInt16.ofNat(0)) && (Float32.toUInt16(-7.9) == UInt16.ofNat(0)) && (UInt16.toFloat32(UInt16.ofNat(247)) == 247.0)\nconst f3Float32UInt32: Bool := (Float32.toUInt32(Float32.nan) == UInt32.ofNat(0)) && (Float32.toUInt32(Float32.inf) == UInt32.ofNat(4294967295)) && (Float32.toUInt32(-Float32.inf) == UInt32.ofNat(0)) && (Float32.toUInt32(-7.9) == UInt32.ofNat(0)) && (UInt32.toFloat32(UInt32.ofNat(247)) == 247.0)\nconst f3Float32UInt64: Bool := (Float32.toUInt64(Float32.nan) == UInt64.ofNat(0)) && (Float32.toUInt64(Float32.inf) == UInt64.ofNat(18446744073709551615)) && (Float32.toUInt64(-Float32.inf) == UInt64.ofNat(0)) && (Float32.toUInt64(-7.9) == UInt64.ofNat(0)) && (UInt64.toFloat32(UInt64.ofNat(247)) == 247.0)\nconst f3Float32Int8: Bool := (Float32.toInt8(Float32.nan) == Int8.ofInt(0)) && (Float32.toInt8(Float32.inf) == Int8.ofInt(127)) && (Float32.toInt8(-Float32.inf) == Int8.ofInt(-128)) && (Float32.toInt8(-7.9) == Int8.ofInt(-7)) && (Int8.toFloat32(Int8.ofInt(-7)) == -7.0)\nconst f3Float32Int16: Bool := (Float32.toInt16(Float32.nan) == Int16.ofInt(0)) && (Float32.toInt16(Float32.inf) == Int16.ofInt(32767)) && (Float32.toInt16(-Float32.inf) == Int16.ofInt(-32768)) && (Float32.toInt16(-7.9) == Int16.ofInt(-7)) && (Int16.toFloat32(Int16.ofInt(-7)) == -7.0)\nconst f3Float32Int32: Bool := (Float32.toInt32(Float32.nan) == Int32.ofInt(0)) && (Float32.toInt32(Float32.inf) == Int32.ofInt(2147483647)) && (Float32.toInt32(-Float32.inf) == Int32.ofInt(-2147483648)) && (Float32.toInt32(-7.9) == Int32.ofInt(-7)) && (Int32.toFloat32(Int32.ofInt(-7)) == -7.0)\nconst f3Float32Int64: Bool := (Float32.toInt64(Float32.nan) == Int64.ofInt(0)) && (Float32.toInt64(Float32.inf) == Int64.ofInt(9223372036854775807)) && (Float32.toInt64(-Float32.inf) == Int64.ofInt(-9223372036854775808)) && (Float32.toInt64(-7.9) == Int64.ofInt(-7)) && (Int64.toFloat32(Int64.ofInt(-7)) == -7.0)\nfunction f3DefaultScientific(unit: Unit): Nat := { let value := -42.0\n UInt64.toNat(Float.toBits(value)) }\nconst f3DefaultScientificBits: Nat := f3DefaultScientific()\nconst f3LiteralMixed64: Nat := UInt64.toNat(Float.toBits(1.0 + 2))\nconst f3LiteralMixed32: Nat := UInt32.toNat(Float32.toBits(1.0 + 2))\nfunction f3Generic{A: Type}[OfScientific A](m: Nat, s: Bool, e: Nat): A := OfScientific.ofScientific(m, s, e)\nfunction f3Apply(fn: Nat -> Bool -> Nat -> Float): Float := fn(1, true, 1)\nconst f3Partial: Nat := UInt64.toNat(Float.toBits(f3Apply(Float.ofScientific)))\nconst f3Generic32: Nat := UInt32.toNat(Float32.toBits(f3Generic(1, true, 1)))\nconst f3WordDoubleRounding32: Nat := UInt32.toNat(Float32.toBits(UInt64.toFloat32(UInt64.ofNat(18014399583223809))))\nconst f3SignedDoubleRounding32: Nat := UInt32.toNat(Float32.toBits(Int64.toFloat32(Int64.ofInt(-18014399583223809))))\n"

private def scientificLiteralFixture : String :=
  "namespace ScientificLiterals\nuniverse u\nstructure Decimal where { mantissa: Nat\n negative: Bool\n exponent: Nat }\ninstance decimal: OfScientific Decimal where { ofScientific := fun (m: Nat) (s: Bool) (e: Nat) => Decimal.mk(m, s, e) }\nstructure High: Type 1 where { value: Decimal }\ninstance high: OfScientific High where { ofScientific := fun (m: Nat) (s: Bool) (e: Nat) => High.mk(Decimal.mk(m, s, e)) }\nfunction describe(value: Decimal): String := toString(value.mantissa) ++ \":\" ++ (if (value.negative) { \"-\" } else { \"+\" }) ++ toString(value.exponent)\nfunction generic{A: Type u}[OfScientific A](): A := 9.87\nfunction raw[zero: OfNat Nat 0](): Decimal := 0.0\nend ScientificLiterals\nconst scientificFraction: String := ScientificLiterals.describe(1.23)\nconst scientificExponent: String := ScientificLiterals.describe(1.2e3)\nconst scientificNegativeExponent: String := ScientificLiterals.describe(1.2E-3)\nconst scientificGrouped: String := ScientificLiterals.describe(1_2.3__4e+0_2)\nconst scientificBareDot: String := ScientificLiterals.describe(1.)\nconst scientificZeroExponent: String := ScientificLiterals.describe(1e0)\nconst scientificRawParameters: String := ScientificLiterals.describe(ScientificLiterals.raw((), zero := { ofNat := 42 }))\nconst scientificGeneric: String := ScientificLiterals.describe(ScientificLiterals.generic())\nconst scientificHigh: String := ScientificLiterals.describe(ScientificLiterals.High.value(ScientificLiterals.generic()))\n"

private def literalConstraintFixture : String :=
  "namespace LiteralConstraints\nuniverse u\nstructure Ticket where { value: Nat }\ninstance ticket{n: Nat}: OfNat(Ticket, n) where { ofNat := Ticket.mk(n) }\ninstance ticketAdd: Add Ticket where { add := fun (a: Ticket) (b: Ticket) => Ticket.mk(a.value + b.value + 1) }\nstructure High: Type 1 where { value: Nat }\ninstance highAdd: Add High where { add := fun (a: High) (b: High) => High.mk(a.value + b.value) }\ninstance hetero: HMul(Nat, Bool, Nat) where { hMul := fun (a: Nat) (b: Bool) => if (b) { a } else { 0 } }\nfunction add{A: Type u}[Add A](a: A, b: A): A := a + b\nfunction sub{A: Type u}[Sub A](a: A, b: A): A := a - b\nfunction mul{A: Type u}[Mul A](a: A, b: A): A := a * b\nfunction div{A: Type u}[Div A](a: A, b: A): A := a / b\nfunction mod{A: Type u}[Mod A](a: A, b: A): A := a % b\nfunction append{A: Type u}[Append A](a: A, b: A): A := a ++ b\nfunction withZero[zero: OfNat Nat 0](): Nat := 0\nfunction inferredNatural(unit: Unit): String := { let value := 17\n toString(value) }\nfunction inferredNegative(unit: Unit): String := { let value := -7\n toString(value) }\nend LiteralConstraints\nconst literalLeft: Nat := LiteralConstraints.Ticket.value(2 + LiteralConstraints.Ticket.mk(5))\nconst literalRight: Nat := LiteralConstraints.Ticket.value(LiteralConstraints.Ticket.mk(5) + 2)\nconst homogeneousAdd: Nat := LiteralConstraints.add(6, 5)\nconst homogeneousSub: Nat := LiteralConstraints.sub(9, 2)\nconst homogeneousMul: Nat := LiteralConstraints.mul(3, 6)\nconst homogeneousDiv: Nat := LiteralConstraints.div(10, 3)\nconst homogeneousMod: Nat := LiteralConstraints.mod(11, 3)\nconst homogeneousAppend: String := LiteralConstraints.append(\"a\", \"b\")\nconst literalLocalNat: Nat := LiteralConstraints.withZero((), zero := { ofNat := 42 })\nconst literalNatural: String := LiteralConstraints.inferredNatural()\nconst literalNegative: String := LiteralConstraints.inferredNegative()\nconst homogeneousHigh: Nat := LiteralConstraints.High.value(LiteralConstraints.add(LiteralConstraints.High.mk(5), LiteralConstraints.High.mk(7)))\nconst homogeneousFloat: Nat := UInt64.toNat(Float.toBits(LiteralConstraints.add(Float.ofBits(UInt64.ofNat(4607182418800017408)), Float.ofBits(UInt64.ofNat(4611686018427387904)))))\nconst heterogeneousMul: Nat := 9 * true\n"

private def defaultInstanceFixture : String :=
  "namespace DefaultChoice\nclass Choice(A: Type) where { pick: Nat }\nclass Missing(A: Type) where { marker: Nat }\ninstance ordinaryBool: Choice Bool where { pick := 37 }\n@[default_instance 600]\ninstance fallbackNat: Choice Nat where { pick := 31 }\n@[default_instance 700]\ndef unavailable[missing: Missing Bool]: Choice Bool := { pick := 47 }\nclass Preference(A: Type) where { pick: Nat }\ninstance ordinaryPreference: Preference Nat where { pick := 23 }\n@[default_instance 1000]\ndef preferBool: Preference Bool := { pick := 99 }\nclass Outer(A: Type) where { pick: Nat }\n@[default_instance 800]\ninstance outer{A: Type}[choice: Choice A]: Outer A where { pick := Choice.pick(A := A) }\nclass Tie(A: Type) where { pick: Nat }\n@[default_instance 200]\ninstance tieNat: Tie Nat where { pick := 1 }\n@[default_instance 200]\ninstance tieBool: Tie Bool where { pick := 2 }\nfunction choose{A: Type}[choice: Choice A](): Nat := Choice.pick(A := A)\nfunction competing{A: Type}[choice: Choice A][preference: Preference A](): Nat := Choice.pick(A := A)\nfunction nested{A: Type}[outer: Outer A](): Nat := Outer.pick(A := A)\nfunction tie{A: Type}[value: Tie A](): Nat := Tie.pick(A := A)\nfunction anchored{A: Type}[choice: Choice A](value: A): Nat := Choice.pick(A := A)\nfunction preference{A: Type}[preference: Preference A](): Nat := Preference.pick(A := A)\nuniverse u\nclass Poly(A: Type u) where { pick: Nat }\n@[default_instance]\ninstance poly{A: Type u}[inhabited: Inhabited A]: Poly A where { pick := 91 }\nend DefaultChoice\nconst defaultRollback: Nat := DefaultChoice.choose()\nconst defaultPriority: Nat := DefaultChoice.competing()\nconst defaultNested: Nat := DefaultChoice.nested()\nconst defaultTie: Nat := DefaultChoice.tie()\nconst defaultAnchor: Nat := DefaultChoice.anchored(true)\nconst defaultOnlyInferred: Nat := DefaultChoice.preference()\nconst defaultUniverse: Nat := DefaultChoice.Poly.pick(A := ProductLevels.High)\n"

private def arrayUniverseFixture : String :=
  "namespace ArrayLevels\nuniverse u v\nfunction mapAcross{A: Type u}{B: Type v}(f: A -> B, xs: Array A): Array B := Array.map(f, xs)\nfunction foldAcross{A: Type u}{B: Type v}(f: B -> A -> B, init: B, xs: Array A): B := Array.foldl(f, init, xs, 0, Array.size(xs))\ntheorem sizeModel{A: Type u}(xs: List A): Array.size(Array.mk(xs)) = List.length(xs) := by { rfl }\ntheorem listModel{A: Type u}(xs: List A): Array.toList(Array.mk(xs)) = xs := by { rfl }\nend ArrayLevels\nconst arrayHighValues: Array(ProductLevels.High) := Array.mk([ProductLevels.High.mk(5), ProductLevels.High.mk(7)])\nconst arrayHighMapDown: Nat := (ArrayLevels.mapAcross(ProductLevels.High.value, arrayHighValues))[1]!\nconst arrayHighMapUp: Nat := (ArrayLevels.mapAcross(ProductLevels.High.mk, #[11]))[0]!.value\nconst arrayHighFoldDown: Nat := ArrayLevels.foldAcross(fun acc => fun value => acc + value.value, 0, arrayHighValues)\nconst arrayHighFoldUp: Nat := (ArrayLevels.foldAcross(fun (acc: ProductLevels.High) => fun (value: Nat) => ProductLevels.High.mk(acc.value + value), ProductLevels.High.mk(0), #[13, 17])).value\nconst arrayHighDefault: Nat := Array.size((Inhabited.default : Array(ProductLevels.High)))\nconst arrayHighRepr: String := reprStr(arrayHighValues)\nconst arrayHighFormat: String := Std.Format.pretty(Std.format(arrayHighValues))\nconst arrayHighHash: Bool := hash(arrayHighValues) == mixHash(mixHash(UInt64.ofNat(7), hash(ProductLevels.High.mk(5))), hash(ProductLevels.High.mk(7)))\n"

private def hashFixture : String :=
  "namespace Hashing\nuniverse u\nstructure Box(A: Type u): Type u where { value: A } deriving Hashable\nstructure Checked where { value: Nat\n witness: value = value } deriving Hashable\ninductive Choice where { | none | value(payload: Nat) } deriving Hashable\ninductive Hidden where { | value{secret: Nat}(payload: Nat) } deriving Hashable\ninductive Void where { } deriving Hashable\nfunction generic{A: Type u}[inst: Hashable(A)](value: A): UInt64 := hash(value)\nfunction ignoreSort{A: Sort u}(value: A, answer: Nat): Nat := answer\nend Hashing\nfunction hashText(value: String): Nat := UInt64.toNat(hash(value))\nfunction hashNatural(value: Nat): Nat := UInt64.toNat(hash(value))\nfunction hashInteger(value: Int): Nat := UInt64.toNat(hash(value))\nfunction hashPair(first: Nat, second: Nat): Nat := UInt64.toNat(mixHash(UInt64.ofNat(first), UInt64.ofNat(second)))\nconst hashRecord: Nat := UInt64.toNat(hash(Hashing.Box.mk((23 : Nat))))\nconst hashProof: Nat := UInt64.toNat(hash(Hashing.Checked.mk(19, by { rfl })))\nconst hashCtor: Nat := UInt64.toNat(hash(Hashing.Choice.value(29)))\nconst hashNullary: Nat := UInt64.toNat(hash(Hashing.Choice.none))\nconst hashImplicit: Nat := UInt64.toNat(hash(Hashing.Hidden.value(secret := 31, payload := 37)))\nconst hashOption: Nat := UInt64.toNat(hash(Option.some((41 : Nat))))\nconst hashNone: Nat := UInt64.toNat(hash((Option.none : Option Nat)))\nconst hashList: Nat := UInt64.toNat(hash([1, 2, 3]))\nconst hashArray: Nat := UInt64.toNat(hash(Array.mk([1, 2, 3])))\nconst hashTuple: Nat := UInt64.toNat(hash(Prod.mk((43 : Nat), true)))\nconst hashProposition: Nat := UInt64.toNat(hash(True.intro))\nconst sortPropositionEntry: Nat := Hashing.ignoreSort(True.intro, 61)\nconst sortPropositionPartial: Nat := (Hashing.ignoreSort(True.intro))(67)\nfunction integerCases(value: Int): Nat := match Int.neg(value) with { | Int.ofNat n => Nat.add(n, 71) | Int.negSucc n => Nat.add(n, 73) }\nconst hashFin: Nat := UInt64.toNat(hash(Fin.mk(n := 4, val := 3, isLt := Nat.lt_succ_self(3))))\nconst hashPoly: Nat := UInt64.toNat(Hashing.generic((47 : Nat)))\nconst hashScalar: Nat := UInt64.toNat(hash((18446744073709551615 : UInt64)))\nconst hashNarrow: Nat := UInt64.toNat(hash((255 : UInt8)))\nconst hashChar: Nat := UInt64.toNat(hash(Char.ofNat(128512)))\nconst hashUnit: Nat := UInt64.toNat(hash(()))\nconst hash64Value: Nat := UInt64.toNat(hash64((53 : UInt64)))\n"

private def unsignedDisplayFixture : String :=
  "function unsignedDisplay(value: Nat): String := String.intercalate(\",\", [reprStr(UInt8.ofNat(value)), reprStr(UInt16.ofNat(value)), reprStr(UInt32.ofNat(value)), reprStr(UInt64.ofNat(value)), Std.Format.pretty(Std.format(UInt64.ofNat(value)))])\nconst unsignedDefaults: Nat := UInt8.toNat(Inhabited.default) + UInt16.toNat(Inhabited.default) + UInt32.toNat(Inhabited.default) + UInt64.toNat(Inhabited.default)\nconst unsignedListDisplay: String := Std.Format.pretty(repr([(1 : UInt8), (2 : UInt8), (3 : UInt8), (4 : UInt8)]), 8)\n"

-- Run source-level checks for the *entire* fixed-width method family before
-- the combined List/map/display fixture. This is a coherent unsigned-operation
-- API conformance gate, not a one-off workaround for an individual expression.
-- Native official-kernel acceptance is mandatory; no unknown reference,
-- implicit model fallback or silent dictionary replacement is permitted.
private def unsignedOperatorSourceCases : IO Unit := do
  -- Identify the earliest kernel boundary without weakening any acceptance:
  -- type declarations, pure Nat functions, UInt identities, constructors,
  -- conversions and lets all use their ordinary checked source pipeline.
  let baselines : Array (String × String) := #[
    ("natural identity", "function operation(a: Nat): Nat := a\n"),
    ("natural let", "function operation(a: Nat): Nat := { let value: Nat := a\n value }\n"),
    ("word identity", "function operation(value: UInt8): UInt8 := value\n"),
    ("word constructor", "function operation(value: Nat): UInt8 := UInt8.ofNat(value)\n"),
    ("word conversion", "function operation(value: UInt8): Nat := UInt8.toNat(value)\n"),
    ("word let", "function operation(n: Nat): UInt8 := { let value: UInt8 := UInt8.ofNat(n)\n value }\n"),
    ("word constant", "const operation: UInt8 := UInt8.ofNat(7)\n")]
  let baselineRequests : Array PsV7Native.Request :=
    baselines.map fun (_, source) => { source }
  let baselineResult ← PsV7Native.runBatch baselineRequests
  let baseline ← match baselineResult with
    | .error error => throw (IO.userError ("unsigned baseline batch: " ++ error.message))
    | .ok batch => pure batch
  let mut baselineFailures : Nat := 0
  for i in [:baselines.size] do
    let some (label, _) := baselines[i]? | throw (IO.userError "missing baseline label")
    let some answer := baseline.results[i]? | throw (IO.userError "missing baseline result")
    match answer with
    | .ok _ => IO.println ("PSCV0_UNSIGNED_BASELINE: PASS " ++ label)
    | .error problem =>
      baselineFailures := baselineFailures + 1
      IO.println ("PSCV0_UNSIGNED_BASELINE: " ++ label ++
        " refused at " ++ problem.phase ++ ": " ++ problem.message)
  let samples : Array (String × String × String) := #[
    -- Differentially isolate ordinary projection/conversion, direct checked
    -- method call, typeclass projection, and composed result transport.
    ("toNat", "Nat", "UInt8.toNat(x)"),
    ("directAdd", "UInt8", "UInt8.add(x, y)"),
    ("operatorAdd", "UInt8", "x + y"),
    ("directToNatAdd", "Nat", "UInt8.toNat(UInt8.add(x, y))"),
    ("add", "Nat", "UInt8.toNat(x + y)"),
    ("sub", "Nat", "UInt8.toNat(x - y)"),
    ("mul", "Nat", "UInt8.toNat(x * y)"),
    ("div", "Nat", "UInt8.toNat(x / y)"),
    ("mod", "Nat", "UInt8.toNat(x % y)"),
    ("neg", "Nat", "UInt8.toNat(-x)"),
    ("complement", "Nat", "UInt8.toNat(UInt8.complement(x))"),
    ("and", "Nat", "UInt8.toNat(UInt8.land(x, y))"),
    ("or", "Nat", "UInt8.toNat(UInt8.lor(x, y))"),
    ("xor", "Nat", "UInt8.toNat(UInt8.xor(x, y))"),
    ("shiftLeft", "Nat", "UInt8.toNat(UInt8.shiftLeft(x, y))"),
    ("shiftRight", "Nat", "UInt8.toNat(UInt8.shiftRight(x, y))"),
    ("map", "List String", "List.map(Nat.repr, [UInt8.toNat(x + y)])"),
    ("display", "String",
      "String.intercalate(\",\", List.map(Nat.repr, [UInt8.toNat(x + y)]))")]
  let requests : Array PsV7Native.Request := samples.map fun (_, resultType, expression) =>
    { source := "function operation(a: Nat, b: Nat): " ++ resultType ++
        " := { let x: UInt8 := UInt8.ofNat(a)\n let y: UInt8 := UInt8.ofNat(b)\n " ++
        expression ++ " }\n" }
  let result ← PsV7Native.runBatch requests
  let batch ← match result with
    | .error error => throw (IO.userError ("unsigned source matrix: " ++ error.message))
    | .ok batch => pure batch
  let mut failures : List String := []
  for i in [:samples.size] do
    let some (label, _, _) := samples[i]? | throw (IO.userError "missing unsigned label")
    let some answer := batch.results[i]? | throw (IO.userError "missing unsigned result")
    match answer with
    | .ok _ => IO.println ("PSCV0_UNSIGNED_SOURCE: PASS " ++ label)
    | .error problem =>
      let message := "PSCV0_UNSIGNED_SOURCE: " ++ label ++
        " refused at " ++ problem.phase ++ ": " ++ problem.message
      IO.println message
      failures := message :: failures
  unless failures.isEmpty && baselineFailures == 0 do
    throw (IO.userError ("PSCV0_UNSIGNED_SOURCE: " ++
      toString failures.length ++ " checked operation cases and " ++
      toString baselineFailures ++ " baseline cases failed"))

-- Native kernel/Lean-4.35.0 correspondence for the general String APIs.
-- Both definitions are total List traversals; no host join/intercalate
-- shortcut or parser-only special case may satisfy these acceptance checks.
private def stringJoinIntercalateCases : IO Unit := do
  let samples : Array (String × String) := #[
    ("join empty", "const joined: String := String.join(([] : List String))\n"),
    ("join unicode", "const joined: String := String.join([\"λ\", \"😀\"])\n"),
    ("intercalate empty",
      "const joined: String := String.intercalate(\",\", ([] : List String))\n"),
    ("intercalate singleton",
      "const joined: String := String.intercalate(\",\", [\"x\"])\n"),
    ("intercalate empty element",
      "const joined: String := String.intercalate(\",\", [\"a\", \"\", \"b\"])\n"),
    ("intercalate unicode",
      "const joined: String := String.intercalate(\"🌍\", [\"λ\", \"😀\"])\n"),
    ("intercalate mapped values",
      "const joined: String := String.intercalate(\",\", List.map(Nat.repr, [2, 3]))\n")]
  let requests : Array PsV7Native.Request :=
    samples.map fun (_, source) => { source }
  let result ← PsV7Native.runBatch requests
  let batch ← match result with
    | .ok value => pure value
    | .error error => throw (IO.userError ("String API batch: " ++ error.message))
  let mut failures := 0
  for i in [:samples.size] do
    let some (label, _) := samples[i]? | throw (IO.userError "missing String API label")
    let some answer := batch.results[i]? | throw (IO.userError "missing String API result")
    match answer with
    | .ok _ => IO.println ("PSCV0_STRING_API: PASS " ++ label)
    | .error failure =>
      failures := failures + 1
      IO.println ("PSCV0_STRING_API: " ++ label ++
        " refused at " ++ failure.phase ++ ": " ++ failure.message)
  if failures != 0 then
    throw (IO.userError (toString failures ++ " String API checks failed"))

-- Lean 4.35.0 Init/Prelude.lean HAdd: an output-param class with an
-- ordinary method and local instance semantics. Check the entire resolution
-- family so a polymorphic class error cannot be hidden by a Nat/UInt shortcut.
private def hAddPolymorphicCases : IO Unit := do
  let cases : Array (String × String) := #[
    ("generic identity",
      "function generic{A: Type}(left: A, right: A): A := left\n"),
    ("generic instance unused",
      "function generic{A: Type}[operation: HAdd(A, A, A)](left: A, right: A): A := left\n"),
    ("generic operator",
      "function generic{A: Type}[operation: HAdd(A, A, A)](left: A, right: A): A := left + right\n"),
    ("generic direct projection",
      "function generic{A: Type}[operation: HAdd(A, A, A)](left: A, right: A): A := HAdd.hAdd(left, right, self := operation)\n"),
    ("generic structure method",
      "function generic{A: Type}[operation: HAdd(A, A, A)](left: A, right: A): A := operation.hAdd(left, right)\n"),
    ("Nat local instance",
      "function generic[operation: HAdd(Nat, Nat, Nat)](left: Nat, right: Nat): Nat := left + right\n")]
  let requests : Array PsV7Native.Request := cases.map fun (_, source) => { source }
  let result ← PsV7Native.runBatch requests
  let batch ← match result with
    | .error problem => throw (IO.userError ("HAdd local/generic batch: " ++ problem.message))
    | .ok result => pure result
  let mut failures := 0
  for i in [:cases.size] do
    let some (label, _) := cases[i]? | throw (IO.userError "missing HAdd label")
    let some result := batch.results[i]? | throw (IO.userError "missing HAdd result")
    match result with
    | .ok _ => IO.println ("PSCV0_HADD_GENERIC: PASS " ++ label)
    | .error problem =>
      failures := failures + 1
      IO.println ("PSCV0_HADD_GENERIC: " ++ label ++
        " refused at " ++ problem.phase ++ ": " ++ problem.message)
  unless failures == 0 do
    throw (IO.userError (toString failures ++ " HAdd generic source cases failed"))

-- APP-03 follows pinned Lean 4.35.0's `Unit := PUnit` definition,
-- not a spelling-only check. Test the positive reduction and negative
-- explicit-argument families without special-casing Coercion.boxed.
private def unitEmptyCallCases : IO Unit := do
  let good : Array (String × String) := #[
    ("Unit empty call",
      "function run(value: Unit): Nat := 3\nconst result: Nat := run()\n"),
    ("PUnit empty call",
      "function run(value: (PUnit : Type)): Nat := 5\nconst result: Nat := run()\n"),
    ("explicit Unit call",
      "function run(value: Unit): Nat := 7\nconst result: Nat := run(Unit.unit)\n"),
    ("parenthesized Unit callable",
      "function run(value: Unit): Nat := 11\nconst result: Nat := (run)()\n"),
    ("namespace Unit callable",
      "namespace Coercion\nfunction boxed(unit: Unit): Nat := 877\nend Coercion\nconst result: Nat := Coercion.boxed()\n")]
  let bad : Array (String × String) := #[
    ("Nat needs argument",
      "function run(value: Nat): Nat := value\nconst result: Nat := run()\n"),
    ("required second Nat",
      "function run(value: Unit, n: Nat): Nat := n\nconst result: Nat := run()\n"),
    ("required second Unit",
      "function run(a: Unit, b: Unit): Nat := 0\nconst result: Nat := run()\n"),
    ("noncallable Nat",
      "const value: Nat := 0\nconst result: Nat := value()\n")]
  let requests : Array PsV7Native.Request := (good ++ bad).map fun (_, source) => { source }
  let result ← PsV7Native.runBatch requests
  let batch ← match result with
    | .ok batch => pure batch
    | .error problem => throw (IO.userError ("APP-03 batch: " ++ problem.message))
  let mut failures := 0
  for i in [:good.size] do
    let some (label, _) := good[i]? | throw (IO.userError "missing APP-03 positive label")
    let some response := batch.results[i]? | throw (IO.userError "missing APP-03 result")
    match response with
    | .ok _ => IO.println ("PSCV0_UNIT_EMPTY_CALL: PASS " ++ label)
    | .error failure =>
      failures := failures + 1
      IO.println ("PSCV0_UNIT_EMPTY_CALL: " ++ label ++
        " refused at " ++ failure.phase ++ ": " ++ failure.message)
  for i in [:bad.size] do
    let some (label, _) := bad[i]? | throw (IO.userError "missing APP-03 negative label")
    let some response := batch.results[good.size + i]? | throw (IO.userError "missing APP-03 refusal")
    match response with
    | .ok _ =>
      failures := failures + 1
      IO.println ("PSCV0_UNIT_EMPTY_CALL: incorrectly accepted " ++ label)
    | .error _ => IO.println ("PSCV0_UNIT_EMPTY_CALL: PASS negative " ++ label)
  if failures != 0 then
    throw (IO.userError (toString failures ++ " APP-03 acceptance/refusal cases failed"))

private def wordFixture : String :=
  "function wordOperations8(a: Nat, b: Nat): String := { let x: UInt8 := UInt8.ofNat(a)\n let y: UInt8 := UInt8.ofNat(b)\n String.intercalate(\",\", List.map(Nat.repr, [UInt8.toNat(x + y), UInt8.toNat(x - y), UInt8.toNat(x * y), UInt8.toNat(x / y), UInt8.toNat(x % y), UInt8.toNat(-x), UInt8.toNat(UInt8.complement(x)), UInt8.toNat(UInt8.land(x, y)), UInt8.toNat(UInt8.lor(x, y)), UInt8.toNat(UInt8.xor(x, y)), UInt8.toNat(UInt8.shiftLeft(x, y)), UInt8.toNat(UInt8.shiftRight(x, y))])) }\nfunction wordOperations16(a: Nat, b: Nat): String := { let x: UInt16 := UInt16.ofNat(a)\n let y: UInt16 := UInt16.ofNat(b)\n String.intercalate(\",\", List.map(Nat.repr, [UInt16.toNat(x + y), UInt16.toNat(x - y), UInt16.toNat(x * y), UInt16.toNat(x / y), UInt16.toNat(x % y), UInt16.toNat(-x), UInt16.toNat(UInt16.complement(x)), UInt16.toNat(UInt16.land(x, y)), UInt16.toNat(UInt16.lor(x, y)), UInt16.toNat(UInt16.xor(x, y)), UInt16.toNat(UInt16.shiftLeft(x, y)), UInt16.toNat(UInt16.shiftRight(x, y))])) }\nfunction wordOperations32(a: Nat, b: Nat): String := { let x: UInt32 := UInt32.ofNat(a)\n let y: UInt32 := UInt32.ofNat(b)\n String.intercalate(\",\", List.map(Nat.repr, [UInt32.toNat(x + y), UInt32.toNat(x - y), UInt32.toNat(x * y), UInt32.toNat(x / y), UInt32.toNat(x % y), UInt32.toNat(-x), UInt32.toNat(UInt32.complement(x)), UInt32.toNat(UInt32.land(x, y)), UInt32.toNat(UInt32.lor(x, y)), UInt32.toNat(UInt32.xor(x, y)), UInt32.toNat(UInt32.shiftLeft(x, y)), UInt32.toNat(UInt32.shiftRight(x, y))])) }\nfunction wordOperations64(a: Nat, b: Nat): String := { let x: UInt64 := UInt64.ofNat(a)\n let y: UInt64 := UInt64.ofNat(b)\n String.intercalate(\",\", List.map(Nat.repr, [UInt64.toNat(x + y), UInt64.toNat(x - y), UInt64.toNat(x * y), UInt64.toNat(x / y), UInt64.toNat(x % y), UInt64.toNat(-x), UInt64.toNat(UInt64.complement(x)), UInt64.toNat(UInt64.land(x, y)), UInt64.toNat(UInt64.lor(x, y)), UInt64.toNat(UInt64.xor(x, y)), UInt64.toNat(UInt64.shiftLeft(x, y)), UInt64.toNat(UInt64.shiftRight(x, y))])) }\nfunction wordApply(operation: UInt64 -> UInt64 -> UInt64, left: UInt64, right: UInt64): Nat := UInt64.toNat(operation(left)(right))\nconst wordHigherOrder: Nat := wordApply(UInt64.shiftLeft, (3 : UInt64), (65 : UInt64))\nfunction wordGeneric{A: Type}[operation: HAdd(A, A, A)](left: A, right: A): A := left + right\nconst wordGenericWrap: Nat := UInt8.toNat(wordGeneric((255 : UInt8), (2 : UInt8)))\ntheorem wordModel: UInt8.toNat(UInt8.add((255 : UInt8), (2 : UInt8))) = 1 := by { rfl }\n"

-- Shared signed source family: every operation enters ordinary source
-- elaboration, official kernel checking and typed target-neutral erasure.
-- The native independent oracle below checks real pinned Lean 4.35.0 values.
private def signedFixture : String :=
  "function signed8Add(a: Nat, b: Nat): Int8 := Int8.add(Int8.ofNat(a), Int8.ofNat(b))\nfunction signed8Div(a: Nat, b: Nat): Int8 := Int8.div(Int8.ofNat(a), Int8.ofNat(b))\nfunction signed8Mod(a: Nat, b: Nat): Int8 := Int8.mod(Int8.ofNat(a), Int8.ofNat(b))\nfunction signed8Neg(a: Nat): Int8 := Int8.neg(Int8.ofNat(a))\nfunction signed8Complement(a: Nat): Int8 := Int8.complement(Int8.ofNat(a))\nfunction signed8Mul(a: Nat, b: Nat): Int8 := Int8.mul(Int8.ofNat(a), Int8.ofNat(b))\nfunction signed16Sub(a: Nat, b: Nat): Int16 := Int16.sub(Int16.ofNat(a), Int16.ofNat(b))\nfunction signed16Mul(a: Nat, b: Nat): Int16 := Int16.mul(Int16.ofNat(a), Int16.ofNat(b))\nfunction signed16Add(a: Nat, b: Nat): Int16 := Int16.add(Int16.ofNat(a), Int16.ofNat(b))\nfunction signed32Div(a: Nat, b: Nat): Int32 := Int32.div(Int32.ofNat(a), Int32.ofNat(b))\nfunction signed32Mod(a: Nat, b: Nat): Int32 := Int32.mod(Int32.ofNat(a), Int32.ofNat(b))\nfunction signed32Xor(a: Nat, b: Nat): Int32 := Int32.xor(Int32.ofNat(a), Int32.ofNat(b))\nfunction signed64Add(a: Nat, b: Nat): Int64 := Int64.add(Int64.ofNat(a), Int64.ofNat(b))\nfunction signed64Div(a: Nat, b: Nat): Int64 := Int64.div(Int64.ofNat(a), Int64.ofNat(b))\nfunction signed64Mod(a: Nat, b: Nat): Int64 := Int64.mod(Int64.ofNat(a), Int64.ofNat(b))\nfunction signed64Complement(a: Nat): Int64 := Int64.complement(Int64.ofNat(a))\nfunction signed64Mul(a: Nat, b: Nat): Int64 := Int64.mul(Int64.ofNat(a), Int64.ofNat(b))\n"

-- Generic operator and dictionary admission exercises exactly the same
-- class graph used by Nat and UInt, with checked SInt methods behind it.
private def signedDictionaryFixture : String :=
  "const signedLiteral8: Int8 := (255 : Int8)\nfunction signedOperator8(a: Int8, b: Int8): Int8 := a + b\nfunction signedOperator16(a: Int16, b: Int16): Int16 := a * b\nfunction signedOperator32(a: Int32, b: Int32): Int32 := a / b\nconst signedNegative64: Int64 := -(1 : Int64)\nfunction signedEquality8(a: Int8, b: Int8): Bool := a == b\nconst signedDefault8: Int8 := Inhabited.default\n"

-- Four checked, kernel-certificated two's-complement conversions from
-- the same pinned Nat-bit carriers as the native mathematical model.
private def signedConversionFixture : String :=
  "function signedToInt8(value: Nat): Int := Int8.toInt(Int8.ofNat(value))\nfunction signedToInt16(value: Nat): Int := Int16.toInt(Int16.ofNat(value))\nfunction signedToInt32(value: Nat): Int := Int32.toInt(Int32.ofNat(value))\nfunction signedToInt64(value: Nat): Int := Int64.toInt(Int64.ofNat(value))\nfunction signedFromInt8(value: Int): Int8 := Int8.ofInt(value)\nfunction signedFromInt16(value: Int): Int16 := Int16.ofInt(value)\nfunction signedFromInt32(value: Int): Int32 := Int32.ofInt(value)\nfunction signedFromInt64(value: Int): Int64 := Int64.ofInt(value)\n"

private def signedShiftFixture : String :=
  "function signed8ShiftLeft(a: Int8, b: Int8): Int8 := Int8.shiftLeft(a, b)\nfunction signed8ShiftRight(a: Int8, b: Int8): Int8 := Int8.shiftRight(a, b)\nfunction signed16ShiftLeft(a: Int16, b: Int16): Int16 := Int16.shiftLeft(a, b)\nfunction signed16ShiftRight(a: Int16, b: Int16): Int16 := Int16.shiftRight(a, b)\nfunction signed32ShiftLeft(a: Int32, b: Int32): Int32 := Int32.shiftLeft(a, b)\nfunction signed32ShiftRight(a: Int32, b: Int32): Int32 := Int32.shiftRight(a, b)\nfunction signed64ShiftLeft(a: Int64, b: Int64): Int64 := Int64.shiftLeft(a, b)\nfunction signed64ShiftRight(a: Int64, b: Int64): Int64 := Int64.shiftRight(a, b)\n"

-- Native Lean defines these four clamps by Int.toNat after IntN.toInt.
private def signedClampFixture : String :=
  "function signedClamp8(value: Int8): Nat := Int8.toNatClampNeg(value)\nfunction signedClamp16(value: Int16): Nat := Int16.toNatClampNeg(value)\nfunction signedClamp32(value: Int32): Nat := Int32.toNatClampNeg(value)\nfunction signedClamp64(value: Int64): Nat := Int64.toNatClampNeg(value)\n"

-- Checked signed absolute values use the pinned bit-pattern sign model.
private def signedAbsFixture : String :=
  "function signedAbs8(value: Int8): Int8 := Int8.abs(value)\nfunction signedAbs16(value: Int16): Int16 := Int16.abs(value)\nfunction signedAbs32(value: Int32): Int32 := Int32.abs(value)\nfunction signedAbs64(value: Int64): Int64 := Int64.abs(value)\n"

-- Signed order follows the native IntN/BitVec relations and decisions.
private def signedOrderFixture : String :=
  "function signedLT8(a: Int8, b: Int8): Bool := Decidable.decide(self := Int8.decLt(a, b))\nfunction signedLE8(a: Int8, b: Int8): Bool := Decidable.decide(self := Int8.decLe(a, b))\nfunction signedLT16(a: Int16, b: Int16): Bool := Decidable.decide(self := Int16.decLt(a, b))\nfunction signedLE16(a: Int16, b: Int16): Bool := Decidable.decide(self := Int16.decLe(a, b))\nfunction signedLT32(a: Int32, b: Int32): Bool := Decidable.decide(self := Int32.decLt(a, b))\nfunction signedLE32(a: Int32, b: Int32): Bool := Decidable.decide(self := Int32.decLe(a, b))\nfunction signedLT64(a: Int64, b: Int64): Bool := Decidable.decide(self := Int64.decLt(a, b))\nfunction signedLE64(a: Int64, b: Int64): Bool := Decidable.decide(self := Int64.decLe(a, b))\n"

-- Pinned SInt size/extrema and Nat-recursive wrapping power.
private def signedNumericFixture : String :=
  "function signedPow8(value: Int8, exponent: Nat): Int8 := Int8.pow(value, exponent)\nfunction signedPow16(value: Int16, exponent: Nat): Int16 := Int16.pow(value, exponent)\nfunction signedPow32(value: Int32, exponent: Nat): Int32 := Int32.pow(value, exponent)\nfunction signedPow64(value: Int64, exponent: Nat): Int64 := Int64.pow(value, exponent)\nconst signedSize8: Nat := Int8.size\nconst signedSize16: Nat := Int16.size\nconst signedSize32: Nat := Int32.size\nconst signedSize64: Nat := Int64.size\nconst signedMin8: Int8 := Int8.minValue\nconst signedMin16: Int16 := Int16.minValue\nconst signedMin32: Int32 := Int32.minValue\nconst signedMin64: Int64 := Int64.minValue\nconst signedMax8: Int8 := Int8.maxValue\nconst signedMax16: Int16 := Int16.maxValue\nconst signedMax32: Int32 := Int32.maxValue\nconst signedMax64: Int64 := Int64.maxValue\n"

-- Checked Bool recursor reproduces native Bool-to-fixed-width conversions.
private def boolWordFixture : String :=
  "function boolWordUInt8(value: Bool): UInt8 := Bool.toUInt8(value)\nfunction boolWordUInt16(value: Bool): UInt16 := Bool.toUInt16(value)\nfunction boolWordUInt32(value: Bool): UInt32 := Bool.toUInt32(value)\nfunction boolWordUInt64(value: Bool): UInt64 := Bool.toUInt64(value)\nfunction boolWordInt8(value: Bool): Int8 := Bool.toInt8(value)\nfunction boolWordInt16(value: Bool): Int16 := Bool.toInt16(value)\nfunction boolWordInt32(value: Bool): Int32 := Bool.toInt32(value)\nfunction boolWordInt64(value: Bool): Int64 := Bool.toInt64(value)\n"

-- Pinned Lean 4.35.0 UInt8/16/32/64 unsigned relation decisions.
private def unsignedOrderFixture : String :=
  "function unsignedLT8(a: UInt8, b: UInt8): Bool := Decidable.decide(self := UInt8.decLt(a, b))\nfunction unsignedLE8(a: UInt8, b: UInt8): Bool := Decidable.decide(self := UInt8.decLe(a, b))\nfunction unsignedLT16(a: UInt16, b: UInt16): Bool := Decidable.decide(self := UInt16.decLt(a, b))\nfunction unsignedLE16(a: UInt16, b: UInt16): Bool := Decidable.decide(self := UInt16.decLe(a, b))\nfunction unsignedLT32(a: UInt32, b: UInt32): Bool := Decidable.decide(self := UInt32.decLt(a, b))\nfunction unsignedLE32(a: UInt32, b: UInt32): Bool := Decidable.decide(self := UInt32.decLe(a, b))\nfunction unsignedLT64(a: UInt64, b: UInt64): Bool := Decidable.decide(self := UInt64.decLt(a, b))\nfunction unsignedLE64(a: UInt64, b: UInt64): Bool := Decidable.decide(self := UInt64.decLe(a, b))\n"

-- Pinned Lean 4.35.0 UIntN.pow is Nat-recursive wrapping multiplication.
private def unsignedPowerFixture : String :=
  "function unsignedPow8(value: UInt8, exponent: Nat): UInt8 := UInt8.pow(value, exponent)\nfunction unsignedPow16(value: UInt16, exponent: Nat): UInt16 := UInt16.pow(value, exponent)\nfunction unsignedPow32(value: UInt32, exponent: Nat): UInt32 := UInt32.pow(value, exponent)\nfunction unsignedPow64(value: UInt64, exponent: Nat): UInt64 := UInt64.pow(value, exponent)\n"

-- UIntN.ofInt wraps arbitrary precision Int through the checked Int.rec path.
private def unsignedOfIntFixture : String :=
  "function unsignedFromInt8(value: Int): UInt8 := UInt8.ofInt(value)\nfunction unsignedFromInt16(value: Int): UInt16 := UInt16.ofInt(value)\nfunction unsignedFromInt32(value: Int): UInt32 := UInt32.ofInt(value)\nfunction unsignedFromInt64(value: Int): UInt64 := UInt64.ofInt(value)\n"

-- Lean 4.35.0 UInt.ofNatClamp saturates instead of wrapping.
private def unsignedClampFixture : String :=
  "function unsignedClamp8(value: Nat): UInt8 := UInt8.ofNatClamp(value)\nfunction unsignedTruncate8(value: Nat): UInt8 := UInt8.ofNatTruncate(value)\nfunction unsignedClamp16(value: Nat): UInt16 := UInt16.ofNatClamp(value)\nfunction unsignedTruncate16(value: Nat): UInt16 := UInt16.ofNatTruncate(value)\nfunction unsignedClamp32(value: Nat): UInt32 := UInt32.ofNatClamp(value)\nfunction unsignedTruncate32(value: Nat): UInt32 := UInt32.ofNatTruncate(value)\nfunction unsignedClamp64(value: Nat): UInt64 := UInt64.ofNatClamp(value)\nfunction unsignedTruncate64(value: Nat): UInt64 := UInt64.ofNatTruncate(value)\n"

-- Genuine two-constructor, two-universe Sum, not a JavaScript union.
private def standardSumFixture : String :=
  "function sumScore(value: Sum(Nat, Nat)): Nat := match value with { | Sum.inl left => left | Sum.inr right => right + 100 }\nconst sumLeftScore: Nat := sumScore((Sum.inl(17) : Sum(Nat, Nat)))\nconst sumRightScore: Nat := sumScore((Sum.inr(23) : Sum(Nat, Nat)))\n"

-- Lean 4.35.0 packed-byte logical structure over Array UInt8.
-- Checked UInt bit-canonicalization helpers. These are NOT Float values:
-- the independent native Float.ofBits oracle supplies the expected semantics.
private def standardFloatCanonicalFixture : String :=
  "function canonical64Bits(value: Nat): Nat := UInt64.toNat(PsStandard.canonicalFloat64Bits(UInt64.ofNat(value)))\nfunction canonical32Bits(value: Nat): Nat := UInt32.toNat(PsStandard.canonicalFloat32Bits(UInt32.ofNat(value)))\nfunction isNaN64Bits(value: Nat): Bool := PsStandard.isNaNFloat64Bits(UInt64.ofNat(value))\nfunction isNaN32Bits(value: Nat): Bool := PsStandard.isNaNFloat32Bits(UInt32.ofNat(value))\nfunction isInf64Bits(value: Nat): Bool := PsStandard.isInfFloat64Bits(UInt64.ofNat(value))\nfunction isFinite64Bits(value: Nat): Bool := PsStandard.isFiniteFloat64Bits(UInt64.ofNat(value))\nfunction isInf32Bits(value: Nat): Bool := PsStandard.isInfFloat32Bits(UInt32.ofNat(value))\nfunction isFinite32Bits(value: Nat): Bool := PsStandard.isFiniteFloat32Bits(UInt32.ofNat(value))\n"

-- IEEE Boolean equality is distinct from canonical logical equality. These
-- checked bit models do not claim to instantiate BEq/DecidableEq for Float.
private def standardFloatBitEqualityFixture : String :=
  "function ieeeEq64Bits(left: Nat, right: Nat): Bool := PsStandard.beqFloat64Bits(UInt64.ofNat(left), UInt64.ofNat(right))\nfunction logicalEq64Bits(left: Nat, right: Nat): Bool := PsStandard.logicalEqFloat64Bits(UInt64.ofNat(left), UInt64.ofNat(right))\nfunction ieeeEq32Bits(left: Nat, right: Nat): Bool := PsStandard.beqFloat32Bits(UInt32.ofNat(left), UInt32.ofNat(right))\nfunction logicalEq32Bits(left: Nat, right: Nat): Bool := PsStandard.logicalEqFloat32Bits(UInt32.ofNat(left), UInt32.ofNat(right))\n"

private def standardByteArrayFixture : String :=
  "const byteEmptyLength: Nat := ByteArray.size(ByteArray.empty)\nfunction byteRoundtrip(value: UInt8): UInt8 := Array.getD(ByteArray.data(ByteArray.push(ByteArray.empty, value)), 0, (0 : UInt8))\nfunction byteTwoLength(left: UInt8, right: UInt8): Nat := ByteArray.size(ByteArray.push(ByteArray.push(ByteArray.empty, left), right))\n"

-- Pinned Lean 4.35.0 ByteArray read/write, BEq and defaults.
private def byteArrayCollectionFixture : String :=
  "function byteReadSaved(value: UInt8): UInt8 := ByteArray.get!(ByteArray.push(ByteArray.empty, value), 0)\nfunction byteReplaceSaved(value: UInt8): UInt8 := ByteArray.get!(ByteArray.set!(ByteArray.push(ByteArray.empty, (3 : UInt8)), 0, value), 0)\nfunction byteReplaceOutside(value: UInt8): UInt8 := ByteArray.get!(ByteArray.set!(ByteArray.push(ByteArray.empty, value), 19, (0 : UInt8)), 0)\nconst byteEmptyIsEmpty: Bool := ByteArray.isEmpty(ByteArray.empty)\nconst byteNonEmptyIsEmpty: Bool := ByteArray.isEmpty(ByteArray.push(ByteArray.empty, (3 : UInt8)))\nconst byteDefaultLength: Nat := ByteArray.size((Inhabited.default : ByteArray))\nconst byteEqualSame: Bool := ByteArray.beq(ByteArray.push(ByteArray.empty, (3 : UInt8)), ByteArray.push(ByteArray.empty, (3 : UInt8)))\nconst byteEqualDifferent: Bool := ByteArray.beq(ByteArray.push(ByteArray.empty, (3 : UInt8)), ByteArray.push(ByteArray.empty, (4 : UInt8)))\nfunction byteCheckedRead(value: UInt8): UInt8 := ByteArray.get(ByteArray.push(ByteArray.empty, value), 0, PsStandard.natBleReflects(1, 1))\nfunction byteCheckedWrite(value: UInt8): UInt8 := ByteArray.get!(ByteArray.set(ByteArray.push(ByteArray.empty, (3 : UInt8)), 0, value, PsStandard.natBleReflects(1, 1)), 0)\nconst byteOptionalSome: UInt8 := Option.getD((ByteArray.push(ByteArray.empty, (6 : UInt8)))[0]?, (0 : UInt8))\nconst byteOptionalNone: Bool := Option.isNone((ByteArray.empty)[0]?)\nfunction byteListLength(value: UInt8): Nat := List.length(ByteArray.toList(ByteArray.push(ByteArray.empty, value)))\nfunction byteListFirst(value: UInt8): UInt8 := Option.getD((ByteArray.toList(ByteArray.push(ByteArray.empty, value)))[0]?, (0 : UInt8))\nfunction byteFromListHead(value: UInt8): UInt8 := ByteArray.get!(List.toByteArray([value]), 0)\nfunction byteFromListLength(value: UInt8): Nat := ByteArray.size(List.toByteArray([(1 : UInt8), value]))\nfunction byteSliceFirst(value: UInt8): UInt8 := ByteArray.get!(ByteArray.extract(List.toByteArray([(9 : UInt8), value, (5 : UInt8)]), 1, 3), 0)\nfunction byteSliceClamped(value: UInt8): Nat := ByteArray.size(ByteArray.extract(List.toByteArray([value, (3 : UInt8)]), 1, 999))\nconst byteSliceReversed: Nat := ByteArray.size(ByteArray.extract(List.toByteArray([(1 : UInt8), (2 : UInt8)]), 2, 1))\nfunction byteAppendLength(value: UInt8): Nat := ByteArray.size(ByteArray.append(List.toByteArray([(1 : UInt8)]), List.toByteArray([value, (2 : UInt8)])))\nfunction byteAppendMiddle(value: UInt8): UInt8 := ByteArray.get!(ByteArray.append(List.toByteArray([(1 : UInt8)]), List.toByteArray([value, (2 : UInt8)])), 1)\nconst byteAppendEmpty: Nat := ByteArray.size(ByteArray.append(ByteArray.empty, ByteArray.empty))\nfunction byteCopyDefault(value: UInt8): UInt8 := ByteArray.get!(ByteArray.copySlice(List.toByteArray([value, (8 : UInt8)]), 0, List.toByteArray([(1 : UInt8), (2 : UInt8), (3 : UInt8)]), 1, 2), 1)\nfunction byteCopyExactFalse(value: UInt8): UInt8 := ByteArray.get!(ByteArray.copySlice(List.toByteArray([value]), 0, List.toByteArray([(1 : UInt8), (2 : UInt8), (3 : UInt8)]), 1, 1, false), 2)\nfunction byteCopyExtend(value: UInt8): Nat := ByteArray.size(ByteArray.copySlice(List.toByteArray([value, (5 : UInt8)]), 0, List.toByteArray([(3 : UInt8)]), 1, 2, true))\nconst byteCopyOutside: Nat := ByteArray.size(ByteArray.copySlice(ByteArray.empty, 20, List.toByteArray([(2 : UInt8)]), 0, 5))\nfunction byteGetOutside(index: Nat): UInt8 := ByteArray.get!(ByteArray.empty, index)\n"

private def unsignedFixture : String :=
  "function unsigned8(value: Nat): Nat := UInt8.toNat(UInt8.ofNat(value))\nfunction unsigned16(value: Nat): Nat := UInt16.toNat(UInt16.ofNat(value))\nfunction unsigned32(value: Nat): Nat := UInt32.toNat(UInt32.ofNat(value))\nfunction unsigned64(value: Nat): Nat := UInt64.toNat(UInt64.ofNat(value))\nconst unsignedLiteral: Nat := UInt64.toNat((18446744073709551619 : UInt64))\nfunction unsignedIdentity{A: Type}(value: A): A := value\nfunction unsignedGeneric(value: Nat): Nat := UInt64.toNat(unsignedIdentity(UInt64.ofNat(value)))\nfunction unsignedViaBits(value: Nat): Nat := BitVec.toNat(UInt32.toBitVec(UInt32.ofNat(value)))\nfunction unsignedViaFin(value: Nat): Nat := Fin.val(UInt16.toFin(UInt16.ofNat(value)))\nfunction unsignedRebuild(value: Nat): Nat := UInt8.toNat(UInt8.ofBitVec(UInt8.toBitVec(UInt8.ofNat(value))))\nfunction unsignedMatch(value: Nat): Nat := match UInt64.ofNat(value) with { | UInt64.ofBitVec bits => BitVec.toNat(bits) }\nfunction unsignedUse(convert: Nat -> UInt64, value: Nat): Nat := UInt64.toNat(convert(value))\nfunction unsignedHigher(value: Nat): Nat := unsignedUse(UInt64.ofNat, value)\nfunction bitvecConvert(width: Nat, value: Nat): Nat := BitVec.toNat(BitVec.ofNat(width, value))\nfunction naturalPower(base: Nat, exponent: Nat): Nat := Nat.pow(base, exponent)\ntheorem unsignedBound(value: UInt64): Nat.lt(UInt64.toNat(value), UInt64.size) := Fin.isLt(UInt64.toFin(value))\n"

private def integerConversionFixture : String :=
  "function integerToNatural(value: Int): Nat := Int.toNat(value)\nfunction useIntegerConversion(convert: Int -> Nat, value: Int): Nat := convert(value)\nconst integerConversionAsValue: Nat := useIntegerConversion(Int.toNat, (4294967295 : Int))\n"

private def quotingFixture : String :=
  "function quoteText(value: String): String := String.quote(value)\nconst quoteCharacter: String := Char.quote(Char.ofNat(39))\nconst quoteInString: String := Char.quoteCore(Char.ofNat(39), true)\n"

private def coercionFixture : String :=
  "namespace Coercion\nstructure Box where { value: Nat }\ninstance unbox: Coe(Box, Nat) where { coe := Box.value }\nfunction boxed(unit: Unit): Box := Box.mk(877)\nfunction accept(value: Nat): Nat := value\nstructure Callable where { run: Nat -> Nat }\ninstance callable: CoeFun(Callable, fun (self: Callable) => Nat -> Nat) where { coe := Callable.run }\nstructure Action where { run: Unit -> Nat }\ninstance action: CoeFun(Action, fun (self: Action) => Unit -> Nat) where { coe := Action.run }\nstructure Carrier where { carrier: Type }\ninstance carrier: CoeSort(Carrier, Type) where { coe := Carrier.carrier }\nconst natural: Carrier := Carrier.mk(Nat)\nfunction identity(value: natural): natural := value\nfunction fromLocal{A: Type}[conversion: Coe(A, Nat)](value: A): Nat := value\nfunction invoke[converted: CoeFun(Callable, fun (self: Callable) => Nat -> Nat)](value: Callable): Nat := value(919)\nstructure FamilyBox(A: Type, F: A -> Type) where { value: forall(x: A), F(x) }\nend Coercion\nconst coercionArgument: Nat := Coercion.accept(Coercion.Box.mk(877))\nconst coercionApplication: Nat := Coercion.boxed()\nconst coercionFunction: Nat := Coercion.Callable.mk(fun x => x + 1)(880)\nconst coercionEmpty: Nat := Coercion.Action.mk(fun unit => 883)()\nconst coercionSort: Nat := Coercion.identity((887 : Nat))\nconst coercionLocal: Nat := Coercion.fromLocal(Coercion.Box.mk(907))\nconst coercionLocalFunction: Nat := Coercion.invoke(Coercion.Callable.mk(fun x => x + 1))\nconst familyBox: Coercion.FamilyBox(Nat, fun (x: Nat) => Nat) := { value := fun x => x + 2 }\nconst familyBoxValue: Nat := familyBox.value(927)\n"

private def numericFixture : String :=
  "namespace Numeric\nstructure Ticket where { value: Nat }\ninstance ticket{n: Nat}: OfNat(Ticket, n) where { ofNat := Ticket.mk(n) }\nfunction generic{A: Type}[OfNat A 857](unit: Unit): A := 857\nstructure Lift(A: Type): Type 1 where { value: A }\ninstance lifted{n: Nat}: OfNat(Lift Nat, n) where { ofNat := Lift.mk(n) }\nend Numeric\nconst numericTicket: Nat := Numeric.Ticket.value((859 : Numeric.Ticket))\nconst numericGeneric: Nat := Numeric.Ticket.value(Numeric.generic())\nconst numericHigh: Nat := Numeric.Lift.value((863 : Numeric.Lift Nat))\n"

private def postponedFixture : String :=
  "namespace Postponed\nstructure Box where { value: Nat }\nfunction choose{A: Type}(first: A, second: A): A := first\nfunction apply{A: Type}{B: Type}(fn: A -> B, value: A): B := fn(value)\nfunction proof{P: Prop}(witness: P, anchor: P): Nat := 823\nfunction boxValue(x: Box): Nat := x.value\nfunction readLater{A: Type}(first: A, anchor: A, read: A -> Nat): Nat := read(first)\nfunction withDefault{A: Type}(first: A, second: A := first): A := second\nend Postponed\nconst postponedRecord: Nat := Postponed.readLater({ value := 821 }, Postponed.Box.mk(0), Postponed.boxValue)\nconst postponedLambda: Nat := Postponed.apply(fun x => x.value, Postponed.Box.mk(827))\nconst postponedProof: Nat := Postponed.proof(by { constructor }, True.intro)\nconst postponedInteger: Int := Postponed.choose(829, Int.ofNat(0))\nconst postponedDefaultNatural: Nat := Postponed.choose(839, 0)\nconst postponedNamedRecord: Nat := Postponed.readLater(read := Postponed.boxValue, anchor := Postponed.Box.mk(0), first := { value := 853 })\n"

private def derivingEqualityFixture : String :=
  "namespace DerivingEquality\nuniverse u v\nstructure Pair(A: Type u, B: Type v) where {\n  first: A\n  second: B\n} deriving DecidableEq, BEq\ninductive Event(A: Type u): Type u where {\n  | empty\n  | value(payload: A)\n  | label(text: String)\n} deriving DecidableEq, BEq\nstructure Lift(A: Type): Type 1 where { value: A } deriving DecidableEq\nstructure Checked where {\n  count: Nat := 797\n  witness: count = count := by { rfl }\n} deriving Inhabited, BEq, DecidableEq\nstructure Seeded(A: Type u, seed: A): Type u where { value: A := seed } deriving Inhabited\ninductive Void where { } deriving BEq, DecidableEq\nfunction seeded{A: Type u}(seed: A): Seeded(A, seed) := Inhabited.default\nfunction same{A: Type u}[DecidableEq A](a: A, b: A): Bool := if (a = b) { true } else { false }\nend DerivingEquality\nfunction derivedExplicitDecision(a: Nat, b: Nat): Bool := Decidable.decide(self := decEq(a, b))\nconst derivedDecisionEqual: Bool := DerivingEquality.same(DerivingEquality.Pair.mk(DerivingEquality.Lift.mk(787), \"x\"), DerivingEquality.Pair.mk(DerivingEquality.Lift.mk(787), \"x\"))\nconst derivedDecisionDifferent: Bool := DerivingEquality.same(DerivingEquality.Event.value(787), DerivingEquality.Event.value(788))\nconst derivedDecisionTag: Bool := DerivingEquality.same(DerivingEquality.Event.value(787), DerivingEquality.Event.label(\"x\"))\nconst derivedDecisionString: Bool := DerivingEquality.same((DerivingEquality.Event.label(\"λ😀\") : DerivingEquality.Event Nat), DerivingEquality.Event.label(\"λ😀\"))\nconst derivedDefaultRecord: DerivingEquality.Checked := {}\nconst derivedDefaultOverride: DerivingEquality.Checked := { count := 809 }\nconst derivedDefaultRuntime: Nat := DerivingEquality.Checked.count((Inhabited.default : DerivingEquality.Checked))\nconst derivedDefaultRecordRuntime: Nat := derivedDefaultRecord.count\nconst derivedDefaultOverrideRuntime: Nat := derivedDefaultOverride.count\nconst derivedSeedRuntime: Nat := DerivingEquality.Seeded.value(DerivingEquality.seeded(811))\nconst derivedProofBEq: Bool := derivedDefaultRecord == derivedDefaultRecord\nconst derivedProofDecision: Bool := DerivingEquality.same(derivedDefaultRecord, derivedDefaultRecord)\nconst derivedProofDifferent: Bool := DerivingEquality.same(derivedDefaultRecord, derivedDefaultOverride)\ntheorem defaultCorrect: derivedDefaultRuntime = 797 := by { rfl }\ntheorem recordDefaultCorrect: derivedDefaultRecordRuntime = 797 := by { rfl }\ntheorem overrideCorrect: derivedDefaultOverrideRuntime = 809 := by { rfl }\ntheorem seedCorrect: derivedSeedRuntime = 811 := by { rfl }\n"

private def executableFloatOperationsFixture : String :=
  "function f2GenericAdd{A: Type}[HAdd A A A](a: A, b: A): A := a + b\nfunction f2Add64(a: Nat, b: Nat): Nat := UInt64.toNat(Float.toBits((Float.ofBits(UInt64.ofNat(a)) + Float.ofBits(UInt64.ofNat(b)))))\nfunction f2Sub64(a: Nat, b: Nat): Nat := UInt64.toNat(Float.toBits((Float.ofBits(UInt64.ofNat(a)) - Float.ofBits(UInt64.ofNat(b)))))\nfunction f2Mul64(a: Nat, b: Nat): Nat := UInt64.toNat(Float.toBits((Float.ofBits(UInt64.ofNat(a)) * Float.ofBits(UInt64.ofNat(b)))))\nfunction f2Div64(a: Nat, b: Nat): Nat := UInt64.toNat(Float.toBits((Float.ofBits(UInt64.ofNat(a)) / Float.ofBits(UInt64.ofNat(b)))))\nfunction f2Neg64(a: Nat): Nat := UInt64.toNat(Float.toBits((-Float.ofBits(UInt64.ofNat(a)))))\nfunction f2Abs64(a: Nat): Nat := UInt64.toNat(Float.toBits(Float.abs(Float.ofBits(UInt64.ofNat(a)))))\nfunction f2BEq64(a: Nat, b: Nat): Bool := Float.ofBits(UInt64.ofNat(a)) == Float.ofBits(UInt64.ofNat(b))\nfunction f2Eq64(a: Nat, b: Nat): Bool := if (Float.ofBits(UInt64.ofNat(a)) = Float.ofBits(UInt64.ofNat(b))) { true } else { false }\nfunction f2LT64(a: Nat, b: Nat): Bool := Decidable.decide(self := Float.decLt(Float.ofBits(UInt64.ofNat(a)), Float.ofBits(UInt64.ofNat(b))))\nfunction f2LE64(a: Nat, b: Nat): Bool := Decidable.decide(self := Float.decLe(Float.ofBits(UInt64.ofNat(a)), Float.ofBits(UInt64.ofNat(b))))\nfunction f2NaN64(a: Nat): Bool := Float.isNaN(Float.ofBits(UInt64.ofNat(a)))\nfunction f2Inf64(a: Nat): Bool := Float.isInf(Float.ofBits(UInt64.ofNat(a)))\nfunction f2Finite64(a: Nat): Bool := Float.isFinite(Float.ofBits(UInt64.ofNat(a)))\nfunction f2Apply64(fn: Float -> Float -> Float, a: Float, b: Float): Float := fn(a, b)\nfunction f2Partial64(a: Nat, b: Nat): Nat := UInt64.toNat(Float.toBits(f2Apply64(Float.add, Float.ofBits(UInt64.ofNat(a)), Float.ofBits(UInt64.ofNat(b)))))\nfunction f2Generic64(a: Nat, b: Nat): Nat := UInt64.toNat(Float.toBits(f2GenericAdd(Float.ofBits(UInt64.ofNat(a)), Float.ofBits(UInt64.ofNat(b)))))\nfunction f2Model64(a: Nat, b: Nat): Nat := UInt64.toNat(Float.toBits(Float.ofModel(Float.Model.add(Float.toModel(Float.ofBits(UInt64.ofNat(a))), Float.toModel(Float.ofBits(UInt64.ofNat(b)))))))\nconst f2Default64: Nat := UInt64.toNat(Float.toBits((Inhabited.default : Float)))\nconst f2Nan64: Nat := UInt64.toNat(Float.toBits(Float.nan))\nconst f2Infinity64: Nat := UInt64.toNat(Float.toBits(Float.inf))\nfunction f2Add32(a: Nat, b: Nat): Nat := UInt32.toNat(Float32.toBits((Float32.ofBits(UInt32.ofNat(a)) + Float32.ofBits(UInt32.ofNat(b)))))\nfunction f2Sub32(a: Nat, b: Nat): Nat := UInt32.toNat(Float32.toBits((Float32.ofBits(UInt32.ofNat(a)) - Float32.ofBits(UInt32.ofNat(b)))))\nfunction f2Mul32(a: Nat, b: Nat): Nat := UInt32.toNat(Float32.toBits((Float32.ofBits(UInt32.ofNat(a)) * Float32.ofBits(UInt32.ofNat(b)))))\nfunction f2Div32(a: Nat, b: Nat): Nat := UInt32.toNat(Float32.toBits((Float32.ofBits(UInt32.ofNat(a)) / Float32.ofBits(UInt32.ofNat(b)))))\nfunction f2Neg32(a: Nat): Nat := UInt32.toNat(Float32.toBits((-Float32.ofBits(UInt32.ofNat(a)))))\nfunction f2Abs32(a: Nat): Nat := UInt32.toNat(Float32.toBits(Float32.abs(Float32.ofBits(UInt32.ofNat(a)))))\nfunction f2BEq32(a: Nat, b: Nat): Bool := Float32.ofBits(UInt32.ofNat(a)) == Float32.ofBits(UInt32.ofNat(b))\nfunction f2Eq32(a: Nat, b: Nat): Bool := if (Float32.ofBits(UInt32.ofNat(a)) = Float32.ofBits(UInt32.ofNat(b))) { true } else { false }\nfunction f2LT32(a: Nat, b: Nat): Bool := Decidable.decide(self := Float32.decLt(Float32.ofBits(UInt32.ofNat(a)), Float32.ofBits(UInt32.ofNat(b))))\nfunction f2LE32(a: Nat, b: Nat): Bool := Decidable.decide(self := Float32.decLe(Float32.ofBits(UInt32.ofNat(a)), Float32.ofBits(UInt32.ofNat(b))))\nfunction f2NaN32(a: Nat): Bool := Float32.isNaN(Float32.ofBits(UInt32.ofNat(a)))\nfunction f2Inf32(a: Nat): Bool := Float32.isInf(Float32.ofBits(UInt32.ofNat(a)))\nfunction f2Finite32(a: Nat): Bool := Float32.isFinite(Float32.ofBits(UInt32.ofNat(a)))\nfunction f2Apply32(fn: Float32 -> Float32 -> Float32, a: Float32, b: Float32): Float32 := fn(a, b)\nfunction f2Partial32(a: Nat, b: Nat): Nat := UInt32.toNat(Float32.toBits(f2Apply32(Float32.add, Float32.ofBits(UInt32.ofNat(a)), Float32.ofBits(UInt32.ofNat(b)))))\nfunction f2Generic32(a: Nat, b: Nat): Nat := UInt32.toNat(Float32.toBits(f2GenericAdd(Float32.ofBits(UInt32.ofNat(a)), Float32.ofBits(UInt32.ofNat(b)))))\nfunction f2Model32(a: Nat, b: Nat): Nat := UInt32.toNat(Float32.toBits(Float32.ofModel(Float32.Model.add(Float32.toModel(Float32.ofBits(UInt32.ofNat(a))), Float32.toModel(Float32.ofBits(UInt32.ofNat(b)))))))\nconst f2Default32: Nat := UInt32.toNat(Float32.toBits((Inhabited.default : Float32)))\nconst f2Nan32: Nat := UInt32.toNat(Float32.toBits(Float32.nan))\nconst f2Infinity32: Nat := UInt32.toNat(Float32.toBits(Float32.inf))\n"

private def executableFloatFixture : String :=
  "structure F1Box(A: Type) where { value: A }\nfunction f1Identity{A: Type}(value: A): A := value\nfunction f1Round64(bits: Nat): Nat := UInt64.toNat(Float.toBits(Float.ofBits(UInt64.ofNat(bits))))\nfunction f1Model64(bits: Nat): Nat := match Float.toModel(Float.ofBits(UInt64.ofNat(bits))) with { | Float.Model.mk raw valid => UInt64.toNat(Float.toBits(Float.ofModel(Float.Model.mk(raw, valid)))) }\nfunction f1Match64(bits: Nat): Nat := match Float.ofBits(UInt64.ofNat(bits)) with { | Float.ofModel model => UInt64.toNat(Float.Model.toBits(model)) }\nfunction f1Use64(make: UInt64 -> Float, read: Float -> UInt64, bits: Nat): Nat := UInt64.toNat(read(make(UInt64.ofNat(bits))))\nfunction f1Partial64(bits: Nat): Nat := f1Use64(Float.ofBits, Float.toBits, bits)\nfunction f1Generic64(bits: Nat): Nat := UInt64.toNat(Float.toBits(f1Identity(Float.ofBits(UInt64.ofNat(bits)))))\nfunction f1Record64(bits: Nat): Nat := UInt64.toNat(Float.toBits(F1Box.value(F1Box.mk(Float.ofBits(UInt64.ofNat(bits))))))\nfunction f1Array64(bits: Nat): Nat := UInt64.toNat(Float.toBits(Array.getD(#[Float.ofBits(UInt64.ofNat(bits))], 0, Float.ofBits(UInt64.ofNat(0)))))\nfunction f1Closure64(bits: Nat): Nat := {\n  let value: Float := Float.ofBits(UInt64.ofNat(bits))\n  let read: Unit -> Float := fun (_: Unit) => value\n  UInt64.toNat(Float.toBits(read(())))\n}\nfunction f1Round32(bits: Nat): Nat := UInt32.toNat(Float32.toBits(Float32.ofBits(UInt32.ofNat(bits))))\nfunction f1Model32(bits: Nat): Nat := match Float32.toModel(Float32.ofBits(UInt32.ofNat(bits))) with { | Float32.Model.mk raw valid => UInt32.toNat(Float32.toBits(Float32.ofModel(Float32.Model.mk(raw, valid)))) }\nfunction f1Match32(bits: Nat): Nat := match Float32.ofBits(UInt32.ofNat(bits)) with { | Float32.ofModel model => UInt32.toNat(Float32.Model.toBits(model)) }\nfunction f1Use32(make: UInt32 -> Float32, read: Float32 -> UInt32, bits: Nat): Nat := UInt32.toNat(read(make(UInt32.ofNat(bits))))\nfunction f1Partial32(bits: Nat): Nat := f1Use32(Float32.ofBits, Float32.toBits, bits)\nfunction f1Generic32(bits: Nat): Nat := UInt32.toNat(Float32.toBits(f1Identity(Float32.ofBits(UInt32.ofNat(bits)))))\nfunction f1Record32(bits: Nat): Nat := UInt32.toNat(Float32.toBits(F1Box.value(F1Box.mk(Float32.ofBits(UInt32.ofNat(bits))))))\nfunction f1Array32(bits: Nat): Nat := UInt32.toNat(Float32.toBits(Array.getD(#[Float32.ofBits(UInt32.ofNat(bits))], 0, Float32.ofBits(UInt32.ofNat(0)))))\nfunction f1Closure32(bits: Nat): Nat := {\n  let value: Float32 := Float32.ofBits(UInt32.ofNat(bits))\n  let read: Unit -> Float32 := fun (_: Unit) => value\n  UInt32.toNat(Float32.toBits(read(())))\n}\n"

private def arrayFilterFixture : String :=
  "namespace FilterCases\nuniverse u\nfunction keep{A: Type u}(predicate: A -> Bool, values: Array A): Array A := Array.filter(predicate, values)\nfunction greater(limit: Nat): Nat -> Bool := fun value => if (limit < value) { true } else { false }\nfunction rendered(start: Nat, stop: Nat): String := reprStr(Array.toList(Array.filter(greater(2), #[1, 2, 5, 2, 7, 7], start := start, stop := stop)))\nstructure High: Type 1 where { value: Nat }\nconst high: Array High := keep(fun value => if (2 < value.value) { true } else { false }, #[High.mk(1), High.mk(5)])\nconst partial: (Nat -> Bool) -> Array Nat -> Nat -> Nat -> Array Nat := Array.filter(α := Nat)\nend FilterCases\nconst arrayFilterDefault: String := reprStr(Array.toList(Array.filter(FilterCases.greater(2), #[1, 2, 5, 2, 7, 7])))\nconst arrayFilterStart: String := reprStr(Array.toList(Array.filter(fun _ => true, #[1, 2, 5, 2, 7, 7], start := 3)))\nconst arrayFilterStop: String := reprStr(Array.toList(Array.filter(fun _ => true, #[1, 2, 5, 2, 7, 7], stop := 3)))\nconst arrayFilterNone: String := reprStr(Array.toList(Array.filter(fun _ => false, #[1, 2, 5])))\nconst arrayFilterEmpty: String := reprStr(Array.toList(Array.filter(fun _ => true, (#[] : Array Nat))))\nconst arrayFilterPartial: String := reprStr(Array.toList(FilterCases.partial(FilterCases.greater(2), #[1, 2, 5, 2, 7, 7], 0, 100)))\nconst arrayFilterHigh: Nat := (Array.getD(FilterCases.high, 0, FilterCases.High.mk(0))).value\nconst arrayFilterPersistent: String := { let source := #[1, 2, 5]\n let filtered := Array.filter(fun value => if (1 < value) { true } else { false }, source)\n reprStr(Array.toList(source)) ++ \"/\" ++ reprStr(Array.toList(Array.push(filtered, 9))) }\nfunction arrayFilterBounds(start: Nat, stop: Nat): String := FilterCases.rendered(start, stop)\ntheorem arrayFilterModel: Array.toList(Array.filter(fun _ => true, #[1, 2], start := 0, stop := 2)) = [1, 2] := by { rfl }\n"

private def operatorTreeFixture : String :=
  "namespace OperatorTree\nstructure Bag where { value: Nat }\ninstance plus: Add Bag where { add := fun a => fun b => Bag.mk(a.value + b.value) }\ninstance times: Mul Bag where { mul := fun a => fun b => Bag.mk(a.value * b.value) }\n@[default_instance 1100]\ninstance scale: HMul(Nat, Bag, Bag) where { hMul := fun a => fun b => Bag.mk(a * b.value) }\nstructure Tag where { value: Nat }\ninstance combine: HAdd(Bag, Tag, Nat) where { hAdd := fun a => fun b => a.value + b.value }\nend OperatorTree\nfunction operatorTreePromote(n: Nat, i: Int): Int := (n + 0) + i\nfunction operatorTreeReverse(n: Nat, i: Int): Int := i + (0 + n)\nfunction operatorExpected(n: Nat): Int := n + 1\nfunction operatorTreeNeg(n: Nat, i: Int): Int := -n + i\nfunction operatorRelation(n: Nat, i: Int): Bool := if (n < i) { true } else { false }\nfunction operatorBooleanRelation(n: Nat): Bool := (n < 2) == (n ≤ 1)\nfunction operatorPropBool(n: Nat): Bool := n < 2\nfunction operatorPowerNat(a: Nat, b: Nat, c: Nat): Nat := a ^ b ^ c\nfunction operatorPowerInt(a: Int, n: Nat): Int := a ^ n\nfunction operatorShiftLeft(a: Nat, n: Nat): Nat := a <<< n\nfunction operatorShiftRight(a: Nat, n: Nat): Nat := a >>> n\nconst operatorWordShift: Nat := UInt8.toNat((129 : UInt8) <<< 1)\nconst operatorSignedShift: Int := Int64.toInt((-9 : Int64) >>> 2)\nconst operatorWordPower: Nat := UInt8.toNat((3 : UInt8) ^ 6)\nconst operatorHeterogeneous: Nat := OperatorTree.Bag.mk(5) + OperatorTree.Tag.mk(7)\nconst operatorHeterogeneousDefault: Nat := OperatorTree.Bag.value(2 * OperatorTree.Bag.mk(11))\ntheorem operatorLeafCoercions(n: Nat, i: Int): (n + 0) + i = Int.add(Int.add(Int.ofNat(n), 0), i) := by { rfl }\ntheorem operatorRightAction(a: Int, n: Nat): a ^ n = Int.pow(a, n) := by { rfl }\n"

private def logicDecisionFixture : String :=
  "function logicIntEquality(a: Int, b: Int): Bool := if (a = b) { true } else { false }\nfunction logicAnd(a: Nat, b: Nat): Bool := if ((a < b) ∧ (a ≤ b)) { true } else { false }\nfunction logicOr(a: Nat, b: Nat): Bool := if ((a < b) ∨ (a = b)) { true } else { false }\nfunction logicNot(a: Nat, b: Nat): Bool := if (a ≠ b) { true } else { false }\nfunction logicImplies(a: Nat, b: Nat): Bool := if ((a < b) -> (a ≤ b)) { true } else { false }\nfunction logicIff(a: Nat, b: Nat): Bool := if ((a < b) ↔ (a ≤ b)) { true } else { false }\nfunction logicTrue(a: Nat, b: Nat): Bool := if (True) { true } else { false }\nfunction logicFalse(a: Nat, b: Nat): Bool := if (False) { true } else { false }\nfunction logicDecisions(a: Nat, b: Nat): String := reprStr([logicAnd(a, b), logicOr(a, b), logicNot(a, b), logicImplies(a, b), logicIff(a, b), logicTrue(a, b), logicFalse(a, b)])\nfunction intComparison(a: Int, b: Int): String := reprStr([if (a < b) { true } else { false }, if (a ≤ b) { true } else { false }, if (a > b) { true } else { false }, if (a ≥ b) { true } else { false }])\n"

private def comparisonNotationFixture : String :=
  "function comparisonNotation(a: Nat, b: Nat): String := reprStr([if (a < b) { true } else { false }, if (a <= b) { true } else { false }, if (a ≤ b) { true } else { false }, if (a > b) { true } else { false }, if (a >= b) { true } else { false }, if (a ≥ b) { true } else { false }, if (a ≠ b) { true } else { false }])\ntheorem comparisonNotationScope(a: Nat, b: Nat, h: a < b): LT.lt(a, b) := by { exact h }\n"

private def utf8Fixture : String :=
  "namespace Utf8Cases\nconst samples: Array ByteArray := #[List.toByteArray([]), List.toByteArray([0]), List.toByteArray([65, 0, 66]), List.toByteArray([127, 194, 128, 223, 191, 224, 160, 128, 239, 191, 191, 240, 144, 128, 128, 244, 143, 191, 191]), List.toByteArray([239, 187, 191, 65]), List.toByteArray([195, 169, 240, 159, 152, 128]), List.toByteArray([128]), List.toByteArray([192, 128]), List.toByteArray([193, 191]), List.toByteArray([194]), List.toByteArray([226, 130]), List.toByteArray([226, 65, 172]), List.toByteArray([224, 159, 191]), List.toByteArray([237, 160, 128]), List.toByteArray([240, 143, 191, 191]), List.toByteArray([244, 144, 128, 128]), List.toByteArray([245, 128, 128, 128]), List.toByteArray([255]), List.toByteArray([65, 195])]\nfunction sample(index: Nat): ByteArray := Array.getD(samples, index, ByteArray.empty)\nfunction read(decode: ByteArray -> Option String, bytes: ByteArray): String := match decode(bytes) with { | .none => \"#invalid\" | .some text => \"#\" ++ text }\nend Utf8Cases\nfunction utf8ValidateCase(index: Nat): Bool := ByteArray.validateUTF8(Utf8Cases.sample(index))\nfunction utf8DecodeCase(index: Nat): String := Utf8Cases.read(String.fromUTF8?, Utf8Cases.sample(index))\nfunction utf8RoundtripCase(index: Nat): String := match String.fromUTF8?(Utf8Cases.sample(index)) with { | .none => \"#invalid\" | .some text => reprStr(List.map(UInt8.toNat, ByteArray.toList(String.toUTF8(text)))) }\nfunction utf8Encode(text: String): String := reprStr(List.map(UInt8.toNat, ByteArray.toList(String.toUTF8(text))))\nconst utf8Persistent: Bool := {\n let before: ByteArray := Utf8Cases.sample(5)\n let decoded: Option String := String.fromUTF8?(before)\n let after: ByteArray := ByteArray.set!(before, 0, 65)\n ByteArray.beq(before, Utf8Cases.sample(5)) && ByteArray.validateUTF8(before) && !ByteArray.validateUTF8(after)\n}\n"

private def application : String :=
  operatorTreeFixture ++ logicDecisionFixture ++ utf8Fixture ++ comparisonNotationFixture ++ arrayFilterFixture ++ floatDisplayFixture ++ floatConversionsFixture ++ executableFloatOperationsFixture ++ executableFloatFixture ++ productUniverseFixture ++ arrayUniverseFixture ++ defaultInstanceFixture ++ literalConstraintFixture ++ scientificLiteralFixture ++ hashFixture ++ wordFixture ++ signedFixture ++ signedDictionaryFixture ++ signedConversionFixture ++ signedShiftFixture ++ signedClampFixture ++ signedAbsFixture ++ signedOrderFixture ++ signedNumericFixture ++ boolWordFixture ++ unsignedOrderFixture ++ unsignedPowerFixture ++ unsignedOfIntFixture ++ unsignedClampFixture ++ standardSumFixture ++ standardFloatCanonicalFixture ++ standardFloatBitEqualityFixture ++ standardByteArrayFixture ++ byteArrayCollectionFixture ++ unsignedDisplayFixture ++ unsignedFixture ++ reprFixture ++ formatFixture ++ integerConversionFixture ++ quotingFixture ++ coercionFixture ++ numericFixture ++ postponedFixture ++ derivingEqualityFixture ++ generalizedRuntimeFixture ++
  "const generalizedSharedRuntime: Nat := GeneralizedRuntime.combined(poly := GeneralizedRuntime.generic, unit := ())\n" ++
  "const syntheticDefaultRuntime: Nat := GeneralizedRuntime.selected()\n" ++
  "const syntheticExpectedRuntime: Bool := GeneralizedRuntime.expected(())\n" ++
  "function emptyElim{A: Type}(value: Empty): A := nomatch value\n" ++
  "function falseElim{A: Type}(proof: False): A := nomatch proof\n" ++
  "inductive Void(A: Type) where { }\n" ++
  "function voidElim{A: Type}(value: Void(A)): A := nomatch value\n" ++
  "inductive Diagonal: Nat -> Nat -> Type where { | same(n: Nat): Diagonal(n, n) }\n" ++
  "function impossibleIndex(value: Diagonal(0, 1)): Nat := nomatch value\n" ++
  "function ignoreGuard(guard: False -> Nat): Nat := 119\n" ++
  "function guarded(value: Nat, proof: False): Nat := nomatch proof\n" ++
  "const proofClosure: Nat := ignoreGuard(fun (proof: False) => nomatch proof)\n" ++
  "const proofEntry: Nat := ignoreGuard(guarded(120))\n" ++
  -- Class notation resolves through the existing output-param and instance
  -- elaborator; it never hard-codes Nat addition in the parser.
  -- Generic HAdd/HSub/HMul/HDiv/HMod classes and their Nat instances now
  -- come from the pinned portable checked Standard prelude.
  "function arithmeticPrecedence(a: Nat, b: Nat, c: Nat): Nat := a + b * c - Nat.div(Nat.add(a, c), b)\n" ++
  "const arithmeticMixed: Nat := arithmeticPrecedence(10, 2, 3)\n" ++
  "const arithmeticAssociative: Nat := 8 - 3 - 2\n" ++
  "const arithmeticModulo: Nat := 17 % 5 * 2 + 3\n" ++
  "function secondInList(xs: List Nat): Nat := match xs with {\n" ++
  "  | List.cons first (List.cons second tail) => second\n" ++
  "  | _ => 0\n" ++
  "}\n" ++
  "const listConsSecond: Nat := secondInList(1 :: 2 :: [])\n" ++
  "const listConsSingle: Nat := secondInList(3 :: [])\n" ++
  "const stdListFoldlRuntime: Nat := List.foldl(Nat.add, 0, [1, 2, 3])\n" ++
  "const stdListFoldrRuntime: Nat := List.foldr(Nat.add, 0, [1, 2, 3])\n" ++
  "const stdListMapRuntime: Nat := List.length(List.map(Nat.succ, [1, 2, 3]))\n" ++
  "const stdListFilterRuntime: Nat := List.length(List.filter(fun (n: Nat) => Nat.blt(n, 3), [1, 2, 3, 4]))\n" ++
  "const stdListReverseRuntime: Nat := Option.getD(List.get?(List.reverse([4, 5]), 0), 0)\n" ++
  "const stdListGetOutsideRuntime: Nat := Option.getD(List.get?([4, 5], 8), 99)\n" ++
  "const stdOptionRuntime: Nat := Option.getD(Option.bind(Option.some(3), fun (n: Nat) => Option.some(Nat.succ(n))), 0)\n" ++
  "const stdExceptSeed: Except String Nat := Except.ok(4)\n" ++
  "const stdExceptBad: Except String Nat := Except.error(\"bad\")\n" ++
  "const stdExceptMapRuntime: Nat := Option.getD(Except.toOption(Except.map(Nat.succ, stdExceptSeed)), 0)\n" ++
  "const stdExceptBindRuntime: Nat := Option.getD(Except.toOption(Except.bind(stdExceptSeed, fun (n: Nat) => Except.ok(Nat.add(n, 2)))), 0)\n" ++
  "const stdExceptRecoveryRuntime: Nat := Option.getD(Except.toOption(Except.tryCatch(Except.mapError(fun (s: String) => String.Internal.length(s), stdExceptBad), fun (len: Nat) => Except.ok(len))), 0)\n" ++
  "const stdExceptIsOkRuntime: Bool := Except.isOk(stdExceptSeed)\n" ++
  "const stdExceptFailureRuntime: Nat := Option.getD(Except.toOption(stdExceptBad), 77)\n" ++
  "const stdExceptFallbackRuntime: Nat := Option.getD(Except.toOption(Except.orElseLazy(stdExceptBad, fun (_: Unit) => Except.ok(12))), 0)\n" ++
  "const stdExceptToBoolRuntime: Bool := Except.toBool(stdExceptSeed)\n" ++
  "const appendSimple: Bool := if (\"left\" ++ \"right\" = \"leftright\") { true } else { false }\n" ++
  "const appendUnicode: Bool := if (\"🍋\" ++ \"é\" = \"🍋é\") { true } else { false }\n" ++
  "const appendGrouped: Bool := if ((\"A\" ++ \"B\") ++ \"C\" = \"ABC\") { true } else { false }\n" ++
  "const stdStringBeqRuntime: Bool := \"green\" == \"green\"\n" ++
  "const stdStringNeRuntime: Bool := \"green\" != \"red\"\n" ++
  "const equalityTrue: Bool := 3 + 4 == 7\n" ++
  "const equalityFalse: Bool := 3 * 4 == 11\n" ++
  "const inequalityTrue: Bool := 4 * 5 != 21\n" ++
  "const equalityComposed: Bool := 2 + 2 == 4 && !(5 == 6)\n" ++
  "const boolLazyPrecedence: Bool := true || false && false\n" ++
  "const boolLazyNegation: Bool := !false && true\n" ++
  "const boolLazyGrouping: Bool := !(false || true)\n" ++
  "function boolLazyBranch(a: Bool, b: Bool): Bool := a && !b || b\n" ++
  "const signedLiteral: Int := -42\n" ++
  "function signedArithmetic(a: Int, b: Int): Int := -a * b + a\n" ++
  "opaque keep(value: Nat): Nat := {\n" ++
  "  let selected: _ := value\n" ++
  "  selected\n" ++
  "}\n" ++
  "function apply(f: Nat -> Nat, value: Nat): Nat := f(value)\n" ++
  "function choose{A: Type}(first: A, second: A): A := first\n" ++
  "function useUnit(value: Unit): Nat := 9\n" ++
  "const identity: Nat -> Nat := fun x => x\n" ++
  "const shadow: Nat -> Nat := fun x =>\n" ++
  "  let x: Nat := x\n" ++
  "  x\n" ++
  "function capture(value: Nat): Nat := apply(fun ignored => value, 0)\n" ++
  "const answer: Nat := apply(fun x => x, choose(A := Nat, second := 0, first := 42))\n" ++
  "const typed: Nat := (identity(7) : Nat)\n" ++
  "const completed: Nat := useUnit()\n" ++
  "const inferred: Nat := choose(A := _, first := 8, second := 0)\n" ++
  "const inferredLambda: Nat := (fun x => x)(13)\n" ++
  "const nested: Nat := apply(fun x =>\n" ++
  "  let f: Nat -> Nat := fun x => x\n" ++
  "  f(x), 11)\n" ++
  "const declared: _ := 12\n" ++
  "namespace Library\n" ++
  "const fallback: Nat := 17\n" ++
  "function defaulted(first: Nat := fallback, second: Nat := first): Nat := second\n" ++
  "function withUnit(value: Nat := 19, u: Unit): Nat := value\n" ++
  "function nullary(): Nat := 23\n" ++
  "namespace Inner\n" ++
  "const inherited: Nat := fallback\n" ++
  "end Inner\n" ++
  "end Library\n" ++
  "namespace Caller\n" ++
  "const fallback: Nat := 99\n" ++
  "open Library\n" ++
  "const answer: Nat := defaulted()\n" ++
  "const named: Nat := defaulted(second := 5)\n" ++
  "const contextual: Nat := defaulted\n" ++
  "const preserved: Nat -> Nat := defaulted(4)\n" ++
  "const alias: Nat -> Nat -> Nat := defaulted\n" ++
  "end Caller\n" ++
  "section Vars\n" ++
  "variable {A: Type} (seed: A)\n" ++
  "def sectionResult: A := seed\n" ++
  "function sectionIgnored(value: Nat): Nat := value\n" ++
  "function sectionDefault(value: A := seed): A := value\n" ++
  "section Inner\n" ++
  "variable (count: Nat)\n" ++
  "def sectionCount: Nat := count\n" ++
  "end Inner\n" ++
  "function sectionShadow(seed: Nat): Nat := seed\n" ++
  "end Vars\n" ++
  "const sectionAnswer: Nat := sectionResult(seed := 31)\n" ++
  "const sectionDefaultAnswer: Nat := sectionDefault(seed := 32)\n" ++
  "const fromOpened: Nat := Caller.answer\n" ++
  "const fromInherited: Nat := Library.Inner.inherited\n" ++
  "const fromPartial: Nat := Caller.preserved(6)\n" ++
  "const fromNullary: Nat := Library.nullary()\n" ++
  "const fromUnitDefault: Nat := Library.withUnit()\n" ++
  "section Proofs\n" ++
  "variable (P: Prop) (proof: P)\n" ++
  "include proof\n" ++
  "theorem included: P := proof\n" ++
  "omit proof\n" ++
  "theorem explicitProof(proof: P): P := proof\n" ++
  "end Proofs\n" ++
  "section Recursive\n" ++
  "variable (seed: Nat)\n" ++
  "function sectionFold(xs: List Nat): Nat := match xs with {\n" ++
  "  | List.nil => seed\n" ++
  "  | List.cons head tail => sectionFold(tail)\n" ++
  "}\n" ++
  "end Recursive\n" ++
  "const recursiveSection: Nat := sectionFold(37, [])\n" ++
  "function strictDefault{{A: Type}}(value: Nat := 3): Nat := value\n" ++
  "const strictCompleted: Nat := strictDefault(A := Nat)\n" ++
  "const quantifiedId: forall A : Type, A -> A := fun (A: Type) x => x\n" ++
  "const unicodeId: ∀ (A: Type), A → A := λ (A: Type) x ↦ x\n" ++
  "const implicitId: forall {A: Type}, A -> A := fun {A: Type} x => x\n" ++
  "function unicodeStrict⦃A: Type⦄(value: A): A := value\n" ++
  "const quantifiedAnswer: Nat := quantifiedId(Nat, 41)\n" ++
  "const unicodeAnswer: Nat := unicodeId(Nat, 42)\n" ++
  "const implicitAnswer: Nat := implicitId(43)\n" ++
  "const strictAnswer: Nat := unicodeStrict(44)\n" ++
  "const dependentId: (A: Type) -> A -> A := λ (A: Type) x => x\n" ++
  "const dependentAnswer: Nat := dependentId(Nat, 45)\n" ++
  "theorem quantifiedProof: ∀ (P: Prop), P -> P := λ (P: Prop) proof => proof\n" ++
  "const groupLocal: forall (T: Type), T -> T -> T := fun (T: Type) (T x: T) => x\n" ++
  "const groupOuter: Nat := groupLocal(Nat, 1, 51)\n" ++
  "const groupPi: (A B: Type) -> A -> B -> B := fun (A B: Type) (x: A) (y: B) => y\n" ++
  "const groupArrow: Nat := groupPi(Bool, Nat, true, 52)\n" ++
  "const groupBare: forall A B : Type, A -> B -> A := fun (A B: Type) (x: A) (y: B) => x\n" ++
  "const groupBareAnswer: Nat := groupBare(Nat, Bool, 53, true)\n" ++
  "const groupInferred: Nat -> Bool -> Bool := fun (x y) => y\n" ++
  "const groupInferredAnswer: Bool := groupInferred(0, true)\n" ++
  "const groupGlobal: Nat -> Nat -> Nat := fun (Nat x: Nat) => x\n" ++
  "const groupGlobalAnswer: Nat := groupGlobal(0, 54)\n" ++
  "function groupImplicit{A B: Type}(x: A, y: B): B := y\n" ++
  "function groupStrict⦃A B: Type⦄(x: A, y: B): B := y\n" ++
  "const groupKindsAnswer: Nat := groupStrict(groupImplicit(0, true), 55)\n" ++
  "section Grouped\n" ++
  "variable (A B: Type) (x y: A)\n" ++
  "function groupSection(z: B): A := y\n" ++
  "function groupFold(xs: List B, count: Nat): A := match xs with {\n" ++
  "  | List.nil => y\n" ++
  "  | List.cons head tail => groupFold(tail, Nat.succ(count))\n" ++
  "}\n" ++
  "end Grouped\n" ++
  "const groupSectionAnswer: Nat := groupSection(Nat, Bool, 56, true)\n" ++
  "const groupFoldAnswer: Nat := groupFold(Nat, Bool, 57, [true,], 0)\n" ++
  "namespace Data\n" ++
  "structure Duo{A B: Type} where {\n" ++
  "  (A spare: A)\n" ++
  "  convert: forall (x y: Nat), B\n" ++
  "}\n" ++
  "const duo: Duo(A := Nat, B := Nat) := {\n" ++
  "  A := 1,\n" ++
  "  spare := 61,\n" ++
  "  convert := fun (x y) => y\n" ++
  "}\n" ++
  "const dataRecord: Nat := duo.convert(duo.A, duo.spare)\n" ++
  "inductive Event(A: Type){B C: Type}(D: Type): Type where {\n" ++
  "  | idle\n" ++
  "  | item(seed: A){n m: Nat}(choose: forall (x y: A), A := fun (x y) => y)\n" ++
  "}\n" ++
  "const event: Event(Nat, Nat, B := Nat, C := Bool) := Event.item(1, n := 0, m := 0)\n" ++
  "function pick(value: Event(Nat, Nat, B := Nat, C := Bool)): Nat := match value with {\n" ++
  "  | Event.idle => 0\n" ++
  "  | Event.item seed n m choose => choose(seed, 62)\n" ++
  "}\n" ++
  "end Data\n" ++
  "const dataRecordAnswer: Nat := Data.dataRecord\n" ++
  "const dataMatchAnswer: Nat := Data.pick(Data.event)\n" ++
  "namespace Indexed\n" ++
  "inductive Vector(A: Type): Nat -> Type where {\n" ++
  "  | nil: Vector(A, 0)\n" ++
  "  | cons(n: Nat, head: A, tail: Vector(A, n)): Vector(A, Nat.succ(n))\n" ++
  "}\n" ++
  "const one: Vector(Nat, Nat.succ(0)) := Vector.cons(0, 71, Vector.nil)\n" ++
  "function peek{A: Type}(n: Nat, values: Vector(A, n), fallback: A): A := match values with {\n" ++
  "  | Vector.nil => fallback\n" ++
  "  | Vector.cons n head tail => head\n" ++
  "}\n" ++
  "inductive Cell(A: Type): Nat -> Bool -> Type where {\n" ++
  "  | cell(n: Nat, flag: Bool, value: A): Cell(A, n, flag)\n" ++
  "}\n" ++
  "function readCell{A: Type}(n: Nat, flag: Bool, cell: Cell(A, n, flag)): A := match cell with {\n" ++
  "  | Cell.cell n flag value => value\n" ++
  "}\n" ++
  "theorem vectorInduction{A: Type}(P: Prop, base: P, n: Nat, values: Vector(A, n)): P :=\n" ++
  "  Vector.rec(fun n values => P, base, fun n head tail ih => ih, values)\n" ++
  "function map{A B: Type}(f: A -> B, n: Nat, values: Vector(A, n)): Vector(B, n) := match values with {\n" ++
  "  | Vector.nil => Vector.nil\n" ++
  "  | Vector.cons k head tail => Vector.cons(k, f(head), map(f, k, tail))\n" ++
  "}\n" ++
  "function rebuild{A: Type}(n: Nat, values: Vector(A, n)): Vector(A, n) := match values with {\n" ++
  "  | Vector.nil => values\n" ++
  "  | Vector.cons k head tail => values\n" ++
  "}\n" ++
  "function count{A: Type}(n: Nat, values: Vector(A, n), total: Nat): Nat := match values with {\n" ++
  "  | Vector.nil => total\n" ++
  "  | Vector.cons k head tail => count(k, tail, Nat.succ(total))\n" ++
  "}\n" ++
  "function copyCell{A: Type}(n: Nat, flag: Bool, cell: Cell(A, n, flag)): Cell(A, n, flag) := match cell with {\n" ++
  "  | Cell.cell k tag value => Cell.cell(k, tag, value)\n" ++
  "}\n" ++
  "inductive EvenChain: Nat -> Type where {\n" ++
  "  | stop: EvenChain(0)\n" ++
  "  | step(k: Nat, next: EvenChain(Nat.succ(k))): EvenChain(Nat.succ(Nat.succ(k)))\n" ++
  "  | single: EvenChain(Nat.succ(0))\n" ++
  "}\n" ++
  "function chainCopy(n: Nat, chain: EvenChain(n)): EvenChain(n) := match chain with {\n" ++
  "  | EvenChain.stop => EvenChain.stop\n" ++
  "  | EvenChain.step k next => EvenChain.step(k, chainCopy(Nat.succ(k), next))\n" ++
  "  | EvenChain.single => EvenChain.single\n" ++
  "}\n" ++
  "const two: Vector(Nat, Nat.succ(Nat.succ(0))) := Vector.cons(Nat.succ(0), 74, one)\n" ++
  "const mapped: Vector(Nat, Nat.succ(Nat.succ(0))) := map(fun x => Nat.succ(x), Nat.succ(Nat.succ(0)), two)\n" ++
  "const chained: EvenChain(Nat.succ(Nat.succ(0))) := chainCopy(Nat.succ(Nat.succ(0)), EvenChain.step(0, EvenChain.single))\n" ++
  "function chainSize(n: Nat, chain: EvenChain(n)): Nat := match chain with {\n" ++
  "  | EvenChain.stop => n\n" ++
  "  | EvenChain.step k next => Nat.succ(chainSize(Nat.succ(k), next))\n" ++
  "  | EvenChain.single => n\n" ++
  "}\n" ++
  "function contextCopy{A: Type}(n: Nat, values: Vector(A, n), other: Vector(A, n)): Vector(A, n) := match values with {\n" ++
  "  | Vector.nil => other\n" ++
  "  | Vector.cons k head tail => other\n" ++
  "}\n" ++
  "function localCopy(n: Nat, values: Vector(Nat, n)): Vector(Nat, n) :=\n" ++
  "  let other: Vector(Nat, n) := values\n" ++
  "  match values with { | Vector.nil => other | Vector.cons k head tail => other }\n" ++
  "function head{A: Type}(n: Nat, values: Vector(A, Nat.succ(n))): A := match values with {\n" ++
  "  | Vector.cons k head tail => head\n" ++
  "}\n" ++
  "function tail{A: Type}(n: Nat, values: Vector(A, Nat.succ(n))): Vector(A, n) := match values with {\n" ++
  "  | Vector.cons k head tail => tail\n" ++
  "}\n" ++
  "function fixedTail(values: Vector(Nat, 2)): Vector(Nat, 1) := match values with {\n" ++
  "  | Vector.cons k head tail => tail\n" ++
  "}\n" ++
  "function zeroOnly(values: Vector(Nat, 0)): Nat := match values with { | Vector.nil => 85 }\n" ++
  "inductive Same: Nat -> Nat -> Type where { | same(n: Nat): Same(n, n) }\n" ++
  "function impossible(value: Same(0, 1)): Nat := match value with { }\n" ++
  "inductive Flag: Bool -> Type where { | yes: Flag(true) | no: Flag(false) }\n" ++
  "function trueOnly(value: Flag(true)): Nat := match value with { | Flag.yes => 91 }\n" ++
  "function boolBranch(value: Bool): Nat := match value with { | true => 93 | false => 94 }\n" ++
  "theorem contextProof(P: Nat -> Prop, n: Nat, proof: P(n)): P(n) := match n with {\n" ++
  "  | Nat.zero => proof\n" ++
  "  | Nat.succ k => proof\n" ++
  "}\n" ++
  "function replace{A: Type}(n: Nat, values: Vector(A, n), other: Vector(A, n)): Vector(A, n) := match values with {\n" ++
  "  | Vector.nil => other\n" ++
  "  | Vector.cons k head tail => Vector.cons(k, head, replace(k, tail, tail))\n" ++
  "}\n" ++
  "function captured(n: Nat, values: Vector(Nat, n)): Nat := Vector.rec(fun k value => Nat, n, fun k head tail ih => ih, values)\n" ++
  "function computedFold(seed: Nat, n: Nat): Nat := Nat.rec(fun k => Nat, seed, fun k ih => Nat.succ(ih), Nat.succ(n))\n" ++
  "function localFold(seed: Nat, n: Nat): Nat :=\n" ++
  "  let run: Nat -> Nat := fun m => Nat.rec(fun k => Nat, seed, fun k ih => Nat.succ(ih), m)\n" ++
  "  run(n)\n" ++
  "function nestedFold(n: Nat): Nat := Nat.rec(fun k => Nat, 0, fun k ih => Nat.rec(fun j => Nat, ih, fun j inner => Nat.succ(inner), k), n)\n" ++
  "function capturedMap{A: Type}(n: Nat, values: Vector(A, n)): Vector(A, n) := Vector.rec(fun k value => Vector(A, k), Vector.nil, fun k head tail ih => Vector.cons(k, head, ih), values)\n" ++
  "function twoTail{A: Type}(n: Nat, values: Vector(A, Nat.succ(Nat.succ(n)))): Vector(A, n) := match values with { | .cons _ _ (.cons k _ tail) => tail }\n" ++
  "function multiIndexed(n: Nat, values: Vector(Nat, n)): Nat := match n, values with { | 0, .nil => 0 | k + 1, .cons m head tail => head }\n" ++
  "end Indexed\n" ++
  "const indexedAnswer: Nat := Indexed.peek(Nat.succ(0), Indexed.one, 0)\n" ++
  "const indexedEmpty: Nat := Indexed.peek(0, Indexed.Vector.nil, 72)\n" ++
  "const indexedCell: Nat := Indexed.readCell(3, true, Indexed.Cell.cell(3, true, 73))\n" ++
  "const indexedMapped: Nat := Indexed.peek(Nat.succ(Nat.succ(0)), Indexed.mapped, 0)\n" ++
  "const indexedRebuilt: Nat := Indexed.peek(Nat.succ(Nat.succ(0)), Indexed.rebuild(Nat.succ(Nat.succ(0)), Indexed.two), 0)\n" ++
  "const indexedCount: Nat := Indexed.count(Nat.succ(Nat.succ(0)), Indexed.two, 80)\n" ++
  "const indexedCopiedCell: Nat := Indexed.readCell(3, true, Indexed.copyCell(3, true, Indexed.Cell.cell(3, true, 76)))\n" ++
  "const indexedChainSize: Nat := Indexed.chainSize(Nat.succ(Nat.succ(0)), Indexed.chained)\n" ++
  "const contextAnswer: Nat := Indexed.head(1, Indexed.contextCopy(2, Indexed.two, Indexed.two))\n" ++
  "const contextLetAnswer: Nat := Indexed.head(1, Indexed.localCopy(2, Indexed.two))\n" ++
  "const refinedTailAnswer: Nat := Indexed.head(0, Indexed.tail(1, Indexed.two))\n" ++
  "const fixedTailAnswer: Nat := Indexed.head(0, Indexed.fixedTail(Indexed.two))\n" ++
  "const zeroCaseAnswer: Nat := Indexed.zeroOnly(Indexed.Vector.nil)\n" ++
  "const trueCaseAnswer: Nat := Indexed.trueOnly(Indexed.Flag.yes)\n" ++
  "const boolCaseAnswer: Nat := Indexed.boolBranch(false)\n" ++
  "const dependentRecursionAnswer: Nat := Indexed.head(1, Indexed.replace(2, Indexed.two, Indexed.two))\n" ++
  "const capturedFoldAnswer: Nat := Indexed.captured(2, Indexed.two)\n" ++
  "const computedFoldAnswer: Nat := Indexed.computedFold(100, 3)\n" ++
  "const localFoldAnswer: Nat := Indexed.localFold(100, 4)\n" ++
  "const nestedFoldAnswer: Nat := Indexed.nestedFold(4)\n" ++
  "const capturedMapAnswer: Nat := Indexed.head(1, Indexed.capturedMap(2, Indexed.two))\n" ++
  "function multi(a: Bool, b: Bool): Nat := match a, b with { | true, _ => 10 | _, true => 20 | _, _ => 30 }\n" ++
  "function nestedPattern(value: Option(Option Nat)): Nat := match value with { | .some (.some n) => n | .some .none => 4 | .none => 5 }\n" ++
  "function overlap(value: Option Nat, b: Bool): Nat := match value, b with { | .some n, true => n | .some m, _ => Nat.succ(m) | _, _ => 0 }\n" ++
  "function captureNames(a: Nat, b: Nat): Nat := match a, b with { | x, a => x }\n" ++
  "function tuplePattern(value: Prod Nat Nat): Nat := match value with { | (x, y) => x }\n" ++
  "function impossiblePair(n: Nat, value: Empty): Nat := nomatch n, value\n" ++
  "const matrixFirst: Nat := multi(true, true)\n" ++
  "const matrixSecond: Nat := multi(false, true)\n" ++
  "const matrixLast: Nat := multi(false, false)\n" ++
  "const nestedSome: Nat := nestedPattern(Option.some(Option.some(113)))\n" ++
  "const nestedNone: Nat := nestedPattern(Option.some(Option.none))\n" ++
  "const nestedEmpty: Nat := nestedPattern(Option.none)\n" ++
  "const overlapFirst: Nat := overlap(Option.some(115), true)\n" ++
  "const overlapSecond: Nat := overlap(Option.some(115), false)\n" ++
  "const matrixCapture: Nat := captureNames(117, 0)\n" ++
  "const tupleAnswer: Nat := tuplePattern(Prod.mk(118, 0))\n" ++
  "const nestedTail: Nat := Indexed.zeroOnly(Indexed.twoTail(0, Indexed.two))\n" ++
  "const matrixIndexed: Nat := Indexed.multiIndexed(2, Indexed.two)\n" ++
  "function ifPattern(value: Option Nat): Nat := if let .some n := value { n } else { 0 }\n" ++
  "function letPattern(value: Prod Nat Nat): Nat := {\n  let (first, second) := value\n  first\n}\n" ++
  "function inferredPattern(value: Option Nat): Nat := {\n  let result := match value with { | .some n => n | .none => 0 }\n  result\n}\n" ++
  "function ifPatternScope(value: Option Nat, n: Nat): Nat := if let .some n := value { n } else { n }\n" ++
  "function isNested(value: Option(Option Nat)): Bool := value matches .some (.some _)\n" ++
  "function inferredIfPattern(value: Option Nat): Nat := {\n  let result := if let .some n := value { n } else { 0 }\n  result\n}\n" ++
  "function dependentLet(value: Indexed.Vector(Nat, 1)): Nat := {\n  let .cons k head tail := value\n  head\n}\n" ++
  "function inferredLetPattern(value: Prod Nat Nat): Nat := {\n  let result := let (first, second) := value\n    second\n  result\n}\n" ++
  "const ifPatternSome: Nat := ifPattern(Option.some(121))\n" ++
  "const ifPatternNone: Nat := ifPattern(Option.none)\n" ++
  "const letPatternAnswer: Nat := letPattern(Prod.mk(122, 0))\n" ++
  "const inferredPatternAnswer: Nat := inferredPattern(Option.some(123))\n" ++
  "const patternScopeAnswer: Nat := ifPatternScope(Option.none, 124)\n" ++
  "const matchesYes: Bool := isNested(Option.some(Option.some(1)))\n" ++
  "const matchesNo: Bool := isNested(Option.some(Option.none))\n" ++
  "const inferredIfAnswer: Nat := inferredIfPattern(Option.some(125))\n" ++
  "const dependentLetAnswer: Nat := dependentLet(Indexed.one)\n" ++
  "const inferredLetAnswer: Nat := inferredLetPattern(Prod.mk(0, 126))\n" ++
  "structure CertifiedPair where {\n  before: True\n  first: Nat\n  certified: Eq(first, first)\n  second: Nat\n  after: True\n}\n" ++
  "const checkedPair: CertifiedPair := CertifiedPair.mk(True.intro, 131, Eq.refl(131), 132, True.intro)\n" ++
  "theorem checkedPairProof: Eq(checkedPair.first, checkedPair.first) := checkedPair.certified\n" ++
  "function proofRecord(value: CertifiedPair): Nat := match value with { | .mk _ first _ second _ => second }\n" ++
  "const proofProjectionAnswer: Nat := checkedPair.second\n" ++
  "const proofRecordAnswer: Nat := proofRecord(checkedPair)\n" ++
  "inductive CertifiedList where { | nil | cons(head: Nat, proof: True, tail: CertifiedList, after: True) }\n" ++
  "function certifiedCount(value: CertifiedList): Nat := match value with { | .nil => 0 | .cons _ _ tail _ => Nat.succ(certifiedCount(tail)) }\n" ++
  "const checkedList: CertifiedList := CertifiedList.cons(131, True.intro, CertifiedList.cons(132, True.intro, CertifiedList.nil, True.intro), True.intro)\n" ++
  "const proofRecursiveAnswer: Nat := certifiedCount(checkedList)\n" ++
  "const proofConstructor: True -> CertifiedList := CertifiedList.cons(133, True.intro, CertifiedList.nil)\n" ++
  "const proofPartialAnswer: Nat := certifiedCount(proofConstructor(True.intro))\n" ++
  "namespace Classes\n" ++
  "class Measure(A: Type) where {\n" ++
  "  measure: A -> Nat\n" ++
  "  law: True\n" ++
  "}\n" ++
  "instance (priority := low) lowNat: Measure Nat where {\n" ++
  "  measure(value: Nat): Nat := 140\n" ++
  "  law := True.intro\n" ++
  "}\n" ++
  "instance chosenNat: Measure Nat where {\n" ++
  "  measure(value: Nat): Nat := value\n" ++
  "  law := True.intro\n" ++
  "}\n" ++
  "instance (priority := high) cycle{A: Type}[Measure A]: Measure A where {\n" ++
  "  measure(value: A): Nat := Measure.measure(value)\n" ++
  "  law := True.intro\n" ++
  "}\n" ++
  "instance optionMeasure{A: Type}[Measure A]: Measure(Option A) where {\n" ++
  "  measure(value: Option A): Nat := match value with { | .none => 0 | .some n => Measure.measure(n) }\n" ++
  "  law := True.intro\n" ++
  "}\n" ++
  "function localFirst[chosen: Measure Nat](value: Nat): Nat := Measure.measure(value)\n" ++
  "const selected: Nat := Measure.measure(141)\n" ++
  "const nested: Nat := Measure.measure(Option.some(Option.some(142)))\n" ++
  "const local: Nat := localFirst(chosen := lowNat, value := 143)\n" ++
  "theorem lawful: True := Measure.law(A := Nat)\n" ++
  "const staticProjection: Nat := CertifiedPair.second(checkedPair)\n" ++
  "class Flag where { enabled: Bool }\n" ++
  "instance (priority := 777): Flag where { enabled := true }\n" ++
  "const anonymous: Bool := Flag.enabled\n" ++
  "end Classes\n" ++
  "namespace Waiters\n" ++
  "class A where { value: Nat }\n" ++
  "class B where { value: Nat }\n" ++
  "class Result where { value: Nat }\n" ++
  "instance seed: A where { value := 733 }\n" ++
  "instance (priority := high) fromB[B]: A where { value := B.value }\n" ++
  "instance fromA[A]: B where { value := A.value }\n" ++
  "instance combine[A][B]: Result where { value := Nat.add(A.value, B.value) }\n" ++
  "const result: Nat := Result.value\n" ++
  "end Waiters\n" ++
  "const instanceWaiterRuntime: Nat := Waiters.result\n" ++
  "const classSelected: Nat := Classes.selected\n" ++
  "const classNested: Nat := Classes.nested\n" ++
  "const classLocal: Nat := Classes.local\n" ++
  "const classStaticProjection: Nat := Classes.staticProjection\n" ++
  "const classAnonymous: Bool := Classes.anonymous\n" ++
  "function borrowedBeforeMove(value: Nat): Nat := value + keep(value)\n" ++
  "structure Callback where { run: Nat -> Nat }\n" ++
  "function makeCallback(base: Nat): Callback := { run := fun value => Nat.add(base, value) }\n" ++
  "function selectCallback(flag: Bool, base: Nat): Nat -> Nat := match flag with { | true => fun value => Nat.add(base, value) | false => fun value => value }\n" ++
  "const callback: Callback := makeCallback(150)\n" ++
  "const callbackFirst: Nat := callback.run(1)\n" ++
  "const callbackAgain: Nat := callback.run(2)\n" ++
  "const callbackChosen: Nat := selectCallback(true, 160)(3)\n" ++
  "function arrayAlias(seed: Nat): Nat := {\n  let original: Array Nat := #[seed,]\n  let changed: Array Nat := Array.push(original, 1)\n  Nat.add(Array.size(original), Array.size(changed))\n}\n" ++
  "const arrayAliasAnswer: Nat := arrayAlias(5)\n" ++
  "function buildArray(n: Nat, values: Array Nat): Array Nat := match n with { | 0 => values | k + 1 => buildArray(k, Array.push(values, k)) }\n" ++
  "const arrayBuiltSize: Nat := Array.size(buildArray(1000, #[]))\n" ++
  "const largeNatural: Nat := 18446744073709551617\n" ++
  "const saturatedNatural: Nat := Nat.sub(1, 9)\n" ++
  "const zeroDivision: Nat := Nat.div(7, 0)\n" ++
  "const unicodeLength: Nat := String.Internal.length(\"α🙂\")\n" ++
  "const unicodeBytes: Nat := String.utf8ByteSize(\"α🙂\")\n" ++
  "namespace Universes\n" ++
  "universe u v\n" ++
  "function keep(A: Type u, value: A): A := value\n" ++
  "function keepMax(A: Type (max u v), value: A): A := value\n" ++
  "function keepSort(A: Sort (imax u v), value: A): A := value\n" ++
  "function keepOffset(A: Type (u + 1), value: A): A := value\n" ++
  "function keepHole(A: Type _, value: A): A := value\n" ++
  "function commuted(A: Type (max u v), value: A): A := keepMax(A, value)\n" ++
  "inductive Bag(A: Type u): Type u where { | nil | cons(head: A, tail: Bag A) }\n" ++
  "function size(A: Type u, value: Bag A): Nat := match value with { | .nil => 0 | .cons head tail => Nat.succ(size(A, tail)) }\n" ++
  "structure Holder(A: Type u) where { value: A }\n" ++
  "class Echo(A: Type u) where { run: A -> A }\n" ++
  "instance every{A: Type u}: Echo A where { run(value: A): A := value }\n" ++
  "function reflected{A: Type u}(value: A): A := Echo.run(value)\n" ++
  "end Universes\n" ++
  "const universeIdentity: Nat := Universes.keep(Nat, 201)\n" ++
  "const universeHole: Nat := Universes.keepHole(Nat, 202)\n" ++
  "const universeSize: Nat := Universes.size(Nat, Universes.Bag.cons(203, Universes.Bag.nil))\n" ++
  "const universeProjection: Nat := Universes.Holder.value(Universes.Holder.mk(204))\n" ++
  "const universeInstance: Nat := Universes.reflected(205)\n" ++
  "theorem tacticIdentity(P: Prop): P -> P := by {\n  intro h\n  exact h\n}\n" ++
  "theorem tacticApply(P: Prop, Q: Prop, step: P -> Q, h: P): Q := by {\n  apply step\n  assumption\n}\n" ++
  "theorem tacticRefine(P: Prop, h: P): P := by {\n  refine tacticIdentity(P, _)\n  exact h\n}\n" ++
  "theorem tacticRfl(n: Nat): n = n := by { rfl }\n" ++
  "theorem tacticTrue: True := by { constructor }\n" ++
  "function tacticPair(value: Nat): Prod Nat Nat := by {\n  constructor\n  · exact value\n  · exact value\n}\n" ++
  "function tacticShadow(value: Nat): Nat -> Nat := by {\n  intro value\n  exact value\n}\n" ++
  "const tacticPairAnswer: Nat := Prod.fst(tacticPair(211))\n" ++
  "const tacticShadowAnswer: Nat := tacticShadow(0)(212)\n" ++
  "function tacticMixed(value: Nat): Prod Nat Bool := by {\n  constructor\n  any_goals exact value\n  all_goals constructor\n}\n" ++
  "const tacticMixedNat: Nat := Prod.fst(tacticMixed(213))\n" ++
  "const tacticMixedBool: Bool := Prod.snd(tacticMixed(214))\n" ++
  "theorem andProof(P: Prop, Q: Prop, hp: P, hq: Q): P ∧ Q := by {\n  constructor\n  · exact hp\n  · exact hq\n}\n" ++
  "theorem andProjection(P: Prop, Q: Prop, h: P ∧ Q): P := h.left\n" ++
  "theorem orProof(P: Prop, Q: Prop, hp: P): P ∨ Q := Or.inl(hp)\n" ++
  "theorem existsProof(n: Nat): Exists(fun (x: Nat) => Eq(x, x)) := by {\n  refine Exists.intro(n, _)\n  rfl\n}\n" ++
  "theorem iffProof(P: Prop): P ↔ P := by {\n  constructor\n  all_goals intro h\n  all_goals assumption\n}\n" ++
  "theorem notFalse: ¬ False := by {\n  intro h\n  exact h\n}\n" ++
  "theorem logicalPrecedence(P: Prop, Q: Prop, R: Prop, h: P ∧ Q ∨ R): (P ∧ Q) ∨ R := h\n" ++
  "theorem andAssociativity(P: Prop, Q: Prop, R: Prop, h: P ∧ Q ∧ R): P ∧ (Q ∧ R) := h\n" ++
  "theorem implicationPrecedence(P: Prop, Q: Prop): P -> Q ↔ (P -> Q) := by {\n  constructor\n  all_goals intro h\n  all_goals assumption\n}\n" ++
  "theorem logicalAliases(P: Prop, Q: Prop, h: P /\\ Q): P \\/ Q := Or.inl(h.left)\n" ++
  "theorem iffAlias(P: Prop): P <-> P := iffProof(P)\n" ++
  "theorem termFact(P: Prop, h: P): P := {\n  have local: P := h\n  show P from local\n}\n" ++
  "theorem nestedFact(n: Nat): n = n := by {\n  have equality: n = n := by { rfl }\n  change Eq(n, n)\n  exact equality\n}\n" ++
  "theorem selectGoal(P: Prop, Q: Prop, hp: P, hq: Q): P ∧ Q := by {\n  constructor\n  show Q\n  exact hq\n  show P\n  exact hp\n}\n" ++
  "theorem localDefinition: 3 = 3 := by {\n  let x: Nat := 3\n  change x = 3\n  rfl\n}\n" ++
  "function savedFact(value: Nat): Nat -> Nat := by {\n  have saved: Nat := value\n  intro delta\n  exact Nat.add(saved, delta)\n}\n" ++
  "theorem savedFactValue: savedFact(217)(1) = 218 := by { rfl }\n" ++
  "theorem namedWitness(n: Nat): ∃ x: Nat, x = n := by {\n  refine Exists.intro(n, _)\n  rfl\n}\n" ++
  "theorem inferredWitness(n: Nat): exists x, x = n := namedWitness(n)\n" ++
  "theorem doubleWitness: ∃ (x y: Nat), x = y := by {\n  refine Exists.intro(0, Exists.intro(0, _))\n  rfl\n}\n" ++
  "theorem anonymousFact(P: Prop, h: P): P := by {\n  have : P := h\n  exact this\n}\n" ++
  "theorem termShow(n: Nat): n = n := show n = n by { rfl }\n" ++
  "theorem naturalComputation: Nat.mul(Nat.add(2, 3), Nat.sub(9, 7)) = 10 := by { rfl }\n" ++
  "theorem naturalDivision: Nat.div(7, 0) = 0 ∧ Nat.mod(7, 0) = 7 := by {\n  constructor\n  all_goals rfl\n}\n" ++
  "theorem naturalComparison: Nat.beq(3, 3) = true ∧ Nat.ble(4, 3) = false := by {\n  constructor\n  all_goals rfl\n}\n" ++
  "namespace Predicates\n" ++
  "inductive Evidence(P: Prop): Prop where { | intro(proof: P) }\n" ++
  "theorem evidence(P: Prop, h: P): Evidence P := by {\n  constructor\n  assumption\n}\n" ++
  "theorem recover(P: Prop, h: Evidence P): P := match h with { | .intro proof => proof }\n" ++
  "function fixed(h: Evidence True): Nat := match h with { | .intro proof => 231 }\n" ++
  "inductive Secret: Prop where { | hide(value: Nat) }\n" ++
  "theorem secret(n: Nat): Secret := Secret.hide(n)\n" ++
  "theorem secretTrue(h: Secret): True := match h with { | .hide value => True.intro }\n" ++
  "inductive Choice(P: Prop, Q: Prop): Prop where { | left(proof: P) | right(proof: Q) }\n" ++
  "theorem choose(P: Prop, Q: Prop, h: Choice(P, Q)): P ∨ Q := match h with { | .left hp => Or.inl(hp) | .right hq => Or.inr(hq) }\n" ++
  "inductive Impossible: Prop where { }\n" ++
  "function absurd(h: Impossible): Nat := nomatch h\n" ++
  "inductive Indexed: Nat -> Prop where { | intro(n: Nat): Indexed(n) }\n" ++
  "theorem indexed(n: Nat, h: Indexed(n)): True := match h with { | .intro m => True.intro }\n" ++
  "end Predicates\n" ++
  "const proofFamilyAnswer: Nat := Predicates.fixed(Predicates.Evidence.intro(True.intro))\n" ++
  "const savedFactAnswer: Nat := savedFact(217)(1)\n" ++
  "structure PropositionBox(P: Prop): Prop where { proof: P }\n" ++
  "theorem propositionRecord(P: Prop, h: P): PropositionBox P := { proof := h }\n" ++
  "theorem propositionProjection(P: Prop, h: PropositionBox P): P := h.proof\n" ++
  "class PropositionClass(P: Prop): Prop where { hold: P }\n" ++
  "instance trueClass: PropositionClass True where { hold := True.intro }\n" ++
  "theorem propositionInstance: True := PropositionClass.hold(P := True)\n" ++
  "structure ExplicitHigh(A: Type): Type 1 where { value: A }\n" ++
  "const explicitHighAnswer: Nat := ExplicitHigh.value(ExplicitHigh.mk(241))\n" ++
  "namespace Updates\n" ++
  "structure Pair where {\n  first: Nat\n  second: Nat\n}\n" ++
  "function change(source: Pair, value: Nat): Pair := { source with second := value, }\n" ++
  "function keep(source: Pair): Pair := {\n  { source with }\n}\n" ++
  "const original: Pair := { first := 251, second := 252 }\n" ++
  "const changed: Pair := change(original, 253)\n" ++
  "const inferred: Nat := {\n  let pair := { changed with second := 254 }\n  pair.second\n}\n" ++
  "const copied: Pair := keep(changed)\n" ++
  "function adjust(source: CertifiedPair): CertifiedPair := { source with certified := by { rfl }, first := 255 }\n" ++
  "const dependent: CertifiedPair := adjust(checkedPair)\n" ++
  "function replace{A: Type}(source: Universes.Holder(A), value: A): Universes.Holder(A) := { source with value := value }\n" ++
  "const generic: Universes.Holder Nat := replace(Universes.Holder.mk(256), 257)\n" ++
  "theorem proofUpdate(P: Prop, source: PropositionBox P, h: P): PropositionBox P := { source with proof := h }\n" ++
  "end Updates\n" ++
  "const updateFirst: Nat := Updates.changed.first\n" ++
  "const updateSecond: Nat := Updates.copied.second\n" ++
  "const updateInferred: Nat := Updates.inferred\n" ++
  "const updateDependent: Nat := Updates.dependent.first\n" ++
  "const updateGeneric: Nat := Updates.generic.value\n" ++
  "const delayedLambda: Nat -> Nat := by {\n  refine (fun (n: Nat) => _)\n  exact n\n}\n" ++
  "const delayedLet: Nat := by {\n  refine (let n: Nat := 261\n    _)\n  exact n\n}\n" ++
  "theorem delayedHave(P: Prop, h: P): P := by {\n  refine (have saved: P := h\n    _)\n  exact saved\n}\n" ++
  "theorem delayedNested: forall (P: Prop), P -> P := by {\n  refine (fun (P: Prop) => fun (h: P) => _)\n  exact h\n}\n" ++
  "function delayedUpdate(source: CertifiedPair): CertifiedPair := by {\n  refine { source with first := 263, certified := _ }\n  rfl\n}\n" ++
  "const delayedLambdaAnswer: Nat := delayedLambda(262)\n" ++
  "const delayedUpdateAnswer: Nat := CertifiedPair.first(delayedUpdate(checkedPair))\n" ++
  "function delayedMatch(value: Option Nat): Nat := by {\n  refine (match value with { | .none => 264 | .some n => _ })\n  exact n\n}\n" ++
  "function delayedTail(n: Nat, value: Indexed.Vector(Nat, Nat.succ(n))): Indexed.Vector(Nat, n) := by {\n  refine (match value with { | .cons k head tail => _ })\n  exact tail\n}\n" ++
  "function delayedContext(n: Nat, value: Indexed.Vector(Nat, n), other: Indexed.Vector(Nat, n)): Indexed.Vector(Nat, n) := by {\n  refine (match value with { | .nil => _ | .cons k head tail => _ })\n  · exact other\n  · exact other\n}\n" ++
  "function delayedComputed(value: Nat): Nat := by {\n  refine (match Option.some(value) with { | .none => 0 | .some n => _ })\n  exact n\n}\n" ++
  "const delayedMatchAnswer: Nat := delayedMatch(Option.some(265))\n" ++
  "const delayedTailAnswer: Nat := Indexed.head(0, delayedTail(1, Indexed.two))\n" ++
  "const delayedContextAnswer: Nat := Indexed.head(0, delayedContext(1, Indexed.one, Indexed.one))\n" ++
  "const delayedComputedAnswer: Nat := delayedComputed(266)\n" ++
  "function eliminationCount(n: Nat): Nat := by {\n  induction n\n  case zero => exact 0\n  case succ k ih => exact Nat.succ(ih)\n}\n" ++
  "function casesPred(n: Nat): Nat := by {\n  cases n\n  case zero => exact 0\n  case succ k => exact k\n}\n" ++
  "theorem inductionTrue(n: Nat): True := by {\n  induction n\n  case zero => constructor\n  case succ k ih => exact ih\n}\n" ++
  "theorem casesSwap(P: Prop, Q: Prop, h: P \\/ Q): Q \\/ P := by {\n  cases h\n  case inl hp => exact Or.inr(hp)\n  case inr hq => exact Or.inl(hq)\n}\n" ++
  "theorem nextPair(P: Prop, Q: Prop, hp: P, hq: Q): P /\\ Q := by {\n  constructor\n  next => exact hp\n  next => exact hq\n}\n" ++
  "function casesTail(n: Nat, value: Indexed.Vector(Nat, Nat.succ(n))): Indexed.Vector(Nat, n) := by {\n  cases value\n  case cons k head tail => exact tail\n}\n" ++
  "function casesContext(n: Nat, value: Indexed.Vector(Nat, n), other: Indexed.Vector(Nat, n)): Indexed.Vector(Nat, n) := by {\n  cases value\n  case nil => exact other\n  case cons k head tail => exact other\n}\n" ++
  "function casesEmpty(value: Empty): Nat := by {\n  cases value\n}\n" ++
  "const eliminationCountAnswer: Nat := eliminationCount(271)\n" ++
  "const casesPredAnswer: Nat := casesPred(272)\n" ++
  "const casesTailAnswer: Nat := Indexed.head(0, casesTail(1, Indexed.two))\n" ++
  "const casesContextAnswer: Nat := Indexed.head(0, casesContext(1, Indexed.one, Indexed.one))\n" ++
  "const decisionYes: Decidable True := Decidable.isTrue(True.intro)\n" ++
  "const decisionNo: Decidable False := Decidable.isFalse(fun h => h)\n" ++
  "function decisionChoose{P: Prop}[decision: Decidable P](yes: Nat, no: Nat): Nat := if (P) { yes } else { no }\n" ++
  "function proofChoose{P: Prop}[decision: Decidable P](yes: P -> Nat, no: (¬P) -> Nat): Nat := if (h : P) { yes(h) } else { no(h) }\n" ++
  "function equalityChoose(n: Nat): Nat := if (n = 0) { 283 } else { 284 }\n" ++
  "const decisionTrueAnswer: Nat := decisionChoose(P := True, decision := decisionYes, yes := 281, no := 0)\n" ++
  "const decisionFalseAnswer: Nat := decisionChoose(P := False, decision := decisionNo, yes := 0, no := 282)\n" ++
  "const decisionEqualAnswer: Nat := equalityChoose(0)\n" ++
  "const decisionDifferentAnswer: Nat := equalityChoose(1)\n" ++
  "const decisionStringAnswer: Nat := if (\"αβ\" = \"αβ\") { 285 } else { 0 }\n" ++
  "const proofTrueAnswer: Nat := proofChoose(P := True, decision := decisionYes, yes := fun h => 286, no := fun h => 0)\n" ++
  "const proofFalseAnswer: Nat := proofChoose(P := False, decision := decisionNo, yes := fun h => 0, no := fun h => 287)\n" ++
  "function refineConditional{P: Prop}[decision: Decidable P](yes: P -> Nat, no: (¬P) -> Nat): Nat := by {\n  refine (if (h : P) { _ } else { _ })\n  · exact yes(h)\n  · exact no(h)\n}\n" ++
  "const refineConditionalAnswer: Nat := refineConditional(P := True, decision := decisionYes, yes := fun h => 288, no := fun h => 0)\n" ++
  "theorem conditionalExcluded(P: Prop)[Decidable P]: P ∨ ¬P := if (h : P) { Or.inl(h) } else { Or.inr(h) }\n" ++
  "namespace Outputs\n" ++
  "universe a b\n" ++
  "class Convert(A: Type a, B: outParam(Type b)): Type (max a b) where { run: A -> B }\n" ++
  "instance nat: Convert Nat Nat where { run(n: Nat): Nat := Nat.succ(n) }\n" ++
  "instance flag: Convert Bool Nat where { run(value: Bool): Nat := if (value) { 292 } else { 293 } }\n" ++
  "class Lift(A: Type a, B: outParam(Type b)): Type (max a b) where { run: A -> B }\n" ++
  "instance lifted{A: Type a}{B: Type b}[Convert A B]: Lift A B where { run(value: A): B := Convert.run(value) }\n" ++
  "function local{A: Type a}{B: Type b}[Convert A B](value: A): B := {\n  let converted := Convert.run(value)\n  converted\n}\n" ++
  "const inferred: Nat := {\n  let converted := Convert.run(290)\n  converted\n}\n" ++
  "const localAnswer: Nat := local(true)\n" ++
  "const flagAnswer: Nat := Convert.run(false)\n" ++
  "const nested: Nat := {\n  let converted := Lift.run(294)\n  converted\n}\n" ++
  "end Outputs\n" ++
  "const outputInferredAnswer: Nat := Outputs.inferred\n" ++
  "const outputLocalAnswer: Nat := Outputs.localAnswer\n" ++
  "const outputFlagAnswer: Nat := Outputs.flagAnswer\n" ++
  "const outputNestedAnswer: Nat := Outputs.nested\n" ++
  "abbrev IdentityType(A: Type): Type := A\n" ++
  "const aliasAnswer: IdentityType Nat := 318\n" ++
  "namespace DoCore\nfunction pair(value: Nat): Except(String, Nat × Nat) := do {\n  return (value, Nat.add(value, 1))\n}\nfunction flow(flag: Bool, fail: Bool): Except String Nat := do {\n  let base: Nat := 300\n  if (flag) {\n    return base\n  }\n  let (left, right) ← pair(base)\n  let _: Unit ← if (fail) { Except.error(\"stopped\") } else { Except.ok(()) }\n  return Nat.add(left, right)\n}\nfunction read(value: Except String Nat): Nat :=\n  match value with { | .error _ => 399 | .ok n => n }\nfunction optionFlow(found: Bool): Option Nat := do {\n  let n: Nat ← if (found) { Option.some(302) } else { Option.none }\n  if let .some extra := Option.some(2) {\n    return Nat.add(n, extra)\n  }\n  return 0\n}\nfunction readOption(value: Option Nat): Nat :=\n  match value with { | .none => 398 | .some n => n }\nfunction Identity(A: Type): Type := Id A\nfunction identityFlow(flag: Bool): Identity Nat := do {\n  let x: Nat ← do {\n    return 303\n  }\n  if (h : flag) {\n    let proof: flag = true := h\n    return x\n  }\n  let (a, b): Nat × Nat := (x, 2)\n  return Nat.add(a, b)\n}\nfunction identityOption(flag: Bool): Id(Option Nat) := do {\n  if (flag) {\n    return Option.some(306)\n  }\n  return Option.none\n}\nfunction ignoredUnit(flag: Bool): Except String Nat := do {\n  if (flag) {\n    Except.ok(())\n    Except.ok(())\n  }\n  return 307\n}\nend DoCore\nconst doEarlyAnswer: Nat := DoCore.read(DoCore.flow(true, false))\nconst doBindAnswer: Nat := DoCore.read(DoCore.flow(false, false))\nconst doErrorAnswer: Nat := DoCore.read(DoCore.flow(false, true))\nconst doOptionAnswer: Nat := DoCore.readOption(DoCore.optionFlow(true))\nconst doNoneAnswer: Nat := DoCore.readOption(DoCore.optionFlow(false))\nconst doIdentityEarly: Nat := DoCore.identityFlow(true)\nconst doIdentityTail: Nat := DoCore.identityFlow(false)\nconst doIdentityOption: Nat := DoCore.readOption(DoCore.identityOption(true))\nconst doIgnoredUnit: Nat := DoCore.read(DoCore.ignoredUnit(true))\n" ++
  -- Exercise exactly the same checked dependent dictionary across JS, TS,
  -- Rust, Wasm GC and Component observation pipelines, not just emission.
  "namespace ProofIndexRuntime\n" ++
  "structure IndexBox where { value: Nat }\n" ++
  "instance indexGet: GetElem(IndexBox, Nat, Nat, fun (_: IndexBox) => fun (i: Nat) => i = 0) where {\n" ++
  "  getElem(xs: IndexBox, i: Nat, h: i = 0): Nat := xs.value\n" ++
  "}\n" ++
  "function atZero(xs: IndexBox): Nat := xs[0]\n" ++
  "function atExplicit(xs: IndexBox, i: Nat, h: i = 0): Nat := xs[i]'h\n" ++
  "function atAssumed(xs: IndexBox, i: Nat, h: i = 0): Nat := xs[i]\n" ++
  "structure AlwaysBox where { value: Nat }\n" ++
  "instance alwaysGet: GetElem(AlwaysBox, Nat, Nat, fun (_: AlwaysBox) => fun (_: Nat) => True) where {\n" ++
  "  getElem(xs: AlwaysBox, i: Nat, h: True): Nat := xs.value\n" ++
  "}\n" ++
  "function alwaysAt(xs: AlwaysBox): Nat := xs[42]\n" ++
  "instance alwaysOptional: GetElem?(AlwaysBox, Nat, Nat, fun (_: AlwaysBox) => fun (_: Nat) => True) where {\n" ++
  "  toGetElem := alwaysGet\n" ++
  "  getElem?(xs: AlwaysBox, i: Nat): Option Nat := Option.some(xs.value)\n" ++
  "  getElem![inhabited: Inhabited Nat](xs: AlwaysBox, i: Nat): Nat := GetElem?.getElem!Default(Option.some(xs.value))\n" ++
  "}\n" ++
  "function atOptional(xs: AlwaysBox): Nat := Option.getD(xs[42]?, 0)\n" ++
  "function atBang(xs: AlwaysBox): Nat := xs[42]!\n" ++
  "structure AndBox where { value: Nat }\n" ++
  "instance andGet: GetElem(AndBox, Nat, Nat, fun (_: AndBox) => fun (_: Nat) => True ∧ True) where {\n" ++
  "  getElem(xs: AndBox, i: Nat, h: True ∧ True): Nat := xs.value\n" ++
  "}\n" ++
  "function andAt(xs: AndBox): Nat := xs[42]\n" ++
  "end ProofIndexRuntime\n" ++
  "const indexZeroRuntime: Nat := ProofIndexRuntime.atZero(ProofIndexRuntime.IndexBox.mk(311))\n" ++
  "const indexExplicitRuntime: Nat := ProofIndexRuntime.atExplicit(ProofIndexRuntime.IndexBox.mk(313), 0, by { rfl })\n" ++
  "const indexAssumedRuntime: Nat := ProofIndexRuntime.atAssumed(ProofIndexRuntime.IndexBox.mk(317), 0, by { rfl })\n" ++
  "const indexTrueRuntime: Nat := ProofIndexRuntime.alwaysAt(ProofIndexRuntime.AlwaysBox.mk(319))\n" ++
  "const indexOptionalRuntime: Nat := ProofIndexRuntime.atOptional(ProofIndexRuntime.AlwaysBox.mk(327))\n" ++
  "const indexBangRuntime: Nat := ProofIndexRuntime.atBang(ProofIndexRuntime.AlwaysBox.mk(329))\n" ++
  "const indexAndRuntime: Nat := ProofIndexRuntime.andAt(ProofIndexRuntime.AndBox.mk(323))\n" ++
  -- Prove that the low-priority optional dictionary is derivable without a
  -- user-defined GetElem? instance, using real dependent True/False evidence.
  "namespace DerivedIndex\n" ++
  "structure Positive where { value: Nat }\n" ++
  "instance positiveGet: GetElem(Positive, Nat, Nat, fun (_: Positive) => fun (_: Nat) => True) where {\n" ++
  "  getElem(xs: Positive, i: Nat, h: True): Nat := xs.value\n" ++
  "}\n" ++
  -- The checked generic coherence lemma is an ordinary source-level theorem,
  -- not an axiom claiming arbitrary user-defined GetElem? instances lawful.
  "theorem decidableCoherence(P: Prop, left: Decidable P, right: Decidable P): left = right := PsStandard.decidableUnique(P, left, right)\n" ++
  "function opt(xs: Positive): Nat := Option.getD(xs[99]?, 0)\n" ++
  "function bang(xs: Positive): Nat := xs[99]!\n" ++
  "structure Negative where { value: Nat }\n" ++
  "instance negativeGet: GetElem(Negative, Nat, Nat, fun (_: Negative) => fun (_: Nat) => False) where {\n" ++
  "  getElem(xs: Negative, i: Nat, h: False): Nat := xs.value\n" ++
  "}\n" ++
  "function absent(xs: Negative): Bool := Option.isNone(xs[0]?)\n" ++
  "end DerivedIndex\n" ++
  "const derivedPositiveRuntime: Nat := DerivedIndex.opt(DerivedIndex.Positive.mk(347))\n" ++
  "const derivedBangRuntime: Nat := DerivedIndex.bang(DerivedIndex.Positive.mk(349))\n" ++
  "const derivedNegativeRuntime: Bool := DerivedIndex.absent(DerivedIndex.Negative.mk(351))\n" ++
  "const bangDefaultValue: Nat := GetElem?.getElem!Default(Option.some(337))\n" ++
  "function bangDefaultTrap(n: Nat): Nat := GetElem?.getElem!Default((Option.none : Option Nat))\n" ++
  "function orderLeRuntime(n: Nat, m: Nat): Bool := if (Nat.le(n, m)) { true } else { false }\n" ++
  "function orderLtRuntime(n: Nat, m: Nat): Bool := if (Nat.lt(n, m)) { true } else { false }\n" ++
  "function decisionFlag{P: Prop}(decision: Decidable P): Bool := by {\n  cases decision\n  case intro flag reflection => exact flag\n}\n" ++
  "function orderDecisionRuntime(n: Nat, m: Nat): Bool := decisionFlag(Nat.decLe(n, m))\n" ++
  "namespace DerivingParameters\n" ++
  "universe u v\n" ++
  "inductive Choice(A: Type u): Type u where { | value(payload: A) | empty } deriving Inhabited, BEq\n" ++
  "structure Pair(A: Type u, B: Type v) where {\n" ++
  "  first: A\n" ++
  "  second: B\n" ++
  "} deriving Inhabited, BEq\n" ++
  "structure Phantom(A: Type u, B: Type v) where { value: A } deriving Inhabited\n" ++
  "structure Tagged(A: Type u, n: Nat): Type u where { value: A } deriving Inhabited, BEq\n" ++
  "structure Lift(A: Type): Type 1 where { value: A } deriving Inhabited, BEq\n" ++
  "structure SortBox(A: Sort u) where { value: A } deriving Inhabited\n" ++
  "structure Nested(A: Type u): Type u where { value: Option A } deriving Inhabited, BEq\n" ++
  "function defaultChoice{A: Type u}(unit: Unit): Choice A := Inhabited.default\n" ++
  "function defaultPhantom{A: Type u}{B: Type v}[Inhabited A](unit: Unit): Phantom(A, B) := Inhabited.default\n" ++
  "function defaultSort{A: Sort u}[Inhabited A](unit: Unit): SortBox A := Inhabited.default\n" ++
  "theorem choiceDefault{A: Type u}: defaultChoice(A := A, unit := ()) = Choice.empty := by { rfl }\n" ++
  "theorem phantomDefault{A: Type u}{B: Type v}[Inhabited A]: Phantom.value(defaultPhantom(A := A, B := B, unit := ())) = (Inhabited.default : A) := by { rfl }\n" ++
  "theorem nestedDefault{A: Type u}: Nested.value((Inhabited.default : Nested A)) = (Option.none : Option A) := by { rfl }\n" ++
  "end DerivingParameters\n" ++
  "const derivingMinimalRuntime: Bool := match DerivingParameters.defaultChoice(A := Empty, unit := ()) with { | .value value => nomatch value | .empty => true }\n" ++
  "const derivingPhantomRuntime: Nat := DerivingParameters.Phantom.value(DerivingParameters.defaultPhantom(A := Nat, B := Empty, unit := ()))\n" ++
  "const derivingHighDefault: DerivingParameters.Pair(DerivingParameters.Lift Nat, Nat) := Inhabited.default\n" ++
  "const derivingHighDefaultRuntime: Nat := DerivingParameters.Lift.value(derivingHighDefault.first)\n" ++
  "const derivingNested: DerivingParameters.Nested(DerivingParameters.Lift Nat) := DerivingParameters.Nested.mk(Option.some(DerivingParameters.Lift.mk(761)))\n" ++
  "const derivingNestedProjection: Option(DerivingParameters.Lift Nat) := derivingNested.value\n" ++
  "const derivingNestedRuntime: Nat := DerivingParameters.Lift.value(Option.getD(derivingNestedProjection, DerivingParameters.Lift.mk(0)))\n" ++
  "theorem derivingNestedProof: derivingNestedRuntime = 761 := by { rfl }\n" ++
  "const derivingHighEqualRuntime: Bool := DerivingParameters.Pair.mk(DerivingParameters.Lift.mk(751), 3) == DerivingParameters.Pair.mk(DerivingParameters.Lift.mk(751), 3)\n" ++
  "const derivingHighUnequalRuntime: Bool := DerivingParameters.Pair.mk(DerivingParameters.Lift.mk(751), 3) == DerivingParameters.Pair.mk(DerivingParameters.Lift.mk(751), 4)\n" ++
  "const derivingPayloadEqualRuntime: Bool := DerivingParameters.Choice.value(DerivingParameters.Lift.mk(757)) == DerivingParameters.Choice.value(DerivingParameters.Lift.mk(757))\n" ++
  "const derivingPayloadTagRuntime: Bool := DerivingParameters.Choice.value(DerivingParameters.Lift.mk(757)) == DerivingParameters.Choice.empty\n" ++
  "const derivingValueParamRuntime: Bool := DerivingParameters.Tagged.mk(A := Nat, n := 7, value := 5) == DerivingParameters.Tagged.mk(A := Nat, n := 7, value := 5)\n" ++
  "theorem derivingHighDefaultProof: derivingHighDefaultRuntime = 0 := by { rfl }\n" ++
  "theorem derivingHighEqualProof: derivingHighEqualRuntime = true := by { rfl }\n" ++
  "theorem derivingHighUnequalProof: derivingHighUnequalRuntime = false := by { rfl }\n" ++
  "theorem derivingPayloadEqualProof: derivingPayloadEqualRuntime = true := by { rfl }\n" ++
  "theorem derivingPayloadTagProof: derivingPayloadTagRuntime = false := by { rfl }\n" ++
  "namespace M1Universes\n" ++
  "universe u v\n" ++
  "structure Box(A: Type u): Type u where { value: A }\n" ++
  "instance boxed{A: Type u}: GetElem(Box A, Nat, A, fun (_: Box A) => fun (_: Nat) => True) where {\n" ++
  "  getElem(xs: Box A, i: Nat, h: True): A := xs.value\n" ++
  "}\n" ++
  "function lookup{A: Type u}(xs: Box A): Option A := xs[0]?\n" ++
  "function requireLaw{A: Type u}[LawfulGetElem(Box A, Nat, A, fun (_: Box A) => fun (_: Nat) => True)](xs: Box A): Nat := 1\n" ++
  "function bindMap{A: Type u}{B: Type u}(f: A -> B, xs: Option A): Option B := do {\n" ++
  "  let x: A ← xs\n" ++
  "  return f(x)\n" ++
  "}\n" ++
  "function defaultOption{A: Type u}(unit: Unit): Option A := Inhabited.default\n" ++
  "end M1Universes\n" ++
  "function highRead(xs: Option(ExplicitHigh Nat)): Nat := ExplicitHigh.value(Option.getD(xs, ExplicitHigh.mk(0)))\n" ++
  "instance highNatBEq: BEq(ExplicitHigh Nat) where { beq(left: ExplicitHigh Nat, right: ExplicitHigh Nat): Bool := left.value == right.value }\n" ++
  "const highBEqRuntime: Bool := Option.some(ExplicitHigh.mk(397)) == Option.some(ExplicitHigh.mk(397))\n" ++
  "const highOptionalRuntime: Nat := highRead(M1Universes.lookup(M1Universes.Box.mk(ExplicitHigh.mk(359))))\n" ++
  "const highMapRuntime: Nat := highRead(Option.map(fun n => ExplicitHigh.mk(n), Option.some(367)))\n" ++
  "const highDoRuntime: Nat := highRead(M1Universes.bindMap(fun value => value, Option.some(ExplicitHigh.mk(373))))\n" ++
  "const highNoneRuntime: Bool := Option.isNone((Option.none : Option(ExplicitHigh Nat)))\n" ++
  "const highDefaultRuntime: Bool := Option.isNone(M1Universes.defaultOption(A := ExplicitHigh Nat, unit := ()))\n" ++
  "const highLawfulRuntime: Nat := M1Universes.requireLaw(M1Universes.Box.mk(ExplicitHigh.mk(379)))\n" ++
  "structure BoundedBox where {\n  value: Nat\n  size: Nat\n}\n" ++
  "instance boundedBoxGet: GetElem(BoundedBox, Nat, Nat, fun (xs: BoundedBox) => fun (i: Nat) => Nat.lt(i, xs.size)) where {\n" ++
  "  getElem(xs: BoundedBox, i: Nat, h: Nat.lt(i, xs.size)): Nat := xs.value\n" ++
  "}\n" ++
  "function boundedByChain(xs: BoundedBox, i: Nat, j: Nat, h: Nat.lt(i, j), k: Nat.le(j, xs.size)): Nat := xs[i]\n" ++
  "const bigBoundIndexRuntime: Nat := (BoundedBox.mk(383, 184467440737095516171))[184467440737095516170]\n" ++
  "const symbolicBoundRuntime: Nat := boundedByChain(BoundedBox.mk(389, 5), 1, 3, PsStandard.natBleReflects(2, 3), PsStandard.natBleReflects(3, 5))\n" ++
  "function listChecked(xs: List Nat, i: Nat, h: Nat.lt(i, List.length(xs))): Nat := xs[i]\n" ++
  "function listFinChecked(xs: List Nat, i: Fin(List.length(xs))): Nat := List.get(xs, i)\n" ++
  "function listLawful[LawfulGetElem(List Nat, Nat, Nat, fun xs => fun i => Nat.lt(i, List.length(xs)))](xs: List Nat): Nat := List.length(xs)\n" ++
  "function finLawful{n: Nat}[LawfulGetElem(List Nat, Fin n, Nat, fun xs => fun i => Nat.lt(Fin.val(i), List.length(xs)))](xs: List Nat): Nat := List.length(xs)\n" ++
  "const listProofRuntime: Nat := listChecked([401, 409], 1, PsStandard.natBleReflects(2, 2))\n" ++
  "const listAutoRuntime: Nat := [419, 421][1]\n" ++
  "const listOptionalRuntime: Nat := Option.getD([431, 433][1]?, 0)\n" ++
  "const listBangRuntime: Nat := [439, 443][1]!\n" ++
  "const listEmptyRuntime: Bool := Option.isNone(([] : List Nat)[0]?)\n" ++
  "const listHugeRuntime: Bool := Option.isNone([449][184467440737095516170]?)\n" ++
  "const listLawfulRuntime: Nat := listLawful([457, 461])\n" ++
  "const finIndexSeed: Fin(10) := Fin.mk(1, PsStandard.natBleReflects(2, 10))\n" ++
  "const finOptionalRuntime: Nat := Option.getD([463, 467][finIndexSeed]?, 0)\n" ++
  "const finMismatchRuntime: Bool := Option.isNone([479][finIndexSeed]?)\n" ++
  "const finProofRuntime: Nat := [487, 491][finIndexSeed]\n" ++
  "const finLawfulRuntime: Nat := finLawful(n := 10, xs := [499, 503])\n" ++
  "const finListGetRuntime: Nat := listFinChecked([509, 521], Fin.mk(1, PsStandard.natBleReflects(2, 2)))\n" ++
  "function listBangPanic(unit: Nat): Nat := ([] : List Nat)[0]!\n" ++
  "function finBangPanic(unit: Nat): Nat := [523][finIndexSeed]!\n" ++
  "function arrayChecked(xs: Array Nat, i: Nat, h: Nat.lt(i, Array.size(xs))): Nat := xs[i]\n" ++
  "function arrayLawful[LawfulGetElem(Array Nat, Nat, Nat, fun xs => fun i => Nat.lt(i, Array.size(xs)))](xs: Array Nat): Nat := Array.size(xs)\n" ++
  "const arrayProofRuntime: Nat := arrayChecked(#[541, 547], 1, PsStandard.natBleReflects(2, 2))\n" ++
  "const arrayAutoRuntime: Nat := #[551, 557][1]\n" ++
  "const arrayOptionalRuntime: Nat := Option.getD(#[563][0]?, 0)\n" ++
  "const arrayBangRuntime: Nat := #[571][0]!\n" ++
  "const arrayEmptyRuntime: Bool := Option.isNone((#[] : Array Nat)[0]?)\n" ++
  "const arrayHugeRuntime: Bool := Option.isNone(#[577][184467440737095516170]?)\n" ++
  "const arrayFinMismatchRuntime: Bool := Option.isNone(#[587][finIndexSeed]?)\n" ++
  "const arrayLawfulRuntime: Nat := arrayLawful(#[593, 599])\n" ++
  "const arrayFinGetRuntime: Nat := Array.get(#[601, 607], Fin.mk(1, PsStandard.natBleReflects(2, 2)))\n" ++
  "const arrayConstructRuntime: Nat := (Array.mk([613, 617]))[1]\n" ++
  "const arrayRoundtripRuntime: Nat := Option.getD(List.get?(Array.toList(List.toArray([619, 631])), 1), 0)\n" ++
  "const arrayBoolRoundtripRuntime: Bool := Option.getD(List.get?(Array.toList(Array.mk([false, true])), 1), false)\n" ++
  "function arraySetAlias(seed: Nat): Nat := {\n  let original: Array Nat := #[seed, 641]\n  let changed: Array Nat := Array.set(original, 1, 643, PsStandard.natBleReflects(2, 2))\n  Nat.add(original[1]!, changed[1]!)\n}\n" ++
  "const arraySetAliasRuntime: Nat := arraySetAlias(647)\n" ++
  "const arraySetHugeRuntime: Nat := (Array.setIfInBounds(#[653], 184467440737095516170, 0))[0]!\n" ++
  "const arrayFoldSliceRuntime: Nat := Array.foldl(fun acc => fun item => Nat.add(acc, item), 0, #[2, 3, 5, 7], 1, 3)\n" ++
  "const arrayFoldHugeRuntime: Nat := Array.foldl(fun acc => fun item => Nat.add(acc, item), 661, #[2, 3], 184467440737095516170, 184467440737095516171)\n" ++
  "const arrayMapRuntime: Nat := (Array.map(fun item => Nat.add(item, 1), #[673]))[0]!\n" ++
  "function arrayBangPanic(unit: Nat): Nat := (#[] : Array Nat)[0]!\n" ++
  "structure CustomIndex where { value: Nat }\ninstance customChecked: GetElem(CustomIndex, Nat, Nat, fun (_: CustomIndex) => fun (_: Nat) => True) where { getElem(xs: CustomIndex, i: Nat, h: True): Nat := xs.value }\ninstance (priority := high) customOptional: GetElem?(CustomIndex, Nat, Nat, fun (_: CustomIndex) => fun (_: Nat) => True) where {\n  toGetElem := customChecked\n  getElem?(xs: CustomIndex, i: Nat): Option Nat := Option.none\n  getElem![inhabited: Inhabited Nat](xs: CustomIndex, i: Nat): Nat := GetElem?.getElem!Default((Option.none : Option Nat))\n}\nconst customPriorityRuntime: Bool := Option.isNone((CustomIndex.mk(701))[0]?)\nconst customFinPriorityRuntime: Bool := Option.isNone((CustomIndex.mk(701))[finIndexSeed]?)\n" ++
  "const indexingPositionsRuntime: Nat := Nat.add(Nat.add([2, 3, 5][0], Nat.add([2, 3, 5][1], [2, 3, 5][2])), Nat.add(#[7, 11, 13][0], Nat.add(#[7, 11, 13][1], #[7, 11, 13][2])))\nconst finEmptyRuntime: Bool := Option.isNone(([] : List Nat)[finIndexSeed]?) && Option.isNone((#[] : Array Nat)[finIndexSeed]?)\nconst arrayMaker: List Nat -> Array Nat := Array.mk\nconst arrayReader: Array Nat -> List Nat := Array.toList\nconst arrayPartialConversionRuntime: Nat := Option.getD(List.get?(arrayReader(arrayMaker([709, 719])), 1), 0)\n" ++
  "function arrayLogicalLength(xs: Array Nat): Nat := match xs with { | .mk values => List.length(values) }\nconst arrayEliminationRuntime: Nat := arrayLogicalLength(#[727, 733, 739])\n"

private def instanceProgram : String :=
  "namespace Effects\n" ++
  "function keep(value: Nat): Except String Nat := do {\n  return value\n}\n" ++
  "end Effects\n" ++
  "function need{P: Prop}[decision: Decidable P](value: Nat): Nat := value\n" ++
  "function forward{P: Prop}[Decidable P](value: Nat): Nat := need(P := P, value := value)\n" ++
  "const lambdaForward: forall (P: Prop) [Decidable P], Nat -> Nat :=\n" ++
  "  λ (P: Prop) [Decidable P] value => need(P := P, value := value)\n" ++
  "section Instances\n" ++
  "variable (P Q: Prop) [Decidable P]\n" ++
  "function sectionForward(value: Nat): Nat := need(P := P, value := value)\n" ++
  "end Instances\n"

private def semanticCases : IO Unit := do
  let requests : Array PsV7Native.Request := #[
    { source := application },
    { source := instanceProgram },
    { source := "function keep(value: Nat): Nat := value\nconst bad: Nat := keep (3)\n" },
    { source := "function bad(n: Nat): Nat := nomatch n\n" },
    { source := "import Missing\nconst answer: Nat := 42\n" },
    { source := "const leaked: Nat := answer\n" },
    { source := "const answer: Nat := 43\n" },
    { source := "function keep(value: Nat): Nat := value\nconst bad: Nat := keep(missing := 1)\n" },
    { source := "function keep(value: Nat): Nat := value\nconst bad: Nat := keep(value := 1, value := 2)\n" },
    { source := "function use(a: Unit, b: Unit): Nat := 0\nconst bad: Nat := use()\n" },
    { source := "const bad: Nat := _\n" },
    { source := "const bad: Nat -> Nat := fun x => true\n" },
    { source := "const bad: Nat := keep(value := 1, 2)\n" },
    { source := "const value: Nat := 1\nconst bad: Nat := value()\n" },
    { source := "namespace A\nconst value: Nat := 1\nend A\nnamespace B\nconst value: Nat := 2\nend B\nopen A B\nconst bad: Nat := value\n" },
    { source := "namespace A\nend B\n" },
    { source := "namespace A\nconst value: Nat := 1\nend A\nsection\nopen A\nconst good: Nat := value\nend\nconst bad: Nat := value\n" },
    { source := "section\nvariable (P: Prop) (proof: P)\ntheorem bad: P := proof\nend\n" },
    { source := "function bad(value: Nat := true): Nat := value\n" },
    { source := "function need(value: Nat := 1, required: Nat): Nat := required\nconst bad: Nat := need()\n" },
    { source := "section\nvariable (value: Nat)\nconst good: Nat := value\n" },
    { source := "const bad: Nat -> Nat -> Nat := fun (x: Nat, y: Nat) => x\n" },
    { source := "const bad: Unit -> Nat := fun() => 0\n" },
    { source := "const bad: forall (A: Type) A -> A := fun (A: Type) x => x\n" },
    { source := "function need{P: Prop}[Decidable P](value: Nat): Nat := value\nfunction bad{P: Prop}(value: Nat): Nat := need(P := P, value := value)\n" },
    { source := "function bad(x y: Nat): Nat := x\n" },
    { source := "const bad: forall (A x: A), A := fun (A x: A) => x\n" },
    { source := "section\nvariable (x x: Nat)\nend\n" },
    { source := "structure Bad(A: Type)(B: Type) where { value: A }\n" },
    { source := "inductive Bad where { | empty() }\n" },
    { source := "structure Bad where { x: Nat, y: Nat }\n" },
    { source := "inductive Bad(A: Type): Nat -> Type where { | bad: Bad(Nat, 0) }\n" },
    { source := "inductive Bad: Nat -> Type where { | bad }\n" },
    { source := "inductive Bad: Nat -> Type where { | bad: List Nat }\n" },
    { source := "inductive Bad: Nat -> Type where { | bad: Bad(0) }\nconst wrong: Bad(Nat.succ(0)) := Bad.bad\n" },
    { source := "inductive V: Nat -> Type where { | nil: V(0) | cons(k: Nat, tail: V(k)): V(Nat.succ(k)) }\nfunction bad(n: Nat, v: V(n)): Nat := match v with { | V.nil => 0 | V.cons k tail => bad(Nat.succ(k), tail) }\n" },
    { source := "inductive V: Nat -> Type where { | nil: V(0) | cons(k: Nat, tail: V(k)): V(Nat.succ(k)) }\nfunction bad(n: Nat, v: V(n), other: V(n)): Nat := match v with { | V.nil => 0 | V.cons k tail => bad(k, tail, other) }\n" },
    { source := "inductive V: Nat -> Type where { | nil: V(0) | cons(k: Nat, tail: V(k)): V(Nat.succ(k)) }\nfunction captured(n: Nat, v: V(n)): Nat := V.rec(fun k value => Nat, n, fun k tail ih => ih, v)\n", targets := [.typescript] },
    { source := "inductive V: Nat -> Type where { | nil: V(0) | cons(k: Nat, tail: V(k)): V(Nat.succ(k)) }\nfunction bad(n: Nat, v: V(n)): V(n) := match v with { | V.nil => V.nil | V.cons k tail => tail }\n" },
    { source := "inductive V: Nat -> Type where { | nil: V(0) | cons(k: Nat, tail: V(k)): V(Nat.succ(k)) }\nfunction bad(n: Nat, v: V(n)): Nat := match v with { | V.cons k tail => 0 }\n" },
    { source := "inductive Same: Nat -> Nat -> Type where { | same(n: Nat): Same(n, n) }\nfunction bad(n: Nat, value: Same(n, n)): Nat := match value with { }\n" },
    { source := "inductive V: Nat -> Type where { | nil: V(0) | cons(k: Nat, tail: V(k)): V(Nat.succ(k)) }\nfunction bad(v: V(1)): V(1) := match v with { | V.cons k tail => tail }\n" },
    { source := "function bad(a: Bool, b: Bool): Nat := match a, b with { | true => 0 | _ => 1 }\n" },
    { source := "function bad(value: Prod Nat Nat): Nat := match value with { | (x, x) => x }\n" },
    { source := "function bad(value: Option(Option Nat)): Nat := match value with { | .some (.some n) => n | .none => 0 }\n" },
    { source := "function bad(value: Option(Prod Nat Nat)): Nat := match value with { | .some(x, y) => x | .none => 0 }\n" },
    { source := "function bad(value: Option Nat): Nat := if let .some n := value { n } else { n }\n" },
    { source := "function bad(value: Option Nat): Nat := {\n  let .some n := value\n  n\n}\n" },
    { source := "class C where { value: Nat }\ninstance (priority := high + 1): C where { value := 0 }\n" },
    { source := "structure C where { value: Nat }\ninstance : C where { value := 0 }\n" },
    { source := "class C where { value: Nat }\ninstance : C := C.mk(0)\n" },
    { source := "class C where { value: Nat }\ninstance () : C where { value := 0 }\n" },
    { source := "class C where { value: Nat }\ninstance : C where { value := true }\n" },
    { source := "class C where { value: Nat }\ninstance loop[C]: C where { value := C.value }\nconst bad: Nat := C.value\n" },
    { source := "function bad(A: Type missing, value: A): A := value\n" },
    { source := "section\nuniverse u\nfunction good(A: Type u, value: A): A := value\nend\nfunction bad(A: Type u, value: A): A := value\n" },
    { source := "universe u u\n" },
    { source := "universe u\nfunction bad(A: Type (u + 33), value: A): A := value\n" },
    { source := "theorem bad(P: Prop): P := by { exact _ }\n" },
    { source := "theorem bad(P: Prop): P -> P := by {\n  intro h\n}\n" },
    { source := "function bad(value: Nat): Nat -> Nat := by {\n  · intro x\n  exact value\n}\n" },
    { source := "theorem bad: Eq(0, 1) := by { rfl }\n" },
    { source := "theorem bad(P: Prop, step: P -> P, h: P): P := by { exact step (h) }\n" },
    { source := "theorem bad: Eq(0, 1) := by { any_goals rfl }\n" },
    { source := "function bad(h: Or True True): Nat := match h with { | .inl proof => 0 | .inr proof => 1 }\n" },
    { source := "theorem bad(n: Nat): n = n = n := by { rfl }\n" },
    { source := "function id(n: Nat): Nat := n\ntheorem bad(n: Nat): id (n) = n := by { rfl }\n" },
    { source := "theorem bad: True := by {\n  have x: Nat := 0\n  have h: x = 0 := by { rfl }\n  constructor\n}\n" },
    { source := "theorem bad: True := {\n  have x: Nat := 0\n  have h: x = 0 := by { rfl }\n  True.intro\n}\n" },
    { source := "theorem bad: True := by {\n  show False\n  constructor\n}\n" },
    { source := "theorem bad(n: Nat): exists {x: Nat}, x = n := by { constructor }\n" },
    { source := "theorem bad: True := by {\n  have h: True := _\n  exact h\n}\n" },
    { source := "inductive Hidden: Prop where { | mk(value: Nat) }\nfunction bad(h: Hidden): Nat := match h with { | .mk value => value }\n" },
    { source := "inductive Choice: Prop where { | yes | no }\nfunction bad(h: Choice): Nat := match h with { | .yes => 0 | .no => 1 }\n" },
    { source := "inductive Encoded: Nat -> Prop where { | mk(n: Nat): Encoded(Nat.succ(n)) }\nfunction bad(n: Nat, h: Encoded(n)): Nat := match h with { | .mk value => value }\n" },
    { source := "structure Hidden: Prop where { value: Nat }\n" },
    { source := "structure Indexed: Nat -> Type where { value: Nat }\n" },
    { source := "structure Bad: Nat where { }\n" },
    { source := "structure Pair where {\n  first: Nat\n  second: Nat\n}\nfunction bad(p: Pair): Pair := { p with first := 1, first := 2 }\n" },
    { source := "structure Pair where { first: Nat }\nfunction bad(p: Pair): Pair := { p with wrong := 1 }\n" },
    { source := "structure Pair where {\n  first: Nat\n  second: Nat\n}\nconst bad: Pair := { first := 1 }\n" },
    { source := "structure Pair where { first: Nat }\nconst bad: Nat := {\n  let p := { first := 1 }\n  0\n}\n" },
    { source := "structure Checked where {\n  n: Nat\n  proof: n = 0\n}\nfunction bad(p: Checked): Checked := { p with n := 1 }\n" },
    { source := "structure Pair where { first: Nat }\nfunction id(n: Nat): Nat := n\nfunction bad(p: Pair): Pair := { p with first := id (0) }\n" },
    { source := "const bad: Nat -> Nat := by {\n  refine (fun (n: Nat) => _)\n}\n" },
    { source := "function bad(n: Nat): Nat := by {\n  cases n\n  case zero => exact 0\n  case succ k => exact ih\n}\n" },
    { source := "function bad(n: Nat): Nat := by {\n  cases n\n  case absent => exact 0\n}\n" },
    { source := "function bad(n: Nat): Nat := by {\n  cases n\n  case zero x => exact 0\n}\n" },
    { source := "function bad(n: Nat): Nat := by {\n  cases n\n  case zero => exact n\n  case succ k => exact k\n}\n" },
    { source := "function bad(P: Prop): Nat := if (P) { 0 } else { 1 }\n" },
    { source := "function bad(P: Prop)[Decidable P](use: P -> Nat): Nat := if (h : P) { use(h) } else { use(h) }\n" },
    { source := "function bad(b: Bool): Nat := {\n  let value: Nat := if (h : b) { 1 } else { 2 }\n  h\n}\n" },
    { source := "class Bad(A: outParam(Type), n: A) where { value: A }\n" },
    { source := "class C(A: Type, B: outParam(Type)) where { run: A -> B }\ninstance low: C Nat Bool where { run(n: Nat): Bool := true }\ninstance high: C Nat Nat where { run(n: Nat): Nat := n }\nconst bad: Bool := C.run(0)\n" },
    { source := "class C(A: Type, B: outParam(Type)) where { run: A -> B }\ninstance nat: C Nat Nat where { run(n: Nat): Nat := n }\nfunction need{A: Type}{B: Type}[C A B](value: Nat): Nat := value\nconst bad: Nat := need(0)\n" },
    { source := "class C(A: Type, B: outParam(Type)) where { run: A -> B }\ninstance loop{A: Type}{B: Type}[C A B]: C A B where { run(value: A): B := C.run(value) }\nconst bad: Nat := C.run(0)\n" }]

  let expected : Array (Option String) :=
    #[none, none, some "parse", some "elaborate", some "parse", some "elaborate", none,
      some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "parse", some "elaborate",
      some "elaborate", some "elaborate", some "elaborate", some "elaborate",
      some "elaborate", some "elaborate", some "elaborate",
      some "parse", some "parse", some "parse", some "elaborate",
      some "parse", some "elaborate", some "elaborate",
      some "parse", some "parse", some "parse",
      some "elaborate", some "elaborate", some "elaborate", some "elaborate",
      some "elaborate", some "elaborate", none, some "elaborate",
      some "elaborate", some "elaborate", some "elaborate",
      some "elaborate", some "elaborate", some "elaborate", some "parse",
      some "elaborate", some "elaborate",
      some "parse", some "elaborate", some "parse", some "parse", some "elaborate", some "elaborate",
      some "elaborate", some "elaborate", some "elaborate", some "parse",
      some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "parse", some "elaborate", some "elaborate", some "parse", some "parse", some "elaborate", some "elaborate", some "elaborate", some "parse", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "parse", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate", some "elaborate"]
  let diagnosticPrefixes : Array String := #["PSCV0-ARGUMENT: unknown", "PSCV0-ARGUMENT: duplicate", "PSCV0-APP-03", "PSCV0-UNSOLVED-INFERENCE", "PSCV0-TYPE-MISMATCH", "PSCV0-PARSE", "PSCV0-ELABORATION",
    "PSCV0-SCOPE: ambiguous", "PSCV0-SCOPE: end name", "PSCV0-SCOPE: unknown name",
    "PSCV0-SCOPE: theorem proof", "PSCV0-TYPE-MISMATCH", "PSCV0-APP-03", "PSCV0-SCOPE: unclosed",
    "PSCV0-PARSE", "PSCV0-PARSE", "PSCV0-PARSE", "PSCV0-ELABORATION",
    "PSCV0-PARSE", "PSCV0-SCOPE: unknown name", "PSCV0-SCOPE: duplicate active section variable",
    "PSCV0-PARSE: PSCV0-BIND-02", "PSCV0-PARSE: nonempty binder group",
    "PSCV0-PARSE: newline-separated structure field",
    "PSCV0-DATA: constructor parameters must remain uniform",
    "PSCV0-DATA: indexed constructor requires a result type",
    "PSCV0-DATA: constructor result must be its declared family", "PSCV0-TYPE-MISMATCH",
    "PSCV0-RECURSION: argument", "PSCV0-RECURSION: invariant parameter", "", "PSCV0-TYPE-MISMATCH",
    "PSCV0-MATCH: missing feasible", "PSCV0-MATCH: missing feasible", "PSCV0-TYPE-MISMATCH",
    "PSCV0-MATCH: pattern row", "PSCV0-SCOPE: duplicate pattern", "PSCV0-MATCH: missing feasible", "PSCV0-PARSE",
    "PSCV0-SCOPE: unknown name", "PSCV0-MATCH: missing feasible",
    "PSCV0-PARSE", "PSCV0-DATA: instance result", "PSCV0-PARSE", "PSCV0-PARSE", "PSCV0-TYPE-MISMATCH", "PSCV0-ELABORATION",
    "PSCV0-SCOPE: unknown universe", "PSCV0-SCOPE: unknown universe",
    "PSCV0-SCOPE: duplicate or invalid universe", "PSCV0-PARSE",
    "PSCV0-PROOF: exact left", "PSCV0-PROOF: unsolved goals",
    "PSCV0-PROOF: focused branch", "PSCV0-PROOF: rfl", "PSCV0-APP-02", "PSCV0-PROOF: tactic failed on all goals", "PSCV0-ELABORATION", "PSCV0-PARSE", "PSCV0-APP-02", "PSCV0-PROOF: rfl", "PSCV0-PROOF: rfl", "PSCV0-PROOF: show", "PSCV0-PARSE", "PSCV0-PROOF: local declaration", "PSCV0-ELABORATION", "PSCV0-ELABORATION", "PSCV0-ELABORATION", "PSCV0-DATA: Prop structure fields", "PSCV0-DATA: structure result", "PSCV0-DATA: data family must end", "PSCV0-ARGUMENT: duplicate record", "PSCV0-ARGUMENT: unknown record", "PSCV0-ARGUMENT: missing required record", "PSCV0-ARGUMENT: record requires", "PSCV0-TYPE-MISMATCH", "PSCV0-APP-02", "PSCV0-PROOF: unsolved goals", "PSCV0-SCOPE: unknown name", "PSCV0-PROOF: unknown case tag", "PSCV0-PROOF: too many case binder", "PSCV0-SCOPE: unknown name", "PSCV0-ARGUMENT: conditional proposition", "PSCV0-TYPE-MISMATCH", "PSCV0-SCOPE: unknown name", "PSCV0-DATA: class input parameter", "PSCV0-ELABORATION", "PSCV0-ELABORATION", "PSCV0-ELABORATION"]
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok batch => pure batch
    | .error error => throw (IO.userError (reprStr error))
  for i in [:expected.size] do
    let some result := batch.results[i]?
      | throw (IO.userError "missing batch result")
    IO.println (PsV7Native.resultJson ("case-" ++ toString i) result).compress
    match expected[i]!, result with
    | none, .ok _ => pure ()
    | some phase, .error error =>
        unless error.phase == phase do
          throw (IO.userError s!"case {i}: expected {phase}, got {error.phase}")
        if i >= 7 then
          unless error.message.startsWith diagnosticPrefixes[i - 7]! do
            throw (IO.userError s!"case {i}: wrong diagnostic: {error.message}")
        if i == 3 && !error.message.startsWith "PSCV0-MATCH: missing feasible" then
          throw (IO.userError "nomatch accepted or misclassified a feasible Nat branch")
        if i == 2 && !error.message.startsWith "PSCV0-APP-02" then
          throw (IO.userError "gap application did not reach APP-02")
        if i == 4 && error.message != "PSCV0-NATIVE-MODULE-IMPORTS-PENDING" then
          throw (IO.userError "imports were not explicitly refused")
    | _, _ => throw (IO.userError s!"case {i}: wrong acceptance outcome")
  IO.FS.createDirAll "../dist/pscv0-native"
  IO.FS.writeFile "../dist/pscv0-native/application.ps" application
  IO.FS.writeFile "../dist/pscv0-native/semantic.json"
    (Lean.Json.mkObj [
      ("preludeMs", toJson batch.preludeMs),
      ("results", Lean.Json.arr (batch.results.map (PsV7Native.resultJson "batch-case")))]).pretty
  IO.println "PSCV0_NATIVE_SEMANTICS: PASS 4 checked programs, 92 phase-specific refusals, shared-prelude isolation"

private def metavariableBoundary : IO Unit := do
  let type := PsExpr.constE psNatName []
  let functionType := PsExpr.forallE (psRootName "argument") type type .explicit
  let parent := psMetaFresh psMetaEmpty psLocalEmpty functionType .syntheticOpaque
  let child := psMetaFresh parent.context psLocalEmpty type .natural
  let .mvar parentId := parent.expr | throw (IO.userError "missing parent")
  let .mvar childId := child.expr | throw (IO.userError "missing child")
  let pushed := psLocalPushBinding psLocalEmpty (psRootName "captured") type .explicit
  let goal := psMetaFresh child.context pushed.context type .syntheticOpaque
  let .mvar goalId := goal.expr | throw (IO.userError "missing goal")
  let some context := psMetaAssignDelayed goal.context parentId
      [.lambdaE pushed.id (psRootName "captured") type .explicit] goal.expr
    | throw (IO.userError "delayed assignment rejected")
  if (psMetaAssign context goalId (.app parent.expr (.fvar pushed.id))).isSome then
    throw (IO.userError "cycle through delayed scope accepted")
  if (psMetaAssign context childId goal.expr).isSome then
    throw (IO.userError "goal alias escaped its captured context")
  let environment := psSelfHostProdPreludeEnvironment
  let proposition := psLocalPushBinding psLocalEmpty (psRootName "P") (.sortE .zero) .explicit
  let first := psLocalPushBinding proposition.context (psRootName "first") (.fvar proposition.id) .explicit
  let second := psLocalPushBinding first.context (psRootName "second") (.fvar proposition.id) .explicit
  let expectedProof := psLogicEq .zero (.fvar proposition.id) (.fvar first.id) (.fvar first.id)
  let function := psLocalPushBinding second.context (psRootName "consume")
    (.forallE .anonymous expectedProof type .explicit) .explicit
  let otherProof := psLogicRefl .zero (.fvar proposition.id) (.fvar second.id)
  unless (psInferType environment psMetaEmpty function.context
      (.app (.fvar function.id) otherProof)).isOk &&
      (psInferType environment psMetaEmpty second.context
        (.letE .anonymous expectedProof otherProof (.lit (.natural 0)))).isOk do
    throw (IO.userError "typed inference rejected convertible proof fields")
  if (psInferType environment psMetaEmpty function.context
      (.app (.fvar function.id) (psLogicRefl (.succ .zero) type (.lit (.natural 0))))).isOk then
    throw (IO.userError "proof irrelevance identified different propositions")
  let locals := (psLocalPushBinding psLocalEmpty (psRootName "consume")
    (.forallE .anonymous (psLogicEq (.succ .zero) type (.lit (.natural 0)) (.lit (.natural 0))) type .explicit) .explicit)
  if (psInferType environment psMetaEmpty locals.context
      (.app (.fvar locals.id) (psLogicRefl (.succ .zero) type (.lit (.natural 1))))).isOk then
    throw (IO.userError "proof irrelevance identified runtime values")
  IO.println "PSCV0_NATIVE_SCOPE_BOUNDARY: PASS delayed cycles, goal scopes and typed proof conversion"

private def emissionBoundary : IO Unit := do
  let invalid : PsVerifiedIrModule := { psVerifiedIrModuleEmpty with declarations := [
    { name := "bad", typeParameters := [], parameters := [], resultType := .primitive .nat, body := .literal (.bool true) }] }
  match psWithCheckedIr psIrCheckDefaultOptions invalid (fun _ => .ok ()) with
  | .ok _ => throw (IO.userError "invalid IR reached emission")
  | .error message => unless message.startsWith "PSCV0-IR-CHECK:" do
      throw (IO.userError message)
  let state : PsCodegenNames := {}
  let names := ["A.b", "A_b", "α", "normal"]
  let (_, state) ← match (names.mapM psCodegenName).run state with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  unless (state.symbols.map (·.outputName)).eraseDups.length == names.length do
    throw (IO.userError "target name collision")
  unless state.symbols.any (fun s => s.semanticName == "α" && s.outputName == "α") do
    throw (IO.userError "Unicode name lost before target naming")
  let rendered ← match psRenderDoc (.origin "normal" (psDocBlock "function normal()" [.text "return 1;"])) with
    | .ok value => pure value
    | .error error => throw (IO.userError error)
  unless rendered.text.contains '\n' && rendered.ranges.length == 1 &&
      rendered.ranges.all (fun r => r.startByte <= r.endByte && r.endByte <= rendered.text.utf8ByteSize) do
    throw (IO.userError "structured layout/origin range invalid")
  unless ["module.js", "module.d.ts", "nested/module.wasm"].all psArtifactPathValid &&
      ["../x.js", "/x", "C:/x", "CON.js", "x./y"].all (fun p => !psArtifactPathValid p) do
    throw (IO.userError "artifact path boundary")
  let coords := psSourceCoordinates "a😀é\nβ"
  let position ← match psSourceCoordinateAt coords 7 with
    | .ok p => pure p
    | .error e => throw (IO.userError e)
  unless position.line == 0 && position.column == 4 do
    throw (IO.userError "UTF-8 / UTF-16 source coordinate conversion")
  let sourcePrefix := "/* 😀 */ "
  let generatedPrefix := "/* 🦀 */ "
  let sourceText := sourcePrefix ++ "const λ = 1;"
  let origin : PsSourceOrigin := {
    identity := { file := "unicode-input.js", declaration := "λ" }
    span := {
      start := { byteOffset := sourcePrefix.utf8ByteSize, line := 1, column := 9 }
      stop := { byteOffset := sourceText.utf8ByteSize, line := 1, column := 21 } } }
  let fixture ← get "map layout" (psRenderDoc (.append (.text generatedPrefix)
    (.append (.origin "λ" (psDocBlock "function λ()" [.text "return 1n;"])) (.text "\n// synthetic 😀\n"))))
  let mapping ← get "map" (psSourceMap
    { sourceName := "unicode-input.js", sourceText := sourceText, outputStem := "unicode-output", origins := [("λ", origin)] }
    [{ semanticName := "λ", outputName := "λ" }] fixture)
  IO.FS.createDirAll "../dist/pscv0-native"
  IO.FS.writeFile "../dist/pscv0-native/unicode-output.js" fixture.text
  IO.FS.writeFile "../dist/pscv0-native/unicode-output.js.map" mapping
  IO.println "PSCV0_NATIVE_EMISSION_BOUNDARY: PASS invalid IR refusal, names and layout origins"

private def doBoundaries : IO Unit := do
  let cases : Array (String × String) := #[
    ("const bad: Bool := if (1 < 2 < 3) { true } else { false }\n", "parse"),
    ("const bad: Bool := if (1 < = 2) { true } else { false }\n", "parse"),
    ("universe u v\nfunction bad{A: Type u}{B: Type v}(xs: Option A, f: A -> B): Option B := do {\n  let x: A ← xs\n  return f(x)\n}\n", "elaborate"),
    ("const bad: Except String Nat := do { return 1; return 2 }\n", "parse"),
    ("const bad: Option Nat := do {\n  let n: Nat ← Except.ok(1)\n  return n\n}\n", "elaborate"),
    ("const bad: Except String Nat := do {\n  Except.ok(1)\n  return 2\n}\n", "elaborate"),
    ("const bad: Id Nat := do {\n  let .some n := Option.none\n  return n\n}\n", "elaborate"),
    ("function bad(flag: Bool): Id Nat := do {\n  if (h : flag) { return 1 }\n  return h\n}\n", "elaborate"),
    ("const bad: Id Nat := do {\n  if let .some n ← Option.some(1) { return n }\n  return 0\n}\n", "parse"),
    ("const bad: Id Nat := do {\n  let (x, x) := (1, 2)\n  return x\n}\n", "elaborate"),
    ("opaque hidden: Nat := 1\ntheorem bad: hidden = 1 := by { rfl }\n", "elaborate")]
  let batch ← match ← PsV7Native.runBatch (cases.map fun (source, _) => { source }) with
    | .ok batch => pure batch
    | .error error => throw (IO.userError (reprStr error))
  for i in [:cases.size] do
    let some outcome := batch.results[i]? |
      throw (IO.userError s!"missing do boundary result {i}")
    match outcome with
    | .error error =>
      unless error.phase == cases[i]!.snd do
        throw (IO.userError s!"do boundary {i}: {error.phase}: {error.message}")
    | .ok _ => throw (IO.userError s!"do boundary {i}: invalid source accepted")
  IO.println "PSCV0_NATIVE_DO: PASS 8 do refusals, 2 comparison syntax refusals and 1 opaque definitional-opacity refusal"

-- Reuse the production graph planner and checked environment, rather than
-- introducing a separate project interpreter or a large fixture suite.
private def projectBoundaries : IO Unit := do
  let _ ← get "pinned Standard declaration and instance registry"
    (psStandardExceptAudit psSelfHostProdPreludeEnvironment)
  let _ ← get "pinned RC4 Standard snapshot"
    (psStandardSnapshotValidate psSelfHostProdPreludeEnvironment
      psStandardSnapshotExpected)
  -- Independent published SHA-256 known-answer vectors protect padding,
  -- expansion, endianness and round arithmetic. Unicode forces UTF-8 input.
  let shaVectors := [
    ("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
    ("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
    ("hello world", "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"),
    ("é", "4a99557e4033c3539de2eb65472017cad5f9557f7a0625a09f1c3f6e2ba69c4c")]
  for (input, expectedDigest) in shaVectors do
    let actual := psStandardSnapshotSHA256 input
    unless actual == expectedDigest do
      throw (IO.userError ("Standard SHA-256 known-answer failure for " ++
        reprStr input ++ ": " ++ actual))
  IO.println ("PSCV0_NATIVE_STANDARD_SHA256_CANDIDATE: " ++
    psStandardSnapshotSHA256Fingerprint psSelfHostProdPreludeEnvironment)
  let _ ← get "cryptographic Standard registry fingerprint"
    (psStandardSnapshotValidateCrypto psSelfHostProdPreludeEnvironment
      psStandardSnapshotExpectedSHA256)
  -- One graph contains a seeded mutual cycle, a diamond, and a convertible
  -- duplicate. Local hypotheses are real typed evidence; the graph never
  -- manufactures recursive dictionaries to close the cycle.
  let environment := psSelfHostProdPreludeEnvironment
  let a := psStandardInhabitedType (.constE psNatName [])
  let b := psStandardInhabitedType (.constE (psRootName "Bool") [])
  let resultGoal := psStandardInhabitedType (.constE (psRootName "String") [])
  -- optParam is reducible in RC4. Id is implicit-reducible and therefore
  -- cannot serve as an instance-search alias without a bridging instance.
  let aliasNat := psLogicApply (.constE psOptParamName [.succ .zero])
    [.constE psNatName [], .lit (.natural 0)]
  let aliasA := psStandardInhabitedType aliasNat
  let need := fun domain result =>
    PsExpr.forallE (psRootName "dictionary") domain result .instanceImplicit
  let add := fun locals name type =>
    (psLocalPushBinding locals (psRootName name) type .instanceImplicit).context
  let locals := add psLocalEmpty "seed" a
  let locals := add locals "aFromB" (need b a)
  let locals := add locals "bFromA" (need a b)
  let locals := add locals "finish" (need a (need b (need aliasA resultGoal)))
  let graph := psSynthInstanceWithTable environment locals psInstanceIndexEmpty
    psMetaEmpty 64 resultGoal
  let some graphWitness := graph.result.value |
    throw (IO.userError "seeded cycle/diamond did not produce finite evidence")
  unless (psInstanceReplay environment locals psMetaEmpty resultGoal graphWitness).isSome &&
      graph.table.visits == 3 && graph.table.answers == 3 &&
      graph.table.reusedGoals >= 3 && graph.table.resumed >= 4 &&
      !graph.table.resourceExceeded do
    throw (IO.userError ("instance graph failed sharing or waiter propagation: " ++
      toString graph.table.visits ++ "/" ++ toString graph.table.reusedGoals ++
      "/" ++ toString graph.table.resumed))
  -- Duplicating a dependency must not repeat candidate expansion. Queue
  -- transitions grow with dependency edges, not with all paths in a diamond.
  let mut previousChecks := 0
  for width in [1, 8, 32] do
    let telescope := (List.replicate width aliasA).foldr need resultGoal
    let repeated := add (add psLocalEmpty "seed" a) "finish" telescope
    let measured := psSynthInstanceWithTable environment repeated psInstanceIndexEmpty
      psMetaEmpty 64 resultGoal
    unless measured.result.value.isSome && measured.table.visits == 2 &&
        measured.table.reusedGoals == width - 1 &&
        measured.table.transitions <= 4 * width + 8 &&
        (previousChecks == 0 || measured.table.candidateChecks == previousChecks) do
      throw (IO.userError "repeated dictionary dependencies expanded duplicate candidates")
    previousChecks := measured.table.candidateChecks
    IO.println ("PSCV0_NATIVE_INSTANCE_GROWTH: edges=" ++ toString width ++
      " generators=" ++ toString measured.table.visits ++
      " candidates=" ++ toString measured.table.candidateChecks ++
      " transitions=" ++ toString measured.table.transitions)
  -- The cached registry must preserve exact global priority/tie order,
  -- including entries whose class metadata is absent.
  let registryEntries := environment.instances.entries
  let mixed : PsInstanceIndex := { entries := registryEntries.zipIdx.map fun (entry, i) =>
    if i % 3 == 0 then { entry with className := none } else entry }
  let registry := psInstanceRegistry mixed
  for className in environment.classes do
    let expected := mixed.entries.filter fun entry =>
      entry.className.isNone || entry.className.any (psNameEq className)
    let actual := psInstanceRegistryEntries registry className
    unless actual.length == expected.length &&
        (actual.zip expected).all (fun (a, b) =>
          a.priority == b.priority && psExprAlphaEq a.value b.value) do
      throw (IO.userError "class-index lookup changed global instance order")
  -- Full structural keys partition both distinct heads and distinct rigid
  -- arguments. Hash hits still require equality and checked answer replay.
  for width in [1, 8, 32] do
    for partitioned in [true, false] do
      let mut measuredEnv := environment
      let mut measuredLocals := psLocalEmpty
      let mut goals := []
      for i in List.range width do
        let name := PsName.num (psRootName "MeasuredClass") i
        let goal := if partitioned then PsExpr.constE name [] else
          psStandardInhabitedType (psStandardFinOf (.lit (.natural (i + 1))))
        if partitioned then
          measuredEnv := psPreludeAdd measuredEnv
            (.axiomDecl name [] psPreludeTypeType)
        measuredLocals := add measuredLocals ("seed" ++ toString i) goal
        goals := goal :: goals
      measuredLocals := add measuredLocals "finish" (goals.reverse.foldr need resultGoal)
      let measured := psSynthInstanceWithTable measuredEnv measuredLocals
        psInstanceIndexEmpty psMetaEmpty 64 resultGoal
      unless measured.result.value.isSome && measured.table.visits == width + 1 &&
          measured.table.goalComparisons <= width do
        throw (IO.userError "instance structural indexing changed results or repeated same-head comparisons")
      IO.println ("PSCV0_INSTANCE_LOOKUP_GROWTH: goals=" ++ toString width ++
        " partitioned=" ++ toString partitioned ++
        " comparisons=" ++ toString measured.table.goalComparisons ++
        " candidates=" ++ toString measured.table.candidateChecks)
  -- Key construction must not execute a large primitive power merely to
  -- organize goals. Candidate unification remains responsible for conversion.
  let indexedPower := psLogicApply (.constE (psDecisionName "Nat.pow") [])
    [.lit (.natural 2), .lit (.natural 1000000000)]
  let canonicalPower := psInstanceCanonicalKey environment psLocalEmpty psMetaEmpty
    256 indexedPower
  unless psExprAlphaEq canonicalPower indexedPower do
    throw (IO.userError "instance key construction executed primitive arithmetic")
  let alphaLeft := PsExpr.lam (psRootName "x") (.constE psNatName []) (.bvar 0) .explicit
  let alphaRight := PsExpr.lam (psRootName "y") (.constE psNatName []) (.bvar 0) .explicit
  unless psInstanceExprHash alphaLeft == psInstanceExprHash alphaRight do
    throw (IO.userError "alpha-equal instance keys have different hashes")
  let hiddenAlias := psStandardInhabitedType
    (.app (.constE (psRootName "Id") [.zero]) (.constE psNatName []))
  let hiddenSearch := psSynthInstanceWithTable environment (add psLocalEmpty "seed" a)
    psInstanceIndexEmpty psMetaEmpty 64 hiddenAlias
  unless hiddenSearch.result.value.isNone && !hiddenSearch.table.resourceExceeded do
    throw (IO.userError "implicit-reducible alias was used by instance search")
  let unseeded := add (add psLocalEmpty "aFromB" (need b a)) "bFromA" (need a b)
  let cycle := psSynthInstanceWithTable environment unseeded psInstanceIndexEmpty
    psMetaEmpty 64 a
  unless cycle.result.value.isNone && cycle.table.visits == 2 &&
      !cycle.table.resourceExceeded do
    throw (IO.userError "unseeded cycle fabricated evidence or spun until exhaustion")
  -- Private continuations retain assignments in local dictionary types,
  -- even when those outputs do not occur in the final result class. Replaying
  -- only the witness against the result type would lose these constraints.
  let natType := PsExpr.constE psNatName []
  let arrayType := psPreludeArrayOf natType
  let elemMeta := psMetaFresh psMetaEmpty psLocalEmpty (.sortE (.succ .zero)) .natural
  let validityType := psLogicPi 101 "xs" arrayType
    (psLogicPi 102 "i" natType (.sortE .zero))
  let validMeta := psMetaFresh elemMeta.context psLocalEmpty validityType .natural
  let indexing := psLogicApply (.constE psStandardGetElemName [.zero, .zero, .zero])
    [arrayType, natType, elemMeta.expr, validMeta.expr]
  let ownedLocals := add (add psLocalEmpty "resolveOutput" (need indexing resultGoal))
    "finish" (need resultGoal b)
  let indexingOnly : PsInstanceIndex := {
    entries := environment.instances.entries.filter fun entry =>
      match entry.className with
      | some name => psNameEq name psStandardGetElemName
      | none => false }
  let owned := psSynthInstanceWithTable environment ownedLocals indexingOnly
    validMeta.context 64 b
  let some ownedWitness := owned.result.value |
    throw (IO.userError "owned instance continuation dropped local-type assignments")
  unless psExprAlphaEq (psMetaInstantiate owned.result.context elemMeta.expr) natType &&
      !psExprHasUnresolvedMeta (psMetaInstantiate owned.result.context validMeta.expr) &&
      (psInstanceReplay environment ownedLocals owned.result.context b ownedWitness).isSome do
    throw (IO.userError "owned instance assignments were not checked and returned")
  -- Each independent resource limit fails closed, as does evidence height.
  for limits in [
      ({ goals := 0 } : PsInstanceSearchLimits),
      ({ candidates := 0 } : PsInstanceSearchLimits),
      ({ transitions := 0 } : PsInstanceSearchLimits),
      ({ answers := 0 } : PsInstanceSearchLimits)] do
    let exhausted := psSynthInstanceWithLimits environment locals psInstanceIndexEmpty
      psMetaEmpty 64 limits resultGoal
    unless exhausted.result.value.isNone && exhausted.table.resourceExceeded do
      throw (IO.userError "instance graph resource limit did not fail closed")
  let shallow := psSynthInstanceWithTable environment locals psInstanceIndexEmpty
    psMetaEmpty 1 resultGoal
  unless shallow.result.value.isNone do
    throw (IO.userError "instance graph exceeded evidence height")
  -- Pi scope ownership: a local dictionary introduced while solving the first
  -- argument must not leak into the second argument's parent-scope goal.
  let piA := need a a
  let isolated := add psLocalEmpty "finish" (need piA (need a resultGoal))
  let leaked := psSynthInstanceWithTable environment isolated psInstanceIndexEmpty
    psMetaEmpty 64 resultGoal
  unless leaked.result.value.isNone do
    throw (IO.userError "Pi-local dictionary escaped its generator scope")
  let universalGoal := psLogicPi 71 "n" (.constE psNatName []) a
  let universalResult := psSynthInstanceWithTable environment
    psLocalEmpty environment.instances psMetaEmpty 64 universalGoal
  let some witness := universalResult.result.value
    | throw (IO.userError "Pi-indexed class synthesis rejected")
  unless (psInstanceReplay environment psLocalEmpty psMetaEmpty universalGoal witness).isSome do
    throw (IO.userError "Pi dictionary synthesized an incorrect function type")
  IO.println ("PSCV0_NATIVE_INSTANCE_GRAPH: PASS cycle/diamond/conversion, " ++
    "scope isolation, evidence replay and independent resource limits")
  let wrongDigest := "sha256:" ++ String.ofList (List.replicate 64 '0')
  if (psStandardSnapshotValidateCrypto psSelfHostProdPreludeEnvironment
      wrongDigest).isOk then
    throw (IO.userError "Standard SHA-256 accepted a deliberately wrong expected digest")
  let unrelatedAlias := {
    psSelfHostProdPreludeEnvironment with
    exportedAliases := (psRootName "unexpectedAlias", psNatName) ::
      psSelfHostProdPreludeEnvironment.exportedAliases }
  if (psStandardSnapshotValidate unrelatedAlias psStandardSnapshotExpected).isOk then
    throw (IO.userError "pinned Standard snapshot accepted alias registry drift")
  if (psStandardSnapshotValidateCrypto unrelatedAlias
      psStandardSnapshotExpectedSHA256).isOk then
    throw (IO.userError "Standard SHA-256 accepted alias registry drift")
  IO.println ("PSCV0_NATIVE_STANDARD_SNAPSHOT: declarations=" ++
    toString psSelfHostProdPreludeEnvironment.declarations.length ++
    " classes=" ++ toString psSelfHostProdPreludeEnvironment.classes.length ++
    " instances=" ++ toString psSelfHostProdPreludeEnvironment.instances.entries.length ++
    " fingerprint=" ++ psStandardSnapshotExpected)
  -- Type-family parameters to a class are erased even when their source
  -- shape is a dependent function returning Sort (e.g. coll → idx → Prop).
  -- An ordinary function returning Nat remains computational, and an actual
  -- proposition remains a proof. These three classifications must not merge.
  let nat := PsExpr.constE psNatName []
  let predicateFamily := psLogicPi 50 "xs" nat (psLogicPi 51 "i" nat (.sortE .zero))
  let runtimeFunction := psLogicPi 50 "xs" nat nat
  let psIndexKind := psErasureClassifyBinder
    psSelfHostProdPreludeEnvironment psLocalEmpty predicateFamily
  let runtimeKind := psErasureClassifyBinder
    psSelfHostProdPreludeEnvironment psLocalEmpty runtimeFunction
  let proofKind := psErasureClassifyBinder
    psSelfHostProdPreludeEnvironment psLocalEmpty (.constE (psRootName "True") [])
  unless (match psIndexKind with | .index => true | _ => false) &&
      (match runtimeKind with | .runtime => true | _ => false) &&
      (match proofKind with | .proof => true | _ => false) do
    throw (IO.userError "type-family parameter erasure confused predicates with runtime functions/proofs")
  let some getElemFamily := psEnvironmentFindInductive
      psSelfHostProdPreludeEnvironment psStandardGetElemName
    | throw (IO.userError "checked GetElem family is missing")
  let reifiedSourceIndices ← get "GetElem source/type parameter plan"
    ((psErasureInductiveSourceTypeIndices psSelfHostProdPreludeEnvironment
      (psErasureScopeEmpty []) getElemFamily).mapError (fun _ =>
      "GetElem parameter telescope cannot be classified"))
  unless reifiedSourceIndices == [0, 1, 2] do
    throw (IO.userError "GetElem.valid escaped the erased predicate-index contract")

  let badStandard := psEnvironmentInsert psSelfHostProdPreludeEnvironment
    (.definitionDecl
      (psNameAppendStr (psRootName "PsStandard") "instBEqNat") []
      (.constE psBoolName []) (.constE psBoolTrueName []))
  if (psStandardInhabitedAudit badStandard).isOk then
    throw (IO.userError "Standard registry admitted a same-name type/body drift")
  let library : PsPscv0ModuleSource := {
    name := "Library"
    source := "namespace Library\nfunction double(value: Nat): Nat := Nat.add(value, value)\nend Library\n" }
  let facade : PsPscv0ModuleSource := {
    name := "Facade"
    source := "public import Library\nnamespace Facade\nconst greeting: Nat := 3\nend Facade\n" }
  let client : PsPscv0ModuleSource := {
    name := "Client"
    source := "import Facade\nconst answer: Nat := Library.double(7)\n" }
  let direct : PsPscv0ModuleSource := {
    name := "Direct"
    source := "import Library\nconst answer: Nat := Library.double(7)\n" }
  let parsed ← get "project parse" (psPscv0ProjectParse [direct, library])
  let ordered ← get "dependency ordering" (psPscv0ProjectOrder 3 parsed [])
  unless ordered.map (·.name) == ["Library", "Direct"] do
    throw (IO.userError "module graph dependency order")
  let unused : PsPscv0ModuleSource := {
    name := "Unused", source := "const answer: Nat := 99\n" }
  let trimmed ← get "entry dependency closure"
    (psCompilerPreparePscv0Project "Direct" [unused, direct, library])
  unless trimmed.origins.length == 2 &&
      !trimmed.origins.any (fun origin => origin.moduleName == "Unused") do
    throw (IO.userError "unreachable module entered compiled project closure")
  let prepared ← get "checked public imports"
    (psCompilerPreparePscv0Project "Client" [client, facade, library])
  unless prepared.mainNames.any (fun n => psNameToString n == "answer") &&
      prepared.libraryNames.any (fun n => psNameToString n == "Library.double") do
    throw (IO.userError "module graph missing imported checked declaration")
  let cycleA : PsPscv0ModuleSource := {
    name := "A", source := "import B\nconst one: Nat := 1\n" }
  let cycleB : PsPscv0ModuleSource := {
    name := "B", source := "import A\nconst two: Nat := 2\n" }
  if (psCompilerPreparePscv0Project "A" [cycleA, cycleB]).isOk then
    throw (IO.userError "module graph accepted a cycle")
  if (psPscv0ProjectParse [{ name := "A", source := "import Missing\nconst x: Nat := 1\n" }]).isOk then
    throw (IO.userError "module graph accepted missing import")
  -- The very same source graph must pass independent official Lean checking and
  -- target IR admission, not just the pure graph planner.
  let hiddenFacade : PsPscv0ModuleSource := {
    name := "HiddenFacade"
    source := "import Library\nnamespace HiddenFacade\nconst local: Nat := Library.double(2)\nend HiddenFacade\n" }
  let hiddenClient := "import HiddenFacade\nconst leaked: Nat := Library.double(7)\n"
  let opacityClient := "import Library\ntheorem cannotUnfold: Library.double(7) = 14 := by { rfl }\n"
  let vault : PsPscv0ModuleSource := {
    name := "Vault"
    source := "namespace Vault\nprivate const hidden: Nat := 4\nfunction addHidden(value: Nat): Nat := Nat.add(hidden, value)\nend Vault\n" }
  let privateClient := "import Vault\nopen Vault\nconst answer: Nat := addHidden(3)\n"
  let privateLeak := "import Vault\nconst stolen: Nat := Vault.hidden\n"
  let publicRoot := "public import Vault\nconst answer: Nat := Vault.addHidden(2)\n"
  let privateRoot := "import Vault\nprivate const local: Nat := 2\nconst answer: Nat := Nat.add(local, Vault.addHidden(2))\n"
  let scopedProject ← get "private declaration interface"
    (psCompilerPreparePscv0Project "PrivateClient" [
      vault, { name := "PrivateClient", source := privateClient }])
  unless scopedProject.mainNames.any (fun n => psNameToString n == "answer") &&
      scopedProject.libraryNames.any (fun n =>
        psNameToString n == "$psc0Private.Vault.Vault.hidden") do
    throw (IO.userError "module private member lost from runtime library closure")
  let left : PsPscv0ModuleSource := {
    name := "Left", source := "public import Vault\nconst left: Nat := 1\n" }
  let right : PsPscv0ModuleSource := {
    name := "Right", source := "public import Vault\nconst right: Nat := 2\n" }
  let diamond : PsPscv0ModuleSource := {
    name := "Diamond"
    source := "import Left\nimport Right\nconst answer: Nat := Vault.addHidden(3)\n" }
  let closure ← get "checked diamond import"
    (psCompilerPreparePscv0Project "Diamond" [diamond, left, right, vault])
  unless closure.mainNames.any (fun n => psNameToString n == "answer") do
    throw (IO.userError "diamond import lost its checked public identity")
  -- A generated, checked typeclass instance is part of the public module
  -- interface and must survive two re-export routes without duplicate
  -- registration or loss of its actual source declaration provenance.
  let palette : PsPscv0ModuleSource := {
    name := "Palette"
    source := "namespace Palette\ninductive Shade where { | red | blue } deriving Inhabited\nend Palette\n" }
  let leftExport : PsPscv0ModuleSource := {
    name := "LeftExport", source := "public import Palette\nconst leftTag: Nat := 1\n" }
  let rightExport : PsPscv0ModuleSource := {
    name := "RightExport", source := "public import Palette\nconst rightTag: Nat := 2\n" }
  let derivedClient : PsPscv0ModuleSource := {
    name := "DerivedClient"
    source := "import LeftExport\nimport RightExport\nconst chosen: Palette.Shade := Inhabited.default\n" }
  let derived ← get "public derived-instance diamond"
    (psCompilerPreparePscv0Project "DerivedClient"
      [derivedClient, leftExport, rightExport, palette])
  unless derived.mainNames.any (fun name => psNameToString name == "chosen") &&
      derived.libraryNames.any (fun name =>
        psNameToString name == "Palette.Shade.instInhabited") &&
      derived.origins.any (fun owner => owner.moduleName == "Palette" &&
        owner.batches.any (fun batch =>
          batch.members.any (fun member =>
            match member.role with
            | .derivedInstance => true
            | _ => false))) do
    throw (IO.userError "derived typeclass instance lost across public-import diamond")
  let aliases : PsPscv0ModuleSource := {
    name := "Aliases"
    source := "namespace Aliases\nabbrev six: Nat := 6\nfunction twice(value: Nat): Nat := Nat.add(value, value)\nend Aliases\n" }
  let abbreviationClient :=
    "import Aliases\ntheorem exposed: Aliases.six = 6 := by { rfl }\n"
  let abbreviationOpacity :=
    "import Aliases\ntheorem cannotUnfold: Aliases.twice(3) = 6 := by { rfl }\n"
  let invalidExposed : PsPscv0ModuleSource := {
    name := "InvalidExposed"
    source := "namespace InvalidExposed\nprivate const seed: Nat := 9\nabbrev leaked: Nat := seed\nend InvalidExposed\n" }
  if (psCompilerPreparePscv0Project "InvalidExposed" [invalidExposed]).isOk then
    throw (IO.userError "exposed abbreviation body leaked private declaration")
  let privateA : PsPscv0ModuleSource := {
    name := "PrivateA"
    source := "private const same: Nat := 3\nfunction leftValue(value: Nat): Nat := Nat.add(same, value)\n" }
  let privateB : PsPscv0ModuleSource := {
    name := "PrivateB"
    source := "private const same: Nat := 5\nfunction rightValue(value: Nat): Nat := Nat.add(same, value)\n" }
  let sharedClient : PsPscv0ModuleSource := {
    name := "SharedClient"
    source := "import PrivateA\nimport PrivateB\nconst answer: Nat := Nat.add(leftValue(1), rightValue(1))\n" }
  let isolated ← get "module-local private name hygiene"
    (psCompilerPreparePscv0Project "SharedClient" [sharedClient, privateA, privateB])
  unless isolated.mainNames.any (fun name => psNameToString name == "answer") &&
      isolated.libraryNames.any (fun name =>
        psNameToString name == "$psc0Private.PrivateA.same") &&
      isolated.libraryNames.any (fun name =>
        psNameToString name == "$psc0Private.PrivateB.same") do
    throw (IO.userError "two private module identities collided or lost scope")
  let rawSource := "const rawQuotes: String := r#\"two \"quotes\" and \\n\"#\ntheorem quotesMatch: rawQuotes = \"two \\\"quotes\\\" and \\\\n\" := by { rfl }\nconst rawLines: String := r\"one\ntwo\"\ntheorem linesMatch: rawLines = \"one\\ntwo\" := by { rfl }\n"
  if (psPscv0ParseProgram "const raw: String := r#\"unterminated\n").isOk then
    throw (IO.userError "raw literal lexer accepted an unterminated delimiter")
  let numeralSource := "const decimal: Nat := 1_234_567\ntheorem decCorrect: decimal = 1234567 := by { rfl }\nconst hexadecimal: Nat := 0xDeaD_Beef\ntheorem hexCorrect: hexadecimal = 3735928559 := by { rfl }\nconst binary: Nat := 0B1010_0011\ntheorem binCorrect: binary = 163 := by { rfl }\nconst octal: Nat := 0o17\ntheorem octCorrect: octal = 15 := by { rfl }\n"
  let invalidNumeral := "const broken: Nat := 0x_\n"
  let tostringSource :=
    "const echoed: String := toString(\"ready\")\n" ++
    "theorem stringIdentity: echoed = \"ready\" := by { rfl }\n" ++
    "const represented: String := toString(Int.ofNat(7))\n" ++
    "const naturalText: String := toString(42)\n" ++
    "const characterText: String := toString('x')\n" ++
    "const booleanText: String := toString(true)\n" ++
    "theorem boolRendering: booleanText = \"true\" := by { rfl }\n"
  let standardEqualitySource :=
    "const sameBool: Bool := true == true\n" ++
    "theorem sameBoolProof: sameBool = true := by { rfl }\n" ++
    "const differentBool: Bool := false == true\n" ++
    "theorem differentBoolProof: differentBool = false := by { rfl }\n" ++
    "const sameChar: Bool := 'x' == 'x'\n" ++
    "const differentChar: Bool := 'x' != 'y'\n" ++
    "const sameUnit: Bool := () == ()\n"
  let optionLibrarySource :=
    "function bump(n: Nat): Nat := Nat.succ(n)\n" ++
    "const mapped: Option Nat := Option.map(bump, Option.some(3))\n" ++
    "theorem mappedCorrect: mapped = Option.some(4) := by { rfl }\n" ++
    "const fallback: Nat := Option.getD(Option.none, 9)\n" ++
    "theorem fallbackCorrect: fallback = 9 := by { rfl }\n" ++
    "const bound: Option Nat := Option.bind(Option.some(3), Option.some)\n" ++
    "theorem boundCorrect: bound = Option.some(3) := by { rfl }\n"
  let listLibrarySource :=
    "function bumpList(n: Nat): Nat := Nat.succ(n)\n" ++
    "function addList(a: Nat, b: Nat): Nat := Nat.add(a, b)\n" ++
    "const listCount: Nat := List.length([2, 3, 4])\n" ++
    "theorem listCountProof: listCount = 3 := by { rfl }\n" ++
    "const listMapped: List Nat := List.map(bumpList, [2, 3])\n" ++
    "theorem listMappedProof: listMapped = [3, 4] := by { rfl }\n" ++
    "const listAppended: List Nat := List.append([2, 3], [4])\n" ++
    "theorem listAppendedProof: listAppended = [2, 3, 4] := by { rfl }\n" ++
    "const listFiltered: List Nat := List.filter(fun (n: Nat) => true, [2, 3])\n" ++
    "theorem listFilteredProof: listFiltered = [2, 3] := by { rfl }\n" ++
    "const listFolded: Nat := List.foldl(addList, 0, [1, 2, 3])\n" ++
    "theorem listFoldedProof: listFolded = 6 := by { rfl }\n"
  let listSafeIndexSource :=
    "const headSafe: Option Nat := List.get?([10, 20], 0)\n" ++
    "theorem headSafeProof: headSafe = Option.some(10) := by { rfl }\n" ++
    "const tailSafe: Option Nat := List.get?([10, 20], 1)\n" ++
    "theorem tailSafeProof: tailSafe = Option.some(20) := by { rfl }\n" ++
    "const beyondSafe: Option Nat := List.get?([10, 20], 5)\n" ++
    "theorem beyondSafeProof: beyondSafe = Option.none := by { rfl }\n"
  let collectionCompletionSource :=
    "const hasValue: Bool := Option.isSome(Option.some(3))\n" ++
    "theorem hasValueProof: hasValue = true := by { rfl }\n" ++
    "const absentValue: Option Nat := Option.none\n" ++
    "const missingValue: Bool := Option.isNone(absentValue)\n" ++
    "theorem missingValueProof: missingValue = true := by { rfl }\n" ++
    "const keptValue: Option Nat := Option.filter(fun (n: Nat) => true, Option.some(3))\n" ++
    "theorem keptValueProof: keptValue = Option.some(3) := by { rfl }\n" ++
    "function listConsHead(n: Nat, xs: List Nat): List Nat := List.cons(n, xs)\n" ++
    "const foldedRight: List Nat := List.foldr(listConsHead, [], [3, 4])\n" ++
    "theorem foldedRightProof: foldedRight = [3, 4] := by { rfl }\n" ++
    "const reversedList: List Nat := List.reverse([1, 2, 3])\n" ++
    "theorem reversedListProof: reversedList = [3, 2, 1] := by { rfl }\n" ++
    "const firstTwo: List Nat := List.take(2, [10, 20, 30])\n" ++
    "theorem firstTwoProof: firstTwo = [10, 20] := by { rfl }\n" ++
    "const beyondLength: List Nat := List.take(9, [10, 20])\n" ++
    "theorem beyondLengthProof: beyondLength = [10, 20] := by { rfl }\n" ++
    "const emptyPrefix: List Nat := List.take(0, [10, 20])\n" ++
    "theorem emptyPrefixProof: emptyPrefix = [] := by { rfl }\n" ++
    "const remaining: List Nat := List.drop(2, [10, 20, 30])\n" ++
    "theorem remainingProof: remaining = [30] := by { rfl }\n" ++
    "const noneRemain: List Nat := List.drop(9, [10, 20])\n" ++
    "theorem noneRemainProof: noneRemain = [] := by { rfl }\n" ++
    "const allRemain: List Nat := List.drop(0, [10, 20])\n" ++
    "theorem allRemainProof: allRemain = [10, 20] := by { rfl }\n"
  let inhabitedSource :=
    "const defaultNat: Nat := Inhabited.default\n" ++
    "theorem defaultNatProof: defaultNat = 0 := by { rfl }\n" ++
    "const defaultBool: Bool := Inhabited.default\n" ++
    "theorem defaultBoolProof: defaultBool = false := by { rfl }\n" ++
    "const defaultString: String := Inhabited.default\n" ++
    "const defaultOption: Option Nat := Inhabited.default\n" ++
    "theorem defaultOptionProof: defaultOption = Option.none := by { rfl }\n" ++
    "const defaultList: List Nat := Inhabited.default\n" ++
    "theorem defaultListProof: defaultList = [] := by { rfl }\n" ++
    "const defaultArray: Array Nat := Inhabited.default\n"
  let noInhabited := "const impossible: Empty := Inhabited.default\n"
  let derivingInhabitedSource :=
    "inductive Signal where { | green | red } deriving Inhabited\n" ++
    "const chosen: Signal := Inhabited.default\n" ++
    "theorem chosenProof: chosen = Signal.green := by { rfl }\n"
  let derivingMissingCtor :=
    "inductive NoConstructor where { } deriving Inhabited\n"
  let derivingPayload :=
    "inductive Payload where { | make(value: Nat) } deriving Inhabited\n" ++
    "const payload: Payload := Inhabited.default\n" ++
    "theorem payloadProof: payload = Payload.make(0) := by { rfl }\n"
  let derivingStructure :=
    "structure Defaults where {\n  count: Nat\n  enabled: Bool\n} deriving Inhabited\n" ++
    "const recordDefault: Defaults := Inhabited.default\n" ++
    "theorem countProof: recordDefault.count = 0 := by { rfl }\n"
  let derivingEnumRepr :=
    "inductive Shade where { | dark | light } deriving Repr\n" ++
    "const shadeText: String := reprStr(Shade.dark)\n"
  let derivingEnumEqualitySource :=
    "inductive Traffic where { | red | yellow | green } deriving BEq, Inhabited\n" ++
    "const equalRed: Bool := Traffic.red == Traffic.red\n" ++
    "theorem equalRedCorrect: equalRed = true := by { rfl }\n" ++
    "const differentTags: Bool := Traffic.red == Traffic.green\n" ++
    "theorem differentTagsCorrect: differentTags = false := by { rfl }\n" ++
    "const defaultTraffic: Traffic := Inhabited.default\n" ++
    "theorem defaultTrafficCorrect: defaultTraffic = Traffic.red := by { rfl }\n"
  let derivingEnumFieldRefusal :=
    "structure UnsupportedRecord where {\n  fn: Nat -> Nat\n} deriving BEq\n"
  let derivingStructureEqualitySource :=
    "structure RecordPoint where {\n  first: Nat\n  enabled: Bool\n} deriving BEq\n" ++
    "const pointsEqual: Bool := RecordPoint.mk(3, true) == RecordPoint.mk(3, true)\n" ++
    "theorem pointsEqualProof: pointsEqual = true := by { rfl }\n" ++
    "const pointsDiffer: Bool := RecordPoint.mk(3, true) == RecordPoint.mk(3, false)\n" ++
    "theorem pointsDifferProof: pointsDiffer = false := by { rfl }\n"
  let derivingStringBEqSource :=
    "structure StringTag where {\n  value: String\n} deriving BEq\n" ++
    "const stringTagEq: Bool := StringTag.mk(\"hi\") == StringTag.mk(\"hi\")\n" ++
    "const stringTagNe: Bool := StringTag.mk(\"hi\") == StringTag.mk(\"bye\")\n"
  let derivingPayloadBEqSource :=
    "inductive CellLabel where { | empty | count(value: Nat) | enabled(value: Bool) } deriving BEq\n" ++
    "const samePayload: Bool := CellLabel.count(3) == CellLabel.count(3)\n" ++
    "theorem samePayloadProof: samePayload = true := by { rfl }\n" ++
    "const otherPayload: Bool := CellLabel.count(3) == CellLabel.count(4)\n" ++
    "theorem otherPayloadProof: otherPayload = false := by { rfl }\n" ++
    "const otherCtor: Bool := CellLabel.count(3) == CellLabel.enabled(true)\n" ++
    "theorem otherCtorProof: otherCtor = false := by { rfl }\n"
  let derivingRecursiveBEqRefusal :=
    "inductive RecursiveCell where { | nil | cons(next: RecursiveCell) } deriving BEq\n"
  let optionEqualitySource :=
    "const a: Option Nat := Option.some(3)\n" ++
    "const equalSome: Bool := a == Option.some(3)\n" ++
    "theorem equalSomeProof: equalSome = true := by { rfl }\n" ++
    "const otherSome: Bool := a == Option.some(4)\n" ++
    "theorem otherSomeProof: otherSome = false := by { rfl }\n" ++
    "const emptyBox: Option Nat := Option.none\n" ++
    "const noneEqualsNone: Bool := emptyBox == emptyBox\n" ++
    "theorem noneEqualsNoneProof: noneEqualsNone = true := by { rfl }\n"
  let optionEqualityRefusal :=
    "const boxed: Option(Nat -> Nat) := Option.none\n" ++
    "const badEq: Bool := boxed == boxed\n"
  let listEqualitySource :=
    "const listEqLeft: List Nat := [1, 2, 3]\n" ++
    "const listEqRight: List Nat := [1, 2, 3]\n" ++
    "const listEqual: Bool := listEqLeft == listEqRight\n" ++
    "theorem listEqualProof: listEqual = true := by { rfl }\n" ++
    "const listOther: List Nat := [1, 2, 4]\n" ++
    "const listDifferent: Bool := listEqLeft == listOther\n" ++
    "theorem listDifferentProof: listDifferent = false := by { rfl }\n"
  let listEqualityRefusal :=
    "const listOfFunctions: List(Nat -> Nat) := []\n" ++
    "const missingEq: Bool := listOfFunctions == listOfFunctions\n"
  let checkedProducts :=
    "const productDefault: Prod Nat Bool := Inhabited.default\n" ++
    "theorem productDefaultProof: productDefault = (0, false) := by { rfl }\n" ++
    "const samePair: Bool := (2, true) == (2, true)\n" ++
    "theorem samePairProof: samePair = true := by { rfl }\n" ++
    "const differentPair: Bool := (2, true) == (2, false)\n" ++
    "theorem differentPairProof: differentPair = false := by { rfl }\n" ++
    "const nestedPair: Prod(Option Nat, List Bool) := (Option.some(1), [true])\n" ++
    "const nestedPairEqualsSelf: Bool := nestedPair == nestedPair\n" ++
    "theorem nestedPairProof: nestedPairEqualsSelf = true := by { rfl }\n"
  let productMissingEquality :=
    "const functions: Prod((Nat -> Nat), Nat) := (fun (x: Nat) => x, 1)\n" ++
    "const shouldFail: Bool := functions == functions\n"
  let checkedExcept :=
    "function increment(n: Nat): Nat := Nat.succ(n)\n" ++
    "const sourceOk: Except String Nat := Except.ok(4)\n" ++
    "const mapped: Except String Nat := Except.map(increment, sourceOk)\n" ++
    "theorem mappedProof: mapped = Except.ok(5) := by { rfl }\n" ++
    "const chained: Except String Nat := Except.bind(sourceOk, fun (n: Nat) => Except.ok(Nat.succ(n)))\n" ++
    "theorem chainedProof: chained = Except.ok(5) := by { rfl }\n" ++
    "const sourceError: Except String Nat := Except.error(\"bad\")\n" ++
    "const mappedError: Except Nat Nat := Except.mapError(fun (s: String) => 3, sourceError)\n" ++
    "theorem mappedErrorProof: mappedError = Except.error(3) := by { rfl }\n" ++
    "const mappedErrorRuntime: Except Nat Nat := Except.mapError(fun (s: String) => String.Internal.length(s), sourceError)\n" ++
    "const recovered: Except String Nat := Except.tryCatch(sourceError, fun (s: String) => Except.ok(3))\n" ++
    "theorem recoveredProof: recovered = Except.ok(3) := by { rfl }\n" ++
    "const recoveredRuntime: Except String Nat := Except.tryCatch(sourceError, fun (s: String) => Except.ok(String.Internal.length(s)))\n" ++
    "const successFlag: Bool := Except.isOk(sourceOk)\n" ++
    "theorem successFlagProof: successFlag = true := by { rfl }\n" ++
    "const absent: Option Nat := Except.toOption(sourceError)\n" ++
    "theorem absentProof: absent = Option.none := by { rfl }\n" ++
    "const returned: Except String Nat := Except.pure(7)\n" ++
    "theorem returnedProof: returned = Except.ok(7) := by { rfl }\n" ++
    "const reflected: Bool := Except.toBool(sourceOk)\n" ++
    "theorem reflectedProof: reflected = true := by { rfl }\n" ++
    "const fallbackResult: Except String Nat := Except.orElseLazy(sourceError, fun (_: Unit) => Except.ok(12))\n" ++
    "theorem fallbackResultProof: fallbackResult = Except.ok(12) := by { rfl }\n" ++
    "const keptSuccess: Except String Nat := Except.orElseLazy(sourceOk, fun (_: Unit) => Except.ok(19))\n" ++
    "theorem keptSuccessProof: keptSuccess = sourceOk := by { rfl }\n"
  let exceptTypeMismatch :=
    "const bad: Except String Nat := Except.map(Nat.succ, Option.some(1))\n"
  let interpolationSource :=
    "const msg: String := s!\"Value {42}, flag {true}\"\n" ++
    "const inner: String := s!\"Embedded {String.Internal.append(\"x\", \"y\")}\"\n" ++
    "const braces: String := s!\"double {{braces}}\"\n" ++
    "theorem bracesExact: braces = \"double {braces}\" := by { rfl }\n"
  let invalidInterpolation := "const msg: String := s!\"unfinished {12\"\n"
  let requests : Array PsV7Native.Request := #[
    { source := direct.source, moduleName := "Direct", modules := [library],
      targets := [.javascript, .typescript, .rust] },
    { source := client.source, moduleName := "Client", modules := [library, facade] },
    { source := hiddenClient, moduleName := "HiddenClient", modules := [library, hiddenFacade] },
    { source := opacityClient, moduleName := "Opacity", modules := [library] },
    { source := privateClient, moduleName := "PrivateClient", modules := [vault],
      targets := [.javascript] },
    { source := privateLeak, moduleName := "Leaker", modules := [vault] },
    { source := publicRoot, moduleName := "PublicRoot", modules := [vault],
      targets := [.javascript] },
    { source := privateRoot, moduleName := "PrivateRoot", modules := [vault],
      targets := [.javascript] },
    { source := abbreviationClient, moduleName := "AbbrevClient", modules := [aliases] },
    { source := abbreviationOpacity, moduleName := "AbbrevOpacity", modules := [aliases] },
    { source := sharedClient.source, moduleName := "SharedClient",
      modules := [privateA, privateB], targets := [.javascript] },
    { source := rawSource, moduleName := "RawStrings" },
    { source := numeralSource, moduleName := "RadixNumerals" },
    { source := invalidNumeral, moduleName := "InvalidNumeral" },
    { source := tostringSource, moduleName := "StandardToString",
      targets := [.javascript, .typescript, .rust] },
    { source := interpolationSource, moduleName := "Interpolated",
      targets := [.javascript, .typescript, .rust] },
    { source := invalidInterpolation, moduleName := "InvalidInterpolation" },
    { source := standardEqualitySource, moduleName := "StandardEquality",
      targets := [.javascript, .typescript, .rust] },
    { source := optionLibrarySource, moduleName := "StandardOption",
      targets := [.javascript, .typescript, .rust] },
    { source := listLibrarySource, moduleName := "StandardList",
      targets := [.javascript, .typescript, .rust] },
    { source := listSafeIndexSource, moduleName := "SafeListIndex",
      targets := [.javascript, .typescript, .rust] },
    { source := collectionCompletionSource, moduleName := "StandardCollectionCompletion",
      targets := [.javascript, .typescript, .rust] },
    { source := inhabitedSource, moduleName := "StandardInhabited",
      targets := [.javascript, .typescript, .rust] },
    { source := noInhabited, moduleName := "NoInhabited" },
    { source := derivingInhabitedSource, moduleName := "DerivingInhabited",
      targets := [.javascript, .typescript, .rust] },
    { source := derivingMissingCtor, moduleName := "DerivingMissingCtor" },
    { source := derivingEnumRepr, moduleName := "DerivingEnumRepr",
      targets := [.javascript, .typescript, .rust] },
    { source := derivingPayload, moduleName := "DerivingPayload",
      targets := [.javascript, .typescript, .rust] },
    { source := derivingStructure, moduleName := "DerivingStructure",
      targets := [.javascript, .typescript, .rust] },
    { source := derivingEnumEqualitySource, moduleName := "DerivingEnumBEq",
      targets := [.javascript, .typescript, .rust] },
    { source := derivingEnumFieldRefusal, moduleName := "DerivingBEqFields" },
    { source := derivingStructureEqualitySource, moduleName := "DerivingStructureBEq",
      targets := [.javascript, .typescript, .rust] },
    { source := derivingStringBEqSource, moduleName := "DerivingStringBEq",
      targets := [.javascript, .typescript, .rust] },
    { source := derivingPayloadBEqSource, moduleName := "DerivingPayloadBEq",
      targets := [.javascript, .typescript, .rust] },
    { source := derivingRecursiveBEqRefusal, moduleName := "DerivingRecursiveBEq" },
    { source := optionEqualitySource, moduleName := "PolymorphicOptionBEq",
      targets := [.javascript, .typescript, .rust] },
    { source := optionEqualityRefusal, moduleName := "OptionBEqMissingElem" },
    { source := listEqualitySource, moduleName := "PolymorphicListBEq",
      targets := [.javascript, .typescript, .rust] },
    { source := listEqualityRefusal, moduleName := "ListBEqMissingElem" },
    { source := checkedProducts, moduleName := "CheckedProduct",
      targets := [.javascript, .typescript, .rust] },
    { source := productMissingEquality, moduleName := "ProductBEqMissingElem" },
    { source := checkedExcept, moduleName := "CheckedExcept",
      targets := [.javascript, .typescript, .rust] },
    { source := exceptTypeMismatch, moduleName := "ExceptTypeMismatch" }]
  let checked ← match ← PsV7Native.runBatch requests with
    | .ok result => pure result
    | .error error => throw (IO.userError ("module host prelude: " ++ error.message))
  for i in [:requests.size] do
    let some outcome := checked.results[i]?
      | throw (IO.userError "module host outcome missing")
    match i, outcome with
    | 0, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "module host target artifact closure")
        for artifact in value.artifacts do
          if artifact.exports.any (fun e => e.semanticName == "Library.double") then
            throw (IO.userError "ordinary imported runtime symbol leaked into public API")
    | 1, .ok _ | 8, .ok _ | 11, .ok _ | 12, .ok _ => pure ()
    | 4, .ok value | 6, .ok value | 7, .ok value | 10, .ok value =>
        unless value.artifacts.length == 1 do
          throw (IO.userError "module linked JS artifact missing")
        let some artifact := value.artifacts.head?
          | throw (IO.userError "module linked artifact missing")
        unless artifact.exports.all (fun e => e.semanticName == "answer") do
          throw (IO.userError "private or re-exported library name leaked into entry API")
    | 2, .error error | 3, .error error | 5, .error error | 9, .error error =>
        unless error.phase == "module" do
          throw (IO.userError ("module visibility/reflexivity checked at wrong boundary: " ++ error.phase))
    | 14, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "checked ToString dictionary missing backend artifacts")
    | 14, .error error =>
        throw (IO.userError ("ToString exported-alias check failed at " ++
          error.phase ++ ": " ++ error.message))
    | 15, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "interpolation missing multi-target checked artifacts")
    | 15, .error error =>
        throw (IO.userError ("interpolation failed at " ++ error.phase ++
          ": " ++ error.message))
    | 16, .error error =>
        unless error.phase == "parse" do
          throw (IO.userError ("invalid interpolation was not rejected by the lexical/parser boundary: " ++
            error.phase ++ ": " ++ error.message))
    | 17, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "checked BEq instances missing cross-target artifacts")
    | 17, .error error =>
        throw (IO.userError ("checked BEq Standard case failed at " ++
          error.phase ++ ": " ++ error.message))
    | 18, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "checked Option API missing backend artifacts")
    | 18, .error error =>
        throw (IO.userError ("checked Option API failed at " ++
          error.phase ++ ": " ++ error.message))
    | 19, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "checked List APIs missing multi-target artifacts")
    | 19, .error error =>
        throw (IO.userError ("checked List APIs failed at " ++
          error.phase ++ ": " ++ error.message))
    | 20, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "List.get? safe-indexing missing checked artifacts")
    | 20, .error error =>
        throw (IO.userError ("List.get? safe-indexing failed at " ++
          error.phase ++ ": " ++ error.message))
    | 21, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "checked collection API missing backend artifacts")
    | 21, .error error =>
        throw (IO.userError ("collection API completion failed at " ++
          error.phase ++ ": " ++ error.message))
    | 22, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "checked Inhabited Standard missing backend artifacts")
    | 22, .error error =>
        throw (IO.userError ("checked Inhabited Standard failed at " ++
          error.phase ++ ": " ++ error.message))
    | 23, .error error =>
        unless error.phase == "elaborate" do
          throw (IO.userError "uninhabited Empty was not rejected during synthesis")
    | 24, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "derived Inhabited instance missing checked artifacts")
    | 24, .error error =>
        throw (IO.userError ("deriving Inhabited rejected at " ++ error.phase ++ ": " ++ error.message))
    | 26, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "derived enum Repr missing checked target artifacts")
    | 26, .error error =>
        throw (IO.userError ("derived enum Repr failed at " ++ error.phase ++ ": " ++ error.message))
    | 25, .error error =>
        unless error.phase == "elaborate" do
          throw (IO.userError "unsupported deriving did not fail during elaboration")
    | 27, .ok value | 28, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "derived payload/structure missing checked artifacts")
    | 27, .error error | 28, .error error =>
        throw (IO.userError ("derived payload/structure failed at " ++
          error.phase ++ ": " ++ error.message))
    | 29, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "derived enumeration BEq missing target artifacts")
    | 29, .error error =>
        throw (IO.userError ("derived enumeration BEq failed at " ++
          error.phase ++ ": " ++ error.message))
    | 30, .error error =>
        unless error.phase == "elaborate" do
          throw (IO.userError "missing field BEq instance did not refuse at elaboration")
    | 31, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "checked structure BEq missing backend artifacts")
    | 31, .error error =>
        throw (IO.userError ("checked structure BEq failed at " ++
          error.phase ++ ": " ++ error.message))
    | 32, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "derived string structure BEq lacks target artifacts")
    | 32, .error error =>
        throw (IO.userError ("derived string structure BEq failed at " ++
          error.phase ++ ": " ++ error.message))
    | 33, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "nonrecursive payload BEq lacks checked artifacts")
    | 33, .error error =>
        throw (IO.userError ("nonrecursive payload BEq failed at " ++
          error.phase ++ ": " ++ error.message))
    | 34, .error error =>
        unless error.phase == "elaborate" do
          throw (IO.userError "recursive payload BEq did not fail during elaboration")
    | 35, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "polymorphic Option BEq missing target artifacts")
    | 35, .error error =>
        throw (IO.userError ("polymorphic Option BEq failed at " ++
          error.phase ++ ": " ++ error.message))
    | 36, .error error =>
        unless error.phase == "elaborate" do
          throw (IO.userError "missing element BEq failed outside elaboration")
    | 37, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "polymorphic List BEq missing target artifacts")
    | 37, .error error =>
        throw (IO.userError ("polymorphic List BEq failed at " ++
          error.phase ++ ": " ++ error.message))
    | 38, .error error =>
        unless error.phase == "elaborate" do
          throw (IO.userError "missing list-element BEq failed outside elaboration")
    | 39, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "checked Prod dictionaries missing backend artifacts")
    | 39, .error error =>
        throw (IO.userError ("checked Prod dictionaries failed at " ++
          error.phase ++ ": " ++ error.message))
    | 40, .error error =>
        unless error.phase == "elaborate" do
          throw (IO.userError "unsupported Prod component equality accepted")
    | 41, .ok value =>
        unless value.artifacts.length == 3 do
          throw (IO.userError "checked Except operations missing backend artifacts")
    | 41, .error error =>
        throw (IO.userError ("checked Except operations failed at " ++
          error.phase ++ ": " ++ error.message))
    | 42, .error error =>
        unless error.phase == "elaborate" do
          throw (IO.userError "ill-typed Except.map argument accepted")
    | 13, .error error =>
        unless error.phase == "elaborate" do
          throw (IO.userError "invalid radix literal was not refused by elaboration")
    | _, _ => throw (IO.userError s!"module official checker acceptance mismatch {i}")
  IO.println "PSCV0_NATIVE_MODULES: PASS module boundaries, RC4 raw/radix, checked ToString dictionaries, abbreviation exposure and entry exports"

private def derivingBoundaries : IO Unit := do
  -- Type-valued fields exercise kernel projection inference only; their runtime
  -- representation is outside the selected backend subset.
  let projection : PsV7Native.Request := {
    source := "universe u\nstructure TypeField: Type (u + 1) where { value: Type u }\nconst record: TypeField := TypeField.mk(Nat)\nconst projected: Type := record.value\ntheorem correct: projected = Nat := by { rfl }\nfunction emptyList{A: Type u}(unit: Unit): List A := Inhabited.default\nfunction equalLists{A: Type u}[BEq A](xs: List A, ys: List A): Bool := List.beq(xs, ys)\ntheorem emptyTypes: emptyList(A := Type, unit := Unit.unit) = List.nil := by { rfl }\nfunction listProof{A: Type u}(xs: List A, i: Nat, h: Nat.lt(i, List.length(xs))): A := xs[i]'h\nfunction listOptional{A: Type u}(xs: List A, i: Nat): Option A := xs[i]?\nfunction listBang{A: Type u}[Inhabited A](xs: List A, i: Nat): A := xs[i]!\nfunction listPublicBang{A: Type u}[Inhabited A](xs: List A, i: Nat): A := List.get!(xs, i)\nfunction requireListLaw{A: Type u}[LawfulGetElem(List A, Nat, A, fun xs => fun i => Nat.lt(i, List.length(xs)))](xs: List A): Nat := List.length(xs)\nfunction listLaw{A: Type u}(xs: List A): Nat := requireListLaw(xs)\ntheorem typeIndex: listOptional([Nat], 0) = Option.some(Nat) := by { rfl }\n" }
  let requests : Array PsV7Native.Request := #[
    { source := "universe u\nstructure Box(A: Type u): Type u where { value: A } deriving BEq\nfunction bad(x: Box(Nat -> Nat)): Bool := x == x\n" },
    { source := "structure Dependent where {\n  n: Nat\n  value: Fin n\n} deriving BEq\n" },
    { source := "universe u\ninductive Chain(A: Type u): Type u where { | nil | cons(head: A, tail: Chain A) } deriving BEq\n" },
    { source := "structure Bad where { f: Nat -> Nat } deriving DecidableEq\n" },
    { source := "structure Bad where {\n n: Nat\n value: Fin n\n} deriving DecidableEq\n" },
    { source := "inductive Bad where { | nil | cons(next: Bad) } deriving DecidableEq\n" },
    { source := "inductive Bad: Nat -> Type where { | intro(n: Nat): Bad n } deriving DecidableEq\n" },
    { source := "structure Bad where { value: Nat := true } deriving Inhabited\n" },
    { source := "structure Bad where { f: Nat -> Nat } deriving Repr\n" },
    { source := "inductive Bad where { | loop(tail: Bad) } deriving Repr\n" },
    { source := "structure Required where { value: Nat }\nconst bad: Required := {}\n" }
  ]
  let batch ← match ← PsV7Native.runBatch (#[projection] ++ requests) with
    | .ok batch => pure batch
    | .error error => throw (IO.userError ("deriving host prelude: " ++ error.message))
  let some projectionResult := batch.results[0]?
    | throw (IO.userError "projection qualification missing")
  match projectionResult with
  | .ok _ => pure ()
  | .error error => throw (IO.userError ("projection universe inference: " ++ error.message))
  for result in batch.results.toList.drop 1 do
    match result with
    | .error error =>
      unless error.phase == "elaborate" do
        throw (IO.userError ("deriving refusal escaped elaboration: " ++ error.phase ++ ": " ++ error.message))
    | .ok _ => throw (IO.userError "deriving admitted an unsupported comparison")
  IO.println "PSCV0_DERIVING_BOUNDARIES: PASS dictionaries, dependent runtime fields, recursion, indices, ill-typed defaults and missing required fields"

private def syntheticBoundaries : IO Unit := do
  let environment := psSelfHostProdPreludeEnvironment
  let nat := PsExpr.constE psNatName []
  let type := PsExpr.sortE (.succ .zero)
  -- A dependent template contains A : Sort ?u followed by x : A. Opening it
  -- twice in one recipient must allocate independent term and universe IDs.
  let freshLevel := psMetaFreshLevel psMetaEmpty
  let a := psMetaFresh freshLevel.context psLocalEmpty (.sortE freshLevel.level) .natural
  let x := psMetaFresh a.context psLocalEmpty a.expr .natural
  let some template := psMetaAbstract x.context psLocalEmpty x.expr a.expr |
    throw (IO.userError "dependent natural answer could not be abstracted")
  let occupied := psMetaFresh psMetaEmpty psLocalEmpty nat .natural
  let some (firstContext, firstValue, firstType) :=
      psMetaOpenTemplate occupied.context psLocalEmpty template |
    throw (IO.userError "first dependent answer could not be opened")
  let some (secondContext, secondValue, secondType) :=
      psMetaOpenTemplate firstContext psLocalEmpty template |
    throw (IO.userError "second dependent answer could not be opened")
  unless template.parameters.length == 2 && template.levels == 1 &&
      !psExprAlphaEq firstValue secondValue && !psExprAlphaEq firstType secondType &&
      secondContext.levels.nextId == 2 do
    throw (IO.userError "template replay aliased term or universe variables")
  let first := psUnify environment psLocalEmpty secondContext firstType nat
  let second := psUnify environment psLocalEmpty first.context secondType (.constE psBoolName [])
  unless first.success && second.success &&
      psExprAlphaEq (psMetaInstantiate second.context firstType) nat &&
      psExprAlphaEq (psMetaInstantiate second.context secondType) (.constE psBoolName []) do
    throw (IO.userError "shared answer specializations interfered")
  for kind in [PsMetaVarKind.synthetic, .syntheticOpaque] do
    let obligation := psMetaFresh psMetaEmpty psLocalEmpty nat kind
    if (psMetaAbstract obligation.context psLocalEmpty obligation.expr nat).isSome then
      throw (IO.userError "an outstanding synthetic obligation became an answer parameter")
  let captured := psLocalPushBinding psLocalEmpty (psRootName "n") nat .explicit
  let hole := psMetaFresh psMetaEmpty captured.context nat .natural
  let some scopedTemplate := psMetaAbstract hole.context captured.context hole.expr nat |
    throw (IO.userError "scoped answer abstraction failed")
  if (psMetaOpenTemplate psMetaEmpty psLocalEmpty scopedTemplate).isSome then
    throw (IO.userError "answer template escaped its captured scope")
  -- A mandatory type default unlocks an earlier dictionary and equality.
  let defaultType := psMetaFresh psMetaEmpty psLocalEmpty type .syntheticOpaque
  let .mvar defaultId := defaultType.expr | throw (IO.userError "default ID")
  let dictionary := psMetaFresh defaultType.context psLocalEmpty
    (psStandardInhabitedType defaultType.expr) .synthetic
  let .mvar dictionaryId := dictionary.expr | throw (IO.userError "dictionary ID")
  let constraints : List PsSyntheticConstraint := [
    .expectedType psLocalEmpty defaultType.expr nat,
    .instanceGoal dictionaryId, .defaultValue defaultId nat]
  let solved := psSyntheticSolve environment environment.instances dictionary.context constraints
  unless solved.pending.isEmpty && !solved.resourceExceeded &&
      (psMetaFindAssignment solved.context dictionaryId).isSome do
    throw (IO.userError "default did not wake shared expected/instance constraints")
  let incompatible := psSyntheticSolve environment environment.instances dictionary.context
    [.expectedType psLocalEmpty defaultType.expr (.constE psBoolName []),
     .defaultValue defaultId nat]
  unless !incompatible.pending.isEmpty &&
      psExprAlphaEq (psMetaInstantiate incompatible.context defaultType.expr) nat do
    throw (IO.userError "expected result replaced a mandatory omitted default")
  let exhausted := psSyntheticSolve environment environment.instances dictionary.context
    constraints true 4
  unless exhausted.resourceExceeded &&
      exhausted.context.assignments.length == dictionary.context.assignments.length do
    throw (IO.userError "synthetic resource refusal leaked assignments")
  let parsed ← get "generalized fixture parse" (psCompilerParsePscv0 generalizedFixture)
  let elaborated ← get "generalized fixture elaboration"
    ((psElabProgram environment parsed).mapError psCompilerPscv0ElabError)
  let resultName := psNameAppendStr (psRootName "Generalized") "Result"
  let evidence := psNameAppendStr (psRootName "Generalized") "Evidence"
  let genericType := PsExpr.forallE (psRootName "A") type
    (.app (.constE evidence [.zero]) (.bvar 0)) .explicit
  let locals := (psLocalPushBinding psLocalEmpty (psRootName "poly")
    genericType .instanceImplicit).context
  let graph := psSynthInstanceWithTable elaborated.environment locals
    elaborated.environment.instances psMetaEmpty 64 (.constE resultName [])
  unless graph.result.value.isSome && graph.table.generalizedAnswers >= 1 &&
      graph.table.freshenedAnswers >= 1 && graph.table.reusedGoals >= 1 do
    throw (IO.userError "generalized generator was not shared between specializations")
  IO.println ("PSCV0_NATIVE_GENERALIZED: answers=" ++ toString graph.table.answers ++
    " generalized=" ++ toString graph.table.generalizedAnswers ++
    " freshened=" ++ toString graph.table.freshenedAnswers ++
    " generators=" ++ toString graph.table.visits)
  let requests : Array PsV7Native.Request := #[
    { source := generalizedFixture ++ "function bad[poly: forall(A: Type), Generalized.Evidence A](unit: Unit): Nat := Generalized.Evidence.value\n" },
    { source := generalizedFixture ++ "const bad: Bool := Generalized.selected()\n" },
    { source := generalizedFixture ++ "instance bad{A: Type}: Generalized.Evidence A where { value := 0 }\n" }]
  -- Type-polymorphic local dictionaries are kernel-qualified. Passing them
  -- as runtime values still needs higher-rank IR; Nat-indexed local dictionaries
  -- above exercise the same answer sharing through the existing runtime IR.
  let positive : PsV7Native.Request := {
    source := generalizedFixture ++
      "const answer: Nat := Generalized.combined(poly := Generalized.generic, unit := ())\n" }
  let rankBoundary := { positive with targets := [.typescript] }
  let batch ← match ← PsV7Native.runBatch (#[positive, rankBoundary] ++ requests) with
    | .ok batch => pure batch
    | .error error => throw (IO.userError ("synthetic host prelude: " ++ error.message))
  let some positiveResult := batch.results[0]? |
    throw (IO.userError "generalized type qualification missing")
  match positiveResult with
  | .ok _ => pure ()
  | .error error => throw (IO.userError ("generalized type qualification: " ++ error.message))
  let some rankResult := batch.results[1]? |
    throw (IO.userError "higher-rank emission boundary missing")
  match rankResult with
  | .error error =>
    unless error.phase == "erase" do
      throw (IO.userError ("higher-rank refusal escaped erasure: " ++ error.message))
  | .ok _ => throw (IO.userError "higher-rank runtime dictionary crossed its IR boundary")
  for result in batch.results.toList.drop 2 do
    match result with
    | .error error =>
      unless error.phase == "elaborate" do
        throw (IO.userError ("synthetic refusal escaped elaboration: " ++ error.message))
    | .ok _ => throw (IO.userError "unresolved root/default conflict was accepted")
  IO.println "PSCV0_NATIVE_SYNTHETIC: PASS scoped templates, independent replay, mandatory defaults, quiescence and rollback"

private def defaultInstanceBoundaries : IO Unit := do
  let environment := psSelfHostProdPreludeEnvironment
  let program ← get "default-instance source" (psCompilerParsePscv0
    (productUniverseFixture ++ defaultInstanceFixture))
  let elaborated ← get "default-instance elaboration"
    ((psElabProgram environment program).mapError psCompilerPscv0ElabError)
  let selected := elaborated.environment
  unless selected.instances.defaults.length == environment.instances.defaults.length + 7 do
    throw (IO.userError "default registry lost a declaration")
  let type := psMetaFresh psMetaEmpty psLocalEmpty (.sortE (.succ .zero)) .natural
  let goal := PsExpr.app (.constE (psDecisionName "DefaultChoice.Choice") []) type.expr
  let dictionary := psMetaFresh type.context psLocalEmpty goal .synthetic
  let .mvar id := dictionary.expr | throw (IO.userError "default goal ID")
  let pending := [PsSyntheticConstraint.instanceGoal id]
  let ordinary := psSyntheticSolve selected selected.instances dictionary.context pending false
  unless !ordinary.pending.isEmpty && ordinary.context.assignments.isEmpty do
    throw (IO.userError "ordinary synthesis guessed a default input")
  let solved := psSyntheticSolve selected selected.instances dictionary.context pending
  unless solved.pending.isEmpty && !solved.resourceExceeded &&
      psExprAlphaEq (psMetaInstantiate solved.context type.expr) (.constE psNatName []) &&
      solved.context.declarations.length == dictionary.context.declarations.length do
    throw (IO.userError "default rollback leaked a rejected candidate or chose the wrong type")
  let exhausted := psSyntheticSolve selected selected.instances dictionary.context pending true 1
  unless exhausted.resourceExceeded && exhausted.context.assignments.isEmpty do
    throw (IO.userError "default queue resource refusal leaked assignments")
  -- Exported tie order and diamond deduplication apply to both registries.
  let view := psPscv0OwnInterface selected elaborated.declarations [] []
  let diamond := psPscv0InterfaceMerge view view
  unless diamond.defaults.length == 7 && diamond.instances.length == view.instances.length do
    throw (IO.userError "default/public-import diamond duplicated evidence")
  let imported ← get "default interface" (psPscv0InstallInterface environment diamond)
  unless (imported.instances.defaults.map psStandardSnapshotInstance) ==
      (selected.instances.defaults.map psStandardSnapshotInstance) do
    throw (IO.userError "import changed default priority or tie order")
  let source :=
    "class PrivateDefault(A: Type) where { pick: Nat }\n" ++
    "@[default_instance] private def hiddenDefault: PrivateDefault Nat := { pick := 5 }\n"
  let parsed ← get "private default parse" (psCompilerParsePscv0 source)
  let privateResult ← get "private default elaboration"
    ((psElabProgramWithOrigins environment parsed "Defaults").mapError psCompilerPscv0ElabError)
  let privateView := psPscv0OwnInterface privateResult.result.environment
    privateResult.result.declarations privateResult.privateNames []
  unless privateResult.result.environment.instances.defaults.length == environment.instances.defaults.length + 1 &&
      privateView.defaults.isEmpty do
    throw (IO.userError "private default escaped its module")
  let bad ← get "nonclass default parse"
    (psCompilerParsePscv0 "@[default_instance] const bad: Nat := 0\n")
  if (psElabProgram environment bad).isOk then
    throw (IO.userError "default attribute accepted a nonclass result")
  -- Default-only declarations cannot rescue definite ordinary failure.
  for source in [
      "class OnlyDefault(A: Type) where { pick: Nat }\n" ++
      "@[default_instance] def onlyDefault: OnlyDefault Nat := { pick := 83 }\n" ++
      "const rejected: Nat := OnlyDefault.pick\n",
      productUniverseFixture ++ defaultInstanceFixture ++
      "const rejected: Nat := DefaultChoice.Preference.pick(A := Bool)\n"] do
    let parsed ← get "default failure parse" (psCompilerParsePscv0 source)
    if (psElabProgram environment parsed).isOk then
      throw (IO.userError "definite ordinary failure incorrectly reached defaulting")
  IO.println "PSCV0_DEFAULT_INSTANCES: PASS priority, transactional dependencies, ordinary quiescence, universes, module visibility and budgets"

private def postponedBoundaries : IO Unit := do
  let requests : Array PsV7Native.Request := #[
    { source := coercionFixture ++ "structure Outer where { box: Coercion.Box }\ninstance chain: Coe(Outer, Coercion.Box) where { coe := Outer.box }\nconst bad: Nat := Outer.mk(Coercion.Box.mk(0))\n" },
    { source := coercionFixture ++ "const bad: Nat := Coercion.Box.mk(0)()\n" },
    { source := "structure Bad where { value: Nat }\ninstance bad: CoeFun(Bad, fun (self: Bad) => Nat) where { coe := Bad.value }\nconst rejected: Nat := Bad.mk(1)()\n" },
    { source := "structure Bad where { value: Nat }\ninstance bad: CoeSort(Bad, Nat) where { coe := Bad.value }\nfunction rejected(x: Bad.mk(0)): Nat := 0\n" },
    { source := numericFixture ++ "const bad: Numeric.Ticket := true\n" },
    { source := "structure NoNumeral where { value: Nat }\nconst bad: NoNumeral := 1\n" },
    { source := "structure Wrong where { value: Nat }\ninstance wrong: OfNat(Wrong, 0) where { ofNat := true }\n" },
    { source := postponedFixture ++
        "const bad: Nat := Postponed.choose({ absent := 1 }, 0)\n" },
    { source := postponedFixture ++
        "const bad: Nat := Postponed.proof(by { rfl }, True.intro)\n" },
    { source := postponedFixture ++
        "const bad: Nat := Postponed.apply(fun x => x.absent, Postponed.Box.mk(0))\n" }]
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok batch => pure batch
    | .error error => throw (IO.userError ("postponed prelude: " ++ error.message))
  for result in batch.results do
    match result with
    | .error error =>
      unless error.phase == "elaborate" do
        throw (IO.userError ("postponed refusal escaped elaboration: " ++ error.message))
    | .ok _ => throw (IO.userError "invalid postponed term was accepted")
  IO.println "PSCV0_POSTPONED: PASS scoped syntax, tactics, numeral fallback and delayed refusal"

private def transparencyBoundaries : IO Unit := do
  let requests : Array PsV7Native.Request := #[
    { source := "abbrev Clear: Type := Nat\nconst numeral: Clear := 937\nconst value: Clear := Inhabited.default\nconst Hidden: Type := Nat\nfunction localEvidence[Inhabited Hidden](unit: Unit): Hidden := Inhabited.default\nconst explicit: Hidden := (937 : Nat)\n" },
    { source := "const Hidden: Type := Nat\nconst bad: Hidden := Inhabited.default\n" },
    { source := "const Hidden: Type := Nat\nconst bad: Hidden := 937\n" },
    { moduleName := "Client",
      source := "import Types\nconst value: Clear := Inhabited.default\nconst numeral: Clear := 937\n",
      modules := [{ name := "Types", source := "abbrev Clear: Type := Nat\n" }] }
  ]
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok batch => pure batch
    | .error error => throw (IO.userError ("transparency prelude: " ++ error.message))
  unless batch.results.size == requests.size do
    throw (IO.userError "transparency result count")
  for (result, i) in batch.results.toList.zipIdx do
    match result with
    | .ok _ =>
      if i == 1 || i == 2 then throw (IO.userError ("ordinary type alias unfolded during instance search: " ++ toString i))
    | .error error =>
      unless (i == 1 || i == 2) && error.phase == "elaborate" do
        throw (IO.userError ("transparency boundary " ++ toString i ++ ": " ++ error.message))
  -- Metadata changes are semantic drift even when every Core declaration is
  -- byte-identical. Cached bucket layout is deliberately absent from the hash.
  let original := psSelfHostProdPreludeEnvironment
  let changed := psEnvironmentSetReducibility original psOptParamName .semireducible
  unless psStandardSnapshotPayload original != psStandardSnapshotPayload changed do
    throw (IO.userError "reducibility missing from frozen semantic payload")
  -- Same observations as the pinned native WHNF oracle above, plus stuck
  -- evidence and an irreducible dictionary. No raw-Nat special case is used.
  let n := PsExpr.lit (.natural 857)
  let nat := PsExpr.constE psNatName []
  let project := fun dictionary => psExprApplyMany
    (.constE (psDecisionName "OfNat.ofNat") [.zero]) [nat, n, dictionary]
  let dictionary := PsExpr.app (.constE (psDecisionName "PsStandard.instOfNatNat") []) n
  let concrete := project dictionary
  let explicit := project (psExprApplyMany
    (.constE (psDecisionName "OfNat.mk") [.zero]) [nat, n, .lit (.natural 42)])
  for mode in [PsTransparency.instances, .«implicit»] do
    unless psExprAlphaEq (psWhnfWithTransparency mode original psMetaEmpty psLocalEmpty concrete) n do
      throw (IO.userError "class projection failed at instance transparency")
    unless psExprAlphaEq (psWhnfWithTransparency mode original psMetaEmpty psLocalEmpty explicit) (.lit (.natural 42)) do
      throw (IO.userError "class projection discarded explicit dictionary evidence")
  unless psExprAlphaEq (psWhnfWithTransparency .reducible original psMetaEmpty psLocalEmpty concrete) concrete do
    throw (IO.userError "class field unfolded at reducible transparency")
  let blocked := psEnvironmentSetReducibility original
    (psDecisionName "PsStandard.instOfNatNat") .irreducible
  unless psExprAlphaEq (psWhnfWithTransparency .instances blocked psMetaEmpty psLocalEmpty concrete) concrete do
    throw (IO.userError "irreducible dictionary unfolded at instance transparency")
  let family := psExprApplyMany (.constE (psRootName "OfNat") [.zero]) [nat, n]
  let pushed := psLocalPushBinding psLocalEmpty (psRootName "dictionary") family .instanceImplicit
  let stuck := project (.fvar pushed.id)
  unless psExprAlphaEq (psWhnfWithTransparency .instances original psMetaEmpty pushed.context stuck) stuck do
    throw (IO.userError "stuck class projection lost its canonical application")
  IO.println "PSCV0_TRANSPARENCY: PASS abbreviations, native class projections, stuck/irreducible evidence, rigid refusal and metadata drift"

-- Pinned Lean 4.35.0 BitVec.toInt gives this exact two's-complement
-- decomposition; these are definitional kernel certificates, not runtime
-- observations or newly assumed arithmetic identities.
private theorem signedToInt8_model (x : Int8) :
    x.toInt =
      (if 2 * x.toUInt8.toNat < 2 ^ 8 then
        (x.toUInt8.toNat : Int)
      else
        (x.toUInt8.toNat : Int) - (2 ^ 8 : Nat)) := by
  rfl

private theorem signedToInt16_model (x : Int16) :
    x.toInt =
      (if 2 * x.toUInt16.toNat < 2 ^ 16 then
        (x.toUInt16.toNat : Int)
      else
        (x.toUInt16.toNat : Int) - (2 ^ 16 : Nat)) := by
  rfl

private theorem signedToInt32_model (x : Int32) :
    x.toInt =
      (if 2 * x.toUInt32.toNat < 2 ^ 32 then
        (x.toUInt32.toNat : Int)
      else
        (x.toUInt32.toNat : Int) - (2 ^ 32 : Nat)) := by
  rfl

private theorem signedToInt64_model (x : Int64) :
    x.toInt =
      (if 2 * x.toUInt64.toNat < 2 ^ 64 then
        (x.toUInt64.toNat : Int)
      else
        (x.toUInt64.toNat : Int) - (2 ^ 64 : Nat)) := by
  rfl

-- The expected results are fixed by the pinned official Lean 4.35.0
-- SInt/Basic logical implementations, NOT inferred from generated targets.
-- Compare exactly the same input vectors as JS/TS/Rust observations.
private def signedNativeOracle : IO Unit := do
  let checks : List (String × Int × Int) := [
    ("unsignedClamp8(0)", Int.ofNat (UInt8.toNat (UInt8.ofNatClamp 0)), 0),
    ("unsignedClamp8(255)", Int.ofNat (UInt8.toNat (UInt8.ofNatClamp 255)), 255),
    ("unsignedClamp8(256)", Int.ofNat (UInt8.toNat (UInt8.ofNatClamp 256)), 255),
    ("unsignedTruncate8(256)", Int.ofNat (UInt8.toNat (UInt8.ofNatTruncate 256)), 255),
    ("unsignedClamp16(0)", Int.ofNat (UInt16.toNat (UInt16.ofNatClamp 0)), 0),
    ("unsignedClamp16(65535)", Int.ofNat (UInt16.toNat (UInt16.ofNatClamp 65535)), 65535),
    ("unsignedClamp16(65536)", Int.ofNat (UInt16.toNat (UInt16.ofNatClamp 65536)), 65535),
    ("unsignedTruncate16(65536)", Int.ofNat (UInt16.toNat (UInt16.ofNatTruncate 65536)), 65535),
    ("unsignedClamp32(0)", Int.ofNat (UInt32.toNat (UInt32.ofNatClamp 0)), 0),
    ("unsignedClamp32(4294967295)", Int.ofNat (UInt32.toNat (UInt32.ofNatClamp 4294967295)), 4294967295),
    ("unsignedClamp32(4294967296)", Int.ofNat (UInt32.toNat (UInt32.ofNatClamp 4294967296)), 4294967295),
    ("unsignedTruncate32(4294967296)", Int.ofNat (UInt32.toNat (UInt32.ofNatTruncate 4294967296)), 4294967295),
    ("unsignedClamp64(0)", Int.ofNat (UInt64.toNat (UInt64.ofNatClamp 0)), 0),
    ("unsignedClamp64(18446744073709551615)", Int.ofNat (UInt64.toNat (UInt64.ofNatClamp 18446744073709551615)), 18446744073709551615),
    ("unsignedClamp64(18446744073709551616)", Int.ofNat (UInt64.toNat (UInt64.ofNatClamp 18446744073709551616)), 18446744073709551615),
    ("unsignedTruncate64(18446744073709551616)", Int.ofNat (UInt64.toNat (UInt64.ofNatTruncate 18446744073709551616)), 18446744073709551615),
    ("unsignedFromInt8(-1)", Int.ofNat (UInt8.toNat (UInt8.ofInt (-1))), 255),
    ("unsignedFromInt8(-257)", Int.ofNat (UInt8.toNat (UInt8.ofInt (-257))), 255),
    ("unsignedFromInt8(256)", Int.ofNat (UInt8.toNat (UInt8.ofInt 256)), 0),
    ("unsignedFromInt16(-1)", Int.ofNat (UInt16.toNat (UInt16.ofInt (-1))), 65535),
    ("unsignedFromInt16(-65537)", Int.ofNat (UInt16.toNat (UInt16.ofInt (-65537))), 65535),
    ("unsignedFromInt16(65536)", Int.ofNat (UInt16.toNat (UInt16.ofInt 65536)), 0),
    ("unsignedFromInt32(-1)", Int.ofNat (UInt32.toNat (UInt32.ofInt (-1))), 4294967295),
    ("unsignedFromInt32(-4294967297)", Int.ofNat (UInt32.toNat (UInt32.ofInt (-4294967297))), 4294967295),
    ("unsignedFromInt32(4294967296)", Int.ofNat (UInt32.toNat (UInt32.ofInt 4294967296)), 0),
    ("unsignedFromInt64(-1)", Int.ofNat (UInt64.toNat (UInt64.ofInt (-1))), 18446744073709551615),
    ("unsignedFromInt64(-18446744073709551617)", Int.ofNat (UInt64.toNat (UInt64.ofInt (-18446744073709551617))), 18446744073709551615),
    ("unsignedFromInt64(18446744073709551616)", Int.ofNat (UInt64.toNat (UInt64.ofInt 18446744073709551616)), 0),
    ("unsignedPow8(255,2)", Int.ofNat (UInt8.toNat (UInt8.pow (UInt8.ofNat 255) 2)), 1),
    ("unsignedPow8(2,8)", Int.ofNat (UInt8.toNat (UInt8.pow (UInt8.ofNat 2) 8)), 0),
    ("unsignedPow8(17,0)", Int.ofNat (UInt8.toNat (UInt8.pow (UInt8.ofNat 17) 0)), 1),
    ("unsignedPow16(65535,2)", Int.ofNat (UInt16.toNat (UInt16.pow (UInt16.ofNat 65535) 2)), 1),
    ("unsignedPow16(2,16)", Int.ofNat (UInt16.toNat (UInt16.pow (UInt16.ofNat 2) 16)), 0),
    ("unsignedPow32(4294967295,2)", Int.ofNat (UInt32.toNat (UInt32.pow (UInt32.ofNat 4294967295) 2)), 1),
    ("unsignedPow32(2,32)", Int.ofNat (UInt32.toNat (UInt32.pow (UInt32.ofNat 2) 32)), 0),
    ("unsignedPow64(18446744073709551615,2)", Int.ofNat (UInt64.toNat (UInt64.pow (UInt64.ofNat 18446744073709551615) 2)), 1),
    ("unsignedPow64(2,64)", Int.ofNat (UInt64.toNat (UInt64.pow (UInt64.ofNat 2) 64)), 0),
    ("unsignedLT8(0,255)", if (UInt8.ofNat 0) < (UInt8.ofNat 255) then 1 else 0, 1),
    ("unsignedLT8(255,0)", if (UInt8.ofNat 255) < (UInt8.ofNat 0) then 1 else 0, 0),
    ("unsignedLE8(255,255)", if (UInt8.ofNat 255) ≤ (UInt8.ofNat 255) then 1 else 0, 1),
    ("unsignedLE8(255,0)", if (UInt8.ofNat 255) ≤ (UInt8.ofNat 0) then 1 else 0, 0),
    ("unsignedLT16(0,65535)", if (UInt16.ofNat 0) < (UInt16.ofNat 65535) then 1 else 0, 1),
    ("unsignedLT16(65535,0)", if (UInt16.ofNat 65535) < (UInt16.ofNat 0) then 1 else 0, 0),
    ("unsignedLE16(65535,65535)", if (UInt16.ofNat 65535) ≤ (UInt16.ofNat 65535) then 1 else 0, 1),
    ("unsignedLE16(65535,0)", if (UInt16.ofNat 65535) ≤ (UInt16.ofNat 0) then 1 else 0, 0),
    ("unsignedLT32(0,4294967295)", if (UInt32.ofNat 0) < (UInt32.ofNat 4294967295) then 1 else 0, 1),
    ("unsignedLT32(4294967295,0)", if (UInt32.ofNat 4294967295) < (UInt32.ofNat 0) then 1 else 0, 0),
    ("unsignedLE32(4294967295,4294967295)", if (UInt32.ofNat 4294967295) ≤ (UInt32.ofNat 4294967295) then 1 else 0, 1),
    ("unsignedLE32(4294967295,0)", if (UInt32.ofNat 4294967295) ≤ (UInt32.ofNat 0) then 1 else 0, 0),
    ("unsignedLT64(0,18446744073709551615)", if (UInt64.ofNat 0) < (UInt64.ofNat 18446744073709551615) then 1 else 0, 1),
    ("unsignedLT64(18446744073709551615,0)", if (UInt64.ofNat 18446744073709551615) < (UInt64.ofNat 0) then 1 else 0, 0),
    ("unsignedLE64(18446744073709551615,18446744073709551615)", if (UInt64.ofNat 18446744073709551615) ≤ (UInt64.ofNat 18446744073709551615) then 1 else 0, 1),
    ("unsignedLE64(18446744073709551615,0)", if (UInt64.ofNat 18446744073709551615) ≤ (UInt64.ofNat 0) then 1 else 0, 0),
    ("Bool.toUInt8(false)", Int.ofNat (UInt8.toNat (Bool.toUInt8 false)), 0),
    ("Bool.toUInt8(true)", Int.ofNat (UInt8.toNat (Bool.toUInt8 true)), 1),
    ("Bool.toUInt16(false)", Int.ofNat (UInt16.toNat (Bool.toUInt16 false)), 0),
    ("Bool.toUInt16(true)", Int.ofNat (UInt16.toNat (Bool.toUInt16 true)), 1),
    ("Bool.toUInt32(false)", Int.ofNat (UInt32.toNat (Bool.toUInt32 false)), 0),
    ("Bool.toUInt32(true)", Int.ofNat (UInt32.toNat (Bool.toUInt32 true)), 1),
    ("Bool.toUInt64(false)", Int.ofNat (UInt64.toNat (Bool.toUInt64 false)), 0),
    ("Bool.toUInt64(true)", Int.ofNat (UInt64.toNat (Bool.toUInt64 true)), 1),
    ("Bool.toInt8(false)", Int8.toInt (Bool.toInt8 false), 0),
    ("Bool.toInt8(true)", Int8.toInt (Bool.toInt8 true), 1),
    ("Bool.toInt16(false)", Int16.toInt (Bool.toInt16 false), 0),
    ("Bool.toInt16(true)", Int16.toInt (Bool.toInt16 true), 1),
    ("Bool.toInt32(false)", Int32.toInt (Bool.toInt32 false), 0),
    ("Bool.toInt32(true)", Int32.toInt (Bool.toInt32 true), 1),
    ("Bool.toInt64(false)", Int64.toInt (Bool.toInt64 false), 0),
    ("Bool.toInt64(true)", Int64.toInt (Bool.toInt64 true), 1),
    ("signedSize8", Int.ofNat Int8.size, 256),
    ("signedSize16", Int.ofNat Int16.size, 65536),
    ("signedSize32", Int.ofNat Int32.size, 4294967296),
    ("signedSize64", Int.ofNat Int64.size, 18446744073709551616),
    ("signedMin8", Int8.toInt Int8.minValue, -128),
    ("signedMin16", Int16.toInt Int16.minValue, -32768),
    ("signedMin32", Int32.toInt Int32.minValue, -2147483648),
    ("signedMin64", Int64.toInt Int64.minValue, -9223372036854775808),
    ("signedMax8", Int8.toInt Int8.maxValue, 127),
    ("signedMax16", Int16.toInt Int16.maxValue, 32767),
    ("signedMax32", Int32.toInt Int32.maxValue, 2147483647),
    ("signedMax64", Int64.toInt Int64.maxValue, 9223372036854775807),
    ("signedPow8(-2,3)", Int8.toInt (Int8.pow (Int8.ofInt (-2)) 3), -8),
    ("signedPow8(-128,2)", Int8.toInt (Int8.pow (Int8.ofInt (-128)) 2), 0),
    ("signedPow16(-2,3)", Int16.toInt (Int16.pow (Int16.ofInt (-2)) 3), -8),
    ("signedPow16(32767,2)", Int16.toInt (Int16.pow (Int16.ofInt 32767) 2), 1),
    ("signedPow32(-2,31)", Int32.toInt (Int32.pow (Int32.ofInt (-2)) 31), -2147483648),
    ("signedPow32(2147483647,2)", Int32.toInt (Int32.pow (Int32.ofInt 2147483647) 2), 1),
    ("signedPow64(-2,63)", Int64.toInt (Int64.pow (Int64.ofInt (-2)) 63), -9223372036854775808),
    ("signedPow64(9223372036854775807,2)", Int64.toInt (Int64.pow (Int64.ofInt 9223372036854775807) 2), 1),
    ("signedLT8(-128,127)", if (Int8.ofInt (-128)) < (Int8.ofInt 127) then 1 else 0, 1),
    ("signedLT8(127,-128)", if (Int8.ofInt 127) < (Int8.ofInt (-128)) then 1 else 0, 0),
    ("signedLE8(-128,-128)", if (Int8.ofInt (-128)) ≤ (Int8.ofInt (-128)) then 1 else 0, 1),
    ("signedLE8(127,-128)", if (Int8.ofInt 127) ≤ (Int8.ofInt (-128)) then 1 else 0, 0),
    ("signedLT16(-32768,32767)", if (Int16.ofInt (-32768)) < (Int16.ofInt 32767) then 1 else 0, 1),
    ("signedLT16(32767,-32768)", if (Int16.ofInt 32767) < (Int16.ofInt (-32768)) then 1 else 0, 0),
    ("signedLE16(-32768,-32768)", if (Int16.ofInt (-32768)) ≤ (Int16.ofInt (-32768)) then 1 else 0, 1),
    ("signedLE16(32767,-32768)", if (Int16.ofInt 32767) ≤ (Int16.ofInt (-32768)) then 1 else 0, 0),
    ("signedLT32(-2147483648,2147483647)", if (Int32.ofInt (-2147483648)) < (Int32.ofInt 2147483647) then 1 else 0, 1),
    ("signedLT32(2147483647,-2147483648)", if (Int32.ofInt 2147483647) < (Int32.ofInt (-2147483648)) then 1 else 0, 0),
    ("signedLE32(-2147483648,-2147483648)", if (Int32.ofInt (-2147483648)) ≤ (Int32.ofInt (-2147483648)) then 1 else 0, 1),
    ("signedLE32(2147483647,-2147483648)", if (Int32.ofInt 2147483647) ≤ (Int32.ofInt (-2147483648)) then 1 else 0, 0),
    ("signedLT64(-9223372036854775808,9223372036854775807)", if (Int64.ofInt (-9223372036854775808)) < (Int64.ofInt 9223372036854775807) then 1 else 0, 1),
    ("signedLT64(9223372036854775807,-9223372036854775808)", if (Int64.ofInt 9223372036854775807) < (Int64.ofInt (-9223372036854775808)) then 1 else 0, 0),
    ("signedLE64(-9223372036854775808,-9223372036854775808)", if (Int64.ofInt (-9223372036854775808)) ≤ (Int64.ofInt (-9223372036854775808)) then 1 else 0, 1),
    ("signedLE64(9223372036854775807,-9223372036854775808)", if (Int64.ofInt 9223372036854775807) ≤ (Int64.ofInt (-9223372036854775808)) then 1 else 0, 0),
    ("signedAbs8(-128)", Int8.toInt (Int8.abs (Int8.ofInt (-128))), -128),
    ("signedAbs8(-3)", Int8.toInt (Int8.abs (Int8.ofInt (-3))), 3),
    ("signedAbs8(127)", Int8.toInt (Int8.abs (Int8.ofInt 127)), 127),
    ("signedAbs16(-32768)", Int16.toInt (Int16.abs (Int16.ofInt (-32768))), -32768),
    ("signedAbs16(-3)", Int16.toInt (Int16.abs (Int16.ofInt (-3))), 3),
    ("signedAbs16(32767)", Int16.toInt (Int16.abs (Int16.ofInt 32767)), 32767),
    ("signedAbs32(-2147483648)", Int32.toInt (Int32.abs (Int32.ofInt (-2147483648))), -2147483648),
    ("signedAbs32(-3)", Int32.toInt (Int32.abs (Int32.ofInt (-3))), 3),
    ("signedAbs32(2147483647)", Int32.toInt (Int32.abs (Int32.ofInt 2147483647)), 2147483647),
    ("signedAbs64(-9223372036854775808)", Int64.toInt (Int64.abs (Int64.ofInt (-9223372036854775808))), -9223372036854775808),
    ("signedAbs64(-3)", Int64.toInt (Int64.abs (Int64.ofInt (-3))), 3),
    ("signedAbs64(9223372036854775807)", Int64.toInt (Int64.abs (Int64.ofInt 9223372036854775807)), 9223372036854775807),
    ("signedClamp8(-128)", Int.ofNat (Int8.toNatClampNeg (Int8.ofInt (-128))), 0),
    ("signedClamp8(127)", Int.ofNat (Int8.toNatClampNeg (Int8.ofInt 127)), 127),
    ("signedClamp8(-1)", Int.ofNat (Int8.toNatClampNeg (Int8.ofInt (-1))), 0),
    ("signedClamp16(-32768)", Int.ofNat (Int16.toNatClampNeg (Int16.ofInt (-32768))), 0),
    ("signedClamp16(32767)", Int.ofNat (Int16.toNatClampNeg (Int16.ofInt 32767)), 32767),
    ("signedClamp16(0)", Int.ofNat (Int16.toNatClampNeg (Int16.ofInt 0)), 0),
    ("signedClamp32(-2147483648)", Int.ofNat (Int32.toNatClampNeg (Int32.ofInt (-2147483648))), 0),
    ("signedClamp32(2147483647)", Int.ofNat (Int32.toNatClampNeg (Int32.ofInt 2147483647)), 2147483647),
    ("signedClamp32(-1)", Int.ofNat (Int32.toNatClampNeg (Int32.ofInt (-1))), 0),
    ("signedClamp64(-9223372036854775808)", Int.ofNat (Int64.toNatClampNeg (Int64.ofInt (-9223372036854775808))), 0),
    ("signedClamp64(9223372036854775807)", Int.ofNat (Int64.toNatClampNeg (Int64.ofInt 9223372036854775807)), 9223372036854775807),
    ("signedClamp64(-1)", Int.ofNat (Int64.toNatClampNeg (Int64.ofInt (-1))), 0),
    ("signed8ShiftLeft(1,-1)", Int8.toInt (Int8.shiftLeft (Int8.ofInt (1)) (Int8.ofInt (-1))), -128),
    ("signed8ShiftLeft(1,8)", Int8.toInt (Int8.shiftLeft (Int8.ofInt (1)) (Int8.ofInt (8))), 1),
    ("signed8ShiftRight(-128,1)", Int8.toInt (Int8.shiftRight (Int8.ofInt (-128)) (Int8.ofInt (1))), -64),
    ("signed8ShiftRight(-128,-1)", Int8.toInt (Int8.shiftRight (Int8.ofInt (-128)) (Int8.ofInt (-1))), -1),
    ("signed16ShiftLeft(1,-1)", Int16.toInt (Int16.shiftLeft (Int16.ofInt (1)) (Int16.ofInt (-1))), -32768),
    ("signed16ShiftLeft(1,16)", Int16.toInt (Int16.shiftLeft (Int16.ofInt (1)) (Int16.ofInt (16))), 1),
    ("signed16ShiftRight(-32768,-1)", Int16.toInt (Int16.shiftRight (Int16.ofInt (-32768)) (Int16.ofInt (-1))), -1),
    ("signed16ShiftRight(-3,1)", Int16.toInt (Int16.shiftRight (Int16.ofInt (-3)) (Int16.ofInt (1))), -2),
    ("signed32ShiftLeft(1,-1)", Int32.toInt (Int32.shiftLeft (Int32.ofInt (1)) (Int32.ofInt (-1))), -2147483648),
    ("signed32ShiftLeft(1,32)", Int32.toInt (Int32.shiftLeft (Int32.ofInt (1)) (Int32.ofInt (32))), 1),
    ("signed32ShiftRight(-2147483648,31)", Int32.toInt (Int32.shiftRight (Int32.ofInt (-2147483648)) (Int32.ofInt (31))), -1),
    ("signed32ShiftRight(-5,1)", Int32.toInt (Int32.shiftRight (Int32.ofInt (-5)) (Int32.ofInt (1))), -3),
    ("signed64ShiftLeft(1,-1)", Int64.toInt (Int64.shiftLeft (Int64.ofInt (1)) (Int64.ofInt (-1))), -9223372036854775808),
    ("signed64ShiftLeft(1,64)", Int64.toInt (Int64.shiftLeft (Int64.ofInt (1)) (Int64.ofInt (64))), 1),
    ("signed64ShiftRight(-9223372036854775808,1)", Int64.toInt (Int64.shiftRight (Int64.ofInt (-9223372036854775808)) (Int64.ofInt (1))), -4611686018427387904),
    ("signed64ShiftRight(-5,1)", Int64.toInt (Int64.shiftRight (Int64.ofInt (-5)) (Int64.ofInt (1))), -3),
    ("signedFromInt8(-129)", Int8.toInt (Int8.ofInt (-129)), 127),
    ("signedFromInt8(128)", Int8.toInt (Int8.ofInt (128)), -128),
    ("signedFromInt16(-32769)", Int16.toInt (Int16.ofInt (-32769)), 32767),
    ("signedFromInt16(32768)", Int16.toInt (Int16.ofInt (32768)), -32768),
    ("signedFromInt32(-2147483649)", Int32.toInt (Int32.ofInt (-2147483649)), 2147483647),
    ("signedFromInt32(2147483648)", Int32.toInt (Int32.ofInt (2147483648)), -2147483648),
    ("signedFromInt64(-9223372036854775809)", Int64.toInt (Int64.ofInt (-9223372036854775809)), 9223372036854775807),
    ("signedFromInt64(9223372036854775808)", Int64.toInt (Int64.ofInt (9223372036854775808)), -9223372036854775808),
    ("signed8Add(127,1)", Int8.toInt (Int8.add (Int8.ofNat 127) (Int8.ofNat 1)), -128),
    ("signed8Add(255,2)", Int8.toInt (Int8.add (Int8.ofNat 255) (Int8.ofNat 2)), 1),
    ("signed8Div(128,255)", Int8.toInt (Int8.div (Int8.ofNat 128) (Int8.ofNat 255)), -128),
    ("signed8Div(128,0)", Int8.toInt (Int8.div (Int8.ofNat 128) (Int8.ofNat 0)), 0),
    ("signed8Mod(128,255)", Int8.toInt (Int8.mod (Int8.ofNat 128) (Int8.ofNat 255)), 0),
    ("signed8Mod(128,0)", Int8.toInt (Int8.mod (Int8.ofNat 128) (Int8.ofNat 0)), -128),
    ("signed8Mod(251,2)", Int8.toInt (Int8.mod (Int8.ofNat 251) (Int8.ofNat 2)), -1),
    ("signed8Neg(128)", Int8.toInt (Int8.neg (Int8.ofNat 128)), -128),
    ("signed8Complement(0)", Int8.toInt (Int8.complement (Int8.ofNat 0)), -1),
    ("signed8Mul(127,127)", Int8.toInt (Int8.mul (Int8.ofNat 127) (Int8.ofNat 127)), 1),
    ("signed16Sub(32768,1)", Int16.toInt (Int16.sub (Int16.ofNat 32768) (Int16.ofNat 1)), 32767),
    ("signed16Mul(32767,2)", Int16.toInt (Int16.mul (Int16.ofNat 32767) (Int16.ofNat 2)), -2),
    ("signed16Add(65535,2)", Int16.toInt (Int16.add (Int16.ofNat 65535) (Int16.ofNat 2)), 1),
    ("signed32Div(2147483648,4294967295)", Int32.toInt (Int32.div (Int32.ofNat 2147483648) (Int32.ofNat 4294967295)), -2147483648),
    ("signed32Div(2147483648,0)", Int32.toInt (Int32.div (Int32.ofNat 2147483648) (Int32.ofNat 0)), 0),
    ("signed32Mod(2147483648,0)", Int32.toInt (Int32.mod (Int32.ofNat 2147483648) (Int32.ofNat 0)), -2147483648),
    ("signed32Xor(2147483648,4294967295)", Int32.toInt (Int32.xor (Int32.ofNat 2147483648) (Int32.ofNat 4294967295)), 2147483647),
    ("signed64Add(9223372036854775807,1)", Int64.toInt (Int64.add (Int64.ofNat 9223372036854775807) (Int64.ofNat 1)), -9223372036854775808),
    ("signed64Div(9223372036854775808,18446744073709551615)", Int64.toInt (Int64.div (Int64.ofNat 9223372036854775808) (Int64.ofNat 18446744073709551615)), -9223372036854775808),
    ("signed64Mod(9223372036854775808,0)", Int64.toInt (Int64.mod (Int64.ofNat 9223372036854775808) (Int64.ofNat 0)), -9223372036854775808),
    ("signed64Complement(0)", Int64.toInt (Int64.complement (Int64.ofNat 0)), -1),
    ("signed64Mul(9223372036854775807,2)", Int64.toInt (Int64.mul (Int64.ofNat 9223372036854775807) (Int64.ofNat 2)), -2)]
  for (name, observed, expected) in checks do
    unless observed == expected do
      throw (IO.userError ("PSCV0-SIGNED-ORACLE: " ++ name ++
        ": expected " ++ toString expected ++ ", actual " ++ toString observed))
  -- Negative IR cases must refuse unqualified widths, family confusion and
  -- noncanonical signed literals before any backend is invoked.
  match psIrCheckIntrinsicSignature (.signedOfNat .int8) [] with
  | .ok _ => pure ()
  | .error _ => throw (IO.userError "PSCV0-SIGNED-IR: qualified Int8 refused")
  match psIrCheckIntrinsicSignature (.signedOfNat .uint8) [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "PSCV0-SIGNED-IR: unsigned signedOfNat accepted")
  match psIrCheckIntrinsicSignature (.signedToUnsigned .int8) [] with
  | .ok _ => pure ()
  | .error _ => throw (IO.userError "PSCV0-SIGNED-IR: signed carrier reinterpretation refused")
  match psIrCheckIntrinsicSignature (.signedToUnsigned .uint8) [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "PSCV0-SIGNED-IR: unsigned carrier reinterpretation accepted")
  match psIrCheckIntrinsicSignature (.machineIntBinary .isize .add) [] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "PSCV0-SIGNED-IR: target-sized word accepted without profile")
  match psIrCheckLiteralType (.machineInteger .int8 (-129)) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "PSCV0-SIGNED-IR: out-of-range negative literal accepted")
  match psIrCheckLiteralType (.machineInteger .int8 128) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "PSCV0-SIGNED-IR: out-of-range positive literal accepted")
  IO.println ("PSCV0_SIGNED_NATIVE_ORACLE: PASS " ++ toString checks.length ++
    " pinned SInt values and seven strict typed IR checks")

-- Independent official Lean 4.35.0 sum eliminator observations.
private def standardSumNativeOracle : IO Unit := do
  let score : Sum Nat Nat → Nat := fun value =>
    match value with
    | Sum.inl left => left
    | Sum.inr right => right + 100
  unless score (Sum.inl 17) == 17 do
    throw (IO.userError "PSCV0_SUM_ORACLE: left constructor mismatch")
  unless score (Sum.inr 23) == 123 do
    throw (IO.userError "PSCV0_SUM_ORACLE: right constructor mismatch")
  IO.println "PSCV0_SUM_ORACLE: PASS 2 pinned Sum constructor/eliminator cases"

private def byteArrayCollectionNativeOracle : IO Unit := do
  let a := ByteArray.push ByteArray.empty (3 : UInt8)
  let b := a.set! 0 (255 : UInt8)
  unless ByteArray.get! b 0 == (255 : UInt8) do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: bounded update mismatch")
  unless ByteArray.get! (a.set! 19 (0 : UInt8)) 0 == (3 : UInt8) do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: out-of-bounds replacement altered array")
  unless (ByteArray.empty).isEmpty do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: empty predicate mismatch")
  if a.isEmpty then
    throw (IO.userError "PSCV0_BYTE_COLLECTION: nonempty predicate mismatch")
  unless ByteArray.beq a (ByteArray.push ByteArray.empty (3 : UInt8)) do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: Boolean equality mismatch")
  if ByteArray.beq a (ByteArray.push ByteArray.empty (4 : UInt8)) then
    throw (IO.userError "PSCV0_BYTE_COLLECTION: distinct bytes compared equal")
  unless (default : ByteArray).size == 0 do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: default constructor mismatch")
  unless (ByteArray.push ByteArray.empty (3 : UInt8))[0]? ==
      some (3 : UInt8) do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: optional valid lookup")
  unless (ByteArray.empty)[0]? == (none : Option UInt8) do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: optional empty lookup")
  unless ByteArray.get (ByteArray.push ByteArray.empty (3 : UInt8))
      0 (by decide) == (3 : UInt8) do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: proof-carrying getter")
  let replaced := ByteArray.set (ByteArray.push ByteArray.empty (3 : UInt8))
    0 (7 : UInt8) (by decide)
  unless replaced[0]? == some (7 : UInt8) do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: proof-carrying setter")
  unless (ByteArray.push ByteArray.empty (3 : UInt8)).toList ==
      [(3 : UInt8)] do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: native ordered toList")
  let source : List UInt8 := [9, 5, 3]
  let fromList := source.toByteArray
  unless fromList.toList == source do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: List.toByteArray order")
  unless (fromList.extract 1 3).toList == [5, 3] do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: half-open extract")
  unless (fromList.extract 1 99).toList == [5, 3] do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: clipped extract")
  unless (fromList.extract 2 1).toList == [] do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: reversed extract")
  let appended := source.toByteArray.append ([255] : List UInt8).toByteArray
  unless appended.toList == [9, 5, 3, 255] do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: ordered append")
  unless (source.toByteArray.append ByteArray.empty).toList == source do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: append empty")
  let copiedDefault := source.toByteArray.copySlice 0
    ([17, 18, 19] : List UInt8).toByteArray 1 2
  unless copiedDefault.toList == [17, 9, 5] do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: copySlice default and overwrite")
  let copiedFalse := source.toByteArray.copySlice 0
    ([17, 18, 19] : List UInt8).toByteArray 1 2 false
  unless copiedFalse.toList == [17, 9, 5] do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: copySlice false capacity hint")
  let copiedOutside := source.toByteArray.copySlice 99
    ([17, 18, 19] : List UInt8).toByteArray 1 2
  unless copiedOutside.toList == [17, 18, 19] do
    throw (IO.userError "PSCV0_BYTE_COLLECTION: copySlice outside source")
  IO.println "PSCV0_BYTE_COLLECTION_ORACLE: PASS twenty-one independent native ByteArray cases"

private def byteArrayNativeOracle : IO Unit := do
  let empty := ByteArray.empty
  let bytes := (ByteArray.push (ByteArray.push empty (1 : UInt8)) (255 : UInt8))
  unless empty.size == 0 do
    throw (IO.userError "PSCV0_BYTE_ARRAY_ORACLE: empty size mismatch")
  unless bytes.size == 2 do
    throw (IO.userError "PSCV0_BYTE_ARRAY_ORACLE: push size mismatch")
  unless bytes.data.getD 1 (0 : UInt8) == 255 do
    throw (IO.userError "PSCV0_BYTE_ARRAY_ORACLE: stored byte mismatch")
  IO.println "PSCV0_BYTE_ARRAY_ORACLE: PASS empty/push/size/data"

private def selectedStandardManifestCases : IO Unit := do
  let environment := psSelfHostProdPreludeEnvironment
  match PsV7Native.standardSurfaceManifestAudit environment with
  | .error message => throw (IO.userError message)
  | .ok () => pure ()
  let manifest := PsV7Native.standardSurfaceManifestJson environment
  let repr := manifest.compress
  unless (repr.splitOn "selectedStandardSHA256").length > 1 &&
      (repr.splitOn "selectedSurfaceSHA256").length > 1 &&
      (repr.splitOn "instanceRegistrations").length > 1 &&
      (repr.splitOn "selectedNotation").length > 1 &&
      (repr.splitOn "registeredAxioms").length > 1 do
    throw (IO.userError "PSCV0-MANIFEST: missing selected boundary")
  IO.println s!"PSCV0_STANDARD_MANIFEST: PASS selected notation, deriving, tactics, effects, module boundaries and {environment.declarations.length} strict declarations"

-- Dirty caller heartbeats must not consume an independent admission's budget.
-- The same scope still refuses an ill-typed declaration and restores its caller.
private def kernelHeartbeatIsolationCases : IO Unit := do
  let empty := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  let witness : Lean.Declaration := .defnDecl {
    name := `_pscv0HeartbeatScopeWitness
    levelParams := []
    type := .sort (.succ (.succ .zero))
    value := .sort (.succ .zero)
    hints := .opaque
    safety := .safe }
  let original ← IO.getNumHeartbeats
  try
    IO.setNumHeartbeats 2000001
    -- Exercise the actual C++ counter, not just allocation accounting.
    -- Each distinct tiny definition forces kernel work on this caller thread.
    for i in [:128] do
      let seed : Lean.Declaration := .defnDecl {
        name := .num `_pscv0HeartbeatSeed i
        levelParams := []
        type := .sort (.succ (.succ .zero))
        value := .sort (.succ .zero)
        hints := .opaque
        safety := .safe }
      let seeded ← IO.lazyPure fun _ => empty.addDeclCore 0 20000 seed none
      unless seeded.isOk do
        throw (IO.userError "kernel heartbeat seed was ill-typed")
    let stale ← IO.lazyPure fun _ => empty.addDeclCore 64 20000 witness none
    match stale with
    | .error .deterministicTimeout => pure ()
    | _ => throw (IO.userError "kernel counter isolation probe did not exhaust its caller")
    let admitted ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
      empty.addDeclCore 64 20000 witness none
    unless admitted.isOk do
      throw (IO.userError "independent kernel admission inherited caller heartbeats")
    let restored ← IO.getNumHeartbeats
    unless restored ≥ 2000001 do
      throw (IO.userError "kernel admission lost caller heartbeat baseline")
    let invalid : Lean.Declaration := .defnDecl {
      name := `_pscv0HeartbeatScopeInvalid
      levelParams := []
      type := .sort .zero
      value := .sort .zero
      hints := .opaque
      safety := .safe }
    let refused ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
      empty.addDeclCore 2000000 20000 invalid none
    if refused.isOk then
      throw (IO.userError "fresh heartbeat scope accepted an ill-typed declaration")
    let restoredFailure ← IO.getNumHeartbeats
    unless restoredFailure ≥ restored do
      throw (IO.userError "failed kernel admission lost caller heartbeat baseline")
  finally
    IO.setNumHeartbeats original
  IO.println "PSCV0_KERNEL_SCOPE: PASS actual kernel-counter isolation, allocation baseline preservation and type refusal"

-- One compact source boundary check; the shared backend observations execute
-- the IEEE corpus, model elimination and generic/closure paths below.
private def floatConstructorBoundaries : IO Unit := do
  let cases64 : List (UInt64 × UInt64) := [
    (0, 0),
    (9223372036854775808, 9223372036854775808),
    (1, 1),
    (4503599627370495, 4503599627370495),
    (4503599627370496, 4503599627370496),
    (4607182418800017408, 4607182418800017408),
    (9218868437227405311, 9218868437227405311),
    (18442240474082181119, 18442240474082181119),
    (9218868437227405312, 9218868437227405312),
    (18442240474082181120, 18442240474082181120),
    (9218868437227405313, 9221120237041090560),
    (18442240474082181121, 9221120237041090560),
    (9221120237041090560, 9221120237041090560),
    (18446744073709551615, 9221120237041090560)]
  for (bits, expected) in cases64 do
    unless (Float.ofBits bits).toBits == expected do
      throw (IO.userError "pinned native Float64 oracle differs from IEEE corpus")
  let cases32 : List (UInt32 × UInt32) := [
    (0, 0),
    (2147483648, 2147483648),
    (1, 1),
    (8388607, 8388607),
    (8388608, 8388608),
    (1065353216, 1065353216),
    (2139095039, 2139095039),
    (4286578687, 4286578687),
    (2139095040, 2139095040),
    (4286578688, 4286578688),
    (2139095041, 2143289344),
    (4286578689, 2143289344),
    (2143289344, 2143289344),
    (4294967295, 2143289344)]
  for (bits, expected) in cases32 do
    unless (Float32.ofBits bits).toBits == expected do
      throw (IO.userError "pinned native Float32 oracle differs from IEEE corpus")
  let requests : Array PsV7Native.Request := #[
    { source := executableFloatFixture, targets := [.javascript, .typescript, .rust] },
    { source := "function bad(bits: UInt32): Float := Float.ofBits(bits)\n", targets := [] }]
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok value => pure value
    | .error error => throw (IO.userError ("Float constructor prelude: " ++ error.message))
  match batch.results.toList with
  | [.ok accepted, .error badType] =>
    unless accepted.artifacts.length == 3 do
      throw (IO.userError "executable Float fixture did not emit all three source targets")
    unless badType.phase == "elaborate" do
      throw (IO.userError ("Float constructor argument escaped elaboration: " ++ badType.message))
  | results => throw (IO.userError ("executable Float boundary mismatch: " ++
      String.intercalate "; " (results.map fun r => match r with
        | .ok _ => "accepted" | .error e => e.phase ++ ": " ++ e.message)))
  for (operation, input, output) in [
      (PsVerifiedIrIntrinsic.floatOfBits .float, PsVerifiedIrType.primitive .uint32, PsVerifiedIrType.primitive .float),
      (.floatToBits .float, .primitive .float32, .primitive .uint64)] do
    let invalid : PsVerifiedIrModule := { psVerifiedIrModuleEmpty with declarations := [
      { name := "wrongWidth", typeParameters := [], parameters := [{ name := "value", type := input }],
        resultType := output, body := .intrinsic operation [] [.var "value"] }] }
    match psWithCheckedIr psIrCheckDefaultOptions invalid (fun _ => .ok ()) with
    | .error message => unless message.startsWith "PSCV0-IR-CHECK:" do
        throw (IO.userError message)
    | .ok _ => throw (IO.userError "wrong-width floating intrinsic reached emission")
  let mixed : PsVerifiedIrModule := { psVerifiedIrModuleEmpty with declarations := [
    { name := "mixedFloatWidths", typeParameters := [],
      parameters := [{ name := "left", type := .primitive .float32 },
        { name := "right", type := .primitive .float }],
      resultType := .primitive .float32,
      body := .intrinsic (.floatBinary .float32 .add) [] [.var "left", .var "right"] }] }
  match psWithCheckedIr psIrCheckDefaultOptions mixed (fun _ => .ok ()) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "mixed-width floating arithmetic reached emission")
  IO.println "PSCV0_FLOAT_F1: PASS source bit/model/generic/closure paths and width refusal"

-- IEEE boundaries are checked against pinned native Lean independently of
-- PSC0 erasure and target lowering. The same cases execute in shared targets.
private def floatOperationsNativeOracle : IO Unit := do
  let checks : List (String × Nat × Nat) := [
    ("f2Add64", (Float.add (Float.ofBits 4607182418800017408) (Float.ofBits 4611686018427387904)).toBits.toNat, 4613937818241073152),
    ("f2Add64", (Float.add (Float.ofBits 9218868437227405311) (Float.ofBits 9218868437227405311)).toBits.toNat, 9218868437227405312),
    ("f2Add64", (Float.add (Float.ofBits 1) (Float.ofBits 1)).toBits.toNat, 2),
    ("f2Add64", (Float.add (Float.ofBits 4607182418800017408) (Float.ofBits 4368491638549381120)).toBits.toNat, 4607182418800017408),
    ("f2Add64", (Float.add (Float.ofBits 4607182418800017409) (Float.ofBits 4368491638549381120)).toBits.toNat, 4607182418800017410),
    ("f2Sub64", (Float.sub (Float.ofBits 4607182418800017408) (Float.ofBits 4607182418800017408)).toBits.toNat, 0),
    ("f2Sub64", (Float.sub (Float.ofBits 9223372036854775808) (Float.ofBits 0)).toBits.toNat, 9223372036854775808),
    ("f2Mul64", (Float.mul (Float.ofBits 0) (Float.ofBits 9218868437227405312)).toBits.toNat, 9221120237041090560),
    ("f2Mul64", (Float.mul (Float.ofBits 1) (Float.ofBits 4602678819172646912)).toBits.toNat, 0),
    ("f2Mul64", (Float.mul (Float.ofBits 3) (Float.ofBits 4602678819172646912)).toBits.toNat, 2),
    ("f2Div64", (Float.div (Float.ofBits 4607182418800017408) (Float.ofBits 0)).toBits.toNat, 9218868437227405312),
    ("f2Div64", (Float.div (Float.ofBits 13830554455654793216) (Float.ofBits 0)).toBits.toNat, 18442240474082181120),
    ("f2Div64", (Float.div (Float.ofBits 0) (Float.ofBits 0)).toBits.toNat, 9221120237041090560),
    ("f2Div64", (Float.div (Float.ofBits 4607182418800017408) (Float.ofBits 4613937818241073152)).toBits.toNat, 4599676419421066581),
    ("f2Div64", (Float.div (Float.ofBits 4503599627370496) (Float.ofBits 4611686018427387904)).toBits.toNat, 2251799813685248),
    ("f2Neg64", (Float.neg (Float.ofBits 0)).toBits.toNat, 9223372036854775808),
    ("f2Neg64", (Float.neg (Float.ofBits 9223372036854775808)).toBits.toNat, 0),
    ("f2Neg64", (Float.neg (Float.ofBits 18442240474082181121)).toBits.toNat, 9221120237041090560),
    ("f2Abs64", (Float.abs (Float.ofBits 18442240474082181120)).toBits.toNat, 9218868437227405312),
    ("f2Abs64", (Float.abs (Float.ofBits 13830554455654793216)).toBits.toNat, 4607182418800017408),
    ("f2BEq64", (if Float.beq (Float.ofBits 0) (Float.ofBits 9223372036854775808) then 1 else 0), 1),
    ("f2BEq64", (if Float.beq (Float.ofBits 9221120237041090560) (Float.ofBits 9221120237041090560) then 1 else 0), 0),
    ("f2BEq64", (if Float.beq (Float.ofBits 9218868437227405312) (Float.ofBits 9218868437227405312) then 1 else 0), 1),
    ("f2Eq64", (if (Float.ofBits 0) = (Float.ofBits 9223372036854775808) then 1 else 0), 0),
    ("f2Eq64", (if (Float.ofBits 9221120237041090560) = (Float.ofBits 18442240474082181121) then 1 else 0), 1),
    ("f2Eq64", (if (Float.ofBits 9218868437227405312) = (Float.ofBits 9218868437227405312) then 1 else 0), 1),
    ("f2LT64", (if Float.lt (Float.ofBits 18442240474082181120) (Float.ofBits 0) then 1 else 0), 1),
    ("f2LT64", (if Float.lt (Float.ofBits 9221120237041090560) (Float.ofBits 0) then 1 else 0), 0),
    ("f2LE64", (if Float.le (Float.ofBits 0) (Float.ofBits 9223372036854775808) then 1 else 0), 1),
    ("f2LE64", (if Float.le (Float.ofBits 9221120237041090560) (Float.ofBits 9221120237041090560) then 1 else 0), 0),
    ("f2NaN64", (if Float.isNaN (Float.ofBits 18442240474082181121) then 1 else 0), 1),
    ("f2NaN64", (if Float.isNaN (Float.ofBits 9218868437227405312) then 1 else 0), 0),
    ("f2Inf64", (if Float.isInf (Float.ofBits 18442240474082181120) then 1 else 0), 1),
    ("f2Inf64", (if Float.isInf (Float.ofBits 9221120237041090560) then 1 else 0), 0),
    ("f2Finite64", (if Float.isFinite (Float.ofBits 4503599627370496) then 1 else 0), 1),
    ("f2Finite64", (if Float.isFinite (Float.ofBits 1) then 1 else 0), 1),
    ("f2Finite64", (if Float.isFinite (Float.ofBits 9223372036854775808) then 1 else 0), 1),
    ("f2Finite64", (if Float.isFinite (Float.ofBits 9221120237041090560) then 1 else 0), 0),
    ("f2Partial64", (Float.add (Float.ofBits 4607182418800017408) (Float.ofBits 4611686018427387904)).toBits.toNat, 4613937818241073152),
    ("f2Generic64", (Float.add (Float.ofBits 4607182418800017408) (Float.ofBits 4611686018427387904)).toBits.toNat, 4613937818241073152),
    ("f2Model64", (Float.add (Float.ofBits 4607182418800017408) (Float.ofBits 4611686018427387904)).toBits.toNat, 4613937818241073152),
    ("f2Default64", (default : Float).toBits.toNat, 0),
    ("f2Nan64", Float.nan.toBits.toNat, 9221120237041090560),
    ("f2Infinity64", Float.inf.toBits.toNat, 9218868437227405312),
    ("f2Add32", (Float32.add (Float32.ofBits 1065353216) (Float32.ofBits 1073741824)).toBits.toNat, 1077936128),
    ("f2Add32", (Float32.add (Float32.ofBits 2139095039) (Float32.ofBits 2139095039)).toBits.toNat, 2139095040),
    ("f2Add32", (Float32.add (Float32.ofBits 1) (Float32.ofBits 1)).toBits.toNat, 2),
    ("f2Add32", (Float32.add (Float32.ofBits 1065353216) (Float32.ofBits 864026624)).toBits.toNat, 1065353216),
    ("f2Add32", (Float32.add (Float32.ofBits 1065353217) (Float32.ofBits 864026624)).toBits.toNat, 1065353218),
    ("f2Sub32", (Float32.sub (Float32.ofBits 1065353216) (Float32.ofBits 1065353216)).toBits.toNat, 0),
    ("f2Sub32", (Float32.sub (Float32.ofBits 2147483648) (Float32.ofBits 0)).toBits.toNat, 2147483648),
    ("f2Mul32", (Float32.mul (Float32.ofBits 0) (Float32.ofBits 2139095040)).toBits.toNat, 2143289344),
    ("f2Mul32", (Float32.mul (Float32.ofBits 1) (Float32.ofBits 1056964608)).toBits.toNat, 0),
    ("f2Mul32", (Float32.mul (Float32.ofBits 3) (Float32.ofBits 1056964608)).toBits.toNat, 2),
    ("f2Div32", (Float32.div (Float32.ofBits 1065353216) (Float32.ofBits 0)).toBits.toNat, 2139095040),
    ("f2Div32", (Float32.div (Float32.ofBits 3212836864) (Float32.ofBits 0)).toBits.toNat, 4286578688),
    ("f2Div32", (Float32.div (Float32.ofBits 0) (Float32.ofBits 0)).toBits.toNat, 2143289344),
    ("f2Div32", (Float32.div (Float32.ofBits 1065353216) (Float32.ofBits 1077936128)).toBits.toNat, 1051372203),
    ("f2Div32", (Float32.div (Float32.ofBits 8388608) (Float32.ofBits 1073741824)).toBits.toNat, 4194304),
    ("f2Neg32", (Float32.neg (Float32.ofBits 0)).toBits.toNat, 2147483648),
    ("f2Neg32", (Float32.neg (Float32.ofBits 2147483648)).toBits.toNat, 0),
    ("f2Neg32", (Float32.neg (Float32.ofBits 4286578689)).toBits.toNat, 2143289344),
    ("f2Abs32", (Float32.abs (Float32.ofBits 4286578688)).toBits.toNat, 2139095040),
    ("f2Abs32", (Float32.abs (Float32.ofBits 3212836864)).toBits.toNat, 1065353216),
    ("f2BEq32", (if Float32.beq (Float32.ofBits 0) (Float32.ofBits 2147483648) then 1 else 0), 1),
    ("f2BEq32", (if Float32.beq (Float32.ofBits 2143289344) (Float32.ofBits 2143289344) then 1 else 0), 0),
    ("f2BEq32", (if Float32.beq (Float32.ofBits 2139095040) (Float32.ofBits 2139095040) then 1 else 0), 1),
    ("f2Eq32", (if (Float32.ofBits 0) = (Float32.ofBits 2147483648) then 1 else 0), 0),
    ("f2Eq32", (if (Float32.ofBits 2143289344) = (Float32.ofBits 4286578689) then 1 else 0), 1),
    ("f2Eq32", (if (Float32.ofBits 2139095040) = (Float32.ofBits 2139095040) then 1 else 0), 1),
    ("f2LT32", (if Float32.lt (Float32.ofBits 4286578688) (Float32.ofBits 0) then 1 else 0), 1),
    ("f2LT32", (if Float32.lt (Float32.ofBits 2143289344) (Float32.ofBits 0) then 1 else 0), 0),
    ("f2LE32", (if Float32.le (Float32.ofBits 0) (Float32.ofBits 2147483648) then 1 else 0), 1),
    ("f2LE32", (if Float32.le (Float32.ofBits 2143289344) (Float32.ofBits 2143289344) then 1 else 0), 0),
    ("f2NaN32", (if Float32.isNaN (Float32.ofBits 4286578689) then 1 else 0), 1),
    ("f2NaN32", (if Float32.isNaN (Float32.ofBits 2139095040) then 1 else 0), 0),
    ("f2Inf32", (if Float32.isInf (Float32.ofBits 4286578688) then 1 else 0), 1),
    ("f2Inf32", (if Float32.isInf (Float32.ofBits 2143289344) then 1 else 0), 0),
    ("f2Finite32", (if Float32.isFinite (Float32.ofBits 8388608) then 1 else 0), 1),
    ("f2Finite32", (if Float32.isFinite (Float32.ofBits 1) then 1 else 0), 1),
    ("f2Finite32", (if Float32.isFinite (Float32.ofBits 2147483648) then 1 else 0), 1),
    ("f2Finite32", (if Float32.isFinite (Float32.ofBits 2143289344) then 1 else 0), 0),
    ("f2Partial32", (Float32.add (Float32.ofBits 1065353216) (Float32.ofBits 1073741824)).toBits.toNat, 1077936128),
    ("f2Generic32", (Float32.add (Float32.ofBits 1065353216) (Float32.ofBits 1073741824)).toBits.toNat, 1077936128),
    ("f2Model32", (Float32.add (Float32.ofBits 1065353216) (Float32.ofBits 1073741824)).toBits.toNat, 1077936128),
    ("f2Default32", (default : Float32).toBits.toNat, 0),
    ("f2Nan32", Float32.nan.toBits.toNat, 2143289344),
    ("f2Infinity32", Float32.inf.toBits.toNat, 2139095040)]
  for (name, observed, expected) in checks do
    unless observed == expected do
      throw (IO.userError ("PSCV0_FLOAT_F2_ORACLE: " ++ name ++ " expected " ++ toString expected ++ " got " ++ toString observed))
  IO.println "PSCV0_FLOAT_F2_ORACLE: PASS 88 pinned native arithmetic, rounding, IEEE and logical equality observations"

#guard (Float.toUInt8 Float.nan == (UInt8.ofNat (0))) && (Float.toUInt8 Float.inf == (UInt8.ofNat (255))) && (Float.toUInt8 (-Float.inf) == (UInt8.ofNat (0))) && (Float.toUInt8 (-7.9) == (UInt8.ofNat (0))) && (UInt8.toFloat (UInt8.ofNat (247)) == 247.0)
#guard (Float.toUInt16 Float.nan == (UInt16.ofNat (0))) && (Float.toUInt16 Float.inf == (UInt16.ofNat (65535))) && (Float.toUInt16 (-Float.inf) == (UInt16.ofNat (0))) && (Float.toUInt16 (-7.9) == (UInt16.ofNat (0))) && (UInt16.toFloat (UInt16.ofNat (247)) == 247.0)
#guard (Float.toUInt32 Float.nan == (UInt32.ofNat (0))) && (Float.toUInt32 Float.inf == (UInt32.ofNat (4294967295))) && (Float.toUInt32 (-Float.inf) == (UInt32.ofNat (0))) && (Float.toUInt32 (-7.9) == (UInt32.ofNat (0))) && (UInt32.toFloat (UInt32.ofNat (247)) == 247.0)
#guard (Float.toUInt64 Float.nan == (UInt64.ofNat (0))) && (Float.toUInt64 Float.inf == (UInt64.ofNat (18446744073709551615))) && (Float.toUInt64 (-Float.inf) == (UInt64.ofNat (0))) && (Float.toUInt64 (-7.9) == (UInt64.ofNat (0))) && (UInt64.toFloat (UInt64.ofNat (247)) == 247.0)
#guard (Float.toInt8 Float.nan == (Int8.ofInt (0))) && (Float.toInt8 Float.inf == (Int8.ofInt (127))) && (Float.toInt8 (-Float.inf) == (Int8.ofInt (-128))) && (Float.toInt8 (-7.9) == (Int8.ofInt (-7))) && (Int8.toFloat (Int8.ofInt (-7)) == (-7.0))
#guard (Float.toInt16 Float.nan == (Int16.ofInt (0))) && (Float.toInt16 Float.inf == (Int16.ofInt (32767))) && (Float.toInt16 (-Float.inf) == (Int16.ofInt (-32768))) && (Float.toInt16 (-7.9) == (Int16.ofInt (-7))) && (Int16.toFloat (Int16.ofInt (-7)) == (-7.0))
#guard (Float.toInt32 Float.nan == (Int32.ofInt (0))) && (Float.toInt32 Float.inf == (Int32.ofInt (2147483647))) && (Float.toInt32 (-Float.inf) == (Int32.ofInt (-2147483648))) && (Float.toInt32 (-7.9) == (Int32.ofInt (-7))) && (Int32.toFloat (Int32.ofInt (-7)) == (-7.0))
#guard (Float.toInt64 Float.nan == (Int64.ofInt (0))) && (Float.toInt64 Float.inf == (Int64.ofInt (9223372036854775807))) && (Float.toInt64 (-Float.inf) == (Int64.ofInt (-9223372036854775808))) && (Float.toInt64 (-7.9) == (Int64.ofInt (-7))) && (Int64.toFloat (Int64.ofInt (-7)) == (-7.0))
#guard (Float32.toUInt8 Float32.nan == (UInt8.ofNat (0))) && (Float32.toUInt8 Float32.inf == (UInt8.ofNat (255))) && (Float32.toUInt8 (-Float32.inf) == (UInt8.ofNat (0))) && (Float32.toUInt8 (-7.9) == (UInt8.ofNat (0))) && (UInt8.toFloat32 (UInt8.ofNat (247)) == 247.0)
#guard (Float32.toUInt16 Float32.nan == (UInt16.ofNat (0))) && (Float32.toUInt16 Float32.inf == (UInt16.ofNat (65535))) && (Float32.toUInt16 (-Float32.inf) == (UInt16.ofNat (0))) && (Float32.toUInt16 (-7.9) == (UInt16.ofNat (0))) && (UInt16.toFloat32 (UInt16.ofNat (247)) == 247.0)
#guard (Float32.toUInt32 Float32.nan == (UInt32.ofNat (0))) && (Float32.toUInt32 Float32.inf == (UInt32.ofNat (4294967295))) && (Float32.toUInt32 (-Float32.inf) == (UInt32.ofNat (0))) && (Float32.toUInt32 (-7.9) == (UInt32.ofNat (0))) && (UInt32.toFloat32 (UInt32.ofNat (247)) == 247.0)
#guard (Float32.toUInt64 Float32.nan == (UInt64.ofNat (0))) && (Float32.toUInt64 Float32.inf == (UInt64.ofNat (18446744073709551615))) && (Float32.toUInt64 (-Float32.inf) == (UInt64.ofNat (0))) && (Float32.toUInt64 (-7.9) == (UInt64.ofNat (0))) && (UInt64.toFloat32 (UInt64.ofNat (247)) == 247.0)
#guard (Float32.toInt8 Float32.nan == (Int8.ofInt (0))) && (Float32.toInt8 Float32.inf == (Int8.ofInt (127))) && (Float32.toInt8 (-Float32.inf) == (Int8.ofInt (-128))) && (Float32.toInt8 (-7.9) == (Int8.ofInt (-7))) && (Int8.toFloat32 (Int8.ofInt (-7)) == (-7.0))
#guard (Float32.toInt16 Float32.nan == (Int16.ofInt (0))) && (Float32.toInt16 Float32.inf == (Int16.ofInt (32767))) && (Float32.toInt16 (-Float32.inf) == (Int16.ofInt (-32768))) && (Float32.toInt16 (-7.9) == (Int16.ofInt (-7))) && (Int16.toFloat32 (Int16.ofInt (-7)) == (-7.0))
#guard (Float32.toInt32 Float32.nan == (Int32.ofInt (0))) && (Float32.toInt32 Float32.inf == (Int32.ofInt (2147483647))) && (Float32.toInt32 (-Float32.inf) == (Int32.ofInt (-2147483648))) && (Float32.toInt32 (-7.9) == (Int32.ofInt (-7))) && (Int32.toFloat32 (Int32.ofInt (-7)) == (-7.0))
#guard (Float32.toInt64 Float32.nan == (Int64.ofInt (0))) && (Float32.toInt64 Float32.inf == (Int64.ofInt (9223372036854775807))) && (Float32.toInt64 (-Float32.inf) == (Int64.ofInt (-9223372036854775808))) && (Float32.toInt64 (-7.9) == (Int64.ofInt (-7))) && (Int64.toFloat32 (Int64.ofInt (-7)) == (-7.0))

private def floatConversionsNativeOracle : IO Unit := do
  let checks : List (String × Nat × Nat) := [
    ("f3Scientific64", (Float.ofScientific 1 true 1).toBits.toNat, 4591870180066957722),
    ("f3Scientific64", (Float.ofScientific 0 false 999999).toBits.toNat, 0),
    ("f3Scientific64", (Float.ofScientific 1 false 999999).toBits.toNat, 9218868437227405312),
    ("f3Scientific64", (Float.ofScientific 1 true 999999).toBits.toNat, 0),
    ("f3Scientific64", (Float.ofScientific 5 true 324).toBits.toNat, 1),
    ("f3Scientific64", (Float.ofScientific 22250738585072014 true 324).toBits.toNat, 4503599627370496),
    ("f3Scientific64", (Float.ofScientific 17976931348623157 false 292).toBits.toNat, 9218868437227405311),
    ("f3Scientific64", (Float.ofScientific 100000000000000011102230246251565404236316680908203125 true 53).toBits.toNat, 4607182418800017408),
    ("f3Scientific64", (Float.ofScientific 100000000000000011102230246251565404236316680908203126 true 53).toBits.toNat, 4607182418800017409),
    ("f3Scientific64", (Float.ofScientific 9689081178615771 true 325).toBits.toNat, 196109186302929),
    ("f3ModelScientific64", (Float.ofModel (Float.Model.ofScientific 9689081178615771 (-325))).toBits.toNat, 196109186302929),
    ("f3Scientific32", (Float32.ofScientific 1 true 1).toBits.toNat, 1036831949),
    ("f3Scientific32", (Float32.ofScientific 0 false 999999).toBits.toNat, 0),
    ("f3Scientific32", (Float32.ofScientific 1 false 999999).toBits.toNat, 2139095040),
    ("f3Scientific32", (Float32.ofScientific 1 true 999999).toBits.toNat, 0),
    ("f3Scientific32", (Float32.ofScientific 7 true 46).toBits.toNat, 0),
    ("f3Scientific32", (Float32.ofScientific 8 true 46).toBits.toNat, 1),
    ("f3Scientific32", (Float32.ofScientific 11754943508222875 true 54).toBits.toNat, 8388608),
    ("f3Scientific32", (Float32.ofScientific 34028234663852886 false 22).toBits.toNat, 2139095039),
    ("f3Scientific32", (Float32.ofScientific 1000000059604644775390625 true 24).toBits.toNat, 1065353216),
    ("f3Scientific32", (Float32.ofScientific 1000000059604644775390625000001 true 30).toBits.toNat, 1065353217),
    ("f3ModelScientific32", (Float32.ofModel (Float32.Model.ofScientific 1000000059604644775390625000001 (-30))).toBits.toNat, 1065353217),
    ("f3Natural64", (Float.ofNat 9007199254740993).toBits.toNat, 4845873199050653696),
    ("f3Natural64", (Float.ofNat 9007199254740995).toBits.toNat, 4845873199050653698),
    ("f3Natural64", (Float.ofNat 179769313486231590772930519078902473361797697894230657273430081157732675805500963132708477322407536021120113879871393357658789768814416622492847430639474124377767893424865485276302219601246094119453082952085005768838150682342462881473913110540827237163350510684586298239947245938479716304835356329624224137216).toBits.toNat, 9218868437227405312),
    ("f3Natural32", (Float32.ofNat 18014399583223809).toBits.toNat, 1518338049),
    ("f3Natural32", (Float32.ofNat 340282366920938463463374607431768211456).toBits.toNat, 2139095040),
    ("f3Integer64", (Float.ofInt (-9007199254740995)).toBits.toNat, 14069245235905429506),
    ("f3Integer32", (Float32.ofInt (-18014399583223809)).toBits.toNat, 3665821697),
    ("f3DefaultScientificBits", (let value := -42.0; value.toBits.toNat), 13854479828675198976),
    ("f3LiteralMixed64", ((1.0 + 2 : Float).toBits.toNat), 4613937818241073152),
    ("f3LiteralMixed32", ((1.0 + 2 : Float32).toBits.toNat), 1077936128),
    ("f3Partial", (Float.ofScientific 1 true 1).toBits.toNat, 4591870180066957722),
    ("f3Generic32", (Float32.ofScientific 1 true 1).toBits.toNat, 1036831949),
    ("f3WordDoubleRounding32", (UInt64.toFloat32 (UInt64.ofNat 18014399583223809)).toBits.toNat, 1518338049),
    ("f3SignedDoubleRounding32", (Int64.toFloat32 (Int64.ofInt (-18014399583223809))).toBits.toNat, 3665821697)]
  for (name, observed, expected) in checks do
    unless observed == expected do
      throw (IO.userError ("PSCV0_FLOAT_F3_ORACLE: " ++ name ++ " expected " ++ toString expected ++ " got " ++ toString observed))
  IO.println "PSCV0_FLOAT_F3_ORACLE: PASS exact scientific rounding and fixed-width conversion family"

private def floatDisplayNativeOracle : IO Unit := do
  let displays : List (String × String) := [
    (Float.toString (Float.ofBits 0), "0.000000"),
    (Float.toString (Float.ofBits 9223372036854775808), "-0.000000"),
    (Float.toString (Float.ofBits 4609434218613702656), "1.500000"),
    (Float.toString (Float.ofBits 4575657221408423936), "0.007812"),
    (Float.toString (Float.ofBits 4582412620849479680), "0.023438"),
    (Float.toString (Float.ofBits 13799029258263199744), "-0.007812"),
    (Float.toString (Float.ofBits 1), "0.000000"),
    (Float.toString (Float.ofBits 9223372036854775809), "-0.000000"),
    (Float.toString (Float.ofBits 4611686016625948053), "2.000000"),
    (Float.toString (Float.ofBits 4921056587992461136), "1000000000000000000000.000000"),
    (Float.toString (Float.ofBits 9218868437227405311), "179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368.000000"),
    (Float.toString (Float.ofBits 9218868437227405312), "inf"),
    (Float.toString (Float.ofBits 18442240474082181120), "-inf"),
    (Float.toString (Float.ofBits 18442240474082181121), "NaN"),
    (Float32.toString (Float32.ofBits 0), "0.000000"),
    (Float32.toString (Float32.ofBits 2147483648), "-0.000000"),
    (Float32.toString (Float32.ofBits 1074161254), "2.100000"),
    (Float32.toString (Float32.ofBits 1006632960), "0.007812"),
    (Float32.toString (Float32.ofBits 1019215872), "0.023438"),
    (Float32.toString (Float32.ofBits 1), "0.000000"),
    (Float32.toString (Float32.ofBits 2139095039), "340282346638528859811704183484516925440.000000"),
    (Float32.toString (Float32.ofBits 2139095040), "inf"),
    (Float32.toString (Float32.ofBits 4286578688), "-inf"),
    (Float32.toString (Float32.ofBits 4286578689), "NaN"),
    (Std.Format.pretty (Float.repr (Float.ofBits 13832806255468478464) 1024), "(-1.500000)"),
    (Std.Format.pretty (Float.repr (Float.ofBits 9223372036854775808) 1024), "-0.000000"),
    (Std.Format.pretty (Float.repr (Float.ofBits 13832806255468478464) 0), "-1.500000"),
    (Std.Format.pretty (Float32.repr (Float32.ofBits 3217031168) 1024), "(-1.500000)"),
    (toString (1.5 : Float32), "1.500000"),
    (Float.toString (-1.5), "-1.500000"),
    (s!"float={(-0.0 : Float)}", "float=-0.000000"),
    (reprStr [(1.5 : Float), -2.25], "[1.500000, -2.250000]"),
    (Std.Format.pretty (Std.format (1.5 : Float)), "1.500000")]
  for (observed, expected) in displays do
    unless observed == expected do
      throw (IO.userError ("PSCV0_FLOAT_F4_ORACLE: expected " ++ expected ++ " got " ++ observed))
  let casts : List (Nat × Nat) := [
    ((Float.toFloat32 (Float.ofBits 9223372036854775808)).toBits.toNat, 2147483648),
    ((Float.toFloat32 (Float.ofBits 9218868437227405312)).toBits.toNat, 2139095040),
    ((Float.toFloat32 (Float.ofBits 9221120237041090560)).toBits.toNat, 2143289344),
    ((Float.toFloat32 (Float.ofBits 4607182419068452864)).toBits.toNat, 1065353216),
    ((Float.toFloat32 (Float.ofBits 4607182419605323776)).toBits.toNat, 1065353218),
    ((Float.toFloat32 (Float.ofBits 3931642474694443008)).toBits.toNat, 0),
    ((Float.toFloat32 (Float.ofBits 3938397874135498752)).toBits.toNat, 2),
    ((Float.toFloat32 (Float.ofBits 9094988921128908188)).toBits.toNat, 2139095040),
    ((Float32.toFloat (Float32.ofBits 2147483648)).toBits.toNat, 9223372036854775808),
    ((Float32.toFloat (Float32.ofBits 2139095039)).toBits.toNat, 5183643170566569984),
    ((Float32.toFloat (Float32.ofBits 1)).toBits.toNat, 3936146074321813504),
    ((Float32.toFloat (Float32.ofBits 2143289344)).toBits.toNat, 9221120237041090560)]
  for (observed, expected) in casts do
    unless observed == expected do
      throw (IO.userError ("PSCV0_FLOAT_CAST_ORACLE: expected " ++ toString expected ++ " got " ++ toString observed))
  IO.println "PSCV0_FLOAT_F4_ORACLE: PASS fixed-six decimal display, Repr and cross-width contracts"

private def arrayFilterNativeOracle : IO Unit := do
  let values : Array Nat := #[1, 2, 5, 2, 7, 7]
  let greater := fun (value : Nat) => decide (2 < value)
  let pairs : List (List Nat × List Nat) := [
    ((values.filter greater).toList, [5, 7, 7]),
    ((values.filter (fun _ => true) (start := 3)).toList, [2, 7, 7]),
    ((values.filter (fun _ => true) (stop := 3)).toList, [1, 2, 5]),
    ((values.filter (fun _ => false)).toList, []),
    (((#[] : Array Nat).filter greater).toList, []),
    ((values.filter greater (start := 1) (stop := 5)).toList, [5, 7]),
    ((values.filter greater (start := 5) (stop := 2)).toList, []),
    ((values.filter greater (start := 1000000000000000000000) (stop := 1000000000000000000001)).toList, [])]
  unless pairs.all (fun (actual, expected) => actual == expected) do
    throw (IO.userError "PSCV0_ARRAY_FILTER_ORACLE: pinned slice/order mismatch")
  IO.println "PSCV0_ARRAY_FILTER_ORACLE: PASS pinned bounded stable filtering"

private def utf8NativeOracle : IO Unit := do
  let cases : List (List UInt8 × Option String) := [
    ([], some ""),
    ([0], some "\x00"),
    ([65, 0, 66], some "A\x00B"),
    ([127, 194, 128, 223, 191, 224, 160, 128, 239, 191, 191, 240, 144, 128, 128, 244, 143, 191, 191], some "߿ࠀ￿𐀀􏿿"),
    ([239, 187, 191, 65], some "﻿A"),
    ([195, 169, 240, 159, 152, 128], some "é😀"),
    ([128], none),
    ([192, 128], none),
    ([193, 191], none),
    ([194], none),
    ([226, 130], none),
    ([226, 65, 172], none),
    ([224, 159, 191], none),
    ([237, 160, 128], none),
    ([240, 143, 191, 191], none),
    ([244, 144, 128, 128], none),
    ([245, 128, 128, 128], none),
    ([255], none),
    ([65, 195], none)]
  for (input,expected) in cases do
    let bytes := input.toByteArray
    unless String.fromUTF8? bytes == expected && bytes.validateUTF8 == expected.isSome do
      throw (IO.userError "PSCV0_UTF8_ORACLE: native strict decoding mismatch")
    if let some text := expected then
      unless text.toUTF8.toList == input do
        throw (IO.userError "PSCV0_UTF8_ORACLE: native encoding mismatch")
  IO.println "PSCV0_UTF8_ORACLE: PASS strict validation, encoding, scalar boundaries and BOM preservation"

def main : IO Unit := do
  utf8NativeOracle
  arrayFilterNativeOracle
  platformWordCases
  floatDisplayNativeOracle
  floatConversionsNativeOracle
  floatOperationsNativeOracle
  kernelHeartbeatIsolationCases
  selectedStandardManifestCases
  floatConstructorBoundaries
  IO.println "PSCV0_FLOAT_CONSTRUCTIVE_ORACLE: PASS independent pinned Nat.pow_eq_zero statement and axiom audit"
  emissionBoundary
  metavariableBoundary
  parserCases
  getElemFoundationCases
  highUniverseHashableCases
  stringJoinIntercalateCases
  unsignedOperatorSourceCases
  signedNativeOracle
  standardSumNativeOracle
  byteArrayNativeOracle
  byteArrayCollectionNativeOracle
  hAddPolymorphicCases
  unitEmptyCallCases
  semanticCases
  doBoundaries
  projectBoundaries
  derivingBoundaries
  syntheticBoundaries
  defaultInstanceBoundaries
  postponedBoundaries
  transparencyBoundaries
  IO.println "PSCV0_NATIVE_CHECKS: PASS; no compiler-source translation or self-host regeneration"
