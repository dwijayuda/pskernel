import Ps.BackendJs.Lower
import Ps.CompilerIr.Validate

inductive PsJsIrValidationError where
  | fuelExhausted
  | invalidIdentifier (name : String)
  | duplicateGlobal (name : String)
  | duplicateParameter (name : String)
  | duplicateField (name : String)
  | duplicateAlternative (name : String)
  | unknownVariable (name : String)
  | invalidRuntimeArity
  | invalidMachineIntegerLiteral

def psJsValidationContains
    (name : String)
    (names : List String) : Bool :=
  match names with
  | List.nil =>
      false
  | List.cons value rest =>
      if psStringEq name value then
        true
      else
        psJsValidationContains name rest

def psJsValidationUnique
    (names : List String) : Bool :=
  match names with
  | List.nil =>
      true
  | List.cons name rest =>
      if psJsValidationContains name rest then
        false
      else
        psJsValidationUnique rest

def psJsValidationParameterNames
    (parameters : List PsJsIrParameter) :
    List String :=
  match parameters with
  | List.nil =>
      List.nil
  | List.cons parameter rest =>
      List.cons
        parameter.name
        (psJsValidationParameterNames rest)

def psJsValidationBindingNames
    (bindings : List PsJsIrMatchBinding) :
    List String :=
  match bindings with
  | List.nil =>
      List.nil
  | List.cons binding rest =>
      List.cons
        binding.name
        (psJsValidationBindingNames rest)

def psJsValidationBindingFields
    (bindings : List PsJsIrMatchBinding) :
    List String :=
  match bindings with
  | List.nil =>
      List.nil
  | List.cons binding rest =>
      List.cons
        binding.field
        (psJsValidationBindingFields rest)

def psJsValidationFieldNames
    (fields : List (String × PsJsIrExpr)) :
    List String :=
  match fields with
  | List.nil =>
      List.nil
  | List.cons field rest =>
      List.cons
        (Prod.fst field)
        (psJsValidationFieldNames rest)

def psJsValidationAlternativeNames
    (alternatives :
      List
        (String ×
          List PsJsIrMatchBinding ×
          PsJsIrExpr)) :
    List String :=
  match alternatives with
  | List.nil =>
      List.nil
  | List.cons alternative rest =>
      List.cons
        (Prod.fst alternative)
        (psJsValidationAlternativeNames rest)

def psJsValidationImportNames
    (imports : List PsJsIrImport) :
    List String :=
  match imports with
  | List.nil =>
      List.nil
  | List.cons value rest =>
      List.cons
        value.localName
        (psJsValidationImportNames rest)

def psJsValidationDeclarationNames
    (declarations : List PsJsIrDeclaration) :
    List String :=
  match declarations with
  | List.nil =>
      List.nil
  | List.cons value rest =>
      List.cons
        value.name
        (psJsValidationDeclarationNames rest)

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

def psJsValidationMachineType
    (type : PsJsIrMachineIntegerType) :
    PsVerifiedIrMachineIntegerType :=
  match type with
  | PsJsIrMachineIntegerType.uint8 =>
      PsVerifiedIrMachineIntegerType.uint8
  | PsJsIrMachineIntegerType.uint16 =>
      PsVerifiedIrMachineIntegerType.uint16
  | PsJsIrMachineIntegerType.uint32 =>
      PsVerifiedIrMachineIntegerType.uint32
  | PsJsIrMachineIntegerType.uint64 =>
      PsVerifiedIrMachineIntegerType.uint64
  | PsJsIrMachineIntegerType.int8 =>
      PsVerifiedIrMachineIntegerType.int8
  | PsJsIrMachineIntegerType.int16 =>
      PsVerifiedIrMachineIntegerType.int16
  | PsJsIrMachineIntegerType.int32 =>
      PsVerifiedIrMachineIntegerType.int32
  | PsJsIrMachineIntegerType.int64 =>
      PsVerifiedIrMachineIntegerType.int64

def psJsValidateLiteral
    (literal : PsJsIrLiteral) :
    Except PsJsIrValidationError Unit :=
  match literal with
  | PsJsIrLiteral.machineInteger type value =>
      if
          psVerifiedIrMachineIntegerLiteralCanonical
            (psJsValidationMachineType type)
            value then
        Except.ok Unit.unit
      else
        Except.error
          PsJsIrValidationError.invalidMachineIntegerLiteral
  | _ =>
      Except.ok Unit.unit

def psJsRuntimeArity
    (operation : PsJsIrRuntimeOp) : Nat :=
  match operation with
  | PsJsIrRuntimeOp.uint8OfNat => 1
  | PsJsIrRuntimeOp.natSub => 2
  | PsJsIrRuntimeOp.natDiv => 2
  | PsJsIrRuntimeOp.natMod => 2
  | PsJsIrRuntimeOp.intNegSucc => 1
  | PsJsIrRuntimeOp.intRepr => 1
  | PsJsIrRuntimeOp.charOfNat => 1
  | PsJsIrRuntimeOp.charToNat => 1
  | PsJsIrRuntimeOp.stringLength => 1
  | PsJsIrRuntimeOp.stringUtf8ByteSize => 1
  | PsJsIrRuntimeOp.stringNext => 2
  | PsJsIrRuntimeOp.stringGet => 2
  | PsJsIrRuntimeOp.stringAtEnd => 2
  | PsJsIrRuntimeOp.stringExtract => 3
  | PsJsIrRuntimeOp.arrayEmptyWithCapacity => 1
  | PsJsIrRuntimeOp.arraySize => 1
  | PsJsIrRuntimeOp.arrayPush => 2
  | PsJsIrRuntimeOp.arrayGet => 2
  | PsJsIrRuntimeOp.arrayGetD => 3
  | PsJsIrRuntimeOp.arraySet => 3
  | PsJsIrRuntimeOp.arraySetIfInBounds => 3
  | PsJsIrRuntimeOp.arrayMap => 2
  | PsJsIrRuntimeOp.arrayFoldl => 5

def psJsValidationExprListWith
    (validate :
      PsJsIrExpr ->
        Except PsJsIrValidationError Unit)
    (values : List PsJsIrExpr) :
    Except PsJsIrValidationError Unit :=
  match values with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons value rest =>
      match validate value with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psJsValidationExprListWith
            validate
            rest

def psJsValidationFieldValuesWith
    (validate :
      PsJsIrExpr ->
        Except PsJsIrValidationError Unit)
    (fields : List (String × PsJsIrExpr)) :
    Except PsJsIrValidationError Unit :=
  match fields with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons field rest =>
      match validate (Prod.snd field) with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psJsValidationFieldValuesWith
            validate
            rest

def psJsValidationFieldsWith
    (validate :
      PsJsIrExpr ->
        Except PsJsIrValidationError Unit)
    (fields : List (String × PsJsIrExpr)) :
    Except PsJsIrValidationError Unit :=
  if
      psJsValidationUnique
        (psJsValidationFieldNames fields) then
    psJsValidationFieldValuesWith validate fields
  else
    Except.error
      (PsJsIrValidationError.duplicateField "")

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

def psJsValidationBindingIdentifiers
    (bindings : List PsJsIrMatchBinding) : Bool :=
  match bindings with
  | List.nil =>
      true
  | List.cons binding rest =>
      if psJsIdentifierSupported binding.name then
        psJsValidationBindingIdentifiers rest
      else
        false

def psJsValidationAlternativeBodiesWith
    (validate :
      List String ->
      PsJsIrExpr ->
        Except PsJsIrValidationError Unit)
    (locals : List String)
    (alternatives :
      List
        (String ×
          List PsJsIrMatchBinding ×
          PsJsIrExpr)) :
    Except PsJsIrValidationError Unit :=
  match alternatives with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons alternative rest =>
      let bindings : List PsJsIrMatchBinding :=
        Prod.fst (Prod.snd alternative);
      let body : PsJsIrExpr :=
        Prod.snd (Prod.snd alternative);
      if
          psJsValidationUnique
            (psJsValidationBindingNames bindings) then
        if
            psJsValidationUnique
              (psJsValidationBindingFields bindings) then
          if psJsValidationBindingIdentifiers bindings then
            match
                validate
                  (psJsValidationAddBindings
                    bindings
                    locals)
                  body with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                psJsValidationAlternativeBodiesWith
                  validate
                  locals
                  rest
          else
            Except.error
              (PsJsIrValidationError.invalidIdentifier "")
        else
          Except.error
            (PsJsIrValidationError.duplicateField "")
      else
        Except.error
          (PsJsIrValidationError.duplicateParameter "")

def psJsValidationAlternativesWith
    (validate :
      List String ->
      PsJsIrExpr ->
        Except PsJsIrValidationError Unit)
    (locals : List String)
    (alternatives :
      List
        (String ×
          List PsJsIrMatchBinding ×
          PsJsIrExpr)) :
    Except PsJsIrValidationError Unit :=
  if
      psJsValidationUnique
        (psJsValidationAlternativeNames alternatives) then
    psJsValidationAlternativeBodiesWith
      validate
      locals
      alternatives
  else
    Except.error
      (PsJsIrValidationError.duplicateAlternative "")

def psJsValidationNamesSupported
    (names : List String) : Bool :=
  match names with
  | List.nil =>
      true
  | List.cons name rest =>
      if psJsIdentifierSupported name then
        psJsValidationNamesSupported rest
      else
        false

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

def psJsValidateImport
    (value : PsJsIrImport) :
    Except PsJsIrValidationError Unit :=
  if psJsIdentifierSupported value.localName then
    if psJsImportNameSupported value.importedName then
      if psStringEq value.source "" then
        Except.error
          (PsJsIrValidationError.invalidIdentifier
            value.source)
      else
        Except.ok Unit.unit
    else
      Except.error
        (PsJsIrValidationError.invalidIdentifier
          value.importedName)
  else
    Except.error
      (PsJsIrValidationError.invalidIdentifier
        value.localName)

def psJsValidateImports
    (imports : List PsJsIrImport) :
    Except PsJsIrValidationError Unit :=
  match imports with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons value rest =>
      match psJsValidateImport value with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psJsValidateImports rest

def psJsValidateDeclaration
    (globals : List String)
    (value : PsJsIrDeclaration) :
    Except PsJsIrValidationError Unit :=
  let parameters : List String :=
    psJsValidationParameterNames value.parameters;
  if psJsIdentifierSupported value.name then
    if psJsValidationUnique parameters then
      if psJsValidationNamesSupported parameters then
        psJsValidateExprWithFuel
          globals
          65536
          parameters
          value.body
      else
        Except.error
          (PsJsIrValidationError.invalidIdentifier value.name)
    else
      Except.error
        (PsJsIrValidationError.duplicateParameter value.name)
  else
    Except.error
      (PsJsIrValidationError.invalidIdentifier value.name)

def psJsValidateDeclarations
    (globals : List String)
    (declarations : List PsJsIrDeclaration) :
    Except PsJsIrValidationError Unit :=
  match declarations with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons value rest =>
      match psJsValidateDeclaration globals value with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psJsValidateDeclarations globals rest

def psJsValidateModule
    (module : PsJsIrModule) :
    Except PsJsIrValidationError Unit :=
  let globals : List String :=
    psJsValidationAppendNames
      (psJsValidationImportNames module.imports)
      (psJsValidationDeclarationNames module.declarations);
  if psJsValidationUnique globals then
    match psJsValidateImports module.imports with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        psJsValidateDeclarations
          globals
          module.declarations
  else
    Except.error
      (PsJsIrValidationError.duplicateGlobal "")

