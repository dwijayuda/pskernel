import Ps.BackendRust.Type

def psRustEmitExprListWith
    (emitExpr :
      PsVerifiedIrExpr ->
      Except PsRustEmitError String) :
    List PsVerifiedIrExpr ->
    Except PsRustEmitError (List String)
  | List.nil =>
      Except.ok List.nil
  | List.cons expr rest =>
      match emitExpr expr with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitExprListWith emitExpr rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons printed printedRest)

def psRustEmitFieldListWith
    (emitExpr :
      PsVerifiedIrExpr ->
      Except PsRustEmitError String) :
    List (Prod String PsVerifiedIrExpr) ->
    Except PsRustEmitError (List String)
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      match emitExpr (Prod.snd field) with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          let rendered :=
            psRustConcat3
              (Prod.fst field)
              ": "
              printed;
          match psRustEmitFieldListWith emitExpr rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustEmitParameterList
    (parameters : List PsVerifiedIrParameter) :
    Except PsRustEmitError (List String) :=
  match parameters with
  | List.nil =>
      Except.ok List.nil
  | List.cons parameter rest =>
      match psRustEmitType parameter.type with
      | Except.error error =>
          Except.error error
      | Except.ok printedType =>
          let rendered :=
            psRustConcat3
              parameter.name
              ": "
              printedType;
          match psRustEmitParameterList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustEmitIntrinsicFromPrinted
    (operation : PsVerifiedIrIntrinsic)
    (arguments : List String) :
    Except PsRustEmitError String :=
  match operation with
  | PsVerifiedIrIntrinsic.natAdd =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "__ps_nat_add(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natSub =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "__ps_nat_sub(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natMul =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "__ps_nat_mul(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natDiv =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "__ps_nat_div(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natMod =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "__ps_nat_mod(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natEq =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") == ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natNe =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") != ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natLe =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") <= ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natLt =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") < ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intOfNat =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_int_of_nat(&("
              value
              "))")
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intNegSucc =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_int_neg_succ(&("
              value
              "))")
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intNeg =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_int_neg(&("
              value
              "))")
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intAdd =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "__ps_int_add(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intSub =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "__ps_int_sub(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intMul =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "__ps_int_mul(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intEq =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") == ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intLe =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") <= ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intLt =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") < ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.boolNot =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3 "(!(" value "))")
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.boolAnd =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") && ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.boolOr =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") || ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.boolEq =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") == ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.boolNe =>
      match arguments with
      | List.cons left (List.cons right List.nil) =>
          Except.ok
            (psRustConcat4
              "(("
              left
              ") != ("
              (psRustConcat2 right "))"))
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | _ =>
      Except.error PsRustEmitError.unsupportedIntrinsic

def psRustEmitMatchBindings
    (bindings : List PsVerifiedIrMatchBinding) : String :=
  match bindings with
  | List.nil =>
      ""
  | List.cons binding rest =>
      let current :=
        psRustConcat3
          binding.field
          ": "
          binding.name;
      match rest with
      | List.nil =>
          current
      | List.cons _ _ =>
          psRustConcat3
            current
            ", "
            (psRustEmitMatchBindings rest)

def psRustEmitAlternativeListWith
    (emitExpr :
      PsVerifiedIrExpr ->
      Except PsRustEmitError String)
    (inductiveName : String) :
    List
      (Prod String
        (Prod
          (List PsVerifiedIrMatchBinding)
          PsVerifiedIrExpr)) ->
    Except PsRustEmitError (List String)
  | List.nil =>
      Except.ok List.nil
  | List.cons alternative rest =>
      let constructorName := Prod.fst alternative;
      let payload := Prod.snd alternative;
      let bindings := Prod.fst payload;
      let body := Prod.snd payload;
      match emitExpr body with
      | Except.error error =>
          Except.error error
      | Except.ok printedBody =>
          let pattern :=
            psRustConcat4
              inductiveName
              "::"
              constructorName
              (psRustConcat3
                " { "
                (psRustEmitMatchBindings bindings)
                " }");
          let rendered :=
            psRustConcat3
              pattern
              " => "
              printedBody;
          match psRustEmitAlternativeListWith
              emitExpr
              inductiveName
              rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustEmitExprWithFuel :
    Nat ->
    PsVerifiedIrExpr ->
    Except PsRustEmitError String
  | 0, _ =>
      Except.error PsRustEmitError.fuelExhausted
  | fuel + 1, expr =>
      let emitNested :=
        fun nested =>
          psRustEmitExprWithFuel fuel nested;
      match expr with
      | PsVerifiedIrExpr.literal literal =>
          Except.ok (psRustEmitLiteral literal)
      | PsVerifiedIrExpr.var name =>
          Except.ok name
      | PsVerifiedIrExpr.intrinsic operation arguments =>
          match psRustEmitExprListWith emitNested arguments with
          | Except.error error =>
              Except.error error
          | Except.ok printedArguments =>
              psRustEmitIntrinsicFromPrinted
                operation
                printedArguments
      | PsVerifiedIrExpr.lambda parameters body =>
          match psRustEmitParameterList parameters with
          | Except.error error =>
              Except.error error
          | Except.ok printedParameters =>
              match emitNested body with
              | Except.error error =>
                  Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    (psRustConcat4
                      "|"
                      (psRustJoin ", " printedParameters)
                      "| "
                      printedBody)
      | PsVerifiedIrExpr.call fn _ arguments =>
          match emitNested fn with
          | Except.error error =>
              Except.error error
          | Except.ok printedFn =>
              match psRustEmitExprListWith emitNested arguments with
              | Except.error error =>
                  Except.error error
              | Except.ok printedArguments =>
                  Except.ok
                    (psRustConcat4
                      "("
                      printedFn
                      ")("
                      (psRustConcat2
                        (psRustJoin ", " printedArguments)
                        ")"))
      | PsVerifiedIrExpr.letE name value body =>
          match emitNested value with
          | Except.error error =>
              Except.error error
          | Except.ok printedValue =>
              match emitNested body with
              | Except.error error =>
                  Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    (psRustConcat4
                      "{ let "
                      name
                      " = "
                      (psRustConcat4
                        printedValue
                        "; "
                        printedBody
                        " }"))
      | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
          match emitNested condition with
          | Except.error error =>
              Except.error error
          | Except.ok printedCondition =>
              match emitNested thenBranch with
              | Except.error error =>
                  Except.error error
              | Except.ok printedThen =>
                  match emitNested elseBranch with
                  | Except.error error =>
                      Except.error error
                  | Except.ok printedElse =>
                      Except.ok
                        (psRustConcat4
                          "(if "
                          printedCondition
                          " { "
                          (psRustConcat4
                            printedThen
                            " } else { "
                            printedElse
                            " })"))
      | PsVerifiedIrExpr.record structureName fields =>
          match psRustEmitFieldListWith emitNested fields with
          | Except.error error =>
              Except.error error
          | Except.ok printedFields =>
              Except.ok
                (psRustConcat4
                  structureName
                  " { "
                  (psRustJoin ", " printedFields)
                  " }")
      | PsVerifiedIrExpr.projection target field =>
          match emitNested target with
          | Except.error error =>
              Except.error error
          | Except.ok printedTarget =>
              Except.ok
                (psRustConcat4
                  "("
                  printedTarget
                  ")."
                  field)
      | PsVerifiedIrExpr.constructor
          inductiveName
          constructorName
          _
          fields =>
          match psRustEmitFieldListWith emitNested fields with
          | Except.error error =>
              Except.error error
          | Except.ok printedFields =>
              match printedFields with
              | List.nil =>
                  Except.ok
                    (psRustConcat4
                      inductiveName
                      "::"
                      constructorName
                      "{}")
              | List.cons _ _ =>
                  Except.ok
                    (psRustConcat4
                      inductiveName
                      "::"
                      constructorName
                      (psRustConcat3
                        " { "
                        (psRustJoin ", " printedFields)
                        " }"))
      | PsVerifiedIrExpr.matchE
          inductiveName
          scrutinee
          alternatives =>
          match emitNested scrutinee with
          | Except.error error =>
              Except.error error
          | Except.ok printedScrutinee =>
              match psRustEmitAlternativeListWith
                  emitNested
                  inductiveName
                  alternatives with
              | Except.error error =>
                  Except.error error
              | Except.ok printedAlternatives =>
                  Except.ok
                    (psRustConcat4
                      "(match "
                      printedScrutinee
                      " { "
                      (psRustConcat2
                        (psRustJoin ", " printedAlternatives)
                        " })"))

def psRustEmitExpr
    (expr : PsVerifiedIrExpr) :
    Except PsRustEmitError String :=
  psRustEmitExprWithFuel 4096 expr
