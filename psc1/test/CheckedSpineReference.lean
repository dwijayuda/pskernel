import Ps.Bridge.CheckedAdmissions

namespace CheckedSpineReference

def psCheckedNestedCollect (all : List PsDeclaration) (declarations : List PsDeclaration) : Except PsCheckedAdmissionCodecError (List (Prod PsName PsDeclaration)) :=
  match declarations with
  | List.nil => Except.ok List.nil
  | List.cons declaration rest =>
      match psCheckedNestedCollect all rest with
      | Except.error error => Except.error error
      | Except.ok tail =>
          match declaration with
          | PsDeclaration.inductiveDecl info =>
              match psCheckedNestedRoots all info.name info.constructors List.nil with
              | Except.error error => Except.error error
              | Except.ok roots =>
                  if psListIsEmpty roots then Except.ok tail
                  else
                    match psCheckedNestedExpand info.name (Nat.succ (psCheckedNestedSizes roots)) roots List.nil with
                    | Except.error error => Except.error error
                    | Except.ok shapes =>
                        match psCheckedNestedWrapper all info shapes with
                        | Except.error error => Except.error error
                        | Except.ok wrapper => Except.ok (List.cons (Prod.mk info.name wrapper) tail)
          | _ => Except.ok tail

def psCheckedNestedFind (wrappers : List (Prod PsName PsDeclaration)) : PsName -> Option PsDeclaration :=
  match wrappers with
  | List.nil => fun (_name : PsName) => Option.none
  | List.cons entry rest =>
      let smaller : PsName -> Option PsDeclaration := psCheckedNestedFind rest;
      fun (name : PsName) => if psNameEq name (Prod.fst entry) then Option.some (Prod.snd entry) else smaller name

def psCheckedNestedNormalize (wrappers : List (Prod PsName PsDeclaration)) (declarations : List PsDeclaration) : List PsDeclaration :=
  match declarations with
  | List.nil => List.nil
  | List.cons declaration rest =>
      let tail := psCheckedNestedNormalize wrappers rest;
      match declaration with
      | PsDeclaration.definitionDecl name levels type value =>
          List.cons (PsDeclaration.definitionDecl name levels (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers value)) tail
      | PsDeclaration.theoremDecl name levels type value =>
          List.cons (PsDeclaration.theoremDecl name levels (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers value)) tail
      | PsDeclaration.inductiveDecl info =>
          match psCheckedNestedFind wrappers info.name with
          | Option.none => List.cons declaration tail
          | Option.some wrapper => List.cons declaration (List.cons wrapper tail)
      | _ => List.cons declaration tail


end CheckedSpineReference
