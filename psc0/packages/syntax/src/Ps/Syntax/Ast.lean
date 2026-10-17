import Ps.Foundation.Source

structure PsSyntaxName where
  segments : List String
  span : PsSourceSpan

inductive PsSyntaxBinderKind where
  | explicit
  | implicit
  | strictImplicit
  | instanceImplicit

-- A nonempty native group shares one annotation. The first name preserves
-- unary construction; moreNames retains the group boundary until elaboration.
structure PsSyntaxBinderHead where
  group ::
  name : PsSyntaxName
  kind : PsSyntaxBinderKind
  span : PsSourceSpan
  moreNames : List PsSyntaxName := []

def PsSyntaxBinderHead.mk (name : PsSyntaxName) (kind : PsSyntaxBinderKind)
    (span : PsSourceSpan) : PsSyntaxBinderHead :=
  .group name kind span []

def psSyntaxBinderNames (head : PsSyntaxBinderHead) : List PsSyntaxName :=
  head.name :: head.moreNames

def psSyntaxBinderSelectNames (head : PsSyntaxBinderHead)
    (keep : PsSyntaxName → Bool) : Option PsSyntaxBinderHead :=
  match (psSyntaxBinderNames head).filter keep with
  | [] => none
  | name :: moreNames => some { head with name, moreNames }

def psSyntaxAnonymousInstanceBinder (head : PsSyntaxBinderHead) : Bool :=
  match head.kind, head.name.segments with
  | .instanceImplicit, [name] => head.moreNames.isEmpty && name.startsWith "$psc0Inst"
  | _, _ => false

inductive PsSyntaxPattern where
  | natural (value : Nat) (span : PsSourceSpan)
  | bool (value : Bool) (span : PsSourceSpan)
  | wildcard (span : PsSourceSpan)
  | variable (name : PsSyntaxName)
  | ctor (name : PsSyntaxName) (fields : List PsSyntaxPattern) (span : PsSourceSpan)

-- Construction helper for existing flat parser clients; the stored tree is
-- uniformly recursive.
def PsSyntaxPattern.constructor (name : PsSyntaxName) (binders : List PsSyntaxName)
    (span : PsSourceSpan) : PsSyntaxPattern :=
  .ctor name (binders.map fun name =>
    if name.segments == ["_"] then .wildcard name.span else .variable name) span

def psSyntaxPatternNames (fuel : Nat) (pattern : PsSyntaxPattern) : List PsSyntaxName :=
  match fuel with
  | 0 => []
  | fuel + 1 => match pattern with
    | .variable name => [name]
    | .ctor _ fields _ => fields.flatMap (psSyntaxPatternNames fuel)
    | _ => []

-- Universe syntax has its own category; its names are never term variables.
inductive PsSyntaxLevel where
  | number (value : Nat)
  | name (value : String)
  | hole
  | offset (base : PsSyntaxLevel) (amount : Nat)
  | max (left right : PsSyntaxLevel)
  | imax (left right : PsSyntaxLevel)

structure PsSyntaxProofScope where
  namePrefix : List String := []
  opened : List (List String) := []
  -- Module-owned private names are resolved within tactic terms, never
  -- serialized as public names or made visible to external importers.
  privateAliases : List (List String × List String) := []
  -- Delayed proof terms resolve a mutual peer to its checked local alias,
  -- which already supplies the common captured telescope with all binder kinds.
  mutualAliases : List (List String × List String) := []
  -- Flat where locals shadow the enclosing section/parameter scope, while
  -- bindings introduced inside a helper or proof retain ordinary precedence.
  localAliases : List (String × List String) := []

-- Operator intent survives parsing so elaboration can join operand types before
-- inserting coercions. Ordinary named calls keep their ordinary semantics.
inductive PsSyntaxOperatorKind where
  | unary | binary | rightAction | relation | booleanRelation
  deriving BEq

mutual
inductive PsSyntaxTerm where
  | doE (items : List PsSyntaxDoItem) (span : PsSourceSpan)
  | byE (tactics : List PsSyntaxTactic) (scope : PsSyntaxProofScope) (span : PsSourceSpan)
  | sortE (isType : Bool) (level : PsSyntaxLevel) (span : PsSourceSpan)
  | reference (name : PsSyntaxName)
  | hole (span : PsSourceSpan)
  -- Declaration-only absence of a result annotation. Keep it distinct from
  -- an explicit `_`, so source printing never turns inference into a header.
  | omittedType (span : PsSourceSpan)
  -- Binder-only source annotation; checked as Lean's reducible optParam type.
  | optionalType (type value : PsSyntaxTerm) (span : PsSourceSpan)
  | ascription (value type : PsSyntaxTerm) (span : PsSourceSpan)
  -- Adjacent calls retain labels and the empty-invocation request until elaboration.
  | call (fn : PsSyntaxTerm)
      (args : List (Prod (Option PsSyntaxName) PsSyntaxTerm)) (span : PsSourceSpan)
  | operatorE (kind : PsSyntaxOperatorKind) (name : PsSyntaxName)
      (spelling : String) (arguments : List PsSyntaxTerm) (span : PsSourceSpan)
  | natural (text : String) (span : PsSourceSpan)
  | scientific (text : String) (span : PsSourceSpan)
  | string (text : String) (span : PsSourceSpan)
  | character (text : String) (span : PsSourceSpan)
  | bool (value : Bool) (span : PsSourceSpan)
  | unit (span : PsSourceSpan)
  | record
      (fields : List (Prod PsSyntaxName PsSyntaxTerm))
      (span : PsSourceSpan)
  | recordUpdate (source : PsSyntaxTerm)
      (fields : List (PsSyntaxName × PsSyntaxTerm)) (span : PsSourceSpan)
  | app (fn : PsSyntaxTerm) (args : List PsSyntaxTerm) (span : PsSourceSpan)
  | lambda
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (body : PsSyntaxTerm)
      (span : PsSourceSpan)
  | forallE
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (body : PsSyntaxTerm)
      (span : PsSourceSpan)
  | haveE (name : PsSyntaxName) (type : Option PsSyntaxTerm)
      (value body : PsSyntaxTerm) (span : PsSourceSpan)
  | letE
      (name : PsSyntaxName)
      (type : Option PsSyntaxTerm)
      (value : PsSyntaxTerm)
      (body : PsSyntaxTerm)
      (span : PsSourceSpan)
  | ifE
      (proofName : Option PsSyntaxName)
      (condition : PsSyntaxTerm)
      (thenBranch : PsSyntaxTerm)
      (elseBranch : PsSyntaxTerm)
      (span : PsSourceSpan)
  | matchMany
      (scrutinees : List PsSyntaxTerm)
      (alternatives : List (List PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))
      (span : PsSourceSpan)

-- Do is source control syntax. Effect selection belongs to typed elaboration.
inductive PsSyntaxDoItem where
  | binding (pattern : PsSyntaxPattern) (type : Option PsSyntaxTerm)
      (value : PsSyntaxTerm) (monadic : Bool) (span : PsSourceSpan)
  | action (value : PsSyntaxTerm) (span : PsSourceSpan)
  | returnValue (value : PsSyntaxTerm) (span : PsSourceSpan)
  | conditional (name : Option PsSyntaxName) (condition : PsSyntaxTerm)
      (yes no : List PsSyntaxDoItem) (span : PsSourceSpan)
  | conditionalPattern (pattern : PsSyntaxPattern) (value : PsSyntaxTerm)
      (yes no : List PsSyntaxDoItem) (span : PsSourceSpan)

inductive PsSyntaxTactic where
  | exactE (value : PsSyntaxTerm) (refine : Bool) (span : PsSourceSpan)
  | applyE (value : PsSyntaxTerm) (span : PsSourceSpan)
  | localE (name : PsSyntaxName) (type : Option PsSyntaxTerm) (value : PsSyntaxTerm)
      (reducible : Bool) (span : PsSourceSpan)
  | change (type : PsSyntaxTerm) (select : Bool) (span : PsSourceSpan)
  | eliminate (value : PsSyntaxTerm) (induction : Bool) (span : PsSourceSpan)
  | caseE (tag : Option PsSyntaxName) (names : List PsSyntaxName)
      (body : List PsSyntaxTactic) (span : PsSourceSpan)
  | intro (names : List PsSyntaxName) (span : PsSourceSpan)
  | assumption (span : PsSourceSpan)
  -- Compiler-generated index side-condition solver. It never introduces
  -- axioms, guesses inequalities or leaves unsolved proof metavariables.
  | indexValidity (span : PsSourceSpan)
  | reflexivity (span : PsSourceSpan)
  | constructor (span : PsSourceSpan)
  | focus (body : List PsSyntaxTactic) (mustClose : Bool) (span : PsSourceSpan)
  | each (body : List PsSyntaxTactic) (any : Bool) (span : PsSourceSpan)
end

def psSyntaxDoTerms (fuel : Nat) (item : PsSyntaxDoItem) : List PsSyntaxTerm :=
  match fuel with
  | 0 => []
  | fuel + 1 => match item with
    | .binding _ type value _ _ => type.toList ++ [value]
    | .action value _ | .returnValue value _ => [value]
    | .conditional _ condition yes no _ | .conditionalPattern _ condition yes no _ =>
      condition :: (yes ++ no).flatMap (psSyntaxDoTerms fuel)

def psSyntaxDoSpan : PsSyntaxDoItem → PsSourceSpan
  | .binding _ _ _ _ span | .action _ span | .returnValue _ span
  | .conditional _ _ _ _ span | .conditionalPattern _ _ _ _ span => span

def psSyntaxTacticTerms (fuel : Nat) (tactic : PsSyntaxTactic) : List PsSyntaxTerm :=
  match fuel with
  | 0 => []
  | fuel + 1 => match tactic with
    | .exactE value _ _ | .applyE value _ | .change value _ _ | .eliminate value _ _ => [value]
    | .localE _ type value _ _ => type.toList ++ [value]
    | .focus body _ _ | .each body _ _ | .caseE _ _ body _ => body.flatMap (psSyntaxTacticTerms fuel)
    | _ => []

-- Single-scrutinee clients construct the same matrix representation.
def PsSyntaxTerm.matchE (scrutinee : PsSyntaxTerm)
    (alternatives : List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))
    (span : PsSourceSpan) : PsSyntaxTerm :=
  .matchMany [scrutinee] (alternatives.map fun (pattern, body, span) => ([pattern], body, span)) span

def psSyntaxSpanJoin (start : PsSourceSpan) (stop : PsSourceSpan) : PsSourceSpan :=
  { start := start.start, stop := stop.stop }

def psSyntaxTermSpan : PsSyntaxTerm -> PsSourceSpan
  | .doE _ span => span
  | .byE _ _ span => span
  | .sortE _ _ span => span
  | .hole span => span
  | .omittedType span => span
  | .optionalType _ _ span => span
  | .ascription _ _ span => span
  | .call _ _ span => span
  | .operatorE _ _ _ _ span => span
  | .reference name => name.span
  | .natural _ span => span
  | .scientific _ span => span
  | .string _ span => span
  | .character _ span => span
  | .bool _ span => span
  | .unit span => span
  | .record _ span | .recordUpdate _ _ span => span
  | .app _ _ span => span
  | .lambda _ _ span => span
  | .forallE _ _ span => span
  | .letE _ _ _ _ span | .haveE _ _ _ _ span => span
  | .ifE _ _ _ _ span => span
  | .matchMany _ _ span => span

def psSyntaxPatternSpan : PsSyntaxPattern -> PsSourceSpan
  | .natural _ span => span
  | .bool _ span => span
  | .wildcard span => span
  | .ctor _ _ span => span
  | .variable name => name.span

structure PsSyntaxInductiveConstructor where
  name : PsSyntaxName
  fields : List (Prod PsSyntaxBinderHead PsSyntaxTerm)
  span : PsSourceSpan
  resultType : Option PsSyntaxTerm := none

structure PsSyntaxImport where
  moduleName : PsSyntaxName
  span : PsSourceSpan
  -- RC4 module-style import: a public import also re-exports this module's
  -- public interface. Ordinary imports remain visible only in this module.
  isPublic : Bool := false

-- The selected total suffix retains its measure, proof-body scope and source
-- span independently of the function body. `decreasing` is a byE node when
-- present; native printing removes its term-level by/braces for decreasing_by.
structure PsSyntaxTermination where
  measure : PsSyntaxTerm
  decreasing : Option PsSyntaxTerm := none
  span : PsSourceSpan

-- Local `def` is owned source syntax, not a top-level command. Its optional
-- result annotation and recursion suffix survive until typed group preparation.
inductive PsSyntaxLocalRecursion where
  | total (termination : PsSyntaxTermination)
  | fixedpoint (span : PsSourceSpan)

structure PsSyntaxLocalDefinition where
  name : PsSyntaxName
  binders : List (PsSyntaxBinderHead × PsSyntaxTerm)
  type : Option PsSyntaxTerm
  value : PsSyntaxTerm
  recursion : Option PsSyntaxLocalRecursion
  span : PsSourceSpan

inductive PsSyntaxDeclaration where
  -- The wrapped declaration retains its own head, body and suffix. The last
  -- span belongs to `where { ... }`; helper bodies are not declaration bodies.
  | whereDeclaration
      (declaration : PsSyntaxDeclaration)
      (locals : List PsSyntaxLocalDefinition)
      (span : PsSourceSpan)
  | definition
      (name : PsSyntaxName)
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (type : PsSyntaxTerm)
      (value : PsSyntaxTerm)
      (span : PsSourceSpan)
  | partialDefinition
      (name : PsSyntaxName)
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (type : PsSyntaxTerm)
      (value : PsSyntaxTerm)
      (span : PsSourceSpan)
  -- Retain the requested P1 strategy through parsing and scope resolution.
  -- Its eventual fixed-point construction has a separate assumption gate;
  -- this node is neither a total definition nor an opaque P0 implementation.
  | fixedpointDefinition
      (name : PsSyntaxName)
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (type : PsSyntaxTerm)
      (value : PsSyntaxTerm)
      (span : PsSourceSpan)
  | wellFoundedDefinition
      (name : PsSyntaxName)
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (type : PsSyntaxTerm)
      (value : PsSyntaxTerm)
      (termination : PsSyntaxTermination)
      (span : PsSourceSpan)
  | theoremDecl
      (name : PsSyntaxName)
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (type : PsSyntaxTerm)
      (value : PsSyntaxTerm)
      (span : PsSourceSpan)
  | inductiveDecl
      (name : PsSyntaxName)
      (params : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (resultType : Option PsSyntaxTerm)
      (constructors : List PsSyntaxInductiveConstructor)
      (span : PsSourceSpan)
  | structureDecl
      (name : PsSyntaxName)
      (params : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (resultType : Option PsSyntaxTerm)
      (fields : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (span : PsSourceSpan)

structure PsSyntaxModule where
  imports : List PsSyntaxImport
  declarations : List PsSyntaxDeclaration

-- Commands are ordered independently of declarations. The legacy module record
-- remains a declaration-only API; v7 programs retain all scope boundaries.
-- Registration is command metadata; the underlying value/data declaration
-- retains the shared binder, scope and elaboration representation.
inductive PsSyntaxRegistration where
  | classDecl
  | abbrevDecl
  | opaqueDecl
  | instanceDecl (priority : Nat)
  | defaultInstanceDecl (priority : Nat) (ordinaryPriority : Option Nat)

-- A source mutual block keeps ordered declaration and modifier ownership.
-- It is not flattened into sequential commands or a mutual-inductive group.
structure PsSyntaxMutualMember where
  declaration : PsSyntaxDeclaration
  isPrivate : Bool := false
  registration : Option PsSyntaxRegistration := none

inductive PsSyntaxCommand where
  | universeCmd (names : List PsSyntaxName) (span : PsSourceSpan)
  | registeredDeclaration (value : PsSyntaxDeclaration) (registration : PsSyntaxRegistration)
  | declaration (value : PsSyntaxDeclaration)
  -- Modifier ownership stays in command syntax; data/term ASTs are unchanged.
  | privateDeclaration (value : PsSyntaxDeclaration)
  | privateRegisteredDeclaration (value : PsSyntaxDeclaration) (registration : PsSyntaxRegistration)
  -- A trailing allowlisted deriving clause belongs to its defining data
  -- command, not to a second unconstrained source macro or derived type AST.
  | derivingDeclaration (value : PsSyntaxDeclaration) (handlers : List PsSyntaxName)
      (isPrivate : Bool)
  | mutualDeclarations (members : List PsSyntaxMutualMember) (span : PsSourceSpan)
  | namespaceCmd (name : PsSyntaxName) (span : PsSourceSpan)
  | sectionCmd (name : Option PsSyntaxName) (span : PsSourceSpan)
  | endCmd (name : Option PsSyntaxName) (span : PsSourceSpan)
  | openCmd (names : List PsSyntaxName) (span : PsSourceSpan)
  | variableCmd (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) (span : PsSourceSpan)
  | includeCmd (names : List PsSyntaxName) (span : PsSourceSpan)
  | omitCmd (names : List PsSyntaxName) (span : PsSourceSpan)

structure PsSyntaxProgram where
  imports : List PsSyntaxImport
  commands : List PsSyntaxCommand

