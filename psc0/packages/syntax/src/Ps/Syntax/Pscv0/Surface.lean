import Ps.Syntax.Translate
import Ps.Foundation.List

-- Portable high-level intent; semantic lowering is a separate operation.
inductive PsPscv0DoItem where
  | bind (name : PsSyntaxName) (action : PsSyntaxTerm) (span : PsSourceSpan)
  | letValue (name : PsSyntaxName) (type : Option PsSyntaxTerm)
      (value : PsSyntaxTerm) (span : PsSourceSpan)
  | action (value : PsSyntaxTerm) (span : PsSourceSpan)
  | returnValue (value : PsSyntaxTerm) (span : PsSourceSpan)
structure PsPscv0DoBlock where
  items : List PsPscv0DoItem
  span : PsSourceSpan
structure PsPscv0SurfaceDeclaration where
  keyword : String
  declaration : PsSyntaxDeclaration
  doBody : Option PsPscv0DoBlock
structure PsPscv0SurfaceModule where
  originalSource : String
  proofScript : Bool
  commentTrivia : Bool
  imports : List PsSyntaxImport
  declarations : List PsPscv0SurfaceDeclaration
  errorName : PsSyntaxName
  discardName : PsSyntaxName

def psPscv0LanguageEdition : String := "pscv0"
def psPscv0ReferenceSha256 : String :=
  "843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5"
def psPscv0SurfaceCapability : String := "declaration-except-do/1"
def psPscv0FullConformance : Bool := false

def psPscv0Cat (values : List String) : String := psPrintJoin "" values

def psPscv0ParseError (error : PsParseError) : String :=
  match error with
  | .fuelExhausted => "PSCV0-PARSE-BUDGET"
  | .unexpectedEnd expected => psPscv0Cat ["PSCV0-PARSE-EOF: ", expected]
  | .expectedText expected actual span =>
      psPscv0Cat ["PSCV0-PARSE: ", expected, " at ", psNatToString span.start.line,
        ":", psNatToString span.start.column, "; got ", actual]
  | .expectedKind _ _ span =>
      psPscv0Cat ["PSCV0-PARSE-KIND at ", psNatToString span.start.line,
        ":", psNatToString span.start.column]

def psPscv0TokenAt (tokens : List PsToken) (offset : Nat) : Option PsToken :=
  match tokens with
  | [] => Option.none
  | token :: rest =>
      if Nat.beq token.span.start.byteOffset offset then Option.some token
      else psPscv0TokenAt rest offset

def psPscv0TokenTextAt (tokens : List PsToken) (offset : Nat) : String :=
  match psPscv0TokenAt tokens offset with
  | none => ""
  | some token => token.text

def psPscv0NameText (name : PsSyntaxName) : String := psPrintJoin "." name.segments

def psPscv0TokenNamesContain (tokens : List PsToken) (name : String) : Bool :=
  match tokens with
  | [] => false
  | token :: rest =>
      if psTokenKindEq token.kind PsTokenKind.identifier then
        if psStringEq token.text name then true
        else psPscv0TokenNamesContain rest name
      else psPscv0TokenNamesContain rest name

def psPscv0FreshNameWorker (tokens : List PsToken) (fuel : Nat)
    (candidate : String) : Except String String :=
  match fuel with
  | 0 => Except.error "PSCV0-FRESH-NAME-BUDGET"
  | remaining + 1 =>
      if psPscv0TokenNamesContain tokens candidate then
        psPscv0FreshNameWorker tokens remaining (String.push candidate '_')
      else Except.ok candidate

def psPscv0FreshName (tokens : List PsToken) (base : String)
    (span : PsSourceSpan) : Except String PsSyntaxName :=
  match psPscv0FreshNameWorker tokens (Nat.succ (psListLength tokens)) base with
  | Except.error error => Except.error error
  | Except.ok name => Except.ok (PsSyntaxName.mk [name] span)

def psPscv0GroupedArgument (tokens : List PsToken) (term : PsSyntaxTerm) : Bool :=
  let span := psSyntaxTermSpan term;
  psStringEq (psPscv0TokenTextAt tokens span.start.byteOffset) "("

def psPscv0RecordTerm (field : Prod PsSyntaxName PsSyntaxTerm) : PsSyntaxTerm := field.snd

def psPscv0TermBinderType (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) : PsSyntaxTerm := binder.snd

def psPscv0AlternativeTerm
    (alternative : Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)) : PsSyntaxTerm :=
  alternative.snd.fst

def psPscv0TermChildren (term : PsSyntaxTerm) : List PsSyntaxTerm :=
  match term with
  | .reference _ => []
  | .natural _ _ => []
  | .string _ _ => []
  | .character _ _ => []
  | .bool _ _ => []
  | .unit _ => []
  | .record fields _ => psListMap psPscv0RecordTerm fields
  | .app fn args _ => List.cons fn args
  | .lambda binders body _ => List.cons body (psListMap psPscv0TermBinderType binders)
  | .forallE binders body _ => List.cons body (psListMap psPscv0TermBinderType binders)
  | .letE _ type value body _ =>
      match type with
      | none => [value, body]
      | some annotation => [annotation, value, body]
  | .ifE condition yes no _ => [condition, yes, no]
  | .matchE scrutinee alternatives _ => List.cons scrutinee (psListMap psPscv0AlternativeTerm alternatives)

-- The seed supports structurally recursive function-valued results. Keeping
-- term as that returned function's argument preserves the complete Pi type
-- while avoiding a partially supplied recursive call in the old normalizer.
def psPscv0ValidateTermWithFuel (tokens : List PsToken) (fuel : Nat) :
    PsSyntaxTerm -> Except String Unit :=
  match fuel with
  | 0 => fun (_term : PsSyntaxTerm) => Except.error "PSCV0-TERM-BUDGET"
  | remaining + 1 =>
      let check : PsSyntaxTerm -> Except String Unit :=
        psPscv0ValidateTermWithFuel tokens remaining;
      fun (term : PsSyntaxTerm) =>
        let localCheck : Except String Unit :=
          match term with
          | .app fn args _ =>
              match args with
              | [] => Except.error "PSCV0-APP-03-COMPLETION-NOT-YET-SUPPORTED"
              | _ :: _ =>
                  let fnSpan := psSyntaxTermSpan fn;
                  if psStringEq (psPscv0TokenTextAt tokens fnSpan.stop.byteOffset) "(" then Except.ok ()
                  else if psListAny (psPscv0GroupedArgument tokens) args then Except.error "PSCV0-APP-02"
                  else Except.ok ()
          | _ => Except.ok ();
        match localCheck with
        | Except.error error => Except.error error
        | Except.ok _ =>
            match psListMapExcept check (psPscv0TermChildren term) with
            | Except.error error => Except.error error
            | Except.ok _ => Except.ok ()

def psPscv0ReadTerm (proofScript : Bool) (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxTerm) :=
  let parsed : Except PsParseError (PsParseResult PsSyntaxTerm) :=
    if proofScript then psParseProofScriptTerm cursor else psParseLeanTerm cursor;
  match parsed with
  | Except.error error => Except.error (psPscv0ParseError error)
  | Except.ok result =>
      if proofScript then
        match psPscv0ValidateTermWithFuel cursor.remaining 4096 result.value with
        | Except.error error => Except.error error
        | Except.ok _ => Except.ok result
      else Except.ok result

def psPscv0ReadCompleteTerm (proofScript : Bool) (cursor : PsTokenCursor) : Except String PsSyntaxTerm :=
  match psPscv0ReadTerm proofScript cursor with
  | Except.error error => Except.error error
  | Except.ok parsed =>
      if psTokenCursorDone parsed.cursor then Except.ok parsed.value
      else Except.error "PSCV0-TERM-TRAILING-INPUT"

-- APP-04: application printing is compositional over the *actual*
-- nested source syntax tree. Unlike the historical Lean printer, a compound
-- function head is not rejected or flattened into a larger argument list.
-- This source printer has no effect on canonical Core or kernel trust.
-- Unsupported non-application source families still fail through the
-- unchanged normal Lean printer until a selected v7 printer owns them.
def psPscv0PrintLeanApplicationWithFuel (fuel : Nat) :
    PsSyntaxTerm -> Except PsSourcePrintError String :=
  match fuel with
  | 0 => fun (_term : PsSyntaxTerm) => Except.error PsSourcePrintError.fuelExhausted
  | remaining + 1 =>
      let smaller : PsSyntaxTerm -> Except PsSourcePrintError String :=
        psPscv0PrintLeanApplicationWithFuel remaining;
      fun (term : PsSyntaxTerm) =>
        match term with
        | .app head args _ =>
            match args with
            | [] => Except.error PsSourcePrintError.unsupportedApplication
            | _ :: _ =>
                match smaller head with
                | Except.error error => Except.error error
                | Except.ok renderedHead =>
                    let printArgument : PsSyntaxTerm -> Except PsSourcePrintError String :=
                      fun (argument : PsSyntaxTerm) =>
                        match smaller argument with
                        | Except.error error => Except.error error
                        | Except.ok rendered =>
                            if psSyntaxTermSimpleForApplication argument then Except.ok rendered
                            else Except.ok (psPscv0Cat ["(", rendered, ")"]);
                    match psListMapExcept printArgument args with
                    | Except.error error => Except.error error
                    | Except.ok renderedArgs =>
                        let callee :=
                          if psSyntaxTermSimpleForApplication head then renderedHead
                          else psPscv0Cat ["(", renderedHead, ")"];
                        Except.ok (psPscv0Cat [callee, " ", psPrintJoin " " renderedArgs])
        | _ => psPrintLeanTerm term

def psPscv0PrintTerm (proofScript : Bool) (term : PsSyntaxTerm) : Except String String :=
  let result : Except PsSourcePrintError String :=
    if proofScript then psPrintProofScriptTerm term
    else psPscv0PrintLeanApplicationWithFuel 4096 term;
  match result with
  | Except.error _ => Except.error "PSCV0-SOURCE-TERM-PRINT-UNSUPPORTED"
  | Except.ok text => Except.ok text

def psPscv0IndentChars (chars : List Char) : String :=
  match chars with
  | [] => ""
  | char :: rest =>
      let suffix := psPscv0IndentChars rest;
      if psLexCharEq char '\n' then psPscv0Cat ["\n  ", suffix]
      else psPscv0Cat [String.push "" char, suffix]

def psPscv0Indent (text : String) : String :=
  let cursor := psLexCursorFromString text;
  psPscv0Cat ["  ", psPscv0IndentChars cursor.remaining]

def psPscv0DoItemSpan (item : PsPscv0DoItem) : PsSourceSpan :=
  match item with
  | .bind _ _ span => span
  | .letValue _ _ _ span => span
  | .action _ span => span
  | .returnValue _ span => span

def psPscv0PrintDoItem (proofScript : Bool) (item : PsPscv0DoItem) : Except String String :=
  match item with
  | .bind name action _ =>
      match psPscv0PrintTerm proofScript action with
      | Except.error error => Except.error error
      | Except.ok text => Except.ok (psPscv0Cat ["let ", psPscv0NameText name, " ← ", text])
  | .letValue name type value _ =>
      let typeText : Except String String :=
        match type with
        | none => Except.ok ""
        | some annotation =>
            match psPscv0PrintTerm proofScript annotation with
            | Except.error error => Except.error error
            | Except.ok text => Except.ok (psPscv0Cat [" : ", text]);
      match typeText with
      | Except.error error => Except.error error
      | Except.ok annotation =>
          match psPscv0PrintTerm proofScript value with
          | Except.error error => Except.error error
          | Except.ok text => Except.ok (psPscv0Cat ["let ", psPscv0NameText name, annotation, " := ", text])
  | .action value _ => psPscv0PrintTerm proofScript value
  | .returnValue value _ =>
      match psPscv0PrintTerm proofScript value with
      | Except.error error => Except.error error
      | Except.ok text => Except.ok (psPscv0Cat ["return ", text])

def psPscv0PrintDoBlock (proofScript : Bool) (block : PsPscv0DoBlock) : Except String String :=
  let printItem : PsPscv0DoItem -> Except String String := psPscv0PrintDoItem proofScript;
  match psListMapExcept printItem block.items with
  | Except.error error => Except.error error
  | Except.ok lines =>
      let body := psPscv0Indent (psPrintJoin "\n" lines);
      if proofScript then Except.ok (psPscv0Cat ["do {\n", body, "\n}"])
      else Except.ok (psPscv0Cat ["do\n", body])

def psPscv0ExceptCall (constructor : String) (value : PsSyntaxTerm) (span : PsSourceSpan) : PsSyntaxTerm :=
  PsSyntaxTerm.app (PsSyntaxTerm.reference (PsSyntaxName.mk ["Except", constructor] span)) [value] span

def psPscv0BindMatch (action : PsSyntaxTerm) (name errorName : PsSyntaxName)
    (continuation : PsSyntaxTerm) (span : PsSourceSpan) : PsSyntaxTerm :=
  let failure := psPscv0ExceptCall "error" (PsSyntaxTerm.reference errorName) span;
  let errorPattern := PsSyntaxPattern.constructor (PsSyntaxName.mk ["Except", "error"] span) [errorName] span;
  let okPattern := PsSyntaxPattern.constructor (PsSyntaxName.mk ["Except", "ok"] span) [name] span;
  PsSyntaxTerm.matchE action
    [Prod.mk errorPattern (Prod.mk failure span), Prod.mk okPattern (Prod.mk continuation span)] span

def psPscv0LowerDoItems (errorName discardName : PsSyntaxName)
    (items : List PsPscv0DoItem) : Except String PsSyntaxTerm :=
  match items with
  | [] => Except.error "PSCV0-DO-MISSING-FINAL-ACTION"
  | item :: rest =>
      match item with
      | .returnValue value span =>
          match rest with
          | [] => Except.ok (psPscv0ExceptCall "ok" value span)
          | _ :: _ => Except.error "PSCV0-DO-NONTERMINAL-RETURN-UNSUPPORTED"
      | .action value span =>
          match rest with
          | [] => Except.ok value
          | _ :: _ =>
              match psPscv0LowerDoItems errorName discardName rest with
              | Except.error error => Except.error error
              | Except.ok continuation => Except.ok (psPscv0BindMatch value discardName errorName continuation span)
      | .bind name action span =>
          if psStringEq (psPscv0NameText name) "Except" then Except.error "PSCV0-DO-EFFECT-SHADOW-UNSUPPORTED"
          else
            match psPscv0LowerDoItems errorName discardName rest with
            | Except.error error => Except.error error
            | Except.ok continuation =>
                let actual := if psStringEq (psPscv0NameText name) "_" then discardName else name;
                Except.ok (psPscv0BindMatch action actual errorName continuation span)
      | .letValue name type value span =>
          if psStringEq (psPscv0NameText name) "Except" then Except.error "PSCV0-DO-EFFECT-SHADOW-UNSUPPORTED"
          else
            match psPscv0LowerDoItems errorName discardName rest with
            | Except.error error => Except.error error
            | Except.ok continuation => Except.ok (PsSyntaxTerm.letE name type value continuation span)
