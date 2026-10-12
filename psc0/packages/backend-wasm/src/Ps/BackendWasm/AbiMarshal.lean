import Ps.BackendWasm.AbiRuntime

namespace PsWasm

private def g := RuntimeCode.get
private def k (n : Nat) := RuntimeCode.i32 (Int.ofNat n)
private def o := RuntimeCode.op
private def c := RuntimeCode.call
private def put := RuntimeCode.set
private def seq := RuntimeCode.seq
private def choice := RuntimeCode.ite
private def add (a b : R) := o .i32Add [a, b]
private def eq (a b : R) := o .i32Eq [a, b]
private def offset (pointer : R) (n : Nat) := if n == 0 then pointer else add pointer (k n)
private def load (pointer : R) := o (.memory .load32) [pointer]
private def store (pointer value : R) := o (.memory .store32) [pointer, value]
private def trap : R := o .unreachable []

def abiHelper (direction : String) (node : AbiNode) := "__ps_abi_" ++ direction ++ "_" ++ psCodegenBaseName node.name

def abiRepresentation (node : AbiNode) : Except String PsWasmValueType :=
  match node.shape with
  | .limbs => pure limbsType
  | .payload _ => throw "PSCV0-ABI-PLAN: payload is a layout, not a standalone language value"
  | _ => representation node.type

def abiConvert (value : R) (actual expected : PsVerifiedIrType) : Except String R := do
  return (← convert actual expected).foldl (fun value instruction => .op instruction [value]) value

def abiBox (value : R) (type : PsVerifiedIrType) : Except String R := do
  return (← box type).foldl (fun value instruction => .op instruction [value]) value

def abiUnbox (value : R) (type : PsVerifiedIrType) : Except String R := do
  return (← unbox type).foldl (fun value instruction => .op instruction [value]) value

def abiRead (plan : AbiPlan) (id : Nat) (pointer : R) : Except String R := do
  return c (abiHelper "load" (← abiNode plan id)) [pointer]

def abiWrite (plan : AbiPlan) (id : Nat) (pointer value : R) : Except String R := do
  return c (abiHelper "store" (← abiNode plan id)) [pointer, value]

def abiReadFields (plan : AbiPlan) (pointer : R) (fields : List AbiField) : Except String (List R) :=
  fields.mapM fun field => do
    let child ← abiNode plan field.node
    abiConvert (← abiRead plan field.node (offset pointer field.offset)) child.type field.formal

def abiWriteFields (plan : AbiPlan) (pointer value : R) (runtimeName : String)
    (fields : List AbiField) (baseIndex : Nat := 0) : Except String R := do
  let fields ← fields.mapM fun field => do
    let child ← abiNode plan field.node
    let value ← abiConvert (o (.structGet runtimeName (field.index + baseIndex)) [value]) field.formal child.type
    abiWrite plan field.node (offset pointer field.offset) value
  return seq fields

-- One load/store pair per concrete boundary type. The node's layout is shared
-- with WIT flattening and component type emission.
def abiMarshalNode (plan : AbiPlan) (node : AbiNode) : Except String (List RuntimeDefinition) := do
  if let .payload _ := node.shape then return []
  let type ← abiRepresentation node
  let loadName := abiHelper "load" node
  let storeName := abiHelper "store" node
  let pointer := g "pointer"
  let value := g "value"
  let index := g "index"
  let count := g "count"
  let buffer := g "buffer"
  let data := g "data"
  let check := c "__ps_abi_check_range" [pointer, k node.size, k node.alignment]
  let mut loadLocals : List (String × PsWasmValueType) := []
  let mut storeLocals : List (String × PsWasmValueType) := []
  let mut extras : List RuntimeDefinition := []
  let (readBody, writeBody) ← match node.shape with
    | .scalar scalar => do
      let memoryOp := if scalar == .bool then PsWasmMemoryOp.load8 else .load32
      let storeOp := if scalar == .bool then PsWasmMemoryOp.store8 else .store32
      let validate := fun value => match scalar with
        | .bool => c "__ps_abi_check_bool" [value]
        | .char => c "__ps_abi_check_char" [value]
        | .word => value
      pure (validate (o (.memory memoryOp) [pointer]), o (.memory storeOp) [pointer, validate value])
    | .string => do
      loadLocals := [("buffer", bytesType), ("count", .i32), ("data", .i32)]
      storeLocals := [("buffer", bytesType), ("data", .i32)]
      pure (
        seq [put "data" (load pointer), put "count" (load (offset pointer 4)),
          c "__ps_abi_check_range" [data, count, k 1],
          put "buffer" (c "__ps_abi_read_bytes" [data, o (.arrayNewDefault bytesName) [count], k 0]),
          o (.structNew stringName) [buffer, c "__ps_abi_utf8_count" [buffer, k 0, k 0]]],
        seq [put "buffer" (o (.structGet stringName 0) [value]),
          put "data" (abiAllocate (o .arrayLen [buffer]) (k 1)),
          c "__ps_abi_write_bytes" [data, buffer, k 0],
          store pointer data, store (offset pointer 4) (o .arrayLen [buffer])])
    | .natural limbs => do
      loadLocals := [("limbs", limbsType)]
      pure (
        seq [put "limbs" (← abiRead plan limbs pointer),
          c "__ps_nat_trim" [g "limbs", o .arrayLen [g "limbs"]]],
        ← abiWrite plan limbs pointer (o (.structGet naturalName 0) [value]))
    | .integer negative magnitude => do
      pure (c "__ps_int_make" [
          choice (some .i32) (← abiRead plan negative pointer) (.i32 (-1)) (k 1),
          ← abiRead plan magnitude (offset pointer 4)],
        seq [← abiWrite plan negative pointer (o .i32LtS [o (.structGet integerName 0) [value], k 0]),
          ← abiWrite plan magnitude (offset pointer 4) (o (.structGet integerName 1) [value])])
    | .record runtimeName fields => do
      pure (o (.structNew runtimeName) (← abiReadFields plan pointer fields),
        ← abiWriteFields plan pointer value runtimeName fields)
    | .variant runtimeName cases payloadOffset tagSize => do
      loadLocals := [("tag", .i32)]
      let loadOp := if tagSize == 1 then PsWasmMemoryOp.load8 else if tagSize == 2 then .load16 else .load32
      let storeOp := if tagSize == 1 then PsWasmMemoryOp.store8 else if tagSize == 2 then .store16 else .store32
      let reads ← cases.mapM fun alternative => do
        return (alternative.tag, o (.structNew alternative.constructor)
          (k alternative.tag :: (← abiReadFields plan (offset pointer payloadOffset) alternative.fields)))
      let writes ← cases.mapM fun alternative => do
        return (alternative.tag, ← abiWriteFields plan (offset pointer payloadOffset)
          (o (.refCast alternative.constructor) [value]) alternative.constructor alternative.fields 1)
      pure (
        seq [put "tag" (o (.memory loadOp) [pointer]),
          reads.foldr (fun (tag, body) rest => choice (some type) (eq (g "tag") (k tag)) body rest) trap],
        seq [o (.memory storeOp) [pointer, o (.structGet runtimeName 0) [value]],
          writes.foldr (fun (tag, body) rest =>
            choice none (eq (o (.structGet runtimeName 0) [value]) (k tag)) body rest) trap])
    | .limbs | .list _ => do
      let element ← match node.shape with
        | .list id => (abiNode plan id).map some
        | _ => pure none
      let stride := (element.map (·.size)).getD 4
      let alignment := (element.map (·.alignment)).getD 4
      let storageName := if element.isSome then valuesName else limbsName
      let storageType := if element.isSome then valuesType else limbsType
      let readLoop := abiHelper "read_elements" node
      let writeLoop := abiHelper "write_elements" node
      let location := add data (o .i32Mul [index, k stride])
      let readValue ← match element with
        | none => pure (load location)
        | some child => abiBox (c (abiHelper "load" child) [location]) child.type
      let writeValue ← match element with
        | none => pure (store location (o (.arrayGet limbsName) [buffer, index]))
        | some child => do
          let value ← abiUnbox (o (.arrayGet valuesName) [buffer, index]) child.type
          pure (c (abiHelper "store" child) [location, value])
      extras := [
        ← runtimeDefinition readLoop [("data", .i32), ("buffer", storageType), ("index", .i32)] [storageType] []
          (choice (some storageType) (eq index (o .arrayLen [buffer])) buffer
            (seq [o (.arraySet storageName) [buffer, index, readValue],
              c readLoop [data, buffer, add index (k 1)]])),
        ← runtimeDefinition writeLoop [("data", .i32), ("buffer", storageType), ("index", .i32)] [] []
          (choice none (eq index (o .arrayLen [buffer])) (seq [])
            (seq [writeValue, c writeLoop [data, buffer, add index (k 1)]]))]
      loadLocals := [("data", .i32), ("count", .i32), ("buffer", storageType)]
      storeLocals := [("data", .i32), ("count", .i32), ("buffer", storageType)]
      let allocate := if element.isSome then
        o (.arrayNew valuesName) [o (.structNew scalarBoxName) [k 0], count]
        else o (.arrayNewDefault limbsName) [count]
      let result := if element.isSome then o (.structNew PsWasm.arrayName) [buffer] else buffer
      let getArray := if element.isSome then o (.structGet PsWasm.arrayName 0) [value] else value
      pure (
        seq [put "data" (load pointer), put "count" (load (offset pointer 4)),
          if element.isSome then seq [] else
            choice none (o .i32GtU [count, k 134217727]) trap (seq []),
          c "__ps_abi_check_range" [data, c "__ps_abi_checked_product" [count, k stride], k alignment],
          put "buffer" (c readLoop [data, allocate, k 0]), result],
        seq [put "buffer" getArray, put "count" (o .arrayLen [buffer]),
          put "data" (abiAllocate (c "__ps_abi_checked_product" [count, k stride]) (k alignment)),
          c writeLoop [data, buffer, k 0], store pointer data, store (offset pointer 4) count])
    | .payload _ => throw "PSCV0-ABI-PLAN: unexpected standalone payload"
  return extras ++ [
    ← runtimeDefinition loadName [("pointer", .i32)] [type] loadLocals (seq [check, readBody]),
    ← runtimeDefinition storeName [("pointer", .i32), ("value", type)] [] storeLocals (seq [check, writeBody])]

-- Flat inputs are stored into a temporary canonical record, then use the same
-- checked decoder as indirect inputs. This avoids two independent GC decoders.
def abiStoreFlat (plan : AbiPlan) : Nat → Nat → R → List R → Except String R
  | 0, _, _, _ => throw "PSCV0-ABI-RESOURCE: flattening traversal exhausted"
  | fuel + 1, id, pointer, values => do
    let node ← abiNode plan id
    if values.length != node.flat then throw "PSCV0-ABI-PLAN: flat input arity"
    let slot := fun (index : Nat) => (match values[index]? with
      | some value => pure value
      | none => throw "PSCV0-ABI-PLAN: missing flat slot" : Except String R)
    let fields := fun (fields : List AbiField) => do
      let mut start := 0
      let mut code : List R := []
      for field in fields do
        let child ← abiNode plan field.node
        code := code ++ [← abiStoreFlat plan fuel field.node (offset pointer field.offset)
          ((values.drop start).take child.flat)]
        start := start + child.flat
      return seq code
    match node.shape with
    | .scalar scalar =>
      let value ← slot 0
      let value := match scalar with
        | .bool => c "__ps_abi_check_bool" [value]
        | .char => c "__ps_abi_check_char" [value]
        | .word => value
      return o (.memory (if scalar == .bool then .store8 else .store32)) [pointer, value]
    | .string | .list _ | .limbs =>
      return seq [store pointer (← slot 0), store (offset pointer 4) (← slot 1)]
    | .natural limbs => abiStoreFlat plan fuel limbs pointer values
    | .integer negative magnitude =>
      return seq [← abiStoreFlat plan fuel negative pointer (values.take 1),
        ← abiStoreFlat plan fuel magnitude (offset pointer 4) (values.drop 1)]
    | .record _ fs | .payload fs => fields fs
    | .variant _ cases payloadOffset tagSize =>
      let tag ← slot 0
      let storeOp := if tagSize == 1 then PsWasmMemoryOp.store8 else if tagSize == 2 then .store16 else .store32
      let cases ← cases.mapM fun alternative => do
        let body ← match alternative.payload with
          | none => pure (seq [])
          | some id => do
            let child ← abiNode plan id
            abiStoreFlat plan fuel id (offset pointer payloadOffset) ((values.drop 1).take child.flat)
        return (alternative.tag, body)
      -- Validate before narrowing the discriminant into its compact memory slot.
      return seq [cases.foldr (fun (n, body) rest => choice none (eq tag (k n)) body rest) trap,
        o (.memory storeOp) [pointer, tag]]

def abiSingleResult (plan : AbiPlan) : Nat → Nat → R → Except String R
  | 0, _, _ => throw "PSCV0-ABI-RESOURCE: result flattening traversal exhausted"
  | fuel + 1, id, pointer => do
    let node ← abiNode plan id
    if node.flat != 1 then throw "PSCV0-ABI-PLAN: result must have one flat slot"
    match node.shape with
    | .scalar scalar => return o (.memory (if scalar == .bool then .load8 else .load32)) [pointer]
    | .variant _ _ _ tagSize =>
      return o (.memory (if tagSize == 1 then .load8 else if tagSize == 2 then .load16 else .load32)) [pointer]
    | .record _ fields | .payload fields =>
      let some field := fields.head? | throw "PSCV0-ABI-PLAN: empty flat result"
      abiSingleResult plan fuel field.node (offset pointer field.offset)
    | _ => throw "PSCV0-ABI-PLAN: invalid single result layout"

def abiExportWrapper (plan : AbiPlan) (e : AbiExport) : Except String RuntimeDefinition := do
  let mut parameters : List (String × PsWasmValueType) := []
  let mut locals : List (String × PsWasmValueType) := []
  let mut prepare : List R := [c "__ps_abi_enter" []]
  let mut arguments : List R := []
  if e.indirectParameters then
    parameters := [("arguments", .i32)]
    prepare := prepare ++ [c "__ps_abi_check_range" [g "arguments", k e.parameterSize, k e.parameterAlignment]]
  for ((name, id), index) in e.parameters.zipIdx do
    let node ← abiNode plan id
    let temporary := name ++ "_abi"
    let pointer := if e.indirectParameters then offset (g "arguments") (e.parameterOffsets[index]?.getD 0)
      else g temporary
    if !e.indirectParameters then
      let flatNames := (List.range node.flat).map fun i => name ++ "_" ++ toString i
      parameters := parameters ++ flatNames.map fun n => (n, .i32)
      locals := locals ++ [(temporary, .i32)]
      prepare := prepare ++ [put temporary (abiAllocate (k node.size) (k node.alignment)),
        ← abiStoreFlat plan 4096 id pointer (flatNames.map g)]
    arguments := arguments ++ [← abiRead plan id pointer]
  let body ← match e.result with
    | none => pure (seq (prepare ++ [o .drop [c e.target arguments]]))
    | some id => do
      let node ← abiNode plan id
      locals := locals ++ [("result_value", ← abiRepresentation node), ("result_pointer", .i32)]
      let result ← if e.indirectResult then pure (g "result_pointer")
        else abiSingleResult plan 4096 id (g "result_pointer")
      pure (seq (prepare ++ [put "result_value" (c e.target arguments),
        put "result_pointer" (abiAllocate (k node.size) (k node.alignment)),
        ← abiWrite plan id (g "result_pointer") (g "result_value"),
        result]))
  runtimeDefinition ("__ps_abi_export_" ++ e.target) parameters
    (if e.result.isSome then [.i32] else []) locals body

def addCanonicalAdapters (core : PsWasmModule) (names : LocalNames) (plan : AbiPlan) :
    Except String (PsWasmModule × LocalNames) := do
  let runtime ← abiMemoryRuntime
  let marshals ← plan.nodes.mapM (abiMarshalNode plan)
  let exports ← plan.exports.mapM (abiExportWrapper plan)
  let definitions := runtime ++ marshals.flatten ++ exports
  let abiExports := [
    ("__ps_abi_realloc", "__ps_abi_realloc"),
    ("__ps_abi_post_return", "__ps_abi_post_return"),
    ("__ps_abi_post_return_void", "__ps_abi_post_return_void"),
    ("__ps_abi_usage", "__ps_abi_usage")]
  let core : PsWasmModule := {
    core with
    abiMemory := true, abiGlobals := [("abi_cursor", 16), ("abi_active", 0)]
    functions := core.functions ++ definitions.map (·.function)
    exports := abiExports ++ plan.exports.map fun e => (e.semanticName, "__ps_abi_export_" ++ e.target) }
  return (← pruneFunctions core, names ++ definitions.map fun d => (d.function.name, d.names))

end PsWasm
