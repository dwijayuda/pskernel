import Ps.Syntax.Ast
import Ps.Foundation.Text

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

def psPrintBindingPattern (pattern : PsSyntaxBindingPattern) :
    Except PsSourcePrintError String :=
  match pattern with
  | PsSyntaxBindingPattern.name name => psPrintSyntaxName name
  | PsSyntaxBindingPattern.wildcard _ => Except.ok "_"
  | PsSyntaxBindingPattern.unit _ => Except.ok "()"
  | PsSyntaxBindingPattern.pair first second _ =>
      match psPrintBindingPattern first with
      | Except.error error => Except.error error
      | Except.ok left =>
          match psPrintBindingPattern second with
          | Except.error error => Except.error error
          | Except.ok right =>
              Except.ok (psPrintJoin "" ["(", left, ", ", right, ")"])

def psPrintBinderDelimiters
    (kind : PsSyntaxBinderKind) : Prod String String :=
  match kind with
  | PsSyntaxBinderKind.explicit => Prod.mk "(" ")"
  | PsSyntaxBinderKind.implicit => Prod.mk "{" "}"
  | PsSyntaxBinderKind.strictImplicit => Prod.mk "{{" "}}"
  | PsSyntaxBinderKind.instanceImplicit => Prod.mk "[" "]"

def psPrintPattern
    (pattern : PsSyntaxPattern) :
    Except PsSourcePrintError String :=
  match pattern with
  | PsSyntaxPattern.bool value _ =>
      if value then
        Except.ok "true"
      else
        Except.ok "false"
  | PsSyntaxPattern.wildcard _ =>
      Except.ok "_"
  | PsSyntaxPattern.constructor name binders _ =>
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
  | PsSyntaxTerm.reference _ => true
  | PsSyntaxTerm.natural _ _ => true
  | PsSyntaxTerm.string _ _ => true
  | PsSyntaxTerm.character _ _ => true
  | PsSyntaxTerm.bool _ _ => true
  | PsSyntaxTerm.unit _ => true
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
    (bindingPrefix separator : String) (value : PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match psPrintSyntaxName name with
  | Except.error error => Except.error error
  | Except.ok printedName =>
      let printedType : Except PsSourcePrintError String :=
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
                [bindingPrefix, printedName, printedType, separator, groupedValue])

def psPrintBindingPatternHead
    (printTerm : PsSyntaxTerm -> Except PsSourcePrintError String)
    (pattern : PsSyntaxBindingPattern) (annotation : Option PsSyntaxTerm)
    (value : PsSyntaxTerm) : Except PsSourcePrintError String :=
  match psPrintBindingPattern pattern with
  | Except.error error => Except.error error
  | Except.ok rawPattern =>
      let printedPattern : String :=
        match pattern with
        | PsSyntaxBindingPattern.name _ => psPrintCommonConcat3 "(" rawPattern ")"
        | PsSyntaxBindingPattern.wildcard _ => psPrintCommonConcat3 "(" rawPattern ")"
        | _ => rawPattern;
      let printedType : Except PsSourcePrintError String :=
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
              let groupedValue : String :=
                if psSyntaxTermSimpleForApplication value then printedValue
                else psPrintCommonConcat3 "(" printedValue ")";
              Except.ok (psPrintJoin ""
                ["let ", printedPattern, printedType, " := ", groupedValue])

def psPrintDoLoopHead
    (printBody : PsSyntaxTerm -> Except PsSourcePrintError String)
    (native : Bool) (header : String) (body : PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match printBody body with
  | Except.error error => Except.error error
  | Except.ok printedBody =>
      if native then
        Except.ok (psPrintJoin "" [header, " do { ", printedBody, " }"])
      else
        Except.ok (psPrintJoin "" [header, " {\n  ", printedBody, "\n}"])

def psPrintDoBody
    (printTerm : PsSyntaxTerm -> Except PsSourcePrintError String)
    (native : Bool) (separator : String) (fuel : Nat) :
    PsSyntaxTerm -> Except PsSourcePrintError String :=
  match fuel with
  | Nat.zero =>
      fun (_body : PsSyntaxTerm) => Except.error PsSourcePrintError.fuelExhausted
  | Nat.succ remaining =>
      fun (body : PsSyntaxTerm) =>
        let smaller : PsSyntaxTerm -> Except PsSourcePrintError String :=
          psPrintDoBody printTerm native separator remaining;
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
                    if psStringEq printedTail "" then Except.ok printedHead
                    else Except.ok (psPrintCommonConcat3 printedHead separator printedTail);
        match body with
        | PsSyntaxTerm.letPatternE pattern annotation value tail _ =>
            withTail (psPrintBindingPatternHead printTerm pattern annotation value) tail
        | PsSyntaxTerm.letE name annotation value tail _ =>
            withTail (psPrintDoBinding printTerm name annotation "let " " := " value) tail
        | PsSyntaxTerm.doEndE _ => Except.ok ""
        | PsSyntaxTerm.doLetMutE name annotation value tail _ =>
            withTail (psPrintDoBinding printTerm name annotation "let mut " " := " value) tail
        | PsSyntaxTerm.doAssignE name value tail _ =>
            let printedHead : Except PsSourcePrintError String :=
              match psPrintSyntaxName name with
              | Except.error error => Except.error error
              | Except.ok printedName =>
                  match printTerm value with
                  | Except.error error => Except.error error
                  | Except.ok printedValue =>
                      Except.ok (psPrintJoin "" [printedName, " := (", printedValue, ")"]);
            withTail printedHead tail
        | PsSyntaxTerm.doIfE condition thenBody elseBody tail _ =>
            let printedHead : Except PsSourcePrintError String :=
              match printTerm condition with
              | Except.error error => Except.error error
              | Except.ok printedCondition =>
                  match smaller thenBody with
                  | Except.error error => Except.error error
                  | Except.ok printedThen =>
                      match smaller elseBody with
                      | Except.error error => Except.error error
                      | Except.ok printedElse =>
                          let head :=
                            if native then
                              psPrintJoin "" ["if ", printedCondition, " then { ", printedThen, " }"]
                            else
                              psPrintJoin "" ["if (", printedCondition, ") {\n  ", printedThen, "\n}"];
                          if psStringEq printedElse "" then Except.ok head
                          else if native then
                            Except.ok (psPrintJoin "" [head, " else { ", printedElse, " }"])
                          else
                            Except.ok (psPrintJoin "" [head, " else {\n  ", printedElse, "\n}"]);
            withTail printedHead tail
        | PsSyntaxTerm.doForE name collection loopBody tail _ =>
            let printedHead : Except PsSourcePrintError String :=
              match psPrintSyntaxName name with
              | Except.error error => Except.error error
              | Except.ok printedName =>
                  match printTerm collection with
                  | Except.error error => Except.error error
                  | Except.ok printedCollection =>
                      psPrintDoLoopHead smaller native
                        (psPrintJoin "" ["for ", printedName, " in ", printedCollection]) loopBody;
            withTail printedHead tail
        | PsSyntaxTerm.doForRangeE name lower upper loopBody tail _ =>
            let printedHead : Except PsSourcePrintError String :=
              match psPrintSyntaxName name with
              | Except.error error => Except.error error
              | Except.ok printedName =>
                  match printTerm lower with
                  | Except.error error => Except.error error
                  | Except.ok printedLower =>
                      match printTerm upper with
                      | Except.error error => Except.error error
                      | Except.ok printedUpper =>
                          psPrintDoLoopHead smaller native
                            (psPrintJoin "" ["for ", printedName, " in [",
                              printedLower, ":", printedUpper, "]"]) loopBody;
            withTail printedHead tail
        | PsSyntaxTerm.doWhileE condition loopBody tail _ =>
            let printedHead : Except PsSourcePrintError String :=
              match printTerm condition with
              | Except.error error => Except.error error
              | Except.ok printedCondition =>
                  psPrintDoLoopHead smaller native
                    (psPrintJoin "" ["while (", printedCondition, ")"]) loopBody;
            withTail printedHead tail
        | PsSyntaxTerm.doTryE action name recovery tail _ =>
            let printedHead : Except PsSourcePrintError String :=
              match psPrintSyntaxName name with
              | Except.error error => Except.error error
              | Except.ok printedName =>
                  match smaller action with
                  | Except.error error => Except.error error
                  | Except.ok printedBody =>
                      match smaller recovery with
                      | Except.error error => Except.error error
                      | Except.ok printedRecovery =>
                          if native then
                            Except.ok (psPrintJoin "" ["try { ", printedBody, " } catch ",
                              printedName, " => { ", printedRecovery, " }"])
                          else
                            Except.ok (psPrintJoin "" ["try {\n  ", printedBody, "\n} catch ",
                              printedName, " => {\n  ", printedRecovery, "\n}"]);
            withTail printedHead tail
        | PsSyntaxTerm.doBindE name annotation value tail _ =>
            withTail (psPrintDoBinding printTerm name annotation "let " " <- " value) tail
        | PsSyntaxTerm.doThenE action tail _ =>
            let printedAction : Except PsSourcePrintError String :=
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
        | _ =>
            match printTerm body with
            | Except.error error => Except.error error
            | Except.ok printed =>
                if psSyntaxTermSimpleForApplication body then Except.ok printed
                else Except.ok (psPrintCommonConcat3 "(" printed ")")

-- Operators consume primary/application operands. Preserve low-precedence
-- source forms as grouped terms in both surface printers.
def psPrintOperatorOperand (term : PsSyntaxTerm) (printed : String) : String :=
  match term with
  | PsSyntaxTerm.ifE _ _ _ _ => psPrintCommonConcat3 "(" printed ")"
  | PsSyntaxTerm.letE _ _ _ _ _ => psPrintCommonConcat3 "(" printed ")"
  | PsSyntaxTerm.letPatternE _ _ _ _ _ => psPrintCommonConcat3 "(" printed ")"
  | PsSyntaxTerm.matchE _ _ _ => psPrintCommonConcat3 "(" printed ")"
  | PsSyntaxTerm.lambda _ _ _ => psPrintCommonConcat3 "(" printed ")"
  | PsSyntaxTerm.forallE _ _ _ => psPrintCommonConcat3 "(" printed ")"
  | PsSyntaxTerm.doE _ _ => psPrintCommonConcat3 "(" printed ")"
  | _ => printed

def psPrintUnaryOperator
    (printTerm : PsSyntaxTerm -> Except PsSourcePrintError String)
    (operator : String) (operand : PsSyntaxTerm) :
    Except PsSourcePrintError String :=
  match printTerm operand with
  | Except.error error => Except.error error
  | Except.ok printed =>
      Except.ok (psPrintJoin "" ["(", operator, psPrintOperatorOperand operand printed, ")"])

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
          Except.ok (psPrintJoin "" ["(", psPrintOperatorOperand left printedLeft,
            " ", operator, " ", psPrintOperatorOperand right printedRight, ")"])
