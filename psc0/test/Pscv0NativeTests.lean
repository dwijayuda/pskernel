import Ps.Host.NativeV7
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
  "function keep(value: Nat): Nat := {\n" ++
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
  "const recursiveSection: Nat := sectionFold(37, List.cons(1, List.nil))\n" ++
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
  "const groupFoldAnswer: Nat := groupFold(Nat, Bool, 57, List.cons(true, List.nil), 0)\n" ++
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
  "const inferredLetAnswer: Nat := inferredLetPattern(Prod.mk(0, 126))\n"

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
    { source := "inductive V: Nat -> Type where { | nil: V(0) | cons(k: Nat, tail: V(k)): V(Nat.succ(k)) }\nfunction captured(n: Nat, v: V(n)): Nat := V.rec(fun k value => Nat, n, fun k tail ih => ih, v)\n", emit := true },
    { source := "inductive V: Nat -> Type where { | nil: V(0) | cons(k: Nat, tail: V(k)): V(Nat.succ(k)) }\nfunction bad(n: Nat, v: V(n)): V(n) := match v with { | V.nil => V.nil | V.cons k tail => tail }\n" },
    { source := "inductive V: Nat -> Type where { | nil: V(0) | cons(k: Nat, tail: V(k)): V(Nat.succ(k)) }\nfunction bad(n: Nat, v: V(n)): Nat := match v with { | V.cons k tail => 0 }\n" },
    { source := "inductive Same: Nat -> Nat -> Type where { | same(n: Nat): Same(n, n) }\nfunction bad(n: Nat, value: Same(n, n)): Nat := match value with { }\n" },
    { source := "inductive V: Nat -> Type where { | nil: V(0) | cons(k: Nat, tail: V(k)): V(Nat.succ(k)) }\nfunction bad(v: V(1)): V(1) := match v with { | V.cons k tail => tail }\n" },
    { source := "function bad(a: Bool, b: Bool): Nat := match a, b with { | true => 0 | _ => 1 }\n" },
    { source := "function bad(value: Prod Nat Nat): Nat := match value with { | (x, x) => x }\n" },
    { source := "function bad(value: Option(Option Nat)): Nat := match value with { | .some (.some n) => n | .none => 0 }\n" },
    { source := "function bad(value: Option(Prod Nat Nat)): Nat := match value with { | .some(x, y) => x | .none => 0 }\n" },
    { source := "function bad(value: Option Nat): Nat := if let .some n := value { n } else { n }\n" },
    { source := "function bad(value: Option Nat): Nat := {\n  let .some n := value\n  n\n}\n" }]

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
      some "elaborate", some "elaborate"]
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
    "PSCV0-SCOPE: unknown name", "PSCV0-MATCH: missing feasible"]
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
  IO.println "PSCV0_NATIVE_SEMANTICS: PASS 4 checked programs, 44 phase-specific refusals, shared-prelude isolation"

def main : IO Unit := do
  parserCases
  semanticCases
  IO.println "PSCV0_NATIVE_CHECKS: PASS; no compiler-source translation or self-host regeneration"
