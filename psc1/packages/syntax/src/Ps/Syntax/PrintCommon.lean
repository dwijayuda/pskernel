import Ps.Syntax.Ast

inductive PsSourcePrintError where
  | fuelExhausted
  | unsupportedApplication
  | emptyName
  | unsupportedSourceForm (message : String)

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

def psPrintSyntaxNames
    (names : List PsSyntaxName) :
    Except PsSourcePrintError (List String) :=
  match names with
  | List.nil =>
      Except.ok List.nil
  | List.cons name rest =>
      let printedHeadResult :=
        psPrintSyntaxName name;
      match printedHeadResult with
      | Except.error error =>
          Except.error error
      | Except.ok printedHead =>
          let printedTailResult :=
            psPrintSyntaxNames rest;
          match printedTailResult with
          | Except.error error =>
              Except.error error
          | Except.ok printedTail =>
              Except.ok (List.cons printedHead printedTail)

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
      if value then
        Except.ok "true"
      else
        Except.ok "false"
  | .wildcard _ =>
      Except.ok "_"
  | .constructor name binders _ =>
      let printedNameResult :=
        psPrintSyntaxName name;
      match printedNameResult with
      | Except.error error => Except.error error
      | Except.ok printedName =>
          let printedBindersResult :=
            psPrintSyntaxNames binders;
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

-- Print statement spines through the same term callback as their enclosing
-- frontend. Native Lean uses semicolons inside braces; ProofScript uses LF.
def psPrintDoBinding
    (printTerm : PsSyntaxTerm -> Except PsSourcePrintError String)
    (name : PsSyntaxName) (annotation : Option PsSyntaxTerm)
    (separator : String) (value : PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match psPrintSyntaxName name with
  | Except.error error => Except.error error
  | Except.ok printedName =>
      let printedType :=
        match annotation with
        | Option.none => Except.ok ""
        | Option.some type =>
            match printTerm type with
            | Except.error error => Except.error error
            | Except.ok printed => Except.ok (psPrintCommonConcat2 " : " printed);
      match printedType with
      | Except.error error => Except.error error
      | Except.ok printedType =>
          match printTerm value with
          | Except.error error => Except.error error
          | Except.ok printedValue =>
              let groupedValue :=
                if psSyntaxTermSimpleForApplication value then printedValue
                else psPrintCommonConcat3 "(" printedValue ")";
              Except.ok (psPrintJoin ""
                ["let ", printedName, printedType, separator, groupedValue])

def psPrintDoBody
    (printTerm : PsSyntaxTerm -> Except PsSourcePrintError String)
    (separator : String) (fuel : Nat) :
    PsSyntaxTerm -> Except PsSourcePrintError String :=
  match fuel with
  | Nat.zero =>
      fun (_body : PsSyntaxTerm) => Except.error PsSourcePrintError.fuelExhausted
  | Nat.succ remaining =>
      fun (body : PsSyntaxTerm) =>
        let smaller : PsSyntaxTerm -> Except PsSourcePrintError String :=
          psPrintDoBody printTerm separator remaining;
        let withTail :
            Except PsSourcePrintError String -> PsSyntaxTerm ->
            Except PsSourcePrintError String :=
          fun (head : Except PsSourcePrintError String) (tail : PsSyntaxTerm) =>
            match head with
            | Except.error error => Except.error error
            | Except.ok printedHead =>
                match smaller tail with
                | Except.error error => Except.error error
                | Except.ok printedTail =>
                    Except.ok (psPrintCommonConcat3 printedHead separator printedTail);
        match body with
        | PsSyntaxTerm.letE name annotation value tail _ =>
            withTail (psPrintDoBinding printTerm name annotation " := " value) tail
        | PsSyntaxTerm.doBindE name annotation value tail _ =>
            withTail (psPrintDoBinding printTerm name annotation " <- " value) tail
        | PsSyntaxTerm.doThenE action tail _ =>
            let printedAction :=
              match printTerm action with
              | Except.error error => Except.error error
              | Except.ok printed =>
                  if psSyntaxTermSimpleForApplication action then Except.ok printed
                  else Except.ok (psPrintCommonConcat3 "(" printed ")");
            withTail printedAction tail
        | PsSyntaxTerm.doReturnE value _ =>
            match printTerm value with
            | Except.error error => Except.error error
            | Except.ok printed =>
                let groupedValue :=
                  if psSyntaxTermSimpleForApplication value then printed
                  else psPrintCommonConcat3 "(" printed ")";
                Except.ok (psPrintCommonConcat2 "return " groupedValue)
        | _ => printTerm body

def psPrintUnaryOperator
    (printTerm : PsSyntaxTerm -> Except PsSourcePrintError String)
    (operator : String) (operand : PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match printTerm operand with
  | Except.error error => Except.error error
  | Except.ok printed => Except.ok (psPrintJoin "" ["(", operator, printed, ")"])

def psPrintBinaryOperator
    (printTerm : PsSyntaxTerm -> Except PsSourcePrintError String)
    (operator : String) (left right : PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match printTerm left with
  | Except.error error => Except.error error
  | Except.ok printedLeft =>
      match printTerm right with
      | Except.error error => Except.error error
      | Except.ok printedRight =>
          Except.ok (psPrintJoin "" ["(", printedLeft, " ", operator, " ", printedRight, ")"])
