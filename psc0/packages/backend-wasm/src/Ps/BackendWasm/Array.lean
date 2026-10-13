import Ps.BackendWasm.String

namespace PsWasm

private def g := RuntimeCode.get
private def k := RuntimeCode.i32
private def o := RuntimeCode.op
private def c := RuntimeCode.call
private def put := RuntimeCode.set
private def seq := RuntimeCode.seq
private def choice := RuntimeCode.ite
private def add (a b : R) := o .i32Add [a, b]
private def eq (a b : R) := o .i32Eq [a, b]
private def len (a : R) := o .arrayLen [a]
private def values (a : R) := o (.structGet arrayName 0) [a]
private def read (a index : R) := o (.arrayGet valuesName) [a, index]
private def write (a index value : R) := o (.arraySet valuesName) [a, index, value]
private def allocate (size : R) := o (.arrayNew valuesName) [o (.structNew scalarBoxName) [k 0], size]
private def array (a : R) := o (.structNew arrayName) [a]
private def nat (n : R) := c "__ps_nat_from_u32" [n]
private def narrow (n : R) := c "__ps_nat_to_u32" [n]

def invokeClosure (fn : R) (args : List R) : R :=
  .op (.callRef (closureCodeName args.length))
    (fn :: args ++ [.op (.refCastFunction (closureCodeName args.length))
      [.op (.structGet closureName 0) [fn]]])

-- Source arrays are persistent. Mutation is confined to unpublished copies.
-- Generic elements use the same Value convention as closure arguments.
def arrayRuntime : Except String (List RuntimeDefinition) := do
  let emit := fun suffix params result locals body =>
    runtimeDefinition ("__ps_array_" ++ suffix) params [result] locals body
  let a := g "a"
  let index := g "index"
  let output := g "output"
  let size := g "size"
  let fn := g "fn"
  return [
    ← emit "build_loop" [("head", closureType), ("tail", closureType), ("state", valueType),
        ("output", valuesType), ("index", .i32)] arrayType []
      (choice (some arrayType) (eq index (len output)) (array output)
        (seq [write output index (invokeClosure (g "head") [g "state"]),
          c "__ps_array_build_loop" [g "head", g "tail",
            invokeClosure (g "tail") [g "state"], output, add index (k 1)]])),
    ← emit "build" [("count", naturalType), ("state", valueType),
        ("head", closureType), ("tail", closureType)] arrayType []
      (c "__ps_array_build_loop" [g "head", g "tail", g "state",
        allocate (narrow (g "count")), k 0]),
    ← emit "empty" [("capacity", naturalType)] arrayType []
      (array (o (.arrayNewFixed valuesName 0) [])),
    ← emit "size" [("a", arrayType)] naturalType [] (nat (len (values a))),
    ← emit "copy" [("a", valuesType), ("size", .i32)] valuesType [("output", valuesType)]
      (seq [put "output" (allocate size),
        o (.arrayCopy valuesName valuesName) [output, k 0, a, k 0, len a], output]),
    ← emit "push" [("a", arrayType), ("value", valueType)] arrayType [("output", valuesType)]
      (seq [put "output" (c "__ps_array_copy" [values a, c "__ps_checked_size" [len (values a), k 1]]),
        write output (len (values a)) (g "value"), array output]),
    ← emit "in_bounds" [("a", arrayType), ("index", naturalType)] .i32 []
      (c "__ps_nat_lt" [index, nat (len (values a))]),
    ← emit "get" [("a", arrayType), ("index", naturalType)] valueType []
      (choice (some valueType) (c "__ps_array_in_bounds" [a, index])
        (read (values a) (narrow index)) (o .unreachable [])),
    ← emit "get_default" [("a", arrayType), ("index", naturalType), ("fallback", valueType)] valueType []
      (choice (some valueType) (c "__ps_array_in_bounds" [a, index])
        (read (values a) (narrow index)) (g "fallback")),
    ← emit "replace" [("a", arrayType), ("index", .i32), ("value", valueType)] arrayType [("output", valuesType)]
      (seq [put "output" (c "__ps_array_copy" [values a, len (values a)]),
        write output index (g "value"), array output]),
    ← emit "set" [("a", arrayType), ("index", naturalType), ("value", valueType)] arrayType []
      (choice (some arrayType) (c "__ps_array_in_bounds" [a, index])
        (c "__ps_array_replace" [a, narrow index, g "value"]) (o .unreachable [])),
    ← emit "set_if_in_bounds" [("a", arrayType), ("index", naturalType), ("value", valueType)] arrayType []
      (choice (some arrayType) (c "__ps_array_in_bounds" [a, index])
        (c "__ps_array_replace" [a, narrow index, g "value"]) a),
    ← emit "map_loop" [("fn", closureType), ("a", valuesType), ("output", valuesType), ("index", .i32)] arrayType []
      (choice (some arrayType) (eq index (len a)) (array output)
        (seq [write output index (invokeClosure fn [read a index]),
          c "__ps_array_map_loop" [fn, a, output, add index (k 1)]])),
    ← emit "map" [("fn", closureType), ("a", arrayType)] arrayType []
      (c "__ps_array_map_loop" [fn, values a, allocate (len (values a)), k 0]),
    ← emit "fold_loop" [("fn", closureType), ("value", valueType), ("a", valuesType),
        ("index", .i32), ("size", .i32)] valueType []
      (choice (some valueType) (o .i32GeU [index, size]) (g "value")
        (c "__ps_array_fold_loop" [fn, invokeClosure fn [g "value", read a index],
          a, add index (k 1), size])),
    ← emit "clamp" [("index", naturalType), ("size", .i32)] .i32 []
      (choice (some .i32) (c "__ps_nat_lt" [index, nat size]) (narrow index) size),
    ← emit "fold" [("fn", closureType), ("value", valueType), ("a", arrayType),
        ("start", naturalType), ("stop", naturalType)] valueType []
      (c "__ps_array_fold_loop" [fn, g "value", values a,
        c "__ps_array_clamp" [g "start", len (values a)],
        c "__ps_array_clamp" [g "stop", len (values a)]])]
end PsWasm
