import Ps.BackendRust.Expr

structure PsRustTailAlias where
  name : String
  arity : Nat
  captures : List (Prod String String)

structure PsRustTailCall where
  captured : List String
  arguments : List PsVerifiedIrExpr

def psRustTailSameTypes (parameters : List PsVerifiedIrTypeParameter) : List PsVerifiedIrType -> Bool :=
  match parameters with
  | List.nil =>
      fun (arguments : List PsVerifiedIrType) =>
        match arguments with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons parameter rest =>
      let smaller : List PsVerifiedIrType -> Bool := psRustTailSameTypes rest;
      fun (arguments : List PsVerifiedIrType) =>
        match arguments with
        | List.nil => false
        | List.cons argument others =>
            match argument with
            | PsVerifiedIrType.typeParameter name =>
                if psStringEq name parameter.name then smaller others else false
            | _ => false

def psRustTailArguments (declaration : PsVerifiedIrDeclaration)
    (locals : List String) (expr : PsVerifiedIrExpr) : Option (List PsVerifiedIrExpr) :=
  match expr with
  | PsVerifiedIrExpr.call fn typeArguments arguments =>
      match fn with
      | PsVerifiedIrExpr.var name =>
          if psStringEq name declaration.name then
            if psRustStringListContains locals name then Option.none
            else if psRustTailSameTypes declaration.typeParameters typeArguments then
              if Nat.beq (psListLength declaration.parameters) (psListLength arguments) then Option.some arguments
              else Option.none
            else Option.none
          else Option.none
      | _ => Option.none
  | _ => Option.none

def psRustTailFindAlias (aliases : List PsRustTailAlias) (name : String) : Option PsRustTailAlias :=
  match aliases with
  | List.nil => Option.none
  | List.cons alias rest =>
      if psStringEq alias.name name then Option.some alias else psRustTailFindAlias rest name

def psRustTailHideAliases (names : List String) (aliases : List PsRustTailAlias) : List PsRustTailAlias :=
  match aliases with
  | List.nil => List.nil
  | List.cons alias rest =>
      if psRustStringListContains names alias.name then psRustTailHideAliases names rest
      else List.cons alias (psRustTailHideAliases names rest)

def psRustTailCapturedArguments (captures : List (Prod String String)) : List String :=
  match captures with
  | List.nil => List.nil
  | List.cons capture rest =>
      List.cons (psRustClonePrinted (Prod.snd capture)) (psRustTailCapturedArguments rest)

def psRustTailCallFor (declaration : PsVerifiedIrDeclaration) (locals : List String)
    (aliases : List PsRustTailAlias) (expr : PsVerifiedIrExpr) : Option PsRustTailCall :=
  match psRustTailArguments declaration locals expr with
  | Option.some arguments => Option.some (PsRustTailCall.mk List.nil arguments)
  | Option.none =>
      match expr with
      | PsVerifiedIrExpr.call fn typeArguments arguments =>
          match typeArguments with
          | List.cons _ _ => Option.none
          | List.nil =>
              match fn with
              | PsVerifiedIrExpr.var name =>
                  match psRustTailFindAlias aliases name with
                  | Option.none => Option.none
                  | Option.some alias =>
                      if Nat.beq alias.arity (psListLength arguments) then
                        Option.some (PsRustTailCall.mk (psRustTailCapturedArguments alias.captures) arguments)
                      else Option.none
              | _ => Option.none
      | _ => Option.none

def psRustTailDrop (count : Nat) : List PsVerifiedIrExpr -> List PsVerifiedIrExpr :=
  match count with
  | Nat.zero => fun (values : List PsVerifiedIrExpr) => values
  | Nat.succ remaining =>
      let smaller : List PsVerifiedIrExpr -> List PsVerifiedIrExpr := psRustTailDrop remaining;
      fun (values : List PsVerifiedIrExpr) =>
        match values with
        | List.nil => List.nil
        | List.cons _ rest => smaller rest

def psRustTailEtaSuffix (parameters : List PsVerifiedIrParameter) : List PsVerifiedIrExpr -> Bool :=
  match parameters with
  | List.nil =>
      fun (arguments : List PsVerifiedIrExpr) =>
        match arguments with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons parameter rest =>
      let smaller : List PsVerifiedIrExpr -> Bool := psRustTailEtaSuffix rest;
      fun (arguments : List PsVerifiedIrExpr) =>
        match arguments with
        | List.nil => false
        | List.cons argument others =>
            match argument with
            | PsVerifiedIrExpr.var name =>
                if psStringEq parameter.name name then smaller others else false
            | _ => false

def psRustTailCaptureNames (locals parameters : List String)
    (arguments : List PsVerifiedIrExpr) : Option (List String) :=
  match arguments with
  | List.nil => Option.some List.nil
  | List.cons argument rest =>
      match argument with
      | PsVerifiedIrExpr.var name =>
          if psRustStringListContains parameters name then Option.none
          else if psRustStringListContains locals name then
            match psRustTailCaptureNames locals parameters rest with
            | Option.none => Option.none
            | Option.some names => Option.some (List.cons name names)
          else Option.none
      | _ => Option.none

def psRustTailCaptureBindings (scope : Nat) (names : List String) : Nat -> List (Prod String String) :=
  match names with
  | List.nil => fun (_index : Nat) => List.nil
  | List.cons name rest =>
      let smaller : Nat -> List (Prod String String) := psRustTailCaptureBindings scope rest;
      fun (index : Nat) =>
        List.cons (Prod.mk name (psRustConcat4 "__ps_internal_tail_capture_" (psNatToString scope) "_" (psNatToString index)))
          (smaller (Nat.succ index))

-- Recognize only eta closures forwarding a captured-variable prefix and their
-- unchanged parameter suffix to the same function at the same type arguments.
-- Captures are snapshotted in a reserved Rust namespace BEFORE the let binder.
def psRustTailAliasFor (declaration : PsVerifiedIrDeclaration) (locals : List String)
    (scope : Nat) (name : String) (value : PsVerifiedIrExpr) : Option PsRustTailAlias :=
  match value with
  | PsVerifiedIrExpr.lambda parameters _ body =>
      match psRustTailArguments declaration (psRustAddParameterNames parameters locals) body with
      | Option.none => Option.none
      | Option.some arguments =>
          let arity := psListLength parameters;
          if Nat.ble arity (psListLength arguments) then
            let capturedCount := Nat.sub (psListLength arguments) arity;
            if psRustTailEtaSuffix parameters (psRustTailDrop capturedCount arguments) then
              match psRustTailCaptureNames locals (psRustAddParameterNames parameters List.nil)
                  (psListTake capturedCount arguments) with
              | Option.none => Option.none
              | Option.some names =>
                  Option.some (PsRustTailAlias.mk name arity (psRustTailCaptureBindings scope names 0))
            else Option.none
          else Option.none
  | _ => Option.none

def psRustTailEnterAlias (declaration : PsVerifiedIrDeclaration) (locals : List String)
    (aliases : List PsRustTailAlias) (scope : Nat) (name : String) (value : PsVerifiedIrExpr) : List PsRustTailAlias :=
  let visible := psRustTailHideAliases [name] aliases;
  match psRustTailAliasFor declaration locals scope name value with
  | Option.none => visible
  | Option.some alias => List.cons alias visible

def psRustTailCaptureLets (captures : List (Prod String String)) : String :=
  match captures with
  | List.nil => ""
  | List.cons capture rest =>
      psRustJoin "" ["let ", Prod.snd capture, " = ", psRustClonePrinted (psRustIdentifier (Prod.fst capture)),
        "; ", psRustTailCaptureLets rest]
