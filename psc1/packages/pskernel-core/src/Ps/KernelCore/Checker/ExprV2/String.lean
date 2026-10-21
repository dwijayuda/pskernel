import Ps.KernelCore.Checker.Context
import Ps.KernelCore.Core.ExprV2.TransformSpine

/- The scalar string-to-constructor translation is built directly in one
canonical DAG. UTF-8 byte positions, Char.ofNat values, universe arguments
and the predecessor placement match the original translation exactly. -/
def psKernelExprV2StringDataStop
    (arena : PsKernelExprV2PagedArena) (listNil : Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  match psKernelExprV2PagedRequire arena listNil with
  | Except.error error => Except.error error
  | Except.ok _ => Except.ok (Prod.mk arena listNil)

def psKernelExprV2StringConstructorDataWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> String -> Nat -> Nat -> Nat -> Nat ->
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  match fuel with
  | Nat.zero =>
      fun (arena : PsKernelExprV2PagedArena) (_value : String) (_position : Nat)
          (listNil _listCons _charOfNat : Nat) =>
        psKernelExprV2StringDataStop arena listNil
  | Nat.succ remaining =>
      fun (arena : PsKernelExprV2PagedArena) (value : String) (position : Nat)
          (listNil listCons charOfNat : Nat) =>
        if String.Internal.atEnd value (String.Pos.Raw.mk position) then
          psKernelExprV2StringDataStop arena listNil
        else
          let char := String.Internal.get value (String.Pos.Raw.mk position);
          let nextPosition :=
            String.Pos.Raw.byteIdx (String.Internal.next value (String.Pos.Raw.mk position));
          match psKernelExprV2PagedMkLit arena (PsKernelLiteral.nat (Char.toNat char)) with
          | Except.error error => Except.error error
          | Except.ok numeral =>
              match psKernelExprV2PagedMkApp (Prod.fst numeral) charOfNat (Prod.snd numeral) with
              | Except.error error => Except.error error
              | Except.ok charExpr =>
                  let recur := psKernelExprV2StringConstructorDataWithFuel remaining;
                  match recur (Prod.fst charExpr) value nextPosition listNil listCons charOfNat with
                  | Except.error error => Except.error error
                  | Except.ok rest =>
                      match psKernelExprV2PagedMkApp
                          (Prod.fst rest) listCons (Prod.snd charExpr) with
                      | Except.error error => Except.error error
                      | Except.ok head =>
                          psKernelExprV2PagedMkApp
                            (Prod.fst head) (Prod.snd head) (Prod.snd rest)

def psKernelExprV2StringLitToConstructorOnCanonical
    (arena : PsKernelExprV2PagedArena) (value : String) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  let zeroLevels := List.cons PsKernelLevel.zero List.nil;
  match psKernelExprV2PagedMkConst arena psKernelCharName List.nil with
  | Except.error error => Except.error error
  | Except.ok charType =>
      match psKernelExprV2PagedMkConst (Prod.fst charType) psKernelListNilName zeroLevels with
      | Except.error error => Except.error error
      | Except.ok nilHead =>
          match psKernelExprV2PagedMkApp
              (Prod.fst nilHead) (Prod.snd nilHead) (Prod.snd charType) with
          | Except.error error => Except.error error
          | Except.ok listNil =>
              match psKernelExprV2PagedMkConst
                  (Prod.fst listNil) psKernelListConsName zeroLevels with
              | Except.error error => Except.error error
              | Except.ok consHead =>
                  match psKernelExprV2PagedMkApp
                      (Prod.fst consHead) (Prod.snd consHead) (Prod.snd charType) with
                  | Except.error error => Except.error error
                  | Except.ok listCons =>
                      match psKernelExprV2PagedMkConst
                          (Prod.fst listCons) psKernelCharOfNatName List.nil with
                      | Except.error error => Except.error error
                      | Except.ok charOfNat =>
                          match psKernelExprV2StringConstructorDataWithFuel
                              (Nat.succ (String.utf8ByteSize value)) (Prod.fst charOfNat)
                              value 0 (Prod.snd listNil) (Prod.snd listCons)
                              (Prod.snd charOfNat) with
                          | Except.error error => Except.error error
                          | Except.ok data =>
                              match psKernelExprV2PagedMkConst
                                  (Prod.fst data) psKernelStringOfListName List.nil with
                              | Except.error error => Except.error error
                              | Except.ok head =>
                                  psKernelExprV2PagedMkApp
                                    (Prod.fst head) (Prod.snd head) (Prod.snd data)

def psKernelExprV2IsStringOfListAppOnCanonical
    (arena : PsKernelExprV2PagedArena) (root : Nat) : Except String Bool :=
  match psKernelExprV2PagedRequire arena root with
  | Except.error error => Except.error error
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.app fn _ =>
          match psKernelExprV2PagedRequire arena fn with
          | Except.error error => Except.error error
          | Except.ok head =>
              match head.node with
              | PsKernelExprV2Node.const name levels =>
                  match levels with
                  | List.nil => Except.ok (psKernelNameEq name psKernelStringOfListName)
                  | List.cons _ _ => Except.ok false
              | _ => Except.ok false
      | _ => Except.ok false
