import Ps.BackendJs.Print

namespace JsAppliedPrefixReference

def psVerifiedIrIntDecimalMagnitudeWithFuel
    (remainingFuel : Nat) :
    String -> Nat -> Nat -> Nat :=
  match remainingFuel with
  | 0 =>
      fun (_text : String) (_position : Nat) (acc : Nat) =>
        acc
  | fuel + 1 =>
      let smaller : String -> Nat -> Nat -> Nat :=
        psVerifiedIrIntDecimalMagnitudeWithFuel fuel;
      fun (text : String) (position : Nat) (acc : Nat) =>
        if String.Internal.atEnd text (String.Pos.Raw.mk position) then
          acc
        else
          let char : Char :=
            String.Internal.get text (String.Pos.Raw.mk position);
          let digit : Nat :=
            Nat.sub (Char.toNat char) 48;
          let nextPosition : Nat :=
            String.Pos.Raw.byteIdx
              (String.Internal.next
                text
                (String.Pos.Raw.mk position));
          smaller
            text
            nextPosition
            (Nat.add (Nat.mul acc 10) digit)

def psJsTypeSupportedWithPolicyAndFuel
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (fuel : Nat) :
    PsVerifiedIrType -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_type : PsVerifiedIrType) => false
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrType -> Bool :=
        psJsTypeSupportedWithPolicyAndFuel
          profile uniform
          remaining;
      fun (type : PsVerifiedIrType) =>
        match type with
        | PsVerifiedIrType.primitive primitive =>
            psJsPrimitiveTypeSupportedWithProfile
              profile
              primitive
        | PsVerifiedIrType.function parameters result =>
            if psVerifiedIrListAll smaller parameters then
              smaller result
            else
              false
        | PsVerifiedIrType.named name arguments =>
            if psStringEq name "Array" then
              match arguments with
              | List.nil => false
              | List.cons elementType rest =>
                  match rest with
                  | List.nil => smaller elementType
                  | List.cons _ _ => false
            else
              if uniform then psVerifiedIrListAll smaller arguments
              else psListIsEmpty arguments
        | PsVerifiedIrType.typeParameter _ => uniform
        | _ => false

-- Existing callers keep the closed specialization contract.
def psJsLowerExprWithPolicyAndFuel
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (fuel : Nat) :
    PsVerifiedIrExpr ->
      Except PsJsLowerError PsJsIrExpr :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsVerifiedIrExpr) =>
        Except.error PsJsLowerError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          PsVerifiedIrExpr ->
            Except PsJsLowerError PsJsIrExpr :=
        psJsLowerExprWithPolicyAndFuel
          profile uniform
          remaining;
      fun (expr : PsVerifiedIrExpr) =>
        match expr with
        | PsVerifiedIrExpr.literal literal =>
            match
                psJsLowerLiteralWithProfile
                  profile
                  literal with
            | Except.error error => Except.error error
            | Except.ok value =>
                Except.ok (PsJsIrExpr.literal value)
        | PsVerifiedIrExpr.var name =>
            if psJsIdentifierSupported name then
              Except.ok (PsJsIrExpr.var name)
            else
              Except.error (PsJsLowerError.unsupportedName name)
        | PsVerifiedIrExpr.intrinsic
            operation
            typeArguments
            arguments =>
            if psListIsEmpty typeArguments then
              match operation with
              | PsVerifiedIrIntrinsic.machineIntBinary type integerOperation =>
                  match
                      psJsLowerMachineIntegerTypeWithProfile
                        profile
                        type with
                  | Except.error error => Except.error error
                  | Except.ok loweredType =>
                      psJsLowerBinaryWith
                        smaller
                        (PsJsIrBinaryOp.machineInt
                          loweredType
                          (psJsLowerIntegerBinaryOp integerOperation))
                        arguments
              | PsVerifiedIrIntrinsic.machineIntCompare type integerOperation =>
                  match
                      psJsLowerMachineIntegerTypeWithProfile
                        profile
                        type with
                  | Except.error error => Except.error error
                  | Except.ok _ =>
                      psJsLowerBinaryWith
                        smaller
                        (PsJsIrBinaryOp.machineIntCompare
                          (psJsLowerIntegerCompareOp integerOperation))
                        arguments
              | PsVerifiedIrIntrinsic.floatBinary type floatOperation =>
                  psJsLowerBinaryWith
                    smaller
                    (PsJsIrBinaryOp.floatBinary
                      (psJsLowerFloatingType type)
                      (psJsLowerFloatBinaryOp floatOperation))
                    arguments
              | PsVerifiedIrIntrinsic.floatCompare _ floatOperation =>
                  psJsLowerBinaryWith
                    smaller
                    (PsJsIrBinaryOp.floatCompare
                      (psJsLowerFloatCompareOp floatOperation))
                    arguments
              | PsVerifiedIrIntrinsic.natAdd =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintAdd arguments
              | PsVerifiedIrIntrinsic.natSub =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.natSub arguments
              | PsVerifiedIrIntrinsic.natMul =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintMul arguments
              | PsVerifiedIrIntrinsic.natDiv =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.natDiv arguments
              | PsVerifiedIrIntrinsic.natMod =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.natMod arguments
              | PsVerifiedIrIntrinsic.natEq =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintEq arguments
              | PsVerifiedIrIntrinsic.natNe =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintNe arguments
              | PsVerifiedIrIntrinsic.natLe =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintLe arguments
              | PsVerifiedIrIntrinsic.natLt =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintLt arguments
              | PsVerifiedIrIntrinsic.intOfNat =>
                  psJsLowerIdentityWith smaller arguments
              | PsVerifiedIrIntrinsic.intRepr =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.intRepr arguments
              | PsVerifiedIrIntrinsic.intNegSucc =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.intNegSucc arguments
              | PsVerifiedIrIntrinsic.intNeg =>
                  psJsLowerUnaryWith
                    smaller PsJsIrUnaryOp.bigintNeg arguments
              | PsVerifiedIrIntrinsic.intAdd =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintAdd arguments
              | PsVerifiedIrIntrinsic.intSub =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintSub arguments
              | PsVerifiedIrIntrinsic.intMul =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintMul arguments
              | PsVerifiedIrIntrinsic.intEq =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintEq arguments
              | PsVerifiedIrIntrinsic.intLe =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintLe arguments
              | PsVerifiedIrIntrinsic.intLt =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintLt arguments
              | PsVerifiedIrIntrinsic.boolNot =>
                  psJsLowerUnaryWith
                    smaller PsJsIrUnaryOp.boolNot arguments
              | PsVerifiedIrIntrinsic.boolAnd =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.boolAnd arguments
              | PsVerifiedIrIntrinsic.boolOr =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.boolOr arguments
              | PsVerifiedIrIntrinsic.boolEq =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.boolEq arguments
              | PsVerifiedIrIntrinsic.boolNe =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.boolNe arguments
              | PsVerifiedIrIntrinsic.charOfNat =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.charOfNat arguments
              | PsVerifiedIrIntrinsic.charToNat =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.charToNat arguments
              | PsVerifiedIrIntrinsic.stringPush =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.stringConcat arguments
              | PsVerifiedIrIntrinsic.stringSingleton =>
                  psJsLowerIdentityWith smaller arguments
              | PsVerifiedIrIntrinsic.stringLength =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.stringLength arguments
              | PsVerifiedIrIntrinsic.stringAppend =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.stringConcat arguments
              | PsVerifiedIrIntrinsic.stringUtf8ByteSize =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.stringUtf8ByteSize arguments
              | PsVerifiedIrIntrinsic.stringNext =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.stringNext arguments
              | PsVerifiedIrIntrinsic.stringGet =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.stringGet arguments
              | PsVerifiedIrIntrinsic.stringAtEnd =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.stringAtEnd arguments
              | PsVerifiedIrIntrinsic.stringExtract =>
                  psJsLowerRuntimeTernaryWith
                    smaller PsJsIrRuntimeOp.stringExtract arguments
              | PsVerifiedIrIntrinsic.stringEq =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.stringEq arguments
              | _ =>
                  Except.error PsJsLowerError.unsupportedIntrinsic
            else
              match operation with
              | PsVerifiedIrIntrinsic.arrayEmptyWithCapacity =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayEmptyWithCapacity
                      1
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arraySize =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arraySize
                      1
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arrayPush =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayPush
                      2
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arrayGet =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayGet
                      2
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arrayGetD =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayGetD
                      3
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arraySet =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arraySet
                      3
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arraySetIfInBounds =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arraySetIfInBounds
                      3
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arrayMap =>
                  if
                      psJsTwoTypeArgumentsSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayMap
                      2
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arrayFoldl =>
                  if
                      psJsTwoTypeArgumentsSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayFoldl
                      5
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | _ =>
                  Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.lambda
            parameters
            resultType
            body =>
            if
                psJsTypeSupportedWithPolicy
                  profile uniform
                  resultType then
              match
                  psJsLowerParameterNamesWithPolicy
                    profile uniform
                    parameters with
              | Except.error error => Except.error error
              | Except.ok names =>
                  match smaller body with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      Except.ok
                        (PsJsIrExpr.lambda
                          names
                          loweredBody)
            else
              Except.error PsJsLowerError.unsupportedType
        | PsVerifiedIrExpr.call fn typeArguments arguments =>
            if psJsErasedTypeArgumentsSupported profile uniform typeArguments then
              match smaller fn with
              | Except.error error => Except.error error
              | Except.ok loweredFn =>
                  match psListMapExcept smaller arguments with
                  | Except.error error => Except.error error
                  | Except.ok loweredArguments =>
                      Except.ok
                        (PsJsIrExpr.call
                          loweredFn
                          loweredArguments)
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.letE
            name
            type
            value
            body =>
            if psJsIdentifierSupported name then
              if
                  psJsTypeSupportedWithPolicy
                    profile uniform
                    type then
                match smaller value with
                | Except.error error => Except.error error
                | Except.ok loweredValue =>
                    match smaller body with
                    | Except.error error => Except.error error
                    | Except.ok loweredBody =>
                        Except.ok
                          (PsJsIrExpr.letE
                            name
                            loweredValue
                            loweredBody)
              else
                Except.error PsJsLowerError.unsupportedType
            else
              Except.error
                (PsJsLowerError.unsupportedName name)
        | PsVerifiedIrExpr.ifE
            condition
            thenBranch
            elseBranch =>
            match smaller condition with
            | Except.error error => Except.error error
            | Except.ok loweredCondition =>
                match smaller thenBranch with
                | Except.error error => Except.error error
                | Except.ok loweredThen =>
                    match smaller elseBranch with
                    | Except.error error => Except.error error
                    | Except.ok loweredElse =>
                        Except.ok
                          (PsJsIrExpr.ifE
                            loweredCondition
                            loweredThen
                            loweredElse)
        | PsVerifiedIrExpr.record
            _structureName
            typeArguments
            fields =>
            if psJsErasedTypeArgumentsSupported profile uniform typeArguments then
              match psJsLowerFieldsWith smaller fields with
              | Except.error error => Except.error error
              | Except.ok loweredFields =>
                  Except.ok
                    (PsJsIrExpr.record loweredFields)
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.projection
            _structureName
            typeArguments
            target
            field =>
            if psJsErasedTypeArgumentsSupported profile uniform typeArguments then
              match smaller target with
              | Except.error error => Except.error error
              | Except.ok loweredTarget =>
                  Except.ok
                    (PsJsIrExpr.projection
                      loweredTarget
                      field)
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.constructor
            _inductiveName
            constructorName
            typeArguments
            fields =>
            if psJsErasedTypeArgumentsSupported profile uniform typeArguments then
              match psJsLowerFieldsWith smaller fields with
              | Except.error error => Except.error error
              | Except.ok loweredFields =>
                  Except.ok
                    (PsJsIrExpr.constructor
                      constructorName
                      loweredFields)
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.matchE
            _inductiveName
            typeArguments
            scrutinee
            alternatives =>
            if psJsErasedTypeArgumentsSupported profile uniform typeArguments then
              match smaller scrutinee with
              | Except.error error => Except.error error
              | Except.ok loweredScrutinee =>
                  match
                      psJsLowerMatchAlternativesWithPolicy
                        profile uniform
                        smaller
                        alternatives with
                  | Except.error error => Except.error error
                  | Except.ok loweredAlternatives =>
                      Except.ok
                        (PsJsIrExpr.matchE
                          loweredScrutinee
                          loweredAlternatives)
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported

-- Existing callers keep the closed specialization contract.
def psJsValidationAppendNames
    (left : List String) :
    List String -> List String :=
  match left with
  | List.nil =>
      fun (right : List String) => right
  | List.cons value rest =>
      let smaller : List String -> List String :=
        psJsValidationAppendNames rest;
      fun (right : List String) =>
        List.cons value (smaller right)

def psJsValidationAddBindings
    (bindings : List PsJsIrMatchBinding) :
    List String -> List String :=
  match bindings with
  | List.nil =>
      fun (locals : List String) => locals
  | List.cons binding rest =>
      let smaller : List String -> List String :=
        psJsValidationAddBindings rest;
      fun (locals : List String) =>
        smaller
          (List.cons binding.name locals)

def psJsValidateExprWithFuel
    (globals : List String)
    (fuel : Nat) :
    List String ->
    PsJsIrExpr ->
      Except PsJsIrValidationError Unit :=
  match fuel with
  | Nat.zero =>
      fun
        (_locals : List String)
        (_expr : PsJsIrExpr) =>
        Except.error
          PsJsIrValidationError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          List String ->
          PsJsIrExpr ->
            Except PsJsIrValidationError Unit :=
        psJsValidateExprWithFuel
          globals
          remaining;
      fun
        (locals : List String)
        (expr : PsJsIrExpr) =>
        let validateCurrent :
            PsJsIrExpr ->
              Except PsJsIrValidationError Unit :=
          fun (nested : PsJsIrExpr) =>
            smaller locals nested;
        match expr with
        | PsJsIrExpr.literal literal =>
            psJsValidateLiteral literal
        | PsJsIrExpr.var name =>
            if psJsValidationContains name locals then
              Except.ok Unit.unit
            else if psJsValidationContains name globals then
              Except.ok Unit.unit
            else
              Except.error
                (PsJsIrValidationError.unknownVariable name)
        | PsJsIrExpr.unary _ value =>
            validateCurrent value
        | PsJsIrExpr.binary _ left right =>
            match validateCurrent left with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                validateCurrent right
        | PsJsIrExpr.runtime operation arguments =>
            if
                Nat.beq
                  (psListLength arguments)
                  (psJsRuntimeArity operation) then
              psJsValidationExprListWith
                validateCurrent
                arguments
            else
              Except.error
                PsJsIrValidationError.invalidRuntimeArity
        | PsJsIrExpr.lambda parameters body =>
            if psJsValidationUnique parameters then
              if psJsValidationNamesSupported parameters then
                smaller
                  (psJsValidationAppendNames
                    parameters
                    locals)
                  body
              else
                Except.error
                  (PsJsIrValidationError.invalidIdentifier "")
            else
              Except.error
                (PsJsIrValidationError.duplicateParameter "")
        | PsJsIrExpr.call fn arguments =>
            match validateCurrent fn with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                psJsValidationExprListWith
                  validateCurrent
                  arguments
        | PsJsIrExpr.letE name value body =>
            if psJsIdentifierSupported name then
              match validateCurrent value with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  smaller
                    (List.cons name locals)
                    body
            else
              Except.error
                (PsJsIrValidationError.invalidIdentifier name)
        | PsJsIrExpr.ifE condition thenBranch elseBranch =>
            match validateCurrent condition with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                match validateCurrent thenBranch with
                | Except.error error =>
                    Except.error error
                | Except.ok _ =>
                    validateCurrent elseBranch
        | PsJsIrExpr.record fields =>
            psJsValidationFieldsWith
              validateCurrent
              fields
        | PsJsIrExpr.projection target _ =>
            validateCurrent target
        | PsJsIrExpr.constructor _ fields =>
            psJsValidationFieldsWith
              validateCurrent
              fields
        | PsJsIrExpr.matchE scrutinee alternatives =>
            match validateCurrent scrutinee with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                psJsValidationAlternativesWith
                  smaller
                  locals
                  alternatives

def psJsTailDrop (count : Nat) : List PsJsIrExpr -> List PsJsIrExpr :=
  match count with
  | Nat.zero => fun (values : List PsJsIrExpr) => values
  | Nat.succ remaining =>
      let smaller : List PsJsIrExpr -> List PsJsIrExpr := psJsTailDrop remaining;
      fun (values : List PsJsIrExpr) =>
        match values with
        | List.nil => List.nil
        | List.cons _ rest => smaller rest

def psJsTailEtaSuffix (parameters : List String) : List PsJsIrExpr -> Bool :=
  match parameters with
  | List.nil => fun (arguments : List PsJsIrExpr) => psListIsEmpty arguments
  | List.cons parameter rest =>
      let smaller : List PsJsIrExpr -> Bool := psJsTailEtaSuffix rest;
      fun (arguments : List PsJsIrExpr) =>
        match arguments with
        | List.nil => false
        | List.cons argument others =>
            match argument with
            | PsJsIrExpr.var name => if psStringEq parameter name then smaller others else false
            | _ => false

def psJsTailCaptureBindings (available : String -> Bool) (scope : Nat)
    (names : List String) : Nat -> Option (List (Prod String String)) :=
  match names with
  | List.nil => fun (_index : Nat) => Option.some List.nil
  | List.cons name rest =>
      let smaller : Nat -> Option (List (Prod String String)) := psJsTailCaptureBindings available scope rest;
      fun (index : Nat) =>
        let fresh := String.Internal.append "__ps$tail$capture$"
          (String.Internal.append (psNatToString scope) (String.Internal.append "$" (psNatToString index)));
        if available fresh then
          match smaller (Nat.succ index) with
          | Option.none => Option.none
          | Option.some bindings => Option.some (List.cons (Prod.mk name fresh) bindings)
        else Option.none

def psJsTailRewriteWithFuel (declaration : PsJsIrDeclaration)
    (uses : PsJsIrExpr -> String -> Bool) (available : String -> Bool) (fuel : Nat) :
    List String -> List PsJsTailAlias -> PsJsIrExpr -> Option PsJsIrExpr :=
  match fuel with
  | Nat.zero => fun (_locals : List String) (_aliases : List PsJsTailAlias) (_expr : PsJsIrExpr) => Option.none
  | Nat.succ remaining =>
      let smaller : List String -> List PsJsTailAlias -> PsJsIrExpr -> Option PsJsIrExpr :=
        psJsTailRewriteWithFuel declaration uses available remaining;
      fun (locals : List String) (aliases : List PsJsTailAlias) (expr : PsJsIrExpr) =>
        if psJsTailContains locals declaration.name then Option.none
        else
          match expr with
          | PsJsIrExpr.letE name value body =>
              let visible := psJsTailAliasHide [name] aliases;
              match psJsTailRecognizeAlias declaration available locals remaining name value with
              | Option.some alias =>
                  if psListAny (psJsTailCaptureIsAlias aliases) alias.captures then Option.none
                  else
                    match smaller (List.cons name locals) (List.cons alias visible) body with
                    | Option.none => Option.none
                    | Option.some rewritten => Option.some (psJsTailCaptureLets alias.captures rewritten)
              | Option.none =>
                  if psJsTailAliasMentioned uses aliases value then Option.none
                  else
                    match smaller (List.cons name locals) visible body with
                    | Option.none => Option.none
                    | Option.some rewritten => Option.some (PsJsIrExpr.letE name value rewritten)
          | PsJsIrExpr.ifE condition yes no =>
              if psJsTailAliasMentioned uses aliases condition then Option.none
              else
                match smaller locals aliases yes with
                | Option.none => Option.none
                | Option.some left =>
                    match smaller locals aliases no with
                    | Option.none => Option.none
                    | Option.some right => Option.some (PsJsIrExpr.ifE condition left right)
          | PsJsIrExpr.matchE scrutinee alternatives =>
              if psJsTailAliasMentioned uses aliases scrutinee then Option.none
              else
                match psJsTailRewriteAlternatives smaller locals aliases alternatives with
                | Option.none => Option.none
                | Option.some values => Option.some (PsJsIrExpr.matchE scrutinee values)
          | PsJsIrExpr.call fn arguments =>
              match fn with
              | PsJsIrExpr.var name =>
                  match psJsTailAliasFind aliases name with
                  | Option.none =>
                      if psJsTailAliasMentioned uses aliases expr then Option.none else Option.some expr
                  | Option.some alias =>
                      if Nat.beq alias.arity (psListLength arguments) then
                        if psListAny (psJsTailAliasMentioned uses aliases) arguments then Option.none
                        else Option.some (PsJsIrExpr.call (PsJsIrExpr.var declaration.name)
                          (psListAppend (psJsTailCapturedArgs alias.captures) arguments))
                      else Option.none
              | _ => if psJsTailAliasMentioned uses aliases expr then Option.none else Option.some expr
          | _ => if psJsTailAliasMentioned uses aliases expr then Option.none else Option.some expr

def psJsPrintDeclarationsObservedWith
    (print : PsJsIrDeclaration -> Except PsJsEmitError String)
    (declarations : List PsJsIrDeclaration) :
    Bool -> PsTextBuilder -> PsJsGeneratedPosition ->
    List PsJsGeneratedDeclarationSpan -> Except PsJsEmitError PsJsPrintedModule :=
  match declarations with
  | List.nil =>
      fun (_observe : Bool) (builder : PsTextBuilder)
          (_position : PsJsGeneratedPosition) (spansRev : List PsJsGeneratedDeclarationSpan) =>
        Except.ok
          (PsJsPrintedModule.mk (psTextBuilderFinish builder) (psListReverse spansRev))
  | List.cons declaration rest =>
      let smaller :
          Bool -> PsTextBuilder -> PsJsGeneratedPosition ->
          List PsJsGeneratedDeclarationSpan -> Except PsJsEmitError PsJsPrintedModule :=
        psJsPrintDeclarationsObservedWith print rest;
      fun (observe : Bool) (builder : PsTextBuilder)
          (position : PsJsGeneratedPosition) (spansRev : List PsJsGeneratedDeclarationSpan) =>
        match print declaration with
        | Except.error error => Except.error error
        | Except.ok printed =>
            let nextBuilder : PsTextBuilder := psTextBuilderAppend builder printed;
            if observe then
              match psJsAdvanceGeneratedText position printed with
              | Except.error error => Except.error error
              | Except.ok nextPosition =>
                  smaller true nextBuilder nextPosition
                    (List.cons
                      (PsJsGeneratedDeclarationSpan.mk declaration.name position nextPosition)
                      spansRev)
            else smaller false nextBuilder position spansRev

end JsAppliedPrefixReference
