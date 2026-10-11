import Ps.KernelCore.Core.Declaration

inductive PsKernelEnvironmentIndex where
  | empty
  | small (constants : List PsKernelConstantInfo)
  | bucket (constants : List PsKernelConstantInfo)
  | branch
      (left : PsKernelEnvironmentIndex)
      (right : PsKernelEnvironmentIndex)

def psKernelEnvironmentHashStringWorker
    (fuel : Nat) :
    String -> Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (_value : String)
        (_position : Nat)
        (hash : Nat) =>
        hash
  | Nat.succ remaining =>
      let smaller :
          String -> Nat -> Nat -> Nat :=
        psKernelEnvironmentHashStringWorker remaining;
      fun
        (value : String)
        (position : Nat)
        (hash : Nat) =>
        if
            String.Internal.atEnd
              value
              (String.Pos.Raw.mk position) then
          hash
        else
          let char :=
            String.Internal.get
              value
              (String.Pos.Raw.mk position);
          let next :=
            String.Pos.Raw.byteIdx
              (String.Internal.next
                value
                (String.Pos.Raw.mk position));
          smaller
            value
            next
            (Nat.mod
              (Nat.add
                (Nat.mul hash 31)
                (Char.toNat char))
              65521)

def psKernelEnvironmentNameHash
    (name : PsKernelName) :
    Nat :=
  match name with
  | PsKernelName.anonymous =>
      0
  | PsKernelName.str parent value =>
      psKernelEnvironmentHashStringWorker
        (Nat.succ
          (String.utf8ByteSize value))
        value
        0
        (Nat.mod
          (Nat.add
            (Nat.mul
              (psKernelEnvironmentNameHash parent)
              31)
            1)
          65521)
  | PsKernelName.num parent value =>
      Nat.mod
        (Nat.add
          (Nat.add
            (Nat.mul
              (psKernelEnvironmentNameHash parent)
              31)
            2)
          value)
        65521

def psKernelEnvironmentIndexSmallLimit : Nat :=
  8

def psKernelEnvironmentIndexListLength
    (constants : List PsKernelConstantInfo) :
    Nat :=
  match constants with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ
        (psKernelEnvironmentIndexListLength rest)

def psKernelEnvironmentIndexFindWorker
    (fuel : Nat) :
    PsKernelEnvironmentIndex ->
    Nat ->
    List PsKernelConstantInfo :=
  match fuel with
  | Nat.zero =>
      fun
        (index : PsKernelEnvironmentIndex)
        (_hash : Nat) =>
        match index with
        | PsKernelEnvironmentIndex.bucket constants =>
            constants
        | _ =>
            List.nil
  | Nat.succ remaining =>
      let smaller :
          PsKernelEnvironmentIndex ->
          Nat ->
          List PsKernelConstantInfo :=
        psKernelEnvironmentIndexFindWorker remaining;
      fun
        (index : PsKernelEnvironmentIndex)
        (hash : Nat) =>
        match index with
        | PsKernelEnvironmentIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then
              smaller
                left
                (Nat.div hash 2)
            else
              smaller
                right
                (Nat.div hash 2)
        | _ =>
            List.nil

def psKernelEnvironmentIndexSetWorker
    (fuel : Nat) :
    PsKernelEnvironmentIndex ->
    Nat ->
    List PsKernelConstantInfo ->
    PsKernelEnvironmentIndex :=
  match fuel with
  | Nat.zero =>
      fun
        (_index : PsKernelEnvironmentIndex)
        (_hash : Nat)
        (constants : List PsKernelConstantInfo) =>
        PsKernelEnvironmentIndex.bucket constants
  | Nat.succ remaining =>
      let smaller :
          PsKernelEnvironmentIndex ->
          Nat ->
          List PsKernelConstantInfo ->
          PsKernelEnvironmentIndex :=
        psKernelEnvironmentIndexSetWorker remaining;
      fun
        (index : PsKernelEnvironmentIndex)
        (hash : Nat)
        (constants : List PsKernelConstantInfo) =>
        let left : PsKernelEnvironmentIndex :=
          match index with
          | PsKernelEnvironmentIndex.branch value _ =>
              value
          | _ =>
              PsKernelEnvironmentIndex.empty;
        let right : PsKernelEnvironmentIndex :=
          match index with
          | PsKernelEnvironmentIndex.branch _ value =>
              value
          | _ =>
              PsKernelEnvironmentIndex.empty;
        if Nat.beq (Nat.mod hash 2) 0 then
          PsKernelEnvironmentIndex.branch
            (smaller
              left
              (Nat.div hash 2)
              constants)
            right
        else
          PsKernelEnvironmentIndex.branch
            left
            (smaller
              right
              (Nat.div hash 2)
              constants)

def psKernelEnvironmentIndexRemoveNameWorker
    (constants : List PsKernelConstantInfo) :
    PsKernelName ->
    List PsKernelConstantInfo :=
  match constants with
  | List.nil =>
      fun (_name : PsKernelName) =>
        List.nil
  | List.cons info rest =>
      let smaller :
          PsKernelName ->
          List PsKernelConstantInfo :=
        psKernelEnvironmentIndexRemoveNameWorker rest;
      fun (name : PsKernelName) =>
        if
            psKernelNameEq
              (psKernelConstantInfoName info)
              name then
          smaller name
        else
          List.cons
            info
            (smaller name)

def psKernelEnvironmentIndexRemoveName
    (name : PsKernelName)
    (constants : List PsKernelConstantInfo) :
    List PsKernelConstantInfo :=
  psKernelEnvironmentIndexRemoveNameWorker
    constants
    name

def psKernelEnvironmentIndexBuild
    (constants : List PsKernelConstantInfo) :
    PsKernelEnvironmentIndex :=
  match constants with
  | List.nil =>
      PsKernelEnvironmentIndex.empty
  | List.cons info rest =>
      let index :=
        psKernelEnvironmentIndexBuild rest;
      let name :=
        psKernelConstantInfoName info;
      let hash :=
        psKernelEnvironmentNameHash name;
      let bucket :=
        psKernelEnvironmentIndexFindWorker
          16
          index
          hash;
      psKernelEnvironmentIndexSetWorker
        16
        index
        hash
        (List.cons
          info
          (psKernelEnvironmentIndexRemoveName
            name
            bucket))

def psKernelEnvironmentIndexFind
    (index : PsKernelEnvironmentIndex)
    (name : PsKernelName) :
    List PsKernelConstantInfo :=
  match index with
  | PsKernelEnvironmentIndex.empty =>
      List.nil
  | PsKernelEnvironmentIndex.small constants =>
      constants
  | PsKernelEnvironmentIndex.bucket constants =>
      constants
  | PsKernelEnvironmentIndex.branch _ _ =>
      psKernelEnvironmentIndexFindWorker
        16
        index
        (psKernelEnvironmentNameHash name)

def psKernelEnvironmentIndexInsert
    (index : PsKernelEnvironmentIndex)
    (info : PsKernelConstantInfo) :
    PsKernelEnvironmentIndex :=
  let name :=
    psKernelConstantInfoName info;
  match index with
  | PsKernelEnvironmentIndex.empty =>
      PsKernelEnvironmentIndex.small
        (List.cons info List.nil)
  | PsKernelEnvironmentIndex.small constants =>
      let next :=
        List.cons
          info
          (psKernelEnvironmentIndexRemoveName
            name
            constants);
      if
          Nat.ble
            (psKernelEnvironmentIndexListLength next)
            psKernelEnvironmentIndexSmallLimit then
        PsKernelEnvironmentIndex.small next
      else
        psKernelEnvironmentIndexBuild next
  | _ =>
      let hash :=
        psKernelEnvironmentNameHash name;
      let bucket :=
        psKernelEnvironmentIndexFindWorker
          16
          index
          hash;
      psKernelEnvironmentIndexSetWorker
        16
        index
        hash
        (List.cons
          info
          (psKernelEnvironmentIndexRemoveName
            name
            bucket))
