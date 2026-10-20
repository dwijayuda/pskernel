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

inductive PsSyntaxBindingPattern where
  | name (name : PsSyntaxName)
  | wildcard (span : PsSourceSpan)
  | unit (span : PsSourceSpan)
  | pair (first second : PsSyntaxBindingPattern) (span : PsSourceSpan)

def psSyntaxBindingPatternSpan : PsSyntaxBindingPattern -> PsSourceSpan
  | .name name => name.span
  | .wildcard span => span
  | .unit span => span
  | .pair _ _ span => span

-- Preserve traversal order and duplicate leaves for binding validation.
def psSyntaxAppendNames (left : List PsSyntaxName) : List PsSyntaxName -> List PsSyntaxName :=
  match left with
  | List.nil => fun (right : List PsSyntaxName) => right
  | List.cons name rest =>
      let smaller : List PsSyntaxName -> List PsSyntaxName := psSyntaxAppendNames rest;
      fun (right : List PsSyntaxName) => List.cons name (smaller right)

def psSyntaxBindingPatternNames (pattern : PsSyntaxBindingPattern) : List PsSyntaxName :=
  match pattern with
  | .name name => [name]
  | .wildcard _ => []
  | .unit _ => []
  | .pair first second _ =>
      psSyntaxAppendNames (psSyntaxBindingPatternNames first) (psSyntaxBindingPatternNames second)

def psSyntaxBindingPatternSize (pattern : PsSyntaxBindingPattern) : Nat :=
  match pattern with
  | .name _ => 1
  | .wildcard _ => 1
  | .unit _ => 1
  | .pair first second _ =>
      1 + psSyntaxBindingPatternSize first + psSyntaxBindingPatternSize second

inductive PsSyntaxPattern where
  | bool (value : Bool) (span : PsSourceSpan)
  | wildcard (span : PsSourceSpan)
  | constructor
      (name : PsSyntaxName)
      (binders : List PsSyntaxName)
      (span : PsSourceSpan)

inductive PsSyntaxTerm where
  | reference (name : PsSyntaxName)
  | natural (text : String) (span : PsSourceSpan)
  | string (text : String) (span : PsSourceSpan)
  | character (text : String) (span : PsSourceSpan)
  | bool (value : Bool) (span : PsSourceSpan)
  | unit (span : PsSourceSpan)
  | record
      (fields : List (Prod PsSyntaxName PsSyntaxTerm))
      (span : PsSourceSpan)
  | app (fn : PsSyntaxTerm) (args : List PsSyntaxTerm) (span : PsSourceSpan)
  | arrayGetOptionE (array index : PsSyntaxTerm) (span : PsSourceSpan)
  | unary (operator : String) (operand : PsSyntaxTerm) (span : PsSourceSpan)
  | binary (operator : String) (left right : PsSyntaxTerm) (span : PsSourceSpan)
  | doE (body : PsSyntaxTerm) (span : PsSourceSpan)
  | doBindE
      (name : PsSyntaxName)
      (type : Option PsSyntaxTerm)
      (action body : PsSyntaxTerm)
      (span : PsSourceSpan)
  | doThenE (action body : PsSyntaxTerm) (span : PsSourceSpan)
  | doReturnE (value : PsSyntaxTerm) (span : PsSourceSpan)
  | doLetMutE
      (name : PsSyntaxName) (type : Option PsSyntaxTerm)
      (value body : PsSyntaxTerm) (span : PsSourceSpan)
  | doAssignE
      (name : PsSyntaxName) (value body : PsSyntaxTerm) (span : PsSourceSpan)
  | doIfE
      (condition thenBody elseBody rest : PsSyntaxTerm) (span : PsSourceSpan)
  | doTryE
      (body : PsSyntaxTerm) (errorName : PsSyntaxName)
      (handler rest : PsSyntaxTerm) (span : PsSourceSpan)
  | doEndE (span : PsSourceSpan)
  | doForE
      (name : PsSyntaxName) (collection body rest : PsSyntaxTerm)
      (span : PsSourceSpan)
  | doForRangeE
      (name : PsSyntaxName) (lower upper body rest : PsSyntaxTerm)
      (span : PsSourceSpan)
  | doWhileE
      (condition body rest : PsSyntaxTerm) (span : PsSourceSpan)
  | lambda
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (body : PsSyntaxTerm)
      (span : PsSourceSpan)
  | forallE
      (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
      (body : PsSyntaxTerm)
      (span : PsSourceSpan)
  | letPatternE
      (pattern : PsSyntaxBindingPattern)
      (type : Option PsSyntaxTerm)
      (value body : PsSyntaxTerm)
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

  | scopedDecl
      (namespacePath : List String)
      (declaration : PsSyntaxDeclaration)

structure PsSyntaxModule where
  imports : List PsSyntaxImport
  declarations : List PsSyntaxDeclaration

-- Namespace commands preserve local source names. These helpers interpret the
-- per-declaration scope metadata at semantic declaration boundaries.
def psSyntaxNamespaceAppend (left : List String) (right : List String) : List String :=
  match left with
  | List.nil => right
  | List.cons first rest => List.cons first (psSyntaxNamespaceAppend rest right)

def psSyntaxNamespaceName (namespacePrefix : List String) (name : PsSyntaxName) : PsSyntaxName :=
  PsSyntaxName.mk (psSyntaxNamespaceAppend namespacePrefix name.segments) name.span

-- Recurse structurally on the declaration before supplying the namespace.
def psSyntaxDeclarationQualifyWorker (source : PsSyntaxDeclaration) :
    List String -> PsSyntaxDeclaration :=
  match source with
  | PsSyntaxDeclaration.scopedDecl path declaration =>
      let smaller : List String -> PsSyntaxDeclaration :=
        psSyntaxDeclarationQualifyWorker declaration;
      fun (namespacePrefix : List String) =>
        smaller (psSyntaxNamespaceAppend namespacePrefix path)
  | PsSyntaxDeclaration.definition name binders type value span =>
      fun (namespacePrefix : List String) =>
        PsSyntaxDeclaration.definition (psSyntaxNamespaceName namespacePrefix name) binders type value span
  | PsSyntaxDeclaration.partialDefinition name binders type value span =>
      fun (namespacePrefix : List String) =>
        PsSyntaxDeclaration.partialDefinition (psSyntaxNamespaceName namespacePrefix name) binders type value span
  | PsSyntaxDeclaration.theoremDecl name binders type value span =>
      fun (namespacePrefix : List String) =>
        PsSyntaxDeclaration.theoremDecl (psSyntaxNamespaceName namespacePrefix name) binders type value span
  | PsSyntaxDeclaration.inductiveDecl name params type constructors span =>
      fun (namespacePrefix : List String) =>
        PsSyntaxDeclaration.inductiveDecl (psSyntaxNamespaceName namespacePrefix name) params type constructors span
  | PsSyntaxDeclaration.structureDecl name params fields span =>
      fun (namespacePrefix : List String) =>
        PsSyntaxDeclaration.structureDecl (psSyntaxNamespaceName namespacePrefix name) params fields span

def psSyntaxDeclarationQualify (namespacePrefix : List String)
    (source : PsSyntaxDeclaration) : PsSyntaxDeclaration :=
  psSyntaxDeclarationQualifyWorker source namespacePrefix

def psSyntaxDeclarationSpan (source : PsSyntaxDeclaration) : PsSourceSpan :=
  match source with
  | .definition _ _ _ _ span => span
  | .partialDefinition _ _ _ _ span => span
  | .theoremDecl _ _ _ _ span => span
  | .inductiveDecl _ _ _ _ span => span
  | .structureDecl _ _ _ span => span
  | .scopedDecl _ declaration => psSyntaxDeclarationSpan declaration
