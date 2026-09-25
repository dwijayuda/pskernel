import Ps.Foundation.Name
import Ps.Core.Declaration

def psDeclarationName : PsDeclaration -> PsName
  | .axiomDecl name _ _ => name
  | .definitionDecl name _ _ _ => name
  | .theoremDecl name _ _ _ => name
  | .partialDecl name _ _ _ => name
  | .opaqueDecl name _ _ _ => name
  | .inductiveDecl info => info.name
  | .constructorDecl info => info.name
  | .recursorDecl info => info.name

def psDeclarationLevelParams : PsDeclaration -> List PsName
  | .axiomDecl _ levelParams _ => levelParams
  | .definitionDecl _ levelParams _ _ => levelParams
  | .theoremDecl _ levelParams _ _ => levelParams
  | .partialDecl _ levelParams _ _ => levelParams
  | .opaqueDecl _ levelParams _ _ => levelParams
  | .inductiveDecl info => info.levelParams
  | .constructorDecl info => info.levelParams
  | .recursorDecl info => info.levelParams

def psDeclarationType : PsDeclaration -> PsExpr
  | .axiomDecl _ _ type => type
  | .definitionDecl _ _ type _ => type
  | .theoremDecl _ _ type _ => type
  | .partialDecl _ _ type _ => type
  | .opaqueDecl _ _ type _ => type
  | .inductiveDecl info => info.type
  | .constructorDecl info => info.type
  | .recursorDecl info => info.type

def psDeclarationValue : PsDeclaration -> Option PsExpr
  | .definitionDecl _ _ _ value => some value
  | _ => none

def psDeclarationInductiveInfo : PsDeclaration -> Option PsInductiveInfo
  | .inductiveDecl info => some info
  | _ => none

def psDeclarationConstructorInfo : PsDeclaration -> Option PsConstructorInfo
  | .constructorDecl info => some info
  | _ => none

def psDeclarationRecursorInfo : PsDeclaration -> Option PsRecursorInfo
  | .recursorDecl info => some info
  | _ => none

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

def psEnvironmentFindInductive
    (environment : PsEnvironment)
    (name : PsName) : Option PsInductiveInfo :=
  match psEnvironmentFind environment name with
  | some declaration => psDeclarationInductiveInfo declaration
  | none => none

def psEnvironmentFindConstructor
    (environment : PsEnvironment)
    (name : PsName) : Option PsConstructorInfo :=
  match psEnvironmentFind environment name with
  | some declaration => psDeclarationConstructorInfo declaration
  | none => none

def psEnvironmentFindRecursor
    (environment : PsEnvironment)
    (name : PsName) : Option PsRecursorInfo :=
  match psEnvironmentFind environment name with
  | some declaration => psDeclarationRecursorInfo declaration
  | none => none

def psEnvironmentContains (environment : PsEnvironment) (name : PsName) : Bool :=
  match psEnvironmentFind environment name with
  | none => false
  | some _ => true

def psEnvironmentAdd (environment : PsEnvironment) (declaration : PsDeclaration) : Option PsEnvironment :=
  if psEnvironmentContains environment (psDeclarationName declaration) then
    none
  else
    some { declarations := declaration :: environment.declarations }
