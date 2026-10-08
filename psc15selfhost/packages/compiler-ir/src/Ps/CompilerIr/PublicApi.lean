import Ps.Core.Declaration

-- Logical owner: public-api. Physical package separation is deferred.
-- Source semantic signatures only: no values, erased layouts, target names,
-- source positions, serialized capabilities, or preservation claims.
inductive PsPublicApiConstantKind where
  | axiomValue
  | definitionValue
  | theoremValue
  | partialValue
  | opaqueValue

inductive PsPublicApiDeclaration where
  | constant
      (kind : PsPublicApiConstantKind)
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
  | inductiveDecl (info : PsInductiveInfo)
  | constructorDecl (info : PsConstructorInfo)
  | recursorDecl (info : PsRecursorInfo)

structure PsPublicApiModule where
  declarations : List PsPublicApiDeclaration

-- The current frontend has no public/private export policy. This exact
-- projection retains all prepared declarations, including generated members.
-- Selecting a target export surface is a separate adapter obligation.
def psPublicApiProjectDeclaration
    (declaration : PsDeclaration) : PsPublicApiDeclaration :=
  match declaration with
  | PsDeclaration.axiomDecl name levels type =>
      PsPublicApiDeclaration.constant PsPublicApiConstantKind.axiomValue name levels type
  | PsDeclaration.definitionDecl name levels type _ =>
      PsPublicApiDeclaration.constant PsPublicApiConstantKind.definitionValue name levels type
  | PsDeclaration.theoremDecl name levels type _ =>
      PsPublicApiDeclaration.constant PsPublicApiConstantKind.theoremValue name levels type
  | PsDeclaration.partialDecl name levels type _ =>
      PsPublicApiDeclaration.constant PsPublicApiConstantKind.partialValue name levels type
  | PsDeclaration.opaqueDecl name levels type _ =>
      PsPublicApiDeclaration.constant PsPublicApiConstantKind.opaqueValue name levels type
  | PsDeclaration.inductiveDecl info =>
      PsPublicApiDeclaration.inductiveDecl info
  | PsDeclaration.constructorDecl info =>
      PsPublicApiDeclaration.constructorDecl info
  | PsDeclaration.recursorDecl info =>
      PsPublicApiDeclaration.recursorDecl info

def psPublicApiProjectDeclarations
    (declarations : List PsDeclaration) : List PsPublicApiDeclaration :=
  match declarations with
  | List.nil => List.nil
  | List.cons declaration rest =>
      List.cons
        (psPublicApiProjectDeclaration declaration)
        (psPublicApiProjectDeclarations rest)

def psPublicApiProjectModule
    (declarations : List PsDeclaration) : PsPublicApiModule :=
  PsPublicApiModule.mk (psPublicApiProjectDeclarations declarations)
