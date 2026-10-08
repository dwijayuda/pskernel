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
  | .definitionDecl _ _ _ value => Option.some value
  | _ => Option.none

def psDeclarationInductiveInfo : PsDeclaration -> Option PsInductiveInfo
  | .inductiveDecl info => Option.some info
  | _ => Option.none

def psDeclarationConstructorInfo : PsDeclaration -> Option PsConstructorInfo
  | .constructorDecl info => Option.some info
  | _ => Option.none

def psDeclarationRecursorInfo : PsDeclaration -> Option PsRecursorInfo
  | .recursorDecl info => Option.some info
  | _ => Option.none

structure PsEnvironment where
  declarations : List PsDeclaration

def psEnvironmentEmpty : PsEnvironment :=
  PsEnvironment.mk List.nil

def psEnvironmentFindInListWorker
    (declarations : List PsDeclaration) :
    PsName -> Option PsDeclaration :=
  match declarations with
  | List.nil =>
      fun (_name : PsName) => Option.none
  | List.cons declaration rest =>
      let smaller : PsName -> Option PsDeclaration :=
        psEnvironmentFindInListWorker rest;
      fun (name : PsName) =>
        if psNameEq name (psDeclarationName declaration) then
          Option.some declaration
        else
          smaller name

def psEnvironmentFindInList
    (name : PsName)
    (declarations : List PsDeclaration) :
    Option PsDeclaration :=
  psEnvironmentFindInListWorker declarations name

def psEnvironmentFind (environment : PsEnvironment) (name : PsName) : Option PsDeclaration :=
  psEnvironmentFindInList name environment.declarations

def psEnvironmentFindInductive
    (environment : PsEnvironment)
    (name : PsName) : Option PsInductiveInfo :=
  match psEnvironmentFind environment name with
  | some declaration => psDeclarationInductiveInfo declaration
  | none => Option.none

def psEnvironmentFindConstructor
    (environment : PsEnvironment)
    (name : PsName) : Option PsConstructorInfo :=
  match psEnvironmentFind environment name with
  | some declaration => psDeclarationConstructorInfo declaration
  | none => Option.none

def psEnvironmentFindRecursor
    (environment : PsEnvironment)
    (name : PsName) : Option PsRecursorInfo :=
  match psEnvironmentFind environment name with
  | some declaration => psDeclarationRecursorInfo declaration
  | none => Option.none

def psEnvironmentContains (environment : PsEnvironment) (name : PsName) : Bool :=
  match psEnvironmentFind environment name with
  | none => false
  | some _ => true

def psEnvironmentRemoveNameWorker
    (declarations : List PsDeclaration) :
    PsName -> List PsDeclaration :=
  match declarations with
  | List.nil =>
      fun (_name : PsName) => List.nil
  | List.cons declaration rest =>
      let smaller : PsName -> List PsDeclaration :=
        psEnvironmentRemoveNameWorker rest;
      fun (name : PsName) =>
        if psNameEq name (psDeclarationName declaration) then
          smaller name
        else
          List.cons declaration (smaller name)

def psEnvironmentRemoveName
    (name : PsName)
    (declarations : List PsDeclaration) :
    List PsDeclaration :=
  psEnvironmentRemoveNameWorker declarations name

def psEnvironmentAddReplacingAxiom
    (environment : PsEnvironment)
    (declaration : PsDeclaration) : Option PsEnvironment :=
  let name := psDeclarationName declaration;
  match psEnvironmentFind environment name with
  | none =>
      Option.some
        (PsEnvironment.mk
          (List.cons declaration environment.declarations))
  | some existing =>
      match existing with
      | .axiomDecl _ _ _ =>
          Option.some
            (PsEnvironment.mk
              (List.cons
                declaration
                (psEnvironmentRemoveName
                  name
                  environment.declarations)))
      | _ =>
          Option.none

def psEnvironmentAdd (environment : PsEnvironment) (declaration : PsDeclaration) : Option PsEnvironment :=
  if psEnvironmentContains environment (psDeclarationName declaration) then
    Option.none
  else
    Option.some (PsEnvironment.mk (List.cons declaration environment.declarations))
