import Ps.Foundation.Source

structure PsSyntaxName where
  segments : List String
  span : PsSourceSpan

inductive PsSyntaxBinderKind where
  | explicit
  | implicit
  | strictImplicit
  | instanceImplicit

structure PsSyntaxBinderHead where
  name : PsSyntaxName
  kind : PsSyntaxBinderKind
  span : PsSourceSpan

inductive PsSyntaxPattern where
  | bool (value : Bool) (span : PsSourceSpan)
  | wildcard (span : PsSourceSpan)
  | constructor
      (name : PsSyntaxName)
      (binders : List PsSyntaxName)
      (span : PsSourceSpan)

inductive PsSyntaxTerm where
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
  | matchE
      (scrutinee : PsSyntaxTerm)
      (alternatives : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))
      (span : PsSourceSpan)

structure PsSyntaxInductiveConstructor where
  name : PsSyntaxName
  fields : List (Prod PsSyntaxBinderHead PsSyntaxTerm)
  span : PsSourceSpan

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
inductive PsSyntaxCommand where
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
