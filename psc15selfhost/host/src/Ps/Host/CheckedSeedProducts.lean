import Ps.DriverJs.Compiler
import Ps.DriverWasm.Compiler
import Lean.Data.Json

-- Native host transport only. Commands describe products; acceptance authority
-- remains the parent host's live selected-provider decision for this session.
def psCheckedSeedProductsProtocol : String := "psc-checked-seed-products/1"

structure PsCheckedSeedProductsRequest where
  target : String
  representation : String
  metadata : Bool
  declarations : Bool
  sourceMap : Bool

def psCheckedSeedProductsDecode (text : String) : Except String PsCheckedSeedProductsRequest := do
  if text.utf8ByteSize > 4096 then throw "PSC2_CHECKED_SEED_PRODUCT_REQUEST_RESOURCE"
  let json ← Lean.Json.parse text
  let items ← json.getArr?
  if items.size != 6 then throw "PSC2_CHECKED_SEED_PRODUCT_REQUEST_SCHEMA"
  let tag ← items[0]!.getStr?
  let target ← items[1]!.getStr?
  let representation ← items[2]!.getStr?
  let metadata ← items[3]!.getBool?
  let declarations ← items[4]!.getBool?
  let sourceMap ← items[5]!.getBool?
  if tag != psCheckedSeedProductsProtocol then throw "PSC2_CHECKED_SEED_PRODUCT_REQUEST_SCHEMA"
  if target != "javascript" && target != "wasm" then throw "PSC2_CHECKED_SEED_PRODUCT_TARGET"
  if representation != "psc-js-closed-instances/1" && representation != "psc-js-uniform-values/1" then
    throw "PSC2_CHECKED_SEED_PRODUCT_REPRESENTATION"
  if target != "javascript" &&
      (representation != "psc-js-closed-instances/1" || declarations || sourceMap) then
    throw "PSC2_CHECKED_SEED_PRODUCT_TARGET"
  pure ⟨target, representation, metadata, declarations, sourceMap⟩

def psCheckedSeedProductsAssertPrepared
    (prepared : PsCompilerAdmissionReadyModule) (admissions : String) : IO Unit := do
  let .ok current := psCompilerAdmissionsFromPrepared prepared
    | throw (IO.userError "PSC2_CHECKED_PREPARED_INTEGRITY_FAILED")
  if current != admissions then throw (IO.userError "PSC2_CHECKED_PAYLOAD_CHANGED")

def psCheckedSeedProductsMetadata
    (request : PsCheckedSeedProductsRequest) (prepared : PsCompilerAdmissionReadyModule)
    (origins erasure : String) : IO (List (String × Lean.Json)) := do
  let metadata := request.metadata || request.sourceMap
  if !metadata && !request.declarations then return []
  let .ok api := psCompilerPublicApiFromPrepared prepared
    | throw (IO.userError "PSC2_CHECKED_PUBLIC_API_FAILED")
  let fields := [("publicApi", Lean.Json.str api), ("erasureCorrespondence", Lean.Json.str erasure)]
  pure (fields ++ if metadata then [("declarationOrigins", Lean.Json.str origins)] else [])

def psCheckedSeedProductsEmit
    (request : PsCheckedSeedProductsRequest) (prepared : PsCompilerAdmissionReadyModule)
    (origins : String) : IO (List (String × Lean.Json)) := do
  let common := [("phase", Lean.Json.str "emitted"),
    ("protocol", Lean.Json.str psCheckedSeedProductsProtocol),
    ("target", Lean.Json.str request.target), ("representation", Lean.Json.str request.representation)]
  let metadata := request.metadata || request.sourceMap
  if request.target == "javascript" then
    let (javaScript, runtimeIr, verifiedIr, selectedKey, selectedIr, jsIr, erasure, positions) ←
      if request.representation == "psc-js-uniform-values/1" then do
        let .ok output := psCompilerUniformJavaScriptStagesFromPrepared prepared
          | throw (IO.userError "PSC2_CHECKED_EMISSION_FAILED")
        pure (output.javaScript, output.runtimeIr, output.verifiedIr, "uniformSpecializedIr",
          output.uniformSpecializedIr, output.jsIr, output.erasureCorrespondence, output.generatedPositions)
      else do
        let .ok output := psCompilerJavaScriptStagesFromPrepared prepared
          | throw (IO.userError "PSC2_CHECKED_EMISSION_FAILED")
        pure (output.javaScript, output.runtimeIr, output.verifiedIr, "specializedIr",
          output.specializedIr, output.jsIr, output.erasureCorrespondence, output.generatedPositions)
    let products ← psCheckedSeedProductsMetadata request prepared origins erasure
    pure (common ++ [("javaScript", Lean.Json.str javaScript), ("runtimeIr", Lean.Json.str runtimeIr),
      ("verifiedIr", Lean.Json.str verifiedIr), (selectedKey, Lean.Json.str selectedIr),
      ("jsIr", Lean.Json.str jsIr)] ++ products ++
      if metadata then [("generatedPositions", Lean.Json.str positions)] else [])
  else
    let .ok output := psCompilerWasmStagesFromPrepared psCompilerWasm32Target prepared
      | throw (IO.userError "PSC2_CHECKED_EMISSION_FAILED")
    let products ← psCheckedSeedProductsMetadata request prepared origins output.erasureCorrespondence
    pure (common ++ [("wasm", Lean.Json.arr (output.wasm.toArray.map fun byte => Lean.toJson byte.toNat)),
      ("runtimeIr", Lean.Json.str output.runtimeIr), ("verifiedIr", Lean.Json.str output.verifiedIr),
      ("specializedIr", Lean.Json.str output.specializedIr), ("wasmIr", Lean.Json.str output.wasmIr)] ++ products)

def psCheckedSeedProductsReadLine : IO String := do
  let line ← (← IO.getStdin).getLine
  if !line.endsWith "\n" then throw (IO.userError "PSC2_CHECKED_SEED_PRODUCT_COMMAND_EOF")
  -- Remove framing only. Whitespace in a declaration request remains visible
  -- to the portable canonical-request decoder.
  pure (line.dropEnd 1).toString

def psCheckedSeedProductsSession
    (prepared : PsCompilerAdmissionReadyModule) (origins : String) : IO Unit := do
  let .ok admissions := psCompilerAdmissionsFromPrepared prepared
    | throw (IO.userError "PSC2_CHECKED_PREPARED_INTEGRITY_FAILED")
  let stdout ← IO.getStdout
  stdout.putStrLn (Lean.Json.mkObj [("phase", Lean.Json.str "prepared"),
    ("protocol", Lean.Json.str psCheckedSeedProductsProtocol), ("admissions", Lean.Json.str admissions)]).compress
  stdout.flush
  let command ← psCheckedSeedProductsReadLine
  if command == "checked" then
    stdout.putStrLn (Lean.Json.mkObj [("phase", Lean.Json.str "checked"),
      ("protocol", Lean.Json.str psCheckedSeedProductsProtocol)]).compress
    stdout.flush
    return
  let .ok request := psCheckedSeedProductsDecode command
    | throw (IO.userError "PSC2_CHECKED_SEED_PRODUCT_REQUEST")
  psCheckedSeedProductsAssertPrepared prepared admissions
  let fields ← psCheckedSeedProductsEmit request prepared origins
  psCheckedSeedProductsAssertPrepared prepared admissions
  stdout.putStrLn (Lean.Json.mkObj fields).compress
  stdout.flush
  if request.declarations then
    -- The host derives exact bindings from the emitted source/runtime/export
    -- inventory. The same live prepared source supplies portable declarations.
    let wire ← psCheckedSeedProductsReadLine
    let .ok declarationRequest := psTsDecodeDeclarationCommand wire
      | throw (IO.userError "PSC2_CHECKED_SEED_DECLARATION_REQUEST")
    let expectedProfile := if request.representation == "psc-js-uniform-values/1" then
      "psc-direct-js-declarations-uniform-structural/1" else "psc-direct-js-declarations-closed-structural/1"
    if psTsEncodeDeclarationProfile declarationRequest.profile != expectedProfile then
      throw (IO.userError "PSC2_CHECKED_SEED_DECLARATION_PROFILE")
    psCheckedSeedProductsAssertPrepared prepared admissions
    let .ok declarations := psCompilerJavaScriptDeclarationsFromPrepared wire prepared
      | throw (IO.userError "PSC2_CHECKED_SEED_DECLARATION_FAILED")
    psCheckedSeedProductsAssertPrepared prepared admissions
    stdout.putStrLn (Lean.Json.mkObj [("phase", Lean.Json.str "declarations"),
      ("protocol", Lean.Json.str psCheckedSeedProductsProtocol),
      ("declarations", Lean.Json.str declarations)]).compress
    stdout.flush
