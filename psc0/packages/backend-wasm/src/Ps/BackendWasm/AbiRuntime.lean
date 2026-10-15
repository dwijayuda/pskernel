import Ps.BackendWasm.AbiPlan

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
private def trap : R := o .unreachable []
private def cursor : R := o (.globalGet 0) []
private def active : R := o (.globalGet 1) []

def abiAllocate (size alignment : R) : R :=
  .call "__ps_abi_realloc" [.i32 0, .i32 0, alignment, size]

def abiMemoryRuntime : Except String (List RuntimeDefinition) := do
  let emit := fun suffix params results locals body =>
    runtimeDefinition ("__ps_abi_" ++ suffix) params results locals body
  let pointer := g "pointer"
  let size := g "size"
  let alignment := g "alignment"
  let index := g "index"
  let a := g "a"
  let bytes := g "bytes"
  let length := g "length"
  let code := g "code"
  let postReturns ← abiPostReturns.mapM fun (name, parameters) =>
    runtimeDefinition name (parameters.zipIdx.map fun (type, i) => ("result" ++ toString i, type)) [] []
      (seq [choice none (eq active (k 0)) trap (seq []),
        o (.globalSet 0) [k 16], o (.globalSet 1) [k 0]])
  return postReturns ++ [
    ← emit "checked_product" [("a", .i32), ("b", .i32)] [.i32] [("product", .i64)]
      (seq [put "product" (o .i64Mul [
          o (.word .i64ExtendI32U) [a], o (.word .i64ExtendI32U) [g "b"]]),
        choice (some .i32) (o .i64GtU [g "product", .i64 2147483647]) trap
          (o (.word .i32WrapI64) [g "product"])]),
    ← emit "check_range" [("pointer", .i32), ("size", .i32), ("alignment", .i32)] [] [("end", .i32)]
      (seq [
        choice none (o .i32Ne [o .i32And [pointer, sub alignment (k 1)], k 0]) trap (seq []),
        put "end" (c "__ps_checked_size" [pointer, size]),
        choice none (o .i64GtU [o (.word .i64ExtendI32U) [g "end"],
          o (.word .i64Shl) [o (.word .i64ExtendI32U) [o (.memory .size) []], .i64 16]]) trap (seq [])]),
    ← emit "realloc" [("old_pointer", .i32), ("old_size", .i32), ("alignment", .i32), ("size", .i32)] [.i32]
      [("pointer", .i32), ("end", .i32), ("pages", .i32)]
      (choice (some .i32) (eq size (k 0)) (k 0)
        (seq [
          choice none (o .i32Or [eq alignment (k 0),
              o .i32Or [o .i32GtU [alignment, k 8],
                o .i32Ne [o .i32And [alignment, sub alignment (k 1)], k 0]]]) trap (seq []),
          put "pointer" (o .i32And [c "__ps_checked_size" [cursor, sub alignment (k 1)],
            o .i32Sub [k 0, alignment]]),
          put "end" (c "__ps_checked_size" [pointer, size]),
          choice none (o .i32GtU [g "end", k 2147483647]) trap (seq []),
          put "pages" (o .i32ShrU [add (g "end") (k 65535), k 16]),
          choice none (o .i32GtU [g "pages", o (.memory .size) []])
            (choice none (eq (o (.memory .grow) [sub (g "pages") (o (.memory .size) [])]) (k (-1)))
              trap (seq [])) (seq []),
          choice none (o .i32Ne [g "old_size", k 0])
            (seq [c "__ps_abi_check_range" [g "old_pointer", g "old_size", alignment],
              o (.memory .copy) [pointer, g "old_pointer",
                choice (some .i32) (lt size (g "old_size")) size (g "old_size")]]) (seq []),
          o (.globalSet 0) [g "end"], pointer])),
    ← emit "enter" [] [] []
      (seq [choice none (o .i32Ne [active, k 0]) trap (seq []), o (.globalSet 1) [k 1]]),
    ← emit "usage" [] [.i32] [] cursor,
    ← emit "check_bool" [("value", .i32)] [.i32] []
      (choice (some .i32) (o .i32LeU [g "value", k 1]) (g "value") trap),
    ← emit "check_char" [("value", .i32)] [.i32] []
      (choice (some .i32) (o .i32And [lt (g "value") (k 1114112),
        o .i32Or [lt (g "value") (k 55296), o .i32GeU [g "value", k 57344]]]) (g "value") trap),
    ← emit "read_bytes" [("pointer", .i32), ("bytes", bytesType), ("index", .i32)] [bytesType] []
      (choice (some bytesType) (eq index (o .arrayLen [bytes])) bytes
        (seq [o (.arraySet bytesName) [bytes, index, o (.memory .load8) [add pointer index]],
          c "__ps_abi_read_bytes" [pointer, bytes, add index (k 1)]])),
    ← emit "write_bytes" [("pointer", .i32), ("bytes", bytesType), ("index", .i32)] [] []
      (choice none (eq index (o .arrayLen [bytes])) (seq [])
        (seq [o (.memory .store8) [add pointer index, o (.arrayGetU bytesName) [bytes, index]],
          c "__ps_abi_write_bytes" [pointer, bytes, add index (k 1)]])),
    ← emit "utf8_tail" [("bytes", bytesType), ("index", .i32), ("remaining", .i32)] [] []
      (choice none (eq (g "remaining") (k 0)) (seq [])
        (seq [choice none (o .i32Ne [o .i32And [o (.arrayGetU bytesName) [bytes, index], k 192], k 128])
            trap (seq []),
          c "__ps_abi_utf8_tail" [bytes, add index (k 1), sub (g "remaining") (k 1)]])),
    ← emit "utf8_count" [("bytes", bytesType), ("index", .i32), ("length", .i32)] [.i32]
      [("width", .i32), ("code", .i32), ("lead", .i32)]
      (choice (some .i32) (eq index (o .arrayLen [bytes])) length
        (seq [put "lead" (o (.arrayGetU bytesName) [bytes, index]),
          choice none (o .i32Or [
              o .i32And [o .i32GeU [g "lead", k 128], lt (g "lead") (k 194)],
              o .i32GeU [g "lead", k 245]]) trap (seq []),
          put "width" (c "__ps_string_lead_width" [g "lead"]),
          choice none (o .i32GtU [g "width", sub (o .arrayLen [bytes]) index]) trap (seq []),
          c "__ps_abi_utf8_tail" [bytes, add index (k 1), sub (g "width") (k 1)],
          put "code" (c "__ps_abi_check_char" [c "__ps_string_decode" [bytes, index]]),
          choice none (o .i32Ne [c "__ps_string_width" [code], g "width"]) trap (seq []),
          c "__ps_abi_utf8_count" [bytes, add index (g "width"), add length (k 1)]]))]
end PsWasm
