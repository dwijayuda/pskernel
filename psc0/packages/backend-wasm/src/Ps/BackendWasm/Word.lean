import Ps.BackendWasm.LowerInt
import Ps.BackendWasm.RuntimeBuilder

namespace PsWasm

-- Lean 4.35.0 include/lean/lean.h: total division/remainder, including zero
-- and signed minimum / -1. Guards surround the trapping Wasm instructions.
-- These pure scalar helpers allocate neither GC data nor linear memory.
def wordDivisionRuntime (wide signed remainder : Bool) :
    Except String RuntimeDefinition := do
  let type := if wide then PsWasmValueType.i64 else .i32
  let constant := if wide then RuntimeCode.i64 else RuntimeCode.i32
  let lhs := RuntimeCode.get "dividend"
  let rhs := RuntimeCode.get "divisor"
  let equal := fun a b => RuntimeCode.op (if wide then .i64Eq else .i32Eq) [a, b]
  let operation : PsWasmWordOp :=
    if wide then
      if signed then (if remainder then .i64RemS else .i64DivS)
      else (if remainder then .i64RemU else .i64DivU)
    else
      if signed then (if remainder then .i32RemS else .i32DivS)
      else (if remainder then .i32RemU else .i32DivU)
  let arithmetic := RuntimeCode.op (.word operation) [lhs, rhs]
  let arithmetic := if signed then
    RuntimeCode.ite (some type)
      (.op .i32And [equal lhs (constant (if wide then -9223372036854775808 else -2147483648)),
        equal rhs (constant (-1))])
      (if remainder then constant 0 else lhs) arithmetic
    else arithmetic
  runtimeDefinition (psWasmWordDivisionName wide signed remainder)
    [("dividend", type), ("divisor", type)] [type] []
    (.ite (some type) (equal rhs (constant 0))
      (if remainder then lhs else constant 0) arithmetic)

def wordRuntime : Except String (List RuntimeDefinition) := do
  let variants := [false, true].flatMap fun wide =>
    [false, true].flatMap fun signed =>
      [false, true].map fun remainder => (wide, signed, remainder)
  variants.mapM fun (wide, signed, remainder) => wordDivisionRuntime wide signed remainder

end PsWasm
