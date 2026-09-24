import Ps.Foundation.Name
import Ps.Foundation.Source

structure PsSyntaxName where
  segments : List String
  span : PsSourceSpan

inductive PsSyntaxBinderKind where
  | explicit
  | implicit
  | strictImplicit
  | instanceImplicit

structure PsSyntaxBinder where
  name : PsSyntaxName
  type : PsSyntaxTerm
  kind : PsSyntaxBinderKind
  span : PsSourceSpan

inductive PsSyntaxTerm where
  | reference (name : PsSyntaxName)
  | natural (text : String) (span : PsSourceSpan)
  | string (text : String) (span : PsSourceSpan)
  | character (text : String) (span : PsSourceSpan)
  | bool (value : Bool) (span : PsSourceSpan)
  | unit (span : PsSourceSpan)
  | app (fn : PsSyntaxTerm) (args : List PsSyntaxTerm) (span : PsSourceSpan)
  | lambda (binders : List PsSyntaxBinder) (body : PsSyntaxTerm) (span : PsSourceSpan)
  | forallE (binders : List PsSyntaxBinder) (body : PsSyntaxTerm) (span : PsSourceSpan)
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

structure PsSyntaxImport where
  moduleName : PsSyntaxName
  span : PsSourceSpan

inductive PsSyntaxDeclaration where
  | definition
      (name : PsSyntaxName)
      (binders : List PsSyntaxBinder)
      (type : PsSyntaxTerm)
      (value : PsSyntaxTerm)
      (span : PsSourceSpan)
  | theorem
      (name : PsSyntaxName)
      (binders : List PsSyntaxBinder)
      (type : PsSyntaxTerm)
      (value : PsSyntaxTerm)
      (span : PsSourceSpan)

structure PsSyntaxModule where
  imports : List PsSyntaxImport
  declarations : List PsSyntaxDeclaration
