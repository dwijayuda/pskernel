import Ps.CompilerIr.Validate
import Ps.Bridge.Json
import Ps.BackendPython.Runtime
import Ps.BackendCommon.Plan
import Ps.BackendCommon.Source

structure PsPythonOutput where
  source : String
  stub : String
  runtimeSource : String
  runtimeHelpers : List String
  declarationLines : List (Prod String Nat)

namespace PsPython

def cat (parts : List String) : String := psTextJoin "" parts

def decimal (value : Nat) : String := Int.repr (Int.ofNat value)

def asciiLetter (code : Nat) : Bool :=
  (Nat.ble 65 code && Nat.ble code 90) || (Nat.ble 97 code && Nat.ble code 122)

def asciiDigit (code : Nat) : Bool := Nat.ble 48 code && Nat.ble code 57

def encodePartAcc (chars : List Char) (builder : PsTextBuilder) : String :=
  match chars with
  | List.nil => psTextBuilderFinish builder
  | List.cons char rest =>
      let code : Nat := Char.toNat char;
      let part : String :=
        if Nat.beq code 95 then "__"
        else if asciiLetter code || asciiDigit code then String.singleton char
        else cat ["_u", decimal code, "_"];
      encodePartAcc rest (psTextBuilderAppend builder part)

def encodePart (name : String) : String :=
  encodePartAcc (psJsonStringToChars name) psTextBuilderEmpty

def globalName (name : String) : String := cat ["_psc_g_", encodePart name]
def valueName (name : String) : String := cat ["_psc_value_", encodePart name]

def reservedPrefix (chars : List Char) : Bool :=
  match chars with
  | List.nil => false
  | List.cons a rest =>
      match rest with
      | List.nil => false
      | List.cons b rest =>
          match rest with
          | List.nil => false
          | List.cons c rest =>
              match rest with
              | List.nil => false
              | List.cons d rest =>
                  match rest with
                  | List.nil => false
                  | List.cons e _ =>
                      Nat.beq (Char.toNat a) 95 && Nat.beq (Char.toNat b) 112 &&
                        Nat.beq (Char.toNat c) 115 && Nat.beq (Char.toNat d) 99 &&
                        Nat.beq (Char.toNat e) 95

def publicNameAllowed (name : String) : Bool :=
  let chars : List Char := psJsonStringToChars name;
  let keywords : List String :=
    ["False", "None", "True", "and", "as", "assert", "async", "await",
      "break", "class", "continue", "def", "del", "elif", "else", "except", "finally",
      "for", "from", "global", "if", "import", "in", "is", "lambda", "nonlocal",
      "not", "or", "pass", "raise", "return", "try", "while", "with", "yield"];
  !reservedPrefix chars && !psStringEq name "__all__" && !psBackendNameSeen name keywords &&
    match chars with
    | List.nil => false
    | List.cons char rest =>
        (Nat.beq (Char.toNat char) 95 || asciiLetter (Char.toNat char)) &&
          psBackendSourceAll (fun (other : Char) =>
            let code : Nat := Char.toNat other;
            Nat.beq code 95 || asciiLetter code || asciiDigit code) rest

def scalarType (type : PsVerifiedIrType) : Except String String :=
  match type with
  | PsVerifiedIrType.primitive scalar =>
      match scalar with
      | PsVerifiedIrPrimitiveType.nat => Except.ok "_psc_b.int"
      | PsVerifiedIrPrimitiveType.int => Except.ok "_psc_b.int"
      | PsVerifiedIrPrimitiveType.bool => Except.ok "_psc_b.bool"
      | PsVerifiedIrPrimitiveType.char => Except.ok "_psc_b.str"
      | PsVerifiedIrPrimitiveType.string => Except.ok "_psc_b.str"
      | PsVerifiedIrPrimitiveType.unit => Except.ok "None"
      | _ => Except.error "PSC1_PYTHON_PUBLIC_ABI_UNSUPPORTED: expected Nat, Int, Bool, Char, String or Unit"
  | _ => Except.error "PSC1_PYTHON_PUBLIC_ABI_UNSUPPORTED: expected Nat, Int, Bool, Char, String or Unit"

def checkType (fuel : Nat) : PsVerifiedIrType -> Except String Unit :=
  match fuel with
  | Nat.zero => fun (_type : PsVerifiedIrType) => Except.error "PSC1_PYTHON_TYPE_BUDGET"
  | Nat.succ remaining =>
      fun (type : PsVerifiedIrType) =>
        let check : PsVerifiedIrType -> Except String Unit := checkType remaining;
        match type with
        | PsVerifiedIrType.primitive scalar =>
            if psBackendActivePrimitive scalar then Except.ok Unit.unit
            else Except.error "PSC1_PYTHON_CAPABILITY_UNSUPPORTED: unresolved, generic or machine/float type"
        | PsVerifiedIrType.function parameters result => do
            psBackendSourceForExcept check parameters
            check result
        | PsVerifiedIrType.named _ arguments => psBackendSourceForExcept check arguments
        | _ => Except.error "PSC1_PYTHON_CAPABILITY_UNSUPPORTED: unresolved, generic or machine/float type"

def hexDigits (fuel : Nat) : Nat -> String -> String :=
  match fuel with
  | Nat.zero => fun (_value : Nat) (acc : String) => acc
  | Nat.succ remaining =>
      fun (value : Nat) (acc : String) =>
        if Nat.beq value 0 then acc
        else hexDigits remaining (Nat.div value 16)
          (cat [psJsonHexDigit (Nat.mod value 16), acc])

def naturalLiteral (value : Nat) : String :=
  let text : String := decimal value;
  if Nat.blt (String.utf8ByteSize text) 600 then text
  else cat ["0x", hexDigits (Nat.succ (String.utf8ByteSize text)) value ""]

def magnitudeChars (chars : List Char) (acc : Nat) : Nat :=
  match chars with
  | List.nil => acc
  | List.cons char rest =>
      magnitudeChars rest (Nat.add (Nat.mul acc 10) (Nat.sub (Char.toNat char) 48))

def integerMagnitude (value : Int) : Prod Bool Nat :=
  let chars : List Char := psJsonStringToChars (Int.repr value);
  match chars with
  | List.nil => Prod.mk false 0
  | List.cons first rest =>
      if Nat.beq (Char.toNat first) 45 then Prod.mk true (magnitudeChars rest 0)
      else Prod.mk false (magnitudeChars chars 0)

def literal (value : PsVerifiedIrLiteral) : Except String String :=
  match value with
  | PsVerifiedIrLiteral.natural number => Except.ok (naturalLiteral number)
  | PsVerifiedIrLiteral.integer number =>
      let parts : Prod Bool Nat := integerMagnitude number;
      Except.ok (cat [if parts.fst then "-" else "", naturalLiteral parts.snd])
  | PsVerifiedIrLiteral.string text => Except.ok (psJsonQuote text)
  | PsVerifiedIrLiteral.bool flag => Except.ok (if flag then "True" else "False")
  | PsVerifiedIrLiteral.unit => Except.ok "None"
  | PsVerifiedIrLiteral.machineInteger _ _ => Except.error "PSC1_PYTHON_SCALAR_CAPABILITY_UNQUALIFIED"

structure EmitState where
  linesRev : List String
  lineCount : Nat
  indent : Nat
  nextIndex : Nat
  helpers : List String
  originsRev : List (Prod String Nat)

def initialState : EmitState := EmitState.mk List.nil 0 0 0 List.nil List.nil
def Emit (Value : Type) : Type := PsBackendStateExcept EmitState String Value
def Scope : Type := List (Prod String String)

def padding (count : Nat) (builder : PsTextBuilder) : String :=
  match count with
  | Nat.zero => psTextBuilderFinish builder
  | Nat.succ remaining => padding remaining (psTextBuilderAppend builder "    ")

def line (text : String) : Emit Unit :=
  psBackendStateModify (fun (state : EmitState) =>
    EmitState.mk (List.cons (cat [padding state.indent psTextBuilderEmpty, text]) state.linesRev)
      (Nat.succ state.lineCount) state.indent state.nextIndex state.helpers state.originsRev)

def fresh (hint : String) : Emit String :=
  psBackendStateBind (psBackendStateGet Unit.unit) (fun (state : EmitState) =>
    psBackendStateBind
      (psBackendStateSet (EmitState.mk state.linesRev state.lineCount state.indent
        (Nat.succ state.nextIndex) state.helpers state.originsRev))
      (fun (_unit : Unit) =>
        psBackendStatePure (cat ["_psc_l", decimal state.nextIndex, "_", encodePart hint])))

def helper (name : String) : Emit Unit :=
  psBackendStateModify (fun (state : EmitState) =>
    EmitState.mk state.linesRev state.lineCount state.indent state.nextIndex
      (if psBackendNameSeen name state.helpers then state.helpers else psListAppend state.helpers [name])
      state.originsRev)

def shiftIndent (increase : Bool) : Emit Unit :=
  psBackendStateModify (fun (state : EmitState) =>
    EmitState.mk state.linesRev state.lineCount
      (if increase then Nat.succ state.indent else Nat.sub state.indent 1)
      state.nextIndex state.helpers state.originsRev)

def withIndent {Value : Type} (action : Emit Value) : Emit Value :=
  psBackendStateBind (shiftIndent true) (fun (_unit : Unit) =>
    psBackendStateBind action (fun (value : Value) =>
      psBackendStateBind (shiftIndent false) (fun (_unit : Unit) => psBackendStatePure value)))

def bindValue (value : String) : Emit String :=
  psBackendStateBind (fresh "tmp") (fun (name : String) =>
    psBackendStateBind (line (cat [name, " = ", value]))
      (fun (_unit : Unit) => psBackendStatePure name))

def tuple (values : List String) : String :=
  match values with
  | List.nil => "()"
  | List.cons value rest =>
      if psListIsEmpty rest then cat ["(", value, ",)"]
      else cat ["(", psTextJoin ", " values, ")"]

def emitCall (fn : String) (args : List String) (tail : Bool) : Emit String :=
  psBackendStateBind (helper "calls") (fun (_unit : Unit) =>
    bindValue (cat ["(yield (", fn, ", ", tuple args, ", ", if tail then "True" else "False", "))"]))

def emitHelper (id name : String) (args : List String) : Emit String :=
  psBackendStateBind (helper id) (fun (_unit : Unit) =>
    bindValue (cat [name, "(", psTextJoin ", " args, ")"]))

def binary (args : List String) (symbol : String) : Emit String :=
  match args with
  | [a, b] => bindValue (cat ["(", a, " ", symbol, " ", b, ")"])
  | _ => psBackendStateThrow "PSC1_PYTHON_INTRINSIC_ARITY"

def unary (args : List String) (before after : String) : Emit String :=
  match args with
  | [a] => bindValue (cat [before, a, after])
  | _ => psBackendStateThrow "PSC1_PYTHON_INTRINSIC_ARITY"

def emitIntrinsic (operation : PsVerifiedIrIntrinsic) (args : List String)
    (tail : Bool) : Emit String :=
  match operation with
  | PsVerifiedIrIntrinsic.natAdd => binary args "+"
  | PsVerifiedIrIntrinsic.intAdd => binary args "+"
  | PsVerifiedIrIntrinsic.stringPush => binary args "+"
  | PsVerifiedIrIntrinsic.stringAppend => binary args "+"
  | PsVerifiedIrIntrinsic.natMul => binary args "*"
  | PsVerifiedIrIntrinsic.intMul => binary args "*"
  | PsVerifiedIrIntrinsic.intSub => binary args "-"
  | PsVerifiedIrIntrinsic.natEq => binary args "=="
  | PsVerifiedIrIntrinsic.intEq => binary args "=="
  | PsVerifiedIrIntrinsic.boolEq => binary args "=="
  | PsVerifiedIrIntrinsic.stringEq => binary args "=="
  | PsVerifiedIrIntrinsic.natNe => binary args "!="
  | PsVerifiedIrIntrinsic.boolNe => binary args "!="
  | PsVerifiedIrIntrinsic.natLe => binary args "<="
  | PsVerifiedIrIntrinsic.intLe => binary args "<="
  | PsVerifiedIrIntrinsic.natLt => binary args "<"
  | PsVerifiedIrIntrinsic.intLt => binary args "<"
  | PsVerifiedIrIntrinsic.natSub =>
      match args with
      | [a, b] => bindValue (cat ["(", a, " - ", b, " if ", a, " >= ", b, " else 0)"])
      | _ => psBackendStateThrow "PSC1_PYTHON_INTRINSIC_ARITY"
  | PsVerifiedIrIntrinsic.natDiv =>
      match args with
      | [a, b] => bindValue (cat ["(0 if ", b, " == 0 else ", a, " // ", b, ")"])
      | _ => psBackendStateThrow "PSC1_PYTHON_INTRINSIC_ARITY"
  | PsVerifiedIrIntrinsic.natMod =>
      match args with
      | [a, b] => bindValue (cat ["(", a, " if ", b, " == 0 else ", a, " % ", b, ")"])
      | _ => psBackendStateThrow "PSC1_PYTHON_INTRINSIC_ARITY"
  | PsVerifiedIrIntrinsic.intOfNat =>
      match args with
      | [a] => psBackendStatePure a
      | _ => psBackendStateThrow "PSC1_PYTHON_INTRINSIC_ARITY"
  | PsVerifiedIrIntrinsic.stringSingleton =>
      match args with
      | [a] => psBackendStatePure a
      | _ => psBackendStateThrow "PSC1_PYTHON_INTRINSIC_ARITY"
  | PsVerifiedIrIntrinsic.intNeg => unary args "(-" ")"
  | PsVerifiedIrIntrinsic.intNegSucc => unary args "(-(" " + 1))"
  | PsVerifiedIrIntrinsic.intRepr => emitHelper "int-repr" "_psc_int_repr" args
  | PsVerifiedIrIntrinsic.boolNot => unary args "(not " ")"
  | PsVerifiedIrIntrinsic.boolAnd => psBackendStateThrow "PSC1_PYTHON_SHORT_CIRCUIT_LOWERING"
  | PsVerifiedIrIntrinsic.boolOr => psBackendStateThrow "PSC1_PYTHON_SHORT_CIRCUIT_LOWERING"
  | PsVerifiedIrIntrinsic.charOfNat => emitHelper "char-of-nat" "_psc_char_of_nat" args
  | PsVerifiedIrIntrinsic.charToNat =>
      psBackendStateBind (helper "builtins") (fun (_unit : Unit) => unary args "_psc_b.ord(" ")")
  | PsVerifiedIrIntrinsic.stringLength =>
      psBackendStateBind (helper "builtins") (fun (_unit : Unit) => unary args "_psc_b.len(" ")")
  | PsVerifiedIrIntrinsic.arraySize =>
      psBackendStateBind (helper "builtins") (fun (_unit : Unit) => unary args "_psc_b.len(" ")")
  | PsVerifiedIrIntrinsic.stringUtf8ByteSize =>
      psBackendStateBind (helper "builtins") (fun (_unit : Unit) => unary args "_psc_b.len(" ".encode(\"utf-8\"))")
  | PsVerifiedIrIntrinsic.stringGet => emitHelper "string-get" "_psc_string_get" args
  | PsVerifiedIrIntrinsic.stringNext => emitHelper "string-next" "_psc_string_next" args
  | PsVerifiedIrIntrinsic.stringExtract => emitHelper "string-extract" "_psc_string_extract" args
  | PsVerifiedIrIntrinsic.stringAtEnd =>
      psBackendStateBind (helper "builtins") (fun (_unit : Unit) =>
        match args with
        | [source, position] => bindValue (cat ["(", position, " >= _psc_b.len(", source, ".encode(\"utf-8\")))"])
        | _ => psBackendStateThrow "PSC1_PYTHON_INTRINSIC_ARITY")
  | PsVerifiedIrIntrinsic.arrayEmptyWithCapacity => bindValue "()"
  | PsVerifiedIrIntrinsic.arrayPush =>
      match args with
      | [array, value] => bindValue (cat [array, " + (", value, ",)"])
      | _ => psBackendStateThrow "PSC1_PYTHON_INTRINSIC_ARITY"
  | PsVerifiedIrIntrinsic.arrayGet => emitHelper "array-get" "_psc_array_get" args
  | PsVerifiedIrIntrinsic.arrayGetD => emitHelper "array-get-d" "_psc_array_get_d" args
  | PsVerifiedIrIntrinsic.arraySet => emitHelper "array-set" "_psc_array_set" args
  | PsVerifiedIrIntrinsic.arraySetIfInBounds => emitHelper "array-set-if" "_psc_array_set_if" args
  | PsVerifiedIrIntrinsic.arrayMap =>
      psBackendStateBind (helper "array-map") (fun (_unit : Unit) => emitCall "_psc_array_map" args tail)
  | PsVerifiedIrIntrinsic.arrayFoldl =>
      psBackendStateBind (helper "array-foldl") (fun (_unit : Unit) => emitCall "_psc_array_foldl" args tail)
  | _ => psBackendStateThrow "PSC1_PYTHON_INTRINSIC_CAPABILITY_UNQUALIFIED"

def structureFields (module : PsVerifiedIrModule) (name : String) : Except String (List String) :=
  match psBackendSourceFind (fun (info : PsVerifiedIrStructure) => psStringEq info.name name) module.structures with
  | Option.none => Except.error (cat ["PSC1_PYTHON_STRUCTURE_MISSING: ", name])
  | Option.some info => Except.ok (psListMap (fun (field : PsVerifiedIrStructureField) => field.name) info.fields)

def constructorFields (module : PsVerifiedIrModule) (owner name : String) : Except String (List String) :=
  match psBackendSourceFind (fun (info : PsVerifiedIrInductive) => psStringEq info.name owner) module.inductives with
  | Option.none => Except.error (cat ["PSC1_PYTHON_INDUCTIVE_MISSING: ", owner])
  | Option.some info =>
      match psBackendSourceFind (fun (constructor : PsVerifiedIrConstructor) =>
          psStringEq constructor.name name) info.constructors with
      | Option.none => Except.error (cat ["PSC1_PYTHON_CONSTRUCTOR_MISSING: ", name])
      | Option.some constructor =>
          Except.ok (psListMap (fun (field : PsVerifiedIrConstructorField) => field.name) constructor.fields)

def fieldPositionFrom (fields : List String) (name : String) (index : Nat) : Except String Nat :=
  match fields with
  | List.nil => Except.error (cat ["PSC1_PYTHON_FIELD_MISSING: ", name])
  | List.cons field rest =>
      if psStringEq field name then Except.ok index else fieldPositionFrom rest name (Nat.succ index)

def fieldPosition (fields : List String) (name : String) : Except String Nat :=
  fieldPositionFrom fields name 0

def emitParameter (parameter : PsVerifiedIrParameter) : Emit (Prod String String) :=
  psBackendStateBind (psBackendStateLift (checkType 256 parameter.type)) (fun (_unit : Unit) =>
    psBackendStateBind (fresh parameter.name) (fun (name : String) =>
      psBackendStatePure (Prod.mk parameter.name name)))

def emitParameters (scope : Scope) (parameters : List PsVerifiedIrParameter) :
    Emit (Prod Scope (List String)) :=
  psBackendStateBind (psBackendSourceMapState emitParameter parameters)
    (fun (entries : List (Prod String String)) =>
      psBackendStatePure (Prod.mk (psListAppend entries scope)
        (psListMap (fun (entry : Prod String String) => entry.snd) entries)))

def checkTypes (types : List PsVerifiedIrType) : Emit Unit :=
  psBackendStateLift (psBackendSourceForExcept (checkType 256) types)

def emitNamedFields (emit : PsVerifiedIrExpr -> Bool -> Emit String)
    (fields : List (Prod String PsVerifiedIrExpr)) : Emit (List (Prod String String)) :=
  psBackendSourceMapState
    (fun (field : Prod String PsVerifiedIrExpr) =>
      psBackendStateBind (emit field.snd false) (fun (value : String) =>
        psBackendStatePure (Prod.mk field.fst value))) fields

def orderedValues (schema : List String) (values : List (Prod String String)) : Except String (List String) :=
  psListMapExcept (fun (field : String) =>
    match psBackendSourceFind (fun (value : Prod String String) => psStringEq value.fst field) values with
    | Option.some value => Except.ok value.snd
    | Option.none => Except.error (cat ["PSC1_PYTHON_FIELD_MISSING: ", field])) schema

def assignExpression (emit : PsVerifiedIrExpr -> Bool -> Emit String)
    (body : PsVerifiedIrExpr) (tail : Bool) (result : String) : Emit Unit :=
  psBackendStateBind (emit body tail) (fun (value : String) => line (cat [result, " = ", value]))

def emitBindings (fields : List String) (scrutinee : String)
    (bindings : List PsVerifiedIrMatchBinding) : Emit (List (Prod String String)) :=
  psBackendSourceMapState (fun (binding : PsVerifiedIrMatchBinding) =>
    psBackendStateBind (psBackendStateLift (checkType 256 binding.type)) (fun (_unit : Unit) =>
      psBackendStateBind (psBackendStateLift (fieldPosition fields binding.field)) (fun (index : Nat) =>
        psBackendStateBind (fresh binding.name) (fun (name : String) =>
          psBackendStateBind (line (cat [name, " = ", scrutinee, "[", decimal (Nat.succ index), "]"]))
            (fun (_unit : Unit) => psBackendStatePure (Prod.mk binding.name name)))))) bindings

def emitAlternative
    (emit : Scope -> PsVerifiedIrExpr -> Bool -> Emit String)
    (module : PsVerifiedIrModule) (scope : Scope) (owner scrutinee result : String)
    (first : Option String) (tail : Bool)
    (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) : Emit Unit :=
  let name : String := alternative.fst;
  let bindings : List PsVerifiedIrMatchBinding := alternative.snd.fst;
  let body : PsVerifiedIrExpr := alternative.snd.snd;
  psBackendStateBind (psBackendStateLift (constructorFields module owner name))
    (fun (fields : List String) =>
      let branchPrefix : String :=
        match first with
        | Option.some firstName => if psStringEq firstName name then "if " else "elif "
        | Option.none => "elif ";
      psBackendStateBind (line (cat [branchPrefix, scrutinee, "[0] == ", psJsonQuote name, ":"]))
        (fun (_unit : Unit) =>
          withIndent (psBackendStateBind (emitBindings fields scrutinee bindings)
            (fun (entries : List (Prod String String)) =>
              assignExpression (emit (psListAppend entries scope)) body tail result))))

def firstAlternative (alternatives : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) :
    Option String :=
  match alternatives with
  | List.nil => Option.none
  | List.cons alternative _ => Option.some alternative.fst

def expression (fuel : Nat) :
    PsVerifiedIrModule -> Scope -> PsVerifiedIrExpr -> Bool -> Emit String :=
  match fuel with
  | Nat.zero =>
      fun (_module : PsVerifiedIrModule) (_scope : Scope) (_expr : PsVerifiedIrExpr)
          (_tail : Bool) => psBackendStateThrow "PSC1_PYTHON_EMISSION_BUDGET"
  | Nat.succ remaining =>
      fun (module : PsVerifiedIrModule) (scope : Scope) (expr : PsVerifiedIrExpr)
          (tail : Bool) (state : EmitState) =>
        let emit : PsVerifiedIrExpr -> Bool -> Emit String := expression remaining module scope;
        match expr with
        | PsVerifiedIrExpr.literal value => do
            let text <- literal value
            bindValue text state
        | PsVerifiedIrExpr.var name =>
            match psBackendSourceFind (fun (binding : Prod String String) =>
                psStringEq binding.fst name) scope with
            | Option.some binding => Except.ok (Prod.mk binding.snd state)
            | Option.none =>
                if psListAny (fun (declaration : PsVerifiedIrDeclaration) =>
                    psStringEq declaration.name name && psListIsEmpty declaration.parameters) module.declarations then
                  emitCall (valueName name) List.nil tail state
                else Except.ok (Prod.mk (globalName name) state)
        | PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.boolAnd _ [a, b] => do
            let (left, state) <- emit a false state
            let (result, state) <- fresh "and" state
            let (_unit, state) <- line (cat ["if ", left, ":"]) state
            let (_unit, state) <- withIndent (assignExpression emit b tail result) state
            let (_unit, state) <- line "else:" state
            let (_unit, state) <- withIndent (line (cat [result, " = False"])) state
            Except.ok (Prod.mk result state)
        | PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.boolOr _ [a, b] => do
            let (left, state) <- emit a false state
            let (result, state) <- fresh "or" state
            let (_unit, state) <- line (cat ["if ", left, ":"]) state
            let (_unit, state) <- withIndent (line (cat [result, " = True"])) state
            let (_unit, state) <- line "else:" state
            let (_unit, state) <- withIndent (assignExpression emit b tail result) state
            Except.ok (Prod.mk result state)
        | PsVerifiedIrExpr.intrinsic operation types arguments => do
            let (_unit, state) <- checkTypes types state
            let (values, state) <- psBackendSourceMapState
              (fun (argument : PsVerifiedIrExpr) => emit argument false) arguments state
            emitIntrinsic operation values tail state
        | PsVerifiedIrExpr.lambda parameters resultType body => do
            checkType 256 resultType
            let (name, state) <- fresh "closure" state
            let (pair, state) <- emitParameters scope parameters state
            let inner : Scope := pair.fst
            let names : List String := pair.snd
            let (_unit, state) <- line (cat ["def ", name, "(", psTextJoin ", " names, "):"]) state
            let action : Emit Unit :=
              psBackendStateBind (expression remaining module inner body true)
                (fun (result : String) => line (cat ["return ", result]))
            let (_unit, state) <- withIndent action state
            Except.ok (Prod.mk name state)
        | PsVerifiedIrExpr.call fn types arguments => do
            let (_unit, state) <- checkTypes types state
            let (callee, state) <- emit fn false state
            let (saved, state) <- bindValue callee state
            let (values, state) <- psBackendSourceMapState
              (fun (argument : PsVerifiedIrExpr) => emit argument false) arguments state
            emitCall saved values tail state
        | PsVerifiedIrExpr.letE name type value body => do
            checkType 256 type
            let (value, state) <- emit value false state
            let (localName, state) <- fresh name state
            let (_unit, state) <- line (cat [localName, " = ", value]) state
            expression remaining module (List.cons (Prod.mk name localName) scope) body tail state
        | PsVerifiedIrExpr.ifE condition yes no => do
            let (condition, state) <- emit condition false state
            let (result, state) <- fresh "branch" state
            let (_unit, state) <- line (cat ["if ", condition, ":"]) state
            let (_unit, state) <- withIndent (assignExpression emit yes tail result) state
            let (_unit, state) <- line "else:" state
            let (_unit, state) <- withIndent (assignExpression emit no tail result) state
            Except.ok (Prod.mk result state)
        | PsVerifiedIrExpr.record name types fields => do
            let (_unit, state) <- checkTypes types state
            let schema <- structureFields module name
            let (values, state) <- emitNamedFields emit fields state
            let ordered <- orderedValues schema values
            bindValue (tuple ordered) state
        | PsVerifiedIrExpr.projection name types target field => do
            let (_unit, state) <- checkTypes types state
            let (target, state) <- emit target false state
            let fields <- structureFields module name
            let index <- fieldPosition fields field
            bindValue (cat [target, "[", decimal index, "]"]) state
        | PsVerifiedIrExpr.constructor owner name types fields => do
            let (_unit, state) <- checkTypes types state
            let schema <- constructorFields module owner name
            let (values, state) <- emitNamedFields emit fields state
            let ordered <- orderedValues schema values
            bindValue (tuple (List.cons (psJsonQuote name) ordered)) state
        | PsVerifiedIrExpr.matchE owner types scrutinee alternatives => do
            let (_unit, state) <- checkTypes types state
            let (scrutinee, state) <- emit scrutinee false state
            let (result, state) <- fresh "match" state
            let emitWithScope : Scope -> PsVerifiedIrExpr -> Bool -> Emit String :=
              expression remaining module
            let (_unit, state) <- psBackendSourceForState
              (emitAlternative emitWithScope module scope owner scrutinee result (firstAlternative alternatives) tail)
              alternatives state
            let (_unit, state) <- helper "builtins" state
            let action : Emit Unit :=
              if psListIsEmpty alternatives then
                line "raise _psc_b.RuntimeError(\"PSC1_IMPOSSIBLE_CONSTRUCTOR\")"
              else psBackendStateBind (line "else:") (fun (_unit : Unit) =>
                withIndent (line "raise _psc_b.RuntimeError(\"PSC1_IMPOSSIBLE_CONSTRUCTOR\")"))
            let (_unit, state) <- action state
            Except.ok (Prod.mk result state)

def parameterCheck (name : String) (type : PsVerifiedIrType) : Except String String :=
  match type with
  | PsVerifiedIrType.primitive scalar =>
      match scalar with
      | PsVerifiedIrPrimitiveType.nat =>
          Except.ok (cat ["_psc_b.type(", name, ") is _psc_b.int and ", name, " >= 0"])
      | PsVerifiedIrPrimitiveType.int => Except.ok (cat ["_psc_b.type(", name, ") is _psc_b.int"])
      | PsVerifiedIrPrimitiveType.bool => Except.ok (cat ["_psc_b.type(", name, ") is _psc_b.bool"])
      | PsVerifiedIrPrimitiveType.string =>
          Except.ok (cat ["_psc_b.type(", name, ") is _psc_b.str and not _psc_b.any(0xD800 <= _psc_b.ord(_psc_c) <= 0xDFFF for _psc_c in ", name, ")"])
      | PsVerifiedIrPrimitiveType.char =>
          Except.ok (cat ["_psc_b.type(", name, ") is _psc_b.str and _psc_b.len(", name, ") == 1 and not (0xD800 <= _psc_b.ord(", name, ") <= 0xDFFF)"])
      | PsVerifiedIrPrimitiveType.unit => Except.ok (cat [name, " is None"])
      | _ => Except.error "PSC1_PYTHON_PUBLIC_ABI_UNSUPPORTED"
  | _ => Except.error "PSC1_PYTHON_PUBLIC_ABI_UNSUPPORTED"

def noteOrigin (name : String) : Emit Unit :=
  psBackendStateModify (fun (state : EmitState) =>
    EmitState.mk state.linesRev state.lineCount state.indent state.nextIndex state.helpers
      (List.cons (Prod.mk name (Nat.succ state.lineCount)) state.originsRev))

def emitDeclaration (module : PsVerifiedIrModule) (declaration : PsVerifiedIrDeclaration) :
    Emit Unit :=
  fun (state : EmitState) => do
    if !psListIsEmpty declaration.typeParameters then
      throw (cat ["PSC1_PYTHON_GENERIC_DECLARATION_UNSUPPORTED: ", declaration.name])
    checkType 256 declaration.resultType
    let (pair, state) <- emitParameters List.nil declaration.parameters state
    let scope : Scope := pair.fst
    let parameters : List String := pair.snd
    let name : String :=
      if psListIsEmpty declaration.parameters then valueName declaration.name else globalName declaration.name
    let (_unit, state) <- noteOrigin declaration.name state
    let (_unit, state) <- line (cat ["def ", name, "(", psTextJoin ", " parameters, "):"]) state
    let action : Emit Unit :=
      psBackendStateBind (expression 4096 module scope declaration.body true)
        (fun (result : String) => line (cat ["return ", result]))
    let (_unit, state) <- withIndent action state
    line "" state

def publicParameter (ioAbi : Bool) (item : Prod PsVerifiedIrParameter Nat) :
    Except String (Prod String (Prod String PsVerifiedIrType)) := do
  let parameter : PsVerifiedIrParameter := item.fst
  let text <- if ioAbi && psBackendIoDispatcherType parameter.type then
      Except.ok "Callable[[_psc_b.str], _psc_b.str]" else scalarType parameter.type
  Except.ok (Prod.mk (cat ["arg", decimal item.snd]) (Prod.mk text parameter.type))

def publicParameterCheck (ioAbi : Bool) (publicName : String)
    (parameter : Prod String (Prod String PsVerifiedIrType)) : Emit Unit :=
  fun (state : EmitState) => do
    let check <- if ioAbi && psBackendIoDispatcherType parameter.snd.snd then
        Except.ok (cat ["_psc_b.callable(", parameter.fst, ")"])
      else parameterCheck parameter.fst parameter.snd.snd
    let (_unit, state) <- line (cat ["if not (", check, "):"]) state
    withIndent (line (cat ["raise _psc_b.TypeError(",
      psJsonQuote (cat ["PSC1_PYTHON_ARGUMENT_TYPE: ", publicName, ":", parameter.fst]), ")"])) state

def emitPublicFunction (name : String)
    (parameters : List (Prod String (Prod String PsVerifiedIrType)))
    (ioAbi calls : Bool) : Emit Unit :=
  fun (state : EmitState) => do
    let (_unit, state) <- psBackendSourceForState (publicParameterCheck ioAbi name) parameters state
    let args : String := psTextJoin ", "
      (psListMap (fun (parameter : Prod String (Prod String PsVerifiedIrType)) => parameter.fst) parameters)
    let call : String :=
      if calls then cat ["_psc_run(", globalName name, ", ", args, ")"]
      else cat [globalName name, "(", args, ")"]
    line (cat ["return ", call]) state

def emitPublics (module : PsVerifiedIrModule) (ioAbi calls : Bool)
    (names : List String) (seen : List String) (stubsRev : List String) :
    Emit (List String) :=
  fun (state : EmitState) =>
    match names with
    | List.nil => Except.ok (Prod.mk (psListReverse stubsRev) state)
    | List.cons name rest => do
        if psBackendNameSeen name seen then
          throw (cat ["PSC1_PYTHON_DUPLICATE_PUBLIC_DECLARATION: ", name])
        if !publicNameAllowed name then throw (cat ["PSC1_PYTHON_PUBLIC_NAME_UNSUPPORTED: ", name])
        let declaration <- match psBackendSourceFind (fun (value : PsVerifiedIrDeclaration) =>
            psStringEq value.name name) module.declarations with
          | Option.none => Except.error (cat ["PSC1_PYTHON_PUBLIC_DECLARATION_MISSING: ", name])
          | Option.some value => Except.ok value
        let resultType <- scalarType declaration.resultType
        if psListIsEmpty declaration.parameters then
          let force : String :=
            if calls then cat ["_psc_run(", valueName name, ")"] else cat [valueName name, "()"]
          let (_unit, state) <- line (cat [name, " = ", force]) state
          emitPublics module ioAbi calls rest (List.cons name seen)
            (List.cons (cat [name, ": ", resultType]) stubsRev) state
        else
          let (_unit, state) <- helper "builtins" state
          let parameters <- psListMapExcept (publicParameter ioAbi)
            (psBackendSourceZipIndex declaration.parameters)
          let signature : String := psTextJoin ", "
            (psListMap (fun (parameter : Prod String (Prod String PsVerifiedIrType)) =>
              cat [parameter.fst, ": ", parameter.snd.fst]) parameters)
          let (_unit, state) <- line (cat ["def ", name, "(", signature, ") -> ", resultType, ":"]) state
          let (_unit, state) <- withIndent (emitPublicFunction name parameters ioAbi calls) state
          let (_unit, state) <- line "" state
          emitPublics module ioAbi calls rest (List.cons name seen)
            (List.cons (cat ["def ", name, "(", signature, ") -> ", resultType, ": ..."]) stubsRev) state

def emitModuleBody (module : PsVerifiedIrModule) (publicNames : List String) (ioAbi : Bool) :
    Emit String :=
  fun (state : EmitState) => do
    if !psListIsEmpty module.imports then throw "PSC1_PYTHON_FOREIGN_IMPORT_UNSUPPORTED"
    let (_unit, state) <- psBackendSourceForState (emitDeclaration module) module.declarations state
    let calls : Bool := psBackendNameSeen "calls" state.helpers
    let (_unit, state) <- line "from typing import Callable" state
    let (_unit, state) <- line "" state
    let stubs : List String :=
      ["# Generated PSC1 scalar API; Nat values are nonnegative Python int.", "import builtins as _psc_b", "from typing import Callable", ""]
    let (stubs, state) <- emitPublics module ioAbi calls publicNames List.nil (psListReverse stubs) state
    let (_unit, state) <- line (cat ["__all__ = [",
      psTextJoin ", " (psListMap psJsonQuote publicNames), "]"]) state
    Except.ok (Prod.mk (cat [psTextJoin "\n" stubs, "\n"]) state)

def countNewlines (chars : List Char) (count : Nat) : Nat :=
  match chars with
  | List.nil => count
  | List.cons char rest =>
      countNewlines rest (if Nat.beq (Char.toNat char) 10 then Nat.succ count else count)

end PsPython

def psPythonEmitModuleWithIo (validated : PsValidatedIrModule) (publicNames : List String)
    (ioAbi : Bool) : Except String PsPythonOutput := do
  match psStrictValidateModule validated.raw with
  | Except.error _ => throw "PSC1_PYTHON_IR_VALIDATION_FAILED"
  | Except.ok _ => pure Unit.unit
  let (stub, state) <- PsPython.emitModuleBody validated.raw publicNames ioAbi PsPython.initialState
  let selected : List String := psPythonRuntimeClosure state.helpers
  let runtime : String := psPythonRuntimeSource selected
  let header : String := "# Generated by PSC1 DirectPython; requires Python >= 3.14.\n# Logical admission does not certify backend preservation.\n\n"
  let sourcePrefix : String := PsPython.cat [header, runtime]
  let offset : Nat := PsPython.countNewlines (psJsonStringToChars sourcePrefix) 0
  Except.ok (PsPythonOutput.mk
    (PsPython.cat [sourcePrefix, psTextJoin "\n" (psListReverse state.linesRev), "\n"])
    stub runtime selected
    (psListMap (fun (pair : Prod String Nat) => Prod.mk pair.fst (Nat.add pair.snd offset))
      (psListReverse state.originsRev)))
