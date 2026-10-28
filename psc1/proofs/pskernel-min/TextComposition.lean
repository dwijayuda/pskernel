import CompilerPreservation
import Init.Data.String.Defs
import Init.Data.ByteArray.Bootstrap
import Init.Data.List.Lemmas

/- Constructive composition of the actual compiler join.
   No law for String.Internal externs or target-engine evaluation is assumed. -/
namespace Ps.MinKernel.TextComposition

open Ps.MinKernel.CompilerPreservation

def utf8 (text : String) : List UInt8 := text.toByteArray.data.toList

theorem append_utf8 (left right : String) :
    utf8 (String.append left right) = utf8 left ++ utf8 right := rfl

theorem empty_utf8 : utf8 "" = [] := rfl

-- The specification is an independent standard list intercalation of exact bytes.
theorem join_utf8 (separator : String) (values : List String) :
    utf8 (psTsJoin separator values) =
      List.intercalate (utf8 separator) (values.map utf8) := by
  induction values with
  | nil => rfl
  | cons value rest ih =>
      cases rest with
      | nil =>
          simp only [psTsJoin, List.map_cons, List.map_nil, List.intercalate_singleton]
      | cons next tail =>
          change utf8 (String.append value
            (String.append separator (psTsJoin separator (next :: tail)))) = _
          rw [append_utf8, append_utf8, ih]
          simp only [List.map_cons, List.intercalate_cons_cons, List.append_assoc]

theorem join_empty_utf8 (values : List String) :
    utf8 (psTsJoin "" values) = (values.map utf8).flatten := by
  induction values with
  | nil => rfl
  | cons value rest ih =>
      cases rest with
      | nil =>
          simp only [psTsJoin, List.map_cons, List.map_nil, List.flatten_cons,
            List.flatten_nil, List.append_nil]
      | cons next tail =>
          change utf8 (String.append value
            (String.append "" (psTsJoin "" (next :: tail)))) = _
          rw [append_utf8, append_utf8, empty_utf8]
          simpa only [List.nil_append, List.map_cons, List.flatten_cons] using
            congrArg (fun bytes => utf8 value ++ bytes) ih

theorem join_pair_utf8 (separator left right : String) :
    utf8 (psTsJoin separator [left, right]) =
      utf8 left ++ utf8 separator ++ utf8 right := by
  rw [join_utf8]
  simp only [List.map_cons, List.map_nil, List.intercalate_cons_cons,
    List.intercalate_singleton]

-- This composes arbitrary emitted fragment lists, including both empty cases.
theorem join_concat_empty_utf8 (left right : List String) :
    utf8 (psTsJoin "" (left ++ right)) =
      utf8 (psTsJoin "" left) ++ utf8 (psTsJoin "" right) := by
  rw [join_empty_utf8, join_empty_utf8, join_empty_utf8, List.map_append,
    List.flatten_append]

-- R5 establishes the exact selected emitter templates; R6 connects them to bytes.
theorem emit_binary_utf8 (op : Binary) (left right : String) :
    ∃ output,
      psTsEmitIntrinsicFromPrinted (irOperation op) [left, right] = .ok output ∧
      utf8 output = ((binaryTokens op left right).map utf8).flatten :=
  ⟨_, emit_binary_template op left right, join_empty_utf8 _⟩

theorem emit_add_bytes (left right : String) :
    ∃ output,
      psTsEmitIntrinsicFromPrinted .natAdd [left, right] = .ok output ∧
      utf8 output =
        utf8 "(" ++ utf8 left ++ utf8 " + " ++ utf8 right ++ utf8 ")" := by
  refine ⟨_, emit_binary_template .add left right, ?_⟩
  rw [join_empty_utf8]
  simp only [binaryTokens, List.map_cons, List.map_nil, List.flatten_cons,
    List.flatten_nil, List.append_nil, List.append_assoc]

theorem emit_and_bytes (left right : String) :
    ∃ output,
      psTsEmitIntrinsicFromPrinted .boolAnd [left, right] = .ok output ∧
      utf8 output =
        utf8 "(" ++ utf8 left ++ utf8 " && " ++ utf8 right ++ utf8 ")" := by
  refine ⟨_, emit_binary_template .and left right, ?_⟩
  rw [join_empty_utf8]
  simp only [binaryTokens, List.map_cons, List.map_nil, List.flatten_cons,
    List.flatten_nil, List.append_nil, List.append_assoc]

theorem emit_sub_bytes (left right : String) :
    ∃ output,
      psTsEmitIntrinsicFromPrinted .natSub [left, right] = .ok output ∧
      utf8 output =
        utf8 "((__ps_a: bigint, __ps_b: bigint) => " ++
        utf8 "(__ps_a >= __ps_b ? __ps_a - __ps_b : 0n))(" ++
        utf8 left ++ utf8 ", " ++ utf8 right ++ utf8 ")" := by
  refine ⟨_, emit_binary_template .sub left right, ?_⟩
  rw [join_empty_utf8]
  simp only [binaryTokens, List.map_cons, List.map_nil, List.flatten_cons,
    List.flatten_nil, List.append_nil, List.append_assoc]

end Ps.MinKernel.TextComposition
