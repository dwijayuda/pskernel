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
            match psRustEmitExprListWith ordinary call.arguments with
            | Except.error error => Except.error error
            | Except.ok printed =>
                Except.ok (psRustConcat3 "{ __ps_internal_tail_state = "
                  (psRustTailTuple (psListAppend call.captured printed)) "; continue; }")
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
