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
  | .scientific _ _ => true
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

-- The absence marker has no term spelling. Only declaration printers may
-- consume it, preserving the distinction between no annotation and `: _`.
def psPrintDeclarationResult (printTerm : PsSyntaxTerm → Except PsSourcePrintError String)
    (type : PsSyntaxTerm) : Except PsSourcePrintError String := do
  match type with
  | .omittedType _ => return ""
  | _ => return " : " ++ (← printTerm type)

def psPrintTactics (printTerm : PsSyntaxTerm → Except PsSourcePrintError String)
    (fuel : Nat) (tactics : List PsSyntaxTactic) : Except PsSourcePrintError String := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let lines ← tactics.mapM fun tactic => do
      match tactic with
      | .exactE value refine _ => return (if refine then "refine " else "exact ") ++ (← printTerm value)
      | .applyE value _ => return "apply " ++ (← printTerm value)
      | .localE name type value reducible _ =>
        let annotation ← match type with
          | none => pure ""
          | some type => do
            let rendered ← printTerm type
            pure (" : " ++ rendered)
        return (if reducible then "let " else "have ") ++ (← psPrintSyntaxName name) ++
          annotation ++ " := " ++ (← printTerm value)
      | .change type select _ => return (if select then "show " else "change ") ++ (← printTerm type)
      | .eliminate value induction _ =>
        return (if induction then "induction " else "cases ") ++ (← printTerm value)
      | .caseE tag names body _ =>
        let header ← match tag with
          | none => pure "next"
          | some name => do
            let name ← psPrintSyntaxName name
            pure ("case " ++ name)
        let names ← psPrintSyntaxNames names
        let body ← psPrintTactics printTerm fuel body
        return header ++ (if names.isEmpty then "" else " " ++ psPrintJoin " " names) ++
          " =>\n  " ++ body.replace "\n" "\n  "
      | .intro names _ =>
        let rendered ← psPrintSyntaxNames names
        return "intro" ++ (if rendered.isEmpty then "" else " " ++ psPrintJoin " " rendered)
      | .assumption _ => return "assumption"
      | .indexValidity _ => return "get_elem_tactic"
      | .reflexivity _ => return "rfl"
      | .constructor _ => return "constructor"
      | .focus body close _ =>
        let body ← psPrintTactics printTerm fuel body
        return (if close then "·" else "focus") ++ "\n  " ++ body.replace "\n" "\n  "
      | .each body any _ =>
        let body ← psPrintTactics printTerm fuel body
        return (if any then "any_goals" else "all_goals") ++ "\n  " ++ body.replace "\n" "\n  "
    return psPrintJoin "\n" lines

-- Shared readable do layout; only delimiter/conditional spelling is target-owned.
def psPrintDoItems (proofScript : Bool)
    (printTerm : PsSyntaxTerm → Except PsSourcePrintError String)
    (fuel : Nat) (items : List PsSyntaxDoItem) : Except PsSourcePrintError String := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let block := fun text => if proofScript then
        " {\n  " ++ text.replace "\n" "\n  " ++ "\n}"
      else "\n  " ++ text.replace "\n" "\n  "
    let lines ← items.mapM fun item => do
      match item with
      | .binding pattern type value monadic _ =>
        let annotation ← match type with
          | none => pure ""
          | some type => do pure (" : " ++ (← printTerm type))
        return "let " ++ (← psPrintPattern pattern) ++ annotation ++
          (if monadic then " ← " else " := ") ++ (← printTerm value)
      | .action value _ => printTerm value
      | .returnValue value _ => return "return " ++ (← printTerm value)
      | .conditional name condition yes no _ =>
        let proof ← match name with
          | none => pure ""
          | some name => do pure ((← psPrintSyntaxName name) ++ " : ")
        let condition ← printTerm condition
        let yes ← psPrintDoItems proofScript printTerm fuel yes
        let noText ← if no.isEmpty then pure "" else do
          pure (" else" ++ block (← psPrintDoItems proofScript printTerm fuel no))
        return (if proofScript then "if (" ++ proof ++ condition ++ ")"
                else "if " ++ proof ++ condition ++ " then") ++ block yes ++ noText
      | .conditionalPattern pattern value yes no _ =>
        let yes ← psPrintDoItems proofScript printTerm fuel yes
        let noText ← if no.isEmpty then pure "" else do
          pure (" else" ++ block (← psPrintDoItems proofScript printTerm fuel no))
        return "if let " ++ (← psPrintPattern pattern) ++ " := " ++ (← printTerm value) ++
          (if proofScript then "" else " then") ++ block yes ++ noText
    return psPrintJoin "\n" lines

-- Parenthesized reconstruction retains the source operator protocol. Printing
-- a class-projection call instead would lose coercion-tree semantics.
def psPrintSyntaxOperator (kind : PsSyntaxOperatorKind) (spelling : String)
    (arguments : List String) : Except PsSourcePrintError String :=
  match kind, arguments with
  | .unary, [value] => .ok ("(" ++ spelling ++ "(" ++ value ++ "))")
  | .unary, _ => .error (.unsupportedSourceForm "unary operator arity")
  | _, [left, right] => .ok ("(" ++ left ++ " " ++ spelling ++ " " ++ right ++ ")")
  | _, _ => .error (.unsupportedSourceForm "binary operator arity")
