import Ps.Erasure.Expr

namespace PsKernelCompilerStringAliasProofs

-- Verbatim original primitive dispatch from d732, with only the declaration name changed.
private def frozenPrimitiveApplication
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (erase :
      PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) :=
  match view.head with
  | .constE name _ =>
      let text := psNameToString name;
      let binary : PsVerifiedIrIntrinsic -> Except PsErasureError (Option PsVerifiedIrExpr) :=
        fun (operation : PsVerifiedIrIntrinsic) =>
          if Nat.beq (psListLength view.args) 2 then
            match
                psEraseMappedIntrinsic
                  erase
                  operation
                  view.args with
            | Except.error error => Except.error error
            | Except.ok result => Except.ok (Option.some result)
          else
            Except.error PsErasureError.unsupportedApplication;
      let productProjection : Nat -> Except PsErasureError (Option PsVerifiedIrExpr) :=
        fun (index : Nat) =>
          if Nat.beq (psListLength view.args) 3 then
            match psErasureExprListAt view.args 2 with
            | Option.none => Except.error PsErasureError.unsupportedApplication
            | Option.some value =>
                match erase (PsExpr.proj psProdName index value) with
                | Except.error error => Except.error error
                | Except.ok result => Except.ok (Option.some result)
          else Except.error PsErasureError.unsupportedApplication;
      if psStringEq text "Prod.fst" then productProjection 0
      else if psStringEq text "Prod.snd" then productProjection 1
      else if psStringEq text "Int.ofNat" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.intOfNat
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Int.repr" then
        if Nat.beq (psListLength view.args) 1 then
          match psEraseMappedIntrinsic erase PsVerifiedIrIntrinsic.intRepr view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Int.negSucc" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.intNegSucc
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Int.neg" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.intNeg
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Int.add" then
        binary PsVerifiedIrIntrinsic.intAdd
      else if psStringEq text "Int.sub" then
        binary PsVerifiedIrIntrinsic.intSub
      else if psStringEq text "Int.mul" then
        binary PsVerifiedIrIntrinsic.intMul
      else if psStringEq text "Nat.succ" then
        match view.args with
        | List.nil => Except.error PsErasureError.unsupportedApplication
        | List.cons argument rest =>
            match rest with
            | List.cons _ _ => Except.error PsErasureError.unsupportedApplication
            | List.nil =>
                match erase argument with
                | Except.error error => Except.error error
                | Except.ok value =>
                    Except.ok (Option.some
                      (PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.natAdd []
                        [value, PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)]))
      else if psStringEq text "Nat.add" then
        binary PsVerifiedIrIntrinsic.natAdd
      else if psStringEq text "Nat.sub" then
        binary PsVerifiedIrIntrinsic.natSub
      else if psStringEq text "Nat.mul" then
        binary PsVerifiedIrIntrinsic.natMul
      else if psStringEq text "Nat.div" then
        binary PsVerifiedIrIntrinsic.natDiv
      else if psStringEq text "Nat.mod" then
        binary PsVerifiedIrIntrinsic.natMod
      else if psStringEq text "Nat.beq" then
        binary PsVerifiedIrIntrinsic.natEq
      else if psStringEq text "Nat.ble" then
        binary PsVerifiedIrIntrinsic.natLe
      else if psStringEq text "Nat.blt" then
        binary PsVerifiedIrIntrinsic.natLt
      else if psStringEq text "Bool.and" then
        binary PsVerifiedIrIntrinsic.boolAnd
      else if psStringEq text "Bool.or" then
        binary PsVerifiedIrIntrinsic.boolOr
      else if psStringEq text "Bool.not" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.boolNot
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Char.ofNat" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.charOfNat
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "Char.toNat" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.charToNat
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.Pos.Raw.mk" then
        match view.args with
        | List.cons value rest =>
            match rest with
            | List.nil =>
                match erase value with
                | Except.error error => Except.error error
                | Except.ok result => Except.ok (Option.some result)
            | List.cons _ _ =>
                Except.error PsErasureError.unsupportedApplication
        | _ =>
            Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.Pos.Raw.byteIdx" then
        match view.args with
        | List.cons value rest =>
            match rest with
            | List.nil =>
                match erase value with
                | Except.error error => Except.error error
                | Except.ok result => Except.ok (Option.some result)
            | List.cons _ _ =>
                Except.error PsErasureError.unsupportedApplication
        | _ =>
            Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.push" then
        binary PsVerifiedIrIntrinsic.stringPush
      else if psStringEq text "String.singleton" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringSingleton
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.Internal.length" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringLength
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.Internal.append" ||
              psStringEq text "String.append" then
        binary PsVerifiedIrIntrinsic.stringAppend
      else if psStringEq text "String.utf8ByteSize" then
        if Nat.beq (psListLength view.args) 1 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringUtf8ByteSize
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psStringEq text "String.Internal.next" ||
              psStringEq text "String.Pos.Raw.next" then
        binary PsVerifiedIrIntrinsic.stringNext
      else if psStringEq text "String.Internal.get" then
        binary PsVerifiedIrIntrinsic.stringGet
      else if psStringEq text "String.Internal.atEnd" ||
              psStringEq text "String.Pos.Raw.atEnd" then
        binary PsVerifiedIrIntrinsic.stringAtEnd
      else if psStringEq text "String.Internal.extract" then
        if Nat.beq (psListLength view.args) 3 then
          match
              psEraseMappedIntrinsic
                erase
                PsVerifiedIrIntrinsic.stringExtract
                view.args with
          | Except.error error => Except.error error
          | Except.ok result => Except.ok (Option.some result)
        else
          Except.error PsErasureError.unsupportedApplication
      else if psErasureBoolAnd (psStringEq text "Array.emptyWithCapacity") (Nat.beq (psListLength view.args) 2) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
              view.args [0] [1] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.size") (Nat.beq (psListLength view.args) 2) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arraySize
              view.args [0] [1] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.push") (Nat.beq (psListLength view.args) 3) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arrayPush
              view.args [0] [1, 2] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.getInternal") (Nat.beq (psListLength view.args) 4) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arrayGet
              view.args [0] [1, 2] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.getD") (Nat.beq (psListLength view.args) 4) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arrayGetD
              view.args [0] [1, 2, 3] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.set") (Nat.beq (psListLength view.args) 5) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arraySet
              view.args [0] [1, 2, 3] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.setIfInBounds") (Nat.beq (psListLength view.args) 4) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arraySetIfInBounds
              view.args [0] [1, 2, 3] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.map") (Nat.beq (psListLength view.args) 4) then
        match
            psEraseTypedIntrinsic
              environment scope erase
              PsVerifiedIrIntrinsic.arrayMap
              view.args [0, 1] [2, 3] with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else if psErasureBoolAnd (psStringEq text "Array.foldl") (Nat.beq (psListLength view.args) 7) then
        match
            psEraseArrayFoldl environment scope erase view.args with
        | Except.error error => Except.error error
        | Except.ok result => Except.ok (Option.some result)
      else
        Except.ok Option.none
  | _ => Except.ok Option.none

theorem portable_disjunction_exact_original (left right : Bool) :
    psErasureBoolOr left right = (left || right) := by
  cases left <;> rfl

theorem primitive_dispatch_exact_original_all_inputs
    (environment : PsEnvironment) (scope : PsErasureScope)
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    psErasePrimitiveApplication environment scope erase view =
      frozenPrimitiveApplication environment scope erase view := by
  simp only [psErasePrimitiveApplication, frozenPrimitiveApplication,
    portable_disjunction_exact_original]

end PsKernelCompilerStringAliasProofs

#print axioms PsKernelCompilerStringAliasProofs.portable_disjunction_exact_original
#print axioms PsKernelCompilerStringAliasProofs.primitive_dispatch_exact_original_all_inputs
