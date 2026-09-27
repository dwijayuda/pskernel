import Ps.CompilerIr.Model
import Ps.Bridge.Json
import Ps.BackendJs.Model

structure PsJsLocalBinding where
  sourceName : String
  type : PsVerifiedIrPrimitiveType
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
  if psJsonNatInRange code 65 90 then true
  else if psJsonNatInRange code 97 122 then true
  else if Nat.beq code 95 then true
  else Nat.beq code 36

def psJsNameTail (values : List Char) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest =>
      if psJsNameHead value then psJsNameTail rest
      else if psJsonNatInRange (Char.toNat value) 48 57 then psJsNameTail rest
      else false

def psJsContainsName (values : List String) (name : String) : Bool :=
  match values with
  | List.nil => false
  | List.cons value rest =>
      if psJsonStringEq value name then true
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
    match psJsonStringToChars name with
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
      if psJsonStringEq binding.sourceName name then Option.some binding
      else psJsLookupLocal rest name

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

def psJsLowerExprWorker (body : PsVerifiedIrExpr) :
    List PsJsLocalBinding -> Nat -> PsVerifiedIrPrimitiveType ->
    Except PsJsError PsJsLoweredExpr :=
  match body with
  | PsVerifiedIrExpr.literal value =>
      fun (_locals : List PsJsLocalBinding) =>
        fun (nextLocal : Nat) =>
          fun (expectedType : PsVerifiedIrPrimitiveType) =>
            match psJsLowerLiteral value expectedType with
            | Except.error error => Except.error error
            | Except.ok lowered =>
                Except.ok (PsJsLoweredExpr.mk
                  (PsJsExpr.literal lowered)
                  nextLocal)
  | PsVerifiedIrExpr.var name =>
      fun (locals : List PsJsLocalBinding) =>
        fun (nextLocal : Nat) =>
          fun (expectedType : PsVerifiedIrPrimitiveType) =>
            match psJsLookupLocal locals name with
            | Option.none => Except.error PsJsError.unsupportedExpression
            | Option.some binding =>
                if psJsPrimitiveTypeEq binding.type expectedType then
                  Except.ok (PsJsLoweredExpr.mk
                    (PsJsExpr.local binding.index)
                    nextLocal)
                else Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrExpr.letE name type value innerBody =>
      let lowerValue :
          List PsJsLocalBinding -> Nat -> PsVerifiedIrPrimitiveType ->
          Except PsJsError PsJsLoweredExpr :=
        psJsLowerExprWorker value;
      let lowerBody :
          List PsJsLocalBinding -> Nat -> PsVerifiedIrPrimitiveType ->
          Except PsJsError PsJsLoweredExpr :=
        psJsLowerExprWorker innerBody;
      fun (locals : List PsJsLocalBinding) =>
        fun (nextLocal : Nat) =>
          fun (expectedType : PsVerifiedIrPrimitiveType) =>
            match type with
            | PsVerifiedIrType.primitive localType =>
                match lowerValue locals nextLocal localType with
                | Except.error error => Except.error error
                | Except.ok loweredValue =>
                    let localIndex := loweredValue.nextLocal;
                    let binding := PsJsLocalBinding.mk name localType localIndex;
                    match lowerBody
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
          List PsJsLocalBinding -> Nat -> PsVerifiedIrPrimitiveType ->
          Except PsJsError PsJsLoweredExpr :=
        psJsLowerExprWorker condition;
      let lowerThen :
          List PsJsLocalBinding -> Nat -> PsVerifiedIrPrimitiveType ->
          Except PsJsError PsJsLoweredExpr :=
        psJsLowerExprWorker thenBranch;
      let lowerElse :
          List PsJsLocalBinding -> Nat -> PsVerifiedIrPrimitiveType ->
          Except PsJsError PsJsLoweredExpr :=
        psJsLowerExprWorker elseBranch;
      fun (locals : List PsJsLocalBinding) =>
        fun (nextLocal : Nat) =>
          fun (expectedType : PsVerifiedIrPrimitiveType) =>
            match lowerCondition
              locals nextLocal PsVerifiedIrPrimitiveType.bool with
            | Except.error error => Except.error error
            | Except.ok loweredCondition =>
                match lowerThen
                  locals loweredCondition.nextLocal expectedType with
                | Except.error error => Except.error error
                | Except.ok loweredThen =>
                    match lowerElse
                      locals loweredThen.nextLocal expectedType with
                    | Except.error error => Except.error error
                    | Except.ok loweredElse =>
                        Except.ok (PsJsLoweredExpr.mk
                          (PsJsExpr.ifE
                            loweredCondition.expr
                            loweredThen.expr
                            loweredElse.expr)
                          loweredElse.nextLocal)
  | _ =>
      fun (_locals : List PsJsLocalBinding) =>
        fun (_nextLocal : Nat) =>
          fun (_expectedType : PsVerifiedIrPrimitiveType) =>
            Except.error PsJsError.unsupportedExpression

def psJsLowerExpr (locals : List PsJsLocalBinding) (nextLocal : Nat)
    (expectedType : PsVerifiedIrPrimitiveType) (body : PsVerifiedIrExpr) :
    Except PsJsError PsJsLoweredExpr :=
  psJsLowerExprWorker body locals nextLocal expectedType

def psJsLowerDeclarationBody (parameters : List PsVerifiedIrParameter)
    (type : PsVerifiedIrType) (body : PsVerifiedIrExpr) :
    Except PsJsError PsJsExpr :=
  match type with
  | PsVerifiedIrType.primitive primitive =>
      if psJsPrimitiveTypeSupported primitive then
        match psJsLowerParameters parameters List.nil 0 with
        | Except.error error => Except.error error
        | Except.ok loweredParameters =>
            match psJsLowerExpr
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
  psJsLowerDeclarationBody List.nil type body

def psJsLowerConstant (declaration : PsVerifiedIrDeclaration) :
    Except PsJsError PsJsConstant :=
  match declaration.typeParameters with
  | List.cons _ _ => Except.error (PsJsError.unsupportedDeclaration declaration.name)
  | List.nil =>
      if psJsValidExportName declaration.name then
        match psJsLowerDeclarationBody
          declaration.parameters declaration.resultType declaration.body with
        | Except.error error => Except.error error
        | Except.ok body => Except.ok (PsJsConstant.mk declaration.name body)
      else Except.error (PsJsError.invalidExportName declaration.name)

def psJsLowerConstants (declarations : List PsVerifiedIrDeclaration) :
    List String -> Except PsJsError (List PsJsConstant) :=
  match declarations with
  | List.nil => fun (_used : List String) => Except.ok List.nil
  | List.cons declaration rest =>
      let smaller : List String -> Except PsJsError (List PsJsConstant) :=
        psJsLowerConstants rest;
      fun (used : List String) =>
        if psJsContainsName used declaration.name then
          Except.error (PsJsError.duplicateExport declaration.name)
        else
          match psJsLowerConstant declaration with
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
              match psJsLowerConstants module.declarations List.nil with
              | Except.error error => Except.error error
              | Except.ok constants => Except.ok (PsJsModule.mk constants)
