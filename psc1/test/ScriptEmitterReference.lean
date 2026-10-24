import Ps.BackendPython.Module
import Ps.BackendPhp.Module
import ScriptRuntimeReference

-- Exact pre-normalization emitters, native test references only.
-- Never imported by any generated compiler's owned source closure.
namespace PsScriptEmitterReference.Python

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
    | .var name =>
        match scope.find? (fun binding => binding.1 == name) with
        | some binding => pure binding.2
        | none =>
            if m.declarations.any (fun d => d.name == name && d.parameters.isEmpty) then
              emitCall (valueName name) [] tail
            else pure (globalName name)
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

private def emitModuleBody (m : PsVerifiedIrModule) (publicNames : List String) (ioAbi : Bool) : Emit String := do
  if !m.imports.isEmpty then throw "PSC1_PYTHON_FOREIGN_IMPORT_UNSUPPORTED"
  for d in m.declarations do
    emitDeclaration m d
  let calls := (← get).helpers.contains "calls"
  -- Nullary declarations are pure thunks. All definitions precede forcing, so
  -- valid forward value references and specialization order cannot change meaning.
  line "from typing import Callable"
  line ""
  let mut stubs : List String := ["# Generated PSC1 scalar API; Nat values are nonnegative Python int.", "import builtins as _psc_b", "from typing import Callable", ""]
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
      line (name ++ " = " ++ (if calls then "_psc_run(" ++ valueName name ++ ")" else valueName name ++ "()"))
      stubs := stubs ++ [name ++ ": " ++ resultType]
    else
      helper "builtins"
      let params ← (d.parameters.zipIdx).mapM fun item => do
        let t ← if ioAbi && psBackendIoDispatcherType item.1.type then pure "Callable[[_psc_b.str], _psc_b.str]"
          else scalarType item.1.type
        pure ("arg" ++ toString item.2, t, item.1.type)
      let signature := String.intercalate ", " (params.map fun p => p.1 ++ ": " ++ p.2.1)
      line ("def " ++ name ++ "(" ++ signature ++ ") -> " ++ resultType ++ ":")
      withIndent do
        for p in params do
          let check ← if ioAbi && psBackendIoDispatcherType p.2.2 then pure ("_psc_b.callable(" ++ p.1 ++ ")")
            else parameterCheck p.1 p.2.2
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
def psPythonEmitModule (validated : PsValidatedIrModule) (publicNames : List String)
    (ioAbi : Bool := false) :
    Except String PsPythonOutput := do
  match psStrictValidateModule validated.raw with
  | .error _ => throw "PSC1_PYTHON_IR_VALIDATION_FAILED"
  | .ok _ => pure ()
  let (stub, state) ← (PsPython.emitModuleBody validated.raw publicNames ioAbi).run {}
  let selected := PsScriptRuntimeReference.Python.psPythonRuntimeClosure state.helpers
  let runtime := PsScriptRuntimeReference.Python.psPythonRuntimeSource selected
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

end PsScriptEmitterReference.Python

namespace PsScriptEmitterReference.Php

structure PsPhpPrintedModule where
  source : String
  composer : String
  runtimeSource : String
  runtimeVersion : String := PsScriptRuntimeReference.Php.psPhpRuntimeVersion
  runtimeRequirements : List String
  declarations : List (String × String)
  declarationLines : List (String × Nat)

private def phpQuote (value : String) : String :=
  "\"" ++ String.join (value.toList.map fun c =>
    if c == '\\' then "\\\\"
    else if c == '"' then "\\\""
    else if c == '$' then "\\$"
    else if c == '\n' then "\\n"
    else if c == '\r' then "\\r"
    else if c == '\t' then "\\t"
    else if c.toNat < 32 then
      let digits := "0123456789abcdef".toList
      "\\x" ++ String.singleton (digits[c.toNat / 16]!) ++ String.singleton (digits[c.toNat % 16]!)
    else String.singleton c) ++ "\""

private def phpStem (value : String) : String :=
  String.join (value.toList.map fun c =>
    if c.isAlpha && c.toNat < 128 || c.isDigit || c == '_' then String.singleton c
    else "_u" ++ toString c.toNat ++ "_")

private def phpType : Nat → PsVerifiedIrType → Except String String
  | 0, _ => .error "PSC1_PHP_TYPE_BUDGET"
  | n+1, type =>
    match type with
    | .primitive .nat | .primitive .int => .ok "\\GMP"
    | .primitive .bool => .ok "bool"
    | .primitive .string | .primitive .char => .ok "string"
    | .primitive .unit => .ok "null"
    | .function parameters result => do
        let _ ← parameters.mapM (phpType n)
        let _ ← phpType n result
        return "\\Closure"
    | .named _ arguments => do
        let _ ← arguments.mapM (phpType n)
        return "array"
    | _ => .error "PSC1_PHP_TYPE_UNSUPPORTED: machine scalars, floats and unresolved types are not qualified"

private def phpTypeRequirements : Nat → PsVerifiedIrType → List String
  | 0, _ => []
  | n+1, type =>
    match type with
    | .primitive .nat | .primitive .int => ["gmp"]
    | .function parameters result =>
        parameters.flatMap (phpTypeRequirements n) ++ phpTypeRequirements n result
    | .named _ arguments => arguments.flatMap (phpTypeRequirements n)
    | _ => []

private def phpIntrinsicRequirements : PsVerifiedIrIntrinsic → List String
  | .boolNot | .boolAnd | .boolOr | .boolEq | .boolNe => []
  | .stringPush | .stringSingleton | .stringAppend | .stringEq => []
  | .charOfNat => ["charOfNat"]
  | .charToNat => ["charToNat"]
  | .stringLength => ["unicodeChars", "gmp"]
  | .stringGet => ["stringGet"]
  | .stringNext => ["stringNext"]
  | .stringExtract => ["stringExtract"]
  | .arrayMap => ["calls"]
  | .arrayFoldl => ["calls", "gmp"]
  | _ => ["gmp"]

private def phpExprRequirements
    (valueNames : List String) : Nat → List String → PsVerifiedIrExpr → List String
  | 0, _, _ => []
  | n+1, bound, expr =>
    let visit := phpExprRequirements valueNames n bound
    match expr with
    | .literal (.natural _) | .literal (.integer _) => ["gmp"]
    | .literal _ => []
    | .var name => if valueNames.contains name && !bound.contains name then ["calls"] else []
    | .intrinsic op types args =>
        phpIntrinsicRequirements op ++ types.flatMap (phpTypeRequirements n) ++ args.flatMap visit
    | .lambda parameters result body =>
        parameters.flatMap (fun p => phpTypeRequirements n p.type) ++
          phpTypeRequirements n result ++
          phpExprRequirements valueNames n (parameters.map (fun p => p.name) ++ bound) body
    | .call fn _ args => "calls" :: (visit fn ++ args.flatMap visit)
    | .letE name type value body =>
        phpTypeRequirements n type ++ visit value ++
          phpExprRequirements valueNames n (name :: bound) body
    | .ifE condition yes no => visit condition ++ visit yes ++ visit no
    | .record _ _ fields | .constructor _ _ _ fields => fields.flatMap (fun field => visit field.2)
    | .projection _ _ target _ => visit target
    | .matchE _ _ target alternatives => visit target ++ alternatives.flatMap (fun alt =>
        phpExprRequirements valueNames n (alt.2.1.map (fun binding => binding.name) ++ bound) alt.2.2)

private structure PhpContext where
  globals : List (String × String)
  valueNames : List String
  locals : List (String × String) := []
  helpers : List String
  scheduled : Bool

private structure PhpState where
  lines : Array String := #[]
  counter : Nat := 0
  indent : Nat := 1

private abbrev PhpEmit := StateT PhpState (Except String)

private def phpLift (value : Except String α) : PhpEmit α :=
  fun state => do
    let item ← value
    return (item, state)

private def phpLine (line : String) : PhpEmit Unit := do
  let state ← get
  let padding := String.join (List.replicate state.indent "    ")
  set { state with lines := state.lines.push (padding ++ line) }

private def phpIndent (delta : Int) : PhpEmit Unit := do
  modify fun s => { s with indent := (Int.ofNat s.indent + delta).toNat }

private def phpFresh (stem : String := "tmp") : PhpEmit String := do
  let state ← get
  set { state with counter := state.counter + 1 }
  return "$v" ++ toString state.counter ++ "_" ++ phpStem stem

private def phpBind (expression : String) : PhpEmit String := do
  let name ← phpFresh
  phpLine (name ++ " = " ++ expression ++ ";")
  return name

private def phpCapture (context : PhpContext) : String :=
  let refs := context.globals.map (fun p => "&" ++ p.2)
  let values := (context.locals.map (fun p => p.2) ++ context.helpers).foldl
    (fun seen value => if seen.contains value then seen else seen ++ [value]) []
  let captures := refs ++ values
  if captures.isEmpty then "" else " use (" ++ String.intercalate ", " captures ++ ")"

private def phpGuard (context : PhpContext) (name : String) (type : PsVerifiedIrType) : PhpEmit Unit := do
  let condition := match type with
    | .primitive .nat => "!(" ++ name ++ " instanceof \\GMP) || gmp_cmp(" ++ name ++ ", 0) < 0"
    | .primitive .int => "!(" ++ name ++ " instanceof \\GMP)"
    | .primitive .bool => "!is_bool(" ++ name ++ ")"
    | .primitive .string =>
        if context.helpers.contains "$__ps_utf8Valid" then
          "!is_string(" ++ name ++ ") || !$__ps_utf8Valid(" ++ name ++ ")"
        else "!is_string(" ++ name ++ ") || preg_match('//u', " ++ name ++ ") !== 1"
    | .primitive .char => "!is_string(" ++ name ++ ") || preg_match('/\\A.\\z/us', " ++ name ++ ") !== 1"
    | .primitive .unit => name ++ " !== null"
    | .function _ _ => "!(" ++ name ++ " instanceof \\Closure)"
    | .named _ _ => "!is_array(" ++ name ++ ")"
    | _ => "true"
  phpLine ("if (" ++ condition ++ ") {")
  phpIndent 1
  phpLine "throw new \\TypeError('PSC1_PHP_ARGUMENT_TYPE');"
  phpIndent (-1)
  phpLine "}"

private def phpInvoke (context : PhpContext) (fn : String) (args : List String) : String :=
  if context.scheduled then
    "(yield [" ++ fn ++ ", [" ++ String.intercalate ", " args ++ "]])"
  else fn ++ "(" ++ String.intercalate ", " args ++ ")"

private def phpIntrinsic
    (context : PhpContext) (op : PsVerifiedIrIntrinsic) (args : List String) : PhpEmit String := do
  let gmp (name : String) := name ++ "(" ++ String.intercalate ", " args ++ ")"
  match op, args with
  | .natAdd, [_, _] | .intAdd, [_, _] => phpBind (gmp "gmp_add")
  | .natMul, [_, _] | .intMul, [_, _] => phpBind (gmp "gmp_mul")
  | .intSub, [_, _] => phpBind (gmp "gmp_sub")
  | .natSub, [a, b] => phpBind ("(gmp_cmp(" ++ a ++ ", " ++ b ++ ") < 0 ? gmp_init(0) : gmp_sub(" ++ a ++ ", " ++ b ++ "))")
  | .natDiv, [a, b] => phpBind ("(gmp_cmp(" ++ b ++ ", 0) === 0 ? gmp_init(0) : gmp_div_q(" ++ a ++ ", " ++ b ++ ", GMP_ROUND_ZERO))")
  | .natMod, [a, b] => phpBind ("(gmp_cmp(" ++ b ++ ", 0) === 0 ? " ++ a ++ " : gmp_mod(" ++ a ++ ", " ++ b ++ "))")
  | .natEq, [a, b] | .intEq, [a, b] => phpBind ("(gmp_cmp(" ++ a ++ ", " ++ b ++ ") === 0)")
  | .natNe, [a, b] => phpBind ("(gmp_cmp(" ++ a ++ ", " ++ b ++ ") !== 0)")
  | .natLe, [a, b] | .intLe, [a, b] => phpBind ("(gmp_cmp(" ++ a ++ ", " ++ b ++ ") <= 0)")
  | .natLt, [a, b] | .intLt, [a, b] => phpBind ("(gmp_cmp(" ++ a ++ ", " ++ b ++ ") < 0)")
  | .intOfNat, [a] => pure a
  | .intRepr, [a] => phpBind ("gmp_strval(" ++ a ++ ", 10)")
  | .intNegSucc, [a] => phpBind ("gmp_neg(gmp_add(" ++ a ++ ", 1))")
  | .intNeg, [_] => phpBind (gmp "gmp_neg")
  | .boolNot, [a] => phpBind ("(!" ++ a ++ ")")
  | .boolEq, [a, b] | .stringEq, [a, b] => phpBind ("(" ++ a ++ " === " ++ b ++ ")")
  | .boolNe, [a, b] => phpBind ("(" ++ a ++ " !== " ++ b ++ ")")
  | .boolAnd, [a, b] => phpBind ("(" ++ a ++ " && " ++ b ++ ")")
  | .boolOr, [a, b] => phpBind ("(" ++ a ++ " || " ++ b ++ ")")
  | .charOfNat, [_] => phpBind (gmp "$__ps_charOfNat")
  | .charToNat, [_] => phpBind (gmp "$__ps_charToNat")
  | .stringSingleton, [a] => pure a
  | .stringPush, [a, b] | .stringAppend, [a, b] => phpBind ("(" ++ a ++ " . " ++ b ++ ")")
  | .stringLength, [a] => phpBind ("gmp_init(count($__ps_unicodeChars(" ++ a ++ ")))")
  | .stringUtf8ByteSize, [a] => phpBind ("gmp_init(strlen(" ++ a ++ "))")
  | .stringGet, [_, _] => phpBind (gmp "$__ps_stringGet")
  | .stringNext, [_, _] => phpBind (gmp "$__ps_stringNext")
  | .stringExtract, [_, _, _] => phpBind (gmp "$__ps_stringExtract")
  | .stringAtEnd, [a, b] => phpBind ("(gmp_cmp(" ++ b ++ ", strlen(" ++ a ++ ")) >= 0)")
  | .arrayEmptyWithCapacity, [_] => phpBind "[]"
  | .arraySize, [a] => phpBind ("gmp_init(count(" ++ a ++ "))")
  | .arrayPush, [a, value] => do
      let result ← phpBind a
      phpLine (result ++ "[] = " ++ value ++ ";")
      return result
  | .arrayGet, [a, index] => do
      phpLine ("if (gmp_cmp(" ++ index ++ ", 0) < 0 || gmp_cmp(" ++ index ++ ", count(" ++ a ++ ")) >= 0) {")
      phpIndent 1
      phpLine "throw new \\OutOfBoundsException('PSC1_ARRAY_GET_BOUNDS');"
      phpIndent (-1)
      phpLine "}"
      phpBind (a ++ "[gmp_intval(" ++ index ++ ")]")
  | .arrayGetD, [a, index, fallback] =>
      phpBind ("(gmp_cmp(" ++ index ++ ", 0) >= 0 && gmp_cmp(" ++ index ++ ", count(" ++ a ++ ")) < 0 ? " ++ a ++ "[gmp_intval(" ++ index ++ ")] : " ++ fallback ++ ")")
  | .arraySet, [a, index, value] | .arraySetIfInBounds, [a, index, value] => do
      let result ← phpBind a
      phpLine ("if (gmp_cmp(" ++ index ++ ", 0) >= 0 && gmp_cmp(" ++ index ++ ", count(" ++ a ++ ")) < 0) {")
      phpIndent 1
      phpLine (result ++ "[gmp_intval(" ++ index ++ ")] = " ++ value ++ ";")
      phpIndent (-1)
      match op with
      | .arraySet =>
          phpLine "} else {"
          phpIndent 1
          phpLine "throw new \\OutOfBoundsException('PSC1_ARRAY_SET_BOUNDS');"
          phpIndent (-1)
      | _ => pure ()
      phpLine "}"
      return result
  | .arrayMap, [fn, a] => do
      let result ← phpBind "[]"
      let item ← phpFresh "item"
      phpLine ("foreach (" ++ a ++ " as " ++ item ++ ") {")
      phpIndent 1
      phpLine (result ++ "[] = " ++ phpInvoke context fn [item] ++ ";")
      phpIndent (-1)
      phpLine "}"
      return result
  | .arrayFoldl, [fn, init, a, start, stop] => do
      let result ← phpBind init
      let index ← phpFresh "index"
      let limit ← phpBind ("gmp_init(count(" ++ a ++ "))")
      phpLine ("for (" ++ index ++ " = " ++ start ++ "; gmp_cmp(" ++ index ++ ", " ++ stop ++ ") < 0 && gmp_cmp(" ++ index ++ ", " ++ limit ++ ") < 0; " ++ index ++ " = gmp_add(" ++ index ++ ", 1)) {")
      phpIndent 1
      phpLine (result ++ " = " ++ phpInvoke context fn [result, a ++ "[gmp_intval(" ++ index ++ ")]"] ++ ";")
      phpIndent (-1)
      phpLine "}"
      return result
  | _, _ => throw "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY"

private def phpEmitExpr : Nat → PhpContext → PsVerifiedIrExpr → PhpEmit String
  | 0, _, _ => throw "PSC1_PHP_LOWERING_BUDGET"
  | fuel+1, context, expr => do
    let emit := phpEmitExpr fuel context
    match expr with
    | .literal (.natural value) => phpBind ("gmp_init(" ++ phpQuote (toString value) ++ ", 10)")
    | .literal (.integer value) => phpBind ("gmp_init(" ++ phpQuote (toString value) ++ ", 10)")
    | .literal (.bool value) => pure (if value then "true" else "false")
    | .literal (.string value) => pure (phpQuote value)
    | .literal .unit => pure "null"
    | .literal (.machineInteger _ _) => throw "PSC1_PHP_MACHINE_SCALAR_UNSUPPORTED"
    | .var name =>
        match context.locals.find? (fun item => item.1 == name) with
        | some item => pure item.2
        | none =>
          match context.globals.find? (fun item => item.1 == name) with
          | none => throw ("PSC1_PHP_UNKNOWN_SYMBOL: " ++ name)
          | some item =>
              if context.valueNames.contains name then
                phpBind (phpInvoke context item.2 [])
              else pure item.2
    | .intrinsic .boolAnd _ [left, right] =>
        phpEmitExpr fuel context (.ifE left right (.literal (.bool false)))
    | .intrinsic .boolOr _ [left, right] =>
        phpEmitExpr fuel context (.ifE left (.literal (.bool true)) right)
    | .intrinsic operation _ arguments =>
        let printed ← arguments.mapM emit
        phpIntrinsic context operation printed
    | .call fn _ arguments =>
        let target ← phpBind (← emit fn)
        let printed ← arguments.mapM emit
        phpBind (phpInvoke context target printed)
    | .letE name type value body =>
        let _ ← phpLift (phpType 4096 type)
        let printed ← emit value
        let localName ← phpFresh name
        phpLine (localName ++ " = " ++ printed ++ ";")
        phpEmitExpr fuel { context with locals := (name, localName) :: context.locals } body
    | .ifE condition yes no =>
        let printedCondition ← emit condition
        let result ← phpFresh "branch"
        phpLine ("if (" ++ printedCondition ++ " === true) {")
        phpIndent 1
        let printedYes ← emit yes
        phpLine (result ++ " = " ++ printedYes ++ ";")
        phpIndent (-1)
        phpLine "} else {"
        phpIndent 1
        let printedNo ← emit no
        phpLine (result ++ " = " ++ printedNo ++ ";")
        phpIndent (-1)
        phpLine "}"
        return result
    | .lambda parameters result body =>
        let target ← phpFresh "closure"
        let printedParameters ← parameters.mapM fun parameter => do
          let type ← phpLift (phpType 4096 parameter.type)
          let name ← phpFresh parameter.name
          return (parameter.name, name, type, parameter.type)
        let resultType ← phpLift (phpType 4096 result)
        let printed := printedParameters.map (fun p => "mixed " ++ p.2.1)
        phpLine (target ++ " = " ++ (if context.scheduled then "$__ps_wrap(" else "") ++
          "static function (" ++ String.intercalate ", " printed ++ ")" ++
          phpCapture context ++ ": " ++ (if context.scheduled then "\\Generator" else resultType) ++ " {")
        phpIndent 1
        phpLine ("if (func_num_args() !== " ++ toString parameters.length ++ ") { throw new \\ArgumentCountError('PSC1_PHP_ARITY'); }")
        if context.scheduled then phpLine "if (false) { yield; }"
        for p in printedParameters do phpGuard context p.2.1 p.2.2.2
        let locals := printedParameters.map (fun p => (p.1, p.2.1))
        let value ← phpEmitExpr fuel { context with locals := locals ++ context.locals } body
        phpLine ("return " ++ value ++ ";")
        phpIndent (-1)
        phpLine (if context.scheduled then "});" else "};")
        return target
    | .record _ _ fields =>
        let values ← fields.mapM fun field => do
          let value ← emit field.2
          return phpQuote field.1 ++ " => " ++ value
        phpBind ("[" ++ String.intercalate ", " values ++ "]")
    | .projection _ _ target field =>
        let value ← emit target
        phpBind (value ++ "[" ++ phpQuote field ++ "]")
    | .constructor _ constructorName _ fields =>
        let values ← fields.mapM fun field => do
          let value ← emit field.2
          return phpQuote field.1 ++ " => " ++ value
        phpBind ("[" ++ phpQuote constructorName ++ ", [" ++ String.intercalate ", " values ++ "]]")
    | .matchE _ _ scrutinee alternatives =>
        let target ← emit scrutinee
        let result ← phpFresh "match"
        let mut first := true
        for alternative in alternatives do
          phpLine ((if first then "if (" else "} elseif (") ++ target ++ "[0] === " ++ phpQuote alternative.1 ++ ") {")
          first := false
          phpIndent 1
          let mut locals := context.locals
          for binding in alternative.2.1 do
            let _ ← phpLift (phpType 4096 binding.type)
            let localName ← phpFresh binding.name
            phpLine (localName ++ " = " ++ target ++ "[1][" ++ phpQuote binding.field ++ "];")
            locals := (binding.name, localName) :: locals
          let value ← phpEmitExpr fuel { context with locals := locals } alternative.2.2
          phpLine (result ++ " = " ++ value ++ ";")
          phpIndent (-1)
        if first then
          phpLine "throw new \\UnexpectedValueException('PSC1_PHP_EMPTY_MATCH');"
        else
          phpLine "} else {"
          phpIndent 1
          phpLine "throw new \\UnexpectedValueException('PSC1_PHP_CONSTRUCTOR_TAG');"
          phpIndent (-1)
          phpLine "}"
        return result

-- A zero-parameter declaration is a value: reading its global may execute it.
-- Only a fully saturated, unshadowed function reference is a direct self call.
private def phpDirectSelfCall (declaration : PsVerifiedIrDeclaration)
    (bound : List String) (expr : PsVerifiedIrExpr) : Option (List PsVerifiedIrExpr) :=
  match expr with
  | .call (.var name) _ arguments =>
      if !declaration.parameters.isEmpty && name == declaration.name &&
          !bound.contains name && arguments.length == declaration.parameters.length then
        some arguments
      else none
  | _ => none

private def phpHasDirectSelfTail (declaration : PsVerifiedIrDeclaration) :
    Nat → List String → PsVerifiedIrExpr → Bool
  | 0, _, _ => false
  | fuel+1, bound, expr =>
      match phpDirectSelfCall declaration bound expr with
      | some _ => true
      | none =>
          match expr with
          | .letE name _ _ body =>
              phpHasDirectSelfTail declaration fuel (name :: bound) body
          | .ifE _ yes no =>
              phpHasDirectSelfTail declaration fuel bound yes ||
                phpHasDirectSelfTail declaration fuel bound no
          | .matchE _ _ _ alternatives =>
              alternatives.any (fun alternative =>
                phpHasDirectSelfTail declaration fuel
                  (alternative.2.1.map (fun binding => binding.name) ++ bound) alternative.2.2)
          | _ => false

-- Tail recurrence replaces only this declaration's frame. Calls in initializers,
-- arguments and other non-tail positions retain the generator scheduler.
-- Every new argument is evaluated and saved before any parameter is reassigned.
private def phpEmitDirectSelfTail (declaration : PsVerifiedIrDeclaration)
    (parameters : List String) : Nat → PhpContext → PsVerifiedIrExpr → PhpEmit Unit
  | 0, _, _ => throw "PSC1_PHP_LOWERING_BUDGET"
  | fuel+1, context, expr => do
      let emit := phpEmitExpr fuel context
      match phpDirectSelfCall declaration (context.locals.map (fun item => item.1)) expr with
      | some arguments =>
          let values ← arguments.mapM (fun argument => do
            let value ← emit argument
            phpBind value)
          for (parameter, value) in parameters.zip values do
            phpLine (parameter ++ " = " ++ value ++ ";")
          phpLine "continue;"
      | none =>
          match expr with
          | .letE name type value body =>
              let _ ← phpLift (phpType 4096 type)
              let printed ← emit value
              let localName ← phpFresh name
              phpLine (localName ++ " = " ++ printed ++ ";")
              phpEmitDirectSelfTail declaration parameters fuel
                { context with locals := (name, localName) :: context.locals } body
          | .ifE condition yes no =>
              let printedCondition ← emit condition
              phpLine ("if (" ++ printedCondition ++ " === true) {")
              phpIndent 1
              phpEmitDirectSelfTail declaration parameters fuel context yes
              phpIndent (-1)
              phpLine "} else {"
              phpIndent 1
              phpEmitDirectSelfTail declaration parameters fuel context no
              phpIndent (-1)
              phpLine "}"
          | .matchE _ _ scrutinee alternatives =>
              let target ← emit scrutinee
              let mut first := true
              for alternative in alternatives do
                phpLine ((if first then "if (" else "} elseif (") ++ target ++
                  "[0] === " ++ phpQuote alternative.1 ++ ") {")
                first := false
                phpIndent 1
                let mut locals := context.locals
                for binding in alternative.2.1 do
                  let _ ← phpLift (phpType 4096 binding.type)
                  let localName ← phpFresh binding.name
                  phpLine (localName ++ " = " ++ target ++ "[1][" ++ phpQuote binding.field ++ "];")
                  locals := (binding.name, localName) :: locals
                phpEmitDirectSelfTail declaration parameters fuel
                  { context with locals := locals } alternative.2.2
                phpIndent (-1)
              if first then
                phpLine "throw new \\UnexpectedValueException('PSC1_PHP_EMPTY_MATCH');"
              else
                phpLine "} else {"
                phpIndent 1
                phpLine "throw new \\UnexpectedValueException('PSC1_PHP_CONSTRUCTOR_TAG');"
                phpIndent (-1)
                phpLine "}"
          | _ =>
              let value ← emit expr
              phpLine ("return " ++ value ++ ";")

private def phpEmitDeclaration (context : PhpContext)
    (declaration : PsVerifiedIrDeclaration) : PhpEmit Nat := do
  let symbol ← match context.globals.find? (fun item => item.1 == declaration.name) with
    | some entry => pure entry.2
    | none => throw "PSC1_PHP_INTERNAL_SYMBOL"
  let parameters ← declaration.parameters.mapM fun parameter => do
    let type ← phpLift (phpType 4096 parameter.type)
    let name ← phpFresh parameter.name
    return (parameter.name, name, type, parameter.type)
  let resultType ← phpLift (phpType 4096 declaration.resultType)
  phpLine ("// declaration " ++ phpQuote declaration.name)
  for p in parameters do phpLine ("/** @param " ++ p.2.2.1 ++ " " ++ p.2.1 ++ " */")
  phpLine ("/** @return " ++ (if context.scheduled then "\\Generator<mixed, mixed, mixed, " ++ resultType ++ ">" else resultType) ++ " */")
  let line := (← get).lines.size + 1
  phpLine (symbol ++ " = " ++ (if context.scheduled then "$__ps_wrap(" else "") ++
    "static function (" ++ String.intercalate ", " (parameters.map (fun p => "mixed " ++ p.2.1)) ++ ")" ++
    phpCapture context ++ ": " ++ (if context.scheduled then "\\Generator" else resultType) ++ " {")
  phpIndent 1
  phpLine ("if (func_num_args() !== " ++ toString parameters.length ++ ") { throw new \\ArgumentCountError('PSC1_PHP_ARITY'); }")
  if context.scheduled then phpLine "if (false) { yield; }"
  let locals := parameters.map (fun parameter => (parameter.1, parameter.2.1))
  let hasTail := phpHasDirectSelfTail declaration 4096
    (declaration.parameters.map (fun parameter => parameter.name)) declaration.body
  if hasTail then
    phpLine "while (true) {"
    phpIndent 1
  for parameter in parameters do phpGuard context parameter.2.1 parameter.2.2.2
  if hasTail then
    phpEmitDirectSelfTail declaration (parameters.map (fun parameter => parameter.2.1))
      4096 { context with locals } declaration.body
  else
    let value ← phpEmitExpr 4096 { context with locals } declaration.body
    phpLine ("return " ++ value ++ ";")
  if hasTail then
    phpIndent (-1)
    phpLine "}"
  phpIndent (-1)
  phpLine (if context.scheduled then "});" else "};")
  phpLine ""
  return line

private def phpPublicScalar : PsVerifiedIrType → Bool
  | .primitive .nat | .primitive .int | .primitive .bool
  | .primitive .char | .primitive .string | .primitive .unit => true
  | _ => false

def psPhpEmitValidatedModule
    (irModule : PsValidatedIrModule) (publicNames : List String) (ioAbi : Bool := false) :
    Except String PsPhpPrintedModule := do
  let _ ← (psStrictValidateModule irModule.raw).mapError (fun _ => "PSC1_PHP_IR_VALIDATION_FAILED")
  let raw := irModule.raw
  if !raw.imports.isEmpty then throw "PSC1_PHP_EXTERNAL_IMPORT_UNSUPPORTED"
  for declaration in raw.declarations do
    if !declaration.typeParameters.isEmpty then throw "PSC1_PHP_SPECIALIZATION_REQUIRED"
    let _ ← phpType 4096 declaration.resultType
    for parameter in declaration.parameters do
      discard (phpType 4096 parameter.type)
  for item in raw.structures do
    if !item.typeParameters.isEmpty then throw "PSC1_PHP_SPECIALIZATION_REQUIRED"
    for field in item.fields do
      discard (phpType 4096 field.type)
  for item in raw.inductives do
    if !item.typeParameters.isEmpty then throw "PSC1_PHP_SPECIALIZATION_REQUIRED"
    for ctor in item.constructors do
      for field in ctor.fields do
        discard (phpType 4096 field.type)
  let mut seenPublic : List String := []
  for name in publicNames do
    if seenPublic.contains name then throw ("PSC1_PHP_DUPLICATE_PUBLIC_DECLARATION: " ++ name)
    seenPublic := name :: seenPublic
    match raw.declarations.find? (fun d => d.name == name) with
    | none => throw ("PSC1_PHP_UNKNOWN_PUBLIC_DECLARATION: " ++ name)
    | some d =>
        if !phpPublicScalar d.resultType || !d.parameters.all (fun p => phpPublicScalar p.type || (ioAbi && psBackendIoDispatcherType p.type)) then
          throw ("PSC1_PHP_PUBLIC_ABI_UNSUPPORTED: " ++ name)
  let valueNames := (raw.declarations.filter (fun d => d.parameters.isEmpty)).map (fun d => d.name)
  let requested := raw.declarations.flatMap fun declaration =>
    phpTypeRequirements 4096 declaration.resultType ++
    declaration.parameters.flatMap (fun parameter => phpTypeRequirements 4096 parameter.type) ++
    phpExprRequirements valueNames 4096 (declaration.parameters.map (fun p => p.name)) declaration.body
  let requirements := PsScriptRuntimeReference.Php.psPhpRuntimeClosure requested
  let runtimeSource := PsScriptRuntimeReference.Php.psPhpSelectedRuntimeSource requirements
  let globals := (raw.declarations.zipIdx).map fun (d, index) =>
    (d.name, "$g" ++ toString index ++ "_" ++ phpStem d.name)
  let context : PhpContext := {
    globals, valueNames,
    helpers := PsScriptRuntimeReference.Php.psPhpRuntimeVariables requirements,
    scheduled := requirements.contains "calls"
  }
  let sourcePrefix := "<?php\n" ++
    "// Generated by ProofScript PSC1 DirectPHP. Public API: return value of require.\n" ++
    "declare(strict_types=1);\n\nreturn (static function (): array {\n" ++ runtimeSource
  let initial : PhpState := { lines := (sourcePrefix.dropEnd 1).toString.splitOn "\n" |>.toArray }
  let emit : PhpEmit (List (String × Nat)) := do
    for entry in globals do phpLine (entry.2 ++ " = null;")
    if !globals.isEmpty then phpLine ""
    let mut positions := []
    for declaration in raw.declarations do
      let line ← phpEmitDeclaration context declaration
      positions := positions ++ [(declaration.name, line)]
    phpLine "return ["
    phpIndent 1
    for name in publicNames do
      let symbol ← match globals.find? (fun p => p.1 == name) with
        | some p => pure p.2
        | none => throw "PSC1_PHP_INTERNAL_PUBLIC_SYMBOL"
      phpLine (phpQuote name ++ " => " ++ symbol ++ (if valueNames.contains name then "()" else "") ++ ",")
    phpIndent (-1)
    phpLine "];"
    phpIndent (-1)
    phpLine "})();"
    return positions
  let (positions, state) ← emit.run initial
  let composer := "{\n  \"type\": \"library\",\n  \"require\": {\n    \"php\": \">=8.5\"" ++
    (if requirements.contains "gmp" then ",\n    \"ext-gmp\": \"*\"" else "") ++
    "\n  }\n}\n"
  return {
    source := String.intercalate "\n" state.lines.toList ++ "\n",
    composer, runtimeSource,
    runtimeRequirements := requirements,
    declarations := globals,
    declarationLines := positions
  }

end PsScriptEmitterReference.Php
