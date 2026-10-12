import Ps.Host.NativeV7
import Ps.Compiler.Pscv0Modules
import Pscv0M1Harness

open Lean (toJson)

private def get {α : Type} (label : String) (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError (label ++ ": " ++ error))

private def parserCases : IO Unit := do
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

private def application : String :=
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
  "const appendSimple: Bool := if (\"left\" ++ \"right\" = \"leftright\") { true } else { false }\n" ++
  "const appendUnicode: Bool := if (\"🍋\" ++ \"é\" = \"🍋é\") { true } else { false }\n" ++
  "const appendGrouped: Bool := if ((\"A\" ++ \"B\") ++ \"C\" = \"ABC\") { true } else { false }\n" ++
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
  "namespace DoCore\nfunction pair(value: Nat): Except(String, Nat × Nat) := do {\n  return (value, Nat.add(value, 1))\n}\nfunction flow(flag: Bool, fail: Bool): Except String Nat := do {\n  let base: Nat := 300\n  if (flag) {\n    return base\n  }\n  let (left, right) ← pair(base)\n  let _: Unit ← if (fail) { Except.error(\"stopped\") } else { Except.ok(()) }\n  return Nat.add(left, right)\n}\nfunction read(value: Except String Nat): Nat :=\n  match value with { | .error _ => 399 | .ok n => n }\nfunction optionFlow(found: Bool): Option Nat := do {\n  let n: Nat ← if (found) { Option.some(302) } else { Option.none }\n  if let .some extra := Option.some(2) {\n    return Nat.add(n, extra)\n  }\n  return 0\n}\nfunction readOption(value: Option Nat): Nat :=\n  match value with { | .none => 398 | .some n => n }\nfunction Identity(A: Type): Type := Id A\nfunction identityFlow(flag: Bool): Identity Nat := do {\n  let x: Nat ← do {\n    return 303\n  }\n  if (h : flag) {\n    let proof: flag = true := h\n    return x\n  }\n  let (a, b): Nat × Nat := (x, 2)\n  return Nat.add(a, b)\n}\nfunction identityOption(flag: Bool): Id(Option Nat) := do {\n  if (flag) {\n    return Option.some(306)\n  }\n  return Option.none\n}\nfunction ignoredUnit(flag: Bool): Except String Nat := do {\n  if (flag) {\n    Except.ok(())\n    Except.ok(())\n  }\n  return 307\n}\nend DoCore\nconst doEarlyAnswer: Nat := DoCore.read(DoCore.flow(true, false))\nconst doBindAnswer: Nat := DoCore.read(DoCore.flow(false, false))\nconst doErrorAnswer: Nat := DoCore.read(DoCore.flow(false, true))\nconst doOptionAnswer: Nat := DoCore.readOption(DoCore.optionFlow(true))\nconst doNoneAnswer: Nat := DoCore.readOption(DoCore.optionFlow(false))\nconst doIdentityEarly: Nat := DoCore.identityFlow(true)\nconst doIdentityTail: Nat := DoCore.identityFlow(false)\nconst doIdentityOption: Nat := DoCore.readOption(DoCore.identityOption(true))\nconst doIgnoredUnit: Nat := DoCore.read(DoCore.ignoredUnit(true))\n"

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
  IO.println "PSCV0_NATIVE_SCOPE_BOUNDARY: PASS delayed cycle and goal scope refusal"

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
  IO.println "PSCV0_NATIVE_DO: PASS 7 do refusals and 1 opaque definitional-opacity refusal"

-- Reuse the production graph planner and checked environment, rather than
-- introducing a separate project interpreter or a large fixture suite.
private def projectBoundaries : IO Unit := do
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
      targets := [.javascript, .typescript, .rust] }]
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
    | 13, .error error =>
        unless error.phase == "elaborate" do
          throw (IO.userError "invalid radix literal was not refused by elaboration")
    | _, _ => throw (IO.userError s!"module official checker acceptance mismatch {i}")
  IO.println "PSCV0_NATIVE_MODULES: PASS module boundaries, RC4 raw/radix, checked ToString dictionaries, abbreviation exposure and entry exports"

def main : IO Unit := do
  emissionBoundary
  metavariableBoundary
  parserCases
  semanticCases
  doBoundaries
  projectBoundaries
  IO.println "PSCV0_NATIVE_CHECKS: PASS; no compiler-source translation or self-host regeneration"
