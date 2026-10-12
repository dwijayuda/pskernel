import Ps.BackendWasm.Model
import Ps.BackendWasm.Binary
import Ps.Codegen.Doc
import Ps.Codegen.Names

namespace PsWasm

-- Identifiers are an injective byte spelling, independent of linking identity.
def hexDigit (n : Nat) : String :=
  String.singleton (("0123456789abcdef".toList[n % 16]!).toLower)

def hexByte (b : UInt8) : String := hexDigit (b.toNat / 16) ++ hexDigit b.toNat

def watId (name : String) : String :=
  "$" ++ String.join (name.toUTF8.data.toList.map fun b =>
    let c := Char.ofNat b.toNat
    if (b.toNat < 128 && (c.isAlpha || c.isDigit)) || ['_', '.', '-', '$'].contains c then String.singleton c
    else "~" ++ hexByte b)

def watQuote (name : String) : String :=
  "\"" ++ String.join (name.toUTF8.data.toList.map fun b =>
    if b.toNat >= 32 && b.toNat <= 126 && b.toNat != 34 && b.toNat != 92 then
      String.singleton (Char.ofNat b.toNat)
    else "\\" ++ hexByte b) ++ "\""

def watType : PsWasmValueType → String
  | .i32 => "i32" | .i64 => "i64" | .f32 => "f32" | .f64 => "f64"
  | .refT name => "(ref " ++ watId name ++ ")"
  | .funcRef => "funcref"
  | .noValue => "" -- Rejected by target validation, never a value.

def watStorage : PsWasmStorageType → String
  | .packedI8 => "i8" | .packedI16 => "i16" | .value t => watType t

def watResults (ts : List PsWasmValueType) : String :=
  if ts.isEmpty then "" else " (result " ++ String.intercalate " " (ts.map watType) ++ ")"

def watParams (ts : List PsWasmValueType) : String :=
  if ts.isEmpty then "" else " (param " ++ String.intercalate " " (ts.map watType) ++ ")"

def hexNat : Nat → Nat → String
  | 0, _ => ""
  | n + 1, value =>
    if value < 16 then hexDigit value else hexNat n (value / 16) ++ hexDigit value

-- Exact bit-preserving hexadecimal literals, including signed zero/NaN payloads.
def watFloat (bits fractionBits exponentBits : Nat) : String :=
  let sign := if bits / 2^(fractionBits + exponentBits) == 0 then "" else "-"
  let fraction := bits % 2^fractionBits
  let exponent := (bits / 2^fractionBits) % 2^exponentBits
  let bias := 2^(exponentBits - 1) - 1
  if exponent == 2^exponentBits - 1 then
    sign ++ (if fraction == 0 then "inf" else "nan:0x" ++ hexNat 16 fraction)
  else
    let significand := fraction + (if exponent == 0 then 0 else 2^fractionBits)
    let power := Int.ofNat (if exponent == 0 then 1 else exponent) - Int.ofNat (bias + fractionBits)
    sign ++ "0x" ++ hexNat 16 significand ++ "p" ++ toString power

def watInstruction (locals : List String) : PsWasmInstruction → String
  | .memory operation => (psWasmMemoryInstruction operation).mnemonic
  | .globalGet index => "global.get " ++ toString index
  | .globalSet index => "global.set " ++ toString index
  | .word operation => (psWasmWordInstruction operation).mnemonic
  | .localGet i => "local.get " ++ watId (locals[i]?.getD ("local" ++ toString i))
  | .localSet i => "local.set " ++ watId (locals[i]?.getD ("local" ++ toString i))
  | .drop => "drop" | .unreachable => "unreachable"
  | .call n => "call " ++ watId n
  | .returnCall n => "return_call " ++ watId n
  | .return_ => "return"
  | .ifStart result => "if" ++ watResults result.toList
  | .else_ => "else"
  | .end_ => "end"
  | .i32Const n => "i32.const " ++ toString (psWasmNormalizeI32Immediate n)
  | .i64Const n => "i64.const " ++ toString (psWasmNormalizeI64Immediate n)
  | .f32ConstBits b => "f32.const " ++ watFloat b.toNat 23 8
  | .f64ConstBits b => "f64.const " ++ watFloat b.toNat 52 11
  | .i32Add => "i32.add"
  | .i32Sub => "i32.sub"
  | .i32Mul => "i32.mul"
  | .i32And => "i32.and"
  | .i32Or => "i32.or"
  | .i32Xor => "i32.xor"
  | .i32ShrU => "i32.shr_u"
  | .i32Extend8S => "i32.extend8_s"
  | .i32Extend16S => "i32.extend16_s"
  | .i32Eq => "i32.eq"
  | .i32Ne => "i32.ne"
  | .i32LtS => "i32.lt_s"
  | .i32LtU => "i32.lt_u"
  | .i32LeS => "i32.le_s"
  | .i32LeU => "i32.le_u"
  | .i32GtS => "i32.gt_s"
  | .i32GtU => "i32.gt_u"
  | .i32GeS => "i32.ge_s"
  | .i32GeU => "i32.ge_u"
  | .i64Add => "i64.add"
  | .i64Sub => "i64.sub"
  | .i64Mul => "i64.mul"
  | .i64And => "i64.and"
  | .i64Or => "i64.or"
  | .i64Xor => "i64.xor"
  | .i64Eq => "i64.eq"
  | .i64Ne => "i64.ne"
  | .i64LtS => "i64.lt_s"
  | .i64LtU => "i64.lt_u"
  | .i64LeS => "i64.le_s"
  | .i64LeU => "i64.le_u"
  | .i64GtS => "i64.gt_s"
  | .i64GtU => "i64.gt_u"
  | .i64GeS => "i64.ge_s"
  | .i64GeU => "i64.ge_u"
  | .f32Add => "f32.add"
  | .f32Sub => "f32.sub"
  | .f32Mul => "f32.mul"
  | .f32Div => "f32.div"
  | .f32Eq => "f32.eq"
  | .f32Ne => "f32.ne"
  | .f32Lt => "f32.lt"
  | .f32Le => "f32.le"
  | .f32Gt => "f32.gt"
  | .f32Ge => "f32.ge"
  | .f64Add => "f64.add"
  | .f64Sub => "f64.sub"
  | .f64Mul => "f64.mul"
  | .f64Div => "f64.div"
  | .f64Eq => "f64.eq"
  | .f64Ne => "f64.ne"
  | .f64Lt => "f64.lt"
  | .f64Le => "f64.le"
  | .f64Gt => "f64.gt"
  | .f64Ge => "f64.ge"
  | .structNew n => "struct.new " ++ watId n
  | .structGet n i => "struct.get " ++ watId n ++ " " ++ toString i
  | .structGetS n i => "struct.get_s " ++ watId n ++ " " ++ toString i
  | .structGetU n i => "struct.get_u " ++ watId n ++ " " ++ toString i
  | .arrayNew n => "array.new " ++ watId n
  | .arrayNewDefault n => "array.new_default " ++ watId n
  | .arrayNewFixed n i => "array.new_fixed " ++ watId n ++ " " ++ toString i
  | .arrayGet n => "array.get " ++ watId n
  | .arrayGetS n => "array.get_s " ++ watId n
  | .arrayGetU n => "array.get_u " ++ watId n
  | .arraySet n => "array.set " ++ watId n
  | .arrayLen => "array.len"
  | .arrayCopy a b => "array.copy " ++ watId a ++ " " ++ watId b
  | .refTest n => "ref.test (ref " ++ watId n ++ ")"
  | .refCast n | .refCastFunction n => "ref.cast (ref " ++ watId n ++ ")"
  | .refFunc n => "ref.func " ++ watId n
  | .callRef n => "call_ref " ++ watId n
  | .returnCallRef n => "return_call_ref " ++ watId n

def watBody (locals : List String) (body : List PsWasmInstruction) : List PsDoc :=
  (body.foldl (fun (state : Nat × List PsDoc) instruction =>
    let indent := match instruction with
      | .else_ | .end_ => state.1 - 1 | _ => state.1
    let line := .text (String.ofList (List.replicate (indent * 2) ' ') ++ watInstruction locals instruction)
    let next := match instruction with | .ifStart _ | .else_ => indent + 1 | _ => indent
    (next, line :: state.2)) (0, [])).2.reverse

abbrev LocalNames := List (String × List String)

def functionLocalNames (names : LocalNames) (f : PsWasmFunction) : List String :=
  let given := (names.find? (fun p => p.1 == f.name)).map (·.2) |>.getD []
  (List.range (f.parameters.length + f.locals.length)).map fun i =>
    given[i]?.getD ((if i < f.parameters.length then "arg" else "local") ++ toString i)

def watFunction (names : LocalNames) (f : PsWasmFunction) : PsDoc :=
  let locals := functionLocalNames names f
  let params := f.parameters.zipIdx |>.map fun (t, i) =>
    "(param " ++ watId (locals[i]!) ++ " " ++ watType t ++ ")"
  let localDecls := f.locals.zipIdx |>.map fun (t, i) =>
    PsDoc.text ("(local " ++ watId (locals[i + f.parameters.length]!) ++ " " ++ watType t ++ ")")
  let header := "(func " ++ watId f.name ++
    (f.typeName.map (fun n => " (type " ++ watId n ++ ")")).getD "" ++
    (if params.isEmpty then "" else " " ++ String.intercalate " " params) ++ watResults f.results
  .origin f.name (.append (.text header)
    (.append (.nest 2 (.append .hardline (psDocJoin .hardline (localDecls ++ watBody locals f.body))))
      (.append .hardline (.text ")"))))

def anonymousTypeName (m : PsWasmModule) (i : Nat) : String :=
  let used := m.structures.map (·.name) ++ m.arrays.map (·.name) ++ m.functionTypes.map (·.name)
  psCodegenFresh (used.length + 1) used ("signature" ++ toString i)

def watModuleDoc (m : PsWasmModule) (names : LocalNames := []) (header := "(module") : PsDoc :=
  let structures := m.structures.map fun s =>
    let fields := s.fields.map fun field => PsDoc.text ("(field " ++ watId field.name ++ " " ++ watStorage field.storageType ++ ")")
    let sub := if s.superType.isSome || !s.isFinal then
      "(sub " ++ (if s.isFinal then "final " else "") ++
        (s.superType.map (fun n => watId n ++ " ")).getD "" else ""
    .append (.text ("(type " ++ watId s.name ++ " " ++ sub ++ "(struct"))
      (.append (.nest 2 (if fields.isEmpty then .text "" else .append .hardline (psDocJoin .hardline fields)))
        (.text (if sub.isEmpty then "))" else ")))")))
  let arrays := m.arrays.map fun a =>
    let storage := watStorage a.elementType
    PsDoc.text ("(type " ++ watId a.name ++ " (array " ++
      (if a.mutable then "(mut " ++ storage ++ ")" else storage) ++ "))")
  let signatures := m.functionTypes.map fun t =>
    PsDoc.text ("(type " ++ watId t.name ++ " (func" ++ watParams t.parameters ++ watResults t.results ++ "))")
  -- Independent singleton function signatures retain Canonical ABI type identity.
  let anonymous := m.functions.zipIdx |>.map fun (f, i) =>
    PsDoc.text ("(type " ++ watId (anonymousTypeName m i) ++ " (func" ++ watParams f.parameters ++ watResults f.results ++ "))")
  let types := structures ++ arrays
  let group := if types.isEmpty then [] else [
    PsDoc.append (.text "(rec") (.append (.nest 2 (.append .hardline (psDocJoin .hardline types)))
      (.append .hardline (.text ")")))]
  let refs := if m.functionRefs.isEmpty then [] else [
    PsDoc.text ("(elem declare func " ++ String.intercalate " " (m.functionRefs.map watId) ++ ")")]
  let exports := (m.exports.map fun (external, internal) =>
    PsDoc.text ("(export " ++ watQuote external ++ " (func " ++ watId internal ++ "))")) ++
    (if m.abiMemory then [PsDoc.text "(export \"memory\" (memory $abi_buffers))"] else [])
  let memory := if m.abiMemory then [PsDoc.text "(memory $abi_buffers 1 32768)"] else []
  let globals := m.abiGlobals.map fun (name, value) =>
    PsDoc.text ("(global " ++ watId name ++ " (mut i32) (i32.const " ++ toString value ++ "))")
  let functions := m.functions.zipIdx |>.map fun (f, i) =>
    watFunction names { f with typeName := some (f.typeName.getD (anonymousTypeName m i)) }
  .append (.text header)
    (.append (.nest 2 (.append .hardline (psDocJoin .hardline (group ++ signatures ++ anonymous ++ memory ++ globals ++ refs ++ functions ++ exports))))
      (.append .hardline (.text ")")))

end PsWasm
