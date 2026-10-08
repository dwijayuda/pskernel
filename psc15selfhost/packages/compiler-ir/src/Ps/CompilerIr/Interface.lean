import Ps.CompilerIr.Validate

-- Runtime values already express owned functions, records and variants.
-- Foreign handles, borrowed values, streams and futures need a separate adapter
-- contract; this profile never invents representations for them.
structure PsInterfaceIrExport where
  name : String
  type : PsVerifiedIrType

inductive PsInterfaceIrOrigin where
  | host (assumptionId : String)
  | linkedModule

structure PsInterfaceIrContract where
  moduleId : String
  semanticProfile : String
  abiProfile : String
  targets : List String
  requiredCapabilities : List String
  origin : PsInterfaceIrOrigin
  structures : List PsVerifiedIrStructure
  inductives : List PsVerifiedIrInductive
  exports : List PsInterfaceIrExport

structure PsInterfaceIrPolicy where
  target : String
  allowedCapabilities : List String

inductive PsInterfaceIrError where
  | invalidIr (error : PsVerifiedIrValidationError)
  | invalidContract (moduleId : String)
  | unsupportedProfile (moduleId : String)
  | missingInterface (moduleId : String)
  | missingExport (moduleId name : String)
  | signatureMismatch (localName : String)
  | layoutMismatch (localName : String)
  | capabilityDenied (moduleId : String)
  | duplicateModule
  | dependencyCycle (moduleId : String)
  | unsupportedGenericExport (name : String)
  | invalidHostOrigin (moduleId : String)

def psInterfaceAll {alpha : Type}
    (check : alpha -> Bool) (values : List alpha) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest =>
      if check value then psInterfaceAll check rest else false

def psInterfacePairAll {alpha : Type}
    (check : alpha -> alpha -> Bool) (left : List alpha) :
    List alpha -> Bool :=
  match left with
  | List.nil =>
      fun (right : List alpha) => psListIsEmpty right
  | List.cons value rest =>
      let smaller : List alpha -> Bool := psInterfacePairAll check rest;
      fun (right : List alpha) =>
        match right with
        | List.nil => false
        | List.cons other others =>
            if check value other then smaller others else false

def psInterfaceNonempty (value : String) : Bool :=
  if psStringEq value "" then false else true

def psInterfaceNamesValid (values : List String) : Bool :=
  if psStrictStringListUnique values then
    psInterfaceAll psInterfaceNonempty values
  else false

def psInterfaceSubset (required allowed : List String) : Bool :=
  let check : String -> Bool :=
    fun (name : String) => psStrictStringInList name allowed;
  psInterfaceAll check required

def psInterfaceModuleId (value : PsInterfaceIrContract) : String :=
  value.moduleId

def psInterfaceExportName (value : PsInterfaceIrExport) : String :=
  value.name

def psInterfaceFind (values : List PsInterfaceIrContract) (name : String) :
    Option PsInterfaceIrContract :=
  match values with
  | List.nil => Option.none
  | List.cons value rest =>
      if psStringEq value.moduleId name then Option.some value
      else psInterfaceFind rest name

def psInterfaceFindExport (values : List PsInterfaceIrExport) (name : String) :
    Option PsInterfaceIrExport :=
  match values with
  | List.nil => Option.none
  | List.cons value rest =>
      if psStringEq value.name name then Option.some value
      else psInterfaceFindExport rest name

def psInterfaceAsImport (moduleId : String) (value : PsInterfaceIrExport) :
    PsVerifiedIrExternalImport :=
  PsVerifiedIrExternalImport.mk value.name moduleId value.name value.type

def psInterfaceAsModule (value : PsInterfaceIrContract) : PsVerifiedIrModule :=
  PsVerifiedIrModule.mk
    (psListMap (psInterfaceAsImport value.moduleId) value.exports)
    value.structures value.inductives List.nil

def psInterfaceOriginValid (origin : PsInterfaceIrOrigin) : Bool :=
  match origin with
  | .host assumption => psInterfaceNonempty assumption
  | .linkedModule => true

def psInterfaceContractNamesValid (value : PsInterfaceIrContract) : Bool :=
  if psInterfaceNonempty value.moduleId then
    if psInterfaceOriginValid value.origin then
      if psInterfaceNamesValid value.targets then
        if psListIsEmpty value.targets then false
        else psInterfaceNamesValid value.requiredCapabilities
      else false
    else false
  else false

def psInterfaceProfileValid (policy : PsInterfaceIrPolicy)
    (value : PsInterfaceIrContract) : Bool :=
  if psStringEq value.semanticProfile "psc-runtime-semantics/1" then
    if psStringEq value.abiProfile "psc-runtime-values/1" then
      psStrictStringInList policy.target value.targets
    else false
  else false

def psInterfaceValidateContract (policy : PsInterfaceIrPolicy)
    (value : PsInterfaceIrContract) : Except PsInterfaceIrError Unit :=
  if psInterfaceContractNamesValid value then
    if psInterfaceProfileValid policy value then
      if psInterfaceSubset value.requiredCapabilities policy.allowedCapabilities then
        match psStrictValidateModule (psInterfaceAsModule value) with
        | Except.error error => Except.error (PsInterfaceIrError.invalidIr error)
        | Except.ok _ => Except.ok Unit.unit
      else Except.error (PsInterfaceIrError.capabilityDenied value.moduleId)
    else Except.error (PsInterfaceIrError.unsupportedProfile value.moduleId)
  else Except.error (PsInterfaceIrError.invalidContract value.moduleId)

def psInterfaceValidateContext (policy : PsInterfaceIrPolicy)
    (values : List PsInterfaceIrContract) : Except PsInterfaceIrError Unit :=
  if psStrictStringInList policy.target ["typescript", "javascript", "rust", "wasm"] then
    if psInterfaceNamesValid policy.allowedCapabilities then
      if psStrictStringListUnique (psListMap psInterfaceModuleId values) then
        match psListMapExcept (psInterfaceValidateContract policy) values with
        | Except.error error => Except.error error
        | Except.ok _ => Except.ok Unit.unit
      else Except.error PsInterfaceIrError.duplicateModule
    else Except.error (PsInterfaceIrError.invalidContract "capability-policy")
  else Except.error (PsInterfaceIrError.unsupportedProfile policy.target)

def psInterfaceStructureFieldEq
    (left right : PsVerifiedIrStructureField) : Bool :=
  if psStringEq left.name right.name then psStrictTypeEq left.type right.type
  else false

def psInterfaceConstructorFieldEq
    (left right : PsVerifiedIrConstructorField) : Bool :=
  if psStringEq left.name right.name then psStrictTypeEq left.type right.type
  else false

def psInterfaceConstructorEq
    (left right : PsVerifiedIrConstructor) : Bool :=
  if psStringEq left.name right.name then
    psInterfacePairAll psInterfaceConstructorFieldEq left.fields right.fields
  else false

def psInterfaceStructureFieldType (value : PsVerifiedIrStructureField) :
    PsVerifiedIrType := value.type

def psInterfaceConstructorFieldType (value : PsVerifiedIrConstructorField) :
    PsVerifiedIrType := value.type

def psInterfaceConstructorTypes (values : List PsVerifiedIrConstructor) :
    List PsVerifiedIrType :=
  match values with
  | List.nil => List.nil
  | List.cons value rest =>
      psListAppend (psListMap psInterfaceConstructorFieldType value.fields)
        (psInterfaceConstructorTypes rest)

def psInterfaceTypeParametersEq
    (left right : List PsVerifiedIrTypeParameter) : Bool :=
  psInterfacePairAll psStringEq
    (psStrictTypeParameterNames left) (psStrictTypeParameterNames right)

-- Exact public layout, including constructor/field order and generic binders.
-- Nominal recursion is tracked by name; fuel exhaustion rejects conservatively.
def psInterfaceLayoutWithFuel (consumer provider : PsVerifiedIrModule)
    (fuel : Nat) : List String -> PsVerifiedIrType -> Bool :=
  match fuel with
  | Nat.zero => fun (_seen : List String) (_type : PsVerifiedIrType) => false
  | Nat.succ remaining =>
      let smaller : List String -> PsVerifiedIrType -> Bool :=
        psInterfaceLayoutWithFuel consumer provider remaining;
      fun (seen : List String) (type : PsVerifiedIrType) =>
        match type with
        | .unknown => false
        | .primitive _ => true
        | .typeParameter _ => true
        | .function parameters result =>
            if psInterfaceAll (smaller seen) parameters then smaller seen result
            else false
        | .named name arguments =>
            if psInterfaceAll (smaller seen) arguments then
              if psStringEq name "Array" then true
              else if psStrictStringInList name seen then true
              else
                let nested : PsVerifiedIrType -> Bool := smaller (List.cons name seen);
                match psVerifiedIrFindStructure consumer.structures name with
                | Option.some left =>
                    match psVerifiedIrFindStructure provider.structures name with
                    | Option.none => false
                    | Option.some right =>
                        if psInterfaceTypeParametersEq left.typeParameters right.typeParameters then
                          if psInterfacePairAll psInterfaceStructureFieldEq left.fields right.fields then
                            psInterfaceAll nested (psListMap psInterfaceStructureFieldType left.fields)
                          else false
                        else false
                | Option.none =>
                    match psVerifiedIrFindInductive consumer.inductives name with
                    | Option.none => false
                    | Option.some left =>
                        match psVerifiedIrFindInductive provider.inductives name with
                        | Option.none => false
                        | Option.some right =>
                            if psInterfaceTypeParametersEq left.typeParameters right.typeParameters then
                              if psInterfacePairAll psInterfaceConstructorEq left.constructors right.constructors then
                                psInterfaceAll nested (psInterfaceConstructorTypes left.constructors)
                              else false
                            else false
            else false

def psInterfaceValidateImport (module : PsVerifiedIrModule)
    (interfaces : List PsInterfaceIrContract) (value : PsVerifiedIrExternalImport) :
    Except PsInterfaceIrError Unit :=
  match psInterfaceFind interfaces value.source with
  | Option.none => Except.error (PsInterfaceIrError.missingInterface value.source)
  | Option.some provider =>
      match psInterfaceFindExport provider.exports value.importedName with
      | Option.none => Except.error (PsInterfaceIrError.missingExport value.source value.importedName)
      | Option.some exported =>
          if psStrictTypeEq value.type exported.type then
            if psInterfaceLayoutWithFuel module (psInterfaceAsModule provider) 4096 List.nil value.type then
              Except.ok Unit.unit
            else Except.error (PsInterfaceIrError.layoutMismatch value.localName)
          else Except.error (PsInterfaceIrError.signatureMismatch value.localName)

def psValidateErasedIrModuleWithInterfaces (policy : PsInterfaceIrPolicy)
    (interfaces : List PsInterfaceIrContract) (erased : PsErasedIrModule) :
    Except PsInterfaceIrError PsValidatedIrModule :=
  match psInterfaceValidateContext policy interfaces with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psValidateErasedIrModuleReferences erased with
      | Except.error error => Except.error (PsInterfaceIrError.invalidIr error)
      | Except.ok _ =>
          match psStrictValidateModule erased.raw with
          | Except.error error => Except.error (PsInterfaceIrError.invalidIr error)
          | Except.ok _ =>
              match psListMapExcept (psInterfaceValidateImport erased.raw interfaces) erased.raw.imports with
              | Except.error error => Except.error error
              | Except.ok _ => Except.ok (PsValidatedIrModule.mk erased.raw)
