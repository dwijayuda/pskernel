import Ps.DriverJs.Compiler
import Ps.DriverWasm.Compiler
import Ps.DriverRust.Compiler
import Lean.Data.Json

-- Native host transport only. Commands describe products; acceptance authority
-- remains the parent host's live selected-provider decision for this session.
def psCheckedSeedProductsProtocol : String := "psc-checked-seed-products/1"
def psCheckedSeedCanonicalProtocol : String := "psc-checked-seed-products/2"
def psCheckedSeedRustProtocol : String := "psc-checked-seed-products/3"

structure PsCheckedSeedProductsRequest where
  target : String
  representation : String
  metadata : Bool
  declarations : Bool
  sourceMap : Bool
  canonicalRequest : Option String := none

-- Shared six-field shape; each public version separately pins its capability.
def psCheckedSeedProductsTuple (protocol text : String) : Except String PsCheckedSeedProductsRequest := do
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
  if tag != protocol then throw "PSC2_CHECKED_SEED_PRODUCT_REQUEST_SCHEMA"
  pure ⟨target, representation, metadata, declarations, sourceMap, none⟩

def psCheckedSeedProductsDecode (text : String) : Except String PsCheckedSeedProductsRequest := do
  let request ← psCheckedSeedProductsTuple psCheckedSeedProductsProtocol text
  if request.target != "javascript" && request.target != "wasm" then throw "PSC2_CHECKED_SEED_PRODUCT_TARGET"
  if request.representation != "psc-js-closed-instances/1" && request.representation != "psc-js-uniform-values/1" then
    throw "PSC2_CHECKED_SEED_PRODUCT_REPRESENTATION"
  if request.target != "javascript" &&
      (request.representation != "psc-js-closed-instances/1" || request.declarations || request.sourceMap) then
    throw "PSC2_CHECKED_SEED_PRODUCT_TARGET"
  pure request

def psCheckedSeedRustDecode (text : String) : Except String PsCheckedSeedProductsRequest := do
  let request ← psCheckedSeedProductsTuple psCheckedSeedRustProtocol text
  if request.target != "rust" || request.representation != "psc-rust-source/2021" ||
      request.declarations || request.sourceMap then throw "PSC2_CHECKED_SEED_RUST_SELECTION"
  pure request

def psCheckedSeedProductsProtocolFor (request : PsCheckedSeedProductsRequest) : String :=
  if request.target == "rust" then psCheckedSeedRustProtocol
  else if request.canonicalRequest.isSome then psCheckedSeedCanonicalProtocol
  else psCheckedSeedProductsProtocol

-- Version 2 is explicit Canonical Wasm selection. Version 1 stays exact.
def psCheckedSeedCanonicalDecode (text : String) : Except String PsCheckedSeedProductsRequest := do
  if text.utf8ByteSize > 2101248 then throw "PSC2_CHECKED_SEED_PRODUCT_REQUEST_RESOURCE"
  let json ← Lean.Json.parse text
  let items ← json.getArr?
  if items.size != 7 then throw "PSC2_CHECKED_SEED_PRODUCT_REQUEST_SCHEMA"
  let tag ← items[0]!.getStr?
  let target ← items[1]!.getStr?
  let representation ← items[2]!.getStr?
  let metadata ← items[3]!.getBool?
  let declarations ← items[4]!.getBool?
  let sourceMap ← items[5]!.getBool?
  let wire ← items[6]!.getStr?
  if tag != psCheckedSeedCanonicalProtocol || target != "wasm" ||
      representation != "psc-js-closed-instances/1" || declarations || sourceMap then
    throw "PSC2_CHECKED_SEED_CANONICAL_SELECTION"
  let .ok _ := psWasmCanonicalDecodeRequest wire
    | throw "PSC2_CHECKED_SEED_CANONICAL_REQUEST"
  pure ⟨target, representation, metadata, false, false, some wire⟩

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
    ("protocol", Lean.Json.str (psCheckedSeedProductsProtocolFor request)),
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
  else if request.target == "rust" then
    let .ok output := psCompilerRustStagesFromPrepared prepared
      | throw (IO.userError "PSC2_CHECKED_RUST_EMISSION_FAILED")
    let products ← psCheckedSeedProductsMetadata request prepared origins output.erasureCorrespondence
    pure (common ++ [("rustSource", Lean.Json.str output.rustSource), ("runtimeIr", Lean.Json.str output.runtimeIr),
      ("verifiedIr", Lean.Json.str output.verifiedIr)] ++ products)
  else
    let (wasm, runtimeIr, verifiedIr, specializedIr, wasmIr, erasure, interfaceProducts) ←
      match request.canonicalRequest with
      | some wire => do
          let .ok output := psCompilerWasmCanonicalStagesFromPrepared wire prepared
            | throw (IO.userError "PSC2_CHECKED_CANONICAL_EMISSION_FAILED")
          pure (output.wasm, output.runtimeIr, output.verifiedIr, output.specializedIr, output.wasmIr,
            output.erasureCorrespondence,
            [("interfaceJson", Lean.Json.str output.interfaceJson), ("bindingJson", Lean.Json.str output.bindingJson)])
      | none => do
          let .ok output := psCompilerWasmStagesFromPrepared psCompilerWasm32Target prepared
            | throw (IO.userError "PSC2_CHECKED_EMISSION_FAILED")
          pure (output.wasm, output.runtimeIr, output.verifiedIr, output.specializedIr, output.wasmIr,
            output.erasureCorrespondence, [])
    let products ← psCheckedSeedProductsMetadata request prepared origins erasure
    pure (common ++ [("wasm", Lean.Json.arr (wasm.toArray.map fun byte => Lean.toJson byte.toNat)),
      ("runtimeIr", Lean.Json.str runtimeIr), ("verifiedIr", Lean.Json.str verifiedIr),
      ("specializedIr", Lean.Json.str specializedIr), ("wasmIr", Lean.Json.str wasmIr)] ++ products ++ interfaceProducts)

def psCheckedSeedProductsReadLine : IO String := do
  let line ← (← IO.getStdin).getLine
  if !line.endsWith "\n" then throw (IO.userError "PSC2_CHECKED_SEED_PRODUCT_COMMAND_EOF")
  -- Remove framing only. Whitespace in a declaration request remains visible
  -- to the portable canonical-request decoder.
  pure (line.dropEnd 1).toString

def psCheckedSeedProductsSession
    (prepared : PsCompilerAdmissionReadyModule) (origins : String) (protocol : String := psCheckedSeedProductsProtocol) : IO Unit := do
  if protocol != psCheckedSeedProductsProtocol && protocol != psCheckedSeedCanonicalProtocol &&
      protocol != psCheckedSeedRustProtocol then throw (IO.userError "PSC2_CHECKED_SEED_PRODUCT_PROTOCOL")
  let .ok admissions := psCompilerAdmissionsFromPrepared prepared
    | throw (IO.userError "PSC2_CHECKED_PREPARED_INTEGRITY_FAILED")
  let stdout ← IO.getStdout
  stdout.putStrLn (Lean.Json.mkObj [("phase", Lean.Json.str "prepared"),
    ("protocol", Lean.Json.str protocol), ("admissions", Lean.Json.str admissions)]).compress
  stdout.flush
  let command ← psCheckedSeedProductsReadLine
  if command == "checked" then
    stdout.putStrLn (Lean.Json.mkObj [("phase", Lean.Json.str "checked"),
      ("protocol", Lean.Json.str protocol)]).compress
    stdout.flush
    return
  let decoded := if protocol == psCheckedSeedRustProtocol then psCheckedSeedRustDecode command
    else if protocol == psCheckedSeedCanonicalProtocol then psCheckedSeedCanonicalDecode command
    else psCheckedSeedProductsDecode command
  let .ok request := decoded
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
      ("protocol", Lean.Json.str protocol),
      ("declarations", Lean.Json.str declarations)]).compress
    stdout.flush
