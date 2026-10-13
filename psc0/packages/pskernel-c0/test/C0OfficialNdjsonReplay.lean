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
and sequentially checked safe axioms, definitions, theorems and opaques with dependencies. It is intentionally not a general Lean exporter
frontend and does not silently drop mdata, FVar, MVar or inductive records.
-/

/-- Exporter metadata is never a kernel axiom: all generated entries must
    be reconstructed from checked inductive source and independently compared. -/
inductive C0ExportInductiveSource where
  | ordinary (decl : PsKernelSimpleInductiveDecl)
  | mutual (decl : PsKernelSimpleMutualInductiveDecl)

structure C0ExportInductiveGroup where
  source : C0ExportInductiveSource
  expectedTypes : List PsKernelInductiveInfo
  expectedCtors : List PsKernelConstructorInfo
  expectedRecs : List PsKernelRecursorInfo

inductive C0ExportDeclaration where
  | axiomDecl (value : PsKernelAxiomInfo)
  | definition (value : PsKernelDefinitionInfo)
  | theoremDecl (value : PsKernelTheoremInfo)
  | opaqueDecl (value : PsKernelOpaqueInfo)
  | inductiveGroup (value : C0ExportInductiveGroup)

structure C0ExportTables where
  names : Array PsKernelName := #[.anonymous]
  levels : Array PsKernelLevel := #[.zero]
  exprs : Array PsKernelExpr := #[]
  declarations : List C0ExportDeclaration := []
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

/-- Exact shape check for exporter Name lists; binder display names in
    encoded expressions are not proof semantics, so types use kernel equality. -/
def c0ExportSameNames (xs ys : List PsKernelName) : Bool :=
  xs.length == ys.length &&
    (xs.zip ys).all (fun (x, y) => psKernelNameEq x y)

def c0ExportSameBase (a b : PsKernelConstantBase) : Bool :=
  psKernelNameEq a.name b.name &&
  c0ExportSameNames a.levelParams b.levelParams &&
  psKernelExprEq a.type b.type

def c0ExportReadInductiveType
    (st : C0ExportTables) (j : Lean.Json) :
    Except String PsKernelInductiveInfo := do
  c0ExportOnlyKeys j
    ["name", "levelParams", "type", "numParams", "numIndices",
     "all", "ctors", "numNested", "isRec", "isUnsafe", "isReflexive"]
  let name ← c0ExportName st (← c0JsonNat j "name")
  let levels ← c0ExportNames st (← c0JsonObj j "levelParams")
  let type ← c0ExportExpr st (← c0JsonNat j "type")
  let all ← c0ExportNames st (← c0JsonObj j "all")
  let ctors ← c0ExportNames st (← c0JsonObj j "ctors")
  let numParams ← c0JsonNat j "numParams"
  let numIndices ← c0JsonNat j "numIndices"
  let numNested ← c0JsonNat j "numNested"
  let isRec ← (← c0JsonObj j "isRec").getBool?
  let isUnsafe ← (← c0JsonObj j "isUnsafe").getBool?
  let isReflexive ← (← c0JsonObj j "isReflexive").getBool?
  return {
    base := { name := name, levelParams := levels, type := type }
    numParams := numParams
    numIndices := numIndices
    all := all
    ctors := ctors
    numNested := numNested
    isRec := isRec
    isUnsafe := isUnsafe
    isReflexive := isReflexive
  }

def c0ExportReadConstructor
    (st : C0ExportTables) (j : Lean.Json) :
    Except String PsKernelConstructorInfo := do
  c0ExportOnlyKeys j
    ["name", "levelParams", "type", "induct", "cidx",
     "numParams", "numFields", "isUnsafe"]
  let name ← c0ExportName st (← c0JsonNat j "name")
  let levels ← c0ExportNames st (← c0JsonObj j "levelParams")
  let type ← c0ExportExpr st (← c0JsonNat j "type")
  let induct ← c0ExportName st (← c0JsonNat j "induct")
  let cidx ← c0JsonNat j "cidx"
  let numParams ← c0JsonNat j "numParams"
  let numFields ← c0JsonNat j "numFields"
  let isUnsafe ← (← c0JsonObj j "isUnsafe").getBool?
  return {
    base := { name := name, levelParams := levels, type := type }
    induct := induct
    cidx := cidx
    numParams := numParams
    numFields := numFields
    isUnsafe := isUnsafe
  }

def c0ExportReadRecursorRule
    (st : C0ExportTables) (j : Lean.Json) :
    Except String PsKernelRecursorRule := do
  c0ExportOnlyKeys j ["ctor", "nfields", "rhs"]
  let ctor ← c0ExportName st (← c0JsonNat j "ctor")
  let fields ← c0JsonNat j "nfields"
  let rhs ← c0ExportExpr st (← c0JsonNat j "rhs")
  return { ctor := ctor, nFields := fields, rhs := rhs }

def c0ExportReadRecursor
    (st : C0ExportTables) (j : Lean.Json) :
    Except String PsKernelRecursorInfo := do
  c0ExportOnlyKeys j
    ["name", "levelParams", "type", "all", "numParams",
     "numIndices", "numMotives", "numMinors", "rules", "k", "isUnsafe"]
  let name ← c0ExportName st (← c0JsonNat j "name")
  let levels ← c0ExportNames st (← c0JsonObj j "levelParams")
  let type ← c0ExportExpr st (← c0JsonNat j "type")
  let all ← c0ExportNames st (← c0JsonObj j "all")
  let numParams ← c0JsonNat j "numParams"
  let numIndices ← c0JsonNat j "numIndices"
  let numMotives ← c0JsonNat j "numMotives"
  let numMinors ← c0JsonNat j "numMinors"
  let rules ← (← c0JsonObj j "rules").getArr?
  let rules ← rules.toList.mapM (c0ExportReadRecursorRule st)
  let k ← (← c0JsonObj j "k").getBool?
  let isUnsafe ← (← c0JsonObj j "isUnsafe").getBool?
  return {
    base := { name := name, levelParams := levels, type := type }
    all := all
    numParams := numParams
    numIndices := numIndices
    numMotives := numMotives
    numMinors := numMinors
    rules := rules
    k := k
    isUnsafe := isUnsafe
  }

/-- A complete ordinary export block is reconstructed, never admitted by
    trusting its precomputed recursor or constructor declarations.
    Mutual/nested/safety variants remain explicit declines. -/
def c0ExportReadInductiveGroup
    (st : C0ExportTables) (block : Lean.Json) :
    Except String C0ExportInductiveGroup := do
  c0ExportOnlyKeys block ["types", "ctors", "recs"]
  let ts ← (← c0JsonObj block "types").getArr?
  let cs ← (← c0JsonObj block "ctors").getArr?
  let rs ← (← c0JsonObj block "recs").getArr?
  let types ← ts.toList.mapM (c0ExportReadInductiveType st)
  let expectedCtors ← cs.toList.mapM (c0ExportReadConstructor st)
  let expectedRecs ← rs.toList.mapM (c0ExportReadRecursor st)
  let some first := types.head?
    | throw "malformed NDJSON empty inductive group"
  let names := types.map (fun t => t.base.name)
  if types.any (fun t => t.numNested != 0) then
    throw "unsupported NDJSON nested inductive group"
  if types.any (fun t => t.isUnsafe) ||
      expectedCtors.any (fun c => c.isUnsafe) ||
      expectedRecs.any (fun c => c.isUnsafe) then
    throw "unsupported NDJSON unsafe inductive group"
  for ty in types do
    if !c0ExportSameNames ty.all names ||
        !c0ExportSameNames ty.base.levelParams first.base.levelParams ||
        ty.numParams != first.numParams then
      throw "unsupported NDJSON inconsistent mutual inductive header"
    let constructors := expectedCtors.filter
      (fun c => psKernelNameEq c.induct ty.base.name)
    if !c0ExportSameNames
        (constructors.map (fun c => c.base.name)) ty.ctors then
      throw "malformed NDJSON inductive constructor manifest"
    for i in [:constructors.length] do
      let some c := constructors[i]?
        | throw "malformed NDJSON constructor index"
      if c.cidx != i || c.numParams != ty.numParams ||
          !c0ExportSameNames c.base.levelParams ty.base.levelParams then
        throw "malformed NDJSON inductive constructor metadata"
  let listedCount := (types.map (fun ty =>
    (expectedCtors.filter (fun c =>
      psKernelNameEq c.induct ty.base.name)).length)).foldl (· + ·) 0
  if listedCount != expectedCtors.length then
    throw "malformed NDJSON constructor with unknown inductive owner"
  let recNames := expectedRecs.map (fun r => r.base.name)
  let generatedNames := types.map (fun t =>
    psKernelSimpleRecName t.base.name)
  if !c0ExportSameNames recNames generatedNames then
    throw "unsupported NDJSON recursor family is not canonical"
  let toCtor (c : PsKernelConstructorInfo) :
      PsKernelSimpleConstructorDecl :=
    { name := c.base.name, type := c.base.type }
  let source : C0ExportInductiveSource :=
    if types.length == 1 then
      C0ExportInductiveSource.ordinary {
        levelParams := first.base.levelParams
        name := first.base.name
        type := first.base.type
        ctors := expectedCtors.map toCtor
        isUnsafe := false
        numParams := first.numParams
      }
    else
      C0ExportInductiveSource.mutual {
        levelParams := first.base.levelParams
        numParams := first.numParams
        types := types.map (fun ty => {
          name := ty.base.name
          type := ty.base.type
          ctors := (expectedCtors.filter (fun c =>
            psKernelNameEq c.induct ty.base.name)).map toCtor
        })
        isUnsafe := false
      }
  return {
    source := source
    expectedTypes := types
    expectedCtors := expectedCtors
    expectedRecs := expectedRecs
  }

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
    return { st with declarations := .definition definition :: st.declarations }
  if let .ok payload := c0JsonObj j "axiom" then
    c0ExportOnlyKeys j ["axiom"]
    c0ExportOnlyKeys payload ["name", "levelParams", "type", "isUnsafe"]
    let name ← c0ExportName st (← c0JsonNat payload "name")
    let params ← c0ExportNames st (← c0JsonObj payload "levelParams")
    let ty ← c0ExportExpr st (← c0JsonNat payload "type")
    let isUnsafe ← (← c0JsonObj payload "isUnsafe").getBool?
    if isUnsafe then throw "unsupported unsafe axiom policy"
    let axiomInfo : PsKernelAxiomInfo := {
      base := { name := name, levelParams := params, type := ty }
      isUnsafe := false
    }
    return { st with declarations := .axiomDecl axiomInfo :: st.declarations }
  if let .ok payload := c0JsonObj j "thm" then
    c0ExportOnlyKeys j ["thm"]
    c0ExportOnlyKeys payload ["name", "levelParams", "type", "value", "all"]
    let nameId ← c0JsonNat payload "name"
    let allIds ← c0JsonNatList (← c0JsonObj payload "all")
    if !allIds.contains nameId then
      throw "malformed NDJSON theorem manifest"
    let name ← c0ExportName st nameId
    let params ← c0ExportNames st (← c0JsonObj payload "levelParams")
    let ty ← c0ExportExpr st (← c0JsonNat payload "type")
    let value ← c0ExportExpr st (← c0JsonNat payload "value")
    let theoremInfo : PsKernelTheoremInfo := {
      base := { name := name, levelParams := params, type := ty }
      value := value
    }
    return { st with declarations := .theoremDecl theoremInfo :: st.declarations }
  if let .ok payload := c0JsonObj j "opaque" then
    c0ExportOnlyKeys j ["opaque"]
    c0ExportOnlyKeys payload
      ["name", "levelParams", "type", "value", "isUnsafe", "all"]
    let nameId ← c0JsonNat payload "name"
    let allIds ← c0JsonNatList (← c0JsonObj payload "all")
    if !allIds.contains nameId then
      throw "malformed NDJSON opaque manifest"
    let name ← c0ExportName st nameId
    let params ← c0ExportNames st (← c0JsonObj payload "levelParams")
    let ty ← c0ExportExpr st (← c0JsonNat payload "type")
    let value ← c0ExportExpr st (← c0JsonNat payload "value")
    let isUnsafe ← (← c0JsonObj payload "isUnsafe").getBool?
    if isUnsafe then throw "unsupported unsafe opaque policy"
    let opaqueInfo : PsKernelOpaqueInfo := {
      base := { name := name, levelParams := params, type := ty }
      value := value
      isUnsafe := false
    }
    return { st with declarations := .opaqueDecl opaqueInfo :: st.declarations }
  if let .ok payload := c0JsonObj j "inductive" then
    c0ExportOnlyKeys j ["inductive"]
    let group ← c0ExportReadInductiveGroup st payload
    return { st with declarations :=
      .inductiveGroup group :: st.declarations }
  throw "unsupported NDJSON declaration tag"

/-- A supported record may be parsed once; everything else fails closed. -/
def c0ExportReadSubset (input : String) : Except String (List C0ExportDeclaration) := do
  let mut tables : C0ExportTables := {}
  for line in input.splitOn "\n" do
    if line != "" then
      let record ← Lean.Json.parse line
      tables ← c0ExportParseRecord tables record
  if !tables.header then throw "NDJSON missing pinned metadata"
  match tables.declarations with
  | [] => throw "NDJSON missing a supported declaration"
  | declarations => pure declarations.reverse

/-- Independent post-admission comparison with all emitted inductive,
    constructor and recursor metadata. No exported derived item gets admitted
    unchecked; any divergence declines the input and preserves the old env. -/
def c0ExportVerifyOrdinaryInductive
    (env : PsKernelEnvironment) (group : C0ExportInductiveGroup) :
    Except String Unit := do
  for expected in group.expectedTypes do
    let some (.inductInfo ty) :=
        psKernelEnvironmentFind env expected.base.name
      | throw "unsupported generated inductive type missing"
    if !c0ExportSameBase ty.base expected.base ||
        ty.numParams != expected.numParams ||
        ty.numIndices != expected.numIndices ||
        ty.numNested != expected.numNested ||
        ty.isRec != expected.isRec ||
        ty.isReflexive != expected.isReflexive ||
        ty.isUnsafe != expected.isUnsafe ||
        !c0ExportSameNames ty.all expected.all ||
        !c0ExportSameNames ty.ctors expected.ctors then
      throw "unsupported generated inductive metadata differs from exporter"
  for expectedCtor in group.expectedCtors do
    let some (.ctorInfo got) :=
        psKernelEnvironmentFind env expectedCtor.base.name
      | throw "unsupported generated constructor missing"
    if !c0ExportSameBase got.base expectedCtor.base ||
        !psKernelNameEq got.induct expectedCtor.induct ||
        got.cidx != expectedCtor.cidx ||
        got.numParams != expectedCtor.numParams ||
        got.numFields != expectedCtor.numFields ||
        got.isUnsafe != expectedCtor.isUnsafe then
      throw "unsupported generated constructor metadata differs from exporter"
  for expectedRec in group.expectedRecs do
    let some (.recInfo got) :=
        psKernelEnvironmentFind env expectedRec.base.name
      | throw "unsupported generated recursor missing"
    if !c0ExportSameBase got.base expectedRec.base ||
        !c0ExportSameNames got.all expectedRec.all ||
        got.numParams != expectedRec.numParams ||
        got.numIndices != expectedRec.numIndices ||
        got.numMotives != expectedRec.numMotives ||
        got.numMinors != expectedRec.numMinors ||
        got.k != expectedRec.k ||
        got.isUnsafe != expectedRec.isUnsafe ||
        got.rules.length != expectedRec.rules.length then
      throw "unsupported generated recursor metadata differs from exporter"
    for (a, b) in got.rules.zip expectedRec.rules do
      if !psKernelNameEq a.ctor b.ctor ||
          a.nFields != b.nFields || !psKernelExprEq a.rhs b.rhs then
        throw "unsupported generated recursor reduction rule differs"

/-- One declaration check, preserving the kernel's typed error category.
    The source recursive checker is the *only* acceptance authority. -/
def c0ExportCheckOne
    (env : PsKernelEnvironment)
    (info : C0ExportDeclaration)
    (fuel : Nat := 4096) : Except PsKernelError PsKernelEnvironment :=
  let result : Except String PsKernelEnvironment :=
    match info with
    | .axiomDecl value =>
        psKernelAddAxiom fuel env value 4096 psKernelLeanNatMaxSizeDefault
    | .definition value =>
        psKernelAddDefinition fuel env value 4096 psKernelLeanNatMaxSizeDefault
    | .theoremDecl value =>
        psKernelAddTheorem fuel env value 4096 psKernelLeanNatMaxSizeDefault
    | .opaqueDecl value =>
        psKernelAddOpaque fuel env value 4096 psKernelLeanNatMaxSizeDefault
    | .inductiveGroup group =>
        match group.source with
        | .ordinary decl =>
            psKernelAddSimpleInductive fuel env decl
              4096 psKernelLeanNatMaxSizeDefault
        | .mutual decl =>
            psKernelAddSimpleMutualInductive fuel env decl
              4096 psKernelLeanNatMaxSizeDefault
  match result with
  | .ok next =>
      match info with
      | .inductiveGroup group =>
          match c0ExportVerifyOrdinaryInductive next group with
          | .ok _ => .ok next
          | .error message => .error (.declinedUnsupported message)
      | _ => .ok next
  | .error message => .error (psKernelErrorFromMessage message)

/-- The retained batch replay is an independent test reference for online
    declaration admission. It never converts a resource failure to rejection. -/
def c0ExportCheckDefinitions (infos : List C0ExportDeclaration) :
    Except PsKernelError Bool := do
  let mut env := psKernelEnvironmentEmpty
  for info in infos do
    match c0ExportCheckOne env info with
    | .ok next => env := next
    | .error (.rejectedInvalid _) => return false
    | .error error => throw error
  return true

/-- The conformance harness distinguishes official acceptance/rejection from
    a test-adapter decline, malformed source and inconclusive checker work.
    A declined feature is never counted as an official kernel rejection. -/
inductive C0ExportVerdict where
  | accepted
  | rejected
  | unsupported
  | malformed
  | resourceExhausted
  | inconclusive
  deriving BEq, Repr

def c0ExportClassifyInputError (message : String) : C0ExportVerdict :=
  if message.startsWith "unsupported" ||
      message.startsWith "NDJSON exported by an unsupported" then
    .unsupported
  else
    .malformed

/-- Categorise kernel outcomes without confusing a fuel/size limit,
    unsupported semantics or an unknown diagnostic with invalid proof terms. -/
def c0ExportFromKernelError : PsKernelError → C0ExportVerdict
  | .rejectedInvalid _ => .rejected
  | .declinedUnsupported _ => .unsupported
  | .resourceExhausted _ _ => .resourceExhausted
  | .internalError _ => .inconclusive

/-- Retained whole-batch oracle: parses all source records before checking.
    Its distinct ordering is useful for detecting online replay drift. -/
def c0ExportVerdictBatch (input : String) : C0ExportVerdict :=
  match c0ExportReadSubset input with
  | .error message => c0ExportClassifyInputError message
  | .ok declarations =>
      match c0ExportCheckDefinitions declarations with
      | .ok true => .accepted
      | .ok false => .rejected
      | .error error => c0ExportFromKernelError error

/-- Decode source in order and admit each declaration immediately, rather
    than materialising and retaining a separate list of *all* declarations.
    Name, level and expression tables are still retained, and input is still
    read into a String; this is not yet a bounded-memory streaming importer.
    On the first invalid declaration, return rejected without admitting any
    later record. Every unknown input form fails closed. -/
def c0ExportVerdictOnline (input : String) (fuel : Nat := 4096) :
    C0ExportVerdict := Id.run do
  let mut tables : C0ExportTables := {}
  let mut env := psKernelEnvironmentEmpty
  let mut checkedCount := 0
  for line in input.splitOn "\n" do
    if line != "" then
      let .ok record := Lean.Json.parse line
        | return .malformed
      match c0ExportParseRecord tables record with
      | .error message => return c0ExportClassifyInputError message
      | .ok parsed =>
          -- The environment consumes declarations immediately, while indexed
          -- names/levels/expressions remain for subsequent source references.
          tables := { parsed with declarations := [] }
          for declaration in parsed.declarations do
            match c0ExportCheckOne env declaration fuel with
            | .ok next =>
                env := next
                checkedCount := checkedCount + 1
            | .error error => return c0ExportFromKernelError error
  if !tables.header || checkedCount == 0 then .malformed
  else .accepted

def c0ExportVerdictOf (input : String) : C0ExportVerdict :=
  c0ExportVerdictOnline input

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

/-- Cross-check category handling and bounded-fuel exhaustion without
    weakening the checked source rules to make an expected result pass. -/
def c0ExportOnlineOutcomes : IO Unit := do
  let simple ← IO.FS.readFile "test/C0OfficialAccept.ndjson"
  if c0ExportVerdictOnline simple 0 != .resourceExhausted then
    throw (IO.userError "C0 online replay misclassified fuel exhaustion")
  if c0ExportFromKernelError
      (.declinedUnsupported "unsupported feature") != .unsupported ||
      c0ExportFromKernelError
      (.resourceExhausted .fuel "budget exhausted") != .resourceExhausted ||
      c0ExportFromKernelError
      (.internalError "unknown") != .inconclusive then
    throw (IO.userError "C0 online verdict categories are not disjoint")
  let invalid ← IO.FS.readFile "test/C0OfficialChainReject.ndjson"
  if c0ExportVerdictOnline invalid != .rejected then
    throw (IO.userError "C0 online replay lost late invalid declaration")
  -- Supported source prefixes must preserve the first invalid judgment:
  -- later syntactically invalid records cannot turn it into acceptance.
  let withSuffix := invalid ++ "{broken-json}\n"
  if c0ExportVerdictOnline withSuffix != .rejected then
    throw (IO.userError "C0 online replay lost first failure precedence")

/-- The first actual pinned Init inductive verifies that derived
    constructor/recursor metadata is not an independently trusted source.
    Mutations must never be accepted or reclassified as kernel rejection. -/
def c0ExportRejectForgedInductiveMetadata : IO Unit := do
  let valid ← IO.FS.readFile "test/C0OfficialInitSubtypeAccept.ndjson"
  if c0ExportVerdictOnline valid != .accepted then
    throw (IO.userError "C0 could not replay real Init Subtype inductive")
  let mutations : List (String × String) := [
    ("constructor-field-count",
      valid.replace "\"numFields\":2" "\"numFields\":3"),
    ("recursor-field-count",
      valid.replace "\"nfields\":2" "\"nfields\":3"),
    ("recursor-rule-expression",
      valid.replace "\"rhs\":45" "\"rhs\":44"),
    ("nested-group-decline",
      valid.replace "\"numNested\":0" "\"numNested\":1"),
    ("type-name-manifest",
      valid.replace "\"all\":[1]" "\"all\":[]")
  ]
  for (label, input) in mutations do
    if input == valid then
      throw (IO.userError ("ineffective inductive metadata mutation: " ++ label))
    let verdict := c0ExportVerdictOnline input
    if verdict == .accepted || verdict == .rejected then
      throw (IO.userError s!"forged inductive metadata was treated as kernel verdict {label}: {repr verdict}")

def main : IO Unit := do
  c0ExportRejectLossyImports
  c0ExportRejectForgedInductiveMetadata
  c0ExportOnlineOutcomes
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
    ("C0OfficialChainReject.ndjson", false),
    ("C0OfficialAxiomAccept.ndjson", true),
    ("C0OfficialAxiomReject.ndjson", false),
    ("C0OfficialTheoremAccept.ndjson", true),
    ("C0OfficialTheoremReject.ndjson", false),
    ("C0OfficialOpaqueAccept.ndjson", true),
    ("C0OfficialOpaqueReject.ndjson", false),
    ("C0OfficialMixedAccept.ndjson", true),
    ("C0OfficialInitSubtypeAccept.ndjson", true),
    ("C0OfficialInitThreeInductivesAccept.ndjson", true),
    ("C0OfficialMixedReject.ndjson", false)
  ]
  for item in cases do
    let path := "test/" ++ item.fst
    let input ← IO.FS.readFile path
    let expected := if item.snd then C0ExportVerdict.accepted
      else C0ExportVerdict.rejected
    let actual := c0ExportVerdictOf input
    let reference := c0ExportVerdictBatch input
    if actual != reference then
      throw (IO.userError s!"C0 online/batch replay divergence {path}: {repr actual}, {repr reference}")
    if actual != expected then
      throw (IO.userError s!"C0/official NDJSON verdict mismatch {path}: {repr actual}")
  IO.println "C0_LEAN435 exact_official_ndjson_subset_replay=pass"
