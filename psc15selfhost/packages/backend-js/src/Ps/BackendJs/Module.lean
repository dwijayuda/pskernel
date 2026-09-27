import Ps.BackendJs.Normalize
import Ps.BackendJs.Lower
import Ps.BackendJs.Emit

def psJsAddParameterNames (parameters : List PsVerifiedIrParameter)
    (locals : List String) : List String :=
  match parameters with
  | List.nil => locals
  | List.cons parameter rest =>
      psJsAddParameterNames rest (List.cons parameter.name locals)

def psJsHasShadowedGlobalCallWithFuel (fuel : Nat) :
    List String -> PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_locals : List String) =>
        fun (_expr : PsVerifiedIrExpr) => true
  | Nat.succ remaining =>
      let smaller : List String -> PsVerifiedIrExpr -> Bool :=
        psJsHasShadowedGlobalCallWithFuel remaining;
      fun (locals : List String) =>
        fun (expr : PsVerifiedIrExpr) =>
          match expr with
          | PsVerifiedIrExpr.call fn _ _ =>
              match fn with
              | PsVerifiedIrExpr.var name => psJsContainsName locals name
              | _ => false
          | PsVerifiedIrExpr.letE name _ value body =>
              if smaller locals value then true
              else smaller (List.cons name locals) body
          | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
              if smaller locals condition then true
              else if smaller locals thenBranch then true
              else smaller locals elseBranch
          | PsVerifiedIrExpr.lambda parameters _ body =>
              smaller (psJsAddParameterNames parameters locals) body
          | _ => false

def psJsHasShadowedGlobalCall (locals : List String)
    (expr : PsVerifiedIrExpr) : Bool :=
  psJsHasShadowedGlobalCallWithFuel 4096 locals expr

def psJsValidateDeclarationCallTargets
    (declaration : PsVerifiedIrDeclaration) : Except PsJsError Unit :=
  let locals := psJsAddParameterNames declaration.parameters List.nil;
  if psJsHasShadowedGlobalCall locals declaration.body then
    Except.error PsJsError.unsupportedExpression
  else Except.ok Unit.unit

def psJsValidateDeclarationCallTargetsList
    (declarations : List PsVerifiedIrDeclaration) : Except PsJsError Unit :=
  match declarations with
  | List.nil => Except.ok Unit.unit
  | List.cons declaration rest =>
      match psJsValidateDeclarationCallTargets declaration with
      | Except.error error => Except.error error
      | Except.ok _ => psJsValidateDeclarationCallTargetsList rest

def psJsHasUnsafeEagerCallWithFuel (fuel : Nat) :
    List String -> List String -> PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_initializedGlobals : List String) =>
        fun (_locals : List String) =>
          fun (_expr : PsVerifiedIrExpr) => true
  | Nat.succ remaining =>
      let smaller : List String -> List String -> PsVerifiedIrExpr -> Bool :=
        psJsHasUnsafeEagerCallWithFuel remaining;
      fun (initializedGlobals : List String) =>
        fun (locals : List String) =>
          fun (expr : PsVerifiedIrExpr) =>
            match expr with
            | PsVerifiedIrExpr.call fn _ _ =>
                match fn with
                | PsVerifiedIrExpr.var name =>
                    if psJsContainsName locals name then false
                    else if psJsContainsName initializedGlobals name then false
                    else true
                | _ => false
            | PsVerifiedIrExpr.letE name _ value body =>
                if smaller initializedGlobals locals value then true
                else smaller initializedGlobals (List.cons name locals) body
            | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
                if smaller initializedGlobals locals condition then true
                else if smaller initializedGlobals locals thenBranch then true
                else smaller initializedGlobals locals elseBranch
            | PsVerifiedIrExpr.lambda _ _ _ => false
            | _ => false

def psJsHasUnsafeEagerCall (initializedGlobals : List String)
    (expr : PsVerifiedIrExpr) : Bool :=
  psJsHasUnsafeEagerCallWithFuel 4096 initializedGlobals List.nil expr

def psJsValidateInitializationOrderAux
    (declarations : List PsVerifiedIrDeclaration) :
    List String -> Except PsJsError Unit :=
  match declarations with
  | List.nil =>
      fun (_initializedGlobals : List String) => Except.ok Unit.unit
  | List.cons declaration rest =>
      let smaller : List String -> Except PsJsError Unit :=
        psJsValidateInitializationOrderAux rest;
      fun (initializedGlobals : List String) =>
        match declaration.parameters with
        | List.nil =>
            if psJsHasUnsafeEagerCall initializedGlobals declaration.body then
              Except.error PsJsError.unsupportedExpression
            else smaller (List.cons declaration.name initializedGlobals)
        | List.cons _ _ =>
            smaller (List.cons declaration.name initializedGlobals)

def psJsValidateInitializationOrder
    (declarations : List PsVerifiedIrDeclaration) : Except PsJsError Unit :=
  psJsValidateInitializationOrderAux declarations List.nil

def psJsEmitNormalizedModule (module : PsVerifiedIrModule) :
    Except PsJsError String :=
  match psJsValidateDeclarationCallTargetsList module.declarations with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psJsValidateInitializationOrder module.declarations with
      | Except.error error => Except.error error
      | Except.ok _ =>
          match psJsLowerModule module with
          | Except.error error => Except.error error
          | Except.ok lowered => psJsEmitTargetModule lowered

def psJsEmitModule (module : PsVerifiedIrModule) : Except PsJsError String :=
  match psJsNormalizeModule module with
  | Except.error error => Except.error error
  | Except.ok normalized => psJsEmitNormalizedModule normalized
