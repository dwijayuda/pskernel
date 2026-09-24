import Ps.Foundation.Name
import Ps.Core.Declaration

def psDeclarationName : PsDeclaration -> PsName
  | .axiomDecl name _ _ => name
  | .definitionDecl name _ _ _ => name
  | .theoremDecl name _ _ _ => name
  | .opaqueDecl name _ _ _ => name

structure PsEnvironment where
  declarations : List PsDeclaration

def psEnvironmentEmpty : PsEnvironment :=
  { declarations := [] }

def psEnvironmentFindInList (name : PsName) : List PsDeclaration -> Option PsDeclaration
  | [] => none
  | declaration :: rest =>
      if psNameEq name (psDeclarationName declaration) then
        some declaration
      else
        psEnvironmentFindInList name rest

def psEnvironmentFind (environment : PsEnvironment) (name : PsName) : Option PsDeclaration :=
  psEnvironmentFindInList name environment.declarations

def psEnvironmentContains (environment : PsEnvironment) (name : PsName) : Bool :=
  match psEnvironmentFind environment name with
  | none => false
  | some _ => true

def psEnvironmentAdd (environment : PsEnvironment) (declaration : PsDeclaration) : Option PsEnvironment :=
  if psEnvironmentContains environment (psDeclarationName declaration) then
    none
  else
    some { declarations := declaration :: environment.declarations }
