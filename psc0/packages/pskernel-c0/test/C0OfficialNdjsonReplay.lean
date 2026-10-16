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
  | nested (decl : PsKernelSimpleMutualInductiveDecl)

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
  | quotientGroup (parts : List PsKernelQuotInfo)

-- Pinned Lean 4.35's 32-way PersistentArray bounds copying on shared
-- exporter snapshots; no kernel expression or checker semantics change.
-- These defaults are reachable only through a proven in-range lookup.
private instance : Inhabited PsKernelName := ⟨.anonymous⟩
private instance : Inhabited PsKernelLevel := ⟨.zero⟩
private instance : Inhabited PsKernelExpr := ⟨.bvar 0⟩

structure C0ExportTables where
  names : Lean.PersistentArray PsKernelName :=
    (Lean.PersistentArray.empty.push .anonymous)
  levels : Lean.PersistentArray PsKernelLevel :=
    (Lean.PersistentArray.empty.push .zero)
  exprs : Lean.PersistentArray PsKernelExpr := Lean.PersistentArray.empty
  declarations : List C0ExportDeclaration := []
  quotientParts : Nat := 0
  quotientPending : List PsKernelQuotInfo := []
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
  if h : idx < tables.names.size then
    .ok tables.names[idx]
  else
    .error s!"unknown NDJSON name handle {idx}"

def c0ExportLevel
    (tables : C0ExportTables) (idx : Nat) :
    Except String PsKernelLevel :=
  if h : idx < tables.levels.size then
    .ok tables.levels[idx]
  else
    .error s!"unknown NDJSON level handle {idx}"

def c0ExportExpr
    (tables : C0ExportTables) (idx : Nat) :
    Except String PsKernelExpr :=
  if h : idx < tables.exprs.size then
    .ok tables.exprs[idx]
  else
    .error s!"unknown NDJSON expression handle {idx}"

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

/-- Exported Quot is four records, not four independent axioms. The
    official native kernel initializes the whole package once after Eq is
    checked. Each source record must agree with that generated environment. -/
def c0ExportQuotKind (s : String) : Except String PsKernelQuotKind :=
  match s with
  | "type" => .ok .typeQ
  | "ctor" => .ok .ctorQ
  | "lift" => .ok .liftQ
  | "ind" => .ok .indQ
  | _ => .error "unsupported NDJSON quotient declaration kind"

def c0ExportSameQuotKind (a b : PsKernelQuotKind) : Bool :=
  match a, b with
  | .typeQ, .typeQ => true
  | .ctorQ, .ctorQ => true
  | .liftQ, .liftQ => true
  | .indQ, .indQ => true
  | _, _ => false

def c0ExportReadQuot
    (st : C0ExportTables) (j : Lean.Json) :
    Except String PsKernelQuotInfo := do
  c0ExportOnlyKeys j ["name", "levelParams", "type", "kind"]
  let name ← c0ExportName st (← c0JsonNat j "name")
  let levels ← c0ExportNames st (← c0JsonObj j "levelParams")
  let type ← c0ExportExpr st (← c0JsonNat j "type")
  let kind ← c0ExportQuotKind (← c0JsonString j "kind")
  return { base := { name := name, levelParams := levels, type := type },
           kind := kind }

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
  let hasNested := types.any (fun t => t.numNested != 0)
  if hasNested && types.length != 1 then
    throw "unsupported NDJSON nested mutual group"
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
  -- Ordinary and simple mutual groups have one conventional .rec name
  -- per type. Nested preprocessing may produce extra recursors or different
  -- auxiliary names: do not guess their spelling here. Instead, every
  -- exported recursor is checked *after* independent native generation,
  -- including its type, motive/indices, constructor rules and safety.
  if !hasNested && !c0ExportSameNames recNames generatedNames then
    throw "unsupported NDJSON recursor family is not canonical"
  let toCtor (c : PsKernelConstructorInfo) :
      PsKernelSimpleConstructorDecl :=
    { name := c.base.name, type := c.base.type }
  let mutualDecl : PsKernelSimpleMutualInductiveDecl := {
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
  let source : C0ExportInductiveSource :=
    if hasNested then
      -- The native nested-admission subsystem independently discovers
      -- auxiliary families and checks its restoration; metadata remains
      -- a post-admission comparator, never an axiom.
      .nested mutualDecl
    else if types.length == 1 then
      .ordinary {
        levelParams := first.base.levelParams
        name := first.base.name
        type := first.base.type
        ctors := expectedCtors.map toCtor
        isUnsafe := false
        numParams := first.numParams
      }
    else
      .mutual mutualDecl
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
    -- Consume the table fields before pushing: no stale owner of the
    -- growing array is needed after its referenced name was decoded.
    let ⟨names, levels, exprs, declarations, quotientParts, quotientPending, header⟩ := st
    return ⟨names.push newName, levels, exprs, declarations,
      quotientParts, quotientPending, header⟩
  if let .ok value := c0JsonObj j "il" then
    let idx ← value.getNat?
    if idx != st.levels.size then throw "NDJSON level IDs not sequential"
    let newLevel ← c0ExportDecodeLevel st j
    let ⟨names, levels, exprs, declarations, quotientParts, quotientPending, header⟩ := st
    return ⟨names, levels.push newLevel, exprs, declarations,
      quotientParts, quotientPending, header⟩
  if let .ok value := c0JsonObj j "ie" then
    let idx ← value.getNat?
    if idx != st.exprs.size then throw "NDJSON expression IDs not sequential"
    let newExpr ← c0ExportDecodeExpr st j
    let ⟨names, levels, exprs, declarations, quotientParts, quotientPending, header⟩ := st
    return ⟨names, levels, exprs.push newExpr, declarations,
      quotientParts, quotientPending, header⟩
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
  if let .ok payload := c0JsonObj j "quot" then
    c0ExportOnlyKeys j ["quot"]
    let info ← c0ExportReadQuot st payload
    let expected : List PsKernelQuotKind :=
      [.typeQ, .ctorQ, .liftQ, .indQ]
    let some orderedKind := expected[st.quotientParts]?
      | throw "malformed NDJSON extra quotient declaration"
    if !c0ExportSameQuotKind info.kind orderedKind then
      throw "unsupported NDJSON noncanonical quotient declaration order"
    if st.quotientParts == 3 then
      return { st with
        quotientParts := 4
        quotientPending := []
        declarations := .quotientGroup
          (st.quotientPending.reverse ++ [info]) :: st.declarations }
    else
      return { st with
        quotientParts := st.quotientParts + 1
        quotientPending := info :: st.quotientPending }
  throw "unsupported NDJSON declaration tag"

/-- A supported record may be parsed once; everything else fails closed. -/
def c0ExportReadSubset (input : String) : Except String (List C0ExportDeclaration) := do
  let mut tables : C0ExportTables := {}
  for line in input.splitOn "\n" do
    if line != "" then
      let record ← Lean.Json.parse line
      tables ← c0ExportParseRecord tables record
  if !tables.header then throw "NDJSON missing pinned metadata"
  if tables.quotientParts != 0 && tables.quotientParts != 4 then
    throw "malformed NDJSON incomplete quotient group"
  match tables.declarations with
  | [] => throw "NDJSON missing a supported declaration"
  | declarations => pure declarations.reverse

/-- Independent metadata fidelity: each exported generated declaration
    must exactly match a declaration produced by native kernel admission.
    Report the first mismatching *field family* for real-library conformance
    diagnostics; no comparison here grants typing or admits an export axiom. -/
def c0ExportVerifyOrdinaryInductive
    (env : PsKernelEnvironment) (group : C0ExportInductiveGroup) :
    Except String Unit := do
  for expected in group.expectedTypes do
    let some (.inductInfo got) :=
        psKernelEnvironmentFind env expected.base.name
      | throw "unsupported generated inductive type missing"
    if !c0ExportSameBase got.base expected.base then
      throw "unsupported generated inductive name/universes/type mismatch"
    if got.numParams != expected.numParams ||
        got.numIndices != expected.numIndices ||
        got.numNested != expected.numNested then
      throw "unsupported generated inductive parameter/index/nested count mismatch"
    if got.isRec != expected.isRec ||
        got.isReflexive != expected.isReflexive ||
        got.isUnsafe != expected.isUnsafe then
      throw "unsupported generated inductive recursion/reflexivity/safety mismatch"
    if !c0ExportSameNames got.all expected.all ||
        !c0ExportSameNames got.ctors expected.ctors then
      throw "unsupported generated inductive family/constructor manifest mismatch"
  for expectedCtor in group.expectedCtors do
    let some (.ctorInfo got) :=
        psKernelEnvironmentFind env expectedCtor.base.name
      | throw "unsupported generated constructor missing"
    if !c0ExportSameBase got.base expectedCtor.base then
      throw "unsupported generated constructor name/universes/type mismatch"
    if !psKernelNameEq got.induct expectedCtor.induct ||
        got.cidx != expectedCtor.cidx ||
        got.numParams != expectedCtor.numParams ||
        got.numFields != expectedCtor.numFields ||
        got.isUnsafe != expectedCtor.isUnsafe then
      throw "unsupported generated constructor owner/index/fields/safety mismatch"
  for expectedRec in group.expectedRecs do
    let some (.recInfo got) :=
        psKernelEnvironmentFind env expectedRec.base.name
      | throw "unsupported generated recursor missing"
    if !c0ExportSameBase got.base expectedRec.base then
      throw "unsupported generated recursor name/universes/type mismatch"
    if !c0ExportSameNames got.all expectedRec.all ||
        got.numParams != expectedRec.numParams ||
        got.numIndices != expectedRec.numIndices ||
        got.numMotives != expectedRec.numMotives ||
        got.numMinors != expectedRec.numMinors then
      throw "unsupported generated recursor family/arity mismatch"
    if got.k != expectedRec.k ||
        got.isUnsafe != expectedRec.isUnsafe then
      throw "unsupported generated recursor K/safety mismatch"
    if got.rules.length != expectedRec.rules.length then
      throw "unsupported generated recursor reduction rule count mismatch"
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
        | .nested decl =>
            psKernelAddSimpleNestedInductive fuel env decl
              4096 psKernelLeanNatMaxSizeDefault
    | .quotientGroup _ =>
        psKernelAddQuot env
  match result with
  | .ok next =>
      match info with
      | .inductiveGroup group =>
          match c0ExportVerifyOrdinaryInductive next group with
          | .ok _ => .ok next
          | .error message => .error (.declinedUnsupported message)
      | .quotientGroup group =>
          let metadataAgrees := group.length == 4 && group.all (fun expected =>
            match psKernelEnvironmentFind next expected.base.name with
            | some (.quotInfo got) =>
                c0ExportSameBase got.base expected.base &&
                  c0ExportSameQuotKind got.kind expected.kind
            | _ => false)
          if metadataAgrees then .ok next
          else .error (.declinedUnsupported
            "exported quotient package differs from generated checked Quot")
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

/-- Shared, pure incremental checking state; only the official source
    expression tables and admitted environment are retained. -/
structure C0ExportOnlineState where
  tables : C0ExportTables := {}
  environment : PsKernelEnvironment := psKernelEnvironmentEmpty
  checkedCount : Nat := 0

/-- An error retains only its actual reason and, for a checker error,
    the exact environment and declaration at the failed admission. Successful
    records need not keep an old copy of the huge NDJSON expression table merely
    to support a future diagnostic. This is not part of trusted kernel state. -/
inductive C0ExportStepFailure where
  | malformedJson (message : String)
  | invalidInput (message : String)
  | checked (environment : PsKernelEnvironment)
      (declaration : C0ExportDeclaration) (error : PsKernelError)

def c0ExportStepFailureVerdict : C0ExportStepFailure → C0ExportVerdict
  | .malformedJson _ => .malformed
  | .invalidInput message => c0ExportClassifyInputError message
  | .checked _ _ error => c0ExportFromKernelError error

/-- Parse one record with exclusive ownership of the growing tables.
    Source checking and admission are unchanged; failure carries diagnostics
    so callers never retain a second table owner on the successful hot path. -/
def c0ExportStepDetailed
    (state : C0ExportOnlineState) (raw : String) (fuel : Nat) :
    Except C0ExportStepFailure C0ExportOnlineState := do
  let ⟨tables, initialEnv, initialChecked⟩ := state
  let record ← match Lean.Json.parse raw with
    | .ok value => pure value
    | .error message => throw (.malformedJson message)
  let parsed ← match c0ExportParseRecord tables record with
    | .ok next => pure next
    | .error message => throw (.invalidInput message)
  let mut env := initialEnv
  let mut checked := initialChecked
  for declaration in parsed.declarations do
    match c0ExportCheckOne env declaration fuel with
    | .ok next =>
        env := next
        checked := checked + 1
    | .error error => throw (.checked env declaration error)
  return {
    tables := { parsed with declarations := [] }
    environment := env
    checkedCount := checked
  }

/-- Preserve the original public pure verdict and transition API. -/
def c0ExportStep
    (state : C0ExportOnlineState) (raw : String) (fuel : Nat) :
    Except C0ExportVerdict C0ExportOnlineState :=
  match c0ExportStepDetailed state raw fuel with
  | .ok next => .ok next
  | .error failure => .error (c0ExportStepFailureVerdict failure)

def c0ExportFinish (state : C0ExportOnlineState) : C0ExportVerdict :=
  if !state.tables.header || state.checkedCount == 0 then .malformed
  else if state.tables.quotientParts != 0 &&
      state.tables.quotientParts != 4 then .malformed
  else .accepted

/-- In-memory regression entry point shares the exact same step semantics
    as the true line-by-line file path below. -/
def c0ExportVerdictOnline (input : String) (fuel : Nat := 4096) :
    C0ExportVerdict := Id.run do
  let mut state : C0ExportOnlineState := {}
  for line in input.splitOn "\n" do
    if line != "" then
      match c0ExportStep state line fuel with
      | .error verdict => return verdict
      | .ok next => state := next
  return c0ExportFinish state

/-- Bounded expression rendering for test-only DefEq mismatch investigation.
    The kernel and its proof receipts never consult these summaries. -/
def c0ExportMismatchTerm : Nat → PsKernelExpr → String
  | 0, _ => "…"
  | _ + 1, .const name _ => psKernelMutualDiagnosticName name
  | _ + 1, .fvar name => "fvar:" ++ psKernelMutualDiagnosticName name
  | _ + 1, .mvar name => "mvar:" ++ psKernelMutualDiagnosticName name
  | _ + 1, .bvar idx => "#" ++ toString idx
  | _ + 1, .sort _ => "Sort"
  | n + 1, .app fn arg =>
      "(" ++ c0ExportMismatchTerm n fn ++ " " ++
      c0ExportMismatchTerm n arg ++ ")"
  | n + 1, .forallE _ ty body _ =>
      "(Pi " ++ c0ExportMismatchTerm n ty ++ ". " ++
      c0ExportMismatchTerm n body ++ ")"
  | n + 1, .lam _ ty body _ =>
      "(Lam " ++ c0ExportMismatchTerm n ty ++ ". " ++
      c0ExportMismatchTerm n body ++ ")"
  | n + 1, .letE _ ty _ body _ =>
      "(Let :" ++ c0ExportMismatchTerm n ty ++ ". " ++
      c0ExportMismatchTerm n body ++ ")"
  | _ + 1, .lit _ => "literal"
  | n + 1, .mdata _ body => c0ExportMismatchTerm n body
  | n + 1, .proj name idx value =>
      "(Proj " ++ psKernelMutualDiagnosticName name ++ "." ++
      toString idx ++ " " ++ c0ExportMismatchTerm n value ++ ")"

/-- Dissect outer application arguments without additional conversion
    or speculative reductions. A witness is printed only after rejection. -/
def c0ExportMismatchArgument (xs : List PsKernelExpr) (index : Nat) :
    String :=
  match psKernelExprListGet xs index with
  | some value => c0ExportMismatchTerm 10 value
  | none => "<missing>"

def c0ExportMismatchOutline (expr : PsKernelExpr) : String :=
  let head := psKernelExprGetAppFn expr
  let args := psKernelExprGetAppArgs expr
  "head=" ++ c0ExportMismatchTerm 3 head ++
  " argc=" ++ toString (psKernelExprListLength args) ++
  " arg0=" ++ c0ExportMismatchArgument args 0 ++
  " arg1=" ++ c0ExportMismatchArgument args 1 ++
  " arg2=" ++ c0ExportMismatchArgument args 2

/-- Non-accepting diagnostic for the FIRST false DefEq application.
    Compare the corresponding head and argument pairs independently under
    the SAME source context/state. These additional observations never
    change the checker verdict, its environment or its trusted caches.
    Distinguishing Pi-type beta from function-eta is essential for the
    real Lean 4.35 Init record-86,383 false rejection. -/
def c0ExportMismatchDefEqComponent
    (defeq :
      PsKernelCheckerContext → PsKernelCheckerState →
        PsKernelExpr → PsKernelExpr →
          Except String (Bool × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (index : Nat) : String :=
  let lhs := psKernelExprGetAppArgs left
  let rhs := psKernelExprGetAppArgs right
  match psKernelExprListGet lhs index, psKernelExprListGet rhs index with
  | some a, some b =>
      let verdict := match defeq context state a b with
        | .ok (true, _) => "equal"
        | .ok (false, _) => "different"
        | .error e => "error:" ++ e
      "arg" ++ toString index ++ "=" ++ verdict ++
        " lhs=" ++ c0ExportMismatchTerm 5 a ++
        " rhs=" ++ c0ExportMismatchTerm 5 b
  | _, _ => "arg" ++ toString index ++ "=missing"

def c0ExportMismatchDefEqComponents
    (defeq :
      PsKernelCheckerContext → PsKernelCheckerState →
        PsKernelExpr → PsKernelExpr →
          Except String (Bool × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) : String :=
  let headLeft := psKernelExprGetAppFn left
  let headRight := psKernelExprGetAppFn right
  let headVerdict := match defeq context state headLeft headRight with
    | .ok (true, _) => "equal"
    | .ok (false, _) => "different"
    | .error e => "error:" ++ e
  "head=" ++ headVerdict ++
    " | " ++ c0ExportMismatchDefEqComponent defeq context state left right 0 ++
    " | " ++ c0ExportMismatchDefEqComponent defeq context state left right 1 ++
    " | " ++ c0ExportMismatchDefEqComponent defeq context state left right 2

/-- Only invoked *after* authoritative rejection, never for admission.
    Diagnose whether the theorem's type or proof body failed and compare the
    optimized checked-application engine against its original source-owned
    syntax-directed checker, with identical environment, local context, fuel
    and DefEq/WHNF callbacks. No reference result changes the kernel verdict. -/
def c0ExportDiagnosticTheoremMismatch
    (environment : PsKernelEnvironment)
    (info : PsKernelTheoremInfo)
    (fuel : Nat) : IO Unit := do
  let initial := psKernelMkCheckerSession environment
    info.base.levelParams .safe 4096 psKernelLeanNatMaxSizeDefault
  match psKernelCheckConstantBaseWithSession fuel initial info.base with
  | .error why =>
      IO.println ("C0_REAL_THEOREM_FAILURE_STAGE=type " ++ why)
  | .ok afterHeader =>
      match psKernelSessionIsProp fuel afterHeader info.base.type with
      | .error why =>
          IO.println ("C0_REAL_THEOREM_FAILURE_STAGE=proposition " ++ why)
      | .ok (_, proofSession) =>
          match psKernelSessionCheck fuel proofSession info.value with
          | .ok _ =>
              IO.println "C0_REAL_THEOREM_FAILURE_STAGE=post-check"
          | .error why =>
              IO.println ("C0_REAL_THEOREM_FAILURE_STAGE=proof " ++ why)
              let defeq := psKernelIsDefEqWithFuel fuel
              let whnf := psKernelWhnfWithRecursorFuel fuel defeq
              match psKernelInferCoreWithFuel fuel whnf defeq
                  proofSession.context proofSession.state info.value false with
              | .ok _ =>
                  IO.println "C0_REAL_THEOREM_REFERENCE_CHECK=accepted"
              | .error historical =>
                  IO.println
                    ("C0_REAL_THEOREM_REFERENCE_CHECK=rejected " ++ historical)
                  -- A first false DefEq comparison is a diagnostic candidate,
                  -- not necessarily the final source of the failed theorem.
                  -- This re-evaluation is never used for admission.
                  let witnessDefEq := fun
                      (ctx : PsKernelCheckerContext)
                      (st : PsKernelCheckerState)
                      (left right : PsKernelExpr) =>
                    match defeq ctx st left right with
                    | .ok (false, _) =>
                        .error ("first-false lhs=" ++
                          c0ExportMismatchTerm 7 left ++
                          " rhs=" ++ c0ExportMismatchTerm 7 right ++
                          " | lhs-parts: " ++ c0ExportMismatchOutline left ++
                          " | rhs-parts: " ++ c0ExportMismatchOutline right ++
                          " | components: " ++
                            c0ExportMismatchDefEqComponents defeq ctx st
                              left right)
                    | result => result
                  let witnessWhnf := psKernelWhnfWithRecursorFuel fuel witnessDefEq
                  match psKernelInferCoreWithFuel fuel witnessWhnf witnessDefEq
                      proofSession.context proofSession.state info.value false with
                  | .ok _ =>
                      IO.println "C0_REAL_THEOREM_FIRST_FALSE=none"
                  | .error reason =>
                      IO.println ("C0_REAL_THEOREM_FIRST_FALSE=" ++ reason)

/-- Label source checker substeps *after* a rejected inductive bundle.
    This uses the existing authoritative checking helpers, on a disposable
    diagnostic environment, without admitting any proof or influencing the
    original declaration outcome. In particular, an exported recursor is
    never imported as an axiom to explain a rejection. -/
def c0ExportStage {α : Type} (stage : String) :
    Except String α → Except String α
  | .ok result => .ok result
  | .error reason => .error (stage ++ ": " ++ reason)

/-- A pure diagnostic probe of the first false conversion in the
    original checked source path; invoked only for a rejected constructor
    type, never in the admitted kernel computation. -/
def c0ExportDiagnoseCtorFirstFalse
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) : String :=
  let defeq := psKernelIsDefEqWithFuel fuel
  let witnessDefEq := fun
      (ctx : PsKernelCheckerContext)
      (st : PsKernelCheckerState)
      (left right : PsKernelExpr) =>
    match defeq ctx st left right with
    | .ok (false, _) =>
        .error ("first-false lhs=" ++ c0ExportMismatchTerm 7 left ++
          " rhs=" ++ c0ExportMismatchTerm 7 right ++
          " | components=" ++
          c0ExportMismatchDefEqComponents defeq ctx st left right)
    | result => result
  let witnessWhnf := psKernelWhnfWithRecursorFuel fuel witnessDefEq
  match psKernelInferCoreWithFuel fuel witnessWhnf witnessDefEq
      session.context session.state expr false with
  | .error reason => reason
  | .ok _ => "no first-false in independent source callback recheck"

/-- Identify the *field index* and original checked suboperation that
    produced a constructor rejection, without changing the authoritative
    admission result. Mirrors the source field-opening sequence on a discarded
    session; none of its intermediate environments are ever published. -/
def c0ExportDiagnoseFieldSequence
    (fuel : Nat) :
    PsKernelCheckerSession ->
    PsKernelName ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    Nat ->
    PsKernelLevel ->
    PsKernelExpr ->
    Nat ->
    Except String String :=
  match fuel with
  | 0 =>
      fun _ _ _ _ _ _ _ _ =>
        .error "diagnostic field-opening budget exhausted"
  | remaining + 1 =>
      fun session target levels params numIndices resultLevel ty fieldIndex => do
        let reduced ← c0ExportStage
          ("field[" ++ toString fieldIndex ++ "]/whnf")
          (psKernelSessionWhnf remaining session ty)
        match reduced.1 with
        | .forallE userName domain body binderInfo =>
            let domainType ←
              match psKernelSessionCheck remaining reduced.2 domain with
              | .ok result => pure result
              | .error original =>
                  throw ("field[" ++ toString fieldIndex ++
                    "]/full_domain: " ++ original ++
                    " | domain=" ++ c0ExportMismatchTerm 9 domain ++
                    " | first-false=" ++
                    c0ExportDiagnoseCtorFirstFalse remaining reduced.2 domain)
            let fieldSort ← c0ExportStage
              ("field[" ++ toString fieldIndex ++ "]/sort")
              (psKernelSessionEnsureSort remaining domainType.2 domainType.1)
            if !(psKernelLevelLe fieldSort.1 resultLevel ||
                psKernelLevelNormalizesToZero resultLevel) then
              throw ("field[" ++ toString fieldIndex ++
                "]/universe: constructor field universe is too large")
            let opened := psKernelSessionWithLocal fieldSort.2 userName
              (psKernelExprConsumeTypeAnnotations domain) binderInfo
            let analysis ← c0ExportStage
              ("field[" ++ toString fieldIndex ++ "]/positivity")
              (psKernelAnalyzeSimpleRecursiveArgument remaining opened.2
                target levels params numIndices domain)
            let nextLocals := psKernelLocalContextWithNextIndex
              opened.2.context.localContext
              analysis.session.context.localContext.nextIndex
            let child := PsKernelCheckerSession.mk
              (psKernelCheckerContextWithLocalContext
                opened.2.context nextLocals)
              analysis.session.state
            c0ExportDiagnoseFieldSequence remaining child target levels
              params numIndices resultLevel
              (psKernelExprInstantiate1 body (.fvar opened.1))
              (fieldIndex + 1)
        | _ =>
            pure ("all " ++ toString fieldIndex ++
              " constructor field opening stages succeeded")

/-- A failure-only diagnostic of the original safe definition stages.
    A failed record is never admitted; this repeats the source checks on an
    immutable, disposable environment to locate the first resource boundary. -/
def c0ExportDiagnoseDefinitionStages
    (env : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (fuel : Nat) : Except String String := do
  let session := psKernelMkCheckerSession env value.base.levelParams
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let header ← c0ExportStage "header/full_check"
    (psKernelCheckConstantBaseWithSession fuel session value.base)
  let _ ← c0ExportStage "body/closure"
    (psKernelCheckNoMVarNoFVar value.value)
  let _ ← c0ExportStage "body/universes"
    (psKernelCheckLevelParams value.value value.base.levelParams)
  let inferred ← c0ExportStage "body/full_check"
    (psKernelSessionCheck fuel header value.value)
  let eq ← c0ExportStage "body/defeq"
    (psKernelSessionIsDefEq fuel inferred.2 inferred.1 value.base.type)
  if eq.1 then
    return "staged source checking accepted unexpectedly"
  else
    throw "body/defeq=false"

/-- Failure-only comparison of the two disputed terms under the *same*
    original checker context, state and source resource policy. Distinguishes
    cheap-projection core WHNF, full core WHNF, and public WHNF without
    inserting any equality or reduction into the accepting checker. -/
def c0ExportDescribeWhnfProbe
    (result : Except String (PsKernelExpr × PsKernelCheckerState)) :
    String :=
  match result with
  | .error error => "error=" ++ error
  | .ok (reduced, _) => "ok=" ++ c0ExportMismatchTerm 6 reduced

/-- Locate the first exact syntactic disagreement through common app and
    binder spines. This is a bounded *diagnostic only*, never a DefEq rule:
    binder names are ignored by the existing exact kernel Expr equality. -/
def c0ExportFirstSyntacticDifference
    (depth : Nat)
    (context : PsKernelCheckerContext) :
    PsKernelExpr -> PsKernelExpr -> String :=
  match depth with
  | 0 =>
      fun lhs rhs => "depth_limit lhs=" ++ c0ExportMismatchTerm 5 lhs ++
        " rhs=" ++ c0ExportMismatchTerm 5 rhs
  | remaining + 1 =>
      let smaller := c0ExportFirstSyntacticDifference remaining context
      fun lhs rhs =>
        if psKernelExprEq lhs rhs then "same"
        else
          match lhs, rhs with
          | .app lf la, .app rf ra =>
              if psKernelExprEq lf rf then
                "app.arg/" ++ smaller la ra
              else
                "app.fn/" ++ smaller lf rf
          | .lam _ lt lb _, .lam _ rt rb _ =>
              if psKernelExprEq lt rt then
                "lambda.body/" ++ smaller lb rb
              else
                "lambda.domain/" ++ smaller lt rt
          | .forallE _ lt lb _, .forallE _ rt rb _ =>
              if psKernelExprEq lt rt then
                "forall.body/" ++ smaller lb rb
              else
                "forall.domain/" ++ smaller lt rt
          | .letE _ lt lv lb _, .letE _ rt rv rb _ =>
              if !psKernelExprEq lt rt then
                "let.type/" ++ smaller lt rt
              else if !psKernelExprEq lv rv then
                "let.value/" ++ smaller lv rv
              else
                "let.body/" ++ smaller lb rb
          | .mdata _ le, .mdata _ re =>
              "mdata.body/" ++ smaller le re
          | .proj _ _ le, .proj _ _ re =>
              "proj.body/" ++ smaller le re
          | _, .fvar name =>
              let bindingInfo :=
                match psKernelLocalContextFind context.localContext name with
                | .none => "binding=missing"
                | .some declaration =>
                    match psKernelLocalDeclValue declaration with
                    | .none => "binding=ordinary"
                    | .some value =>
                        "binding=let value=" ++
                          c0ExportMismatchTerm 7 value ++
                          " lhs_matches_value=" ++
                          toString (psKernelExprEq lhs value)
              "leaf lhs=" ++ c0ExportMismatchTerm 6 lhs ++
                " rhs=" ++ c0ExportMismatchTerm 6 rhs ++
                " | " ++ bindingInfo
          | _, _ =>
              "leaf lhs=" ++ c0ExportMismatchTerm 6 lhs ++
                " rhs=" ++ c0ExportMismatchTerm 6 rhs

/-- Inspect two candidate proof applications under an *opened and scoped*
    binder context. This is a discarded first-failure diagnostic: even a
    positive type/proposition observation does not admit or cache a term. -/
def c0ExportProofArgumentWitness
    (fuel : Nat)
    (ctx : PsKernelCheckerContext)
    (st : PsKernelCheckerState)
    (lhs rhs : PsKernelExpr) : String :=
  let session := PsKernelCheckerSession.mk ctx st
  match psKernelSessionCheck fuel session lhs with
  | .error reason =>
      "left_check_error=" ++ reason
  | .ok (leftType, afterLeft) =>
      match psKernelSessionCheck fuel afterLeft rhs with
      | .error reason => "right_check_error=" ++ reason
      | .ok (rightType, afterRight) =>
          let equalTypes := psKernelExprEq leftType rightType
          let leftProp :=
            match psKernelSessionIsProp fuel afterRight leftType with
            | .ok (yes, _) => toString yes
            | .error err => "error:" ++ err
          let rightProp :=
            match psKernelSessionIsProp fuel afterRight rightType with
            | .ok (yes, _) => toString yes
            | .error err => "error:" ++ err
          let typeCompare :=
            if equalTypes then "identical"
            else
              match psKernelSessionIsDefEq fuel afterRight
                  leftType rightType with
              | .ok (yes, _) => toString yes
              | .error err => "error:" ++ err
          "left_type=" ++ c0ExportMismatchTerm 7 leftType ++
            " right_type=" ++ c0ExportMismatchTerm 7 rightType ++
            " equal_types=" ++ toString equalTypes ++
            " left_is_prop=" ++ leftProp ++
            " right_is_prop=" ++ rightProp ++
            " type_defeq=" ++ typeCompare

/-- Follow the first *open-binder-safe* syntactic divergence. Source binders
    are instantiated with a shared fresh checker local before examining their
    bodies: type inference on a raw de Bruijn body would be ill scoped.
    At two distinct constant-headed applications, report independently
    checked types and whether the proof-irrelevance premise holds. -/
def c0ExportScopedProofDifference
    (depth : Nat)
    (fuel : Nat) :
    PsKernelCheckerContext -> PsKernelCheckerState ->
    PsKernelExpr -> PsKernelExpr -> String :=
  match depth with
  | 0 =>
      fun _ _ _ _ => "scoped_diagnostic_depth_exhausted"
  | remaining + 1 =>
      let descend := c0ExportScopedProofDifference remaining fuel
      fun ctx st lhs rhs =>
        if psKernelExprEq lhs rhs then "same"
        else
          match lhs, rhs with
          | .app lf la, .app rf ra =>
              if psKernelExprEq lf rf then
                "app.arg/" ++ descend ctx st la ra
              else
                match psKernelExprGetAppFn lhs,
                      psKernelExprGetAppFn rhs with
                | .const leftName _, .const rightName _ =>
                    if psKernelNameEq leftName rightName then
                      "app.fn/" ++ descend ctx st lf rf
                    else
                      "proof_head_left=" ++ c0ExportMismatchTerm 3
                        (psKernelExprGetAppFn lhs) ++
                      " proof_head_right=" ++ c0ExportMismatchTerm 3
                        (psKernelExprGetAppFn rhs) ++
                      " | " ++
                      c0ExportProofArgumentWitness fuel ctx st lhs rhs
                | _, _ => "app.fn/" ++ descend ctx st lf rf
          | .lam name lt lb bi, .lam _ rt rb _ =>
              if psKernelExprEq lt rt then
                let fresh := psKernelCheckerStateFreshName st name
                let openedLocal := psKernelLocalContextAddLocal
                  ctx.localContext fresh.1 name lt bi
                let child := psKernelCheckerContextWithLocalContext ctx openedLocal
                "lambda.body/" ++ descend child fresh.2
                  (psKernelExprInstantiate1 lb (.fvar fresh.1))
                  (psKernelExprInstantiate1 rb (.fvar fresh.1))
              else "lambda.domain/" ++ descend ctx st lt rt
          | .forallE name lt lb bi, .forallE _ rt rb _ =>
              if psKernelExprEq lt rt then
                let fresh := psKernelCheckerStateFreshName st name
                let openedLocal := psKernelLocalContextAddLocal
                  ctx.localContext fresh.1 name lt bi
                let child := psKernelCheckerContextWithLocalContext ctx openedLocal
                "forall.body/" ++ descend child fresh.2
                  (psKernelExprInstantiate1 lb (.fvar fresh.1))
                  (psKernelExprInstantiate1 rb (.fvar fresh.1))
              else "forall.domain/" ++ descend ctx st lt rt
          | .letE name lt lv lb _, .letE _ rt rv rb _ =>
              if psKernelExprEq lt rt && psKernelExprEq lv rv then
                let opened := psKernelCheckerContextWithLet
                  ctx name lt lv
                "let.body/" ++ descend opened.2 st
                  (psKernelExprInstantiate1 lb (.fvar opened.1))
                  (psKernelExprInstantiate1 rb (.fvar opened.1))
              else if psKernelExprEq lt rt then
                "let.value/" ++ descend ctx st lv rv
              else "let.type/" ++ descend ctx st lt rt
          | .mdata _ le, .mdata _ re =>
              "mdata.body/" ++ descend ctx st le re
          | .proj _ _ le, .proj _ _ re =>
              "proj.body/" ++ descend ctx st le re
          | _, _ =>
              "different_shapes left=" ++ c0ExportMismatchTerm 5 lhs ++
              " right=" ++ c0ExportMismatchTerm 5 rhs

/-- First nontrivial application argument in two full-WHNF expressions.
    This is a discarded, source-owned diagnostic: compare the shared head,
    then check arguments left-to-right in the same order as Lean 4.35's
    type_checker::is_def_eq_app, threading only the genuine source state. -/
def c0ExportProbeFirstAppMismatchAux
    (defeq :
      PsKernelCheckerContext -> PsKernelCheckerState ->
      PsKernelExpr -> PsKernelExpr ->
      Except String (Bool × PsKernelCheckerState))
    (ctx : PsKernelCheckerContext)
    (st : PsKernelCheckerState) :
    Nat -> List PsKernelExpr -> List PsKernelExpr -> String
  | _, [], [] => "all_arguments_equal"
  | i, lhs :: leftRest, rhs :: rightRest =>
      if psKernelExprEq lhs rhs then
        c0ExportProbeFirstAppMismatchAux defeq ctx st (i+1) leftRest rightRest
      else
        let detailLabel := "argument[" ++ toString i ++
          "] lhs=" ++ c0ExportMismatchTerm 8 lhs ++
          " rhs=" ++ c0ExportMismatchTerm 8 rhs
        match defeq ctx st lhs rhs with
        | .ok (true, updated) =>
            detailLabel ++ " result=true | " ++
              c0ExportProbeFirstAppMismatchAux defeq ctx updated
                (i+1) leftRest rightRest
        | .ok (false, _) => detailLabel ++ " result=false"
        | .error error =>
            detailLabel ++ " error=" ++ error ++
              " | first_syntax_path=" ++
                c0ExportFirstSyntacticDifference 48 ctx lhs rhs
  | _, _, _ => "different_argument_counts"

def c0ExportProbeFirstAppMismatch
    (fuel : Nat)
    (ctx : PsKernelCheckerContext)
    (st : PsKernelCheckerState)
    (lhs rhs : PsKernelExpr) : String :=
  let defeq := psKernelIsDefEqWithFuel fuel
  let leftSpine := psKernelExprGetAppFnArgs lhs
  let rightSpine := psKernelExprGetAppFnArgs rhs
  match defeq ctx st leftSpine.fst rightSpine.fst with
  | .error error => "head_error=" ++ error
  | .ok (false, _) => "heads_not_definitionally_equal"
  | .ok (true, updated) =>
      "head_equal | " ++
        c0ExportProbeFirstAppMismatchAux defeq ctx updated 0
          leftSpine.snd rightSpine.snd

/-- Diagnostic-only finite expansion of active let FVars. -/
def c0ExportExpandLocalLets (fuel : Nat)
    (ctx : PsKernelCheckerContext) : PsKernelExpr → PsKernelExpr :=
  match fuel with
  | 0 => fun e => e
  | remaining + 1 =>
      let go := c0ExportExpandLocalLets remaining ctx
      fun e =>
        match e with
        | .fvar n =>
            match psKernelLocalContextFind ctx.localContext n with
            | .some d =>
                match psKernelLocalDeclValue d with
                | .some v => go v
                | .none => e
            | .none => e
        | .app f a => .app (go f) (go a)
        | .lam n t b i => .lam n (go t) (go b) i
        | .forallE n t b i => .forallE n (go t) (go b) i
        | .letE n t v b d => .letE n (go t) (go v) (go b) d
        | .mdata m b => .mdata m (go b)
        | .proj n i b => .proj n i (go b)
        | _ => e

/-- Non-accepting proof argument comparison: require two fully checked
    applications of admitted theorems with one exact, verified Prop type. -/
def c0ExportCheckedProofPair (fuel : Nat)
    (ctx : PsKernelCheckerContext) (st : PsKernelCheckerState)
    (lhs rhs : PsKernelExpr) : Bool :=
  match psKernelExprGetAppFn lhs, psKernelExprGetAppFn rhs with
  | .const ln _, .const rn _ =>
      match psKernelEnvironmentFind ctx.environment ln,
          psKernelEnvironmentFind ctx.environment rn with
      | .some (.thmInfo _), .some (.thmInfo _) =>
          let session := PsKernelCheckerSession.mk ctx st
          match psKernelSessionCheck fuel session lhs with
          | .error _ => false
          | .ok (lt, next) =>
              match psKernelSessionCheck fuel next rhs with
              | .error _ => false
              | .ok (rt, last) =>
                  if psKernelExprEq lt rt then
                    match psKernelSessionIsProp fuel last lt with
                    | .ok (isProp, _) => isProp
                    | .error _ => false
                  else false
      | _, _ => false
  | _, _ => false

/-- Bounded candidate only; never used for admission or DefEq caching.
    Common binders open hygienically before comparing proof applications. -/
def c0ExportProofCongruenceCandidate (depth fuel : Nat) :
    PsKernelCheckerContext → PsKernelCheckerState →
    PsKernelExpr → PsKernelExpr → Bool :=
  match depth with
  | 0 => fun _ _ _ _ => false
  | n + 1 =>
      let go := c0ExportProofCongruenceCandidate n fuel
      fun ctx st lhs rhs =>
        if psKernelExprEq lhs rhs then true
        else
          match lhs, rhs with
          | .app lf la, .app rf ra =>
              if c0ExportCheckedProofPair fuel ctx st lhs rhs then true
              else if go ctx st lf rf then go ctx st la ra
              else false
          | .lam name lt lb bi, .lam _ rt rb _ =>
              if psKernelExprEq lt rt then
                let fresh := psKernelCheckerStateFreshName st name
                let lc := psKernelLocalContextAddLocal
                  ctx.localContext fresh.1 name lt bi
                let child := psKernelCheckerContextWithLocalContext ctx lc
                go child fresh.2
                  (psKernelExprInstantiate1 lb (.fvar fresh.1))
                  (psKernelExprInstantiate1 rb (.fvar fresh.1))
              else false
          | .forallE name lt lb bi, .forallE _ rt rb _ =>
              if psKernelExprEq lt rt then
                let fresh := psKernelCheckerStateFreshName st name
                let lc := psKernelLocalContextAddLocal
                  ctx.localContext fresh.1 name lt bi
                let child := psKernelCheckerContextWithLocalContext ctx lc
                go child fresh.2
                  (psKernelExprInstantiate1 lb (.fvar fresh.1))
                  (psKernelExprInstantiate1 rb (.fvar fresh.1))
              else false
          | .mdata _ lb, .mdata _ rb => go ctx st lb rb
          | .proj ln li lb, .proj rn ri rb =>
              if psKernelNameEq ln rn && li == ri then go ctx st lb rb
              else false
          | _, _ => false

def c0ExportDiagnoseDefEqWhnfSides
    (fuel : Nat)
    (ctx : PsKernelCheckerContext)
    (st : PsKernelCheckerState)
    (lhs rhs : PsKernelExpr) : String :=
  let defeq := psKernelIsDefEqWithFuel fuel
  let core := psKernelWhnfCoreWithRecursorFuel fuel defeq
  let full := psKernelWhnfWithRecursorFuel fuel defeq
  let lCheap := c0ExportDescribeWhnfProbe (core ctx st lhs false true)
  let rCheap := c0ExportDescribeWhnfProbe (core ctx st rhs false true)
  let lCore := c0ExportDescribeWhnfProbe (core ctx st lhs false false)
  let rCore := c0ExportDescribeWhnfProbe (core ctx st rhs false false)
  let leftPublic := full ctx st lhs
  let rightPublic := full ctx st rhs
  let lPublic := c0ExportDescribeWhnfProbe leftPublic
  let rPublic := c0ExportDescribeWhnfProbe rightPublic
  let normalizedConversion :=
    match leftPublic, rightPublic with
    | .ok (leftNormal, _), .ok (rightNormal, _) =>
        let zetaLeft := c0ExportExpandLocalLets 192 ctx leftNormal
        let zetaRight := c0ExportExpandLocalLets 192 ctx rightNormal
        let zetaSame := psKernelExprEq zetaLeft zetaRight
        let zetaText :=
          " | zeta_equal=" ++ toString zetaSame ++
          " | zeta_path=" ++
            c0ExportFirstSyntacticDifference 48 ctx zetaLeft zetaRight ++
          " | proof_congruence_candidate=" ++
            toString (c0ExportProofCongruenceCandidate
              96 fuel ctx st zetaLeft zetaRight)
        let same := psKernelExprEq leftNormal rightNormal
        if same then
          "full_whnf_structural_equal=true"
        else
          match defeq ctx st leftNormal rightNormal with
          | .ok (equal, _) =>
              "full_whnf_structural_equal=false normalized_defeq=" ++
                toString equal
          | .error error =>
              "full_whnf_structural_equal=false normalized_defeq_error=" ++
                error ++ zetaText ++ " | scoped_proof=" ++
                c0ExportScopedProofDifference 64 fuel ctx st
                  zetaLeft zetaRight ++
                " | first_app_argument=" ++
                c0ExportProbeFirstAppMismatch fuel ctx st
                  leftNormal rightNormal
    | _, _ => "full_whnf_structural_equal=unavailable"
  " lhs_cheap=" ++ lCheap ++ " rhs_cheap=" ++ rCheap ++
  " lhs_core=" ++ lCore ++ " rhs_core=" ++ rCore ++
  " lhs_public=" ++ lPublic ++ " rhs_public=" ++ rPublic ++
  " | normalized=" ++ normalizedConversion

/-- Trace the *outermost failing source callback*, not an accepting
    alternate checker. WHNF and DefEq remain the original source functions.
    The wrapper only annotates their existing errors with bounded expressions;
    it is invoked after the original declaration has already been declined. -/
def c0ExportDiagnoseDefinitionReduction
    (env : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (fuel : Nat) : String :=
  let session := psKernelMkCheckerSession env value.base.levelParams
    .safe 4096 psKernelLeanNatMaxSizeDefault
  match psKernelCheckConstantBaseWithSession fuel session value.base with
  | .error reason => "header: " ++ reason
  | .ok header =>
      let originalDefEq := psKernelIsDefEqWithFuel fuel
      let tracedDefEq := fun
          (ctx : PsKernelCheckerContext)
          (st : PsKernelCheckerState)
          (lhs rhs : PsKernelExpr) =>
        match originalDefEq ctx st lhs rhs with
        | .error reason =>
            let whnfTrace :=
              if reason == "kernel reduction budget exhausted" then
                " | whnf_sides=" ++
                  c0ExportDiagnoseDefEqWhnfSides fuel ctx st lhs rhs
              else ""
            .error ("defeq left=" ++ c0ExportMismatchTerm 7 lhs ++
              " right=" ++ c0ExportMismatchTerm 7 rhs ++
              " | " ++ reason ++ whnfTrace)
        | result => result
      let originalWhnf := psKernelWhnfWithRecursorFuel fuel tracedDefEq
      let tracedWhnf := fun
          (ctx : PsKernelCheckerContext)
          (st : PsKernelCheckerState)
          (expr : PsKernelExpr) =>
        match originalWhnf ctx st expr with
        | .error reason =>
            .error ("whnf input=" ++ c0ExportMismatchTerm 7 expr ++
              " | " ++ reason)
        | result => result
      match psKernelCheckWithFuel fuel tracedWhnf tracedDefEq
          header.context header.state value.value with
      | .ok _ => "annotated source callback completed"
      | .error reason => reason

def c0ExportDiagnosticDefinitionResource
    (env : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (fuel : Nat) : IO Unit := do
  IO.println ("C0_REAL_RESOURCE_DEF_NAME=" ++
    c0ExportMismatchTerm 2 (.const value.base.name []))
  match c0ExportDiagnoseDefinitionStages env value fuel with
  | .ok result =>
      IO.println ("C0_REAL_RESOURCE_DEF_STAGE=" ++ result)
  | .error stage =>
      IO.println ("C0_REAL_RESOURCE_DEF_STAGE=" ++ stage)
      IO.println ("C0_REAL_RESOURCE_DEF_CONVERSION=" ++
        c0ExportDiagnoseDefinitionReduction env value fuel)
  -- Diagnostic only. The original 4096-fuel verdict has already been
  -- returned; increasing a *probe* budget neither admits nor authorizes a
  -- declaration and must not be counted toward positive acceptance.
  let started ← IO.monoMsNow
  let probeFuel := fuel * 2
  match c0ExportCheckOne env (.definition value) probeFuel with
  | .ok _ =>
      IO.println s!"C0_REAL_RESOURCE_DEF_PROBE fuel={probeFuel} result=accepted_diagnostic_only"
  | .error error =>
      IO.println s!"C0_REAL_RESOURCE_DEF_PROBE fuel={probeFuel} result={repr (c0ExportFromKernelError error)}"
  let finished ← IO.monoMsNow
  IO.println s!"C0_REAL_RESOURCE_DEF_PROBE_ELAPSED_MS={finished - started}"

/-- Drill into the same checked constructor sequence using singleton source
    transactions. The full bundle is already rejected before this function
    runs: no result is published, and all original error strings stay intact.
    A staged failure specifies the constructor and suboperation, not an
    alternative validity judgment. -/
def c0ExportDiagnoseConstructorSequence
    (fuel : Nat)
    (decl : PsKernelSimpleInductiveDecl)
    (safety : PsKernelDefinitionSafety)
    (resultLevel : PsKernelLevel)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (headerSession : PsKernelCheckerSession)
    (work : PsKernelEnvironment)
    (index : Nat) :
    List PsKernelSimpleConstructorDecl → Except String String
  | [] => .ok "all constructor singleton stages succeeded"
  | ctor :: rest => do
      match psKernelAddSimpleConstructorsWithFuel (fuel + 1)
            fuel
          decl safety resultLevel levels params numIndices
          headerSession work index [ctor] with
      | .ok result =>
          c0ExportDiagnoseConstructorSequence fuel decl safety
            resultLevel levels params numIndices headerSession
            result.environment (index + 1) rest
      | .error original =>
          let label := "constructor[" ++ toString index ++ "]"
          let closedSession := psKernelMkCheckerSession work
            decl.levelParams safety 4096 psKernelLeanNatMaxSizeDefault
          let checked ←
            match psKernelSessionCheck fuel closedSession ctor.type with
            | .ok result => pure result
            | .error reason =>
                throw (label ++ "/full_type: " ++ reason ++
                  " | " ++ c0ExportDiagnoseCtorFirstFalse
                    fuel closedSession ctor.type)
          let _ ← c0ExportStage (label ++ "/type_sort")
            (psKernelSessionEnsureSort fuel checked.2 checked.1)
          let opened ← c0ExportStage (label ++ "/open_params")
            (psKernelOpenSimpleConstructorParams
              fuel (psKernelSessionWithEnvironment headerSession work)
              params ctor.type)
          let fields ←
            match psKernelOpenSimpleConstructorFields
                fuel opened.session decl.name levels params numIndices
                resultLevel opened.result with
            | .ok result => pure result
            | .error original =>
                let detail := c0ExportDiagnoseFieldSequence (fuel + 1)
                  opened.session decl.name levels params numIndices
                  resultLevel opened.result 0
                match detail with
                | .error reason =>
                    throw (label ++ "/open_fields: " ++ original ++
                      " | " ++ reason)
                | .ok summary =>
                    throw (label ++ "/open_fields: " ++ original ++
                      " | " ++ summary)
          let _ ← c0ExportStage (label ++ "/result_indices")
            (psKernelValidateSimpleConstructorResult
              decl.name levels params numIndices fields.result)
          return label ++ ": source singleton rejected (" ++ original ++
            ") but diagnostic substeps completed"

def c0ExportDiagnoseOrdinaryInductiveStages
    (env : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl)
    (fuel : Nat) : Except String String := do
  let safety := if decl.isUnsafe then
    PsKernelDefinitionSafety.unsafeDef
  else
    PsKernelDefinitionSafety.safe
  let initial := psKernelMkCheckerSession env
    decl.levelParams safety 4096 psKernelLeanNatMaxSizeDefault
  let header ← c0ExportStage "header type"
    (psKernelSessionCheck fuel initial decl.type)
  let headerSort ← c0ExportStage "header sort"
    (psKernelSessionEnsureSort fuel header.2 header.1)
  let params ← c0ExportStage "open uniform parameters"
    (psKernelOpenSimpleHeaderParams fuel headerSort.2 decl.type decl.numParams)
  let indices ← c0ExportStage "open indices"
    (psKernelOpenSimpleHeaderIndices fuel params.session params.result)
  match indices.result with
  | .sort resultLevel =>
      let levels := psKernelLevelParamsToLevels decl.levelParams
      let numIndices := psKernelOpenBinderListLength indices.binders
      let initialInfo : PsKernelInductiveInfo :=
        { base := { name := decl.name, levelParams := decl.levelParams,
                     type := decl.type }
          numParams := decl.numParams
          numIndices := numIndices
          all := [decl.name]
          ctors := psKernelSimpleCtorNames decl.ctors
          numNested := 0
          isRec := false
          isReflexive := false
          isUnsafe := decl.isUnsafe }
      let work0 := psKernelEnvironmentAddUnchecked env (.inductInfo initialInfo)
      let constructors ←
        match psKernelAddSimpleConstructorsWithFuel (fuel + 1)
            fuel
            decl safety resultLevel levels params.binders numIndices
            params.session work0 0 decl.ctors with
        | .ok result => .ok result
        | .error reason =>
            let detail := c0ExportDiagnoseConstructorSequence
              fuel decl safety resultLevel levels params.binders
              numIndices params.session work0 0 decl.ctors
            match detail with
            | .ok summary =>
                .error ("checked constructors: " ++ reason ++
                  " | " ++ summary)
            | .error stage =>
                .error ("checked constructors: " ++ reason ++
                  " | " ++ stage)
      let shapes := constructors.shapes
      let finalInfo : PsKernelInductiveInfo :=
        { initialInfo with
          isRec := psKernelSimpleHasRecursiveFields shapes
          isReflexive := psKernelSimpleHasReflexiveFields shapes }
      let work1 := psKernelEnvironmentReplaceUnchecked
        constructors.environment (.inductInfo finalInfo)
      let elimSession := psKernelSessionWithEnvironment params.session work1
      let _ ← c0ExportStage "checked elimination level"
        (psKernelSimpleElimOnlyAtZero
          fuel elimSession params.binders resultLevel decl.ctors)
      return "header, constructors and elimination accepted; error in generated recursor/rules"
  | _ => throw "header opened to a nonsort result"

/-- Unlike the normal source admission, this only runs after an authoritative
    rejecting verdict. It cannot turn that verdict into acceptance. -/
def c0ExportDiagnosticInductiveMismatch
    (env : PsKernelEnvironment)
    (group : C0ExportInductiveGroup)
    (fuel : Nat) : IO Unit := do
  match group.source with
  | .ordinary decl =>
      match c0ExportDiagnoseOrdinaryInductiveStages env decl fuel with
      | .ok stage =>
          IO.println ("C0_REAL_INDUCTIVE_STAGE= " ++ stage)
      | .error stage =>
          IO.println ("C0_REAL_INDUCTIVE_STAGE_FAILURE= " ++ stage)
  | .mutual _ =>
      IO.println "C0_REAL_INDUCTIVE_STAGE=mutual; requires mutual diagnostic"
  | .nested _ =>
      IO.println "C0_REAL_INDUCTIVE_STAGE=nested; requires nested diagnostic"

/-- Render names only for IO trace diagnostics, never for checker decisions. -/
def c0ExportTraceName : PsKernelName → String
  | .anonymous => ""
  | .str parent value =>
      let parentName := c0ExportTraceName parent
      if parentName.isEmpty then value else parentName ++ "." ++ value
  | .num parent value =>
      let parentName := c0ExportTraceName parent
      if parentName.isEmpty then toString value
      else parentName ++ "." ++ toString value

/-- Lazily resolve the exact exported declaration name for a stalled
    or completed slow declaration. This never determines an admission result. -/
def c0ExportTraceDeclarationName
    (tables : C0ExportTables) (raw kind : String) : String :=
  match Lean.Json.parse raw with
  | .error _ => "<unparsed>"
  | .ok record =>
      match record.getObjVal? kind with
      | .error _ => "<unknown-kind>"
      | .ok payload =>
          match c0JsonNat payload "name" with
          | .error _ => "<unnamed>"
          | .ok idx =>
              match c0ExportName tables idx with
              | .error _ => s!"<unknown-name-{idx}>"
              | .ok name => c0ExportTraceName name

/-- Result and one-based physical NDJSON record count, including a
    failed record. This is a diagnostic, never a proof receipt. -/
def c0ExportVerdictFromFileTrace
    (path : System.FilePath) (fuel : Nat := 4096)
    (traceDeclarations : Bool := false) :
    IO (C0ExportVerdict × Nat) := do
  let handle ← IO.FS.Handle.mk path .read
  let mut state : C0ExportOnlineState := {}
  let mut consumed := 0
  -- Diagnostic timings are outside the pure checker and never affect
  -- source verdicts, admitted environments, resource budgets or cache state.
  -- Time ONLY declaration records and the 50k-record interval boundaries;
  -- avoid a clock call for each of the millions of ordinary table records.
  let started ← IO.monoMsNow
  let mut previousProgress := started
  let mut intervalDeclMs : Nat := 0
  let mut intervalDeclCount : Nat := 0
  let mut slowestDeclMs : Nat := 0
  let mut slowestDeclRecord : Nat := 0
  let mut slowestDeclKind : String := "none"
  let mut reading := true
  while reading do
    let line ← handle.getLine
    if line.isEmpty then
      reading := false
    else if line != "\n" then
      consumed := consumed + 1
      -- Official lean4export emits one declaration tag as the initial
      -- JSON key. No parser or semantic path is changed for profiling.
      let declKind :=
        if line.startsWith "{\"thm\":" then "thm"
        else if line.startsWith "{\"def\":" then "def"
        else if line.startsWith "{\"inductive\":" then "inductive"
        else if line.startsWith "{\"axiom\":" then "axiom"
        else if line.startsWith "{\"opaque\":" then "opaque"
        else if line.startsWith "{\"quot\":" then "quot"
        else ""
      -- Emit the active declaration BEFORE checker execution. A timeout
      -- therefore identifies the precise still-running declaration.
      -- The diagnostic is outside the measured source checker duration.
      if traceDeclarations && !declKind.isEmpty then
        IO.println s!"C0_REAL_EXPORT_DECL_BEGIN record={consumed} kind={declKind} name={c0ExportTraceDeclarationName state.tables line declKind}"
      let began ← if declKind.isEmpty then pure 0 else IO.monoMsNow
      let outcome := c0ExportStepDetailed state line fuel
      if !declKind.isEmpty then
        let elapsed := (← IO.monoMsNow) - began
        intervalDeclMs := intervalDeclMs + elapsed
        intervalDeclCount := intervalDeclCount + 1
        if elapsed > slowestDeclMs then
          slowestDeclMs := elapsed
          slowestDeclRecord := consumed
          slowestDeclKind := declKind
        if elapsed >= 3000 then
          IO.println s!"C0_REAL_EXPORT_SLOW_DECL record={consumed} kind={declKind} elapsed_ms={elapsed} name={c0ExportTraceDeclarationName state.tables line declKind}"
      match outcome with
      | .error failure =>
          -- The first failure already carries the original parser reason or
          -- exact pre-admission checker environment. Do NOT retain 'state'
          -- across successful table pushes just for this diagnostic branch.
          let verdict := c0ExportStepFailureVerdict failure
          match failure with
          | .malformedJson message =>
              IO.println ("C0_REAL_EXPORT_PARSE_ERROR=" ++ message)
          | .invalidInput message =>
              IO.println ("C0_REAL_EXPORT_INPUT_REASON=" ++ message)
          | .checked env declaration error =>
              match error with
              | .rejectedInvalid message =>
                  IO.println ("C0_REAL_EXPORT_REJECT_MESSAGE=" ++ message)
                  match declaration with
                  | .theoremDecl info =>
                      c0ExportDiagnosticTheoremMismatch env info fuel
                  | .inductiveGroup group =>
                      c0ExportDiagnosticInductiveMismatch env group fuel
                  | _ => pure ()
              | .declinedUnsupported message =>
                  IO.println ("C0_REAL_EXPORT_DECLINED_REASON=" ++ message)
              | .resourceExhausted _ message =>
                  IO.println ("C0_REAL_EXPORT_RESOURCE_REASON=" ++ message)
                  match declaration with
                  | .definition info =>
                      c0ExportDiagnosticDefinitionResource env info fuel
                  | _ => pure ()
              | .internalError message =>
                  IO.println ("C0_REAL_EXPORT_INTERNAL_REASON=" ++ message)
          return (verdict, consumed)
      | .ok next =>
          state := next
          -- Diagnostic-only streaming progress. The complete source
          -- environment and every checking decision remain unchanged.
          -- Report a bounded cadence even if a multi-million-record
          -- real corpus later times out or exhausts host resources.
          if consumed % 50000 == 0 then
            let now ← IO.monoMsNow
            let interval := now - previousProgress
            IO.println s!"C0_REAL_EXPORT_PROGRESS consumed_records={consumed} checked_declarations={state.checkedCount} elapsed_ms={now - started} interval_ms={interval} measured_decl_ms={intervalDeclMs} other_ms={interval - intervalDeclMs} measured_decls={intervalDeclCount} slowest_decl_record={slowestDeclRecord} slowest_decl_kind={slowestDeclKind} slowest_decl_ms={slowestDeclMs}"
            previousProgress := now
            intervalDeclMs := 0
            intervalDeclCount := 0
            slowestDeclMs := 0
            slowestDeclRecord := 0
            slowestDeclKind := "none"
  return (c0ExportFinish state, consumed)

def c0ExportVerdictFromFile
    (path : System.FilePath) (fuel : Nat := 4096) :
    IO C0ExportVerdict := do
  let result ← c0ExportVerdictFromFileTrace path fuel
  return result.fst

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
  let partialQuot := simple ++
    "{\"quot\":{\"name\":1,\"levelParams\":[],\"type\":0,\"kind\":\"type\"}}\n"
  if c0ExportVerdictOnline partialQuot != .malformed ||
      c0ExportVerdictBatch partialQuot != .malformed then
    throw (IO.userError "C0 admitted incomplete four-record quotient export")
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

/-- Only a positively accepted replay is a successful strict command.
    The ordinary diagnostic command keeps all original non-accepting outcomes.
    Fuel remains explicit and unchanged; host errors remain distinct from
    a kernel rejection or resource-exhausted verdict. -/
def c0ExportRequireAccepted (outcome : C0ExportVerdict) : Except String Unit :=
  if outcome == .accepted then .ok ()
  else .error s!"C0_REAL_EXPORT_STRICT_FAILURE verdict={repr outcome}"

/-- Opt-in strict admission CLI; unchanged source checking and trace. -/
def c0ExportPrintFileOutcome
    (path : String) (fuel : Nat) (strict : Bool := false)
    (traceDeclarations : Bool := false) : IO Unit := do
  let (outcome, lines) ← c0ExportVerdictFromFileTrace
    path fuel traceDeclarations
  IO.println s!"C0_REAL_EXPORT replay_outcome={repr outcome} consumed_records={lines} fuel={fuel}"
  if strict then
    match c0ExportRequireAccepted outcome with
    | .ok () => pure ()
    | .error reason => throw (IO.userError reason)

def main (args : List String) : IO Unit := do
  match args with
  | [path] =>
      c0ExportPrintFileOutcome path 4096
      return ()
  | [path, fuelText] =>
      let some fuel := fuelText.toNat?
        | throw (IO.userError "expected decimal fuel budget")
      c0ExportPrintFileOutcome path fuel
      return ()
  | [flag, path, fuelText] =>
      let some fuel := fuelText.toNat?
        | throw (IO.userError "expected decimal fuel budget")
      if flag == "--require-accepted" then
        c0ExportPrintFileOutcome path fuel true
      else if flag == "--trace-declarations" then
        c0ExportPrintFileOutcome path fuel false true
      else
        throw (IO.userError "unknown NDJSON replay mode")
      return ()
  | [first, second, path, fuelText] =>
      if first != "--require-accepted" ||
          second != "--trace-declarations" then
        throw (IO.userError "unknown NDJSON replay mode")
      let some fuel := fuelText.toNat?
        | throw (IO.userError "expected decimal fuel budget")
      c0ExportPrintFileOutcome path fuel true true
      return ()
  | [] => pure ()
  | _ => throw (IO.userError "expected NDJSON path [fuel] with optional --require-accepted and/or --trace-declarations")
  -- Negatives, unsupported input and resource exhaustion can never be
  -- promoted to a process-success acceptance contract.
  for verdict in [C0ExportVerdict.rejected, .unsupported, .malformed,
      .resourceExhausted, .inconclusive] do
    if (c0ExportRequireAccepted verdict).isOk then
      throw (IO.userError "strict NDJSON replay admitted a non-accepting verdict")
  if !(c0ExportRequireAccepted .accepted).isOk then
    throw (IO.userError "strict NDJSON replay declined accepted input")
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
    ("C0OfficialInitSubtypeReject.ndjson", false),
    ("C0OfficialInitThreeInductivesAccept.ndjson", true),
    ("C0OfficialMixedReject.ndjson", false)
  ]
  for item in cases do
    let path := "test/" ++ item.fst
    let input ← IO.FS.readFile path
    let expected := if item.snd then C0ExportVerdict.accepted
      else C0ExportVerdict.rejected
    let actual := c0ExportVerdictOf input
    let streamed ← c0ExportVerdictFromFile path
    if streamed != actual then
      throw (IO.userError s!"C0 streaming/file replay divergence {path}: {repr streamed}, {repr actual}")
    let reference := c0ExportVerdictBatch input
    if actual != reference then
      throw (IO.userError s!"C0 online/batch replay divergence {path}: {repr actual}, {repr reference}")
    if actual != expected then
      throw (IO.userError s!"C0/official NDJSON verdict mismatch {path}: {repr actual}")
  IO.println "C0_LEAN435 exact_official_ndjson_subset_replay=pass"
