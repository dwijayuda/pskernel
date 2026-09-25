import Ps.Syntax.Ast

inductive PsSourcePrintError where
  | fuelExhausted
  | unsupportedApplication
  | emptyName

def psPrintCommonConcat2
    (left right : String) : String :=
  String.Internal.append left right

def psPrintCommonConcat3
    (first second third : String) : String :=
  let firstTwo := psPrintCommonConcat2 first second;
  psPrintCommonConcat2 firstTwo third

def psPrintJoin
    (separator : String)
    (values : List String) : String :=
  match values with
  | List.nil => ""
  | List.cons value rest =>
      match rest with
      | List.nil => value
      | List.cons _ _ =>
          psPrintCommonConcat3
            value
            separator
            (psPrintJoin separator rest)

def psPrintSyntaxName (name : PsSyntaxName) :
    Except PsSourcePrintError String :=
  let segments := name.segments;
  match segments with
  | List.nil => Except.error PsSourcePrintError.emptyName
  | List.cons _ _ => Except.ok (psPrintJoin "." segments)

def psPrintBinderDelimiters
    (kind : PsSyntaxBinderKind) : Prod String String :=
  match kind with
  | .explicit => Prod.mk "(" ")"
  | .implicit => Prod.mk "{" "}"
  | .strictImplicit => Prod.mk "{{" "}}"
  | .instanceImplicit => Prod.mk "[" "]"

def psPrintPattern
    (pattern : PsSyntaxPattern) :
    Except PsSourcePrintError String :=
  match pattern with
  | .bool value _ =>
      match value with
      | true => Except.ok "true"
      | false => Except.ok "false"
  | .wildcard _ =>
      Except.ok "_"
  | .constructor name binders _ =>
      let printedNameResult :=
        psPrintSyntaxName name;
      match printedNameResult with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedBindersResult :
              Except PsSourcePrintError (List String) :=
            binders.mapM psPrintSyntaxName;
          match printedBindersResult with
          | Except.error error => Except.error error
          | Except.ok printedBinders =>
              match printedBinders with
              | List.nil =>
                  Except.ok printedName
              | List.cons _ _ =>
                  Except.ok
                    (psPrintCommonConcat3
                      printedName
                      " "
                      (psPrintJoin " " printedBinders))

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
  | List.nil => body
  | List.cons binder rest =>
      psPrintCommonConcat3
        binder
        " -> "
        (psPrintArrowChain rest body)
