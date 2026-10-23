import Ps.Environment.Basic
import Ps.Erasure.Inductive

namespace SharedLookupPrefixReference

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

def psFindConstructorDeclaration (declarations : List PsDeclaration) : PsName -> Option PsConstructorInfo :=
  match declarations with
  | List.nil => fun (_target : PsName) => Option.none
  | List.cons declaration rest =>
      let smaller : PsName -> Option PsConstructorInfo := psFindConstructorDeclaration rest;
      fun (target : PsName) =>
        match declaration with
        | PsDeclaration.constructorDecl info =>
            if psNameEq info.name target then Option.some info else smaller target
        | _ => smaller target


def psFindRecursorDeclaration (declarations : List PsDeclaration) : PsName -> Option PsRecursorInfo :=
  match declarations with
  | List.nil => fun (_target : PsName) => Option.none
  | List.cons declaration rest =>
      let smaller : PsName -> Option PsRecursorInfo := psFindRecursorDeclaration rest;
      fun (target : PsName) =>
        match declaration with
        | PsDeclaration.recursorDecl info =>
            if psNameEq info.name target then Option.some info else smaller target
        | _ => smaller target


end SharedLookupPrefixReference
