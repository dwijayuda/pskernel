import Ps.BackendRust.Expr

-- Only saturated, unshadowed, monomorphic direct self calls are eligible.
-- The loop carries a tuple so every argument is evaluated before replacement.
-- Mutual, polymorphic, indirect and non-tail recursion keep ordinary emission.
def psRustTailArguments (declaration : PsVerifiedIrDeclaration)
    (locals : List String) (expr : PsVerifiedIrExpr) : Option (List PsVerifiedIrExpr) :=
  match declaration.typeParameters with
  | List.cons _ _ => Option.none
  | List.nil =>
      match expr with
      | PsVerifiedIrExpr.call fn typeArguments arguments =>
          match fn with
          | PsVerifiedIrExpr.var name =>
              if psStringEq name declaration.name then
                if psRustStringListContains locals name then Option.none
                else
                  match typeArguments with
                  | List.cons _ _ => Option.none
                  | List.nil =>
                      if Nat.beq (psListLength declaration.parameters) (psListLength arguments) then
                        Option.some arguments
                      else Option.none
              else Option.none
          | _ => Option.none
      | _ => Option.none

def psRustTailAnyAlternative
    (check : List String -> PsVerifiedIrExpr -> Bool) (locals : List String)
    (alternatives : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) : Bool :=
  match alternatives with
  | List.nil => false
  | List.cons alternative rest =>
      let payload := Prod.snd alternative;
      if check (psRustAddBindingNames (Prod.fst payload) locals) (Prod.snd payload) then true
      else psRustTailAnyAlternative check locals rest

def psRustHasTailWorker (declaration : PsVerifiedIrDeclaration) (fuel : Nat) :
    List String -> PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero => fun (_locals : List String) (_expr : PsVerifiedIrExpr) => false
  | Nat.succ remaining =>
      let smaller : List String -> PsVerifiedIrExpr -> Bool := psRustHasTailWorker declaration remaining;
      fun (locals : List String) (expr : PsVerifiedIrExpr) =>
        match psRustTailArguments declaration locals expr with
        | Option.some _ => true
        | Option.none =>
            match expr with
            | PsVerifiedIrExpr.letE name _ _ body => smaller (List.cons name locals) body
            | PsVerifiedIrExpr.ifE _ thenBranch elseBranch =>
                if smaller locals thenBranch then true else smaller locals elseBranch
            | PsVerifiedIrExpr.matchE _ _ _ alternatives => psRustTailAnyAlternative smaller locals alternatives
            | _ => false

def psRustTailTuple (values : List String) : String :=
  match values with
  | List.nil => "()"
  | List.cons _ _ => psRustConcat3 "(" (psRustJoin ", " values) ",)"

def psRustTailParameterNames (parameters : List PsVerifiedIrParameter) : List String :=
  match parameters with
  | List.nil => List.nil
  | List.cons parameter rest =>
      List.cons (psRustIdentifier parameter.name) (psRustTailParameterNames rest)

def psRustTailLet (name : String) (type : PsVerifiedIrType) (value : PsVerifiedIrExpr)
    (printedValue printedBody : String) : Except PsRustEmitError String :=
  let annotation : Except PsRustEmitError String :=
    match type with
    | PsVerifiedIrType.function _ _ =>
        match psRustEmitClosureValueType type with
        | Except.error error => Except.error error
        | Except.ok printed => Except.ok (psRustConcat2 ": " printed)
    | _ => Except.ok "";
  match annotation with
  | Except.error error => Except.error error
  | Except.ok printedType =>
      Except.ok (psRustJoin ""
        ["{ let ", psRustIdentifier name, printedType, " = ",
         psRustCloneExprPrinted value printedValue, "; ", printedBody, " }"])

def psRustEmitTailWorker (declarations : List PsVerifiedIrDeclaration)
    (declaration : PsVerifiedIrDeclaration) (fuel : Nat) :
    List String -> PsVerifiedIrExpr -> Except PsRustEmitError String :=
  match fuel with
  | Nat.zero =>
      fun (_locals : List String) (_expr : PsVerifiedIrExpr) => Except.error PsRustEmitError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : List String -> PsVerifiedIrExpr -> Except PsRustEmitError String :=
        psRustEmitTailWorker declarations declaration remaining;
      fun (locals : List String) (expr : PsVerifiedIrExpr) =>
        let ordinary : PsVerifiedIrExpr -> Except PsRustEmitError String :=
          psRustEmitExprWorker declarations remaining locals;
        match psRustTailArguments declaration locals expr with
        | Option.some arguments =>
            match psRustEmitExprListWith ordinary arguments with
            | Except.error error => Except.error error
            | Except.ok printed =>
                Except.ok (psRustConcat3 "{ __ps_internal_tail_state = "
                  (psRustTailTuple printed) "; continue; }")
        | Option.none =>
            match expr with
            | PsVerifiedIrExpr.letE name type value body =>
                match ordinary value with
                | Except.error error => Except.error error
                | Except.ok printedValue =>
                    match smaller (List.cons name locals) body with
                    | Except.error error => Except.error error
                    | Except.ok printedBody => psRustTailLet name type value printedValue printedBody
            | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
                match ordinary condition with
                | Except.error error => Except.error error
                | Except.ok printedCondition =>
                    match smaller locals thenBranch with
                    | Except.error error => Except.error error
                    | Except.ok printedThen =>
                        match smaller locals elseBranch with
                        | Except.error error => Except.error error
                        | Except.ok printedElse =>
                            Except.ok (psRustJoin ""
                              ["if ", printedCondition, " { ", printedThen, " } else { ", printedElse, " }"])
            | PsVerifiedIrExpr.matchE inductiveName _ scrutinee alternatives =>
                match ordinary scrutinee with
                | Except.error error => Except.error error
                | Except.ok printedScrutinee =>
                    match psRustEmitAlternativeListWith locals smaller inductiveName alternatives with
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
    match psRustEmitTailWorker declarations declaration 4096 locals body with
    | Except.error error => Except.error error
    | Except.ok printed =>
        let parameters := psRustTailTuple (psRustTailParameterNames declaration.parameters);
        Except.ok (psRustJoin "" ["let mut __ps_internal_tail_state = ", parameters,
          "; loop { let ", parameters, " = __ps_internal_tail_state; ", printed, " }"])
  else psRustEmitExprWorker declarations 4096 locals body
