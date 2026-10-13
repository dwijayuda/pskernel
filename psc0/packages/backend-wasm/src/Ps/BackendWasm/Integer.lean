import Ps.BackendWasm.Natural

namespace PsWasm

private def g := RuntimeCode.get
private def k := RuntimeCode.i32
private def o := RuntimeCode.op
private def c := RuntimeCode.call
private def choice := RuntimeCode.ite
private def sign (value : R) := o (.structGet integerName 0) [value]
private def magnitude (value : R) := o (.structGet integerName 1) [value]
private def make (s n : R) := c "__ps_int_make" [s, n]

def integerRuntime : Except String (List RuntimeDefinition) := do
  let emit := fun suffix params result locals body =>
    runtimeDefinition ("__ps_int_" ++ suffix) params [result] locals body
  let a := g "left"
  let b := g "right"
  let mut functions := [
    ← emit "make" [("sign", .i32), ("magnitude", naturalType)] integerType []
      (o (.structNew integerName) [
        choice (some .i32) (c "__ps_nat_is_zero" [g "magnitude"]) (k 0) (g "sign"), g "magnitude"]),
    ← emit "to_nat" [("value", integerType)] naturalType []
      (choice (some naturalType) (o .i32LtS [sign (g "value"), k 0])
        (c "__ps_nat_from_u32" [k 0]) (magnitude (g "value"))),
    ← emit "of_nat" [("value", naturalType)] integerType [] (make (k 1) (g "value")),
    ← emit "neg_succ" [("value", naturalType)] integerType []
      (make (k (-1)) (c "__ps_nat_add" [g "value", c "__ps_nat_from_u32" [k 1]])),
    ← emit "neg" [("value", integerType)] integerType []
      (o (.structNew integerName) [o .i32Sub [k 0, sign (g "value")], magnitude (g "value")]),
    ← emit "compare" [("left", integerType), ("right", integerType)] .i32 []
      (choice (some .i32) (o .i32Eq [sign a, sign b])
        (o .i32Mul [sign a, c "__ps_nat_compare" [magnitude a, magnitude b]])
        (choice (some .i32) (o .i32LtS [sign a, sign b]) (k (-1)) (k 1))),
    ← emit "add" [("left", integerType), ("right", integerType)] integerType []
      (choice (some integerType) (o .i32Eq [sign a, k 0]) b
        (choice (some integerType) (o .i32Eq [sign b, k 0]) a
          (choice (some integerType) (o .i32Eq [sign a, sign b])
            (make (sign a) (c "__ps_nat_add" [magnitude a, magnitude b]))
            (choice (some integerType)
              (o .i32LtS [c "__ps_nat_compare" [magnitude a, magnitude b], k 0])
              (make (sign b) (c "__ps_nat_sub" [magnitude b, magnitude a]))
              (make (sign a) (c "__ps_nat_sub" [magnitude a, magnitude b])))))),
    ← emit "sub" [("left", integerType), ("right", integerType)] integerType []
      (c "__ps_int_add" [a, c "__ps_int_neg" [b]]),
    ← emit "mul" [("left", integerType), ("right", integerType)] integerType []
      (make (o .i32Mul [sign a, sign b]) (c "__ps_nat_mul" [magnitude a, magnitude b]))]
  for (suffix, instruction) in [
      ("eq", PsWasmInstruction.i32Eq), ("lt", .i32LtS), ("le", .i32LeS)] do
    functions := functions ++ [← emit suffix [("left", integerType), ("right", integerType)] .i32 []
      (o instruction [c "__ps_int_compare" [a, b], k 0])]
  return functions

def integerLiteral (value : Int) : List PsWasmInstruction :=
  [.i32Const (if value == 0 then 0 else if value < 0 then -1 else 1)] ++
    naturalLiteral value.natAbs ++ [.structNew integerName]

end PsWasm
