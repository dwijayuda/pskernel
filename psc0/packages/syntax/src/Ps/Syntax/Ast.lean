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

mutual
inductive PsSyntaxTerm where
  | byE (tactics : List PsSyntaxTactic) (scope : PsSyntaxProofScope) (span : PsSourceSpan)
  | sortE (isType : Bool) (level : PsSyntaxLevel) (span : PsSourceSpan)
  | reference (name : PsSyntaxName)
  | hole (span : PsSourceSpan)
  -- Binder-only source annotation; checked as Lean's reducible optParam type.
  | optionalType (type value : PsSyntaxTerm) (span : PsSourceSpan)
  | ascription (value type : PsSyntaxTerm) (span : PsSourceSpan)
  -- Adjacent calls retain labels and the empty-invocation request until elaboration.
  | call (fn : PsSyntaxTerm)
      (args : List (Prod (Option PsSyntaxName) PsSyntaxTerm)) (span : PsSourceSpan)
  | natural (text : String) (span : PsSourceSpan)
  | string (text : String) (span : PsSourceSpan)
  | character (text : String) (span : PsSourceSpan)
  | bool (value : Bool) (span : PsSourceSpan)
  | unit (span : PsSourceSpan)
  | record
      (fields : List (Prod PsSyntaxName PsSyntaxTerm))
      (span : PsSourceSpan)
  | app (fn : PsSyntaxTerm) (args : List PsSyntaxTerm) (span : PsSourceSpan)
  | lambda
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (body : PsSyntaxTerm)
      (span : PsSourceSpan)
  | forallE
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (body : PsSyntaxTerm)
      (span : PsSourceSpan)
  | letE
      (name : PsSyntaxName)
      (type : Option PsSyntaxTerm)
      (value : PsSyntaxTerm)
      (body : PsSyntaxTerm)
      (span : PsSourceSpan)
  | ifE
      (condition : PsSyntaxTerm)
      (thenBranch : PsSyntaxTerm)
      (elseBranch : PsSyntaxTerm)
      (span : PsSourceSpan)
  | matchMany
      (scrutinees : List PsSyntaxTerm)
      (alternatives : List (List PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))
      (span : PsSourceSpan)

inductive PsSyntaxTactic where
  | exactE (value : PsSyntaxTerm) (refine : Bool) (span : PsSourceSpan)
  | applyE (value : PsSyntaxTerm) (span : PsSourceSpan)
  | intro (names : List PsSyntaxName) (span : PsSourceSpan)
  | assumption (span : PsSourceSpan)
  | reflexivity (span : PsSourceSpan)
  | constructor (span : PsSourceSpan)
  | focus (body : List PsSyntaxTactic) (mustClose : Bool) (span : PsSourceSpan)
  | each (body : List PsSyntaxTactic) (any : Bool) (span : PsSourceSpan)
end

def psSyntaxTacticTerms (fuel : Nat) (tactic : PsSyntaxTactic) : List PsSyntaxTerm :=
  match fuel with
  | 0 => []
  | fuel + 1 => match tactic with
    | .exactE value _ _ | .applyE value _ => [value]
    | .focus body _ _ | .each body _ _ => body.flatMap (psSyntaxTacticTerms fuel)
    | _ => []

-- Single-scrutinee clients construct the same matrix representation.
def PsSyntaxTerm.matchE (scrutinee : PsSyntaxTerm)
    (alternatives : List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))
    (span : PsSourceSpan) : PsSyntaxTerm :=
  .matchMany [scrutinee] (alternatives.map fun (pattern, body, span) => ([pattern], body, span)) span

def psSyntaxSpanJoin (start : PsSourceSpan) (stop : PsSourceSpan) : PsSourceSpan :=
  { start := start.start, stop := stop.stop }

def psSyntaxTermSpan : PsSyntaxTerm -> PsSourceSpan
  | .byE _ _ span => span
  | .sortE _ _ span => span
  | .hole span => span
  | .optionalType _ _ span => span
  | .ascription _ _ span => span
  | .call _ _ span => span
  | .reference name => name.span
  | .natural _ span => span
  | .string _ span => span
  | .character _ span => span
  | .bool _ span => span
  | .unit span => span
  | .record _ span => span
  | .app _ _ span => span
  | .lambda _ _ span => span
  | .forallE _ _ span => span
  | .letE _ _ _ _ span => span
  | .ifE _ _ _ span => span
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

inductive PsSyntaxDeclaration where
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
  | instanceDecl (priority : Nat)

inductive PsSyntaxCommand where
  | universeCmd (names : List PsSyntaxName) (span : PsSourceSpan)
  | registeredDeclaration (value : PsSyntaxDeclaration) (registration : PsSyntaxRegistration)
  | declaration (value : PsSyntaxDeclaration)
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
