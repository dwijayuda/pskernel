import Ps.BackendWasm.BinaryBytes

namespace WasmEncodingSpineReference
open Ps.Internal.WasmBinaryBytes

def psListFlatMapExcept {α β ε : Type}
    (convert : α -> Except ε (List β)) (values : List α) : Except ε (List β) :=
  match values with
  | List.nil => Except.ok []
  | List.cons value rest =>
      match convert value with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psListFlatMapExcept convert rest with
          | Except.error error => Except.error error
          | Except.ok other => Except.ok (psListAppend first other)

def psWasmEncodeByteChunks (chunks : List (List Nat)) : List Nat :=
  match chunks with
  | List.nil => []
  | List.cons chunk rest => psListAppend chunk (psWasmEncodeByteChunks rest)

def psWasmEncodeUtf8Chars
    (chars : List Char) :
    List Nat :=
  match chars with
  | List.nil => []
  | List.cons char rest =>
      psListAppend
        (psWasmEncodeUtf8Char char)
        (psWasmEncodeUtf8Chars rest)

end WasmEncodingSpineReference
