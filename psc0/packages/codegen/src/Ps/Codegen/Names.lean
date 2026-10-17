import Ps.CompilerIr.Model

structure PsCodegenSymbol where
  semanticName : String
  outputName : String

structure PsCodegenNames where
  reserved : List String := []
  symbols : List PsCodegenSymbol := []

-- Preserve ordinary names and common Unicode letters. Other characters remain
-- represented in semanticName; only target spelling is normalized here.
def psCodegenLetter (c : Char) : Bool :=
  c.isAlpha || (c.toNat >= 0x391 && c.toNat <= 0x3a1) ||
  (c.toNat >= 0x3a3 && c.toNat <= 0x3c9) ||
  (c.toNat >= 0x410 && c.toNat <= 0x44f) ||
  (c.toNat >= 0x4e00 && c.toNat <= 0x9fff)

def psCodegenBaseName (raw : String) : String :=
  let text := String.ofList (raw.toList.map fun c =>
    if psCodegenLetter c || c.isDigit || c == '_' then c else '_')
  match text.toList with
  | [] => "value"
  | first :: _ =>
      if psCodegenLetter first || first == '_' then text else "value_" ++ text

def psCodegenFresh : Nat → List String → String → String
  | 0, _, name => name
  | n + 1, used, name =>
      if used.contains name then psCodegenFresh n used (name ++ "_") else name

abbrev PsCodegenNameM := StateT PsCodegenNames (Except String)

def psCodegenName (raw : String) : PsCodegenNameM String := do
  let state ← get
  if let some entry := state.symbols.find? (fun entry => entry.semanticName == raw) then
    return entry.outputName
  let base := psCodegenBaseName raw
  let base := if state.reserved.contains base || base == "_" ||
      base.startsWith "__ps" then "source_" ++ base else base
  let used := state.reserved ++ state.symbols.map (·.outputName)
  let name := psCodegenFresh (used.length + 1) used base
  set { state with symbols := { semanticName := raw, outputName := name } :: state.symbols }
  return name

def psCodegenType : Nat → PsVerifiedIrType → StateT PsCodegenNames (Except String) PsVerifiedIrType
  | 0, _ => throw "PSCV0-NAME: type traversal budget exhausted"
  | n + 1, type => do
      match type with
      | .unknown | .primitive _ => return type
      | .typeParameter name => return .typeParameter (← psCodegenName name)
      | .named name args =>
          let name ← if name == "Array" then pure name else psCodegenName name
          return .named name (← args.mapM (psCodegenType n))
      | .function args result =>
          return .function (← args.mapM (psCodegenType n)) (← psCodegenType n result)

def psCodegenParameter (p : PsVerifiedIrParameter) :
    StateT PsCodegenNames (Except String) PsVerifiedIrParameter := do
  return { name := ← psCodegenName p.name, type := ← psCodegenType 65536 p.type }

def psCodegenExpr : Nat → PsVerifiedIrExpr →
    StateT PsCodegenNames (Except String) PsVerifiedIrExpr
  | 0, _ => throw "PSCV0-NAME: expression traversal budget exhausted"
  | n + 1, expr => do
      let types := List.mapM (psCodegenType 65536)
      let fields := fun (fs : List (String × PsVerifiedIrExpr)) =>
        fs.mapM fun (name, value) => do
          return (← psCodegenName name, ← psCodegenExpr n value)
      match expr with
      | .unreachable type => return .unreachable (← psCodegenType 65536 type)
      | .panic message type => return .panic message (← psCodegenType 65536 type)
      | .literal _ => return expr
      | .var name => return .var (← psCodegenName name)
      | .intrinsic op ts args => return .intrinsic op (← types ts) (← args.mapM (psCodegenExpr n))
      | .call fn ts args => return .call (← psCodegenExpr n fn) (← types ts) (← args.mapM (psCodegenExpr n))
      | .lambda ps type body =>
          return .lambda (← ps.mapM psCodegenParameter) (← psCodegenType 65536 type) (← psCodegenExpr n body)
      | .letE name type value body =>
          return .letE (← psCodegenName name) (← psCodegenType 65536 type)
            (← psCodegenExpr n value) (← psCodegenExpr n body)
      | .ifE c t e => return .ifE (← psCodegenExpr n c) (← psCodegenExpr n t) (← psCodegenExpr n e)
      | .record name ts fs => return .record (← psCodegenName name) (← types ts) (← fields fs)
      | .constructor name ctor ts fs =>
          return .constructor (← psCodegenName name) (← psCodegenName ctor) (← types ts) (← fields fs)
      | .projection name ts target field =>
          return .projection (← psCodegenName name) (← types ts) (← psCodegenExpr n target) (← psCodegenName field)
      | .matchE name ts target alts =>
          let alts ← alts.mapM fun (ctor, bindings, body) => do
            let bindings ← bindings.mapM fun b => do
              return {
                field := ← psCodegenName b.field
                name := ← psCodegenName b.name
                type := ← psCodegenType 65536 b.type : PsVerifiedIrMatchBinding }
            return (← psCodegenName ctor, bindings, ← psCodegenExpr n body)
          return .matchE (← psCodegenName name) (← types ts) (← psCodegenExpr n target) alts

def psCodegenModule (ir : PsVerifiedIrModule) :
    StateT PsCodegenNames (Except String) PsVerifiedIrModule := do
  -- Allocate public declaration identities before private expression names.
  for s in ir.structures do
    let _ ← psCodegenName s.name
    pure ()
  for s in ir.inductives do
    let _ ← psCodegenName s.name
    pure ()
  for d in ir.declarations do
    let _ ← psCodegenName d.name
    pure ()
  let parameters := fun (ps : List PsVerifiedIrTypeParameter) =>
    ps.mapM fun p => do return { name := ← psCodegenName p.name : PsVerifiedIrTypeParameter }
  let structures ← ir.structures.mapM fun s => do
    let fields ← s.fields.mapM fun p => do
      return { name := ← psCodegenName p.name, type := ← psCodegenType 65536 p.type : PsVerifiedIrStructureField }
    return {
      name := ← psCodegenName s.name
      typeParameters := ← parameters s.typeParameters
      fields := fields : PsVerifiedIrStructure }
  let inductives ← ir.inductives.mapM fun s => do
    let constructors ← s.constructors.mapM fun c => do
      let fields ← c.fields.mapM fun p => do
        return { name := ← psCodegenName p.name, type := ← psCodegenType 65536 p.type : PsVerifiedIrConstructorField }
      return { name := ← psCodegenName c.name, fields : PsVerifiedIrConstructor }
    return {
      name := ← psCodegenName s.name
      typeParameters := ← parameters s.typeParameters
      constructors := constructors : PsVerifiedIrInductive }
  let declarations ← ir.declarations.mapM fun d => do
    return {
      name := ← psCodegenName d.name
      typeParameters := ← parameters d.typeParameters
      parameters := ← d.parameters.mapM psCodegenParameter
      resultType := ← psCodegenType 65536 d.resultType
      body := ← psCodegenExpr 65536 d.body : PsVerifiedIrDeclaration }
  let imports ← ir.imports.mapM fun d => do
    return { d with localName := ← psCodegenName d.localName, type := ← psCodegenType 65536 d.type }
  let foreignData ← ir.foreignData.mapM fun (name, safe) => do
    return (← psCodegenName name, safe)
  let internalNames ← ir.internalNames.mapM psCodegenName
  return { foreignData, imports, structures, inductives, declarations, internalNames }

def psCodegenNamesFor (ir : PsVerifiedIrModule) (reserved : List String) :
    Except String (PsVerifiedIrModule × PsCodegenNames) :=
  (psCodegenModule ir).run { reserved := "Array" :: reserved }
