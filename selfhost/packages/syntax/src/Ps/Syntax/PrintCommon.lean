import Ps.Syntax.Ast

inductive PsSourcePrintError where
  | fuelExhausted
  | unsupportedApplication
  | emptyName

def psPrintJoin (separator : String) : List String -> String
  | [] => ""
  | [value] => value
  | value :: rest =>
      value ++ separator ++ psPrintJoin separator rest

def psPrintSyntaxName (name : PsSyntaxName) :
    Except PsSourcePrintError String :=
  match name.segments with
  | [] => Except.error PsSourcePrintError.emptyName
  | segments => Except.ok (psPrintJoin "." segments)

def psPrintBinderDelimiters
    (kind : PsSyntaxBinderKind) : String × String :=
  match kind with
  | .explicit => ("(", ")")
  | .implicit => ("{", "}")
  | .strictImplicit => ("{{", "}}")
  | .instanceImplicit => ("[", "]")

def psPrintPattern
    (pattern : PsSyntaxPattern) :
    Except PsSourcePrintError String :=
  match pattern with
  | .bool value _ =>
      Except.ok (if value then "true" else "false")
  | .wildcard _ =>
      Except.ok "_"
  | .constructor name binders _ =>
      match psPrintSyntaxName name with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          match binders.mapM psPrintSyntaxName with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              if printedBinders.isEmpty then
                Except.ok printedName
              else
                Except.ok
                  (printedName ++ " " ++ psPrintJoin " " printedBinders)

def psSyntaxTermSimpleForApplication : PsSyntaxTerm -> Bool
  | .reference _ => true
  | .natural _ _ => true
  | .string _ _ => true
  | .character _ _ => true
  | .bool _ _ => true
  | .unit _ => true
  | _ => false

def psPrintArrowChain
    (binders : List String)
    (body : String) : String :=
  match binders with
  | [] => body
  | binder :: rest =>
      binder ++ " -> " ++ psPrintArrowChain rest body
