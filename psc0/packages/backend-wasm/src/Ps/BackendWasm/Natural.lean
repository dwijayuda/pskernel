import Ps.BackendWasm.Value

namespace PsWasm

-- Little-endian unsigned 32-bit limbs. Published Natural values are immutable;
-- only freshly allocated working arrays are mutated. Zero has no limbs.
-- Loops are emitted as typed tail calls, including nested multiplication loops.
private def g := RuntimeCode.get
private def k := RuntimeCode.i32
private def o := RuntimeCode.op
private def c := RuntimeCode.call
private def put := RuntimeCode.set
private def seq := RuntimeCode.seq
private def choice := RuntimeCode.ite
private def wide (v : R) := o (.word .i64ExtendI32U) [v]
private def low (v : R) := o (.word .i32WrapI64) [v]
private def high (v : R) := o (.word .i64ShrU) [v, .i64 32]
private def add (a b : R) := o .i32Add [a, b]
private def sub (a b : R) := o .i32Sub [a, b]
private def eq (a b : R) := o .i32Eq [a, b]
private def lt (a b : R) := o .i32LtU [a, b]
private def len (a : R) := o .arrayLen [a]
private def limbs (a : R) := o (.structGet naturalName 0) [a]
private def limb (a index : R) := o (.arrayGet limbsName) [a, index]
private def write (a index value : R) := o (.arraySet limbsName) [a, index, value]
private def allocate (size : R) := o (.arrayNewDefault limbsName) [size]
private def natural (a : R) := o (.structNew naturalName) [a]
private def trap : R := o .unreachable []

private def natFunction (suffix : String) (parameters : List (String × PsWasmValueType))
    (result : PsWasmValueType) (locals : List (String × PsWasmValueType)) (body : R) :=
  runtimeDefinition ("__ps_nat_" ++ suffix) parameters [result] locals body

-- Normalization consumes an owned working array. The returned array is never
-- subsequently written through that working reference.
def naturalRuntime : Except String (List RuntimeDefinition) := do
  let a := g "a"
  let b := g "b"
  let size := g "size"
  let index := g "index"
  let output := g "output"
  let carry := g "carry"
  let total := g "total"
  let mut functions : List RuntimeDefinition := []
  let emit := natFunction
  functions := functions ++ [← emit "zero" [] naturalType []
    (natural (o (.arrayNewFixed limbsName 0) []))]
  functions := functions ++ [← emit "from_u32" [("value", .i32)] naturalType []
    (choice (some naturalType) (eq (g "value") (k 0))
      (c "__ps_nat_zero" [])
      (natural (o (.arrayNewFixed limbsName 1) [g "value"])))]
  functions := functions ++ [← emit "trim" [("a", limbsType), ("size", .i32)] naturalType [("output", limbsType)]
    (choice (some naturalType) (eq size (k 0)) (c "__ps_nat_zero" [])
      (choice (some naturalType) (eq (limb a (sub size (k 1))) (k 0))
        (c "__ps_nat_trim" [a, sub size (k 1)])
        (choice (some naturalType) (eq size (len a)) (natural a)
          (seq [put "output" (allocate size),
            o (.arrayCopy limbsName limbsName) [output, k 0, a, k 0, size],
            natural output]))))]
  functions := functions ++ [← emit "is_zero" [("value", naturalType)] .i32 []
    (eq (len (limbs (g "value"))) (k 0))]
  functions := functions ++ [← emit "to_u32" [("value", naturalType)] .i32 []
    (choice (some .i32) (eq (len (limbs (g "value"))) (k 0)) (k 0)
      (choice (some .i32) (eq (len (limbs (g "value"))) (k 1))
        (limb (limbs (g "value")) (k 0)) trap))]
  functions := functions ++ [← emit "at" [("a", limbsType), ("index", .i32)] .i32 []
    (choice (some .i32) (lt index (len a)) (limb a index) (k 0))]
  functions := functions ++ [← emit "compare_limbs" [("a", limbsType), ("b", limbsType), ("size", .i32)] .i32 []
    (choice (some .i32) (eq size (k 0)) (k 0)
      (choice (some .i32) (eq (limb a (sub size (k 1))) (limb b (sub size (k 1))))
        (c "__ps_nat_compare_limbs" [a, b, sub size (k 1)])
        (choice (some .i32) (lt (limb a (sub size (k 1))) (limb b (sub size (k 1))))
          (k (-1)) (k 1))))]
  functions := functions ++ [← emit "compare" [("left", naturalType), ("right", naturalType)] .i32
    [("a", limbsType), ("b", limbsType)]
    (seq [put "a" (limbs (g "left")), put "b" (limbs (g "right")),
      choice (some .i32) (eq (len a) (len b))
        (c "__ps_nat_compare_limbs" [a, b, len a])
        (choice (some .i32) (lt (len a) (len b)) (k (-1)) (k 1))])]
  functions := functions ++ [← emit "checked_size" [("a", .i32), ("b", .i32)] .i32 [("size", .i32)]
    (seq [put "size" (add a b),
      -- Bound bit positions as well as allocation indices without truncation.
      choice (some .i32) (o .i32Or [lt size a, o .i32GtU [size, k 134217727]]) trap size])]
  functions := functions ++ [← emit "add_loop"
    [("a", limbsType), ("b", limbsType), ("output", limbsType),
     ("index", .i32), ("size", .i32), ("carry", .i64)]
    naturalType [("total", .i64)]
    (choice (some naturalType) (eq index size)
      (seq [write output size (low carry), c "__ps_nat_trim" [output, add size (k 1)]])
      (seq [put "total" (o .i64Add [o .i64Add [
          wide (c "__ps_nat_at" [a, index]), wide (c "__ps_nat_at" [b, index])], carry]),
        write output index (low total),
        c "__ps_nat_add_loop" [a, b, output, add index (k 1), size, high total]]))]
  functions := functions ++ [← emit "add" [("left", naturalType), ("right", naturalType)] naturalType
    [("a", limbsType), ("b", limbsType), ("size", .i32)]
    (seq [put "a" (limbs (g "left")), put "b" (limbs (g "right")),
      put "size" (choice (some .i32) (lt (len a) (len b)) (len b) (len a)),
      c "__ps_nat_add_loop" [a, b, allocate (c "__ps_nat_checked_size" [size, k 1]),
        k 0, size, .i64 0]])]
  functions := functions ++ [← emit "subtract_loop"
    [("a", limbsType), ("b", limbsType), ("output", limbsType),
     ("index", .i32), ("borrow", .i64)] naturalType [("total", .i64)]
    (choice (some naturalType) (eq index (len a)) (c "__ps_nat_trim" [output, len a])
      (seq [put "total" (o .i64Sub [o .i64Sub [
          wide (limb a index), wide (c "__ps_nat_at" [b, index])], g "borrow"]),
        write output index (low total),
        c "__ps_nat_subtract_loop" [a, b, output, add index (k 1),
          o (.word .i64ShrU) [total, .i64 63]]]))]
  functions := functions ++ [← emit "sub" [("left", naturalType), ("right", naturalType)] naturalType []
    (choice (some naturalType)
      (o .i32LtS [c "__ps_nat_compare" [g "left", g "right"], k 0])
      (c "__ps_nat_zero" [])
      (c "__ps_nat_subtract_loop" [limbs (g "left"), limbs (g "right"),
        allocate (len (limbs (g "left"))), k 0, .i64 0]))]
  functions := functions ++ [← emit "multiply_row"
    [("a", limbsType), ("b", limbsType), ("output", limbsType),
     ("row", .i32), ("index", .i32), ("carry", .i64)] limbsType [("total", .i64)]
    (choice (some limbsType) (eq index (len b))
      (seq [write output (add (g "row") index) (low carry), output])
      (seq [put "total" (o .i64Add [o .i64Add [
          o .i64Mul [wide (limb a (g "row")), wide (limb b index)],
          wide (limb output (add (g "row") index))], carry]),
        write output (add (g "row") index) (low total),
        c "__ps_nat_multiply_row" [a, b, output, g "row", add index (k 1), high total]]))]
  functions := functions ++ [← emit "multiply_rows"
    [("a", limbsType), ("b", limbsType), ("output", limbsType), ("row", .i32)] naturalType []
    (choice (some naturalType) (eq (g "row") (len a)) (c "__ps_nat_trim" [output, len output])
      (c "__ps_nat_multiply_rows" [a, b,
        c "__ps_nat_multiply_row" [a, b, output, g "row", k 0, .i64 0], add (g "row") (k 1)]))]
  functions := functions ++ [← emit "mul" [("left", naturalType), ("right", naturalType)] naturalType
    [("a", limbsType), ("b", limbsType)]
    (seq [put "a" (limbs (g "left")), put "b" (limbs (g "right")),
      choice (some naturalType) (o .i32Or [eq (len a) (k 0), eq (len b) (k 0)])
        (c "__ps_nat_zero" [])
        (c "__ps_nat_multiply_rows" [a, b,
          allocate (c "__ps_nat_checked_size" [len a, len b]), k 0])])]
  -- Binary long division is bounded by dividend bit length, never by quotient
  -- magnitude. Both results are computed in one traversal; the selector only
  -- chooses which normalized value is returned.
  functions := functions ++ [← emit "divide_bits"
    [("a", limbsType), ("divisor", naturalType), ("quotient", limbsType),
     ("remainder", naturalType), ("position", .i32), ("want_remainder", .i32)] naturalType
    [("next", naturalType), ("bit", .i32), ("index", .i32), ("mask", .i32)]
    (choice (some naturalType) (eq (g "position") (k 0))
      (choice (some naturalType) (g "want_remainder") (g "remainder")
        (c "__ps_nat_trim" [g "quotient", len (g "quotient")]))
      (seq [put "position" (sub (g "position") (k 1)),
        put "index" (o .i32ShrU [g "position", k 5]),
        put "mask" (o (.word .i32Shl) [k 1, o .i32And [g "position", k 31]]),
        put "bit" (o .i32Ne [o .i32And [limb a index, g "mask"], k 0]),
        put "next" (c "__ps_nat_add" [
          c "__ps_nat_add" [g "remainder", g "remainder"],
          c "__ps_nat_from_u32" [g "bit"]]),
        choice (some naturalType)
          (o .i32LtS [c "__ps_nat_compare" [g "next", g "divisor"], k 0])
          (c "__ps_nat_divide_bits" [a, g "divisor", g "quotient", g "next",
            g "position", g "want_remainder"])
          (seq [write (g "quotient") index (o .i32Or [limb (g "quotient") index, g "mask"]),
            c "__ps_nat_divide_bits" [a, g "divisor", g "quotient",
              c "__ps_nat_sub" [g "next", g "divisor"], g "position", g "want_remainder"]])]))]
  -- Single-limb division is linear in the numerator's limb count. This is the
  -- common path for small divisors and decimal formatting.
  functions := functions ++ [← emit "divide_word"
    [("a", limbsType), ("divisor", .i64), ("quotient", limbsType),
     ("size", .i32), ("carry", .i64), ("want_remainder", .i32)] naturalType [("total", .i64)]
    (choice (some naturalType) (eq size (k 0))
      (choice (some naturalType) (g "want_remainder")
        (c "__ps_nat_from_u32" [low carry])
        (c "__ps_nat_trim" [g "quotient", len (g "quotient")]))
      (seq [put "size" (sub size (k 1)),
        put "total" (o .i64Or [o (.word .i64Shl) [carry, .i64 32], wide (limb a size)]),
        write (g "quotient") size (low (o (.word .i64DivU) [total, g "divisor"])),
        c "__ps_nat_divide_word" [a, g "divisor", g "quotient", size,
          o (.word .i64RemU) [total, g "divisor"], g "want_remainder"]]))]
  functions := functions ++ [← emit "divide"
    [("left", naturalType), ("right", naturalType), ("want_remainder", .i32)] naturalType
    [("a", limbsType), ("size", .i32)]
    (choice (some naturalType) (c "__ps_nat_is_zero" [g "right"])
      (choice (some naturalType) (g "want_remainder") (g "left") (c "__ps_nat_zero" []))
      (seq [put "a" (limbs (g "left")),
        put "size" (c "__ps_nat_checked_size" [len a, k 0]),
        choice (some naturalType) (eq (len (limbs (g "right"))) (k 1))
          (c "__ps_nat_divide_word" [a, wide (limb (limbs (g "right")) (k 0)), allocate size,
            size, .i64 0, g "want_remainder"])
          (c "__ps_nat_divide_bits" [a, g "right", allocate size, c "__ps_nat_zero" [],
            o (.word .i32Shl) [size, k 5], g "want_remainder"])]))]
  for (suffix, instruction) in [
      ("eq", PsWasmInstruction.i32Eq), ("ne", .i32Ne),
      ("lt", .i32LtS), ("le", .i32LeS)] do
    functions := functions ++ [← emit suffix [("left", naturalType), ("right", naturalType)] .i32 []
      (o instruction [c "__ps_nat_compare" [g "left", g "right"], k 0])]
  for (suffix, remainder) in [("div", false), ("mod", true)] do
    functions := functions ++ [← emit suffix [("left", naturalType), ("right", naturalType)] naturalType []
      (c "__ps_nat_divide" [g "left", g "right", k (if remainder then 1 else 0)])]
  return functions

-- Literal work is proportional to limb count, including huge source literals.
def naturalLiteralLimbs : Nat → Nat → List PsWasmInstruction
  | 0, _ => []
  | n + 1, value =>
    if value == 0 then [] else
      .i32Const (Int.ofNat (value % 4294967296)) :: naturalLiteralLimbs n (value / 4294967296)

def naturalLiteral (value : Nat) : List PsWasmInstruction :=
  let limbs := naturalLiteralLimbs (value.log2 / 32 + 1) value
  limbs ++ [.arrayNewFixed limbsName limbs.length, .structNew naturalName]

end PsWasm
