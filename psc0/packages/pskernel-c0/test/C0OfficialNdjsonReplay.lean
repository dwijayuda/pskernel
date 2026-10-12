import Lean
import Ps.KernelCore.API.Kernel

/-!
Strict Lean 4.35.0 NDJSON subset replay into the C0 accepting checker.

Unlike separately hand-written C0 fixtures, this test checks the exact same
source bytes consumed by the official leanchecker --from-export runner.
Unsupported tags, missing references, incorrect IDs, duplicate definitions,
version drift and non-serialisable semantic constructs all fail closed as
input/unsupported errors, never as an accepted or rejected kernel judgment.

This subset includes standard names and levels, sort/bvar/constant,
applications, lambda/forall, let, projection and literal expressions,
and sequentially checked ordinary definitions with dependencies. It is intentionally not a general Lean exporter
frontend and does not silently drop mdata, FVar, MVar or inductive records.
-/

structure C0ExportTables where
  names : Array PsKernelName := #[.anonymous]
  levels : Array PsKernelLevel := #[.zero]
  exprs : Array PsKernelExpr := #[]
  definitions : List PsKernelDefinitionInfo := []
  header : Bool := false

def c0JsonObj (j : Lean.Json) (key : String) : Except String Lean.Json :=
  j.getObjVal? key

def c0JsonNat (j : Lean.Json) (key : String) : Except String Nat := do
  let value ← c0JsonObj j key
  value.getNat?

def c0JsonString (j : Lean.Json) (key : String) : Except String String := do
  let value ← c0JsonObj j key
  value.getStr?

/-- Fail closed on unknown fields, including apparently harmless metadata:
    a lossy source projection cannot be used as an official conformance verdict. -/
def c0ExportOnlyKeys (j : Lean.Json) (allowed : List String) :
    Except String Unit := do
  let object ← j.getObj?
  let fields := object.toList.map Prod.fst
  for key in fields do
    if !allowed.contains key then
      throw ("unsupported NDJSON field: " ++ key)

def c0JsonNatList (j : Lean.Json) : Except String (List Nat) := do
  let arr ← j.getArr?
  arr.toList.mapM (fun value => value.getNat?)

def c0ExportName
    (tables : C0ExportTables) (idx : Nat) :
    Except String PsKernelName :=
  match tables.names[idx]? with
  | some value => .ok value
  | none => .error s!"unknown NDJSON name handle {idx}"

def c0ExportLevel
    (tables : C0ExportTables) (idx : Nat) :
    Except String PsKernelLevel :=
  match tables.levels[idx]? with
  | some value => .ok value
  | none => .error s!"unknown NDJSON level handle {idx}"

def c0ExportExpr
    (tables : C0ExportTables) (idx : Nat) :
    Except String PsKernelExpr :=
  match tables.exprs[idx]? with
  | some value => .ok value
  | none => .error s!"unknown NDJSON expression handle {idx}"

def c0ExportNames
    (tables : C0ExportTables) (j : Lean.Json) :
    Except String (List PsKernelName) := do
  let refs ← c0JsonNatList j
  refs.mapM (c0ExportName tables)

def c0ExportLevels
    (tables : C0ExportTables) (j : Lean.Json) :
    Except String (List PsKernelLevel) := do
  let refs ← c0JsonNatList j
  refs.mapM (c0ExportLevel tables)

def c0ExportBinderInfo (s : String) : Except String PsKernelBinderInfo :=
  match s with
  | "default" => .ok .default
  | "implicit" => .ok .implicit
  | "strictImplicit" => .ok .strictImplicit
  | "instImplicit" => .ok .instImplicit
  | _ => .error "unsupported NDJSON binder annotation"

/-- Decode one exact exported name; ID 0 is the anonymous sentinel. -/
def c0ExportDecodeName
    (tables : C0ExportTables)
    (j : Lean.Json) : Except String PsKernelName := do
  if let .ok entry := c0JsonObj j "str" then
    c0ExportOnlyKeys j ["in", "str"]
    c0ExportOnlyKeys entry ["pre", "str"]
    let pre ← c0ExportName tables (← c0JsonNat entry "pre")
    let part ← c0JsonString entry "str"
    return .str pre part
  if let .ok entry := c0JsonObj j "num" then
    c0ExportOnlyKeys j ["in", "num"]
    c0ExportOnlyKeys entry ["pre", "i"]
    let pre ← c0ExportName tables (← c0JsonNat entry "pre")
    let part ← c0JsonNat entry "i"
    return .num pre part
  throw "unsupported NDJSON name constructor"

/-- Decode levels only after all referenced earlier levels exist. -/
def c0ExportDecodeLevel
    (tables : C0ExportTables)
    (j : Lean.Json) : Except String PsKernelLevel := do
  if let .ok value := c0JsonObj j "succ" then
    c0ExportOnlyKeys j ["il", "succ"]
    return .succ (← c0ExportLevel tables (← value.getNat?))
  if let .ok value := c0JsonObj j "max" then
    c0ExportOnlyKeys j ["il", "max"]
    match ← c0JsonNatList value with
    | [a, b] =>
        return .max (← c0ExportLevel tables a) (← c0ExportLevel tables b)
    | _ => throw "malformed NDJSON level max pair"
  if let .ok value := c0JsonObj j "imax" then
    c0ExportOnlyKeys j ["il", "imax"]
    match ← c0JsonNatList value with
    | [a, b] =>
        return .imax (← c0ExportLevel tables a) (← c0ExportLevel tables b)
    | _ => throw "malformed NDJSON level imax pair"
  if let .ok value := c0JsonObj j "param" then
    c0ExportOnlyKeys j ["il", "param"]
    return .param (← c0ExportName tables (← value.getNat?))
  throw "unsupported NDJSON level constructor"

/-- Preserve supported expression constructors exactly, without inventing
    metadata values or silently converting fvars into bound variables. -/
def c0ExportDecodeExpr
    (tables : C0ExportTables)
    (j : Lean.Json) : Except String PsKernelExpr := do
  if let .ok value := c0JsonObj j "bvar" then
    c0ExportOnlyKeys j ["ie", "bvar"]
    return .bvar (← value.getNat?)
  if let .ok value := c0JsonObj j "sort" then
    c0ExportOnlyKeys j ["ie", "sort"]
    return .sort (← c0ExportLevel tables (← value.getNat?))
  if let .ok value := c0JsonObj j "const" then
    c0ExportOnlyKeys j ["ie", "const"]
    c0ExportOnlyKeys value ["name", "us"]
    let name ← c0ExportName tables (← c0JsonNat value "name")
    let levels ← c0ExportLevels tables (← c0JsonObj value "us")
    return .const name levels
  if let .ok value := c0JsonObj j "app" then
    c0ExportOnlyKeys j ["ie", "app"]
    c0ExportOnlyKeys value ["fn", "arg"]
    let fn ← c0ExportExpr tables (← c0JsonNat value "fn")
    let arg ← c0ExportExpr tables (← c0JsonNat value "arg")
    return .app fn arg
  if let .ok value := c0JsonObj j "lam" then
    c0ExportOnlyKeys j ["ie", "lam"]
    c0ExportOnlyKeys value ["name", "type", "body", "binderInfo"]
    let name ← c0ExportName tables (← c0JsonNat value "name")
    let ty ← c0ExportExpr tables (← c0JsonNat value "type")
    let body ← c0ExportExpr tables (← c0JsonNat value "body")
    let bi ← c0ExportBinderInfo (← c0JsonString value "binderInfo")
    return .lam name ty body bi
  if let .ok value := c0JsonObj j "forallE" then
    c0ExportOnlyKeys j ["ie", "forallE"]
    c0ExportOnlyKeys value ["name", "type", "body", "binderInfo"]
    let name ← c0ExportName tables (← c0JsonNat value "name")
    let ty ← c0ExportExpr tables (← c0JsonNat value "type")
    let body ← c0ExportExpr tables (← c0JsonNat value "body")
    let bi ← c0ExportBinderInfo (← c0JsonString value "binderInfo")
    return .forallE name ty body bi
  if let .ok value := c0JsonObj j "letE" then
    c0ExportOnlyKeys j ["ie", "letE"]
    let name ← c0ExportName tables (← c0JsonNat value "name")
    let ty ← c0ExportExpr tables (← c0JsonNat value "type")
    let val ← c0ExportExpr tables (← c0JsonNat value "value")
    let body ← c0ExportExpr tables (← c0JsonNat value "body")
    c0ExportOnlyKeys value ["name", "type", "value", "body", "nondep"]
    let nd ← (← c0JsonObj value "nondep").getBool?
    return .letE name ty val body nd
  if let .ok value := c0JsonObj j "proj" then
    c0ExportOnlyKeys j ["ie", "proj"]
    c0ExportOnlyKeys value ["typeName", "idx", "struct"]
    let name ← c0ExportName tables (← c0JsonNat value "typeName")
    let idx ← c0JsonNat value "idx"
    let body ← c0ExportExpr tables (← c0JsonNat value "struct")
    return .proj name idx body
  if let .ok value := c0JsonObj j "natVal" then
    c0ExportOnlyKeys j ["ie", "natVal"]
    let s ← value.getStr?
    match s.toNat? with
    | some n => return .lit (.nat n)
    | none => throw "malformed NDJSON Nat literal"
  if let .ok value := c0JsonObj j "strVal" then
    c0ExportOnlyKeys j ["ie", "strVal"]
    return .lit (.str (← value.getStr?))
  throw "unsupported NDJSON expression constructor or metadata"

/-- Track the original exporter IDs; never confuse an unresolved reference
    or malformed format with a checked kernel rejection. -/
def c0ExportParseRecord
    (st : C0ExportTables)
    (j : Lean.Json) : Except String C0ExportTables := do
  if let .ok headerData := c0JsonObj j "meta" then
    c0ExportOnlyKeys j ["meta"]
    c0ExportOnlyKeys headerData ["exporter", "format", "lean"]
    let exporter ← c0JsonObj headerData "exporter"
    c0ExportOnlyKeys exporter ["name", "version"]
    let exporterName ← c0JsonString exporter "name"
    let exporterVersion ← c0JsonString exporter "version"
    let leanData ← c0JsonObj headerData "lean"
    c0ExportOnlyKeys leanData ["version", "githash"]
    let formatData ← c0JsonObj headerData "format"
    c0ExportOnlyKeys formatData ["version"]
    if exporterName != "lean4export" || exporterVersion != "3.1.0" then
      throw "unsupported NDJSON exporter identity"
    if st.header then throw "duplicate NDJSON export metadata"
    let version ← c0JsonString (← c0JsonObj headerData "lean") "version"
    let hash ← c0JsonString (← c0JsonObj headerData "lean") "githash"
    let format ← c0JsonString (← c0JsonObj headerData "format") "version"
    if version != "4.35.0" ||
        hash != "eb6cafb7290e8bd5f2937522d8d804f58f02bafc" ||
        format != "3.1.0" then
      throw "NDJSON exported by an unsupported Lean version or format"
    return { st with header := true }
  if !st.header then throw "NDJSON declaration preceded export metadata"
  if let .ok value := c0JsonObj j "in" then
    let idx ← value.getNat?
    if idx != st.names.size then throw "NDJSON name IDs not sequential"
    let newName ← c0ExportDecodeName st j
    return { st with names := st.names.push newName }
  if let .ok value := c0JsonObj j "il" then
    let idx ← value.getNat?
    if idx != st.levels.size then throw "NDJSON level IDs not sequential"
    let newLevel ← c0ExportDecodeLevel st j
    return { st with levels := st.levels.push newLevel }
  if let .ok value := c0JsonObj j "ie" then
    let idx ← value.getNat?
    if idx != st.exprs.size then throw "NDJSON expression IDs not sequential"
    let newExpr ← c0ExportDecodeExpr st j
    return { st with exprs := st.exprs.push newExpr }
  if let .ok payload := c0JsonObj j "def" then
    c0ExportOnlyKeys j ["def"]
    c0ExportOnlyKeys payload
      ["all", "hints", "levelParams", "name", "safety", "type", "value"]
    let declarationId ← c0JsonNat payload "name"
    let allIds ← c0JsonNatList (← c0JsonObj payload "all")
    if !allIds.contains declarationId then
      throw "malformed NDJSON declaration manifest"
    let name ← c0ExportName st declarationId
    let params ← c0ExportNames st (← c0JsonObj payload "levelParams")
    let ty ← c0ExportExpr st (← c0JsonNat payload "type")
    let value ← c0ExportExpr st (← c0JsonNat payload "value")
    let safety ← c0JsonString payload "safety"
    if safety != "safe" then throw "unsupported safety policy"
    let hintValue ← c0JsonObj payload "hints"
    let hints ←
      match hintValue.getStr? with
      | .ok "abbrev" => pure PsKernelReducibilityHints.abbrevHint
      | .ok "opaque" => pure PsKernelReducibilityHints.opaqueHint
      | .ok _ => throw "unsupported reducibility hint"
      | .error _ =>
          c0ExportOnlyKeys hintValue ["regular"]
          let height ← c0JsonNat hintValue "regular"
          pure (PsKernelReducibilityHints.regular height)
    let definition : PsKernelDefinitionInfo := {
      base := { name := name, levelParams := params, type := ty }
      value := value
      hints := hints
      safety := .safe
    }
    return { st with definitions := definition :: st.definitions }
  throw "unsupported NDJSON declaration tag"

/-- A supported record may be parsed once; everything else fails closed. -/
def c0ExportReadSubset (input : String) : Except String (List PsKernelDefinitionInfo) := do
  let mut tables : C0ExportTables := {}
  for line in input.splitOn "\n" do
    if line != "" then
      let record ← Lean.Json.parse line
      tables ← c0ExportParseRecord tables record
  if !tables.header then throw "NDJSON missing pinned metadata"
  match tables.definitions with
  | [] => throw "NDJSON missing a supported declaration"
  | definitions => pure definitions.reverse

/-- Sequentially check exactly the declarations recovered from official
    NDJSON bytes in their original order. A failed checked definition cannot
    mutate the previously accepted environment, and unsupported input errors
    remain distinct from legitimate kernel rejection. -/
def c0ExportCheckDefinitions (infos : List PsKernelDefinitionInfo) :
    Except String Bool := do
  let mut env := psKernelEnvironmentEmpty
  for info in infos do
    match psKernelAddDefinition 4096 env info
        4096 psKernelLeanNatMaxSizeDefault with
    | .ok next => env := next
    | .error message =>
        match psKernelErrorFromMessage message with
        | .rejectedInvalid _ => return false
        | _ => throw ("C0 check did not yield a normal rejection: " ++ message)
  return true

/-- The conformance harness distinguishes official acceptance/rejection from
    a test-adapter decline, malformed source and inconclusive checker work.
    A declined feature is never counted as an official kernel rejection. -/
inductive C0ExportVerdict where
  | accepted
  | rejected
  | unsupported
  | malformed
  | inconclusive
  deriving BEq, Repr

def c0ExportClassifyInputError (message : String) : C0ExportVerdict :=
  if message.startsWith "unsupported" ||
      message.startsWith "NDJSON exported by an unsupported" then
    .unsupported
  else
    .malformed

def c0ExportVerdictOf (input : String) : C0ExportVerdict :=
  match c0ExportReadSubset input with
  | .error message => c0ExportClassifyInputError message
  | .ok declarations =>
      match c0ExportCheckDefinitions declarations with
      | .ok true => .accepted
      | .ok false => .rejected
      | .error _ => .inconclusive

/-- No exporter, unsupported field or malformed input may become a positive
    or negative *kernel* verdict. Failure must occur before checking. -/
def c0ExportRejectLossyImports : IO Unit := do
  let valid ← IO.FS.readFile "test/C0OfficialAccept.ndjson"
  let invalidInputs : List (String × String × C0ExportVerdict) := [
    ("unknown-definition-field",
      valid.replace "\"safety\":\"safe\"" "\"safety\":\"safe\",\"trustedShortcut\":true", .unsupported),
    ("unknown-expression-field",
      valid.replace "\"ie\":0,\"sort\":0" "\"ie\":0,\"sort\":0,\"mdata\":42", .unsupported),
    ("unknown-exporter-field",
      valid.replace "\"format\":{\"version\":\"3.1.0\"}"
        "\"format\":{\"version\":\"3.1.0\",\"unsafe\":true}", .unsupported),
    ("unknown-formatter-version",
      valid.replace "\"version\":\"3.1.0\"" "\"version\":\"999.0\"", .unsupported),
    ("missing-declaration-manifest",
      valid.replace "\"all\":[1]" "\"all\":[]", .malformed),
    ("unknown-name-field",
      valid.replace "\"pre\":0,\"str\":\"C0OfficialReference\""
        "\"pre\":0,\"str\":\"C0OfficialReference\",\"untrusted\":true", .unsupported)
  ]
  for (label, input, expected) in invalidInputs do
    if input == valid then
      throw (IO.userError ("ineffective negative export mutation: " ++ label))
    let result := c0ExportVerdictOf input
    if result != expected then
      throw (IO.userError s!"wrong input category {label}: {repr result}")

def main : IO Unit := do
  c0ExportRejectLossyImports
  let cases : List (String × Bool) := [
    ("C0OfficialAccept.ndjson", true),
    ("C0OfficialReject.ndjson", false),
    ("C0OfficialBinderAccept.ndjson", true),
    ("C0OfficialBinderReject.ndjson", false),
    ("C0OfficialLetAccept.ndjson", true),
    ("C0OfficialLetReject.ndjson", false),
    ("C0OfficialUniverseAccept.ndjson", true),
    ("C0OfficialUniverseReject.ndjson", false),
    ("C0OfficialAppAccept.ndjson", true),
    ("C0OfficialAppReject.ndjson", false),
    ("C0OfficialDependencyAccept.ndjson", true),
    ("C0OfficialDependencyReject.ndjson", false),
    ("C0OfficialChainAccept.ndjson", true),
    ("C0OfficialChainReject.ndjson", false)
  ]
  for item in cases do
    let path := "test/" ++ item.fst
    let input ← IO.FS.readFile path
    let expected := if item.snd then C0ExportVerdict.accepted
      else C0ExportVerdict.rejected
    let actual := c0ExportVerdictOf input
    if actual != expected then
      throw (IO.userError s!"C0/official NDJSON verdict mismatch {path}: {repr actual}")
  IO.println "C0_LEAN435 exact_official_ndjson_subset_replay=pass"
