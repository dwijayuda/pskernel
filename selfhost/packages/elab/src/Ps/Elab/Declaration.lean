import Ps.Core.Declaration
import Ps.Elab.Term

structure PsElabDeclarationResult where
  declaration : PsDeclaration
  metaContext : PsMetaContext

structure PsElabModuleResult where
  environment : PsEnvironment
  declarations : List PsDeclaration

def psElabDeclarationParts
    (environment : PsEnvironment)
    (nameSyntax : PsSyntaxName)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax : PsSyntaxTerm)
    (valueSyntax : PsSyntaxTerm)
    (isTheorem : Bool) :
    Except PsElabError PsElabDeclarationResult :=
  match psSyntaxNameToName nameSyntax with
  | none => Except.error PsElabError.emptyName
  | some name =>
      let initial := psElabContextEmpty environment
      match psElabTypedBinders
          (fun context term expected => psElabTerm context term expected)
          initial
          binders with
      | Except.error error => Except.error error
      | Except.ok binderResult =>
          match psElabTerm binderResult.context typeSyntax none with
          | Except.error error => Except.error error
          | Except.ok typeResult =>
              match psInferEnsureSort
                  typeResult.context.environment
                  typeResult.context.metaContext
                  typeResult.context.localContext
                  typeResult.type with
              | Except.error error =>
                  Except.error (PsElabError.infer error)
              | Except.ok _ =>
                  match psElabTerm
                      typeResult.context
                      valueSyntax
                      (some typeResult.term) with
                  | Except.error error => Except.error error
                  | Except.ok valueResult =>
                      let metaContext := valueResult.context.metaContext
                      let openValue :=
                        psMetaInstantiate metaContext valueResult.term
                      let openType :=
                        psMetaInstantiate metaContext typeResult.term
                      let closed :=
                        psCloseElabTypedBinders
                          metaContext
                          binderResult.bindersRev
                          openValue
                          openType
                      if
                          psExprHasUnresolvedMeta closed.1
                            || psExprHasUnresolvedMeta closed.2 then
                        Except.error PsElabError.unresolvedMetavariable
                      else if isTheorem then
                        Except.ok {
                          declaration :=
                            PsDeclaration.theoremDecl
                              name
                              []
                              closed.2
                              closed.1
                          metaContext := metaContext
                        }
                      else
                        Except.ok {
                          declaration :=
                            PsDeclaration.definitionDecl
                              name
                              []
                              closed.2
                              closed.1
                          metaContext := metaContext
                        }

def psElabDeclaration
    (environment : PsEnvironment)
    (source : PsSyntaxDeclaration) :
    Except PsElabError PsElabDeclarationResult :=
  match source with
  | .definition name binders type value _ =>
      psElabDeclarationParts
        environment
        name
        binders
        type
        value
        false
  | .theoremDecl name binders type value _ =>
      psElabDeclarationParts
        environment
        name
        binders
        type
        value
        true

def psElabDeclarations
    (environment : PsEnvironment) :
    List PsSyntaxDeclaration ->
    List PsDeclaration ->
    Except PsElabError PsElabModuleResult
  | [], declarationsRev =>
      Except.ok {
        environment := environment
        declarations := declarationsRev.reverse
      }
  | source :: rest, declarationsRev =>
      match psElabDeclaration environment source with
      | Except.error error => Except.error error
      | Except.ok result =>
          match psEnvironmentAdd environment result.declaration with
          | none =>
              Except.error
                (PsElabError.duplicateDeclaration
                  (psDeclarationName result.declaration))
          | some nextEnvironment =>
              psElabDeclarations
                nextEnvironment
                rest
                (result.declaration :: declarationsRev)

def psElabModule
    (environment : PsEnvironment)
    (module : PsSyntaxModule) :
    Except PsElabError PsElabModuleResult :=
  psElabDeclarations environment module.declarations []
