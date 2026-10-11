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

-- The generated local name of an anonymous instance is never source syntax.
def psPrintTypedBinder (head : PsSyntaxBinderHead) (type : String) :
    Except PsSourcePrintError String := do
  if psSyntaxAnonymousInstanceBinder head then return "[" ++ type ++ "]"
  let names ← psPrintSyntaxNames (psSyntaxBinderNames head)
  let name := psPrintJoin " " names
  let delimiters := psPrintBinderDelimiters head.kind
  return delimiters.fst ++ name ++ " : " ++ type ++ delimiters.snd

def psPrintPatternWithFuel (fuel : Nat) (pattern : PsSyntaxPattern) :
    Except PsSourcePrintError String := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .natural value _ => return toString value
    | .bool value _ => return if value then "true" else "false"
    | .wildcard _ => return "_"
    | .variable name => psPrintSyntaxName name
    | .ctor name fields _ =>
      let name ← psPrintSyntaxName name
      let fields ← fields.mapM fun field => do
        let text ← psPrintPatternWithFuel fuel field
        return match field with
          | .ctor _ (_ :: _) _ => "(" ++ text ++ ")"
          | _ => text
      return String.intercalate " " (name :: fields)

def psPrintPattern (pattern : PsSyntaxPattern) : Except PsSourcePrintError String :=
  psPrintPatternWithFuel 4096 pattern

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

-- Parenthesize composite levels independently of the surrounding term printer.
def psPrintSyntaxLevel : PsSyntaxLevel → String
  | .number n => toString n
  | .name name => name
  | .hole => "_"
  | .offset base n => "(" ++ psPrintSyntaxLevel base ++ " + " ++ toString n ++ ")"
  | .max left right => "(max " ++ psPrintSyntaxLevel left ++ " " ++ psPrintSyntaxLevel right ++ ")"
  | .imax left right => "(imax " ++ psPrintSyntaxLevel left ++ " " ++ psPrintSyntaxLevel right ++ ")"

def psPrintSyntaxSort (isType : Bool) (level : PsSyntaxLevel) : String :=
  match isType, level with
  | true, .number 0 => "Type"
  | false, .number 0 => "Prop"
  | true, _ => "(Type " ++ psPrintSyntaxLevel level ++ ")"
  | false, _ => "(Sort " ++ psPrintSyntaxLevel level ++ ")"

def psPrintTactics (printTerm : PsSyntaxTerm → Except PsSourcePrintError String)
    (fuel : Nat) (tactics : List PsSyntaxTactic) : Except PsSourcePrintError String := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let lines ← tactics.mapM fun tactic => do
      match tactic with
      | .exactE value refine _ => return (if refine then "refine " else "exact ") ++ (← printTerm value)
      | .applyE value _ => return "apply " ++ (← printTerm value)
      | .intro names _ =>
        let rendered ← psPrintSyntaxNames names
        return "intro" ++ (if rendered.isEmpty then "" else " " ++ psPrintJoin " " rendered)
      | .assumption _ => return "assumption"
      | .reflexivity _ => return "rfl"
      | .constructor _ => return "constructor"
      | .focus body close _ =>
        let body ← psPrintTactics printTerm fuel body
        return (if close then "·" else "focus") ++ "\n  " ++ body.replace "\n" "\n  "
    return psPrintJoin "\n" lines
