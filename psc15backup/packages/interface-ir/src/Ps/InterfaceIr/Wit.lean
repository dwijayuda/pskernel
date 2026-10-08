import Ps.InterfaceIr.Validate

def psForeignConcat (parts : List String) : String :=
  match parts with
  | List.nil => ""
  | List.cons part rest => String.Internal.append part (psForeignConcat rest)

def psForeignJoin (separator : String) (parts : List String) : String :=
  match parts with
  | List.nil => ""
  | List.cons part rest =>
      if psListIsEmpty rest then part
      else psForeignConcat [part, separator, psForeignJoin separator rest]

def psForeignWitName (name : String) : String := String.Internal.append "%" name

def psForeignWitScalar (type : PsForeignScalar) : String :=
  match type with
  | .bool => "bool"
  | .u8 => "u8"
  | .u16 => "u16"
  | .u32 => "u32"
  | .u64 => "u64"
  | .s8 => "s8"
  | .s16 => "s16"
  | .s32 => "s32"
  | .s64 => "s64"
  | .f32 => "f32"
  | .f64 => "f64"
  | .char => "char"
  | .string => "string"

def psForeignWitWrap (leading trailing : String) (rendered : Except PsForeignError String) : Except PsForeignError String :=
  match rendered with
  | Except.error error => Except.error error
  | Except.ok text => Except.ok (psForeignConcat [leading, text, trailing])

def psForeignWitOptional (render : PsForeignType -> Except PsForeignError String)
    (leading : String) (type : Option PsForeignType) : Except PsForeignError String :=
  match type with
  | Option.none => Except.ok leading
  | Option.some value => psForeignWitWrap (String.Internal.append leading "<") ">" (render value)

def psForeignWitResult (render : PsForeignType -> Except PsForeignError String)
    (ok error : Option PsForeignType) : Except PsForeignError String :=
  match ok with
  | Option.none =>
      match error with
      | Option.none => Except.ok "result"
      | Option.some errorType => psForeignWitWrap "result<_, " ">" (render errorType)
  | Option.some okType =>
      match render okType with
      | Except.error failure => Except.error failure
      | Except.ok okText =>
          match error with
          | Option.none => Except.ok (psForeignConcat ["result<", okText, ">"])
          | Option.some errorType =>
              psForeignWitWrap (psForeignConcat ["result<", okText, ", "]) ">" (render errorType)

def psForeignWitTypeWithFuel (fuel : Nat) : PsForeignType -> Except PsForeignError String :=
  match fuel with
  | Nat.zero => fun (_type : PsForeignType) => Except.error PsForeignError.resourceExhausted
  | Nat.succ remaining =>
      let smaller : PsForeignType -> Except PsForeignError String := psForeignWitTypeWithFuel remaining;
      fun (type : PsForeignType) =>
        match type with
        | .scalar scalar => Except.ok (psForeignWitScalar scalar)
        | .named name => Except.ok (psForeignWitName name)
        | .list element => psForeignWitWrap "list<" ">" (smaller element)
        | .option element => psForeignWitWrap "option<" ">" (smaller element)
        | .result ok error => psForeignWitResult smaller ok error
        | .tuple elements =>
            match psListMapExcept smaller elements with
            | Except.error error => Except.error error
            | Except.ok texts => Except.ok (psForeignConcat ["tuple<", psForeignJoin ", " texts, ">"])
        | .own resource => Except.ok (psForeignWitName resource)
        | .borrow resource => Except.ok (psForeignConcat ["borrow<", psForeignWitName resource, ">"])
        | .future element => psForeignWitOptional smaller "future" element
        | .stream element => psForeignWitOptional smaller "stream" element

def psForeignWitField (fuel : Nat) (field : PsForeignField) : Except PsForeignError String :=
  psForeignWitWrap (String.Internal.append (psForeignWitName field.name) ": ") ""
    (psForeignWitTypeWithFuel fuel field.type)

def psForeignWitCase (fuel : Nat) (value : PsForeignCase) : Except PsForeignError String :=
  match value.payload with
  | Option.none => Except.ok (psForeignWitName value.name)
  | Option.some type => psForeignWitWrap (String.Internal.append (psForeignWitName value.name) "(") ")"
      (psForeignWitTypeWithFuel fuel type)

def psForeignWitDefinition (fuel : Nat) (definition : PsForeignDefinition) : Except PsForeignError String :=
  let name := psForeignWitName definition.name;
  match definition.body with
  | .alias type => psForeignWitWrap (psForeignConcat ["  type ", name, " = "]) ";\n" (psForeignWitTypeWithFuel fuel type)
  | .resource => Except.ok (psForeignConcat ["  resource ", name, ";\n"])
  | .record fields =>
      match psListMapExcept (psForeignWitField fuel) fields with
      | Except.error error => Except.error error
      | Except.ok texts => Except.ok (psForeignConcat ["  record ", name, " { ", psForeignJoin ", " texts, " }\n"])
  | .variant cases =>
      match psListMapExcept (psForeignWitCase fuel) cases with
      | Except.error error => Except.error error
      | Except.ok texts => Except.ok (psForeignConcat ["  variant ", name, " { ", psForeignJoin ", " texts, " }\n"])
  | .enumeration cases =>
      Except.ok (psForeignConcat ["  enum ", name, " { ", psForeignJoin ", " (psListMap psForeignWitName cases), " }\n"])

def psForeignWitFunctionResult (fuel : Nat) (type : Option PsForeignType) : Except PsForeignError String :=
  match type with
  | Option.none => Except.ok ""
  | Option.some value => psForeignWitWrap " -> " "" (psForeignWitTypeWithFuel fuel value)

def psForeignWitFunction (fuel : Nat) (function : PsForeignFunction) : Except PsForeignError String :=
  match psListMapExcept (psForeignWitField fuel) function.parameters with
  | Except.error error => Except.error error
  | Except.ok parameters =>
      match psForeignWitFunctionResult fuel function.result with
      | Except.error error => Except.error error
      | Except.ok result =>
          let mode : String := if function.asynchronous then "async func(" else "func(";
          Except.ok (psForeignConcat ["  ", psForeignWitName function.name, ": ", mode,
            psForeignJoin ", " parameters, ")", result, ";\n"])

def psForeignWitInterface (fuel : Nat) (value : PsForeignInterface) : Except PsForeignError String :=
  match psListMapExcept (psForeignWitDefinition fuel) value.definitions with
  | Except.error error => Except.error error
  | Except.ok definitions =>
      match psListMapExcept (psForeignWitFunction fuel) value.functions with
      | Except.error error => Except.error error
      | Except.ok functions => Except.ok (psForeignConcat ["interface ", psForeignWitName value.name, " {\n",
          psForeignConcat definitions, psForeignConcat functions, "}\n\n"])

def psForeignWitWorldEdge (direction name : String) : String :=
  psForeignConcat ["  ", direction, " ", psForeignWitName name, ";\n"]

-- Always validate the raw world immediately before emission. Strings naming a
-- profile or a serialized 'validated' flag cannot bypass this check.
def psForeignEmitWit (policy : PsForeignPolicy) (world : PsForeignWorld) : Except PsForeignError String :=
  if psStringEq policy.target "component-model" then
    match psForeignValidateWorld policy world with
    | Except.error error => Except.error error
    | Except.ok _ =>
        match psListMapExcept (psForeignWitInterface policy.typeDepth) world.interfaces with
        | Except.error error => Except.error error
        | Except.ok interfaces => Except.ok (psForeignConcat ["package ", psForeignWitName world.packageNamespace,
            ":", psForeignWitName world.packageName, ";\n\n", psForeignConcat interfaces,
            "world ", psForeignWitName world.name, " {\n",
            psForeignConcat (psListMap (psForeignWitWorldEdge "import") world.imports),
            psForeignConcat (psListMap (psForeignWitWorldEdge "export") world.exports), "}\n"])
  else Except.error PsForeignError.targetUnavailable
