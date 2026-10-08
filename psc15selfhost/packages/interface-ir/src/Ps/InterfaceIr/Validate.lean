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

def psForeignSummaryValues {alpha : Type} (empty : alpha) (merge : alpha -> alpha -> alpha)
    (values : List (Except PsForeignError alpha)) : Except PsForeignError alpha :=
  let unwrap : Except PsForeignError alpha -> Except PsForeignError alpha :=
    fun (value : Except PsForeignError alpha) => value;
  match psListMapExcept unwrap values with
  | Except.error error => Except.error error
  | Except.ok summaries => Except.ok (psListFoldLeftWorker merge summaries empty)

def psForeignOptionSummary {alpha : Type} (check : PsForeignType -> Except PsForeignError alpha)
    (empty : alpha) (value : Option PsForeignType) : Except PsForeignError alpha :=
  match value with
  | Option.none => Except.ok empty
  | Option.some type => check type

-- Shape/name checks are shared by unit validation and cached depth analysis.
def psForeignBodySummary {alpha : Type} (check : PsForeignType -> Except PsForeignError alpha)
    (empty : alpha) (merge : alpha -> alpha -> alpha)
    (body : PsForeignDefinitionBody) : Except PsForeignError alpha :=
  match body with
  | PsForeignDefinitionBody.alias type => check type
  | PsForeignDefinitionBody.record fields =>
      let fieldSummary : PsForeignField -> Except PsForeignError alpha :=
        fun (field : PsForeignField) => check field.type;
      if psListIsEmpty fields then Except.error PsForeignError.invalidOrUnsupportedType
      else if psForeignNamesValid (psListMap psForeignFieldName fields) then
        psForeignSummaryValues empty merge (psListMap fieldSummary fields)
      else Except.error PsForeignError.invalidName
  | PsForeignDefinitionBody.variant cases =>
      let caseSummary : PsForeignCase -> Except PsForeignError alpha :=
        fun (value : PsForeignCase) => psForeignOptionSummary check empty value.payload;
      if psListIsEmpty cases then Except.error PsForeignError.invalidOrUnsupportedType
      else if psForeignNamesValid (psListMap psForeignCaseName cases) then
        psForeignSummaryValues empty merge (psListMap caseSummary cases)
      else Except.error PsForeignError.invalidName
  | PsForeignDefinitionBody.enumeration cases =>
      if psListIsEmpty cases then Except.error PsForeignError.invalidOrUnsupportedType
      else if psForeignNamesValid cases then Except.ok empty else Except.error PsForeignError.invalidName
  | PsForeignDefinitionBody.resource => Except.ok empty

def psForeignBodyValid (check : PsForeignType -> Except PsForeignError Unit)
    (body : PsForeignDefinitionBody) : Except PsForeignError Unit :=
  let merge : Unit -> Unit -> Unit := fun (_left _right : Unit) => Unit.unit;
  psForeignBodySummary check Unit.unit merge body

def psForeignDepthMax (left right : Nat) : Nat :=
  if Nat.ble left right then right else left

def psForeignDepthLookup (depths : List (Prod String Nat)) (name : String) : Option Nat :=
  match depths with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq (Prod.fst entry) name then Option.some (Prod.snd entry)
      else psForeignDepthLookup rest name

def psForeignDepthSuccessor (value : Except PsForeignError Nat) : Except PsForeignError Nat :=
  match value with
  | Except.error error => Except.error error
  | Except.ok depth => Except.ok (Nat.succ depth)

-- Depths count the same type nodes as the inherited fuel contract. A named
-- reference consumes one node plus the already checked definition-body depth.
-- Borrow permission is consumed at the immediate parameter, never inherited.
def psForeignTypeDepthWithFuel (definitions : List PsForeignDefinition)
    (depths : List (Prod String Nat)) (allowAsync : Bool) (fuel : Nat) :
    Bool -> PsForeignType -> Except PsForeignError Nat :=
  match fuel with
  | Nat.zero =>
      fun (_allowBorrow : Bool) (_type : PsForeignType) => Except.error PsForeignError.resourceExhausted
  | Nat.succ remaining =>
      let smaller : Bool -> PsForeignType -> Except PsForeignError Nat :=
        psForeignTypeDepthWithFuel definitions depths allowAsync remaining;
      fun (allowBorrow : Bool) (type : PsForeignType) =>
        let nested : PsForeignType -> Except PsForeignError Nat := smaller false;
        match type with
        | PsForeignType.scalar _ => Except.ok 1
        | PsForeignType.named name =>
            if psForeignIsResource definitions name then Except.error PsForeignError.invalidOrUnsupportedType
            else
              match psForeignDepthLookup depths name with
              | Option.none => Except.error PsForeignError.invalidOrUnsupportedType
              | Option.some depth =>
                  if Nat.ble depth remaining then Except.ok (Nat.succ depth)
                  else Except.error PsForeignError.resourceExhausted
        | PsForeignType.list element => psForeignDepthSuccessor (nested element)
        | PsForeignType.option element => psForeignDepthSuccessor (nested element)
        | PsForeignType.result ok error =>
            psForeignDepthSuccessor (psForeignSummaryValues 0 psForeignDepthMax
              [psForeignOptionSummary nested 0 ok, psForeignOptionSummary nested 0 error])
        | PsForeignType.tuple elements =>
            if psListIsEmpty elements then Except.error PsForeignError.invalidOrUnsupportedType
            else psForeignDepthSuccessor (psForeignSummaryValues 0 psForeignDepthMax (psListMap nested elements))
        | PsForeignType.own resource =>
            if psForeignIsResource definitions resource then Except.ok 1
            else Except.error PsForeignError.invalidOrUnsupportedType
        | PsForeignType.borrow resource =>
            if allowBorrow then
              if psForeignIsResource definitions resource then Except.ok 1
              else Except.error PsForeignError.invalidOrUnsupportedType
            else Except.error PsForeignError.invalidOrUnsupportedType
        | PsForeignType.future element =>
            if allowAsync then psForeignDepthSuccessor (psForeignOptionSummary nested 0 element)
            else Except.error PsForeignError.invalidOrUnsupportedType
        | PsForeignType.stream element =>
            if allowAsync then psForeignDepthSuccessor (psForeignOptionSummary nested 0 element)
            else Except.error PsForeignError.invalidOrUnsupportedType

structure PsForeignTypeGraph where
  ordered : List PsForeignDefinition
  depths : List (Prod String Nat)

structure PsForeignTypeGraphState where
  depths : List (Prod String Nat)
  orderedReverse : List PsForeignDefinition
  deferredReverse : List PsForeignDefinition

def psForeignTypeGraphPass (allowAsync : Bool) (depth : Nat) (definitions : List PsForeignDefinition)
    (pending : List PsForeignDefinition) : PsForeignTypeGraphState -> Except PsForeignError PsForeignTypeGraphState :=
  match pending with
  | List.nil => fun (state : PsForeignTypeGraphState) => Except.ok state
  | List.cons definition rest =>
      let smaller : PsForeignTypeGraphState -> Except PsForeignError PsForeignTypeGraphState :=
        psForeignTypeGraphPass allowAsync depth definitions rest;
      fun (state : PsForeignTypeGraphState) =>
        let check : PsForeignType -> Except PsForeignError Nat :=
          psForeignTypeDepthWithFuel definitions state.depths allowAsync depth false;
        match psForeignBodySummary check 0 psForeignDepthMax definition.body with
        | Except.error error =>
            match error with
            | PsForeignError.invalidOrUnsupportedType =>
                smaller (PsForeignTypeGraphState.mk state.depths state.orderedReverse
                  (List.cons definition state.deferredReverse))
            | _ => Except.error error
        | Except.ok required =>
            smaller (PsForeignTypeGraphState.mk (List.cons (Prod.mk definition.name required) state.depths)
              (List.cons definition state.orderedReverse) state.deferredReverse)

def psForeignTypeGraphWithFuel (allowAsync : Bool) (depth : Nat)
    (definitions : List PsForeignDefinition) (fuel : Nat) :
    List PsForeignDefinition -> List (Prod String Nat) -> List PsForeignDefinition ->
      Except PsForeignError PsForeignTypeGraph :=
  match fuel with
  | Nat.zero =>
      fun (_pending : List PsForeignDefinition) (_depths : List (Prod String Nat)) (_ordered : List PsForeignDefinition) =>
        Except.error PsForeignError.invalidOrUnsupportedType
  | Nat.succ remaining =>
      let smaller : List PsForeignDefinition -> List (Prod String Nat) -> List PsForeignDefinition ->
          Except PsForeignError PsForeignTypeGraph :=
        psForeignTypeGraphWithFuel allowAsync depth definitions remaining;
      fun (pending : List PsForeignDefinition) (depths : List (Prod String Nat)) (ordered : List PsForeignDefinition) =>
        match pending with
        | List.nil => Except.ok (PsForeignTypeGraph.mk (psListReverse ordered) depths)
        | List.cons _ _ =>
            match psForeignTypeGraphPass allowAsync depth definitions pending (PsForeignTypeGraphState.mk depths ordered List.nil) with
            | Except.error error => Except.error error
            | Except.ok state =>
                if Nat.beq (psListLength state.deferredReverse) (psListLength pending) then
                  Except.error PsForeignError.invalidOrUnsupportedType
                else smaller (psListReverse state.deferredReverse) state.depths state.orderedReverse

def psForeignAnalyzeDefinitions (allowAsync : Bool) (depth : Nat) (definitions : List PsForeignDefinition) :
    Except PsForeignError PsForeignTypeGraph :=
  if Nat.beq depth 0 then Except.error PsForeignError.resourceExhausted
  else if psForeignNamesValid (psListMap psForeignDefinitionName definitions) then
    psForeignTypeGraphWithFuel allowAsync depth definitions (Nat.succ (psListLength definitions)) definitions List.nil List.nil
  else Except.error PsForeignError.duplicateName

def psForeignDepthCheck (check : PsForeignType -> Except PsForeignError Nat)
    (type : PsForeignType) : Except PsForeignError Unit :=
  match check type with
  | Except.error error => Except.error error
  | Except.ok _ => Except.ok Unit.unit

def psForeignFunctionValidWithGraph (policy : PsForeignPolicy) (definitions : List PsForeignDefinition)
    (graph : PsForeignTypeGraph) (function : PsForeignFunction) : Except PsForeignError Unit :=
  let borrowAllowed : Bool := if function.asynchronous then false else true;
  let argumentCheck : PsForeignType -> Except PsForeignError Unit :=
    psForeignDepthCheck (psForeignTypeDepthWithFuel definitions graph.depths policy.allowAsync policy.typeDepth borrowAllowed);
  let resultCheck : PsForeignType -> Except PsForeignError Unit :=
    psForeignDepthCheck (psForeignTypeDepthWithFuel definitions graph.depths policy.allowAsync policy.typeDepth false);
  if if function.asynchronous then policy.allowAsync else true then
    if psForeignNamesValid (psListMap psForeignFieldName function.parameters) then
      if psForeignNamesValid function.targets then
        if psForeignContains policy.target function.targets then
          match psForeignForEach (psForeignFieldTypeValid argumentCheck) function.parameters with
          | Except.error error => Except.error error
          | Except.ok _ => psForeignOptionTypeValid resultCheck function.result
        else Except.error PsForeignError.targetUnavailable
      else Except.error PsForeignError.invalidName
    else Except.error PsForeignError.invalidName
  else Except.error PsForeignError.invalidOrUnsupportedType

def psForeignFunctionValid (policy : PsForeignPolicy) (definitions : List PsForeignDefinition)
    (function : PsForeignFunction) : Except PsForeignError Unit :=
  match psForeignAnalyzeDefinitions policy.allowAsync policy.typeDepth definitions with
  | Except.error error => Except.error error
  | Except.ok graph => psForeignFunctionValidWithGraph policy definitions graph function

def psForeignInterfaceValid (policy : PsForeignPolicy) (value : PsForeignInterface) : Except PsForeignError Unit :=
  let names := psListAppend (psListMap psForeignDefinitionName value.definitions) (psListMap psForeignFunctionName value.functions);
  if psForeignNamesValid names then
    if psForeignNamesValid value.requiredCapabilities then
      if psForeignNamesValid value.providedCapabilities then
        match psForeignAnalyzeDefinitions policy.allowAsync policy.typeDepth value.definitions with
        | Except.error error => Except.error error
        | Except.ok graph => psForeignForEach (psForeignFunctionValidWithGraph policy value.definitions graph) value.functions
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
