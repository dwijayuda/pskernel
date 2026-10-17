import Ps.BackendWasm.Integer

namespace PsWasm

private def g := RuntimeCode.get
private def k := RuntimeCode.i32
private def o := RuntimeCode.op
private def c := RuntimeCode.call
private def put := RuntimeCode.set
private def seq := RuntimeCode.seq
private def choice := RuntimeCode.ite
private def add (a b : R) := o .i32Add [a, b]
private def sub (a b : R) := o .i32Sub [a, b]
private def eq (a b : R) := o .i32Eq [a, b]
private def lt (a b : R) := o .i32LtU [a, b]
private def len (a : R) := o .arrayLen [a]
private def bytes (a : R) := o (.structGet stringName 0) [a]
private def count (a : R) := o (.structGet stringName 1) [a]
private def byte (a index : R) := o (.arrayGetU bytesName) [a, index]
private def write (a index value : R) := o (.arraySet bytesName) [a, index, value]
private def allocate (size : R) := o (.arrayNewDefault bytesName) [size]
private def string (a size : R) := o (.structNew stringName) [a, size]
private def trap : R := o .unreachable []
private def nat (n : R) := c "__ps_nat_from_u32" [n]
private def narrow (n : R) := c "__ps_nat_to_u32" [n]

-- Internal strings always contain valid UTF-8. Offsets are byte positions,
-- including Lean's defined fallbacks at continuation bytes and past the end.
def stringRuntime : Except String (List RuntimeDefinition) := do
  let emit := fun suffix params result locals body =>
    runtimeDefinition ("__ps_string_" ++ suffix) params [result] locals body
  let a := g "a"
  let b := g "b"
  let index := g "index"
  let size := g "size"
  let output := g "output"
  let text := g "text"
  let position := g "position"
  let code := g "code"
  let mut functions := [
    ← runtimeDefinition "__ps_checked_size" [("a", .i32), ("b", .i32)] [.i32] [("size", .i32)]
      (seq [put "size" (add a b), choice (some .i32) (lt size a) trap size]),
    ← runtimeDefinition "__ps_char_of_nat" [("value", naturalType)] [.i32] [("code", .i32)]
      (choice (some .i32) (c "__ps_nat_lt" [g "value", nat (k 1114112)])
        (seq [put "code" (narrow (g "value")),
          choice (some .i32) (o .i32And [o .i32GeU [code, k 55296], lt code (k 57344)]) (k 0) code])
        (k 0)),
    ← emit "empty" [] stringType [] (string (o (.arrayNewFixed bytesName 0) []) (k 0)),
    ← emit "boundary" [("a", bytesType), ("index", .i32)] .i32 []
      (choice (some .i32) (eq index (len a)) (k 1)
        (choice (some .i32) (lt index (len a))
          (o .i32Ne [o .i32And [byte a index, k 192], k 128]) (k 0))),
    ← emit "width" [("code", .i32)] .i32 []
      (choice (some .i32) (lt code (k 128)) (k 1)
        (choice (some .i32) (lt code (k 2048)) (k 2)
          (choice (some .i32) (lt code (k 65536)) (k 3) (k 4)))),
    ← emit "lead_width" [("code", .i32)] .i32 []
      (choice (some .i32) (lt code (k 128)) (k 1)
        (choice (some .i32) (lt code (k 224)) (k 2)
          (choice (some .i32) (lt code (k 240)) (k 3) (k 4)))),
    ← emit "decode_tail" [("a", bytesType), ("index", .i32), ("remaining", .i32), ("code", .i32)] .i32 []
      (choice (some .i32) (eq (g "remaining") (k 0)) code
        (c "__ps_string_decode_tail" [a, add index (k 1), sub (g "remaining") (k 1),
          o .i32Or [o (.word .i32Shl) [code, k 6], o .i32And [byte a index, k 63]]])),
    ← emit "decode" [("a", bytesType), ("index", .i32)] .i32 [("code", .i32), ("size", .i32)]
      (seq [put "code" (byte a index), put "size" (c "__ps_string_lead_width" [code]),
        choice (some .i32) (eq size (k 1)) code
          (c "__ps_string_decode_tail" [a, add index (k 1), sub size (k 1),
            o .i32And [code, o .i32ShrU [k 127, size]]])]),
    ← emit "encode_tail" [("output", bytesType), ("index", .i32), ("code", .i32), ("size", .i32)] stringType []
      (choice (some stringType) (eq index (k 0))
        (seq [write output (k 0) (o .i32Or [code,
            choice (some .i32) (eq size (k 1)) (k 0)
              (choice (some .i32) (eq size (k 2)) (k 192)
                (choice (some .i32) (eq size (k 3)) (k 224) (k 240)))]),
          string output (k 1)])
        (seq [write output index (o .i32Or [k 128, o .i32And [code, k 63]]),
          c "__ps_string_encode_tail" [output, sub index (k 1), o .i32ShrU [code, k 6], size]])),
    ← emit "singleton" [("code", .i32)] stringType [("size", .i32)]
      (seq [put "size" (c "__ps_string_width" [code]),
        c "__ps_string_encode_tail" [allocate size, sub size (k 1), code, size]]),
    ← emit "length" [("text", stringType)] naturalType [] (nat (count text)),
    ← emit "byte_size" [("text", stringType)] naturalType [] (nat (len (bytes text))),
    ← emit "append" [("a", stringType), ("b", stringType)] stringType [("output", bytesType), ("size", .i32)]
      (seq [put "size" (c "__ps_checked_size" [len (bytes a), len (bytes b)]),
        put "output" (allocate size),
        o (.arrayCopy bytesName bytesName) [output, k 0, bytes a, k 0, len (bytes a)],
        o (.arrayCopy bytesName bytesName) [output, len (bytes a), bytes b, k 0, len (bytes b)],
        string output (c "__ps_checked_size" [count a, count b])]),
    ← emit "push" [("text", stringType), ("code", .i32)] stringType []
      (c "__ps_string_append" [text, c "__ps_string_singleton" [code]]),
    ← emit "equal_bytes" [("a", bytesType), ("b", bytesType), ("index", .i32)] .i32 []
      (choice (some .i32) (eq index (len a)) (k 1)
        (choice (some .i32) (eq (byte a index) (byte b index))
          (c "__ps_string_equal_bytes" [a, b, add index (k 1)]) (k 0))),
    ← emit "eq" [("a", stringType), ("b", stringType)] .i32 []
      (choice (some .i32) (eq (len (bytes a)) (len (bytes b)))
        (c "__ps_string_equal_bytes" [bytes a, bytes b, k 0]) (k 0)),
    ← emit "at_end" [("text", stringType), ("position", naturalType)] .i32 []
      (c "__ps_nat_le" [nat (len (bytes text)), position]),
    ← emit "get" [("text", stringType), ("position", naturalType)] .i32 [("index", .i32)]
      (choice (some .i32) (c "__ps_nat_lt" [position, nat (len (bytes text))])
        (seq [put "index" (narrow position),
          choice (some .i32) (c "__ps_string_boundary" [bytes text, index])
            (c "__ps_string_decode" [bytes text, index]) (k 65)]) (k 65)),
    ← emit "next" [("text", stringType), ("position", naturalType)] naturalType [("size", .i32), ("index", .i32)]
      (seq [put "size" (k 1),
        choice none (c "__ps_nat_lt" [position, nat (len (bytes text))])
          (seq [put "index" (narrow position),
            choice none (c "__ps_string_boundary" [bytes text, index])
              (put "size" (c "__ps_string_lead_width" [byte (bytes text) index])) (seq [])]) (seq []),
        c "__ps_nat_add" [position, nat size]]),
    ← emit "count" [("a", bytesType), ("index", .i32), ("size", .i32), ("count", .i32)] .i32 []
      (choice (some .i32) (eq index size) (g "count")
        (c "__ps_string_count" [a, add index (k 1), size,
          add (g "count") (c "__ps_string_boundary" [a, index])])),
    ← emit "slice" [("a", bytesType), ("start", .i32), ("stop", .i32)] stringType
      [("output", bytesType), ("size", .i32)]
      (seq [put "size" (sub (g "stop") (g "start")), put "output" (allocate size),
        o (.arrayCopy bytesName bytesName) [output, k 0, a, g "start", size],
        string output (c "__ps_string_count" [output, k 0, size, k 0])]),
    ← emit "extract" [("text", stringType), ("start", naturalType), ("stop", naturalType)] stringType
      [("index", .i32), ("size", .i32)]
      (choice (some stringType) (o .i32And [
          c "__ps_nat_lt" [g "start", g "stop"],
          c "__ps_nat_lt" [g "start", nat (len (bytes text))]])
        (seq [put "index" (narrow (g "start")),
          choice (some stringType) (c "__ps_string_boundary" [bytes text, index])
            (seq [put "size" (len (bytes text)),
              choice none (c "__ps_nat_lt" [g "stop", nat size])
                (choice none (c "__ps_string_boundary" [bytes text, narrow (g "stop")])
                  (put "size" (narrow (g "stop"))) (seq [])) (seq []),
              c "__ps_string_slice" [bytes text, index, size]])
            (c "__ps_string_empty" [])])
        (c "__ps_string_empty" []))]
  -- Decimal formatting uses a fresh limb workspace, never mutates a Nat value.
  functions := functions ++ [
    ← emit "decimal_word" [("a", limbsType), ("size", .i32), ("carry", .i64)] .i32 [("total", .i64)]
      (choice (some .i32) (eq size (k 0)) (o (.word .i32WrapI64) [g "carry"])
        (seq [put "size" (sub size (k 1)),
          put "total" (o .i64Or [o (.word .i64Shl) [g "carry", .i64 32],
            o (.word .i64ExtendI32U) [o (.arrayGet limbsName) [a, size]]]),
          o (.arraySet limbsName) [a, size, o (.word .i32WrapI64) [o (.word .i64DivU) [g "total", .i64 10]]],
          c "__ps_string_decimal_word" [a, size, o (.word .i64RemU) [g "total", .i64 10]]])),
    ← emit "decimal_size" [("a", limbsType), ("size", .i32)] .i32 []
      (choice (some .i32) (eq size (k 0)) (k 0)
        (choice (some .i32) (eq (o (.arrayGet limbsName) [a, sub size (k 1)]) (k 0))
          (c "__ps_string_decimal_size" [a, sub size (k 1)]) size)),
    ← emit "decimal" [("a", limbsType), ("size", .i32), ("output", bytesType), ("index", .i32), ("negative", .i32)]
      stringType [("digit", .i32)]
      (seq [put "digit" (c "__ps_string_decimal_word" [a, size, .i64 0]),
        put "index" (sub index (k 1)), write output index (add (k 48) (g "digit")),
        put "size" (c "__ps_string_decimal_size" [a, size]),
        choice (some stringType) (eq size (k 0))
          (seq [choice none (g "negative")
              (seq [put "index" (sub index (k 1)), write output index (k 45)]) (seq []),
            c "__ps_string_slice" [output, index, len output]])
          (c "__ps_string_decimal" [a, size, output, index, g "negative"])]),
    ← runtimeDefinition "__ps_int_repr" [("value", integerType)] [stringType]
      [("a", limbsType), ("work", limbsType), ("size", .i32), ("capacity", .i32)]
      (seq [put "a" (o (.structGet naturalName 0) [o (.structGet integerName 1) [g "value"]]),
        put "size" (len a), put "work" (o (.arrayNewDefault limbsName) [size]),
        o (.arrayCopy limbsName limbsName) [g "work", k 0, a, k 0, size],
        -- Natural limb count is bounded; ten decimal digits per limb + sign.
        put "capacity" (add (o .i32Mul [size, k 10]) (k 2)),
        c "__ps_string_decimal" [g "work", size, allocate (g "capacity"), g "capacity",
          o .i32LtS [o (.structGet integerName 0) [g "value"], k 0]]])]
  return functions

def stringLiteral (value : String) : List PsWasmInstruction :=
  value.toUTF8.data.toList.map (fun b => .i32Const (Int.ofNat b.toNat)) ++
    [.arrayNewFixed bytesName value.utf8ByteSize, .i32Const (Int.ofNat value.length), .structNew stringName]

end PsWasm
