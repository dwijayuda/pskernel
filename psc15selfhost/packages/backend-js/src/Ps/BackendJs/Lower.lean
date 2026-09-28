import Ps.CompilerIr.Model
import Ps.BackendJs.PortableText
import Ps.BackendJs.Model

structure PsJsLocalBinding where
  sourceName : String
  type : PsVerifiedIrPrimitiveType
  index : Nat

structure PsJsGlobalBinding where
  sourceName : String
  parameterTypes : List PsVerifiedIrPrimitiveType
  resultType : PsVerifiedIrPrimitiveType
  index : Nat

structure PsJsLoweredExpr where
  expr : PsJsExpr
  nextLocal : Nat

structure PsJsLoweredParameters where
  locals : List PsJsLocalBinding
  indexes : List Nat
  nextLocal : Nat

def psJsNameHead (value : Char) : Bool :=
  let code := Char.toNat value;
  if psJsTextNatInRange code 65 90 then true
  else if psJsTextNatInRange code 97 122 then true
  else if Nat.beq code 95 then true
  else Nat.beq code 36

def psJsNameTail (values : List Char) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest =>
      if psJsNameHead value then psJsNameTail rest
      else if psJsTextNatInRange (Char.toNat value) 48 57 then psJsNameTail rest
      else false

def psJsContainsName (values : List String) (name : String) : Bool :=
  match values with
  | List.nil => false
  | List.cons value rest =>
      if psJsTextStringEq value name then true
      else psJsContainsName rest name

def psJsReservedNames : List String :=
  ["await", "break", "case", "catch", "class", "const", "continue",
   "debugger", "default", "delete", "do", "else", "enum", "export",
   "extends", "false", "finally", "for", "function", "if", "implements",
   "import", "in", "instanceof", "interface", "let", "new", "null",
   "package", "private", "protected", "public", "return", "static",
   "super", "switch", "this", "throw", "true", "try", "typeof", "var",
   "void", "while", "with", "yield", "eval", "arguments"]

def psJsValidExportName (name : String) : Bool :=
  if psJsContainsName psJsReservedNames name then false
  else
    match psJsTextStringToChars name with
    | List.nil => false
    | List.cons head tail =>
        if psJsNameHead head then psJsNameTail tail else false

def psJsPrimitiveTypeEq (left right : PsVerifiedIrPrimitiveType) : Bool :=
  match left with
  | PsVerifiedIrPrimitiveType.nat =>
      match right with | PsVerifiedIrPrimitiveType.nat => true | _ => false
  | PsVerifiedIrPrimitiveType.int =>
      match right with | PsVerifiedIrPrimitiveType.int => true | _ => false
  | PsVerifiedIrPrimitiveType.uint8 =>
      match right with | PsVerifiedIrPrimitiveType.uint8 => true | _ => false
  | PsVerifiedIrPrimitiveType.uint16 =>
      match right with | PsVerifiedIrPrimitiveType.uint16 => true | _ => false
  | PsVerifiedIrPrimitiveType.uint32 =>
      match right with | PsVerifiedIrPrimitiveType.uint32 => true | _ => false
  | PsVerifiedIrPrimitiveType.uint64 =>
      match right with | PsVerifiedIrPrimitiveType.uint64 => true | _ => false
  | PsVerifiedIrPrimitiveType.usize =>
      match right with | PsVerifiedIrPrimitiveType.usize => true | _ => false
  | PsVerifiedIrPrimitiveType.int8 =>
      match right with | PsVerifiedIrPrimitiveType.int8 => true | _ => false
  | PsVerifiedIrPrimitiveType.int16 =>
      match right with | PsVerifiedIrPrimitiveType.int16 => true | _ => false
  | PsVerifiedIrPrimitiveType.int32 =>
      match right with | PsVerifiedIrPrimitiveType.int32 => true | _ => false
  | PsVerifiedIrPrimitiveType.int64 =>
      match right with | PsVerifiedIrPrimitiveType.int64 => true | _ => false
  | PsVerifiedIrPrimitiveType.isize =>
      match right with | PsVerifiedIrPrimitiveType.isize => true | _ => false
  | PsVerifiedIrPrimitiveType.float =>
      match right with | PsVerifiedIrPrimitiveType.float => true | _ => false
  | PsVerifiedIrPrimitiveType.float32 =>
      match right with | PsVerifiedIrPrimitiveType.float32 => true | _ => false
  | PsVerifiedIrPrimitiveType.bool =>
      match right with | PsVerifiedIrPrimitiveType.bool => true | _ => false
  | PsVerifiedIrPrimitiveType.char =>
      match right with | PsVerifiedIrPrimitiveType.char => true | _ => false
  | PsVerifiedIrPrimitiveType.string =>
      match right with | PsVerifiedIrPrimitiveType.string => true | _ => false
  | PsVerifiedIrPrimitiveType.unit =>
      match right with | PsVerifiedIrPrimitiveType.unit => true | _ => false

def psJsPrimitiveTypeSupported (type : PsVerifiedIrPrimitiveType) : Bool :=
  match type with
  | PsVerifiedIrPrimitiveType.nat => true
  | PsVerifiedIrPrimitiveType.int => true
  | PsVerifiedIrPrimitiveType.bool => true
  | PsVerifiedIrPrimitiveType.string => true
  | PsVerifiedIrPrimitiveType.unit => true
  | _ => false

def psJsLookupLocal (locals : List PsJsLocalBinding)
    (name : String) : Option PsJsLocalBinding :=
  match locals with
  | List.nil => Option.none
  | List.cons binding rest =>
      if psJsTextStringEq binding.sourceName name then Option.some binding
      else psJsLookupLocal rest name

def psJsLookupGlobal (globals : List PsJsGlobalBinding)
    (name : String) : Option PsJsGlobalBinding :=
  match globals with
  | List.nil => Option.none
  | List.cons binding rest =>
      if psJsTextStringEq binding.sourceName name then Option.some binding
      else psJsLookupGlobal rest name

def psJsLowerParameterTypes (parameters : List PsVerifiedIrParameter) :
    Except PsJsError (List PsVerifiedIrPrimitiveType) :=
  match parameters with
  | List.nil => Except.ok List.nil
  | List.cons parameter rest =>
      match parameter.type with
      | PsVerifiedIrType.primitive primitive =>
          if psJsPrimitiveTypeSupported primitive then
            match psJsLowerParameterTypes rest with
            | Except.error error => Except.error error
            | Except.ok lowered => Except.ok (List.cons primitive lowered)
          else Except.error PsJsError.unsupportedExpression
      | _ => Except.error PsJsError.unsupportedExpression

def psJsBuildGlobals (declarations : List PsVerifiedIrDeclaration) :
    Nat -> List String -> Except PsJsError (List PsJsGlobalBinding) :=
  match declarations with
  | List.nil =>
      fun (_index : Nat) =>
        fun (_used : List String) => Except.ok List.nil
  | List.cons declaration rest =>
      let smaller :
          Nat -> List String -> Except PsJsError (List PsJsGlobalBinding) :=
        psJsBuildGlobals rest;
      fun (index : Nat) =>
        fun (used : List String) =>
          if psJsContainsName used declaration.name then
            Except.error (PsJsError.duplicateExport declaration.name)
          else if psJsValidExportName declaration.name then
            match declaration.typeParameters with
            | List.cons _ _ =>
                Except.error (PsJsError.unsupportedDeclaration declaration.name)
            | List.nil =>
                match declaration.resultType with
                | PsVerifiedIrType.primitive resultType =>
                    if psJsPrimitiveTypeSupported resultType then
                      match psJsLowerParameterTypes declaration.parameters with
                      | Except.error error => Except.error error
                      | Except.ok parameterTypes =>
                          match smaller
                            (Nat.succ index)
                            (List.cons declaration.name used) with
                          | Except.error error => Except.error error
                          | Except.ok globals =>
                              Except.ok (List.cons
                                (PsJsGlobalBinding.mk
                                  declaration.name
                                  parameterTypes
                                  resultType
                                  index)
                                globals)
                    else Except.error PsJsError.unsupportedExpression
                | _ => Except.error PsJsError.literalTypeMismatch
          else Except.error (PsJsError.invalidExportName declaration.name)

def psJsLowerParameters (parameters : List PsVerifiedIrParameter) :
    List PsJsLocalBinding -> Nat -> Except PsJsError PsJsLoweredParameters :=
  match parameters with
  | List.nil =>
      fun (locals : List PsJsLocalBinding) =>
        fun (nextLocal : Nat) =>
          Except.ok (PsJsLoweredParameters.mk locals List.nil nextLocal)
  | List.cons parameter rest =>
      let smaller :
          List PsJsLocalBinding -> Nat -> Except PsJsError PsJsLoweredParameters :=
        psJsLowerParameters rest;
      fun (locals : List PsJsLocalBinding) =>
        fun (nextLocal : Nat) =>
          match parameter.type with
          | PsVerifiedIrType.primitive primitive =>
              if psJsPrimitiveTypeSupported primitive then
                match psJsLookupLocal locals parameter.name with
                | Option.some _ => Except.error PsJsError.unsupportedExpression
                | Option.none =>
                    let binding := PsJsLocalBinding.mk parameter.name primitive nextLocal;
                    match smaller
                      (List.cons binding locals)
                      (Nat.succ nextLocal) with
                    | Except.error error => Except.error error
                    | Except.ok lowered =>
                        Except.ok (PsJsLoweredParameters.mk
                          lowered.locals
                          (List.cons nextLocal lowered.indexes)
                          lowered.nextLocal)
              else Except.error PsJsError.unsupportedExpression
          | _ => Except.error PsJsError.unsupportedExpression

def psJsLowerLiteral (value : PsVerifiedIrLiteral)
    (type : PsVerifiedIrPrimitiveType) : Except PsJsError PsJsLiteral :=
  match value with
  | PsVerifiedIrLiteral.natural number =>
      match type with
      | PsVerifiedIrPrimitiveType.nat => Except.ok (PsJsLiteral.natural number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrLiteral.integer number =>
      match type with
      | PsVerifiedIrPrimitiveType.int => Except.ok (PsJsLiteral.integer number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrLiteral.bool boolean =>
      match type with
      | PsVerifiedIrPrimitiveType.bool => Except.ok (PsJsLiteral.boolean boolean)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrLiteral.string text =>
      match type with
      | PsVerifiedIrPrimitiveType.string => Except.ok (PsJsLiteral.string text)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrLiteral.unit =>
      match type with
      | PsVerifiedIrPrimitiveType.unit => Except.ok PsJsLiteral.undefined
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrLiteral.machineInteger _ _ =>
      Except.error PsJsError.unsupportedExpression

def psJsLowerAtomicExprWithFuel (fuel : Nat) :
    PsVerifiedIrExpr -> List PsJsLocalBinding -> Nat ->
    PsVerifiedIrPrimitiveType -> Except PsJsError PsJsLoweredExpr :=
  match fuel with
  | Nat.zero =>
      fun (_body : PsVerifiedIrExpr) =>
        fun (_locals : List PsJsLocalBinding) =>
          fun (_nextLocal : Nat) =>
            fun (_expectedType : PsVerifiedIrPrimitiveType) =>
              Except.error PsJsError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          PsVerifiedIrExpr -> List PsJsLocalBinding -> Nat ->
          PsVerifiedIrPrimitiveType -> Except PsJsError PsJsLoweredExpr :=
        psJsLowerAtomicExprWithFuel remaining;
      fun (body : PsVerifiedIrExpr) =>
        fun (locals : List PsJsLocalBinding) =>
          fun (nextLocal : Nat) =>
            fun (expectedType : PsVerifiedIrPrimitiveType) =>
              match body with
              | PsVerifiedIrExpr.literal value =>
                  match psJsLowerLiteral value expectedType with
                  | Except.error error => Except.error error
                  | Except.ok lowered =>
                      Except.ok
                        (PsJsLoweredExpr.mk (PsJsExpr.literal lowered) nextLocal)
              | PsVerifiedIrExpr.var name =>
                  match psJsLookupLocal locals name with
                  | Option.none => Except.error PsJsError.unsupportedExpression
                  | Option.some binding =>
                      if psJsPrimitiveTypeEq binding.type expectedType then
                        Except.ok
                          (PsJsLoweredExpr.mk
                            (PsJsExpr.local binding.index)
                            nextLocal)
                      else Except.error PsJsError.literalTypeMismatch
              | PsVerifiedIrExpr.letE name type value innerBody =>
                  match type with
                  | PsVerifiedIrType.primitive localType =>
                      match smaller value locals nextLocal localType with
                      | Except.error error => Except.error error
                      | Except.ok loweredValue =>
                          let localIndex := loweredValue.nextLocal;
                          let binding :=
                            PsJsLocalBinding.mk name localType localIndex;
                          match smaller
                            innerBody
                            (List.cons binding locals)
                            (Nat.succ localIndex)
                            expectedType with
                          | Except.error error => Except.error error
                          | Except.ok loweredBody =>
                              Except.ok
                                (PsJsLoweredExpr.mk
                                  (PsJsExpr.letE
                                    localIndex
                                    loweredValue.expr
                                    loweredBody.expr)
                                  loweredBody.nextLocal)
                  | _ => Except.error PsJsError.unsupportedExpression
              | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
                  match smaller
                    condition
                    locals
                    nextLocal
                    PsVerifiedIrPrimitiveType.bool with
                  | Except.error error => Except.error error
                  | Except.ok loweredCondition =>
                      match smaller
                        thenBranch
                        locals
                        loweredCondition.nextLocal
                        expectedType with
                      | Except.error error => Except.error error
                      | Except.ok loweredThen =>
                          match smaller
                            elseBranch
                            locals
                            loweredThen.nextLocal
                            expectedType with
                          | Except.error error => Except.error error
                          | Except.ok loweredElse =>
                              Except.ok
                                (PsJsLoweredExpr.mk
                                  (PsJsExpr.ifE
                                    loweredCondition.expr
                                    loweredThen.expr
                                    loweredElse.expr)
                                  loweredElse.nextLocal)
              | _ => Except.error PsJsError.unsupportedExpression

def psJsLowerAtomicExpr (body : PsVerifiedIrExpr)
    (locals : List PsJsLocalBinding) (nextLocal : Nat)
    (expectedType : PsVerifiedIrPrimitiveType) : Except PsJsError PsJsLoweredExpr :=
  psJsLowerAtomicExprWithFuel 4096 body locals nextLocal expectedType

def psJsLowerAtomicArguments (parameterTypes : List PsVerifiedIrPrimitiveType) :
    List PsVerifiedIrExpr -> List PsJsLocalBinding -> Nat ->
    Except PsJsError (List PsJsExpr) :=
  match parameterTypes with
  | List.nil =>
      fun (arguments : List PsVerifiedIrExpr) =>
        fun (_locals : List PsJsLocalBinding) =>
          fun (_nextLocal : Nat) =>
            match arguments with
            | List.nil => Except.ok List.nil
            | List.cons _ _ => Except.error PsJsError.unsupportedExpression
  | List.cons parameterType restTypes =>
      let smaller :
          List PsVerifiedIrExpr -> List PsJsLocalBinding -> Nat ->
          Except PsJsError (List PsJsExpr) :=
        psJsLowerAtomicArguments restTypes;
      fun (arguments : List PsVerifiedIrExpr) =>
        fun (locals : List PsJsLocalBinding) =>
          fun (nextLocal : Nat) =>
            match arguments with
            | List.nil => Except.error PsJsError.unsupportedExpression
            | List.cons argument restArguments =>
                match psJsLowerAtomicExpr
                  argument locals nextLocal parameterType with
                | Except.error error => Except.error error
                | Except.ok loweredArgument =>
                    match smaller
                      restArguments locals loweredArgument.nextLocal with
                    | Except.error error => Except.error error
                    | Except.ok loweredRest =>
                        Except.ok (List.cons loweredArgument.expr loweredRest)

def psJsLowerExprWorker (body : PsVerifiedIrExpr) :
    List PsJsGlobalBinding -> List PsJsLocalBinding -> Nat ->
    PsVerifiedIrPrimitiveType -> Except PsJsError PsJsLoweredExpr :=
  match body with
  | PsVerifiedIrExpr.literal value =>
      fun (_globals : List PsJsGlobalBinding) =>
        fun (locals : List PsJsLocalBinding) =>
          fun (nextLocal : Nat) =>
            fun (expectedType : PsVerifiedIrPrimitiveType) =>
              psJsLowerAtomicExpr
                (PsVerifiedIrExpr.literal value) locals nextLocal expectedType
  | PsVerifiedIrExpr.var name =>
      fun (_globals : List PsJsGlobalBinding) =>
        fun (locals : List PsJsLocalBinding) =>
          fun (nextLocal : Nat) =>
            fun (expectedType : PsVerifiedIrPrimitiveType) =>
              psJsLowerAtomicExpr
                (PsVerifiedIrExpr.var name) locals nextLocal expectedType
  | PsVerifiedIrExpr.call fn typeArguments arguments =>
      fun (globals : List PsJsGlobalBinding) =>
        fun (locals : List PsJsLocalBinding) =>
          fun (nextLocal : Nat) =>
            fun (expectedType : PsVerifiedIrPrimitiveType) =>
              match typeArguments with
              | List.cons _ _ => Except.error PsJsError.unsupportedExpression
              | List.nil =>
                  match fn with
                  | PsVerifiedIrExpr.var name =>
                      match psJsLookupGlobal globals name with
                      | Option.none => Except.error PsJsError.unsupportedExpression
                      | Option.some global =>
                          if psJsPrimitiveTypeEq global.resultType expectedType then
                            match global.parameterTypes with
                            | List.nil => Except.error PsJsError.unsupportedExpression
                            | List.cons _ _ =>
                                match psJsLowerAtomicArguments
                                  global.parameterTypes arguments locals nextLocal with
                                | Except.error error => Except.error error
                                | Except.ok loweredArguments =>
                                    Except.ok (PsJsLoweredExpr.mk
                                      (PsJsExpr.call
                                        (PsJsExpr.global global.index)
                                        loweredArguments)
                                      nextLocal)
                          else Except.error PsJsError.literalTypeMismatch
                  | _ => Except.error PsJsError.unsupportedExpression
  | PsVerifiedIrExpr.letE name type value innerBody =>
      let lowerValue :
          List PsJsGlobalBinding -> List PsJsLocalBinding -> Nat ->
          PsVerifiedIrPrimitiveType -> Except PsJsError PsJsLoweredExpr :=
        psJsLowerExprWorker value;
      let lowerBody :
          List PsJsGlobalBinding -> List PsJsLocalBinding -> Nat ->
          PsVerifiedIrPrimitiveType -> Except PsJsError PsJsLoweredExpr :=
        psJsLowerExprWorker innerBody;
      fun (globals : List PsJsGlobalBinding) =>
        fun (locals : List PsJsLocalBinding) =>
          fun (nextLocal : Nat) =>
            fun (expectedType : PsVerifiedIrPrimitiveType) =>
              match type with
              | PsVerifiedIrType.primitive localType =>
                  match lowerValue globals locals nextLocal localType with
                  | Except.error error => Except.error error
                  | Except.ok loweredValue =>
                      let localIndex := loweredValue.nextLocal;
                      let binding := PsJsLocalBinding.mk name localType localIndex;
                      match lowerBody
                        globals
                        (List.cons binding locals)
                        (Nat.succ localIndex)
                        expectedType with
                      | Except.error error => Except.error error
                      | Except.ok loweredBody =>
                          Except.ok (PsJsLoweredExpr.mk
                            (PsJsExpr.letE
                              localIndex
                              loweredValue.expr
                              loweredBody.expr)
                            loweredBody.nextLocal)
              | _ => Except.error PsJsError.unsupportedExpression
  | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
      let lowerCondition :
          List PsJsGlobalBinding -> List PsJsLocalBinding -> Nat ->
          PsVerifiedIrPrimitiveType -> Except PsJsError PsJsLoweredExpr :=
        psJsLowerExprWorker condition;
      let lowerThen :
          List PsJsGlobalBinding -> List PsJsLocalBinding -> Nat ->
          PsVerifiedIrPrimitiveType -> Except PsJsError PsJsLoweredExpr :=
        psJsLowerExprWorker thenBranch;
      let lowerElse :
          List PsJsGlobalBinding -> List PsJsLocalBinding -> Nat ->
          PsVerifiedIrPrimitiveType -> Except PsJsError PsJsLoweredExpr :=
        psJsLowerExprWorker elseBranch;
      fun (globals : List PsJsGlobalBinding) =>
        fun (locals : List PsJsLocalBinding) =>
          fun (nextLocal : Nat) =>
            fun (expectedType : PsVerifiedIrPrimitiveType) =>
              match lowerCondition
                globals locals nextLocal PsVerifiedIrPrimitiveType.bool with
              | Except.error error => Except.error error
              | Except.ok loweredCondition =>
                  match lowerThen
                    globals locals loweredCondition.nextLocal expectedType with
                  | Except.error error => Except.error error
                  | Except.ok loweredThen =>
                      match lowerElse
                        globals locals loweredThen.nextLocal expectedType with
                      | Except.error error => Except.error error
                      | Except.ok loweredElse =>
                          Except.ok (PsJsLoweredExpr.mk
                            (PsJsExpr.ifE
                              loweredCondition.expr
                              loweredThen.expr
                              loweredElse.expr)
                            loweredElse.nextLocal)
  | _ =>
      fun (_globals : List PsJsGlobalBinding) =>
        fun (_locals : List PsJsLocalBinding) =>
          fun (_nextLocal : Nat) =>
            fun (_expectedType : PsVerifiedIrPrimitiveType) =>
              Except.error PsJsError.unsupportedExpression

def psJsLowerExpr (globals : List PsJsGlobalBinding)
    (locals : List PsJsLocalBinding) (nextLocal : Nat)
    (expectedType : PsVerifiedIrPrimitiveType) (body : PsVerifiedIrExpr) :
    Except PsJsError PsJsLoweredExpr :=
  psJsLowerExprWorker body globals locals nextLocal expectedType

def psJsLowerDeclarationBody (globals : List PsJsGlobalBinding)
    (parameters : List PsVerifiedIrParameter)
    (type : PsVerifiedIrType) (body : PsVerifiedIrExpr) :
    Except PsJsError PsJsExpr :=
  match type with
  | PsVerifiedIrType.primitive primitive =>
      if psJsPrimitiveTypeSupported primitive then
        match psJsLowerParameters parameters List.nil 0 with
        | Except.error error => Except.error error
        | Except.ok loweredParameters =>
            match psJsLowerExpr
              globals
              loweredParameters.locals
              loweredParameters.nextLocal
              primitive
              body with
            | Except.error error => Except.error error
            | Except.ok loweredBody =>
                match loweredParameters.indexes with
                | List.nil => Except.ok loweredBody.expr
                | List.cons _ _ =>
                    Except.ok (PsJsExpr.lambda
                      loweredParameters.indexes
                      loweredBody.expr)
      else Except.error PsJsError.unsupportedExpression
  | _ => Except.error PsJsError.literalTypeMismatch

def psJsLowerBody (type : PsVerifiedIrType)
    (body : PsVerifiedIrExpr) : Except PsJsError PsJsExpr :=
  psJsLowerDeclarationBody List.nil List.nil type body

def psJsLowerConstant (globals : List PsJsGlobalBinding)
    (declaration : PsVerifiedIrDeclaration) : Except PsJsError PsJsConstant :=
  match declaration.typeParameters with
  | List.cons _ _ => Except.error (PsJsError.unsupportedDeclaration declaration.name)
  | List.nil =>
      if psJsValidExportName declaration.name then
        match psJsLowerDeclarationBody
          globals declaration.parameters declaration.resultType declaration.body with
        | Except.error error => Except.error error
        | Except.ok body => Except.ok (PsJsConstant.mk declaration.name body)
      else Except.error (PsJsError.invalidExportName declaration.name)

def psJsLowerConstants (globals : List PsJsGlobalBinding)
    (declarations : List PsVerifiedIrDeclaration) :
    List String -> Except PsJsError (List PsJsConstant) :=
  match declarations with
  | List.nil => fun (_used : List String) => Except.ok List.nil
  | List.cons declaration rest =>
      let smaller : List String -> Except PsJsError (List PsJsConstant) :=
        psJsLowerConstants globals rest;
      fun (used : List String) =>
        if psJsContainsName used declaration.name then
          Except.error (PsJsError.duplicateExport declaration.name)
        else
          match psJsLowerConstant globals declaration with
          | Except.error error => Except.error error
          | Except.ok value =>
              match smaller (List.cons declaration.name used) with
              | Except.error error => Except.error error
              | Except.ok values => Except.ok (List.cons value values)

def psJsLowerModule (module : PsVerifiedIrModule) : Except PsJsError PsJsModule :=
  match module.imports with
  | List.cons _ _ => Except.error PsJsError.unsupportedModule
  | List.nil =>
      match module.structures with
      | List.cons _ _ => Except.error PsJsError.unsupportedModule
      | List.nil =>
          match module.inductives with
          | List.cons _ _ => Except.error PsJsError.unsupportedModule
          | List.nil =>
              match psJsBuildGlobals module.declarations 0 List.nil with
              | Except.error error => Except.error error
              | Except.ok globals =>
                  match psJsLowerConstants globals module.declarations List.nil with
                  | Except.error error => Except.error error
                  | Except.ok constants => Except.ok (PsJsModule.mk constants)
