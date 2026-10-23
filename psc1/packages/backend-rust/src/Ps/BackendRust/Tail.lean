import Ps.BackendRust.TailAlias

-- The loop carries a tuple so arguments are evaluated before replacement.
-- Recognized eta aliases freeze captures before binding; shadowing hides aliases.
def psRustTailAnyAlternative
    (check : List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Bool)
    (locals : List String) (aliases : List PsRustTailAlias)
    (alternatives : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) : Bool :=
  match alternatives with
  | List.nil => false
  | List.cons alternative rest =>
      let payload := Prod.snd alternative;
      let names := psRustAddBindingNames (Prod.fst payload) List.nil;
      if check (psRustAddBindingNames (Prod.fst payload) locals) (psRustTailHideAliases names aliases) (Prod.snd payload) then true
      else psRustTailAnyAlternative check locals aliases rest

def psRustHasTailAliasWorker (declaration : PsVerifiedIrDeclaration) (fuel : Nat) :
    List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_locals : List String) (_aliases : List PsRustTailAlias) (_expr : PsVerifiedIrExpr) => false
  | Nat.succ remaining =>
      let smaller : List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Bool :=
        psRustHasTailAliasWorker declaration remaining;
      fun (locals : List String) (aliases : List PsRustTailAlias) (expr : PsVerifiedIrExpr) =>
        match psRustTailCallFor declaration locals aliases expr with
        | Option.some _ => true
        | Option.none =>
            match expr with
            | PsVerifiedIrExpr.letE name _ value body =>
                smaller (List.cons name locals) (psRustTailEnterAlias declaration locals aliases remaining name value) body
            | PsVerifiedIrExpr.ifE _ thenBranch elseBranch =>
                if smaller locals aliases thenBranch then true else smaller locals aliases elseBranch
            | PsVerifiedIrExpr.matchE _ _ _ alternatives => psRustTailAnyAlternative smaller locals aliases alternatives
            | _ => false

def psRustHasTailWorker (declaration : PsVerifiedIrDeclaration) (fuel : Nat)
    (locals : List String) (expr : PsVerifiedIrExpr) : Bool :=
  psRustHasTailAliasWorker declaration fuel locals List.nil expr

def psRustTailTuple (values : List String) : String :=
  match values with
  | List.nil => "()"
  | List.cons _ _ => psRustConcat3 "(" (psRustJoin ", " values) ",)"

def psRustTailParameterNames (parameters : List PsVerifiedIrParameter) : List String :=
  match parameters with
  | List.nil => List.nil
  | List.cons parameter rest =>
      List.cons (psRustIdentifier parameter.name) (psRustTailParameterNames rest)

-- A loop parameter is owned and initialized. Moving an unchanged String
-- after all other arguments have been computed avoids copying the full input
-- at every scan step. Repeated local names conservatively detect shadowing.
def psRustTailSingleLocal (locals : List String) : String -> Bool :=
  match locals with
  | List.nil => fun (_name : String) => false
  | List.cons head rest =>
      fun (name : String) =>
        let smaller : String -> Bool := psRustTailSingleLocal rest;
        if psStringEq head name then
          !psListAny (fun (other : String) => psStringEq other name) rest
        else smaller name

def psRustTailInvariantString (locals : List String)
    (parameter : PsVerifiedIrParameter) (argument : PsVerifiedIrExpr) : Bool :=
  match parameter.type with
  | PsVerifiedIrType.primitive primitive =>
      match primitive with
      | PsVerifiedIrPrimitiveType.string =>
          match argument with
          | PsVerifiedIrExpr.var name =>
              psStringEq name parameter.name && psRustTailSingleLocal locals name
          | _ => false
      | _ => false
  | _ => false

structure PsRustTailMovePlan where
  statements : List String
  values : List String
  original : List String
  moved : Bool

def psRustTailMoveArguments
    (emit : PsVerifiedIrExpr -> Except PsRustEmitError String)
    (locals : List String) (parameters : List PsVerifiedIrParameter) :
    List PsVerifiedIrExpr -> Nat -> Except PsRustEmitError PsRustTailMovePlan :=
  match parameters with
  | List.nil =>
      fun (arguments : List PsVerifiedIrExpr) (_index : Nat) =>
        if psListIsEmpty arguments then Except.ok (PsRustTailMovePlan.mk [] [] [] false)
        else Except.error PsRustEmitError.intrinsicArity
  | List.cons parameter rest =>
      fun (arguments : List PsVerifiedIrExpr) (index : Nat) =>
        let smaller : List PsVerifiedIrExpr -> Nat -> Except PsRustEmitError PsRustTailMovePlan :=
          psRustTailMoveArguments emit locals rest;
        match arguments with
        | List.nil => Except.error PsRustEmitError.intrinsicArity
        | List.cons argument others =>
            -- Retain ordinary emission and its errors even for moved operands.
            match emit argument with
            | Except.error error => Except.error error
            | Except.ok printed =>
                match smaller others (Nat.succ index) with
                | Except.error error => Except.error error
                | Except.ok tail =>
                    let original : String := psRustCloneExprPrinted argument printed;
                    if psRustTailInvariantString locals parameter argument then
                      Except.ok (PsRustTailMovePlan.mk tail.statements
                        (List.cons (psRustIdentifier parameter.name) tail.values)
                        (List.cons original tail.original) true)
                    else
                      match psRustEmitClosureValueType parameter.type with
                      | Except.error error => Except.error error
                      | Except.ok type =>
                          let temporary : String := psRustConcat2 "__ps_internal_tail_next_" (psNatToString index);
                          let statement : String := psRustJoin "" [
                            "let ", temporary, ": ", type, " = ", original, ";"];
                          Except.ok (PsRustTailMovePlan.mk (List.cons statement tail.statements)
                            (List.cons temporary tail.values) (List.cons original tail.original) tail.moved)

def psRustTailNextState
    (emit : PsVerifiedIrExpr -> Except PsRustEmitError String)
    (declaration : PsVerifiedIrDeclaration) (locals : List String)
    (captured : List String) (arguments : List PsVerifiedIrExpr) :
    Except PsRustEmitError String :=
  if psListIsEmpty captured then
    match psRustTailMoveArguments emit locals declaration.parameters arguments 0 with
    | Except.error error => Except.error error
    | Except.ok plan =>
        if plan.moved then
          Except.ok (psRustJoin "" ["{ ", psRustJoin " " plan.statements,
            " __ps_internal_tail_state = ", psRustTailTuple plan.values, "; continue; }"])
        else
          Except.ok (psRustConcat3 "{ __ps_internal_tail_state = "
            (psRustTailTuple plan.original) "; continue; }")
  else
    match psRustEmitExprListWith emit arguments with
    | Except.error error => Except.error error
    | Except.ok printed =>
        Except.ok (psRustConcat3 "{ __ps_internal_tail_state = "
          (psRustTailTuple (psListAppend captured printed)) "; continue; }")

def psRustTailLet (name : String) (type : PsVerifiedIrType) (value : PsVerifiedIrExpr)
    (printedValue printedBody : String) : Except PsRustEmitError String :=
  let annotation : Except PsRustEmitError String :=
    match type with
    | PsVerifiedIrType.function _ _ =>
        match psRustEmitClosureValueType type with
        | Except.error error => Except.error error
        | Except.ok printed => Except.ok (psRustConcat2 ": " printed)
    | _ =>
        match psRustEmitType type with
        | Except.error error => Except.error error
        | Except.ok printed => Except.ok (psRustConcat2 ": " printed);
  match annotation with
  | Except.error error => Except.error error
  | Except.ok printedType =>
      Except.ok (psRustJoin ""
        ["{ let ", psRustIdentifier name, printedType, " = ",
         psRustCloneExprPrinted value printedValue, "; ", printedBody, " }"])

def psRustEmitTailWorker (declarations : List PsVerifiedIrDeclaration)
    (declaration : PsVerifiedIrDeclaration) (fuel : Nat) :
    List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Except PsRustEmitError String :=
  match fuel with
  | Nat.zero =>
      fun (_locals : List String) (_aliases : List PsRustTailAlias) (_expr : PsVerifiedIrExpr) => Except.error PsRustEmitError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Except PsRustEmitError String :=
        psRustEmitTailWorker declarations declaration remaining;
      fun (locals : List String) (aliases : List PsRustTailAlias) (expr : PsVerifiedIrExpr) =>
        let ordinary : PsVerifiedIrExpr -> Except PsRustEmitError String :=
          psRustEmitExprWorker declarations remaining locals;
        match psRustTailCallFor declaration locals aliases expr with
        | Option.some call =>
            psRustTailNextState ordinary declaration locals call.captured call.arguments
        | Option.none =>
            match expr with
            | PsVerifiedIrExpr.letE name type value body =>
                match ordinary value with
                | Except.error error => Except.error error
                | Except.ok printedValue =>
                    match smaller (List.cons name locals) (psRustTailEnterAlias declaration locals aliases remaining name value) body with
                    | Except.error error => Except.error error
                    | Except.ok printedBody =>
                        match psRustTailLet name type value printedValue printedBody with
                        | Except.error error => Except.error error
                        | Except.ok printedLet =>
                            match psRustTailAliasFor declaration locals remaining name value with
                            | Option.none => Except.ok printedLet
                            | Option.some alias =>
                                Except.ok (psRustJoin "" ["{ ", psRustTailCaptureLets alias.captures, printedLet, " }"])
            | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
                match ordinary condition with
                | Except.error error => Except.error error
                | Except.ok printedCondition =>
                    match smaller locals aliases thenBranch with
                    | Except.error error => Except.error error
                    | Except.ok printedThen =>
                        match smaller locals aliases elseBranch with
                        | Except.error error => Except.error error
                        | Except.ok printedElse =>
                            Except.ok (psRustJoin ""
                              ["if ", printedCondition, " { ", printedThen, " } else { ", printedElse, " }"])
            | PsVerifiedIrExpr.matchE inductiveName _ scrutinee alternatives =>
                match ordinary scrutinee with
                | Except.error error => Except.error error
                | Except.ok printedScrutinee =>
                    let emitAlternative : List String -> PsVerifiedIrExpr -> Except PsRustEmitError String :=
                      fun (nestedLocals : List String) (body : PsVerifiedIrExpr) =>
                        let addedNames := psListTake (Nat.sub (psListLength nestedLocals) (psListLength locals)) nestedLocals;
                        smaller nestedLocals (psRustTailHideAliases addedNames aliases) body;
                    match psRustEmitAlternativeListWith locals emitAlternative inductiveName alternatives with
                    | Except.error error => Except.error error
                    | Except.ok printedAlternatives =>
                        Except.ok (psRustJoin "" ["match ", psRustCloneExprPrinted scrutinee printedScrutinee,
                          " { ", psRustJoin ", " printedAlternatives, " }"])
            | _ =>
                match ordinary expr with
                | Except.error error => Except.error error
                | Except.ok printed => Except.ok (psRustConcat3 "break { " printed " };")

def psRustEmitDeclarationBody (declarations : List PsVerifiedIrDeclaration)
    (declaration : PsVerifiedIrDeclaration) (locals : List String)
    (body : PsVerifiedIrExpr) : Except PsRustEmitError String :=
  if psRustHasTailWorker declaration 4096 locals body then
    match psRustEmitTailWorker declarations declaration 4096 locals List.nil body with
    | Except.error error => Except.error error
    | Except.ok printed =>
        let parameters := psRustTailTuple (psRustTailParameterNames declaration.parameters);
        Except.ok (psRustJoin "" ["let mut __ps_internal_tail_state = ", parameters,
          "; loop { let ", parameters, " = __ps_internal_tail_state; ", printed, " }"])
  else psRustEmitExprWorker declarations 4096 locals body
