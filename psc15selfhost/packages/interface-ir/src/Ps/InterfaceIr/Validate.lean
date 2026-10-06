import Ps.InterfaceIr.Model

def psForeignAll {alpha : Type} (check : alpha -> Bool) (values : List alpha) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest => if check value then psForeignAll check rest else false

def psForeignContains (name : String) (names : List String) : Bool :=
  match names with
  | List.nil => false
  | List.cons other rest => if psStringEq name other then true else psForeignContains name rest

def psForeignUnique (names : List String) : Bool :=
  match names with
  | List.nil => true
  | List.cons name rest => if psForeignContains name rest then false else psForeignUnique rest

def psForeignNameBytes (fuel : Nat) : String -> Nat -> Bool -> Bool :=
  match fuel with
  | Nat.zero => fun (_name : String) (_position : Nat) (_needLetter : Bool) => false
  | Nat.succ remaining =>
      let smaller : String -> Nat -> Bool -> Bool := psForeignNameBytes remaining;
      fun (name : String) (position : Nat) (needLetter : Bool) =>
        if String.Internal.atEnd name (String.Pos.Raw.mk position) then
          if needLetter then false else true
        else
          let code := Char.toNat (String.Internal.get name (String.Pos.Raw.mk position));
          let next := String.Pos.Raw.byteIdx (String.Internal.next name (String.Pos.Raw.mk position));
          if Nat.ble 97 code then
            if Nat.ble code 122 then smaller name next false else false
          else if needLetter then false
          else if Nat.beq code 45 then smaller name next true
          else if Nat.ble 48 code then
            if Nat.ble code 57 then smaller name next false else false
          else false

def psForeignNameValid (name : String) : Bool :=
  psForeignNameBytes (Nat.succ (String.utf8ByteSize name)) name 0 true

def psForeignNamesValid (names : List String) : Bool :=
  if psForeignUnique names then psForeignAll psForeignNameValid names else false

def psForeignSubset (required allowed : List String) : Bool :=
  let check : String -> Bool := fun (name : String) => psForeignContains name allowed;
  psForeignAll check required

def psForeignFieldName (field : PsForeignField) : String := field.name
def psForeignCaseName (value : PsForeignCase) : String := value.name
def psForeignDefinitionName (value : PsForeignDefinition) : String := value.name
def psForeignFunctionName (value : PsForeignFunction) : String := value.name
def psForeignInterfaceName (value : PsForeignInterface) : String := value.name

def psForeignFindDefinition (definitions : List PsForeignDefinition) (name : String) : Option PsForeignDefinition :=
  match definitions with
  | List.nil => Option.none
  | List.cons definition rest =>
      if psStringEq definition.name name then Option.some definition else psForeignFindDefinition rest name

def psForeignIsResource (definitions : List PsForeignDefinition) (name : String) : Bool :=
  match psForeignFindDefinition definitions name with
  | Option.none => false
  | Option.some definition =>
      match definition.body with
      | .resource => true
      | _ => false

def psForeignForEach {alpha : Type} (check : alpha -> Except PsForeignError Unit)
    (values : List alpha) : Except PsForeignError Unit :=
  match psListMapExcept check values with
  | Except.error error => Except.error error
  | Except.ok _ => Except.ok Unit.unit

def psForeignOptionTypeValid (check : PsForeignType -> Except PsForeignError Unit)
    (value : Option PsForeignType) : Except PsForeignError Unit :=
  match value with
  | Option.none => Except.ok Unit.unit
  | Option.some type => check type

def psForeignFieldTypeValid (check : PsForeignType -> Except PsForeignError Unit)
    (field : PsForeignField) : Except PsForeignError Unit := check field.type
def psForeignCaseTypeValid (check : PsForeignType -> Except PsForeignError Unit)
    (value : PsForeignCase) : Except PsForeignError Unit :=
  psForeignOptionTypeValid check value.payload

def psForeignBodyValid (check : PsForeignType -> Except PsForeignError Unit)
    (body : PsForeignDefinitionBody) : Except PsForeignError Unit :=
  match body with
  | .alias type => check type
  | .record fields =>
      if psListIsEmpty fields then Except.error PsForeignError.invalidOrUnsupportedType
      else if psForeignNamesValid (psListMap psForeignFieldName fields) then
        psForeignForEach (psForeignFieldTypeValid check) fields
      else Except.error PsForeignError.invalidName
  | .variant cases =>
      if psListIsEmpty cases then Except.error PsForeignError.invalidOrUnsupportedType
      else if psForeignNamesValid (psListMap psForeignCaseName cases) then
        psForeignForEach (psForeignCaseTypeValid check) cases
      else Except.error PsForeignError.invalidName
  | .enumeration cases =>
      if psListIsEmpty cases then Except.error PsForeignError.invalidOrUnsupportedType
      else if psForeignNamesValid cases then Except.ok Unit.unit else Except.error PsForeignError.invalidName
  | .resource => Except.ok Unit.unit

-- Borrowing is deliberately limited to direct synchronous parameters. Nested
-- borrowing, borrowed returns, and async borrows need a distinct lifetime
-- contract rather than a permissive representation guess.
def psForeignTypeValidWithFuel (fuel : Nat) : List PsForeignDefinition -> List String -> Bool -> Bool -> PsForeignType -> Except PsForeignError Unit :=
  match fuel with
  | Nat.zero =>
      fun (_definitions : List PsForeignDefinition) (_active : List String) (_allowAsync : Bool) (_allowBorrow : Bool) (_type : PsForeignType) => Except.error PsForeignError.resourceExhausted
  | Nat.succ remaining =>
      let smaller := psForeignTypeValidWithFuel remaining;
      fun (definitions : List PsForeignDefinition) (active : List String) (allowAsync allowBorrow : Bool) (type : PsForeignType) =>
        let nested : PsForeignType -> Except PsForeignError Unit := smaller definitions active allowAsync false;
        match type with
        | .scalar _ => Except.ok Unit.unit
        | .named name =>
            if psForeignContains name active then Except.error PsForeignError.invalidOrUnsupportedType
            else
              match psForeignFindDefinition definitions name with
              | Option.none => Except.error PsForeignError.invalidOrUnsupportedType
              | Option.some definition =>
                  match definition.body with
                  | .resource => Except.error PsForeignError.invalidOrUnsupportedType
                  | _ => psForeignBodyValid (smaller definitions (List.cons name active) allowAsync false) definition.body
        | .list element => nested element
        | .option element => nested element
        | .result ok error =>
            match psForeignOptionTypeValid nested ok with
            | Except.error failure => Except.error failure
            | Except.ok _ => psForeignOptionTypeValid nested error
        | .tuple elements =>
            if psListIsEmpty elements then Except.error PsForeignError.invalidOrUnsupportedType else psForeignForEach nested elements
        | .own resource =>
            if psForeignIsResource definitions resource then Except.ok Unit.unit else Except.error PsForeignError.invalidOrUnsupportedType
        | .borrow resource =>
            if allowBorrow then
              if psForeignIsResource definitions resource then Except.ok Unit.unit else Except.error PsForeignError.invalidOrUnsupportedType
            else Except.error PsForeignError.invalidOrUnsupportedType
        | .future element =>
            if allowAsync then psForeignOptionTypeValid nested element else Except.error PsForeignError.invalidOrUnsupportedType
        | .stream element =>
            if allowAsync then psForeignOptionTypeValid nested element else Except.error PsForeignError.invalidOrUnsupportedType

def psForeignDefinitionValid (policy : PsForeignPolicy) (definitions : List PsForeignDefinition) (definition : PsForeignDefinition) : Except PsForeignError Unit :=
  let check : PsForeignType -> Except PsForeignError Unit :=
    psForeignTypeValidWithFuel policy.typeDepth definitions (List.cons definition.name List.nil) policy.allowAsync false;
  psForeignBodyValid check definition.body

def psForeignFunctionTypesValid (policy : PsForeignPolicy) (definitions : List PsForeignDefinition) (function : PsForeignFunction) : Except PsForeignError Unit :=
  let borrowAllowed : Bool := if function.asynchronous then false else true;
  let argumentCheck : PsForeignType -> Except PsForeignError Unit :=
    psForeignTypeValidWithFuel policy.typeDepth definitions List.nil policy.allowAsync borrowAllowed;
  let resultCheck : PsForeignType -> Except PsForeignError Unit :=
    psForeignTypeValidWithFuel policy.typeDepth definitions List.nil policy.allowAsync false;
  if psForeignNamesValid (psListMap psForeignFieldName function.parameters) then
    if psForeignNamesValid function.targets then
      if psForeignContains policy.target function.targets then
        match psForeignForEach (psForeignFieldTypeValid argumentCheck) function.parameters with
        | Except.error error => Except.error error
        | Except.ok _ => psForeignOptionTypeValid resultCheck function.result
      else Except.error PsForeignError.targetUnavailable
    else Except.error PsForeignError.invalidName
  else Except.error PsForeignError.invalidName

def psForeignFunctionValid (policy : PsForeignPolicy) (definitions : List PsForeignDefinition) (function : PsForeignFunction) : Except PsForeignError Unit :=
  if function.asynchronous then
    if policy.allowAsync then psForeignFunctionTypesValid policy definitions function
    else Except.error PsForeignError.invalidOrUnsupportedType
  else psForeignFunctionTypesValid policy definitions function

def psForeignInterfaceValid (policy : PsForeignPolicy) (value : PsForeignInterface) : Except PsForeignError Unit :=
  let names := psListAppend (psListMap psForeignDefinitionName value.definitions) (psListMap psForeignFunctionName value.functions);
  if psForeignNamesValid names then
    if psForeignNamesValid value.requiredCapabilities then
      if psForeignNamesValid value.providedCapabilities then
        match psForeignForEach (psForeignDefinitionValid policy value.definitions) value.definitions with
        | Except.error error => Except.error error
        | Except.ok _ => psForeignForEach (psForeignFunctionValid policy value.definitions) value.functions
      else Except.error PsForeignError.invalidName
    else Except.error PsForeignError.invalidName
  else Except.error PsForeignError.duplicateName

def psForeignCapabilityBoundary (policy : PsForeignPolicy) (world : PsForeignWorld) (value : PsForeignInterface) : Bool :=
  if psForeignContains value.name world.imports then
    if psForeignSubset value.requiredCapabilities policy.allowedImports then
      if psForeignSubset value.providedCapabilities policy.allowedImports then
        if psForeignContains value.name world.exports then psForeignSubset value.providedCapabilities policy.allowedExports else true
      else false
    else false
  else if psForeignContains value.name world.exports then
    if psForeignSubset value.requiredCapabilities policy.allowedImports then psForeignSubset value.providedCapabilities policy.allowedExports else false
  else true

def psForeignValidateWorld (policy : PsForeignPolicy) (world : PsForeignWorld) : Except PsForeignError Unit :=
  if psStringEq world.contract "psc-foreign-interface/1" then
    if Nat.beq policy.typeDepth 0 then Except.error PsForeignError.resourceExhausted
    else if psForeignContains policy.target ["component-model", "javascript", "typescript", "rust"] then
      let names := psListMap psForeignInterfaceName world.interfaces;
      if psForeignNamesValid (List.cons world.name names) then
        if psForeignNameValid world.packageNamespace then
          if psForeignNameValid world.packageName then
            if psForeignNamesValid world.imports then
              if psForeignNamesValid world.exports then
                if psForeignSubset world.imports names then
                  if psForeignSubset world.exports names then
                    if psForeignNamesValid policy.allowedImports then
                      if psForeignNamesValid policy.allowedExports then
                        if psForeignAll (psForeignCapabilityBoundary policy world) world.interfaces then
                          psForeignForEach (psForeignInterfaceValid policy) world.interfaces
                        else Except.error PsForeignError.capabilityDenied
                      else Except.error PsForeignError.invalidName
                    else Except.error PsForeignError.invalidName
                  else Except.error PsForeignError.missingInterface
                else Except.error PsForeignError.missingInterface
              else Except.error PsForeignError.invalidName
            else Except.error PsForeignError.invalidName
          else Except.error PsForeignError.invalidName
        else Except.error PsForeignError.invalidName
      else Except.error PsForeignError.duplicateName
    else Except.error PsForeignError.targetUnavailable
  else Except.error PsForeignError.unsupportedContract
