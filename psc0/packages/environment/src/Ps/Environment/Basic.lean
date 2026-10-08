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

-- A persistent 16-bit trie narrows lookup to a collision bucket. The ordered
-- declaration list remains authoritative for enumeration and admission order.
inductive PsEnvironmentIndex where
  | empty
  | bucket (declarations : List PsDeclaration)
  | branch (left right : PsEnvironmentIndex)

def psEnvironmentHashStringWorker (fuel : Nat) : String -> Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (_value : String) (_position : Nat) (hash : Nat) => hash
  | Nat.succ remaining =>
      let smaller : String -> Nat -> Nat -> Nat := psEnvironmentHashStringWorker remaining;
      fun (value : String) (position : Nat) (hash : Nat) =>
        if String.Internal.atEnd value (String.Pos.Raw.mk position) then hash
        else
          let char := String.Internal.get value (String.Pos.Raw.mk position);
          let next := String.Pos.Raw.byteIdx (String.Internal.next value (String.Pos.Raw.mk position));
          smaller value next (Nat.mod (Nat.add (Nat.mul hash 31) (Char.toNat char)) 65521)

def psEnvironmentNameHash (name : PsName) : Nat :=
  match name with
  | PsName.anonymous => 0
  | PsName.str parent value =>
      psEnvironmentHashStringWorker (Nat.succ (String.utf8ByteSize value)) value 0
        (Nat.mod (Nat.add (Nat.mul (psEnvironmentNameHash parent) 31) 1) 65521)
  | PsName.num parent value =>
      Nat.mod (Nat.add (Nat.add (Nat.mul (psEnvironmentNameHash parent) 31) 2) value) 65521

def psEnvironmentIndexFindWorker (fuel : Nat) : PsEnvironmentIndex -> Nat -> List PsDeclaration :=
  match fuel with
  | Nat.zero =>
      fun (index : PsEnvironmentIndex) (_hash : Nat) =>
        match index with
        | PsEnvironmentIndex.bucket declarations => declarations
        | _ => List.nil
  | Nat.succ remaining =>
      let smaller : PsEnvironmentIndex -> Nat -> List PsDeclaration := psEnvironmentIndexFindWorker remaining;
      fun (index : PsEnvironmentIndex) (hash : Nat) =>
        match index with
        | PsEnvironmentIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then smaller left (Nat.div hash 2)
            else smaller right (Nat.div hash 2)
        | _ => List.nil

def psEnvironmentIndexSetWorker (fuel : Nat) : PsEnvironmentIndex -> Nat -> List PsDeclaration -> PsEnvironmentIndex :=
  match fuel with
  | Nat.zero => fun (_index : PsEnvironmentIndex) (_hash : Nat) (declarations : List PsDeclaration) => PsEnvironmentIndex.bucket declarations
  | Nat.succ remaining =>
      let smaller : PsEnvironmentIndex -> Nat -> List PsDeclaration -> PsEnvironmentIndex := psEnvironmentIndexSetWorker remaining;
      fun (index : PsEnvironmentIndex) (hash : Nat) (declarations : List PsDeclaration) =>
        let left : PsEnvironmentIndex := match index with
          | PsEnvironmentIndex.branch value _ => value
          | _ => PsEnvironmentIndex.empty;
        let right : PsEnvironmentIndex := match index with
          | PsEnvironmentIndex.branch _ value => value
          | _ => PsEnvironmentIndex.empty;
        if Nat.beq (Nat.mod hash 2) 0 then
          PsEnvironmentIndex.branch (smaller left (Nat.div hash 2) declarations) right
        else PsEnvironmentIndex.branch left (smaller right (Nat.div hash 2) declarations)

structure PsEnvironment where
  declarations : List PsDeclaration
  index : PsEnvironmentIndex

def psEnvironmentEmpty : PsEnvironment :=
  PsEnvironment.mk List.nil PsEnvironmentIndex.empty

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
  psEnvironmentFindInList name (psEnvironmentIndexFindWorker 16 environment.index (psEnvironmentNameHash name))

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

def psEnvironmentIndexInsert (index : PsEnvironmentIndex) (declaration : PsDeclaration) : PsEnvironmentIndex :=
  let name := psDeclarationName declaration;
  let hash := psEnvironmentNameHash name;
  let bucket := psEnvironmentIndexFindWorker 16 index hash;
  psEnvironmentIndexSetWorker 16 index hash (List.cons declaration (psEnvironmentRemoveName name bucket))

def psEnvironmentAddReplacingAxiom
    (environment : PsEnvironment)
    (declaration : PsDeclaration) : Option PsEnvironment :=
  let name := psDeclarationName declaration;
  match psEnvironmentFind environment name with
  | none =>
      Option.some
        (PsEnvironment.mk
          (List.cons declaration environment.declarations)
          (psEnvironmentIndexInsert environment.index declaration))
  | some existing =>
      match existing with
      | .axiomDecl _ _ _ =>
          Option.some
            (PsEnvironment.mk
              (List.cons
                declaration
                (psEnvironmentRemoveName
                  name
                  environment.declarations))
              (psEnvironmentIndexInsert environment.index declaration))
      | _ =>
          Option.none

def psEnvironmentAdd (environment : PsEnvironment) (declaration : PsDeclaration) : Option PsEnvironment :=
  if psEnvironmentContains environment (psDeclarationName declaration) then
    Option.none
  else
    Option.some (PsEnvironment.mk (List.cons declaration environment.declarations)
      (psEnvironmentIndexInsert environment.index declaration))
