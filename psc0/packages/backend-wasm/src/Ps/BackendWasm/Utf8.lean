import Ps.BackendWasm.Array

namespace PsWasm
private def g := RuntimeCode.get
private def k := RuntimeCode.i32
private def o := RuntimeCode.op
private def c := RuntimeCode.call
private def put := RuntimeCode.set
private def seq := RuntimeCode.seq
private def choice := RuntimeCode.ite
private def add (a b : R) := o .i32Add [a,b]
private def sub (a b : R) := o .i32Sub [a,b]
private def eq (a b : R) := o .i32Eq [a,b]
private def lt (a b : R) := o .i32LtU [a,b]
private def len (a : R) := o .arrayLen [a]
private def byte (a index : R) := o (.arrayGetU bytesName) [a,index]
private def values (a : R) := o (.structGet arrayName 0) [a]

-- Strict validation is shared by source decoding and Canonical ABI input.
-- Count uses i64 so the -1 invalid sentinel cannot alias any valid u32 length.
-- Every continuation read is preceded by the whole-scalar remaining-size check.
def utf8Runtime : Except String (List RuntimeDefinition) := do
  let emit := fun suffix params result locals body =>
    runtimeDefinition ("__ps_utf8_" ++ suffix) params [result] locals body
  let bytes := g "bytes"
  let index := g "index"
  let width := g "width"
  let code := g "code"
  let output := g "output"
  let source := g "source"
  let invalid : R := .i64 (-1)
  let scalarValid := o .i32And [lt code (k 1114112),
    o .i32Or [lt code (k 55296), o .i32GeU [code,k 57344]]]
  return [
    ← emit "tail" [("bytes",bytesType),("index",.i32),("remaining",.i32)] .i32 []
      (choice (some .i32) (eq (g "remaining") (k 0)) (k 1)
        (choice (some .i32) (eq (o .i32And [byte bytes index,k 192]) (k 128))
          (c "__ps_utf8_tail" [bytes,add index (k 1),sub (g "remaining") (k 1)]) (k 0))),
    ← emit "count" [("bytes",bytesType),("index",.i32),("count",.i64)] .i64
      [("lead",.i32),("width",.i32),("code",.i32)]
      (choice (some .i64) (eq index (len bytes)) (g "count")
        (choice (some .i64) (lt index (len bytes))
          (seq [put "lead" (byte bytes index),
            choice (some .i64) (o .i32Or [
                o .i32And [o .i32GeU [g "lead",k 128],lt (g "lead") (k 194)],
                o .i32GeU [g "lead",k 245]]) invalid
              (seq [put "width" (c "__ps_string_lead_width" [g "lead"]),
                choice (some .i64) (o .i32GtU [width,sub (len bytes) index]) invalid
                  (choice (some .i64) (c "__ps_utf8_tail" [bytes,add index (k 1),sub width (k 1)])
                    (seq [put "code" (c "__ps_string_decode" [bytes,index]),
                      choice (some .i64) (o .i32And [scalarValid,
                          eq (c "__ps_string_width" [code]) width])
                        (c "__ps_utf8_count" [bytes,add index width,o .i64Add [g "count",.i64 1]])
                        invalid]) invalid)])]) invalid)),
    -- Packing/unpacking changes only storage. Both sides are private buffers;
    -- existing source ByteArrays and String storage are never mutated.
    ← emit "pack_loop" [("source",valuesType),("output",bytesType),("index",.i32)] bytesType []
      (choice (some bytesType) (eq index (len source)) output
        (seq [o (.arraySet bytesName) [output,index,
            o (.structGet scalarBoxName 0) [o (.refCast scalarBoxName)
              [o (.arrayGet valuesName) [source,index]]]],
          c "__ps_utf8_pack_loop" [source,output,add index (k 1)]])),
    ← emit "pack" [("source",arrayType)] bytesType []
      (c "__ps_utf8_pack_loop" [values source,o (.arrayNewDefault bytesName) [len (values source)],k 0]),
    ← emit "unpack_loop" [("bytes",bytesType),("output",valuesType),("index",.i32)] arrayType []
      (choice (some arrayType) (eq index (len bytes)) (o (.structNew arrayName) [output])
        (seq [o (.arraySet valuesName) [output,index,o (.structNew scalarBoxName) [byte bytes index]],
          c "__ps_utf8_unpack_loop" [bytes,output,add index (k 1)]])),
    ← runtimeDefinition "__ps_string_to_utf8" [("text",stringType)] [arrayType] [("bytes",bytesType)]
      (seq [put "bytes" (o (.structGet stringName 0) [g "text"]),
        c "__ps_utf8_unpack_loop" [bytes,
          o (.arrayNew valuesName) [o (.structNew scalarBoxName) [k 0],len bytes],k 0]]),
    ← emit "valid" [("source",arrayType)] .i32 []
      (o .i64GeS [c "__ps_utf8_count" [c "__ps_utf8_pack" [source],k 0,.i64 0],.i64 0]),
    ← emit "decode" [("source",arrayType)] stringType [("bytes",bytesType),("count",.i64)]
      (seq [put "bytes" (c "__ps_utf8_pack" [source]),
        put "count" (c "__ps_utf8_count" [bytes,k 0,.i64 0]),
        choice (some stringType) (o .i64LtS [g "count",.i64 0])
          (c "__ps_string_empty" [])
          (o (.structNew stringName) [bytes,o (.word .i32WrapI64) [g "count"]])])]
end PsWasm
