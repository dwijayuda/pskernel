import Ps.Codegen.Doc
import Ps.BackendTs.Type

namespace PsEcma

inductive Dialect where
  | javascript | typescript
  deriving BEq

structure Parameter where
  name : String
  type : String := ""
  rest : Bool := false

mutual
inductive Expr where
  | atom (token : String)
  | unary (op : String) (value : Expr)
  | binary (op : String) (left right : Expr)
  | conditional (condition yes no : Expr)
  | member (target : Expr) (field : String) (optional : Bool := false)
  | index (target key : Expr)
  | call (fn : Expr) (types : String) (arguments : List Expr)
  | newE (name : String) (types : String) (arguments : List Expr)
  | array (elements : List Expr)
  | object (fields : List (String × Expr))
  | cast (value : Expr) (type : String)
  | nonnull (value : Expr)
  | generic (value : Expr) (types : String)
  | functionE (generator : Bool) (types : String) (parameters : List Parameter)
      (result : String) (body : List Stmt)
inductive Stmt where
  | expression (value : Expr)
  | binding (mutable : Bool) (name type : String) (value : Option Expr)
  | returnE (value : Expr)
  | throwE (value : Expr)
  | continueE
  | block (body : List Stmt)
  | ifE (condition : Expr) (yes no : List Stmt)
  | whileE (condition : Expr) (body : List Stmt)
  | forOf (name : String) (value : Expr) (body : List Stmt)
  | switchE (value : Expr) (cases : List (Expr × List Stmt))
  | functionD (exported generator : Bool) (name types : String)
      (parameters : List Parameter) (result : String) (body : List Stmt)
end

def cat (docs : List PsDoc) : PsDoc := psDocJoin (.text "") docs
def txt := PsDoc.text
def typed (dialect : Dialect) (text : String) : String :=
  if dialect == .typescript then text else ""
def annotation (dialect : Dialect) (type : String) : String :=
  if type.isEmpty then "" else typed dialect (": " ++ type)
def parameter (dialect : Dialect) (p : Parameter) : String :=
  (if p.rest then "..." else "") ++ p.name ++ annotation dialect p.type
def signature (dialect : Dialect) (types : String) (parameters : List Parameter) (result : String) : String :=
  typed dialect types ++ "(" ++ String.intercalate ", " (parameters.map (parameter dialect)) ++ ")" ++ annotation dialect result
def blockDoc (body : List PsDoc) : PsDoc :=
  if body.isEmpty then txt "{}" else cat [
    txt "{", .nest 2 (cat [.hardline, psDocJoin .hardline body]), .hardline, txt "}"]
def enclosed (left : String) (body : PsDoc) (right : String) : PsDoc :=
  cat [txt left, body, txt right]
def argumentsDoc (args : List PsDoc) : PsDoc :=
  .group (enclosed "(" (.nest 2 (psDocJoin (cat [txt ",", .line]) args)) ")")

mutual
def exprDoc (dialect : Dialect) : Nat → Expr → Except String PsDoc
  | 0, _ => .error "PSCV0-ECMA: expression print budget"
  | fuel + 1, value => do
    let expr := exprDoc dialect fuel
    match value with
    | .atom token => return txt token
    | .unary op value =>
        if op == "..." then return cat [txt op, ← expr value]
        else return enclosed "(" (cat [txt op, ← expr value]) ")"
    | .binary op a b => return enclosed "(" (cat [← expr a, txt (" " ++ op ++ " "), ← expr b]) ")"
    | .conditional c a b => return enclosed "(" (.group (cat [
        ← expr c, txt " ?", .nest 2 (cat [.line, ← expr a, txt " :", .line, ← expr b])])) ")"
    | .member target field optional =>
        let rendered ← expr target
        let rendered := match target with
          | .atom token =>
              if token.startsWith "-" || (token.toList.head?.map Char.isDigit).getD false
              then enclosed "(" rendered ")" else rendered
          | _ => rendered
        return cat [rendered, txt ((if optional then "?." else ".") ++ field)]
    | .index target key => return cat [← expr target, enclosed "[" (← expr key) "]"]
    | .call fn types args => return cat [← expr fn, txt (typed dialect types), argumentsDoc (← args.mapM expr)]
    | .newE name types args => return cat [txt ("new " ++ name ++ typed dialect types), argumentsDoc (← args.mapM expr)]
    | .array values => return enclosed "[" (.group (psDocJoin (cat [txt ",", .line]) (← values.mapM expr))) "]"
    | .object fields =>
        let fields ← fields.mapM fun (key, value) => do
          return cat [txt ((if key == "__proto__" then "[\"__proto__\"]" else key) ++ ": "), ← expr value]
        return enclosed "({" (.group (.nest 2 (psDocJoin (cat [txt ",", .line]) fields))) "})"
    | .cast value type =>
        if dialect == .javascript then expr value
        else return enclosed "(" (cat [← expr value, txt (" as " ++ type)]) ")"
    | .nonnull value => return cat [← expr value, txt (typed dialect "!")]
    | .generic value types => return cat [← expr value, txt (typed dialect types)]
    | .functionE generator types parameters result body =>
        return enclosed "(" (cat [
          txt ((if generator then "function*" else "function") ++ signature dialect types parameters result ++ " "),
          blockDoc (← body.mapM (stmtDoc dialect fuel))]) ")"
def stmtDoc (dialect : Dialect) : Nat → Stmt → Except String PsDoc
  | 0, _ => .error "PSCV0-ECMA: statement print budget"
  | fuel + 1, statement => do
    let expr := exprDoc dialect fuel
    let body := fun (statements : List Stmt) => do return blockDoc (← statements.mapM (stmtDoc dialect fuel))
    match statement with
    | .expression value => return cat [← expr value, txt ";"]
    | .binding mutable name type value =>
        return cat [txt ((if mutable then "let " else "const ") ++ name ++ annotation dialect type),
          ← (match value with | none => pure (txt "") | some v => do return cat [txt " = ", ← expr v]), txt ";"]
    | .returnE value => return cat [txt "return ", ← expr value, txt ";"]
    | .throwE value => return cat [txt "throw ", ← expr value, txt ";"]
    | .continueE => return txt "continue;"
    | .block statements => body statements
    | .ifE condition yes no => return cat [
        txt "if (", ← expr condition, txt ") ", ← body yes,
        ← (if no.isEmpty then pure (txt "") else do return cat [txt " else ", ← body no])]
    | .whileE condition statements =>
        return cat [txt "while (", ← expr condition, txt ") ", ← body statements]
    | .forOf name value statements =>
        return cat [txt ("for (const " ++ name ++ " of "), ← expr value, txt ") ", ← body statements]
    | .switchE value cases =>
        let cases ← cases.mapM fun (label, statements) => do
          return cat [txt "case ", ← expr label, txt ": ", ← body statements]
        return cat [txt "switch (", ← expr value, txt ") ", blockDoc cases]
    | .functionD exported generator name types parameters result statements =>
        return cat [txt ((if exported then "export " else "") ++
          (if generator then "function* " else "function ") ++ name ++
          signature dialect types parameters result ++ " "), ← body statements]
end

def id := Expr.atom
def str (value : String) : Expr := .atom (psJsonQuote value)
def num (value : Nat) : Expr := .atom (toString value)
def call (name : String) (args : List Expr) : Expr := .call (.atom name) "" args
def method (value : Expr) (name : String) (args : List Expr) : Expr := .call (.member value name) "" args
def field (value : Expr) (name : String) : Expr := .member value name
def bin := Expr.binary
def unary := Expr.unary
def set (target value : Expr) : Stmt := .expression (.binary "=" target value)
def inc (name : String) (value : Expr) : Stmt := .expression (.binary "+=" (id name) value)
def const (name : String) (value : Expr) : Stmt := .binding false name "" (some value)
def letE (name : String) (value : Expr) : Stmt := .binding true name "" (some value)
def ret := Stmt.returnE
def fail (message : String) : Stmt := .throwE (.newE "Error" "" [str message])
def invoke (parameters : List Parameter) (result : String) (body : List Stmt) (args : List Expr)
    (generic : String := "") : Expr :=
  .call (.functionE false generic parameters result body) "" args
def delegate (body : List Stmt) (parameters : List Parameter := []) (args : List Expr := [])
    (result : String := "") : Expr :=
  .unary "yield* " (.call (.functionE true "" parameters result body) "" args)
def irType (type : PsVerifiedIrType) : Except String String :=
  (psTsEmitType type).mapError (fun _ => "PSCV0-ECMA: unsupported runtime type")
def irParameters (parameters : List PsVerifiedIrParameter) : Except String (List Parameter) :=
  parameters.mapM fun p => do return { name := p.name, type := ← irType p.type }
end PsEcma
