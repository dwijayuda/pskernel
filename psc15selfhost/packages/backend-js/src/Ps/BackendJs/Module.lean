import Ps.BackendJs.Normalize
import Ps.BackendJs.Lower
import Ps.BackendJs.Emit

def psJsAddParameterNames (parameters : List PsVerifiedIrParameter) :
    List String -> List String :=
  match parameters with
  | List.nil =>
      fun (locals : List String) => locals
  | List.cons parameter rest =>
      let smaller : List String -> List String :=
        psJsAddParameterNames rest;
      fun (locals : List String) =>
        smaller (List.cons parameter.name locals)

def psJsHasShadowedGlobalCallWithFuel (fuel : Nat) :
    List String -> PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_locals : List String) =>
        fun (_expr : PsVerifiedIrExpr) => true
  | Nat.succ remaining =>
      let smaller : List String -> PsVerifiedIrExpr -> Bool :=
        psJsHasShadowedGlobalCallWithFuel remaining;
      fun (locals : List String) =>
        fun (expr : PsVerifiedIrExpr) =>
          match expr with
          | PsVerifiedIrExpr.call fn _ _ =>
              match fn with
              | PsVerifiedIrExpr.var name => psJsContainsName locals name
              | _ => false
          | PsVerifiedIrExpr.letE name _ value body =>
              if smaller locals value then true
              else smaller (List.cons name locals) body
          | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
              if smaller locals condition then true
              else if smaller locals thenBranch then true
              else smaller locals elseBranch
          | PsVerifiedIrExpr.lambda parameters _ body =>
              smaller (psJsAddParameterNames parameters locals) body
          | _ => false

def psJsHasShadowedGlobalCall (locals : List String)
    (expr : PsVerifiedIrExpr) : Bool :=
  psJsHasShadowedGlobalCallWithFuel 4096 locals expr

def psJsValidateDeclarationCallTargets
    (declaration : PsVerifiedIrDeclaration) : Except PsJsError Unit :=
  let locals := psJsAddParameterNames declaration.parameters List.nil;
  if psJsHasShadowedGlobalCall locals declaration.body then
    Except.error PsJsError.unsupportedExpression
  else Except.ok Unit.unit

def psJsValidateDeclarationCallTargetsList
    (declarations : List PsVerifiedIrDeclaration) : Except PsJsError Unit :=
  match declarations with
  | List.nil => Except.ok Unit.unit
  | List.cons declaration rest =>
      match psJsValidateDeclarationCallTargets declaration with
      | Except.error error => Except.error error
      | Except.ok _ => psJsValidateDeclarationCallTargetsList rest

def psJsHasUnsafeEagerCallWithFuel (fuel : Nat) :
    List String -> List String -> PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_initializedGlobals : List String) =>
        fun (_locals : List String) =>
          fun (_expr : PsVerifiedIrExpr) => true
  | Nat.succ remaining =>
      let smaller : List String -> List String -> PsVerifiedIrExpr -> Bool :=
        psJsHasUnsafeEagerCallWithFuel remaining;
      fun (initializedGlobals : List String) =>
        fun (locals : List String) =>
          fun (expr : PsVerifiedIrExpr) =>
            match expr with
            | PsVerifiedIrExpr.call fn _ _ =>
                match fn with
                | PsVerifiedIrExpr.var name =>
                    if psJsContainsName locals name then false
                    else if psJsContainsName initializedGlobals name then false
                    else true
                | _ => false
            | PsVerifiedIrExpr.letE name _ value body =>
                if smaller initializedGlobals locals value then true
                else smaller initializedGlobals (List.cons name locals) body
            | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
                if smaller initializedGlobals locals condition then true
                else if smaller initializedGlobals thenBranch then true
                else smaller initializedGlobals elseBranch
            | PsVerifiedIrExpr.lambda _ _ _ => false
            | _ => false

def psJsHasUnsafeEagerCall (initializedGlobals : List String)
    (expr : PsVerifiedIrExpr) : Bool :=
  psJsHasUnsafeEagerCallWithFuel 4096 initializedGlobals List.nil expr

def psJsValidateInitializationOrderAux
    (declarations : List PsVerifiedIrDeclaration) :
    List String -> Except PsJsError Unit :=
  match declarations with
  | List.nil =>
      fun (_initializedGlobals : List String) => Except.ok Unit.unit
  | List.cons declaration rest =>
      let smaller : List String -> Except PsJsError Unit :=
        psJsValidateInitializationOrderAux rest;
      fun (initializedGlobals : List String) =>
        match declaration.parameters with
        | List.nil =>
            if psJsHasUnsafeEagerCall initializedGlobals declaration.body then
              Except.error PsJsError.unsupportedExpression
            else smaller (List.cons declaration.name initializedGlobals)
        | List.cons _ _ =>
            smaller (List.cons declaration.name initializedGlobals)

def psJsValidateInitializationOrder
    (declarations : List PsVerifiedIrDeclaration) : Except PsJsError Unit :=
  psJsValidateInitializationOrderAux declarations List.nil

def psJsLiteralDeclarationShape (declaration : PsVerifiedIrDeclaration) : Bool :=
  match declaration.typeParameters with
  | List.cons _ _ => false
  | List.nil =>
      match declaration.parameters with
      | List.cons _ _ => false
      | List.nil =>
          match declaration.resultType with
          | PsVerifiedIrType.primitive _ =>
              match declaration.body with
              | PsVerifiedIrExpr.literal _ => true
              | _ => false
          | _ => false

def psJsAllLiteralDeclarations (declarations : List PsVerifiedIrDeclaration) : Bool :=
  match declarations with
  | List.nil => true
  | List.cons declaration rest =>
      if psJsLiteralDeclarationShape declaration then
        psJsAllLiteralDeclarations rest
      else false

def psJsLowerFixedWidthMachineLiteral
    (machine : PsVerifiedIrMachineIntegerType)
    (number : Int)
    (type : PsVerifiedIrPrimitiveType) : Except PsJsError PsJsLiteral :=
  match machine with
  | PsVerifiedIrMachineIntegerType.uint8 =>
      match type with
      | PsVerifiedIrPrimitiveType.uint8 => Except.ok (PsJsLiteral.machineNumber number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrMachineIntegerType.uint16 =>
      match type with
      | PsVerifiedIrPrimitiveType.uint16 => Except.ok (PsJsLiteral.machineNumber number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrMachineIntegerType.uint32 =>
      match type with
      | PsVerifiedIrPrimitiveType.uint32 => Except.ok (PsJsLiteral.machineNumber number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrMachineIntegerType.uint64 =>
      match type with
      | PsVerifiedIrPrimitiveType.uint64 => Except.ok (PsJsLiteral.machineBigInt number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrMachineIntegerType.usize =>
      Except.error PsJsError.unsupportedExpression
  | PsVerifiedIrMachineIntegerType.int8 =>
      match type with
      | PsVerifiedIrPrimitiveType.int8 => Except.ok (PsJsLiteral.machineNumber number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrMachineIntegerType.int16 =>
      match type with
      | PsVerifiedIrPrimitiveType.int16 => Except.ok (PsJsLiteral.machineNumber number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrMachineIntegerType.int32 =>
      match type with
      | PsVerifiedIrPrimitiveType.int32 => Except.ok (PsJsLiteral.machineNumber number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrMachineIntegerType.int64 =>
      match type with
      | PsVerifiedIrPrimitiveType.int64 => Except.ok (PsJsLiteral.machineBigInt number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrMachineIntegerType.isize =>
      Except.error PsJsError.unsupportedExpression

def psJsLowerBackendLiteral (value : PsVerifiedIrLiteral)
    (type : PsVerifiedIrPrimitiveType) : Except PsJsError PsJsLiteral :=
  match value with
  | PsVerifiedIrLiteral.machineInteger machine number =>
      psJsLowerFixedWidthMachineLiteral machine number type
  | _ => psJsLowerLiteral value type

def psJsLowerLiteralDeclaration
    (declaration : PsVerifiedIrDeclaration) : Except PsJsError PsJsConstant :=
  if psJsValidExportName declaration.name then
    match declaration.typeParameters with
    | List.cons _ _ => Except.error (PsJsError.unsupportedDeclaration declaration.name)
    | List.nil =>
        match declaration.parameters with
        | List.cons _ _ => Except.error PsJsError.unsupportedExpression
        | List.nil =>
            match declaration.resultType with
            | PsVerifiedIrType.primitive primitive =>
                match declaration.body with
                | PsVerifiedIrExpr.literal value =>
                    match psJsLowerBackendLiteral value primitive with
                    | Except.error error => Except.error error
                    | Except.ok lowered =>
                        Except.ok (PsJsConstant.mk declaration.name (PsJsExpr.literal lowered))
                | _ => Except.error PsJsError.unsupportedExpression
            | _ => Except.error PsJsError.literalTypeMismatch
  else Except.error (PsJsError.invalidExportName declaration.name)

def psJsLowerLiteralDeclarations (declarations : List PsVerifiedIrDeclaration) :
    List String -> Except PsJsError (List PsJsConstant) :=
  match declarations with
  | List.nil =>
      fun (_used : List String) => Except.ok List.nil
  | List.cons declaration rest =>
      let smaller : List String -> Except PsJsError (List PsJsConstant) :=
        psJsLowerLiteralDeclarations rest;
      fun (used : List String) =>
        if psJsContainsName used declaration.name then
          Except.error (PsJsError.duplicateExport declaration.name)
        else
          match psJsLowerLiteralDeclaration declaration with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              match smaller (List.cons declaration.name used) with
              | Except.error error => Except.error error
              | Except.ok loweredRest => Except.ok (List.cons lowered loweredRest)

def psJsLowerLiteralModule (module : PsVerifiedIrModule) : Except PsJsError PsJsModule :=
  match module.imports with
  | List.cons _ _ => Except.error PsJsError.unsupportedModule
  | List.nil =>
      match module.structures with
      | List.cons _ _ => Except.error PsJsError.unsupportedModule
      | List.nil =>
          match module.inductives with
          | List.cons _ _ => Except.error PsJsError.unsupportedModule
          | List.nil =>
              match psJsLowerLiteralDeclarations module.declarations List.nil with
              | Except.error error => Except.error error
              | Except.ok constants => Except.ok (PsJsModule.mk constants)

def psJsEmitNormalizedModule (module : PsVerifiedIrModule) :
    Except PsJsError String :=
  match psJsValidateDeclarationCallTargetsList module.declarations with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psJsValidateInitializationOrder module.declarations with
      | Except.error error => Except.error error
      | Except.ok _ =>
          if psJsAllLiteralDeclarations module.declarations then
            match psJsLowerLiteralModule module with
            | Except.error error => Except.error error
            | Except.ok lowered => psJsEmitTargetModule lowered
          else
            match psJsLowerModule module with
            | Except.error error => Except.error error
            | Except.ok lowered => psJsEmitTargetModule lowered

def psJsEmitModule (module : PsVerifiedIrModule) : Except PsJsError String :=
  match psJsNormalizeModule module with
  | Except.error error => Except.error error
  | Except.ok normalized => psJsEmitNormalizedModule normalized
