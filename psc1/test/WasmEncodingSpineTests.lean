import WasmEncodingSpineReference

open Ps.Internal.WasmBinaryBytes

private theorem encoding_reverse_acc_eq (values acc : List alpha) :
    psListReverseAcc values acc = values.reverse ++ acc := by
  induction values generalizing acc with
  | nil => rfl
  | cons head tail ih =>
      simp [psListReverseAcc, ih, List.reverse_cons, List.append_assoc]

private theorem encoding_reverse_eq (values : List alpha) :
    psListReverse values = values.reverse := by
  simp [psListReverse, encoding_reverse_acc_eq]

private theorem encoding_append_eq (left right : List alpha) :
    psListAppend left right = left ++ right := by
  simp [psListAppend, encoding_reverse_acc_eq, encoding_reverse_eq]

private theorem encoding_flat_map_acc_eq
    (convert : alpha -> Except error (List beta)) (values : List alpha) (acc : List beta) :
    psListFlatMapExceptAcc convert values acc =
      match WasmEncodingSpineReference.psListFlatMapExcept convert values with
      | .error failure => .error failure
      | .ok mapped => .ok (acc.reverse ++ mapped) := by
  induction values generalizing acc with
  | nil =>
      simp [psListFlatMapExceptAcc, WasmEncodingSpineReference.psListFlatMapExcept,
        encoding_reverse_eq]
  | cons head tail ih =>
      simp only [psListFlatMapExceptAcc, WasmEncodingSpineReference.psListFlatMapExcept]
      cases result : convert head with
      | error failure => simp [result]
      | ok first =>
          simp only [result]
          rw [ih]
          cases rest : WasmEncodingSpineReference.psListFlatMapExcept convert tail with
          | error failure => simp [rest]
          | ok mapped =>
              simp [rest, encoding_reverse_acc_eq, encoding_append_eq,
                List.reverse_append, List.append_assoc]

theorem wasm_encoding_flat_map_eq
    (convert : alpha -> Except error (List beta)) (values : List alpha) :
    psListFlatMapExcept convert values =
      WasmEncodingSpineReference.psListFlatMapExcept convert values := by
  have h := encoding_flat_map_acc_eq convert values []
  cases result : WasmEncodingSpineReference.psListFlatMapExcept convert values with
  | error failure => simpa [psListFlatMapExcept, result] using h
  | ok mapped => simpa [psListFlatMapExcept, result] using h

private theorem encoding_chunks_acc_eq (chunks : List (List Nat)) (acc : List Nat) :
    psWasmEncodeByteChunksAcc chunks acc =
      acc.reverse ++ WasmEncodingSpineReference.psWasmEncodeByteChunks chunks := by
  induction chunks generalizing acc with
  | nil =>
      simp [psWasmEncodeByteChunksAcc, WasmEncodingSpineReference.psWasmEncodeByteChunks,
        encoding_reverse_eq]
  | cons chunk rest ih =>
      simp [psWasmEncodeByteChunksAcc, WasmEncodingSpineReference.psWasmEncodeByteChunks,
        ih, encoding_reverse_acc_eq, encoding_append_eq,
        List.reverse_append, List.append_assoc]

theorem wasm_encoding_chunks_eq (chunks : List (List Nat)) :
    psWasmEncodeByteChunks chunks =
      WasmEncodingSpineReference.psWasmEncodeByteChunks chunks := by
  simpa [psWasmEncodeByteChunks] using encoding_chunks_acc_eq chunks []

private theorem encoding_utf8_acc_eq (chars : List Char) (acc : List Nat) :
    psWasmEncodeUtf8CharsAcc chars acc =
      acc.reverse ++ WasmEncodingSpineReference.psWasmEncodeUtf8Chars chars := by
  induction chars generalizing acc with
  | nil =>
      simp [psWasmEncodeUtf8CharsAcc, WasmEncodingSpineReference.psWasmEncodeUtf8Chars,
        encoding_reverse_eq]
  | cons char rest ih =>
      simp [psWasmEncodeUtf8CharsAcc, WasmEncodingSpineReference.psWasmEncodeUtf8Chars,
        ih, encoding_reverse_acc_eq, encoding_append_eq,
        List.reverse_append, List.append_assoc]

theorem wasm_encoding_utf8_eq (chars : List Char) :
    psWasmEncodeUtf8Chars chars = WasmEncodingSpineReference.psWasmEncodeUtf8Chars chars := by
  simpa [psWasmEncodeUtf8Chars] using encoding_utf8_acc_eq chars []

#print axioms wasm_encoding_flat_map_eq
#print axioms wasm_encoding_chunks_eq
#print axioms wasm_encoding_utf8_eq

def runWasmEncodingSpineTests : IO Unit := do
  let values := List.range 100000
  let accept : Nat -> Except Nat (List Nat) :=
    fun n => .ok [n % 256, (n + 1) % 256]
  match psListFlatMapExcept accept values with
  | .error _ => throw (IO.userError "Wasm encoding flatten refused")
  | .ok bytes =>
      if bytes != values.flatMap (fun n => [n % 256, (n + 1) % 256]) then
        throw (IO.userError "Wasm encoding flatten order/bytes changed")
  let refuse : Nat -> Except Nat (List Nat) :=
    fun n => if n == 17 || n == 23 then .error n else .ok [n]
  match psListFlatMapExcept refuse values with
  | .error 17 => pure ()
  | _ => throw (IO.userError "Wasm encoding first-error priority changed")
  let chunks := values.map (fun n => [n, n + 1])
  if psWasmEncodeByteChunks chunks != chunks.flatMap id then
    throw (IO.userError "Wasm chunk order changed")
  let chars := List.replicate 100000 'λ'
  if psWasmEncodeUtf8Chars chars != (List.replicate 100000 [206,187]).flatMap id then
    throw (IO.userError "Wasm large UTF8 encoding changed")
  let boundaries := [0,127,128,2047,2048,55295,57344,65535,65536,1114111].map Char.ofNat
  if psWasmEncodeUtf8Chars boundaries != WasmEncodingSpineReference.psWasmEncodeUtf8Chars boundaries then
    throw (IO.userError "Wasm UTF8 scalar boundaries changed")
  IO.println "PSC1_WASM_ENCODING_SPINES: three all-input retained API equalities;100000-element flatten/chunks/UTF8; exact bytes/order/first-error"
