/-
Adapted from Lean 4.35.0 runtime/hash.{h,cpp}.
Copyright (c) 2013 Microsoft Corporation. Author: Leonardo de Moura.
Apache-2.0; see THIRD_PARTY_NOTICES.md. MurmurHash2 by Austin Appleby.
Modified: canonical little-endian GC byte-array traversal; no linear memory.
-/
import Ps.BackendWasm.String
namespace PsWasm
private def g := RuntimeCode.get
private def k := RuntimeCode.i32
private def q := RuntimeCode.i64
private def o := RuntimeCode.op
private def c := RuntimeCode.call
private def put := RuntimeCode.set
private def seq := RuntimeCode.seq
private def choose := RuntimeCode.ite
private def multiplier : R := q 14313749767032793493
private def multiply (value : R) : R := o .i64Mul [value, multiplier]
private def scramble (value : R) : R := o .i64Xor [value, o (.word .i64ShrU) [value, q 47]]
private def add (left right : R) : R := o .i32Add [left, right]

def hashRuntime : Except String (List RuntimeDefinition) := do
  return [
    ← runtimeDefinition "__ps_hash_mix" [("seed", .i64), ("key", .i64)] [.i64] []
      (seq [put "key" (multiply (g "key")), put "key" (scramble (g "key")),
        multiply (o .i64Xor [g "seed", o .i64Xor [g "key", multiplier]])]),
    -- At most eight bytes; small recursive calls are converted to tail loops.
    ← runtimeDefinition "__ps_hash_word"
      [("bytes", bytesType), ("index", .i32), ("count", .i32), ("shift", .i64), ("word", .i64)]
      [.i64] []
      (choose (some .i64) (o .i32Eq [g "count", k 0]) (g "word")
        (c "__ps_hash_word" [g "bytes", add (g "index") (k 1),
          o .i32Sub [g "count", k 1], o .i64Add [g "shift", q 8],
          o .i64Or [g "word", o (.word .i64Shl) [
            o (.word .i64ExtendI32U) [o (.arrayGetU bytesName) [g "bytes", g "index"]],
            g "shift"]]])),
    ← runtimeDefinition "__ps_hash_blocks"
      [("bytes", bytesType), ("index", .i32), ("hash", .i64)] [.i64]
      [("remaining", .i32), ("key", .i64)]
      (seq [put "remaining" (o .i32Sub [o .arrayLen [g "bytes"], g "index"]),
        choose (some .i64) (o .i32GeU [g "remaining", k 8])
          (seq [put "key" (multiply (c "__ps_hash_word" [g "bytes", g "index", k 8, q 0, q 0])),
            put "key" (multiply (scramble (g "key"))),
            c "__ps_hash_blocks" [g "bytes", add (g "index") (k 8),
              multiply (o .i64Xor [g "hash", g "key"])]])
          (seq [
            choose none (o .i32Ne [g "remaining", k 0])
              (put "hash" (multiply (o .i64Xor [g "hash",
                c "__ps_hash_word" [g "bytes", g "index", g "remaining", q 0, q 0]])))
              (seq []),
            put "hash" (multiply (scramble (g "hash"))),
            scramble (g "hash")])]),
    ← runtimeDefinition "__ps_string_hash" [("text", stringType)] [.i64] [("bytes", bytesType)]
      (seq [put "bytes" (o (.structGet stringName 0) [g "text"]),
        c "__ps_hash_blocks" [g "bytes", k 0,
          o .i64Xor [q 11, multiply (o (.word .i64ExtendI32U) [o .arrayLen [g "bytes"]])]]])
  ]
end PsWasm
