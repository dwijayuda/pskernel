import Ps.BackendTs.Type
import Ps.Codegen.Names

def psTsLookup (entries : List (String × String)) : String -> Option String :=
  match entries with
  | List.nil => fun (_name : String) => Option.none
  | List.cons entry rest =>
      let smaller : String -> Option String := psTsLookup rest;
      fun (name : String) =>
        match entry with
        | Prod.mk key value => if psStringEq key name then Option.some value else smaller name

def psTsExprUsesNameWithFuel (fuel : Nat) : PsVerifiedIrExpr -> String -> Bool :=
  match fuel with
  | Nat.zero => fun (_expr : PsVerifiedIrExpr) (_name : String) => true
  | Nat.succ remaining =>
      fun (expr : PsVerifiedIrExpr) (name : String) =>
        let smaller : PsVerifiedIrExpr -> String -> Bool := psTsExprUsesNameWithFuel remaining;
        let uses : PsVerifiedIrExpr -> Bool := fun (value : PsVerifiedIrExpr) => smaller value name;
        let parameterUses : PsVerifiedIrParameter -> Bool :=
          fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name name;
        let bindingUses : PsVerifiedIrMatchBinding -> Bool :=
          fun (binding : PsVerifiedIrMatchBinding) => psStringEq binding.name name;
        let fieldUses : (String × PsVerifiedIrExpr) -> Bool :=
          fun (field : String × PsVerifiedIrExpr) =>
            match field with
            | Prod.mk _ value => smaller value name;
        let alternativeUses : (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) -> Bool :=
          fun (alternative : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) =>
            match alternative with
            | Prod.mk _ detail =>
                match detail with
                | Prod.mk bindings body =>
                    if psListAny bindingUses bindings then true else smaller body name;
        match expr with
        | .unreachable _ => false
        | .literal _ => false
        | .var value => psStringEq value name
        | .intrinsic _ _ arguments => psListAny uses arguments
        | .lambda parameters _ body =>
            if psListAny parameterUses parameters then true else smaller body name
        | .call fn _ arguments => if smaller fn name then true else psListAny uses arguments
        | .letE localName _ value body =>
            if psStringEq localName name then true
            else if smaller value name then true else smaller body name
        | .ifE condition thenBranch elseBranch =>
            if smaller condition name then true
            else if smaller thenBranch name then true else smaller elseBranch name
        | .record _ _ fields => psListAny fieldUses fields
        | .projection _ _ target _ => smaller target name
        | .constructor _ _ _ fields => psListAny fieldUses fields
        | .matchE _ _ scrutinee alternatives =>
            if smaller scrutinee name then true else psListAny alternativeUses alternatives

def psTsFreshMatchTempWorker
    (expr : PsVerifiedIrExpr) (attempts : Nat) (index : Nat) : String :=
  match attempts with
  | Nat.zero => "__ps$match$overflow"
  | Nat.succ remaining =>
      let candidate := String.Internal.append "__ps$match$" (psNatToString index);
      if psTsExprUsesNameWithFuel 4096 expr candidate then
        psTsFreshMatchTempWorker expr remaining (Nat.succ index)
      else candidate

def psTsFreshMatchTempLoop (expr : PsVerifiedIrExpr) (index attempts : Nat) : String :=
  psTsFreshMatchTempWorker expr attempts index

def psTsFreshMatchTemp (expr : PsVerifiedIrExpr) : String :=
  psTsFreshMatchTempLoop expr 0 4096

def psTsReservedNames : List String :=
  ["break", "case", "catch", "class", "const", "continue", "debugger", "default",
   "delete", "do", "else", "enum", "export", "extends", "false", "finally", "for",
   "function", "if", "import", "in", "instanceof", "new", "null", "return", "super",
   "switch", "this", "throw", "true", "try", "typeof", "var", "void", "while", "with",
   "yield", "let", "static", "implements", "interface", "package", "private",
   "protected", "public", "await", "arguments", "eval"]

structure PsTsFreshNameResult where
  name : String
  nextIndex : Nat

def psTsAppendLines (left : List String) : List String -> List String :=
  match left with
  | List.nil => fun (right : List String) => right
  | List.cons value rest =>
      let smaller : List String -> List String := psTsAppendLines rest;
      fun (right : List String) => List.cons value (smaller right)

def psTsFreshInternalWorker
    (used : List String) (namePrefix : String)
    (attempts : Nat) (index : Nat) : PsTsFreshNameResult :=
  match attempts with
  | Nat.zero =>
      PsTsFreshNameResult.mk (String.Internal.append namePrefix "overflow") (Nat.succ index)
  | Nat.succ remaining =>
      let candidate := String.Internal.append namePrefix (psNatToString index);
      let sameName : String -> Bool := fun (name : String) => psStringEq name candidate;
      if psListAny sameName used then
        psTsFreshInternalWorker used namePrefix remaining (Nat.succ index)
      else PsTsFreshNameResult.mk candidate (Nat.succ index)

def psTsFreshInternalWithFuel (used : List String) (namePrefix : String) (index attempts : Nat) : PsTsFreshNameResult :=
  psTsFreshInternalWorker used namePrefix attempts index

def psTsFreshInternal (used : List String) (namePrefix : String) (index : Nat) : PsTsFreshNameResult :=
  psTsFreshInternalWithFuel used namePrefix index 4096

structure PsTsSymbolMapState where
  used : List String
  nextIndex : Nat
  entriesRev : List (String × String)

def psTsBuildSymbolMap
    (namePrefix : String)
    (names : List String)
    (state : PsTsSymbolMapState) : PsTsSymbolMapState :=
  match names with
  | List.nil => state
  | List.cons name rest =>
      let fresh := psTsFreshInternal state.used namePrefix state.nextIndex;
      psTsBuildSymbolMap namePrefix rest
        (PsTsSymbolMapState.mk
          (List.cons fresh.name state.used)
          fresh.nextIndex
          (List.cons (Prod.mk name fresh.name) state.entriesRev))

def psTsStructureName (value : PsVerifiedIrStructure) : String := value.name
def psTsInductiveName (value : PsVerifiedIrInductive) : String := value.name
def psTsDeclarationName (value : PsVerifiedIrDeclaration) : String := value.name
def psTsTypeParameterName (value : PsVerifiedIrTypeParameter) : String := value.name

def psTsModuleTopLevelNames (module : PsVerifiedIrModule) : List String :=
  psTsAppendLines (psListMap psTsDeclarationName module.declarations)
    (psTsAppendLines (psListMap psTsStructureName module.structures) (psListMap psTsInductiveName module.inductives))

def psTsBuildBrandMap (module : PsVerifiedIrModule) : List (String × String) :=
  let state := psTsBuildSymbolMap "__ps$brand$" (psListMap psTsStructureName module.structures)
    (PsTsSymbolMapState.mk (psTsModuleTopLevelNames module) 0 List.nil);
  psListReverse state.entriesRev

def psTsBuildTagMap (module : PsVerifiedIrModule) : List (String × String) :=
  let state := psTsBuildSymbolMap "__ps$tag$" (psListMap psTsInductiveName module.inductives)
    (PsTsSymbolMapState.mk (psTsModuleTopLevelNames module) 0 List.nil);
  psListReverse state.entriesRev

def psTsGenericNames (parameters : List PsVerifiedIrTypeParameter) : String :=
  if psListIsEmpty parameters then ""
  else psTsJoin "" ["<", psTsJoin ", " (psListMap psTsTypeParameterName parameters), ">"]

def psTsNameSequence (namePrefix : String) (count : Nat) : Nat -> List String :=
  match count with
  | Nat.zero => fun (_index : Nat) => List.nil
  | Nat.succ remaining =>
      fun (index : Nat) => let smaller : Nat -> List String := psTsNameSequence namePrefix remaining; List.cons (String.Internal.append namePrefix (psNatToString index)) (smaller (Nat.succ index))

-- Eta parameters are already evaluated variables. When none of their names
-- occur in the callee, they can safely pass through its lexical bindings and
-- branches without capturing a name or changing argument evaluation order.
def psTsEtaArgumentsFresh (fn : PsVerifiedIrExpr) (arguments : List PsVerifiedIrExpr) : Bool :=
  match arguments with
  | List.nil => true
  | List.cons argument rest =>
      match argument with
      | PsVerifiedIrExpr.var name =>
          if psTsExprUsesNameWithFuel 4096 fn name then false else psTsEtaArgumentsFresh fn rest
      | _ => false

def psTsEtaBind (parameters : List PsVerifiedIrParameter) : List PsVerifiedIrExpr -> PsVerifiedIrExpr -> Option PsVerifiedIrExpr :=
  match parameters with
  | List.nil => fun (arguments : List PsVerifiedIrExpr) (body : PsVerifiedIrExpr) =>
      if psListIsEmpty arguments then Option.some body else Option.none
  | List.cons parameter rest =>
      let smaller : List PsVerifiedIrExpr -> PsVerifiedIrExpr -> Option PsVerifiedIrExpr := psTsEtaBind rest;
      fun (arguments : List PsVerifiedIrExpr) (body : PsVerifiedIrExpr) =>
        match arguments with
        | List.nil => Option.none
        | List.cons argument tail =>
            match smaller tail body with
            | Option.none => Option.none
            | Option.some inner => Option.some (PsVerifiedIrExpr.letE parameter.name parameter.type argument inner)

def psTsEtaAlternatives (apply : PsVerifiedIrExpr -> Option PsVerifiedIrExpr)
    (alternatives : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) :
    Option (List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) :=
  match alternatives with
  | List.nil => Option.some List.nil
  | List.cons alternative rest =>
      match apply (Prod.snd (Prod.snd alternative)) with
      | Option.none => Option.none
      | Option.some body =>
          match psTsEtaAlternatives apply rest with
          | Option.none => Option.none
          | Option.some tail => Option.some (List.cons (Prod.mk (Prod.fst alternative) (Prod.mk (Prod.fst (Prod.snd alternative)) body)) tail)

def psTsEtaApplyWorker (arguments : List PsVerifiedIrExpr) (fuel : Nat) : PsVerifiedIrExpr -> Option PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero => fun (_fn : PsVerifiedIrExpr) => Option.none
  | Nat.succ remaining =>
      fun (fn : PsVerifiedIrExpr) =>
        let smaller : PsVerifiedIrExpr -> Option PsVerifiedIrExpr := psTsEtaApplyWorker arguments remaining;
        match fn with
        | PsVerifiedIrExpr.lambda parameters _ body => psTsEtaBind parameters arguments body
        | PsVerifiedIrExpr.letE name type value body =>
            match smaller body with
            | Option.none => Option.none
            | Option.some inner => Option.some (PsVerifiedIrExpr.letE name type value inner)
        | PsVerifiedIrExpr.ifE condition left right =>
            match smaller left with
            | Option.none => Option.none
            | Option.some first =>
                match smaller right with
                | Option.none => Option.none
                | Option.some second => Option.some (PsVerifiedIrExpr.ifE condition first second)
        | PsVerifiedIrExpr.matchE name types scrutinee alternatives =>
            match psTsEtaAlternatives smaller alternatives with
            | Option.none => Option.none
            | Option.some branches => Option.some (PsVerifiedIrExpr.matchE name types scrutinee branches)
        | _ => Option.none

def psTsInlineEtaApplication (expr : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  match expr with
  | PsVerifiedIrExpr.call fn types arguments =>
      if psListIsEmpty types then
        if psTsEtaArgumentsFresh fn arguments then
          match psTsEtaApplyWorker arguments 4096 fn with
          | Option.some body => body
          | Option.none => expr
        else expr
      else expr
  | _ => expr

-- A zero/successor fold over one recursive field is a count. Emit its exact
-- computation as a loop, avoiding a suspended generator for every list cell.
-- Recognition uses the IR shape, not a source function or inductive name.
def psTsCountLiteral (expected : Nat) (expr : PsVerifiedIrExpr) : Bool :=
  match expr with
  | PsVerifiedIrExpr.literal literal =>
      match literal with
      | PsVerifiedIrLiteral.natural value => Nat.beq expected value
      | _ => false
  | _ => false

def psTsCountRecursiveArgument (name : String) (expr : PsVerifiedIrExpr) : Option String :=
  match expr with
  | PsVerifiedIrExpr.call fn _ args =>
      match fn with
      | PsVerifiedIrExpr.var called =>
          if psStringEq called name then
            match args with
            | List.cons argument rest =>
                if psListIsEmpty rest then
                  match argument with
                  | PsVerifiedIrExpr.var localName => Option.some localName
                  | _ => Option.none
                else Option.none
            | _ => Option.none
          else Option.none
      | _ => Option.none
  | _ => Option.none

def psTsCountStepArgument (name : String) (expr : PsVerifiedIrExpr) : Option String :=
  match expr with
  | PsVerifiedIrExpr.intrinsic operation _ args =>
      match operation with
      | PsVerifiedIrIntrinsic.natAdd =>
          match args with
          | List.cons left rest =>
              match rest with
              | List.cons right tail =>
                  if psListIsEmpty tail then
                    if psTsCountLiteral 1 left then psTsCountRecursiveArgument name right
                    else if psTsCountLiteral 1 right then psTsCountRecursiveArgument name left
                    else Option.none
                  else Option.none
              | _ => Option.none
          | _ => Option.none
      | _ => Option.none
  | _ => Option.none

def psTsCountField (localName : String) (bindings : List PsVerifiedIrMatchBinding) : Option String :=
  match bindings with
  | List.nil => Option.none
  | List.cons binding rest =>
      if psStringEq localName binding.name then Option.some binding.field
      else psTsCountField localName rest

-- Closed tail workers need no suspended continuations. This recognizer accepts
-- pure expressions and exact self calls only; all other code uses generators.
structure PsTsTailAlias where
  name : String
  captured : List PsVerifiedIrExpr
  arity : Nat

def psTsTailMap {alpha beta : Type} (convert : alpha -> Option beta) (values : List alpha) : Option (List beta) :=
  match values with
  | List.nil => Option.some List.nil
  | List.cons value rest =>
      match convert value with
      | Option.none => Option.none
      | Option.some result =>
          match psTsTailMap convert rest with
          | Option.none => Option.none
          | Option.some results => Option.some (List.cons result results)

def psTsTailFindAlias (aliases : List PsTsTailAlias) (name : String) : Option PsTsTailAlias :=
  match aliases with
  | List.nil => Option.none
  | List.cons alias rest =>
      if psStringEq alias.name name then Option.some alias else psTsTailFindAlias rest name

def psTsTailParametersMatch (parameters : List PsVerifiedIrParameter) : List PsVerifiedIrExpr -> Bool :=
  match parameters with
  | List.nil => fun (arguments : List PsVerifiedIrExpr) => psListIsEmpty arguments
  | List.cons parameter rest =>
      let smaller : List PsVerifiedIrExpr -> Bool := psTsTailParametersMatch rest;
      fun (arguments : List PsVerifiedIrExpr) =>
        match arguments with
        | List.nil => false
        | List.cons argument tail =>
            match argument with
            | PsVerifiedIrExpr.var name => if psStringEq name parameter.name then smaller tail else false
            | _ => false

def psTsTailAliasPrefix (parameters : List PsVerifiedIrParameter) (arguments : List PsVerifiedIrExpr) : Option (List PsVerifiedIrExpr) :=
  match arguments with
  | List.nil => if psListIsEmpty parameters then Option.some List.nil else Option.none
  | List.cons argument rest =>
      if psTsTailParametersMatch parameters arguments then Option.some List.nil
      else
        match argument with
        | PsVerifiedIrExpr.var name =>
            let shadows : PsVerifiedIrParameter -> Bool := fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name name;
            if psListAny shadows parameters then Option.none
            else
              match psTsTailAliasPrefix parameters rest with
              | Option.none => Option.none
              | Option.some captured => Option.some (List.cons argument captured)
        | _ => Option.none

def psTsTailAliasValue (self name : String) (value : PsVerifiedIrExpr) : Option PsTsTailAlias :=
  match value with
  | PsVerifiedIrExpr.lambda parameters _ body =>
      match body with
      | PsVerifiedIrExpr.call fn types arguments =>
          if psListIsEmpty types then
            match fn with
            | PsVerifiedIrExpr.var called =>
                if psStringEq called self then
                  let shadows : PsVerifiedIrParameter -> Bool := fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name self;
                  if psListAny shadows parameters then Option.none
                  else
                    match psTsTailAliasPrefix parameters arguments with
                    | Option.none => Option.none
                    | Option.some captured => Option.some (PsTsTailAlias.mk name captured (psListLength parameters))
                else Option.none
            | _ => Option.none
          else Option.none
      | _ => Option.none
  | _ => Option.none

def psTsTailPureWithFuel (aliases : List PsTsTailAlias) (fuel : Nat) : PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero => fun (_expr : PsVerifiedIrExpr) => false
  | Nat.succ remaining =>
      fun (expr : PsVerifiedIrExpr) =>
        let smaller : PsVerifiedIrExpr -> Bool := psTsTailPureWithFuel aliases remaining;
        let impure : PsVerifiedIrExpr -> Bool := fun (value : PsVerifiedIrExpr) => if smaller value then false else true;
        let impureField : Prod String PsVerifiedIrExpr -> Bool := fun (field : Prod String PsVerifiedIrExpr) => impure (Prod.snd field);
        match expr with
        | PsVerifiedIrExpr.literal _ => true
        | PsVerifiedIrExpr.var name =>
            match psTsTailFindAlias aliases name with
            | Option.none => true
            | Option.some _ => false
        | PsVerifiedIrExpr.intrinsic operation _ arguments =>
            match operation with
            | PsVerifiedIrIntrinsic.arrayMap => false
            | PsVerifiedIrIntrinsic.arrayFoldl => false
            | _ => if psListAny impure arguments then false else true
        | PsVerifiedIrExpr.record _ _ fields => if psListAny impureField fields then false else true
        | PsVerifiedIrExpr.constructor _ _ _ fields => if psListAny impureField fields then false else true
        | PsVerifiedIrExpr.projection _ _ target _ => smaller target
        | PsVerifiedIrExpr.ifE condition left right =>
            if smaller condition then if smaller left then smaller right else false else false
        | _ => false

def psTsTailBindingSafe (declaration : PsVerifiedIrDeclaration) (aliases : List PsTsTailAlias) (name : String) : Bool :=
  let parameterUses : PsVerifiedIrParameter -> Bool := fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name name;
  let prefixUses : PsVerifiedIrExpr -> Bool := fun (value : PsVerifiedIrExpr) => psTsExprUsesNameWithFuel 4096 value name;
  let aliasUses : PsTsTailAlias -> Bool := fun (alias : PsTsTailAlias) =>
    if psStringEq alias.name name then true else psListAny prefixUses alias.captured;
  if psStringEq declaration.name name then false
  else if psListAny parameterUses declaration.parameters then false
  else if psListAny aliasUses aliases then false
  else true

def psTsTailCallArguments (self : String) (aliases : List PsTsTailAlias)
    (fn : PsVerifiedIrExpr) (arguments : List PsVerifiedIrExpr) : Option (List PsVerifiedIrExpr) :=
  match fn with
  | PsVerifiedIrExpr.var name =>
      if psStringEq name self then Option.some arguments
      else
        match psTsTailFindAlias aliases name with
        | Option.none => Option.none
        | Option.some alias =>
            if Nat.beq alias.arity (psListLength arguments) then Option.some (psListAppend alias.captured arguments)
            else Option.none
  | _ => Option.none

