import Ps.Environment.StandardFormatData

-- Construct one ordinary definition from its closed explicit telescope.
def psFormatDefinition (name : String) (parameters : List PsStandardDataField)
    (result body : PsExpr) : PsDeclaration :=
  psOrderDecl name (psStandardDataBind parameters 0 result)
    (psStandardDataBind parameters 0 body true)

def psFormatBasicDeclarations : List PsDeclaration :=
  let format := psFormatType
  let str := PsExpr.constE psStringName []
  let bool := PsExpr.constE psBoolName []
  let yes := PsExpr.constE psBoolTrueName []
  let no := PsExpr.constE psBoolFalseName []
  let value := PsExpr.fvar 0
  let text := fun s => psFormatCall "text" [s]
  let append := fun a b => psFormatCall "append" [a, b]
  let group := fun f fill => psFormatCall "group" [f, psFormatBehavior fill]
  let nest := fun n f => psFormatCall "nest" [n, f]
  let add := fun a b => psOrderCall "Nat.add" [a, b]
  let two := PsExpr.lit (.natural 2)
  let unary := fun name result body =>
    psFormatDefinition name [{ name := "f", type := format }] result body
  let empty := psFormatFold bool value 100 {
    nil := yes, line := no, align := fun _ => yes
    text := fun s => psLogicApply psStandardBEqStringMethod [s, .lit (.string "")]
    nest := fun _ _ ih => ih
    append := fun _ _ left right => psStandardStringIf bool left right no
    group := fun _ _ ih => ih, tag := fun _ _ ih => ih }
  let isNil := psFormatFold bool value 100 {
    nil := yes, line := no, align := fun _ => no, text := fun _ => no
    nest := fun _ _ _ => no, append := fun _ _ _ _ => no
    group := fun _ _ _ => no, tag := fun _ _ _ => no }
  let weight := psFormatFold psOrderNat value 100 {
    nil := two, line := two, align := fun _ => two
    text := fun s => add two (.app (.constE psStringUtf8ByteSizeName []) s)
    nest := fun _ _ ih => add two ih
    append := fun _ _ left right => add two (add left right)
    group := fun _ _ ih => add two ih, tag := fun _ _ ih => add two ih }
  let bracket := fun fill =>
    let left := PsExpr.fvar 0
    let body := PsExpr.fvar 1
    let right := PsExpr.fvar 2
    let indent := PsExpr.app (.constE psIntOfNatName [])
      (.app (.constE psStringLengthName []) left)
    psFormatDefinition (if fill then "Std.Format.bracketFill" else "Std.Format.bracket")
      [{ name := "left", type := str }, { name := "f", type := format },
       { name := "right", type := str }] format
      (group (nest indent (append (append (text left) body) (text right))) fill)
  let bracketCall := fun left right =>
    psFormatCall "bracket" [.lit (.string left), value, .lit (.string right)]
  [ unary "Std.Format.isEmpty" bool empty,
    unary "Std.Format.isNil" bool isNil,
    unary "$psc0Standard.formatWeight" psOrderNat weight,
    unary "Std.Format.fill" format (group value true),
    bracket false, bracket true,
    unary "Std.Format.paren" format (bracketCall "(" ")"),
    unary "Std.Format.sbracket" format (bracketCall "[" "]"),
    psOrderDecl "Std.Format.defWidth" psOrderNat (.lit (.natural 120)),
    psOrderDecl "Std.Format.defIndent" psOrderNat two,
    psOrderDecl "Std.Format.defUnicode" bool yes,
    unary "Std.Format.nestD" format
      (nest (.app (.constE psIntOfNatName []) two) value),
    unary "Std.Format.indentD" format
      (psFormatCall "nestD" [append (psFormatCall "line") value]) ]
