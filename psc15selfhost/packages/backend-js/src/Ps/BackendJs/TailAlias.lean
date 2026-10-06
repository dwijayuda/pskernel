import Ps.BackendJs.Model
import Ps.Foundation.List
import Ps.Foundation.Name

structure PsJsTailAlias where
  name : String
  arity : Nat
  captures : List (Prod String String)

def psJsTailContains (names : List String) (name : String) : Bool :=
  let sameName : String -> Bool := fun (value : String) => psStringEq value name;
  psListAny sameName names

def psJsTailAliasFind (aliases : List PsJsTailAlias) (name : String) : Option PsJsTailAlias :=
  match aliases with
  | List.nil => Option.none
  | List.cons alias rest =>
      if psStringEq alias.name name then Option.some alias else psJsTailAliasFind rest name

def psJsTailAliasHide (names : List String) (aliases : List PsJsTailAlias) : List PsJsTailAlias :=
  match aliases with
  | List.nil => List.nil
  | List.cons alias rest =>
      if psJsTailContains names alias.name then psJsTailAliasHide names rest
      else List.cons alias (psJsTailAliasHide names rest)

def psJsTailAliasMentioned (uses : PsJsIrExpr -> String -> Bool)
    (aliases : List PsJsTailAlias) (expr : PsJsIrExpr) : Bool :=
  let mentioned : PsJsTailAlias -> Bool := fun (alias : PsJsTailAlias) => uses expr alias.name;
  psListAny mentioned aliases

def psJsTailCaptureIsAlias (aliases : List PsJsTailAlias) (capture : Prod String String) : Bool :=
  match psJsTailAliasFind aliases (Prod.fst capture) with
  | Option.none => false
  | Option.some _ => true

def psJsTailDrop (count : Nat) : List PsJsIrExpr -> List PsJsIrExpr :=
  match count with
  | Nat.zero => fun (values : List PsJsIrExpr) => values
  | Nat.succ remaining =>
      let smaller : List PsJsIrExpr -> List PsJsIrExpr := psJsTailDrop remaining;
      fun (values : List PsJsIrExpr) =>
        match values with
        | List.nil => List.nil
        | List.cons _ rest => smaller rest

def psJsTailEtaSuffix (parameters : List String) : List PsJsIrExpr -> Bool :=
  match parameters with
  | List.nil => fun (arguments : List PsJsIrExpr) => psListIsEmpty arguments
  | List.cons parameter rest =>
      let smaller : List PsJsIrExpr -> Bool := psJsTailEtaSuffix rest;
      fun (arguments : List PsJsIrExpr) =>
        match arguments with
        | List.nil => false
        | List.cons argument others =>
            match argument with
            | PsJsIrExpr.var name => if psStringEq parameter name then smaller others else false
            | _ => false

def psJsTailCaptureNames (locals parameters : List String)
    (arguments : List PsJsIrExpr) : Option (List String) :=
  match arguments with
  | List.nil => Option.some List.nil
  | List.cons argument rest =>
      match argument with
      | PsJsIrExpr.var name =>
          if psJsTailContains parameters name then Option.none
          else if psJsTailContains locals name then
            match psJsTailCaptureNames locals parameters rest with
            | Option.none => Option.none
            | Option.some names => Option.some (List.cons name names)
          else Option.none
      | _ => Option.none

def psJsTailCaptureBindings (available : String -> Bool) (scope : Nat)
    (names : List String) : Nat -> Option (List (Prod String String)) :=
  match names with
  | List.nil => fun (_index : Nat) => Option.some List.nil
  | List.cons name rest =>
      let smaller : Nat -> Option (List (Prod String String)) := psJsTailCaptureBindings available scope rest;
      fun (index : Nat) =>
        let fresh := String.Internal.append "__ps$tail$capture$"
          (String.Internal.append (psNatToString scope) (String.Internal.append "$" (psNatToString index)));
        if available fresh then
          match smaller (Nat.succ index) with
          | Option.none => Option.none
          | Option.some bindings => Option.some (List.cons (Prod.mk name fresh) bindings)
        else Option.none

def psJsTailRecognizeAlias (declaration : PsJsIrDeclaration) (available : String -> Bool)
    (locals : List String) (scope : Nat) (name : String) (value : PsJsIrExpr) : Option PsJsTailAlias :=
  match value with
  | PsJsIrExpr.lambda parameters body =>
      if psJsTailContains parameters declaration.name then Option.none
      else
        match body with
        | PsJsIrExpr.call fn arguments =>
            match fn with
            | PsJsIrExpr.var called =>
                if psStringEq called declaration.name then
                  if Nat.beq (psListLength arguments) (psListLength declaration.parameters) then
                    let arity := psListLength parameters;
                    if Nat.ble arity (psListLength arguments) then
                      let count := Nat.sub (psListLength arguments) arity;
                      if psJsTailEtaSuffix parameters (psJsTailDrop count arguments) then
                        match psJsTailCaptureNames locals parameters (psListTake count arguments) with
                        | Option.none => Option.none
                        | Option.some names =>
                            match psJsTailCaptureBindings available scope names 0 with
                            | Option.none => Option.none
                            | Option.some captures => Option.some (PsJsTailAlias.mk name arity captures)
                      else Option.none
                    else Option.none
                  else Option.none
                else Option.none
            | _ => Option.none
        | _ => Option.none
  | _ => Option.none

def psJsTailCapturedArgs (captures : List (Prod String String)) : List PsJsIrExpr :=
  let argument : Prod String String -> PsJsIrExpr :=
    fun (capture : Prod String String) => PsJsIrExpr.var (Prod.snd capture);
  psListMap argument captures

def psJsTailCaptureLets (captures : List (Prod String String)) (body : PsJsIrExpr) : PsJsIrExpr :=
  match captures with
  | List.nil => body
  | List.cons capture rest =>
      PsJsIrExpr.letE (Prod.snd capture) (PsJsIrExpr.var (Prod.fst capture)) (psJsTailCaptureLets rest body)

def psJsTailBindingName (value : PsJsIrMatchBinding) : String := value.name

def psJsTailRewriteAlternatives
    (rewrite : List String -> List PsJsTailAlias -> PsJsIrExpr -> Option PsJsIrExpr)
    (locals : List String) (aliases : List PsJsTailAlias)
    (values : List (Prod String (Prod (List PsJsIrMatchBinding) PsJsIrExpr))) :
    Option (List (Prod String (Prod (List PsJsIrMatchBinding) PsJsIrExpr))) :=
  match values with
  | List.nil => Option.some List.nil
  | List.cons value rest =>
      let payload := Prod.snd value;
      let names := psListMap psJsTailBindingName (Prod.fst payload);
      match rewrite (psListAppend names locals) (psJsTailAliasHide names aliases) (Prod.snd payload) with
      | Option.none => Option.none
      | Option.some body =>
          match psJsTailRewriteAlternatives rewrite locals aliases rest with
          | Option.none => Option.none
          | Option.some others =>
              Option.some (List.cons (Prod.mk (Prod.fst value) (Prod.mk (Prod.fst payload) body)) others)

-- Remove a forwarding closure only when every remaining occurrence is a
-- saturated tail call. Any ordinary use declines the whole transformation.
def psJsTailRewriteWithFuel (declaration : PsJsIrDeclaration)
    (uses : PsJsIrExpr -> String -> Bool) (available : String -> Bool) (fuel : Nat) :
    List String -> List PsJsTailAlias -> PsJsIrExpr -> Option PsJsIrExpr :=
  match fuel with
  | Nat.zero => fun (_locals : List String) (_aliases : List PsJsTailAlias) (_expr : PsJsIrExpr) => Option.none
  | Nat.succ remaining =>
      let smaller : List String -> List PsJsTailAlias -> PsJsIrExpr -> Option PsJsIrExpr :=
        psJsTailRewriteWithFuel declaration uses available remaining;
      fun (locals : List String) (aliases : List PsJsTailAlias) (expr : PsJsIrExpr) =>
        if psJsTailContains locals declaration.name then Option.none
        else
          match expr with
          | PsJsIrExpr.letE name value body =>
              let visible := psJsTailAliasHide [name] aliases;
              match psJsTailRecognizeAlias declaration available locals remaining name value with
              | Option.some alias =>
                  if psListAny (psJsTailCaptureIsAlias aliases) alias.captures then Option.none
                  else
                    match smaller (List.cons name locals) (List.cons alias visible) body with
                    | Option.none => Option.none
                    | Option.some rewritten => Option.some (psJsTailCaptureLets alias.captures rewritten)
              | Option.none =>
                  if psJsTailAliasMentioned uses aliases value then Option.none
                  else
                    match smaller (List.cons name locals) visible body with
                    | Option.none => Option.none
                    | Option.some rewritten => Option.some (PsJsIrExpr.letE name value rewritten)
          | PsJsIrExpr.ifE condition yes no =>
              if psJsTailAliasMentioned uses aliases condition then Option.none
              else
                match smaller locals aliases yes with
                | Option.none => Option.none
                | Option.some left =>
                    match smaller locals aliases no with
                    | Option.none => Option.none
                    | Option.some right => Option.some (PsJsIrExpr.ifE condition left right)
          | PsJsIrExpr.matchE scrutinee alternatives =>
              if psJsTailAliasMentioned uses aliases scrutinee then Option.none
              else
                match psJsTailRewriteAlternatives smaller locals aliases alternatives with
                | Option.none => Option.none
                | Option.some values => Option.some (PsJsIrExpr.matchE scrutinee values)
          | PsJsIrExpr.call fn arguments =>
              match fn with
              | PsJsIrExpr.var name =>
                  match psJsTailAliasFind aliases name with
                  | Option.none =>
                      if psJsTailAliasMentioned uses aliases expr then Option.none else Option.some expr
                  | Option.some alias =>
                      if Nat.beq alias.arity (psListLength arguments) then
                        if psListAny (psJsTailAliasMentioned uses aliases) arguments then Option.none
                        else Option.some (PsJsIrExpr.call (PsJsIrExpr.var declaration.name)
                          (psListAppend (psJsTailCapturedArgs alias.captures) arguments))
                      else Option.none
              | _ => if psJsTailAliasMentioned uses aliases expr then Option.none else Option.some expr
          | _ => if psJsTailAliasMentioned uses aliases expr then Option.none else Option.some expr
