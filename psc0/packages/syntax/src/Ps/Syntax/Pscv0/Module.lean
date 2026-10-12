import Ps.Syntax.Pscv0.ProgramRead
import Ps.Syntax.Pscv0.TypePrint

-- Full original input is retained. Printing unanchored comments declines.
def psPscv0SkipEndedTokens (tokens : List PsToken) (offset : Nat) : List PsToken :=
  match tokens with
  | [] => []
  | token :: rest =>
      if Nat.ble token.span.stop.byteOffset offset then psPscv0SkipEndedTokens rest offset
      else tokens

def psPscv0CommentTriviaWorker (chars : List Char) (position : PsSourcePos)
    (tokens : List PsToken) : Bool :=
  match chars with
  | [] => false
  | char :: rest =>
      let current := psPscv0SkipEndedTokens tokens position.byteOffset;
      let gap : Bool :=
        match current with
        | [] => true
        | token :: _ => Nat.ble (Nat.succ position.byteOffset) token.span.start.byteOffset;
      let whitespace := if Nat.beq (Char.toNat char) 65279 then true else psLexWhitespace char;
      if gap then
        if whitespace then psPscv0CommentTriviaWorker rest (psLexAdvancePosition position char) current
        else true
      else psPscv0CommentTriviaWorker rest (psLexAdvancePosition position char) current

def psPscv0FindBlock (blocks : List PsPscv0DoBlock) (offset : Nat) : Option PsPscv0DoBlock :=
  match blocks with
  | [] => Option.none
  | block :: rest =>
      if Nat.beq block.span.start.byteOffset offset then Option.some block
      else psPscv0FindBlock rest offset

def psPscv0BodyBlock (blocks : List PsPscv0DoBlock) (value : PsSyntaxTerm) : Option PsPscv0DoBlock :=
  match value with
  | .reference name =>
      if psStringEq (psPscv0NameText name) psPscv0DoSlot then psPscv0FindBlock blocks name.span.start.byteOffset
      else Option.none
  | _ => Option.none

def psPscv0ExceptType (type : PsSyntaxTerm) : Bool :=
  match type with
  | .call (.reference name) args _ =>
      psStringEq (psPscv0NameText name) "Except" && args.length == 2 && args.all (fun a => a.fst.isNone)
  | .app fn args _ =>
      match fn with
      | .reference name =>
          if psStringEq (psPscv0NameText name) "Except" then Nat.beq (psListLength args) 2 else false
      | _ => false
  | _ => false

def psPscv0BinderShadowsExcept (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) : Bool :=
  (psSyntaxBinderNames binder.fst).any (fun name => psStringEq (psPscv0NameText name) "Except")
def psPscv0BinderType (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) : PsSyntaxTerm := binder.snd

def psPscv0ConstructorTerms (constructor : PsSyntaxInductiveConstructor) : List PsSyntaxTerm :=
  psListMap psPscv0BinderType constructor.fields ++ constructor.resultType.toList

def psPscv0JoinTermLists (values : List (List PsSyntaxTerm)) : List PsSyntaxTerm :=
  match values with
  | [] => []
  | first :: rest => psListAppend first (psPscv0JoinTermLists rest)

def psPscv0DeclarationTerms (declaration : PsSyntaxDeclaration) : List PsSyntaxTerm :=
  match declaration with
  | .definition _ binders type value _ => List.cons type (List.cons value (psListMap psPscv0BinderType binders))
  | .partialDefinition _ binders type value _ => List.cons type (List.cons value (psListMap psPscv0BinderType binders))
  | .theoremDecl _ binders type value _ => List.cons type (List.cons value (psListMap psPscv0BinderType binders))
  | .structureDecl _ params result fields _ =>
      result.toList ++ psListMap psPscv0BinderType (psListAppend params fields)
  | .inductiveDecl _ params result constructors _ =>
      let terms := psListAppend (psListMap psPscv0BinderType params)
        (psPscv0JoinTermLists (psListMap psPscv0ConstructorTerms constructors));
      match result with
      | none => terms
      | some type => List.cons type terms

def psPscv0AttachDeclaration (proofScript : Bool) (tokens : List PsToken)
    (blocks : List PsPscv0DoBlock) (errorName discardName : PsSyntaxName)
    (declaration : PsSyntaxDeclaration) : Except String PsPscv0SurfaceDeclaration :=
  let syntaxCheck : Except String Unit :=
    if proofScript then
      let check : PsSyntaxTerm -> Except String Unit := psPscv0ValidateTermWithFuel tokens 4096;
      match psListMapExcept check (psPscv0DeclarationTerms declaration) with
      | Except.error error => Except.error error
      | Except.ok _ => Except.ok ()
    else Except.ok ();
  match syntaxCheck with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match declaration with
      | .partialDefinition _ _ _ _ _ => Except.error "PSCV0-PARTIAL-EXCLUDED"
      | .definition _ binders type value span =>
          let keyword := psPscv0TokenTextAt tokens span.start.byteOffset;
          let block := psPscv0BodyBlock blocks value;
          match block with
          | none => Except.ok (PsPscv0SurfaceDeclaration.mk keyword declaration Option.none)
          | some body =>
              if psPscv0ExceptType type then
                if psListAny psPscv0BinderShadowsExcept binders then Except.error "PSCV0-DO-EFFECT-SHADOW-UNSUPPORTED"
                else
                  match psPscv0LowerDoItems errorName discardName body.items with
                  | Except.error error => Except.error error
                  | Except.ok _ => Except.ok (PsPscv0SurfaceDeclaration.mk keyword declaration block)
              else Except.error "PSCV0-DO-EXPLICIT-EXCEPT-RESULT-REQUIRED"
      | _ => Except.ok (PsPscv0SurfaceDeclaration.mk "" declaration Option.none)

def psPscv0CountDoBodies (declarations : List PsPscv0SurfaceDeclaration) : Nat :=
  match declarations with
  | [] => 0
  | declaration :: rest =>
      let tail := psPscv0CountDoBodies rest;
      match declaration.doBody with
      | none => tail
      | some _ => Nat.succ tail

structure PsPscv0SourceInput where
  tokens : List PsToken
  rewritten : PsPscv0Rewritten
  errorName : PsSyntaxName
  discardName : PsSyntaxName
  commentTrivia : Bool

-- Both declaration-only translation and ordered-program compilation use the
-- same lexical budgets, do-block reader, hygiene and source validation.
def psPscv0PrepareSource (proofScript : Bool) (source : String) (legacyDo : Bool := true) :
    Except String PsPscv0SourceInput := do
  if source.utf8ByteSize > 1048576 then throw "PSCV0-SOURCE-BYTE-BUDGET"
  let tokens ← (if proofScript then psLexProofScript source else psLex source).mapError
    (fun _ => "PSCV0-LEXICAL-SOURCE-ERROR")
  if tokens.length > 65536 then throw "PSCV0-SOURCE-TOKEN-BUDGET"
  let rewritten ← if legacyDo then
      psPscv0RewriteTokens proofScript 65537 (PsTokenCursor.mk tokens) "" 0 [] []
    else pure (PsPscv0Rewritten.mk tokens [])
  let pos := PsSourcePos.mk 0 1 1
  let span := PsSourceSpan.mk pos pos
  let errorName ← psPscv0FreshName tokens "pscv0InternalError" span
  let discardName ← psPscv0FreshName tokens "pscv0InternalDiscard" span
  let cursor := psLexCursorFromString source
  return {
    tokens := tokens
    rewritten := rewritten
    errorName := errorName
    discardName := discardName
    commentTrivia := psPscv0CommentTriviaWorker cursor.remaining cursor.position tokens }

def psPscv0ParseSource (proofScript : Bool) (source : String) :
    Except String PsPscv0SurfaceModule := do
  let input ← psPscv0PrepareSource proofScript source
  -- This translation API deliberately remains flat. Scope commands are never
  -- discarded to manufacture a printable declaration-only module.
  let parsed ← if proofScript then psPscv0ParseTokens input.rewritten.tokens
    else (psParseLeanTokens input.rewritten.tokens).mapError psPscv0ParseError
  let declarations ← parsed.declarations.mapM
    (psPscv0AttachDeclaration proofScript input.tokens input.rewritten.blocks
      input.errorName input.discardName)
  if psPscv0CountDoBodies declarations != input.rewritten.blocks.length then
    throw "PSCV0-DO-DECLARATION-BODY-ONLY"
  return {
    originalSource := source
    proofScript := proofScript
    commentTrivia := input.commentTrivia
    imports := parsed.imports
    declarations := declarations
    errorName := input.errorName
    discardName := input.discardName }

def psPscv0LowerDeclaration (errorName discardName : PsSyntaxName)
    (surface : PsPscv0SurfaceDeclaration) : Except String PsSyntaxDeclaration :=
  match surface.doBody with
  | none => Except.ok surface.declaration
  | some block =>
      match surface.declaration with
      | .definition name binders type _ span =>
          match psPscv0LowerDoItems errorName discardName block.items with
          | Except.error error => Except.error error
          | Except.ok body => Except.ok (PsSyntaxDeclaration.definition name binders type body span)
      | _ => Except.error "PSCV0-DO-DECLARATION-BODY-ONLY"

-- The native program API retains typed do syntax. Legacy source translation
-- keeps its explicitly bounded Except-only contract and never serves compilation.
def psPscv0ParseProgram (source : String) : Except String PsSyntaxProgram := do
  let input ← psPscv0PrepareSource true source false
  let parsed ← psPscv0ParseProgramTokens input.tokens
  for command in parsed.commands do
    match command with
    | .declaration declaration | .registeredDeclaration declaration _ =>
      match declaration with
      | .partialDefinition .. => throw "PSCV0-PARTIAL-EXCLUDED"
      | _ => pure ()
      for term in psPscv0DeclarationTerms declaration do
        psPscv0ValidateTermWithFuel input.tokens 4096 term
    | .variableCmd binders _ =>
      for (_, type) in binders do psPscv0ValidateTermWithFuel input.tokens 4096 type
    | _ => pure ()
  return parsed

def psPscv0LowerModule (surface : PsPscv0SurfaceModule) : Except String PsSyntaxModule :=
  let lower : PsPscv0SurfaceDeclaration -> Except String PsSyntaxDeclaration :=
    psPscv0LowerDeclaration surface.errorName surface.discardName;
  match psListMapExcept lower surface.declarations with
  | Except.error error => Except.error error
  | Except.ok declarations => Except.ok (PsSyntaxModule.mk surface.imports declarations)

def psPscv0PrintBinders (proofScript : Bool)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) : Except String String :=
  if proofScript then
    match psPrintProofScriptDeclarationBinders binders with
    | Except.error _ => Except.error "PSCV0-BINDER-PRINT-UNSUPPORTED"
    | Except.ok text => Except.ok text
  else
    match psListMapExcept psPscv0PrintLeanBinder binders with
    | Except.error _ => Except.error "PSCV0-BINDER-PRINT-UNSUPPORTED"
    | Except.ok texts => Except.ok (psPrintLeanSpaceJoinedSuffix texts)

def psPscv0PrintResultType (proofScript : Bool) (type : PsSyntaxTerm) : Except String String :=
  if proofScript then psPscv0PrintTerm true type
  else
    match psPscv0PrintLeanType type with
    | Except.error _ => Except.error "PSCV0-RESULT-TYPE-PRINT-UNSUPPORTED"
    | Except.ok text => Except.ok text

def psPscv0PrintSurfaceDeclaration (proofScript : Bool)
    (surface : PsPscv0SurfaceDeclaration) : Except String String :=
  match surface.declaration with
  | .definition name binders type value _ =>
      match psPscv0PrintBinders proofScript binders with
      | Except.error error => Except.error error
      | Except.ok parameters =>
          match psPscv0PrintResultType proofScript type with
          | Except.error error => Except.error error
          | Except.ok resultType =>
              let body : Except String String :=
                match surface.doBody with
                | none => psPscv0PrintTerm proofScript value
                | some block => psPscv0PrintDoBlock proofScript block;
              match body with
              | Except.error error => Except.error error
              | Except.ok expression =>
                  let keyword := if proofScript then surface.keyword else "def";
                  Except.ok (psPscv0Cat [keyword, " ", psPscv0NameText name,
                    parameters, " : ", resultType, " := ", expression])
  | _ =>
      let printed : Except PsSourcePrintError String :=
        if proofScript then psPrintProofScriptDeclaration surface.declaration
        else psPrintLeanDeclaration surface.declaration;
      match printed with
      | Except.error _ => Except.error "PSCV0-DECLARATION-PRINT-UNSUPPORTED"
      | Except.ok text => Except.ok text

def psPscv0PrintImport (sourceImport : PsSyntaxImport) : String :=
  psPscv0Cat [(if sourceImport.isPublic then "public import " else "import "),
    psPscv0NameText sourceImport.moduleName]

def psPscv0PrintSurfaceModule (proofScript : Bool) (surface : PsPscv0SurfaceModule) : Except String String :=
  if surface.commentTrivia then Except.error "PSCV0-TRIVIA-PRINT-PENDING"
  else
    let printer : PsPscv0SurfaceDeclaration -> Except String String := psPscv0PrintSurfaceDeclaration proofScript;
    match psListMapExcept printer surface.declarations with
    | Except.error error => Except.error error
    | Except.ok declarations =>
        let imports := psListMap psPscv0PrintImport surface.imports;
        let importPrefix := if psListIsEmpty imports then "" else psPscv0Cat [psPrintJoin "\n" imports, "\n\n"];
        Except.ok (psPscv0Cat [importPrefix, psPrintJoin "\n\n" declarations, "\n"])

def psPscv0LoweredSurface (declaration : PsSyntaxDeclaration) : PsPscv0SurfaceDeclaration :=
  PsPscv0SurfaceDeclaration.mk "def" declaration Option.none

def psPscv0LowerToLean (proofScript : Bool) (source : String) : Except String String :=
  match psPscv0ParseSource proofScript source with
  | Except.error error => Except.error error
  | Except.ok surface =>
      match psPscv0LowerModule surface with
      | Except.error error => Except.error error
      | Except.ok sourceModule =>
          let lowered := PsPscv0SurfaceModule.mk "" false false sourceModule.imports
            (psListMap psPscv0LoweredSurface sourceModule.declarations) surface.errorName surface.discardName;
          psPscv0PrintSurfaceModule false lowered

def psPscv0TranslateReadable (sourceIsPs targetIsPs : Bool) (source : String) : Except String String :=
  match psPscv0ParseSource sourceIsPs source with
  | Except.error error => Except.error error
  | Except.ok surface => psPscv0PrintSurfaceModule targetIsPs surface

def psPscv0ReplayOriginal (surface : PsPscv0SurfaceModule) : String := surface.originalSource
