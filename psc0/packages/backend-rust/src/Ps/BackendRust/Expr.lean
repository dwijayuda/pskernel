import Ps.BackendRust.Captures
import Ps.BackendRust.Intrinsic
import Ps.BackendRust.Layout
import Ps.Codegen.Doc

def psRustResult {α : Type} (value : Except PsRustEmitError α) : Except String α :=
  value.mapError (fun error => "PSCV0-RUST: " ++ reprStr error)

def psRustDocCall (callee : PsDoc) (arguments : List PsDoc) : PsDoc :=
  .group (.append callee (.append (.text "(")
    (.append (.nest 2 (psDocJoin (.append (.text ",") .line) arguments)) (.text ")"))))

def psRustDocWrap (left : String) (body : PsDoc) (right : String) : PsDoc :=
  .append (.text left) (.append body (.text right))

def psRustFree (ctx : PsRustContext) (expr : PsVerifiedIrExpr) : List String :=
  psRustCollectCapturesWorker ctx.locals 65536 [] expr []

def psRustFreeMany (ctx : PsRustContext) (exprs : List PsVerifiedIrExpr) : List String :=
  exprs.flatMap (psRustFree ctx)

def psRustParameter (p : PsVerifiedIrParameter) : Except String String := do
  return p.name ++ ": " ++ (← psRustResult (psRustEmitType p.type))

def psRustGlobalValue (ctx : PsRustContext) (name : String) : Except String PsDoc := do
  let some d := ctx.declarations.find? (fun d => d.name == name)
    | throw ("PSCV0-RUST: unknown global " ++ name)
  if d.parameters.isEmpty then return .text (name ++ "()")
  if !d.typeParameters.isEmpty then throw ("PSCV0-RUST: uninstantiated polymorphic value " ++ name)
  let type ← psRustResult (psRustEmitType (.function (d.parameters.map (·.type)) d.resultType))
  return .text ("(std::rc::Rc::new(" ++ name ++ ") as " ++ type ++ ")")

-- 'preserve' is a backwards liveness set. Owned final uses move; uses needed
-- by the continuation clone. Captures of a repeatable Fn are always preserved.
def psRustExpr (fuel : Nat) (ctx : PsRustContext) (preserve : List String)
    (expr : PsVerifiedIrExpr) : Except String PsDoc := do
  match fuel with
  | 0 => throw "PSCV0-RUST: expression budget exhausted"
  | fuel + 1 =>
    let emit := psRustExpr fuel { ctx with tail? := none }
    let arguments := fun (live : List String) (args : List PsVerifiedIrExpr) => do
      let mut docs := []
      for i in [:args.length] do
        let some arg := args[i]? | throw "PSCV0-RUST: argument index"
        let doc ← emit (live ++ psRustFreeMany ctx (args.drop (i + 1))) arg
        docs := doc :: docs
      return docs.reverse
    if let some declaration := ctx.tail? then
      if let some call := psRustTailCallFor declaration ctx.locals ctx.aliases expr then
        let args ← arguments preserve call.arguments
        let args := call.captured.map PsDoc.text ++ args
        let tuple : PsDoc := .append (.text "(") (.append (psDocJoin (.text ", ") args) (.text ",)"))
        return psDocBlock "" [
          .append (.text "__ps_tail_state = ") (.append tuple (.text ";")),
          .text "continue;"]
    match expr with
    | .unreachable _ => return .text "panic!(\"unreachable checked PSCV0 branch\")"
    | .literal value => return .text (psRustEmitLiteral value)
    | .var name =>
        if ctx.locals.contains name then
          return .text (if preserve.contains name then psRustClonePrinted name else name)
        else psRustGlobalValue ctx name
    | .intrinsic op _ args =>
        -- Name complex operands once, in order. Borrowed variables avoid a
        -- needless BigInt/array clone; owned updates can retain uniqueness.
        let mut statements := []
        let mut printed := []
        let mut held := []
        for i in [:args.length] do
          let some arg := args[i]? | throw "PSCV0-RUST: intrinsic argument index"
          let live := preserve ++ held ++ psRustFreeMany ctx (args.drop (i + 1))
          match arg with
          | .var name =>
              if ctx.locals.contains name && !psRustIntrinsicConsumes op i then
                printed := name :: printed
                held := name :: held
              else
                let value ← emit live arg
                let temporary := "__ps_arg_" ++ toString fuel ++ "_" ++ toString i
                statements := .append (.text ("let " ++ temporary ++ " = ")) (.append value (.text ";")) :: statements
                printed := temporary :: printed
          | _ =>
              let value ← emit live arg
              let temporary := "__ps_arg_" ++ toString fuel ++ "_" ++ toString i
              statements := .append (.text ("let " ++ temporary ++ " = ")) (.append value (.text ";")) :: statements
              printed := temporary :: printed
        let value ← psRustResult (psRustEmitIntrinsicFromPrinted op printed.reverse)
        if statements.isEmpty then return .text value
        return psDocBlock "" (statements.reverse ++ [.text value])
    | .call fn types args =>
        let fnLive := preserve ++ psRustFreeMany ctx args
        let callee ← match fn with
          | .var name =>
              if ctx.locals.contains name then pure (PsDoc.text name)
              else
                let some d := ctx.declarations.find? (fun d => d.name == name)
                  | throw ("PSCV0-RUST: unknown callee " ++ name)
                let generic ← psRustResult (psRustEmitTypeArguments types)
                pure (.text (name ++ generic ++ if d.parameters.isEmpty then "()" else ""))
          | _ => pure (psRustDocWrap "(" (← emit fnLive fn) ")")
        -- A closure's call receiver remains live until all arguments finish.
        let callCtx := preserve ++ psRustFree ctx fn
        let docs ← arguments callCtx args
        return psRustDocCall callee docs
    | .lambda ps result body =>
        let names := ps.map (·.name)
        let captures := psRustCollectCapturesWorker ctx.locals fuel names body []
        let nested := { ctx with locals := names ++ ctx.locals, tail? := none, aliases := [] }
        let body ← psRustExpr fuel nested captures body
        let parameters ← ps.mapM psRustParameter
        let type ← psRustResult (psRustEmitType (.function (ps.map (·.type)) result))
        let result ← psRustResult (psRustEmitType result)
        let clones := captures.map fun name => PsDoc.text ("let " ++ name ++ " = " ++
          (if preserve.contains name then psRustClonePrinted name else name) ++ ";")
        let closure : PsDoc := .append (.text ("let __ps_closure: " ++ type ++ " = std::rc::Rc::new("))
          (.append (psDocBlock ("move |" ++ String.intercalate ", " parameters ++ "| -> " ++ result) [body]) (.text ");"))
        return psDocBlock "" (clones ++ [closure, .text "__ps_closure"])
    | .letE name type value body =>
        let value ← emit (preserve ++ psRustFree ctx body) value
        let type ← psRustResult (psRustEmitType type)
        let (aliases, captures) : List PsRustTailAlias × List (String × String) := match ctx.tail? with
          | none => (ctx.aliases, [])
          | some d =>
              let original := match expr with | .letE _ _ v _ => v | _ => .literal .unit
              let snapshots := match psRustTailAliasFor d ctx.locals fuel name original with
                | none => []
                | some entry => entry.captures
              (psRustTailEnterAlias d ctx.locals ctx.aliases fuel name original, snapshots)
        let body ← psRustExpr fuel { ctx with locals := name :: ctx.locals, aliases } preserve body
        let captureDocs := captures.map fun (source, captureName) =>
          PsDoc.text ("let " ++ captureName ++ " = " ++ psRustClonePrinted source ++ ";")
        return psDocBlock "" (captureDocs ++ [
          PsDoc.append (.text ("let " ++ name ++ ": " ++ type ++ " = ")) (.append value (.text ";")), body])
    | .ifE condition yes no =>
        let condition ← emit (preserve ++ psRustFreeMany ctx [yes, no]) condition
        let yes ← psRustExpr fuel ctx preserve yes
        let no ← psRustExpr fuel ctx preserve no
        return .append (.text "if ") (.append condition
          (.append (psDocBlock "" [yes]) (.append (.text " else ") (psDocBlock "" [no]))))
    | .record name types fields | .constructor name _ types fields =>
        let ctor := match expr with | .constructor _ ctor _ _ => "::" ++ ctor | _ => ""
        let generic ← psRustResult (psRustEmitTypeArguments types)
        let values ← arguments preserve (fields.map (·.2))
        let entries := (fields.zip values).map fun ((field, _), value) =>
          PsDoc.append (.text (field ++ ": ")) (.append value (.text ","))
        let entries := if types.isEmpty then entries else entries ++ [.text "__ps_marker: std::marker::PhantomData,"]
        let node := psRustNodeName ctx.shared name
        let value := psDocBlock (node ++ generic ++ ctor) entries
        return if ctx.shared.contains name then psRustDocWrap "std::rc::Rc::new(" value ")" else value
    | .projection name _ target field =>
        let target ← emit preserve target
        let value := psRustDocWrap "(" target (")." ++ field)
        return if ctx.shared.contains name then psRustDocWrap "(" value ").clone()" else value
    | .matchE name _ target alternatives =>
        if alternatives.isEmpty then
          let target ← emit preserve target
          return psDocBlock "" [
            .append (.text "let __ps_empty = ") (.append target (.text ";")),
            .text "panic!(\"uninhabited checked PSCV0 value\")"]
        let branchFree := alternatives.flatMap fun (_, _, body) => psRustFree ctx body
        let target ← emit (preserve ++ branchFree) target
        let shared := ctx.shared.contains name
        let mut arms := []
        for (ctor, bindings, body) in alternatives do
          let fields := bindings.map fun b =>
            b.field ++ ": " ++ if shared then "__ps_field_" ++ b.name else b.name
          let clones := if shared then bindings.map (fun b =>
            PsDoc.text ("let " ++ b.name ++ " = __ps_field_" ++ b.name ++ ".clone();")) else []
          let branch ← psRustExpr fuel { ctx with locals := bindings.map (·.name) ++ ctx.locals } preserve body
          let pattern := psRustNodeName ctx.shared name ++ "::" ++ ctor ++ " { " ++
            String.intercalate ", " (fields ++ [".."]) ++ " } =>"
          arms := .append (psDocBlock pattern (clones ++ [branch])) (.text ",") :: arms
        let target := if shared then psRustDocWrap "(" target ").as_ref()" else psRustDocWrap "(" target ")"
        return .append (.text "match ") (.append target (psDocBlock "" arms.reverse))
