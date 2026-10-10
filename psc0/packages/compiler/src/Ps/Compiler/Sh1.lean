import Ps.Compiler.Api

-- Source-policy evidence is not kernel acceptance or semantic qualification.
-- Inputs are raw, ordered modules from one source edition. Parsed imports are
-- checked before the ordinary preparation API discards import syntax.
-- moduleName is a caller-supplied structured bundle identity, not a parsed
-- identifier or filesystem path. Equality uses exact segments, with no dot or
-- separator normalization. Hosts own canonical path-to-name mapping; actual
-- imports are parsed and must equal an earlier supplied segment list.
structure PsSh1SourceInput where
  moduleName : List String
  source : String

def psSh1SourceInput (moduleName : List String) (source : String) :
    PsSh1SourceInput :=
  PsSh1SourceInput.mk moduleName source

structure PsSh1SourceOptions where
  maxModules : Nat
  maxInputBytes : Nat
  maxSyntaxSteps : Nat
  maxTypeSteps : Nat
  maxTermSteps : Nat

def psSh1SourceOptionsWithLimits
    (maxModules maxInputBytes maxSyntaxSteps maxTypeSteps maxTermSteps : Nat) :
    PsSh1SourceOptions :=
  PsSh1SourceOptions.mk
    maxModules maxInputBytes maxSyntaxSteps maxTypeSteps maxTermSteps

def psSh1DefaultSourceOptions : PsSh1SourceOptions :=
  PsSh1SourceOptions.mk 1024 16777216 5000000 1000000 5000000

structure PsSh1SourceFinding where
  code : String
  detail : String
  moduleName : String
  owner : String
  span : Option PsSourceSpan

inductive PsSh1SourceError where
  | policy (finding : PsSh1SourceFinding)
  | compiler (moduleName : String) (error : PsCompilerError)
  | origin (moduleName : String) (error : PsElabOriginError)

def psSh1SourceFailure
    (code detail moduleName owner : String) (span : Option PsSourceSpan) :
    PsSh1SourceError :=
  PsSh1SourceError.policy
    (PsSh1SourceFinding.mk code detail moduleName owner span)

structure PsSh1SyntaxStats where
  visitedSteps : Nat
  typeSteps : Nat
  termSteps : Nat
  declarationCount : Nat
  theoremCount : Nat

def psSh1EmptySyntaxStats : PsSh1SyntaxStats :=
  PsSh1SyntaxStats.mk 0 0 0 0 0

structure PsSh1SourceReport where
  profile : String
  enforcementVersion : Nat
  sourceKind : PsCompilerSourceKind
  options : PsSh1SourceOptions
  moduleCount : Nat
  sourceBytes : Nat
  inputBytes : Nat
  importCount : Nat
  stats : PsSh1SyntaxStats
  accepted : Bool
  traversalComplete : Bool
  strictSh1Qualified : Bool

structure PsSh1ParsedModule where
  moduleName : List String
  sourceModule : PsSyntaxModule

-- Each record is attached to the actual successful module preparation.
-- coreStart counts preceding actual batch members in the final prepared order.
-- The batch retains containing source spans and the actual normalization plan;
-- this declaration-level association is not an expression preservation proof.
structure PsSh1ModuleOrigin where
  moduleName : List String
  coreStart : Nat
  batches : List PsElabBatchOrigin

structure PsSh1PreparedSources where
  prepared : PsCompilerAdmissionReadyModule
  environment : PsEnvironment
  admissions : String
  parsedModules : List PsSh1ParsedModule
  origins : List PsSh1ModuleOrigin
  report : PsSh1SourceReport

def psSh1NameTextWorker (segments : List String) (prefixText : String) : String :=
  match segments with
  | List.nil => prefixText
  | List.cons segment rest =>
      let next : String :=
        if Nat.beq (String.utf8ByteSize prefixText) 0 then segment
        else String.Internal.append
          (String.Internal.append prefixText ".") segment;
      psSh1NameTextWorker rest next

def psSh1NameText (segments : List String) : String :=
  psSh1NameTextWorker segments ""

def psSh1SegmentsEqual (left : List String) (right : List String) : Bool :=
  match left with
  | List.nil => psListIsEmpty right
  | List.cons head tail =>
      match right with
      | List.nil => false
      | List.cons other rest =>
          if psStringEq head other then psSh1SegmentsEqual tail rest
          else false

def psSh1HasModule (modules : List (List String)) (name : List String) : Bool :=
  match modules with
  | List.nil => false
  | List.cons current rest =>
      if psSh1SegmentsEqual current name then true
      else psSh1HasModule rest name

def psSh1PackageSectionAllowed (sectionName : String) : Bool :=
  if psStringEq sectionName "Bootstrap" then true
  else if psStringEq sectionName "Foundation" then true
  else if psStringEq sectionName "Syntax" then true
  else if psStringEq sectionName "Core" then true
  else if psStringEq sectionName "Environment" then true
  else if psStringEq sectionName "Meta" then true
  else if psStringEq sectionName "Elab" then true
  else if psStringEq sectionName "Bridge" then true
  else if psStringEq sectionName "CompilerIr" then true
  else if psStringEq sectionName "Erasure" then true
  else if psStringEq sectionName "Compiler" then true
  else if psStringEq sectionName "BackendTs" then true
  else false

def psSh1ModuleNameAllowed (segments : List String) : Bool :=
  match segments with
  | List.nil => false
  | List.cons rootName rest =>
      if psStringEq rootName "Ps" then
        match rest with
        | List.nil => false
        | List.cons sectionName tail =>
            if psListIsEmpty tail then false
            else psSh1PackageSectionAllowed sectionName
      else false

-- Name and import scans have their own maxSyntaxSteps allowance. AST task,
-- type-position and term-position counts are aggregate across the whole bundle.
-- These are bounded work scopes, not a global wall-clock or heap guarantee.
def psSh1NameBytesWorker
    (maxBytes fuel : Nat) (segments : List String) (bytes : Nat) :
    Except PsSh1SourceError Nat :=
  match fuel with
  | Nat.zero =>
      if psListIsEmpty segments then Except.ok bytes
      else Except.error
        (psSh1SourceFailure "source-name-limit" "module name traversal exhausted"
          "<input>" "" Option.none)
  | Nat.succ remaining =>
      match segments with
      | List.nil => Except.ok bytes
      | List.cons segment rest =>
          let size : Nat := String.utf8ByteSize segment;
          if Nat.beq size 0 then
            Except.error
              (psSh1SourceFailure "source-module-name" "empty module name segment"
                "<input>" "" Option.none)
          else
            let next : Nat := Nat.add bytes size;
            if Nat.ble next maxBytes then
              psSh1NameBytesWorker maxBytes remaining rest next
            else Except.error
              (psSh1SourceFailure "source-input-byte-limit" "module name exceeds input limit"
                "<input>" "" Option.none)

def psSh1CollectDoOrigins
    (tokens : List PsToken) (originsRev : List PsSourceSpan) : List PsSourceSpan :=
  match tokens with
  | List.nil => originsRev
  | List.cons token rest =>
      let next : List PsSourceSpan :=
        if psTokenKindEq token.kind PsTokenKind.identifier then
          if psStringEq token.text "do" then
            List.cons token.span originsRev
          else originsRev
        else originsRev;
      psSh1CollectDoOrigins rest next

def psSh1FindOrigin (origins : List PsSourceSpan) (offset : Nat) : Option PsSourceSpan :=
  match origins with
  | List.nil => Option.none
  | List.cons current rest =>
      if Nat.beq current.start.byteOffset offset then Option.some current
      else psSh1FindOrigin rest offset

def psSh1IsCompilerDoName (segments : List String) : Bool :=
  match segments with
  | List.nil => false
  | List.cons first rest =>
      if psListIsEmpty rest then
        if psStringEq first "compilerPure" then true
        else psStringEq first "compilerBind"
      else false

-- The owned Lean parser gives a lowered do reference its originating do span.
-- Match that provenance, not arbitrary occurrences of the word or helper name.
-- Qualified field names, binder names, comments, strings and ordinary calls do
-- not meet both conditions. The current PS frontend already refuses do syntax.
def psSh1ReferenceFromDo
    (origins : List PsSourceSpan) (name : PsSyntaxName) : Option PsSourceSpan :=
  if psSh1IsCompilerDoName name.segments then
    psSh1FindOrigin origins name.span.start.byteOffset
  else Option.none

structure PsSh1ParsedSource where
  sourceModule : PsSyntaxModule
  doOrigins : List PsSourceSpan

def psSh1LexSource (sourceKind : PsCompilerSourceKind) (source : String) :
    Except PsCompilerError (List PsToken) :=
  match sourceKind with
  | PsCompilerSourceKind.lean =>
      match psLex source with
      | Except.error error =>
          Except.error (PsCompilerError.leanFrontend (PsLeanFrontendError.lex error))
      | Except.ok tokens => Except.ok tokens
  | PsCompilerSourceKind.proofScript =>
      match psLexProofScript source with
      | Except.error error =>
          Except.error
            (PsCompilerError.proofScriptFrontend (PsProofScriptFrontendError.lex error))
      | Except.ok tokens => Except.ok tokens

def psSh1ParseTokens (sourceKind : PsCompilerSourceKind) (tokens : List PsToken) :
    Except PsCompilerError PsSyntaxModule :=
  match sourceKind with
  | PsCompilerSourceKind.lean =>
      match psParseLeanTokens tokens with
      | Except.error error =>
          Except.error (PsCompilerError.leanFrontend (PsLeanFrontendError.parse error))
      | Except.ok sourceModule => Except.ok sourceModule
  | PsCompilerSourceKind.proofScript =>
      match psParseProofScriptTokens tokens with
      | Except.error error =>
          Except.error
            (PsCompilerError.proofScriptFrontend (PsProofScriptFrontendError.parse error))
      | Except.ok sourceModule => Except.ok sourceModule

def psSh1ParseSource (sourceKind : PsCompilerSourceKind) (source : String) :
    Except PsCompilerError PsSh1ParsedSource :=
  match psSh1LexSource sourceKind source with
  | Except.error error => Except.error error
  | Except.ok tokens =>
      match psSh1ParseTokens sourceKind tokens with
      | Except.error error => Except.error error
      | Except.ok sourceModule =>
          Except.ok
            (PsSh1ParsedSource.mk sourceModule (psSh1CollectDoOrigins tokens List.nil))

def psSh1CheckImports
    (moduleName : String) (loaded : List (List String)) (fuel : Nat)
    (imports : List PsSyntaxImport) (count : Nat) :
    Except PsSh1SourceError Nat :=
  match fuel with
  | Nat.zero =>
      if psListIsEmpty imports then Except.ok count
      else Except.error
        (psSh1SourceFailure "source-import-limit" "import traversal exhausted"
          moduleName "" Option.none)
  | Nat.succ remaining =>
      match imports with
      | List.nil => Except.ok count
      | List.cons sourceImport rest =>
          let name : List String := sourceImport.moduleName.segments;
          if psSh1ModuleNameAllowed name then
            if psSh1HasModule loaded name then
              psSh1CheckImports moduleName loaded remaining rest (Nat.succ count)
            else Except.error
              (psSh1SourceFailure "source-import-unresolved"
                (psSh1NameText name) moduleName "" (Option.some sourceImport.span))
          else Except.error
            (psSh1SourceFailure "source-import-package"
              (psSh1NameText name) moduleName "" (Option.some sourceImport.span))

inductive PsSh1SyntaxRegion where
  | type
  | term

inductive PsSh1SyntaxTask where
  | declarations (sources : List PsSyntaxDeclaration)
  | declaration (source : PsSyntaxDeclaration)
  | term (owner : String) (region : PsSh1SyntaxRegion) (value : PsSyntaxTerm)
  | terms (owner : String) (region : PsSh1SyntaxRegion) (values : List PsSyntaxTerm)
  | binders (owner : String) (values : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
  | fields (owner : String) (region : PsSh1SyntaxRegion)
      (values : List (Prod PsSyntaxName PsSyntaxTerm))
  | alternatives (owner : String) (region : PsSh1SyntaxRegion)
      (values : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))
  | constructors (owner : String) (values : List PsSyntaxInductiveConstructor)

structure PsSh1SyntaxState where
  tasks : List PsSh1SyntaxTask
  stats : PsSh1SyntaxStats

def psSh1SyntaxSchedule
    (state : PsSh1SyntaxState) (tasks : List PsSh1SyntaxTask) : PsSh1SyntaxState :=
  PsSh1SyntaxState.mk (psListAppend tasks state.tasks) state.stats

def psSh1SyntaxSetStats
    (state : PsSh1SyntaxState) (stats : PsSh1SyntaxStats) : PsSh1SyntaxState :=
  PsSh1SyntaxState.mk state.tasks stats

def psSh1CountTerm
    (options : PsSh1SourceOptions) (moduleName owner : String)
    (region : PsSh1SyntaxRegion) (span : PsSourceSpan)
    (state : PsSh1SyntaxState) : Except PsSh1SourceError PsSh1SyntaxState :=
  let stats : PsSh1SyntaxStats := state.stats;
  match region with
  | PsSh1SyntaxRegion.type =>
      if Nat.blt stats.typeSteps options.maxTypeSteps then
        Except.ok (psSh1SyntaxSetStats state
          (PsSh1SyntaxStats.mk stats.visitedSteps (Nat.succ stats.typeSteps)
            stats.termSteps stats.declarationCount stats.theoremCount))
      else Except.error
        (psSh1SourceFailure "source-type-limit" "type-position traversal exhausted"
          moduleName owner (Option.some span))
  | PsSh1SyntaxRegion.term =>
      if Nat.blt stats.termSteps options.maxTermSteps then
        Except.ok (psSh1SyntaxSetStats state
          (PsSh1SyntaxStats.mk stats.visitedSteps stats.typeSteps
            (Nat.succ stats.termSteps) stats.declarationCount stats.theoremCount))
      else Except.error
        (psSh1SourceFailure "source-term-limit" "term-position traversal exhausted"
          moduleName owner (Option.some span))

-- Every source term constructor is named here. Typed recursion, inference,
-- rank-1 runtime use and layouts remain the actual elaborator/checker's work.
def psSh1SyntaxTermStep
    (moduleName owner : String) (origins : List PsSourceSpan)
    (region : PsSh1SyntaxRegion) (term : PsSyntaxTerm)
    (state : PsSh1SyntaxState) : Except PsSh1SourceError PsSh1SyntaxState :=
  match term with
  | PsSyntaxTerm.reference name =>
      match psSh1ReferenceFromDo origins name with
      | Option.some origin =>
          Except.error
            (psSh1SourceFailure "source-do-unsupported"
              "do semantics are outside the enabled source profile"
              moduleName owner (Option.some origin))
      | Option.none => Except.ok state
  | PsSyntaxTerm.natural _ _ => Except.ok state
  | PsSyntaxTerm.string _ _ => Except.ok state
  | PsSyntaxTerm.character _ _ => Except.ok state
  | PsSyntaxTerm.bool _ _ => Except.ok state
  | PsSyntaxTerm.unit _ => Except.ok state
  | PsSyntaxTerm.record fields _ =>
      Except.ok (psSh1SyntaxSchedule state [PsSh1SyntaxTask.fields owner region fields])
  | PsSyntaxTerm.app fn args _ =>
      Except.ok (psSh1SyntaxSchedule state
        [PsSh1SyntaxTask.term owner region fn, PsSh1SyntaxTask.terms owner region args])
  | PsSyntaxTerm.lambda binders body _ =>
      Except.ok (psSh1SyntaxSchedule state
        [PsSh1SyntaxTask.binders owner binders, PsSh1SyntaxTask.term owner region body])
  | PsSyntaxTerm.forallE binders body _ =>
      Except.ok (psSh1SyntaxSchedule state
        [PsSh1SyntaxTask.binders owner binders,
         PsSh1SyntaxTask.term owner PsSh1SyntaxRegion.type body])
  | PsSyntaxTerm.letE _ type value body _ =>
      let bodies : List PsSh1SyntaxTask :=
        [PsSh1SyntaxTask.term owner region value, PsSh1SyntaxTask.term owner region body];
      match type with
      | Option.none => Except.ok (psSh1SyntaxSchedule state bodies)
      | Option.some annotation =>
          Except.ok (psSh1SyntaxSchedule state
            (List.cons (PsSh1SyntaxTask.term owner PsSh1SyntaxRegion.type annotation) bodies))
  | PsSyntaxTerm.ifE condition thenBranch elseBranch _ =>
      Except.ok (psSh1SyntaxSchedule state
        [PsSh1SyntaxTask.term owner region condition,
         PsSh1SyntaxTask.term owner region thenBranch,
         PsSh1SyntaxTask.term owner region elseBranch])
  | PsSyntaxTerm.matchE scrutinee alternatives _ =>
      Except.ok (psSh1SyntaxSchedule state
        [PsSh1SyntaxTask.term owner region scrutinee,
         PsSh1SyntaxTask.alternatives owner region alternatives])

def psSh1CountDeclaration (state : PsSh1SyntaxState) (isTheorem : Bool) :
    PsSh1SyntaxState :=
  let stats : PsSh1SyntaxStats := state.stats;
  let theoremCount : Nat :=
    if isTheorem then Nat.succ stats.theoremCount else stats.theoremCount;
  psSh1SyntaxSetStats state
    (PsSh1SyntaxStats.mk stats.visitedSteps stats.typeSteps stats.termSteps
      (Nat.succ stats.declarationCount) theoremCount)

def psSh1DeclarationTasks
    (name : PsSyntaxName) (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (type value : PsSyntaxTerm) : List PsSh1SyntaxTask :=
  let owner : String := psSh1NameText name.segments;
  [PsSh1SyntaxTask.binders owner binders,
   PsSh1SyntaxTask.term owner PsSh1SyntaxRegion.type type,
   PsSh1SyntaxTask.term owner PsSh1SyntaxRegion.term value]

-- Erasure gives these exact source symbols intrinsic meaning before ordinary
-- declaration dispatch. The source-owned lane reserves all of them; a missing
-- prelude symbol is not permission to define an unrelated implementation.
-- The finite inventory is audited against psErasePrimitiveApplication.
def psSh1PrimitiveDeclarationNameReserved (text : String) : Bool :=
  if psStringEq text "Prod.fst" then true
  else if psStringEq text "Prod.snd" then true
  else if psStringEq text "Int.ofNat" then true
  else if psStringEq text "Int.repr" then true
  else if psStringEq text "Int.negSucc" then true
  else if psStringEq text "Int.neg" then true
  else if psStringEq text "Int.add" then true
  else if psStringEq text "Int.sub" then true
  else if psStringEq text "Int.mul" then true
  else if psStringEq text "Nat.succ" then true
  else if psStringEq text "Nat.add" then true
  else if psStringEq text "Nat.sub" then true
  else if psStringEq text "Nat.mul" then true
  else if psStringEq text "Nat.div" then true
  else if psStringEq text "Nat.mod" then true
  else if psStringEq text "Nat.beq" then true
  else if psStringEq text "Nat.ble" then true
  else if psStringEq text "Nat.blt" then true
  else if psStringEq text "Bool.and" then true
  else if psStringEq text "Bool.or" then true
  else if psStringEq text "Bool.not" then true
  else if psStringEq text "Char.ofNat" then true
  else if psStringEq text "Char.toNat" then true
  else if psStringEq text "String.Pos.Raw.mk" then true
  else if psStringEq text "String.Pos.Raw.byteIdx" then true
  else if psStringEq text "String.push" then true
  else if psStringEq text "String.singleton" then true
  else if psStringEq text "String.Internal.length" then true
  else if psStringEq text "String.Internal.append" then true
  else if psStringEq text "String.utf8ByteSize" then true
  else if psStringEq text "String.Internal.next" then true
  else if psStringEq text "String.Internal.get" then true
  else if psStringEq text "String.Internal.atEnd" then true
  else if psStringEq text "String.Internal.extract" then true
  else if psStringEq text "Array.emptyWithCapacity" then true
  else if psStringEq text "Array.size" then true
  else if psStringEq text "Array.push" then true
  else if psStringEq text "Array.getInternal" then true
  else if psStringEq text "Array.getD" then true
  else if psStringEq text "Array.set" then true
  else if psStringEq text "Array.setIfInBounds" then true
  else if psStringEq text "Array.map" then true
  else psStringEq text "Array.foldl"

def psSh1SourceDeclarationName (source : PsSyntaxDeclaration) : PsSyntaxName :=
  match source with
  | PsSyntaxDeclaration.definition name _ _ _ _ => name
  | PsSyntaxDeclaration.partialDefinition name _ _ _ _ => name
  | PsSyntaxDeclaration.theoremDecl name _ _ _ _ => name
  | PsSyntaxDeclaration.inductiveDecl name _ _ _ _ => name
  | PsSyntaxDeclaration.structureDecl name _ _ _ => name


-- General partial definitions are excluded. Theorems use the existing
-- proof/type-erasure preparation path; they are not silently banned or declared
-- kernel-checked.
-- Axiom, opaque, class/instance, macro and extension commands have no declaration
-- constructor in this source AST: the real parser refuses them before this walk.
def psSh1SyntaxDeclarationBodyStep
    (moduleName : String) (source : PsSyntaxDeclaration) (state : PsSh1SyntaxState) :
    Except PsSh1SourceError PsSh1SyntaxState :=
  match source with
  | PsSyntaxDeclaration.definition name binders type value _ =>
      Except.ok (psSh1SyntaxSchedule (psSh1CountDeclaration state false)
        (psSh1DeclarationTasks name binders type value))
  | PsSyntaxDeclaration.partialDefinition name _ _ _ span =>
      Except.error
        (psSh1SourceFailure "source-partial-definition"
          "general partial definitions are outside the enabled source profile"
          moduleName (psSh1NameText name.segments) (Option.some span))
  | PsSyntaxDeclaration.theoremDecl name binders type value _ =>
      Except.ok (psSh1SyntaxSchedule (psSh1CountDeclaration state true)
        (psSh1DeclarationTasks name binders type value))
  | PsSyntaxDeclaration.inductiveDecl name params resultType constructors _ =>
      let owner : String := psSh1NameText name.segments;
      let tail : List PsSh1SyntaxTask := [PsSh1SyntaxTask.constructors owner constructors];
      let withResult : List PsSh1SyntaxTask :=
        match resultType with
        | Option.none => tail
        | Option.some type =>
            List.cons (PsSh1SyntaxTask.term owner PsSh1SyntaxRegion.type type) tail;
      Except.ok (psSh1SyntaxSchedule (psSh1CountDeclaration state false)
        (List.cons (PsSh1SyntaxTask.binders owner params) withResult))
  | PsSyntaxDeclaration.structureDecl name params fields _ =>
      let owner : String := psSh1NameText name.segments;
      Except.ok (psSh1SyntaxSchedule (psSh1CountDeclaration state false)
        [PsSh1SyntaxTask.binders owner params, PsSh1SyntaxTask.binders owner fields])


def psSh1SyntaxDeclarationStep
    (moduleName : String) (source : PsSyntaxDeclaration) (state : PsSh1SyntaxState) :
    Except PsSh1SourceError PsSh1SyntaxState :=
  let name : PsSyntaxName := psSh1SourceDeclarationName source;
  let text : String := psSh1NameText name.segments;
  if psSh1PrimitiveDeclarationNameReserved text then
    Except.error
      (psSh1SourceFailure "source-intrinsic-name-reserved"
        "source declarations cannot redefine a reserved erasure intrinsic symbol"
        moduleName text (Option.some name.span))
  else if psStringEq text "String.Pos.Raw" then
    Except.error
      (psSh1SourceFailure "source-builtin-type-name-reserved"
        "source declarations cannot redefine the fixed raw string position type"
        moduleName text (Option.some name.span))
  else psSh1SyntaxDeclarationBodyStep moduleName source state

def psSh1PatternBody
    (owner : String) (region : PsSh1SyntaxRegion)
    (pattern : PsSyntaxPattern) (body : PsSyntaxTerm) : PsSh1SyntaxTask :=
  match pattern with
  | PsSyntaxPattern.bool _ _ => PsSh1SyntaxTask.term owner region body
  | PsSyntaxPattern.wildcard _ => PsSh1SyntaxTask.term owner region body
  | PsSyntaxPattern.constructor _ _ _ => PsSh1SyntaxTask.term owner region body

def psSh1BinderType (owner : String)
    (binder : Prod PsSyntaxBinderHead PsSyntaxTerm) : PsSh1SyntaxTask :=
  match binder.fst.kind with
  | PsSyntaxBinderKind.explicit =>
      PsSh1SyntaxTask.term owner PsSh1SyntaxRegion.type binder.snd
  | PsSyntaxBinderKind.implicit =>
      PsSh1SyntaxTask.term owner PsSh1SyntaxRegion.type binder.snd
  | PsSyntaxBinderKind.strictImplicit =>
      PsSh1SyntaxTask.term owner PsSh1SyntaxRegion.type binder.snd
  | PsSyntaxBinderKind.instanceImplicit =>
      PsSh1SyntaxTask.term owner PsSh1SyntaxRegion.type binder.snd

def psSh1SyntaxStep
    (options : PsSh1SourceOptions) (moduleName : String) (origins : List PsSourceSpan)
    (task : PsSh1SyntaxTask) (state : PsSh1SyntaxState) :
    Except PsSh1SourceError PsSh1SyntaxState :=
  match task with
  | PsSh1SyntaxTask.declarations sources =>
      match sources with
      | List.nil => Except.ok state
      | List.cons source rest =>
          Except.ok (psSh1SyntaxSchedule state
            [PsSh1SyntaxTask.declaration source, PsSh1SyntaxTask.declarations rest])
  | PsSh1SyntaxTask.declaration source =>
      psSh1SyntaxDeclarationStep moduleName source state
  | PsSh1SyntaxTask.term owner region term =>
      match psSh1CountTerm options moduleName owner region (psSyntaxTermSpan term) state with
      | Except.error error => Except.error error
      | Except.ok counted => psSh1SyntaxTermStep moduleName owner origins region term counted
  | PsSh1SyntaxTask.terms owner region values =>
      match values with
      | List.nil => Except.ok state
      | List.cons value rest =>
          Except.ok (psSh1SyntaxSchedule state
            [PsSh1SyntaxTask.term owner region value, PsSh1SyntaxTask.terms owner region rest])
  | PsSh1SyntaxTask.binders owner values =>
      match values with
      | List.nil => Except.ok state
      | List.cons binder rest =>
          Except.ok (psSh1SyntaxSchedule state
            [psSh1BinderType owner binder, PsSh1SyntaxTask.binders owner rest])
  | PsSh1SyntaxTask.fields owner region values =>
      match values with
      | List.nil => Except.ok state
      | List.cons field rest =>
          Except.ok (psSh1SyntaxSchedule state
            [PsSh1SyntaxTask.term owner region field.snd, PsSh1SyntaxTask.fields owner region rest])
  | PsSh1SyntaxTask.alternatives owner region values =>
      match values with
      | List.nil => Except.ok state
      | List.cons alternative rest =>
          Except.ok (psSh1SyntaxSchedule state
            [psSh1PatternBody owner region alternative.fst alternative.snd.fst,
             PsSh1SyntaxTask.alternatives owner region rest])
  | PsSh1SyntaxTask.constructors owner values =>
      match values with
      | List.nil => Except.ok state
      | List.cons ctorInfo rest =>
          Except.ok (psSh1SyntaxSchedule state
            [PsSh1SyntaxTask.binders owner ctorInfo.fields,
             PsSh1SyntaxTask.constructors owner rest])

def psSh1SyntaxRun
    (options : PsSh1SourceOptions) (moduleName : String) (origins : List PsSourceSpan)
    (fuel : Nat) (state : PsSh1SyntaxState) :
    Except PsSh1SourceError PsSh1SyntaxStats :=
  match fuel with
  | Nat.zero =>
      if psListIsEmpty state.tasks then Except.ok state.stats
      else Except.error
        (psSh1SourceFailure "source-syntax-limit" "syntax task traversal exhausted"
          moduleName "" Option.none)
  | Nat.succ remaining =>
      match state.tasks with
      | List.nil => Except.ok state.stats
      | List.cons task rest =>
          let stats : PsSh1SyntaxStats := state.stats;
          let next : PsSh1SyntaxState := PsSh1SyntaxState.mk rest
            (PsSh1SyntaxStats.mk (Nat.succ stats.visitedSteps) stats.typeSteps
              stats.termSteps stats.declarationCount stats.theoremCount);
          match psSh1SyntaxStep options moduleName origins task next with
          | Except.error error => Except.error error
          | Except.ok stepped => psSh1SyntaxRun options moduleName origins remaining stepped

def psSh1OriginCoreCount
    (origins : List PsElabBatchOrigin) (count : Nat) : Nat :=
  match origins with
  | List.nil => count
  | List.cons origin rest =>
      psSh1OriginCoreCount rest (Nat.add count (psListLength origin.members))

structure PsSh1PreparationState where
  preparation : PsCompilerPreparationState
  modulesRev : List (List String)
  parsedRev : List PsSh1ParsedModule
  originsRev : List PsSh1ModuleOrigin
  coreCount : Nat
  moduleCount : Nat
  sourceBytes : Nat
  inputBytes : Nat
  importCount : Nat
  stats : PsSh1SyntaxStats

def psSh1PrepareModule
    (options : PsSh1SourceOptions) (input : PsSh1SourceInput)
    (state : PsSh1PreparationState) : Except PsSh1SourceError PsSh1PreparationState :=
  if Nat.blt state.moduleCount options.maxModules then
    match psSh1NameBytesWorker options.maxInputBytes options.maxSyntaxSteps input.moduleName 0 with
    | Except.error error => Except.error error
    | Except.ok nameBytes =>
        let moduleName : String := psSh1NameText input.moduleName;
        if psSh1ModuleNameAllowed input.moduleName then
          if psSh1HasModule state.modulesRev input.moduleName then
            Except.error
              (psSh1SourceFailure "source-module-duplicate" moduleName moduleName "" Option.none)
          else
            let sourceBytes : Nat := String.utf8ByteSize input.source;
            let inputBytes : Nat := Nat.add state.inputBytes (Nat.add nameBytes sourceBytes);
            if Nat.ble inputBytes options.maxInputBytes then
              match psSh1ParseSource state.preparation.sourceKind input.source with
              | Except.error error => Except.error (PsSh1SourceError.compiler moduleName error)
              | Except.ok parsed =>
                  match psSh1CheckImports moduleName state.modulesRev options.maxSyntaxSteps
                      parsed.sourceModule.imports 0 with
                  | Except.error error => Except.error error
                  | Except.ok importCount =>
                      let tasks : List PsSh1SyntaxTask :=
                        [PsSh1SyntaxTask.declarations parsed.sourceModule.declarations];
                      match psSh1SyntaxRun options moduleName parsed.doOrigins
                          (Nat.sub options.maxSyntaxSteps state.stats.visitedSteps)
                          (PsSh1SyntaxState.mk tasks state.stats) with
                      | Except.error error => Except.error error
                      | Except.ok stats =>
                          match psCompilerPreparationStepParsedWithOrigins
                              state.preparation parsed.sourceModule with
                          | Except.error error =>
                              Except.error (PsSh1SourceError.origin moduleName error)
                          | Except.ok result =>
                              let origin : PsSh1ModuleOrigin :=
                                PsSh1ModuleOrigin.mk
                                  input.moduleName state.coreCount result.origins;
                              Except.ok (PsSh1PreparationState.mk result.state
                                (List.cons input.moduleName state.modulesRev)
                                (List.cons
                                  (PsSh1ParsedModule.mk input.moduleName parsed.sourceModule)
                                  state.parsedRev)
                                (List.cons origin state.originsRev)
                                (psSh1OriginCoreCount result.origins state.coreCount)
                                (Nat.succ state.moduleCount)
                                (Nat.add state.sourceBytes sourceBytes)
                                inputBytes (Nat.add state.importCount importCount) stats)
            else Except.error
              (psSh1SourceFailure "source-input-byte-limit" "raw source bundle exceeds input limit"
                moduleName "" Option.none)
        else Except.error
          (psSh1SourceFailure "source-module-package" moduleName moduleName "" Option.none)
  else Except.error
    (psSh1SourceFailure "source-module-limit" "module count exceeds limit"
      "<input>" "" Option.none)

def psSh1PrepareSourcesWorker
    (inputs : List PsSh1SourceInput) (options : PsSh1SourceOptions)
    (state : PsSh1PreparationState) : Except PsSh1SourceError PsSh1PreparationState :=
  match inputs with
  | List.nil => Except.ok state
  | List.cons input rest =>
      match psSh1PrepareModule options input state with
      | Except.error error => Except.error error
      | Except.ok next => psSh1PrepareSourcesWorker rest options next

-- This source entry owns parsing and preparation. The returned data is useful
-- for diagnostics and composition, not an unforgeable transferable certificate.
-- Strict-labelled emission must enter through the corresponding source API.
def psCompilerSh1PrepareSources
    (options : PsSh1SourceOptions) (sourceKind : PsCompilerSourceKind)
    (inputs : List PsSh1SourceInput) : Except PsSh1SourceError PsSh1PreparedSources :=
  if psListIsEmpty inputs then
    Except.error
      (psSh1SourceFailure "source-empty-bundle" "at least one source module is required"
        "<input>" "" Option.none)
  else
    let initial : PsSh1PreparationState := PsSh1PreparationState.mk
      (psCompilerPreparationStart sourceKind) List.nil List.nil List.nil
      0 0 0 0 0 psSh1EmptySyntaxStats;
    match psSh1PrepareSourcesWorker inputs options initial with
    | Except.error error => Except.error error
    | Except.ok state =>
        match psCompilerPreparationFinishWithOutput state.preparation with
        | Except.error error => Except.error (PsSh1SourceError.compiler "<bundle>" error)
        | Except.ok output =>
            let report : PsSh1SourceReport := PsSh1SourceReport.mk
              "PSC0-SH/1" 1 sourceKind options state.moduleCount state.sourceBytes
              state.inputBytes state.importCount state.stats true true false;
            Except.ok (PsSh1PreparedSources.mk
              output.prepared output.environment output.admissions
              (psListReverse state.parsedRev) (psListReverse state.originsRev) report)
