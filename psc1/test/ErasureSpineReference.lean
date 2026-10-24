import Ps.Erasure.Basic

namespace ErasureSpineReference

def psErasureIndexPrepend (Value : Type) (entries : List (Prod PsName Value)) : PsErasureNameIndex Value -> PsErasureNameIndex Value :=
  match entries with
  | List.nil => fun (tail : PsErasureNameIndex Value) => tail
  | List.cons entry rest =>
      let smaller : PsErasureNameIndex Value -> PsErasureNameIndex Value := psErasureIndexPrepend Value rest;
      fun (tail : PsErasureNameIndex Value) =>
        match entry with
        | Prod.mk name value => psErasureIndexInsert Value (smaller tail) name value

def psErasureDeclarationNameIndex (entries : List (Prod PsName String)) : PsErasureDeclarationNames :=
  match entries with
  | List.nil => PsErasureDeclarationNames.mk PsErasureNameIndex.empty PsErasureNameIndex.empty 0 PsErasureNameIndex.empty
  | List.cons entry rest =>
      let tail := psErasureDeclarationNameIndex rest;
      match entry with
      | Prod.mk name value => PsErasureDeclarationNames.mk
          (psErasureIndexInsert String tail.byCore name value)
          (psErasureIndexInsert Bool tail.byOutput (PsName.str PsName.anonymous value) true)
          (Nat.succ tail.count)
          tail.entries

def psErasureDeclarationEntryIndex
    (environment : PsEnvironment) (declarations : List PsDeclaration) :
    Except PsErasureError (PsErasureNameIndex PsErasureEntryInfo) :=
  match declarations with
  | List.nil => Except.ok PsErasureNameIndex.empty
  | List.cons declaration rest =>
      match psErasureDeclarationEntryIndex environment rest with
      | Except.error error => Except.error error
      | Except.ok tail =>
          match declaration with
          | PsDeclaration.definitionDecl name _ type value =>
              psErasureAddDeclarationEntry environment name type value tail
          | PsDeclaration.partialDecl name _ type value =>
              psErasureAddDeclarationEntry environment name type value tail
          | _ => Except.ok tail


end ErasureSpineReference
