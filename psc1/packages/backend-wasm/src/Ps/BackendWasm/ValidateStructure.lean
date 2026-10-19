import Ps.BackendWasm.Model
import Ps.Foundation.List

inductive PsWasmIrValidationError where
  | duplicateTypeName (name : String)
  | duplicateFunctionName (name : String)
  | duplicateExportName (name : String)
  | duplicateFunctionRef (name : String)
  | unknownHeapType (name : String)
  | unknownStructure (name : String)
  | unknownArray (name : String)
  | unknownFunctionType (name : String)
  | unknownFunction (name : String)
  | invalidFieldIndex (name : String) (index : Nat)
  | invalidLocalIndex (name : String) (index : Nat)
  | functionTypeMismatch (name : String)
  | invalidControlFlow (name : String)
  | invalidValueType
  | invalidTypeDeclaration (name : String)
  | invalidFunctionBody (name : String)

def psWasmIrStringIn
    (target : String)
    (values : List String) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons value rest =>
      if psStringEq target value then
        true
      else
        psWasmIrStringIn target rest

def psWasmIrUnique
    (values : List String) : Bool :=
  match values with
  | List.nil =>
      true
  | List.cons value rest =>
      if psWasmIrStringIn value rest then
        false
      else
        psWasmIrUnique rest

def psWasmIrStructNames
    (values : List PsWasmStructType) :
    List String :=
  match values with
  | List.nil =>
      List.nil
  | List.cons value rest =>
      List.cons
        value.name
        (psWasmIrStructNames rest)

def psWasmIrArrayNames
    (values : List PsWasmArrayType) :
    List String :=
  match values with
  | List.nil =>
      List.nil
  | List.cons value rest =>
      List.cons
        value.name
        (psWasmIrArrayNames rest)

def psWasmIrFunctionTypeNames
    (values : List PsWasmFunctionType) :
    List String :=
  match values with
  | List.nil =>
      List.nil
  | List.cons value rest =>
      List.cons
        value.name
        (psWasmIrFunctionTypeNames rest)

def psWasmIrFunctionNames
    (values : List PsWasmFunction) :
    List String :=
  match values with
  | List.nil =>
      List.nil
  | List.cons value rest =>
      List.cons
        value.name
        (psWasmIrFunctionNames rest)

def psWasmIrExportNames
    (values : List (String × String)) :
    List String :=
  match values with
  | List.nil =>
      List.nil
  | List.cons value rest =>
      List.cons
        (Prod.fst value)
        (psWasmIrExportNames rest)

def psWasmIrAppend
    (left : List String) :
    List String -> List String :=
  match left with
  | List.nil =>
      fun (right : List String) => right
  | List.cons value rest =>
      let smaller : List String -> List String :=
        psWasmIrAppend rest;
      fun (right : List String) =>
        List.cons value (smaller right)

def psWasmIrFindStructure
    (values : List PsWasmStructType)
    (target : String) :
    Option PsWasmStructType :=
  match values with
  | List.nil =>
      Option.none
  | List.cons value rest =>
      if psStringEq value.name target then
        Option.some value
      else
        psWasmIrFindStructure rest target

def psWasmIrFindArray
    (values : List PsWasmArrayType)
    (target : String) :
    Option PsWasmArrayType :=
  match values with
  | List.nil =>
      Option.none
  | List.cons value rest =>
      if psStringEq value.name target then
        Option.some value
      else
        psWasmIrFindArray rest target

def psWasmIrFindFunctionType
    (values : List PsWasmFunctionType)
    (target : String) :
    Option PsWasmFunctionType :=
  match values with
  | List.nil =>
      Option.none
  | List.cons value rest =>
      if psStringEq value.name target then
        Option.some value
      else
        psWasmIrFindFunctionType rest target

def psWasmIrFindFunction
    (values : List PsWasmFunction)
    (target : String) :
    Option PsWasmFunction :=
  match values with
  | List.nil =>
      Option.none
  | List.cons value rest =>
      if psStringEq value.name target then
        Option.some value
      else
        psWasmIrFindFunction rest target

def psWasmIrValueTypeEq
    (left right : PsWasmValueType) : Bool :=
  match left with
  | PsWasmValueType.i32 =>
      match right with
      | PsWasmValueType.i32 => true
      | _ => false
  | PsWasmValueType.i64 =>
      match right with
      | PsWasmValueType.i64 => true
      | _ => false
  | PsWasmValueType.f32 =>
      match right with
      | PsWasmValueType.f32 => true
      | _ => false
  | PsWasmValueType.f64 =>
      match right with
      | PsWasmValueType.f64 => true
      | _ => false
  | PsWasmValueType.refT leftName =>
      match right with
      | PsWasmValueType.refT rightName =>
          psStringEq leftName rightName
      | _ => false
  | PsWasmValueType.funcRef =>
      match right with
      | PsWasmValueType.funcRef => true
      | _ => false
  | PsWasmValueType.noValue =>
      match right with
      | PsWasmValueType.noValue => true
      | _ => false

def psWasmIrValueTypeListsEq
    (left : List PsWasmValueType) :
    List PsWasmValueType -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsWasmValueType) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons value rest =>
      let smaller :
          List PsWasmValueType -> Bool :=
        psWasmIrValueTypeListsEq rest;
      fun (right : List PsWasmValueType) =>
        match right with
        | List.nil => false
        | List.cons other otherRest =>
            if psWasmIrValueTypeEq value other then
              smaller otherRest
            else
              false

def psWasmIrHeapTypeExists
    (module : PsWasmModule)
    (name : String) : Bool :=
  match psWasmIrFindStructure module.structures name with
  | Option.some _ => true
  | Option.none =>
      match psWasmIrFindArray module.arrays name with
      | Option.some _ => true
      | Option.none => false

def psWasmIrValidateValueType
    (module : PsWasmModule)
    (type : PsWasmValueType) :
    Except PsWasmIrValidationError Unit :=
  match type with
  | PsWasmValueType.refT name =>
      if psWasmIrHeapTypeExists module name then
        Except.ok Unit.unit
      else
        Except.error
          (PsWasmIrValidationError.unknownHeapType name)
  | PsWasmValueType.noValue => Except.error PsWasmIrValidationError.invalidValueType
  | _ =>
      Except.ok Unit.unit

def psWasmIrValidateValueTypes
    (module : PsWasmModule)
    (types : List PsWasmValueType) :
    Except PsWasmIrValidationError Unit :=
  match types with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons type rest =>
      match psWasmIrValidateValueType module type with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psWasmIrValidateValueTypes module rest

def psWasmIrValidateStorageType
    (module : PsWasmModule)
    (type : PsWasmStorageType) :
    Except PsWasmIrValidationError Unit :=
  match type with
  | PsWasmStorageType.value valueType =>
      psWasmIrValidateValueType module valueType
  | _ =>
      Except.ok Unit.unit

def psWasmIrValidateStructFields
    (module : PsWasmModule)
    (fields : List PsWasmStructField) :
    Except PsWasmIrValidationError Unit :=
  match fields with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons field rest =>
      match psWasmIrValidateStorageType module field.storageType with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psWasmIrValidateStructFields module rest

def psWasmIrValidateStructures
    (module : PsWasmModule)
    (structures : List PsWasmStructType) :
    Except PsWasmIrValidationError Unit :=
  match structures with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons value rest =>
      match value.superType with
      | Option.some parent =>
          match psWasmIrFindStructure module.structures parent with
          | Option.none =>
              Except.error
                (PsWasmIrValidationError.unknownStructure parent)
          | Option.some _ =>
              match psWasmIrValidateStructFields module value.fields with
              | Except.error error => Except.error error
              | Except.ok _ =>
                  psWasmIrValidateStructures module rest
      | Option.none =>
          match psWasmIrValidateStructFields module value.fields with
          | Except.error error => Except.error error
          | Except.ok _ =>
              psWasmIrValidateStructures module rest

def psWasmIrValidateArrays
    (module : PsWasmModule)
    (arrays : List PsWasmArrayType) :
    Except PsWasmIrValidationError Unit :=
  match arrays with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons value rest =>
      match psWasmIrValidateStorageType module value.elementType with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psWasmIrValidateArrays module rest

def psWasmIrValidateFunctionTypes
    (module : PsWasmModule)
    (types : List PsWasmFunctionType) :
    Except PsWasmIrValidationError Unit :=
  match types with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons value rest =>
      match psWasmIrValidateValueTypes module value.parameters with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match psWasmIrValidateValueTypes module value.results with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              psWasmIrValidateFunctionTypes module rest

def psWasmIrValidateInstruction
    (module : PsWasmModule)
    (functionName : String)
    (localCount : Nat)
    (instruction : PsWasmInstruction) :
    Except PsWasmIrValidationError Unit :=
  match instruction with
  | PsWasmInstruction.localGet index =>
      if Nat.blt index localCount then
        Except.ok Unit.unit
      else
        Except.error
          (PsWasmIrValidationError.invalidLocalIndex
            functionName
            index)
  | PsWasmInstruction.localSet index =>
      if Nat.blt index localCount then
        Except.ok Unit.unit
      else
        Except.error
          (PsWasmIrValidationError.invalidLocalIndex
            functionName
            index)
  | PsWasmInstruction.call name =>
      match psWasmIrFindFunction module.functions name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownFunction name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.returnCall name =>
      match psWasmIrFindFunction module.functions name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownFunction name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.ifStart result =>
      match result with
      | Option.none => Except.ok Unit.unit
      | Option.some type =>
          psWasmIrValidateValueType module type
  | PsWasmInstruction.structNew name =>
      match psWasmIrFindStructure module.structures name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownStructure name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.structGet name index =>
      match psWasmIrFindStructure module.structures name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownStructure name)
      | Option.some value =>
          if Nat.blt index (psListLength value.fields) then
            Except.ok Unit.unit
          else
            Except.error
              (PsWasmIrValidationError.invalidFieldIndex
                name
                index)
  | PsWasmInstruction.structGetS name index =>
      match psWasmIrFindStructure module.structures name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownStructure name)
      | Option.some value =>
          if Nat.blt index (psListLength value.fields) then
            Except.ok Unit.unit
          else
            Except.error
              (PsWasmIrValidationError.invalidFieldIndex
                name
                index)
  | PsWasmInstruction.structGetU name index =>
      match psWasmIrFindStructure module.structures name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownStructure name)
      | Option.some value =>
          if Nat.blt index (psListLength value.fields) then
            Except.ok Unit.unit
          else
            Except.error
              (PsWasmIrValidationError.invalidFieldIndex
                name
                index)
  | PsWasmInstruction.arrayNew name =>
      match psWasmIrFindArray module.arrays name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownArray name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.arrayNewDefault name =>
      match psWasmIrFindArray module.arrays name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownArray name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.arrayNewFixed name _ =>
      match psWasmIrFindArray module.arrays name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownArray name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.arrayGet name =>
      match psWasmIrFindArray module.arrays name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownArray name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.arrayGetS name =>
      match psWasmIrFindArray module.arrays name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownArray name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.arrayGetU name =>
      match psWasmIrFindArray module.arrays name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownArray name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.arraySet name =>
      match psWasmIrFindArray module.arrays name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownArray name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.arrayCopy destination source =>
      match psWasmIrFindArray module.arrays destination with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownArray destination)
      | Option.some _ =>
          match psWasmIrFindArray module.arrays source with
          | Option.none =>
              Except.error
                (PsWasmIrValidationError.unknownArray source)
          | Option.some _ =>
              Except.ok Unit.unit
  | PsWasmInstruction.refTest name =>
      match psWasmIrFindStructure module.structures name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownStructure name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.refCast name =>
      match psWasmIrFindStructure module.structures name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownStructure name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.refFunc name =>
      match psWasmIrFindFunction module.functions name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownFunction name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.refCastFunction name =>
      match psWasmIrFindFunctionType module.functionTypes name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownFunctionType name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.callRef name =>
      match psWasmIrFindFunctionType module.functionTypes name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownFunctionType name)
      | Option.some _ =>
          Except.ok Unit.unit
  | PsWasmInstruction.returnCallRef name =>
      match psWasmIrFindFunctionType module.functionTypes name with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownFunctionType name)
      | Option.some _ =>
          Except.ok Unit.unit
  | _ =>
      Except.ok Unit.unit

def psWasmIrValidateInstructions
    (module : PsWasmModule)
    (functionName : String)
    (localCount : Nat)
    (instructions : List PsWasmInstruction) :
    Except PsWasmIrValidationError Unit :=
  match instructions with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons instruction rest =>
      match
          psWasmIrValidateInstruction
            module
            functionName
            localCount
            instruction with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psWasmIrValidateInstructions
            module
            functionName
            localCount
            rest

def psWasmIrValidateControl
    (functionName : String)
    (instructions : List PsWasmInstruction) :
    List Bool ->
    Except PsWasmIrValidationError Unit :=
  match instructions with
  | List.nil =>
      fun (stack : List Bool) =>
        match stack with
        | List.nil => Except.ok Unit.unit
        | List.cons _ _ =>
            Except.error
              (PsWasmIrValidationError.invalidControlFlow
                functionName)
  | List.cons instruction rest =>
      let smaller :
          List Bool ->
          Except PsWasmIrValidationError Unit :=
        psWasmIrValidateControl
          functionName
          rest;
      fun (stack : List Bool) =>
        match instruction with
        | PsWasmInstruction.ifStart _ =>
            smaller (List.cons false stack)
        | PsWasmInstruction.else_ =>
            match stack with
            | List.nil =>
                Except.error
                  (PsWasmIrValidationError.invalidControlFlow
                    functionName)
            | List.cons seenElse tail =>
                if seenElse then
                  Except.error
                    (PsWasmIrValidationError.invalidControlFlow
                      functionName)
                else
                  smaller (List.cons true tail)
        | PsWasmInstruction.end_ =>
            match stack with
            | List.nil =>
                Except.error
                  (PsWasmIrValidationError.invalidControlFlow
                    functionName)
            | List.cons _ tail =>
                smaller tail
        | _ =>
            smaller stack

def psWasmIrValidateFunction
    (module : PsWasmModule)
    (value : PsWasmFunction) :
    Except PsWasmIrValidationError Unit :=
  match psWasmIrValidateValueTypes module value.parameters with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match psWasmIrValidateValueTypes module value.results with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match psWasmIrValidateValueTypes module value.locals with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              match value.typeName with
              | Option.some typeName =>
                  match
                      psWasmIrFindFunctionType
                        module.functionTypes
                        typeName with
                  | Option.none =>
                      Except.error
                        (PsWasmIrValidationError.unknownFunctionType
                          typeName)
                  | Option.some functionType =>
                      if
                          psWasmIrValueTypeListsEq
                            value.parameters
                            functionType.parameters then
                        if
                            psWasmIrValueTypeListsEq
                              value.results
                              functionType.results then
                          match
                              psWasmIrValidateInstructions
                                module
                                value.name
                                (Nat.add
                                  (psListLength value.parameters)
                                  (psListLength value.locals))
                                value.body with
                          | Except.error error =>
                              Except.error error
                          | Except.ok _ =>
                              psWasmIrValidateControl
                                value.name
                                value.body
                                List.nil
                        else
                          Except.error
                            (PsWasmIrValidationError.functionTypeMismatch
                              value.name)
                      else
                        Except.error
                          (PsWasmIrValidationError.functionTypeMismatch
                            value.name)
              | Option.none =>
                  match
                      psWasmIrValidateInstructions
                        module
                        value.name
                        (Nat.add
                          (psListLength value.parameters)
                          (psListLength value.locals))
                        value.body with
                  | Except.error error =>
                      Except.error error
                  | Except.ok _ =>
                      psWasmIrValidateControl
                        value.name
                        value.body
                        List.nil

def psWasmIrValidateFunctions
    (module : PsWasmModule)
    (values : List PsWasmFunction) :
    Except PsWasmIrValidationError Unit :=
  match values with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons value rest =>
      match psWasmIrValidateFunction module value with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          psWasmIrValidateFunctions module rest

def psWasmIrValidateFunctionRefs
    (module : PsWasmModule)
    (values : List String) :
    Except PsWasmIrValidationError Unit :=
  match values with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons value rest =>
      match psWasmIrFindFunction module.functions value with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownFunction value)
      | Option.some _ =>
          psWasmIrValidateFunctionRefs module rest

def psWasmIrValidateExports
    (module : PsWasmModule)
    (values : List (String × String)) :
    Except PsWasmIrValidationError Unit :=
  match values with
  | List.nil =>
      Except.ok Unit.unit
  | List.cons value rest =>
      match
          psWasmIrFindFunction
            module.functions
            (Prod.snd value) with
      | Option.none =>
          Except.error
            (PsWasmIrValidationError.unknownFunction
              (Prod.snd value))
      | Option.some _ =>
          psWasmIrValidateExports module rest

def psWasmIrValidateModuleStructure
    (module : PsWasmModule) :
    Except PsWasmIrValidationError Unit :=
  let typeNames : List String :=
    psWasmIrAppend
      (psWasmIrStructNames module.structures)
      (psWasmIrAppend
        (psWasmIrArrayNames module.arrays)
        (psWasmIrFunctionTypeNames
          module.functionTypes));
  let functionNames : List String :=
    psWasmIrFunctionNames module.functions;
  let exportNames : List String :=
    psWasmIrExportNames module.exports;
  if psWasmIrUnique typeNames then
    if psWasmIrUnique functionNames then
      if psWasmIrUnique exportNames then
        if psWasmIrUnique module.functionRefs then
          match
              psWasmIrValidateStructures
                module
                module.structures with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              match
                  psWasmIrValidateArrays
                    module
                    module.arrays with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  match
                      psWasmIrValidateFunctionTypes
                        module
                        module.functionTypes with
                  | Except.error error =>
                      Except.error error
                  | Except.ok _ =>
                      match
                          psWasmIrValidateFunctions
                            module
                            module.functions with
                      | Except.error error =>
                          Except.error error
                      | Except.ok _ =>
                          match
                              psWasmIrValidateFunctionRefs
                                module
                                module.functionRefs with
                          | Except.error error =>
                              Except.error error
                          | Except.ok _ =>
                              psWasmIrValidateExports
                                module
                                module.exports
        else
          Except.error
            (PsWasmIrValidationError.duplicateFunctionRef "")
      else
        Except.error
          (PsWasmIrValidationError.duplicateExportName "")
    else
      Except.error
        (PsWasmIrValidationError.duplicateFunctionName "")
  else
    Except.error
      (PsWasmIrValidationError.duplicateTypeName "")
