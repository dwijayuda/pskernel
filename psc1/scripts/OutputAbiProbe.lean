import Ps.CompilerUnified.Service

private def demand (condition : Bool) (code : String) : IO Unit :=
  if condition then pure () else throw (IO.userError ("PSC1_OUTPUT_ABI_" ++ code))

-- Native reference transport only. The compiler is the existing unified service;
-- independent admission remains a separate required host operation.
def main (args : List String) : IO Unit := do
  let [target, input, output] := args
    | throw (IO.userError "PSC1_OUTPUT_ABI_USAGE")
  let bytes ← IO.FS.readBinFile input
  demand (bytes.size ≤ 33554432) "REQUEST_LIMIT"
  let some text := String.fromUTF8? bytes | throw (IO.userError "PSC1_OUTPUT_ABI_UTF8")
  let request : Except Ps.Internal.CompilerService.Error Ps.Internal.CompilerService.Request := do
    let value ← (psJsonParse text).mapError (fun _ =>
      Ps.Internal.CompilerService.failure "wire" "invalid-json")
    let fields ← Ps.Internal.CompilerService.readArray value
    let selected ← Ps.Internal.CompilerService.decodeOutputRequestFields fields
    pure selected.fst
  match request with
  | .error _ => pure ()
  | .ok selected =>
      demand (selected.sources.length ≤ 256 &&
        selected.sources.all (fun source => source.text.utf8ByteSize ≤ 1048576)) "SOURCE_LIMIT"
  let envelope := psJsonArray [
    psJsonQuote "psc1-unified-compiler-service/2", psJsonQuote target, text]
  let response := Ps.Internal.UnifiedCompilerService.candidate envelope
  demand (response.utf8ByteSize ≤ 33554432) "RESPONSE_LIMIT"
  IO.FS.writeFile output response
