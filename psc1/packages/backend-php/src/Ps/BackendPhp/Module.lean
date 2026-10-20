import Ps.CompilerIr.Validate
import Ps.BackendPhp.Runtime

structure PsPhpPrintedModule where
  source : String
  composer : String
  runtimeSource : String
  runtimeVersion : String := psPhpRuntimeVersion
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
    (valueNames : List String) : Nat → PsVerifiedIrExpr → List String
  | 0, _ => []
  | n+1, expr =>
    let visit := phpExprRequirements valueNames n
    match expr with
    | .literal (.natural _) | .literal (.integer _) => ["gmp"]
    | .literal _ => []
    | .var name => if valueNames.contains name then ["calls"] else []
    | .intrinsic op types args =>
        phpIntrinsicRequirements op ++ types.flatMap (phpTypeRequirements n) ++ args.flatMap visit
    | .lambda parameters result body =>
        parameters.flatMap (fun p => phpTypeRequirements n p.type) ++
          phpTypeRequirements n result ++ visit body
    | .call fn _ args => "calls" :: (visit fn ++ args.flatMap visit)
    | .letE _ type value body => phpTypeRequirements n type ++ visit value ++ visit body
    | .ifE condition yes no => visit condition ++ visit yes ++ visit no
    | .record _ _ fields | .constructor _ _ _ fields => fields.flatMap (fun field => visit field.2)
    | .projection _ _ target _ => visit target
    | .matchE _ _ target alternatives => visit target ++ alternatives.flatMap (fun alt => visit alt.2.2)

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

private def phpGuard (name : String) (type : PsVerifiedIrType) : PhpEmit Unit := do
  let condition := match type with
    | .primitive .nat => "!(" ++ name ++ " instanceof \\GMP) || gmp_cmp(" ++ name ++ ", 0) < 0"
    | .primitive .int => "!(" ++ name ++ " instanceof \\GMP)"
    | .primitive .bool => "!is_bool(" ++ name ++ ")"
    | .primitive .string => "!is_string(" ++ name ++ ") || preg_match('//u', " ++ name ++ ") !== 1"
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
        for p in printedParameters do phpGuard p.2.1 p.2.2.2
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
  for parameter in parameters do phpGuard parameter.2.1 parameter.2.2.2
  let locals := parameters.map (fun parameter => (parameter.1, parameter.2.1))
  let value ← phpEmitExpr 4096 { context with locals } declaration.body
  phpLine ("return " ++ value ++ ";")
  phpIndent (-1)
  phpLine (if context.scheduled then "});" else "};")
  phpLine ""
  return line

private def phpPublicScalar : PsVerifiedIrType → Bool
  | .primitive .nat | .primitive .int | .primitive .bool
  | .primitive .char | .primitive .string | .primitive .unit => true
  | _ => false

def psPhpEmitValidatedModule
    (irModule : PsValidatedIrModule) (publicNames : List String) :
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
        if !phpPublicScalar d.resultType || !d.parameters.all (fun p => phpPublicScalar p.type) then
          throw ("PSC1_PHP_PUBLIC_ABI_UNSUPPORTED: " ++ name)
  let valueNames := (raw.declarations.filter (fun d => d.parameters.isEmpty)).map (fun d => d.name)
  let requested := raw.declarations.flatMap fun declaration =>
    phpTypeRequirements 4096 declaration.resultType ++
    declaration.parameters.flatMap (fun parameter => phpTypeRequirements 4096 parameter.type) ++
    phpExprRequirements valueNames 4096 declaration.body
  let requirements := psPhpRuntimeClosure requested
  let runtimeSource := psPhpSelectedRuntimeSource requirements
  let globals := (raw.declarations.zipIdx).map fun (d, index) =>
    (d.name, "$g" ++ toString index ++ "_" ++ phpStem d.name)
  let context : PhpContext := {
    globals, valueNames,
    helpers := psPhpRuntimeVariables requirements,
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
