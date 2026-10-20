import Ps.CompilerIr.Validate
import Ps.Bridge.Json
import Ps.BackendPython.Runtime

/-- Source output is data, not admission evidence. The host retains the checked closure. -/
structure PsPythonOutput where
  source : String
  stub : String
  runtimeSource : String
  runtimeHelpers : List String
  declarationLines : List (String × Nat)

namespace PsPython

private def encodePart (name : String) : String :=
  String.join ((psJsonStringToChars name).map fun c =>
    if c == '_' then "__"
    else if c.isAlphanum && c.toNat < 128 then String.singleton c
    else "_u" ++ toString c.toNat ++ "_")

private def globalName (name : String) : String := "_psc_g_" ++ encodePart name
private def valueName (name : String) : String := "_psc_value_" ++ encodePart name

private def publicNameAllowed (name : String) : Bool :=
  let chars := psJsonStringToChars name
  let keywords := ["False", "None", "True", "and", "as", "assert", "async", "await",
    "break", "class", "continue", "def", "del", "elif", "else", "except", "finally",
    "for", "from", "global", "if", "import", "in", "is", "lambda", "nonlocal",
    "not", "or", "pass", "raise", "return", "try", "while", "with", "yield"]
  !name.startsWith "_psc_" && name != "__all__" && !keywords.contains name &&
    match chars with
    | [] => false
    | c :: rest =>
        (c == '_' || c.isAlpha) && c.toNat < 128 &&
          rest.all (fun ch => (ch == '_' || ch.isAlphanum) && ch.toNat < 128)

private def scalarType : PsVerifiedIrType → Except String String
  | .primitive .nat | .primitive .int => .ok "_psc_b.int"
  | .primitive .bool => .ok "_psc_b.bool"
  | .primitive .char | .primitive .string => .ok "_psc_b.str"
  | .primitive .unit => .ok "None"
  | _ => .error "PSC1_PYTHON_PUBLIC_ABI_UNSUPPORTED: expected Nat, Int, Bool, Char, String or Unit"

private def checkType (fuel : Nat) (t : PsVerifiedIrType) : Except String Unit :=
  match fuel with
  | 0 => .error "PSC1_PYTHON_TYPE_BUDGET"
  | fuel + 1 =>
    match t with
    | .primitive .nat | .primitive .int | .primitive .bool
    | .primitive .char | .primitive .string | .primitive .unit => .ok ()
    | .function ps result => do
        ps.forM (checkType fuel)
        checkType fuel result
    | .named _ args => args.forM (checkType fuel)
    | _ => .error "PSC1_PYTHON_CAPABILITY_UNSUPPORTED: unresolved, generic or machine/float type"

private def hexDigits : Nat → Nat → String → String
  | 0, _, acc => acc
  | fuel + 1, n, acc =>
      if n == 0 then acc
      else hexDigits fuel (n / 16) (psJsonHexDigit (n % 16) ++ acc)

private def naturalLiteral (value : Nat) : String :=
  let decimal := toString value
  if decimal.length < 600 then decimal
  else "0x" ++ hexDigits (decimal.length + 1) value ""

private def literal : PsVerifiedIrLiteral → Except String String
  | .natural value => .ok (naturalLiteral value)
  | .integer value =>
      .ok ((if value < 0 then "-" else "") ++ naturalLiteral value.natAbs)
  | .string value => .ok (psJsonQuote value)
  | .bool value => .ok (if value then "True" else "False")
  | .unit => .ok "None"
  | .machineInteger _ _ => .error "PSC1_PYTHON_SCALAR_CAPABILITY_UNQUALIFIED"

private structure EmitState where
  lines : Array String := #[]
  indent : Nat := 0
  nextIndex : Nat := 0
  helpers : List String := []
  origins : List (String × Nat) := []

private abbrev Emit := StateT EmitState (Except String)
private abbrev Scope := List (String × String)

private def line (text : String) : Emit Unit := do
  let s ← get
  let padding := String.join (List.replicate s.indent "    ")
  set { s with lines := s.lines.push (padding ++ text) }

private def fresh (hint : String := "tmp") : Emit String := do
  let s ← get
  set { s with nextIndex := s.nextIndex + 1 }
  pure ("_psc_l" ++ toString s.nextIndex ++ "_" ++ encodePart hint)

private def helper (id : String) : Emit Unit :=
  modify fun s => { s with helpers := if s.helpers.contains id then s.helpers else s.helpers ++ [id] }

private def withIndent (action : Emit α) : Emit α := do
  modify fun s => { s with indent := s.indent + 1 }
  let result ← action
  modify fun s => { s with indent := s.indent - 1 }
  pure result

private def bindValue (value : String) : Emit String := do
  let name ← fresh
  line (name ++ " = " ++ value)
  pure name

private def findLocal (scope : Scope) (name : String) : String :=
  match scope.find? (fun pair => pair.1 == name) with
  | some pair => pair.2
  | none => globalName name

private def tuple (values : List String) : String :=
  match values with
  | [] => "()"
  | [value] => "(" ++ value ++ ",)"
  | _ => "(" ++ String.intercalate ", " values ++ ")"

private def emitCall (fn : String) (args : List String) (tail : Bool) : Emit String := do
  helper "calls"
  bindValue ("(yield (" ++ fn ++ ", " ++ tuple args ++ ", " ++
    (if tail then "True" else "False") ++ "))")

private def emitHelper (id name : String) (args : List String) : Emit String := do
  helper id
  bindValue (name ++ "(" ++ String.intercalate ", " args ++ ")")

private def emitIntrinsic
    (op : PsVerifiedIrIntrinsic) (args : List String) (tail : Bool) : Emit String := do
  let binary (symbol : String) : Emit String := do
    match args with
    | [a, b] => bindValue ("(" ++ a ++ " " ++ symbol ++ " " ++ b ++ ")")
    | _ => throw "PSC1_PYTHON_INTRINSIC_ARITY"
  let unary (before after : String) : Emit String := do
    match args with
    | [a] => bindValue (before ++ a ++ after)
    | _ => throw "PSC1_PYTHON_INTRINSIC_ARITY"
  match op with
  | .natAdd | .intAdd | .stringPush | .stringAppend => binary "+"
  | .natMul | .intMul => binary "*"
  | .intSub => binary "-"
  | .natEq | .intEq | .boolEq | .stringEq => binary "=="
  | .natNe | .boolNe => binary "!="
  | .natLe | .intLe => binary "<="
  | .natLt | .intLt => binary "<"
  | .natSub =>
      match args with
      | [a, b] => bindValue ("(" ++ a ++ " - " ++ b ++ " if " ++ a ++ " >= " ++ b ++ " else 0)")
      | _ => throw "PSC1_PYTHON_INTRINSIC_ARITY"
  | .natDiv | .natMod =>
      match args with
      | [a, b] =>
          let isDiv := match op with | .natDiv => true | _ => false
          bindValue ("(" ++ (if isDiv then "0" else a) ++ " if " ++ b ++
            " == 0 else " ++ a ++ (if isDiv then " // " else " % ") ++ b ++ ")")
      | _ => throw "PSC1_PYTHON_INTRINSIC_ARITY"
  | .intOfNat | .stringSingleton =>
      match args with
      | [a] => pure a
      | _ => throw "PSC1_PYTHON_INTRINSIC_ARITY"
  | .intNeg => unary "(-" ")"
  | .intNegSucc => unary "(-(" " + 1))"
  | .intRepr => emitHelper "int-repr" "_psc_int_repr" args
  | .boolNot => unary "(not " ")"
  | .boolAnd | .boolOr => throw "PSC1_PYTHON_SHORT_CIRCUIT_LOWERING"
  | .charOfNat => emitHelper "char-of-nat" "_psc_char_of_nat" args
  | .charToNat =>
      helper "builtins"
      unary "_psc_b.ord(" ")"
  | .stringLength | .arraySize =>
      helper "builtins"
      unary "_psc_b.len(" ")"
  | .stringUtf8ByteSize =>
      helper "builtins"
      unary "_psc_b.len(" ".encode(\"utf-8\"))"
  | .stringGet => emitHelper "string-get" "_psc_string_get" args
  | .stringNext => emitHelper "string-next" "_psc_string_next" args
  | .stringExtract => emitHelper "string-extract" "_psc_string_extract" args
  | .stringAtEnd =>
      helper "builtins"
      match args with
      | [s, p] => bindValue ("(" ++ p ++ " >= _psc_b.len(" ++ s ++ ".encode(\"utf-8\")))")
      | _ => throw "PSC1_PYTHON_INTRINSIC_ARITY"
  | .arrayEmptyWithCapacity => bindValue "()"
  | .arrayPush =>
      match args with
      | [a, v] => bindValue (a ++ " + (" ++ v ++ ",)")
      | _ => throw "PSC1_PYTHON_INTRINSIC_ARITY"
  | .arrayGet => emitHelper "array-get" "_psc_array_get" args
  | .arrayGetD => emitHelper "array-get-d" "_psc_array_get_d" args
  | .arraySet => emitHelper "array-set" "_psc_array_set" args
  | .arraySetIfInBounds => emitHelper "array-set-if" "_psc_array_set_if" args
  | .arrayMap =>
      helper "array-map"
      emitCall "_psc_array_map" args tail
  | .arrayFoldl =>
      helper "array-foldl"
      emitCall "_psc_array_foldl" args tail
  | _ => throw "PSC1_PYTHON_INTRINSIC_CAPABILITY_UNQUALIFIED"

private def structureFields (m : PsVerifiedIrModule) (name : String) : Except String (List String) := do
  let some info := m.structures.find? (fun s => s.name == name)
    | throw ("PSC1_PYTHON_STRUCTURE_MISSING: " ++ name)
  pure (info.fields.map fun f => f.name)

private def constructorFields (m : PsVerifiedIrModule) (owner name : String) :
    Except String (List String) := do
  let some info := m.inductives.find? (fun s => s.name == owner)
    | throw ("PSC1_PYTHON_INDUCTIVE_MISSING: " ++ owner)
  let some ctor := info.constructors.find? (fun c => c.name == name)
    | throw ("PSC1_PYTHON_CONSTRUCTOR_MISSING: " ++ name)
  pure (ctor.fields.map fun f => f.name)

private def fieldPosition (fields : List String) (name : String) : Except String Nat :=
  if fields.contains name then .ok (fields.idxOf name)
  else .error ("PSC1_PYTHON_FIELD_MISSING: " ++ name)

private def emitParameters (scope : Scope) (parameters : List PsVerifiedIrParameter) :
    Emit (Scope × List String) := do
  let entries ← parameters.mapM fun p => do
    checkType 256 p.type
    let localName ← fresh p.name
    pure (p.name, localName)
  pure (entries ++ scope, entries.map Prod.snd)

-- Each IR binding gets a distinct Python local. Captured locals are never
-- reassigned, including shadowed names and branch-local values.
private def expression (fuel : Nat) (m : PsVerifiedIrModule) (scope : Scope)
    (expr : PsVerifiedIrExpr) (tail : Bool) : Emit String := do
  match fuel with
  | 0 => throw "PSC1_PYTHON_EMISSION_BUDGET"
  | fuel + 1 =>
    let smaller := expression fuel m scope
    match expr with
    | .literal value => bindValue (← literal value)
    | .var name => pure (findLocal scope name)
    | .intrinsic .boolAnd _ [a, b] =>
        let left ← smaller a false
        let result ← fresh "and"
        line ("if " ++ left ++ ":")
        withIndent do
          let right ← smaller b tail
          line (result ++ " = " ++ right)
        line "else:"
        withIndent (line (result ++ " = False"))
        pure result
    | .intrinsic .boolOr _ [a, b] =>
        let left ← smaller a false
        let result ← fresh "or"
        line ("if " ++ left ++ ":")
        withIndent (line (result ++ " = True"))
        line "else:"
        withIndent do
          let right ← smaller b tail
          line (result ++ " = " ++ right)
        pure result
    | .intrinsic operation typeArguments arguments =>
        typeArguments.forM fun argumentType => do
          let _ ← checkType 256 argumentType
          pure ()
        let values ← arguments.mapM fun a => smaller a false
        emitIntrinsic operation values tail
    | .lambda parameters resultType body =>
        checkType 256 resultType
        let name ← fresh "closure"
        let (inner, names) ← emitParameters scope parameters
        line ("def " ++ name ++ "(" ++ String.intercalate ", " names ++ "):")
        withIndent do
          let result ← expression fuel m inner body true
          line ("return " ++ result)
        pure name
    | .call fn typeArguments arguments =>
        typeArguments.forM fun argumentType => do
          let _ ← checkType 256 argumentType
          pure ()
        let callee ← smaller fn false
        -- Freeze the callee before evaluating any argument.
        let saved ← bindValue callee
        let values ← arguments.mapM fun a => smaller a false
        emitCall saved values tail
    | .letE name t value body =>
        checkType 256 t
        let value ← smaller value false
        let localName ← fresh name
        line (localName ++ " = " ++ value)
        expression fuel m ((name, localName) :: scope) body tail
    | .ifE condition yes no =>
        let condition ← smaller condition false
        let result ← fresh "branch"
        line ("if " ++ condition ++ ":")
        withIndent do
          let value ← smaller yes tail
          line (result ++ " = " ++ value)
        line "else:"
        withIndent do
          let value ← smaller no tail
          line (result ++ " = " ++ value)
        pure result
    | .record name types fields =>
        types.forM fun argumentType => do
          let _ ← checkType 256 argumentType
          pure ()
        let schema ← structureFields m name
        let values ← fields.mapM fun field => do
          let value ← smaller field.2 false
          pure (field.1, value)
        let ordered ← schema.mapM fun field =>
          match values.find? (fun v => v.1 == field) with
          | some value => pure value.2
          | none => throw ("PSC1_PYTHON_FIELD_MISSING: " ++ field)
        bindValue (tuple ordered)
    | .projection name types target field =>
        types.forM fun argumentType => do
          let _ ← checkType 256 argumentType
          pure ()
        let target ← smaller target false
        let fields ← structureFields m name
        let index ← fieldPosition fields field
        bindValue (target ++ "[" ++ toString index ++ "]")
    | .constructor owner name types fields =>
        types.forM fun argumentType => do
          let _ ← checkType 256 argumentType
          pure ()
        let schema ← constructorFields m owner name
        let values ← fields.mapM fun field => do
          let value ← smaller field.2 false
          pure (field.1, value)
        let ordered ← schema.mapM fun field =>
          match values.find? (fun v => v.1 == field) with
          | some value => pure value.2
          | none => throw ("PSC1_PYTHON_FIELD_MISSING: " ++ field)
        bindValue (tuple (psJsonQuote name :: ordered))
    | .matchE owner types scrutinee alternatives =>
        types.forM fun argumentType => do
          let _ ← checkType 256 argumentType
          pure ()
        let scrutinee ← smaller scrutinee false
        let result ← fresh "match"
        for alternative in alternatives do
          let name := alternative.1
          let bindings := alternative.2.1
          let body := alternative.2.2
          let fields ← constructorFields m owner name
          let branchPrefix := if alternatives.head?.map Prod.fst == some name then "if " else "elif "
          line (branchPrefix ++ scrutinee ++ "[0] == " ++ psJsonQuote name ++ ":")
          withIndent do
            let entries ← bindings.mapM fun binding => do
              checkType 256 binding.type
              let index ← fieldPosition fields binding.field
              let localName ← fresh binding.name
              line (localName ++ " = " ++ scrutinee ++ "[" ++ toString (index + 1) ++ "]")
              pure (binding.name, localName)
            let value ← expression fuel m (entries ++ scope) body tail
            line (result ++ " = " ++ value)
        helper "builtins"
        if alternatives.isEmpty then
          line "raise _psc_b.RuntimeError(\"PSC1_IMPOSSIBLE_CONSTRUCTOR\")"
        else
          line "else:"
          withIndent (line "raise _psc_b.RuntimeError(\"PSC1_IMPOSSIBLE_CONSTRUCTOR\")")
        pure result

private def parameterCheck (name : String) (t : PsVerifiedIrType) : Except String String := do
  match t with
  | .primitive .nat => pure ("_psc_b.type(" ++ name ++ ") is _psc_b.int and " ++ name ++ " >= 0")
  | .primitive .int => pure ("_psc_b.type(" ++ name ++ ") is _psc_b.int")
  | .primitive .bool => pure ("_psc_b.type(" ++ name ++ ") is _psc_b.bool")
  | .primitive .string =>
      pure ("_psc_b.type(" ++ name ++ ") is _psc_b.str and not _psc_b.any(0xD800 <= _psc_b.ord(_psc_c) <= 0xDFFF for _psc_c in " ++ name ++ ")")
  | .primitive .char =>
      pure ("_psc_b.type(" ++ name ++ ") is _psc_b.str and _psc_b.len(" ++ name ++ ") == 1 and not (0xD800 <= _psc_b.ord(" ++ name ++ ") <= 0xDFFF)")
  | .primitive .unit => pure (name ++ " is None")
  | _ => throw "PSC1_PYTHON_PUBLIC_ABI_UNSUPPORTED"

private def emitDeclaration (m : PsVerifiedIrModule) (d : PsVerifiedIrDeclaration) : Emit Unit := do
  if !d.typeParameters.isEmpty then
    throw ("PSC1_PYTHON_GENERIC_DECLARATION_UNSUPPORTED: " ++ d.name)
  checkType 256 d.resultType
  let (scope, parameters) ← emitParameters [] d.parameters
  let name := if d.parameters.isEmpty then valueName d.name else globalName d.name
  let s ← get
  modify fun st => { st with origins := st.origins ++ [(d.name, s.lines.size + 1)] }
  line ("def " ++ name ++ "(" ++ String.intercalate ", " parameters ++ "):")
  withIndent do
    let result ← expression 4096 m scope d.body true
    line ("return " ++ result)
  line ""

private def emitModuleBody (m : PsVerifiedIrModule) (publicNames : List String) : Emit String := do
  if !m.imports.isEmpty then throw "PSC1_PYTHON_FOREIGN_IMPORT_UNSUPPORTED"
  for d in m.declarations do
    emitDeclaration m d
  let calls := (← get).helpers.contains "calls"
  for d in m.declarations do
    if d.parameters.isEmpty then
      line (globalName d.name ++ " = " ++ (if calls then "_psc_run(" ++ valueName d.name ++ ")" else valueName d.name ++ "()"))
  line ""
  let mut stubs : List String := ["# Generated PSC1 scalar API; Nat values are nonnegative Python int.", "import builtins as _psc_b", ""]
  let mut seenPublic : List String := []
  for name in publicNames do
    if seenPublic.contains name then
      throw ("PSC1_PYTHON_DUPLICATE_PUBLIC_DECLARATION: " ++ name)
    seenPublic := name :: seenPublic
    if !publicNameAllowed name then
      throw ("PSC1_PYTHON_PUBLIC_NAME_UNSUPPORTED: " ++ name)
    let some d := m.declarations.find? (fun d => d.name == name)
      | throw ("PSC1_PYTHON_PUBLIC_DECLARATION_MISSING: " ++ name)
    let resultType ← scalarType d.resultType
    if d.parameters.isEmpty then
      line (name ++ " = " ++ globalName name)
      stubs := stubs ++ [name ++ ": " ++ resultType]
    else
      helper "builtins"
      let params ← (d.parameters.zipIdx).mapM fun item => do
        let t ← scalarType item.1.type
        pure ("arg" ++ toString item.2, t, item.1.type)
      let signature := String.intercalate ", " (params.map fun p => p.1 ++ ": " ++ p.2.1)
      line ("def " ++ name ++ "(" ++ signature ++ ") -> " ++ resultType ++ ":")
      withIndent do
        for p in params do
          let check ← parameterCheck p.1 p.2.2
          line ("if not (" ++ check ++ "):")
          withIndent (line ("raise _psc_b.TypeError(" ++ psJsonQuote ("PSC1_PYTHON_ARGUMENT_TYPE: " ++ name ++ ":" ++ p.1) ++ ")"))
        let args := String.intercalate ", " (params.map Prod.fst)
        let call := if calls then "_psc_run(" ++ globalName name ++ ", " ++ args ++ ")"
          else globalName name ++ "(" ++ args ++ ")"
        line ("return " ++ call)
      line ""
      stubs := stubs ++ ["def " ++ name ++ "(" ++ signature ++ ") -> " ++ resultType ++ ": ..."]
  line ("__all__ = [" ++ String.intercalate ", " (publicNames.map psJsonQuote) ++ "]")
  pure (String.intercalate "\n" stubs ++ "\n")

end PsPython

/-- A backend never treats the constructible wrapper as trust. Full IR validation
runs here; admission, exact source identity and transactional publication stay host-owned. -/
def psPythonEmitModule (validated : PsValidatedIrModule) (publicNames : List String) :
    Except String PsPythonOutput := do
  match psStrictValidateModule validated.raw with
  | .error _ => throw "PSC1_PYTHON_IR_VALIDATION_FAILED"
  | .ok _ => pure ()
  let (stub, state) ← (PsPython.emitModuleBody validated.raw publicNames).run {}
  let selected := psPythonRuntimeClosure state.helpers
  let runtime := psPythonRuntimeSource selected
  let header := "# Generated by PSC1 DirectPython; requires Python >= 3.14.\n# Logical admission does not certify backend preservation.\n\n"
  let sourcePrefix := header ++ runtime
  let offset := (sourcePrefix.splitOn "\n").length - 1
  pure {
    source := sourcePrefix ++ String.intercalate "\n" state.lines.toList ++ "\n"
    stub := stub
    runtimeSource := runtime
    runtimeHelpers := selected
    declarationLines := state.origins.map fun p => (p.1, p.2 + offset)
  }
