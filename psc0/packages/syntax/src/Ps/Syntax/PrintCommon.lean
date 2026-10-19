import Ps.Syntax.Ast
import Ps.Syntax.Lexer

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
    Except PsSourcePrintError String := do
  if name.resolvedName.isSome then
    throw (.unsupportedSourceForm "an internal resolved name has no source spelling")
  if !name.universeBinders.isEmpty then
    throw (.unsupportedSourceForm "universe binders require a declaration head")
  if name.segments.isEmpty then throw .emptyName
  if name.segments.any (fun part => part.toList.contains '»') then
    throw (.unsupportedSourceForm "identifier contains a closing guillemet")
  return psPrintJoin "." (name.segments.map fun part =>
    psLexIdentifierSpelling part name.escaped)

def psPrintDeclarationName (name : PsSyntaxName) :
    Except PsSourcePrintError String := do
  let head ← psPrintSyntaxName { name with universeBinders := [] }
  if name.universeBinders.isEmpty then return head
  let levels ← name.universeBinders.mapM fun binder =>
    psPrintSyntaxName {
      segments := binder.segments, span := binder.span, escaped := binder.escaped }
  return head ++ ".{" ++ psPrintJoin ", " levels ++ "}"

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
    | .inaccessible value => psPrintPatternWithFuel fuel value
    | .ctor name fields _ | .dotCtor name fields _ =>
      let name ← psPrintSyntaxName name
      let name := match pattern with | .dotCtor .. => "." ++ name | _ => name
      let fields ← fields.mapM fun field => do
        let text ← psPrintPatternWithFuel fuel field
        return match field with
          | .ctor _ (_ :: _) _ | .dotCtor _ (_ :: _) _ => "(" ++ text ++ ")"
          | .inaccessible (.ctor _ (_ :: _) _) =>
            "(" ++ text ++ ")"
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
  | .name name => psLexIdentifierSpelling name
      (psLexReservedIdentifier name || (["max", "imax"] : List String).contains name)
  | .qualifiedName segments => String.intercalate "." (segments.map fun part =>
      psLexIdentifierSpelling part
        (psLexReservedIdentifier part || (["max", "imax"] : List String).contains part))
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

def psPrintRCasesAtom (pattern : PsSyntaxRCasesPattern) (text : String) : String :=
  match pattern with
  | .typed .. | .alternatives .. => "(" ++ text ++ ")"
  | _ => text

def psPrintRCasesPattern (printTerm : PsSyntaxTerm → Except PsSourcePrintError String)
    (fuel : Nat) (pattern : PsSyntaxRCasesPattern) : Except PsSourcePrintError String := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .one name => psPrintSyntaxName name
    | .clear _ => return "-"
    | .explicit pattern _ =>
      return "@" ++ psPrintRCasesAtom pattern (← psPrintRCasesPattern printTerm fuel pattern)
    | .typed pattern type _ =>
      let text ← psPrintRCasesPattern printTerm fuel pattern
      let text := match pattern with | .typed .. => "(" ++ text ++ ")" | _ => text
      return text ++ " : " ++ (← printTerm type)
    | .tuple patterns _ =>
      let patterns ← patterns.mapM (psPrintRCasesPattern printTerm fuel)
      return "⟨" ++ psPrintJoin ", " patterns ++ "⟩"
    | .alternatives patterns _ =>
      if patterns.isEmpty then throw (.unsupportedSourceForm "empty rcases alternatives")
      let patterns ← patterns.mapM fun pattern => do
        let text ← psPrintRCasesPattern printTerm fuel pattern
        pure (psPrintRCasesAtom pattern text)
      return psPrintJoin " | " patterns
    | .paren pattern _ =>
      return "(" ++ (← psPrintRCasesPattern printTerm fuel pattern) ++ ")"

def psPrintRIntroPattern (printTerm : PsSyntaxTerm → Except PsSourcePrintError String)
    (fuel : Nat) (pattern : PsSyntaxRIntroPattern) : Except PsSourcePrintError String := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match pattern with
    | .pattern pattern =>
      return psPrintRCasesAtom pattern (← psPrintRCasesPattern printTerm fuel pattern)
    | .group patterns type _ =>
      if patterns.isEmpty then throw (.unsupportedSourceForm "empty rintro group")
      let patterns ← patterns.mapM (psPrintRIntroPattern printTerm fuel)
      let annotation ← match type with
        | none => pure ""
        | some type => do pure (" : " ++ (← printTerm type))
      return "(" ++ psPrintJoin " " patterns ++ annotation ++ ")"

-- Printing a calc annotation must preserve the leading-hole type hint.
-- Parenthesizing its first infix operand would turn _ into (_) and change
-- native elaboration in heterogeneous/coercion chains.
def psPrintCalcLeadingHole (fuel start : Nat) (source : PsSyntaxTerm) :
    Except PsSourcePrintError Bool := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if (psSyntaxTermSpan source).start.byteOffset != start then return false
    match source with
    | .hole span => return span.stop.byteOffset == span.start.byteOffset + 1
    | _ =>
      let children := match source with
        | .operatorE _ _ _ arguments _ => arguments
        | .app fn arguments _ => fn :: arguments
        | .call fn arguments _ => fn :: arguments.map Prod.snd
        | .ascription value _ _ => [value]
        | _ => []
      for child in children do
        if ← psPrintCalcLeadingHole fuel start child then return true
      return false

def psPrintCalcAnnotation (printTerm : PsSyntaxTerm → Except PsSourcePrintError String)
    (fuel : Nat) (source : PsSyntaxTerm) : Except PsSourcePrintError String := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if !(← psPrintCalcLeadingHole (fuel + 1) (psSyntaxTermSpan source).start.byteOffset source) then
      return ← printTerm source
    match source with
    | .operatorE _ _ spelling [left, right] _ =>
      return (← psPrintCalcAnnotation printTerm fuel left) ++ " " ++ spelling ++ " " ++
        (← printTerm right)
    | .app (.reference name) [left, right] _ =>
      let spelling := [(["And"], "∧"), (["Or"], "∨"), (["Iff"], "↔"),
        (["Prod"], "×"), (["List", "cons"], "::")].find? (fun item => item.1 == name.segments)
      match spelling with
      | some (_, spelling) =>
        return (← psPrintCalcAnnotation printTerm fuel left) ++ " " ++ spelling ++ " " ++
          (← printTerm right)
      | none => printTerm source
    | _ => printTerm source

def psPrintCalc (printTerm : PsSyntaxTerm → Except PsSourcePrintError String)
    (fuel : Nat) (steps : List (PsSyntaxTerm × PsSyntaxTerm)) :
    Except PsSourcePrintError String := do
  if steps.isEmpty then throw (.unsupportedSourceForm "empty calc")
  let rows ← steps.mapM fun (annotation, proof) => do
    let annotation ← psPrintCalcAnnotation printTerm fuel annotation
    let proof ← printTerm proof
    pure ((annotation ++ " := " ++ proof).replace "\n" "\n  ")
  return "calc\n  " ++ psPrintJoin "\n  " rows


def psPrintProofLocation (printTerm : PsSyntaxTerm → Except PsSourcePrintError String)
    (location : PsSyntaxProofLocation PsSyntaxTerm) : Except PsSourcePrintError String := do
  match location with
  | .all => return " at *"
  | .targets [] true => return ""
  | .targets hypotheses target =>
    if hypotheses.isEmpty && !target then
      throw (.unsupportedSourceForm "empty proof location")
    let hypotheses ← hypotheses.mapM fun term => do
      let text ← printTerm term
      pure ("(" ++ text ++ ")")
    return " at " ++ psPrintJoin " " (hypotheses ++ if target then ["⊢"] else [])

def psPrintTactics (printTerm : PsSyntaxTerm → Except PsSourcePrintError String)
    (fuel : Nat) (tactics : List PsSyntaxTactic) : Except PsSourcePrintError String := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let lines ← tactics.mapM fun tactic => do
      match tactic with
      | .exactE value refine _ => return (if refine then "refine " else "exact ") ++ (← printTerm value)
      | .applyE value _ => return "apply " ++ (← printTerm value)
      | .rewriteE rules location close _ =>
        let rules ← rules.mapM fun (source, reverse) => do
          pure ((if reverse then "← " else "") ++ (← printTerm source))
        return (if close then "rw [" else "rewrite [") ++ psPrintJoin ", " rules ++ "]" ++
          (← psPrintProofLocation printTerm location)
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
      | .suffices name type value _ =>
        return "suffices " ++ (← psPrintSyntaxName name) ++ " : " ++
          (← printTerm type) ++ " from " ++ (← printTerm value)
      | .calcE steps _ => psPrintCalc printTerm fuel steps
      | .classicalE body _ =>
        let body ← psPrintTactics printTerm fuel body
        return "classical\n  " ++ body.replace "\n" "\n  "
      | .intros names _ =>
        let rendered ← psPrintSyntaxNames names
        return "intros" ++ (if rendered.isEmpty then "" else " " ++ psPrintJoin " " rendered)
      | .rcasesE targets pattern _ =>
        let targets ← targets.mapM fun target => do
          let equation ← match target.equationName? with
            | none => pure ""
            | some name => do pure ((← psPrintSyntaxName name) ++ " : ")
          pure (equation ++ (← printTerm target.term))
        let pattern ← match pattern with
          | none => pure ""
          | some pattern => do pure (" with " ++ (← psPrintRCasesPattern printTerm fuel pattern))
        return "rcases" ++ (if targets.isEmpty then "" else " " ++ psPrintJoin ", " targets) ++ pattern
      | .rintroE patterns type _ =>
        if patterns.isEmpty then throw (.unsupportedSourceForm "empty rintro")
        let patterns ← patterns.mapM (psPrintRIntroPattern printTerm fuel)
        let annotation ← match type with
          | none => pure ""
          | some type => do pure (" : " ++ (← printTerm type))
        return "rintro " ++ psPrintJoin " " patterns ++ annotation
      | .obtainE pattern type values _ =>
        let pattern ← match pattern with
          | none => pure ""
          | some pattern => do
            let text ← psPrintRCasesPattern printTerm fuel pattern
            let text := match pattern with | .typed .. => "(" ++ text ++ ")" | _ => text
            pure (" " ++ text)
        let annotation ← match type with
          | none => pure ""
          | some type => do pure (" : " ++ (← printTerm type))
        let values ← match values with
          | none => pure ""
          | some values => do
            if values.isEmpty then throw (.unsupportedSourceForm "empty obtain values")
            pure (" := " ++ psPrintJoin ", " (← values.mapM printTerm))
        return "obtain" ++ pattern ++ annotation ++ values
      | .byCases name proposition _ =>
        let name ← match name with
          | none => pure ""
          | some name => do pure ((← psPrintSyntaxName name) ++ " : ")
        return "by_cases " ++ name ++ (← printTerm proposition)
      | .exfalso _ => return "exfalso"
      | .decide _ => return "decide"
      | .extE patterns depth _ =>
        let patterns ← patterns.mapM (psPrintRIntroPattern printTerm fuel)
        return "ext" ++ (if patterns.isEmpty then "" else " " ++ psPrintJoin " " patterns) ++
          (if depth == 100 then "" else " : " ++ psNatToString depth)
      | .intro names _ =>
        let rendered ← psPrintSyntaxNames names
        return "intro" ++ (if rendered.isEmpty then "" else " " ++ psPrintJoin " " rendered)
      | .assumption _ => return "assumption"
      | .indexValidity _ => return "get_elem_tactic"
      | .reflexivity _ => return "rfl"
      | .constructor _ => return "constructor"
      | .constructorFirst _ => return "constructor!"
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
