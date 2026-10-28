import Ps.MinKernel.Profile.RegularIngressProfile

-- R4B has an explicit term type. Ordinary atoms retain R3 semantics; a regular
-- recursor keeps its result code in the complete ambient registry.
inductive PsMinRegCoreTerm where
  | ordinary (term : PsMinOpTerm)
  | recursor (slot : Nat) (result : PsMinRegTy)
  | lam (domain : PsMinRegTy) (body : PsMinRegCoreTerm)
  | app (fn : PsMinRegCoreTerm) (argument : PsMinRegCoreTerm)
  | letE (type : PsMinRegTy) (value : PsMinRegCoreTerm) (body : PsMinRegCoreTerm)

structure PsMinRegCoreDefinition where
  type : PsMinRegTy
  value : PsMinRegCoreTerm

def psMinRegCoreLiftCode (type : PsMinRegTy) (amount : Nat) : PsMinRegTy :=
  match type with
  | .empty => PsMinRegTy.empty
  | .unit => PsMinRegTy.unit
  | .nat => PsMinRegTy.nat
  | .boolean => PsMinRegTy.boolean
  | .data index => PsMinRegTy.data (Nat.add index amount)
  | .arr domain result => PsMinRegTy.arr
      (psMinRegCoreLiftCode domain amount) (psMinRegCoreLiftCode result amount)
  | .list element => PsMinRegTy.list (psMinRegCoreLiftCode element amount)
  | .option element => PsMinRegTy.option (psMinRegCoreLiftCode element amount)

def psMinRegCoreSpecAt (specs : List PsMinRegSpec) (slot : Nat) : Option PsMinRegSpec :=
  match specs with
  | List.nil => Option.none
  | List.cons spec rest => match slot with
    | Nat.zero => Option.some spec
    | Nat.succ previous => psMinRegCoreSpecAt rest previous

def psMinRegCoreAmbientFields (slot : Nat) (fields : List PsMinRegField)
    (result : PsMinRegTy) : PsMinRegTy :=
  match fields with
  | List.nil => result
  | List.cons field rest => match field with
    | .ground code => PsMinRegTy.arr (psMinRegCoreLiftCode code (Nat.succ slot))
        (psMinRegCoreAmbientFields slot rest result)
    | .recursive => PsMinRegTy.arr (PsMinRegTy.data slot)
        (psMinRegCoreAmbientFields slot rest result)

def psMinRegCoreAmbientBranch (slot : Nat) (result : PsMinRegTy)
    (fields : List PsMinRegField) : PsMinRegTy :=
  psMinRegCoreAmbientFields slot fields
    (psMinRegRepeatArrow (psMinRegSelfCount fields) result result)

def psMinRegCoreAmbientBranches (slot : Nat) (result : PsMinRegTy)
    (constructors : List (List PsMinRegField)) : PsMinRegTy :=
  match constructors with
  | List.nil => PsMinRegTy.arr (PsMinRegTy.data slot) result
  | List.cons fields rest => PsMinRegTy.arr
      (psMinRegCoreAmbientBranch slot result fields)
      (psMinRegCoreAmbientBranches slot result rest)

def psMinRegCoreAmbientRecursorType (specs : List PsMinRegSpec) (slot : Nat)
    (result : PsMinRegTy) : Option PsMinRegTy :=
  match psMinRegCoreSpecAt specs slot with
  | Option.none => Option.none
  | Option.some spec => Option.some (psMinRegCoreAmbientBranches slot result spec.constructors)

def psMinRegCoreInfer (fuel : Nat) (specs : List PsMinRegSpec)
    (globals locals : List PsMinRegTy) (term : PsMinRegCoreTerm) : Option PsMinRegTy :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining => match term with
    | .ordinary atom => psMinOpInfer remaining specs globals locals atom
    | .recursor slot result =>
      if psMinRegTyValid remaining (psMinRegSpecCount specs) result then
        psMinRegCoreAmbientRecursorType specs slot result else Option.none
    | .lam domain body =>
      if psMinRegTyValid remaining (psMinRegSpecCount specs) domain then
        match psMinRegCoreInfer remaining specs globals (List.cons domain locals) body with
        | Option.none => Option.none
        | Option.some result => Option.some (PsMinRegTy.arr domain result)
      else Option.none
    | .app fn argument => match psMinRegCoreInfer remaining specs globals locals fn with
      | Option.none => Option.none
      | Option.some functionType => match functionType with
        | .arr domain result => match psMinRegCoreInfer remaining specs globals locals argument with
          | Option.none => Option.none
          | Option.some argumentType => if psMinRegTyEq remaining domain argumentType then
              Option.some result else Option.none
        | _ => Option.none
    | .letE type value body =>
      if psMinRegTyValid remaining (psMinRegSpecCount specs) type then
        match psMinRegCoreInfer remaining specs globals locals value with
        | Option.none => Option.none
        | Option.some actual => if psMinRegTyEq remaining actual type then
            psMinRegCoreInfer remaining specs globals (List.cons type locals) body else Option.none
      else Option.none

def psMinRegCoreCheckDefinitions (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (globals : List PsMinRegTy) (definitions : List PsMinRegCoreDefinition) : Option (List PsMinRegTy) :=
  match definitions with
  | List.nil => Option.some globals
  | List.cons definition rest => match declarationFuel with
    | Nat.zero => Option.none
    | Nat.succ remaining => if psMinRegTyValid termFuel (psMinRegSpecCount specs) definition.type then
        match psMinRegCoreInfer termFuel specs globals List.nil definition.value with
        | Option.none => Option.none
        | Option.some actual => if psMinRegTyEq termFuel actual definition.type then
            psMinRegCoreCheckDefinitions termFuel remaining specs
              (List.cons definition.type globals) rest else Option.none
      else Option.none

def psMinRegCoreCheckEnvironment (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (definitions : List PsMinRegCoreDefinition) : Option (List PsMinRegTy) :=
  if psMinRegRegistryValid termFuel specs then
    psMinRegCoreCheckDefinitions termFuel declarationFuel specs List.nil definitions else Option.none
